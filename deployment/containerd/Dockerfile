ARG version

FROM ubuntu:22.04 as builder

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    apt-get install -y --no-install-recommends \
    ca-certificates=20211016 \
    curl=7.81.0-1ubuntu1.20 \
    make=4.3-4.1build1 \
    git=1:2.34.1-1ubuntu1.15 \
    gcc=4:11.2.0-1ubuntu1 \
    build-essential=12.9ubuntu3 \
    pkgconf=1.8.0-1 \
    libtool=2.4.6-15build2 \
    libsystemd-dev=249.11-0ubuntu3.16 \
    libprotobuf-c-dev=1.3.3-1ubuntu2.1 \
    libcap-dev=1:2.44-1ubuntu0.22.04.2 \
    libseccomp-dev=2.5.3-2ubuntu3~22.04.1 \
    libyajl-dev=2.1.0-3ubuntu0.22.04.1 \
    go-md2man=2.0.1+ds1-1 \
    autoconf=2.71-2 \
    python3=3.10.6-1~22.04.1 \
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

RUN curl -sSf https://raw.githubusercontent.com/WasmEdge/WasmEdge/master/utils/install.sh | bash -s -- --path=/usr/local/ --version=0.14.1 \
    && git clone https://github.com/containers/crun /opt/crun

# build crun with --with-wasmedge flag (https://wasmedge.org/docs/develop/deploy/oci-runtime/crun/)
WORKDIR /opt/crun
RUN git checkout tags/1.22 -b wasm \
    && ./autogen.sh \
    && ./configure --with-wasmedge --enable-embedded-yajl \
    && make

FROM kindest/node:v${version}

COPY --from=builder /opt/crun/crun /usr/local/sbin/crun
COPY --from=builder /usr/local/lib/libwasmedge.so /usr/local/lib/libwasmedge.so

RUN echo "Installing Packages ..." \
    && bash -c 'cat <<< $(jq "del(.hooks.createContainer)" /etc/containerd/cri-base.json) > /etc/containerd/cri-base.json' \
    && ldconfig
