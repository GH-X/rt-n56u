#!/bin/sh

[ "$(nvram get ss-tunnel_enable)" = "1" ] || exit 0

ss_bin=ss-local
ss_json_file="/tmp/ss-local.json"
ss_proc="/var/ss-tunnel"
#/usr/bin/ss-local -> /var/ss-tunnel -> /usr/bin/ss-orig-tunnel or /usr/bin/ssr-local

ss_type=$(nvram get ss_type)
ssp_type=${ss_type:0} # 0=ss 1=ssr 2=trojan

if [ "$ssp_type" = "0" ]; then
	ln -sf /usr/bin/ss-orig-tunnel $ss_proc
elif [ "$ssp_type" = "1" ]; then
	ss_protocol=$(nvram get ss_protocol)
	ss_proto_param=$(nvram get ss_proto_param)
	ss_obfs=$(nvram get ss_obfs)
	ss_obfs_param=$(nvram get ss_obfs_param)
	ln -sf /usr/bin/ssr-local $ss_proc
elif [ "$ssp_type" = "2" ]; then
	logger -st "SSP[$$]Tunnel" "DNS隧道仅适用于SS和SSR"
	nvram set ss-tunnel_enable=0 && exit 1
fi

ss_server=$(nvram get ss_server)
ss_server_port=$(nvram get ss_server_port)
ss_method=$(nvram get ss_method)
ss_password=$(nvram get ss_key)

ss_tunnel_remote=$(nvram get ss-tunnel_remote)
ss_tunnel_mtu=$(nvram get ss-tunnel_mtu)
ss_tunnel_local_port=$(nvram get ss-tunnel_local_port)

ss_timeout=$(nvram get ss_timeout)

func_gen_ss_json(){
cat > "$ss_json_file" <<EOF
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
    "local_port": $ss_tunnel_local_port,
    "mtu": $ss_tunnel_mtu
}

EOF
}

func_start_ss_tunnel(){
	func_gen_ss_json
	sh -c "$ss_bin -u -c $ss_json_file -L $ss_tunnel_remote & "
	return $?
}

func_stop(){
	killall -q $ss_bin
}

case "$1" in
start)
	func_start_ss_tunnel && logger -st "SSP[$$]Tunnel" "成功启动" || logger -st "SSP[$$]Tunnel" "启动失败"
	;;
stop)
	func_stop
	;;
restart)
	func_stop
	func_start_ss_tunnel
	;;
*)
	echo "Usage: $0 { start | stop | restart }"
	exit 1
	;;
esac
