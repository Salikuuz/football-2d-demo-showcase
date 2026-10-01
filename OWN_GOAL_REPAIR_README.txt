HYBRID AI OWN-GOAL REPAIR V2.4

DIAGNOSIS

The final coordinator did not show that workers 2, 5 and 3 were generally
weaker. They all ranked above the baseline in quality, win score or goal
difference, but were rejected by the 5% own-goal gate.

The own-goal rate became high for four reasons:

1. Attribution is strict:
   any final touch by the conceding team is counted as an own goal. That
   includes goalkeeper blocks and Reflex Block deflections.

2. The dangerous failures are concentrated in defensive situations,
   especially wall-shot pressure. The final action distributions contain many
   challenge_ball, protect_goal, shadow_defend and clear_open_side decisions.
   This points to last-second defensive contacts and bad clearances rather
   than only offensive wall shots.

3. There was no central mechanical safety gate:
   CPU charged shots, dribble touches, Trap or Volley, redirects, goalkeeper
   blocks and Reflex Block could all create a velocity crossing their own goal
   mouth.

4. The frozen suite is small:
   one own goal in 14 evaluated matches is already 7.1%; one in 8 is 12.5%;
   two in 8 is 25%.

HARD MECHANICAL PREVENTION

The patch predicts whether a proposed CPU-generated ball velocity crosses its
own goal plane inside the padded goal mouth. The prediction follows up to
three top/bottom-wall rebounds, so a wall-bank clearance toward the CPU's own
goal is also intercepted.

Protected paths:
- CPU dribble/self-pass touches
- charged CPU shots
- Trap or Volley first-time volleys
- ball redirects used by CPU abilities
- Goalkeeper's Reach blocks
- Reflex Block deflections

When dangerous:
- the touch is redirected forward and toward a safe side lane,
- existing incoming velocity is cancelled correctly using ball mass,
- Curve Shot steering is disabled when its initial impulse was safety-corrected,
- the event is recorded for training diagnostics.

This does not protect human players from their own inputs.

DIAGNOSTICS

Each goal now records:
- final touch kind
- incoming velocity
- outgoing velocity
- whether the safety layer redirected it
- avoidable own goal versus forced goalkeeper/reflex deflection

New benchmark metrics:
- avoidable_own_goals
- forced_deflection_own_goals
- dangerous_own_goal_touch_attempts
- dangerous_own_goal_touch_rejections
- own_goal_prevention_redirects

REWARD CHANGES

Default own-goal penalty:
-7.0 -> -16.0

Dangerous own-goal touch penalty:
-1.2 -> -6.0

The dedicated repair configuration uses:
- actual own goal: -18.0
- dangerous own-goal touch: -8.5

Forced deflections receive a smaller extra tactical penalty than avoidable
kicks, but they still count against the strict benchmark own-goal gate.

OFFENSE PRESERVATION

The repair run does not restart from the weak baseline.

It copies and resumes:
- worker 2
- worker 5
- worker 3

Six repair workers are seeded as:
2, 5, 3, 2, 5, 3

Mutation and exploration are deliberately lower than a fresh search. Offensive
rewards for goals, chances and expected-goal gain remain strong. The purpose is
to preserve the discovered offense while removing unsafe defensive touches.

The tactical policy also:
- applies safety floors/ceilings after loading old checkpoints, so the resumed
  worker policies cannot overwrite the new own-goal-danger guards,
- strongly prefers clear_open_side in own-goal danger,
- penalizes challenge, carry, delay, wall shots and unsafe passes near its own
  goal,
- scans 20 safe forward/lateral clearance targets instead of only two.

INSTALL

Wait until no training/coordinator processes are running.

Copy the patch contents into:
C:\Users\salik\Documents\football-2d-

Allow overwriting.

PARSE TEST

& "C:\Users\salik\Downloads\Godot_v4.7.1-stable_win64.exe" `
  --headless `
  --path "C:\Users\salik\Documents\football-2d-" `
  --editor `
  --quit

START THE TARGETED REPAIR RUN

cd "C:\Users\salik\Documents\football-2d-"

$Godot = "C:\Users\salik\Downloads\Godot_v4.7.1-stable_win64.exe"
$Project = "C:\Users\salik\Documents\football-2d-"

Unblock-File ".\training\run_own_goal_repair_workers.ps1"

.\training\run_own_goal_repair_workers.ps1 `
  -Godot $Godot `
  -Project $Project `
  -Workers 6 `
  -Hours 2 `
  -Speed 7

The script automatically finds the newest completed parallel run containing
worker_2, worker_5 and worker_3.

To select a specific source run:

.\training\run_own_goal_repair_workers.ps1 `
  -Godot $Godot `
  -Project $Project `
  -SourceRunId "YYYYMMDD_HHMMSS" `
  -Workers 6 `
  -Hours 2 `
  -Speed 7

PROMOTION

The main champion changes only when a repaired candidate:
- passes the frozen benchmark,
- stays at or below the 5% own-goal rate,
- beats the baseline coordinator quality.

All repair seeds, workers, benchmarks and logs remain saved even when no
candidate passes.
