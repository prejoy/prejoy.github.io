---
title: 'Bug:Vitis V++无法生成xo'
date: 2022-10-19 10:15:51 +0800
categories: [Xilinx, Chore]
tags: [xilinx, vitis, workflow]     # TAG names should always be lowercase
published: true
img_path: /assets/img/postimgs/Xilinx/Chore/
---

## Vitis 使用V++编译HLS无法生成xo问题

ref:<https://github.com/Xilinx/Vitis-Tutorials/tree/2020.2/Vitis_Platform_Creation/Introduction/02-Edge-AI-ZCU104>

描述：vitis中v++编译hls的cpp代码，没有报错，但最后却报error：failed to generate IP,无法生成IP。

```
****** Vivado v2020.2 (64-bit)
  **** SW Build 3064766 on Wed Nov 18 09:12:47 MST 2020
  **** IP Build 3064653 on Wed Nov 18 14:17:31 MST 2020
    ** Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.

source run_ippack.tcl -notrace
bad lexical cast: source type value could not be interpreted as target
    while executing
"rdi::set_property core_revision 2210181547 {component component_1}"
    invoked from within
"set_property core_revision $Revision $core"
    (file "run_ippack.tcl" line 1081)
INFO: [Common 17-206] Exiting Vivado at Tue Oct 18 15:48:19 2022...
ERROR: [IMPL 213-28] Failed to generate IP.
INFO: [HLS 200-111] Finished Command export_design CPU user time: 26.12 seconds. CPU system time: 1.39 seconds. Elapsed time: 41.58 seconds; current allocated memory: 274.192 MB.
command 'ap_source' returned error code
```

发现是 xilinx 的vitis工具本身的缺陷导致。

解决补丁： <https://support.xilinx.com/s/article/76960?language=en_US>

