# Skarp — Universal Karpathy Guidelines for AI Coding Agents

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

| Agent / Tool | Config File Location | Adapter Location |
| :--- | :--- | :--- |
| **Universal Standard** | `AGENTS.md` | [`adapters/universal/AGENTS.md`](adapters/universal/AGENTS.md) |
| **Claude Code** | `CLAUDE.md` | [`adapters/claude/CLAUDE.md`](adapters/claude/CLAUDE.md) |
| **Cursor** | `.cursor/rules/karpathy-guidelines.mdc` or `.cursorrules` | [`adapters/cursor/`](adapters/cursor/) |
| **GitHub Copilot** | `.github/copilot-instructions.md` | [`adapters/copilot/copilot-instructions.md`](adapters/copilot/copilot-instructions.md) |
| **Windsurf (Cascade)** | `.windsurfrules` | [`adapters/windsurf/.windsurfrules`](adapters/windsurf/.windsurfrules) |
| **Cline / Roo Code** | `.clinerules` | [`adapters/cline/.clinerules`](adapters/cline/.clinerules) |
| **Aider** | `CONVENTIONS.md` | [`adapters/aider/CONVENTIONS.md`](adapters/aider/CONVENTIONS.md) |
| **Gemini CLI / Antigravity** | `GEMINI.md` | [`adapters/gemini/GEMINI.md`](adapters/gemini/GEMINI.md) |

---

## Quick Install

### Method 1: Universal Installer Script (Recommended)

Run the installer directly into your target project:

```bash
# Install for all supported agents in current directory:
curl -fsSL https://raw.githubusercontent.com/realmadede/Skarp/main/install.sh | bash

# Or install for specific agents only:
curl -fsSL https://raw.githubusercontent.com/realmadede/Skarp/main/install.sh | bash -s -- --agents cursor,claude,universal

# Or install into a specific directory:
curl -fsSL https://raw.githubusercontent.com/realmadede/Skarp/main/install.sh | bash -s -- --dir /path/to/my-project --agents copilot,windsurf
```

If you have cloned this repository locally:
```bash
./install.sh --agents cursor,claude,copilot
```

### Method 2: One-Line Single File Download

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

**Cline / Roo Code (`.clinerules`):**
```bash
curl -o .clinerules https://raw.githubusercontent.com/realmadede/Skarp/main/adapters/cline/.clinerules
```

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

Strong success criteria let the agent loop independently toward a verified solution.

---

## Key Insight

From Andrej Karpathy:

> *"LLMs are exceptionally good at looping until they meet specific goals... Don't tell it what to do, give it success criteria and watch it go."*

---

## Real-World Examples

See [**`EXAMPLES.md`**](EXAMPLES.md) for detailed before-and-after examples of good vs. bad LLM behaviors across each principle.

---

## How to Know It's Working

You know these guidelines are working when:
- **Clean diffs:** Only requested changes appear in git diffs.
- **Zero bloat:** Code is minimal, straightforward, and readable.
- **Questions before mistakes:** Clarifying questions arrive before implementation rather than apologies after breakage.
- **Verified completion:** Changes pass tests or verification commands before being presented.

---

## Customization

These guidelines are designed to be merged with your project-specific instructions. Add a section at the bottom of your rules file:

```markdown
## Project-Specific Guidelines
- Use TypeScript strict mode.
- All API endpoints must have integration tests.
- Follow existing error patterns in `src/utils/errors.ts`.
```

---

## Tradeoff Note

These guidelines bias toward **caution over speed**. For trivial tasks (simple typo fixes, obvious one-liners), use judgment — not every minor change needs exhaustive verification loops.

---

## License

MIT © [realmadede](https://github.com/realmadede)
