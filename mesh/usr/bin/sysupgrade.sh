#!/bin/sh

source /etc/profile

. /lib/functions.sh

################################# varible ############################################

# auto get $(ifconfig wlan0 | grep macaddr)
config_load sysconf
config_get soft_version system soft_version
config_get wan_interface system wan_interface
config_get wlan_interface system wlan_interface
config_get product_id system product_id
config_get server_domain system server_domain
config_get device_id system device_id
config_get firmware system firmware

# get wlan interface mac address.
mac_addr=$(ifconfig $wan_interface | grep "HWaddr" | awk -F " " '{ print $5 }')
# construct server url
server_url=http://${server_domain}:7000

################################# function ############################################

# led controller

leds_blink() {
    echo timer > /sys/devices/platform/leds-gpio/leds/e600gac:control:blue/trigger
}

leds_on() {
    echo default-on > /sys/devices/platform/leds-gpio/leds/e600gac:control:blue/trigger
}

# json data format analysis
function json_parse() { 
    data=$(echo $1 | tr -d " " | sed 's/\"//g' | sed 's/\n//g')
    echo $(echo $data | sed 's/.*'$2':\([^,}]*\).*/\1/')  
} 

# ping command
ping_cmd() {
    ping -W 2 -w 2 -c 1 $1>/dev/null
    ret=$?
    if [ $ret -eq 0  ]
    then 
        echo OK
    else 
        echo ERROR
    fi
}

# configuration file version number compare function.
version_gt() { test "$(echo "$@" | tr -s " " "\n" | sort -n | head -n 1)" != "$1"; }


################################# process ############################################

#### ping web server until receiving feedback

for i in `seq 60`
do
    ##### check network 
    ret=$(ping_cmd $server_domain)
    if [ "$ret" = "OK" ];
    then 
        echo $ret
        break
    fi
    [ $i -eq 60 ] && exit
done

# get firmware version
json=$(curl $server_url/\?product_id\=$product_id\&macaddr\=$mac_addr\&devid\=$device_id\&soft_ver\=$soft_version)

if [ -z "$json" ];
then
    echo "web server $server_url no response."
    exit
fi

# get device id, software version and product id 
r_soft_version=$(json_parse "$json" "soft_ver")
r_device_id=$(json_parse "$json" "devid")
r_md5=$(json_parse "$json" "md5")

echo $json
echo $r_md5

# compare version
echo $r_soft_version $soft_version
if version_gt "$r_soft_version" "$soft_version"
then
    # check information and download firmware
    os_file=$firmware-$product_id-$r_soft_version.bin
    rm -rf "/tmp/$os_file"

    download_url="$server_url/$product_id/$os_file"

    wget -c -P /tmp $download_url
    if [ ! -f /tmp/$os_file ]
    then
        echo "/tmp/$osfile download failed."
        exit
    fi
    echo "download $os_file to /tmp "

    # MD5 verification and upgrade
    cd /tmp
    echo "$r_md5 *$os_file" > /tmp/md5sums
    md5sum -c -s /tmp/md5sums
    
    # varify successfully.
    if [ $? == 0  ]
    then
        # upgrade successsfully.
        # send sccessfull message.
        curl "$server_url/?devid=$r_device_id&update_success=1"

        # save device id
        uci set sysconf.@system[0].device_id=$r_device_id
        uci set sysconf.@system[0].soft_version=$r_soft_version
        uci commit sysconf

        leds_blink

        # upgrade system.
        sysupgrade -c /tmp/$os_file

        # echo information.
        echo "starting to upgrate /tmp/$os_file."
    else
        echo "md5sum varification failed."
    fi
else
    echo "local firmware version greater than or equal to remote firmware version"
fi


