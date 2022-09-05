:: CREATE THE DATABASE SCHEMA
:: Parameters:
::	%1 database user
::	%2 database host
::	%3 database port
::	%4 database schema
::	%5 database name 
::	%6 database password
::	%7 --createEnumTabs, keep blank if no
::	%8 --createTidCol, keep blank if no
::	%9 --createBasketCol, keep blank if no
::	%10 t_id column name
::	%11 interlis model path  

@echo off

:: Set parameters
set %1
set	%2
set	%3
set	%4
set	%5
set	%6
set	%7
set	%8
set	%9
shift
set %9
shift
set %9

:: Run ili2db and create the schema.
C:\ProgramData\Oracle\Java\javapath\java.exe -jar C:\Users\SGCA0260\AppData\Roaming\QGIS\QGIS3\profiles\test\python\plugins\QgisModelBaker\libs\modelbaker\iliwrapper\bin\ili2pg-4.6.1\ili2pg-4.6.1.jar --schemaimport --dbusr %MOVD_USER% --dbhost %MOVD_HOST% --dbport %MOVD_PORT% --dbschema %MOVD_SCHEMA% --dbdatabase %MOVD_DB% --dbpwd %MOVD_PASSWORD% --sqlEnableNull --coalesceCatalogueRef --createEnumTabs --createNumChecks --createFk --createFkIdx --coalesceMultiSurface --coalesceMultiLine --coalesceMultiPoint --coalesceArray --beautifyEnumDispName --createGeomIdx --createMetaInfo --expandMultilingual --createTypeConstraint %CREATE_TID_COL% --t_id_Name %T_ID_NAME% %CREATE_ENUM_TAB% %CREATE_BASKET_COL% --importTid --smart2Inheritance --defaultSrsCode 2056 --models MD01MOVDMN95V24 %MOVD_MODEL%
endlocal
