# TRANSFER DATA FROM AN ORACLE TABLE TO A POSTGRES TABLE
usage="$(basename "$0") [-h] [-d PGDATABASE] [-H PGHOST] [-O OHOST] [-p PGPORT] [-U PGUSER] [-w PGPASSWORD] [-W OPASSWORD] [-s PGSCHEMA] [-S OSCHEMA] [-t TABLES]
Parameters:
	-h show this help text
	-d Postgres database name
	-H Postgres database host
	-p Postgres database port
	-U Postgres database user
	-w Postgres database password
	-s Postgres database schema
 	-O Oracle database host
	-W Oracle database password
	-S Oracle database schema
	-t Oracle/Postgresql table correspondance (json file)"

# Get parameters.
while getopts :hd:H:O:p:U:w:W:s:S:t: flag
do
        case "${flag}" in
		h) echo "$usage"; exit;;
		d) pgdatabase=${OPTARG};;
                H) pghost=${OPTARG};;
		O) ohost=${OPTARG};;
                p) pgport=${OPTARG};;
                U) pguser=${OPTARG};;
                w) pgpassword=${OPTARG};;
		W) opassword=${OPTARG};;
                s) pgschema=${OPTARG};;
		S) oschema=${OPTARG};;
                t) tables=${OPTARG};;
		:) printf "missing argument for -%s\n" "$OPTARG" >&2; echo "$usage" >&2; exit 1;;
               \?) printf "illegal option: -%s\n" "$OPTARG" >&2; echo "$usage" >&2; exit 1;;
        esac
done


# Make parameters mandatory
if [ ! ${pgdatabase} ] || [ ! ${pghost} ] || [ ! ${ohost} ] || [ ! ${pgport} ] || [ ! ${pguser} ] || [ ! ${pgpassword} ] || [ ! ${opassword} ] || [ ! ${pgschema} ] || [ ! ${oschema} ] || [ ! ${tables} ]; then
  echo "arguments -d, -H, -O, -p, -U, -w, -W, -s, -S and -t must be provided"
  echo "$usage" >&2; exit 1
fi


# Load table correspondance into a structured array.
declare -A tables_arr
while IFS="=" read -r key value
do
        tables_arr[$key]="$value"
done < <(jq -r 'to_entries|map("\(.key)=\(.value)")|.[]' $tables)

# Run the ogr2ogr data transfer command
for key in "${!tables_arr[@]}"; do
	ogr2ogr -progress -append -preserve_fid -nln $pgschema.${tables_arr[$key]} -f PostgreSQL PG:"dbname=$pgdatabase host=$pghost port=$pgport user=$pguser password=$pgpassword schemas=$pgschema" OCI:$oschema/$opassword@$ohost:$key 2>&1
