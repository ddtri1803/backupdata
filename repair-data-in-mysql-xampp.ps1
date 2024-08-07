# 11:06:22 SA  [mysql] 	Status change detected: running
# 11:06:23 SA  [mysql] 	Status change detected: stopped
# 11:06:23 SA  [mysql] 	Error: MySQL shutdown unexpectedly.
# 11:06:23 SA  [mysql] 	This may be due to a blocked port, missing dependencies, 
# 11:06:23 SA  [mysql] 	improper privileges, a crash, or a shutdown by another method.
# 11:06:23 SA  [mysql] 	Press the Logs button to view error logs and check
# 11:06:23 SA  [mysql] 	the Windows Event Viewer for more clues
# 11:06:23 SA  [mysql] 	entire log window on the forums

# Function to check if a path exists
function Test-PathAndExit {
    param (
        [string]$path
    )
    if (-Not (Test-Path $path)) {
        Write-Host "Error: Path $path does not exist."
        exit 1
    }
}

# Confirm action with the user
function Confirm-Action {
    param (
        [string]$message
    )
    $confirmation = Read-Host "$message (y/n)"
    if ($confirmation -ne 'y') {
        Write-Host "Action cancelled by user."
        exit 0
    }
}

# Check if necessary paths exist
Test-PathAndExit "./data"
Test-PathAndExit "./backup"

# Confirm action
Confirm-Action "This will backup your current data and replace it with the backup data. Do you want to continue?"

# Backup old data with timestamp
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupOldDataPath = "./data_old_$timestamp"
Rename-Item -Path "./data" -NewName $backupOldDataPath
Write-Host "Old data backed up to $backupOldDataPath"

# Create new data directory
Copy-Item -Path "./backup" -Destination "./data" -Recurse
if (Test-Path "./data/test") {
    Remove-Item "./data/test" -Recurse
}

# Copy necessary databases
$dbPaths = Get-ChildItem -Path $backupOldDataPath -Exclude ('mysql', 'performance_schema', 'phpmyadmin') -Recurse -Directory
foreach ($dbPath in $dbPaths) {
    Copy-Item -Path $dbPath.FullName -Destination "./data" -Recurse
}

# Copy ibdata1 file if it exists
if (Test-Path "$backupOldDataPath/ibdata1") {
    Copy-Item -Path "$backupOldDataPath/ibdata1" -Destination "./data/ibdata1"
}

# Notify user
Write-Host "Finished repairing MySQL data"
Write-Host "Previous data is located at $backupOldDataPath"
