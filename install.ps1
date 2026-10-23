<#
.SYNOPSIS
    Skarp — Universal Karpathy Guidelines Installer for Windows (PowerShell)
    https://github.com/realmadede/Skarp

.DESCRIPTION
    Installs Andrej Karpathy-inspired behavioral guidelines for AI coding agents.
    Supports Universal AGENTS.md, Claude Code, Cursor, GitHub Copilot, Windsurf, Cline, Aider, Gemini CLI, etc.

.EXAMPLE
    # Install for all supported agents in current directory:
    .\install.ps1

.EXAMPLE
    # Install via remote one-liner:
    irm https://raw.githubusercontent.com/realmadede/Skarp/main/install.ps1 | iex

.EXAMPLE
    # Install for specific agents and append to existing files:
    .\install.ps1 -Agents cursor,claude -Append
#>

[CmdletBinding()]
param (
    [Alias("agent")]
    [string[]]$Agents = @("all"),

    [Alias("d")]
    [string]$Dir = ".",

    [Alias("f")]
    [switch]$Force,

    [Alias("s")]
    [switch]$Symlink,

    [Alias("app")]
    [switch]$Append,

    [Alias("u")]
    [switch]$Uninstall,

    [switch]$NoExamples,

    [Alias("l")]
    [switch]$List,

    [Alias("h")]
    [switch]$Help
)

$RepoRawUrl = "https://raw.githubusercontent.com/realmadede/Skarp/main"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path 2>$null

$AllAgents = @("universal", "claude", "cursor", "copilot", "windsurf", "cline", "aider", "gemini", "codex")

if ($Help) {
    Write-Host @"
   _____ _                      
  / ____| |                     
 | (___ | | ____ _ _ __ _ __    
  \___ \| |/ / _` | '__| '_ \   
  ____) |   < (_| | |  | |_) |  
 |_____/|_|\_\__,_|_|  | .__/   
                       | |      
                       |_|      
  Universal Karpathy Guidelines for AI Coding Agents (Windows PowerShell)

Usage:
  install.ps1 [-Agents <list>] [-Dir <path>] [-Force] [-Symlink] [-Append] [-NoExamples] [-List] [-Help]

Options:
  -Agents, -agent   Comma-separated list or array of agents to install (default: all)
                    Available: universal, claude, cursor, copilot, windsurf, cline, aider, gemini, codex, all
  -Dir, -d          Target project directory (default: .)
  -Symlink, -s      Create symlinks instead of copying (requires local cloned repo)
  -Append, -app     Append/merge guidelines into existing files instead of skipping
  -Uninstall, -u    Uninstall guidelines from target directory (cleans merged blocks)
  -Force, -f        Overwrite existing rule files without prompting
  -NoExamples       Skip copying EXAMPLES.md reference file
  -List, -l         List supported agents and their target files
  -Help, -h         Show this help message
"@
    exit 0
}

if ($List) {
    Write-Host @"
Supported Agents & Target Files:
  universal   -> AGENTS.md
  claude      -> CLAUDE.md
  cursor      -> .cursor\rules\karpathy-guidelines.mdc
  copilot     -> .github\copilot-instructions.md
  windsurf    -> .windsurfrules
  cline       -> .clinerules
  aider       -> CONVENTIONS.md
  gemini      -> GEMINI.md
  codex       -> CODEX.md
"@
    exit 0
}

# Resolve selected agents
$Selected = @()
if ($Agents -contains "all") {
    $Selected = $AllAgents
} else {
    foreach ($item in $Agents) {
        $parts = $item.Split(",")
        foreach ($p in $parts) {
            $trimmed = $p.Trim().ToLower()
            if ($trimmed -and $trimmed -ne "all") {
                $Selected += $trimmed
            }
        }
    }
    foreach ($agent in $Selected) {
        if ($AllAgents -notcontains $agent) {
            Write-Error "Unknown agent: $agent. Valid agents: $($AllAgents -join ', '), all"
            exit 1
        }
    }
}

if ($Symlink -and $Append) {
    Write-Error "Cannot combine -Symlink and -Append."
    exit 1
}

$ResolvedTargetDir = (Resolve-Path -Path $Dir -ErrorAction SilentlyContinue)
if (-not $ResolvedTargetDir) {
    New-Item -ItemType Directory -Path $Dir -Force | Out-Null
    $ResolvedTargetDir = (Resolve-Path -Path $Dir).Path
} else {
    $ResolvedTargetDir = $ResolvedTargetDir.Path
}

$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Wrap-SkarpContent {
    param ([string]$Content)
    $StartMarker = "<!-- SKARP_GUIDELINES_START -->"
    $EndMarker = "<!-- SKARP_GUIDELINES_END -->"

    if ($Content.Contains($StartMarker)) {
        return $Content
    }

    if ($Content -match "^(---[\r\n]+[\s\S]*?[\r\n]+---[\r\n]*)([\s\S]*)$") {
        $Frontmatter = $Matches[1]
        $Body = $Matches[2].Trim()
        return "$Frontmatter`r`n$StartMarker`r`n$Body`r`n$EndMarker`r`n"
    } else {
        return "$StartMarker`r`n$($Content.Trim())`r`n$EndMarker`r`n"
    }
}

function Uninstall-SkarpFile {
    param ([string]$RelTarget)

    $FullTarget = Join-Path $ResolvedTargetDir $RelTarget
    if (-not (Test-Path $FullTarget)) { return }

    $StartMarker = "<!-- SKARP_GUIDELINES_START -->"
    $EndMarker = "<!-- SKARP_GUIDELINES_END -->"
    $ExistingText = Get-Content -Path $FullTarget -Raw -Encoding UTF8

    if (-not ($ExistingText -match [regex]::Escape($StartMarker))) {
        Write-Host "  [SKIP]    $RelTarget not installed by Skarp"
        return
    }

    $Pattern = "\r?\n*" + [regex]::Escape($StartMarker) + ".*?" + [regex]::Escape($EndMarker) + "\r?\n*"
    $Remaining = [regex]::Replace($ExistingText, $Pattern, "", [System.Text.RegularExpressions.RegexOptions]::Singleline).Trim()
    $BodyWithoutFm = [regex]::Replace($Remaining, "^---[\r\n]+[\s\S]*?[\r\n]+---[\r\n]*", "", [System.Text.RegularExpressions.RegexOptions]::Singleline).Trim()

    if ($Remaining -eq "" -or $BodyWithoutFm -eq "") {
        Remove-Item -Path $FullTarget -Force
        Write-Host "  [REMOVED] $RelTarget"
    } else {
        [System.IO.File]::WriteAllText($FullTarget, ($Remaining + "`r`n"), $Utf8NoBom)
        Write-Host "  [CLEANED] $RelTarget (removed Skarp block)"
    }

    $ParentFolder = Split-Path -Parent $FullTarget
    if ($ParentFolder -ne $ResolvedTargetDir -and (Test-Path $ParentFolder)) {
        $Remaining = Get-ChildItem -Path $ParentFolder -Force -Recurse
        if (-not $Remaining) {
            Remove-Item -Path $ParentFolder -Force -Recurse -ErrorAction SilentlyContinue
        }
    }
}

if ($Uninstall) {
    Write-Host "Uninstalling Skarp guidelines from: $ResolvedTargetDir"
    foreach ($agent in $Selected) {
        switch ($agent) {
            "universal" { Uninstall-SkarpFile "AGENTS.md" }
            "claude"    { Uninstall-SkarpFile "CLAUDE.md" }
            "cursor"    { Uninstall-SkarpFile ".cursor/rules/karpathy-guidelines.mdc" }
            "copilot"   { Uninstall-SkarpFile ".github/copilot-instructions.md" }
            "windsurf"  { Uninstall-SkarpFile ".windsurfrules" }
            "cline"     { Uninstall-SkarpFile ".clinerules" }
            "aider"     { Uninstall-SkarpFile "CONVENTIONS.md" }
            "gemini"    { Uninstall-SkarpFile "GEMINI.md" }
            "codex"     { Uninstall-SkarpFile "CODEX.md" }
        }
    }
    Uninstall-SkarpFile "EXAMPLES.md"
    Write-Host ""
    Write-Host "Uninstall complete!"
    exit 0
}

Write-Host "Installing Skarp guidelines into: $ResolvedTargetDir"

function Install-SkarpFile {
    param (
        [string]$AgentName,
        [string]$RelTarget,
        [string]$AdapterPath
    )

    $FullTarget = Join-Path $ResolvedTargetDir $RelTarget
    $TargetFolder = Split-Path -Parent $FullTarget
    if (-not (Test-Path $TargetFolder)) {
        New-Item -ItemType Directory -Path $TargetFolder -Force | Out-Null
    }

    $LocalSource = $null
    if ($ScriptDir -and (Test-Path (Join-Path $ScriptDir $AdapterPath))) {
        $LocalSource = (Join-Path $ScriptDir $AdapterPath)
    }

    $targetItem = Get-Item $FullTarget -ErrorAction SilentlyContinue
    if ($targetItem -and $targetItem.LinkType -and $Append) {
        Write-Error "Error: Cannot -Append to symlinked file: $RelTarget"
        exit 1
    }

    if ($Symlink) {
        if (-not $LocalSource) {
            Write-Error "Error: -Symlink requires local repository files, but $AdapterPath was not found."
            exit 1
        }
        if (Test-Path $FullTarget) {
            if ($Force) {
                Remove-Item -Force $FullTarget
            } else {
                Write-Host "  [SKIP]    $RelTarget already exists. Use -Force to overwrite."
                return
            }
        }
        New-Item -ItemType SymbolicLink -Path $FullTarget -Value $LocalSource -Force | Out-Null
        Write-Host "  [LINK]    $RelTarget -> $LocalSource"
        return
    }

    $Content = ""
    if ($LocalSource) {
        $Content = Get-Content -Path $LocalSource -Raw -Encoding UTF8
    } else {
        $RemoteUrl = "$RepoRawUrl/$AdapterPath"
        try {
            $Content = (Invoke-RestMethod -Uri $RemoteUrl -UseBasicParsing)
        } catch {
            Write-Error "Failed to download $RemoteUrl : $_"
            return
        }
    }

    if (Test-Path $FullTarget) {
        if ($Append -and ($RelTarget -ne "EXAMPLES.md")) {
            $StartMarker = "<!-- SKARP_GUIDELINES_START -->"
            $EndMarker = "<!-- SKARP_GUIDELINES_END -->"
            $ExistingText = Get-Content -Path $FullTarget -Raw -Encoding UTF8

            if ($ExistingText -match [regex]::Escape($StartMarker)) {
                $Pattern = [regex]::Escape($StartMarker) + ".*?" + [regex]::Escape($EndMarker)
                $Replacement = "$StartMarker`r`n$Content`r`n$EndMarker"
                $NewText = [regex]::Replace($ExistingText, $Pattern, $Replacement, [System.Text.RegularExpressions.RegexOptions]::Singleline)
                [System.IO.File]::WriteAllText($FullTarget, $NewText, $Utf8NoBom)
                Write-Host "  [UPDATED] $RelTarget (refreshed existing Skarp block)"
                return
            } else {
                $NewText = "$ExistingText`r`n`r`n$StartMarker`r`n$Content`r`n$EndMarker"
                [System.IO.File]::WriteAllText($FullTarget, $NewText, $Utf8NoBom)
                Write-Host "  [MERGED]  $RelTarget (appended to existing file)"
                return
            }
        } elseif (-not $Force) {
            Write-Host "  [SKIP]    $RelTarget already exists. Use -Force to overwrite or -Append to merge."
            return
        }
    }

    $Wrapped = Wrap-SkarpContent $Content
    [System.IO.File]::WriteAllText($FullTarget, $Wrapped, $Utf8NoBom)
    Write-Host "  [OK]      $RelTarget"
}

foreach ($agent in $Selected) {
    switch ($agent) {
        "universal" { Install-SkarpFile "universal" "AGENTS.md" "adapters/universal/AGENTS.md" }
        "claude"    { Install-SkarpFile "claude" "CLAUDE.md" "adapters/claude/CLAUDE.md" }
        "cursor"    { Install-SkarpFile "cursor" ".cursor/rules/karpathy-guidelines.mdc" "adapters/cursor/karpathy-guidelines.mdc" }
        "copilot"   { Install-SkarpFile "copilot" ".github/copilot-instructions.md" "adapters/copilot/copilot-instructions.md" }
        "windsurf"  { Install-SkarpFile "windsurf" ".windsurfrules" "adapters/windsurf/.windsurfrules" }
        "cline"     { Install-SkarpFile "cline" ".clinerules" "adapters/cline/.clinerules" }
        "aider"     { Install-SkarpFile "aider" "CONVENTIONS.md" "adapters/aider/CONVENTIONS.md" }
        "gemini"    { Install-SkarpFile "gemini" "GEMINI.md" "adapters/gemini/GEMINI.md" }
        "codex"     { Install-SkarpFile "codex" "CODEX.md" "adapters/codex/CODEX.md" }
        default     { Write-Warning "Unrecognized agent: $agent (skipping)" }
    }
}

if (-not $NoExamples) {
    Install-SkarpFile "examples" "EXAMPLES.md" "EXAMPLES.md"
}

Write-Host ""
Write-Host "Installation complete! Skarp guidelines are now active for selected agents."
