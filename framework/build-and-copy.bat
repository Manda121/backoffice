call mvn clean install
if errorlevel 1 exit /b 1

REM Copier le jar généré vers ../backoffice-reservation/WEB-INF/lib/
copy target\framework-sprint-1.jar ..\backoffice-reservation\WEB-INF\lib\
