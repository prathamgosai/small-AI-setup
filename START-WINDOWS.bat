@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Portable Qwen
rem ------------------------------------------------------------------
rem  Windows: double-click this file to start Portable Qwen.
rem  Optional (from a Command Prompt):
rem     START-WINDOWS.bat chat    chat inside this window instead of the browser
rem     START-WINDOWS.bat cpu     don't use the graphics card
rem     START-WINDOWS.bat fast    turn off "thinking" (quicker, a bit less smart)
rem  Settings: set QWEN_CTX=16384 (context size), set QWEN_PORT=8080
rem ------------------------------------------------------------------
cd /d "%~dp0"

set "MODE=web"
set "FORCE_CPU=0"
set "NO_THINK=0"
for %%a in (%*) do (
  if /i "%%a"=="chat" set "MODE=chat"
  if /i "%%a"=="cli"  set "MODE=chat"
  if /i "%%a"=="cpu"  set "FORCE_CPU=1"
  if /i "%%a"=="fast" set "NO_THINK=1"
)
if not defined QWEN_CTX set "QWEN_CTX=16384"
if not defined QWEN_PORT set "QWEN_PORT=8080"

rem ---- engine for this CPU type ----
set "ARCH=%PROCESSOR_ARCHITECTURE%"
if defined PROCESSOR_ARCHITEW6432 set "ARCH=%PROCESSOR_ARCHITEW6432%"
set "BIN=%~dp0engine\windows-x64"
if /i "%ARCH%"=="ARM64" set "BIN=%~dp0engine\windows-arm64"
if not exist "%BIN%\llama-server.exe" (
  echo ERROR: engine not found in "%BIN%"
  goto :fail
)

rem ---- model (first .gguf in models, not the mmproj vision file) ----
set "MODEL="
for %%f in ("%~dp0models\*.gguf") do (
  set "NAME=%%~nxf"
  if /i not "!NAME:~0,6!"=="mmproj" if not defined MODEL set "MODEL=%%~ff"
)
if not defined MODEL (
  echo ERROR: no model .gguf file found in "%~dp0models"
  goto :fail
)
set "MMPROJ="
for %%f in ("%~dp0models\mmproj*.gguf") do if not defined MMPROJ set "MMPROJ=%%~ff"

rem ---- optional system prompt (the AI's role). Delete/rename the file for a plain assistant ----
set "SYSPROMPT="
if exist "%~dp0prompts\system-prompt.txt" set "SYSPROMPT=%~dp0prompts\system-prompt.txt"

set "EXTRA="
if "%FORCE_CPU%"=="1" set "EXTRA=-ngl 0"
if "%NO_THINK%"=="1" set "EXTRA=%EXTRA% --reasoning off"

echo.
echo ==============================================================
echo  Portable Qwen
for %%m in ("%MODEL%") do echo  Model : %%~nxm
if defined MMPROJ echo  Vision: enabled
if defined SYSPROMPT echo  Role  : prompts\system-prompt.txt
set /p VER=<"%~dp0engine\VERSION.txt"
echo  Engine: llama.cpp %VER% ^(%ARCH%^)
echo ==============================================================
echo  Loading the model from USB can take 1-4 minutes.
echo  Keep this window open. Close it to stop the AI.
echo ==============================================================
echo.

if "%MODE%"=="chat" (
  if defined SYSPROMPT (
    "%BIN%\llama-cli.exe" -m "%MODEL%" -c %QWEN_CTX% --jinja -sysf "%SYSPROMPT%" %EXTRA%
  ) else (
    "%BIN%\llama-cli.exe" -m "%MODEL%" -c %QWEN_CTX% --jinja %EXTRA%
  )
  goto :end
)

set "URL=http://127.0.0.1:%QWEN_PORT%"

rem ---- already running (or still loading)? then just open the chat ----
powershell -NoProfile -Command "try { if((Invoke-WebRequest -UseBasicParsing -TimeoutSec 3 '%URL%/health').StatusCode -eq 200){ exit 0 } } catch { if($_.Exception.Response -and [int]$_.Exception.Response.StatusCode -eq 503){ exit 2 } }; exit 1"
set "STATE=%errorlevel%"
if "%STATE%"=="0" (
  echo The AI is already running. Opening the chat: %URL%
  start "" "%URL%"
  "%SystemRoot%System32	imeout.exe" /t 4 >nul
  exit /b 0
)
if "%STATE%"=="2" (
  echo The AI is already starting in another window. The chat opens when it is ready.
  start "" /b powershell -NoProfile -WindowStyle Hidden -Command "for($i=0;$i -lt 600;$i++){ Start-Sleep 1; try { if((Invoke-WebRequest -UseBasicParsing -TimeoutSec 2 '%URL%/health').StatusCode -eq 200){ Start-Process '%URL%'; break } } catch {} }"
  "%SystemRoot%System32	imeout.exe" /t 4 >nul
  exit /b 0
)

rem ---- keep the same port: chat history is saved per address (port) ----
for /f %%p in ('powershell -NoProfile -Command "$p=%QWEN_PORT%; while($p -lt %QWEN_PORT%+20){ try{ $l=[Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback,$p); $l.Start(); $l.Stop(); break } catch { $p++ } }; $p"') do set "PORT=%%p"
if not defined PORT set "PORT=%QWEN_PORT%"
if not "%PORT%"=="%QWEN_PORT%" (
  echo WARNING: port %QWEN_PORT% is used by another program, using port %PORT%.
  echo          Chats saved under port %QWEN_PORT% won't show here. Close that program to get them back.
  echo.
)
set "URL=http://127.0.0.1:%PORT%"

set "MMARG="
if defined MMPROJ set MMARG=--mmproj "%MMPROJ%"

rem ---- give the web chat the system prompt as its default "System Message" ----
set "UIARG="
if defined SYSPROMPT (
  set "QWEN_UICFG=%TEMP%\portable-qwen-webui.json"
  powershell -NoProfile -Command "$t=[IO.File]::ReadAllText($env:SYSPROMPT).Replace([string][char]13,'').TrimEnd(); [IO.File]::WriteAllText($env:QWEN_UICFG, (@{systemMessage=$t} | ConvertTo-Json -Compress))"
  if exist "!QWEN_UICFG!" set UIARG=--webui-config-file "!QWEN_UICFG!"
)

rem ---- open the browser once the server is ready (first start only) ----
start "" /b powershell -NoProfile -WindowStyle Hidden -Command "for($i=0;$i -lt 600;$i++){ Start-Sleep 1; try { if((Invoke-WebRequest -UseBasicParsing -TimeoutSec 2 '%URL%/health').StatusCode -eq 200){ Write-Host ''; Write-Host '>>> Ready - chat at %URL%'; Write-Host ''; Start-Process '%URL%'; break } } catch {} }"

rem ---- run the AI; if it stops unexpectedly, restart it automatically ----
set "TRY=0"
set "GPUARG="
:run
"%BIN%\llama-server.exe" -m "%MODEL%" %MMARG% -c %QWEN_CTX% --host 127.0.0.1 --port %PORT% --jinja %UIARG% %EXTRA% %GPUARG%
if not errorlevel 1 goto :end
set /a TRY+=1
if %TRY% GTR 3 (
  echo.
  echo The AI engine keeps stopping. Try:  START-WINDOWS.bat cpu
  goto :end
)
if "%FORCE_CPU%"=="0" if %TRY% GEQ 2 set "GPUARG=-ngl 0"
echo.
echo ==============================================================
echo  The AI engine stopped unexpectedly. Restarting ^(%TRY% of 3^)...
echo  When it says "listening", click Retry in the browser.
echo ==============================================================
echo.
"%SystemRoot%System32	imeout.exe" /t 3 >nul
start "" /b powershell -NoProfile -WindowStyle Hidden -Command "for($i=0;$i -lt 600;$i++){ Start-Sleep 1; try { if((Invoke-WebRequest -UseBasicParsing -TimeoutSec 2 '%URL%/health').StatusCode -eq 200){ Write-Host ''; Write-Host '>>> Ready again - click Retry in the browser, or open %URL%'; Write-Host ''; break } } catch {} }"
goto :run


:fail
echo.
pause
exit /b 1

:end
echo.
pause
