#!/bin/sh

get_option() {
    echo $(echo $1 | awk -F '|' -v option="$2" '{ for (i=1; i<=NF; i++) { if($i==option) print $(i+1) } }')
}

leds_sync() {
    echo timer > /sys/devices/platform/leds-gpio/leds/e600gac:control:red/trigger
}

leds_sync_off() {
    echo none > /sys/devices/platform/leds-gpio/leds/e600gac:control:red/trigger
}

channel=$(uci get mesh.@mesh-iface[0].channel)
mesh_iface=$(uci get mesh.@mesh-iface[0].mesh_iface)
wlan=$(uci get mesh.@mesh-iface[0].wlan)
ssid=$(uci get mesh.@mesh-iface[0].ssid)
bssid=$(uci get mesh.@mesh-iface[0].bssid)
bridge=$(uci get mesh.@mesh-iface[0].bridge)

btn_pipe=/tmp/btn_pipe
btn_rpipe=/tmp/btn_rpipe

BRCTL=/usr/sbin/brctl
IFCONFIG=/sbin/ifconfig


[ -p $btn_pipe ] && exit
[ -p $btn_rpipe ] && exit

leds_sync
mkdir $btn_rpipe

ifconfig $mesh_iface down                                                          
brctl delif $bridge $mesh_iface

orig_network=$(uci get wireless.@wifi-iface[0].network)

uci set wireless.@wifi-iface[0].ssid=$ssid
uci set wireless.@wifi-iface[0].bssid=$bssid
uci set wireless.@wifi-iface[0].network=none
uci commit wireless
/etc/init.d/network restart

sleep 6
$IFCONFIG $wlan 172.16.16.2 netmask 255.255.0.0
netconfig=$(udpecho -s)

leds_sync_off

echo $netconfig >> /root/sync.log

if [ -z $netconfig ];
then
    rm -f $btn_rpipe
    echo timeout >> /root/sync.log
    exit
fi

ssid=$(get_option $netconfig ssid)
key=$(get_option $netconfig key)
encryption=$(get_option $netconfig encryption)
ssid_ad=$(get_option $netconfig ssid-ad)
bssid_ad=$(get_option $netconfig bssid-ad)

uci set wireless.@wifi-iface[1].ssid=$ssid
uci set wireless.@wifi-iface[1].key=$key
uci set wireless.@wifi-iface[1].encryption=$encryption

uci set wireless.@wifi-iface[0].ssid=$ssid_ad
uci set wireless.@wifi-iface[0].bssid=$bssid_ad
uci set wireless.@wifi-iface[0].network=$orig_network
uci commit wireless

/etc/init.d/network restart
/etc/init.d/mesh restart

rm -f $btn_rpipe

