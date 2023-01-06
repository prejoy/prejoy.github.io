---
title: PCIe Base & Limit寄存器详解
categories: [Drivers, PCI]
tags: [ PCIe, PCI ]
pin: false
published: true
img_path: /assets/img/postimgs/LinuxDrivers/PCI/
---

PCIe中的桥设备（Switch和Root中的P2P）又是如何判断某一请求（Request）是否属于自己或者自己的分支下的设备的呢？
这实际上是通过Type1型配置空间Header中的Base和Limit寄存器来实现的

![PCIe_Base_and_Limit_reg](PCIe_Base_and_Limit_reg.png)

Base和Limit寄存器分别确定了其所有分支下设备（The device that live beneath this bridge）的地址的起始和结束地址。
(Type0 的Bar的LSB几位会指示MM/IO,P/NP，OS向BAR的MSB写入设置其范围)。根据请求类型的不同，分别对应不同的Limit&Base组合：

* Prefetchable Memory Space（P-MMIO）
* Non- Prefetchable Memory Space（NP-MMIO）
* IO Space（IO）

一旦该桥分支下面的任意设备的BAR发生改变，该桥的Base&Limit寄存器也需要做出对应的改变。

下面以一个简单的例子，来分析一下：

![PCIe_Base_and_Limit_reg2](PCIe_Base_and_Limit_reg2.png)

如上图所示，连接到Switch的PortB上的PCIe Endpoint分别配置了NP-MMIO、P-MMIO和IO空间。
下面来简单地分析一下PortB的Header中的Base & Limit 寄存器。


**P-MMIO Base & Limit**

![PCIe_Base_and_Limit_reg3](PCIe_Base_and_Limit_reg3.png)


**NP-MMIO Base & Limit**

![PCIe_Base_and_Limit_reg4](PCIe_Base_and_Limit_reg4.png)

需要注意的是，Endpoint的需要的NP-MMIO的大小明明只有4KB，PortB的Header却给其1MB的空间（最小1MB），
也就是说剩余的空间都将会被浪费掉，并且其他的Endpoint都将无法使用这一空间。


**IO Base & Limit**

![PCIe_Base_and_Limit_reg5](PCIe_Base_and_Limit_reg5.png)

注：IO空间可分配的最小值为4KB，最大值则取决于操作系统和BIOS。


**Unused Base and Limit Registers**

很多情况下，我们并不需要所有的地址空间类型，比如所在某一个Endpoint中没有使用IO Space。
此时，其对应的桥的Header会把Base的地址设置为大于Limit的地址，也就是把地址范围设置为无效。


**一个完整的例子如下图所示：**

![PCIe_Base_and_Limit_reg6](PCIe_Base_and_Limit_reg6.png)

