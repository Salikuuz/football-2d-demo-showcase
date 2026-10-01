class_name HybridOpponentPool
extends RefCounted


const CheckpointStore := preload("res://ai/hybrid/checkpoint_store.gd")
const Policy := preload("res://ai/hybrid/tactical_policy.gd")
const Schema := preload("res://ai/hybrid/tactical_schema.gd")

const SOURCE_CURRENT: StringName = &"current"
const SOURCE_HISTORICAL: StringName = &"historical"
const SOURCE_SCRIPTED: StringName = &"scripted"
const SOURCE_HUMAN: StringName = &"human_imitation"
const SOURCE_SPECIALIST: StringName = &"specialist"
const SOURCE_RANDOMIZED: StringName = &"randomized"

const DEFAULT_MIX: Dictionary = {
	"current": 0.35,
	"historical": 0.25,
	"scripted": 0.15,
	"human_imitation": 0.10,
	"specialist": 0.10,
	"randomized": 0.05
}

var _rng := RandomNumberGenerator.new()
var _entries: Array[Dictionary] = []
var _mix: Dictionary = DEFAULT_MIX.duplicate(true)
var _performance: Dictionary = {}


func _init(seed_value: int = 104729) -> void:
	_rng.seed = seed_value


func configure(
	current_checkpoint: Dictionary,
	legacy_parameters: Dictionary,
	checkpoint_directory: String,
	mix_override: Dictionary = {}
) -> void:
	_entries.clear()
	_performance.clear()
	_mix = _normalize_mix(mix_override if not mix_override.is_empty() else DEFAULT_MIX)
	_add_entry({
		"id": "current",
		"source": SOURCE_CURRENT,
		"label": "Current champion",
		"policy": current_checkpoint.get("policy", Policy.get_default_policy_document()),
		"legacy_parameters": legacy_parameters.duplicate(true),
		"style": "balanced",
		"persistent": true
	})
	_load_historical_entries(checkpoint_directory)
	_add_scripted_entries(legacy_parameters)
	_add_human_entry(current_checkpoint, legacy_parameters)
	_add_specialist_entries(current_checkpoint, legacy_parameters)
	_add_randomized_entries(current_checkpoint, legacy_parameters)


func update_current(checkpoint: Dictionary, legacy_parameters: Dictionary) -> void:
	var policy := checkpoint.get("policy", Policy.get_default_policy_document()) as Dictionary
	for index in range(_entries.size()):
		if str(_entries[index].get("id", "")) != "current":
			continue
		_entries[index]["policy"] = policy.duplicate(true)
		_entries[index]["legacy_parameters"] = legacy_parameters.duplicate(true)
		_entries[index]["checkpoint_checksum"] = str(checkpoint.get("model_checksum", ""))
		return
	_add_entry({
		"id": "current",
		"source": SOURCE_CURRENT,
		"label": "Current champion",
		"policy": policy.duplicate(true),
		"legacy_parameters": legacy_parameters.duplicate(true),
		"style": "balanced",
		"persistent": true,
		"checkpoint_checksum": str(checkpoint.get("model_checksum", ""))
	})


func add_historical_checkpoint(checkpoint: Dictionary, entry_id: String = "") -> bool:
	if checkpoint.is_empty():
		return false
	var identifier := entry_id
	if identifier.is_empty():
		identifier = "historical_%s" % str(checkpoint.get("model_checksum", "unknown")).left(12)
	var before := _entries.size()
	_add_entry({
		"id": identifier,
		"source": SOURCE_HISTORICAL,
		"label": "Historical %s" % identifier.trim_prefix("historical_"),
		"policy": checkpoint.get("policy", Policy.get_default_policy_document()),
		"legacy_parameters": checkpoint.get("legacy_parameters", {}),
		"style": "historical",
		"persistent": true,
		"checkpoint_checksum": str(checkpoint.get("model_checksum", ""))
	})
	return _entries.size() > before


func sample(rng_override: RandomNumberGenerator = null) -> Dictionary:
	if _entries.is_empty():
		return {}
	var active_rng := rng_override if rng_override != null else _rng
	var source := _sample_source(active_rng)
	var candidates: Array[Dictionary] = []
	for entry in _entries:
		if StringName(entry.get("source", &"")) == source:
			candidates.append(entry)
	if candidates.is_empty():
		candidates.assign(_entries)
	var selected := candidates[active_rng.randi_range(0, candidates.size() - 1)]
	return selected.duplicate(true)


func record_result(entry_id: String, score: float, won: bool) -> void:
	var stats := _performance.get(entry_id, {
		"matches": 0,
		"wins": 0,
		"score_sum": 0.0
	}) as Dictionary
	stats["matches"] = int(stats.get("matches", 0)) + 1
	stats["wins"] = int(stats.get("wins", 0)) + (1 if won else 0)
	stats["score_sum"] = float(stats.get("score_sum", 0.0)) + score
	stats["win_rate"] = float(stats["wins"]) / maxf(1.0, float(stats["matches"]))
	stats["average_score"] = float(stats["score_sum"]) / maxf(1.0, float(stats["matches"]))
	_performance[entry_id] = stats


func get_state() -> Dictionary:
	var sources: Dictionary = {}
	for entry in _entries:
		var source_name := str(entry.get("source", "unknown"))
		sources[source_name] = int(sources.get(source_name, 0)) + 1
	var persistent_entries: Array[Dictionary] = []
	for entry in _entries:
		var source := StringName(entry.get("source", &""))
		if not bool(entry.get("persistent", false)) or source in [SOURCE_CURRENT, SOURCE_SCRIPTED, SOURCE_HUMAN]:
			continue
		persistent_entries.append(entry.duplicate(true))
	return {
		"mix": _mix.duplicate(true),
		"entry_count": _entries.size(),
		"entries_by_source": sources,
		"performance": _performance.duplicate(true),
		"persistent_entries": persistent_entries
	}


func get_entries() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry in _entries:
		result.append(entry.duplicate(true))
	return result


func add_counter_opponent(entry: Dictionary) -> bool:
	if entry.is_empty():
		return false
	var counter := entry.duplicate(true)
	counter["source"] = SOURCE_SPECIALIST
	counter["persistent"] = true
	if str(counter.get("id", "")).is_empty():
		counter["id"] = "counter_%d" % Time.get_ticks_msec()
	_add_entry(counter)
	return true


func _sample_source(rng_override: RandomNumberGenerator = null) -> StringName:
	var active_rng := rng_override if rng_override != null else _rng
	var roll := active_rng.randf()
	var accumulated := 0.0
	for source_name in [
		"current",
		"historical",
		"scripted",
		"human_imitation",
		"specialist",
		"randomized"
	]:
		accumulated += float(_mix.get(source_name, 0.0))
		if roll <= accumulated:
			return StringName(source_name)
	return SOURCE_CURRENT


func _load_historical_entries(directory_path: String) -> void:
	var directory := DirAccess.open(directory_path)
	if directory == null:
		return
	var files := directory.get_files()
	files.sort()
	var selected_files: Array[String] = []
	if files.size() <= 12:
		for file_name in files:
			if file_name.ends_with(".json"):
				selected_files.append(file_name)
	else:
		var step := maxf(1.0, float(files.size() - 1) / 11.0)
		for index in range(12):
			var file_index := mini(files.size() - 1, int(round(float(index) * step)))
			var file_name := str(files[file_index])
			if file_name.ends_with(".json") and file_name not in selected_files:
				selected_files.append(file_name)
	for file_name in selected_files:
		var path := directory_path.path_join(file_name)
		var checkpoint := CheckpointStore.load_checkpoint(path)
		if not bool(checkpoint.get("ok", false)):
			continue
		var document := checkpoint.get("document", {}) as Dictionary
		_add_entry({
			"id": "historical_%s" % file_name.get_basename(),
			"source": SOURCE_HISTORICAL,
			"label": "Historical %s" % file_name.get_basename(),
			"policy": document.get("policy", {}),
			"legacy_parameters": document.get("legacy_parameters", {}),
			"style": "historical",
			"path": path,
			"persistent": true
		})


func _add_scripted_entries(legacy_parameters: Dictionary) -> void:
	for style in ["original", "aggressive", "defensive", "passing"]:
		var parameters := legacy_parameters.duplicate(true)
		match style:
			"original":
				parameters = {}
			"aggressive":
				parameters["dribble_choice_chance"] = 0.68
				parameters["creative_shot_chance"] = 0.62
				parameters["minimum_forward_pass_progress"] = 780.0
				parameters["goalkeeper_chase_distance"] = 1750.0
			"defensive":
				parameters["defensive_anchor_distance"] = 1550.0
				parameters["goalkeeper_depth"] = 480.0
				parameters["goalkeeper_chase_distance"] = 980.0
				parameters["defensive_block_ball_blend"] = 0.62
			"passing":
				parameters["dribble_choice_chance"] = 0.24
				parameters["pass_lane_clearance"] = 270.0
				parameters["minimum_forward_pass_progress"] = 300.0
				parameters["pass_lead_seconds"] = 0.3
		var policy := Policy.get_default_policy_document()
		var bias := policy.get("bias", {}) as Dictionary
		match style:
			"aggressive":
				bias[str(Schema.ACTION_DIRECT_SHOT)] = 0.65
				bias[str(Schema.ACTION_CARRY)] = 0.45
				bias[str(Schema.ACTION_CHALLENGE_BALL)] = 0.35
			"defensive":
				bias[str(Schema.ACTION_PROTECT_GOAL)] = 0.75
				bias[str(Schema.ACTION_SHADOW_DEFEND)] = 0.5
				bias[str(Schema.ACTION_ROTATE_BACK)] = 0.35
			"passing":
				bias[str(Schema.ACTION_PASS_AHEAD)] = 0.75
				bias[str(Schema.ACTION_SAFE_PASS)] = 0.55
		policy["bias"] = bias
		_add_entry({
			"id": "scripted_%s" % style,
			"source": SOURCE_SCRIPTED,
			"label": "Scripted %s" % style,
			"policy": policy,
			"legacy_parameters": parameters,
			"style": style,
			"persistent": true
		})


func _add_human_entry(current_checkpoint: Dictionary, legacy_parameters: Dictionary) -> void:
	_add_entry({
		"id": "human_imitation_candidate",
		"source": SOURCE_HUMAN,
		"label": "Human demonstration candidate",
		"policy": current_checkpoint.get("policy", Policy.get_default_policy_document()),
		"legacy_parameters": legacy_parameters.duplicate(true),
		"style": "human_imitation",
		"use_human_candidate": true,
		"persistent": true
	})


func _add_specialist_entries(current_checkpoint: Dictionary, legacy_parameters: Dictionary) -> void:
	for style in ["wall_shot", "wall_shot_defender", "counterpress", "solo_duel"]:
		var policy := Policy.normalize_policy_document(current_checkpoint.get("policy", {}) as Dictionary)
		var bias := policy.get("bias", {}) as Dictionary
		match style:
			"wall_shot":
				bias[str(Schema.ACTION_WALL_BANK_SHOT)] = float(bias.get(str(Schema.ACTION_WALL_BANK_SHOT), 0.0)) + 1.25
			"wall_shot_defender":
				bias[str(Schema.ACTION_SHADOW_DEFEND)] = float(bias.get(str(Schema.ACTION_SHADOW_DEFEND), 0.0)) + 0.9
				bias[str(Schema.ACTION_PROTECT_GOAL)] = float(bias.get(str(Schema.ACTION_PROTECT_GOAL), 0.0)) + 0.7
			"counterpress":
				bias[str(Schema.ACTION_CHALLENGE_BALL)] = float(bias.get(str(Schema.ACTION_CHALLENGE_BALL), 0.0)) + 1.0
				bias[str(Schema.ACTION_ROTATE_BACK)] = float(bias.get(str(Schema.ACTION_ROTATE_BACK), 0.0)) - 0.4
			"solo_duel":
				bias[str(Schema.ACTION_CARRY)] = float(bias.get(str(Schema.ACTION_CARRY), 0.0)) + 1.0
				bias[str(Schema.ACTION_FAKE_CHALLENGE)] = float(bias.get(str(Schema.ACTION_FAKE_CHALLENGE), 0.0)) + 0.45
		policy["bias"] = bias
		_add_entry({
			"id": "specialist_%s" % style,
			"source": SOURCE_SPECIALIST,
			"label": "Specialist %s" % style,
			"policy": policy,
			"legacy_parameters": legacy_parameters.duplicate(true),
			"style": style,
			"persistent": true
		})


func _add_randomized_entries(current_checkpoint: Dictionary, legacy_parameters: Dictionary) -> void:
	for index in range(4):
		var policy := Policy.normalize_policy_document(current_checkpoint.get("policy", {}) as Dictionary)
		var bias := policy.get("bias", {}) as Dictionary
		for action in Schema.ALL_ACTIONS:
			var action_name := str(action)
			bias[action_name] = clampf(float(bias.get(action_name, 0.0)) + _rng.randf_range(-0.75, 0.75), -3.0, 3.0)
		policy["bias"] = bias
		policy["exploration"] = 0.12
		_add_entry({
			"id": "randomized_%02d" % index,
			"source": SOURCE_RANDOMIZED,
			"label": "Randomized %02d" % index,
			"policy": policy,
			"legacy_parameters": legacy_parameters.duplicate(true),
			"style": "randomized",
			"persistent": false
		})


func _add_entry(entry: Dictionary) -> void:
	var entry_id := str(entry.get("id", ""))
	if entry_id.is_empty():
		return
	for existing in _entries:
		if str(existing.get("id", "")) == entry_id:
			return
	_entries.append(entry)


func _normalize_mix(source: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	var total := 0.0
	for key in DEFAULT_MIX.keys():
		var value := maxf(0.0, float(source.get(key, DEFAULT_MIX[key])))
		result[key] = value
		total += value
	if total <= 0.0:
		return DEFAULT_MIX.duplicate(true)
	for key in result.keys():
		result[key] = float(result[key]) / total
	return result


func sample_source(external_rng: RandomNumberGenerator = null) -> Dictionary:
	var entry := sample(external_rng)
	if entry.is_empty():
		return {"category": "current", "id": "current"}
	return {
		"category": str(entry.get("source", SOURCE_CURRENT)),
		"id": str(entry.get("id", "current")),
		"entry": entry
	}


func serialize_state() -> Dictionary:
	return get_state()


func load_state(state: Dictionary) -> void:
	if state.has("mix") and state["mix"] is Dictionary:
		_mix = _normalize_mix(state["mix"] as Dictionary)
	if state.has("performance") and state["performance"] is Dictionary:
		_performance = (state["performance"] as Dictionary).duplicate(true)
	if state.has("persistent_entries") and state["persistent_entries"] is Array:
		for entry_variant in state["persistent_entries"] as Array:
			if entry_variant is Dictionary:
				_add_entry((entry_variant as Dictionary).duplicate(true))
