# PurgeKing --- Windows Maintenance & Cleanup Toolkit

## Product vision, requirements, architecture, safety model, implementation plan, and technical design

**Document status:** Project specification / implementation blueprint\
**Project name:** PurgeKing\
**Target platform:** Windows 10 and Windows 11\
**Primary implementation:** Windows Command Script (`.bat`) using native
CMD commands and Windows utilities\
**Primary deliverable:** A portable, dependency-free `PurgeKing.bat`
file\
**Operating model:** Offline-first, transparent, modular,
user-controlled cleanup

------------------------------------------------------------------------

# 1. Executive summary

PurgeKing is a lightweight Windows maintenance utility designed to help
a user inspect and reclaim disk space by removing disposable files such
as temporary files, selected application caches, browser caches,
graphics shader caches, stale update-download files, and
development-tool caches.

The product is intentionally not a system optimizer, registry cleaner,
driver uninstaller, antivirus, or automated repair suite. Its purpose is
narrower and safer:

1.  Identify cleanup targets that are understood and explicitly
    allowlisted.
2.  Estimate the amount of data that may be reclaimed.
3.  Explain what each cleanup action will and will not remove.
4.  Let the user choose individual modules or a curated cleanup preset.
5.  Delete only approved disposable data, using conservative defaults.
6.  Record actions, skipped targets, errors, and results in a readable
    log.
7.  Avoid changes to installed applications, personal files, Windows
    component stores, and installed device drivers.

PurgeKing should feel like a polished, menu-driven command-line
application while remaining a single portable Batch file. It should work
without an installer, network connection, package manager, runtime, or
third-party executable.

## 1.1 Product promise

> See what can be cleaned. Understand what will happen. Choose what to
> remove. Keep a record of the result.

PurgeKing should never promise a guaranteed amount of reclaimed storage.
File locks, permissions, running applications, Windows servicing, and
files recreated during cleanup can affect the final result.

## 1.2 Important terminology

The earlier idea was described informally as a "Bash project." Because
the target is Windows 10/11 and the agreed implementation is a `.bat`
file, the correct implementation technology is **Windows CMD Batch**,
not Bash. Bash scripts (`.sh`) are intended for Bash-compatible
environments such as Linux, macOS, or WSL. PurgeKing's core must remain
a native Windows Batch application.

------------------------------------------------------------------------

# 2. Problem statement

Windows systems accumulate disposable data during normal operation.
Examples include:

-   Temporary files created by applications and installers.
-   Windows temporary files and selected update-download leftovers.
-   Browser cache data.
-   GPU shader caches.
-   Crash reports and diagnostic leftovers.
-   Build caches and temporary artifacts created by development tools.
-   Old log files created by PurgeKing itself.

This data is not automatically harmful, and not all cache data should be
removed. Some caches improve performance and will simply be recreated
after deletion. Other directories contain a mixture of disposable data
and important state. A broad recursive deletion command can therefore
cause application problems, remove useful data, or damage Windows.

The practical problem is not simply "delete junk." It is:

**Provide a safe, understandable, repeatable way to identify and remove
selected disposable files without treating every large or old file as
junk.**

## 2.1 Goals

-   Reclaim storage from known, low-risk cleanup targets.
-   Give the user a preview before destructive actions.
-   Make each cleanup module independently selectable.
-   Support a one-click curated cleanup after explicit confirmation.
-   Provide clear progress and a final summary.
-   Log what was attempted, what succeeded, and what failed.
-   Work offline and without external dependencies.
-   Be portable and easy to inspect.
-   Use conservative defaults and fail safely.

## 2.2 Non-goals

PurgeKing is not intended to:

-   Delete arbitrary files based only on age or size.
-   Remove installed graphics drivers.
-   Delete files from Windows DriverStore.
-   Manually delete files from `WinSxS`.
-   Delete Windows Installer package caches.
-   Clean the registry.
-   Disable Windows services or scheduled tasks.
-   Disable Windows Update.
-   Disable Defender, firewall, security, or telemetry protections.
-   Modify page files, hibernation, boot configuration, or system
    policies.
-   Uninstall applications.
-   Delete user documents, downloads, photos, videos, game saves, or
    project source code.
-   Guarantee that every cache can be cleaned while its application is
    running.
-   Replace Windows Storage Sense, Disk Cleanup, or supported Windows
    servicing tools.

------------------------------------------------------------------------

# 3. Product principles

Every design and implementation decision should follow these principles.

## 3.1 Safety before maximum cleanup

A smaller safe cleanup is better than a larger cleanup that risks
breaking Windows or applications. If the tool cannot confidently
identify a target, it should skip it.

## 3.2 Explicit allowlisting

Cleanup modules must use a reviewed list of specific target paths and
file patterns. They must not search the entire system drive for files
with generic names such as `cache`, `temp`, `old`, or `backup` and
delete everything found.

## 3.3 Preview before deletion

Analysis and cleanup are separate operations. Analysis must not delete,
move, or modify files. A cleanup action should show its scope and
require confirmation.

## 3.4 Transparency

The UI should explain the purpose of each module, the types of files it
targets, and the limitations. Logs should not hide errors or imply that
skipped files were deleted.

## 3.5 Reversible where practical

Deleting cache files is generally not reversible. Therefore, PurgeKing
should not claim that cleanup is reversible. It should instead minimize
risk by using allowlists, dry-run analysis, confirmation, and
conservative scope.

## 3.6 Idempotence

Running a cleanup twice should be safe. The second run should simply
find fewer eligible files. A missing folder is a normal condition, not a
fatal error.

## 3.7 Least privilege

Do not run as administrator unless the selected operation needs elevated
access. If the product launches elevated for the full session, explain
why and keep the actions constrained. A future improvement may separate
user-level cleanup from administrator-only modules.

## 3.8 No hidden behavior

No network calls, telemetry, advertising, bundled executables, or
background services. All cleanup actions should be visible in the script
and described in the documentation.

------------------------------------------------------------------------

# 4. Functional scope and modules

The first release should expose the following modules. Each module must
be independently callable and must have a documented target list.

## 4.1 Quick Cleanup

**Purpose:** Remove low-risk temporary data that is commonly safe to
recreate.

Candidate targets: - Current user's `%TEMP%` directory. - Selected files
in the Windows temporary directory, only when permissions allow. -
PurgeKing's own expired logs, subject to a retention policy.

Rules: - Do not delete the parent directory. - Do not delete files
outside the configured target. - Skip files that are locked or
inaccessible. - Do not use broad deletion against the entire user
profile. - Report skipped items and errors. - Never assume that every
file in a directory named `Temp` is disposable without validating the
exact target.

## 4.2 Deep Cleanup

**Purpose:** Run a broader set of reviewed cleanup modules.

Deep Cleanup is a preset, not a separate unrestricted deletion engine.
It should call individual modules in a controlled order, for example:

1.  Quick Cleanup.
2.  Windows temporary/update-download cleanup.
3.  GPU shader-cache cleanup.
4.  Browser cache cleanup, only for supported browsers and only when
    safe.
5.  Developer cache cleanup, only for detected and explicitly supported
    tools.

The UI must show which modules are included before execution. Users
should be able to deselect modules. Deep Cleanup must not silently
expand its scope after an update.

## 4.3 Windows Cleanup

**Purpose:** Remove selected disposable Windows data without damaging
the component store or update infrastructure.

Potential target: - Windows Update download cache files under the
documented SoftwareDistribution download area, using a cautious
procedure.

Important safeguards: - Do not manually delete the entire
`SoftwareDistribution` directory. - Do not stop or alter Windows
services as a casual cleanup step. - If a supported Windows servicing
operation is needed, invoke the native Windows utility with documented
arguments and explain the action. - Do not delete `WinSxS` content
manually. - Do not delete `System32`, `Installer`, `DriverStore`,
component manifests, catalog files, or servicing metadata. - If Windows
Update is actively servicing or files are locked, skip the operation and
explain that the user can retry later.

For component-store maintenance, the supported Windows servicing command
may be offered as a distinct, clearly labelled optional action. It must
not be represented as ordinary cache deletion. The tool should explain
that the operation is managed by Windows and may take time. Never use a
hand-written recursive deletion against `WinSxS`.

## 4.4 NVIDIA / GPU Cleanup

**Purpose:** Remove selected graphics shader caches and installer
leftovers without uninstalling or damaging the active graphics driver.

Potential targets, subject to existence and validation: - NVIDIA DirectX
shader cache locations. - NVIDIA DXCache / GLCache locations where
present. - The DirectX Shader Cache managed by Windows, if exposed
through a known supported location. - NVIDIA installer extraction
leftovers in `C:\NVIDIA`, but only after clear preview and validation.

Rules: - Do not delete the installed driver package. - Do not delete
`C:\Windows\System32\DriverStore`. - Do not delete driver files under
Windows system directories. - Do not remove NVIDIA services, registry
keys, control panel components, or driver profiles. - Do not assume all
NVIDIA directories are disposable. - Prefer cleaning shader-cache
contents rather than deleting parent directories. - Warn that shaders
may be rebuilt and the first launch of some games/apps may stutter
temporarily. - Skip active or locked files.

AMD and Intel GPU support should not be claimed until their target paths
and behavior have been separately researched and tested. The UI may say
"GPU Cleanup" only if supported vendors are explicitly listed.

## 4.5 Browser Cleanup

**Purpose:** Remove browser cache data for explicitly supported
browsers.

Initial support should be conservative. Each browser needs its own
target definition and detection logic.

Potential browsers: - Google Chrome. - Microsoft Edge. - Mozilla
Firefox.

Rules: - Do not delete browser profiles. - Do not delete bookmarks,
passwords, cookies, autofill data, extensions, history, sessions, or
saved payment information. - Do not delete entire `User Data`,
`Profiles`, or Firefox profile directories. - Prefer cache-only folders
with documented meanings. - Recommend closing the browser first. - If a
browser is running, either skip its module or warn that some files may
be locked. Do not force-close it. - Browser cache cleanup should be
opt-in, not silently included in the most conservative Quick Cleanup.

## 4.6 Developer Cleanup

**Purpose:** Reclaim disposable caches created by development tools.

Potential support, only after each target has been reviewed: - Python
bytecode cache folders (`__pycache__`) in explicitly selected project
locations, not by scanning and deleting across the entire drive. - pip
download/cache data using the tool's own cache-management command where
available. - npm cache using npm's own cache verification/cleaning
commands, with clear warnings. - Selected temporary build caches for
supported tools. - Temporary files created by known build processes.

Rules: - Never delete source repositories, virtual environments, package
installations, `node_modules`, `.venv`, `venv`, build outputs, or
project folders by default. - Never recursively scan all drives and
remove folders based on a name alone. - Prefer native package-manager
cleanup commands over manual deletion. - Show which tools are detected
and exactly which action will be invoked. - If a tool is not installed,
mark the module as unavailable and continue.

Potential future modules such as Gradle, Maven, Docker, Unreal Engine,
Unity, or Visual Studio caches must be added individually after their
data ownership and cleanup behavior are verified. Docker images,
volumes, and containers must never be treated as ordinary cache files.

## 4.7 Analyze System Junk

**Purpose:** Inspect cleanup targets without deleting anything.

The analysis engine should: - Check whether target folders exist. -
Enumerate eligible files within approved boundaries. - Calculate
approximate eligible file sizes. - Count eligible files. - Identify
locked/inaccessible items where possible. - Show per-module estimates. -
Clearly label estimates as approximate. - Avoid following directory
junctions or symbolic links outside the approved target. - Avoid
scanning entire disks.

Analysis must be read-only. It must not create, delete, or modify target
files. It may write its own report/log outside the inspected target.

## 4.8 System Health Report

**Purpose:** Provide a basic, non-invasive snapshot.

Possible fields: - Windows edition/version/build. - Computer name
(optional; consider privacy in logs). - System drive capacity, free
space, and used space. - User profile temp path. - Detected browsers and
developer tools. - GPU vendor/model where safely discoverable through
native commands. - PurgeKing version. - Last cleanup time and last
result.

The report should avoid collecting serial numbers, account identifiers,
personal file names, or other unnecessary personal data. The report is
local only.

## 4.9 Run Everything

**Purpose:** Run the user's selected cleanup modules in a predictable
order.

This should be a curated workflow, not "delete every possible thing."
Before starting: - Display the exact modules selected. - Display
estimated reclaimable space if analysis has been run. - Warn about
applications that should be closed. - Require explicit confirmation. -
Allow cancellation between modules. - Log the outcome of every module.

------------------------------------------------------------------------

# 5. User experience and command-line interface

## 5.1 Main menu concept

``` text
========================================================
                         PURGEKING
               WINDOWS MAINTENANCE TOOLKIT
========================================================
  Windows 10 / 11                 Version: 1.0.0
  Mode: SAFE                      Admin: Yes / No
--------------------------------------------------------

  [1] Quick Cleanup
  [2] Deep Cleanup
  [3] Windows Cleanup
  [4] NVIDIA / GPU Cleanup
  [5] Browser Cleanup
  [6] Developer Cleanup

--------------------------------------------------------
  [7] Analyze System Junk
  [8] System Health Report
  [9] Run Selected / All Cleanup Modules

  [L] View Latest Log
  [H] Help & Safety Information
  [0] Exit

========================================================
  Select an option:
```

The UI should use CMD-native output, simple color changes, clear
headings, and consistent spacing. It should not depend on ANSI support
being enabled. If color commands fail or are unavailable, the
application must remain usable in plain text.

## 5.2 Module interaction

Each module should follow the same interaction pattern:

1.  Show module name and purpose.
2.  Show the exact cleanup scope.
3.  Check prerequisites, such as whether the application is closed.
4.  Offer analysis/preview.
5.  Ask for confirmation.
6.  Execute only approved actions.
7.  Print success, skipped, and failed counts.
8.  Return to the main menu.

Do not make the user confirm every single file. Confirmation should be
at the module/action level, with a separate confirmation for higher-risk
operations.

## 5.3 Command-line switches

Support optional command-line switches for power users and automation:

  -----------------------------------------------------------------------
  Switch                              Behavior
  ----------------------------------- -----------------------------------
  `/quick`                            Run Quick Cleanup

  `/deep`                             Preview and run Deep Cleanup with
                                      confirmation

  `/browser`                          Run supported browser-cache module

  `/python`                           Run supported Python cache module

  `/gpu`                              Run supported GPU cache module

  `/report`                           Generate system report

  `/analyze`                          Analyze all available approved
                                      targets

  `/everything`                       Run the curated all-module workflow
                                      with confirmation

  `/help`                             Display usage and safety
                                      information
  -----------------------------------------------------------------------

Batch files do not provide robust, secure unattended approval by
default. Destructive command-line switches should still require
confirmation unless a carefully designed, explicit non-interactive mode
is later added. Never interpret an unknown argument as permission to
delete.

Example:

``` bat
PurgeKing.bat /analyze
PurgeKing.bat /quick
PurgeKing.bat /report
```

## 5.4 Accessibility and usability

-   Use readable contrast.
-   Do not rely on color alone to convey success or failure.
-   Keep menu labels short and consistent.
-   Support keyboard-only operation.
-   Validate every menu input.
-   Handle Ctrl+C and unexpected termination as safely as Batch allows.
-   Never leave the user at a confusing blank screen after an error.

------------------------------------------------------------------------

# 6. Technical architecture

PurgeKing is a single-file application, but its internal logic should be
modular. Batch labels and subroutines provide the module boundaries.

## 6.1 High-level architecture

``` text
                    PURGEKING.BAT
                          |
             +------------+------------+
             |                         |
        Initialization             CLI Parser
             |                         |
     +-------+--------+                |
     |       |        |                |
  Version  Logging  Admin Check        |
     |       |        |                |
     +-------+--------+----------------+
                          |
                     Main Menu
                          |
             +------------+------------+
             |            |            |
          Analysis     Cleanup       Reporting
             |            |            |
      Target Registry  Module Router  System Info
             |            |            |
      Path Validation  Preconditions  Log Summary
             |            |
      File Enumeration  Confirmation
             |            |
      Size Estimation   Safe Delete
             |            |
             +------------+------------+
                          |
                    Result Summary
                          |
                       Exit
```

## 6.2 Logical layers

### A. Bootstrap / initialization layer

Responsibilities: - Set the application title. - Set version
constants. - Establish script directory. - Initialize environment
variables. - Establish log location. - Set safe defaults. - Parse
arguments. - Detect Windows version and elevation state.

### B. User-interface layer

Responsibilities: - Draw menus. - Print module descriptions. - Collect
and validate user input. - Display warnings and confirmation prompts. -
Display progress and result summaries.

The UI must not contain the actual deletion logic. It should call module
subroutines.

### C. Target registry layer

Responsibilities: - Define known cleanup targets. - Record the owning
module. - Define whether a target is user-level or
administrator-level. - Define whether a target requires an application
to be closed. - Define whether it is included in Quick, Deep, or
optional cleanup. - Define its risk classification and explanatory text.

In Batch, a target registry can be represented through dedicated
subroutines and variables rather than a complex data structure. Keep
definitions centralized to reduce accidental inconsistency.

### D. Analysis layer

Responsibilities: - Validate paths. - Enumerate eligible files. -
Estimate bytes and file counts. - Detect missing or inaccessible
targets. - Produce a preview without deleting.

### E. Execution layer

Responsibilities: - Revalidate the target immediately before deletion. -
Check prerequisites. - Execute the allowlisted operation. - Count
outcomes where feasible. - Record errors. - Continue safely when one
module fails.

### F. Logging layer

Responsibilities: - Create a timestamped log. - Record application
version and Windows version. - Record selected modules. - Record actions
and outcomes. - Record skipped targets and errors. - Write a final
summary.

### G. Reporting layer

Responsibilities: - Show free space before and after cleanup. -
Summarize approximate reclaimed bytes. - Generate a local text report. -
Avoid unnecessary personal data.

## 6.3 Single-file structure

Suggested internal organization:

``` bat
@echo off
setlocal EnableExtensions DisableDelayedExpansion

rem =====================================================
rem  PURGEKING - WINDOWS MAINTENANCE TOOLKIT
rem  Version and configuration
rem =====================================================

rem [01] CONSTANTS AND CONFIGURATION
rem [02] BOOTSTRAP / INITIALIZATION
rem [03] ARGUMENT PARSING
rem [04] ENVIRONMENT AND ADMIN CHECKS
rem [05] LOGGING UTILITIES
rem [06] MAIN MENU
rem [07] MODULE ROUTER
rem [08] ANALYSIS ENGINE
rem [09] QUICK CLEANUP
rem [10] WINDOWS CLEANUP
rem [11] GPU CLEANUP
rem [12] BROWSER CLEANUP
rem [13] DEVELOPER CLEANUP
rem [14] DEEP CLEANUP
rem [15] SYSTEM REPORT
rem [16] SAFE FILE OPERATIONS
rem [17] VALIDATION UTILITIES
rem [18] ERROR HANDLING
rem [19] EXIT / CLEAN SHUTDOWN
```

The actual script should use labels such as `:MainMenu`,
`:QuickCleanup`, `:AnalyzeTargets`, and `:WriteLog`. Each subroutine
should have one clear responsibility.

------------------------------------------------------------------------

# 7. Execution lifecycle

## 7.1 Startup sequence

1.  Start with `@echo off`.
2.  Enable CMD extensions.
3.  Use `setlocal` to avoid leaking environment changes to the parent
    shell.
4.  Define product name and version.
5.  Resolve the script's own directory using `%~dp0`.
6.  Establish the log directory.
7.  Parse command-line arguments.
8.  Check supported Windows environment.
9.  Determine whether the current process is elevated.
10. Display the main menu or execute the requested non-destructive
    action.

Do not assume the current working directory is the script directory.
Users may launch the file from a shortcut, another terminal directory,
or Explorer. Resolve paths relative to `%~dp0` where appropriate.

## 7.2 Module lifecycle

Every module should use the same conceptual sequence:

``` text
START MODULE
    |
    v
Display purpose and scope
    |
    v
Validate configured target paths
    |
    v
Check prerequisites
    |
    v
Analyze eligible data
    |
    v
Display estimate and limitations
    |
    v
Ask for explicit confirmation
    |
    +---- No ----> Log cancelled -> Return
    |
   Yes
    |
    v
Revalidate target paths
    |
    v
Perform allowlisted cleanup
    |
    v
Count successes / skips / failures
    |
    v
Write module summary to log
    |
    v
Return to caller
```

## 7.3 Revalidation

A path that was safe during analysis may not be safe at execution time
if environment variables or filesystem state change. Before deletion: -
Expand the intended path. - Reject empty paths. - Reject drive roots. -
Reject critical Windows roots. - Confirm the path is within the expected
allowlisted parent. - Reject unexpected network paths. - Avoid following
reparse points or junctions outside the target boundary. - Confirm the
expected target directory exists. - Re-check the operation type.

Do not rely on a preview performed several minutes earlier as the only
safety check.

------------------------------------------------------------------------

# 8. Safe deletion model

This is the most important technical part of PurgeKing.

## 8.1 Never use an unrestricted deletion primitive

Avoid patterns like:

``` bat
del /s /q "%SOME_VARIABLE%\*.*"
rd /s /q "%SOME_VARIABLE%"
```

unless the target has been fully validated and the operation is
specifically intended. These commands can be catastrophic when a
variable is empty, malformed, unexpectedly expanded, or points to the
wrong directory.

A robust implementation should use narrowly scoped deletion routines and
validate the target immediately before execution.

## 8.2 Required path validation

At minimum, a deletion routine should reject: - Empty strings. - `C:\`
or any drive root. - `%SystemRoot%` itself. - `%SystemRoot%\System32`. -
`%SystemRoot%\WinSxS`. - `%SystemRoot%\Installer`. -
`%SystemRoot%\System32\DriverStore`. - The entire user profile. - The
entire application-data root. - The entire browser profile root. - The
entire game or development project root. - UNC/network paths unless a
future feature explicitly supports them.

Also validate that the requested directory is an expected child of the
module's configured target. String-prefix checks alone can be
insufficient if path normalization, `..`, short names, junctions, or
reparse points are not handled carefully. Keep the set of target paths
small and fixed.

## 8.3 Delete contents, not parent directories

For cache directories, the intended operation is usually to remove
eligible contents while leaving the directory structure intact. Do not
remove the parent folder unless its removal is explicitly required and
independently validated.

## 8.4 Locked files and access denied

If a file is locked or access is denied: - Do not force-close the owning
application. - Do not take ownership. - Do not change ACLs. - Do not
disable security controls. - Log the item as skipped or failed. -
Continue with other eligible files if safe.

## 8.5 Reparse points and junctions

Directory junctions and symbolic links can point outside the expected
target. A recursive cleanup can unexpectedly traverse into another
directory tree. The implementation must avoid traversing reparse points
or use a native mechanism whose behavior is understood and tested. If
safe handling cannot be guaranteed in Batch, skip a directory containing
an unexpected reparse point and report it.

## 8.6 No registry cleaner

Registry cleanup is explicitly out of scope. Registry "cleaning" often
has uncertain benefit and can break application or system configuration.

------------------------------------------------------------------------

# 9. Analysis and storage estimation

The analysis engine should provide a useful estimate without making
destructive changes.

## 9.1 Metrics

For each target: - Target name. - Whether the path exists. - Eligible
file count. - Approximate eligible bytes. - Whether the target is
currently accessible. - Whether an application should be closed. -
Whether the module is optional. - Any reason the target was skipped.

## 9.2 Size calculation

CMD's native `for` and `for /r` constructs can enumerate files, but
arithmetic and large file sizes require care. CMD's `set /a` uses signed
32-bit integer arithmetic, which is not suitable for reliably
accumulating large byte totals.

Implementation options: 1. Use a safe, documented native utility for
size reporting if available on supported Windows versions. 2. Use
per-file values with a strategy that avoids 32-bit overflow. 3. Report
file counts and approximate size in a way that clearly states its
limitations. 4. If reliable byte totals cannot be calculated in pure
Batch, show "size estimate unavailable" rather than displaying a false
value.

The product must not silently overflow and show a misleading estimate.

## 9.3 Before-and-after free space

Capture system-drive free space before and after cleanup using a
supported native command. Treat the difference as a system-level
measurement, not an exact measure of PurgeKing's deletions. Windows,
browsers, and other applications may write files during the same period.

The final report should distinguish: - **Estimated eligible data:**
found during analysis. - **Deleted file count:** files successfully
removed where count is available. - **Observed free-space change:**
system drive free-space difference. - **Skipped/failed data:** files not
removed.

------------------------------------------------------------------------

# 10. Logging and diagnostics

## 10.1 Log location

For a portable application, prefer a `logs` directory beside the script:

``` text
PurgeKing/
  PurgeKing.bat
  logs/
    2026-10-31_2216.log
```

If the script directory is not writable, report the issue and use a
clearly documented per-user fallback such as a PurgeKing folder under
`%LOCALAPPDATA%`. Do not silently lose logs.

## 10.2 Log contents

A log should include: - PurgeKing version. - Date and time. - Windows
version/build. - Whether the process is elevated. - Selected
module(s). - Target names (not unnecessary personal file names). -
Analysis counts and estimates. - Actions attempted. - Success, skipped,
and failure counts. - Exit code or error text where available. - Final
summary.

## 10.3 Privacy

Logs remain local. Do not upload them. Avoid collecting: - Personal
document names. - Browser URLs or browsing history. - Passwords,
cookies, tokens, or environment secrets. - Full lists of user files. -
Hardware serial numbers. - Unnecessary account identifiers.

## 10.4 Example log

``` text
========================================================
PURGEKING LOG
Version: 1.0.0
Started: 2026-10-31 22:16:00
Mode: Quick Cleanup
========================================================

[INFO] Environment initialized.
[INFO] Target: User temporary files
[INFO] Target path validated.
[INFO] Eligible files: 128
[INFO] Approximate eligible size: 420 MB
[INFO] User confirmed cleanup.
[OK] Files removed: 121
[SKIP] Locked/in-use files: 7
[ERROR] Files failed: 0

[SUMMARY]
Deleted: 121
Skipped: 7
Failed: 0
Status: Completed with skipped files

========================================================
```

------------------------------------------------------------------------

# 11. Administrator and privilege model

Some Windows cleanup locations require elevation; others do not.

Recommended behavior: - User-level cleanup should run without elevation
where possible. - Administrator-only modules should detect the lack of
elevation and explain why they cannot run. - Do not automatically
relaunch as administrator for every action if it is not needed. - If the
initial product design chooses a single elevated session for simplicity,
show a clear User Account Control prompt and explain the reason. - Do
not attempt to bypass UAC. - Do not change ownership or permissions to
make a cleanup succeed.

A future release could split the workflow into: - **Standard mode:**
current-user temporary files, supported browser caches, and selected
developer caches. - **Administrator mode:** approved Windows-level
targets.

The first release should prioritize predictable behavior over privilege
complexity.

------------------------------------------------------------------------

# 12. Windows compatibility and native tools

PurgeKing should use native Windows components only. Candidate commands
include:

  -----------------------------------------------------------------------
  Command / utility       Intended role           Caution
  ----------------------- ----------------------- -----------------------
  `cmd.exe`               Main runtime            Core dependency

  `choice`                Menu input              Confirm
                                                  availability/behavior

  `for`                   Enumeration             Quote and scope paths
                                                  carefully

  `if`                    Validation and flow     Avoid ambiguous
                                                  expansion

  `setlocal`              Environment isolation   Use consistently

  `wmic`                  Legacy system queries   Deprecated/removed on
                                                  some systems; do not
                                                  depend on it

  `fsutil`                Filesystem information  May require elevation
                                                  for some operations

  `dism.exe`              Supported Windows       Separate optional
                          servicing               operation; never
                                                  imitate it with manual
                                                  deletion

  `cleanmgr.exe`          Windows Disk Cleanup,   Availability varies by
                          where available         Windows version

  `robocopy.exe`          Certain file            Do not use destructive
                          operations/reporting    mirror modes casually

  `wevtutil.exe`          Event log               Event log clearing is
                          administration          out of scope

  `tasklist.exe`          Process detection       Detection only; do not
                                                  force-close apps
  -----------------------------------------------------------------------

The script should not assume deprecated utilities exist. Detect
availability and degrade gracefully.

## 12.1 PowerShell exclusion

The agreed product constraint is **no PowerShell dependency**. Do not
call `powershell.exe` or `pwsh.exe` to perform the core cleanup,
analysis, or reporting. If a future feature truly cannot be implemented
safely in Batch, document it as unsupported rather than quietly
introducing a PowerShell dependency.

## 12.2 External dependencies

No: - Python runtime. - Node.js runtime. - Bash runtime. - Git
requirement. - Third-party command-line utility. - Downloaded
executable. - Network connection.

------------------------------------------------------------------------

# 13. Error handling

Every module should have explicit outcomes: - `SUCCESS` -
`SUCCESS_WITH_SKIPS` - `SKIPPED` - `CANCELLED` - `FAILED`

Examples: - Target does not exist: `SKIPPED`. - User declines:
`CANCELLED`. - Some files are locked: `SUCCESS_WITH_SKIPS`. - Target
path validation fails: `FAILED` and do not delete. - Required utility is
unavailable: `SKIPPED` or `FAILED`, with an explanation. - Logging
fails: warn the user; do not pretend the operation was logged.

One module failing should not automatically terminate the entire
application if the remaining modules can safely continue. However, a
global safety validation failure should stop destructive execution.

------------------------------------------------------------------------

# 14. Configuration and versioning

## 14.1 Central configuration

Keep version, retention period, feature toggles, and default module
selections near the top of the script.

Possible settings: - `APP_NAME` - `APP_VERSION` - `LOG_RETENTION_DAYS` -
`ENABLE_BROWSER_MODULE` - `ENABLE_DEVELOPER_MODULE` -
`ENABLE_GPU_MODULE` - `DEFAULT_PREVIEW_REQUIRED`

Do not scatter hard-coded paths across unrelated subroutines.

## 14.2 Versioning

Use semantic versioning:

-   `MAJOR`: incompatible behavior or major architecture changes.
-   `MINOR`: new modules or compatible features.
-   `PATCH`: fixes and safety improvements.

Every release should update the version in the script, help text, and
log header.

## 14.3 Target registry changes

Every new cleanup target must include: 1. Exact path or supported native
command. 2. Owning module. 3. Data type. 4. Risk assessment. 5. Whether
the application must be closed. 6. Whether administrator rights are
required. 7. Preview behavior. 8. Cleanup method. 9. Test evidence. 10.
Rollback/recovery implications, if any.

No new target should be added to "Run Everything" until it has passed
the test plan.

------------------------------------------------------------------------

# 15. Testing strategy

A cleanup tool must be tested as carefully as a system utility. Testing
should begin in a disposable Windows VM or test account, not on the
user's primary machine.

## 15.1 Unit-style tests

Test each helper routine independently: - Path is empty. - Path contains
spaces. - Path contains special characters. - Path is a drive root. -
Path is a protected Windows directory. - Path is missing. - Path is
read-only. - Path contains locked files. - Path contains nested
directories. - Path contains a junction/reparse point. - Path is
unexpectedly outside the allowlisted parent.

Expected result: unsafe targets are rejected, and no deletion occurs.

## 15.2 Module tests

For each module: - Target absent. - Target present but empty. - Target
contains disposable test files. - Target contains locked test files. -
Target contains nested folders. - User cancels. - User confirms. -
Partial access denied. - Application is running. - Required utility is
missing.

## 15.3 Integration tests

-   Launch from Explorer.
-   Launch from CMD in a different working directory.
-   Launch from a path containing spaces.
-   Launch from a non-administrator account.
-   Launch with administrator rights.
-   Run each command-line switch.
-   Run analysis, then cleanup.
-   Run cleanup twice.
-   Interrupt cleanup.
-   Check that logs are written.
-   Check that the main menu remains functional after module errors.

## 15.4 Regression tests

After every change, confirm: - No protected directory can be selected. -
No browser profile data is deleted. - No installed driver files are
deleted. - No user documents are touched. - No PowerShell dependency has
been introduced. - No external download/network call exists. - The
application still runs on supported Windows 10/11 test environments.

## 15.5 Acceptance criteria

The first release is acceptable when: - It runs as a single `.bat`
file. - It has no external dependencies. - It works offline. - It offers
the agreed menu and modules. - Analysis is non-destructive. - All
destructive actions are allowlisted and confirmed. - It refuses unsafe
paths. - It does not touch DriverStore, WinSxS, Installer, System32, or
user documents. - It produces understandable logs and summaries. - It
handles missing folders, locked files, and permission errors safely. -
Its documentation accurately describes limitations.

------------------------------------------------------------------------

# 16. Build and development workflow

## Phase 1 --- Foundation

Deliver: - `PurgeKing.bat` - Version constants. - Initialization. -
Script-directory detection. - Menu and input validation. - Help
screen. - Logging. - Safe exit.

Do not implement broad cleanup yet. First prove that the application
launches, logs, and handles invalid input correctly.

## Phase 2 --- Safety framework

Deliver: - Target allowlist. - Path validation. - Protected-path
rejection. - Reparse-point policy. - Dry-run analysis. - Confirmation
framework. - Safe deletion helpers. - Outcome and error reporting.

This phase must be complete before any real cleanup module is added.

## Phase 3 --- Low-risk cleanup

Implement and test: 1. Current-user temporary-file cleanup. 2. PurgeKing
log retention. 3. System report.

Test in a VM and inspect the filesystem after each run.

## Phase 4 --- Specialized modules

Add individually: 1. Windows cleanup. 2. NVIDIA shader-cache cleanup. 3.
Browser cache cleanup. 4. Developer cache cleanup.

Each module requires its own target review and test cases.

## Phase 5 --- Presets and reporting

Add: - Deep Cleanup. - Run Everything. - Per-module estimates. -
Before/after free-space report. - Final cleanup summary.

## Phase 6 --- Release hardening

Complete: - Windows 10 and 11 compatibility tests. - Standard-user and
administrator tests. - Special-character path tests. - Locked-file
tests. - Documentation. - Versioning. - Release notes. - Final safety
audit.

------------------------------------------------------------------------

# 17. Suggested repository layout

The delivered utility is one Batch file. During development, a small
repository can keep documentation and test fixtures organized:

``` text
PurgeKing/
│
├── PurgeKing.bat
├── README.md
├── LICENSE
├── CHANGELOG.md
├── docs/
│   ├── ARCHITECTURE.md
│   ├── SAFETY.md
│   ├── MODULES.md
│   └── TESTING.md
│
├── tests/
│   ├── test-plan.md
│   └── fixtures/
│       ├── temp-files/
│       ├── nested-folders/
│       └── locked-file-notes.md
│
└── logs/
    └── (generated at runtime)
```

The release package can contain only `PurgeKing.bat` and a README, with
logs created on first run. The development repository may contain more
documentation and test material.

------------------------------------------------------------------------

# 18. Risks and mitigations

  -----------------------------------------------------------------------
  Risk                    Impact                  Mitigation
  ----------------------- ----------------------- -----------------------
  Incorrect               Deletes wrong path      Reject empty paths;
  environment-variable                            validate exact
  expansion                                       allowlisted target

  Recursive deletion      Deletes data outside    Detect/avoid reparse
  crosses a junction      target                  points; skip uncertain
                                                  trees

  Windows update is       Files locked or         Skip and ask user to
  active                  servicing disrupted     retry later

  Browser is running      Partial cleanup or      Require browser closed;
                          profile issues          never force-close

  Shader cache rebuild    Temporary first-run     Explain expected
                          stutter                 behavior

  Developer cache         Rebuild or project      Use native cache
  contains useful state   failure                 commands; opt-in module

  CMD arithmetic overflow Incorrect storage       Use safe size strategy;
                          estimate                show unavailable when
                                                  uncertain

  Permissions differ by   Partial cleanup         Log access denied; do
  system                                          not change ACLs

  Windows version         Missing commands/paths  Detect capabilities;
  differences                                     skip unsupported
                                                  actions

  User mistakes a driver  Driver damage           Separate installer
  installer leftover for                          leftovers from
  a driver                                        installed driver
                                                  storage

  Log directory is not    Missing diagnostics     Use documented fallback
  writable                                        and warn

  Script is modified or   Unsafe behavior         Keep source readable;
  corrupted                                       version releases;
                                                  publish checksums if
                                                  distributed
  -----------------------------------------------------------------------

------------------------------------------------------------------------

# 19. Explicitly protected locations and data

The following are out of scope for manual deletion:

``` text
%SystemRoot%\System32
%SystemRoot%\WinSxS
%SystemRoot%\Installer
%SystemRoot%\System32\DriverStore
%ProgramFiles%
%ProgramFiles(x86)%
%USERPROFILE%\Documents
%USERPROFILE%\Desktop
%USERPROFILE%\Downloads
Browser profile roots
Game installation directories
Game saves and configuration
Development repositories and source files
Virtual environments and installed packages
Docker volumes, images, and containers
Windows servicing metadata
```

This list is a minimum, not a complete list of every protected Windows
location. The implementation must use explicit target allowlists rather
than assuming that anything not listed here is safe to delete.

------------------------------------------------------------------------

# 20. Definition of done for version 1.0

PurgeKing v1.0 should be considered complete only when all of the
following are true:

-   [ ] Single portable `PurgeKing.bat` application.
-   [ ] Windows 10/11 support documented and tested.
-   [ ] No PowerShell, Bash, Python, Node, or external runtime
    dependency.
-   [ ] Offline operation.
-   [ ] Main menu and help screen.
-   [ ] Command-line switches.
-   [ ] Central target allowlist.
-   [ ] Path validation and protected-path rejection.
-   [ ] Analysis mode that performs no deletion.
-   [ ] Confirmation before destructive operations.
-   [ ] Quick Cleanup.
-   [ ] Windows Cleanup with conservative scope.
-   [ ] NVIDIA/GPU shader-cache cleanup with driver protection.
-   [ ] Browser cache cleanup with profile protection.
-   [ ] Developer cache cleanup with opt-in scope.
-   [ ] Deep Cleanup preset.
-   [ ] Run Everything workflow.
-   [ ] System Health Report.
-   [ ] Timestamped logs and final summary.
-   [ ] Locked-file and access-denied handling.
-   [ ] No registry cleaning.
-   [ ] No manual WinSxS, DriverStore, Installer, or System32 deletion.
-   [ ] Test plan completed in a disposable environment.
-   [ ] README, safety documentation, and changelog.

A module that has not passed its tests should remain disabled or marked
experimental. It should not be included in the default all-in-one
cleanup.

------------------------------------------------------------------------

# 21. Future roadmap

Potential improvements after v1.0:

## v1.1 --- Better diagnostics

-   More accurate per-target size estimation.
-   Better locked-file reporting.
-   Exportable text report.
-   Improved Windows version detection.

## v1.2 --- More cleanup providers

-   Additional GPU vendors after validation.
-   More browser support.
-   More developer tools after native cleanup behavior is reviewed.

## v1.3 --- Scheduling and profiles

-   User-defined cleanup profiles.
-   Optional scheduled analysis (not silent deletion).
-   Configurable log retention.
-   Explicit opt-in for unattended cleanup only after a separate safety
    design.

## v2.0 --- Optional companion interface

A graphical interface is not part of the current scope. The single-file
CMD application remains the product baseline. Any future GUI should be a
separate, explicitly approved project rather than an unplanned
dependency added to PurgeKing.

------------------------------------------------------------------------

# 22. Final product definition

PurgeKing is a **portable Windows maintenance toolkit implemented as a
single native CMD Batch file**. It offers modular cleanup for selected
temporary files, Windows download leftovers, GPU shader caches, browser
caches, and developer caches. It provides read-only analysis, explicit
user confirmation, strict path validation, local logs, and clear
reporting.

Its defining feature is not how aggressively it deletes files. Its
defining feature is that it makes cleanup understandable and controlled.

**Product rule:** If PurgeKing cannot confidently prove that a target is
within its approved cleanup scope, it must skip that target.

------------------------------------------------------------------------

# Appendix A --- Implementation checklist for every new cleanup target

Before adding a target, answer all questions:

1.  What application or Windows component owns this directory?
2.  What exact data is stored there?
3.  Is the data genuinely disposable?
4.  Does deleting it remove credentials, sessions, history, profiles,
    settings, saves, or installed software?
5.  Can the owning application be running?
6.  Does the application need to be closed?
7.  Is there an official/native cleanup command?
8.  Is manual deletion supported and understood?
9.  Can the path be derived safely on all supported Windows versions?
10. Can the path be validated against a fixed allowlist?
11. Can a junction or symbolic link escape the intended directory?
12. Can the analysis engine estimate the eligible data without modifying
    it?
13. What happens if a file is locked?
14. What happens if access is denied?
15. Is administrator access actually required?
16. Is the target appropriate for Quick Cleanup, Deep Cleanup, or
    optional cleanup?
17. What warning must the user see?
18. What test proves the cleanup is safe?
19. What evidence will be recorded in the log?
20. Who reviewed and approved the target?

If any critical question is unanswered, do not enable the target.

# Appendix B --- Suggested first implementation order

For a practical first coding session, implement in this order:

1.  Script header, version, and `setlocal`.
2.  Script directory and log directory handling.
3.  Main menu and input validation.
4.  Help and safety screen.
5.  Logging subroutines.
6.  Admin/elevation detection without automatic privilege escalation.
7.  Target registry and path validation.
8.  Read-only analysis for one test directory.
9.  Safe cleanup of a test fixture directory.
10. Current-user temporary-file module.
11. System report.
12. GPU, browser, Windows, and developer modules one at a time.
13. Presets and final polish.

**Do not begin by writing one giant `del /s /q` command. Build the
safety framework first.**
