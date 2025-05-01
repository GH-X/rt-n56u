#!/bin/sh

USBB_DIR=$(find /media/ -name SSP)
SYSB_DIR="/usr/bin"
CONF_DIR="/tmp/SSP"
ETCS_DIR="/etc/storage"
CRON_CONF="$ETCS_DIR/cron/crontabs/$(nvram get http_username)"
[ -n "$USBB_DIR" ] && EXTB_DIR="$USBB_DIR" || EXTB_DIR="$CONF_DIR"

([ "$EXTB_DIR" == "$USBB_DIR" ] && echo "$(date "+%Y-%m-%d_%H:%M:%S")" > $EXTB_DIR/SSPUSBDIR)&
wait

#$SYSB_DIR/ss-local -> /var/ss-local -> $SYSB_DIR/ss-orig-local or $SYSB_DIR/ssr-local
ss_local_bin="$SYSB_DIR/ss-orig-local"
ssr_local_bin="$SYSB_DIR/ssr-local"
local_bin="ss-local"
local_link="/var/ss-local"
#$SYSB_DIR/ss-local -> /var/ss-local -> $EXTB_DIR/trojan or $SYSB_DIR/trojan
#$SYSB_DIR/ss-local -> /var/ss-local -> $EXTB_DIR/v2ray or $SYSB_DIR/v2ray
#$SYSB_DIR/ss-local -> /var/ss-local -> $EXTB_DIR/naive or $SYSB_DIR/naive
#$SYSB_DIR/ss-local -> /var/ss-local -> $EXTB_DIR/hysteria2 or $SYSB_DIR/hysteria2
#$SYSB_DIR/ss-local -> /var/ss-local -> $EXTB_DIR/xray or $SYSB_DIR/xray
#$SYSB_DIR/ss-local -> /var/ss-local -> $EXTB_DIR/mieru or $SYSB_DIR/mieru
ss_v2rp_bin="ss-v2ray-plugin"
v2rp_bin="v2ray-plugin"
v2rp_link="/var/v2ray-plugin"
#$SYSB_DIR/v2ray-plugin -> /var/v2ray-plugin -> $EXTB_DIR/ss-v2ray-plugin or $SYSB_DIR/ss-v2ray-plugin

nofile="32768"

aiderstart="$CONF_DIR/aiderstart"
socksstart="$CONF_DIR/socksstart"
rulesstart="$CONF_DIR/rulesstart"
localstart="$CONF_DIR/localstart"
scoresfile="$CONF_DIR/scoresfile"
local_log_file="/tmp/ss-local.log"
ssp_custom_conf="$ETCS_DIR/ssp_custom.conf"

sspbinname=$(grep '^sspbinname' $ssp_custom_conf | awk -F\| '{print $2}')
aid_dns=$(nvram get smartdns_enable)
autorec=$(nvram get ss_watchcat_autorec)
ss_enable=$(nvram get ss_enable)
ss_type=$(nvram get ss_type)
ssp_type=${ss_type:0} # 0=ss 1=ssr 2=trojan 3=vmess 4=naive 5=hysteria2 6=vless 7=mieru 8=custom 9=auto
ss_mode=$(nvram get ss_mode) # 0=global 1=chnroute 21=gfwlist(diversion rate: Keen) 22=gfwlist(diversion rate: True)
ss_local_port=$(nvram get ss_local_port)
ss_redir_port=$(expr $ss_local_port + 1)
ss_mtu=$(nvram get ss_mtu)
nodesnum=$(nvram get ss_server_num_x)
dns_local_port=$(nvram get ss_dns_local_port)
dns_remote=$(nvram get ss_dns_remote_server)
dns_remote_addr=$(echo "$dns_remote" | awk -F: '{print $1}')
dns_remote_port=$(echo "$dns_remote" | awk -F: '{print $2}')

LoopBackAddr="127.0.0.1"
smartdns_conf="$CONF_DIR/smartdns.conf"
serveraddrisip="$CONF_DIR/serveraddrisip.txt"
serveraddrnoip="$CONF_DIR/serveraddrnoip.txt"

dnschndt="$ETCS_DIR/chnlist/chnlist_domain.txt"
dnschndp="$CONF_DIR/chnlist_domain.txt"
dnschndm="$CONF_DIR/chnlist_domain.md5"
dnsgfwdt="$ETCS_DIR/gfwlist/gfwlist_domain.txt"
dnsgfwdp="$CONF_DIR/gfwlist_domain.txt"
dnsgfwdm="$CONF_DIR/gfwlist_domain.md5"
dnslistc="$CONF_DIR/gfwlist/dnsmasq.conf"
dnsmasqc="$ETCS_DIR/dnsmasq/dnsmasq.conf"

[ "$ssp_type" == "0" ] && bin_type="SS"
[ "$ssp_type" == "1" ] && bin_type="SSR"
[ "$ssp_type" == "2" ] && bin_type="Trojan"
[ "$ssp_type" == "3" ] && bin_type="VMess"
[ "$ssp_type" == "4" ] && bin_type="Naive"
[ "$ssp_type" == "5" ] && bin_type="Hysteria2"
[ "$ssp_type" == "6" ] && bin_type="VLESS"
[ "$ssp_type" == "7" ] && bin_type="Mieru"
[ "$ssp_type" == "8" ] && bin_type="Custom"
[ "$ssp_type" == "9" ] && bin_type="Auto"
[ ! -d "$CONF_DIR/gfwlist" ] && mkdir -p "$CONF_DIR/gfwlist" && nvram set wait_times=3 && nvram set turn_json_file=0
[ -e "$EXTB_DIR/$sspbinname" ] && chmod +x $EXTB_DIR/$sspbinname && ssp_custom="$EXTB_DIR/$sspbinname" || ssp_custom="$SYSB_DIR/$sspbinname"
[ -e "$EXTB_DIR/trojan" ] && chmod +x $EXTB_DIR/trojan && ssp_trojan="$EXTB_DIR/trojan" || ssp_trojan="$SYSB_DIR/trojan"
[ -e "$EXTB_DIR/naive" ] && chmod +x $EXTB_DIR/naive && ssp_naive="$EXTB_DIR/naive" || ssp_naive="$SYSB_DIR/naive"
[ -e "$EXTB_DIR/hysteria2" ] && chmod +x $EXTB_DIR/hysteria2 && ssp_hysteria2="$EXTB_DIR/hysteria2" || ssp_hysteria2="$SYSB_DIR/hysteria2"
[ -e "$EXTB_DIR/mieru" ] && chmod +x $EXTB_DIR/mieru && ssp_mieru="$EXTB_DIR/mieru" || ssp_mieru="$SYSB_DIR/mieru"
[ -e "$EXTB_DIR/xray" ] && chmod +x $EXTB_DIR/xray && ssp_xray="$EXTB_DIR/xray" || ssp_xray="$SYSB_DIR/xray"
[ -e "$EXTB_DIR/v2ray" ] && chmod +x $EXTB_DIR/v2ray && ssp_v2ray="$EXTB_DIR/v2ray" || ssp_v2ray="$SYSB_DIR/v2ray"
[ -e "$EXTB_DIR/$ss_v2rp_bin" ] && chmod +x $EXTB_DIR/$ss_v2rp_bin && ssp_v2rp="$EXTB_DIR/$ss_v2rp_bin" || ssp_v2rp="$SYSB_DIR/$ss_v2rp_bin"
[ -L $ETCS_DIR/chinadns/chnroute.txt ] && [ ! -e $EXTB_DIR/chnroute.txt ] && \
rm -rf $ETCS_DIR/chinadns/chnroute.txt && tar jxf /etc_ro/chnroute.bz2 -C $ETCS_DIR/chinadns
[ -e $EXTB_DIR/chnroute.txt ] && [ $(cat $ETCS_DIR/chinadns/chnroute.txt | wc -l) -ne $(cat $EXTB_DIR/chnroute.txt | wc -l) ] && \
rm -rf $ETCS_DIR/chinadns/chnroute.txt && ln -sf $EXTB_DIR/chnroute.txt $ETCS_DIR/chinadns/chnroute.txt

stopp()
{
$(pidof "$1" &>/dev/null) || return 1
killall -q -SIGTERM "$1"
sleep 1
$(pidof "$1" &>/dev/null) || return 0
killall -q -9 "$1"
return 0
}

stop_watchcat()
{
nvram set watchcat_state=stop_watchcat
sed -i '/ss-watchcat.sh/d' $CRON_CONF && restart_crond
stopp ss-watchcat.sh
nvram set wait_times=0
nvram set link_times=0
nvram set link_error=0
nvram set server_infor=snum──type──addr:port
nvram set watchcat_state=stopped
}

stop_socks()
{
rm -rf $socksstart
stopp ipt2socks
logger -st "SSP[$$]$bin_type" "关闭本地代理"
}

stop_rules()
{
rm -rf $rulesstart
stopp ss-rules
logger -st "SSP[$$]$bin_type" "关闭透明代理" && ss-rules -f
}

custom_chnlist()
{
chndnum=$(grep -v '^\.' $dnschndt | wc -l)
chnfnum=${chndnum:0}
cp -rf $dnschndt $dnschndp
md5sum $dnschndp > $dnschndm
sed -i '/^\./d' $dnschndp
for addchn in $(nvram get ss_custom_chnlist | sed 's/,/ /g'); do
  [ "$addchn" != "" ] && $(echo $addchn | grep -v -q '^\.') && echo ".$addchn" >> $dnschndp
done
md5sum -c -s $dnschndm
[ "$?" != "0" ] && rm -rf $dnschndt && cp -rf $dnschndp $dnschndt
rm -rf $dnschndp && rm -rf $dnschndm
if [ $(cat $dnschndt | wc -l) -ge $chnfnum ]; then
  return 0
else
  logger -st "SSP[$$]WARNING" "自定义白名单域名发生错误!恢复默认白名单域名"
  rm -rf $dnschndt && tar jxf /etc_ro/chnlist.bz2 -C $ETCS_DIR/chnlist
  return 0
fi
}

custom_gfwlist()
{
gfwdnum=$(grep -v '^\.' $dnsgfwdt | wc -l)
gfwfnum=${gfwdnum:0}
cp -rf $dnsgfwdt $dnsgfwdp
md5sum $dnsgfwdp > $dnsgfwdm
sed -i '/^\./d' $dnsgfwdp
for addgfw in $(nvram get ss_custom_gfwlist | sed 's/,/ /g'); do
  gfwdomain=$(echo $addgfw | grep -v '^\.' | grep -v '^#')
  [ "$gfwdomain" != "" ] && echo ".$gfwdomain" >> $dnsgfwdp
done
md5sum -c -s $dnsgfwdm
[ "$?" != "0" ] && rm -rf $dnsgfwdt && cp -rf $dnsgfwdp $dnsgfwdt
rm -rf $dnsgfwdp && rm -rf $dnsgfwdm
if [ $(cat $dnsgfwdt | wc -l) -ge $gfwfnum ]; then
  return 0
else
  logger -st "SSP[$$]WARNING" "自定义黑名单域名发生错误!恢复默认黑名单域名"
  rm -rf $dnsgfwdt && tar jxf /etc_ro/gfwlist.bz2 -C $ETCS_DIR/gfwlist
  return 0
fi
}

aid_dns()
{
cat > "$smartdns_conf" << EOF
log-num 2
log-syslog yes
speed-check-mode tcp:443,tcp:80,ping
response-mode fastest-ip
dualstack-ip-selection no
ca-file $ETCS_DIR/cacerts/cacert.pem
bind-tcp $LoopBackAddr:$dns_local_port
server-tcp $dns_remote
EOF
for resolvdns in $(awk '{print $2}' /etc/resolv.conf | grep -v "$LoopBackAddr"); do
  echo "server $resolvdns:53" >> $smartdns_conf
done
if [ "$ss_mode" != "0" ]; then
  echo "ipset chnlist" >> $smartdns_conf
  echo "ipset-no-speed gfwlist" >> $smartdns_conf
fi
cat > "$aiderstart" << EOF
#!/bin/sh

smartdns -c $smartdns_conf
EOF
}

del_dns_conf()
{
logger -st "SSP[$$]$bin_type" "清除解析规则"
sed -i 's/^### gfwlist related.*/### gfwlist related resolve/g' $dnsmasqc
sed -i 's/^no-resolv/#no-resolv/g' $dnsmasqc
sed -i 's/^server='$LoopBackAddr'~.*/#server='$LoopBackAddr'~'$dns_local_port'/g' $dnsmasqc
sed -i 's/^min-cache-ttl=/#min-cache-ttl=/g' $dnsmasqc
sed -i 's/^max-cache-ttl=/#max-cache-ttl=/g' $dnsmasqc
sed -i 's:^conf-dir='$CONF_DIR'/gfwlist:#conf-dir='$CONF_DIR'/gfwlist:g' $dnsmasqc
rm -rf $dnslistc
rm -rf $aiderstart
rm -rf $smartdns_conf
stopp smartdns
custom_chnlist
custom_gfwlist
}

get_dns_conf()
{
logger -st "SSP[$$]$bin_type" "创建解析规则"
grep -v '^#' $dnsgfwdt | grep -v '^$' | sed 's/^\.//g' | awk '{printf("server=/%s/'$2'\n", $1, $1 )}' >> $dnslistc
if [ "$ss_mode" == "21" ] || [ "$ss_mode" == "22" ]; then
  grep -v '^#' $dnsgfwdt | grep -v '^$' | sed 's/^\.//g' | awk '{printf("ipset=/%s/gfwlist\n", $1, $1 )}' >> $dnslistc
  [ "$aid_dns" == "0" ] && grep -v '^#' $dnschndt | grep -v '^$' | sed 's/^\.//g' | awk '{printf("ipset=/%s/chnlist\n", $1, $1 )}' >> $dnslistc
fi
[ -e "$serveraddrnoip" ] && awk '{printf("ipset=/%s/servers\n", $1, $1 )}' $serveraddrnoip >> $dnslistc
for addgfw in $(nvram get ss_custom_gfwlist | sed 's/,/ /g'); do
  dnsspoofing=$(echo $addgfw | grep '^#' | sed 's/#//g')
  if [ "$dnsspoofing" != "" ]; then
    sed -i '/'$dnsspoofing'/d' $dnslistc
    echo "server=/$dnsspoofing/$2" >> $dnslistc
    echo "ipset=/$dnsspoofing/chnlist" >> $dnslistc
  fi
done
sed -i 's/^### gfwlist related.*/### gfwlist related resolve by '$1' '$2'/g' $dnsmasqc
[ "$aid_dns" == "1" ] && sed -i 's/^#no-resolv/no-resolv/g' $dnsmasqc
[ "$aid_dns" == "1" ] && sed -i 's/^#server='$LoopBackAddr'~.*/server='$LoopBackAddr'~'$dns_local_port'/g' $dnsmasqc
sed -i 's/^#min-cache-ttl=/min-cache-ttl=/g' $dnsmasqc
sed -i 's/^#max-cache-ttl=/max-cache-ttl=/g' $dnsmasqc
[ -e "$dnslistc" ] && sed -i 's:^#conf-dir='$CONF_DIR'/gfwlist:conf-dir='$CONF_DIR'/gfwlist:g' $dnsmasqc
}

gen_dns_conf()
{
del_dns_conf
if [ "$1" != "0" ]; then
  [ "$aid_dns" == "1" ] && dnstag="dnsmasq+smartdns" && aid_dns
  get_dns_conf ${dnstag:=dnsmasq} "$dns_remote_addr~$dns_remote_port"
fi
[ -e "$aiderstart" ] && chmod +x $aiderstart && $aiderstart
restart_dhcpd
}

del_json_file()
{
logger -st "SSP[$$]$bin_type" "清除配置文件"
nvram set turn_json_file=0
nvram set link_times=0
rm -rf $scoresfile
rm -rf $CONF_DIR/*.md5
rm -rf $CONF_DIR/*.toml
rm -rf $CONF_DIR/*.json
rm -rf $CONF_DIR/*-jsonlist
rm -rf $CONF_DIR/Nodes-list
rm -rf $serveraddrisip
rm -rf $serveraddrnoip
}

stop_local()
{
(stopp $local_bin && logger -st "SSP[$$]$bin_type" "关闭代理进程")&
(stopp $v2rp_bin && logger -st "SSP[$$]$bin_type" "关闭插件进程")&
(rm -rf $localstart)&
wait
return 0
}

notify_detect_internet()
{
killall -q -SIGUSR2 detect_internet
}

stop_ssp()
{
[ -n "$1" ] && nvram set ss_enable=0 && ss_enable="0" && logger -st "SSP[$$]WARNING" "$1"
if [ "$ss_enable" == "0" ]; then
  stop_watchcat
  stop_socks
  stop_rules
  gen_dns_conf 0
  del_json_file
  nvram set start_rules=0
elif [ "$(nvram get link_internet)" == "0" ]; then
  $(nvram get watchcat_state | grep -q 'watchcat_stop_ssp') || stop_watchcat
  stop_socks
  stop_rules
  gen_dns_conf 0
  nvram set start_rules=1
else
  $(nvram get watchcat_state | grep -q 'watchcat_stop_ssp') || stop_watchcat
fi
stop_local
notify_detect_internet
return 0
}

turn_json_file()
{
[ -e "$CONF_DIR/ssp_custom.md5" ] && md5sum -c -s $CONF_DIR/ssp_custom.md5 || return 1
[ -e "$CONF_DIR/Nodes-list.md5" ] && rm -rf $CONF_DIR/Nodes-list && for i in $(seq 1 $nodesnum); do
  j=$(expr $i - 1)
  node_type=$(nvram get ss_server_type_x$j)      # 0  1   2      3     4     5         6     7
  server_addr=$(nvram get ss_server_addr_x$j)    # SS SSR Trojan VMess Naive hysteria2 VLESS Mieru
  server_port=$(nvram get ss_server_port_x$j)    # SS SSR Trojan VMess Naive hysteria2 VLESS Mieru
  server_key=$(nvram get ss_server_key_x$j)      # SS SSR Trojan VMess Naive hysteria2 VLESS Mieru
  server_sni=$(nvram get ss_server_sni_x$j)      #        Trojan VMess       hysteria2 VLESS Mieru
  ss_method=$(nvram get ss_method_x$j)           # SS SSR        VMess                 VLESS
  ss_protocol=$(nvram get ss_protocol_x$j)       #    SSR        VMess Naive hysteria2 VLESS Mieru
  ss_proto_param=$(nvram get ss_proto_param_x$j) #    SSR        VMess                 VLESS Mieru
  ss_obfs=$(nvram get ss_obfs_x$j)               # SS SSR        VMess       hysteria2 VLESS
  ss_obfs_param=$(nvram get ss_obfs_param_x$j)   # SS SSR        VMess       hysteria2 VLESS
  echo "$i#$node_type#$server_addr#$server_port#$server_key#$server_sni#$ss_method#$ss_protocol#$ss_proto_param#$ss_obfs#$ss_obfs_param" >> $CONF_DIR/Nodes-list
done && md5sum -c -s $CONF_DIR/Nodes-list.md5 || return 1
[ "$(cat $CONF_DIR/$bin_type-jsonlist | wc -l)" != "1" ] || return 0
[ "$(nvram get turn_json_file)" == "1" ] || return 0
logger -st "SSP[$$]$bin_type" "更换配置文件" && nvram set link_times=0
turn_temp=$(tail -n 1 $CONF_DIR/$bin_type-jsonlist)
turn_json=${turn_temp:0}
sed -i '/'$turn_json'/d' $CONF_DIR/$bin_type-jsonlist
sed -i '1i\'$turn_json'' $CONF_DIR/$bin_type-jsonlist
return 0
}

addr_isip_noip()
{
addr_isip=$(echo "$1" | grep -E "^([0-9]{1,3}\.){3}[0-9]{1,3}")
if [ "$addr_isip" == "$1" ]; then
  echo "$addr_isip" >> $serveraddrisip
else
  echo "$1" >> $serveraddrnoip
fi
}

gen_json_file()
{
[ "$bin_type" == "Custom" ] || [ "$nodesnum" -ge "1" ] || $(stop_ssp "请到[节点设置]添加服务器" && return 1) || exit 1
confoptarg=$(grep '^confoptarg' $ssp_custom_conf | awk -F\| '{print $2}')
serveraddr=$(grep '^serveraddr' $ssp_custom_conf | awk -F\| '{print $2}')
serverport=$(grep '^serverport' $ssp_custom_conf | awk -F\| '{print $2}')
turn_json_file || del_json_file
[ "$autorec" == "1" ] && nvram set turn_json_file=1 || nvram set turn_json_file=0
if [ ! -e "$CONF_DIR/Nodes-list.md5" ]; then
  nvram set start_rules=1
  logger -st "SSP[$$]$bin_type" "创建配置文件"
  for i in $(seq 1 $nodesnum); do
    j=$(expr $i - 1)
    node_type=$(nvram get ss_server_type_x$j)      # 0  1   2      3     4     5         6     7
    server_addr=$(nvram get ss_server_addr_x$j)    # SS SSR Trojan VMess Naive hysteria2 VLESS Mieru
    server_port=$(nvram get ss_server_port_x$j)    # SS SSR Trojan VMess Naive hysteria2 VLESS Mieru
    server_key=$(nvram get ss_server_key_x$j)      # SS SSR Trojan VMess Naive hysteria2 VLESS Mieru
    server_sni=$(nvram get ss_server_sni_x$j)      #        Trojan VMess       hysteria2 VLESS Mieru
    ss_method=$(nvram get ss_method_x$j)           # SS SSR        VMess                 VLESS
    ss_protocol=$(nvram get ss_protocol_x$j)       #    SSR        VMess Naive hysteria2 VLESS Mieru
    ss_proto_param=$(nvram get ss_proto_param_x$j) #    SSR        VMess                 VLESS Mieru
    ss_obfs=$(nvram get ss_obfs_x$j)               # SS SSR        VMess       hysteria2 VLESS
    ss_obfs_param=$(nvram get ss_obfs_param_x$j)   # SS SSR        VMess       hysteria2 VLESS
    addr_isip_noip $server_addr
    echo "$i#$node_type#$server_addr#$server_port#$server_key#$server_sni#$ss_method#$ss_protocol#$ss_proto_param#$ss_obfs#$ss_obfs_param" >> $CONF_DIR/Nodes-list
    [ "$node_type" == "0" ] && server_type="SS"
    [ "$node_type" == "1" ] && server_type="SSR"
    [ "$node_type" == "2" ] && server_type="Trojan"
    [ "$node_type" == "3" ] && server_type="VMess"
    [ "$node_type" == "4" ] && server_type="Naive"
    [ "$node_type" == "5" ] && server_type="Hysteria2"
    [ "$node_type" == "6" ] && server_type="VLESS"
    [ "$node_type" == "7" ] && server_type="Mieru"
    if [ "$server_type" == "SS" ]; then
      if [ "$ss_obfs" == "v2ray_plugin_websocket" ]; then
        ss_pm="v2rp-WEBS" && ss_plugin="$v2rp_bin"
      elif [ "$ss_obfs" == "v2ray_plugin_quic" ]; then
        ss_pm="v2rp-QUIC" && ss_plugin="$v2rp_bin"
      else
        ss_pm="null" && ss_plugin=""
      fi
      if [ "$ss_pm" == "null" ]; then
        ss_popts=""
        ss_pargs=""
      else
        if $(echo "$ss_obfs_param" | grep -q ","); then
          ss_popts=$(echo "$ss_obfs_param" | awk -F, '{print $1}')
          ss_pargs=$(echo "$ss_obfs_param" | awk -F, '{print $2}')
        else
          ss_popts="$ss_obfs_param"
          ss_pargs=""
        fi
      fi
      l_json_file="$i-$server_type-local.json"
      echo "$server_addr#$server_port#$l_json_file#$ss_pm" >> $CONF_DIR/SS-jsonlist
      echo "$server_addr#$server_port#$l_json_file#$ss_pm" >> $CONF_DIR/Auto-jsonlist
	    cat > "$CONF_DIR/$l_json_file" << EOF
{
    "server": "$server_addr",
    "server_port": $server_port,
    "password": "$server_key",
    "method": "$ss_method",
    "plugin": "$ss_plugin",
    "plugin_opts": "$ss_popts",
    "plugin_args": "$ss_pargs",
    "timeout": 60,
    "local_address": "0.0.0.0",
    "local_port": $ss_local_port,
    "mtu": $ss_mtu
}

EOF
    elif [ "$server_type" == "SSR" ]; then
      l_json_file="$i-$server_type-local.json"
      echo "$server_addr#$server_port#$l_json_file#null" >> $CONF_DIR/SSR-jsonlist
      echo "$server_addr#$server_port#$l_json_file#null" >> $CONF_DIR/Auto-jsonlist
	    cat > "$CONF_DIR/$l_json_file" << EOF
{
    "server": "$server_addr",
    "server_port": $server_port,
    "password": "$server_key",
    "method": "$ss_method",
    "timeout": 60,
    "protocol": "$ss_protocol",
    "protocol_param": "$ss_proto_param",
    "obfs": "$ss_obfs",
    "obfs_param": "$ss_obfs_param",
    "local_address": "0.0.0.0",
    "local_port": $ss_local_port,
    "mtu": $ss_mtu
}

EOF
    elif [ "$server_type" == "Mieru" ]; then
      mieru_mtu="$ss_mtu"
      [ $mieru_mtu -le 1280 ] && mieru_mtu="1280"
      [ $mieru_mtu -ge 1400 ] && mieru_mtu="1400"
      [ "$ss_protocol" == "tcp" ] && ss_protocol="TCP"
      [ "$ss_protocol" == "udp" ] && ss_protocol="UDP"
      $(echo "$server_port" | grep -q "-") && server_port="\"$server_port\"" && mieru_port="portRange" || mieru_port="port"
      l_json_file="$i-$server_type-local.json"
      echo "$server_addr#$server_port#$l_json_file#null" >> $CONF_DIR/Mieru-jsonlist
      echo "$server_addr#$server_port#$l_json_file#null" >> $CONF_DIR/Auto-jsonlist
      cat > "$CONF_DIR/$l_json_file" << EOF
{
    "profiles": [
        {
            "profileName": "default",
            "user": {
                "name": "$ss_proto_param",
                "password": "$server_key"
            },
            "servers": [
                {
                    "ipAddress": "$server_addr",
                    "domainName": "$server_sni",
                    "portBindings": [
                        {
                            "$mieru_port": $server_port,
                            "protocol": "$ss_protocol"
                        }
                    ]
                }
            ],
            "mtu": $mieru_mtu,
            "multiplexing": {
                "level": "MULTIPLEXING_HIGH"
            }
        }
    ],
    "activeProfile": "default",
    "rpcPort": 8964,
    "socks5Port": $ss_local_port,
    "loggingLevel": "INFO",
    "socks5ListenLAN": true
}

EOF
    elif [ "$server_type" == "Trojan" ]; then
      [ "$server_sni" == "" ] && verifyhostname="false" || verifyhostname="true"
      l_json_file="$i-$server_type-local.json"
      echo "$server_addr#$server_port#$l_json_file#null" >> $CONF_DIR/Trojan-jsonlist
      echo "$server_addr#$server_port#$l_json_file#null" >> $CONF_DIR/Auto-jsonlist
      cat > "$CONF_DIR/$l_json_file" << EOF
{
    "run_type": "client",
    "local_addr": "0.0.0.0",
    "local_port": $ss_local_port,
    "remote_addr": "$server_addr",
    "remote_port": $server_port,
    "password": [
        "$server_key"
    ],
    "log_level": 2,
    "ssl": {
        "verify": $verifyhostname,
        "verify_hostname": $verifyhostname,
        "sni": "$server_sni"
    }
}

EOF
    elif [ "$server_type" == "Naive" ]; then
      l_json_file="$i-$server_type-local.json"
      echo "$server_addr#$server_port#$l_json_file#null" >> $CONF_DIR/Naive-jsonlist
      echo "$server_addr#$server_port#$l_json_file#null" >> $CONF_DIR/Auto-jsonlist
      cat > "$CONF_DIR/$l_json_file" << EOF
{
  "listen": "socks://0.0.0.0:$ss_local_port",
  "proxy": "$ss_protocol://$server_key@$server_addr:$server_port",
  "log": "$local_log_file"
}

EOF
    elif [ "$server_type" == "Hysteria2" ]; then
      [ "$server_sni" == "" ] && verifyhostname="false" || verifyhostname="true"
      l_json_file="$i-$server_type-local.toml"
      echo "$server_addr#$server_port#$l_json_file#null" >> $CONF_DIR/Hysteria2-jsonlist
      echo "$server_addr#$server_port#$l_json_file#null" >> $CONF_DIR/Auto-jsonlist
      cat > "$CONF_DIR/$l_json_file" << EOF
server = "$server_addr:$server_port"
auth = "$server_key"

[tls]
sni = "$server_sni"
insecure = $verifyhostname

EOF
      [ "$ss_protocol" == "udp" ] && cat >> "$CONF_DIR/$l_json_file" << EOF
[transport]
type = "$ss_protocol"

  [transport.$ss_protocol]
  hopInterval = "30s"

EOF
      [ "$ss_obfs" == "salamander" ] && cat >> "$CONF_DIR/$l_json_file" << EOF
[obfs]
type = "$ss_obfs"

  [obfs.$ss_obfs]
  password = "$ss_obfs_param"

EOF
      cat >> "$CONF_DIR/$l_json_file" << EOF
[socks5]
listen = "0.0.0.0:$ss_local_port"

EOF
    elif [ "$server_type" == "VLESS" ]; then
      [ "$ss_method" != "empty" ] || ss_method=""
      [ "$ss_obfs" != "empty" ] || ss_obfs=""
      l_json_file="$i-$server_type-local.json"
      echo "$server_addr#$server_port#$l_json_file#null" >> $CONF_DIR/VLESS-jsonlist
      echo "$server_addr#$server_port#$l_json_file#null" >> $CONF_DIR/Auto-jsonlist
      cat > "$CONF_DIR/$l_json_file" << EOF
{
  "log": {
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "tag": "socks",
      "port": $ss_local_port,
      "listen": "0.0.0.0",
      "protocol": "socks",
      "settings": {
        "auth": "noauth",
        "udp": true
      },
      "streamSettings": {
        "sockopt": {
          "tcpFastOpen": false,
          "tproxy": "redirect"
        }
      },
      "sniffing": {
        "enabled": false,
        "destOverride": [
          "http",
          "tls"
        ]
      }
    }
  ],
EOF
      cat >> "$CONF_DIR/$l_json_file" << EOF
  "outbounds": [
    {
      "tag": "proxy",
      "protocol": "vless",
      "settings": {
        "vnext": [
          {
            "address": "$server_addr",
            "port": $server_port,
            "users": [
              {
                "id": "$server_key",
                "encryption": "none",
                "flow": "$ss_method"
              }
            ]
          }
        ]
      },
EOF
      if [ "$ss_protocol" == "raw_tls" ]; then
        [ "$server_sni" != "" ] && allow_insecure="false" || allow_insecure="true"
        cat >> "$CONF_DIR/$l_json_file" << EOF
      "streamSettings": {
        "network": "raw",
        "security": "tls",
        "tlsSettings": {
          "serverName": "$server_sni",
          "allowInsecure": $allow_insecure,
          "fingerprint": "$ss_obfs"
        }
      },
EOF
      elif [ "$ss_protocol" == "raw_reality" ]; then
        cat >> "$CONF_DIR/$l_json_file" << EOF
      "streamSettings": {
        "network": "raw",
        "security": "reality",
        "realitySettings": {
          "show": false,
          "serverName": "$server_sni",
          "fingerprint": "$ss_obfs",
          "shortId": "$ss_proto_param",
          "publicKey": "$ss_obfs_param",
          "spiderX": ""
        }
      },
EOF
      fi
      cat >> "$CONF_DIR/$l_json_file" << EOF
      "mux": {
        "enabled": true,
        "concurrency": 1
      }
    }
  ]
}

EOF
    elif [ "$server_type" == "VMess" ]; then
      if $(echo "$server_key" | grep -q ","); then
        server_uid=$(echo "$server_key" | awk -F, '{print $1}')
        server_aid=$(echo "$server_key" | awk -F, '{print $2}')
      else
        server_uid="$server_key"
        server_aid="0"
      fi
      l_json_file="$i-$server_type-local.json"
      echo "$server_addr#$server_port#$l_json_file#null" >> $CONF_DIR/VMess-jsonlist
      echo "$server_addr#$server_port#$l_json_file#null" >> $CONF_DIR/Auto-jsonlist
      cat > "$CONF_DIR/$l_json_file" << EOF
{
  "log": {
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "tag": "socks",
      "port": $ss_local_port,
      "listen": "0.0.0.0",
      "protocol": "socks",
      "settings": {
        "auth": "noauth",
        "udp": true
      },
      "streamSettings": {
        "sockopt": {
          "tcpFastOpen": false,
          "tproxy": "redirect"
        }
      },
      "sniffing": {
        "enabled": false,
        "destOverride": [
          "http",
          "tls"
        ]
      }
    }
  ],
EOF
      cat >> "$CONF_DIR/$l_json_file" << EOF
  "outbounds": [
    {
      "tag": "proxy",
      "protocol": "vmess",
      "settings": {
        "vnext": [
          {
            "address": "$server_addr",
            "port": $server_port,
            "users": [
              {
                "id": "$server_uid",
                "alterId": $server_aid,
                "security": "$ss_method"
              }
            ]
          }
        ]
      },
EOF
      if [ "$ss_protocol" == "tcp" ] && [ "$ss_obfs" == "none" ]; then
        cat >> "$CONF_DIR/$l_json_file" << EOF
      "streamSettings": {
        "network": "tcp"
      },
EOF
      elif [ "$ss_protocol" == "tcp" ] && [ "$ss_obfs" == "http" ]; then
        cat >> "$CONF_DIR/$l_json_file" << EOF
      "streamSettings": {
        "network": "tcp",
        "tcpSettings": {
          "header": {
            "type": "http",
            "request": {
              "version": "1.1",
              "method": "GET",
              "path": [
                "$ss_proto_param"
              ],
              "headers": {
EOF
        if $(echo "$ss_obfs_param" | grep -q ","); then
          host1=$(echo "$ss_obfs_param" | awk -F, '{print $1}')
          host2=$(echo "$ss_obfs_param" | awk -F, '{print $2}')
          cat >> "$CONF_DIR/$l_json_file" << EOF
                "Host": [
                  "$host1",
                  "$host2"
                ],
EOF
        else
          cat >> "$CONF_DIR/$l_json_file" << EOF
                "Host": [
                  "$ss_obfs_param"
                ],
EOF
        fi
        cat >> "$CONF_DIR/$l_json_file" << EOF
                "User-Agent": [
                  "Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2883.75 Safari/537.36",
                  "Mozilla/5.0 (iPhone; CPU iPhone OS 10_0_2 like Mac OS X) AppleWebKit/601.1 (KHTML, like Gecko) CriOS/53.0.2785.109 Mobile/14A456 Safari/601.1.46"
                ],
                "Accept-Encoding": [
                  "gzip, deflate"
                ],
                "Connection": [
                  "keep-alive"
                ],
                "Pragma": "no-cache"
              }
            }
          }
        }
      },
EOF
      elif [ "$ss_protocol" == "tcp_tls" ]; then
        if [ "$server_sni" != "" ]; then
          server_name="$server_sni"
          allow_insecure="false"
        else
          server_name="$ss_obfs_param"
          allow_insecure="true"
        fi
        if [ "$ss_obfs_param" == "" ]; then
          cat >> "$CONF_DIR/$l_json_file" << EOF
      "streamSettings": {
        "network": "tcp",
        "security": "tls"
      },
EOF
        elif [ "$ss_obfs_param" != "" ]; then
          cat >> "$CONF_DIR/$l_json_file" << EOF
      "streamSettings": {
        "network": "tcp",
        "security": "tls",
        "tlsSettings": {
          "allowInsecure": $allow_insecure,
          "serverName": "$server_name"
        }
      },
EOF
        fi
      elif [ "$ss_protocol" == "ws" ]; then
        if [ "$ss_proto_param" == "" ] && [ "$ss_obfs_param" == "" ]; then
          cat >> "$CONF_DIR/$l_json_file" << EOF
      "streamSettings": {
        "network": "ws"
      },
EOF
        elif [ "$ss_proto_param" != "" ] && [ "$ss_obfs_param" == "" ]; then
          cat >> "$CONF_DIR/$l_json_file" << EOF
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "$ss_proto_param"
        }
      },
EOF
        elif [ "$ss_proto_param" == "" ] && [ "$ss_obfs_param" != "" ]; then
          cat >> "$CONF_DIR/$l_json_file" << EOF
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "headers": {
            "Host": "$ss_obfs_param"
          }
        }
      },
EOF
        elif [ "$ss_proto_param" != "" ] && [ "$ss_obfs_param" != "" ]; then
          cat >> "$CONF_DIR/$l_json_file" << EOF
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "$ss_proto_param",
          "headers": {
            "Host": "$ss_obfs_param"
          }
        }
      },
EOF
        fi
      elif [ "$ss_protocol" == "ws_tls" ]; then
        if [ "$server_sni" != "" ]; then
          server_name="$server_sni"
          allow_insecure="false"
        else
          server_name="$ss_obfs_param"
          allow_insecure="true"
        fi
        if [ "$ss_proto_param" == "" ] && [ "$ss_obfs_param" == "" ]; then
          cat >> "$CONF_DIR/$l_json_file" << EOF
      "streamSettings": {
        "network": "ws",
        "security": "tls"
      },
EOF
        elif [ "$ss_proto_param" != "" ] && [ "$ss_obfs_param" == "" ]; then
          cat >> "$CONF_DIR/$l_json_file" << EOF
      "streamSettings": {
        "network": "ws",
        "security": "tls",
        "wsSettings": {
          "path": "$ss_proto_param"
        }
      },
EOF
        elif [ "$ss_proto_param" == "" ] && [ "$ss_obfs_param" != "" ]; then
          cat >> "$CONF_DIR/$l_json_file" << EOF
      "streamSettings": {
        "network": "ws",
        "security": "tls",
        "tlsSettings": {
          "allowInsecure": $allow_insecure,
          "serverName": "$server_name"
        },
        "wsSettings": {
          "headers": {
            "Host": "$ss_obfs_param"
          }
        }
      },
EOF
        elif [ "$ss_proto_param" != "" ] && [ "$ss_obfs_param" != "" ]; then
          cat >> "$CONF_DIR/$l_json_file" << EOF
      "streamSettings": {
        "network": "ws",
        "security": "tls",
        "tlsSettings": {
          "allowInsecure": $allow_insecure,
          "serverName": "$server_name"
        },
        "wsSettings": {
          "path": "$ss_proto_param",
          "headers": {
            "Host": "$ss_obfs_param"
          }
        }
      },
EOF
        fi
      fi
      cat >> "$CONF_DIR/$l_json_file" << EOF
      "mux": {
        "enabled": true,
        "concurrency": 1
      }
    }
  ]
}

EOF
    fi
  done
  addr_isip_noip $serveraddr
  l_json_file="0-$sspbinname-local.json"
  grep -v '^#' $ssp_custom_conf | grep -v '^sspbinname' | grep -v '^confoptarg' | \
  grep -v '^serveraddr' | grep -v '^serverport' >> $CONF_DIR/$l_json_file
  echo "$serveraddr#$serverport#$l_json_file#null" > $CONF_DIR/Custom-jsonlist
  md5sum $ssp_custom_conf > $CONF_DIR/ssp_custom.md5
  md5sum $CONF_DIR/Nodes-list > $CONF_DIR/Nodes-list.md5
fi
[ "$bin_type" == "Custom" ] || [ "$bin_type" == "Auto" ] || \
$(grep -q "$bin_type-local" $CONF_DIR/$bin_type-jsonlist) || \
$(stop_ssp "请到[节点设置]添加 $bin_type 节点" && return 1) || exit 1
ssp_server_addr=$(tail -n 1 $CONF_DIR/$bin_type-jsonlist | awk -F# '{print $1}')
ssp_server_port=$(tail -n 1 $CONF_DIR/$bin_type-jsonlist | awk -F# '{print $2}')
local_json_file=$(tail -n 1 $CONF_DIR/$bin_type-jsonlist | awk -F# '{print $3}')
ssp_plugin_mode=$(tail -n 1 $CONF_DIR/$bin_type-jsonlist | awk -F# '{print $4}')
ssp_server_snum=$(echo "$local_json_file" | awk -F- '{print $1}')
[ "$bin_type" == "Custom" ] && ssp_server_type="Custom" || \
ssp_server_type=$(echo "$local_json_file" | awk -F- '{print $2}')
if [ "$ssp_server_type" == "SS" ]; then
  if [ "$ssp_plugin_mode" != "null" ]; then
    $([ -x "$ssp_v2rp" ] && ln -sf $ssp_v2rp $v2rp_link) || \
    $(stop_ssp "请上传 $ss_v2rp_bin 可执行文件到 $EXTB_DIR/" && return 1) || exit 1
  fi
  ln -sf $ss_local_bin $local_link
elif [ "$ssp_server_type" == "SSR" ]; then
  ln -sf $ssr_local_bin $local_link
elif [ "$ssp_server_type" == "Trojan" ]; then
  $([ -x "$ssp_trojan" ] && ln -sf $ssp_trojan $local_link) || \
  $(stop_ssp "请上传 trojan 可执行文件到 $EXTB_DIR/" && return 1) || exit 1
elif [ "$ssp_server_type" == "Naive" ]; then
  $([ -x "$ssp_naive" ] && ln -sf $ssp_naive $local_link) || \
  $(stop_ssp "请上传 naive 可执行文件到 $EXTB_DIR/" && return 1) || exit 1
elif [ "$ssp_server_type" == "Hysteria2" ]; then
  $([ -x "$ssp_hysteria2" ] && ln -sf $ssp_hysteria2 $local_link) || \
  $(stop_ssp "请上传 hysteria2 可执行文件到 $EXTB_DIR/" && return 1) || exit 1
elif [ "$ssp_server_type" == "VMess" ]; then
  if [ -x "$ssp_xray" ] && [ ! -x "$ssp_v2ray" ]; then
    ln -sf $ssp_xray $local_link
  else
    $([ -x "$ssp_v2ray" ] && ln -sf $ssp_v2ray $local_link) || \
    $(stop_ssp "请上传 v2ray 可执行文件到 $EXTB_DIR/" && return 1) || exit 1
  fi
elif [ "$ssp_server_type" == "VLESS" ]; then
  $([ -x "$ssp_xray" ] && ln -sf $ssp_xray $local_link) || \
  $(stop_ssp "请上传 xray 可执行文件到 $EXTB_DIR/" && return 1) || exit 1
elif [ "$ssp_server_type" == "Mieru" ]; then
  $([ -x "$ssp_mieru" ] && ln -sf $ssp_mieru $local_link) || \
  $(stop_ssp "请上传 mieru 可执行文件到 $EXTB_DIR/" && return 1) || exit 1
elif [ "$ssp_server_type" == "Custom" ]; then
  $([ -x "$ssp_custom" ] && ln -sf $ssp_custom $local_link) || \
  $(stop_ssp "请上传 $sspbinname 可执行文件到 $EXTB_DIR/" && return 1) || exit 1
fi
$([ -n "$ssp_server_snum" ] && [ -n "$ssp_server_type" ] && \
[ -n "$ssp_server_addr" ] && [ -n "$ssp_server_port" ] && \
[ -n "$local_json_file" ] && return 0) || $(stop_ssp "创建配置文件出错" && return 1) || exit 1
}

start_socks()
{
[ ! -e "$socksstart" ] || return 0
cat > "$socksstart" << EOF
#!/bin/sh

ulimit -n $nofile
start-stop-daemon -S -b -N 0 -x ipt2socks -- -n $nofile -s 0.0.0.0 -p $ss_local_port -b 0.0.0.0 -l $ss_redir_port -R
EOF
chmod +x $socksstart && logger -st "SSP[$$]$bin_type" "开启本地代理" && $socksstart
}

sip_addr()
{
[ -e "$serveraddrisip" ] && echo " -s $serveraddrisip" || echo ""
}

sip_port()
{
echo " -i $ss_redir_port"
}

chn_list()
{
[ "$ss_mode" == "1" ] && [ "$aid_dns" == "0" ] && echo " -c $ETCS_DIR/chinadns/chnroute.txt" || echo ""
}

black_ip()
{
[ "$ss_mode" != "0" ] && echo " -b $dns_remote_addr" || echo ""
}

white_ip()
{
addchn=$(nvram get ss_custom_chnroute | sed 's/[[:space:]]/,/g')
[ "$ss_mode" != "0" ] && [ "$addchn" != "" ] && echo " -w $addchn" || echo ""
}

agent_mode()
{
if [ "$ss_mode" == "0" ]; then # global
  echo " -a 0"
elif [ "$ss_mode" == "1" ]; then # chnroute
  echo " -a 1"
elif [ "$ss_mode" == "21" ]; then # gfwlist(diversion rate: Keen)
  echo " -a 21"
elif [ "$ss_mode" == "22" ]; then # gfwlist(diversion rate: True)
  echo " -a 22"
fi
}

agent_pact()
{
echo " -t"
}

conffile()
{
echo "$CONF_DIR/$local_json_file"
}

opt_arg()
{
if [ "$ssp_server_type" == "Custom" ] && [ "$confoptarg" != "" ]; then
  echo " $confoptarg"
elif [ "$ssp_server_type" == "Mieru" ]; then
  echo " run"
elif [ "$ssp_server_type" == "Naive" ]; then
  echo " $(conffile)"
elif [ "$ssp_server_type" == "VMess" ] || [ "$ssp_server_type" == "VLESS" ]; then
  echo " run -c $(conffile)"
else
  echo " -c $(conffile)"
fi
}

udp_ext()
{
if [ "$ssp_server_type" == "SS" -o "$ssp_server_type" == "SSR" ]; then
  echo " -u"
else
  echo ""
fi
}

start_rules()
{
[ "$(nvram get start_rules)" == "1" ] || return 0
cat > "$rulesstart" << EOF
#!/bin/sh

killall -q -9 ss-rules
ss-rules\
$(sip_addr)\
$(sip_port)\
$(chn_list)\
$(black_ip)\
$(white_ip)\
$(agent_mode)\
$(agent_pact)
EOF
chmod +x $rulesstart && logger -st "SSP[$$]$bin_type" "开启透明代理" && $rulesstart
SREC="$?"
$([ "$SREC" == "0" ] && nvram set start_rules=0 && gen_dns_conf && return 0) || \
$([ "$SREC" == "1" ] && restart_firewall && gen_dns_conf && return 0) || \
$(nvram set start_rules=1 && return $SREC)
}

start_local()
{
cat > "$localstart" << EOF
#!/bin/sh

MemFree=\$(cat /proc/meminfo | grep 'MemFree' | sed 's/[[:space:]]//g' | sed 's/kB//g' | awk -F: '{print \$2}')
ulimit -n $nofile
ulimit -v \$MemFree
ulimit -m \$MemFree
conffile="$(conffile)"
export MIERU_CONFIG_JSON_FILE=\$conffile
export SSL_CERT_FILE='$ETCS_DIR/cacerts/cacert.pem'
export GOMAXPROCS=1

nohup $local_bin$(opt_arg)$(udp_ext) &>$local_log_file &
EOF
chmod +x $localstart && logger -st "SSP[$$]$bin_type" "启动代理进程" && $localstart
$(sleep 1 && pidof $local_bin &>/dev/null) || $(sleep 1 && pidof $local_bin &>/dev/null)
[ "$?" == "1" ] && nvram set turn_json_file=1 && return 1 || return 0
}

ncron()
{
!(grep -q "ss-watchcat.sh" $CRON_CONF) && \
sed -i '/ss-watchcat.sh/d' $CRON_CONF && \
echo "*/$1 * * * * nohup $SYSB_DIR/ss-watchcat.sh 2>/dev/null &" >> $CRON_CONF || return 1
}

dcron()
{
$(grep "ss-watchcat.sh" $CRON_CONF | grep -q -v "/$1") && \
sed -i '/ss-watchcat.sh/d' $CRON_CONF && \
echo "*/$1 * * * * nohup $SYSB_DIR/ss-watchcat.sh 2>/dev/null &" >> $CRON_CONF || return 1
}

scron()
{
ncron $1 || dcron $1
[ "$?" == "0" ] && restart_crond
}

start_ssp()
{
[ "$(nvram get wait_times)" -ge "1" ] && scron 1 && exit 0
$(nvram get watchcat_state | grep -q 'watchcat_start_ssp') || stop_watchcat
gen_json_file
start_socks
start_local || $(nvram set wait_times=1 && logger -st "SSP[$$]WARNING" "启动代理进程出错")
start_rules || $(nvram set wait_times=1 && logger -st "SSP[$$]WARNING" "开启透明代理出错")
nvram set server_infor=$ssp_server_snum──$ssp_server_type──$ssp_server_addr:$ssp_server_port
[ "$(nvram get wait_times)" -ge "1" ] && scron 1 && exit 0
sleep 1 && pidof ss-watchcat.sh &>/dev/null && STA_LOG="重启完成" || $SYSB_DIR/ss-watchcat.sh
logger -st "SSP[$$]$ssp_server_type" "节点$ssp_server_snum[$ssp_server_addr:$ssp_server_port]${STA_LOG:=成功启动}" && scron 1
notify_detect_internet
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
  gen_dns_conf
  ;;
*)
  echo "Usage: $0 { stop | start | restart | rednsconf }"
  exit 1
  ;;
esac

