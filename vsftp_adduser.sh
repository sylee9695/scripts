#!/bin/bash
# coding: utf-8
################################################################
# @@ScriptName: vsftp_adduser.sh
# @@Author: lsy <88919695@qq.com>
# @@Modify Date: 2014-06-17 16:07
# @@Description:
#  this scripts is used to add vsftp virtual user.
################################################################

if [ $(id -u) != "0" ]; then
    echo "Error: You must be use root to run this script!"
    exit 1
fi
clear

vuser_dir=/etc/vsftpd/vusers
local_user=
vir_user=
vir_pwd=
vir_dir=

#判断vsftpd是否安装
rpm -qa|grep vsftp

if [[ $? -ne 0 ]]; then
  yum install vsftpd db4-utils -y
else
  echo "vsftpd installed."
fi

#增加ftp虚拟用户函数
function add_user() {

read -p "please input mapped local user(default www user,enter): " local_user
local_user=${local_user:=www}

while true;do
  read -p "please input ftp username: " vir_user
  if [[ $vir_user = "" ]]; then
    echo "Error! ftp username is null."
  else
    break
  fi
done

while true;do
  read -p "please input ftp password: " vir_pwd
  if [[ $vir_pwd = "" ]]; then
    echo "Error! ftp password is null."
  else
    break
  fi
done

while true;do
  read -p "please input ftp dir: " vir_dir
  if [[ -d $vir_dir ]]; then
    break
  else
    echo "the directry is not exist!"
  fi
done

}

#创建ftp虚拟用户函数
function create_user() {

if [[ ! -d "$vuser_dir" ]]; then
  mkdir $vuser_dir
fi

cat >>/etc/vsftpd/vsftpd_login.txt <<EOF
$vir_user
$vir_pwd
EOF

cat >$vuser_dir/$vir_user <<EOF
guest_enable=YES
guest_username=$local_user
local_root=$vir_dir
write_enable=YES
EOF

db_load -T -t hash -f /etc/vsftpd/vsftpd_login.txt /etc/vsftpd/vsftpd_login.db

/etc/init.d/vsftpd restart
}

#确认ftp虚拟用户信息函数
function user_info() {

add_user

echo "========================================"
echo "local user is: $local_user"
echo "local ftp user is: $vir_user"
echo "local ftp password is: $vir_pwd"
echo "local ftp directry is: $vir_dir"
echo "========================================"

while true;do
  read -p "Are you sure the ftp information? (y or n): " info
  case $info in
    Y|y)
      create_user
      break
      ;;
    N|n)
      user_info
      break
      ;;
    *)
      echo ""
  esac
done
}

user_info

