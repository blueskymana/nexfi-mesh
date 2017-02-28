#!/bin/sh

echo "The ebtables start !"

ebtables -P FORWARD ACCEPT 
ebtables -P INPUT ACCEPT
ebtables -P OUTPUT ACCEPT
ebtables -F 
ebtables -A FORWARD -p ipv4 -i eth0 --ip-dst 192.168.8.8 -j DROP
