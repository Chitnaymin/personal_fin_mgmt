@echo off
echo ===================================
echo   BUILDING AND VERSIONING PWA
echo ===================================

:: 1. Build the Flutter web app for release
echo.
echo [1/2] Building Flutter web app...
flutter build web

:: Check if the build was successful
if %errorlevel% neq 0 (
    echo.
    echo Flutter build failed. Aborting.
    exit /b %errorlevel%
)

echo Flutter build successful.

:: 2. Inject version number into the service worker
echo.
echo [2/2] Injecting version into service worker...

:: Define the path to the service worker file
set SERVICE_WORKER_PATH=build\web\flutter_service_worker.js

:: Get the version from pubspec.yaml (this is a bit tricky in batch)
for /f "tokens=2" %%i in ('findstr /r /c:"^version:" pubspec.yaml') do set APP_VERSION=%%i

:: Add the version as a comment at the top of the service worker file
(echo // Version: %APP_VERSION% - %date% %time%) > %SERVICE_WORKER_PATH%.tmp
(type %SERVICE_WORKER_PATH%) >> %SERVICE_WORKER_PATH%.tmp
move /y %SERVICE_WORKER_PATH%.tmp %SERVICE_WORKER_PATH% > nul

echo Service worker versioned successfully: %APP_VERSION%
echo.
echo ===================================
echo   Build complete. Ready to deploy.
echo ===================================