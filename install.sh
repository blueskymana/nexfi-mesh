#!/bin/sh

cp ./mesh/* /
/etc/init.d/network restart
/etc/init.d/mesh restart
