param($myTimer)

Write-Output "Timer trigger function executed at: $(Get-Date)"

# Start the orchestrator function
$instanceId = Start-DurableOrchestration -FunctionName "OrchestratorFunction" -Input -Input @{ }

Write-Output "Started orchestration with ID = $instanceId"