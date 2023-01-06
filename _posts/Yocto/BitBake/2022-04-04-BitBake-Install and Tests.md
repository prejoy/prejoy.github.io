---
title: BitBake Install and Tests
date: 2022-04-04 15:55:00 +0800
categories: [Yocto, BitBake]
tags: [Bitbake]
pin: false
published: true
---


#  Install

安装途径可以使用git clone，发行版的包管理器，特定版本的压缩包，使用工程中附带的（大型工程中可能附带了一个）。**官方推荐使用git clone方式。**
bitbake 本身是一个python脚本，可执行脚本程序，**安装好python环境**并将其添加到`PATH`环境变量即可（optional）。

```console
$ git clone git://git.openembedded.org/bitbake
$ cd bitbake
$ file ./bin/bitbake
./bin/bitbake: Python script, ASCII text executable

$ export PATH=/path/to/bbtutor/bitbake/bin:$PATH
$ export PYTHONPATH=/path/to/bbtutor/bitbake/lib:$PYTHONPATH

```

You usually need a version of BitBake that matches the metadata you are using. The metadata is generally backwards compatible but not forward compatible.  

选用的bitbake版本最好和工程中使用的metadata版本一致，至少不能低于。metadata通常向后兼容，但不向前兼容。其版本号有3种表示方式，（以yocto版本命名对应的，以时间的，以版本号的），选择稳定的版本并checkout。
```
commit 074da4c469d1f4177a1c5be72b9f3ccdfd379d67 (tag: yocto-4.1, tag: 2022-10-langdale, tag: 2.2)
commit c212b0f3b542efa19f15782421196b7f4b64b0b9 (tag: yocto-4.0, tag: 2022-04-kirkstone, tag: 2.0)
```


# 基本使用

bitbake命令是这套工具的主要接口。

```console
$ ./bin/bitbake -h
Unable to init server: Could not connect: Connection refused
Unable to init server: Could not connect: Connection refused
usage: bitbake [-h] [--version] [-b BUILDFILE] [-k] [-f] [-c CMD] [-C INVALIDATE_STAMP] [-r PREFILE] [-R POSTFILE] [-v] [-D] [-q] [-n]
               [-S SIGNATURE_HANDLER] [-p] [-s] [-e] [-g] [-I EXTRA_ASSUME_PROVIDED] [-l DEBUG_DOMAINS] [-P] [-u UI] [--token XMLRPCTOKEN]
               [--revisions-changed] [--server-only] [-B BIND] [-T SERVER_TIMEOUT] [--no-setscene] [--skip-setscene] [--setscene-only]
               [--remote-server REMOTE_SERVER] [-m] [--observe-only] [--status-only] [-w WRITEEVENTLOG] [--runall RUNALL] [--runonly RUNONLY]
               [recipename/target [recipename/target ...]]

It is assumed there is a conf/bblayers.conf available in cwd or in BBPATH which will provide the layer, BBFILES and other configuration
information.

positional arguments:
  recipename/target     Execute the specified task (default is 'build') for these target recipes (.bb files).

optional arguments:
  -h, --help            show this help message and exit
  --version             Show programs version and exit
  -b BUILDFILE, --buildfile BUILDFILE
                        Execute tasks from a specific .bb recipe directly. WARNING: Does not handle any dependencies from other recipes.
  -k, --continue        Continue as much as possible after an error. While the target that failed and anything depending on it cannot be
                        built, as much as possible will be built before stopping.
  -f, --force           Force the specified targets/task to run (invalidating any existing stamp file).
  -c CMD, --cmd CMD     Specify the task to execute. The exact options available depend on the metadata. Some examples might be 'compile' or
                        'populate_sysroot' or 'listtasks' may give a list of the tasks available.
  -C INVALIDATE_STAMP, --clear-stamp INVALIDATE_STAMP
                        Invalidate the stamp for the specified task such as 'compile' and then run the default task for the specified
                        target(s).
  -r PREFILE, --read PREFILE
                        Read the specified file before bitbake.conf.
  -R POSTFILE, --postread POSTFILE
                        Read the specified file after bitbake.conf.
  -v, --verbose         Enable tracing of shell tasks (with 'set -x'). Also print bb.note(...) messages to stdout (in addition to writing them
                        to ${T}/log.do_<task>).
  -D, --debug           Increase the debug level. You can specify this more than once. -D sets the debug level to 1, where only bb.debug(1,
                        ...) messages are printed to stdout; -DD sets the debug level to 2, where both bb.debug(1, ...) and bb.debug(2, ...)
                        messages are printed; etc. Without -D, no debug messages are printed. Note that -D only affects output to stdout. All
                        debug messages are written to ${T}/log.do_taskname, regardless of the debug level.
  -q, --quiet           Output less log message data to the terminal. You can specify this more than once.
  -n, --dry-run         Don't execute, just go through the motions.
  -S SIGNATURE_HANDLER, --dump-signatures SIGNATURE_HANDLER
                        Dump out the signature construction information, with no task execution. The SIGNATURE_HANDLER parameter is passed to
                        the handler. Two common values are none and printdiff but the handler may define more/less. none means only dump the
                        signature, printdiff means compare the dumped signature with the cached one.
  -p, --parse-only      Quit after parsing the BB recipes.
  -s, --show-versions   Show current and preferred versions of all recipes.
  -e, --environment     Show the global or per-recipe environment complete with information about where variables were set/changed.
  -g, --graphviz        Save dependency tree information for the specified targets in the dot syntax.
  -I EXTRA_ASSUME_PROVIDED, --ignore-deps EXTRA_ASSUME_PROVIDED
                        Assume these dependencies don't exist and are already provided (equivalent to ASSUME_PROVIDED). Useful to make
                        dependency graphs more appealing
  -l DEBUG_DOMAINS, --log-domains DEBUG_DOMAINS
                        Show debug logging for the specified logging domains
  -P, --profile         Profile the command and save reports.
  -u UI, --ui UI        The user interface to use (knotty, ncurses, taskexp or teamcity - default knotty).
  --token XMLRPCTOKEN   Specify the connection token to be used when connecting to a remote server.
  --revisions-changed   Set the exit code depending on whether upstream floating revisions have changed or not.
  --server-only         Run bitbake without a UI, only starting a server (cooker) process.
  -B BIND, --bind BIND  The name/address for the bitbake xmlrpc server to bind to.
  -T SERVER_TIMEOUT, --idle-timeout SERVER_TIMEOUT
                        Set timeout to unload bitbake server due to inactivity, set to -1 means no unload, default: Environment variable
                        BB_SERVER_TIMEOUT.
  --no-setscene         Do not run any setscene tasks. sstate will be ignored and everything needed, built.
  --skip-setscene       Skip setscene tasks if they would be executed. Tasks previously restored from sstate will be kept, unlike --no-
                        setscene
  --setscene-only       Only run setscene tasks, don't run any real tasks.
  --remote-server REMOTE_SERVER
                        Connect to the specified server.
  -m, --kill-server     Terminate any running bitbake server.
  --observe-only        Connect to a server as an observing-only client.
  --status-only         Check the status of the remote bitbake server.
  -w WRITEEVENTLOG, --write-log WRITEEVENTLOG
                        Writes the event log of the build to a bitbake event json file. Use '' (empty string) to assign the name
                        automatically.
  --runall RUNALL       Run the specified task for any recipe in the taskgraph of the specified target (even if it wouldn't otherwise have
                        run).
  --runonly RUNONLY     Run only the specified task within the taskgraph of the specified targets (and any task dependencies those tasks may
                        have).
```


## 从单一配方执行任务

这里的单一配方是指 bb 配方文件不会依赖其他文件，较简单。使用是加上 -b 参数即可。使用 -c 参数指定执行的任务，默认执行任务是*build*。

设有foo_1.0.bb 配方文件，执行该配方的*build*任务:
```console
$ bitbake -b foo_1.0.bb
# 等效于
$ bitbake -b foo_1.0.bb -c build
```

执行clean任务，由于不是默认任务，就必须要通过 -c 指定任务：
```console
$ bitbake -b foo.bb -c clean
```

这里的build，clean都是属于常用的基本任务，用户的bb文件可以覆盖或扩展其具体定义。

>  这里的 -b 参数会让bitbake强制不处理配方依赖关系，不建议使用。一般除了调试目的外，不应该使用。
{: .prompt-danger }



## 从一系列配方执行任务

bitbake 在不使用 -b 参数时，自动处理依赖关系，另外只接受 "PROVIDES" 变量提供的名称。不过所有配方都有隐式的提供一个基于文件名的PROVIDES变量，所以可以不提供，用默认的，提供了PROVIDES相当于为.bb配方提供了别名。

```console
$ bitbake foo
# 执行 foo 配方的clean任务
$ bitbake -c clean foo

# 一次执行多个配方的多个任务
$ bitbake myfirstrecipe:do_taskA mysecondrecipe:do_taskB
```


## 生成依赖图

bitbake可以生成依赖关系图，使用 dot 语法，可以将依赖关系图转换为可视化图片（通过[Graphviz](http://www.graphviz.org/)工具）

When you generate a dependency graph, BitBake writes two files to the current working directory:

* task-depends.dot: Shows dependencies between tasks. These dependencies match BitBake’s internal task execution list.
* pn-buildlist: Shows a simple list of targets that are to be built.

To stop depending on common depends, use the -I depend option and BitBake omits them from the graph. Leaving this information out can produce more readable graphs. This way, you can remove from the graph DEPENDS from inherited classes such as base.bbclass.

可以使用 `-I` 参数将依赖停止在公共依赖上，这样关系图更易读。

Here are two examples that create dependency graphs. The second example omits depends common in OpenEmbedded from the graph:

```console
$ bitbake -g foo

$ bitbake -g -I virtual/kernel -I eglibc foo
```

