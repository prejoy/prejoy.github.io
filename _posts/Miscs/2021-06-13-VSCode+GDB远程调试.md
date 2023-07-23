---
title: VSCode+GDB远程调试
date: 2021-06-13 10:59:00 +0800
categories: [Miscs]
tags: [VSCode,gdb]
---



在VSCode中，支持使用GDB调试器，可以以图形界面远程调试linux环境的程序。用户通过在图形界面操作，由VSCode代为操作GDB，比较直观，
同时也支持用户输入gdb调试指令。


## 前置条件

1. 在linux系统中安装gdb调试器。`sudo apt install gdb`。准备好待调试的程序。
2. 在VS Code中安装C/C++扩展，点击侧边栏中的扩展图标，搜索"C/C++"，然后选择"C/C++"扩展进行安装。


## 远程后本地调试

在VSCode中安装查件“Remote-SSH”，远程登录到linux目标机器，直接在目标机器上编译和调试。可以配饰ssh客户端配置文件，添加主机。编辑`~/.ssh/config`文件，添加目标机器。

example:
```
Host debian
  HostName 172.16.1.96
  Port 22
  User prejoy
  IdentityFile ~/.ssh/id_rsa
```

在vscode中创建好工程，编译debug版本的程序，侧边栏选择“Run and Debug”，（没有就创建一个launch.json），
然后在`.vscode/launch.json`中添加配置，选择 "C/C++(gdb) Launch"，根据情况调整，参考：
```
{
  "version": "0.2.0",
  "configurations": [
    {
        "name": "debug-myapp",
        "type": "cppdbg",
        "request": "launch",
        "program": "${workspaceFolder}/myapp/myapp",
        "args": [],
        "stopAtEntry": true,
        "cwd": "${workspaceFolder}/myapp",
        "environment": [],
        "externalConsole": false,
        "MIMode": "gdb",
        "miDebuggerPath": "/usr/bin/gdb",
        "setupCommands": [
            {
                "description": "为 gdb 启用整齐打印",
                "text": "-enable-pretty-printing",
                "ignoreFailures": true
            }
        ],
        "preLaunchTask": ""
    }
  ]
}
```

随后，选择对应的配置启动调试。

## 远程后远程调试（真远程）

适用于开发环境和运行环境不是同一台设备的情况。需要在运行环境使用gdbserver。

（1） vscode中，先在使用“remote-ssh”连接到开发环境，建立好工程，并编译完成。

（2） 需要将生成的可执行文件传输到运行环境。位置随意，然后在运行环境中使用gdbserver准备对程序调试，
如`gdbserver :5050 ./myapp [arg list...]`，在所有地址的5050端口上侦听。如果程序需要启动参数，写在后面即可。

（3） 在开发环境的vscode中，在`.vscode/launch.json`中添加配置，选择 "C/C++(gdb) Launch"，主要是添加了
`"miDebuggerServerAddress": "192.168.254.180:5050",` 字段以连接远端服务器。参考：

```
{
  "version": "0.2.0",
  "configurations": [
    {
        "name": "remote debug myapp",
        "type": "cppdbg",
        "request": "launch",
        "program": "${workspaceFolder}/myapp/myapp",
        "args": [],
        "stopAtEntry": true,
        "cwd": "${workspaceFolder}/myapp",
        "environment": [],
        "externalConsole": false,
        "MIMode": "gdb",
        "miDebuggerPath": "/usr/bin/gdb",
        "miDebuggerServerAddress": "192.168.254.180:5050",
        "setupCommands": [
            {
                "description": "Enable pretty-printing for gdb",
                "text": "-enable-pretty-printing",
                "ignoreFailures": true
            },
            {
                "description": "Set Disassembly Flavor to Intel",
                "text": "-gdb-set disassembly-flavor intel",
                "ignoreFailures": true
            }
        ],
        "preLaunchTask": ""
    },
  ]
}
```
进入调试页面，启动调试，在VsCode的Debug界面，
有栈变量信息，watch信息，栈信息，线程信息，断点信息，各个单步调试按钮，右键菜单有更多选项可以用于调试。

注意，被调试的程序在运行环境中需要满足基本运行条件，如依赖的动态共享库需要全部存在于动态库加载路径中等，因为编译环境和运行环境可能有差异，需要注意。
另外一点，被调试程序需要和vscode中准备调试的程序是同一个，在更新程序后，编译后，不要忘记同步到运行环境中。可以使用配置中的`preLaunchTask`字段，
设置运行前置任务，通过脚本，完成编译更新和远程同步的工作。


## vscode中使用gdb指令

启动调试后，vscode支持用户输入gdb指令。

选择底部的“DEBUG CONSOLE”栏，可以在里面输入信息，本身是用来和vscode的调试功能交互的，对于GDB调试器，vscode支持执行gdb指令，
只需输入 `-exec <gdb cmd>`即可执行gdb指令，比较方便。这里的`-exec`是不能省略的，表示将后面的命令传送给GDB调试器，因为接收指令的解析器还不是GDB，
所以需要使用`-exec`表明功能。



## 更多参考

[VSCode Debugging](https://code.visualstudio.com/Docs/editor/debugging)

[Configure C/C++ debugging](https://code.visualstudio.com/docs/cpp/launch-json-reference)

[Debug C++ in Visual Studio Code](https://code.visualstudio.com/docs/cpp/cpp-debug)
