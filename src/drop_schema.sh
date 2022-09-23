#!/bin/bash

# DROP THE DATABASE SCHEMA

usage="$(basename "$0") [-h] [-S SERVICE] [-s SCHEMA]
Drop a schema from a database:
    -h  show this help text
    -S  service connection name
    -s  source database schema"

# Get parameters.
while getopts :hS:s: flag
do
        case "${flag}" in
		h) echo "$usage"; exit;;
                S) service=${OPTARG};;
                s) schema=${OPTARG};;
       		:) printf "missing argument for -%s\n" "$OPTARG" >&2; echo "$usage" >&2; exit 1;;
               \?) printf "illegal option: -%s\n" "$OPTARG" >&2; echo "$usage" >&2; exit 1;;
       	esac
done

# Make parameters mandatory
if [ ! ${service} ] || [ ! ${schema} ]; then
  echo "arguments -S and -s must be provided"
  echo "$usage" >&2; exit 1
fi


# Run the DROP query
psql -d "service=$service" -c "DROP SCHEMA IF EXISTS $schema CASCADE;" 2>&1
