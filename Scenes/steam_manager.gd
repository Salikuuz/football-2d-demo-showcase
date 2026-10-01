extends Node


const DEFAULT_STEAM_APP_ID: int = 480
# GodotSteam enum values mirrored as integers so the script remains parseable
# when the Web export intentionally omits the Steam GDExtension.
const STEAM_LEADERBOARD_DATA_REQUEST_GLOBAL: int = 0
const STEAM_LEADERBOARD_DISPLAY_TYPE_NUMERIC: int = 1
const STEAM_LEADERBOARD_SORT_METHOD_DESCENDING: int = 2
const GLOBAL_LEADERBOARD_PVE_MMR: StringName = &"pve_mmr"
const GLOBAL_LEADERBOARD_GOALS: StringName = &"goals"
const GLOBAL_LEADERBOARD_SAVES: StringName = &"saves"
const GLOBAL_LEADERBOARD_LIMIT: int = 100
const GLOBAL_LEADERBOARD_NAMES: Dictionary = {
	GLOBAL_LEADERBOARD_PVE_MMR: "THEODOREBALL_PVE_MMR_V1",
	GLOBAL_LEADERBOARD_GOALS: "THEODOREBALL_CAREER_GOALS_V1",
	GLOBAL_LEADERBOARD_SAVES: "THEODOREBALL_CAREER_SAVES_V1",
}

signal global_leaderboard_changed(
	category: StringName,
	entries: Array,
	status: String
)

var steam_initialized: bool = false
var steam_app_id: int = DEFAULT_STEAM_APP_ID
var _global_leaderboard_handles: Dictionary = {}
var _global_handle_categories: Dictionary = {}
var _global_find_queue: Array[StringName] = []
var _global_find_active: StringName = &""
var _global_requested_downloads: Dictionary = {}
var _global_local_scores: Dictionary = {
	GLOBAL_LEADERBOARD_PVE_MMR: 0,
	GLOBAL_LEADERBOARD_GOALS: 0,
	GLOBAL_LEADERBOARD_SAVES: 0,
}
var _global_entries: Dictionary = {
	GLOBAL_LEADERBOARD_PVE_MMR: [],
	GLOBAL_LEADERBOARD_GOALS: [],
	GLOBAL_LEADERBOARD_SAVES: [],
}
var _global_status: Dictionary = {
	GLOBAL_LEADERBOARD_PVE_MMR: "STEAM OFFLINE",
	GLOBAL_LEADERBOARD_GOALS: "STEAM OFFLINE",
	GLOBAL_LEADERBOARD_SAVES: "STEAM OFFLINE",
}


func _steam_api() -> Object:
	if not Engine.has_singleton("Steam"):
		return null
	return Engine.get_singleton("Steam")


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if OS.has_environment("THEODORE_RL_V2_HEADLESS"):
		set_process(false)
		return
	if OS.has_feature("web"):
		# Steam/GodotSteam is intentionally a desktop-only backend. The mobile Web
		# build stays fully usable for offline/freeplay/PvE while multiplayer is
		# implemented separately later, without logging a fake startup error.
		_global_status[GLOBAL_LEADERBOARD_PVE_MMR] = "MOBILE WEB"
		_global_status[GLOBAL_LEADERBOARD_GOALS] = "MOBILE WEB"
		_global_status[GLOBAL_LEADERBOARD_SAVES] = "MOBILE WEB"
		set_process(false)
		return
	steam_app_id = int(
		ProjectSettings.get_setting(
			"steam/app_id",
			DEFAULT_STEAM_APP_ID
		)
	)
	# Steam uses these when the development build is launched outside
	# the Steam client or from a terminal on Linux.
	OS.set_environment("SteamAppId", str(steam_app_id))
	OS.set_environment("SteamGameId", str(steam_app_id))

	if not Engine.has_singleton("Steam"):
		push_error("GodotSteam was not found.")
		return

	if not _steam_api().isSteamRunning():
		push_error("Steam is not running.")
		return

	var result: Dictionary = _steam_api().steamInitEx(
		steam_app_id,
		false
	)
	print(
		"Steam: ",
		Engine.has_singleton("Steam")
	)

	print(
		"SteamMultiplayerPeer: ",
		ClassDB.class_exists("SteamMultiplayerPeer")
	)
	print("Steam initialization: ", result)

	if int(result.get("status", -1)) != 0:
		push_error(
			"Steam initialization failed: %s"
			% result.get("verbal", "Unknown error")
		)
		return

	steam_initialized = true
	_connect_global_leaderboard_signals()

	print("Steam successfully initialized.")
	print("Steam App ID: ", steam_app_id)
	print("Steam name: ", _steam_api().getPersonaName())
	print("Steam ID: ", _steam_api().getSteamID())
	print("Steam vorhanden: ",Engine.has_singleton("Steam"))
	print("SteamMultiplayerPeer vorhanden: ",ClassDB.class_exists("SteamMultiplayerPeer"))

func _process(_delta: float) -> void:
	if steam_initialized:
		_steam_api().run_callbacks()


func is_global_leaderboard_available() -> bool:
	return (
		steam_initialized
		and Engine.has_singleton("Steam")
		and _steam_api().getSteamID() != 0
	)


func sync_career_leaderboards(goals: int, saves: int, pve_mmr: int = 0) -> void:
	_global_local_scores[GLOBAL_LEADERBOARD_PVE_MMR] = maxi(0, pve_mmr)
	_global_local_scores[GLOBAL_LEADERBOARD_GOALS] = maxi(0, goals)
	_global_local_scores[GLOBAL_LEADERBOARD_SAVES] = maxi(0, saves)
	if not is_global_leaderboard_available():
		_emit_offline_fallback(GLOBAL_LEADERBOARD_PVE_MMR)
		_emit_offline_fallback(GLOBAL_LEADERBOARD_GOALS)
		_emit_offline_fallback(GLOBAL_LEADERBOARD_SAVES)
		return
	_ensure_global_leaderboard(GLOBAL_LEADERBOARD_PVE_MMR)
	_ensure_global_leaderboard(GLOBAL_LEADERBOARD_GOALS)
	_ensure_global_leaderboard(GLOBAL_LEADERBOARD_SAVES)
	_upload_global_score_if_ready(GLOBAL_LEADERBOARD_PVE_MMR)
	_upload_global_score_if_ready(GLOBAL_LEADERBOARD_GOALS)
	_upload_global_score_if_ready(GLOBAL_LEADERBOARD_SAVES)


func request_global_leaderboard(category: StringName) -> void:
	var safe_category: StringName = _sanitize_global_category(category)
	if safe_category == &"":
		return
	if not is_global_leaderboard_available():
		_emit_offline_fallback(safe_category)
		return
	_global_requested_downloads[safe_category] = true
	_set_global_status(safe_category, "LOADING GLOBAL RANKINGS...")
	var handle: int = int(_global_leaderboard_handles.get(safe_category, 0))
	if handle > 0:
		_download_global_entries(safe_category, handle)
	else:
		_ensure_global_leaderboard(safe_category)


func get_global_leaderboard_entries(category: StringName) -> Array:
	var safe_category: StringName = _sanitize_global_category(category)
	return (_global_entries.get(safe_category, []) as Array).duplicate(true)


func get_global_leaderboard_status(category: StringName) -> String:
	var safe_category: StringName = _sanitize_global_category(category)
	return str(_global_status.get(safe_category, "STEAM OFFLINE"))


func _connect_global_leaderboard_signals() -> void:
	if not Engine.has_singleton("Steam"):
		return
	if not _steam_api().leaderboard_find_result.is_connected(
		_on_global_leaderboard_find_result
	):
		_steam_api().leaderboard_find_result.connect(
			_on_global_leaderboard_find_result
		)
	if not _steam_api().leaderboard_score_uploaded.is_connected(
		_on_global_leaderboard_score_uploaded
	):
		_steam_api().leaderboard_score_uploaded.connect(
			_on_global_leaderboard_score_uploaded
		)
	if not _steam_api().leaderboard_scores_downloaded.is_connected(
		_on_global_leaderboard_scores_downloaded
	):
		_steam_api().leaderboard_scores_downloaded.connect(
			_on_global_leaderboard_scores_downloaded
		)
	if not _steam_api().persona_state_change.is_connected(
		_on_global_persona_state_change
	):
		_steam_api().persona_state_change.connect(_on_global_persona_state_change)


func _sanitize_global_category(category: StringName) -> StringName:
	return category if GLOBAL_LEADERBOARD_NAMES.has(category) else &""


func _ensure_global_leaderboard(category: StringName) -> void:
	if (
		not is_global_leaderboard_available()
		or _global_leaderboard_handles.has(category)
		or _global_find_active == category
		or _global_find_queue.has(category)
	):
		return
	_global_find_queue.append(category)
	_pump_global_find_queue()


func _pump_global_find_queue() -> void:
	if (
		not is_global_leaderboard_available()
		or _global_find_active != &""
		or _global_find_queue.is_empty()
	):
		return
	_global_find_active = _global_find_queue.pop_front()
	_set_global_status(_global_find_active, "CONNECTING TO STEAM...")
	_steam_api().findOrCreateLeaderboard(
		str(GLOBAL_LEADERBOARD_NAMES[_global_find_active]),
		STEAM_LEADERBOARD_SORT_METHOD_DESCENDING,
		STEAM_LEADERBOARD_DISPLAY_TYPE_NUMERIC
	)


func _on_global_leaderboard_find_result(
	leaderboard_handle: int,
	found: int
) -> void:
	var category: StringName = _global_find_active
	_global_find_active = &""
	if category == &"":
		_pump_global_find_queue()
		return
	if found != 0 and leaderboard_handle > 0:
		_global_leaderboard_handles[category] = leaderboard_handle
		_global_handle_categories[leaderboard_handle] = category
		_set_global_status(category, "SYNCING YOUR SCORE...")
		_upload_global_score_if_ready(category)
		if bool(_global_requested_downloads.get(category, false)):
			_download_global_entries(category, leaderboard_handle)
	else:
		_set_global_status(category, "GLOBAL LEADERBOARD UNAVAILABLE")
	_pump_global_find_queue()


func _upload_global_score_if_ready(category: StringName) -> void:
	if not is_global_leaderboard_available():
		return
	var handle: int = int(_global_leaderboard_handles.get(category, 0))
	if handle <= 0:
		return
	# Uploading zero deliberately registers a new Steam player even before their
	# first goal/save. Keep-best prevents stale local files from lowering a score.
	_steam_api().uploadLeaderboardScore(
		maxi(0, int(_global_local_scores.get(category, 0))),
		category != GLOBAL_LEADERBOARD_PVE_MMR,
		PackedInt32Array(),
		handle
	)


func _on_global_leaderboard_score_uploaded(
	success: bool,
	leaderboard_handle: int,
	_score_result: Dictionary
) -> void:
	var category: StringName = StringName(
		_global_handle_categories.get(leaderboard_handle, &"")
	)
	if category == &"":
		return
	if not success:
		_set_global_status(category, "SCORE SYNC FAILED • RETRY AVAILABLE")
		return
	if bool(_global_requested_downloads.get(category, false)):
		_download_global_entries(category, leaderboard_handle)
	else:
		_set_global_status(category, "SCORE SYNCED")


func _download_global_entries(category: StringName, handle: int) -> void:
	if handle <= 0 or not is_global_leaderboard_available():
		return
	_set_global_status(category, "LOADING GLOBAL RANKINGS...")
	_steam_api().downloadLeaderboardEntries(
		1,
		GLOBAL_LEADERBOARD_LIMIT,
		STEAM_LEADERBOARD_DATA_REQUEST_GLOBAL,
		handle
	)


func _on_global_leaderboard_scores_downloaded(
	message: String,
	leaderboard_handle: int,
	leaderboard_entries: Array
) -> void:
	var category: StringName = StringName(
		_global_handle_categories.get(leaderboard_handle, &"")
	)
	if category == &"":
		return
	if not message.to_lower().contains("success") and leaderboard_entries.is_empty():
		_set_global_status(category, "NO GLOBAL SCORES YET")
		_global_entries[category] = []
		return
	var normalized_entries: Array = []
	for index: int in range(leaderboard_entries.size()):
		var raw_entry: Dictionary = leaderboard_entries[index] as Dictionary
		var steam_id: int = int(raw_entry.get(
			"steam_id",
			raw_entry.get("steamID", raw_entry.get("user_id", 0))
		))
		var player_name: String = str(raw_entry.get("name", "")).strip_edges()
		if steam_id > 0 and player_name == "":
			player_name = _steam_api().getFriendPersonaName(steam_id).strip_edges()
		if player_name == "" or player_name.to_lower().contains("unknown"):
			player_name = _anonymous_steam_name(steam_id)
			if steam_id > 0:
				_steam_api().requestUserInformation(steam_id, true)
		normalized_entries.append({
			"rank": int(raw_entry.get(
				"global_rank",
				raw_entry.get("rank", index + 1)
			)),
			"steam_id": steam_id,
			"name": player_name,
			"score": maxi(0, int(raw_entry.get("score", 0))),
		})
	_global_entries[category] = normalized_entries
	_global_requested_downloads[category] = false
	_set_global_status(
		category,
		"GLOBAL • %d PLAYERS SHOWN" % normalized_entries.size()
	)


func _on_global_persona_state_change(steam_id: int, _flags: int) -> void:
	if steam_id <= 0 or not is_global_leaderboard_available():
		return
	var refreshed_name: String = _steam_api().getFriendPersonaName(steam_id).strip_edges()
	if refreshed_name == "" or refreshed_name.to_lower().contains("unknown"):
		return
	for category: StringName in [
		GLOBAL_LEADERBOARD_PVE_MMR,
		GLOBAL_LEADERBOARD_GOALS,
		GLOBAL_LEADERBOARD_SAVES,
	]:
		var entries: Array = _global_entries.get(category, []) as Array
		var changed: bool = false
		for entry: Dictionary in entries:
			if int(entry.get("steam_id", 0)) == steam_id:
				entry["name"] = refreshed_name
				changed = true
		if changed:
			global_leaderboard_changed.emit(
				category,
				entries.duplicate(true),
				str(_global_status.get(category, "GLOBAL"))
			)


func _anonymous_steam_name(steam_id: int) -> String:
	if steam_id <= 0:
		return "STEAM PLAYER"
	var id_text: String = str(steam_id)
	return "STEAM PLAYER • %s" % id_text.right(4)


func _set_global_status(category: StringName, status: String) -> void:
	_global_status[category] = status
	global_leaderboard_changed.emit(
		category,
		(_global_entries.get(category, []) as Array).duplicate(true),
		status
	)


func _emit_offline_fallback(category: StringName) -> void:
	var local_name: String = "LOCAL PLAYER"
	var local_steam_id: int = 0
	if Engine.has_singleton("Steam") and steam_initialized:
		local_steam_id = _steam_api().getSteamID()
		var steam_name: String = _steam_api().getPersonaName().strip_edges()
		if steam_name != "":
			local_name = steam_name
	var entries: Array = [{
		"rank": 1,
		"steam_id": local_steam_id,
		"name": local_name,
		"score": maxi(0, int(_global_local_scores.get(category, 0))),
		"local_only": true,
	}]
	_global_entries[category] = entries
	_global_status[category] = "STEAM OFFLINE • SHOWING LOCAL TOTAL"
	global_leaderboard_changed.emit(
		category,
		entries.duplicate(true),
		str(_global_status[category])
	)
