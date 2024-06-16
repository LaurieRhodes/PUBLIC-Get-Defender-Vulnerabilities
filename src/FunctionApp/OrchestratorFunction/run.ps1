param($context)
<#
Orchestrator

#>


<#
  Variables
#>

$EventHubNameSpace = '<your-event-hub-namespace>'
$EventHubName      = '<your-event-hub-name>'
$ClientId          = '<your-Managed-Identity-ClientId>'



<#
  Initialise Modules
#>

# Get the path to the current script directory
$scriptDirectory = Split-Path -Parent $PsScriptRoot

# Define the relative path to the modules directory
$modulesPath = Join-Path $scriptDirectory '\modules'

# Resolve the full path to the modules directory
$resolvedModulesPath = (Get-Item $modulesPath).FullName


# Recursively import all PowerShell modules (.psm1 files) in the modules directory
Get-ChildItem -Path $resolvedModulesPath -Filter *.psm1 -Recurse | ForEach-Object {
    Write-Information "Importing module: $_"
    Import-Module "$_"
}


<#
  Task 1.   Get Machine List
#>

$params = @{
    ClientId          = $ClientId
}

$Text =  $params  | convertto-json
$Bytes = [System.Text.Encoding]::ASCII.GetBytes($Text)
$EncodedText =[Convert]::ToBase64String($Bytes)



write-information "Starting Invoke-DurableActivity -FunctionName Get-Machines"  
$GetMachineTask = Invoke-DurableActivity -FunctionName "Get-Machines" -Input $EncodedText 
$DecodedText = [System.Text.Encoding]::ASCII.GetString([System.Convert]::FromBase64String($GetMachineTask))
$machineRecordCollection = ConvertFrom-Json -inputobject $DecodedText
write-information "Invoke-DurableActivity Get-Machines complete"  
write-debug "Invoke-DurableActivity DecodedText = `n $($DecodedText)"  


<#
  Task 2.   Get Vulnerabilities from Machines
#>


$params = @{
    ClientId          = $ClientId
    data              = $GetMachineTask
}

$Text =  $params  | convertto-json
$Bytes = [System.Text.Encoding]::ASCII.GetBytes($Text)
$EncodedText =[Convert]::ToBase64String($Bytes)

$GetVulnerabilitiesTask = Invoke-DurableActivity -FunctionName "Get-Vulnerabilities" -Input $EncodedText 
$DecodedText = [System.Text.Encoding]::ASCII.GetString([System.Convert]::FromBase64String($GetVulnerabilitiesTask))
$VulnerabilityCollection = ConvertFrom-Json -inputobject $DecodedText
write-information "Invoke-DurableActivity Get-Vulnerabilities complete"  
write-debug "Invoke-DurableActivity Get-Vulnerabilities DecodedText = `n $($DecodedText)"  


<#
  Task 3.   Send Vulnerabilities to Eventhub
#>

 
$params = @{
    EventHubNameSpace = $EventHubNameSpace
    EventHubName      = $EventHubName
    ClientId          = $ClientId
    data              = $GetVulnerabilitiesTask
}

 $Text =  $params  | convertto-json
 $Bytes = [System.Text.Encoding]::ASCII.GetBytes($Text)
 $EncodedText =[Convert]::ToBase64String($Bytes)

$SendtoEventhubTask = Invoke-DurableActivity -FunctionName "Send-toEventHub" -Input $EncodedText
write-information "Invoke-DurableActivity Send-toEventHub complete" 


