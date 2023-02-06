:: TRANSFER DATA FROM AN ORACLE TABLE TO A POSTGRES TABLE
:: Parameters:
::	%1 postgres table
::	%2 database name
::	%3 database host
::	%4 database port
::	%5 database user
::	%6 database password
::	%7 database schema
::	%8 oracle view


@echo off

:: Set parameters
set %1
set %2
set %3
set %4
set %5
set %6
set %7
set %8

:: Run the ogr2ogr data transfer command
ogr2ogr -progress -append -preserve_fid -nln %MOVD_LAUSANNE_SCHEMA%.%POSTGRES_TABLE% -f PostgreSQL PG:"dbname=%MOVD_LAUSANNE_DB% host=%MOVD_LAUSANNE_HOST% port=%MOVD_LAUSANNE_PORT% user=%MOVD_LAUSANNE_USER% password=%MOVD_LAUSANNE_PASSWORD% schemas=%MOVD_LAUSANNE_SCHEMA% tables=%POSTGRES_TABLE%" OCI:MOVD_LSPROD/avs@GEOCADPROD12.lausanne.ch:%ORACLE_VIEW%
