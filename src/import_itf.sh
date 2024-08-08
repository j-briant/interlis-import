#!/bin/bash

# LOOP THROUGH ITF FILES AND LOAD INTO DATABASE.

usage="$(basename "$0") [-h] [-i INTERLISDATA] [-H HOST] [-p PORT] [-U USER] [-w PASSWORD] [-d DATABASE] [-s SCHEMA] [-n TIDNAME]
Import interlis files stored in a given folder into a Postgres database. Requires that the schema is already present in the database:
    -h show this help text
    -i source data (a single file or a folder)
    -H database host
    -p database port
    -U database user
    -w database password
    -d database name
    -s database schema
    -t name of the tid column"

# Die function
die() {
  printf '%s\n' "$1" >&2
  exit 1
}

# Get parameters
while :; do
    case $1 in
        -h|-\?|--help)
			echo "$usage"
			exit;;
        -i|--interlis-data)
            if [ "$2" ]; then
                interlisdata=$2
                shift
            else
                die 'ERROR: "--interlis-data" requires a non-empty option argument.'
            fi;;
        -U|--user)
            if [ "$2" ]; then
                user=$2
                shift
            else
                die 'ERROR: "--user" requires a non-empty option argument.'
            fi;;
        -H|--host)
            if [ "$2" ]; then
                host=$2
                shift
            else
                die 'ERROR: "--host" requires a non-empty option argument.'
            fi;;
        -p|--port)
            if [ "$2" ]; then
                port=$2
                shift
            else
                die 'ERROR: "--port" requires a non-empty option argument.'
            fi;;
        -w|--password)
            if [ "$2" ]; then
                password=$2
                shift
            else
                die 'ERROR: "--password" requires a non-empty option argument.'
            fi;;
        -d|--database)
            if [ "$2" ]; then
                database=$2
                shift
            else
                die 'ERROR: "--database" requires a non-empty option argument.'
            fi;;
        -s|--schema)
            if [ "$2" ]; then
                schema=$2
                shift
            else
                die 'ERROR: "--schema" requires a non-empty option argument.'
            fi;;
        -t|--tidname)
            if [ "$2" ]; then
                tidname=$2
                shift
            else
                die 'ERROR: "--tidname" requires a non-empty option argument.'
            fi;;
        --)
            shift
            break
            ;;
        -?*)
            printf 'WARN: Unknown option (ignored): %s\n' "$1" >&2
            ;;
        *)
            break
    esac
    shift
done

# Make parameters mandatory
if [ ! "${interlisdata}" ] || [ ! "${host}" ] || [ ! "${port}" ] || [ ! "${user}" ] || [ ! "${password}" ] || [ ! "${database}" ] || [ ! "${schema}" ] || [ ! "${tidname}" ]; then
    echo "arguments -i, -H, -p, -U, -w, -d, -s and -t must be provided"
    echo "$usage" >&2; exit 1
fi


# Run ili2db.
if [[ -d "$interlisdata" ]]; then
    for f in "$interlisdata"/*.itf;
    do
        echo "========================= $f ========================="
        datasetname=$(basename "$f" .itf)
        java -jar "/opt/ili2pg-5.1.0/ili2pg-5.1.0.jar" --replace --dbhost "$host" --dbport "$port" --dbusr "$user" --dbpwd "$password" --dbdatabase "$database" --dbschema "$schema" --t_id_Name "$tidname" --importTid --importBid --disableValidation --dataset "$datasetname" "$f" 2>&1
    done
elif [[ -f "$interlisdata" ]]; then
        java -jar "/opt/ili2pg-5.1.0/ili2pg-5.1.0.jar" --replace --dbhost "$host" --dbport "$port" --dbusr "$user" --dbpwd "$password" --dbdatabase "$database" --dbschema "$schema" --t_id_Name "$tidname" --importTid --importBid --disableValidation --dataset "$datasetname" "$interlisdata" 2>&1
fi

