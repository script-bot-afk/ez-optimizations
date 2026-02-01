@echo off
REM -----------------------------------------------------------
REM optimize_windows.bat
REM Safe, non-destructive Windows tweaks to free space and
REM improve responsiveness. DOES NOT touch %windir%\System32.
REM Requires Administrator privileges. Run as Administrator.
REM -----------------------------------------------------------

:: Check for admin; relaunch elevated if necessary
net session >nul 2>&1
if %errorlevel% neq 0 (
  echo Administrative privileges are required. Relaunching...
  powershell -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
  exit /b
)

echo.
echo === Beginning safe optimization routine ===
echo This script will:
echo  - Clear temporary files for the current user and Windows temp
echo  - Empty the Recycle Bin
echo  - Flush DNS and reset network stacks (requires restart for some changes)
echo  - Run DISM component cleanup and SFC system file scan
echo  - Optimize (defrag/trim) the C: drive (Windows will no-op on SSDs)
echo  - Clear thumbnail cache
echo.
pause

REM 1) Clear current user's Temp
echo.
echo [1/9] Clearing user Temp: %temp%
del /f /s /q "%temp%\*" >nul 2>&1
for /d %%p in ("%temp%\*.*") do rmdir "%%p" /s /q >nul 2>&1

REM 2) Clear Windows Temp
echo [2/9] Clearing Windows Temp: %windir%\Temp
del /f /s /q "%windir%\Temp\*" >nul 2>&1
for /d %%p in ("%windir%\Temp\*.*") do rmdir "%%p" /s /q >nul 2>&1

REM 3) Empty Recycle Bin (PowerShell)
echo [3/9] Emptying Recycle Bin
powershell -NoProfile -Command "Try { Clear-RecycleBin -Force -ErrorAction Stop } Catch { Exit 0 }"

REM 4) Flush DNS cache
echo [4/9] Flushing DNS cache
ipconfig /flushdns >nul 2>&1

REM 5) Reset network stacks (winsock and IP). A reboot may be required.
echo [5/9] Resetting network stacks (winsock, IP). A reboot may be required.
netsh winsock reset >nul 2>&1
netsh int ip reset >nul 2>&1

REM 6) DISM cleanup (component store) - safe maintenance
echo [6/9] Running DISM component cleanup (may take several minutes)...
dism /online /cleanup-image /startcomponentcleanup

REM 7) DISM restorehealth then SFC scan (checks/repairs system files)
echo [7/9] Running DISM restorehealth (may take many minutes)...
dism /online /cleanup-image /restorehealth
echo [8/9] Running SFC system file scan (sfc /scannow)...
sfc /scannow

REM 8) Optimize drives (defrag/trim). Windows optimizes SSDs automatically.
echo [9/9] Optimizing C: (defrag/trim)
defrag C: /O

REM Extra: Clear thumbnail cache
echo Clearing thumbnail caches
del /f /s /q "%localappdata%\Microsoft\Windows\Explorer\thumbcache_*" >nul 2>&1

echo.
echo === Optimization routine complete ===
echo Recommended: Restart your PC to apply network resets and complete cleanup.
echo Note: This script intentionally avoids touching %windir%\System32.
echo.

pause
exit /b