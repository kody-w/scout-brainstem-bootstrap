[CmdletBinding()]
param(
    [switch]$RequireReady,
    [int]$TimeoutSeconds = 3
)

$ErrorActionPreference = "Stop"
$url = "http://127.0.0.1:7071/health"

try {
    $health = Invoke-RestMethod -Uri $url -TimeoutSec $TimeoutSeconds
} catch {
    [ordered]@{
        reachable = $false
        status = "offline"
        url = $url
        error = $_.Exception.Message
    } | ConvertTo-Json
    exit 1
}

$result = [ordered]@{
    reachable = $true
    status = [string]$health.status
    version = [string]$health.version
    model = [string]$health.model
    agents = @($health.agents)
    url = $url
}
$result | ConvertTo-Json -Depth 3

if ($RequireReady -and $health.status -ne "ok") {
    exit 2
}
if ($health.status -notin @("ok", "unauthenticated")) {
    exit 3
}
