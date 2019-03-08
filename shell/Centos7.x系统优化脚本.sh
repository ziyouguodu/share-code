#!/bin/bash
#this script is only for CentOS 7.x by Anonym0x1.com
#是否使用root用户执行
if [ "$UID" != "0" ];then
    echo "Please run this script by root"
    exit 1
fi

#判断是否为64位系统
platform=`uname -i`
if [[ $platform != "x86_64" ]];then
echo "this script is only for 64bit Operating System !"
exit 2
fi
echo "the platform is ok"
cat << EOF
+---------------------------------------+
|   your system is CentOS 7 x86_64      |
|      start optimizing.......          |
+---------------------------------------
EOF

set_dns() {
    #设置公网DNS
cat >> /etc/resolv.conf << EOF
nameserver 114.114.114.114
nameserver 223.5.5.5
EOF
}

mod_yum() {
    #更改阿里云yum源
    yum install wget -y
    mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
    wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
}

add_epel() {
    #添加epel源并重建缓存
    yum install epel-release -y
    yum clean all && yum makecache
}

time_sync() {
    #同步网络时间
    ntpdate cn.pool.ntp.org
    echo "* 3 * * * /usr/sbin/ntpdate cn.pool.ntp.org > /dev/null 2>&1" >> /var/spool/cron/root
    systemctl  restart crond.service
}

open_file() {
    #设置最大打开文件描述符数
    echo "ulimit -SHn 102400" >> /etc/rc.local
cat >> /etc/security/limits.conf << EOF
*          soft   nofile       65535
*          hard   nofile       65535
EOF
}

close_selinux() {
    #禁用selinux
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
    setenforce 0
}

close_firewalld() {
    #关闭防火墙
    systemctl disable firewalld.service && systemctl stop firewalld.service
}

set_ssh() {
    #配置ssh
    sed -i 's/^GSSAPIAuthentication yes$/GSSAPIAuthentication no/' /etc/ssh/sshd_config
    sed -i 's/#UseDNS yes/UseDNS no/' /etc/ssh/sshd_config
    sed -i 's/#Port 22/Port 6588/g' /etc/ssh/sshd_config
    systemctl  restart sshd.service
}

set_kernel() {
    #内核参数优化
    cat >> /etc/sysctl.conf << EOF
    net.ipv6.conf.all.disable_ipv6 = 1
    net.ipv6.conf.default.disable_ipv6 = 1
    net.ipv6.conf.lo.disable_ipv6 = 1
    vm.swappiness = 0
    vm.overcommit_memory = 1
    net.ipv4.neigh.default.gc_stale_time=120
    net.ipv4.conf.all.rp_filter=0
    net.ipv4.conf.default.rp_filter=0
    net.ipv4.conf.default.arp_announce = 2
    net.ipv4.conf.lo.arp_announce=2
    net.ipv4.conf.all.arp_announce=2
    net.ipv4.icmp_echo_ignore_broadcasts = 1
    net.ipv4.icmp_ignore_bogus_error_responses = 1
    net.ipv4.conf.all.accept_source_route = 0
    net.ipv4.conf.default.accept_source_route = 0
    net.ipv4.tcp_max_tw_buckets = 6000
    net.ipv4.tcp_syncookies = 1
    net.ipv4.tcp_sack = 1
    net.ipv4.tcp_max_orphans = 3276800
    net.ipv4.tcp_fin_timeout = 2
    net.ipv4.tcp_tw_reuse = 1
    net.ipv4.tcp_tw_recycle = 1
    net.ipv4.tcp_fin_timeout = 1
    net.ipv4.ip_local_port_range = 10000 65000
    net.ipv4.tcp_timestamps = 1
    net.ipv4.tcp_max_syn_backlog = 262144
    net.ipv4.tcp_synack_retries = 1
    net.ipv4.tcp_syn_retries = 1
    net.ipv4.tcp_keepalive_time = 600
    net.ipv4.tcp_keepalive_probes = 3
    net.ipv4.tcp_keepalive_intvl =15
    net.core.somaxconn = 16384
    net.core.netdev_max_backlog = 16384
    kernel.msgmnb = 65536
    kernel.msgmax = 65536
    fs.file-max=65535
EOF
    sysctl -p
}

update_linux() {
    #更新系统并安装常用工具
    yum -y update
    yum install lrzsz tree bash-completion cmake vim net-tools htop zip unzip screen -y

    cat << EOF
    +-------------------------------------------------+
    |               optimizer is done                 |
    |   it's recommond to restart this server !       |
    +-------------------------------------------------+
EOF
}

main() {
    set_dns
    mod_yum
    add_epel
    time_sync
    open_file
    close_selinux
    close_firewalld
    set_ssh
    set_kernel
    update_linux
}

main