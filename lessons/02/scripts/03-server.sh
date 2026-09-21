#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"
begin '03 — Give someone the job of handing out addresses' \
  'The manually assigned addresses work. Have pi-dhcp run dnsmasq to assign
addresses automatically. First, remove the clients’ manual addresses.'
pause 'The server needs its own fixed address. Should it be in the client pool?'
for n in a b; do
  client_down "$n"
  setup "$n" 'if nmcli -t -f NAME connection show --active | grep -qx eth-manual; then
  nmcli connection down eth-manual
fi
if nmcli -t -f NAME connection show | grep -qx eth-manual; then
  nmcli connection delete eth-manual
fi'
  forget_client "$n"
  node "$n" 'ip -4 -br addr show dev eth0'
done
setup dhcp 'if ! nmcli -t -f NAME connection show | grep -qx eth-server; then
  nmcli connection add type ethernet ifname eth0 con-name eth-server \
    ipv4.method manual ipv4.addresses 10.10.0.254/24 ipv4.never-default yes \
    ipv6.method link-local connection.autoconnect yes
fi
nmcli connection up eth-server
cat > /etc/dnsmasq.conf <<CONF
# DHCP only, on the isolated lesson Ethernet network.
port=0
interface=eth0
bind-dynamic
dhcp-range=10.10.0.1,10.10.0.10,255.255.255.0,12h
# No router or DNS server exists on this LAN yet.
dhcp-option=option:router
dhcp-option=option:dns-server
log-dhcp
CONF'
node dhcp 'ip -4 -br addr show dev eth0'
pause 'The server is .254; the clients have no IPv4. Ready to choose a pool?'
node dhcp 'cat /etc/dnsmasq.conf'
pause 'Find eth0, the .1–.10 pool, and 12h. What does that duration mean?'
eye 'A lease lets a client use an address for a limited time.
The server’s .254 sits outside the pool. Empty router/DNS options mean
we are not advertising those services on this local network.'
pause 'Start the service, then check whether it is running.'
setup dhcp 'dnsmasq --test
systemctl enable dnsmasq
systemctl restart dnsmasq'
node dhcp 'systemctl is-active dnsmasq'
finish 'Why give the server .254 when its client pool is .1 through .10?' \
  'The server needs its own address to serve this network. Keeping .254
outside the pool prevents it from offering its own address to a client.
The service is ready; next, watch an addressless client ask for a lease.' \
  'Next: ./scripts/04-dora.sh'
