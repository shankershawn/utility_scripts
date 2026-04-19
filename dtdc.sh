#/bin/bash
curl -s --location 'https://www.dtdc.com/wp-json/custom/v1/domestic/track' \
--header 'Content-Type: application/json' \
--data '{
    "trackType": "refno",
    "trackNumber": "CNIN28045961801"
}' | jq '[.statuses[:6][]|{"remarks":.remarks, "statusTimestamp":.statusTimestamp, "actBranchName":.actBranchName}]'
