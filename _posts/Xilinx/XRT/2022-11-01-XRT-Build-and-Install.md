---
title: 'XRT Build and Install'
date: 2022-11-01 15:58:10 +0800
categories: [Xilinx, XRT]
tags: [xilinx, xrt]     # TAG names should always be lowercase
published: true
img_path: /assets/img/postimgs/Xilinx/XRT/
---

# 编译和打包

## 源码编译

通常不需要，也不推荐，可以使用xilinx编译好的release版本，除非需要自己修改。

可以由Git仓库clone代码，check tag，并进行构建，生成deb/rpm 包，随后安装。

```console
$ git clone https://github.com/Xilinx/XRT.git
$ cd XRT
$ git tag  # 查看可用的tag
$ git checkout 202220.2.14.384  # 使用2.14 版本的tag 

# 构建steps 参考：https://xilinx.github.io/XRT/master/html/build.html

# 安装依赖
$ sudo <XRT>/src/runtime_src/tools/scripts/xrtdeps.sh   

# 构建
$ cd build
$ ./build.sh

# 打包， rpm或者deb包
$ cd build/Release
$ make package
$ cd ../Debug
$ make package
```

每个版本的ChangeLog：<https://github.com/Xilinx/XRT/blob/master/CHANGELOG.rst>


## 下载官方编译好的包

xilinx提供了各个release版本的编译好的rpm/deb包，但目前没有放在github release page上，？？？

官方是按照**linux发行版版本** + **XRT release 版本** 编译的，提供的软件包也是按照该格式命名的。但是，
目前并未找到明确的网页web页面提供下载链接，通过xilinx其他仓库找到了下载链接。仅具有ubuntu，centos和red hat发行版。

下载链接为：  
ubuntu：  
<https://www.xilinx.com/bin/public/openDownload?filename=xrt_202120.2.12.427_20.04-amd64-xrt.deb>
<https://www.xilinx.com/bin/public/openDownload?filename=xrt_202120.2.12.427_18.04-amd64-xrt.deb>

centos:  
<https://www.xilinx.com/bin/public/openDownload?filename=xrt_202120.2.12.427_7.8.2003-x86_64-xrt.rpm>
<https://www.xilinx.com/bin/public/openDownload?filename=xrt_202120.2.12.427_8.1.1911-x86_64-xrt.rpm>

**根据需要修改对应的xrt tag 名称和发行版的版本号即可**。XRT可以使用较新的版本，不需要完全对应版本。如下载当前最新的release版本（ubuntu20.04环境）
```console
$ cd ~/Downloads
$ wget https://www.xilinx.com/bin/public/openDownload?filename=xrt_202220.2.14.384_20.04-amd64-xrt.deb -O xrt_202220.2.14.384_20.04-amd64-xrt.deb
```


## 安装（Install XRT Software Stack）

根据XRT文档安装即可，正常的包安装。
After XRT installation packages (DEB or RPM) are downloaded from Xilinx website or built from source, 
please install it with the following command

Steps for RHEL/CentOS:
```console
$ sudo yum install xrt_<version>.rpm
```

Steps for Ubuntu:
```console
$ sudo apt install xrt_<version>.deb
```

Steps to reinstall XRT on RHEL/CentOS:
```console
$ sudo yum reinstall ./xrt_<version>.rpm
```

Steps to reinstall XRT on Ubuntu:
```console
$ sudo apt install --reinstall ./xrt_<version>.deb
```

安装完毕后，应当能检查到：
```console
$ apt list --installed | grep xrt

WARNING: apt does not have a stable CLI interface. Use with caution in scripts.

xrt/now 2.14.354 amd64 [installed,local]

$ cat /opt/xilinx/xrt/version.json 
{
  "BUILD_VERSION" : "2.14.354",
  "BUILD_VERSION_DATE" : "Sat, 08 Oct 2022 09:49:58 -0700",
  "BUILD_BRANCH" : "2022.2",
  "VERSION_HASH" : "43926231f7183688add2dccfd391b36a1f000bea",
  "VERSION_HASH_DATE" : "Fri, 7 Oct 2022 10:42:02 +0530"
}
```

安装正确。
