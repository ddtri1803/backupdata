# Define the path to the MySQL/MariaDB data directory
$dataDir = "E:\Programs\xampp\mysql\data"

# Stop the MySQL/MariaDB service
Write-Host "Stopping MySQL service..."
Stop-Service -Name "mysql" -Force

# Delete Aria log files
Write-Host "Deleting Aria log files..."
Remove-Item -Path "$dataDir\aria_log.*" -Force

# Run aria_chk to repair Aria tables
Write-Host "Running aria_chk on all Aria tables..."
& "aria_chk" -r "$dataDir\*.MAI"

# Start the MySQL/MariaDB service
Write-Host "Starting MySQL service..."
Start-Service -Name "mysql"

# Run mysql_upgrade to upgrade system tables
Write-Host "Running mysql_upgrade to upgrade system tables..."
& "mysql_upgrade" -u root -p

# Verify that the service is running and check for errors
Write-Host "Checking MySQL service status..."
$serviceStatus = Get-Service -Name "mysql"
if ($serviceStatus.Status -eq "Running") {
    Write-Host "MySQL service is running successfully."
} else {
    Write-Host "MySQL service is not running. Please check the logs for errors."
}

Write-Host "Upgrade and fix process completed. Please check for any additional issues."

# Notes:
# 1. Ensure that 'aria_chk' and 'mysql_upgrade' are in your system PATH or provide their full paths.
# 2. The script will prompt for the MySQL root password. Make sure you have the correct credentials ready.
# 3. Always backup your data before performing these operations.
