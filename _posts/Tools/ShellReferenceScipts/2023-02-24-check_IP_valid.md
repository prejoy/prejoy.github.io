---
title: 'Shell Records - 检验有效IPv4地址'
date: 2023-02-24 14:34:43 +0800
categories: [Tools, ShellReferenceScipts]
tags: [scriptreference]
published: true
---


判断是否为有效 IPv4地址。

```bash
#!/bin/bash


function isValidIp() { 
    local ip=$1 
    local ret=1 
    
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then 
        ip=(${ip//\./ }) # 按.分割，转成数组，方便下面的判断
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]] 
        ret=$? 
    fi 
    return $ret 
}


if ! isValidIp $1;
then
        echo "$1 is not valid IP"
else
        echo "$1 is valid IP"
fi

exit 0
```