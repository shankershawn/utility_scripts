#!/bin/bash
get_website_data () {
	code=$(curl -s -o /dev/null -w "%{http_code}" https://ess.excelityglobal.com/)
	if "200" -eq $code
	then
		echo $code
		curl --location --request POST 'http://129.154.37.114:5001/v1/message/battery_level' \
		--header 'Content-Type: application/json' \
		--data-raw '{
		    "pulseCount": 50,
		    "pulseMillis": 100,
		    "intervalMillis": 50
		}'
	fi
}
while IFS= read -r line
do
        get_website_data $line
done < website_list.txt
