#!/bin/sh

set -e -o pipefail

[ "$1" != "force" ] && [ "$(nvram get ss_update_gfwlist)" != "1" ] && exit 0
GFWLIST_URL="$(nvram get gfwlist_url)"

[ -x /usr/bin/shadowsocks.sh ] && [ -x /usr/bin/smartdns.sh ] && logger -st "SSP[$$]Update" "开始更新黑名单..."

(rm -rf /tmp/GFWblack.conf
curl -k -s -o /tmp/GFWblack.conf --connect-timeout 5 --retry 3 \
${GFWLIST_URL:-"https://raw.githubusercontent.com/GH-X/rt-n56u/GFWListDomainIP/GFWblack.conf"})&
(rm -rf /tmp/GFWblackip.conf
curl -k -s -o /tmp/GFWblackip.conf --connect-timeout 5 --retry 3 \
https://raw.githubusercontent.com/GH-X/rt-n56u/GFWListDomainIP/GFWblackip.conf)&
(rm -rf /tmp/smartdns_address.conf
curl -k -s -o /tmp/smartdns_address.conf --connect-timeout 5 --retry 3 \
https://raw.githubusercontent.com/GH-X/rt-n56u/GFWListDomainIP/smartdns_address.conf)&

wait

[ ! -d /etc/storage/gfwlist/ ] && mkdir /etc/storage/gfwlist/
/usr/bin/smartdns.sh update &>/dev/null && logger -st "SSP[$$]Update" "黑名单更新完成"

[ "$(nvram get ss_enable)" = "1" ] && /usr/bin/shadowsocks.sh restart &>/dev/null
