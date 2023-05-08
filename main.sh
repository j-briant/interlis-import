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


# DELETE GOELAND SCHEMA THEN DUMP/RESTORE FROM GOELAND DATABASE.
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

echo ============================= UPDATING GOELAND DATA ============================= >> $LOGFILE 2>&1
echo Deleting the Goeland schema... >> $LOGFILE 2>&1
su - postgres -c "psql -d $DATABASE -c 'DROP SCHEMA goeland CASCADE;'" >> $LOGFILE 2>&1
echo Recreating it... >> $LOGFILE 2>&1
su - postgres -c "psql -d $DATABASE -c 'CREATE SCHEMA goeland;'" >> $LOGFILE 2>&1
#echo "$truncate_command" | su - postgres -c "psql $DATABASE" >> $LOGFILE 2>&1

echo Backing up and restoring from Goeland replication... >> $LOGFILE 2>&1
su - postgres -c "pg_dump goeland -xO -n public -T spatial_ref_sys -T goeland_addresse_lausanne" | sed 's/public\./goeland\./g' | su - postgres -c "psql $DATABASE" >> $LOGFILE 2>&1


# TRANSFER DATA
echo =========================== TRANSFERING DATA ================================= >> $LOGFILE 2>&1
echo Moving formatted data to diffusion database... >> $LOGFILE 2>&1
/root/bin/ogr_transfer/ogr_transfer.sh -c /etc/ogr_transfer/mo_guichet-conf.json >> $LOGFILE 2>&1

# EXPORT AS SHAPEFILES.
echo Exporting data as shapefile... >> $LOGFILE 2>&1
/root/bin/ogr_transfer/ogr_transfer.sh -c /etc/ogr_transfer/export_mo_guichet-conf.json >> $LOGFILE 2>&1

#echo ===================================== EXPORTING SHAPEFILES =====================================
#$SCRIPTPATH/src/export_shp.sh -f $EXPORTPATH -d $DATABASE -s $MOVD_SCHEMA -x $PREFIX -c $EXPORT_COMMUNES >> $LOGFILE 2>&1

echo Copying data to destination folder... >> $LOGFILE 2>&1
cp -r $TMPEXPORT $EXPORTPATH
 

# COUNT OBJECTS FOR CONTROL
echo ===================================== COUNTING TABLES OBJECTS ===================================== >> $LOGFILE 2>&1
echo Counting MO objects... >> $LOGFILE 2>&1
su - postgres -c "psql -d gc_transfert -c \"select db_monitoring.count_table_object('$MOVD_SCHEMA'); select db_monitoring.count_table_object('specificite_lausanne');\"" >> $LOGFILE 2>&1
echo Counting NPCS objects... >> $LOGFILE 2>&1
su - postgres -c "psql -d gc_transfert -c \"select db_monitoring.count_table_object('$NPCSVD_SCHEMA');\"" >> $LOGFILE 2>&1
echo Counting diffusion objects... >> $LOGFILE 2>&1
su - postgres -c "psql -d diffusion -c \"select db_monitoring.count_table_object('mo_guichet');\"" >> $LOGFILE 2>&1


# CREATE ATTACHMENTS AND SEND EMAIL NOTIFICATION
echo ===================================== SENDING EMAIL NOTIFICATION ===================================== >> $LOGFILE 2>&1
echo -e "MOVD TABLES COUNTS\n" > /tmp/gc_counts.txt
su - postgres -c "psql gc_transfert -c \"select * from db_monitoring.table_last_update_difference;\"" >> /tmp/gc_counts.txt
echo -e "\n\nDIFFUSION TABLES COUNTS\n" >> /tmp/gc_counts.txt
su - postgres -c "psql diffusion -c \"select * from db_monitoring.table_last_update_difference;\"" >> /tmp/gc_counts.txt

echo -e "Bonjour,\n\nVous trouverez en pièce jointe les décomptes de la mise à jour du $(date +"%Y-%m-%d").\n\nBonne semaine,\n\nUn serveur" | mail -s "Mise a jour du $(date +"%Y-%m-%d")" julien.briant@lausanne.ch -a "From: go-db@update-guichet" -A /tmp/gc_counts.txt


# Get end time.
echo END TIME: $(date +"%T") >> $LOGFILE

# Copy error from LOGFILE into ERRORFILE
grep -n -i error $LOGFILE > $ERRORFILE 

