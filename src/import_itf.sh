#!/bin/bash

# LOOP THROUGH ITF FILES AND LOAD INTO DATABASE.

usage="$(basename "$0") [-h] [-f SFOLDER] [-H HOST] [-p PORT] [-U USER] [-w PASSWORD] [-d DATABASE] [-s SCHEMA] [-n TIDNAME]
Import interlis files stored in a given folder into a Postgres database. Requires that the schema is already present in the database:
	-h show this help text
	-f source folder (containing interlis files)
	-H database host
	-p database port
	-U database user
	-w database password
	-d database name
	-s database schema
	-n name of the tid column"


# Get parameters.
while getopts :hf:H:p:U:w:d:s:n: flag
do
        case "${flag}" in
		h) echo "$usage"; exit;;
                f) sfolder=${OPTARG};;
                H) host=${OPTARG};;
                p) port=${OPTARG};;
                U) user=${OPTARG};;
		w) password=${OPTARG};;
		d) database=${OPTARG};;
		s) schema=${OPTARG};;
		n) tidname=${OPTARG};;
		:) printf "missing argument for -%s\n" "$OPTARG" >&2; echo "$usage" >&2; exit 1;;
               \?) printf "illegal option: -%s\n" "$OPTARG" >&2; echo "$usage" >&2; exit 1;;
        esac
done


# Make parameters mandatory
if [ ! ${sfolder} ] || [ ! ${host} ] || [ ! ${port} ] || [ ! ${user} ] || [ ! ${password} ] || [ ! ${database} ] || [ ! ${schema} ] || [ ! ${tidname} ]; then
  echo "arguments -f, -H, -p, -U, -w, -d, -s and -n must be provided"
  echo "$usage" >&2; exit 1
fi


# Run ili2db.
for f in $sfolder/*.itf; 
do
	echo ========================= $f =========================
	datasetname=$(basename $f .itf)
	java -jar "./lib/ili2pg-4.9.0/ili2pg-4.9.0.jar" --replace --dbhost $host --dbport $port --dbusr $user --dbpwd $password --dbdatabase $database --dbschema $schema --t_id_Name $tidname --importTid --importBid --disableValidation --dataset $datasetname $f 2>&1
done
