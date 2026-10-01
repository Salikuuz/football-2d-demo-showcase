THEODORE BALL - MULTIPLAYER PLAYER/BALL JITTER FIX
Godot version validated: 4.7.1 stable (official.a13da4feb)

CHANGED PROJECT FILES ONLY
- Characters/player.gd
- Characters/ball.gd

HOW TO APPLY
1. Back up your local project or create a git branch.
2. Copy the Characters folder from this package into your Theodore Ball project root.
3. Allow it to overwrite only:
   - Characters/player.gd
   - Characters/ball.gd
4. Open the project in Godot 4.7.1 stable.
5. Test a Steam multiplayer match with one host and at least one non-host client.

WHAT THIS FIX TARGETS
The existing project already publishes authoritative player and ball motion at a nominal 60 Hz using MultiplayerSynchronizer. The client presentation had a short fixed prediction ceiling:
- players: 40 ms
- ball: 35 ms

If Internet/Steam delivery arrived in ~50-70 ms bursts or had modest packet jitter, the client exhausted that prediction window, stopped the visual replica for one or more render frames, then corrected when the next snapshot arrived. On 120/144/240 Hz displays this can look like ~20 FPS stepping even while input latency is acceptable.

THE PATCH
- Keeps the host/server fully authoritative.
- Keeps the existing player input transport unchanged.
- Keeps the existing 60 Hz MultiplayerSynchronizer scene configuration unchanged.
- Uses MultiplayerSynchronizer.synchronized to mark actual complete snapshot arrivals.
- Measures the observed receive cadence on each client.
- Adapts the prediction window to modest packet batching/jitter instead of using only a fixed 35-40 ms ceiling.
- Eases stale prediction toward a stop instead of abruptly stopping on the prediction ceiling.
- Slightly softens correction response to hide packet cadence without turning gameplay into client-authoritative simulation.
- Keeps teleport/reset snap behavior intact.
- Resets smoothing history on hard resets/repairs.

NOT CHANGED
- Match rules
- Ball/player authoritative physics
- Input RPC behavior
- AI
- Abilities
- Controls
- Networking topology / host authority
- Scene files
- MultiplayerSynchronizer replication rate

VALIDATION PERFORMED
The patched full project was loaded headlessly with the supplied Godot 4.7.1 stable Linux editor. Godot completed project/scene/script loading with no SCRIPT ERROR, Parse Error, or ERROR entries.

REAL MULTIPLAYER TEST STILL REQUIRED
This environment cannot reproduce your exact Steam route, ping, packet loss, monitor refresh rate, or the second player's machine. The patch is aimed directly at the client-side motion cadence visible in the source, but you should compare it in the same host/non-host setup where the problem was observed.

TEST CHECKLIST
- Non-host's own player moving continuously and changing direction.
- Host player as seen by non-host.
- Ball rolling slowly.
- Ball moving fast after a kick.
- Ball wall/post collisions.
- Kickoff/goal reset teleports (should still snap immediately, not glide).
- Watch the existing lobby ping/jitter display during the test.

If motion is still visibly stepping after this patch, the next useful evidence is the non-host ping/jitter reading plus display refresh rate while the stutter happens. That would tell us whether to tune the adaptive window further or replace MultiplayerSynchronizer motion transport with explicit sequenced snapshot RPCs.
