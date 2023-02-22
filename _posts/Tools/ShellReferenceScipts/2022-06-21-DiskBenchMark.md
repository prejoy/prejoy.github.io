---
title: 'Shell Records - DiskBenchMark'
date: 2022-06-21 14:16:53 +0800
categories: [Tools, ShellReferenceScipts]
tags: [scriptreference]
published: true
---

一些对磁盘检测的处理。

```bash
#!/bin/bash

mkdir -p ./logs/
if [[ $UID != 0 ]];then
    echo "must run as root."
    exit 1
fi

for ((i=0;i<10;i++))
do
    echo "this is $i times"
    fio Max_IOPS.fio --output=./logs/iops_$i.log
    fio Max_BW.fio --output=./logs/bw_$i.log
    fio Min_LAT.fio --output=./logs/lat_$i.log
done


for ((i=0;i<10;i++))
do
    echo "this is $i times file test"

    echo -n "write 2GiB file:"
    time dd if=/dev/zero of=./ssdmnt/t$i.data bs=4K count=524288
    echo -n "read 2GiB file:"
    time dd if=./ssdmnt/t$i.data of=/dev/null bs=4K count=524288

    echo ""
    echo ""
    echo ""
done

```
{: file='looptest.sh'}



```bash
#!/bin/bash

logfile=${1}
echo "logfile is ${logfile}"
echo ""

tjobs="seq-read rand-read seq-write rand-write"
# sed -n "4,4p" ./test1.log

# latency 变动较大，不宜解析
for job in $tjobs;
do  
    echo "now jos is $job"
    # ctx=`grep $job -n ${logfile} | grep  groupid`
    # echo $ctx
    ln=`grep $job -n ${logfile} | grep groupid | awk -F ":" '{print $1}'`
    # echo "line No is $ln"
    ln=$((ln+1))
    ctx=`sed -n "${ln},${ln}p" $logfile`
    echo "ctx is $ctx"

    timeval=`echo "${ctx%msec\)}"`
    timeval=`echo "${timeval#*4096KiB\/}"`
    echo "scale=4;$timeval/1024" | bc  2>/dev/null   
    echo ""
done

grep -n "  lat (msec)   :" ${logfile}
```
{: file='analyze_fio.sh'}



```bash
#!/bin/bash

logfile=$1

alltime="0.000"
echo "========== write 2GB file time ==========="
for ((i=1;i<20;i+=2))
do
    turntime=`cat $logfile | grep -n real | sed -n ${i},${i}p`
    turntime=`echo "${turntime%s}"`
    turntime=`echo "${turntime#*m}"`
    # echo $turntime
    alltime=`echo "scale=4;$turntime+$alltime" | bc`
done
avgtime=`echo "scale=4;$alltime/10" | bc`
echo "write avg time is $avgtime s"
speed=`echo "scale=4;2048/$avgtime" | bc`
echo "write avg speed is $speed MB/s"


alltime="0.000"
echo "========== read 2GB file time ==========="
for ((i=2;i<22;i+=2))
do
    turntime=`cat $logfile | grep -n real | sed -n ${i},${i}p`
    turntime=`echo "${turntime%s}"`
    turntime=`echo "${turntime#*m}"`
    # echo $turntime
    alltime=`echo "scale=4;$turntime+$alltime" | bc`
done
avgtime=`echo "scale=4;$alltime/10" | bc`
echo "read avg time is $avgtime s"
speed=`echo "scale=4;2048/$avgtime" | bc`
echo "read avg speed is $speed MB/s"
```
{: file='analyze_file.sh'}

