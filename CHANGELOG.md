# Changelog

All notable changes to PurgeKing are documented here. Versioning follows
[Semantic Versioning](https://semver.org/).

## [1.0.0] — 2026-10-31

First public release. Application shell, complete safety framework, and the
first low-risk cleanup/analysis/reporting modules.

### Added
- Single-file `PurgeKing.bat` for Windows 10/11 — no external dependencies, offline.
- Menu-driven UI with validated input, help/safety screen, latest-log viewer, clean exit.
- Command-line switches: `/quick`, `/analyze`, `/report`, `/help`, `/selftest`.
- **Safety framework:** path validation, protected-path rejection, allowlisted-parent
  requirement, reparse-point (junction/symlink) policy, safe content-only deletion,
  Y/N confirmation, and outcome/error reporting.
- **Quick Cleanup** `[1]` — current-user `%TEMP%` cleanup with preview and confirmation.
- **Analyze System Junk** `[7]` — read-only preview with exact file counts.
- **System Health Report** `[8]` — local snapshot (no personal data, never uploaded).
- Timestamped logging with automatic retention pruning and a `%LOCALAPPDATA%` fallback.
- Self-test (`/selftest`) with 14 assertions, including a live junction-escape test — 14/14 passing.
- `.gitattributes` enforcing CRLF on `.bat` files.

### Not yet implemented (stubs; planned)
- Deep Cleanup `[2]`, Windows Cleanup `[3]`, NVIDIA/GPU Cleanup `[4]`,
  Browser Cleanup `[5]`, Developer Cleanup `[6]`, Run Everything `[9]`.

### Known limitations
- Byte-size estimation is intentionally omitted (CMD 32-bit arithmetic overflows on
  large totals); analysis reports exact file counts and `size estimate unavailable`.
- On Windows 11 the reported product name may read "Windows 10" (a registry quirk);
  the build number is the reliable identifier.
