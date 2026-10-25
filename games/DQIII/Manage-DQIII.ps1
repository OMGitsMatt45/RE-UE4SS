# MIT; see LICENSE. Run from an extracted release, with III closed.
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][ValidateSet('Install','Verify','Uninstall')][string]$Action,
    [Parameter(Mandatory=$true)][string]$GameDirectory,
    [switch]$ReplaceExisting
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$expectedExe = '00762b2cec4a91373f8ac8479666bfa6dc7d8267e530bcb352e90b5624ac5af0'
$allowed = @('dwmapi.dll','ue4ss/UE4SS.dll','ue4ss/UE4SS-settings.ini',
    'ue4ss/VTableLayout.ini','ue4ss/LICENSE',
    'ue4ss/Mods/DQIIIProbe/enabled.txt','ue4ss/Mods/DQIIIProbe/scripts/main.lua')

function Safe-Path([string]$Root, [string]$Relative) {
    if ([IO.Path]::IsPathRooted($Relative) -or $Relative -match '(^|[\\/])\.\.([\\/]|$)' -or $Relative -match ':') {
        throw "Unsafe relative path: $Relative"
    }
    $base = [IO.Path]::GetFullPath($Root).TrimEnd('\','/')
    $full = [IO.Path]::GetFullPath((Join-Path $base $Relative))
    if (-not $full.StartsWith($base + '\', [StringComparison]::OrdinalIgnoreCase)) { throw 'Path escaped root' }
    $cursor = $full
    while ($cursor) {
        if (Test-Path -LiteralPath $cursor) {
            $item = Get-Item -LiteralPath $cursor -Force
            if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "Reparse point refused: $cursor" }
        }
        $cursor = [IO.Path]::GetDirectoryName($cursor)
    }
    return $full
}
function Hash([string]$Path) {
    $stream = [IO.File]::OpenRead($Path)
    $sha = [Security.Cryptography.SHA256]::Create()
    try { return [BitConverter]::ToString($sha.ComputeHash($stream)).Replace('-','').ToLowerInvariant() }
    finally { $sha.Dispose(); $stream.Dispose() }
}
function Assert-Hash([string]$Path, [string]$Expected) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf) -or (Hash $Path) -ne $Expected.ToLowerInvariant()) {
        throw "Missing or changed file: $Path"
    }
}
function Put-File([string]$From, [string]$To) {
    New-Item -ItemType Directory -Path ([IO.Path]::GetDirectoryName($To)) -Force | Out-Null
    Copy-Item -LiteralPath $From -Destination $To -Force
}

$bin = Safe-Path $GameDirectory 'Game/Binaries/Win64'
$exe = Safe-Path $bin 'DQIIIHD2DRemake.exe'
if (@(Get-Process | Where-Object { $_.ProcessName -like 'DQIII*' -and $_.Path -eq $exe }).Count) { throw 'Close Dragon Quest III first.' }
# Uninstall remains available after a Steam update; Install and Verify are build gated.
if ($Action -ne 'Uninstall') { Assert-Hash $exe $expectedExe }
$state = Safe-Path $bin '.dqiii-ue4ss-core'
$active = Safe-Path $state 'active.json'

if ($Action -eq 'Install') {
    if (Test-Path -LiteralPath $active) { throw 'An installation receipt exists. Verify or Uninstall it first.' }
    foreach ($legacy in @('UE4SS.dll','UE4SS-settings.ini','VTableLayout.ini')) {
        if (Test-Path -LiteralPath (Safe-Path $bin $legacy)) { throw "Move the previous root-layout installation aside first: $legacy" }
    }
    $manifest = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'manifest.json') -Raw | ConvertFrom-Json
    if ($manifest.schema -ne 1 -or @($manifest.files).Count -ne $allowed.Count) { throw 'Invalid package manifest' }
    $seen = @{}
    $entries = @()
    $id = [Guid]::NewGuid().ToString('N')
    foreach ($file in $manifest.files) {
        if ($file.path -cnotin $allowed -or $seen.ContainsKey($file.path)) { throw 'Unexpected or duplicate payload path' }
        $seen[$file.path] = $true
        $source = Safe-Path (Join-Path $PSScriptRoot 'payload') $file.path
        $target = Safe-Path $bin $file.path
        Assert-Hash $source $file.sha256
        $previous = $null
        if (Test-Path -LiteralPath $target) {
            if (-not $ReplaceExisting) { throw "Existing file refused: $target. Review it before using -ReplaceExisting." }
            if (-not (Test-Path -LiteralPath $target -PathType Leaf)) { throw "Not a file: $target" }
            $previous = Hash $target
        }
        $entries += [pscustomobject]@{path=$file.path; sha256=$file.sha256; previous=$previous}
    }
    # All payloads and conflicts were checked before any game file is changed.
    $backupRoot = Safe-Path $state ("backups/" + $id)
    foreach ($entry in $entries) {
        if ($entry.previous) {
            $backup = Safe-Path $backupRoot $entry.path
            Put-File (Safe-Path $bin $entry.path) $backup
            Assert-Hash $backup $entry.previous
        }
    }
    $written = @()
    try {
        foreach ($entry in $entries) {
            $written += $entry
            $target = Safe-Path $bin $entry.path
            Put-File (Safe-Path (Join-Path $PSScriptRoot 'payload') $entry.path) $target
            Assert-Hash $target $entry.sha256
        }
        $receipt = [ordered]@{schema=1; version=$manifest.version; id=$id; files=$entries}
        New-Item -ItemType Directory -Path $state -Force | Out-Null
        $temporary = Safe-Path $state 'active.pending.json'
        $receipt | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $temporary -Encoding UTF8
        Move-Item -LiteralPath $temporary -Destination $active
    } catch {
        foreach ($entry in $written) {
            $target = Safe-Path $bin $entry.path
            if ($entry.previous) { Put-File (Safe-Path $backupRoot $entry.path) $target }
            elseif (Test-Path -LiteralPath $target -PathType Leaf) { Remove-Item -LiteralPath $target }
        }
        throw
    }
    Write-Output 'Installed DQIII core. Launch through Steam; F6 reports native callback counts in ue4ss/UE4SS.log.'
} else {
    if (-not (Test-Path -LiteralPath $active -PathType Leaf)) { throw 'No active installation receipt found.' }
    $receipt = Get-Content -LiteralPath $active -Raw | ConvertFrom-Json
    if ($receipt.schema -ne 1 -or $receipt.id -notmatch '^[a-f0-9]{32}$' -or @($receipt.files).Count -ne $allowed.Count) { throw 'Invalid receipt' }
    $seen = @{}
    $backupRoot = Safe-Path $state ('backups/' + $receipt.id)
    foreach ($entry in $receipt.files) {
        if ($entry.path -cnotin $allowed -or $seen.ContainsKey($entry.path)) { throw 'Invalid receipt path' }
        $seen[$entry.path] = $true
        Assert-Hash (Safe-Path $bin $entry.path) $entry.sha256
        if ($Action -eq 'Uninstall' -and $entry.previous) { Assert-Hash (Safe-Path $backupRoot $entry.path) $entry.previous }
    }
    if ($Action -eq 'Verify') { Write-Output 'Verified tested game build and all seven installed payload files.'; return }
    # Preflight above refuses to overwrite any later edits, and checks every backup.
    foreach ($entry in $receipt.files) {
        $target = Safe-Path $bin $entry.path
        if ($entry.previous) { Put-File (Safe-Path $backupRoot $entry.path) $target }
        else { Remove-Item -LiteralPath $target }
    }
    $history = Safe-Path $state ('uninstalled-' + $receipt.id + '.json')
    Move-Item -LiteralPath $active -Destination $history
    Write-Output 'Uninstalled owned files and restored replaced files. Logs, backups, and other mods are retained.'
}
