class_name TheodoreRLV2ActionCodec
extends RefCounted

const Schema := preload("res://ai_v2/rl_schema.gd")


static func neutral_action() -> Dictionary:
	return {
		"move": Vector2.ZERO,
		"aim": Vector2(1.0, 0.0),
		"kick_strength": 0.0,
		"kick_mode": Schema.KICK_NONE,
		"ability_trigger": false,
		"pass_request": false,
		"receive_mode": Schema.RECEIVE_NONE,
		"receiver_slot": 0
	}


static func sanitize(action: Dictionary) -> Dictionary:
	var move := _vector2_from_value(action.get("move", Vector2.ZERO))
	if move.length_squared() > 1.0:
		move = move.normalized()
	var aim := _vector2_from_value(action.get("aim", Vector2(1.0, 0.0)))
	if aim.length_squared() <= 0.000001:
		aim = Vector2(1.0, 0.0)
	else:
		aim = aim.normalized()
	return {
		"move": move,
		"aim": aim,
		"kick_strength": clampf(float(action.get("kick_strength", 0.0)), 0.0, 1.0),
		"kick_mode": clampi(int(action.get("kick_mode", Schema.KICK_NONE)), 0, 2),
		"ability_trigger": bool(action.get("ability_trigger", false)),
		"pass_request": bool(action.get("pass_request", false)),
		"receive_mode": clampi(int(action.get("receive_mode", Schema.RECEIVE_NONE)), 0, 3),
		"receiver_slot": clampi(int(action.get("receiver_slot", 0)), 0, Schema.MAX_TEAMMATES)
	}


static func encode(action: Dictionary) -> Dictionary:
	var safe := sanitize(action)
	var move: Vector2 = safe["move"]
	var aim: Vector2 = safe["aim"]
	return {
		"continuous": PackedFloat32Array([
			move.x,
			move.y,
			aim.x,
			aim.y,
			float(safe["kick_strength"])
		]),
		"discrete": PackedInt32Array([
			int(safe["kick_mode"]),
			1 if bool(safe["ability_trigger"]) else 0,
			1 if bool(safe["pass_request"]) else 0,
			int(safe["receive_mode"]),
			int(safe["receiver_slot"])
		])
	}


static func decode(continuous, discrete) -> Dictionary:
	var continuous_values: Array = _to_array(continuous)
	var discrete_values: Array = _to_array(discrete)
	while continuous_values.size() < Schema.CONTINUOUS_ACTION_NAMES.size():
		continuous_values.append(0.0)
	while discrete_values.size() < Schema.DISCRETE_ACTION_NAMES.size():
		discrete_values.append(0)
	return sanitize({
		"move": Vector2(float(continuous_values[0]), float(continuous_values[1])),
		"aim": Vector2(float(continuous_values[2]), float(continuous_values[3])),
		"kick_strength": float(continuous_values[4]),
		"kick_mode": int(discrete_values[0]),
		"ability_trigger": int(discrete_values[1]) != 0,
		"pass_request": int(discrete_values[2]) != 0,
		"receive_mode": int(discrete_values[3]),
		"receiver_slot": int(discrete_values[4])
	})


static func to_wire_packet(action: Dictionary) -> Dictionary:
	var encoded := encode(action)
	return {
		"action_version": Schema.ACTION_VERSION,
		"continuous": Array(encoded["continuous"]),
		"discrete": Array(encoded["discrete"])
	}


static func _vector2_from_value(value) -> Vector2:
	if value is Vector2:
		return value
	if value is Array and value.size() >= 2:
		return Vector2(float(value[0]), float(value[1]))
	if value is PackedFloat32Array and value.size() >= 2:
		return Vector2(float(value[0]), float(value[1]))
	if value is Dictionary:
		return Vector2(float(value.get("x", 0.0)), float(value.get("y", 0.0)))
	return Vector2.ZERO


static func _to_array(value) -> Array:
	if value is Array:
		return value.duplicate()
	if value is PackedFloat32Array or value is PackedInt32Array:
		return Array(value)
	return []
