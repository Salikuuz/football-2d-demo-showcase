FOOTBALL FIXED ABILITY ICON SIZE V3.3

DIAGNOSIS
Teamselection.gd used Button.expand_icon = true.

The button text includes:
- the complete ability name,
- two spaces,
- three difficulty stars,
- and sometimes a selected check.

Godot therefore shrank the built-in icon according to the horizontal space
left after the text. Short names retained visible icons, Dead Zone Pass became
tiny, and Goalkeeper's Reach could lose the icon entirely.

FIX
- Removes ability icons from Button's built-in text/icon layout.
- Adds one independent TextureRect named FixedAbilityIcon to every card.
- Every icon receives the same fixed 22x22 box.
- Ability names and stars can no longer resize the icon.
- Reserves a fixed left margin for the icon.
- Uses 10 px button text, dropping to 9 px only for the longest complete
  strings so Goalkeeper's Reach remains visible.
- Keeps the original 1x SVG imports.
- Does not change the icon artwork, ability order, menu dimensions, gameplay,
  particles, ball, camera, field, fonts, FPS, physics, AI or multiplayer.

INSTALL
Copy the contents of this folder into:
C:\Users\salik\Documents\football-2d-

Overwrite:
Scenes\Teamselection.gd

PARSE TEST
& "C:\Users\salik\Downloads\Godot_v4.7.1-stable_win64.exe" `
  --headless `
  --path "C:\Users\salik\Documents\football-2d-" `
  --editor `
  --quit
