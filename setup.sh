#!/usr/bin/bash

# Run this script to copy scripts, configs and libs to the correct places.

# Read conf file
. ./conf/paths.conf

# Copy files
mkdir -p $CONFPATH && cp -r .env communes.json model/ $CONFPATH
mkdir -p $ILI2PGPATH && cp -r ./lib/ili2pg-4.9.0 $ILI2PGPATH
mkdir -p $SCRIPTPATH && cp -r export_guichet_shapefiles.sh update_goeland_schema.sh import_canton_interlis.sh src/ $SCRIPTPATH

