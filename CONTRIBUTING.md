# Contributing to Skarp

Thank you for your interest in improving **Skarp**!

## Core Principles to Keep in Mind
1. **Single Source of Truth:**
   [`AGENTS.md`](AGENTS.md) is the master specification. All other agent configurations in `adapters/` derive from it.
2. **Never Let Adapters Drift:**
   Whenever you propose a change to the core principles or wording, update [`AGENTS.md`](AGENTS.md), then run the adapter synchronization script:
   ```bash
   python3 scripts/sync_adapters.py
   ```
   Verify that all adapters are in sync:
   ```bash
   python3 scripts/sync_adapters.py --check
   ```
3. **Keep It Surgical:**
   Avoid adding speculative abstractions or bloated rules. Respect the 4 core Karpathy principles: *Think Before Coding, Simplicity First, Surgical Changes, Goal-Driven Execution*.

## Submitting Pull Requests
1. Fork the repository.
2. Create a feature branch: `git checkout -b feature/my-improvement`.
3. Make your changes and verify:
   ```bash
   python3 scripts/sync_adapters.py --check
   ./install.sh --dir /tmp/test
   node bin/skarp.js --help
   ```
4. Commit your changes with clear commit messages.
5. Push to your branch and submit a Pull Request to `main`.
