---
title: Todo list
author: cotes
date: 2019-08-09 20:55:00 +0800
categories: [Blogging, Tutorial]
tags: [getting started]
pin: false
published: false
---


# for config file

- [ ] set image default root path
- [X] set post's default author

# for _data/locales
long time,

- [ ] change authors.yml,done something,maybe ok
- [ ] change contact.yml
- [ ] change share.yml


# 23-01-06

1. 添加PCIe相关posts
2. 添加sidebar-title 支持，可以让sidebar-title 不同于title
3. 接下来准备添加和修改，share，contact的相关图标

bing: 网页分享qq个人
qq,微信的contact可以使用 个人名片的二维码，放上去即可。
http://overtrue.me/share.js/
https://blog.csdn.net/weixin_43856422/article/details/100564537

---
sync commit to release 5.4.0

---

# 23-01-12
修改了 `light-scheme`的 sidebar 背景颜色 `--sidebar-bg` -> `#71ff4347` .
添加较多posts

# 23-02-09
补充了PCIe 文章内容，添加文章（cron at systemd.timer）
修改_config.yml 中的title 和 tagline 

# 23-02-22
添加文章，linux 运维 at，cron，systemd 计时器，脚本工具示例，ssh相关配置
修改了tagline，取消了sidebar的知乎链接

-------------------

可以学习的实例化功能： http://jekyllthemes.org/themes/wu-kan/
其他也可以找找，有没有人实现的功能可以参考。

其他有特色的：
for 播客，音频播放  http://jekyllthemes.org/themes/jekyll-podcaster/
个人简历的              http://jekyllthemes.org/themes/neumorphism/
还有其他图文风格的，不是很适合知识记录分享，但适合个人生活记录，也可以在http://jekyllthemes.org/ 上找

-------------------
sync to  腾讯云开发者社区


--------------------

后续考虑 学习记录的

（1）加入 《程序员的自我修养》书籍笔记，docx  to   markdown   posts


（2）systemd 系统管理守护进程
参考：<https://0pointer.net/blog/archives.html> 的系列文章，已存储百度网盘

* [Rethinking PID 1](http://0pointer.de/blog/projects/systemd.html)
* [systemd for Administrators, Part I](http://0pointer.de/blog/projects/systemd-for-admins-1.html)
* [systemd for Administrators, Part II](http://0pointer.de/blog/projects/systemd-for-admins-2.html)
* [systemd for Administrators, Part III](http://0pointer.de/blog/projects/systemd-for-admins-3.html)
* [systemd for Administrators, Part IV](http://0pointer.de/blog/projects/systemd-for-admins-4.html)
* [systemd for Administrators, Part V](http://0pointer.de/blog/projects/three-levels-of-off.html)
* [systemd for Administrators, Part VI](http://0pointer.de/blog/projects/changing-roots)
* [systemd for Administrators, Part VII](http://0pointer.de/blog/projects/blame-game.html)
* [systemd for Administrators, Part VIII](http://0pointer.de/blog/projects/the-new-configuration-files.html)
* [systemd for Administrators, Part IX](http://0pointer.de/blog/projects/on-etc-sysinit.html)
* [systemd for Administrators, Part X](http://0pointer.de/blog/projects/instances.html)
* [systemd for Administrators, Part XI](http://0pointer.de/blog/projects/inetd.html)

（opt）bootchart and systemd-analyze plot > plot.svg  启动性能分析


(3) linux IPC之 dbus技术

（4） linux 容器基础 ， linux namespace技术， LXC/LXD 容器技术，docker 容器技术