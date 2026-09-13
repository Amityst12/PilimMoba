@echo off
cd /d "%~dp0"
echo Starting Pilim MOBA...

if exist "Godot_v4.7.2-stable_win64.exe" (
    start "" "Godot_v4.7.2-stable_win64.exe" --path .
    goto :done
)

for %%f in (godot*.exe Godot*.exe) do (
    start "" "%%f" --path .
    goto :done
)

where godot >nul 2>nul
if %ERRORLEVEL% equ 0 (
    start "" godot --path .
    goto :done
)

echo.
echo [ERROR] Godot 4 executable not found!
echo Please download Godot 4 from https://godotengine.org/download
echo and place the executable in this folder or add it to PATH.
echo.
pause

:done
