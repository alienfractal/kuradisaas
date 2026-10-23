@echo off
setlocal DisableDelayedExpansion
cd /d "%~dp0"

where python >nul 2>nul
if errorlevel 1 (
    echo ERROR: Python was not found on PATH.
    exit /b 1
)

rem No token argument needed: the helper prompts with hidden input after building.
rem Also accepts publish_itch.bat YOUR_ITCH_API_KEY, like the other games.
python "%~dp0publish_itch.py" %*
exit /b %errorlevel%
