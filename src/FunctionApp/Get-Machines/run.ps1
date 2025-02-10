param($params)

$DebugPreference = 'Continue'

write-debug "(Get-Machines) ClientID = $($env:CLIENTID)"

$output = @()


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

Start-Sleep -Seconds 2 # account for Microsoft's API limit

    # Check if there is a next page
    $apiUrl = $response.'@odata.nextLink'

} while ($apiUrl -ne $null)


<#

 Return machineRecordCollection as a base64 encoded string
 
#>

 $Text =  $machineRecordCollection  | convertto-json
 
 $Bytes = [System.Text.Encoding]::ASCII.GetBytes($Text)
 $EncodedText =[Convert]::ToBase64String($Bytes)

 $EncodedText 