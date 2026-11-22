# ── Cache directory setup for static init scripts ───────────
$script:cacheDir = "$HOME\.cache\powershell-init"
if (-not (Test-Path $script:cacheDir)) {
    New-Item -ItemType Directory -Path $script:cacheDir -Force | Out-Null
}

# ── Starship init ───────────────────────────────────────────
$script:starshipCache = "$script:cacheDir\starship_init.ps1"
if (-not (Test-Path $script:starshipCache)) {
    starship init powershell | Out-File -FilePath $script:starshipCache -Encoding utf8
}
. $script:starshipCache

# ── PSReadLine ──────────────────────────────────────────────
Set-PSReadLineOption -PredictionSource HistoryAndPlugin
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineOption -EditMode Emacs
Set-PSReadLineOption -HistorySearchCursorMovesToEnd
Set-PSReadLineOption -BellStyle None

Set-PSReadLineKeyHandler -Key Tab               -Function MenuComplete
Set-PSReadLineKeyHandler -Key UpArrow           -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow         -Function HistorySearchForward
Set-PSReadLineKeyHandler -Key Ctrl+d            -Function DeleteCharOrExit
Set-PSReadLineKeyHandler -Key Ctrl+w            -Function BackwardDeleteWord
Set-PSReadLineKeyHandler -Key Ctrl+LeftArrow    -Function BackwardWord
Set-PSReadLineKeyHandler -Key Ctrl+RightArrow   -Function ForwardWord

# ── zoxide ──────────────────────────────────────────────────
$script:zoxideCache = "$script:cacheDir\zoxide_init.ps1"
if (-not (Test-Path $script:zoxideCache)) {
    zoxide init powershell | Out-File -FilePath $script:zoxideCache -Encoding utf8
}
. $script:zoxideCache

# ── fzf ─────────────────────────────────────────────────────
$env:FZF_DEFAULT_OPTS = "--height 40% --layout=reverse --border --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8,fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc,marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 --preview 'bat --color=always --style=numbers {}' --preview-window=right:50%:wrap"
$env:FZF_DEFAULT_COMMAND = "fd --type f --hidden --follow --exclude .git"

# ── bat ─────────────────────────────────────────────────────
$env:BAT_THEME = "Catppuccin Mocha"

# ── Navigation ──────────────────────────────────────────────
function .. { Set-Location .. }
function ... { Set-Location ../.. }
function .... { Set-Location ../../.. }

# ── ls replacements (eza) ───────────────────────────────────
function ls  { eza --icons --group-directories-first @args }
function ll  { eza -la --icons --group-directories-first --git @args }
function la  { eza -a --icons @args }
function lt  { eza --tree --level=2 --icons --git @args }
function llt { eza --tree --level=3 --icons --git -la @args }

# ── Git shortcuts ───────────────────────────────────────────
function gs   { git status }
function ga   { git add @args }
function gaa  { git add --all }
function gc   { git commit -m @args }
function gca  { git commit --amend }
function gp   { git push }
function gpf  { git push --force-with-lease }
function gl   { git log --oneline --graph --decorate @args }
function gd   { git diff @args }
function gco  { git checkout @args }
function gb   { git branch @args }
function gst  { git stash }
function gstp { git stash pop }
function lg   { lazygit }

# ── Modern CLI replacements ─────────────────────────────────
function cat  { bat @args }
function grep { rg @args }
function find { fd @args }
function top  { btop }
function man  { tldr @args }

# ── Utilities ───────────────────────────────────────────────
function which   { Get-Command @args | Select-Object -ExpandProperty Source }
function touch   { New-Item -ItemType File @args }
function mk      { mkdir @args; Set-Location $args[-1] }
function reload  {
    Remove-Item "$script:cacheDir\*" -Force -ErrorAction SilentlyContinue
    . $PROFILE
}
function sysinfo { Get-ComputerInfo | Select-Object CsName, OsName, OsVersion, CsTotalPhysicalMemory }

# ── Editor ──────────────────────────────────────────────────
$env:EDITOR = "nvim"
function vim { nvim @args }
function vi { nvim @args }
Set-Alias v nvim

# ── Better errors ───────────────────────────────────────────
$ErrorView = 'ConciseView'

# ── Code Review Graph ───────────────────────────────────────
function crg { code-review-graph @args }

# ── LAZY LOADED MODULES (On-demand activation) ──────────────

# 1. PSFzf lazy loading
Set-PSReadLineKeyHandler -Key 'Ctrl+t' -ScriptBlock {
    if (-not (Get-Module -Name PSFzf)) {
        Import-Module PSFzf -ErrorAction SilentlyContinue
    }
    Invoke-FzfPsReadlineHandlerProvider
}

Set-PSReadLineKeyHandler -Key 'Ctrl+r' -ScriptBlock {
    if (-not (Get-Module -Name PSFzf)) {
        Import-Module PSFzf -ErrorAction SilentlyContinue
    }
    Invoke-FzfPsReadlineHandlerHistory
}

# 2. posh-git lazy loading
Register-ArgumentCompleter -CommandName git -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)
    Register-ArgumentCompleter -CommandName git -ScriptBlock $null
    Import-Module posh-git -ErrorAction SilentlyContinue
    return Expand-GitCommand -Command $wordToComplete -WordToComplete $wordToComplete -CommandAst $commandAst -CursorPosition $cursorPosition
}

function git {
    Register-ArgumentCompleter -CommandName git -ScriptBlock $null
    Remove-Item function:git -ErrorAction SilentlyContinue
    Import-Module posh-git -ErrorAction SilentlyContinue
    git @args
}

# 3. Terminal-Icons lazy loading
function Get-ChildItem {
    Remove-Item function:Get-ChildItem -ErrorAction SilentlyContinue
    Import-Module Terminal-Icons -ErrorAction SilentlyContinue
    Get-ChildItem @args
}

# 4. fnm — lazy load
$script:_fnmLoaded = $false
function _ensureFnm {
    if ($script:_fnmLoaded) { return }
    $script:_fnmLoaded = $true
    fnm env --use-on-cd | Out-String | Invoke-Expression
}
function node { _ensureFnm; Remove-Item function:node; node @args }
function npm  { _ensureFnm; Remove-Item function:npm;  npm @args }
function npx  { _ensureFnm; Remove-Item function:npx;  npx @args }
function fnm  { _ensureFnm; Remove-Item function:fnm;  fnm @args }

# Env
$env:PATH = "$HOME\.local\bin;$env:PATH"

# ── Claude on the friend's account (temporary, until own Max plan) ──
# Own login stays in ~/.claude; this one lives in ~/.claude-alt. Settings and CLAUDE.md follow the main copy.
function claude-alt {
    $alt = "$HOME\.claude-alt"
    Copy-Item "$HOME\.claude\settings.json", "$HOME\.claude\CLAUDE.md" $alt -Force
    $env:CLAUDE_CONFIG_DIR = $alt
    try { claude @args } finally { Remove-Item Env:CLAUDE_CONFIG_DIR -ErrorAction SilentlyContinue }
}

# PowerToys CommandNotFound module
Import-Module -Name Microsoft.WinGet.CommandNotFound -ErrorAction SilentlyContinue
#f45873b3-b655-43a6-b217-97c00aa0db58

# ── FIX PSMUX LATE PANE-SIZING SUGGESTION BUG ────────────────
if ($env:PSMUX_SESSION) {
    # Dynamically wraps your existing prompt (Starship)
    $script:__promptBase = $function:prompt
    function global:prompt {
        # Force recommendations and drop-down list mode back active
        Set-PSReadLineOption -PredictionSource HistoryAndPlugin
        Set-PSReadLineOption -PredictionViewStyle ListView
        & $script:__promptBase
    }
}

