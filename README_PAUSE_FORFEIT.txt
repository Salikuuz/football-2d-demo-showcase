INGAME PAUSE + RANKED FORFEIT PROTECTION
=========================================

PAUSE UI
--------
- ESC opens a blurred/dimmed pause menu during a live match.
- A small `Ⅱ` button is also shown at the top-right during gameplay.
- Solo/no-remote-peer matches truly pause the SceneTree.
- Online matches deliberately DO NOT freeze the shared simulation; the menu
  clearly says the match continues online. Allowing one player to stop an
  online ranked game would itself be exploitable.
- ESC resumes/closes the menu.
- Match end/cancel always clears a local pause so the tree cannot remain stuck.

CANCEL / FORFEIT
----------------
Cancel Match now has a second confirmation screen.

PvE Ranked:
- confirmation explicitly warns that it is a forfeit;
- confirming ends the match as a CPU win;
- normal MMR-loss calculation is used;
- all participating humans receive the normal loss result.

PvE Ladder:
- confirming is a loss;
- the 12-match run resets through the existing Ladder loss path.

Ranked mode:
- host cancel is treated as a forfeit rather than a no-result cancel.

Custom/unranked:
- cancel remains a no-result lobby reset, but still requires confirmation.

RAGE-QUIT / ALT-F4 PROTECTION
-----------------------------
PvE Ranked writes a local abandonment marker at match start containing the
opponent rating used for the loss calculation.

A legitimate result overwrites/clears that marker.

If the game is killed/disconnected before a result, the next launch resolves
that pending match as one loss and increments the played-match count. This
closes the "quit at the end to avoid MMR loss" loophole.

Steam host migration exception:
- surviving clients clear THEIR abandonment marker before reconnecting;
- the player who actually disappeared cannot clear theirs, so their pending
  loss remains and is resolved when they return.

FILES
-----
Scenes/match_manager.gd
Scenes/ingame_pause_overlay.gd
