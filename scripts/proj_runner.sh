#!/usr/bin/bash

project_files=$(ls | awk '/.nau/ {print $0}')

for proj in $project_files
do 
    
    echo "Running: $proj"

    # Running Nau project
    cmd.exe /C start $proj

    # Waiting for Nau project to finish
    while [[ ! -z $(tasklist.exe | awk '/composerImGui/ {print $0}') ]]
    do
        sleep 1
    done

done
