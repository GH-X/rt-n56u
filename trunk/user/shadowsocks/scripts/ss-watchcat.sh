#!/bin/sh

statusfile="/tmp/sspstatus.tmp"
log_file="/tmp/ss-watchcat.log"
use_log_file="/tmp/ss-redir.log"
max_log_bytes="1000000"
gfw_domain="https://www.google.com/"
chn_domain="https://www.taobao.com/"
user_agent="Mozilla/5.0 (X11; Linux; rv:74.0) Gecko/20100101 Firefox/74.0"
CRON_CONF="/etc/storage/cron/crontabs/$(nvram get http_username)"

amstimenodes(){
	currentminute=$(date +%M) && timenode=${currentminute:1}
	[ $timenode -eq 9 ] && echo "stop_ams" > $statusfile
	echo "$timenode"
}

dcron(){
	$(cat "$CRON_CONF" 2>/dev/null | grep "ss-watchcat.sh" | grep -v -q "/$1") && \
	sed -i '/ss-watchcat.sh/d' $CRON_CONF && \
	echo "*/$1 * * * * nohup /usr/bin/ss-watchcat.sh 2>/dev/null &" >> $CRON_CONF && restart_crond
}

goout(){
	[ $(amstimenodes) -eq 9 ] && dcron 10
	rm -rf $statusfile
	exit $1
}

loger(){
	sed -i '/'$(date "+%Y-%m-%d_%H:%M:%S")'_watchcat_'$1'/d' $log_file
	sed -i '1i\'$(date "+%Y-%m-%d_%H:%M:%S")'_watchcat_'$1'' $log_file
}

detect_gfw(){
	echo "watchcat_detect_gfw" > $statusfile && loger "检测连接" && \
	curl "$gfw_domain" -k -s --connect-timeout 2 --max-time 4 --retry 2 --retry-max-time 8 \
	-A "$user_agent" | grep -q -s -i "^<!DOCTYPE" || return 1
}

detect_chn(){
	echo "watchcat_detect_chn" > $statusfile && loger "检测网络" && \
	curl "$chn_domain" -k -s --connect-timeout 2 --max-time 4 --retry 2 --retry-max-time 8 \
	-A "$user_agent" | grep -q -s -i "^<!DOCTYPE" || return 1
}

watchcat_stop_ssp(){
	[ "$1" = "0" ] && STO_LOG="网络异常!暂时停止代理" && echo "watchcat_stop_ssp" > $statusfile
	[ "$1" = "1" ] && STO_LOG="连接异常!暂时停止代理" && echo "watchcat_stop_ssp" > $statusfile
	[ "$1" = "2" ] && STO_LOG="没有启用代理!关闭代理" && echo "watchcat_disable_ssp" > $statusfile
	[ "$1" != "2" ] && dcron 10
	loger "$STO_LOG" && logger -st "SSP[$$]WARNING" "$STO_LOG"
	[ -x /usr/bin/dns-forwarder.sh ] && /usr/bin/dns-forwarder.sh stop &>/dev/null
	/usr/bin/ss-tunnel.sh stop &>/dev/null
	/usr/bin/shadowsocks.sh stop &>/dev/null
}

watchcat_start_ssp(){
	echo "watchcat_start_ssp" > $statusfile
	STA_LOG="暂停结束!重新启动代理"
	loger "$STA_LOG" && logger -st "SSP[$$]watchcat" "$STA_LOG"
	[ -x /usr/bin/dns-forwarder.sh ] && \
	[ "$(nvram get dns_forwarder_enable)" = "1" ] && /usr/bin/dns-forwarder.sh start &>/dev/null
	[ "$(nvram get ss-tunnel_enable)" = "1" ] && /usr/bin/ss-tunnel.sh start &>/dev/null
	/usr/bin/shadowsocks.sh start &>/dev/null
}

watchcat_restart_ssp(){
	[ "$1" = "0" ] && echo "watchcat_restart_ssp_link" > $statusfile && RES_LOG="连接异常!重启代理进程"
	[ "$1" = "1" ] && echo "watchcat_restart_ssp_runn" > $statusfile && RES_LOG="代理进程未运行!开始重启"
	[ "$1" = "2" ] && echo "watchcat_restart_ssp_rule" > $statusfile && RES_LOG="没有防火墙规则!开始重启"
	[ "$1" = "3" ] && echo "watchcat_restart_ssp_rule" > $statusfile && RES_LOG="找不到地址集合!开始重启"
	loger "$RES_LOG" && logger -st "SSP[$$]WARNING" "$RES_LOG"
	[ -x /usr/bin/dns-forwarder.sh ] && \
	[ "$(nvram get dns_forwarder_enable)" = "1" ] && /usr/bin/dns-forwarder.sh restart &>/dev/null
	[ "$(nvram get ss-tunnel_enable)" = "1" ] && /usr/bin/ss-tunnel.sh restart &>/dev/null
	/usr/bin/shadowsocks.sh restart &>/dev/null
}

amsgetnotset(){
	amstimenodes
	$(cat "$statusfile" 2>/dev/null | grep -q 'stop_ams') && \
	loger "关闭地址集合自动配置" && goout 0
	(while grep 'ipnotset'; do
		cat /tmp/amsnotset.tmp | sed 's/ DST=/-/g' | sed 's/ LEN=/-/g' | awk -F- '!a[$2]++{print $2}'\
		 >> /tmp/amsallexp.txt
	done < /tmp/syslog.log > /tmp/amsnotset.tmp)&
	wait
	[ -e /tmp/amsallexp.txt ] && return 0 || return 1
}

automaticset(){
	!(cat "$statusfile" 2>/dev/null | grep -q 'stop_ams') && \
	echo "watchcat_automaticset" > $statusfile || goout 0
	!(cat "$CRON_CONF" 2>/dev/null | grep -q "ss-watchcat.sh") && bout="0"
	[ "$(nvram get ss_mode)" != "0" ] && loger "开启地址集合自动配置" && \
	inams=0 || inams=${bout:=540}
	while [ $inams -lt ${bout:=540} ]; do
		amsgetnotset
		if [ "$?" = "0" ]; then
			for ip in $(cat /tmp/amsallexp.txt 2>/dev/null); do
				$(ping -c 1 -s 36 -W 1 -w 1 -q $ip | grep -q '1 packets received')
				if [ "$?" = "0" ]; then
					ipset add chnlist $ip &>/dev/null
					ipset del gfwlist $ip &>/dev/null
					sed -i '/'$ip'/d' /tmp/GFWblackip.conf
					sed -i '/'$ip'/d' /tmp/CHNwhiteip.conf
					echo $ip >> /tmp/CHNwhiteip.conf
				else
					ipset add gfwlist $ip &>/dev/null
					ipset del chnlist $ip &>/dev/null
					sed -i '/'$ip'/d' /tmp/CHNwhiteip.conf
					sed -i '/'$ip'/d' /tmp/GFWblackip.conf
					echo $ip >> /tmp/GFWblackip.conf
				fi
				sed -i '/'$ip'/d' /tmp/amsallexp.set
				echo $ip >> /tmp/amsallexp.set
				sed -i '/'$ip'/d' /tmp/syslog.log
				amstimenodes
				$(cat "$statusfile" 2>/dev/null | grep -q 'stop_ams') && \
				loger "关闭地址集合自动配置" && goout 0
			done
			rm -rf /tmp/amsnotset.tmp
			rm -rf /tmp/amsallexp.txt
			inams=$((inams+1))
		elif [ "$?" = "1" ]; then
			rm -rf /tmp/amsnotset.tmp
			sleep 1
			inams=$((inams+1))
		fi
	done
	loger "关闭地址集合自动配置" && goout 0
}

check(){
	$(cat "$statusfile" 2>/dev/null | grep -q 'watchcat_automaticset') && echo "stop_ams" > $statusfile
	[ -e $log_file ] || echo "$(date "+%Y-%m-%d_%H:%M:%S")_watchcat_首次启动!创建日志" > $log_file
	[ $(stat -c %s $log_file) -lt $max_log_bytes ] || \
	echo "$(date "+%Y-%m-%d_%H:%M:%S")_watchcat_日志文件过大!清空日志文件" > $log_file
	$(cat "$statusfile" 2>/dev/null | grep -q 'watchcat_stop_ssp') && \
	[ "$(nvram get ss_enable)" = "1" ] && !(pidof ss-redir &>/dev/null) && \
	!(iptables-save -c | grep -q "SSP_") && !(ipset list -n | grep -q 'gfwlist') && \
	watchcat_start_ssp
	sleep 1
	[ -e $statusfile ] && goout 0
	echo "watchcat_check" > $statusfile
	[ "$(nvram get ss_enable)" = "1" ] || watchcat_stop_ssp 2
	$(cat "$statusfile" 2>/dev/null | grep -q 'watchcat_check') && \
	!(pidof ss-redir &>/dev/null) && watchcat_restart_ssp 1
	$(cat "$statusfile" 2>/dev/null | grep -q 'watchcat_check') && \
	!(iptables-save -c | grep -q "SSP_") && watchcat_restart_ssp 2
	$(cat "$statusfile" 2>/dev/null | grep -q 'watchcat_check') && \
	!(ipset list -n | grep -q 'gfwlist') && watchcat_restart_ssp 3
	[ $(stat -c %s $use_log_file) -lt $max_log_bytes ] || \
	echo "$(date "+%Y-%m-%d_%H:%M:%S")_watchcat_日志文件过大!清空日志文件" > $use_log_file
	[ "$(nvram get ss_watchcat)" = "1" ] || goout 0
}

detect_ssp(){
	tries=1
	while [ $tries -le 3 ]; do
		if [ $tries -eq 1 ]; then
			loger "开始检测"
		elif [ $tries -eq 2 ]; then
			watchcat_restart_ssp 0
		elif [ $tries -eq 3 ]; then
			watchcat_stop_ssp 1
		fi
		[ "$?" = "0" ] && sleep 1 && detect_gfw
		if [ "$?" = "0" ]; then
			loger "连接正常" && automaticset && goout 0
		else
			loger "连接异常" && detect_chn
			if [ "$?" = "0" ]; then
				loger "网络正常" && tries=$((tries+1))
			else
				loger "网络异常" && watchcat_stop_ssp 0
			fi
		fi
	done
}

check && detect_ssp || goout 1
