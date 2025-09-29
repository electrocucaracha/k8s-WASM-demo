#checkov:skip=CKV_DOCKER_2:Ensure that HEALTHCHECK instructions have been added to container images
ARG version

FROM kindest/node:v${version} as builder

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN DEBIAN_FRONTEND=noninteractive clean-install \
    ca-certificates=20230311+deb12u1 \
    curl=7.88.1-10+deb12u12 \
    make=4.3-4.1 \
    git=1:2.39.5-0+deb12u2 \
    gcc=4:12.2.0-3 \
    build-essential=12.9 \
    pkgconf=1.8.1-1 \
    libtool=2.4.7-7~deb12u1 \
    libsystemd-dev=252.38-1~deb12u1 \
    libprotobuf-c-dev=1.4.1-1+b1 \
    libcap-dev=1:2.66-4+deb12u1 \
    libseccomp-dev=2.5.4-1+deb12u1 \
    libyajl-dev=2.1.0-3+deb12u2 \
    go-md2man=2.0.2+ds1-1 \
    autoconf=2.71-3 \
    python3=3.11.2-1+b1 \
    automake=1:1.16.5-1.3

# install wasmedge headers (https://wasmedge.org/book/en/start/install.html#install-for-all-users)
    # NOTE: WasmEdge C API breaking changes (https://github.com/WasmEdge/WasmEdge/blob/master/docs/book/en/src/embed/c/0.9.1/upgrade_to_0.10.0.md)
RUN curl -sSf https://raw.githubusercontent.com/WasmEdge/WasmEdge/master/utils/install.sh | bash -s -- --path=/usr/local --extension=all --version=0.9.1 \
    && git clone https://github.com/containers/crun /opt/crun

# build crun with --with-wasmedge flag (https://wasmedge.org/book/en/kubernetes/container/crun.html)
WORKDIR /opt/crun
RUN git checkout tags/1.4.5 -b wasm \
    && ./autogen.sh \
    && ./configure --with-wasmedge --enable-embedded-yajl \
    && make

FROM kindest/node:v${version}

ARG version
ENV VERSION $version

COPY crio.conf /etc/crio/crio.conf
COPY --from=builder /opt/crun/crun /usr/local/sbin/crun
COPY --from=builder /usr/local/lib/libwasmedge_c.so /usr/local/lib/libwasmedge_c.so

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# hadolint ignore=DL3008
RUN DEBIAN_FRONTEND=noninteractive clean-install \
    gnupg=2.2.27-3ubuntu2.1 \
    libyajl-dev=2.1.0-3build2 \
    && export CONTAINERS_URL="https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_21.10/" \
    && echo "deb ${CONTAINERS_URL} /" > /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list \
    && export CRIO_URL="http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/${VERSION%.*}/xUbuntu_21.10/" \
    && echo "deb ${CRIO_URL} /" > "/etc/apt/sources.list.d/devel:kubic:libcontainers:stable:cri-o:${VERSION%.*}.list" \
    && curl -L "${CONTAINERS_URL}Release.key" | apt-key add - || true \
    && curl -L "${CRIO_URL}Release.key" | apt-key add - || true \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get --option=Dpkg::Options::=--force-confdef install -y --no-install-recommends \
    cri-o cri-o-runc \
    && rm -rf /var/lib/apt/lists/* \
    && ln -s /usr/libexec/podman/conmon /usr/local/bin/conmon \
    && sed -i 's/containerd/crio/g' /etc/crictl.yaml \
    && systemctl disable containerd \
    && systemctl enable crio
