# Kubernetes Wasm Demo
<!-- markdown-link-check-disable-next-line -->
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
![visitors](https://visitor-badge.glitch.me/badge?page_id=electrocucaracha.k8s-WASM-demo)

## Summary

[WebAssembly (abbreviated Wasm)][1] is a binary instruction format for a
stack-based virtual machine. The main goal is to enable high-performance
applications on web pages, "but it does not make any Web-specific assumptions or
provide Web-specific features, so it can be employed in other environments as
well." It is an open standard and aims to support any language on any operating
system, and in practice all of the most popular languages already have at least
some level of support.

> "WebAssembly, that defines a portable, size- and load-time-efficient format
and execution model specifically designed to serve as a compilation target for
the Web." - [Luke Wagner][4]

WasmEdge is a lightweight, high-performance, and extensible WebAssembly runtime
for cloud native, edge, and decentralized applications.

This project provides an End-to-End code to test an application that uses
WasmEdge runtime in Kubernetes.

### Metrics

The following table shows the sample taken from the 95 percentile values of a
single execution, those values can vary.

| Metric Name         | Description                                                                                | Rust    | Wasm     |
|:--------------------|:-------------------------------------------------------------------------------------------|:-------:|:--------:|
| http_req_blocked    | Time spent blocked (waiting for a free TCP connection slot) before initiating the request. | 5.18ms  | 460.62µs |
| http_req_connecting | Time spent establishing TCP connection to the remote host.                                 | 5.13ms  | 387.23µs |
| http_req_receiving  | Time spent receiving response data from the remote host.                                   | 6.36ms  | 413.08µs |
| http_req_sending    | Time spent sending data to the remote host.                                                | 2.86ms  | 246.45µs |
| http_req_waiting    | Time spent waiting for response from remote host (a.k.a. “time to first byte”, or “TTFB”). | 28.56ms | 69.13ms  |

> Surprisingly, the waiting time for response in WASM is longer than Rust.

## Virtual Machines

The [Vagrant tool][2] can be used for provisioning an Ubuntu Focal
Virtual Machine. It's highly recommended to use the  *setup.sh* script
of the [bootstrap-vagrant project][3] for installing Vagrant
dependencies and plugins required for this project. That script
supports two Virtualization providers (Libvirt and VirtualBox) which
are determine by the **PROVIDER** environment variable.

    curl -fsSL http://bit.ly/initVagrant | PROVIDER=libvirt bash

Once Vagrant is installed, it's possible to provision a Virtual
Machine using the following instructions:

    vagrant up

The provisioning process will take some time to install all
dependencies required by this project and perform a Kubernetes
deployment on it.

[1]: https://webassembly.org/
[2]: https://www.vagrantup.com/
[3]: https://github.com/electrocucaracha/bootstrap-vagrant
[4]: https://blog.mozilla.org/luke/2015/06/17/webassembly/
