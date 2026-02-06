@echo off
setlocal

:: Nom du projet et chemins
set WAR_NAME=framework-test.war
set SRC_DIR=%~dp0
set TMP_DIR=%SRC_DIR%war-tmp
set TOMCAT_WEBAPPS=D:\logiciel\apache-tomcat-10.1.46\apache-tomcat-10.1.46\webapps

call mvn clean compile

echo Nettoyage du dossier temporaire...
if exist "%TMP_DIR%" rmdir /s /q "%TMP_DIR%"

echo Création du dossier temporaire...
mkdir "%TMP_DIR%"

echo Copie des fichiers nécessaires...
xcopy "%SRC_DIR%WEB-INF" "%TMP_DIR%\WEB-INF" /E /I /Y
xcopy "%SRC_DIR%target\classes" "%TMP_DIR%\WEB-INF\classes" /E /I /Y
xcopy "%SRC_DIR%src\main\webapp\templates" "%TMP_DIR%\templates" /E /I /Y

echo Suppression ancien WAR...
if exist "%SRC_DIR%%WAR_NAME%" del "%SRC_DIR%%WAR_NAME%"

echo Création du WAR...
cd /d "%TMP_DIR%"
jar -cvf "%SRC_DIR%%WAR_NAME%" *

echo Copie vers Tomcat webapps...
copy /Y "%SRC_DIR%%WAR_NAME%" "%TOMCAT_WEBAPPS%"

:: Revenir dans le dossier source avant suppression
cd /d "%SRC_DIR%"

echo Nettoyage du dossier temporaire...
rmdir /s /q "%TMP_DIR%"

echo Deployé : %WAR_NAME% -> %TOMCAT_WEBAPPS%
endlocal
