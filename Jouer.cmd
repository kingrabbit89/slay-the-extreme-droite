@echo off
cd /d "%~dp0"
if exist "build\SlayTheExtremeDroite\SlayTheExtremeDroite.exe" (
    start "" "build\SlayTheExtremeDroite\SlayTheExtremeDroite.exe"
) else (
    start "" "tools\godot\Godot_v4.5-stable_win64.exe" --path "demo"
)
