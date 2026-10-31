# Changelog

All notable changes to PurgeKing are documented here. Versioning follows
[Semantic Versioning](https://semver.org/).

## [1.1.0] — 2026-11-01

Phase 4 — specialized cleanup modules. All route through the existing
safety framework (or, for the admin-gated Windows target, a purpose-built
routine with equivalent checks).

### Added
- **Windows Cleanup** `[3]` / `/windows` — Windows Update download-cache cleanup
  (`SoftwareDistribution\Download` contents only). Requires admin; hardcoded path
  with suffix sanity check, reparse-point check, and locked-file skipping. Never
  stops services or touches `SoftwareDistribution` itself, `WinSxS`, `System32`,
  `Installer`, or `DriverStore`.
- **NVIDIA / GPU Cleanup** `[4]` / `/gpu` — NVIDIA `DXCache`/`GLCache`/`NV_Cache`
  and Windows `D3DSCache` shader caches. Driver untouched; rebuild warning shown.
- **Browser Cleanup** `[5]` / `/browser` — cache-only cleanup (`Cache`, `Code Cache`,
  `GPUCache`, Firefox `cache2`) across detected Chrome/Edge/Firefox profiles.
  Running-process detection via `tasklist`; opt-in per browser. Profiles, bookmarks,
  passwords, cookies, and history never touched.
- **Developer Cleanup** `[6]` / `/python` — `npm cache clean --force` and
  `pip cache purge` for detected tools, each confirmed with the exact command shown.
- Shared helpers: `:DelAndTally`, `:CountAndTally`, `:ProcRunning`.
- CLI switches `/windows`, `/gpu`, `/browser`, `/python` are now active.

### Still planned
- Deep Cleanup `[2]` and Run Everything `[9]` presets (Phase 5).

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
