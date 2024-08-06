#!/usr/bin/bash

# CREATE THE DATABASE SCHEMA

usage="$(basename "$0") [-h] [-U USER] [-H HOST] [-p PORT] [-s SCHEMA] [-d DATABASE] [-w PASSWORD] [-E ENUMTAB] [-T TIDCOL] [-B BASKETCOL] [-n TIDNAME] [-i INTERLISFILE] [-m INTERLISMODEL]
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
    -m interlis model"

# Die function
die() {
  printf '%s\n' "$1" >&2
  exit 1
}

# Get parameters
while :; do
    case $1 in 
        -h|-\?|--help) 
			echo "$usage" 
			exit;;
        -U|--user)
            if [ "$2" ]; then
                user=$2
				shift
			else
				die 'ERROR: "--user" requires a non-empty option argument.'
            fi;;
        -H|--host)
            if [ "$2" ]; then
                host=$2
				shift
			else
				die 'ERROR: "--host" requires a non-empty option argument.'
            fi;;
        -p|--port)
            if [ "$2" ]; then
                port=$2
				shift
			else
				die 'ERROR: "--port" requires a non-empty option argument.'
            fi;;
        -s|--schema)
            if [ "$2" ]; then
                schema=$2
				shift
			else
				die 'ERROR: "--schema" requires a non-empty option argument.'
            fi;;
        -d|--database)
            if [ "$2" ]; then
                database=$2
				shift
			else
				die 'ERROR: "--database" requires a non-empty option argument.'
            fi;;
        -w|--password)
            if [ "$2" ]; then
                password=$2
				shift
			else
				die 'ERROR: "--password" requires a non-empty option argument.'
            fi;;
        -n|--tidname)
            if [ "$2" ]; then
                tidname=$2
				shift
			else
				die 'ERROR: "--tidname" requires a non-empty option argument.'
            fi;;
        -i|--interlis-model-file)
            if [ "$2" ]; then
                interlismodelfile=$2
				shift
			else
				die 'ERROR: "--interlis-model-file" requires a non-empty option argument.'
            fi;;
        -m|--interlis-model-name)
            if [ "$2" ]; then
                interlismodelname=$2
				shift
			else
				die 'ERROR: "--interlis-model-name" requires a non-empty option argument.'
            fi;;
        -E|--enumtab)
            enumtab="--createEnumTabs";;
        -T|--tidcol)
            tidcol="--createTidCol";;
        -B|--basketcol)
            basketcol="--createBasketCol";;
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

# Make parameters mandatory
if [ ! "${user}" ] || [ ! "${host}" ] || [ ! "${port}" ] || [ ! "${schema}" ] || [ ! "${database}" ] || [ ! "${password}" ] || [ ! "${tidname}" ] || [ ! "${interlismodelfile}" ] || [ ! "${interlismodelname}" ]; then
    echo "arguments -U, -h, -p, -s, -d, -w, -n, -i and -m must be provided"
    echo "$usage" >&2; exit 1
fi

# Run ili2db and create the schema.
java -jar "/opt/ili2pg-5.0.1/ili2pg-5.0.1.jar" --schemaimport --dbusr "$user" --dbhost "$host" --dbport "$port" --dbschema "$schema" --dbdatabase "$database" --dbpwd "$password" --sqlEnableNull --coalesceCatalogueRef --createEnumTabs --createNumChecks --createFk --createFkIdx --coalesceMultiSurface --coalesceMultiLine --coalesceMultiPoint --coalesceArray --beautifyEnumDispName --createGeomIdx --createMetaInfo --expandMultilingual --createTypeConstraint "$tidcol" --t_id_Name "$tidname" "$enumtab" "$basketcol" --importTid --smart2Inheritance --defaultSrsCode 2056 --models "$interlismodelname" "$interlismodelfile" 2>&1
