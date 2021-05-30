#!/usr/bin/bash

## Calculates the miss ratio of the buffer
# Arguments
# 1 - Buffer file path
calculate_miss_ratio () {

    declare sum
    declare -i lines
    declare -i words
    declare -i hits
    declare -i miss

    sum=0
    lines=0
    hits=0
    miss=0

    for buf in $(ls $1/$basename.*.primitives.buf)
    do
        while read line 
        do
            
            unset indices
            declare -A indices

            for token in $(echo $line)
            do
                
                if [[ -z "${indices[$token]}" ]]; then

                    miss+=1
                    indices[$token]=1

                else

                    hits+=1

                fi

            done

            lines+=1
            sum=$(bc -l <<< "$sum + ($hits / ($hits + $miss))")

        done < $buf
    done

    echo "$(basename $1) -> $lines -> "$(bc -l <<< "$sum / $lines") >> "$dirname/ratios.txt"

}

## Main
if [ $# -ne 1 ] 
then

    echo "Illegal number of parameters" >&2
    exit 1

fi

filepath=$1
dirname=$(dirname $filepath)
basename=$(basename $filepath)

for buf_dir in $(ls $dirname/buffers)
do

    if [[ -d "$dirname/buffers/$buf_dir" ]]
    then
        
        calculate_miss_ratio $dirname/buffers/$buf_dir &

    fi

done

wait
