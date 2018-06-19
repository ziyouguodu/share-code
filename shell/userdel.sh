#!/bin/bash
for i in `seq 1 20`
do
	userdel user$i
	rm -rf /home/user$i
if (( $? == 0 ))
then
	echo "已经删除用户user$i 与目录"
else
	echo "删除失败"
fi
done
	
