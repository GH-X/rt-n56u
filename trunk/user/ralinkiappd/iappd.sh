#!/bin/sh


stop_iappd()
{
$(pidof ralinkiappd &>/dev/null) || return 1
killall -q -SIGTERM ralinkiappd
sleep 1
$(pidof ralinkiappd &>/dev/null) || return 0
killall -q -9 ralinkiappd
return 0
}

start_iappd()
{
if grep -q 'mt76x3_ap' /proc/modules; then
  ralinkiappd -wi rai0 -d 0 &
  sysctl -wq net.ipv4.neigh.rai0.base_reachable_time_ms=10000
  sysctl -wq net.ipv4.neigh.rai0.delay_first_probe_time=1
else
  if grep -q 'rai0' /proc/interrupts; then
    ralinkiappd -wi rai0 -wi ra0 -d 0 &
    sysctl -wq net.ipv4.neigh.rai0.base_reachable_time_ms=10000
    sysctl -wq net.ipv4.neigh.rai0.delay_first_probe_time=1
  else
    ralinkiappd -wi rax0 -wi ra0 -d 0 &
    sysctl -wq net.ipv4.neigh.rax0.base_reachable_time_ms=10000
    sysctl -wq net.ipv4.neigh.rax0.delay_first_probe_time=1	    
  fi
fi
sysctl -wq net.ipv4.neigh.br0.base_reachable_time_ms=10000
sysctl -wq net.ipv4.neigh.br0.delay_first_probe_time=1
sysctl -wq net.ipv4.neigh.eth2.base_reachable_time_ms=10000
sysctl -wq net.ipv4.neigh.eth2.delay_first_probe_time=1
sysctl -wq net.ipv4.neigh.ra0.base_reachable_time_ms=10000
sysctl -wq net.ipv4.neigh.ra0.delay_first_probe_time=1
iptables -A INPUT -i br0 -p tcp --dport 3517 -j ACCEPT
iptables -A INPUT -i br0 -p udp --dport 3517 -j ACCEPT 
}

case "$1" in
stop)
  stop_iappd
  ;;
start)
  start_iappd
  ;;
restart)
  stop_iappd
  start_iappd
  ;;
*)
  echo "Usage: $0 {stop|start|restart}"
  exit 1
  ;;
esac
