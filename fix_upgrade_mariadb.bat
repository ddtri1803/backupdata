@echo off
setlocal
:: fix_upgrade_mariadb.bat fix aria_chk, log
:: Define the path to the MySQL/MariaDB data directory
set DATA_DIR="E:\Programs\xampp\mysql\data"

:: Stop the MySQL service
echo Stopping MySQL service...
net stop mysql

:: Delete Aria log files
echo Deleting Aria log files...
del /q %DATA_DIR%\aria_log.*

:: Run aria_chk to repair Aria tables
echo Running aria_chk on all Aria tables...
aria_chk -r %DATA_DIR%\*.MAI

:: Start the MySQL service
echo Starting MySQL service...
net start mysql

:: Run mysql_upgrade to upgrade system tables
echo Running mysql_upgrade to upgrade system tables...
mysql_upgrade -u root -p

:: Verify service status
echo Checking MySQL service status...
sc query mysql | find "RUNNING"
if %ERRORLEVEL% == 0 (
    echo MySQL service is running successfully.
) else (
    echo MySQL service is not running. Please check the logs for errors.
)

endlocal
echo Upgrade and fix process completed. Please check for any additional issues.
pause

:: Notes:
:: 1. Ensure 'aria_chk' and 'mysql_upgrade' are in your system PATH or provide their full paths.
:: 2. The script will prompt for the MySQL root password. Ensure you have the correct credentials ready.
:: 3. Always backup your data before performing these operations.
