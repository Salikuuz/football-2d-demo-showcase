60-SECOND GRACE + HOST GLOBAL MULTIPLAYER PAUSE
================================================

Cancel / forfeit:
- First 60 seconds of actual live gameplay: old no-result Cancel Match behavior.
- No MMR loss and no PvE Ladder run reset during that window.
- PvE Ranked Alt+F4/disconnect abandonment protection also stays OFF until 60s.
- From 60s onward: Ranked/PvE Ranked cancellation is a forfeit; Ladder resets.
- The 60 seconds are cumulative across the whole match, so leg 2 does not
  create a second free-cancel minute.
- Team introductions, kickoff countdown/reset time, and pauses do not consume
  the grace window.

Multiplayer pause:
- Host ESC / pause icon pauses the entire online match on every peer.
- All players get the blurred pause screen.
- Clients see MATCH PAUSED BY HOST and cannot resume.
- Only the host resumes.
- Client ESC alone does not globally pause the game.
- NetworkManager keeps processing while paused so Steam ownership, networking
  and host migration do not freeze.
- Host migration forcibly clears a synchronized pause if the old host vanishes.

Files:
Scenes/match_manager.gd
Scenes/ingame_pause_overlay.gd
Scenes/network_manager.gd
