:: DROP THE DATABASE SCHEMA
:: Parameters:
::	%1 database user
::	%2 database host
::	%3 database port
::	%4 database schema
::	%5 database name

@echo off

:: Set parameters
set %1
set %2
set %3
set %4
set %5

:: Run the DROP query
psql -U %MOVD_USER% -h %MOVD_HOST% -p %MOVD_PORT% -c "DROP SCHEMA %MOVD_SCHEMA% CASCADE;" -d %MOVD_DB% -w