@echo off
cd /d "%~dp0"
if exist "build\LaTribune\LaTribune.exe" (
    start "" "build\LaTribune\LaTribune.exe"
) else (
    start "" "tools\godot\Godot_v4.5-stable_win64.exe" --path "demo"
)
