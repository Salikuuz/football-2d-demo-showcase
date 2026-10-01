class_name TheodoreRLV2DemonstrationImporter
extends RefCounted

const Schema := preload("res://ai_v2/rl_schema.gd")

const DEMO_VELOCITY_SCALE: float = 3200.0
const FIELD_WIDTH: float = 6610.0
const FIELD_HEIGHT: float = 3640.0
const FIELD_DIAGONAL: float = 7545.733
const DEFAULT_MAX_SPEED: float = 5550.0
const DEFAULT_ACCELERATION: float = 5900.0
const DEFAULT_ABILITY_COOLDOWN: float = 8.0
const DEFAULT_MAX_CHARGE: float = 0.5
const MAX_SAMPLES_PER_SOURCE_MATCH: int = 160

var _feature_indices: Dictionary = {}


func _init() -> void:
	var names: Array[String] = Schema.observation_feature_names()
	for index in range(names.size()):
		_feature_indices[names[index]] = index


func load_candidate_model(path: String = "user://human_demonstrations/candidate_model.json") -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"ok": false, "error": "candidate_model_missing", "path": path}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "error": "candidate_model_unreadable", "path": path}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return {"ok": false, "error": "candidate_model_corrupt", "path": path}
	var result: Dictionary = build_dataset(parsed as Dictionary)
	result["path"] = path
	return result


func build_dataset(model: Dictionary) -> Dictionary:
	var sequences_variant: Variant = model.get("sequences", [])
	if not sequences_variant is Array:
		return {"ok": false, "error": "invalid_sequences"}
	var train: Array[Dictionary] = []
	var validation: Array[Dictionary] = []
	var source_counts: Dictionary = {}
	var ability_counts: Dictionary = {}
	var combination_counts: Dictionary = {}
	var positive_sequences: int = 0
	var negative_sequences: int = 0
	var rejected_sequences: int = 0
	for sequence_variant in sequences_variant as Array:
		if not sequence_variant is Dictionary:
			rejected_sequences += 1
			continue
		var sequence := sequence_variant as Dictionary
		var reward: float = float(sequence.get("reward", 0.0))
		if reward <= 0.0 or bool(sequence.get("negative_example", false)):
			negative_sequences += 1
			continue
		positive_sequences += 1
		var source_match: String = str(sequence.get("source_match", "unknown"))
		var source_count: int = int(source_counts.get(source_match, 0))
		if source_count >= MAX_SAMPLES_PER_SOURCE_MATCH:
			rejected_sequences += 1
			continue
		var sequence_samples: Array[Dictionary] = _sequence_samples(sequence)
		if sequence_samples.is_empty():
			rejected_sequences += 1
			continue
		var destination: Array[Dictionary] = validation if bool(sequence.get("split", false)) else train
		for sample in sequence_samples:
			if source_count >= MAX_SAMPLES_PER_SOURCE_MATCH:
				break
			destination.append(sample)
			source_count += 1
		source_counts[source_match] = source_count
		var ability_id: int = int(sequence.get("ability_id", 0))
		if ability_id > 0:
			ability_counts[str(ability_id)] = int(ability_counts.get(str(ability_id), 0)) + 1
		var combination_id: String = str(sequence.get("combination_id", "ordinary"))
		combination_counts[combination_id] = int(combination_counts.get(combination_id, 0)) + 1
	return {
		"ok": not train.is_empty(),
		"error": "" if not train.is_empty() else "no_positive_training_samples",
		"schema_fingerprint": Schema.schema_fingerprint(),
		"train": train,
		"validation": validation,
		"stats": {
			"source_sequences": (sequences_variant as Array).size(),
			"positive_sequences": positive_sequences,
			"negative_sequences_retained_for_evaluation": negative_sequences,
			"rejected_or_capped_sequences": rejected_sequences,
			"train_samples": train.size(),
			"validation_samples": validation.size(),
			"source_matches": source_counts.size(),
			"ability_sequences": ability_counts,
			"combination_sequences": combination_counts
		}
	}


func context_to_observation(context: Dictionary) -> PackedFloat32Array:
	var observation := PackedFloat32Array()
	observation.resize(Schema.observation_size())
	var actor: Vector2 = _vector(context.get("actor", [0.5, 0.5]), Vector2(0.5, 0.5))
	var actor_velocity: Vector2 = _demo_velocity(context.get("actor_velocity", [0.0, 0.0]))
	var ball: Vector2 = _vector(context.get("ball", [0.5, 0.5]), Vector2(0.5, 0.5))
	var ball_velocity: Vector2 = _demo_velocity(context.get("ball_velocity", [0.0, 0.0]))
	var teammates: Array = context.get("teammates", []) as Array
	var opponents: Array = context.get("opponents", []) as Array
	var possession: String = str(context.get("possession", "loose"))
	_write_feature(observation, "team_size_norm", clampf(float(teammates.size() + 1) / float(Schema.MAX_TEAM_SIZE), 0.0, 1.0))
	_write_feature(observation, "game_started", 1.0)
	_write_feature(observation, "ball_pos_x", ball.x)
	_write_feature(observation, "ball_pos_y", ball.y)
	_write_feature(observation, "ball_vel_x", ball_velocity.x)
	_write_feature(observation, "ball_vel_y", ball_velocity.y)
	_write_feature(observation, "ball_speed_norm", ball_velocity.length())
	for horizon_data in [["025", 0.25], ["050", 0.5], ["100", 1.0]]:
		var horizon_name: String = str(horizon_data[0])
		var horizon: float = float(horizon_data[1])
		var future := Vector2(
			clampf(ball.x + ball_velocity.x * Schema.VELOCITY_SCALE * horizon / FIELD_WIDTH, -0.25, 1.25),
			clampf(ball.y + ball_velocity.y * Schema.VELOCITY_SCALE * horizon / FIELD_HEIGHT, -0.25, 1.25)
		)
		_write_feature(observation, "ball_future_%s_x" % horizon_name, future.x)
		_write_feature(observation, "ball_future_%s_y" % horizon_name, future.y)
	_write_feature(observation, "possession_self", 1.0 if possession == "self" else 0.0)
	_write_feature(observation, "possession_team", 1.0 if possession == "team" else 0.0)
	_write_feature(observation, "possession_opponent", 1.0 if possession in ["opponent", "enemy"] else 0.0)
	_write_feature(observation, "possession_loose", 1.0 if possession not in ["self", "team", "opponent", "enemy"] else 0.0)
	_fill_entity(
		observation,
		"self",
		actor,
		actor_velocity,
		int(context.get("ability_id", 0)),
		context,
		ball,
		&"self"
	)
	for index in range(Schema.MAX_TEAMMATES):
		if index < teammates.size() and teammates[index] is Dictionary:
			var teammate := teammates[index] as Dictionary
			_fill_entity(observation, "teammate_%d" % index, _member_position(teammate), _demo_velocity(teammate.get("velocity", [0.0, 0.0])), int(teammate.get("ability_id", 0)), teammate, ball, &"teammate")
	for index in range(Schema.MAX_OPPONENTS):
		if index < opponents.size() and opponents[index] is Dictionary:
			var opponent := opponents[index] as Dictionary
			_fill_entity(observation, "opponent_%d" % index, _member_position(opponent), _demo_velocity(opponent.get("velocity", [0.0, 0.0])), int(opponent.get("ability_id", 0)), opponent, ball, &"opponent")
	return observation


func action_to_targets(action: Dictionary) -> Dictionary:
	var kind: String = str(action.get("kind", "movement"))
	var move: Vector2 = _vector(action.get("move", [0.0, 0.0]), Vector2.ZERO).limit_length(1.0)
	var aim: Vector2 = _vector(action.get("aim", [1.0, 0.0]), Vector2.RIGHT)
	if aim.length_squared() <= 0.000001:
		aim = Vector2.RIGHT
	else:
		aim = aim.normalized()
	var kick_mode: int = Schema.KICK_NONE
	if kind == "pass" or str(action.get("target_role", "")).begins_with("teammate"):
		kick_mode = Schema.KICK_PASS
	elif kind == "kick":
		kick_mode = Schema.KICK_SHOT
	var strength: float = 0.0
	if kick_mode != Schema.KICK_NONE:
		strength = 0.12 if str(action.get("pass_type", "none")) == "soft" else clampf(float(action.get("charge", 0.0)) / DEFAULT_MAX_CHARGE, 0.08, 1.0)
	var receiver_slot: int = 0
	var target_role: String = str(action.get("target_role", ""))
	if target_role.begins_with("teammate_"):
		receiver_slot = clampi(int(target_role.trim_prefix("teammate_")) + 1, 1, Schema.MAX_TEAMMATES)
	var continuous := PackedFloat32Array([
		_inverse_tanh(move.x),
		_inverse_tanh(move.y),
		_inverse_tanh(aim.x),
		_inverse_tanh(aim.y),
		_logit(strength) if kick_mode != Schema.KICK_NONE else 0.0
	])
	var continuous_mask := PackedFloat32Array([1.0, 1.0, 1.0, 1.0, 1.0 if kick_mode != Schema.KICK_NONE else 0.0])
	return {
		"raw_continuous": continuous,
		"continuous_mask": continuous_mask,
		"discrete": PackedInt32Array([
			kick_mode,
			1 if kind == "ability" else 0,
			0,
			Schema.RECEIVE_NONE,
			receiver_slot
		])
	}


func _sequence_samples(sequence: Dictionary) -> Array[Dictionary]:
	var context_variant: Variant = sequence.get("context", {})
	var actions_variant: Variant = sequence.get("actions", [])
	if not context_variant is Dictionary or not actions_variant is Array:
		return []
	var context := context_variant as Dictionary
	var observation: PackedFloat32Array = context_to_observation(context)
	if observation.size() != Schema.observation_size() or not _all_finite(observation):
		return []
	var reward: float = float(sequence.get("reward", 0.0))
	var confidence: float = clampf(float(sequence.get("confidence", 0.5)), 0.05, 1.0)
	var samples: Array[Dictionary] = []
	var accepted_kinds: Dictionary = {}
	for action_variant in actions_variant as Array:
		if not action_variant is Dictionary:
			continue
		var action := action_variant as Dictionary
		var kind: String = str(action.get("kind", ""))
		if kind not in ["movement", "kick", "pass", "ability"] or accepted_kinds.has(kind):
			continue
		accepted_kinds[kind] = true
		var targets: Dictionary = action_to_targets(action)
		var action_emphasis: float = 1.0
		if kind in ["kick", "pass"]:
			action_emphasis = 2.4
		elif kind == "ability":
			action_emphasis = 1.8
		samples.append({
			"observation": observation.duplicate(),
			"raw_continuous": targets["raw_continuous"],
			"continuous_mask": targets["continuous_mask"],
			"discrete": targets["discrete"],
			"weight": clampf((0.35 + sqrt(maxf(0.0, reward))) * confidence * action_emphasis, 0.08, 5.0),
			"kind": kind,
			"sequence_dt": float(action.get("dt", 0.0)),
			"ability_id": int(sequence.get("ability_id", 0)),
			"combination_id": str(sequence.get("combination_id", "ordinary")),
			"source_match": str(sequence.get("source_match", "unknown"))
		})
	return samples


func _fill_entity(observation: PackedFloat32Array, prefix: String, position: Vector2, velocity: Vector2, ability_id: int, state: Dictionary, ball: Vector2, relation: StringName) -> void:
	var base: String = prefix + "."
	_write_feature(observation, base + "present", 1.0)
	_write_feature(observation, base + "is_self", 1.0 if relation == &"self" else 0.0)
	_write_feature(observation, base + "is_teammate", 1.0 if relation == &"teammate" else 0.0)
	_write_feature(observation, base + "is_opponent", 1.0 if relation == &"opponent" else 0.0)
	_write_feature(observation, base + "is_human", 1.0 if relation == &"self" else 0.0)
	_write_feature(observation, base + "is_cpu", 0.0 if relation == &"self" else 1.0)
	_write_feature(observation, base + "controls_enabled", 1.0)
	_write_feature(observation, base + "pos_x", position.x)
	_write_feature(observation, base + "pos_y", position.y)
	_write_feature(observation, base + "vel_x", velocity.x)
	_write_feature(observation, base + "vel_y", velocity.y)
	var move: Vector2 = _vector(state.get("move", [0.0, 0.0]), Vector2.ZERO).limit_length(1.0)
	_write_feature(observation, base + "move_intent_x", move.x)
	_write_feature(observation, base + "move_intent_y", move.y)
	var distance_to_ball: float = _field_distance(position, ball)
	_write_feature(observation, base + "distance_to_ball_norm", distance_to_ball)
	_write_feature(observation, base + "ball_arrival_time_norm", clampf(distance_to_ball * FIELD_DIAGONAL / DEFAULT_MAX_SPEED / Schema.ARRIVAL_TIME_SCALE, 0.0, 2.0))
	_write_feature(observation, base + "distance_to_own_goal_norm", _field_distance(position, Vector2(0.0, 0.5)))
	_write_feature(observation, base + "distance_to_opponent_goal_norm", _field_distance(position, Vector2(1.0, 0.5)))
	_write_feature(observation, base + "forward_progress", position.x)
	_write_feature(observation, base + "max_speed_norm", DEFAULT_MAX_SPEED / Schema.MAX_SPEED_SCALE)
	_write_feature(observation, base + "acceleration_norm", DEFAULT_ACCELERATION / Schema.ACCELERATION_SCALE)
	_write_feature(observation, base + "effective_speed_multiplier_norm", 1.0 / 3.0)
	_write_feature(observation, base + "effective_acceleration_multiplier_norm", 1.0 / 4.0)
	_write_feature(observation, base + "is_charging", 1.0 if bool(state.get("charging", false)) else 0.0)
	_write_feature(observation, base + "charge_fraction", clampf(float(state.get("charge", 0.0)) / DEFAULT_MAX_CHARGE, 0.0, 1.0))
	_write_feature(observation, base + "has_ball_control", 1.0 if distance_to_ball * FIELD_DIAGONAL <= 260.0 else 0.0)
	var cooldown: float = maxf(0.0, float(state.get("cooldown", 0.0)))
	var cooldown_ready: bool = bool(state.get("cooldown_ready", ability_id > 0 and cooldown <= 0.0))
	_write_feature(observation, base + "ability_ready", 1.0 if ability_id > 0 and cooldown_ready else 0.0)
	_write_feature(observation, base + "ability_active", 1.0 if bool(state.get("ability_active", false)) else 0.0)
	_write_feature(observation, base + "ability_cooldown_fraction", clampf(cooldown / DEFAULT_ABILITY_COOLDOWN, 0.0, 1.0))
	_write_feature(observation, base + "ability_strength_scale", 1.0)
	_write_feature(observation, base + "first_touch_none", 1.0)
	if ability_id >= 0 and ability_id < Schema.ABILITY_COUNT_WITH_NONE:
		_write_feature(observation, base + "selected_ability_%02d" % ability_id, 1.0)
	var active_ability_id: int = int(state.get("active_ability_id", 0))
	if bool(state.get("ability_active", false)) and active_ability_id > 0 and active_ability_id < Schema.ABILITY_COUNT_WITH_NONE:
		_write_feature(observation, base + "active_ability_%02d" % active_ability_id, 1.0)
	_set_ability_role(observation, base, ability_id)


func _set_ability_role(observation: PackedFloat32Array, base: String, ability_id: int) -> void:
	var role: String = ""
	if ability_id in [1, 3, 4, 9, 15, 19, 20, 22]:
		role = "attack"
	elif ability_id in [2, 5, 8, 10, 11, 16, 18, 21]:
		role = "playmaker"
	elif ability_id in [6, 7, 13, 14, 17]:
		role = "defense"
	elif ability_id in [12, 23]:
		role = "flexible"
	if not role.is_empty():
		_write_feature(observation, base + "ability_role_" + role, 1.0)


func _write_feature(observation: PackedFloat32Array, feature_name: String, value: float) -> void:
	var index: int = int(_feature_indices.get(feature_name, -1))
	if index >= 0:
		observation[index] = value


func _member_position(member: Dictionary) -> Vector2:
	return _vector(member.get("position", [0.5, 0.5]), Vector2(0.5, 0.5))


func _demo_velocity(value: Variant) -> Vector2:
	return _vector(value, Vector2.ZERO) * (DEMO_VELOCITY_SCALE / Schema.VELOCITY_SCALE)


func _field_distance(a: Vector2, b: Vector2) -> float:
	return Vector2((a.x - b.x) * FIELD_WIDTH, (a.y - b.y) * FIELD_HEIGHT).length() / FIELD_DIAGONAL


func _vector(value: Variant, fallback: Vector2) -> Vector2:
	if value is Vector2:
		return value
	if value is Array and (value as Array).size() >= 2:
		var values := value as Array
		return Vector2(float(values[0]), float(values[1]))
	if value is PackedFloat32Array and (value as PackedFloat32Array).size() >= 2:
		var values := value as PackedFloat32Array
		return Vector2(values[0], values[1])
	return fallback


func _inverse_tanh(value: float) -> float:
	var safe: float = clampf(value, -0.999, 0.999)
	return 0.5 * log((1.0 + safe) / (1.0 - safe))


func _logit(value: float) -> float:
	var safe: float = clampf(value, 0.001, 0.999)
	return log(safe / (1.0 - safe))


func _all_finite(values: PackedFloat32Array) -> bool:
	for value in values:
		if is_nan(value) or is_inf(value):
			return false
	return true
