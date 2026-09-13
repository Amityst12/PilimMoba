@echo off
cd /d "%~dp0"
echo Opening Project in Godot Editor...
start "" "Godot_v4.7.2-stable_win64.exe" -e --path .
