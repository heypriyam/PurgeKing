# PurgeKing — Architecture

PurgeKing is a **single-file application** (`PurgeKing.bat`), but its logic is modular: Batch labels and subroutines provide the module boundaries. The UI never contains deletion logic — it calls into subroutines.

## Logical layers

```
                      PURGEKING.BAT
                            |
           +----------------+----------------+
           |                                 |
     Bootstrap / init                   CLI parser
   (version, dirs, env, admin)        (:ParseArgs)
           |                                 |
           +----------------+----------------+
                            |
                        Main menu
                     (:MainMenu / input validation)
                            |
        +-------------------+-------------------+
        |                   |                   |
    Analysis            Execution           Reporting
 (:AnalyzeTarget)   (cleanup modules)    (:SystemReport)
        |                   |
  read-only preview   Safety framework
   (count, flag)      (shared, below)
                            |
                     Result + logging
                       (:Log, summary)
```

## Shared safety framework (the core)

Every destructive module routes through these, never around them:

| Routine | Responsibility |
|---------|----------------|
| `:ValidatePath` | Normalizes a path (`%~f`, collapsing `..`), rejects empty / drive roots / UNC / protected trees / whole profile roots, and requires the target to sit under the module's allowlisted parent. Sets `VP_OK`, `VP_REASON`, `VP_FULL`. |
| `:_UnderOrEqual` | Prefix-safe "is child of" check (appends `\` so `C:\Foo` ≠ `C:\FooBar`). |
| `:TreeHasReparse` | Flags any junction/symlink anywhere in a tree via `dir /s /a:l`. |
| `:SafeDeleteContents` | Validates → checks reparse → deletes **contents only** → reports `SD_STATUS` + deleted/remaining counts. |
| `:CountFiles` | Counts files under a path (used for honest before/after deltas). |
| `:Confirm` | Y/N prompt via `choice`, with a `set /p` fallback. |

## File section map

The script is organized into numbered sections (see the `rem [NN]` headers):

```
[01] Constants and configuration      [09] Quick Cleanup
[02] Bootstrap / initialization       [15] System Health Report
[03] Argument parsing                 [16] Safe file operations
[04] Environment and admin checks     [17] Validation utilities
[05] Logging utilities                [18] Confirmation framework
[06] Main menu                        [19] Exit / clean shutdown
[07] Module router (stubs for 4-6)    +   Phase 2 self-test
[08] Analysis engine
```

## Execution lifecycle

### Startup
1. `@echo off`, `setlocal EnableExtensions DisableDelayedExpansion`.
2. Define product name and version.
3. Resolve the script directory from `%~dp0` (never trust the current working directory).
4. Detect environment: admin state (`net session`), Windows build/edition (`reg query` — no `wmic`, no PowerShell).
5. Initialize logging (folder beside script, else `%LOCALAPPDATA%` fallback) and prune expired logs.
6. Parse arguments. Non-destructive actions (`/analyze`, `/report`, `/help`, `/selftest`) run directly; destructive ones (`/quick`) still confirm. Unknown args never imply permission to delete.
7. Show the menu, or run the requested action and exit.

### Module lifecycle
```
Display purpose + scope
   -> Validate configured target paths
   -> Analyze eligible data (read-only preview)
   -> Ask explicit confirmation  --No--> log CANCELLED, return
   -> Revalidate target immediately before deletion
   -> Perform allowlisted cleanup (contents only)
   -> Count successes / skips / failures
   -> Write module summary to log
   -> Return
```

Revalidation at execution time is deliberate: a path that was safe during analysis is re-checked immediately before deletion, so a stale preview is never the only safety gate.

## Design choices worth knowing

- **Delayed expansion is global-off** (`DisableDelayedExpansion`) to avoid `!` corrupting paths; routines that need it enable it locally and pass results out with the `endlocal & set OUT=%local%` idiom.
- **Parenthesized `if (...)` blocks avoid literal `)`** — text like `file(s)` is either escaped (`file^(s^)`) or echoed in flat flow, because an unescaped `)` closes the block early.
- **Size estimation is intentionally omitted** — CMD's `set /a` is 32-bit signed and overflows on large byte totals, so analysis reports exact file **counts** and `size estimate unavailable` rather than a wrong number (spec §9.2).
- **CRLF line endings are required** and enforced via `.gitattributes`; CMD label resolution is unreliable on LF-only files.
