# Server log: adding an IPv4 address

These excerpts were recorded on `pi-foo-dhcp` on September 9, 2026.

With dnsmasq running and no address on `eth0`, incoming DHCP packets produced:

```text
Sep 09 17:17:23 pi-foo-dhcp dnsmasq-dhcp[13798]: DHCP packet received on eth0 which has no address
Sep 09 17:17:25 pi-foo-dhcp dnsmasq-dhcp[13798]: DHCP packet received on eth0 which has no address
Sep 09 17:17:29 pi-foo-dhcp dnsmasq-dhcp[13798]: DHCP packet received on eth0 which has no address
```

After assigning `10.10.0.254/24` to server `eth0`, the same dnsmasq process recorded the following six contiguous lines. The nine preceding lines of the journal excerpt repeated the earlier no-address diagnostic and are omitted here.

```text
Sep 09 17:20:50 pi-foo-dhcp dnsmasq-dhcp[13798]: DHCPDISCOVER(eth0) b8:27:eb:3a:e2:c8
Sep 09 17:20:50 pi-foo-dhcp dnsmasq-dhcp[13798]: DHCPOFFER(eth0) 10.10.0.1 b8:27:eb:3a:e2:c8
Sep 09 17:20:50 pi-foo-dhcp dnsmasq-dhcp[13798]: DHCPDISCOVER(eth0) b8:27:eb:3a:e2:c8
Sep 09 17:20:50 pi-foo-dhcp dnsmasq-dhcp[13798]: DHCPOFFER(eth0) 10.10.0.1 b8:27:eb:3a:e2:c8
Sep 09 17:20:50 pi-foo-dhcp dnsmasq-dhcp[13798]: DHCPREQUEST(eth0) 10.10.0.1 b8:27:eb:3a:e2:c8
Sep 09 17:20:50 pi-foo-dhcp dnsmasq-dhcp[13798]: DHCPACK(eth0) 10.10.0.1 b8:27:eb:3a:e2:c8 pi-foo-01
```

The PID remains `13798`. In this run, the next client attempt succeeded after the server gained its address and prefix, without restarting dnsmasq.
