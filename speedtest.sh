#!/bin/bash
docker run --rm --pull always shankershawn/speedtest:latest > speedtest.log
mail -s "F-ing Speedtest from RaspberryPi" shankershawn@gmail.com < speedtest.log
rm speedtest.log

