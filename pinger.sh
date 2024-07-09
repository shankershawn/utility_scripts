#!/bin/bash

#http_response=$(curl -s -o /dev/null -w "%{http_code}" https://www.google.com)
#if [ $http_response != "200" ]; then
#    sudo ifconfig eth0 down && sudo ifconfig eth0 up
#    echo "Connection dropped. Restarted eth0 network interface" | mail -s "Connection dropped. Restarted eth0 network interface" shankershawn@gmail.com
#else
#    echo "Connection available"
#fi

#Below section is for restarting docker service in case docker network loses connectivity
statement=$(/usr/sbin/ifconfig | grep docker0)
echo $(date)-$statement >> /home/pi/docker-start.log
if [[ $statement == *"docker0"* ]]; then
    echo $(date)-"docker is up" >> /home/pi/docker-start.log
else
    echo $(date)-"Docker connection dropped. Restarting docker service" >> /home/pi/docker-start.log
    sudo service docker restart
    echo "Docker connection dropped. Restarted docker service" | mail -s "Docker connection dropped. Restarted docker service" shankershawn@gmail.com
fi
