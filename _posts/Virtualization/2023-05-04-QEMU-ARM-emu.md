---
title: 'QEMU-Arm System emulator'
categories: [Virtualization]
tags: [qemu]
img_path: /assets/img/postimgs/Virtualization/
---


# 概述

QEMU可以模拟32位和64位Arm cpu。32为的arm架构使用 `qemu-system-arm` 工具，64位的aarch64架构使用
`qemu-system-aarch64`进行模拟。二者的命令行参数基本是通用的。

QEMU对Arm的支持较好，有较多的arm机器可以支持，毕竟arm硬件差异性比x86架构更多。Arm CPU通常被内置在SOC芯片中，
不同公司创建出不同的SOC芯片，并进一步放置在不同机器上，即使是相同的SOC，由于机器（底板）差异，种类也可以用有很多。
64位的Arm也相似。在QEMU中，大约实现了50中开发版的模拟，但也远小于实际的硬件情况。

QEMU主要支持arm的cortex-a系列，m系列和r系列qemu也支持。对于大多数demoboard，CPU类型是固定的，所以通常不需要
手动指定CPU类型，除非使用特殊的virt类型的demoboard。


## Choosing a board model

对于qemu模拟arm的情况，需要手动指定board model，没有默认值的，使用 `-M` 或 `--machine` 指定需要模拟的开发板。

由于arm系统差异很大，一个编译好的arm镜像（固件），换一个开发板环境通常就不能正常运行，这和x86相差很大，x86上基本
都是个标准PC，软件不太关注硬件。

如果使用qemu模拟一个arm系统，请确保编译环境使用的设备是在qemu支持的*machine*中的。


如果不关心复制特定硬件的特性，例如少量RAM，没有PCI或其他硬盘等，并且只想运行Linux，那么最好的选择是使用*virt board*。
这是一个不对应于任何实际硬件的平台，是为在虚拟机中使用而设计的。只需要编译带有合适配置的Linux，以便在虚拟机板上运行。
virt支持PCI, virtio，最新的cpu和大量的RAM。它还支持64位cpu。


## 查看支持的开发板
使用命令查看当前版本的qemu所支持的所有machine。
```bash
qemu-system-aarch64 --machine help
```
以7.2.1为例，可以看到几个熟悉的machine：

|        Machine       |        Description                                 |
| -------------------- | -------------------------------------------------- |
| cubieboard           |  cubietech cubieboard (Cortex-A8)                  |
| mcimx6ul-evk         |  Freescale i.MX6UL Evaluation Kit (Cortex-A7)      |
| mcimx7d-sabre        |  Freescale i.MX7 DUAL SABRE (Cortex-A7)            |
| orangepi-pc          |  Orange Pi PC (Cortex-A7)                          |
| raspi3b              |  Raspberry Pi 3B (revision 1.2)                    |
| smdkc210             |  Samsung SMDKC210 board (Exynos4210)               |
| vexpress-a9          |  ARM Versatile Express for Cortex-A9               |
| stm32vldiscovery     |  ST STM32VLDISCOVERY (Cortex-M3)                   |
| virt-7.2             |  QEMU 7.2 ARM Virtual Machine                      |
| xilinx-zynq-a9       |  Xilinx Zynq Platform Baseboard for Cortex-A9      |
| xlnx-versal-virt     |  Xilinx Versal Virtual development board           |
| xlnx-zcu102          |  Xilinx ZynqMP ZCU102 board 4xA53 and 2xR5F , smp  |

这里模拟测试 `orangepi-pc` 开发板。


# 可选-编译器安装

根据需要安装相关的编译工具
```bash
sudo apt install gcc-arm-linux-gnueabi          # cortex-a linux通用
# sudo apt install gcc-arm-linux-gnueabihf      # arm 带硬件浮点计算单元 fpu的，可以使用这个加速浮点计算
# sudo apt install gcc-arm-none-eabi            # 可以用来编译arm 裸机程序，不和linux相关的，Cortex-M 和 Cortex-R比较适用

sudo apt install gcc-aarch64-linux-gnu         # arm64 编译器，armv8-a，如 a53，a72
```


# 测试模拟 orangepi-pc 开发板

国产开发板，参考资料也比较丰富。SOC芯片使用Allwinner H3 即 **全志H3**芯片。

官方资料参考 [Orange Pi PC官方介绍](http://www.orangepi.cn/html/hardWare/computerAndMicrocontrollers/details/Orange-Pi-PC.html)  
qemu资料参考 [Orange Pi PC (orangepi-pc)](https://www.qemu.org/docs/master/system/arm/orangepi.html)  

qemu已支持模拟的外设包括：

* SMP (Quad Core Cortex-A7)
* Generic Interrupt Controller configuration
* SRAM mappings
* SDRAM controller
* Real Time Clock
* Timer device (re-used from Allwinner A10)
* UART
* SD/MMC storage controller
* EMAC ethernet
* USB 2.0 interfaces
* Clock Control Unit
* System Control module
* Security Identifier device


## 直接机器模拟

模拟的Orange Pi PC 开发板支持从SD卡加载BootLoader，就这像真实使用BootROM的开发板从SD启动一样，可以直接将系统镜像制作好后通过SD卡模拟启动。
在qemu-system-arm中可以使用文件来模拟SD卡。这样就仅使用 `-sd` 参数指定sd卡文件即可，不需要 `-kernel,-append,-dtb,-initrd`这些参数。

下载一个armbian镜像：从<https://www.armbian.com/orange-pi-pc/>下载命令行镜像Armbian 23.02 Jammy。
镜像文件：`Armbian_23.02.2_Orangepipc_jammy_current_5.15.93.img.xz`。该镜像包含了uboot，kernel，initrd，dtb和armbian根文件系统，
是一个制作好的SD卡镜像。可以在qemu中直接模拟运行。

**模拟运行armbian镜像**  
```bash
# 先解压压缩的镜像
xz -d ./Armbian_23.02.2_Orangepipc_jammy_current_5.15.93.img.xz

# 拓展镜像文件到2G或4G，qemu要求
truncate -s 2G ./Armbian_23.02.2_Orangepipc_jammy_current_5.15.93.img

# 模拟
sudo ./qemu-system-arm \
    -M orangepi-pc \
    -nic user \
    -nographic \
    -sd /path/to/Armbian_23.02.2_Orangepipc_jammy_current_5.15.93.img
```

`-nic user`需要编译qemu时，添加配置支持，这里可以去掉，就没有网络。

进入系统后查看一些信息。使用（root:root 登录）
```
root@orangepipc:~# cat /proc/cmdline 
root=UUID=705b28eb-7ba5-481e-ac44-cb93d2cfd612 rootwait rootfstype=ext4 splash=verbose console=ttyS0,115200 console=tty1 hdmi.audio=EDID:0 disp.screen0_output_mode=1920x1080p60 consoleblank=0 loglevel=1 ubootpart=22ff4bb3-01 ubootsource=mmc usb-storage.quirks=   sunxi_ve_mem_reserve=0 sunxi_g2d_mem_reserve=0 sunxi_fb_mem_reserve=16 cgroup_enable=memory swapaccount=1

root@orangepipc:~# df -h
Filesystem      Size  Used Avail Use% Mounted on
tmpfs           100M  3.2M   97M   4% /run
/dev/mmcblk0p1  1.9G  1.5G  278M  85% /
tmpfs           500M     0  500M   0% /dev/shm
tmpfs           5.0M  4.0K  5.0M   1% /run/lock
tmpfs           500M     0  500M   0% /tmp
/dev/zram3       47M 1020K   43M   3% /var/log
tmpfs           100M     0  100M   0% /run/user/0

root@orangepipc:~# free -h
               total        used        free      shared  buff/cache   available
Mem:           999Mi        89Mi       775Mi       3.0Mi       133Mi       882Mi
Swap:          999Mi          0B       999Mi

root@orangepipc:~# ls /boot/
armbianEnv.txt			initrd.img-5.15.93-sunxi
armbian_first_run.txt.template	overlay-user
boot.bmp			System.map-5.15.93-sunxi
boot.cmd			uInitrd
boot.scr			uInitrd-5.15.93-sunxi
config-5.15.93-sunxi		vmlinuz-5.15.93-sunxi
dtb				zImage
dtb-5.15.93-sunxi

root@orangepipc:~# cat /etc/fstab 
UUID=705b28eb-7ba5-481e-ac44-cb93d2cfd612 / ext4 defaults,noatime,commit=600,errors=remount-ro 0 1
tmpfs /tmp tmpfs defaults,nosuid 0 0
```

可以用来模拟运行一些上层应用程序，比较方便了。


**使用官方镜像（debian）**

克隆官方编译环境仓库： <https://github.com/orangepi-xunlong/orangepi-build>

运行build.sh，构建完整镜像。流程较长，会在主机上安装完整的编译环境，工具，编译工具链等，下载各组件源码，编译，打包，安装。
最后完成后构建出 `Orangepipc_2.2.2_debian_buster_server_linux5.4.65.img`镜像文件，
各个组件文件也都有，包括`u-boot,zImage,sun8i-h3-orangepi-pc.dtb,buster-cli-armhf.tar.lz4`等。

```bash
truncate -s 2G ./Orangepipc_2.2.2_debian_buster_server_linux5.4.65.img 

sudo ./qemu-system-arm \
  -M orangepi-pc   \
  -nographic \
  -sd /path/to/Orangepipc_2.2.2_debian_buster_server_linux5.4.65.img
```

使用orangepi:orangepi 登录。

## 常规模拟

使用`-kernel,-append,-dtb,-initrd`等参数指定关键文件。

直接指定rootfs在sd卡上，不使用initrd。

arm-linux-gnueabihf-gcc 版本：gcc version 9.4.0 (Ubuntu 9.4.0-1ubuntu1~20.04.1)
为kernel添加mmc驱动，直接编译进内核，同时将ext4文件系统编译进内核，这个是默认的。
```bash
cd orangepi-build/kernel/orange-pi-5.4
# 好像是这个默认配置，可能能是orangepi_defconfig
# 之前已经使用官方的build脚本配置过了
# make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- sunxi_defconfig   
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- menuconfig

# 将这个编译进内核
# Device Drivers  ---> MMC/SD/SDIO card support  --->  <*> Secure Digital Host Controller Interface support

# 编译和安装
make && make install
```

之后完善rootfs，参考 busybox根文件系统 ，另外可以安装内核的模块到根文件系统，利用loop device制作好rootfs.img。


```
# 安装好内核模块
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- modules_install INSTALL_MOD_PATH=/path/to/myrootfs

# losetup制作rootfs.img
losetup -Pf  ./rootfs.img
# 查看对应的loop 设备
losetup -a 

# 之后为loop 设备建立msdos分区表，格式化ext4文件系统，挂载，拷贝，卸载。。。

# 模拟启动
sudo ./qemu-system-arm -M orangepi-pc -nographic -kernel /path/to/zImage -append 'console=ttyS0,115200  root=/dev/mmcblk0p1'  -dtb /path/to/sun8i-h3-orangepi-pc.dtb -sd /path/to/busybox-1.34.1/rootfs.img
```

启动后无法识别 `/dev/mmcblk0` ，导致无法挂载根文件系统。不确定原因，无法找到模拟的SD卡。

改用initrd临时作为rootfs运行。在kernel配置中打开 `RAM block device support`支持，
重新编译内核，然后制作好 initrd.gz,可以运行，但确实无法识别模拟的SD卡，不确定原因。

```
# 使用相同的rootfs制作initrd.gz  。。。

sudo ./qemu-system-arm -M orangepi-pc -nographic -kernel /path/to/zImage -append 'console=ttyS0,115200 root=/dev/ram0 rw rootfstype=ext4 init=/linuxrc' -dtb /path/to/sun8i-h3-orangepi-pc.dtb  -initrd /path/to/busybox-1.34.1/armramdisk.gz   -sd /path/to/busybox-1.34.1/rootfs.img
```

启动后确实找不到 `/dev/mmcblk*`，不确定是否是qemu模拟问题。还是使用第一种方式。





# 测试模拟 vexpress-a9 开发板

使用的组件：  
uboot : v2020.10 <https://github.com/u-boot/u-boot/releases/tag/v2020.10>  
dts in uboot : vexpress-v2p-ca9.dts (default)   
kernel : linux-5.4.241  

**uboot**  
```bash
# 编译
cd u-boot-2020.10
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- vexpress_ca9x4_defconfig
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- -j20
# 测试运行u-boot
qemu-system-arm -M vexpress-a9 -kernel ./u-boot -nographic -m 512M 
```

vexpress-a9可以启动u-boot了，同样，使用orangepi-pc的uboot测试模拟的orangepi-pc，就不行，应该是和qemu模拟器邮有关。


**kernel**  

下载了内核linux-5.4.241。
```bash
# config
make -C ./linux-5.4.241/ O=./Vexpress-a9x4/ ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- vexpress_defconfig

#build
make -C ./linux-5.4.241/ O=./Vexpress-a9x4/ ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- -j20
```

编译的输出目录为 `./linux-5.4.241/Vexpress-a9x4/`。kernel文件`./arch/arm/boot/zImage`,
dtb文件`arch/arm/boot/dts/vexpress-v2p-ca9.dtb`。已经可以测试运行了，但由于没有文件系统会停止。

```
sudo qemu-system-arm -M vexpress-a9 -m 512M -kernel ./arch/arm/boot/zImage -dtb arch/arm/boot/dts/vexpress-v2p-ca9.dtb -nographic -append "console=ttyAMA0"
```

**rootfs**

这里简单使用`busybox-1.34.1`来构建，也可以使用其他的buildroot，yocto，debootstrap等。

```bash
cd busybox-1.34.1

make menuconfig
# 设置一下交叉编译器 Settings   ---> (arm-linux-gnueabihf-) Cross compiler prefix
# 这里测试使用动态库（默认），也可以使用静态库
# 保持默认

make 
make install
# 确实是arm机器指令的程序
file ./_install/bin/busybox 
# ./_install/bin/busybox: ELF 32-bit LSB shared object, ARM, EABI5 version 1 (SYSV), dynamically linked, interpreter /lib/ld-linux-armhf.so.3, BuildID[sha1]=97249a079f5f647ca1209d542de752c6a7386fe5, for GNU/Linux 3.2.0, stripped


mkdir rootfs_arm
sudo cp -rpf ./_install/* ./rootfs_arm/
# 完善一下根文件系统，参考 busybox根文件系统

#  动态库，拷贝一些交叉编译器的库文件
sudo cp /usr/arm-linux-gnueabihf/lib/* ./lib/
# sudo cp /usr/arm-linux-gnueabihf/include/* ./usr/include/

# 进入内核构建的目录，安装内核模块，并返回
cd /path/to/linux-5.4.241/Vexpress-a9x4
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- modules_install INSTALL_MOD_PATH=/path/to/rootfs_arm
# 好像一个没有
cd -


# 完成，将rootfs_arm 制作为img，这里就使用简单的loop设备，不带分区了
dd if=/dev/zero of=./rootfs.img bs=1G count=1
mkfs.ext4  ./rootfs.img
mkdir -p ./for_mount/
sudo mount -o loop,rw ./rootfs.img ./for_mount/
sudo cp -rpf ./rootfs_arm/* ./for_mount/
sudo umount for_mount 
```

**常规启动方式**  
可以测试启动了，使用 `-kernel,-dtb`等参数指定相关文件，启动参数需要指定`root=`指定根文件设备，和`init=`启动进程，
这里内核里应该已经编译进SD卡驱动，ext4文件系统了。
```
cd /path/to/linux-5.4.241/Vexpress-a9x4
sudo qemu-system-arm \
  -M vexpress-a9 -m 512M -nographic \
  -kernel arch/arm/boot/zImage \
  -dtb arch/arm/boot/dts/vexpress-v2p-ca9.dtb \
  -append "console=ttyAMA0 root=/dev/mmcblk0 rw init=/linuxrc" \
  -sd /path/to/busybox-1.34.1/rootfs.img
```

启动成功，这种方式可以方便替换内核和设备树文件，且不需要uboot来加载引导内核，也可以通过uboot来引导，将内核，设备树和根文件系统都放在SD卡镜像上。


**将内核，设备树和根文件系统都放在SD卡镜像上的方式**

需要将内核和设备树相关文件放到SD卡镜像中。
```bash
# 将zImage和vexpress-v2p-ca9.dtb文件拷贝到 rootfs_arm 目录中，重新制作镜像文件。
mkdir rootfs_arm/boot
cp ~/Downloads/linux-5.4.241/Vexpress-a9x4/arch/arm/boot/zImage ./rootfs_arm/boot/
cp ~/Downloads/linux-5.4.241/Vexpress-a9x4/arch/arm/boot/dts/vexpress-v2p-ca9.dtb ./rootfs_arm/boot/
# 重新制作 rootfs.img ......
```
然后重新使用uboot来引导：

```bash
cd /path/to/u-boot-2020.10
sudo /path/to/qemu-system-arm -M vexpress-a9 -m 512M -nographic -kernel ./u-boot -sd /path/to/busybox-1.34.1/rootfs.img
```
启动后，进入uboot交互界面，输入bdinfo命令查看板级信息，奥查看DRAM信息，等会儿需要加载kernel镜像和设备树
```
=> bdinfo 
boot_params = 0x60002000
DRAM bank   = 0x00000000
-> start    = 0x60000000
-> size     = 0x20000000
DRAM bank   = 0x00000001
-> start    = 0x80000000
-> size     = 0x00000004
memstart    = 0x60000000
memsize     = 0x20000000
flashstart  = 0x00000000
flashsize   = 0x08000000
flashoffset = 0x00000000
baudrate    = 38400 bps
relocaddr   = 0x7ff76000
reloc off   = 0x1f776000
Build       = 32-bit
current eth = smc911x-0
ethaddr     = 52:54:00:12:34:56
IP addr     = <NULL>
fdt_blob    = 0x00000000
new_fdt     = 0x00000000
fdt_size    = 0x00000000
arch_number = 0x000008e0
TLB addr    = 0x7fff0000
irq_sp      = 0x7fe75ee0
sp start    = 0x7fe75ed0
=> 
```

查看内核镜像文件，设备树文件，因为没有分区，所以是0:0
```
=> ext4ls mmc 0:0 boot/
<DIR>       4096 .
<DIR>       4096 ..
         4690528 zImage
           14143 vexpress-v2p-ca9.dtb
```

加载并启动，确认zImage解压后大小，不能出现覆盖，设置启动参数，然后启动。
```
# in u-boot
# load
ext4load mmc 0:0 0x60008000 boot/zImage
ext4load mmc 0:0 0x62000000 boot/vexpress-v2p-ca9.dtb
# boot
setenv bootargs "console=ttyAMA0 root=/dev/mmcblk0 rw init=/linuxrc"
bootz 0x60008000 - 0x62000000
```
启动成功。


**退出模拟**

在qemu中，一次输入`Ctrl+A ，X`，可以退出，不用外部kill。



# 小结

1. qemu模拟器模拟的开发板和模拟器的实现应该有关，和真实的硬件板是有差异的，尤其是底层和硬件方面，适合一些中上层通用部分的测试和调试。
  只要不涉及具体硬件，使用qemu模拟还好，还可以方便的调试。

2. 内核启动参数中使用的 console参数设置的tty不同，似乎是因为不同的机器配置，最后编译生成的串口设备名不同。


# 相关参考
[官网相关资料](http://www.orangepi.cn/html/hardWare/computerAndMicrocontrollers/details/Orange-Pi-PC.html)  
[官网github](https://github.com/orangepi-xunlong)  
[qemu doc](https://www.qemu.org/docs/master/system/arm/orangepi.html)    
