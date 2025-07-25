@echo off
title Gemini CLI with Context7 Memory
echo.
echo 🔄 Starting context7 memory server...
start "Context7-MCP" cmd /k "npx -y @upstash/context7-mcp"

:: Wait a few seconds for context7 to initialize
timeout /t 3 /nobreak >nul

echo ✅ Launching Gemini CLI...
start "Gemini-CLI" cmd /k "gemini"

echo All set! Both memory server and Gemini CLI are running.
exit
