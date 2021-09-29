#!/bin/sh
# 
# Copyright (C) 2018 Nick Peng (pymumu@gmail.com)
# Copyright (C) 2019 chongshengB
# Copyright (C) 2020-2021 GH-X

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
GFWBLACK_CONF="$CUSTOMCONF_DIR/GFWblack.conf"
GFWBLACK_TEMP="$CONF_DIR/GFWblack.conf"
GFWBLACK_MD5="$CONF_DIR/GFWblack.md5"
GFWLIST_CONF="$CUSTOMCONF_DIR/gfwlist/dnsmasq_gfwlist.conf"
GFWLIST_TEMP="$CONF_DIR/dnsmasq_gfwlist.conf"
GFWLIST_MD5="$CONF_DIR/dnsmasq_gfwlist.md5"
ADDRESS_LOG="/tmp/smartdns_address.log"
ADDRESS_CONF="$CUSTOMCONF_DIR/smartdns_address.conf"
ADDRESS_TEMP="$CONF_DIR/smartdns_address.conf"
ADDRESS_TMP="$CONF_DIR/smartdns_address.tmp"
ADDRESS_MD5="$CONF_DIR/smartdns_address.md5"
GFWBLACKIP_CONF="$CUSTOMCONF_DIR/GFWblackip.conf"
GFWBLACKIP_TEMP="$CONF_DIR/GFWblackip.conf"
GFWBLACKIP_TMP="$CONF_DIR/GFWblackip.tmp"
GFWBLACKIP_MD5="$CONF_DIR/GFWblackip.md5"
CHNWHITEIP_CONF="$CUSTOMCONF_DIR/CHNwhiteip.conf"
CHNWHITEIP_TEMP="$CONF_DIR/CHNwhiteip.conf"
CHNWHITEIP_TMP="$CONF_DIR/CHNwhiteip.tmp"
CHNWHITEIP_MD5="$CONF_DIR/CHNwhiteip.md5"
CRON_CONF="$CUSTOMCONF_DIR/cron/crontabs/admin"
sdnse_enable=$(nvram get sdnse_enable)
sdnse_group=$(nvram get sdnse_group)
sdnse_nra=$(nvram get sdnse_nra)
sdnse_nrn=$(nvram get sdnse_nrn)
sdnse_nri=$(nvram get sdnse_nri)
sdnse_nsc=$(nvram get sdnse_nsc)
sdnse_nocache=$(nvram get sdnse_nocache)
sdnse_nrs=$(nvram get sdnse_nrs)
sdnse_nds=$(nvram get sdnse_nds)
sdnse_tcp_server=$(nvram get sdnse_tcp_server)
sdnse_ipv6_server=$(nvram get sdnse_ipv6_server)
sdnse_port=$(nvram get sdnse_port)
sdnse_domain_gfw=$(nvram get sdnse_domain_gfw)
sdns_enable=$(nvram get sdns_enable)
sdns_tcp_server=$(nvram get sdns_tcp_server)
sdns_ipv6_server=$(nvram get sdns_ipv6_server)
sdns_group=$(nvram get sdns_group)
sdns_redirect=$(nvram get sdns_redirect)
sdns_scm=$(nvram get sdns_scm)
snds_dis=$(nvram get snds_dis)
snds_cache=$(nvram get snds_cache)
sdns_prefetch=$(nvram get sdns_prefetch)
sdns_expired=$(nvram get sdns_expired)
sdns_address=$(nvram get sdns_address)
sdns_logl=$(nvram get sdns_logl)

sdns_check()
{
if [ "$sdns_redirect" = "2" ] && [ "$(nvram get sdns_port)" != "53" ]; then
  nvram set sdns_port=53
fi
sdns_port=$(nvram get sdns_port)
if [ -e /tmp/GFWblack.conf ]; then
  GFWBLACK_UPD="/tmp/GFWblack.conf"
else
  GFWBLACK_UPD="/etc_ro/GFWblack.conf"
fi
if [ -e /tmp/GFWblackip.conf ]; then
  GFWBLACKIP_UPD="/tmp/GFWblackip.conf"
else
  GFWBLACKIP_UPD="/dev/null"
fi
if [ -e /tmp/smartdns_address.conf ]; then
  ADDRESS_UPD="/tmp/smartdns_address.conf"
else
  ADDRESS_UPD="/dev/null"
fi
[ -e /tmp/SmartDNSupdate ] && logger -st "SmartDNS[$$]" "上次更新被错误终止" && rm -rf /tmp/SmartDNSupdate
if [ "$sdns_port" == "$sdnse_port" ]; then
  logger -st "SmartDNS[$$]" "设置错误!服务器端口$sdns_port与第二服务器端口$sdnse_port相同"
  nvram set sdns_enable=0
  logger -st "SmartDNS[$$]" "程序退出!请重新设置"
  exit 1
fi
if [ "$sdns_group" == "$sdnse_group" ]; then
  logger -st "SmartDNS[$$]" "设置错误!白名单域名服务器分组$sdns_group与黑名单域名服务器分组$sdnse_group相同"
  nvram set sdns_enable=0
  logger -st "SmartDNS[$$]" "程序退出!请重新设置"
  exit 1
fi
}

gensdnssecond()
{
logger -st "SmartDNS[$$]" "配置第二服务器"
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

sdnsredirect()
{
if [ "$sdns_redirect" = "1" ] && [ "$dnsmasq_upserver" = "1" ]; then
  logger -st "SmartDNS[$$]" "添加DNS转发到$DNSS_W"
  sed -i '/^no-resolv/d' $DNSQ_CONF
  sed -i '/^server=127.0.0.1/d' $DNSQ_CONF
  sed -i '/^server=::1/d' $DNSQ_CONF
  cat >> $DNSQ_CONF << EOF
no-resolv
server=$DNSS_W
EOF
elif [ "$sdns_redirect" = "2" ]; then
  logger -st "SmartDNS[$$]" "添加DNS监听到$DNSS_W"
  sed -i '/^### SmartDNS/d' $DNSQ_CONF
  sed -i '/^port=5353/d' $DNSQ_CONF
  cat >> $DNSQ_CONF << EOF
### SmartDNS redirect occupied 53 port
port=5353
EOF
elif [ "$sdns_redirect" = "0" ]; then
  sed -i '/^no-resolv/d' $DNSQ_CONF
  sed -i '/^server=127.0.0.1/d' $DNSQ_CONF
  sed -i '/^server=::1/d' $DNSQ_CONF
  sed -i '/^### SmartDNS/d' $DNSQ_CONF
  sed -i '/^port=5353/d' $DNSQ_CONF
fi
}

gensdnsmasqup()
{
logger -st "SmartDNS[$$]" "配置域名解析方式"
sed -i '/^servers-file/d' $DNSM_CONF
echo "servers-file=$DNSS_CONF" >> $DNSM_CONF
if [ "$sdnse_enable" = "1" ] && [ "$sdnse_domain_gfw" = "1" ]; then
  dnsmasq_upserver="0"
  sed -i 's/### gfwlist related.*/### gfwlist related resolve by SmartDNS '$DNSS_B'/g' $DNSQ_CONF
  sed -i 's/^#min-cache-ttl=/min-cache-ttl=/g' $DNSQ_CONF
  sed -i 's/^#conf-dir=/conf-dir=/g' $DNSQ_CONF
else
  dnsmasq_upserver="1"
  sed -i 's/^min-cache-ttl=/#min-cache-ttl=/g' $DNSQ_CONF
  sed -i 's/^conf-dir=/#conf-dir=/g' $DNSQ_CONF
fi
sdnsredirect
}

upgfwblack()
{
logger -st "SmartDNS[$$]" "更新黑名单域名"
cp -rf $GFWBLACK_CONF $GFWBLACK_TEMP
md5sum $GFWBLACK_TEMP >> $GFWBLACK_MD5
rm -rf $GFWBLACK_TEMP
cat $GFWBLACK_UPD $BLACKLIST_CONF | grep -v '^#' | grep -v '^$' | awk '!a[$0]++' >> $GFWBLACK_TEMP
for whitedomain in $(cat $WHITELIST_CONF | grep -v '^#' | grep -v '^$')
do
  echo "delete $whitedomain"
  sed -i '/'$whitedomain'/d' $GFWBLACK_TEMP
done
md5sum -c -s $GFWBLACK_MD5
if [ "$?" == "0" ]; then
  logger -st "SmartDNS[$$]" "没有新的黑名单域名"
else
  rm -rf $GFWBLACK_CONF
  cp -rf $GFWBLACK_TEMP $GFWBLACK_CONF
  logger -st "SmartDNS[$$]" "黑名单域名更新成功"
fi
rm -rf $GFWBLACK_TEMP
rm -rf $GFWBLACK_MD5
}

upgfwdnsmq()
{
if [ -d /etc/storage/gfwlist ]; then
  cp -rf $GFWLIST_CONF $GFWLIST_TEMP
  md5sum $GFWLIST_TEMP >> $GFWLIST_MD5
  rm -rf $GFWLIST_TEMP
  grep -v '^#' $GFWBLACK_CONF | grep -v '^$' | awk '{printf("ipset=/%s/gfwlist\n", $1, $1 )}' >> $GFWLIST_TEMP
  grep -v '^#' $WHITELIST_CONF | grep -v '^$' | awk '{printf("ipset=/%s/chnlist\n", $1, $1 )}' >> $GFWLIST_TEMP
  md5sum -c -s $GFWLIST_MD5
  if [ "$?" != "0" ]; then
    rm -rf $GFWLIST_CONF
    cp -rf $GFWLIST_TEMP $GFWLIST_CONF
  fi
  rm -rf $GFWLIST_TEMP
  rm -rf $GFWLIST_MD5
fi
}

gensdnschngfw()
{
rm -rf $CHN_CONF
rm -rf $GFW_CONF
rm -rf $DNSS_CONF
touch $CHN_CONF
touch $GFW_CONF
touch $DNSS_CONF
if [ "$sdnse_enable" = "1" ]; then
  [ -e /tmp/SmartDNSupdate ] || upgfwblack
  logger -st "SmartDNS[$$]" "配置黑名单域名"
  grep -v '^#' $GFWBLACK_CONF | grep -v '^$' | awk '{printf("nameserver /%s/'$sdnse_group'\n", $1, $1 )}' >> $GFW_CONF
  echo "conf-file $GFW_CONF" >> $SMARTDNS_CONF
  grep -v '^#' $GFWBLACK_CONF | grep -v '^$' | awk '{printf("server=/%s/'$DNSS_B'\n", $1, $1 )}' >> $DNSS_CONF
if [ "$sdnse_domain_gfw" = "1" ]; then
  [ -e /tmp/SmartDNSupdate ] || upgfwdnsmq
fi
fi
logger -st "SmartDNS[$$]" "配置白名单域名"
grep -v '^#' $WHITELIST_CONF | grep -v '^$' | awk '{printf("nameserver /%s/'$sdns_group'\n", $1, $1 )}' >> $CHN_CONF
echo "conf-file $CHN_CONF" >> $SMARTDNS_CONF
grep -v '^#' $WHITELIST_CONF | grep -v '^$' | awk '{printf("server=/%s/'$DNSS_W'\n", $1, $1 )}' >> $DNSS_CONF
}

gensdnswblist()
{
CHN_R="/etc/storage/chinadns/chnroute.txt"
rm -rf $BIPLIST_CONF
rm -rf $WIPLIST_CONF
touch $BIPLIST_CONF
logger -st "SmartDNS[$$]" "配置白名单地址为黑名单限制地址"
awk '{printf("blacklist-ip %s\n", $1, $1 )}' $CHNWHITEIP_CONF >> $BIPLIST_CONF
if [ -f "$CHN_R" ]; then
  logger -st "SmartDNS[$$]" "配置国内路由表为黑名单限制地址"
  awk '{printf("blacklist-ip %s\n", $1, $1 )}' $CHN_R >> $BIPLIST_CONF
fi
echo "conf-file $BIPLIST_CONF" >> $SMARTDNS_CONF
touch $WIPLIST_CONF
logger -st "SmartDNS[$$]" "配置白名单地址为白名单允许地址"
awk '{printf("whitelist-ip %s\n", $1, $1 )}' $CHNWHITEIP_CONF >> $WIPLIST_CONF
if [ -f "$CHN_R" ]; then
  logger -st "SmartDNS[$$]" "配置国内路由表为白名单允许地址"
  awk '{printf("whitelist-ip %s\n", $1, $1 )}' $CHN_R >> $WIPLIST_CONF
fi
echo "conf-file $WIPLIST_CONF" >> $SMARTDNS_CONF
}

gensdnsserver()
{
logger -st "SmartDNS[$$]" "配置上游服务器"
listnum=$(nvram get sdnss_staticnum_x)
for i in $(seq 1 $listnum)
do
j=$(expr $i - 1)
sdnss_enable=$(nvram get sdnss_enable_x$j)
if [ $sdnss_enable -eq 1 ]; then
sdnss_ip=$(nvram get sdnss_ip_x$j)
sdnss_port=$(nvram get sdnss_port_x$j)
sdnss_type=$(nvram get sdnss_type_x$j)
sdnss_group=$(nvram get sdnss_group_x$j)
sdnss_edg=$(nvram get sdnss_edg_x$j)
sdnss_ipc=$(nvram get sdnss_ipc_x$j)
sdnss_name=$(nvram get sdnss_name_x$j)
sdnss_custom=$(nvram get sdnss_custom_x$j)
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

upgfwblackip()
{
logger -st "SmartDNS[$$]" "更新黑名单地址"
cp -rf $GFWBLACKIP_CONF $GFWBLACKIP_TEMP
md5sum $GFWBLACKIP_TEMP >> $GFWBLACKIP_MD5
rm -rf $GFWBLACKIP_TEMP
for domain in $(cat $GFWBLACK_CONF)
do
  echo "search $domain"
  cat $ADDRESS_TMP | grep "$domain" | awk -F/ '{print $3}' >> $GFWBLACKIP_TMP
done
cat $GFWBLACKIP_TMP $GFWBLACKIP_UPD $GFWBLACKIP_CONF | grep -v '^$' | sort -u >> $GFWBLACKIP_TEMP
md5sum -c -s $GFWBLACKIP_MD5
if [ "$?" == "0" ]; then
  logger -st "SmartDNS[$$]" "没有新的黑名单地址"
else
  rm -rf $GFWBLACKIP_CONF
  cp -rf $GFWBLACKIP_TEMP $GFWBLACKIP_CONF
  logger -st "SmartDNS[$$]" "黑名单地址更新成功"
fi
}

upchnwhiteip()
{
logger -st "SmartDNS[$$]" "更新白名单地址"
cp -rf $CHNWHITEIP_CONF $CHNWHITEIP_TEMP
md5sum $CHNWHITEIP_TEMP >> $CHNWHITEIP_MD5
rm -rf $CHNWHITEIP_TEMP
cat $ADDRESS_TMP | awk -F/ '{print $3}' | sort -u >> $CHNWHITEIP_TMP
for address in $(cat $GFWBLACKIP_TEMP)
do
  echo "delete $address"
  sed -i '/'$address'/d' $CHNWHITEIP_TMP
done
cat $CHNWHITEIP_TMP $CHNWHITEIP_CONF | grep -v '^$' | sort -u >> $CHNWHITEIP_TEMP
md5sum -c -s $CHNWHITEIP_MD5
if [ "$?" == "0" ]; then
  logger -st "SmartDNS[$$]" "没有新的白名单地址"
else
  rm -rf $CHNWHITEIP_CONF
  cp -rf $CHNWHITEIP_TEMP $CHNWHITEIP_CONF
  logger -st "SmartDNS[$$]" "白名单地址更新成功"
fi
}

address_update()
{
if [ "$sdns_address" = "1" ] || [ -e /tmp/smartdns_address.conf ]; then
  logger -st "SmartDNS[$$]" "更新域名地址"
  cp -rf $ADDRESS_CONF $ADDRESS_TEMP
  md5sum $ADDRESS_TEMP >> $ADDRESS_MD5
  rm -rf $ADDRESS_TEMP
  cat $ADDRESS_LOG | grep 'type: ' | awk '{printf("address /%s/%s\n", $7,$9, $1 )}' >> $ADDRESS_TMP
  cat $ADDRESS_TMP $ADDRESS_UPD $ADDRESS_CONF | grep -v '^$' | \
  grep -v "cdn" | grep -v "googlevideo.com" | \
  awk -F/ '!a[$2]++{print $0}' | sort >> $ADDRESS_TEMP
  md5sum -c -s $ADDRESS_MD5
  if [ "$?" == "0" ]; then
    logger -st "SmartDNS[$$]" "没有新的域名地址"
  else
    rm -rf $ADDRESS_CONF
    cp -rf $ADDRESS_TEMP $ADDRESS_CONF
    logger -st "SmartDNS[$$]" "域名地址更新成功"
  fi
  upgfwblackip
  upchnwhiteip
  rm -rf $ADDRESS_LOG
  rm -rf $ADDRESS_TEMP
  rm -rf $ADDRESS_TMP
  rm -rf $ADDRESS_MD5
  rm -rf $GFWBLACKIP_TEMP
  rm -rf $GFWBLACKIP_TMP
  rm -rf $GFWBLACKIP_MD5
  rm -rf $CHNWHITEIP_TEMP
  rm -rf $CHNWHITEIP_TMP
  rm -rf $CHNWHITEIP_MD5
fi
}

gensdnsconf()
{
logger -st "SmartDNS[$$]" "创建配置文件"
rm -rf /tmp/SmartDNS
mkdir -p /tmp/SmartDNS
touch $SMARTDNS_CONF
echo "conf-file $CUSTOM_CONF" >> $SMARTDNS_CONF
if [ "$sdns_address" = "1" ]; then
  !(cat "$CRON_CONF" | grep -q "smartdns.sh") && \
  echo "33 3 * * * /usr/bin/smartdns.sh update 2>/dev/null" >> $CRON_CONF && restart_crond
  echo "conf-file $ADDRESS_CONF" >> $SMARTDNS_CONF
fi
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
gensdnsmasqup
gensdnschngfw
gensdnswblist
gensdnsserver
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
cat >> $SMARTDNS_CONF << EOF
audit-enable yes
audit-SOA no
audit-size 4m
audit-file $ADDRESS_LOG
audit-num 0
log-level $sdns_logl
log-file /tmp/smartdns.log
log-size 1m
log-num 0
EOF
}

sdns_restore()
{
killall dnsmasq
sed -i 's/^min-cache-ttl=/#min-cache-ttl=/g' $DNSQ_CONF
sed -i 's/^conf-dir=/#conf-dir=/g' $DNSQ_CONF
sed -i '/^no-resolv/d' $DNSQ_CONF
sed -i '/^server=127.0.0.1/d' $DNSQ_CONF
sed -i '/^server=::1/d' $DNSQ_CONF
sed -i '/^### SmartDNS/d' $DNSQ_CONF
sed -i '/^port=5353/d' $DNSQ_CONF
sed -i '/^servers-file/d' $DNSM_CONF
echo "servers-file=/tmp/dnsmasq.servers" >> $DNSM_CONF
dnsmasq
rm -rf /tmp/SmartDNS
rm -rf /tmp/smartdns.log
rm -rf /tmp/smartdns.log*.gz
rm -rf /tmp/smartdns_address.log*.gz
sed -i '/smartdns.sh/d' $CRON_CONF && restart_crond
}

update_restore()
{
rm -rf /tmp/GFWblack.conf
rm -rf /tmp/GFWblackip.conf
rm -rf /tmp/smartdns_address.conf
rm -rf /tmp/SmartDNSupdate
}

start_sdns()
{
ulimit -n 65536
logger -st "SmartDNS[$$]" "开始启动" && \
killall dnsmasq && gensdnsconf && dnsmasq && \
$(nohup $SMARTDNS_BIN -f -c $SMARTDNS_CONF &>/dev/null &) && \
sleep 1 && logger -st "SmartDNS[$(pidof smartdns)]" "成功启动"
}

stop_sdns()
{
killall -q -9 smartdns && logger -st "SmartDNS[$$]" "关闭程序"
[ -e $SMARTDNS_CONF ] && logger -st "SmartDNS[$$]" "清理配置" && sdns_restore
!(pidof smartdns &>/dev/null) && logger -st "SmartDNS[$$]" "程序已经关闭"
}

case "$1" in
start)
  sdns_check
  start_sdns
  ;;
stop)
  stop_sdns
  ;;
restart)
  stop_sdns
  sdns_check
  start_sdns
  ;;
update)
  sdns_check
  echo "SmartDNSupdate" > /tmp/SmartDNSupdate
  [ "$sdns_enable" = "1" ] || mkdir -p /tmp/SmartDNS
  upgfwblack && upgfwdnsmq && address_update
  [ "$sdns_enable" = "0" ] || stop_sdns
  [ "$sdns_enable" = "0" ] || start_sdns
  [ "$sdns_enable" = "1" ] || rm -rf /tmp/SmartDNS
  mtd_storage.sh save &>/dev/null && update_restore
  ;;
*)
  echo "Usage: $0 { start | stop | restart | update }"
  exit 1
  ;;
esac
