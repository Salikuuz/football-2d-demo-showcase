LADDER CHAMPION GOLD NAME — SYNC FIX
====================================

Root cause fixed
----------------
The previous implementation added `pve_ladder_champion` to the network cosmetic
loadout, but `FootballCosmeticInventory.sanitize_catalog_network_loadout()`
discarded unknown keys. FootballPlayer also runs that sanitizer in its
cosmetic_loadout setter, so the prestige flag was always lost before
Teamselection rendered the roster.

This update:
- officially preserves pve_ladder_champion in the central sanitizer;
- explicitly preserves it in NetworkManager too;
- keeps the existing roster synchronization;
- keeps the animated gold traveling-name effect;
- keeps host underline support;
- keeps dynamic 1v1/2v2/3v3/4v4 PvE Ranked slots;
- adds a direct visual-test marker so testing cannot fail because of ConfigFile
  parsing/caching;
- prints `[LadderChampion] local prestige flag = true/false` when the local
  network loadout refreshes.

Test
----
1. Install this patch.
2. Run:
   .\training\enable_ladder_champion_visual_test.ps1
3. FULLY close and restart the game.
4. Enter a multiplayer pregame lobby.
5. Confirm the Godot console says:
   [LadderChampion] local prestige flag = true
6. Your name should be visibly gold with a moving shine.

Restore
-------
.\training\restore_ladder_champion_visual_test.ps1

The first backup created by the previous test helper is preserved and restored,
so the failed earlier test does not destroy the user's real ladder save.
