ARG version

FROM ubuntu:22.04 as builder

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    apt-get install -y --no-install-recommends \
    ca-certificates=20211016 \
    curl=7.81.0-1ubuntu1.6 \
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
    automake=1:1.16.5-1.3 && \
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

COPY config.toml /etc/containerd/config.toml
COPY --from=builder /opt/crun/crun /usr/local/sbin/crun
COPY --from=builder /usr/local/lib/libwasmedge_c.so /usr/local/lib/libwasmedge_c.so

RUN echo "Installing Packages ..." \
    && bash -c 'cat <<< $(jq "del(.hooks.createContainer)" /etc/containerd/cri-base.json) > /etc/containerd/cri-base.json' \
    && ldconfig
