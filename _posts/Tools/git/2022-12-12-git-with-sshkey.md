---
title: 'Git with ssh key'
date: 2022-12-12 23:02:29 +0800
categories: [Tools, Git]
tags: [git, ssh, github]
published: true
---

## 使用ssh key 提交code 到github

在git push 时，会用到该功能。window环境，使用`git bash` 命令行，linux使用`ssh`和`git`命令行工具。

## 生成非对称密钥

```console
$ ssh-keygen -t ed25519 -C "your_email@example.com"
# or
$ ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
```
**这里的email填自己登录github 账户的相同email！**

github官方建议使用 ed25519 形式的，默认生成 `~/.ssh/id_ed25519`和 `~/.ssh/id_ed25519.pub`。

之后，如果有多组密钥，可以分别创建文件夹，放入其中管理。

## 为github 账户添加ssh key
登录github，在 *Settings->SSH and GPG keys* 中，选择**New SSH key**,title中自己起一个名，用于多个设备的情况，可以用来方便区分。**key type**为*Authentication Key*，*Key*内容填写公钥，用于验证私钥。使用命令查看并复制公钥填入即可。
```console
$ cat [path/to/public key]
## example ##
ssh-ed25519 AAAA............................................................. your_email@example.com
```

## 测试密钥可用
测试：
```console
$ ssh -T git@github.com -i [path/to/private key]
```
如果配置成功，github会回应：
“Hi xxx! You've successfully authenticated, but GitHub does not provide shell access.”


## 配置ssh config
linux:`~/.ssh/config`
windows:`C:\Users\xxx\.ssh\config`

```
Host github.com
    HostName github.com
    User [github username]
    IdentityFile [path/to/private key]
    IdentitiesOnly yes
```

配置后，使用ssh协议访问github.com时，（比如git push 时），就会使用指定的私钥了。在有多个私钥时尤其方便。


## 仓库创建

在github创建仓库，之后添加 本地仓库的remote信息，这里尤其要注意，**github官方是HTTPS/SSH/GithubCLI三种协议的，这里使用的一定要是ssh协议的，否则会无法上传**。参考：
```console
$ git remote add origin git@github.com:[github username]/[github repo name].git
$ git remote -v
origin	git@github.com:[github username]/[github repo name].git (fetch)
origin	git@github.com:[github username]/[github repo name].git (push)
```
在comment之后，git push时，git会根据config，自动使用对应的私钥加密，才能push成功。




## 关于隐藏私人邮箱

参考：<https://zhuanlan.zhihu.com/p/421808207>

在本机设置全局用户名和email地址:
```console
$ git config --global user.name "someone"
$ git config --global user.email "someone@hisemail.com"

# 仅对某仓库设置，去掉 --global 即可：
$ cd [repo_dir]
$ git config user.name "someone"
$ git config user.email "someone@hisemail.com"
```

这里的用户名可以随便设置，不需要和github账户一致，关键是邮箱。推荐使用隐私邮箱。
1. 在github 个人设置中开启使用隐私邮箱，设置完后复制
2. 配置git config：
```console
$ git config --global user.name "任何文本"
$ git config --global user.email "ID+username@users.noreply.github.com”
```
