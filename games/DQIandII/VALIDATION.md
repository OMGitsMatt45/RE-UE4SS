# I & II investigation log

Tested installation: Steam 1.0.2 / title screen 1.0.2.0, build 21744054,
AppID 2893570. Runtime: unchanged UE4SS 3.0.1-1181-g83330635. All launches use
Steam Library Play. No game executables or pak assets have been edited.

The five original Win64 files were hashed before testing. Seven existing save
files were copied to private backups and their SHA-256 hashes verified. All seven
save files still matched after the initial startup isolation tests.

| Trial | Configuration | Observation |
|---|---|---|
| Baseline | Original installation and existing ASI plugins | Title screen; clean exit code 0 |
| 01 | III-derived settings, ProcessEvent slot 69, native QA probe | Lua starts and registers ClientRestart; startup crash before menu |
| 02 | Same configuration, print-only Lua script | Same fault and game call stack; native hook registration ruled out |
| 03 | Print-only script, UStructLink hook disabled | Same startup fault |
| 04 | Optional hooks off, object cache off, forced GUObjectArray iteration | Lua print runs, title screen reached, clean exit code 0 |
| 05 | Trial 04 plus ProcessInternal, ProcessLocalScriptFunction, InitGameState, CallFunctionByNameWithArguments, BeginPlay and LocalPlayerExec | Same startup fault |
| 06 | Trial 05 with the two VM hooks disabled | Same startup fault |
| 07 | Trial 05 with InitGameState disabled | Title screen; clean exit code 0 |
| 08 | III-derived configuration with only InitGameState additionally disabled; full native/API QA | Title and II adventure load; reflected calls pass; two native callbacks; clean exit code 0 |

Repeated fault: access violation reading 0x11a, faulting executable RVA 0x2fc07bc.
The game call stack includes ProcessEvent at RVA 0x18611d2. Raw crash reports,
memory dumps, private logs and account paths remain outside this source folder.
Crash reporters were closed without sending reports.

Static candidate: ProcessEvent RVA 0x1860ef0, size 924 bytes; 96.48% similarity
across the first 256 bytes to III's identified function. Slot 69/0x228 dominates
the contiguous vtable pointer runs. Actual reflected-call checks are still needed.

The successful full candidate has `HookInitGameState=0` and `HookLoadMap=0`.
Other hook settings, the object cache and automatic object hash tables retain
their upstream defaults. The hash table self-test passes. Slot 69 is now also
verified through actual calls: object full-name conversion, a reflected bool
read, Add_IntInt(7,5) returning 12, and GetEngineVersion returning
4.27.2-0+++UE4+Release-4.27, dispatched through ExecuteInGameThread.

Dragon Quest II: an existing manual adventure loaded into the saved scene,
ClientRestart PRE fired twice, F6 reported 2, and F7 repeated all API checks
successfully. No movement, dialogue advancement or save commands were performed.
Steam recorded exit code 0; all seven save hashes remained unchanged.
See tests/DQII-evidence.txt for sanitized observations.

Dragon Quest I: a separate full-profile Steam launch selected I and loaded an
existing manual adventure into Tantegel. A tutorial overlay was left untouched.
ClientRestart PRE fired twice, F6 reported 2, and F7 passed the same API checks.
Steam recorded exit code 0; all seven save hashes and all five original Win64
file hashes remained unchanged. See tests/DQI-evidence.txt.

The startup issue is isolated to enabling the default InitGameState hook. This
does not fully map the underlying mismatch; the hook remains disabled.
All other hooks are left at the tested III profile/upstream defaults, but their
individual callback semantics are not certified by these smoke tests. Long play,
battles, arbitrary mods, GUI, SDK dumping and hot reload are unvalidated.

The I & II installer uses the tested III file-ownership approach with its own game
executable pin, process check, probe directory and receipt directory. All six
Windows PowerShell 5.1 fixture tests pass: install/verify/uninstall preservation,
collision refusal and backup restoration, unknown-build/legacy/corrupt-payload
refusal, edited-file preservation, partial-write rollback, and manifest/receipt
path rejection. The fixture pin is changed only in temporary test copies.

The extracted package also passed Install, Verify, Uninstall, Install, and Verify
on the real game directory. Two further normal Steam launches then tested the
shipped DQIandIIProbe separately in II and I. Each loaded the existing manual
adventure, fired two native PRE callbacks and reported `HOOK_READY; count=2` on
F6. Both exited with code 0. See tests/DQII-package-evidence.txt and
tests/DQI-package-evidence.txt. Final verification matched all seven installed
payloads, all five original Win64 files and all seven existing save files.
The API diagnostic is removed from the active installation; only the shipped
observer remains enabled.

The package was rebuilt byte for byte using its included compatibility sources,
and every internal checksum passed. The builder checks the exact official
runtime archive and both DLL hashes. Only its explicit seven-file runtime/profile
allowlist plus compatibility sources and documentation are packaged; private
game files, saves and crashes are not included.
