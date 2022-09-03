#!/bin/bash
http_response=$(curl -s -o /dev/null -w "%{http_code}" https://www.google.com)
if [ $http_response != "200" ]; then
    echo "Connection dropped. Restarting eth0 network interface"
    echo "Connection dropped. Restarting eth0 network interface" | mail -s "Connection dropped. Restarting eth0 network interface" shankershawn@gmail.com
    sudo ifconfig eth0 down && sudo ifconfig eth0 up
else
    echo "Connection available"
fi
