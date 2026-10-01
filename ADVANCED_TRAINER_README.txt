HYBRID AI ADVANCED MIRRORED ES TRAINER V2

WHAT CHANGED

Single-process learning efficiency:
- 12 candidates as 6 mirrored +/- mutation pairs
- 1-match triage for all candidates
- best 6 receive 2-match screening
- best 3 receive the full 6-match challenge
- mathematical early rejection when the positive-match gate is impossible
- weakness-first staged frozen benchmark
- normal-speed verification runs only after frozen gates pass
- rank-based evolution-strategy update uses all candidate rankings
- protected champion changes only after every original promotion gate passes
- ES search center and sigma persist in active.json

Parallel wall-clock mode:
- 2 or 3 isolated Godot branches
- separate output directories and logs
- every branch begins from the same main champion
- coordinator benchmarks baseline plus all branches
- workers never write the main checkpoint
- coordinator replaces the main checkpoint only with a verified improvement

INSTALL

Wait until every running Godot trainer is stopped. Extract into:
C:\Users\salik\Documents\football-2d-

Overwrite:
training\hybrid_ai_trainer.gd

Adds:
training\hybrid_1v1_advanced_es.json
training\hybrid_population_select.gd
training\run_advanced_population_workers.ps1

PREFLIGHT

cd "C:\Users\salik\Documents\football-2d-"
$Godot = "C:\Users\salik\Downloads\Godot_v4.7.1-stable_win64.exe"
$Project = "C:\Users\salik\Documents\football-2d-"

.\training\run_hybrid_ai.ps1 `
  -Godot $Godot `
  -Project $Project `
  -Mode preflight `
  -SkipImport

SINGLE PROCESS, HEADLESS, 7X

.\training\run_hybrid_ai.ps1 `
  -Godot $Godot `
  -Project $Project `
  -Mode train `
  -Config "res://training/hybrid_1v1_advanced_es.json" `
  -Hours 2 `
  -Speed 7 `
  -SkipImport

THREE ISOLATED WORKERS, TWO HOURS EACH

.\training\run_advanced_population_workers.ps1 `
  -Godot $Godot `
  -Project $Project `
  -Workers 3 `
  -Hours 2 `
  -Speed 7

Use 2 workers first if three workers reduce the combined completed-match rate.
The coordinator may keep the existing champion when none of the branches passes
all frozen and normal-speed gates.

EXPECTED SINGLE-PROCESS START

ADVANCED SEARCH: 12 mirrored candidates -> 6 survivors -> 3 finalists
ADVANCED POPULATION G... | 12 candidates in 6 mirrored pairs
TRIAGE RANKING
SCREENING RANKING
FINAL RANKING
ES UPDATE
BENCHMARK STAGE A: weakness-first

IMPORTANT

A new advanced generation is more valuable than an old generation because it
examines 12 related mutations and updates the search center from all rankings.
Compare promotions and benchmark quality, not raw generation count.
