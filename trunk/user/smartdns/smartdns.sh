#!/bin/sh
# Copyright (C) 2018 Nick Peng (pymumu@gmail.com)
# Copyright (C) 2019 chongshengB
# Copyright (C) 2020 GH-X

CONF_DIR="/tmp/SmartDNS"
CUSTOMCONF_DIR="/etc/storage"
SMARTDNS_CONF="$CONF_DIR/smartdns.conf"
CHN_CONF="$CONF_DIR/CHNlist.conf"
GFW_CONF="$CONF_DIR/GFWlist.conf"
DNSS_CONF="$CONF_DIR/dnsmasq.servers"
BIPLIST_CONF="$CONF_DIR/BIPlist.conf"
WIPLIST_CONF="$CONF_DIR/WIPlist.conf"
DNSM_CONF="/etc/dnsmasq.conf"
DNSQ_CONF="$CUSTOMCONF_DIR/dnsmasq/dnsmasq.conf"
BLACKLIST_CONF="$CUSTOMCONF_DIR/smartdns_blacklist.conf"
WHITELIST_CONF="$CUSTOMCONF_DIR/smartdns_whitelist.conf"
CUSTOM_CONF="$CUSTOMCONF_DIR/smartdns_custom.conf"
SMARTDNS_BIN="/usr/bin/smartdns"
GFWRO_CONF="/etc_ro/GFWblack.conf"
GFWBLACK_CONF="$CUSTOMCONF_DIR/GFWblack.conf"
GFWBLACK_TEMP="$CONF_DIR/GFWblack.conf"
GFWBLACK_MD5="$CONF_DIR/GFWblack.md5"
GFWLIST_DIR="$CUSTOMCONF_DIR/gfwlist"
GFWLIST_CONF="$GFWLIST_DIR/dnsmasq_gfwlist.conf"
GFWLIST_TEMP="$CONF_DIR/dnsmasq_gfwlist.conf"
GFWLIST_MD5="$CONF_DIR/dnsmasq_gfwlist.md5"
sdnse_enable=`nvram get sdnse_enable`
sdnse_group=`nvram get sdnse_group`
sdnse_nra=`nvram get sdnse_nra`
sdnse_nrn=`nvram get sdnse_nrn`
sdnse_nri=`nvram get sdnse_nri`
sdnse_nsc=`nvram get sdnse_nsc`
sdnse_nocache=`nvram get sdnse_nocache`
sdnse_nrs=`nvram get sdnse_nrs`
sdnse_nds=`nvram get sdnse_nds`
sdnse_tcp_server=`nvram get sdnse_tcp_server`
sdnse_ipv6_server=`nvram get sdnse_ipv6_server`
sdnse_port=`nvram get sdnse_port`
sdnse_domain_gfw=`nvram get sdnse_domain_gfw`
sdns_enable=`nvram get sdns_enable`
sdns_tcp_server=`nvram get sdns_tcp_server`
sdns_ipv6_server=`nvram get sdns_ipv6_server`
sdns_port=`nvram get sdns_port`
sdns_group=`nvram get sdns_group`
sdns_redirect=`nvram get sdns_redirect`
sdns_scm=`nvram get sdns_scm`
snds_dis=`nvram get snds_dis`
snds_cache=`nvram get snds_cache`
sdns_prefetch=`nvram get sdns_prefetch`
sdns_expired=`nvram get sdns_expired`
ss_enable=`nvram get ss_enable`

sdns_check()
{
if [ "$sdns_group" == "$sdnse_group" ]; then
logger -t "SmartDNS" "设置错误!白名单域名服务器分组$sdns_group与黑名单域名服务器分组$sdnse_group相同"
nvram set sdns_enable=0
logger -t "SmartDNS" "程序退出!请重新设置"
exit 0
fi
if [ "$sdns_port" == "$sdnse_port" ]; then
logger -t "SmartDNS" "设置错误!服务器端口$sdns_port与第二服务器端口$sdnse_port相同"
nvram set sdns_enable=0
logger -t "SmartDNS" "程序退出!请重新设置"
exit 0
fi
}

gensdnssecond()
{
logger -t "SmartDNS" "配置第二服务器"
if [ $sdnse_enable -eq 1 ]; then
ARGS=""
ADDR=""
if [ "$sdnse_group" != "" ]; then
  ARGS="$ARGS -group $sdnse_group"
fi
if [ "$sdnse_nra" = "1" ]; then
  ARGS="$ARGS -no-rule-addr"
fi
if [ "$sdnse_nrn" = "1" ]; then
  ARGS="$ARGS -no-rule-nameserver"
fi
if [ "$sdnse_nri" = "1" ]; then
  ARGS="$ARGS -no-rule-ipset"
fi
if [ "$sdnse_nsc" = "1" ]; then
  ARGS="$ARGS -no-speed-check"
fi
if [ "$sdnse_nocache" = "1" ]; then
  ARGS="$ARGS -no-cache"
fi
if [ "$sdnse_nrs" = "1" ]; then
  ARGS="$ARGS -no-rule-soa"
fi
if [ "$sdnse_nds" = "1" ]; then
  ARGS="$ARGS -no-dualstack-selection"
fi
if [ "$sdnse_ipv6_server" = "0" ]; then
  ARGS="$ARGS -force-aaaa-soa"
fi
if [ "$sdnse_ipv6_server" = "1" ]; then
  ADDR="[::]"
  DNSS_B="::1#$sdnse_port"
else
  ADDR=""
  DNSS_B="127.0.0.1#$sdnse_port"
fi
echo "bind" "$ADDR:$sdnse_port$ARGS" >> $SMARTDNS_CONF
if [ "$sdnse_tcp_server" = "1" ]; then
  echo "bind-tcp" "$ADDR:$sdnse_port$ARGS" >> $SMARTDNS_CONF
fi
fi
}

gensdnsserver()
{
logger -t "SmartDNS" "配置上游服务器"
listnum=`nvram get sdnss_staticnum_x`
for i in $(seq 1 $listnum)
do
j=`expr $i - 1`
sdnss_enable=`nvram get sdnss_enable_x$j`
if [ $sdnss_enable -eq 1 ]; then
sdnss_ip=`nvram get sdnss_ip_x$j`
sdnss_port=`nvram get sdnss_port_x$j`
sdnss_type=`nvram get sdnss_type_x$j`
sdnss_group=`nvram get sdnss_group_x$j`
sdnss_edg=`nvram get sdnss_edg_x$j`
sdnss_ipc=`nvram get sdnss_ipc_x$j`
sdnss_name=`nvram get sdnss_name_x$j`
sdnss_custom=`nvram get sdnss_custom_x$j`
group=""
edg=""
ipc=""
name=""
custom=""
if [ "$sdnss_group" != "" ]; then
  group=" -group $sdnss_group"
fi
if [ "$sdnss_group" != "" ] && [ "$sdnss_edg" = "1" ]; then
  edg=" -exclude-default-group"
fi
if [ "$sdnss_ipc" = "whitelist" ]; then
  ipc=" -whitelist-ip"
elif [ "$sdnss_ipc" = "blacklist" ]; then
  ipc=" -blacklist-ip"
fi
if [ "$sdnss_name" != "" ]; then
  name=" -host-name $sdnss_name -tls-host-verify"
fi
if [ "$sdnss_custom" != "" ]; then
  custom=" $sdnss_custom"
fi
if [ "$sdnss_type" = "tcp" ]; then
if [ "$sdnss_port" = "" ]; then
  echo "server-tcp $sdnss_ip:53$custom$ipc$group$edg" >> $SMARTDNS_CONF
else
  echo "server-tcp $sdnss_ip:$sdnss_port$custom$ipc$group$edg" >> $SMARTDNS_CONF
fi
elif [ "$sdnss_type" = "udp" ]; then
if [ "$sdnss_port" = "" ]; then
  echo "server $sdnss_ip:53$custom$ipc$group$edg" >> $SMARTDNS_CONF
else
  echo "server $sdnss_ip:$sdnss_port$custom$ipc$group$edg" >> $SMARTDNS_CONF
fi
elif [ "$sdnss_type" = "tls" ]; then
if [ "$sdnss_port" = "" ]; then
  echo "server-tls $sdnss_ip:853$name$custom$ipc$group$edg" >> $SMARTDNS_CONF
else
  echo "server-tls $sdnss_ip:$sdnss_port$name$custom$ipc$group$edg" >> $SMARTDNS_CONF
fi
elif [ "$sdnss_type" = "https" ]; then
if [ "$sdnss_port" = "" ]; then
  echo "server-https $sdnss_ip:443$name$custom$ipc$group$edg" >> $SMARTDNS_CONF
else
  echo "server-https $sdnss_ip:$sdnss_port$name$custom$ipc$group$edg" >> $SMARTDNS_CONF
fi
fi
fi
done
}

gensdnswblist()
{
rm -f $BIPLIST_CONF
rm -f $WIPLIST_CONF
if [ -f "/etc/storage/chinadns/chnroute.txt" ]; then
  CHN_R="/etc/storage/chinadns/chnroute.txt"
  logger -t "SmartDNS" "配置国内路由表为黑名单地址"
  touch $BIPLIST_CONF
  awk '{printf("blacklist-ip %s\n", $1, $1 )}' $CHN_R >> $BIPLIST_CONF
  echo "conf-file $BIPLIST_CONF" >> $SMARTDNS_CONF
  logger -t "SmartDNS" "配置国内路由表为白名单地址"
  touch $WIPLIST_CONF
  awk '{printf("whitelist-ip %s\n", $1, $1 )}' $CHN_R >> $WIPLIST_CONF
  echo "conf-file $WIPLIST_CONF" >> $SMARTDNS_CONF
else
  logger -t "SmartDNS" "没有找到国内路由表"
fi
}

upgfwblack()
{
cat $GFWRO_CONF $BLACKLIST_CONF | grep -v '^#' | grep -v '^$' | awk '!a[$0]++' >> $GFWBLACK_TEMP
md5sum $GFWBLACK_TEMP >> $GFWBLACK_MD5
md5sum $GFWBLACK_CONF -c $GFWBLACK_MD5
if [ "$?" == "0" ]; then
  rm -f $GFWBLACK_TEMP
  rm -f $GFWBLACK_MD5
else
  rm -f $GFWBLACK_CONF
  cp -rf $GFWBLACK_TEMP $CUSTOMCONF_DIR
  rm -f $GFWBLACK_TEMP
  rm -f $GFWBLACK_MD5
fi
}

upgfwdnsmq()
{
grep -v '^#' $GFWBLACK_CONF | grep -v '^$' | awk '{printf("server=/%s/'$DNSS_B'\n", $1, $1 )}' >> $GFWLIST_TEMP
md5sum $GFWLIST_TEMP >> $GFWLIST_MD5
md5sum $GFWLIST_CONF -c $GFWLIST_MD5
if [ "$?" == "0" ]; then
  rm -f $GFWLIST_TEMP
  rm -f $GFWLIST_MD5
else
  rm -f $GFWLIST_CONF
  cp -rf $GFWLIST_TEMP $GFWLIST_DIR
  rm -f $GFWLIST_TEMP
  rm -f $GFWLIST_MD5
  sed -i 's/### gfwlist related.*/### gfwlist related resolve by SmartDNS '$DNSS_B'/g' $DNSQ_CONF
fi
}

gensdnschngfw()
{
rm -f $CHN_CONF
rm -f $GFW_CONF
rm -f $DNSS_CONF
touch $CHN_CONF
touch $GFW_CONF
touch $DNSS_CONF
logger -t "SmartDNS" "配置白名单域名"
grep -v '^#' $WHITELIST_CONF | grep -v '^$' | awk '{printf("nameserver /%s/'$sdns_group'\n", $1, $1 )}' >> $CHN_CONF
echo "conf-file $CHN_CONF" >> $SMARTDNS_CONF
grep -v '^#' $WHITELIST_CONF | grep -v '^$' | awk '{printf("server=/%s/'$DNSS_W'\n", $1, $1 )}' >> $DNSS_CONF
if [ "$sdnse_enable" = "1" ] && [ "$sdnse_domain_gfw" = "1" ]; then
if [ -f "$GFWLIST_CONF" ]; then
  logger -t "SmartDNS" "配置黑名单域名"
  upgfwblack
  upgfwdnsmq
  grep -v '^#' $GFWBLACK_CONF | grep -v '^$' | awk '{printf("nameserver /%s/'$sdnse_group'\n", $1, $1 )}' >> $GFW_CONF
  echo "conf-file $GFW_CONF" >> $SMARTDNS_CONF
  grep -v '^#' $GFWBLACK_CONF | grep -v '^$' | awk '{printf("server=/%s/'$DNSS_B'\n", $1, $1 )}' >> $DNSS_CONF
else
  logger -t "SmartDNS" "配置黑名单域名"
  upgfwblack
  grep -v '^#' $GFWBLACK_CONF | grep -v '^$' | awk '{printf("nameserver /%s/'$sdnse_group'\n", $1, $1 )}' >> $GFW_CONF
  echo "conf-file $GFW_CONF" >> $SMARTDNS_CONF
  grep -v '^#' $GFWBLACK_CONF | grep -v '^$' | awk '{printf("server=/%s/'$DNSS_B'\n", $1, $1 )}' >> $DNSS_CONF
fi
fi
}

gensdnsconf()
{
logger -t "SmartDNS" "创建配置文件"
rm -f $SMARTDNS_CONF
touch $SMARTDNS_CONF
echo "conf-file $CUSTOM_CONF" >> $SMARTDNS_CONF
if [ "$sdns_ipv6_server" = "1" ]; then
  echo "bind" "[::]:$sdns_port" >> $SMARTDNS_CONF
  DNSS_W="::1#$sdns_port"
else
  echo "bind" ":$sdns_port" "-no-dualstack-selection" "-force-aaaa-soa" >> $SMARTDNS_CONF
  DNSS_W="127.0.0.1#$sdns_port"
fi
if [ "$sdns_tcp_server" = "1" ]; then
if [ "$sdns_ipv6_server" = "1" ]; then
  echo "bind-tcp" "[::]:$sdns_port" >> $SMARTDNS_CONF
else
  echo "bind-tcp" ":$sdns_port" "-no-dualstack-selection" "-force-aaaa-soa" >> $SMARTDNS_CONF
fi
fi
gensdnssecond
if [ "$sdns_ipv6_server" = "0" ] && [ "$sdnse_ipv6_server" = "0" ]; then
  echo "force-AAAA-SOA yes" >> $SMARTDNS_CONF
else
  echo "force-AAAA-SOA no" >> $SMARTDNS_CONF
fi
if [ "$sdns_scm" = "6" ]; then
  echo "speed-check-mode tcp:443,tcp:80" >> $SMARTDNS_CONF
elif [ "$sdns_scm" = "5" ]; then
  echo "speed-check-mode tcp:80,tcp:443" >> $SMARTDNS_CONF
elif [ "$sdns_scm" = "4" ]; then
  echo "speed-check-mode tcp:443,ping" >> $SMARTDNS_CONF
elif [ "$sdns_scm" = "3" ]; then
  echo "speed-check-mode tcp:80,ping" >> $SMARTDNS_CONF
elif [ "$sdns_scm" = "2" ]; then
  echo "speed-check-mode ping,tcp:443" >> $SMARTDNS_CONF
elif [ "$sdns_scm" = "1" ]; then
  echo "speed-check-mode ping,tcp:80" >> $SMARTDNS_CONF
else
  echo "speed-check-mode none" >> $SMARTDNS_CONF
fi
if [ "$snds_dis" = "1" ]; then
  echo "dualstack-ip-selection yes" >> $SMARTDNS_CONF
else
  echo "dualstack-ip-selection no" >> $SMARTDNS_CONF
fi
echo "cache-size $snds_cache" >> $SMARTDNS_CONF
if [ "$sdns_prefetch" = "1" ]; then
  echo "prefetch-domain yes" >> $SMARTDNS_CONF
else
  echo "prefetch-domain no" >> $SMARTDNS_CONF
fi
if [ "$sdns_expired" = "1" ]; then
  echo "serve-expired yes" >> $SMARTDNS_CONF
else
  echo "serve-expired no" >> $SMARTDNS_CONF
fi
gensdnsserver
gensdnswblist
gensdnschngfw
cat >> $SMARTDNS_CONF << EOF
log-file /tmp/smartdns.log
log-size 1m
log-num 0
audit-enable yes
audit-size 1m
audit-file /tmp/smartdns.log
audit-num 0
EOF
}

sdnsredirect()
{
if [ "$ss_enable" = "1" ] && [ "$sdnse_enable" = "1" ] && [ "$sdnse_domain_gfw" = "1" ]; then
if [ "$sdns_redirect" = "1" ]; then
  sed -i '/^no-resolv/d' $DNSQ_CONF
  sed -i '/^server=127.0.0.1/d' $DNSQ_CONF
  sed -i '/^server=::1/d' $DNSQ_CONF
  cat >> $DNSQ_CONF << EOF
no-resolv
server=$DNSS_W
EOF
  logger -t "SmartDNS" "添加DNS转发到$DNSS_W"
else
  sed -i '/^no-resolv/d' $DNSQ_CONF
  sed -i '/^server=127.0.0.1/d' $DNSQ_CONF
  sed -i '/^server=::1/d' $DNSQ_CONF
fi
fi
if [ "$ss_enable" = "0" ]; then
if [ "$sdns_redirect" = "1" ]; then
  sed -i '/^no-resolv/d' $DNSQ_CONF
  sed -i '/^server=127.0.0.1/d' $DNSQ_CONF
  sed -i '/^server=::1/d' $DNSQ_CONF
  cat >> $DNSQ_CONF << EOF
no-resolv
server=$DNSS_W
EOF
  logger -t "SmartDNS" "添加DNS转发到$DNSS_W"
else
  sed -i '/^no-resolv/d' $DNSQ_CONF
  sed -i '/^server=127.0.0.1/d' $DNSQ_CONF
  sed -i '/^server=::1/d' $DNSQ_CONF
fi
fi
}

gensdnsmasq()
{
if [ "$ss_enable" = "1" ] && [ "$sdnse_enable" = "1" ]; then
if [ "$sdnse_domain_gfw" = "1" ]; then
  sed -i 's/^min-cache-ttl=/#min-cache-ttl=/g' $DNSQ_CONF
  sed -i 's/^conf-dir=/#conf-dir=/g' $DNSQ_CONF
  sed -i '/^servers-file/d' $DNSM_CONF
  echo "servers-file=/tmp/SmartDNS/dnsmasq.servers" >> $DNSM_CONF
else
  sed -i 's/^#min-cache-ttl=/min-cache-ttl=/g' $DNSQ_CONF
  sed -i 's/^#conf-dir=/conf-dir=/g' $DNSQ_CONF
  sed -i '/^servers-file/d' $DNSM_CONF
  echo "servers-file=/tmp/dnsmasq.servers" >> $DNSM_CONF
fi
fi
if [ "$ss_enable" = "0" ] && [ "$sdnse_enable" = "1" ]; then
if [ "$sdnse_domain_gfw" = "1" ]; then
  sed -i '/^servers-file/d' $DNSM_CONF
  echo "servers-file=/tmp/SmartDNS/dnsmasq.servers" >> $DNSM_CONF
else
  sed -i '/^servers-file/d' $DNSM_CONF
  echo "servers-file=/tmp/dnsmasq.servers" >> $DNSM_CONF
fi
fi
}

genrestore()
{
logger -t "SmartDNS" "重置配置"
sed -i 's/^min-cache-ttl=/#min-cache-ttl=/g' $DNSQ_CONF
sed -i 's/^conf-dir=/#conf-dir=/g' $DNSQ_CONF
sed -i '/^no-resolv/d' $DNSQ_CONF
sed -i '/^server=127.0.0.1/d' $DNSQ_CONF
sed -i '/^server=::1/d' $DNSQ_CONF
sed -i '/^servers-file/d' $DNSM_CONF
echo "servers-file=/tmp/dnsmasq.servers" >> $DNSM_CONF
rm -rf /tmp/SmartDNS
rm -rf /tmp/smartdns.log
rm -rf /tmp/smartdns.log*.gz
}

sdnsguard()
{
sdnsprocess=`pidof smartdns`
for sdnspid in $($sdnsprocess)
do
if [ -n "$sdnspid" ]; then
  sleep 1m
else
  logger -t "SmartDNS" "程序异常退出!正在重新启动"
  start_sdns
fi
done
}

start_sdns()
{
killall dnsmasq
logger -t "SmartDNS" "开始启动"
ulimit -n 65536
mkdir -p /tmp/SmartDNS
gensdnsconf
$SMARTDNS_BIN -f -c $SMARTDNS_CONF &> /dev/null &
logger -t "SmartDNS" "配置域名解析方式"
gensdnsmasq
sdnsredirect
smartdns_process=`pidof smartdns`
if [ -n "$smartdns_process" ]; then
logger -t "SmartDNS" "启动成功"
fi
dnsmasq
sdnsguard
}

stop_sdns()
{
killall dnsmasq
smartdns_process=`pidof smartdns`
if [ -n "$smartdns_process" ]; then
  logger -t "SmartDNS" "关闭进程"
  killall smartdns > /dev/null 2>&1
  kill -9 "$smartdns_process" > /dev/null 2>&1
  genrestore
  logger -t "SmartDNS" "关闭成功"
fi
dnsmasq
}

case $1 in
start)
  sdns_check
  start_sdns
  ;;
stop)
  stop_sdns
  ;;
restart)
  stop_sdns
  start_sdns
  ;;
*)
  echo "Usage: $0 { start | stop | restart }"
	exit 1
  ;;
esac
