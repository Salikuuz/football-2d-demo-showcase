FOOTBALL 2D - VISUAL IMPACT UPGRADE V1

IMPORTANT

Do not overwrite the live project while worker training is still running.
Wait until the coordinator has finished, printed its final ranking, and returned
to the normal PowerShell prompt.

This package does not contain or modify anything inside:
- ai/
- training/
- human demonstration data
- user:// hybrid AI checkpoints

WHAT CHANGED

BALL FEEL
- Kick/pass impact strength scales from the real kick impulse.
- Directional white-hot contact flash.
- Larger team-colored shock ring and sparks.
- Ball squash/stretch on contact without changing its collision shape.
- Stronger speed trail with team-colored core.
- Soft moving shadow under the ball.
- Strength-scaled camera shake.

PLAYER FEEDBACK
- Successful pass/kick flashes the player's outer badge ring.
- Chipmunk portrait performs a small contact squash.
- Local player keeps their real display name instead of being renamed "You".
- New pulsing segmented control ring and chevron identifies the local player.

FIELD
- Subtle shader grain and mowing variation.
- Cleaner outer line, center line, center circle and center spot.
- Improved penalty areas, six-yard areas, penalty spots and arcs.
- Colored goal-mouth accents.
- Corner arcs.

SCREEN / GOALS
- Slight vignette below the HUD.
- Goal edge flash and short white strobe.
- Strong goal camera punch.
- Added generated low goal boom layered below the existing goal sound.

SOUND
- The existing soccer kick remains the main sound.
- A generated low body layer is added beneath it and scales with force.
- A generated goal boom is added beneath the existing goal sound.

INSTALL

1. Wait for all active trainers/workers to finish.
2. Make a backup copy of the project folder.
3. Extract this ZIP directly into:

   C:\Users\salik\Documents\football-2d-

4. Allow Windows to overwrite the listed visual files.
5. Do not overwrite any ai/ or training/ files; this ZIP does not contain them.

PARSE TEST

cd "C:\Users\salik\Documents\football-2d-"

$Godot = "C:\Users\salik\Downloads\Godot_v4.7.1-stable_win64.exe"
$Project = "C:\Users\salik\Documents\football-2d-"

& $Godot --headless --path $Project --editor --quit

Then open the game normally and test:
- a soft pass
- a half-strength shot
- a maximum charged shot
- a wall rebound
- a goal
- local-player indicator visibility as host and client

QUICK TUNING

Player scene / Ball Contact Feel:
- impact_body_minimum_volume_db
- impact_body_maximum_volume_db
- ball_contact_squash_amount
- ball_contact_flash_seconds

Ball scene / Ball Impact Feel:
- impact_squash_amount
- impact_visual_seconds
- impact_camera_shake_strength

Camera2D / Impact Camera:
- maximum_shake_offset
- maximum_shake_rotation_degrees
- shake_decay_per_second
- goal_impact_strength

ScreenVisualFX:
- vignette_strength
- goal_boom_volume_db

To mute only the new sound layers, set their maximum/goal volume to -80 dB.
