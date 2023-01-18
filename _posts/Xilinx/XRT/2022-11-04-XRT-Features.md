---
title: 'XRT Features'
date: 2022-11-04 09:39:45 +0800
categories: [Xilinx, XRT]
tags: [xilinx, xrt]     # TAG names should always be lowercase
published: true
img_path: /assets/img/postimgs/Xilinx/XRT/
---


## P2P

PCIe peer-to-peer communication (P2P) is a PCIe feature which enables two PCIe devices to directly transfer data
 between each other without using host RAM as a temporary storage. 
The latest version of Alveo PCIe platforms support P2P feature via PCIe Resizeable BAR Capability.

PCIE特性之一，数据从一个PCIE设备直接到另一个PCIE设备，不经过主机的内存。部分卡支持，同时要求主机BIOS中开启一些特性以允许PCIE P2P。

<https://xilinx.github.io/XRT/master/html/p2p.html>



## M2M

一些Aveo卡，支持卡内buff移动，有硬件方式（opencl有提供封装调用接口）移动，不需要先读取到host 内存，再写到下一个计算单元的输入buff。

<https://xilinx.github.io/XRT/master/html/m2m.html>

>该特性在多个kernel级联时比较有用，可以节省传输时间
{: .prompt-tip }


## Host Memory Access

一些xilinx 的Alveo 卡编译的计算单元可以访问主机的内存。但要求主机开启 Hugepages 功能。

<https://xilinx.github.io/XRT/master/html/hm.html>



## Config file

XRT有一个配置文件，可以控制执行流程，调式，log等。

<https://xilinx.github.io/XRT/master/html/xrt_ini.html>


## Xilinx OpenCL extension

Please follow the general OpenCL guidelines to compile host applications that uses XRT OpenCL API 
with Xilinx OpenCL extensions. Xilinx OpenCL extension doesn’t require additional compiler features. 
Normally C99 or C++11 would be good.

All the OpenCL extensions are described in the file `src/include/1_2/CL/cl_ext_xilinx.h`

根据描述，xilinx的XRT是完全支持OpenCL的，且xilinx还做了额外扩展，xilinx opencl 部分。

使用opencl编译主机程序参考opencl的通用教程即可。

xilinx的opencl扩展部分：<https://xilinx.github.io/XRT/master/html/opencl_extension.html>







