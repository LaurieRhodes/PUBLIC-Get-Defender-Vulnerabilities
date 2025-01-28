param($params)
<#

Get-Vulnerabilities

#>

$DebugPreference = 'Continue'
    
<#
  Initialise Modules
#>


<#
  Get Parameters
#>


$DecodedText = [System.Text.Encoding]::ASCII.GetString([System.Convert]::FromBase64String($params))

$params = ConvertFrom-Json -inputobject $DecodedText

$ClientId          = $env:CLIENTID
$data              = $params.data 
$EventHubName      = $env:EVENTHUBNAME
$EventHubNameSpace = $env:EVENTHUBNAMESPACE


write-debug "ClientId = $($ClientId )"

$machineRecordCollection = $params.data 

$output = @()

$vulnerabilityCollection = @()

class DeviceTvmSoftwareVulnerabilities {
    [String]$DeviceId
    [String]$DeviceName
    [String]$OSPlatform
    [String]$OSArchitecture
    [String]$SoftwareVendor
    [String]$SoftwareName
    [String]$SoftwareVersion
    [String]$CveId
    [String]$VulnerabilitySeverityLevel
    [String]$RecommendedSecurityUpdate
    [String]$RecommendedSecurityUpdateId
    [String]$CveTags
    [String]$CveMitigationStatus
}

function Get-MachineVulnerabilities {
    param (
        [string]$DeviceId,
        [string]$DeviceName,
        [string]$OSPlatform,
        [string]$OSArchitecture
    )

$resourceURL = "https://api.securitycenter.microsoft.com/" 

$Token = Get-AzureADToken -resource $resourceURL -clientId $ClientId

$authHeader = @{
    'Authorization' = "Bearer $($token)"
}

    $OutputArray=@()

    $apiUrl = "https://au.api.security.microsoft.com/api/vulnerabilities/machinesVulnerabilities?`$filter=machineId+eq+'$($DeviceId)'"

    do {
        # Retrieve the current page
        write-debug "Retrieving vulnerability List $($apiUrl)"
        # Disable Keep Alive to prevent long running hang
        $response = Invoke-RestMethod -Uri $apiUrl -Headers $authHeader -Method Get -DisableKeepAlive
        write-debug "vulnerability List Received"

        Start-Sleep -Seconds 5 # account for API request limitations

        foreach($vulnerability in $($response.value)){

            $tmpobject = [DeviceTvmSoftwareVulnerabilities]::New()

            $tmpobject.DeviceId = $DeviceId
            $tmpobject.DeviceName = $DeviceName
            $tmpobject.OSPlatform = $OSPlatform
            $tmpobject.OSArchitecture = $OSArchitecture
            $tmpobject.SoftwareVendor = $vulnerability.productVendor
            $tmpobject.SoftwareName = $vulnerability.productName
            $tmpobject.SoftwareVersion = $vulnerability.productVersion
            $tmpobject.CveId = $vulnerability.cveId
            $tmpobject.VulnerabilitySeverityLevel = $vulnerability.severity
            $tmpobject.RecommendedSecurityUpdate = ''
            $tmpobject.RecommendedSecurityUpdateId = $vulnerability.fixingKbId
            $tmpobject.CveTags = ''
            $tmpobject.CveMitigationStatus = ''

            $OutputArray += $tmpobject

        }

        # Check if there is a next page
        $apiUrl = $response.'@odata.nextLink'
            
        # Release the response object
        $response = $null
    
    } while ($apiUrl -ne $null)

  return $OutputArray


}


$EventHubresourceURL = "https://eventhubs.azure.net" # The resource name to request a token for Event Hubs
$EventHubURI = "https://$($EventHubNameSpace).servicebus.windows.net/$($EventHubName)/messages?timeout=60"

$EventHubtoken = Get-AzureADToken -resource $EventHubresourceURL -clientId $ClientId

$EventHubheader = @{
    "Authorization" = "Bearer $($EventHubtoken)"
    "Content-Type" = "application/json"
}


  # Process each machine record in the current page
  foreach ($machinerecord in $machineRecordCollection) {

      $DeviceId  = $machinerecord.DeviceId 
      $DeviceName = $machinerecord.DeviceName 
      $OSPlatform = $machinerecord.OSPlatform
      $OSArchitecture = $machinerecord.OSArchitecture

     $vulnerabilities =  Get-MachineVulnerabilities -DeviceId $DeviceId -DeviceName $DeviceName -OSPlatform $OSPlatform -OSArchitecture $OSArchitecture 

     foreach ($vulnerability in $vulnerabilities){
        $vulnerabilityCollection += $vulnerability
        Invoke-RestMethod -Uri $EventHubURI  -Method POST -Headers $EventHubheader -Body $(Convertto-json -inputobject $vulnerability) -Verbose -SkipHeaderValidation  
        write-debug "Event Hub data sent"
     } # End foreach Vulnerability
                
 }  # End Vulnerabilities    
 
 