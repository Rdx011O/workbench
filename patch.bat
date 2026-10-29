@echo off
setlocal
echo ===================================================
echo     Workbench - Automated Over-The-Air Patch
echo ===================================================
echo.
cd /d "%~dp0"

echo [1/3] Checking Git Status...
git status --short

set /p COMMIT_MSG="Enter commit description (Press Enter for default): "
if "%COMMIT_MSG%"=="" set COMMIT_MSG=Update Workbench UI and logic

echo.
echo [2/3] Committing and pushing to GitHub...
git add .
git commit -m "%COMMIT_MSG%"
git push origin main

echo.
echo [3/3] Deploying instant patch via Shorebird...
shorebird patch android

echo.
echo ===================================================
echo   Done! Patch has been published to Shorebird.
echo   All installed devices will receive it automatically.
echo ===================================================
pause
