param($context)

# Environment variables
#$EventHubName      = $env:EVENTHUB
#$EventHubNameSpace = $env:EVENTHUBNAMESPACE
#$ClientId          = $env:CLIENTID

$DebugPreference = 'Continue'
    
Write-Debug "Orchestrator function started at: $(Get-Date)"
#Write-Debug "Environment Variables: EventHub=$EventHubName, Namespace=$EventHubNameSpace, ClientID=$ClientId"


<#
  Task 1.   Get Machine List
#>

#$params = @{
#    ClientId          = $ClientId
#}

#$Text =  $params  | convertto-json
#$Bytes = [System.Text.Encoding]::ASCII.GetBytes($Text)
#$EncodedText =[Convert]::ToBase64String($Bytes)


write-debug "Starting Invoke-DurableActivity -FunctionName Get-Machines"
$GetMachineTask = Invoke-DurableActivity -FunctionName "Get-Machines" #-Input $EncodedText 
$DecodedText = [System.Text.Encoding]::ASCII.GetString([System.Convert]::FromBase64String($GetMachineTask))
$machineRecordCollection = ConvertFrom-Json -inputobject $DecodedText
write-debug "Invoke-DurableActivity Get-Machines complete"


# Task 2: Get Vulnerabilities from Machines (Parallel Processing)
$ParallelOutput = @()

$ParallelTasks = 

foreach ($machineRecord in $machineRecordCollection) {
    $params = @{
#        ClientId = $ClientId
        data = $machineRecord
    }
        
    $EncodedText = [Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes((ConvertTo-Json -InputObject $params -Depth 10)))
    $output = Invoke-DurableActivity -FunctionName "Get-Vulnerabilities" -Input $EncodedText
}
