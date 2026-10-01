class_name TheodoreRLV2SharedTeamPolicy
extends RefCounted

const Schema := preload("res://ai_v2/rl_schema.gd")

const OWN_MEMORY_WEIGHT: float = 0.78
const TEAM_MEMORY_WEIGHT: float = 0.22

var policy = null
var _agent_memories: Dictionary = {}
var _team_memories: Dictionary = {}
var _last_intents: Dictionary = {}


func _init(requested_policy) -> void:
	policy = requested_policy


func reset_all() -> void:
	_agent_memories.clear()
	_team_memories.clear()
	_last_intents.clear()


func reset_team(team: StringName) -> void:
	var prefix: String = "%s:" % String(team)
	for key_variant in _agent_memories.keys():
		var key: String = str(key_variant)
		if key.begins_with(prefix):
			_agent_memories.erase(key_variant)
	for key_variant in _last_intents.keys():
		var key: String = str(key_variant)
		if key.begins_with(prefix):
			_last_intents.erase(key_variant)
	_team_memories.erase(String(team))


func sample_team(
	observations: Array[PackedFloat32Array],
	team: StringName,
	deterministic: bool = false,
	slot_offset: int = 0
) -> Array[Dictionary]:
	var slots := PackedInt32Array()
	for local_index in range(observations.size()):
		slots.append(slot_offset + local_index)
	return sample_slots(observations, slots, team, deterministic)


func sample_slots(
	observations: Array[PackedFloat32Array],
	slots: PackedInt32Array,
	team: StringName,
	deterministic: bool = false
) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	if policy == null or observations.size() != slots.size():
		return results
	var shared_before: PackedFloat32Array = _team_memory(team)
	var next_memories: Array[PackedFloat32Array] = []
	for local_index in range(observations.size()):
		var slot: int = slots[local_index]
		var key: String = _agent_key(team, slot)
		var own_memory: PackedFloat32Array = _agent_memories.get(key, policy.initial_memory())
		var policy_memory: PackedFloat32Array = _blend_memories(own_memory, shared_before)
		var sample: Dictionary = policy.sample_recurrent(observations[local_index], policy_memory, team, deterministic)
		sample["team"] = String(team)
		sample["team_slot"] = slot
		sample["memory"] = policy_memory
		results.append(sample)
		next_memories.append(sample.get("next_memory", PackedFloat32Array()))
	for local_index in range(next_memories.size()):
		var slot: int = slots[local_index]
		_agent_memories[_agent_key(team, slot)] = next_memories[local_index]
		_last_intents[_agent_key(team, slot)] = _intent_from_sample(results[local_index])
	_team_memories[String(team)] = _mean_memory(next_memories)
	return results


func memory_for(team: StringName, slot: int) -> PackedFloat32Array:
	return (_agent_memories.get(_agent_key(team, slot), policy.initial_memory()) as PackedFloat32Array).duplicate()


func blended_memory_for(team: StringName, slot: int) -> PackedFloat32Array:
	var own_memory: PackedFloat32Array = _agent_memories.get(_agent_key(team, slot), policy.initial_memory())
	return _blend_memories(own_memory, _team_memory(team))


func team_memory(team: StringName) -> PackedFloat32Array:
	return _team_memory(team).duplicate()


func last_intent(team: StringName, slot: int) -> Dictionary:
	return (_last_intents.get(_agent_key(team, slot), {}) as Dictionary).duplicate(true)


func _agent_key(team: StringName, slot: int) -> String:
	return "%s:%d" % [String(team), slot]


func _team_memory(team: StringName) -> PackedFloat32Array:
	return _team_memories.get(String(team), policy.initial_memory()) as PackedFloat32Array


func _blend_memories(own_memory: PackedFloat32Array, team_memory_value: PackedFloat32Array) -> PackedFloat32Array:
	if own_memory.is_empty():
		return PackedFloat32Array()
	var result := PackedFloat32Array()
	result.resize(own_memory.size())
	for index in range(own_memory.size()):
		var team_value: float = team_memory_value[index] if index < team_memory_value.size() else 0.0
		result[index] = own_memory[index] * OWN_MEMORY_WEIGHT + team_value * TEAM_MEMORY_WEIGHT
	return result


func _mean_memory(memories: Array[PackedFloat32Array]) -> PackedFloat32Array:
	if memories.is_empty() or memories[0].is_empty():
		return PackedFloat32Array()
	var result := PackedFloat32Array()
	result.resize(memories[0].size())
	for memory in memories:
		for index in range(mini(result.size(), memory.size())):
			result[index] += memory[index]
	for index in range(result.size()):
		result[index] /= float(memories.size())
	return result


func _intent_from_sample(sample: Dictionary) -> Dictionary:
	var action: Dictionary = sample.get("action", {}) as Dictionary
	return {
		"move": action.get("move", Vector2.ZERO),
		"aim": action.get("aim", Vector2.ZERO),
		"kick_mode": int(action.get("kick_mode", Schema.KICK_NONE)),
		"kick_strength": float(action.get("kick_strength", 0.0)),
		"ability_trigger": bool(action.get("ability_trigger", false)),
		"receive_mode": int(action.get("receive_mode", Schema.RECEIVE_NONE)),
		"receiver_slot": int(action.get("receiver_slot", 0))
	}
