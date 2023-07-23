通用驱动部分：

内核通知链机制。 （ notifier call chain ）

驱动-热拔插  搜索 MODULE_DEVICE_TABLE 的用途，不是很常见，可以简单记录即可。

udev概念 ，根据帖子实践


需要校正：

计划任务 cron 和 at  --  “有一些alias可以替代前面的5个时间” 表格格式不对



## 文章同步
文章 腾讯云，桌面截图参考
博客园（还可以自定义样式，自定义 JS 脚本）
知乎 
腾讯云开发者+微信公众号

## later

kernel crash debug later to note （fav） aaddr2line

2023-04-18-串口设备文件( ttyUSB ttyS ttyACM ) 记录一些区别， tag  串口相关

容器技术  vs   虚拟化技术  （容器和虚拟化技术不同，分别记录了解）

构建系统 ninja 和 meson（cmake 暂时不更新，需要时再记录）

Devicetree Overlays 设备树覆盖机制 <https://www.kernel.org/doc/html/latest/devicetree/index.html>

## lalater


later freest yocto uasge

ffmpeg分离音视频

《深入理解UNIX系统内核》 [UNIX Internals: The New Frontiers]

ramdisk ramfs tmpfs 比较，各自特点

专栏： https://www.zhihu.com/column/c_1108400140804726784

linux-shell工具 `whiptail` ，一种交互式的shell脚本对话框，比如menuconfig应该就是这样实现的，
它实现了基于文本的类图形界面，在终端上显示，可以用于制作配置工具。它定义了一些组件，使用时需要编程。可以参考：  
[交互式shell脚本对话框----whiptail指令](https://www.cnblogs.com/panyouming/p/8511022.html)  
[基于whiptail和shell脚本的交互式界面](https://blog.csdn.net/lj1158137735/article/details/99059300)   

linux-访问控制工具 `getfacl`，`setfacl` 。安装： `sudo apt install acl` ，ACL权限控制（access control list）是
在UGO权限管理的基础上的一个补充。因为经典的UGO权限控制有点宽，如果一个属于O（其他）的权限是r，但是有个特殊的用户，他属于O组，
但是他又需要rw权限，那么传统的UGO就无法实现（无法对具体某个特定用户设置特定权限），如果把整个O组的权限改为rw又把权限放太大了。
而ACL作为传统UGO机制的一个补充，就是解决这类问题，可以**实现特定的某个用户或组的单独权限**，而不影响其他用户或组的权限。有点
类似VIP用户机制。用法参考：  
[ACL权限是什么，Linux ACL访问控制权限（包含开启方式）](http://c.biancheng.net/view/3120.html)  
[Linux ACL权限设置（setfacl和getfacl）](http://c.biancheng.net/view/3132.html)  
[Linux ACL访问控制权限介绍及用法（转）](https://zhuanlan.zhihu.com/p/112210862)  
[Linux的ACL规则设置——setfacl及getfacl命令的使用详解](https://blog.csdn.net/cheng198956/article/details/100960490)  

linux上的虚拟机管理工具，`vagrant`是一个命令行的工具，通过命令行管理虚拟机，了解即可。主要解决团队成员搭建相同的开发环境问题。现在应该也可以使用docker等方式。

shell脚本使用
    linux 文件名，路径相关工具，  `basename  dirname  realpath  readlink`
    linux bash 内置目录管理工具，  `pushd ,popd ,dirs` 可以将目录压栈，弹栈，和查看，使用 `help pushd`查看帮助，一般可以用在脚本中。

orange pi pc 镜像构建学习
    仓库地址，使用这个老的，有个新的好像是给aarch64用的。
    <https://github.com/orangepi-xunlong/orangepi-build>
    查看官方镜像具体生成步骤，然后在自己从一个个组件制作。
    记录分段式的qemu和模拟整个SD卡的qemu启动，成功就完结了。   XXX 这个不行，还是用基于SD的整体模拟方式
    （以把文件当做sd卡，然后把 uboot，kernel，dtb，rootfs都放卡上）
    后面再记录orangepi的各个组件构建过程和镜像制作。同时以自己的设备树机制为主，这个镜像构建为辅，
    这个镜像构建也比较复杂。中间还会需要测试debootstrap，dpkg等东西。按需做记录

# passed 

V bash 自定义function键 意义，用户简化常用输入命令
V bash  env




怎样成为一名优秀的Linux驱动设备工程师？

作者：匿名用户
链接：https://www.zhihu.com/question/302236329/answer/3027444921
来源：知乎
著作权归作者所有。商业转载请联系作者获得授权，非商业转载请注明出处。

给你的建议，不要看书，有了基础还看书完全是浪费生命！！我当年写linux第一个驱动只花了两天，如果你操作系统原理非常扎实，知道中断或进程调度的详细过程，那么你很容易上手linux驱动开发。再说一句，不要看那些垃圾书，看官方文档，并实际操作，一定要多上手实际操练。并且看那些同类型的开源驱动到底是如何做的。

Linux内核文档：https://www.kernel.org/doc/html/latest/index.html

Linux设备驱动程序开发指南：https://www.kernel.org/doc/html/latest/driver-api/

Linux内核api：https://www.kernel.org/doc/html/latest/core-api/index.htmlUSB

驱动程序开发指南：https://www.kernel.org/doc/html/latest/driver-api/usb/PCI

驱动程序开发指南：https://www.kernel.org/doc/html/latest/driver-api/pci/I2C

驱动程序开发指南：https://www.kernel.org/doc/html/latest/driver-api/i2c.html

非官方的推荐[Linux 内核模块编程指南](https://sysprog21.github.io/lkmpg/)