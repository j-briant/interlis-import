#!/usr/bin/bash

# Get date.
RUNDATE=$(date +"%Y%m%d")

# Log folder variable
LOGFOLDER=./log/$RUNDATE
LOGFILE=$LOGFOLDER/.log
ERRORFILE=$LOGFOLDER/.error
RUNTIMEFILE=$LOGFOLDER/.runtime

# Create folder if not exists
mkdir -p $LOGFOLDER

# Get start time.
echo START TIME: $(date +"%T") > $LOGFILE

# Get environment variables.
. .env


echo ===================================== DOWNLOADING FILES =====================================
./src/download_itf.sh -a "$AUTHORIZATION" -c $COMMUNES -l $DOWNLOAD_LINK -f $MOVD_FOLDER >> $LOGFILE 2>&1

echo ===================================== CREATING SCHEMA =====================================
./src/create_schema.sh -U $MOVD_USER -p $MOVD_PORT -H $MOVD_HOST -s $MOVD_SCHEMA -d $MOVD_DB -w $MOVD_PASSWORD -n $T_ID_NAME -m $MOVD_MODEL -E -T -B >> $LOGFILE 2>&1

echo ===================================== IMPORT STARTING =====================================
./src/import_itf.sh -U $MOVD_USER -p $MOVD_PORT -H $MOVD_HOST -s $MOVD_SCHEMA -d $MOVD_DB -w $MOVD_PASSWORD -n $T_ID_NAME -f $MOVD_FOLDER >> $LOGFILE 2>&1


# Get end time.
echo END TIME: $(date +"%T") >> $LOGFILE

# Copy error from LOGFILE into ERRORFILE
grep -n -i error $LOGFILE > $ERRORFILE 
