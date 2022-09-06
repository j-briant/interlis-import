#!/usr/bin/bash

# CREATE THE DATABASE SCHEMA
# Parameters:
# -U database user
# -h database host
# -p database port
# -s database schema
# -d database name 
# -w database password
# -E --createEnumTabs, keep blank if no
# -T --createTidCol, keep blank if no
# -B --createBasketCol, keep blank if no
# -n t_id column name
# -m interlis model path  

# Set parameters
while getopts U:h:p:s:d:w:E:T:B:n:m: flag
do
        case "${flag}" in
                U) user=${OPTARG};;
                h) host=${OPTARG};;
                p) port=${OPTARG};;
                s) schema=${OPTARG};;
		d) database=${OPTARG};;
		w) password=${OPTARG};;
		n) tidname=${OPTARG};;
		m) interlismodel=${OPTARG};;
		E) enumtab="--createEnumTabs";;
		T) tidcol="--createTidCol";;
		B) basketcol="--createBasketCol";;
        esac
done

echo enumtab=$enumtab
echo user=$user
echo interlis_model=$interlismodel
echo tidname=$tidname

# Run ili2db and create the schema.
java -jar "./lib/ili2pg-4.9.0/ili2pg-4.9.0.jar" --schemaimport --dbusr $user --dbhost $host --dbport $port --dbschema $schema --dbdatabase $database --dbpwd $password --sqlEnableNull --coalesceCatalogueRef --createEnumTabs --createNumChecks --createFk --createFkIdx --coalesceMultiSurface --coalesceMultiLine --coalesceMultiPoint --coalesceArray --beautifyEnumDispName --createGeomIdx --createMetaInfo --expandMultilingual --createTypeConstraint $tidcol --t_id_Name $tidname $enumtab $basketcol --importTid --smart2Inheritance --defaultSrsCode 2056 --models MD01MOVDMN95V24 $interlismodel
