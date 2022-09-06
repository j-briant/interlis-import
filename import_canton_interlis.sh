#!/usr/bin/bash

# Get date.
RUNDATE=$(date +"%Y%m%d")

# Log folder variable
LOGFOLDER=./log/$RUNDATE
LOGFILE=$LOGFOLDER/.log
ERRORFILE=$LOGFOLDER/.error
RUNTIMEFILE=$LOGFOLDER/.runtime

# Get start time.
echo START TIME: $(date +"%T") > $LOGFILE

# Get environment variables.
. .env


echo ===================================== DOWNLOADING FILES =====================================
./src/linux/download_itf.sh -a "$AUTHORIZATION" -c $COMMUNES -l $DOWNLOAD_LINK -f $MOVD_FOLDER >> $LOGFILE 2>&1 | tee $LOGFILE

echo ===================================== CREATING SCHEMA =====================================
./src/linux/create_schema.sh -U $MOVD_USER -p $MOVD_PORT -h $MOVD_HOST -s $MOVD_SCHEMA -d $MOVD_DB -w $MOVD_PASSWORD -n "ogr_id" -m $MOVD_MODEL -E -T -B >> $LOGFILE 2>&1 | tee $LOGFILE

echo ===================================== IMPORT STARTING =====================================
./src/linux/import_itf.sh -U $MOVD_USER -p $MOVD_PORT -h $MOVD_HOST -s $MOVD_SCHEMA -d $MOVD_DB -w $MOVD_PASSWORD -n "ogr_id" -f $MOVD_FOLDER >> $LOGFILE 2>&1 | tee $LOGFILE


# Get end time.
echo END TIME: $(date +"%T") >> $LOGFILE

# Copy error from LOGFILE into ERRORFILE
grep -n -i error $LOGFILE > $ERRORFILE 
