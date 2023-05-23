---
title: 'systemd service配置文件编写'
date: 2020-09-20 14:32:42 +0800
categories: [Tools, systemd]
tags: [systemd]
published: true
img_path: /assets/img/postimgs/Tools/systemd/
---


systemd的service服务配置文件，主要有3个区块，\[Unit\] 区块，\[Install\] 区块，\[Service\] 区块。
详细信息参考， `man 5 systemd.unit`。注意，**配置文件的区块名和字段名，都是大小写敏感的**。


## [Unit]区块

该区块通常是第一个区块，这些参数对于其他系统单元是通用的。会描述一些基本信息，启动顺序和依赖关系等。
详细参考 `man 5 systemd.unit` 的 *[UNIT] SECTION OPTIONS* 部分。一些主要配置项：

Description
: 关于service的一个简要描述。以sshd为例: `Description=OpenBSD Secure Shell server`

Documentation
: 描述该服务或其配置的详细文档，支持列表，使用空格分隔，支持的URI包括 `http://`, `https://`, `file:`, `info:`, `man:`。以sshd服务为例：`Documentation=man:sshd(8) man:sshd_config(5)`

Requires
: 配置对其他服务的需求依赖关系。如果这个服务被激活，则这里列出的unit也被激活。如果其中一个依赖服务激活失败，systemd将不会启动该服务。此选项可以指定多次，也可以指定多个空格分隔的单元。

Wants
: 类似Requires，不过被Wants希望激活的服务，即使失败了，也不影响本身服务运行，而Require相比要求更高，它就会导致自身服务也失败。

BindsTo
: 与Requires也类似，只不过该字段指定的依赖单元如果退出了，也会停止自身服务。

PartOf
: 与Requires也类似，只不过该字段指定的依赖单元stop或restart了，也会同时stop或restart自身服务。

Conflicts
: 冲突的units，填写以空格分隔的unit名称列表，如果指定的冲突units正在运行，则将导致自身服务不运行。

Before, After
: 一个以空格分隔的unit名称列表，用于配置服务之间依赖关系的顺序。

OnFailure
: 一个以空格分隔的unit名称列表，当此服务进入失败状态时激活这些单元名称。


>注意，Wants字段与Requires字段只涉及依赖关系，与启动顺序无关，默认情况下是同时启动的，After和Before字段只涉及启动顺序，不涉及依赖关系。
{: .prompt-warning }



## [Service]区块

该区块主要用于配置systemd的service unit的属性。属于service专用的。参考手册：`man 5 systemd.service`。一些主要属性：

Type
: 配置程序的启动类型，包括
* simple - 服务将 ExecStart字段指定启动的进程作为主要进程，这是默认行为。
* forking - ExecStart字段将以fork()方式启动，服务将子进程作为主要进程。兼容经典的SysV 守护进程模式。
* oneshot - 类似于simple，ExecStart字段指定启动的程序会执行一次，Systemd 会等到它执行完退出为止，再启动其他服务。
* dbus -类似于simple，只是守护进程需要一个D-Bus总线的名称出现。
* notify - 类似于simple，主程序启动结束后，会使用sd_notify或等效调用发送通知消息（notification message）。
* idle - 类似于simple，但是要等到其他任务都执行完，才会启动该服务。一种使用场合是为让该服务的输出，不与其他服务的输出相混合

BusName
: D-Bus总线名称，用于匹配此服务的。对于`Type=dbus`的服务，此选项是必选项。

RemainAfterExit
: 布尔值， 指定即使服务的所有进程都退出，该服务是否被视为活动的。默认为no。

PIDFile
: 指向此守护进程的PID文件的**绝对文件名**。建议在`Type=forking`的服务中使用此选项。服务启动后，Systemd读取守护进程主进程的PID。Systemd不会写入此处配置的文件，它会在服务关闭后删除该文件。

GuessMainPID
: 布尔值，指定如果不能可靠地确定服务的主PID, systemd是否应该猜测。该选项将被忽略，除非设置了`Type=forking`并且没有设置PIDFile。默认为yes。

ExecStart
: 服务启动时执行的命令和参数。一般程序应指定绝对路径。**该选项几乎是必须的。**另外，可以写多行命令。

ExecStartPre/ExecStartPost
: 在ExecStart中的命令之前或之后执行的其他命令。

ExecReload
: Commands to execute to trigger a configuration reload in the service.

ExecStop
: 服务停止时要执行的命令和参数。

ExecStopPost
: 服务停止后要执行的其他命令。

RestartSec
: 重启服务之前休眠的时间(以秒为单位)。

TimeoutStartSec
: 等待服务启动的时间(以秒为单位)。

TimeoutStopSec
: 等待服务停止的时间(以秒为单位)。

TimeoutSec
: 同时配置TimeoutStartSec和TimeoutStopSec的简写。

RuntimeMaxSec
: 服务运行的最大时间(以秒为单位)。通过无穷大(默认值)来配置没有运行时限制。

KillMode
: (该属性属于通用的systemd.kill部分)。定义unit的所有进程如何被杀死。可选值：
* control-group - 当前控制组里面的所有子进程，都会被杀掉。（默认值）
* process - 只杀主进程
* mixed - 主进程将收到 SIGTERM 信号，子进程收到 SIGKILL 信号
* none - 没有进程会被杀掉，只是执行服务的 stop 命令。

Restart
: 配置当服务进程退出、被杀死或达到超时时间时，是否重新启动服务。具体可以参考手册`Restart=`字段。
* no - 不重启服务，（默认值）
* on-success - 当服务进程以(exit code 0)退出时就重启。
* on-failure - 当服务进程以(exit code 非0)退出时就重启。
* on-abnormal - 当服务被信号终止或超时退出时，就重启。
* on-abort - 当服务由于未捕获信号而退出，就重启
* always - 总是重启.

Environment
: 环境变量设置，比如bash中常用的PATH环境变量，这个可以根据程序需要设置，参考格式：`Environment="ONE=one" 'TWO=two two'`

EnvironmentFile
: 环境变量设置文件，效果同 Environment，只是改为从文件读取环境变量。


## [Install]区块

通常是配置文件的最后一个区块，这个区块是所有units文件通用的，用来定义一些unit的安装信息，通常就是开机自启动相关。
参考手册：`man 5 systemd.unit`中的 *[INSTALL] SECTION OPTIONS* 部分。主要属性参考：

Alias
: 此unit文件的别名，（后缀相同），可以使用空格分隔列表。如ssh服务，本身是ssh.service,其定义了`Alias=sshd.service`。

WantedBy/RequiredBy
: 定义该服务依赖的unit，通常是一个或多个Target，配合systemctl enable使用，会在对应的target文件夹中创建软链接。一般WantedBy更常见。

Also
: 安装或卸载此服务时要安装或卸载的附加单元。即一同安装或卸载的单元。


## 参考  
[Systemd 入门教程：命令篇](http://www.ruanyifeng.com/blog/2016/03/systemd-tutorial-commands.html)  
[Systemd 入门教程：实战篇](http://www.ruanyifeng.com/blog/2016/03/systemd-tutorial-part-two.html)  

