#!/usr/bin/env bash

INFO=$(ip addr show $(ip route show default | awk '{ for(i = 1; i <= NF; i++) { if($i == "dev") { print $(i+1) } } }') | grep inet -w | awk '{ print $2 }')

IP=$(cut -d'/' -f1 <<< "$INFO")
echo $IP

SUBNET=$(cut -d'/' -f2 <<< "$INFO")
echo $SUBNET