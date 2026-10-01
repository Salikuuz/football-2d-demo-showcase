class_name HybridRewardLedger
extends RefCounted


const REWARD_VERSION: int = 3
const DEFAULT_WEIGHTS: Dictionary = {
	"win": 10.0,
	"loss": -10.0,
	"goal": 5.0,
	"concede": -5.0,
	"prevent_imminent_goal": 1.2,
	"chance_created": 0.55,
	"teammate_chance_created": 0.45,
	"expected_goal_gain": 0.65,
	"expected_goal_prevented": 0.6,
	"successful_pass": 0.10,
	"line_breaking_pass": 0.24,
	"defense_shift_exploited": 0.20,
	"combination_progress": 0.22,
	"third_man_completion": 0.28,
	"safe_pressure_escape": 0.16,
	"counter_balance": 0.12,
	"sterile_pass_loop": -0.14,
	"unsupported_forward_commit": -0.16,
	"pass_chain_turnover": -0.34,
	"useful_possession": 0.08,
	"ball_race_won": 0.12,
	"danger_cleared": 0.32,
	"interception": 0.12,
	"dangerous_clearance": 0.18,
	"run_behind_completion": 0.28,
	# Creative-wall rewards default to zero so older configs are unaffected.
	# New wall-focused generations opt in explicitly.
	"creative_wall_progress": 0.0,
	"creative_wall_failure": 0.0,
	"productive_wall_pass": 0.0,
	"wall_shot_quality": 0.0,
	"attacking_half_turnover": -0.42,
	"ignored_open_shot": -0.38,
	"ball_hugging": -0.06,
	"counter_concede": -0.65,
	"defensive_mistake": -0.90,
	"open_support": 0.08,
	"double_commit_avoided": 0.06,
	"own_goal": -16.0,
	"open_goal_abandoned": -1.1,
	"useless_repeated_touch": -0.18,
	"mindless_chase": -0.12,
	"teammate_blocked": -0.15,
	"pass_to_opponent": -0.38,
	"own_goal_shot": -6.0,
	"camping": -0.16,
	"stuck": -0.12,
	"impossible_action": -0.08,
	"fallback_override": -0.03
}

var _weights: Dictionary = DEFAULT_WEIGHTS.duplicate(true)
var _components: Dictionary = {}
var _events: Array[Dictionary] = []
var _maximum_events: int = 512


func configure(weights: Dictionary) -> void:
	_weights = DEFAULT_WEIGHTS.duplicate(true)
	for key in weights.keys():
		if _weights.has(key):
			_weights[key] = clampf(float(weights[key]), -20.0, 20.0)


func reset() -> void:
	_components.clear()
	_events.clear()


func add(component: StringName, amount: float = 1.0, context: Dictionary = {}) -> float:
	var component_name := str(component)
	if not _weights.has(component_name):
		return 0.0
	var weighted := float(_weights[component_name]) * amount
	_components[component_name] = float(_components.get(component_name, 0.0)) + weighted
	_events.append({
		"component": component_name,
		"amount": amount,
		"weighted": weighted,
		"context": context.duplicate(true)
	})
	while _events.size() > _maximum_events:
		_events.pop_front()
	return weighted


func total() -> float:
	var value := 0.0
	for component_value in _components.values():
		value += float(component_value)
	return value


func summary() -> Dictionary:
	return {
		"reward_version": REWARD_VERSION,
		"total": total(),
		"components": _components.duplicate(true),
		"event_count": _events.size()
	}


func get_events() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for event in _events:
		result.append(event.duplicate(true))
	return result
