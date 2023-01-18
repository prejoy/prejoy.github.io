---
title: 'XRT Native APIs'
date: 2022-11-09 14:38:54 +0800
categories: [Xilinx, XRT]
tags: [xilinx, xrt]     # TAG names should always be lowercase
published: true
img_path: /assets/img/postimgs/Xilinx/XRT/
---


**在2020.2后，XRT提供了一套新的API接口，包括C/C++和python语言。**  

**要使用XRT的原生API接口，主机程序编译时要链接 `xrt_coreutil` 库，并且，使用C++编译时要求C++标准 `-std=c++17` （或者更高），example:**  
```bash
g++ -g -std=c++17 -I$XILINX_XRT/include -L$XILINX_XRT/lib -o host.exe host.cpp -lxrt_coreutil -pthread
```

>这里使用到了XRT库，在编译前,需要source XRT的环境，主要设置一些环境变量，
>`source /opt/xilinx/xrt/setup.sh` ，里面就有上文的`XILINX_XRT`环境
{: .prompt-info }


XRT native API，xilinx建议使用C++来开发，文档目前也只有C++接口的。  
由Doxygen生成的C/C++接口文档在 `:doc: xrt_native.main` 中。  


详细API文档参考：
[XRT Native Library C++ API](https://xilinx.github.io/XRT/master/html/xrt_native.main.html#) ，按类型分buffer api,config api,custom ip apis,device api,info api,kernel api......


The C++ Class objects used for the APIs are:  

|   objects            |   C++ Class       |  Header files                                  |
| -------------------- | ----------------- |  --------------------------------------------- |
|   Device             | ``xrt::device``   |  ``#include <xrt/xrt_device.h>``               |
|   XCLBIN             | ``xrt::xclbin``   |  ``#include <experimental/xrt_xclbin.h>``      |
|   Buffer             | ``xrt::bo``       |  ``#include <xrt/xrt_bo.h>``                   |
|   Kernel             | ``xrt::kernel``   |  ``#include <xrt/xrt_kernel.h>``               |
|   Run                | ``xrt::run``      |  ``#include <xrt/xrt_kernel.h>``               |
| User-managed Kernel  | ``xrt::ip``       |  ``#include <experimental/xrt_ip.h>``          |
|   Graph              | ``xrt::graph``    |  ``#include <experimental/aie.h>``和``#include <experimental/graph.h>``            |

主要的核心数据结构定义在 `$XILINX_XRT/include/xrt/` 目录的头文件中，一些新特性如 `xrt::ip`, `xrt::aie` 在 `$XILINX_XRT/include/experimental`头文件中，**experimental文件夹下的头文件（新特性）API接口不稳定，可能会发生重大的变化。**  


The common host code flow using the above data structures is as below

* Open Xilinx **Device** and Load the **XCLBIN**
* Create **Buffer** objects to transfer data to kernel inputs and outputs
* Use the Buffer class member functions for the data transfer between host and device (before and after the kernel execution).
* Use **Kernel** and **Run** objects to offload and manage 
the compute-intensive tasks running on FPGA.

Below we will walk through the common API usage to accomplish the above tasks.

---

## Device and XCLBIN 

Device and XCLBIN class provide fundamental infrastructure-related interfaces. The primary objective of the device and XCLBIN related APIs are  
设备和 XCLBIN 类提供与基础结构相关的基本接口。设备和 XCLBIN 相关 API 的主要目标是  

* Open a Device  
* Load compiled kernel binary (or XCLBIN) onto the device  

最简单的加载xclbin的示例代码：  
```cpp
    unsigned int dev_index = 0;
    auto device = xrt::device(dev_index);
    auto xclbin_uuid = device.load_xclbin("kernel.xclbin");
```

* The `xrt::device` class’s constructor is used to open the device (enumerated as 0)
* The member function `xrt::device::load_xclbin` is used to load the XCLBIN from the filename.
* The member function `xrt::device::load_xclbin` returns the *XCLBIN UUID, which is required to open the kernel (refer the Kernel Section)*.

使用index打开设备（设备index如何对应？），也可以使用PCIE的bdf号指定打开。
The class constructor `xrt::device::device(const std::string& bdf)` also supports opening a device object from a Pcie BDF passed as a string.ex:  
```cpp
auto device = xrt::device("0000:03:00.1");
```

The `xrt::device::get_info()` is a useful member function to obtain necessary information about a device. Some of the information such as Name, BDF can be used to select a specific device to load an XCLBIN :  
```cpp
    std::cout << "device name:     " << device.get_info<xrt::info::device::name>() << "\n";
    std::cout << "device bdf:      " << device.get_info<xrt::info::device::bdf>() << "\n";
```

## Buffers  

Buffers are primarily used to transfer the data between the host and the device. The Buffer related APIs are discussed in the following three subsections

1. Buffer allocation and deallocation
2. Data transfer using Buffers
3. Miscellaneous other Buffer APIs

### Buffer allocation and deallocation

The class constructor xrt::bo is mainly used to allocates a buffer object 4K aligned. By default, a regular buffer is created (optionally the user can create other types of buffers by providing a flag).
```cpp
    auto bank_grp_arg0 = kernel.group_id(0); // Memory bank index for kernel argument 0
    auto bank_grp_arg1 = kernel.group_id(1); // Memory bank index for kernel argument 1

    auto input_buffer = xrt::bo(device, buffer_size_in_bytes,bank_grp_arg0);
    auto output_buffer = xrt::bo(device, buffer_size_in_bytes, bank_grp_arg1);
```

In the above code `xrt::bo` buffer objects are created using the class constructor. Please note the following:  
* As no special flags are used a regular buffer will be created. Regular buffer is most common type of buffer that has a host backing pointer allocated by user space in heap memory and a device buffer allocated in the specified memory bank.
* The second argument specifies the buffer size.
* The third argument is used to specify the enumerated memory bank index (to specify the buffer location) where the buffer should be allocated. There are two ways to specify the memory bank index
    * Through kernel arguments: In the above example, the xrt::kernel::group_id() member function is used to pass the memory bank index. This member function accept kernel argument-index and automatically detect corresponding memory bank index by inspecting XCLBIN.  
    * Passing Memory bank index: The xrt::kernel::group_id() also accepts the direct memory bank index (as observed from xbutil examine --report memory output).  

`xrt::bo`同时也是xrt::bo的构造函数，该构造函数有重载，有另一个带flag的构造函数。不指定flag实际等于指定normal flag，创建常规缓冲区。
**这里的常规缓冲区和一般的buff不同：该`xrt::bo` 在主机上会alloc一块空间，指针指向主机的buff空间，同时在设备上也会alloc一块空间，两个空间大小相同，且内容会需要对应。**
**内容对应，就是buff要同步，通过dma读写来完成，将主机的buff写到设备的对应buff，或将设备的buff读取到主机的对应buff。该DMA读写由XRT完成，用户只需调用API接口去完成同步即可。**

第二参数指定申请的buff size。  
第三参数指定设备的 memory bank的索引。有2中方式指定mem bank的索引。
(1)通过内核参数，`xrt::kernel::group_id()`函数,通过该函数指定kernel的索引，自动返回对应的memory bank的索引。
(2)直接传递memory bank 索引，通过工具 `xbutil examine -d 0000:19:00.1 --report memory` 直接查看内存块信息。
一般使用第一种。

**一些补充说明**

xilinx将一个做好的特定功能的硬件模块定义为一个kernel，这个硬件模块可以使用HLS或RTL编写实现，通常由硬件负责。
最终提供给软件的接口是一个类似函数申明的东西，软件可以调用这个“函数”，而函数的参数经常会出现指针的情况，即一个buff。
这个buff就是由 `xrt::bo`来实现，主机上准备好数据，然后传给硬件。具体的，传给硬件哪里，dma是需要地址的，硬件侧可以开辟一些内存作为buffs，
在硬件上，内存是细分的，有不同种类的内存，最终就是一个个区域，主机需要选好对应的区域，不过这个可以由XRT来帮助完成，只需要告诉XRT，这个参数是
“函数“的第几个参数，就能返回它对应的内存区域（`xrtMemoryGroup`，实际为`int`类型）。具体基本就是上文的cpp代码。


### Creating special Buffers

The `xrt::bo()` constructors accept multiple other buffer flags those are described using `enum class` argument with the following enumerator values:  
* `xrt::bo::flags::normal`: Regular buffer (default)
* `xrt::bo::flags::device_only`: Device only buffer (meant to be used only by the kernel, there is no host backing pointer).
* `xrt::bo::flags::host_only`: Host only buffer (buffer resides in the host memory directly transferred to/from the kernel)
* `xrt::bo::flags::p2p`: P2P buffer, A special type of device-only buffer capable of peer-to-peer transfer
* `xrt::bo::flags::cacheable`: Cacheable buffer can be used when the host CPU frequently accessing the buffer (applicable for edge platform).


### Creating Buffers from the user pointer

The `xrt::bo()` constructor can also be called using a pointer provided by the user. The user pointer must be aligned to **4K boundary**.
```cpp
    // Host Memory pointer aligned to 4K boundary
    int *host_ptr;
    posix_memalign(&host_ptr,4096,MAX_LENGTH*sizeof(int));
    // Sample example filling the allocated host memory
    for(int i=0; i<MAX_LENGTH; i++) {
        host_ptr[i] = i;  // whatever
    }
    auto mybuf = xrt::bo (device, host_ptr, MAX_LENGTH*sizeof(int), kernel.group_id(3));
```

这种方式是让XRT使用用户指定的主机buff，就是`xrt::bo`使用的主机的buff，由用户提前分配好，然后提供给XRT，而不是让XRT去自己alloc一块，本质区别不大。


## Data transfer using Buffers

XRT Buffer API library provides a rich set of APIs helping the data transfers between the host and the device, between the buffers, etc. We will discuss the following data transfer style

1. Data transfer between host and device by Buffer read/write API
2. Data transfer between host and device by Buffer map API
3. Data transfer between buffers by copy API

###  Data transfer between host and device by Buffer read/write API

To transfer the data *from the host to the device*, the user first needs to update the host-side buffer backing pointer ,followed by a DMA transfer to the device.

The `xrt::bo` class has following member functions for the same functionality

1. `xrt::bo::write()`
2. `xrt::bo::sync()` with flag `XCL_BO_SYNC_BO_TO_DEVICE`

传数据到设备上， 先`xrt::bo::write()`，再`xrt::bo::sync()`

To transfer the data from the device to the host, the steps are reversed, the user first needs to do a DMA transfer from the device followed by the reading data from the host-side buffer backing pointer.

The corresponding xrt::bo class’s member functions are

1. `xrt::bo::sync()` with flag `XCL_BO_SYNC_BO_FROM_DEVICE`
2. `xrt::bo::read()`

读数据到HOST上，相反，先`xrt::bo::sync()`，再`xrt::bo::read()`。  


Code example of transferring data from the host to the device
```cpp
    auto input_buffer = xrt::bo(device, buffer_size_in_bytes, bank_grp_idx_0);
    // Prepare the input data
    int buff_data[data_size];
    for (auto i=0; i<data_size; ++i) {
        buff_data[i] = i;
    }
    input_buffer.write(buff_data);
    input_buffer.sync(XCL_BO_SYNC_BO_TO_DEVICE);
```

**补充说明**

默认的方式是需要额外调用 `xrt::bo::write()` 或 `xrt::bo::read()` 来完成最终读写的，这个实际是主机上的二次拷贝。
`xrt::bo::sync()`是完成dma读写，实现主机侧buff和设备侧buff的同步。到这里，其实数据已经可用了，而默认的处理方式需要
再进行一次拷贝，是因为，这里dma同步完的buff是由XRT管理的，xilinx的默认方式是将用户程序和XRT管理的这个主机侧buff分离的，
`xrt::bo::write()` 或 `xrt::bo::read()`就是将XRT管理的这个主机侧buff内容再拷贝到用户程序的buff，和socket buff有点
类似，但是因为XRT是用户态程序，是可以去掉这个二次拷贝的，让用户直接使用这个主机侧的buff，使用**Buffer map API**即可实现（参考下文）。

>如果缓冲区是通过用户指针创建的，则在 xrt::bo::sync 调用之前或之后也不需要 xrt::bo::write 或 xrt::bo::read。
{: .prompt-info }

>Note the C++ `xrt::bo::sync`, `xrt::bo::write`, `xrt::bo::read` etc has overloaded version that can be used for partial buffer sync/read/write by **specifying the size and the offset**. For the above code example, the full buffer size and offset=0 are assumed as default arguments.
>请注意，C++ xrt::bo::sync、xrt::bo::write、xrt::bo::read 等具有重载版本，可通过指定大小和偏移量来用于部分缓冲区同步/读/写。这样可以创建一个满足最大size的buff，然后根据需要每次传输指定大小，这个非常有用。
{: .prompt-tip }


### Data transfer between host and device by Buffer map API

The API `xrt::bo::map()` allows mapping the host-side buffer backing pointer to a user pointer. The host code can subsequently exercise the user pointer for the data reads and writes. However, after writing to the mapped pointer (or before reading from the mapped pointer) the API xrt::bo::sync() should be used with direction flag for the DMA operation.

Code example of transferring data from the host to the device by this approach
```cpp
    auto input_buffer = xrt::bo(device, buffer_size_in_bytes, bank_grp_idx_0);
    auto input_buffer_mapped = input_buffer.map<int*>();
    for (auto i=0;i<data_size;++i) {
        input_buffer_mapped[i] = i;
    }
    input_buffer.sync(XCL_BO_SYNC_BO_TO_DEVICE);
```

> 使用map API **可以极大提高效率。应当主要使用这种方式**。不需要调用 read,write了，直接调用sync即可。
{: .prompt-info }


### Data transfer between the buffers by copy API

XRT provides `xrt::bo::copy()` API for deep copy between the two buffer objects if the platform supports a deep-copy 
(for detail refer M2M feature described in [Memory-to-Memory (M2M)](https://xilinx.github.io/XRT/master/html/m2m.html)). 
If deep copy is not supported by the platform the data transfer happens by shallow copy (the data transfer happens via host).

这里说的buff 拷贝应该是在多个kernel 级联时，上一个 kernel 的 out buff 不需要传到CPU再传给下一个kernel 的 in buff。可以在设备上由硬件完成（需要硬件支持，且只支持普通的板卡上的DDR）。
如果硬件不支持，就会经由CPU完成，但API相同，应该只是性能不同。
这里的说的deep copy和C++语言中的深度拷贝概念不同，这里是用硬件拷贝卡上的buff 和 经过CPU的拷贝。

```cpp
    dst_buffer.copy(src_buffer, copy_size_in_bytes);
```

The API xrt::bo::copy() also has overloaded versions to provide a different offset than 0 for both the source and the destination buffer.


## Miscellaneous other Buffer APIs

一些其他的关于BUFF的API。

### DMA-BUF API

XRT provides Buffer export and import APIs primarily used for sharing buffer across devices (P2P application) and processes. 
The buffer handle obtained from `xrt::bo::export_buffer()` is essentially a file descriptor, hence sending across the processes 
requires a suitable IPC mechanism (example, UDS or Unix Domain Socket) to translate the file descriptor of one process into another process.

* `xrt::bo::export_buffer()`: Export the buffer to an exported buffer handle
* `xrt::bo()` constructor: Allocate a BO imported from exported buffer handle


XRT 提供缓冲区导出和导入 API，主要用于跨设备（P2P 应用程序）和进程共享缓冲区。从 `xrt::bo::export_buffer()` 获得的缓冲区句柄本质上是一个文件描述符，因此跨进程发送需要合适的 IPC 机制（例如，UDS 或 Unix 域套接字）将一个进程的文件描述符传递到另一个进程。

Consider the situation of exporting buffer from device 1 to device 2 (inside same host process).

```cpp
    auto buffer_exported = buffer_device_1.export_buffer();
    auto buffer_device_2 = xrt::bo(device_2, buffer_exported);
```
In the above example

* The buffer buffer_device_1 is a buffer allocated on device 1
* buffer_device_1 is exported by the member function xrt::bo::export_buffer
* The new buffer buffer_device_2 is imported for device_2 by the constructor xrt::bo()

上面的例子应该是buff的P2P应用程序的示例，不同进程间的导入导出根据描述还需要配合系统的IPC机制实现。


### Sub-buffer support

The `xrt::bo` class constructor can also be used to allocate a sub-buffer from a parent buffer by specifying a start offset and the size.

In the example below a sub-buffer is created from a parent buffer of size 4 bytes starting from its offset 0

```cpp
    size_t sub_buffer_size = 4;
    size_t sub_buffer_offset = 0;

    auto sub_buffer = xrt::bo(parent_buffer, sub_buffer_size, sub_buffer_offset);
```

XRT的BUFF创建还可以从现有buff创建，本质是对现有buff的引用，但是可以加起始offset，方便应用使用buff。


### Buffer information
XRT provides few other API Class member functions to obtain information related to the buffer.

The member function `xrt::bo::size():` Size of the buffer
The member function `xrt::bo::address()` : Physical address of the buffer

XRT的buff info 成员函数，里面有获取buff物理地址的接口，所以上面的进程间share buff基本是可行的。

---

## Kernel and Run

To execute a kernel on a device, a kernel class (`xrt::kernel`) object has to be created from currently loaded xclbin. The kernel object can be used to execute the kernel function on the hardware instance (*Compute Unit or CU*) of the kernel.

A Run object (`xrt::run`) represents an execution of the kernel. Upon finishing the kernel execution, the Run object can be reused to invoke the same kernel function if desired.

`xrt::kernel` 基本上用来代表一个xclbin里面的计算单元。而运行计算单元则是一个新的类`xrt::run`，`xrt::run`需要使用`xrt::kernel`来完成构造，并且可以重复运行使用。


The following topics are discussed below

* Obtaining kernel object from XCLBIN
* Getting the bank group index of a kernel argument
* Execution of kernel and dealing with the associated run
* Other kernel related API

### Obtaining kernel object from XCLBIN

The kernel object is created from the device, XCLBIN UUID and the kernel name using xrt::kernel() constructor as shown below

```cpp
    auto xclbin_uuid = device.load_xclbin("kernel.xclbin");
    auto krnl = xrt::kernel(device, xclbin_uuid, name);
```

Note: **A single kernel object (when created by a kernel name) can be used to execute multiple CUs as long as CUs are having identical interface connectivity.** If all the CUs of the kernel are not having identical connectivity, XRT assigns a subset of CUs (one or more CUs with identical connectivity) to the created kernel object and discards the rest of the CUs (discarded CUs are not used during the execution of a kernel). For this type of situation creating a kernel object using mangled CU names can be more useful.

注意：只要 CU 具有相同的接口连接，单个内核对象（由内核名称创建时）可用于执行多个 CU。如果内核的所有 CU 不具有相同的连接性，XRT 会将 CU 的子集（一个或多个具有相同连接的 CU）分配给创建的内核对象，并丢弃其余的 CU（在内核执行期间不使用丢弃的 CU）。对于这种情况，使用不完整的 CU 名称创建内核对象可能更有用。

**补充说明**

这里和的kernel name 是由硬件制作时定的，完整的kernel name较长，也有不完整的，如果硬件定义了一组相同功能的kernel，在具体指定某一个时，就需要使用完整的 kernel name，如果只有一个，那就可以使用不完整的kernel name。
另外，kernel name 是有相同的规律的。


As an example, assume a kernel name is foo having 3 CUs foo_1, foo_2, foo_3. The CUs foo_1 and foo_2 are connected to DDR bank 0, but the CU foo_3 is connected to DDR bank 1.

Opening kernel object for foo_1 and foo_2 (as they have identical interface connection)
```cpp
    krnl_obj_1_2 = xrt::kernel(device, xclbin_uuid, "foo:{foo_1,foo_2}");
```
Opening kernel object for foo_3
```cpp
    krnl_obj_3 = xrt::kernel(device, xclbin_uuid, "foo:{foo_3}");
```
这种是在单个kernel object执行多个CU的情况，如果接口不一样，需要分开创建，这个应该和硬件密切相关，需要知道硬件设计。


### Getting bank group index of the kernel argument

We have seen in the Buffer creation section that it is required to provide the buffer location during the buffer creation. 
The member function `xrt::kernel::group_id()` returns the memory bank index (or id) of a specific argument of the kernel. This id is passed as a parameter of `xrt::bo()` constructor to create the buffer on the same memory bank.

Let us review the example below where the buffer is allocated for the kernel’s first (argument index 0) argument.
```cpp
    auto input_buffer = xrt::bo(device, buffer_size_in_bytes, kernel.group_id(0));
```

If the kernel bank index is ambiguous then `kernel.group_id()` returns the last memory bank index in the list it maintains. **This is the case when the kernel has multiple CU with different connectivity for that argument.** For example, let’s assume a kernel argument (argument 0) is connected to memory bank 0, 1, 2 (for 3 CUs), then `kernel.group_id(0)` will return the last index from the group {0,1,2}, i.e. 2. As a result the buffer is created on the memory bank 2, so the buffer cannot be used for the CU0 and CU1.

通用方式：

**However, in the above situation, the user can always create 3 distinct kernel objects corresponds to 3 CUs (by using the `{kernel_name:{cu_name(s)}}` for xrt::kernel constructor) to execute the CUs by separate `xrt::kernel` objects.**


>个人补充： 关于group_id的使用，先看group_id()的函数说明：  
>group_id() - Get the memory bank group id of an kernel argument  
> ```cpp
>   /**
>   * group_id() - Get the memory bank group id of an kernel argument
>   *
>   * @param argno
>   *  The argument index
>   * @return
>   *  The memory group id to use when allocating buffers (see xrt::bo)
>   *
>   * The function throws if the group id is ambigious.
>   */
>  XCL_DRIVER_DLLESPEC
>  int group_id(int argno) const;
>  ```
> 用于获取内核参数（kernel argument）的memory group id。
所谓kernel，就是由HLS/RTL生成的xo文件，这个属于硬件描述文件，HLS的cpp代码生成的就是xo文件，这个是去描述硬件的，尽管看上去是软件代码。而kernel argument是给硬件填的参数，这里容易误导。从HLS的头文件看，example：
jpeg_decoder模块的HLS的头文件：
>
>```cpp
> //！！！HLS代码，描述硬件的，无法在应用程序中直接使用！！！
>extern "C" void krnl_jpeg(
>    ap_uint<AXI_WIDTH>* jpeg_pointer,
>    const int size,
>    ap_uint<64>* yuv_mcu_pointer,
>    ap_uint<32>* infos
>);
>```
> kernel arguments 就是指上面的 jpeg_pointer ， size ，yuv_mcu_pointer，infos 四个参数，**这里容易误解的是，这个函数是描述硬件的，和应用程序开发没有关系，在应用程序中是需要创建一个xrt::kernel对象去对应这个硬件模块，而这个xrt::kernel类的构造却又是需要知道kernel的名字，kernel的名字就是krnl_jpeg这个函数名，这是非常奇怪的地方之一，和一般软件写法完全不同，比如实际的代码：`xrt::kernel my_jpgdecoder_kernel      = xrt::kernel(device, xclbin_uuid, "krnl_jpeg");`，然后使用xrt::run 对应去运行这个模块，第二个奇怪之处：这个jpg_decoder模块运行是需要参数的，（这个可以看HLS代码的接口），应用程序无法调用该函数，但应用程序却需要为其提供参数，应该说是模块参数，需要使用 `void xrt::run::set_arg(int index, xrt::bo& boh)`函数去设置，index参数就是指定第几个参数的，比如第0个就是对应上面jpeg_pointer参数，第1个对应size参数，而且，如果参数是指针，是需要额外使用`xrt::bo::sync()`函数进行dma同步的！！**，大致参考代码：
>```cpp
>    xrt::device device = xrt::device(0);    //第0个设备（支持xocl）
>    xrt::kernel my_jpgdecoder_kernel      = xrt::kernel(device, xclbin_uuid, "krnl_jpeg");
>
>    xrt::run run_myjpgdcd_kernel(my_jpgdecoder_kernel); 
>    xrt::bo jpeg_buffer  = xrt::bo (device, file_size,    xrt::bo::flags::normal, my_jpgdecoder_kernel.group_id (krnl_jpeg_jpeg_ptr));   //这里实际用到了group_id 成员函数
>
>    // set jpeg kernel arguments
>    run_myjpgdcd_kernel.set_arg(0,    jpeg_buffer);   
>    run_myjpgdcd_kernel.set_arg(1,   file_size);    
>    run_myjpgdcd_kernel.set_arg(2,     yuv_buffer);   //出参，已省略 
>    run_myjpgdcd_kernel.set_arg(3,   infos_buffer);
>
>    jpeg_buffer.write(jpeg_data);           //指针，buff，需要同步数据
>    jpeg_buffer.sync(XCL_BO_SYNC_BO_TO_DEVICE);
>
>    run_myjpgdcd_kernel.start();
>    run_myjpgdcd_kernel.wait();             //硬件真正完成操作
>
>    yuv_buffer.sync(XCL_BO_SYNC_BO_FROM_DEVICE);
>    yuv_buffer.read(yuv_data);              //指针的出参，也要dma堵回来。
>```
>后补充：其实XRT对于kernel的运行，也提供了函子的方式执行，就比较像软件代码了。属于cpp的语法应用。
{: .prompt-warning }

### Executing the kernel

Execution of the kernel is associated with a `Run` object. The kernel can be executed by the `xrt::kernel::operator()` that takes all the kernel arguments in order. The kernel execution API returns a run object corresponding to the execution.

```cpp
    // 1st kernel execution
    auto run = kernel(buf_a, buf_b, scalar_1);
    run.wait();

    // 2nd kernel execution with just changing 3rd argument
    run.set_arg(2,scalar_2); // Arguments are specified starting from 0
    run.start();
    run.wait();
```

The `xrt::kernel` class provides **overloaded operator ()** to execute the kernel with a comma-separated list of arguments.

The above c++ code block is demonstrating

* **The kernel execution using the `xrt::kernel()` operator with the list of arguments that returns a `xrt::run` object. This is an asynchronous API and returns after submitting the task.**
* The member function `xrt::run::wait()` is used to block the current thread until the current execution is finished.
* The member function `xrt::run::set_arg()` is used to set one or more kernel argument(s) before the next execution. In the example above, only the last (3rd) argument is changed.
* The member function `xrt::run::start()` is used to start the next kernel execution with new argument(s).

这里提到了两种方式，第一种方式应该是类似函数的方式，一次设置好所有参数，并且立即运行，使用了c++的函数式语法（函子）。第二种方式是常规的，先用kernel初始化构造run对象，然后设置aguments，然后启动运行，等待完成。还是使用第二种方式。

### Other kernel APIs

**Obtaining the run object before execution**: Example of the previous section shows to obtain a `xrt::run` object when the kernel is executed (kernel execution returns a run object). However, a `xrt::run` object can be obtained even before the kernel execution. The flow is as below

* Open a Run object by the `xrt::run` constructor with a kernel argument).
* Set the kernel arguments associated for the next execution by the member function `xrt::run::set_arg()`.
* Execute the kernel by the member function `xrt::run::start()`.
* Wait for the execution finish by the member function `xrt::run::wait()`.

**Timeout while wait for kernel finish**: The member function `xrt::run::wait()` blocks the current thread until the kernel execution finishes. To specify a timeout supported API `xrt::run::wait()` also accepts a timeout in millisecond unit.


## User Manged Kernel 

The `xrt::kernel` is used to execute the kernels with standard control interface through AXI-Lite control registers. These standard control interfaces are well defined and understood by XRT but transparent to the user. These XRT managed kernels should always be represented by xrt::kernel objects in the host code.

xrt::kernel 是符合XRT接入规范的内核（内核实现了xilinx的标准控制接口（通过axi-lite 控制寄存器））。这样的内核，可以很好的接入XRT使用，对用户时透明的。这样的内核就是用 xrt::kernel 代表的，也应该这样用。

The XRT also supports custom control interface for a kernel. These type of kernels (a.k.a User-Managed Kernel) must **be managed by the user by writing/reading to/from the AXI-Lite registers controlling these kernels**. To differentiate from the XRT managed kernel, `class xrt::ip` is used to specify a user-managed kernel inside the user host code.

XRT也支持内核的自定义控制接口。这些类型的内核(又称用户管理内核)必须由用户通过对控制这些内核的axis - lite寄存器进行读写来进行管理。为了与XRT托管内核区别开来，`class XRT::ip`用于在用户主机代码中指定用户托管内核。

补充：xilinx定义的XRT标准接口其实主要就是 控制信号寄存器可能还需要放在特定位置，如0偏移，目前的主要信号有  
Bit[0] = ap_start   
Bit[1] = ap_done   
Bit[2] = ap_idle  
Bit[3] = ap_ready  
Bit[7] = auto_restart  
可能还有其他一些东西。如软件接口信息等。

对于没有按XRT规定实现接口的kernel，就需要用户自己管理，就是用户自己去读写寄存器了，XRT使用`xrt::ip`来管理这些个user-managed kernel。

因为没有寄存器上显示这个kernel是否符合XRT接入规范的信息，所以，使用 `xrt::kernel` 还是 `xrt::ip` 是由用户自己判断的，有用户负责，一般能用 `xrt::kernel`就应该用，这个符合标准。


### Creating xrt::ip object from XCLBIN

The `xrt::ip` object creation is very similar to creating a kernel.
```cpp
    auto xclbin_uuid = device.load_xclbin("kernel.xclbin");
    auto ip = xrt::ip(device, xclbin_uuid, "ip_name");
```

**An ip object can only be opened in exclusive mode**. That means at a time, only one thread/process can access IP at the same time. This is required for a safety reason because multiple threads/processes reading/writing to the AXI-Lite registers at the same time potentially leads to a race situation.

xrt::ip 需要注意的是：它**只能独占访问**，就是防止读写寄存器时出现竞争的情况。


### Allocating buffers for the IP inputs/outputs

Similar to XRT managed kernel `xrt::bo` objects are used to create buffers for IP ports. However, the memory bank location must be specified explicitly by providing enumerated index of the memory bank.

对于user manged kernel（即xrt::ip），其在申请buff时，只能通过提供内存库的枚举索引显式地指定内存库位置。

Below is a example of creating two buffers. Note the last argument of xrt::bo is the enumerated index of the memory bank as seen by the XRT (in this example index 8 corresponds to the host-memory bank). The bank index can be obtained by `xbutil examine --report memory` command.

```cpp
    auto buf_in_a = xrt::bo(device, DATA_SIZE, xrt::bo::flags::host_only, 8);
    auto buf_in_b = xrt::bo(device, DATA_SIZE, xrt::bo::flags::host_only, 8);
```

内存块只能自己填准确值，需要知道硬件，没有 XRT manged kernel(`xrt::kernel`)方便。

### Reading and write CU mapped registers

To read and write from the AXI-Lite register space to a CU (specified by `xrt::ip` object in the host code), the required member functions from the `xrt::ip` class are

* `xrt::ip::read_register`
* `xrt::ip::write_register`
```cpp
    int read_data;
    int write_data = 7;

    auto ip = xrt::ip(device, xclbin_uuid, "foo:{foo_1}");

    read_data = ip.read_register(READ_OFFSET);
    ip.write_register(WRITE_OFFSET,write_data);
```
In the above code block
* The CU named “foo_1” (name syntax: “kernel_name:{cu_name}”) is opened exclusively.
* The Register Read/Write operation is performed.

对于用户管理的kernel,`xrt::ip`，需要去读写寄存器，而`xrt::kernel` 其实应该对应 `xrt::run::set_arg()` ，寄存器可能被封装了。


## Graph

In Versal ACAPs with AI Engines, the XRT Graph class (`xrt::graph`) and its member functions can be used to dynamically load, monitor, and control the graphs executing on the AI Engine array.

在带有AI Engine的Versal ACAP上，XRT进一步实现了 `xrt:graph`类专门负责管理图形相关的，比较专业。

A note regarding Device and Buffer: In AIE based application, the device and buffer have some additional functionlities. For this reason the classes `xrt::aie::device` and `xrt::aie::buffer` are recommended to specify device and buffer objects.

.......  
功能包含open/close,reset,graph execution,性能，参数设置，DMA传输等......
.......  


## XRT Error API
In general, XRT APIs can encounter two types of errors:

* Synchronous error: Error can be thrown by the API itself. The host code can catch these exception and take necessary steps.
* Asynchronous error: Errors from the underneath driver, system, hardware, etc.

XRT provides an `xrt::error` class and its member functions to retrieve the asynchronous errors into the userspace host code. This helps to debug when something goes wrong.

如果遇到错误，如果是同步执行出现错误，则在c++使用使用 trt...catch... 语句就可以直接捕获到异常，并有序完成退出。如果是异步执行出错，比如驱动，系统，硬件。XRT提供了一个`xrt::error`类及其成员函数，用于将异步错误检索到用户空间主机代码中。这有助于在出现错误时进行调试。

* Member function `xrt::error::get_error_code()` - Gets the last error code and its timestamp of a given error class
* Member function `xrt::error::get_timestamp()` - Gets the timestamp of the last error
* Member function `xrt:error::to_string()` - Gets the description string of a given error code.

NOTE: The asynchronous error retrieving APIs are at an early stage of development and only supports AIE related asynchronous errors. Full support for all other asynchronous errors is planned in a future release.

注意:异步错误检索api处于早期开发的阶段(2022 year)，只支持AIE相关的异步错误。计划在未来的版本中完全支持所有其他异步错误。

Example code

```cpp
    graph.run(runInteration);
    try {
       graph.wait(timeout);
    }
    catch (const std::system_error& ex) {
       if (ex.code().value() == ETIME) {
          xrt::error error(device, XRT_ERROR_CLASS_AIE);
          auto errCode = error.get_error_code();
          auto timestamp = error.get_timestamp();
          auto err_str = error.to_string();
          /* code to deal with this specific error */
          std::cout << err_str << std::endl;
       } else {
        /* Something else */
       }
    }
```

The above code shows

* After timeout occurs from xrt::graph::wait() the member functions xrt::error class are called to retrieve asynchronous error code and timestamp
* Member function xrt::error::to_string() is called to obtain the error string.


## Asynchornous Programming with XRT (experimental)

From the 22.1 release, XRT offers a simple asynchronous programming mechanism through the user-defined queues. The `xrt::queue` is lightweight, general-purpose queue implementation which is completely separated from core XRT native API data structures. If needed, the user can also use their own queue implementation instead of the implementation offered by `xrt::queue`.

XRT queue implementation needs #include <experimental/xrt_queue.h> to be added as the header file. The implementation also use C++17 features so the host code must be compiled with `g++ -std=c++17`

......  
......  
......  

<https://xilinx.github.io/XRT/master/html/xrt_native_apis.html#asynchornous-programming-with-xrt-experimental>

22.1， XRT异步编程仍处于实验阶段，且对编译器 c++标准要求较高。

测试可用，未来接口可能会变动，暂不推荐使用。

