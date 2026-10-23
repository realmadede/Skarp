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
SCRIPT_DIR=""
if [[ -n "${BASH_SOURCE[0]:-}" && -f "${BASH_SOURCE[0]}" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

TARGET_DIR="."
AGENTS_INPUT="all"
FORCE=false
SYMLINK=false
WITH_EXAMPLES=true
APPEND=false
UNINSTALL=false

ALL_AGENTS=("universal" "claude" "cursor" "copilot" "windsurf" "cline" "aider" "gemini" "codex")

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
                        Available: universal, claude, cursor, copilot, windsurf, cline, aider, gemini, codex, all
  -d, --dir <path>      Target project directory (default: current directory .)
  -e, --examples        Include EXAMPLES.md reference file (enabled by default)
  --no-examples         Skip copying EXAMPLES.md reference file
  -s, --symlink         Create symlinks instead of copying (requires local cloned repo)
  -A, --append          Append/merge guidelines into existing files instead of skipping
  -u, --uninstall       Uninstall guidelines from target directory (cleans merged blocks)
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
  codex       -> CODEX.md
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
    --no-examples)
      WITH_EXAMPLES=false
      shift
      ;;
    -e|--examples)
      WITH_EXAMPLES=true
      shift
      ;;
    -s|--symlink)
      SYMLINK=true
      shift
      ;;
    -A|--append)
      APPEND=true
      shift
      ;;
    -u|--uninstall)
      UNINSTALL=true
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

if [[ "$SYMLINK" == true && "$APPEND" == true ]]; then
  echo "Error: Cannot combine --symlink and --append." >&2
  exit 1
fi

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
  for agent in "${SELECTED_AGENTS[@]}"; do
    case "$agent" in
      universal|claude|cursor|copilot|windsurf|cline|aider|gemini|codex)
        ;;
      *)
        echo "Error: Unknown agent: $agent" >&2
        echo "Valid agents: universal, claude, cursor, copilot, windsurf, cline, aider, gemini, codex, all" >&2
        exit 1
        ;;
    esac
  done
fi

mkdir -p "$TARGET_DIR"
TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"

wrap_skarp_content() {
  local content="$1"
  local start_marker="<!-- SKARP_GUIDELINES_START -->"
  local end_marker="<!-- SKARP_GUIDELINES_END -->"

  if [[ "$content" == *"$start_marker"* ]]; then
    printf "%s\n" "$content"
    return
  fi

  python3 -c "
import sys, re
content = sys.argv[1]
start = sys.argv[2]
end = sys.argv[3]
m = re.match(r'^(---\r?\n.*?\r?\n---\r?\n)(.*)$', content, re.DOTALL)
if m:
    sys.stdout.write(f'{m.group(1)}\n{start}\n{m.group(2).strip()}\n{end}\n')
else:
    sys.stdout.write(f'{start}\n{content.strip()}\n{end}\n')
" "$content" "$start_marker" "$end_marker"
}

uninstall_file() {
  local rel_target="$1"
  local full_target="$TARGET_DIR/$rel_target"

  if [[ ! -f "$full_target" ]]; then
    return
  fi

  local start_marker="<!-- SKARP_GUIDELINES_START -->"
  local end_marker="<!-- SKARP_GUIDELINES_END -->"

  if ! grep -q "$start_marker" "$full_target"; then
    echo "  [SKIP] $rel_target not installed by Skarp"
    return
  fi

  local status
  status="$(python3 -c "
import sys, os, re
path, start, end = sys.argv[1], sys.argv[2], sys.argv[3]
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()
pattern = re.compile(rf'\n*{re.escape(start)}.*?{re.escape(end)}\n*', re.DOTALL)
remaining = pattern.sub('', text).strip()
body_without_fm = re.sub(r'^---\r?\n.*?\r?\n---\r?\n?', '', remaining, flags=re.DOTALL).strip()
if remaining == '' or body_without_fm == '':
    os.remove(path)
    sys.stdout.write('REMOVED')
else:
    with open(path, 'w', encoding='utf-8') as f:
        f.write(remaining + '\n')
    sys.stdout.write('CLEANED')
" "$full_target" "$start_marker" "$end_marker")"

  if [[ "$status" == "REMOVED" ]]; then
    echo "  [REMOVED] $rel_target"
  elif [[ "$status" == "CLEANED" ]]; then
    echo "  [CLEANED] $rel_target (removed Skarp block)"
  fi

  local parent_dir
  parent_dir="$(dirname "$full_target")"
  if [[ "$parent_dir" != "$TARGET_DIR" && "$parent_dir" == "$TARGET_DIR"* ]]; then
    rmdir "$parent_dir" 2>/dev/null || true
    local grand_parent
    grand_parent="$(dirname "$parent_dir")"
    if [[ "$grand_parent" != "$TARGET_DIR" && "$grand_parent" == "$TARGET_DIR"* ]]; then
      rmdir "$grand_parent" 2>/dev/null || true
    fi
  fi
}

if [[ "$UNINSTALL" == true ]]; then
  echo "Uninstalling Skarp guidelines from: $TARGET_DIR"
  for agent in "${SELECTED_AGENTS[@]}"; do
    case "$agent" in
      universal) uninstall_file "AGENTS.md" ;;
      claude)    uninstall_file "CLAUDE.md" ;;
      cursor)    uninstall_file ".cursor/rules/karpathy-guidelines.mdc" ;;
      copilot)   uninstall_file ".github/copilot-instructions.md" ;;
      windsurf)  uninstall_file ".windsurfrules" ;;
      cline)     uninstall_file ".clinerules" ;;
      aider)     uninstall_file "CONVENTIONS.md" ;;
      gemini)    uninstall_file "GEMINI.md" ;;
      codex)     uninstall_file "CODEX.md" ;;
    esac
  done
  uninstall_file "EXAMPLES.md"
  echo ""
  echo "Uninstall complete!"
  exit 0
fi

echo "Installing Skarp guidelines into: $TARGET_DIR"

install_file() {
  local agent_name="$1"
  local rel_target="$2"
  local adapter_path="$3"

  local full_target="$TARGET_DIR/$rel_target"
  local target_dir
  target_dir="$(dirname "$full_target")"
  mkdir -p "$target_dir"

  # Check if running from local repo with adapter available
  local local_source=""
  if [[ -n "$SCRIPT_DIR" && -f "$SCRIPT_DIR/$adapter_path" ]]; then
    local_source="$SCRIPT_DIR/$adapter_path"
  fi

  if [[ -L "$full_target" && "$APPEND" == true ]]; then
    echo "Error: Cannot --append to symlinked file $rel_target." >&2
    exit 1
  fi

  if [[ -f "$full_target" ]]; then
    if [[ "$APPEND" == true && "$rel_target" != "EXAMPLES.md" ]]; then
      local start_marker="<!-- SKARP_GUIDELINES_START -->"
      local end_marker="<!-- SKARP_GUIDELINES_END -->"

      local content=""
      if [[ -n "$local_source" ]]; then
        content="$(cat "$local_source")"
      else
        local remote_url="$REPO_RAW_URL/$adapter_path"
        if command -v curl >/dev/null 2>&1; then
          content="$(curl -fsSL "$remote_url")"
        elif command -v wget >/dev/null 2>&1; then
          content="$(wget -qO- "$remote_url")"
        fi
      fi

      if grep -q "<!-- SKARP_GUIDELINES_START -->" "$full_target"; then
        if ! command -v python3 >/dev/null 2>&1; then
          echo "Error: python3 is required to update $rel_target." >&2
          exit 1
        fi
        python3 -c "
import sys, re
path, content, start, end = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()
pattern = re.compile(rf'{re.escape(start)}.*?{re.escape(end)}', re.DOTALL)
block = f'{start}\n{content.strip()}\n{end}'
new_text = pattern.sub(lambda m: block, text)
with open(path, 'w', encoding='utf-8') as f:
    f.write(new_text)
" "$full_target" "$content" "$start_marker" "$end_marker"
        echo "  [UPDATED] $rel_target (refreshed existing Skarp block)"
        return
      else
        printf "\n\n%s\n%s\n%s\n" "$start_marker" "$content" "$end_marker" >> "$full_target"
        echo "  [MERGED] $rel_target (appended to existing file)"
        return
      fi
    elif [[ "$FORCE" != true ]]; then
      echo "  [SKIP] $rel_target already exists. Use --force to overwrite or --append to merge."
      return
    fi
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

  local raw_content=""
  if [[ -n "$local_source" ]]; then
    raw_content="$(cat "$local_source")"
  else
    local remote_url="$REPO_RAW_URL/$adapter_path"
    if command -v curl >/dev/null 2>&1; then
      raw_content="$(curl -fsSL "$remote_url")"
    elif command -v wget >/dev/null 2>&1; then
      raw_content="$(wget -qO- "$remote_url")"
    else
      echo "  [ERROR] Neither curl nor wget found to download $remote_url" >&2
      return 1
    fi
  fi

  local wrapped_content
  wrapped_content="$(wrap_skarp_content "$raw_content")"
  printf "%s\n" "$wrapped_content" > "$full_target"
  echo "  [OK]   $rel_target"
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
    codex)
      install_file "codex" "CODEX.md" "adapters/codex/CODEX.md"
      ;;
    *)
      echo "  [WARN] Unrecognized agent: $agent (skipping)"
      ;;
  esac
done

if [[ "$WITH_EXAMPLES" == true ]]; then
  install_file "examples" "EXAMPLES.md" "EXAMPLES.md"
fi

echo ""
echo "Installation complete! Skarp guidelines are now active for selected agents."
