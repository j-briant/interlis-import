@echo off
echo ===================================== CREATING SCHEMA =====================================
call ./src/create_schema.bat
echo ===================================== IMPORT STARTING =====================================
call ./src/import_itf.bat
pause