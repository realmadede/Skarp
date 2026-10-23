# Skarp — Universal Karpathy Guidelines for AI Coding Agents

[![CI](https://github.com/realmadede/Skarp/actions/workflows/ci.yml/badge.svg)](https://github.com/realmadede/Skarp/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/badge/version-1.0.0-green.svg)](https://github.com/realmadede/Skarp/releases)

> Universal behavioral guidelines to reduce common LLM coding mistakes across **any** AI agent, derived from [Andrej Karpathy's observations](https://x.com/karpathy/status/2015883857489522876) on AI coding pitfalls.

---

## The Problems

From Andrej Karpathy's analysis of LLM coding behaviors:

> *"The models make wrong assumptions on your behalf and just run along with them without checking. They don't manage their confusion, don't seek clarifications, don't surface inconsistencies, don't present tradeoffs, don't push back when they should."*

> *"They really like to overcomplicate code and APIs, bloat abstractions, don't clean up dead code... implement a bloated construction over 1000 lines when 100 would do."*

> *"They still sometimes change/remove comments and code they don't sufficiently understand as side effects, even if orthogonal to the task."*

---

## The Universal Solution

These pitfalls stem from fundamental LLM autoregressive characteristics, not from any single tool. **Skarp** provides a unified rule set designed to work across **all** major AI coding assistants and autonomous harnesses.

| Principle | Pitfall Addressed |
| :--- | :--- |
| **1. Think Before Coding** | Wrong assumptions, silent guessing, hidden confusion, unstated tradeoffs |
| **2. Simplicity First** | Overengineering, premature abstractions, speculative flexibility |
| **3. Surgical Changes** | Orthogonal refactoring, touched unrelated comments/formatting, diff bloat |
| **4. Goal-Driven Execution** | Vague instructions, unverified changes, absence of feedback loops |

---

## Supported Agents & Environments

Skarp comes with pre-configured adapters for all major tools located in [`adapters/`](adapters/):

| Agent / Tool | Config File Location | Ready Adapter |
| :--- | :--- | :--- |
| **Universal Standard** | `AGENTS.md` | [`adapters/universal/AGENTS.md`](adapters/universal/AGENTS.md) |
| **Claude Code** | `CLAUDE.md` | [`adapters/claude/CLAUDE.md`](adapters/claude/CLAUDE.md) |
| **Cursor** | `.cursor/rules/karpathy-guidelines.mdc` | [`adapters/cursor/karpathy-guidelines.mdc`](adapters/cursor/karpathy-guidelines.mdc) |
| **GitHub Copilot** | `.github/copilot-instructions.md` | [`adapters/copilot/copilot-instructions.md`](adapters/copilot/copilot-instructions.md) |
| **Windsurf (Cascade)** | `.windsurfrules` | [`adapters/windsurf/.windsurfrules`](adapters/windsurf/.windsurfrules) |
| **Cline / Roo Code** | `.clinerules` | [`adapters/cline/.clinerules`](adapters/cline/.clinerules) |
| **Aider** | `CONVENTIONS.md` | [`adapters/aider/CONVENTIONS.md`](adapters/aider/CONVENTIONS.md) |
| **Gemini CLI / Antigravity** | `GEMINI.md` | [`adapters/gemini/GEMINI.md`](adapters/gemini/GEMINI.md) |

---

## Quick Install

### Method 1: Interactive Zero-Dependency CLI (`npx skarp`)

Run anywhere via Node / npx:

```bash
# Interactive setup in the current project:
npx skarp

# Or specify agents directly:
npx skarp --agents cursor,claude,copilot

# Append to existing rules without overwriting:
npx skarp --append
```

---

### Method 2: Universal Bash Installer (Linux, macOS, WSL)

```bash
# Install for all supported agents in current directory:
curl -fsSL https://raw.githubusercontent.com/realmadede/Skarp/main/install.sh | bash

# Or install for specific agents only:
curl -fsSL https://raw.githubusercontent.com/realmadede/Skarp/main/install.sh | bash -s -- --agents cursor,claude,universal

# Merge into existing configuration files without overwriting:
curl -fsSL https://raw.githubusercontent.com/realmadede/Skarp/main/install.sh | bash -s -- --append
```

---

### Method 3: Windows PowerShell Installer (`install.ps1`)

In PowerShell on Windows:

```powershell
# Install for all agents in current directory:
irm https://raw.githubusercontent.com/realmadede/Skarp/main/install.ps1 | iex

# Or specify agents and append mode:
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/realmadede/Skarp/main/install.ps1))) -Agents cursor,claude -Append
```

---

### Method 4: One-Line Single File Download

**Universal standard (`AGENTS.md`):**
```bash
curl -o AGENTS.md https://raw.githubusercontent.com/realmadede/Skarp/main/AGENTS.md
```

**Claude Code (`CLAUDE.md`):**
```bash
curl -o CLAUDE.md https://raw.githubusercontent.com/realmadede/Skarp/main/adapters/claude/CLAUDE.md
```

**Cursor (`.cursor/rules/karpathy-guidelines.mdc`):**
```bash
mkdir -p .cursor/rules && curl -o .cursor/rules/karpathy-guidelines.mdc https://raw.githubusercontent.com/realmadede/Skarp/main/adapters/cursor/karpathy-guidelines.mdc
```

**GitHub Copilot (`.github/copilot-instructions.md`):**
```bash
mkdir -p .github && curl -o .github/copilot-instructions.md https://raw.githubusercontent.com/realmadede/Skarp/main/adapters/copilot/copilot-instructions.md
```

**Windsurf (`.windsurfrules`):**
```bash
curl -o .windsurfrules https://raw.githubusercontent.com/realmadede/Skarp/main/adapters/windsurf/.windsurfrules
```

---

## Appending to Existing Project Rules

If your repository already has an existing `CLAUDE.md`, `.windsurfrules`, or `.cursor/rules/karpathy-guidelines.mdc`, pass `--append` (or `-A`):

```bash
./install.sh --append
# or
npx skarp --append
```

Skarp wraps guidelines between safety markers:
```markdown
<!-- SKARP_GUIDELINES_START -->
... guidelines ...
<!-- SKARP_GUIDELINES_END -->
```
Running `--append` again in the future safely refreshes the Skarp block without altering any of your own custom team instructions.

---

## Uninstallation

To remove Skarp from your project at any time:

### Option 1: Automated 1-Command Uninstallation
Skarp automatically detects standalone files and removes them. If you used `--append`, it strips only the Skarp block while keeping your own custom rules 100% untouched:

```bash
# Via npx:
npx skarp --uninstall

# Via Bash (Linux / macOS / WSL):
curl -fsSL https://raw.githubusercontent.com/realmadede/Skarp/main/install.sh | bash -s -- --uninstall
# or locally:
./install.sh --uninstall

# Via Windows PowerShell:
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/realmadede/Skarp/main/install.ps1))) -Uninstall
```

### Option 2: Manual Removal
To delete standalone rule files manually:
```bash
rm -f AGENTS.md CLAUDE.md .cursor/rules/karpathy-guidelines.mdc .github/copilot-instructions.md .windsurfrules .clinerules CONVENTIONS.md GEMINI.md EXAMPLES.md
```
If you used `--append`, delete the block between `<!-- SKARP_GUIDELINES_START -->` and `<!-- SKARP_GUIDELINES_END -->` in your configuration file.

---

## The Four Principles in Detail

### 1. Think Before Coding
**Don't assume. Don't hide confusion. Surface tradeoffs.**

LLMs often pick an interpretation silently and run with it. This principle enforces explicit reasoning:
- **State assumptions explicitly** — If uncertain about intent or requirements, ask rather than guess.
- **Present multiple interpretations** — Don't pick silently when ambiguity exists.
- **Push back when warranted** — If a simpler or safer approach exists, recommend it.
- **Stop when confused** — If context is missing or contradictory, halt and clarify.

### 2. Simplicity First
**Minimum code that solves the problem. Nothing speculative.**

Combat the natural LLM tendency toward overengineering:
- No features beyond what was asked.
- No abstractions or generic wrappers for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No defensive boilerplate for impossible scenarios.
- If 200 lines could be 50, rewrite it.
- **The Senior Engineer Smell Test:** Would a senior engineer say this is overcomplicated? If yes, simplify.

### 3. Surgical Changes
**Touch only what you must. Clean up only your own mess.**

When editing existing codebases:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor components that aren't broken.
- Match existing style and naming, even if you would do it differently.
- If you notice unrelated dead code, mention it in text — don't delete it.
- Remove imports/variables/functions that **your** changes made unused.
- Don't remove pre-existing dead code unless asked.
- **The Diff Test:** Every changed line should trace directly to the user's request.

### 4. Goal-Driven Execution
**Define success criteria. Loop until verified.**

Transform imperative tasks into verifiable outcomes:

| Instead of... | Transform to... |
| :--- | :--- |
| *"Add validation"* | *"Write tests for invalid inputs, then implement until they pass"* |
| *"Fix the bug"* | *"Write a test reproducing the issue, then fix until it passes"* |
| *"Refactor X"* | *"Ensure tests pass before and after the refactor"* |

For multi-step tasks, state and execute a concise plan:
```text
1. [Step] → verify: [check / test command]
2. [Step] → verify: [check / test command]
3. [Step] → verify: [check / test command]
```

---

## Evaluating Your Agent (`EVALS.md`)

How do you know if your agent is actually respecting these guidelines? 

See [**`EVALS.md`**](EVALS.md) for a standardized 4-part compliance benchmark:
1. **The Ambiguity Test** (Tests Principle 1: Think Before Coding)
2. **The Overengineering Test** (Tests Principle 2: Simplicity First)
3. **The Surgical Diff Test** (Tests Principle 3: Surgical Changes)
4. **The Verification Loop Test** (Tests Principle 4: Goal-Driven Execution)

---

## Real-World Examples

See [**`EXAMPLES.md`**](EXAMPLES.md) for concrete before-and-after demonstrations of each principle in action.

---

## Contributing & Adapter Sync

To propose improvements to the guidelines or add new agents:
1. Edit the canonical [`AGENTS.md`](AGENTS.md).
2. Sync all adapters automatically:
   ```bash
   python3 scripts/sync_adapters.py
   python3 scripts/sync_adapters.py --check
   ```
See [**`CONTRIBUTING.md`**](CONTRIBUTING.md) for full guidelines.

---

## License

MIT © [realmadede](https://github.com/realmadede)
