#!/usr/bin/env bash
#
# Skarp — Universal Karpathy Guidelines Installer
# https://github.com/realmadede/Skarp
#
# Installs Andrej Karpathy-inspired behavioral guidelines for AI coding agents.
# Supports Universal AGENTS.md, Claude Code, Cursor, GitHub Copilot, Windsurf, Cline, Aider, Gemini CLI, etc.
#

set -euo pipefail

REPO_RAW_URL="https://raw.githubusercontent.com/realmadede/Skarp/main"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || echo "")"

TARGET_DIR="."
AGENTS_INPUT="all"
FORCE=false
SYMLINK=false

ALL_AGENTS=("universal" "claude" "cursor" "copilot" "windsurf" "cline" "aider" "gemini")

print_banner() {
  cat <<'EOF'
   _____ _                      
  / ____| |                     
 | (___ | | ____ _ _ __ _ __    
  \___ \| |/ / _` | '__| '_ \   
  ____) |   < (_| | |  | |_) |  
 |_____/|_|\_\__,_|_|  | .__/   
                       | |      
                       |_|      
  Universal Karpathy Guidelines for AI Coding Agents
EOF
}

usage() {
  print_banner
  cat <<EOF

Usage:
  install.sh [options]

Options:
  -a, --agents <list>   Comma-separated list of agents to install (default: all)
                        Available: universal, claude, cursor, copilot, windsurf, cline, aider, gemini, all
  -d, --dir <path>      Target project directory (default: .)
  -s, --symlink         Create symlinks instead of copying (requires local cloned repo)
  -f, --force           Overwrite existing rule files without prompting
  -l, --list            List all supported agents and their target files
  -h, --help            Show this help message

Examples:
  # Install for all supported agents in current directory:
  ./install.sh

  # Install via curl:
  curl -fsSL https://raw.githubusercontent.com/realmadede/Skarp/main/install.sh | bash

  # Install only for Cursor and Claude:
  ./install.sh --agents cursor,claude

  # Install into a specific project folder:
  ./install.sh --dir /path/to/my-project --agents copilot,windsurf,universal

EOF
  exit 0
}

list_agents() {
  cat <<EOF
Supported Agents & Target Files:
  universal   -> AGENTS.md
  claude      -> CLAUDE.md
  cursor      -> .cursor/rules/karpathy-guidelines.mdc
  copilot     -> .github/copilot-instructions.md
  windsurf    -> .windsurfrules
  cline       -> .clinerules
  aider       -> CONVENTIONS.md
  gemini      -> GEMINI.md
EOF
  exit 0
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -a|--agents)
      AGENTS_INPUT="$2"
      shift 2
      ;;
    -d|--dir)
      TARGET_DIR="$2"
      shift 2
      ;;
    -s|--symlink)
      SYMLINK=true
      shift
      ;;
    -f|--force)
      FORCE=true
      shift
      ;;
    -l|--list)
      list_agents
      ;;
    -h|--help)
      usage
      ;;
    *)
      echo "Error: Unknown argument: $1" >&2
      echo "Run with -h or --help for usage information." >&2
      exit 1
      ;;
  esac
done

# Resolve agent list
SELECTED_AGENTS=()
if [[ "$AGENTS_INPUT" == "all" ]]; then
  SELECTED_AGENTS=("${ALL_AGENTS[@]}")
else
  IFS=',' read -ra ADDR <<< "$AGENTS_INPUT"
  for agent in "${ADDR[@]}"; do
    agent_trimmed="$(echo "$agent" | tr '[:upper:]' '[:lower:]' | xargs)"
    if [[ -n "$agent_trimmed" ]]; then
      SELECTED_AGENTS+=("$agent_trimmed")
    fi
  done
fi

mkdir -p "$TARGET_DIR"
TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"

echo "Installing Skarp guidelines into: $TARGET_DIR"

install_file() {
  local agent_name="$1"
  local rel_target="$2"
  local adapter_path="$3"

  local full_target="$TARGET_DIR/$rel_target"
  local target_dir
  target_dir="$(dirname "$full_target")"
  mkdir -p "$target_dir"

  if [[ -f "$full_target" && "$FORCE" != true ]]; then
    echo "  [SKIP] $rel_target already exists. Use --force to overwrite."
    return
  fi

  # Check if running from local repo with adapter available
  local local_source=""
  if [[ -n "$SCRIPT_DIR" && -f "$SCRIPT_DIR/$adapter_path" ]]; then
    local_source="$SCRIPT_DIR/$adapter_path"
  fi

  if [[ "$SYMLINK" == true ]]; then
    if [[ -n "$local_source" ]]; then
      ln -sf "$local_source" "$full_target"
      echo "  [LINK] $rel_target -> $local_source"
      return
    else
      echo "  [WARN] Cannot symlink when installing remotely or local adapter not found. Falling back to copy."
    fi
  fi

  if [[ -n "$local_source" ]]; then
    cp "$local_source" "$full_target"
    echo "  [OK]   $rel_target (from local $adapter_path)"
  else
    local remote_url="$REPO_RAW_URL/$adapter_path"
    if command -v curl >/dev/null 2>&1; then
      curl -fsSL "$remote_url" -o "$full_target"
      echo "  [OK]   $rel_target (downloaded from remote)"
    elif command -v wget >/dev/null 2>&1; then
      wget -qO "$full_target" "$remote_url"
      echo "  [OK]   $rel_target (downloaded from remote)"
    else
      echo "  [ERROR] Neither curl nor wget found to download $remote_url" >&2
      return 1
    fi
  fi
}

for agent in "${SELECTED_AGENTS[@]}"; do
  case "$agent" in
    universal)
      install_file "universal" "AGENTS.md" "adapters/universal/AGENTS.md"
      ;;
    claude)
      install_file "claude" "CLAUDE.md" "adapters/claude/CLAUDE.md"
      ;;
    cursor)
      install_file "cursor" ".cursor/rules/karpathy-guidelines.mdc" "adapters/cursor/karpathy-guidelines.mdc"
      ;;
    copilot)
      install_file "copilot" ".github/copilot-instructions.md" "adapters/copilot/copilot-instructions.md"
      ;;
    windsurf)
      install_file "windsurf" ".windsurfrules" "adapters/windsurf/.windsurfrules"
      ;;
    cline)
      install_file "cline" ".clinerules" "adapters/cline/.clinerules"
      ;;
    aider)
      install_file "aider" "CONVENTIONS.md" "adapters/aider/CONVENTIONS.md"
      ;;
    gemini)
      install_file "gemini" "GEMINI.md" "adapters/gemini/GEMINI.md"
      ;;
    *)
      echo "  [WARN] Unrecognized agent: $agent (skipping)"
      ;;
  esac
done

echo ""
echo "Installation complete! Skarp guidelines are now active for selected agents."
