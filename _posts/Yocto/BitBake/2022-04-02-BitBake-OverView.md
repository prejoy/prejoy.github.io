---
title: BitBake OverView
date: 2022-04-02 15:55:00 +0800
categories: [Yocto, BitBake]
tags: [Bitbake]
pin: false
published: true
---



# Introduction

**BitBake is a generic task execution engine** that allows *shell and Python* tasks to be run efficiently and in **parallel** while working **within complex inter-task dependency constraints**. One of BitBake’s main users, OpenEmbedded, takes this core and builds embedded Linux software stacks using a task-oriented approach.

Conceptually, BitBake is **similar to GNU Make** in some regards **but has significant differences**:

* **BitBake executes tasks according to *the provided metadata* that builds up the tasks**. *Metadata* is stored in *recipe (.bb)* and *related recipe “append” (.bbappend)* files, *configuration (.conf)* and underlying *include (.inc)* files, and in *class (.bbclass)* files. The metadata **provides** BitBake with **instructions** on what tasks to run **and** the **dependencies** between those tasks.Bitbake根据`metadata`（元数据？）执行任务，元数据是一个逻辑概念，物理上由 `.bb , .bbappend , .conf , .inc , .class` 构成，主体应该是 bb 和 bbappend 文件，称为 `recipes`文件，（配方）。

* **BitBake includes a fetcher library for obtaining source code from various places** such as local files, source control systems, or websites. bitbake工具包含了一套fetcher库，实现了一个从不同来源获取源码的手段

* **The instructions for each unit to be built (e.g. a piece of software) are known as “recipe” files** and contain all the information about the unit (dependencies, source file locations, checksums, description and so on).每个要构建的单元（例如一个软件）的指令被称为“配方”文件，并包含有关该单元的所有信息（依赖关系、源文件位置、校验和、描述等）。

* BitBake includes **a client/server abstraction** and can be used from a command line or used as a service over XML-RPC and has several different user interfaces.BitBake 包含一个客户端/服务器抽象，可以从命令行使用，也可以用作 XML-RPC 上的服务，并且有几个不同的用户接口。



# History and Goals
BitBake was originally a part of the OpenEmbedded project. It was inspired by the Portage package management system used by the Gentoo Linux distribution. On December 7, 2004, OpenEmbedded project team member Chris Larson split the project into two distinct pieces:

* 	BitBake, a generic task executor
* 	OpenEmbedded, a metadata set utilized by BitBake

Today, BitBake is the primary basis of the OpenEmbedded project, which is being used to build and maintain Linux distributions such as the Angstrom Distribution, and which is also being used as the build tool for Linux projects such as the Yocto Project.

Some important original goals for BitBake were:

* Handle cross-compilation.
* Handle inter-package dependencies (build time on target architecture, build time on native architecture, and runtime).
* Support running any number of tasks within a given package, including, but not limited to, fetching upstream sources, unpacking them, patching them, configuring them, and so forth.
* Be Linux distribution agnostic for both build and target systems.
* Be architecture agnostic.
* Support multiple build and target operating systems (e.g. Cygwin, the BSDs, and so forth).
* Be self-contained, rather than tightly integrated into the build machine’s root filesystem.
* Handle conditional metadata on the target architecture, operating system, distribution, and machine.
* Be easy to use the tools to supply local metadata and packages against which to operate.
* Be easy to use BitBake to collaborate between multiple projects for their builds.
* Provide an inheritance mechanism to share common metadata between many packages.

Over time it became apparent that some further requirements were necessary:

* Handle variants of a base recipe (e.g. native, sdk, and multilib).
* Split metadata into layers and allow layers to enhance or override other layers.
* Allow representation of a given set of input variables to a task as a checksum. Based on that checksum, allow acceleration of builds with prebuilt components.

BitBake satisfies all the original requirements and many more with extensions being made to the basic functionality to reflect the additional requirements. Flexibility and power have always been the priorities. BitBake is highly extensible and supports embedded Python code and execution of any arbitrary tasks.


# Concepts

**BitBake is a *program* written in the *Python* language**. *At the highest level, **BitBake interprets metadata, decides what tasks are required to run, and executes those tasks**. Similar to GNU Make, BitBake controls how software is built. GNU Make achieves its control through “makefiles”, while BitBake uses “recipes”*.

BitBake extends the capabilities of a simple tool like GNU Make by allowing for the definition of much more complex tasks, such as assembling entire embedded Linux distributions.

The remainder of this section introduces several concepts that should be understood in order to better leverage the power of BitBake.



## Recipes

*BitBake Recipes, which are denoted by the file extension .bb, are the most basic metadata files*. These recipe files provide BitBake with the following:

* **Descriptive information** about the package (author, homepage, license, and so on)
* The **version** of the recipe
* Existing **dependencies** (both build and runtime dependencies)
* Where the **source code** resides and how to **fetch** it
* Whether the source code requires any **patches**, where to find them, and how to apply them
* How to **configure and compile** the source code
* How to **assemble** the generated artifacts into one or more **installable packages**
* **Where** on the target machine **to install the package** or packages created 

Within the context of BitBake, or any project utilizing BitBake as its build system, files with the .bb extension are referred to as recipes.


> The term “package” is also commonly used to describe recipes. However, since the same word is used to describe packaged output from a project, it is best to maintain a single descriptive term - “recipes”. Put another way, a single “recipe” file is quite capable of generating a number of related but separately installable “packages”. In fact, that ability is fairly common.
{: .prompt-info }


## Configuration 

Configuration files, which are denoted by the `.conf` extension, define various configuration variables that govern the project’s build process. These files fall into several areas that define **machine configuration, distribution configuration, possible compiler tuning, general common configuration, and user configuration**. The main configuration file is the sample bitbake.conf file, which is located within the BitBake source tree conf directory.
由 .conf 扩展名表示的配置文件定义了管理项目构建过程的各种配置变量。 这些文件分为定义机器配置、分发配置、可能的编译器调整、一般通用配置和用户配置的几个区域。 主要配置文件是示例 bitbake.conf 文件，它位于 BitBake 源代码树 conf 目录中。

这里说的 main configuration file 在bitbake 源码路径下的 `./lib/bb/tests/runqueue-tests/conf/bitbake.conf`{: .filepath}
conf文件应该也是可以继承使用的，这里的 main configuration file应该是默认的基本配置。参考：

```
CACHE = "${TOPDIR}/cache"
THISDIR = "${@os.path.dirname(d.getVar('FILE'))}"
COREBASE := "${@os.path.normpath(os.path.dirname(d.getVar('FILE')+'/../../'))}"
EXTRA_BBFILES ?= ""
BBFILES = "${COREBASE}/recipes/*.bb ${EXTRA_BBFILES}"
PROVIDES = "${PN}"
PN = "${@bb.parse.vars_from_file(d.getVar('FILE', False),d)[0]}"
PF = "${BB_CURRENT_MC}:${PN}"
export PATH
TMPDIR ??= "${TOPDIR}"
STAMP = "${TMPDIR}/stamps/${PN}"
T = "${TMPDIR}/workdir/${PN}/temp"
BB_NUMBER_THREADS = "4"

BB_HASHBASE_WHITELIST = "BB_CURRENT_MC BB_HASHSERVE TMPDIR TOPDIR SLOWTASKS SSTATEVALID FILE"

include conf/multiconfig/${BB_CURRENT_MC}.conf
```
{: file='./lib/bb/tests/runqueue-tests/conf/bitbake.conf'}



## Classes

Class files, which are denoted by the `.bbclass` extension, contain information that is useful to share between metadata files. The BitBake source tree currently comes with one class metadata file called `base.bbclass`. You can find this file in the classes directory. The base.bbclass class files is special since it is always included automatically for all recipes and classes. **This class contains definitions for standard basic tasks such as fetching, unpacking, configuring (empty by default), compiling (runs any Makefile present), installing (empty by default) and packaging (empty by default).** **These tasks are often overridden or extended by other classes added during the project development process.**

bitbake将基本的通用功能做成了 `.bbclass` 文件，有一个类继承的设计，基类定义了所有配方都包含的基本任务单元，（获取源码，解压缩，配置，编译，安装，打包等任务）。实际使用中，这个基类是最基础的基类，所有的配方都是有的，一般用户可以自己定义一个派生类继承它，并会override或extend一些任务，以实现自己的配方的特定具体情况，是一个类继承的思想。`base.bbclass`基类路径，在bitbake源码路径下的 `./lib/bb/tests/runqueue-tests/classes/base.bbclass`{: .filepath}


## Layers

`Layers` allow you to isolate different types of customizations from each other. While you might find it tempting to keep everything in one layer when working on a single project, the more modular your metadata, the easier it is to cope with future changes.

layers 允许您将不同类型的定制内容相互隔离。 虽然您可能会发现在处理单个项目时将所有内容都放在一个层中很简单很方便，但元数据越模块化，就越容易应对未来的变化。

To illustrate how you can use layers to keep things modular, consider customizations you might make to support a specific target machine. These types of customizations typically reside in a special layer, rather than a general layer, called a Board Support Package (BSP) layer. Furthermore, the machine customizations should be isolated from recipes and metadata that support a new GUI environment, for example. This situation gives you a couple of layers: one for the machine configurations and one for the GUI environment. It is important to understand, however, that the BSP layer can still make machine-specific additions to recipes within the GUI environment layer without polluting the GUI layer itself with those machine-specific changes. You can accomplish this through a recipe that is a BitBake append (.bbappend) file.

为了说明如何使用层来保持模块化，请考虑您可能进行的定制内容以支持特定的目标机器。 这些类型的定制通常位于一个特殊层，而不是一个通用层，称为板支持包 (BSP) 层。 此外，例如，机器定制应该与支持新 GUI 环境的配方和元数据隔离开来。 这种情况为您提供了几层：一层用于机器配置，一层用于 GUI 环境。 然而，重要的是要理解，BSP 层仍然可以对 GUI 环境层中的配方进行特定于机器的添加，而不会因这些特定于机器的更改而污染 GUI 层本身。 您可以通过作为 BitBake 附加 (.bbappend) 文件的配方来完成此操作。

> 模块化设计思想，有些类似docker的分层。
{: .prompt-tip }




## Append Files

Append files, which are files that have the `.bbappend` file extension, **extend or override information in an existing recipe file**.

BitBake expects every append file to have a corresponding recipe file. Furthermore, the append file and corresponding recipe file must use the same root filename. The filenames can differ only in the file type suffix used (e.g. formfactor_0.0.bb and formfactor_0.0.bbappend).

BitBake 期望每个附加文件都有一个相应的配方文件。 此外，附加文件和相应的配方文件必须使用相同的根文件名。 文件名只能在使用的文件类型后缀上有所不同（例如 formfactor_0.0.bb 和 formfactor_0.0.bbappend）。（还有一个  %  通配符可以扩展匹配）

Information in append files extends or overrides the information in the underlying, similarly-named recipe files.

附加文件中的信息扩展或覆盖了底层、类似名称的配方文件中的信息。

When you name an append file, you can use the **“%” wildcard character** to allow for matching recipe names. For example, suppose you have an append file named as follows: 命名附加文件时，可以使用“%”通配符来匹配配方名称。

```
busybox_1.21.%.bbappend
```

That append file would match any `busybox_1.21.x.bb` version of the recipe. So, the append file would match the following recipe names:

```
busybox_1.21.1.bb
busybox_1.21.2.bb
busybox_1.21.3.bb
```

> The use of the ” % ” character is limited in that it only works directly in front of the .bbappend portion of the append file’s name. You cannot use the wildcard character in any other location of the name.“%”字符的使用受到限制，因为它只能直接在附加文件名称的 .bbappend 部分前面使用。 您不能在名称的任何其他位置使用通配符。
{: .prompt-warning }

If the busybox recipe was updated to busybox_1.3.0.bb, the append name would not match. However, if you named the append file busybox_1.%.bbappend, then you would have a match.**In the most general case, you could name the append file something as simple as busybox_%.bbappend to be entirely version independent**.



---

参考官方文档：[BitBake Documentation](https://docs.yoctoproject.org/bitbake.html)

