FOOTBALL VISUAL CAMERA + SMOOTHING PATCH V2.3

INSTALL AFTER V2.2

Copy the contents of this folder into the project root and overwrite files.

CHANGES
- Removes the center circle and center dot shown in the screenshot.
- Removes all large/long ball-contact shapes that could flash over pitch lines.
- Replaces them with a small local team-colored burst around the ball.
- Replaces the player's circular contact flash with eight short badge ticks.
- Keeps the existing 150% / 50 ms ball pop.
- Disables camera shake for ordinary ball contact, so lines and text do not shimmer.
- Keeps the stronger goal camera impact.
- Camera follows the local human player and uses 1.20x the old zoom.
- Spectators, main menu, and clients without a joined red/blue player retain the old field camera.
- Field lines are thicker, single-stroke, and antialiased without fuzzy shadow under-strokes.
- Enables MSDF/default-font mipmaps and oversampling for sharper text.
- Enables linear-with-mipmaps filtering and mipmaps for raster art downscaled by Camera2D.

NO AI, TRAINING, CHECKPOINT, PHYSICS, KICK FORCE, OR MULTIPLAYER RULES ARE INCLUDED.

PARSE CHECK
& "C:\Users\salik\Downloads\Godot_v4.7.1-stable_win64.exe" `
  --headless `
  --path "C:\Users\salik\Documents\football-2d-" `
  --editor `
  --quit
