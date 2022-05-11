#!/bin/sh

CONF_DIR="/tmp/SSP"
statusfile="$CONF_DIR/statusfile"
netdpcount="$CONF_DIR/netdpcount"
errorcount="$CONF_DIR/errorcount"
ssp_log_file="/tmp/ss-watchcat.log"
redir_log_file="/tmp/ss-redir.log"
max_log_bytes="100000"
gfw_domain="https://www.google.com/"
chn_domain="https://www.taobao.com/"
user_agent="Mozilla/5.0 (X11; Linux; rv:74.0) Gecko/20100101 Firefox/74.0"
CRON_CONF="/etc/storage/cron/crontabs/$(nvram get http_username)"
redirmaxRAM="65536"

autorec=$(nvram get ss_watchcat_autorec)
extbpid=$(expr 100000 + $$)
logmark=${extbpid:1}

infor(){
	issjfinfor=$(tail -n 1 $CONF_DIR/issjfinfor)
	[ -n "$issjfinfor" ] && echo "$issjfinfor" || echo "???──???:???──[???]"
}

loger(){
	sed -i '/'$(date "+%Y-%m-%d_%H:%M:%S")'_'$logmark''$1'/d' $ssp_log_file
	sed -i '1i\'$(date "+%Y-%m-%d_%H:%M:%S")'_'$logmark''$1'' $ssp_log_file
}

count(){
	[ -e $1 ] || echo "0" > $1
	counts_temp=$(tail -n 1 $1)
	counts_form=${counts_temp:0}
	if [ "$2" = "+-" ] || [ "$2" = "-+" ]; then
		echo "$3" > $1
	elif [ "$2" = "++" ]; then
		form_counts=$(expr $counts_form + $3)
		echo "$form_counts" > $1
	elif [ "$2" = "--" ]; then
		form_counts=$(expr $counts_form - $3)
		[ $form_counts -le 0 ] && echo "0" > $1 || echo "$form_counts" > $1
	else
		echo "$counts_form"
	fi
}

wcram(){
	for sspredirPID in $(pidof ss-redir); do
		sspredirRSS=$(cat /proc/$sspredirPID/status | grep 'VmRSS' | \
		sed 's/[[:space:]]//g' | sed 's/kB//g' | awk -F: '{print $2}')
		[ $sspredirRSS -ge $redirmaxRAM ] && count $errorcount +- 5
	done
	return 0
}

goout(){
	!(cat "$statusfile" 2>/dev/null | grep -q 'watchcat_stop_ssp') && wcram && rm -rf $statusfile
	loger "┌──$(infor)"
	exit 0
}

daten(){
	dateS=$(date +%S) && [ $dateS -ge 55 ] && echo "daten_stopwatchcat" > $statusfile
	$(cat "$statusfile" 2>/dev/null | grep -q 'daten_stopwatchcat') && goout
	if [ "$1" = "-l" ]; then
		datel=$(expr 60 - $dateS) && echo "$datel"
	elif [ "$1" = "-m" ]; then
		date_M=$(date +%M) && datem=${date_M:1} && echo "$datem"
	else
		return 0
	fi
}

scout(){
	curl "$1" -L -I -k -s --connect-timeout 4 --max-time 4 --speed-time 4 --speed-limit 4 \
	-A "$user_agent" | grep -q -s -i "HTTP/1.1 200 OK" || return 1
}

watchcat_stop_ssp(){
	!(cat "$statusfile" 2>/dev/null | grep -q 'watchcat_stop_ssp') || return 1
	[ $(count $errorcount) -ge 1 ] || return 1
	STO_LOG="发现异常!!!暂时停止代理" && loger "├──$STO_LOG" && logger -st "SSP[$$]WARNING" "$STO_LOG"
	count $netdpcount +- 0 && echo "watchcat_stop_ssp" > $statusfile
	/usr/bin/shadowsocks.sh stop &>/dev/null && goout
}

watchcat_start_ssp(){
	$(cat "$statusfile" 2>/dev/null | grep -q 'watchcat_stop_ssp') || return 1
	count $errorcount -- 1 && [ $(count $errorcount) -le 0 ] || goout
	scout "$chn_domain" || scout "$chn_domain" || goout
	[ "$(nvram get ss_enable)" = "1" ] && !(pidof ss-redir &>/dev/null) || return 1
	!(iptables-save -c | grep -q "SSP_") && !(ipset list -n | grep -q 'gfwlist') || return 1
	STA_LOG="恢复正常!!!重新启动代理" && loger "├──$STA_LOG" && logger -st "SSP[$$]watchcat" "$STA_LOG"
	count $netdpcount +- 0 && echo "watchcat_start_ssp" > $statusfile
	/usr/bin/shadowsocks.sh start &>/dev/null && return 0 || goout
}

watchcat_restart_ssp(){
	$(cat "$statusfile" 2>/dev/null | grep -q 'check_restart_ssp') || return 1
	[ "$1" = "1" ] && echo "watchcat_restart_ssp_runn" > $statusfile && \
	RES_LOG="代理进程未运行!开始重启"
	[ "$1" = "2" ] && echo "watchcat_restart_ssp_rule" > $statusfile && \
	RES_LOG="没有防火墙规则!开始重启"
	[ "$1" = "3" ] && echo "watchcat_restart_ssp_rule" > $statusfile && \
	RES_LOG="找不到地址集合!开始重启"
	loger "├──$RES_LOG" && logger -st "SSP[$$]WARNING" "$RES_LOG"
	count $netdpcount +- 0 && /usr/bin/shadowsocks.sh restart &>/dev/null && return 0 || goout
}

amsgetnotset(){
	daten
	tail -n +1 /tmp/syslog.log | grep 'ipnotset' >> $CONF_DIR/amsnotset.tmp
	cat $CONF_DIR/amsnotset.tmp | sed 's/ DST=/-/g' | sed 's/ LEN=/-/g' | \
	awk -F- '!a[$2]++{print $2}' >> $CONF_DIR/amsallexp.tmp && rm -rf $CONF_DIR/amsnotset.tmp
	cat $CONF_DIR/amsallexp.txt >> $CONF_DIR/amsallexp.tmp && rm -rf $CONF_DIR/amsallexp.txt
	mv -f $CONF_DIR/amsallexp.tmp $CONF_DIR/amsallexp.txt && rm -rf $CONF_DIR/amsallexp.tmp
}

reconnection(){
	[ $(daten -l) -ge 17 ] && echo "watchcat_reconnection" > $statusfile || goout
	scout "$gfw_domain" || scout "$gfw_domain"
	if [ "$?" = "0" ]; then
		loger "├──连接正常" && count $netdpcount +- 0 && goout || goout
	elif [ "$?" = "1" ]; then
		scout "$chn_domain" || scout "$chn_domain"
		if [ "$?" = "0" ]; then
			[ "$autorec" = "1" ] && count $netdpcount ++ 1 && \
			[ $(count $netdpcount) -ge 3 ] && count $errorcount ++ 1 && goout || goout
		elif [ "$?" = "1" ]; then
			count $errorcount ++ 1 && goout || goout
		else
			goout
		fi
	else
		goout
	fi
}

automaticset(){
	!(cat "$statusfile" 2>/dev/null | grep -q 'daten_stopwatchcat') && \
	echo "watchcat_automaticset" > $statusfile && inams=0 || inams=50
	if [ "$autorec" = "1" ] || [ "$(daten -m)" = "0" ]; then
		bouts=38
	else
		bouts=50
	fi
	while [ $inams -lt $bouts ]; do
		amsgetnotset
		for ip in $(cat $CONF_DIR/amsallexp.txt); do
			$(ping -c 1 -s 36 -W 1 -w 1 -q $ip | grep -q '1 packets received')
			if [ "$?" = "0" ]; then
				ipset add chnlist $ip &>/dev/null
				ipset del gfwlist $ip &>/dev/null
				sed -i '/'$ip'/d' $CONF_DIR/GFWblackip.conf
				sed -i '/'$ip'/d' $CONF_DIR/CHNwhiteip.conf
				echo $ip >> $CONF_DIR/CHNwhiteip.conf
			else
				ipset add gfwlist $ip &>/dev/null
				ipset del chnlist $ip &>/dev/null
				sed -i '/'$ip'/d' $CONF_DIR/CHNwhiteip.conf
				sed -i '/'$ip'/d' $CONF_DIR/GFWblackip.conf
				echo $ip >> $CONF_DIR/GFWblackip.conf
			fi
			sed -i '/'$ip'/d' $CONF_DIR/amsallexp.set
			echo $ip >> $CONF_DIR/amsallexp.set
			sed -i '/'$ip'/d' $CONF_DIR/amsallexp.txt
			sed -i '/ DST='$ip'/d' /tmp/syslog.log || goout
			daten
		done
		rm -rf $CONF_DIR/amsallexp.txt
		sleep 1
		inams=$((inams+1))
	done
}

check_log_file(){
	$(cat "$CRON_CONF" 2>/dev/null | grep -q "ss-watchcat.sh") && cronboot="1" || cronboot="0"
	[ "$cronboot" = "1" ] || rm -rf $ssp_log_file
	[ -e $ssp_log_file ] && loger "└──$(infor)" || \
	echo "$(date "+%Y-%m-%d_%H:%M:%S")_$logmark└──$(infor)" > $ssp_log_file
	[ $(stat -c %s $ssp_log_file) -lt $max_log_bytes ] || \
	sed -i '/'$(tail -n 1 $ssp_log_file | awk -F: '{print $1}')'/d' $ssp_log_file
	[ $(stat -c %s $redir_log_file) -lt $max_log_bytes ] || \
	echo "$(date "+%Y-%m-%d_%H:%M:%S")_$logmark├──日志文件过大!清空日志文件" > $redir_log_file
	[ "$cronboot" = "1" ] || goout
	return 0
}

check_cat_sole(){
	for watchcatPID in $(pidof ss-watchcat.sh); do
		[ "$watchcatPID" != "$$" ] && kill -9 $watchcatPID
	done
	return 0
}

check_restart_ssp(){
	echo "check_restart_ssp" > $statusfile
	!(ipset list -n | grep -q 'gfwlist') && watchcat_restart_ssp 3
	!(iptables-save -c | grep -q "SSP_") && watchcat_restart_ssp 2
	!(pidof ss-redir &>/dev/null) && watchcat_restart_ssp 1
	return 0
}

check(){
	$(cat "$statusfile" 2>/dev/null | grep -q 'watchcat_automaticset') && \
	echo "daten_stopwatchcat" > $statusfile
	check_log_file
	check_cat_sole
	ulimit -n 65536
	watchcat_stop_ssp || watchcat_start_ssp || check_restart_ssp
}

check && automaticset && reconnection || goout
