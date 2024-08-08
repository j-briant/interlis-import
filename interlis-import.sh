#!/usr/bin/bash

# This script is the main script for updating data from interlis. Processes are:
#	1. Backing-up the database if desired
#	2. Creating the dataset from the Interlis file model
#	3. Importing downloaded Interlis files into the newly created dataset

# Functions
die() {
    printf '%s\n' "$1" >&2
    exit 1
}


# Get environment variables.
if [ -f ".env" ]; then
    . .env
fi

# Constants
PGJAR="lib/ili2pg-5.1.0/ili2pg-5.1.0.jar"
GPKGJAR="lib/ili2gpkg-5.1.0/ili2gpkg-5.1.0.jar"
CREATEOPTIONS=( --schemaimport --sqlEnableNull --coalesceCatalogueRef --createEnumTabs --createNumChecks --createFk --createFkIdx --coalesceMultiSurface --coalesceMultiLine --coalesceMultiPoint --coalesceArray --beautifyEnumDispName --createGeomIdx --createMetaInfo --expandMultilingual --createTypeConstraint --createTidCol --createEnumTabs --createBasketCol --importTid --smart2Inheritance )
IMPORTOPTIONS=( --replace --importTid --importBid )

# Command
usage="$(basename "$0") [-h] [-b] [-f FORMAT] [-d DATASET] [-U USER] [-H HOST] [-p PORT] [-w PASSWORD] [-s SCHEMA] [-l INTERLISMODELFILE] [-i INTERLISDATA] [-r SPATIALREFERENCE] [-t TIDNAME] 
Create the model structure into a dataset and import data from interlis:
    -h, --help                   show this help text
    -b, --backup                 backup database schema before anything (must run with backup privilege)
    -f, --format                 output format (gpkg or pg)
    -d, --dataset                destination dataset name (gpkg file name or pg table name)
    -U, --user                   user of the database (only for pg)
    -H, --host                   host of the postgres server (default localhost)
    -p, --port                   port of the postgres server (default 5432)
    -w, --password               password to connect to the postgres database
    -s, --schema                 schema where to build the model and import the data (default public)
    -t, --tidname                tid column name (default tid)
    -v, --validate               validate data during import
    -l, --interlis-model-file    interlis model file, usually a .ili file
    -i, --interlis-data-file     interlis data file, .xtf or .itf
    -r, --spatial-reference      spatial reference EPSG code (default 2056)"


# Get command parameters, overwriting .env values if present.
while :; do
    case $1 in
        -h|-\?|--help)
            echo "$usage"
            exit;;
        -b|--backup)
            BACKUP=true;;
        -f|--format)
            if [ "$2" ]; then
                case "$2" in 
                    pg|gpkg)
                        FORMAT=$2
                        shift
                        ;;
                    *)
                        die 'ERROR: "--format" must be either "pg" or "gpkg".';;
                esac
            else
                die 'ERROR: "--format" requires a non-empty option argument. Must be either "pg" or "gpkg".'
            fi;;
        -U|--user)
            if [ "$2" ]; then
                USER=$2
                shift
            else
                die 'ERROR: "--user" requires a non-empty option argument.'
            fi;;
        -d|--dataset)
            if [ "$2" ]; then
                DATASET=$2
                shift
            else
                die 'ERROR: "--database" requires a non-empty option argument.'
            fi;;
        -H|--host)
            if [ "$2" ]; then
                HOST=$2
                shift
            else
                die 'ERROR: "--host" requires a non-empty option argument.'
            fi;;
        -p|--port)
            if [ "$2" ]; then
                PORT=$2
                shift
            else
                die 'ERROR: "--port" requires a non-empty option argument.'
            fi;;
        -w|--password)
            if [ "$2" ]; then
                PASSWORD=$2
                shift
            else
                die 'ERROR: "--password" requires a non-empty option argument.'
            fi;;
        -s|--schema)
            if [ "$2" ]; then
                SCHEMA=$2
                shift
            else
                die 'ERROR: "--schema" requires a non-empty option argument.'
            fi;;
        -l|--interlis-model-file)
            if [ "$2" ]; then
                INTERLISMODELFILE=$2
                shift
            else
                die 'ERROR: "--interlis-model-file" requires a non-empty option argument.'
            fi;;
        -i|--interlis-data)
            if [ "$2" ]; then
                INTERLISDATA=$2
                shift
            else
                die 'ERROR: "--interlis-data" requires a non-empty option argument.'
            fi;;
        -r|--spatial-reference)
            if [ "$2" ]; then
                SPATIALREFERENCE=$2
                shift
            else
                die 'ERROR: "--spatial-reference" requires a non-empty option argument.'
            fi;;
        -t|--tidname)
            if [ "$2" ]; then
                TIDNAME=$2
                shift
            else
                die 'ERROR: "--tidname" requires a non-empty option argument.'
            fi;;
        -v|--validate)
            ;;
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

# Make sure mandatory parameters are passed, either from the .env or the command line
if [ ! "${FORMAT}" ]; then
    echo "argument -f/--format must be provided ('gpkg' or 'pg')"
    echo "$usage" >&2; exit 1
elif [ "$FORMAT" = "pg" ]; then
    if [ ! "${USER}" ] || [ ! "${DATASET}" ] || [ ! "${PASSWORD}" ] || [ ! "${INTERLISMODELFILE}" ]; then
        echo "arguments -U, -d, -w and -l must be provided"
        echo "$usage" >&2; exit 1
    fi
elif [ "$FORMAT" = "gpkg" ]; then
    if [ ! "${DATASET}" ] || [ ! "${INTERLISMODELFILE}" ]; then
        echo "arguments -d and -l must be provided"
        echo "$usage" >&2; exit 1
    fi
fi


# Get start time.
echo "START TIME: $(date +"%T")"


# BACKUP
if [ "$BACKUP" = true ]; then
    echo "===================================== BACKING UP DATASET ====================================="
    if [ "$FORMAT" = 'pg' ]; then
        PGPASSWORD="$PASSWORD" pg_dump "$DATASET" -n "${SCHEMA:-public}" -Fc > backup_"$(date +"%Y%m%d%H%M%S")".dmp
    elif [ "$FORMAT" = gpkg ]; then
        cp "$DATASET" backup_"$DATASET" >/dev/null
    fi
fi


# CREATE SCHEMA
echo "===================================== CREATE SCHEMAS ====================================="
echo "Creating schema..."
if [ "$FORMAT" = 'pg' ]; then
    #src/create_schema.sh -U "$USER" -p "$PORT" -H "$HOST" -s "$SCHEMA" -d "$DATASET" -w "$PASSWORD" -t "$TIDNAME" -l "$INTERLISMODELFILE" -m "$MODEL" -E -T -B
    java -jar "$PGJAR" \
        "${CREATEOPTIONS[@]}" \
        --dbusr "$USER" \
        --dbhost "${HOST:-localhost}" \
        --dbport "${PORT:-5432}" \
        --dbschema "${SCHEMA:-public}" \
        --dbdatabase "$DATASET" \
        --dbpwd "$PASSWORD" \
        --t_id_Name "${TIDNAME:-tid}" \
        --defaultSrsCode "${SPATIALREFERENCE:-2056}" \
        "$INTERLISMODELFILE"
elif [ "$FORMAT" = 'gpkg' ]; then
    java -jar "$GPKGJAR" \
        "${CREATEOPTIONS[@]}" \
        --dbfile "$DATASET" \
        --t_id_Name "${TIDNAME:-tid}" \
        --defaultSrsCode "${SPATIALREFERENCE:-2056}" \
        "$INTERLISMODELFILE"
fi

# IMPORT
echo "===================================== IMPORT DATA ====================================="
echo "Importing data from Interlis files..."
if [ "$FORMAT" = 'pg' ]; then
    #src/import_itf.sh -U "$USER" -p "$PORT" -H "$HOST" -s "$SCHEMA" -d "$DATASET" -w "$PASSWORD" -t "$TIDNAME" -i "$INTERLISDATA"
    if [[ -d "$INTERLISDATA" ]]; then
        for f in "$INTERLISDATA"/*.itf;
        do
            echo "========================= $f ========================="
            datasetname="${f%.*}"
            java -jar "$PGJAR" \
                "${IMPORTOPTIONS[@]}" \
                --dbhost "${HOST:-localhost}" \
                --dbport "${PORT:-5432}" \
                --dbusr "$USER" \
                --dbpwd "$PASSWORD" \
                --dbdatabase "$DATASET" \
                --dbschema "${SCHEMA:-public}" \
                --t_id_Name "${TIDNAME:-tid}" \
                "${VALIDATE---disableValidation}" \
                --dataset "$datasetname" \
                "$f"
        done
    elif [[ -f "$INTERLISDATA" ]]; then
        datasetname="${INTERLISDATA%.*}"
        java -jar "$PGJAR" \
            "${IMPORTOPTIONS[@]}" \
            --dbhost "${HOST:-localhost}" \
            --dbport "${PORT:-5432}" \
            --dbusr "$USER" \
            --dbpwd "$PASSWORD" \
            --dbdatabase "$DATASET" \
            --dbschema "${SCHEMA:-public}" \
            --t_id_Name "${TIDNAME:-tid}" \
            "${VALIDATE---disableValidation}" \
            --dataset "$datasetname" \
            "$INTERLISDATA"
    fi
elif [ "$FORMAT" = 'gpkg' ]; then
    if [[ -d "$INTERLISDATA" ]]; then
        for f in "$INTERLISDATA"/*.itf;
        do
            echo "========================= $f ========================="
            datasetname="${f%.*}"
            java -jar "$GPKGJAR" \
                "${IMPORTOPTIONS[@]}" \
                --dbfile "$DATASET" \
                --t_id_Name "${TIDNAME:-tid}" \
                "${VALIDATE---disableValidation}" \
                --dataset "$datasetname" \
                "$f"
        done
    elif [[ -f "$INTERLISDATA" ]]; then
        datasetname="${INTERLISDATA%.*}"
        java -jar "$GPKGJAR" \
            "${IMPORTOPTIONS[@]}" \
            --dbfile "$DATASET" \
            --t_id_Name "${TIDNAME:-tid}" \
            "${VALIDATE---disableValidation}" \
            --dataset "$datasetname" \
            "$INTERLISDATA"
    fi
fi

# Get end time.
echo "END TIME: $(date +"%T")"

