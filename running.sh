#!/bin/bash
get_running_data () {
	#nanoseconds=$(date +%s%N | cut -b1-13)
	emailReplyPrefix=""
	isSendMail="N"
	curl --location -o run_data1.txt --request GET 'https://www.trainman.in/services/get-ntes-running-status/'$1'?key=012562ae-60a9-4fcd-84d6-f1354ee1ea48&int=1&refresh=true&date='$2'%20'$3'%20'$4'&time=1682403852871'

#	if [ "$(jq -R 'fromjson? | .trainName' data1.txt)" != null ] && [ "$(jq -R 'fromjson? | .trainName' data1.txt)" != "" ]
#	then
		if [ -f "run_data_$1_$2_$3_$4.txt" ]
		then
			emailReplyPrefix="Re:"
			DATE="$2 $3 $4" jq '[.rakes[] | select(.startDate == env.DATE) | .stations[] | select(.stops | contains(1)) | select(.arr == true) | select(.delay != -1)] | sort_by(.distance) | last | {"station code": .scode, "station name": .sname, "arrival": .actArr, "departure": .actDep, "delay": .delayDep}' run_data1.txt >> temp1.txt
			DATE="$2 $3 $4" jq '[.rakes[] | select(.startDate == env.DATE) | .stations[] | select(.stops | contains(1)) | select(.arr == true) | select(.delay != -1)] | sort_by(.distance) | last | {"station code": .scode, "station name": .sname, "arrival": .actArr, "departure": .actDep, "delay": .delayDep}' run_data_$1_$2_$3_$4.txt >> temp2.txt
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
			cat run_data1.txt | DATE="$2 $3 $4" jq '[.rakes[] | select(.startDate == env.DATE) | .stations[] | select(.stops | contains(1)) | select(.arr == true) | select(.delay != -1)] | sort_by(.distance) | last | {"station code": .scode, "station name": .sname, "arrival": .actArr, "departure": .actDep, "delay": .delayDep}' | mail -s "$emailReplyPrefix Running Status for $1 on $2-$3-$4" $5
			if [ "$6" = "Y" ]
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
		mv run_data1.txt run_data_$1_$2_$3_$4.txt
#	fi
}

while IFS= read -r line
do
	find . -maxdepth 1 -type f -mtime +7 -name 'run_data*.txt' -exec rm {} \;
	get_running_data $line
done < running_list.txt
