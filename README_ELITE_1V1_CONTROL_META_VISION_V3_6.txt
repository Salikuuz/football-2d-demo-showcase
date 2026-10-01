FOOTBALL ELITE 1V1 CONTROL + INNATE META VISION V3.6

APPLY AFTER V3.5.

DIAGNOSIS

1. cpu_player_ai.gd contained an explicit "Human-like Behaviour" system:
   - deliberate mistake rolls
   - hesitation
   - missed reads
   - perception error
   - shot aim error
   - decision timing jitter

2. The hybrid runtime policy also used:
   - exploration
   - action diversity penalties

Those systems can make a CPU look believable, but they deliberately prevent
the highest-scoring action from always being selected.

3. The hybrid possession candidate builder offered direct shots from long
range without requiring the defender to be beaten or a recoverable next
action.

4. Meta Vision occupied a CPU ability slot even though its main benefits are
already appropriate as permanent CPU perception.

COMPETITIVE EXECUTION

- perfect_execution_mode defaults to true.
- No deliberate runtime mistakes.
- No hesitation.
- No perception or shot-aim error.
- No decision jitter.
- Runtime hybrid policy is deterministic.
- Exploration and diversity remain enabled only during training.

INNATE META VISION

- CPU tactical Meta Vision is always active internally.
- CPUs receive:
  - fastest stable decision interval
  - exact ball reads
  - Meta Vision shot targeting
  - no missed pass/ability reads
- This does not activate the visible human Meta Vision ability effect.
- Meta Vision is removed from:
  - CPU Random pools
  - CPU combo selection
  - CPU halftime selection
  - CPU manual dropdowns
- Human players can still select Meta Vision normally.

CONTROL-FIRST 1V1 ATTACK

- The CPU calculates explicit targets beyond the defender.
- Candidate targets are scored by:
  - forward progress
  - distance beyond the defender
  - line clearance around the defender
  - CPU/opponent arrival-time margin
  - ability to retain the next touch
  - wall safety

- When a finish/follow-up is not available, the CPU is forced into a
  controlled bypass dribble instead of a speculative shot.

- A 1v1 shot is allowed only when:
  - the CPU has created a close clear finish, or
  - the defender has already been beaten and the CPU retains the next-action
    advantage.

- The shot condition is checked twice:
  - while candidates are built
  - immediately before execution
  This prevents a stale tactical decision from launching a bad shot after the
  defender has recovered.

- Creative wall/bank shots receive the same 1v1 follow-up gate.

CHECKPOINT COMPATIBILITY

- The 19-action schema is unchanged.
- Existing active.json checkpoints still load.
- New observation features and default weights merge into future policy
  documents.
- Hard candidate gates apply even when an older checkpoint contains aggressive
  shot weights.

FILES

Scenes/cpu_player_ai.gd
Scenes/match_manager.gd
Scenes/Teamselection.gd
ai/hybrid/tactical_adapter.gd
ai/hybrid/tactical_observation_builder.gd
ai/hybrid/tactical_policy.gd
tests/hybrid_core_test.gd

INSTALL

Close Godot.
Copy everything inside this folder into:
C:\Users\salik\Documents\football-2d-

Allow overwriting.

PARSE TEST

& "C:\Users\salik\Downloads\Godot_v4.7.1-stable_win64.exe" `
  --headless `
  --path "C:\Users\salik\Documents\football-2d-" `
  --editor `
  --quit

CORE TEST

& "C:\Users\salik\Downloads\Godot_v4.7.1-stable_win64.exe" `
  --headless `
  --path "C:\Users\salik\Documents\football-2d-" `
  --script "res://tests/hybrid_core_test.gd"

TEST IN GAME

1. Start a true 1v1 against one CPU.
2. Give the CPU possession around midfield.
3. Stand between the CPU and your goal.
4. The CPU should carry toward a target beyond your x-position instead of
   immediately firing into you.
5. After the CPU gets the ball beyond you or creates a close clear lane, it
   should finish.
6. Set the CPU ability to Random repeatedly. Meta Vision must never be assigned.
