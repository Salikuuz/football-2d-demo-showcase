class_name TheodoreRLV2NeuralPolicy
extends RefCounted

const Schema := preload("res://ai_v2/rl_schema.gd")
const LegalActionMask := preload("res://ai_v2/rl_legal_action_mask.gd")

const CONTINUOUS_COUNT: int = 5
const DISCRETE_TOTAL: int = 15
const ACTOR_OUTPUTS: int = CONTINUOUS_COUNT + DISCRETE_TOTAL
const DEFAULT_HIDDEN_SIZE: int = 24
const FIXED_STD: float = 0.34
const LOG_TWO_PI: float = 1.8378770664093453

var observation_size: int = 0
var hidden_size: int = DEFAULT_HIDDEN_SIZE
var memory_size: int = 0
var training_steps: int = 0
var seed_value: int = 104729

var _rng := RandomNumberGenerator.new()
var _input_weights := PackedFloat32Array()
var _recurrent_weights := PackedFloat32Array()
var _hidden_bias := PackedFloat32Array()
var _actor_weights := PackedFloat32Array()
var _actor_bias := PackedFloat32Array()
var _value_weights := PackedFloat32Array()
var _value_bias: float = 0.0


func initialize(requested_observation_size: int, requested_hidden_size: int = DEFAULT_HIDDEN_SIZE, requested_seed: int = 104729) -> void:
	observation_size = maxi(1, requested_observation_size)
	hidden_size = maxi(4, requested_hidden_size)
	seed_value = requested_seed
	memory_size = 0
	_rng.seed = seed_value
	_input_weights.resize(hidden_size * observation_size)
	_recurrent_weights = PackedFloat32Array()
	_hidden_bias.resize(hidden_size)
	_actor_weights.resize(ACTOR_OUTPUTS * hidden_size)
	_actor_bias.resize(ACTOR_OUTPUTS)
	_value_weights.resize(hidden_size)
	var input_scale: float = sqrt(2.0 / float(observation_size + hidden_size))
	var actor_scale: float = sqrt(2.0 / float(hidden_size + ACTOR_OUTPUTS))
	for index in range(_input_weights.size()):
		_input_weights[index] = _rng.randfn(0.0, input_scale)
	for index in range(_actor_weights.size()):
		_actor_weights[index] = _rng.randfn(0.0, actor_scale)
	for index in range(_value_weights.size()):
		_value_weights[index] = _rng.randfn(0.0, actor_scale)
	_hidden_bias.fill(0.0)
	_actor_bias.fill(0.0)
	_value_bias = 0.0
	training_steps = 0


func enable_recurrence(requested_seed: int = -1) -> bool:
	if observation_size <= 0 or hidden_size < 4 or _input_weights.is_empty():
		return false
	memory_size = hidden_size
	_recurrent_weights.resize(hidden_size * memory_size)
	# Recurrence is trained by PPO later. Random recurrent weights corrupt a
	# behavior-cloned policy as soon as its second frame, even though its first
	# frame evaluates correctly. Starting as an identity-neutral memory keeps the
	# cloned fundamentals stable while preserving the recurrent architecture.
	_recurrent_weights.fill(0.0)
	return true


func recurrence_enabled() -> bool:
	return memory_size == hidden_size and _recurrent_weights.size() == hidden_size * memory_size


func initial_memory() -> PackedFloat32Array:
	var memory := PackedFloat32Array()
	memory.resize(memory_size)
	return memory


func sample(observation: PackedFloat32Array, team: StringName, deterministic: bool = false) -> Dictionary:
	return sample_recurrent(observation, initial_memory(), team, deterministic)


func sample_recurrent(
	observation: PackedFloat32Array,
	previous_memory: PackedFloat32Array,
	team: StringName,
	deterministic: bool = false
) -> Dictionary:
	var safe_memory: PackedFloat32Array = _safe_memory(previous_memory)
	var forward_result: Dictionary = _forward(observation, safe_memory)
	var actor: PackedFloat32Array = forward_result["actor"]
	var raw_continuous := PackedFloat32Array()
	raw_continuous.resize(CONTINUOUS_COUNT)
	var log_probability: float = 0.0
	for index in range(CONTINUOUS_COUNT):
		var mean: float = actor[index]
		var raw_value: float = mean if deterministic else mean + _rng.randfn(0.0, FIXED_STD)
		raw_continuous[index] = raw_value
		log_probability += _normal_log_probability(raw_value, mean)
	var discrete := PackedInt32Array()
	discrete.resize(Schema.DISCRETE_ACTION_SIZES.size())
	var discrete_mask: PackedFloat32Array = LegalActionMask.from_observation(observation)
	var actor_offset: int = CONTINUOUS_COUNT
	var mask_offset: int = 0
	for branch_index in range(Schema.DISCRETE_ACTION_SIZES.size()):
		var branch_size: int = Schema.DISCRETE_ACTION_SIZES[branch_index]
		var probabilities: PackedFloat32Array = _masked_softmax_slice(actor, actor_offset, branch_size, discrete_mask, mask_offset)
		var selected: int = _argmax(probabilities) if deterministic else _sample_probability(probabilities)
		discrete[branch_index] = selected
		log_probability += log(maxf(1.0e-8, probabilities[selected]))
		actor_offset += branch_size
		mask_offset += branch_size
	return {
		"action": _decode_action(raw_continuous, discrete, team),
		"raw_continuous": raw_continuous,
		"discrete": discrete,
		"discrete_mask": discrete_mask,
		"log_probability": log_probability,
		"value": float(forward_result["value"]),
		"memory": safe_memory,
		"next_memory": forward_result["next_memory"]
	}


func evaluate_sample(observation: PackedFloat32Array, raw_continuous: PackedFloat32Array, discrete: PackedInt32Array) -> Dictionary:
	return evaluate_recurrent_sample(observation, initial_memory(), raw_continuous, discrete)


func evaluate_recurrent_sample(
	observation: PackedFloat32Array,
	previous_memory: PackedFloat32Array,
	raw_continuous: PackedFloat32Array,
	discrete: PackedInt32Array,
	discrete_mask: PackedFloat32Array = PackedFloat32Array()
) -> Dictionary:
	var safe_memory: PackedFloat32Array = _safe_memory(previous_memory)
	var forward_result: Dictionary = _forward(observation, safe_memory)
	var actor: PackedFloat32Array = forward_result["actor"]
	var log_probability: float = 0.0
	for index in range(CONTINUOUS_COUNT):
		log_probability += _normal_log_probability(raw_continuous[index], actor[index])
	var actor_offset: int = CONTINUOUS_COUNT
	var mask_offset: int = 0
	var safe_mask: PackedFloat32Array = discrete_mask if discrete_mask.size() == DISCRETE_TOTAL else LegalActionMask.all_allowed()
	for branch_index in range(Schema.DISCRETE_ACTION_SIZES.size()):
		var branch_size: int = Schema.DISCRETE_ACTION_SIZES[branch_index]
		var probabilities: PackedFloat32Array = _masked_softmax_slice(actor, actor_offset, branch_size, safe_mask, mask_offset)
		log_probability += log(maxf(1.0e-8, probabilities[discrete[branch_index]]))
		actor_offset += branch_size
		mask_offset += branch_size
	return {
		"log_probability": log_probability,
		"value": float(forward_result["value"]),
		"hidden": forward_result["hidden"],
		"actor": actor,
		"memory": safe_memory,
		"next_memory": forward_result["next_memory"]
	}


func ppo_update(batch: Array[Dictionary], epochs: int = 3, learning_rate: float = 0.00035, clip_ratio: float = 0.2, value_weight: float = 0.5) -> Dictionary:
	if batch.is_empty():
		return {"updated": false, "samples": 0}
	var policy_loss_total: float = 0.0
	var value_loss_total: float = 0.0
	for _epoch in range(maxi(1, epochs)):
		for sample_data in batch:
			var observation: PackedFloat32Array = sample_data["observation"]
			var raw_continuous: PackedFloat32Array = sample_data["raw_continuous"]
			var discrete: PackedInt32Array = sample_data["discrete"]
			var discrete_mask: PackedFloat32Array = sample_data.get("discrete_mask", PackedFloat32Array())
			var sample_memory: PackedFloat32Array = sample_data.get("memory", initial_memory())
			var evaluated: Dictionary = evaluate_recurrent_sample(observation, sample_memory, raw_continuous, discrete, discrete_mask)
			var new_log_probability: float = float(evaluated["log_probability"])
			var old_log_probability: float = float(sample_data["old_log_probability"])
			var advantage: float = float(sample_data["advantage"])
			var return_value: float = float(sample_data["return"])
			var ratio: float = exp(clampf(new_log_probability - old_log_probability, -8.0, 8.0))
			var clipped: bool = (advantage >= 0.0 and ratio > 1.0 + clip_ratio) or (advantage < 0.0 and ratio < 1.0 - clip_ratio)
			var log_probability_gradient: float = 0.0 if clipped else -advantage * ratio
			var actor: PackedFloat32Array = evaluated["actor"]
			var hidden: PackedFloat32Array = evaluated["hidden"]
			var actor_gradient := PackedFloat32Array()
			actor_gradient.resize(ACTOR_OUTPUTS)
			for index in range(CONTINUOUS_COUNT):
				actor_gradient[index] = log_probability_gradient * (raw_continuous[index] - actor[index]) / (FIXED_STD * FIXED_STD)
			var actor_offset: int = CONTINUOUS_COUNT
			var mask_offset: int = 0
			var safe_mask: PackedFloat32Array = discrete_mask if discrete_mask.size() == DISCRETE_TOTAL else LegalActionMask.all_allowed()
			for branch_index in range(Schema.DISCRETE_ACTION_SIZES.size()):
				var branch_size: int = Schema.DISCRETE_ACTION_SIZES[branch_index]
				var probabilities: PackedFloat32Array = _masked_softmax_slice(actor, actor_offset, branch_size, safe_mask, mask_offset)
				for option_index in range(branch_size):
					var selected_term: float = 1.0 if option_index == discrete[branch_index] else 0.0
					actor_gradient[actor_offset + option_index] = log_probability_gradient * (selected_term - probabilities[option_index])
				actor_offset += branch_size
				mask_offset += branch_size
			var value: float = float(evaluated["value"])
			var value_error: float = value - return_value
			_apply_gradients(observation, hidden, actor_gradient, value_error * value_weight, learning_rate, sample_memory)
			policy_loss_total += -minf(ratio * advantage, clampf(ratio, 1.0 - clip_ratio, 1.0 + clip_ratio) * advantage)
			value_loss_total += value_error * value_error
	training_steps += batch.size() * maxi(1, epochs)
	var denominator: float = float(batch.size() * maxi(1, epochs))
	return {
		"updated": true,
		"samples": batch.size(),
		"policy_loss": policy_loss_total / denominator,
		"value_loss": value_loss_total / denominator
	}


func behavior_clone_update(
	batch: Array[Dictionary],
	epochs: int = 5,
	learning_rate: float = 0.00025
) -> Dictionary:
	if batch.is_empty():
		return {"updated": false, "samples": 0, "loss": 0.0, "accuracy": 0.0}
	var loss_total: float = 0.0
	var correct_branches: int = 0
	var branch_total: int = 0
	var update_count: int = 0
	for _epoch in range(maxi(1, epochs)):
		for sample_data in batch:
			var observation: PackedFloat32Array = sample_data.get("observation", PackedFloat32Array())
			var raw_continuous: PackedFloat32Array = sample_data.get("raw_continuous", PackedFloat32Array())
			var continuous_mask: PackedFloat32Array = sample_data.get("continuous_mask", PackedFloat32Array())
			var discrete: PackedInt32Array = sample_data.get("discrete", PackedInt32Array())
			var discrete_mask: PackedFloat32Array = sample_data.get("discrete_mask", LegalActionMask.all_allowed())
			var continuous_weights: PackedFloat32Array = sample_data.get("continuous_weights", PackedFloat32Array())
			var discrete_weights: PackedFloat32Array = sample_data.get("discrete_weights", PackedFloat32Array())
			if (
				observation.size() != observation_size
				or raw_continuous.size() != CONTINUOUS_COUNT
				or continuous_mask.size() != CONTINUOUS_COUNT
				or discrete.size() != Schema.DISCRETE_ACTION_SIZES.size()
			):
				continue
			var weight: float = clampf(float(sample_data.get("weight", 1.0)), 0.01, 5.0)
			var forward_result: Dictionary = _forward(observation)
			var actor: PackedFloat32Array = forward_result["actor"]
			var hidden: PackedFloat32Array = forward_result["hidden"]
			var actor_gradient := PackedFloat32Array()
			actor_gradient.resize(ACTOR_OUTPUTS)
			for index in range(CONTINUOUS_COUNT):
				if continuous_mask[index] <= 0.0:
					continue
				var continuous_weight: float = weight
				if continuous_weights.size() == CONTINUOUS_COUNT:
					continuous_weight *= clampf(continuous_weights[index], 0.0, 5.0)
				if continuous_weight <= 0.0:
					continue
				var error: float = actor[index] - raw_continuous[index]
				actor_gradient[index] = error * continuous_weight
				loss_total += 0.5 * error * error * continuous_weight
			var actor_offset: int = CONTINUOUS_COUNT
			var mask_offset: int = 0
			for branch_index in range(Schema.DISCRETE_ACTION_SIZES.size()):
				var branch_size: int = Schema.DISCRETE_ACTION_SIZES[branch_index]
				var probabilities: PackedFloat32Array = _masked_softmax_slice(actor, actor_offset, branch_size, discrete_mask, mask_offset)
				var selected: int = clampi(discrete[branch_index], 0, branch_size - 1)
				var branch_weight: float = weight
				if discrete_weights.size() == Schema.DISCRETE_ACTION_SIZES.size():
					branch_weight *= clampf(discrete_weights[branch_index], 0.0, 5.0)
				for option_index in range(branch_size):
					if mask_offset + option_index < discrete_mask.size() and discrete_mask[mask_offset + option_index] <= 0.5:
						actor_gradient[actor_offset + option_index] = 0.0
						continue
					var selected_term: float = 1.0 if option_index == selected else 0.0
					actor_gradient[actor_offset + option_index] = (probabilities[option_index] - selected_term) * branch_weight
				if branch_weight > 0.0:
					loss_total -= log(maxf(1.0e-8, probabilities[selected])) * branch_weight
					correct_branches += 1 if _argmax(probabilities) == selected else 0
					branch_total += 1
				actor_offset += branch_size
				mask_offset += branch_size
			_apply_gradients(observation, hidden, actor_gradient, 0.0, learning_rate)
			update_count += 1
	if update_count <= 0:
		return {"updated": false, "samples": 0, "loss": 0.0, "accuracy": 0.0}
	training_steps += update_count
	return {
		"updated": true,
		"samples": batch.size(),
		"gradient_updates": update_count,
		"loss": loss_total / float(update_count),
		"accuracy": float(correct_branches) / maxf(1.0, float(branch_total))
	}


func behavior_clone_evaluate(batch: Array[Dictionary]) -> Dictionary:
	if batch.is_empty():
		return {"samples": 0, "loss": 0.0, "accuracy": 0.0}
	var loss_total: float = 0.0
	var correct_branches: int = 0
	var branch_total: int = 0
	var valid_samples: int = 0
	for sample_data in batch:
		var observation: PackedFloat32Array = sample_data.get("observation", PackedFloat32Array())
		var raw_continuous: PackedFloat32Array = sample_data.get("raw_continuous", PackedFloat32Array())
		var continuous_mask: PackedFloat32Array = sample_data.get("continuous_mask", PackedFloat32Array())
		var discrete: PackedInt32Array = sample_data.get("discrete", PackedInt32Array())
		var discrete_mask: PackedFloat32Array = sample_data.get("discrete_mask", LegalActionMask.all_allowed())
		if observation.size() != observation_size or raw_continuous.size() != CONTINUOUS_COUNT or continuous_mask.size() != CONTINUOUS_COUNT or discrete.size() != Schema.DISCRETE_ACTION_SIZES.size():
			continue
		var actor: PackedFloat32Array = (_forward(observation) as Dictionary)["actor"]
		for index in range(CONTINUOUS_COUNT):
			if continuous_mask[index] > 0.0:
				var error: float = actor[index] - raw_continuous[index]
				loss_total += 0.5 * error * error
		var actor_offset: int = CONTINUOUS_COUNT
		var mask_offset: int = 0
		for branch_index in range(Schema.DISCRETE_ACTION_SIZES.size()):
			var branch_size: int = Schema.DISCRETE_ACTION_SIZES[branch_index]
			var probabilities: PackedFloat32Array = _masked_softmax_slice(actor, actor_offset, branch_size, discrete_mask, mask_offset)
			var selected: int = clampi(discrete[branch_index], 0, branch_size - 1)
			loss_total -= log(maxf(1.0e-8, probabilities[selected]))
			correct_branches += 1 if _argmax(probabilities) == selected else 0
			branch_total += 1
			actor_offset += branch_size
			mask_offset += branch_size
		valid_samples += 1
	return {
		"samples": valid_samples,
		"loss": loss_total / maxf(1.0, float(valid_samples)),
		"accuracy": float(correct_branches) / maxf(1.0, float(branch_total))
	}


func save_checkpoint(path: String, metadata: Dictionary = {}) -> bool:
	var document: Dictionary = {
		"checkpoint_version": 2,
		"model_type": "theodore_v2_godot_recurrent_actor_critic" if recurrence_enabled() else "theodore_v2_godot_ppo_actor_critic",
		"schema_fingerprint": Schema.schema_fingerprint(),
		"observation_size": observation_size,
		"hidden_size": hidden_size,
		"memory_size": memory_size,
		"training_steps": training_steps,
		"seed": seed_value,
		"fixed_std": FIXED_STD,
		"input_weights": Array(_input_weights),
		"recurrent_weights": Array(_recurrent_weights),
		"hidden_bias": Array(_hidden_bias),
		"actor_weights": Array(_actor_weights),
		"actor_bias": Array(_actor_bias),
		"value_weights": Array(_value_weights),
		"value_bias": _value_bias,
		"metadata": metadata.duplicate(true)
	}
	var directory: String = path.get_base_dir()
	if not directory.is_empty() and not path.begins_with("user://"):
		var global_directory: String = ProjectSettings.globalize_path(directory + "/placeholder").get_base_dir()
		DirAccess.make_dir_recursive_absolute(global_directory)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(document))
	return true


func load_checkpoint(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return false
	var document := parsed as Dictionary
	if str(document.get("schema_fingerprint", "")) != Schema.schema_fingerprint():
		return false
	observation_size = int(document.get("observation_size", 0))
	hidden_size = int(document.get("hidden_size", 0))
	memory_size = int(document.get("memory_size", 0))
	if observation_size != Schema.observation_size() or hidden_size < 4:
		return false
	_input_weights = PackedFloat32Array(document.get("input_weights", []))
	_recurrent_weights = PackedFloat32Array(document.get("recurrent_weights", []))
	_hidden_bias = PackedFloat32Array(document.get("hidden_bias", []))
	_actor_weights = PackedFloat32Array(document.get("actor_weights", []))
	_actor_bias = PackedFloat32Array(document.get("actor_bias", []))
	_value_weights = PackedFloat32Array(document.get("value_weights", []))
	_value_bias = float(document.get("value_bias", 0.0))
	training_steps = int(document.get("training_steps", 0))
	seed_value = int(document.get("seed", 104729))
	_rng.seed = seed_value + training_steps
	var recurrent_shape_valid: bool = (
		memory_size == 0 and _recurrent_weights.is_empty()
	) or (
		memory_size == hidden_size
		and _recurrent_weights.size() == hidden_size * memory_size
	)
	return (
		_input_weights.size() == hidden_size * observation_size
		and _hidden_bias.size() == hidden_size
		and _actor_weights.size() == ACTOR_OUTPUTS * hidden_size
		and _actor_bias.size() == ACTOR_OUTPUTS
		and _value_weights.size() == hidden_size
		and recurrent_shape_valid
	)


func _forward(observation: PackedFloat32Array, previous_memory: PackedFloat32Array = PackedFloat32Array()) -> Dictionary:
	var safe_memory: PackedFloat32Array = _safe_memory(previous_memory)
	var hidden := PackedFloat32Array()
	hidden.resize(hidden_size)
	for hidden_index in range(hidden_size):
		var total: float = _hidden_bias[hidden_index]
		var weight_offset: int = hidden_index * observation_size
		for observation_index in range(observation_size):
			total += _input_weights[weight_offset + observation_index] * observation[observation_index]
		if recurrence_enabled():
			var recurrent_offset: int = hidden_index * memory_size
			for memory_index in range(memory_size):
				total += _recurrent_weights[recurrent_offset + memory_index] * safe_memory[memory_index]
		hidden[hidden_index] = tanh(total)
	var actor := PackedFloat32Array()
	actor.resize(ACTOR_OUTPUTS)
	for output_index in range(ACTOR_OUTPUTS):
		var total: float = _actor_bias[output_index]
		var weight_offset: int = output_index * hidden_size
		for hidden_index in range(hidden_size):
			total += _actor_weights[weight_offset + hidden_index] * hidden[hidden_index]
		actor[output_index] = total
	var value: float = _value_bias
	for hidden_index in range(hidden_size):
		value += _value_weights[hidden_index] * hidden[hidden_index]
	var next_memory := PackedFloat32Array()
	if recurrence_enabled():
		next_memory = hidden.duplicate()
	return {"hidden": hidden, "actor": actor, "value": value, "next_memory": next_memory}


func _apply_gradients(
	observation: PackedFloat32Array,
	hidden: PackedFloat32Array,
	actor_gradient: PackedFloat32Array,
	value_gradient: float,
	learning_rate: float,
	previous_memory: PackedFloat32Array = PackedFloat32Array()
) -> void:
	var safe_memory: PackedFloat32Array = _safe_memory(previous_memory)
	var hidden_gradient := PackedFloat32Array()
	hidden_gradient.resize(hidden_size)
	for output_index in range(ACTOR_OUTPUTS):
		var output_gradient: float = clampf(actor_gradient[output_index], -8.0, 8.0)
		var weight_offset: int = output_index * hidden_size
		for hidden_index in range(hidden_size):
			hidden_gradient[hidden_index] += _actor_weights[weight_offset + hidden_index] * output_gradient
			_actor_weights[weight_offset + hidden_index] -= learning_rate * output_gradient * hidden[hidden_index]
		_actor_bias[output_index] -= learning_rate * output_gradient
	var safe_value_gradient: float = clampf(value_gradient, -8.0, 8.0)
	for hidden_index in range(hidden_size):
		hidden_gradient[hidden_index] += _value_weights[hidden_index] * safe_value_gradient
		_value_weights[hidden_index] -= learning_rate * safe_value_gradient * hidden[hidden_index]
	_value_bias -= learning_rate * safe_value_gradient
	for hidden_index in range(hidden_size):
		var activation_gradient: float = clampf(hidden_gradient[hidden_index] * (1.0 - hidden[hidden_index] * hidden[hidden_index]), -8.0, 8.0)
		var weight_offset: int = hidden_index * observation_size
		for observation_index in range(observation_size):
			_input_weights[weight_offset + observation_index] -= learning_rate * activation_gradient * observation[observation_index]
		if recurrence_enabled():
			var recurrent_offset: int = hidden_index * memory_size
			for memory_index in range(memory_size):
				_recurrent_weights[recurrent_offset + memory_index] -= learning_rate * activation_gradient * safe_memory[memory_index]
		_hidden_bias[hidden_index] -= learning_rate * activation_gradient


func _safe_memory(requested: PackedFloat32Array) -> PackedFloat32Array:
	if not recurrence_enabled():
		return PackedFloat32Array()
	if requested.size() == memory_size:
		return requested
	return initial_memory()


func _decode_action(raw_continuous: PackedFloat32Array, discrete: PackedInt32Array, team: StringName) -> Dictionary:
	var mirror_x: float = -1.0 if team == &"red" else 1.0
	var move := Vector2(tanh(raw_continuous[0]) * mirror_x, tanh(raw_continuous[1]))
	var aim := Vector2(tanh(raw_continuous[2]) * mirror_x, tanh(raw_continuous[3]))
	return {
		"move": move,
		"aim": aim,
		"kick_strength": 1.0 / (1.0 + exp(-raw_continuous[4])),
		"kick_mode": discrete[0],
		"ability_trigger": discrete[1] != 0,
		"pass_request": discrete[2] != 0,
		"receive_mode": discrete[3],
		"receiver_slot": discrete[4]
	}


func _normal_log_probability(value: float, mean: float) -> float:
	var normalized: float = (value - mean) / FIXED_STD
	return -0.5 * (normalized * normalized + LOG_TWO_PI) - log(FIXED_STD)


func _softmax_slice(values: PackedFloat32Array, offset: int, count: int) -> PackedFloat32Array:
	var result := PackedFloat32Array()
	result.resize(count)
	var maximum: float = -INF
	for index in range(count):
		maximum = maxf(maximum, values[offset + index])
	var total: float = 0.0
	for index in range(count):
		result[index] = exp(clampf(values[offset + index] - maximum, -30.0, 30.0))
		total += result[index]
	for index in range(count):
		result[index] /= maxf(1.0e-8, total)
	return result


func _masked_softmax_slice(
	values: PackedFloat32Array,
	offset: int,
	count: int,
	mask: PackedFloat32Array,
	mask_offset: int
) -> PackedFloat32Array:
	var result := PackedFloat32Array()
	result.resize(count)
	var maximum: float = -INF
	var allowed_count: int = 0
	for index in range(count):
		if mask_offset + index < mask.size() and mask[mask_offset + index] > 0.5:
			maximum = maxf(maximum, values[offset + index])
			allowed_count += 1
	if allowed_count <= 0:
		result[0] = 1.0
		return result
	var total: float = 0.0
	for index in range(count):
		if mask_offset + index >= mask.size() or mask[mask_offset + index] <= 0.5:
			result[index] = 0.0
			continue
		result[index] = exp(values[offset + index] - maximum)
		total += result[index]
	for index in range(count):
		result[index] /= maxf(1.0e-8, total)
	return result


func _sample_probability(probabilities: PackedFloat32Array) -> int:
	var roll: float = _rng.randf()
	for index in range(probabilities.size()):
		roll -= probabilities[index]
		if roll <= 0.0:
			return index
	return probabilities.size() - 1


func _argmax(values: PackedFloat32Array) -> int:
	var best_index: int = 0
	var best_value: float = values[0]
	for index in range(1, values.size()):
		if values[index] > best_value:
			best_value = values[index]
			best_index = index
	return best_index
