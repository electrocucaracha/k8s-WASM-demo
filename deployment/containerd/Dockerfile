ARG version

FROM kindest/node:v${version} as builder

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN DEBIAN_FRONTEND=noninteractive clean-install \
    make=4.3-4ubuntu1 \
    git=1:2.32.0-1ubuntu1.2 \
    gcc=4:11.2.0-1ubuntu1 \
    build-essential=12.9ubuntu2 \
    pkgconf=1.7.4~git20210206+dcf529b-3 \
    libtool=2.4.6-15 \
    libsystemd-dev=248.3-1ubuntu8.6 \
    libprotobuf-c-dev=1.3.3-1build2 \
    libcap-dev=1:2.44-1build1 \
    libseccomp-dev=2.5.1-1ubuntu1 \
    libyajl-dev=2.1.0-3 \
    go-md2man=2.0.0+ds-5 \
    autoconf=2.69-14 \
    python3=3.9.4-1build1 \
    automake=1:1.16.4-2

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
