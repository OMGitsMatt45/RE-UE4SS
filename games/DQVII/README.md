# Dragon Quest VII Reimagined UE4SS Compatibility Core

Version 0.1.0 packages pinned upstream UE4SS with the two object-listener offsets needed by the tested Steam build of VII. It includes a harmless Lua callback observer and a build-gated installer with backup and uninstall support.

## Tested build

| Component | Version |
|---|---|
| Game | Steam AppID 2499860, build 22412021, executable 1.1.1.0 |
| Engine | 4.27.2-0+++UE4+Release-4.27 |
| UE4SS | 3.0.1-1181-g83330635 |
| Runtime source commit | 8333063595fa3c49ad307f3b0f732accbb760d25 |

`DQ7R/Binaries/Win64/DQ7R-Win64-Shipping.exe` must have SHA-256:

```text
83c568ca6de8d8429a1926b79d2b78b0175d7d6fecd304ecb2cf7b5b32a27404
```

Other builds, stores, and the demo executable are untested. The installer refuses unknown executable bytes. Uninstall remains available after a game update.

## Install

Extract the complete release ZIP. Close VII, then run PowerShell from the extracted folder:

```powershell
.\Manage-DQVII.ps1 -Action Install -GameDirectory 'C:\Program Files (x86)\Steam\steamapps\common\DQ7R'
```

`GameDirectory` is the Steam game root containing the outer `DQ7R.exe` and the `DQ7R` subdirectory. Launch normally through Steam. Mods live under `DQ7R/Binaries/Win64/ue4ss/Mods`.

The installer checks all seven payload files before changing the game and refuses collisions by default. After reviewing existing files, `-ReplaceExisting` explicitly backs up and replaces only those seven owned paths. Uninstall restores those backups. Existing ASI loaders, ASI mods, unrelated Lua mods, game data, and saves are outside the payload. Move root-layout UE4SS installations aside manually first. Do not mix this package with the III/I & II overrides.

## Verify and uninstall

```powershell
.\Manage-DQVII.ps1 -Action Verify -GameDirectory 'C:\Program Files (x86)\Steam\steamapps\common\DQ7R'
.\Manage-DQVII.ps1 -Action Uninstall -GameDirectory 'C:\Program Files (x86)\Steam\steamapps\common\DQ7R'
```

Close the game first. Verify checks the tested executable and installed payload hashes. Uninstall preflights every owned file and required backup, and refuses to overwrite later edits. Logs, receipts, backups, and unrelated mods remain on disk.

## Probe and compatibility change

`DQVIIProbe` only observes `/Script/Engine.PlayerController:ClientRestart`; it does not alter parameters or return values. In `ue4ss/UE4SS.log`, expect `LUA_OK`, `LOOKUP_OK`, `HOOK_READY`, then `HOOK_FIRED` when the game calls it. F6 reports the count and can retry an initially absent target lookup. Callback logging stops after five hits.

`MemberVariableLayout.ini` supplies:

```ini
[FUObjectArray]
UObjectCreateListeners = 0x70
UObjectDeleteListeners = 0x80
```

Without these offsets the pinned runtime crashes while adding a delete listener. Disabling the object cache does not fix that failure because UE4SS still adds a shutdown listener. The correction keeps the cache enabled and retains upstream hook and vtable defaults. ProcessEvent uses stock slot 68; no `VTableLayout.ini` is supplied.

`tests/api-checks.lua` is optional diagnostic source, not an enabled payload. F7 checks object lookup/naming, a reflected bool, an integer ProcessEvent call, and an FString return on the game thread. See `VALIDATION.md` for recorded coverage.

The debug GUI, hot reload, and signature cache are disabled. The default scanner reports an ambiguous optional ConsoleManagerSingleton result; console support is not established. Arbitrary Lua/C++ mods, GUI, SDK dumping, battles, long sessions, and other game versions are outside these smoke tests.

## Rebuild and source

The exact sources are included under `SOURCE/`. Python 3.10+ rebuilds the package without third-party dependencies:

```powershell
python .\SOURCE\build_package.py --runtime-archive .\zDEV-UE4SS_v3.0.1-1181-g83330635.zip --output .\DQVII-UE4SS-Compatibility-Core-v0.1.0.zip
```

Obtain that archive from [upstream UE4SS](https://github.com/UE4SS-RE/RE-UE4SS/releases/download/experimental-latest/zDEV-UE4SS_v3.0.1-1181-g83330635.zip). The builder verifies the archive and both DLL hashes. The upstream experimental tag can move; pinned bytes are authoritative. The ZIP uses fixed timestamps, normalized source line endings, an explicit payload allowlist, and SHA-256 manifests.

Run fixture checks with `python .\SOURCE\tests\test_installer.py`. Only temporary fixture copies replace the production executable pin. UE4SS and this compatibility source are MIT licensed; licenses are included. No game binaries, assets, saves, private dumps, or authentication data are distributed. The supplied DQXI S Hook Core informed the callback test plan; this profile and probe use public UE4SS APIs.
