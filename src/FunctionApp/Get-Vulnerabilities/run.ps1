param($params)
<#
Get-Vulnerabilities


#>


<#
  Get Parameters
#>


$DecodedText = [System.Text.Encoding]::ASCII.GetString([System.Convert]::FromBase64String($params))
write-debug "(Get-Vulnerabilities) run with decoded parameters: `n $($DecodedText)"
$params = ConvertFrom-Json -inputobject $DecodedText

$ClientId          = $params.ClientId
$data              = $params.data 

write-debug "ClientId = $($ClientId )"
write-debug "data = $($data )"

# Decode the Machines array
$DecodedText = [System.Text.Encoding]::ASCII.GetString([System.Convert]::FromBase64String($data))
$machineRecordCollection = ConvertFrom-Json -inputobject $DecodedText





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
        write-information "Retrieving vulnerability List $($apiUrl)"
        $response = Invoke-RestMethod -Uri $apiUrl -Headers $authHeader -Method Get
        write-information "vulnerability List Received"

        
        Start-Sleep -Seconds 2 #account for API limit
        
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

    } while ($apiUrl -ne $null)


  return $OutputArray
       

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
     }
      
  }


<#

 Return an Array of vulnerabilities
 
#>


 $Text =   convertto-json -inputobject $vulnerabilityCollection
 $Bytes = [System.Text.Encoding]::ASCII.GetBytes($Text)
 $EncodedText =[Convert]::ToBase64String($Bytes)

 $EncodedText 