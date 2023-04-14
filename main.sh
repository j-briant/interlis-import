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
su - postgres -c "pg_dump $DATABASE -n $MOVD_SCHEMA -n $NPCS_SCHEMA -Fc > /data/mensuration_officielle.backup" >> $LOGFILE 2>&1


echo ===================================== DOWNLOADS =====================================
echo Downloading MO files...
$SCRIPTPATH/src/download_itf.sh -a "$AUTHORIZATION" -c $MO_COMMUNES -l $MOVD_DOWNLOAD_LINK -f $MOVD_DOWNLOADPATH >> $LOGFILE 2>&1

echo Downloading NPCS files...
$SCRIPTPATH/src/download_itf.sh -a "$AUTHORIZATION" -c $NPCS_COMMUNES -l $NPCSVD_DOWNLOAD_LINK -f $NPCSVD_DOWNLOADPATH >> $LOGFILE 2>&1


echo ===================================== CREATE SCHEMAS =====================================
echo Creating MO schema...
$SCRIPTPATH/src/create_schema.sh -U $USER -p $PORT -H $HOST -s $MOVD_SCHEMA -d $DATABASE -w $PASSWORD -n $T_ID_NAME -m $MOVD_MODEL -E -T -B >> $LOGFILE 2>&1

echo Creating NPCS schema...
$SCRIPTPATH/src/create_schema.sh -U $USER -p $PORT -H $HOST -s $NPCSVD_SCHEMA -d $DATABASE -w $PASSWORD -n $T_ID_NAME -m $MOVD_MODEL -E -T -B >> $LOGFILE 2>&1


echo ===================================== IMPORT DATA =====================================
echo Importing MO data from Interlis files...
$SCRIPTPATH/src/import_itf.sh -U $USER -p $PORT -H $HOST -s $MOVD_SCHEMA -d $DATABASE -w $PASSWORD -n $T_ID_NAME -f $MOVD_DOWNLOADPATH >> $LOGFILE 2>&1

echo Importing NPCS data from Interlis files...
$SCRIPTPATH/src/import_itf.sh -U $USER -p $PORT -H $HOST -s $NPCSVD_SCHEMA -d $DATABASE -w $PASSWORD -n $T_ID_NAME -f $NPCSVD_DOWNLOADPATH >> $LOGFILE 2>&1


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

echo ============================= UPDATING GOELAND DATA =============================
echo Truncating the Goeland schema...
echo "$truncate_command" | su - postgres -c "psql $DATABASE" >> $LOGFILE 2>&1

echo Backuping and restoring from Goeland replication...
su - postgres -c "pg_dump goeland -a -n public -T spatial_ref_sys -T goeland_addresse_lausanne" | sed 's/public\./goeland\./g' | su - postgres -c "psql $DATABASE" >> $LOGFILE 2>&1


# EXPORT VIEWS AS SHAPEFILES.
echo ===================================== EXPORTING SHAPEFILES =====================================
$SCRIPTPATH/src/export_shp.sh -f $EXPORTPATH -d $DATABASE -s $MOVD_SCHEMA -x $PREFIX -c $EXPORT_COMMUNES >> $LOGFILE 2>&1


# COUNT OBJECTS FOR CONTROL
echo ===================================== COUNTING TABLES AND VIEWS OBJECTS =====================================
echo Counting MO objects...
su - postgres -c "psql -d gc_transfert -c \"select db_monitoring.count_table_object('$MOVD_SCHEMA'); select db_monitoring.count_table_object('specificite_lausanne');\"" >> $LOGFILE 2>&1
echo Counting NPCS objects...
su - postgres -c "psql -d gc_transfert -c \"select db_monitoring.count_table_object('$NPCSVD_SCHEMA');\"" >> $LOGFILE 2>&1

echo Counting views objects...
su - postgres -c "psql -d gc_transfert -c \"select db_monitoring.count_gc_view_object('$MOVD_SCHEMA');\"" >> $LOGFILE 2>&1


# CREATE ATTACHMENTS AND SEND EMAIL NOTIFICATION
echo ===================================== SENDING EMAIL NOTIFICATION =====================================
echo -e "MOVD TABLES COUNTS\n" > /tmp/gc_counts.txt
su - postgres -c "psql gc_transfert -c \"select * from db_monitoring.table_last_update_difference;\"" >> /tmp/gc_counts.txt
echo -e "\n\nPAR COMMUNE COUNTS\n" >> /tmp/gc_counts.txt
su - postgres -c "psql gc_transfert -c \"select datasetname, sum(difference) as diff_sum from db_monitoring.view_last_update_difference group by datasetname order by datasetname;\"" >> /tmp/gc_counts.txt
echo -e "\n\nPAR COUCHE COUNTS\n" >> /tmp/gc_counts.txt
su - postgres -c "psql gc_transfert -c \"select schemaname, viewname, sum(difference) as diff_sum from db_monitoring.view_last_update_difference group by schemaname, viewname order by viewname;\"" >> /tmp/gc_counts.txt

echo -e "Bonjour,\n\nVous trouverez en pièce jointe les décomptes de la mise à jour du $(date +"%Y-%m-%d").\n\nBonne semaine,\n\nUn serveur" | mail -s "Mise a jour du $(date +"%Y-%m-%d")" julien.briant@lausanne.ch -a "From: go-db@update-guichet" -A /tmp/gc_counts.txt


# Get end time.
echo END TIME: $(date +"%T") >> $LOGFILE

# Copy error from LOGFILE into ERRORFILE
grep -n -i error $LOGFILE > $ERRORFILE 

