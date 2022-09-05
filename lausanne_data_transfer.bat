@echo off

:: Get parent folder.
for %%i in ("%~dp0.") do set "folder=%%~fi"
echo %folder%

:: Get environment variables.
setlocal
for /F "tokens=*" %%i in ('type %folder%\.env') do set %%i


:: Load source views into a structured array (src).
setlocal EnableDelayedExpansion
set n=0
for %%a in (%ORA_SOURCE_VIEWS:"=%) do (
	set array[!n!].src=%%a
	set /A n+=1
)

:: Load destination tables into a structured array (dest).
set n=0
for %%a in (%PG_DESTINATION_TABLES:"=%) do (
	set array[!n!].dest=%%a
	set /A n+=1
)

:: Drop the schema to delete all data.
echo ===================================== DROPPING %MOVD_LAUSANNE_SCHEMA% SCHEMA =====================================
call ./src/drop_schema.bat "MOVD_USER=%MOVD_LAUSANNE_USER%" "MOVD_HOST=%MOVD_LAUSANNE_HOST%" "MOVD_PORT=%MOVD_LAUSANNE_PORT%" "MOVD_SCHEMA=%MOVD_LAUSANNE_SCHEMA%" "MOVD_DB=%MOVD_LAUSANNE_DB%"

:: Recreate the schema based on the custom interlis model.
echo ===================================== RECREATING %MOVD_LAUSANNE_SCHEMA% SCHEMA =====================================
call ./src/create_schema.bat "MOVD_USER=%MOVD_LAUSANNE_USER%" "MOVD_HOST=%MOVD_LAUSANNE_HOST%" "MOVD_PORT=%MOVD_LAUSANNE_PORT%" "MOVD_SCHEMA=%MOVD_LAUSANNE_SCHEMA%" "MOVD_DB=%MOVD_LAUSANNE_DB%" "MOVD_PASSWORD=%MOVD_LAUSANNE_PASSWORD%" "CREATE_TID_COL=" "T_ID_NAME=%T_ID_NAME%" "CREATE_ENUM_TAB=" "CREATE_BASKET_COL=" "MOVD_MODEL=%MOVD_LAUSANNE_MODEL%"

:: Transfer data from Oracle to Postgre using the ogr2ogr script.
echo ===================================== TRANSFERING DATA =====================================
set x=0
:SymLoop
	call ./src/oracle2postgres.bat "POSTGRES_TABLE=!array[%x%].dest!" "MOVD_LAUSANNE_DB=%MOVD_LAUSANNE_DB%" "MOVD_LAUSANNE_HOST=%MOVD_LAUSANNE_HOST%" "MOVD_LAUSANNE_PORT=%MOVD_LAUSANNE_PORT%" "MOVD_LAUSANNE_USER=%MOVD_LAUSANNE_USER%" "MOVD_LAUSANNE_PASSWORD=%MOVD_LAUSANNE_PASSWORD%" "MOVD_LAUSANNE_SCHEMA=%MOVD_LAUSANNE_SCHEMA%" "ORACLE_VIEW=!array[%x%].src!" >nul
    set /a "x+=1"
	
	if defined array[%x%].src (goto :SymLoop) else (echo ===================================== DATA TRANSFER DONE =====================================)

