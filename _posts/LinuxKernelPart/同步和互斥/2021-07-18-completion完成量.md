---
title: 内核-completion（完成量）
date: 2021-07-18 10:32:00 +0800
categories: [Kernel, 互斥和同步]
tags: [并发及同步,  completion, 完成量]
---

在Linux内核中，Completion是一种同步机制，旨在解决异步操作中的同步问题。异步操作是指一个进程或线程在执行一个耗时的任务时，可以继续执行其他任务，而不必等待该耗时任务完成。
但在某些情况下，需要等待该异步任务完成后再继续执行后续的操作，这时就可以使用Completion来实现同步。

## 原理

**Completion同步机制本质是等待队列的同步场景下的一个简化封装。Completion主要用于解决异步操作的同步问题，而等待队列则是一种更加通用的同步机制，可以用于多种同步需求。**

Completion同步机制的实现原理涉及到等待队列（Wait Queue）和原子操作（Atomic Operations）。其数据结构定义较简单,下面是`struct completion`的定义：（位于`/include/linux/completion.h`文件中）
```c
struct completion {
	unsigned int done;
	wait_queue_head_t wait;
};
```

其实就两个成员，一个等待队列头，用于挂起等待Completion完成的进程或线程，另一个done标记,是一个计数器的作用，它的初始值为0，表示异步操作尚未完成。当异步操作完成时，该计数器会被递增为1。

当一个进程或线程需要等待Completion完成时，它会调用`wait_for_completion()`或相关函数。该函数会检查Completion的`done`计数器是否为0，如果不为0，则表示异步操作已经完成，函数会立即返回。
如果`done`计数器为0，则会将当前进程或线程加入到Completion的等待队列中，并把自己挂起（进入睡眠状态），等待被唤醒。当异步操作完成时，其他线程调用`complete()`或相关函数。
该函数会将Completion的`done`计数器递增为1，并唤醒等待队列中的所有挂起进程或线程。这样就实现了Completion的整个过程，在Completion的实现中，为了确保对`done`计数器的操作是原子的，使用spinlock保护，
这个spinlock来源其实就是`wait`成员里面的锁。


## API接口使用

内核头文件`/include/linux/completion.h`,部分接口其实为宏定义。和waitqueue有些类似，但更简单了。

```c
//用于初始化Completion对象。在使用Completion之前，必须先调用此函数来将Completion对象初始化为0，表示异步操作尚未完成。
void init_completion(struct completion *x);

//等待Completion对象的异步操作完成。如果异步操作已经完成（计数器为1），则该函数立即返回；否则，当前进程或线程将被挂起，等待被唤醒。
void wait_for_completion(struct completion *x);
int wait_for_completion_interruptible(struct completion *x);
unsigned long wait_for_completion_timeout(struct completion *x, unsigned long timeout);

//通知Completion对象异步操作已完成。调用该函数会增加Completion的计数器（`done`），将其设置为1，并唤醒等待队列中的所有等待进程或线程。
void complete(struct completion *x);
void complete_all(struct completion *x);
```

这些API提供了Completion同步机制的基本功能。通过初始化Completion、调用`complete()`来标记异步操作完成，以及调用`wait_for_completion()`或`wait_for_completion_timeout()`等接口来等待异步操作完成，
可以实现异步操作的同步等待。通过这些API，可以有效地解决异步操作之间的依赖关系，并在合适的时机实现同步。
