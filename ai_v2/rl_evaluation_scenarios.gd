class_name TheodoreRLV2EvaluationScenarios
extends RefCounted

const Schema := preload("res://ai_v2/rl_schema.gd")

const FIELD_VARIANT_COUNT: int = 10
const FORMATIONS: Array[StringName] = [
	&"kickoff",
	&"upper_channel",
	&"lower_channel",
	&"central_pressure",
	&"loose_ball",
	&"rebound"
]
const OPPONENT_PROFILES: Array[StringName] = [
	&"balanced",
	&"aggressive",
	&"defensive",
	&"passing",
	&"ability",
	&"randomized"
]


static func build(team_size: int, scenario_index: int, seed_value: int) -> Dictionary:
	var safe_size: int = clampi(team_size, 1, Schema.MAX_TEAM_SIZE)
	var formation: StringName = FORMATIONS[posmod(scenario_index, FORMATIONS.size())]
	var scenario: Dictionary = {
		"id": "%dv%d_%s_%04d" % [safe_size, safe_size, String(formation), scenario_index],
		"seed": seed_value,
		"formation": String(formation),
		"opponent_profile": String(OPPONENT_PROFILES[posmod(scenario_index + safe_size, OPPONENT_PROFILES.size())]),
		"field_variant": posmod(scenario_index * 3 + safe_size, FIELD_VARIANT_COUNT),
		"elapsed_fraction": float(posmod(scenario_index, 4)) * 0.18,
		"blue_score": 1 if posmod(scenario_index, 6) == 1 else 0,
		"red_score": 1 if posmod(scenario_index, 6) == 4 else 0,
		"blue_abilities": _ability_rotation(safe_size, scenario_index, 0),
		"red_abilities": _ability_rotation(safe_size, scenario_index, safe_size + 5),
		"blue_profiles": _profile_rotation(safe_size, scenario_index),
		"red_profiles": _profile_rotation(safe_size, scenario_index + 2)
	}
	_apply_formation(scenario, safe_size, formation)
	return scenario


static func coverage(scenarios: Array[Dictionary]) -> Dictionary:
	var fields: Dictionary = {}
	var formations: Dictionary = {}
	var abilities: Dictionary = {}
	var score_states: Dictionary = {}
	var opponent_profiles: Dictionary = {}
	for scenario in scenarios:
		fields[int(scenario.get("field_variant", -1))] = true
		formations[str(scenario.get("formation", ""))] = true
		opponent_profiles[str(scenario.get("opponent_profile", ""))] = true
		for key in ["blue_abilities", "red_abilities"]:
			for ability_value in scenario.get(key, []) as Array:
				abilities[int(ability_value)] = true
		var blue_score: int = int(scenario.get("blue_score", 0))
		var red_score: int = int(scenario.get("red_score", 0))
		var state: String = "tie" if blue_score == red_score else ("blue_ahead" if blue_score > red_score else "red_ahead")
		score_states[state] = true
	return {
		"field_variants": fields.size(),
		"formations": formations.size(),
		"abilities": abilities.size(),
		"score_states": score_states.size(),
		"opponent_profiles": opponent_profiles.size()
	}


static func _ability_rotation(team_size: int, scenario_index: int, offset: int) -> Array:
	var result: Array = []
	for slot in range(team_size):
		result.append(1 + posmod(scenario_index * team_size + slot + offset, Schema.ABILITY_COUNT_WITH_NONE - 1))
	return result


static func _profile_rotation(team_size: int, scenario_index: int) -> Array:
	var result: Array = []
	for slot in range(team_size):
		match posmod(scenario_index + slot, 4):
			0:
				result.append({"archetype": "balanced"})
			1:
				result.append({"archetype": "pace", "speed_scale": 1.08, "acceleration_scale": 1.1})
			2:
				result.append({"archetype": "power", "ability_strength_scale": 1.12})
			_:
				result.append({"archetype": "keeper", "speed_scale": 0.96, "acceleration_scale": 1.05})
	return result


static func _apply_formation(scenario: Dictionary, team_size: int, formation: StringName) -> void:
	var blue_positions: Array = _base_positions(team_size, true)
	var red_positions: Array = _base_positions(team_size, false)
	var ball_position := Vector2(0.5, 0.5)
	var ball_velocity := Vector2.ZERO
	match formation:
		&"upper_channel":
			ball_position = Vector2(0.5, 0.18)
			_shift_y(blue_positions, -0.16)
			_shift_y(red_positions, -0.16)
		&"lower_channel":
			ball_position = Vector2(0.5, 0.82)
			_shift_y(blue_positions, 0.16)
			_shift_y(red_positions, 0.16)
		&"central_pressure":
			ball_position = Vector2(0.5, 0.5)
			_compress_x(blue_positions, 0.08)
			_compress_x(red_positions, -0.08)
		&"loose_ball":
			ball_position = Vector2(0.5, 0.35)
			ball_velocity = Vector2(0.0, 1100.0)
		&"rebound":
			ball_position = Vector2(0.5, 0.72)
			ball_velocity = Vector2(1300.0, -850.0)
		_:
			pass
	scenario["blue_positions"] = blue_positions
	scenario["red_positions"] = red_positions
	scenario["ball_position"] = ball_position
	scenario["ball_velocity"] = ball_velocity


static func _base_positions(team_size: int, blue: bool) -> Array:
	var result: Array = []
	var x_base: float = 0.36 if blue else 0.64
	for slot in range(team_size):
		var y_value: float = float(slot + 1) / float(team_size + 1)
		var x_stagger: float = float(slot % 2) * (0.035 if blue else -0.035)
		result.append(Vector2(x_base + x_stagger, y_value))
	return result


static func _shift_y(positions: Array, amount: float) -> void:
	for index in range(positions.size()):
		var point: Vector2 = positions[index] as Vector2
		point.y = clampf(point.y + amount, 0.08, 0.92)
		positions[index] = point


static func _compress_x(positions: Array, amount: float) -> void:
	for index in range(positions.size()):
		var point: Vector2 = positions[index] as Vector2
		point.x = clampf(point.x + amount, 0.08, 0.92)
		positions[index] = point
