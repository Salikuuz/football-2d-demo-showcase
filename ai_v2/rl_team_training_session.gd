class_name TheodoreRLV2TeamTrainingSession
extends RefCounted

const HeadlessEnvironment := preload("res://ai_v2/rl_headless_environment.gd")
const SharedTeamPolicy := preload("res://ai_v2/rl_shared_team_policy.gd")
const TeamOpponent := preload("res://ai_v2/rl_team_opponent.gd")
const TeamReward := preload("res://ai_v2/rl_team_reward_model.gd")
const ScriptedHumanTeammate := preload("res://ai_v2/rl_scripted_human_teammate.gd")

const GAMMA: float = 0.995
const GAE_LAMBDA: float = 0.95
const DEFAULT_TEAM_SIZE: int = 2

var policy = null
var shared_policy = null
var opponent = null
var episode_seconds: float = 20.0
var goals_to_win: int = 3
var seed_value: int = 104729
var team_size: int = DEFAULT_TEAM_SIZE
var human_teammate_slots := PackedInt32Array()
var scripted_human = null


func _init(
	neural_policy,
	requested_seed: int = 104729,
	requested_episode_seconds: float = 20.0,
	requested_goals_to_win: int = 3,
	requested_opponent = null,
	requested_team_size: int = DEFAULT_TEAM_SIZE,
	requested_human_teammate_slots: PackedInt32Array = PackedInt32Array()
) -> void:
	policy = neural_policy
	shared_policy = SharedTeamPolicy.new(policy)
	opponent = requested_opponent if requested_opponent != null else TeamOpponent.new({}, requested_seed + 17)
	seed_value = requested_seed
	episode_seconds = maxf(1.0, requested_episode_seconds)
	goals_to_win = maxi(1, requested_goals_to_win)
	team_size = clampi(requested_team_size, 1, 4)
	for slot in requested_human_teammate_slots:
		if slot >= 0 and slot < team_size and not human_teammate_slots.has(slot):
			human_teammate_slots.append(slot)
	scripted_human = ScriptedHumanTeammate.new()


func train_updates(update_count: int, rollout_steps: int, epochs: int = 3, learning_rate: float = 0.00035) -> Dictionary:
	var summaries: Array[Dictionary] = []
	var total_full_games: int = 0
	var total_reward: float = 0.0
	for update_index in range(maxi(1, update_count)):
		var learner_team: StringName = &"blue" if update_index % 2 == 0 else &"red"
		var minimum_steps: int = ceili(episode_seconds / HeadlessEnvironment.FIXED_STEP_SECONDS) + 1
		var effective_steps: int = maxi(maxi(16, rollout_steps), minimum_steps)
		var rollout: Dictionary = collect_rollout(effective_steps, learner_team, seed_value + update_index * 1009)
		var batch: Array[Dictionary] = rollout.get("batch", []) as Array[Dictionary]
		var update_result: Dictionary = policy.ppo_update(batch, epochs, learning_rate)
		total_full_games += int(rollout.get("full_games", 0))
		total_reward += float(rollout.get("team_reward", 0.0))
		summaries.append({
			"update": update_index + 1,
			"learner_team": String(learner_team),
			"samples": batch.size(),
			"full_games": int(rollout.get("full_games", 0)),
			"team_reward": float(rollout.get("team_reward", 0.0)),
			"policy_loss": float(update_result.get("policy_loss", 0.0)),
			"value_loss": float(update_result.get("value_loss", 0.0))
		})
	return {
		"updates": summaries,
		"full_games": total_full_games,
		"team_reward": total_reward,
		"training_steps": policy.training_steps
	}


func collect_rollout(step_count: int, learner_team: StringName, requested_seed: int) -> Dictionary:
	var environment := HeadlessEnvironment.new(team_size, requested_seed, episode_seconds, goals_to_win)
	environment.configure_human_slots(learner_team, human_teammate_slots)
	shared_policy.reset_all()
	scripted_human.reset()
	if opponent.has_method("reset"):
		opponent.reset()
	var neural_slots: PackedInt32Array = _neural_slots()
	var slot_batches: Dictionary = {}
	for slot in neural_slots:
		slot_batches[slot] = []
	var full_games: int = 0
	var total_team_reward: float = 0.0
	var memory_resets: int = 0
	for _step_index in range(maxi(1, step_count)):
		var observations: Array[PackedFloat32Array] = environment.observe_all()
		var learner_observations: Array[PackedFloat32Array] = _team_observations(observations, learner_team)
		var neural_observations: Array[PackedFloat32Array] = _observations_for_slots(learner_observations, neural_slots)
		var learner_samples: Array[Dictionary] = shared_policy.sample_slots(neural_observations, neural_slots, learner_team, false)
		var learner_actions: Array[Dictionary] = _mixed_learner_actions(environment, learner_team, neural_slots, learner_samples)
		var opponent_team: StringName = &"red" if learner_team == &"blue" else &"blue"
		var opponent_actions: Array[Dictionary] = opponent.actions_for(environment, opponent_team)
		var before: Dictionary = TeamReward.capture(environment, learner_team)
		var step_result: Dictionary = environment.step(_ordered_actions(learner_team, learner_actions, opponent_actions))
		var reward_components: Dictionary = TeamReward.transition_reward_components(environment, learner_team, before, step_result)
		var terminated: bool = bool(step_result.get("terminated", false))
		var goal_scored: bool = not StringName(step_result.get("goal_team", &"")).is_empty()
		var reset_boundary: bool = terminated or goal_scored
		for sample_index in range(neural_slots.size()):
			var slot: int = neural_slots[sample_index]
			var sample: Dictionary = learner_samples[sample_index]
			var batch_for_slot: Array = slot_batches[slot] as Array
			var slot_reward: float = TeamReward.reward_for_slot(reward_components, slot)
			batch_for_slot.append({
				"observation": learner_observations[slot],
				"memory": sample.get("memory", PackedFloat32Array()),
				"raw_continuous": sample.get("raw_continuous", PackedFloat32Array()),
				"discrete": sample.get("discrete", PackedInt32Array()),
				"discrete_mask": sample.get("discrete_mask", PackedFloat32Array()),
				"old_log_probability": float(sample.get("log_probability", 0.0)),
				"value": float(sample.get("value", 0.0)),
				"reward": slot_reward,
				"done": terminated,
				"bootstrap_boundary": reset_boundary
			})
		total_team_reward += float(reward_components.get("shared", 0.0)) + float(reward_components.get("aggregate_execution", 0.0))
		if goal_scored:
			shared_policy.reset_all()
			scripted_human.reset()
			if opponent.has_method("reset"):
				opponent.reset()
			memory_resets += 1
		if terminated:
			full_games += 1
			environment.finish_and_reset_if_needed(step_result)
			shared_policy.reset_all()
			scripted_human.reset()
			if opponent.has_method("reset"):
				opponent.reset()
			if not goal_scored:
				memory_resets += 1
	var final_observations: Array[PackedFloat32Array] = _team_observations(environment.observe_all(), learner_team)
	for slot in neural_slots:
		var untyped_batch: Array = slot_batches[slot] as Array
		var batch: Array[Dictionary] = []
		batch.assign(untyped_batch)
		var bootstrap: float = 0.0
		if not batch.is_empty() and not bool(batch.back().get("bootstrap_boundary", batch.back().get("done", false))):
			var memory: PackedFloat32Array = shared_policy.blended_memory_for(learner_team, slot)
			bootstrap = float(policy.sample_recurrent(final_observations[slot], memory, learner_team, true).get("value", 0.0))
		_compute_advantages(batch, bootstrap)
		slot_batches[slot] = batch
	var combined: Array[Dictionary] = []
	for slot in neural_slots:
		var trained_batch: Array[Dictionary] = []
		trained_batch.assign(slot_batches[slot] as Array)
		combined.append_array(trained_batch)
	environment.dispose()
	return {
		"batch": combined,
		"full_games": full_games,
		"team_reward": total_team_reward,
		"memory_resets": memory_resets,
		"samples_per_agent": maxi(1, step_count),
		"team_size": team_size,
		"neural_agent_count": neural_slots.size(),
		"human_teammate_count": human_teammate_slots.size()
	}


func evaluate_against(requested_opponent, match_count: int, requested_seed: int = 400001) -> Dictionary:
	var requested_matches: int = maxi(1, match_count)
	var metrics: Dictionary = {
		"team_size": team_size,
		"human_teammate_count": human_teammate_slots.size(),
		"requested_matches": requested_matches,
		"completed_matches": 0,
		"candidate_wins": 0,
		"champion_wins": 0,
		"draws": 0,
		"candidate_goals": 0,
		"champion_goals": 0,
		"candidate_kicks": 0,
		"candidate_passes": 0,
		"candidate_receiver_targets": 0,
		"candidate_ability_uses": 0,
		"matches": []
	}
	for match_index in range(requested_matches):
		var candidate_team: StringName = &"blue" if match_index % 2 == 0 else &"red"
		var opponent_team: StringName = &"red" if candidate_team == &"blue" else &"blue"
		var environment := HeadlessEnvironment.new(team_size, requested_seed + match_index, episode_seconds, goals_to_win)
		environment.configure_human_slots(candidate_team, human_teammate_slots)
		shared_policy.reset_all()
		scripted_human.reset()
		if requested_opponent.has_method("reset"):
			requested_opponent.reset()
		var maximum_steps: int = ceili(episode_seconds / environment.fixed_step_seconds) + 2
		var result: Dictionary = {}
		for _step_index in range(maximum_steps):
			var observations: Array[PackedFloat32Array] = environment.observe_all()
			var candidate_observations: Array[PackedFloat32Array] = _team_observations(observations, candidate_team)
			var neural_slots: PackedInt32Array = _neural_slots()
			var candidate_samples: Array[Dictionary] = shared_policy.sample_slots(_observations_for_slots(candidate_observations, neural_slots), neural_slots, candidate_team, true)
			var candidate_actions: Array[Dictionary] = _mixed_learner_actions(environment, candidate_team, neural_slots, candidate_samples)
			for action in candidate_actions:
				if int(action.get("kick_mode", 0)) != 0:
					metrics["candidate_kicks"] = int(metrics["candidate_kicks"]) + 1
				if int(action.get("kick_mode", 0)) == 2:
					metrics["candidate_passes"] = int(metrics["candidate_passes"]) + 1
				if int(action.get("receiver_slot", 0)) > 0:
					metrics["candidate_receiver_targets"] = int(metrics["candidate_receiver_targets"]) + 1
				if bool(action.get("ability_trigger", false)):
					metrics["candidate_ability_uses"] = int(metrics["candidate_ability_uses"]) + 1
			var opponent_actions: Array[Dictionary] = requested_opponent.actions_for(environment, opponent_team)
			result = environment.step(_ordered_actions(candidate_team, candidate_actions, opponent_actions))
			if not StringName(result.get("goal_team", &"")).is_empty():
				shared_policy.reset_all()
				scripted_human.reset()
				if requested_opponent.has_method("reset"):
					requested_opponent.reset()
			if bool(result.get("terminated", false)):
				break
		if bool(result.get("terminated", false)):
			_record_match_metrics(metrics, result, candidate_team)
		environment.dispose()
	return metrics


func _team_observations(all_observations: Array[PackedFloat32Array], team: StringName) -> Array[PackedFloat32Array]:
	var result: Array[PackedFloat32Array] = []
	var offset: int = 0 if team == &"blue" else team_size
	for slot in range(team_size):
		result.append(all_observations[offset + slot])
	return result


func _neural_slots() -> PackedInt32Array:
	var result := PackedInt32Array()
	for slot in range(team_size):
		if not human_teammate_slots.has(slot):
			result.append(slot)
	return result


func _observations_for_slots(observations: Array[PackedFloat32Array], slots: PackedInt32Array) -> Array[PackedFloat32Array]:
	var result: Array[PackedFloat32Array] = []
	for slot in slots:
		result.append(observations[slot])
	return result


func _mixed_learner_actions(environment, learner_team: StringName, neural_slots: PackedInt32Array, samples: Array[Dictionary]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	result.resize(team_size)
	var team_players: Array = environment.blue_players if learner_team == &"blue" else environment.red_players
	for slot in range(team_size):
		if human_teammate_slots.has(slot):
			result[slot] = scripted_human.action_for(environment, team_players[slot], learner_team)
		else:
			var sample_index: int = neural_slots.find(slot)
			result[slot] = (samples[sample_index].get("action", {}) as Dictionary) if sample_index >= 0 else {}
	return result


func _actions_from_samples(samples: Array[Dictionary]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for sample in samples:
		result.append(sample.get("action", {}) as Dictionary)
	return result


func _ordered_actions(learner_team: StringName, learner_actions: Array[Dictionary], opponent_actions: Array[Dictionary]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if learner_team == &"blue":
		result.append_array(learner_actions)
		result.append_array(opponent_actions)
	else:
		result.append_array(opponent_actions)
		result.append_array(learner_actions)
	return result


func _record_match_metrics(metrics: Dictionary, result: Dictionary, candidate_team: StringName) -> void:
	metrics["completed_matches"] = int(metrics["completed_matches"]) + 1
	var candidate_score: int = int(result.get("blue_score", 0)) if candidate_team == &"blue" else int(result.get("red_score", 0))
	var opponent_score: int = int(result.get("red_score", 0)) if candidate_team == &"blue" else int(result.get("blue_score", 0))
	metrics["candidate_goals"] = int(metrics["candidate_goals"]) + candidate_score
	metrics["champion_goals"] = int(metrics["champion_goals"]) + opponent_score
	(metrics["matches"] as Array).append({"candidate_team": String(candidate_team), "candidate_score": candidate_score, "opponent_score": opponent_score})
	if candidate_score > opponent_score:
		metrics["candidate_wins"] = int(metrics["candidate_wins"]) + 1
	elif candidate_score < opponent_score:
		metrics["champion_wins"] = int(metrics["champion_wins"]) + 1
	else:
		metrics["draws"] = int(metrics["draws"]) + 1


func _compute_advantages(batch: Array[Dictionary], bootstrap_value: float) -> void:
	var next_value: float = bootstrap_value
	var generalized_advantage: float = 0.0
	for reverse_index in range(batch.size() - 1, -1, -1):
		var sample_data: Dictionary = batch[reverse_index]
		var bootstrap_boundary: bool = bool(sample_data.get("bootstrap_boundary", sample_data.get("done", false)))
		var can_bootstrap: float = 0.0 if bootstrap_boundary else 1.0
		var value: float = float(sample_data.get("value", 0.0))
		var delta: float = float(sample_data.get("reward", 0.0)) + GAMMA * next_value * can_bootstrap - value
		generalized_advantage = delta + GAMMA * GAE_LAMBDA * can_bootstrap * generalized_advantage
		sample_data["advantage"] = generalized_advantage
		sample_data["return"] = generalized_advantage + value
		next_value = value
