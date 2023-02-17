#!/usr/bin/bash

# This script:
#	1. Downloads Interlis files from the ASIT-VD viageo URL
#	2. Create the Postgres schema from the Interlis file model
#	3. Import downloaded Interlis files into the newly created schema


# Get configuration variables
. /etc/update_guichet/paths.conf

# Get environment variables.
. $CONFPATH/.env

COMMUNES=$CONFPATH/communes.json

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


echo ===================================== BACKUPING DATABASE =====================================
su - postgres -c "pg_dump gc_transfert -Fc > /tmp/gc_transfert_backup.backup" >> $LOGFILE 2>&1

echo ===================================== DOWNLOADING FILES =====================================
$SCRIPTPATH/src/download_itf.sh -a "$AUTHORIZATION" -c $COMMUNES -l $DOWNLOAD_LINK -f $DOWNLOAD_PATH >> $LOGFILE 2>&1

echo ===================================== CREATING SCHEMA =====================================
$SCRIPTPATH/src/create_schema.sh -U $MOVD_USER -p $MOVD_PORT -H $MOVD_HOST -s $MOVD_SCHEMA -d $MOVD_DB -w $MOVD_PASSWORD -n $T_ID_NAME -m $MOVD_MODEL -E -T -B >> $LOGFILE 2>&1

echo ===================================== IMPORT STARTING =====================================
$SCRIPTPATH/src/import_itf.sh -U $MOVD_USER -p $MOVD_PORT -H $MOVD_HOST -s $MOVD_SCHEMA -d $MOVD_DB -w $MOVD_PASSWORD -n $T_ID_NAME -f $DOWNLOAD_PATH >> $LOGFILE 2>&1


# Get end time.
echo END TIME: $(date +"%T") >> $LOGFILE

# Copy error from LOGFILE into ERRORFILE
grep -n -i error $LOGFILE > $ERRORFILE 
