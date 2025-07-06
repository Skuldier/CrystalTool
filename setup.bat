@echo off
REM Pokemon Crystal Tier Tool - Setup Launcher

cls
echo Starting Pokemon Crystal Tier Tool Setup...
echo.

REM Check for Python
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Python is not installed or not in PATH
    echo.
    echo This tool requires Python 3.6 or later.
    echo Please download and install Python from:
    echo https://www.python.org/downloads/
    echo.
    echo Make sure to check "Add Python to PATH" during installation!
    echo.
    pause
    exit /b 1
)

REM Run the setup menu
python SETUP.py

if %errorlevel% neq 0 (
    echo.
    echo Setup encountered an error.
    pause
)