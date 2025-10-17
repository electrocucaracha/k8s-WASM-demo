#checkov:skip=CKV_DOCKER_2:Ensure that HEALTHCHECK instructions have been added to container images
ARG version

FROM wasmedge/wasmedge:ubuntu-build-clang as builder

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    apt-get install -y --no-install-recommends \
    pkgconf=1.8.1-2build1 \
    autoconf=2.71-3 \
    libtool=2.4.7-7build1 \
    libyajl-dev=2.1.0-5build1 \
    libcap-dev=1:2.66-5ubuntu2.2 \
    libseccomp-dev=2.5.5-1ubuntu3.1 \
    libsystemd-dev=255.4-1ubuntu8.11 \
    automake=1:1.16.5-1.3ubuntu1 && \
    apt-get clean -y && \
    rm -rf \
    /var/cache/debconf/* \
    /var/lib/apt/lists/* \
    /var/log/* \
    /tmp/* \
    /var/tmp/* \
    /usr/share/doc/* \
    /usr/share/doc-base/* \
    /usr/share/man/* \
    /usr/share/local/*

RUN curl -sSf https://raw.githubusercontent.com/WasmEdge/WasmEdge/master/utils/install.sh | bash -s -- --path=/usr/local/ --version=0.15.0 \
    && git clone https://github.com/containers/crun /opt/crun

# build crun with --with-wasmedge flag (https://wasmedge.org/docs/develop/deploy/oci-runtime/crun/)
WORKDIR /opt/crun
RUN git checkout tags/1.24 -b wasm \
    && ./autogen.sh \
    && ./configure --with-wasmedge --enable-embedded-yajl \
    && make

FROM kindest/node:v${version}

COPY --from=builder /opt/crun/crun /usr/local/sbin/crun
COPY --from=builder /usr/local/lib/libwasmedge.so /usr/local/lib/libwasmedge.so

RUN echo "Installing Packages ..." \
    && bash -c 'cat <<< $(jq "del(.hooks.createContainer)" /etc/containerd/cri-base.json) > /etc/containerd/cri-base.json' \
    && ldconfig
