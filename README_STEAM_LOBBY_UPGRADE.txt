STEAM LOBBY EXPERIENCE UPGRADE

Implemented:
- Public / Friends Only / Private lobby creation.
- Public browser rows now show lobby state, map, match duration, score target,
  active players, spectators, total connected members and host name.
- Waiting lobbies sort ahead of in-progress lobbies.
- 8 playing slots + 4 dedicated spectator slots for Steam lobbies.
- In-progress public matches remain joinable while a spectator slot is free.
  Players joining an in-progress match are automatically placed in Spectator.
- Existing Ready Up system is preserved.
- Host-only Kick Player control in Host Options.
- Players stay in the same Steam lobby after the match and return to the lobby flow.
- Lobby metadata refresh is event-driven/debounced rather than continuously spammed.
- Lightweight unreliable RTT/jitter monitor (1.5 s probe, 2 s snapshot) is shown
  in the team lobby and beside human roster names.
- Kicked clients receive a clearer disconnect reason when possible.

Network note:
The RTT/jitter monitor is intentionally tiny and uses unreliable RPCs. It is mainly
there to tell whether reported stutters line up with actual network jitter. The
lobby changes avoid unnecessary metadata traffic, but gameplay lag spikes can also
come from physics/AI/rendering and should be profiled separately if ping remains stable.

No project.godot changes are included.
