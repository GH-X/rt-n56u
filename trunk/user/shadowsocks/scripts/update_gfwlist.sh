#!/bin/sh

set -e -o pipefail

[ "$1" != "force" ] && [ "$(nvram get ss_update_gfwlist)" != "1" ] && exit 0
GFWLIST_URL="$(nvram get gfwlist_url)"
GFWALL_PURL="https://raw.githubusercontent.com/GH-X/rt-n56u/GFWListDomainIP"

[ -x /usr/bin/shadowsocks.sh ] && [ -x /usr/bin/smartdns.sh ] && \
echo "stop_ams" > /tmp/sspstatus.tmp && logger -st "SSP[$$]Update" "开始更新黑名单..."

(rm -rf /tmp/GFWblack.conf
curl -k -s -o /tmp/GFWblack.conf --connect-timeout 5 --retry 3 \
${GFWLIST_URL:-"$GFWALL_PURL/GFWblack.conf"} && logger -st "SSP[$$]Update" "黑名单域名文件下载完成")&
([ -e /tmp/GFWblackip.conf ] && mv -f /tmp/GFWblackip.conf /tmp/GFWblackip.amsc
curl -k -s -o /tmp/GFWblackip.conf --connect-timeout 5 --retry 3 \
$GFWALL_PURL/GFWblackip.conf && logger -st "SSP[$$]Update" "黑名单地址文件下载完成")&
(rm -rf /tmp/smartdns_address.conf
curl -k -s -o /tmp/smartdns_address.conf --connect-timeout 5 --retry 3 \
$GFWALL_PURL/smartdns_address.conf && logger -st "SSP[$$]Update" "域名地址文件下载完成")&

wait

[ ! -d /etc/storage/gfwlist/ ] && mkdir /etc/storage/gfwlist/
/usr/bin/smartdns.sh update &>/dev/null && logger -st "SSP[$$]Update" "黑名单更新完成"
