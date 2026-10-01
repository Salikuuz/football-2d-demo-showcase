PVE RANKED FORMATION + CLEAN TEXT + HOST UNDERLINE

- Host crown removed in every Teamselection multiplayer roster.
- Current host player name is underlined instead.
- PvE Ranked party display uses four fixed slots:
  top-left, top-right, bottom-left, bottom-right.
- Slots are ordered by team_slot and update live.
- Original stacked roster is restored outside PvE Ranked.
- PvE Ranked matchmaking division + MMR text no longer uses bold/outline
  rendering, fixing the stray glyph/symbol artifacts shown in the screenshots.
- Previous INFO button and real Steam host-migration logic remain unchanged.

Changed file:
Scenes/Teamselection.gd
