#!/bin/bash


nginx_home=/usr/local/nginx
log_path=/home/wwwlogs

ie_agent="360Spider|googlebot|Baiduspider|Sogou web spider|YoudaoBot|YisouSpider"
local_net="10.0.0.100|10.0.0.101"

echo "" >$nginx_home/conf/vhost/blockip.conf

#deny access.log
echo "########################">>$nginx_home/conf/vhost/blockip.conf
tail -n5000 $log_path/access.log \
|grep -i -v -E "$ie_agent" \
|awk '{print $1}' \
|grep -i -v -E "$local_net" \
|awk -F: '{print $1}'|sort|uniq -c|sort -rn \
|awk '{if($1>200)print "deny "$2";"}' >>$nginx_home/conf/vhost/blockip.conf
