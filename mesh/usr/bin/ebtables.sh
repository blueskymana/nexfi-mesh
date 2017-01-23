#!/bin/sh

echo "The ebtables start !"

ebtables -P FORWARD ACCEPT 
ebtables -P INPUT ACCEPT
ebtables -P OUTPUT ACCEPT
ebtables -F 
ebtables -A FORWARD -p ipv4 -i eth0 --ip-dst 173.173.173.1 -j DROP
ebtables -A FORWARD -p ipv4 -i eth0 --ip-dst 173.173.173.2 -j DROP
