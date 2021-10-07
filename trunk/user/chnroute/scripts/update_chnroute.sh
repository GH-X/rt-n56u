#!/bin/sh

set -e -o pipefail

[ "$1" != "force" ] && [ "$(nvram get ss_update_chnroute)" != "1" ] && exit 0
CHNROUTE_URL="$(nvram get chnroute_url)"
ALLROUTE_URL="$(nvram get allroute_url)"
ROUTE_URL="http://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest"
user_agent="Mozilla/5.0 (X11; Linux; rv:74.0) Gecko/20100101 Firefox/74.0"

[ -x /usr/bin/shadowsocks.sh ] && [ -x /usr/bin/smartdns.sh ] && logger -st "SSP[$$]Update" "开始更新路由表..."

(rm -f /tmp/chnroute.txt
if [ -z "$CHNROUTE_URL" ]; then
	curl -k -s -A "$user_agent" --connect-timeout 5 --retry 3 "$ROUTE_URL" | sed '/\*/d' | \
	awk -F\| '/CN\|ipv4/ { printf("%s/%d\n", $4, 32-log($5)/log(2)) }' > /tmp/chnroute.txt
else
	curl -k -s --connect-timeout 5 --retry 3 -o /tmp/chnroute.txt "$CHNROUTE_URL" && \
	sed -i '/^#/d' /tmp/chnroute.txt && sed -i '/^$/d' /tmp/chnroute.txt
fi
[ ! -d /etc/storage/chinadns/ ] && mkdir /etc/storage/chinadns/
if [ $(stat -c %s /tmp/chnroute.txt) -lt 600000 ]; then
	mv -f /tmp/chnroute.txt /etc/storage/chinadns/chnroute.txt
else
	rm -f /etc/storage/chinadns/chnroute.txt && \
	ln -sf /tmp/chnroute.txt /etc/storage/chinadns/chnroute.txt
fi)&

(rm -f /tmp/allroute.txt
if [ -z "$ALLROUTE_URL" ]; then
	curl -k -s -A "$user_agent" --connect-timeout 5 --retry 3 "$ROUTE_URL" | sed '/\*/d' | \
	awk -F\| '/ipv4/ { printf("%s/%d\n", $4, 32-log($5)/log(2)) }' > /tmp/allroute.txt
else
	curl -k -s --connect-timeout 5 --retry 3 -o /tmp/allroute.txt "$ALLROUTE_URL" && \
	sed -i '/^#/d' /tmp/allroute.txt && sed -i '/^$/d' /tmp/allroute.txt
fi
[ ! -d /etc/storage/ssprules/ ] && mkdir /etc/storage/ssprules/
if [ $(stat -c %s /tmp/allroute.txt) -lt 3000000 ]; then
	mv -f /tmp/allroute.txt /etc/storage/ssprules/allroute.txt
else
	rm -f /etc/storage/ssprules/allroute.txt && \
	ln -sf /tmp/allroute.txt /etc/storage/ssprules/allroute.txt
fi)&

wait

mtd_storage.sh save &>/dev/null && logger -st "SSP[$$]Update" "路由表更新完成"

[ "$(nvram get sdns_enable)" = "1" ] && /usr/bin/smartdns.sh restart &>/dev/null
[ "$(nvram get ss_enable)" = "1" ] && /usr/bin/shadowsocks.sh restart &>/dev/null
