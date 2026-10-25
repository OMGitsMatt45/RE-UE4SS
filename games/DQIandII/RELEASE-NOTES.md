## DQI & II UE4SS Compatibility Core 0.1.0 — prerelease

Lua scripting and native function hooks for **Steam Dragon Quest I & II HD-2D
Remake 1.0.2 (build 21744054)**, tested separately in both adventures.

- Pinned, unchanged upstream UE4SS **3.0.1-1181-g83330635**.
- ProcessEvent slot **69 / 0x228**, with **InitGameState and LoadMap hooks disabled**.
- F6 native-callback observer, guarded install/verify/uninstall, backup/restore
  receipts, checksums, exact compatibility sources, and validation evidence.
- Both games loaded existing manual saves, fired real native callbacks and passed
  game-thread property, integer and string-return checks. Exits were clean and
  original files and saves retained their pre-test hashes.

Extract the installable ZIP and follow `README.md`. The installer refuses other
executable hashes. **InitGameState Lua hook APIs and LoadMap hooks are unavailable.**
The default InitGameState hook causes an I & II startup crash and has not been
repaired; the profile disables it. GUI, SDK generation, arbitrary mods, battles,
other game versions and long sessions remain unvalidated.

Use the ZIP and adjacent `.sha256` file. GitHub's automatic source archives contain
source only. No game assets, executables, saves or private crash reports are included.
