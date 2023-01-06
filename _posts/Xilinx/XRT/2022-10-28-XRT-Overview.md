---
title: 'XRT-Overview'
date: 2022-10-28 09:52:40 +0800
categories: [Xilinx, XRT]
tags: [xilinx, xrt]     # TAG names should always be lowercase
published: true
---

参考自xilinx官方的XRT文档：https://xilinx.github.io/XRT/master/html/


# Xilinx® Runtime (XRT) Architecture

* XRT由（一系列用户空间的Libraries和Tools）和（Linux Kernel driver models）组成。
* 可以当做x86加速卡使用（PCI设备），也可以用于嵌入式环境（ARM linux嵌入式环境）。这两种情况主要使用的Linux kernel driver模块不同。（因为x86的PCI驱动和ARM的设备树驱动用法有较大差异）。
* 对于上层应用开发，则提供了统一的 user APIs，(头文件 xrt.h )

![XRT Software Stack](./pics/XRT-Layers.svg)


# Introduction

## XRT and Vitis™ Platform Overview

[Xilinx Runtime library (XRT) ](https://www.xilinx.com/products/design-tools/vitis/xrt.html)是一个开源的用户软件套件，用于方便的管理和使用Xilinx的FPGA/ACAP设备。用户使用C/C++ 或 Python 就可以方便的使用XRT去和硬件的FPGA/ACAP设备交互。（管理硬件的内核驱动模块完全不需要改动？？）

Git仓库 : https://github.com/Xilinx/XRT

### User Application Compilation

* x86Host的应用程序使用C/C++/OpenCL or Python编写。
* 硬件设备的可以使用 C/C++ or VHDL/Verilog hardware description language.这里应该是属于FPGA相关，硬件设备的code使用 Vitis™ compiler, v++ 去编译并链接，（device code 编译为xo，链接生成xclbin，运行于FPGA内部。）

### PCIe Based Platforms

Alveo PCIe stack:

![Alveo PCIe stack](./pics/XRT-Architecture-PCIe.svg)

XRT supports following PCIe based devices:

U200
U250
U280
U50
AWS F1
U30
U25
VCK5000
Advantech VEGA-4000/4002

The platform is comprised of physical partitions called **Shell and User**. The Shell has two physical functions: **privileged PF0 also called mgmt pf and non-privileged PF1 also called user pf**. *Shell provides basic infrastructure for the Alveo platform. User partition (otherwise known as PR-Region) contains user compiled binary.* XRT uses Dynamic Function Exchange (DFX) to load user compiled binary to the User partition.

PF0 为特权级功能，用于管理硬件设备（对于xclmgmt驱动，用户的xclbin文件就是由此模块加载的）。

PF1为用户功能，也称PR-Region，主要就是xclbin，对应用户自己的device code（HLS/RTL/Verilog等）。


### MGMT PF (PF0)

xclmgmt 内核模块用于管理物理功能(physical function)。 Management physical function provides access to Shell components responsible for privileged operations.主要功能：

* User compiled FPGA image (xclbin) download which involves ICAP (bitstream download) programming, clock scaling and isolation logic management.
* Loading firmware container called xsabin which contains PLP (for 2 RP platfroms) and firmwares for embedded Microblazes. The embedded Microblazes perform the functionality of ERT and CMC.
* Access to in-band sensors: temperature, voltage, current, power, fan RPM etc.
* AXI Firewall management in data and control paths. AXI firewalls protect shell and PCIe from untrusted user partition.
* Shell upgrade by programming QSPI flash constroller.
* Device reset and recovery upon detecting AXI firewall trips or explicit request from end user.
* Communication with user pf driver xocl via hardware mailbox. The protocol is defined [Mailbox Inter-domain Communication Protocol](https://xilinx.github.io/XRT/master/html/mailbox.proto.html)
* Interrupt handling for AXI Firewall and Mailbox HW IPs.
* Device DNA (unique ID) discovery and validation.
* DDR and HBM memory ECC handling and reporting.

### USER PF (PF1)

xocl内核模块绑定到用户物理功能。 User physical function provides access to Shell components responsible for non privileged operations.它还提供对用户分区中计算单元的访问。xocl 驱动程序被组织到子设备中，并处理以下功能，这些功能是在 xrt.h 头文件中使用明确定义的 API 执行的。

* Device memory topology discovery and device memory management. The driver provides well-defined abstraction of buffer objects to the clients.
* XDMA/QDMA memory mapped PCIe DMA engine programming and with easy to use buffer migration API.
* Multi-process aware context management with concurrent access to device by multiple processes.
* Compute unit execution pipeline management with the help of hardware scheduler ERT. If ERT is not available then scheduling is completely handled by xocl driver in software.
* Interrupt handling for PCIe DMA, Compute unit completion and Mailbox messages.
* Setting up of Address-remapper tables for direct access to host memory by kernels compiled into user partition. Direct access to host memory is enabled by Slave Bridge (SB) in the shell.
* Buffer import and export via Linux DMA-BUF infrastructure.
* PCIe peer-to-peer buffer mapping and sharing over PCIe bus.
* Secure communication infrastructure for exchanging messages with xclmgmt driver.
* Memory-to-memory (M2M) programming for moving data between device DDR, PL-RAM and HBM.

Note:Section [Security of Alveo Platform](https://xilinx.github.io/XRT/master/html/security.html) describes PCIe platform security and robustness in detail.


### PCIe Based Hybrid Platforms

![Alveo PCIe hybrid stack](./pics/XRT-Architecture-Hybrid.svg)

Alveo PCIe hybrid stack

U30 and VCK5000 are MPSoC and Versal platforms respectively are considered hybrid devices. They have hardedned PS subsystem with ARM APUs in the Shell. The PL fabric is exposed as user partition. The devices act as PCIe endpoint to PCIe hosts like x86_64, PPC64LE. They have two physical function architecture identical to other Alveo platforms. On these platforms the ERT subsystem is running on APU.

基于PCIe的混合设备？？图中差异为 ERT<->ZOCL-ERT，MicroBlaze<->PS，PR Region<->PL-PR Region，感觉主要就是将MicroBlaze换为ARM处理器，去跑ERT子系统，同时PR Region有了变化...



### Zynq-7000 and ZYNQ Ultrascale+ MPSoC Based Embedded Platforms

这里描述XRT的嵌入式平台环境，ARM做主控CPU的结构图。

![MPSoC Embedded stack](./pics/XRT-Architecture-Edge.svg)

MPSoC Embedded stack

![Versal ACAP Embedded stack](./pics/XRT-Architecture-Versal-Edge.svg)

Versal ACAP Embedded stack


在嵌入式平台环境 创建带有XRT环境的平台 步骤参考： [XRT Setup for Embedded Flow](https://xilinx.github.io/XRT/master/html/yocto.html)

构建流程可以部分参考：https://github.com/Xilinx/Vitis_Embedded_Platform_Source

编译好的官方平台：主要有
ZC706
ZCU102
ZCU104
ZCU106
VCK190
https://www.xilinx.com/support/download/index.html/content/xilinx/en/downloadNav/embedded-platforms.html



在嵌入式环境下，ZOCL内核模块完成大部分工作。XRT的API使用头文件 xrt.h 和 xrt_aie.h (for AIE)

* PS memory CMA buffer management and cache management. On SVM enabled platforms zocl also manages SMMU. The driver provides well-defined abstraction of buffer objects to the clients.
* Compute unit execution pipeline management for clients.
* User compiled FPGA image (xclbin) for platforms with Partial Reconfiguration support.
* Buffer object import and export via DMA-BUF.
* Interrupt handling for compute unit completion.
* AIE array programming and graph execution.
* If PL-DDR memory is enabled by instantiating MIG in PL, zocl provides memory management similar to PS memory.
* ZynqMP DMA engine programming for moving data between PS DDR and PL-DDR.
* AIE GMIO data mover programming to move data between NOC and AIE.

Note:Section [Execution Model Overview](https://xilinx.github.io/XRT/master/html/execution-model.html) provides a high level overview of execution model.