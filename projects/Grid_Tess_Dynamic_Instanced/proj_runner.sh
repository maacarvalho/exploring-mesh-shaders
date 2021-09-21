#!/usr/bin/bash

#for n in {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20}
#do

    project_files=$(ls | awk '/.nau/ {print $0}' | shuf)

    for proj in $project_files
    do 
   
        #echo "Running: $proj [$n]"

        # Running Nau project
        cmd.exe /C start $proj

        # Waiting for Nau project to finish
        while [[ ! -z $(tasklist.exe | awk '/composerImGui/ {print $0}') ]]
        do
            sleep 1
        done
    done

#done
