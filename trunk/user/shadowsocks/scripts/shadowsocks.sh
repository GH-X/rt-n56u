#!/bin/sh

ss_bin="/usr/bin/ss-orig-redir"
ssr_bin="/usr/bin/ssr-redir"
trojan_bin="/usr/bin/trojan"
use_bin="ss-redir"
use_link="/var/ss-redir"
use_log_file="/tmp/ss-redir.log"
use_json_file="/tmp/ss-redir.json"

statusfile="/tmp/sspstatus.tmp"
CRON_CONF="/etc/storage/cron/crontabs/$(nvram get http_username)"

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
DNSM_CONF="/etc/dnsmasq.conf"
DNSQ_CONF="/etc/storage/dnsmasq/dnsmasq.conf"

[ "$ssp_type" = "0" ] && bin_type="SS" && ln -sf $ss_bin $use_link
[ "$ssp_type" = "1" ] && bin_type="SSR" && ln -sf $ssr_bin $use_link
[ "$ssp_type" = "2" ] && [ -x "$trojan_bin" ] && bin_type="Trojan" && ln -sf $trojan_bin $use_link
[ "$bin_type" != "" ] || logger -st "SSP[$$]WARNING" "找不到代理进程可执行文件!"

gen_dns_conf()
{
if [ "$(nvram get sdns_enable)" = "0" ] || [ "$(nvram get sdnse_enable)" = "0" ] || [ "$(nvram get sdnse_domain_gfw)" = "0" ]; then
  logger -st "SSP[$$]$bin_type" "创建解析规则"
  if [ -x /usr/bin/dns-forwarder.sh ] && [ "$(nvram get dns_forwarder_enable)" = "1" ]; then
    DNS_APP="dnsForwarder" && DNS_PORT=$(nvram get dns_forwarder_port)
  elif [ "$(nvram get ss-tunnel_enable)" = "1" ] && [ "$ssp_type" -lt "2" ]; then
    DNS_APP="Tunnel" && DNS_PORT=$(nvram get ss-tunnel_local_port)
  else
    DNS_APP="dnsmasq" && DNS_PORT="53" && logger -st "SSP[$$]WARNING" "请正确设置DNS隧道和DNS服务!"
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
  killall -q -9 dnsmasq && \
  grep -v '^#' $GFWBLACK_CONF | grep -v '^$' | awk '{printf("server=/%s/'$ADDR_PORT'\n", $1, $1 )}' > /tmp/dnsmasq.servers && \
  sed -i '/^servers-file/d' $DNSM_CONF && echo "servers-file=/tmp/dnsmasq.servers" >> $DNSM_CONF && \
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
  echo " -g /etc/storage/GFWblackip.conf"
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
  echo " -c /etc/storage/chinadns/chnroute.txt"
fi
}

agent_mode()
{
if [ "$ss_mode" = "0" ]; then # global
  echo " -a 0"
elif [ "$ss_mode" = "1" ]; then # chnroute
  echo " -a 1"
elif [ "$ss_mode" = "2" ]; then # gfwlist
  echo " -a 2"
fi
}

agent_pact()
{
if [ "$ss_udp" = "0" ]; then
  echo " -t"
elif [ "$ss_udp" = "1" ]; then
  echo " -m"
fi
}

stop_rules()
{
killall -q -9 ss-rules
logger -st "SSP[$$]$bin_type" "关闭透明代理" && ss-rules -f
}

start_rules()
{
logger -st "SSP[$$]$bin_type" "开启透明代理" && \
ss-rules\
 -s "$ss_server"\
 -i "$ss_local_port"\
$(gfw_list)\
$(chn_list)\
$(agent_mode)\
$(agent_pact)
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
logger -st "SSP[$$]$bin_type" "启动代理进程" && touch $use_log_file && \
nohup $use_bin -c $use_json_file $(udp_ext) &>$use_log_file &
return 0
}

stop_watchcat()
{
(!(cat "$statusfile" 2>/dev/null | grep -q 'watchcat_stop_ssp') && \
sed -i '/ss-watchcat.sh/d' $CRON_CONF && restart_crond)&
(!(cat "$statusfile" 2>/dev/null | grep -q 'watchcat_stop_ssp') && rm -rf $statusfile)&
(killall -q -9 ss-watchcat.sh)&
wait
return 0
}

stop_ssp()
{
([ "$(nvram get ss_enable)" = "0" ] && echo "main_stop_ssp" > $statusfile
$(cat "$statusfile" 2>/dev/null | grep -q "watchcat_restart_ssp_") || stop_watchcat)&
(killall -q -9 $use_bin && logger -st "SSP[$$]$bin_type" "关闭代理进程")&
($(cat "$statusfile" 2>/dev/null | grep -q 'watchcat_restart_ssp_link') || stop_rules)&
([ -e $use_json_file ] && logger -st "SSP[$$]$bin_type" "清除配置文件" && rm -rf $use_json_file)&
(if [ "$(nvram get sdns_enable)" = "0" ]; then
  logger -st "SSP[$$]$bin_type" "清除解析规则"
  killall -q -9 dnsmasq && \
  echo "" > /tmp/dnsmasq.servers && \
  sed -i 's/^min-cache-ttl=/#min-cache-ttl=/g' $DNSQ_CONF && \
  sed -i 's/^conf-dir=/#conf-dir=/g' $DNSQ_CONF && \
  dnsmasq
fi)&
(cat /tmp/amsallexp.set /tmp/amsallexp.txt 2>/dev/null | sort -u >> /tmp/amsallexp.tmp && \
rm -rf /tmp/amsallexp.set && rm -rf /tmp/amsallexp.txt && \
mv -f /tmp/amsallexp.tmp /tmp/amsallexp.txt)&
wait
!(iptables-save -c | grep -q "SSP_") && !(ipset list -n | grep -q 'gfwlist') && \
logger -st "SSP[$$]$bin_type" "透明代理已经关闭"
!(pidof $use_bin &>/dev/null) && \
logger -st "SSP[$$]$bin_type" "代理进程已经关闭" || logger -st "SSP[$$]WARNING" "代理进程关闭失败!"
[ "$(nvram get ss_enable)" = "0" ] && exit 0 || return 0
}

check_start_ssp()
{
[ "$?" = "0" ] && sleep 1 && pidof $use_bin &>/dev/null && \
$(iptables-save -c | grep -q "SSP_") && $(ipset list -n | grep -q 'gfwlist') && \
logger -st "SSP[$(pidof $use_bin)]$bin_type" "${STA_LOG:=成功启动}" && \
!(cat "$CRON_CONF" 2>/dev/null | grep -q "ss-watchcat.sh") && \
echo "*/1 * * * * nohup /usr/bin/ss-watchcat.sh 2>/dev/null &" >> $CRON_CONF && restart_crond
return 0
}

start_ssp()
{
ulimit -n 65536
logger -st "SSP[$$]$bin_type" "开始启动"
$(cat "$statusfile" 2>/dev/null | grep -q "watchcat_restart_ssp_") || stop_watchcat
[ -L /etc/storage/chinadns/chnroute.txt ] && [ ! -e /tmp/chnroute.txt ] && \
rm -rf /etc/storage/chinadns/chnroute.txt && tar jxf /etc_ro/chnroute.bz2 -C /etc/storage/chinadns
$(cat "$statusfile" 2>/dev/null | grep -q 'watchcat_restart_ssp_link') || start_rules || stop_ssp
gen_dns_conf && gen_json_file && start_redir || stop_ssp
pidof ss-watchcat.sh &>/dev/null && STA_LOG="重启完成" || /usr/bin/ss-watchcat.sh
check_start_ssp
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
