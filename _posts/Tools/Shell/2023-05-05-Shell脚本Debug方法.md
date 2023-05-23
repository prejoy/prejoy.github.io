---
title: 'Shell脚本调试方法'
categories: [Tools, Shell]
tags: [shell, shelldebug, bash]
published: true
---

最简单的调试手段，在shell脚本中添加echo打印，来排查错误，比较繁琐。这里记录一些shell脚本的其他调试方式。

**以下内容全部使用`bash`解释器测试。**



# bash 内置的追踪功能

bash解释器有3个参数帮助调试。`-n`,`-v`,`-x`。

* -n，读一遍脚本中的命令但不执行，用于检查脚本中的语法错误。
* -v，一边执行脚本，一边将执行过的脚本命令打印到标准输出。
* -x，提供跟踪执行信息，将执行的每一条命令和结果依次打印出来。


## 使用`-n` 选项

仅检查语法是否有错误，不会执行脚本中的命令。

写一个带语法错误的脚本测试，屏蔽了一个语法关键字then：
```bash
#!/bin/bash
FILE=$1
if [[ ! -f ${FILE} ]];
# then
    echo "file: ${FILE} not exists"
else
    echo "file: ${FILE} exists"
fi
```

测试，可以报错。
```console
$ bash -n ./mytest.sh 
./mytest.sh: line 6: syntax error near unexpected token `else'
./mytest.sh: line 6: `else'
```

该方式只能检查语法问题。当有多个语法问题时，会在第一个出错的地方就退出。
功能非常有限。



## 使用 `-v` 选项

详细输出模式，逐行或逐块打印待执行的命令和输出。即print cmd，exec cmd，print cmd，exec cmd，...

带测试脚本
```bash
#!/bin/bash

echo "this is my bash script for debug"

FILE=$1
if [[ ! -f ${FILE} ]];
then
    echo "file: ${FILE} not exists"
else
    echo "file: ${FILE} exists"
fi

function myfuncA() {
    echo "just do myfunc A"
    return 2
}

myfuncA
rv=`echo $?`
echo "rv is $rv"

output=`myfuncA`
echo "output is $output"
```

测试运行，在bash解释器后加上 `-v`选项，对整个脚本生效。
```console
$ bash -v ./mytest.sh ./mytest.sh
#!/bin/bash

echo "this is my bash script for debug"
this is my bash script for debug

FILE=$1
if [[ ! -f ${FILE} ]];
then
    echo "file: ${FILE} not exists"
else
    echo "file: ${FILE} exists"
fi
file: ./mytest.sh exists

function myfuncA() {
    echo "just do myfunc A"
    return 2
}

myfuncA
just do myfunc A
rv=`echo $?`
echo "rv is $rv"
rv is 2

output=`myfuncA`
echo "output is $output"
output is just do myfunc A
```

可以看到输出内容较多，打印一行命令并执行一行。因为同时有命令本身的打印，以及命令自身的输出。
其实，shell命令是输出到 `stderr` ，由于stderr和stdout是共用终端的，所以默认就是这样混杂在一起的。
可以将标准错误重定向到文件中，主要可以查看脚本的动态执行路径。

另外，该功能可以通过bash内置的set命令开关，在需要的地方开关一下 `-v`选项的功能，实现仅对一些需要的shell代码块的详细打印，
这样就不会对整个脚本生效了，可以简洁很多。example：仍是上文脚本，仅对第一行打印使用 `-v` 选项。
```bash
#!/bin/bash

set -v     # add here 1
echo "this is my bash script for debug"
set +v     # add here 2

FILE=$1
if [[ ! -f ${FILE} ]];
then
    echo "file: ${FILE} not exists"
else
    echo "file: ${FILE} exists"
fi

function myfuncA() {
    echo "just do myfunc A"
    return 2
}

myfuncA
rv=`echo $?`
echo "rv is $rv"

output=`myfuncA`
echo "output is $output"
```

使用`set -v`开启`-v`功能，在完成第一行打印后直接关闭，使用`set +v`关闭`-v`功能。测试输出：解释器不要加上 `-v` 选项。
```console
$ bash ./mytest.sh ./mytest.sh
echo "this is my bash script for debug"
this is my bash script for debug
set +v
file: ./mytest.sh exists
just do myfunc A
rv is 2
output is just do myfunc A
```

这样就只对局部代码生效。

> 关于`set`这个bash内置命令，可以在bash中输入 `help set` 查看其详细帮助
{: .prompt-tip }


## 使用 `-x` 选项

**strace，追踪模式。这是调试shell脚本的主要方式，功能强大。**  同样可以使用 `set` 命令选择性开启关闭。

追踪执行的语句，打印出来，并在前面加上`+`号标记。另外，它打印的语句是经过变量替换后的语句，即会显示变量的实际内容。
还支持嵌套递归，嵌套的调用（如函数）的追踪会多一个`+`号。

example：
```bash
#!/bin/bash

set -x
echo "this is my bash script for debug"

FILE=$1
if [[ ! -f ${FILE} ]];
then
    echo "file: ${FILE} not exists"
else
    echo "file: ${FILE} exists"
fi
set +x

exit 0
```


测试执行：
```console
$ bash ./mytest.sh ./mytest.sh 
+ echo 'this is my bash script for debug'
this is my bash script for debug
+ FILE=./mytest.sh
+ [[ ! -f ./mytest.sh ]]
+ echo 'file: ./mytest.sh exists'
file: ./mytest.sh exists
+ set +x
```

可以看到，相比于 `-v`选项，有了一些优化，**行首加上了标记以区分命令，且命令的输出已经过替换，将变量内容实际替换上去了**，
非常有利于调试。另外，可以和 `-v` 选择一起使用， `set -xv`，同时显示原命令和替换后的命令。


## `-x`选项的扩展

控制行首打印的具体内容，默认是 `+` 号，这个 `+`号其实是 `$PS4`的内容，可以修改`PS4`，打印更多的信息，如`LINENO`，
`FUNCNAME[$i]`，还有`UID，EUID，PWD，PPID`等等。具体信息可以参考 `man bash` 中 `Shell Variables`部分。

通常修改`PS4` 的默认值，实现自定义信息输出格式，这里打印文件名和行号，example：
```bash

#!/bin/bash

PS4='+ ${BASH_SOURCE[0]}:${LINENO}    exec : '
export PS4   # 可以给子shell使用（如果存在子shell调用）

set -x
echo "this is my bash script for debug"

FILE=$1
if [[ ! -f ${FILE} ]];
then
    echo "file: ${FILE} not exists"
else
    echo "file: ${FILE} exists"
fi
function myfuncA() {
    echo "just do myfunc A"
    return 2
}
myfuncA
set +x

exit 0

```


执行效果：
```console
$ bash ./mytest.sh ./mytest.sh 
+ ./mytest.sh:6    exec : echo 'this is my bash script for debug'
this is my bash script for debug
+ ./mytest.sh:8    exec : FILE=./mytest.sh
+ ./mytest.sh:9    exec : [[ ! -f ./mytest.sh ]]
+ ./mytest.sh:13    exec : echo 'file: ./mytest.sh exists'
file: ./mytest.sh exists
+ ./mytest.sh:19    exec : myfuncA
+ ./mytest.sh:16    exec : echo 'just do myfunc A'
just do myfunc A
+ ./mytest.sh:17    exec : return 2
+ ./mytest.sh:20    exec : set +x
```



# 自定义调试代码

使用一个全局变量，记录调试状态。满足条件才执行后续，如打印。

```bash
_DEBUG="on"

function DEBUG()
{
 [ "$_DEBUG" == "on" ] && echo -n "Debug : " && $@
}

DEBUG echo "test echo line"
```

即通过一个宏开关，动态选择是否执行相关代码。可以配合 `set -x` 使用。




# 其他工具（VSCode扩展）

## shellcheck

该工具也是静态检测工具，通用是静态检测，它比bash内置的 `-n`选项更优秀，错误查找更准确，修复建议也更有效，可以取代默认的 `-n`选项。

安装和使用：
```bash
# 安装
sudo apt install shellcheck

# 检测，如果有语法方面的错误，可以给出很好的修复提示。
# 如果没问题，就没有输出。
shellcheck ./mytest.sh
```

另外，该工具有一个vscode的插件扩展，可以在vscode中安装使用。ShellCheck。



## shfmt

该工具可以较好的format shell的脚本代码，可以和shellcheck配合使用。

```bash
sudo snap install shfmt

# 简单使用
shfmt /mytest.sh
```

该工具也有vscode的扩展插件支持。shell-format。



## BASH Debugger

bashdb是一个类GDB的调试工具，调试效果类似gdb工具。可以运行断点设置、变量查看等常见调试操作。

该工具需要下载后编译安装，软件仓库中未发现。在vscode中可以有插件支持，它提供了 VSCode的插件扩展叫 
[**Bash Debug**](https://marketplace.visualstudio.com/items?itemName=rogalmic.bash-debug)
可以搜索安装。

vscode中 Bash Debug 的配置参考： `launch.json`
```
{
    "version": "0.2.0",
    "configurations": [
        {
            "type": "bashdb",
            "request": "launch",
            "name": "Bash-Debug (simplest configuration)",
            "cwd": "${workspaceFolder}",
            "program": "${workspaceFolder}/mytest.sh",
            "args": []
        }
    ]
}
```
之后，在Debug页面选择该文件进行调试，即可启动图形交互调试。还可以在`DEBUG CONSOLE`中可以输入变量名查看等，进行交互。
另外，有些变量是Bash内置的，也可以查看，具体参考 `man bash`。

---
如果是安装的命令行工具bashdb调试，参考常用命令：
```
 ## 列出代码和查询代码类：
    l  列出当前行以下的10行
    \-  列出正在执行的代码行的前面10行
    .  回到正在执行的代码行
    w 列出正在执行的代码行前后的代码
    /pat/ 向后搜索pat
    ？pat？向前搜索pat

 ## Debug控制类：
    h 帮助
    help 命令 得到命令的具体信息
    q 退出bashdb
    x 算数表达式 计算算数表达式的值，并显示出来
    !!空格Shell命令 参数 执行shell命令
    使用bashdb进行debug的常用命令(cont.)
    print     打印变量值，例如 print $COUNT。
    finish    执行到程序最后或断点处。

 ## 控制脚本执行类：
    n  执行下一条语句，遇到函数，不进入函数里面执行，将函数当作黑盒
    s n 单步执行n次，遇到函数进入函数里面
    b 行号n 在行号n处设置断点      
        （经验证,bashdb的break设置断点命令必须s、s、c然后到这个断点以后,还得重新设置下一个断点,否则不生效,===>即再次s、s、c才行）
    del 行号n 撤销行号n处的断点
    c 行号n 一直执行到行号n处
    R 重新启动
    Finish 执行到程序最后
    cond n expr 条件断点
```


# 参考

<https://blog.csdn.net/m0_37980456/article/details/107644018>  
<https://cloud.tencent.com/developer/article/1614028>  
