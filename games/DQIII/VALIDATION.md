# III core 0.1.0 validation

Tests performed on 2026-10-24/25 (America/New_York), using normal Steam Library
Play launches, the existing game installation, and its existing ASI plugins.

## Pinned inputs

- Steam AppID 2701660, build 19495987, game 1.2.1 (title screen 1.2.1.0), UE4.27.2.
- Executable SHA-256:
  `00762b2cec4a91373f8ac8479666bfa6dc7d8267e530bcb352e90b5624ac5af0`.
- Official UE4SS `3.0.1-1181-g83330635`, source
  `8333063595fa3c49ad307f3b0f732accbb760d25`. Both DLLs are byte-identical to the
  pinned official developer ZIP. Archive/DLL hashes are enforced by the builder.
- Nested `ue4ss` layout, `HookLoadMap=0`, ProcessEvent slot 69/0x228.
  No member-layout overrides or custom signatures. GUI, hot reload, signature
  cache, and external console disabled. Other hook settings use upstream defaults.

## Runtime observations

The manual diagnostic at `tests/api-checks.lua` ran in one normal Steam session:

1. Startup logged `LUA_OK` and registered a native ClientRestart hook.
2. F7 at the title menu used `ExecuteInGameThread`. Object lookup/full-name
   conversion succeeded; PlayerController's `bShowMouseCursor` read as false.
   `KismetMathLibrary:Add_IntInt(7,5)` returned 12 and
   `KismetSystemLibrary:GetEngineVersion():ToString()` returned
   `4.27.2-0+++UE4+Release-4.27`.
3. Loading an existing manual adventure reached the church scene and fired two
   actual native PRE callbacks. No parameters or return values were changed.
4. F7 repeated all four API checks successfully in the loaded map; F6 reported 2.
5. The game was closed without advancing dialogue or performing a save.

See `tests/runtime-evidence.txt` for a sanitized log excerpt. Private file paths,
account identifiers, game object addresses, and complete logs are excluded.

The original 3.0.1 investigation also booted and fired native callbacks with
LoadMap disabled. Enabling its LoadMap hook crashed while copying FURL, resolved
with the matching official PDB (`HookedLoadMap -> FURL copy -> FString copy`).
The modern runtime is tested with that hook disabled; enabling it is unsupported.
The stock UE4.27 ProcessEvent slot is 68; the current executable's unique
ProcessEvent function at RVA 0x1696990 appears at slot 69 in contiguous vtables.
The runtime reports the 0x228 override and the reflected-call checks above pass.

## Installer and packaging checks

`python games/DQIII/tests/test_installer.py -v` exercises Windows PowerShell 5.1
against isolated fake-game fixtures. Production executable pinning is replaced
only in fixture copies of the installer; no bypass switch is shipped.

- Install, verify, and uninstall preserve unrelated mods and the ASI loader.
- Existing files are refused by default; replacement backups restore exact bytes.
- Unknown builds, legacy root-layout installs, and corrupt payloads are refused.
- Uninstall refuses all changes when an owned file has later edits.
- An injected partial-write failure restores the previous proxy bytes.
- Malformed manifest/receipt paths cannot escape the game directory.

The deterministic builder checks the official archive and runtime hashes and
packages only an explicit runtime allowlist plus compatibility sources. The
installable payload contains seven files. No game EXE, assets, saves or dumps are
redistributed. GitHub source archives are not installable runtime packages.

The extracted release package was then installed into the actual game directory.
Verification matched all seven payload hashes. A normal Steam launch reached
the title screen and loaded the existing adventure; the shipped `DQIIIProbe`
fired twice and F6 reported `HOOK_READY; count=2`. Steam recorded exit code 0.
See `tests/package-evidence.txt`. All seven original Win64 files and all four
existing save files retained their pre-test SHA-256 hashes. On the real game
directory, Verify, Uninstall, Install, and Verify completed successfully; all
seven owned payload files were absent after Uninstall and restored by Install.
The tested release is left installed, with the temporary API diagnostic removed.
The ZIP was rebuilt byte for byte from its included compatibility sources, and
every file listed in its internal SHA256SUMS.txt passed verification.

## Scope

This is a short startup/load/reflection smoke test on one Windows Steam build,
not a complete engine ABI audit or a long gameplay stability test. No claim is
made for arbitrary mods, all property/return types, graphical inspection, SDK
generation, hot reload, other game updates, or the other remakes.
