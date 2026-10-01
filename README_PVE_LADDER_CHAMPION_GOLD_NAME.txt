PVE LADDER CHAMPION GOLD NAME REWARD
====================================

Reward condition
----------------
A human player permanently earns the lobby-name prestige effect after actually
clearing the full 12-rung PvE Seasonal Ladder challenge.

- The final-rung win is the award trigger.
- Only human players who were on the ladder team are awarded.
- Spectators are not awarded.
- The reward persists in user://seasonal_ladder.cfg.
- Existing players with season.clears > 0 automatically count as completed.

Visual
------
Completed players get a warm-gold name with a smooth left-to-right traveling
shine inspired by the Champions League rank glint.

The current lobby host underline remains compatible with the gold animation.
The name can therefore be both gold-shining and underlined.

Where it appears
----------------
The completion state is attached to the player's network cosmetic/loadout
metadata, so every peer can see it in pregame rosters across multiplayer modes,
including the new PvE Ranked 2x2 party formation.

Files
-----
Scenes/Teamselection.gd
Scenes/match_manager.gd
Scenes/network_manager.gd
