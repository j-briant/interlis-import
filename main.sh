#!/usr/bin/bash

# This script is the main script for updating MO data and generating shapefiles for the guichet. Processes are:
#	1. Backuping the database
#	2. Downloading Interlis files from the ASIT-VD viageo URL
#	3. Creating the Postgres schema from the Interlis file model
#	4. Importing downloaded Interlis files into the newly created schema
#	5. Importing Goeland data from the goeland database
#	6. Count objects in tables and views
#	7. Send email notification


# Get configuration variables
. /etc/update_guichet/paths.conf

# Get environment variables.
. $CONFPATH/.env

MO_COMMUNES=$CONFPATH/mo_communes.json
NPCS_COMMUNES=$CONFPATH/npcs_communes.json
MOVD_MODEL=$CONFPATH/model/6021.ili
TMPEXPORT=/tmp/guichet/

# Get date.
RUNDATE=$(date +"%Y%m%d")

# Log folder variable
LOGNAME=$(basename "$0")
LOGFILE=$LOGPATH/$LOGNAME.log
ERRORFILE=$LOGPATH/$LOGNAME.error
RUNTIMEFILE=$LOGPATH/$LOGNAME.runtime

# Create folder if not exists
mkdir -p $LOGPATH
mkdir -p $TMPEXPORT
# Change owner to postgres so they can write
chown postgres $TMPEXPORT

# Get start time.
echo START TIME: $(date +"%T") > $LOGFILE


# DOWNLOAD AND IMPORT INTERLIS FILES FROM AVRIC.
echo ===================================== BACKING UP DATABASE ===================================== >> $LOGFILE 2>&1
su - postgres -c "pg_dump $DATABASE -n $MOVD_SCHEMA -n $NPCSVD_SCHEMA -Fc > /data/backups/mensuration_officielle.backup" >> $LOGFILE 2>&1


echo ===================================== DOWNLOADS ===================================== >> $LOGFILE 2>&1
echo Downloading MO files... >> $LOGFILE 2>&1
$SCRIPTPATH/src/download_itf.sh -a "$AUTHORIZATION" -c $MO_COMMUNES -l $MOVD_DOWNLOAD_LINK -f $MOVD_DOWNLOADPATH >> $LOGFILE 2>&1

echo Downloading NPCS files... >> $LOGFILE 2>&1
$SCRIPTPATH/src/download_itf.sh -a "$AUTHORIZATION" -c $NPCS_COMMUNES -l $NPCSVD_DOWNLOAD_LINK -f $NPCSVD_DOWNLOADPATH >> $LOGFILE 2>&1


echo ===================================== CREATE SCHEMAS ===================================== >> $LOGFILE 2>&1
echo Creating MO schema... >> $LOGFILE 2>&1
$SCRIPTPATH/src/create_schema.sh -U $USER -p $PORT -H $HOST -s $MOVD_SCHEMA -d $DATABASE -w $PASSWORD -n $T_ID_NAME -m $MOVD_MODEL -E -T -B >> $LOGFILE 2>&1

echo Creating NPCS schema... >> $LOGFILE 2>&1
$SCRIPTPATH/src/create_schema.sh -U $USER -p $PORT -H $HOST -s $NPCSVD_SCHEMA -d $DATABASE -w $PASSWORD -n $T_ID_NAME -m $MOVD_MODEL -E -T -B >> $LOGFILE 2>&1


echo ===================================== IMPORT DATA ===================================== >> $LOGFILE 2>&1
echo Importing MO data from Interlis files... >> $LOGFILE 2>&1
$SCRIPTPATH/src/import_itf.sh -U $USER -p $PORT -H $HOST -s $MOVD_SCHEMA -d $DATABASE -w $PASSWORD -n $T_ID_NAME -f $MOVD_DOWNLOADPATH >> $LOGFILE 2>&1

echo Importing NPCS data from Interlis files... >> $LOGFILE 2>&1
$SCRIPTPATH/src/import_itf.sh -U $USER -p $PORT -H $HOST -s $NPCSVD_SCHEMA -d $DATABASE -w $PASSWORD -n $T_ID_NAME -f $NPCSVD_DOWNLOADPATH >> $LOGFILE 2>&1


# COUNT OBJECTS FOR CONTROL
echo ===================================== COUNTING TABLES OBJECTS ===================================== >> $LOGFILE 2>&1
echo Counting MO objects... >> $LOGFILE 2>&1
su - postgres -c "psql -d $DATABASE -c \"select db_monitoring.count_table_object('$MOVD_SCHEMA');\"" >> $LOGFILE 2>&1
echo Counting NPCS objects... >> $LOGFILE 2>&1
su - postgres -c "psql -d $DATABASE -c \"select db_monitoring.count_table_object('$NPCSVD_SCHEMA');\"" >> $LOGFILE 2>&1
echo Counting Lausanne data objects... >> $LOGFILE 2>&1
su - postgres -c "psql -d $DATABASE -c \"select db_monitoring.count_table_object('specificite_lausanne');\"" >> $LOGFILE 2>&1
echo Counting diffusion objects... >> $LOGFILE 2>&1
su - postgres -c "psql -d diffusion -c \"select db_monitoring.count_table_object('mo_guichet');\"" >> $LOGFILE 2>&1

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
