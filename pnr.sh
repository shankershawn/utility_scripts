#!/bin/bash
for pnr in $(awk '{print $1}' pnrlist.txt)
do
	curl -s -o out1.txt https://www.confirmtkt.com/pnr-status/$pnr
	trainNo=$(cat out1.txt | grep BookingStatusIndex | sed 's|data = ||' | sed 's|};|}|' | jq -r '.TrainNo')
	if [ ${#trainNo} -ne 0 ]
	then
		isSendMail="N"
		emailReplyPrefix=""
		trainName=$(cat out1.txt | grep BookingStatusIndex | sed 's|data = ||' | sed 's|};|}|' | jq -r '.TrainName')
		doj=$(cat out1.txt | grep BookingStatusIndex | sed 's|data = ||' | sed 's|};|}|' | jq -r '.Doj')
		boardingPoint=$(cat out1.txt | grep BookingStatusIndex | sed 's|data = ||' | sed 's|};|}|' | jq -r '.BoardingPoint')
		reservationUpto=$(cat out1.txt | grep BookingStatusIndex | sed 's|data = ||' | sed 's|};|}|' | jq -r '.ReservationUpto')
		class=$(cat out1.txt | grep BookingStatusIndex | sed 's|data = ||' | sed 's|};|}|' | jq -r '.Class')
		cat out1.txt | grep BookingStatusIndex | sed 's|data = ||' | sed 's|};|}|' | jq -r '[.PassengerStatus[] | {Passenger: .Number, BookingStatus: .BookingStatus, CurrentStatus: .CurrentStatus, Prediction: .Prediction, ConfirmationStatus: .ConfirmTktStatus} | with_entries( select( .value != null ) )]' >> pnr_temp_$pnr.txt
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
			cat pnr_data_$pnr.txt | mail -s "$emailReplyPrefix PNR $pnr - $trainNo - $trainName - $doj - $boardingPoint to $reservationUpto - $class" shankershawn@gmail.com,nairitamganai@gmail.com,tkganaintpc@gmail.com
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
