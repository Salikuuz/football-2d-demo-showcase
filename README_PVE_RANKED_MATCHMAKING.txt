PVE RANKED MATCHMAKING + LOBBY POLISH
=======================================

What changed
------------
1. PvE Ranked matchmaking is now based on the highest-MMR HUMAN in the party,
   not automatically the host.
2. No ranked CPUs are spawned while the party is choosing abilities / readying.
3. Once every human is ready and all MMR profiles have reached the host, the
   server locks matchmaking, generates the hidden CPU lineup, spawns it, and
   immediately starts the match.
4. The existing league intelligence ranges, footballer playstyles, bosses,
   upper-division guests, two-leg rules and per-player MMR calculations stay.
5. Upper-division guest cadence also follows the highest-rated matchmaking
   player's match count rather than the host's count.
6. Team Selection in PvE Ranked now looks like a ranked ready room:
   - no Join Blue / Join Red controls
   - no Leave Team
   - no Spectate
   - no enemy roster preview
   - no Unassigned/Spectator roster sections
   - only YOUR PARTY is shown
   - larger ranked matchmaking card
7. The ranked card shows:
   - matchmaking division
   - your personal MMR
   - highest-party matchmaking rating
   - 1v1/2v2/3v3/4v4 size
   - party ready count
   - personal division progress
   - explicit hidden-opponent status
8. Steam lobby copy now says PvE Ranked uses the highest party MMR.

Fairness
--------
The highest party MMR only sets the opponent bracket. Each human still gets an
individual MMR change calculated from their own rating against the actual CPU
team MMR, including the existing high-opponent loss protection.

Files
-----
Scenes/match_manager.gd
Scenes/Teamselection.gd
Scenes/connection_menu.gd
