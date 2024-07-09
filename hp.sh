#!/bin/bash
MESSAGE=$(($(date +%s%N)))
USER=$1
XUSERINFO=$2
ID=$3
ITERATIONS=$4
curl -o /dev/null --silent "https://api.hushup.app/user/${USER}/message" \
  -H 'authority: api.hushup.app' \
  -H 'accept: application/json, text/plain, */*' \
  -H 'accept-language: en-IN,en;q=0.9' \
  -H 'content-type: application/json' \
  -H 'origin: https://hushup.app' \
  -H 'referer: https://hushup.app/' \
  -H 'sec-ch-ua: "Not A(Brand";v="99", "Google Chrome";v="121", "Chromium";v="121"' \
  -H 'sec-ch-ua-mobile: ?0' \
  -H 'sec-ch-ua-platform: "macOS"' \
  -H 'sec-fetch-dest: empty' \
  -H 'sec-fetch-mode: cors' \
  -H 'sec-fetch-site: same-site' \
  -H 'user-agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36' \
  -H "x-user-info: ${XUSERINFO}" \
  --data-raw "{\"message\":\"${MESSAGE}\",\"id\":\"${ID}\",\"username\":\"${USER}\",\"version\":2}" \
  --compressed
