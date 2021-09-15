#!/bin/sh

set -e -o pipefail

[ "$1" != "force" ] && [ "$(nvram get ss_update_chnroute)" != "1" ] && exit 0
CHNROUTE_URL="$(nvram get chnroute_url)"
ROUTE_URL="http://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest"

[ -x /usr/bin/shadowsocks.sh ] && [ -x /usr/bin/smartdns.sh ] && logger -st "SSP[$$]Update" "开始更新路由表..."

rm -f /tmp/chnroute.txt
rm -f /tmp/allroute.txt

if [ -z "$CHNROUTE_URL" ]; then
	curl -k -s --connect-timeout 5 --retry 3 "$ROUTE_URL" | sed '/\*/d' | \
	awk -F\| '/CN\|ipv4/ { printf("%s/%d\n", $4, 32-log($5)/log(2)) }' > /tmp/chnroute.txt
else
	curl -k -s --connect-timeout 5 --retry 3 -o /tmp/chnroute.txt "$CHNROUTE_URL"
fi

curl -k -s --connect-timeout 5 --retry 3 "$ROUTE_URL" | sed '/\*/d' | \
awk -F\| '/ipv4/ { printf("%s/%d\n", $4, 32-log($5)/log(2)) }' > /tmp/allroute.txt

[ ! -d /etc/storage/chinadns/ ] && mkdir /etc/storage/chinadns/
mv -f /tmp/chnroute.txt /etc/storage/chinadns/chnroute.txt
[ ! -d /etc/storage/ssprules/ ] && mkdir /etc/storage/ssprules/
mv -f /tmp/allroute.txt /etc/storage/ssprules/allroute.txt

mtd_storage.sh save &>/dev/null

[ "$(nvram get sdns_enable)" = "1" ] && /usr/bin/smartdns.sh restart &>/dev/null
[ "$(nvram get ss_enable)" = "1" ] && /usr/bin/shadowsocks.sh restart &>/dev/null

logger -st "SSP[$$]Update" "路由表更新完成"
