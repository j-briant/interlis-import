# interlis-import

Don't think too much about what interlis is, but if you have a .ili or .xtf in your hand then you might wonder what you're supposed to do with it.

## Objectives

Interlis is a, if not completely obscure, not so well documented format, and tools able to make something out of it are rare. Most of the time we'll just take the file and import it in a more convenient format. The library `ili2db` helps with those conversions but the number of parameter is sometimes overwhelming.

The aim here is to have a kind of minimalist and simple way of loading an interlis file (version 1 or 2) into a database (for now Postgres and Geopackage), without thinking too much about how to do it.

## Tools and requirements

You'll need a java runtime environment installed on your system (`sudo apt install default-jre` on Ubuntu). Everything is done thanks to [**`ili2db`**](https://github.com/claeis/ili2db) which is the only requirement (lib included though) with **`psql`** if you plan to backup stuff (see later).

## Configuration

The tool comes with a entry-point script: `interlis-import.sh`, that will call two subscripts: `create_schema.sh` and `import_interlis.sh`, both can be called independantly if you want.

You can print the help message:

```sh
$ ./interlis-import.sh -h
  interlis-import.sh [-h] [-b]
  Create the model structure into a schema and import data from interlis:
     -h show this help text
     -b backup database schema before anything (must run with backup privilege)
```

And a typical import will look like:

```sh
$ ./interlis-import.sh -b
```

Parameters can be stored in a `.env` file saved next to the script and will be overwritten if passed in the command line.

## Scripts

Subscripts can be launched separately if you want, here is a short description.

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
