#!/bin/bash
# coding: utf-8
################################################################
# @@ScriptName: sys_initialize.sh
# @@Author: lsy <88919695@qq.com>
# @@Modify Date: 2014-06-17 16:05
# @@Description:
#   initialize the system
#   this script is only for CentOS 6 x86_64
#################################################################


#check the OS version
platform=`uname -i`
if [ $platform != "x86_64" ];then
echo "this script is only for 64bit Operating System !"
exit 1
fi

version=`cat /etc/redhat-release|awk '{print substr($3,1,1)}'`
if [ $version != 6 ];then
echo "this script is only for CentOS 6 !"
exit 1
fi

cat <<EOF
+---------------------------------------+
|   your system is CentOS 6 x86_64      |
|      start initializing......         |
+---------------------------------------+
EOF

#use sohu mirror as the default yum repo,add the epel
echo "#########################add 163 and epel yum repo...##############################" >> ./initialize.log
echo "add 163 and epel yum repo..."
yum -y install wget >> ./initialize.log
mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
wget http://mirrors.163.com/.help/CentOS6-Base-163.repo -O /etc/yum.repos.d/CentOS-Base.repo >> ./initialize.log 2>&1
rpm -Uvh http://mirrors.ustc.edu.cn/epel/6/x86_64/epel-release-6-8.noarch.rpm >> ./initialize.log
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-6 >> ./initialize.log
yum clean all >> ./initialize.log

#install software
echo "##################################install software...##############################" >> ./initialize.log
echo "install software..."
yum -y install vim-enhanced crontabs >> ./initialize.log
cat >> /etc/bashrc <<EOF
alias vi='vim'
EOF

#set the ntp
echo "##################################set the ntp...###################################" >> ./initialize.log
echo "set the ntp..."
echo "* 4 * * * /usr/sbin/ntpdate 210.72.145.44 > /dev/null 2>&1" >> /var/spool/cron/root

#set the file limit
echo "##############################set the file limit...################################" >> ./initialize.log
echo "set the file limit..."
cat >> /etc/security/limits.conf <<EOF
*  soft  nofile  65535
*  hard  nofile  65535
*  soft  nproc   65535
*  hard  nproc   65535
EOF

#set the control-alt-delete to reboot unused
echo "##################set the control-alt-delete to reboot unused...###################" >> ./initialize.log
echo "set the control-alt-delete to reboot unused..."
sed -i 's#exec /sbin/shutdown -r now#\#exec /sbin/shutdown -r now#' /etc/init/control-alt-delete.conf

#disable selinux
echo "################################disable selinux...#################################" >> ./initialize.log
echo "disable selinux..."
sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config

#set ssh
echo "#####################################set ssh...####################################" >> ./initialize.log
echo "set ssh..."
sed -i 's/^GSSAPIAuthentication yes$/GSSAPIAuthentication no/' /etc/ssh/sshd_config
sed -i 's/#UseDNS yes/UseDNS no/' /etc/ssh/sshd_config
service sshd restart >> ./initialize.log 2>&1

#set kernel parametres
echo "#############################set kernel parametres...##############################" >> ./initialize.log
echo "set kernel parametres..."
cat >> /etc/sysctl.conf <<EOF
net.core.somaxconn = 262144
net.core.netdev_max_backlog = 262144
net.ipv4.tcp_max_orphans = 262144
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_max_tw_buckets = 5000
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_max_syn_backlog = 4096
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 1
net.ipv4.ip_local_port_range = 1024 65000
EOF

#stop chkconfig service
echo "##############################stop unused service...###############################" >> ./initialize.log
echo "stop unused service..."
chkconfig ip6tables off


#disable the ipv6
echo "################################disable the ipv6...################################" >> ./initialize.log
echo "disable the ipv6..."
cat > /etc/modprobe.d/ipv6.conf <<EOF
alias net-pf-10 off
options ipv6 off
EOF

echo "NETWORKING_IPV6=off" >> /etc/sysconfig/network

#reboot the system
echo "System initialize done,please see the initialize.log."
read -p "Do you want to reboot your system?[y/n]:" name
case $name in
Y|""|y)
  /sbin/reboot;;
N|n)
  exit 0;;
*)
  echo "error selection."
esac
