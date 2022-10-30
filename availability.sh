#!/bin/bash
get_availability_data () {
	nanoseconds=$(date +%s%N | cut -b1-13)
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
	cat avail1.txt | jq '{Timestamp: .timeStamp, TrainName: .trainName, TrainNo: .trainNo, From: .from, To: .to, Class: .enqClass, Quota: .quota}, {Status: .avlDayList[] | {DOJ: .availablityDate, Availability: .availablityStatus}}' | mail -s "Availability Status for $1 on $2 from $3 to $4 in class $5 in quota $6" $7
	rm avail1.txt
}

while IFS= read -r line
do
	get_availability_data $line
done < availability_list.txt
