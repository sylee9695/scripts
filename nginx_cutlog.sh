#!/bin/bash
# coding: utf-8
################################################################
# @@ScriptName: nginx_cutlog.sh
# @@Author: lsy <88919695@qq.com>
# @@Modify Date: 2014-06-17 16:08
# @@Description:
#################################################################

#run at 23:55

#设置变量
log_path="/home/wwwlogs"
log_filenames=`ls -l $log_path|grep -v "^d"|awk '{print $9}'`
month=`date +%Y-%m`
day=`date +%d`
date3=`date -d "-3 day" +%d`
log_bak_path=$log_path/$month/$day
mkdir -p $log_bak_path
#对日志归档，压缩3天前的日志
for log_name in $log_filenames
do
mv $log_path/$log_name  $log_bak_path/$log_name
gzip -c $log_path/$month/$date3/$log_name > $log_path/$month/$date3/$log_name.gz
done
#删除3天前日志文件和3个月前的日志文件
rm -f $log_path/$month/$date3/*.log
rm -rf $log_path/$(date -d "-3 month" +"%Y-%m")
#重启nginx日志进程
kill -USR1 `cat /usr/local/nginx/logs/nginx.pid`
