#!/bin/bash
if [ $(docker logs -n 50 raspi-alarm-server | grep -c PI_INIT_FAILED) -gt 0 ]
then
	echo "Initiating raspi-alarm-server-reset" | mail -s "Initiating raspi-alarm-server-reset" shankershawn@gmail.com,saurajyoti.kar@gmail.com
	docker stop raspi-alarm-server
	docker rm raspi-alarm-server
	docker run -tid --restart=always --pull=always --name=raspi-alarm-server --privileged shankershawn/raspi-alarm-server:armv7
	echo "Completed raspi-alarm-server-reset" | mail -s "Completed raspi-alarm-server-reset" shankershawn@gmail.com,saurajyoti.kar@gmail.com
fi
