<#
.SYNOPSIS
    Sets up a Windows dev machine from this repo: apps, shell, terminal, Neovim, komorebi tiling,
    Herdr, Claude Code and a few Windows speed fixes.
    Safe to run again: finished work is skipped and any file it replaces is backed up first.

.EXAMPLE
    .\setup.ps1               # menu: pick what to set up
    .\setup.ps1 -Steps 2,5    # run steps 2 and 5 without the menu
    .\setup.ps1 -All          # run every step
    .\setup.ps1 -Check        # compare this PC's configs with the repo
    .\setup.ps1 -Save         # copy this PC's configs and scoop app list into the repo
#>
param(
    [int[]]$Steps,
    [switch]$All,
    [switch]$Check,
    [switch]$Save
)

$Repo  = $PSScriptRoot
$Docs  = [Environment]::GetFolderPath('MyDocuments')
$Stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$Utf8  = New-Object System.Text.UTF8Encoding $false

$NvimRepo   = 'https://github.com/bewithsnehasish/nvim-config.git'
$NvimBranch = 'windows'

# Repo file -> where it lives on this PC. Install, -Save and -Check all use this list.
$Configs = [ordered]@{
    'powershell\Microsoft.PowerShell_profile.ps1' = "$Docs\PowerShell\Microsoft.PowerShell_profile.ps1"
    'starship\starship.toml'                      = "$HOME\.config\starship.toml"
    'wezterm\.wezterm.lua'                        = "$HOME\.wezterm.lua"
    'herdr\config.toml'                           = "$env:APPDATA\herdr\config.toml"
    'whkd\whkdrc'                                 = "$HOME\.config\whkdrc"
    'claude\settings.json'                        = "$HOME\.claude\settings.json"
    'claude\CLAUDE.md'                            = "$HOME\.claude\CLAUDE.md"
    'claude\statusline.js'                        = "$HOME\.claude\statusline.js"
    'claude\hooks\identity-guard.js'              = "$HOME\.claude\hooks\identity-guard.js"
    'claude\hooks\prettier-on-edit.js'            = "$HOME\.claude\hooks\prettier-on-edit.js"
    'claude\hooks\herdr-agent-state.ps1'          = "$HOME\.claude\hooks\herdr-agent-state.ps1"
    'git\.gitconfig'                              = "$HOME\.gitconfig"
    'git\ssh-config'                              = "$HOME\.ssh\config"
}
foreach ($f in 'komorebi.json',
               'komorebi.bar.monitor0.json', 'komorebi.bar.monitor1.json', 'komorebi.bar.monitor2.json', 'komorebi.bar.monitor3.json',
               'komorebi.my-rules.json') {
    $Configs["komorebi\$f"] = "$HOME\$f"
}

# ---------------------------------------------------------------- helpers

# Home-folder paths are stored as placeholders, so the repo works for any Windows username.
function ConvertTo-RepoText([string]$Text) {
    $Text.Replace($HOME.Replace('\', '\\'), '{{HOME_JSON}}').Replace($HOME, '{{HOME}}').Replace($HOME.Replace('\', '/'), '{{HOME_FWD}}')
}
function ConvertFrom-RepoText([string]$Text) {
    $Text.Replace('{{HOME_JSON}}', $HOME.Replace('\', '\\')).Replace('{{HOME}}', $HOME).Replace('{{HOME_FWD}}', $HOME.Replace('\', '/'))
}

function Write-Note([string]$Text) { Write-Host "    $Text" -ForegroundColor DarkGray }
function Test-Command([string]$Name) { [bool](Get-Command $Name -ErrorAction SilentlyContinue) }

# Picks up PATH changes made by installers during this run.
function Update-Path {
    $env:PATH = [Environment]::GetEnvironmentVariable('PATH', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('PATH', 'User')
}

function Get-Pwsh {
    $cmd = Get-Command pwsh -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    if (Test-Path "$env:ProgramFiles\PowerShell\7\pwsh.exe") { return "$env:ProgramFiles\PowerShell\7\pwsh.exe" }
    "$env:windir\System32\WindowsPowerShell\v1.0\powershell.exe"
}

# Copies the repo's files under one folder (e.g. 'komorebi\') onto this PC, backing up what it replaces.
function Install-Configs([string]$Folder) {
    foreach ($key in @($Configs.Keys)) {
        if (-not $key.StartsWith($Folder)) { continue }
        $src = Join-Path $Repo $key
        $dst = $Configs[$key]
        if (-not (Test-Path $src)) { continue }
        $text = ConvertFrom-RepoText ([IO.File]::ReadAllText($src))
        if (Test-Path $dst) {
            if ([IO.File]::ReadAllText($dst) -ceq $text) { Write-Note "unchanged   $dst"; continue }
            Copy-Item $dst "$dst.bak-$Stamp" -ErrorAction Stop
            Write-Note "backed up   $dst.bak-$Stamp"
        }
        New-Item -ItemType Directory -Force (Split-Path $dst) | Out-Null
        [IO.File]::WriteAllText($dst, $text, $Utf8)
        Write-Note "wrote       $dst"
    }
}

# ---------------------------------------------------------------- steps

function Step-Packages {
    if (-not (Test-Command scoop)) {
        Write-Note 'installing scoop'
        Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
        Invoke-RestMethod https://get.scoop.sh | Invoke-Expression
        Update-Path
    }
    if (-not (Test-Command git)) { scoop install git; Update-Path }

    Write-Note 'scoop apps from packages\scoopfile.json (installed ones are skipped)'
    scoop import (Join-Path $Repo 'packages\scoopfile.json')
    Update-Path

    foreach ($line in Get-Content (Join-Path $Repo 'packages\winget.txt')) {
        $id, $command = ($line -replace '#.*', '').Trim() -split '\s+'
        if (-not $id) { continue }
        if ($command -and (Test-Command $command)) { Write-Note "already installed   $id"; continue }
        Write-Note "installing   $id"
        winget install --id $id -e --silent --accept-package-agreements --accept-source-agreements
        if ($LASTEXITCODE -ne 0) { throw "winget could not install $id (exit $LASTEXITCODE)" }
        Update-Path
    }

    # Modules the PowerShell 7 profile loads (git prompt, file icons, fzf keys).
    # Sent encoded: Windows PowerShell 5.1 strips inner quotes when passing a command to another program.
    $modules = 'foreach ($m in "posh-git", "Terminal-Icons", "PSFzf") { if (Get-Module -ListAvailable $m) { "    module already installed   $m" } else { Install-Module $m -Scope CurrentUser -Force -AcceptLicense -ErrorAction Stop; "    installed module   $m" } }'
    & (Get-Pwsh) -NoProfile -EncodedCommand ([Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($modules)))
    if ($LASTEXITCODE -ne 0) { throw 'installing PowerShell modules failed' }
}

function Step-Shell { Install-Configs 'powershell\'; Install-Configs 'starship\' }

function Step-WezTerm { Install-Configs 'wezterm\' }

function Step-Neovim {
    $dst = "$env:LOCALAPPDATA\nvim"
    if (Test-Path $dst) { Write-Note "already there, left as is   $dst"; return }
    git clone -b $NvimBranch $NvimRepo $dst
    if ($LASTEXITCODE -ne 0) { throw "git clone of $NvimRepo failed" }
    Write-Note 'open nvim once to let it install its plugins'
}

function Step-Komorebi {
    Install-Configs 'komorebi\'
    Install-Configs 'whkd\'
    if (Test-Command komorebic) {
        komorebic fetch-app-specific-configuration | Out-Null
        Write-Note 'community app rules updated   ~\applications.json'
    }

    # komorebi's own startup shortcut starts komorebi, whkd and the bars at login.
    komorebic enable-autostart --whkd --bar | Out-Null
    Write-Note 'starts at login   shell:startup\komorebi.lnk'

    # Windows' own hover-to-focus, without bringing the window to the front, so a floating window stays on top.
    Add-Type -Namespace Win32 -Name Spi -MemberDefinition '[DllImport("user32.dll")] public static extern bool SystemParametersInfo(uint a, uint b, IntPtr c, uint d);'
    [Win32.Spi]::SystemParametersInfo(0x1001, 0, [IntPtr]1, 3) | Out-Null
    [Win32.Spi]::SystemParametersInfo(0x100D, 0, [IntPtr]0, 3) | Out-Null
    Write-Note 'focus follows mouse (no raise) turned on'

    if (Get-Process komorebi -ErrorAction SilentlyContinue) { Write-Note 'komorebi already running' }
    else {
        komorebic start --whkd --bar | Out-Null
        Write-Note 'komorebi started'
    }
}

function Step-Herdr { Install-Configs 'herdr\' }

function Step-Claude {
    if (-not (Test-Command claude)) {
        Write-Note 'installing Claude Code'
        Invoke-RestMethod https://claude.ai/install.ps1 | Invoke-Expression
        Update-Path
    }
    Install-Configs 'claude\'
    Write-Note 'run "claude" once to sign in'
}

function Step-Git {
    Install-Configs 'git\'
    foreach ($key in 'id_ed25519', 'id_ed25519_personal') {
        if (-not (Test-Path "$HOME\.ssh\$key")) {
            Write-Note "no SSH key ~/.ssh/${key}: create one with  ssh-keygen -t ed25519 -f `"$HOME\.ssh\$key`"  and add the .pub file to GitHub"
        }
    }
}

function Step-SpeedFixes {
    # Start login apps right away instead of after Windows' startup delay (this user only, no admin).
    $serialize = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize'
    if (-not (Test-Path $serialize)) { New-Item $serialize | Out-Null }
    Set-ItemProperty $serialize -Name StartupDelayInMSec -Value 1 -Type DWord
    Set-ItemProperty $serialize -Name WaitForIdleState -Value 0 -Type DWord
    Write-Note 'startup apps: no delay'

    # Stop Windows from parking window-less programs (komorebi, whkd, terminal panes) on the slow cores.
    $throttling = (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling' -ErrorAction SilentlyContinue).PowerThrottlingOff
    if ($throttling -eq 1) { Write-Note 'power throttling: already off'; return }
    Write-Note 'power throttling: turning off (approve the admin prompt)'
    Start-Process reg.exe -Verb RunAs -Wait -ArgumentList 'add', 'HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling', '/v', 'PowerThrottlingOff', '/t', 'REG_DWORD', '/d', '1', '/f'
    Write-Note 'restart Windows to apply'
}

function Step-Cleanup {
    $junk = @(Get-ChildItem "$env:LOCALAPPDATA\komorebi" -Filter 'komorebi-bar-*' -File -ErrorAction SilentlyContinue | Where-Object Length -eq 0)
    $junk | Remove-Item -Force
    Write-Note "removed $($junk.Count) empty komorebi-bar files"
    Write-Note 'to trim login apps: Settings > Apps > Startup (or run: start ms-settings:startupapps)'
}

$StepList = @(
    @{ Name = 'Packages';    Info = 'scoop apps, PowerShell 7, WezTerm, Node, PowerShell modules'; Run = { Step-Packages } }
    @{ Name = 'Shell';       Info = 'PowerShell profile + starship prompt';                               Run = { Step-Shell } }
    @{ Name = 'WezTerm';     Info = 'terminal config';                                                    Run = { Step-WezTerm } }
    @{ Name = 'Neovim';      Info = "clone nvim-config ($NvimBranch branch)";                             Run = { Step-Neovim } }
    @{ Name = 'komorebi';    Info = 'tiling + whkd hotkeys + bar + hover focus, started at login';              Run = { Step-Komorebi } }
    @{ Name = 'Herdr';       Info = 'agent workspace config';                                             Run = { Step-Herdr } }
    @{ Name = 'Claude Code'; Info = 'CLI, settings, status line, hooks';                                  Run = { Step-Claude } }
    @{ Name = 'Git + SSH';   Info = 'git config and SSH host aliases (keys are never in the repo)';       Run = { Step-Git } }
    @{ Name = 'Speed fixes'; Info = 'no startup-app delay, no power throttling (one admin prompt)';      Run = { Step-SpeedFixes } }
    @{ Name = 'Cleanup';     Info = 'remove komorebi leftovers, tips for startup apps';                   Run = { Step-Cleanup } }
)

# ---------------------------------------------------------------- -Save / -Check

function Save-Configs {
    foreach ($key in $Configs.Keys) {
        $src = $Configs[$key]
        if (-not (Test-Path $src)) { Write-Note "not on this PC, skipped   $key"; continue }
        $dst = Join-Path $Repo $key
        New-Item -ItemType Directory -Force (Split-Path $dst) | Out-Null
        [IO.File]::WriteAllText($dst, (ConvertTo-RepoText ([IO.File]::ReadAllText($src))), $Utf8)
        Write-Note "saved   $key"
    }
    if (Test-Command scoop) {
        # Keep only what `scoop import` needs, so versions and dates don't churn the repo.
        $export = scoop export | Out-String | ConvertFrom-Json
        $list = [ordered]@{
            buckets = @($export.buckets | ForEach-Object { [ordered]@{ Name = $_.Name; Source = $_.Source } })
            apps    = @($export.apps | Sort-Object Name | ForEach-Object { [ordered]@{ Name = $_.Name; Source = $_.Source; Info = $_.Info } })
        }
        [IO.File]::WriteAllText((Join-Path $Repo 'packages\scoopfile.json'), ($list | ConvertTo-Json -Depth 4), $Utf8)
        Write-Note 'saved   packages\scoopfile.json'
    }
}

function Show-Check {
    foreach ($key in $Configs.Keys) {
        $inRepo = Join-Path $Repo $key
        $onPc = $Configs[$key]
        if (-not (Test-Path $inRepo)) { $state = 'not in repo' }
        elseif (-not (Test-Path $onPc)) { $state = 'not on PC' }
        elseif ((ConvertFrom-RepoText ([IO.File]::ReadAllText($inRepo))) -ceq [IO.File]::ReadAllText($onPc)) { $state = 'same' }
        else { $state = 'DIFFERENT' }
        Write-Host ('  {0,-12} {1}' -f $state, $key)
    }
}

# ---------------------------------------------------------------- main

if ($Save) { Save-Configs; return }
if ($Check) { Show-Check; return }

$admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if ($admin) { Write-Warning 'Run this from a normal (not admin) PowerShell window: scoop refuses to install as admin.'; return }

if ($All) { $Steps = 1..$StepList.Count }
if (-not $Steps) {
    Write-Host "`nWindows setup - pick what to set up:`n"
    for ($i = 0; $i -lt $StepList.Count; $i++) { Write-Host ('  {0,2}) {1,-12} {2}' -f ($i + 1), $StepList[$i].Name, $StepList[$i].Info) }
    $answer = Read-Host "`nNumbers (e.g. 1 3 5), 'a' for all, Enter to quit"
    if (-not $answer) { return }
    if ($answer.Trim() -eq 'a') { $Steps = 1..$StepList.Count }
    else { $Steps = @($answer -split '[,\s]+' | Where-Object { $_ -match '^\d+$' } | ForEach-Object { [int]$_ }) }
}

$log = Join-Path $env:TEMP "dotfiles-setup-$Stamp.log"
Start-Transcript $log | Out-Null
$results = foreach ($n in $Steps) {
    if ($n -lt 1 -or $n -gt $StepList.Count) { Write-Warning "no step $n"; continue }
    $step = $StepList[$n - 1]
    Write-Host "`n==> $n. $($step.Name)" -ForegroundColor Cyan
    try {
        & $step.Run
        [pscustomobject]@{ Step = "$n. $($step.Name)"; Result = 'OK' }
    } catch {
        Write-Host "    $_" -ForegroundColor Red
        [pscustomobject]@{ Step = "$n. $($step.Name)"; Result = "FAILED: $_" }
    }
}
Stop-Transcript | Out-Null

$results | Format-Table -AutoSize | Out-Host
Write-Host "Log: $log"
