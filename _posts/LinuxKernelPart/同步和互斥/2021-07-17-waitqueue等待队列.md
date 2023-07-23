---
title: 内核-waitqueue（等待队列）
date: 2021-07-17 10:32:00 +0800
categories: [Kernel, 互斥和同步]
tags: [并发及同步,  waitqueue, 等待队列]
---

## 介绍

在Linux内核中，等待队列（Wait Queue）是一种用于多任务调度和同步的机制。它是一种双向链表的数据结构，用于管理等待某个条件满足的进程或线程的列表。
等待队列通常与同步原语（如信号量、互斥锁等）一起使用，以便在满足特定条件之前，将进程或线程置于休眠状态。

**等待队列用于解决并发环境中的竞争条件和资源竞争问题。当某个任务需要等待特定条件的发生时，它可以加入等待队列，并进入睡眠状态，释放CPU的使用权。一旦条件满足，等待队列中的任务将被唤醒，可以再次竞争CPU的使用权。**

在Linux内核中，等待队列通常由等待队列头（Wait Queue Head）结构表示，它包含了一个指向等待队列中等待任务的指针列表。等待队列头是一个队列的头部，表示一个特定的条件或事件。当等待的条件满足时，等待队列头将唤醒等待队列中的任务。

等待队列的典型用途包括等待锁释放、等待设备就绪、等待事件发生等。通过使用等待队列，内核可以有效地管理多个任务之间的同步和调度，以避免竞争条件和提高系统的性能和可靠性。



## 大致原理

先看看等待队列的数据结构，数据结构定义位于 `/include/linux/wait.h`中：
```c
typedef struct wait_queue_entry wait_queue_entry_t;
typedef int (*wait_queue_func_t)(struct wait_queue_entry *wq_entry, unsigned mode, int flags, void *key);
/*
 * A single wait-queue entry structure:
 */
struct wait_queue_entry {
	unsigned int		flags;
	void			*private;
	wait_queue_func_t	func;
	struct list_head	entry;
};

struct wait_queue_head {
	spinlock_t		lock;
	struct list_head	head;
};
typedef struct wait_queue_head wait_queue_head_t;
```

等待队列头（Wait Queue Head）数据结构，用于管理等待队列中等待任务的指针列表。它通常作为等待条件或事件的标识符，在内核中定义为`wait_queue_head_t`类型。
等待队列头可以由内核提供的宏或函数进行初始化、唤醒等待的任务以及将任务添加到等待队列中。

等待队列项（Wait Queue Entry）是等待队列中的每个任务或进程的数据结构。它通常作为任务或进程的一部分，用于跟踪其在等待队列中的状态和位置。
等待队列项的定义通常包含任务的标识符、等待条件的状态、指向下一个等待队列项的指针等。

等待和唤醒机制：当任务需要等待某个条件满足时，它会通过调用等待队列相关的函数将自己添加到等待队列中，并进入睡眠状态。这会导致任务释放CPU的使用权，允许其他任务执行。
当条件满足时，其他地方需要调用相应的唤醒函数，这些唤醒函数会遍历等待队列，找到等待队列中与条件相关的任务，并将其从睡眠状态唤醒，使其可以再次竞争CPU的使用权。
等待队列通常与其他同步原语（如信号量、互斥锁等）一起使用，以确保在等待队列中的任务被唤醒时，所等待的条件确实已经满足，并且没有其他竞争条件发生。


## API接口

以下是一些与等待队列相关的常见API接口，有一些是宏定义实现的，这里写出了其等效的类型申明：（内核头文件 `/include/linux/wait.h`）
```c
// 该函数用于初始化一个等待队列头，将其用于管理等待队列中的任务。
void init_waitqueue_head(wait_queue_head_t *q);

// 该函数用于唤醒指定的等待队列中的所有任务，使它们可以再次竞争CPU的使用权。
void wake_up(wait_queue_head_t *q);

// 该函数用于唤醒指定的等待队列中处于可中断睡眠状态的任务，允许它们被唤醒并继续执行。
void wake_up_interruptible(wait_queue_head_t *q);


// 参数：`q` - 指向等待队列头的指针，`condition` - 填写满足条件时继续运行的条件，写一个能放到if语句中判断的表达式。
// 因为该函数是宏实现的，这里的condition其实是放到 if(condition) 中的。
// 返回值：0 表示等待被正常唤醒，负数表示等待被信号中断。
// 该函数使当前任务进入睡眠状态，直到指定的条件满足。任务会被添加到等待队列中，直到被唤醒。不可被信号中断的。
int wait_event(wait_queue_head_t *q, condition);

// 该函数使当前任务进入睡眠状态，直到指定的条件满足。任务会被添加到等待队列中，直到被唤醒。可被信号中断的。若等待被信号中断，则返回-ERESTARTSYS
int wait_event_interruptible(wait_queue_head_t *q, condition);


/*
   一般使用上面的api即可，里面已经封装好了等待队列的加入和移除，并设置好线程睡眠和唤醒等。
   也可以全部手动来完成，不推荐，使用以下api，并配合set_current_state(), schedule(),或其他内核封装的接口手动来管理线程的睡眠和唤醒。
*/
// 该函数用于将一个任务的等待队列项添加到指定的等待队列中。
void add_wait_queue(wait_queue_head_t *q, wait_queue_entry_t *wq_entry);
// 该函数用于从指定的等待队列中移除一个任务的等待队列项。
void remove_wait_queue(wait_queue_head_t *q, wait_queue_entry_t *wq_entry);
```

以上接口在头文件中主要都是以宏定义的形式提供的，还有其他类似的扩展接口，如唤醒所有等，参考内核头文件 `/include/linux/wait.h`。
带`_interruptible`后缀可以被信号打断，一般可以用在驱动程序中，设备文件的读写过程，应支持可以被打断。




## 示例代码片段

```c
static wait_queue_head_t wq;
static int data_ready = 0;      //临界资源，也应当加保护独占访问，或者间接访问。这里没加。

//初始化
init_waitqueue_head(&wq);


//生产者
{
   data_ready = 1;

   pr_info("Data be ready!\n");

   // 唤醒等待队列中的消费者
   wake_up_interruptible(&wq);
}

//消费者
{
   wait_event_interruptible(wq, data_ready==1);

   // 处理数据
   pr_info("Data received and processed!\n");

   // 重置数据就绪标志
   data_ready = 0;
}
```




