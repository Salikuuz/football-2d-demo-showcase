FOOTBALL FREEPLAY-SIZED TEAM UI + REAL MODULATE FLASH V3.4

APPLY AFTER V3.3.

TEAM-SELECTION DIAGNOSIS
The freeplay and team-selection screens did not share the same dimensions.

FREEPLAY
- columns: 205 px minimum
- cards: 200x44
- card text: 14 px
- section headers: 16 px
- separation: 6 px

TEAM SELECTION BEFORE THIS PATCH
- columns: 164 px minimum
- cards: 160x35
- card text: 10 px
- section headers: 13 px
- separation: 5 px
- fixed icons: 22x22

TEAM-SELECTION FIX
- Uses the freeplay dimensions above.
- Fixed ability icons are now 36x36.
- Icons remain independent from text length.
- Long labels and stars cannot shrink or remove an icon.
- Only extremely long selected strings use 13 px text.
- No lobby, host-options, roster or gameplay logic is changed.

BALL WHITE FLASH DIAGNOSIS
The previous versions used a duplicate sprite or a custom shader. The shader
changed Theodore's normal color appearance.

BALL FIX
- Starts from the last working v2.9 Power Strike ball implementation.
- Removes both failed flash approaches entirely.
- Uses the same Ball Sprite2D.modulate property used by Power Strike.
- A kick or pass applies Color(4,4,4,1) for 35 ms.
- It then snaps back to the current real state:
  normal Theodore, or Power Strike red.
- No shader.
- No duplicate Sprite2D.
- No permanent light-skin tint.
- The impact scale pop remains, but it no longer recolors the ball.
- No texture, outline, pivot, filtering, collision, physics, camera, AI,
  multiplayer, kick-force, ability, field or FPS changes.

INSTALL
Close Godot.
Copy everything inside this folder into:
C:\Users\salik\Documents\football-2d-

Overwrite:
- Scenes\Teamselection.gd
- Characters\ball.gd

LOCAL PARSE TEST
& "C:\Users\salik\Downloads\Godot_v4.7.1-stable_win64.exe" `
  --headless `
  --path "C:\Users\salik\Documents\football-2d-" `
  --editor `
  --quit
