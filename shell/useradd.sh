#!/bin/bash
for i in `seq 1 20`
do
	pwd=$(cat /dev/urandom | head -1 | md5sum | head -c 5)
	useradd user$i
	echo "user$pwd" | passwd --stdin user$i
	echo "user$i user$pwd" >> userinfo.txt
done
	
