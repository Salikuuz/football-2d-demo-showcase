ADVANCED WORKER COORDINATOR V2.2

CHANGE

The worker coordinator now accepts:
    -Workers 2 through 8

The process-array naming fix from v2.1 remains included.

INSTALL ONLY AFTER THE CURRENT COORDINATOR HAS FINISHED

Extract into:
C:\Users\salik\Documents\football-2d-

Overwrite:
training\run_advanced_population_workers.ps1

Optional:
Unblock-File ".\training\run_advanced_population_workers.ps1"

SIX WORKERS FOR SIX HOURS

cd "C:\Users\salik\Documents\football-2d-"

$Godot = "C:\Users\salik\Downloads\Godot_v4.7.1-stable_win64.exe"
$Project = "C:\Users\salik\Documents\football-2d-"

.\training\run_advanced_population_workers.ps1 `
  -Godot $Godot `
  -Project $Project `
  -Workers 6 `
  -Hours 6 `
  -Speed 7

This launches six isolated workers simultaneously. Each worker trains for six
real hours. The coordinator then benchmarks the baseline and all six worker
champions sequentially, so total wall-clock time will be longer than six hours.
