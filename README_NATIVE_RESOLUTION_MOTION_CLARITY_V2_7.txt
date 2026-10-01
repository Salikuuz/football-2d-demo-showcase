FOOTBALL NATIVE RESOLUTION / MOTION CLARITY V2.7

DIAGNOSIS FROM THE GAMEPLAY CLIP

The game was not primarily suffering from a motion-blur post-process.
FullscreenManager forced the complete game into a 1152x648 virtual canvas.
Godot then stretched that low-resolution canvas to the actual window or
fullscreen resolution. This made moving edges and detailed player icons soft.

This is especially visible on a 5120x1440 monitor.

FIXES

- Removes the forced 1152x648 virtual canvas.
- Renders directly at the physical/native window resolution.
- Automatically fits the complete field and outside goal structures at every
  resolution and aspect ratio, including ultrawide.
- The full playfield remains visible.
- Caps rendering at 240 FPS.
- Keeps the existing physics interpolation.
- Does not change the physics tick rate or gameplay physics.
- Reimports all moving ability SVG graphics at 4x resolution.
- Ability mipmaps remain disabled to avoid soft foreground portraits.
- Does not modify the ball PNG, ball import settings, ball filtering, ball
  interpolation, ball collision, AI, training, multiplayer or kick forces.

IMPORTANT

A 60 FPS Medal recording can still show temporal motion softness even when the
game itself renders at 240 FPS. For the clearest recording, use Medal's highest
available FPS setting. Paused frames should now be much sharper, especially in
fullscreen/native resolution.

INSTALL

Copy the contents of this folder into:
C:\Users\salik\Documents\football-2d-

Allow overwriting. Godot will reimport the ability SVGs.

PARSE / IMPORT TEST

& "C:\Users\salik\Downloads\Godot_v4.7.1-stable_win64.exe" `
  --headless `
  --path "C:\Users\salik\Documents\football-2d-" `
  --editor `
  --quit

TEST

1. Start in windowed mode and move continuously.
2. Press F11 for fullscreen.
3. Confirm the complete field and both outside goal structures are visible.
4. Confirm the player portrait is much sharper in fullscreen and when goal
   camera zoom occurs.
5. Check that the ball remains crisp and unchanged.
