FOOTBALL BALL CRISP OUTLINE V2.5

APPLY AFTER THE PREVIOUS VISUAL PATCHES.

FIXES
- Reverts the ball texture's mipmap generation.
- Forces nearest/crisp filtering on the Ball Sprite2D only.
- Leaves the text/font smoothing and other UI smoothing untouched.
- Adds a thin black external outline directly to the ball PNG.
- Preserves the corrected centered ball pivot, shadow, collision alignment,
  shot pop, trails, physics, AI, and gameplay behavior.

INSTALL
Copy the contents of this folder into:
C:\Users\salik\Documents\football-2d-

Overwrite:
- theodoreball.png
- theodoreball.png.import
- Characters\ball.tscn

Godot should reimport the ball texture automatically.

PARSE / IMPORT TEST
& "C:\Users\salik\Downloads\Godot_v4.7.1-stable_win64.exe" `
  --headless `
  --path "C:\Users\salik\Documents\football-2d-" `
  --editor `
  --quit
