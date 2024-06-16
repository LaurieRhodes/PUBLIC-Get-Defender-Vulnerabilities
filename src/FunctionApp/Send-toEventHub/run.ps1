param($params)
<#
  Send-toEventhub

#>


<#
  Get Parameters
#>


$DecodedText = [System.Text.Encoding]::ASCII.GetString([System.Convert]::FromBase64String($params))
write-debug "(Send-toEventHub) run with decoded parameters: `n $($DecodedText)"
$params = ConvertFrom-Json -inputobject $DecodedText

$EventHubNameSpace = $params.EventHubNameSpace
$EventHubName      = $params.EventHubName
$ClientId          = $params.ClientId
$data              = $params.data 

write-information "EventHubNameSpace = $($EventHubNameSpace)"
write-information "EventHubName  = $($EventHubName  )"
write-information "ClientId = $($ClientId )"
write-debug "data = $($data )"

# Decode the Vulnerabilities array
$DecodedText = [System.Text.Encoding]::ASCII.GetString([System.Convert]::FromBase64String($data))
$VulnerabilityCollection = ConvertFrom-Json -inputobject $DecodedText



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


# Set Event Hub URI
#$URI = "https://$($EventHubNameSpace).servicebus.windows.net/$($EventHubName)/messages?timeout=60&api-version=2014-01"    
$URI = "https://$($EventHubNameSpace).servicebus.windows.net/$($EventHubName)/messages?timeout=60"

<#
  Get Token for Event Hub
#>


$resourceURL = "https://eventhubs.azure.net" #The resource name to request a token for Event Hubs

$token = Get-AzureADToken -resource $resourceURL -clientId $ClientId
write-information "servicebus token = $($token )"

 # Iterate through each record
foreach ($record in $VulnerabilityCollection) {

$headers = @{
    "Authorization" = "Bearer $($token)"
    "Content-Type" = "application/json"
}

# Execute the Azure REST API
$method = "POST"

Invoke-RestMethod -Uri $URI  -Method $method -Headers $headers -Body $(Convertto-json -inputobject $record) -Verbose -SkipHeaderValidation                
                
}









