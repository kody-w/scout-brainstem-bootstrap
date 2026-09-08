[CmdletBinding()]
param(
    [string]$DestinationRoot = (Join-Path $HOME ".scout\m-skills")
)

$ErrorActionPreference = "Stop"
$source = Join-Path (Split-Path $PSScriptRoot -Parent) "SKILL.md"
$destinationDir = Join-Path $DestinationRoot "scout-brainstem-bootstrap"
$destination = Join-Path $destinationDir "SKILL.md"

if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {
    throw "Repository SKILL.md was not found at $source"
}

New-Item -ItemType Directory -Path $destinationDir -Force | Out-Null
Copy-Item -LiteralPath $source -Destination $destination -Force

$sourceHash = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
$destinationHash = (Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash
if ($sourceHash -ne $destinationHash) {
    throw "Global skill verification failed: copied bytes differ."
}

[ordered]@{
    status = "installed"
    name = "scout-brainstem-bootstrap"
    path = $destination
    sha256 = $destinationHash.ToLowerInvariant()
} | ConvertTo-Json
