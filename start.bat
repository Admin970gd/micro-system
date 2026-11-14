@echo off
setlocal EnableDelayedExpansion
title Start Remote Screen Share Service

:: 1. Attempt Administrator elevation if possible (with graceful fallback)
net session >nul 2>&1
if %errorlevel% neq 0 (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "try { Start-Process cmd -ArgumentList '/c \"\"%~f0\"\"' -Verb RunAs -ErrorAction Stop; exit 0 } catch { exit 1 }" >nul 2>&1
    if !errorlevel! equ 0 exit /b
)

echo =======================================================
echo   Starting Remote Screen Share Service...
echo =======================================================
echo.

:: Clean up old state before launch
if exist "%~dp0viewer_link.txt" del /f /q "%~dp0viewer_link.txt" >nul 2>&1

:: Launch the main service executable in background
start "" "%~dp0SystemHostService.exe"

echo Launching service and generating secure Cloudflare viewer link...
echo Please wait a few moments...
echo.

set /a count=0
:WAIT_LOOP
ping -n 2 127.0.0.1 >nul 2>&1
set /a count+=1

if exist "%~dp0viewer_link.txt" (
    findstr /C:".trycloudflare.com" "%~dp0viewer_link.txt" | findstr /V /C:"api.trycloudflare.com" >nul 2>&1
    if !errorlevel! equ 0 goto DISPLAY_LINK
)

if !count! lss 25 goto WAIT_LOOP

:DISPLAY_LINK
cls
echo =======================================================
echo   Remote Screen Share ? ACTIVE and SECURED
echo =======================================================
echo.
if exist "%~dp0viewer_link.txt" (
    type "%~dp0viewer_link.txt"
    start notepad.exe "%~dp0viewer_link.txt"
) else (
    echo [OK] Service is running in background.
    echo Port: 8000 (Local link: http://127.0.0.1:8000)
)
echo.
echo =======================================================
echo [SUCCESS] Remote Screen Share is now RUNNING.
echo * Share the Remote Viewer Link and License Key with your viewer.
echo * You can close this launcher window anytime.
echo * To STOP the service completely, double-click: stop.bat
echo =======================================================
pause
