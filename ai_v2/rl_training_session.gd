class_name TheodoreRLV2TrainingSession
extends RefCounted

const HeadlessEnvironment := preload("res://ai_v2/rl_headless_environment.gd")
const ChampionAdapter := preload("res://ai_v2/rl_champion_adapter.gd")
const RewardModel := preload("res://ai_v2/rl_reward_model.gd")

const GAMMA: float = 0.995
const GAE_LAMBDA: float = 0.95

var policy = null
var champion = null
var opponent = null
var episode_seconds: float = 20.0
var goals_to_win: int = 3
var seed_value: int = 104729


func _init(neural_policy, requested_seed: int = 104729, requested_episode_seconds: float = 20.0, requested_goals_to_win: int = 3, requested_opponent = null) -> void:
	policy = neural_policy
	champion = ChampionAdapter.new()
	opponent = requested_opponent if requested_opponent != null else champion
	seed_value = requested_seed
	episode_seconds = maxf(1.0, requested_episode_seconds)
	goals_to_win = maxi(1, requested_goals_to_win)


func train_updates(update_count: int, rollout_steps: int, epochs: int = 3, learning_rate: float = 0.00035) -> Dictionary:
	var summaries: Array[Dictionary] = []
	var total_full_games: int = 0
	var total_reward: float = 0.0
	for update_index in range(maxi(1, update_count)):
		var learner_team: StringName = &"blue" if update_index % 2 == 0 else &"red"
		var minimum_full_game_steps: int = ceili(episode_seconds / HeadlessEnvironment.FIXED_STEP_SECONDS) + 1
		var effective_rollout_steps: int = maxi(maxi(16, rollout_steps), minimum_full_game_steps)
		var rollout: Dictionary = collect_rollout(effective_rollout_steps, learner_team, seed_value + update_index * 1009)
		var batch: Array[Dictionary] = rollout.get("batch", [])
		var update_result: Dictionary = policy.ppo_update(batch, epochs, learning_rate)
		total_full_games += int(rollout.get("full_games", 0))
		total_reward += float(rollout.get("total_reward", 0.0))
		summaries.append({
			"update": update_index + 1,
			"learner_team": String(learner_team),
			"full_games": int(rollout.get("full_games", 0)),
			"reward": float(rollout.get("total_reward", 0.0)),
			"policy_loss": float(update_result.get("policy_loss", 0.0)),
			"value_loss": float(update_result.get("value_loss", 0.0))
		})
	return {
		"updates": summaries,
		"full_games": total_full_games,
		"total_reward": total_reward,
		"training_steps": policy.training_steps
	}


func collect_rollout(step_count: int, learner_team: StringName, requested_seed: int) -> Dictionary:
	var environment := HeadlessEnvironment.new(1, requested_seed, episode_seconds, goals_to_win)
	var batch: Array[Dictionary] = []
	var full_games: int = 0
	var total_reward: float = 0.0
	var learner_index: int = 0 if learner_team == &"blue" else 1
	for _step_index in range(maxi(1, step_count)):
		var observations: Array[PackedFloat32Array] = environment.observe_all()
		var learner_sample: Dictionary = policy.sample(observations[learner_index], learner_team, false)
		var actions: Array[Dictionary] = []
		if learner_team == &"blue":
			actions.append(learner_sample["action"])
			actions.append(opponent.action_for(environment, environment.red_players[0]))
		else:
			actions.append(opponent.action_for(environment, environment.blue_players[0]))
			actions.append(learner_sample["action"])
		var before: Dictionary = RewardModel.capture(environment, learner_team)
		var step_result: Dictionary = environment.step(actions)
		var reward: float = RewardModel.transition_reward(environment, learner_team, before, step_result)
		var terminated: bool = bool(step_result.get("terminated", false))
		var reset_boundary: bool = terminated or not StringName(step_result.get("goal_team", &"")).is_empty()
		batch.append({
			"observation": observations[learner_index],
			"raw_continuous": learner_sample["raw_continuous"],
			"discrete": learner_sample["discrete"],
			"discrete_mask": learner_sample.get("discrete_mask", PackedFloat32Array()),
			"old_log_probability": float(learner_sample["log_probability"]),
			"value": float(learner_sample["value"]),
			"reward": reward,
			"done": terminated,
			"bootstrap_boundary": reset_boundary
		})
		total_reward += reward
		if terminated:
			full_games += 1
			environment.finish_and_reset_if_needed(step_result)
	var bootstrap_value: float = 0.0
	if not batch.is_empty() and not bool(batch[batch.size() - 1].get("bootstrap_boundary", batch[batch.size() - 1].get("done", false))):
		var final_observations: Array[PackedFloat32Array] = environment.observe_all()
		bootstrap_value = float(policy.sample(final_observations[learner_index], learner_team, true).get("value", 0.0))
	_compute_advantages(batch, bootstrap_value)
	environment.dispose()
	return {"batch": batch, "full_games": full_games, "total_reward": total_reward}


func evaluate_full_games(match_count: int, requested_seed: int = 300001) -> Dictionary:
	return evaluate_against(opponent, match_count, requested_seed)


func evaluate_against(requested_opponent, match_count: int, requested_seed: int = 300001) -> Dictionary:
	var requested_matches: int = maxi(1, match_count)
	var metrics: Dictionary = {
		"requested_matches": requested_matches,
		"completed_matches": 0,
		"candidate_wins": 0,
		"champion_wins": 0,
		"draws": 0,
		"candidate_goals": 0,
		"champion_goals": 0,
		"candidate_shots": 0,
		"candidate_ability_uses": 0,
		"matches": []
	}
	for match_index in range(requested_matches):
		var candidate_team: StringName = &"blue" if match_index % 2 == 0 else &"red"
		var environment := HeadlessEnvironment.new(1, requested_seed + match_index, episode_seconds, goals_to_win)
		var maximum_steps: int = ceili(episode_seconds / environment.fixed_step_seconds) + 2
		var result: Dictionary = {}
		for _step_index in range(maximum_steps):
			var observations: Array[PackedFloat32Array] = environment.observe_all()
			var candidate_index: int = 0 if candidate_team == &"blue" else 1
			var candidate_sample: Dictionary = policy.sample(observations[candidate_index], candidate_team, true)
			var candidate_action: Dictionary = candidate_sample["action"]
			if int(candidate_action.get("kick_mode", 0)) != 0:
				metrics["candidate_shots"] = int(metrics["candidate_shots"]) + 1
			if bool(candidate_action.get("ability_trigger", false)):
				metrics["candidate_ability_uses"] = int(metrics["candidate_ability_uses"]) + 1
			var actions: Array[Dictionary] = []
			if candidate_team == &"blue":
				actions.append(candidate_action)
				actions.append(requested_opponent.action_for(environment, environment.red_players[0]))
			else:
				actions.append(requested_opponent.action_for(environment, environment.blue_players[0]))
				actions.append(candidate_action)
			result = environment.step(actions)
			if bool(result.get("terminated", false)):
				break
		if not bool(result.get("terminated", false)):
			environment.dispose()
			continue
		metrics["completed_matches"] = int(metrics["completed_matches"]) + 1
		var candidate_score: int = int(result.get("blue_score", 0)) if candidate_team == &"blue" else int(result.get("red_score", 0))
		var champion_score: int = int(result.get("red_score", 0)) if candidate_team == &"blue" else int(result.get("blue_score", 0))
		metrics["candidate_goals"] = int(metrics["candidate_goals"]) + candidate_score
		metrics["champion_goals"] = int(metrics["champion_goals"]) + champion_score
		var match_results: Array = metrics.get("matches", []) as Array
		match_results.append({
			"candidate_team": String(candidate_team),
			"candidate_score": candidate_score,
			"opponent_score": champion_score
		})
		metrics["matches"] = match_results
		if candidate_score > champion_score:
			metrics["candidate_wins"] = int(metrics["candidate_wins"]) + 1
		elif candidate_score < champion_score:
			metrics["champion_wins"] = int(metrics["champion_wins"]) + 1
		else:
			metrics["draws"] = int(metrics["draws"]) + 1
		environment.dispose()
	return metrics


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
