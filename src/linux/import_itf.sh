# LOOP THROUGH ITF FILES AND LOAD INTO DATABASE.

# Parameters:
#       -f source folder (containing interlis files)
#       -h database host
#       -p database port
#       -U database user
#	-w database password
#	-d database name
#	-s database schema
#	-n name of the tid column


# Get parameters.
while getopts f:h:p:U:w:d:s:n: flag
do
        case "${flag}" in
                f) sfolder=${OPTARG};;
                h) host=${OPTARG};;
                p) port=${OPTARG};;
                U) user=${OPTARG};;
		w) password=${OPTARG};;
		d) database=${OPTARG};;
		s) schema=${OPTARG};;
		n) tidname=${OPTARG};;
        esac
done

# Run ili2db.
for f in $sfolder/*.itf; 
do
	echo ========================= $f =========================
	datasetname=$(basename $f .itf)
	java -jar "./lib/ili2pg-4.9.0/ili2pg-4.9.0.jar" --replace --dbhost $host --dbport $port --dbusr $user --dbpwd $password --dbdatabase $database --dbschema $schema --t_id_Name $tidname --importTid --importBid --disableValidation --dataset $datasetname $f 2>&1
done
