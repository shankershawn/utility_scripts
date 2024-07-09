#!/bin/bash
checkin_date=$1
checkout_date=$2
filename=mtdc_out_$(sed 's|/|_|g' <<< $checkin_date)_$(sed 's|/|_|g' <<< $checkout_date).txt
curl --location 'https://api.mtdc.co/api/v2/hotel/check-availability-v2?lang=' --header 'accept: application/json, text/plain, */*' --header 'accept-language: en-IN,en-GB;q=0.9,en-US;q=0.8,en;q=0.7' --header 'content-type: Application/json' --header 'origin: https://www.mtdc.co' --header 'priority: u=1, i' --header 'sec-ch-ua: "Not/A)Brand";v="8", "Chromium";v="126", "Google Chrome";v="126"' --header 'sec-ch-ua-mobile: ?0' --header 'sec-ch-ua-platform: "macOS"' --header 'sec-fetch-dest: empty' --header 'sec-fetch-mode: cors' --header 'sec-fetch-site: same-site' --header 'user-agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36' --data '{"name":"","hotelID":"60c49fb62f26e01f8d68dc7e","checkIn":"'${checkin_date}'","checkOut":"'${checkout_date}'","paxInfo":{"adults":2,"child":0,"rooms":1}}' | jq --arg prefix "₹" '[.[] | select(.ratePlans[0].price <= 2200) | {"Room":.inventory.RoomName, "Image":.inventory.thumbnailImg, "InventoryQuantity": .InventoryQuantity, "Rate": ($prefix + (.ratePlans[0].price | tostring))}]' > temp_$filename

isSendMail="N"
emailReplyPrefix=""
if [ -f "${filename}" ]
then
	emailReplyPrefix="Re:"
	diffVal=$(diff temp_$filename $filename)
	diffValLength=${#diffVal}
	if [ $diffValLength -gt 0 ]
	then
		isSendMail="Y"
	fi
else
	isSendMail="Y"
fi
mv temp_$filename $filename
if [ "$isSendMail" = "Y" ]
then
	cat $filename | mail -s "$filename" shankershawn@gmail.com,nairitamganai@gmail.com,tkganaintpc@gmail.com,shankarsan.ganai@icloud.com
fi
