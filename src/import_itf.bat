:: LOOP THROUGH ITF FILES AND LOAD INTO DATABASE.
@echo off

:: Get date.
set DATE=%date:~-10,2%-%date:~-7,2%-%date:~-4,4%

:: Get parent folder
for %%i in ("%~dp0..") do set "folder=%%~fi"

:: Create log directory if not exists.
set LOG_DIRECTORY=%folder%\log\%DATE%
if not exist %LOG_DIRECTORY% mkdir %LOG_DIRECTORY%

:: Create error folder if not exists
set ERROR_DIRECTORY=%folder%\log\errors\%DATE%
if not exist %ERROR_DIRECTORY% mkdir %ERROR_DIRECTORY%

:: Create running_time folder if not exists
set DURATION_DIRECTORY=%folder%\log\running_time
if not exist %DURATION_DIRECTORY% mkdir %DURATION_DIRECTORY%

:: Get starting time.
set START_TIME=%time%

:: Get environment variables from .env file.
setlocal
for /F "tokens=*" %%i in ('type %folder%\.env') do set %%i

:: Run ili2db.
for %%f in (%folder%\%MOVD_FOLDER%\*.itf) do (
	echo ========================= %%f %%~nf =========================
	C:\ProgramData\Oracle\Java\javapath\java.exe -jar C:\Users\SGCA0260\AppData\Roaming\QGIS\QGIS3\profiles\test\python\plugins\QgisModelBaker\libs\modelbaker\iliwrapper\bin\ili2pg-4.6.1\ili2pg-4.6.1.jar --replace --dbhost %MOVD_HOST% --dbport %MOVD_PORT% --dbusr %MOVD_USER% --dbpwd %MOVD_PASSWORD% --dbdatabase %MOVD_DB% --dbschema %MOVD_SCHEMA% --importTid --importBid --disableValidation --log %LOG_DIRECTORY%\%%~nf_%time:~0,2%%time:~3,2%%time:~6,2%_%DATE%.log --dataset %%~nf %%f 
	)
endlocal

:: Get end time.
set END_TIME=%time%

:: Log running_time.
(echo Date: %DATE% && echo Start time: %START_TIME% && echo End time: %END_TIME% && echo.) >> %DURATION_DIRECTORY%\running_time.log

:: Find errors and log them.
findstr /sI Error %LOG_DIRECTORY%\*_%DATE%.log > %ERROR_DIRECTORY%\%DATE%.log
