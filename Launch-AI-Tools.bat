
@echo off
echo Starting AI Tools...
REM Launch Void
start "" "%USERPROFILE%\void\npm.cmd" start
REM Launch VS Code with Continue.dev
start "" "code" --new-window
REM Launch Cursor IDE
start "" "%LOCALAPPDATA%\Programs\Cursor\Cursor.exe"
echo Tools launched successfully!
pause
