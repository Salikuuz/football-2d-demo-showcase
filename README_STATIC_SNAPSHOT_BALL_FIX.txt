PAUSE BALL RENDER FIX

The pause system no longer touches the ball renderer at all.

Removed:
- Ball Sprite2D visibility/state snapshots
- visibility toggling on resume
- modulate/scale restoration
- live screen_texture shader
- BackBufferCopy

New pause background:
- captures a one-time screenshot of the local viewport before opening
- downsamples it to about 1/10 resolution for a soft blur
- displays that static image under a dark overlay
- deletes the snapshot again when the pause menu closes

Kept:
- ESC-only pause menu
- no separate pause button
- old top-right Cancel Match control suppressed
- synchronized host multiplayer pause
- 60-second ranked/PvE Ranked/PvE Ladder cancel grace behavior

Changed:
Scenes/ingame_pause_overlay.gd
