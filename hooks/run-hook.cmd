: << 'CMDBLOCK'
@echo off
REM Cross-platform polyglot wrapper for loom hook scripts.
REM Windows: cmd.exe runs this batch portion, finds bash, calls the named script.
REM Unix: the shell treats ": <<" as a no-op heredoc and runs the bottom portion.
REM Hook scripts are extensionless so Windows auto-detection (which prepends bash
REM to anything containing .sh) doesn't interfere.
REM Adapted from obra/superpowers (MIT).
REM Usage: run-hook.cmd <script-name> [args...]

if "%~1"=="" ( echo run-hook.cmd: missing script name >&2 & exit /b 1 )
set "HOOK_DIR=%~dp0"
if exist "C:\Program Files\Git\bin\bash.exe" (
    "C:\Program Files\Git\bin\bash.exe" "%HOOK_DIR%%~1" %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %ERRORLEVEL%
)
if exist "C:\Program Files (x86)\Git\bin\bash.exe" (
    "C:\Program Files (x86)\Git\bin\bash.exe" "%HOOK_DIR%%~1" %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %ERRORLEVEL%
)
where bash >nul 2>nul
if %ERRORLEVEL% equ 0 (
    bash "%HOOK_DIR%%~1" %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %ERRORLEVEL%
)
REM No bash found — degrade silently (plugin still works, no context injection).
exit /b 0
CMDBLOCK

# Unix: run the named script directly through bash.
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT_NAME="$1"
shift
exec bash "${SCRIPT_DIR}/${SCRIPT_NAME}" "$@"
