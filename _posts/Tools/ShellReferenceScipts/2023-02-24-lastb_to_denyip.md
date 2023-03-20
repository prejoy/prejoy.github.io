---
title: 'Shell Records - 服务器 sshd 安全维护'
date: 2023-02-24 14:35:43 +0800
categories: [Tools, ShellReferenceScipts]
tags: [scriptreference]
published: true
---


提高服务器安全，将重复攻击的IP加入黑名单。  
**最好配合crontab 或 inotify 来触发执行。**

run as root  
功能定义：一周内登录失败达到5次的IP为攻击者IP，将其加入blacklist  
实现，1.遍历lastb输出，统计攻击IP和次数，计入buffarray，  
     2.for each in buffarray ，add to hosts.deny file if count >=5    


```bash
#!/bin/bash

lastIP="127.0.0.1"
# failip 关联数组，全局变量
declare -A failip

function check_if_in(){
    echo ${!failip[*]} | grep ${1} > /dev/null
    rv=`echo $?`
    if [[ ${rv} == 0 ]];then
        echo "not in"
    else
        echo "be in"
    fi
}

function check_if_in2(){
    if [ ! "${failip[${1}]}" ]; then
        echo "not in" 
    else 
        echo "be in" 
    fi
}


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


# # use this will fall
# lastb -i | head -n 20 | grep -v "begins" | while read LINE
while read LINE
do
    if [[ $LINE == "" ]];then
        continue
    fi

    thisIP=`echo "$LINE" | awk -F' ' '{print $3;}'`

    if [[ $thisIP == $lastIP ]];then
        failip[${lastIP}]=$((failip[${lastIP}]+1))
        # echo "$thisIP : ${failip[$thisIP]}"
        continue
    else
        lastIP=$thisIP
    fi

    rv=`check_if_in2 $thisIP`
    if [[ $rv == "be in" ]];then
        failip[${thisIP}]=$((failip[${thisIP}]+1))
        # echo "$thisIP : ${failip[$thisIP]}"
    else
        failip[${thisIP}]=1
        # echo "$thisIP : ${failip[$thisIP]}"
    fi
# done 
done <<< `lastb -i | grep -v tty[0-9]`


for u in ${!failip[*]}
do
    if ! isValidIp ${u};then
        continue
    fi
    # echo "failip ${u} count : ${failip[$u]}"
    if (( ${failip[$u]} >= 5 ))  ;then
        echo "ALL:${u}" >> /etc/hosts.deny
    fi
done
```



