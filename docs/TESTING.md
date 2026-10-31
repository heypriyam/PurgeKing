# PurgeKing — Testing

> Test cleanup tools in a disposable VM or a throwaway account first — never prove a destructive tool on your primary machine.

## Built-in self-test

```bat
PurgeKing.bat /selftest
```

Runs 14 assertions and prints `N passed, M failed`:

- **Path validation — must reject:** empty, drive root, `%SystemRoot%`, `System32`, `WinSxS`, `Installer`, `DriverStore`, whole profile root, UNC path, and an escape via `..`.
- **Path validation — must accept:** a legitimate child of an allowlisted parent.
- **Allowlist boundary:** a path outside the allowlisted parent is rejected.
- **Safe delete:** on a disposable fixture, contents are cleared, the parent folder survives, and counts are reported.
- **Reparse policy:** a junction created inside the fixture forces a `SKIPPED` (the delete does not proceed).

The fixture lives under `%TEMP%\PurgeKing_selftest` and is created and removed by the test. v1.0.0 passes **14/14**.

## Manual integration checks

- Launch from Explorer (double-click) and from a terminal in a different working directory.
- Launch from a path containing spaces.
- Launch as a standard user and as administrator.
- Run each switch: `/analyze`, `/report`, `/quick`, `/help`, `/selftest`.
- Run analysis, then cleanup; run cleanup twice (second run should find fewer files).
- Confirm logs are written and the menu stays usable after a module returns.

## Regression checklist (after every change)

- No protected directory can be selected or deleted.
- No browser profile, driver file, or user document is touched.
- No PowerShell / Python / Node / Bash dependency introduced.
- No network call or download exists.
- CRLF line endings preserved (LF breaks CMD label resolution).
- `/selftest` still passes.

## Note on line endings

`.bat` must be CRLF. The repo enforces this via `.gitattributes` (`*.bat text eol=crlf`). If a self-test or run fails with `The system cannot find the batch label specified`, check for LF line endings first.
