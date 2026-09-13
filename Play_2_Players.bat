@echo off
cd /d "%~dp0"
echo ========================================================
echo Launching 2 Instances for Local Multiplayer MOBA Test
echo Instance 1: Host (Port 7777)
echo Instance 2: Client (Auto-connects to 127.0.0.1)
echo ========================================================

set "GODOT_CMD="
if exist "Godot_v4.7.2-stable_win64.exe" set "GODOT_CMD=Godot_v4.7.2-stable_win64.exe"
if "%GODOT_CMD%"=="" (
    for %%f in (godot*.exe Godot*.exe) do (
        set "GODOT_CMD=%%f"
        goto :found
    )
)
:found
if "%GODOT_CMD%"=="" (
    where godot >nul 2>nul
    if %ERRORLEVEL% equ 0 set "GODOT_CMD=godot"
)

if "%GODOT_CMD%"=="" (
    echo [ERROR] Godot 4 executable not found!
    pause
    exit /b 1
)

start "" "%GODOT_CMD%" --path . -- ++ --host --name=HostPlayer
timeout /t 2 /nobreak >nul
start "" "%GODOT_CMD%" --path . -- ++ --join=127.0.0.1 --name=ClientPlayer
