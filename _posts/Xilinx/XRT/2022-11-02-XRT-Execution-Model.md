---
title: 'XRT Execution Model'
date: 2022-11-02 14:45:10 +0800
categories: [Xilinx, XRT]
tags: [xilinx, xrt]     # TAG names should always be lowercase
published: true
img_path: /assets/img/postimgs/Xilinx/XRT/
---

# Memory Management

Both PCIe based and embedded platforms use a unified multi-thread/process capable memory management API 
defined in [XRT Core Library](https://xilinx.github.io/XRT/master/html/xrt.main.html) document.

For both class of platforms, memory management is performed inside Linux kernel driver. 
Both drivers use DRM GEM for memory management which includes buffer allocator, buffer mmap support, 
reference counting of buffers and DMA-BUF export/import. 
These operations are made available via ioctls exported by the drivers.

两个使用方式，内存管理都是有linux 内核驱动负责的。
使用DRM GEM框架（linux的图显系统，参考 [Linux GPU Driver Developer’s Guide](https://www.kernel.org/doc/html/latest/gpu/index.html)）
来管理buff分配，buff的mmap，buff 统计计数，dma-buff export/import。这些功能通过ioctl命令导出给用户使用。


## xocl

**Xilinx® PCIe platforms like Alveo PCIe cards support various memory topologies which can be dynamically loaded as part of FPGA image loading step. This means from one FPGA image to another the device may expose one or more memory controllers where each memory controller has its own memory address range. We use Linux drm_mm for allocation of memory and Linux drm_gem framework for mmap handling. Since ordinarily our device memory is not exposed to host CPU (except when we enable PCIe peer-to-peer feature) we use host memory pages to back device memory for mmap support. For syncing between device memory and host memory pages XDMA/QDMA PCIe memory mapped DMA engine is used. Users call sync ioctl to effect DMA in requested direction.**

xocl also supports PCIe Host Memory Bridge where it handles pinning of host memory and programming the Address Remapper tables. Section [Host Memory Access](https://xilinx.github.io/XRT/master/html/hm.html) provides more information.

赛灵思® PCIe 平台（如 Alveo PCIe 卡）支持各种存储器拓扑，这些拓扑可作为 FPGA 映像加载步骤的一部分进行动态加载。这意味着从一个FPGA映像到另一个映像，设备可能会公开一个或多个内存控制器，其中每个内存控制器都有自己的内存地址范围。我们使用 Linux drm_mm 来分配内存，使用 Linux drm_gem 框架进行 mmap 处理。由于通常我们的设备内存不会暴露给主机CPU（除非我们启用PCIe点对点功能），因此我们使用主机内存页来支持设备内存以获得mmap支持。为了在设备内存和主机内存页面之间同步XDMA/QDMA PCIe内存映射DMA引擎。用户调用同步 ioctl 以在请求的方向上实现 DMA。

xocl 还支持 PCIe 主机内存桥，它处理主机内存的固定和地址重映射表的编程。主机内存访问部分提供了详细信息。


## zocl
Xilinx® embedded platforms like Zynq Ultrascale+ MPSoC support various memory topologies as well. In addition to memory shared between PL (FPAG fabric) and PS (ARM A-53) we can also have dedicated memory for PL using a soft memory controller that is instantiated in the PL itself. zocl supports both CMA backed memory management where accelerators in PL use physical addresses and SVM based memory management – with the help of ARM SMMU – where accelerators in PL use virtual addresses also shared with application running on PS.


# Execution Management

Both xocl and zocl support structured execution framework. After xclbin has been loaded by the driver compute units defined by the xclbin are live and ready for execution. The compute units are controlled by driver component called Kernel Domain Scheduler (KDS). KDS queues up execution tasks from client processes via ioctls and then schedules them on available compute units. Both drivers export an ioctl for queuing up execution tasks.

在xclbin文件加载到FPGA后，xclbin文件中对应的计算单元（硬件FPGA中）就处于就绪状态。这些计算单元由 KDS（xilinx做的一个调度器）调度器调度执行。用来调度执行主机上用过ioctl发下来的计算任务。该KDS调度器是支持队列式执行计算任务的，

User space submits execution commands to KDS in well defined command packets. The commands are defined in [Embedded Runtime Library](https://xilinx.github.io/XRT/master/html/ert.main.html)，这个用户提交的计算任务的命令（ioctl）有固定的一些格式，参考上面链接。

KDS notifies user process of a submitted execution task completion asynchronously via POSIX poll mechanism. On PCIe platforms KDS leverages hardware scheduler running on Microblaze soft processor for fine control of compute units. Compute units use interrupts to notify xocl/zocl when they are done. KDS also supports polling mode where KDS actively polls the compute units for completion instead of relying on interrupts from compute units.

在计算卡上，KDS运行在Microblaze上，在一个计算任务完成后，计算单元可以上报中断给HOST，对应主机中xocl模块触发执行handler。KDS也支持轮询模式。

**On PCIe platforms hardware scheduler (referred to above) runs firmware called Embedded Runtime (ERT)**. ERT receives requests from KDS on hardware out-of-order Command Queue with upto 128 command slots. ERT notifies KDS of work completion by using bits in Status Register and MSI-X interrupts. ERT source code is also included with XRT source on GitHub.

这个ERT就是Embedded Runtime，其实就是对应加速卡中运行KDS的一套系统固件（由Microblaze执行）。在HOST视角看来，就可以称为Embedded Runtime (ERT)，这是必要的，不过因为在卡中，也可以不关注吧。ERT应该包含了KDS，同时还有和HOST交互的部分等等，KDS是里面核心的调度方式。

# Board Management

For Alveo boards xclmgmt does the board management like board recovery in case compute units hang the data bus, sensor data collection, AXI Firewall monitoring, clock scaling, power measurement, loading of firmware files on embedded soft processors like ERT and CMC.


# Execution Flow

A typical user execution flow would like the following:

1. Load xclbin using DOWNLOAD ioctl
2. Discover compute unit register map from xclbin
3. Allocate data buffers to feed to the compute units using CREATE_BO/MAP_BO ioctl calls
4. Migrate input data buffers from host to device using SYNC_BO ioctl
5. Allocate an execution command buffer using CREATE_BO/MAP_BO ioctl call and fill the command buffer using data in 2 above and following the format defined in ert.h
6. Submit the execution command buffer using EXECBUF ioctl
7. Wait for completion using POSIX poll
8. Migrate output data buffers from device to host using SYNC_BO ioctl
9. Release data buffers and command buffer


