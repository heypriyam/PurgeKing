@echo off
setlocal EnableExtensions DisableDelayedExpansion

rem =====================================================
rem  PURGEKING - WINDOWS MAINTENANCE TOOLKIT
rem  Phases 1 (foundation) + 2 (safety framework)
rem  Cleanup modules are stubs until Phase 3+.
rem =====================================================

rem ----- [01] CONSTANTS AND CONFIGURATION --------------
set "APP_NAME=PurgeKing"
set "APP_VERSION=1.0.0"
set "LOG_RETENTION_DAYS=7"
set "DEFAULT_PREVIEW_REQUIRED=1"
rem Feature toggles reserved for Phase 3+ modules (not yet active).
set "ENABLE_BROWSER_MODULE=0"
set "ENABLE_DEVELOPER_MODULE=0"
set "ENABLE_GPU_MODULE=0"

title %APP_NAME% %APP_VERSION%

rem ----- [02] BOOTSTRAP / INITIALIZATION ---------------
rem Resolve the script's own directory (never trust the CWD).
set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

call :DetectEnv
call :InitLog
if not defined LOG_FILE (
    echo [WARN] Logging is unavailable; continuing without a log file.
)

rem ----- [03] ARGUMENT PARSING -------------------------
rem Only non-destructive actions auto-run from a switch. Cleanup
rem switches are accepted but refuse until their module exists.
if not "%~1"=="" (
    call :ParseArgs %*
    goto :Exit
)

rem ----- [06] MAIN MENU --------------------------------
:MainMenu
cls
echo ========================================================
echo                          %APP_NAME%
echo                WINDOWS MAINTENANCE TOOLKIT
echo ========================================================
echo   Windows: %WIN_CAPTION% (build %WIN_BUILD%)
echo   Version: %APP_VERSION%                 Admin: %IS_ADMIN%
echo   Mode: SAFE   (Phase 3 - temp cleanup, analysis, report)
echo --------------------------------------------------------
echo.
echo   [1] Quick Cleanup            (user temporary files)
echo   [2] Deep Cleanup             (coming in Phase 5)
echo   [3] Windows Cleanup          (coming in Phase 4)
echo   [4] NVIDIA / GPU Cleanup     (coming in Phase 4)
echo   [5] Browser Cleanup          (coming in Phase 4)
echo   [6] Developer Cleanup        (coming in Phase 4)
echo.
echo --------------------------------------------------------
echo   [7] Analyze System Junk      (read-only preview)
echo   [8] System Health Report
echo   [9] Run Selected / All       (coming in Phase 5)
echo.
echo   [T] Run Safety Self-Test     (Phase 2)
echo   [L] View Latest Log
echo   [H] Help ^& Safety Information
echo   [0] Exit
echo.
echo ========================================================
set "CHOICE="
set /p "CHOICE=  Select an option: "

if not defined CHOICE goto :MainMenu
if /i "%CHOICE%"=="0" goto :Exit
if /i "%CHOICE%"=="1" ( call :QuickCleanup & pause & goto :MainMenu )
if /i "%CHOICE%"=="2" ( call :ModuleStub "Deep Cleanup" "Phase 5" & goto :MainMenu )
if /i "%CHOICE%"=="3" ( call :ModuleStub "Windows Cleanup" "Phase 4" & goto :MainMenu )
if /i "%CHOICE%"=="4" ( call :ModuleStub "NVIDIA / GPU Cleanup" "Phase 4" & goto :MainMenu )
if /i "%CHOICE%"=="5" ( call :ModuleStub "Browser Cleanup" "Phase 4" & goto :MainMenu )
if /i "%CHOICE%"=="6" ( call :ModuleStub "Developer Cleanup" "Phase 4" & goto :MainMenu )
if /i "%CHOICE%"=="7" ( call :AnalyzeSystemJunk & pause & goto :MainMenu )
if /i "%CHOICE%"=="8" ( call :SystemReport & pause & goto :MainMenu )
if /i "%CHOICE%"=="9" ( call :ModuleStub "Run Everything" "Phase 5" & goto :MainMenu )
if /i "%CHOICE%"=="T" ( call :SelfTest & pause & goto :MainMenu )
if /i "%CHOICE%"=="L" ( call :ViewLatestLog & pause & goto :MainMenu )
if /i "%CHOICE%"=="H" ( call :Help & pause & goto :MainMenu )

echo.
echo   Invalid option: "%CHOICE%". Press a valid key.
timeout /t 2 /nobreak >nul 2>&1
goto :MainMenu


rem ----- [03b] ARGUMENT PARSING ROUTINE ----------------
:ParseArgs
set "arg=%~1"
if /i "%arg%"=="/help"    ( call :Help & exit /b 0 )
if /i "%arg%"=="/?"       ( call :Help & exit /b 0 )
if /i "%arg%"=="/selftest" ( call :SelfTest & exit /b %errorlevel% )
rem Phase 3 actions. /quick is destructive, so it still confirms inside.
if /i "%arg%"=="/quick"   ( call :QuickCleanup & exit /b 0 )
if /i "%arg%"=="/analyze" ( call :AnalyzeSystemJunk & exit /b 0 )
if /i "%arg%"=="/report"  ( call :SystemReport & exit /b 0 )
rem Remaining module switches: refuse until the module exists.
rem Never treat an argument as permission to delete.
for %%S in (/deep /browser /python /gpu /everything) do (
    if /i "%arg%"=="%%S" (
        echo %APP_NAME%: "%arg%" is not available yet ^(cleanup modules arrive in Phase 3+^).
        call :Log INFO "CLI switch %arg% requested but module not implemented."
        exit /b 0
    )
)
echo %APP_NAME%: unknown argument "%arg%". Use /help.
call :Log INFO "Unknown CLI argument: %arg%"
exit /b 1


rem ----- [04] ENVIRONMENT AND ADMIN CHECKS -------------
:DetectEnv
rem Admin: net session succeeds only when elevated.
net session >nul 2>&1
if errorlevel 1 ( set "IS_ADMIN=No" ) else ( set "IS_ADMIN=Yes" )

rem Windows build/caption without wmic or PowerShell (reg is native).
set "WIN_BUILD=?"
set "WIN_CAPTION=Windows"
for /f "tokens=2,*" %%A in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v CurrentBuild 2^>nul ^| findstr /i "CurrentBuild"') do set "WIN_BUILD=%%B"
for /f "tokens=2,*" %%A in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v ProductName 2^>nul ^| findstr /i "ProductName"') do set "WIN_CAPTION=%%B"
exit /b 0


rem ----- [05] LOGGING UTILITIES ------------------------
:InitLog
rem Prefer a logs folder beside the script; fall back to LOCALAPPDATA.
set "LOG_FILE="
set "LOG_DIR=%SCRIPT_DIR%\logs"
call :TryLogDir "%LOG_DIR%"
if defined LOG_FILE goto :InitLogHeader
set "LOG_DIR=%LOCALAPPDATA%\%APP_NAME%\logs"
echo [WARN] Script folder not writable; using fallback log location.
call :TryLogDir "%LOG_DIR%"
if not defined LOG_FILE exit /b 1

:InitLogHeader
call :Stamp
set "LOG_FILE=%LOG_DIR%\%STAMP_FILE%.log"
>>"%LOG_FILE%" echo ========================================================
>>"%LOG_FILE%" echo %APP_NAME% LOG
>>"%LOG_FILE%" echo Version: %APP_VERSION%
>>"%LOG_FILE%" echo Started: %STAMP_HUMAN%
>>"%LOG_FILE%" echo Windows: %WIN_CAPTION% (build %WIN_BUILD%)
>>"%LOG_FILE%" echo Elevated: %IS_ADMIN%
>>"%LOG_FILE%" echo ========================================================
call :PruneLogs
exit /b 0

:TryLogDir
rem %1 = candidate dir. Sets LOG_FILE (as a writable flag) on success.
if not exist "%~1" mkdir "%~1" >nul 2>&1
rem Probe writability with a temp file we immediately delete.
>"%~1\.writetest" echo ok 2>nul
if exist "%~1\.writetest" (
    del /f /q "%~1\.writetest" >nul 2>&1
    set "LOG_FILE=pending"
)
exit /b 0

:Log
rem %1 = level (INFO/OK/SKIP/ERROR/WARN), %2 = quoted message.
if not defined LOG_FILE exit /b 0
if "%LOG_FILE%"=="pending" exit /b 0
call :Stamp
>>"%LOG_FILE%" echo [%~1] %STAMP_HUMAN% %~2
exit /b 0

:PruneLogs
rem Delete our own logs older than retention. forfiles is native on 10/11.
if not defined LOG_DIR exit /b 0
forfiles /p "%LOG_DIR%" /m "*.log" /d -%LOG_RETENTION_DAYS% /c "cmd /c del /f /q @path" >nul 2>&1
exit /b 0

:Stamp
rem shortcut: %DATE%/%TIME% are locale-formatted; we only sanitize them
rem into filename-safe text. Good enough for log names; a locale-stable
rem timestamp would need PowerShell/wmic, both excluded by the spec.
set "STAMP_HUMAN=%DATE% %TIME%"
set "STAMP_FILE=%STAMP_HUMAN%"
set "STAMP_FILE=%STAMP_FILE:/=-%"
set "STAMP_FILE=%STAMP_FILE::=-%"
set "STAMP_FILE=%STAMP_FILE: =_%"
set "STAMP_FILE=%STAMP_FILE:.=-%"
set "STAMP_FILE=%STAMP_FILE:,=-%"
exit /b 0

:ViewLatestLog
if not defined LOG_FILE ( echo   No log file available. & exit /b 0 )
if "%LOG_FILE%"=="pending" ( echo   Logging is unavailable. & exit /b 0 )
echo.
echo --- %LOG_FILE% ---
echo.
type "%LOG_FILE%"
echo.
exit /b 0


rem ----- [07] MODULE ROUTER (stubs for now) ------------
:ModuleStub
rem %1 = module name, %2 = which phase delivers it.
cls
echo ========================================================
echo   %~1
echo ========================================================
echo.
echo   This module is not implemented yet.
echo   It is scheduled for %~2.
echo.
echo   The Phase 1+2 build ships the application shell and the
echo   safety framework (path validation, protected-path
echo   rejection, reparse-point policy, confirmation, and the
echo   safe-delete helper). Run the Safety Self-Test [T] to
echo   exercise that framework.
echo.
call :Log INFO "Module requested (not implemented): %~1"
pause
exit /b 0


rem ----- [16] SAFE FILE OPERATIONS ---------------------
:SafeDeleteContents
rem Delete the CONTENTS of a validated cache directory, never the
rem directory itself. %1 = target dir, %2 = allowlisted parent.
rem Returns: SD_STATUS = SUCCESS | SUCCESS_WITH_SKIPS | SKIPPED | FAILED
rem          SD_DELETED / SD_REMAINING = file counts.
set "SD_STATUS=FAILED"
set "SD_DELETED=0"
set "SD_REMAINING=0"

call :ValidatePath "%~1" "%~2"
if not "%VP_OK%"=="1" (
    call :Log ERROR "SafeDelete refused '%~1': %VP_REASON%"
    set "SD_STATUS=FAILED"
    exit /b 1
)

rem Target must exist (missing is a normal, non-fatal condition).
if not exist "%VP_FULL%\" (
    call :Log SKIP "Target does not exist: %VP_FULL%"
    set "SD_STATUS=SKIPPED"
    exit /b 0
)

rem Reparse-point policy: if the target OR anything under it is a
rem junction/symlink, skip the whole target rather than risk a
rem recursive delete escaping the tree (spec 8.5).
call :TreeHasReparse "%VP_FULL%"
if "%TREE_REPARSE%"=="1" (
    call :Log SKIP "Reparse point found under '%VP_FULL%'; skipped for safety."
    set "SD_STATUS=SKIPPED"
    exit /b 0
)

rem Count eligible files first so we can report honest deleted/remaining.
call :CountFiles "%VP_FULL%"
set "SD_BEFORE=%CF_COUNT%"

rem No reparse points under the tree were found, so del /s and rd are
rem safe here: del removes files only; rd then clears emptied subdirs.
del /f /s /q "%VP_FULL%\*" >nul 2>&1
for /d %%D in ("%VP_FULL%\*") do rd /s /q "%%~fD" >nul 2>&1

call :CountFiles "%VP_FULL%"
set "SD_REMAINING=%CF_COUNT%"
set /a SD_DELETED=%SD_BEFORE% - %SD_REMAINING%
if %SD_DELETED% lss 0 set "SD_DELETED=0"

if %SD_REMAINING% gtr 0 (
    set "SD_STATUS=SUCCESS_WITH_SKIPS"
    call :Log OK "Deleted %SD_DELETED% file(s); %SD_REMAINING% locked/skipped in %VP_FULL%"
) else (
    set "SD_STATUS=SUCCESS"
    call :Log OK "Deleted %SD_DELETED% file(s) in %VP_FULL%"
)
exit /b 0

:CountFiles
rem %1 = dir. Sets CF_COUNT to the number of files under it.
set "CF_COUNT=0"
if not exist "%~1\" exit /b 0
for /f %%N in ('dir /s /b /a:-d "%~1" 2^>nul ^| find /c /v ""') do set "CF_COUNT=%%N"
exit /b 0


rem ----- [17] VALIDATION UTILITIES ---------------------
:ValidatePath
rem %1 = candidate path, %2 = allowlisted parent it must sit under.
rem Sets VP_OK (1/0), VP_REASON, VP_FULL (normalized candidate).
rem shortcut: uses delayed expansion, so paths containing '!' are not
rem supported; approved cache targets don't contain '!'. Revisit if a
rem future target path can include it.
setlocal EnableDelayedExpansion
set "cand=%~1"
set "parent=%~2"
set "ok=1"
set "reason=OK"

rem Normalize to fully-qualified paths (collapses . and ..).
if not defined cand (
    endlocal & set "VP_OK=0" & set "VP_REASON=empty path" & set "VP_FULL="
    exit /b 1
)
for %%I in ("!cand!")   do set "full=%%~fI"
for %%I in ("!parent!") do set "pfull=%%~fI"

:vp_check
rem Reject UNC / network paths.
if "!full:~0,2!"=="\\" ( set "ok=0" & set "reason=UNC/network path not allowed" & goto :vp_done )

rem Reject a bare drive root (e.g. C:\).
if "!full:~1,2!"==":\" if "!full:~3!"=="" ( set "ok=0" & set "reason=drive root not allowed" & goto :vp_done )

rem Hard-blocked trees: reject if equal to, or underneath, any of these.
for %%P in (
    "!SystemRoot!"
    "!SystemRoot!\System32"
    "!SystemRoot!\WinSxS"
    "!SystemRoot!\Installer"
    "!SystemRoot!\System32\DriverStore"
    "!ProgramFiles!"
    "!ProgramFiles(x86)!"
) do (
    call :_UnderOrEqual "!full!" "%%~fP"
    if "!UE!"=="1" ( set "ok=0" & set "reason=protected system location: %%~fP" & goto :vp_done )
)

rem Roots we allow children of but never the root itself.
for %%P in (
    "!USERPROFILE!"
    "!LOCALAPPDATA!"
    "!APPDATA!"
    "!USERPROFILE!\Documents"
    "!USERPROFILE!\Desktop"
    "!USERPROFILE!\Downloads"
) do (
    if /i "!full!"=="%%~fP" ( set "ok=0" & set "reason=refusing a whole profile root: %%~fP" & goto :vp_done )
)

rem Positive allowlist: the candidate MUST sit under the module's parent.
if not defined parent ( set "ok=0" & set "reason=no allowlisted parent supplied" & goto :vp_done )
call :_UnderOrEqual "!full!" "!pfull!"
if not "!UE!"=="1" ( set "ok=0" & set "reason=outside allowlisted parent !pfull!" & goto :vp_done )

:vp_done
endlocal & set "VP_OK=%ok%" & set "VP_REASON=%reason%" & set "VP_FULL=%full%"
if "%VP_OK%"=="1" ( exit /b 0 ) else ( exit /b 1 )

:_UnderOrEqual
rem %1 = full child, %2 = base. Sets UE=1 if child == base or under base\.
rem Prefix-safe (appends \ so C:\Foo does not match C:\FooBar).
setlocal EnableDelayedExpansion
set "child=%~1"
set "base=%~2"
set "UE=0"
if /i "!child!"=="!base!" ( set "UE=1" & goto :ue_done )
set "needle=!base!\"
set "n=0"
set "s=!needle!"
:ue_len
if defined s ( set "s=!s:~1!" & set /a n+=1 & goto :ue_len )
if /i "!child:~0,%n%!"=="!needle!" set "UE=1"
:ue_done
endlocal & set "UE=%UE%"
exit /b 0

:TreeHasReparse
rem %1 = dir. Sets TREE_REPARSE=1 if any junction/symlink exists in the
rem tree (including the root). dir /a:l lists reparse points.
rem shortcut: scans the whole tree, so it is slow on huge dirs; cache
rem targets are small enough. Nested-junction detection relies on dir's
rem reporting, which is adequate but not a kernel-level guarantee.
set "TREE_REPARSE=0"
for /f "delims=" %%L in ('dir /s /a:l "%~1" 2^>nul ^| findstr /i "<JUNCTION> <SYMLINKD> <SYMLINK>"') do set "TREE_REPARSE=1"
exit /b 0


rem ----- [18] CONFIRMATION FRAMEWORK -------------------
:Confirm
rem %1 = quoted prompt. Sets CONFIRMED=1 on yes, 0 on no.
rem Uses choice when available, else falls back to set /p.
set "CONFIRMED=0"
where choice >nul 2>&1
if errorlevel 1 (
    set "ans="
    set /p "ans=%~1 [y/N]: "
    if /i "%ans%"=="y" set "CONFIRMED=1"
    exit /b 0
)
choice /c YN /n /m "%~1 [Y/N]: "
if errorlevel 2 ( set "CONFIRMED=0" ) else ( set "CONFIRMED=1" )
exit /b 0


rem ----- Help & Safety ---------------------------------
:Help
cls
echo ========================================================
echo   %APP_NAME% %APP_VERSION% - Help ^& Safety
echo ========================================================
echo.
echo   %APP_NAME% removes only disposable files from a small,
echo   reviewed allowlist. It never touches System32, WinSxS,
echo   the Installer cache, DriverStore, Program Files, your
echo   documents, or browser profiles.
echo.
echo   This build contains the application shell and the
echo   safety framework only. Cleanup modules arrive in later
echo   phases and will always: preview first, require explicit
echo   confirmation, and log every outcome.
echo.
echo   Command-line switches:
echo     /help       Show this screen
echo     /selftest   Run the safety-framework self-test
echo     /quick      Quick Cleanup of user temp (asks to confirm)
echo     /analyze    Read-only preview of approved targets
echo     /report     System health report
echo     /deep /browser /python /gpu /everything
echo                 (accepted but refuse until implemented)
echo.
echo   Safety rules enforced now:
echo     - Empty paths, drive roots, and UNC paths are rejected.
echo     - Protected Windows/Program Files trees are rejected.
echo     - A target must sit under its module's allowlisted parent.
echo     - Directories containing junctions/symlinks are skipped.
echo     - Deletes clear contents, never the parent folder.
echo.
echo   Logs are written locally to:
echo     %LOG_DIR%
echo   Nothing is uploaded. No PowerShell, no network, no deps.
echo.
exit /b 0


rem ----- [08] ANALYSIS ENGINE (read-only) --------------
:AnalyzeTarget
rem %1 = display name, %2 = target path, %3 = allowlisted parent.
rem Read-only: validates, checks existence, counts files, flags
rem reparse points. Sets AT_STATUS and AT_FILES. Never deletes.
set "AT_FILES=0"
set "AT_STATUS=?"
call :ValidatePath "%~2" "%~3"
if not "%VP_OK%"=="1" (
    set "AT_STATUS=INVALID"
    echo   %~1: NOT ANALYZED ^(%VP_REASON%^)
    call :Log ERROR "Analyze refused '%~2': %VP_REASON%"
    exit /b 0
)
if not exist "%VP_FULL%\" (
    set "AT_STATUS=MISSING"
    echo   %~1: not present ^(nothing to clean^)
    call :Log INFO "Analyze: target missing: %VP_FULL%"
    exit /b 0
)
call :TreeHasReparse "%VP_FULL%"
call :CountFiles "%VP_FULL%"
set "AT_FILES=%CF_COUNT%"
if "%TREE_REPARSE%"=="1" (
    set "AT_STATUS=SKIP_REPARSE"
    echo   %~1: %AT_FILES% file^(s^); contains a junction/symlink -^> would be SKIPPED
    call :Log INFO "Analyze: %~1 has reparse point; %AT_FILES% files; would skip."
) else (
    set "AT_STATUS=READY"
    echo   %~1: %AT_FILES% eligible file^(s^)  [size estimate unavailable]
    call :Log INFO "Analyze: %~1 eligible files=%AT_FILES%"
)
exit /b 0


rem ----- [09] QUICK CLEANUP ----------------------------
:QuickCleanup
cls
echo ========================================================
echo   Quick Cleanup - user temporary files
echo ========================================================
echo.
echo   Removes disposable files from your per-user temp folder:
echo     %TEMP%
echo   Files in use are locked by Windows and will be skipped.
echo   Your own temp files created right now may remain; that
echo   is normal. PurgeKing's old logs are pruned automatically
echo   at startup (retention: %LOG_RETENTION_DAYS% days).
echo.
echo   Preview:
call :AnalyzeTarget "User temporary files" "%TEMP%" "%LOCALAPPDATA%"
echo.
call :Log INFO "Quick Cleanup: analysis complete, awaiting confirmation."
call :Confirm "Delete eligible temporary files now?"
if not "%CONFIRMED%"=="1" (
    echo.
    echo   Cancelled. Nothing was deleted.
    call :Log INFO "Quick Cleanup: CANCELLED by user."
    exit /b 0
)
echo.
echo   Cleaning...
call :SafeDeleteContents "%TEMP%" "%LOCALAPPDATA%"
echo.
echo   --- Quick Cleanup summary ---
echo   Status : %SD_STATUS%
echo   Deleted: %SD_DELETED% file(s)
echo   Skipped: %SD_REMAINING% file(s) (locked/in-use; counts approximate)
call :Log INFO "Quick Cleanup finished: status=%SD_STATUS% deleted=%SD_DELETED% skipped=%SD_REMAINING%"
exit /b 0


rem ----- Analyze System Junk (read-only preview) -------
:AnalyzeSystemJunk
cls
echo ========================================================
echo   Analyze System Junk (read-only - nothing is deleted)
echo ========================================================
echo.
echo   Approved targets available in this build:
echo.
call :AnalyzeTarget "User temporary files" "%TEMP%" "%LOCALAPPDATA%"
echo.
echo   Other modules (Windows, GPU, browser, developer) arrive
echo   in later phases and are not analyzed yet.
echo.
echo   Note: sizes are not estimated in this build to avoid
echo   inaccurate totals; file counts are exact at scan time.
call :Log INFO "Analyze System Junk completed."
exit /b 0


rem ----- [15] SYSTEM HEALTH REPORT ---------------------
:SystemReport
cls
echo ========================================================
echo   System Health Report (local, read-only)
echo ========================================================
echo.
echo   PurgeKing version : %APP_VERSION%
echo   Windows           : %WIN_CAPTION% (build %WIN_BUILD%)
echo   Elevated          : %IS_ADMIN%
echo   Computer name     : %COMPUTERNAME%
echo   System drive      : %SystemDrive%
echo   User temp path    : %TEMP%
echo.
echo   --- System drive free space ---
rem 'dir' reports free space without elevation (fsutil often needs admin).
rem The line is "N Dir(s)  X bytes free"; split on ')' to drop the prefix.
rem Echo flat (not inside parens) because the text contains ')'.
set "FREELINE="
for /f "tokens=*" %%F in ('dir %SystemDrive%\ 2^>nul ^| findstr /i /c:"bytes free"') do set "FREELINE=%%F"
if not defined FREELINE set "FREELINE=) query unavailable"
for /f "tokens=2 delims=)" %%G in ("%FREELINE%") do set "FREELINE=%%G"
echo   Free:%FREELINE%
echo.
echo   --- Detected browsers ---
if exist "%LOCALAPPDATA%\Google\Chrome\User Data"   (echo   Google Chrome   : present) else (echo   Google Chrome   : not found)
if exist "%LOCALAPPDATA%\Microsoft\Edge\User Data"  (echo   Microsoft Edge  : present) else (echo   Microsoft Edge  : not found)
if exist "%APPDATA%\Mozilla\Firefox\Profiles"       (echo   Mozilla Firefox : present) else (echo   Mozilla Firefox : not found)
echo.
echo   --- Detected developer tools ---
call :ReportTool "Python" python
call :ReportTool "Node/npm" npm
call :ReportTool "pip" pip
echo.
echo   Latest log: %LOG_FILE%
call :Log INFO "System Health Report generated."
exit /b 0

:ReportTool
rem %1 = label, %2 = executable to probe with 'where'.
where %2 >nul 2>&1
if errorlevel 1 ( echo   %~1 : not found ) else ( echo   %~1 : present )
exit /b 0


rem ----- Phase 2 self-test -----------------------------
:SelfTest
cls
echo ========================================================
echo   %APP_NAME% - Safety Framework Self-Test
echo ========================================================
echo.
set "ST_PASS=0"
set "ST_FAIL=0"
call :Log INFO "Self-test started."

rem --- Path validation: these MUST be rejected ---
call :_AssertReject ""                               "empty path"
call :_AssertReject "C:\"                             "drive root"
call :_AssertReject "%SystemRoot%"                    "Windows root"
call :_AssertReject "%SystemRoot%\System32"           "System32"
call :_AssertReject "%SystemRoot%\WinSxS"             "WinSxS"
call :_AssertReject "%SystemRoot%\Installer"          "Installer"
call :_AssertReject "%SystemRoot%\System32\DriverStore" "DriverStore"
call :_AssertReject "%USERPROFILE%"                   "whole profile root"
call :_AssertReject "\\server\share\x"                "UNC path"
call :_AssertReject "%TEMP%\..\..\Windows\System32"   "escape via .."

rem --- Path validation: this MUST be accepted ---
set "ST_GOODPARENT=%TEMP%"
call :_AssertAccept "%TEMP%\PurgeKing_selftest"       "child of %%TEMP%%"

rem --- A path OUTSIDE the allowlisted parent MUST be rejected ---
call :ValidatePath "%ProgramData%\somecache" "%TEMP%"
if "%VP_OK%"=="1" ( call :_Fail "outside-parent path was accepted" ) else ( call :_Ok "outside-parent path rejected" )

rem --- Safe delete against a disposable fixture ---
call :_SelfTestDelete

echo.
echo --------------------------------------------------------
echo   Self-test result: %ST_PASS% passed, %ST_FAIL% failed.
echo --------------------------------------------------------
call :Log INFO "Self-test finished: %ST_PASS% passed, %ST_FAIL% failed."
if %ST_FAIL% gtr 0 ( exit /b 1 ) else ( exit /b 0 )

:_AssertReject
rem %1 = path, %2 = label. Passes if validation rejects it.
call :ValidatePath "%~1" "C:\PurgeKingAllow"
if "%VP_OK%"=="1" ( call :_Fail "should reject %~2 (%~1)" ) else ( call :_Ok "rejected %~2" )
exit /b 0

:_AssertAccept
rem %1 = path (must be under ST_GOODPARENT), %2 = label.
call :ValidatePath "%~1" "%ST_GOODPARENT%"
if "%VP_OK%"=="1" ( call :_Ok "accepted %~2" ) else ( call :_Fail "should accept %~2 (%VP_REASON%)" )
exit /b 0

:_SelfTestDelete
set "FX=%TEMP%\PurgeKing_selftest"
rd /s /q "%FX%" >nul 2>&1
mkdir "%FX%" >nul 2>&1
mkdir "%FX%\sub" >nul 2>&1
>"%FX%\a.tmp" echo x
>"%FX%\b.tmp" echo x
>"%FX%\sub\c.tmp" echo x

call :SafeDeleteContents "%FX%" "%TEMP%"
if not exist "%FX%\" ( call :_Fail "safe-delete removed the parent folder" & exit /b 0 )
call :CountFiles "%FX%"
if "%CF_COUNT%"=="0" (
    call :_Ok "safe-delete cleared contents, kept folder (status %SD_STATUS%)"
) else (
    call :_Fail "safe-delete left %CF_COUNT% file(s) behind"
)

rem Reparse policy: a junction in the tree must cause a SKIP.
rem Flat flow (no parenthesized block) so %SD_STATUS% is read AFTER the
rem call, not expanded at parse time.
mkdir "%FX%\sub" >nul 2>&1
>"%FX%\d.tmp" echo x
mklink /j "%FX%\link" "%SystemRoot%" >nul 2>&1
if not exist "%FX%\link\" (
    echo   [info] Could not create a junction fixture; reparse test skipped.
    goto :st_del_done
)
call :SafeDeleteContents "%FX%" "%TEMP%"
if /i "%SD_STATUS%"=="SKIPPED" ( call :_Ok "junction in tree = SKIPPED, target untouched" ) else ( call :_Fail "junction present but status was %SD_STATUS%" )
rd "%FX%\link" >nul 2>&1

:st_del_done
rd /s /q "%FX%" >nul 2>&1
exit /b 0

:_Ok
set /a ST_PASS+=1
echo   [PASS] %~1
exit /b 0

:_Fail
set /a ST_FAIL+=1
echo   [FAIL] %~1
call :Log ERROR "Self-test failure: %~1"
exit /b 0


rem ----- [19] EXIT / CLEAN SHUTDOWN --------------------
:Exit
call :Log INFO "Session ended."
endlocal
exit /b 0
