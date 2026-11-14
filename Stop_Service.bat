@echo off
setlocal EnableDelayedExpansion
title Stop Remote Screen Share Service

:: 1. Attempt Administrator elevation if possible (with graceful fallback)
net session >nul 2>&1
if %errorlevel% neq 0 (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "try { Start-Process cmd -ArgumentList '/c \"\"%~f0\"\"' -Verb RunAs -ErrorAction Stop; exit 0 } catch { exit 1 }" >nul 2>&1
    if !errorlevel! equ 0 exit /b
)

echo =======================================================
echo   Stopping Remote Screen Share Service and Background Tasks...
echo =======================================================
echo.

:: 2. Terminate by process image names
taskkill /F /IM SystemHostService.exe /T >nul 2>&1
taskkill /F /IM cloudflared.exe /T >nul 2>&1
taskkill /F /IM TunnelService.exe /T >nul 2>&1

:: 3. Terminate via PowerShell for any stubborn background handles
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-Process -Name 'SystemHostService', 'cloudflared', 'TunnelService' -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue" >nul 2>&1

:: 4. Terminate by stored PID if service.pid exists
if exist "%~dp0service.pid" (
    for /f "usebackq delims=" %%P in ("%~dp0service.pid") do (
        taskkill /F /PID %%P /T >nul 2>&1
        powershell -NoProfile -ExecutionPolicy Bypass -Command "Stop-Process -Id %%P -Force -ErrorAction SilentlyContinue" >nul 2>&1
    )
    del /f /q "%~dp0service.pid" >nul 2>&1
)

:: 5. Free port 8000 forcefully
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-NetTCPConnection -LocalPort 8000 -ErrorAction SilentlyContinue | ForEach-Object { Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue }" >nul 2>&1

:: 6. Clean up temporary state files
if exist "%~dp0service.pid" del /f /q "%~dp0service.pid" >nul 2>&1
if exist "%~dp0viewer_link.txt" (
    (
        echo =======================================================
        echo   Remote Screen Share ? SERVICE STOPPED
        echo =======================================================
        echo.
        echo Remote Screen Share is currently OFFLINE.
        echo To start the service again, run: start.bat
        echo.
        echo =======================================================
    ) > "%~dp0viewer_link.txt"
)

echo.
echo =======================================================
echo [SUCCESS] Remote Screen Share Service has been completely STOPPED.
echo All background processes (SystemHostService, cloudflared, TunnelService) terminated.
echo Port 8000 is now free.
echo =======================================================
echo.
ping -n 4 127.0.0.1 >nul 2>&1
