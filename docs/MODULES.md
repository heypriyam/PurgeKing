# PurgeKing — Modules

## Implemented (v1.0.0)

### Quick Cleanup — `[1]` / `/quick`
- **Target:** current user's `%TEMP%`, validated under `%LOCALAPPDATA%`.
- **Method:** `:SafeDeleteContents` — clears contents, keeps the folder.
- **Prerequisites:** none; locked/in-use files are skipped.
- **Confirmation:** required (Y/N).
- **Also:** PurgeKing's own logs older than the retention window (7 days) are pruned automatically at startup.

### Analyze System Junk — `[7]` / `/analyze`
- **Read-only.** Validates each approved target, reports existence, exact eligible file count, and reparse status. Deletes nothing.
- Sizes are reported as `unavailable` rather than risk a wrong total (see ARCHITECTURE "Design choices").

### System Health Report — `[8]` / `/report`
- Local snapshot: version, Windows build, elevation, system-drive free space (via `dir`, no elevation needed), detected browsers and dev tools, latest log path.
- No serial numbers, account identifiers, or personal file names collected. Never uploaded.

## Planned

Each requires its own target review and test cases before shipping.

| Module | Scope sketch | Key constraints |
|--------|--------------|-----------------|
| Windows Cleanup `[3]` | Windows Update download leftovers (cautious) | Never delete `SoftwareDistribution` wholesale, `WinSxS`, or servicing metadata. Use native servicing commands where needed, clearly labelled. |
| NVIDIA / GPU Cleanup `[4]` | DirectX / DXCache / GLCache shader caches | Never touch the installed driver or `DriverStore`. Clean cache contents, warn about first-run shader rebuild. |
| Browser Cleanup `[5]` | Cache-only folders for Chrome / Edge / Firefox | Never delete profiles, bookmarks, passwords, cookies, history. Recommend closing the browser; never force-close. Opt-in. |
| Developer Cleanup `[6]` | `__pycache__`, pip/npm caches via native commands | Never delete source, `.venv`/`venv`, `node_modules`, builds, or Docker data. Prefer native cache commands. Opt-in. |
| Deep Cleanup `[2]` | Curated preset calling the above in order | Shows included modules first; user can deselect; never silently expands scope. |
| Run Everything `[9]` | Runs the user's selected modules | Shows selection + estimate, confirms, allows cancel between modules. |

## Checklist for every new target

A target ships only after all of these are answered:

1. What component owns the directory, and what exact data is stored there?
2. Is the data genuinely disposable? Does deleting it remove credentials, sessions, history, profiles, settings, saves, or installed software?
3. Can the owning app be running? Must it be closed?
4. Is there an official/native cleanup command? Is manual deletion supported and understood?
5. Can the path be derived and validated against a fixed allowlist on all supported Windows versions?
6. Can a junction/symlink escape the intended directory?
7. Can analysis estimate the data without modifying it?
8. What happens on a locked file / access denied?
9. Is administrator access actually required?
10. Quick, Deep, or optional-only?
11. What warning must the user see? What test proves it's safe? What goes in the log? Who approved it?

**No target enters "Run Everything" until it passes its tests.** A module that hasn't passed stays disabled or experimental.
