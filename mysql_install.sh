#!/bin/bash
# coding: utf-8
################################################################
# @@ScriptName: mysql_install.sh
# @@Author: sylee
# @@Modify Date: 2014-06-17 16:09
# @@Description:
#   mysql auto install script. mysql version is 5.1.72 or 5.5.37
################################################################

base_dir=$(pwd)
dir_src="/usr/local/src"

function check_mysql() {
rpm -qa|grep mysql
rpm -e mysql

yum -y remove mysql-server mysql
yum -y install bison gcc gcc-c++ cmake ncurses-devel wget
}

function mysql_select() {
clear
echo "#################################################"
cat <<EOF
1. install mysql5.1.72
2. install mysql5.5.37

EOF

while true; do
  echo -n "Pls input which mysql version you want to install(1 or 2) :"
  read mysqlver
  case $mysqlver in
    1)
      mysql51_install 2>&1 | tee -a $base_dir/install.log
      break
      ;;
    2)
      mysql55_install 2>&1 | tee -a $base_dir/install.log
      break
      ;;
    *)
      echo -n "Error Selection! "
      ;;
  esac
done

#set mysql root passwd
echo "#################################################"
read -p "please input mysql root password(default password: root): " mysqlpwd
mysqlpwd=${mysqlpwd:=root}
echo "Your mysql root password is: $mysqlpwd"

}

function mysql51_install() {

check_mysql 2>&1 | tee -a $base_dir/install.log

wget http://cdn.mysql.com/archives/mysql-5.1/mysql-5.1.72.tar.gz -P $dir_src
cd $dir_src
if [[ -s "mysql-5.1.72.tar.gz" ]]; then
  echo "mysql-5.1.72.tar.gz found"
else
  wget http://cdn.mysql.com/archives/mysql-5.1/mysql-5.1.72.tar.gz -P $dir_src
fi
rm -f /etc/my.cnf
useradd -s /sbin/nologin -M mysql

tar zxvf mysql-5.1.72.tar.gz
cd mysql-5.1.72/
./configure --prefix=/usr/local/mysql \
--with-charset=utf8 \
--with-collation=utf8_general_ci \
--with-extra-charsets=complex \
--enable-thread-safe-client \
--enable-assembler \
--with-mysqld-ldflags=-all-static \
--enable-thread-safe-client \
--with-big-tables \
--with-readline \
--with-ssl \
--with-embedded-server \
--enable-local-infile \
--with-plugins=innobase \
--with-plugins=partition
make -j 2 && make install

#判断mysql是否安装成功
if [ -s /usr/local/mysql -a -s /usr/local/mysql/bin/mysql ]; then
  info_mysql="ok"
else
  echo "Error: /usr/local/mysql not found! mysql install failed!"
  exit 1
fi

cp /usr/local/mysql/share/mysql/my-medium.cnf /etc/my.cnf
sed -i 's/skip-locking/skip-external-locking/g' /etc/my.cnf
cp /usr/local/mysql/share/mysql/mysql.server /etc/init.d/mysql
chmod 755 /etc/init.d/mysql
chkconfig mysql on
/usr/local/mysql/bin/mysql_install_db --user=mysql
chown -R mysql /usr/local/mysql/var
chgrp -R mysql /usr/local/mysql/

cat > /etc/ld.so.conf.d/mysql.conf<<EOF
/usr/local/mysql/lib/mysql
/usr/local/lib
EOF
ldconfig

ln -s /usr/local/mysql/lib/mysql /usr/lib/mysql
ln -s /usr/local/mysql/include/mysql /usr/include/mysql
ln -s /usr/local/mysql/bin/mysql /usr/bin/mysql
ln -s /usr/local/mysql/bin/mysqldump /usr/bin/mysqldump
ln -s /usr/local/mysql/bin/myisamchk /usr/bin/myisamchk
ln -s /usr/local/mysql/bin/mysqld_safe /usr/bin/mysqld_safe

/etc/init.d/mysql start
/usr/local/mysql/bin/mysqladmin -u root password $mysqlpwd

#删除多余用户
cat > /tmp/mysql_sec_script<<EOF
use mysql;
delete from user where not (user='root') ;
delete from user where user='root' and password='';
drop database test;
DROP USER ''@'%';
flush privileges;
EOF

/usr/local/mysql/bin/mysql -u root -p$mysqlpwd -h localhost < /tmp/mysql_sec_script
rm -f /tmp/mysql_sec_script

/etc/init.d/mysql restart

#mysql安装信息
echo "################## Mysql Install successfull #####################"
echo "mysql dir: /usr/local/mysql"
echo "mysql datadir: /usr/local/mysql/var"
echo 'useage:  service mysql {start|stop|reload|restart|status}'
echo "#################################################################"

}

function mysql55_install() {

check_mysql 2>&1 | tee -a $base_dir/install.log

wget http://cdn.mysql.com/Downloads/MySQL-5.5/mysql-5.5.37.tar.gz -P $dir_src
cd $dir_src
if [[ -s "mysql-5.5.37.tar.gz" ]]; then
  echo "mysql-5.5.37.tar.gz found"
else
  wget http://cdn.mysql.com/Downloads/MySQL-5.5/mysql-5.5.37.tar.gz -P $dir_src
fi
rm -f /etc/my.cnf
useradd -s /sbin/nologin -M mysql

tar zxvf mysql-5.5.37.tar.gz
cd mysql-5.5.37
cmake -DCMAKE_INSTALL_PREFIX=/usr/local/mysql \
-DMYSQL_USER=mysql \
-DEXTRA_CHARSETS=all \
-DDEFAULT_CHARSET=utf8 \
-DDEFAULT_COLLATION=utf8_general_ci \
-DWITH_READLINE=1 \
-DWITH_SSL=system \
-DWITH_ZLIB=system \
-DWITH_EMBEDDED_SERVER=1 \
-DENABLED_LOCAL_INFILE=1
make -j 2 && make install

#判断mysql是否安装成功
if [ -s /usr/local/mysql -a -s /usr/local/mysql/bin/mysql ]; then
  info_mysql="ok"
else
  echo "Error: /usr/local/mysql not found! mysql install failed!"
  exit 1
fi

chown -R mysql.mysql /usr/local/mysql/
cp support-files/my-medium.cnf /etc/my.cnf
sed '/skip-external-locking/i\datadir = /usr/local/mysql/var' -i /etc/my.cnf
sed '/skip-external-locking/i\default-storage-engine=MyISAM\nloose-skip-innodb' -i /etc/my.cnf

/usr/local/mysql/scripts/mysql_install_db --defaults-file=/etc/my.cnf --basedir=/usr/local/mysql --datadir=/usr/local/mysql/var --user=mysql

cp support-files/mysql.server /etc/init.d/mysql
chmod 755 /etc/init.d/mysql
chkconfig mysql on

cat > /etc/ld.so.conf.d/mysql.conf<<EOF
/usr/local/mysql/lib
/usr/local/lib
EOF
ldconfig

ln -s /usr/local/mysql/lib/mysql /usr/lib/mysql
ln -s /usr/local/mysql/include/mysql /usr/include/mysql
ln -s /usr/local/mysql/bin/mysql /usr/bin/mysql
ln -s /usr/local/mysql/bin/mysqldump /usr/bin/mysqldump
ln -s /usr/local/mysql/bin/myisamchk /usr/bin/myisamchk
ln -s /usr/local/mysql/bin/mysqld_safe /usr/bin/mysqld_safe

/etc/init.d/mysql start
/usr/local/mysql/bin/mysqladmin -u root password $mysqlpwd

#删除多余用户
cat > /tmp/mysql_sec_script<<EOF
use mysql;
delete from user where not (user='root') ;
delete from user where user='root' and password='';
drop database test;
DROP USER ''@'%';
flush privileges;
EOF

/usr/local/mysql/bin/mysql -u root -p$mysqlpwd -h localhost < /tmp/mysql_sec_script
rm -f /tmp/mysql_sec_script

/etc/init.d/mysql restart

#mysql安装信息
echo "################## Mysql Install successfull #####################"
echo "mysql dir: /usr/local/mysql"
echo "mysql datadir: /usr/local/mysql/var"
echo 'useage:  service mysql {start|stop|reload|restart|status}'
echo "#################################################################"

}

mysql_select
