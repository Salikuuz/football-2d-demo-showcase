class_name DefenseEcho
extends StaticBody2D

const ECHO_RED_COLLISION_LAYER_VALUE: int = 16
const ECHO_BLUE_COLLISION_LAYER_VALUE: int = 32

var _player_block_shape: CollisionShape2D

var lifetime: float = 5.0
var elapsed: float = 0.0
var visual_radius: float = 119.0
var team_color: Color = Color(0.35, 0.7, 1.0)
var portrait_texture: Texture2D
var consumed: bool = false
var power_break: bool = false
var consume_elapsed: float = 0.0
var consume_duration: float = 0.22


func configure(
	world_position: Vector2,
	duration: float,
	player_team: StringName,
	portrait: Texture2D,
	radius: float
) -> void:
	global_position = world_position
	lifetime = maxf(0.1, duration)
	visual_radius = maxf(24.0, radius)
	portrait_texture = portrait
	_configure_player_blocker(player_team)
	team_color = (
		Color(1.0, 0.24, 0.32, 1.0)
		if player_team == &"red"
		else Color(0.18, 0.58, 1.0, 1.0)
	)
	z_index = 5
	queue_redraw()


func _configure_player_blocker(player_team: StringName) -> void:
	# The Echo is solid only for enemy players. FootballPlayer adds the
	# opposing Echo layer to its collision mask. The Echo itself scans
	# nothing, which prevents teammates and the ball from being caught by
	# this physics body. Ball blocking remains handled authoritatively by
	# FootballPlayer/FootballBall.
	collision_layer = (
		ECHO_RED_COLLISION_LAYER_VALUE
		if player_team == &"red"
		else ECHO_BLUE_COLLISION_LAYER_VALUE
	)
	collision_mask = 0

	if _player_block_shape == null:
		_player_block_shape = CollisionShape2D.new()
		_player_block_shape.name = "EnemyPlayerBlocker"
		add_child(_player_block_shape)

	var circle := CircleShape2D.new()
	# Slightly inside the visible ring so collisions feel aligned rather than
	# as if the player hits an invisible wall before reaching the Echo.
	circle.radius = maxf(20.0, visual_radius * 0.86)
	_player_block_shape.shape = circle
	_player_block_shape.disabled = false


func _disable_player_blocker() -> void:
	if _player_block_shape != null:
		_player_block_shape.set_deferred("disabled", true)
	collision_layer = 0


func consume(was_power_strike: bool) -> void:
	if consumed:
		return
	consumed = true
	_disable_player_blocker()
	power_break = was_power_strike
	consume_elapsed = 0.0
	queue_redraw()


func _process(delta: float) -> void:
	if consumed:
		consume_elapsed += delta
		queue_redraw()
		if consume_elapsed >= consume_duration:
			queue_free()
		return

	elapsed += delta
	queue_redraw()
	if elapsed >= lifetime:
		queue_free()


func _draw() -> void:
	var life_ratio := clampf(1.0 - elapsed / maxf(0.1, lifetime), 0.0, 1.0)
	var blink := 0.48 + 0.34 * sin(elapsed * 14.0)
	var alpha := clampf(blink * minf(1.0, life_ratio * 4.0), 0.16, 0.82)
	var scale_ratio := 1.0
	if consumed:
		var consume_ratio := clampf(
			consume_elapsed / maxf(0.01, consume_duration),
			0.0,
			1.0
		)
		alpha = 1.0 - consume_ratio
		scale_ratio = lerpf(1.0, 1.42 if power_break else 1.18, consume_ratio)

	var radius := visual_radius * scale_ratio
	var shadow_color := Color(0.0, 0.0, 0.0, 0.26 * alpha)
	draw_circle(Vector2(0.0, 14.0), radius * 0.86, shadow_color)
	draw_circle(Vector2.ZERO, radius, Color(team_color, 0.15 * alpha))
	draw_arc(
		Vector2.ZERO,
		radius,
		0.0,
		TAU,
		72,
		Color(team_color.lightened(0.25), 0.88 * alpha),
		8.0,
		true
	)
	draw_arc(
		Vector2.ZERO,
		radius * 0.84,
		0.0,
		TAU,
		64,
		Color(1.0, 1.0, 1.0, 0.52 * alpha),
		3.0,
		true
	)

	if portrait_texture != null:
		var diameter := radius * 1.5
		draw_texture_rect(
			portrait_texture,
			Rect2(
				Vector2(-diameter * 0.5, -diameter * 0.5),
				Vector2.ONE * diameter
			),
			false,
			Color(1.0, 1.0, 1.0, 0.32 * alpha)
		)

	var scan_color := Color(team_color.lightened(0.42), 0.36 * alpha)
	for index in range(-3, 4):
		var y := float(index) * radius * 0.22
		var half_width := sqrt(maxf(0.0, radius * radius - y * y)) * 0.72
		draw_line(
			Vector2(-half_width, y),
			Vector2(half_width, y),
			scan_color,
			2.0,
			true
		)

	if consumed:
		var shard_color := (
			Color(1.0, 0.15, 0.08, alpha)
			if power_break
			else Color(team_color.lightened(0.5), alpha)
		)
		for index in range(12):
			var angle := TAU * float(index) / 12.0
			var start := Vector2.RIGHT.rotated(angle) * radius * 0.45
			var finish := Vector2.RIGHT.rotated(angle) * radius * 1.32
			draw_line(start, finish, shard_color, 4.0, true)
