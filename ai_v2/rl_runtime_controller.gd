class_name TheodoreRLV2RuntimeController
extends RefCounted

## Experimental Part 9 bridge between the isolated V2 policy and live CPU AI.
## It is deliberately disabled by default. The live CPU remains authoritative and
## may reject every proposal before any gameplay input is changed.

const Interface := preload("res://ai_v2/rl_interface.gd")
const NeuralPolicy := preload("res://ai_v2/rl_neural_policy.gd")

const DEFAULT_ONE_VS_ONE_CHECKPOINT: String = (
	"res://training/ai_v2/checkpoints/1v1_candidate.json"
)
const DEFAULT_MULTITEAM_CHECKPOINT: String = (
	"res://training/ai_v2/checkpoints/multiteam_candidate.json"
)

static var _policy_cache: Dictionary = {}
static var _failed_checkpoint_cache: Dictionary = {}

var enabled: bool = false
var deterministic: bool = true
var one_vs_one_checkpoint_path: String = DEFAULT_ONE_VS_ONE_CHECKPOINT
var multiteam_checkpoint_path: String = DEFAULT_MULTITEAM_CHECKPOINT

var _agent_memories: Dictionary = {}
var _test_policy: Variant = null
var _last_status: Dictionary = {
	"accepted": false,
	"reason": "not_requested"
}


func _init() -> void:
	reload_project_settings()


func reload_project_settings() -> void:
	enabled = bool(ProjectSettings.get_setting(
		"ai_v2/runtime/enabled",
		false
	))
	deterministic = bool(ProjectSettings.get_setting(
		"ai_v2/runtime/deterministic",
		true
	))
	one_vs_one_checkpoint_path = str(ProjectSettings.get_setting(
		"ai_v2/runtime/one_vs_one_checkpoint",
		DEFAULT_ONE_VS_ONE_CHECKPOINT
	))
	multiteam_checkpoint_path = str(ProjectSettings.get_setting(
		"ai_v2/runtime/multiteam_checkpoint",
		DEFAULT_MULTITEAM_CHECKPOINT
	))


func configure(
	runtime_enabled: bool,
	one_vs_one_path: String = DEFAULT_ONE_VS_ONE_CHECKPOINT,
	multiteam_path: String = DEFAULT_MULTITEAM_CHECKPOINT,
	deterministic_actions: bool = true
) -> void:
	enabled = runtime_enabled
	one_vs_one_checkpoint_path = one_vs_one_path
	multiteam_checkpoint_path = multiteam_path
	deterministic = deterministic_actions
	reset_all_agents()


func set_test_policy(policy: Variant) -> void:
	_test_policy = policy
	reset_all_agents()


func request_intent(
	manager: Node,
	player: Node,
	field_rect: Rect2,
	server_now: float,
	team_size: int
) -> Dictionary:
	if not enabled:
		return _reject("disabled")
	if manager == null or player == null:
		return _reject("missing_manager_or_player")
	if not is_instance_valid(manager) or not is_instance_valid(player):
		return _reject("invalid_manager_or_player")
	if not bool(player.get("cpu_controlled")):
		return _reject("not_cpu_controlled")
	if not bool(player.get("controls_enabled")):
		return _reject("controls_disabled")
	var team: StringName = StringName(player.get("team"))
	if team not in [&"blue", &"red"]:
		return _reject("invalid_team")

	var observation_packet: Dictionary = Interface.observe(
		manager,
		player,
		field_rect,
		server_now
	)
	if not bool(observation_packet.get("valid", false)):
		return _reject(
			"observation_%s" % str(observation_packet.get("error", "invalid"))
		)
	var policy: Variant = _test_policy
	var checkpoint_path: String = "test_policy"
	if policy == null:
		checkpoint_path = _checkpoint_for_team_size(team_size)
		policy = _get_or_load_policy(checkpoint_path)
	if policy == null:
		return _reject("checkpoint_unavailable", checkpoint_path)
	if not policy.has_method("initial_memory") or not policy.has_method("sample_recurrent"):
		return _reject("invalid_policy_interface", checkpoint_path)

	var agent_key: String = _agent_key(player)
	var previous_memory: PackedFloat32Array = _agent_memories.get(
		agent_key,
		policy.call("initial_memory") as PackedFloat32Array
	)
	var sample: Dictionary = policy.call(
		"sample_recurrent",
		observation_packet.get("flat", PackedFloat32Array()),
		previous_memory,
		team,
		deterministic
	) as Dictionary
	var raw_action: Dictionary = sample.get("action", {}) as Dictionary
	if not _action_is_finite(raw_action):
		return _reject("invalid_policy_action", checkpoint_path)
	var action: Dictionary = Interface.sanitize_action(raw_action)
	if not _action_is_finite(action):
		return _reject("invalid_sanitized_action", checkpoint_path)
	var next_memory: PackedFloat32Array = sample.get(
		"next_memory",
		previous_memory
	) as PackedFloat32Array
	if not _memory_is_finite(next_memory):
		return _reject("invalid_policy_memory", checkpoint_path)
	_agent_memories[agent_key] = next_memory
	_last_status = {
		"accepted": true,
		"reason": "accepted",
		"checkpoint_path": checkpoint_path,
		"agent_key": agent_key,
		"team_size": team_size
	}
	return {
		"accepted": true,
		"reason": "accepted",
		"checkpoint_path": checkpoint_path,
		"agent_key": agent_key,
		"action": action
	}


func reset_agent(player: Node) -> void:
	if player == null or not is_instance_valid(player):
		return
	_agent_memories.erase(_agent_key(player))


func reset_all_agents() -> void:
	_agent_memories.clear()


func get_last_status() -> Dictionary:
	return _last_status.duplicate(true)


func get_agent_memory_for_tests(player: Node) -> PackedFloat32Array:
	if player == null or not is_instance_valid(player):
		return PackedFloat32Array()
	return _agent_memories.get(_agent_key(player), PackedFloat32Array())


static func clear_checkpoint_cache_for_tests() -> void:
	_policy_cache.clear()
	_failed_checkpoint_cache.clear()


func _checkpoint_for_team_size(team_size: int) -> String:
	return (
		one_vs_one_checkpoint_path
		if team_size <= 1
		else multiteam_checkpoint_path
	)


func _get_or_load_policy(checkpoint_path: String) -> Variant:
	if checkpoint_path.is_empty():
		return null
	if _policy_cache.has(checkpoint_path):
		return _policy_cache[checkpoint_path]
	if _failed_checkpoint_cache.has(checkpoint_path):
		return null
	var policy := NeuralPolicy.new()
	if not policy.load_checkpoint(checkpoint_path):
		_failed_checkpoint_cache[checkpoint_path] = true
		if OS.is_debug_build():
			push_warning("AI V2 runtime rejected checkpoint: %s" % checkpoint_path)
		return null
	_policy_cache[checkpoint_path] = policy
	return policy


func _agent_key(player: Node) -> String:
	return "%s:%d:%d" % [
		str(player.get("team")),
		int(player.get("team_slot")),
		int(player.get("owner_peer_id"))
	]


func _reject(reason: String, checkpoint_path: String = "") -> Dictionary:
	_last_status = {
		"accepted": false,
		"reason": reason,
		"checkpoint_path": checkpoint_path
	}
	return _last_status.duplicate(true)


func _action_is_finite(action: Dictionary) -> bool:
	if action.is_empty():
		return false
	var move: Variant = action.get("move", Vector2.ZERO)
	var aim: Variant = action.get("aim", Vector2.ZERO)
	if not move is Vector2 or not aim is Vector2:
		return false
	var move_vector: Vector2 = move as Vector2
	var aim_vector: Vector2 = aim as Vector2
	return (
		is_finite(move_vector.x)
		and is_finite(move_vector.y)
		and is_finite(aim_vector.x)
		and is_finite(aim_vector.y)
		and is_finite(float(action.get("kick_strength", 0.0)))
	)


func _memory_is_finite(memory: PackedFloat32Array) -> bool:
	for value: float in memory:
		if not is_finite(value):
			return false
	return true
