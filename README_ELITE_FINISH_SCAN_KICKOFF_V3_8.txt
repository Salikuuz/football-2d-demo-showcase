FOOTBALL ELITE FINISH SCAN + KICKOFF STRATEGIES V3.8

APPLY AFTER V3.7.

CLIP DIAGNOSIS
- The v3.7 space-play commitment could keep controlling the CPU for up to 2.6 seconds after a shooting lane opened.
- The previous shot gate over-prioritized follow-up possession and defender bypass, so a valid full-power finish could be rejected.
- The self-pass medium-force ceiling was correct for self-passes but was not supposed to limit real shots.

NEW ATTACK PRIORITY
1. 80%+ predicted goal probability: cancel dribble/self-pass and fully charge the shot.
2. 56-80% probability: use a controlled 56-84% charge depending on the route.
3. No reliable finish: retain possession and use direct/wall self-pass planning from v3.7.

TRAJECTORY SCAN
- 11 targets across the real goal mouth.
- Full, strong controlled and medium controlled charge levels.
- Direct routes and up to 6 wall-bank routes.
- Estimates ball travel time, damping, wall loss, route clearance, defender interception time and reaction delay.
- High-speed shots through a nearby challenge are accepted when the ball is predicted to reach goal before the defender can establish a block.

LIVE INTERRUPTION
A recollected ball immediately runs the finish scan. A high-confidence lane interrupts the active self-pass/carry plan, fixing the clip where the CPU kept dribbling until it collided with the defender.

KICKOFF PORTFOLIO
- possession
- delayed
- delayed counter
- fake
- wall control
- aggressive

The choice reacts to opponent rush speed/distance and rotates strategies so every kickoff is not identical. This is tactical variety, not intentional mistakes.

FILES
Scenes/cpu_player_ai.gd
ai/hybrid/tactical_adapter.gd
ai/hybrid/tactical_observation_builder.gd
ai/hybrid/tactical_policy.gd

INSTALL
Copy into C:\Users\salik\Documents\football-2d- after v3.7 and overwrite.

PARSE TEST
& "C:\Users\salik\Downloads\Godot_v4.7.1-stable_win64.exe" `
  --headless `
  --path "C:\Users\salik\Documents\football-2d-" `
  --editor `
  --quit
