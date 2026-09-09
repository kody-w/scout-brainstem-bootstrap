[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$AddonRoot,

    [Parameter(Mandatory = $true)]
    [string]$BrainstemRoot
)

$ErrorActionPreference = "Stop"
$AddonRoot = [IO.Path]::GetFullPath($AddonRoot)
$BrainstemRoot = [IO.Path]::GetFullPath($BrainstemRoot)
$ManifestPath = Join-Path $AddonRoot "brainstem-addon.json"
$PayloadRoot = Join-Path $AddonRoot "addon"

function Assert-NoLinkedPath([string]$Path, [string]$Boundary) {
    $currentPath = [IO.Path]::GetFullPath($Path)
    $boundaryPath = [IO.Path]::GetFullPath($Boundary).TrimEnd("\")
    if (
        $currentPath -ne $boundaryPath -and
        -not $currentPath.StartsWith(
            $boundaryPath + "\",
            [StringComparison]::OrdinalIgnoreCase
        )
    ) {
        throw "Add-on destination escapes Brainstem."
    }
    while (-not (Test-Path -LiteralPath $currentPath)) {
        $parent = Split-Path $currentPath -Parent
        if (-not $parent -or $parent.Length -lt $boundaryPath.Length) {
            throw "Add-on destination has no safe ancestor."
        }
        $currentPath = $parent
    }
    while ($currentPath.Length -ge $boundaryPath.Length) {
        $current = Get-Item -LiteralPath $currentPath -Force
        if ($current.LinkType) {
            throw "Add-on destination cannot traverse a linked path."
        }
        if ($current.FullName.TrimEnd("\") -eq $boundaryPath) {
            return
        }
        $parent = Split-Path $current.FullName -Parent
        if (-not $parent -or $parent.Length -lt $boundaryPath.Length) {
            break
        }
        $currentPath = $parent
    }
    throw "Add-on destination did not resolve through Brainstem."
}

if (-not (Test-Path -LiteralPath $ManifestPath -PathType Leaf)) {
    throw "brainstem-addon.json is missing."
}
if (-not (Test-Path -LiteralPath $PayloadRoot -PathType Container)) {
    throw "The add-on payload directory is missing."
}
if (-not (Test-Path -LiteralPath (Join-Path $BrainstemRoot "brainstem.py"))) {
    throw "The target is not a Brainstem runtime."
}

$manifest = Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json
if ($manifest.schema -ne "rapp-brainstem-addon/1") {
    throw "Unsupported Brainstem add-on schema."
}
if ($manifest.protocol.spec -ne "rapp/1") {
    throw "The add-on does not declare RAPP/1."
}
if ($manifest.wire.transport -ne "POST /chat") {
    throw "The add-on attempts to redefine the RAPP/1 wire."
}
if (
    [string]::IsNullOrWhiteSpace($manifest.install.root) -or
    $manifest.install.root.Contains("..") -or
    $manifest.install.root.Contains(":") -or
    $manifest.install.root.StartsWith("/") -or
    $manifest.install.root.StartsWith("\")
) {
    throw "The add-on install root is unsafe."
}

$installRoot = [IO.Path]::GetFullPath(
    (Join-Path $BrainstemRoot $manifest.install.root)
)
if (
    $installRoot -ne $BrainstemRoot -and
    -not $installRoot.StartsWith(
        $BrainstemRoot.TrimEnd("\") + "\",
        [StringComparison]::OrdinalIgnoreCase
    )
) {
    throw "The add-on install root escapes Brainstem."
}
Assert-NoLinkedPath (Split-Path $installRoot -Parent) $BrainstemRoot
New-Item -ItemType Directory -Path $installRoot -Force | Out-Null
Assert-NoLinkedPath $installRoot $BrainstemRoot

$seen = @{}
foreach ($artifact in $manifest.payload.files) {
    $relative = [string]$artifact.path
    if (
        [string]::IsNullOrWhiteSpace($relative) -or
        $relative.Contains("..") -or
        $relative.Contains(":") -or
        $relative.StartsWith("/") -or
        $relative.StartsWith("\")
    ) {
        throw "Unsafe add-on payload path: $relative"
    }
    $key = $relative.Replace("\", "/").ToLowerInvariant()
    if ($seen.ContainsKey($key)) {
        throw "Duplicate add-on payload path: $relative"
    }
    $seen[$key] = $true

    $source = [IO.Path]::GetFullPath(
        (Join-Path $PayloadRoot $relative.Replace("/", "\"))
    )
    $destination = [IO.Path]::GetFullPath(
        (Join-Path $installRoot $relative.Replace("/", "\"))
    )
    if (
        -not $source.StartsWith(
            $PayloadRoot.TrimEnd("\") + "\",
            [StringComparison]::OrdinalIgnoreCase
        ) -or
        -not $destination.StartsWith(
            $installRoot.TrimEnd("\") + "\",
            [StringComparison]::OrdinalIgnoreCase
        )
    ) {
        throw "Add-on payload path escaped its declared root."
    }
    if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {
        throw "Add-on payload file is missing: $relative"
    }
    if ((Get-Item -LiteralPath $source).Length -ne [int64]$artifact.bytes) {
        throw "Add-on payload length mismatch: $relative"
    }
    if ((Get-Item -LiteralPath $source -Force).LinkType) {
        throw "Add-on payload cannot contain symbolic links."
    }
    Assert-NoLinkedPath (Split-Path $destination -Parent) $BrainstemRoot
    if (
        (Test-Path -LiteralPath $destination) -and
        (Get-Item -LiteralPath $destination -Force).LinkType
    ) {
        throw "Add-on destination cannot be a symbolic link."
    }
    $actual = (Get-FileHash -LiteralPath $source -Algorithm SHA256).
        Hash.
        ToLowerInvariant()
    if ($actual -ne $artifact.sha256) {
        throw "Add-on payload hash mismatch: $relative"
    }
    New-Item `
        -ItemType Directory `
        -Path (Split-Path $destination -Parent) `
        -Force |
        Out-Null
    Assert-NoLinkedPath (Split-Path $destination -Parent) $BrainstemRoot
    Copy-Item -LiteralPath $source -Destination $destination -Force
}

Copy-Item `
    -LiteralPath $ManifestPath `
    -Destination (Join-Path $installRoot "addon.json") `
    -Force
foreach ($directory in $manifest.collaboration.local_directories) {
    if (
        [string]$directory -notmatch "^[a-z][a-z0-9-]{0,63}$"
    ) {
        throw "Unsafe collaboration directory: $directory"
    }
    New-Item `
        -ItemType Directory `
        -Path (Join-Path $installRoot $directory) `
        -Force |
        Out-Null
}

[ordered]@{
    status = "installed"
    schema = $manifest.schema
    name = $manifest.name
    version = $manifest.version
    install_root = $installRoot
    skill = (Join-Path $installRoot $manifest.install.skill)
    entrypoint = (Join-Path $installRoot $manifest.install.entrypoint)
} | ConvertTo-Json
