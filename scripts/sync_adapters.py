#!/usr/bin/env python3
"""
scripts/sync_adapters.py — Skarp Adapter Synchronization Tool

Extracts the core principles from the canonical AGENTS.md and renders all agent adapters.
Usage:
    python3 scripts/sync_adapters.py          # Regenerates all adapters from AGENTS.md
    python3 scripts/sync_adapters.py --check  # Validates all adapters (exits non-zero if out of sync)
"""

import sys
import os
import re
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
AGENTS_MD_PATH = REPO_ROOT / "AGENTS.md"
ADAPTERS_DIR = REPO_ROOT / "adapters"

def extract_principles(agents_md_text: str) -> str:
    """Extract sections 1 through 4 from AGENTS.md."""
    match = re.search(r'(## 1\. Think Before Coding[\s\S]*?)(?=\n## 5\. Summary of Working Behavior|\Z)', agents_md_text)
    if not match:
        raise ValueError("Could not find principles 1-4 in AGENTS.md")
    return match.group(1).strip()

def extract_summary(agents_md_text: str) -> str:
    """Extract section 5 (Summary of Working Behavior) from AGENTS.md."""
    match = re.search(r'(## 5\. Summary of Working Behavior[\s\S]*?)(?=\n## 6\. Examples & Reference|\Z)', agents_md_text)
    if not match:
        return ""
    return match.group(1).strip()

def extract_examples(agents_md_text: str) -> str:
    """Extract section 6 (Examples & Reference) from AGENTS.md."""
    match = re.search(r'(## 6\. Examples & Reference[\s\S]*?)$', agents_md_text)
    if not match:
        return ""
    return match.group(1).strip()

def generate_adapters(agents_text: str) -> dict:
    """Generate expected content for each adapter file using AGENTS.md as single source of truth."""
    principles = extract_principles(agents_text)
    summary = extract_summary(agents_text)
    examples = extract_examples(agents_text)

    # Universal AGENTS.md is identical to root AGENTS.md
    universal_agents = agents_text.strip() + "\n"

    # Claude Code
    claude = f"""# CLAUDE.md — Claude Code Guidelines

Behavioral guidelines to reduce common LLM coding mistakes, derived from Andrej Karpathy's observations on LLM coding pitfalls. Merge with project-specific instructions as needed.

**Tradeoff:** These guidelines intentionally bias toward **caution over speed**. For trivial tasks, use judgment.

---

{principles}

---

{summary}

---

{examples}
"""

    # Cursor .mdc
    cursor_mdc = f"""---
description: Behavioral guidelines to reduce common LLM coding mistakes. Use when writing, reviewing, or refactoring code to avoid overcomplication, make surgical changes, surface assumptions, and define verifiable success criteria.
alwaysApply: true
---

# Cursor Behavioral Guidelines

Behavioral guidelines to reduce common LLM coding mistakes, derived from Andrej Karpathy's observations on LLM coding pitfalls. Merge with project-specific instructions as needed.

**Tradeoff:** These guidelines intentionally bias toward **caution over speed**. For trivial tasks, use judgment.

---

{principles}

---

{summary}

---

{examples}
"""

    # GitHub Copilot
    copilot = f"""# GitHub Copilot Instructions — Karpathy Behavioral Guidelines

Behavioral guidelines to reduce common LLM coding mistakes, derived from Andrej Karpathy's observations on LLM coding pitfalls. Merge with project-specific instructions as needed.

**Tradeoff:** These guidelines intentionally bias toward **caution over speed**. For trivial tasks, use judgment.

---

{principles}

---

{summary}

---

{examples}
"""

    # Windsurf
    windsurf = f"""# Windsurf Cascade Rules — Karpathy Behavioral Guidelines

Behavioral guidelines to reduce common LLM coding mistakes, derived from Andrej Karpathy's observations on LLM coding pitfalls. Merge with project-specific instructions as needed.

**Tradeoff:** These guidelines intentionally bias toward **caution over speed**. For trivial tasks, use judgment.

---

{principles}

---

{summary}

---

{examples}
"""

    # Cline / Roo Code
    cline = f"""# Cline / Roo Code Rules — Karpathy Behavioral Guidelines

Behavioral guidelines to reduce common LLM coding mistakes, derived from Andrej Karpathy's observations on LLM coding pitfalls. Merge with project-specific instructions as needed.

**Tradeoff:** These guidelines intentionally bias toward **caution over speed**. For trivial tasks, use judgment.

---

{principles}

---

{summary}

---

{examples}
"""

    # Aider
    aider = f"""# Aider Coding Conventions — Karpathy Behavioral Guidelines

Behavioral guidelines to reduce common LLM coding mistakes, derived from Andrej Karpathy's observations on LLM coding pitfalls.

**Tradeoff:** These guidelines intentionally bias toward **caution over speed**. For trivial tasks, use judgment.

---

{principles}

---

{summary}

---

{examples}
"""

    # Gemini CLI / Antigravity
    gemini = f"""# GEMINI.md — Gemini CLI & Antigravity Guidelines

Behavioral guidelines to reduce common LLM coding mistakes, derived from Andrej Karpathy's observations on LLM coding pitfalls.

**Tradeoff:** These guidelines intentionally bias toward **caution over speed**. For trivial tasks, use judgment.

---

{principles}

---

{summary}

---

{examples}
"""

    adapters = {
        ADAPTERS_DIR / "universal" / "AGENTS.md": universal_agents,
        ADAPTERS_DIR / "claude" / "CLAUDE.md": claude.strip() + "\n",
        ADAPTERS_DIR / "cursor" / "karpathy-guidelines.mdc": cursor_mdc.strip() + "\n",
        ADAPTERS_DIR / "copilot" / "copilot-instructions.md": copilot.strip() + "\n",
        ADAPTERS_DIR / "windsurf" / ".windsurfrules": windsurf.strip() + "\n",
        ADAPTERS_DIR / "cline" / ".clinerules": cline.strip() + "\n",
        ADAPTERS_DIR / "aider" / "CONVENTIONS.md": aider.strip() + "\n",
        ADAPTERS_DIR / "gemini" / "GEMINI.md": gemini.strip() + "\n",
    }

    return adapters

def main():
    check_mode = "--check" in sys.argv

    if not AGENTS_MD_PATH.exists():
        print(f"Error: {AGENTS_MD_PATH} not found.", file=sys.stderr)
        sys.exit(1)

    agents_text = AGENTS_MD_PATH.read_text(encoding="utf-8")
    expected_adapters = generate_adapters(agents_text)

    has_diff = False

    for target_path, expected_content in expected_adapters.items():
        target_path.parent.mkdir(parents=True, exist_ok=True)
        if not target_path.exists():
            print(f"[MISSING] {target_path.relative_to(REPO_ROOT)}")
            has_diff = True
            if not check_mode:
                target_path.write_text(expected_content, encoding="utf-8")
                print(f"  -> Created {target_path.relative_to(REPO_ROOT)}")
            continue

        actual_content = target_path.read_text(encoding="utf-8")
        if actual_content.strip() != expected_content.strip():
            print(f"[OUT OF SYNC] {target_path.relative_to(REPO_ROOT)}")
            has_diff = True
            if not check_mode:
                target_path.write_text(expected_content, encoding="utf-8")
                print(f"  -> Updated {target_path.relative_to(REPO_ROOT)}")
        else:
            if not check_mode:
                print(f"[OK] {target_path.relative_to(REPO_ROOT)}")

    if check_mode:
        if has_diff:
            print("\nError: One or more adapters are out of sync with AGENTS.md. Run 'python3 scripts/sync_adapters.py' to sync.")
            sys.exit(1)
        else:
            print("All adapters are perfectly in sync with AGENTS.md.")
            sys.exit(0)

if __name__ == "__main__":
    main()
