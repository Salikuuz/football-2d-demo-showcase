class_name TheodoreRLV2LegalActionMask
extends RefCounted

const Schema := preload("res://ai_v2/rl_schema.gd")

const DISCRETE_TOTAL: int = 15

static var _self_control_index: int = -1
static var _self_ability_ready_index: int = -1
static var _teammate_present_indices: PackedInt32Array = PackedInt32Array()


static func from_observation(observation: PackedFloat32Array) -> PackedFloat32Array:
	_ensure_indices()
	var result := PackedFloat32Array()
	result.resize(DISCRETE_TOTAL)
	result.fill(1.0)
	var has_control: bool = _feature_enabled(observation, _self_control_index)
	var ability_ready: bool = _feature_enabled(observation, _self_ability_ready_index)
	var has_teammate: bool = false
	for index in _teammate_present_indices:
		has_teammate = has_teammate or _feature_enabled(observation, index)

	# kick_mode: none is always legal; shots require contact and passes additionally
	# require a real receiver. This prevents the policy from receiving credit for
	# thousands of kick requests that the authoritative environment rejects.
	result[0] = 1.0
	result[1] = 1.0 if has_control else 0.0
	result[2] = 1.0 if has_control and has_teammate else 0.0
	# ability_trigger: never request an unavailable or cooling-down ability.
	result[3] = 1.0
	result[4] = 1.0 if ability_ready else 0.0
	# pass_request and reception modes remain legal away from the ball because
	# they are intentional pre-reception actions.
	# receiver_slot: a policy may only name teammate slots that exist.
	result[11] = 1.0
	for teammate_slot in range(Schema.MAX_TEAMMATES):
		result[12 + teammate_slot] = 1.0 if _feature_enabled(observation, _teammate_present_indices[teammate_slot]) else 0.0
	return result


static func all_allowed() -> PackedFloat32Array:
	var result := PackedFloat32Array()
	result.resize(DISCRETE_TOTAL)
	result.fill(1.0)
	return result


static func _ensure_indices() -> void:
	if _self_control_index >= 0:
		return
	var names: Array[String] = Schema.observation_feature_names()
	_self_control_index = names.find("self.has_ball_control")
	_self_ability_ready_index = names.find("self.ability_ready")
	_teammate_present_indices.resize(Schema.MAX_TEAMMATES)
	for teammate_slot in range(Schema.MAX_TEAMMATES):
		_teammate_present_indices[teammate_slot] = names.find("teammate_%d.present" % teammate_slot)


static func _feature_enabled(observation: PackedFloat32Array, index: int) -> bool:
	return index >= 0 and index < observation.size() and observation[index] > 0.5
