# Hybrid AI project audit and exact training walkthrough

## 1. What the failed test actually proves

The pasted Windows run did not enter a football match. It failed while Godot
was loading scripts and resources. The trainer therefore executed zero useful
physics steps and zero self-play matches.

The first visible failure is already inside a cascade: `FootballPlayer` is
unavailable while `match_manager.gd` parses. After that, anything depending on
`FootballPlayer`, `FootballMatchManager`, `NetworkManager`, `CPUPlayerAI`,
`MenuStyler`, `UIMotion` and the other global classes also fails.

The same run also reports:

- missing source/imported audio and image resources;
- missing `Characters/player.tscn`;
- missing `Assets/controller_gamepad.svg`;
- unavailable `Steam` and `SteamMultiplayerPeer`;
- failure to load `Scenes/playfield.tscn`;
- and only then failure to parse `hybrid_ai_trainer.gd`.

That means the real-physics smoke test failed before the AI trainer itself
could be judged.

## 2. The uploaded ZIP is not a complete project root

The inspected archive does not contain `project.godot`. It also lacks several
root resources referenced by `Scenes/playfield.tscn`, including:

- `Download (3).png`
- `field.png`
- `goalsound.mp3`
- `menuclicksounds.mp3`
- `mixkit-hitting-soccer-ball-2112-godot.mp3`
- `pump-shotgun.mp3`
- `goal.jpg`
- `theodoreball.png`

The archive does contain `Characters/player.tscn` and
`Assets/controller_gamepad.svg`, while the Windows log says those were missing.
Therefore the folder used by the failed command and the uploaded archive are
different incomplete copies. Do not train from either incomplete copy.

## 3. What the AI rework actually is

The rework is a hybrid, not a from-scratch neural agent:

1. `Scenes/cpu_player_ai.gd` remains the mechanical executor.
2. The hybrid tactical policy selects one of 19 high-level football actions.
3. The old scripted controller performs movement, aim, kick timing, collision
   response, ability execution and emergency behavior.
4. Self-play mutates candidate parameters, plays matches, compares rewards and
   promotes candidates that pass gates.
5. Optional Python behavior cloning can initialize tactical action preferences
   from demonstrations.

The tactical layer is a linear action scorer over normalized observations. It
can learn that one existing action is better than another in a situation. It
cannot invent a new dribble mechanic, repair collision code, discover an action
that is absent from the action space, or learn raw controller inputs end to end.

## 4. Why it may currently feel worse

The uploaded active hybrid checkpoint is still a safe default:

- `training_steps = 0`
- `simulated_matches = 0`
- empty model checksum
- `training_configuration.source = safe_default`

Your legacy CPU profile is trained, but the new tactical layer is not. The
hybrid action branch runs before the ordinary legacy offense/defense branch
when it successfully handles a decision. Therefore an untrained tactical layer
can override parts of the older, more mature decision-making.

Training can improve action selection. It cannot fix missing resources, script
parse failures, incorrect physics, broken actions or bad telemetry.

## 5. Important training-system weaknesses found

### Full-game scene dependency

`hybrid_ai_trainer.gd` preloads the complete `Scenes/playfield.tscn`. Headless
training therefore depends on UI scripts, Steam/network integration, textures,
audio and every global class in the game. One missing cosmetic asset can stop
all AI training. The patch does not redesign this because that would be a
larger gameplay architecture change. A dedicated stripped training scene is
the next justified engineering step only after the complete project passes the
preflight.

### Curriculum durations are currently descriptive

The 21 curriculum stages contain `duration` values, but the trainer uses the
global `match_seconds` value. The stage duration is not currently applied as
the episode duration.

### Curriculum stages are initial-state scenarios

Stages reposition entities and configure controls, but they do not generally
terminate the episode immediately when their named success condition occurs.
For example, a “reach the ball” episode can continue into unrelated play. The
curriculum is useful, but it is not yet a strict task-by-task reinforcement
learning curriculum.

### Bad checkpoint metadata

The default active checkpoint says `curriculum_stage = full_match`, but no stage
with that ID exists. Explicit stage names from the supplied configs avoid this
ambiguity.

### Joint mutation is noisy

The default `hybrid_league_evolution` mutates legacy mechanical parameters and
tactical policy weights together. That makes it hard to know whether a result
came from better tactics or damaged mechanics. Begin with
`tactical_policy_only`; use low-rate joint fine-tuning only after the tactical
policy is stable.

### Old self-play can reward the wrong thing

Older offense-focused training could promote profiles with attractive shot or
chance telemetry despite losing matches. More training is not automatically
better when the reward and promotion gates do not match the desired behavior.
Frozen normal-speed benchmarks, goal difference, own-goal rate and preserved
counter-opponents are more important than raw generation count.

## 6. What this patch changes

It does not overwrite gameplay code.

It adds:

- `training/run_hybrid_ai_fixed.ps1`
- `tests/training_preflight.gd`
- staged JSON configs under `training/configs/`
- a PowerShell installer

The fixed launcher:

1. verifies that the selected folder is a complete project;
2. optionally backs up the stale `.godot` cache;
3. runs Godot's resource import before standalone scripts;
4. runs a clear preflight that checks global classes, GodotSteam and the full
   playfield;
5. only then starts tests or training.

## 7. Installation

Extract this patch outside the game project, then run:

```powershell
Set-ExecutionPolicy -Scope Process Bypass

.\install_patch.ps1 `
  -Project "C:\Users\salik\Documents\football-2d-"
```

The installer does not overwrite the original launcher or gameplay scripts.

## 8. Repair the project before training

Use the one complete original project folder that contains `project.godot` and
all source assets. Do not copy only `.godot/imported` files; Godot needs the
original source resources.

Set paths:

```powershell
$Godot = "C:\Users\salik\Downloads\Godot_v4.7.1-stable_win64.exe"
$Project = "C:\Users\salik\Documents\football-2d-"
```

On the first repaired run, rebuild the generated cache:

```powershell
.\training\run_hybrid_ai_fixed.ps1 `
  -Godot $Godot `
  -Project $Project `
  -Mode preflight `
  -RebuildCache
```

Expected final line:

```text
HYBRID AI TRAINING PREFLIGHT PASSED
```

If this fails, fix the first listed missing file/class. Do not start self-play.

## 9. Run the native core test

```powershell
.\training\run_hybrid_ai_fixed.ps1 `
  -Godot $Godot `
  -Project $Project `
  -Mode core-test
```

Expected final line:

```text
HYBRID CORE TESTS PASSED
```

## 10. Run the real-physics smoke test

```powershell
.\training\run_hybrid_ai_fixed.ps1 `
  -Godot $Godot `
  -Project $Project `
  -Mode train `
  -Config res://training/configs/hybrid_smoke_real_physics.json
```

This intentionally uses:

- 1x speed;
- 1v1;
- 20-second matches;
- tactical-policy-only mutation;
- no promotion benchmark;
- a separate smoke output directory.

Its purpose is to prove scene loading, rigid-body stepping, match reset,
telemetry and checkpoint writing. It is not intended to improve the AI.

Run status:

```powershell
.\training\run_hybrid_ai_fixed.ps1 `
  -Godot $Godot `
  -Project $Project `
  -Mode status `
  -Checkpoint user://hybrid_ai/smoke_real_physics/active.json
```

A successful smoke checkpoint should have:

- `training_steps > 0`
- `simulated_matches > 0`
- a non-empty checksum
- no parse errors
- no missing-resource errors
- no NaN/Infinity values
- matches that reset and finish

## 11. Establish a baseline before learning

Benchmark the current untrained/default tactical checkpoint before comparing
later models:

```powershell
.\training\run_hybrid_ai_fixed.ps1 `
  -Godot $Godot `
  -Project $Project `
  -Mode benchmark `
  -Config res://training/configs/hybrid_1v1_tactical.json `
  -Checkpoint res://training/hybrid_checkpoints/active.json `
  -Output user://hybrid_ai/baseline_1v1_benchmark.json
```

Record win score, goal difference, own-goal rate, action categories and results
by opponent. A later model is better only if it improves these without
collapsing against a preserved counter.

## 12. Correct training order

### Stage A: 1v1 tactical policy

```powershell
.\training\run_hybrid_ai_fixed.ps1 `
  -Godot $Godot `
  -Project $Project `
  -Mode train `
  -Config res://training/configs/hybrid_1v1_tactical.json
```

This freezes the trained legacy mechanics and learns high-level tactical action
selection.

### Stage B: 2v2 tactical policy

```powershell
.\training\run_hybrid_ai_fixed.ps1 `
  -Godot $Godot `
  -Project $Project `
  -Mode train `
  -Config res://training/configs/hybrid_2v2_tactical.json
```

This resumes the 1v1 checkpoint and adds pass/carry choices, support spacing and
double-commit avoidance.

### Stage C: 3v3 tactical policy

```powershell
.\training\run_hybrid_ai_fixed.ps1 `
  -Godot $Godot `
  -Project $Project `
  -Mode train `
  -Config res://training/configs/hybrid_3v3_tactical.json
```

### Stage D: 4v4 tactical policy

```powershell
.\training\run_hybrid_ai_fixed.ps1 `
  -Godot $Godot `
  -Project $Project `
  -Mode train `
  -Config res://training/configs/hybrid_4v4_tactical.json
```

The benchmark coverage expands with every stage, so later specialization cannot
silently erase earlier competence.

### Stage E: optional joint fine-tuning

Only after the tactical checkpoints visibly outperform the baseline:

```powershell
.\training\run_hybrid_ai_fixed.ps1 `
  -Godot $Godot `
  -Project $Project `
  -Mode train `
  -Config res://training/configs/hybrid_joint_finetune.json
```

This uses much lower mutation rates because it can modify the reliable legacy
mechanics.

## 13. Final benchmark and selection

Benchmark the final candidate:

```powershell
.\training\run_hybrid_ai_fixed.ps1 `
  -Godot $Godot `
  -Project $Project `
  -Mode benchmark `
  -Config res://training/configs/hybrid_4v4_tactical.json `
  -Checkpoint user://hybrid_ai/4v4_tactical/active.json `
  -Output user://hybrid_ai/4v4_tactical/final_benchmark.json
```

Verify integrity:

```powershell
.\training\run_hybrid_ai_fixed.ps1 `
  -Godot $Godot `
  -Project $Project `
  -Mode verify `
  -Checkpoint user://hybrid_ai/4v4_tactical/active.json
```

Do not select it for live play merely because training completed. Select only
after the benchmark passes and manual matches show no obvious regression:

```powershell
.\training\run_hybrid_ai_fixed.ps1 `
  -Godot $Godot `
  -Project $Project `
  -Mode select `
  -Checkpoint user://hybrid_ai/4v4_tactical/active.json
```

## 14. What to watch while training

Use `training_metrics.jsonl` and `training_metrics.csv`. Track:

- promotions versus generations;
- goals for and against;
- normal-speed benchmark results;
- own goals;
- fallback rate and fallback reasons;
- tactical action usage;
- passes and completed passes;
- shots and on-target shots;
- double-commit time;
- results by opponent/counter;
- whether one action dominates every situation.

Warning signs:

- many generations and zero promotions;
- promotions while goal difference gets worse;
- one action taking almost all decisions;
- fallback rate staying high;
- success only at accelerated speed;
- 3v3/4v4 improvement accompanied by 1v1 collapse;
- repeated losses to one preserved counter.

## 15. Can training make this AI “unbeatable”?

It can make the existing action-selection policy substantially better and less
predictable. It cannot guarantee unbeatable play.

The current learner searches a finite, hand-designed policy space through
evolutionary mutation. Its ceiling is limited by:

- the 19 available actions;
- observation quality;
- the scripted executor;
- reward/telemetry correctness;
- opponent diversity;
- the amount of evaluation noise;
- and whether the mechanical controller can execute the selected tactic.

For a genuinely higher ceiling later, the next architecture step is not
“remove all scripted AI.” It is:

1. keep the deterministic executor and safety fallbacks;
2. isolate a lightweight training environment;
3. verify observations/actions/rewards;
4. use behavior cloning to initialize;
5. train a policy with a proper RL algorithm;
6. retain league opponents and frozen regressions.

That should happen only after the present physics and evaluation pipeline is
reliably passing.
