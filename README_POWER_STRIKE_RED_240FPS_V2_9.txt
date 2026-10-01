FOOTBALL POWER STRIKE RED + 240 FPS V2.9

APPLY AFTER V2.8.

FIXES
- Power Strike player aura and pulse rim stay red for the whole active ability.
- The Power Strike ball becomes red before kick feedback is emitted.
- The ordinary Line2D ball trail turns red for Power Strike.
- The ordinary speed-trail particles turn red for Power Strike.
- The Power Strike ball no longer turns white just because speed falls below
  1100.
- Red state survives bounces, slows, redirects, goalkeeper blocks and reflex
  deflections.
- It clears on a real ball reset or the next ordinary non-Power-Strike kick.
- Adds run/max_fps=240.
- No camera, fullscreen, resolution, physics-tick, AI, training, force,
  duration or cooldown changes.

INSTALL
Copy everything inside this folder into:
C:\Users\salik\Documents\football-2d-

Overwrite:
- Characters\ball.gd
- Characters\player.gd
- project.godot

PARSE TEST
& "C:\Users\salik\Downloads\Godot_v4.7.1-stable_win64.exe" `
  --headless `
  --path "C:\Users\salik\Documents\football-2d-" `
  --editor `
  --quit
