# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Fixed
- **Uninstall safety**: Prevent uninstall from deleting unmanaged user files; only strip content within `<!-- SKARP_GUIDELINES_START -->` / `<!-- SKARP_GUIDELINES_END -->` markers across all installers (`install.sh`, `install.ps1`, `bin/skarp.js`).
- **Append deduplication**: Prevent guideline duplication when `--append` is executed on files that already contain a Skarp block across all installers.
- **Python regex handling in `install.sh`**: Use replacer function to safely handle backslashes (`\d`, `\1`) during block replacement, remove silent append fallback, and ensure errors surface properly during install and uninstall.
- **Node CLI string replacement**: Use replacement callback function in `bin/skarp.js` to avoid special pattern expansion (`$&`, `$1`).
- **CLI argument handling**: Validate arguments in `bin/skarp.js` and `install.sh`; fail with non-zero exit on missing values, unknown flags, and unrecognized agent names.
- **PowerShell script compatibility**: Correct parameter alias help to `-agent` and `-app`; ensure UTF-8 without BOM encoding on Windows PowerShell.
- **Piped bash execution (`curl | bash`)**: Fix `SCRIPT_DIR` fallback so piped execution does not treat the current working directory as the local repository.
- **Symlink protection**: Prevent `--append` from writing through symlinked targets and modifying source adapters in `install.sh`.

### Added
- **License**: Add MIT license file.
- **Repository guidelines & hygiene**: Add `.gitignore`, `SECURITY.md`, and `CHANGELOG.md`.
- **Packaging**: Specify `files` and `engines` (`>=18`) in `package.json`.
- **Automated test suite & CI coverage**: Add `scripts/test.js` (`npm test`) and expand GitHub Actions workflow with regression tests for installer bugs, user file survival, single-marker append, and invalid arguments across Linux, macOS, and Windows.

### Changed
- **Single source of truth**: Re-architect `scripts/sync_adapters.py` to parse core principles dynamically from `AGENTS.md` and generate all agent adapters.
- **Cursor configuration**: Remove uninstalled legacy `.cursorrules` in favor of modern `.cursor/rules/karpathy-guidelines.mdc`.
- **PowerShell documentation**: Update README PowerShell one-liners to use scriptblock invocation syntax.
- **Help text**: Document `-e, --examples` flag in `install.sh` help output.
