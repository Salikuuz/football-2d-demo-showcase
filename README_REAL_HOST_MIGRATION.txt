REAL MULTIPLAYER HOST MIGRATION + PVE RANKED UI POLISH
=======================================================

Builds on the previous highest-MMR PvE Ranked matchmaking update.

PvE Ranked UI
-------------
- INFO button is inside the PvE Ranked matchmaking card and opens the existing
  ranked information popup.
- Long division titles in this matchmaking card use a clean static outlined
  RichText style instead of per-character glint, removing the stray-symbol /
  artifact appearance.

Host system (all Steam multiplayer modes)
-----------------------------------------
- Current lobby host has a gold crown in Teamselection rosters.
- Roster snapshots explicitly carry the current server/host peer ID.
- Host-only kick logic no longer assumes a hard-coded host ID.
- Custom Multiplayer, Ladder and PvE Ranked all use the same host migration
  layer because it lives in NetworkManager rather than one game mode.
- When the current Steam host leaves normally, it chooses a deterministic
  successor from the remaining lobby members and calls Steam.setLobbyOwner()
  before closing its game peer.
- If the host crashes/disconnects, Steam's lobby ownership can transfer to a
  remaining member; clients stay in the Steam lobby, discover the new owner,
  and rebuild the Godot SteamMultiplayerPeer around that owner.
- The promoted player creates the new game host; everyone else reconnects.
- Player identity/cosmetics are registered again and each client restores its
  previous ability/team selection where that mode allows manual team choice.
- READY is intentionally reset after migration so a recovering lobby cannot
  accidentally launch before everybody has reconnected.
- New host metadata, invite ownership and crown follow the migrated owner.
- Non-host clients now correctly call Steam.leaveLobby() when leaving; the old
  implementation only left Steam when the local user happened to be owner.

Live match behavior
-------------------
A live match is NOT hot-migrated frame-for-frame. That would risk accepting an
out-of-date client copy of ball/physics state as authoritative. Instead, if a
host disappears during a match, the remaining Steam party migrates host and
returns to the SAME mode's lobby. The interrupted match is cancelled without a
win/loss/MMR result. This is deliberately safer and deterministic.

Local ENet
----------
The crown/host UI still identifies the local server. Automatic network host
migration is Steam-only because ENet clients are connected to a specific IP
server and this project does not have a LAN rendezvous service that can tell
all peers a replacement host address.

Changed project files
---------------------
Scenes/network_manager.gd
Scenes/match_manager.gd
Scenes/Teamselection.gd
Scenes/connection_menu.gd
