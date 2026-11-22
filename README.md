# dotfiles-windows

My Windows dev setup in one script: komorebi tiling with whkd hotkeys and masir focus-follows-mouse, WezTerm, PowerShell 7 + starship, Neovim, Herdr, Claude Code, and a few Windows speed fixes.

`setup.ps1` is safe to run again and again. It skips anything already done, backs up a file before replacing it (`<file>.bak-<date>`), keeps going if one step fails, and ends with an OK/FAILED table and a log file.

## Set up a new PC

Open a **normal** (not admin) PowerShell window:

```powershell
winget install --id Git.Git -e                 # then open a new PowerShell window
git clone https://github.com/bewithsnehasish/dotfiles-windows "$HOME\Github\dotfiles-windows"
cd "$HOME\Github\dotfiles-windows"
powershell -ExecutionPolicy Bypass -File .\setup.ps1
```

Pick steps from the menu (`1 3 5`, or `a` for all). Without the menu: `.\setup.ps1 -Steps 2,5` or `.\setup.ps1 -All`.

| # | Step | What it does |
|---|------|--------------|
| 1 | Packages | Installs scoop and the apps in `packages\scoopfile.json`, the winget apps in `packages\winget.txt` (PowerShell 7, WezTerm, Node 22, masir), and the PowerShell modules posh-git, Terminal-Icons and PSFzf |
| 2 | Shell | PowerShell 7 profile and starship prompt |
| 3 | WezTerm | `~\.wezterm.lua` |
| 4 | Neovim | Clones [nvim-config](https://github.com/bewithsnehasish/nvim-config) (`windows` branch) into `%LOCALAPPDATA%\nvim` |
| 5 | komorebi | komorebi layouts, bar, rules, whkd hotkeys, masir, and a login launcher that starts everything within a second |
| 6 | Herdr | Herdr config |
| 7 | Claude Code | Installs the CLI, then settings, status line and hooks |
| 8 | Git + SSH | `.gitconfig` and SSH host aliases (`github.com` = work, `github-pr` = personal). Keys are never stored here |
| 9 | Speed fixes | Login apps start without Windows' delay; power throttling off (one admin prompt, then restart) |
| 10 | Cleanup | Removes komorebi's empty leftover files and points you to the startup-apps list |

After a full run: restart Windows, open `nvim` once so it installs its plugins, and run `claude` once to sign in.

## Keep the repo up to date

After changing a config on this PC:

```powershell
.\setup.ps1 -Check   # which configs differ from the repo
.\setup.ps1 -Save    # copy this PC's configs and scoop app list into the repo, then commit and push
```

Paths under your user folder are stored as `{{HOME}}` placeholders, so the configs work for any Windows username.

## komorebi hotkeys (whkd)

| Keys | Action |
|------|--------|
| `alt + h / j / k / l` | Focus left / down / up / right |
| `alt + shift + h / j / k / l` | Move window |
| `alt + shift + enter` | Promote window to the main slot |
| `alt + 1 … 9` | Go to workspace |
| `alt + shift + 1 … 9` | Move window to workspace |
| `alt + left / down / up / right` | Stack with the neighbouring window |
| `alt + ;` | Unstack |
| `alt + [` / `alt + ]` | Cycle through a stack |
| `alt + - / =` | Shrink / grow width (`shift` for height) |
| `alt + t` | Float / tile the window |
| `alt + f` | Maximise |
| `alt + shift + f` | Monocle (one window fills the screen) |
| `alt + ctrl + t` | Always float windows like this one (saves a rule) |
| `alt + ctrl + i` | Always let komorebi ignore windows like this one (popups, PiP, call bars) |
| `alt + q` / `alt + m` | Close / minimise |
| `alt + x` / `alt + y` | Flip layout |
| `alt + shift + r` | Retile |
| `alt + p` | Pause komorebi |
| `alt + , / .` | Focus previous / next monitor (`shift` moves the window) |
| `alt + enter` | WezTerm |
| `alt + b` / `alt + s` | Helium / Slack (focus if open, else launch) |
| `alt + e` | Explorer |
| `alt + shift + b` | Restart the bar |
| `alt + o` / `alt + shift + o` | Reload whkd / komorebi config |

## Good to know

- **Window rules** live in `komorebi\komorebi.my-rules.json` and are loaded on top of the community `applications.json`. `alt + ctrl + t/i` adds to it; if a window's title changes every time, edit its rule to use `"matching_strategy": "Contains"`.
- **whkd runs commands through `cmd`**: about 0.1 s per hotkey instead of about 0.6 s with PowerShell. Don't put `# comments` at the end of command lines in `whkdrc`.
- **Monitor IDs** in `komorebi.*.json` (`display_index_preferences`) belong to this laptop's displays. On another machine, check `komorebic monitor-information` and update them.
- **This repo should stay private.** The Claude settings describe work systems.

## Troubleshooting

| Problem | Fix |
|---------|-----|
| komorebi not running after login | Run `~\komorebi-start.ps1` and check that the shortcut in `shell:startup` exists |
| Hotkeys do nothing | `alt + o`, or run `whkd` |
| Login apps slow again after a Windows update | Updates can remove the startup-delay setting; run step 9 again |
| Undo the speed fixes | `Remove-Item HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize -Recurse`, and in an admin window `reg delete HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling /v PowerThrottlingOff /f`, then restart |
| A step failed | The summary shows the error; the full output is in the log path it prints |
