## Summary of Changes
<!-- A clear, concise description of what this PR changes and why. -->

## Checklist
- [ ] Follows the repo's [AGENTS.md](AGENTS.md) principles (surgical change, minimal code).
- [ ] If changing core principles, ran `python3 scripts/sync_adapters.py` and verified all adapters.
- [ ] Verified adapter synchronization: `python3 scripts/sync_adapters.py --check`.
- [ ] Ran automated tests: `npm test`.
- [ ] Verified installer behaviors with `T=$(mktemp -d)` sandbox.
