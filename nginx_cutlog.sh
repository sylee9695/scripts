#!/bin/bash
# coding: utf-8
################################################################
# @@ScriptName: nginx_cutlog.sh
# @@Author: lsy <88919695@qq.com>
# @@Modify Date: 2014-06-18 11:37
# @@Description:
#################################################################

#run at 23:55

log_dir="/home/wwwlogs"
logbak_dir=$log_dir/$(date +%Y-%m)/$(date +%d)
del_day=`date -d "-3 day" +%d`
log_files=`ls $log_dir/$(date +%Y-%m)/$del_day|grep log$`
[ -d $logbak_dir ] || mkdir -p $logbak_dir

#对日志归档，压缩3天前的日志
mv $log_dir/*.log  $logbak_dir/

for log_name in $log_files; do
  gzip $log_dir/$(date +%Y-%m)/$del_day/$log_name
done
#删除3个月前的日志文件
rm -rf $log_dir/$(date -d "-3 month" +"%Y-%m")
#重启nginx日志进程
kill -USR1 `cat /usr/local/nginx/logs/nginx.pid`

