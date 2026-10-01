FOOTBALL 2D - BALL ALIGNMENT / CLEAN IMPACT / FIELD / PHANTOM HEEL FIX V2.2

APPLY AFTER:
- Football Visual Impact Upgrade v1
- Football Visual Field + Phantom Heel v2
- Impact Restore No Directional Rotation v2.1

WHAT WAS ACTUALLY WRONG WITH THE BALL

The Ball Sprite2D used an off-center setup:
- position = (51.50106, 39.8881)
- centered = false
- offset = (-458.835, -399.465)

That made the normal-size image look centered, but its transform pivot was far away
from the visible ball. Scaling the sprite or cancelling the parent rotation therefore
moved the visible artwork away from the RigidBody2D collision center. The separate
shadow stayed on the physics body, exposing the problem.

V2.2 fixes the pivot itself:
- the sprite is centered on its visible alpha bounds
- the sprite is anchored directly to the physics-body position every frame
- its artwork remains upright
- scaling is uniform around the actual ball center
- ball physics, collision and velocity are unchanged

SHOT IMPACT

- Removes directional squash and all direction-based ball movement.
- Replaces it with a centered uniform size pop.
- Maximum-power shot reaches 150% ball size.
- Pop eases in over 0.05 seconds (50 ms), then immediately returns to normal.
- 0.5 ms would be visually imperceptible, so 50 ms is used.
- Camera shot shake distance is reduced by 50%.
- Contact spark count and visual weight are approximately halved.
- The huge expanding circular shock rings are removed completely.
- This removes the white curved arcs that appeared against field borders.

FIELD MARKINGS

- Outer field border: 14 px with antialiasing.
- Main field markings: 12 px.
- Secondary/goal-area markings: 10 px.
- Goal extensions: 13 px.
- More points are used for center circles, penalty arcs and corner arcs.
- Existing coordinates remain tied to the real collision borders:
  left 318, right 7030, top 770, bottom 4230.

PHANTOM HEEL

- The supplied sound had about 0.337 seconds of leading silence.
- The silence is trimmed and the file is converted to PCM WAV.
- The custom sound is played before visual spawning at -5 dB.
- The generic ability sound no longer plays over Phantom Heel.
- Phantom Heel icon is changed from purple to red.
- Phantom Heel shadow, rim and particles are changed to red tones.

FILES

Characters/ball.gd
Characters/ball.tscn
Characters/ball_shadow.gd
Characters/player.gd
Characters/ability_heel_turn.svg
Scenes/kick_feedback_fx.gd
Scenes/match_camera.gd
Scenes/field_visuals.gd
Audio/phantom_heel_sharingan.wav

INSTALL

1. Close Godot.
2. Copy the CONTENTS of this folder into the project root.
3. Overwrite the listed files.
4. Let Godot import the new WAV and modified SVG.

PROJECT ROOT:
C:\Users\salik\Documents\football-2d-

PARSE TEST

& "C:\Users\salik\Downloads\Godot_v4.7.1-stable_win64.exe" `
  --headless `
  --path "C:\Users\salik\Documents\football-2d-" `
  --editor `
  --quit

This patch does not contain AI, trainer, checkpoint or policy files.
