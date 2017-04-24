#!/bin/sh

channel=$(uci get mesh.@mesh-iface[0].channel)
mesh_iface=$(uci get mesh.@mesh-iface[0].mesh_iface)
wlan=$(uci get mesh.@mesh-iface[0].wlan)
ssid=$(uci get mesh.@mesh-iface[0].ssid)
bridge=$(uci get mesh.@mesh-iface[0].bridge)
bssid=$(uci get mesh.@mesh-iface[0].bssid)

btn_pipe=/tmp/btn_pipe
btn_msg=relased
btn_rpipe=/tmp/btn_rpipe

BRCTL=/usr/sbin/brctl
IFCONFIG=/sbin/ifconfig

leds_sync() {
    echo timer > /sys/devices/platform/leds-gpio/leds/e600gac:control:green/trigger
}

leds_sync_off() {
    echo none > /sys/devices/platform/leds-gpio/leds/e600gac:control:green/trigger
}


if [ -p $btn_pipe ];
then
    echo $btn_msg > $btn_pipe
    exit
fi

[ -p $btn_pipe ] && exit
[ -p $btn_rpipe ] && exit

leds_sync

#bridge_ssid=$(uci get wireless.@wifi-iface[0].ssid)
#bridge_bssid=$(uci get wireless.@wifi-iface[0].bssid)
bridge_ssid=$(head -n 10 /dev/urandom | md5sum | head -c 8)
bridge_bssid=00$(dd bs=1 count=5 if=/dev/random 2>/dev/null |hexdump -v -e '/1 ":%02X"')
bridge_network=$(uci get wireless.@wifi-iface[0].network)

uci set wireless.@wifi-iface[0].ssid=$ssid
uci set wireless.@wifi-iface[0].bssid=$bssid
uci set wireless.@wifi-iface[0].network=none
uci commit wireless

ifconfig $mesh_iface down
brctl delif $bridge $mesh_iface

msg=none
mkfifo $btn_pipe
read -t 1 msg <> $btn_pipe

/etc/init.d/network restart
sleep 5
$IFCONFIG $wlan 172.16.16.1 netmask 255.255.0.0

# sync data
ssid=$(uci get wireless.@wifi-iface[1].ssid)
key=$(uci get wireless.@wifi-iface[1].key)
encryption=$(uci get wireless.@wifi-iface[1].encryption)

syncdata="ssid|${ssid}|key|${key}|encryption|${encryption}|ssid-ad|${bridge_ssid}|bssid-ad|${bridge_bssid}"

bcast=172.16.255.255
# transfer data

while [ 1 ];
do
    udpecho $bcast $syncdata 
    echo $syncdata > /tmp/sync.log
    read -t 1 msg <> $btn_pipe
    if [ $btn_msg = $msg ];
    then
        break
    fi
    #echo $msg
done

leds_sync_off

uci set wireless.@wifi-iface[0].ssid=$bridge_ssid
uci set wireless.@wifi-iface[0].bssid=$bridge_bssid
uci set wireless.@wifi-iface[0].network=$bridge_network
uci commit wireless

/etc/init.d/network restart
/etc/init.d/mesh restart

rm $btn_pipe
