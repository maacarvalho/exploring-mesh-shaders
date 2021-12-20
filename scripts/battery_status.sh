#!/usr/bin/bash

old_status="2"

while true
    do 
        sleep 1s
        new_status=$(WMIC.exe Path Win32_Battery Get BatteryStatus | head -2 | tail -1)
        #echo "Status: ${new_status:0:1}"
        if [[ "${new_status:0:1}" != "${old_status:0:1}" ]]
        then 
            old_status=$new_status
            if [[ "${new_status:0:1}" != "2" ]]
            then
                echo "NOT On Power" 
            fi
        fi 
    done
