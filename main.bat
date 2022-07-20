@echo off
echo ===================================== DOWNLOADING FILES =====================================
call ./src/download_itf.bat
echo ===================================== CREATING SCHEMA =====================================
call ./src/create_schema.bat
echo ===================================== IMPORT STARTING =====================================
call ./src/import_itf.bat
pause