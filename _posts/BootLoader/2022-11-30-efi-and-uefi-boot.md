---
title: 'efi and uefi boot'
date: 2022-11-30 09:23:23 +0800
categories: [BootLoader]
tags: [efi, uefi]
published: true
---



# BIOS 固件

一系列硬编码的小程序的集合，存放在PC的motherborad上的rom chip中（通常是flash存储器或EEPROM）。

没有BIOS，计算机将无法启动。BIOS就像“基本的操作系统”，它连接计算机的基本组件，并允许它启动。即使加载了主操作系统，它仍然可能使用BIOS与主要组件进行通信。**它的主要功能之一是引导系统启动，但不是只有这一个功能**。它应当是一套控制该主板的固件（风扇，超频，RTC，存储设置（比如记录首选启动项），IO驱动，POST自检，系统引导功能），而不仅仅是引导系统。

简单说，就是初始化硬件，POST检测以保证连接到PC的硬件外设都正常，配置底层硬件设置（这个应该会传给OS的），引导系统。而且，BIOS是必要的，一定有的，在母板上。

另外，关于引导系统这点，也不完全准确，应该说是引导系统启动器，比如windows，windows启动器中会让你选择启动win7/win8/win10,如果安装了多个windows系统，（开始->运行->msconfig 可以配置）。对于linux系列，其实就对应引导启动grub程序，grub再选择启动具体某个linux发行版。所以BIOS引导系统启动也不是直接就去加载系统的。

## 4 main functions:

* POST - Test computer hardware insuring hardware is properly functioning before starting process of loading Operating System.

* Bootstrap Loader - Process of locating the operating system. If capable Operating system located BIOS will pass the control to it.

* BIOS - Software / Drivers which interfaces between the operating system and your hardware. When running DOS or Windows you are using complete BIOS support.

* CMOS Setup - Configuration program. Which allows you to configure hardware settings including system settings such as computer passwords, time, and date.

## How does system bootstrap
<https://www.cs.yale.edu/flint/feng/cos/resources/BIOS/>  

The system BIOS is what starts the computer running when you turn it on. The following are the steps that a typical boot sequence involves.

1. The internal power supply turns on and initializes. The power supply takes some time until it can generate reliable power for the rest of the computer, and having it turn on prematurely could potentially lead to damage. Therefore, the chipset will generate a reset signal to the processor (the same as if you held the reset button down for a while on your case) until it receives the Power Good signal from the power supply.
2. When the reset button is released, the processor will be ready to start executing. When the processor first starts up, it is suffering from amnesia; there is nothing at all in the memory to execute. Of course processor makers know this will happen, so they pre-program the processor to always look at the same place in the system BIOS ROM for the start of the BIOS boot program. This is normally location FFFF0h, right at the end of the system memory. They put it there so that the size of the ROM can be changed without creating compatibility problems. Since there are only 16 bytes left from there to the end of conventional memory, this location just contains a "jump" instruction telling the processor where to go to find the real BIOS startup program.
3. The BIOS performs the power-on self test (POST). If there are any fatal errors, the boot process stops. POST beep codes can be found in this area of the Troubleshooting Expert.
4. The BIOS looks for the video card. In particular, it looks for the video card's built in BIOS program and runs it. This BIOS is normally found at location C000h in memory. The system BIOS executes the video card BIOS, which initializes the video card. Most modern cards will display information on the screen about the video card. (This is why on a modern PC you usually see something on the screen about the video card before you see the messages from the system BIOS itself).
5. The BIOS then looks for other devices' ROMs to see if any of them have BIOSes. Normally, the IDE/ATA hard disk BIOS will be found at C8000h and executed. If any other device BIOSes are found, they are executed as well.
6. The BIOS displays its startup screen.
7. The BIOS does more tests on the system, including the memory count-up test which you see on the screen. The BIOS will generally display a text error message on the screen if it encounters an error at this point; these error messages and their explanations can be found in this part of the Troubleshooting Expert.
8. The BIOS performs a "system inventory" of sorts, doing more tests to determine what sort of hardware is in the system. Modern BIOSes have many automatic settings and will determine memory timing (for example) based on what kind of memory it finds. Many BIOSes can also dynamically set hard drive parameters and access modes, and will determine these at roughly this time. Some will display a message on the screen for each drive they detect and configure this way. The BIOS will also now search for and label logical devices (COM and LPT ports).
9. If the BIOS supports the Plug and Play standard, it will detect and configure Plug and Play devices at this time and display a message on the screen for each one it finds. See here for more details on how PnP detects devices and assigns resources.
10. The BIOS will display a summary screen about your system's configuration. Checking this page of data can be helpful in diagnosing setup problems, although it can be hard to see because sometimes it flashes on the screen very quickly before scrolling off the top.
11. The BIOS begins the search for a drive to boot from. Most modern BIOSes contain a setting that controls if the system should first try to boot from the floppy disk (A:) or first try the hard disk (C:). Some BIOSes will even let you boot from your CD-ROM drive or other devices, depending on the boot sequence BIOS setting.
12. Having identified its target boot drive, the BIOS looks for boot information to start the operating system boot process. If it is searching a hard disk, it looks for a master boot record at cylinder 0, head 0, sector 1 (the first sector on the disk); if it is searching a floppy disk, it looks at the same address on the floppy disk for a volume boot sector.
13. If it finds what it is looking for, the BIOS starts the process of booting the operating system, using the information in the boot sector. At this point, the code in the boot sector takes over from the BIOS. The DOS boot process is described in detail here. If the first device that the system tries (floppy, hard disk, etc.) is not found, the BIOS will then try the next device in the boot sequence, and continue until it finds a bootable device.
14. If no boot device at all can be found, the system will normally display an error message and then freeze up the system. What the error message is depends entirely on the BIOS, and can be anything from the rather clear "No boot device available" to the very cryptic "NO ROM BASIC - SYSTEM HALTED". This will also happen if you have a bootable hard disk partition but forget to set it active.
 

BIOS is a piece of program. When the system starts, the register EIP is initialized to FFFF0 to execute the JMP instruction there, which leads to the execution of the system BIOS code.

BIOS will initialize other devices; initialize the interrupt vector; find other BIOS programs and run them.

**Q?:efi 如何被加载的？而且efi分区一定要求是FAT32格式的，是需要BIOS去加载吗？？把引导OS编程引导efi启动？？**

## 查看BIOS信息
在window7,8,10 上，hit ”Windows+R“，type “msinfo32”,hit Enter. 可以查看硬件信息集合。
补充：里面有一项 BIOS模式， 为BIOS或UEFI。

## 从BIOS切换到UEFI
Select **UEFI Boot Mode** or **Legacy BIOS Boot Mode (BIOS)** Access the BIOS Setup Utility. From the BIOS Main menu screen, select Boot. From the Boot screen, select UEFI/BIOS Boot Mode, and press Enter. Use the up and down arrows to select Legacy BIOS Boot Mode or UEFI Boot Mode, and then press Enter.

这个只需要在开机后，进入BIOS菜单，修改BOOT相关设置即可。不同的主板有差别。

注意：这里说的特指BIOS的启动模式，不是BIOS的全部功能，使用UEFI Boot方式或Legacy BIOS Boot方式。传统的BIOS启动模式是一定会支持的，UEFI启动方式现在的主板也基本都支持，而且是默认了。

### 开启UEFI方法

以下的设置项有的就修改，没有就跳过：

1）切换到Boot，选择UEFI Boot回车设置为Enabled

2）有些电脑在Startup下，把UEFI/Legacy Boot设置为UEFI Only

3）把Boot mode select设置为UEFI

4）Boot Type设置为UEFI Boot Type

5）华硕的Launch CSM默认是Disabled，CSM开启时表示Legacy模式，关闭时表示UEFI模式

### 修改为传统BIOS

注：如果有以下选项，就需要修改，没有就略过

1）Secure Boot改成Disabled，禁用安全启动

2）CSM改成Enable或Yes，表示兼容

3）Boot mode或UEFI mode改成Legacy，表示传统启动方式

4）OS Optimized Defaults改成Disabled或Other OS，禁用默认系统优先设置

5）部分机型需设置BIOS密码才可以修改Secure Boot，找到Set Supervisor Password设置密码



# MBR 分区格式

MBR（Master Boot Record） 主引导记录 相对古老的分区方式，自1982年创建，使用至今 MBR又叫做主引导扇区，是计算机开机后访问磁盘时读取的首个扇区，即位于硬盘的0号柱面 (Cylinder)、0号磁头 (Side)、1号扇区 (Sector)。

MBR分区格式通常配合legacy boot mode使用。MBR 分区头一定是被放置在硬盘开头部分，固定大小512字节。（硬盘的第0磁道第0柱面第1扇区）。512字节==446+64+2；
真正的分区表 **DPT（Disk Partition Table硬盘分区表）** 其实对应那个64字节。

## 硬盘分区DPT
分区表由4项组成，每项16个字节（Byte).共4×16 = 64字节(Byte)。每项描述一个分区的基本信息。

| offset   |   释义  |
| -------- | ------- |
|  1       |  引导标志。若值为80H表示活动分区，若值为00H表示非活动分区。| 
| 2,3,4    |  本分区的*起始*磁头号、扇区号、柱面号。磁头号——第2字节；    扇区号——第3字节的低6位；  柱面号——为第3字节高2位+第4字节8位。 |
| 5          |   分区类型符。 00H——表示该分区未用（即没有指定）；06H——FAT16基本分区；0BH——FAT32基本分区；05H——扩展分区；07H——NTFS分区； 0FH——（LBA模式）扩展分区（83H为Linux分区等）。|
| 6,7,8      |  本分区的*结束*磁头号、扇区号、柱面号。其中：磁头号——第6字节；扇区号——第7字节的低6位；柱面号——第7字节的高2位+第8字节。 |
| 9,10,11,12 |  逻辑起始扇区号（u32） ，本分区之前已用了的扇区数。 |
| 13,14,15,16 | 本分区的总扇区数。（u32）  |

分区表上有64/16=4项，每一项表示一个分区，主分区表上的4项用来表示主分区和扩展分区的信息。因为扩展分区最多只能有一个，所以硬盘最多可以有四个主分区或者三个主分区，一个扩展分区。余下的分区表是表示逻辑分区的。逻辑区都是位于扩展分区里面的，并且逻辑分区的个数没有限制。**扩展分区相当于一个指针机制，该分区再次存放DPT分区表信息，把这个扩展部分称为扩展分区，区别于主分区。**

## 最后2字节
固定为magic number : 0x55,0xAA ，0xAA是最后一个字节

## 开头446字节
放置 Pre-Boot程序-引导程序，这个是操作系统安装时写入的，用来将引导OS启动的，从硬盘搬到内存，并启动执行。这里的446字节是最多用446字节，OS版本不同，这个Pre-Boot程序也有差异，不过都不会超过446字节。使用fdisk或parted工具修改分区表时，改动的其实是DPT，这个Pre-Boot程序是不会动的。


# UEFI 固件

UEFI stands for **Unified Extensible Firmware Interface**. It does the same job as a BIOS, but with one basic difference: it stores all data about initialization and startup in an .efi file. UEFI supports drive sizes upto 9 zettabytes, whereas BIOS only supports 2.2 terabytes. UEFI provides faster boot time.

UEFI也需要OS支持才能用，如果OS太老，可能是不支持的，如windowsXP。win7，win8，win10以及现在的主流linux发行版都支持UEFI启动。

**UEFI functions via special firmware installed on a computer's motherboard.** Like BIOS, UEFI is installed at the time of manufacturing and is the first program that runs when booting a computer. It checks to see which hardware components are attached, wakes up the components and hands them over to the OS.The new specification addresses several limitations of BIOS, including restrictions on hard disk partition size and the amount of time BIOS takes to perform its tasks.

**UEFI 通过安装在计算机主板上的特殊固件运行**。与 BIOS 一样，UEFI 是在制造时安装的，是启动计算机时运行的第一个程序。它会检查连接了哪些硬件组件，唤醒这些组件并将它们交给操作系统。新规范解决了 BIOS 的几个限制，包括对硬盘分区大小和 BIOS 执行其任务所需时间的限制。

UEFI，统一可扩展固件接口，是一种个人电脑系统规格，用来定义操作系统与系统固件之间的软件界面，作为BIOS的替代方案。可扩展固件接口负责加电自检、联系操作系统以及提供连接操作系统与硬件的接口。


后续补充（修正）：UEFI，Unified Extensible Firmware Interface，本身的释义是一个**接口规范**，定义了操作系统和主板固件之间的软件接口规范。所以，UEFI在物理上应该对应两部分，**主板的UEFI固件和操作系统的efi程序文件**。想要efi boot，需要两方面要求，主板的UEFI firmware固件符合UEFI规范，磁盘的EFI分区做好，并安装好 .efi 程序文件。

个人理解：
1. UEFI接口规范，如果类比BIOS，其实是定义BIOS要做什么，如BIOS的POST自检，IO管理，启动管理，而BIOS做的这些，没有明确规范，是自己定义的，而UEFI则是由组织规定的（有Intel交给组织后统一规范，即UEFI，之前也是Intel自己定义的）。这个UEFI的接口规范内容比BIOS多很多，功能更多，安全性更高，具体可以参考[wiki连接](https://en.wikipedia.org/wiki/UEFI)，比如，支持图形化了，要求引导的磁盘为GPT分区格式，secure boot，更容易支持多系统。
2. 根据UEFI接口规范，对下，就是主板，对应主板的UEFI固件，这个主板的UEFI固件可能是和BIOS并列存在的，即厂商的主板固件同时支持BIOS和UEFI，用户可以自由切换。UEFI固件的基本功能和BIOS固件相类似的事情，IO外设管理，系统引导等等，角色定位和BIOS固件一致，但是功能更强大。
3. 根据UEFI接口规范，对上，就是OS的接口。对应磁盘上要求的FAT32分区，里面要存放 .efi 程序。这个.efi 程序会负责引导OS启动，所以启动OS比BIOS的legacy boot mode 快。另外，这个 .efi 程序文件不是一个文件，而是多个，而且还可以带配置文件。里面和grub也有关， 有一个grubx64.efi。应该是先引导启动的grub，grub再启动linux。这些个 .efi 文件根据UEFI规范，需要放在硬盘的标准分区上，**即esp分区（efi分区），且必须对该分区设置boot和esp标记，且要求必须是FAT的文件系统**。这样，UEFI boot mode才能找到这个EFI分区。很关键。然后，将efi程序文件和配置文件放入即可（这些一般由工具完成，如OS安装，grub install）。（EFI分区在window上用户不可直接看到，系统隐藏了，linux上一般在 /boot/efi/ ）。EFI分区一般512MB即可。

UEFI 的行为就像一个位于固件和操作系统之间的微型操作系统。它在启动时执行与 BIOS 相同的诊断，但提供了更大的灵活性。

In 2013, custody of the Advanced Configuration and Power Interface (ACPI) was transferred to UEFI Forum.
 Originally developed collaboratively by HP, Intel, Microsoft, Phoenix Technologies and Toshiba, ACPI is an open standard for BIOS that governs how much power is delivered to each peripheral device.
UEFI在现代计算机母版几乎是默认了，算是实现了取代BIOS的目标。ACPI接口标准也在2013年交给UEFI组织了。

另外，在linux中，efi程序的安装好像是grub完成的，只需要运行 grub-install /dev/xxx 即可，这里的xxx磁盘名暂保留，不确定是磁盘还是分区。(目前使用的基本都是grub2，已经支持efi启动了。)在linux系统中，通过 `ls /sys/firmware/efi` 就可以判断是否是efi启动的，如果存在该目录，就是efi启动的，否则就是bios(legacy)启动的。

UEFI相比BIOS，启动更快，因为BIOS固件存储空间容量很有限，所以它使用16-bit的指令，而现代的CPU都是32位或64位CPU，这样运行BIOS代码就很慢。而EFI(UEFI)没有该问题，EFI程序引导部分是放在磁盘上的。

UEFI的优点和特性参考：  
<https://en.wikipedia.org/wiki/UEFI>  
<https://www.techtarget.com/whatis/definition/Unified-Extensible-Firmware-Interface-UEFI>  


# GPT 分区格式

GPT(全局唯一标识磁盘分区表),是源自EFI标准的一种全新磁盘分区表标准结构。相比于MBR分区格式，增加内容较多。且考虑到了兼容MBR的情况（防止有些机器不识别导致破坏GPT分区信息）。

GPT分区的使用，一是作为系统启动盘，一般要求UEFI，UEFI支持GPT，二是作为系统的数据盘，要求OS能识别GPT，只要不是很古老的OS，基本都能识别GPT分区格式。

<https://zhuanlan.zhihu.com/p/517741220>

过去磁盘的一个扇区大小仅有512字节，由于目前出现了4k扇区，因此在扇区的定义上，大多会采用**逻辑区块地址（Logical Block Address，LBA）**来处理。**GPT会将磁盘的所有区块以LBA（默认512字节）进行规划，从数字0从小到大开始编号，第一个LBA为LBA0**。MBR仅使用第一个LBA块（512字节）来记录分区信息，并且当该区块出现错误时整块磁盘都将难以修复，但GPT不同,它使用了开头的34个LBA区块来记录分区信息，并且把整个磁盘的最后34个LBA也拿来做一个备份。关于这34个LBA的使用：

LBA0（MBR兼容区块/保护MBR）
: 保护MBR包含一个DOS分区表(LBA0)，只包含一个类型值为0xEE的分区项，在小于2TB的磁盘上，大小为整个磁盘；在更大的磁盘上，它的大小固定为2TB。它的作用是阻止不能识别GPT分区的磁盘工具试图对其进行分区或格式化等操作，起一个保护作用，所以该扇区被称为“保护MBR”。实际上，EFI根本不使用这个分区表。就是起保护作用的。

LBA1（GPT表头记录）
: 这部分记录了分区表的位置和大小，同时也记录了前面提到备份用的GPT分区所在位置（最后34个LBA），还放置了分区表的校验码（CRC32），校验码的作用是让操作系统判断GPT的正确与否，倘若发现错误则可以从备份的GPT中恢复正常运行。

LBA2-33（实际记录分区信息处）
: 从LBA2开始，每个LBA都是用于存放分区信息的，每个LBA可以提供4条的分区记录信息，所以最多有4x32=128条分区记录（每条分区信息叫一个entry，大小128字节，一个LBA就可以放4条，）相比于MNR的16字节为一条分区信息，GPT的分区信息较多（由起始地址、结束地址、类型值、名字、属性标志、GUID值组成。分区表建立后，128位的GUID对系统来说是唯一的。）。

后面的LBA到最后34个LBA之间
: 存放数据使用的LBA

最后34个LBA
: 开头的GPT分区表的备份

## GPT分区头信息格式
EFI信息区位于磁盘的1号扇区(LBA1)，也称为GPT头。其具体结构如下表所示

|   相对字节偏移量(十六进制)   |  字节数  |	说明[整数皆以little endian方式表示]  |
|  --------------------    |   ------  |  -----------------------------    |
|         00～07	       |     8	    |   GPT头签名“45 46 49 20 50 41 52 54”(ASCII码为“EFI PART”) |
|         08～0B	       |     4	    |   版本号，目前是1.0版，其值是“00 00 01 00” |
|         0C～0F	       |     4	    |   GPT头的大小(字节数)，通常为“5C 00 00 00”(0x5C)，也就是92字节。 |
|         10～13	       |     4	    |   GPT头CRC校验和(计算时把这个字段本身看做零值) |
|         14～17	       |     4	    |   保留，必须为“00 00 00 00” |
|         18～1F	       |     8	    |   EFI信息区(GPT头)的起始扇区号，通常为“01 00 00 00 00 00 00 00”，也就是LBA1。 |
|         20～27	       |     8	    |   EFI信息区(GPT头)备份位置的扇区号，也就是EFI区域结束扇区号。通常是整个磁盘最末一个扇区。 |
|         28～2F	       |     8	    |   GPT分区区域的起始扇区号，通常为“22 00 00 00 00 00 00 00”(0x22)，也即是LBA34。 |
|         30～37	       |     8	    |   GPT分区区域的结束扇区号，通常是倒数第34扇区。 |
|         38～47	       |     16	    |   磁盘GUID(全球唯一标识符,与UUID是同义词) |
|         48～4F	       |     8	    |   分区表起始扇区号，通常为“02 00 00 00 00 00 00 00”(0x02)，也就是LBA2。 |
|         50～53	       |     4	    |   分区表总项数，通常限定为“80 00 00 00”(0x80)，也就是128个。 |
|         54～57	       |     4	    |   每个分区表项占用字节数，通常限定为“80 00 00 00”(0x80)，也就是128字节。 |
|         58～5B	       |     4	    |   分区表CRC校验和 |
|         5C～*	           |     *	    |   保留，通常是全零填充  |


## 分区项entry

|  相对字节偏移量(十六进制)  |	字节数	 |  说明[整数皆以little endian方式表示]  |
|  -------------------    |  ------  |  --------------------------------   | 
|       00～0F	          |    16	 |  用GUID表示的分区类型                |
|       10～1F	          |    16	 |  用GUID表示的分区唯一标示符           |
|       20～27	          |    8	 |  该分区的起始扇区，用LBA值表示。       |
|       28～2F	          |    8	 |  该分区的结束扇区(包含)，用LBA值表示，通常是奇数。       |
|       30～37	          |    8	 |  该分区的属性标志                                    |
|       38～7F	          |    72	 |  UTF-16LE编码的人类可读的分区名称，最大32个字符。        |

细节参考：  
<https://blog.csdn.net/dzhongjie/article/details/112325468>  
<https://en.wikipedia.org/wiki/GUID_Partition_Table>  


# notes
1. BIOS firmware 是被保存在PC的motherboard的ROM chip上的，通常这是个flash 存储器。而efi固件则是保存在硬盘的特殊分区efi分区（也有较esp分区的）。一个要擦写flash存储器芯片，一个只要通过文件系统修改分区中的文件即可。在硬件形态上有很大差异的，比如flash芯片的存储容量，加载速度，加载OS的途径。
2. UEFI是统一化后的EFI，现在使用的一般是UEFI，它是被公开，规范化的。但它是从EFI发展过来的，很多软件上的概念名称仍然叫EFI，而不是UEFI，这点需要记得。





# VMware 虚拟机中实验测试

## 虚拟机配置

1. 磁盘类型默认为SCSI类型的硬盘，改为使用NVMe，模拟真实情况。（编辑虚拟机设置->硬件）
2. VMware创建的虚拟机默认使用传统的BIOS固件，改为UEFI固件，模拟真实情况。（编辑虚拟机设置->选项->高级）
3. 菜单栏->虚拟机->电源->打开电源时进入固件 （查看，VMware虚拟机意义不大）

系统安装时，对于UEFI启动的，在分区时，要划一个esp分区，`used as ESP partition`,然后其他正常操作。
...