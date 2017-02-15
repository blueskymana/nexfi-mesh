#!/bin/sh

channel=$(uci get mesh.@mesh-iface[0].channel)
mesh_iface=$(uci get mesh.@mesh-iface[0].mesh_iface)
wlan=$(uci get mesh.@mesh-iface[0].wlan)
ssid=$(uci get mesh.@mesh-iface[0].ssid)
bridge=$(uci get mesh.@mesh-iface[0].bridge)

MP=/usr/bin/mp
BRCTL=/usr/sbin/brctl
IFCONFIG=/sbin/ifconfig

/etc/init.d/mesh stop
orig_ssid=$(uci get wireless.@wifi-iface[1].ssid)
orig_bssid=$(uci get wireless.@wifi-iface[1].bssid)

uci set wireless.@wifi-iface[1].ssid=$ssid
uci set wireless.@wifi-iface[1].mode=$bssid
uci commit wireless
/etc/init.d/network reload
sleep 3
$IFCONFIG $wlan 172.16.73.1 netmask 255.255.255.0

# sync data
ssid=$(uci get wireless.@wifi-iface[0].ssid)
key=$(uci get wireless.@wifi-iface[0].key)
encryption=$(uci get wireless.@wifi-iface[0].encryption)
ssid2=$(uci get wireless.@wifi-iface[1].ssid)
bssid=$(uci get wireless.@wifi-iface[1].bssid)
syncdata="ssid:${ssid}:key:${key}:encryption:${encryption}:ssid2:${ssid2}:bssid:${bssid}"

bcast=172.16.73.255
# transfer data

for i in {1 2 3 4 5 6 7 8 9 10}
do
    udpecho $bcast $syncdata 
    echo $syncdata
    sleep 1
done

uci set wireless.@wifi-iface[1].ssid=$orig_ssid
uci set wireless.@wifi-iface[1].mode=$orig_bssid
uci commit wireless

/etc/init.d/network reload
sleep 3
/etc/init.d/mesh restart

#$MP add $mesh_iface $wlan nexfi-sync $channel
#$IFCONFIG $mesh_iface 172.16.73.1 netmask 255.255.255.0
