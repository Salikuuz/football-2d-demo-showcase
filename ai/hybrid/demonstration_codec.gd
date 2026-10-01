class_name HybridDemonstrationCodec
extends RefCounted


const Schema := preload("res://ai/hybrid/tactical_schema.gd")


static func infer_tactical_label(
	context: Dictionary,
	actions: Array,
	anchor_type: String = ""
) -> String:
	var possession := str(context.get("possession", "none"))
	var under_pressure := bool(context.get("under_pressure", false))
	for action_variant in actions:
		var action := action_variant as Dictionary
		var kind := str(action.get("kind", ""))
		var role := str(action.get("target_role", "space"))
		var pass_type := str(action.get("pass_type", "none"))
		if kind == "pass" or role.begins_with("teammate"):
			var lead := action.get("lead", [0.0, 0.0]) as Array
			var forward_lead := absf(float(lead[0])) if not lead.is_empty() else 0.0
			return str(Schema.ACTION_PASS_AHEAD if forward_lead > 0.035 or pass_type not in ["none", "short"] else Schema.ACTION_SAFE_PASS)
		if kind in ["kick", "shot_result"] or role == "goal":
			var target := action.get("target", [1.0, 0.5]) as Array
			if target.size() >= 2:
				var target_y := float(target[1])
				if target_y < 0.34:
					return str(Schema.ACTION_NEAR_POST_SHOT)
				if target_y > 0.66:
					return str(Schema.ACTION_FAR_POST_SHOT)
			return str(Schema.ACTION_DIRECT_SHOT)
		if kind in ["interception", "recovery", "defense"]:
			return str(Schema.ACTION_CHALLENGE_BALL)
	if anchor_type in ["interception", "recovery", "defense"]:
		return str(Schema.ACTION_CHALLENGE_BALL)
	if possession in ["self", "team"]:
		return str(Schema.ACTION_CARRY if possession == "self" else Schema.ACTION_SUPPORT_TEAMMATE)
	if possession in ["opponent", "enemy"]:
		return str(Schema.ACTION_SHADOW_DEFEND if under_pressure else Schema.ACTION_PROTECT_GOAL)
	return str(Schema.ACTION_MOVE_OPEN)


static func context_to_features(context: Dictionary) -> Dictionary:
	var actor := context.get("actor", [0.5, 0.5]) as Array
	var ball := context.get("ball", [0.5, 0.5]) as Array
	var goal := context.get("goal", [1.0, 0.5]) as Array
	var actor_x := float(actor[0]) if actor.size() >= 1 else 0.5
	var actor_y := float(actor[1]) if actor.size() >= 2 else 0.5
	var ball_x := float(ball[0]) if ball.size() >= 1 else 0.5
	var ball_y := float(ball[1]) if ball.size() >= 2 else 0.5
	var goal_x := float(goal[0]) if goal.size() >= 1 else 1.0
	var possession := str(context.get("possession", "none"))
	var dx := ball_x - actor_x
	var dy := ball_y - actor_y
	var ball_distance := clampf(Vector2(dx, dy).length(), 0.0, 1.5)
	var goal_distance := clampf(absf(goal_x - ball_x), 0.0, 1.5)
	return {
		"bias": 1.0,
		"possession_self": 1.0 if possession == "self" else 0.0,
		"possession_team": 1.0 if possession == "team" else 0.0,
		"possession_opponent": 1.0 if possession in ["opponent", "enemy"] else 0.0,
		"possession_loose": 1.0 if possession not in ["self", "team", "opponent", "enemy"] else 0.0,
		"player_x": actor_x,
		"player_y": actor_y,
		"ball_x": ball_x,
		"ball_y": ball_y,
		"ball_ahead": clampf(dx, -1.0, 1.0),
		"ball_distance": ball_distance,
		"goal_distance": goal_distance,
		"goal_closeness": 1.0 - clampf(goal_distance, 0.0, 1.0),
		"opponent_pressure": 1.0 if bool(context.get("under_pressure", false)) else 0.0,
		"ability_ready": 1.0 if bool(context.get("cooldown_ready", true)) else 0.0
	}
