---
title: 'losetup管理loop设备'
categories: [Tools, Linux]
tags: [losetup,loop]
published: true
---


# 关于loop device

在Linux中，loop设备（回环设备）是一种虚拟块设备，这种技术可以实现将磁盘上的普通文件作为一个虚拟的块设备来使用，可以像对待一般的块设备一样来操作它。
可以轻松的在一个现有的文件系统中实现出一个虚拟的磁盘或文件系统。

该loop device的主要用途：

1. 制作/修改/调试 系统镜像，比如老的光盘ISO可以通过挂载为loop设备在主机上调试，制作文件系统，等制作好img镜像文件后，进行烧录。同样，还有嵌入式
   环境下常见的SD卡镜像（可以直接烧录的完整镜像），一般也是这样制作的。硬盘也同样可以。
2. 可以用来调试文件系统，将文件系统映射到一个loop设备上，可以对该文件系统进行调试和修复，而不影响实际硬件上的数据。
3. 安全隔离：通过使用loop设备，可以将应用程序运行在一个完全隔离的环境中，以保护主机系统的安全性。


可以通过 `ls  -l /dev/ | grep loop` 命令查看系统中挂载的loop设备，ubuntu系统中的snap就用了许多。


# losetup 工具

`losetup` 是 Linux 系统中用于设置与管理loop设备的命令行工具。使用较简单，`man losetup` 或 `losetup -h` 查看帮助。

测试之前，需要准备一个一定大小的文件，用于映射loop 设备。这里直接创建test.img 文件，大小为2GB
```bash
dd if=/dev/zero of=./test.img bs=1G count=2

# 或者
# touch ./test.img
# truncate -s 2G ./test.img

ls -lh ./test.img 
-rw-rw-r-- 1 user user 2.0G 5月   8 16:47 ./test.img
```


## 查看系统中的loop设备使用情况

使用`losetup -a`查看。
```console
# losetup -a
/dev/loop1: []: (/var/lib/snapd/snaps/core22_617.snap)
/dev/loop8: []: (/var/lib/snapd/snaps/snapd_18596.snap)
/dev/loop6: []: (/var/lib/snapd/snaps/core20_1879.snap)
/dev/loop13: []: (/var/lib/snapd/snaps/gnome-42-2204_102.snap)
...

```

## 创建loop设备

这里把刚刚创建的`test.img`作为loop块虚拟设备。需要将文件绑定到一个没有使用的loop设备，如果是手动绑定，需要先查看用了哪些loop设备，然后选一个没有用过
的loop设备来绑定，也可以自动查找绑定。创建loop设备后，可以在 `/dev` 目录下找到。

自动绑定，绑定后需要查看一下绑定到哪一个，方便后续操作
```console
# 将./test.img 绑定到loop设备
$ sudo losetup -f ./test.img 
$ losetup -a
...
/dev/loop2: []: (/home/user/test.img)
...
```

或者手动绑定，查看系统中未使用的，这里是15
```console
$ losetup -a
...
$ sudo losetup /dev/loop15 ./test.img 
```


**关于分区问题**

默认创建的loop设备是不支持分区操作的，可以对块设备格式化文件系统使用，但默认不支持分区。
像嵌入式环境制作系统镜像，通常需要都分区，所以在losetup绑定时需要额外指定参数以支持分区操作，否则会有奇怪的问题。

让loop设备支持分区，在绑定时加上`-P`参数即可

```
$ sudo losetup -Pf ./test.img
#check： /dev/loop2: []: (/home/user/test.img)

sudo parted /dev/loop2
    # 制作好分区
    #(parted) p                                                                
    #Model: Loopback device (loopback)
    #Disk /dev/loop2: 2147MB
    #Sector size (logical/physical): 512B/512B
    #Partition Table: msdos
    #Disk Flags: 
    #
    #Number  Start   End     Size    Type     File system  Flags
    # 1      1049kB  215MB   214MB   primary  ext4         lba
    # 2      215MB   2147MB  1933MB  primary  ext4         lba

# 现在就有分区了
$ ls /dev/loop2*
/dev/loop2  /dev/loop2p1  /dev/loop2p2

# 之后进行正常的格式化文件系统，挂载，读写，卸载等操作。。。
```


**卸载后操作**

完成umount卸载后，记得删除loop设备，（解决文件和loop设备的绑定关系）。参考 [删除loop设备](#删除loop设备)。


**关于直接mount的问题**

创建的test.img文件是可以直接在mount时作为loop device挂载的。参考：
```console
$ sudo mkfs.ext4 ./test.img 
$ mkdir mnt_point
$ sudo mount -o loop,rw ./test.img ./mnt_point/
$ lsblk
NAME        MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
loop0         7:0    0     4K  1 loop /snap/bare/5
loop1         7:1    0    73M  1 loop /snap/core22/617
loop2         7:2    0     2G  0 loop /home/user/mnt_point
```
直接使用mount挂载，主要问题是不支持分区。不如losetup更灵活。如果是制作系统镜像相关，就容易有问题。



## 删除loop设备

在umount后，记得删除loop设备，即解除文件和loop设备的绑定。使用 `-d` 参数。

```
$ losetup -a
...
/dev/loop2: []: (/home/user/test.img)
...
$ sudo losetup -d /dev/loop2 
```


# loop设备数量的限制

能创建的loop设备是有上限的，可以进行设置。
如果loop子系统是编译为内核模块的，则直接
```
cat 'options loop max_loop=64 > /etc/modprobe
```
指定一下最大数量即可。

如果loop子系统是直接编译进内核的，直接修改内核配置：
```
CONFIG_BLK_DEV_LOOP=y
CONFIG_BLK_DEV_LOOP_MIN_COUNT=8
```

或者启动时的参数设置，在启动参数添加 `max_loop=64` 即可设置。对于x86系统，一般使用grub引导，可以直接在grub配置中添加`GRUB_CMDLINE_LINUX="max_loop=64"`，并更新grub生效。


# 一个关于系统镜像的问题

遇到有一个系统镜像文件，大致是 debian.img.xz。 解压`xz -d` 之后，查看文件信息：
```
file ./debian.img
debian.img: DOS/MBR boot sector; partition 1 : ID=0x83, start-CHS (0x40,0,1), end-CHS (0x199,1,32), startsector 8192, 3976384 sectors


$ parted  ./debian.img p
WARNING: You are not superuser.  Watch out for permissions.
Model:  (file)
Disk debian.img: 2147MB
Sector size (logical/physical): 512B/512B
Partition Table: msdos
Disk Flags: 

Number  Start   End     Size    Type     File system  Flags
 1      4194kB  2040MB  2036MB  primary  ext4

```

可以看到，是有分区的，尽管只有一个分区。所以绑定loop设备时，需要加上 `-p` 参数，
```
sudo losetup -Pf ./debian.img
```
之后`losetup -a`查看loop 号码，并可以在 `/dev/`下看到该文件的分区，然后挂载具体分区就可以了。

如果直接设置loop设备时，没有支持分区，直接挂载，则会产生奇怪的错误：
```
NTFS signature is missing.
Failed to mount '/dev/loop20': Invalid argument
The device '/dev/loop20' doesn't seem to have a valid NTFS.
Maybe the wrong device is used? Or the whole disk instead of a
partition (e.g. /dev/sda, not /dev/sda1)? Or the other way around?
```
应该是文件系统识别错误，即使使用使用ext4文件系统挂载也不行。需要注意。