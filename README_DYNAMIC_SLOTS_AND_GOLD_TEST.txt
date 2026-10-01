PVE RANKED DYNAMIC OPEN SLOTS + LADDER CHAMPION VISUAL TEST
============================================================

Dynamic PvE Ranked formation slots
----------------------------------
The small YOUR PARTY formation now follows the selected queue size:

1v1: 1 visible player position, 0 OPEN SLOT labels
2v2: 2 visible positions, 1 OPEN SLOT when solo
3v3: 3 visible positions, 2 OPEN SLOT labels when solo
4v4: 4 visible positions, 3 OPEN SLOT labels when solo

Slots beyond the selected party size are hidden entirely.

Testing the Ladder Champion gold name
-------------------------------------
From the project root:

  .\training\enable_ladder_champion_visual_test.ps1

Then fully leave/re-enter a multiplayer lobby, or restart the game. Your local
profile should be synchronized with pve_ladder_champion=true and your pregame
name should show the moving golden shine.

After testing, restore the exact original seasonal_ladder.cfg with:

  .\training\restore_ladder_champion_visual_test.ps1

The enable script backs up the real file before changing anything. The restore
script restores it byte-for-byte from that backup. This test does NOT grant a
real clear permanently.
