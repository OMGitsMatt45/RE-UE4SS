# DQVII 0.1.0 validation

Local Windows Steam smoke tests on 2026-10-25, using the existing ASI setup. This records the tested features and the limits of the prerelease.

## Provenance

- Steam AppID 2499860, build 22412021; executable file/product version 1.1.1.0.
- Reflected engine string: `4.27.2-0+++UE4+Release-4.27`.
- Executable SHA-256: `83c568ca6de8d8429a1926b79d2b78b0175d7d6fecd304ecb2cf7b5b32a27404`.
- Official runtime ZIP SHA-256: `82378cd7f679d055026286f11347355ac67c712f21eb892060c902bb0184b907`.
- UE4SS.dll SHA-256: `ce5e3c46a920cc00b2817ac61e438c9162830290379d0b5b9c4dfc2b29459290`.
- dwmapi.dll SHA-256: `93b9431a5a4f32c675d269c5da1c9b3ec6f88552ec20c282ab435f411e9271fb`.
- Runtime source commit: `8333063595fa3c49ad307f3b0f732accbb760d25`.

## Diagnosis

The original setup, including the ASI loader and Classic Vocations ASI, reached the title and exited normally (Steam exit code 0). All nine save files, including demo saves, were backed up and hash verified before testing.

The first candidate used upstream hooks and layouts, with only debug GUI, hot reload, and signature cache disabled. It crashed before Lua initialized: access violation reading null at UE4SS.dll RVA `0x43c4a0`. The matching official PDB maps that instruction to `FUObjectArray::AddUObjectDeleteListener + 0x40`. Disassembly shows the runtime reading the expected listener array's count and pointer, then dereferencing a null pointer with a nonzero count.

A second launch changed only `bUseUObjectArrayCache` to false. It failed at the same instruction when adding the shutdown listener. Disabling the cache is therefore not a sufficient workaround.

Static references identify GUObjectArray at game RVA `0x5ea7660`. The shutdown code at RVA `0x1e08d40` iterates the delete-listener array at + `0x80`, with an assertion string identifying the delete listeners. The corresponding creation-listener array is at + `0x70`. The runtime had used + `0x78` for deletion. Two entries in `MemberVariableLayout.ini` correct creation to `0x70` and deletion to `0x80`.

With these entries and the cache restored, UE4SS initialized, loaded Lua, registered a native ClientRestart hook, and delivered a callback. Its hash-table self-test passed. No upstream hooks were disabled for this candidate.

VII's ProcessEvent at RVA `0x1dfe760` closely matched the identified III function and appeared at slot 68 in the dominant contiguous vtables. UE4SS's stock layout resolved that address. Reflected integer and string calls provide runtime evidence for retaining this layout instead of the HD-2D slot-69 override.

## Runtime checks

F7 in the temporary QA mod schedules these read-only checks through `ExecuteInGameThread`:

- `StaticFindObject`, `IsValid`, and `GetFullName` for KismetSystemLibrary.
- Reflected `PlayerController.bShowMouseCursor` returns a bool.
- `KismetMathLibrary:Add_IntInt(7, 5)` returns 12.
- `KismetSystemLibrary:GetEngineVersion():ToString()` returns the engine string above.

All four passed during the opening/title sequence and again after loading an existing adventure into Pilchard Bay: Church. A second native ClientRestart callback fired during that load; F6 reported count 2. The game then closed normally with Steam reporting exit code 0 for both game processes. See `tests/runtime-evidence.txt` for selected diagnostic lines.

The game updated its release autosave and system-save files while loading. All nine pre-test files were backed up and verified; the seven other files, including manual and demo saves, remained byte-identical. The two test-updated versions and their pre-test originals are both preserved privately. The observer and QA scripts perform no save operations. All six original Win64 files, including the preexisting ASI and loader, remain byte-identical.

## Installer checks

Six Windows PowerShell 5.1 fixture tests passed: install/verify/uninstall preservation; explicit collision backup/restore; executable, legacy layout and payload checksum rejection; edited-file uninstall refusal; rollback after an injected copy failure; and manifest/receipt path escape rejection. Fake game data is used; these checks do not establish engine compatibility.

The first built ZIP was extracted and its installer was exercised against the closed real game: Install, Verify, Uninstall, Install, Verify all passed. Verify checked all seven payload files. Only the normal probe is enabled in this installation; the temporary QA mod and its private crash dumps/logs were moved outside the game first.

That packaged installation then launched normally through Steam, reached the title/menu, and loaded the existing adventure into Pilchard Bay: Church. The shipped DQVIIProbe registered its native observer, logged startup and save-load callbacks, and reported `STATUS: HOOK_READY; count=2` on F6. Both game processes exited with code 0. See `tests/package-evidence.txt` for selected lines. The F7 QA mod was not enabled in this run.

## Artifact integrity

The ZIP has an external SHA-256 file and 28 internal SHA256SUMS entries covering its other 28 files. Verification passed for every ZIP member, exact seven-file payload ownership, forbidden game/private file extensions, and installed bytes. Rebuilding with the included SOURCE and the pinned official runtime archive produced a byte-identical ZIP.

## Limits

This profile uses unmodified upstream DLLs. It does not establish general compatibility for arbitrary Lua or native mods. No GUI, SDK generation, battle, long-session, or demo-executable test has been performed. ConsoleManagerSingleton has two scan candidates and remains unresolved; the developer console is not a validated feature. Full private logs and crash dumps stay local; release evidence contains selected diagnostic lines only.
