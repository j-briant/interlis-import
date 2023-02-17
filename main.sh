#!/usr/bin/bash

# This script is the main script for updating MO data and generating shapefiles for the guichet. Processes are:
#	1. Backuping the database
#	2. Downloading Interlis files from the ASIT-VD viageo URL
#	3. Creating the Postgres schema from the Interlis file model
#	4. Importing downloaded Interlis files into the newly created schema
#	5. Importing Goeland data from the goeland database
#	6. Count objects in tables and views


# Get configuration variables
. /etc/update_guichet/paths.conf

# Get environment variables.
. $CONFPATH/.env

COMMUNES=$CONFPATH/communes.json
MOVD_MODEL=$CONFPATH/model/6021.ili

# Get date.
RUNDATE=$(date +"%Y%m%d")

# Log folder variable
LOGNAME=$(basename "$0")
LOGFILE=$LOGPATH/$LOGNAME.log
ERRORFILE=$LOGPATH/$LOGNAME.error
RUNTIMEFILE=$LOGPATH/$LOGNAME.runtime

# Create folder if not exists
mkdir -p $LOGPATH

# Get start time.
echo START TIME: $(date +"%T") > $LOGFILE


# DOWNLOAD AND IMPORT INTERLIS FILES FROM AVRIC.

echo ===================================== BACKING UP DATABASE =====================================
su - postgres -c "pg_dump $MOVD_DB -Fc > /tmp/gc_transfert_backup.backup" >> $LOGFILE 2>&1

echo ===================================== DOWNLOADING FILES =====================================
$SCRIPTPATH/src/download_itf.sh -a "$AUTHORIZATION" -c $COMMUNES -l $DOWNLOAD_LINK -f $DOWNLOADPATH >> $LOGFILE 2>&1

echo ===================================== CREATING SCHEMA =====================================
$SCRIPTPATH/src/create_schema.sh -U $MOVD_USER -p $MOVD_PORT -H $MOVD_HOST -s $MOVD_SCHEMA -d $MOVD_DB -w $MOVD_PASSWORD -n $T_ID_NAME -m $MOVD_MODEL -E -T -B >> $LOGFILE 2>&1

echo ===================================== IMPORT STARTING =====================================
$SCRIPTPATH/src/import_itf.sh -U $MOVD_USER -p $MOVD_PORT -H $MOVD_HOST -s $MOVD_SCHEMA -d $MOVD_DB -w $MOVD_PASSWORD -n $T_ID_NAME -f $DOWNLOADPATH >> $LOGFILE 2>&1


# TRUNCATE GOELAND SCHEMA THEN DUMP/RESTORE FROM GOELAND DATABASE.

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
echo "$truncate_command" | su - postgres -c "psql $MOVD_DB" >> $LOGFILE 2>&1

echo ============================= BACKUP AND RESTORE FROM GOELAND =============================
# Backup and restore goeland data.
su - postgres -c "pg_dump goeland -a -n public -T spatial_ref_sys -T goeland_addresse_lausanne" | sed 's/public\./goeland\./g' | su - postgres -c "psql $MOVD_DB" >> $LOGFILE 2>&1


# EXPORT VIEWS AS SHAPEFILES.

echo ===================================== EXPORTING SHAPEFILES =====================================
$SCRIPTPATH/src/export_shp.sh -f $EXPORTPATH -d $MOVD_DB -s $MOVD_SCHEMA -x $PREFIX -c $EXPORT_COMMUNES >> $LOGFILE 2>&1


# Get end time.
echo END TIME: $(date +"%T") >> $LOGFILE

# Copy error from LOGFILE into ERRORFILE
grep -n -i error $LOGFILE > $ERRORFILE 
