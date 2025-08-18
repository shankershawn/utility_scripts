#!/bin/bash
for pnr in $(awk '{print $1}' pnrlist.txt)
do
	curl 'https://cttrainsapi.confirmtkt.com/api/v2/ctpro/mweb/6156410112?querysource=ct-web&locale=en&getHighChanceText=true&livePnr=false'   -H 'Accept: */*'   -H 'Accept-Language: en-IN,en-GB;q=0.9,en-US;q=0.8,en;q=0.7'   -H $'ApiKey: ct-web\u00212$'   -H 'CT-Token;'   -H 'CT-Userkey;'   -H 'ClientId: ct-web'   -H 'Connection: keep-alive'   -H 'Content-Type: application/json'   -H 'DeviceId: a1b2355f-d43b-47f1-8b65-a95c09bc4887'   -H 'Origin: https://www.confirmtkt.com'   -H 'Referer: https://www.confirmtkt.com/'   -H 'Sec-Fetch-Dest: empty'   -H 'Sec-Fetch-Mode: cors'   -H 'Sec-Fetch-Site: same-site'   -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36'   -H 'sec-ch-ua: "Not)A;Brand";v="8", "Chromium";v="138", "Google Chrome";v="138"'   -H 'sec-ch-ua-mobile: ?0'   -H 'sec-ch-ua-platform: "macOS"'   --data-raw '{"proPlanName":"CP7","emailId":"","tempToken":""}' | jq -r '.data.pnrResponse' > out1.txt
	trainNo=$(cat out1.txt | jq -r '.trainNo')
	if [ ${#trainNo} -ne 0 ]
	then
		isSendMail="N"
		emailReplyPrefix=""
		trainName=$(cat out1.txt | jq '.trainName')
		doj=$(cat out1.txt | jq '.doj')
		boardingPoint=$(cat out1.txt | jq '.boardingPoint')
		reservationUpto=$(cat out1.txt | jq '.reservationUpto')
		class=$(cat out1.txt | jq '.class')
		cat out1.txt | jq -r '[.passengerStatus[] | {Passenger: .number, BookingStatus: .bookingStatus, CurrentStatus: .currentStatus} | with_entries( select( .value != null ) )]' >> pnr_temp_$pnr.txt
		if [ -f "pnr_data_$pnr.txt" ]
		then
			emailReplyPrefix="Re:"
			diffVal=$(diff pnr_temp_$pnr.txt pnr_data_$pnr.txt)
			diffValLength=${#diffVal}
			if [ $diffValLength -gt 0 ]
			then
				isSendMail="Y"
			fi
		else
			isSendMail="Y"
		fi
		mv pnr_temp_$pnr.txt pnr_data_$pnr.txt
		if [ "$isSendMail" = "Y" ]
		then
			cat pnr_data_$pnr.txt | mail -s "$emailReplyPrefix PNR $pnr - $trainNo - $trainName - $doj - $boardingPoint to $reservationUpto - $class" shankarsan.ganai@icloud.com,nairitamganai@gmail.com,tkganaintpc@gmail.com
			curl --location --request POST 'http://129.154.37.114:5001/v1/message/battery_level' \
			--header 'Content-Type: application/json' \
			--data-raw '{
			    "pulseCount": 1,
			    "pulseMillis": 100,
			    "intervalMillis": 0
			}'
		fi
		rm out1.txt
	fi
done
