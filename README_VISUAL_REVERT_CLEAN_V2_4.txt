FOOTBALL VISUAL REVERT / CLEANUP V2.4

APPLY AFTER:
- Visual Fix v2.2
- Camera/Smoothing v2.3
- Parse Fix v2.3.1

CHANGES
- Restores the center circle and center dot.
- Removes only the curved penalty arcs beside the two penalty areas.
- Keeps the thicker 20/18/16 px antialiased field markings.
- Restores the original full-field camera behavior.
- Removes local-player follow and the 20% local-player zoom.
- Keeps goal camera focus and goal impact.
- Ordinary ball hits no longer shift/rotate the whole camera.
- Removes the v2.3 ball-contact cuts/sparks overlay completely.
- Keeps the centered 150% ball pop, speed trail, and player hit feedback.
- Removes direction-based rotation of the player portrait/circle on shots.
- Does not overwrite project.godot or texture import settings, so the text/font
  smoothing and texture-filtering changes from v2.3 remain active.

INSTALL
Copy the contents of this folder into:
C:\Users\salik\Documents\football-2d-

Overwrite the included files.

PARSE TEST
& "C:\Users\salik\Downloads\Godot_v4.7.1-stable_win64.exe" `
  --headless `
  --path "C:\Users\salik\Documents\football-2d-" `
  --editor `
  --quit
