:: CREATE THE DATABASE SCHEMA
@echo off

:: Get parent folder.
for %%i in ("%~dp0..") do set "folder=%%~fi"
echo %folder%

:: Get environment variables.
setlocal
for /F "tokens=*" %%i in ('type %folder%\.env') do set %%i

:: Run ili2db and create the schema.
C:\ProgramData\Oracle\Java\javapath\java.exe -jar C:\Users\SGCA0260\AppData\Roaming\QGIS\QGIS3\profiles\test\python\plugins\QgisModelBaker\libs\modelbaker\iliwrapper\bin\ili2pg-4.6.1\ili2pg-4.6.1.jar --schemaimport --dbhost %MOVD_HOST% --dbport %MOVD_PORT% --dbusr %MOVD_USER% --dbpwd %MOVD_PASSWORD% --dbdatabase %MOVD_DB% --dbschema %MOVD_SCHEMA% --sqlEnableNull --coalesceCatalogueRef --createEnumTabs --createNumChecks --createFk --createFkIdx --coalesceMultiSurface --coalesceMultiLine --coalesceMultiPoint --coalesceArray --beautifyEnumDispName --createGeomIdx --createMetaInfo --expandMultilingual --createTypeConstraint --createEnumTabsWithId --createTidCol --importTid --smart2Inheritance --createBasketCol --defaultSrsCode 2056 --models MD01MOVDMN95V24 %folder%\%MOVD_MODEL%
endlocal
