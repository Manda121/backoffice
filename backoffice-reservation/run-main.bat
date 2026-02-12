@echo off
echo ========================================
echo    Generateur de Token d'API
echo ========================================

echo.
echo [1/3] Compilation du projet...
call mvn compile -q
if errorlevel 1 (
    echo ERREUR: La compilation a echoue !
    goto end
)
echo       OK

echo [2/3] Copie des dependances...
call mvn dependency:copy-dependencies -DoutputDirectory=target/libs -q 2>nul
if errorlevel 1 (
    echo ERREUR: Impossible de copier les dependances !
    goto end
)
echo       OK

echo [3/3] Execution du generateur de token...
echo.
java -cp "target/classes;target/libs/*" util.Main

:end
echo.
pause
