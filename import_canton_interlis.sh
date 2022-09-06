#!/usr/bin/bash

# Get environment variables.
. .env

echo $MOVD_FOLDER
echo $COMMUNES
echo $DOWNLOAD_LINK
echo $AUTHORIZATION

read -p "Waiting..."

echo ===================================== DOWNLOADING FILES =====================================
./src/linux/download_itf.sh -a "$AUTHORIZATION" -c $COMMUNES -l $DOWNLOAD_LINK -f $MOVD_FOLDER
read -p "Waiting..."
echo ===================================== CREATING SCHEMA =====================================
./src/create_schema.sh "MOVD_USER=$MOVD_USER" "MOVD_SCHEMA=$MOVD_SCHEMA" "MOVD_HOST=$MOVD_HOST" "MOVD_HOST=$MOVD_HOST" "MOVD_DB=$MOVD_DB" "MOVD_PASSWORD=$MOVD_PASSWORD" "MOVD_MODEL=$MOVD_MODEL" >/dev/null
echo ===================================== IMPORT STARTING =====================================
./src/import_itf.sh
pause
