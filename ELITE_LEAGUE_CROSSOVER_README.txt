HYBRID AI ELITE LEAGUE + CONTROLLED CROSSOVER V2.3

IMPORTANT
Apply this only after the currently running worker round has completely ended.
Replacing the files does not upgrade a PowerShell coordinator process that is
already running.

PURPOSE

The old coordinator:
1. started isolated workers,
2. benchmarked their final champions,
3. selected one winner,
4. discarded the strategic value of the other strong workers.

V2.3 changes the process to:

6 isolated worker lineages
-> frozen benchmark
-> elite cross-play tournament
-> controlled grouped crossover children
-> frozen benchmark for every child
-> child-vs-elite cross-play
-> one verified main champion
-> up to three verified archived specialists
-> next round seeds workers across every lineage

PERSISTENT ELITE ARCHIVE

Stored under:

%APPDATA%\Godot\app_userdata\Football 2d\hybrid_ai\1v1\elite_archive

Persistent files:
- elite_0.json
- elite_1.json
- elite_2.json
- manifest.json

Every round also gets an immutable snapshot under:

elite_archive\runs\<RUN_ID>\

The archive excludes the selected main champion, because the main checkpoint
already exists separately. It therefore preserves up to three additional
specialists.

NEXT-ROUND LINEAGE SEEDING

At the beginning of later rounds, workers are seeded in rotation from:

1. main champion,
2. elite specialist 0,
3. elite specialist 1,
4. elite specialist 2,
5. main champion again,
6. elite specialist 0 again.

With six workers and three archived specialists, this gives breadth without
making every worker restart from the exact same policy.

Every worker also receives copies of:
- the current main champion,
- all elite specialists,
- the normal main history.

Those files are placed in the worker's isolated history directory. The current
trainer's historical-opponent share is 25%, so workers can directly train
against the other elite lineages.

ELITE CROSS-PLAY

The coordinator runs direct head-to-head series between:
- the baseline main champion,
- the strongest verified workers,
- previously archived elites.

Cross-play alternates colors automatically.

Selection remains safety-first:
- frozen benchmark pass is mandatory,
- frozen quality must beat the baseline for main promotion,
- cross-play cannot bypass the frozen promotion gate.

Cross-play only helps rank candidates that already passed the safety benchmark.

CONTROLLED CROSSOVER

The coordinator can create up to three children:

1. offense child,
2. defense child,
3. control/possession child.

This is not raw averaging.

Each child:
- keeps one elite as its base,
- copies only a related group of tactical actions from another elite,
- keeps unrelated action groups unchanged,
- applies only 0.015 deterministic jitter to the transferred group,
- blends policy scalars only 25% toward the donor,
- transfers matching legacy parameters by keyword group.

Action groups:

OFFENSE
- direct shot
- near-post shot
- far-post shot
- wall-bank shot
- pass ahead

CONTROL
- carry
- delay touch
- safe pass
- pass ahead
- move open
- support teammate

DEFENSE
- challenge
- fake challenge
- shadow defend
- protect goal
- clear open side
- rotate back
- mark opponent
- avoid double commit

Every crossover child must:
1. validate as a checkpoint,
2. pass the complete frozen benchmark,
3. cross-play against the elite parents,
before it can become the main champion or enter the persistent archive.

NEW TRAINER MODE

hybrid_ai_trainer.gd now supports:

--crossplay-opponent-checkpoint
--crossplay-output
--crossplay-matches
--crossplay-candidate-label
--crossplay-opponent-label

This mode plays a fixed candidate directly against a fixed checkpoint and
writes:
- wins,
- draws,
- losses,
- win score,
- goal difference,
- average reward,
- per-match results.

COMMAND

Your existing command still works:

cd "C:\Users\salik\Documents\football-2d-"

$Godot = "C:\Users\salik\Downloads\Godot_v4.7.1-stable_win64.exe"
$Project = "C:\Users\salik\Documents\football-2d-"

Unblock-File ".\training\run_advanced_population_workers.ps1"

.\training\run_advanced_population_workers.ps1 -Godot $Godot -Project $Project -Workers 6 -Hours 2 -Speed 7

The defaults automatically enable:
- 3 elite specialists,
- 4 matches per cross-play series,
- 3 controlled crossover children.

Explicit equivalent:

.\training\run_advanced_population_workers.ps1 `
  -Godot $Godot `
  -Project $Project `
  -Workers 6 `
  -Hours 2 `
  -Speed 7 `
  -EliteCount 3 `
  -CrossplayMatches 4 `
  -CrossoverChildren 3

OPTIONS

Disable crossover temporarily:

-DisableCrossover

Disable direct cross-play temporarily:

-DisableCrossplay

Change archive size:

-EliteCount 2

Change series depth:

-CrossplayMatches 6

CrossplayMatches is automatically made even so each policy plays both colors.

COORDINATOR OUTPUT

At the end, ranking rows include:

frozen
- original frozen benchmark quality

cross
- average head-to-head cross-play score

select
- final ordering score used among frozen-verified candidates

The final output states:
- whether the main champion changed,
- how many specialists were archived,
- the archive path,
- which lineages will seed the next round.

FILES

training\hybrid_ai_trainer.gd
training\hybrid_elite_crossover.gd
training\hybrid_population_select.gd
training\run_advanced_population_workers.ps1
training\hybrid_1v1_advanced_es.json

INSTALL

1. Wait until the current six-worker run and final coordinator benchmark end.
2. Close any remaining training Godot processes.
3. Copy the training folder from this patch into:

C:\Users\salik\Documents\football-2d-

4. Allow overwriting.

LOCAL PARSE CHECK

& "C:\Users\salik\Downloads\Godot_v4.7.1-stable_win64.exe" `
  --headless `
  --path "C:\Users\salik\Documents\football-2d-" `
  --editor `
  --quit

SAFETY

- Workers remain isolated.
- Only the coordinator writes the main checkpoint.
- Crossover children are never written directly to active.json.
- The frozen benchmark remains mandatory.
- Cross-play cannot promote a frozen-benchmark failure.
- Existing active.json is not deleted.
- Existing history is preserved.
- Existing elite archive is snapshot-tested again on later rounds.
- The 19-action tactical schema is unchanged.
