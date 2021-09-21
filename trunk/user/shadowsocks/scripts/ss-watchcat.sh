#!/bin/sh

pidfile="/var/ss-watchcat.pid"
log_file="/tmp/ss-watchcat.log"
use_log_file="/tmp/ss-redir.log"
max_log_bytes="1000000"
chn_domain="www.qq.com"
gfw_domain="https://www.youtube.com/"

goout(){
	rm -rf $pidfile
	exit $1
}

loger(){
	sed -i '1i\'$(date "+%Y-%m-%d_%H:%M:%S")'_watchcat_'$1'' $log_file
}

detect_gfw(){
	loger "检测代理" && wget --spider --quiet --timeout=3 $gfw_domain &>/dev/null
	return $?
}

detect_chn(){
	loger "检测网络" && /bin/ping -c 3 $chn_domain -w 5 &>/dev/null
	return $?
}

stop_ssp(){
	logger -st "SSP[$$]watchcat" "代理异常!关闭SSP代理" && loger "代理异常!关闭SSP代理" && \
	nvram set ss_enable=0 && /usr/bin/shadowsocks.sh stop &>/dev/null && goout 1
}

restart_ssp(){
	[ -x /usr/bin/dns-forwarder.sh ] && [ "$(nvram get dns_forwarder_enable)" = "1" ] && \
	loger "代理异常!重启DNS服务" && /usr/bin/dns-forwarder.sh restart &>/dev/null
	[ "$(nvram get ss-tunnel_enable)" = "1" ] && loger "代理异常!重启DNS隧道" && \
	/usr/bin/ss-tunnel.sh restart &>/dev/null
	logger -st "SSP[$$]watchcat" "代理异常!重启SSP代理" && loger "代理异常!重启SSP代理" && \
	/usr/bin/shadowsocks.sh restart &>/dev/null
}

check(){
	[ -e $pidfile ] && kill -9 $(cat $pidfile) &>/dev/null
	echo "$$" > $pidfile
	[ -e $log_file ] || echo "$(date "+%Y-%m-%d_%H:%M:%S")_watchcat_首次启动!创建日志" > $log_file
	[ $(stat -c %s $log_file) -lt $max_log_bytes ] || \
	echo "$(date "+%Y-%m-%d_%H:%M:%S")_watchcat_日志文件过大!清空日志文件" > $log_file
	[ "$(nvram get ss_enable)" = "1" ] || goout 0
	!(pidof ss-redir &>/dev/null) && loger "代理程序未运行" && restart_ssp
	!(iptables-save -c | grep -q "SSP_") && loger "没有防火墙规则" && restart_ssp
	!(ipset list -n | grep -q "gfwlist") && loger "找不到地址集合" && restart_ssp
	[ $(stat -c %s $use_log_file) -lt $max_log_bytes ] || \
	echo "$(date "+%Y-%m-%d_%H:%M:%S")_watchcat_日志文件过大!清空日志文件" > $use_log_file
	[ "$(nvram get ss_watchcat)" = "1" ] || goout 0
}

detect_ssp(){
	tries=0
	while [ $tries -le 4 ]; do
		if [ $tries -eq 0 ]; then
			waittime="sleep 15"
		elif [ $tries -eq 1 ]; then
			waittime="sleep 10"
		elif [ $tries -eq 2 ]; then
			waittime="sleep 15"
			restart_ssp
		elif [ $tries -eq 3 ]; then
			waittime="sleep 10"
		elif [ $tries -eq 4 ]; then
			stop_ssp
		fi
		$waittime && detect_gfw
		if [ "$?" = "0" ]; then
			loger "代理正常" && tries=$((tries+1))
			[ $tries -eq 2 ] && goout 0
			[ $tries -eq 4 ] && goout 0
		else
			detect_chn
			if [ "$?" = "0" ]; then
				tries=$((tries+1))
			else
				loger "网络异常" && tries=$((tries+1))
				[ $tries -eq 2 ] && goout 1
				[ $tries -eq 4 ] && goout 1
			fi
		fi
	done
}

check && detect_ssp || goout 1
