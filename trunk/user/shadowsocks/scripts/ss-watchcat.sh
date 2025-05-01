#!/bin/sh

CONF_DIR="/tmp/SSP"
ETCS_DIR="/etc/storage"
CRON_CONF="$ETCS_DIR/cron/crontabs/$(nvram get http_username)"
aiderstart="$CONF_DIR/aiderstart"
socksstart="$CONF_DIR/socksstart"
localstart="$CONF_DIR/localstart"
scoresfile="$CONF_DIR/scoresfile"
ssp_log_file="/tmp/ss-watchcat.log"
local_log_file="/tmp/ss-local.log"
max_log_bytes="100000"
local_RUNOUT="0"
local_bin="ss-local"

tl_timeout=$(nvram get di_timeout)
timeslimit=$(expr $tl_timeout \* 3)
autorec=$(nvram get ss_watchcat_autorec)
extbpid=$(expr 100000 + $$)
logmark=${extbpid:1}

loger(){
	sed -i '1i\'$(date "+%Y-%m-%d_%H:%M:%S")'_'$logmark''$1'' $ssp_log_file
}

count(){
	nvram_value_temp=$(nvram get $1)
	nvram_value=${nvram_value_temp:0}
	if [ "$2" == "+-" ] || [ "$2" == "-+" ]; then
		nvram set $1=$3
	elif [ "$2" == "++" ]; then
		count_value=$(expr $nvram_value + $3)
		[ $count_value -ge $4 ] && nvram set $1=$4 || nvram set $1=$count_value
	elif [ "$2" == "--" ]; then
		count_value=$(expr $nvram_value - $3)
		[ $count_value -le $4 ] && nvram set $1=$4 || nvram set $1=$count_value
	else
		echo "$nvram_value"
	fi
}

infor(){
	serverinfor=$(nvram get server_infor)
	[ "$serverinfor" != "snum──type──addr:port" ] && \
	echo "$serverinfor──$(count link_times)" || echo "snum──type──addr:port──time"
}

score(){
	infor=$(infor) && [ "$infor" != "snum──type──addr:port──time" ] || return 0
	infornode=$(echo "$infor" | awk -F── 'BEGIN{OFS="──"}{print $1,$2,$3}')
	infortime=$(echo "$infor" | awk -F── '{print $4}')
	if $(grep -q "$infornode" $scoresfile); then
		scoretime=$(grep "$infornode" $scoresfile | awk -F── '{print $4}')
		[ "$infortime" == "" ] && infortime="$scoretime" && count link_times +- $infortime
		[ $scoretime -ge $infortime ] && lognode="1" || lognode="0"
		sed -i '/^'$infornode'/d' $scoresfile
	else
		lognode="1"
	fi
	echo "$infornode──$infortime" >> $scoresfile
	sort -u -n -r $scoresfile > $CONF_DIR/scoresfile.tmp && mv -f $CONF_DIR/scoresfile.tmp $scoresfile
	[ "$lognode" == "1" ] && while read line
	do
		scorenode=$(echo "$line" | awk -F── 'BEGIN{OFS="──"}{print $1,$2,$3}')
		node_snum=$(echo "$line" | awk -F── '{print $1}')
		node_type=$(echo "$line" | awk -F── '{print $2}')
		node_addr=$(echo "$line" | awk -F── '{print $3}' | awk -F: '{print $1}')
		node_port=$(echo "$line" | awk -F── '{print $3}' | awk -F: '{print $2}')
		node_time=$(echo "$line" | awk -F── '{print $4}')
		loger "├────连接时长:$node_time"
		loger "├────节点端口:$node_port"
		loger "├────节点地址:$node_addr"
		loger "├────节点类型:$node_type"
		[ "$scorenode" == "$infornode" ] && \
		loger "├──当前节点:$node_snum" || loger "├──历史节点:$node_snum"
	done < $scoresfile
}

godet(){
	if !(ipset list -n | grep -q 'servers') || !(ipset list -n | grep -q 'private') || \
	!(ipset list -n | grep -q 'gfwlist') || !(ipset list -n | grep -q 'chnlist'); then
		count wait_times ++ 1 5 && count turn_json_file +- 0 && count start_rules +- 1
	fi
	[ $local_RUNOUT -ge 3 ] && count wait_times ++ 1 5 && count turn_json_file +- 1
	[ $(count wait_times) -le 0 ] && score
	nvram set watchcat_state=stopped
}

goout(){
	!(nvram get watchcat_state | grep -q 'watchcat_stop_ssp') && godet
	loger "┌──$(infor)"
	exit 0
}

dndet(){
	[ -x "$aiderstart" ] && if $(tail -n +1 $aiderstart | grep -q 'smartdns'); then
		$(pidof smartdns &>/dev/null) || $(pidof smartdns &>/dev/null) || \
		$(pidof smartdns &>/dev/null) || $(pidof smartdns &>/dev/null) || \
		$($aiderstart && loger "├──辅助解析中止!!!启动进程")
	fi
	[ -x "$socksstart" ] && if $(tail -n +1 $socksstart | grep -q 'ipt2socks'); then
		$(pidof ipt2socks &>/dev/null) || $(pidof ipt2socks &>/dev/null) || \
		$(pidof ipt2socks &>/dev/null) || $(pidof ipt2socks &>/dev/null) || \
		$($socksstart && loger "├──本地代理中止!!!启动进程")
	fi
	$(pidof dnsmasq &>/dev/null) || $(pidof dnsmasq &>/dev/null) || \
	$(pidof dnsmasq &>/dev/null) || $(pidof dnsmasq &>/dev/null) || \
	!(restart_dhcpd && loger "├──解析进程中止!!!启动进程")
	$(pidof $local_bin &>/dev/null) || $(pidof $local_bin &>/dev/null) || \
	$(pidof $local_bin &>/dev/null) || $(pidof $local_bin &>/dev/null) || \
	!($localstart && loger "├──代理进程中止!!!启动进程") || local_RUNOUT=$((local_RUNOUT+1))
}

daten(){
	dateS=$(date +%S) && [ $dateS -ge 55 ] && nvram set watchcat_state=stop_watchcat
	if [ "$1" == "-l" ]; then
		datel=$(expr 60 - $dateS) && echo "$datel"
	elif [ "$1" == "-m" ]; then
		date_M=$(date +%M) && datem=${date_M:1} && echo "$datem"
	else
		!(nvram get watchcat_state | grep -q 'stop_watchcat') || return 1
	fi
}

sleeptime(){
	sleep $1
	return $2
}

notify_detect_internet(){
	killall -q -SIGUSR2 detect_internet
}

watchcat_stop_ssp(){
	!(nvram get watchcat_state | grep -q 'watchcat_stop_ssp') || return 0
	[ $(count wait_times) -ge 1 ] || return 0
	score
	STO_LOG="发现异常!!!暂时停止代理" && loger "├──$STO_LOG" && logger -st "SSP[$$]WARNING" "$STO_LOG"
	nvram set watchcat_state=watchcat_stop_ssp && /usr/bin/shadowsocks.sh stop &>/dev/null && return 1
}

watchcat_start_ssp(){
	$(nvram get watchcat_state | grep -q 'watchcat_stop_ssp') || return 0
	notify_detect_internet && sleeptime $timeslimit 0 && [ "$(count link_internet)" == "1" ] || return 1
	count wait_times -- 1 0 && [ $(count wait_times) -le 0 ] || return 1
	[ "$(count ss_enable)" == "1" ] || /usr/bin/shadowsocks.sh stop &>/dev/null
	!(pidof $local_bin &>/dev/null) || /usr/bin/shadowsocks.sh stop &>/dev/null
	STA_LOG="恢复正常!!!重新启动代理" && loger "├──$STA_LOG" && logger -st "SSP[$$]WARNING" "$STA_LOG"
	count link_error +- 0 && count wait_times +- 0 && nvram set watchcat_state=watchcat_start_ssp
	/usr/bin/shadowsocks.sh start &>/dev/null || return 1
}

reconnection(){
	daten || return 1
	[ "$recyesornot" == "1" ] || sleeptime 1 1 || return 0
	recyesornot="0" && count link_times ++ 1 525600
	[ $(count link_error) -ge 1 ] || [ $(count link_internet) -ne 2 ] || sleeptime 1 1 || return 0
	notify_detect_internet && sleeptime $timeslimit 0
	if [ "$(count link_internet)" == "2" ]; then
		count link_error +- 0
	elif [ "$(count link_internet)" == "1" ]; then
		if [ "$autorec" == "1" ]; then
			count link_error ++ 1 9
			if [ $(count link_error) -ge 2 ]; then
				count wait_times ++ 1 5 && count turn_json_file +- 1
				watchcat_stop_ssp || watchcat_start_ssp || return 1
			else
				count link_times -- 1 0
			fi
		else
			count link_error ++ 1 9
			if [ $(count link_error) -ge 9 ]; then
				count wait_times ++ 1 5 && count turn_json_file +- 0
				watchcat_stop_ssp || return 1
			else
				count link_times -- 1 0
			fi
		fi
	elif [ "$(count link_internet)" == "0" ]; then
		count wait_times ++ 1 5 && count turn_json_file +- 0
		watchcat_stop_ssp || return 1
	else
		return 0
	fi
}

automaticset(){
	daten && nvram set watchcat_state=watchcat_automaticset && inams=10 || inams=61
	recyesornot="1" && bouts=$(daten -l)
	while [ $inams -le $bouts ]; do
		Stime=$(daten -l) && ST=${Stime:0}
		dndetinams=${inams:1}
		if [ "$dndetinams" == "0" ] || [ "$inams" == "$bouts" ]; then
			dndet
		fi
		reconnection || inams=61
		Etime=$(daten -l) && ET=${Etime:0}
		UT=$(expr $ST - $ET)
		inams=$((inams+UT))
	done
}

check_cat_file(){
	$(grep -q "ss-watchcat.sh" $CRON_CONF) && cronboot="1" || cronboot="0"
	[ "$cronboot" == "1" ] || rm -rf $ssp_log_file
	$([ -e $ssp_log_file ] && loger "└──$(infor)") || \
	echo "$(date "+%Y-%m-%d_%H:%M:%S")_$logmark└──$(infor)" > $ssp_log_file
	[ ! -s $ssp_log_file ] && count wait_times +- 2 && count turn_json_file +- 0
	touch $local_log_file
	[ ! -e $scoresfile ] && score
	[ $(daten -l) -ge $(expr $timeslimit \* 2 + 9) ] || return 1
	while [ $(stat -c %s $ssp_log_file) -gt $max_log_bytes ]; do
		sed -i '/'$(tail -n 1 $ssp_log_file | awk -F: '{print $1":"$2}')'/d' $ssp_log_file
	done
	while [ $(stat -c %s $local_log_file) -gt $max_log_bytes ]; do
		sed -i '9d' $local_log_file
	done
	[ "$cronboot" == "1" ] && return 0 || return 1
}

check_cat_sole(){
	$(nvram get watchcat_state | grep -q 'watchcat_automaticset') && \
	nvram set watchcat_state=stop_watchcat && sleeptime 2 0 && nvram set watchcat_state=check_cat_sole
	for watchcatPID in $(pidof ss-watchcat.sh); do
		[ "$watchcatPID" != "$$" ] && kill -9 $watchcatPID
	done
}

check(){
	echo -1000 > /proc/$$/oom_score_adj
	ulimit -t 60
	check_cat_file || goout || return 1
	check_cat_sole
	watchcat_stop_ssp || goout || return 1
	watchcat_start_ssp || goout || return 1
	automaticset || goout || return 1
	goout
}

check

