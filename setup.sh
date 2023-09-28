#!/usr/bin/bash

# Run this script to copy scripts, configs and libs to the correct places.

# Read conf file
. ./conf/paths.conf

# Copy files
mkdir -p $CONFPATH && cp -r ./conf/paths.conf .env mo_communes.json npcs_communes.json model/ $CONFPATH
mkdir -p $ILI2PGPATH && cp -r ./lib/ili2pg-5.0.1 $ILI2PGPATH
mkdir -p $SCRIPTPATH && cp -r main.sh src/ $SCRIPTPATH

