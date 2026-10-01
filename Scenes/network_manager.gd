class_name NetworkManager
extends Node


enum NetworkMode {
	NONE,
	LOCAL_ENET,
	STEAM,
	FREEPLAY,
	SINGLEPLAYER_RANKED
}


const LOCAL_PORT: int = 8910
const LOCAL_ADDRESS: String = "127.0.0.1"
const MAX_CLIENTS: int = 12
const STEAM_PLAYER_SLOTS: int = 12
const STEAM_SPECTATOR_SLOTS: int = 4
const STEAM_LOBBY_MEMBER_LIMIT: int = STEAM_PLAYER_SLOTS + STEAM_SPECTATOR_SLOTS
const STEAM_LOBBY_PUBLIC: int = 2
const STEAM_LOBBY_FRIENDS_ONLY: int = 1
const STEAM_LOBBY_PRIVATE: int = 0
const LATENCY_PROBE_INTERVAL_MSEC: int = 1500
const LATENCY_SNAPSHOT_INTERVAL_MSEC: int = 2000
const LOBBY_METADATA_DEBOUNCE_MSEC: int = 250
const STEAM_VIRTUAL_PORT: int = 0
const STEAM_RESULT_OK: int = 1
# GodotSteam enum values kept as plain integers so this script can also compile
# in the Web build where the desktop-only Steam GDExtension is absent.
const STEAM_LOBBY_COMPARISON_EQUAL: int = 0
const STEAM_LOBBY_DISTANCE_FILTER_WORLDWIDE: int = 3
const STEAM_LOBBY_ENTER_SUCCESS: int = 1
const GAME_ID: String = "football-2d"
const NETWORK_PROTOCOL_VERSION: int = 1
const LOBBY_BROWSER_KEY: String = "theodore-ball-public-v1"
const STEAM_SESSION_STANDARD: int = 0
const STEAM_SESSION_LADDER: int = 1
const STEAM_SESSION_PVE_RANKED: int = 2
const STEAM_SESSION_DRAFT: int = 3
const HOST_MIGRATION_RETRY_MSEC: int = 250
const HOST_MIGRATION_TIMEOUT_MSEC: int = 10000
const HOST_MIGRATION_PROFILE_RETRY_MSEC: int = 150
const HOST_MIGRATION_PROFILE_MAX_ATTEMPTS: int = 40
const CPU_GOAL_THEME_CHANCE: float = 0.20

const PLAYER_SCENE_FALLBACK_PATHS: Array[String] = [
	"res://Characters/player.tscn",
	"res://player.tscn"
]


@export_category("Steam")
@export var auto_open_invite_overlay: bool = false
@export var steam_lobby_callback_timeout: float = 15.0
@export var steam_peer_connection_timeout: float = 20.0
@export var steam_lobby_search_timeout: float = 20.0

@export_category("Local Connection")
@export var local_connection_timeout: float = 8.0

@export_category("Player Spawning")
@export var player_scene: PackedScene
@export var player_spawner: MultiplayerSpawner
@export var players_parent: Node2D


signal connection_changed(message: String)
signal session_started
signal session_ended
signal lobby_search_started
signal lobby_list_updated(lobbies: Array[Dictionary])
signal latency_snapshot_updated(snapshot: Dictionary)
signal lobby_metadata_changed(metadata: Dictionary)
signal host_changed(host_steam_id: int, local_is_host: bool)


var current_mode: NetworkMode = NetworkMode.NONE
var steam_peer: Variant = null
var lobby_id: int = 0
var setup_complete: bool = false
var steam_available: bool = false
var creating_lobby: bool = false
var joining_lobby: bool = false
var invite_after_lobby_created: bool = false
var searching_lobbies: bool = false
var pending_lobby_name: String = ""
var pending_lobby_type: int = STEAM_LOBBY_PUBLIC
var current_lobby_type: int = STEAM_LOBBY_PUBLIC
var pending_session_type: int = STEAM_SESSION_STANDARD
var current_session_type: int = STEAM_SESSION_STANDARD
var pending_ladder_fresh_start: bool = false
var pending_ranked_team_size: int = 2
var current_ranked_team_size: int = 2
var _latest_roster_snapshot: Dictionary = {}
var _lobby_metadata_dirty: bool = false
var _lobby_metadata_due_msec: int = 0
var _next_latency_probe_msec: int = 0
var _next_latency_snapshot_msec: int = 0
var _ping_sequence: int = 0
var _local_latency_ms: int = 0
var _local_jitter_ms: int = 0
var _peer_latency: Dictionary = {}
var _disconnect_reason_override: String = ""
var _connection_stage: StringName = &""
var _connection_deadline_msec: int = 0
var _lobby_search_deadline_msec: int = 0
var _session_active: bool = false
var _host_migration_pending: bool = false
var _host_migration_reconnect_active: bool = false
var _host_migration_deadline_msec: int = 0
var _host_migration_next_attempt_msec: int = 0
var _host_migration_old_owner_steam_id: int = 0
var _host_migration_target_steam_id: int = 0
var _host_migration_local_profile: Dictionary = {}
var _host_migration_was_match_active: bool = false
var _host_migration_restore_pending: bool = false
var _host_migration_restore_attempts: int = 0
var _host_migration_restore_next_msec: int = 0


func _ready() -> void:
	# Host-controlled multiplayer pause freezes gameplay, but Steam/network
	# maintenance and host migration must keep running while SceneTree is paused.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_find_missing_references()

	if not _validate_references():
		connection_changed.emit("Network setup is incomplete")
		return

	_configure_player_spawner()
	_connect_multiplayer_signals()

	# GodotSteam has no Web binary in this project. Keep the offline/freeplay/PvE
	# path completely independent from the desktop extension so the PWA can boot
	# with Web GDExtension support disabled.
	steam_available = false if OS.has_feature("web") else _validate_steam()
	if steam_available:
		_connect_steam_signals()
	_connect_match_state_signals()
	_connect_battle_pass_progress()
	_connect_cosmetic_preferences()

	setup_complete = true

	print("NetworkManager setup complete.")
	print("Local ENet address: %s:%d" % [LOCAL_ADDRESS, LOCAL_PORT])
	print("Spawn path: ", player_spawner.spawn_path)

	if steam_available:
		print("Steam name: ", _steam_api().getPersonaName())
		print("Steam ID: ", _steam_api().getSteamID())
		_try_join_lobby_from_command_line()
	else:
		print("Steam unavailable; local ENet mode is still ready.")


func _process(_delta: float) -> void:
	_process_host_migration()
	_process_host_migration_profile_restore()
	_process_lobby_metadata_refresh()
	_process_latency_monitor()

	if (
		searching_lobbies
		and _lobby_search_deadline_msec > 0
		and Time.get_ticks_msec() >= _lobby_search_deadline_msec
	):
		searching_lobbies = false
		_lobby_search_deadline_msec = 0
		connection_changed.emit("Steam lobby search timed out")
		lobby_list_updated.emit([])

	if (
		_connection_stage == &""
		or _connection_deadline_msec <= 0
		or Time.get_ticks_msec() < _connection_deadline_msec
	):
		return
	_fail_pending_connection(
		"Connection timed out during %s."
		% _get_connection_stage_name()
	)


# ================================================================
# INITIAL SETUP
# ================================================================

func _find_missing_references() -> void:
	var scene_root := get_parent()

	if scene_root == null:
		return

	if player_spawner == null:
		player_spawner = scene_root.get_node_or_null(
			"MultiplayerSpawner"
		) as MultiplayerSpawner

	if players_parent == null:
		players_parent = scene_root.get_node_or_null(
			"Players"
		) as Node2D

	if player_scene != null:
		return

	for path in PLAYER_SCENE_FALLBACK_PATHS:
		if not ResourceLoader.exists(path):
			continue

		var loaded_resource := load(path)

		if loaded_resource is PackedScene:
			player_scene = loaded_resource as PackedScene
			print("Automatically loaded player scene: ", path)
			return


func _validate_references() -> bool:
	var valid := true

	if player_spawner == null:
		push_error(
			"Player Spawner was not assigned and a node named " +
			"'MultiplayerSpawner' was not found."
		)
		valid = false

	if players_parent == null:
		push_error(
			"Players Parent was not assigned and a node named " +
			"'Players' was not found."
		)
		valid = false

	if player_scene == null:
		push_error(
			"Player Scene was not assigned and player.tscn " +
			"could not be found automatically."
		)
		valid = false

	return valid


func _steam_api() -> Object:
	if not Engine.has_singleton("Steam"):
		return null
	return Engine.get_singleton("Steam")


func _new_steam_peer() -> Variant:
	# Instantiate by class name instead of statically referencing the GodotSteam
	# type. This lets the exact same gameplay script load in a Web export where
	# the desktop-only GDExtension is intentionally omitted.
	if not ClassDB.class_exists("SteamMultiplayerPeer"):
		return null
	return ClassDB.instantiate("SteamMultiplayerPeer")


func _validate_steam() -> bool:
	if not Engine.has_singleton("Steam"):
		push_warning("GodotSteam is not available.")
		return false

	if not ClassDB.class_exists("SteamMultiplayerPeer"):
		push_warning("SteamMultiplayerPeer is not available.")
		return false

	if _steam_api().getSteamID() == 0:
		push_warning(
			"Steam is not initialized. Steam mode is unavailable, " +
			"but local ENet mode can still be used."
		)
		return false

	return true


func _configure_player_spawner() -> void:
	player_spawner.spawn_function = _create_player
	player_spawner.spawn_path = player_spawner.get_path_to(
		players_parent
	)


func _connect_multiplayer_signals() -> void:
	if not multiplayer.peer_connected.is_connected(
		_on_peer_connected
	):
		multiplayer.peer_connected.connect(_on_peer_connected)

	if not multiplayer.peer_disconnected.is_connected(
		_on_peer_disconnected
	):
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)

	if not multiplayer.connected_to_server.is_connected(
		_on_connected_to_server
	):
		multiplayer.connected_to_server.connect(
			_on_connected_to_server
		)

	if not multiplayer.connection_failed.is_connected(
		_on_connection_failed
	):
		multiplayer.connection_failed.connect(_on_connection_failed)

	if not multiplayer.server_disconnected.is_connected(
		_on_server_disconnected
	):
		multiplayer.server_disconnected.connect(
			_on_server_disconnected
		)

	if not player_spawner.spawned.is_connected(
		_on_remote_player_spawned
	):
		player_spawner.spawned.connect(_on_remote_player_spawned)


func _connect_steam_signals() -> void:
	if not _steam_api().lobby_created.is_connected(
		_on_steam_lobby_created
	):
		_steam_api().lobby_created.connect(_on_steam_lobby_created)

	if not _steam_api().lobby_joined.is_connected(
		_on_steam_lobby_joined
	):
		_steam_api().lobby_joined.connect(_on_steam_lobby_joined)

	if not _steam_api().join_requested.is_connected(
		_on_steam_join_requested
	):
		_steam_api().join_requested.connect(_on_steam_join_requested)

	if not _steam_api().lobby_match_list.is_connected(
		_on_steam_lobby_match_list
	):
		_steam_api().lobby_match_list.connect(
			_on_steam_lobby_match_list
		)


func _connect_match_state_signals() -> void:
	var match_manager := get_parent().get_node_or_null(
		"MatchManager"
	) as FootballMatchManager
	if match_manager == null:
		return

	if not match_manager.match_started.is_connected(
		_on_match_started
	):
		match_manager.match_started.connect(_on_match_started)

	if not match_manager.match_ended.is_connected(
		_on_match_ended
	):
		match_manager.match_ended.connect(_on_match_ended)

	if not match_manager.match_cancelled.is_connected(
		_on_match_cancelled
	):
		match_manager.match_cancelled.connect(_on_match_cancelled)

	if not match_manager.match_settings_changed.is_connected(
		_on_match_settings_metadata_changed
	):
		match_manager.match_settings_changed.connect(
			_on_match_settings_metadata_changed
		)
	if not match_manager.field_variant_changed.is_connected(
		_on_field_variant_metadata_changed
	):
		match_manager.field_variant_changed.connect(
			_on_field_variant_metadata_changed
		)
	if not match_manager.roster_details_changed.is_connected(
		_on_roster_metadata_changed
	):
		match_manager.roster_details_changed.connect(
			_on_roster_metadata_changed
		)


# ================================================================
# PLAYER SPAWNING
# ================================================================

func _create_player(data: Variant) -> Node:
	if not (data is Dictionary):
		push_error("Player spawn data was not a Dictionary.")
		return null

	var player_data: Dictionary = data

	if not player_data.has("peer_id"):
		push_error("Player spawn data has no peer_id.")
		return null

	if player_scene == null:
		push_error("Cannot create player: Player Scene is null.")
		return null

	var peer_id: int = int(player_data["peer_id"])
	var player := player_scene.instantiate() as FootballPlayer

	if player == null:
		push_error(
			"player.tscn does not use FootballPlayer " +
			"on its root node."
		)
		return null

	player.name = str(peer_id)
	player.owner_peer_id = peer_id
	player.cpu_controlled = bool(player_data.get("cpu_controlled", false))
	player.display_name = str(player_data.get(
		"display_name",
		_get_fallback_player_name(peer_id)
	))
	player.cosmetic_loadout = _sanitize_cosmetic_loadout(
		player_data.get("cosmetic_loadout", {}) as Dictionary
	)

	# Preserve the existing server-authoritative FootballPlayer setup.
	player.set_multiplayer_authority(1, true)
	player.controls_enabled = true

	var spawn_position: Vector2 = player_data.get(
		"position",
		Vector2.ZERO
	)

	player.position = spawn_position

	print(
		"Created player ",
		peer_id,
		" on peer ",
		multiplayer.get_unique_id(),
		" at ",
		spawn_position
	)

	return player


func spawn_cpu_player(
	cpu_id: int,
	cpu_name: String
) -> FootballPlayer:
	if (
		not multiplayer.is_server()
		or not setup_complete
		or player_spawner == null
		or players_parent == null
		or player_scene == null
		or cpu_id <= MAX_CLIENTS
	):
		return null

	var node_name := str(cpu_id)
	var existing := players_parent.get_node_or_null(
		node_name
	) as FootballPlayer
	if existing != null:
		return existing

	var spawn_data := {
		"peer_id": cpu_id,
		"position": Vector2.ZERO,
		"cpu_controlled": true,
		"display_name": cpu_name.left(32),
		"cosmetic_loadout": _build_random_cpu_cosmetic_loadout(),
	}
	return player_spawner.spawn(spawn_data) as FootballPlayer


func _build_random_cpu_cosmetic_loadout() -> Dictionary:
	var loadout: Dictionary = FootballCosmeticInventory.get_default_network_loadout()
	loadout["player_skin"] = _random_cpu_cosmetic_for_slot(
		FootballCosmeticInventory.SLOT_PLAYER_SKIN,
		str(loadout["player_skin"])
	)
	loadout["player_skin_blue"] = loadout["player_skin"]
	loadout["player_skin_red"] = loadout["player_skin"]
	loadout["frame_palette"] = _random_cpu_cosmetic_for_slot(
		FootballCosmeticInventory.SLOT_FRAME_PALETTE,
		str(loadout["frame_palette"])
	)
	loadout["frame_palette_blue"] = loadout["frame_palette"]
	loadout["frame_palette_red"] = loadout["frame_palette"]
	loadout["player_material"] = _random_cpu_cosmetic_for_slot(
		FootballCosmeticInventory.SLOT_PLAYER_MATERIAL,
		str(loadout["player_material"])
	)
	loadout["player_material_blue"] = loadout["player_material"]
	loadout["player_material_red"] = loadout["player_material"]
	loadout["team_primary_color_blue"] = randi_range(
		0,
		FootballCosmeticInventory.BLUE_TEAM_COLORS.size() - 1
	)
	loadout["team_primary_color_red"] = randi_range(
		0,
		FootballCosmeticInventory.RED_TEAM_COLORS.size() - 1
	)
	loadout["player_skin_color_index"] = randi_range(
		0,
		FootballCosmeticInventory.PLAYER_SKIN_COLORS.size() - 1
	)
	loadout["goal_explosion"] = _random_cpu_cosmetic_for_slot(
		FootballCosmeticInventory.SLOT_GOAL_EXPLOSION,
		str(loadout["goal_explosion"])
	)
	loadout["goal_explosion_blue"] = loadout["goal_explosion"]
	loadout["goal_explosion_red"] = loadout["goal_explosion"]
	loadout["goal_explosion_color_index"] = randi_range(
		0,
		FootballCosmeticInventory.GOAL_EXPLOSION_COLORS.size() - 1
	)
	if randf() < CPU_GOAL_THEME_CHANCE:
		loadout["goal_theme"] = _random_cpu_cosmetic_for_slot(
			FootballCosmeticInventory.SLOT_GOAL_THEME,
			str(loadout["goal_theme"])
		)
	loadout["goal_theme_blue"] = loadout["goal_theme"]
	loadout["goal_theme_red"] = loadout["goal_theme"]
	loadout["player_banner"] = _random_cpu_cosmetic_for_slot(
		FootballCosmeticInventory.SLOT_PLAYER_BANNER,
		str(loadout["player_banner"])
	)
	loadout["player_banner_blue"] = loadout["player_banner"]
	loadout["player_banner_red"] = loadout["player_banner"]
	loadout["player_banner_color_index"] = randi_range(
		0,
		FootballCosmeticInventory.PLAYER_BANNER_COLORS.size() - 1
	)
	loadout["player_banner_color_blue"] = loadout["player_banner_color_index"]
	loadout["player_banner_color_red"] = loadout["player_banner_color_index"]
	loadout["ability_particle"] = _random_cpu_cosmetic_for_slot(
		FootballCosmeticInventory.SLOT_ABILITY_PARTICLE,
		str(loadout["ability_particle"])
	)
	loadout["ability_particle_blue"] = loadout["ability_particle"]
	loadout["ability_particle_red"] = loadout["ability_particle"]
	return FootballCosmeticInventory.sanitize_catalog_network_loadout(loadout)


func _random_cpu_cosmetic_for_slot(
	slot: StringName,
	fallback_id: String
) -> String:
	var candidates: Array[String] = []
	for item_id_variant: Variant in FootballCosmeticInventory.CATALOG.keys():
		var item_id: String = str(item_id_variant)
		var item: Dictionary = FootballCosmeticInventory.CATALOG[item_id] as Dictionary
		if (
			FootballCosmeticInventory.is_catalog_item_obtainable(item)
			and StringName(item.get("slot", &"")) == slot
			and item_id != fallback_id
		):
			candidates.append(item_id)
	if candidates.is_empty():
		return fallback_id
	return candidates[randi_range(0, candidates.size() - 1)]


func spawn_player_for_peer(peer_id: int) -> void:
	if not multiplayer.is_server():
		return

	if not setup_complete:
		push_error(
			"Cannot spawn player because NetworkManager " +
			"setup is incomplete."
		)
		return

	if player_spawner == null:
		push_error("Cannot spawn player: Player Spawner is null.")
		return

	if players_parent == null:
		push_error("Cannot spawn player: Players Parent is null.")
		return

	if player_scene == null:
		push_error("Cannot spawn player: Player Scene is null.")
		return

	var player_name := str(peer_id)

	if players_parent.has_node(player_name):
		print("Player already exists: ", peer_id)
		return

	var spawn_position := Vector2(
		300.0 + players_parent.get_child_count() * 150.0,
		300.0
	)

	var spawn_data := {
		"peer_id": peer_id,
		"position": spawn_position
	}

	print("Server spawning player: ", peer_id)

	var spawned_player := player_spawner.spawn(spawn_data)

	if spawned_player == null:
		push_error(
			"MultiplayerSpawner failed to spawn player %d."
			% peer_id
		)


func _on_remote_player_spawned(node: Node) -> void:
	print(
		"REMOTE PLAYER RECEIVED: ",
		node.name,
		" on peer ",
		multiplayer.get_unique_id()
	)


# ================================================================
# LOCAL ENET
# ================================================================

func start_freeplay() -> bool:
	if not _can_start_connection():
		return false

	current_mode = NetworkMode.FREEPLAY
	spawn_player_for_peer(multiplayer.get_unique_id())
	_register_local_identity()
	# Session UI must transition first. start_freeplay() then emits
	# freeplay_started, which gives the Freeplay HUD final ownership
	# of the screen and hides the normal team lobby.
	_set_session_active(true)

	var match_manager := get_parent().get_node_or_null(
		"MatchManager"
	) as FootballMatchManager
	if match_manager == null or not match_manager.start_freeplay():
		_clear_spawned_players()
		current_mode = NetworkMode.NONE
		connection_changed.emit("Could not start Freeplay")
		_set_session_active(false)
		return false

	connection_changed.emit("Freeplay")
	return true


func start_singleplayer_ranked(team_size: int) -> bool:
	if not _can_start_connection():
		return false
	var match_manager := get_parent().get_node_or_null(
		"MatchManager"
	) as FootballMatchManager
	if match_manager == null:
		connection_changed.emit("Single-player ranked is unavailable")
		return false

	current_mode = NetworkMode.SINGLEPLAYER_RANKED
	spawn_player_for_peer(multiplayer.get_unique_id())
	_register_local_identity()
	if not match_manager.configure_singleplayer_ranked_session(team_size):
		_clear_spawned_players()
		current_mode = NetworkMode.NONE
		connection_changed.emit("Could not create PvE ranked match")
		return false

	connection_changed.emit(
		"PvE Ranked %dv%d • Division %d • %d MMR"
		% [
			team_size,
			team_size,
			match_manager.singleplayer_ranked_division,
			match_manager.singleplayer_ranked_mmr
		]
	)
	_set_session_active(true)
	return true


func host_local() -> bool:
	if not _can_start_connection():
		return false

	var enet_peer := ENetMultiplayerPeer.new()
	var error := enet_peer.create_server(LOCAL_PORT, MAX_CLIENTS)

	if error != OK:
		var message := (
			"Could not host local game on port %d: %s"
			% [LOCAL_PORT, error_string(error)]
		)
		push_error(message)
		connection_changed.emit(message)
		return false

	current_mode = NetworkMode.LOCAL_ENET
	multiplayer.multiplayer_peer = enet_peer
	spawn_player_for_peer(multiplayer.get_unique_id())
	_register_local_identity()
	connection_changed.emit(
		"Local host ready on %s:%d"
		% [LOCAL_ADDRESS, LOCAL_PORT]
	)
	_set_session_active(true)
	return true


func join_local() -> bool:
	if not _can_start_connection():
		return false

	var enet_peer := ENetMultiplayerPeer.new()
	var error := enet_peer.create_client(
		LOCAL_ADDRESS,
		LOCAL_PORT
	)

	if error != OK:
		var message := (
			"Could not connect to %s:%d: %s"
			% [LOCAL_ADDRESS, LOCAL_PORT, error_string(error)]
		)
		push_error(message)
		connection_changed.emit(message)
		return false

	current_mode = NetworkMode.LOCAL_ENET
	multiplayer.multiplayer_peer = enet_peer
	_begin_connection_timeout(
		&"local_peer",
		local_connection_timeout
	)
	connection_changed.emit(
		"Connecting locally to %s:%d..."
		% [LOCAL_ADDRESS, LOCAL_PORT]
	)
	return true


# ================================================================
# STEAM LOBBY BROWSER
# ================================================================

func request_steam_lobbies() -> bool:
	if not _can_use_steam():
		lobby_list_updated.emit([])
		return false

	if searching_lobbies:
		connection_changed.emit("Steam lobby search is already running")
		return false

	searching_lobbies = true
	_lobby_search_deadline_msec = (
		Time.get_ticks_msec()
		+ int(maxf(1.0, steam_lobby_search_timeout) * 1000.0)
	)
	lobby_search_started.emit()
	connection_changed.emit("Searching for public Steam lobbies...")

	# App ID 480 is shared by many projects. Re-applying these filters
	# before every request prevents unrelated Spacewar lobbies from
	# appearing in this game's browser.
	_steam_api().addRequestLobbyListStringFilter(
		"game",
		GAME_ID,
		STEAM_LOBBY_COMPARISON_EQUAL
	)
	_steam_api().addRequestLobbyListStringFilter(
		"protocol",
		str(NETWORK_PROTOCOL_VERSION),
		STEAM_LOBBY_COMPARISON_EQUAL
	)
	_steam_api().addRequestLobbyListStringFilter(
		"browser_key",
		LOBBY_BROWSER_KEY,
		STEAM_LOBBY_COMPARISON_EQUAL
	)
	_steam_api().addRequestLobbyListFilterSlotsAvailable(1)
	_steam_api().addRequestLobbyListDistanceFilter(
		STEAM_LOBBY_DISTANCE_FILTER_WORLDWIDE
	)
	_steam_api().addRequestLobbyListResultCountFilter(50)
	_steam_api().requestLobbyList()
	return true


func _on_steam_lobby_match_list(lobby_ids: Array) -> void:
	if not searching_lobbies:
		return

	searching_lobbies = false
	_lobby_search_deadline_msec = 0

	var results: Array[Dictionary] = []
	for lobby_value in lobby_ids:
		var found_lobby_id := int(lobby_value)
		if found_lobby_id <= 0:
			continue

		var compatibility_error := _get_lobby_compatibility_error(
			found_lobby_id
		)
		if not compatibility_error.is_empty():
			continue

		var state: String = _steam_api().getLobbyData(found_lobby_id, "state")
		if state != "waiting" and state != "playing":
			continue

		var member_count: int = int(_steam_api().getNumLobbyMembers(found_lobby_id))
		var member_limit: int = int(_steam_api().getLobbyMemberLimit(found_lobby_id))
		if member_limit <= 0:
			member_limit = MAX_CLIENTS
		if member_count >= member_limit:
			continue

		var lobby_name: String = str(_steam_api().getLobbyData(found_lobby_id, "name"))
		if lobby_name.strip_edges().is_empty():
			lobby_name = "Steam Lobby"

		var host_name: String = _steam_api().getLobbyData(found_lobby_id, "host")
		var map_name: String = _steam_api().getLobbyData(found_lobby_id, "map")
		var match_minutes_text: String = _steam_api().getLobbyData(
			found_lobby_id, "match_minutes"
		)
		var goals_text: String = _steam_api().getLobbyData(
			found_lobby_id, "goals_to_win"
		)
		var players_text: String = _steam_api().getLobbyData(found_lobby_id, "players")
		var player_slots_text: String = _steam_api().getLobbyData(
			found_lobby_id,
			"player_slots"
		)
		var spectators_text: String = _steam_api().getLobbyData(
			found_lobby_id, "spectators"
		)
		var session_type_text: String = _steam_api().getLobbyData(found_lobby_id, "mode")
		var ranked_size_text: String = _steam_api().getLobbyData(
			found_lobby_id,
			"ranked_team_size"
		)
		results.append({
			"id": found_lobby_id,
			"name": lobby_name.left(48),
			"host": host_name.left(32),
			"members": member_count,
			"max_members": member_limit,
			"state": state,
			"map": map_name if not map_name.is_empty() else "Map 1",
			"match_minutes": int(match_minutes_text) if match_minutes_text.is_valid_int() else 3,
			"goals_to_win": int(goals_text) if goals_text.is_valid_int() else 5,
			"players": int(players_text) if players_text.is_valid_int() else 0,
			"player_slots": (
				int(player_slots_text)
				if player_slots_text.is_valid_int()
				else STEAM_PLAYER_SLOTS
			),
			"spectators": int(spectators_text) if spectators_text.is_valid_int() else 0,
			"mode": session_type_text if not session_type_text.is_empty() else "standard",
			"ranked_team_size": (
				int(ranked_size_text)
				if ranked_size_text.is_valid_int()
				else 2
			),
			"spectator_slots": STEAM_SPECTATOR_SLOTS
		})

	results.sort_custom(_sort_lobby_results)
	connection_changed.emit(
		"Found %d public Steam %s"
		% [
			results.size(),
			"lobby" if results.size() == 1 else "lobbies"
		]
	)
	lobby_list_updated.emit(results)


func _sort_lobby_results(a: Dictionary, b: Dictionary) -> bool:
	var a_state: String = str(a.get("state", "waiting"))
	var b_state: String = str(b.get("state", "waiting"))
	if a_state != b_state:
		return a_state == "waiting"
	var a_members: int = int(a.get("members", 0))
	var b_members: int = int(b.get("members", 0))
	if a_members != b_members:
		return a_members > b_members
	return str(a.get("name", "")).nocasecmp_to(
		str(b.get("name", ""))
	) < 0


# ================================================================
# STEAM HOSTING
# ================================================================

func host_steam(
	custom_lobby_name: String = "",
	lobby_type: int = STEAM_LOBBY_PUBLIC,
	session_type: int = STEAM_SESSION_STANDARD,
	start_ladder_from_beginning: bool = false,
	ranked_team_size: int = 2
) -> bool:
	if not _can_use_steam():
		return false

	if not _can_start_connection():
		return false

	if creating_lobby:
		connection_changed.emit(
			"Steam lobby is already being created"
		)
		return false

	current_mode = NetworkMode.STEAM
	creating_lobby = true
	pending_lobby_name = _sanitize_lobby_name(custom_lobby_name)
	pending_lobby_type = _sanitize_lobby_type(lobby_type)
	pending_session_type = clampi(
		session_type,
		STEAM_SESSION_STANDARD,
		STEAM_SESSION_DRAFT
	)
	pending_ranked_team_size = clampi(ranked_team_size, 2, 6)
	pending_ladder_fresh_start = (
		pending_session_type == STEAM_SESSION_LADDER
		and start_ladder_from_beginning
	)
	_begin_connection_timeout(
		&"steam_create_lobby",
		steam_lobby_callback_timeout
	)
	connection_changed.emit("Creating Steam lobby...")

	_steam_api().createLobby(
		pending_lobby_type,
		(
			pending_ranked_team_size + STEAM_SPECTATOR_SLOTS
			if pending_session_type == STEAM_SESSION_PVE_RANKED
			else STEAM_LOBBY_MEMBER_LIMIT
		)
	)
	return true


# Compatibility with the previous menu/API.
func host_game() -> bool:
	return host_steam()


func _on_steam_lobby_created(
	result: int,
	new_lobby_id: int
) -> void:
	if not creating_lobby or current_mode != NetworkMode.STEAM:
		if new_lobby_id != 0 and steam_available:
			_steam_api().leaveLobby(new_lobby_id)
		return

	creating_lobby = false

	if result != STEAM_RESULT_OK or new_lobby_id == 0:
		_clear_connection_timeout()
		current_mode = NetworkMode.NONE
		var message := (
			"Could not create Steam lobby. Result: %d"
			% result
		)
		push_error(message)
		connection_changed.emit(message)
		return

	lobby_id = new_lobby_id
	current_lobby_type = pending_lobby_type
	current_session_type = pending_session_type
	current_ranked_team_size = pending_ranked_team_size
	var display_name := pending_lobby_name
	if display_name.is_empty():
		display_name = "%s's Lobby" % _steam_api().getPersonaName()
	pending_lobby_name = ""

	_steam_api().setLobbyJoinable(lobby_id, true)
	_steam_api().setLobbyData(
		lobby_id,
		"name",
		display_name
	)
	_steam_api().setLobbyData(lobby_id, "game", GAME_ID)
	_steam_api().setLobbyData(
		lobby_id,
		"protocol",
		str(NETWORK_PROTOCOL_VERSION)
	)
	_steam_api().setLobbyData(lobby_id, "state", "waiting")
	_steam_api().setLobbyData(lobby_id, "browser_key", LOBBY_BROWSER_KEY)
	_steam_api().setLobbyData(lobby_id, "host", _steam_api().getPersonaName())
	_steam_api().setLobbyData(lobby_id, "visibility", _lobby_type_name(current_lobby_type))
	_steam_api().setLobbyData(
		lobby_id,
		"mode",
		_steam_session_mode_name(current_session_type)
	)
	_steam_api().setLobbyData(
		lobby_id,
		"ranked_team_size",
		str(current_ranked_team_size)
	)
	_steam_api().setLobbyData(
		lobby_id,
		"player_slots",
		str(
			current_ranked_team_size
			if current_session_type == STEAM_SESSION_PVE_RANKED
			else STEAM_PLAYER_SLOTS
		)
	)
	_steam_api().setLobbyData(lobby_id, "spectator_slots", str(STEAM_SPECTATOR_SLOTS))
	_queue_lobby_metadata_refresh(true)

	steam_peer = _new_steam_peer()
	var error: Error = steam_peer.create_host(STEAM_VIRTUAL_PORT)

	if error != OK:
		var message := (
			"Could not create Steam host: %s"
			% error_string(error)
		)
		push_error(message)
		_close_current_peer()
		_leave_current_lobby()
		_clear_connection_timeout()
		connection_changed.emit(message)
		return

	multiplayer.multiplayer_peer = steam_peer
	var match_manager := get_parent().get_node_or_null("MatchManager") as FootballMatchManager
	if match_manager != null:
		if current_session_type == STEAM_SESSION_DRAFT:
			match_manager.configure_draft_session(true)
		elif current_session_type == STEAM_SESSION_PVE_RANKED:
			match_manager.configure_draft_session(false)
			match_manager.configure_pve_ranked_session(
				current_ranked_team_size,
				true
			)
		else:
			match_manager.configure_draft_session(false)
			match_manager.configure_ladder_session(
				current_session_type == STEAM_SESSION_LADDER,
				pending_ladder_fresh_start
			)
	pending_ladder_fresh_start = false
	_clear_connection_timeout()

	print("Steam lobby created: ", lobby_id)
	print("Steam host started with Godot peer ID 1.")

	spawn_player_for_peer(1)
	_register_local_identity()
	connection_changed.emit(
		"Steam lobby ready: %d" % lobby_id
	)
	_set_session_active(true)

	if auto_open_invite_overlay or invite_after_lobby_created:
		invite_after_lobby_created = false
		call_deferred("_open_invite_overlay")


func invite_friends() -> bool:
	if not _can_use_steam():
		return false

	if lobby_id != 0:
		if (
			current_mode != NetworkMode.STEAM
			or not multiplayer.is_server()
		):
			connection_changed.emit("Only the Steam host can invite")
			return false

		_open_invite_overlay()
		return true

	if creating_lobby:
		invite_after_lobby_created = true
		connection_changed.emit(
			"Creating Steam lobby; invite window will open..."
		)
		return true

	if not multiplayer.multiplayer_peer is OfflineMultiplayerPeer:
		connection_changed.emit(
			"Disconnect from the local game before hosting Steam"
		)
		return false

	invite_after_lobby_created = true
	return host_steam()


func _open_invite_overlay() -> void:
	if lobby_id == 0:
		connection_changed.emit("Steam lobby is not ready yet")
		return

	if not multiplayer.is_server():
		connection_changed.emit("Only the Steam host can invite")
		return

	_steam_api().activateGameOverlayInviteDialog(lobby_id)
	connection_changed.emit("Steam invite window opened")


# Compatibility for older callers that supplied an IP address.
func join_game(_unused_value: Variant = null) -> bool:
	return join_local()


# ================================================================
# STEAM JOINING
# ================================================================

func join_steam_lobby(target_lobby_id: int) -> bool:
	if not _can_use_steam():
		return false

	if target_lobby_id <= 0:
		connection_changed.emit("Invalid Steam lobby ID")
		return false

	if joining_lobby:
		connection_changed.emit("Already joining a Steam lobby")
		return false

	if (
		creating_lobby
		or lobby_id != 0
		or not multiplayer.multiplayer_peer
		is OfflineMultiplayerPeer
	):
		disconnect_game()

	current_mode = NetworkMode.STEAM
	joining_lobby = true
	_begin_connection_timeout(
		&"steam_join_lobby",
		steam_lobby_callback_timeout
	)
	connection_changed.emit(
		"Joining Steam lobby %d..." % target_lobby_id
	)

	_steam_api().joinLobby(target_lobby_id)
	return true


func _on_steam_join_requested(
	requested_lobby_id: int,
	friend_steam_id: int
) -> void:
	print(
		"Steam invitation accepted from ",
		friend_steam_id,
		" for lobby ",
		requested_lobby_id
	)
	join_steam_lobby(requested_lobby_id)


func _on_steam_lobby_joined(
	joined_lobby_id: int,
	_permissions: int,
	_locked: bool,
	response: int
) -> void:
	if creating_lobby and current_mode == NetworkMode.STEAM:
		# Steam normally sends lobby_created first. If the enter
		# callback arrives early, leave it for lobby_created to finish.
		return

	var is_expected_host_callback: bool = (
		current_mode == NetworkMode.STEAM
		and lobby_id != 0
		and lobby_id == joined_lobby_id
		and _steam_api().getLobbyOwner(joined_lobby_id)
		== _steam_api().getSteamID()
	)
	if not joining_lobby and not is_expected_host_callback:
		if joined_lobby_id != 0 and steam_available:
			_steam_api().leaveLobby(joined_lobby_id)
		return

	joining_lobby = false

	if response != STEAM_LOBBY_ENTER_SUCCESS:
		_clear_connection_timeout()
		current_mode = NetworkMode.NONE
		var message := (
			"Could not enter Steam lobby. Response: %d"
			% response
		)
		push_error(message)
		connection_changed.emit(message)
		return

	var host_steam_id: int = _steam_api().getLobbyOwner(
		joined_lobby_id
	)
	current_session_type = _steam_session_type_from_name(
		_steam_api().getLobbyData(joined_lobby_id, "mode")
	)
	current_lobby_type = _steam_lobby_type_from_visibility_name(
		_steam_api().getLobbyData(joined_lobby_id, "visibility")
	)
	var ranked_size_text: String = _steam_api().getLobbyData(
		joined_lobby_id,
		"ranked_team_size"
	)
	current_ranked_team_size = clampi(
		int(ranked_size_text) if ranked_size_text.is_valid_int() else 2,
		2,
		6
	)

	if host_steam_id == 0:
		push_error("Steam lobby has no valid owner.")
		_steam_api().leaveLobby(joined_lobby_id)
		_clear_connection_timeout()
		current_mode = NetworkMode.NONE
		connection_changed.emit("Could not find Steam lobby host")
		return

	# The lobby owner already created the peer in lobby_created.
	if host_steam_id == _steam_api().getSteamID():
		_clear_connection_timeout()
		print("Host entered own Steam lobby: ", lobby_id)
		return

	var metadata_error := _get_lobby_compatibility_error(
		joined_lobby_id
	)
	if not metadata_error.is_empty():
		_steam_api().leaveLobby(joined_lobby_id)
		_clear_connection_timeout()
		current_mode = NetworkMode.NONE
		connection_changed.emit(metadata_error)
		return

	lobby_id = joined_lobby_id

	steam_peer = _new_steam_peer()
	steam_peer.set_no_nagle(true)
	var error: Error = steam_peer.create_client(
		host_steam_id,
		STEAM_VIRTUAL_PORT
	)

	if error != OK:
		var message := (
			"Could not create Steam client: %s"
			% error_string(error)
		)
		push_error(message)
		_close_current_peer()
		_leave_current_lobby()
		_clear_connection_timeout()
		connection_changed.emit(message)
		return

	multiplayer.multiplayer_peer = steam_peer
	_begin_connection_timeout(
		&"steam_peer",
		steam_peer_connection_timeout
	)

	print("Joined Steam lobby: ", lobby_id)
	print("Connecting to Steam host: ", host_steam_id)
	connection_changed.emit("Connecting through _steam_api()...")


func _try_join_lobby_from_command_line() -> void:
	var arguments := OS.get_cmdline_args()

	for index in range(arguments.size() - 1):
		if arguments[index] != "+connect_lobby":
			continue

		var lobby_argument := arguments[index + 1]

		if not lobby_argument.is_valid_int():
			return

		var requested_lobby_id := int(lobby_argument)

		if requested_lobby_id > 0:
			call_deferred(
				"join_steam_lobby",
				requested_lobby_id
			)
		return


# ================================================================
# DISCONNECTING
# ================================================================

func disconnect_game() -> void:
	var match_manager := get_parent().get_node_or_null(
		"MatchManager"
	) as FootballMatchManager
	if match_manager != null and match_manager.freeplay_active:
		match_manager.stop_freeplay()

	# Steam lobbies survive the host leaving. If we are the current owner and
	# other members remain, explicitly pass ownership before closing the game
	# peer. This gives the clients a deterministic successor instead of making
	# the whole multiplayer party disappear with the old host.
	var handed_off_host: bool = false
	if (
		current_mode == NetworkMode.STEAM
		and lobby_id != 0
		and steam_available
		and _steam_api().getLobbyOwner(lobby_id) == _steam_api().getSteamID()
	):
		handed_off_host = _handoff_steam_lobby_before_local_leave()

	_close_current_peer()
	_leave_current_lobby(not handed_off_host)
	_clear_spawned_players()
	_reset_host_migration_state()

	creating_lobby = false
	joining_lobby = false
	invite_after_lobby_created = false
	pending_lobby_name = ""
	pending_lobby_type = STEAM_LOBBY_PUBLIC
	current_lobby_type = STEAM_LOBBY_PUBLIC
	pending_session_type = STEAM_SESSION_STANDARD
	current_session_type = STEAM_SESSION_STANDARD
	pending_ladder_fresh_start = false
	pending_ranked_team_size = 2
	current_ranked_team_size = 2
	_peer_latency.clear()
	_local_latency_ms = 0
	_local_jitter_ms = 0
	searching_lobbies = false
	_lobby_search_deadline_msec = 0
	_clear_connection_timeout()

	connection_changed.emit("Disconnected")
	_set_session_active(false)


func leave_lobby() -> void:
	disconnect_game()


func _close_current_peer() -> void:
	if not multiplayer.multiplayer_peer is OfflineMultiplayerPeer:
		multiplayer.multiplayer_peer.close()

	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	steam_peer = null
	current_mode = NetworkMode.NONE


func _close_peer_for_host_migration() -> void:
	if not multiplayer.multiplayer_peer is OfflineMultiplayerPeer:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	steam_peer = null
	# We deliberately remain a member of the same Steam lobby while only the
	# Godot game transport is rebuilt around the new owner.
	current_mode = NetworkMode.STEAM


func _leave_current_lobby(close_lobby: bool = true) -> void:
	if lobby_id != 0 and steam_available:
		if (
			close_lobby
			and _steam_api().getLobbyOwner(lobby_id) == _steam_api().getSteamID()
		):
			_steam_api().setLobbyJoinable(lobby_id, false)
		# Every member must leave its Steam lobby, not only the owner.
		_steam_api().leaveLobby(lobby_id)
	lobby_id = 0


func _pick_steam_host_successor() -> int:
	if lobby_id == 0 or not steam_available:
		return 0
	var local_steam_id: int = _steam_api().getSteamID()
	var candidates: Array[int] = []
	var member_count: int = _steam_api().getNumLobbyMembers(lobby_id)
	for index in range(member_count):
		var member_steam_id: int = _steam_api().getLobbyMemberByIndex(lobby_id, index)
		if member_steam_id > 0 and member_steam_id != local_steam_id:
			candidates.append(member_steam_id)
	if candidates.is_empty():
		return 0
	# Deterministic election. Everyone can independently reason about the same
	# order, while the current owner explicitly requests this successor first.
	candidates.sort()
	return candidates[0]


func _handoff_steam_lobby_before_local_leave() -> bool:
	var successor: int = _pick_steam_host_successor()
	if successor <= 0:
		return false
	var transferred: bool = _steam_api().setLobbyOwner(lobby_id, successor)
	if transferred:
		print("Steam lobby host handoff requested: ", _steam_api().getSteamID(), " -> ", successor)
	return transferred


func _capture_local_host_migration_profile() -> Dictionary:
	var local_peer_id: int = multiplayer.get_unique_id()
	for group_name in ["red", "blue", "spectators", "unassigned"]:
		var entries: Array = _latest_roster_snapshot.get(group_name, [])
		for entry_value in entries:
			if not (entry_value is Dictionary):
				continue
			var entry: Dictionary = entry_value
			if bool(entry.get("cpu", false)):
				continue
			if int(entry.get("peer_id", 0)) != local_peer_id:
				continue
			var team_name: String = ""
			match group_name:
				"red":
					team_name = "red"
				"blue":
					team_name = "blue"
				"spectators":
					team_name = "spectator"
				_:
					team_name = ""
			return {
				"team": team_name,
				"ability": int(entry.get("ability", 0)),
				# A host switch deliberately clears READY so a migrated party never
				# launches unexpectedly while clients are still reconnecting.
				"ready": false
			}
	return {"team": "", "ability": 0, "ready": false}


func _start_steam_host_migration() -> void:
	if (
		current_mode != NetworkMode.STEAM
		or lobby_id == 0
		or not steam_available
	):
		_finish_failed_host_migration("Steam host disconnected")
		return
	if _host_migration_pending or _host_migration_reconnect_active:
		return

	_host_migration_local_profile = _capture_local_host_migration_profile()
	var match_manager := get_parent().get_node_or_null(
		"MatchManager"
	) as FootballMatchManager
	_host_migration_was_match_active = (
		match_manager != null and match_manager.game_has_started
	)
	if match_manager != null:
		match_manager.prepare_local_for_network_host_migration()
	_host_migration_old_owner_steam_id = _steam_api().getLobbyOwner(lobby_id)
	_host_migration_target_steam_id = 0
	_host_migration_pending = true
	_host_migration_reconnect_active = false
	_host_migration_deadline_msec = (
		Time.get_ticks_msec() + HOST_MIGRATION_TIMEOUT_MSEC
	)
	_host_migration_next_attempt_msec = Time.get_ticks_msec() + 100
	_clear_connection_timeout()
	_close_peer_for_host_migration()
	_clear_spawned_players()
	_peer_latency.clear()
	connection_changed.emit("Host left • transferring lobby host...")


func _process_host_migration() -> void:
	var now_msec: int = Time.get_ticks_msec()
	if _host_migration_reconnect_active:
		if (
			_host_migration_deadline_msec > 0
			and now_msec >= _host_migration_deadline_msec
		):
			_finish_failed_host_migration("Could not reconnect to the migrated Steam host")
		return
	if not _host_migration_pending:
		return
	if now_msec >= _host_migration_deadline_msec:
		_finish_failed_host_migration("Could not recover the Steam lobby host")
		return
	if now_msec < _host_migration_next_attempt_msec:
		return
	_host_migration_next_attempt_msec = now_msec + HOST_MIGRATION_RETRY_MSEC
	if lobby_id == 0 or not steam_available:
		_finish_failed_host_migration("Steam lobby was lost during host migration")
		return

	var new_owner: int = _steam_api().getLobbyOwner(lobby_id)
	if new_owner <= 0:
		return
	# Steam guarantees a lobby owner while members remain, but the old owner can
	# be visible briefly while LeaveLobby propagation is still in flight.
	if new_owner == _host_migration_old_owner_steam_id:
		return

	_host_migration_target_steam_id = new_owner
	_host_migration_pending = false
	if new_owner == _steam_api().getSteamID():
		_become_migrated_steam_host()
	else:
		_connect_to_migrated_steam_host(new_owner)


func _become_migrated_steam_host() -> void:
	steam_peer = _new_steam_peer()
	var error: Error = steam_peer.create_host(STEAM_VIRTUAL_PORT)
	if error != OK:
		_host_migration_pending = true
		_host_migration_next_attempt_msec = (
			Time.get_ticks_msec() + HOST_MIGRATION_RETRY_MSEC
		)
		steam_peer = null
		return

	multiplayer.multiplayer_peer = steam_peer
	current_mode = NetworkMode.STEAM
	_host_migration_reconnect_active = false
	_clear_connection_timeout()

	var match_manager := get_parent().get_node_or_null(
		"MatchManager"
	) as FootballMatchManager
	if match_manager != null:
		match_manager.prepare_for_network_host_migration(
			_host_migration_was_match_active
		)

	spawn_player_for_peer(multiplayer.get_unique_id())
	_register_local_identity()
	if match_manager != null:
		match_manager.finish_network_host_migration_rebuild()

	_steam_api().setLobbyData(lobby_id, "host", _steam_api().getPersonaName())
	_steam_api().setLobbyData(
		lobby_id,
		"mode",
		_steam_session_mode_name(current_session_type)
	)
	_steam_api().setLobbyData(
		lobby_id,
		"ranked_team_size",
		str(current_ranked_team_size)
	)
	_steam_api().setLobbyType(lobby_id, current_lobby_type)
	_steam_api().setLobbyJoinable(lobby_id, true)
	_queue_lobby_metadata_refresh(true)
	_schedule_host_migration_profile_restore()
	host_changed.emit(_steam_api().getSteamID(), true)
	connection_changed.emit("Host migrated • you are the new lobby host")


func _connect_to_migrated_steam_host(new_owner_steam_id: int) -> void:
	steam_peer = _new_steam_peer()
	steam_peer.set_no_nagle(true)
	var error: Error = steam_peer.create_client(
		new_owner_steam_id,
		STEAM_VIRTUAL_PORT
	)
	if error != OK:
		steam_peer = null
		_host_migration_pending = true
		_host_migration_next_attempt_msec = (
			Time.get_ticks_msec() + HOST_MIGRATION_RETRY_MSEC
		)
		return

	multiplayer.multiplayer_peer = steam_peer
	current_mode = NetworkMode.STEAM
	_host_migration_reconnect_active = true
	host_changed.emit(new_owner_steam_id, false)
	connection_changed.emit("Host migrated • reconnecting to new host...")


func _schedule_host_migration_profile_restore() -> void:
	_host_migration_restore_pending = true
	_host_migration_restore_attempts = 0
	_host_migration_restore_next_msec = Time.get_ticks_msec() + 100


func _process_host_migration_profile_restore() -> void:
	if not _host_migration_restore_pending:
		return
	var now_msec: int = Time.get_ticks_msec()
	if now_msec < _host_migration_restore_next_msec:
		return
	_host_migration_restore_next_msec = (
		now_msec + HOST_MIGRATION_PROFILE_RETRY_MSEC
	)
	_host_migration_restore_attempts += 1
	if _host_migration_restore_attempts > HOST_MIGRATION_PROFILE_MAX_ATTEMPTS:
		_host_migration_restore_pending = false
		return
	if players_parent == null:
		return
	var local_player := players_parent.get_node_or_null(
		str(multiplayer.get_unique_id())
	) as FootballPlayer
	if local_player == null:
		return
	var match_manager := get_parent().get_node_or_null(
		"MatchManager"
	) as FootballMatchManager
	if match_manager == null:
		_host_migration_restore_pending = false
		return

	var desired_team := StringName(
		str(_host_migration_local_profile.get("team", ""))
	)
	# Ladder and PvE Ranked own their team assignment. Custom/standard lobbies
	# restore the player's previous team choice.
	if (
		not match_manager.ladder_mode
		and not match_manager.singleplayer_ranked_mode
		and desired_team != &""
	):
		match_manager.request_join_team(desired_team)
	match_manager.request_select_ability(
		int(_host_migration_local_profile.get("ability", 0))
	)
	# Ready is intentionally reset on migration.
	match_manager.request_set_ready(false)
	_host_migration_restore_pending = false
	_host_migration_local_profile.clear()


func _finish_failed_host_migration(message: String) -> void:
	push_warning(message)
	_close_current_peer()
	_leave_current_lobby(false)
	_clear_spawned_players()
	_reset_host_migration_state()
	connection_changed.emit(message)
	_set_session_active(false)


func _reset_host_migration_state() -> void:
	_host_migration_pending = false
	_host_migration_reconnect_active = false
	_host_migration_deadline_msec = 0
	_host_migration_next_attempt_msec = 0
	_host_migration_old_owner_steam_id = 0
	_host_migration_target_steam_id = 0
	_host_migration_local_profile.clear()
	_host_migration_was_match_active = false
	_host_migration_restore_pending = false
	_host_migration_restore_attempts = 0
	_host_migration_restore_next_msec = 0


func _clear_spawned_players() -> void:
	if players_parent == null:
		return

	for player in players_parent.get_children():
		players_parent.remove_child(player)
		player.queue_free()


func _begin_connection_timeout(
	stage: StringName,
	timeout_seconds: float
) -> void:
	_connection_stage = stage
	_connection_deadline_msec = (
		Time.get_ticks_msec()
		+ int(maxf(1.0, timeout_seconds) * 1000.0)
	)


func _clear_connection_timeout() -> void:
	_connection_stage = &""
	_connection_deadline_msec = 0


func _get_connection_stage_name() -> String:
	match _connection_stage:
		&"local_peer":
			return "local host connection"
		&"steam_create_lobby":
			return "Steam lobby creation"
		&"steam_join_lobby":
			return "Steam lobby entry"
		&"steam_peer":
			return "Steam host connection"
		_:
			return "network setup"


func _fail_pending_connection(message: String) -> void:
	push_error(message)
	creating_lobby = false
	joining_lobby = false
	invite_after_lobby_created = false
	pending_lobby_name = ""
	searching_lobbies = false
	_lobby_search_deadline_msec = 0
	_clear_connection_timeout()
	_close_current_peer()
	_leave_current_lobby()
	_clear_spawned_players()
	_reset_host_migration_state()
	connection_changed.emit(message)
	_set_session_active(false)


func _set_session_active(active: bool) -> void:
	if _session_active == active:
		return
	_session_active = active
	if active:
		session_started.emit()
	else:
		session_ended.emit()


func _get_lobby_compatibility_error(
	target_lobby_id: int
) -> String:
	var lobby_game: String = str(_steam_api().getLobbyData(
		target_lobby_id,
		"game"
	))
	if lobby_game != GAME_ID:
		return "This Steam lobby belongs to a different game."

	var protocol_text: String = str(_steam_api().getLobbyData(
		target_lobby_id,
		"protocol"
	))
	if (
		not protocol_text.is_valid_int()
		or int(protocol_text) != NETWORK_PROTOCOL_VERSION
	):
		return (
			"Host uses an incompatible game build "
			+ "(network protocol mismatch)."
		)
	return ""


func _sanitize_lobby_name(raw_name: String) -> String:
	var cleaned := raw_name.strip_edges()
	cleaned = cleaned.replace("\n", " ")
	cleaned = cleaned.replace("\r", " ")
	cleaned = cleaned.replace("\t", " ")
	while cleaned.contains("  "):
		cleaned = cleaned.replace("  ", " ")
	return cleaned.left(48)


func _on_match_started() -> void:
	_set_host_lobby_state("playing", _steam_lobby_has_open_spectator_slot())
	_queue_lobby_metadata_refresh(true)


func _on_match_ended(_winning_team: StringName) -> void:
	_set_host_lobby_state("waiting", true)
	_queue_lobby_metadata_refresh(true)


func _on_match_cancelled() -> void:
	_set_host_lobby_state("waiting", true)
	_queue_lobby_metadata_refresh(true)


func _set_host_lobby_state(
	state: String,
	joinable: bool
) -> void:
	if (
		lobby_id == 0
		or not steam_available
		or current_mode != NetworkMode.STEAM
		or not multiplayer.is_server()
	):
		return
	_steam_api().setLobbyData(lobby_id, "state", state)
	_steam_api().setLobbyJoinable(lobby_id, joinable)


func _can_start_connection() -> bool:
	if not setup_complete:
		connection_changed.emit("Network setup is incomplete")
		return false

	if (
		creating_lobby
		or joining_lobby
		or _connection_stage != &""
	):
		connection_changed.emit(
			"Another connection attempt is already in progress"
		)
		return false

	if not multiplayer.multiplayer_peer is OfflineMultiplayerPeer:
		push_warning("This window is already connected.")
		connection_changed.emit("Already connected")
		return false

	return true


func _can_use_steam() -> bool:
	if not setup_complete:
		connection_changed.emit("Network setup is incomplete")
		return false

	if not steam_available:
		connection_changed.emit(
			"Steam unavailable; start Steam and relaunch the game"
		)
		return false

	return true


# ================================================================
# MULTIPLAYER SIGNALS
# ================================================================

func _on_peer_connected(peer_id: int) -> void:
	print(
		"Peer connected: ",
		peer_id,
		" seen by peer ",
		multiplayer.get_unique_id()
	)

	if multiplayer.is_server():
		spawn_player_for_peer(peer_id)
		var match_manager := get_parent().get_node_or_null(
			"MatchManager"
		) as FootballMatchManager
		if match_manager != null:
			if match_manager.game_has_started:
				_assign_peer_to_spectator(peer_id, match_manager)
			match_manager.call_deferred(
				"sync_state_to_peer",
				peer_id
			)
		_queue_lobby_metadata_refresh()


func _on_peer_disconnected(peer_id: int) -> void:
	print("Peer disconnected: ", peer_id)

	if not multiplayer.is_server() or players_parent == null:
		return

	var player := players_parent.get_node_or_null(str(peer_id))

	if player != null:
		player.queue_free()
	_peer_latency.erase(peer_id)
	_queue_lobby_metadata_refresh()


func _on_connected_to_server() -> void:
	print(
		"Connected successfully. My Godot peer ID: ",
		multiplayer.get_unique_id()
	)

	_clear_connection_timeout()
	var completed_host_migration: bool = _host_migration_reconnect_active
	if current_mode == NetworkMode.LOCAL_ENET:
		connection_changed.emit("Connected to local host")
	elif completed_host_migration:
		connection_changed.emit("Host migrated • reconnected")
	else:
		connection_changed.emit("Connected to Steam host")

	_register_player_identity.rpc_id(1, _get_local_player_name())
	_register_player_cosmetics.rpc_id(1, _get_local_cosmetic_loadout())
	if completed_host_migration:
		_host_migration_reconnect_active = false
		_schedule_host_migration_profile_restore()
	_set_session_active(true)


func _on_connection_failed() -> void:
	if (
		current_mode == NetworkMode.STEAM
		and lobby_id != 0
		and (_host_migration_reconnect_active or _host_migration_pending)
	):
		print("Host migration reconnect attempt failed; retrying.")
		_close_peer_for_host_migration()
		_host_migration_reconnect_active = false
		_host_migration_pending = true
		_host_migration_next_attempt_msec = (
			Time.get_ticks_msec() + HOST_MIGRATION_RETRY_MSEC
		)
		return

	var failed_mode := current_mode
	push_error("Multiplayer connection failed.")

	_close_current_peer()
	_leave_current_lobby()
	_clear_spawned_players()

	joining_lobby = false
	creating_lobby = false
	pending_lobby_name = ""
	_clear_connection_timeout()

	if failed_mode == NetworkMode.LOCAL_ENET:
		connection_changed.emit(
			"Local connection failed; start Local Host first"
		)
	else:
		connection_changed.emit("Steam connection failed")
	_set_session_active(false)


func _on_server_disconnected() -> void:
	var disconnected_mode := current_mode
	print("Multiplayer host disconnected.")

	# A kick is intentional and must never be interpreted as an election event.
	if not _disconnect_reason_override.is_empty():
		var kick_message: String = _disconnect_reason_override
		_disconnect_reason_override = ""
		_close_current_peer()
		_leave_current_lobby(false)
		_clear_spawned_players()
		_reset_host_migration_state()
		connection_changed.emit(kick_message)
		_set_session_active(false)
		return

	if disconnected_mode == NetworkMode.STEAM and lobby_id != 0:
		if _host_migration_reconnect_active:
			_close_peer_for_host_migration()
			_host_migration_reconnect_active = false
			_host_migration_old_owner_steam_id = _host_migration_target_steam_id
			_host_migration_target_steam_id = 0
			_host_migration_pending = true
			_host_migration_next_attempt_msec = (
				Time.get_ticks_msec() + HOST_MIGRATION_RETRY_MSEC
			)
			connection_changed.emit("New host left • transferring host again...")
		else:
			_start_steam_host_migration()
		return

	_close_current_peer()
	_leave_current_lobby()
	_clear_spawned_players()

	joining_lobby = false
	creating_lobby = false
	pending_lobby_name = ""
	_clear_connection_timeout()

	if disconnected_mode == NetworkMode.LOCAL_ENET:
		connection_changed.emit("Local host disconnected")
	else:
		connection_changed.emit("Host disconnected")
	_set_session_active(false)


# ================================================================
# PLAYER IDENTITIES
# ================================================================

func _get_local_player_name() -> String:
	if steam_available:
		var steam_name: String = str(_steam_api().getPersonaName()).strip_edges()
		if not steam_name.is_empty():
			return steam_name.left(32)

	return _get_fallback_player_name(multiplayer.get_unique_id())


func _get_fallback_player_name(peer_id: int) -> String:
	return "Player %d" % peer_id


func _register_local_identity() -> void:
	if not multiplayer.is_server():
		return

	_set_player_identity(
		multiplayer.get_unique_id(),
		_get_local_player_name()
	)
	_set_player_cosmetics(
		multiplayer.get_unique_id(),
		_get_local_cosmetic_loadout()
	)


@rpc("any_peer", "call_remote", "reliable")
func _register_player_identity(requested_name: String) -> void:
	if not multiplayer.is_server():
		return

	var sender_id := multiplayer.get_remote_sender_id()
	call_deferred(
		"_set_player_identity",
		sender_id,
		requested_name
	)


@rpc("any_peer", "call_remote", "reliable")
func _register_player_cosmetics(requested_loadout: Dictionary) -> void:
	if not multiplayer.is_server():
		return
	var sender_id: int = multiplayer.get_remote_sender_id()
	call_deferred(
		"_set_player_cosmetics",
		sender_id,
		requested_loadout
	)


func _set_player_identity(peer_id: int, requested_name: String) -> void:
	if not multiplayer.is_server() or players_parent == null:
		return

	var player := players_parent.get_node_or_null(
		str(peer_id)
	) as FootballPlayer

	if player == null:
		return

	var safe_name := requested_name.strip_edges().left(32)
	if safe_name.is_empty():
		safe_name = _get_fallback_player_name(peer_id)

	player.display_name = safe_name

	var match_manager := get_parent().get_node_or_null(
		"MatchManager"
	) as FootballMatchManager
	if match_manager != null:
		match_manager.refresh_roster()


func _get_local_cosmetic_loadout() -> Dictionary:
	var inventory := get_node_or_null(
		"/root/CosmeticInventory"
	) as FootballCosmeticInventory
	var loadout: Dictionary = (
		FootballCosmeticInventory.get_default_network_loadout()
		if inventory == null
		else inventory.get_network_loadout()
	)
	var match_manager := get_parent().get_node_or_null(
		"MatchManager"
	) as FootballMatchManager
	loadout["pve_ladder_champion"] = (
		match_manager != null
		and match_manager.has_local_ladder_challenge_completion()
	)
	return loadout


func refresh_local_cosmetic_loadout() -> void:
	if not setup_complete or not _session_active or players_parent == null:
		return
	var loadout: Dictionary = _get_local_cosmetic_loadout()
	print(
		"[LadderChampion] local prestige flag = ",
		bool(loadout.get("pve_ladder_champion", false))
	)
	var local_peer_id: int = multiplayer.get_unique_id()
	if multiplayer.is_server():
		_set_player_cosmetics(local_peer_id, loadout)
	else:
		_register_player_cosmetics.rpc_id(1, loadout)


func _connect_battle_pass_progress() -> void:
	var battle_pass := get_node_or_null("/root/BattlePass") as FootballBattlePass
	if (
		battle_pass != null
		and not battle_pass.progress_changed.is_connected(
			_on_local_battle_pass_progress_changed
		)
	):
		battle_pass.progress_changed.connect(
			_on_local_battle_pass_progress_changed
		)


func _connect_cosmetic_preferences() -> void:
	var inventory := get_node_or_null(
		"/root/CosmeticInventory"
	) as FootballCosmeticInventory
	if inventory == null:
		return
	if not inventory.visual_preferences_changed.is_connected(
		_on_local_cosmetic_preferences_changed
	):
		inventory.visual_preferences_changed.connect(
			_on_local_cosmetic_preferences_changed
		)
	# Locker equips used to update only the local profile file. While already in
	# a lobby, the NetworkManager was never told that the network-visible loadout
	# changed, so goal themes and roster previews stayed stale until rejoining.
	if not inventory.loadout_changed.is_connected(
		_on_local_cosmetic_loadout_changed
	):
		inventory.loadout_changed.connect(
			_on_local_cosmetic_loadout_changed
		)


func _on_local_cosmetic_preferences_changed() -> void:
	refresh_local_cosmetic_loadout()


func _on_local_cosmetic_loadout_changed(
	_slot: StringName,
	_item_id: String
) -> void:
	refresh_local_cosmetic_loadout()


func _on_local_battle_pass_progress_changed(
	_level: int,
	_season_xp: int
) -> void:
	refresh_local_cosmetic_loadout()


func _sanitize_cosmetic_loadout(payload: Dictionary) -> Dictionary:
	var sanitized: Dictionary = (
		FootballCosmeticInventory.sanitize_catalog_network_loadout(payload)
	)
	# Keep PvE Ladder prestige metadata through registration. The central
	# inventory sanitizer also preserves it, but retaining it here makes the
	# network contract explicit and backwards-safe.
	sanitized["pve_ladder_champion"] = bool(
		payload.get("pve_ladder_champion", false)
	)
	return sanitized


func _set_player_cosmetics(peer_id: int, requested_loadout: Dictionary) -> void:
	if not multiplayer.is_server() or players_parent == null:
		return
	var player := players_parent.get_node_or_null(str(peer_id)) as FootballPlayer
	if player == null or player.cpu_controlled:
		return
	player.cosmetic_loadout = _sanitize_cosmetic_loadout(requested_loadout)
	var match_manager := get_parent().get_node_or_null(
		"MatchManager"
	) as FootballMatchManager
	if match_manager != null:
		match_manager.refresh_roster()


# ================================================================
# STEAM LOBBY QUALITY / METADATA / HOST CONTROLS
# ================================================================

func _sanitize_lobby_type(lobby_type: int) -> int:
	if lobby_type == STEAM_LOBBY_PRIVATE:
		return STEAM_LOBBY_PRIVATE
	if lobby_type == STEAM_LOBBY_FRIENDS_ONLY:
		return STEAM_LOBBY_FRIENDS_ONLY
	return STEAM_LOBBY_PUBLIC


func _lobby_type_name(lobby_type: int) -> String:
	match _sanitize_lobby_type(lobby_type):
		STEAM_LOBBY_PRIVATE:
			return "Private"
		STEAM_LOBBY_FRIENDS_ONLY:
			return "Friends Only"
		_:
			return "Public"


func _steam_lobby_type_from_visibility_name(value: String) -> int:
	match value.strip_edges().to_lower():
		"private":
			return STEAM_LOBBY_PRIVATE
		"friends", "friends only", "friends-only":
			return STEAM_LOBBY_FRIENDS_ONLY
		_:
			return STEAM_LOBBY_PUBLIC


func _steam_session_mode_name(session_type: int) -> String:
	match session_type:
		STEAM_SESSION_LADDER:
			return "ladder"
		STEAM_SESSION_PVE_RANKED:
			return "pve_ranked"
		STEAM_SESSION_DRAFT:
			return "draft"
		_:
			return "standard"


func _steam_session_type_from_name(mode_name: String) -> int:
	match mode_name:
		"ladder":
			return STEAM_SESSION_LADDER
		"pve_ranked":
			return STEAM_SESSION_PVE_RANKED
		"draft":
			return STEAM_SESSION_DRAFT
		_:
			return STEAM_SESSION_STANDARD


func set_lobby_visibility(lobby_type: int) -> bool:
	if (
		lobby_id == 0
		or current_mode != NetworkMode.STEAM
		or not multiplayer.is_server()
		or not steam_available
	):
		return false
	current_lobby_type = _sanitize_lobby_type(lobby_type)
	_steam_api().setLobbyType(lobby_id, current_lobby_type)
	_steam_api().setLobbyData(
		lobby_id,
		"visibility",
		_lobby_type_name(current_lobby_type)
	)
	lobby_metadata_changed.emit(get_current_lobby_summary())
	return true


func get_current_lobby_summary() -> Dictionary:
	if lobby_id == 0 or not steam_available:
		return {}
	var result: Dictionary = {
		"id": lobby_id,
		"name": _steam_api().getLobbyData(lobby_id, "name"),
		"host": _steam_api().getLobbyData(lobby_id, "host"),
		"state": _steam_api().getLobbyData(lobby_id, "state"),
		"mode": _steam_api().getLobbyData(lobby_id, "mode"),
		"ranked_team_size": int(
			_steam_api().getLobbyData(lobby_id, "ranked_team_size")
		),
		"ladder_rung": int(_steam_api().getLobbyData(lobby_id, "ladder_rung")),
		"visibility": _steam_api().getLobbyData(lobby_id, "visibility"),
		"map": _steam_api().getLobbyData(lobby_id, "map"),
		"members": _steam_api().getNumLobbyMembers(lobby_id),
		"max_members": _steam_api().getLobbyMemberLimit(lobby_id),
		"players": int(_steam_api().getLobbyData(lobby_id, "players")),
		"spectators": int(_steam_api().getLobbyData(lobby_id, "spectators")),
		"player_slots": int(_steam_api().getLobbyData(lobby_id, "player_slots")),
		"spectator_slots": STEAM_SPECTATOR_SLOTS
	}
	var minutes_text: String = _steam_api().getLobbyData(lobby_id, "match_minutes")
	var goals_text: String = _steam_api().getLobbyData(lobby_id, "goals_to_win")
	result["match_minutes"] = (
		int(minutes_text) if minutes_text.is_valid_int() else 0
	)
	result["goals_to_win"] = (
		int(goals_text) if goals_text.is_valid_int() else 0
	)
	return result


func get_latency_snapshot() -> Dictionary:
	return _peer_latency.duplicate(true)


func get_peer_latency_ms(peer_id: int) -> int:
	var entry: Dictionary = _peer_latency.get(peer_id, {})
	return int(entry.get("ping", 0))


func kick_peer(peer_id: int) -> bool:
	if (
		not multiplayer.is_server()
		or peer_id <= 0
		or peer_id == multiplayer.get_unique_id()
		or multiplayer.multiplayer_peer is OfflineMultiplayerPeer
	):
		return false
	_receive_kick_notice.rpc_id(peer_id, "Removed from the Steam lobby by the host.")
	call_deferred("_disconnect_kicked_peer", peer_id)
	return true


func _disconnect_kicked_peer(peer_id: int) -> void:
	if not multiplayer.is_server():
		return
	if multiplayer.multiplayer_peer is OfflineMultiplayerPeer:
		return
	multiplayer.multiplayer_peer.disconnect_peer(peer_id, false)


@rpc("authority", "call_remote", "reliable")
func _receive_kick_notice(message: String) -> void:
	_disconnect_reason_override = message.left(96)


func _assign_peer_to_spectator(
	peer_id: int,
	match_manager: FootballMatchManager
) -> void:
	if players_parent == null:
		return
	var player := players_parent.get_node_or_null(str(peer_id)) as FootballPlayer
	if player == null:
		return
	match_manager.join_team(player, FootballMatchManager.TEAM_SPECTATOR)


func _on_match_settings_metadata_changed(
	_seconds: float,
	_goals: int
) -> void:
	_queue_lobby_metadata_refresh()


func _on_field_variant_metadata_changed(_variant_index: int) -> void:
	_queue_lobby_metadata_refresh()


func _on_roster_metadata_changed(roster: Dictionary) -> void:
	_latest_roster_snapshot = roster.duplicate(true)
	_queue_lobby_metadata_refresh()


func _queue_lobby_metadata_refresh(immediate: bool = false) -> void:
	if (
		lobby_id == 0
		or current_mode != NetworkMode.STEAM
		or not multiplayer.is_server()
		or not steam_available
	):
		return
	_lobby_metadata_dirty = true
	_lobby_metadata_due_msec = (
		Time.get_ticks_msec()
		if immediate
		else Time.get_ticks_msec() + LOBBY_METADATA_DEBOUNCE_MSEC
	)


func _process_lobby_metadata_refresh() -> void:
	if not _lobby_metadata_dirty:
		return
	if Time.get_ticks_msec() < _lobby_metadata_due_msec:
		return
	_lobby_metadata_dirty = false
	_refresh_host_lobby_metadata_now()


func _refresh_host_lobby_metadata_now() -> void:
	if (
		lobby_id == 0
		or current_mode != NetworkMode.STEAM
		or not multiplayer.is_server()
		or not steam_available
	):
		return
	var match_manager := get_parent().get_node_or_null(
		"MatchManager"
	) as FootballMatchManager
	if match_manager == null:
		return

	var roster: Dictionary = _latest_roster_snapshot
	var human_players: int = 0
	var spectators: int = 0
	var ready_players: int = 0
	for team_key in ["red", "blue"]:
		var entries: Array = roster.get(team_key, [])
		for entry_value in entries:
			if not (entry_value is Dictionary):
				continue
			var entry: Dictionary = entry_value
			if bool(entry.get("cpu", false)):
				continue
			human_players += 1
			if bool(entry.get("ready", false)):
				ready_players += 1
	for entry_value in roster.get("spectators", []):
		if entry_value is Dictionary and not bool(entry_value.get("cpu", false)):
			spectators += 1

	var state: String = "playing" if match_manager.game_has_started else "waiting"
	_steam_api().setLobbyData(lobby_id, "host", _steam_api().getPersonaName())
	_steam_api().setLobbyData(lobby_id, "state", state)
	_steam_api().setLobbyData(lobby_id, "map", "Map %d" % (match_manager.current_field_variant + 1))
	_steam_api().setLobbyData(
		lobby_id,
		"match_minutes",
		str(maxi(1, int(round(match_manager.regulation_seconds / 60.0))))
	)
	_steam_api().setLobbyData(lobby_id, "goals_to_win", str(match_manager.goals_to_win))
	_steam_api().setLobbyData(lobby_id, "players", str(human_players))
	_steam_api().setLobbyData(lobby_id, "spectators", str(spectators))
	_steam_api().setLobbyData(lobby_id, "ready", str(ready_players))
	_steam_api().setLobbyData(lobby_id, "visibility", _lobby_type_name(current_lobby_type))
	_steam_api().setLobbyData(
		lobby_id,
		"mode",
		_steam_session_mode_name(current_session_type)
	)
	_steam_api().setLobbyData(
		lobby_id,
		"ranked_team_size",
		str(current_ranked_team_size)
	)
	_steam_api().setLobbyData(
		lobby_id,
		"ladder_rung",
		str(match_manager.ladder_rung if match_manager.ladder_mode else 0)
	)
	_steam_api().setLobbyJoinable(
		lobby_id,
		not match_manager.game_has_started
		or spectators < STEAM_SPECTATOR_SLOTS
	)
	lobby_metadata_changed.emit(get_current_lobby_summary())


func _steam_lobby_has_open_spectator_slot() -> bool:
	var spectators: int = 0
	for entry_value in _latest_roster_snapshot.get("spectators", []):
		if entry_value is Dictionary and not bool(entry_value.get("cpu", false)):
			spectators += 1
	return spectators < STEAM_SPECTATOR_SLOTS


func _process_latency_monitor() -> void:
	if not _session_active or current_mode != NetworkMode.STEAM:
		return
	if multiplayer.multiplayer_peer is OfflineMultiplayerPeer:
		return
	var now_msec: int = Time.get_ticks_msec()
	if multiplayer.is_server():
		_peer_latency[multiplayer.get_unique_id()] = {"ping": 0, "jitter": 0}
		if now_msec >= _next_latency_snapshot_msec:
			_next_latency_snapshot_msec = now_msec + LATENCY_SNAPSHOT_INTERVAL_MSEC
			_receive_latency_snapshot.rpc(_peer_latency.duplicate(true))
		return
	if now_msec < _next_latency_probe_msec:
		return
	_next_latency_probe_msec = now_msec + LATENCY_PROBE_INTERVAL_MSEC
	_ping_sequence += 1
	_ping_server.rpc_id(1, _ping_sequence, Time.get_ticks_usec())


@rpc("any_peer", "call_remote", "unreliable")
func _ping_server(sequence: int, sent_usec: int) -> void:
	if not multiplayer.is_server():
		return
	var sender_id: int = multiplayer.get_remote_sender_id()
	_pong_client.rpc_id(sender_id, sequence, sent_usec)


@rpc("authority", "call_remote", "unreliable")
func _pong_client(_sequence: int, sent_usec: int) -> void:
	if multiplayer.is_server():
		return
	var rtt_usec: int = maxi(0, Time.get_ticks_usec() - sent_usec)
	var sample_ms: int = clampi(int(round(float(rtt_usec) / 1000.0)), 0, 2000)
	var previous_ms: int = _local_latency_ms
	_local_latency_ms = sample_ms
	_local_jitter_ms = (
		abs(sample_ms - previous_ms)
		if previous_ms > 0
		else 0
	)
	_report_latency.rpc_id(1, _local_latency_ms, _local_jitter_ms)


@rpc("any_peer", "call_remote", "unreliable")
func _report_latency(ping_ms: int, jitter_ms: int) -> void:
	if not multiplayer.is_server():
		return
	var sender_id: int = multiplayer.get_remote_sender_id()
	_peer_latency[sender_id] = {
		"ping": clampi(ping_ms, 0, 2000),
		"jitter": clampi(jitter_ms, 0, 2000)
	}


@rpc("authority", "call_local", "unreliable")
func _receive_latency_snapshot(snapshot: Dictionary) -> void:
	_peer_latency = snapshot.duplicate(true)
	latency_snapshot_updated.emit(_peer_latency.duplicate(true))
