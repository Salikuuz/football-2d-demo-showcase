class_name FootballAbilityPreviewStage
extends Control


const BLUE := Color(0.22, 0.62, 1.0)
const RED := Color(1.0, 0.25, 0.3)
const PURPLE := Color(0.74, 0.3, 1.0)
const MIRAGE_PURPLE := Color(0.72, 0.24, 1.0)
const GOLD := Color(1.0, 0.82, 0.2)
const CYAN := Color(0.22, 0.95, 1.0)

var ability_id: int = FootballPlayer.ABILITY_NONE
var _elapsed: float = 0.0


func _ready() -> void:
	custom_minimum_size = Vector2(306.0, 108.0)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)


func set_ability(value: int) -> void:
	ability_id = clampi(
		value,
		FootballPlayer.ABILITY_NONE,
		FootballPlayer.ABILITY_COUNT
	)
	_elapsed = 0.0
	queue_redraw()


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_elapsed += delta
	queue_redraw()


func _draw() -> void:
	_draw_pitch()
	var t := fmod(_elapsed, 5.6) / 5.6
	match ability_id:
		FootballPlayer.ABILITY_BURST_DRIBBLE:
			_draw_burst_dribble(t)
		FootballPlayer.ABILITY_QUICK_TRIGGER:
			_draw_curve_shot(t)
		FootballPlayer.ABILITY_POWER_STRIKE:
			_draw_power_strike(t)
		FootballPlayer.ABILITY_OVERDRIVE:
			_draw_overdrive(t)
		FootballPlayer.ABILITY_HEEL_TURN:
			_draw_phantom_heel(t)
		FootballPlayer.ABILITY_ENFORCER:
			_draw_enforcer(t)
		FootballPlayer.ABILITY_GOALKEEPER_REACH:
			_draw_goalkeeper_reach(t)
		FootballPlayer.ABILITY_TIME_SKIP_PASS:
			_draw_dead_zone_pass(t)
		FootballPlayer.ABILITY_DIRECT_FINISH:
			_draw_trap_or_volley(t)
		FootballPlayer.ABILITY_ELASTIC_STEP:
			_draw_elastic_step(t)
		FootballPlayer.ABILITY_META_VISION:
			_draw_meta_vision(t)
		FootballPlayer.ABILITY_COPYCAT:
			_draw_copycat(t)
		FootballPlayer.ABILITY_REFLEX_BLOCK:
			_draw_reflex_block(t)
		FootballPlayer.ABILITY_IRON_ANCHOR:
			_draw_iron_anchor(t)
		FootballPlayer.ABILITY_BLIND_SPOT:
			_draw_mirage_step(t)
		FootballPlayer.ABILITY_BOOGIE_WOOGIE:
			_draw_boogie_woogie(t)
		FootballPlayer.ABILITY_ECHO:
			_draw_echo(t)
		FootballPlayer.ABILITY_RETURN_TAG:
			_draw_return_tag(t)
		FootballPlayer.ABILITY_BREAKAWAY:
			_draw_breakaway(t)
		FootballPlayer.ABILITY_SNAPBACK:
			_draw_snapback(t)
		FootballPlayer.ABILITY_SIDE_SWIPE:
			_draw_side_swipe(t)
		FootballPlayer.ABILITY_NUTMEG:
			_draw_nutmeg(t)
		FootballPlayer.ABILITY_DECOY_RUN:
			_draw_decoy_run(t)
		_:
			_draw_no_ability(t)


func _draw_pitch() -> void:
	var field := Rect2(Vector2.ZERO, size)
	draw_rect(field, Color(0.055, 0.2, 0.15))
	for index in range(8):
		var stripe := Rect2(
			Vector2(size.x * float(index) / 8.0, 0.0),
			Vector2(size.x / 8.0 + 1.0, size.y)
		)
		var stripe_color := (
			Color(0.08, 0.3, 0.2)
			if index % 2 == 0
			else Color(0.065, 0.255, 0.18)
		)
		draw_rect(stripe, stripe_color)
	var line := Color(0.76, 0.92, 0.84, 0.56)
	draw_rect(Rect2(Vector2(7.0, 7.0), size - Vector2(14.0, 14.0)), line, false, 1.5)
	draw_line(_point(0.5, 0.04), _point(0.5, 0.96), line, 1.2)
	draw_arc(_point(0.5, 0.5), size.y * 0.16, 0.0, TAU, 48, line, 1.2)
	draw_rect(
		Rect2(_point(0.0, 0.29), Vector2(size.x * 0.12, size.y * 0.42)),
		line,
		false,
		1.2
	)
	draw_rect(
		Rect2(_point(0.88, 0.29), Vector2(size.x * 0.12, size.y * 0.42)),
		line,
		false,
		1.2
	)
	_draw_goal(false, Color(0.3, 0.7, 1.0, 0.7))
	_draw_goal(true, Color(1.0, 0.3, 0.34, 0.7))


func _draw_no_ability(t: float) -> void:
	var player := _lerp_path([
		_point(0.23, 0.68), _point(0.43, 0.56), _point(0.65, 0.45)
	], _phase(t, 0.08, 0.72))
	var ball := player + Vector2(17.0, -5.0)
	_draw_player(player, BLUE, Vector2.RIGHT)
	_draw_ball(ball)
	_draw_player(_point(0.55, 0.48), RED, Vector2.LEFT)
	_draw_arrow(player + Vector2(22.0, -22.0), Vector2.RIGHT, Color.WHITE)


func _draw_burst_dribble(t: float) -> void:
	var progress := _phase(t, 0.08, 0.78)
	var path: Array[Vector2] = [
		_point(0.19, 0.72), _point(0.36, 0.34),
		_point(0.57, 0.67), _point(0.79, 0.4)
	]
	var player := _lerp_path(path, progress)
	var direction := _path_direction(path, progress)
	_draw_motion_trail(path, progress, CYAN, 5.0)
	_draw_player(_point(0.39, 0.5), RED, Vector2.LEFT)
	_draw_player(_point(0.61, 0.5), RED, Vector2.LEFT)
	_draw_player(player, BLUE, direction, true)
	_draw_ball(player + direction * 17.0)
	_draw_charge_pips(2 - mini(int(progress * 3.0), 2))


func _draw_curve_shot(t: float) -> void:
	var shooter := _point(0.22, 0.68)
	var defender := _point(0.55, 0.53)
	var curve: Array[Vector2] = _bezier_points(
		shooter + Vector2(16.0, -4.0),
		_point(0.47, 0.13),
		_point(0.76, 0.16),
		_point(0.95, 0.45),
		32
	)
	_draw_player(shooter, BLUE, Vector2.RIGHT, t < 0.28)
	_draw_player(defender, RED, Vector2.LEFT)
	_draw_dashed_path(curve, PURPLE, 2.5, 0.62)
	var progress := _phase(t, 0.24, 0.78)
	_draw_ball(_lerp_path(curve, progress), PURPLE)
	if progress > 0.9:
		_draw_goal_flash(true, PURPLE, _phase(progress, 0.9, 1.0))


func _draw_power_strike(t: float) -> void:
	var shooter := _point(0.22, 0.54)
	var start := shooter + Vector2(18.0, 0.0)
	var finish := _point(0.96, 0.5)
	var charge := _phase(t, 0.04, 0.31)
	var flight := _phase(t, 0.31, 0.68)
	_draw_player(shooter, BLUE, Vector2.RIGHT, true)
	_draw_aura(shooter, Color(1.0, 0.25, 0.06), 24.0 + charge * 10.0)
	var ball := start.lerp(finish, flight * flight)
	_draw_flame_trail(start, ball)
	_draw_ball(ball, Color(1.0, 0.18, 0.04))
	_draw_player(_point(0.69, 0.5), RED, Vector2.LEFT)
	if flight > 0.9:
		_draw_goal_flash(true, Color(1.0, 0.25, 0.04), _phase(flight, 0.9, 1.0))


func _draw_overdrive(t: float) -> void:
	var pass_progress := _phase(t, 0.02, 0.53)
	var runner_progress := _phase(t, 0.1, 0.58)
	var passer := _point(0.18, 0.72)
	var target := _point(0.72, 0.27)
	var runner := _point(0.35, 0.78).lerp(target, runner_progress)
	var ball := passer.lerp(target, pass_progress)
	_draw_player(passer, BLUE.darkened(0.12), (target - passer).normalized())
	_draw_speed_lines(_point(0.35, 0.78), runner, CYAN)
	_draw_player(runner, BLUE, (target - runner).normalized(), true)
	_draw_ball(ball)
	_draw_player(_point(0.51, 0.42), RED, Vector2.RIGHT)
	_draw_player(_point(0.63, 0.62), RED, Vector2.UP)


func _draw_phantom_heel(t: float) -> void:
	var player := _point(0.56, 0.5)
	var incoming := _point(0.27, 0.5).lerp(player - Vector2(16.0, 0.0), _phase(t, 0.04, 0.36))
	var ball := incoming
	if t >= 0.36:
		ball = (player - Vector2(16.0, 0.0)).lerp(
			player + Vector2(42.0, 28.0),
			_phase(t, 0.36, 0.5)
		)
	_draw_player(player, BLUE, Vector2.LEFT, t > 0.31 and t < 0.54)
	_draw_player(_point(0.68, 0.47), RED, Vector2.LEFT)
	_draw_shadow_burst(player - Vector2(18.0, 0.0), player + Vector2(40.0, 28.0), t)
	_draw_ball(ball, PURPLE if t > 0.34 else Color.WHITE)


func _draw_enforcer(t: float) -> void:
	var enforcer := _point(0.39, 0.55)
	var enemy_start := _point(0.53, 0.55)
	var enemy := enemy_start
	if t > 0.31:
		enemy = enemy_start.lerp(_point(0.7, 0.27), _phase(t, 0.31, 0.56))
	_draw_aura(enforcer, Color(0.94, 0.2, 0.3), 29.0)
	_draw_player(enforcer, BLUE, Vector2.RIGHT, true)
	_draw_player(enemy, RED, Vector2.LEFT)
	_draw_ball(_point(0.61, 0.63))
	if t > 0.28 and t < 0.52:
		_draw_impact(enemy_start, GOLD, _phase(t, 0.28, 0.52))
	_draw_arrow(_point(0.56, 0.68), Vector2.RIGHT, Color(0.55, 0.9, 1.0))


func _draw_goalkeeper_reach(t: float) -> void:
	var shot_start := _point(0.31, 0.72)
	var save_point := _point(0.87, 0.32)
	var flight := _phase(t, 0.08, 0.62)
	var keeper_progress := _phase(t, 0.36, 0.64)
	var keeper := _point(0.88, 0.52).lerp(save_point, keeper_progress)
	_draw_player(_point(0.28, 0.7), BLUE, Vector2.RIGHT)
	_draw_ball(shot_start.lerp(save_point, flight))
	_draw_speed_lines(_point(0.88, 0.52), keeper, CYAN)
	_draw_player(keeper, RED, (save_point - _point(0.88, 0.52)).normalized(), true)
	if flight > 0.92:
		_draw_impact(save_point, CYAN, _phase(flight, 0.92, 1.0))


func _draw_dead_zone_pass(t: float) -> void:
	var passer := _point(0.2, 0.67)
	var receive := _point(0.72, 0.35)
	var progress := _phase(t, 0.12, 0.69)
	var eased := 1.0 - pow(1.0 - progress, 3.7)
	var ball := (passer + Vector2(16.0, -5.0)).lerp(receive, eased)
	_draw_player(passer, BLUE, (receive - passer).normalized(), t < 0.23)
	_draw_player(receive + Vector2(18.0, 4.0), BLUE, Vector2.LEFT)
	_draw_player(_point(0.5, 0.62), RED, Vector2.UP)
	_draw_dashed_path([passer, receive], PURPLE, 2.0, 0.45)
	_draw_ball(ball, PURPLE)
	if progress > 0.8:
		draw_arc(receive, 18.0, 0.0, TAU, 24, PURPLE, 2.0)


func _draw_trap_or_volley(t: float) -> void:
	var crosser := _point(0.21, 0.7)
	var finisher := _point(0.72, 0.46)
	var arrival := _phase(t, 0.05, 0.5)
	var cross_path := _bezier_points(
		crosser, _point(0.38, 0.16), _point(0.62, 0.2), finisher, 24
	)
	var ball := _lerp_path(cross_path, arrival)
	if t > 0.5:
		ball = finisher.lerp(_point(0.96, 0.38), _phase(t, 0.5, 0.69))
	_draw_player(crosser, BLUE.darkened(0.12), Vector2.RIGHT)
	_draw_player(finisher + Vector2(-13.0, 13.0), BLUE, Vector2.RIGHT, t > 0.43)
	_draw_player(_point(0.78, 0.61), RED, Vector2.UP)
	_draw_dashed_path(cross_path, Color(0.7, 0.88, 1.0), 1.7, 0.35)
	_draw_ball(ball, GOLD if t > 0.46 else Color.WHITE)
	if t > 0.47 and t < 0.61:
		_draw_impact(finisher, GOLD, _phase(t, 0.47, 0.61))


func _draw_elastic_step(t: float) -> void:
	var ball := _point(0.54, 0.52)
	var orbit_progress := _phase(t, 0.1, 0.63)
	var angle := lerpf(PI, -0.35 * PI, orbit_progress)
	var player := ball + Vector2(cos(angle), sin(angle)) * 38.0
	_draw_player(_point(0.62, 0.39), RED, Vector2.LEFT)
	_draw_orbit(ball, PURPLE)
	_draw_player(player, BLUE, (ball - player).normalized(), true)
	_draw_ball(ball)
	_draw_impact(player, PURPLE, fmod(orbit_progress * 2.0, 1.0))


func _draw_meta_vision(t: float) -> void:
	var player := _point(0.28, 0.68)
	var ball := _point(0.38, 0.57).lerp(_point(0.72, 0.16), _phase(t, 0.2, 0.68))
	var prediction: Array[Vector2] = [
		_point(0.38, 0.57), _point(0.73, 0.12),
		_point(0.88, 0.35), _point(0.96, 0.46)
	]
	_draw_dashed_path(prediction, CYAN, 2.0, 0.92)
	_draw_player(player, BLUE, Vector2.RIGHT, true)
	_draw_player(_point(0.64, 0.47), RED, Vector2.LEFT)
	_draw_interception_marker(_point(0.72, 0.16), t)
	_draw_ball(ball, CYAN)
	_draw_goal_flash(true, Color(1.0, 0.18, 0.22), 0.65 + sin(t * TAU * 4.0) * 0.25)
	_draw_vision_rings(player, t)


func _draw_copycat(t: float) -> void:
	var source := _point(0.23, 0.34)
	var copy := _point(0.31, 0.68)
	var link_alpha := clampf(sin(_phase(t, 0.06, 0.31) * PI), 0.0, 1.0)
	_draw_player(source, BLUE.darkened(0.16), Vector2.RIGHT, true)
	_draw_aura(source, Color(1.0, 0.3, 0.06), 25.0)
	_draw_player(copy, BLUE, Vector2.RIGHT, t > 0.25)
	_draw_dashed_path([source, copy], Color(0.55, 1.0, 0.68, link_alpha), 2.2, link_alpha)
	var flight := _phase(t, 0.38, 0.74)
	var start := copy + Vector2(18.0, -2.0)
	var ball := start.lerp(_point(0.96, 0.49), flight * flight)
	_draw_flame_trail(start, ball, Color(0.38, 1.0, 0.62))
	_draw_ball(ball, Color(0.42, 1.0, 0.64))


func _draw_reflex_block(t: float) -> void:
	var defender := _point(0.7, 0.5)
	var impact := defender - Vector2(22.0, 0.0)
	var incoming := _point(0.24, 0.56).lerp(impact, _phase(t, 0.08, 0.49))
	var ball := incoming
	if t > 0.49:
		ball = impact.lerp(_point(0.48, 0.19), _phase(t, 0.49, 0.76))
	_draw_player(_point(0.22, 0.56), RED, Vector2.RIGHT)
	_draw_guard_cone(defender, Vector2.LEFT, CYAN)
	_draw_player(defender, BLUE, Vector2.LEFT, true)
	_draw_player(_point(0.48, 0.18), BLUE.darkened(0.14), Vector2.DOWN)
	_draw_ball(ball)
	if t > 0.45 and t < 0.62:
		_draw_impact(impact, CYAN, _phase(t, 0.45, 0.62))


func _draw_iron_anchor(t: float) -> void:
	var anchor := _point(0.7, 0.51)
	var stop := anchor - Vector2(23.0, 0.0)
	var incoming := _point(0.22, 0.43).lerp(stop, _phase(t, 0.05, 0.5))
	var ball := incoming
	if t > 0.5:
		ball = stop
	_draw_player(_point(0.2, 0.43), RED, Vector2.RIGHT)
	_draw_player(anchor, BLUE, Vector2.LEFT, t > 0.42)
	_draw_ball(ball, CYAN if t > 0.47 else Color.WHITE)
	if t > 0.46:
		for radius in [15.0, 23.0, 31.0]:
			draw_arc(stop, radius, 0.0, TAU, 24, Color(CYAN, 0.52), 1.5)
		draw_line(stop + Vector2(-8.0, 18.0), stop + Vector2(8.0, 18.0), CYAN, 3.0)


func _draw_mirage_step(t: float) -> void:
	var start := _point(0.34, 0.61)
	var enemy := _point(0.54, 0.51)
	var finish := _point(0.68, 0.38)
	var travel := _phase(t, 0.25, 0.52)
	var player := start.lerp(finish, travel)
	var visibility := 1.0
	if travel > 0.05 and travel < 0.95:
		visibility = 0.16
	_draw_player(enemy, RED, Vector2.LEFT)
	_draw_small_shadow_particles(start, finish, travel, MIRAGE_PURPLE)
	_draw_player(player, Color(BLUE, visibility), Vector2.RIGHT, t > 0.2)
	var ball := start + Vector2(18.0, -4.0)
	if t > 0.17:
		ball = ball.lerp(finish + Vector2(18.0, -4.0), _phase(t, 0.17, 0.55))
	_draw_ball(ball, MIRAGE_PURPLE)


func _draw_boogie_woogie(t: float) -> void:
	var blue_start := _point(0.31, 0.66)
	var red_start := _point(0.67, 0.39)
	var swap := _phase(t, 0.28, 0.42)
	var blue_position := blue_start.lerp(red_start, swap)
	var red_position := red_start.lerp(blue_start, swap)
	_draw_player(blue_position, BLUE, Vector2.RIGHT, t > 0.2)
	_draw_player(red_position, RED, Vector2.LEFT)
	_draw_ball(_point(0.73, 0.53) + Vector2(48.0, 0.0) * _phase(t, 0.39, 0.65), GOLD)
	if t > 0.37 and t < 0.7:
		var wave := _phase(t, 0.37, 0.7)
		draw_arc(red_start, 18.0 + wave * 55.0, 0.0, TAU, 36, Color(PURPLE, 1.0 - wave), 3.0)
	_draw_clap(red_start, t)


func _draw_echo(t: float) -> void:
	var defender := _point(0.30, 0.55)
	var echo_position := _point(0.48, 0.55)
	var attacker := _point(0.72, 0.55)
	var flight := _phase(t, 0.22, 0.64)
	var ball_start := attacker + Vector2(-15.0, 0.0)
	var ball_finish := echo_position + Vector2(8.0, 0.0)
	_draw_player(defender, BLUE, Vector2.RIGHT, true)
	var blink := 0.28 + 0.52 * absf(sin(_elapsed * 8.0))
	_draw_player(echo_position, Color(BLUE, blink), Vector2.RIGHT)
	for index in range(-2, 3):
		var y := float(index) * 5.0
		draw_line(
			echo_position + Vector2(-12.0, y),
			echo_position + Vector2(12.0, y),
			Color(CYAN, blink * 0.6),
			1.0
		)
	_draw_player(attacker, RED, Vector2.LEFT, t < 0.24)
	var ball_position := ball_start.lerp(ball_finish, flight)
	_draw_ball(ball_position)
	if flight > 0.86:
		_draw_impact(echo_position, CYAN, _phase(flight, 0.86, 1.0))


func _draw_return_tag(t: float) -> void:
	var playmaker := _point(0.22, 0.67)
	var teammate := _point(0.58, 0.34)
	var forward_target := _point(0.78, 0.58)
	var first_pass := _phase(t, 0.08, 0.42)
	var second_pass := _phase(t, 0.50, 0.84)
	var runner_position := playmaker.lerp(forward_target, _phase(t, 0.22, 0.82))
	_draw_player(runner_position, BLUE, Vector2.RIGHT, true)
	_draw_player(teammate, BLUE, Vector2.LEFT)
	_draw_player(_point(0.48, 0.54), RED, Vector2.LEFT)
	var first_ball := playmaker.lerp(teammate, first_pass)
	var ball_position := first_ball
	if t >= 0.50:
		ball_position = teammate.lerp(runner_position, second_pass)
	_draw_ball(ball_position, PURPLE)
	var ring_alpha := 0.34 + 0.38 * absf(sin(_elapsed * 7.0))
	draw_arc(ball_position, 11.0, 0.0, TAU, 24, Color(PURPLE, ring_alpha), 2.0)
	if t < 0.5:
		_draw_arrow(playmaker + Vector2(10.0, -15.0), playmaker.direction_to(teammate), PURPLE)
	else:
		_draw_arrow(teammate + Vector2(10.0, 10.0), teammate.direction_to(runner_position), CYAN)


func _draw_breakaway(t: float) -> void:
	var attacker_path: Array[Vector2] = [
		_point(0.22, 0.70), _point(0.42, 0.56),
		_point(0.62, 0.34), _point(0.82, 0.28)
	]
	var defender := _point(0.46, 0.56)
	var runner_progress := _phase(t, 0.18, 0.78)
	var runner := _lerp_path(attacker_path, runner_progress)
	var direction := _path_direction(attacker_path, runner_progress)
	var ball_start := _point(0.28, 0.68)
	var ball_finish := _point(0.72, 0.28)
	var ball_progress := _phase(t, 0.12, 0.62)
	var ball := ball_start.lerp(ball_finish, pow(ball_progress, 0.92))
	_draw_player(defender, RED, Vector2.LEFT)
	_draw_motion_trail(attacker_path, runner_progress, GOLD, 4.2)
	_draw_speed_lines(_point(0.20, 0.71), runner, GOLD)
	_draw_player(runner, BLUE, direction, true)
	_draw_ball(ball, GOLD)
	if t > 0.12 and t < 0.30:
		_draw_impact(ball_start, GOLD, _phase(t, 0.12, 0.30))
	if ball_progress > 0.84:
		_draw_goal_flash(true, GOLD, _phase(ball_progress, 0.84, 1.0))


func _draw_snapback(t: float) -> void:
	var attacker := _point(0.28, 0.64)
	var attacker_run := attacker.lerp(_point(0.38, 0.55), _phase(t, 0.20, 0.78))
	var defender := _point(0.61, 0.50)
	var mark_target := _point(0.76, 0.43)
	var out_progress := _phase(t, 0.08, 0.34)
	var recall_progress := _phase(t, 0.46, 0.86)
	var ball := attacker + Vector2(16.0, -4.0)
	if t < 0.46:
		ball = (attacker + Vector2(16.0, -4.0)).lerp(mark_target, out_progress)
	else:
		var snap_curve := _bezier_points(
			mark_target,
			_point(0.67, 0.20),
			_point(0.48, 0.36),
			attacker_run + Vector2(16.0, -4.0),
			28
		)
		ball = _lerp_path(snap_curve, recall_progress)
		_draw_dashed_path(snap_curve, Color(1.0, 0.33, 0.72), 2.2, 0.58)
	_draw_player(attacker_run, BLUE, Vector2.RIGHT, true)
	_draw_player(defender, RED, Vector2.LEFT)
	_draw_ball(ball, Color(1.0, 0.35, 0.74))
	draw_arc(ball, 10.5, 0.0, TAU, 24, Color(1.0, 0.35, 0.74, 0.9), 1.9)
	if t > 0.44 and t < 0.70:
		_draw_impact(mark_target, Color(1.0, 0.35, 0.74), _phase(t, 0.44, 0.70))


func _draw_side_swipe(t: float) -> void:
	# Side Swipe is a straight sideways shot from an unusual body/ball position.
	# The player is near the top-right goal line with the ball slightly below them,
	# then fires it sideways into goal without needing a normal shooting angle.
	var attacker := _point(0.80, 0.34)
	var keeper := _point(0.92, 0.68)
	var ball_start := attacker + Vector2(0.0, 18.0)
	var ball_finish := _point(0.985, 0.52)
	var shot_progress := _phase(t, 0.28, 0.72)
	var ball := ball_start.lerp(ball_finish, shot_progress)

	# Attacker faces downward toward the ball, making the sideways release read clearly.
	_draw_player(attacker, BLUE, Vector2.DOWN, t < 0.36)
	_draw_player(keeper, RED.darkened(0.15), Vector2.UP)
	_draw_ball(ball, CYAN)

	# Short lateral swipe cue near the kicking leg/ball. No curve, no arc path.
	if t < 0.34:
		var cue := _phase(t, 0.08, 0.30)
		draw_line(
			ball_start + Vector2(-16.0, -8.0),
			ball_start + Vector2(12.0, -8.0),
			Color(CYAN, 0.38 * cue),
			2.0
		)
		draw_line(
			ball_start + Vector2(-20.0, 0.0),
			ball_start + Vector2(10.0, 0.0),
			Color(CYAN, 0.62 * cue),
			3.0
		)
		draw_line(
			ball_start + Vector2(-14.0, 8.0),
			ball_start + Vector2(14.0, 8.0),
			Color(CYAN, 0.32 * cue),
			2.0
		)

	# Straight sideways shot trail.
	if t >= 0.28:
		var trail_end := ball
		for index in range(3):
			var offset := Vector2(0.0, float(index - 1) * 4.0)
			draw_line(
				ball_start + offset,
				trail_end - Vector2(8.0 + float(index) * 3.0, 0.0) + offset,
				Color(CYAN, 0.24 + float(index) * 0.10),
				2.0
			)
	if t > 0.26 and t < 0.42:
		_draw_impact(ball_start, CYAN, _phase(t, 0.26, 0.42))
	if shot_progress > 0.92:
		_draw_goal_flash(true, CYAN, _phase(shot_progress, 0.92, 1.0))
		_draw_impact(ball_finish, CYAN, _phase(shot_progress, 0.92, 1.0))


func _draw_nutmeg(t: float) -> void:
	var attacker := _point(0.24, 0.52)
	var defender := _point(0.52, 0.52)
	var finish := _point(0.84, 0.52)
	var ball: Vector2 = attacker + Vector2(18.0, 0.0)
	if t > 0.28:
		ball = ball.lerp(finish, _phase(t, 0.28, 0.74))
	_draw_player(attacker, BLUE, Vector2.RIGHT, t < 0.36)
	_draw_player(defender, RED, Vector2.LEFT)
	_draw_ball(ball, GOLD)
	draw_line(attacker + Vector2(22.0, 0.0), finish, Color(GOLD, 0.34), 2.0)
	if ball.x > defender.x - 14.0 and ball.x < defender.x + 18.0:
		_draw_impact(defender, GOLD, _phase(t, 0.42, 0.58))


func _draw_decoy_run(t: float) -> void:
	var origin := _point(0.25, 0.56)
	var real_player := origin.lerp(_point(0.55, 0.72), _phase(t, 0.20, 0.70))
	var decoy := origin.lerp(_point(0.79, 0.38), _phase(t, 0.20, 0.82))
	var defender := _point(0.72, 0.48)
	_draw_player(real_player, Color(BLUE, 0.48), Vector2(1.0, 0.45), true)
	_draw_player(decoy, Color(PURPLE, 0.62 * (1.0 - _phase(t, 0.35, 0.9))), Vector2.RIGHT)
	_draw_player(defender, RED, decoy - defender)
	_draw_small_shadow_particles(origin, decoy, _phase(t, 0.20, 0.82))

func _point(x: float, y: float) -> Vector2:
	return Vector2(size.x * x, size.y * y)


func _phase(value: float, start: float, finish: float) -> float:
	return smoothstep(start, finish, value)


func _lerp_path(points: Array[Vector2], progress: float) -> Vector2:
	if points.is_empty():
		return Vector2.ZERO
	if points.size() == 1:
		return points[0]
	var scaled := clampf(progress, 0.0, 1.0) * float(points.size() - 1)
	var index := mini(int(floor(scaled)), points.size() - 2)
	return points[index].lerp(points[index + 1], scaled - float(index))


func _path_direction(points: Array[Vector2], progress: float) -> Vector2:
	var before := _lerp_path(points, maxf(0.0, progress - 0.02))
	var after := _lerp_path(points, minf(1.0, progress + 0.02))
	return (after - before).normalized()


func _bezier_points(
	start: Vector2,
	control_a: Vector2,
	control_b: Vector2,
	finish: Vector2,
	count: int
) -> Array[Vector2]:
	var points: Array[Vector2] = []
	for index in range(maxi(count, 2)):
		var t := float(index) / float(maxi(count - 1, 1))
		var inverse := 1.0 - t
		points.append(
			start * inverse * inverse * inverse
			+ control_a * 3.0 * inverse * inverse * t
			+ control_b * 3.0 * inverse * t * t
			+ finish * t * t * t
		)
	return points


func _draw_goal(right_side: bool, color: Color) -> void:
	var x := size.x - 7.0 if right_side else 7.0
	var direction := -1.0 if right_side else 1.0
	var top := _point(1.0 if right_side else 0.0, 0.36)
	var bottom := _point(1.0 if right_side else 0.0, 0.64)
	draw_line(top, bottom, color, 4.0)
	draw_line(top, top + Vector2(direction * 13.0, 0.0), color, 2.0)
	draw_line(bottom, bottom + Vector2(direction * 13.0, 0.0), color, 2.0)
	draw_line(Vector2(x, top.y), Vector2(x, bottom.y), color, 2.0)


func _draw_goal_flash(right_side: bool, color: Color, amount: float) -> void:
	var x := size.x - 8.0 if right_side else 8.0
	var alpha := clampf(amount, 0.0, 1.0)
	draw_line(
		Vector2(x, size.y * 0.34),
		Vector2(x, size.y * 0.66),
		Color(color, alpha),
		7.0
	)


func _draw_player(
	position: Vector2,
	color: Color,
	facing: Vector2,
	active: bool = false
) -> void:
	if active:
		draw_arc(position, 17.0, 0.0, TAU, 32, Color(GOLD, color.a * 0.92), 2.0)
	draw_circle(position + Vector2(2.0, 4.0), 12.0, Color(0.0, 0.0, 0.0, 0.32 * color.a))
	draw_circle(position, 11.0, color)
	draw_arc(position, 11.0, 0.0, TAU, 28, Color(0.92, 0.98, 1.0, color.a), 1.8)
	var safe_facing := facing.normalized()
	if safe_facing.is_zero_approx():
		safe_facing = Vector2.RIGHT
	draw_line(position, position + safe_facing * 14.0, Color(1.0, 1.0, 1.0, color.a), 2.0)


func _draw_ball(position: Vector2, glow: Color = Color.WHITE) -> void:
	if glow != Color.WHITE:
		draw_circle(position, 12.0, Color(glow, 0.16))
	draw_circle(position + Vector2(1.5, 2.5), 7.0, Color(0.0, 0.0, 0.0, 0.4))
	draw_circle(position, 6.5, Color(0.96, 0.96, 0.9))
	draw_circle(position, 2.2, Color(0.08, 0.1, 0.12))
	draw_arc(position, 6.5, 0.0, TAU, 20, glow, 1.3)


func _draw_dashed_path(
	points: Array[Vector2],
	color: Color,
	width: float,
	alpha: float
) -> void:
	if points.size() < 2:
		return
	for index in range(points.size() - 1):
		if index % 2 == 0:
			draw_line(points[index], points[index + 1], Color(color, alpha), width)


func _draw_motion_trail(
	path: Array[Vector2],
	progress: float,
	color: Color,
	width: float
) -> void:
	var points := PackedVector2Array()
	for index in range(9):
		var sample := maxf(0.0, progress - float(8 - index) * 0.026)
		points.append(_lerp_path(path, sample))
	if points.size() > 1:
		draw_polyline(points, Color(color, 0.55), width, true)


func _draw_speed_lines(start: Vector2, finish: Vector2, color: Color) -> void:
	var direction := (finish - start).normalized()
	var side := direction.orthogonal()
	for index in range(3):
		var offset := side * float(index - 1) * 7.0
		draw_line(start + offset, finish - direction * 16.0 + offset, Color(color, 0.48), 2.0)


func _draw_flame_trail(
	start: Vector2,
	finish: Vector2,
	color: Color = Color(1.0, 0.28, 0.03)
) -> void:
	var distance := start.distance_to(finish)
	var count := mini(int(distance / 10.0), 26)
	for index in range(count):
		var ratio := float(index) / float(maxi(count, 1))
		var point := start.lerp(finish, ratio)
		var wobble := sin(float(index) * 2.1 + _elapsed * 14.0) * 4.0
		point.y += wobble
		draw_circle(point, 3.8 * ratio + 1.0, Color(color, 0.18 + ratio * 0.55))


func _draw_aura(position: Vector2, color: Color, radius: float) -> void:
	var pulse := 2.0 + sin(_elapsed * 9.0) * 2.0
	draw_circle(position, radius + pulse, Color(color, 0.1))
	draw_arc(position, radius + pulse, 0.0, TAU, 30, Color(color, 0.75), 2.0)


func _draw_impact(position: Vector2, color: Color, progress: float) -> void:
	var safe := clampf(progress, 0.0, 1.0)
	for index in range(8):
		var direction := Vector2.from_angle(TAU * float(index) / 8.0)
		draw_line(
			position + direction * (8.0 + safe * 8.0),
			position + direction * (15.0 + safe * 18.0),
			Color(color, 1.0 - safe),
			2.2
		)


func _draw_shadow_burst(start: Vector2, finish: Vector2, t: float) -> void:
	if t < 0.3 or t > 0.66:
		return
	var amount := _phase(t, 0.3, 0.5)
	draw_circle(start, 13.0 + amount * 20.0, Color(0.12, 0.0, 0.2, 0.4 * (1.0 - amount)))
	draw_circle(finish, 9.0 + amount * 15.0, Color(PURPLE, 0.36 * (1.0 - amount)))


func _draw_orbit(center: Vector2, color: Color) -> void:
	draw_arc(center, 38.0, -PI, -0.35 * PI, 24, Color(color, 0.7), 2.0)
	_draw_arrow(center + Vector2(20.0, -32.0), Vector2.RIGHT, color)


func _draw_arrow(position: Vector2, direction: Vector2, color: Color) -> void:
	var safe := direction.normalized()
	if safe.is_zero_approx():
		return
	var side := safe.orthogonal()
	draw_line(position, position + safe * 24.0, color, 2.0)
	draw_colored_polygon(PackedVector2Array([
		position + safe * 28.0,
		position + safe * 18.0 + side * 5.0,
		position + safe * 18.0 - side * 5.0
	]), color)


func _draw_charge_pips(remaining: int) -> void:
	for index in range(2):
		var color := CYAN if index < remaining else Color(0.2, 0.27, 0.3, 0.7)
		draw_circle(Vector2(20.0 + float(index) * 18.0, 20.0), 5.0, color)


func _draw_interception_marker(position: Vector2, t: float) -> void:
	var pulse := 9.0 + sin(t * TAU * 5.0) * 3.0
	draw_arc(position, pulse, 0.0, TAU, 20, GOLD, 2.0)
	draw_line(position - Vector2(12.0, 0.0), position + Vector2(12.0, 0.0), GOLD, 1.2)
	draw_line(position - Vector2(0.0, 12.0), position + Vector2(0.0, 12.0), GOLD, 1.2)


func _draw_vision_rings(position: Vector2, t: float) -> void:
	for index in range(3):
		var radius := 19.0 + fmod(t * 48.0 + float(index) * 13.0, 39.0)
		draw_arc(position, radius, 0.0, TAU, 30, Color(CYAN, 0.42 * (1.0 - radius / 62.0)), 1.2)


func _draw_guard_cone(position: Vector2, facing: Vector2, color: Color) -> void:
	var angle := facing.angle()
	var points := PackedVector2Array([position])
	for index in range(13):
		var sample := lerpf(angle - 0.62, angle + 0.62, float(index) / 12.0)
		points.append(position + Vector2.from_angle(sample) * 48.0)
	draw_colored_polygon(points, Color(color, 0.16))
	draw_arc(position, 48.0, angle - 0.62, angle + 0.62, 18, Color(color, 0.82), 2.0)


func _draw_small_shadow_particles(
	start: Vector2,
	finish: Vector2,
	progress: float,
	color: Color = PURPLE
) -> void:
	for index in range(18):
		var ratio := fmod(float(index) / 18.0 + progress, 1.0)
		var point := start.lerp(finish, ratio)
		point += Vector2(
			sin(float(index) * 4.1) * 8.0,
			cos(float(index) * 2.7) * 6.0
		)
		draw_circle(point, 1.5 + float(index % 3), Color(color, 0.72 * (1.0 - ratio * 0.5)))


func _draw_clap(position: Vector2, t: float) -> void:
	if t < 0.19 or t > 0.45:
		return
	var close := sin(_phase(t, 0.19, 0.45) * PI)
	var gap := 18.0 * (1.0 - close)
	draw_line(position + Vector2(-gap - 11.0, -18.0), position + Vector2(-gap, -8.0), GOLD, 5.0)
	draw_line(position + Vector2(gap + 11.0, -18.0), position + Vector2(gap, -8.0), GOLD, 5.0)
