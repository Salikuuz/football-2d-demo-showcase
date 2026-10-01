FOOTBALL ELITE 1V1 AGGRESSIVE OFFENSE V3.9

APPLY AFTER V3.8.2.

WHY THE OFFENSE WAS WEAK
- The finish scanner compared defender arrival at an interception point with
  the ball's full travel time to the goal. This rejected shots that would
  reach the interception point first.
- Only 0.80+ finish confidence forcibly interrupted the hybrid policy.
- Carry received multiple stacked bonuses and often outscored shooting.
- Possession plans stayed committed too long and were too straight.

FIXES
- Ball and defender are now timed at the exact same interception point.
- Direct and wall routes use separate travel timing before and after a bounce.
- 0.80+ confidence still uses a fully charged shot.
- Controlled finishes start at 0.50 and immediately interrupt carrying.
- Open lanes, close range, defender-behind-ball states and late full-power
  challenges are scored more aggressively.
- Carry loses 6 score when a valid finish exists.
- Carry commitment: 0.62 -> 0.30 seconds.
- Space-play commitment: 2.60 -> 1.35 seconds.
- Space-play minimum score: 760 -> 520.
- Forced close-pressure space plays accept another 28% lower threshold.
- Larger lateral search, stronger wall preference and stronger straight-line
  penalty.

EXPECTED
- Shoot immediately through a lane the defender cannot reach in time.
- Use full power for the highest-confidence finishes.
- Use controlled power for real but less certain finishes.
- Use lateral or wall self-passes only when no finish exists.
- Stop carrying into the defender after a scoring line opens.

FILES
Scenes\cpu_player_ai.gd
ai\hybrid\tactical_adapter.gd
ai\hybrid\tactical_policy.gd

INSTALL
Copy this folder into:
C:\Users\salik\Documents\football-2d-

PARSE TEST
& "C:\Users\salik\Downloads\Godot_v4.7.1-stable_win64.exe" `
  --headless `
  --path "C:\Users\salik\Documents\football-2d-" `
  --editor `
  --quit
