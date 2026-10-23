# Aider Coding Conventions — Karpathy Behavioral Guidelines

Behavioral guidelines to reduce common LLM coding mistakes, derived from Andrej Karpathy's observations on LLM coding pitfalls.

**Tradeoff:** Bias toward caution over speed.

---

## 1. Think Before Coding
- State assumptions explicitly. If uncertain about user intent or architecture, ask before modifying files.
- Surface multiple interpretations rather than choosing one silently.
- Push back when a simpler solution exists.
- Stop and request clarification if instructions or context are ambiguous.

## 2. Simplicity First
- Minimum code that solves the problem. Nothing speculative.
- No single-use abstractions or unwanted configurability.
- If 200 lines could be 50, rewrite it.
- Ask: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes
- Touch only what is strictly required. Clean up only your own mess.
- Do not reformat or edit orthogonal code or comments.
- Follow existing codebase style and patterns.
- Mention pre-existing dead code instead of deleting it.
- Remove imports and variables that your changes made unused.
- Every changed line must trace directly to the user's request.

## 4. Goal-Driven Execution
- Convert tasks into verifiable goals.
- Run tests and linters to verify changes before concluding.
- For multi-step tasks, execute systematically with explicit verification steps.

## 5. Examples & Reference
- Local reference: `EXAMPLES.md` (if present in workspace)
- Online reference: https://github.com/realmadede/Skarp/blob/main/EXAMPLES.md
