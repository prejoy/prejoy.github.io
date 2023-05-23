---
title: 'Login Shell and Interactive Shell'
date: 2020-09-17 14:32:42 +0800
categories: [Tools, Shell]
tags: [LoginShell,login]
published: true
---

Shell是一个命令解释器程序，它读取并解释用户发出的命令。shell可以执行基本命令，如运行程序、输入文本和打印输出。它还负责处理错误和其他需要用户干预的情况。
shell可用于自动化现有任务或完全创建新任务。shell为系统中的许多工具提供了一个公共接口。例如，如果shell需要执行一个需要系统命令的操作，
它将搜索该命令（通过PATH环境变量），然后为用户执行该命令。

Shell具有两种属性，即"Interactive"与"Login"。一个是交互属性，一个是登录属性。
* 按照shell是否与用户进行交互，可以将其分为 交互式(interactive)与 非交互式(non-interactive)。
* 按照shell是否被用户登陆，又可将其分为"login shell"与"non-login shell"。

具体信息查看手册 `man bash` 。

# Interactive and Non-interactive

交互式shell
: 用户最常见的，如通常打开的终端，shell程序会等待用户输入，提交命令，然后立即执行。在用户退出后，shell也最终会退出。


非交互式shell
: 简单说就是shell脚本，shell不与用户交互，而是读取shellscripts脚本文件，并执行其中的命令。当读到文件末尾EOF时，shell终止退出。

## 判断方式

判断`$PS1` 或 `$-`，前者表示命令行提示符参数，后者表示当前shell的启动选项参数。

```
user@debian:~$ echo $-     # 交互式shell
himBHs
user@debian:~$ bash -c 'echo $-'   # 非交互式shell
hBc

user@debian:~$ echo $PS1    # 交互式shell
\[\e]0;\u@\h: \w\a\]${debian_chroot:+($debian_chroot)}\u@\h:\w\$
user@debian:~$ bash -c 'echo $PS1'   # 非交互式shell

user@debian:~$ 
```

主要区别，非交互式shell参数中没有 i(-i参数)，另外就是 `$PS1`的内容是空的。

>bash的 `-c`参数表示从命令行读取字符串作为bash输入（代替文件），会产生非交互式shell
{: .prompt-tip }



# Login Shell and Non-Login Shell

shell 可以分login shell 和non-login shell，以bash shell为例，它在启动时会执行一些预定的脚本来初始化配置它的环境。而login shell 和 
non-login shell 的主要区别就是shell程序初始化启动时，执行的一些预定脚本差异。

## 查看当前shell是否为login shell
查看是否为login shell，可以使用命令：

```bash
echo $0
```

如果开头带一个 `-` 符号的，则是login shell，没有的则是non-logni shell。login shell可能会显示 `-bash`，`-su` 等，non-login shell则会显示
`bash`，`su`等。


```
# just login via ssh
user@debian:~$ echo $0
-bash
user@debian:~$ bash
user@debian:~$ echo $0
bash
user@debian:~$ exit
exit
user@debian:~$ echo $0
-bash
user@debian:~$ 
```

## Login Shell

**login shell 是一个用户登录交互式会话时（如tty终端，SSH，'su -'命令），其user id 下的第一个进程。** 该进程会执行一系列的预配置脚本来设置环境。
图形化登录界面在逻辑上也是属于loginshell的，但它本身不是一个shell。如
```
/etc/profile 
    -> 脚本中会进一步调用 /etc/bash.bashrc  和  /etc/profile.d/*.sh

~/.profile 或 ~/.bash_profile   (bash 和传统的Bourne shell)
    -> 脚本中进步一调用 ~/.bashrc 
######################################################################
/etc/zprofile and ~/.zprofile for zsh, 
/etc/csh.login and ~/.login for csh, etc.
```

**最初始的是从 `/etc/profile` 开始**,先执行系统预设的一些配置，这些都在 /etc/的相关目录下，之后再设置一些用户设定的环境设置，这些就都在用户主目录下了。
zsh和csh也有相关的配置，过程相似，主要配置文件名有不同。


## Non-login Shell

当**在一个已经存在的会话中**启动一个shell，就属于non-login shell，如图形化界面中新建一个终端，在一个shell中启动一个新的shell（命令行），都是如此。
它主要执行的预配置文件会少一些，少掉profile相关的部分。

```
~/.bashrc                      #  for bash
/etc/zshrc and ~/.zshrc        #  for zsh 
/etc/csh.cshrc and ~/.cshrc    #  for csh
```

虽说执行的预配置文件少（不执行 `/etc/profile`），但相应的环境变量如果是通过`export`导出的，那么在后面的shell中其实也都是有效存在的。

>可以通过 `echo`打印 , `export`导出和*临时变量赋值* 进行实践，验证该过程
{: .prompt-tip }

以下示例的环境变量使用export导出,所以都生效，now setting打印显示各个相关文件的echo的执行顺序。
```
# Connection established.
now settting global bashrc
now setting global profile
now setting local bash rc
now setting local profile

user@debian:~$ bash -i
now settting global bashrc
now setting local bash rc

user@debian:~$ env | grep "BASH\|PROFILE"
GBBASHRC=this is global bash rc
LCBASHRC=this is local bash rc
GBPROFILE=this is global profile
LCPROFILE=this is local profile
user@debian:~$ 
```



