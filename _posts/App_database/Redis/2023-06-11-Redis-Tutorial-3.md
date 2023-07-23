---
title: Redis-Tutorial-3
date: 2023-06-11 10:15:00 +0800
categories: [App_database, Redis]
tags: [Redis]
---


## Bitmaps

**Bitmaps不是一种真实的数据类型，而是在String类型上定义的一组面向位的操作**。由于**字符串是二进制安全的blob**，其最大长度为512 MB，因此它们适合设置最多2^32个不同的位。

Redis中bitmap的操作有两种：一是对某一位的置位或清除或读取；另一种是对一批位进行操作，如统计指定范围内的数量。

bitmap的主要优点是：有时存储一些信息，是二值的，就可以极大节省内存空间。

**使用`SETBIT`和`GETBIT`命令设置和检索位**:(ex:设置第十位)

```
127.0.0.1:6379> SETBIT mybitmap 10 1
(integer) 0
127.0.0.1:6379> GETBIT mybitmap 10 
(integer) 1
127.0.0.1:6379> GETBIT mybitmap 11
(integer) 0
```

`SETBIT`命令，如果寻址的位数超过当前字符串的长度，该命令会自动增长字符串。
`GETBIT`命令，如果查找的位超出目前字符串最大长度，总是返回0。


**bitmap批量操作命令**

1. `BITOP` : 在不同字符串之间执行逐位操作。提供的操作包括AND、OR、XOR和NOT。
2. `BITCOUNT` : 统计指定范围内bitmap的1的数量。
3. `BITPOS` : 查找第一个指定值为0或1的位。

```
> setbit key 0 1
(integer) 0
> setbit key 100 1
(integer) 0
> bitcount key
(integer) 2
```


## bitfield

Redis中的bitfields类型，它实际上是一种用于存储和操作二进制位的数据结构。

在计算机中，数据存储和处理的最小单位是位（bit），而Redis的bitfields类型允许你在Redis中以位为单位进行操作和存储数据。

Redis的bitfields类型提供了一种方便的方式来处理这种需求。可以创建一个bitfield，类似于一个位数组，其中每个位都可以单独访问和操作。


在位域中，你可以指定位的偏移量和长度，并对它们进行读取、设置或修改。这可以以非常灵活的方式处理二进制数据的特定部分，而不需要存储整个数据结构。
Redis的bitfields类型还提供了一些方便的指令，用于执行各种位级操作，比如位的逻辑运算（AND、OR、XOR）和位的移动。

bitfields类型在存储和处理二进制数据时非常有用。它可以节省存储空间，因为每个位只需要占用一个比特，而不是一个字节。此外，它提供了高效的位级操作，可以在一次命令中完成多个位的读取、设置或修改。

总的来说，Redis的bitfields类型是一种用于存储和操作二进制位的数据结构。它可以帮助你更细粒度地处理数据，以及进行高效的位级操作。
无论是位掩码、标志位、权限管理还是其他与位相关的需求，bitfields类型都可以提供方便且高效的解决方案。


## HyperLogLogs

Redis中的HyperLogLogs类型，它是一种特殊的数据结构，用于估计元素的唯一数量，而不需要存储实际的元素。（用于处理集合中的元素去重计数）。
适合用在需要关闭元素的数量，而不是元素的内容的场景。示例：

统计一个网站的独立访客数量，但不需要为每个访客保留具体内容记录，会浪费大量内存空间，此时使用HyperLogLogs类型就很合适。

HyperLogLogs类型可以估计集合中不同元素的数量，而不需要存储实际的元素本身。它的原理是使用一种称为"基数估计算法"的技术，可以以极低的内存消耗来近似计算集合的基数（不同元素的数量）。

简而言之，HyperLogLogs类型允许你使用非常小的存储空间来估计大量元素的唯一数量。虽然估计值可能会有一定的误差，但在实践中，这种误差通常非常小。

HyperLogLogs类型在处理大规模的数据集合时非常有用。它能够以非常高效的方式对大量的元素进行去重计数，而不会占用太多的内存。这对于统计分析、流量监控、用户活跃度等方面都非常有帮助。


## Geospatial

Redis中一种特殊的数据结构，可以用来存储和处理地理位置信息，比如经纬度坐标。它基本上是一个用于地理位置数据的索引。

geospatial类型使用了一种称为"地理哈希表"的数据结构来存储地理位置信息。每个地理位置被表示为一个点，由经度（longitude）和纬度（latitude）坐标确定。
使用这些坐标，可以将地理位置数据存储在Redis中，并执行一些特定的操作（可以将地理位置表示为一个唯一的标识符，并与其他属性相关联。）。

使用geospatial类型，可以实现如：

1. 添加地理位置：将地理位置及其对应的标识（通常是一个唯一的ID）添加到地理哈希表中。这样，就可以在Redis中建立一个地理位置索引。

2. 搜索附近的位置：根据给定的坐标，在地理哈希表中查找附近的地理位置。这个功能非常有用，比如查找附近的商家、附近的朋友等。

3. 计算距离：可以使用geospatial类型来计算两个地理位置之间的距离。这样，可以确定两个地点之间的准确距离，并进行进一步的分析和比较。

4. 进行地理位置的集合操作：可以对地理位置数据执行集合操作，比如求交集、并集、差集等。这样，可以根据地理位置信息进行更高级的查询和分析。

Redis中的geospatial类型提供了一种简单而有效的方式来存储和处理地理位置信息。它可以帮助我们构建地理位置索引、搜索附近的位置、计算距离等，为地理位置相关的应用提供了强大的功能支持。


## Stream

Redis中的Stream类型，是一种用于处理实时消息流的数据结构。是 Redis 5.0 版本新增加的数据结构。比redis的发布订阅功能更进一步。

Stream是一个有序的消息队列，可以按时间顺序存储和检索消息。每条消息都有一个唯一的ID，你可以使用这个ID来标识和访问特定的消息。

使用Stream类型，可以将新的消息追加到Stream中，并指定一个唯一的ID。还可以为每条消息添加附加数据，比如发送者、时间戳或其他自定义字段。
可以使用命令来读取最新的消息，或者根据消息ID范围进行范围查询。此外，还可以为Stream设置消费者组。消费者组可以有多个消费者，
每个消费者都可以独立地消费Stream中的消息。当一个消费者获取并处理了一条消息后，其他消费者将不再接收该消息。这种方式可以实现消息的多播或者消息的分发处理。

总的来说，Redis的Stream类型是一种用于处理实时消息流的数据结构。它可以高效地存储和检索消息，并支持多个消费者并行处理消息。
无论是实时日志、事件通知还是流式数据分析，Stream类型都可以灵活应对。

