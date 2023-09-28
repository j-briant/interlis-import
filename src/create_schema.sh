#!/usr/bin/bash

# CREATE THE DATABASE SCHEMA

usage="$(basename "$0") [-h] [-U USER] [-H HOST] [-p PORT] [-s SCHEMA] [-d DATABASE] [-w PASSWORD] [-E ENUMTAB] [-T TIDCOL] [-B BASKETCOL] [-n TIDNAME] [-m INTERLISMODEL]
Create a Postgres schema based on an interlis model (.ili):
	-h show this help text
	-U database user
	-H database host
	-p database port
	-s database schema
	-d database name 
	-w database password
	-E --createEnumTabs, keep blank if no
	-T --createTidCol, keep blank if no
	-B --createBasketCol, keep blank if no
	-n t_id column name
	-m interlis model path"

# Set parameters
while getopts :hU:H:p:s:d:w:n:m:ETB flag
do
        case "${flag}" in
		h) echo "$usage"; exit;;
		U) user=${OPTARG};;
                H) host=${OPTARG};;
                p) port=${OPTARG};;
                s) schema=${OPTARG};;
		d) database=${OPTARG};;
		w) password=${OPTARG};;
		n) tidname=${OPTARG};;
		m) interlismodel=${OPTARG};;
		E) enumtab="--createEnumTabs";;
		T) tidcol="--createTidCol";;
		B) basketcol="--createBasketCol";;
		:) printf "missing argument for -%s\n" "$OPTARG" >&2; echo "$usage" >&2; exit 1;;
               \?) printf "illegal option: -%s\n" "$OPTARG" >&2; echo "$usage" >&2; exit 1;;
        esac
done


# Make parameters mandatory
if [ ! ${user} ] || [ ! ${host} ] || [ ! ${port} ] || [ ! ${schema} ] || [ ! ${database} ] || [ ! ${password} ] || [ ! ${tidname} ] || [ ! ${interlismodel} ]; then
  echo "arguments -U, -h, -p, -s, -d, -w, -n and -m must be provided"
  echo "$usage" >&2; exit 1
fi


# Run ili2db and create the schema.
java -jar "/opt/ili2pg-5.0.1/ili2pg-5.0.1.jar" --schemaimport --dbusr $user --dbhost $host --dbport $port --dbschema $schema --dbdatabase $database --dbpwd $password --sqlEnableNull --coalesceCatalogueRef --createEnumTabs --createNumChecks --createFk --createFkIdx --coalesceMultiSurface --coalesceMultiLine --coalesceMultiPoint --coalesceArray --beautifyEnumDispName --createGeomIdx --createMetaInfo --expandMultilingual --createTypeConstraint $tidcol --t_id_Name $tidname $enumtab $basketcol --importTid --smart2Inheritance --defaultSrsCode 2056 --models MD01MOVDMN95V24 $interlismodel 2>&1
