param($params)
<#
Get-Machines

#>


<#
  Initialise Modules
#>

$DebugPreference = 'Continue'

<#
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

#>

<#
  Get Parameters
#>

# Used to demonstrate parameter passing
#$DecodedText = [System.Text.Encoding]::ASCII.GetString([System.Convert]::FromBase64String($params))
#write-information "(Get-Machines) run with decoded parameters: `n $($DecodedText)"
#$params = ConvertFrom-Json -inputobject $DecodedText

#$ClientId          = $env:CLIENTID

write-debug "(Get-Machines) ClientID = $($env:CLIENTID)"


$output = @()

<#

 Properties received from Orchestrator
 Will determine the vulnerabilities being queried for a machine
 
#>

$resourceURL = "https://api.securitycenter.microsoft.com/"

$Token = Get-AzureADToken -resource $resourceURL -clientId $env:CLIENTID

$authHeader = @{
    'Authorization' = "Bearer $($token)"
}


$machineRecordCollection = @()

# Initial URL to retrieve a list of all active machines
$apiUrl = "https://au.api.security.microsoft.com/api/machines?`$filter=healthStatus+eq+'Active'"

do {
    # Retrieve the current page
    write-debug "Retrieving Machine List $($apiUrl)"
    $response = Invoke-RestMethod -Uri $apiUrl -Headers $authHeader -Method Get
    write-debug "Machine List Received"


    # Process each machine record in the current page
    foreach ($machinerecord in $response.value) {
        $tmpobj = [PSCustomObject]@{
            DeviceId       = $machinerecord.id
            DeviceName     = $machinerecord.computerDnsName
            OSPlatform     = $machinerecord.osPlatform
            OSArchitecture = $machinerecord.osArchitecture
        }
        $machineRecordCollection  += $tmpobj
    }

Start-Sleep -Seconds 2 #account for API limit

    # Check if there is a next page
    $apiUrl = $response.'@odata.nextLink'

} while ($apiUrl -ne $null)


<#

 Return machineRecordCollection
 
#>

 $Text =  $machineRecordCollection  | convertto-json
 
 $Bytes = [System.Text.Encoding]::ASCII.GetBytes($Text)
 $EncodedText =[Convert]::ToBase64String($Bytes)

 $EncodedText 