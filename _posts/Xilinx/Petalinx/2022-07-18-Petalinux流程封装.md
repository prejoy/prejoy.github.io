---
title: '个人的Petalinx流程简单封装脚本'
date: 2022-05-19 09:36:38 +0800
categories: [Xilinx, Petalinx]
tags: [Petalinx, workflow]     # TAG names should always be lowercase
published: true
---


Petalinux 参考Xilinx [UG1144](https://www.xilinx.com/search/support-keyword-search.html#q=ug1144) 文档即可。

这里作了一些重复步骤的简单封装，但也有一些问题，需要区分不同的平台，zynqMP和Versal，以及各个版本 2020.2,2021.1,2022.2...等。

## 编译部分

使用离线包，使用默认配置，生成template工程。参考：

```bash
#!/bin/bash

# 为了区别petalinx不同版本
# 要求  petalinx 安装路径结尾以版本号为最后文件夹
# 如 /tools/Petalinux/v2022.1/ ， /tools/Petalinux/v2021.2/ 等


V2020d2_DOWNLOADS='/data/petalinux-offline-cache/v2020.2/downloads'
V2020d2_SSTATE='/data/petalinux-offline-cache/v2020.2/sstate_aarch64_2020.2/aarch64'
V2021d1_DOWNLOADS='/data/petalinux-offline-cache/v2021.1/downloads'
V2021d1_SSTATE='/data/petalinux-offline-cache/v2021.1/sstate_aaarch64_2021.1/aarch64'
V2021d2_DOWNLOADS='/data/petalinux-offline-cache/v2021.2/downloads'
V2021d2_SSTATE='/data/petalinux-offline-cache/v2021.2/sstate_aarch64_2021.2/aarch64'
V2022d1_DOWNLOADS='/data/petalinux-offline-cache/v2022.1/downloads'
V2022d1_SSTATE='/data/petalinux-offline-cache/v2022.1/aarch64'

LOCAL_DOWNLOADS=""
LOCAL_SSTATE=""


PETALINUX_TOOL_VERSION=""
PETALINUX_PROJ_NAME=""
XSA_FILE_PATH=""
SET_XSA=0
XARCH=""

# petalinux-config -c [component]
CFG_CMD=""
DO_CFG=0

# petalinux-build -x [cmd]
EXEC_CMD="build"



##############################################################
#####################    funcionts     #######################
##############################################################
function check_tool {
    petalinux-create --help 1>/dev/null 2>&1
    ret=$?
    if [[ $ret != 0 ]];then
        echo "patalinux tool is not in PATH , config the tool first."
        # pta2002
        exit 1
    fi
}

function check_tool_version {
    str=`echo $PETALINUX`
    PETALINUX_TOOL_VERSION=${str##*/}
    echo "petalinux version : ${PETALINUX_TOOL_VERSION}"
    echo "tool path: $PETALINUX"

}

function show_help {
    echo ""
    echo "usage:"
    echo "$0 [petalinx_project_name] -f [xsa file path] -c [component] -x [build cmd] -a [arch]"
    echo "[petalinx_project_name] is must ,[-f],[-c],[-x],[-a] is optional"
    echo "note:put this script besides the petalinux projects."
    echo "[-a] option is only needed when create a new project,fill in 'zynqMP' or 'versal' "
}

function error_exit {
    show_help
    exit 1
}

# ===  main funciont  ==== 
check_tool
check_tool_version
if [[ ${PETALINUX_TOOL_VERSION} == "v2020.2" ]];then
    LOCAL_DOWNLOADS=${V2020d2_DOWNLOADS}
    LOCAL_SSTATE=${V2020d2_SSTATE}
elif [[ ${PETALINUX_TOOL_VERSION} == "v2021.1" ]];then
    LOCAL_DOWNLOADS=${V2021d1_DOWNLOADS}
    LOCAL_SSTATE=${V2021d1_SSTATE}    
elif [[ ${PETALINUX_TOOL_VERSION} == "v2021.2" ]];then
    LOCAL_DOWNLOADS=${V2021d2_DOWNLOADS}
    LOCAL_SSTATE=${V2021d2_SSTATE}  
elif [[ ${PETALINUX_TOOL_VERSION} == "v2022.1" ]];then
    LOCAL_DOWNLOADS=${V2022d1_DOWNLOADS}
    LOCAL_SSTATE=${V2022d1_SSTATE}  
else
    echo "error version"
fi

echo "LOCAL_DOWNLOADS : ${LOCAL_DOWNLOADS}"
echo "LOCAL_SSTATE : ${LOCAL_SSTATE}"


if [[ $# < 1 ]];then
        echo "we need to specify a project name at least!"
        error_exit
else 
    PETALINUX_PROJ_NAME=${1}
    shift
fi

while getopts "f:x:c:a:h" opt
do
    case ${opt} in 
        f)
            XSA_FILE_PATH=${OPTARG}
            SET_XSA=1
            ;;
        x)
            EXEC_CMD=${OPTARG}
            ;;
        c)
            CFG_CMD=${OPTARG}
            DO_CFG=1
            ;;
        a)
            if [[ ${OPTARG} == "zynqMP" ]];then
                XARCH=${OPTARG}
            elif [[ ${OPTARG} == "versal" ]];then
                XARCH=${OPTARG}
            else 
                echo "unknown arch,exit..."
                exit 1
            fi
            ;;
        h)
            show_help
            exit 0
            ;;
        ?)
            echo "unknown option !"
            error_exit
            ;;
    esac
done

# echo "petalinux project : $PETALINUX_PROJ_NAME"
# echo "xsa file : $XSA_FILE_PATH"
# echo "EXEC_CMD : $EXEC_CMD"
# echo "CFG_CMD  : $CFG_CMD"

# check xsa file
if [[ $SET_XSA == 1 ]];then
    stat ${XSA_FILE_PATH} 1>/dev/null 2>&1
    ret=$?
    if [[ $ret != 0 && $SET_XSA == 1 ]];then
        echo "error:XSA file does not exist"
        error_exit
    fi
else
    echo "not set xsa file"
fi

stat ${PETALINUX_PROJ_NAME} 1>/dev/null 2>&1
ret=$?
if [[ $ret != 0 ]];then
    echo "can't stat petalinux project name."
fi

# echo "set project name : $ret"
# echo "set xsa : $SET_XSA"


# PETALINUX_PROJ_NAME not exist ,create the project 
if [[ $ret != 0 ]];then
    echo "project not exist ,to create it "
    if [[ $SET_XSA == 1 ]];then
        if [[ ${XARCH} == "" ]];then
            echo "error arch name!"
            exit 1
        fi
        petalinux-create --type project --template ${XARCH} --name ${PETALINUX_PROJ_NAME}
        echo "${XARCH}" > ${PETALINUX_PROJ_NAME}/.arch
    else
        echo "error petalinux project name!"
        error_exit
    fi
fi


if [[ $DO_CFG == 1 ]];then
    echo "only config the project"
    petalinux-config -p ${PETALINUX_PROJ_NAME} -c ${CFG_CMD}
    exit 0
fi


# PETALINUX_PROJ_NAME exists ,rebuild or re-import-hwfile project 
# use [-p] option instead of  `cd ${PETALINUX_PROJ_NAME}`
if [[ $SET_XSA == 1 ]];then
    petalinux-config -p ${PETALINUX_PROJ_NAME} --silentconfig --get-hw-description ${XSA_FILE_PATH}

    FILENAME=./${PETALINUX_PROJ_NAME}/project-spec/configs/config
    LN_PRE_MIRROR_URL=`grep -n "CONFIG_PRE_MIRROR_URL" ${FILENAME} | awk -F: '{print $1}'`
    LN_LOCAL_SSTATE_FEEDS_URL=`grep -n "CONFIG_YOCTO_LOCAL_SSTATE_FEEDS_URL" ${FILENAME} | awk -F: '{print $1}'`
    LN_NETWORK_SSTATE_FEED1=`grep -n "CONFIG_YOCTO_NETWORK_SSTATE_FEEDS=" ${FILENAME} | awk -F: '{print $1}'`
    LN_NETWORK_SSTATE_FEED2=`grep -n "CONFIG_YOCTO_NETWORK_SSTATE_FEEDS_URL=" ${FILENAME} | awk -F: '{print $1}'`
    LN_YOCTO_BB_NO_NETWORK=`grep -n "CONFIG_YOCTO_BB_NO_NETWORK" ${FILENAME} | awk -F: '{print $1}'`
    sed -i \
        -e "${LN_PRE_MIRROR_URL}c CONFIG_PRE_MIRROR_URL=\"file://${LOCAL_DOWNLOADS}\"" \
        -e "${LN_LOCAL_SSTATE_FEEDS_URL}c CONFIG_YOCTO_LOCAL_SSTATE_FEEDS_URL=\"${LOCAL_SSTATE}\"" \
        -e "${LN_NETWORK_SSTATE_FEED1}c # CONFIG_YOCTO_NETWORK_SSTATE_FEEDS is not set" \
        -e "${LN_NETWORK_SSTATE_FEED2}d" \
        -e "${LN_YOCTO_BB_NO_NETWORK}c CONFIG_YOCTO_BB_NO_NETWORK=y" \
    ${FILENAME}
    # 这里或许使用menuconfig更好，这样好像会导致 do_fetch
    petalinux-config -p ${PETALINUX_PROJ_NAME} --silentconfig

    # [optional],need to modify project-spec/meta-user/conf/petalinuxbsp.conf  to cancel qemu
    cp -f ./petalinuxbsp_confs/petalinuxbsp_${PETALINUX_TOOL_VERSION}.conf  ${PETALINUX_PROJ_NAME}/project-spec/meta-user/conf/petalinuxbsp.conf
fi

petalinux-build -p ${PETALINUX_PROJ_NAME} -x ${EXEC_CMD}
cd ${PETALINUX_PROJ_NAME} 
petalinux-package --boot --u-boot --format BIN --force
# petalinux-package --prebuilt --force    # 可以不生成 prbuilt ，可以设置使用现有image下载
cd -
exit 0

```
{: file='build_petalinux_proj.sh'}



## JTAG下载运行

### 关于jtag boot功能

需要使用 xsdb / hw_server 工具，（source 对应 vivado 环境即可）。

xsdb工具使用tcl 脚本，但是需要使用其工具去解释脚本，工具可以使用xsct或xsdb。
**xsdb调试设备时，其实是C/S结构，真正去和设备交互的程序是hw_server**，这是一个服务器程序，默认监听在127.0.0.1:3121 端口，xsdb脚本交互时，是与它交互的。

脚本中的筛选，过滤是tcl脚本语言提供的功能。而一些命令则应该是xilinx提供的，放到了xsdb的环境里面。

那么，在编译服务器上，只需要通过简单修改参数，连接目标机器上的hw_server服务器程序，就可以实现远程调试设备了，不需要拷贝到localhost去。

如果hw_server 未运行，xsdb 将自动启动一个仅运行在本地的hw_server，如果需要远程下载，就先手动运行：

`/tools/Xilinx/Vivado/2021.1/bin/hw_server  -S`

可以将其运行在daemon模式，并编写服务，开机运行：

```
[Unit]
Description=Xilinx Hw server ,for download and debug with jtag
After=network.target 

[Service]
Type=forking
ExecStart=/bin/bash /data/tools/Xilinx/Vivado/2021.1/bin/hw_server  -S -d
KillMode=control-group
Restart=on-failure
RestartSec=30

[Install]
WantedBy=multi-user.target
```
{: file='/lib/systemd/system/xilinx-hw-server.service'}

```console
$ systemctl daemon-reload 
$ systemctl enable xilinx-hw-server.service
$ systemctl start xilinx-hw-server.service
$ sudo ss -pntl | grep 3121
LISTEN   0         16                  0.0.0.0:3121             0.0.0.0:*        users:(("hw_server",pid=2258,fd=3))  
```

hw_server 已运行。**目前hw_server 会竞争使用jtag，所以只能开一个版本的，无法多个版本共存。**

### jtag 下载运行

让xilinx 开发板以jtag boot模式启动。

>脚本的过滤功能较简单，如果一台机器上同时存在多个可以下载的xilinx开发板，需要修改过滤方式。
{: .prompt-warning }

```bash
#!/bin/bash

function check_xsdb {
    xsdb -help 1>/dev/null 2>&1
    ret=$?
    if [[ $ret != 0 ]];then
        echo "xsdb tool is not in PATH , config the tool first."
        # vvd2002
        exit 1
    fi
}

function check_tool {
    petalinux-create --help 1>/dev/null 2>&1
    ret=$?
    if [[ $ret != 0 ]];then
        echo "patalinux tool is not in PATH , config the tool first."
        # pta2002
        exit 1
    fi
}

function show_help {
    echo ""
    echo "usage:"
    echo "$0 [petalinx_project_name] -l [boot level] -a [arch] -s [hw server ip]"
    echo "0=reset only"
    echo "1=reserve"
    echo "2=boot uboot only"
    echo "3=boot kernel (default)"
}


# __main__

# levels:
# 0=reset only
# 1=reserve
# 2=boot uboot only
# 3=boot kernel (default)
RUN_LEVEL=3
PROJECT_NAME=""
XARCH=""
HW_SERVER="127.0.0.1"

check_xsdb
check_tool


if [[ $# < 1 ]];then
	echo "need a project name as first parameter!"
    echo "reset the card only"
	RUN_LEVEL=0
else
    PROJECT_NAME=${1}
    stat ${PROJECT_NAME} 1>/dev/null 2>&1
    ret=`echo $?`
    if [[ $ret != 0 ]];then 
        echo "wrong project name:${PROJECT_NAME}!"
        echo "reset the card only"
        RUN_LEVEL=0
    else
        shift
    fi
fi


while getopts "a:s:l:h" opt
do
    case ${opt} in 
        a)
            if [[ ${OPTARG} == "zynqMP" ]];then
                XARCH=${OPTARG}
            elif [[ ${OPTARG} == "versal" ]];then
                XARCH=${OPTARG}
            else 
                echo "unknown arch,exit..."
                exit 1
            fi
            ;;
        s)
            HW_SERVER=${OPTARG}
            ;;
        l)
            RUN_LEVEL=${OPTARG}
            ;;
        h)
            show_help
            exit 0
            ;;
        ?)
            echo "unknown option !"
            error_exit
            ;;
    esac
done


if [[ ${XARCH} == "" ]];then
    XARCH=`cat ${PROJECT_NAME}/.arch 2>/dev/null`
fi


############################################################################
if [[ ${XARCH} == "zynqMP" ]];then

    echo "reseting the card... "
xsdb << EOF
after 1000
connect -host ${HW_SERVER} -port 3121
after 500
targets -set -filter {name =~ "*APU*"}
after 200
rst
after 400
disconnect
EOF
    echo "reset card end,check if card in exception,should shutdown"

    if [[ $RUN_LEVEL == 0 ]];then
        exit 0
    fi

    cd ${PROJECT_NAME}

    if  [[ $RUN_LEVEL == 2 ]];then
        petalinux-boot --jtag --u-boot --fpga --hw_server-url ${HW_SERVER}:3121
    elif [[ $RUN_LEVEL == 3 ]];then
        petalinux-boot --jtag --kernel --fpga  --hw_server-url ${HW_SERVER}:3121
    fi


############################################################################
elif [[ ${XARCH} == "versal" ]];then

    echo "all exec in xsdb..."
    cd ${PROJECT_NAME}
    if  [[ $RUN_LEVEL == 3 ]];then
xsdb << EOF
connect -host ${HW_SERVER} -port 3121
targets -set -filter {name =~ "*xcvc1902*"}
rst
device program ./images/linux/BOOT.BIN
dow -data -force ./images/linux/Image 0x00200000
dow -data -force ./images/linux/rootfs.cpio.gz.u-boot 0x04000000
dow -data -force ./images/linux/system.dtb 0x00001000
disconnect
EOF
# 在串口中启动指令： booti 0x00200000 0x04000000 0x00001000
# 也可以使用fit image，配合bootm 指令

    elif [[ $RUN_LEVEL == 2 ]];then
xsdb << EOF
connect -host ${HW_SERVER} -port 3121
targets -set -filter {name =~ "*xcvc1902*"}
rst
device program ./images/linux/BOOT.BIN
disconnect
EOF
    fi

############################################################################
else
    echo "no arch specift."
    exit 1
fi


# petalinux-boot --jtag --prebuilt 3


# Generate xsdb tcl using petalinux-boot command:
#   $ petalinux-boot --jtag --kernel --fpga --tcl mytcl # images are taken from <PROJECT>/images/linux directory

#   This is similar to UC3, but instead of loading images on target a tcl(mytcl) is generated.
#   This script can be modified further by users and used directly with xsdb to load images. Ex: xsdb mytcl

```
{: file='run_petalinux_image_jtag.sh'}


`petalinux-boot` 对于versal平台似乎有些问题，不能成功下载，这里直接使用xsdb手动下载。另外，如果u-boot自启动配置不正确，
需要在串口中执行自己的启动命令，或修改uboot。

>如果开发板和镜像的网卡可以正确工作，可以通过uboot的 tftpboot/dhcp 功能下载kernel相关镜像，快速启动，jtag仅下载到 u-boot 部分即可
{: .prompt-tip }




