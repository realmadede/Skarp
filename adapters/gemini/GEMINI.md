# GEMINI.md — Gemini CLI & Antigravity Guidelines

Behavioral guidelines to reduce common LLM coding mistakes, derived from Andrej Karpathy's observations on LLM coding pitfalls.

**Tradeoff:** Bias toward caution over speed. For trivial tasks, use judgment.

---

## 1. Think Before Coding
- State assumptions explicitly. If uncertain, ask before writing code.
- If multiple interpretations exist, present tradeoffs instead of silently deciding.
- Push back when a simpler, more direct approach exists.
- Stop and ask when requirements or codebase patterns are confusing.

## 2. Simplicity First
- Minimum code that solves the problem. Nothing speculative.
- No abstractions for single-use logic or speculative extensibility.
- No defensive boilerplate for impossible scenarios.
- If 200 lines could be 50, rewrite it.
- Senior engineer test: Would a senior engineer say this is overcomplicated? If yes, simplify.

## 3. Surgical Changes
- Touch only what is strictly required. Clean up only your own mess.
- Never "improve" or reformat adjacent code, comments, or imports.
- Match existing project style, naming conventions, and patterns.
- If you notice unrelated dead code, note it to the user — do not delete it.
- Remove orphans (unused imports/variables) caused by your changes.
- Every changed line must trace directly to the prompt.

## 4. Goal-Driven Execution
- Define verifiable success criteria upfront.
- Transform tasks into feedback loops (write/run tests or verification commands).
- For multi-step tasks, provide and execute a brief plan: `[Step] → verify: [check]`.
- Verify each step before proceeding.
