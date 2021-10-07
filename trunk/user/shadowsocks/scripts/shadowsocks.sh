#!/bin/sh

ss_bin="/usr/bin/ss-orig-redir"
ssr_bin="/usr/bin/ssr-redir"
trojan_bin="/usr/bin/trojan"
use_bin="ss-redir"
use_link="/var/ss-redir"
use_log_file="/tmp/ss-redir.log"
use_json_file="/tmp/ss-redir.json"

statusfile="/tmp/ss-watchcat"
CRON_CONF="/etc/storage/cron/crontabs/admin"

ss_type=$(nvram get ss_type)
ssp_type=${ss_type:0} # 0=ss 1=ssr 2=trojan

ss_server=$(nvram get ss_server)
ss_server_sni=$(nvram get ss_server_sni)
ss_server_port=$(nvram get ss_server_port)
ss_local_port=$(nvram get ss_local_port)
ss_password=$(nvram get ss_key)
ss_method=$(nvram get ss_method)
ss_timeout=$(nvram get ss_timeout)
ss_protocol=$(nvram get ss_protocol)
ss_proto_param=$(nvram get ss_proto_param)
ss_obfs=$(nvram get ss_obfs)
ss_obfs_param=$(nvram get ss_obfs_param)
ss_mtu=$(nvram get ss_mtu)

ss_mode=$(nvram get ss_mode) # 0=global 1=chnroute 2=gfwlist
ss_udp=$(nvram get ss_udp)

GFWBLACK_CONF="/etc/storage/GFWblack.conf"
GFWLIST_CONF="/etc/storage/gfwlist/dnsmasq_gfwlist.conf"
GFWLIST_TEMP="/tmp/dnsmasq_gfwlist.conf"
GFWLIST_MD5="/tmp/dnsmasq_gfwlist.md5"
DNSQ_CONF="/etc/storage/dnsmasq/dnsmasq.conf"

[ "$ssp_type" = "0" ] && bin_type="SS" && ln -sf $ss_bin $use_link
[ "$ssp_type" = "1" ] && bin_type="SSR" && ln -sf $ssr_bin $use_link
[ "$ssp_type" = "2" ] && [ -x "$trojan_bin" ] && bin_type="Trojan" && ln -sf $trojan_bin $use_link
[ "$bin_type" != "" ] || logger -st "SSP[$$]$bin_type" "找不到可执行文件!"

gen_dns_conf()
{
if [ "$(nvram get sdns_enable)" = "0" ]; then
  logger -st "SSP[$$]$bin_type" "创建域名解析规则"
  if [ -x /usr/bin/dns-forwarder.sh ] && [ "$(nvram get dns_forwarder_enable)" = "1" ]; then
    DNS_APP="dnsForwarder" && DNS_PORT=$(nvram get dns_forwarder_port)
  elif [ "$(nvram get ss-tunnel_enable)" = "1" ]; then
    DNS_APP="ssTunnel" && DNS_PORT=$(nvram get ss-tunnel_local_port)
  else
    DNS_APP="dnsmasq" && DNS_PORT="53"
  fi
  ADDR_PORT="127.0.0.1#$DNS_PORT"
  cp -rf $GFWLIST_CONF $GFWLIST_TEMP
  md5sum $GFWLIST_TEMP >> $GFWLIST_MD5
  rm -rf $GFWLIST_TEMP
  grep -v '^#' $GFWBLACK_CONF | grep -v '^$' | awk '{printf("ipset=/%s/gfwlist\n", $1, $1 )}' >> $GFWLIST_TEMP
  md5sum -c -s $GFWLIST_MD5
  if [ "$?" != "0" ]; then
    rm -rf $GFWLIST_CONF
    cp -rf $GFWLIST_TEMP $GFWLIST_CONF
  fi
  rm -rf $GFWLIST_TEMP
  rm -rf $GFWLIST_MD5
  killall dnsmasq && \
  grep -v '^#' $GFWBLACK_CONF | grep -v '^$' | awk '{printf("server=/%s/'$ADDR_PORT'\n", $1, $1 )}' > /tmp/dnsmasq.servers && \
  sed -i 's/### gfwlist related.*/### gfwlist related resolve by '$DNS_APP' '$ADDR_PORT'/g' $DNSQ_CONF && \
  sed -i 's/^#min-cache-ttl=/min-cache-ttl=/g' $DNSQ_CONF && \
  sed -i 's/^#conf-dir=/conf-dir=/g' $DNSQ_CONF && \
  sleep 1 && dnsmasq
fi
}

gen_json_file()
{
logger -st "SSP[$$]$bin_type" "创建配置文件"
if [ "$ssp_type" = "0" ]; then
	cat > "$use_json_file" << EOF
{
    "server": "$ss_server",
    "server_port": $ss_server_port,
    "password": "$ss_password",
    "method": "$ss_method",
    "timeout": $ss_timeout,
    "local_address": "0.0.0.0",
    "local_port": $ss_local_port,
    "mtu": $ss_mtu
}

EOF
elif [ "$ssp_type" = "1" ]; then
	cat > "$use_json_file" << EOF
{
    "server": "$ss_server",
    "server_port": $ss_server_port,
    "password": "$ss_password",
    "method": "$ss_method",
    "timeout": $ss_timeout,
    "protocol": "$ss_protocol",
    "protocol_param": "$ss_proto_param",
    "obfs": "$ss_obfs",
    "obfs_param": "$ss_obfs_param",
    "local_address": "0.0.0.0",
    "local_port": $ss_local_port,
    "mtu": $ss_mtu
}

EOF
elif [ "$ssp_type" = "2" ]; then
  if [ "$ss_server_sni" = "" ]; then
    VHN="false"
  else
    VHN="true"
  fi
	cat > "$use_json_file" << EOF
{
    "run_type": "nat",
    "local_addr": "0.0.0.0",
    "local_port": $ss_local_port,
    "remote_addr": "$ss_server",
    "remote_port": $ss_server_port,
    "password": [
        "$ss_password"
    ],
    "log_level": 2,
    "ssl": {
        "verify": false,
        "verify_hostname": $VHN,
        "sni": "$ss_server_sni"
    }
}

EOF
fi
}

gfw_list()
{
if [ "$ss_mode" = "0" ]; then # global
  echo ""
elif [ "$ss_mode" = "1" ]; then # chnroute
  echo ""
elif [ "$ss_mode" = "2" ]; then # gfwlist
  echo " -g /etc/storage/GFWblackip.conf"
fi
}

chn_list()
{
if [ "$ss_mode" = "0" ]; then # global
  echo ""
elif [ "$ss_mode" = "1" ]; then # chnroute
  echo " -c /etc/storage/chinadns/chnroute.txt"
elif [ "$ss_mode" = "2" ]; then # gfwlist
  echo ""
fi
}

exc_list()
{
if [ "$ss_mode" = "0" ]; then # global
  echo ""
elif [ "$ss_mode" = "1" ]; then # chnroute
  echo ""
elif [ "$ss_mode" = "2" ]; then # gfwlist
  echo " -e /etc/storage/ssprules/allroute.txt"
fi
}

agent_mode()
{
if [ "$ss_udp" = "0" ]; then
  echo " -t"
elif [ "$ss_udp" = "1" ]; then
  echo " -m"
fi
}

start_rules()
{
logger -st "SSP[$$]$bin_type" "开启透明代理"
ss-rules\
 -s "$ss_server"\
 -i "$ss_local_port"\
$(gfw_list)\
$(chn_list)\
$(exc_list)\
$(agent_mode)
}

udp_ext()
{
if [ "$ss_udp" = "1" ]; then
  if [ "$ssp_type" = "0" ] || [ "$ssp_type" = "1" ]; then
    echo " -u"
  fi
fi
}

start_redir()
{
logger -st "SSP[$$]$bin_type" "启动代理"
nohup $use_bin -c $use_json_file\
$(udp_ext) &>$use_log_file &
}

stop_watchcat()
{
killall -q -9 ss-watchcat.sh && rm -rf $statusfile
sed -i '/ss-watchcat.sh/d' $CRON_CONF && restart_crond
}

stop_ssp()
{
!(cat "$statusfile" 2>/dev/null | grep -q "restart_ssp") && stop_watchcat
killall -q -9 $use_bin && logger -st "SSP[$$]$bin_type" "关闭程序"
if $(iptables-save -c | grep -q "SSP_") || $(ipset list -n | grep -q "gfwlist"); then
  logger -st "SSP[$$]$bin_type" "关闭透明代理" && ss-rules -f
fi
[ -e $use_json_file ] && logger -st "SSP[$$]$bin_type" "清除配置文件" && rm -rf $use_json_file
if [ "$(nvram get sdns_enable)" = "0" ]; then
  logger -st "SSP[$$]$bin_type" "清除域名解析规则"
  killall dnsmasq && \
  echo "" > /tmp/dnsmasq.servers && \
  sed -i 's/^min-cache-ttl=/#min-cache-ttl=/g' $DNSQ_CONF && \
  sed -i 's/^conf-dir=/#conf-dir=/g' $DNSQ_CONF && \
  dnsmasq
fi
!(pidof $use_bin &>/dev/null) && \
!(iptables-save -c | grep -q "SSP_") && !(ipset list -n | grep -q "gfwlist") && \
logger -st "SSP[$$]$bin_type" "程序已经关闭"
}

start_ssp()
{
ulimit -n 65536
!(cat "$statusfile" 2>/dev/null | grep -q "restart_ssp") && stop_watchcat
[ $(stat -c %s /etc/storage/chinadns/chnroute.txt) -lt 1000 ] && [ ! -e /tmp/chnroute.txt ] && \
rm -rf /etc/storage/chinadns/chnroute.txt && tar jxf /etc_ro/chnroute.bz2 -C /etc/storage/chinadns
[ $(stat -c %s /etc/storage/ssprules/allroute.txt) -lt 1000 ] && [ ! -e /tmp/allroute.txt ] && \
rm -rf /etc/storage/ssprules/allroute.txt && tar jxf /etc_ro/allroute.bz2 -C /etc/storage/ssprules
logger -st "SSP[$$]$bin_type" "开始启动" && touch $use_log_file && \
gen_dns_conf && gen_json_file && start_rules && start_redir || stop_ssp
pidof ss-watchcat.sh &>/dev/null || /usr/bin/ss-watchcat.sh
[ "$?" = "0" ] && sleep 1 && pidof $use_bin &>/dev/null && \
$(iptables-save -c | grep -q "SSP_") && $(ipset list -n | grep -q "gfwlist") && \
logger -st "SSP[$(pidof $use_bin)]$bin_type" "成功启动" && \
!(cat "$CRON_CONF" 2>/dev/null | grep -q "ss-watchcat.sh") && \
echo "*/5 * * * * /usr/bin/ss-watchcat.sh 2>/dev/null" >> $CRON_CONF && restart_crond
}

case "$1" in
start)
  start_ssp
  ;;
stop)
  stop_ssp
  ;;
restart)
  stop_ssp
  start_ssp
  ;;
*)
  echo "Usage: $0 { start | stop | restart }"
  exit 1
  ;;
esac
