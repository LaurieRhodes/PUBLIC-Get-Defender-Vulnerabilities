param($context)

$DebugPreference = 'Continue'
    
Write-Debug "Orchestrator function started at: $(Get-Date)"


<#
  Task 1.   Get Machine List
#>


write-debug "Starting Invoke-DurableActivity -FunctionName Get-Machines"
$GetMachineTask = Invoke-DurableActivity -FunctionName "Get-Machines" 
$DecodedText = [System.Text.Encoding]::ASCII.GetString([System.Convert]::FromBase64String($GetMachineTask))
$machineRecordCollection = ConvertFrom-Json -inputobject $DecodedText
write-debug "Invoke-DurableActivity Get-Machines complete"


# Task 2: Get Vulnerabilities from Machines (Parallel Processing)
$ParallelOutput = @()

$ParallelTasks = 

foreach ($machineRecord in $machineRecordCollection) {
    $params = @{
        data = $machineRecord
    }
        
    $EncodedText = [Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes((ConvertTo-Json -InputObject $params -Depth 10)))
    $output = Invoke-DurableActivity -FunctionName "Get-Vulnerabilities" -Input $EncodedText
}
