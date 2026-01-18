
@echo off
echo ============================================
echo Launching AI Development Toolkit...
echo ============================================

REM Launch Void Editor
echo Starting Void Editor...
start "" "%USERPROFILE%\void\npm.cmd" start

REM Launch VS Code with multiple projects
echo Opening VS Code with projects...
start "" "code" "%USERPROFILE%\Projects\Project1"
start "" "code" "%USERPROFILE%\Projects\Project2"

REM Launch Cursor IDE
echo Starting Cursor IDE...
start "" "%LOCALAPPDATA%\Programs\Cursor\Cursor.exe"

REM Run CLI commands in separate terminals
echo Running CLI commands...
start cmd /k "opencode \"Explain async in Python\""
start cmd /k "sgpt \"Generate a Python class for API client\""
start cmd /k "chatgpt \"Summarize this code snippet\""
start cmd /k "gpt \"Create a Dockerfile for Node.js app\""

echo ============================================
echo All tools launched successfully!
pause
