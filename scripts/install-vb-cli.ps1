# Install the exact VirtualBoard CLI release selected by .vb-version on
# Windows. Downloads are bounded and HTTPS-only; activation uses a flushed,
# same-directory staging file and an atomic replace.

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$InstallDirectory,

    [switch]$Local,
    [switch]$EnsureLatest,
    [switch]$Yes
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$downloadFile = $null
$checksumsFile = $null
$stageFile = $null

function Get-NormalizedVersion {
    param([Parameter(Mandatory = $true)][string]$Value)

    $match = [regex]::Match($Value.Trim(), '^[vV]?([0-9]+\.[0-9]+\.[0-9]+(?:[.-][0-9A-Za-z.-]+)?)$')
    if (-not $match.Success) {
        return $null
    }
    return $match.Groups[1].Value
}

function Get-PositiveLimit {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][long]$Default
    )

    $raw = [Environment]::GetEnvironmentVariable($Name)
    if ([string]::IsNullOrWhiteSpace($raw)) {
        return $Default
    }
    [long]$parsed = 0
    if (-not [long]::TryParse($raw, [ref]$parsed) -or $parsed -le 0) {
        throw "$Name must be a positive integer"
    }
    return $parsed
}

function Get-ExistingItem {
    param([Parameter(Mandatory = $true)][string]$LiteralPath)

    $item = Get-Item -LiteralPath $LiteralPath -Force -ErrorAction SilentlyContinue
    return $item
}

function Assert-SafeDestinationPath {
    param(
        [Parameter(Mandatory = $true)][string]$FullPath,
        [Parameter(Mandatory = $true)][ValidateSet('directory', 'file')][string]$LeafKind
    )

    $root = [IO.Path]::GetPathRoot($FullPath)
    if ([string]::IsNullOrEmpty($root) -or $root.StartsWith('\\')) {
        throw "the installer requires a local, drive-rooted destination: $FullPath"
    }

    $rootItem = Get-ExistingItem -LiteralPath $root
    if ($null -eq $rootItem -or -not $rootItem.PSIsContainer) {
        throw "destination drive root does not exist: $root"
    }
    if (($rootItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw "destination drive root is a reparse point: $root"
    }

    $relative = $FullPath.Substring($root.Length)
    $components = @($relative -split '[\\/]' | Where-Object { $_.Length -gt 0 })
    $current = $root
    for ($index = 0; $index -lt $components.Count; $index++) {
        $current = Join-Path -Path $current -ChildPath $components[$index]
        $item = Get-ExistingItem -LiteralPath $current
        if ($null -eq $item) {
            break
        }
        if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
            throw "destination path contains a reparse point: $current"
        }

        $isLeaf = $index -eq ($components.Count - 1)
        if (-not $isLeaf -or $LeafKind -eq 'directory') {
            if (-not $item.PSIsContainer) {
                throw "destination ancestor is not a directory: $current"
            }
        }
        elseif ($item.PSIsContainer) {
            throw "destination is not a regular file: $current"
        }
    }
}

function New-SafeDirectory {
    param([Parameter(Mandatory = $true)][string]$FullPath)

    Assert-SafeDestinationPath -FullPath $FullPath -LeafKind directory
    $root = [IO.Path]::GetPathRoot($FullPath)
    $relative = $FullPath.Substring($root.Length)
    $components = @($relative -split '[\\/]' | Where-Object { $_.Length -gt 0 })
    $current = $root
    foreach ($component in $components) {
        $current = Join-Path -Path $current -ChildPath $component
        $item = Get-ExistingItem -LiteralPath $current
        if ($null -eq $item) {
            $null = New-Item -ItemType Directory -Path $current
            $item = Get-ExistingItem -LiteralPath $current
        }
        if ($null -eq $item -or -not $item.PSIsContainer -or
            (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0)) {
            throw "destination directory was replaced during creation: $current"
        }
    }
}

function Copy-BoundedStream {
    param(
        [Parameter(Mandatory = $true)][IO.Stream]$InputStream,
        [Parameter(Mandatory = $true)][string]$Destination,
        [Parameter(Mandatory = $true)][long]$MaximumBytes,
        [Threading.CancellationToken]$CancellationToken = [Threading.CancellationToken]::None
    )

    $output = [IO.File]::Open($Destination, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
    try {
        $buffer = New-Object byte[] 81920
        [long]$total = 0
        while (($read = $InputStream.ReadAsync($buffer, 0, $buffer.Length, $CancellationToken).GetAwaiter().GetResult()) -gt 0) {
            $total += $read
            if ($total -gt $MaximumBytes) {
                throw "download exceeds the configured $MaximumBytes-byte limit"
            }
            $output.Write($buffer, 0, $read)
        }
        $output.Flush($true)
    }
    finally {
        $output.Dispose()
    }
}

function Receive-HttpsFile {
    param(
        [Parameter(Mandatory = $true)][uri]$Uri,
        [Parameter(Mandatory = $true)][string]$Destination,
        [Parameter(Mandatory = $true)][long]$MaximumBytes,
        [Parameter(Mandatory = $true)][int]$TimeoutSeconds
    )

    if ($Uri.Scheme -ne 'https') {
        throw "refusing non-HTTPS download: $Uri"
    }

    Add-Type -AssemblyName System.Net.Http
    $handler = New-Object System.Net.Http.HttpClientHandler
    $handler.AllowAutoRedirect = $false
    $client = New-Object System.Net.Http.HttpClient($handler)
    $client.Timeout = [TimeSpan]::FromSeconds($TimeoutSeconds)
    $client.DefaultRequestHeaders.UserAgent.ParseAdd('virtualboard-bootstrap-installer/1')
    $cancellation = New-Object Threading.CancellationTokenSource
    $cancellation.CancelAfter([TimeSpan]::FromSeconds($TimeoutSeconds))
    try {
        $current = $Uri
        for ($redirects = 0; $redirects -le 5; $redirects++) {
            $response = $client.GetAsync(
                $current,
                [Net.Http.HttpCompletionOption]::ResponseHeadersRead,
                $cancellation.Token
            ).GetAwaiter().GetResult()
            try {
                $status = [int]$response.StatusCode
                if ($status -in @(301, 302, 303, 307, 308)) {
                    if ($redirects -eq 5 -or $null -eq $response.Headers.Location) {
                        throw "too many or invalid redirects while downloading $Uri"
                    }
                    $next = [uri]::new($current, $response.Headers.Location)
                    if ($next.Scheme -ne 'https') {
                        throw "refusing redirect to non-HTTPS URL: $next"
                    }
                    $current = $next
                    continue
                }
                if (-not $response.IsSuccessStatusCode) {
                    throw "download failed with HTTP $status for $current"
                }
                $contentLength = $response.Content.Headers.ContentLength
                if ($null -ne $contentLength -and $contentLength -gt $MaximumBytes) {
                    throw "download exceeds the configured $MaximumBytes-byte limit"
                }
                $input = $response.Content.ReadAsStreamAsync().GetAwaiter().GetResult()
                try {
                    Copy-BoundedStream -InputStream $input -Destination $Destination -MaximumBytes $MaximumBytes -CancellationToken $cancellation.Token
                }
                finally {
                    $input.Dispose()
                }
                return
            }
            finally {
                $response.Dispose()
            }
        }
        throw "download redirect limit exceeded for $Uri"
    }
    finally {
        $cancellation.Dispose()
        $client.Dispose()
        $handler.Dispose()
    }
}

function Receive-ReleaseFile {
    param(
        [Parameter(Mandatory = $true)][uri]$Uri,
        [Parameter(Mandatory = $true)][string]$Destination,
        [Parameter(Mandatory = $true)][long]$MaximumBytes,
        [Parameter(Mandatory = $true)][int]$TimeoutSeconds
    )

    if ($env:VB_INSTALLER_TESTING -eq '1' -and
        -not [string]::IsNullOrWhiteSpace($env:VB_INSTALLER_TEST_SOURCE_DIR)) {
        $leaf = [IO.Path]::GetFileName($Uri.AbsolutePath)
        $source = Join-Path -Path $env:VB_INSTALLER_TEST_SOURCE_DIR -ChildPath $leaf
        if (-not [string]::IsNullOrWhiteSpace($env:VB_INSTALLER_TEST_DOWNLOAD_LOG)) {
            [IO.File]::AppendAllText($env:VB_INSTALLER_TEST_DOWNLOAD_LOG, "$Uri$([Environment]::NewLine)")
        }
        $input = [IO.File]::OpenRead($source)
        try {
            Copy-BoundedStream -InputStream $input -Destination $Destination -MaximumBytes $MaximumBytes
        }
        finally {
            $input.Dispose()
        }
        return
    }

    Receive-HttpsFile -Uri $Uri -Destination $Destination -MaximumBytes $MaximumBytes -TimeoutSeconds $TimeoutSeconds
}

function Get-BinaryVersion {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not [IO.File]::Exists($Path)) {
        return $null
    }
    try {
        $output = & $Path version 2>$null
        if ($LASTEXITCODE -ne 0) {
            return $null
        }
        $normalized = Get-NormalizedVersion -Value (($output | Out-String).Trim())
        return $normalized
    }
    catch {
        return $null
    }
}

function Get-ExpectedChecksum {
    param(
        [Parameter(Mandatory = $true)][string]$Manifest,
        [Parameter(Mandatory = $true)][string]$BinaryName
    )

    $matches = @()
    foreach ($line in [IO.File]::ReadAllLines($Manifest)) {
        $match = [regex]::Match($line, '^\s*([0-9A-Fa-f]{64})\s+\*?(.+?)\s*$')
        if (-not $match.Success) {
            continue
        }
        $name = $match.Groups[2].Value
        if ($name.StartsWith('./')) {
            $name = $name.Substring(2)
        }
        if ($name -ceq $BinaryName) {
            $matches += $match.Groups[1].Value.ToLowerInvariant()
        }
    }
    if ($matches.Count -ne 1) {
        throw "expected exactly one checksum entry for $BinaryName; found $($matches.Count)"
    }
    return $matches[0]
}

function Invoke-AtomicActivation {
    param(
        [Parameter(Mandatory = $true)][string]$Stage,
        [Parameter(Mandatory = $true)][string]$Target,
        [Parameter(Mandatory = $true)][string]$ExpectedHash
    )

    $stream = [IO.File]::Open($Stage, [IO.FileMode]::Open, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
    try {
        $hasher = [Security.Cryptography.SHA256]::Create()
        try {
            $stream.Position = 0
            $digest = ([BitConverter]::ToString($hasher.ComputeHash($stream))).Replace('-', '').ToLowerInvariant()
        }
        finally {
            $hasher.Dispose()
        }
        if ($digest -cne $ExpectedHash) {
            throw "staging bytes changed before activation"
        }
        $stream.Flush($true)
    }
    finally {
        $stream.Dispose()
    }

    Assert-SafeDestinationPath -FullPath $Stage -LeafKind file
    Assert-SafeDestinationPath -FullPath $Target -LeafKind file
    $pathDigest = (Get-FileHash -LiteralPath $Stage -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($pathDigest -cne $ExpectedHash) {
        throw "staging path changed before activation"
    }

    if ($env:VB_INSTALLER_TESTING -eq '1' -and $env:VB_INSTALLER_TEST_FAIL_ACTIVATION -eq '1') {
        throw "injected activation failure"
    }

    if ([IO.File]::Exists($Target)) {
        [IO.File]::Replace($Stage, $Target, $null, $true)
    }
    else {
        [IO.File]::Move($Stage, $Target)
    }
}

try {
    if ($env:OS -ne 'Windows_NT') {
        throw "install-vb-cli.ps1 supports Windows only; use install-vb-cli.sh on macOS or Linux"
    }
    if ($PSVersionTable.PSVersion -lt [version]'5.1') {
        throw "PowerShell 5.1 or newer is required"
    }
    if ($Local -and -not [string]::IsNullOrWhiteSpace($InstallDirectory)) {
        throw "-Local and -InstallDirectory cannot be used together"
    }

    $repository = if ([string]::IsNullOrWhiteSpace($env:VB_GITHUB_REPO)) {
        'virtualboard/vb-cli'
    }
    else {
        $env:VB_GITHUB_REPO
    }
    if ($repository -notmatch '^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$') {
        throw "VB_GITHUB_REPO must use the form owner/repository"
    }

    $repositoryRoot = [IO.Path]::GetFullPath((Join-Path -Path $PSScriptRoot -ChildPath '..'))
    $versionFile = if ([string]::IsNullOrWhiteSpace($env:VB_VERSION_FILE)) {
        Join-Path -Path $repositoryRoot -ChildPath '.vb-version'
    }
    else {
        [IO.Path]::GetFullPath($env:VB_VERSION_FILE)
    }
    if (-not [IO.File]::Exists($versionFile)) {
        throw "version file not found: $versionFile"
    }
    $targetTag = [IO.File]::ReadAllText($versionFile).Trim()
    $targetVersion = Get-NormalizedVersion -Value $targetTag
    if ([string]::IsNullOrWhiteSpace($targetVersion)) {
        throw "invalid version '$targetTag' in $versionFile"
    }

    $architecture = $env:PROCESSOR_ARCHITECTURE
    if ($architecture -eq 'AMD64') {
        $assetArchitecture = 'amd64'
    }
    elseif ($architecture -eq 'ARM64') {
        $assetArchitecture = 'arm64'
    }
    else {
        throw "unsupported Windows architecture '$architecture'; supported architectures are AMD64 and ARM64"
    }
    $binaryName = "vb-windows-$assetArchitecture.exe"

    if ($Local) {
        $targetDirectory = [IO.Path]::GetFullPath((Get-Location).Path)
    }
    elseif (-not [string]::IsNullOrWhiteSpace($InstallDirectory)) {
        $targetDirectory = [IO.Path]::GetFullPath($InstallDirectory)
    }
    else {
        if ([string]::IsNullOrWhiteSpace($env:LOCALAPPDATA)) {
            throw "LOCALAPPDATA is unavailable; pass -InstallDirectory explicitly"
        }
        $targetDirectory = [IO.Path]::GetFullPath((Join-Path $env:LOCALAPPDATA 'VirtualBoard\bin'))
    }
    $targetFile = Join-Path -Path $targetDirectory -ChildPath 'vb.exe'

    Assert-SafeDestinationPath -FullPath $targetDirectory -LeafKind directory
    Assert-SafeDestinationPath -FullPath $targetFile -LeafKind file

    Write-Host "Virtual Board CLI Installer"
    Write-Host "==========================="
    Write-Host "Selected version: $targetTag ($versionFile)"

    if (-not $EnsureLatest -and -not $Yes) {
        $answer = Read-Host "Install exact version $targetTag at $targetFile? [y/N]"
        if ($answer -notmatch '^(?i:y|yes)$') {
            Write-Host "Installation cancelled."
            exit 0
        }
    }

    New-SafeDirectory -FullPath $targetDirectory
    Assert-SafeDestinationPath -FullPath $targetFile -LeafKind file

    $binaryMaximum = Get-PositiveLimit -Name 'VB_BINARY_MAX_BYTES' -Default 104857600
    $checksumsMaximum = Get-PositiveLimit -Name 'VB_CHECKSUMS_MAX_BYTES' -Default 1048576
    $timeoutSeconds = Get-PositiveLimit -Name 'VB_CURL_MAX_TIME' -Default 120
    if ($timeoutSeconds -gt [int]::MaxValue) {
        throw "VB_CURL_MAX_TIME is too large"
    }

    $downloadFile = Join-Path ([IO.Path]::GetTempPath()) ("vb-download-{0}.exe" -f [guid]::NewGuid().ToString('N'))
    $checksumsFile = Join-Path ([IO.Path]::GetTempPath()) ("vb-checksums-{0}.txt" -f [guid]::NewGuid().ToString('N'))
    $downloadUri = [uri]"https://github.com/$repository/releases/download/$targetTag/$binaryName"
    $checksumsUri = [uri]"https://github.com/$repository/releases/download/$targetTag/checksums.txt"

    Receive-ReleaseFile -Uri $checksumsUri -Destination $checksumsFile -MaximumBytes $checksumsMaximum -TimeoutSeconds ([int]$timeoutSeconds)

    $expectedHash = Get-ExpectedChecksum -Manifest $checksumsFile -BinaryName $binaryName
    if ([IO.File]::Exists($targetFile)) {
        Assert-SafeDestinationPath -FullPath $targetFile -LeafKind file
        $targetHash = (Get-FileHash -LiteralPath $targetFile -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($targetHash -ceq $expectedHash) {
            $currentVersion = Get-BinaryVersion -Path $targetFile
            if ($currentVersion -ne $targetVersion) {
                throw "manifest-verified destination version mismatch: expected v$targetVersion, got v$currentVersion"
            }
            Write-Host "Exact manifest-verified version is already installed at $targetFile."
            exit 0
        }
    }

    Write-Host "Downloading $downloadUri"
    Receive-ReleaseFile -Uri $downloadUri -Destination $downloadFile -MaximumBytes $binaryMaximum -TimeoutSeconds ([int]$timeoutSeconds)
    $actualHash = (Get-FileHash -LiteralPath $downloadFile -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actualHash -cne $expectedHash) {
        throw "SHA-256 checksum mismatch for $binaryName"
    }
    Write-Host "Checksum verified."

    $downloadedVersion = Get-BinaryVersion -Path $downloadFile
    if ($downloadedVersion -ne $targetVersion) {
        throw "downloaded binary version mismatch: expected v$targetVersion, got v$downloadedVersion"
    }

    Assert-SafeDestinationPath -FullPath $targetDirectory -LeafKind directory
    Assert-SafeDestinationPath -FullPath $targetFile -LeafKind file
    $stageFile = Join-Path -Path $targetDirectory -ChildPath (".vb.install.{0}.exe" -f [guid]::NewGuid().ToString('N'))
    [IO.File]::Copy($downloadFile, $stageFile, $false)
    Assert-SafeDestinationPath -FullPath $stageFile -LeafKind file

    $stagedHash = (Get-FileHash -LiteralPath $stageFile -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($stagedHash -cne $expectedHash) {
        throw "same-directory staged binary checksum mismatch"
    }
    $stagedVersion = Get-BinaryVersion -Path $stageFile
    if ($stagedVersion -ne $targetVersion) {
        throw "same-directory staged binary version mismatch: expected v$targetVersion, got v$stagedVersion"
    }

    Invoke-AtomicActivation -Stage $stageFile -Target $targetFile -ExpectedHash $expectedHash
    $stageFile = $null

    $installedHash = (Get-FileHash -LiteralPath $targetFile -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($installedHash -cne $expectedHash) {
        throw "post-install binary checksum mismatch"
    }
    $installedVersion = Get-BinaryVersion -Path $targetFile
    if ($installedVersion -ne $targetVersion) {
        throw "post-install version mismatch: expected v$targetVersion, got v$installedVersion"
    }

    Write-Host "Installed and verified $targetTag at $targetFile"
    exit 0
}
catch {
    Write-Error "VirtualBoard CLI installation failed: $($_.Exception.Message)"
    exit 1
}
finally {
    foreach ($path in @($downloadFile, $checksumsFile, $stageFile)) {
        if (-not [string]::IsNullOrWhiteSpace($path) -and [IO.File]::Exists($path)) {
            Remove-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
        }
    }
}
