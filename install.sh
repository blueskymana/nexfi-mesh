#!/bin/sh

# install
cp -R ./mesh/* /

# OS configuration
. ./scripts/mesh.sh

# nexfi-mesh configuration
rm -rf /etc/rc.d/S98mesh
ln -s /etc/init.d/mesh /etc/rc.d/S98mesh
/etc/init.d/mesh enable

# remove network & wireless 
rm -rf /etc/config/network
rm -rf /etc/config/wireless

# 

reboot
