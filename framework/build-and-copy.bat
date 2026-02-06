call mvn clean install
if errorlevel 1 exit /b 1

REM Copier le jar généré vers ../backoffice/WEB-INF/lib/
copy target\framework-sprint-1.jar ..\backoffice\WEB-INF\lib\
