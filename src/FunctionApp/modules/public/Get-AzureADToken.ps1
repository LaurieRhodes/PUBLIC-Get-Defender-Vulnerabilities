# Load the necessary .NET assemblies
Add-Type -AssemblyName 'System.Net.Http'
Add-Type -AssemblyName 'System.Net'
Add-Type -AssemblyName 'System.Net.Primitives'

function Get-AzureADToken {
    param (
        [string]$resource, # https://api.securitycenter.microsoft.com/"
        [string]$apiVersion = "2019-08-01",
        [string]$clientId  # The client ID of the user-assigned managed identity
    )



    try {
    

 
$resource = "?resource=$($resource)"
$clientId="&client_id=$($clientId)"

$url = $env:IDENTITY_ENDPOINT + $resource + $clientId + "&api-version=$($apiVersion)"
Write-Debug "url = $($url)"  

$Headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$Headers.Add("Metadata", "True")
$Headers.Add("X-IDENTITY-HEADER", $env:IDENTITY_HEADER)
$accessToken = Invoke-RestMethod -Uri $url -Method 'GET' -Headers $Headers

$token = $accessToken.access_token 

        
  return $token
        
    } catch {
    $errorMessage = $_.Exception.Message
    $errorDetails = $_.Exception.InnerException
    if ($errorDetails) {
        $errorMessage += " Inner Exception: $($errorDetails.Message)"
    }
    Write-Error -Message "(Get-AzureADToken) Failed: $errorMessage"
}
}




