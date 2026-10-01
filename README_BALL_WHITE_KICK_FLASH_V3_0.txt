FOOTBALL BALL WHITE KICK FLASH V3.0

APPLY AFTER V2.9.

CHANGE
- Every successful kick or pass produces a very short white flash directly
  over the football.
- Total visible time is about 50 milliseconds:
    15 ms solid white
    35 ms fade-out
- A separate white silhouette overlay is used.
- The actual ball sprite is not recolored, rotated, offset, blurred or moved.
- The crisp nearest-filtered ball and black outline remain unchanged.
- Power Strike returns to its red ball state immediately after the flash.
- The existing centered ball-size pop and trail effects remain unchanged.
- No camera, physics, collision, force, AI, multiplayer, ability or FPS changes.

INSTALL
Copy everything inside this folder into:
C:\Users\salik\Documents\football-2d-

Overwrite:
Characters\ball.gd

PARSE TEST
& "C:\Users\salik\Downloads\Godot_v4.7.1-stable_win64.exe" `
  --headless `
  --path "C:\Users\salik\Documents\football-2d-" `
  --editor `
  --quit
