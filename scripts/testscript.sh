#!/bin/bash
# Script to collect the status of lshw output from home servers
# Dependencies:
# * LSHW: http://ezix.org/project/wiki/HardwareLiSter
# * JQ: http://stedolan.github.io/jq/
#
# On each machine you can run something like this from cron (Don't know CRON, no worries: https://crontab-generator.org/)
# 0 0 * * * /usr/sbin/lshw -json -quiet > /var/log/lshw-dump.json
# Author: Jose Vicente Nunez
#
declare -a servers=(
k8s1
)

DATADIR="$HOME/Documents/lshw-dump"

/usr/bin/mkdir -p -v "$DATADIR"
for server in ${servers[*]}; do
    echo "Visiting: $server"
    #/usr/bin/scp -o logLevel=Error ${server}:/var/log/lshw-dump.json ${DATADIR}/lshw-$server-dump.json &
    lshw -quiet -json > lshw-dump.json
    cp lshw-dump.json lshw-$server-dump.json &
done
wait
for lshw in lshw-dump.json; do
#for lshw in $(/usr/bin/find $DATADIR -type f -name 'lshw-*-dump.json'); do
    jq '.["product","vendor", "configuration"]' $lshw
done
