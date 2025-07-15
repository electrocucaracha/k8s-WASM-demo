# Kubernetes Wasm Demo

<!-- markdown-link-check-disable-next-line -->

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Ruby Style Guide](https://img.shields.io/badge/code_style-rubocop-brightgreen.svg)](https://github.com/rubocop/rubocop)
![visitors](https://visitor-badge.laobi.icu/badge?page_id=electrocucaracha.k8s-WASM-demo)

## Summary

[WebAssembly (Wasm)][1] is a binary instruction format designed for a stack-based
virtual machine. Its primary goal is to enable high-performance applications on
web pages. However, it’s not limited to the Web — Wasm makes no Web-specific
assumptions and does not include Web-only features. As an open standard, it is
intended to support any language across any operating system, and today, most
popular languages already offer some degree of support.

> "WebAssembly, that defines a portable, size- and load-time-efficient format
> and execution model specifically designed to serve as a compilation target for
> the Web." - [Luke Wagner][4]

WasmEdge is a lightweight, high-performance, and extensible WebAssembly runtime
optimized for cloud-native, edge, and decentralized applications.

This project offers end-to-end code to test a Kubernetes-based application using
the WasmEdge runtime.

### Metrics

The following table presents sample metrics taken from the 95th percentile of a
single test run. These values may vary with each execution:

| Metric Name         | Description                                                                         |  Rust   |   Wasm   |
| :------------------ | :---------------------------------------------------------------------------------- | :-----: | :------: |
| http_req_blocked    | Time spent waiting for an available TCP connection before making the request.       | 14.06ms |  3.55ms  |
| http_req_connecting | Time spent establishing a TCP connection to the remote host.                        | 13.79ms |  3.16ms  |
| http_req_receiving  | Time spent receiving data from the remote host.                                     | 16.04ms |  2.39ms  |
| http_req_sending    | Time spent sending data to the remote host.                                         | 7.14ms  |  1.57ms  |
| http_req_waiting    | Time spent waiting for the response (also known as "time to first byte" or "TTFB"). | 34.92ms | 126.93ms |

> Note: Surprisingly, the response waiting time in the Wasm version is longer than in Rust.

## Virtual Machines

The [Vagrant tool][2] can be used to provision an Ubuntu Focal virtual machine.
It’s highly recommended to use the _setup.sh_ script from the [bootstrap-vagrant project][3]
to install the required Vagrant dependencies and plugins.

This script supports two virtualization providers — Libvirt and
VirtualBox — which can be selected via the **PROVIDER** environment variable:

    curl -fsSL http://bit.ly/initVagrant | PROVIDER=libvirt bash

Once Vagrant is set up, you can provision the virtual machine using:

    vagrant up

This process may take a while, as it installs all dependencies and deploys Kubernetes within the VM.

[1]: https://webassembly.org/
[2]: https://www.vagrantup.com/
[3]: https://github.com/electrocucaracha/bootstrap-vagrant
[4]: https://blog.mozilla.org/luke/2015/06/17/webassembly/
