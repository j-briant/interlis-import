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

# Get date.
RUNDATE=$(date +"%Y%m%d")

# Log folder variable
LOGNAME=$(basename "$0")
LOGFILE=$LOGPATH/$LOGNAME.log
ERRORFILE=$LOGPATH/$LOGNAME.error

# Get start time.
echo START TIME: $(date +"%T") > $LOGFILE

# BACKUP
if [ "$backup" = true ]; then
        echo ===================================== BACKING UP DATABASE ===================================== >> $LOGFILE 2>&1
        pg_dump $DATABASE -n $SCHEMA -Fc > backup.dmp >> $LOGFILE 2>&1
fi

# IMPORT INTERLIS FILES.
echo ===================================== CREATE SCHEMAS ===================================== >> $LOGFILE 2>&1
echo Creating schema... >> $LOGFILE 2>&1
src/create_schema.sh -U $USER -p $PORT -H $HOST -s $SCHEMA -d $DATABASE -w $PASSWORD -n $T_ID_NAME -i $INTERLISMODELFILE -m $MODEL -E -T -B >> $LOGFILE 2>&1

echo ===================================== IMPORT DATA ===================================== >> $LOGFILE 2>&1
echo Importing data from Interlis files... >> $LOGFILE 2>&1
src/import_itf.sh -U $USER -p $PORT -H $HOST -s $SCHEMA -d $DATABASE -w $PASSWORD -n $T_ID_NAME -f $INTERLISDATAFILE >> $LOGFILE 2>&1

# Get end time.
echo END TIME: $(date +"%T") >> $LOGFILE

# Copy error from LOGFILE into ERRORFILE
grep -n -i error $LOGFILE > $ERRORFILE 

# Set exit status depending on $ERRORFILE
if [ -s $ERRORFILE ]; then
        # The file is not-empty
	exit 1
else
        # The file is empty
	exit 0
fi
