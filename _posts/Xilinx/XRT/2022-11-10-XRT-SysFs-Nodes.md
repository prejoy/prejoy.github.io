---
title: 'XRT Linux Sys FileSystem Nodes'
date: 2022-11-10 13:18:22 +0800
categories: [Xilinx, XRT]
tags: [xilinx, xrt]     # TAG names should always be lowercase
published: true
img_path: /assets/img/postimgs/Xilinx/XRT/
---


`xocl` and `xclmgmt` drivers expose several `sysfs` nodes under the `pci` device root node. The sysfs nodes are populated by platform drivers present in the respective drivers.

## xocl

The `xocl` driver exposes various sections of the `xclbin` image including the `xclbinuuid` on `sysfs`. *This makes it very convenient for tools (such as `xbutil`) to discover characteristics of the image currently loaded on the FPGA*. The data layout of xclbin sections are defined in file xclbin.h which can be found under runtime/core/include directory. Platform drivers XDMA, ICAP, MB Scheduler, Mailbox, XMC, XVC, FeatureROM export their nodes on sysfs.

ex:
```bash
sudo tree /sys/bus/pci/devices/0000\:1a\:00.1
```

## xclmgmt

The `xclmgmt` driver exposes various sections of the `xclbin` image including the `xclbinuuid` on `sysfs`. This makes it very convenient for tools (such as xbutil) to discover characteristics of the image currently loaded on the FPGA. The data layout of xclbin sections are defined in file xclbin.h which can be found under runtime/core/include directory. Platform drivers ICAP, FPGA Manager, AXI Firewall, Mailbox, XMC, XVC, FeatureROM export their nodes on sysfs.

ex:
```bash
sudo tree /sys/bus/pci/devices/0000\:1a\:00.0
```


## zocl

Similar to PCIe drivers, `zocl` driver used in embedded platforms exposes various sections of the `xclbin` image including the `xclbinuuid` on `sysfs`. This makes it very convenient for tools (such as xbutil) to discover characteristics of the image currently loaded on the FPGA. The data layout of xclbin sections are defined in file xclbin.h which can be found under runtime/core/include directory.

ex:
```bash
sudo tree /sys/bus/platform/devices/amba/zyxclmm_drm
```

