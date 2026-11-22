# Starts komorebi, whkd and masir together, then each bar as soon as komorebi answers.
# `komorebic start --bar` launches them one after another and showed the bar ~45 s after komorebi at login.
# -BarsOnly just starts any missing bars (the alt+shift+b hotkey uses it).
param([switch]$BarsOnly)
$kc = "$env:USERPROFILE\scoop\apps\komorebi\current"

# komorebi-bar crashes on start when its screen isn't connected, so start only the bars whose screen is there.
function Start-MissingBars {
    $state = & "$kc\komorebic.exe" state 2>$null | ConvertFrom-Json
    if (-not $state) { return }
    $connected = $state.monitor_usr_idx_map.PSObject.Properties.Name
    $running = @(Get-CimInstance Win32_Process -Filter "Name='komorebi-bar.exe'").CommandLine -join "`n"
    $cfg = Get-Content "$env:USERPROFILE\komorebi.json" -Raw | ConvertFrom-Json
    foreach ($bar in $cfg.bar_configurations) {
        $path = $bar -replace '\$Env:USERPROFILE', $env:USERPROFILE
        $index = (Get-Content $path -Raw | ConvertFrom-Json).monitor.index
        if ($connected -contains "$index" -and -not $running.Contains((Split-Path $path -Leaf))) {
            Start-Process "$kc\komorebi-bar.exe" -ArgumentList '--config', $path -WindowStyle Hidden
        }
    }
}

if ($BarsOnly) { Start-MissingBars; return }

Start-Process "$kc\komorebi.exe" -WindowStyle Hidden
Start-Process "$env:USERPROFILE\scoop\apps\whkd\current\whkd.exe" -WindowStyle Hidden
if (Test-Path "$env:ProgramFiles\masir\bin\masir.exe") { Start-Process "$env:ProgramFiles\masir\bin\masir.exe" -WindowStyle Hidden }

# A bar exits if komorebi isn't up yet, so wait until it answers (at most 60 s).
$deadline = (Get-Date).AddSeconds(60)
do { Start-Sleep -Milliseconds 250; & "$kc\komorebic.exe" state *> $null } until ($LASTEXITCODE -eq 0 -or (Get-Date) -gt $deadline)
Start-MissingBars

# Stay running and start a screen's bar when that screen is plugged in later. One watcher per login.
$mutex = [Threading.Mutex]::new($false, 'Local\komorebi-bar-watcher')
if (-not $mutex.WaitOne(0)) { return }
Register-ObjectEvent -InputObject ([Microsoft.Win32.SystemEvents]) -EventName DisplaySettingsChanged -SourceIdentifier display | Out-Null
while ($true) {
    Wait-Event -SourceIdentifier display | Out-Null
    # komorebi needs a moment to register the new screen; retrying never starts a bar twice.
    foreach ($try in 1..5) {
        Start-Sleep -Seconds 2
        Get-Event -SourceIdentifier display -ErrorAction SilentlyContinue | Remove-Event
        Start-MissingBars
    }
}
