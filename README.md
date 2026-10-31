# PurgeKing

**A portable, dependency-free Windows maintenance & cleanup toolkit — one native `.bat` file.**

> See what can be cleaned. Understand what will happen. Choose what to remove. Keep a record of the result.

PurgeKing reclaims disk space by removing **only** disposable files from a small, reviewed allowlist — temporary files today, with browser/GPU/developer caches on the roadmap. It is **not** a registry cleaner, driver tool, optimizer, or "delete everything that looks like junk" script. Its defining feature is not how aggressively it deletes — it's that cleanup is **understandable, previewable, and controlled**.

- **Single file.** Just `PurgeKing.bat`. No installer, runtime, or dependencies.
- **Offline.** No network calls, telemetry, ads, or bundled executables.
- **No PowerShell, Python, Node, or Bash.** Native CMD + built-in Windows tools only.
- **Safe by construction.** Every deletion target is validated against a strict allowlist and refused if it can't be proven safe.

Platform: **Windows 10 / 11**.

---

## ⚠️ Release status — read this

This is tagged **v1.0.0**, but the full module set from the design spec is being delivered in phases. **Three modules are live; six are stubs** that print "coming in a later phase" and delete nothing.

| Menu | Module | Status |
|------|--------|--------|
| `[1]` | Quick Cleanup (user `%TEMP%`) | ✅ **Implemented** |
| `[7]` | Analyze System Junk (read-only) | ✅ **Implemented** |
| `[8]` | System Health Report | ✅ **Implemented** |
| `[T]` | Safety Self-Test | ✅ **Implemented** |
| `[2]` | Deep Cleanup | 🔜 Planned |
| `[3]` | Windows Cleanup | 🔜 Planned |
| `[4]` | NVIDIA / GPU Cleanup | 🔜 Planned |
| `[5]` | Browser Cleanup | 🔜 Planned |
| `[6]` | Developer Cleanup | 🔜 Planned |
| `[9]` | Run Everything | 🔜 Planned |

The entire **safety framework** (path validation, protected-path rejection, reparse-point policy, safe-delete, confirmation, logging) is complete and self-tested — so the planned modules plug into a proven foundation.

---

## Quick start

1. Download **`PurgeKing.bat`**.
2. Double-click it, or run it from a terminal:

```bat
PurgeKing.bat            :: interactive menu
PurgeKing.bat /analyze   :: read-only preview, deletes nothing
PurgeKing.bat /report    :: local system health snapshot
PurgeKing.bat /quick     :: clean user temp (asks to confirm first)
PurgeKing.bat /selftest  :: run the safety-framework self-test
PurgeKing.bat /help       :: usage and safety info
```

> **Keep the file as CRLF.** `.bat` files must use Windows (CRLF) line endings — CMD's `goto`/`call` label search fails intermittently on LF. The included `.gitattributes` enforces this; if you edit the file, save it as CRLF.

Nothing is ever deleted without an explicit on-screen confirmation.

---

## What it does

### Quick Cleanup `[1]` / `/quick`
Removes disposable files from your **per-user temp folder** (`%TEMP%`). Files that Windows has locked (in use) are skipped, not forced. PurgeKing's own old logs are pruned automatically at startup (7-day retention).

### Analyze System Junk `[7]` / `/analyze`
**Read-only.** Validates each approved target, reports whether it exists, counts eligible files, and flags any junction/symlink. Deletes, moves, and modifies nothing.

### System Health Report `[8]` / `/report`
A local snapshot: PurgeKing version, Windows build, elevation state, system-drive free space, detected browsers (Chrome/Edge/Firefox) and developer tools (Python/npm/pip), and the latest log path. Collects no serial numbers, account IDs, or personal file names. Never uploaded.

### Safety Self-Test `[T]` / `/selftest`
Runs 14 assertions against the safety framework — including a live junction-escape test — and reports pass/fail. Run it any time to verify the guardrails.

---

## Safety model (short version)

Before **any** deletion, the target path must survive validation, or the operation is refused:

- Rejects empty paths, bare drive roots (`C:\`), and UNC/network paths.
- Rejects protected trees: `System32`, `WinSxS`, `Installer`, `DriverStore`, the Windows root, and Program Files.
- Refuses whole profile roots (`%USERPROFILE%`, `%APPDATA%`, `%LOCALAPPDATA%`, Documents/Desktop/Downloads).
- Requires the target to sit **under its module's allowlisted parent** (prefix-safe, so `C:\Foo` never matches `C:\FooBar`).
- Skips any directory tree containing a junction or symlink, so a recursive delete can't escape via a reparse point.
- Deletes **contents only** — never the parent folder.
- Locked / access-denied files are logged and skipped. PurgeKing never force-closes apps, takes ownership, or changes ACLs.

**Out of scope, permanently:** registry cleaning, driver removal, `WinSxS`/`DriverStore`/`Installer`/`System32` deletion, disabling services or security, uninstalling apps, and deleting documents, downloads, game saves, source code, virtual environments, or Docker data.

See [docs/SAFETY.md](docs/SAFETY.md) for the full model.

---

## Logs

Timestamped logs are written locally to a `logs/` folder beside the script (falling back to `%LOCALAPPDATA%\PurgeKing\logs` if that isn't writable). They record version, Windows build, selected modules, counts, and outcomes — and stay on your machine. Nothing is uploaded.

---

## Documentation

- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) — internal structure, layers, execution lifecycle.
- [docs/SAFETY.md](docs/SAFETY.md) — the full safety model and validation rules.
- [docs/MODULES.md](docs/MODULES.md) — per-module scope, targets, and roadmap.
- [docs/TESTING.md](docs/TESTING.md) — test strategy and how to run the self-test.
- [CHANGELOG.md](CHANGELOG.md) — version history.

---

## Contributing

New cleanup targets must pass the checklist in [docs/MODULES.md](docs/MODULES.md) before they ship: exact path, owning component, risk assessment, preview behavior, cleanup method, and a test. **No target enters "Run Everything" until it passes its tests.** If PurgeKing cannot prove a target is in scope, it skips it.

## License

**PurgeKing is free for noncommercial and personal use** under the
[PolyForm Noncommercial License 1.0.0](LICENSE.md). Hobby projects, study,
research, and use by nonprofits/educational/government bodies are all permitted.

**Commercial use is not granted by this license.** For a commercial license,
contact priyamchandr@gmail.com.

© 2026 Priyam Chandra
