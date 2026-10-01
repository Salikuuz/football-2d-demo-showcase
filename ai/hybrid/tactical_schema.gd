class_name HybridTacticalSchema
extends RefCounted


const OBSERVATION_VERSION: int = 2
const ACTION_SPACE_VERSION: int = 2
const CHECKPOINT_VERSION: int = 2
const MAX_TEAM_SIZE: int = 4

const ACTION_IDLE: StringName = &"idle"
const ACTION_DIRECT_SHOT: StringName = &"direct_shot"
const ACTION_NEAR_POST_SHOT: StringName = &"near_post_shot"
const ACTION_FAR_POST_SHOT: StringName = &"far_post_shot"
const ACTION_WALL_BANK_SHOT: StringName = &"wall_bank_shot"
const ACTION_PASS_AHEAD: StringName = &"pass_ahead"
const ACTION_SAFE_PASS: StringName = &"safe_pass"
const ACTION_CLEAR_OPEN_SIDE: StringName = &"clear_open_side"
const ACTION_CARRY: StringName = &"carry"
const ACTION_CHALLENGE_BALL: StringName = &"challenge_ball"
const ACTION_FAKE_CHALLENGE: StringName = &"fake_challenge"
const ACTION_DELAY_TOUCH: StringName = &"delay_touch"
const ACTION_SHADOW_DEFEND: StringName = &"shadow_defend"
const ACTION_PROTECT_GOAL: StringName = &"protect_goal"
const ACTION_MARK_OPPONENT: StringName = &"mark_opponent"
const ACTION_ROTATE_BACK: StringName = &"rotate_back"
const ACTION_MOVE_OPEN: StringName = &"move_open"
const ACTION_SUPPORT_TEAMMATE: StringName = &"support_teammate"
const ACTION_AVOID_DOUBLE_COMMIT: StringName = &"avoid_double_commit"
const ACTION_WAIT: StringName = &"wait"

const ALL_ACTIONS: Array[StringName] = [
	ACTION_DIRECT_SHOT,
	ACTION_NEAR_POST_SHOT,
	ACTION_FAR_POST_SHOT,
	ACTION_WALL_BANK_SHOT,
	ACTION_PASS_AHEAD,
	ACTION_SAFE_PASS,
	ACTION_CLEAR_OPEN_SIDE,
	ACTION_CARRY,
	ACTION_CHALLENGE_BALL,
	ACTION_FAKE_CHALLENGE,
	ACTION_DELAY_TOUCH,
	ACTION_SHADOW_DEFEND,
	ACTION_PROTECT_GOAL,
	ACTION_MARK_OPPONENT,
	ACTION_ROTATE_BACK,
	ACTION_MOVE_OPEN,
	ACTION_SUPPORT_TEAMMATE,
	ACTION_AVOID_DOUBLE_COMMIT,
	ACTION_WAIT
]

const POSSESSION_ACTIONS: Array[StringName] = [
	ACTION_DIRECT_SHOT,
	ACTION_NEAR_POST_SHOT,
	ACTION_FAR_POST_SHOT,
	ACTION_WALL_BANK_SHOT,
	ACTION_PASS_AHEAD,
	ACTION_SAFE_PASS,
	ACTION_CARRY,
	ACTION_DELAY_TOUCH
]

const DEFENSIVE_ACTIONS: Array[StringName] = [
	ACTION_CHALLENGE_BALL,
	ACTION_FAKE_CHALLENGE,
	ACTION_SHADOW_DEFEND,
	ACTION_PROTECT_GOAL,
	ACTION_MARK_OPPONENT,
	ACTION_ROTATE_BACK
]

const OFF_BALL_ACTIONS: Array[StringName] = [
	ACTION_MOVE_OPEN,
	ACTION_SUPPORT_TEAMMATE,
	ACTION_AVOID_DOUBLE_COMMIT,
	ACTION_ROTATE_BACK,
	ACTION_MARK_OPPONENT,
	ACTION_WAIT
]


static func is_known_action(action: StringName) -> bool:
	return action in ALL_ACTIONS or action == ACTION_IDLE


static func empty_decision(reason: String = "") -> Dictionary:
	return {
		"action": ACTION_IDLE,
		"target_position": Vector2.ZERO,
		"target_peer_id": 0,
		"urgency": 0.0,
		"commit_seconds": 0.0,
		"ability_id": 0,
		"score": -INF,
		"possible": false,
		"reason": reason
	}
