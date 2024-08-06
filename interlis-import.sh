#!/usr/bin/bash

# This script is the main script for updating data from interlis. Processes are:
#	1. Backing-up the database if desired
#	2. Creating the Postgres schema from the Interlis file model
#	3. Importing downloaded Interlis files into the newly created schema

usage="$(basename "$0") [-h] [-b]
Create the model structure into a schema and import data from interlis:
    -h show this help text
    -b backup database schema before anything (must run with backup privilege)"

# Get parameters.
while :; do
    case $1 in
        -h|-\?|--help)
            echo "$usage"
            exit;;
        -b|--backup)
            backup=true;;
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

# Get environment variables.
. .env

# Get start time.
echo "START TIME: $(date +"%T")"

# BACKUP
if [ "$backup" = true ]; then
        echo "===================================== BACKING UP DATABASE ====================================="
        PGPASSWORD="$PASSWORD" pg_dump "$DATABASE" -n "$SCHEMA" -Fc > backup_"$(date +"%Y%m%d%H%M%S")".dmp
fi

# IMPORT INTERLIS FILES.
{
    echo "===================================== CREATE SCHEMAS ====================================="
    echo "Creating schema..."
    src/create_schema.sh -U "$USER" -p "$PORT" -H "$HOST" -s "$SCHEMA" -d "$DATABASE" -w "$PASSWORD" -n "$T_ID_NAME" -i "$INTERLISMODELFILE" -m "$MODEL" -E -T -B

    echo "===================================== IMPORT DATA ====================================="
    echo "Importing data from Interlis files..."
    src/import_itf.sh -U "$USER" -p "$PORT" -H "$HOST" -s "$SCHEMA" -d "$DATABASE" -w "$PASSWORD" -n "$T_ID_NAME" -i "$INTERLISDATA"
}

# Get end time.
echo "END TIME: $(date +"%T")"

