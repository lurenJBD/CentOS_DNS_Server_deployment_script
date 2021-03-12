#!/bin/bash
set -o errexit
set -o pipefail

# 更新chnroute
churl='http://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest'
echo 'Updating chnroute... It may take a long time'
wget -q --spider "$churl" && chnroute=$(curl -4sSkL "$churl") && $ok=0
if [ $ok == 0 ];then
  echo "create chnroute hash:net family inet" >/opt/chinadns-ng/chnroute.ipset
  echo "$chnroute" | grep CN | grep ipv4 | awk -F'|' '{printf("add chnroute %s/%d\n", $4, 32-log($5)/log(2))}' >>/opt/chinadns-ng/chnroute.ipset && echo update chnroute successful!
else
  echo Update chnroute Failed!
fi
# 更新chnroute6
echo 'Updating chnroute6... It may take a long time'
if [ $ok == 0 ];then
  echo "create chnroute6 hash:net family inet6" >/opt/chinadns-ng/chnroute6.ipset
  echo "$chnroute" | grep CN | grep ipv6 | awk -F'|' '{printf("add chnroute6 %s/%d\n", $4, $5)}' >>/opt/chinadns-ng/chnroute6.ipset && echo update chnroute6 successful!
else
  echo Update chnroute6 Failed!
fi