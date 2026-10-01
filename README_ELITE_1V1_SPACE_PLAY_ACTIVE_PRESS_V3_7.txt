FOOTBALL ELITE 1V1 SPACE PLAY + ACTIVE PRESS V3.7

APPLY AFTER V3.6.

PROBLEM 1: STRAIGHT-LINE DRIBBLING

"Get the ball behind the defender" is now treated as a collection plan rather
than merely a forward dribble target.

The CPU scans:
- five forward distances,
- nine lateral offsets,
- direct self-pass routes,
- top-wall bank self-passes,
- bottom-wall bank self-passes.

Every destination is rejected unless:
- it is meaningfully beyond the defender,
- the launch route is clear enough,
- the CPU can arrive before the opponent,
- the ball does not arrive too early for the CPU,
- the destination leaves a useful shooting lane afterward.

Each valid route is scored using:
- forward progress,
- bypass margin,
- direct/wall route clearance,
- destination space,
- CPU versus opponent arrival margin,
- ball versus CPU timing,
- shooting-lane quality after collection,
- goal distance after collection,
- wall-route advantage,
- penalties for repeatedly using a blocked straight line.

TOUCH POWER

The CPU calculates the impulse needed for each route using:
- route distance,
- ball linear damping,
- desired CPU arrival time,
- wall restitution for bank routes.

The touch is clamped between a controlled medium-force range:
- minimum: 980
- maximum: 2425
- no automatic full-power blast.

The desired ball arrival is approximately 0.08 seconds before the CPU, so the
CPU should collect while still being closer than the defender.

EXECUTION

1. Move behind the live ball.
2. Apply the calculated direct or wall-bank touch.
3. Chase the predicted collection point.
4. Recalculate the live interception while the ball moves.
5. Abort and enter duel recovery if the opponent clearly wins the race.
6. Resume attack immediately after recollecting.

The existing 19-action policy schema is unchanged. ACTION_CARRY can now invoke
this mechanical space-play executor.

PROBLEM 2: PASSIVE DEFENSE AGAINST A STATIONARY HUMAN

The previous stall escalation required the CPU to already be within about
540 pixels. A CPU standing near midfield could therefore remain passive
forever.

V3.7 adds a true-1v1 hard override:

After 0.62 seconds of confirmed stalling, the CPU:
- starts closing from any distance,
- cannot preserve a passive gap larger than 760 pixels,
- evaluates direct shot, upper/lower wall, and upper/lower dribble routes,
- moves to the position covering the best combination of those routes,
- stays goal-side,
- uses lateral positioning to bait a direction.

Pressure distance changes by map location:
- carrier near CPU attacking goal: approximately 335 pixels and more aggressive,
- midfield: approximately 470 pixels,
- carrier near CPU own goal: approximately 560 pixels and safer.

After prolonged stalling, the CPU forces a tackle:
- normally around 1.75 seconds,
- faster when the carrier is parked near its own goal,
- up to 920 pixels away once the tackle phase starts.

This override is only active in a true 1v1. It does not make every defender
double-commit in future 2v2/3v3/4v4 matches.

TRAINING FEATURES

New observations:
- space_play_available
- space_play_uses_wall
- space_play_quality
- space_play_recovery_margin
- space_play_shooting_lane
- space_play_force_ratio

Existing checkpoints remain compatible. Candidate scoring and the hard
mechanical rules work immediately; future self-play can learn the new features.

FILES

Scenes/cpu_player_ai.gd
ai/hybrid/tactical_adapter.gd
ai/hybrid/tactical_observation_builder.gd
ai/hybrid/tactical_policy.gd

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

TEST 1: SELF-PASS

1. Start a true 1v1.
2. Let the CPU control the ball in midfield.
3. Stand directly between the CPU and the goal.
4. The CPU should compare lateral direct touches and both wall banks instead
   of repeatedly carrying straight into you.
5. It should use a medium touch, chase the destination, and collect before you
   when the timing margin is positive.

TEST 2: STALL PRESSURE

1. Take possession and stop completely.
2. The CPU should begin closing after roughly 0.62 seconds.
3. It should approach goal-side and slightly offset rather than remaining at
   midfield.
4. It should eventually force a tackle rather than permit infinite stalling.
