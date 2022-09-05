:: DOWNLOAD ITF FILES
:: Parameters:
::	%1 federal numbers of required cities
::	%2 cantonal number of required cities
::	%3 authorization
::	%4 download link
::	%5 destination folder 
  
@echo off

:: Set parameters.
set %1
set %2
set %3
set %4
set %5

:: Load federal numbers into a structured array (federal).
setlocal EnableDelayedExpansion
set n=0
for %%a in (%FEDERAL_NUMBER:"=%) do (
	set array[!n!].federal=%%a
	set /A n+=1
)

:: Load cantonal numbers into a structured array (cantonal).
set n=0
for %%a in (%CANTONAL_NUMBER:"=%) do (
	set array[!n!].cantonal=%%a
	set /A n+=1
)
 
:: Loop through the structured array and download the interlis files.
set x=0
:SymLoop
if defined array[%x%].cantonal (
	curl -H "authorization: %AUTHORIZATION%" "%DOWNLOAD_LINK%/!array[%x%].federal!" --output %MOVD_FOLDER%\!array[%x%].cantonal!.itf
    set /a "x+=1"
	)
    if defined array[%x%].cantonal (GOTO :SymLoop) else (echo DOWNLOAD HAS FINISHED)