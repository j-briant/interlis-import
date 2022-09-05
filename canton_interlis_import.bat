@echo off

:: Get parent folder.
for %%i in ("%~dp0.") do set "folder=%%~fi"
echo %folder%

:: Get environment variables.
setlocal
for /F "tokens=*" %%i in ('type %folder%\.env') do set %%i

echo ===================================== DOWNLOADING FILES =====================================
call ./src/download_itf.bat "FEDERAL_NUMBER=%FEDERAL_NUMBER%" "CANTONAL_NUMBER=%CANTONAL_NUMBER%" "AUTHORIZATION=%AUTHORIZATION%" "DOWNLOAD_LINK=%DOWNLOAD_LINK%" "MOVD_FOLDER=%MOVD_FOLDER%"
echo ===================================== CREATING SCHEMA =====================================
call ./src/create_schema.bat "MOVD_USER=%MOVD_USER%" "MOVD_SCHEMA=%MOVD_SCHEMA%" "MOVD_HOST=%MOVD_HOST%" "MOVD_HOST=%MOVD_HOST%" "MOVD_DB=%MOVD_DB%" "MOVD_PASSWORD=%MOVD_PASSWORD%" "MOVD_MODEL=%MOVD_MODEL%" >nul
echo ===================================== IMPORT STARTING =====================================
call ./src/import_itf.bat
pause