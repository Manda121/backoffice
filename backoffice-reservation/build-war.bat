@echo off
echo ========================================
echo Compilation du framework
echo ========================================

cd ..\framework
call mvn clean install

echo.
echo ========================================
echo Compilation de backoffice-reservation
echo ========================================

cd ..\backoffice-reservation
call mvn clean package

echo.
echo ========================================
echo Build termine!
echo ========================================
echo.
echo Le fichier WAR se trouve dans: target\backoffice-reservation-sprint-7.war
echo.
echo Pour deployer sur Tomcat:
echo   1. Copiez target\backoffice-reservation-sprint-7.war dans le dossier webapps de Tomcat
echo   2. Demarrez Tomcat
echo   3. Acces: http://localhost:8080/backoffice-reservation-sprint-7/reservation/form
echo.
pause
