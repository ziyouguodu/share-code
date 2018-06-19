#!/bin/bash
#扫描192.168.1.0/24网段在线主机
#--------方案一，使用nmap快速扫描-------
yum install -y nmap
nmap -sP 192.168.1.0/24

#--------方案二：使用ping判断----------
ip=192.168.1.
for n in `seq 1 254`
do
ping -c 3 $ip$n &> /tmp/day.log
	if (( $? == 0 ))
	then
	echo "$ip$n 在线"
	else
	echo "$ip$n 不在线"
fi
done
