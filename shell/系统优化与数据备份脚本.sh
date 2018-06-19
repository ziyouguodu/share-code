#!/bin/sh
#日志因确保有备份，此脚本应在夜间执行
#-----------清除缓存与日志------------
sync; echo 3 > /proc/sys/vm/drop_caches
cat /dev/null > /var/log/syslog
cat /dev/null > /var/adm/sylog
cat /dev/null > /var/log/wtmp
cat /dev/null > /var/log/maillog
cat /dev/null > /var/log/messages
#-----------备份web程序------------------
DATE=`date +%Y%m%d`
zip -r /alidata/backups/web/test/web_$DATE.zip /alidata/www/test
#-----------备份数据库-----------
# Database info
DB_NAME="  "
DB_USER="  "
DB_PASS="  "
# PATH
BIN_DIR="/alidata/server/mysql/bin/"
BCK_DIR="/alidata/backups/mysql/test"

# TODO
$BIN_DIR/mysqldump --opt -u$DB_USER -p$DB_PASS $DB_NAME | gzip > $BCK_DIR/db_$DATE.gz

#删除超过30天的
find /alidata/backups/mysql/test -mtime +30 -name '*.gz' -exec rm -rf {} \;
find /alidata/backups/web/test -mtime +30 -name '*.zip' -exec rm -rf {} \;
