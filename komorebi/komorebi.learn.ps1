# Adds a rule for the focused window (its app + exact title) to komorebi.my-rules.json,
# so windows like it float (or are left alone by komorebi) from now on. Bound to hotkeys in whkdrc.
param(
    [ValidateSet('float', 'ignore')] [string]$Mode = 'float',
    [string]$File = "$env:USERPROFILE\komorebi.my-rules.json",
    [switch]$NoApply
)

Add-Type @'
using System; using System.Text; using System.Runtime.InteropServices;
public static class Fg {
  [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
  [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
  [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
}
'@
$h = [Fg]::GetForegroundWindow()
$sb = [Text.StringBuilder]::new(512); [void][Fg]::GetWindowText($h, $sb, 512)
$procId = [uint32]0; [void][Fg]::GetWindowThreadProcessId($h, [ref]$procId)
$title = $sb.ToString()
$exe = Split-Path -Leaf (Get-Process -Id $procId).Path
if (-not $title -or -not $exe) { exit 1 }

$rules = Get-Content $File -Raw | ConvertFrom-Json -AsHashtable
$app = "learned: $exe"
$kind = if ($Mode -eq 'float') { 'floating' } else { 'ignore' }
if (-not $rules[$app]) { $rules[$app] = @{} }
$rules[$app][$kind] = @($rules[$app][$kind] | Where-Object { $_ }) + , @(
    [ordered]@{ kind = 'Exe'; id = $exe; matching_strategy = 'Equals' },
    [ordered]@{ kind = 'Title'; id = $title; matching_strategy = 'Equals' }
)
ConvertTo-Json -InputObject $rules -Depth 10 | Set-Content $File
"$Mode rule added: $exe / '$title'"

if (-not $NoApply) {
    komorebic reload-configuration
    komorebic toggle-float   # frees the current window now; the rule handles the next ones
}
