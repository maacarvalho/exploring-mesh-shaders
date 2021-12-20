#!/usr/bin/bash

if [ $# -ne 1 ] 
then

    echo "Illegal number of parameters" >&2
    exit 1

fi

filepath=$1

dirname=$(dirname $filepath)
basename=$(basename $filepath)

if [[ "${basename#*.}" != "obj" ]] 
then

    echo "Only designed to randomize Wavefront (.obj) files." >&2
    exit 2

fi

awk 'BEGIN{srand(); counter=0.0; type=""} 
     /^mtllib/  {counter=counter+1; printf("%.5f %s\n", counter, $0); type="mtllib";}
     /^v /      {counter=counter+1; printf("%.5f %s\n", counter, $0); type="v";}
     /^vn /     {counter=counter+1; printf("%.5f %s\n", counter, $0); type="vn";}
     /^vt /     {counter=counter+1; printf("%.5f %s\n", counter, $0); type="vt";}
     /^usemtl / {counter=counter+1; printf("%.5f %s\n", counter, $0); type="usemtl";}
     /^f /      {if (type != "f") counter=counter+1; printf("%.5f %s\n", counter+rand(), $0); type="f";}' \
         "$dirname/$basename" \
    | sort -n -k 1 \
    | awk 'sub(/\S* /,"")' > "$dirname/${basename%%.obj}.rand.obj"
