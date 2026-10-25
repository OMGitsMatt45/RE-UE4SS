# DQIII UE4SS Compatibility Core 0.1.0 (prerelease)

A tested Lua scripting and native-hook starting point for **Steam Dragon Quest III
HD-2D Remake 1.2.1**, build **19495987**, Unreal Engine **4.27.2**.

Bundles the **unchanged upstream UE4SS 3.0.1-1181-g83330635** runtime, a III-specific
ProcessEvent vtable profile, settings, and a small callback observer. This is a
compatibility distribution, not a newly compiled engine or gameplay overhaul.
The repository release branch starts at the exact bundled upstream revision.

## Install

1. Close III. Extract the release ZIP to a separate folder.
2. Open PowerShell in the extracted folder and run, adjusting the game location:

```powershell
.\Manage-DQIII.ps1 -Action Install -GameDirectory 'C:\Program Files (x86)\Steam\steamapps\common\DRAGON QUEST III HD-2D Remake'
```

If Windows blocks a downloaded script, review it and use the file's Properties
**Unblock** option. The installer refuses unrecognized executable hashes and
existing payload files. Review an existing installation before using
`-ReplaceExisting`, which backs up only the seven files this release owns.
Older root-layout UE4SS installations must be moved aside first. Other UE4SS mods
can remain under `ue4ss/Mods`; check their compatibility separately.

Launch with **Play in Steam**. The included `DQIIIProbe` observes
`PlayerController:ClientRestart`. Load an existing adventure, then press **F6**.
Look in `Game/Binaries/Win64/ue4ss/UE4SS.log` for `LUA_OK`, `HOOK_READY`,
`HOOK_FIRED` and a nonzero callback count. Registration alone is not evidence that
a callback ran. To disable the observer, remove its `enabled.txt` with the game
closed (restore it before installer verification/uninstallation).

## Verify and remove

```powershell
.\Manage-DQIII.ps1 -Action Verify -GameDirectory 'C:\path\to\DRAGON QUEST III HD-2D Remake'
.\Manage-DQIII.ps1 -Action Uninstall -GameDirectory 'C:\path\to\DRAGON QUEST III HD-2D Remake'
```

Uninstall restores files backed up by `-ReplaceExisting`. It checks all owned
files before making changes and refuses if you edited them later. Retain your
edits elsewhere and restore the release's bytes before retrying. Logs, unrelated
mods, and `.dqiii-ue4ss-core` receipts/backups remain. No saves, pak assets,
`dsound.dll`, ASI plugins, or global `mods.txt` files are installed or removed.
Uninstall is still available after a game update; install/verify require the
tested executable. Updates require a new compatibility test.

## Compatibility and limits

- `UObject::ProcessEvent` uses slot **69**, byte offset **0x228**, in this game.
  The profile changes only that named entry. The unused entries keep unrelated
  class tables intact; no XI S member-layout profiles or signatures are copied.
- **`HookLoadMap = 0` is required by this profile.** The legacy detour's FURL copy
  crashed in the 3.0.1 investigation. Lua LoadMap hook APIs are unavailable here.
  The newer build is shipped with that detour disabled too.
- Confirmed: Lua startup, native ClientRestart callbacks on loading an adventure,
  object lookup/name conversion, a reflected boolean read, and game-thread
  ProcessEvent integer/string return checks. See [VALIDATION.md](VALIDATION.md).
- Graphical inspector, SDK dumps, hot reload, arbitrary gameplay scripts,
  multiplayer, other platforms/builds, and long play sessions are unvalidated.
  GUI and external consoles are disabled by default. This is an early prerelease.
- The optional `SOURCE/tests/api-checks.lua` is a manual F7 diagnostic; it is not
  installed by default. It runs read-only calls in `ExecuteInGameThread`.

## Reproduce

Download the exact official developer archive recorded in `manifest.json` from
[the upstream experimental release](https://github.com/UE4SS-RE/RE-UE4SS/releases/tag/experimental-latest).
The experimental tag moves; the builder checks the pinned archive SHA-256 and
both DLL hashes and will reject a different download.

```powershell
python games/DQIII/build_package.py --runtime-archive zDEV-UE4SS_v3.0.1-1181-g83330635.zip --output DQIII-UE4SS-Compatibility-Core-v0.1.0.zip
```

The package contains exact compatibility sources, per-file SHA-256 sums, runtime
provenance, and the MIT license. It contains no game binaries/assets, save files,
private logs, memory dumps, or third-party DQXI mod files. Thanks to the UE4SS
maintainers and the DQXI community's Hook Core work that informed this investigation.
