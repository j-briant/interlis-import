#!/usr/bin/bash

# This script:
#	1. Downloads Interlis files from the ASIT-VD viageo URL
#	2. Create the Postgres schema from the Interlis file model
#	3. Import downloaded Interlis files into the newly created schema


# Get environment variables.
. /etc/update_guichet/.env
COMMUNES=$CONF_PATH/communes.json

# Get date.
RUNDATE=$(date +"%Y%m%d")

# Log folder variable
LOGNAME=$(basename "$0")
LOGFILE=$LOG_PATH/$LOGNAME.log
ERRORFILE=$LOG_PATH/$LOGNAME.error
RUNTIMEFILE=$LOG_PATH/$LOGNAME.runtime

# Create folder if not exists
mkdir -p $LOG_PATH

# Get start time.
echo START TIME: $(date +"%T") > $LOGFILE



echo ===================================== DOWNLOADING FILES =====================================
/usr/local/lib/update_guichet/src/download_itf.sh -a "$AUTHORIZATION" -c $COMMUNES -l $DOWNLOAD_LINK -f $DOWNLOAD_PATH >> $LOGFILE 2>&1

echo ===================================== CREATING SCHEMA =====================================
/usr/local/lib/update_guichet/src/create_schema.sh -U $MOVD_USER -p $MOVD_PORT -H $MOVD_HOST -s $MOVD_SCHEMA -d $MOVD_DB -w $MOVD_PASSWORD -n $T_ID_NAME -m $MOVD_MODEL -E -T -B >> $LOGFILE 2>&1

echo ===================================== IMPORT STARTING =====================================
/usr/local/lib/update_guichet/src/import_itf.sh -U $MOVD_USER -p $MOVD_PORT -H $MOVD_HOST -s $MOVD_SCHEMA -d $MOVD_DB -w $MOVD_PASSWORD -n $T_ID_NAME -f $DOWNLOAD_PATH >> $LOGFILE 2>&1


# Get end time.
echo END TIME: $(date +"%T") >> $LOGFILE

# Copy error from LOGFILE into ERRORFILE
grep -n -i error $LOGFILE > $ERRORFILE 
