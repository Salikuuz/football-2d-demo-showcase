class_name FootballBall
extends RigidBody2D


const LOCAL_SETTINGS_PATH: String = "user://player_settings.cfg"
# The ball is authoritative on the server, but clients render a short
# extrapolated/smoothed copy. This avoids writing a RigidBody transform directly
# whenever a network packet happens to arrive, which was visibly jittery at
# high render rates.
const NETWORK_BALL_EXTRAPOLATION_SECONDS: float = 0.035
const NETWORK_BALL_MAX_EXTRAPOLATION_SECONDS: float = 0.090
const NETWORK_BALL_SNAPSHOT_INTERVAL_BLEND: float = 0.20
const NETWORK_BALL_SNAPSHOT_INTERVAL_MAX_SAMPLE_SECONDS: float = 0.250
const NETWORK_BALL_SNAPSHOT_INTERVAL_MULTIPLIER: float = 1.55
const NETWORK_BALL_SNAPSHOT_JITTER_MARGIN_SECONDS: float = 0.008
const NETWORK_BALL_STALE_DECAY_SECONDS: float = 0.024
const NETWORK_BALL_SMOOTHING_RESPONSE: float = 50.0
const NETWORK_BALL_TELEPORT_SNAP_DISTANCE: float = 900.0
const BALL_STYLE_THEODORE: StringName = &"theodore"
const BALL_STYLE_CLASSIC: StringName = &"classic"
const BALL_STYLE_TENNIS: StringName = &"tennis"
const BALL_STYLE_VOLLEYBALL: StringName = &"volleyball"
const BALL_STYLE_BASKETBALL: StringName = &"basketball"
const BALL_STYLE_BLUSH_POP: StringName = &"blush_pop"
const BALL_STYLE_SUNSET_ORBIT: StringName = &"sunset_orbit"
const BALL_STYLE_VIOLET_SWIRL: StringName = &"violet_swirl"
const BALL_STYLE_SHADOW_PULSE: StringName = &"shadow_pulse"
const BALL_STYLE_LIME_TWIST: StringName = &"lime_twist"
const THEODORE_BALL_TEXTURE: Texture2D = preload("res://theodoreball.png")
const CLASSIC_BALL_TEXTURE: Texture2D = preload(
	"res://Characters/8542ed85-244c-4f74-b0a5-181eb4e58456.png"
)
const TENNIS_BALL_TEXTURE: Texture2D = preload("res://Assets/balls/tennis_ball.png")
const VOLLEYBALL_TEXTURE: Texture2D = preload("res://Assets/balls/volleyball.png")
const BASKETBALL_TEXTURE: Texture2D = preload("res://Assets/balls/basketball.png")
const BLUSH_POP_BALL_TEXTURE: Texture2D = preload("res://Assets/balls/blush_pop_ball.png")
const SUNSET_ORBIT_BALL_TEXTURE: Texture2D = preload("res://Assets/balls/sunset_orbit_ball.png")
const VIOLET_SWIRL_BALL_TEXTURE: Texture2D = preload("res://Assets/balls/violet_swirl_ball.png")
const SHADOW_PULSE_BALL_TEXTURE: Texture2D = preload("res://Assets/balls/shadow_pulse_ball.png")
const LIME_TWIST_BALL_TEXTURE: Texture2D = preload("res://Assets/balls/lime_twist_ball.png")
const THEODORE_BALL_SCALE := Vector2(0.25711755, 0.26822037)
const CLASSIC_BALL_SCALE := Vector2(0.21700194, 0.220292)
const TENNIS_BALL_SCALE := Vector2(0.1398, 0.1398)
const VOLLEYBALL_SCALE := Vector2(0.1049, 0.1049)
const BASKETBALL_SCALE := Vector2(0.0832, 0.0833)
const BLUSH_POP_BALL_SCALE := Vector2(0.106, 0.106)
const SUNSET_ORBIT_BALL_SCALE := Vector2(0.272, 0.272)
const VIOLET_SWIRL_BALL_SCALE := Vector2(0.106, 0.106)
const SHADOW_PULSE_BALL_SCALE := Vector2(0.106, 0.106)
const LIME_TWIST_BALL_SCALE := Vector2(0.272, 0.272)
const THEODORE_BALL_OFFSET := Vector2(6.5, -3.0)
const CLASSIC_BALL_OFFSET := Vector2(6.0, 0.5)
const TENNIS_BALL_OFFSET := Vector2.ZERO
const VOLLEYBALL_OFFSET := Vector2.ZERO
const BASKETBALL_OFFSET := Vector2.ZERO
const BLUSH_POP_BALL_OFFSET := Vector2.ZERO
const SUNSET_ORBIT_BALL_OFFSET := Vector2.ZERO
const VIOLET_SWIRL_BALL_OFFSET := Vector2.ZERO
const SHADOW_PULSE_BALL_OFFSET := Vector2.ZERO
const LIME_TWIST_BALL_OFFSET := Vector2.ZERO
# One shared catalog drives both the in-match ball renderer and the visual
# appearance picker in Options. Adding another cosmetic ball now only needs a
# single entry here instead of a separate menu item plus renderer branch.
const BALL_APPEARANCE_VARIANTS: Array[Dictionary] = [
	{
		"style": BALL_STYLE_THEODORE,
		"display_name": "Theodore",
		"texture": THEODORE_BALL_TEXTURE,
		"sprite_scale": THEODORE_BALL_SCALE,
		"sprite_offset": THEODORE_BALL_OFFSET,
	},
	{
		"style": BALL_STYLE_CLASSIC,
		"display_name": "Classic Football",
		"texture": CLASSIC_BALL_TEXTURE,
		"sprite_scale": CLASSIC_BALL_SCALE,
		"sprite_offset": CLASSIC_BALL_OFFSET,
	},
	{
		"style": BALL_STYLE_TENNIS,
		"display_name": "Tennis Ball",
		"texture": TENNIS_BALL_TEXTURE,
		"sprite_scale": TENNIS_BALL_SCALE,
		"sprite_offset": TENNIS_BALL_OFFSET,
	},
	{
		"style": BALL_STYLE_VOLLEYBALL,
		"display_name": "Volleyball",
		"texture": VOLLEYBALL_TEXTURE,
		"sprite_scale": VOLLEYBALL_SCALE,
		"sprite_offset": VOLLEYBALL_OFFSET,
	},
	{
		"style": BALL_STYLE_BASKETBALL,
		"display_name": "Basketball",
		"texture": BASKETBALL_TEXTURE,
		"sprite_scale": BASKETBALL_SCALE,
		"sprite_offset": BASKETBALL_OFFSET,
	},
	{
		"style": BALL_STYLE_BLUSH_POP,
		"display_name": "Astral Prism",
		"texture": BLUSH_POP_BALL_TEXTURE,
		"sprite_scale": BLUSH_POP_BALL_SCALE,
		"sprite_offset": BLUSH_POP_BALL_OFFSET,
	},
	{
		"style": BALL_STYLE_SUNSET_ORBIT,
		"display_name": "Supernova Crown",
		"texture": SUNSET_ORBIT_BALL_TEXTURE,
		"sprite_scale": SUNSET_ORBIT_BALL_SCALE,
		"sprite_offset": SUNSET_ORBIT_BALL_OFFSET,
	},
	{
		"style": BALL_STYLE_VIOLET_SWIRL,
		"display_name": "Eclipse Core",
		"texture": VIOLET_SWIRL_BALL_TEXTURE,
		"sprite_scale": VIOLET_SWIRL_BALL_SCALE,
		"sprite_offset": VIOLET_SWIRL_BALL_OFFSET,
	},
	{
		"style": BALL_STYLE_SHADOW_PULSE,
		"display_name": "Aurora Nexus",
		"texture": SHADOW_PULSE_BALL_TEXTURE,
		"sprite_scale": SHADOW_PULSE_BALL_SCALE,
		"sprite_offset": SHADOW_PULSE_BALL_OFFSET,
	},
	{
		"style": BALL_STYLE_LIME_TWIST,
		"display_name": "Stellar Bloom",
		"texture": LIME_TWIST_BALL_TEXTURE,
		"sprite_scale": LIME_TWIST_BALL_SCALE,
		"sprite_offset": LIME_TWIST_BALL_OFFSET,
	},
]
# Corrupt RigidBody2D transforms (NaN/INF) vanish from both rendering and the
# physics broadphase. These limits are intentionally far outside the arena and
# only exist as a last-resort recovery boundary.
const PHYSICS_SANITY_MAX_COORDINATE: float = 100000.0
const PHYSICS_SANITY_MAX_SPEED: float = 100000.0
const PHYSICS_SANITY_MAX_SINGLE_STEP_DISPLACEMENT: float = 20000.0


const BALL_CONTACT_SOUND: AudioStream = preload(
	"res://mixkit-hitting-soccer-ball-2112-godot.mp3"
)
# Keep ordinary football contacts in the same natural recorded-ball family as
# the shot tiers. Arcade character comes from timing/mix, not synthetic layers.
const WALL_HIT_SOUND: AudioStream = preload("res://Audio/sfx_kick_normal.wav")
const POST_HIT_SOUND: AudioStream = preload("res://Audio/sfx_kick_strong.wav")
const SAVE_SOUND: AudioStream = preload("res://Audio/sfx_kick_normal.wav")
const INTERCEPTION_SOUND: AudioStream = preload("res://Audio/sfx_kick_normal.wav")

const GoalExplosionFX = preload(
	"res://Scenes/goal_explosion_fx.gd"
)
const KickFeedbackFX = preload(
	"res://Scenes/kick_feedback_fx.gd"
)

signal player_touch_registered(
	peer_id: int,
	player_name: String,
	player_team: StringName,
	incoming_velocity: Vector2
)
signal player_kicked(
	peer_id: int,
	player_name: String,
	player_team: StringName,
	kick_position: Vector2,
	predicted_velocity: Vector2
)
signal wall_collision_replay_event(speed: float)

@export var maximum_speed: float = 12000.0
var fun_kick_speed_multiplier: float = 1.0
var _pending_fun_kick_velocity_bonus: Vector2 = Vector2.ZERO
var _physics_sanity_last_transform: Transform2D = Transform2D.IDENTITY
var _physics_sanity_last_velocity: Vector2 = Vector2.ZERO
var _physics_sanity_last_angular_velocity: float = 0.0
var _physics_sanity_initialized: bool = false

# MultiplayerSynchronizer replicates these authoritative motion snapshots. The
# actual client transform is intentionally not synchronized directly; clients
# consume these values and render them smoothly every frame.
var network_position: Vector2 = Vector2.ZERO
var network_linear_velocity: Vector2 = Vector2.ZERO
var network_rotation: float = 0.0
var network_angular_velocity: float = 0.0
var _network_target_position: Vector2 = Vector2.ZERO
var _network_target_velocity: Vector2 = Vector2.ZERO
var _network_target_rotation: float = 0.0
var _network_target_angular_velocity: float = 0.0
var _network_last_snapshot_position: Vector2 = Vector2.INF
var _network_last_snapshot_velocity: Vector2 = Vector2.INF
var _network_last_snapshot_rotation: float = INF
var _network_last_snapshot_angular_velocity: float = INF
var _network_snapshot_age: float = 0.0
var _network_smoothed_snapshot_interval: float = 1.0 / 60.0
var _network_motion_initialized: bool = false
var _network_snapshot_signal_connected: bool = false
var _network_last_safe_render_position: Vector2 = Vector2.ZERO

@export_category("Player Ball-Impact Knockback")
@export_range(0.0, 1.0, 0.05)
var player_ball_impact_knockback_multiplier: float = 0.0
@export var player_ball_impact_full_speed: float = 6000.0

@export_category("Shot / Pass Speed Trail")
@export var speed_trail_start_speed: float = 1200.0
@export var speed_trail_full_speed: float = 7000.0
@export var speed_trail_lifetime: float = 0.32
@export var speed_trail_point_spacing: float = 16.0
@export var speed_trail_max_points: int = 40
@export var speed_trail_min_core_width: float = 7.0
@export var speed_trail_max_core_width: float = 18.0

@export_category("Last Touch Team Trail")
@export var neutral_trail_color: Color = Color(
	0.68, 0.76, 0.86, 1.0
)
@export var red_team_trail_color: Color = Color(
	1.0, 0.22, 0.28, 1.0
)
@export var blue_team_trail_color: Color = Color(
	0.16, 0.52, 1.0, 1.0
)

@export_category("Ball Impact Feel")
@export_range(1.0, 2.0, 0.01)
var impact_pulse_max_scale: float = 1.50
@export_range(0.01, 0.20, 0.005)
var impact_pulse_expand_seconds: float = 0.05
@export_range(0.005, 0.08, 0.005)
var impact_pulse_return_seconds: float = 0.015
@export_range(0.0, 1.0, 0.01)
var impact_camera_shake_strength: float = 0.29
@export var collision_visual_minimum_speed: float = 1500.0
@export var player_contact_visual_minimum_speed: float = 1300.0

@export_category("Kick White Flash")
@export var kick_white_flash_color: Color = Color(
	4.0,
	4.0,
	4.0,
	1.0
)
@export_range(0.002, 0.03, 0.001)
var kick_white_flash_attack_seconds: float = 0.008
@export_range(0.0, 0.03, 0.001)
var kick_white_flash_hold_seconds: float = 0.006
@export_range(0.01, 0.08, 0.001)
var kick_white_flash_release_seconds: float = 0.032

@export_category("Arena Containment")
@export var arena_containment_enabled: bool = true
@export var arena_playable_bounds: Rect2 = Rect2(
	318.0,
	770.0,
	6712.0,
	3460.0
)
@export var arena_goal_mouth_y: Vector2 = Vector2(1727.5, 3272.5)
@export var arena_ball_radius: float = 36.0
@export var arena_goal_escape_margin: float = 2000.0
@export_range(0.0, 1.0, 0.01)
var arena_recovery_bounce: float = 0.78

@export_category("CPU Defensive Own-Goal Prevention")
@export var cpu_defensive_own_goal_prevention_enabled: bool = true
@export var cpu_absolute_own_goal_lock_enabled: bool = true
@export var cpu_defensive_prediction_seconds: float = 2.0
@export var cpu_defensive_goal_mouth_padding: float = 210.0
@export var cpu_defensive_minimum_toward_speed: float = 100.0
@export var cpu_defensive_safe_speed: float = 1650.0
@export var cpu_defensive_lateral_weight: float = 0.55
@export var cpu_own_goal_recovery_field_offset: float = 150.0
@export var cpu_own_goal_emergency_plane_margin: float = 220.0

@export_category("Goal Explosion")
@export var blue_goal_explosion_color: Color = Color(
	0.16, 0.55, 1.0, 1.0
)
@export var red_goal_explosion_color: Color = Color(
	1.0, 0.16, 0.22, 1.0
)
@export var goal_explosion_ball_hide_seconds: float = 5.0

@export_category("Ball Visual Rolling")
@export var visual_roll_enabled: bool = true
@export var visual_roll_auto_center_sprite: bool = true
@export_range(1.0, 256.0, 1.0)
var visual_roll_radius: float = 64.0
@export_range(0.05, 2.0, 0.05)
var visual_roll_speed_multiplier: float = 0.22
@export_range(0.0, 500.0, 1.0)
var visual_roll_minimum_speed: float = 8.0
@export_range(1.0, 100.0, 0.5)
var visual_roll_max_radians_per_second: float = 18.0
@export_range(1.0, 30.0, 0.5)
var visual_roll_velocity_smoothing: float = 10.0

@export_category("Power Strike Visuals")
@export var power_strike_stop_speed: float = 1100.0
@export var power_strike_ball_color: Color = Color(
	1.0,
	0.20,
	0.14,
	1.0
)
@export var power_strike_trail_color: Color = Color(
	1.0,
	0.04,
	0.10,
	1.0
)

@export_category("Curve Shot Trail")
@export var curve_trail_lifetime: float = 0.65
@export var curve_trail_point_spacing: float = 14.0
@export var curve_trail_max_points: int = 48

@export_category("Dead Zone Pass Trail")
@export var time_skip_trail_lifetime: float = 0.7
@export var time_skip_trail_point_spacing: float = 12.0
@export var time_skip_trail_max_points: int = 56

@export_category("Return Tag Visuals")
@export var return_tag_ring_radius: float = 62.0
@export var return_tag_ring_width: float = 7.0
@export var return_tag_orbit_radius: float = 78.0
@export var return_tag_orbit_speed: float = 3.6

@export_category("Snapback Visuals")
@export var snapback_ring_radius: float = 67.0
@export var snapback_ring_width: float = 7.0

@export_category("Collision Sound")
@export var collision_sound: AudioStream
@export var minimum_collision_sound_speed: float = 0.0
@export var collision_sound_cooldown: float = 0.1
@export_range(-80.0, 24.0, 0.1)
var collision_sound_volume_db: float = 10.0
@export_range(0.1, 4.0, 0.01)
var collision_sound_pitch_scale: float = 1.0

var last_touch_peer_id: int = 0
var last_touch_name: String = ""
var last_touch_team: StringName = &""
var last_touch_kind: StringName = &""
var last_touch_incoming_velocity: Vector2 = Vector2.ZERO
var last_touch_outgoing_velocity: Vector2 = Vector2.ZERO
var last_touch_safety_redirected: bool = false
var last_touch_was_cpu: bool = false
var last_red_touch_peer_id: int = 0
var last_red_touch_name: String = ""
var last_blue_touch_peer_id: int = 0
var last_blue_touch_name: String = ""
# Monotonic server-side counter for player contacts. Snapback stores this
# after its kick and cancels safely if anybody touches the ball before recall.
var _player_touch_serial: int = 0
var _nutmeg_bypass_player_instance_id: int = 0
var _nutmeg_bypass_generation: int = 0
var _next_collision_sound_time: float = 0.0
var _had_non_player_contact: bool = false
var _player_contact_ids: Dictionary = {}
var _knockback_reference_speed: float = 0.0
var _previous_physics_velocity: Vector2 = Vector2.ZERO
var _speed_trail_point_times: Array[float] = []
var _current_speed_trail_color: Color = Color(
	0.68,
	0.76,
	0.86,
	1.0
)
var _current_speed_trail_team: StringName = &""
# Exact equipped team color of the player who last touched the ball.  Keep this
# separate from _current_speed_trail_color because temporary ability VFX may
# override the visible trail and then need to restore ownership color.
var _last_touch_visual_color: Color = Color(0.72, 0.84, 1.0, 1.0)
var _current_glow_fx_peer_id: int = 0
var _current_glow_fx_name: String = ""
var power_strike_visual_active: bool = false
var power_strike_haaland_visual_active: bool = false
var curve_shot_active: bool = false
var curve_shot_turn_direction: float = 1.0
var curve_shot_time_remaining: float = 0.0
var curve_shot_steering_speed: float = 0.0
var curve_shot_minimum_speed: float = 0.0
var curve_shot_obstacle_active: bool = false
var curve_shot_obstacle_position: Vector2 = Vector2.ZERO
var curve_shot_original_direction: Vector2 = Vector2.ZERO
var curve_shot_avoidance_side: float = 0.0
var curve_shot_avoidance_clearance: float = 0.0
var curve_shot_obstacle_pass_margin: float = 0.0
var curve_shot_visual_active: bool = false
var _curve_trail_point_times: Array[float] = []
var time_skip_pass_active: bool = false
var time_skip_fast_time_remaining: float = 0.0
var time_skip_slow_speed: float = 0.0
var time_skip_stopping_deceleration: float = 0.0
var time_skip_stop_speed: float = 0.0
var time_skip_slow_phase_started: bool = false
var time_skip_visual_active: bool = false
var _time_skip_trail_point_times: Array[float] = []
var _goal_explosion_generation: int = 0
var _goal_ball_visual_hide_active: bool = false
var _goal_ball_visual_restore_deadline_usec: int = 0
var _ball_sprite_base_scale: Vector2 = Vector2.ONE
var _ball_sprite_default_scale: Vector2 = Vector2.ONE
var _ball_visual_size_multiplier: float = 1.0
var _large_team_size_multiplier: float = 1.0
var _collision_shape_default_scale: Vector2 = Vector2.ONE
var _arena_ball_radius_default: float = 36.0
var _ball_sprite_base_rotation: float = 0.0
var _ball_sprite_base_offset: Vector2 = Vector2.ZERO
var _ball_visual_roll_rotation: float = 0.0
var _ball_visual_roll_direction: float = 1.0
var _ball_visual_roll_last_motion: Vector2 = Vector2.ZERO
var _ball_visual_roll_smoothed_speed: float = 0.0
var _ball_visual_roll_initialized: bool = false
var _ball_impact_tween: Tween
var _goal_implosion_tween: Tween
var _kick_white_flash_tween: Tween
var _kick_white_flash_active: bool = false
var _kick_white_flash_start_color: Color = Color.WHITE
var _kick_white_flash_base_color: Color = Color.WHITE
var return_tag_owner_peer_id: int = 0
var return_tag_owner_name: String = ""
var return_tag_team: StringName = &""
var return_tag_expires_at: float = 0.0
var return_tag_visual_active: bool = false
var return_tag_visual_remaining: float = 0.0
var return_tag_visual_duration: float = 0.0
var _return_tag_visual_elapsed: float = 0.0
var snapback_mark_owner_peer_id: int = 0
var snapback_mark_team: StringName = &""
var snapback_mark_visual_active: bool = false
var snapback_mark_visual_remaining: float = 0.0
var snapback_mark_visual_duration: float = 0.0
var _snapback_mark_visual_elapsed: float = 0.0
var snapback_recall_curve_active: bool = false
var snapback_recall_target_peer_id: int = 0
var snapback_recall_target_team: StringName = &""
var snapback_recall_time_remaining: float = 0.0
var snapback_recall_speed: float = 0.0
var snapback_recall_lead_seconds: float = 0.0
var snapback_recall_turn_rate: float = 0.0

@onready var collision_audio: AudioStreamPlayer = $CollisionAudio
@onready var contact_audio: AudioStreamPlayer2D = $ContactAudio
@onready var ball_sprite: Sprite2D = $Ball
@onready var ball_collision_shape: CollisionShape2D = $CollisionShape2D
@onready var power_strike_flames: CPUParticles2D = (
	$PowerStrikeFlames
)
@onready var power_strike_embers: CPUParticles2D = (
	$PowerStrikeEmbers
)
@onready var speed_trail_glow: Line2D = $SpeedTrailGlow
@onready var speed_trail_core: Line2D = $SpeedTrailCore
@onready var speed_trail_particles: CPUParticles2D = $SpeedTrailParticles
@onready var speed_trail_embers: CPUParticles2D = $SpeedTrailEmbers
@onready var curve_trail: Line2D = $CurveTrail
@onready var time_skip_trail: Line2D = $TimeSkipPassTrail
@onready var ball_glow_fx: Node2D = $BallGlowFX


func begin_nutmeg_bypass(opponent: FootballPlayer, duration: float) -> void:
	if opponent == null:
		return
	_nutmeg_bypass_generation += 1
	var generation: int = _nutmeg_bypass_generation
	_nutmeg_bypass_player_instance_id = int(opponent.get_instance_id())
	_clear_nutmeg_bypass_after(generation, maxf(0.01, duration))


func is_nutmeg_bypass_target(player: FootballPlayer) -> bool:
	return (
		player != null
		and _nutmeg_bypass_player_instance_id
		== int(player.get_instance_id())
	)


func _clear_nutmeg_bypass_after(
	generation: int,
	duration: float
) -> void:
	await get_tree().create_timer(duration).timeout
	if generation == _nutmeg_bypass_generation:
		_nutmeg_bypass_player_instance_id = 0


func _ready() -> void:
	_remember_valid_physics_state(
		global_transform,
		linear_velocity,
		angular_velocity
	)
	# Capture the authored physics size before local visual style setup calls the
	# shared size multiplier helper. Otherwise that helper would treat Vector2.ONE
	# as the base and silently erase the ball scene's collision scale.
	if ball_collision_shape != null:
		_collision_shape_default_scale = ball_collision_shape.scale
	_arena_ball_radius_default = arena_ball_radius
	if ball_sprite != null:
		if visual_roll_auto_center_sprite:
			_center_ball_sprite_pivot()
		_apply_saved_local_ball_style()
		_ball_sprite_base_scale = ball_sprite.scale
		_ball_sprite_default_scale = ball_sprite.scale
		_ball_sprite_base_rotation = ball_sprite.global_rotation
		_ball_sprite_base_offset = ball_sprite.offset
	_reset_ball_visual_roll(true)
	_apply_power_strike_visual(false)
	_apply_curve_shot_visual(false, true)
	_apply_time_skip_visual(false, true)
	_apply_last_touch_team_trail(&"")
	_apply_last_touch_player_fx(Color(0.72, 0.84, 1.0, 1.0))

	# Only the server simulates ball physics. Clients receive authoritative
	# snapshots and render toward them explicitly at the display frame rate.
	if multiplayer.is_server():
		network_position = position
		network_linear_velocity = linear_velocity
		network_rotation = rotation
		network_angular_velocity = angular_velocity
	else:
		freeze = true
		physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		reset_physics_interpolation()
		_network_target_position = position
		_network_target_velocity = linear_velocity
		_network_target_rotation = rotation
		_network_target_angular_velocity = angular_velocity
		# Treat the default replicated values as already observed so a client does
		# not briefly jump to Vector2.ZERO before the first server snapshot arrives.
		_network_last_snapshot_position = network_position
		_network_last_snapshot_velocity = network_linear_velocity
		_network_last_snapshot_rotation = network_rotation
		_network_last_snapshot_angular_velocity = network_angular_velocity
		_network_motion_initialized = true
		_network_last_safe_render_position = position
		_connect_network_motion_snapshot_signal()


func _apply_saved_local_ball_style() -> void:
	var config := ConfigFile.new()
	var style := BALL_STYLE_THEODORE
	if config.load(LOCAL_SETTINGS_PATH) == OK:
		style = StringName(
			str(config.get_value("display", "ball_appearance", "theodore"))
		)
	apply_local_ball_style(style)


static func get_ball_appearance_variants() -> Array[Dictionary]:
	# Duplicate the dictionaries so UI code can safely read/extend its local copy
	# without mutating the canonical gameplay catalog.
	return BALL_APPEARANCE_VARIANTS.duplicate(true)


static func get_ball_appearance_variant(style: StringName) -> Dictionary:
	for variant: Dictionary in BALL_APPEARANCE_VARIANTS:
		if StringName(variant.get("style", &"")) == style:
			return variant
	return BALL_APPEARANCE_VARIANTS[0]


func apply_local_ball_style(style: StringName) -> void:
	if ball_sprite == null:
		return
	var variant: Dictionary = get_ball_appearance_variant(style)
	ball_sprite.texture = variant.get("texture", THEODORE_BALL_TEXTURE) as Texture2D
	ball_sprite.offset = variant.get("sprite_offset", THEODORE_BALL_OFFSET) as Vector2
	var base_scale: Vector2 = variant.get(
		"sprite_scale",
		THEODORE_BALL_SCALE
	) as Vector2
	_ball_sprite_default_scale = base_scale
	_apply_effective_size_multiplier()
	_ball_sprite_base_offset = ball_sprite.offset


func set_fun_size_multiplier(multiplier: float) -> void:
	_ball_visual_size_multiplier = clampf(multiplier, 1.0, 2.0)
	_apply_effective_size_multiplier()


func set_large_team_size_multiplier(multiplier: float) -> void:
	_large_team_size_multiplier = clampf(multiplier, 0.5, 1.0)
	_apply_effective_size_multiplier()


func _apply_effective_size_multiplier() -> void:
	var effective_multiplier := (
		_ball_visual_size_multiplier * _large_team_size_multiplier
	)
	if ball_collision_shape != null:
		ball_collision_shape.scale = (
			_collision_shape_default_scale * effective_multiplier
		)
	arena_ball_radius = _arena_ball_radius_default * effective_multiplier
	_ball_sprite_base_scale = _ball_sprite_default_scale * effective_multiplier
	if ball_sprite != null:
		ball_sprite.scale = _ball_sprite_base_scale
	var ball_shadow: Node = get_node_or_null("BallShadow")
	if ball_shadow != null and ball_shadow.has_method("set_ball_size_multiplier"):
		ball_shadow.call("set_ball_size_multiplier", effective_multiplier)
	if ball_glow_fx != null and ball_glow_fx.has_method("set_size_multiplier"):
		ball_glow_fx.call("set_size_multiplier", effective_multiplier)


func _process(delta: float) -> void:
	if not multiplayer.is_server():
		_update_client_network_motion(delta)
		_repair_invalid_client_physics_state()
	# The sprite's local spin is visual-only and intentionally runs at the
	# render rate. The Sprite2D has interpolation disabled locally, while the
	# RigidBody2D parent position remains physics-interpolated.
	_repair_stale_ball_render_visibility()
	_update_ball_visual_roll(delta)
	_update_return_tag_visual(delta)
	_update_snapback_mark_visual(delta)
	if (
		multiplayer.is_server()
		and return_tag_owner_peer_id > 0
		and _server_time_seconds() >= return_tag_expires_at
	):
		clear_return_tag()


func _update_client_network_motion(delta: float) -> void:
	if not _network_snapshot_signal_connected:
		var received_new_snapshot: bool = (
			network_position != _network_last_snapshot_position
			or network_linear_velocity != _network_last_snapshot_velocity
			or not is_equal_approx(
				network_rotation,
				_network_last_snapshot_rotation
			)
			or not is_equal_approx(
				network_angular_velocity,
				_network_last_snapshot_angular_velocity
			)
		)
		if received_new_snapshot:
			_accept_network_motion_snapshot()
		else:
			_network_snapshot_age += maxf(0.0, delta)
	else:
		_network_snapshot_age += maxf(0.0, delta)

	linear_velocity = _network_target_velocity
	angular_velocity = _network_target_angular_velocity
	if not _network_motion_initialized:
		position = _network_target_position
		rotation = _network_target_rotation
		_network_motion_initialized = true
		_network_last_safe_render_position = position
		return

	var extrapolation_seconds := _get_network_prediction_seconds()
	var desired_position: Vector2 = (
		_network_target_position
		+ _network_target_velocity * extrapolation_seconds
	)
	if (desired_position - position).length() >= NETWORK_BALL_TELEPORT_SNAP_DISTANCE:
		position = _network_target_position
		rotation = _network_target_rotation
		_network_last_safe_render_position = position
		return

	var blend: float = 1.0 - exp(
		-NETWORK_BALL_SMOOTHING_RESPONSE * maxf(0.0, delta)
	)
	blend = clampf(blend, 0.0, 1.0)
	position = position.lerp(desired_position, blend)
	var desired_rotation: float = (
		_network_target_rotation
		+ _network_target_angular_velocity * extrapolation_seconds
	)
	rotation = lerp_angle(rotation, desired_rotation, blend)
	if _physics_vector_is_sane(position):
		_network_last_safe_render_position = position


func _connect_network_motion_snapshot_signal() -> void:
	var synchronizer := get_node_or_null(
		"MultiplayerSynchronizer"
	) as MultiplayerSynchronizer
	if synchronizer == null:
		return
	if not synchronizer.synchronized.is_connected(
		_on_network_motion_synchronized
	):
		synchronizer.synchronized.connect(
			_on_network_motion_synchronized
		)
	_network_snapshot_signal_connected = true


func _on_network_motion_synchronized() -> void:
	if multiplayer.is_server():
		return
	_accept_network_motion_snapshot()


func _accept_network_motion_snapshot() -> void:
	var arrival_interval := _network_snapshot_age
	if (
		arrival_interval > 0.001
		and arrival_interval <= NETWORK_BALL_SNAPSHOT_INTERVAL_MAX_SAMPLE_SECONDS
	):
		_network_smoothed_snapshot_interval = lerpf(
			_network_smoothed_snapshot_interval,
			arrival_interval,
			NETWORK_BALL_SNAPSHOT_INTERVAL_BLEND
		)
	_network_last_snapshot_position = network_position
	_network_last_snapshot_velocity = network_linear_velocity
	_network_last_snapshot_rotation = network_rotation
	_network_last_snapshot_angular_velocity = network_angular_velocity
	_network_target_position = network_position
	_network_target_velocity = network_linear_velocity
	_network_target_rotation = network_rotation
	_network_target_angular_velocity = network_angular_velocity
	_network_snapshot_age = 0.0


func _get_network_prediction_seconds() -> float:
	var prediction_horizon := clampf(
		maxf(
			NETWORK_BALL_EXTRAPOLATION_SECONDS,
			_network_smoothed_snapshot_interval
			* NETWORK_BALL_SNAPSHOT_INTERVAL_MULTIPLIER
			+ NETWORK_BALL_SNAPSHOT_JITTER_MARGIN_SECONDS
		),
		NETWORK_BALL_EXTRAPOLATION_SECONDS,
		NETWORK_BALL_MAX_EXTRAPOLATION_SECONDS
	)
	if _network_snapshot_age <= prediction_horizon:
		return _network_snapshot_age

	# A stale ball snapshot should slow down smoothly rather than suddenly stop,
	# but the tail is intentionally short because ball collisions can change
	# velocity much more abruptly than player movement.
	var stale_age := _network_snapshot_age - prediction_horizon
	var decay_seconds := maxf(0.001, NETWORK_BALL_STALE_DECAY_SECONDS)
	return prediction_horizon + decay_seconds * (
		1.0 - exp(-stale_age / decay_seconds)
	)


func _reset_client_network_motion(
	reset_position: Vector2,
	reset_velocity: Vector2 = Vector2.ZERO,
	reset_rotation: float = 0.0,
	reset_angular_velocity: float = 0.0
) -> void:
	if multiplayer.is_server():
		return
	global_position = reset_position
	linear_velocity = reset_velocity
	angular_velocity = reset_angular_velocity
	rotation = reset_rotation
	network_position = reset_position
	network_linear_velocity = reset_velocity
	network_rotation = reset_rotation
	network_angular_velocity = reset_angular_velocity
	_network_target_position = reset_position
	_network_target_velocity = reset_velocity
	_network_target_rotation = reset_rotation
	_network_target_angular_velocity = reset_angular_velocity
	_network_last_snapshot_position = reset_position
	_network_last_snapshot_velocity = reset_velocity
	_network_last_snapshot_rotation = reset_rotation
	_network_last_snapshot_angular_velocity = reset_angular_velocity
	_network_snapshot_age = 0.0
	_network_smoothed_snapshot_interval = 1.0 / 60.0
	_network_motion_initialized = true
	_network_last_safe_render_position = reset_position
	reset_physics_interpolation()


func _physics_process(_delta: float) -> void:
	# These trails sample the authoritative physics position. Sampling them
	# from _process mixed render and physics clocks and caused visible stepping.
	_update_speed_trail()
	_update_curve_trail()
	_update_time_skip_trail()


func play_goal_explosion(
	scoring_team: StringName,
	ball_hide_seconds: float = -1.0,
	cosmetic_id: String = "goal_explosion.classic",
	color_index: int = FootballCosmeticInventory.PLAYER_SKIN_ORIGINAL_COLOR,
	hold_arena_until_goal_replay: bool = false
) -> void:
	if not multiplayer.is_server():
		return
	var hide_seconds := (
		goal_explosion_ball_hide_seconds
		if ball_hide_seconds < 0.0
		else ball_hide_seconds
	)
	var safe_cosmetic_id: String = str(
		FootballCosmeticInventory.sanitize_catalog_network_loadout({
			"goal_explosion": cosmetic_id,
		}).get("goal_explosion", "goal_explosion.classic")
	)
	var safe_color_index: int = (
		FootballCosmeticInventory.sanitize_goal_explosion_color_index(color_index)
	)
	_receive_goal_explosion.rpc(
		scoring_team,
		hide_seconds,
		safe_cosmetic_id,
		safe_color_index,
		hold_arena_until_goal_replay
	)


@rpc("authority", "call_local", "reliable")
func _receive_goal_explosion(
	scoring_team: StringName,
	ball_hide_seconds: float,
	cosmetic_id: String,
	color_index: int,
	hold_arena_until_goal_replay: bool
) -> void:
	if ball_sprite == null or get_parent() == null:
		return

	_goal_explosion_generation += 1
	var generation := _goal_explosion_generation
	_goal_ball_visual_hide_active = true
	_goal_ball_visual_restore_deadline_usec = (
		Time.get_ticks_usec()
		+ int(round((maxf(0.05, ball_hide_seconds) + 0.75) * 1000000.0))
	)
	var color := (
		red_goal_explosion_color
		if scoring_team == &"red"
		else blue_goal_explosion_color
	)
	var effect := GoalExplosionFX.new()
	get_parent().add_child(effect)
	effect.global_position = global_position
	effect.setup(
		color,
		cosmetic_id,
		color_index,
		hold_arena_until_goal_replay,
		ball_hide_seconds
	)
	_add_goal_camera_punch()

	power_strike_flames.emitting = false
	power_strike_embers.emitting = false
	_clear_speed_trail()
	_apply_curve_shot_visual(false, true)
	_apply_time_skip_visual(false, true)
	if multiplayer.is_server():
		clear_return_tag()
		clear_snapback_mark()
		_stop_snapback_recall_curve()
	_implode_ball_for_goal(effect.team_color, generation)
	_restore_ball_after_goal_explosion(generation, ball_hide_seconds)


func _implode_ball_for_goal(
	color: Color,
	generation: int
) -> void:
	if _goal_implosion_tween != null:
		_goal_implosion_tween.kill()
	_stop_kick_white_flash()
	ball_sprite.show()
	ball_sprite.scale = _ball_sprite_base_scale * 1.35
	ball_sprite.modulate = color.lightened(0.42)
	_goal_implosion_tween = create_tween()
	_goal_implosion_tween.set_parallel(true)
	_goal_implosion_tween.tween_property(
		ball_sprite,
		"scale",
		Vector2.ZERO,
		0.14
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	_goal_implosion_tween.tween_property(
		ball_sprite,
		"modulate:a",
		0.0,
		0.12
	)
	await _goal_implosion_tween.finished
	if generation == _goal_explosion_generation:
		ball_sprite.hide()


func _restore_ball_after_goal_explosion(
	generation: int,
	ball_hide_seconds: float
) -> void:
	await get_tree().create_timer(
		maxf(0.05, ball_hide_seconds)
	).timeout
	if generation == _goal_explosion_generation:
		_restore_ball_render_visibility()


func _restore_ball_render_visibility() -> void:
	if (
		_goal_implosion_tween != null
		and _goal_implosion_tween.is_valid()
	):
		_goal_implosion_tween.kill()
	_goal_implosion_tween = null
	_goal_ball_visual_hide_active = false
	_goal_ball_visual_restore_deadline_usec = 0
	if not is_instance_valid(ball_sprite):
		return
	ball_sprite.scale = _ball_sprite_base_scale
	ball_sprite.offset = _ball_sprite_base_offset
	ball_sprite.modulate = _get_ball_base_modulate()
	ball_sprite.show()


func _repair_stale_ball_render_visibility() -> void:
	if not is_instance_valid(ball_sprite):
		return
	if _goal_ball_visual_hide_active:
		if (
			_goal_ball_visual_restore_deadline_usec > 0
			and Time.get_ticks_usec()
			>= _goal_ball_visual_restore_deadline_usec
		):
			_restore_ball_render_visibility()
		return
	if (
		not ball_sprite.visible
		or ball_sprite.modulate.a <= 0.01
		or ball_sprite.scale.length_squared() <= 0.0001
	):
		_restore_ball_render_visibility()


func _stop_arena_goal_explosions_for_replay() -> void:
	var tree := get_tree()
	if tree == null:
		return
	for effect_variant in tree.get_nodes_in_group(
		"goal_explosion_hold_until_replay"
	):
		var effect := effect_variant as Node
		if is_instance_valid(effect):
			effect.queue_free()


func prepare_for_goal_replay() -> void:
	if not multiplayer.is_server():
		return
	_receive_prepare_for_goal_replay.rpc()


@rpc("authority", "call_local", "reliable")
func _receive_prepare_for_goal_replay() -> void:
	_stop_arena_goal_explosions_for_replay()
	_goal_explosion_generation += 1
	_reset_ball_impact_animation()
	_restore_ball_render_visibility()
	if ball_sprite == null:
		return
	power_strike_flames.emitting = false
	power_strike_embers.emitting = false
	_clear_speed_trail()
	_apply_curve_shot_visual(false, true)
	_apply_time_skip_visual(false, true)


func _integrate_forces(
	state: PhysicsDirectBodyState2D
) -> void:
	if not multiplayer.is_server():
		return

	_repair_invalid_physics_state(state)
	_repair_horizontal_wall_contact_tangent(state)
	var integration_entry_velocity := state.linear_velocity
	if not _pending_fun_kick_velocity_bonus.is_zero_approx():
		state.linear_velocity += _pending_fun_kick_velocity_bonus
		_pending_fun_kick_velocity_bonus = Vector2.ZERO
	_update_snapback_recall_curve(state)
	_update_curve_shot(state)
	_update_time_skip_pass(state)
	var velocity := state.linear_velocity
	_knockback_reference_speed = velocity.length()
	_update_player_contacts(state, velocity)
	_apply_cpu_own_goal_hard_lock(state)
	velocity = state.linear_velocity
	_update_collision_sound(state, velocity.length())

	if velocity.length() > maximum_speed:
		state.linear_velocity = (
			velocity.normalized()
			* maximum_speed
		)
	_apply_arena_containment(state, integration_entry_velocity)
	_repair_invalid_physics_state(state)
	_previous_physics_velocity = state.linear_velocity
	_update_power_strike_visual_from_speed(
		state.linear_velocity.length()
	)
	_publish_server_network_motion_state(state)


func _publish_server_network_motion_state(
	state: PhysicsDirectBodyState2D
) -> void:
	# Keep all ball motion fields from the same authoritative physics step so
	# clients cannot combine render-frame values from different simulation ticks.
	network_position = state.transform.origin
	network_linear_velocity = state.linear_velocity
	network_rotation = state.transform.get_rotation()
	network_angular_velocity = state.angular_velocity


func _physics_vector_is_sane(
	value: Vector2,
	maximum_component: float = PHYSICS_SANITY_MAX_COORDINATE
) -> bool:
	return (
		is_finite(value.x)
		and is_finite(value.y)
		and absf(value.x) <= maximum_component
		and absf(value.y) <= maximum_component
	)


func _physics_transform_is_sane(value: Transform2D) -> bool:
	return (
		_physics_vector_is_sane(value.origin)
		and _physics_vector_is_sane(value.x, 1000.0)
		and _physics_vector_is_sane(value.y, 1000.0)
	)


func _remember_valid_physics_state(
	value_transform: Transform2D,
	value_velocity: Vector2,
	value_angular_velocity: float
) -> void:
	if not _physics_transform_is_sane(value_transform):
		return
	_physics_sanity_last_transform = value_transform
	_physics_sanity_last_velocity = (
		value_velocity
		if _physics_vector_is_sane(
			value_velocity,
			PHYSICS_SANITY_MAX_SPEED
		)
		else Vector2.ZERO
	)
	_physics_sanity_last_angular_velocity = (
		value_angular_velocity
		if is_finite(value_angular_velocity)
		else 0.0
	)
	_physics_sanity_initialized = true


func _repair_invalid_physics_state(
	state: PhysicsDirectBodyState2D
) -> bool:
	var transform_valid := _physics_transform_is_sane(state.transform)
	if transform_valid and _physics_sanity_initialized:
		transform_valid = (
			state.transform.origin.distance_to(
				_physics_sanity_last_transform.origin
			)
			<= PHYSICS_SANITY_MAX_SINGLE_STEP_DISPLACEMENT
		)
	var velocity_valid := _physics_vector_is_sane(
		state.linear_velocity,
		PHYSICS_SANITY_MAX_SPEED
	)
	var angular_valid := is_finite(state.angular_velocity)
	if transform_valid and velocity_valid and angular_valid:
		_remember_valid_physics_state(
			state.transform,
			state.linear_velocity,
			state.angular_velocity
		)
		return false

	if not _physics_sanity_initialized:
		var fallback_origin := arena_playable_bounds.get_center()
		if _physics_vector_is_sane(global_position):
			fallback_origin = global_position
		_physics_sanity_last_transform = Transform2D(0.0, fallback_origin)
		_physics_sanity_last_velocity = Vector2.ZERO
		_physics_sanity_last_angular_velocity = 0.0
		_physics_sanity_initialized = true

	if not transform_valid:
		state.transform = _physics_sanity_last_transform
	if not velocity_valid:
		state.linear_velocity = Vector2.ZERO
	else:
		state.linear_velocity = state.linear_velocity.limit_length(
			PHYSICS_SANITY_MAX_SPEED
		)
	if not angular_valid:
		state.angular_velocity = 0.0
	_pending_fun_kick_velocity_bonus = Vector2.ZERO
	_remember_valid_physics_state(
		state.transform,
		state.linear_velocity,
		state.angular_velocity
	)
	return true


func _repair_invalid_client_physics_state() -> bool:
	var current_transform := global_transform
	var transform_valid := _physics_transform_is_sane(current_transform)
	if transform_valid and _physics_sanity_initialized:
		transform_valid = (
			current_transform.origin.distance_to(
				_physics_sanity_last_transform.origin
			)
			<= PHYSICS_SANITY_MAX_SINGLE_STEP_DISPLACEMENT
		)
	var velocity_valid := _physics_vector_is_sane(
		linear_velocity,
		PHYSICS_SANITY_MAX_SPEED
	)
	var angular_valid := is_finite(angular_velocity)
	if transform_valid and velocity_valid and angular_valid:
		_remember_valid_physics_state(
			current_transform,
			linear_velocity,
			angular_velocity
		)
		return false
	if not _physics_sanity_initialized:
		_physics_sanity_last_transform = Transform2D(
			0.0,
			arena_playable_bounds.get_center()
		)
		_physics_sanity_last_velocity = Vector2.ZERO
		_physics_sanity_last_angular_velocity = 0.0
		_physics_sanity_initialized = true
	if not transform_valid:
		global_transform = _physics_sanity_last_transform
	if not velocity_valid:
		linear_velocity = Vector2.ZERO
	if not angular_valid:
		angular_velocity = 0.0
	return true


func _apply_arena_containment(
	state: PhysicsDirectBodyState2D,
	integration_entry_velocity: Vector2 = Vector2.ZERO
) -> void:
	if not arena_containment_enabled:
		return
	var bounds := arena_playable_bounds.abs()
	if bounds.size.x <= 0.0 or bounds.size.y <= 0.0:
		return

	var radius := maxf(0.0, arena_ball_radius)
	var minimum_x := bounds.position.x + radius
	var maximum_x := bounds.end.x - radius
	var minimum_y := bounds.position.y + radius
	var maximum_y := bounds.end.y - radius
	var position := state.transform.origin
	var velocity := state.linear_velocity
	var recovered := false

	if position.y < minimum_y:
		position.y = minimum_y
		velocity = _preserve_horizontal_wall_tangent(
			integration_entry_velocity,
			velocity
		)
		velocity.y = absf(velocity.y) * arena_recovery_bounce
		recovered = true
	elif position.y > maximum_y:
		position.y = maximum_y
		velocity = _preserve_horizontal_wall_tangent(
			integration_entry_velocity,
			velocity
		)
		velocity.y = -absf(velocity.y) * arena_recovery_bounce
		recovered = true

	var inside_goal_mouth := (
		position.y >= arena_goal_mouth_y.x
		and position.y <= arena_goal_mouth_y.y
	)
	if not inside_goal_mouth:
		if position.x < minimum_x:
			position.x = minimum_x
			velocity.x = absf(velocity.x) * arena_recovery_bounce
			recovered = true
		elif position.x > maximum_x:
			position.x = maximum_x
			velocity.x = -absf(velocity.x) * arena_recovery_bounce
			recovered = true
	else:
		# The goal mouth must remain open long enough for its Area2D to score.
		# If the Area is ever skipped at extreme speed, recover only after the
		# ball has travelled completely behind the goal trigger.
		var escape_margin := maxf(0.0, arena_goal_escape_margin)
		if position.x < bounds.position.x - escape_margin:
			position.x = minimum_x
			velocity.x = absf(velocity.x) * arena_recovery_bounce
			recovered = true
		elif position.x > bounds.end.x + escape_margin:
			position.x = maximum_x
			velocity.x = -absf(velocity.x) * arena_recovery_bounce
			recovered = true

	if not recovered:
		return
	var corrected_transform := state.transform
	corrected_transform.origin = position
	state.transform = corrected_transform
	state.linear_velocity = velocity
	state.angular_velocity *= 0.92


func _preserve_horizontal_wall_tangent(
	previous_velocity: Vector2,
	current_velocity: Vector2
) -> Vector2:
	if (
		absf(previous_velocity.x) < 1.0
		or absf(current_velocity.x) < 1.0
		or signf(previous_velocity.x) == signf(current_velocity.x)
	):
		return current_velocity
	var corrected := current_velocity
	corrected.x = absf(current_velocity.x) * signf(previous_velocity.x)
	return corrected


func _repair_horizontal_wall_contact_tangent(
	state: PhysicsDirectBodyState2D
) -> void:
	if (
		_previous_physics_velocity.length_squared() < 1.0
		or state.get_contact_count() <= 0
	):
		return
	var bounds := arena_playable_bounds.abs()
	var radius := maxf(0.0, arena_ball_radius)
	var position := state.transform.origin
	var minimum_y := bounds.position.y + radius
	var maximum_y := bounds.end.y - radius
	var near_top := position.y <= minimum_y + radius * 2.0
	var near_bottom := position.y >= maximum_y - radius * 2.0
	if not near_top and not near_bottom:
		return
	var has_wall_contact := false
	for contact_index in range(state.get_contact_count()):
		var collider := state.get_contact_collider_object(contact_index)
		if collider != null and not collider is FootballPlayer:
			has_wall_contact = true
			break
	if not has_wall_contact:
		return
	var current_velocity := state.linear_velocity
	var bounced_from_top := (
		near_top
		and _previous_physics_velocity.y < -1.0
		and current_velocity.y > 1.0
	)
	var bounced_from_bottom := (
		near_bottom
		and _previous_physics_velocity.y > 1.0
		and current_velocity.y < -1.0
	)
	if not bounced_from_top and not bounced_from_bottom:
		return
	state.linear_velocity = _preserve_horizontal_wall_tangent(
		_previous_physics_velocity,
		current_velocity
	)


func _update_curve_shot(
	state: PhysicsDirectBodyState2D
) -> void:
	if not curve_shot_active:
		return

	curve_shot_time_remaining = maxf(
		0.0,
		curve_shot_time_remaining - state.step
	)
	var velocity := state.linear_velocity
	if (
		curve_shot_time_remaining <= 0.0
		or velocity.length() < curve_shot_minimum_speed
	):
		_stop_curve_shot()
		return

	var frame_turn := 0.0
	if curve_shot_obstacle_active:
		frame_turn = _get_obstacle_curve_turn(
			velocity,
			state.step
		)
	else:
		frame_turn = (
			curve_shot_turn_direction
			* maxf(0.0, curve_shot_steering_speed)
			* state.step
		)
	state.linear_velocity = velocity.rotated(frame_turn)


func _get_obstacle_curve_turn(
	velocity: Vector2,
	delta: float
) -> float:
	var original_direction := curve_shot_original_direction.normalized()
	if original_direction.is_zero_approx():
		curve_shot_obstacle_active = false
		return 0.0

	var passed_distance := (
		global_position - curve_shot_obstacle_position
	).dot(original_direction)
	var has_passed_blocker := (
		passed_distance
		>= maxf(0.0, curve_shot_obstacle_pass_margin)
	)
	var desired_direction := original_direction
	if not has_passed_blocker:
		var perpendicular := Vector2(
			-original_direction.y,
			original_direction.x
		)
		var waypoint := (
			curve_shot_obstacle_position
			+ perpendicular
			* curve_shot_avoidance_side
			* maxf(0.0, curve_shot_avoidance_clearance)
		)
		desired_direction = global_position.direction_to(waypoint)

	if desired_direction.is_zero_approx():
		return 0.0

	var angle_error := velocity.normalized().angle_to(
		desired_direction
	)
	var maximum_turn := (
		maxf(0.0, curve_shot_steering_speed)
		* maxf(0.0, delta)
	)
	if has_passed_blocker and absf(angle_error) <= 0.035:
		_stop_curve_shot()
		return 0.0
	return clampf(angle_error, -maximum_turn, maximum_turn)


func start_curve_shot(
	turn_direction: float,
	duration: float,
	steering_radians_per_second: float,
	minimum_speed: float,
	obstacle_position: Vector2 = Vector2.ZERO,
	original_direction: Vector2 = Vector2.ZERO,
	avoidance_side: float = 0.0,
	avoidance_clearance: float = 0.0,
	obstacle_pass_margin: float = 0.0
) -> void:
	if not multiplayer.is_server():
		return

	curve_shot_turn_direction = clampf(
		turn_direction,
		-1.0,
		1.0
	)
	curve_shot_time_remaining = maxf(0.0, duration)
	curve_shot_steering_speed = maxf(
		0.0,
		steering_radians_per_second
	)
	curve_shot_minimum_speed = maxf(0.0, minimum_speed)
	curve_shot_obstacle_position = obstacle_position
	curve_shot_original_direction = original_direction.normalized()
	curve_shot_avoidance_side = signf(avoidance_side)
	curve_shot_avoidance_clearance = maxf(
		0.0,
		avoidance_clearance
	)
	curve_shot_obstacle_pass_margin = maxf(
		0.0,
		obstacle_pass_margin
	)
	curve_shot_obstacle_active = (
		not curve_shot_original_direction.is_zero_approx()
		and not is_zero_approx(curve_shot_avoidance_side)
		and curve_shot_avoidance_clearance > 0.0
	)
	curve_shot_active = (
		curve_shot_time_remaining > 0.0
		and curve_shot_steering_speed > 0.0
	)
	_set_curve_shot_visual(curve_shot_active)


func start_time_skip_pass(
	direction: Vector2,
	initial_speed: float,
	fast_duration: float,
	slow_speed: float,
	stopping_deceleration: float,
	stop_speed: float,
	peer_id: int,
	player_name: String,
	player_team: StringName
) -> void:
	if not multiplayer.is_server():
		return

	var safe_direction := direction.normalized()
	if safe_direction.is_zero_approx():
		return

	var target_velocity := (
		safe_direction * maxf(0.0, initial_speed)
	)
	var kick_impulse := (
		(target_velocity - linear_velocity)
		* maxf(0.001, mass)
	)
	register_kick(
		peer_id,
		player_name,
		player_team,
		kick_impulse
	)
	_stop_curve_shot()
	_set_power_strike_visual(false)
	linear_velocity = target_velocity
	angular_velocity = 0.0
	sleeping = false

	time_skip_fast_time_remaining = maxf(0.0, fast_duration)
	time_skip_slow_speed = maxf(0.0, slow_speed)
	time_skip_stopping_deceleration = maxf(
		0.0,
		stopping_deceleration
	)
	time_skip_stop_speed = maxf(0.0, stop_speed)
	time_skip_slow_phase_started = false
	time_skip_pass_active = target_velocity.length() > 0.0
	_set_time_skip_visual(time_skip_pass_active)


func _update_time_skip_pass(
	state: PhysicsDirectBodyState2D
) -> void:
	if not time_skip_pass_active:
		return

	if time_skip_fast_time_remaining > 0.0:
		time_skip_fast_time_remaining = maxf(
			0.0,
			time_skip_fast_time_remaining - state.step
		)
		if time_skip_fast_time_remaining > 0.0:
			return

	var velocity := state.linear_velocity
	var speed := velocity.length()
	if not time_skip_slow_phase_started:
		time_skip_slow_phase_started = true
		speed = minf(speed, time_skip_slow_speed)
	elif time_skip_stopping_deceleration > 0.0:
		speed = move_toward(
			speed,
			0.0,
			time_skip_stopping_deceleration * state.step
		)

	if (
		speed <= time_skip_stop_speed
		or velocity.is_zero_approx()
	):
		state.linear_velocity = Vector2.ZERO
		state.angular_velocity = 0.0
		_stop_time_skip_pass()
		return

	state.linear_velocity = velocity.normalized() * speed


func _stop_time_skip_pass() -> void:
	var was_active := time_skip_pass_active
	time_skip_pass_active = false
	time_skip_fast_time_remaining = 0.0
	time_skip_slow_phase_started = false
	if was_active:
		_set_time_skip_visual(false)


func _stop_curve_shot() -> void:
	var was_active := curve_shot_active
	curve_shot_active = false
	curve_shot_time_remaining = 0.0
	curve_shot_obstacle_active = false
	if was_active:
		_set_curve_shot_visual(false)


func _update_speed_trail() -> void:
	# Normal ball motion uses the same dense two-layer particle language as
	# Power Strike, but recolored to the last-touch player's equipped team color.
	# The legacy Line2D path stays disabled so this reads as motion particles,
	# never as a trajectory/prediction line.
	if speed_trail_glow != null:
		if speed_trail_glow.get_point_count() > 0:
			speed_trail_glow.clear_points()
		speed_trail_glow.visible = false
	if speed_trail_core != null:
		if speed_trail_core.get_point_count() > 0:
			speed_trail_core.clear_points()
		speed_trail_core.visible = false
	_speed_trail_point_times.clear()

	if speed_trail_particles == null or speed_trail_embers == null:
		return

	# This is one shared trail for ordinary possession and Power Strike.
	# Power Strike only swaps this trail's color, so a separate team-color trail
	# can never stack underneath it.

	var speed := linear_velocity.length()
	var start_speed := maxf(0.0, speed_trail_start_speed)
	var full_speed := maxf(start_speed + 1.0, speed_trail_full_speed)
	var strength := clampf(
		(speed - start_speed) / (full_speed - start_speed),
		0.0,
		1.0
	)
	var ball_is_visible := ball_sprite == null or ball_sprite.visible
	var trail_active := speed >= start_speed and ball_is_visible
	speed_trail_particles.emitting = trail_active
	speed_trail_embers.emitting = trail_active
	if not trail_active:
		return

	# Both emitters are world-space so particles stay where the ball actually
	# travelled. Aim them backward to create Power-Strike-like density without
	# drawing a continuous path.
	if not linear_velocity.is_zero_approx():
		var backward_direction := (
			-linear_velocity.normalized()
		).rotated(-global_rotation)
		speed_trail_particles.direction = backward_direction
		speed_trail_embers.direction = backward_direction

	# The moving particle texture is a neutral white mask, so these modulates
	# are the actual visible trail colors. Keep the main layer on the exact
	# last-touch color instead of washing it toward Power-Strike orange/yellow.
	var main_color: Color = _current_speed_trail_color
	var ember_color: Color = _current_speed_trail_color.lightened(0.18)
	speed_trail_particles.modulate = Color(
		main_color,
		lerpf(0.72, 1.0, strength)
	)
	speed_trail_embers.modulate = Color(
		ember_color,
		lerpf(0.56, 0.92, strength)
	)


func _clear_speed_trail() -> void:
	_speed_trail_point_times.clear()
	if speed_trail_glow != null:
		speed_trail_glow.clear_points()
		speed_trail_glow.visible = false
	if speed_trail_core != null:
		speed_trail_core.clear_points()
		speed_trail_core.visible = false
	if speed_trail_particles != null:
		speed_trail_particles.emitting = false
	if speed_trail_embers != null:
		speed_trail_embers.emitting = false


func _update_curve_trail() -> void:
	if curve_trail == null:
		return

	curve_trail.global_position = Vector2.ZERO
	var now := float(Time.get_ticks_msec()) / 1000.0
	if curve_shot_visual_active:
		var should_add_point := (
			curve_trail.get_point_count() == 0
			or curve_trail.get_point_position(
				curve_trail.get_point_count() - 1
			).distance_to(global_position)
			>= maxf(1.0, curve_trail_point_spacing)
		)
		if should_add_point:
			curve_trail.add_point(global_position)
			_curve_trail_point_times.append(now)

	while (
		not _curve_trail_point_times.is_empty()
		and (
			now - _curve_trail_point_times[0]
			> maxf(0.01, curve_trail_lifetime)
			or curve_trail.get_point_count()
			> maxi(2, curve_trail_max_points)
		)
	):
		_curve_trail_point_times.pop_front()
		curve_trail.remove_point(0)

	curve_trail.visible = curve_trail.get_point_count() >= 2


func _set_curve_shot_visual(enabled: bool) -> void:
	if not multiplayer.is_server():
		return
	if curve_shot_visual_active == enabled:
		return

	_receive_curve_shot_visual.rpc(enabled)


@rpc("authority", "call_local", "reliable")
func _receive_curve_shot_visual(enabled: bool) -> void:
	curve_shot_visual_active = enabled
	_apply_curve_shot_visual(enabled)


func _apply_curve_shot_visual(
	enabled: bool,
	clear_existing: bool = false
) -> void:
	if curve_trail == null:
		return

	if enabled or clear_existing:
		curve_trail.clear_points()
		_curve_trail_point_times.clear()
	curve_trail.visible = false


func _update_time_skip_trail() -> void:
	if time_skip_trail == null:
		return

	time_skip_trail.global_position = Vector2.ZERO
	var now := float(Time.get_ticks_msec()) / 1000.0
	if time_skip_visual_active:
		var should_add_point := (
			time_skip_trail.get_point_count() == 0
			or time_skip_trail.get_point_position(
				time_skip_trail.get_point_count() - 1
			).distance_to(global_position)
			>= maxf(1.0, time_skip_trail_point_spacing)
		)
		if should_add_point:
			time_skip_trail.add_point(global_position)
			_time_skip_trail_point_times.append(now)

	while (
		not _time_skip_trail_point_times.is_empty()
		and (
			now - _time_skip_trail_point_times[0]
			> maxf(0.01, time_skip_trail_lifetime)
			or time_skip_trail.get_point_count()
			> maxi(2, time_skip_trail_max_points)
		)
	):
		_time_skip_trail_point_times.pop_front()
		time_skip_trail.remove_point(0)

	time_skip_trail.visible = (
		time_skip_trail.get_point_count() >= 2
	)


func _set_time_skip_visual(enabled: bool) -> void:
	if not multiplayer.is_server():
		return
	if time_skip_visual_active == enabled:
		return

	_receive_time_skip_visual.rpc(enabled)


@rpc("authority", "call_local", "reliable")
func _receive_time_skip_visual(enabled: bool) -> void:
	time_skip_visual_active = enabled
	_apply_time_skip_visual(enabled)


func _apply_time_skip_visual(
	enabled: bool,
	clear_existing: bool = false
) -> void:
	if time_skip_trail == null:
		return

	if enabled or clear_existing:
		time_skip_trail.clear_points()
		_time_skip_trail_point_times.clear()
	time_skip_trail.visible = false


func _update_player_contacts(
	state: PhysicsDirectBodyState2D,
	incoming_velocity: Vector2
) -> void:
	var current_contact_ids: Dictionary = {}

	for contact_index in range(state.get_contact_count()):
		var player := state.get_contact_collider_object(
			contact_index
		) as FootballPlayer
		if player == null:
			continue

		var player_id := player.get_instance_id()
		current_contact_ids[player_id] = true
		if _player_contact_ids.has(player_id):
			continue

		var previous_touch_team := last_touch_team
		var incoming_speed := incoming_velocity.length()
		if (
			previous_touch_team != &""
			and previous_touch_team != player.team
			and incoming_speed >= 320.0
		):
			var contact_kind: StringName = (
				&"save"
				if _incoming_threatens_team_goal(
					player.team,
					incoming_velocity
				)
				else &"interception"
			)
			_queue_player_contact_camera_feedback(
				incoming_speed,
				contact_kind
			)

		register_touch(
			player.owner_peer_id,
			player.display_name,
			player.team,
			incoming_velocity,
			&"physical_contact",
			state.linear_velocity
		)

	_player_contact_ids = current_contact_ids


func get_player_ball_impact_knockback_multiplier() -> float:
	var multiplier := clampf(
		player_ball_impact_knockback_multiplier,
		0.0,
		1.0
	)
	var full_speed := maxf(0.0, player_ball_impact_full_speed)
	var impact_speed := maxf(
		linear_velocity.length(),
		_knockback_reference_speed
	)
	if full_speed > 0.0 and impact_speed >= full_speed:
		return 1.0
	return multiplier


func _update_collision_sound(
	state: PhysicsDirectBodyState2D,
	speed: float
) -> void:
	var has_non_player_contact := false
	var collision_kind: StringName = &"wall"

	for contact_index in range(state.get_contact_count()):
		var collider := state.get_contact_collider_object(
			contact_index
		)
		if collider == null or collider is FootballPlayer:
			continue

		has_non_player_contact = true
		if _is_goal_post_contact(global_position):
			collision_kind = &"post"
		break

	if (
		has_non_player_contact
		and not _had_non_player_contact
		and speed >= minimum_collision_sound_speed
	):
		_queue_collision_sound(speed, collision_kind)

	_had_non_player_contact = has_non_player_contact


func _is_goal_post_contact(contact_position: Vector2) -> bool:
	var bounds := arena_playable_bounds.abs()
	var near_side := (
		absf(contact_position.x - bounds.position.x) <= 220.0
		or absf(contact_position.x - bounds.end.x) <= 220.0
	)
	if not near_side:
		return false
	var mouth := arena_goal_mouth_y
	var post_band := 150.0
	return (
		absf(contact_position.y - mouth.x) <= post_band
		or absf(contact_position.y - mouth.y) <= post_band
	)



func _queue_collision_sound(
	speed: float,
	collision_kind: StringName = &"wall"
) -> void:
	if collision_sound == null:
		return

	var now := float(Time.get_ticks_msec()) / 1000.0
	if now < _next_collision_sound_time:
		return

	_next_collision_sound_time = (
		now + maxf(0.0, collision_sound_cooldown)
	)
	wall_collision_replay_event.emit(speed)
	call_deferred(
		"_broadcast_collision_sound",
		speed,
		collision_kind
	)


func _broadcast_collision_sound(
	speed: float,
	collision_kind: StringName
) -> void:
	if not multiplayer.is_server():
		return

	_receive_collision_sound.rpc(speed, collision_kind)


@rpc("authority", "call_local", "unreliable")
func _receive_collision_sound(
	speed: float = 2400.0,
	collision_kind: StringName = &"wall"
) -> void:
	_add_collision_impact_camera_shake(speed, collision_kind)
	if speed >= maxf(0.0, collision_visual_minimum_speed):
		var impact_color: Color = (
			Color(1.0, 0.72, 0.2)
			if collision_kind == &"post"
			else Color(0.42, 0.86, 1.0)
		)
		var impact_direction: Vector2 = (
			-linear_velocity.normalized()
			if linear_velocity.length_squared() > 1.0
			else Vector2.UP
		)
		_spawn_compact_contact_feedback(
			impact_color,
			impact_direction,
			clampf(speed / 7000.0, 0.24, 1.0)
		)
	var stream: AudioStream = (
		POST_HIT_SOUND
		if collision_kind == &"post"
		else WALL_HIT_SOUND
	)
	if stream == null:
		stream = collision_sound
	if stream == null:
		return

	var strength := clampf(speed / 5200.0, 0.0, 1.0)
	collision_audio.stop()
	collision_audio.stream = stream
	collision_audio.volume_db = (
		lerpf(-11.0, -4.0, strength)
		if collision_kind == &"post"
		else lerpf(-15.0, -7.0, strength)
	)
	collision_audio.pitch_scale = (
		lerpf(1.03, 0.98, strength)
		if collision_kind == &"post"
		else lerpf(0.96, 0.90, strength)
	)
	collision_audio.play()


func _queue_player_contact_camera_feedback(
	speed: float,
	contact_kind: StringName
) -> void:
	call_deferred(
		"_broadcast_player_contact_camera_feedback",
		speed,
		contact_kind
	)


func _broadcast_player_contact_camera_feedback(
	speed: float,
	contact_kind: StringName
) -> void:
	if not multiplayer.is_server():
		return
	_receive_player_contact_camera_feedback.rpc(speed, contact_kind)


@rpc("authority", "call_local", "unreliable")
func _receive_player_contact_camera_feedback(
	speed: float,
	contact_kind: StringName
) -> void:
	_add_player_contact_camera_shake(speed, contact_kind)
	_play_player_contact_sound(speed, contact_kind)
	if speed < maxf(0.0, player_contact_visual_minimum_speed):
		return
	var contact_color: Color = (
		Color(1.0, 0.78, 0.18)
		if contact_kind == &"save"
		else Color(0.28, 1.0, 0.68)
	)
	var contact_direction: Vector2 = (
		linear_velocity.normalized()
		if linear_velocity.length_squared() > 1.0
		else Vector2.UP
	)
	_spawn_compact_contact_feedback(
		contact_color,
		contact_direction,
		clampf(speed / 6500.0, 0.28, 1.0)
	)


func _play_player_contact_sound(
	speed: float,
	contact_kind: StringName
) -> void:
	if contact_audio == null:
		return
	var stream: AudioStream = null
	match contact_kind:
		&"save":
			stream = SAVE_SOUND
		&"interception":
			stream = INTERCEPTION_SOUND
		_:
			return
	if stream == null:
		return
	var strength := clampf((speed - 300.0) / 3300.0, 0.0, 1.0)
	contact_audio.stop()
	contact_audio.stream = stream
	contact_audio.volume_db = (
		lerpf(-6.0, 0.0, strength)
		if contact_kind == &"save"
		else lerpf(-7.0, -1.0, strength)
	)
	contact_audio.pitch_scale = (
		lerpf(0.94, 0.86, strength)
		if contact_kind == &"save"
		else lerpf(1.01, 0.95, strength)
	)
	contact_audio.play()


func _spawn_compact_contact_feedback(
	color: Color,
	direction: Vector2,
	strength: float
) -> void:
	if get_parent() == null or not is_visible_in_tree():
		return
	var effect: Node2D = KickFeedbackFX.new()
	get_parent().add_child(effect)
	effect.global_position = global_position
	effect.setup(color, direction, strength)


func _incoming_threatens_team_goal(
	player_team: StringName,
	incoming_velocity: Vector2
) -> bool:
	var goal := _get_goal_for_team(player_team)
	if goal == null or incoming_velocity.length() < 1.0:
		return false
	var mouth := goal.get_mouth_y_range()
	var goal_x := goal.get_goal_plane_x()
	var to_goal_x := goal_x - global_position.x
	if absf(to_goal_x) > 2600.0:
		return false
	if absf(incoming_velocity.x) < 1.0:
		return false
	var time_to_plane := to_goal_x / incoming_velocity.x
	if time_to_plane < 0.0 or time_to_plane > 1.5:
		return false
	var projected_y := (
		global_position.y
		+ incoming_velocity.y * time_to_plane
	)
	return (
		projected_y >= mouth.x - 210.0
		and projected_y <= mouth.y + 210.0
	)


func play_goal_replay_collision_sound(
	speed: float = 2400.0
) -> void:
	_receive_collision_sound(speed, &"wall")


func play_goal_replay_kick_feedback(
	effect_position: Vector2,
	player_team: StringName,
	direction: Vector2,
	intensity: float
) -> void:
	if get_parent() == null:
		return
	var color := (
		power_strike_trail_color
		if power_strike_visual_active
		else (
			Color(1.0, 0.25, 0.28)
			if player_team == &"red"
			else Color(0.2, 0.58, 1.0)
		)
	)
	var effect := KickFeedbackFX.new()
	get_parent().add_child(effect)
	effect.global_position = effect_position
	effect.setup(color, direction, intensity)
	if power_strike_visual_active:
		_add_power_strike_camera_emphasis(direction)
	else:
		_add_ball_impact_camera_shake(intensity)


func set_goal_replay_visual_state(
	power_strike_active: bool,
	curve_active: bool,
	time_skip_active: bool
) -> void:
	power_strike_visual_active = power_strike_active
	curve_shot_visual_active = curve_active
	time_skip_visual_active = time_skip_active
	_apply_power_strike_visual(power_strike_active)
	_apply_curve_shot_visual(curve_active, not curve_active)
	_apply_time_skip_visual(time_skip_active, not time_skip_active)


func slow_ball() -> void:
	if not multiplayer.is_server():
		return

	_stop_time_skip_pass()
	linear_velocity *= 0.15
	angular_velocity *= 0.15
	sleeping = false


func reset_ball(spawn_position: Vector2) -> void:
	if not multiplayer.is_server():
		return

	freeze = true

	global_position = spawn_position
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	rotation = 0.0
	reset_physics_interpolation()
	_reset_ball_visual_roll(true)
	_had_non_player_contact = false
	_player_contact_ids.clear()
	_knockback_reference_speed = 0.0
	_previous_physics_velocity = Vector2.ZERO
	_reset_ball_impact_animation()
	_clear_speed_trail()
	_stop_curve_shot()
	_stop_time_skip_pass()
	_set_power_strike_visual(false)
	_goal_explosion_generation += 1
	_restore_ball_render_visibility()
	clear_return_tag()
	clear_snapback_mark()
	_stop_snapback_recall_curve()

	freeze = false
	sleeping = false
	clear_last_touch()
	_receive_forced_ball_reset.rpc(spawn_position)


@rpc("authority", "call_remote", "reliable")
func _receive_forced_ball_reset(spawn_position: Vector2) -> void:
	freeze = true
	global_position = spawn_position
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	rotation = 0.0
	reset_physics_interpolation()
	_reset_ball_visual_roll(true)
	_knockback_reference_speed = 0.0
	_previous_physics_velocity = Vector2.ZERO
	_reset_ball_impact_animation()
	_clear_speed_trail()
	_stop_curve_shot()
	_stop_time_skip_pass()
	_set_power_strike_visual(false)
	_goal_explosion_generation += 1
	_restore_ball_render_visibility()
	_apply_return_tag_visual(false, &"", 0.0)
	_apply_snapback_mark_visual(false, &"", 0.0)
	_reset_client_network_motion(spawn_position)


@rpc("authority", "call_remote", "reliable")
func _receive_ball_interpolation_reset(
	reset_position: Vector2,
	reset_velocity: Vector2,
	reset_rotation: float,
	reset_angular_velocity: float
) -> void:
	# Redirects and emergency recoveries are deliberate discontinuities. Carry
	# the authoritative state in the reliable reset itself so an older unreliable
	# motion snapshot cannot briefly pull the ball back to its pre-reset position.
	_reset_client_network_motion(
		reset_position,
		reset_velocity,
		reset_rotation,
		reset_angular_velocity
	)


func register_touch(
	peer_id: int,
	player_name: String,
	player_team: StringName,
	incoming_velocity: Vector2 = Vector2.ZERO,
	touch_kind: StringName = &"touch",
	outgoing_velocity: Vector2 = Vector2.ZERO,
	safety_redirected: bool = false
) -> void:
	if not multiplayer.is_server():
		return

	_player_touch_serial += 1
	last_touch_peer_id = peer_id
	last_touch_name = player_name
	last_touch_team = player_team
	last_touch_kind = touch_kind
	last_touch_incoming_velocity = incoming_velocity
	last_touch_outgoing_velocity = outgoing_velocity
	last_touch_safety_redirected = safety_redirected
	last_touch_was_cpu = _touch_belongs_to_cpu_player(
		peer_id,
		player_team
	)
	if snapback_recall_curve_active and touch_kind != &"snapback":
		_stop_snapback_recall_curve()
	if snapback_mark_owner_peer_id > 0 and touch_kind != &"snapback":
		clear_snapback_mark()
	if return_tag_owner_peer_id > 0:
		var opposing_touch := player_team != return_tag_team
		var teammate_committed_elsewhere := (
			player_team == return_tag_team
			and touch_kind == &"kick"
		)
		if opposing_touch or teammate_committed_elsewhere:
			clear_return_tag()
	_set_last_touch_team_trail(
		player_team,
		touch_kind == &"kick"
	)
	_set_last_touch_player_fx(
		peer_id,
		player_name,
		player_team,
		touch_kind == &"kick"
	)
	match player_team:
		&"red":
			last_red_touch_peer_id = peer_id
			last_red_touch_name = player_name
		&"blue":
			last_blue_touch_peer_id = peer_id
			last_blue_touch_name = player_name

	player_touch_registered.emit(
		peer_id,
		player_name,
		player_team,
		incoming_velocity
	)


func get_player_touch_serial() -> int:
	return _player_touch_serial


func register_kick(
	peer_id: int,
	player_name: String,
	player_team: StringName,
	kick_impulse: Vector2,
	power_strike_kick: bool = false
) -> void:
	if not multiplayer.is_server():
		return

	# A curve belongs to the kick that created it. Any new kick must clear the
	# previous ball steering before the new kick optionally starts its own curve.
	# Without this, a Power Strike (or any normal touch) could inherit Curve Shot
	# physics from the previous player and create an unintended hybrid shot.
	_stop_curve_shot()
	if power_strike_kick:
		_set_power_strike_visual(true)
	elif power_strike_visual_active:
		_set_power_strike_visual(false)

	_stop_time_skip_pass()
	var incoming_velocity := linear_velocity
	var kick_direction := kick_impulse.normalized()
	var kick_intensity := clampf(
		kick_impulse.length() / 3000.0,
		0.2,
		1.0
	)
	_receive_kick_feedback.rpc(
		player_team,
		kick_direction,
		kick_intensity,
		power_strike_kick
	)
	_notify_kicker_visual(
		peer_id,
		kick_impulse.length(),
		kick_direction
	)
	var safe_mass := maxf(0.001, mass)
	var speed_multiplier: float = maxf(1.0, fun_kick_speed_multiplier)
	var predicted_kick_velocity: Vector2 = kick_impulse / safe_mass * speed_multiplier
	if speed_multiplier > 1.0:
		_pending_fun_kick_velocity_bonus += (
			kick_impulse / safe_mass * (speed_multiplier - 1.0)
		)
	register_touch(
		peer_id,
		player_name,
		player_team,
		incoming_velocity,
		&"kick",
		incoming_velocity + predicted_kick_velocity,
		false
	)
	player_kicked.emit(
		peer_id,
		player_name,
		player_team,
		global_position,
		incoming_velocity + predicted_kick_velocity
	)


@rpc("authority", "call_local", "unreliable")
func _receive_kick_feedback(
	player_team: StringName,
	direction: Vector2,
	intensity: float,
	power_strike_kick: bool = false
) -> void:
	if get_parent() == null:
		return
	var color := (
		Color(1.0, 0.25, 0.28)
		if player_team == &"red"
		else Color(0.2, 0.58, 1.0)
	)
	var effect := KickFeedbackFX.new()
	get_parent().add_child(effect)
	effect.global_position = global_position
	effect.setup(color, direction, intensity)
	_apply_kick_trail_color(color)
	_play_kick_white_flash()
	_play_ball_contact_animation(color, direction, intensity)
	if power_strike_kick:
		_add_power_strike_camera_emphasis(direction)
	else:
		_add_ball_impact_camera_shake(intensity)


func _notify_kicker_visual(
	peer_id: int,
	force: float,
	direction: Vector2
) -> void:
	if not multiplayer.is_server() or peer_id <= 0:
		return
	var playfield := get_parent()
	if playfield == null:
		return
	var players_parent := playfield.get_node_or_null("Players")
	if players_parent == null:
		return

	var kicker := players_parent.get_node_or_null(
		str(peer_id)
	) as FootballPlayer
	if kicker == null:
		for child in players_parent.get_children():
			var candidate := child as FootballPlayer
			if candidate != null and candidate.owner_peer_id == peer_id:
				kicker = candidate
				break
	if kicker != null:
		kicker.play_ball_contact_visual(force, direction)


func _get_ball_base_modulate() -> Color:
	return (
		power_strike_ball_color
		if power_strike_visual_active
		else Color.WHITE
	)


func _apply_ball_base_modulate() -> void:
	if ball_sprite == null or _kick_white_flash_active:
		return
	ball_sprite.modulate = _get_ball_base_modulate()


func _set_kick_white_flash_attack_progress(
	progress: float
) -> void:
	if ball_sprite == null:
		return
	ball_sprite.modulate = _kick_white_flash_start_color.lerp(
		kick_white_flash_color,
		clampf(progress, 0.0, 1.0)
	)


func _set_kick_white_flash_release_progress(
	progress: float
) -> void:
	if ball_sprite == null:
		return
	ball_sprite.modulate = kick_white_flash_color.lerp(
		_kick_white_flash_base_color,
		clampf(progress, 0.0, 1.0)
	)


func _play_kick_white_flash() -> void:
	if ball_sprite == null or not ball_sprite.visible:
		return

	if _kick_white_flash_tween != null:
		_kick_white_flash_tween.kill()

	_kick_white_flash_active = true
	_kick_white_flash_start_color = ball_sprite.modulate
	_kick_white_flash_base_color = _get_ball_base_modulate()

	_kick_white_flash_tween = create_tween()
	_kick_white_flash_tween.tween_method(
		Callable(
			self,
			"_set_kick_white_flash_attack_progress"
		),
		0.0,
		1.0,
		maxf(
			0.002,
			kick_white_flash_attack_seconds
		)
	).set_trans(Tween.TRANS_QUAD).set_ease(
		Tween.EASE_OUT
	)

	if kick_white_flash_hold_seconds > 0.0:
		_kick_white_flash_tween.tween_interval(
			kick_white_flash_hold_seconds
		)

	_kick_white_flash_tween.tween_method(
		Callable(
			self,
			"_set_kick_white_flash_release_progress"
		),
		0.0,
		1.0,
		maxf(
			0.01,
			kick_white_flash_release_seconds
		)
	).set_trans(Tween.TRANS_QUAD).set_ease(
		Tween.EASE_OUT
	)
	_kick_white_flash_tween.tween_callback(
		_finish_kick_white_flash
	)


func _finish_kick_white_flash() -> void:
	_kick_white_flash_active = false
	_kick_white_flash_tween = null
	if ball_sprite == null:
		return
	ball_sprite.modulate = _get_ball_base_modulate()


func _stop_kick_white_flash() -> void:
	if _kick_white_flash_tween != null:
		_kick_white_flash_tween.kill()
		_kick_white_flash_tween = null
	_kick_white_flash_active = false
	if ball_sprite != null:
		ball_sprite.modulate = _get_ball_base_modulate()


func _play_ball_contact_animation(
	_color: Color,
	_direction: Vector2,
	strength: float
) -> void:
	if ball_sprite == null or not ball_sprite.visible:
		return
	if _ball_impact_tween != null:
		_ball_impact_tween.kill()

	var safe_strength: float = clampf(strength, 0.0, 1.0)
	var peak_scale: float = lerpf(
		1.12,
		maxf(1.0, impact_pulse_max_scale),
		safe_strength
	)

	_stabilize_ball_sprite_rotation()
	ball_sprite.scale = _ball_sprite_base_scale

	_ball_impact_tween = create_tween()
	_ball_impact_tween.tween_property(
		ball_sprite,
		"scale",
		_ball_sprite_base_scale * peak_scale,
		maxf(0.01, impact_pulse_expand_seconds)
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_ball_impact_tween.tween_property(
		ball_sprite,
		"scale",
		_ball_sprite_base_scale,
		maxf(0.005, impact_pulse_return_seconds)
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _center_ball_sprite_pivot() -> void:
	if ball_sprite == null or ball_sprite.texture == null:
		return
	var image := ball_sprite.texture.get_image()
	if image == null or image.is_empty():
		ball_sprite.position = Vector2.ZERO
		ball_sprite.offset = Vector2.ZERO
		return
	var used_rect := image.get_used_rect()
	if used_rect.size.x <= 0 or used_rect.size.y <= 0:
		ball_sprite.position = Vector2.ZERO
		ball_sprite.offset = Vector2.ZERO
		return
	var texture_size := ball_sprite.texture.get_size()
	var visible_center := (
		Vector2(used_rect.position)
		+ Vector2(used_rect.size) * 0.5
	)
	ball_sprite.centered = true
	ball_sprite.position = Vector2.ZERO
	ball_sprite.offset = texture_size * 0.5 - visible_center


func _update_ball_visual_roll(delta: float) -> void:
	if ball_sprite == null:
		return
	if not _ball_visual_roll_initialized:
		_ball_visual_roll_initialized = true

	if not visual_roll_enabled:
		_ball_visual_roll_rotation = 0.0
		_ball_visual_roll_last_motion = Vector2.ZERO
		_ball_visual_roll_smoothed_speed = 0.0
		_stabilize_ball_sprite_rotation()
		return

	var target_speed := linear_velocity.length()
	var smoothing_weight := 1.0 - exp(
		-maxf(0.01, visual_roll_velocity_smoothing)
		* maxf(0.0, delta)
	)
	_ball_visual_roll_smoothed_speed = lerpf(
		_ball_visual_roll_smoothed_speed,
		target_speed,
		clampf(smoothing_weight, 0.0, 1.0)
	)
	if (
		target_speed < maxf(0.0, visual_roll_minimum_speed)
		and _ball_visual_roll_smoothed_speed
		< maxf(0.0, visual_roll_minimum_speed)
	):
		_ball_visual_roll_smoothed_speed = 0.0
		_stabilize_ball_sprite_rotation()
		return

	var safe_speed := maxf(target_speed, 0.001)
	var motion_direction := linear_velocity / safe_speed
	if _ball_visual_roll_last_motion.is_zero_approx():
		var dominant_component := motion_direction.x
		if absf(motion_direction.y) > absf(motion_direction.x):
			dominant_component = motion_direction.y
		if dominant_component < 0.0:
			_ball_visual_roll_direction = -1.0
		else:
			_ball_visual_roll_direction = 1.0
	elif motion_direction.dot(_ball_visual_roll_last_motion) < -0.25:
		_ball_visual_roll_direction *= -1.0
	_ball_visual_roll_last_motion = motion_direction

	var radians_per_second := minf(
		_ball_visual_roll_smoothed_speed
		* maxf(0.0, visual_roll_speed_multiplier)
		/ maxf(1.0, visual_roll_radius),
		maxf(1.0, visual_roll_max_radians_per_second)
	)
	_ball_visual_roll_rotation = fposmod(
		_ball_visual_roll_rotation
		+ _ball_visual_roll_direction
		* radians_per_second
		* maxf(0.0, delta),
		TAU
	)
	_stabilize_ball_sprite_rotation()


func _reset_ball_visual_roll(reset_rotation: bool) -> void:
	_ball_visual_roll_last_motion = Vector2.ZERO
	_ball_visual_roll_smoothed_speed = 0.0
	_ball_visual_roll_initialized = true
	_ball_visual_roll_direction = 1.0
	if reset_rotation:
		_ball_visual_roll_rotation = 0.0
	_stabilize_ball_sprite_rotation()


func _stabilize_ball_sprite_rotation() -> void:
	if ball_sprite == null:
		return
	ball_sprite.global_rotation = (
		_ball_sprite_base_rotation
		+ _ball_visual_roll_rotation
	)


func _reset_ball_impact_animation() -> void:
	if _ball_impact_tween != null:
		_ball_impact_tween.kill()
		_ball_impact_tween = null
	_stop_kick_white_flash()
	if ball_sprite == null:
		return
	ball_sprite.scale = _ball_sprite_base_scale
	ball_sprite.offset = _ball_sprite_base_offset
	_stabilize_ball_sprite_rotation()
	ball_sprite.modulate = _get_ball_base_modulate()


func _set_last_touch_team_trail(
	player_team: StringName,
	force_refresh: bool = false
) -> void:
	if not multiplayer.is_server():
		return
	if not force_refresh and player_team == _current_speed_trail_team:
		return
	_receive_last_touch_team_trail.rpc(player_team)


@rpc("authority", "call_local", "reliable")
func _receive_last_touch_team_trail(
	player_team: StringName
) -> void:
	_apply_last_touch_team_trail(player_team)


func _apply_last_touch_team_trail(
	player_team: StringName
) -> void:
	_current_speed_trail_team = player_team
	match player_team:
		&"red":
			_apply_kick_trail_color(red_team_trail_color)
		&"blue":
			_apply_kick_trail_color(blue_team_trail_color)
		_:
			_apply_kick_trail_color(neutral_trail_color)


func _set_last_touch_player_fx(
	peer_id: int,
	player_name: String,
	player_team: StringName,
	force_refresh: bool = false
) -> void:
	if not multiplayer.is_server():
		return
	if (
		not force_refresh
		and peer_id == _current_glow_fx_peer_id
		and player_name == _current_glow_fx_name
	):
		return
	_current_glow_fx_peer_id = peer_id
	_current_glow_fx_name = player_name
	var color: Color = _resolve_touch_player_fx_color(
		peer_id,
		player_name,
		player_team
	)
	_receive_last_touch_player_fx.rpc(color)


@rpc("authority", "call_local", "reliable")
func _receive_last_touch_player_fx(color: Color) -> void:
	_apply_last_touch_player_fx(color)


func _apply_last_touch_player_fx(color: Color) -> void:
	_last_touch_visual_color = Color(color.r, color.g, color.b, 1.0)
	if ball_glow_fx != null and ball_glow_fx.has_method("set_accent_color"):
		ball_glow_fx.call("set_accent_color", _last_touch_visual_color)
	# The normal trail and ball light are two views of the same possession state:
	# both use the exact equipped team color of the last-touch player. Temporary
	# special ability trail overrides are allowed to finish before restoring it.
	if not power_strike_visual_active:
		_apply_kick_trail_color(_last_touch_visual_color)


func _resolve_touch_player_fx_color(
	peer_id: int,
	player_name: String,
	player_team: StringName
) -> Color:
	var fallback: Color = neutral_trail_color
	match player_team:
		&"red":
			fallback = red_team_trail_color.lightened(0.16)
		&"blue":
			fallback = blue_team_trail_color.lightened(0.16)

	var playfield: Node = get_parent()
	var players_parent: Node = null
	if playfield != null:
		players_parent = playfield.get_node_or_null("Players")
	if players_parent == null:
		return fallback

	var peer_match: FootballPlayer = null
	for child: Node in players_parent.get_children():
		var candidate := child as FootballPlayer
		if candidate == null or candidate.team != player_team:
			continue
		if candidate.display_name == player_name:
			return candidate.get_soft_glow_color()
		if candidate.owner_peer_id == peer_id:
			peer_match = candidate
	if peer_match != null:
		return peer_match.get_soft_glow_color()
	return fallback


func _apply_kick_trail_color(color: Color) -> void:
	_current_speed_trail_color = color
	var bright := color.lightened(0.48)
	var glow_gradient := Gradient.new()
	glow_gradient.offsets = PackedFloat32Array([0.0, 0.34, 0.72, 1.0])
	glow_gradient.colors = PackedColorArray([
		Color(color, 0.0),
		Color(color, 0.22),
		Color(bright, 0.62),
		Color(1.0, 1.0, 1.0, 0.94)
	])
	speed_trail_glow.gradient = glow_gradient

	var core_gradient := Gradient.new()
	core_gradient.offsets = PackedFloat32Array([0.0, 0.28, 0.68, 1.0])
	core_gradient.colors = PackedColorArray([
		Color(color, 0.0),
		Color(color, 0.34),
		Color(bright, 0.86),
		Color(1.0, 1.0, 1.0, 1.0)
	])
	speed_trail_core.gradient = core_gradient


func _add_ball_impact_camera_shake(strength: float) -> void:
	var camera := get_viewport().get_camera_2d()
	if (
		camera != null
		and camera.has_method("add_ball_impact_shake")
	):
		camera.call(
			"add_ball_impact_shake",
			clampf(strength, 0.0, 1.0)
		)


func _add_collision_impact_camera_shake(
	speed: float,
	collision_kind: StringName
) -> void:
	var camera := get_viewport().get_camera_2d()
	if (
		camera != null
		and camera.has_method("add_collision_impact_shake")
	):
		camera.call(
			"add_collision_impact_shake",
			maxf(0.0, speed),
			collision_kind
		)


func _add_player_contact_camera_shake(
	speed: float,
	contact_kind: StringName
) -> void:
	var camera := get_viewport().get_camera_2d()
	if (
		camera != null
		and camera.has_method("add_player_contact_shake")
	):
		camera.call(
			"add_player_contact_shake",
			maxf(0.0, speed),
			contact_kind
		)


func _add_power_strike_camera_emphasis(direction: Vector2) -> void:
	var camera := get_viewport().get_camera_2d()
	if (
		camera != null
		and camera.has_method("add_power_strike_emphasis")
	):
		camera.call("add_power_strike_emphasis", direction)


func _add_goal_camera_punch() -> void:
	var camera := get_viewport().get_camera_2d()
	if camera != null and camera.has_method("add_goal_impact_shake"):
		camera.call("add_goal_impact_shake")


func arm_snapback_mark(
	peer_id: int,
	player_team: StringName,
	duration: float
) -> void:
	if not multiplayer.is_server() or peer_id <= 0 or player_team == &"":
		return
	snapback_mark_owner_peer_id = peer_id
	snapback_mark_team = player_team
	var safe_duration: float = maxf(0.1, duration)
	_receive_snapback_mark_visual.rpc(true, player_team, safe_duration)


func clear_snapback_mark() -> void:
	if not multiplayer.is_server():
		return
	snapback_mark_owner_peer_id = 0
	snapback_mark_team = &""
	_receive_snapback_mark_visual.rpc(false, &"", 0.0)


func start_snapback_recall_curve(
	peer_id: int,
	player_team: StringName,
	duration: float,
	desired_speed: float,
	lead_seconds: float,
	turn_rate: float
) -> void:
	if not multiplayer.is_server() or peer_id <= 0 or player_team == &"":
		return
	clear_snapback_mark()
	_stop_curve_shot()
	_stop_time_skip_pass()
	snapback_recall_curve_active = true
	snapback_recall_target_peer_id = peer_id
	snapback_recall_target_team = player_team
	snapback_recall_time_remaining = maxf(0.05, duration)
	snapback_recall_speed = maxf(300.0, desired_speed)
	snapback_recall_lead_seconds = maxf(0.0, lead_seconds)
	snapback_recall_turn_rate = maxf(0.5, turn_rate)


func _stop_snapback_recall_curve() -> void:
	snapback_recall_curve_active = false
	snapback_recall_target_peer_id = 0
	snapback_recall_target_team = &""
	snapback_recall_time_remaining = 0.0
	snapback_recall_speed = 0.0
	snapback_recall_lead_seconds = 0.0
	snapback_recall_turn_rate = 0.0


func _get_snapback_target_player() -> FootballPlayer:
	if snapback_recall_target_peer_id <= 0 or get_parent() == null:
		return null
	var players_parent := get_parent().get_node_or_null("Players")
	if players_parent == null:
		return null
	var direct := players_parent.get_node_or_null(str(snapback_recall_target_peer_id)) as FootballPlayer
	if direct != null and direct.team == snapback_recall_target_team:
		return direct
	for child in players_parent.get_children():
		var candidate := child as FootballPlayer
		if (
			candidate != null
			and candidate.owner_peer_id == snapback_recall_target_peer_id
			and candidate.team == snapback_recall_target_team
		):
			return candidate
	return null


func _update_snapback_recall_curve(state: PhysicsDirectBodyState2D) -> void:
	if not snapback_recall_curve_active:
		return
	snapback_recall_time_remaining = maxf(
		0.0,
		snapback_recall_time_remaining - state.step
	)
	if snapback_recall_time_remaining <= 0.0:
		_stop_snapback_recall_curve()
		return
	var target: FootballPlayer = _get_snapback_target_player()
	if target == null or not target.controls_enabled:
		_stop_snapback_recall_curve()
		return
	var target_position: Vector2 = (
		target.global_position
		+ target.linear_velocity * snapback_recall_lead_seconds
	)
	var distance: float = global_position.distance_to(target_position)
	var desired_direction: Vector2 = global_position.direction_to(target_position)
	if desired_direction.is_zero_approx():
		_stop_snapback_recall_curve()
		return
	var velocity: Vector2 = state.linear_velocity
	var current_direction: Vector2 = velocity.normalized()
	if current_direction.is_zero_approx():
		current_direction = desired_direction
	var angle_error: float = current_direction.angle_to(desired_direction)
	var maximum_turn: float = snapback_recall_turn_rate * maxf(0.0, state.step)
	var steered_direction: Vector2 = current_direction.rotated(
		clampf(angle_error, -maximum_turn, maximum_turn)
	).normalized()
	# Stay fast over distance, then bleed a little speed near the receiver so
	# the curve actually arrives instead of overshooting a moving player.
	var arrival_speed: float = snapback_recall_speed
	if distance < 520.0:
		arrival_speed = minf(
			snapback_recall_speed,
			maxf(1350.0, distance * 8.5)
		)
	state.linear_velocity = steered_direction * minf(arrival_speed, maximum_speed)
	sleeping = false


@rpc("authority", "call_local", "reliable")
func _receive_snapback_mark_visual(
	enabled: bool,
	player_team: StringName,
	duration: float
) -> void:
	_apply_snapback_mark_visual(enabled, player_team, duration)


func _apply_snapback_mark_visual(
	enabled: bool,
	player_team: StringName,
	duration: float
) -> void:
	snapback_mark_visual_active = enabled
	snapback_mark_visual_duration = maxf(0.0, duration)
	snapback_mark_visual_remaining = snapback_mark_visual_duration
	_snapback_mark_visual_elapsed = 0.0
	if enabled:
		snapback_mark_team = player_team
	else:
		snapback_mark_team = &""
	queue_redraw()


func _update_snapback_mark_visual(delta: float) -> void:
	if not snapback_mark_visual_active:
		return
	_snapback_mark_visual_elapsed += delta
	snapback_mark_visual_remaining = maxf(
		0.0,
		snapback_mark_visual_remaining - delta
	)
	if snapback_mark_visual_remaining <= 0.0:
		snapback_mark_visual_active = false
	queue_redraw()


func arm_return_tag(
	peer_id: int,
	player_name: String,
	player_team: StringName,
	duration: float
) -> void:
	if not multiplayer.is_server() or peer_id <= 0 or player_team == &"":
		return
	return_tag_owner_peer_id = peer_id
	return_tag_owner_name = player_name
	return_tag_team = player_team
	var safe_duration := maxf(0.1, duration)
	return_tag_expires_at = _server_time_seconds() + safe_duration
	_receive_return_tag_visual.rpc(
		true,
		return_tag_team,
		safe_duration
	)


func clear_return_tag() -> void:
	if not multiplayer.is_server():
		return
	if return_tag_owner_peer_id <= 0 and not return_tag_visual_active:
		return
	return_tag_owner_peer_id = 0
	return_tag_owner_name = ""
	return_tag_team = &""
	return_tag_expires_at = 0.0
	_receive_return_tag_visual.rpc(false, &"", 0.0)


func can_return_tag_for(
	passer_peer_id: int,
	passer_team: StringName
) -> bool:
	if not multiplayer.is_server():
		return false
	if return_tag_owner_peer_id <= 0:
		return false
	if _server_time_seconds() >= return_tag_expires_at:
		clear_return_tag()
		return false
	return (
		passer_team == return_tag_team
		and passer_peer_id > 0
		and passer_peer_id != return_tag_owner_peer_id
	)


func get_return_tag_owner_peer_id() -> int:
	return return_tag_owner_peer_id


func execute_return_tag_pass(
	target_position: Vector2,
	return_speed: float,
	passer_peer_id: int,
	passer_name: String,
	passer_team: StringName,
	apply_cpu_safety: bool = false
) -> bool:
	if not can_return_tag_for(passer_peer_id, passer_team):
		return false
	var direction := global_position.direction_to(target_position)
	if direction.is_zero_approx():
		return false
	var incoming_velocity := linear_velocity
	var target_velocity := direction * maxf(0.0, return_speed)
	var safety_result: Dictionary = _sanitize_cpu_defensive_velocity(
		global_position,
		target_velocity,
		passer_team,
		apply_cpu_safety,
		&"return_tag"
	)
	target_velocity = safety_result.get(
		"velocity",
		target_velocity
	) as Vector2
	clear_return_tag()
	clear_snapback_mark()
	_stop_snapback_recall_curve()
	_stop_curve_shot()
	_stop_time_skip_pass()
	var kick_impulse := (
		target_velocity - incoming_velocity
	) * maxf(0.001, mass)
	register_kick(
		passer_peer_id,
		passer_name,
		passer_team,
		kick_impulse,
		false
	)
	linear_velocity = target_velocity.limit_length(maxf(1.0, maximum_speed))
	angular_velocity *= 0.35
	sleeping = false
	return true


func block_from_echo(
	echo_position: Vector2,
	stop_speed_limit: float,
	fast_ball_speed_retention: float,
	peer_id: int,
	player_name: String,
	player_team: StringName,
	apply_cpu_safety: bool = false
) -> void:
	if not multiplayer.is_server():
		return
	var incoming_velocity := linear_velocity
	var incoming_speed := incoming_velocity.length()
	_queue_player_contact_camera_feedback(
		incoming_speed,
		(
			&"save"
			if _incoming_threatens_team_goal(
				player_team,
				incoming_velocity
			)
			else &"interception"
		)
	)

	# Echo is a true one-hit blocker. Speed, charge level and special-shot
	# type do not reduce its stopping power. The parameters remain in the
	# signature for compatibility with existing callers/scenes.
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	clear_return_tag()
	clear_snapback_mark()
	_stop_snapback_recall_curve()
	_stop_curve_shot()
	_stop_time_skip_pass()
	if power_strike_visual_active:
		_set_power_strike_visual(false)

	register_touch(
		peer_id,
		player_name,
		player_team,
		incoming_velocity,
		&"echo_block",
		Vector2.ZERO,
		false
	)
	sleeping = false


@rpc("authority", "call_local", "reliable")
func _receive_return_tag_visual(
	enabled: bool,
	player_team: StringName,
	duration: float
) -> void:
	_apply_return_tag_visual(enabled, player_team, duration)


func _apply_return_tag_visual(
	enabled: bool,
	player_team: StringName,
	duration: float
) -> void:
	return_tag_visual_active = enabled
	return_tag_visual_duration = maxf(0.0, duration)
	return_tag_visual_remaining = return_tag_visual_duration
	_return_tag_visual_elapsed = 0.0
	if enabled:
		return_tag_team = player_team
	elif not multiplayer.is_server():
		return_tag_team = &""
	queue_redraw()


func _update_return_tag_visual(delta: float) -> void:
	if not return_tag_visual_active:
		return
	_return_tag_visual_elapsed += delta
	return_tag_visual_remaining = maxf(
		0.0,
		return_tag_visual_remaining - delta
	)
	if return_tag_visual_remaining <= 0.0:
		return_tag_visual_active = false
	queue_redraw()


func _draw() -> void:
	if return_tag_visual_active:
		var color := (
			Color(1.0, 0.24, 0.34, 1.0)
			if return_tag_team == &"red"
			else Color(0.28, 0.68, 1.0, 1.0)
		)
		var fade := clampf(
			return_tag_visual_remaining / maxf(0.1, return_tag_visual_duration),
			0.0,
			1.0
		)
		var pulse := 0.82 + 0.18 * sin(_return_tag_visual_elapsed * 8.0)
		var alpha := clampf(fade * pulse, 0.0, 1.0)
		draw_arc(
			Vector2.ZERO,
			maxf(8.0, return_tag_ring_radius),
			0.0,
			TAU,
			64,
			Color(color.lightened(0.32), 0.92 * alpha),
			maxf(1.0, return_tag_ring_width),
			true
		)
		for index in range(2):
			var angle := _return_tag_visual_elapsed * return_tag_orbit_speed + PI * float(index)
			var point := Vector2.RIGHT.rotated(angle) * maxf(12.0, return_tag_orbit_radius)
			draw_circle(point, 9.0, Color(color, alpha))
			var tangent := Vector2.RIGHT.rotated(angle + PI * 0.5)
			var tip := point + tangent * 15.0
			draw_line(point, tip, Color.WHITE, 4.0, true)
			draw_line(tip, tip - tangent.rotated(0.65) * 8.0, Color.WHITE, 4.0, true)

	if snapback_mark_visual_active:
		var snap_fade: float = clampf(
			snapback_mark_visual_remaining / maxf(0.1, snapback_mark_visual_duration),
			0.0,
			1.0
		)
		var snap_pulse: float = 0.82 + 0.18 * sin(_snapback_mark_visual_elapsed * 10.0)
		var snap_alpha: float = snap_fade * snap_pulse
		var snap_color := Color(1.0, 0.31, 0.63, snap_alpha)
		draw_arc(
			Vector2.ZERO,
			maxf(8.0, snapback_ring_radius),
			-PI * 0.25,
			PI * 1.35,
			52,
			snap_color,
			maxf(1.0, snapback_ring_width),
			true
		)
		var hook_angle: float = _snapback_mark_visual_elapsed * -5.5
		var hook_point: Vector2 = Vector2.RIGHT.rotated(hook_angle) * maxf(12.0, snapback_ring_radius)
		draw_circle(hook_point, 7.0, Color(1.0, 0.72, 0.88, snap_alpha))


func _server_time_seconds() -> float:
	return float(Time.get_ticks_msec()) / 1000.0


func redirect_ball(
	new_position: Vector2,
	new_velocity: Vector2,
	peer_id: int,
	player_name: String,
	player_team: StringName,
	apply_cpu_safety: bool = false
) -> void:
	if not multiplayer.is_server():
		return

	var incoming_velocity: Vector2 = linear_velocity
	var safety_result: Dictionary = _sanitize_cpu_defensive_velocity(
		new_position,
		new_velocity,
		player_team,
		apply_cpu_safety,
		&"redirect"
	)
	new_velocity = safety_result.get(
		"velocity",
		new_velocity
	) as Vector2
	register_touch(
		peer_id,
		player_name,
		player_team,
		incoming_velocity,
		&"redirect",
		new_velocity,
		bool(safety_result.get("redirected", false))
	)
	_stop_time_skip_pass()
	_stop_curve_shot()
	_knockback_reference_speed = 0.0
	_clear_speed_trail()
	freeze = true
	global_position = new_position
	linear_velocity = new_velocity
	_previous_physics_velocity = new_velocity
	angular_velocity = 0.0
	rotation = 0.0
	reset_physics_interpolation()
	freeze = false
	sleeping = false
	_receive_ball_interpolation_reset.rpc(
		global_position,
		linear_velocity,
		rotation,
		angular_velocity
	)


func block_from_goalkeeper(
	blocker_position: Vector2,
	speed_retention: float,
	speed_limit: float,
	peer_id: int,
	player_name: String,
	player_team: StringName,
	apply_cpu_safety: bool = false
) -> void:
	if not multiplayer.is_server():
		return

	var incoming_velocity := linear_velocity
	_stop_time_skip_pass()
	_queue_player_contact_camera_feedback(
		incoming_velocity.length(),
		&"save"
	)
	var away_direction := blocker_position.direction_to(
		global_position
	)
	if away_direction.is_zero_approx():
		away_direction = -linear_velocity.normalized()
	if away_direction.is_zero_approx():
		away_direction = Vector2.RIGHT

	var blocked_speed := minf(
		linear_velocity.length()
		* clampf(speed_retention, 0.0, 1.0),
		maxf(0.0, speed_limit)
	)
	var proposed_velocity: Vector2 = away_direction * blocked_speed
	var safety_result: Dictionary = _sanitize_cpu_defensive_velocity(
		global_position,
		proposed_velocity,
		player_team,
		apply_cpu_safety,
		&"goalkeeper_block"
	)
	linear_velocity = safety_result.get(
		"velocity",
		proposed_velocity
	) as Vector2
	register_touch(
		peer_id,
		player_name,
		player_team,
		incoming_velocity,
		&"goalkeeper_block",
		linear_velocity,
		bool(safety_result.get("redirected", false))
	)
	angular_velocity *= clampf(speed_retention, 0.0, 1.0)
	sleeping = false



func reflex_deflect(
	blocker_position: Vector2,
	facing_direction: Vector2,
	deflection_degrees: float,
	speed_retention: float,
	speed_limit: float,
	peer_id: int,
	player_name: String,
	player_team: StringName,
	apply_cpu_safety: bool = false
) -> void:
	if not multiplayer.is_server():
		return

	var incoming_velocity := linear_velocity
	_stop_time_skip_pass()
	_queue_player_contact_camera_feedback(
		incoming_velocity.length(),
		(
			&"save"
			if _incoming_threatens_team_goal(
				player_team,
				incoming_velocity
			)
			else &"interception"
		)
	)

	var facing := facing_direction.normalized()
	if facing.is_zero_approx():
		facing = blocker_position.direction_to(global_position)
	if facing.is_zero_approx():
		facing = -incoming_velocity.normalized()
	if facing.is_zero_approx():
		facing = Vector2.RIGHT

	var ball_offset := global_position - blocker_position
	var side := signf(facing.cross(ball_offset))
	if is_zero_approx(side):
		side = signf(incoming_velocity.cross(facing))
	if is_zero_approx(side):
		side = 1.0

	var deflection_direction := facing.rotated(
		side
		* deg_to_rad(
			clampf(deflection_degrees, 0.0, 90.0)
		)
	)
	var deflected_speed := minf(
		incoming_velocity.length()
		* clampf(speed_retention, 0.0, 1.0),
		maxf(0.0, speed_limit)
	)
	var proposed_velocity: Vector2 = (
		deflection_direction * deflected_speed
	)
	var safety_result: Dictionary = _sanitize_cpu_defensive_velocity(
		global_position,
		proposed_velocity,
		player_team,
		apply_cpu_safety,
		&"reflex_deflect"
	)
	linear_velocity = safety_result.get(
		"velocity",
		proposed_velocity
	) as Vector2
	register_touch(
		peer_id,
		player_name,
		player_team,
		incoming_velocity,
		&"reflex_deflect",
		linear_velocity,
		bool(safety_result.get("redirected", false))
	)
	angular_velocity *= clampf(speed_retention, 0.0, 1.0)
	sleeping = false



func _sanitize_cpu_defensive_velocity(
	ball_position: Vector2,
	proposed_velocity: Vector2,
	player_team: StringName,
	apply_cpu_safety: bool,
	touch_kind: StringName
) -> Dictionary:
	if (
		not apply_cpu_safety
		or not cpu_defensive_own_goal_prevention_enabled
		or proposed_velocity.is_zero_approx()
	):
		return {
			"velocity": proposed_velocity,
			"redirected": false
		}

	var own_goal: FootballGoal = _get_goal_for_team(player_team)
	if own_goal == null:
		return {
			"velocity": proposed_velocity,
			"redirected": false
		}
	if not _velocity_crosses_goal_mouth(
		ball_position,
		proposed_velocity,
		own_goal
	):
		return {
			"velocity": proposed_velocity,
			"redirected": false
		}

	var goal_center_y: float = (
		own_goal.get_mouth_y_range().x
		+ own_goal.get_mouth_y_range().y
	) * 0.5
	var away_x: float = _get_goal_field_side_sign(own_goal)
	var lateral_sign: float = (
		-1.0
		if ball_position.y < goal_center_y
		else 1.0
	)
	var safe_direction: Vector2 = Vector2(
		away_x,
		lateral_sign * cpu_defensive_lateral_weight
	).normalized()
	var safe_velocity: Vector2 = (
		safe_direction
		* maxf(
			cpu_defensive_safe_speed,
			proposed_velocity.length() * 0.80
		)
	)
	_record_own_goal_safety_event(
		player_team,
		&"redirect",
		touch_kind
	)
	return {
		"velocity": safe_velocity,
		"redirected": true
	}


func _velocity_crosses_goal_mouth(
	ball_position: Vector2,
	velocity: Vector2,
	goal: FootballGoal
) -> bool:
	if velocity.length() < cpu_defensive_minimum_toward_speed:
		return false
	if absf(velocity.x) < 0.001:
		return false

	var position: Vector2 = ball_position
	var simulated_velocity: Vector2 = velocity
	var remaining_seconds: float = maxf(
		0.1,
		cpu_defensive_prediction_seconds
	)
	var top_y: float = arena_playable_bounds.position.y
	var bottom_y: float = (
		arena_playable_bounds.position.y
		+ arena_playable_bounds.size.y
	)
	var mouth: Vector2 = goal.get_mouth_y_range()
	var goal_x: float = goal.get_goal_plane_x()

	for _bounce_index in range(4):
		var goal_time: float = (
			goal_x - position.x
		) / simulated_velocity.x
		var wall_time: float = INF
		if simulated_velocity.y < -0.001:
			wall_time = (
				top_y - position.y
			) / simulated_velocity.y
		elif simulated_velocity.y > 0.001:
			wall_time = (
				bottom_y - position.y
			) / simulated_velocity.y

		if (
			goal_time > 0.0
			and goal_time <= remaining_seconds
			and (
				wall_time <= 0.0
				or goal_time <= wall_time
			)
		):
			var predicted_y: float = (
				position.y
				+ simulated_velocity.y * goal_time
			)
			return (
				predicted_y
				>= mouth.x - cpu_defensive_goal_mouth_padding
				and predicted_y
				<= mouth.y + cpu_defensive_goal_mouth_padding
			)

		if (
			wall_time <= 0.0
			or wall_time > remaining_seconds
			or not is_finite(wall_time)
		):
			return false

		position += simulated_velocity * wall_time
		position.y = clampf(position.y, top_y, bottom_y)
		simulated_velocity.y *= -1.0
		remaining_seconds -= wall_time

	return false


func _touch_belongs_to_cpu_player(
	peer_id: int,
	player_team: StringName
) -> bool:
	if peer_id <= 0 or player_team == &"" or get_parent() == null:
		return false
	var players_parent := get_parent().get_node_or_null("Players")
	if players_parent == null:
		return false
	var player := players_parent.get_node_or_null(
		str(peer_id)
	) as FootballPlayer
	return (
		player != null
		and player.cpu_controlled
		and player.team == player_team
	)


func _get_goal_field_side_sign(goal: FootballGoal) -> float:
	if goal == null:
		return 1.0
	var field_center_x := arena_playable_bounds.get_center().x
	var field_side_sign := signf(
		field_center_x - goal.get_goal_plane_x()
	)
	return field_side_sign if not is_zero_approx(field_side_sign) else 1.0


func _cpu_owned_ball_threatens_own_goal(
	ball_position: Vector2,
	velocity: Vector2,
	own_goal: FootballGoal
) -> bool:
	if own_goal == null:
		return false

	var goal_x := own_goal.get_goal_plane_x()
	var mouth := own_goal.get_mouth_y_range()
	var field_side_sign := _get_goal_field_side_sign(own_goal)
	var field_depth := (
		ball_position.x - goal_x
	) * field_side_sign
	var inside_padded_mouth := (
		ball_position.y
		>= mouth.x - cpu_defensive_goal_mouth_padding
		and ball_position.y
		<= mouth.y + cpu_defensive_goal_mouth_padding
	)
	var moving_toward_goal := (
		velocity.x * -field_side_sign > 0.001
	)

	if inside_padded_mouth:
		if field_depth <= maxf(
			arena_ball_radius,
			cpu_own_goal_emergency_plane_margin
		):
			return field_depth <= arena_ball_radius or moving_toward_goal

	if not moving_toward_goal:
		return false
	return _velocity_crosses_goal_mouth(
		ball_position,
		velocity,
		own_goal
	)


func _build_cpu_own_goal_recovery(
	ball_position: Vector2,
	velocity: Vector2,
	own_goal: FootballGoal
) -> Dictionary:
	var goal_x := own_goal.get_goal_plane_x()
	var mouth := own_goal.get_mouth_y_range()
	var mouth_center_y := (mouth.x + mouth.y) * 0.5
	var field_side_sign := _get_goal_field_side_sign(own_goal)
	var lateral_sign := (
		-1.0 if ball_position.y < mouth_center_y else 1.0
	)
	var safe_direction := Vector2(
		field_side_sign,
		lateral_sign * cpu_defensive_lateral_weight
	).normalized()
	var safe_speed := maxf(
		cpu_defensive_safe_speed,
		velocity.length() * 0.82
	)
	var safe_position := ball_position
	var minimum_field_depth := (
		maxf(0.0, arena_ball_radius)
		+ maxf(20.0, cpu_own_goal_recovery_field_offset)
	)
	var field_depth := (
		ball_position.x - goal_x
	) * field_side_sign
	if field_depth < minimum_field_depth:
		safe_position.x = (
			goal_x + field_side_sign * minimum_field_depth
		)
	var bounds := arena_playable_bounds.abs()
	safe_position.x = clampf(
		safe_position.x,
		bounds.position.x + arena_ball_radius,
		bounds.end.x - arena_ball_radius
	)
	safe_position.y = clampf(
		safe_position.y,
		bounds.position.y + arena_ball_radius,
		bounds.end.y - arena_ball_radius
	)
	return {
		"position": safe_position,
		"velocity": safe_direction * safe_speed
	}


func _apply_cpu_own_goal_hard_lock(
	state: PhysicsDirectBodyState2D
) -> void:
	if (
		not cpu_absolute_own_goal_lock_enabled
		or not last_touch_was_cpu
		or last_touch_team == &""
	):
		return
	var own_goal := _get_goal_for_team(last_touch_team)
	if own_goal == null:
		return
	var ball_position := state.transform.origin
	if not _cpu_owned_ball_threatens_own_goal(
		ball_position,
		state.linear_velocity,
		own_goal
	):
		return

	var recovery := _build_cpu_own_goal_recovery(
		ball_position,
		state.linear_velocity,
		own_goal
	)
	var corrected_transform := state.transform
	corrected_transform.origin = recovery.get(
		"position",
		ball_position
	) as Vector2
	state.transform = corrected_transform
	state.linear_velocity = recovery.get(
		"velocity",
		state.linear_velocity
	) as Vector2
	state.angular_velocity *= 0.35
	_stop_curve_shot()
	_stop_time_skip_pass()
	last_touch_outgoing_velocity = state.linear_velocity
	last_touch_safety_redirected = true
	_record_own_goal_safety_event(
		last_touch_team,
		&"hard_lock",
		last_touch_kind
	)


func recover_cpu_own_goal(
	player_team: StringName
) -> bool:
	if (
		not multiplayer.is_server()
		or not cpu_absolute_own_goal_lock_enabled
		or player_team == &""
	):
		return false
	var own_goal := _get_goal_for_team(player_team)
	if own_goal == null:
		return false
	var recovery := _build_cpu_own_goal_recovery(
		global_position,
		linear_velocity,
		own_goal
	)
	freeze = true
	global_position = recovery.get(
		"position",
		global_position
	) as Vector2
	linear_velocity = recovery.get(
		"velocity",
		linear_velocity
	) as Vector2
	angular_velocity *= 0.35
	rotation = 0.0
	reset_physics_interpolation()
	freeze = false
	sleeping = false
	_receive_ball_interpolation_reset.rpc(
		global_position,
		linear_velocity,
		rotation,
		angular_velocity
	)
	_stop_curve_shot()
	_stop_time_skip_pass()
	last_touch_outgoing_velocity = linear_velocity
	last_touch_safety_redirected = true
	_record_own_goal_safety_event(
		player_team,
		&"goal_line_lock",
		last_touch_kind
	)
	return true


func _get_goal_for_team(
	player_team: StringName
) -> FootballGoal:
	for node in get_tree().get_nodes_in_group("football_goals"):
		var goal := node as FootballGoal
		if (
			goal != null
			and StringName(goal.defending_team) == player_team
		):
			return goal
	return null


func _get_active_playfield_root() -> Node:
	var current_scene: Node = get_tree().current_scene
	if current_scene == null:
		return null
	if current_scene.get_node_or_null("MatchManager") != null:
		return current_scene
	var nested_playfield := current_scene.find_child("Playfield", true, false)
	if nested_playfield != null:
		return nested_playfield
	return current_scene


func _record_own_goal_safety_event(
	player_team: StringName,
	event_kind: StringName,
	touch_kind: StringName
) -> void:
	var current_scene: Node = _get_active_playfield_root()
	if current_scene == null:
		return
	var manager := current_scene.get_node_or_null(
		"MatchManager"
	) as FootballMatchManager
	if manager == null:
		return
	manager.record_cpu_own_goal_safety_event(
		player_team,
		event_kind,
		touch_kind,
		last_touch_peer_id
	)


func clear_last_touch() -> void:
	last_touch_peer_id = 0
	last_touch_name = ""
	last_touch_team = &""
	last_touch_kind = &""
	last_touch_incoming_velocity = Vector2.ZERO
	last_touch_outgoing_velocity = Vector2.ZERO
	last_touch_safety_redirected = false
	last_touch_was_cpu = false
	last_red_touch_peer_id = 0
	last_red_touch_name = ""
	last_blue_touch_peer_id = 0
	last_blue_touch_name = ""
	if multiplayer.is_server():
		_set_last_touch_team_trail(&"", true)
		_current_glow_fx_peer_id = 0
		_current_glow_fx_name = ""
		_receive_last_touch_player_fx.rpc(neutral_trail_color)


func get_last_touch_name_for_team(
	scoring_team: StringName
) -> String:
	match scoring_team:
		&"red":
			return last_red_touch_name
		&"blue":
			return last_blue_touch_name
		_:
			return ""


func get_last_touch_peer_id_for_team(
	scoring_team: StringName
) -> int:
	match scoring_team:
		&"red":
			return last_red_touch_peer_id
		&"blue":
			return last_blue_touch_peer_id
		_:
			return 0


func ignite_power_strike(use_haaland_visual: bool = false) -> void:
	if not multiplayer.is_server():
		return

	_set_power_strike_visual(true, use_haaland_visual)


func sync_visual_to_peer(peer_id: int) -> void:
	if not multiplayer.is_server() or peer_id <= 0:
		return

	_receive_power_strike_visual.rpc_id(
		peer_id,
		power_strike_visual_active,
		power_strike_haaland_visual_active
	)
	_receive_curve_shot_visual.rpc_id(
		peer_id,
		curve_shot_active
	)
	if return_tag_owner_peer_id > 0:
		var remaining := maxf(0.0, return_tag_expires_at - _server_time_seconds())
		if remaining > 0.0:
			_receive_return_tag_visual.rpc_id(
				peer_id,
				true,
				return_tag_team,
				remaining
			)


func _update_power_strike_visual_from_speed(
	speed: float
) -> void:
	if not power_strike_visual_active:
		return
	if speed > maxf(0.0, power_strike_stop_speed):
		return

	_set_power_strike_visual(false)


func _set_power_strike_visual(enabled: bool, use_haaland_visual: bool = false) -> void:
	if not multiplayer.is_server():
		return
	if (
		power_strike_visual_active == enabled
		and power_strike_haaland_visual_active == (enabled and use_haaland_visual)
	):
		return

	_receive_power_strike_visual.rpc(enabled, use_haaland_visual)


@rpc("authority", "call_local", "reliable")
func _receive_power_strike_visual(
	enabled: bool,
	use_haaland_visual: bool = false
) -> void:
	power_strike_visual_active = enabled
	power_strike_haaland_visual_active = enabled and use_haaland_visual
	_apply_power_strike_visual(enabled)


func _apply_power_strike_visual(enabled: bool) -> void:
	if (
		ball_sprite == null
		or power_strike_flames == null
		or power_strike_embers == null
	):
		return

	if not _kick_white_flash_active:
		ball_sprite.modulate = Color(0.42, 0.82, 1.0, 1.0) if (
			enabled and power_strike_haaland_visual_active
		) else (power_strike_ball_color if enabled else Color.WHITE)
	power_strike_flames.emitting = enabled
	power_strike_embers.emitting = enabled
	power_strike_flames.modulate = Color(0.52, 0.88, 1.0, 1.0) if (
		enabled and power_strike_haaland_visual_active
	) else Color.WHITE
	power_strike_embers.modulate = Color(0.94, 0.99, 1.0, 1.0) if (
		enabled and power_strike_haaland_visual_active
	) else Color.WHITE
	power_strike_flames.amount = 86 if (
		enabled and power_strike_haaland_visual_active
	) else 42
	power_strike_embers.amount = 58 if (
		enabled and power_strike_haaland_visual_active
	) else 26

	if enabled:
		var trail_color: Color = Color(0.25, 0.72, 1.0, 1.0) if power_strike_haaland_visual_active else power_strike_trail_color
		_apply_kick_trail_color(trail_color)
		# The moving trail is shared with normal ball motion; recoloring the same
		# emitters avoids a second team-color trail overlapping Power Strike. The
		# dedicated PowerStrikeFlames/Embers remain the ball-attached impact layer.
		power_strike_flames.restart()
		power_strike_embers.restart()
	else:
		_apply_kick_trail_color(_last_touch_visual_color)


func set_play_enabled(enabled: bool) -> void:
	if not multiplayer.is_server():
		return

	freeze = not enabled
	if enabled:
		sleeping = false
