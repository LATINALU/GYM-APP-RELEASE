@echo off
REM Script de utilidad para comandos Flutter en Quantum Gym App
REM Usa la ruta configurada de Flutter

SET FLUTTER_BIN=C:\flutter\bin\flutter.bat

echo ========================================
echo   QUANTUM GYM APP - Flutter Commands
echo ========================================
echo.

if "%1"=="" goto menu
if "%1"=="get" goto get
if "%1"=="upgrade" goto upgrade
if "%1"=="clean" goto clean
if "%1"=="analyze" goto analyze
if "%1"=="build" goto build
if "%1"=="run" goto run
goto menu

:menu
echo Comandos disponibles:
echo.
echo   flutter-commands get       - Instalar dependencias
echo   flutter-commands upgrade   - Actualizar dependencias
echo   flutter-commands clean     - Limpiar cache
echo   flutter-commands analyze   - Analizar codigo
echo   flutter-commands build     - Compilar app
echo   flutter-commands run       - Ejecutar app
echo.
goto end

:get
echo Instalando dependencias...
%FLUTTER_BIN% pub get
goto end

:upgrade
echo Actualizando dependencias...
%FLUTTER_BIN% pub upgrade
goto end

:clean
echo Limpiando cache...
%FLUTTER_BIN% clean
goto end

:analyze
echo Analizando codigo...
%FLUTTER_BIN% analyze
goto end

:build
echo Compilando aplicacion...
%FLUTTER_BIN% build apk --debug
goto end

:run
echo Ejecutando aplicacion...
%FLUTTER_BIN% run
goto end

:end
echo.
echo Completado.
