param($myTimer)

Write-Output "Timer trigger function executed at: $(Get-Date)"

# Start the orchestrator function
try {
    $instanceId = Start-DurableOrchestration -FunctionName "OrchestratorFunction"
    Write-Output "Started orchestration with ID = $instanceId"
} catch {
    Write-Error "Failed to start orchestration: $_"
}
