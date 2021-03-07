#!/bin/sh
# Copyright (C) 2021 GH-X

ADDRESS_CONF="$CUSTOMCONF_DIR/smartdns_address.conf"
ADDRESS_LOG="/tmp/smartdns_address.log"
ADDRESS_TEMP="$CONF_DIR/smartdns_address.conf"
ADDRESS_MD5="$CONF_DIR/smartdns_address.md5"
smartdns_process=`pidof smartdns`

addressmemory()
{
logger -t "SmartDNS" "启用域名地址记忆"
while [ -n "$smartdns_process" ]
do
  sleep $smartdns_process
  cat $ADDRESS_LOG $ADDRESS_CONF | grep -v '^$' | awk -F/ '!a[$2]++{print $0}' | while read line
  do
    echo "$line" >> $ADDRESS_TEMP
  done
  md5sum $ADDRESS_TEMP >> $ADDRESS_MD5
  md5sum $ADDRESS_CONF -c $ADDRESS_MD5
  if [ "$?" == "0" ]; then
    rm -f $ADDRESS_TEMP
    rm -f $ADDRESS_MD5
    logger -t "SmartDNS" "没有新的域名地址"
  else
    rm -f $ADDRESS_CONF
    cp -rf $ADDRESS_TEMP $ADDRESS_CONF
    rm -f $ADDRESS_TEMP
    rm -f $ADDRESS_LOG
    logger -t "SmartDNS" "域名地址更新成功"
    smartdns.sh restart
  fi
done
}

case $1 in
start)
  addressmemory
  ;;
esac
