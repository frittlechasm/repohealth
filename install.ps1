param(
  [string]$Dir = $env:REPOHEALTH_INSTALL_DIR,
  [string]$Version = $env:REPOHEALTH_VERSION,
  [string]$Bin = $env:REPOHEALTH_BIN,
  [string]$BaseUrl = $env:REPOHEALTH_BASE_URL,
  [switch]$NoPathUpdate
)

$ErrorActionPreference = "Stop"

if (-not $Dir) {
  $Dir = Join-Path $env:LOCALAPPDATA "Programs\repohealth"
}
if (-not $Version) {
  $Version = "main"
}
if (-not $Bin) {
  $Bin = "repohealth"
}
if ($Bin -match '[\\/]') {
  throw "Binary name must not contain path separators."
}
if (-not $BaseUrl) {
  $BaseUrl = "https://raw.githubusercontent.com/frittlechasm/repohealth/$Version"
}
if (-not (Get-Command bash -ErrorAction SilentlyContinue)) {
  throw "bash is required to run repohealth on Windows. Install Git for Windows, then rerun this installer."
}

$scriptUrl = "$BaseUrl/repohealth"
$scriptPath = Join-Path $Dir $Bin
$cmdPath = Join-Path $Dir "$Bin.cmd"
$tmp = Join-Path ([IO.Path]::GetTempPath()) "repohealth-install-$PID"

try {
  Invoke-WebRequest -Uri $scriptUrl -OutFile $tmp -UseBasicParsing

  $firstLine = Get-Content -LiteralPath $tmp -TotalCount 1
  if ($firstLine -ne "#!/usr/bin/env bash") {
    throw "Downloaded file does not look like repohealth."
  }

  New-Item -ItemType Directory -Force -Path $Dir | Out-Null
  Copy-Item -LiteralPath $tmp -Destination $scriptPath -Force

  $cmd = @"
@echo off
bash "%~dp0$Bin" %*
"@
  Set-Content -LiteralPath $cmdPath -Value $cmd -NoNewline -Encoding ASCII

  Write-Host "Installed repohealth to $scriptPath"
  Write-Host "Installed Windows launcher to $cmdPath"

  $pathParts = [Environment]::GetEnvironmentVariable("Path", "User") -split ';' | Where-Object { $_ }
  $alreadyOnPath = $pathParts | Where-Object { $_.TrimEnd('\') -ieq $Dir.TrimEnd('\') }

  if (-not $alreadyOnPath) {
    if ($NoPathUpdate) {
      Write-Host "Add this directory to PATH to run $Bin from any terminal: $Dir"
    } else {
      $newPath = ($pathParts + $Dir) -join ';'
      [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
      $env:Path = ($env:Path, $Dir) -join ';'
      Write-Host "Added $Dir to your user PATH."
    }
  }
} finally {
  Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
}
