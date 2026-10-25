# DQVII UE4SS Compatibility Core v0.1.0

Prerelease for Dragon Quest VII Reimagined Steam build 22412021, executable 1.1.1.0. The pinned upstream runtime crashes before Lua loads with its default listener layout. This profile corrects FUObjectArray creation/deletion listener offsets to `0x70`/`0x80`, retaining upstream hooks and ProcessEvent slot 68.

Includes UE4SS 3.0.1-1181-g83330635, a harmless F6 ClientRestart observer, a build-gated PowerShell installer/uninstaller, backup/restore support, complete compatibility sources, validation notes, and SHA-256 manifests. Debug GUI, hot reload, and signature cache are disabled. Optional F7 reflection QA source is included but not enabled in the payload.

The packaged probe was tested through title, existing adventure load, two real native callbacks, F6 status, and clean exit. Separate F7 QA passed object/bool/integer/FString checks before and after loading. Six installer fixture checks and real-game install/verify/uninstall/reinstall checks passed. See `VALIDATION.md` for details.

Other builds/stores, the demo executable, arbitrary mods, SDK dumping, GUI, console support, battles, and long sessions are untested. No game data or saves are included. Close the game before installing and launch through Steam. Like normal gameplay, loading a save can update autosave/system data; keep your own backups.
