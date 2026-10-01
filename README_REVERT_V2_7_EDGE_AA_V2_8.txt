FOOTBALL V2.7 FULL REVERT + TARGETED EDGE AA V2.8

WHAT THIS REVERTS
- Native-resolution fullscreen changes from v2.7.
- Automatic camera framing from v2.7.
- 240 FPS project cap from v2.7.
- 4x particle rasterization from v2.7.
- The enlarged/fat ability particles.
- All v2.7 fullscreen and camera behavior.

WHAT THIS KEEPS
- The original full-field camera behavior.
- The original 1152x648 game canvas behavior.
- Goal camera effects from the earlier visual patches.
- Player physics interpolation from v2.6.
- Crisp outlined ball from v2.5.
- Thick field markings and earlier visual fixes.

TARGETED EDGE FIX
- Changes 2D MSAA from 4x to 8x.
- Uses higher raster quality only for player ability portraits/icons.
- Keeps ability_particle.svg at its original 1x scale.
- Keeps linear filtering only on the moving player portrait and shadow.
- Narrows the portrait circle mask edge so it is antialiased but not fuzzy.
- Does not change text, HUD, menus, camera zoom, fullscreen resolution or ball.

INSTALL
Copy everything inside this folder into:
C:\Users\salik\Documents\football-2d-

Allow overwriting. Godot will reimport the ability SVG files.

PARSE / IMPORT TEST
& "C:\Users\salik\Downloads\Godot_v4.7.1-stable_win64.exe" `
  --headless `
  --path "C:\Users\salik\Documents\football-2d-" `
  --editor `
  --quit
