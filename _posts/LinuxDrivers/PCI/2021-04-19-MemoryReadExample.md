---
title: PCIe Memory Read Example
categories: [Drivers, PCI]
tags: [ PCIe, PCI ]
pin: false
published: true
img_path: /assets/img/postimgs/LinuxDrivers/PCI/
---

这里以MRd包为例：
如下图所示，Requester的应用层（软件层）首先向其事务层发送如下信息：
32位（或者64位）的Memory地址，
事务类型（Transaction Type）（Mrd，Mwr，IORd，IOWr，Cfg，Message等），
数据量（以DW为单位）（这里是MRd，所以有数据量），
TC（Traffic Class，即优先级），
字节使能（Byte Enable）和
属性信息（Attributes）等。


![PCIeMemoryReadExample](PCIeMemoryReadExample.png)


然后接收端的事务层（应用层在4层，把请求发到本地的3层事务层）使用这些信息创建了一个Mrd TLP（Memory Read的事务层包），
并将Requester的ID（BDF，Bus & Device & Function）写入到该TLP的Header中，
以便Completer根据这一BDF将Completion信息返回给Requester。
然后这个TLP会根据其TC的值被放到对应的VC Buffer中，Flow Control逻辑便会检测接收端的对应的接收VC Buffer空间是否充足。
一旦接收端的VC Buffer空间充足，TLP便会准备被向接收端发送。

注：TLP的Header实际上有两种，32位的地址对应的是3DW的Header，64为的地址对应的是4DW的Header。

当TLP到达数据链路层（Data Link Layer）时候，数据链路层会为其添加上12位的序列号（Sequence Number）和32位的LCRC。
并将添加上这些信息之后的TLP（即DLLP）在Replay Buffer中做一个备份，并随后将其发送至物理层。

物理层接收到DLLP之后，为其添加上起始字符（Start & End Characters，又叫帧字符，Frame Characters），
然后依次进行解字节（Strip Byte）、扰码（Scramble）、8b/10b编码并进行串行化，随后发送至相邻的PCIe设备的物理层。

接收端PCIe设备（即Completer）的物理层接收到数据之后，依次执行与发送端相反的操作。并从数据中恢复出时钟，然后将恢复出来的DLLP发送至数据链路层。

Completer的数据链路层首先检查DLLP中的LCRC，如果存在错误，则向Requester发送一个Nak类型的DLLP，
该DLLP包含了其接受到的DLLP中的序列号（Sequence Number）。Requester的数据链路层接收到来自Completer的Nak DLLP之后，
从中找到序列号（Sequence Number），并根据序列号在Replay Buffer找到对应的DLLP，然后将其重新发送至Completer。
如果Completer的数据链路层没有检查到LCRC的错误，也会向Requester发送一个Ack类型的DLLP，该DLLP同样包含了其接收到的DLLP中的序列号。
Requester的数据链路层接收到之一Ack DLLP之后，便会根据其中的序列号在Replay Buffer中找到对应的DLLP的备份，并将其丢弃（Discard）。


当接收端PCIe设备（即Completer）的数据链路层正确的接收到了来自Requester的DLLP（包含TLP的）时，
随后将其进一步发送至事务层，事务层检查ECRC（可选的），并对TLP进行解析，然后将解析后的信息发送至应用层（软件层）。

如下图所示，Completer的应用层会根据接受到的信息进行相应的处理，处理完成后会将数据发送至事务层，
事务层根据这一信息创建一个新的TLP（即CplD，Completion with data）。并根据先前接收到的TLP中的BDF信息，找到原来的Requester，
然后将CplD发送至该Requester。这一发送过程与Requester向Completer发送TLP（Mrd Request）的过程基本是一致的。所以这里就不在重复了。

注：如果Completer不能够返回有效数据给Requester，或者遇到错误，则其返回的就不是CplD了，
而是Cpl（Completion without data），Requester接收到Cpl的TLP之后便会知道发生了错误，其应用层（软件层）会进行相应的处理。

![PCIeMemoryReadExample2](PCIeMemoryReadExample2.png)


