# PurgeKing — Modules

## Implemented (v1.1.0)

### Quick Cleanup — `[1]` / `/quick`
- **Target:** current user's `%TEMP%`, validated under `%LOCALAPPDATA%`.
- **Method:** `:SafeDeleteContents` — clears contents, keeps the folder.
- **Prerequisites:** none; locked/in-use files are skipped.
- **Confirmation:** required (Y/N).
- **Also:** PurgeKing's own logs older than the retention window (7 days) are pruned automatically at startup.

### Analyze System Junk — `[7]` / `/analyze`
- **Read-only.** Validates each approved target, reports existence, exact eligible file count, and reparse status. Deletes nothing.
- Sizes are reported as `unavailable` rather than risk a wrong total (see ARCHITECTURE "Design choices").

### Windows Cleanup — `[3]` / `/windows`
- **Target:** `%SystemRoot%\SoftwareDistribution\Download` (contents only).
- **Requires administrator.** Without elevation the module explains and exits.
- Purpose-built routine (`:CleanWUCache`), not the generic safe-delete — because the generic helper refuses everything under `%SystemRoot%` by design. Uses a hardcoded path plus a suffix sanity check, a reparse-point check, and locked-file skipping. Never deletes `SoftwareDistribution` itself, stops a service, or touches `WinSxS`/`System32`/`Installer`/`DriverStore`.
- If files are locked (active servicing), they are skipped with a "retry later" note.

### NVIDIA / GPU Cleanup — `[4]` / `/gpu`
- **Targets:** `%LOCALAPPDATA%\NVIDIA\DXCache`, `\NVIDIA\GLCache`, `\NVIDIA Corporation\NV_Cache`, `\D3DSCache` (Windows DirectX shader cache), all validated under `%LOCALAPPDATA%`.
- Driver is never touched. Warns that shaders rebuild and first launch may stutter. AMD/Intel not claimed.

### Browser Cleanup — `[5]` / `/browser`
- **Targets:** per-profile `Cache`, `Code Cache`, `GPUCache` under Chrome/Edge `User Data`, and Firefox `cache2`, validated under each browser's root.
- Enumerates profile folders dynamically. Never touches profiles, bookmarks, passwords, cookies, history, or sessions. Detects running processes (`tasklist`) and warns; never force-closes. Opt-in per browser.

### Developer Cleanup — `[6]` / `/python`
- Runs each tool's **own** command — `npm cache clean --force`, `pip cache purge` — for detected tools, confirmed individually, with the exact command shown first.
- Never deletes source, `.venv`/`venv`, `node_modules`, builds, or Docker data. `__pycache__`/per-project caches are out of scope for automated cleaning.

### System Health Report — `[8]` / `/report`
- Local snapshot: version, Windows build, elevation, system-drive free space (via `dir`, no elevation needed), detected browsers and dev tools, latest log path.
- No serial numbers, account identifiers, or personal file names collected. Never uploaded.

## Planned

Each is a preset built on the modules above, not a new deletion engine.

| Module | Scope sketch | Key constraints |
|--------|--------------|-----------------|
| Deep Cleanup `[2]` | Curated preset calling selected modules in order | Shows included modules first; user can deselect; never silently expands scope. |
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
