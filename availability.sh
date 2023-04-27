#!/bin/bash
get_availability_data () {
	#nanoseconds=$(date +%s%N | cut -b1-13)
	emailReplyPrefix=""
	isSendMail="N"
	curl --location -o data1.txt --request GET 'https://securedapi.confirmtkt.com/api/platform/trainbooking/avlFareenquiry?trainNo='$1'&travelClass='$2'&quota='$3'&fromStnCode='$4'&destStnCode='$5'&doj='$6'&token=204F97FDBEBA275624E386BD688AE83E94E87D37364787DC5AD51D3C05E47F58&planZeroCan=RO-E1&appVersion=290'

	if [ "$(jq -R 'fromjson? | .trainName' data1.txt)" != null ] && [ "$(jq -R 'fromjson? | .trainName' data1.txt)" != "" ]
	then
		if [ -f "data_$1_$2_$3_$4_$5_$6.txt" ]
		then
			emailReplyPrefix="Re:"
			jq .avlDayList[] data1.txt >> temp1.txt
			jq .avlDayList[] data_$1_$2_$3_$4_$5_$6.txt >> temp2.txt
			diffVal=$(diff temp1.txt temp2.txt)
			rm  temp1.txt temp2.txt
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
			cat data1.txt | jq '{Timestamp: .timeStamp, TrainName: .trainName, TrainNo: .trainNo, From: .from, To: .to, Class: .enqClass, Quota: .quota}, {Status: .avlDayList[] | {DOJ: .availablityDate, Availability: .availablityStatus}}' | mail -s "$emailReplyPrefix Availability Status for $1 on $6 from $4 to $5 in class $2 in quota $3" $7
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
		mv data1.txt data_$1_$2_$3_$4_$5_$6.txt
	fi
}

while IFS= read -r line
do
	find . -maxdepth 1 -type f -mtime +7 -name 'data*.txt' -exec rm {} \;
	get_availability_data $line
done < availability_list.txt
