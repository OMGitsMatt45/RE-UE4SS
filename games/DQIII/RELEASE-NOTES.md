## DQIII UE4SS Compatibility Core 0.1.0 — prerelease

Lua scripts and native function hooks for **Steam Dragon Quest III HD-2D Remake
1.2.1 (build 19495987)**, with a tested III ProcessEvent slot override.

- Pinned, unchanged upstream UE4SS **3.0.1-1181-g83330635**.
- Corrects `UObject::ProcessEvent` to slot **69 / 0x228** and disables LoadMap hooks.
- Includes an F6 native-callback observer, guarded install/verify/uninstall tool,
  backup/restore receipts, checksums, sources, and validation notes.
- Verified normal Steam startup, loading an existing adventure, actual native
  callbacks, reflected property reads, integer/string calls on the game thread,
  and clean exit. Original ASI plugins and save files retained their hashes.

Extract the ZIP and follow `README.md`. The installer rejects other executable
hashes. **LoadMap Lua hooks are disabled.** GUI, SDK dumping, other game builds,
and long play sessions are unvalidated. This is an initial compatibility
prerelease; it does not establish compatibility for every UE4SS mod.

The ZIP and adjacent `.sha256` file are the installable release. GitHub's automatic
source archives contain source code only. No game assets or saves are included.
