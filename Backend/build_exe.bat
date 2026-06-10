@echo off
setlocal EnableDelayedExpansion

REM ============================================================
REM  build_exe.bat  —  One-click builder for BillingServer.exe
REM
REM  Usage: Double-click this file from the Backend\ folder,
REM         OR run from a command prompt:
REM              cd /d "D:\Freelance\Billing And Sales System\Backend"
REM              build_exe.bat
REM
REM  Output: dist\BillingServer.exe
REM          dist\media\          (product images — ship alongside exe)
REM
REM  Spec file used: django_app.spec
REM
REM  Requirements on BUILD machine:
REM    - Python 3.10+ virtual env in env\
REM    - MySQL development headers (mysqlclient C extension)
REM    - All packages installed via:  pip install -r requirements.txt
REM ============================================================

echo.
echo ============================================================
echo   Billing ^& Sales System Server  --  EXE Build Script
echo ============================================================
echo.

REM ---------------------------------------------------------------
REM  Ensure we are running from the Backend\ directory
REM ---------------------------------------------------------------
if not exist "django_app.spec" (
    echo [ERROR] django_app.spec not found.
    echo         Run this script from the Backend\ folder.
    goto :error
)

REM ---------------------------------------------------------------
REM  Step 1: Activate virtual environment
REM ---------------------------------------------------------------
echo [1/7] Activating virtual environment ...
if exist "env\Scripts\activate.bat" (
    call env\Scripts\activate.bat
    echo       OK — env\ activated.
) else if exist "..\env\Scripts\activate.bat" (
    call ..\env\Scripts\activate.bat
    echo       OK — parent env\ activated.
) else (
    echo [WARN] env\ not found — using system Python.
    echo         Consider running from the parent folder:  python -m venv env
)
echo.

REM ---------------------------------------------------------------
REM  Step 2: Sync all dependencies from requirements.txt
REM ---------------------------------------------------------------
echo [2/7] Syncing dependencies from requirements.txt ...
pip install -r requirements.txt --quiet
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] pip install failed. Check your internet connection or requirements.txt.
    goto :error
)
echo       OK — all dependencies installed.
echo.

REM ---------------------------------------------------------------
REM  Step 3: Run Django system checks
REM ---------------------------------------------------------------
echo [3/7] Running Django system checks ...
python manage.py check --deploy 2>nul || python manage.py check
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Django check failed — fix the errors above before building.
    goto :error
)
echo       OK — Django checks passed.
echo.

REM ---------------------------------------------------------------
REM  Step 4: Stop any running instance and clean previous artifacts
REM ---------------------------------------------------------------
echo [4/7] Cleaning previous build artifacts ...

tasklist /FI "IMAGENAME eq BillingServer.exe" 2>nul | find /I "BillingServer.exe" >nul
if %ERRORLEVEL% EQU 0 (
    echo       Stopping running BillingServer.exe ...
    taskkill /F /IM BillingServer.exe >nul 2>&1
    timeout /t 3 /nobreak >nul
    echo       OK — server process stopped.
)

if exist "dist\BillingServer.exe" (
    del /f /q "dist\BillingServer.exe"
    if exist "dist\BillingServer.exe" (
        echo [ERROR] Cannot delete dist\BillingServer.exe — file is still locked.
        echo         Close any program that is using it, then try again.
        goto :error
    )
)

REM Remove stale log so it does not get shipped to end-users
if exist "dist\billing_server.log" del /f /q "dist\billing_server.log"

if exist "build\django_app" rmdir /s /q "build\django_app"
echo       OK — clean done.
echo.

REM ---------------------------------------------------------------
REM  Step 5: Run PyInstaller
REM ---------------------------------------------------------------
echo [5/7] Running PyInstaller (this may take several minutes) ...
pyinstaller django_app.spec --clean --noconfirm
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] PyInstaller failed — see output above.
    goto :error
)
if not exist "dist\BillingServer.exe" (
    echo [ERROR] PyInstaller finished but dist\BillingServer.exe was not created.
    goto :error
)
echo       OK — dist\BillingServer.exe created.
echo.

REM ---------------------------------------------------------------
REM  Step 6: Copy media\ folder next to the exe
REM          (media is intentionally NOT bundled inside the exe so
REM           product images can be updated without rebuilding)
REM ---------------------------------------------------------------
echo [6/7] Copying media\ folder to dist\ ...
if exist "dist\media" (
    rmdir /s /q "dist\media"
    echo       Cleared old dist\media\.
)
if exist "media" (
    xcopy /e /i /y "media" "dist\media" >nul
    echo       OK — media\ copied to dist\media\
) else (
    mkdir "dist\media\product_images"
    echo       NOTE: media\ not found — created empty dist\media\product_images\
)
echo.

REM ---------------------------------------------------------------
REM  Step 7: Print distribution summary
REM ---------------------------------------------------------------
echo [7/7] Build complete!
echo.
echo ============================================================
echo   DISTRIBUTION FOLDER:  dist\
echo ============================================================
echo.
echo   BillingServer.exe      -- the server application
echo   media\                 -- product images  (ship alongside exe)
echo.
echo   On the target machine:
echo     1. Install MySQL 8+ and start the MySQL service
echo     2. Create the database:
echo           mysql -u root -p
echo           CREATE DATABASE pos_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
echo     3. Copy BillingServer.exe AND media\ to the same folder
echo     4. Double-click BillingServer.exe
echo     5. A tray icon appears -- server is running on http://localhost:8000
echo     6. Right-click the tray icon -^> "Open Admin Panel" for Django admin
echo     7. Logs are written to billing_server.log in the same folder
echo.
echo ============================================================
echo.
goto :eof

:error
echo.
echo ============================================================
echo   BUILD FAILED -- see errors above
echo ============================================================
echo.
pause
exit /b 1
