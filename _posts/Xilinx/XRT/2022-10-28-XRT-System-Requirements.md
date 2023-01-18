---
title: 'XRT System Requirements'
date: 2022-10-28 16:10:10 +0800
categories: [Xilinx, XRT]
tags: [xilinx, xrt]     # TAG names should always be lowercase
published: true
img_path: /assets/img/postimgs/Xilinx/XRT/
---


# System Requirements

Host Platform for PCIe Accelerator Cards

* x86_64
* AARCH64
* PPC64LE

Supported Xilinx® Accelerator Cards are listed in [XRT and Vitis™ Platform Overview](https://xilinx.github.io/XRT/master/html/platforms.html) .

# XRT Software Stack for PCIe Accelerator Cards

XRT software stack requires Linux kernel 3.10+.

The XRT software stack is tested on RHEL/CentOS and Ubuntu. For the detailed list of supported OS, please refer to the specific release versions of [UG1451 XRT Release Notes](https://www.xilinx.com/support/documentation-navigation/see-all-versions.html?xlnxproducttypes=Design%20Tools&xlnxdocumentid=UG1451).

XRT is needed on both application development and deployment environments
To install XRT on the host, please refer to page [XRT Installation](https://xilinx.github.io/XRT/master/html/install.html). for dependencies installation steps and XRT installation steps.

To build a custom XRT package, please refer to page [Building the XRT Software Stack](https://xilinx.github.io/XRT/master/html/build.html). for dependencies installation steps and building steps.

# XRT Software Stack for Embedded Platforms

XRT software stack requires Linux kernel 3.10+. XRT for embedded platforms is tested with PetaLinux.

XRT needs to be installed on the development environment (rootfs or sysroot) and deployment environment (rootfs) of embedded platforms.

If embedded processor native compile is to be used, XRT, xrt-dev and GCC needs to be installed on the target embedded system rootfs.

If application is developed on a server with cross compiling technique, XRT needs to be installed into sysroot. The application can be cross compiled against the sysroot. XRT for server is not required on the cross compile server.

The embedded platform for deployment should have XRT and ZOCL installed. For details about building embedded platforms please refer to [XRT Setup for Embedded Flow](https://xilinx.github.io/XRT/master/html/yocto.html).


