---
title: Redis-Tutorial
date: 2023-06-07 09:46:00 +0800
categories: [App_database, Redis]
tags: [Redis]
---


## Key

redis是数据类型的key-value对，redis中，key是二进制级安全的，可以使用常见的字符串如"foo"作为key，
甚至也可以使用jpg图片的内存作为key，空字符串也可以作为一个有效的键值（这个应该相当于一个二进制的0了）。

1. 不建议使用太长的key，如1024字节，会浪费内存，且查找会更加费时。如果确实需要一个很长的值作为key，可以使用其哈希值来替代。
2. 也不建议使用太短的key，如 "user:1000:followers"和"u1000flw"，此时完全可以使用前者，可读性更好，主要是节省的内存并不明显，根据实际需要平衡。
3. 建议使用有规律的特定模式命名key，如"object-type:id"，示例"user:1000"。点或破折号通常用于多字字段，如 "comment:4321:reply.to" 或 "comment:4321:reply-to"
4. key的最大长度是512MB


>命令可以大写，也可以小写，以下主要使用大写，方便区分

## Strings

字符串是最简单的数据类型。可以用作映射一个字符串到另一个字符串，因为key和value都当做字符串使用。

### 设置和读取

使用`SET`和`GET`命令，如果值已经存在则覆盖，并且是忽略类型的（即使该key的现有值不是string类型），所以SET是一个赋值操作。
```
>set name:1 wang
OK
> get name:1
"wang"
> set name:1 lee
OK
> get name:1
"lee"
```

strings的值可以包含二进制数据，甚至可以保存一张jpg图片的内容。value大小不能超过512MB。

`SET`命令还支持一些选项，如仅在value未设置时设置，或仅在value已设置时才能设置（覆盖），具体参考
[SET](https://redis.io/commands/set/)命令参数列表。


**补充1：`GETSET`命令**

可以设置新值，并返回旧值。可以用来读取并更新。

**补充2：`MSET,MGET`命令**

可以在一条命令中，批量设置和批量读取值，可以有效减小延迟，提高性能。读取时，返回列表
```
127.0.0.1:6379> MSET a 10 b 20 c 30
OK
127.0.0.1:6379> MGET a b c
1) "10"
2) "20"
3) "30"
```

**后补充：更多string的特性介绍参考 [Redis Strings](https://redis.io/docs/data-types/strings/) ，更多 [Strings相关命令](https://redis.io/commands/?group=string)**

### 自增自减

有几个命令 `INCR,DECR,INCRBY,DECRBY`，可以把字符串当做整数操作，且**该操作是原子的，atomic**，可以防止竞争。

```
127.0.0.1:6379> set mynum 100
OK
127.0.0.1:6379> INCR mynum
(integer) 101
127.0.0.1:6379> INCR mynum
(integer) 102
127.0.0.1:6379> INCRBY mynum 10
(integer) 112
127.0.0.1:6379> INCRBY mynum 10
(integer) 122
```



## 修改和查询key

redis中很多命令是和数据类型相关的，即特定的数据类型有相关联的几个操作命令。但是也有一些通用的命令，可以与任意类型的key搭配使用。

### 命令查看key信息

**使用 `EXISTS`命令查看key是否已定义在库中，使用`DEL` 删除key(-value 对)。**

如：查询一个key是否在数据库中存在，还可以删除：
```
127.0.0.1:6379> EXISTS mytestkey
(integer) 0
127.0.0.1:6379> SET mytestkey 123
OK
127.0.0.1:6379> EXISTS mytestkey
(integer) 1
127.0.0.1:6379> DEL mytestkey
(integer) 1
127.0.0.1:6379> EXISTS mytestkey
(integer) 0
```
exists 返回1/0,分别表示该key在数据库中存在/不存在。del删除成功返回1，删除失败返回0（库中无该key）。

**使用 `TYPE`命令查看key的value的类型。**

```
127.0.0.1:6379> SET mykey qwer
OK
127.0.0.1:6379> TYPE mykey
string
127.0.0.1:6379> SET mykey 123
OK
127.0.0.1:6379> TYPE mykey
string
127.0.0.1:6379> INCR mykey
(integer) 124
127.0.0.1:6379> DEL mykey
(integer) 1
127.0.0.1:6379> TYPE mykey
none
```

**其他通用命令。。。**


## key有效周期（超时自销）

在redis中的key-value对，不管该key是何种类型，都可以设置超时时间，也叫“time to live”或“TTL”，超过时间后redis自动
销毁该key。

一些注意点：
* 超时时间可以使用秒或毫秒为单位。
* 超时时间的精度是1毫秒
* 超时时间会被复制并保存在磁盘上，所以即使redis服务器程序关闭了，时间也事实过去了。（即redis记录了该key的销毁时间日期）

**使用`EXPIRE` 关键字可以设置key的超时时间**

```
127.0.0.1:6379> GET mykey
(nil)
127.0.0.1:6379> SET mykey qqq
OK
127.0.0.1:6379> EXPIRE mykey 5
(integer) 1
127.0.0.1:6379> GET mykey
"qqq"
#####  这里等5秒钟，让key超时销毁，再查看
127.0.0.1:6379> GET mykey
(nil)
```

**补充1：`PERSIST`命令**

可以删除掉一个key设置的超时时间，即取消一个key已设置的超时。

**补充2：`TTL`命令**

可以查看一个key超时的剩余时间。

补充3：可以使用`SET`命令的`ex` 选项快速设置超时。

补充4：如果要使用毫秒为单位，可以使用 `PEXPIRE`和`PTTL`命令。


```
127.0.0.1:6379> SET mykey qqq ex 15
OK
127.0.0.1:6379> TTL mykey
(integer) 11
127.0.0.1:6379> PTTL mykey
(integer) 8314
```


## Lists

list通常指一个有序元素的序列。**Redis中的lists是通过链表（Linked List）实现的，而不是数组**。这意味着，不管list中已有多少元素，
在该list的头和尾添加或删除元素需要的时间是固定的。缺点是访问元素不快，（数组通过索引可以快速访问到对应元素，而链表去访问对应元素和访问元素
的索引成正比）。

Redis的 `Lists`是通过链表实现的，主要对于数据库系统而言，能快速将元素插入到一个很长的list中是更重要的。
另外一点，可以在固定时间内以固定长度获取。

如果需要快速访问大量元素的中间部分的数据，可以使用`sorted sets`更合适。

### list基本操作命令

一个redis 的list，左边是head，右边是tail，即 `[ head ,...., tail ]`，可以在头部或尾部添加和删除元素。

**`LPUSH,LPOP,RPUSH,RPOP` 命令用于添加或删除元素。返回list中存在的元素数量。**

**`LRANGE` 命令用于查看list中的某一段元素**，需要提供两个索引用于指定区间。索引支持正值和负值，
正值从0开始，letf to right；负值从-1开始，即从尾部向前，`-1`代表最后一个，可以正值和负值混用。
```
127.0.0.1:6379> rpush mylist A
(integer) 1
127.0.0.1:6379> rpush mylist B
(integer) 2
127.0.0.1:6379> lpush mylist C
(integer) 3
127.0.0.1:6379> LRANGE mylist 0 -1
1) "C"
2) "A"
3) "B"
```

**补充1：`LPUSH`和`RPUSH`支持批量添加**

**补充2：当list中无值时，再pop操作会返回null**

```
127.0.0.1:6379> RPUSH mylist a b c
(integer) 6
127.0.0.1:6379> LPUSH mylist 1 2 3 4 
(integer) 10
127.0.0.1:6379> LRANGE mylist 0 -1
 1) "4"
 2) "3"
 3) "2"
 4) "1"
 5) "C"
 6) "A"
 7) "B"
 8) "a"
 9) "b"
10) "c"

127.0.0.1:6379> RPOP mylist 
"c"
127.0.0.1:6379> LPOP mylist 
"4"
127.0.0.1:6379> LRANGE mylist 0 -1
1) "3"
2) "2"
3) "1"
4) "C"
5) "A"
6) "B"
7) "a"
8) "b"
```

list可以用于生产者-消费者模型，堆栈模型。如在应用中获取最新10个元素，（其他应用会动态更新list），只要使用 `LPUSH` 添加
到头部，并使用 `LRANGE 0 9` 就可以获取到最新的10个元素，如互联网上最近更新的10照片。


**`LTRIM` 命令裁剪list**

在很多的应用场景中，只需要最新的几条元素，如社交网络更新，日志等。那么在添加后，可以裁剪掉不需要的元素。
使用`LTRIM`命令，该命令用法类似`LRANGE`命令，提供范围两个索引，将其他的去掉，这个是对list的原地操作。

```
127.0.0.1:6379> RPUSH mylist 1 2 3 4 5 
(integer) 5
127.0.0.1:6379> LTRIM mylist 0 2
OK
127.0.0.1:6379> LRANGE mylist 0 -1
1) "1"
2) "2"
3) "3"

127.0.0.1:6379> LPUSH mylist 7 8
(integer) 5
127.0.0.1:6379> LRANGE mylist 0 -1
1) "8"
2) "7"
3) "1"
4) "2"
5) "3"
```

如上例，裁剪后保留 `[0-2]` 3个元素，是对mylist的直接操作，但是仅是裁剪，没有限制。list在之后仍然可以添加扩展。


补充：虽然LRANGE在技术上是一个O(N)命令，但访问列表头部或尾部的小范围是一个常量时间操作。


### list的阻塞操作

列表有一个特殊的特性，使它们适合于实现队列，并且通常作为进程间通信系统的阻塞操作模块。

如在一个进程生产数据，另一个进程中消费数据，可以使用最简单的方式实现：`LPUSH` 和 `RPOP`命令来实现。

但有时，这个“队列”里面没有数据时，在`RPOP`时，就会返回null，此时就需要消费者进程不断轮询检查了。

为此Redis还提供了POP的阻塞版本命令，`BLPOP`和`BRPOP`，知道“队列”中有数据时才返回。最后有一个超时时间参数。

example：开两个`redis-cli`，

生产者端：
```
127.0.0.1:6379> lrange mylist 0 -1
1) "1"
2) "3"
3) "5"

#### wait some time ####

127.0.0.1:6379> rpush mylist 7
(integer) 1
```

消费者端：
```
127.0.0.1:6379> lpop mylist
"1"
127.0.0.1:6379> blpop mylist 5
1) "mylist"
2) "3"
127.0.0.1:6379> blpop mylist 5
1) "mylist"
2) "5"
127.0.0.1:6379> blpop mylist 5
(nil)
(5.05s)
127.0.0.1:6379> blpop mylist 5
1) "mylist"
2) "7"
(0.94s)
```

会有两种返回，一个是超时后，还未获取到，此时返回 *nil和经历的超时时间*；另一个是获取到了，返回 *key的name和pop出来的value*。

**补充1：超时时间可以设置为0,可以一直阻塞直到有数据返回**

**补充2： 为何`BLPOP`返回值中会有key的name作为一个返回结果，因为`BLPOP`,`BRPOP`是可以一个命令中阻塞等待多个“队列”的，
有一个“队列”有值即会返回，此时就需要知道是哪个“队列”的值了**

```
#### 消费者   ####
127.0.0.1:6379> blpop mylist mylist2 0
1) "mylist2"
2) "2"
(5.14s)

#### 生产者  ####
127.0.0.1:6379> rpush mylist2 1
(integer) 1
127.0.0.1:6379> rpush mylist2 2
(integer) 1
```

**补充3：如果有多个消费者多阻塞等待同一个生产者，按照先来先服务的顺序处理**


### list其他命令

可用`LMOVE`，`BLMOVE`创建更安全的队列或环形队列。

**后补充：更多lists的特性介绍参考 [Redis Lists](https://redis.io/docs/data-types/lists/) ，更多 [Lists相关命令](https://redis.io/commands/?group=list)**



## 自动创建和删除key

redis的特性，**如果列表（Lists）中没有元素，redis会自动删除该key；同时，向一个不存在的list添加元素时，redis会自动创建对应的key。**
不仅是列表，其他由多个元素组成的数据类型，（如Streams, Sets, Sorted Sets and Hashes），也都是这样的。

大概有3条规则总结这个行为：

（1） 当向聚合数据类型添加元素时，如果目标的key不存在，则在添加元素之前创建一个空的聚合数据类型。如果目标key已经存在了，也不允许错误类型的操作命令。

```
> del mylist
(integer) 1
> lpush mylist 1 2 3
(integer) 3

> set foo bar
OK
> lpush foo 1 2 3
(error) WRONGTYPE Operation against a key holding the wrong kind of value
> type foo
string
```

（2）当从聚合数据类型中删除元素时，如果value为空了，对应的key将自动销毁。Stream类型是此规则的唯一例外。

```
> lpush mylist 1 2 3
(integer) 3
> exists mylist
(integer) 1
> lpop mylist
"3"
> lpop mylist
"2"
> lpop mylist
"1"
> exists mylist
(integer) 0
```

（3）对一个不存在key，调用只读命令或一个移除元素的写命令，总是相同的结果。这个结果好像这个key存在一样

```
> del mylist
(integer) 0
> llen mylist
(integer) 0
> lpop mylist
(nil)
> exists mylist
(integer) 0
```

这里删除了mylist这个key，但是调用llen命令和rpop命令时，没有报错，好像这个key存在一样，其实是不存在的。
（llen命令，获取list内的元素个数统计）







# 参考

[Redis Offical](https://redis.io/docs/getting-started/)

[Redis Offical Commands Doc](https://redis.io/commands/)

