extends Camera2D


@export var match_manager: FootballMatchManager
@export var players_parent: Node2D
@export var ball: FootballBall

@export_category("Large Team Camera")
@export var large_team_zoom: Vector2 = Vector2(0.18, 0.18)
@export var large_team_min_zoom: Vector2 = Vector2(0.11, 0.11)
@export_range(1.0, 20.0, 0.1)
var large_team_follow_speed: float = 8.5
# Kept as an exported compatibility setting for older scenes/tests. Large-team
# gameplay no longer uses a positional dead zone; the player is the camera
# anchor and ball separation is handled primarily through dynamic zoom.
@export var large_team_dead_zone: Vector2 = Vector2.ZERO
@export_range(0.0, 0.5, 0.01)
var large_team_look_ahead_seconds: float = 0.01
@export var large_team_max_look_ahead: Vector2 = Vector2(60.0, 40.0)
@export_range(0.0, 0.15, 0.005)
var large_team_ball_follow_weight: float = 0.0
@export_range(0.0, 2000.0, 10.0)
var large_team_ball_follow_start_distance: float = 300.0
@export var large_team_max_ball_bias: Vector2 = Vector2.ZERO
@export_range(1.0, 20.0, 0.1)
var large_team_ball_follow_speed: float = 4.8
@export_range(0.2, 20.0, 0.1)
var large_team_zoom_follow_speed: float = 2.2
@export_range(0.2, 20.0, 0.1)
var large_team_zoom_in_follow_speed: float = 0.7
@export_range(0.0, 0.03, 0.001)
var large_team_zoom_deadband: float = 0.006
@export_range(0.55, 0.95, 0.01)
var large_team_ball_safe_screen_fraction: float = 0.86
# Fallback bounds. Runtime goal/ball geometry expands these so the camera can
# travel behind both goals rather than stopping at the goal line.
@export var large_team_arena_bounds: Rect2 = Rect2(
	Vector2(-3000.0, -900.0),
	Vector2(14100.0, 6800.0)
)
@export_range(0.0, 5000.0, 50.0)
var large_team_behind_goal_camera_margin: float = 3000.0
@export_range(0.0, 3000.0, 50.0)
var large_team_sideline_camera_margin: float = 1500.0
@export_range(24.0, 120.0, 1.0)
var ball_indicator_screen_margin: float = 58.0
# The ball marker should only appear once the ball is truly off camera (with a
# tiny safety buffer outside the screen), not while it is still visible near an
# edge.
@export_range(0.0, 48.0, 1.0)
var ball_indicator_activation_padding: float = 10.0
@export_range(18.0, 90.0, 1.0)
var player_indicator_screen_margin: float = 34.0
@export_range(8.0, 30.0, 1.0)
var player_indicator_size: float = 13.0

@export_category("Penalty Camera")
@export var penalty_camera_zoom: Vector2 = Vector2(0.34, 0.34)
@export_range(1.0, 30.0, 0.1)
var penalty_camera_follow_speed: float = 9.5

@export_category("Goal Focus")
@export var goal_focus_zoom: Vector2 = Vector2(0.24, 0.24)
@export var goal_focus_move_seconds: float = 0.22
@export var goal_focus_hold_seconds: float = 6.0
@export var goal_focus_return_seconds: float = 0.35
@export_range(1.0, 30.0, 0.1)
var goal_focus_follow_speed: float = 12.0

@export_category("Impact Camera")
@export_range(0.0, 180.0, 1.0)
var maximum_shake_offset: float = 43.0
@export_range(0.0, 4.0, 0.1)
var maximum_shake_rotation_degrees: float = 0.0
@export_range(0.5, 12.0, 0.1)
var shake_decay_per_second: float = 4.8
@export_range(5.0, 80.0, 1.0)
var shake_frequency: float = 36.0
@export_range(0.0, 1.0, 0.01)
var goal_impact_strength: float = 0.84
@export_range(0.0, 1.0, 0.01)
var high_energy_kick_threshold: float = 0.80
@export_range(0.0, 1.0, 0.01)
var high_energy_kick_max_trauma: float = 0.24
@export var high_energy_collision_speed: float = 5200.0
@export_range(0.0, 1.0, 0.01)
var high_energy_collision_max_trauma: float = 0.29
@export var high_energy_player_contact_speed: float = 4700.0
@export_range(0.0, 1.0, 0.01)
var high_energy_player_contact_max_trauma: float = 0.24

@export_category("Power Strike Camera")
@export_range(0.0, 1.0, 0.01)
var power_strike_shake_strength: float = 0.40
@export_range(0.0, 0.12, 0.005)
var power_strike_zoom_punch: float = 0.040

@export_category("Goal Camera Punch")
@export_range(0.0, 0.20, 0.005)
var goal_zoom_punch: float = 0.090
@export_range(1.0, 30.0, 0.5)
var zoom_punch_recovery_speed: float = 11.0

var _default_position: Vector2
var _default_zoom: Vector2
var _default_offset: Vector2
var _composition_offset: Vector2
var _composition_zoom: Vector2
var _focus_generation: int = 0
var _camera_tween: Tween
var _focused_scorer: FootballPlayer
var _following_scorer: bool = false
var _goal_replay_active: bool = false
var _trauma: float = 0.0
var _shake_clock: float = 0.0
var _zoom_punch: float = 0.0
var _large_team_mode: bool = false
var _large_team_local_player: FootballPlayer
var _large_team_initial_center_pending: bool = false
var _large_team_focus_anchor: Vector2 = Vector2.ZERO
var _large_team_camera_anchor: Vector2 = Vector2.ZERO
var _large_team_focus_anchor_valid: bool = false
var _large_team_ball_bias: Vector2 = Vector2.ZERO
# Server/solo players are rendered through Godot's 60 Hz physics interpolation,
# while this camera runs every display frame. Sampling the raw RigidBody2D
# position directly would therefore make the camera chase a 60 Hz stair-step
# target even on a 144/240 Hz display. Keep the last two authoritative samples
# so the camera follows the same in-between presentation position as the player.
var _large_team_sample_player_instance_id: int = 0
var _large_team_sample_physics_frame: int = -1
var _large_team_previous_player_position: Vector2 = Vector2.ZERO
var _large_team_current_player_position: Vector2 = Vector2.ZERO
var _large_team_player_sample_valid: bool = false
var _penalty_camera_was_active: bool = false
var _ball_indicator_layer: CanvasLayer
var _ball_indicator_root: Node2D
var _ball_indicator_arrow: Polygon2D
var _player_indicator_layer: CanvasLayer
var _player_indicators: Dictionary = {}


func _ready() -> void:
	_default_position = position
	_default_zoom = zoom
	_default_offset = offset
	_composition_offset = offset
	_composition_zoom = zoom

	if match_manager == null or players_parent == null:
		push_error("Match camera references are incomplete.")
		return

	if ball == null:
		ball = get_parent().get_node_or_null("Ball") as FootballBall

	match_manager.roster_changed.connect(_on_roster_changed)
	match_manager.match_started.connect(_on_match_started)
	match_manager.goal_focus_requested.connect(_on_goal_focus_requested)
	match_manager.goal_replay_state_changed.connect(
		_on_goal_replay_state_changed
	)
	match_manager.match_cancelled.connect(_restore_immediately)
	match_manager.match_ended.connect(
		func(_winning_team: StringName) -> void:
			_restore_immediately()
	)
	_build_ball_offscreen_indicator()
	_build_player_offscreen_indicator_layer()
	_refresh_large_team_mode_from_players.call_deferred()


func _process(delta: float) -> void:
	var penalty_camera_active := _is_penalty_camera_active()
	if not _goal_replay_active and not _following_scorer:
		if penalty_camera_active:
			_update_penalty_camera(delta)
		else:
			if _penalty_camera_was_active and _large_team_mode:
				_large_team_initial_center_pending = true
			_update_large_team_camera(delta)
	_penalty_camera_was_active = penalty_camera_active
	_update_zoom_punch(delta)
	_update_camera_shake(delta)
	_update_ball_offscreen_indicator()
	_update_player_offscreen_indicators()

	if not _following_scorer:
		return
	if not is_instance_valid(_focused_scorer):
		_following_scorer = false
		_focused_scorer = null
		return

	var follow_weight := 1.0 - exp(
		-maxf(1.0, goal_focus_follow_speed) * delta
	)
	global_position = global_position.lerp(
		_focused_scorer.global_position,
		follow_weight
	)


func _on_roster_changed(red_count: int, blue_count: int) -> void:
	var was_large_team_mode := _large_team_mode
	_large_team_mode = mini(red_count, blue_count) >= 4
	_large_team_local_player = _find_local_active_player()
	if _large_team_mode and not was_large_team_mode:
		_large_team_initial_center_pending = true
		_large_team_focus_anchor_valid = false
	elif not _large_team_mode:
		_large_team_initial_center_pending = false
		_large_team_focus_anchor_valid = false
		_large_team_ball_bias = Vector2.ZERO


func _on_match_started() -> void:
	if not _large_team_mode:
		return
	_large_team_local_player = _find_local_active_player()
	_large_team_initial_center_pending = true
	_large_team_focus_anchor_valid = false
	_large_team_ball_bias = Vector2.ZERO


func _refresh_large_team_mode_from_players() -> void:
	if players_parent == null:
		return
	var red_count := 0
	var blue_count := 0
	for child: Node in players_parent.get_children():
		var player := child as FootballPlayer
		if player == null or player.training_dummy:
			continue
		if player.team == FootballMatchManager.TEAM_RED:
			red_count += 1
		elif player.team == FootballMatchManager.TEAM_BLUE:
			blue_count += 1
	_on_roster_changed(red_count, blue_count)


func _find_local_active_player() -> FootballPlayer:
	if players_parent == null:
		return null
	var local_peer_id := multiplayer.get_unique_id()
	var named_player := players_parent.get_node_or_null(str(local_peer_id)) as FootballPlayer
	if (
		named_player != null
		and named_player.team in [FootballMatchManager.TEAM_RED, FootballMatchManager.TEAM_BLUE]
	):
		return named_player
	for child: Node in players_parent.get_children():
		var player := child as FootballPlayer
		if (
			player != null
			and player.owner_peer_id == local_peer_id
			and player.team in [FootballMatchManager.TEAM_RED, FootballMatchManager.TEAM_BLUE]
		):
			return player
	return null


func _is_penalty_camera_active() -> bool:
	return (
		match_manager != null
		and match_manager.game_has_started
		and match_manager.penalty_shootout_active
	)


func _update_penalty_camera(delta: float) -> void:
	var target_position := _get_penalty_camera_target()
	var follow_weight := 1.0 - exp(
		-maxf(1.0, penalty_camera_follow_speed) * delta
	)
	global_position = global_position.lerp(target_position, follow_weight)
	_composition_zoom = _composition_zoom.lerp(
		penalty_camera_zoom,
		follow_weight
	)
	_composition_offset = _composition_offset.lerp(
		_default_offset,
		follow_weight
	)


func _get_penalty_camera_target() -> Vector2:
	var playfield := get_parent()
	if playfield == null or match_manager == null:
		return _default_position

	var attacking_team := match_manager.penalty_turn
	var target_goal_name := (
		"Goal_Red"
		if attacking_team == FootballMatchManager.TEAM_BLUE
		else "Goal_Blue"
	)
	var target_goal := playfield.get_node_or_null(target_goal_name) as FootballGoal
	if target_goal == null:
		return ball.global_position if is_instance_valid(ball) else _default_position

	var mouth_range := target_goal.get_mouth_y_range()
	var center_y := (mouth_range.x + mouth_range.y) * 0.5
	var goal_x := target_goal.get_goal_plane_x()
	var attack_direction := (
		1.0
		if attacking_team == FootballMatchManager.TEAM_BLUE
		else -1.0
	)
	var penalty_spot_x := goal_x - attack_direction * maxf(
		300.0,
		match_manager.penalty_spot_distance_from_goal
	)
	var kicker_distance := (
		match_manager.ranked_penalty_kicker_distance_from_ball
		if match_manager.ranked_mode
		else match_manager.penalty_kicker_distance_from_ball
	)
	var kicker_start_x := penalty_spot_x - attack_direction * maxf(
		120.0,
		kicker_distance
	)
	# Frame the complete penalty action: run-up, spot, goalkeeper and goal.
	return Vector2((kicker_start_x + goal_x) * 0.5, center_y)


func _update_large_team_camera(delta: float) -> void:
	if not _large_team_mode:
		_large_team_ball_bias = Vector2.ZERO
		var return_weight := 1.0 - exp(-maxf(1.0, large_team_follow_speed) * delta)
		global_position = global_position.lerp(_default_position, return_weight)
		_composition_zoom = _composition_zoom.lerp(_default_zoom, return_weight)
		return

	if not is_instance_valid(_large_team_local_player):
		_large_team_local_player = _find_local_active_player()
	if not is_instance_valid(_large_team_local_player):
		_large_team_focus_anchor_valid = false
		_large_team_ball_bias = Vector2.ZERO
		# Spectators keep the normal complete-field framing.
		var spectator_weight := 1.0 - exp(-maxf(1.0, large_team_follow_speed) * delta)
		global_position = global_position.lerp(_default_position, spectator_weight)
		_composition_zoom = _composition_zoom.lerp(_default_zoom, spectator_weight)
		return

	if _large_team_initial_center_pending:
		_center_large_team_camera_on_local_player()
		return

	var player_position := _get_large_team_presented_player_position()
	var target_zoom := _get_large_team_dynamic_zoom(player_position)
	var current_zoom_scalar := minf(_composition_zoom.x, _composition_zoom.y)
	var target_zoom_scalar := minf(target_zoom.x, target_zoom.y)
	if absf(target_zoom_scalar - current_zoom_scalar) <= maxf(0.0, large_team_zoom_deadband):
		target_zoom = _composition_zoom
		target_zoom_scalar = current_zoom_scalar
	# Pull back reasonably quickly when the ball is escaping the frame, but
	# return toward the closer base view much more slowly. This avoids the
	# constant zoom-in/zoom-out breathing that can feel uncomfortable.
	var zoom_speed := (
		large_team_zoom_follow_speed
		if target_zoom_scalar < current_zoom_scalar
		else large_team_zoom_in_follow_speed
	)
	var zoom_weight := 1.0 - exp(-maxf(0.2, zoom_speed) * delta)
	_composition_zoom = _composition_zoom.lerp(target_zoom, zoom_weight)

	# Keep the controlled player almost fully centered. A tiny velocity lead keeps
	# movement from feeling visually backwards, but the old large positional
	# dead-zone is intentionally gone.
	var player_velocity := _large_team_local_player.linear_velocity
	if not multiplayer.is_server():
		player_velocity = _large_team_local_player.network_linear_velocity
	var look_ahead := player_velocity * maxf(0.0, large_team_look_ahead_seconds)
	look_ahead.x = clampf(
		look_ahead.x,
		-large_team_max_look_ahead.x,
		large_team_max_look_ahead.x
	)
	look_ahead.y = clampf(
		look_ahead.y,
		-large_team_max_look_ahead.y,
		large_team_max_look_ahead.y
	)

	# The ball influences framing only slightly. Its main influence is dynamic
	# zoom below, which preserves the player's near-center composition instead of
	# dragging the camera halfway toward a distant ball.
	_update_large_team_ball_bias(delta, player_position)
	var desired_position := player_position + look_ahead + _large_team_ball_bias
	var camera_target := _clamp_large_team_camera_position(
		desired_position,
		target_zoom
	)
	var follow_weight := 1.0 - exp(-maxf(1.0, large_team_follow_speed) * delta)
	global_position = global_position.lerp(camera_target, follow_weight)

	# Keep the old anchor members coherent for replay/reset compatibility, even
	# though they no longer drive normal large-team camera movement.
	_large_team_focus_anchor = player_position
	_large_team_camera_anchor = camera_target
	_large_team_focus_anchor_valid = true


func _get_large_team_presented_player_position() -> Vector2:
	if not is_instance_valid(_large_team_local_player):
		_large_team_player_sample_valid = false
		return _default_position

	var raw_position := _large_team_local_player.global_position
	# Client replicas already run their existing network interpolation every
	# rendered frame, so applying a second interpolation layer here would lag them.
	if not multiplayer.is_server():
		_large_team_player_sample_valid = false
		return raw_position

	var player_instance_id := _large_team_local_player.get_instance_id()
	var physics_frame := Engine.get_physics_frames()
	if (
		not _large_team_player_sample_valid
		or player_instance_id != _large_team_sample_player_instance_id
	):
		_large_team_sample_player_instance_id = player_instance_id
		_large_team_sample_physics_frame = physics_frame
		_large_team_previous_player_position = raw_position
		_large_team_current_player_position = raw_position
		_large_team_player_sample_valid = true
		return raw_position

	if physics_frame != _large_team_sample_physics_frame:
		var frame_gap := physics_frame - _large_team_sample_physics_frame
		_large_team_sample_physics_frame = physics_frame
		# A normal render frame sees exactly one new physics sample. If rendering
		# fell behind by multiple physics ticks, do not interpolate across stale
		# history because that would add visible catch-up latency.
		if frame_gap == 1:
			_large_team_previous_player_position = (
				_large_team_current_player_position
			)
		else:
			_large_team_previous_player_position = raw_position
		_large_team_current_player_position = raw_position

	var interpolation_fraction := clampf(
		Engine.get_physics_interpolation_fraction(),
		0.0,
		1.0
	)
	return _large_team_previous_player_position.lerp(
		_large_team_current_player_position,
		interpolation_fraction
	)


func _get_large_team_dynamic_zoom(player_position: Vector2) -> Vector2:
	var base_scalar := minf(large_team_zoom.x, large_team_zoom.y)
	var minimum_scalar := minf(large_team_min_zoom.x, large_team_min_zoom.y)
	base_scalar = maxf(0.01, base_scalar)
	minimum_scalar = clampf(minimum_scalar, 0.01, base_scalar)

	if (
		not is_instance_valid(ball)
		or not ball.visible
		or match_manager == null
		or not match_manager.game_has_started
		or match_manager.penalty_shootout_active
	):
		return Vector2.ONE * base_scalar

	var viewport_size := get_viewport_rect().size
	if viewport_size.x <= 1.0 or viewport_size.y <= 1.0:
		return Vector2.ONE * base_scalar

	var separation := (ball.global_position - player_position).abs()
	var safe_fraction := clampf(large_team_ball_safe_screen_fraction, 0.55, 0.95)
	var safe_half_pixels := viewport_size * (0.5 * safe_fraction)

	# Camera2D zoom maps world separation to screen separation by multiplication.
	# Choose the largest zoom that still keeps the ball inside the safe area,
	# then clamp how far the view may pull back.
	var fit_x := base_scalar
	var fit_y := base_scalar
	if separation.x > 1.0:
		fit_x = safe_half_pixels.x / separation.x
	if separation.y > 1.0:
		fit_y = safe_half_pixels.y / separation.y
	var fit_scalar := minf(base_scalar, minf(fit_x, fit_y))
	return Vector2.ONE * clampf(fit_scalar, minimum_scalar, base_scalar)


func _update_large_team_ball_bias(delta: float, player_position: Vector2) -> void:
	var target_bias := Vector2.ZERO
	if (
		is_instance_valid(ball)
		and ball.visible
		and match_manager != null
		and match_manager.game_has_started
		and not match_manager.penalty_shootout_active
	):
		var to_ball := ball.global_position - player_position
		var distance_to_ball := to_ball.length()
		var start_distance := maxf(0.0, large_team_ball_follow_start_distance)
		if distance_to_ball > start_distance and distance_to_ball > 0.001:
			var excess_distance := distance_to_ball - start_distance
			target_bias = (
				to_ball / distance_to_ball
				* excess_distance
				* clampf(large_team_ball_follow_weight, 0.0, 0.5)
			)
			target_bias.x = clampf(
				target_bias.x,
				-large_team_max_ball_bias.x,
				large_team_max_ball_bias.x
			)
			target_bias.y = clampf(
				target_bias.y,
				-large_team_max_ball_bias.y,
				large_team_max_ball_bias.y
			)

	var ball_follow_weight := 1.0 - exp(
		-maxf(1.0, large_team_ball_follow_speed) * delta
	)
	_large_team_ball_bias = _large_team_ball_bias.lerp(
		target_bias,
		ball_follow_weight
	)


func _center_large_team_camera_on_local_player() -> void:
	if not _large_team_mode or not is_instance_valid(_large_team_local_player):
		return
	var player_position := _get_large_team_presented_player_position()
	var centered_position := _clamp_large_team_camera_position(
		player_position,
		large_team_zoom
	)
	global_position = centered_position
	_large_team_focus_anchor = player_position
	_large_team_camera_anchor = centered_position
	_large_team_focus_anchor_valid = true
	_large_team_ball_bias = Vector2.ZERO
	_composition_zoom = large_team_zoom
	zoom = large_team_zoom
	_composition_offset = _default_offset
	offset = _default_offset
	_large_team_initial_center_pending = false
	reset_physics_interpolation()


func _build_ball_offscreen_indicator() -> void:
	if _ball_indicator_layer != null:
		return
	_ball_indicator_layer = CanvasLayer.new()
	_ball_indicator_layer.name = "BallOffscreenIndicatorLayer"
	_ball_indicator_layer.layer = 70
	add_child(_ball_indicator_layer)

	_ball_indicator_root = Node2D.new()
	_ball_indicator_root.name = "BallOffscreenIndicator"
	_ball_indicator_root.visible = false
	_ball_indicator_layer.add_child(_ball_indicator_root)

	var backdrop := Polygon2D.new()
	backdrop.name = "Backdrop"
	backdrop.polygon = _make_indicator_circle(22.0, 24)
	backdrop.color = Color(0.015, 0.025, 0.04, 0.88)
	_ball_indicator_root.add_child(backdrop)

	var ball_dot := Polygon2D.new()
	ball_dot.name = "BallDot"
	ball_dot.polygon = _make_indicator_circle(9.0, 20)
	ball_dot.color = Color(0.96, 0.98, 1.0, 1.0)
	_ball_indicator_root.add_child(ball_dot)

	_ball_indicator_arrow = Polygon2D.new()
	_ball_indicator_arrow.name = "DirectionArrow"
	_ball_indicator_arrow.polygon = PackedVector2Array([
		Vector2(31.0, 0.0),
		Vector2(15.0, -9.0),
		Vector2(18.0, 0.0),
		Vector2(15.0, 9.0),
	])
	_ball_indicator_arrow.color = Color(1.0, 0.78, 0.24, 1.0)
	_ball_indicator_root.add_child(_ball_indicator_arrow)


func _make_indicator_circle(radius: float, point_count: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	var safe_count := maxi(8, point_count)
	for point_index in range(safe_count):
		points.append(
			Vector2.from_angle(TAU * float(point_index) / float(safe_count))
			* radius
		)
	return points


func _update_ball_offscreen_indicator() -> void:
	if _ball_indicator_root == null:
		return
	if (
		not _large_team_mode
		or not match_manager.game_has_started
		or match_manager.penalty_shootout_active
		or _goal_replay_active
		or _following_scorer
		or not is_instance_valid(ball)
		or not ball.visible
	):
		_ball_indicator_root.visible = false
		return

	var viewport_size := get_viewport_rect().size
	if viewport_size.x <= 1.0 or viewport_size.y <= 1.0:
		_ball_indicator_root.visible = false
		return

	var ball_screen_position := (
		get_viewport().get_canvas_transform() * ball.global_position
	)
	var margin := clampf(
		ball_indicator_screen_margin,
		24.0,
		minf(viewport_size.x, viewport_size.y) * 0.22
	)
	var activation_padding := clampf(ball_indicator_activation_padding, 0.0, 48.0)
	var visible_rect := Rect2(Vector2.ZERO, viewport_size).grow(activation_padding)
	if visible_rect.has_point(ball_screen_position):
		_ball_indicator_root.visible = false
		return

	var screen_center := viewport_size * 0.5
	var to_ball := ball_screen_position - screen_center
	if to_ball.length_squared() <= 0.001:
		_ball_indicator_root.visible = false
		return
	var direction := to_ball.normalized()
	var half_safe_size := viewport_size * 0.5 - Vector2.ONE * margin
	var x_distance := INF if absf(direction.x) < 0.0001 else half_safe_size.x / absf(direction.x)
	var y_distance := INF if absf(direction.y) < 0.0001 else half_safe_size.y / absf(direction.y)
	var edge_distance := minf(x_distance, y_distance)
	_ball_indicator_root.position = screen_center + direction * edge_distance
	_ball_indicator_arrow.rotation = direction.angle()
	_ball_indicator_root.visible = true


func _build_player_offscreen_indicator_layer() -> void:
	if _player_indicator_layer != null:
		return
	_player_indicator_layer = CanvasLayer.new()
	_player_indicator_layer.name = "PlayerOffscreenIndicatorLayer"
	# Keep player markers just behind the ball marker if they meet at an edge.
	_player_indicator_layer.layer = 69
	add_child(_player_indicator_layer)


func _get_or_create_player_indicator(player: FootballPlayer) -> Dictionary:
	var indicator_id := player.get_instance_id()
	if _player_indicators.has(indicator_id):
		return _player_indicators[indicator_id] as Dictionary

	var root := Node2D.new()
	root.name = "PlayerIndicator_%d" % indicator_id
	root.visible = false
	_player_indicator_layer.add_child(root)

	var outer := Polygon2D.new()
	outer.name = "AllianceOutline"
	root.add_child(outer)

	var dark_center := Polygon2D.new()
	dark_center.name = "DarkCenter"
	root.add_child(dark_center)

	var color_dot := Polygon2D.new()
	color_dot.name = "PlayerColor"
	color_dot.polygon = _make_indicator_circle(player_indicator_size * 0.46, 16)
	root.add_child(color_dot)

	var arrow := Polygon2D.new()
	arrow.name = "DirectionArrow"
	arrow.polygon = PackedVector2Array([
		Vector2(player_indicator_size + 12.0, 0.0),
		Vector2(player_indicator_size + 4.0, -4.5),
		Vector2(player_indicator_size + 4.0, 4.5),
	])
	root.add_child(arrow)

	var indicator := {
		"root": root,
		"outer": outer,
		"dark_center": dark_center,
		"color_dot": color_dot,
		"arrow": arrow,
		"is_teammate": null,
	}
	_player_indicators[indicator_id] = indicator
	return indicator


func _set_player_indicator_alliance_style(
	indicator: Dictionary,
	is_teammate: bool,
	player_team: StringName,
	player_color: Color
) -> void:
	var outer := indicator.get("outer") as Polygon2D
	var dark_center := indicator.get("dark_center") as Polygon2D
	var color_dot := indicator.get("color_dot") as Polygon2D
	var arrow := indicator.get("arrow") as Polygon2D
	if outer == null or dark_center == null or color_dot == null or arrow == null:
		return

	var size := maxf(8.0, player_indicator_size)
	# Color communicates the player's actual team, while shape still communicates
	# ally/enemy relative to the local player. This avoids a red teammate being
	# shown with a blue marker (or a blue opponent with a red one).
	var team_color := (
		Color(0.16, 0.52, 1.0, 0.96)
		if player_team == FootballMatchManager.TEAM_BLUE
		else Color(1.0, 0.22, 0.30, 0.96)
	)
	# Geometry is static once alliance is known. Do not rebuild polygon arrays
	# every rendered frame in 6v6 just to update an edge marker's color/position.
	var previous_alliance: Variant = indicator.get("is_teammate", null)
	if previous_alliance == null or bool(previous_alliance) != is_teammate:
		if is_teammate:
			outer.polygon = _make_indicator_circle(size, 18)
			dark_center.polygon = _make_indicator_circle(size * 0.72, 18)
		else:
			outer.polygon = PackedVector2Array([
				Vector2(0.0, -size),
				Vector2(size, 0.0),
				Vector2(0.0, size),
				Vector2(-size, 0.0),
			])
			dark_center.polygon = PackedVector2Array([
				Vector2(0.0, -size * 0.70),
				Vector2(size * 0.70, 0.0),
				Vector2(0.0, size * 0.70),
				Vector2(-size * 0.70, 0.0),
			])
		indicator["is_teammate"] = is_teammate
	outer.color = team_color
	dark_center.color = Color(0.012, 0.020, 0.032, 0.92)
	color_dot.color = Color(player_color.r, player_color.g, player_color.b, 1.0)
	arrow.color = team_color


func _update_player_offscreen_indicators() -> void:
	if _player_indicator_layer == null:
		return
	var can_show := (
		_large_team_mode
		and match_manager != null
		and match_manager.game_has_started
		and not match_manager.penalty_shootout_active
		and not _goal_replay_active
		and not _following_scorer
	)
	if not can_show:
		_hide_all_player_offscreen_indicators()
		return
	if not is_instance_valid(_large_team_local_player):
		_large_team_local_player = _find_local_active_player()
	if not is_instance_valid(_large_team_local_player) or players_parent == null:
		_hide_all_player_offscreen_indicators()
		return

	var viewport_size := get_viewport_rect().size
	if viewport_size.x <= 1.0 or viewport_size.y <= 1.0:
		_hide_all_player_offscreen_indicators()
		return
	var margin := clampf(
		player_indicator_screen_margin,
		18.0,
		minf(viewport_size.x, viewport_size.y) * 0.18
	)
	var visible_padding := maxf(18.0, player_indicator_size + 6.0)
	var visible_rect := Rect2(
		Vector2(visible_padding, visible_padding),
		viewport_size - Vector2.ONE * visible_padding * 2.0
	)
	var screen_center := viewport_size * 0.5
	var active_indicator_ids: Dictionary = {}

	for child: Node in players_parent.get_children():
		var player := child as FootballPlayer
		if (
			player == null
			or player == _large_team_local_player
			or player.training_dummy
			or not player.visible
			or player.team not in [FootballMatchManager.TEAM_RED, FootballMatchManager.TEAM_BLUE]
		):
			continue
		var indicator_id := player.get_instance_id()
		active_indicator_ids[indicator_id] = true
		var indicator := _get_or_create_player_indicator(player)
		var root := indicator.get("root") as Node2D
		var arrow := indicator.get("arrow") as Polygon2D
		if root == null or arrow == null:
			continue

		var player_screen_position := get_viewport().get_canvas_transform() * player.global_position
		if visible_rect.has_point(player_screen_position):
			root.visible = false
			continue
		var to_player := player_screen_position - screen_center
		if to_player.length_squared() <= 0.001:
			root.visible = false
			continue
		var direction := to_player.normalized()
		var half_safe_size := viewport_size * 0.5 - Vector2.ONE * margin
		var x_distance := INF if absf(direction.x) < 0.0001 else half_safe_size.x / absf(direction.x)
		var y_distance := INF if absf(direction.y) < 0.0001 else half_safe_size.y / absf(direction.y)
		var edge_distance := minf(x_distance, y_distance)
		root.position = screen_center + direction * edge_distance
		arrow.rotation = direction.angle()

		var is_teammate := player.team == _large_team_local_player.team
		var player_color := (
			player.get_soft_glow_color()
			if player.has_method("get_soft_glow_color")
			else (Color(0.18, 0.58, 1.0) if is_teammate else Color(1.0, 0.24, 0.30))
		)
		_set_player_indicator_alliance_style(
			indicator,
			is_teammate,
			player.team,
			player_color
		)
		root.visible = true

	# Roster changes can free players while their CanvasLayer marker survives.
	# Remove those stale markers instead of letting hidden nodes accumulate.
	for indicator_id: Variant in _player_indicators.keys():
		if active_indicator_ids.has(indicator_id):
			continue
		var stale := _player_indicators[indicator_id] as Dictionary
		var stale_root := stale.get("root") as Node2D
		if stale_root != null and is_instance_valid(stale_root):
			stale_root.queue_free()
		_player_indicators.erase(indicator_id)


func _hide_all_player_offscreen_indicators() -> void:
	for indicator_value: Variant in _player_indicators.values():
		var indicator := indicator_value as Dictionary
		var root := indicator.get("root") as Node2D
		if root != null and is_instance_valid(root):
			root.visible = false


func _get_large_team_camera_bounds() -> Rect2:
	var bounds := large_team_arena_bounds

	# Build the horizontal range from the actual goals when possible. The old
	# fixed range ended roughly at the goal lines, which prevented a player near
	# goal from ever being centered. Give the camera real room behind each goal.
	if (
		match_manager != null
		and is_instance_valid(match_manager.red_goal)
		and is_instance_valid(match_manager.blue_goal)
	):
		var red_goal_x := match_manager.red_goal.get_goal_plane_x()
		var blue_goal_x := match_manager.blue_goal.get_goal_plane_x()
		var left_goal_x := minf(red_goal_x, blue_goal_x)
		var right_goal_x := maxf(red_goal_x, blue_goal_x)
		var behind_goal := maxf(0.0, large_team_behind_goal_camera_margin)
		bounds.position.x = left_goal_x - behind_goal
		bounds.size.x = (right_goal_x - left_goal_x) + behind_goal * 2.0

	# Do the same vertically from the ball's real playable rectangle so keeping
	# the player centered near a touchline is possible without changing physics.
	if is_instance_valid(ball):
		var playable := ball.arena_playable_bounds.abs()
		var sideline_margin := maxf(0.0, large_team_sideline_camera_margin)
		bounds.position.y = playable.position.y - sideline_margin
		bounds.size.y = playable.size.y + sideline_margin * 2.0

	return bounds


func _clamp_large_team_camera_position(
	desired_position: Vector2,
	_target_zoom: Vector2
) -> Vector2:
	var camera_bounds := _get_large_team_camera_bounds()
	var bounds_min := camera_bounds.position
	var bounds_max := camera_bounds.end

	# These are camera-center limits, not viewport-edge limits. Large-team maps
	# have a full-screen background behind the pitch, so forcing every zoom level
	# to keep the entire viewport inside the field bounds only pushes the player
	# away from screen center near a goal. Allow the view itself to extend beyond
	# the pitch while keeping the camera center within a sane behind-goal range.
	return Vector2(
		clampf(desired_position.x, bounds_min.x, bounds_max.x),
		clampf(desired_position.y, bounds_min.y, bounds_max.y)
	)


func add_ball_impact_shake(strength: float) -> void:
	if _goal_replay_active:
		return
	var safe_strength := clampf(strength, 0.0, 1.0)
	var threshold := clampf(high_energy_kick_threshold, 0.0, 0.99)
	if safe_strength < threshold:
		return
	var normalized := clampf(
		(safe_strength - threshold) / maxf(0.01, 1.0 - threshold),
		0.0,
		1.0
	)
	var trauma := lerpf(
		0.08,
		clampf(high_energy_kick_max_trauma, 0.0, 1.0),
		pow(normalized, 0.85)
	)
	_trauma = maxf(_trauma, trauma)


func add_collision_impact_shake(
	speed: float,
	collision_kind: StringName = &"wall"
) -> void:
	if _goal_replay_active:
		return
	var threshold := maxf(1.0, high_energy_collision_speed)
	if collision_kind == &"post":
		threshold *= 0.90
	if speed < threshold:
		return
	var normalized := clampf(
		(speed - threshold) / maxf(1.0, 12000.0 - threshold),
		0.0,
		1.0
	)
	var trauma := lerpf(
		0.10,
		clampf(high_energy_collision_max_trauma, 0.0, 1.0),
		pow(normalized, 0.75)
	)
	if collision_kind == &"post":
		trauma = minf(1.0, trauma * 1.12)
	_trauma = maxf(_trauma, trauma)


func add_player_contact_shake(
	speed: float,
	contact_kind: StringName = &"interception"
) -> void:
	if _goal_replay_active:
		return
	var threshold := maxf(1.0, high_energy_player_contact_speed)
	if speed < threshold:
		return
	var normalized := clampf(
		(speed - threshold) / maxf(1.0, 12000.0 - threshold),
		0.0,
		1.0
	)
	var trauma := lerpf(
		0.08,
		clampf(high_energy_player_contact_max_trauma, 0.0, 1.0),
		pow(normalized, 0.80)
	)
	if contact_kind == &"save":
		trauma = minf(1.0, trauma * 1.08)
	_trauma = maxf(_trauma, trauma)


func add_power_strike_emphasis(direction: Vector2) -> void:
	if _goal_replay_active:
		return
	_trauma = maxf(
		_trauma,
		clampf(power_strike_shake_strength, 0.0, 1.0)
	)
	_zoom_punch = maxf(
		_zoom_punch,
		clampf(power_strike_zoom_punch, 0.0, 0.20)
	)
	_play_power_strike_screen_flash()
	# Competitive framing stays fixed: Power Strike never pans the camera.
	var _unused_direction := direction


func _play_power_strike_screen_flash() -> void:
	var playfield := get_parent()
	if playfield == null:
		return
	var screen_fx := playfield.get_node_or_null("ScreenVisualFX")
	if screen_fx != null and screen_fx.has_method("play_power_strike_flash"):
		screen_fx.call("play_power_strike_flash")


func add_goal_impact_shake() -> void:
	_trauma = maxf(
		_trauma,
		clampf(goal_impact_strength, 0.0, 1.0)
	)
	# Goal explosions need the complete arena framing. Keep the impact shake,
	# but do not add a goal-specific zoom punch.


func _update_zoom_punch(delta: float) -> void:
	var weight := 1.0 - exp(
		-maxf(1.0, zoom_punch_recovery_speed) * delta
	)
	_zoom_punch = lerpf(_zoom_punch, 0.0, weight)
	if _zoom_punch < 0.0001:
		_zoom_punch = 0.0
	zoom = _composition_zoom * (1.0 + _zoom_punch)


func _update_camera_shake(delta: float) -> void:
	_shake_clock += delta * maxf(1.0, shake_frequency)
	var base_offset := _composition_offset
	if _trauma <= 0.0001:
		_trauma = 0.0
		offset = base_offset
		rotation = 0.0
		return

	_trauma = maxf(
		0.0,
		_trauma - delta * maxf(0.1, shake_decay_per_second)
	)
	var amount := _trauma * _trauma
	var x_noise := sin(_shake_clock * 1.17 + 0.4)
	var y_noise := cos(_shake_clock * 1.43 + 1.9)
	var rotation_noise := sin(_shake_clock * 1.83 + 2.7)

	offset = (
		base_offset
		+ Vector2(x_noise, y_noise)
		* maximum_shake_offset
		* amount
	)
	rotation = (
		deg_to_rad(maximum_shake_rotation_degrees)
		* rotation_noise
		* amount
	)


func _on_goal_focus_requested(scorer_peer_id: int) -> void:
	_focus_generation += 1
	# Keep the camera on the complete field during goals. Goal explosions and
	# their arena effects are designed for this framing, so scorer-follow and
	# goal zoom are intentionally disabled until a future cinematic pass.
	var _unused_scorer_peer_id := scorer_peer_id
	_restore_immediately()


func _on_goal_replay_state_changed(
	active: bool,
	_votes: int,
	_total_voters: int,
	_slow_motion: bool
) -> void:
	_goal_replay_active = active
	if active:
		_restore_immediately()
	elif _large_team_mode:
		_large_team_initial_center_pending = true
		_large_team_focus_anchor_valid = false
		_large_team_ball_bias = Vector2.ZERO


func _return_to_field(generation: int) -> void:
	if generation != _focus_generation:
		return

	_following_scorer = false
	_focused_scorer = null

	if _camera_tween != null:
		_camera_tween.kill()

	_camera_tween = create_tween().set_parallel(true)
	_camera_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_camera_tween.tween_property(
		self,
		"position",
		_default_position,
		maxf(0.05, goal_focus_return_seconds)
	)
	_camera_tween.tween_property(
		self,
		"_composition_zoom",
		_default_zoom,
		maxf(0.05, goal_focus_return_seconds)
	)
	_camera_tween.tween_property(
		self,
		"_composition_offset",
		_default_offset,
		maxf(0.05, goal_focus_return_seconds)
	)


func _restore_immediately() -> void:
	_focus_generation += 1
	_following_scorer = false
	_focused_scorer = null
	_trauma = 0.0
	_zoom_punch = 0.0

	if _camera_tween != null:
		_camera_tween.kill()

	position = _default_position
	_composition_zoom = _default_zoom
	zoom = _default_zoom
	_composition_offset = _default_offset
	offset = _default_offset
	rotation = 0.0
	_large_team_ball_bias = Vector2.ZERO
