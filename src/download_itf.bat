:: DOWNLOAD ITF FILES
@echo off

:: Get parent folder.
for %%i in ("%~dp0..") do set "folder=%%~fi"
echo %folder%

:: Get environment variables.
for /F "tokens=*" %%i in ('type %folder%\.env') do set %%i

:: Load federal numbers into a structured array (federal)
setlocal EnableDelayedExpansion
set n=0
for %%a in (%FEDERAL_NUMBER%) do (
	set array[!n!].federal=%%a
	set /A n+=1
)

:: Load cantonal numbers into a structured array (cantonal)
set n=0
for %%a in (%CANTONAL_NUMBER%) do (
	set array[!n!].cantonal=%%a
	set /A n+=1
)

:: Loop through the structured array and download the interlis files.
set "x=0"
:SymLoop
if defined array[%x%].cantonal (
    echo !array[%x%].federal! : !array[%x%].cantonal!
	curl -H "authorization: %AUTHORIZATION%" "%DOWNLOAD_LINK%/!array[%x%].federal!" --output %folder%/%MOVD_FOLDER%/!array[%x%].cantonal!.itf
    set /a "x+=1"
	)
    GOTO :SymLoop