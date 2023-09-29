#!/usr/bin/bash

# DOWNLOAD ITF FILES

usage="$(basename "$0") [-h] [-c COMMUNES] [-a AUTHORIZATION] [-l DLINK] [-f DFOLDER]
Download ASIT-VD interlis files based on a list of city numbers:
	-h show this help text
	-c cities numbers json file
	-a authorization
	-l download link
	-f destination folder"

# Get parameters.
while getopts :hc:a:l:f: flag
do
	case "${flag}" in
		h) echo "$usage"; exit;;
		c) communes=${OPTARG};;
		a) authorization=${OPTARG};;
		l) dlink=${OPTARG};;
		f) dfolder=${OPTARG};;
		:) printf "missing argument for -%s\n" "$OPTARG" >&2; echo "$usage" >&2; exit 1;;
               \?) printf "illegal option: -%s\n" "$OPTARG" >&2; echo "$usage" >&2; exit 1;;
	esac
done

# Make parameters mandatory
if [[ ( ! ${communes} ) || ( ! ${authorization} ) || ( ! ${dlink} ) || ( ! ${dfolder} ) ]] ; then
  echo "arguments -c, -a, -l and -f must be provided"
  echo "$usage" >&2; exit 1
fi


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
