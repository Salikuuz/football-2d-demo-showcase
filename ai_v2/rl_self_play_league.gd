class_name TheodoreRLV2SelfPlayLeague
extends RefCounted

const LeagueOpponent := preload("res://ai_v2/rl_league_opponent.gd")

const STATE_VERSION: int = 1
const DEFAULT_ELO: float = 1000.0
const K_FACTOR: float = 28.0

var state_path: String = ""
var state: Dictionary = {}
var default_champion_path: String = "res://training/ai_v2/checkpoints/1v1_champion.json"
var _rng := RandomNumberGenerator.new()


func _init(
	requested_state_path: String = "res://training/ai_v2/league/1v1_league.json",
	requested_seed: int = 20260813,
	requested_champion_path: String = "res://training/ai_v2/checkpoints/1v1_champion.json"
) -> void:
	state_path = requested_state_path
	default_champion_path = requested_champion_path
	_rng.seed = requested_seed
	state = _default_state(requested_seed)
	load_state()
	ensure_required_opponents()


func ensure_required_opponents() -> void:
	_upsert_default("theodore_current", "Current Theodore Champion", "legacy", "current", "balanced")
	_upsert_default("specialist_aggressive", "Aggressive Specialist", "specialist", "specialist", "aggressive")
	_upsert_default("specialist_defensive", "Defensive Specialist", "specialist", "specialist", "defensive")
	_upsert_default("specialist_passing", "Passing Specialist", "specialist", "specialist", "passing")
	_upsert_default("specialist_ability", "Ability Specialist", "specialist", "specialist", "ability")
	_upsert_default("randomized_a", "Randomized Policy A", "randomized", "randomized", "randomized", 0.12)
	_upsert_default("randomized_b", "Randomized Policy B", "randomized", "randomized", "randomized", 0.25)
	var champion_path: String = str(state.get("champion_path", ""))
	if not champion_path.is_empty() and FileAccess.file_exists(champion_path):
		upsert_entry({
			"id": "v2_current",
			"name": "V2 Current Champion",
			"kind": "neural",
			"category": "current_v2",
			"profile": "balanced",
			"checkpoint_path": champion_path,
			"sampling_weight": 1.4
		})


func sample_entry() -> Dictionary:
	var entries: Array = state.get("entries", []) as Array
	if entries.is_empty():
		ensure_required_opponents()
		entries = state.get("entries", []) as Array
	var total_weight: float = 0.0
	for entry_variant in entries:
		var entry := entry_variant as Dictionary
		total_weight += maxf(0.01, float(entry.get("sampling_weight", 1.0)))
	var roll: float = _rng.randf() * total_weight
	for entry_variant in entries:
		var entry := entry_variant as Dictionary
		roll -= maxf(0.01, float(entry.get("sampling_weight", 1.0)))
		if roll <= 0.0:
			return entry.duplicate(true)
	return (entries.back() as Dictionary).duplicate(true)


func build_opponent(entry: Dictionary, seed_offset: int = 0):
	return LeagueOpponent.new(entry, int(state.get("seed", 1)) + seed_offset)


func record_match(opponent_id: String, candidate_score: int, opponent_score: int, candidate_side: StringName) -> void:
	var index: int = _find_entry_index(opponent_id)
	if index < 0:
		return
	var entries: Array = state.get("entries", []) as Array
	var entry := (entries[index] as Dictionary).duplicate(true)
	var candidate_elo: float = float(state.get("candidate_elo", DEFAULT_ELO))
	var opponent_elo: float = float(entry.get("elo", DEFAULT_ELO))
	var actual: float = 1.0 if candidate_score > opponent_score else (0.0 if candidate_score < opponent_score else 0.5)
	var expected: float = 1.0 / (1.0 + pow(10.0, (opponent_elo - candidate_elo) / 400.0))
	var change: float = K_FACTOR * (actual - expected)
	state["candidate_elo"] = candidate_elo + change
	entry["elo"] = opponent_elo - change
	entry["matches"] = int(entry.get("matches", 0)) + 1
	entry["wins_vs_candidate"] = int(entry.get("wins_vs_candidate", 0)) + (1 if opponent_score > candidate_score else 0)
	entry["losses_vs_candidate"] = int(entry.get("losses_vs_candidate", 0)) + (1 if opponent_score < candidate_score else 0)
	entry["draws_vs_candidate"] = int(entry.get("draws_vs_candidate", 0)) + (1 if opponent_score == candidate_score else 0)
	entry["goals_for"] = int(entry.get("goals_for", 0)) + opponent_score
	entry["goals_against"] = int(entry.get("goals_against", 0)) + candidate_score
	entry["blue_appearances"] = int(entry.get("blue_appearances", 0)) + (1 if candidate_side == &"red" else 0)
	entry["red_appearances"] = int(entry.get("red_appearances", 0)) + (1 if candidate_side == &"blue" else 0)
	entries[index] = entry
	state["entries"] = entries
	state["matches_recorded"] = int(state.get("matches_recorded", 0)) + 1


func register_snapshot(snapshot_id: String, checkpoint_path: String, display_name: String = "Previous V2 Champion") -> bool:
	if snapshot_id.is_empty() or checkpoint_path.is_empty() or not FileAccess.file_exists(checkpoint_path):
		return false
	upsert_entry({
		"id": snapshot_id,
		"name": display_name,
		"kind": "neural",
		"category": "historical_v2",
		"profile": "balanced",
		"checkpoint_path": checkpoint_path,
		"sampling_weight": 1.15
	})
	return true


func upsert_entry(requested: Dictionary) -> void:
	var entries: Array = state.get("entries", []) as Array
	var index: int = _find_entry_index(str(requested.get("id", "")))
	var source: Dictionary = requested.duplicate(true)
	if index >= 0:
		var old := entries[index] as Dictionary
		source = old.duplicate(true)
		for key_variant in requested.keys():
			source[key_variant] = requested[key_variant]
	var entry: Dictionary = _normalized_entry(source)
	if index >= 0:
		entries[index] = entry
	else:
		entries.append(entry)
	state["entries"] = entries


func categories() -> Array[String]:
	var result: Array[String] = []
	for entry_variant in state.get("entries", []) as Array:
		var entry := entry_variant as Dictionary
		var category: String = str(entry.get("category", "unknown"))
		if not result.has(category):
			result.append(category)
	result.sort()
	return result


func save_state() -> bool:
	state["updated_unix"] = Time.get_unix_time_from_system()
	var directory: String = state_path.get_base_dir()
	if not directory.is_empty() and not state_path.begins_with("user://"):
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory + "/placeholder").get_base_dir())
	var file := FileAccess.open(state_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(state, "\t"))
	return true


func load_state() -> bool:
	if not FileAccess.file_exists(state_path):
		return false
	var file := FileAccess.open(state_path, FileAccess.READ)
	if file == null:
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return false
	var document := parsed as Dictionary
	if int(document.get("version", 0)) != STATE_VERSION:
		return false
	state = document.duplicate(true)
	_rng.seed = int(state.get("seed", 1)) + int(state.get("matches_recorded", 0))
	return true


func _upsert_default(id: String, display_name: String, kind: String, category: String, profile: String, jitter: float = 0.0) -> void:
	if _find_entry_index(id) >= 0:
		return
	var requested: Dictionary = {
		"id": id,
		"name": display_name,
		"kind": kind,
		"category": category,
		"profile": profile,
		"sampling_weight": 1.0
	}
	if jitter > 0.0:
		requested["jitter"] = jitter
	upsert_entry(requested)


func _find_entry_index(entry_id: String) -> int:
	var entries: Array = state.get("entries", []) as Array
	for index in range(entries.size()):
		var entry := entries[index] as Dictionary
		if str(entry.get("id", "")) == entry_id:
			return index
	return -1


func _normalized_entry(requested: Dictionary) -> Dictionary:
	return {
		"id": str(requested.get("id", "")),
		"name": str(requested.get("name", requested.get("id", "Opponent"))),
		"kind": str(requested.get("kind", "legacy")),
		"category": str(requested.get("category", "specialist")),
		"profile": str(requested.get("profile", "balanced")),
		"checkpoint_path": str(requested.get("checkpoint_path", "")),
		"sampling_weight": maxf(0.01, float(requested.get("sampling_weight", 1.0))),
		"jitter": maxf(0.0, float(requested.get("jitter", 0.0))),
		"elo": float(requested.get("elo", DEFAULT_ELO)),
		"matches": int(requested.get("matches", 0)),
		"wins_vs_candidate": int(requested.get("wins_vs_candidate", 0)),
		"losses_vs_candidate": int(requested.get("losses_vs_candidate", 0)),
		"draws_vs_candidate": int(requested.get("draws_vs_candidate", 0)),
		"goals_for": int(requested.get("goals_for", 0)),
		"goals_against": int(requested.get("goals_against", 0)),
		"blue_appearances": int(requested.get("blue_appearances", 0)),
		"red_appearances": int(requested.get("red_appearances", 0))
	}


func _default_state(seed_value: int) -> Dictionary:
	return {
		"version": STATE_VERSION,
		"seed": seed_value,
		"generation": 0,
		"matches_recorded": 0,
		"candidate_elo": DEFAULT_ELO,
		"champion_elo": DEFAULT_ELO,
		"champion_path": default_champion_path,
		"entries": []
	}
