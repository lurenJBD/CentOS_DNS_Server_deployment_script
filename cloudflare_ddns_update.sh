#!/bin/sh

# 参考资料:
# https://github.com/openwrt/packages/blob/master/net/ddns-scripts/samples/update_sample.sh
# https://github.com/anjianshi/cloudxns-ddns/blob/master/cloudxns.sh
# https://gist.github.com/icyleaf/8fc867003cb3c868bfae855e722ce392
#
# Requirements:
# curl
# egrep
#


[ -z "$domain" ]   && write_log 14 "Service section not configured correctly! Missing 'domain'"
[ -z "$username" ] && write_log 14 "Service section not configured correctly! Missing 'username'"
[ -z "$password" ] && write_log 14 "Service section not configured correctly! Missing 'password'"

if test ! $(which curl); then
    write_log 14 "Service missing curl dependency"
fi

API_URL="https://api.cloudflare.com/client/v4/"
API_DOMAIN=$domain
API_SUBDOMAIN=$domain
API_EMAIL=$username
API_KEY=$password
API_DNS_RECORD_TYPE=A
API_IP=$__IP
API_ZONE_ID=
API_DNS_RECORD_ID=

API_ENDPOINT_API="https://api.cloudflare.com/client/v4/zones"

get_domain_zone_id() {
  local url="${API_ENDPOINT_API}/?name=${API_DOMAIN}"

  local result=$(request_get $url)
  API_ZONE_ID=$(echo $result| egrep -o "\"id\":\"[0-9a-f]{32}\"" | egrep -o "[0-9a-f]{32}" | head -n1)
}

get_dns_record_id() {
  local url="${API_ENDPOINT_API}/${API_ZONE_ID}/dns_records?name=${API_SUBDOMAIN}&type=${API_DNS_RECORD_TYPE}"
  local result=$(request_get $url)
  API_DNS_RECORD_ID=$(echo $result | egrep -o "\"id\":\"[0-9a-f]{32}\"" | egrep -o "[0-9a-f]{32}" | head -n1)
}

update_dns_record() {
  local url="${API_ENDPOINT_API}/${API_ZONE_ID}/dns_records/${API_DNS_RECORD_ID}"
  local data='{"type":"A","name":"'${API_SUBDOMAIN}'","content":"'${API_IP}'","ttl":120,"proxied":false})'

  local result=$($request_put $url $data)
}

request_get() {
  local url="$1"

  curl -s -X GET $url \
       -H "X-Auth-Email: ${API_EMAIL}" \
       -H "X-Auth-Key: ${API_KEY}" \
       -H "Content-Type: application/json"
}

request_put() {
  local url="$1"
  local data="$2"

  curl -s -X PUT $url \
       -H "X-Auth-Email: ${API_EMAIL}" \
       -H "X-Auth-Key: ${API_KEY}" \
       -H "Content-Type: application/json" \
       --data ${data}
}

get_domain_zone_id
get_dns_record_id
$RESULT=$(update_dns_record)

if [ $(echo -n "$RESULT"|grep -o "\"success\":true"|wc -l) = 1 ];then
    return 0
else
    return 1
fi
