---
title: 内核-semaphore（信号量）
date: 2021-07-13 15:13:00 +0800
categories: [Kernel, 互斥和同步]
tags: [并发及同步, semaphore, 信号量]
img_path: /assets/img/postimgs/LinuxKernelPart/
---


`信号量（Semaphore）`是一种用于进程同步和互斥的机制。它是一种计数器对象，用于管理并发访问共享资源。
相比自旋锁，信号量的一大特点是**允许调用它的线程进入睡眠状态**，即调用它的线程**可能会出现进程的切换**。


## 大致实现

信号量本身的定义不复杂，位于内核源吗`/include/linux/semaphore.h`中。
```c
/* Please don't access any members of this structure directly */
struct semaphore {
	raw_spinlock_t		lock;
	unsigned int		count;
	struct list_head	wait_list;
};
```
wait_list用于管理在该信号量上睡眠的进程；count为信号量计数值，用于管理可用的资源数量，当计数值大于0时，
线程可以获取到信号量并继续执行，计数值为0时，线程需要等待其他线程释放信号量。当初始化时设置的信号量大于1时，就有可重入性；
lock用于实现count的原子操作，所以不能直接操作信号量的成员，需要使用对应提供的接口。


## 常用API接口

**初始化信号量**

可以静态初始化或动态初始化。

```c
// 静态初始化
#define DEFINE_SEMAPHORE(name)	\
	struct semaphore name = __SEMAPHORE_INITIALIZER(name, 1)

// 动态初始化
static inline void sema_init(struct semaphore *sem, int val);
```

**信号量操作**

主要是获取和释放，核心对应count资源计数值的增减。有获取（down）和释放（up）操作。

```c
void             down(struct semaphore *sem);
int __must_check down_interruptible(struct semaphore *sem);
int __must_check down_killable(struct semaphore *sem);
int __must_check down_trylock(struct semaphore *sem);
int __must_check down_timeout(struct semaphore *sem, long jiffies);

void             up(struct semaphore *sem);
```

只要信号量的count值是大于0的，就可以获取到（down操作），获取和释放的过程有结构体中的自旋锁保护。如果count是
小于等于0的，一般表示资源不可用，当前的执行线程或被阻塞，并加入到信号量的wait_list中，直到由其他线程释放了信号量（up操作）
后，唤醒wait_list上的线程，并检测信号量可用并获取信号量后，继续执行。

**linux的睡眠态分可中断睡眠态和不可中断睡眠态，可中断表示可以被用户空间发送来的信号打断，提早退出。对应`down_interruptible`，
如果被中断，需要检测其返回值，确定是正常获取还是被打断，返回0是获取到，非0值一般可以给用户返回 `-ERESTARTSYS`。**
如果使用不可打断的接口`down`，线程会一直阻塞，直到获取到信号量为止，用户无法打断。

释放信号量只有一个接口 `up`，会释放一个信号量，并唤醒wait_list上的线程。



## 读写信号量（rwsem）

除了普通的信号量（Semaphore），还有一种特殊的信号量叫做读写信号量（Reader-Writer Semaphore）。
读写信号量是一种用于实现读写锁的机制，用于控制对共享资源的读写操作。一般多读少写的场景可以使用，使用场景不如普通信号量多。
概念上近似读取者和写入者自旋锁。

读写信号量支持两种模式的访问：读模式和写模式。多个进程可以同时获取读写信号量的读模式，但只能有一个进程获取写模式。
读模式是共享的，多个进程可以同时获取读写信号量的读模式。写模式是互斥的，只有一个进程可以获取读写信号量的写模式。

相关API可以参考内核头文件 `/include/linux/rwsem.h`。用法上基本相似，但区分了读锁和写锁（信号量）。

