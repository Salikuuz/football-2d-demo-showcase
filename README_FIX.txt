GODOT TRAINING / IMPORT FIX

This patch changes only:
- training/run_hybrid_ai.ps1
- addons/godotsteam/godotsteam.gdextension
- project.godot path references
- tests/training_preflight.gd

It does not change gameplay, physics, AI decisions, rewards, assets, networking logic, or controller behavior.

WHY THE COMMANDS FAILED
1. The earlier PowerShell launcher returned before the Godot GUI-subsystem process ended, so $LASTEXITCODE was empty and several Godot processes overlapped.
2. GodotSteam hot-reload attempted to create/load ~libgodotsteam...dll. The project contains many stale ~lib... and .TMP copies, and Windows could not open the active shadow copy.
3. Once GodotSteam failed, Steam and SteamMultiplayerPeer were unavailable. That caused dependent scripts and global classes to fail, ending in the misleading hybrid_ai_trainer.gd parse error.

INSTALL
1. Close the Godot editor, the game, and every Godot process.
2. Extract this ZIP into the complete project root.
3. Allow overwrite of the four matching files.
4. Do not copy or delete assets.

FIRST COMMANDS

cd "C:\Users\salik\Documents\football-2d-"
Get-ChildItem .\training\*.ps1 | Unblock-File

$Godot = "C:\Users\salik\Downloads\Godot_v4.7.1-stable_win64.exe"
$Project = "C:\Users\salik\Documents\football-2d-"

.\training\run_hybrid_ai.ps1 `
  -Godot $Godot `
  -Project $Project `
  -Mode preflight `
  -RebuildCache

The script now:
- refuses to start while another Godot process is running;
- deletes only stale GodotSteam ~lib / TMP shadow copies;
- waits for every Godot process and uses its real exit code;
- imports resources before tests/training;
- runs preflight before train/benchmark;
- keeps the original Steam DLL files untouched.

After preflight passes:

.\training\run_hybrid_ai.ps1 `
  -Godot $Godot `
  -Project $Project `
  -Mode core-test

.\training\run_hybrid_ai.ps1 `
  -Godot $Godot `
  -Project $Project `
  -Mode controller-test

Then run the real-physics smoke configuration you already have.
