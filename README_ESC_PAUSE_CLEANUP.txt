ESC-ONLY PAUSE CLEANUP + BALL VISIBILITY FIX
=============================================

Changes
-------
- Removed the newly-created top-right pause button completely.
- Pause / forfeit menu is now opened only through ESC / ui_cancel.
- Permanently suppresses the legacy top-right Scoreboard Cancel Match `×`
  control, even if scoreboard code attempts to show it during a match.
- Keeps Cancel / Forfeit available inside the ESC menu.

Ball visibility fix
-------------------
Two safeguards were added:
1. Blur rendering now uses an explicit BackBufferCopy before sampling the
   screen texture.
2. The exact Sprite2D visual state of the ball is captured before a real
   local/global pause and restored after unpausing, followed by a forced redraw.

The snapshot preserves whether the ball was already intentionally hidden, so
goal explosion / replay behavior is not overridden by the fix.

Base
----
This patch is a follow-up to:
ranked_60s_grace_and_host_multiplayer_pause.zip

File changed
------------
Scenes/ingame_pause_overlay.gd
