class_name TheodoreRLV2Schema
extends RefCounted

const PROTOCOL_NAME: String = "theodore_rl_v2"
const OBSERVATION_VERSION: int = 1
const ACTION_VERSION: int = 1
const MAX_TEAM_SIZE: int = 4
const MAX_TEAMMATES: int = 3
const MAX_OPPONENTS: int = 4
const ABILITY_COUNT_WITH_NONE: int = 24
const MAX_MATCH_SECONDS: float = 600.0
const VELOCITY_SCALE: float = 9000.0
const MAX_SPEED_SCALE: float = 8500.0
const ACCELERATION_SCALE: float = 12000.0
const ARRIVAL_TIME_SCALE: float = 3.0
const ABILITY_TIME_SCALE: float = 12.0

const KICK_NONE: int = 0
const KICK_SHOT: int = 1
const KICK_PASS: int = 2

const RECEIVE_NONE: int = 0
const RECEIVE_TRAP: int = 1
const RECEIVE_VOLLEY: int = 2
const RECEIVE_DUMMY: int = 3

const GLOBAL_FEATURE_NAMES: Array[String] = [
	"team_size_norm",
	"own_score_norm",
	"opponent_score_norm",
	"score_difference_norm",
	"time_remaining_norm",
	"is_overtime",
	"kickoff_waiting",
	"round_resetting",
	"game_started",
	"freeplay_active",
	"field_variant_norm",
	"human_teammate_count_norm",
	"human_opponent_count_norm",
	"ball_pos_x",
	"ball_pos_y",
	"ball_vel_x",
	"ball_vel_y",
	"ball_speed_norm",
	"ball_future_025_x",
	"ball_future_025_y",
	"ball_future_050_x",
	"ball_future_050_y",
	"ball_future_100_x",
	"ball_future_100_y",
	"possession_self",
	"possession_team",
	"possession_opponent",
	"possession_loose"
]

const ENTITY_BASE_FEATURE_NAMES: Array[String] = [
	"present",
	"is_self",
	"is_teammate",
	"is_opponent",
	"is_human",
	"is_cpu",
	"controls_enabled",
	"team_slot_norm",
	"pos_x",
	"pos_y",
	"vel_x",
	"vel_y",
	"move_intent_x",
	"move_intent_y",
	"distance_to_ball_norm",
	"ball_arrival_time_norm",
	"distance_to_own_goal_norm",
	"distance_to_opponent_goal_norm",
	"forward_progress",
	"max_speed_norm",
	"acceleration_norm",
	"effective_speed_multiplier_norm",
	"effective_acceleration_multiplier_norm",
	"is_charging",
	"charge_fraction",
	"next_kick_is_pass",
	"pass_request_active",
	"has_ball_control",
	"ability_ready",
	"ability_active",
	"ability_cooldown_fraction",
	"ability_active_remaining_norm",
	"ability_strength_scale",
	"permanent_overdrive",
	"permanent_power_strike",
	"ability_role_attack",
	"ability_role_playmaker",
	"ability_role_flexible",
	"ability_role_defense",
	"first_touch_none",
	"first_touch_trap",
	"first_touch_volley",
	"first_touch_dummy"
]

const CONTINUOUS_ACTION_NAMES: Array[String] = [
	"move_x",
	"move_y",
	"aim_x",
	"aim_y",
	"kick_strength"
]

const DISCRETE_ACTION_NAMES: Array[String] = [
	"kick_mode",
	"ability_trigger",
	"pass_request",
	"receive_mode",
	"receiver_slot"
]

const DISCRETE_ACTION_SIZES: Array[int] = [3, 2, 2, 4, 4]


static func entity_feature_names() -> Array[String]:
	var result: Array[String] = ENTITY_BASE_FEATURE_NAMES.duplicate()
	for ability_id in range(ABILITY_COUNT_WITH_NONE):
		result.append("selected_ability_%02d" % ability_id)
	for ability_id in range(ABILITY_COUNT_WITH_NONE):
		result.append("active_ability_%02d" % ability_id)
	return result


static func observation_feature_names() -> Array[String]:
	var result: Array[String] = GLOBAL_FEATURE_NAMES.duplicate()
	var entity_names: Array[String] = entity_feature_names()
	for feature_name in entity_names:
		result.append("self.%s" % feature_name)
	for teammate_index in range(MAX_TEAMMATES):
		for feature_name in entity_names:
			result.append("teammate_%d.%s" % [teammate_index, feature_name])
	for opponent_index in range(MAX_OPPONENTS):
		for feature_name in entity_names:
			result.append("opponent_%d.%s" % [opponent_index, feature_name])
	return result


static func observation_size() -> int:
	return observation_feature_names().size()


static func entity_feature_size() -> int:
	return entity_feature_names().size()


static func schema_signature() -> String:
	var parts: Array[String] = [
		PROTOCOL_NAME,
		"obs:%d" % OBSERVATION_VERSION,
		"act:%d" % ACTION_VERSION,
		"obs_features:%s" % "|".join(observation_feature_names()),
		"continuous:%s" % "|".join(CONTINUOUS_ACTION_NAMES),
		"discrete:%s" % "|".join(DISCRETE_ACTION_NAMES),
		"discrete_sizes:%s" % str(DISCRETE_ACTION_SIZES)
	]
	return "\n".join(parts)


static func schema_fingerprint() -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(schema_signature().to_utf8_buffer())
	return context.finish().hex_encode()


static func contract() -> Dictionary:
	return {
		"protocol": PROTOCOL_NAME,
		"observation_version": OBSERVATION_VERSION,
		"action_version": ACTION_VERSION,
		"schema_fingerprint": schema_fingerprint(),
		"observation_size": observation_size(),
		"observation_features": observation_feature_names(),
		"entity_feature_size": entity_feature_size(),
		"max_team_size": MAX_TEAM_SIZE,
		"max_teammates": MAX_TEAMMATES,
		"max_opponents": MAX_OPPONENTS,
		"canonical_frame": "own_goal_left_attack_positive_x",
		"entity_slot_order": "team_slot_then_peer_id",
		"human_teammates_supported": true,
		"continuous_actions": CONTINUOUS_ACTION_NAMES,
		"continuous_action_low": [-1.0, -1.0, -1.0, -1.0, 0.0],
		"continuous_action_high": [1.0, 1.0, 1.0, 1.0, 1.0],
		"discrete_actions": DISCRETE_ACTION_NAMES,
		"discrete_action_sizes": DISCRETE_ACTION_SIZES,
		"kick_modes": {
			"none": KICK_NONE,
			"shot": KICK_SHOT,
			"pass": KICK_PASS
		},
		"receive_modes": {
			"none": RECEIVE_NONE,
			"trap": RECEIVE_TRAP,
			"volley": RECEIVE_VOLLEY,
			"dummy": RECEIVE_DUMMY
		},
		"receiver_slot_semantics": "0=none,1=teammate_0,2=teammate_1,3=teammate_2",
		"difficulty_scaling": "reserved_for_later_runtime_policy_profiles"
	}
