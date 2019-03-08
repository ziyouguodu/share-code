#!/bin/bash
#this script is only for CentOS 7.x
#链神科技 By Anonym0x1

#定义路径
SERVICE="/root/service"
LOGS="/root/logs"
CONF="/root/conf"

#定义软件版本号
NGINX_VERSION=1.14.2
REDIS_VERSION=5.0.3
MYSQL_VERSION=5.7.25
#JDK_VERSION=8u201

#是否使用root用户执行
if [ "$UID" != "0" ];then
    echo "Please run this script by root"
    exit 1
fi

#创建目录
mkdir -p $SERVICE/{nginx,redis}
mkdir -p $LOGS/{nginx,redis,mysql}
mkdir -p $CONF/{nginx,redis,mysql}
chmod 775 /root
chmod 777 -R logs

#安装java环境
Install_JavaJdk()
{
cd ${SERVICE}
 wget -T 360 --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie"  https://download.oracle.com/otn-pub/java/jdk/8u201-b09/42970487e3af4f5aa5bca3f542482c60/jdk-8u201-linux-x64.tar.gz
if [ ! -f  "jdk-8u201-linux-x64.tar.gz" ]; then
  echo "java-jdk安装包下载失败";
  exit 1;
fi
tar -zxvf jdk-8u201-linux-x64.tar.gz && rm -f jdk-8u201-linux-x64.tar.gz
mv jdk1.8.0_201 jdk
cat >> /etc/profile <<EOF
export JAVA_HOME=${SERVICE}/jdk
export CLASSPATH=.:\$JAVA_HOME/lib/dt.jar:\$JAVA_HOME/lib/tools.jar
export PATH=\$PATH:\$JAVA_HOME/bin
EOF
source /etc/profile
}

#安装Nginx
Install_Nginx()
{
    cd ${SERVICE}
    wget -T 360  http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz
    if [ ! -f  "nginx-${NGINX_VERSION}.tar.gz" ]; then
    echo "nginx安装包下载失败";
    exit 2;
    fi

    yum -y install gcc gcc-c++ glibc automake autoconf libtool make pcre pcre-devel zlib  \
    zlib-devel openssl openssl-devel GeoIP GeoIP-devel GeoIP-data \
    lua-devel ibxml2 libxml2-dev libxslt-devel gd-devel

    groupadd www && useradd  -s /sbin/nologin -M -g www www

    tar -zxvf nginx-${NGINX_VERSION}.tar.gz && rm -f nginx-${NGINX_VERSION}.tar.gz
    cd nginx-${NGINX_VERSION}

    ./configure --prefix=${SERVICE}/nginx \
    #--conf-path=${CONF}/nginx/nginx.conf
    --error-log-path=${LOGS}/nginx/nginx_error.log \
    --http-log-path=${LOGS}/nginx/nginx_access.log \
    --user=www \
    --group=www \
    --with-http_ssl_module \
    --with-http_gunzip_module \
    --with-http_gzip_static_module \
    --with-http_secure_link_module \
    --with-http_stub_status_module \
    --with-http_auth_request_module \
    --with-http_geoip_module=dynamic \
    --with-http_v2_module \
    --with-threads \
    --with-file-aio \
    --with-stream \
    --with-stream_ssl_module \

    make && make install

    ln -s ${SERVICE}/nginx/conf/nginx.conf ${CONF}/nginx/nginx.conf

cat  >> /lib/systemd/system/nginx.service << EOF
[Unit]
Description=The NGINX HTTP and reverse proxy server
After=syslog.target network.target remote-fs.target nss-lookup.target

[Service]
Type=forking
PIDFile=${SERVICE}/nginx/logs/nginx.pid
ExecStartPre=${SERVICE}/nginx/sbin/nginx -t
ExecStart=${SERVICE}/nginx/sbin/nginx
ExecReload=${SERVICE}/nginx/sbin/nginx -s reload
ExecStop=/usr/bin/kill -s QUIT \$MAINPID
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload

systemctl start nginx.service && systemctl enable nginx.service

}

#安装redis
Install_Redis()
{
    cd ${SERVICE}
    wget -T 360 http://download.redis.io/releases/redis-${REDIS_VERSION}.tar.gz
    if [ ! -f  "redis-${REDIS_VERSION}.tar.gz" ]; then
    echo "redis安装包下载失败";
    exit 3;
    fi
    tar -zxvf redis-${REDIS_VERSION}.tar.gz && rm -f redis-${REDIS_VERSION}.tar.gz
    yum -y install gcc gcc-c++
    cd redis-${REDIS_VERSION}
    make PREFIX=${SERVICE}/redis install
    cp ${SERVICE}/redis-${REDIS_VERSION}/redis.conf ${CONF}/redis/redis.conf

cat >> /lib/systemd/system/redis.service  << EOF
[Unit]
Description=redis-server
After=network.target

[Service]
Type=forking
ExecStart=${SERVICE}/redis/bin/redis-server ${CONF}/redis/redis.conf
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF
    sed -i 's/daemonize no/daemonize yes/g' ${CONF}/redis/redis.conf
    systemctl daemon-reload
    systemctl start redis.service && systemctl enable redis.service
}


#安装Mysql
Install_MySQL()
{
    cd ${SERVICE}

    wget -T 360 https://dev.mysql.com/get/Downloads/MySQL-5.7/mysql-${MYSQL_VERSION}-linux-glibc2.12-x86_64.tar.gz

    if [ ! -f  "mysql-${MYSQL_VERSION}-linux-glibc2.12-x86_64.tar.gz" ]; then
    echo "mysql安装包下载失败";
    exit 4;
    fi

    yum install -y libaio
    groupadd mysql && useradd -r -g mysql -G root -M -s /bin/false mysql

    tar -zxvf mysql-${MYSQL_VERSION}-linux-glibc2.12-x86_64.tar.gz && rm -f mysql-${MYSQL_VERSION}-linux-glibc2.12-x86_64.tar.gz

    mv mysql-${MYSQL_VERSION}-linux-glibc2.12-x86_64 mysql
    mkdir ./mysql/data
    chown -R mysql:mysql mysql

    cat > /etc/my.cnf << EOF
[mysqld]
server-id=1
basedir=${SERVICE}/mysql
datadir=${SERVICE}/mysql/data
socket=/tmp/mysql.sock
log-error=${LOGS}/mysql/mysql.log
pid-file=${SERVICE}/mysql/data/mysql.pid
explicit_defaults_for_timestamp=true
character-set-server = utf8mb4
collation-server = utf8mb4_general_ci
lower_case_table_names = 1
EOF

./mysql/bin/mysqld --initialize --user=mysql --basedir=${SERVICE}/mysql --datadir=${SERVICE}/mysql/data

    cp ./mysql/support-files/mysql.server /etc/init.d/mysqld
    chkconfig --add mysqld && chkconfig mysqld on
    service mysqld start

    echo "export PATH=${SERVICE}/mysql/bin:\$PATH" >> /etc/profile
    source /etc/profile
    #修改mysql密码
    password=$(grep 'A temporary password' /root/logs/mysql/mysql.log | awk -F"root@localhost: " '{ print $2}')
    ${SERVICE}/mysql/bin/mysql -u root -p${password} --connect-expired-password <<EOF
set password = 'Liansheng!@#2019';
exit
EOF
    ln -s /etc/my.conf ${CONF}/mysql/my.conf
}


Output() {

. /etc/init.d/functions
nginx="nginx-service"
if [ $(netstat -ntlup | grep nginx |wc -l) -gt 0 ] ;then
    action "$nginx" /bin/true
else
    action "$nginx" /bin/false
fi

mysql="mysql-service"
if [ $(netstat -ntlup | grep mysqld |wc -l) -gt 0 ];then
    action "$mysql" /bin/true
else
    action "$mysql" /bin/false
fi

redis="redis-service"
if [ $(netstat -ntlup | grep redis-server |wc -l) -gt 0 ];then
   action "$redis" /bin/true
else
    action "$redis" /bin/false
fi

echo "应用全部安装完毕请查看相关信息并重新启动！！！"
cat << EOF
----------------------------------------------------------------------------------------------------------------------
应用安装路径为：${SERVICE}
配置文件目录路径为：${CONF}
日志文件路径为：${LOGS}
使用systemctl 管理 nginx |redis 服务; Mysql使用 service mysqld start|stop|restart
!!!请注意mysql root密码已经修改
----------------------------------------------------------------------------------------------------------------------
EOF
}

Install(){
cat << EOF
+---------------------------------------------------------------+
|      Nginx+javajdk+redis+Mysql (自动化安装脚本)   |
+---------------------------------------------------------------+
EOF

read -p "Are you sure want to install it?(yes/no):" a
if [[ $a = yes ]];then
    Install_JavaJdk
    Install_Nginx
    Install_Redis
    Install_MySQL
    Output
else
    exit 1
fi
}

Install