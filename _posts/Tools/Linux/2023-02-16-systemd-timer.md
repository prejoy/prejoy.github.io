---
title: '计划任务 systemd-timer 实现'
date: 2022-02-16 09:42:33 +0800
categories: [Tools, Linux]
tags: [systemd, timer, cron, at, 运维]
published: true
---

# 使用systemd timer 代替 cron jobs


与cron jobs 一样，systemd计时器可以在指定的时间间隔触发事件(shell脚本和程序)，例如每天一次，在一个月的特定一天(可能只在星期一)，
或者在上午8点到下午6点的工作时间内每15分钟触发一次事件。计时器还可以做一些cron作业不能做的事情。
例如，计时器可以触发脚本或程序在某个事件之后运行特定的时间，比如引导、启动、完成上一个任务，甚至是计时器调用的服务单元之前完成的时间。


## 系统的维护工作定时器

在使用systemd守护进程的linux系统上，systemd会创建一些系统维护工作的定时器，来完成linux系统后台的一些维护工作，如更新系统数据库，清除tmp临时目录，
归档日志等。

查看系统上所有的systemd定时器：
```console
$ sudo systemctl status *timer
● fstrim.timer - Discard unused blocks once a week
     Loaded: loaded (/lib/systemd/system/fstrim.timer; enabled; vendor preset: enabled)
     Active: active (waiting) since Tue 2023-02-14 17:51:12 CST; 1 day 16h ago
    Trigger: Mon 2023-02-20 00:00:00 CST; 3 days left
   Triggers: ● fstrim.service
       Docs: man:fstrim

Warning: journal has been rotated since unit was started, output may be incomplete.

● e2scrub_all.timer - Periodic ext4 Online Metadata Check for All Filesystems
     Loaded: loaded (/lib/systemd/system/e2scrub_all.timer; enabled; vendor preset: enabled)
     Active: active (waiting) since Tue 2023-02-14 17:51:12 CST; 1 day 16h ago
    Trigger: Sun 2023-02-19 03:10:32 CST; 2 days left
   Triggers: ● e2scrub_all.service

Warning: journal has been rotated since unit was started, output may be incomplete.

● motd-news.timer - Message of the Day
     Loaded: loaded (/lib/systemd/system/motd-news.timer; enabled; vendor preset: enabled)
     Active: active (waiting) since Tue 2023-02-14 17:51:12 CST; 1 day 16h ago
    Trigger: Thu 2023-02-16 15:38:16 CST; 5h 29min left
   Triggers: ● motd-news.service

Warning: journal has been rotated since unit was started, output may be incomplete.

● man-db.timer - Daily man-db regeneration
     Loaded: loaded (/lib/systemd/system/man-db.timer; enabled; vendor preset: enabled)
     Active: active (waiting) since Tue 2023-02-14 17:51:12 CST; 1 day 16h ago
    Trigger: Fri 2023-02-17 00:00:00 CST; 13h left
   Triggers: ● man-db.service
       Docs: man:mandb(8)

Warning: journal has been rotated since unit was started, output may be incomplete.

● logrotate.timer - Daily rotation of log files
     Loaded: loaded (/lib/systemd/system/logrotate.timer; enabled; vendor preset: enabled)
     Active: active (waiting) since Tue 2023-02-14 17:51:12 CST; 1 day 16h ago
    Trigger: Fri 2023-02-17 00:00:00 CST; 13h left
   Triggers: ● logrotate.service
       Docs: man:logrotate(8)
             man:logrotate.conf(5)

Warning: journal has been rotated since unit was started, output may be incomplete.

● anacron.timer - Trigger anacron every hour
     Loaded: loaded (/lib/systemd/system/anacron.timer; enabled; vendor preset: enabled)
     Active: active (waiting) since Tue 2023-02-14 17:51:12 CST; 1 day 16h ago
    Trigger: Thu 2023-02-16 10:32:40 CST; 24min left
   Triggers: ● anacron.service

Warning: journal has been rotated since unit was started, output may be incomplete.

● fwupd-refresh.timer - Refresh fwupd metadata regularly
     Loaded: loaded (/lib/systemd/system/fwupd-refresh.timer; enabled; vendor preset: enabled)
     Active: active (waiting) since Tue 2023-02-14 17:51:12 CST; 1 day 16h ago
    Trigger: Thu 2023-02-16 21:35:03 CST; 11h left
   Triggers: ● fwupd-refresh.service

Warning: journal has been rotated since unit was started, output may be incomplete.

● ua-timer.timer - Ubuntu Advantage Timer for running repeated jobs
     Loaded: loaded (/lib/systemd/system/ua-timer.timer; enabled; vendor preset: enabled)
     Active: active (waiting) since Tue 2023-02-14 17:51:12 CST; 1 day 16h ago
    Trigger: Thu 2023-02-16 16:09:19 CST; 6h left
   Triggers: ● ua-timer.service

Warning: journal has been rotated since unit was started, output may be incomplete.

● apt-daily-upgrade.timer - Daily apt upgrade and clean activities
     Loaded: loaded (/lib/systemd/system/apt-daily-upgrade.timer; enabled; vendor preset: enabled)
     Active: active (waiting) since Tue 2023-02-14 17:51:12 CST; 1 day 16h ago
    Trigger: Fri 2023-02-17 06:45:00 CST; 20h left
   Triggers: ● apt-daily-upgrade.service

Warning: journal has been rotated since unit was started, output may be incomplete.

● apt-daily.timer - Daily apt download activities
     Loaded: loaded (/lib/systemd/system/apt-daily.timer; enabled; vendor preset: enabled)
     Active: active (waiting) since Tue 2023-02-14 17:51:12 CST; 1 day 16h ago
    Trigger: Thu 2023-02-16 10:29:54 CST; 21min left
   Triggers: ● apt-daily.service

Warning: journal has been rotated since unit was started, output may be incomplete.

● systemd-tmpfiles-clean.timer - Daily Cleanup of Temporary Directories
     Loaded: loaded (/lib/systemd/system/systemd-tmpfiles-clean.timer; static; vendor preset: enabled)
     Active: active (waiting) since Tue 2023-02-14 17:51:12 CST; 1 day 16h ago
    Trigger: Thu 2023-02-16 18:06:21 CST; 7h left
   Triggers: ● systemd-tmpfiles-clean.service
       Docs: man:tmpfiles.d(5)
             man:systemd-tmpfiles(8)

Warning: journal has been rotated since unit was started, output may be incomplete.

```

* 第一行：定时器名称和一个简短的功能介绍
* 第二行：显示定时器的状态，是否loaded，对应的.timer定时器文件路径，vendor preset 厂商预置？
* 第三行：激活状态，已激活时间
* 第四行：定时器下次触发生效时间，距离上次触发时的大致时间
* 第五行：定时器的触发对象，即触发时执行的service或event
* 可选行：Docs，该定时器相关联的文档
* 最后行：最近的日志入口，日志是定时器触发执行的service的日志。主要是日志文件里的时间，
  如`Jun 02 08:02:33 debian systemd[1]: Started Run system activity accounting tool every 10 minutes.`这种。


## 创建一个timer

需要创建一个 [service unit](https://opensource.com/article/20/5/manage-startup-systemd)和一个*timer unit*来trigger该服务。

这里演示一个简单的示例，实现定期监控系统内存情况，service主要使用`free`命令来实现内存查看。配合定时器周期执行，实现监控。

在 `/etc/systemd/system `{: .filepath} 或 `/lib/systemd/system`{: .filepath} 路径下创建并编辑文件  `myMonitor.service`{: .filepath},

```
# This service unit is for testing timer units 
# By David Both
# Licensed under GPL V2
#

[Unit]
Description=Logs system statistics to the systemd journal
Wants=myMonitor.timer

[Service]
Type=oneshot
ExecStart=/usr/bin/free

[Install]
WantedBy=multi-user.target
```
{: file="myMonitor.service" }

systemd服务单元运行的程序的标准输出(STDOUT)会被发送到systemd日志。先运行几次,间隔几秒。

```console
sudo systemctl start myMonitor.service
sudo systemctl start myMonitor.service
sudo systemctl start myMonitor.service
sudo systemctl start myMonitor.service
sudo systemctl start myMonitor.service
```

这里使用 `journalctl` 工具来查看系统日志，可以方便的做一些过滤，（也可以直接打开日志文件手动查找，`/var/log/syslog`或`/var/log/message`）
使用 ` -S, --since=, -U, --until=` 选项指定时间范围，使用 `-u, --unit=UNIT|PATTERN` 指定systemd unit (such as a service unit)，
二者组合过滤。

```console
$ sudo journalctl -S today -u myMonitor.service 
-- Logs begin at Thu 2023-02-16 06:12:16 CST, end at Thu 2023-02-16 11:19:53 CST. --
2月 16 11:04:33 debian systemd[1]: Starting Logs system statistics to the systemd journal...
2月 16 11:04:33 debian free[3324927]:               total        used        free      shared  buff/cache   available
2月 16 11:04:33 debian free[3324927]: Mem:      263732092    40874196    83460540      157056   139397356   220860260
2月 16 11:04:33 debian free[3324927]: Swap:       2097148           0     2097148
2月 16 11:04:33 debian systemd[1]: myMonitor.service: Succeeded.
2月 16 11:04:33 debian systemd[1]: Finished Logs system statistics to the systemd journal.
2月 16 11:04:36 debian systemd[1]: Starting Logs system statistics to the systemd journal...
2月 16 11:04:36 debian free[3324955]:               total        used        free      shared  buff/cache   available
2月 16 11:04:36 debian free[3324955]: Mem:      263732092    40945708    83388800      157056   139397584   220788716
2月 16 11:04:36 debian free[3324955]: Swap:       2097148           0     2097148
2月 16 11:04:36 debian systemd[1]: myMonitor.service: Succeeded.
2月 16 11:04:36 debian systemd[1]: Finished Logs system statistics to the systemd journal.
2月 16 11:04:39 debian systemd[1]: Starting Logs system statistics to the systemd journal...
2月 16 11:04:39 debian free[3324981]:               total        used        free      shared  buff/cache   available
2月 16 11:04:39 debian free[3324981]: Mem:      263732092    40955716    83378168      157056   139398208   220778748
2月 16 11:04:39 debian free[3324981]: Swap:       2097148           0     2097148
2月 16 11:04:39 debian systemd[1]: myMonitor.service: Succeeded.
2月 16 11:04:39 debian systemd[1]: Finished Logs system statistics to the systemd journal.
2月 16 11:04:42 debian systemd[1]: Starting Logs system statistics to the systemd journal...
2月 16 11:04:42 debian free[3325008]:               total        used        free      shared  buff/cache   available
2月 16 11:04:42 debian free[3325008]: Mem:      263732092    40953072    83380596      157056   139398424   220781364
2月 16 11:04:42 debian free[3325008]: Swap:       2097148           0     2097148
2月 16 11:04:42 debian systemd[1]: myMonitor.service: Succeeded.
2月 16 11:04:42 debian systemd[1]: Finished Logs system statistics to the systemd journal.
2月 16 11:04:43 debian systemd[1]: Starting Logs system statistics to the systemd journal...
2月 16 11:04:43 debian free[3325015]:               total        used        free      shared  buff/cache   available
2月 16 11:04:43 debian free[3325015]: Mem:      263732092    40953636    83379840      157056   139398616   220780804
2月 16 11:04:43 debian free[3325015]: Swap:       2097148           0     2097148
2月 16 11:04:43 debian systemd[1]: myMonitor.service: Succeeded.
2月 16 11:04:43 debian systemd[1]: Finished Logs system statistics to the systemd journal.

```


myMonitor.service 服务工作正常，现在继续在相同目录下创建 *timer unit* 文件`myMonitor.timer`，并编辑
```
# This timer unit is for testing
# By David Both
# Licensed under GPL V2
#

[Unit]
Description=Logs some system statistics to the systemd journal
Requires=myMonitor.service

[Timer]
Unit=myMonitor.service
OnCalendar=*-*-* *:*:00

[Install]
WantedBy=timers.target
```
{: file="myMonitor.service" }

**其中\[Timer\]的OnCalendar字段表述timer的触发周期。这里应该是每分钟触发一次。**


然后在一个终端中阻塞读取日志，方便查看，journalctl with the **-f (--follow)** option:

```console
$ sudo journalctl -S today -f -u myMonitor.service
-- Logs begin at Thu 2023-02-16 09:03:57 CST. --
```

编写完myMonitor.timer 后，先开好journalctl等待日志，随后启动再次启动myMonitor.service服务。
```console
sudo systemctl start myMonitor.service
```

因为在`myMonitor.service`文件中明确定义了`Wants=myMonitor.timer`，所以这个timer定时器会被自动激活，过几分钟，
查看timer的状态，可以发现该定时器已被激活，应该是服务将其激活的，但是没有使能开机自启动。
```console
$ sudo systemctl status myMonitor.timer
● myMonitor.timer - Logs some system statistics to the systemd journal
     Loaded: loaded (/etc/systemd/system/myMonitor.timer; disabled; vendor preset: enabled)
     Active: active (waiting) since Thu 2023-02-16 13:55:48 CST; 10min ago
    Trigger: Thu 2023-02-16 14:07:00 CST; 34s left
   Triggers: ● myMonitor.service

2月 16 13:55:48 cpr systemd[1]: Started Logs some system statistics to the systemd journal.
```


等几分钟日志，可以看到一个不太“正确”的现象，myMonitor.service 的确被周期执行了，但是并不一定在 :00 秒时执行的，
而且间隔的周期也不固定，不全是1分钟，有的长于1分钟，有的短于1分钟。这其实是systemd有意为之的，不过有方法覆盖这种策略。

这种“故意的不精准”做法是有原因的，主要为了防止多个服务在完全相同的时间触发，如一般使用 `Weekly`, `Daily` 或是其他这种
特殊的时间别名时，它们都会在 *00:00:00* 时刻触发。Systemd的Timer被特意设计为在指定时刻左右偏差随机触发，来防止同时触发。
这个左右偏差的窗口范围\[0s,60s\],即随机时间偏差不会超过1分钟。大多数情况下，这种概率触发定时器都是比较合适的，
大量任务同时触发对系统资源有一个burst，cpu，内存，io，而且系统日志也更容易混在一起。是不友好的。


对于某些对时间要求高的任务，可以**指定更大的触发时间跨度精度(在微秒内)**，通过添加这样的语句到timer unit 文件的 `Timer` section:

```
AccuracySec=1us
```

时间跨度可用于指定所需的精度，以及为重复或一次性事件定义时间跨度。有效的时间跨度单位：

* usec, us, µs
* msec, ms
* seconds, second, sec, s
* minutes, minute, min, m
* hours, hour, hr, h
* days, day, d
* weeks, week, w
* months, month, M (defined as 30.44 days)
* years, year, y (defined as 365.25 days)


`/lib/systemd/system`{: .filepath} 中的所有默认计时器都指定了更大的精度范围，因为确切的时间不是关键时间。
看看系统创建的计时器中的一些规范，还可以查看它们是如何编写定时器的。

```console
$ sudo grep Accur /lib/systemd/system/*timer
/lib/systemd/system/fstrim.timer:AccuracySec=1h
/lib/systemd/system/logrotate.timer:AccuracySec=12h
/lib/systemd/system/man-db.timer:AccuracySec=12h
/lib/systemd/system/snapd.snap-repair.timer:AccuracySec=10min
```


在此例中，没有enable定时器，如果要enable，执行 `systemctl enable myMonitor.timer` 即可自启动。
另外，myMonitor.service 也不需要enable，因为它是有定时器触发的。



## Timer types

Systemd计时器具有cron中没有的其他功能，cron只能在特定的、重复的、实时的日期和时间触发。
Systemd定时器还可以配置为根据其他Systemd Unit的状态的变化来触发。例如，一个timer unit可以配置为在system boot, 
after startup, or after a defined service unit activates 后触发（startup 可能是systemd启动完毕？）这种
就都属于*Monotonic timers*（单次定时器），它们就会在系统引导后执行一次，直到下次重启系统。参考表格：


|        Timer       |     Monotonic     |     Definition   | 
| ------------------ | :----------------: | ---------------- | 
|  OnActiveSec=        |        V        |  This defines a timer relative to the moment the timer is activated.  |
|  OnBootSec=          |        V        |  This defines a timer relative to when the machine boots up.  |
|  OnStartupSec=       |        V        |  This defines a timer relative to when the service manager first starts. For system timer units, this is very similar to `OnBootSec=`, as the system service manager generally starts very early at boot. It's primarily useful when configured in units running in the per-user service manager, as the user service manager generally starts on first login only, not during boot.  |
|  OnUnitActiveSec=    |        V       |  This defines a timer relative to when the timer that is to be activated was last activated.  |
|  OnUnitInactiveSec=  |        V       |  This defines a timer relative to when the timer that is to be activated was last deactivated.  |
|  OnCalendar=         |        X      |   This defines real-time (i.e., wall clock) timers with calendar event expressions. See `systemd.time(7)` for more information on the syntax of calendar event expressions. Otherwise, the semantics are similar to `OnActiveSec=` and related settings. This timer is the one most like those used with the cron service.  |

比如，设置在系统启动后5天，执行一次任务，则配置 `OnBootSec=5d` ，差不多这样，误差1分钟。


## Calendar event specifications

大部分的定时器都是周期性timer，也就是Calendar event。

systemd的timer 使用的时间和日期的格式 和 crontab 是不同的格式，它比crontab更灵活，而且容易理解。

使用 `OnCalendar=` 的 基本格式是 `DOW YYYY-MM-DD HH:MM:SS` ，DOW(day of week)是可选的，其他字段可以使用星号(*)来匹配该位置的任何值。
所有日历时间形式都转换为规范化形式。如果没有指定时间time，则会假设其为00:00:00。如果没有指定日期date，但指定了时间time，
则下一次匹配的时间可能是今天或明天，取决于当前时间。

另外，
* 可以使用名称或数字来代表月份和星期几。可以使用逗号 `,`表示列表，如第10天和第20天就在*DD*处写 `10,20`。
* 单位周期可以用`..`连接，表示在开始值和结束值之间的值，如周一到周五，可以在*DOW*处写`Mon..Fri`这样。（crontab也有相类似的用法符号）。
* 对于日期部分，还有额外选项。波浪号(`~`)可用于指定该月的最后一天或该月最后一天之前的指定天数。`/`用法类似crontab的，`A/B`，从A日期开始，每间隔B都要触发。


|  Calendar  event specification    |    Description    |
| :-------------------------------  | :--------------- |
|   DOW YYYY-MM-DD HH:MM:SS         |      default      | 
|   \*-\*-\* 00:15:30               |    Every day of every month of every year at 15 minutes and 30 seconds after midnight  |
|   Weekly                          |    Every Monday at 00:00:00  |
|   Mon \*-\*-\* 00:00:00           |     Same as weekly  |
|   Mon                             |     Same as weekly  |
|   Wed 2020-\*-\*                  |     Every Wednesday in 2020 at 00:00:00  |
|   Mon..Fri 2021-\*-\*             |     Every weekday in 2021 at 00:00:00  |
|   2022-6,7,8-1,15 01:15:00        |     The 1st and 15th of June, July, and August of 2022 at 01:15:00am  |
|   Mon \*-05~03                     |     The next occurrence of a Monday in May of any year which is also the 3rd day from the end of the month.   |
|   Mon..Fri \*-08~04                |     The 4th day preceding the end of August for any years in which it also falls on a weekday.  |
|   \*-05~03/2                       |    The 3rd day from the end of the month of May and then again two days later. Repeats every year. Note that this expression uses the Tilde (~).   |
|   \*-05-03/2                       |    The third day of the month of may and then every 2nd day for the rest of May. Repeats every year. Note that this expression uses the dash (-).   |



## systemd-analyze 分析测试工具

systemd提供了一个分析和调试工具 `systemd-analyze` , 可以分析systemd相关的大量内容，time 和 calendar 也在其中。
具体的手册参考 `man 1 systemd-analyze` 。

该工具可以解析 *calendar time* 时间规范，并提供相关的规范化信息。使用calendar子命令即可。
包括规范格式后的calendar time，下次触发时间（当前时区和UTC时区）。
示例：

```console
$ systemd-analyze calendar 2030-10-01
  Original form: 2030-10-01                 
Normalized form: 2030-10-01 00:00:00        
    Next elapse: Tue 2030-10-01 00:00:00 CST
       (in UTC): Mon 2030-09-30 16:00:00 UTC
       From now: 7 years 7 months left  
```

对于日历+时间的，一定要用引号包围，否则工具会将其两个时间参数处理：
```console
$ systemd-analyze calendar "2030-10-01 09:00:00"
Normalized form: 2030-10-01 09:00:00        
    Next elapse: Tue 2030-10-01 09:00:00 CST
       (in UTC): Tue 2030-10-01 01:00:00 UTC
       From now: 7 years 7 months left

$ systemd-analyze calendar 2030-10-01 09:00:00
  Original form: 2030-10-01                 
Normalized form: 2030-10-01 00:00:00        
    Next elapse: Tue 2030-10-01 00:00:00 CST
       (in UTC): Mon 2030-09-30 16:00:00 UTC
       From now: 7 years 7 months left      

  Original form: 09:00:00                   
Normalized form: *-*-* 09:00:00             
    Next elapse: Sat 2023-02-18 09:00:00 CST
       (in UTC): Sat 2023-02-18 01:00:00 UTC
       From now: 22h left 
```


最后将规范化的时间写入 `OnCalendar=` 字段，字段这里不能加引号。

systemd-analyze calendar 还有 *--iterations ，--base-time*等其他参数。


## 小结
Systemd计时器可用于执行与cron工具相同的任务，但在日历和触发事件的单调时间规范方面提供了更大的灵活性。
定时器的触发任务也可以由systemctl命令手动立即执行。另外，对于一次性的任务调度，systemd-timer 不如at方便。



## 参考手册
systemd定时器的详细手册，参考man page，包括timer accuracy, event-time specifications, and trigger events.
```
$ man systemd.time
$ man systemd.timer
```

ref:[Use systemd timers instead of cronjobs](https://opensource.com/article/20/7/systemd-timers)
