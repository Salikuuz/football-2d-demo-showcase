class_name AITrainingScenarioDirector
extends RefCounted

const TEAM_BLUE: StringName = &"blue"
const TEAM_RED: StringName = &"red"
const NO_TEAM: StringName = &""
const FIELD_BOUNDS := Rect2(300.0, 750.0, 6750.0, 3500.0)
const FIELD_CENTER := Vector2(3675.0, 2500.0)

const SCENARIO_TWO_V_ONE: StringName = &"2v1"
const SCENARIO_ONE_V_ONE_WALL: StringName = &"1v1_wall"
const SCENARIO_OPEN_REBOUND: StringName = &"open_rebound"
const SCENARIO_LAST_MAN_DEFENSE: StringName = &"last_man_defense"
const SCENARIO_CROSS_FAR_POST: StringName = &"cross_far_post"
const SCENARIO_KEEPER_DISTRIBUTION: StringName = &"keeper_distribution"
const SCENARIO_BLOCKED_SHOOTING_LANE: StringName = &"blocked_shooting_lane"
const SCENARIO_KICKOFF_ATTACK: StringName = &"kickoff_attack"
const SCENARIO_KICKOFF_DEFENSE: StringName = &"kickoff_defense"
const SCENARIO_CENTRAL_DUEL: StringName = &"central_duel"
const SCENARIO_PRESSURE_ESCAPE: StringName = &"pressure_escape"
const SCENARIO_FINISHING_DUEL: StringName = &"finishing_duel"
const SCENARIO_WALL_ESCAPE: StringName = &"wall_escape"
const SCENARIO_WALL_ANGLE_CREATION: StringName = &"wall_angle_creation"
const SCENARIO_CROWDED_WALL_BREAKOUT: StringName = &"crowded_wall_breakout"
const SCENARIO_REBOUND_CHAOS: StringName = &"rebound_chaos"
const SCENARIO_THREADED_PASS_FINISH: StringName = &"threaded_pass_finish"

const DEFAULT_SCENARIOS: Array[StringName] = [
	SCENARIO_TWO_V_ONE,
	SCENARIO_ONE_V_ONE_WALL,
	SCENARIO_OPEN_REBOUND,
	SCENARIO_LAST_MAN_DEFENSE,
	SCENARIO_CROSS_FAR_POST,
	SCENARIO_KEEPER_DISTRIBUTION,
	SCENARIO_BLOCKED_SHOOTING_LANE
]

var _manager: Node
var _rng := RandomNumberGenerator.new()
var _scenario_seconds: float = 7.5
var _scenario_elapsed: float = 999.0
var _scenario_serial: int = 0
var _scenarios: Array[StringName] = DEFAULT_SCENARIOS.duplicate()
var _current_scenario: StringName = &""
var _current_focus_team: StringName = TEAM_BLUE
var _activation_counts: Dictionary = {}
var _side_sign: float = -1.0


func setup(
	manager: Node,
	scenario_seconds: float = 7.5,
	scenarios: Array[StringName] = [],
	seed: int = 104729
) -> void:
	_manager = manager
	_scenario_seconds = clampf(scenario_seconds, 3.0, 20.0)
	_rng.seed = seed
	_scenarios = scenarios.duplicate()
	if _scenarios.is_empty():
		_scenarios = DEFAULT_SCENARIOS.duplicate()
	_scenario_elapsed = _scenario_seconds
	_scenario_serial = 0
	_current_scenario = &""
	_current_focus_team = TEAM_BLUE
	_activation_counts.clear()


func tick(simulated_delta: float) -> Dictionary:
	if _manager == null:
		return {}
	if not bool(_manager.get("game_has_started")):
		_scenario_elapsed = _scenario_seconds
		return {}
	if bool(_manager.get("round_resetting")):
		# A goal/reset ends the current drill. Arm the next one immediately so the
		# trainer never spends several seconds playing an unrelated kickoff state.
		_scenario_elapsed = _scenario_seconds
		return {}
	_scenario_elapsed += maxf(0.0, simulated_delta)
	if _scenario_elapsed < _scenario_seconds:
		return {}
	_scenario_elapsed = 0.0
	return _activate_next_scenario()


func get_current_scenario() -> StringName:
	return _current_scenario


func get_current_focus_team() -> StringName:
	return _current_focus_team


func get_activation_counts() -> Dictionary:
	return _activation_counts.duplicate(true)


func get_debug_state() -> Dictionary:
	return {
		"scenario": str(_current_scenario),
		"focus_team": str(_current_focus_team),
		"scenario_serial": _scenario_serial,
		"time_to_reset": maxf(0.0, _scenario_seconds - _scenario_elapsed),
		"activation_counts": _activation_counts.duplicate(true)
	}


func _activate_next_scenario() -> Dictionary:
	if _scenarios.is_empty():
		return {}
	var scenario: StringName = _scenarios[_scenario_serial % _scenarios.size()]
	_current_focus_team = TEAM_BLUE if _scenario_serial % 2 == 0 else TEAM_RED
	_side_sign = -1.0 if int(_scenario_serial / 2) % 2 == 0 else 1.0
	_scenario_serial += 1
	_current_scenario = scenario
	_activation_counts[str(scenario)] = int(_activation_counts.get(str(scenario), 0)) + 1
	_apply_scenario(scenario, _current_focus_team)
	return {
		"scenario": str(scenario),
		"focus_team": str(_current_focus_team),
		"serial": _scenario_serial
	}


func _apply_scenario(scenario: StringName, focus_team: StringName) -> void:
	_reset_runtime_state()
	var is_kickoff_drill: bool = scenario in [
		SCENARIO_KICKOFF_ATTACK,
		SCENARIO_KICKOFF_DEFENSE,
	]
	# Ordinary drills are synthetic active-possession states. Kickoff drills are
	# intentionally the opposite: they preserve the real kickoff gate so the
	# live 1v1 kickoff strategy is what gets trained instead of a fake shortcut.
	_manager.set("_match_clock_waiting_for_kickoff", is_kickoff_drill)
	match scenario:
		SCENARIO_TWO_V_ONE:
			_apply_two_v_one(focus_team)
		SCENARIO_ONE_V_ONE_WALL:
			_apply_one_v_one_wall(focus_team)
		SCENARIO_OPEN_REBOUND:
			_apply_open_rebound(focus_team)
		SCENARIO_LAST_MAN_DEFENSE:
			_apply_last_man_defense(focus_team)
		SCENARIO_CROSS_FAR_POST:
			_apply_cross_far_post(focus_team)
		SCENARIO_KEEPER_DISTRIBUTION:
			_apply_keeper_distribution(focus_team)
		SCENARIO_BLOCKED_SHOOTING_LANE:
			_apply_blocked_shooting_lane(focus_team)
		SCENARIO_KICKOFF_ATTACK:
			_apply_kickoff_attack(focus_team)
		SCENARIO_KICKOFF_DEFENSE:
			_apply_kickoff_defense(focus_team)
		SCENARIO_CENTRAL_DUEL:
			_apply_central_duel(focus_team)
		SCENARIO_PRESSURE_ESCAPE:
			_apply_pressure_escape(focus_team)
		SCENARIO_FINISHING_DUEL:
			_apply_finishing_duel(focus_team)
		SCENARIO_WALL_ESCAPE:
			_apply_wall_escape(focus_team)
		SCENARIO_WALL_ANGLE_CREATION:
			_apply_wall_angle_creation(focus_team)
		SCENARIO_CROWDED_WALL_BREAKOUT:
			_apply_crowded_wall_breakout(focus_team)
		SCENARIO_REBOUND_CHAOS:
			_apply_rebound_chaos(focus_team)
		SCENARIO_THREADED_PASS_FINISH:
			_apply_threaded_pass_finish(focus_team)
		_:
			_apply_two_v_one(focus_team)


func _reset_runtime_state() -> void:
	if _manager.has_method("clear_cpu_tactical_state"):
		_manager.call("clear_cpu_tactical_state")
	else:
		for property_name in [
			"_cpu_ball_commitments",
			"_cpu_tactical_intentions",
			"_cpu_pass_intentions",
			"_cpu_combination_plans"
		]:
			var value: Variant = _manager.get(property_name)
			if value is Dictionary:
				(value as Dictionary).clear()
	for team in [TEAM_BLUE, TEAM_RED]:
		for player in _get_team_players(team):
			if not is_instance_valid(player):
				continue
			player.set_controls_enabled(true)
			var controller: Node = player.get_node_or_null("CPUController")
			if controller != null and controller.has_method("reset_hybrid_episode"):
				controller.call("reset_hybrid_episode")


func _apply_two_v_one(focus_team: StringName) -> void:
	var attackers: Array = _get_outfield_players(focus_team)
	var defenders: Array = _get_outfield_players(_other_team(focus_team))
	var attacking_keeper: Node = _get_keeper(focus_team)
	var defending_keeper: Node = _get_keeper(_other_team(focus_team))
	var ball_position: Vector2 = _from_attacking_frame(Vector2(3550.0, 2500.0), focus_team)
	_place_player(_at(attackers, 0), _from_attacking_frame(Vector2(3420.0, 2500.0), focus_team))
	_place_player(_at(attackers, 1), _from_attacking_frame(Vector2(3920.0, 1580.0 if _side_sign < 0.0 else 3420.0), focus_team))
	_place_player(_at(attackers, 2), _from_attacking_frame(Vector2(3050.0, 3500.0 if _side_sign < 0.0 else 1500.0), focus_team))
	_place_player(_at(defenders, 0), _from_attacking_frame(Vector2(4400.0, 2500.0), focus_team))
	# Keep the drill a genuine 2v1 (goalkeeper excluded from the outfield count).
	_park_player(_at(defenders, 1), _from_attacking_frame(Vector2(3000.0, 4050.0), focus_team))
	_park_player(_at(defenders, 2), _from_attacking_frame(Vector2(3000.0, 950.0), focus_team))
	_place_keeper(attacking_keeper, focus_team, true)
	_place_keeper(defending_keeper, _other_team(focus_team), true)
	_place_ball(ball_position, Vector2.ZERO, _at(attackers, 0), focus_team)


func _apply_one_v_one_wall(focus_team: StringName) -> void:
	var attackers: Array = _get_outfield_players(focus_team)
	var defenders: Array = _get_outfield_players(_other_team(focus_team))
	var wall_y: float = 990.0 if _side_sign < 0.0 else 4010.0
	var support_y: float = 3650.0 if _side_sign < 0.0 else 1350.0
	var ball_position: Vector2 = _from_attacking_frame(Vector2(3850.0, wall_y), focus_team)
	_place_player(_at(attackers, 0), _from_attacking_frame(Vector2(3720.0, wall_y + (120.0 * -_side_sign)), focus_team))
	_place_player(_at(defenders, 0), _from_attacking_frame(Vector2(4380.0, wall_y + (190.0 * -_side_sign)), focus_team))
	_park_player(_at(attackers, 1), _from_attacking_frame(Vector2(3050.0, support_y), focus_team))
	_park_player(_at(defenders, 1), _from_attacking_frame(Vector2(5200.0, support_y), focus_team))
	_park_remaining_players(focus_team, attackers, 2, Vector2(3000.0, 2500.0))
	_park_remaining_players(_other_team(focus_team), defenders, 2, Vector2(5400.0, 2500.0))
	_place_keeper(_get_keeper(focus_team), focus_team, true)
	_place_keeper(_get_keeper(_other_team(focus_team)), _other_team(focus_team), true)
	_place_ball(ball_position, Vector2.ZERO, _at(attackers, 0), focus_team)


func _apply_open_rebound(focus_team: StringName) -> void:
	var attackers: Array = _get_outfield_players(focus_team)
	var defenders: Array = _get_outfield_players(_other_team(focus_team))
	var ball_position: Vector2 = _from_attacking_frame(Vector2(5730.0, 2050.0 if _side_sign < 0.0 else 2950.0), focus_team)
	var velocity: Vector2 = _from_attacking_velocity(Vector2(2050.0, 720.0 * _side_sign), focus_team)
	_place_player(_at(attackers, 0), _from_attacking_frame(Vector2(5280.0, 2920.0 if _side_sign < 0.0 else 2080.0), focus_team))
	_place_player(_at(attackers, 1), _from_attacking_frame(Vector2(5000.0, 1900.0 if _side_sign < 0.0 else 3100.0), focus_team))
	_place_player(_at(defenders, 0), _from_attacking_frame(Vector2(5900.0, 2500.0), focus_team))
	_park_player(_at(defenders, 1), _from_attacking_frame(Vector2(3950.0, 4050.0 if _side_sign < 0.0 else 950.0), focus_team))
	_place_keeper(_get_keeper(focus_team), focus_team, true)
	_place_keeper(_get_keeper(_other_team(focus_team)), _other_team(focus_team), true)
	_place_ball(ball_position, velocity, null, NO_TEAM)


func _apply_last_man_defense(focus_team: StringName) -> void:
	var attackers: Array = _get_outfield_players(focus_team)
	var defenders: Array = _get_outfield_players(_other_team(focus_team))
	var ball_position: Vector2 = _from_attacking_frame(Vector2(5050.0, 2500.0), focus_team)
	_place_player(_at(attackers, 0), _from_attacking_frame(Vector2(4900.0, 2500.0), focus_team))
	_park_player(_at(attackers, 1), _from_attacking_frame(Vector2(3550.0, 1050.0 if _side_sign < 0.0 else 3950.0), focus_team))
	_place_player(_at(defenders, 0), _from_attacking_frame(Vector2(5650.0, 2500.0), focus_team))
	_park_player(_at(defenders, 1), _from_attacking_frame(Vector2(3500.0, 3950.0 if _side_sign < 0.0 else 1050.0), focus_team))
	_place_keeper(_get_keeper(focus_team), focus_team, true)
	_place_keeper(_get_keeper(_other_team(focus_team)), _other_team(focus_team), true)
	_place_ball(ball_position, Vector2.ZERO, _at(attackers, 0), focus_team)


func _apply_cross_far_post(focus_team: StringName) -> void:
	var attackers: Array = _get_outfield_players(focus_team)
	var defenders: Array = _get_outfield_players(_other_team(focus_team))
	var near_y: float = 1060.0 if _side_sign < 0.0 else 3940.0
	var far_y: float = 3400.0 if _side_sign < 0.0 else 1600.0
	var ball_position: Vector2 = _from_attacking_frame(Vector2(5550.0, near_y), focus_team)
	_place_player(_at(attackers, 0), _from_attacking_frame(Vector2(5420.0, near_y), focus_team))
	_place_player(_at(attackers, 1), _from_attacking_frame(Vector2(6020.0, far_y), focus_team))
	_place_player(_at(attackers, 2), _from_attacking_frame(Vector2(5150.0, 2500.0), focus_team))
	_place_player(_at(defenders, 0), _from_attacking_frame(Vector2(5900.0, 2320.0), focus_team))
	_place_player(_at(defenders, 1), _from_attacking_frame(Vector2(6150.0, far_y - 260.0 * _side_sign), focus_team))
	_place_keeper(_get_keeper(focus_team), focus_team, true)
	_place_keeper(_get_keeper(_other_team(focus_team)), _other_team(focus_team), true)
	_place_ball(ball_position, Vector2.ZERO, _at(attackers, 0), focus_team)


func _apply_keeper_distribution(focus_team: StringName) -> void:
	var attackers: Array = _get_outfield_players(focus_team)
	var opponents: Array = _get_outfield_players(_other_team(focus_team))
	var keeper: Node = _get_keeper(focus_team)
	var keeper_position: Vector2 = _from_attacking_frame(Vector2(760.0, 2500.0), focus_team)
	_place_player(keeper, keeper_position)
	_place_player(_at(attackers, 0), _from_attacking_frame(Vector2(1800.0, 1350.0), focus_team))
	_place_player(_at(attackers, 1), _from_attacking_frame(Vector2(1900.0, 3650.0), focus_team))
	_place_player(_at(attackers, 2), _from_attacking_frame(Vector2(2550.0, 2500.0), focus_team))
	_place_player(_at(opponents, 0), _from_attacking_frame(Vector2(2050.0, 2500.0), focus_team))
	_place_player(_at(opponents, 1), _from_attacking_frame(Vector2(2750.0, 1500.0), focus_team))
	_place_player(_at(opponents, 2), _from_attacking_frame(Vector2(2850.0, 3500.0), focus_team))
	_place_keeper(_get_keeper(_other_team(focus_team)), _other_team(focus_team), true)
	_place_ball(keeper_position + Vector2(_attack_sign(focus_team) * 165.0, 0.0), Vector2.ZERO, keeper, focus_team)


func _apply_kickoff_attack(focus_team: StringName) -> void:
	var attacking_players: Array = _get_team_players(focus_team)
	var defending_team: StringName = _other_team(focus_team)
	var defending_players: Array = _get_team_players(defending_team)
	var attacker: Node = _at(attacking_players, 0)
	var defender: Node = _at(defending_players, 0)
	var attack_sign: float = _attack_sign(focus_team)
	# Cycle several dangerous human-style approach lanes so the policy cannot
	# memorize one center-line answer. The evaluated attacker gets a small race
	# advantage and must learn how to turn kickoff possession into a real chance.
	var lane_choices: Array[float] = [-330.0, -190.0, -80.0, 80.0, 190.0, 330.0]
	var lane: float = lane_choices[_rng.randi_range(0, lane_choices.size() - 1)]
	var attacker_position := FIELD_CENTER + Vector2(-attack_sign * 520.0, lane)
	var defender_position := FIELD_CENTER + Vector2(attack_sign * 610.0, -lane * 0.72)
	_place_player(attacker, attacker_position)
	_place_player(defender, defender_position)
	for index in range(1, attacking_players.size()):
		_park_player(attacking_players[index], _from_attacking_frame(Vector2(1650.0, 1100.0 + index * 560.0), focus_team))
	for index in range(1, defending_players.size()):
		_park_player(defending_players[index], _from_attacking_frame(Vector2(5650.0, 1100.0 + index * 560.0), focus_team))
	_place_ball(FIELD_CENTER, Vector2.ZERO, null, NO_TEAM)


func _apply_kickoff_defense(focus_team: StringName) -> void:
	var defending_players: Array = _get_team_players(focus_team)
	var attacking_team: StringName = _other_team(focus_team)
	var attacking_players: Array = _get_team_players(attacking_team)
	var defender: Node = _at(defending_players, 0)
	var attacker: Node = _at(attacking_players, 0)
	var attack_sign: float = _attack_sign(attacking_team)
	# Recreate the vulnerable 1v1 state where an opponent can repeatedly rush the
	# same diagonal kickoff angle. The attacker starts slightly favored, forcing
	# the defending policy to learn interception, delayed challenge and recovery.
	var lane_choices: Array[float] = [-380.0, -240.0, -120.0, 120.0, 240.0, 380.0]
	var lane: float = lane_choices[_rng.randi_range(0, lane_choices.size() - 1)]
	var attacker_position := FIELD_CENTER + Vector2(-attack_sign * 485.0, lane)
	var defender_position := FIELD_CENTER + Vector2(attack_sign * 640.0, -lane * 0.58)
	_place_player(attacker, attacker_position)
	_place_player(defender, defender_position)
	for index in range(1, attacking_players.size()):
		_park_player(attacking_players[index], _from_attacking_frame(Vector2(1650.0, 1100.0 + index * 560.0), attacking_team))
	for index in range(1, defending_players.size()):
		_park_player(defending_players[index], _from_attacking_frame(Vector2(1650.0, 1100.0 + index * 560.0), focus_team))
	_place_ball(FIELD_CENTER, Vector2.ZERO, null, NO_TEAM)


func _park_extra_duel_players(players: Array, start_index: int) -> void:
	for index in range(start_index, players.size()):
		var player: Node = players[index]
		if not is_instance_valid(player):
			continue
		var parking_y: float = 900.0 + float(index) * 520.0
		_park_player(player, Vector2(3675.0, parking_y))


func _apply_central_duel(focus_team: StringName) -> void:
	# Neutral central possession against one live defender. This directly trains
	# the ordinary 1v1 state that G001 still struggled with against original_1v1.
	var attackers: Array = _get_team_players(focus_team)
	var defending_team: StringName = _other_team(focus_team)
	var defenders: Array = _get_team_players(defending_team)
	var attacker: Node = _at(attackers, 0)
	var defender: Node = _at(defenders, 0)
	if not is_instance_valid(attacker) or not is_instance_valid(defender):
		return

	var lane_choices: Array[float] = [1650.0, 2050.0, 2500.0, 2950.0, 3350.0]
	var lane: float = lane_choices[_rng.randi_range(0, lane_choices.size() - 1)]
	var defender_y: float = 2500.0 + (lane - 2500.0) * 0.42
	var attacker_position: Vector2 = _from_attacking_frame(
		Vector2(3650.0, lane),
		focus_team
	)
	var defender_position: Vector2 = _from_attacking_frame(
		Vector2(4380.0, defender_y),
		focus_team
	)
	var ball_position: Vector2 = attacker_position + Vector2(
		_attack_sign(focus_team) * 145.0,
		0.0
	)

	_place_player(attacker, attacker_position)
	_place_player(defender, defender_position)
	_park_extra_duel_players(attackers, 1)
	_park_extra_duel_players(defenders, 1)
	_place_ball(ball_position, Vector2.ZERO, attacker, focus_team)


func _apply_pressure_escape(focus_team: StringName) -> void:
	# Tight pressure near a wall/half-space. G001's opponent-pool telemetry showed
	# counterpress and solo-duel specialists among its most difficult opponents.
	var attackers: Array = _get_team_players(focus_team)
	var defending_team: StringName = _other_team(focus_team)
	var defenders: Array = _get_team_players(defending_team)
	var attacker: Node = _at(attackers, 0)
	var defender: Node = _at(defenders, 0)
	if not is_instance_valid(attacker) or not is_instance_valid(defender):
		return

	var upper_side: bool = (_scenario_serial % 2) == 0
	var lane: float = 1260.0 if upper_side else 3740.0
	var side_offset: float = 175.0 if upper_side else -175.0
	var attacker_position: Vector2 = _from_attacking_frame(
		Vector2(3450.0, lane),
		focus_team
	)
	var defender_position: Vector2 = _from_attacking_frame(
		Vector2(3790.0, lane + side_offset),
		focus_team
	)
	var ball_position: Vector2 = attacker_position + Vector2(
		_attack_sign(focus_team) * 125.0,
		0.0
	)

	_place_player(attacker, attacker_position)
	_place_player(defender, defender_position)
	_park_extra_duel_players(attackers, 1)
	_park_extra_duel_players(defenders, 1)
	_place_ball(ball_position, Vector2.ZERO, attacker, focus_team)


func _apply_finishing_duel(focus_team: StringName) -> void:
	# Repeated high-value finishing situations with one defender between the
	# carrier and goal. G001 generated many shots but failed to score in either
	# original_1v1 benchmark match, so G002 needs conversion quality, not volume.
	var attackers: Array = _get_team_players(focus_team)
	var defending_team: StringName = _other_team(focus_team)
	var defenders: Array = _get_team_players(defending_team)
	var attacker: Node = _at(attackers, 0)
	var defender: Node = _at(defenders, 0)
	if not is_instance_valid(attacker) or not is_instance_valid(defender):
		return

	var lane_choices: Array[float] = [1700.0, 2150.0, 2850.0, 3300.0]
	var lane: float = lane_choices[_rng.randi_range(0, lane_choices.size() - 1)]
	var defender_y: float = 2500.0 + (lane - 2500.0) * 0.28
	var attacker_position: Vector2 = _from_attacking_frame(
		Vector2(4930.0, lane),
		focus_team
	)
	var defender_position: Vector2 = _from_attacking_frame(
		Vector2(5520.0, defender_y),
		focus_team
	)
	var ball_position: Vector2 = attacker_position + Vector2(
		_attack_sign(focus_team) * 140.0,
		0.0
	)

	_place_player(attacker, attacker_position)
	_place_player(defender, defender_position)
	_park_extra_duel_players(attackers, 1)
	_park_extra_duel_players(defenders, 1)
	_place_ball(ball_position, Vector2.ZERO, attacker, focus_team)


func _apply_blocked_shooting_lane(focus_team: StringName) -> void:
	var attackers: Array = _get_outfield_players(focus_team)
	var defenders: Array = _get_outfield_players(_other_team(focus_team))
	var ball_position: Vector2 = _from_attacking_frame(Vector2(4700.0, 2500.0), focus_team)
	_place_player(_at(attackers, 0), _from_attacking_frame(Vector2(4560.0, 2500.0), focus_team))
	_place_player(_at(defenders, 0), _from_attacking_frame(Vector2(5200.0, 2500.0), focus_team))
	_place_player(_at(attackers, 1), _from_attacking_frame(Vector2(5000.0, 1350.0 if _side_sign < 0.0 else 3650.0), focus_team))
	_place_player(_at(attackers, 2), _from_attacking_frame(Vector2(3920.0, 3300.0 if _side_sign < 0.0 else 1700.0), focus_team))
	_place_player(_at(defenders, 1), _from_attacking_frame(Vector2(5550.0, 1550.0 if _side_sign < 0.0 else 3450.0), focus_team))
	_place_keeper(_get_keeper(focus_team), focus_team, true)
	_place_keeper(_get_keeper(_other_team(focus_team)), _other_team(focus_team), true)
	_place_ball(ball_position, Vector2.ZERO, _at(attackers, 0), focus_team)


func _apply_wall_escape(focus_team: StringName) -> void:
	# Give the carrier a genuine choice: the direct lane is pressured, while the
	# nearby wall opens a self-pass lane and any available teammate remains a
	# valid alternative. Nothing in the drill forces the wall action itself.
	var attackers: Array = _get_outfield_players(focus_team)
	var defenders: Array = _get_outfield_players(_other_team(focus_team))
	var upper_side: bool = _side_sign < 0.0
	var wall_y: float = 1040.0 if upper_side else 3960.0
	var inside_sign: float = 1.0 if upper_side else -1.0
	var carrier_position := _from_attacking_frame(
		Vector2(3500.0, wall_y + 150.0 * inside_sign),
		focus_team
	)
	var defender_position := _from_attacking_frame(
		Vector2(3890.0, wall_y + 265.0 * inside_sign),
		focus_team
	)
	_place_player(_at(attackers, 0), carrier_position)
	_place_player(_at(defenders, 0), defender_position)
	_place_player(
		_at(attackers, 1),
		_from_attacking_frame(
			Vector2(4160.0, 2360.0 if upper_side else 2640.0),
			focus_team
		)
	)
	_place_player(
		_at(defenders, 1),
		_from_attacking_frame(
			Vector2(4550.0, 2500.0),
			focus_team
		)
	)
	_park_remaining_players(focus_team, attackers, 2, Vector2(3000.0, 3550.0))
	_park_remaining_players(
		_other_team(focus_team),
		defenders,
		2,
		Vector2(5200.0, 1450.0)
	)
	_place_keeper(_get_keeper(focus_team), focus_team, true)
	_place_keeper(_get_keeper(_other_team(focus_team)), _other_team(focus_team), true)
	var ball_position := carrier_position + Vector2(
		_attack_sign(focus_team) * 135.0,
		0.0
	)
	_place_ball(ball_position, Vector2.ZERO, _at(attackers, 0), focus_team)


func _apply_wall_angle_creation(focus_team: StringName) -> void:
	# An attacking-third state where the obvious central shot is screened. The
	# policy can bank a shot, create a new angle with a wall self-pass, combine
	# with a teammate, or reset if those routes are actually unsafe.
	var attackers: Array = _get_outfield_players(focus_team)
	var defenders: Array = _get_outfield_players(_other_team(focus_team))
	var upper_side: bool = _side_sign < 0.0
	var carrier_y: float = 1320.0 if upper_side else 3680.0
	var inside_y: float = 1880.0 if upper_side else 3120.0
	var support_y: float = 3000.0 if upper_side else 2000.0
	var carrier_position := _from_attacking_frame(
		Vector2(4820.0, carrier_y),
		focus_team
	)
	_place_player(_at(attackers, 0), carrier_position)
	_place_player(
		_at(defenders, 0),
		_from_attacking_frame(Vector2(5380.0, inside_y), focus_team)
	)
	_place_player(
		_at(attackers, 1),
		_from_attacking_frame(Vector2(5100.0, support_y), focus_team)
	)
	_place_player(
		_at(defenders, 1),
		_from_attacking_frame(
			Vector2(5830.0, 2480.0 if upper_side else 2520.0),
			focus_team
		)
	)
	_park_remaining_players(focus_team, attackers, 2, Vector2(4020.0, 3550.0))
	_park_remaining_players(
		_other_team(focus_team),
		defenders,
		2,
		Vector2(6100.0, 1450.0)
	)
	_place_keeper(_get_keeper(focus_team), focus_team, true)
	_place_keeper(_get_keeper(_other_team(focus_team)), _other_team(focus_team), true)
	var ball_position := carrier_position + Vector2(
		_attack_sign(focus_team) * 135.0,
		0.0
	)
	_place_ball(ball_position, Vector2.ZERO, _at(attackers, 0), focus_team)


func _apply_crowded_wall_breakout(focus_team: StringName) -> void:
	# Team-mode pressure cluster. The wall is useful, but so are a central release,
	# a switch, a one-two, or a reset. This is deliberately an open tactical
	# problem so self-play can discover new sequences instead of memorizing one.
	var attackers: Array = _get_outfield_players(focus_team)
	var defenders: Array = _get_outfield_players(_other_team(focus_team))
	var upper_side: bool = _side_sign < 0.0
	var wall_y: float = 1120.0 if upper_side else 3880.0
	var inside_sign: float = 1.0 if upper_side else -1.0
	var carrier_position := _from_attacking_frame(
		Vector2(3500.0, wall_y + 130.0 * inside_sign),
		focus_team
	)
	_place_player(_at(attackers, 0), carrier_position)
	_place_player(
		_at(defenders, 0),
		_from_attacking_frame(
			Vector2(3830.0, wall_y + 220.0 * inside_sign),
			focus_team
		)
	)
	_place_player(
		_at(defenders, 1),
		_from_attacking_frame(
			Vector2(3670.0, wall_y + 720.0 * inside_sign),
			focus_team
		)
	)
	_place_player(
		_at(attackers, 1),
		_from_attacking_frame(Vector2(4200.0, 2500.0), focus_team)
	)
	_place_player(
		_at(attackers, 2),
		_from_attacking_frame(
			Vector2(4580.0, 3430.0 if upper_side else 1570.0),
			focus_team
		)
	)
	_park_remaining_players(focus_team, attackers, 3, Vector2(3050.0, 2500.0))
	_park_remaining_players(
		_other_team(focus_team),
		defenders,
		2,
		Vector2(5300.0, 2500.0)
	)
	_place_keeper(_get_keeper(focus_team), focus_team, true)
	_place_keeper(_get_keeper(_other_team(focus_team)), _other_team(focus_team), true)
	var ball_position := carrier_position + Vector2(
		_attack_sign(focus_team) * 135.0,
		0.0
	)
	_place_ball(ball_position, Vector2.ZERO, _at(attackers, 0), focus_team)


func _apply_threaded_pass_finish(focus_team: StringName) -> void:
	# Team-only chance-creation drill based on the user's clip:
	# a passer has a narrow but real lane BETWEEN two defenders to a teammate
	# already arriving in finishing range. The receiver is not scripted to shoot;
	# the normal first-touch / fast-follow-up logic must recognize the chance.
	#
	# This deliberately uses the existing line-breaking-pass + goal/chance
	# rewards instead of hardcoding the exact combo as a required action.
	var attackers: Array = _get_outfield_players(focus_team)
	var defenders: Array = _get_outfield_players(_other_team(focus_team))
	if attackers.size() < 2 or defenders.size() < 2:
		_apply_two_v_one(focus_team)
		return

	var passer := _at(attackers, 0)
	var receiver := _at(attackers, 1)
	var passer_position := _from_attacking_frame(
		Vector2(4260.0, 2500.0),
		focus_team
	)
	var receiver_y: float = 2460.0 if _side_sign < 0.0 else 2540.0
	var receiver_position := _from_attacking_frame(
		Vector2(5480.0, receiver_y),
		focus_team
	)

	_place_player(
		_at(defenders, 0),
		_from_attacking_frame(Vector2(4770.0, 2150.0), focus_team)
	)
	_place_player(
		_at(defenders, 1),
		_from_attacking_frame(Vector2(4920.0, 2860.0), focus_team)
	)
	_place_player(passer, passer_position)
	_place_player(receiver, receiver_position)

	_place_player(
		_at(attackers, 2),
		_from_attacking_frame(
			Vector2(5050.0, 3420.0 if _side_sign < 0.0 else 1580.0),
			focus_team
		)
	)
	_park_remaining_players(focus_team, attackers, 3, Vector2(3550.0, 3600.0))
	_park_remaining_players(
		_other_team(focus_team),
		defenders,
		2,
		Vector2(6000.0, 1450.0)
	)

	_place_keeper(_get_keeper(focus_team), focus_team, true)
	_place_keeper(
		_get_keeper(_other_team(focus_team)),
		_other_team(focus_team),
		true
	)
	var ball_position := passer_position + Vector2(
		_attack_sign(focus_team) * 135.0,
		0.0
	)
	_place_ball(ball_position, Vector2.ZERO, passer, focus_team)


func _apply_rebound_chaos(focus_team: StringName) -> void:
	# A live second-ball state that is about to bounce off a side wall. Both
	# teams must predict the rebound, decide whether to challenge or hold shape,
	# and immediately convert the recovery into the best available next action.
	var attackers: Array = _get_outfield_players(focus_team)
	var defenders: Array = _get_outfield_players(_other_team(focus_team))
	var upper_side: bool = _side_sign < 0.0
	var ball_y: float = 1015.0 if upper_side else 3985.0
	var wall_velocity_y: float = -980.0 if upper_side else 980.0
	var ball_position := _from_attacking_frame(
		Vector2(4930.0, ball_y),
		focus_team
	)
	var ball_velocity := _from_attacking_velocity(
		Vector2(1450.0, wall_velocity_y),
		focus_team
	)
	_place_player(
		_at(attackers, 0),
		_from_attacking_frame(
			Vector2(4550.0, 1590.0 if upper_side else 3410.0),
			focus_team
		)
	)
	_place_player(
		_at(defenders, 0),
		_from_attacking_frame(
			Vector2(5200.0, 1680.0 if upper_side else 3320.0),
			focus_team
		)
	)
	_place_player(
		_at(attackers, 1),
		_from_attacking_frame(
			Vector2(5320.0, 2640.0 if upper_side else 2360.0),
			focus_team
		)
	)
	_place_player(
		_at(defenders, 1),
		_from_attacking_frame(
			Vector2(5570.0, 2500.0),
			focus_team
		)
	)
	_park_remaining_players(focus_team, attackers, 2, Vector2(3650.0, 3550.0))
	_park_remaining_players(
		_other_team(focus_team),
		defenders,
		2,
		Vector2(6000.0, 1450.0)
	)
	_place_keeper(_get_keeper(focus_team), focus_team, true)
	_place_keeper(_get_keeper(_other_team(focus_team)), _other_team(focus_team), true)
	_place_ball(ball_position, ball_velocity, null, NO_TEAM)


func _get_team_players(team: StringName) -> Array:
	if _manager == null:
		return []
	var source: Variant = _manager.get("blue_players") if team == TEAM_BLUE else _manager.get("red_players")
	var result: Array = []
	if source is Array:
		for player in source as Array:
			if is_instance_valid(player):
				result.append(player)
	result.sort_custom(func(a: Node, b: Node) -> bool:
		return int(a.get("owner_peer_id")) < int(b.get("owner_peer_id"))
	)
	return result


func _get_keeper(team: StringName) -> Node:
	if _manager != null and _manager.has_method("get_designated_cpu_goalkeeper"):
		var keeper: Variant = _manager.call("get_designated_cpu_goalkeeper", team)
		if is_instance_valid(keeper):
			return keeper
	var players: Array = _get_team_players(team)
	return players[0] if not players.is_empty() else null


func _get_outfield_players(team: StringName) -> Array:
	var players: Array = _get_team_players(team)
	# In 1v1 the sole CPU is also the tactical "designated goalkeeper". Scenario
	# drills still need that player to act as the attacker/defender, so only strip
	# the keeper when there is a separate teammate available.
	if players.size() <= 1:
		return players
	var keeper: Node = _get_keeper(team)
	var result: Array = []
	for player in players:
		if player != keeper:
			result.append(player)
	return result


func _place_player(player: Node, position: Vector2) -> void:
	if not is_instance_valid(player):
		return
	var safe_position: Vector2 = Vector2(
		clampf(position.x, FIELD_BOUNDS.position.x + 90.0, FIELD_BOUNDS.end.x - 90.0),
		clampf(position.y, FIELD_BOUNDS.position.y + 90.0, FIELD_BOUNDS.end.y - 90.0)
	)
	if player.has_method("reset_to_position"):
		player.call("reset_to_position", safe_position)
	else:
		player.set("global_position", safe_position)
		player.set("linear_velocity", Vector2.ZERO)
	if player.has_method("set_controls_enabled"):
		player.call("set_controls_enabled", true)


func _place_keeper(keeper: Node, team: StringName, normal_depth: bool) -> void:
	if not is_instance_valid(keeper):
		return
	# A 1v1 side has no separate goalkeeper to park; moving its only player here
	# would silently destroy the synthetic attacking/defending drill.
	if _get_team_players(team).size() <= 1:
		return
	var canonical_x: float = 720.0 if normal_depth else 980.0
	_place_player(keeper, _from_attacking_frame(Vector2(canonical_x, 2500.0), team))


func _park_player(player: Node, position: Vector2) -> void:
	if not is_instance_valid(player):
		return
	_place_player(player, position)
	if player.has_method("set_controls_enabled"):
		player.call("set_controls_enabled", false)


func _park_remaining_players(
	team: StringName,
	players: Array,
	start_index: int,
	canonical_anchor: Vector2
) -> void:
	for index in range(start_index, players.size()):
		var lane_offset: float = float(index - start_index) * 520.0
		var target: Vector2 = canonical_anchor + Vector2(-lane_offset, lane_offset * _side_sign)
		_park_player(players[index], _from_attacking_frame(target, team))


func _place_remaining_players(
	team: StringName,
	players: Array,
	start_index: int,
	canonical_anchor: Vector2
) -> void:
	for index in range(start_index, players.size()):
		var lane_offset: float = float(index - start_index) * 520.0
		var target: Vector2 = canonical_anchor + Vector2(-lane_offset, lane_offset * _side_sign)
		_place_player(players[index], _from_attacking_frame(target, team))


func _place_ball(
	position: Vector2,
	velocity: Vector2,
	owner: Node,
	owner_team: StringName
) -> void:
	var ball: Node = _manager.get("ball") if _manager != null else null
	if not is_instance_valid(ball):
		return
	if ball.has_method("reset_ball"):
		ball.call("reset_ball", position)
	else:
		ball.set("global_position", position)
	ball.set("linear_velocity", velocity)
	ball.set("sleeping", false)
	if is_instance_valid(owner) and owner_team in [TEAM_BLUE, TEAM_RED]:
		var peer_id: int = int(owner.get("owner_peer_id"))
		var display_name: String = str(owner.get("display_name"))
		# Seed possession without emitting a synthetic touch event into telemetry.
		ball.set("last_touch_peer_id", peer_id)
		ball.set("last_touch_name", display_name)
		ball.set("last_touch_team", owner_team)
		ball.set("last_touch_kind", &"scenario_control")
		ball.set("last_touch_was_cpu", true)
		if _manager.has_method("_update_cpu_possession_from_touch"):
			_manager.call("_update_cpu_possession_from_touch", peer_id, owner_team)
	else:
		# Neutral scenarios, especially kickoffs, must not inherit possession from
		# the previous drill or the kickoff policy will reason from stale ownership.
		ball.set("last_touch_peer_id", 0)
		ball.set("last_touch_name", "")
		ball.set("last_touch_team", NO_TEAM)
		ball.set("last_touch_kind", &"scenario_neutral")
		ball.set("last_touch_was_cpu", false)
		if _manager.get("_cpu_possession_team") != null:
			_manager.set("_cpu_possession_team", NO_TEAM)


func _at(players: Array, index: int) -> Node:
	return players[index] if index >= 0 and index < players.size() else null


func _other_team(team: StringName) -> StringName:
	return TEAM_RED if team == TEAM_BLUE else TEAM_BLUE


func _attack_sign(team: StringName) -> float:
	return 1.0 if team == TEAM_BLUE else -1.0


func _from_attacking_frame(position: Vector2, team: StringName) -> Vector2:
	if team == TEAM_BLUE:
		return position
	return Vector2(FIELD_CENTER.x * 2.0 - position.x, position.y)


func _from_attacking_velocity(velocity: Vector2, team: StringName) -> Vector2:
	if team == TEAM_BLUE:
		return velocity
	return Vector2(-velocity.x, velocity.y)
