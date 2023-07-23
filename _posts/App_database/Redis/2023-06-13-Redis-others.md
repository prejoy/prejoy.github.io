---
title: Redis-其他特性
date: 2023-06-13 10:59:00 +0800
categories: [App_database, Redis]
tags: [Redis]
---


## 发布/订阅模式

这是redis中的一种消息通信格式，定义了发布者和订阅者，发布者发送消息，订阅者接收消息。二者直接加入了一个channel通道的逻辑抽象以分层。
发布者发布信息到“通道”中，订阅者从“通道”中获取，“通道”是广播的，发布者发布了一个消息到“通道”中，所有订阅该“通道”的订阅者都会收到一份副本信息。
特点：**单向，广播，阻塞**。

example：订阅者先订阅channel，虽然在新的终端再开一个redis-cli，作为发布者向对应的channel发送信息。

订阅者
```
127.0.0.1:6379> SUBSCRIBE myvtchannel 
Reading messages... (press Ctrl-C to quit)
1) "subscribe"
2) "myvtchannel"
3) (integer) 1
1) "message"
2) "myvtchannel"
3) "text1"
1) "message"
2) "myvtchannel"
3) "12345"
```

发布者
```
127.0.0.1:6379> PUBLISH myvtchannel text1
(integer) 1
127.0.0.1:6379> PUBLISH myvtchannel 12345
(integer) 1
```

订阅可以同时订阅多个channel，发布可以一次发布多条信息，具体参考命令手册。


### 相关命令

Redis中与发布和订阅相关的常用命令。可以创建和管理频道的订阅者，并与其他客户端实时地进行消息传递。

1. `SUBSCRIBE channel [channel ...]`
   - 作用：订阅一个或多个频道，接收发布者发送到这些频道的消息。

2. `UNSUBSCRIBE [channel [channel ...]]`
   - 作用：取消订阅一个或多个频道，如果不指定频道参数，则取消订阅所有频道。

3. `PSUBSCRIBE pattern [pattern ...]`
   - 作用：使用模式匹配订阅一个或多个符合给定模式的频道。

5. `PUBLISH channel message`
   - 作用：向指定频道发布一条消息，订阅该频道的所有订阅者都会接收到该消息。

6. `PUBSUB subcommand [argument [argument ...]]`
   - 作用：执行不同的发布订阅操作，包括查看订阅与发布系统状态、获取订阅者数量等。

### 参考

[Redis Pub/Sub](https://redis.io/docs/manual/pubsub/)

[Pub/Sub Commands](https://redis.io/commands/?group=pubsub)





## 事务（Transactions）


在Redis中，事务（Transactions）是一种将一组命令打包执行的机制，可以保证这些命令在执行过程中不会被其他客户端的命令中断。
Redis 事务以`MULTI`命令开始，到`EXEC`命令结束，在这两个命令之间的命令会放入事务队列，等到`EXEC`命令执行后，再开始执行，
执行期间不会被其他客户端的命令插入。如果事务中有命令执行失败，其余的命令依然执行。事务将多个操作作为一个原子操作进行处理。

整体过程为 开始事务-命令入队-执行事务。


example:
```
127.0.0.1:6379> MULTI
OK
127.0.0.1:6379> SET user wang
QUEUED
127.0.0.1:6379> GET user
QUEUED
127.0.0.1:6379> SADD dbs redis mysql sqlserver mongodb
QUEUED
127.0.0.1:6379> SMEMBERS dbs
QUEUED
127.0.0.1:6379> EXEC
1) OK
2) "wang"
3) (integer) 4
4) 1) "mongodb"
   2) "sqlserver"
   3) "mysql"
   4) "redis"
```


### 事务相关命令

1. `MULTI`
   - 作用：标记事务块的开始。接下来的命令将被添加到事务队列中，而不会立即执行。

2. `EXEC`
   - 作用：执行事务中的所有命令。Redis将按照命令在事务队列中的顺序执行这些命令，并将结果返回。

3. `DISCARD`
   - 作用：取消当前事务，清除事务队列中的所有命令。

4. `WATCH key [key ...]`
   - 作用：监视一个或多个键，如果在事务执行过程中有任何被监视的键被修改，则事务会被中断。

5. `UNWATCH`
   - 作用：取消对所有键的监视。


### 参考

[Redis Transactions](https://redis.io/docs/manual/transactions/)

[Transactions Commands](https://redis.io/commands/?group=transactions)



## 备份和恢复（持久化功能）

Redis提供了备份和恢复功能，可以用于将Redis数据进行备份并在需要时进行恢复。这些功能使得用户可以对数据进行持久化和灾难恢复，
以确保数据的安全性和可靠性。Redis提供了两种备份方式：RDB快照（snapshot）和AOF日志（append-only file）。

**RDB快照**

RDB快照是将Redis数据以二进制文件的形式保存到磁盘中。它是一种点对点备份方式，可以在需要时快速恢复数据。
使用`SAVE`命令手动创建RDB快照，或者使用配置文件中的自动快照规则进行定期备份。

redis的`SAVE`命令可以创建当前数据库的备份，到磁盘文件上，默认存储到redis安装目录的`dump.rdb`二进制文件。

还有一个 `BGSAVE`命令，可以在后台异步存储，`SAVE`是同步执行的。

恢复时，将文件放到redis安装目录，并启动redis-server服务即可。有些配置是相关的。
```
CONFIG GET dir
1) "dir"
2) "/var/lib/redis"
CONFIG GET dbfilename
1) "dbfilename"
2) "dump.rdb"
```

详细内容参考：[Redis persistence](https://redis.io/docs/management/persistence/)，和redis版本有关。



## 管道技术（pipelining）

一种优化客户端-服务器之间的通信方法。通过使用管道，客户端可以将多个命令一次性发送给服务器，而无需等待每个命令的响应，从而显著提高了通信效率。
管道中的命令仅是一批次处理，并不是事务，是可以被其他客户端插入的。

使用管道技术可以在以下情况下获得最佳性能提升：
* 需要执行**大量命令的批量操作**。
* **需要在一个请求中获取多个命令的结果**。
* 在**高延迟网络环境下，通过减少通信次数来提高性能**。
  
使用Redis管道技术时，客户端需要按照一定的顺序将命令发送到服务器，并适当地处理命令的响应。管道技术可以通过Redis客户端库或使用Redis协议自行实现。

管道的核心特点就是批量发送和批量接收命令，通过批量操作，可以有效提高Redis的性能和效率，并减少网络开销和通信延迟，进一步提高性能表现。

**补充：管道，对于批量操作的性能提升是非常有效的，可以多使用使用。具体根据使用的redis客户端接口使用。**

详细内容参考：[Redis pipelining](https://redis.io/docs/manual/pipelining/)


