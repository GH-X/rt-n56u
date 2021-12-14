#!/bin/sh

statusfile="/tmp/sspstatus.tmp"
log_file="/tmp/ss-watchcat.log"
use_log_file="/tmp/ss-redir.log"
max_log_bytes="1000000"
gfw_domain="https://www.youtube.com/"
chn_domain="https://www.taobao.com/"
user_agent="Mozilla/5.0 (X11; Linux; rv:74.0) Gecko/20100101 Firefox/74.0"

goout(){
	rm -rf $statusfile
	exit $1
}

loger(){
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
	[ "$1" = "0" ] && STO_LOG="网络异常!暂时关闭代理" && echo "watchcat_stop_ssp" > $statusfile
	[ "$1" = "1" ] && STO_LOG="连接异常!暂时关闭代理" && echo "watchcat_stop_ssp" > $statusfile
	[ "$1" = "2" ] && STO_LOG="没有启用代理!关闭代理" && echo "watchcat_disable_ssp" > $statusfile
	loger "$STO_LOG" && logger -st "SSP[$$]WARNING" "$STO_LOG"
	[ -x /usr/bin/dns-forwarder.sh ] && /usr/bin/dns-forwarder.sh stop &>/dev/null
	/usr/bin/ss-tunnel.sh stop &>/dev/null
	/usr/bin/shadowsocks.sh stop &>/dev/null
}

watchcat_start_ssp(){
	echo "watchcat_start_ssp" > $statusfile
	loger "开启代理" && logger -st "SSP[$$]watchcat" "开启代理"
	[ -x /usr/bin/dns-forwarder.sh ] && \
	[ "$(nvram get dns_forwarder_enable)" = "1" ] && /usr/bin/dns-forwarder.sh start &>/dev/null
	[ "$(nvram get ss-tunnel_enable)" = "1" ] && /usr/bin/ss-tunnel.sh start &>/dev/null
	/usr/bin/shadowsocks.sh start &>/dev/null
}

watchcat_restart_ssp(){
	echo "watchcat_restart_ssp" > $statusfile
	[ "$1" = "0" ] && RES_LOG="连接异常!开始重启"
	[ "$1" = "1" ] && RES_LOG="代理程序未运行!开始重启"
	[ "$1" = "2" ] && RES_LOG="没有防火墙规则!开始重启"
	[ "$1" = "3" ] && RES_LOG="找不到地址集合!开始重启"
	loger "$RES_LOG" && logger -st "SSP[$$]WARNING" "$RES_LOG"
	[ -x /usr/bin/dns-forwarder.sh ] && \
	[ "$(nvram get dns_forwarder_enable)" = "1" ] && /usr/bin/dns-forwarder.sh restart &>/dev/null
	[ "$(nvram get ss-tunnel_enable)" = "1" ] && /usr/bin/ss-tunnel.sh restart &>/dev/null
	/usr/bin/shadowsocks.sh restart &>/dev/null
}

check(){
	[ -e $log_file ] || echo "$(date "+%Y-%m-%d_%H:%M:%S")_watchcat_首次启动!创建日志" > $log_file
	[ $(stat -c %s $log_file) -lt $max_log_bytes ] || \
	echo "$(date "+%Y-%m-%d_%H:%M:%S")_watchcat_日志文件过大!清空日志文件" > $log_file
	$(cat "$statusfile" 2>/dev/null | grep -q 'watchcat_stop_ssp') && \
	[ "$(nvram get ss_enable)" = "1" ] && !(pidof ss-redir &>/dev/null) && \
	!(iptables-save -c | grep -q "SSP_") && !(ipset list -n | grep -q 'gfwlist') && \
	watchcat_start_ssp
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
			loger "连接正常" && goout 0
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
