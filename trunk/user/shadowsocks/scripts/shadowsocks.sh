#!/bin/sh

ss_redir_bin="/usr/bin/ss-orig-redir"
ssr_redir_bin="/usr/bin/ssr-redir"
redir_bin="ss-redir"
redir_link="/var/ss-redir"
#/usr/bin/ss-redir -> /var/ss-redir -> /usr/bin/ss-orig-redir or /usr/bin/ssr-redir
ss_tunnel_bin="/usr/bin/ss-orig-tunnel"
ssr_tunnel_bin="/usr/bin/ssr-local"
tunnel_bin="ss-local"
tunnel_link="/var/ss-tunnel"
#/usr/bin/ss-local -> /var/ss-tunnel -> /usr/bin/ss-orig-tunnel or /usr/bin/ssr-local

CONF_DIR="/tmp/SSP"
redir_log_file="/tmp/ss-redir.log"
issjfinfor="$CONF_DIR/issjfinfor"
statusfile="$CONF_DIR/statusfile"
countslink="$CONF_DIR/countslink"
countsrest="$CONF_DIR/countsrest"
CRON_CONF="/etc/storage/cron/crontabs/$(nvram get http_username)"

ss_type=$(nvram get ss_type)
ssp_type=${ss_type:0} # 0=ss 1=ssr 2=trojan 9=auto

ss_mode=$(nvram get ss_mode) # 0=global 1=chnroute 2=gfwlist
ss_udp=$(nvram get ss_udp)

ss_local_port=$(nvram get ss_local_port)
ss_mtu=$(nvram get ss_mtu)
ss_tunnel_mtu=$(nvram get ss-tunnel_mtu)
ss_timeout=$(nvram get ss_timeout)

nodesnum=$(nvram get ss_server_num_x)
nodenewn=$(expr $nodesnum - 1)
nodenewa=$(nvram get ss_server_addr_x$nodenewn)
nodenewp=$(nvram get ss_server_port_x$nodenewn)

ss_dns_p=$(nvram get ss_dns_local_port)
ss_dns_s=$(nvram get ss_dns_remote_server)
dnsfsmip=$(echo "$ss_dns_s" | awk -F: '{print $1}')
dnstcpsp=$(echo "$ss_dns_s" | sed 's/:/~/g')

dnsfslsp="127.0.0.1#$ss_dns_p"
dnsgfwdt="/etc/storage/gfwlist/gfwlist_domain.txt"
dnsgfwdc="$CONF_DIR/gfwlist/dnsmasq.conf"
dnsmasqc="/etc/storage/dnsmasq/dnsmasq.conf"

[ "$ssp_type" = "0" ] && bin_type="SS"
[ "$ssp_type" = "1" ] && bin_type="SSR"
[ "$ssp_type" = "2" ] && bin_type="Trojan"
[ "$ssp_type" = "9" ] && bin_type="Auto"
[ "$bin_type" = "Trojan" -o "$bin_type" = "Auto" ] && [ "$(nvram get ss-tunnel_enable)" = "1" ] && nvram set ss-tunnel_enable=0
[ "$(nvram get dns_forwarder_enable)" = "1" ] && [ "$(nvram get ss-tunnel_enable)" = "1" ] && nvram set ss-tunnel_enable=0
[ ! -d "$CONF_DIR/gfwlist" ] && mkdir -p "$CONF_DIR/gfwlist"
[ -e /tmp/trojan ] && chmod +x /tmp/trojan && trojan_bin="/tmp/trojan" || trojan_bin="/usr/bin/trojan"
[ -L /etc/storage/chinadns/chnroute.txt ] && [ ! -e /tmp/chnroute.txt ] && \
rm -rf /etc/storage/chinadns/chnroute.txt && tar jxf /etc_ro/chnroute.bz2 -C /etc/storage/chinadns

del_json_file()
{
logger -st "SSP[$$]$bin_type" "清除配置文件"
rm -rf $CONF_DIR/*.json
rm -rf $CONF_DIR/*-jsonlist
return 0
}

turn_json_file()
{
[ "$bin_type" = "Auto" ] || \
$(cat $CONF_DIR/$bin_type-jsonlist 2>/dev/null | grep -q "$bin_type-redir") || return 1
[ "$(cat $CONF_DIR/Auto-jsonlist 2>/dev/null | wc -l)" = "$nodesnum" ] || return 1
$(cat $CONF_DIR/Auto-jsonlist 2>/dev/null | grep -q "$nodenewa#$nodenewp#") || return 1
[ "$(cat $CONF_DIR/$bin_type-jsonlist 2>/dev/null | wc -l)" != "1" ] || return 0
!(cat "$statusfile" 2>/dev/null | grep -q 'watchcat_restart_ssp_rule') || return 0
logger -st "SSP[$$]$bin_type" "更换配置文件"
turn_temp=$(tail -n 1 $CONF_DIR/$bin_type-jsonlist)
turn_json=${turn_temp:0}
sed -i '/'$turn_json'/d' $CONF_DIR/$bin_type-jsonlist
sed -i '1i\'$turn_json'' $CONF_DIR/$bin_type-jsonlist
return 0
}

gen_json_file()
{
turn_json_file || del_json_file
if [ ! -e "$CONF_DIR/Auto-jsonlist" ]; then
  logger -st "SSP[$$]$bin_type" "创建配置文件"
  for i in $(seq 1 $nodesnum); do
    j=$(expr $i - 1)
    node_type=$(nvram get ss_server_type_x$j)
    [ "$node_type" = "0" ] && server_type="SS"
    [ "$node_type" = "1" ] && server_type="SSR"
    [ "$node_type" = "2" ] && server_type="Trojan"
    if [ "$server_type" = "SS" ]; then
      server_addr=$(nvram get ss_server_addr_x$j)
      server_port=$(nvram get ss_server_port_x$j)
      server_key=$(nvram get ss_server_key_x$j)
      ss_method=$(nvram get ss_method_x$j)
      r_json_file="$i-$server_type-redir.json"
      t_json_file="$i-$server_type-tunnel.json"
      echo "$server_addr#$server_port#$r_json_file#$t_json_file" >> $CONF_DIR/SS-jsonlist
      echo "$server_addr#$server_port#$r_json_file#$t_json_file" >> $CONF_DIR/Auto-jsonlist
	    cat > "$CONF_DIR/$r_json_file" << EOF
{
    "server": "$server_addr",
    "server_port": $server_port,
    "password": "$server_key",
    "method": "$ss_method",
    "timeout": $ss_timeout,
    "local_address": "0.0.0.0",
    "local_port": $ss_local_port,
    "mtu": $ss_mtu
}

EOF
      cat > "$CONF_DIR/$t_json_file" << EOF
{
    "server": "$server_addr",
    "server_port": $server_port,
    "password": "$server_key",
    "method": "$ss_method",
    "timeout": $ss_timeout,
    "local_address": "0.0.0.0",
    "local_port": $ss_dns_p,
    "mtu": $ss_tunnel_mtu
}

EOF
    elif [ "$server_type" = "SSR" ]; then
      server_addr=$(nvram get ss_server_addr_x$j)
      server_port=$(nvram get ss_server_port_x$j)
      server_key=$(nvram get ss_server_key_x$j)
      ss_method=$(nvram get ss_method_x$j)
      ss_protocol=$(nvram get ss_protocol_x$j)
      ss_proto_param=$(nvram get ss_proto_param_x$j)
      ss_obfs=$(nvram get ss_obfs_x$j)
      ss_obfs_param=$(nvram get ss_obfs_param_x$j)
      r_json_file="$i-$server_type-redir.json"
      t_json_file="$i-$server_type-tunnel.json"
      echo "$server_addr#$server_port#$r_json_file#$t_json_file" >> $CONF_DIR/SSR-jsonlist
      echo "$server_addr#$server_port#$r_json_file#$t_json_file" >> $CONF_DIR/Auto-jsonlist
	    cat > "$CONF_DIR/$r_json_file" << EOF
{
    "server": "$server_addr",
    "server_port": $server_port,
    "password": "$server_key",
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
      cat > "$CONF_DIR/$t_json_file" <<EOF
{
    "server": "$server_addr",
    "server_port": $server_port,
    "password": "$server_key",
    "method": "$ss_method",
    "timeout": $ss_timeout,
    "protocol": "$ss_protocol",
    "protocol_param": "$ss_proto_param",
    "obfs": "$ss_obfs",
    "obfs_param": "$ss_obfs_param",
    "local_address": "0.0.0.0",
    "local_port": $ss_dns_p,
    "mtu": $ss_tunnel_mtu
}

EOF
    elif [ "$server_type" = "Trojan" ]; then
      server_addr=$(nvram get ss_server_addr_x$j)
      server_port=$(nvram get ss_server_port_x$j)
      server_key=$(nvram get ss_server_key_x$j)
      server_sni=$(nvram get ss_server_sni_x$j)
      if [ "$server_sni" = "" ]; then
        verifyhostname="false"
      else
        verifyhostname="true"
      fi
      r_json_file="$i-$server_type-redir.json"
      echo "$server_addr#$server_port#$r_json_file#null" >> $CONF_DIR/Trojan-jsonlist
      echo "$server_addr#$server_port#$r_json_file#null" >> $CONF_DIR/Auto-jsonlist
      cat > "$CONF_DIR/$r_json_file" << EOF
{
    "run_type": "nat",
    "local_addr": "0.0.0.0",
    "local_port": $ss_local_port,
    "remote_addr": "$server_addr",
    "remote_port": $server_port,
    "password": [
        "$server_key"
    ],
    "log_level": 2,
    "ssl": {
        "verify": false,
        "verify_hostname": $verifyhostname,
        "sni": "$server_sni"
    }
}

EOF
    fi
  done
fi
[ "$bin_type" = "Auto" ] || \
$(cat $CONF_DIR/$bin_type-jsonlist 2>/dev/null | grep -q "$bin_type-redir") || return 1
ssp_server_addr=$(tail -n 1 $CONF_DIR/$bin_type-jsonlist | awk -F# '{print $1}')
ssp_server_port=$(tail -n 1 $CONF_DIR/$bin_type-jsonlist | awk -F# '{print $2}')
redir_json_file=$(tail -n 1 $CONF_DIR/$bin_type-jsonlist | awk -F# '{print $3}')
tunnel_json_file=$(tail -n 1 $CONF_DIR/$bin_type-jsonlist | awk -F# '{print $4}')
ssp_server_type=$(echo "$redir_json_file" | awk -F- '{print $2}')
[ "$ssp_server_type" = "SS" ] && ln -sf $ss_redir_bin $redir_link && ln -sf $ss_tunnel_bin $tunnel_link
[ "$ssp_server_type" = "SSR" ] && ln -sf $ssr_redir_bin $redir_link && ln -sf $ssr_tunnel_bin $tunnel_link
[ "$ssp_server_type" = "Trojan" ] && ln -sf $trojan_bin $redir_link
return 0
}

del_dns_conf()
{
logger -st "SSP[$$]$bin_type" "清除解析规则"
sed -i 's/^### gfwlist related.*/### gfwlist related resolve/g' $dnsmasqc
sed -i 's/^min-cache-ttl=/#min-cache-ttl=/g' $dnsmasqc
sed -i 's/^conf-dir=/#conf-dir=/g' $dnsmasqc
sed -i 's:^gfwlist='$dnsgfwdt':#gfwlist='$dnsgfwdt':g' $dnsmasqc
rm -rf $dnsgfwdc
killall -q -9 dns-forwarder
killall -q -9 $tunnel_bin
restart_dhcpd
}

get_dns_conf()
{
[ "$1" != "dnsmasq-tcp" ] && grep -v '^#' $dnsgfwdt | grep -v '^$' | awk '{printf("server=/%s/'$dnsfslsp'\n", $1, $1 )}' >> $dnsgfwdc
[ "$1" != "dnsmasq-tcp" ] && grep -v '^#' $dnsgfwdt | grep -v '^$' | awk '{printf("ipset=/%s/gfwlist\n", $1, $1 )}' >> $dnsgfwdc
sed -i 's/^### gfwlist related.*/### gfwlist related resolve by '$1' '$2'/g' $dnsmasqc
[ "$1" != "dnsmasq-tcp" ] && sed -i 's/^#min-cache-ttl=/min-cache-ttl=/g' $dnsmasqc
[ "$1" != "dnsmasq-tcp" ] && sed -i 's/^#conf-dir=/conf-dir=/g' $dnsmasqc
[ "$1" == "dnsmasq-tcp" ] && sed -i 's:^#gfwlist='$dnsgfwdt'.*:gfwlist='$dnsgfwdt'@'$dnstcpsp':g' $dnsmasqc
return 0
}

gen_dns_conf()
{
logger -st "SSP[$$]$bin_type" "创建解析规则"
if [ "$(nvram get dns_forwarder_enable)" = "1" ]; then
  get_dns_conf dns-forwarder "$dnsfslsp"
  start-stop-daemon -S -b -x dns-forwarder -- -b "0.0.0.0" -p "$ss_dns_p" -s "$ss_dns_s"
elif [ "$(nvram get ss-tunnel_enable)" = "1" ]; then
  get_dns_conf ss-tunnel "$dnsfslsp"
  sh -c "$tunnel_bin -u -c $CONF_DIR/$tunnel_json_file -L $ss_dns_s &"
else
  get_dns_conf dnsmasq-tcp "$dnstcpsp"
fi
restart_dhcpd
}

gfw_list()
{
if [ "$ss_mode" = "0" ]; then # global
  echo ""
elif [ "$ss_mode" = "1" ]; then # chnroute
  echo " -g $CONF_DIR/GFWblackip.conf"
elif [ "$ss_mode" = "2" ]; then # gfwlist
  echo " -g $CONF_DIR/GFWblackip.conf"
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

chnexp_list()
{
if [ "$ss_mode" = "0" ]; then # global
  echo ""
elif [ "$ss_mode" = "1" ]; then # chnroute
  echo " -e $CONF_DIR/CHNwhiteip.conf"
elif [ "$ss_mode" = "2" ]; then # gfwlist
  echo " -e $CONF_DIR/CHNwhiteip.conf"
fi
}

black_ip()
{
echo " -b $dnsfsmip"
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

udp_ext()
{
if [ "$ss_udp" = "1" ]; then
  if [ "$ssp_type" = "0" ] || [ "$ssp_type" = "1" ]; then
    echo " -u"
  fi
fi
}

stop_rules()
{
killall -q -9 ss-rules
logger -st "SSP[$$]$bin_type" "关闭透明代理" && ss-rules -f && restart_firewall && \
!(iptables-save -c | grep -q "SSP_") && !(ipset list -n | grep -q 'gfwlist') && \
logger -st "SSP[$$]$bin_type" "透明代理已经关闭"
}

start_rules()
{
logger -st "SSP[$$]$bin_type" "开启透明代理" && \
ss-rules\
 -s "$ssp_server_addr"\
 -i "$ss_local_port"\
$(gfw_list)\
$(chn_list)\
$(chnexp_list)\
$(black_ip)\
$(agent_mode)\
$(agent_pact)
}

stop_redir()
{
killall -q -9 $redir_bin && logger -st "SSP[$$]$bin_type" "关闭代理进程" && sleep 1 && \
!(pidof $redir_bin &>/dev/null) && logger -st "SSP[$$]$bin_type" "代理进程已经关闭"
return 0
}

start_redir()
{
logger -st "SSP[$$]$bin_type" "启动代理进程" && \
nohup $redir_bin -c $CONF_DIR/$redir_json_file $(udp_ext) &>$redir_log_file &
$(sleep 1 && pidof $redir_bin &>/dev/null) || $(sleep 1 && pidof $redir_bin &>/dev/null)
return $?
}

stop_watchcat()
{
(sed -i '/ss-watchcat.sh/d' $CRON_CONF && restart_crond)&
(killall -q -9 ss-watchcat.sh)&
(rm -rf $statusfile
rm -rf $countslink
rm -rf $countsrest
rm -rf $issjfinfor)&
wait
return 0
}

ncron()
{
!(cat "$CRON_CONF" 2>/dev/null | grep -q "ss-watchcat.sh") && \
echo "*/$1 * * * * nohup /usr/bin/ss-watchcat.sh 2>/dev/null &" >> $CRON_CONF || return 1
}

dcron()
{
$(cat "$CRON_CONF" 2>/dev/null | grep "ss-watchcat.sh" | grep -v -q "/$1") && \
sed -i '/ss-watchcat.sh/d' $CRON_CONF && \
echo "*/$1 * * * * nohup /usr/bin/ss-watchcat.sh 2>/dev/null &" >> $CRON_CONF || return 1
}

scron()
{
ncron $1 || dcron $1
[ "$?" = "0" ] && restart_crond
return 0
}

stop_ssp()
{
[ -n "$1" ] && logger -st "SSP[$$]WARNING" "$1" && nvram set ss_enable=0
[ "$(nvram get ss_enable)" = "0" ] && echo "daten_stopwatchcat" > $statusfile && del_json_file
$(cat "$statusfile" 2>/dev/null | grep -q 'watchcat_stop_ssp') || \
$(cat "$statusfile" 2>/dev/null | grep -q "watchcat_restart_ssp_") || stop_watchcat
del_dns_conf
stop_rules
stop_redir
(if [ -e "$CONF_DIR/amsallexp.set" ] || [ -e "$CONF_DIR/amsallexp.txt" ]; then
  cat $CONF_DIR/amsallexp.set $CONF_DIR/amsallexp.txt 2>/dev/null | sort -u >> $CONF_DIR/amsallexp.tmp && \
  rm -rf $CONF_DIR/amsallexp.set && rm -rf $CONF_DIR/amsallexp.txt && \
  mv -f $CONF_DIR/amsallexp.tmp $CONF_DIR/amsallexp.txt
fi)&
wait
[ -n "$1" ] && logger -st "SSP[$$]WARNING" "启动失败" && exit 1 || return 0
}

start_ssp()
{
ulimit -n 65536
[ $nodesnum -ge 1 ] || stop_ssp "请到[节点设置]添加服务器"
logger -st "SSP[$$]$bin_type" "开始启动" && gen_json_file || stop_ssp "找不到[$bin_type]服务器"
[ -n "$ssp_server_type" ] && [ -n "$ssp_server_addr" ] && [ -n "$ssp_server_port" ] && [ -n "$redir_json_file" ] || stop_ssp "配置文件发生错误"
$(cat "$statusfile" 2>/dev/null | grep -q 'watchcat_start_ssp') || \
$(cat "$statusfile" 2>/dev/null | grep -q "watchcat_restart_ssp_") || stop_watchcat
start_redir || stop_ssp "代理进程发生错误"
start_rules || stop_ssp "透明代理发生错误"
gen_dns_conf || stop_ssp "解析规则发生错误"
echo "$ssp_server_type──$ssp_server_addr:$ssp_server_port──[$redir_json_file]" > $issjfinfor
sleep 1 && pidof ss-watchcat.sh &>/dev/null && STA_LOG="重启完成" || /usr/bin/ss-watchcat.sh
logger -st "SSP[$(pidof $redir_bin)]$ssp_server_type" "$ssp_server_addr:$ssp_server_port [$redir_json_file] ${STA_LOG:=成功启动}" && scron 1
return 0
}

case "$1" in
stop)
  stop_ssp
  ;;
start)
  start_ssp
  ;;
restart)
  stop_ssp
  start_ssp
  ;;
rednsconf)
  del_dns_conf
  gen_dns_conf
  ;;
cleandnsconf)
  del_dns_conf
  ;;
*)
  echo "Usage: $0 { start | stop | restart | rednsconf | cleandnsconf }"
  exit 1
  ;;
esac
