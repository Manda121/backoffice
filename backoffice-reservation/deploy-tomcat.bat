@echo off
echo ========================================
echo Build et deploiement sur Tomcat
echo ========================================

set TOMCAT_WEBAPPS=D:\serveur\apache-tomcat-10.1.28\webapps
set WAR_NAME=backoffice-reservation-sprint-7.war

echo.
echo [1/2] Compilation du projet...
call mvn clean package
if errorlevel 1 goto end

echo.
echo [2/2] Copie du WAR vers Tomcat...
if not exist "%TOMCAT_WEBAPPS%" (
    echo Le dossier Tomcat n'existe pas: %TOMCAT_WEBAPPS%
    goto end
)

copy /Y "target\%WAR_NAME%" "%TOMCAT_WEBAPPS%\%WAR_NAME%"

echo.
echo Deploiement termine.
echo Acces: http://localhost:8080/%WAR_NAME%/

:end
echo.
pause
