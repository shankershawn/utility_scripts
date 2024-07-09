#!/bin/bash
curl -s --location 'http://129.154.37.114:5001/v1/message/battery_level' --header 'Content-Type: application/json' --data '{"pulseCount": 3, "pulseMillis": 200, "intervalMillis": 300}' > /dev/null
