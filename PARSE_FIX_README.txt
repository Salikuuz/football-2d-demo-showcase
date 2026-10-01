HYBRID AI POPULATION TRAINER V1.1 PARSE FIX

FIXED

The original population package accidentally changed this loop:

_run_human_demo_benchmark_set()
    range(_matches_per_challenge)

to:
    range(match_count)

match_count is local to _evaluate_challenger(), so Godot stopped parsing at
approximately line 868.

V1.1 restores the human benchmark loop and applies the dynamic match_count loop
to the correct challenger evaluation function.

INSTALL

Extract into:
C:\Users\salik\Documents\football-2d-

Overwrite:
training\hybrid_ai_trainer.gd

The population config remains:
training\hybrid_1v1_population_fast.json

PREFLIGHT

cd "C:\Users\salik\Documents\football-2d-"

$Godot = "C:\Users\salik\Downloads\Godot_v4.7.1-stable_win64.exe"
$Project = "C:\Users\salik\Documents\football-2d-"

.\training\run_hybrid_ai.ps1 `
  -Godot $Godot `
  -Project $Project `
  -Mode preflight `
  -SkipImport

HEADLESS 7X

.\training\run_hybrid_ai.ps1 `
  -Godot $Godot `
  -Project $Project `
  -Mode train `
  -Config "res://training/hybrid_1v1_population_fast.json" `
  -Hours 2 `
  -Speed 7 `
  -SkipImport
