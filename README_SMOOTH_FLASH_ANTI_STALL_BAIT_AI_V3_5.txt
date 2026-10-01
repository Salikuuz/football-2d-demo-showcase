FOOTBALL SMOOTH WHITE FLASH + ANTI-STALL BAIT AI V3.5

APPLY AFTER V3.4.

WHITE BALL FLASH
- Uses the real Ball Sprite2D.modulate property, the same visual mechanism
  already used by Power Strike.
- No ShaderMaterial and no duplicate ball sprite.
- Fast smooth timing:
    8 ms transition from the current ball state to bright white
    6 ms white hold
    32 ms transition back to the correct base state
- The release uses a fast ease-out so it leaves full white quickly and settles
  smoothly instead of snapping.
- Restores normal Theodore after an ordinary kick/pass.
- Restores Power Strike red after a Power Strike kick/pass.
- The scale pop remains scale-only and cannot recolor the ball.
- No ball texture, outline, pivot, filtering, collision, physics, position,
  rotation or camera changes.

ANTI-STALL / BAIT DEFENSE
- Detects one opponent continuously controlling a nearly stationary ball.
- Uses carrier input, carrier speed, ball speed, displacement and charge state.
- Stall response begins after roughly 0.42 seconds and reaches full strength
  around 1.15 seconds.
- Adds policy observations for:
    opponent stall state
    stall duration and strength
    idle carrier input
    sudden commitment to a shot/dribble
    proximity to the CPU's own goal
    proximity to the opponent goal / counterattack risk
- Uses the existing fake_challenge action; no action-space/schema change.
- A stall fake challenge now has two real phases:
    1. approach on a slight lateral feint while remaining goal-side
    2. retreat into a shadow position and read the carrier
- Alternates the feint side between attempts so the pressure is less repetitive.
- If the carrier suddenly shoots, charges or accelerates, the CPU immediately
  reads the commitment.
- It pokes/clears only when the challenge is judged safe; otherwise it retreats
  and keeps the goal-side recovery lane.
- Near the CPU goal it stays farther goal-side, probes for less time and
  recovers longer before committing.
- Near the opponent goal it also preserves a counterattack escape instead of
  diving blindly without cover or an immediate tackle.
- After a prolonged stall, a safe close tackle gains priority so the human
  cannot wait forever without being pressured.
- New telemetry:
    stall_fake_challenges
    stall_forced_actions
    stall_escalation_challenges
- Existing checkpoints remain compatible. New default feature weights are
  merged into old policy documents by the existing normalization path, so the
  current active checkpoint is not deleted or overwritten.
- Future tactical-policy self-play can mutate the new weights because they are
  part of the normalized policy document.

LIMIT
This is a stateful anti-stall and two-phase deception layer, not a complete
long-horizon opponent world model. It gives the current 19-action policy the
observations and mechanics needed to learn when fake challenges work through
self-play while remaining compatible with the current project.

INSTALL
Close the running game/editor.
Copy everything inside this folder into:
C:\Users\salik\Documents\football-2d-

Overwrite:
- Characters\ball.gd
- ai\hybrid\tactical_adapter.gd
- ai\hybrid\tactical_observation_builder.gd
- ai\hybrid\tactical_policy.gd
- tests\hybrid_core_test.gd

This patch does not overwrite:
- user://hybrid_ai/1v1/active.json
- tactical_schema.gd
- AI action-space versions
- legacy mechanics
- training saves
- camera, field, UI or player visuals

LOCAL PARSE TEST
& "C:\Users\salik\Downloads\Godot_v4.7.1-stable_win64.exe" `
  --headless `
  --path "C:\Users\salik\Documents\football-2d-" `
  --editor `
  --quit

HYBRID CORE TEST
& "C:\Users\salik\Downloads\Godot_v4.7.1-stable_win64.exe" `
  --headless `
  --path "C:\Users\salik\Documents\football-2d-" `
  --script "res://tests/hybrid_core_test.gd"
