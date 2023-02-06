#!/usr/bin/bash

# This script exports data views from the database, identified with a prefix, to shapefiles into the desired folder. 

# Get environment variables.
. /etc/update_guichet/.env

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


echo ===================================== EXPORTING SHAPEFILES =====================================
/usr/local/lib/update_guichet/src/export_shp.sh -f $EXPORT_FOLDER -d $MOVD_DB -s $MOVD_SCHEMA -x $PREFIX -c $EXPORT_COMMUNES >> $LOGFILE 2>&1


# Get end time.
echo END TIME: $(date +"%T") >> $LOGFILE

# Copy error from LOGFILE into ERRORFILE
grep -n -i error $LOGFILE > $ERRORFILE 
