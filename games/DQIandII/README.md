# DQI & II UE4SS Compatibility Core 0.1.0 (prerelease)

A Lua scripting and native-hook starting point for **Steam Dragon Quest I & II
HD-2D Remake 1.0.2**, build **21744054**, Unreal Engine **4.27.2**. Both adventures
were tested separately with existing manual saves.

Bundles the unchanged official **UE4SS 3.0.1-1181-g83330635** runtime, a separate
I & II profile, settings, and a small F6 callback observer. No member-layout
overrides, custom signatures, game assets, or game executable changes are used.

## Install

Close the game and extract the installable release ZIP to a separate folder.
Open PowerShell in the extracted folder and run, adjusting the game location:

```powershell
.\Manage-DQIandII.ps1 -Action Install -GameDirectory 'C:\Program Files (x86)\Steam\steamapps\common\DRAGON QUEST I and II HD-2D Remake'
```

If Windows blocks a downloaded script, review it and use the file's Properties
**Unblock** option. The installer checks the tested game executable SHA-256 and
every payload hash before writing. Existing payload files are refused. Review an
existing installation before using `-ReplaceExisting`, which backs up the seven
files this release owns. Move older root-layout UE4SS installations aside first.
Unrelated mods can remain under `ue4ss/Mods`; check compatibility separately.

Launch through **Play in Steam**. Choose either I or II and load an adventure.
Press **F6**, then inspect `Game/Binaries/Win64/ue4ss/UE4SS.log`. The included
`DQIandIIProbe` observes `PlayerController:ClientRestart` without changing its
arguments or return value. Look for `LUA_OK`, `HOOK_READY`, `HOOK_FIRED` and a
nonzero count. Registration alone does not prove a callback ran.

To disable the observer, remove its `enabled.txt` while the game is closed;
restore that file before installer verification or uninstallation.

## Verify and uninstall

```powershell
.\Manage-DQIandII.ps1 -Action Verify -GameDirectory 'C:\path\to\DRAGON QUEST I and II HD-2D Remake'
.\Manage-DQIandII.ps1 -Action Uninstall -GameDirectory 'C:\path\to\DRAGON QUEST I and II HD-2D Remake'
```

Uninstall checks every owned file first, refuses later edits, and restores any
files backed up by `-ReplaceExisting`. Preserve your edits elsewhere and restore
the release's bytes before retrying. It leaves logs, unrelated mods, and
`.dqiandii-ue4ss-core` receipts/backups. It does not manage saves, pak files,
`dsound.dll`, ASI plugins, or global `mods.txt` files. Uninstall remains available
after a game update; installation and verification require the tested build.

## Compatibility profile and limits

- **ProcessEvent slot 69 / 0x228** is needed for reflected calls, as in III. The
  profile overrides only that named virtual entry and leaves other default
  entries intact. Actual integer and string return checks passed in both games.
- **`HookInitGameState = 0` is required by this profile.** Startup crashed with
  the hook enabled, including with print-only Lua and with VM hooks disabled.
  Disabling it restored startup while the other settings returned to III's full
  profile. The underlying mismatch has not been repaired or fully mapped.
  `RegisterInitGameStatePreHook` and `RegisterInitGameStatePostHook` are unavailable.
- **`HookLoadMap = 0` is retained from III's workaround.** LoadMap Lua hooks are
  unavailable. Enabling this hook in I & II has not been validated.
- Confirmed: Lua startup; actual ClientRestart callbacks on manual save loads in
  **both I and II**; object lookup and full-name conversion; reflected boolean
  reads; integer addition and engine-version string returns on the game thread.
- The graphical inspector, SDK generation, hot reload, arbitrary mods, battles,
  other game builds/platforms, and long play sessions remain unvalidated. GUI and
  external consoles are disabled. This is an initial compatibility prerelease.

The temporary F7 API diagnostic is included under `SOURCE/tests/api-checks.lua`
for reproducibility and is not installed by default. It performs read-only calls
through `ExecuteInGameThread`. See [VALIDATION.md](VALIDATION.md) for the test
matrix and sanitized logs. Existing ASI plugins stayed in place during testing.

## Reproduce the package

Use Python 3.10+ and the exact official developer archive recorded in
`manifest.json` from [the upstream experimental release](https://github.com/UE4SS-RE/RE-UE4SS/releases/tag/experimental-latest).
The tag moves; the builder rejects an archive or DLL that differs from the pinned
SHA-256 values. Both bundled DLLs are unchanged upstream binaries.

```powershell
python games/DQIandII/build_package.py --runtime-archive zDEV-UE4SS_v3.0.1-1181-g83330635.zip --output DQIandII-UE4SS-Compatibility-Core-v0.1.0.zip
```

The ZIP contains compatibility sources, notices, runtime provenance, internal
SHA-256 sums and a MIT license. The adjacent `.sha256` file covers the complete
ZIP. GitHub's automatic source archives do not include the runtime payload.
No game executables, assets, saves, private logs, memory dumps or DQXI mod files
are redistributed. Thanks to the UE4SS maintainers and the DQXI community's Hook
Core work that informed this investigation.
