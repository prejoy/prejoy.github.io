---
title: 'syslinux and extlinux'
date: 2022-11-25 15:58:46 +0800
categories: [BootLoader]
tags: [extlinux]
published: true
---

# syslinux and extlinux

what is syslinux : <https://www.makeuseof.com/syslinux-bootloader-file-structure/>  
about syslinux on wiki : <https://en.wikipedia.org/wiki/SYSLINUX>  

Syslinux has two meanings. 
* The first is the operating system bootloader, which uses the Linux kernel on IBM-compatible computers. 
* The second is the SYSLINUX bootloader used in the FAT file system. 

Most of the time you can see both Syslinux and SYSLINUX used interchangeably. There is a misunderstanding here. To clarify, Syslinux is for IBM-compatible systems, whereas SYSLINUX is for the FAT file system.

syslinux有两种解释，一个是特指 IBM兼容机器的BootLoader（Syslinux），可以认为是内置的。（这个意义先这样用的用过不多了）。另一个是一种BootLoader软件（SYSLINUX），只能安装用在FAT文件系统中。 Syslinux is for IBM-compatible systems, whereas SYSLINUX is for the FAT file system. **不过二者很容易混淆**，不用太在意名称大小写。一般是指第二种释义（一个linux的BootLoader程序，运行在FAT文件系统上的，可能grub一般运行在ext文件系统上吧）。


There are four different types of Syslinux bootloaders:

* SYSLINUX: Installs on FAT file systems
* EXTLINUX: Installs on ext, btrfs, FAT, NTFS, XFS, UFS, and HFS file systems
* ISOLINUX: Installs on CDs and DVDs
* PXELINUX: A type of network bootloader

syslinux实际有4个变种，其中extlinux几乎就是syslinux的扩展，它在功能和使用上和syslinux兼容，而且它还可以安装在ext，xfs，hfs等其他文件系统上，属于扩展了。


## EXTLINUX

<https://wiki.syslinux.org/wiki/index.php?title=EXTLINUX>  
<https://linux.die.net/man/1/extlinux>  


EXTLINUX is a general-purpose bootloader, similar to LILO or GRUB. Since Syslinux 4, EXTLINUX is capable of handling Btrfs, FAT, NTFS, UFS/UFS2, and XFS filesystems.

EXTLINUX is a Syslinux variant which boots from a Linux filesystem.

EXTLINUX supports:
* [3.00+] ext2/3,
* [4.00+] FAT12/16/32, ext2/3/4, Btrfs,
* [4.06+] FAT12/16/32, NTFS, ext2/3/4, Btrfs,
* [5.01+] FAT12/16/32, NTFS, ext2/3/4, Btrfs, XFS,
* [6.03+] FAT12/16/32, NTFS, ext2/3/4, Btrfs, XFS, UFS/FFS,

It works the same way as SYSLINUX, with a few slight modifications.


----

小结：就是要一个BootLoader程序，现在用的应该不多。在现代的uboot中，支持了extlinux,extlinux有一个配置文件，/boot/extlinux/extlinux.conf。
不知道是uboot 作了chain loading 二次启动extlinux 还是 uboot自己实现了一个兼容的简单的extlinux？