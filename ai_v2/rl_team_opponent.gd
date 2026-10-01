class_name TheodoreRLV2TeamOpponent
extends RefCounted

const NeuralPolicy := preload("res://ai_v2/rl_neural_policy.gd")
const LeagueOpponent := preload("res://ai_v2/rl_league_opponent.gd")
const SharedTeamPolicy := preload("res://ai_v2/rl_shared_team_policy.gd")
const Schema := preload("res://ai_v2/rl_schema.gd")

var entry: Dictionary = {}
var _single_agent = null
var _neural = null
var _shared = null


func _init(requested_entry: Dictionary = {}, requested_seed: int = 1) -> void:
	entry = requested_entry.duplicate(true)
	var checkpoint_path: String = str(entry.get("checkpoint_path", ""))
	if str(entry.get("kind", "legacy")) == "neural" and not checkpoint_path.is_empty():
		var loaded_policy := NeuralPolicy.new()
		if loaded_policy.load_checkpoint(checkpoint_path):
			if not loaded_policy.recurrence_enabled():
				loaded_policy.enable_recurrence(requested_seed + 31)
			_neural = loaded_policy
			_shared = SharedTeamPolicy.new(_neural)
	if _shared == null:
		_single_agent = LeagueOpponent.new(entry, requested_seed)


func actions_for(environment, team: StringName) -> Array[Dictionary]:
	var team_players: Array = environment.blue_players if team == &"blue" else environment.red_players
	if _shared != null:
		var all_observations: Array[PackedFloat32Array] = environment.observe_all()
		var offset: int = 0 if team == &"blue" else environment.blue_players.size()
		var observations: Array[PackedFloat32Array] = []
		for local_index in range(team_players.size()):
			observations.append(all_observations[offset + local_index])
		var samples: Array[Dictionary] = _shared.sample_team(observations, team, true)
		var actions: Array[Dictionary] = []
		for sample in samples:
			actions.append(sample.get("action", {}) as Dictionary)
		return actions
	var result: Array[Dictionary] = []
	for player_index in range(team_players.size()):
		var player = team_players[player_index]
		var action: Dictionary = _single_agent.action_for(environment, player)
		if str(entry.get("profile", "balanced")) == "passing" and team_players.size() > 1:
			var teammate_index: int = (player_index + 1) % team_players.size()
			var teammate = team_players[teammate_index]
			if player.global_position.distance_to(environment.ball.global_position) <= environment.BALL_CONTROL_DISTANCE:
				action["aim"] = environment.ball.global_position.direction_to(teammate.global_position)
				action["kick_mode"] = Schema.KICK_PASS
				action["kick_strength"] = 0.52
				action["receiver_slot"] = environment.receiver_action_slot(player, teammate)
		result.append(action)
	return result


func reset() -> void:
	if _shared != null:
		_shared.reset_all()


func identity() -> Dictionary:
	var result: Dictionary = entry.duplicate(true)
	result["shared_recurrent"] = _shared != null
	return result
