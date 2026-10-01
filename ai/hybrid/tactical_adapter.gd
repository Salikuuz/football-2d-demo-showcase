class_name HybridTacticalAdapter
extends RefCounted


const Schema := preload("res://ai/hybrid/tactical_schema.gd")
const ObservationBuilder := preload("res://ai/hybrid/tactical_observation_builder.gd")
const Policy := preload("res://ai/hybrid/tactical_policy.gd")
const CheckpointStore := preload("res://ai/hybrid/checkpoint_store.gd")

const LEGACY_INTENT_IDLE: StringName = &"idle"
const LEGACY_INTENT_CHASE: StringName = &"chase_ball"
const LEGACY_INTENT_DRIBBLE: StringName = &"dribble"
const LEGACY_INTENT_SHOOT: StringName = &"shoot"
const LEGACY_INTENT_PASS: StringName = &"pass"
const LEGACY_INTENT_COVER: StringName = &"cover"
const LEGACY_INTENT_WIDE_SUPPORT: StringName = &"wide_support"
const LEGACY_INTENT_MARK: StringName = &"mark"

# Rocket-League-style anti-stall defense:
# sell pressure, preserve a goal-side escape, then react to the carrier.
const STALL_DETECTION_SECONDS: float = 0.42
const STALL_FULL_STRENGTH_SECONDS: float = 1.15
const STALL_CARRIER_MAX_SPEED: float = 170.0
const STALL_BALL_MAX_SPEED: float = 220.0
const STALL_INPUT_MAXIMUM: float = 0.18
const STALL_SAMPLE_MOVEMENT_TOLERANCE: float = 34.0
const STALL_PROBE_MINIMUM_DISTANCE: float = 285.0
const STALL_NEAR_GOAL_PROBE_DISTANCE: float = 410.0
const STALL_ESCALATION_SECONDS: float = 1.20
const STALL_ESCALATION_DISTANCE: float = 1080.0
const STALL_LIVE_COMMIT_THRESHOLD: float = 0.52
const ONE_V_ONE_STALL_CLOSE_SECONDS: float = 0.62
const ONE_V_ONE_STALL_FORCE_SECONDS: float = 1.75
const ONE_V_ONE_STALL_FORCE_DISTANCE: float = 920.0
const ONE_V_ONE_STALL_MAXIMUM_PASSIVE_GAP: float = 760.0
const ONE_V_ONE_STALL_ATTACKING_GOAL_GAP: float = 335.0
const ONE_V_ONE_STALL_MIDFIELD_GAP: float = 470.0
const ONE_V_ONE_STALL_DEFENSIVE_GOAL_GAP: float = 560.0

static var _runtime_checkpoint_cache: Dictionary = {}

var _controller: Node
var _policy := Policy.new()
var _checkpoint_path: String = CheckpointStore.DEFAULT_ACTIVE_PATH
var _checkpoint_metadata: Dictionary = {}
var _enabled: bool = true
var _training_mode: bool = false
var _exploration_override: float = -1.0
var _decision_interval: float = 0.12
var _next_decision_at: float = 0.0
var _active_decision: Dictionary = {}
var _active_until: float = 0.0
var _fallback_active: bool = false
var _fallback_reason: String = ""
var _fallback_count: int = 0
var _decision_serial: int = 0
var _last_observation: Dictionary = {}
var _last_candidates: Array[Dictionary] = []
var _last_error: String = ""
var _last_defender_override_active: bool = false
var _last_defender_override_target: Vector2 = Vector2.ZERO
var _last_defender_override_reason: String = ""
var _last_defender_override_margin: float = 0.0
var _tracked_opponent_carrier_peer_id: int = 0
var _last_opponent_behavior_sample_at: float = -INF
var _last_opponent_carrier_position: Vector2 = Vector2.ZERO
var _last_observed_ball_position: Vector2 = Vector2.ZERO
var _last_opponent_carrier_velocity: Vector2 = Vector2.ZERO
var _last_observed_ball_velocity: Vector2 = Vector2.ZERO
var _opponent_stall_seconds: float = 0.0
var _opponent_stall_strength: float = 0.0
var _opponent_idle_input: float = 0.0
var _opponent_commit_signal: float = 0.0
var _opponent_stall_near_goal: bool = false
var _stall_probe_side: float = 1.0
var _last_stall_pressure_target: Vector2 = Vector2.ZERO
var _last_stall_pressure_route: String = ""
var _last_stall_pressure_mode: String = ""
var _last_team_defensive_role: StringName = &""
var _last_team_defensive_target: Vector2 = Vector2.ZERO
var _last_policy_strength: float = 1.0


func setup(
	controller: Node,
	checkpoint_path: String,
	enabled: bool,
	decision_interval: float,
	training_mode: bool = false
) -> void:
	_controller = controller
	_checkpoint_path = checkpoint_path
	_enabled = enabled
	_decision_interval = maxf(0.04, decision_interval)
	_training_mode = training_mode
	_load_active_checkpoint()


func set_enabled(value: bool) -> void:
	_enabled = value
	if not _enabled:
		clear_active_decision()


func set_training_mode(value: bool, exploration_override: float = -1.0) -> void:
	_training_mode = value
	_exploration_override = exploration_override


func apply_policy_document(document: Dictionary) -> bool:
	var policy_source := document
	if document.has("policy") and document["policy"] is Dictionary:
		policy_source = document["policy"] as Dictionary
	var accepted := _policy.set_policy_document(policy_source)
	if accepted:
		_checkpoint_metadata = document.duplicate(true)
		_checkpoint_metadata.erase("policy")
		_last_error = ""
	else:
		_last_error = "hybrid_policy_invalid"
	return accepted


func get_policy_document() -> Dictionary:
	return _policy.get_policy_document()


func clear_active_decision() -> void:
	_active_decision.clear()
	_active_until = 0.0
	_fallback_active = false
	_fallback_reason = ""


func reset_episode() -> void:
	clear_active_decision()
	_policy.reset_episode_history()
	_next_decision_at = 0.0
	_decision_serial = 0
	_reset_opponent_behavior_tracking()
	_stall_probe_side = 1.0
	_last_team_defensive_role = &""
	_last_team_defensive_target = Vector2.ZERO


func _get_effective_decision_interval() -> float:
	if _controller == null:
		return _decision_interval
	var utilization := 0.0
	if _controller.has_method("get_champion_utilization_ratio"):
		utilization = clampf(
			float(_controller.call("get_champion_utilization_ratio")),
			0.0,
			1.0
		)
	var tempo := clampf(inverse_lerp(0.55, 1.0, utilization), 0.0, 1.0)
	return lerpf(
		_decision_interval,
		0.018,
		tempo
	)


func _get_effective_commit_seconds(raw_seconds: float) -> float:
	if _controller == null:
		return raw_seconds
	var utilization := 0.0
	if _controller.has_method("get_champion_utilization_ratio"):
		utilization = clampf(
			float(_controller.call("get_champion_utilization_ratio")),
			0.0,
			1.0
		)
	var tempo := clampf(inverse_lerp(0.55, 1.0, utilization), 0.0, 1.0)
	return lerpf(raw_seconds, maxf(0.045, raw_seconds * 0.42), tempo)


func try_handle_outfield_decision() -> bool:
	if not _enabled or _controller == null:
		return false
	if not _controller_ready():
		_set_fallback("controller_not_ready")
		return false
	var now: float = _now()
	var needs_full_observation: bool = (
		_last_observation.is_empty()
		or now >= _next_decision_at
	)
	var observation_profile_started_usec: int = int(
		_controller.call("begin_runtime_subsystem_profile")
		if _controller.has_method("begin_runtime_subsystem_profile")
		else 0
	)
	var safety_observation: Dictionary = (
		ObservationBuilder.build(_controller)
		if needs_full_observation
		else ObservationBuilder.build_safety(_controller)
	)
	_augment_observation_with_opponent_behavior(
		safety_observation,
		now
	)
	if _controller.has_method("end_runtime_subsystem_profile"):
		_controller.call(
			"end_runtime_subsystem_profile",
			&"hybrid_observation",
			observation_profile_started_usec
		)
	if _try_last_defender_recovery_override(safety_observation):
		return true
	if _try_one_vs_one_stall_pressure_override(
		safety_observation,
		now
	):
		return true
	if (
		str(safety_observation.get("possession", "")) == "self"
		and float(
			safety_observation.get(
				"elite_goal_probability",
				0.0
			)
		) >= float(
			_controller.get(
				"elite_controlled_shot_probability"
			)
		)
	):
		var finish_goal: Node = _controller.call("_get_opponent_goal")
		if (
			finish_goal != null
			and bool(_controller.call(
				"_try_execute_elite_finish_scan",
				finish_goal,
				true
			))
		):
			clear_active_decision()
			return true
	_last_defender_override_active = false
	_last_defender_override_target = Vector2.ZERO
	_last_defender_override_reason = ""
	_last_defender_override_margin = 0.0
	if not _active_decision.is_empty() and now < _active_until:
		if _decision_still_valid(
			_active_decision,
			safety_observation
		):
			if _execute_decision(_active_decision):
				_fallback_active = false
				_fallback_reason = ""
				return true
		else:
			_set_fallback("committed_action_invalidated")
			clear_active_decision()
	if now < _next_decision_at:
		return false
	_next_decision_at = now + _get_effective_decision_interval()
	_last_observation = safety_observation
	if _last_observation.is_empty():
		_set_fallback("observation_build_failed")
		return false
	var candidate_profile_started_usec: int = int(
		_controller.call("begin_runtime_subsystem_profile")
		if _controller.has_method("begin_runtime_subsystem_profile")
		else 0
	)
	_last_candidates = _build_candidates(_last_observation)
	_last_policy_strength = _get_tactical_policy_strength()
	var decision := _policy.choose(
		_last_observation,
		_last_candidates,
		_training_mode,
		_exploration_override,
		_last_policy_strength
	)
	if _controller.has_method("end_runtime_subsystem_profile"):
		_controller.call(
			"end_runtime_subsystem_profile",
			&"hybrid_candidate_evaluation",
			candidate_profile_started_usec
		)
	if decision.is_empty() or not bool(decision.get("possible", false)):
		_set_fallback(str(decision.get("reason", "no_policy_decision")))
		return false
	_decision_serial += 1
	decision["serial"] = _decision_serial
	decision["selected_at"] = now
	_active_decision = decision.duplicate(true)
	_active_until = now + clampf(
		_get_effective_commit_seconds(
			float(decision.get("commit_seconds", 0.18))
		),
		0.04,
		2.4
	)
	if _execute_decision(_active_decision):
		_fallback_active = false
		_fallback_reason = ""
		_record_policy_decision(_active_decision)
		return true
	_set_fallback("mechanical_executor_rejected_%s" % str(decision.get("action", "unknown")))
	return false


func _get_tactical_policy_strength() -> float:
	# Training always sees the complete candidate policy. Runtime difficulty only
	# scales how strongly learned preferences can override the deterministic
	# football rules; it never changes physics, input accuracy, or executor power.
	if _training_mode:
		return 1.0
	if _controller == null:
		return 1.0
	if _controller.has_method("get_champion_utilization_ratio"):
		return clampf(
			float(_controller.call("get_champion_utilization_ratio")),
			0.0,
			1.0
		)
	return 1.0


func get_debug_state() -> Dictionary:
	return {
		"enabled": _enabled,
		"checkpoint_path": _checkpoint_path,
		"checkpoint_checksum": str(_checkpoint_metadata.get("model_checksum", "")),
		"training_steps": int(_checkpoint_metadata.get("training_steps", 0)),
		"model_type": str(_checkpoint_metadata.get("model_type", "hybrid_linear_tactical_policy")),
		"current_action": str(_active_decision.get("action", Schema.ACTION_IDLE)),
		"target_position": _active_decision.get("target_position", Vector2.ZERO),
		"target_peer_id": int(_active_decision.get("target_peer_id", 0)),
		"commit_remaining": maxf(0.0, _active_until - _now()),
		"fallback_active": _fallback_active,
		"fallback_reason": _fallback_reason,
		"fallback_count": _fallback_count,
		"last_error": _last_error,
		"last_scores": _policy.get_last_scores(),
		"action_usage": _policy.get_action_usage(),
		"candidate_count": _last_candidates.size(),
		"policy_strength": _last_policy_strength,
		"last_defender_override_active": _last_defender_override_active,
		"last_defender_override_target": _last_defender_override_target,
		"last_defender_override_reason": _last_defender_override_reason,
		"last_defender_override_margin": _last_defender_override_margin,
		"opponent_stall_seconds": _opponent_stall_seconds,
		"opponent_stall_strength": _opponent_stall_strength,
		"opponent_idle_input": _opponent_idle_input,
		"opponent_commit_signal": _opponent_commit_signal,
		"opponent_stall_near_goal": _opponent_stall_near_goal,
		"fake_challenge_phase": _get_fake_challenge_phase(),
		"stall_pressure_target": _last_stall_pressure_target,
		"stall_pressure_route": _last_stall_pressure_route,
		"stall_pressure_mode": _last_stall_pressure_mode,
		"team_defensive_role": str(_last_team_defensive_role),
		"team_defensive_target": _last_team_defensive_target
	}


func _load_active_checkpoint() -> void:
	var modified_time: int = int(
		FileAccess.get_modified_time(_checkpoint_path)
	)
	var cached: Dictionary = _runtime_checkpoint_cache.get(
		_checkpoint_path,
		{}
	) as Dictionary
	if (
		not cached.is_empty()
		and int(cached.get("modified_time", -1)) == modified_time
	):
		var cached_document: Dictionary = cached.get(
			"document",
			{}
		) as Dictionary
		if apply_policy_document(cached_document):
			_set_checkpoint_metadata(cached_document)
			_last_error = ""
			return
	var result := CheckpointStore.load_checkpoint(_checkpoint_path)
	if bool(result.get("ok", false)):
		var document := (result.get("document", {}) as Dictionary).duplicate(true)
		if str(document.get("model_checksum", "")).is_empty():
			document["model_checksum"] = str(result.get("model_checksum", ""))
		if apply_policy_document(document):
			var runtime_document := _make_runtime_checkpoint_document(document)
			_runtime_checkpoint_cache[_checkpoint_path] = {
				"modified_time": modified_time,
				"document": runtime_document
			}
			_set_checkpoint_metadata(runtime_document)
			_last_error = ""
			return
	_last_error = str(result.get("error", "checkpoint_load_failed"))
	# A failed load is visible and explicit. The deterministic default keeps the
	# game playable, but the error remains available through get_debug_state().
	_policy.set_policy_document(Policy.get_default_policy_document())
	push_warning(
		"Hybrid CPU checkpoint load failed (%s): %s. Using safe tactical defaults."
		% [_checkpoint_path, _last_error]
	)


func _make_runtime_checkpoint_document(document: Dictionary) -> Dictionary:
	# Training checkpoints can contain megabytes of opponent-pool history and
	# benchmark data. Runtime CPUs only need the policy and compact identity
	# fields. Keeping those training-only sections out of the shared cache also
	# avoids deep-copying them once per CPU.
	return {
		"policy": (document.get("policy", {}) as Dictionary).duplicate(true),
		"model_checksum": str(document.get("model_checksum", "")),
		"training_steps": int(document.get("training_steps", 0)),
		"model_type": str(document.get(
			"model_type",
			"hybrid_linear_tactical_policy"
		)),
		"checkpoint_version": int(document.get("checkpoint_version", 0)),
		"observation_version": int(document.get("observation_version", 0)),
		"action_space_version": int(document.get("action_space_version", 0))
	}


func _set_checkpoint_metadata(document: Dictionary) -> void:
	_checkpoint_metadata = document.duplicate(true)
	_checkpoint_metadata.erase("policy")


func _controller_ready() -> bool:
	return (
		is_instance_valid(_controller.get("controlled_player"))
		and is_instance_valid(_controller.get("match_manager"))
		and is_instance_valid(_controller.get("ball"))
	)


func _reset_opponent_behavior_tracking() -> void:
	_tracked_opponent_carrier_peer_id = 0
	_last_opponent_behavior_sample_at = -INF
	_last_opponent_carrier_position = Vector2.ZERO
	_last_observed_ball_position = Vector2.ZERO
	_last_opponent_carrier_velocity = Vector2.ZERO
	_last_observed_ball_velocity = Vector2.ZERO
	_opponent_stall_seconds = 0.0
	_opponent_stall_strength = 0.0
	_opponent_idle_input = 0.0
	_opponent_commit_signal = 0.0
	_opponent_stall_near_goal = false
	_last_stall_pressure_target = Vector2.ZERO
	_last_stall_pressure_route = ""
	_last_stall_pressure_mode = ""


func _augment_observation_with_opponent_behavior(
	observation: Dictionary,
	now: float
) -> void:
	if observation.is_empty():
		return

	var ball: Node = _controller.get("ball")
	var carrier: Node = _controller.call(
		"_get_likely_opponent_ball_carrier"
	)
	var opponent_possession: bool = (
		str(observation.get("possession", "loose"))
		== "opponent"
	)
	if ball == null or carrier == null or not opponent_possession:
		_reset_opponent_behavior_tracking()
		_write_opponent_behavior_features(observation)
		return

	var carrier_peer_id: int = int(carrier.get("owner_peer_id"))
	var carrier_position: Vector2 = carrier.get("global_position")
	var ball_position: Vector2 = ball.get("global_position")
	var carrier_velocity: Vector2 = carrier.get("linear_velocity")
	var ball_velocity: Vector2 = ball.get("linear_velocity")
	var input_variant: Variant = carrier.get("server_direction")
	var carrier_input: Vector2 = (
		input_variant as Vector2
		if input_variant is Vector2
		else Vector2.ZERO
	)
	var input_strength: float = clampf(
		carrier_input.length(),
		0.0,
		1.0
	)
	var same_carrier: bool = (
		carrier_peer_id == _tracked_opponent_carrier_peer_id
		and _last_opponent_behavior_sample_at > -INF
	)
	var sample_seconds: float = 0.0
	if same_carrier:
		sample_seconds = clampf(
			now - _last_opponent_behavior_sample_at,
			0.0,
			0.25
		)

	var carrier_displacement: float = (
		carrier_position.distance_to(
			_last_opponent_carrier_position
		)
		if same_carrier
		else 0.0
	)
	var ball_displacement: float = (
		ball_position.distance_to(
			_last_observed_ball_position
		)
		if same_carrier
		else 0.0
	)
	var low_motion: bool = (
		carrier_velocity.length()
		<= STALL_CARRIER_MAX_SPEED
		and ball_velocity.length()
		<= STALL_BALL_MAX_SPEED
		and input_strength <= STALL_INPUT_MAXIMUM
		and not bool(carrier.get("server_is_charging"))
		and (
			not same_carrier
			or (
				carrier_displacement
				<= STALL_SAMPLE_MOVEMENT_TOLERANCE
				and ball_displacement
				<= STALL_SAMPLE_MOVEMENT_TOLERANCE
			)
		)
	)

	if same_carrier and low_motion:
		_opponent_stall_seconds += sample_seconds
	elif same_carrier:
		_opponent_stall_seconds = maxf(
			0.0,
			_opponent_stall_seconds
			- sample_seconds * 3.0
		)
	else:
		_opponent_stall_seconds = 0.0

	var carrier_speed_gain: float = maxf(
		0.0,
		carrier_velocity.length()
		- _last_opponent_carrier_velocity.length()
	)
	var ball_speed_gain: float = maxf(
		0.0,
		ball_velocity.length()
		- _last_observed_ball_velocity.length()
	)
	_opponent_idle_input = 1.0 - clampf(
		input_strength / maxf(
			0.01,
			STALL_INPUT_MAXIMUM * 2.0
		),
		0.0,
		1.0
	)
	var commit_signal: float = input_strength
	commit_signal = maxf(
		commit_signal,
		carrier_velocity.length() / 900.0
	)
	commit_signal = maxf(
		commit_signal,
		ball_velocity.length() / 1500.0
	)
	commit_signal = maxf(
		commit_signal,
		carrier_speed_gain / 650.0
	)
	commit_signal = maxf(
		commit_signal,
		ball_speed_gain / 900.0
	)
	if bool(carrier.get("server_is_charging")):
		commit_signal = 1.0
	_opponent_commit_signal = clampf(
		commit_signal,
		0.0,
		1.0
	)
	_opponent_stall_strength = smoothstep(
		STALL_DETECTION_SECONDS,
		STALL_FULL_STRENGTH_SECONDS,
		_opponent_stall_seconds
	) * _opponent_idle_input

	var own_goal_distance: float = float(
		observation.get("own_goal_distance", 1.0)
	)
	_opponent_stall_near_goal = (
		own_goal_distance <= 0.34
		and _opponent_stall_strength > 0.0
	)

	_tracked_opponent_carrier_peer_id = carrier_peer_id
	_last_opponent_behavior_sample_at = now
	_last_opponent_carrier_position = carrier_position
	_last_observed_ball_position = ball_position
	_last_opponent_carrier_velocity = carrier_velocity
	_last_observed_ball_velocity = ball_velocity
	_write_opponent_behavior_features(observation)


func _write_opponent_behavior_features(
	observation: Dictionary
) -> void:
	var own_goal_distance: float = float(
		observation.get("own_goal_distance", 1.0)
	)
	observation["opponent_stall"] = (
		_opponent_stall_strength > 0.0
	)
	observation["opponent_stall_seconds"] = (
		_opponent_stall_seconds
	)
	observation["opponent_stall_strength"] = (
		_opponent_stall_strength
	)
	observation["opponent_idle_input"] = (
		_opponent_idle_input
	)
	observation["opponent_commit_signal"] = (
		_opponent_commit_signal
	)
	observation["defensive_goal_proximity"] = 1.0 - clampf(
		own_goal_distance / 0.55,
		0.0,
		1.0
	)
	var attacking_goal_distance: float = float(
		observation.get("goal_distance", 1.0)
	)
	observation["attacking_goal_proximity"] = 1.0 - clampf(
		attacking_goal_distance / 0.55,
		0.0,
		1.0
	)
	observation["opponent_stall_near_goal"] = (
		_opponent_stall_near_goal
	)


func _get_fake_challenge_phase() -> String:
	if StringName(
		_active_decision.get(
			"action",
			Schema.ACTION_IDLE
		)
	) != Schema.ACTION_FAKE_CHALLENGE:
		return "inactive"
	if not bool(
		_active_decision.get("stall_bait", false)
	):
		return "standard"
	var elapsed: float = maxf(
		0.0,
		_now() - float(
			_active_decision.get(
				"selected_at",
				_now()
			)
		)
	)
	return (
		"probe"
		if elapsed < float(
			_active_decision.get(
				"probe_seconds",
				0.18
			)
		)
		else "recover"
	)


func _try_one_vs_one_stall_pressure_override(
	observation: Dictionary,
	now: float
) -> bool:
	if (
		_controller == null
		or not _controller.has_method(
			"_is_true_one_vs_one"
		)
		or not bool(
			_controller.call("_is_true_one_vs_one")
		)
		or str(
			observation.get("possession", "")
		) != "opponent"
	):
		return false

	var stall_seconds: float = maxf(
		0.0,
		float(
			observation.get(
				"opponent_stall_seconds",
				0.0
			)
		)
	)
	var stall_strength: float = clampf(
		float(
			observation.get(
				"opponent_stall_strength",
				0.0
			)
		),
		0.0,
		1.0
	)
	if (
		stall_seconds < ONE_V_ONE_STALL_CLOSE_SECONDS
		or stall_strength <= 0.0
	):
		return false

	var player: Node = _controller.get("controlled_player")
	var ball: Node = _controller.get("ball")
	var carrier: Node = _controller.call(
		"_get_likely_opponent_ball_carrier"
	)
	var own_goal: Node = _controller.call("_get_own_goal")
	if (
		player == null
		or ball == null
		or carrier == null
		or own_goal == null
	):
		return false

	var ball_position: Vector2 = ball.get(
		"global_position"
	)
	var player_position: Vector2 = player.get(
		"global_position"
	)
	var player_ball_distance: float = (
		player_position.distance_to(ball_position)
	)
	var attacker_behind: bool = bool(
		observation.get(
			"attacker_behind_defender",
			false
		)
	)
	var own_goal_danger: bool = bool(
		observation.get("own_goal_danger", false)
	)
	var defensive_goal_proximity: float = clampf(
		float(
			observation.get(
				"defensive_goal_proximity",
				0.0
			)
		),
		0.0,
		1.0
	)
	var attacking_goal_proximity: float = clampf(
		float(
			observation.get(
				"attacking_goal_proximity",
				0.0
			)
		),
		0.0,
		1.0
	)

	# When the carrier is parked near its own goal, this CPU is the attacker.
	# Passivity has no value there: close rapidly and create a tackle window.
	var force_seconds: float = lerpf(
		ONE_V_ONE_STALL_FORCE_SECONDS,
		0.95,
		attacking_goal_proximity
	)
	var force_tackle: bool = (
		stall_seconds >= force_seconds
		and player_ball_distance
		<= ONE_V_ONE_STALL_FORCE_DISTANCE
		and not attacker_behind
		and (
			not own_goal_danger
			or defensive_goal_proximity < 0.72
		)
	)

	var immediate_contact: bool = (
		player_ball_distance
		<= float(
			player.get(
				"kick_feedback_detection_distance"
			)
		) * 1.28
	)
	if force_tackle or immediate_contact:
		clear_active_decision()
		_last_stall_pressure_target = ball_position
		_last_stall_pressure_route = "ball"
		_last_stall_pressure_mode = (
			"forced_tackle"
			if force_tackle
			else "contact_poke"
		)
		_controller.set(
			"_movement_target",
			ball_position
		)
		_controller.call(
			"_set_tactical_intent",
			LEGACY_INTENT_CHASE,
			ball_position,
			int(carrier.get("owner_peer_id"))
		)
		_controller.call("_try_defensive_ball_win")
		_record_defense_event(
			&"one_vs_one_stall_forced_press"
		)
		return true

	var pressure_plan: Dictionary = (
		_build_predictive_stall_pressure_plan(
			carrier,
			own_goal,
			observation
		)
	)
	if pressure_plan.is_empty():
		return false

	var pressure_target: Vector2 = pressure_plan.get(
		"target",
		ball_position
	)
	var desired_gap: float = float(
		pressure_plan.get(
			"desired_gap",
			ONE_V_ONE_STALL_MIDFIELD_GAP
		)
	)
	# Never remain farther away than the passive-gap cap once a stall is
	# confirmed. The target continuously advances as the CPU closes.
	if player_ball_distance > ONE_V_ONE_STALL_MAXIMUM_PASSIVE_GAP:
		var toward_ball: Vector2 = player_position.direction_to(
			pressure_target
		)
		var close_distance: float = minf(
			player_position.distance_to(pressure_target),
			maxf(
				180.0,
				player_ball_distance
				- ONE_V_ONE_STALL_MAXIMUM_PASSIVE_GAP
				+ desired_gap * 0.32
			)
		)
		pressure_target = (
			player_position
			+ toward_ball * close_distance
		)

	clear_active_decision()
	_last_stall_pressure_target = pressure_target
	_last_stall_pressure_route = str(
		pressure_plan.get("route", "direct")
	)
	_last_stall_pressure_mode = (
		"close_options"
		if player_ball_distance
		> ONE_V_ONE_STALL_MAXIMUM_PASSIVE_GAP
		else "bait_and_cut"
	)
	_controller.set(
		"_movement_target",
		pressure_target
	)
	_controller.call(
		"_set_tactical_intent",
		LEGACY_INTENT_MARK,
		pressure_target,
		int(carrier.get("owner_peer_id"))
	)
	return true


func _build_predictive_stall_pressure_plan(
	carrier: Node,
	own_goal: Node,
	observation: Dictionary
) -> Dictionary:
	var player: Node = _controller.get("controlled_player")
	var ball: Node = _controller.get("ball")
	if (
		player == null
		or ball == null
		or carrier == null
		or own_goal == null
	):
		return {}

	var ball_position: Vector2 = ball.get(
		"global_position"
	)
	var player_position: Vector2 = player.get(
		"global_position"
	)
	var goal_center: Vector2 = _controller.call(
		"_get_goal_center",
		own_goal
	)
	var toward_goal: Vector2 = ball_position.direction_to(
		goal_center
	)
	if toward_goal.is_zero_approx():
		toward_goal = Vector2(
			-float(
				_controller.call("_get_attack_sign")
			),
			0.0
		)
	var tangent: Vector2 = Vector2(
		-toward_goal.y,
		toward_goal.x
	)

	var defensive_goal_proximity: float = clampf(
		float(
			observation.get(
				"defensive_goal_proximity",
				0.0
			)
		),
		0.0,
		1.0
	)
	var attacking_goal_proximity: float = clampf(
		float(
			observation.get(
				"attacking_goal_proximity",
				0.0
			)
		),
		0.0,
		1.0
	)
	var desired_gap: float = lerpf(
		ONE_V_ONE_STALL_MIDFIELD_GAP,
		ONE_V_ONE_STALL_DEFENSIVE_GOAL_GAP,
		defensive_goal_proximity
	)
	desired_gap = lerpf(
		desired_gap,
		ONE_V_ONE_STALL_ATTACKING_GOAL_GAP,
		attacking_goal_proximity
	)

	var minimum_y: float = float(
		_controller.get("minimum_field_y")
	)
	var maximum_y: float = float(
		_controller.get("maximum_field_y")
	)
	var field_height: float = maxf(
		1.0,
		maximum_y - minimum_y
	)
	var top_lane: Vector2 = Vector2(
		goal_center.x,
		minimum_y + field_height * 0.18
	)
	var bottom_lane: Vector2 = Vector2(
		goal_center.x,
		maximum_y - field_height * 0.18
	)
	var upper_escape: Vector2 = (
		ball_position
		+ toward_goal * 960.0
		- tangent * 720.0
	)
	var lower_escape: Vector2 = (
		ball_position
		+ toward_goal * 960.0
		+ tangent * 720.0
	)

	var routes: Array[Dictionary] = [
		{
			"name": "direct_shot",
			"end": goal_center,
			"weight": 1.35
		},
		{
			"name": "top_wall",
			"end": top_lane,
			"weight": 0.92
		},
		{
			"name": "bottom_wall",
			"end": bottom_lane,
			"weight": 0.92
		},
		{
			"name": "upper_dribble",
			"end": upper_escape,
			"weight": 0.78
		},
		{
			"name": "lower_dribble",
			"end": lower_escape,
			"weight": 0.78
		}
	]

	var base_target: Vector2 = (
		ball_position + toward_goal * desired_gap
	)
	var lateral_offsets: Array[float] = [
		-260.0,
		-130.0,
		0.0,
		130.0,
		260.0
	]
	var best_target: Vector2 = base_target
	var best_score: float = -INF
	var best_route_name: String = "direct_shot"
	for lateral_offset in lateral_offsets:
		var raw_candidate: Vector2 = (
			base_target + tangent * lateral_offset
		)
		var candidate: Vector2 = (
			_controller.call(
				"_clamp_to_field",
				raw_candidate
			) as Vector2
		)
		var candidate_goal_distance: float = (
			candidate.distance_to(goal_center)
		)
		var ball_goal_distance: float = (
			ball_position.distance_to(goal_center)
		)
		if (
			candidate_goal_distance
			>= ball_goal_distance - 55.0
		):
			continue

		var coverage_score: float = 0.0
		var strongest_route_score: float = -INF
		var strongest_route_name: String = "direct_shot"
		for route in routes:
			var route_end: Vector2 = route.get(
				"end",
				goal_center
			)
			var route_distance: float = float(
				_controller.call(
					"_distance_to_segment",
					candidate,
					ball_position,
					route_end
				)
			)
			var route_score: float = (
				maxf(
					0.0,
					690.0 - route_distance
				)
				* float(route.get("weight", 1.0))
			)
			coverage_score += route_score
			if route_score > strongest_route_score:
				strongest_route_score = route_score
				strongest_route_name = str(
					route.get("name", "direct_shot")
				)

		var travel_cost: float = (
			player_position.distance_to(candidate) * 0.24
		)
		var gap_penalty: float = absf(
			candidate.distance_to(ball_position)
			- desired_gap
		) * 0.95
		var bait_side_bonus: float = 0.0
		if (
			not is_zero_approx(lateral_offset)
			and signf(lateral_offset)
			== _stall_probe_side
		):
			bait_side_bonus = 70.0
		var score: float = (
			coverage_score
			- travel_cost
			- gap_penalty
			+ bait_side_bonus
		)
		if score > best_score:
			best_score = score
			best_target = candidate
			best_route_name = strongest_route_name

	return {
		"target": best_target,
		"route": best_route_name,
		"desired_gap": desired_gap,
		"score": best_score
	}


func _try_last_defender_recovery_override(
	observation: Dictionary
) -> bool:
	if observation.is_empty():
		return false
	if not bool(
		observation.get("attacker_behind_defender", false)
	):
		return false
	if bool(
		observation.get("goal_cover_available", false)
	):
		return false

	var player: Node = _controller.get("controlled_player")
	var ball: Node = _controller.get("ball")
	var own_goal: Node = _controller.call("_get_own_goal")
	var carrier: Node = _controller.call(
		"_get_likely_opponent_ball_carrier"
	)
	if (
		player == null
		or ball == null
		or own_goal == null
		or carrier == null
	):
		return false

	var player_ball_distance: float = (
		player.get("global_position") as Vector2
	).distance_to(ball.get("global_position") as Vector2)
	var tackle_distance := maxf(
		90.0,
		float(player.get("kick_feedback_detection_distance"))
		* 1.04
	)

	# A genuinely immediate tackle remains legal. Otherwise, once the attacker
	# has crossed behind the last defender, the learned policy is not allowed
	# to keep pressing, marking from behind, or reuse a stale challenge.
	if player_ball_distance <= tackle_distance:
		_controller.call("_try_defensive_ball_win")

	var target := _get_emergency_goal_side_recovery_target(
		carrier,
		own_goal
	)
	if target.is_zero_approx():
		return false

	clear_active_decision()
	_last_defender_override_active = true
	_last_defender_override_target = target
	_last_defender_override_reason = "attacker_behind_last_defender"
	_last_defender_override_margin = float(
		observation.get("breakaway_goal_side_margin", 0.0)
	)

	_controller.call("_clear_attack_plan")
	_controller.set("_movement_target", target)
	_controller.call(
		"_set_tactical_intent",
		LEGACY_INTENT_COVER,
		target,
		int(carrier.get("owner_peer_id"))
	)
	return true


func _get_emergency_goal_side_recovery_target(
	carrier: Node,
	own_goal: Node
) -> Vector2:
	if carrier == null or own_goal == null:
		return Vector2.ZERO
	var ball: Node = _controller.get("ball")
	if ball == null:
		return Vector2.ZERO

	var goal_center: Vector2 = _controller.call(
		"_get_goal_center",
		own_goal
	)
	var carrier_position: Vector2 = carrier.get("global_position")
	var carrier_velocity: Vector2 = carrier.get("linear_velocity")
	var predicted_carrier := (
		carrier_position
		+ carrier_velocity * 0.18
	)
	var ball_position: Vector2 = ball.get("global_position")
	var ball_velocity: Vector2 = ball.get("linear_velocity")
	var predicted_ball := ball_position + ball_velocity * 0.12

	# Both components are guaranteed to lie between the attacker/ball and goal.
	# This target does not use the shared defensive assignment, because that
	# assignment may still label this player as the presser.
	var carrier_goal_side := predicted_carrier.lerp(
		goal_center,
		0.38
	)
	var shot_lane_block := predicted_ball.lerp(
		goal_center,
		0.42
	)
	var target := carrier_goal_side.lerp(
		shot_lane_block,
		0.46
	)

	var mouth_range: Vector2 = own_goal.call(
		"get_mouth_y_range"
	)
	var mouth_center_y := (
		mouth_range.x + mouth_range.y
	) * 0.5
	target.y = lerpf(
		target.y,
		mouth_center_y,
		0.18
	)

	# Guarantee that the recovery target is actually goal-side of the carrier.
	var target_goal_distance := target.distance_to(goal_center)
	var carrier_goal_distance := predicted_carrier.distance_to(
		goal_center
	)
	if target_goal_distance >= carrier_goal_distance - 80.0:
		target = predicted_carrier.lerp(
			goal_center,
			0.52
		)

	return _controller.call("_clamp_to_field", target) as Vector2


func _build_candidates(observation: Dictionary) -> Array[Dictionary]:
	var candidates: Array[Dictionary] = []
	var possession: String = str(observation.get("possession", "loose"))
	var primary_chaser := bool(observation.get("primary_chaser", false))
	var own_goal_danger := bool(observation.get("own_goal_danger", false))

	# "team" possession is impossible when this CPU has no active teammate.
	# Treat a kickable ball as self possession; otherwise keep chasing the loose
	# ball. This prevents 1v1 support/wait strafing beside an untouched ball.
	if possession == "team" and not _has_other_teammate():
		var player: Node = _controller.get("controlled_player")
		if player != null and bool(player.call("cpu_has_kickable_ball")):
			possession = "self"
		else:
			possession = "loose"
			primary_chaser = true

	var defensive_assignment: Dictionary = {}
	if possession == "opponent":
		defensive_assignment = _get_team_defensive_assignment()
		var assigned_role := StringName(
			defensive_assignment.get("role", &"")
		)
		_last_team_defensive_role = assigned_role
		_last_team_defensive_target = defensive_assignment.get(
			"target_position",
			Vector2.ZERO
		) as Vector2
		if assigned_role == &"press":
			primary_chaser = true
			observation["primary_chaser"] = true
		elif assigned_role in [&"cover", &"final", &"mark"]:
			primary_chaser = false
			observation["primary_chaser"] = false
	else:
		_last_team_defensive_role = &""
		_last_team_defensive_target = Vector2.ZERO

	match possession:
		"self":
			_append_possession_candidates(candidates, observation)
		"team":
			_append_support_candidates(candidates, observation)
		"opponent":
			_append_defensive_candidates(candidates, observation, own_goal_danger)
			_apply_team_defensive_role_constraints(
				candidates,
				defensive_assignment
			)
		_:
			_append_loose_ball_candidates(candidates, observation, primary_chaser, own_goal_danger)
	if candidates.is_empty():
		candidates.append(_candidate(Schema.ACTION_WAIT, Vector2.ZERO, 0, -0.8, 0.08, true, "safe_idle"))
	return candidates


func _get_team_defensive_assignment() -> Dictionary:
	if _controller == null:
		return {}
	var player: Node = _controller.get("controlled_player")
	var match_manager: Node = _controller.get("match_manager")
	if player == null or match_manager == null:
		return {}
	var active_team_count := int(
		_controller.call("_get_active_team_player_count")
	)
	if active_team_count < 2:
		return {}
	return match_manager.call(
		"get_cpu_defensive_assignment",
		StringName(player.get("team")),
		int(player.get("owner_peer_id"))
	) as Dictionary


func _apply_team_defensive_role_constraints(
	candidates: Array[Dictionary],
	assignment: Dictionary
) -> void:
	if assignment.is_empty():
		return
	var role := StringName(assignment.get("role", &""))
	if role.is_empty():
		return
	var player: Node = _controller.get("controlled_player")
	var ball: Node = _controller.get("ball")
	var immediate_tackle := false
	if player != null and ball != null:
		var tackle_radius := maxf(
			95.0,
			float(player.get("kick_feedback_detection_distance")) * 1.14
		)
		immediate_tackle = (
			(player.get("global_position") as Vector2).distance_to(
				ball.get("global_position") as Vector2
			) <= tackle_radius
		)
	for candidate in candidates:
		var action := StringName(candidate.get("action", Schema.ACTION_IDLE))
		var score := float(candidate.get("base_score", -INF))
		match role:
			&"press":
				match action:
					Schema.ACTION_CHALLENGE_BALL:
						score += 2.65
					Schema.ACTION_SHADOW_DEFEND:
						score += 1.45
					Schema.ACTION_FAKE_CHALLENGE:
						score += 0.35
					Schema.ACTION_PROTECT_GOAL, Schema.ACTION_ROTATE_BACK, Schema.ACTION_MARK_OPPONENT:
						score -= 3.25
					Schema.ACTION_WAIT:
						score -= 5.0
			&"cover", &"final", &"mark":
				match action:
					Schema.ACTION_CHALLENGE_BALL:
						if not immediate_tackle:
							score -= 4.25
					Schema.ACTION_PROTECT_GOAL, Schema.ACTION_ROTATE_BACK:
						score += 2.1
					Schema.ACTION_SHADOW_DEFEND:
						score += 1.45
					Schema.ACTION_MARK_OPPONENT:
						score += 1.0
					Schema.ACTION_FAKE_CHALLENGE:
						score -= 1.8
		candidate["base_score"] = score
		candidate["urgency"] = clampf(score / 2.5, 0.0, 1.0)
		candidate["team_defensive_role"] = role

	# Team defense already computes one presser plus distinct cover/final/mark
	# jobs. In large matches the hybrid policy used to honor only the presser's
	# exact lane, while every other defender was free to choose another generic
	# ball-side candidate. That is what recreated the crowd around the ball.
	# Feed every assigned lane into the candidate set in 4v4+; smaller modes keep
	# the old behavior.
	var large_team_shape := (
		_controller.has_method("is_large_team_football_shape_active")
		and bool(_controller.call("is_large_team_football_shape_active"))
	)
	var assigned_target: Vector2 = assignment.get(
		"target_position",
		Vector2.ZERO
	) as Vector2
	if (
		large_team_shape
		and _controller.has_method("resolve_cpu_defensive_assignment_target")
	):
		assigned_target = _controller.call(
			"resolve_cpu_defensive_assignment_target",
			assignment
		) as Vector2

	if not assigned_target.is_zero_approx() and (role == &"press" or large_team_shape):
		var assigned_action := Schema.ACTION_SHADOW_DEFEND
		var assigned_score := 3.2
		var assigned_commit := 0.20
		var assigned_reason := "assigned_team_press_lane"
		match role:
			&"cover":
				assigned_action = Schema.ACTION_ROTATE_BACK
				assigned_score = 3.05
				assigned_commit = 0.34
				assigned_reason = "assigned_large_team_cover_lane"
			&"final":
				assigned_action = Schema.ACTION_PROTECT_GOAL
				assigned_score = 3.35
				assigned_commit = 0.38
				assigned_reason = "assigned_large_team_final_lane"
			&"mark":
				assigned_action = Schema.ACTION_MARK_OPPONENT
				assigned_score = 3.10
				assigned_commit = 0.34
				assigned_reason = "assigned_large_team_mark_lane"
		var assigned_candidate := _candidate(
			assigned_action,
			assigned_target,
			int(assignment.get("target_peer_id", 0)),
			assigned_score,
			assigned_commit,
			true,
			assigned_reason,
			0.82 if large_team_shape else 0.78
		)
		assigned_candidate["team_defensive_role"] = role
		candidates.append(assigned_candidate)


func _append_loose_ball_candidates(
	candidates: Array[Dictionary],
	observation: Dictionary,
	primary_chaser: bool,
	own_goal_danger: bool
) -> void:
	var ball: Node = _controller.get("ball")
	var player: Node = _controller.get("controlled_player")
	if ball == null or player == null:
		return
	if not primary_chaser:
		if own_goal_danger:
			var emergency_target: Vector2 = _controller.call(
				"_get_defensive_position"
			)
			candidates.append(_candidate(
				Schema.ACTION_PROTECT_GOAL,
				emergency_target,
				0,
				1.35,
				0.28,
				true,
				"loose_ball_goal_cover"
			))
		_append_support_candidates(candidates, observation)
		return

	var predicted_ball: Vector2 = _controller.call(
		"_get_predicted_ball_position"
	)
	if predicted_ball.is_zero_approx():
		predicted_ball = ball.get("global_position") as Vector2

	var context: Dictionary = _get_challenge_context(observation, predicted_ball)
	var opponent: Node = context.get("opponent", null) as Node
	var opponent_peer_id := (
		int(opponent.get("owner_peer_id"))
		if opponent != null
		else 0
	)
	var race_advantage: float = float(context.get("race_advantage", 0.0))
	var safe_to_challenge: bool = bool(
		context.get("safe_to_challenge", true)
	)
	var shot_threat: float = float(context.get("shot_threat", 0.0))
	var open_net_risk: float = float(context.get("open_net_risk", 0.0))
	var clear_self_first: bool = bool(
		context.get("clear_self_first", false)
	)
	var can_intercept_goal_threat: bool = bool(
		context.get("can_intercept_goal_threat", false)
	)
	var ball_speed := (ball.get("linear_velocity") as Vector2).length()
	var distance := (
		player.get("global_position") as Vector2
	).distance_to(predicted_ball)

	var challenge_target := predicted_ball
	if opponent != null:
		challenge_target = _controller.call(
			"_get_duel_challenge_position",
			predicted_ball,
			opponent
		) as Vector2
	var challenge_score := 1.0
	if clear_self_first:
		challenge_score += 3.25
	if can_intercept_goal_threat:
		challenge_score += 2.50
	challenge_score += clampf(race_advantage * 1.35, -1.35, 1.15)
	challenge_score += clampf(1.0 - distance / 1800.0, -0.25, 0.65)
	challenge_score -= open_net_risk * 1.65
	challenge_score -= shot_threat * 0.35
	if own_goal_danger and bool(context.get("immediate_tackle", false)):
		challenge_score += 0.45
	candidates.append(_candidate(
		Schema.ACTION_CHALLENGE_BALL,
		challenge_target,
		opponent_peer_id,
		challenge_score,
		0.18,
		safe_to_challenge,
		"loose_ball_intercept" if safe_to_challenge else "lost_ball_race",
		1.0
		if clear_self_first or can_intercept_goal_threat
		else clampf((race_advantage + 0.4) / 1.1, 0.0, 1.0)
	))

	# Do not offer retreat/marking alternatives when this CPU has an uncontested
	# first touch. Leaving only the collection action prevents the learned policy
	# from overthinking an obvious loose-ball recovery.
	if clear_self_first or can_intercept_goal_threat:
		return

	if opponent != null and (
		not safe_to_challenge
		or race_advantage < 0.10
		or shot_threat >= 0.35
	):
		var recovery_target := _controller.call(
			"_get_duel_goal_side_recovery_position",
			opponent,
			predicted_ball
		) as Vector2
		candidates.append(_candidate(
			Schema.ACTION_SHADOW_DEFEND,
			recovery_target,
			opponent_peer_id,
			0.85
			+ maxf(0.0, -race_advantage) * 1.15
			+ shot_threat * 1.0
			+ open_net_risk * 1.25,
			0.26,
			true,
			"cede_lost_race_and_block_goal"
		))
		if not own_goal_danger and shot_threat < 0.65:
			var fake_target: Vector2 = predicted_ball.lerp(
				recovery_target,
				0.55
			)
			candidates.append(_candidate(
				Schema.ACTION_FAKE_CHALLENGE,
				fake_target,
				opponent_peer_id,
				0.35
				+ maxf(0.0, -race_advantage) * 0.45,
				0.18,
				true,
				"delay_first_touch"
			))

	if own_goal_danger or open_net_risk >= 0.35 or shot_threat >= 0.55:
		var protect_target: Vector2 = _controller.call(
			"_get_defensive_position"
		)
		candidates.append(_candidate(
			Schema.ACTION_PROTECT_GOAL,
			protect_target,
			0,
			1.05
			+ open_net_risk * 1.75
			+ shot_threat * 1.25
			+ (0.45 if own_goal_danger else 0.0),
			0.30,
			true,
			"last_defender_safety"
		))


func _get_challenge_context(
	observation: Dictionary,
	intercept_position: Vector2 = Vector2.ZERO
) -> Dictionary:
	var player: Node = _controller.get("controlled_player")
	var ball: Node = _controller.get("ball")
	var own_goal: Node = _controller.call("_get_own_goal")
	var opponent: Node = _controller.call(
		"_get_likely_opponent_ball_carrier"
	)
	var own_arrival := float(
		observation.get("self_ball_arrival_seconds", 3.0)
	)
	var opponent_arrival := float(
		observation.get(
			"nearest_opponent_ball_arrival_seconds",
			3.0
		)
	)
	if opponent != null:
		var duel_data := _controller.call(
			"_get_duel_interception_data",
			opponent
		) as Dictionary
		if not duel_data.is_empty():
			own_arrival = float(
				duel_data.get("own_arrival", own_arrival)
			)
			opponent_arrival = float(
				duel_data.get(
					"opponent_arrival",
					opponent_arrival
				)
			)
			if intercept_position.is_zero_approx():
				intercept_position = duel_data.get(
					"position",
					ball.get("global_position")
				) as Vector2

	var race_advantage := opponent_arrival - own_arrival
	var immediate_tackle := false
	if player != null and ball != null:
		var tackle_radius := maxf(
			90.0,
			float(player.get("kick_feedback_detection_distance"))
			* 1.16
		)
		immediate_tackle = (
			(player.get("global_position") as Vector2).distance_to(
				ball.get("global_position") as Vector2
			)
			<= tackle_radius
		)

	var predicted_threat := _controller.call(
		"_predict_own_goal_threat",
		1.25
	) as Dictionary
	var goal_threat := not predicted_threat.is_empty()
	var goal_threat_time := float(
		predicted_threat.get("time", INF)
	)

	var has_cover: bool = bool(
		observation.get("goal_cover_available", false)
	)
	var open_net_risk: float = float(
		observation.get("open_net_risk", 0.0)
	)
	var shot_threat: float = float(
		observation.get("opponent_shot_threat", 0.0)
	)
	var opponent_controls := false
	if opponent != null:
		opponent_controls = bool(
			_controller.call("_opponent_controls_ball", opponent)
		)

	var pre_shot_read: Dictionary = {}
	var pre_shot_risk := 0.0
	var pre_shot_intercept := Vector2.ZERO
	var pre_shot_ball_arrival := INF
	var pre_shot_own_arrival := INF
	var pre_shot_emergency := false
	if opponent_controls and own_goal != null:
		pre_shot_read = _controller.call(
			"_get_defensive_shot_read",
			opponent,
			own_goal
		) as Dictionary
		pre_shot_risk = clampf(
			float(pre_shot_read.get("route_risk", 0.0)),
			0.0,
			1.0
		)
		if pre_shot_risk < 0.42:
			pre_shot_risk = 0.0
		pre_shot_intercept = pre_shot_read.get(
			"route_intercept",
			Vector2.ZERO
		) as Vector2
		pre_shot_ball_arrival = float(
			pre_shot_read.get("route_ball_arrival", INF)
		)
		pre_shot_own_arrival = float(
			pre_shot_read.get("route_own_arrival", INF)
		)
		pre_shot_emergency = bool(
			pre_shot_read.get("route_emergency", false)
		)
		shot_threat = maxf(shot_threat, pre_shot_risk)

	var possession: String = str(
		observation.get("possession", "loose")
	)
	var clear_self_first := (
		not opponent_controls
		and possession == "loose"
		and race_advantage >= 0.12
	)
	var can_intercept_goal_threat := (
		goal_threat
		and own_arrival <= goal_threat_time + 0.10
	)
	var can_cut_pre_shot_route := (
		pre_shot_risk > 0.0
		and pre_shot_own_arrival <= pre_shot_ball_arrival + 0.08
	)
	# An actual shot toward goal makes interception more urgent; it must not
	# automatically disable the challenge. The previous version inverted this
	# and could leave a dangerous free ball untouched.
	var safe_to_challenge := (
		immediate_tackle
		or clear_self_first
		or can_intercept_goal_threat
		or race_advantage >= 0.08
		or (
			race_advantage >= -0.08
			and open_net_risk < 0.58
		)
		or (
			has_cover
			and race_advantage >= -0.24
		)
	)
	if (
		opponent_controls
		and race_advantage < -0.08
		and not immediate_tackle
	):
		safe_to_challenge = false
	if (
		open_net_risk >= 0.72
		and not has_cover
		and not immediate_tackle
		and not clear_self_first
		and not can_intercept_goal_threat
	):
		safe_to_challenge = false
	if (
		shot_threat >= 0.82
		and not immediate_tackle
		and not clear_self_first
		and not can_intercept_goal_threat
	):
		safe_to_challenge = false
	if (
		pre_shot_risk >= 0.58
		and not immediate_tackle
		and not clear_self_first
		and not can_cut_pre_shot_route
	):
		safe_to_challenge = false

	return {
		"opponent": opponent,
		"intercept_position": intercept_position,
		"own_arrival": own_arrival,
		"opponent_arrival": opponent_arrival,
		"race_advantage": race_advantage,
		"clear_self_first": clear_self_first,
		"can_intercept_goal_threat": can_intercept_goal_threat,
		"goal_threat_time": goal_threat_time,
		"immediate_tackle": immediate_tackle,
		"goal_threat": goal_threat,
		"has_cover": has_cover,
		"open_net_risk": open_net_risk,
		"shot_threat": shot_threat,
		"pre_shot_risk": pre_shot_risk,
		"pre_shot_intercept": pre_shot_intercept,
		"pre_shot_ball_arrival": pre_shot_ball_arrival,
		"pre_shot_own_arrival": pre_shot_own_arrival,
		"pre_shot_emergency": pre_shot_emergency,
		"can_cut_pre_shot_route": can_cut_pre_shot_route,
		"pre_shot_route_type": pre_shot_read.get(
			"route_type",
			&"none"
		),
		"opponent_controls": opponent_controls,
		"safe_to_challenge": safe_to_challenge
	}


func _get_pass_search_count(base_count: int) -> int:
	var safe_base: int = maxi(1, base_count)
	# Champions League shares most of the full champion's broader team-play
	# search. INT 17/18/19 inspect progressively more alternatives, with INT 20
	# still seeing the complete dynamic set.
	if (
		_controller != null
		and _controller.has_method("get_effective_skill_level")
		and _controller.has_method("_get_dynamic_pass_search_count")
	):
		var level: int = int(_controller.call("get_effective_skill_level"))
		if level >= 17:
			var expanded_count: int = maxi(
				safe_base,
				int(_controller.call("_get_dynamic_pass_search_count", safe_base))
			)
			var elite_strength: float = clampf(
				0.70 + float(level - 17) * 0.10,
				0.0,
				1.0
			)
			return safe_base + int(round(
				float(expanded_count - safe_base) * elite_strength
			))
	return safe_base


func _append_possession_candidates(candidates: Array[Dictionary], observation: Dictionary) -> void:
	var opponent_goal: Node = _controller.call("_get_opponent_goal")
	if opponent_goal == null:
		return
	var ball: Node = _controller.get("ball")
	var player: Node = _controller.get("controlled_player")
	var goal_center: Vector2 = _controller.call("_get_goal_center", opponent_goal)
	var mouth_range: Vector2 = opponent_goal.call("get_mouth_y_range")
	var attack_sign := float(_controller.call("_get_attack_sign"))
	var goal_distance := (ball.get("global_position") as Vector2).distance_to(goal_center)
	var direct_clearance := float(_controller.call("_minimum_segment_clearance", ball.get("global_position"), goal_center))
	var kick_ready := bool(player.call("cpu_has_kickable_ball"))
	var one_vs_one: bool = bool(
		observation.get("one_vs_one", false)
	)
	var direct_shot_allowed: bool = (
		not one_vs_one
		or _one_vs_one_shot_allowed(goal_center)
	)
	var elite_goal_probability: float = clampf(
		float(
			observation.get(
				"elite_goal_probability",
				0.0
			)
		),
		0.0,
		1.0
	)
	var shot_base := clampf(
		2.2 - goal_distance / 2600.0,
		-0.2,
		1.8
	)
	shot_base += clampf(
		direct_clearance / 650.0,
		-0.8,
		0.9
	)
	shot_base += elite_goal_probability * 3.25
	# A large number of merely goal-bound shots was outperforming patient
	# attacks during training. Make distance and predicted conversion matter:
	# when the finish model does not see a real chance, carrying into a better
	# lane should beat another speculative hit.
	var patient_attack_bonus := 0.0
	if elite_goal_probability < 0.30 and goal_distance > 2100.0:
		var patience_distance := clampf(
			(goal_distance - 2100.0) / 2600.0,
			0.0,
			1.0
		)
		var lane_uncertainty := 1.0 - clampf(
			direct_clearance / 620.0,
			0.0,
			1.0
		)
		patient_attack_bonus = patience_distance * lerpf(
			0.55,
			1.35,
			lane_uncertainty
		)
		shot_base -= patient_attack_bonus
	var direct_route_viable := bool(
		_controller.call("_shot_target_is_viable", goal_center)
	)
	candidates.append(_candidate(
		Schema.ACTION_DIRECT_SHOT,
		goal_center,
		0,
		shot_base,
		0.34,
		(
			kick_ready or goal_distance < 4400.0
		) and direct_shot_allowed and direct_route_viable,
		"direct_lane_with_followup"
		if direct_shot_allowed and direct_route_viable
		else "blocked_direct_shot_lane",
		clampf(direct_clearance / 700.0, 0.0, 1.0)
	))
	var near_y := mouth_range.x + minf(170.0, maxf(35.0, mouth_range.y - mouth_range.x) * 0.18)
	var far_y := mouth_range.y - minf(170.0, maxf(35.0, mouth_range.y - mouth_range.x) * 0.18)
	var player_y := (player.get("global_position") as Vector2).y
	var near_target := Vector2(goal_center.x, near_y if absf(player_y - near_y) < absf(player_y - far_y) else far_y)
	var far_target := Vector2(goal_center.x, far_y if near_target.y == near_y else near_y)
	var near_shot_allowed: bool = (
		not one_vs_one
		or _one_vs_one_shot_allowed(near_target)
	)
	var far_shot_allowed: bool = (
		not one_vs_one
		or _one_vs_one_shot_allowed(far_target)
	)
	var near_clearance := float(_controller.call(
		"_minimum_segment_clearance",
		ball.get("global_position"),
		near_target
	))
	var far_clearance := float(_controller.call(
		"_minimum_segment_clearance",
		ball.get("global_position"),
		far_target
	))
	var near_route_viable := bool(
		_controller.call("_shot_target_is_viable", near_target)
	)
	var far_route_viable := bool(
		_controller.call("_shot_target_is_viable", far_target)
	)
	candidates.append(_candidate(
		Schema.ACTION_NEAR_POST_SHOT,
		near_target,
		0,
		shot_base - 0.05
		+ clampf((near_clearance - direct_clearance) / 650.0, -0.55, 0.65),
		0.34,
		kick_ready and near_shot_allowed and near_route_viable,
		"near_post_with_followup"
		if near_route_viable
		else "blocked_near_post_lane"
	))
	candidates.append(_candidate(
		Schema.ACTION_FAR_POST_SHOT,
		far_target,
		0,
		shot_base + 0.03
		+ clampf((far_clearance - direct_clearance) / 650.0, -0.55, 0.65),
		0.36,
		kick_ready and far_shot_allowed and far_route_viable,
		"far_post_with_followup"
		if far_route_viable
		else "blocked_far_post_lane"
	))
	var wall_route := _controller.call("_get_best_wall_route", far_target) as Dictionary
	if not wall_route.is_empty():
		var wall_clearance := float(wall_route.get("clearance", 0.0))
		var wall_bounce: Vector2 = wall_route.get("bounce", Vector2.ZERO)
		var best_direct_clearance := maxf(
			direct_clearance,
			maxf(near_clearance, far_clearance)
		)
		var direct_lane_available := (
			(direct_route_viable and direct_shot_allowed)
			or (near_route_viable and near_shot_allowed)
			or (far_route_viable and far_shot_allowed)
		)
		var required_wall_clearance := maxf(
			120.0,
			float(_controller.get("wall_route_minimum_clearance"))
		)
		var required_wall_advantage := maxf(
			145.0,
			float(_controller.get("wall_route_required_advantage"))
		)
		var wall_advantage := wall_clearance - best_direct_clearance
		var wall_solves_blocked_lane := (
			not direct_lane_available
			and wall_clearance >= required_wall_clearance
		)
		var wall_is_clearly_better := (
			wall_clearance >= required_wall_clearance
			and wall_advantage >= required_wall_advantage
		)
		var useful_wall_route := (
			wall_solves_blocked_lane or wall_is_clearly_better
		)
		var wall_candidate := _candidate(
			Schema.ACTION_WALL_BANK_SHOT,
			far_target,
			0,
			shot_base - 0.70
			+ clampf(wall_advantage / 520.0, -0.65, 0.75),
			0.58,
			(
				kick_ready
				and not wall_bounce.is_zero_approx()
				and useful_wall_route
				and (
					not one_vs_one
					or _one_vs_one_shot_allowed(far_target)
				)
			),
			(
				"bank_solves_blocked_lane"
				if wall_solves_blocked_lane
				else "bank_route_clearly_better"
			),
			clampf((wall_advantage + 180.0) / 700.0, 0.0, 1.0)
		)
		wall_candidate["wall_bounce"] = wall_bounce
		wall_candidate["route_distance"] = float(wall_route.get("distance", 0.0))
		candidates.append(wall_candidate)
	var team_candidates_added := false
	if _controller.has_method("_get_ranked_team_pass_plans"):
		var pass_search_count: int = _get_pass_search_count(5)
		var ranked_plans := _controller.call(
			"_get_ranked_team_pass_plans",
			opponent_goal,
			pass_search_count,
			false
		) as Array
		for plan_variant in ranked_plans:
			if not plan_variant is Dictionary:
				continue
			var plan := plan_variant as Dictionary
			if _append_advanced_team_pass_candidate(
				candidates,
				plan,
				ball.get("global_position") as Vector2,
				attack_sign,
				kick_ready
			):
				team_candidates_added = true
	if not team_candidates_added:
		_append_legacy_pass_candidates(
			candidates,
			opponent_goal,
			ball.get("global_position") as Vector2,
			attack_sign,
			kick_ready
		)
	var nearest_pressure := float(_controller.call("_nearest_opponent_distance", ball.get("global_position")))
	var carry_target := _best_carry_target(goal_center)
	var carry_base: float = (
		0.35
		+ clampf(nearest_pressure / 900.0, 0.0, 0.7)
		- clampf(goal_distance / 7000.0, 0.0, 0.4)
	)
	carry_base += patient_attack_bonus * 1.10
	var carry_objective: float = 0.0
	var space_play_available: bool = bool(
		observation.get(
			"space_play_available",
			false
		)
	)
	if space_play_available and elite_goal_probability < 0.46:
		carry_base += 1.45
		carry_objective = maxf(
			carry_objective,
			clampf(
				float(
					observation.get(
						"space_play_quality",
						0.0
					)
				),
				0.0,
				1.0
			)
		)
		carry_target = observation.get(
			"space_play_destination",
			carry_target
		) as Vector2
	if one_vs_one:
		var followup_ready: bool = bool(
			observation.get(
				"shot_followup_ready",
				false
			)
		)
		var defender_beaten: bool = bool(
			observation.get(
				"offensive_defender_beaten",
				false
			)
		)
		if not followup_ready:
			carry_base += 0.72
			carry_objective = maxf(
				carry_objective,
				0.68
			)
		elif not defender_beaten:
			carry_base += 0.38
			carry_objective = maxf(
				carry_objective,
				0.55
			)

	if elite_goal_probability >= 0.50:
		carry_base -= 6.0
	elif elite_goal_probability >= 0.34:
		carry_base -= 2.15

	candidates.append(_candidate(
		Schema.ACTION_CARRY,
		carry_target,
		0,
		carry_base,
		0.30,
		true,
		"create_space_then_finish",
		carry_objective
	))
	if bool(observation.get("own_goal_danger", false)):
		var clear_target := Vector2(goal_center.x, clampf((ball.get("global_position") as Vector2).y, mouth_range.x, mouth_range.y))
		candidates.append(_candidate(Schema.ACTION_CLEAR_OPEN_SIDE, clear_target, 0, 2.5, 0.35, true, "emergency_clear", 1.0))
	if nearest_pressure > 700.0 and not kick_ready:
		candidates.append(_candidate(Schema.ACTION_DELAY_TOUCH, carry_target, 0, 0.1, 0.16, true, "wait_for_control"))


func _append_defensive_candidates(
	candidates: Array[Dictionary],
	observation: Dictionary,
	own_goal_danger: bool
) -> void:
	var ball: Node = _controller.get("ball")
	var player: Node = _controller.get("controlled_player")
	var own_goal: Node = _controller.call("_get_own_goal")
	if own_goal == null or ball == null or player == null:
		return

	var predicted_ball: Vector2 = _controller.call(
		"_get_predicted_ball_position"
	)
	var carrier: Node = _controller.call(
		"_get_likely_opponent_ball_carrier"
	)
	var own_goal_center: Vector2 = _controller.call(
		"_get_goal_center",
		own_goal
	)
	var primary: bool = bool(
		observation.get("primary_chaser", false)
	)
	var context: Dictionary = _get_challenge_context(
		observation,
		predicted_ball
	)
	var race_advantage: float = float(
		context.get("race_advantage", 0.0)
	)
	var shot_threat: float = float(
		context.get("shot_threat", 0.0)
	)
	var open_net_risk: float = float(
		context.get("open_net_risk", 0.0)
	)
	var immediate_tackle: bool = bool(
		context.get("immediate_tackle", false)
	)
	var safe_to_challenge: bool = bool(
		context.get("safe_to_challenge", false)
	)
	var has_cover: bool = bool(
		context.get("has_cover", false)
	)
	var clear_self_first: bool = bool(
		context.get("clear_self_first", false)
	)
	var can_intercept_goal_threat: bool = bool(
		context.get("can_intercept_goal_threat", false)
	)
	var pre_shot_risk: float = clampf(
		float(context.get("pre_shot_risk", 0.0)),
		0.0,
		1.0
	)
	var pre_shot_intercept: Vector2 = context.get(
		"pre_shot_intercept",
		Vector2.ZERO
	) as Vector2
	var pre_shot_emergency: bool = bool(
		context.get("pre_shot_emergency", false)
	)
	var carrier_peer_id: int = (
		int(carrier.get("owner_peer_id"))
		if carrier != null
		else 0
	)
	var stall_strength: float = clampf(
		float(
			observation.get(
				"opponent_stall_strength",
				0.0
			)
		),
		0.0,
		1.0
	)
	var stall_seconds: float = maxf(
		0.0,
		float(
			observation.get(
				"opponent_stall_seconds",
				0.0
			)
		)
	)
	var opponent_commit_signal: float = clampf(
		float(
			observation.get(
				"opponent_commit_signal",
				0.0
			)
		),
		0.0,
		1.0
	)
	var goal_proximity: float = clampf(
		float(
			observation.get(
				"defensive_goal_proximity",
				0.0
			)
		),
		0.0,
		1.0
	)
	var attacking_goal_proximity: float = clampf(
		float(
			observation.get(
				"attacking_goal_proximity",
				0.0
			)
		),
		0.0,
		1.0
	)
	var attacker_behind: bool = bool(
		observation.get(
			"attacker_behind_defender",
			false
		)
	)
	var player_ball_distance: float = (
		(player.get("global_position") as Vector2).distance_to(
			ball.get("global_position") as Vector2
		)
	)
	var stall_escalation: bool = (
		stall_seconds >= STALL_ESCALATION_SECONDS
		and player_ball_distance <= STALL_ESCALATION_DISTANCE
		and not attacker_behind
	)

	var challenge_possible: bool = (
		(primary or immediate_tackle)
		and safe_to_challenge
	)
	if has_cover and race_advantage >= -0.18:
		challenge_possible = (
			challenge_possible or primary
		)
	if (
		stall_escalation
		and primary
		and safe_to_challenge
		and (
			has_cover
			or attacking_goal_proximity < 0.45
			or immediate_tackle
		)
	):
		challenge_possible = true

	var challenge_base: float = (
		1.05 if primary else -0.35
	)
	if clear_self_first:
		challenge_base += 3.25
	if can_intercept_goal_threat:
		challenge_base += 2.50
	challenge_base += clampf(
		race_advantage * 1.4,
		-1.5,
		1.2
	)
	challenge_base -= open_net_risk * 1.85
	challenge_base -= shot_threat * 0.35
	if not immediate_tackle:
		challenge_base -= pre_shot_risk * 1.85
	challenge_base += opponent_commit_signal * 1.15
	challenge_base += stall_strength * lerpf(
		0.78,
		0.30,
		goal_proximity
	)
	if (
		stall_strength > 0.0
		and attacking_goal_proximity >= 0.45
		and not has_cover
		and not immediate_tackle
	):
		var true_one_vs_one: bool = (
			_controller.has_method(
				"_is_true_one_vs_one"
			)
			and bool(
				_controller.call(
					"_is_true_one_vs_one"
				)
			)
		)
		if true_one_vs_one:
			challenge_base += (
				stall_strength
				* lerpf(
					0.55,
					1.45,
					attacking_goal_proximity
				)
			)
		else:
			challenge_base -= stall_strength * lerpf(
				0.35,
				0.95,
				attacking_goal_proximity
			)
	if (
		stall_strength > 0.0
		and goal_proximity >= 0.45
		and not has_cover
		and not immediate_tackle
	):
		challenge_base -= stall_strength * 0.70
	if immediate_tackle:
		challenge_base += 0.75
	if stall_escalation and challenge_possible:
		challenge_base += 1.10

	var challenge_candidate: Dictionary = _candidate(
		Schema.ACTION_CHALLENGE_BALL,
		predicted_ball,
		carrier_peer_id,
		challenge_base,
		0.20,
		challenge_possible,
		"stall_window_tackle"
		if stall_escalation and challenge_possible
		else (
			"winnable_press"
			if challenge_possible
			else "unsafe_press"
		),
		1.0
		if clear_self_first or can_intercept_goal_threat
		else clampf(
			(race_advantage + 0.35) / 1.0,
			0.0,
			1.0
		)
	)
	challenge_candidate["stall_escalation"] = (
		stall_escalation
	)
	candidates.append(challenge_candidate)

	if clear_self_first or can_intercept_goal_threat:
		return

	if carrier != null:
		var lane_target: Vector2 = _controller.call(
			"_get_anticipatory_goal_defense_position",
			carrier,
			own_goal,
			false
		) as Vector2
		if lane_target.is_zero_approx():
			var carrier_position: Vector2 = carrier.get(
				"global_position"
			)
			lane_target = carrier_position.lerp(
				own_goal_center,
				0.42
			)

		candidates.append(_candidate(
			Schema.ACTION_SHADOW_DEFEND,
			lane_target,
			carrier_peer_id,
			0.85
			+ shot_threat * 1.25
			+ pre_shot_risk * 2.35
			+ (0.70 if pre_shot_emergency else 0.0)
			+ open_net_risk * 1.55
			+ maxf(0.0, -race_advantage) * 0.85
			+ (0.45 if own_goal_danger else 0.0)
			+ stall_strength * (
				0.38 + goal_proximity * 0.52
			)
			+ opponent_commit_signal * 1.25,
			0.28,
			true,
			"read_release_and_shadow"
			if stall_strength > 0.0
			else "block_shot_and_delay"
		))

		var standard_fake_allowed: bool = (
			not own_goal_danger
			and shot_threat < 0.60
			and pre_shot_risk < 0.46
			and open_net_risk < 0.62
		)
		var stall_fake_allowed: bool = (
			stall_strength > 0.0
			and primary
			and not attacker_behind
			and shot_threat < 0.84
			and pre_shot_risk < 0.58
			and (
				has_cover
				or goal_proximity < 0.88
				or player_ball_distance
				<= STALL_NEAR_GOAL_PROBE_DISTANCE
			)
		)
		if standard_fake_allowed or stall_fake_allowed:
			if stall_fake_allowed:
				var bait_plan: Dictionary = _build_stall_bait_plan(
					carrier,
					own_goal,
					lane_target,
					observation
				)
				if not bait_plan.is_empty():
					var bait_candidate: Dictionary = _candidate(
						Schema.ACTION_FAKE_CHALLENGE,
						bait_plan.get(
							"probe_target",
							lane_target
						),
						carrier_peer_id,
						0.38
						+ maxf(
							0.0,
							-race_advantage
						) * 0.35
						+ stall_strength * (
							1.18
							+ goal_proximity * 0.48
							+ attacking_goal_proximity * 0.42
						)
						- opponent_commit_signal * 0.85,
						float(
							bait_plan.get(
								"commit_seconds",
								0.56
							)
						),
						true,
						"stall_bait_probe",
						clampf(
							stall_strength
							* (
								1.0
								- open_net_risk * 0.45
							),
							0.0,
							1.0
						)
					)
					for key_variant in bait_plan.keys():
						bait_candidate[key_variant] = (
							bait_plan[key_variant]
						)
					bait_candidate["stall_bait"] = true
					candidates.append(bait_candidate)
			else:
				var fake_target: Vector2 = predicted_ball.lerp(
					lane_target,
					0.5
				)
				candidates.append(_candidate(
					Schema.ACTION_FAKE_CHALLENGE,
					fake_target,
					carrier_peer_id,
					0.25
					+ maxf(
						0.0,
						-race_advantage
					) * 0.55,
					0.22,
					true,
					"show_press_keep_goal_side"
				))

	var protect_target: Vector2 = (
		ball.get("global_position") as Vector2
	).lerp(
		own_goal_center,
		0.58
	)
	if carrier != null and (
		attacker_behind
		or open_net_risk >= 0.45
		or shot_threat >= 0.55
	):
		protect_target = (
			_get_emergency_goal_side_recovery_target(
				carrier,
				own_goal
			)
		)
	if pre_shot_risk >= 0.52 and not pre_shot_intercept.is_zero_approx():
		protect_target = pre_shot_intercept
	candidates.append(_candidate(
		Schema.ACTION_PROTECT_GOAL,
		protect_target,
		0,
		0.72
		+ open_net_risk * 1.85
		+ shot_threat * 1.35
		+ pre_shot_risk * 2.10
		+ (0.85 if pre_shot_emergency else 0.0)
		+ (0.65 if own_goal_danger else 0.0)
		+ (0.25 if not has_cover else 0.0)
		+ stall_strength * goal_proximity * 0.72
		+ opponent_commit_signal * 1.10,
		0.38,
		true,
		"protect_then_counter"
		if stall_strength > 0.0
		else "preserve_last_defender"
	))

	var mark: Node = _controller.call(
		"_select_marking_target"
	)
	if mark != null:
		var mark_target: Vector2 = _controller.call(
			"_get_goal_side_mark_position",
			mark,
			own_goal
		)
		candidates.append(_candidate(
			Schema.ACTION_MARK_OPPONENT,
			mark_target,
			int(mark.get("owner_peer_id")),
			0.3,
			0.48,
			not primary,
			"mark_threat"
		))

	var rotate_target: Vector2 = protect_target
	if (
		not attacker_behind
		and open_net_risk < 0.45
	):
		rotate_target = _controller.call(
			"_get_defensive_position"
		) as Vector2
	candidates.append(_candidate(
		Schema.ACTION_ROTATE_BACK,
		rotate_target,
		0,
		0.45
		+ open_net_risk * 1.2
		+ (0.55 if not primary else 0.0)
		+ opponent_commit_signal * 0.65,
		0.44,
		true,
		"restore_goal_side"
	))


func _build_stall_bait_plan(
	carrier: Node,
	own_goal: Node,
	lane_target: Vector2,
	observation: Dictionary
) -> Dictionary:
	var ball: Node = _controller.get("ball")
	var player: Node = _controller.get("controlled_player")
	if (
		carrier == null
		or own_goal == null
		or ball == null
		or player == null
	):
		return {}

	var ball_position: Vector2 = ball.get(
		"global_position"
	)
	var goal_center: Vector2 = _controller.call(
		"_get_goal_center",
		own_goal
	)
	var ball_goal_distance: float = ball_position.distance_to(
		goal_center
	)
	if ball_goal_distance <= 1.0:
		return {}

	var goal_proximity: float = clampf(
		float(
			observation.get(
				"defensive_goal_proximity",
				0.0
			)
		),
		0.0,
		1.0
	)
	var stall_strength: float = clampf(
		float(
			observation.get(
				"opponent_stall_strength",
				0.0
			)
		),
		0.0,
		1.0
	)
	var attacking_goal_proximity: float = clampf(
		float(
			observation.get(
				"attacking_goal_proximity",
				0.0
			)
		),
		0.0,
		1.0
	)
	var commitment_risk: float = maxf(
		goal_proximity,
		attacking_goal_proximity * 0.85
	)
	var toward_goal: Vector2 = ball_position.direction_to(
		goal_center
	)
	var tangent: Vector2 = Vector2(
		-toward_goal.y,
		toward_goal.x
	)
	var probe_distance: float = lerpf(
		STALL_PROBE_MINIMUM_DISTANCE,
		STALL_NEAR_GOAL_PROBE_DISTANCE,
		commitment_risk
	)
	var lateral_feint: float = lerpf(
		70.0,
		125.0,
		stall_strength
	) * lerpf(
		1.0,
		0.62,
		commitment_risk
	)
	var probe_target: Vector2 = (
		ball_position
		+ toward_goal * probe_distance
		+ tangent
		* _stall_probe_side
		* lateral_feint
	)

	# A fake challenge may approach the carrier, but it must remain goal-side
	# of the ball unless a separate challenge action is selected.
	var maximum_probe_goal_distance: float = (
		ball_goal_distance - 70.0
	)
	if (
		probe_target.distance_to(goal_center)
		>= maximum_probe_goal_distance
	):
		var safe_ratio: float = clampf(
			probe_distance
			/ maxf(
				1.0,
				ball_goal_distance
			),
			0.08,
			0.58
		)
		probe_target = ball_position.lerp(
			goal_center,
			safe_ratio
		)
		probe_target += (
			tangent
			* _stall_probe_side
			* lateral_feint
			* 0.55
		)

	var retreat_target: Vector2 = lane_target.lerp(
		goal_center,
		lerpf(
			0.08,
			0.30,
			commitment_risk
		)
	)
	retreat_target -= (
		tangent
		* _stall_probe_side
		* lateral_feint
		* 0.28
	)

	probe_target = _controller.call(
		"_clamp_to_field",
		probe_target
	) as Vector2
	retreat_target = _controller.call(
		"_clamp_to_field",
		retreat_target
	) as Vector2

	var probe_seconds: float = lerpf(
		0.22,
		0.14,
		commitment_risk
	)
	var recovery_seconds: float = lerpf(
		0.28,
		0.42,
		commitment_risk
	)
	return {
		"probe_target": probe_target,
		"retreat_target": retreat_target,
		"probe_seconds": probe_seconds,
		"recovery_seconds": recovery_seconds,
		"commit_seconds": (
			probe_seconds + recovery_seconds
		),
		"bait_side": _stall_probe_side
	}


func _append_support_candidates(
	candidates: Array[Dictionary],
	observation: Dictionary
) -> void:
	if not _has_other_teammate():
		var player: Node = _controller.get("controlled_player")
		if player != null and bool(player.call("cpu_has_kickable_ball")):
			_append_possession_candidates(candidates, observation)
		else:
			_append_loose_ball_candidates(
				candidates,
				observation,
				true,
				bool(observation.get("own_goal_danger", false))
			)
		return
	var assignment: Dictionary = {}
	if _controller.has_method("_get_team_play_support_assignment"):
		assignment = _controller.call(
			"_get_team_play_support_assignment"
		) as Dictionary
	var support_target: Vector2 = Vector2.ZERO
	var support_intent := LEGACY_INTENT_WIDE_SUPPORT
	var support_role := "legacy"
	var support_reason := "support_lane"
	var support_base := 0.72
	if not assignment.is_empty():
		support_target = assignment.get("position", Vector2.ZERO)
		support_intent = StringName(
			assignment.get("intent", LEGACY_INTENT_WIDE_SUPPORT)
		)
		support_role = str(assignment.get("role", "support"))
		support_reason = str(
			assignment.get("reason", "coordinated_support")
		)
		match support_role:
			"run_behind":
				support_base = 0.98
			"far_post":
				support_base = 0.97
			"rebound":
				support_base = 0.96
			"return_lane":
				support_base = 0.94
			"cover":
				support_base = 0.93
			"width":
				support_base = 0.91
			"decoy":
				support_base = 0.84
			"runner":
				support_base = 0.96
			"creator":
				support_base = 0.90
			"safety":
				support_base = 0.88
	if support_target.is_zero_approx():
		support_target = _controller.call(
			"_get_attacking_support_position"
		)
	var support_candidate := _candidate(
		Schema.ACTION_SUPPORT_TEAMMATE,
		support_target,
		0,
		support_base,
		0.58,
		true,
		support_reason,
		0.56 if not assignment.is_empty() else 0.25
	)
	support_candidate["team_intent"] = support_intent
	support_candidate["support_role"] = support_role
	candidates.append(support_candidate)

	var open_target := _best_open_space_target(support_target)
	var move_open_candidate := _candidate(
		Schema.ACTION_MOVE_OPEN,
		open_target,
		0,
		0.42 if assignment.is_empty() else 0.28,
		0.46,
		true,
		"secondary_open_space"
	)
	move_open_candidate["team_intent"] = LEGACY_INTENT_WIDE_SUPPORT
	candidates.append(move_open_candidate)
	if not bool(observation.get("primary_chaser", false)):
		var safety_role := support_role in [
			"cover",
			"return_lane",
			"rebound",
			"safety"
		]
		var discipline_base := 0.50
		if support_role in ["cover", "safety"]:
			discipline_base = 0.70
		elif safety_role:
			discipline_base = 0.61
		var discipline_candidate := _candidate(
			Schema.ACTION_AVOID_DOUBLE_COMMIT,
			support_target,
			0,
			discipline_base,
			0.48,
			true,
			"role_discipline"
		)
		discipline_candidate["team_intent"] = (
			LEGACY_INTENT_COVER
			if support_role in ["cover", "safety"]
			else support_intent
		)
		candidates.append(discipline_candidate)
	var wait_candidate := _candidate(
		Schema.ACTION_WAIT,
		support_target,
		0,
		-0.42,
		0.12,
		true,
		"hold_shape"
	)
	wait_candidate["team_intent"] = support_intent
	candidates.append(wait_candidate)


func _candidate(
	action: StringName,
	target_position: Vector2,
	target_peer_id: int,
	base_score: float,
	commit_seconds: float,
	possible: bool,
	reason: String,
	objective_advantage: float = 0.0
) -> Dictionary:
	return {
		"action": action,
		"target_position": target_position,
		"target_peer_id": target_peer_id,
		"base_score": base_score,
		"commit_seconds": commit_seconds,
		"urgency": clampf(base_score / 2.5, 0.0, 1.0),
		"possible": possible,
		"reason": reason,
		"objective_advantage": objective_advantage
	}


func _execute_decision(decision: Dictionary) -> bool:
	var action := StringName(decision.get("action", Schema.ACTION_IDLE))
	match action:
		Schema.ACTION_DIRECT_SHOT, Schema.ACTION_NEAR_POST_SHOT, Schema.ACTION_FAR_POST_SHOT:
			return _execute_shot(decision, false)
		Schema.ACTION_WALL_BANK_SHOT:
			return _execute_shot(decision, true)
		Schema.ACTION_PASS_AHEAD, Schema.ACTION_SAFE_PASS:
			return _execute_pass(decision)
		Schema.ACTION_CLEAR_OPEN_SIDE:
			_controller.call("_update_emergency_clearance")
			return true
		Schema.ACTION_CARRY:
			var opponent_goal: Node = _controller.call("_get_opponent_goal")
			if opponent_goal == null:
				return false
			_controller.call("_clear_attack_plan")
			if (
				_controller.has_method(
					"_try_begin_one_vs_one_space_play"
				)
				and bool(
					_controller.call(
						"_try_begin_one_vs_one_space_play",
						opponent_goal,
						true
					)
				)
			):
				_controller.call(
					"_update_one_vs_one_space_play"
				)
				_controller.call(
					"_set_tactical_intent",
					LEGACY_INTENT_DRIBBLE,
					decision.get(
						"target_position",
						Vector2.ZERO
					)
				)
				return true
			_controller.call("_update_dribble", opponent_goal)
			_controller.call("_set_tactical_intent", LEGACY_INTENT_DRIBBLE, decision.get("target_position", Vector2.ZERO))
			return true
		Schema.ACTION_DELAY_TOUCH:
			return _execute_delay(decision)
		Schema.ACTION_CHALLENGE_BALL:
			if (
				bool(
					decision.get(
						"stall_escalation",
						false
					)
				)
				and not bool(
					decision.get(
						"stall_event_recorded",
						false
					)
				)
			):
				decision["stall_event_recorded"] = true
				_record_defense_event(
					&"stall_escalation_challenges"
				)
			var challenge_peer_id := int(
				decision.get("target_peer_id", 0)
			)
			if challenge_peer_id > 0:
				_controller.call(
					"_try_begin_duel_resolution",
					challenge_peer_id,
					_now()
				)
				if bool(
					_controller.call(
						"_update_duel_resolution_decision"
					)
				):
					return true
			_controller.set(
				"_movement_target",
				decision.get("target_position", Vector2.ZERO)
			)
			_controller.call(
				"_set_tactical_intent",
				LEGACY_INTENT_CHASE,
				decision.get("target_position", Vector2.ZERO),
				challenge_peer_id
			)
			_controller.call("_try_defensive_ball_win")
			return true
		Schema.ACTION_FAKE_CHALLENGE:
			return _execute_fake_challenge(decision)
		Schema.ACTION_SHADOW_DEFEND:
			if bool(_controller.call("_update_anticipatory_carrier_defense")):
				return true
			_controller.set("_movement_target", decision.get("target_position", Vector2.ZERO))
			_controller.call("_set_tactical_intent", LEGACY_INTENT_MARK, decision.get("target_position", Vector2.ZERO), int(decision.get("target_peer_id", 0)))
			return true
		Schema.ACTION_PROTECT_GOAL, Schema.ACTION_ROTATE_BACK:
			_controller.set("_movement_target", decision.get("target_position", Vector2.ZERO))
			_controller.call("_set_tactical_intent", LEGACY_INTENT_COVER, decision.get("target_position", Vector2.ZERO))
			return true
		Schema.ACTION_MARK_OPPONENT:
			_controller.set("_movement_target", decision.get("target_position", Vector2.ZERO))
			_controller.call("_set_tactical_intent", LEGACY_INTENT_MARK, decision.get("target_position", Vector2.ZERO), int(decision.get("target_peer_id", 0)))
			return true
		Schema.ACTION_MOVE_OPEN, Schema.ACTION_SUPPORT_TEAMMATE, Schema.ACTION_AVOID_DOUBLE_COMMIT:
			_controller.call("_clear_attack_plan")
			var support_target: Vector2 = decision.get(
				"target_position",
				Vector2.ZERO
			)
			var support_intent := StringName(
				decision.get(
					"team_intent",
					LEGACY_INTENT_WIDE_SUPPORT
				)
			)
			_controller.set("_movement_target", support_target)
			_controller.call(
				"_set_tactical_intent",
				support_intent,
				support_target
			)
			return true
		Schema.ACTION_WAIT:
			_controller.set("_movement_target", decision.get("target_position", _controller.get("controlled_player").get("global_position")))
			_controller.call("_set_tactical_intent", LEGACY_INTENT_IDLE, decision.get("target_position", Vector2.ZERO))
			return true
	return false


func _execute_fake_challenge(
	decision: Dictionary
) -> bool:
	var target_peer_id: int = int(
		decision.get("target_peer_id", 0)
	)
	if not bool(
		decision.get("stall_bait", false)
	):
		var standard_target: Vector2 = decision.get(
			"target_position",
			Vector2.ZERO
		)
		_controller.set(
			"_movement_target",
			standard_target
		)
		_controller.call(
			"_set_tactical_intent",
			LEGACY_INTENT_COVER,
			standard_target,
			target_peer_id
		)
		return true

	var player: Node = _controller.get(
		"controlled_player"
	)
	var ball: Node = _controller.get("ball")
	var carrier: Node = _controller.call(
		"_get_opponent_by_peer_id",
		target_peer_id
	)
	if carrier == null:
		carrier = _controller.call(
			"_get_likely_opponent_ball_carrier"
		)
	if player == null or ball == null or carrier == null:
		return false

	if not bool(
		decision.get("bait_started", false)
	):
		decision["bait_started"] = true
		_stall_probe_side *= -1.0
		_record_defense_event(
			&"stall_fake_challenges"
		)

	var now: float = _now()
	var elapsed: float = maxf(
		0.0,
		now - float(
			decision.get(
				"selected_at",
				now
			)
		)
	)
	var probe_seconds: float = maxf(
		0.04,
		float(
			decision.get(
				"probe_seconds",
				0.18
			)
		)
	)
	var live_commit_signal: float = (
		_get_live_opponent_commit_signal(
			carrier,
			ball
		)
	)
	var retreat_target: Vector2 = (
		_get_live_stall_retreat_target(
			carrier,
			decision
		)
	)
	var movement_target: Vector2
	var tactical_intent: StringName = LEGACY_INTENT_COVER

	if live_commit_signal >= STALL_LIVE_COMMIT_THRESHOLD:
		if not bool(
			decision.get(
				"forced_action_recorded",
				false
			)
		):
			decision["forced_action_recorded"] = true
			_record_defense_event(
				&"stall_forced_actions"
			)

		var live_observation: Dictionary = (
			ObservationBuilder.build(
				_controller
			)
		)
		_write_opponent_behavior_features(
			live_observation
		)
		var challenge_context: Dictionary = (
			_get_challenge_context(
				live_observation,
				ball.get("global_position")
				as Vector2
			)
		)
		var player_ball_distance: float = (
			(player.get("global_position") as Vector2)
			.distance_to(
				ball.get("global_position")
				as Vector2
			)
		)
		var can_poke: bool = (
			bool(
				challenge_context.get(
					"safe_to_challenge",
					false
				)
			)
			and player_ball_distance
			<= STALL_ESCALATION_DISTANCE
			and (
				bool(
					challenge_context.get(
						"has_cover",
						false
					)
				)
				or float(
					live_observation.get(
						"attacking_goal_proximity",
						0.0
					)
				) < 0.45
				or bool(
					challenge_context.get(
						"immediate_tackle",
						false
					)
				)
			)
		)
		if can_poke:
			movement_target = ball.get(
				"global_position"
			) as Vector2
			tactical_intent = LEGACY_INTENT_CHASE
			_controller.set(
				"_movement_target",
				movement_target
			)
			_controller.call(
				"_set_tactical_intent",
				tactical_intent,
				movement_target,
				target_peer_id
			)
			_controller.call(
				"_try_defensive_ball_win"
			)
			return true

		movement_target = retreat_target
		tactical_intent = LEGACY_INTENT_MARK
	elif elapsed < probe_seconds:
		movement_target = decision.get(
			"probe_target",
			decision.get(
				"target_position",
				Vector2.ZERO
			)
		) as Vector2
	else:
		movement_target = retreat_target
		tactical_intent = LEGACY_INTENT_MARK

	_controller.set(
		"_movement_target",
		movement_target
	)
	_controller.call(
		"_set_tactical_intent",
		tactical_intent,
		movement_target,
		target_peer_id
	)
	return true


func _get_live_opponent_commit_signal(
	carrier: Node,
	ball: Node
) -> float:
	if carrier == null or ball == null:
		return 1.0
	var input_variant: Variant = carrier.get(
		"server_direction"
	)
	var carrier_input: Vector2 = (
		input_variant as Vector2
		if input_variant is Vector2
		else Vector2.ZERO
	)
	var carrier_velocity: Vector2 = carrier.get(
		"linear_velocity"
	)
	var ball_velocity: Vector2 = ball.get(
		"linear_velocity"
	)
	var commit_signal: float = carrier_input.length()
	commit_signal = maxf(
		commit_signal,
		carrier_velocity.length() / 850.0
	)
	commit_signal = maxf(
		commit_signal,
		ball_velocity.length() / 1350.0
	)
	if bool(carrier.get("server_is_charging")):
		commit_signal = 1.0
	return clampf(
		commit_signal,
		0.0,
		1.0
	)


func _get_live_stall_retreat_target(
	carrier: Node,
	decision: Dictionary
) -> Vector2:
	var fallback: Vector2 = decision.get(
		"retreat_target",
		decision.get(
			"target_position",
			Vector2.ZERO
		)
	)
	var own_goal: Node = _controller.call(
		"_get_own_goal"
	)
	if carrier == null or own_goal == null:
		return fallback
	var target: Vector2 = _controller.call(
		"_get_anticipatory_goal_defense_position",
		carrier,
		own_goal,
		false
	) as Vector2
	if target.is_zero_approx():
		var goal_center: Vector2 = _controller.call(
			"_get_goal_center",
			own_goal
		)
		target = (
			carrier.get("global_position")
			as Vector2
		).lerp(
			goal_center,
			0.46
		)
	return _controller.call(
		"_clamp_to_field",
		target.lerp(
			fallback,
			0.45
		)
	) as Vector2


func _record_defense_event(
	metric: StringName
) -> void:
	var manager: Node = _controller.get(
		"match_manager"
	)
	var player: Node = _controller.get(
		"controlled_player"
	)
	if (
		manager == null
		or player == null
		or not manager.has_method(
			"record_cpu_defense_event"
		)
	):
		return
	manager.call(
		"record_cpu_defense_event",
		StringName(player.get("team")),
		metric
	)


func _execute_shot(decision: Dictionary, wall_shot: bool) -> bool:
	var player: Node = _controller.get("controlled_player")
	var ball: Node = _controller.get("ball")
	if player == null or ball == null:
		return false
	var destination: Vector2 = decision.get("target_position", Vector2.ZERO)
	if destination.is_zero_approx():
		return false
	if (
		not wall_shot
		and _controller.has_method("_shot_target_is_viable")
		and not bool(_controller.call(
			"_shot_target_is_viable",
			destination
		))
	):
		var blocked_goal: Node = _controller.call("_get_opponent_goal")
		if (
			blocked_goal != null
			and _controller.has_method("_try_execute_obvious_team_pass")
			and bool(_controller.call(
				"_try_execute_obvious_team_pass",
				blocked_goal
			))
		):
			clear_active_decision()
			return true
		if blocked_goal == null:
			return false
		_controller.call("_clear_attack_plan")
		_controller.call("_update_dribble", blocked_goal)
		_controller.call(
			"_set_tactical_intent",
			LEGACY_INTENT_DRIBBLE,
			_best_carry_target(
				_controller.call("_get_goal_center", blocked_goal) as Vector2
			)
		)
		return true
	if not _one_vs_one_shot_allowed(destination):
		var opponent_goal: Node = _controller.call(
			"_get_opponent_goal"
		)
		if opponent_goal == null:
			return false
		_controller.call("_clear_attack_plan")
		_controller.call(
			"_update_dribble",
			opponent_goal
		)
		_controller.call(
			"_set_tactical_intent",
			LEGACY_INTENT_DRIBBLE,
			_best_carry_target(
				_controller.call(
					"_get_goal_center",
					opponent_goal
				) as Vector2
			)
		)
		return true
	_controller.call("_clear_attack_plan")
	_controller.set("_plan_is_pass", false)
	_controller.set("_planned_receiver", null)
	_controller.set("_plan_expires_at", _now() + clampf(float(decision.get("commit_seconds", 0.4)), 0.2, 1.2))
	if wall_shot:
		var wall_bounce: Vector2 = decision.get("wall_bounce", Vector2.ZERO)
		if wall_bounce.is_zero_approx():
			return false
		_controller.set("_planned_destination", destination)
		_controller.set("_shot_target", wall_bounce)
		_controller.set("_planned_route_distance", maxf(
			float(decision.get("route_distance", 0.0)),
			(ball.get("global_position") as Vector2).distance_to(wall_bounce)
			+ wall_bounce.distance_to(destination)
		))
		_controller.set("_plan_uses_wall", true)
	else:
		_controller.call("_set_planned_route", destination, true, true)
	var shot_target: Vector2 = _controller.get("_shot_target")
	var strike_position: Vector2 = _controller.call("_get_strike_position", shot_target)
	_controller.set("_movement_target", strike_position)
	_controller.call("_set_tactical_intent", LEGACY_INTENT_SHOOT, shot_target)
	_controller.call("_try_begin_shot", false)
	return true


func _execute_pass(decision: Dictionary) -> bool:
	var receiver: Node = _controller.call(
		"_get_teammate_by_peer_id",
		int(decision.get("target_peer_id", 0))
	)
	if receiver == null:
		return false
	var player: Node = _controller.get("controlled_player")
	var manager: Node = _controller.get("match_manager")
	if (
		bool(player.get("server_is_charging"))
		and not bool(_controller.get("_plan_is_pass"))
	):
		player.call("cpu_cancel_shot_charge")
		_controller.call("_reset_cpu_charge_tracking")
	var destination: Vector2 = decision.get(
		"target_position",
		receiver.get("global_position")
	)
	var team_plan := decision.get("team_plan", {}) as Dictionary
	var opponent_goal: Node = _controller.call("_get_opponent_goal")
	var applied_team_plan := false
	if (
		not team_plan.is_empty()
		and opponent_goal != null
		and _controller.has_method("_apply_team_pass_plan")
	):
		applied_team_plan = bool(_controller.call(
			"_apply_team_pass_plan",
			team_plan,
			opponent_goal,
			_now()
		))
	if not applied_team_plan:
		_controller.call("_clear_attack_plan")
		_controller.set("_plan_is_pass", true)
		_controller.set("_planned_receiver", receiver)
		_controller.set(
			"_plan_expires_at",
			_now() + clampf(
				float(decision.get("commit_seconds", 0.4)),
				0.2,
				1.2
			)
		)
		_controller.call(
			"_set_planned_route",
			destination,
			true,
			false
		)
		manager.call(
			"set_cpu_pass_intention",
			int(player.get("owner_peer_id")),
			int(receiver.get("owner_peer_id")),
			_controller.get("_planned_destination"),
			float(_controller.get("pass_intention_seconds"))
		)
		if (
			opponent_goal != null
			and _controller.has_method(
				"_register_elite_combination_play"
			)
		):
			_controller.call(
				"_register_elite_combination_play",
				receiver,
				_controller.get("_planned_destination"),
				opponent_goal
			)
	var shot_target: Vector2 = _controller.get("_shot_target")
	_controller.set(
		"_movement_target",
		_controller.call("_get_strike_position", shot_target)
	)
	_controller.call(
		"_set_tactical_intent",
		LEGACY_INTENT_PASS,
		shot_target,
		int(receiver.get("owner_peer_id"))
	)
	_controller.call("_try_begin_shot", false)
	return true


func _execute_delay(decision: Dictionary) -> bool:
	var player: Node = _controller.get("controlled_player")
	if player == null:
		return false
	if bool(player.get("server_is_charging")):
		player.call("cpu_cancel_shot_charge")
		_controller.call("_reset_cpu_charge_tracking")
	var target: Vector2 = decision.get("target_position", player.get("global_position"))
	_controller.set("_movement_target", target)
	_controller.call("_set_tactical_intent", LEGACY_INTENT_DRIBBLE, target)
	return true


func _decision_still_valid(
	decision: Dictionary,
	current_observation: Dictionary = {}
) -> bool:
	var action := StringName(
		decision.get("action", Schema.ACTION_IDLE)
	)
	if current_observation.is_empty():
		current_observation = ObservationBuilder.build(
			_controller
		)
		_augment_observation_with_opponent_behavior(
			current_observation,
			_now()
		)
	var possession: String = str(
		current_observation.get("possession", "loose")
	)
	var solo_roster: bool = not _has_other_teammate()
	var attacker_behind_defender: bool = bool(
		current_observation.get(
			"attacker_behind_defender",
			false
		)
	)
	if (
		attacker_behind_defender
		and action in [
			Schema.ACTION_CHALLENGE_BALL,
			Schema.ACTION_FAKE_CHALLENGE,
			Schema.ACTION_MARK_OPPONENT
		]
	):
		return false
	if action in Schema.POSSESSION_ACTIONS and possession == "opponent":
		return false
	if action in Schema.DEFENSIVE_ACTIONS and possession == "self":
		return false
	if (
		action in [
			Schema.ACTION_DIRECT_SHOT,
			Schema.ACTION_NEAR_POST_SHOT,
			Schema.ACTION_FAR_POST_SHOT
		]
		and _controller.has_method("_shot_target_is_viable")
		and not bool(_controller.call(
			"_shot_target_is_viable",
			decision.get("target_position", Vector2.ZERO) as Vector2
		))
	):
		return false
	if (
		action in [
			Schema.ACTION_MOVE_OPEN,
			Schema.ACTION_SUPPORT_TEAMMATE,
			Schema.ACTION_AVOID_DOUBLE_COMMIT
		]
		and (solo_roster or possession != "team")
	):
		return false
	if action == Schema.ACTION_WAIT and solo_roster:
		return false
	if action == Schema.ACTION_CHALLENGE_BALL:
		var context: Dictionary = _get_challenge_context(
			current_observation,
			decision.get(
				"target_position",
				Vector2.ZERO
			) as Vector2
		)
		if not bool(
			context.get("safe_to_challenge", false)
		):
			return false
	if action == Schema.ACTION_FAKE_CHALLENGE:
		if possession != "opponent":
			return false
		var fake_context: Dictionary = _get_challenge_context(
			current_observation,
			decision.get(
				"target_position",
				Vector2.ZERO
			) as Vector2
		)
		if bool(
			current_observation.get(
				"attacker_behind_defender",
				false
			)
		):
			return false
		if (
			not bool(
				decision.get(
					"stall_bait",
					false
				)
			)
			and (
				bool(
					fake_context.get(
						"goal_threat",
						false
					)
				)
				or float(
					fake_context.get(
						"shot_threat",
						0.0
					)
				) >= 0.78
			)
		):
			return false
	var target_peer_id: int = int(
		decision.get("target_peer_id", 0)
	)
	if target_peer_id > 0:
		var target_player: Node = _controller.call(
			"_get_teammate_by_peer_id",
			target_peer_id
		)
		if target_player == null:
			target_player = _controller.call(
				"_get_opponent_by_peer_id",
				target_peer_id
			)
		if target_player == null:
			return false
	return true


func _one_vs_one_shot_allowed(
	target: Vector2
) -> bool:
	if (
		_controller == null
		or not _controller.has_method("_is_true_one_vs_one")
		or not bool(_controller.call("_is_true_one_vs_one"))
	):
		return true
	if _controller.has_method("_get_elite_finish_preview"):
		var goal: Node = _controller.call("_get_opponent_goal")
		if goal != null:
			var plan: Dictionary = _controller.call(
				"_get_elite_finish_preview",
				goal
			) as Dictionary
			if float(plan.get("goal_probability", 0.0)) >= float(
				_controller.get("elite_controlled_shot_probability")
			):
				return true
	if not _controller.has_method("_one_vs_one_shot_has_finish_or_followup"):
		return false
	return bool(_controller.call(
		"_one_vs_one_shot_has_finish_or_followup",
		target
	))


func _append_advanced_team_pass_candidate(
	candidates: Array[Dictionary],
	team_plan: Dictionary,
	ball_position: Vector2,
	attack_sign: float,
	kick_ready: bool
) -> bool:
	var receiver: Node = _controller.call(
		"_get_teammate_by_peer_id",
		int(team_plan.get("receiver_peer_id", 0))
	)
	if receiver == null:
		return false
	var target: Vector2 = team_plan.get("destination", Vector2.ZERO)
	if target.is_zero_approx():
		return false
	var clearance := float(team_plan.get("route_clearance", 0.0))
	var progress := (target.x - ball_position.x) * attack_sign
	var quality := clampf(float(team_plan.get("quality", 0.0)), 0.0, 1.0)
	var interception_margin := clampf(
		float(team_plan.get("interception_margin", -0.5)),
		-0.5,
		1.5
	)
	var receiver_margin := clampf(
		float(team_plan.get("receiver_margin", -0.5)),
		-0.5,
		1.5
	)
	var chain_value := maxf(0.0, float(team_plan.get("chain_value", 0.0)))
	var defensive_error := maxf(
		0.0,
		float(team_plan.get("defensive_error_value", 0.0))
	)
	var counter_risk := clampf(
		float(team_plan.get("counter_risk", 1.0)),
		0.0,
		1.0
	)
	var kind := StringName(team_plan.get("kind", &"lead"))
	var safe_kind := kind in [
		&"to_feet",
		&"layoff",
		&"pressure_escape",
		&"recycle",
		&"square"
	]
	var action := (
		Schema.ACTION_SAFE_PASS
		if safe_kind
		else Schema.ACTION_PASS_AHEAD
	)
	var base_score := (
		0.18
		+ clampf(clearance / 700.0, -0.5, 0.9)
		+ clampf(progress / 2200.0, -0.65, 0.85)
		+ quality * 1.10
		+ clampf(interception_margin, -0.3, 1.0) * 0.58
		+ clampf(receiver_margin, -0.3, 1.0) * 0.30
		+ clampf(chain_value / 850.0, 0.0, 1.0) * 0.52
		+ clampf(defensive_error / 520.0, 0.0, 1.0) * 0.50
		- counter_risk * 0.76
	)
	if safe_kind:
		base_score += 0.10
	var candidate := _candidate(
		action,
		target,
		int(receiver.get("owner_peer_id")),
		base_score,
		clampf(float(team_plan.get("ball_time", 0.42)), 0.28, 0.64),
		kick_ready,
		str(team_plan.get("reason", "advanced_team_pass")),
		quality
	)
	candidate["team_plan"] = team_plan.duplicate(true)
	candidate["pass_kind"] = kind
	candidate["feature_overrides"] = _team_pass_feature_overrides(team_plan)
	candidates.append(candidate)
	return true


func _append_legacy_pass_candidates(
	candidates: Array[Dictionary],
	opponent_goal: Node,
	ball_position: Vector2,
	attack_sign: float,
	kick_ready: bool
) -> void:
	var receiver: Node = _controller.call("_select_pass_target", opponent_goal)
	if receiver == null:
		return
	var lead_target: Vector2 = _controller.call(
		"_get_lead_pass_target",
		receiver
	)
	var pass_clearance := float(_controller.call(
		"_minimum_pass_lane_clearance",
		lead_target
	))
	var progress := (lead_target.x - ball_position.x) * attack_sign
	var pass_base := (
		0.25
		+ clampf(pass_clearance / 700.0, -0.5, 0.8)
		+ clampf(progress / 2200.0, -0.6, 0.8)
	)
	candidates.append(_candidate(
		Schema.ACTION_PASS_AHEAD,
		lead_target,
		int(receiver.get("owner_peer_id")),
		pass_base,
		0.42,
		kick_ready,
		"legacy_progressive_pass",
		clampf((pass_clearance + progress * 0.15) / 900.0, 0.0, 1.0)
	))
	candidates.append(_candidate(
		Schema.ACTION_SAFE_PASS,
		receiver.get("global_position") as Vector2,
		int(receiver.get("owner_peer_id")),
		pass_base - 0.28,
		0.34,
		kick_ready,
		"legacy_retention_pass"
	))


func _team_pass_feature_overrides(plan: Dictionary) -> Dictionary:
	var kind := StringName(plan.get("kind", &"lead"))
	return {
		"pass_available": 1.0,
		"pass_lane": clampf(
			float(plan.get("route_clearance", 0.0)) / 1000.0,
			-1.0,
			1.5
		),
		"pass_progress": clampf(
			float(plan.get("forward_progress", 0.0)) / 2200.0,
			-1.0,
			1.0
		),
		"pass_receiver_open": clampf(
			float(plan.get("openness", 0.0)) / 1500.0,
			0.0,
			1.5
		),
		"pass_quality": clampf(float(plan.get("quality", 0.0)), 0.0, 1.0),
		"pass_interception_margin": clampf(
			float(plan.get("interception_margin", -0.5)),
			-1.0,
			1.5
		),
		"pass_receiver_margin": clampf(
			float(plan.get("receiver_margin", -0.5)),
			-1.0,
			1.5
		),
		"pass_chain_value": clampf(
			float(plan.get("chain_value", 0.0)) / 900.0,
			0.0,
			1.0
		),
		"pass_counter_risk": clampf(
			float(plan.get("counter_risk", 1.0)),
			0.0,
			1.0
		),
		"pass_defensive_error": clampf(
			float(plan.get("defensive_error_value", 0.0)) / 650.0,
			0.0,
			1.0
		),
		"pass_is_through": 1.0 if kind in [
			&"through",
			&"diagonal_split",
			&"blindside",
			&"overlap",
			&"underlap"
		] else 0.0,
		"pass_is_switch": 1.0 if kind == &"wide_switch" else 0.0,
		"pass_is_cutback": 1.0 if kind == &"cutback" else 0.0,
		"pass_is_wall": 1.0 if kind == &"wall_bank" else 0.0,
		"pass_is_combination": 1.0 if kind in [
			&"one_two",
			&"third_man",
			&"overlap",
			&"underlap"
		] else 0.0,
		"pass_is_pressure_escape": 1.0 if kind in [
			&"pressure_escape",
			&"layoff",
			&"recycle"
		] else 0.0,
		"pass_is_blindside": 1.0 if kind == &"blindside" else 0.0,
		"pass_is_square": 1.0 if kind == &"square" else 0.0,
		"pass_is_recycle": 1.0 if kind == &"recycle" else 0.0
	}


func _best_carry_target(goal_center: Vector2) -> Vector2:
	var player: Node = _controller.get("controlled_player")
	var ball: Node = _controller.get("ball")
	if (
		_controller.has_method("_is_true_one_vs_one")
		and bool(_controller.call("_is_true_one_vs_one"))
		and _controller.has_method(
			"_get_one_vs_one_bypass_target"
		)
	):
		var opponent_goal: Node = _controller.call(
			"_get_opponent_goal"
		)
		if opponent_goal != null:
			var bypass_target: Vector2 = _controller.call(
				"_get_one_vs_one_bypass_target",
				opponent_goal,
				null
			) as Vector2
			if not bypass_target.is_zero_approx():
				return bypass_target
	var base_position: Vector2 = ball.get("global_position")
	var attack_direction := base_position.direction_to(goal_center)
	if attack_direction.is_zero_approx():
		attack_direction = Vector2(float(_controller.call("_get_attack_sign")), 0.0)
	var best_target := base_position + attack_direction * 760.0
	var best_score := -INF
	for lateral in [-1.0, -0.55, 0.0, 0.55, 1.0]:
		var candidate := base_position + attack_direction * 760.0 + Vector2(0.0, lateral * 520.0)
		candidate = _controller.call("_clamp_to_field", candidate)
		var clearance := float(_controller.call("_nearest_opponent_distance", candidate))
		var progress := (candidate.x - base_position.x) * float(_controller.call("_get_attack_sign"))
		var travel := (player.get("global_position") as Vector2).distance_to(candidate)
		var score := progress * 0.55 + clearance * 0.7 - travel * 0.12
		if score > best_score:
			best_score = score
			best_target = candidate
	return best_target


func _best_open_space_target(fallback: Vector2) -> Vector2:
	var player: Node = _controller.get("controlled_player")
	var ball: Node = _controller.get("ball")
	var attack_sign := float(_controller.call("_get_attack_sign"))
	var base: Vector2 = player.get("global_position")
	var best_target := fallback
	var best_score := -INF
	for forward in [300.0, 650.0, 950.0]:
		for lateral in [-780.0, -390.0, 0.0, 390.0, 780.0]:
			var candidate := base + Vector2(attack_sign * forward, lateral)
			candidate = _controller.call("_clamp_to_field", candidate)
			var opponent_space := float(_controller.call("_nearest_opponent_distance", candidate))
			var teammate_space := _nearest_teammate_distance(candidate)
			var ball_relevance := candidate.distance_to(ball.get("global_position"))
			var score := opponent_space * 0.65 + teammate_space * 0.25 - ball_relevance * 0.08
			if score > best_score:
				best_score = score
				best_target = candidate
	return best_target


func _has_other_teammate() -> bool:
	if _controller == null:
		return false
	var controlled_player: Node = _controller.get("controlled_player")
	var teammates: Array = _controller.call("_get_teammates") as Array
	for teammate_variant in teammates:
		var teammate := teammate_variant as Node
		if (
			teammate != null
			and is_instance_valid(teammate)
			and teammate != controlled_player
			and bool(teammate.get("controls_enabled"))
		):
			return true
	return false


func _nearest_teammate_distance(position: Vector2) -> float:
	var nearest := 2200.0
	var teammates: Array = _controller.call("_get_teammates") as Array
	var controlled_player: Node = _controller.get("controlled_player")
	for teammate_variant in teammates:
		var teammate := teammate_variant as Node
		if not is_instance_valid(teammate) or teammate == controlled_player:
			continue
		nearest = minf(nearest, (teammate.get("global_position") as Vector2).distance_to(position))
	return nearest


func _set_fallback(reason: String) -> void:
	_fallback_active = true
	_fallback_reason = reason
	_fallback_count += 1
	if _controller != null:
		var manager: Node = _controller.get("match_manager")
		if manager != null and manager.has_method("record_hybrid_ai_fallback"):
			manager.call("record_hybrid_ai_fallback", int(_controller.get("controlled_player").get("owner_peer_id")), reason)


func _record_policy_decision(decision: Dictionary) -> void:
	if _controller == null:
		return
	var manager: Node = _controller.get("match_manager")
	if manager != null and manager.has_method("record_hybrid_ai_decision"):
		manager.call(
			"record_hybrid_ai_decision",
			int(_controller.get("controlled_player").get("owner_peer_id")),
			str(decision.get("action", Schema.ACTION_IDLE)),
			float(decision.get("score", 0.0)),
			str(decision.get("reason", ""))
		)


func _now() -> float:
	if _controller != null and _controller.has_method("_server_time_seconds"):
		return float(_controller.call("_server_time_seconds"))
	return Time.get_ticks_msec() / 1000.0
