#!/bin/bash
for script_name in $(awk '{print $1}' scriptlist.txt)
do
	sh $script_name > out_tmp_$script_name.txt
	if [ -f out_tmp_$script_name.txt ]
	then
		isSendMail="N"
		emailReplyPrefix=""
		if [ -f out_$script_name.txt ]
		then
			emailReplyPrefix="Re:"
			diffVal=$(diff out_tmp_$script_name.txt out_$script_name.txt)
			diffValLength=${#diffVal}
			if [ $diffValLength -gt 0 ]
			then
				isSendMail="Y"
			fi
		else
			isSendMail="Y"
		fi
		mv out_tmp_$script_name.txt out_$script_name.txt
		if [ "$isSendMail" = "Y" ]
		then
			cat out_$script_name.txt | mail -s "$emailReplyPrefix Invoked $script_name" shankarsan.ganai@icloud.com,nairitamganai@gmail.com,tkganaintpc@gmail.com
			curl --location --request POST 'http://129.154.37.114:5001/v1/message/battery_level' \
			--header 'Content-Type: application/json' \
			--data-raw '{
			    "pulseCount": 1,
			    "pulseMillis": 100,
			    "intervalMillis": 0
			}'
		fi
	fi
done
