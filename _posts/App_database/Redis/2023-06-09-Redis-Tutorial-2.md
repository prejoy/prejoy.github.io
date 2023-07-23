---
title: Redis-Tutorial-2
date: 2023-06-09 09:31:00 +0800
categories: [App_database, Redis]
tags: [Redis]
---


## Hashes

Redis的Hashes类型，是一个key存储的value是多个kv对，定义其实很宽松。该key的类型为hash，
元素值则为多组key-value对，存入的key-value对（元素）数量上没有限制，类型通常是自定义的字符串，
方便用户保存不同类型的hash结果。
大致形式： `[user-key] - [ [key value]  [key value]  [key value] ... ]`

**`HSET`命令（基本），创建/添加元素到Hashes中**

**`HGET`命令，某个hashes中，根据某个元素的key，获取其对应的value**

**`HDEL`命令,根据元素的key删除对应的元素。**

**`HLEN`命令，获取hashes中的元素数量**


```
127.0.0.1:6379> HSET myhashset f1cksum 1234
(integer) 1
127.0.0.1:6379> TYPE myhashset 
hash
127.0.0.1:6379> HLEN myhashset
(integer) 1
127.0.0.1:6379> HSET myhashset f2cksum abcd name wang
(integer) 2
127.0.0.1:6379> HLEN myhashset
(integer) 3
127.0.0.1:6379> HGET myhashset f1cksum
"1234"
127.0.0.1:6379> HGET myhashset name
"wang"
```

**`HMGET`命令，可以获取多个元素的值，是 `HGET`的多数量版本，而`HSET`本身就可以设置多个。对于不存在的filed，值返回nil**

**`HGETALL`命令，可以获取hashes中的全部域和对应的值**

```
127.0.0.1:6379> HMGET myhashset f1cksum f2cksum test-no-exist-fild
1) "1234"
2) "abcd"
3) (nil)

127.0.0.1:6379> HGETALL myhashset
1) "f1cksum"
2) "1234"
3) "f2cksum"
4) "abcd"
5) "name"
6) "wang"
```

**`HINCRBY`命令，可以将元素域的值当做整数增减。**

**`HINCRBYFLOAT`命令，可以将元素域的值当做小数数增减。**

```
127.0.0.1:6379> HSET myhashset testnum 1
(integer) 1
127.0.0.1:6379> HINCRBY myhashset testnum 5
(integer) 6
127.0.0.1:6379> HINCRBY myhashset testnum 5
(integer) 11
127.0.0.1:6379> HINCRBY myhashset testnum -2
(integer) 9
```


**补充1：大部分Redis Hash 命令是O(1)复杂度的，除了少量几个`HKEYS`, `HVALS`,`HGETALL`命令是O(n)复杂度的，n为hashes中元素的数量**

**补充2：小的hashes(i.e., a few elements with small values) 在内存中是使用特殊方式编码的，用于有效节省内存**


### more 

**其他关于Redis Hashes的特性介绍 [Redis Hashes](https://redis.io/docs/data-types/hashes/) ，
命令参考 [Redis Hashes Commands](https://redis.io/commands/?group=hash)。**



## Sets

Redis的集合（Sets）是 **unordered collections** of **strings**。
对集合可以执行的操作主要有，测试给定元素是否已经存在，执行多个集合之间的交集、并集或差值，等等。


**`SADD`命令将新元素添加到集合中。**

**`SREM`命令，删除集合中的元素**

**`SMEMBERS`命令返回集合中的所有数据。**

```
127.0.0.1:6379> SADD myset 1 2 3 
(integer) 3
127.0.0.1:6379> SMEMBERS myset
1) "1"
2) "2"
3) "3"

127.0.0.1:6379> SREM myset 1
(integer) 1
127.0.0.1:6379> SMEMBERS myset
1) "2"
2) "3"
```
注意，返回的set的结果顺序不保证是固定的，因为set是无序的。


**`SISMEMBER`命令，测试元素是否存在于集合中**

测试元素 “2”是否在集合中，返回存在，因为上文添加过了该元素。
```
127.0.0.1:6379> SISMEMBER myset 2
(integer) 1
127.0.0.1:6379> SISMEMBER myset qqqq
(integer) 0
```


集合很适合表达对象之间的关系。例如，我们可以很容易地使用集合来实现标记。

一个简单的示例：为我们想要标记的每个对象设置一个集合。该集合包含与该对象关联的标签的id。

一个例子是给新闻文章加标签。如果一篇文章的ID是1000，关联标签为1、2、5和77，使用集合可以将它们关联起来，
并进一步建立反向关联：

```
127.0.0.1:6379> sadd news:1000:tags 1 2 5 77
(integer) 4
127.0.0.1:6379> sadd tag:1:news 1000
(integer) 1
127.0.0.1:6379> sadd tag:2:news 1000
(integer) 1
127.0.0.1:6379> sadd tag:5:news 1000
(integer) 1
127.0.0.1:6379> sadd tag:77:news 1000
(integer) 1
```

并配合其他数据类型，如Redis hashes，保存文章ID和文章名称等的关系。使用`SMEMBERS` 查看所有相关信息。

**交集操作（intersection）： `SINTER` 命令，返回多个集合的交集部分的内容**
```
sinter tag:1:news tag:2:news tag:5:news
1) "1000"
127.0.0.1:6379> sinter tag:1:news tag:2:news tag:5:news test-null-set
(empty list or set)
```
因为上文中，1,2,5都添加了一个1000，所以1000是它们的交集。而test-null-set不存在，应是作为空集处理，就没有交集。

**补充：除了交集之外，您还可以执行联合、差分、提取随机元素等等。需要使用其他Sets相关命令。**

**随机提取元素（随机从集合中取出一个元素返回）：`SPOP`命令。**
示例：创建一个牌组，随机取出两张。
```
127.0.0.1:6379> SADD deck a1 a2 a3 b1 b2 b3 c1 c2 c3
(integer) 9
127.0.0.1:6379> SPOP deck
"c1"
127.0.0.1:6379> SPOP deck
"a1"
127.0.0.1:6379> SMEMBERS deck
1) "a2"
2) "c2"
3) "b1"
4) "b3"
5) "b2"
6) "a3"
7) "c3"
```


**并集操作(union): `SUNION`命令，以及其衍生命令`SUNIONSTORE`**

```
SUNION key [key ...]
SUNIONSTORE destination key [key ...]
```

如果每次取牌后，需要重新初始化，不是很方便，可以使用并集操作保存到一个副本中。
```
127.0.0.1:6379> SADD bak-deck a1 a2 a3 b1 b2 b3 c1 c2 c3
(integer) 9
127.0.0.1:6379> SUNIONSTORE game:1:deck bak-deck
(integer) 9
127.0.0.1:6379> SMEMBERS game:1:deck
1) "b3"
2) "b1"
3) "a1"
4) "c2"
5) "b2"
6) "a3"
7) "c1"
8) "a2"
9) "c3"
```

上例中，取并集的key只有1个，所以相当于1比1复制了一份。然后存储到新的key（hashes）中。


**获取集合内元素数量：`SCARD`命令**

example:9-2=7
```
127.0.0.1:6379> SCARD game:1:deck
(integer) 9
127.0.0.1:6379> SPOP game:1:deck
"a2"
127.0.0.1:6379> SPOP game:1:deck
"c2"
127.0.0.1:6379> SCARD game:1:deck
(integer) 7
```


**查询集合内随机元素：`SRANDMEMBER`命令**

该命令和`SPOP`有些相似，不同之处在于，该命令仅是peek，不会从集合中拿出元素，而`SPOP`会拿出元素。

```
127.0.0.1:6379> SCARD game:1:deck
(integer) 7
127.0.0.1:6379> SRANDMEMBER game:1:deck
"a1"
127.0.0.1:6379> SRANDMEMBER game:1:deck
"b3"
127.0.0.1:6379> SCARD game:1:deck
(integer) 7
127.0.0.1:6379> SPOP game:1:deck
"a1"
127.0.0.1:6379> SCARD game:1:deck
(integer) 6
```

### more

**其他关于Redis Hashes的特性介绍 [Redis Sets](https://redis.io/docs/data-types/sets/) ，
命令参考 [Redis Set Commands](https://redis.io/commands/?group=set)。**


## Sorted sets

有序集合是一种数据类型，接近于Set和Hash的混合。与集合一样，有序集合也是由唯一的、不重复的字符串元素组成，因此在某种意义上，排序集合也是一个集合。

为何有序集合中的元素是有序的？有序集合中每个元素都会与一个`浮动的点数值`关联，这个浮动的点数值也称为分数`score`,所以，该类型和hashes又有点相似，
因为它的每个元素都映射到一个值。

此外，有序集合中的元素是按顺序获取的，（**有序的“序”是元素的数据结构存储排列有序，并不是可以按序获取对应的元素**），有序集合按照如下规则排序元素：

* 如果有元素A和B，它们各自的score不同，如果A的score 大于 B的score，则redis定义A元素 大于 B元素。
* 如果A和B的score相同，则进一步比A和B的字符串的字典顺序，如果A的字符串字典顺序 大于 B的，则定义A元素大于B元素。A元素和B元素的字符串不可能相同，因为集合的特性，要求元素是唯一的。


**使用`ZADD`命令创建和添加有序集合元素**

该命令和`SADD`有些类似，只是在元素前面添加了一个参数，作为该元素的`score`。也可以多个元素一起添加。

example: 创建一个黑客名称的有序集合，使用他们的出生年份作为`score`。

```
127.0.0.1:6379> ZADD hackers 1940 "Alan Kay"
(integer) 1
127.0.0.1:6379> zadd hackers 1957 "Sophie Wilson"
(integer) 1
127.0.0.1:6379> zadd hackers 1953 "Richard Stallman"
(integer) 1
127.0.0.1:6379> zadd hackers 1949 "Anita Borg"
(integer) 1
127.0.0.1:6379> zadd hackers 1965 "Yukihiro Matsumoto" 1914 "Hedy Lamarr"
(integer) 1
127.0.0.1:6379> zadd hackers 1916 "Claude Shannon" 1969 "Linus Torvalds" 1912 "Alan Turing"
(integer) 1
```

有序集合会在内部将元素根据其score值排序好，大致原理：通过双端口数据结构实现，（同时包含一个跳跃list以及一个hash表），所以，每次向有序集合添加元素时，Redis会执行O(log(N))操作，
有序集合内部已经完成了排序。

**使用 `ZRANGE`或 `ZREVRANGE` 命令显示有序集合内容**

用法类似`LRANG`。

```
127.0.0.1:6379> ZRANGE hackers 0 -1
1) "Alan Turing"
2) "Hedy Lamarr"
3) "Claude Shannon"
4) "Alan Kay"
5) "Anita Borg"
6) "Richard Stallman"
7) "Sophie Wilson"
8) "Yukihiro Matsumoto"
9) "Linus Torvalds"
127.0.0.1:6379> ZREVRANGE hackers 0 -1
1) "Linus Torvalds"
2) "Yukihiro Matsumoto"
3) "Sophie Wilson"
4) "Richard Stallman"
5) "Anita Borg"
6) "Alan Kay"
7) "Claude Shannon"
8) "Hedy Lamarr"
9) "Alan Turing"
```

可以看到，是按照score升序或降序排列好的。

还可以带上score一起显示，补充 `withscores`选项即可。

```
127.0.0.1:6379> ZRANGE hackers 0 -1 withscores
 1) "Alan Turing"
 2) "1912"
 3) "Hedy Lamarr"
 4) "1914"
 5) "Claude Shannon"
 6) "1916"
 7) "Alan Kay"
 8) "1940"
 9) "Anita Borg"
10) "1949"
11) "Richard Stallman"
12) "1953"
13) "Sophie Wilson"
14) "1957"
15) "Yukihiro Matsumoto"
16) "1965"
17) "Linus Torvalds"
18) "1969"
```

### 有序集合可以在范围上操作

如获取 1950年之前的黑客，使用`ZRANGEBYSCORE`命令，在score范围上操作，`-inf`为负无穷，两边的端点值是包含的。

```
127.0.0.1:6379> zrangebyscore hackers -inf 1950
1) "Alan Turing"
2) "Hedy Lamarr"
3) "Claude Shannon"
4) "Alan Kay"
5) "Anita Borg"
```

**按score范围删除元素： `ZREMRANGEBYSCORE` 命令**

删除年龄（score）在1940-1960之间的黑客：
```
127.0.0.1:6379> zremrangebyscore hackers 1940 1960
(integer) 4
127.0.0.1:6379> ZRANGE hackers 0 -1 withscores
 1) "Alan Turing"
 2) "1912"
 3) "Hedy Lamarr"
 4) "1914"
 5) "Claude Shannon"
 6) "1916"
 7) "Yukihiro Matsumoto"
 8) "1965"
 9) "Linus Torvalds"
10) "1969"
```

**get-rank功能，获取元素索引（第几个，不是score值）：`ZRANK`,`ZREVRANK`命令**

注意一下，返回值即可。
```
127.0.0.1:6379> ZRANGE hackers 0 -1
1) "Alan Turing"
2) "Hedy Lamarr"
3) "Claude Shannon"
4) "Yukihiro Matsumoto"
5) "Linus Torvalds"
127.0.0.1:6379> zrank hackers "Alan Turing"
(integer) 0
127.0.0.1:6379> zrank hackers "Claude Shannon"
(integer) 2
127.0.0.1:6379> ZREVRANK hackers "Yukihiro Matsumoto"
(integer) 1
```


### score更新

有序集合的score可以随时更新。只要对已经包含在有序集合中的元素调用`ZADD`，就会以O(log(N))的时间复杂度更新它的分数(和位置)。
**因此，有序集合适用于有大量更新的情况。**

由于这一特点，排行榜是一个常见的使用场景。典型的应用是游戏排行榜，可以根据用户的最高分对其进行排序，并配合 `get-rank`的操作，以显示TopN名用户，
以及用户在排行榜中的排名(例如，“你在这里是第4932名最高分”)。

```
127.0.0.1:6379> ZRANGE hackers 0 -1 withscores
 1) "Alan Turing"
 2) "1912"
 3) "Hedy Lamarr"
 4) "1914"
 5) "Claude Shannon"
 6) "1916"
 7) "Yukihiro Matsumoto"
 8) "1965"
 9) "Linus Torvalds"
10) "1969"
127.0.0.1:6379> ZADD hackers 2012 "Alan Turing"
(integer) 0
127.0.0.1:6379> ZRANGE hackers 0 -1 withscores
 1) "Hedy Lamarr"
 2) "1914"
 3) "Claude Shannon"
 4) "1916"
 5) "Yukihiro Matsumoto"
 6) "1965"
 7) "Linus Torvalds"
 8) "1969"
 9) "Alan Turing"
10) "2012"
```



### more 

**其他关于Redis Hashes的特性介绍 [Redis Sorted Set](https://redis.io/docs/data-types/sorted-sets/) ，
命令参考 [Redis Sorted Set Commands](https://redis.io/commands/?group=sorted-set)。**

