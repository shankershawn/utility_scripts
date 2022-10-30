#!/bin/bash
get_availability_data () {
	nanoseconds=$(date +%s%N | cut -b1-13)
	isSendMail="N"
	curl --location -o avail1.txt --request POST 'https://www.irctc.co.in/eticketing/protected/mapps1/avlFarenquiry/'$1'/'$2'/'$3'/'$4'/'$5'/'$6'/N' \
	--header 'Accept:  application/json, text/plain, */*' \
	--header 'bmirak:  webbm' \
	--header 'Content-Language:  en' \
	--header 'Content-Type:  application/json; charset=UTF-8' \
	--header 'greq: $nanoseconds' \
	--data-raw '{
	    "paymentFlag": "N",
	    "concessionBooking": false,
	    "ftBooking": false,
	    "loyaltyRedemptionBooking": false,
	    "ticketType": "E",
	    "moreThanOneDay": true,
	    "isLogedinReq": false
	}'
	if [ -f "avail_$1_$2_$3_$4_$5_$6.txt" ]
	then
		jq .avlDayList[] avail1.txt >> temp1.txt
		jq .avlDayList[] avail_$1_$2_$3_$4_$5_$6.txt >> temp2.txt
		diffVal=$(diff temp1.txt temp2.txt)
		rm  temp1.txt temp2.txt
		#diffVal="abc"
		diffValLength=${#diffVal}
		if [ $diffValLength -gt 0 ]
		then
			isSendMail="Y"
		fi
	else
		isSendMail="Y"
	fi

	if [ "$isSendMail" = "Y" ]
	then
		cat avail1.txt | jq '{Timestamp: .timeStamp, TrainName: .trainName, TrainNo: .trainNo, From: .from, To: .to, Class: .enqClass, Quota: .quota}, {Status: .avlDayList[] | {DOJ: .availablityDate, Availability: .availablityStatus}}' | mail -s "Availability Status for $1 on $2 from $3 to $4 in class $5 in quota $6" $7
		if [ "$8" = "Y" ]
		then
			curl --location --request POST 'http://129.154.37.114:5001/v1/message/battery_level' \
			--header 'Content-Type: application/json' \
			--data-raw '{
			    "pulseCount": 1,
			    "pulseMillis": 100,
			    "intervalMillis": 0
			}'
		fi
	fi
	mv avail1.txt avail_$1_$2_$3_$4_$5_$6.txt
}

while IFS= read -r line
do
	get_availability_data $line
done < availability_list.txt
