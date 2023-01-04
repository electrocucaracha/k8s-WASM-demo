ARG version

FROM kindest/node:v${version} as builder

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN DEBIAN_FRONTEND=noninteractive clean-install \
    make=4.3-4.1build1 \
    git=1:2.34.1-1ubuntu1.5 \
    gcc=4:11.2.0-1ubuntu1 \
    build-essential=12.9ubuntu3 \
    pkgconf=1.8.0-1 \
    libtool=2.4.6-15build2 \
    libsystemd-dev=249.11-0ubuntu3.6 \
    libprotobuf-c-dev=1.3.3-1ubuntu2.1 \
    libcap-dev=1:2.44-1build3 \
    libseccomp-dev=2.5.3-2ubuntu2 \
    libyajl-dev=2.1.0-3build2 \
    go-md2man=2.0.1+ds1-1 \
    autoconf=2.71-2 \
    python3=3.10.6-1~22.04 \
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
