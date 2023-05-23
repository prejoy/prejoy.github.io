---
title: '关于ramdisk,ramfs,tmpfs及initrd,initramfs'
categories: [Rootfs]
tags: [busybox,rootfs,ramdisk,ramfs,tmpfs,initrd,initramfs]
published: true
---


主要记录 linux中的 ramdisk ，ramfs，tmpfs以及相关的initrd和initramfs。


# ramdisk

RAMDisk是一种虚拟磁盘技术，它将一部分系统内存（RAM）虚拟为硬盘，并允许用户在其中创建文件系统和存储数据等，具有*非常快的读写速度*，
因为它没有磁盘I/O的开销。相对的，数据将只存在于内存中，在系统重启后将不再存在，不适合保存需要持久存储的数据。

在ramdisk上可以实现任何其他文件系统，如ext。不过在Linux中，**通常使用tmpfs文件系统来格式化ramdisk**。tmpfs是一种特殊的文件系统，
它将文件存储在内存中，并且可以根据需要自动调整大小。这使得tmpfs可以与RAMDisk一样快，并且具有更好的可扩展性。

## ramdisk 使用示例

如果需要加速一些数据/目录的读写速度，可以把它们放在ramdisk中实现良好的加速。尤其是大量的小文件。

**默认ramdisk及容量限制**  
在ubuntu20.04中测试，ubuntu系统默认会使用一半的物理内存作为Ramdisk，并将其挂载在 `/dev/shm`。
```console
$ free -h
              total        used        free      shared  buff/cache   available
Mem:          125Gi       8.3Gi       113Gi       251Mi       3.5Gi       115Gi
Swap:         8.0Gi          0B       8.0Gi

$ df -h /dev/shm
Filesystem      Size  Used Avail Use% Mounted on
tmpfs            63G     0   63G   0% /dev/shm
```

重新限制ramdisk的使用大小可以使用如下命令
```bash
mount -o remount,size=32G /dev/shm
```

另外也可以通过`/etc/fstab`文件来永久生效，在该文件中修改或添加一行
```
tmpfs   /dev/shm    tmpfs   defaults,size=512M   0    0
```
该目录 `/dev/shm`是ubuntu默认创建的 ramdisk，可以直接使用的，将文件或目录放置在该路径下即可。



**创建一个自己的RAMDisk** 
理论上挂载点放在哪里都可以，这里将`/mnt/my_ramdisk`用于挂载点 。
```bash
# 创建一个目录，用于挂载
sudo mkdir -p /mnt/my_ramdisk
# 挂载
sudo mount -t tmpfs -o defaults,size=2048M tmpfs /mnt/my_ramdisk

# 检查是否挂载成功，应当能看到
df -h
# 可以测试读写
echo "hello" > /mnt/my_ramdisk/test.txt
cat /mnt/my_ramdisk/test.txt


# 卸载，使用 umount
sudo umount /mnt/my_ramdisk
```


自动挂载ramdisk，编写`/etc/fstab` 添加一行即可，并可以执行 `sudo mount -a` 立即生效。
```
tmpfs   /mnt/my_ramdisk   tmpfs   defaults,size=2048M   0   0
```


**使用补充**  
在重新启动后，ramdisk区域将被完全删除，因此可以考虑备份系统(如使用定时周期任务，每隔15分钟自动备份一次ramdisk中的内容到磁盘)，
以及恢复它的方法(如在编写一个启动后的服务，从磁盘备份区域复制回ramdisk 挂载目录)。如果是不重要的数据，那就不需要了。


## 关于initrd/initramfs

initrd和initramfs在内核看来其实是相似的技术手段，实现通用的目的。[具体initrd和initramfs的关联](#initramfs-和-initrd-的关联)

initrd （boot loader initialized RAM disk）。它是在系统初始化引导时候可以使用的 内存文件系统，它被加载到内核中并用于引导
启动过程中的初始化。initrd通常包含一些必要的工具和驱动程序，可以在根文件系统挂载之前初始化硬件设备、加载模块和设置网络等。

通常，在Linux启动的早期阶段，initrd会被加载到系统内存中，并被内核作为根文件系统挂载。然后，initrd执行用户指定的脚本或二进制文件，
完成基本的系统初始化、设备探测和共享库加载等任务。之后，initrd释放控制权给真正的根文件系统，使系统能够顺利地完成引导过程并进入用户空间。

**为何需要initrd**  

主要解决模块读取和磁盘驱动的先有鸡先有蛋的问题。并且是不太增加内核大小的条件下。系统启动过程中有些驱动是必不可少的，最典型的是磁盘IO，
（没有磁盘驱动，就无法挂载根文件系统，linux启动后必须要挂载根文件系统）。按照这个原理，只需要将相关的必要驱动编译进内核即可。

早期的计算机设备，磁盘驱动单一，主要就是软盘和硬盘，可以直接编译进内核，所以直接在引导内核时加上`root=xxx`参数即可。现代系统不太合适了，
主要现在磁盘类的驱动种类非常丰富，如果全部编译进内核，内核就臃肿了，且启动时间会增加，另外，如果某个驱动程序出现了问题，需要重新编译整个内核。

现代的linux系统，支持initrd，initramfs这种内存文件系统，就是将这些需要的内核模块和其他相关文件，专门做成一个mini的根文件系统，加载在内存中，
这样，linux就有了相关的磁盘驱动等，就这个挂载根文件系统了，挂载真正的文件系统后，将从内存文件系统切换到真正的磁盘上的根文件系统，
根文件系统里面也有相关的驱动。这样可以确保操作系统能够成功地启动并正确地加载所有必要的驱动程序。

此外，使用initrd技术还可以支持在运行时加载驱动程序，以及在引导过程中修复系统或者添加新的硬件支持等功能。


**制作(initramfs格式)**

一般可以使用`cpio`工具来创建initrd。首先需要做一个mini的文件系统，并把必要的驱动加入进去，可以参考busybox制作根文件系统。

在创建initrd时，用户需要指定所需的内核模块、驱动程序和其他文件。这些文件通常被打包成一个压缩的cpio归档文件。
在构建完成后，用户需要将生成的initrd文件复制到/boot目录下，并更新grub或其他引导程序的配置文件以指向它。（x86-grub）


```bash
# 创建一个空的目录作为initrd的根目录：mkdir /tmp/initrd-root
# 使用mknod命令在/dev目录下创建必要的设备节点，例如console、null等。
# 在此目录下创建必要的目录结构和文件，例如/dev、/proc、/sys等目录，并将需要用到的驱动程序和工具拷贝到相应的位置。
# cp -a /lib/modules/$(uname -r)/kernel/xxx /tmp/initrd-root/lib/modules/$(uname -r)/kernel/xxx

# 假设作好的根文件系统路径为 /tmp/initrd-root ，打包到initrd.cpio归档文件
cd /tmp/initrd-root
find . | cpio -o -H newc > /tmp/initrd.cpio
# 一般都会进一步使用gzip压缩下，生成 initrd.cpio.gz
gzip -9 /tmp/initrd.cpio
# 一步到位
# find . | cpio -o -H newc | gzip -9 > /tmp/initrd.cpio


# ##### 解压方式记录，记得单独创建一个文件夹，拷贝进来    #######
gzip -d ./initrd.cpio.gz
cpio -idmv < ./initrd.cpio

# ######   x86 linux - grub可选       ######
# 可以将文件重命名下
mv /tmp/initrd.cpio.gz /boot/initrd.img-$(uname -r)
# 最后更新grub相关配置，使其指向生成的img文件
# 根据实际情况调整。
```




# ramfs 和 tmpfs

**tmpfs是ramfs的继承者，继承并扩展了ramfs。**

## ramfs

Ramfs是一个非常简单的文件系统，它**将**Linux的**磁盘缓存机制(页面缓存和dentry缓存)**导出为一个**可动态调整大小**的**基于ram**的文件系统。

Ramfs是来源于磁盘缓存机制的，该机制主要就是磁盘的IO缓存，一般的文件都是会cached在内存中的，从物理磁盘中读取的pages of data都是保存在ram中的，
但是标记为干净的（不需要写回harddisk）。写数据到harddisk时，也是相似的，pages of data先是cached在内存中的，到合适的时间真正写入harddisk，
这个主要就是file cache机制，可以加速文件的IO读写访问，还有个dentry cache就是目录缓存机制，加速目录的访问，原理相似。

而ramfs，就是在磁盘缓存机制的基础上，去掉了harddisk的最终写入，而这个文件和目录的cache机制保留，这样意味着相关的页面状态永远是干净的。
ramfs的实现代码量很少，所有的工作都是由现有的Linux Cache机制基础上完成的，是直接编译进内核的，无法移除。

ramfs相比于更老的 ramdisk机制，ramdisk机制是从ram中挖掉一块内存，将其视为 "harddisk" 使用的。这块内存的大小是固定的，不能动态改变，另外，
由于其实模拟 harddisk，所以在文件的读写访问上和一般的磁盘是一样的，在经过磁盘缓存机制后，还需要在复制一次到相关的内存块中，多了一次读写拷贝，
性能会降低一些；还有，ram disk由于是模拟 “harddisk”，所以需要为其搞一个文件系统驱动模块才能使用（如ext2），这个又会浪费内存和额外的CPU资源。

总之，ramfs相比ramdisk，有许多优点，主要是优化了文件IO读写操作整个流程中的很多不必要的操作。而且ramfs实现也比ramdisk更简单。
但是ramfs也有缺点：就是可以一直向它写入数据，直到填满所有内存，并且linux的虚拟内存管理单元无法释放它，因为VM认为文件应该写入harddisk(而不是交换空间)，
但是ramfs没有任何harddisk。因此，应该只允许root(或受信任的用户)对ramfs挂载进行写访问。

*虽然ramfs很好，不过，现在有更好的tmpfs。*

## tmpfs

tmpfs在ramfs的基础上演化而来，增加了使用的**RAM大小限制**，**支持将数据写入交换空间swap**。可以**允许普通用户对tmpfs挂载进行写访问**。
它的使用和ramfs基本没有区别。

使用场景：

1. linux内核中总是挂载一个用户看不到的tmpfs，用于共享的 匿名映射和SYSV共享内存。这个挂载不依赖于CONFIG_TMPFS。
   如果没有设置CONFIG_TMPFS，则不构建tmpfs的用户可见部分。但是内部机制总是存在的。
2. glibc2.2版本及以上，tmpfs被希望挂载在 `/dev/shm`，并可以给POSIX的共享内存机制使用（shm_open, shm_unlink）。使用命令 `df -h`
   可以查看。如果没有自动挂载，可以在 `/etc/fstab`中添加如下行：`tmpfs   /dev/shm  tmpfs   defaults  0 0`。此外，SYSV的共享内存机制
   则不需要这个挂载，因为它使用那个内核内部挂载的tmpfs。
3. 可以用于挂载 `/tmp`， `/var/tmp`， `/run` 等目录 。


tmpfs挂载时，一般需要指定size，即最大使用的ram量，默认是一般内存，使用挂载参数`size`指定，或者使用`nr_blocks`和 `nr_inodes`,单位不同。




## rootfs
Rootfs是ramfs(或tmpfs，如果启用了的话)的一个特殊实例，大多数的用途就是在rootfs上挂载另一个文件系统，并忽略它。ramfs实例占用的空间量很小。
如果启用了CONFIG_TMPFS, rootfs将默认使用tmpfs而不是ramfs。要强制使用ramfs，请在内核命令行中添加" rootfstype=ramfs "。




# initramfs 和 initrd 的关联

>***initramfs is a cpio archive file*** of the initial file system that is loaded to memory. 

initramfs，initial RAM文件系统，允许内核*从内核内置的RAM磁盘或由引导加载程序传递的RAM磁盘*运行用户空间应用程序。
一般是BootLoader程序加载传递过去的，也可以在配置内核时指定CONFIG_INITRAMFS_SOURCE(Initramfs source file(s))。
在用户空间初始化也更加方便定制和修改系统的引导，也更安全，否则全在内核中就不方便也不安全。在x86上debian上，直接有工具
`initramfs-tools`可以管理initramfs。

**在Linux 2.6系列中引入的initramfs是initrd的继承者。** 现在，Linux内核使用的initramfs通常是一个gzip压缩后的 **cpio归档文件**，
它会被提取到内存文件系统(通常是tmpfs)中，并用作根文件系统。在提取之后，内核检查rootfs是否包含一个文件`/init`，如果是，它将其作为PID 1执行。
这个init进程(initramfs中的)负责将系统启动，包括定位和挂载真正的根设备(如果有的话，嵌入式环境下可能会没有)。

**initramfs在传统的x86中和嵌入式环境中的使用可能是不同的！！**  
传统的initramfs是一个小型的根文件系统，功能一般固定为查找并移交给主要的根文件系统。但在嵌入式环境中，很可能不会移交给新的根文件系统，
就直接跑在initramfs上，不过嵌入式环境下，initramfs里面肯定是将必要的程序，库等都做全了，所以也不同担心运行问题。另外，嵌入式环境也是支持
传统模式的，也可以像传统的initramfs一样，查找并移交给新的主要的根文件系统。都是支持的。主要区别在于，传统用例有一个初始化脚本来挂载最终映像，
而嵌入式环境则可能是根据需要定制的。

如在`yocto`中，传统用例由INITRAMFS_IMAGE变量支持。它允许指定一个映像用作initramfs，而主rootfs仍在构建中。有一个用于此目的的映像配方，
名为core_image_minimal_initramfs，因此，如果您在配置文件中指定INITRAMFS_IMAGE = "core-image-minimal-initramfs"，
那么yocto将构建两个rootfs，第一个rootfs使用初始化脚本挂载第二个rootfs。此外，变量INITRAMFS_IMAGE_BUNDLE还确保initramfs也被内置到内核中。


## 一些历史

2.4内核时使用最原始 initrd技术，制作会麻烦一些 ，且内核对齐的处理也复杂一些。大致处理过程如下，简单了解即可。

1. boot loader把内核以及initrd文件的内容加载到内存。
2. 内核初始化过程中，把initrd文件的内容解压缩，并拷贝到`/dev/ram0` 设备上，即又读入一次内存
3. 内核以 `rw` 的模式将 `/dev/ram0` 设备挂载为原始的根文件系统。
4. 内核最后执行initrd中的 `/linuxrc` 文件，通常是一个脚本。负责加载内核访问根文件系统必须的驱动，
5. `/linuxrc`文件最后一般是挂载真正的根文件系统。
6. 在真正的根文件系统中执行 `/sbin/init` 。

这种方式，不是很好，不仅需要额外的内存拷贝，还要求内核中编译进initrd使用的文件系统模块，处理流程也更复杂，所有后面就被优化了。

同时这种initrd 根文件系统的制作方式，大小是固定的，而且是不用cpio工具的，参考：
```bash
# 先做好initrd根文件系统，和initramfs是一样的，假设rootfs目录为 init_rootfs
dd if=/dev/zero of=./initrd.img bs=512k count=5
mkfs.ext4 -F -m0 ./initrd.img
mount -t ext4 -o loop ./initrd.img   /mnt
cp -r   ./init_rootfs/* /mnt      # 拷贝rootfs
umount /mnt
gzip -9 ./initrd.img
```

可以看到，initrd的大小是在制作时固定的，不灵活，而且需要格式化文件系统。
针对以上的问题，到linux2.6内核时，使用initramfs进行了一些优化。2.6内核开始的initramfs，原理上其实相似，主要是细节优化。所以initramfs定位是initrd的继承者。

initramfs中直接使用 ramfs(tmpfs) ，由于这个本身就是固定编译进内核的，所以内核不需要额外的文件系统模块了。另外就是，使用cpio工具
来打包根文件系统，大小是灵活可变的。内核在处理initramfs时，流程也更简单，解压完后，做个判断（因为内核兼容历史的initrd技术），如果
是cpio格式的initramfs，就可以直接挂载为根文件系统使用，不需要额外的拷贝内存，加载文件系统驱动了。因为ramfs的机制实现是基于linux
的磁盘缓存机制实现的，使用更简单。initramfs的大致处理过程参考：

1. boot loader 把内核以及 initrd 文件加载到内存的特定位置。
2. 内核判断initrd的文件格式，如果是cpio格式，解压并将其作为rootfs挂载。
3. 执行initrd中的`/init`文件，执行到这一点，内核的工作全部结束，完全交给`/init`文件处理。
4. `/init`中可以加载各种驱动和模块等，最后一般也是挂载真正的根文件系统，（嵌入式环境可能不需要）。

initramfs的制作方式也更简单，会用到cpio工具，参考：
```bash
# 首先进入制作好的根文件系统目录
cd init_rootfs
find . | cpio -c -o > ../initrd.img
gzip ../initrd.img
```


## 使用initrd/initramfs

制作好好的inintramfs镜像文件，一般是有BootLoader负责并加载给内核。由于在linux内核启动引导阶段，没有rootfs，也更不能识别文件
系统等。所以BootLoader传递 initramfs 的img文件时，传递的只能是地址，起始地址和结束地址。不同的CPU架构，可能地址的格式会有差别。

虽然传递的是地址，但是用户在BootLoader程序中不一定需要指定地址，比如，在grub引导x86时，通过initrd参数指定initramfs文件即可，
grub是可以识别文件系统的，后续会读取img文件，自动完成地址相关的设置，用户不需要关注。而在uboot引导arm系统中，booti命令启动时，
就需要用户主动传递initramfs的加载地址给内核了。所以，和CPU架构有关系。




## 简单小结
1. initrd/initramfs在内核看来，是统一的，在内核配置中也是，后者是前者的继任者，更加优化了
2. 二者使用时还是有些区别的，initrd中会执行`/linuxrc`，而initramfs则是执行`/init`。
3. 二者的制作过程也有差异，initramfs使用cpio制作，更简单。
4. 二者在内核中都支持，二者的这些差异根源就是在内核的在启动过程中对这两种类型的rootfs的处理流程差异。
5. 二者使用的rootfs其实基本没有区别，只是打包的内核的使用处理流程有些差异。




**内核相关代码**
```
start_kernel();
    vfs_caches_init();
        mnt_init();
            shmem_init();
	        init_rootfs();
	        init_mount_tree();
```


# 参考
* [Ramfs, rootfs and initramfs](https://www.kernel.org/doc/html/latest/filesystems/ramfs-rootfs-initramfs.html?highlight=ramfs)
* [Tmpfs](https://www.kernel.org/doc/html/latest/filesystems/tmpfs.html)
* [rootfs和initrd](https://www.cnblogs.com/tsecer/p/10485749.html)
* [RamDisk与Initrd](https://blog.csdn.net/gx19862005/article/details/12774687)
* [Linux内核Ramdisk(initrd)机制](https://blog.csdn.net/xiehaihit/article/details/91959216)