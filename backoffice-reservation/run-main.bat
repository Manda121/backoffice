@echo off
echo ========================================
echo    Generateur de Token d'API
echo ========================================
echo.

set SRC=src\main\java\util\Main.java
set OUT=target\classes
set PG_JAR=%USERPROFILE%\.m2\repository\org\postgresql\postgresql\42.7.1\postgresql-42.7.1.jar

echo [1/2] Compilation de Main.java...
javac -d "%OUT%" -cp "%PG_JAR%" "%SRC%"
if errorlevel 1 (
    echo ERREUR: La compilation a echoue !
    goto end
)
echo       OK

echo [2/2] Execution du generateur de token...
echo.
java -cp "%OUT%;%PG_JAR%" util.Main

:end
echo.
pause
