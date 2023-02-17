#!/usr/bin/bash

# Run this script to copy scripts, configs and libs to the correct places.

# Read conf file
. ./conf/paths.conf

# Copy files
mkdir -p $CONFPATH && cp -r ./conf/paths.conf .env communes.json model/ $CONFPATH
mkdir -p $ILI2PGPATH && cp -r ./lib/ili2pg-4.9.0 $ILI2PGPATH
mkdir -p $SCRIPTPATH && cp -r main.sh src/ $SCRIPTPATH

