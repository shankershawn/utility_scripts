#!/bin/bash
for pnr in $(awk '{print $1}' pnrlist.txt)
do
	curl -s -o out1.txt https://www.confirmtkt.com/pnr-status/$pnr
	trainNo=$(cat out1.txt | grep BookingStatusIndex | sed 's|var data = ||' | sed 's|};|}|' | jq -r '.TrainNo')
	trainName=$(cat out1.txt | grep BookingStatusIndex | sed 's|var data = ||' | sed 's|};|}|' | jq -r '.TrainName')
	doj=$(cat out1.txt | grep BookingStatusIndex | sed 's|var data = ||' | sed 's|};|}|' | jq -r '.Doj')
	boardingPoint=$(cat out1.txt | grep BookingStatusIndex | sed 's|var data = ||' | sed 's|};|}|' | jq -r '.BoardingPoint')
	reservationUpto=$(cat out1.txt | grep BookingStatusIndex | sed 's|var data = ||' | sed 's|};|}|' | jq -r '.ReservationUpto')
	class=$(cat out1.txt | grep BookingStatusIndex | sed 's|var data = ||' | sed 's|};|}|' | jq -r '.Class')
	mail_body=$(cat out1.txt | grep BookingStatusIndex | sed 's|var data = ||' | sed 's|};|}|' | jq -r '.PassengerStatus[] | {Passenger: .Number, BookingStatus: .BookingStatus, CurrentStatus: .CurrentStatus, Prediction: .Prediction, ConfirmationStatus: .ConfirmTktStatus} | with_entries( select( .value != null ) )')
	echo $mail_body | mail -s "PNR $pnr - $trainNo - $trainName - $doj - $boardingPoint to $reservationUpto - $class" shankershawn@gmail.com,nairitamganai@gmail.com,tkganaintpc@gmail.com
	rm out1.txt
done
