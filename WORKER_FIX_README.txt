ADVANCED WORKER COORDINATOR V2.1 FIX

PROBLEM FIXED

PowerShell variable names are case-insensitive.

The script parameter:
    [int]$Workers

and the worker process array:
    $workers = @()

were treated as the same typed variable. Assigning an object array to an Int32
caused:

System.Object[] cannot be converted to System.Int32

V2.1 renames the process collection to:
    $workerJobs

No administrator rights are required.

INSTALL

Extract into:
C:\Users\salik\Documents\football-2d-

Overwrite:
training\run_advanced_population_workers.ps1

OPTIONAL: REMOVE THE INTERNET SECURITY PROMPT

Unblock-File ".\training\run_advanced_population_workers.ps1"

RUN

cd "C:\Users\salik\Documents\football-2d-"

$Godot = "C:\Users\salik\Downloads\Godot_v4.7.1-stable_win64.exe"
$Project = "C:\Users\salik\Documents\football-2d-"

.\training\run_advanced_population_workers.ps1 `
  -Godot $Godot `
  -Project $Project `
  -Workers 3 `
  -Hours 2 `
  -Speed 7
