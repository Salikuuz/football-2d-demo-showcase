class_name ChampionsLeagueManager
extends FootballMatchManager


# Compatibility subclass for scenes that want a dedicated Draft manager.
# The authoritative implementation lives in FootballMatchManager so every
# existing playfield, RPC path, bot controller, and aggregate-score consumer
# uses the same state machine without replacing its configured scene node.
