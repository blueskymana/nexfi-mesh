#!/bin/sh

get_option() {
    echo $(echo $1 | awk -F '|' -v option="$2" '{ for (i=1; i<=NF; i++) { if($i==option) print $(i+1) } }')
}

channel=$(uci get mesh.@mesh-iface[0].channel)
mesh_iface=$(uci get mesh.@mesh-iface[0].mesh_iface)
wlan=$(uci get mesh.@mesh-iface[0].wlan)
ssid=$(uci get mesh.@mesh-iface[0].ssid)
bssid=$(uci get mesh.@mesh-iface[0].bssid)
bridge=$(uci get mesh.@mesh-iface[0].bridge)

MP=/usr/bin/mp
BRCTL=/usr/sbin/brctl
IFCONFIG=/sbin/ifconfig

/etc/init.d/mesh stop
uci set wireless.@wifi-iface[1].ssid=$ssid
uci set wireless.@wifi-iface[1].bssid=$bssid
uci commit wireless
/etc/init.d/network reload

sleep 3
$IFCONFIG $wlan 172.16.73.2 netmask 255.255.255.0
netconfig=$(udpecho -s)
echo $netconfig > /root/sync.log

ssid=$(get_option $netconfig ssid)
key=$(get_option $netconfig key)
encryption=$(get_option $netconfig encryption)
ssid_ad=$(get_option $netconfig ssid-ad)
bssid_ad=$(get_option $netconfig bssid-ad)

uci set wireless.@wifi-iface[0].ssid=$ssid
uci set wireless.@wifi-iface[0].key=$key
uci set wireless.@wifi-iface[0].encryption=$encryption

uci set wireless.@wifi-iface[1].ssid=$ssid_ad
uci set wireless.@wifi-iface[1].bssid=$bssid_ad
uci commit wireless

/etc/init.d/network restart
sleep 3
/etc/init.d/mesh restart

#/etc/init.d/mesh stop
#$MP add $mesh_iface $wlan nexfi-sync $channel
#$IFCONFIG $mesh_iface 172.16.73.2 netmask 255.255.255.0
