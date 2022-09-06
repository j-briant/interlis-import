#!/usr/bin/bash

# DOWNLOAD ITF FILES
# Parameters:
#	%c cities numbers json file
#	%a authorization
#	%l download link
#	%f destination folder 
  
# Get parameters.
while getopts c:a:l:f: flag
do
	case "${flag}" in
		c) communes=${OPTARG};;
		a) authorization=${OPTARG};;
		l) dlink=${OPTARG};;
		f) dfolder=${OPTARG};;
	esac
done

# Create output folder if not exists
mkdir -p $dfolder

# Load communes into a structured array.
declare -A communes_arr
while IFS="=" read -r key value
do
	communes_arr[$key]="$value"
done < <(jq -r 'to_entries|map("\(.key)=\(.value)")|.[]' $communes)


# Loop through the structured array and download the interlis files.
for key in "${!communes_arr[@]}"; do
	curl -H "authorization: $authorization" "$dlink/$key" --output $dfolder/${communes_arr[$key]}.itf 2>&1
done

# Echo final words.
echo DOWNLOAD HAS FINISHED
