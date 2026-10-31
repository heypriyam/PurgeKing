# PurgeKing — Safety Model

Safety before maximum cleanup. A smaller safe cleanup beats a larger one that risks breaking Windows. **If PurgeKing cannot prove a target is in scope, it skips it.**

## Principles

- **Explicit allowlisting.** Modules act on a reviewed list of specific paths. They never scan the system drive for names like `cache`, `temp`, or `old` and delete what they find.
- **Preview before deletion.** Analysis is read-only and separate from cleanup. Deletion always requires confirmation.
- **Transparency.** Logs record what was attempted, what succeeded, what was skipped, and what failed. Skipped files are never reported as deleted.
- **Idempotence.** Running twice is safe; a missing folder is a normal condition, not an error.
- **Least privilege.** Runs without elevation where possible. Never bypasses UAC, takes ownership, or changes ACLs to force a delete.
- **No hidden behavior.** No network, telemetry, ads, bundled binaries, or background services.

## Path validation (`:ValidatePath`)

Before any deletion the candidate path is normalized (`%~f`, which collapses `.` and `..`) and must pass **all** of:

**Rejected outright:**
- Empty string.
- Bare drive root (`C:\`).
- UNC / network path (`\\server\share`).
- Equal to, or underneath, a hard-blocked tree:
  - `%SystemRoot%`
  - `%SystemRoot%\System32`
  - `%SystemRoot%\WinSxS`
  - `%SystemRoot%\Installer`
  - `%SystemRoot%\System32\DriverStore`
  - `%ProgramFiles%`, `%ProgramFiles(x86)%`
- Exactly equal to a profile root: `%USERPROFILE%`, `%LOCALAPPDATA%`, `%APPDATA%`, or `%USERPROFILE%\{Documents,Desktop,Downloads}`.

**Required:**
- Must sit **under the module's allowlisted parent**. This positive check is prefix-safe (a trailing `\` is appended before comparison), so `C:\Foo` never matches `C:\FooBar`. It is the strongest guarantee: even if a block list missed something, a target outside its module's small configured parent is refused.

## Reparse points (`:TreeHasReparse`)

Junctions and symbolic links can point outside the intended tree, and a recursive delete can follow them into another directory. PurgeKing scans the whole target tree (`dir /s /a:l`) and, if **any** junction/symlink is present, **skips the entire target** and reports it — rather than risk an escape. Only after confirming none exist does it use `del /s` + `rd` on the tree.

> Limitation: tree-wide reparse detection relies on `dir`'s reporting, which is adequate but not a kernel-level guarantee, and the scan is slower on very large trees (cache targets are small enough).

## Delete contents, not parents

For cache directories the intended operation is to clear eligible **contents** while leaving the directory structure intact. The parent folder is never removed unless its removal is explicitly required and independently validated (no current module does this).

## Locked files and access denied

If a file is locked or access is denied, PurgeKing:
- does **not** force-close the owning application;
- does **not** take ownership or change ACLs;
- does **not** disable any security control;
- logs the item as skipped/failed and continues with other eligible files.

## Permanently out of scope

```
Registry cleaning
%SystemRoot%\System32, \WinSxS, \Installer, \System32\DriverStore
%ProgramFiles%, %ProgramFiles(x86)%
Disabling services, scheduled tasks, Windows Update, Defender, firewall
Uninstalling applications
Documents, Desktop, Downloads, photos, videos, game saves
Browser profiles (bookmarks, passwords, cookies, history, sessions)
Installed drivers and DriverStore content
Virtual environments, installed packages, node_modules, build outputs
Docker images, volumes, containers
```

This list is a **minimum**, not exhaustive. PurgeKing relies on explicit allowlists, not on the assumption that anything not listed here is safe to delete.

## Verifying the guardrails

Run `PurgeKing.bat /selftest` (or menu `[T]`). It asserts that unsafe paths are rejected, a valid child is accepted, a path outside the allowlisted parent is refused, safe-delete clears contents without removing the parent, and a junction in the tree forces a `SKIPPED`. v1.0.0 ships with **14/14 passing**.
