[CmdletBinding()]
param(
    [switch]$DownloadPinnedInstaller,
    [string]$InstallerPath,
    [string]$PythonPath = "python"
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
if ($PSVersionTable.PSEdition -ne "Desktop" -or $PSVersionTable.PSVersion.Major -ne 5) {
    throw "Run this reproduction with Windows PowerShell 5.1 (powershell.exe)."
}
if ($DownloadPinnedInstaller -and $InstallerPath) {
    throw "Choose either -DownloadPinnedInstaller or -InstallerPath, not both."
}

$root = Split-Path $PSScriptRoot -Parent
$python = (Get-Command $PythonPath -CommandType Application -ErrorAction Stop).Source
$nativeFixture = Join-Path $root "tests\fixtures\native_stderr.py"
$scratch = Join-Path ([IO.Path]::GetTempPath()) (
    "scout-bootstrap-repro-" + [guid]::NewGuid().ToString("N")
)
New-Item -ItemType Directory -Path $scratch -ErrorAction Stop | Out-Null

try {
    $utf8 = New-Object System.Text.UTF8Encoding($false, $true)
    $fixturePath = Join-Path $scratch "utf8-no-bom.ps1"
    $fixtureSource = 'Write-Output "before ' + [char]0x2014 + ' after"' + "`n"
    [IO.File]::WriteAllText($fixturePath, $fixtureSource, $utf8)
    $sourcePath = $fixturePath
    $sourceKind = "offline-fixture"
    $pinVerified = $null

    if ($DownloadPinnedInstaller -or $InstallerPath) {
        $manifest = Get-Content -LiteralPath (Join-Path $root "bootstrap-manifest.json") -Raw |
            ConvertFrom-Json
        $artifact = $manifest.brainstem.installers.windows
        if ($DownloadPinnedInstaller) {
            $sourcePath = Join-Path $scratch "pinned-install.ps1"
            Invoke-WebRequest -UseBasicParsing -Uri $artifact.url `
                -OutFile $sourcePath -TimeoutSec 60
        } else {
            $sourcePath = (Resolve-Path -LiteralPath $InstallerPath).Path
        }
        $hash = (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($hash -ne $artifact.sha256) {
            throw "Pinned installer hash mismatch; refusing even the parse-only reproduction."
        }
        $sourceKind = "pinned-installer"
        $pinVerified = $true
    }

    $beforeHash = (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash
    $tokens = $null
    $defaultErrors = $null
    [Management.Automation.Language.Parser]::ParseFile(
        $sourcePath, [ref]$tokens, [ref]$defaultErrors
    ) | Out-Null
    $utf8Errors = $null
    [Management.Automation.Language.Parser]::ParseInput(
        [IO.File]::ReadAllText($sourcePath, $utf8),
        $sourcePath,
        [ref]$tokens,
        [ref]$utf8Errors
    ) | Out-Null
    if ($utf8Errors.Count) {
        throw "The source is not valid PowerShell when decoded explicitly as UTF-8."
    }

    # Make the ANSI failure reproducible even on hosts configured for UTF-8.
    $ansiFixtureErrors = $null
    $ansiFixture = [Text.Encoding]::GetEncoding(1252).GetString(
        [IO.File]::ReadAllBytes($fixturePath)
    )
    [Management.Automation.Language.Parser]::ParseInput(
        $ansiFixture, [ref]$tokens, [ref]$ansiFixtureErrors
    ) | Out-Null
    if (-not $ansiFixtureErrors.Count) {
        throw "The Windows-1252 fixture did not reproduce the encoding failure."
    }
    $afterHash = (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash
    if ($beforeHash -ne $afterHash) {
        throw "The inspected source changed during the reproduction."
    }

    $legacyErrorId = $null
    $legacyLog = Join-Path $scratch "merged.log"
    try {
        & $python $nativeFixture *> $legacyLog
    } catch {
        if ($_.FullyQualifiedErrorId -notlike "NativeCommandError*") {
            throw
        }
        $legacyErrorId = $_.FullyQualifiedErrorId
    }
    if (-not $legacyErrorId) {
        throw "Merged native stderr did not reproduce NativeCommandError."
    }

    $stdoutLog = Join-Path $scratch "native.out.log"
    $stderrLog = Join-Path $scratch "native.err.log"
    $process = Start-Process -FilePath $python `
        -ArgumentList ('"' + $nativeFixture + '"') `
        -RedirectStandardOutput $stdoutLog `
        -RedirectStandardError $stderrLog `
        -WindowStyle Hidden -Wait -PassThru
    try {
        $nativeExitCode = $process.ExitCode
    } finally {
        $process.Dispose()
    }
    $stdoutCaptured = (Get-Content -LiteralPath $stdoutLog -Raw).Trim() -eq "native fixture completed"
    $stderrCaptured = (Get-Content -LiteralPath $stderrLog -Raw).Trim() -eq "WARNING: harmless startup warning"
    if ($nativeExitCode -ne 0 -or -not $stdoutCaptured -or -not $stderrCaptured) {
        throw "Separate native streams did not preserve the successful process result and both logs."
    }

    $report = [ordered]@{
        schema = "scout-bootstrap-windows-repro/1"
        powershell_version = $PSVersionTable.PSVersion.ToString()
        default_code_page = [Text.Encoding]::Default.CodePage
        source = $sourceKind
        pin_verified = $pinVerified
        source_unchanged = $true
        installer_executed = $false
        runtime_touched = $false
        encoding = [ordered]@{
            default_parse_error_count = $defaultErrors.Count
            explicit_utf8_parse_error_count = $utf8Errors.Count
            windows_1252_fixture_error_count = $ansiFixtureErrors.Count
        }
        native_stderr = [ordered]@{
            merged_stream_error_id = $legacyErrorId
            separate_stream_exit_code = $nativeExitCode
            stdout_captured = $stdoutCaptured
            stderr_captured = $stderrCaptured
        }
    }
} finally {
    Remove-Item -LiteralPath $scratch -Recurse -Force -ErrorAction Stop
}

$report.temporary_files_removed = -not (Test-Path -LiteralPath $scratch)
$report | ConvertTo-Json -Depth 4
