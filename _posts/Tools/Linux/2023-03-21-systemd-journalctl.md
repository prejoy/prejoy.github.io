---
title: 'journalctl - systemd辅助日志工具'
date: 2023-03-21 09:42:33 +0800
categories: [Tools, Linux]
tags: [systemd, journalctl, 运维, 日志]
published: true
---


系统日志一般位于 */var/log/* 目录。主要日志文件syslog或messages。查看日志文件可以使用通用的文本查看工具或文本编辑器。
而**使用systemd 作为init程序的系统上，systemd会统一管理所有units的日志**，并额外提供了一个`journalctl`工具来查看、过滤
units的日志。`journalctl`是systemd的日志管理的一部分，systemd中有一个`systemd-journald.service`服务，由它来为systemd
记录日志到系统日志文件中，`journalctl`就可以用来查看由该服务记录的日志。相关的手册可以参考如下。
```bash
$ man 1 journalctl
$ man 8 systemd-journald.service
$ man 5 journald.conf
```

目前主流发行版都使用systemd作为init进程，很多服务也移植为systemd服务了。journalctl有很广的使用空间，这里记录一些使用方式。

# journalctl 基本使用
```
journalctl [OPTIONS...] [MATCHES...]
```
详细细节参考 journalctl man 手册 ，`man 1 journalctl`。

## 输出所有的日志记录

不带任何参数，直接运行`journalctl`，会显示本次启动后，由`systemd-journald.service`服务记录的日志。使用方法同`less`。
有一些高亮提示。
```console
$ journalctl
```

## 日志文件的磁盘空间管理

```console
# 查看系统日志文件的磁盘占用大小情况
$ sudo journalctl --disk-usage

# 指定日志文件占据的最大空间
$ sudo journalctl --vacuum-size=1G

# 指定日志文件保存多久
$ sudo journalctl --vacuum-time=1years
```

另外， 可以通过 `/etc/systemd/journald.conf` 文件来配置 systemd-journald服务的磁盘使用限制等，具体参考man手册。


## 指定时间范围 

参数选项 `-S, --since=, -U, --until=`，指定from S to U。

```console
$ sudo journalctl --since="2012-10-30 18:17:16"
$ sudo journalctl --since "20 min ago"
$ sudo journalctl --since yesterday
$ sudo journalctl --since "2015-01-10" --until "2015-01-11 03:00"
$ sudo journalctl --since 09:00 --until "1 hour ago"
```

## 指定服务名或程序

以ssh服务为例，可以指定服务名，或程序名。使用 `-u, --unit=UNIT|PATTERN` 指定服务名，支持通配符。
也可以直接匹配一个可执行程序。`-u` 参数可以使用多次，指定多个，即一个或关系。

```console
$ sudo journalctl -u ssh.service
$ sudo journalctl /usr/sbin/sshd
```

## 指定最新几行

这个用法类似 tail -n 。

```console
# 显示尾部最后20行日志
$ sudo journalctl -n 20
```

## 使用标准输出模式

默认journalctl使用的是按页输出的，即`less`工具的形式。指定 `--no-pager`参数使用标准输出。

```console
$ journalctl --no-pager
```

## 阻塞输出模式

这个用法类似 tail -f 。可以wait on 等待日志输出，最好继续配合其他选项进行过滤，如服务名。

```console
$ sudo journalctl -f
```


## 输出内核日志

不显示应用层日志，仅显示内核层日志。

```console
$ sudo journalctl -k
```

## 查看设备相关的内核日志

可以查看设备节点的相关内核日志，如
```console
$ sudo journalctl /dev/sda
$ sudo journalctl /dev/nvme0n1  
$ sudo journalctl /dev/sda
```


## 输出过去某次运行日志

可以简单认为一次从开机到关机的所有日志。

```console
# 本次开机启动为止的日志
$ journalctl -b
$ journalctl -b -0

# 上次开机的日志==1,上上次就是2，类推
$ journalctl -b -1

# 配合-k使用，查看上次运行的内核日志
$ sudo journalctl -k -b -1
```

上次，或上几次的日志是保存在系统日志中的，保存的数量可以配置，可以使用命令查看系统保存的次数。
```console
$ journalctl --list-boots
Hint: You are currently not seeing messages from other users and the system.
      Users in groups 'adm', 'systemd-journal' can see all messages.
      Pass -q to turn off this notice.
-3 dfd9de3a32b04e6da9af979a1c1b1b1f Thu 2023-02-16 17:34:39 CST—Fri 2023-02-24 16:08:30 CST
-2 6d74af3182824f989b43d1d75f442e6a Fri 2023-02-24 17:19:06 CST—Thu 2023-03-02 13:44:31 CST
-1 ed4ef5306cc3412b99f18b6ff25dc840 Thu 2023-03-02 14:24:04 CST—Fri 2023-03-17 12:48:54 CST
 0 00738d71a4aa484a88831c64cb5b8e13 Fri 2023-03-17 13:03:19 CST—Wed 2023-03-22 10:43:50 CST
```



## 通过日志级别进行过滤
使用 `-p` 选项来过滤日志的级别。 可以指定的优先级如下：
* 0: emerg
* 1: alert
* 2: crit
* 3: err
* 4: warning
* 5: notice
* 6: info
* 7: debug

```console
# 注意，这里指定的是优先级的名称。
$ sudo journalctl -p err
```


## 日志的持久化存储

参考 `man journald.conf` 的 `Storage=` 字段。





