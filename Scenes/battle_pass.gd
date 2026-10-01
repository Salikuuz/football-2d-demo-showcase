class_name FootballBattlePass
extends Node


signal progress_changed(level: int, season_xp: int)
signal reward_claimed(tier: int, item_id: String)
signal lootbox_opened(lootbox_number: int, item_id: String)
signal match_xp_awarded(
	earned_xp: int,
	previous_xp: int,
	current_xp: int,
	previous_level: int,
	current_level: int,
	previous_lootboxes: int,
	current_lootboxes: int
)
# Compatibility signal for the short-lived Case Vault build.
signal case_opened(case_number: int, item_id: String)

const SCHEMA_VERSION: int = 4
const SEASON_ID: String = "season_01_first_touch"
const LEGACY_SEASON_IDS: Array[String] = ["preseason_andromeda"]
const SAVE_PATH: String = "user://battle_pass.cfg"
const XP_PER_TIER: int = 500
const LEGACY_MAX_TIER: int = 50
const FULL_XP_MATCH_SECONDS: float = 600.0
const WIN_XP_MULTIPLIER: float = 1.5

# Kept only to migrate the original fixed-tier save format. New progression
# uses every non-default catalog cosmetic as a unique lootbox drop.
const LEGACY_REWARDS: Array[Dictionary] = [
	{"tier": 1, "item_id": "player_banner.kickoff"},
	{"tier": 2, "item_id": "quick_chat.locked_in"},
	{"tier": 3, "item_id": "player_skin.street_striker"},
	{"tier": 4, "item_id": "player_banner.blueprint"},
	{"tier": 5, "item_id": "goal_explosion.goal_rush"},
	{"tier": 6, "item_id": "quick_chat.calculated"},
	{"tier": 7, "item_id": "player_skin.frostline"},
	{"tier": 8, "item_id": "player_banner.clean_sheet"},
	{"tier": 9, "item_id": "goal_explosion.confetti_cup"},
	{"tier": 10, "item_id": "player_skin.royal_guard"},
	{"tier": 11, "item_id": "quick_chat.wall_play"},
	{"tier": 12, "item_id": "player_banner.night_match"},
	{"tier": 13, "item_id": "player_skin.ember"},
	{"tier": 14, "item_id": "goal_explosion.ember_burst"},
	{"tier": 15, "item_id": "quick_chat.one_more"},
	{"tier": 16, "item_id": "player_banner.captain"},
	{"tier": 17, "item_id": "player_skin.neon_pitch"},
	{"tier": 18, "item_id": "goal_explosion.electric_net"},
	{"tier": 19, "item_id": "quick_chat.my_ball"},
	{"tier": 20, "item_id": "player_skin.shadow_play"},
	{"tier": 21, "item_id": "player_banner.golden_boot"},
	{"tier": 22, "item_id": "quick_chat.play_wide"},
	{"tier": 23, "item_id": "player_skin.aerial_ace"},
	{"tier": 24, "item_id": "goal_explosion.cyclone"},
	{"tier": 25, "item_id": "player_banner.frozen_final"},
	{"tier": 26, "item_id": "quick_chat.switch"},
	{"tier": 27, "item_id": "player_skin.crimson_press"},
	{"tier": 28, "item_id": "goal_explosion.pixel_break"},
	{"tier": 29, "item_id": "player_banner.tactical_board"},
	{"tier": 30, "item_id": "player_skin.chrome_touch"},
	{"tier": 31, "item_id": "quick_chat.center_it"},
	{"tier": 32, "item_id": "goal_explosion.crown_burst"},
	{"tier": 33, "item_id": "player_banner.striker"},
	{"tier": 34, "item_id": "player_skin.mint_control"},
	{"tier": 35, "item_id": "quick_chat.hold_line"},
	{"tier": 36, "item_id": "goal_explosion.ice_breaker"},
	{"tier": 37, "item_id": "player_banner.finals"},
	{"tier": 38, "item_id": "player_skin.sunset_playmaker"},
	{"tier": 39, "item_id": "quick_chat.counter"},
	{"tier": 40, "item_id": "goal_explosion.comet_strike"},
	{"tier": 41, "item_id": "player_banner.elite"},
	{"tier": 42, "item_id": "player_skin.obsidian_wall"},
	{"tier": 43, "item_id": "quick_chat.clutch"},
	{"tier": 44, "item_id": "goal_explosion.trophy_lift"},
	{"tier": 45, "item_id": "player_banner.champion"},
	{"tier": 46, "item_id": "player_skin.golden_touch"},
	{"tier": 47, "item_id": "quick_chat.game_on"},
	{"tier": 48, "item_id": "goal_explosion.stadium_roar"},
	{"tier": 49, "item_id": "player_banner.dark_vanguard"},
	{"tier": 50, "item_id": "player_skin.dark_vanguard"},
]

var season_xp: int = 0
var _opened_lootboxes: int = 0
var _lootbox_history: Array[String] = []
var _save_path: String = SAVE_PATH
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	if OS.has_environment("THEODORE_RL_V2_HEADLESS"):
		return
	load_progress()


func get_max_level() -> int:
	var obtainable_count: int = 0
	for item_variant: Variant in FootballCosmeticInventory.CATALOG.values():
		var item: Dictionary = item_variant as Dictionary
		if (
			FootballCosmeticInventory.is_catalog_item_obtainable(item)
			and not bool(item.get("owned_by_default", false))
		):
			obtainable_count += 1
	return obtainable_count


func get_level() -> int:
	return mini(get_max_level(), season_xp / XP_PER_TIER)


func get_xp_into_level() -> int:
	if get_level() >= get_max_level():
		return XP_PER_TIER
	return season_xp % XP_PER_TIER


func get_xp_for_next_level() -> int:
	return XP_PER_TIER


func get_drop_pool() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var inventory := get_node_or_null(
		"/root/CosmeticInventory"
	) as FootballCosmeticInventory
	for item_id_variant: Variant in FootballCosmeticInventory.CATALOG.keys():
		var item_id: String = str(item_id_variant)
		var catalog_item: Dictionary = (
			FootballCosmeticInventory.CATALOG[item_id] as Dictionary
		)
		if bool(catalog_item.get("owned_by_default", false)):
			continue
		if not FootballCosmeticInventory.is_catalog_item_obtainable(catalog_item):
			continue
		var copy: Dictionary = catalog_item.duplicate(true)
		copy["item_id"] = item_id
		copy["owned"] = inventory != null and inventory.is_owned(item_id)
		result.append(copy)
	result.sort_custom(_drop_item_precedes)
	return result


func get_rewards() -> Array[Dictionary]:
	# Compatibility for callers that only need to inspect the cosmetic pool.
	return get_drop_pool()


func get_available_lootboxes() -> int:
	return maxi(0, get_level() - _opened_lootboxes)


func get_opened_lootbox_count() -> int:
	return _opened_lootboxes


func get_lootbox_history() -> Array[String]:
	return _lootbox_history.duplicate()


func get_available_cases() -> int:
	return get_available_lootboxes()


func get_opened_case_count() -> int:
	return get_opened_lootbox_count()


func get_case_history() -> Array[String]:
	return get_lootbox_history()


func set_random_seed(seed_value: int) -> void:
	_rng.seed = seed_value


func add_match_xp(
	won: bool,
	goals: int,
	saves: int,
	passes: int,
	scheduled_match_seconds: float = FULL_XP_MATCH_SECONDS
) -> int:
	var previous_xp: int = season_xp
	var previous_level: int = get_level()
	var previous_lootboxes: int = get_available_lootboxes()
	var earned: int = calculate_match_xp(
		won,
		goals,
		saves,
		passes,
		scheduled_match_seconds
	)
	season_xp = mini(get_max_level() * XP_PER_TIER, season_xp + earned)
	var credited_xp: int = season_xp - previous_xp
	save_progress()
	progress_changed.emit(get_level(), season_xp)
	match_xp_awarded.emit(
		credited_xp,
		previous_xp,
		season_xp,
		previous_level,
		get_level(),
		previous_lootboxes,
		get_available_lootboxes()
	)
	return credited_xp


static func calculate_match_xp(
	won: bool,
	goals: int,
	saves: int,
	passes: int,
	scheduled_match_seconds: float
) -> int:
	var performance_xp: int = 100
	performance_xp += clampi(goals, 0, 20) * 25
	performance_xp += clampi(saves, 0, 30) * 12
	performance_xp += clampi(passes, 0, 50) * 4
	var win_multiplier: float = WIN_XP_MULTIPLIER if won else 1.0
	var duration_multiplier: float = maxf(
		0.0,
		scheduled_match_seconds / FULL_XP_MATCH_SECONDS
	)
	return maxi(
		0,
		roundi(float(performance_xp) * win_multiplier * duration_multiplier)
	)


func open_lootbox() -> Dictionary:
	if get_available_lootboxes() <= 0:
		return {}
	var inventory := get_node_or_null("/root/CosmeticInventory") as FootballCosmeticInventory
	if inventory == null:
		return {}
	var candidates: Array[Dictionary] = []
	for drop: Dictionary in get_drop_pool():
		var candidate_id: String = str(drop.get("item_id", ""))
		if not candidate_id.is_empty() and not inventory.is_owned(candidate_id):
			candidates.append(drop)
	if candidates.is_empty():
		return {}
	var reward: Dictionary = _pick_random_drop(candidates)
	var item_id: String = str(reward.get("item_id", ""))
	if item_id.is_empty() or not inventory.unlock_item(item_id):
		return {}
	_opened_lootboxes += 1
	_lootbox_history.append(item_id)
	save_progress()
	reward_claimed.emit(_opened_lootboxes, item_id)
	lootbox_opened.emit(_opened_lootboxes, item_id)
	case_opened.emit(_opened_lootboxes, item_id)
	progress_changed.emit(get_level(), season_xp)
	reward["owned"] = true
	return reward


func open_case() -> Dictionary:
	return open_lootbox()


func claim_reward(_tier: int) -> bool:
	# Backward-compatible entry point for old code and saves. The chosen drop is
	# intentionally random now; tiers no longer map to fixed items.
	return not open_lootbox().is_empty()


func load_progress(path: String = SAVE_PATH) -> Error:
	_save_path = path
	season_xp = 0
	_opened_lootboxes = 0
	_lootbox_history.clear()
	var config := ConfigFile.new()
	var load_error: Error = config.load(path)
	if load_error == ERR_FILE_NOT_FOUND:
		return save_progress(path)
	if load_error != OK:
		return load_error
	var stored_season_id: String = str(config.get_value("season", "id", ""))
	if stored_season_id != SEASON_ID and not LEGACY_SEASON_IDS.has(stored_season_id):
		return save_progress(path)
	season_xp = clampi(
		int(config.get_value("season", "xp", 0)),
		0,
		get_max_level() * XP_PER_TIER
	)
	if stored_season_id == SEASON_ID:
		if config.has_section_key("season", "opened_lootboxes"):
			_opened_lootboxes = clampi(
				int(config.get_value("season", "opened_lootboxes", 0)),
				0,
				get_level()
			)
			var stored_history: Array = config.get_value(
				"season", "lootbox_history", []
			) as Array
			for item_variant: Variant in stored_history:
				var stored_item_id: String = str(item_variant)
				if FootballCosmeticInventory.CATALOG.has(stored_item_id):
					_lootbox_history.append(stored_item_id)
		elif config.has_section_key("season", "opened_cases"):
			# Schema 3 used Case Vault terminology. Preserve every opened box and
			# its history while upgrading the save to Lootboxes.
			_opened_lootboxes = clampi(
				int(config.get_value("season", "opened_cases", 0)),
				0,
				get_level()
			)
			var case_history: Array = config.get_value(
				"season", "case_history", []
			) as Array
			for item_variant: Variant in case_history:
				var case_item_id: String = str(item_variant)
				if FootballCosmeticInventory.CATALOG.has(case_item_id):
					_lootbox_history.append(case_item_id)
		else:
			# Schema 2 stored fixed claimed tiers. Treat each claim as an already
			# opened lootbox so migration never grants duplicate free boxes.
			var claimed: Array = config.get_value(
				"season", "claimed_tiers", []
			) as Array
			_opened_lootboxes = mini(claimed.size(), get_level())
	else:
		# Preserve earned XP from the small preseason prototype, but do not mark
		# unrelated First Touch rewards as already claimed.
		return save_progress(path)
	return OK


func save_progress(path: String = "") -> Error:
	var target_path: String = _save_path if path.is_empty() else path
	_save_path = target_path
	var config := ConfigFile.new()
	config.set_value("profile", "version", SCHEMA_VERSION)
	config.set_value("season", "id", SEASON_ID)
	config.set_value("season", "xp", season_xp)
	config.set_value("season", "opened_lootboxes", _opened_lootboxes)
	config.set_value("season", "lootbox_history", _lootbox_history)
	return config.save(target_path)


func _drop_item_precedes(left: Dictionary, right: Dictionary) -> bool:
	var rarity_order: Dictionary = {
		"legendary": 0,
		"epic": 1,
		"rare": 2,
		"uncommon": 3,
		"common": 4,
	}
	var left_rarity: int = int(rarity_order.get(str(left.get("rarity", "common")), 4))
	var right_rarity: int = int(rarity_order.get(str(right.get("rarity", "common")), 4))
	if left_rarity != right_rarity:
		return left_rarity < right_rarity
	return str(left.get("name", "")) < str(right.get("name", ""))


func _pick_random_drop(candidates: Array[Dictionary]) -> Dictionary:
	if candidates.is_empty():
		return {}
	var total_weight: float = 0.0
	for candidate: Dictionary in candidates:
		total_weight += get_lootbox_rarity_weight(
			str(candidate.get("rarity", "common"))
		)
	var roll: float = _rng.randf() * total_weight
	for candidate: Dictionary in candidates:
		roll -= get_lootbox_rarity_weight(
			str(candidate.get("rarity", "common"))
		)
		if roll <= 0.0:
			return candidate.duplicate(true)
	return candidates.back().duplicate(true)


static func get_lootbox_rarity_weight(rarity: String) -> float:
	# Mild weighting: high-rarity drops stay realistic to obtain while each
	# individual Epic or Legendary is less likely than an individual Common.
	match rarity.to_lower():
		"legendary":
			return 0.45
		"epic":
			return 0.60
		"rare":
			return 0.75
		"uncommon":
			return 0.90
	return 1.0
