FOOTBALL UI / ICON / FONT RESTORE + REAL BALL FLASH V3.2

APPLY AFTER THE CURRENT PATCHES, INCLUDING V3.1.

ROLLBACKS
- Restores the original project font and UI rendering behavior.
- Removes every global font oversampling, MSDF, font-mipmap, texture-filter
  and subpixel snap override introduced by earlier visual patches.
- Restores all ability SVG imports to their original 1x scale.
- This fixes ability button/icon sizing and returns the Abilities and Host
  Options panels to their original layout.
- No menu script or layout scene is replaced.

KEPT
- 240 FPS render cap.
- Player physics interpolation.
- 8x 2D MSAA edge antialiasing.
- Stylized field grain/darker variants.
- Goal glow.
- Overtime border.
- Stylized scoring announcement.
- Unique ability activation particles.
- Power Strike red visuals and red trail.
- Phantom Heel red/Sharingan visuals.

BALL WHITE FLASH
- Removes the failed duplicate-sprite approach.
- Uses one ShaderMaterial directly on the real Ball Sprite2D.
- Normal ball or Power Strike red is the underlying base tint.
- Every successful kick/pass overrides the actual ball to pure white.
- White hold: 12 ms.
- White fade: 42 ms.
- It then reveals the correct normal or Power Strike red state.
- No ball texture, pivot, outline, filtering, collision, physics, position,
  rotation or camera changes.

INSTALL
Close the running game/editor.
Copy everything inside this folder into:
C:\Users\salik\Documents\football-2d-

Allow overwriting.

Godot will reimport the ability SVG files at their original dimensions.

LOCAL PARSE / REIMPORT TEST
& "C:\Users\salik\Downloads\Godot_v4.7.1-stable_win64.exe" `
  --headless `
  --path "C:\Users\salik\Documents\football-2d-" `
  --editor `
  --quit
