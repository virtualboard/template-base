[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Candidate
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($env:OS -ne 'Windows_NT') {
    throw 'the PowerShell installer contract requires native Windows'
}

$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$installer = Join-Path $root 'scripts\install-vb-cli.ps1'
$candidatePath = [IO.Path]::GetFullPath($Candidate)
if (-not [IO.File]::Exists($candidatePath)) {
    throw "candidate binary not found: $candidatePath"
}

$selectedTag = [IO.File]::ReadAllText((Join-Path $root '.vb-version')).Trim()
$architecture = if ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64') { 'arm64' } else { 'amd64' }
$assetName = "vb-windows-$architecture.exe"
$shellName = if ($PSVersionTable.PSEdition -eq 'Desktop') { 'powershell.exe' } else { 'pwsh.exe' }
$shell = (Get-Command $shellName -ErrorAction Stop).Source
$testRoot = Join-Path ([IO.Path]::GetTempPath()) ("vb-powershell-installer-test-{0}" -f [guid]::NewGuid().ToString('N'))
$null = New-Item -ItemType Directory -Path $testRoot
$testsRun = 0

function Fail-Test {
    param([Parameter(Mandatory = $true)][string]$Message)
    throw "not ok - $Message"
}

function Pass-Test {
    param([Parameter(Mandatory = $true)][string]$Message)
    $script:testsRun++
    Write-Host "ok $script:testsRun - $Message"
}

function New-TestCase {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [string]$Version = $selectedTag
    )

    $caseRoot = Join-Path $testRoot $Name
    $source = Join-Path $caseRoot 'source'
    $destination = Join-Path $caseRoot 'destination'
    $null = New-Item -ItemType Directory -Path $source
    $null = New-Item -ItemType Directory -Path $destination
    $versionFile = Join-Path $caseRoot '.vb-version'
    [IO.File]::WriteAllText($versionFile, "$Version$([Environment]::NewLine)")
    $asset = Join-Path $source $assetName
    [IO.File]::Copy($candidatePath, $asset, $false)
    $hash = (Get-FileHash -LiteralPath $asset -Algorithm SHA256).Hash.ToLowerInvariant()
    [IO.File]::WriteAllText(
        (Join-Path $source 'checksums.txt'),
        "$hash  $assetName$([Environment]::NewLine)"
    )
    $downloadLog = Join-Path $caseRoot 'downloads.log'
    [IO.File]::WriteAllText($downloadLog, '')
    return [pscustomobject]@{
        Root = $caseRoot
        Source = $source
        Destination = $destination
        VersionFile = $versionFile
        Asset = $asset
        Checksums = Join-Path $source 'checksums.txt'
        DownloadLog = $downloadLog
        Target = Join-Path $destination 'vb.exe'
    }
}

function Invoke-TestInstaller {
    param(
        [Parameter(Mandatory = $true)]$Case,
        [string[]]$InstallerArguments,
        [hashtable]$ExtraEnvironment = @{}
    )

    $names = @(
        'VB_VERSION_FILE',
        'VB_INSTALLER_TESTING',
        'VB_INSTALLER_TEST_SOURCE_DIR',
        'VB_INSTALLER_TEST_DOWNLOAD_LOG',
        'VB_INSTALLER_TEST_FAIL_ACTIVATION',
        'VB_BINARY_MAX_BYTES',
        'VB_CHECKSUMS_MAX_BYTES'
    )
    $saved = @{}
    foreach ($name in $names) {
        $saved[$name] = [Environment]::GetEnvironmentVariable($name)
        [Environment]::SetEnvironmentVariable($name, $null)
    }
    try {
        $env:VB_VERSION_FILE = $Case.VersionFile
        $env:VB_INSTALLER_TESTING = '1'
        $env:VB_INSTALLER_TEST_SOURCE_DIR = $Case.Source
        $env:VB_INSTALLER_TEST_DOWNLOAD_LOG = $Case.DownloadLog
        foreach ($entry in $ExtraEnvironment.GetEnumerator()) {
            [Environment]::SetEnvironmentVariable([string]$entry.Key, [string]$entry.Value)
        }
        $output = & $shell -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $installer @InstallerArguments 2>&1
        return [pscustomobject]@{
            ExitCode = $LASTEXITCODE
            Output = ($output | Out-String)
        }
    }
    finally {
        foreach ($name in $names) {
            [Environment]::SetEnvironmentVariable($name, $saved[$name])
        }
    }
}

function Copy-MismatchedBinary {
    param([Parameter(Mandatory = $true)][string]$Destination)
    [IO.File]::Copy((Join-Path $env:WINDIR 'System32\where.exe'), $Destination, $false)
}

try {
    $case = New-TestCase -Name 'exact-install'
    $result = Invoke-TestInstaller -Case $case -InstallerArguments @('-EnsureLatest', '-InstallDirectory', $case.Destination)
    if ($result.ExitCode -ne 0) { Fail-Test "exact install failed: $($result.Output)" }
    $reported = (& $case.Target version | Out-String).Trim()
    if ($reported -ne $selectedTag) { Fail-Test "installed candidate reported '$reported'" }
    Pass-Test 'installs the exact selected Windows binary'

    $case = New-TestCase -Name 'exact-manifest-verified'
    [IO.File]::Copy($candidatePath, $case.Target, $false)
    $result = Invoke-TestInstaller -Case $case -InstallerArguments @('-EnsureLatest', '-InstallDirectory', $case.Destination)
    if ($result.ExitCode -ne 0) { Fail-Test "manifest-verified no-op failed: $($result.Output)" }
    $downloads = @(Get-Content -LiteralPath $case.DownloadLog | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    if ($downloads.Count -ne 1 -or $downloads[0] -notmatch '/checksums\.txt$') {
        Fail-Test 'exact destination was not authenticated solely through checksums.txt'
    }
    Pass-Test 'exact destination is accepted only after manifest verification'

    $case = New-TestCase -Name 'checksum-failure'
    Copy-MismatchedBinary -Destination $case.Target
    $before = (Get-FileHash -LiteralPath $case.Target -Algorithm SHA256).Hash
    [IO.File]::WriteAllText($case.Checksums, "$('0' * 64)  $assetName$([Environment]::NewLine)")
    $result = Invoke-TestInstaller -Case $case -InstallerArguments @('-EnsureLatest', '-InstallDirectory', $case.Destination)
    if ($result.ExitCode -eq 0) { Fail-Test 'checksum mismatch was accepted' }
    $after = (Get-FileHash -LiteralPath $case.Target -Algorithm SHA256).Hash
    if ($after -cne $before) { Fail-Test 'checksum failure changed the existing binary' }
    Pass-Test 'checksum mismatch fails closed without replacing an existing binary'

    $case = New-TestCase -Name 'duplicate-checksum'
    $line = [IO.File]::ReadAllText($case.Checksums)
    [IO.File]::WriteAllText($case.Checksums, "$line$line")
    $result = Invoke-TestInstaller -Case $case -InstallerArguments @('-EnsureLatest', '-InstallDirectory', $case.Destination)
    if ($result.ExitCode -eq 0) { Fail-Test 'duplicate checksum entries were accepted' }
    if ([IO.File]::Exists($case.Target)) { Fail-Test 'duplicate checksum installed a binary' }
    Pass-Test 'requires exactly one checksum-manifest entry'

    $case = New-TestCase -Name 'oversized-download'
    Copy-MismatchedBinary -Destination $case.Target
    $before = (Get-FileHash -LiteralPath $case.Target -Algorithm SHA256).Hash
    $result = Invoke-TestInstaller -Case $case `
        -InstallerArguments @('-EnsureLatest', '-InstallDirectory', $case.Destination) `
        -ExtraEnvironment @{ VB_BINARY_MAX_BYTES = '1' }
    if ($result.ExitCode -eq 0) { Fail-Test 'oversized binary was accepted' }
    $after = (Get-FileHash -LiteralPath $case.Target -Algorithm SHA256).Hash
    if ($after -cne $before) { Fail-Test 'oversized download changed the existing binary' }
    Pass-Test 'enforces the binary download limit before activation'

    $case = New-TestCase -Name 'version-mismatch' -Version 'v99.98.97'
    Copy-MismatchedBinary -Destination $case.Target
    $before = (Get-FileHash -LiteralPath $case.Target -Algorithm SHA256).Hash
    $result = Invoke-TestInstaller -Case $case -InstallerArguments @('-EnsureLatest', '-InstallDirectory', $case.Destination)
    if ($result.ExitCode -eq 0) { Fail-Test 'downloaded version mismatch was accepted' }
    $after = (Get-FileHash -LiteralPath $case.Target -Algorithm SHA256).Hash
    if ($after -cne $before) { Fail-Test 'version mismatch changed the existing binary' }
    Pass-Test 'version-checks downloaded bytes before replacement'

    $case = New-TestCase -Name 'atomic-replacement'
    Copy-MismatchedBinary -Destination $case.Target
    $result = Invoke-TestInstaller -Case $case -InstallerArguments @('-EnsureLatest', '-InstallDirectory', $case.Destination)
    if ($result.ExitCode -ne 0) { Fail-Test "atomic replacement failed: $($result.Output)" }
    $reported = (& $case.Target version | Out-String).Trim()
    if ($reported -ne $selectedTag) { Fail-Test "replacement reported '$reported'" }
    Pass-Test 'atomically replaces an existing Windows executable'

    $case = New-TestCase -Name 'activation-failure'
    Copy-MismatchedBinary -Destination $case.Target
    $before = (Get-FileHash -LiteralPath $case.Target -Algorithm SHA256).Hash
    $result = Invoke-TestInstaller -Case $case `
        -InstallerArguments @('-EnsureLatest', '-InstallDirectory', $case.Destination) `
        -ExtraEnvironment @{ VB_INSTALLER_TEST_FAIL_ACTIVATION = '1' }
    if ($result.ExitCode -eq 0) { Fail-Test 'injected activation failure unexpectedly succeeded' }
    $after = (Get-FileHash -LiteralPath $case.Target -Algorithm SHA256).Hash
    if ($after -cne $before) { Fail-Test 'activation failure damaged the existing binary' }
    if (@(Get-ChildItem -LiteralPath $case.Destination -Filter '.vb.install.*').Count -ne 0) {
        Fail-Test 'activation failure left a staging file behind'
    }
    Pass-Test 'atomic activation failure preserves the existing binary and cleans staging'

    $case = New-TestCase -Name 'junction-ancestor'
    $escape = Join-Path $case.Root 'escape'
    $linked = Join-Path $case.Root 'linked'
    $null = New-Item -ItemType Directory -Path $escape
    $null = New-Item -ItemType Junction -Path $linked -Target $escape
    $destination = Join-Path $linked 'nested'
    $result = Invoke-TestInstaller -Case $case -InstallerArguments @('-EnsureLatest', '-InstallDirectory', $destination)
    if ($result.ExitCode -eq 0) { Fail-Test 'junction destination ancestor was accepted' }
    if ([IO.File]::Exists((Join-Path $escape 'nested\vb.exe'))) { Fail-Test 'installer escaped through a junction' }
    if ((Get-Item -LiteralPath $case.DownloadLog).Length -ne 0) { Fail-Test 'junction was rejected only after download' }
    Pass-Test 'rejects destination junctions before download'

    Write-Host "1..$testsRun"
    exit 0
}
finally {
    Remove-Item -LiteralPath $testRoot -Recurse -Force -ErrorAction SilentlyContinue
}
