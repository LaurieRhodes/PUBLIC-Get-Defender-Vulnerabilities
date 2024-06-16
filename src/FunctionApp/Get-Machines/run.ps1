param($params)
<#
Get-Machines


#>



<#
  Get Parameters
#>

$DecodedText = [System.Text.Encoding]::ASCII.GetString([System.Convert]::FromBase64String($params))
write-debug "(Get-Machines) run with decoded parameters: `n $($DecodedText)"
$params = ConvertFrom-Json -inputobject $DecodedText

$ClientId          = $params.ClientId




$output = @()


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

<#

 Properties received from Orchestrator
 Will determine the vulnerabilities being queried for a machine
 
#>

$resourceURL = "https://api.securitycenter.microsoft.com/" 

$Token = Get-AzureADToken -resource $resourceURL -clientId $ClientId 

$authHeader = @{
    'Authorization' = "Bearer $($token)"
}


$machineRecordCollection = @()

# Initial URL to retrieve a list of all active machines
$apiUrl = "https://au.api.security.microsoft.com/api/machines?`$filter=healthStatus+eq+'Active'"

do {
    # Retrieve the current page
    write-information "Retrieving Machine List $($apiUrl)"
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