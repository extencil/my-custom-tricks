# neighbor's network via proxy
### Context
My neighbor has a vulnerable wireless network and I have a test device sitting here in my room. It's an old Lenovo laptop running Ubuntu 24.04.1 LTS. This laptop is connected to my "access point/router" trough an UTP cable. I want to use their network as my exit node.

For this, i will use squid proxy.

#### Install network-manager and squid-proxy:
```console
ubuntu@p-ubnt-srv01:~$ sudo apt install network-manager -y
```

#### List Available Wireless Networks
```console
ubuntu@p-ubnt-srv01:~$ nmcli device wifi list
IN-USE  BSSID              BSSID                    MODE   CHAN  RATE        SIGNAL  BARS  SECURITY  
        aa:bb:cc:11:22:33  [SSID] Neighbor 2.4G    Infra  6     405 Mbit/s  100     ▂▄▆█  WPA2      
```

#### Connect to the network
```console
# ubuntu@p-ubnt-srv01:~$ sudo nmcli device wifi connect <BSSID> password <PASSWORD>
ubuntu@p-ubnt-srv01:~$ sudo nmcli device wifi connect aa:bb:cc:11:22:33 password 1234567890
Device 'wlp2s0' successfully activated with 'b3266946-0f9a-4147-8cc1-1535d58dc975'.
```

#### Getting IP adress from 'wlp2s0' interface
```console
ubuntu@p-ubnt-srv01:~$ ip a
...
3: wlp2s0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group 57841 qlen 1000
    link/ether 00:00:00:00:00:00 brd ff:ff:ff:ff:ff:ff
    inet 10.0.0.120/24 brd 10.0.0.255 scope global dynamic noprefixroute wlp2s0
...
# As you can see, the DHCP given IP address is 10.0.0.120
```

#### Register the routing table name on iproute2 (if you want):

Edit rt_tables file:
```console
root@p-ubnt-srv01:~# nano /etc/iproute2/rt_tables
```

Add this line to the end of file:
```console
200     wifiout
```

#### Add a custom route for all traffic originating from wlp2s0 to use the Wi-Fi gateway
```console
root@p-ubnt-srv01:~# ip route add default via 10.0.0.1 dev wlp2s0 table wifiout
```

#### Add a policy routing rule to apply the new table when using IP 10.0.0.120
```console
root@p-ubnt-srv01:~# ip rule add from 10.0.0.120 table wifiout
```

#### Apply NAT (Masquerade) for Outbound Traffic via Wi-Fi
```console
root@p-ubnt-srv01:~# iptables -t nat -A POSTROUTING -s 10.0.0.120 -o wlp2s0 -j MASQUERADE
```

#### Test the Outbound Connection Using the Source IP
```console
root@p-ubnt-srv01:~# curl --interface 10.0.0.120 http://api.ipify.org
```

#### Squid Proxy Configuration:

Edit the Squid configuration file:
```console
root@p-ubnt-srv01:# sudo nano /etc/squid/squid.conf
```

Add or modify these lines:
```conf
http_port 3128
http_access allow all
tcp_outgoing_address 10.0.0.120
```

#### Restart Squid to Apply Changes
```console
root@p-ubnt-srv01:~# sudo systemctl restart squid
```

#### Confirm Proxy Behavior from a Client Machine
```console
root@p-ubnt-srv01:~# curl -x http://<proxy-ip>:3128 http://api.ipify.org
```
