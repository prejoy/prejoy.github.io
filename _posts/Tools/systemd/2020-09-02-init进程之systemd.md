---
title: 'init进程--systemd'
date: 2020-09-02 11:33:42 +0800
categories: [Tools, systemd]
tags: [systemd]
published: true
img_path: /assets/img/postimgs/Tools/systemd/
---

# 第一个进程

Linux系统启动的第一个进程，传统的就是init进程，也被称为SysV init启动系统。特点的串行启动，现代的linux一般使用systemd代替init启动进程，
并行启动，速度快，但更加庞大复杂。中间也出现过upstart启动进程，在Ubuntu上使用过，（Ubuntu15后就是用systemd代替了upstart），
systemd启动效率比upstart更佳。（主要是Linux在移动平台上广泛使用，对启动速度有要求，systemd就是模仿了IOS的launchd，一种并行的启动方式），
现代linux发行版基本都采用了systemd作为启动进程。
如centos7，查看init进程：

![查看init进程](systemd-loc.png)


# systemd程序

它是目前（2020）常见的引导和服务管理程序，如centos7，ubuntu18中，已经用systemd代理了传统的SysV init，启动过程将交给systemd处理。
**Systemd的一个核心功能是它同时支持SysV init的后开机启动脚本。**


Systemd引入了并行启动的概念（sysV的init是串行的），它会为每个需要启动的守护进程建立一个套接字，这些套接字对于使用它们的进程来说是抽象的，
这样它们可以允许不同守护进程之间进行交互。Systemd会创建新进程并为每个进程分配一个*控制组（cgroup）*。处于不同控制组的进程之间可以通过内核来互相通信。
Systemd的一些核心功能。

* 和init比起来引导过程简化了很多
* Systemd支持并发引导过程从而可以更快启动
* 通过控制组来追踪进程，而不是PID
* 优化了处理引导过程和服务之间依赖的方式
* 支持系统快照和恢复
* 监控已启动的服务；也支持重启已崩溃服务
* 包含了systemd-login模块用于控制用户登录
* 支持加载和卸载组件
* 低内存使用痕迹以及任务调度能力
* 记录事件的Journald模块和记录系统日志的syslogd模块

Systemd同时也清晰地处理了系统关机过程。它在/usr/lib/systemd/目录下有三个脚本，分别叫systemd-halt.service，systemd-poweroff.service，
systemd-reboot.service。这几个脚本会在用户选择关机，重启或待机时执行。在接收到关机事件时，systemd首先卸载所有文件系统并停止所有内存交换设备，
断开存储设备，之后停止所有剩下的进程。


> cgroups:Cgroups全称Control Groups，是Linux内核提供的物理资源隔离机制，通过这种机制，可以实现对Linux进程或者进程组的资源限制、隔离和统计功能。
> Cgroup是于2.6内核由Google公司主导引入的，它是Linux内核实现资源虚拟化的技术基石，LXC(Linux Containers)和docker容器所用到的资源隔离技术，正是Cgroup。
> 参考：[浅谈Linux Cgroups机制](https://zhuanlan.zhihu.com/p/81668069)
{: .prompt-info }


# Systemd启动过程概览

1. 当你打开电源后电脑所做的第一件事情就是BIOS初始化。BIOS会读取引导设备设定，定位并传递系统控制权给MBR（假设硬盘是第一引导设备）。

2. MBR从Grub或LILO引导程序读取相关信息并初始化内核。接下来将由Grub或LILO继续引导系统。如果你在grub配置文件里指定了systemd作为引导管理程序，
   之后的引导过程将由systemd完成。Systemd使用“target”来处理引导和服务管理过程。这些systemd里的“target”文件被用于分组不同的引导单元以及启动同步进程。

3. **systemd执行的第一个目标是default.target。**但实际上default.target是指向graphical.target的软链接。Linux里的软链接用起来和Windows下的快捷方式一样。
   文件Graphical.target的实际位置是/usr/lib/systemd/system/graphical.target。在下面的截图里显示了graphical.target文件的内容。依赖multi-user.target。  
   ![启动过程概览1](p230308i1.png)  
   注意：在ubuntu1804版本中， /usr/lib/systemd 和 /lib/systemd 已经不是同一个目录，上文的在 /lib/systemd 中，
   具有system的启动配置文件于目录/lib/systemd/system ,而/usr/lib/systemd/ 中只有用户级的启动配置文件 于/usr/lib/systemd/user/ 中。
   而centos7 则是 /usr/lib/systemd 和 /lib/systemd 目录都是一样的，然后 system 和 user 的启动配置文件都在同一个目录级，两个目录居然是两份相同的文件？

4. 在这个阶段，会启动multi-user.target而这个target将自己的子单元放在目录“/etc/systemd/system/multi-user.target.wants”里。
   这个target为多用户支持设定系统环境。非root用户会在这个阶段的引导过程中启用。防火墙相关的服务也会在这个阶段启动。
   "multi-user.target"会将控制权交给另一层“basic.target”。
   ![启动过程概览2](p230308i2.png)  
   ![启动过程概览3](p230308i3.png)  

5. "basic.target"单元用于启动普通服务特别是图形管理服务。它通过/etc/systemd/system/basic.target.wants目录来决定哪些服务会被启动，basic.target之后将控制权交给sysinit.target.
   ![启动过程概览4](p230308i4.png)  

6. "sysinit.target"会启动重要的系统服务例如系统挂载，内存交换空间和设备，内核补充选项等等。sysinit.target在启动过程中会传递给local-fs.target。这个target单元的内容如下面截图里所展示。
   ![启动过程概览4](p230308i4.png)  

7. local-fs.target，这个target单元不会启动用户相关的服务，它只处理底层核心服务。这个target会根据/etc/fstab和/etc/inittab来执行相关操作。


部分参考: <https://blog.csdn.net/a617996505/article/details/88423794>


# systemd 相关文档

[systemd github](https://github.com/systemd/systemd)

Most documentation is available on [systemd's web site](https://systemd.io/).

Assorted, older, general information about systemd can be found in the [systemd Wiki](https://www.freedesktop.org/wiki/Software/systemd).

[fedora-Understanding and administering systemd](https://docs.fedoraproject.org/en-US/quick-docs/understanding-and-administering-systemd/index.html)  

