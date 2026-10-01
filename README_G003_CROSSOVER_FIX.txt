G003 CROSSOVER RESUME / POWERSHELL FIX
======================================

What happened
-------------
The crossover succeeded in Godot:

  ELITE CROSSOVER CREATED | group=control | ...
  CHECKSUM: d44a2949...

Windows PowerShell returned control before the Godot headless executable had
fully exited, so `$LASTEXITCODE` was checked too early and the launcher threw a
false failure.

Fix
---
- `$LASTEXITCODE` is no longer used as the crossover success signal.
- The generated checkpoint JSON is now the authoritative success condition.
- The launcher waits up to 120 seconds for a valid JSON checkpoint.
- Existing valid crossover seeds are reused.
- This makes the G003 preparation safe to rerun after a partial setup.

For the current machine/run, the already-created `control.json` will be reused.
The script will continue with the offense and defense fusion seeds and then
start G003 normally.

Run
---
From the project root:

  .\training\prepare_and_start_G003.ps1

No G002 training is repeated and the current main champion is not replaced.
