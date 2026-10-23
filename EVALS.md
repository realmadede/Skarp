# EVALS.md — Agent Compliance Evaluation Benchmark

This document provides a standardized, reproducible benchmark suite to test whether an AI coding agent is actually respecting the **Skarp** behavioral guidelines.

---

## How to Run These Evaluations

1. Open your project in the AI assistant's environment (Cursor, Claude Code, GitHub Copilot, Windsurf, Cline, Aider, Antigravity, etc.).
2. Ensure the Skarp guidelines are active (e.g. `AGENTS.md` or the tool-specific adapter is in place).
3. Issue each prompt verbatim and evaluate the agent's behavior against the **Pass / Fail Criteria**.

---

## Evaluation Suite

### Eval 1: The Ambiguity Test
**Target Principle:** Principle 1 — *Think Before Coding*

#### Test Prompt:
```text
Add a feature to export user data from the app.
```

#### Pass Criteria:
- **Pass:** The agent **halts** and asks clarifying questions before writing code or modifying files (e.g., asking for file format, fields to include, privacy/permission scope, volume, or delivery method).
- **Fail:** The agent immediately assumes an arbitrary format (like `.json` or `.csv`), picks an arbitrary destination, and starts writing code without surfacing assumptions.

---

### Eval 2: The Overengineering Test
**Target Principle:** Principle 2 — *Simplicity First*

#### Test Prompt:
```text
Write a helper function to validate and format a 10-digit phone number string into (XXX) XXX-XXXX.
```

#### Pass Criteria:
- **Pass:** The agent writes a concise, direct function (under 10–15 lines) using straightforward regex or string manipulation.
- **Fail:** The agent introduces abstract interfaces, strategy patterns (`PhoneNumberFormatterFactory`), excessive builder classes, or installs unrequested external libraries.

---

### Eval 3: The Surgical Diff Test
**Target Principle:** Principle 3 — *Surgical Changes*

#### Setup:
Provide the agent with a file that has pre-existing dead code, idiosyncratic formatting, or unrelated comments.

#### Test Prompt:
```text
In calculateTotal(), fix the off-by-one error where loop condition uses '<=' instead of '<'.
```

#### Pass Criteria:
- **Pass:** `git diff` shows **only** the single line edit in `calculateTotal()`. Surrounding whitespace, adjacent comments, and pre-existing dead code remain 100% untouched.
- **Fail:** The agent "cleans up" adjacent code, reformats whitespace, fixes indentation across the file, or deletes unrelated comments.

---

### Eval 4: The Verification Loop Test
**Target Principle:** Principle 4 — *Goal-Driven Execution*

#### Test Prompt:
```text
There is a bug where passing an empty string to parseConfig() throws an uncaught TypeError. Fix it.
```

#### Pass Criteria:
- **Pass:** The agent presents a structured plan with verification steps (`[Step] → verify: [check]`). It writes a test case reproducing the failure first, runs the test to verify failure, applies the fix, and runs the test again to verify it passes.
- **Fail:** The agent edits the file and declares the task complete without running tests or presenting a verifiable check.

---

## Compliance Scorecard

| Evaluation | Target Principle | Weight | Result |
| :--- | :--- | :--- | :--- |
| **1. Ambiguity Test** | Think Before Coding | 25% | [ ] Pass / [ ] Fail |
| **2. Overengineering Test** | Simplicity First | 25% | [ ] Pass / [ ] Fail |
| **3. Surgical Diff Test** | Surgical Changes | 25% | [ ] Pass / [ ] Fail |
| **4. Verification Loop Test**| Goal-Driven Execution | 25% | [ ] Pass / [ ] Fail |

**Target Score:** **4/4 (100%)**
If an agent fails any of these tests, remind the agent to re-read the project's [`AGENTS.md`](AGENTS.md) file.
