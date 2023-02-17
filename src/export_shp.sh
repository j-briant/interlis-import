#!/usr/bin/bash

# EXPORT VIEWS TO SHAPEFILE

usage="$(basename "$0") [-h] [-d DBNAME] [-s SCHEMANAME] [-x PREFIX] [-c COMMUNES] [-f DFOLDER]
Export data views of a given list of cities to shapefile:
	-h show this help text
	-d database name
	-s schema name
	-x prefix identifying views or tables to export
	-c cities numbers list
	-f destination folder"

die() {
  printf '%s\n' "$1" >&2
  exit 1
}

# Get parameters.
while :; do
	case $1 in
		-h|-\?|--help) 
			echo "$usage" 
			exit;;
		-d|--dbname) 
			if [ "$2" ]; then 
				dbname=$2 
				shift 
			else 
				die 'ERROR: "--dbname" requires a non-empty option argument.'
			fi;;
		-s|--sname) 
			if [ "$2" ]; then 
				sname=$2 
				shift
                        else 
				die 'ERROR: "--sname" requires a non-empty option argument.'
                        fi;;
		-x|--prefix)
			if [ "$2" ]; then 
				prefix=$2 
				shift
                        else 
				die 'ERROR: "--prefix" requires a non-empty option argument.'
                        fi;;
		-c|--communes) 
			if [ "$2" ]; then 
				communes=$2 
				shift
			else 
				die 'ERROR: "--communes" requires a non-empty option argument.'
                        fi;;
		-f|--folder) 
			if [ "$2" ]; then 
				dfolder=$2 
				shift
                        else 
				die 'ERROR: "--folder" requires a non-empty option argument.'
                        fi;;
		--)
			shift
			break
			;;
		-?*)
			printf 'WARN: Unknown option (ignored): %s\n' "$1" >&2
			;;
		*)
			break
	esac
	shift
done

# Make parameter mandatory
if [ ! ${dbname} ] | [ ! ${sname} ] | [ ! ${prefix} ] | [ ! ${dfolder} ]; then
  echo "argument -d, -s, x and -f must be provided"
  echo "$usage" >&2; exit 1
fi

# If communes is not empty reassign for full export
if [ ! ${communes} ]; 
then
  communes_condition=""
else
  communes_condition="WHERE numcom IN ($communes)"
fi

# Create output folders if not exist
mkdir -p $dfolder
su postgres -c "mkdir -p /tmp/export_shape/"

# Get views list
view_list=$(su postgres -c "psql -d $dbname -t -c \"select table_name from information_schema.views where table_schema = '$sname' and table_name like '$prefix%';\"") 2>&1

# Loop through views and export locally
for item in $view_list
do
  echo "Exporting $item..."
  su postgres -c "pgsql2shp -f /tmp/export_shape/$item $dbname \"select * from $sname.$item $communes_condition\"" 2>&1
done

# Copy to destination
echo "Copying to destination folder..."
cp -r /tmp/export_shape $dfolder 2>&1

