# Starts komorebi, whkd and masir together, then each bar as soon as komorebi answers.
# `komorebic start --bar` launches them one after another and showed the bar ~45 s after komorebi at login.
$kc = "$env:USERPROFILE\scoop\apps\komorebi\current"
Start-Process "$kc\komorebi.exe" -WindowStyle Hidden
Start-Process "$env:USERPROFILE\scoop\apps\whkd\current\whkd.exe" -WindowStyle Hidden
if (Test-Path "$env:ProgramFiles\masir\bin\masir.exe") { Start-Process "$env:ProgramFiles\masir\bin\masir.exe" -WindowStyle Hidden }

# A bar exits if komorebi isn't up yet, so wait until it answers (at most 60 s).
$deadline = (Get-Date).AddSeconds(60)
do { Start-Sleep -Milliseconds 250; & "$kc\komorebic.exe" state *> $null } until ($LASTEXITCODE -eq 0 -or (Get-Date) -gt $deadline)

$cfg = Get-Content "$env:USERPROFILE\komorebi.json" -Raw | ConvertFrom-Json
foreach ($bar in $cfg.bar_configurations) {
    $path = $bar -replace '\$Env:USERPROFILE', $env:USERPROFILE
    Start-Process "$kc\komorebi-bar.exe" -ArgumentList '--config', $path -WindowStyle Hidden
}
