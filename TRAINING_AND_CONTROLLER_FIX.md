# Required setup and commands

These changes only repair project loading/training startup, isolate parallel
worker output, and fix controller mapping/hot-plug handling.

## First run

Use the complete project folder that also contains your original art/audio.

```powershell
Set-ExecutionPolicy -Scope Process Bypass

$Godot = "C:\Users\salik\Downloads\Godot_v4.7.1-stable_win64.exe"
$Project = "C:\Users\salik\Documents\football-2d-"

.\training\run_hybrid_ai.ps1 `
  -Godot $Godot `
  -Project $Project `
  -Mode preflight `
  -RebuildCache
```

Do not train until the final line is:

```text
HYBRID AI TRAINING PREFLIGHT PASSED
```

## Tests

```powershell
.\training\run_hybrid_ai.ps1 `
  -Godot $Godot `
  -Project $Project `
  -Mode core-test
```

```powershell
.\training\run_hybrid_ai.ps1 `
  -Godot $Godot `
  -Project $Project `
  -Mode controller-test
```

The controller test checks device-independent bindings, mapping-database
availability, hot-plug registration, controller switching, and disconnect
fallback.

## Short real-physics test

This runs real 1x physics and does not save a candidate:

```powershell
.\training\run_hybrid_ai.ps1 `
  -Godot $Godot `
  -Project $Project `
  -Mode train `
  -Config res://training/hybrid_smoke_config.json `
  -DryRun
```

The earlier failed command never reached this stage because the project had not
been imported and `project.godot` was absent from the supplied project copy.

## Actual training order

Run each stage only after the previous one completes successfully.

```powershell
.\training\run_hybrid_ai.ps1 -Godot $Godot -Project $Project -Mode train -Config res://training/hybrid_1v1_tactical.json
```

```powershell
.\training\run_hybrid_ai.ps1 -Godot $Godot -Project $Project -Mode train -Config res://training/hybrid_2v2_tactical.json
```

```powershell
.\training\run_hybrid_ai.ps1 -Godot $Godot -Project $Project -Mode train -Config res://training/hybrid_3v3_tactical.json
```

```powershell
.\training\run_hybrid_ai.ps1 -Godot $Godot -Project $Project -Mode train -Config res://training/hybrid_4v4_tactical.json
```

These stages mutate only the new tactical policy. They do not mutate the older
mechanical CPU parameters.

## Check a checkpoint

```powershell
.\training\run_hybrid_ai.ps1 `
  -Godot $Godot `
  -Project $Project `
  -Mode status `
  -Checkpoint user://hybrid_ai/4v4/active.json
```

```powershell
.\training\run_hybrid_ai.ps1 `
  -Godot $Godot `
  -Project $Project `
  -Mode verify `
  -Checkpoint user://hybrid_ai/4v4/active.json
```

## Controller database in exported builds

The game now loads:

```text
res://ControllerMappings/gamecontrollerdb.txt
```

In your existing Windows export preset, include this non-resource file:

```text
ControllerMappings/*.txt
```

Do not replace your export preset with a new one; add this filter to the preset
you already use.
