extends Node


const HybridDemonstrationCodec := preload("res://ai/hybrid/demonstration_codec.gd")

const SCHEMA_VERSION := 2
const MODEL_VERSION := 1
const LESSON_FILE := "user://human_ai_lessons.json"
const DEMO_ROOT := "user://human_demonstrations"
const RAW_DIRECTORY := DEMO_ROOT + "/raw"
const CANDIDATE_FILE := DEMO_ROOT + "/candidate_model.json"
const PROMOTED_FILE := DEMO_ROOT + "/promoted_model.json"
const STATE_FILE := DEMO_ROOT + "/state.json"
const MAX_ADAPTIVE_BLEND := 0.22
const MINIMUM_EVIDENCE := 4.0
const SAVE_INTERVAL_SECONDS := 4.0
const SAMPLE_INTERVAL_SECONDS := 0.10
const SEQUENCE_BEFORE_SECONDS := 2.25
const SEQUENCE_AFTER_SECONDS := 1.35
const MIN_RUNTIME_CONFIDENCE := 0.72
const MAX_SEQUENCES_PER_PLAYER_MATCH := 24
const MAX_IDENTICAL_FINGERPRINTS := 3

var _lessons: Dictionary = {}
var _recent_actions: Dictionary = {}
var _last_save_at := 0.0
var _storage_path_override := ""
var _demo_root_override := ""
var _active_match: Dictionary = {}
var _lesson_snapshot_for_active_match: Dictionary = {}
var _last_sample_at := -INF
var _candidate_model: Dictionary = {}
var _promoted_model: Dictionary = {}
var _model_state: Dictionary = {"enabled": false, "promoted_revision": 0}
var _load_warnings: Array[String] = []
var _benchmark_candidate_team: StringName = &""
var _benchmark_mode_active: bool = false


func _ready() -> void:
	if OS.has_environment("THEODORE_RL_V2_HEADLESS"):
		return
	_load_lessons()
	_reload_demonstration_models()


# -----------------------------------------------------------------------------
# Backward-compatible scalar preference layer (schema 1)
# -----------------------------------------------------------------------------

func record_human_kick(
	peer_id: int,
	team: StringName,
	forward_progress: float,
	shot_quality: float,
	used_wall: bool,
	ability_id: int,
	under_pressure: bool
) -> void:
	if peer_id <= 0:
		return
	var quality := clampf(0.12 + maxf(0.0, forward_progress) * 0.36 + shot_quality * 0.52, 0.0, 1.0)
	var action := {
		"team": team, "time": _now(), "quality": quality,
		"used_wall": used_wall, "ability_id": ability_id,
		"under_pressure": under_pressure,
		"forward_progress": forward_progress, "shot_quality": shot_quality
	}
	_recent_actions[peer_id] = action
	if quality >= 0.46:
		_apply_action_lesson(action, quality * 0.18)


func record_human_ability_used(
	peer_id: int,
	team: StringName,
	ability_id: int,
	context_quality: float,
	under_pressure: bool
) -> void:
	if peer_id <= 0 or ability_id <= 0:
		return
	var quality := clampf(context_quality, 0.0, 1.0)
	var action := {
		"team": team, "time": _now(), "quality": quality,
		"used_wall": false, "ability_id": ability_id,
		"under_pressure": under_pressure,
		"forward_progress": 0.0, "shot_quality": 0.0
	}
	_recent_actions[peer_id] = action
	if quality >= 0.58:
		_apply_action_lesson(action, quality * 0.055)


func record_human_goal(peer_id: int, team: StringName) -> void:
	var action := _recent_actions.get(peer_id, {}) as Dictionary
	if action.is_empty() or StringName(action.get("team", &"")) != team:
		return
	if _now() - float(action.get("time", 0.0)) <= 7.0:
		_apply_action_lesson(action, 1.0)


func get_adaptive_profile_overlay() -> Dictionary:
	var parameters := _lessons.get("parameters", {}) as Dictionary
	var evidence := float(_lessons.get("evidence", 0.0))
	if evidence < MINIMUM_EVIDENCE:
		return {}
	var blend := minf(MAX_ADAPTIVE_BLEND, MAX_ADAPTIVE_BLEND * evidence / 55.0)
	return {
		"parameters": parameters.duplicate(true), "blend": blend,
		"evidence": evidence, "matches": int(_lessons.get("matches", 0))
	}


func finish_human_match() -> void:
	_lessons["matches"] = int(_lessons.get("matches", 0)) + 1
	_save_lessons(true)


func get_learning_summary() -> Dictionary:
	var overlay := get_adaptive_profile_overlay()
	return {
		"matches": int(_lessons.get("matches", 0)),
		"evidence": float(_lessons.get("evidence", 0.0)),
		"blend_percent": roundf(float(overlay.get("blend", 0.0)) * 1000.0) / 10.0,
		"parameters": (overlay.get("parameters", {}) as Dictionary).duplicate(true),
		"candidate_sequences": (_candidate_model.get("sequences", []) as Array).size(),
		"promoted_sequences": (_promoted_model.get("sequences", []) as Array).size(),
		"demonstrations_enabled": bool(_model_state.get("enabled", false)),
		"load_warnings": _load_warnings.duplicate()
	}


func reset_human_lessons() -> void:
	_lessons = _default_lessons()
	_recent_actions.clear()
	_save_lessons(true)


# -----------------------------------------------------------------------------
# Authoritative match recorder. It receives server facts, never local input.
# -----------------------------------------------------------------------------

func begin_authoritative_match(roster: Array, metadata: Dictionary) -> void:
	var humans: Dictionary = {}
	for raw_player in roster:
		if not raw_player is Dictionary:
			continue
		var player := raw_player as Dictionary
		var peer_id := int(player.get("peer_id", 0))
		var team := StringName(player.get("team", &""))
		if peer_id <= 0 or bool(player.get("cpu", false)) or team not in [&"blue", &"red"]:
			continue
		humans[str(peer_id)] = {
			"peer_id": peer_id, "team": str(team), "frames": [], "events": []
		}
	if humans.is_empty():
		_active_match.clear()
		_lesson_snapshot_for_active_match.clear()
		return
	_lesson_snapshot_for_active_match = _lessons.duplicate(true)
	_active_match = {
		"schema_version": SCHEMA_VERSION,
		"match_id": "%d-%d" % [Time.get_unix_time_from_system(), Time.get_ticks_msec()],
		"started_unix": Time.get_unix_time_from_system(),
		"metadata": _sanitize_metadata(metadata),
		"players": humans
	}
	_last_sample_at = -INF


func has_active_authoritative_match() -> bool:
	return not _active_match.is_empty()


func record_authoritative_frame(timestamp: float, snapshots: Dictionary) -> void:
	if _active_match.is_empty() or timestamp - _last_sample_at < SAMPLE_INTERVAL_SECONDS:
		return
	_last_sample_at = timestamp
	var players := _active_match.get("players", {}) as Dictionary
	for peer_key in players.keys():
		var peer_id := int(peer_key)
		var snapshot := snapshots.get(peer_id, snapshots.get(peer_key, {})) as Dictionary
		if snapshot.is_empty():
			continue
		var stream := players[peer_key] as Dictionary
		var frame := _sanitize_frame(snapshot)
		frame["t"] = snappedf(timestamp, 0.001)
		(stream["frames"] as Array).append(frame)


func record_authoritative_event(
	peer_id: int,
	event_type: StringName,
	timestamp: float,
	data: Dictionary = {}
) -> void:
	if _active_match.is_empty():
		return
	var players := _active_match.get("players", {}) as Dictionary
	var key := str(peer_id)
	if not players.has(key):
		return
	var event := _sanitize_event(data)
	event["type"] = str(event_type)
	event["t"] = snappedf(timestamp, 0.001)
	((players[key] as Dictionary)["events"] as Array).append(event)


func finish_authoritative_match(result: Dictionary) -> Dictionary:
	if _active_match.is_empty():
		return {}
	_active_match["result"] = _sanitize_event(result)
	_active_match["ended_unix"] = Time.get_unix_time_from_system()
	var raw_document := _active_match.duplicate(true)
	_active_match.clear()
	_lesson_snapshot_for_active_match.clear()
	var raw_path := _raw_path_for_match(str(raw_document.get("match_id", "match")))
	_write_json(raw_path, raw_document)
	var converted := convert_recording_to_demonstrations(raw_document)
	_merge_into_candidate(converted, str(raw_document.get("match_id", "")))
	return {"raw_path": raw_path, "demonstrations": converted.size()}


func abort_authoritative_match() -> void:
	_active_match.clear()
	if not _lesson_snapshot_for_active_match.is_empty():
		_lessons = _lesson_snapshot_for_active_match.duplicate(true)
		_save_lessons(true)
	_lesson_snapshot_for_active_match.clear()
	_recent_actions.clear()
	_last_sample_at = -INF


func convert_recording_to_demonstrations(document: Dictionary) -> Array:
	var migrated := _migrate_recording(document)
	if migrated.is_empty():
		return []
	var output: Array = []
	var result := migrated.get("result", {}) as Dictionary
	var players := migrated.get("players", {}) as Dictionary
	var fingerprints: Dictionary = {}
	for peer_key in players.keys():
		var stream := players[peer_key] as Dictionary
		var frames := stream.get("frames", []) as Array
		var events := stream.get("events", []) as Array
		var made_for_player := 0
		for raw_event in events:
			if made_for_player >= MAX_SEQUENCES_PER_PLAYER_MATCH or not raw_event is Dictionary:
				break
			var event := raw_event as Dictionary
			if str(event.get("type", "")) not in [
				"kick", "pass", "ability", "reception", "interception",
				"recovery", "defense", "shot_result", "goal", "assist",
				"own_goal", "possession_loss", "pass_completed", "pass_failed",
				"chance_created", "combination_completed", "ability_success",
				"ability_failed", "shot_conceded"
			]:
				continue
			var sequence := _build_sequence(stream, frames, events, event, result, false)
			if sequence.is_empty():
				continue
			var fingerprint := str(sequence.get("fingerprint", ""))
			var count := int(fingerprints.get(fingerprint, 0))
			if count >= MAX_IDENTICAL_FINGERPRINTS:
				continue
			fingerprints[fingerprint] = count + 1
			output.append(sequence)
			output.append(_mirror_sequence(sequence))
			made_for_player += 1
	return output


func import_recording(path: String) -> Dictionary:
	var document := _read_json(path)
	if document.is_empty():
		return {"ok": false, "error": "corrupt_or_missing", "path": path}
	var sequences := convert_recording_to_demonstrations(document)
	if sequences.is_empty():
		return {"ok": false, "error": "no_valid_sequences", "path": path}
	_merge_into_candidate(sequences, str(document.get("match_id", path.get_file())))
	return {"ok": true, "sequences": sequences.size(), "path": path}


# -----------------------------------------------------------------------------
# Candidate training, held-out evaluation, promotion, enabling and rollback.
# -----------------------------------------------------------------------------

func train_candidate_from_raw() -> Dictionary:
	_candidate_model = _empty_model("candidate")
	var directory := DirAccess.open(_demo_path("raw"))
	if directory == null:
		_save_candidate()
		return {"files": 0, "sequences": 0}
	var files := directory.get_files()
	files.sort()
	var imported := 0
	for file_name in files:
		if not file_name.ends_with(".json"):
			continue
		var document := _read_json(_demo_path("raw/" + file_name))
		var sequences := convert_recording_to_demonstrations(document)
		if sequences.is_empty():
			continue
		_merge_sequences(_candidate_model, sequences, str(document.get("match_id", file_name)))
		imported += 1
	_finalize_model(_candidate_model)
	_save_candidate()
	return {"files": imported, "sequences": (_candidate_model.get("sequences", []) as Array).size()}


func evaluate_candidate(benchmark: Dictionary = {}) -> Dictionary:
	var sequences := _candidate_model.get("sequences", []) as Array
	var replay_metrics := _evaluate_held_out_replay(sequences)
	var held_out_total := int(replay_metrics.get("samples", 0))
	var held_out_correct := int(replay_metrics.get("correct", 0))
	var held_out_reward := float(replay_metrics.get("reward", 0.0))
	var training_reward := 0.0
	var ability_ids: Dictionary = {}
	for raw_sequence in sequences:
		var sequence := raw_sequence as Dictionary
		var reward := float(sequence.get("reward", 0.0))
		var held_out := int(sequence.get("split", 0)) == 1
		if not held_out:
			training_reward += reward
		var ability_id := int(sequence.get("ability_id", 0))
		if ability_id > 0:
			ability_ids[ability_id] = true
	var held_out_accuracy := float(held_out_correct) / maxf(1.0, float(held_out_total))
	var candidate_metrics := benchmark.get("candidate", {}) as Dictionary
	var champion_metrics := benchmark.get("champion", {}) as Dictionary
	var benchmark_supplied := not candidate_metrics.is_empty() and not champion_metrics.is_empty()
	var benchmark_passed := benchmark_supplied and _benchmark_improves(candidate_metrics, champion_metrics)
	var held_out_passed := held_out_total >= 4 and held_out_accuracy >= 0.55 and held_out_reward > -float(held_out_total) * 0.15
	var result := {
		"version": MODEL_VERSION,
		"held_out_samples": held_out_total,
		"held_out_accuracy": held_out_accuracy,
		"held_out_reward": held_out_reward,
		"training_reward": training_reward,
		"ability_policies": ability_ids.size(),
		"held_out_passed": held_out_passed,
		"benchmark_supplied": benchmark_supplied,
		"benchmark_passed": benchmark_passed,
		"promotion_allowed": held_out_passed and benchmark_passed,
		"candidate_metrics": candidate_metrics,
		"champion_metrics": champion_metrics
	}
	_candidate_model["last_evaluation"] = result
	_save_candidate()
	return result


func _evaluate_held_out_replay(sequences: Array) -> Dictionary:
	var training: Array = []
	var held_out: Array = []
	for raw_sequence in sequences:
		var sequence := raw_sequence as Dictionary
		if int(sequence.get("split", 0)) == 1:
			held_out.append(sequence)
		else:
			training.append(sequence)
	var replay_model := _empty_model("held_out_replay")
	replay_model["sequences"] = training
	var correct := 0
	var reward := 0.0
	for expected in held_out:
		var expected_reward := float(expected.get("reward", 0.0))
		reward += expected_reward
		var predicted := query_model(replay_model, expected.get("context", {}) as Dictionary)
		if expected_reward < 0.0:
			# A negative example is handled correctly when it is not selected as a
			# positive plan in the same context.
			if predicted.is_empty() or str(predicted.get("fingerprint", "")) != str(expected.get("fingerprint", "")):
				correct += 1
			continue
		if predicted.is_empty() or int(predicted.get("ability_id", 0)) != int(expected.get("ability_id", 0)):
			continue
		var predicted_actions := predicted.get("actions", []) as Array
		var expected_actions := expected.get("actions", []) as Array
		if predicted_actions.is_empty() or expected_actions.is_empty():
			continue
		var predicted_action := predicted_actions.front() as Dictionary
		var expected_action := expected_actions.front() as Dictionary
		if str(predicted_action.get("kind", "")) != str(expected_action.get("kind", "")):
			continue
		if _array_distance(predicted_action.get("target", []), expected_action.get("target", [])) <= 0.28:
			correct += 1
	return {"samples": held_out.size(), "correct": correct, "reward": reward}


func promote_candidate() -> Dictionary:
	var evaluation := _candidate_model.get("last_evaluation", {}) as Dictionary
	if not bool(evaluation.get("promotion_allowed", false)):
		return {"ok": false, "error": "evaluation_gate_failed", "evaluation": evaluation}
	_promoted_model = _candidate_model.duplicate(true)
	_promoted_model["kind"] = "promoted"
	_promoted_model["promoted_unix"] = Time.get_unix_time_from_system()
	_model_state["promoted_revision"] = int(_model_state.get("promoted_revision", 0)) + 1
	_write_json(_demo_path("promoted_model.json"), _promoted_model)
	_save_state()
	return {"ok": true, "revision": int(_model_state["promoted_revision"]), "sequences": (_promoted_model.get("sequences", []) as Array).size()}


func set_demonstration_model_enabled(enabled: bool) -> bool:
	if enabled and (_promoted_model.get("sequences", []) as Array).is_empty():
		return false
	_model_state["enabled"] = enabled
	_save_state()
	return true


func revert_demonstration_model() -> void:
	_model_state["enabled"] = false
	_save_state()


func get_contextual_demonstration(context: Dictionary) -> Dictionary:
	if _benchmark_mode_active:
		if (
			_benchmark_candidate_team in [&"blue", &"red"]
			and StringName(context.get("live_team", &"")) == _benchmark_candidate_team
		):
			return query_model(_candidate_model, context)
		return {}
	if not bool(_model_state.get("enabled", false)):
		return {}
	return query_model(_promoted_model, context)


func set_candidate_benchmark_team(team: StringName) -> bool:
	if team not in [&"", &"blue", &"red"]:
		return false
	_benchmark_candidate_team = team
	return team == &"" or not (_candidate_model.get("sequences", []) as Array).is_empty()


func set_candidate_benchmark_mode(active: bool, team: StringName = &"") -> bool:
	if team not in [&"", &"blue", &"red"]:
		return false
	_benchmark_mode_active = active
	_benchmark_candidate_team = team if active else &""
	return not active or team == &"" or not (_candidate_model.get("sequences", []) as Array).is_empty()


func has_candidate_demonstrations() -> bool:
	return not (_candidate_model.get("sequences", []) as Array).is_empty()


func query_candidate_for_tests(context: Dictionary) -> Dictionary:
	return query_model(_candidate_model, context)


func query_model(model: Dictionary, context: Dictionary) -> Dictionary:
	var sequences := model.get("sequences", []) as Array
	var best: Dictionary = {}
	var best_score := -INF
	for raw_sequence in sequences:
		var sequence := raw_sequence as Dictionary
		if float(sequence.get("reward", 0.0)) <= 0.0:
			continue
		var start_context := sequence.get("context", {}) as Dictionary
		var similarity := _context_similarity(start_context, context)
		var score := similarity * float(sequence.get("confidence", 0.0))
		if score > best_score:
			best_score = score
			best = sequence
	if best.is_empty() or best_score < MIN_RUNTIME_CONFIDENCE:
		return {}
	var plan := best.duplicate(true)
	plan["runtime_confidence"] = best_score
	plan["adapted_actions"] = _adapt_actions(best.get("actions", []) as Array, context)
	return plan


# -----------------------------------------------------------------------------
# Conversion and normalization helpers
# -----------------------------------------------------------------------------

func _build_sequence(
	stream: Dictionary,
	frames: Array,
	events: Array,
	anchor: Dictionary,
	result: Dictionary,
	mirrored: bool
) -> Dictionary:
	var anchor_time := float(anchor.get("t", 0.0))
	var selected_frames: Array = []
	for raw_frame in frames:
		var frame := raw_frame as Dictionary
		var time := float(frame.get("t", 0.0))
		if time >= anchor_time - SEQUENCE_BEFORE_SECONDS and time <= anchor_time + SEQUENCE_AFTER_SECONDS:
			selected_frames.append(frame.duplicate(true))
	if selected_frames.size() < 2:
		return {}
	var selected_events: Array = []
	for raw_event in events:
		var event := raw_event as Dictionary
		var time := float(event.get("t", 0.0))
		if time >= anchor_time - 0.35 and time <= anchor_time + SEQUENCE_AFTER_SECONDS:
			selected_events.append(event.duplicate(true))
	var reward := _score_sequence(anchor, selected_events, result, int(stream.get("peer_id", 0)))
	var actions := _events_to_actions(selected_events, anchor_time)
	actions.push_front(_frame_to_movement_action(selected_frames.front() as Dictionary, anchor_time))
	var context := _compact_context(selected_frames.front() as Dictionary)
	var ability_id := int(anchor.get("ability_id", 0))
	context["ability_id"] = ability_id
	var tactical_label := HybridDemonstrationCodec.infer_tactical_label(
		context,
		actions,
		str(anchor.get("type", ""))
	)
	var fingerprint := _sequence_fingerprint(context, actions, ability_id)
	return {
		"schema_version": SCHEMA_VERSION,
		"model_version": MODEL_VERSION,
		"source_match": str(_active_match.get("match_id", "")),
		"anchor_type": str(anchor.get("type", "")),
		"ability_id": ability_id,
		"combination_id": str(anchor.get("combination_id", "ordinary")),
		"context": context,
		"tactical_label": tactical_label,
		"actions": actions,
		"reward": reward,
		"negative_example": reward < 0.0,
		"confidence": clampf(0.45 + absf(reward) * 0.11 + minf(selected_frames.size(), 18) * 0.012, 0.0, 0.96),
		"fingerprint": fingerprint,
		"split": abs(fingerprint.hash()) % 5 == 0,
		"mirrored": mirrored
	}


func _score_sequence(anchor: Dictionary, events: Array, result: Dictionary, peer_id: int) -> float:
	var score := 0.0
	var productive_followup := false
	for raw_event in events:
		var event := raw_event as Dictionary
		match str(event.get("type", "")):
			"goal": score += 5.0; productive_followup = true
			"assist": score += 3.2; productive_followup = true
			"chance_created": score += 1.5; productive_followup = true
			"combination_completed": score += 2.2; productive_followup = true
			"ability_success": score += 1.35; productive_followup = true
			"reception": score += 0.65; productive_followup = true
			"recovery", "interception": score += 1.0; productive_followup = true
			"defense": score += 0.8; productive_followup = true
			"pass_completed": score += 0.75; productive_followup = true
			"shot_result":
				score += 1.0 if bool(event.get("on_target", false)) else -0.4
				productive_followup = productive_followup or bool(event.get("on_target", false))
			"pass_failed": score -= 0.8
			"ability_failed": score -= 1.0
			"possession_loss": score -= 1.1
			"shot_conceded": score -= 1.2
			"own_goal": score -= 7.0
	if str(anchor.get("type", "")) == "own_goal":
		score -= 4.0
	if str(anchor.get("type", "")) == "ability" and not productive_followup:
		score -= 0.65
	if int(result.get("own_goal_peer_id", 0)) == peer_id:
		score -= 3.0
	return clampf(score, -10.0, 10.0)


func _events_to_actions(events: Array, anchor_time: float) -> Array:
	var actions: Array = []
	for raw_event in events:
		var event := raw_event as Dictionary
		var type := str(event.get("type", ""))
		if type not in ["kick", "pass", "ability", "reception", "interception", "recovery", "defense"]:
			continue
		var action := {
			"dt": snappedf(float(event.get("t", anchor_time)) - anchor_time, 0.01),
			"kind": type,
			"move": event.get("move", [0.0, 0.0]),
			"aim": event.get("aim", [1.0, 0.0]),
			"target": event.get("target", [1.0, 0.5]),
			"target_role": str(event.get("target_role", "space")),
			"lead": event.get("lead", [0.0, 0.0]),
			"charge": clampf(float(event.get("charge", 0.0)), 0.0, 4.0),
			"pass_type": str(event.get("pass_type", "none")),
			"ability_id": int(event.get("ability_id", 0)),
			"cooldown_ready": bool(event.get("cooldown_ready", true))
		}
		actions.append(action)
	actions.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.get("dt", 0.0)) < float(b.get("dt", 0.0)))
	return actions


func _frame_to_movement_action(frame: Dictionary, anchor_time: float) -> Dictionary:
	var actor := frame.get("actor", [0.5, 0.5]) as Array
	var move := frame.get("move", [0.0, 0.0]) as Array
	var target := [
		clampf(float(actor[0]) + float(move[0]) * 0.08, 0.0, 1.0),
		clampf(float(actor[1]) + float(move[1]) * 0.11, 0.0, 1.0)
	]
	return {
		"dt": 0.0, "kind": "movement", "move": move,
		"aim": frame.get("aim", [1.0, 0.0]), "target": target,
		"source_actor": actor,
		"target_role": "space", "charge": 0.0, "pass_type": "none",
		"ability_id": int(frame.get("ability_id", 0)), "cooldown_ready": bool(frame.get("cooldown_ready", true))
	}


func _mirror_sequence(sequence: Dictionary) -> Dictionary:
	var mirrored := sequence.duplicate(true)
	mirrored["mirrored"] = true
	var context := mirrored.get("context", {}) as Dictionary
	_mirror_context_y(context)
	for raw_action in mirrored.get("actions", []) as Array:
		var action := raw_action as Dictionary
		action["move"] = _mirror_direction_y(action.get("move", [0.0, 0.0]))
		action["aim"] = _mirror_direction_y(action.get("aim", [1.0, 0.0]))
		action["target"] = _mirror_point_y(action.get("target", [0.5, 0.5]))
		action["lead"] = _mirror_direction_y(action.get("lead", [0.0, 0.0]))
		if action.has("source_actor"):
			action["source_actor"] = _mirror_point_y(action["source_actor"])
	mirrored["fingerprint"] = str(sequence.get("fingerprint", "")) + "-m"
	mirrored["split"] = abs(str(mirrored["fingerprint"]).hash()) % 5 == 0
	return mirrored


func _compact_context(frame: Dictionary) -> Dictionary:
	return {
		"actor": frame.get("actor", [0.5, 0.5]),
		"actor_velocity": frame.get("actor_velocity", [0.0, 0.0]),
		"ball": frame.get("ball", [0.5, 0.5]),
		"ball_velocity": frame.get("ball_velocity", [0.0, 0.0]),
		"possession": str(frame.get("possession", "none")),
		"teammates": frame.get("teammates", []),
		"opponents": frame.get("opponents", []),
		"goal": frame.get("goal", [1.0, 0.5]),
		"goalkeeper": frame.get("goalkeeper", [1.0, 0.5]),
		"ability_id": int(frame.get("ability_id", 0)),
		"cooldown_ready": bool(frame.get("cooldown_ready", true)),
		"under_pressure": bool(frame.get("under_pressure", false))
	}


func _context_similarity(a: Dictionary, b: Dictionary) -> float:
	if str(a.get("possession", "none")) != str(b.get("possession", "none")):
		return 0.0
	var ability_a := int(a.get("ability_id", 0))
	var ability_b := int(b.get("ability_id", 0))
	if ability_a > 0 and ability_b != ability_a:
		return 0.0
	if ability_a > 0 and not bool(b.get("cooldown_ready", false)):
		return 0.0
	var distance := 0.0
	distance += _array_distance(a.get("actor", []), b.get("actor", [])) * 1.2
	distance += _array_distance(a.get("ball", []), b.get("ball", [])) * 1.7
	distance += _array_distance(a.get("ball_velocity", []), b.get("ball_velocity", [])) * 0.45
	distance += _array_distance(a.get("goalkeeper", []), b.get("goalkeeper", [])) * 0.55
	distance += _group_context_distance(a.get("teammates", []) as Array, b.get("teammates", []) as Array) * 0.55
	distance += _group_context_distance(a.get("opponents", []) as Array, b.get("opponents", []) as Array) * 0.85
	if bool(a.get("under_pressure", false)) != bool(b.get("under_pressure", false)):
		distance += 0.22
	return clampf(exp(-distance * 1.7), 0.0, 1.0)


func _group_context_distance(a: Array, b: Array) -> float:
	var distance := absf(float(a.size() - b.size())) * 0.12
	var compared := mini(3, mini(a.size(), b.size()))
	for index in range(compared):
		var a_member := a[index] as Dictionary
		var b_member := b[index] as Dictionary
		distance += _array_distance(a_member.get("position", []), b_member.get("position", [])) / float(maxi(1, compared))
	return distance


func _adapt_actions(actions: Array, context: Dictionary) -> Array:
	var adapted: Array = []
	var live_actor := context.get("actor", [0.5, 0.5]) as Array
	for raw_action in actions:
		var action := (raw_action as Dictionary).duplicate(true)
		var target := action.get("target", live_actor) as Array
		var role := str(action.get("target_role", "space"))
		if role.begins_with("teammate"):
			var teammates := context.get("teammates", []) as Array
			var index := clampi(int(role.get_slice("_", 1)), 0, maxi(0, teammates.size() - 1))
			if not teammates.is_empty():
				var teammate := teammates[index] as Dictionary
				target = teammate.get("position", target) as Array
				var lead := action.get("lead", [0.0, 0.0]) as Array
				if target.size() >= 2 and lead.size() >= 2:
					target = [
						clampf(float(target[0]) + float(lead[0]), 0.0, 1.0),
						clampf(float(target[1]) + float(lead[1]), 0.0, 1.0)
					]
		elif role == "goal":
			target = context.get("goal", target) as Array
		else:
			var source_actor := (raw_action as Dictionary).get("source_actor", live_actor) as Array
			if source_actor.size() >= 2 and live_actor.size() >= 2 and target.size() >= 2:
				target = [clampf(float(live_actor[0]) + float(target[0]) - float(source_actor[0]), 0.0, 1.0), clampf(float(live_actor[1]) + float(target[1]) - float(source_actor[1]), 0.0, 1.0)]
		action["target"] = target
		adapted.append(action)
	return adapted


func _sanitize_frame(source: Dictionary) -> Dictionary:
	var allowed := ["actor", "actor_velocity", "ball", "ball_velocity", "possession", "teammates", "opponents", "goal", "goalkeeper", "move", "aim", "charging", "charge", "ability_id", "active_ability_id", "ability_active", "cooldown", "cooldown_ready", "under_pressure", "attack_direction"]
	var result: Dictionary = {}
	for key in allowed:
		if source.has(key):
			result[key] = _json_safe(source[key])
	return result


func _sanitize_event(source: Dictionary) -> Dictionary:
	var blocked_fragments := ["name", "chat", "account", "steam", "controller", "device", "guid"]
	var result: Dictionary = {}
	for key in source.keys():
		var normalized_key := str(key).to_lower()
		var blocked := false
		for fragment in blocked_fragments:
			if normalized_key.contains(fragment):
				blocked = true
				break
		if blocked:
			continue
		result[str(key)] = _json_safe(source[key])
	return result


func _sanitize_metadata(source: Dictionary) -> Dictionary:
	return _sanitize_event(source)


func _json_safe(value: Variant) -> Variant:
	if value is Vector2:
		return [snappedf(value.x, 0.0001), snappedf(value.y, 0.0001)]
	if value is StringName:
		return str(value)
	if value is Dictionary:
		return _sanitize_event(value as Dictionary)
	if value is Array:
		var output: Array = []
		for item in value:
			output.append(_json_safe(item))
		return output
	return value


func _migrate_recording(document: Dictionary) -> Dictionary:
	var version := int(document.get("schema_version", document.get("version", 1)))
	if version == SCHEMA_VERSION and document.get("players") is Dictionary:
		return document.duplicate(true)
	if version == 1 and document.get("players") is Dictionary:
		var migrated := document.duplicate(true)
		migrated["schema_version"] = SCHEMA_VERSION
		for peer_key in (migrated.get("players", {}) as Dictionary).keys():
			var stream := (migrated["players"] as Dictionary)[peer_key] as Dictionary
			if not stream.has("events"):
				stream["events"] = []
			if not stream.has("frames"):
				stream["frames"] = []
		return migrated
	_load_warnings.append("Unsupported demonstration recording schema: %d" % version)
	return {}


func export_behavior_cloning_dataset(
	output_path: String = "user://human_demonstrations/tactical_bc.jsonl"
) -> Dictionary:
	var sequences := _candidate_model.get("sequences", []) as Array
	if sequences.is_empty():
		return {"ok": false, "error": "candidate_has_no_sequences"}
	var absolute_directory := ProjectSettings.globalize_path(output_path.get_base_dir())
	DirAccess.make_dir_recursive_absolute(absolute_directory)
	var file := FileAccess.open(output_path, FileAccess.WRITE)
	if file == null:
		return {"ok": false, "error": "dataset_write_failed", "path": output_path}
	var train_count := 0
	var validation_count := 0
	for sequence_variant in sequences:
		var sequence := sequence_variant as Dictionary
		if bool(sequence.get("negative_example", false)):
			continue
		var context := sequence.get("context", {}) as Dictionary
		var actions := sequence.get("actions", []) as Array
		var label := str(sequence.get("tactical_label", ""))
		if label.is_empty():
			label = HybridDemonstrationCodec.infer_tactical_label(
				context, actions, str(sequence.get("anchor_type", ""))
			)
		var split := "validation" if bool(sequence.get("split", false)) else "train"
		if split == "validation":
			validation_count += 1
		else:
			train_count += 1
		file.store_line(JSON.stringify({
			"features": HybridDemonstrationCodec.context_to_features(context),
			"label": label,
			"split": split,
			"confidence": float(sequence.get("confidence", 0.0)),
			"reward": float(sequence.get("reward", 0.0)),
			"source_match": str(sequence.get("source_match", ""))
		}))
	return {
		"ok": true,
		"path": output_path,
		"train": train_count,
		"validation": validation_count
	}


# -----------------------------------------------------------------------------
# Persistence/model helpers
# -----------------------------------------------------------------------------

func set_storage_path_for_tests(path: String) -> void:
	_storage_path_override = path


func set_demo_root_for_tests(path: String) -> void:
	_demo_root_override = path.trim_suffix("/")
	_reload_demonstration_models()


func set_candidate_model_for_tests(model: Dictionary) -> void:
	_candidate_model = model.duplicate(true)


func get_candidate_model_for_tests() -> Dictionary:
	return _candidate_model.duplicate(true)


func _merge_into_candidate(sequences: Array, source_match: String) -> void:
	if _candidate_model.is_empty():
		_candidate_model = _empty_model("candidate")
	_merge_sequences(_candidate_model, sequences, source_match)
	_finalize_model(_candidate_model)
	_save_candidate()


func _merge_sequences(model: Dictionary, sequences: Array, source_match: String) -> void:
	var stored := model.get("sequences", []) as Array
	var per_match: Dictionary = {}
	for raw_sequence in stored:
		var existing := raw_sequence as Dictionary
		per_match[str(existing.get("source_match", ""))] = int(per_match.get(str(existing.get("source_match", "")), 0)) + 1
	for raw_sequence in sequences:
		var sequence := (raw_sequence as Dictionary).duplicate(true)
		sequence["source_match"] = source_match
		if int(per_match.get(source_match, 0)) >= MAX_SEQUENCES_PER_PLAYER_MATCH * 4:
			break
		var duplicate_count := 0
		for raw_existing in stored:
			if str((raw_existing as Dictionary).get("fingerprint", "")) == str(sequence.get("fingerprint", "")):
				duplicate_count += 1
		if duplicate_count >= MAX_IDENTICAL_FINGERPRINTS:
			continue
		stored.append(sequence)
		per_match[source_match] = int(per_match.get(source_match, 0)) + 1
	model["sequences"] = stored
	var sources := model.get("source_matches", []) as Array
	if not source_match.is_empty() and source_match not in sources:
		sources.append(source_match)
	model["source_matches"] = sources


func _finalize_model(model: Dictionary) -> void:
	var sequences := model.get("sequences", []) as Array
	var policies: Dictionary = {"ordinary": 0, "abilities": {}, "combinations": {}}
	var fingerprint_counts: Dictionary = {}
	for raw_sequence in sequences:
		var sequence := raw_sequence as Dictionary
		var fingerprint := str(sequence.get("fingerprint", ""))
		fingerprint_counts[fingerprint] = int(fingerprint_counts.get(fingerprint, 0)) + 1
		var ability_id := int(sequence.get("ability_id", 0))
		var combo := str(sequence.get("combination_id", "ordinary"))
		if ability_id > 0:
			var abilities := policies["abilities"] as Dictionary
			abilities[str(ability_id)] = int(abilities.get(str(ability_id), 0)) + 1
		elif combo != "ordinary":
			var combos := policies["combinations"] as Dictionary
			combos[combo] = int(combos.get(combo, 0)) + 1
		else:
			policies["ordinary"] = int(policies["ordinary"]) + 1
	for raw_sequence in sequences:
		var sequence := raw_sequence as Dictionary
		var repeats := int(fingerprint_counts.get(str(sequence.get("fingerprint", "")), 1))
		var reliability := 1.0 / sqrt(float(maxi(1, repeats)))
		sequence["confidence"] = clampf(float(sequence.get("confidence", 0.0)) * reliability, 0.0, 0.96)
	model["policies"] = policies
	model["updated_unix"] = Time.get_unix_time_from_system()


func _benchmark_improves(candidate: Dictionary, champion: Dictionary) -> bool:
	var candidate_value := (
		float(candidate.get("goals", 0.0)) * 4.0
		+ float(candidate.get("assists", 0.0)) * 2.0
		+ float(candidate.get("possession_safety", 0.0)) * 2.0
		+ float(candidate.get("defense", 0.0)) * 1.5
		- float(candidate.get("own_goals", 0.0)) * 7.0
	)
	var champion_value := (
		float(champion.get("goals", 0.0)) * 4.0
		+ float(champion.get("assists", 0.0)) * 2.0
		+ float(champion.get("possession_safety", 0.0)) * 2.0
		+ float(champion.get("defense", 0.0)) * 1.5
		- float(champion.get("own_goals", 0.0)) * 7.0
	)
	return (
		candidate_value > champion_value
		and float(candidate.get("goals", 0.0)) >= float(champion.get("goals", 0.0))
		and float(candidate.get("assists", 0.0)) >= float(champion.get("assists", 0.0))
		and float(candidate.get("possession_safety", 0.0)) >= float(champion.get("possession_safety", 0.0))
		and float(candidate.get("defense", 0.0)) >= float(champion.get("defense", 0.0))
		and float(candidate.get("own_goals", 0.0)) <= float(champion.get("own_goals", 0.0))
	)


func _empty_model(kind: String) -> Dictionary:
	return {"model_version": MODEL_VERSION, "schema_version": SCHEMA_VERSION, "kind": kind, "source_matches": [], "sequences": [], "policies": {}}


func _reload_demonstration_models() -> void:
	_load_warnings.clear()
	_candidate_model = _load_model(_demo_path("candidate_model.json"), "candidate")
	_promoted_model = _load_model(_demo_path("promoted_model.json"), "promoted")
	var state := _read_json(_demo_path("state.json"))
	if not state.is_empty():
		_model_state = state
	else:
		_model_state = {"enabled": false, "promoted_revision": 0}


func _load_model(path: String, kind: String) -> Dictionary:
	var document := _read_json(path)
	if document.is_empty():
		return _empty_model(kind)
	if int(document.get("model_version", 0)) != MODEL_VERSION or not document.get("sequences") is Array:
		_load_warnings.append("Ignored incompatible or corrupt %s model." % kind)
		return _empty_model(kind)
	return document


func _save_candidate() -> void:
	_write_json(_demo_path("candidate_model.json"), _candidate_model)


func _save_state() -> void:
	_write_json(_demo_path("state.json"), _model_state)


func _raw_path_for_match(match_id: String) -> String:
	return _demo_path("raw/%s.json" % match_id.validate_filename())


func _demo_path(relative: String) -> String:
	var root := _demo_root_override if not _demo_root_override.is_empty() else DEMO_ROOT
	return root + "/" + relative.trim_prefix("/")


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK:
		return {}
	var parsed: Variant = parser.data
	return parsed as Dictionary if parsed is Dictionary else {}


func _write_json(path: String, data: Dictionary) -> bool:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Could not write human demonstration data: %s" % path)
		return false
	file.store_string(JSON.stringify(data, "\t", false))
	return true


func _sequence_fingerprint(context: Dictionary, actions: Array, ability_id: int) -> String:
	var actor := context.get("actor", [0.5, 0.5]) as Array
	var ball_position := context.get("ball", [0.5, 0.5]) as Array
	var kind := str((actions.front() as Dictionary).get("kind", "movement")) if not actions.is_empty() else "movement"
	return "%d:%s:%d:%d:%d:%d:%s" % [ability_id, str(context.get("possession", "none")), roundi(float(actor[0]) * 8.0), roundi(float(actor[1]) * 6.0), roundi(float(ball_position[0]) * 8.0), roundi(float(ball_position[1]) * 6.0), kind]


func _mirror_context_y(context: Dictionary) -> void:
	for key in ["actor", "ball", "goal", "goalkeeper"]:
		if context.has(key):
			context[key] = _mirror_point_y(context[key])
	for key in ["actor_velocity", "ball_velocity"]:
		if context.has(key):
			context[key] = _mirror_direction_y(context[key])
	for group_key in ["teammates", "opponents"]:
		for raw_member in context.get(group_key, []) as Array:
			var member := raw_member as Dictionary
			if member.has("position"):
				member["position"] = _mirror_point_y(member["position"])
			if member.has("velocity"):
				member["velocity"] = _mirror_direction_y(member["velocity"])


func _mirror_point_y(value: Variant) -> Array:
	var point := value as Array
	return [float(point[0]), 1.0 - float(point[1])] if point.size() >= 2 else [0.5, 0.5]


func _mirror_direction_y(value: Variant) -> Array:
	var direction := value as Array
	return [float(direction[0]), -float(direction[1])] if direction.size() >= 2 else [0.0, 0.0]


func _array_distance(a_value: Variant, b_value: Variant) -> float:
	var a := a_value as Array
	var b := b_value as Array
	if a.size() < 2 or b.size() < 2:
		return 1.0
	return Vector2(float(a[0]), float(a[1])).distance_to(Vector2(float(b[0]), float(b[1])))


func _apply_action_lesson(action: Dictionary, weight: float) -> void:
	if weight <= 0.0:
		return
	var parameters := _lessons.get("parameters", {}) as Dictionary
	var forward_progress := float(action.get("forward_progress", 0.0))
	var shot_quality := float(action.get("shot_quality", 0.0))
	var used_wall := bool(action.get("used_wall", false))
	var ability_id := int(action.get("ability_id", 0))
	var under_pressure := bool(action.get("under_pressure", false))
	if forward_progress >= 0.32:
		_nudge(parameters, "advance_play_chance", 0.70, weight)
		_nudge(parameters, "pass_lead_seconds", 0.27, weight)
		_nudge(parameters, "cpu_receiver_forward_lead", 410.0, weight)
	if shot_quality >= 0.42:
		_nudge(parameters, "creative_shot_chance", 0.48, weight)
		_nudge(parameters, "shot_aim_vertical_spread", 265.0, weight)
	if used_wall:
		_nudge(parameters, "wall_dribble_choice_chance", 0.43, weight)
		_nudge(parameters, "creative_wall_shot_chance", 0.38, weight)
	if ability_id > 0:
		_nudge(parameters, "ability_improvisation_chance", 0.43, weight)
		_nudge(parameters, "coordinated_ability_play_chance", 0.48, weight)
		_nudge(parameters, "ability_use_bias_%d" % ability_id, 1.38, weight)
	if under_pressure and forward_progress >= 0.2:
		_nudge(parameters, "dribble_choice_chance", 0.52, weight)
		_nudge(parameters, "contest_escape_choice_chance", 0.49, weight)
	_lessons["parameters"] = parameters
	_lessons["evidence"] = float(_lessons.get("evidence", 0.0)) + weight
	_save_lessons()


func _nudge(parameters: Dictionary, key: String, target: float, weight: float) -> void:
	var current := float(parameters.get(key, target))
	parameters[key] = lerpf(current, target, clampf(weight * 0.09, 0.0, 0.08))


func _default_lessons() -> Dictionary:
	return {"version": 1, "matches": 0, "evidence": 0.0, "parameters": {}}


func _load_lessons() -> void:
	_lessons = _default_lessons()
	var document := _read_json(_storage_path())
	if document.has("parameters") and document.get("parameters") is Dictionary:
		_lessons = document


func _save_lessons(force: bool = false) -> void:
	if not force and _now() - _last_save_at < SAVE_INTERVAL_SECONDS:
		return
	_write_json(_storage_path(), _lessons)
	_last_save_at = _now()


func _storage_path() -> String:
	return _storage_path_override if not _storage_path_override.is_empty() else LESSON_FILE


func _now() -> float:
	return float(Time.get_ticks_msec()) / 1000.0
