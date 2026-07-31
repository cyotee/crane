#!/bin/bash
# Create filter from first arg, removing quote escapes
filter=$(echo "$1" | tr -d '\\')
result=$(jq -c "$filter" "$2")
array=(`echo $result | tr -d '"[]' | tr ',' ' ' `)
arraylength=${#array[@]}
for (( i=0; i<${arraylength}; i++ ));
do
    array[$i]=$(cast --to-hexdata ${array[$i]})
done
result="["$(echo ${array[@]} | tr ' ' ', ')"]"
cast abi-encode "result(bytes[])" $result
