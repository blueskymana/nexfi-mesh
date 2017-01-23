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
$MP add $mesh_iface $wlan nexfi-sync $channel
$IFCONFIG $mesh_iface 172.2.2.1 netmask 255.255.255.0

# sync data
ssid=$(uci get wireless.@wifi-iface[0].ssid)
key=$(uci get wireless.@wifi-iface[0].key)
encryption=$(uci get wireless.@wifi-iface[0].encryption)
ssid2=$(uci get wireless.@wifi-iface[1].ssid)
syncdata="ssid:${ssid}:key:${key}:encryption:${encryption}:ssid2:${ssid2}"

bcast=172.2.2.255
# transfer data

for i in {1 2 3 4 5 6 7 8}
do
    udpecho $bcast $syncdata 
    echo $syncdata
    sleep 1
done

/etc/init.d/mesh stop
/etc/init.d/mesh restart

