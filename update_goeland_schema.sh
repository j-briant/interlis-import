#!/bin/bash

# TRUNCATE GOELAND SCHEMA THEN DUMP/RESTORE FROM GOELAND DATABASE.

usage="$(basename "$0") [-h] [-d DATABASE]
Update data in goeland schema. Truncates tables, then dump, sed and restore in a pipe.        
	-h show this help text
        -d database name"

# Get parameters.
while getopts :hf:H:p:U:w:d:s:n: flag
do
        case "${flag}" in
                h) echo "$usage"; exit;;
                d) database=${OPTARG};;
                :) printf "missing argument for -%s\n" "$OPTARG" >&2; echo "$usage" >&2; exit 1;;
               \?) printf "illegal option: -%s\n" "$OPTARG" >&2; echo "$usage" >&2; exit 1;;
        esac
done


# Make parameters mandatory
if [ ! ${database} ] ; then
  echo "arguments -d must be provided"
  echo "$usage" >&2; exit 1
fi

# Get configuration variables
. /etc/update_guichet/paths.conf

# Get environment variables
. $CONFPATH/.env

# Get date.
RUNDATE=$(date +"%Y%m%d")

# Log folder variable
LOGNAME=$(basename "$0")
LOGFILE=$LOG_PATH/$LOGNAME.log
ERRORFILE=$LOG_PATH/$LOGNAME.error
RUNTIMEFILE=$LOG_PATH/$LOGNAME.runtime

# Create folder if not exists
mkdir -p $LOGNAME

# Get start time.
echo START TIME: $(date +"%T") > $LOGFILE


# Run psql.
truncate_command="
	DO \$$
	DECLARE r record;
	BEGIN
	FOR r in (SELECT table_schema, table_name FROM information_schema.tables where table_schema = 'goeland')
	LOOP
		EXECUTE 'TRUNCATE ' || r.table_schema || '.' || r.table_name || ';';
	END LOOP;
	END \$$;	
	"

echo ============================= TRUNCATING THE GOELAND SCHEMA =============================
echo "$truncate_command" | su - postgres -c "psql $database" >> $LOGFILE 2>&1

echo ============================= BACKUP AND RESTORE FROM GOELAND =============================
# Backup and restore goeland data.
su - postgres -c "pg_dump goeland -a -n public -T spatial_ref_sys -T goeland_addresse_lausanne" | sed 's/public\./goeland\./g' | su - postgres -c "psql $database" >> $LOGFILE 2>&1



# Get end time.
echo END TIME: $(date +"%T") >> $LOGFILE

# Copy error from LOGFILE into ERRORFILE
grep -n -i error $LOGFILE > $ERRORFILE
