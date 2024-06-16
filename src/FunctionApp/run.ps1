# run.ps1

# Get the path to the modules directory
$modulesPath = Join-Path $PSScriptRoot 'modules'

# Recursively import all PowerShell modules (.psm1 files) in the modules directory
Get-ChildItem -Path $modulesPath -Filter *.psm1 -Recurse | ForEach-Object {
    Write-Output "Importing module: $modulesPath\$_"
    Import-Module "$modulesPath\$_"
}


# Define the path to the AWS-Cloudtrail.ps1 script
$scriptPath = Join-Path $PSScriptRoot 'Test.ps1'

Write-Output "executing: $scriptPath"

# Execute the powershell script
& $scriptPath

