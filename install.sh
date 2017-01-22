#!/bin/sh

cp -R ./mesh/* /
/etc/init.d/network restart
sleep 3
/etc/init.d/mesh restart
