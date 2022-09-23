# TRANSFER DATA FROM ORACLE TO POSTGRESQL

# Get date.
RUNDATE=$(date +"%Y%m%d")

# Log folder variable
LOGFOLDER=./log/$RUNDATE
LOGFILE=$LOGFOLDER/.log
ERRORFILE=$LOGFOLDER/.error
RUNTIMEFILE=$LOGFOLDER/.runtime

# Create log folder if not exists
mkdir -p $LOGFOLDER

# Get start time.
echo START TIME: $(date +"%T") > $LOGFILE

# Get environment variables.
. .env

# Drop the schema to delete all data.
echo =========================== DROPPING $MOVD_LAUSANNE_SCHEMA SCHEMA ===========================
./src/drop_schema.sh -S $MOVD_SERVICE -s $MOVD_LAUSANNE_SCHEMA >> $LOGFILE 2>&1


# Recreate the schema based on the custom interlis model.
echo =========================== RECREATING $MOVD_LAUSANNE_SCHEMA SCHEMA ==========================
./src/create_schema.sh -U $MOVD_LAUSANNE_USER -H $MOVD_LAUSANNE_HOST -p $MOVD_LAUSANNE_PORT -s $MOVD_LAUSANNE_SCHEMA -d $MOVD_LAUSANNE_DB -w $MOVD_LAUSANNE_PASSWORD -n $T_ID_NAME -m $MOVD_LAUSANNE_MODEL>> $LOGFILE 2>&1


# Transfer data from Oracle to Postgres using the ogr2ogr script.
echo =========================== TRANSFERING DATA =============================
#./src/oracle2postgres.sh -d $MOVD_LAUSANNE_DB -H $MOVD_LAUSANNE_HOST -p $MOVD_LAUSANNE_PORT -U $MOVD_LAUSANNE_USER -w $MOVD_LAUSANNE_PASSWORD -s $MOVD_LAUSANNE_SCHEMA -O $MOVD_ORACLE_HOST -W $MOVD_ORACLE_PASSWORD -S $MOVD_ORACLE_SCHEMA -t $ORA_PG_CORRESPONDANCE >> $LOGFILE 2>&1


# Get end time.
echo END TIME: $(date +"%T") >> $LOGFILE

# Copy error from LOGFILE into ERRORFILE
grep -n -i error $LOGFILE > $ERRORFILE

echo =========================== DATA TRANSFER DONE =============================

