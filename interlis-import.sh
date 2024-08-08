#!/usr/bin/bash

# This script is the main script for updating data from interlis. Processes are:
#	1. Backing-up the database if desired
#	2. Creating the Postgres schema from the Interlis file model
#	3. Importing downloaded Interlis files into the newly created schema

usage="$(basename "$0") [-h] [-b]
Create the model structure into a schema and import data from interlis:
    -h show this help text
    -f output format (gpkg or pg)
    -b backup database schema before anything (must run with backup privilege)"

# Get environment variables.
. .env

# Get command parameters, overwriting .env values if present.
while :; do
    case $1 in
        -h|-\?|--help)
            echo "$usage"
            exit;;
        -b|--backup)
            BACKUP=true;;
        -f|--format)
            if [ "$2" ]; then
                FORMAT=$2
                shift
            else
                die 'ERROR: "--format" requires a non-empty option argument. Must be either "pg" or "gpkg".'
            fi;;
        -U|--user)
            if [ "$2" ]; then
                USER=$2
                shift
            else
                die 'ERROR: "--user" requires a non-empty option argument.'
            fi;;
        -d|--database)
            if [ "$2" ]; then
                DATABASE=$2
                shift
            else
                die 'ERROR: "--database" requires a non-empty option argument.'
            fi;;
        -H|--host)
            if [ "$2" ]; then
                HOST=$2
                shift
            else
                die 'ERROR: "--host" requires a non-empty option argument.'
            fi;;
        -p|--port)
            if [ "$2" ]; then
                PORT=$2
                shift
            else
                die 'ERROR: "--port" requires a non-empty option argument.'
            fi;;
        -w|--password)
            if [ "$2" ]; then
                PASSWORD=$2
                shift
            else
                die 'ERROR: "--password" requires a non-empty option argument.'
            fi;;
        -s|--schema)
            if [ "$2" ]; then
                SCHEMA=$2
                shift
            else
                die 'ERROR: "--schema" requires a non-empty option argument.'
            fi;;
        -f|--interlis-model-file)
            if [ "$2" ]; then
                INTERLISMODELFILE=$2
                shift
            else
                die 'ERROR: "--interlis-model-file" requires a non-empty option argument.'
            fi;;
        -i|--interlis-data)
            if [ "$2" ]; then
                INTERLISDATA=$2
                shift
            else
                die 'ERROR: "--interlis-data" requires a non-empty option argument.'
            fi;;
        -m|--interlis-model-name)
            if [ "$2" ]; then
                MODEL=$2
                shift
            else
                die 'ERROR: "--interlis-model-name" requires a non-empty option argument.'
            fi;;
         -t|--tidname)
            if [ "$2" ]; then
                T_ID_NAME=$2
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

# Make sure mandatory parameters are passed, either from the .env or the command line
if [ "$FORMAT" = "pg" ]; then
    if [ ! "${USER}" ] || [ ! "${HOST}" ] || [ ! "${PORT}" ] || [ ! "${SCHEMA}" ] || [ ! "${DATABASE}" ] || [ ! "${PASSWORD}" ] || [ ! "${TIDNAME}" ] || [ ! "${INTERLISMODELFILE}" ] || [ ! "${MODEL}" ]; then
        echo "arguments -U, -h, -p, -s, -d, -w, -t, -f and -m must be provided"
        echo "$usage" >&2; exit 1
    fi
elif [ "$FORMAT" = "gpkg" ]; then
    if [ ! "${TIDNAME}" ] || [ ! "${INTERLISMODELFILE}" ] || [ ! "${MODEL}" ]; then
        echo "arguments -d, -t, -f and -m must be provided"
        echo "$usage" >&2; exit 1
    fi
fi

# Get start time.
echo "START TIME: $(date +"%T")"

# BACKUP
if [ "$BACKUP" = true ]; then
        echo "===================================== BACKING UP DATABASE ====================================="
        PGPASSWORD="$PASSWORD" pg_dump "$DATABASE" -n "$SCHEMA" -Fc > backup_"$(date +"%Y%m%d%H%M%S")".dmp
fi

# IMPORT INTERLIS FILES.
{
    echo "===================================== CREATE SCHEMAS ====================================="
    echo "Creating schema..."
    src/create_schema.sh -U "$USER" -p "$PORT" -H "$HOST" -s "$SCHEMA" -d "$DATABASE" -w "$PASSWORD" -t "$T_ID_NAME" -f "$INTERLISMODELFILE" -m "$MODEL" -E -T -B

    echo "===================================== IMPORT DATA ====================================="
    echo "Importing data from Interlis files..."
    src/import_itf.sh -U "$USER" -p "$PORT" -H "$HOST" -s "$SCHEMA" -d "$DATABASE" -w "$PASSWORD" -t "$T_ID_NAME" -i "$INTERLISDATA"
}

# Get end time.
echo "END TIME: $(date +"%T")"

