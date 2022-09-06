#!/usr/bin/bash

# Get environment variables.
. .env

#echo ===================================== DOWNLOADING FILES =====================================
#./src/linux/download_itf.sh -a "$AUTHORIZATION" -c $COMMUNES -l $DOWNLOAD_LINK -f $MOVD_FOLDER
#read -p "Waiting..."
echo ===================================== CREATING SCHEMA =====================================
./src/linux/create_schema.sh -U $MOVD_USER -p $MOVD_PORT -h $MOVD_HOST -s $MOVD_SCHEMA -d $MOVD_DB -w $MOVD_PASSWORD -n "ogr_id" -m $MOVD_MODEL -E -T -B
echo ===================================== IMPORT STARTING =====================================
./src/import_itf.sh
