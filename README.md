# interlis-import

For if you have a .ili or .xtf in your hand and you're wondering what you're supposed to do with it.

## Objectives

Interlis is a, if not completely obscure, not so well documented format, and tools able to make something out of it are rare. Most of the time we'll just take the file and import it in a more convenient format. The library `ili2db` helps with those conversions but the number of parameter is sometimes overwhelming.

The aim here is to have a kind of minimalist and simple way of loading an interlis file (version 1 or 2) into a database (for now Postgres and Geopackage), without thinking too much about how to do it.

## Tools and requirements

You'll need a java runtime environment installed on your system (`sudo apt install default-jre` on Ubuntu). Everything is done thanks to [**`ili2db`**](https://github.com/claeis/ili2db) which is the only requirement (lib included though) with **`psql`** if you plan to backup stuff (see later).

## How to run?

First clone the repo:

```sh
$ git clone https://github.com/j-briant/interlis-import.git
```

And try to run:

```sh
$ ./interlis-import.sh -h
```

The help message should show:

```sh
$ ./interlis-import.sh -h
  interlis-import.sh [-h] [-b] [-f FORMAT] [-d DATASET] [-U USER] [-H HOST] [-p PORT] [-w PASSWORD] [-s SCHEMA] [-l INTERLISMODELFILE] [-i INTERLISDATA] [-r SPATIALREFERENCE] [-t TIDNAME]
  Create the model structure into a dataset and import data from interlis:
    -h, --help                   show this help text
    -b, --backup                 backup dataset before anything (pg_dump or copy gpkg)
    -f, --format                 output format (gpkg or pg)
    -d, --dataset                destination dataset name (gpkg file name or pg table name)
    -U, --user                   user of the database (only for pg)
    -H, --host                   host of the postgres server (default localhost)
    -p, --port                   port of the postgres server (default 5432)
    -w, --password               password to connect to the postgres database
    -s, --schema                 schema where to build the model and import the data (default public)
    -t, --tidname                tid column name (default tid)
    -l, --interlis-model-file    interlis model file, usually a .ili file
    -i, --interlis-data-file     interlis data file, .xtf or .itf, or a folder containing those
    -r, --spatial-reference      spatial reference EPSG code (default 2056)
```

And a typical import will look like:

```sh
$ ./interlis-import.sh -b -f gpkg -d dst.gpkg -l model.ili -i data.xtf
```

## Configuration

The tool comes with a single script: `interlis-import.sh`. Be aware that the script is dependant on the location of the `ili2db` libraries, hardcoded in `lib`.

Parameters can be stored in a `.env` file saved next to the script. They will be overwritten if passed again in the command line. The parameters are the following:

```
FORMAT=pg
DATASET="my_table"
HOST="localhost"
USER="my_user"
PASSWORD="my_password"
PORT=5432
SCHEMA="my_schema"
INTERLISMODELFILE="./model/model.ili"
INTERLISDATA="./data/data.xtf"
TIDNAME=fid
SPATIALREFERENCE=2056
```

### Formats

Two formats are supported here: PostgreSQL and GeoPackage. Given by the `-f/--format` parameter, it influences the required parameters. Using the `pg` format, you'll then need to pass connection parameters (`-H`, `-U`, `-w`, `-s`, `-p`, some of them have a default) to your database. With GeoPackage (`gpkg`), those parameters will be ignored.

### Dataset

It's the name of a Postgres table or of a GeoPackage file (with extension).

### Interlis model file

This is the file describing the model of your data. It's usually a `.ili` file. If you don't have one and working with a `.xtf` file, you can try to pass it instead, as `ili2db` will try to find the model definition in well-known repos.

### Interlis data

A file or a directory of files, in `.itf` or `.xtf` format, containing data to be imported. If multiple files are imported, each of them will be imported into a separate `dataset`, allowing to identify their source after the import.

### Backup

You can backup your data if you're importing into an existing dataset. For Postgres, a dump file is created, for GeoPackage a copy of your already existing dataset.

### Tid name

The primary column name, this parameter might disappear in the future.

## Scripts

Two legacy subscripts can be launched separately if you want, here is a short description.

### create_schema.sh

This script will, as its name suggests, create a the structure of the model in your destination dataset. Interlis is strongly modelled and the first step is to create the model indicated by the interlis file.

Parameters are essentially connection information: `[-U USER]`, `[-H HOST]`, `[-p PORT]`, `[-s SCHEMA]`, `[-d DATABASE]`, `[-w PASSWORD]`. At the time of writing. `pg_service` files are not supported.

Remaining options parameterize the model creation:
* `-E`/`--createEnumTabs` --> Create a dedicated table for enums.
* `-T`/`--createTidCol` --> Create a `t_ili_tid` column in each table.
* `-B`/`--createBasketCol` --> Create a `t_basket` column in each table.
* `-n t_id` --> The name of the unique id column.
* `-m interlis_model_name` --> The name of the interlis model.
* `-i interlis_model_file` --> Path to the model definition (.ili)

The script can be called as below:

```sh
src/create_schema.sh -d my_db -h my_host -p 5432 -s my_schema -U username -w password -E -T -B -n "fid" -m "MODELNAME" -i "/path/to/my/model.ili"
```

### import_itf.sh

Once the model is build, you can import data. It will read a file (.itf or .xtf) or a folder (of .itf or .xtf) and import them in the destination database. If a folder containing multiple files is passed, each file is loaded into its own `dataset`.

As with `create_schema.sh`, most of parameters are connection information: `[-U USER]`, `[-H HOST]`, `[-p PORT]`, `[-s SCHEMA]`, `[-d DATABASE]`, `[-w PASSWORD]`.

Path to your input interlis data file or folder is given to `-i interlis data`. The parameter `-n tid_name` indicates the name of the _t_id_ used during the schema creation.

It could look like:

```sh
src/import_itf.sh -d my_db -h my_host -p 5432 -s my_schema -U username -w password -f "/tmp/my_directory/" -n "fid"
```
