[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$WorkspaceRoot
)

$ErrorActionPreference = "Stop"
$SourceRepository = "https://github.com/microsoft/aibast-agents-library.git"
$SourceRef = "refs/pull/201/head"
$SourceCommit = "8a430919d269febd6cd67570059842c446fc6252"
$BootstrapRoot = Split-Path $PSScriptRoot -Parent
$WorkspaceRoot = [IO.Path]::GetFullPath($WorkspaceRoot)
$BrainstemRoot = Join-Path $WorkspaceRoot "rapp_brainstem"
$AddonInstaller = Join-Path $PSScriptRoot "install-addon.ps1"
$Manifest = Join-Path $BootstrapRoot "brainstem-addon.json"

function Invoke-Git {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments)
    & git @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Git failed: git $($Arguments -join ' ')"
    }
}

function Test-ExpectedRepository {
    if (-not (Test-Path -LiteralPath (Join-Path $WorkspaceRoot ".git"))) {
        return $false
    }
    $remote = (& git -C $WorkspaceRoot remote get-url origin 2>$null |
        Select-Object -First 1)
    return [string]$remote -eq $SourceRepository
}

function Ensure-LocalExcludes {
    $excludePath = Join-Path $WorkspaceRoot ".git\info\exclude"
    $excludeEntries = @(
        "/rapp_brainstem/.brainstem_data/",
        "/rapp_brainstem/agents/experimental/scout/addon.json",
        "/rapp_brainstem/agents/experimental/scout/COLLABORATION.md",
        "/rapp_brainstem/agents/experimental/scout/candidates/",
        "/rapp_brainstem/agents/experimental/scout/evidence/",
        "/rapp_brainstem/agents/experimental/scout/handoffs/"
    )
    $existing = if (Test-Path -LiteralPath $excludePath) {
        @(Get-Content -LiteralPath $excludePath)
    } else {
        @()
    }
    foreach ($entry in $excludeEntries) {
        if ($existing -notcontains $entry) {
            Add-Content -LiteralPath $excludePath -Value $entry -Encoding UTF8
        }
    }
}

if (-not (Test-Path -LiteralPath $WorkspaceRoot)) {
    New-Item -ItemType Directory -Path $WorkspaceRoot -Force | Out-Null
}

$entries = @(Get-ChildItem -LiteralPath $WorkspaceRoot -Force)
if ($entries.Count -eq 0) {
    Invoke-Git init $WorkspaceRoot
    Invoke-Git -C $WorkspaceRoot remote add origin $SourceRepository
} elseif (-not (Test-ExpectedRepository)) {
    throw "The target is not empty and is not the expected Brainstem workspace."
} else {
    Ensure-LocalExcludes
    $dirty = & git -C $WorkspaceRoot status --porcelain
    if ($dirty) {
        throw "The existing Brainstem workspace has local changes; update refused."
    }
}

Invoke-Git -C $WorkspaceRoot config core.autocrlf false
Invoke-Git -C $WorkspaceRoot sparse-checkout init --no-cone
Invoke-Git -C $WorkspaceRoot sparse-checkout set /rapp_brainstem/
Ensure-LocalExcludes

Invoke-Git -C $WorkspaceRoot fetch `
    --filter=blob:none `
    --depth 1 `
    origin `
    $SourceRef
$fetched = (& git -C $WorkspaceRoot rev-parse FETCH_HEAD).Trim()
if ($fetched -ne $SourceCommit) {
    throw "The published Scout-native source ref moved unexpectedly."
}
Invoke-Git -C $WorkspaceRoot checkout --detach $SourceCommit

$manifestObject = Get-Content -LiteralPath $Manifest -Raw | ConvertFrom-Json
foreach ($artifact in $manifestObject.compatibility.verified_artifacts) {
    $path = Join-Path $WorkspaceRoot ($artifact.path.Replace("/", "\"))
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Verified workspace artifact is missing: $($artifact.path)"
    }
    $actual = (Get-FileHash -LiteralPath $path -Algorithm SHA256).
        Hash.
        ToLowerInvariant()
    if ($actual -ne $artifact.sha256) {
        throw "Verified workspace artifact changed: $($artifact.path)"
    }
}

& $AddonInstaller `
    -AddonRoot $BootstrapRoot `
    -BrainstemRoot $BrainstemRoot
if ($LASTEXITCODE -ne 0) {
    throw "The Scout-native add-on could not be installed."
}
foreach ($artifact in $manifestObject.payload.files) {
    $managedRelative = ([string]$artifact.path).Replace("\", "/")
    $managedPath = "rapp_brainstem/agents/experimental/scout/$managedRelative"
    $tracked = & git -C $WorkspaceRoot ls-files -- $managedPath
    if ($tracked) {
        Invoke-Git -C $WorkspaceRoot update-index --assume-unchanged $managedPath
    }
}

[ordered]@{
    status = "ready"
    schema = "rapp-brainstem-addon/1"
    addon = $manifestObject.name
    workspace = $WorkspaceRoot
    brainstem = $BrainstemRoot
    preview = (Join-Path $BrainstemRoot "index.html")
    controller = (
        Join-Path $BrainstemRoot `
            "agents\experimental\scout\brainstem-workspace.ps1"
    )
    collaboration_root = (
        Join-Path $BrainstemRoot "agents\experimental\scout"
    )
    source_commit = $SourceCommit
    grail_id = $manifestObject.compatibility.grail.id
    verified = $true
} | ConvertTo-Json
