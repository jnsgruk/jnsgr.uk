#!/bin/ash
mkdir -p /var/log/gosherve
/usr/bin/gosherve > "/var/log/gosherve/gosherve-$(date +"%s").log" 2>&1