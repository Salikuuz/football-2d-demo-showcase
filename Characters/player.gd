class_name FootballPlayer
extends RigidBody2D


const DIRECTION_INDICATOR_SETTING: StringName = (
	&"gameplay/show_direction_indicator"
)


const SERVER_PEER_ID: int = 1
# Multiplayer movement transport is intentionally split into two rates:
# - input is event-driven with a small heartbeat, so holding one direction does
#   not generate a packet every render/physics frame;
# - authoritative position snapshots are sent at a lower rate and rendered
#   smoothly on clients by interpolation/extrapolation.
# This keeps 4v4 traffic down without making remote players visibly move at the
# snapshot rate.
const CLIENT_INPUT_MIN_SEND_INTERVAL_SECONDS: float = 1.0 / 60.0
const CLIENT_INPUT_HEARTBEAT_SECONDS: float = 1.0 / 30.0
const CLIENT_INPUT_DIRECTION_CHANGE_THRESHOLD: float = 0.025
const CLIENT_INPUT_IMMEDIATE_CHANGE_THRESHOLD: float = 0.12
const NETWORK_SNAPSHOT_EXTRAPOLATION_SECONDS: float = 0.040
# Steam/Internet delivery is not guaranteed to arrive at the exact cadence the
# server emits. Keep the 40 ms low-latency prediction used on clean links, but
# adapt the prediction window to the cadence actually observed by each client.
# This prevents a 50-70 ms packet gap from exhausting prediction and visibly
# freezing the replica for a few render frames before the next snapshot lands.
const NETWORK_SNAPSHOT_MAX_EXTRAPOLATION_SECONDS: float = 0.120
const NETWORK_SNAPSHOT_INTERVAL_BLEND: float = 0.20
const NETWORK_SNAPSHOT_INTERVAL_MAX_SAMPLE_SECONDS: float = 0.250
const NETWORK_SNAPSHOT_INTERVAL_MULTIPLIER: float = 1.75
const NETWORK_SNAPSHOT_JITTER_MARGIN_SECONDS: float = 0.008
const NETWORK_SNAPSHOT_STALE_DECAY_SECONDS: float = 0.045
const NETWORK_REMOTE_SMOOTHING_RESPONSE: float = 46.0
const NETWORK_LOCAL_SMOOTHING_RESPONSE: float = 56.0
const NETWORK_TELEPORT_SNAP_DISTANCE: float = 720.0
# Keep authoritative player replication at the original full 60 Hz in every
# team size. Large-match performance is handled by CPU work distribution, not
# by reducing visible remote-player snapshot cadence.
const NETWORK_PLAYER_SNAPSHOT_INTERVAL_DEFAULT: float = 1.0 / 60.0
# A NaN/INF transform makes a CollisionObject2D disappear from both rendering
# and physics even though the node still exists. Keep the guard deliberately
# far outside the real arena so it can only catch corrupt physics/network data.
const PHYSICS_SANITY_MAX_COORDINATE: float = 100000.0
const PHYSICS_SANITY_MAX_SPEED: float = 100000.0
const PHYSICS_SANITY_MAX_SINGLE_STEP_DISPLACEMENT: float = 20000.0
const BALL_COLLISION_LAYER_VALUE: int = 2
const DICTATOR_MBAPPE_DISPLAY_NAME: String = "Golden Striker"
const SATORU_GOJO_DISPLAY_NAME: String = "Satoru Gojo"
const NEYMAR_DISPLAY_NAME: String = "Neymar Jr"
const HAALAND_DISPLAY_NAME: String = "Erling Haaland"
const MANUEL_NEUER_DISPLAY_NAME: String = "Manuel Neuer"
const DICTATOR_NAME_GOLD: Color = Color(1.0, 0.82, 0.18, 1.0)
const DICTATOR_NAME_GOLD_BRIGHT: Color = Color(1.0, 0.96, 0.62, 1.0)
const DICTATOR_NAME_OUTLINE: Color = Color(0.26, 0.08, 0.01, 1.0)
const DICTATOR_NAME_SHADOW: Color = Color(1.0, 0.22, 0.03, 0.94)
const GOJO_NAME_PURPLE: Color = Color(0.61, 0.25, 1.0, 1.0)
const GOJO_NAME_PURPLE_BRIGHT: Color = Color(0.94, 0.74, 1.0, 1.0)
const GOJO_NAME_OUTLINE: Color = Color(0.11, 0.01, 0.25, 1.0)
const GOJO_NAME_SHADOW: Color = Color(1.0, 0.18, 0.52, 0.86)
const NEYMAR_NAME_YELLOW: Color = Color(1.0, 0.86, 0.18, 1.0)
const NEYMAR_NAME_GREEN: Color = Color(0.20, 0.78, 0.34, 1.0)
const NEYMAR_NAME_OUTLINE: Color = Color(0.02, 0.09, 0.25, 1.0)
const NEYMAR_NAME_SHADOW: Color = Color(0.10, 0.30, 0.70, 0.90)
const HAALAND_NAME_SKY: Color = Color(0.42, 0.82, 1.0, 1.0)
const HAALAND_NAME_WHITE: Color = Color(0.94, 0.99, 1.0, 1.0)
const HAALAND_NAME_OUTLINE: Color = Color(0.025, 0.08, 0.18, 1.0)
const HAALAND_NAME_SHADOW: Color = Color(0.12, 0.60, 0.95, 0.90)
const NEUER_NAME_TEAL: Color = Color(0.18, 0.88, 0.78, 1.0)
const NEUER_NAME_WHITE: Color = Color(0.94, 1.0, 0.98, 1.0)
const NEUER_NAME_OUTLINE: Color = Color(0.015, 0.10, 0.11, 1.0)
const NEUER_NAME_SHADOW: Color = Color(0.08, 0.62, 0.55, 0.90)
const PHANTOM_HEEL_PARTICLE_TEXTURE: Texture2D = preload(
	"res://Characters/ability_particle.svg"
)
const MIRAGE_STEP_PARTICLE_TEXTURE: Texture2D = preload(
	"res://Characters/mirage_step_particle.svg"
)
const ABILITY_PARTICLE_TEXTURES: Dictionary = {
	"classic": preload("res://Characters/ability_particle.svg"),
	"streaks": preload("res://Assets/cosmetics/particles/velocity_streak.svg"),
	"stars": preload("res://Assets/cosmetics/particles/star_particle.svg"),
	"orbits": preload("res://Assets/cosmetics/particles/orbit_particle.svg"),
	"shards": preload("res://Assets/cosmetics/particles/prism_shard.svg"),
	"wisps": preload("res://Assets/cosmetics/particles/void_wisp.svg"),
	"bubbles": preload("res://Assets/cosmetics/particles/bubble_particle.svg"),
	"comets": preload("res://Assets/cosmetics/particles/comet_spark.svg"),
}
const BALL_IMPACT_BODY_SOUND: AudioStream = preload(
	"res://Audio/ball_impact_body.wav"
)
const PHANTOM_HEEL_SOUND: AudioStream = preload(
	"res://Audio/phantom_heel_sharingan.wav"
)
const BURST_DRIBBLE_SOUND: AudioStream = preload("res://Audio/burst_dribble.wav")
const ENFORCER_SOUND: AudioStream = preload("res://Audio/enforcer_whip.wav")
const CURVE_SHOT_SOUND: AudioStream = preload("res://Audio/curve_shot.wav")
const DEAD_ZONE_PASS_SOUND: AudioStream = preload("res://Audio/dead_zone_pass.wav")
const REFLEX_BLOCK_SOUND: AudioStream = preload("res://Audio/reflex_shield.wav")
const BOOGIE_WOOGIE_SOUND: AudioStream = preload("res://Audio/boogie_woogie.mp3")
const ECHO_PLACEMENT_SOUND: AudioStream = preload("res://Audio/echo_anvil.mp3")
const MIRAGE_STEP_SOUND: AudioStream = preload("res://Audio/mirage_step_lightning.wav")
const DEFENSE_ECHO_SCRIPT = preload(
	"res://Characters/defense_echo.gd"
)

const ABILITY_NONE: int = 0
const ABILITY_BURST_DRIBBLE: int = 1
const ABILITY_QUICK_TRIGGER: int = 2
const ABILITY_POWER_STRIKE: int = 3
const ABILITY_OVERDRIVE: int = 4
const ABILITY_HEEL_TURN: int = 5
const ABILITY_ENFORCER: int = 6
const ABILITY_GOALKEEPER_REACH: int = 7
const ABILITY_TIME_SKIP_PASS: int = 8
const ABILITY_DIRECT_FINISH: int = 9
const ABILITY_ELASTIC_STEP: int = 10
const ABILITY_META_VISION: int = 11
const ABILITY_COPYCAT: int = 12
const ABILITY_REFLEX_BLOCK: int = 13
const ABILITY_IRON_ANCHOR: int = 14
const ABILITY_BLIND_SPOT: int = 15
const ABILITY_BOOGIE_WOOGIE: int = 16
const ABILITY_ECHO: int = 17
const ABILITY_RETURN_TAG: int = 18
const ABILITY_BREAKAWAY: int = 19
const ABILITY_SNAPBACK: int = 20
const ABILITY_SIDE_SWIPE: int = 21
const ABILITY_NUTMEG: int = 22
const ABILITY_DECOY_RUN: int = 23

# Echo uses two dedicated physics layers so only opponents collide with the
# stationary echo. The ball continues to use the existing server-side Echo
# blocker logic and therefore does not physically bounce from this body.
const ECHO_RED_COLLISION_LAYER_VALUE: int = 16
const ECHO_BLUE_COLLISION_LAYER_VALUE: int = 32
const ECHO_COLLISION_LAYER_VALUES: int = (
	ECHO_RED_COLLISION_LAYER_VALUE | ECHO_BLUE_COLLISION_LAYER_VALUE
)
const ABILITY_COUNT: int = 23

const ABILITY_ROLE_ATTACK: StringName = &"attack"
const ABILITY_ROLE_PLAYMAKER: StringName = &"playmaker"
const ABILITY_ROLE_FLEXIBLE: StringName = &"flexible"
const ABILITY_ROLE_DEFENSE: StringName = &"defense"

const ACTION_PULSE_SHOT: int = 0
const ACTION_PULSE_PASS: int = 1
const ACTION_PULSE_PASS_REQUEST: int = 2
const ACTION_PULSE_ABILITY: int = 3
const ACTION_PULSE_FULL_SHOT: int = 4
const ACTION_PULSE_POWER_STRIKE: int = 5

const HUMAN_FIRST_TOUCH_NONE: StringName = &"none"
const HUMAN_FIRST_TOUCH_TRAP: StringName = &"trap"
const HUMAN_FIRST_TOUCH_DUMMY: StringName = &"dummy"


signal ability_used(
	peer_id: int,
	player_team: StringName,
	ability_id: int
)


static func get_ability_role(ability_id: int) -> StringName:
	if ability_id in [
		ABILITY_BURST_DRIBBLE,
		ABILITY_DIRECT_FINISH,
		ABILITY_POWER_STRIKE,
		ABILITY_OVERDRIVE,
		ABILITY_BLIND_SPOT,
		ABILITY_BREAKAWAY,
		ABILITY_SNAPBACK,
		ABILITY_NUTMEG
	]:
		return ABILITY_ROLE_ATTACK
	if ability_id in [
		ABILITY_QUICK_TRIGGER,
		ABILITY_ELASTIC_STEP,
		ABILITY_HEEL_TURN,
		ABILITY_TIME_SKIP_PASS,
		ABILITY_META_VISION,
		ABILITY_BOOGIE_WOOGIE,
		ABILITY_RETURN_TAG,
		ABILITY_SIDE_SWIPE
	]:
		return ABILITY_ROLE_PLAYMAKER
	if ability_id in [ABILITY_NONE, ABILITY_COPYCAT, ABILITY_DECOY_RUN]:
		return ABILITY_ROLE_FLEXIBLE
	if ability_id in [
		ABILITY_ENFORCER,
		ABILITY_GOALKEEPER_REACH,
		ABILITY_REFLEX_BLOCK,
		ABILITY_IRON_ANCHOR,
		ABILITY_ECHO
	]:
		return ABILITY_ROLE_DEFENSE
	return ABILITY_ROLE_FLEXIBLE


static func get_ability_ids_for_role(role: StringName) -> Array[int]:
	match role:
		ABILITY_ROLE_ATTACK:
			return [
				ABILITY_BURST_DRIBBLE,
				ABILITY_DIRECT_FINISH,
				ABILITY_POWER_STRIKE,
				ABILITY_OVERDRIVE,
				ABILITY_BLIND_SPOT,
				ABILITY_BREAKAWAY,
				ABILITY_SNAPBACK,
				ABILITY_NUTMEG
			]
		ABILITY_ROLE_PLAYMAKER:
			return [
				ABILITY_QUICK_TRIGGER,
				ABILITY_ELASTIC_STEP,
				ABILITY_HEEL_TURN,
				ABILITY_TIME_SKIP_PASS,
				ABILITY_META_VISION,
				ABILITY_BOOGIE_WOOGIE,
				ABILITY_RETURN_TAG,
				ABILITY_SIDE_SWIPE
			]
		ABILITY_ROLE_FLEXIBLE:
			return [ABILITY_NONE, ABILITY_COPYCAT, ABILITY_DECOY_RUN]
		ABILITY_ROLE_DEFENSE:
			return [
				ABILITY_ENFORCER,
				ABILITY_GOALKEEPER_REACH,
				ABILITY_REFLEX_BLOCK,
				ABILITY_IRON_ANCHOR,
				ABILITY_ECHO
			]
	return []

const ABILITY_NAMES: Dictionary = {
	ABILITY_BURST_DRIBBLE: "Burst Dribble",
	ABILITY_QUICK_TRIGGER: "Curve Shot",
	ABILITY_POWER_STRIKE: "Power Strike",
	ABILITY_OVERDRIVE: "Overdrive",
	ABILITY_HEEL_TURN: "Phantom Heel",
	ABILITY_ENFORCER: "Enforcer",
	ABILITY_GOALKEEPER_REACH: "Goalkeeper's Reach",
	ABILITY_TIME_SKIP_PASS: "Dead Zone Pass",
	ABILITY_DIRECT_FINISH: "Trap or Volley",
	ABILITY_ELASTIC_STEP: "Elastic Step",
	ABILITY_META_VISION: "Meta Vision",
	ABILITY_COPYCAT: "Copycat",
	ABILITY_REFLEX_BLOCK: "Reflex Block",
	ABILITY_IRON_ANCHOR: "Iron Anchor",
	ABILITY_BLIND_SPOT: "Mirage Step",
	ABILITY_BOOGIE_WOOGIE: "Boogie Woogie",
	ABILITY_ECHO: "Echo",
	ABILITY_RETURN_TAG: "Return Tag",
	ABILITY_BREAKAWAY: "Breakaway",
	ABILITY_SNAPBACK: "Snapback",
	ABILITY_SIDE_SWIPE: "Side Swipe",
	ABILITY_NUTMEG: "Nutmeg",
	ABILITY_DECOY_RUN: "Decoy Run"
}

const ABILITY_DESCRIPTIONS: Dictionary = {
	ABILITY_NONE: "Equip no special ability. Your movement, charged shots, and team play remain fully available.",
	ABILITY_BURST_DRIBBLE: "Gain two short explosive dashes for beating a defender while keeping the ball within playing distance. The full cooldown starts after the final dash.",
	ABILITY_QUICK_TRIGGER: "Empower your next charged shot to bend around one nearby defender in its path. Hold the side you want the ball to curve toward with your movement input as you release Shoot. With no side input, Curve Shot keeps its automatic bend.",
	ABILITY_POWER_STRIKE: "Enter a temporary power state that makes charged shots dramatically heavier. A struck ball ignites and stays empowered until it loses speed.",
	ABILITY_OVERDRIVE: "Temporarily increase movement speed and acceleration for breakaways, recovery runs, and reaching passes before the opposition.",
	ABILITY_HEEL_TURN: "Press once near the ball to kill its momentum and heel-drag it diagonally behind you. During the short follow-up window, press Ability again to cut forward across the defender's opposite side. Hold a side for the first drag; with no input, it chooses the safer pocket.",
	ABILITY_ENFORCER: "Enter a physical power state where your kicks can launch opposing players away, opening space for yourself and your teammates.",
	ABILITY_GOALKEEPER_REACH: "Dive rapidly in your movement direction and control one ball caught inside the extended reach. Best used on shots normal movement cannot reach.",
	ABILITY_TIME_SKIP_PASS: "Fire a rapid pass that brakes inside a teammate's path. Aim away from teammates to push it into space as a decelerating self-pass.",
	ABILITY_DIRECT_FINISH: "Choose your reception: press Ability to arm a controlled trap, or double-tap Shoot to arm a powerful first-time volley. The chosen action triggers when the incoming ball reaches you.",
	ABILITY_ELASTIC_STEP: "Chain four close-control slalom touches around the ball. Each press reads your movement and nearby defenders, then carries the ball with your step so the next touch stays under control.",
	ABILITY_META_VISION: "Reveal long ball trajectories, wall bounces, interception points, and dangerous goal paths for perfect reads while the effect is active.",
	ABILITY_COPYCAT: "Capture the next eligible teammate ability and hold it for up to 12 seconds or until you use it. The copy fires at 90% strength with 1.5 seconds extra cooldown. Goalkeeper's Reach cannot be copied.",
	ABILITY_REFLEX_BLOCK: "Guard a forward cone for a brief moment and deflect one incoming ball sideways, turning a save or interception into a counterattack.",
	ABILITY_IRON_ANCHOR: "Instantly nullify the velocity of one nearby ball. Kill a dangerous shot, interrupt a dribble, or bring a difficult ball under control.",
	ABILITY_BLIND_SPOT: "Slip through a nearby opponent and reappear behind them. A ball under your control travels through the shadow with you, creating an immediate dribbling escape.",
	ABILITY_BOOGIE_WOOGIE: "Swap positions with the nearest opponent. Your arrival creates a shockwave that pushes the ball and other nearby enemies away.",
	ABILITY_ECHO: "Leave a blinking defensive echo at your current position for 5 seconds. It physically blocks enemy players and completely stops the first opposing moving ball that reaches it, including full-speed shots and Power Strikes.",
	ABILITY_RETURN_TAG: "Arm your next normal kick with a return tag. A teammate who presses Pass on the tagged ball sends a properly led return into the safest forward lane for a clean one-two.",
	ABILITY_BREAKAWAY: "Press Ability with the ball to knock a controlled touch beyond the defender into the clearest forward lane and burst after it. Away from the ball, it stays armed until you press Pass in range.",
	ABILITY_SNAPBACK: "Arm your next pass or normal shot, then press Ability again during the longer recall window. The marked ball snaps back fast and curves toward your predicted running position; another player touch cancels it.",
	ABILITY_SIDE_SWIPE: "Arm a diagonal side-cut for 4 seconds. Hold a side, then Pass or Shoot to carve the ball forward around pressure. With no side input, it chooses the safer escape lane.",
	ABILITY_NUTMEG: "Arm your next controlled touch. If an opponent blocks its route, the ball passes through them once and you gain a short forward burst to race around and collect it.",
	ABILITY_DECOY_RUN: "Send a fading afterimage running in your current direction while your real player becomes briefly muted. It changes no collision and grants no invisibility."
}


@export var owner_peer_id: int = 1
@export var cpu_controlled: bool = false
@export var training_dummy: bool = false

@export var display_name: String = "Player":
	set(value):
		display_name = value
		if is_node_ready():
			_update_name_label()

@export var cosmetic_loadout: Dictionary = {
	"version": 13,
	"battle_pass_complete": false,
	"player_skin": "player_skin.classic",
	"team_player_skins_enabled": false,
	"player_skin_blue": "player_skin.classic",
	"player_skin_red": "player_skin.classic",
	"frame_palette": "frame_palette.classic_touch",
	"frame_palette_blue": "frame_palette.classic_touch",
	"frame_palette_red": "frame_palette.classic_touch",
	"player_material": "player_material.matte",
	"player_material_blue": "player_material.matte",
	"player_material_red": "player_material.matte",
	"team_primary_color_blue": 0,
	"team_primary_color_red": 0,
	"special_team_color_override": "",
	"player_skin_color_index": -1,
	"player_skin_color_blue": -1,
	"player_skin_color_red": -1,
	"goal_explosion": "goal_explosion.classic",
	"goal_explosion_blue": "goal_explosion.classic",
	"goal_explosion_red": "goal_explosion.classic",
	"goal_explosion_color_index": -1,
	"goal_theme": "goal_theme.classic",
	"goal_theme_blue": "goal_theme.classic",
	"goal_theme_red": "goal_theme.classic",
	"player_banner": "player_banner.classic",
	"player_banner_blue": "player_banner.classic",
	"player_banner_red": "player_banner.classic",
	"player_banner_color_index": -1,
	"player_banner_color_blue": -1,
	"player_banner_color_red": -1,
	"ability_particle": "ability_particle.classic",
	"ability_particle_blue": "ability_particle.classic",
	"ability_particle_red": "ability_particle.classic",
	"player_subtitle": "",
	"quick_chat": [
		"quick_chat.nice_shot",
		"quick_chat.great_pass",
		"quick_chat.what_a_save",
		"quick_chat.defending",
		"quick_chat.passing",
		"quick_chat.centering",
		"quick_chat.sorry",
		"quick_chat.gg",
	],
}:
	set(value):
		cosmetic_loadout = (
			FootballCosmeticInventory.sanitize_catalog_network_loadout(value)
		)
		if is_node_ready():
			_apply_cosmetic_loadout()

@export_category("Movement")
@export var acceleration: float = 5900.0
@export var max_speed: float = 5550.0

@export_category("Charged Shot")
@export var minimum_shot_force: float = 700.0
@export var maximum_shot_force: float = 3000.0
@export var maximum_charge_seconds: float = 1.5
@export var shot_buffer_seconds: float = 0.3

@export_category("Soft Pass")
@export var soft_pass_force: float = 520.0
@export var soft_pass_cooldown_seconds: float = 0.75
@export var soft_pass_shot_lockout_seconds: float = 0.35

const REVERSE_DRAG_MIN_INPUT_STRENGTH: float = 0.62
const REVERSE_DRAG_MAX_REVERSAL_DOT: float = -0.52
const REVERSE_DRAG_DIRECTION_MEMORY_SECONDS: float = 0.42
const REVERSE_DRAG_EXECUTION_WINDOW_SECONDS: float = 0.36
const REVERSE_DRAG_MIN_FORCE: float = 620.0
const REVERSE_DRAG_MAX_FORCE: float = 900.0
const REVERSE_DRAG_TOUCH_COOLDOWN_SECONDS: float = 0.14
const REVERSE_DRAG_SHOT_LOCKOUT_SECONDS: float = 0.10
const REVERSE_DRAG_CHAIN_WINDOW_SECONDS: float = 0.90
const REVERSE_DRAG_CHAIN_MIN_INPUT_STRENGTH: float = 0.28
const REVERSE_DRAG_CHAIN_MIN_DIRECTION_DOT: float = -0.08
const REVERSE_DRAG_CHAIN_MIN_FORCE: float = 560.0
const REVERSE_DRAG_CHAIN_MAX_FORCE: float = 780.0
const REVERSE_DRAG_CHAIN_STEER_WEIGHT: float = 0.62
const REVERSE_DRAG_INITIAL_CONTROL_STRENGTH: float = 0.90
const REVERSE_DRAG_CHAIN_CONTROL_STRENGTH: float = 0.88

@export_category("Human First Touch")
@export var human_first_touch_enabled: bool = true
@export var human_first_touch_anticipation_distance: float = 1150.0
@export var human_first_touch_minimum_incoming_speed: float = 260.0
@export var human_first_touch_plan_seconds: float = 1.25
@export var human_first_touch_trap_speed: float = 105.0
@export var human_first_touch_dummy_distance: float = 380.0
@export var human_first_touch_dummy_seconds: float = 0.28

@export_category("Player Feedback")
@export var kick_feedback_detection_distance: float = 270.0
@export var kick_range_idle_color: Color = Color(
	0.4, 0.72, 1.0, 0.24
)
@export var kick_range_ready_color: Color = Color(
	1.0, 0.86, 0.22, 0.92
)
@export var kick_confirmed_color: Color = Color(
	0.22, 1.0, 0.46, 0.96
)
@export var kick_range_miss_color: Color = Color(
	1.0, 0.2, 0.22, 0.95
)
@export var charge_low_color: Color = Color(
	0.25, 0.85, 1.0, 1.0
)
@export var charge_middle_color: Color = Color(
	1.0, 0.86, 0.18, 1.0
)
@export var charge_high_color: Color = Color(
	1.0, 0.22, 0.12, 1.0
)
@export_range(0.05, 0.6, 0.01)
var soft_shot_zone_end: float = 0.32
@export_range(0.4, 0.95, 0.01)
var power_shot_zone_start: float = 0.72
@export var shot_preview_minimum_length: float = 1400.0
@export var shot_preview_maximum_length: float = 3200.0
@export_range(0, 6, 1)
var shot_preview_maximum_bounces: int = 3
@export_flags_2d_physics
var shot_preview_wall_collision_mask: int = 8
@export var shot_aim_guide_radius: float = 340.0
@export var shot_aim_guide_ball_clearance: float = 110.0
@export_range(8.0, 100.0, 1.0)
var shot_aim_guide_arc_degrees: float = 42.0
@export_range(4, 24, 1)
var shot_aim_guide_point_count: int = 16
@export var shot_aim_guide_color: Color = Color(
	0.68, 0.94, 1.0, 0.88
)

@export_category("Direction Arrow")
@export var direction_arrow_color: Color = Color(
	1.0, 1.0, 1.0, 0.26
)
@export_range(60.0, 320.0, 1.0)
var direction_arrow_distance: float = 188.0
@export_range(0.1, 2.5, 0.01)
var direction_arrow_scale_multiplier: float = 0.62

@export_category("Networked Action Pulse")
@export var action_pulse_shot_color: Color = Color(
	1.0, 0.94, 0.72, 1.0
)
@export var action_pulse_pass_color: Color = Color(
	0.12, 0.82, 1.0, 1.0
)
@export var action_pulse_pass_request_color: Color = Color(
	0.38, 1.0, 0.62, 1.0
)
@export var action_pulse_default_ability_color: Color = Color(
	0.72, 0.36, 1.0, 1.0
)
@export var action_pulse_full_shot_color: Color = Color(
	1.0, 0.76, 0.18, 1.0
)
@export var action_pulse_power_strike_color: Color = Color(
	1.0, 0.08, 0.12, 1.0
)
@export_range(0.20, 1.20, 0.01)
var ability_activation_cue_seconds: float = 0.46
@export_range(0.0, 1.0, 0.01)
var ability_active_ring_alpha: float = 0.30
@export_range(0.0, 1.0, 0.01)
var full_charge_anticipation_start: float = 0.72
@export_range(0.01, 0.12, 0.001)
var action_pulse_attack_seconds: float = 0.055
@export_range(0.08, 0.80, 0.01)
var action_pulse_release_seconds: float = 0.36
@export_range(0.60, 1.00, 0.01)
var action_pulse_start_scale: float = 0.84
@export_range(1.05, 1.70, 0.01)
var action_pulse_end_scale: float = 1.30
@export_range(1.0, 24.0, 0.5)
var action_pulse_line_width: float = 10.0
@export_range(0.0, 30.0, 1.0)
var action_pulse_radius_padding: float = 8.0
@export_range(16, 96, 1)
var action_pulse_point_count: int = 48

@export_category("Player Name")
@export var blue_name_color: Color = Color(0.35, 0.68, 1.0)
@export var red_name_color: Color = Color(1.0, 0.35, 0.38)
@export var neutral_name_color: Color = Color.WHITE

@export_category("Player Badge Visual")
@export var badge_outer_radius: float = 132.0
@export var badge_team_ring_radius: float = 124.0
@export var badge_white_trim_radius: float = 111.0
@export var badge_inner_radius: float = 103.0
@export var badge_shadow_offset: Vector2 = Vector2(0.0, 13.0)
@export var badge_blue_color: Color = Color(0.16, 0.55, 1.0)
@export var badge_red_color: Color = Color(1.0, 0.22, 0.3)
@export var badge_neutral_color: Color = Color(0.58, 0.65, 0.72)
@export var badge_inner_color: Color = Color(0.035, 0.065, 0.09)

@export_category("Ability Selection")
@export_range(0, ABILITY_COUNT, 1)
var selected_ability: int = ABILITY_NONE:
	set(value):
		selected_ability = clampi(
			value,
			ABILITY_NONE,
			ABILITY_COUNT
		)
		if is_node_ready():
			_update_ability_portrait(true)
			_refresh_soft_glow()

var draft_perk_id: int = 0
var draft_perk_speed_multiplier: float = 1.0
var draft_perk_acceleration_multiplier: float = 1.0
var draft_perk_shot_force_multiplier: float = 1.0
var draft_perk_pass_force_multiplier: float = 1.0
var draft_perk_charge_time_multiplier: float = 1.0
var draft_perk_cooldown_multiplier: float = 1.0
var draft_perk_pass_cooldown_multiplier: float = 1.0
var draft_perk_ability_strength_multiplier: float = 1.0
var draft_perk_ability_duration_multiplier: float = 1.0
var draft_perk_action_speed_until: float = 0.0
var draft_perk_action_speed_multiplier: float = 1.0
var draft_perk_action_acceleration_until: float = 0.0
var draft_perk_action_acceleration_multiplier: float = 1.0
var draft_perk_last_completed_pass_at: float = -9999.0
var draft_perk_ability_to_pass_until: float = 0.0
var draft_perk_next_shot_until: float = 0.0
var draft_perk_next_shot_multiplier: float = 1.0
var draft_perk_next_pass_until: float = 0.0
var draft_perk_next_pass_multiplier: float = 1.0
var draft_perk_curve_pass_until: float = 0.0
var draft_perk_shot_cycle_until: float = 0.0
var draft_perk_completed_pass_count: int = 0
var draft_perk_kickoff_encore_available: bool = true
var draft_perk_next_cooldown_free: bool = false
var draft_perk_reverse_card_available: bool = true
var draft_perk_double_feature_uses: int = 0
var draft_perk_copycat_uses_remaining: int = 0
var server_mirage_step_charges: int = 1
var server_breakaway_charges: int = 1

@export_category("Ability Player Skin Image Slots")
@export var no_ability_skin: Texture2D
@export var burst_dribble_skin: Texture2D
@export var curve_shot_skin: Texture2D
@export var power_strike_skin: Texture2D
@export var overdrive_skin: Texture2D
@export var heel_turn_skin: Texture2D
@export var enforcer_skin: Texture2D
@export var goalkeeper_reach_skin: Texture2D
@export var time_skip_pass_skin: Texture2D
@export var direct_finish_skin: Texture2D
@export var elastic_step_skin: Texture2D
@export var meta_vision_skin: Texture2D
@export var copycat_skin: Texture2D
@export var reflex_block_skin: Texture2D
@export var iron_anchor_skin: Texture2D
@export var blind_spot_skin: Texture2D
@export var boogie_woogie_skin: Texture2D
@export var echo_skin: Texture2D
@export var return_tag_skin: Texture2D
@export var breakaway_skin: Texture2D
@export var snapback_skin: Texture2D
@export var side_swipe_skin: Texture2D
@export var nutmeg_skin: Texture2D
@export var decoy_run_skin: Texture2D
@export_range(40.0, 220.0, 1.0)
var ability_skin_diameter: float = 164.0

@export_category("Ability 1 - Burst Dribble")
@export var burst_duration: float = 0.1
@export var burst_cooldown: float = 3.0
@export var burst_impulse: float = 1100.0
@export var burst_acceleration_multiplier: float = 4.0
@export var burst_speed_multiplier: float = 1.5
@export var burst_ball_contact_speed_limit: float = 900.0
@export var burst_ball_control_radius: float = 360.0
@export_range(1, 5, 1)
var burst_max_charges: int = 2
@export var burst_delay_between_dashes: float = 0.2

@export_category("Ability 2 - Curve Shot")
@export var curve_shot_effect_duration: float = 6.0
@export var curve_shot_cooldown: float = 9.0
@export var curve_shot_ball_duration: float = 1.4
@export var curve_shot_steering_radians_per_second: float = 0.6
@export var curve_shot_minimum_ball_speed: float = 300.0
@export_range(1.0, 2.0, 0.01)
var curve_shot_force_multiplier: float = 1.18
@export_range(0.0, 1.0, 0.01)
var curve_shot_goal_assist_strength: float = 0.18
@export_range(0.0, 45.0, 0.5)
var curve_shot_max_aim_correction_degrees: float = 10.0
@export var curve_shot_blocker_search_radius: float = 900.0
@export var curve_shot_lane_half_width: float = 225.0
@export var curve_shot_blocker_minimum_forward_distance: float = 520.0
@export var curve_shot_blocker_avoidance_clearance: float = 225.0
@export var curve_shot_blocker_pass_margin: float = 95.0
@export_range(0.1, 6.0, 0.01)
var curve_shot_blocker_steering_multiplier: float = 4.8

@export_category("Ability 3 - Power Strike")
@export var power_strike_duration: float = 6.0
@export var power_strike_cooldown: float = 6.0
@export var power_strike_force_multiplier: float = 1.75

@export_category("Boss - Erling Haaland")
@export_range(1.0, 2.0, 0.01)
var haaland_boss_speed_multiplier: float = 1.22
@export_range(1.0, 2.0, 0.01)
var haaland_boss_acceleration_multiplier: float = 1.18
@export_range(1.0, 2.0, 0.01)
var haaland_predator_speed_multiplier: float = 1.34
@export_range(1.0, 3.0, 0.01)
var haaland_predator_acceleration_multiplier: float = 1.55
@export_range(0.25, 1.0, 0.01)
var haaland_predator_charge_time_multiplier: float = 0.58
@export_range(1.0, 8.0, 0.1)
var haaland_predator_duration: float = 4.5

@export_category("Ability 4 - Overdrive")
@export var overdrive_duration: float = 4.0
@export var overdrive_cooldown: float = 6.0
@export var overdrive_speed_multiplier: float = 1.5
@export var overdrive_acceleration_multiplier: float = 1.5

@export_category("Ability 5 - Phantom Heel")
@export var heel_turn_cooldown: float = 5.0
@export var heel_turn_ball_distance: float = 260.0
@export var heel_turn_ball_speed: float = 0.0
@export_range(10.0, 80.0, 1.0)
var heel_turn_exit_angle_degrees: float = 32.0
@export var heel_turn_lane_probe_distance: float = 760.0
@export var heel_turn_followup_window: float = 1.25
@export var heel_turn_followup_delay: float = 0.10
@export var heel_turn_followup_ball_distance: float = 420.0
@export var heel_turn_followup_ball_speed: float = 1700.0
@export var heel_turn_followup_player_step_speed: float = 1500.0
@export_range(0.0, 1.5, 0.01)
var heel_turn_followup_side_weight: float = 0.42
@export var heel_turn_ball_minimum_x: float = 355.0
@export var heel_turn_ball_maximum_x: float = 6994.0
@export var heel_turn_ball_minimum_y: float = 806.0
@export var heel_turn_ball_maximum_y: float = 4194.0
@export_category("Phantom Heel Sound")
@export_range(-80.0, 24.0, 0.1)
var phantom_heel_sound_volume_db: float = -15.0
@export_range(0.1, 4.0, 0.01)
var phantom_heel_sound_pitch_scale: float = 1.0
@export_category("Phantom Heel Visuals")
@export var phantom_heel_shadow_radius: float = 58.0
@export var phantom_heel_shadow_duration: float = 0.65
@export_range(3, 64, 1)
var phantom_heel_shadow_points: int = 28
@export_range(1, 128, 1)
var phantom_heel_particle_amount: int = 46
@export var phantom_heel_particle_lifetime: float = 0.7
@export var phantom_heel_particle_speed_min: float = 85.0
@export var phantom_heel_particle_speed_max: float = 230.0
@export var phantom_heel_shadow_color: Color = Color(
	0.07,
	0.0,
	0.012,
	0.92
)
@export var phantom_heel_rim_color: Color = Color(
	0.95,
	0.025,
	0.075,
	0.84
)
@export var phantom_heel_particle_color: Color = Color(
	1.0,
	0.055,
	0.12,
	0.98
)

@export_category("Ability 6 - Enforcer")
@export var enforcer_duration: float = 6.0
@export var enforcer_cooldown: float = 5.0
@export var enforcer_player_kick_force_multiplier: float = 1.0

@export_category("Ability 7 - Goalkeeper's Reach")
@export var goalkeeper_reach_duration: float = 0.35
@export var goalkeeper_reach_cooldown: float = 6.0
@export var goalkeeper_reach_impulse: float = 2400.0
@export var goalkeeper_reach_speed_multiplier: float = 1.8
@export var goalkeeper_reach_radius: float = 280.0
@export_range(0.0, 1.0, 0.01)
var goalkeeper_ball_speed_retention: float = 0.45
@export var goalkeeper_ball_speed_limit: float = 1400.0

@export_category("Ability 8 - Dead Zone Pass")
@export var time_skip_pass_cooldown: float = 8.0
@export var time_skip_pass_initial_speed: float = 7200.0
@export var time_skip_pass_slow_speed: float = 850.0
@export var time_skip_pass_stopping_deceleration: float = 1500.0
@export var time_skip_pass_stop_speed: float = 45.0
@export var time_skip_pass_maximum_receiver_distance: float = 4300.0
@export_range(10.0, 180.0, 1.0)
var time_skip_pass_receiver_cone_degrees: float = 76.0
@export var time_skip_pass_receiver_lead_seconds: float = 0.2
@export var time_skip_pass_self_distance: float = 1500.0
@export var time_skip_pass_minimum_fast_duration: float = 0.08
@export var time_skip_pass_maximum_fast_duration: float = 0.52

@export_category("Ability 9 - Trap or Volley")
@export var direct_finish_cooldown: float = 8.0
@export var direct_finish_timing_window: float = 3.0
@export var direct_finish_activation_radius: float = 760.0
@export var direct_finish_contact_distance: float = 220.0
@export var direct_finish_minimum_ball_speed: float = 120.0
@export_range(-1.0, 1.0, 0.01)
var direct_finish_minimum_approach_dot: float = -0.8
@export_range(0.12, 0.5, 0.01)
var direct_finish_double_tap_seconds: float = 0.28
@export var direct_finish_trap_minimum_ball_speed: float = 35.0
@export_range(-1.0, 1.0, 0.01)
var direct_finish_trap_minimum_approach_dot: float = -1.0
@export_range(0.1, 1.5, 0.01)
var direct_finish_maximum_force_ratio: float = 1.15
@export_range(0.0, 1.0, 0.01)
var direct_finish_trap_velocity_ratio: float = 0.0
@export var direct_finish_trap_control_distance: float = 145.0

@export_category("Ability 10 - Elastic Step")
@export var elastic_step_duration: float = 0.12
@export var elastic_step_cooldown: float = 7.0
@export var elastic_step_dash_speed: float = 1750.0
@export var elastic_step_orbit_distance: float = 190.0
@export_range(5.0, 120.0, 1.0)
var elastic_step_orbit_degrees: float = 30.0
@export var elastic_step_max_travel_distance: float = 250.0
@export var elastic_step_exit_speed: float = 950.0
@export var elastic_step_acceleration_multiplier: float = 2.7
@export var elastic_step_speed_multiplier: float = 1.32
@export_range(1, 5, 1)
var elastic_step_max_charges: int = 4
@export var elastic_step_delay_between_uses: float = 0.12
@export var elastic_step_ball_touch_speed: float = 1750.0
@export_range(0.5, 1.0, 0.01)
var elastic_step_ball_carry_ratio: float = 0.96
@export_range(0.0, 0.3, 0.01)
var elastic_step_ball_lead_weight: float = 0.08

@export_category("Ability 11 - Meta Vision")
@export var meta_vision_duration: float = 4.0
@export var meta_vision_cooldown: float = 12.0
@export_range(4, 64, 1)
var meta_vision_prediction_steps: int = 28
@export var meta_vision_prediction_step_seconds: float = 0.08
@export_flags_2d_physics
var meta_vision_wall_collision_mask: int = 8
@export var meta_vision_collision_margin: float = 2.0
@export var meta_vision_intercept_reach_margin: float = 150.0
@export var meta_vision_own_intercept_color: Color = Color(
	0.22, 1.0, 0.48, 0.95
)
@export var meta_vision_enemy_intercept_color: Color = Color(
	1.0, 0.18, 0.24, 0.95
)
@export var meta_vision_danger_minimum_ball_speed: float = 350.0

@export_category("Ability 12 - Copycat")
@export_range(0.1, 1.0, 0.01)
var copycat_strength_multiplier: float = 0.90
@export var copycat_extra_cooldown: float = 1.5
@export var copycat_memory_seconds: float = 12.0
@export var copycat_fallback_cooldown: float = 10.0

@export_category("Ability 13 - Reflex Block")
@export var reflex_block_duration: float = 0.45
@export var reflex_block_cooldown: float = 6.0
@export var reflex_block_radius: float = 360.0
@export_range(1.0, 179.0, 1.0)
var reflex_block_cone_degrees: float = 110.0
@export var reflex_block_minimum_ball_speed: float = 200.0
@export_range(0.0, 1.0, 0.01)
var reflex_block_speed_retention: float = 0.72
@export var reflex_block_speed_limit: float = 2800.0
@export_range(0.0, 90.0, 1.0)
var reflex_block_deflection_degrees: float = 52.0

@export_category("Ability 14 - Iron Anchor")
@export var iron_anchor_cooldown: float = 6.75
@export var iron_anchor_trap_radius: float = 400.0
@export_range(0.0, 1.0, 0.01)
var iron_anchor_ball_velocity_retention: float = 0.0
@export var iron_anchor_trap_visual_radius: float = 95.0

@export_category("Ability 15 - Mirage Step")
@export var blind_spot_cooldown: float = 8.0
@export var blind_spot_search_radius: float = 700.0
@export var blind_spot_distance_behind_target: float = 280.0
@export var blind_spot_enemy_collision_ignore_seconds: float = 0.3
@export var blind_spot_ball_carry_distance: float = 155.0
@export var blind_spot_ball_exit_speed: float = 720.0
@export_range(8, 128, 1)
var blind_spot_particle_amount: int = 54
@export var blind_spot_particle_lifetime: float = 0.42
@export var blind_spot_particle_path_width: float = 24.0
@export var blind_spot_particle_speed_min: float = 45.0
@export var blind_spot_particle_speed_max: float = 135.0
@export var blind_spot_particle_scale_min: float = 0.12
@export var blind_spot_particle_scale_max: float = 0.32
@export var blind_spot_trail_color: Color = Color(
	0.70, 0.26, 1.0, 0.98
)
@export var blind_spot_shadow_step_duration: float = 0.18
@export var blind_spot_shadow_arc_distance: float = 125.0
@export var blind_spot_shadow_color: Color = Color(
	0.20, 0.03, 0.34, 0.94
)

@export_category("Ability 16 - Boogie Woogie")
@export var boogie_woogie_cooldown: float = 10.0
@export var boogie_woogie_primary_color: Color = Color(
	0.74, 0.28, 1.0, 1.0
)
@export var boogie_woogie_secondary_color: Color = Color(
	0.2, 0.95, 1.0, 1.0
)
@export var boogie_woogie_shockwave_radius: float = 360.0
@export var boogie_woogie_ball_push_impulse: float = 700.0
@export var boogie_woogie_enemy_push_impulse: float = 550.0
@export_range(0.0, 1.0, 0.01)
var boogie_woogie_edge_force_fraction: float = 0.35

@export_category("Ability 17 - Echo")
@export var echo_duration: float = 5.0
@export var echo_cooldown: float = 11.0
@export var echo_collision_radius: float = 132.0
@export var echo_minimum_trigger_speed: float = 1.0
@export var echo_stop_speed_limit: float = 4700.0
@export_range(0.0, 1.0, 0.01)
var echo_fast_ball_speed_retention: float = 0.55

@export_category("Ability 18 - Return Tag")
@export var return_tag_arming_duration: float = 5.0
@export var return_tag_mark_duration: float = 5.5
@export var return_tag_cooldown: float = 10.0
@export var return_tag_return_speed: float = 2750.0
@export var return_tag_maximum_return_speed: float = 3900.0
@export var return_tag_lead_seconds: float = 0.16
@export var return_tag_minimum_distance: float = 240.0
@export var return_tag_forward_lead_distance: float = 520.0
@export var return_tag_side_lead_distance: float = 260.0

@export_category("Ability 19 - Breakaway")
@export var breakaway_arming_duration: float = 4.0
@export var breakaway_cooldown: float = 9.0
@export var breakaway_ball_speed: float = 5600.0
@export var breakaway_ball_lead_over_player_speed: float = 1350.0
@export var breakaway_maximum_ball_speed: float = 7600.0
@export var breakaway_player_impulse: float = 620.0
@export var breakaway_chase_duration: float = 0.72
@export var breakaway_chase_speed_multiplier: float = 1.48
@export var breakaway_chase_acceleration_multiplier: float = 2.35
@export var breakaway_lane_angle_degrees: float = 28.0
@export var breakaway_lane_probe_distance: float = 1450.0
@export var breakaway_lane_clearance_threshold: float = 300.0
@export var breakaway_shot_lockout_seconds: float = 0.08
@export_range(0.0, 1.0, 0.01)
var breakaway_minimum_forward_input_dot: float = 0.20

@export_category("Ability 20 - Snapback")
@export var snapback_arming_duration: float = 4.5
@export var snapback_recall_window: float = 1.55
@export var snapback_cooldown: float = 10.0
@export var snapback_recall_speed: float = 4850.0
@export var snapback_maximum_recall_speed: float = 6800.0
@export var snapback_lead_seconds: float = 0.18
@export var snapback_curve_duration: float = 0.78
@export var snapback_curve_turn_rate: float = 15.0
@export var snapback_maximum_distance: float = 2600.0
@export var snapback_minimum_recall_delay: float = 0.08

@export_category("Ability 21 - Side Swipe")
@export var side_swipe_arming_duration: float = 4.0
@export var side_swipe_cooldown: float = 9.5
@export var side_swipe_pass_force: float = 1850.0
@export_range(0.5, 1.5, 0.01)
var side_swipe_shot_force_multiplier: float = 1.08
@export_range(0.0, 1.0, 0.01)
var side_swipe_minimum_shot_ratio: float = 0.48
@export var side_swipe_lane_probe_distance: float = 1300.0
@export var side_swipe_lane_clearance_radius: float = 240.0
@export_range(0.0, 1.0, 0.01)
var side_swipe_forward_blend: float = 0.62

@export_category("Ability 22 - Nutmeg")
@export var nutmeg_arming_duration: float = 4.0
@export var nutmeg_cooldown: float = 8.0
@export var nutmeg_probe_distance: float = 950.0
@export var nutmeg_lane_half_width: float = 145.0
@export var nutmeg_collision_clearance: float = 170.0
@export var nutmeg_maximum_ignore_seconds: float = 0.65
@export var nutmeg_exit_impulse: float = 440.0
@export var nutmeg_outplay_duration: float = 0.95
@export var nutmeg_outplay_speed_multiplier: float = 1.52
@export var nutmeg_outplay_acceleration_multiplier: float = 2.35

@export_category("Ability 23 - Decoy Run")
@export var decoy_run_duration: float = 1.15
@export var decoy_run_cooldown: float = 7.0
@export var decoy_run_minimum_speed: float = 480.0
@export_range(0.15, 0.9, 0.01)
var decoy_run_player_alpha: float = 0.48

@export_category("Ability Sounds")
@export var ability_used_sound: AudioStream
@export var ability_ready_sound: AudioStream
@export_range(-80.0, 24.0, 0.1)
var ability_sound_volume_db: float = -8.0
@export_range(-80.0, 24.0, 0.1)
var ability_ready_volume_db: float = -16.0
@export_range(0.1, 4.0, 0.01)
var ability_used_pitch_scale: float = 0.8
@export_range(0.1, 4.0, 0.01)
var ability_ready_pitch_scale: float = 1.25

@export_category("Shot Sounds")
@export var shot_sound_tiers: Array[ShotSoundTier] = []
@export var power_strike_shot_sound: AudioStream
@export_range(-80.0, 24.0, 0.1)
var power_strike_shot_volume_db: float = -5.0

@export_category("Ball Contact Feel")
@export_range(0.08, 0.5, 0.01)
var ball_contact_flash_seconds: float = 0.16
@export_range(0.0, 0.5, 0.01)
var ball_contact_squash_amount: float = 0.18
@export_range(-80.0, 12.0, 0.5)
var impact_body_minimum_volume_db: float = -24.0
@export_range(-80.0, 12.0, 0.5)
var impact_body_maximum_volume_db: float = -11.0

@export_category("CPU Own-Goal Prevention")
@export var cpu_own_goal_prevention_enabled: bool = true
@export var cpu_own_goal_hard_zone_distance: float = 3000.0
@export var cpu_own_goal_prediction_seconds: float = 1.8
@export var cpu_own_goal_mouth_padding: float = 190.0
@export var cpu_own_goal_minimum_toward_speed: float = 120.0
@export var cpu_own_goal_safe_forward_speed: float = 1450.0
@export var cpu_own_goal_safe_lateral_weight: float = 0.42

@export_category("Pass Request")
@export var pass_request_duration: float = 1.4
@export var pass_request_cooldown: float = 0.75
@export var pass_request_sound: AudioStream
@export_range(-80.0, 24.0, 0.1)
var pass_request_volume_db: float = -18.0
@export_range(0.1, 4.0, 0.01)
var pass_request_pitch_scale: float = 1.0

@onready var kick_area: Area2D = $KickArea
@onready var body_collision_shape: CollisionShape2D = $CollisionShape2D
@onready var name_label: Label = $NameLabel
@onready var quick_chat_bubble: PanelContainer = $QuickChatBubble
@onready var quick_chat_label: Label = $QuickChatBubble/Label
@onready var shot_charge_bar: ProgressBar = $ShotChargeBar
@onready var shot_charge_readout: Label = $ShotChargeReadout
@onready var local_player_marker: Label = $LocalPlayerMarker
@onready var kick_range_indicator: Line2D = $KickRangeIndicator
@onready var shot_direction_preview: Line2D = $ShotDirectionPreview
@onready var shot_direction_arrow: Line2D = $ShotDirectionArrow
@onready var shot_bounce_marker: Line2D = $ShotBounceMarker
@onready var movement_direction_arrow: Sprite2D = (
	$MovementDirectionArrow
)
@onready var shot_aim_guide: Line2D = $ShotAimGuide
@onready var shot_audio: AudioStreamPlayer2D = $ShotAudio
@onready var curve_shot_audio: AudioStreamPlayer2D = $CurveShotAudio
@onready var dead_zone_pass_audio: AudioStreamPlayer2D = $DeadZonePassAudio
@onready var reflex_block_audio: AudioStreamPlayer2D = $ReflexBlockAudio
@onready var impact_body_audio: AudioStreamPlayer2D = (
	get_node_or_null("ImpactBodyAudio") as AudioStreamPlayer2D
)
@onready var ability_audio: AudioStreamPlayer = $AbilityAudio
@onready var pass_request_marker: Label = $PassRequestMarker
@onready var pass_request_audio: AudioStreamPlayer = $PassRequestAudio
@onready var ability_particles: FootballAbilityGpuParticles = $AbilityParticles
@onready var ability_pulse_particles: FootballAbilityGpuParticles = (
	$AbilityPulseParticles
)
@onready var goalkeeper_reach_area: Area2D = (
	$GoalkeeperReachArea
)
@onready var player_circle: Sprite2D = $Testplaxayer2
@onready var cosmetic_static_viewport: SubViewport = $CosmeticStaticViewport
@onready var cosmetic_static_layer: Node2D = $CosmeticStaticViewport/CosmeticStaticLayer
@onready var cosmetic_static_sprite: Sprite2D = $CosmeticStaticSprite
@onready var cosmetic_animated_layer: Node2D = $CosmeticAnimatedLayer
@onready var player_glow_fx: Node2D = $PlayerGlowFX
@onready var ability_portrait: TextureRect = $AbilityPortrait
@onready var meta_vision_trajectory: Line2D = (
	$MetaVisionTrajectory
)
@onready var meta_vision_landing_marker: Line2D = (
	$MetaVisionLandingMarker
)
@onready var meta_vision_intercept_path: Line2D = (
	$MetaVisionInterceptPath
)
@onready var meta_vision_own_intercept_marker: Line2D = (
	$MetaVisionOwnInterceptMarker
)
@onready var meta_vision_enemy_intercept_marker: Line2D = (
	$MetaVisionEnemyInterceptMarker
)


@export var team: StringName = &"":
	set(value):
		team = value

		if is_node_ready():
			_update_team_visual()
			_update_name_label()
			_refresh_soft_glow()
			_refresh_echo_player_collision_mask()


@export var team_slot: int = -1
@export var controls_enabled: bool = false

# Input that the server uses to move this player.
var server_direction: Vector2 = Vector2.ZERO
var _ball_free_linear_velocity: Vector2 = Vector2.ZERO

# Network motion is replicated instead of writing RigidBody2D.position directly
# on clients. Direct transform replication at 30 Hz looked choppy, while sending
# transforms every render frame can become very expensive at 240 FPS in 4v4.
# Clients render toward these authoritative snapshots every frame.
var network_position: Vector2 = Vector2.ZERO
var network_linear_velocity: Vector2 = Vector2.ZERO
var _network_target_position: Vector2 = Vector2.ZERO
var _network_target_velocity: Vector2 = Vector2.ZERO
var _network_last_snapshot_position: Vector2 = Vector2.INF
var _network_last_snapshot_velocity: Vector2 = Vector2.INF
var _network_snapshot_age: float = 0.0
var _network_smoothed_snapshot_interval: float = 1.0 / 60.0
var _network_motion_initialized: bool = false
var _network_snapshot_signal_connected: bool = false
var _network_last_safe_render_position: Vector2 = Vector2.ZERO
var _physics_sanity_last_transform: Transform2D = Transform2D.IDENTITY
var _physics_sanity_last_velocity: Vector2 = Vector2.ZERO
var _physics_sanity_last_angular_velocity: float = 0.0
var _physics_sanity_initialized: bool = false

# Client input transport. Starts/stops and large turns are immediate. Small stick
# changes are coalesced and a heartbeat repairs the state if an unreliable packet
# is lost.
var _client_input_send_elapsed: float = 0.0
var _client_last_sent_direction: Vector2 = Vector2.ZERO
var _client_has_sent_direction: bool = false
var _client_input_sequence: int = 0
var _server_last_input_sequence: int = -1

# Charge timing is measured by the server. A client can request
# press/release only for its own player and cannot submit force.
var server_is_charging: bool = false
var server_charge_started_at: float = 0.0
var server_last_kick_charge_seconds: float = 0.0
var server_last_kick_was_soft_pass: bool = false
var server_last_kick_time: float = -INF
var next_shot_allowed_at: float = 0.0
var next_soft_pass_allowed_at: float = 0.0
var _server_reverse_drag_last_strong_direction: Vector2 = Vector2.ZERO
var _server_reverse_drag_last_strong_at: float = -INF
var _server_reverse_drag_armed_until: float = -INF
var _server_reverse_drag_forward_direction: Vector2 = Vector2.ZERO
var _server_reverse_drag_reverse_direction: Vector2 = Vector2.ZERO
var _server_reverse_drag_snap_quality: float = 0.0
var _server_reverse_drag_current_input: Vector2 = Vector2.ZERO
var _server_reverse_drag_chain_until: float = -INF
var _server_reverse_drag_chain_direction: Vector2 = Vector2.ZERO
var _server_reverse_drag_last_touch_at: float = -INF
var _server_reverse_drag_chain_touch_queued: bool = false
var server_pass_request_ends_at: float = 0.0
var _next_pass_request_allowed_at: float = 0.0
var _local_pass_request_remaining: float = 0.0
var server_human_first_touch_mode: StringName = HUMAN_FIRST_TOUCH_NONE
var server_human_first_touch_direction: Vector2 = Vector2.ZERO
var server_human_first_touch_ends_at: float = 0.0
var server_human_first_touch_dummy_until: float = 0.0
var _local_human_first_touch_mode: StringName = HUMAN_FIRST_TOUCH_NONE
var _local_human_first_touch_ends_at: float = 0.0

# Local-only value intended for a future charge meter.
var local_charge_seconds: float = 0.0
var local_is_charging: bool = false
var replicated_charge_active: bool = false
var replicated_charge_seconds: float = 0.0
var replicated_charge_duration: float = 1.0

# Ability timing is authoritative on the server. Clients receive
# durations only for local HUD animation and shared particles.
var server_ability_active: bool = false
var server_active_ability_id: int = ABILITY_NONE
var server_permanent_overdrive_enabled: bool = false
var server_permanent_power_strike_enabled: bool = false
var server_permanent_elastic_step_enabled: bool = false
var server_permanent_iron_anchor_enabled: bool = false
var server_haaland_predator_until: float = 0.0
var server_haaland_predator_charge_armed: bool = false
var server_neuer_dead_zone_cooldown_ends_at: float = 0.0
var server_ability_ends_at: float = 0.0
var server_ability_cooldown_ends_at: float = 0.0
var server_pending_cooldown: float = 0.0
var server_burst_charges: int = 2
var server_next_burst_allowed_at: float = 0.0
var server_burst_ball_speed_limits: Dictionary = {}
var server_elastic_step_charges: int = 2
var server_next_elastic_step_allowed_at: float = 0.0
var server_goalkeeper_reach_charges: int = 1
var server_boogie_woogie_charges: int = 1
var server_ability_strength_scale: float = 1.0
var server_last_used_ability_id: int = ABILITY_NONE
var server_last_ability_used_at: float = 0.0
var server_copycat_stored_ability_id: int = ABILITY_NONE
var server_copycat_stored_expires_at: float = 0.0
var server_reflex_blocked_ball_id: int = 0
var server_reflex_facing: Vector2 = Vector2.ZERO
var server_direct_finish_volley_requested: bool = false
var server_direct_finish_aim_direction: Vector2 = Vector2.ZERO
var server_direct_finish_candidate_id: int = 0
var server_direct_finish_candidate_entered_at: float = 0.0
var server_blind_spot_target_position: Vector2 = Vector2.ZERO
var server_blind_spot_target_player: FootballPlayer
var server_echo_active: bool = false
var server_echo_position: Vector2 = Vector2.ZERO
var server_echo_ends_at: float = 0.0
var server_echo_generation: int = 0
var server_echo_blocks_remaining: int = 1
var server_echo_blocked_ball_ids: Dictionary = {}
var server_snapback_ball_id: int = 0
var server_snapback_touch_serial: int = 0
var server_snapback_kick_at: float = 0.0
var server_phantom_heel_ball_id: int = 0
var server_phantom_heel_drag_direction: Vector2 = Vector2.ZERO
var server_phantom_heel_followup_ready_at: float = 0.0
var server_breakaway_chase_until: float = 0.0
var server_breakaway_chase_direction: Vector2 = Vector2.ZERO
var server_breakaway_chase_strength: float = 1.0
var server_nutmeg_chase_until: float = 0.0
var server_nutmeg_chase_direction: Vector2 = Vector2.ZERO
var server_next_kick_is_pass: bool = false
var freeplay_cooldowns_disabled: bool = false
var match_cooldowns_disabled: bool = false
var freeplay_copycat_source_ability: int = ABILITY_POWER_STRIKE

var local_ability_active: bool = false
var local_active_ability_id: int = ABILITY_NONE
var local_direct_finish_volley_requested: bool = false
var _local_direct_finish_tap_pending: bool = false
var _local_direct_finish_first_tap_at: float = 0.0
var _local_direct_finish_quick_release_pending: bool = false
var _local_direct_finish_quick_release_seconds: float = 0.0
var local_ability_effect_remaining: float = 0.0
var local_copycat_stored_ability_id: int = ABILITY_NONE
var local_copycat_memory_remaining: float = 0.0
var _decoy_run_visual_generation: int = 0
var local_ability_cooldown_remaining: float = 0.0
var local_ability_cooldown_total: float = 0.0
var local_ability_timers_paused: bool = false
var local_burst_charges: int = 2
var local_elastic_step_charges: int = 2
var local_burst_max_charges: int = 2
var local_elastic_step_max_charges: int = 4
var _normal_collision_mask: int = 0
var _goalkeeper_blocked_balls: Dictionary = {}
var _quick_chat_generation: int = 0
var server_ability_timers_paused: bool = false
var server_paused_effect_remaining: float = 0.0
var server_paused_cooldown_remaining: float = 0.0
var _charge_fill_style: StyleBoxFlat
var _ball_was_kickable: bool = false
var _kick_result_flash_remaining: float = 0.0
var _kick_result_success: bool = false
var _ball_contact_flash_remaining: float = 0.0
var _ball_contact_flash_strength: float = 0.0
var _ball_contact_flash_color: Color = Color.WHITE
var _portrait_impact_tween: Tween
var _mirage_visibility_tween: Tween
var _mirage_visibility_restore_deadline_usec: int = 0
var _action_pulse_visual_scale: float = 1.0
var _action_pulse_visual_tween: Tween
var _action_feedback_type: int = ACTION_PULSE_SHOT
var _action_feedback_intensity: float = 0.0
var _action_feedback_remaining: float = 0.0
var _action_feedback_total: float = 0.0
var _ability_activation_cue_id: int = ABILITY_NONE
var _ability_activation_cue_remaining: float = 0.0
var _ability_activation_cue_total: float = 0.0
var _dictator_name_shine_time: float = 0.0
var _player_circle_base_scale: Vector2 = Vector2.ONE
var _ability_portrait_base_scale: Vector2 = Vector2.ONE
var _movement_direction_arrow_base_scale: Vector2 = Vector2.ONE
var _body_collision_base_scale: Vector2 = Vector2.ONE
var _large_team_size_multiplier: float = 1.0
var _match_team_size: int = 0
var _cpu_time_skip_pass_receiver_peer_id: int = 0
var _cpu_time_skip_pass_target: Vector2 = Vector2.ZERO
var _local_echo_node: DefenseEcho
var _local_echo_generation: int = 0
var _default_ability_portrait_material: Material


func _configure_motion_interpolation_mode() -> void:
	# Authoritative/server players are real physics bodies, so Godot's 2D
	# physics interpolation is useful between simulation ticks. Remote/client
	# replicas are different: _update_client_network_motion() already moves them
	# every rendered frame. Leaving built-in physics interpolation enabled there
	# applies a second interpolation layer to the same transform and can make the
	# whole badge + name look soft while moving.
	if multiplayer.is_server():
		physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON
	else:
		physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		reset_physics_interpolation()


func _ready() -> void:
	_configure_motion_interpolation_mode()
	_ball_free_linear_velocity = linear_velocity
	_network_last_safe_render_position = position
	_remember_valid_physics_state(
		global_transform,
		linear_velocity,
		angular_velocity
	)
	_normal_collision_mask = collision_mask
	_refresh_echo_player_collision_mask()
	_prepare_default_ability_ready_sound()
	if impact_body_audio != null:
		impact_body_audio.stream = BALL_IMPACT_BODY_SOUND
	server_burst_charges = _get_effective_burst_max_charges()
	local_burst_max_charges = _get_effective_burst_max_charges()
	local_burst_charges = local_burst_max_charges
	server_elastic_step_charges = _get_effective_elastic_step_max_charges()
	server_mirage_step_charges = _get_effective_mirage_step_max_charges()
	server_breakaway_charges = _get_effective_breakaway_max_charges()
	server_goalkeeper_reach_charges = _get_effective_goalkeeper_reach_max_charges()
	server_boogie_woogie_charges = _get_effective_boogie_woogie_max_charges()
	local_elastic_step_max_charges = _get_effective_elastic_step_max_charges()
	local_elastic_step_charges = local_elastic_step_max_charges
	_update_name_label()
	quick_chat_bubble.hide()
	shot_charge_bar.hide()
	shot_charge_bar.value = 0.0
	shot_charge_readout.hide()
	shot_direction_preview.hide()
	shot_direction_arrow.hide()
	shot_bounce_marker.hide()
	if movement_direction_arrow != null:
		movement_direction_arrow.hide()
	shot_aim_guide.hide()
	_prepare_shot_bounce_marker()
	_prepare_shot_aim_guide()
	_charge_fill_style = StyleBoxFlat.new()
	_charge_fill_style.bg_color = charge_low_color
	_charge_fill_style.corner_radius_top_left = 7
	_charge_fill_style.corner_radius_top_right = 7
	_charge_fill_style.corner_radius_bottom_left = 7
	_charge_fill_style.corner_radius_bottom_right = 7
	shot_charge_bar.add_theme_stylebox_override(
		"fill",
		_charge_fill_style
	)
	# The local player is identified by their white name instead of a
	# separate symbol above the character.
	local_player_marker.hide()
	pass_request_marker.hide()
	pass_request_audio.stream = (
		pass_request_sound
		if pass_request_sound != null
		else _create_default_pass_request_sound()
	)
	pass_request_audio.volume_db = pass_request_volume_db
	pass_request_audio.pitch_scale = pass_request_pitch_scale
	_prepare_kick_range_indicator()
	if player_circle != null:
		_player_circle_base_scale = player_circle.scale
	if cosmetic_static_viewport != null and cosmetic_static_sprite != null:
		cosmetic_static_sprite.texture = cosmetic_static_viewport.get_texture()
	if ability_portrait != null:
		_ability_portrait_base_scale = ability_portrait.scale
		_default_ability_portrait_material = ability_portrait.material
	if movement_direction_arrow != null:
		_movement_direction_arrow_base_scale = movement_direction_arrow.scale
	if body_collision_shape != null:
		_body_collision_base_scale = body_collision_shape.scale
	_apply_large_team_size_multiplier()
	_apply_action_pulse_visual_scale(1.0)
	ability_particles.emitting = false
	ability_pulse_particles.emitting = false
	queue_redraw()
	meta_vision_trajectory.hide()
	meta_vision_landing_marker.hide()
	meta_vision_intercept_path.hide()
	meta_vision_own_intercept_marker.hide()
	meta_vision_enemy_intercept_marker.hide()
	var reach_scale := maxf(
		0.01,
		goalkeeper_reach_radius / 100.0
	)
	goalkeeper_reach_area.scale = Vector2.ONE * reach_scale
	_update_team_visual()
	_update_ability_portrait(false)
	_apply_cosmetic_loadout()
	var cosmetic_inventory := get_node_or_null(
		"/root/CosmeticInventory"
	) as FootballCosmeticInventory
	if (
		cosmetic_inventory != null
		and not cosmetic_inventory.visual_preferences_changed.is_connected(
			refresh_field_ability_icon_visibility
		)
	):
		cosmetic_inventory.visual_preferences_changed.connect(
			refresh_field_ability_icon_visibility
		)

	# Only the server simulates RigidBody physics. Clients never invent a
	# second gameplay timeline: they render host-authoritative motion snapshots
	# and only smooth the visual correction between packets.
	if multiplayer.is_server():
		network_position = position
		network_linear_velocity = linear_velocity
	else:
		freeze = true
		_network_target_position = position
		_network_target_velocity = linear_velocity
		_network_last_snapshot_position = network_position
		_network_last_snapshot_velocity = network_linear_velocity
		_network_motion_initialized = true
		_connect_network_motion_snapshot_signal()


func _process(delta: float) -> void:
	if not multiplayer.is_server():
		_update_client_network_motion(delta)
	_repair_stale_player_render_visibility()
	_update_replicated_charge(delta)
	_update_meta_vision_visual()
	_update_pass_request_visual(delta)
	_update_ball_contact_visual(delta)
	_update_spectator_shot_aim_guide()
	_update_movement_direction_arrow()
	_update_readability_feedback(delta)
	_update_special_boss_name_shine(delta)
	if not _is_local_player():
		return
	_update_local_kick_feedback(delta)
	_update_local_shot_aim_guide()
	_update_local_shot_preview()

	if local_ability_timers_paused:
		return

	if local_ability_effect_remaining > 0.0:
		local_ability_effect_remaining = maxf(
			0.0,
			local_ability_effect_remaining - delta
		)

	if local_copycat_memory_remaining > 0.0:
		local_copycat_memory_remaining = maxf(
			0.0,
			local_copycat_memory_remaining - delta
		)
		if local_copycat_memory_remaining <= 0.0:
			local_copycat_stored_ability_id = ABILITY_NONE

	if local_ability_cooldown_remaining <= 0.0:
		return

	local_ability_cooldown_remaining = maxf(
		0.0,
		local_ability_cooldown_remaining - delta
	)
	if local_ability_cooldown_remaining <= 0.0:
		_play_local_ability_sound(
			ability_ready_sound,
			ability_ready_pitch_scale,
			ability_ready_volume_db
		)


func show_quick_chat(message: String, duration: float = 2.4) -> void:
	_quick_chat_generation += 1
	var generation := _quick_chat_generation
	if pass_request_audio != null and pass_request_audio.stream != null:
		pass_request_audio.stop()
		pass_request_audio.play()
	quick_chat_label.text = message.strip_edges()
	quick_chat_bubble.modulate = Color.WHITE
	quick_chat_bubble.scale = Vector2(0.82, 0.82)
	quick_chat_bubble.pivot_offset = quick_chat_bubble.size * 0.5
	quick_chat_bubble.show()
	var tween := create_tween().set_parallel(true)
	tween.tween_property(
		quick_chat_bubble,
		"scale",
		Vector2.ONE,
		0.12
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(
		quick_chat_bubble,
		"modulate:a",
		1.0,
		0.08
	)
	await get_tree().create_timer(maxf(0.5, duration)).timeout
	if generation != _quick_chat_generation:
		return
	var hide_tween := create_tween()
	hide_tween.tween_property(
		quick_chat_bubble,
		"modulate:a",
		0.0,
		0.16
	)
	await hide_tween.finished
	if generation == _quick_chat_generation:
		quick_chat_bubble.hide()


func _physics_process(delta: float) -> void:
	if multiplayer.is_server():
		_update_server_ability()
		_server_update_human_first_touch()
		_server_update_queued_reverse_drag_touch()
		if _server_ability_is_active(ABILITY_BURST_DRIBBLE):
			_server_limit_burst_ball_velocity()
		if _server_ability_is_active(
			ABILITY_GOALKEEPER_REACH
		):
			_server_update_goalkeeper_reach()
		elif _server_ability_is_active(ABILITY_REFLEX_BLOCK):
			_server_update_reflex_block()
		elif _server_ability_is_active(ABILITY_DIRECT_FINISH):
			_server_update_direct_finish()
		_server_update_echo()

	if _is_local_player() and controls_enabled:
		_update_pending_direct_finish_tap()
		var direction := Input.get_vector(
			"move_left",
			"move_right",
			"move_up",
			"move_down"
		)
		_update_local_human_first_touch(direction)

		if multiplayer.is_server():
			_server_track_reverse_drag_input(direction)
			server_direction = direction
		else:
			_update_client_movement_input_transport(delta, direction)

		if (
			Input.is_action_just_pressed("shoot")
			and not _mouse_shoot_is_over_ui()
		):
			if not _handle_direct_finish_shoot_pressed():
				_begin_local_charge()

		if local_is_charging:
			var charge_seconds := _current_maximum_charge_seconds()
			local_charge_seconds = minf(
				charge_seconds,
				local_charge_seconds + delta
			)
			_update_charge_bar()

		if Input.is_action_just_released("shoot"):
			_release_local_charge()

		if Input.is_action_just_pressed("ability"):
			_request_local_ability()

		if Input.is_action_just_pressed("request_pass"):
			_request_local_pass()

		if Input.is_action_just_pressed("first_touch_trap"):
			_try_arm_local_human_first_touch(
				HUMAN_FIRST_TOUCH_TRAP,
				direction
			)

		if Input.is_action_just_pressed("first_touch_dummy"):
			_try_arm_local_human_first_touch(
				HUMAN_FIRST_TOUCH_DUMMY,
				direction
			)

		if Input.is_action_just_pressed("soft_pass"):
			_request_local_soft_pass()
	else:
		_cancel_pending_direct_finish_tap()
		if local_is_charging:
			_cancel_local_charge()


func _handle_direct_finish_shoot_pressed() -> bool:
	if not _can_locally_choose_direct_finish():
		_cancel_pending_direct_finish_tap()
		return false
	var now := Time.get_ticks_msec() / 1000.0
	if (
		_local_direct_finish_tap_pending
		and now - _local_direct_finish_first_tap_at
		<= maxf(0.12, direct_finish_double_tap_seconds)
	):
		_cancel_pending_direct_finish_tap()
		_request_local_direct_finish_volley()
		return true
	# Track the first press as a possible double-tap without consuming it.
	# Charging still starts immediately; a quick release is committed as a
	# normal shot only if no second press arrives during the short window.
	_local_direct_finish_tap_pending = true
	_local_direct_finish_first_tap_at = now
	return false


func _update_pending_direct_finish_tap() -> void:
	if not _local_direct_finish_tap_pending:
		return
	var elapsed := (
		Time.get_ticks_msec() / 1000.0
		- _local_direct_finish_first_tap_at
	)
	if elapsed < maxf(0.12, direct_finish_double_tap_seconds):
		return
	_commit_pending_direct_finish_quick_shot()
	_cancel_pending_direct_finish_tap()


func _cancel_pending_direct_finish_tap() -> void:
	_local_direct_finish_tap_pending = false
	_local_direct_finish_first_tap_at = 0.0
	_local_direct_finish_quick_release_pending = false
	_local_direct_finish_quick_release_seconds = 0.0


func _can_locally_choose_direct_finish() -> bool:
	if selected_ability != ABILITY_DIRECT_FINISH:
		return false
	if local_ability_timers_paused:
		return false
	if (
		local_ability_active
		and local_active_ability_id == ABILITY_DIRECT_FINISH
	):
		return true
	return local_ability_cooldown_remaining <= 0.0

func _is_local_player() -> bool:
	return multiplayer.get_unique_id() == owner_peer_id


func _mouse_shoot_is_over_ui() -> bool:
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		return false
	var hovered_control := get_viewport().gui_get_hovered_control()
	return (
		hovered_control != null
		and hovered_control.mouse_filter
		!= Control.MOUSE_FILTER_IGNORE
	)



func _update_local_human_first_touch(_direction: Vector2) -> void:
	# Human first touch is now fully opt-in. Normal movement, Shoot and Soft Pass
	# never arm an automatic reception. Only the dedicated Trap / Dummy binds do.
	if not human_first_touch_enabled or cpu_controlled or not controls_enabled:
		_local_human_first_touch_mode = HUMAN_FIRST_TOUCH_NONE
		_local_human_first_touch_ends_at = 0.0
		return
	var now: float = Time.get_ticks_msec() / 1000.0
	if now >= _local_human_first_touch_ends_at:
		_local_human_first_touch_mode = HUMAN_FIRST_TOUCH_NONE
		_local_human_first_touch_ends_at = 0.0


func _try_arm_local_human_first_touch(
	mode: StringName,
	direction: Vector2
) -> bool:
	if (
		not human_first_touch_enabled
		or cpu_controlled
		or not controls_enabled
		or local_is_charging
	):
		return false
	if mode not in [HUMAN_FIRST_TOUCH_TRAP, HUMAN_FIRST_TOUCH_DUMMY]:
		return false
	if (
		selected_ability == ABILITY_DIRECT_FINISH
		and mode == HUMAN_FIRST_TOUCH_TRAP
	):
		# Trap or Volley already owns its reception mechanic. Do not stack the
		# generic manual trap on top of that ability.
		return false
	var incoming_ball: FootballBall = _find_incoming_ball(
		human_first_touch_anticipation_distance
	)
	if incoming_ball == null:
		return false
	var ball_distance: float = global_position.distance_to(
		incoming_ball.global_position
	)
	if ball_distance <= kick_feedback_detection_distance * 0.92:
		return false
	var touch_direction: Vector2 = direction.normalized()
	if touch_direction.is_zero_approx():
		touch_direction = server_direction.normalized()
	if touch_direction.is_zero_approx():
		touch_direction = incoming_ball.linear_velocity.normalized()
	if touch_direction.is_zero_approx():
		touch_direction = Vector2.RIGHT
	_local_human_first_touch_mode = mode
	_local_human_first_touch_ends_at = (
		Time.get_ticks_msec() / 1000.0
		+ maxf(0.25, human_first_touch_plan_seconds)
	)
	if multiplayer.is_server():
		_server_arm_human_first_touch(
			owner_peer_id,
			mode,
			touch_direction
		)
	else:
		_request_human_first_touch.rpc_id(
			SERVER_PEER_ID,
			mode,
			touch_direction
		)
	return true


@rpc("any_peer", "call_remote", "reliable")
func _request_human_first_touch(
	mode: StringName,
	direction: Vector2
) -> void:
	if (
		not multiplayer.is_server()
		or multiplayer.get_remote_sender_id() != owner_peer_id
	):
		return
	_server_arm_human_first_touch(
		owner_peer_id,
		mode,
		direction
	)


func _server_arm_human_first_touch(
	requester_peer_id: int,
	mode: StringName,
	direction: Vector2
) -> bool:
	if (
		not multiplayer.is_server()
		or requester_peer_id != owner_peer_id
		or cpu_controlled
		or not controls_enabled
		or not human_first_touch_enabled
	):
		return false
	if mode not in [HUMAN_FIRST_TOUCH_TRAP, HUMAN_FIRST_TOUCH_DUMMY]:
		return false
	if (
		selected_ability == ABILITY_DIRECT_FINISH
		and mode == HUMAN_FIRST_TOUCH_TRAP
	):
		return false
	var touch_direction: Vector2 = direction.limit_length(1.0)
	if touch_direction.is_zero_approx():
		touch_direction = server_direction.normalized()
	server_human_first_touch_mode = mode
	server_human_first_touch_direction = touch_direction
	server_human_first_touch_ends_at = (
		_server_time_seconds()
		+ maxf(0.25, human_first_touch_plan_seconds)
	)
	return true


func _server_update_human_first_touch() -> void:
	if not multiplayer.is_server():
		return
	var now: float = _server_time_seconds()
	if server_human_first_touch_dummy_until > 0.0:
		if now < server_human_first_touch_dummy_until:
			return
		server_human_first_touch_dummy_until = 0.0
		_restore_ball_collision_after_human_dummy()
	if (
		server_human_first_touch_mode == HUMAN_FIRST_TOUCH_NONE
		or cpu_controlled
		or not controls_enabled
		or not human_first_touch_enabled
	):
		return
	if now >= server_human_first_touch_ends_at:
		_server_clear_human_first_touch()
		return
	var incoming_ball: FootballBall = _find_incoming_ball(
		human_first_touch_anticipation_distance
	)
	if incoming_ball == null:
		return
	var distance: float = global_position.distance_to(
		incoming_ball.global_position
	)
	if server_human_first_touch_mode == HUMAN_FIRST_TOUCH_DUMMY:
		if distance <= maxf(
			kick_feedback_detection_distance,
			human_first_touch_dummy_distance
		):
			_set_ball_body_collision_enabled(false)
			server_human_first_touch_dummy_until = (
				now + maxf(0.08, human_first_touch_dummy_seconds)
			)
			server_human_first_touch_mode = HUMAN_FIRST_TOUCH_NONE
			server_human_first_touch_ends_at = 0.0
		return
	if distance > kick_feedback_detection_distance + 30.0:
		return
	_server_execute_human_first_touch(incoming_ball)


func _server_execute_human_first_touch(
	ball_target: FootballBall
) -> bool:
	if (
		ball_target == null
		or server_human_first_touch_mode != HUMAN_FIRST_TOUCH_TRAP
	):
		return false
	var direction: Vector2 = server_human_first_touch_direction.normalized()
	if direction.is_zero_approx():
		direction = server_direction.normalized()
	if direction.is_zero_approx():
		direction = ball_target.linear_velocity.normalized()
	if direction.is_zero_approx():
		direction = Vector2.RIGHT
	var incoming_velocity: Vector2 = ball_target.linear_velocity
	var desired_velocity: Vector2 = direction * maxf(
		0.0,
		human_first_touch_trap_speed
	)
	# Trap deliberately absorbs almost all incoming pace. It only happens after
	# the player presses the dedicated Trap bind; ordinary receptions are untouched.
	desired_velocity = incoming_velocity.lerp(desired_velocity, 0.94)
	var mass_value: float = maxf(0.001, ball_target.mass)
	var impulse: Vector2 = (desired_velocity - incoming_velocity) * mass_value
	if impulse.length() <= 0.01:
		_server_clear_human_first_touch()
		return false
	ball_target.register_touch(
		owner_peer_id,
		display_name,
		team,
		incoming_velocity,
		&"human_first_touch_trap",
		desired_velocity
	)
	ball_target.apply_central_impulse(impulse)
	play_ball_contact_visual(impulse.length(), direction)
	_server_clear_human_first_touch()
	return true


func _server_clear_human_first_touch() -> void:
	server_human_first_touch_mode = HUMAN_FIRST_TOUCH_NONE
	server_human_first_touch_direction = Vector2.ZERO
	server_human_first_touch_ends_at = 0.0


func _restore_ball_collision_after_human_dummy() -> void:
	if (
		_server_ability_is_active(ABILITY_GOALKEEPER_REACH)
		or _server_ability_is_active(ABILITY_ELASTIC_STEP)
	):
		return
	_set_ball_body_collision_enabled(true)


func _find_incoming_ball(maximum_distance: float) -> FootballBall:
	var best_ball: FootballBall
	var best_time: float = INF
	for node in get_tree().get_nodes_in_group("football_balls"):
		var candidate: FootballBall = node as FootballBall
		if candidate == null:
			continue
		var offset: Vector2 = global_position - candidate.global_position
		var distance: float = offset.length()
		if distance <= 1.0 or distance > maxf(1.0, maximum_distance):
			continue
		var speed: float = candidate.linear_velocity.length()
		if speed < maxf(1.0, human_first_touch_minimum_incoming_speed):
			continue
		var travel_direction: Vector2 = candidate.linear_velocity / speed
		var toward_player: float = travel_direction.dot(offset / distance)
		if toward_player < 0.72:
			continue
		var lateral_miss: float = absf(offset.cross(travel_direction))
		if lateral_miss > kick_feedback_detection_distance + 165.0:
			continue
		var closing_speed: float = maxf(1.0, speed * toward_player)
		var arrival_time: float = distance / closing_speed
		if arrival_time > maxf(0.35, human_first_touch_plan_seconds + 0.45):
			continue
		if arrival_time < best_time:
			best_time = arrival_time
			best_ball = candidate
	return best_ball


func _update_team_visual() -> void:
	if player_circle == null:
		return

	match team:
		&"red":
			player_circle.modulate = Color(1.0, 0.45, 0.45)
		&"blue":
			player_circle.modulate = Color(0.45, 0.65, 1.0)
		_:
			player_circle.modulate = Color.WHITE
	_invalidate_player_cosmetic_cache(true)
	queue_redraw()


func get_cosmetic_item_id(slot: StringName) -> String:
	if (
		slot == FootballCosmeticInventory.SLOT_PLAYER_SKIN
		and bool(cosmetic_loadout.get("team_player_skins_enabled", false))
		and team in [&"blue", &"red"]
	):
		return str(cosmetic_loadout.get(
			"player_skin_%s" % str(team),
			cosmetic_loadout.get("player_skin", "player_skin.classic")
		))
	if team in [&"blue", &"red"]:
		var team_key: String = "%s_%s" % [str(slot), str(team)]
		if cosmetic_loadout.has(team_key):
			return str(cosmetic_loadout.get(team_key, cosmetic_loadout.get(str(slot), "")))
	return str(cosmetic_loadout.get(str(slot), ""))


func get_player_skin_color_index() -> int:
	var fallback_index: int = int(
		cosmetic_loadout.get("player_skin_color_index", -1)
	)
	if team in [&"blue", &"red"]:
		return FootballCosmeticInventory.sanitize_player_skin_color_index(
			int(cosmetic_loadout.get(
				"player_skin_color_%s" % str(team),
				fallback_index
			))
		)
	return FootballCosmeticInventory.sanitize_player_skin_color_index(
		fallback_index
	)


func get_quick_chat_item_ids() -> Array[String]:
	var result: Array[String] = []
	var stored: Array = cosmetic_loadout.get("quick_chat", []) as Array
	for item_id_variant: Variant in stored:
		result.append(str(item_id_variant))
	return result


func _apply_cosmetic_loadout() -> void:
	# Cosmetic IDs alter visuals only. Team colors, collision geometry, ability
	# portraits, and every gameplay value remain unchanged.
	_apply_ability_particle_cosmetic()
	_invalidate_player_cosmetic_cache(true)
	_refresh_soft_glow()
	queue_redraw()


func _apply_ability_particle_cosmetic() -> void:
	if ability_particles == null or ability_pulse_particles == null:
		return
	var cosmetic_id: String = get_cosmetic_item_id(
		FootballCosmeticInventory.SLOT_ABILITY_PARTICLE
	)
	var cosmetic_item: Dictionary = FootballCosmeticInventory.CATALOG.get(
		cosmetic_id,
		FootballCosmeticInventory.CATALOG["ability_particle.classic"]
	) as Dictionary
	var pattern: String = str(cosmetic_item.get("pattern", "classic"))
	var texture: Texture2D = ABILITY_PARTICLE_TEXTURES.get(
		pattern,
		ABILITY_PARTICLE_TEXTURES["classic"]
	) as Texture2D
	ability_particles.texture = texture
	ability_pulse_particles.texture = texture
	# Keep ability-specific colors and semantic motion. These profiles only
	# alter the visible particle silhouette, density, and arrangement.
	match pattern:
		"streaks":
			ability_particles.amount += 12
			ability_particles.spread *= 0.58
			ability_particles.scale_amount_min *= 0.72
			ability_particles.scale_amount_max *= 0.86
		"stars":
			ability_particles.amount = maxi(28, ability_particles.amount - 12)
			ability_particles.scale_amount_min *= 0.82
			ability_particles.scale_amount_max *= 1.12
			ability_pulse_particles.scale_amount_max *= 1.18
		"orbits":
			ability_particles.amount = maxi(24, ability_particles.amount - 18)
			ability_particles.lifetime *= 1.28
			ability_particles.initial_velocity_min *= 0.55
			ability_particles.initial_velocity_max *= 0.68
			ability_particles.scale_amount_min *= 0.78
			ability_particles.scale_amount_max *= 0.92
		"shards":
			ability_particles.amount += 18
			ability_particles.spread = minf(180.0, ability_particles.spread * 1.18)
			ability_particles.scale_amount_min *= 0.58
			ability_particles.scale_amount_max *= 0.78
			ability_pulse_particles.amount += 8
		"wisps":
			ability_particles.amount = maxi(22, ability_particles.amount - 20)
			ability_particles.lifetime *= 1.42
			ability_particles.initial_velocity_min *= 0.44
			ability_particles.initial_velocity_max *= 0.58
			ability_particles.scale_amount_min *= 1.08
			ability_particles.scale_amount_max *= 1.42
			ability_pulse_particles.lifetime *= 1.30
		"bubbles":
			ability_particles.amount = maxi(30, ability_particles.amount - 10)
			ability_particles.lifetime *= 1.38
			ability_particles.initial_velocity_min *= 0.48
			ability_particles.initial_velocity_max *= 0.62
			ability_particles.scale_amount_min *= 0.84
			ability_particles.scale_amount_max *= 1.24
			ability_pulse_particles.scale_amount_max *= 1.30
		"comets":
			ability_particles.amount += 10
			ability_particles.lifetime *= 0.76
			ability_particles.spread *= 0.66
			ability_particles.initial_velocity_min *= 1.18
			ability_particles.initial_velocity_max *= 1.34
			ability_particles.scale_amount_min *= 0.62
			ability_particles.scale_amount_max *= 0.82


func get_ability_fx_color() -> Color:
	return ability_particles.color if ability_particles != null else Color.WHITE


func get_ability_fx_cue_remaining() -> float:
	return _ability_activation_cue_remaining


func get_ability_fx_cue_total() -> float:
	return _ability_activation_cue_total


func get_ability_fx_presentation_scale() -> float:
	return maxf(
		0.01,
		_action_pulse_visual_scale * _large_team_size_multiplier
	)


func get_ability_fx_pattern_index() -> int:
	var cosmetic_id: String = get_cosmetic_item_id(
		FootballCosmeticInventory.SLOT_ABILITY_PARTICLE
	)
	var cosmetic_item: Dictionary = FootballCosmeticInventory.CATALOG.get(
		cosmetic_id,
		FootballCosmeticInventory.CATALOG["ability_particle.classic"]
	) as Dictionary
	match str(cosmetic_item.get("pattern", "classic")):
		"streaks":
			return 1
		"stars":
			return 2
		"orbits":
			return 3
		"shards":
			return 4
		"wisps":
			return 5
		"bubbles":
			return 6
		"comets":
			return 7
	return 0


func _draw_circle_aa(
	position: Vector2,
	radius: float,
	color: Color,
	filled: bool = true,
	width: float = -1.0,
	_antialiased: bool = true
) -> void:
	draw_circle(position, radius, color, filled, width, true)


func _screen_pixels_per_world_unit() -> float:
	if not is_inside_tree():
		return 1.0
	var screen_transform := get_global_transform_with_canvas()
	var x_scale: float = screen_transform.x.length()
	var y_scale: float = screen_transform.y.length()
	return maxf(0.001, (x_scale + y_scale) * 0.5)


func _physical_pixels_per_world_unit() -> float:
	# get_global_transform_with_canvas() stops at the authored/logical canvas.
	# Theodore Ball then scales that 1152x648 canvas to the real window. Include
	# that final presentation scale so the minimum below is expressed in actual
	# monitor pixels instead of logical pixels. This is what keeps 1080p detail
	# from collapsing while leaving 4K essentially unchanged.
	var logical_scale := _screen_pixels_per_world_unit()
	var viewport := get_viewport()
	var window := get_window()
	if viewport == null or window == null:
		return logical_scale
	var logical_size := viewport.get_visible_rect().size
	var physical_size := Vector2(window.size)
	if (
		logical_size.x <= 0.0
		or logical_size.y <= 0.0
		or physical_size.x <= 0.0
		or physical_size.y <= 0.0
	):
		return logical_scale
	var presentation_scale := minf(
		physical_size.x / logical_size.x,
		physical_size.y / logical_size.y
	)
	return maxf(0.001, logical_scale * presentation_scale)


func _screen_safe_stroke_width(
	world_width: float,
	minimum_screen_pixels: float = 1.90
) -> float:
	return maxf(
		world_width,
		minimum_screen_pixels / _physical_pixels_per_world_unit()
	)


func _draw_arc_screen_aa(
	center: Vector2,
	radius: float,
	start_angle: float,
	end_angle: float,
	point_count: int,
	color: Color,
	width: float = -1.0,
	antialiased: bool = true
) -> void:
	draw_arc(
		center, radius, start_angle, end_angle, point_count, color,
		_screen_safe_stroke_width(width), antialiased
	)


func _draw_line_screen_aa(
	from: Vector2,
	to: Vector2,
	color: Color,
	width: float = -1.0,
	antialiased: bool = true
) -> void:
	draw_line(
		from, to, color, _screen_safe_stroke_width(width), antialiased
	)


func _draw_polyline_screen_aa(
	points: PackedVector2Array,
	color: Color,
	width: float = -1.0,
	antialiased: bool = true
) -> void:
	draw_polyline(
		points, color, _screen_safe_stroke_width(width), antialiased
	)


func _draw() -> void:
	# The expensive cosmetic badge is rendered by two child CanvasItems: a
	# cached static layer and a much smaller animated layer. This root draw pass
	# is reserved for short-lived gameplay readability effects only.
	var visual_scale := maxf(
		0.01,
		_action_pulse_visual_scale * _large_team_size_multiplier
	)
	var safe_outer_radius := maxf(40.0, badge_outer_radius) * visual_scale
	if _ball_contact_flash_remaining > 0.0:
		_draw_ball_contact_flash(safe_outer_radius)
	_draw_charge_anticipation(safe_outer_radius)
	_draw_action_readability_feedback(safe_outer_radius)


func _player_cosmetic_has_animated_details() -> bool:
	var player_skin_id: String = get_cosmetic_item_id(
		FootballCosmeticInventory.SLOT_PLAYER_SKIN
	)
	var skin_item: Dictionary = FootballCosmeticInventory.CATALOG.get(
		player_skin_id,
		{}
	) as Dictionary
	return FootballPlayerSkinVisuals.has_animated_details(
		player_skin_id,
		skin_item
	)


func _invalidate_player_cosmetic_cache(redraw_static: bool = true) -> void:
	if cosmetic_static_layer != null and redraw_static:
		if cosmetic_static_layer.has_method("invalidate"):
			cosmetic_static_layer.invalidate()
		else:
			cosmetic_static_layer.queue_redraw()
	if cosmetic_animated_layer != null:
		if cosmetic_animated_layer.has_method("invalidate"):
			cosmetic_animated_layer.invalidate()
		else:
			cosmetic_animated_layer.queue_redraw()


func _draw_player_cosmetic_cache_layer(
	canvas: CanvasItem,
	animated_pass: bool
) -> void:
	var team_color: Color = _get_effective_badge_team_color()
	var frame_color := Color(0.92, 0.97, 0.97, 0.96)
	var player_skin_id: String = get_cosmetic_item_id(
		FootballCosmeticInventory.SLOT_PLAYER_SKIN
	)
	var base_skin_item: Dictionary = FootballCosmeticInventory.CATALOG.get(
		player_skin_id,
		{}
	) as Dictionary
	var skin_item: Dictionary = FootballCosmeticInventory.apply_player_skin_color(
		player_skin_id,
		base_skin_item,
		get_player_skin_color_index()
	)
	var frame_palette_id: String = get_cosmetic_item_id(
		FootballCosmeticInventory.SLOT_FRAME_PALETTE
	)
	skin_item = FootballCosmeticInventory.apply_player_skin_team_profile(
		frame_palette_id,
		skin_item,
		team
	)
	var custom_frame_palette: bool = frame_palette_id != "frame_palette.classic_touch"
	var frame_primary := team_color
	var frame_glow := team_color
	var frame_primary_html: String = str(skin_item.get("frame_primary", ""))
	if Color.html_is_valid(frame_primary_html):
		frame_primary = Color(frame_primary_html)
	var frame_glow_html: String = str(skin_item.get("team_glow", ""))
	if Color.html_is_valid(frame_glow_html):
		frame_glow = Color(frame_glow_html)
	var frame_ring_color: Color = (
		team_color.lerp(frame_primary, 0.68) if custom_frame_palette else team_color
	)
	var skin_secondary_html: String = str(skin_item.get(
		"frame_secondary",
		skin_item.get("secondary", "")
	))
	if Color.html_is_valid(skin_secondary_html):
		frame_color = Color(skin_secondary_html)
	var frame_highlight := Color(
		minf(team_color.r + 0.28, 1.0),
		minf(team_color.g + 0.28, 1.0),
		minf(team_color.b + 0.28, 1.0),
		0.68
	)
	if custom_frame_palette:
		frame_highlight = frame_primary.lerp(frame_glow, 0.24)
		frame_highlight.a = 0.92

	# Geometry is authored at normal player scale and the cache nodes themselves
	# carry the action-pulse / 4v4+ presentation scale. This lets those effects
	# animate via transforms instead of rebuilding vector geometry.
	var visual_scale := 1.0
	var safe_outer_radius := maxf(40.0, badge_outer_radius)
	var safe_team_radius := clampf(
		badge_team_ring_radius,
		20.0,
		safe_outer_radius - 2.0
	)
	var safe_trim_radius := clampf(
		badge_white_trim_radius,
		16.0,
		safe_team_radius - 3.0
	)
	var safe_inner_radius := clampf(
		badge_inner_radius,
		12.0,
		safe_trim_radius - 3.0
	)
	var animation_time := float(Time.get_ticks_msec()) / 1000.0

	if not animated_pass:
		_cache_draw_circle_aa(
			canvas,
			badge_shadow_offset * 1.30,
			safe_outer_radius + 10.0,
			Color(0.0, 0.0, 0.0, 0.16)
		)
		_cache_draw_circle_aa(
			canvas,
			badge_shadow_offset * 0.70,
			safe_outer_radius + 5.0,
			Color(0.0, 0.005, 0.008, 0.28)
		)
		_cache_draw_circle_aa(
			canvas,
			Vector2.ZERO,
			safe_outer_radius + 7.0,
			Color(frame_glow, 0.38) if custom_frame_palette else Color(team_color, 0.20)
		)
		_cache_draw_circle_aa(
			canvas,
			Vector2.ZERO,
			safe_outer_radius,
			Color(0.008, 0.018, 0.025, 0.92)
		)
		_cache_draw_circle_aa(
			canvas,
			Vector2.ZERO,
			safe_team_radius,
			Color(frame_ring_color, 0.92 if custom_frame_palette else 0.88)
		)

	var material_id: String = get_cosmetic_item_id(
		FootballCosmeticInventory.SLOT_PLAYER_MATERIAL
	)
	var material_item: Dictionary = FootballCosmeticInventory.CATALOG.get(
		material_id,
		FootballCosmeticInventory.CATALOG["player_material.matte"]
	) as Dictionary
	FootballPlayerSkinVisuals.draw_team_material(
		canvas,
		Vector2.ZERO,
		material_item,
		team_color,
		safe_team_radius,
		safe_trim_radius,
		visual_scale,
		animation_time,
		not animated_pass,
		animated_pass
	)
	_draw_material_identity_overlays_cached(
		canvas,
		Vector2.ZERO,
		material_item,
		team_color,
		safe_team_radius,
		safe_trim_radius,
		visual_scale,
		animation_time,
		animated_pass
	)

	if not animated_pass:
		_cache_draw_circle_aa(
			canvas,
			Vector2.ZERO,
			safe_trim_radius,
			frame_color
		)
		_cache_draw_circle_aa(
			canvas,
			Vector2.ZERO,
			safe_inner_radius,
			badge_inner_color.lerp(team_color.darkened(0.68), 0.18)
		)
		FootballPlayerSkinVisuals.draw_skin_static(
			canvas,
			Vector2.ZERO,
			player_skin_id,
			skin_item,
			safe_inner_radius,
			safe_team_radius,
			visual_scale
		)
	else:
		FootballPlayerSkinVisuals.draw_skin_animated(
			canvas,
			Vector2.ZERO,
			player_skin_id,
			skin_item,
			safe_inner_radius,
			safe_team_radius,
			visual_scale,
			animation_time
		)

	FootballPlayerSkinVisuals.draw_team_frame(
		canvas,
		Vector2.ZERO,
		player_skin_id,
		skin_item,
		team_color,
		safe_outer_radius,
		safe_team_radius,
		visual_scale,
		animation_time,
		not animated_pass,
		animated_pass
	)

	if animated_pass:
		return

	# Frame-palette overlays and post caps are fully static and stay cached.
	if custom_frame_palette:
		_cache_draw_arc_screen_aa(
			canvas,
			Vector2.ZERO,
			safe_outer_radius - 2.0,
			0.0,
			TAU,
			64,
			Color(frame_primary, 0.42),
			2.2
		)
	_cache_draw_arc_screen_aa(
		canvas,
		Vector2.ZERO,
		safe_team_radius - 3.0,
		PI * 1.08,
		PI * 1.88,
		42,
		frame_highlight,
		3.0
	)
	_cache_draw_arc_screen_aa(
		canvas,
		Vector2.ZERO,
		safe_team_radius - 4.0,
		PI * 0.08,
		PI * 0.88,
		42,
		Color(frame_glow, 0.48) if custom_frame_palette else Color(0.0, 0.01, 0.018, 0.22),
		4.0 if custom_frame_palette else 5.0
	)
	_cache_draw_arc_screen_aa(
		canvas,
		Vector2.ZERO,
		safe_inner_radius - 2.0,
		0.0,
		TAU,
		48,
		Color(frame_primary, 0.40) if custom_frame_palette else Color(frame_color, 0.26),
		2.5
	)
	for post_direction: Vector2 in [Vector2.UP, Vector2.DOWN]:
		var post: Vector2 = post_direction * (safe_team_radius - 6.5)
		_cache_draw_circle_aa(canvas, post, 5.5, frame_color)
		_cache_draw_circle_aa(
			canvas,
			post,
			2.7,
			Color(frame_glow, 0.98) if custom_frame_palette else Color(team_color, 0.94)
		)


func _cache_draw_circle_aa(
	canvas: CanvasItem,
	position: Vector2,
	radius: float,
	color: Color,
	filled: bool = true,
	width: float = -1.0
) -> void:
	canvas.draw_circle(position, radius, color, filled, width, true)


func _cache_draw_arc_screen_aa(
	canvas: CanvasItem,
	center: Vector2,
	radius: float,
	start_angle: float,
	end_angle: float,
	point_count: int,
	color: Color,
	width: float = -1.0,
	antialiased: bool = true
) -> void:
	canvas.draw_arc(
		center,
		radius,
		start_angle,
		end_angle,
		point_count,
		color,
		FootballPlayerSkinVisuals._screen_safe_stroke_width(canvas, width),
		antialiased
	)


func _cache_draw_line_screen_aa(
	canvas: CanvasItem,
	from: Vector2,
	to: Vector2,
	color: Color,
	width: float = -1.0,
	antialiased: bool = true
) -> void:
	canvas.draw_line(
		from,
		to,
		color,
		FootballPlayerSkinVisuals._screen_safe_stroke_width(canvas, width),
		antialiased
	)


func _cache_draw_polyline_screen_aa(
	canvas: CanvasItem,
	points: PackedVector2Array,
	color: Color,
	width: float = -1.0,
	antialiased: bool = true
) -> void:
	canvas.draw_polyline(
		points,
		color,
		FootballPlayerSkinVisuals._screen_safe_stroke_width(canvas, width),
		antialiased
	)


func _draw_player_cosmetic_layer(
	player_skin_id: String,
	skin_item: Dictionary,
	inner_radius: float,
	team_radius: float,
	visual_scale: float
) -> void:
	FootballPlayerSkinVisuals.draw_skin(
		self,
		Vector2.ZERO,
		player_skin_id,
		skin_item,
		inner_radius,
		team_radius,
		visual_scale,
		float(Time.get_ticks_msec()) / 1000.0
	)


func _draw_material_identity_overlays_cached(
	canvas: CanvasItem,
	center: Vector2,
	material_item: Dictionary,
	team_color: Color,
	team_radius: float,
	trim_radius: float,
	visual_scale: float,
	time_seconds: float,
	animated_pass: bool
) -> void:
	var material_style: String = str(material_item.get("material_style", "matte"))
	if material_style == "" or material_style == "matte":
		return
	if FootballPlayerSkinVisuals.is_material_style_animated(material_style) != animated_pass:
		return
	var ring_mid: float = lerpf(trim_radius, team_radius, 0.55)
	var ring_span: float = maxf(3.0 * visual_scale, team_radius - trim_radius)
	var bright: Color = team_color.lightened(0.36)
	var soft: Color = team_color.lightened(0.18)
	var dark: Color = team_color.darkened(0.26)
	match material_style:
		"anodized":
			for band in range(3):
				var offset: float = float(band) * 0.16
				var glow_color: Color = bright.lerp(Color(0.92, 0.60 + 0.08 * band, 1.0, 1.0), 0.35)
				_cache_draw_arc_screen_aa(canvas, center, ring_mid - band * 1.8 * visual_scale, -0.55 + offset, 0.85 + offset, 28, Color(glow_color, 0.55), 2.4 * visual_scale, true)
				_cache_draw_arc_screen_aa(canvas, center, ring_mid - band * 1.8 * visual_scale, PI + 0.30 + offset, PI + 1.55 + offset, 28, Color(soft, 0.40), 2.0 * visual_scale, true)
		"brushed":
			for i in range(10):
				var angle: float = -0.92 + i * 0.22
				var inner: Vector2 = center + Vector2.RIGHT.rotated(angle) * (trim_radius + 2.0 * visual_scale)
				var outer: Vector2 = center + Vector2.RIGHT.rotated(angle + 0.12) * (team_radius - 2.2 * visual_scale)
				_cache_draw_line_screen_aa(canvas, inner, outer, Color(bright, 0.34 if i % 2 == 0 else 0.22), 1.6 * visual_scale, true)
				inner = center + Vector2.RIGHT.rotated(angle + PI) * (trim_radius + 2.0 * visual_scale)
				outer = center + Vector2.RIGHT.rotated(angle + PI + 0.12) * (team_radius - 2.2 * visual_scale)
				_cache_draw_line_screen_aa(canvas, inner, outer, Color(bright, 0.30 if i % 2 == 0 else 0.18), 1.6 * visual_scale, true)
		"carbon":
			for i in range(12):
				var a0: float = float(i) * TAU / 12.0
				var p0: Vector2 = center + Vector2.RIGHT.rotated(a0) * (trim_radius + 1.5 * visual_scale)
				var p1: Vector2 = center + Vector2.RIGHT.rotated(a0 + 0.16) * (ring_mid - 1.5 * visual_scale)
				var p2: Vector2 = center + Vector2.RIGHT.rotated(a0 + 0.32) * (team_radius - 2.0 * visual_scale)
				var p3: Vector2 = center + Vector2.RIGHT.rotated(a0 + 0.16) * (ring_mid + 2.0 * visual_scale)
				canvas.draw_colored_polygon(PackedVector2Array([p0, p1, p2, p3]), Color(dark, 0.26))
				_cache_draw_polyline_screen_aa(canvas, PackedVector2Array([p0, p1, p2, p3, p0]), Color(bright, 0.22), 1.0 * visual_scale, true)
		"pearl":
			var pearl_a: Color = Color(1.0, 0.82, 0.98, 0.48)
			var pearl_b: Color = Color(0.72, 0.96, 1.0, 0.34)
			_cache_draw_arc_screen_aa(canvas, center, ring_mid, -0.25, 1.95, 34, pearl_a, 3.2 * visual_scale, true)
			_cache_draw_arc_screen_aa(canvas, center, ring_mid - 2.0 * visual_scale, PI * 0.82, PI * 1.72, 30, pearl_b, 2.4 * visual_scale, true)
			for i in range(6):
				var sparkle_pos: Vector2 = center + Vector2.RIGHT.rotated(time_seconds * 0.55 + i * TAU / 6.0) * (ring_mid + sin(time_seconds * 1.4 + i) * 1.6 * visual_scale)
				_cache_draw_circle_aa(canvas, sparkle_pos, 1.2 * visual_scale, Color(1,1,1,0.55))
		"circuit":
			for i in range(8):
				var angle: float = time_seconds * 0.18 + float(i) * TAU / 8.0
				var p0: Vector2 = center + Vector2.RIGHT.rotated(angle) * (trim_radius + 1.5 * visual_scale)
				var p1: Vector2 = center + Vector2.RIGHT.rotated(angle) * (team_radius - 3.6 * visual_scale)
				var p2: Vector2 = p1 + Vector2.RIGHT.rotated(angle + (0.35 if i % 2 == 0 else -0.35)) * (5.0 * visual_scale)
				_cache_draw_line_screen_aa(canvas, p0, p1, Color(bright, 0.42), 1.7 * visual_scale, true)
				_cache_draw_line_screen_aa(canvas, p1, p2, Color(bright, 0.42), 1.7 * visual_scale, true)
				_cache_draw_circle_aa(canvas, p1, 1.8 * visual_scale, Color(bright, 0.75))
		"stardust":
			for i in range(14):
				var angle: float = float(i) * TAU / 14.0 + sin(time_seconds * 0.7 + i * 0.9) * 0.08
				var radius: float = trim_radius + 2.0 * visual_scale + fmod(float(i) * 3.1, ring_span - 1.0 * visual_scale)
				var capped_radius: float = minf(radius, team_radius - 1.5 * visual_scale)
				var pos: Vector2 = center + Vector2.RIGHT.rotated(angle) * capped_radius
				var size: float = 1.1 * visual_scale + float(i % 3) * 0.35 * visual_scale
				_cache_draw_circle_aa(canvas, pos, size, Color(1.0, 1.0, 1.0, 0.68))
				_cache_draw_line_screen_aa(canvas, pos + Vector2(-size, 0), pos + Vector2(size, 0), Color(bright, 0.42), 1.0 * visual_scale, true)
				_cache_draw_line_screen_aa(canvas, pos + Vector2(0, -size), pos + Vector2(0, size), Color(bright, 0.42), 1.0 * visual_scale, true)
		"vortex":
			for band in range(4):
				var start: float = time_seconds * 0.45 + float(band) * 0.52
				var end: float = start + 1.02 + float(band) * 0.12
				_cache_draw_arc_screen_aa(canvas, center, ring_mid - band * 1.5 * visual_scale, start, end, 32, Color(bright, 0.34 - band * 0.05), 2.1 * visual_scale, true)
				_cache_draw_arc_screen_aa(canvas, center, ring_mid + band * 0.9 * visual_scale, start + PI, end + PI * 0.92, 32, Color(soft, 0.26 - band * 0.04), 1.8 * visual_scale, true)
		_:
			pass


func _draw_material_identity_overlays(
	center: Vector2,
	material_item: Dictionary,
	team_color: Color,
	team_radius: float,
	trim_radius: float,
	visual_scale: float,
	time_seconds: float
) -> void:
	var material_style: String = str(material_item.get("material_style", "matte"))
	if material_style == "" or material_style == "matte":
		return
	var ring_mid: float = lerpf(trim_radius, team_radius, 0.55)
	var ring_span: float = maxf(3.0 * visual_scale, team_radius - trim_radius)
	var bright: Color = team_color.lightened(0.36)
	var soft: Color = team_color.lightened(0.18)
	var dark: Color = team_color.darkened(0.26)
	match material_style:
		"anodized":
			for band in range(3):
				var offset: float = float(band) * 0.16
				var glow_color: Color = bright.lerp(Color(0.92, 0.60 + 0.08 * band, 1.0, 1.0), 0.35)
				_draw_arc_screen_aa(center, ring_mid - band * 1.8 * visual_scale, -0.55 + offset, 0.85 + offset, 28, Color(glow_color, 0.55), 2.4 * visual_scale, true)
				_draw_arc_screen_aa(center, ring_mid - band * 1.8 * visual_scale, PI + 0.30 + offset, PI + 1.55 + offset, 28, Color(soft, 0.40), 2.0 * visual_scale, true)
		"brushed":
			for i in range(10):
				var angle: float = -0.92 + i * 0.22
				var inner: Vector2 = center + Vector2.RIGHT.rotated(angle) * (trim_radius + 2.0 * visual_scale)
				var outer: Vector2 = center + Vector2.RIGHT.rotated(angle + 0.12) * (team_radius - 2.2 * visual_scale)
				_draw_line_screen_aa(inner, outer, Color(bright, 0.34 if i % 2 == 0 else 0.22), 1.6 * visual_scale, true)
				inner = center + Vector2.RIGHT.rotated(angle + PI) * (trim_radius + 2.0 * visual_scale)
				outer = center + Vector2.RIGHT.rotated(angle + PI + 0.12) * (team_radius - 2.2 * visual_scale)
				_draw_line_screen_aa(inner, outer, Color(bright, 0.30 if i % 2 == 0 else 0.18), 1.6 * visual_scale, true)
		"carbon":
			for i in range(12):
				var a0: float = float(i) * TAU / 12.0
				var p0: Vector2 = center + Vector2.RIGHT.rotated(a0) * (trim_radius + 1.5 * visual_scale)
				var p1: Vector2 = center + Vector2.RIGHT.rotated(a0 + 0.16) * (ring_mid - 1.5 * visual_scale)
				var p2: Vector2 = center + Vector2.RIGHT.rotated(a0 + 0.32) * (team_radius - 2.0 * visual_scale)
				var p3: Vector2 = center + Vector2.RIGHT.rotated(a0 + 0.16) * (ring_mid + 2.0 * visual_scale)
				draw_colored_polygon(PackedVector2Array([p0, p1, p2, p3]), Color(dark, 0.26))
				_draw_polyline_screen_aa(PackedVector2Array([p0, p1, p2, p3, p0]), Color(bright, 0.22), 1.0 * visual_scale, true)
		"pearl":
			var pearl_a: Color = Color(1.0, 0.82, 0.98, 0.48)
			var pearl_b: Color = Color(0.72, 0.96, 1.0, 0.34)
			_draw_arc_screen_aa(center, ring_mid, -0.25, 1.95, 34, pearl_a, 3.2 * visual_scale, true)
			_draw_arc_screen_aa(center, ring_mid - 2.0 * visual_scale, PI * 0.82, PI * 1.72, 30, pearl_b, 2.4 * visual_scale, true)
			for i in range(6):
				var sparkle_pos: Vector2 = center + Vector2.RIGHT.rotated(time_seconds * 0.55 + i * TAU / 6.0) * (ring_mid + sin(time_seconds * 1.4 + i) * 1.6 * visual_scale)
				_draw_circle_aa(sparkle_pos, 1.2 * visual_scale, Color(1,1,1,0.55))
		"circuit":
			for i in range(8):
				var angle: float = time_seconds * 0.18 + float(i) * TAU / 8.0
				var p0: Vector2 = center + Vector2.RIGHT.rotated(angle) * (trim_radius + 1.5 * visual_scale)
				var p1: Vector2 = center + Vector2.RIGHT.rotated(angle) * (team_radius - 3.6 * visual_scale)
				var p2: Vector2 = p1 + Vector2.RIGHT.rotated(angle + (0.35 if i % 2 == 0 else -0.35)) * (5.0 * visual_scale)
				_draw_line_screen_aa(p0, p1, Color(bright, 0.42), 1.7 * visual_scale, true)
				_draw_line_screen_aa(p1, p2, Color(bright, 0.42), 1.7 * visual_scale, true)
				_draw_circle_aa(p1, 1.8 * visual_scale, Color(bright, 0.75))
		"stardust":
			for i in range(14):
				var angle: float = float(i) * TAU / 14.0 + sin(time_seconds * 0.7 + i * 0.9) * 0.08
				var radius: float = trim_radius + 2.0 * visual_scale + fmod(float(i) * 3.1, ring_span - 1.0 * visual_scale)
				var capped_radius: float = minf(radius, team_radius - 1.5 * visual_scale)
				var pos: Vector2 = center + Vector2.RIGHT.rotated(angle) * capped_radius
				var size: float = 1.1 * visual_scale + float(i % 3) * 0.35 * visual_scale
				_draw_circle_aa(pos, size, Color(1.0, 1.0, 1.0, 0.68))
				_draw_line_screen_aa(pos + Vector2(-size, 0), pos + Vector2(size, 0), Color(bright, 0.42), 1.0 * visual_scale, true)
				_draw_line_screen_aa(pos + Vector2(0, -size), pos + Vector2(0, size), Color(bright, 0.42), 1.0 * visual_scale, true)
		"vortex":
			for band in range(4):
				var start: float = time_seconds * 0.45 + float(band) * 0.52
				var end: float = start + 1.02 + float(band) * 0.12
				_draw_arc_screen_aa(center, ring_mid - band * 1.5 * visual_scale, start, end, 32, Color(bright, 0.34 - band * 0.05), 2.1 * visual_scale, true)
				_draw_arc_screen_aa(center, ring_mid + band * 0.9 * visual_scale, start + PI, end + PI * 0.92, 32, Color(soft, 0.26 - band * 0.04), 1.8 * visual_scale, true)
		_:
			pass


func _draw_ball_contact_flash(outer_radius: float) -> void:
	var duration := maxf(0.01, ball_contact_flash_seconds)
	var remaining_ratio := clampf(
		_ball_contact_flash_remaining / duration,
		0.0,
		1.0
	)
	var expansion := 1.0 - remaining_ratio
	var alpha := pow(remaining_ratio, 1.7)
	var bright := _ball_contact_flash_color.lightened(0.42)
	var base_radius := outer_radius + 10.0 + expansion * 9.0
	var tick_length := lerpf(11.0, 25.0, _ball_contact_flash_strength)

	# Short badge ticks make contact readable without drawing a large ring
	# over the pitch markings.
	for tick_index in range(8):
		var angle := float(tick_index) * TAU / 8.0
		var direction := Vector2.from_angle(angle)
		var start := direction * base_radius
		var finish := direction * (base_radius + tick_length)
		_draw_line_screen_aa(
			start,
			finish,
			Color(bright, alpha * 0.72),
			lerpf(5.0, 1.0, expansion),
			true
		)


func _get_badge_team_color() -> Color:
	match team:
		&"blue":
			return badge_blue_color
		&"red":
			return badge_red_color
		_:
			return badge_neutral_color


func _get_effective_badge_team_color() -> Color:
	var team_color: Color = _get_badge_team_color()
	if team in [&"blue", &"red"]:
		team_color = FootballCosmeticInventory.get_team_primary_color_from_index(
			team,
			int(cosmetic_loadout.get("team_primary_color_%s" % str(team), 0))
		)
	var special_override: String = str(
		cosmetic_loadout.get("special_team_color_override", "")
	).to_lower()
	if special_override == FootballCosmeticInventory.DICTATOR_TEAM_COLOR_OVERRIDE:
		return Color(FootballCosmeticInventory.DICTATOR_TEAM_COLOR_OVERRIDE)
	if special_override == FootballCosmeticInventory.GOJO_TEAM_COLOR_OVERRIDE:
		return Color(FootballCosmeticInventory.GOJO_TEAM_COLOR_OVERRIDE)
	if special_override == FootballCosmeticInventory.NEYMAR_TEAM_COLOR_OVERRIDE:
		return Color(FootballCosmeticInventory.NEYMAR_TEAM_COLOR_OVERRIDE)
	if special_override == FootballCosmeticInventory.HAALAND_TEAM_COLOR_OVERRIDE:
		return Color(FootballCosmeticInventory.HAALAND_TEAM_COLOR_OVERRIDE)
	return team_color


# Visual-only soft light uses the player's equipped TEAM color only.  Abilities
# deliberately do not tint this: if a player equips cyan/teal/gold/etc. for the
# team presentation, the light around that character stays that same identity.
# Special footballer team-color overrides are already handled by
# _get_effective_badge_team_color(), so their light remains visually consistent
# with the badge as well.
func get_soft_glow_color() -> Color:
	return _get_effective_badge_team_color()


func _refresh_soft_glow() -> void:
	if player_glow_fx == null:
		return
	if player_glow_fx.has_method("set_accent_color"):
		player_glow_fx.call("set_accent_color", get_soft_glow_color())
	if player_glow_fx.has_method("set_size_multiplier"):
		player_glow_fx.call(
			"set_size_multiplier",
			_action_pulse_visual_scale * _large_team_size_multiplier
		)


func _update_ability_portrait(animate: bool) -> void:
	if ability_portrait == null:
		return

	var portrait_texture := _get_selected_portrait()
	var diameter := maxf(40.0, ability_skin_diameter)
	ability_portrait.position = Vector2.ONE * (-diameter * 0.5)
	ability_portrait.size = Vector2.ONE * diameter
	ability_portrait.texture = portrait_texture
	# The Mirage Step icon is pre-colored in the canonical SVG like every other
	# menu/HUD use. Keep only the normal circular field mask here so its colors
	# stay identical instead of being recolored a second time.
	ability_portrait.material = _default_ability_portrait_material
	if is_satoru_gojo() and selected_ability == ABILITY_IRON_ANCHOR:
		ability_portrait.modulate = Color(0.77, 0.36, 1.0, 1.0)
	elif is_haaland_boss() and selected_ability == ABILITY_POWER_STRIKE:
		ability_portrait.modulate = Color(0.50, 0.86, 1.0, 1.0)
	elif is_neymar_boss() and selected_ability == ABILITY_ELASTIC_STEP:
		ability_portrait.modulate = Color(1.0, 0.78, 0.28, 1.0)
	else:
		ability_portrait.modulate = Color.WHITE
	ability_portrait.visible = (
		portrait_texture != null
		and _should_show_field_ability_icons()
	)

	var portrait_scale := _get_ability_portrait_presentation_scale()
	if not animate or portrait_texture == null:
		ability_portrait.modulate.a = 1.0
		ability_portrait.scale = portrait_scale
		return

	ability_portrait.pivot_offset = ability_portrait.size * 0.5
	ability_portrait.modulate.a = 0.0
	ability_portrait.scale = portrait_scale * 0.86
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUART)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(
		ability_portrait,
		"modulate:a",
		1.0,
		0.2
	)
	tween.tween_property(
		ability_portrait,
		"scale",
		portrait_scale,
		0.2
	)


func _get_ability_portrait_presentation_scale() -> Vector2:
	return (
		_ability_portrait_base_scale
		* _action_pulse_visual_scale
		* _large_team_size_multiplier
	)


func _should_show_field_ability_icons() -> bool:
	# This is a local accessibility/cosmetic preference, not part of a
	# player's replicated appearance. Every client may hide only the icon on
	# its own controlled character without changing what anybody else sees.
	if cpu_controlled or not _is_local_player():
		return true
	var inventory := get_node_or_null(
		"/root/CosmeticInventory"
	) as FootballCosmeticInventory
	if inventory == null:
		return true
	return inventory.get_show_field_ability_icons()


func refresh_field_ability_icon_visibility() -> void:
	_update_ability_portrait(false)


func _get_selected_portrait() -> Texture2D:
	match selected_ability:
		ABILITY_BURST_DRIBBLE:
			return burst_dribble_skin
		ABILITY_QUICK_TRIGGER:
			return curve_shot_skin
		ABILITY_POWER_STRIKE:
			return power_strike_skin
		ABILITY_OVERDRIVE:
			return overdrive_skin
		ABILITY_HEEL_TURN:
			return heel_turn_skin
		ABILITY_ENFORCER:
			return enforcer_skin
		ABILITY_GOALKEEPER_REACH:
			return goalkeeper_reach_skin
		ABILITY_TIME_SKIP_PASS:
			return time_skip_pass_skin
		ABILITY_DIRECT_FINISH:
			return direct_finish_skin
		ABILITY_ELASTIC_STEP:
			return elastic_step_skin
		ABILITY_META_VISION:
			return meta_vision_skin
		ABILITY_COPYCAT:
			return copycat_skin
		ABILITY_REFLEX_BLOCK:
			return reflex_block_skin
		ABILITY_IRON_ANCHOR:
			return iron_anchor_skin
		ABILITY_BLIND_SPOT:
			return blind_spot_skin
		ABILITY_BOOGIE_WOOGIE:
			return boogie_woogie_skin
		ABILITY_ECHO:
			return echo_skin
		ABILITY_RETURN_TAG:
			return return_tag_skin
		ABILITY_BREAKAWAY:
			return breakaway_skin
		ABILITY_SNAPBACK:
			return snapback_skin
		ABILITY_SIDE_SWIPE:
			return side_swipe_skin
		ABILITY_NUTMEG:
			return nutmeg_skin
		ABILITY_DECOY_RUN:
			return decoy_run_skin
		_:
			return no_ability_skin


func _integrate_forces(
	state: PhysicsDirectBodyState2D
) -> void:
	if not multiplayer.is_server():
		return
	_repair_invalid_physics_state(state)
	if not controls_enabled:
		_publish_server_network_motion_state(state)
		return


	if not _physics_vector_is_sane(server_direction, 2.0):
		server_direction = Vector2.ZERO
	var movement_direction := server_direction.limit_length(1.0)
	var acceleration_multiplier := 1.0
	var speed_multiplier := 1.0

	if _server_ability_is_active(ABILITY_BURST_DRIBBLE):
		acceleration_multiplier = lerpf(
			1.0,
			burst_acceleration_multiplier,
			server_ability_strength_scale
		)
		speed_multiplier = lerpf(
			1.0,
			burst_speed_multiplier,
			server_ability_strength_scale
		)
	elif _server_ability_is_active(ABILITY_ELASTIC_STEP):
		acceleration_multiplier = lerpf(
			1.0,
			elastic_step_acceleration_multiplier,
			server_ability_strength_scale
		)
		speed_multiplier = lerpf(
			1.0,
			elastic_step_speed_multiplier,
			server_ability_strength_scale
		)
		_keep_elastic_step_inside_kick_range(
			state,
			movement_direction
		)
	elif _server_ability_is_active(
		ABILITY_GOALKEEPER_REACH
	):
		speed_multiplier = lerpf(
			1.0,
			goalkeeper_reach_speed_multiplier,
			server_ability_strength_scale
		)
	elif _server_ability_is_active(ABILITY_OVERDRIVE):
		acceleration_multiplier = lerpf(
			1.0,
			overdrive_acceleration_multiplier,
			server_ability_strength_scale
		)
		speed_multiplier = lerpf(
			1.0,
			overdrive_speed_multiplier,
			server_ability_strength_scale
		)
	var now: float = _server_time_seconds()
	if is_haaland_boss():
		# Relentless Nine is intrinsic boss behavior, not a Draft perk. It is
		# therefore active in every mode and cannot collide with card effects.
		speed_multiplier = maxf(
			speed_multiplier,
			maxf(1.0, haaland_boss_speed_multiplier)
		)
		acceleration_multiplier = maxf(
			acceleration_multiplier,
			maxf(1.0, haaland_boss_acceleration_multiplier)
		)
		if _haaland_predator_is_active(now):
			speed_multiplier = maxf(
				speed_multiplier,
				maxf(1.0, haaland_predator_speed_multiplier)
			)
			acceleration_multiplier = maxf(
				acceleration_multiplier,
				maxf(1.0, haaland_predator_acceleration_multiplier)
			)
	acceleration_multiplier *= draft_perk_acceleration_multiplier
	speed_multiplier *= draft_perk_speed_multiplier
	if now < draft_perk_action_acceleration_until:
		acceleration_multiplier *= draft_perk_action_acceleration_multiplier
	if now < draft_perk_action_speed_until:
		speed_multiplier *= draft_perk_action_speed_multiplier
	if now < server_breakaway_chase_until:
		var chase_strength: float = clampf(
			server_breakaway_chase_strength,
			0.0,
			1.5
		)
		acceleration_multiplier = maxf(
			acceleration_multiplier,
			lerpf(
				1.0,
				breakaway_chase_acceleration_multiplier,
				chase_strength
			)
		)
		speed_multiplier = maxf(
			speed_multiplier,
			lerpf(
				1.0,
				breakaway_chase_speed_multiplier,
				chase_strength
			)
		)
		if (
			movement_direction.is_zero_approx()
			and not server_breakaway_chase_direction.is_zero_approx()
		):
			movement_direction = (
				server_breakaway_chase_direction.normalized() * 0.35
			)
	elif server_breakaway_chase_until > 0.0:
		server_breakaway_chase_until = 0.0
		server_breakaway_chase_direction = Vector2.ZERO
		server_breakaway_chase_strength = 1.0
	if now < server_nutmeg_chase_until:
		acceleration_multiplier = maxf(
			acceleration_multiplier,
			maxf(1.0, nutmeg_outplay_acceleration_multiplier)
		)
		speed_multiplier = maxf(
			speed_multiplier,
			maxf(1.0, nutmeg_outplay_speed_multiplier)
		)
		if (
			movement_direction.is_zero_approx()
			and not server_nutmeg_chase_direction.is_zero_approx()
		):
			movement_direction = server_nutmeg_chase_direction * 0.3
	elif server_nutmeg_chase_until > 0.0:
		server_nutmeg_chase_until = 0.0
		server_nutmeg_chase_direction = Vector2.ZERO

	for contact_index in range(state.get_contact_count()):
		var collider := state.get_contact_collider_object(
			contact_index
		)
		if collider is FootballBall:
			continue

		var contact_normal := state.get_contact_local_normal(
			contact_index
		).normalized()
		var into_surface := movement_direction.dot(
			contact_normal
		)

		if into_surface < 0.0:
			movement_direction -= (
				contact_normal * into_surface
			)

	state.apply_central_force(
		movement_direction
		* acceleration
		* acceleration_multiplier
	)

	var current_max_speed := max_speed * speed_multiplier
	if state.linear_velocity.length() > current_max_speed:
		state.linear_velocity = (
			state.linear_velocity.normalized()
			* current_max_speed
		)

	var damp_factor := clampf(
		1.0 - maxf(0.0, linear_damp) * state.step,
		0.0,
		1.0
	)
	var ball_free_velocity := _ball_free_linear_velocity * damp_factor
	ball_free_velocity += (
		movement_direction
		* acceleration
		* acceleration_multiplier
		* state.inverse_mass
		* state.step
	)
	ball_free_velocity = ball_free_velocity.limit_length(
		maxf(0.0, current_max_speed)
	)

	_apply_ball_contact_knockback_multiplier(
		state,
		ball_free_velocity
	)
	_ball_free_linear_velocity = state.linear_velocity
	_repair_invalid_physics_state(state)
	_publish_server_network_motion_state(state)


func _publish_server_network_motion_state(
	state: PhysicsDirectBodyState2D
) -> void:
	# Publish exactly the state simulated by the host physics tick. The
	# MultiplayerSynchronizer samples these values at 60 Hz.
	var parent_node := get_parent() as Node2D
	network_position = (
		parent_node.to_local(state.transform.origin)
		if parent_node != null
		else state.transform.origin
	)
	network_linear_velocity = state.linear_velocity


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
		var fallback_origin := Vector2.ZERO
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
	server_direction = Vector2.ZERO
	_ball_free_linear_velocity = state.linear_velocity
	_remember_valid_physics_state(
		state.transform,
		state.linear_velocity,
		state.angular_velocity
	)
	return true


func _apply_ball_contact_knockback_multiplier(
	state: PhysicsDirectBodyState2D,
	ball_free_velocity: Vector2
) -> void:
	for contact_index in range(state.get_contact_count()):
		var ball := state.get_contact_collider_object(
			contact_index
		) as FootballBall
		if ball == null:
			continue

		var multiplier := ball.get_player_ball_impact_knockback_multiplier()
		if multiplier >= 1.0:
			continue

		var away_from_ball := (
			state.transform.origin - ball.global_position
		).normalized()
		if away_from_ball.is_zero_approx():
			away_from_ball = state.get_contact_local_normal(
				contact_index
			).normalized()
		if away_from_ball.is_zero_approx():
			continue

		var physical_axis_speed := state.linear_velocity.dot(
			away_from_ball
		)
		var ball_free_axis_speed := ball_free_velocity.dot(
			away_from_ball
		)
		var adjusted_axis_speed := lerpf(
			ball_free_axis_speed,
			physical_axis_speed,
			multiplier
		)
		state.linear_velocity += away_from_ball * (
			adjusted_axis_speed - physical_axis_speed
		)


func _update_client_movement_input_transport(
	delta: float,
	direction: Vector2
) -> void:
	var limited_direction: Vector2 = direction.limit_length(1.0)
	_client_input_send_elapsed += maxf(0.0, delta)

	var current_stopped: bool = limited_direction.length_squared() <= 0.0004
	var previous_stopped: bool = (
		not _client_has_sent_direction
		or _client_last_sent_direction.length_squared() <= 0.0004
	)
	var direction_delta: float = limited_direction.distance_to(
		_client_last_sent_direction
	)
	var start_or_stop: bool = (
		_client_has_sent_direction
		and current_stopped != previous_stopped
	)
	var immediate_turn: bool = (
		_client_has_sent_direction
		and direction_delta >= CLIENT_INPUT_IMMEDIATE_CHANGE_THRESHOLD
	)
	var sampled_change: bool = (
		direction_delta >= CLIENT_INPUT_DIRECTION_CHANGE_THRESHOLD
		and _client_input_send_elapsed >= CLIENT_INPUT_MIN_SEND_INTERVAL_SECONDS
	)
	var heartbeat_due: bool = (
		_client_input_send_elapsed >= CLIENT_INPUT_HEARTBEAT_SECONDS
	)

	if (
		not _client_has_sent_direction
		or start_or_stop
		or immediate_turn
		or sampled_change
		or heartbeat_due
	):
		_client_input_sequence += 1
		_send_movement_input.rpc_id(
			SERVER_PEER_ID,
			_client_input_sequence,
			limited_direction
		)
		_client_last_sent_direction = limited_direction
		_client_has_sent_direction = true
		_client_input_send_elapsed = 0.0


func _update_client_network_motion(delta: float) -> void:
	_repair_invalid_client_network_motion()
	# Prefer MultiplayerSynchronizer.synchronized so packet arrival cadence is
	# measured from complete synchronization states instead of inferred from
	# whether a value happened to change. Keep the old value-edge detection as a
	# fallback for unusual scene/runtime setups where the signal is unavailable.
	if not _network_snapshot_signal_connected:
		var received_new_snapshot: bool = (
			network_position != _network_last_snapshot_position
			or network_linear_velocity != _network_last_snapshot_velocity
		)
		if received_new_snapshot:
			_accept_network_motion_snapshot()
		else:
			_network_snapshot_age += maxf(0.0, delta)
	else:
		_network_snapshot_age += maxf(0.0, delta)

	# Keep client-side visual helpers that read linear_velocity useful even though
	# physics itself remains server-only/frozen on clients.
	linear_velocity = _network_target_velocity

	if not _network_motion_initialized:
		position = _network_target_position
		_network_motion_initialized = true
		return

	var extrapolation_seconds := _get_network_prediction_seconds()
	var desired_position: Vector2 = (
		_network_target_position
		+ _network_target_velocity * extrapolation_seconds
	)
	var correction: Vector2 = desired_position - position
	if correction.length() >= NETWORK_TELEPORT_SNAP_DISTANCE:
		# Kickoffs, goal resets, swaps and other deliberate teleports must not
		# visually glide across the whole arena.
		position = _network_target_position
		return

	var response: float = (
		NETWORK_LOCAL_SMOOTHING_RESPONSE
		if _is_local_player()
		else NETWORK_REMOTE_SMOOTHING_RESPONSE
	)
	var blend: float = 1.0 - exp(-response * maxf(0.0, delta))
	position = position.lerp(desired_position, clampf(blend, 0.0, 1.0))
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
		and arrival_interval <= NETWORK_SNAPSHOT_INTERVAL_MAX_SAMPLE_SECONDS
	):
		_network_smoothed_snapshot_interval = lerpf(
			_network_smoothed_snapshot_interval,
			arrival_interval,
			NETWORK_SNAPSHOT_INTERVAL_BLEND
		)
	_network_last_snapshot_position = network_position
	_network_last_snapshot_velocity = network_linear_velocity
	_network_target_position = network_position
	_network_target_velocity = network_linear_velocity
	_network_snapshot_age = 0.0


func _get_network_prediction_seconds() -> float:
	var prediction_horizon := clampf(
		maxf(
			NETWORK_SNAPSHOT_EXTRAPOLATION_SECONDS,
			_network_smoothed_snapshot_interval
			* NETWORK_SNAPSHOT_INTERVAL_MULTIPLIER
			+ NETWORK_SNAPSHOT_JITTER_MARGIN_SECONDS
		),
		NETWORK_SNAPSHOT_EXTRAPOLATION_SECONDS,
		NETWORK_SNAPSHOT_MAX_EXTRAPOLATION_SECONDS
	)
	if _network_snapshot_age <= prediction_horizon:
		return _network_snapshot_age

	# If a packet is late, ease toward a stop instead of hitting the prediction
	# ceiling in one frame. This makes packet loss/jitter visible as a gentle
	# correction rather than the old stop-jump-stop cadence.
	var stale_age := _network_snapshot_age - prediction_horizon
	var decay_seconds := maxf(
		0.001,
		NETWORK_SNAPSHOT_STALE_DECAY_SECONDS
	)
	return prediction_horizon + decay_seconds * (
		1.0 - exp(-stale_age / decay_seconds)
	)


func _repair_invalid_client_network_motion() -> bool:
	var repaired := false
	if not _physics_vector_is_sane(position):
		position = _network_last_safe_render_position
		repaired = true
	if (
		not _physics_vector_is_sane(network_position)
		or network_position.distance_to(
			_network_last_safe_render_position
		) > PHYSICS_SANITY_MAX_SINGLE_STEP_DISPLACEMENT
	):
		network_position = _network_last_safe_render_position
		repaired = true
	if not _physics_vector_is_sane(
		network_linear_velocity,
		PHYSICS_SANITY_MAX_SPEED
	):
		network_linear_velocity = Vector2.ZERO
		repaired = true
	if not _physics_vector_is_sane(_network_target_position):
		_network_target_position = _network_last_safe_render_position
		repaired = true
	if not _physics_vector_is_sane(
		_network_target_velocity,
		PHYSICS_SANITY_MAX_SPEED
	):
		_network_target_velocity = Vector2.ZERO
		repaired = true
	if repaired:
		_network_last_snapshot_position = network_position
		_network_last_snapshot_velocity = network_linear_velocity
		_network_snapshot_age = 0.0
		_network_smoothed_snapshot_interval = 1.0 / 60.0
	return repaired


@rpc("any_peer", "call_remote", "unreliable")
func _send_movement_input(sequence: int, direction: Vector2) -> void:
	if (
		not multiplayer.is_server()
		or multiplayer.get_remote_sender_id() != owner_peer_id
	):
		return
	if sequence <= _server_last_input_sequence:
		return
	_server_last_input_sequence = sequence

	_server_track_reverse_drag_input(direction)
	server_direction = direction.limit_length(1.0)


func _server_track_reverse_drag_input(direction: Vector2) -> void:
	if not multiplayer.is_server() or cpu_controlled or not controls_enabled:
		return
	var limited_direction: Vector2 = direction.limit_length(1.0)
	_server_reverse_drag_current_input = limited_direction
	if limited_direction.length() < REVERSE_DRAG_MIN_INPUT_STRENGTH:
		return
	var now: float = _server_time_seconds()
	var strong_direction: Vector2 = limited_direction.normalized()
	if (
		not _server_reverse_drag_last_strong_direction.is_zero_approx()
		and now - _server_reverse_drag_last_strong_at
		<= REVERSE_DRAG_DIRECTION_MEMORY_SECONDS
	):
		var reversal_dot: float = _server_reverse_drag_last_strong_direction.dot(
			strong_direction
		)
		if reversal_dot <= REVERSE_DRAG_MAX_REVERSAL_DOT:
			_server_reverse_drag_forward_direction = (
				_server_reverse_drag_last_strong_direction
			)
			_server_reverse_drag_reverse_direction = strong_direction
			_server_reverse_drag_armed_until = (
				now + REVERSE_DRAG_EXECUTION_WINDOW_SECONDS
			)
			_server_reverse_drag_snap_quality = clampf(
				(-reversal_dot - absf(REVERSE_DRAG_MAX_REVERSAL_DOT))
				/ maxf(0.001, 1.0 - absf(REVERSE_DRAG_MAX_REVERSAL_DOT)),
				0.0,
				1.0
			)
	_server_reverse_drag_last_strong_direction = strong_direction
	_server_reverse_drag_last_strong_at = now


func _clear_server_reverse_drag_chain() -> void:
	_server_reverse_drag_chain_until = -INF
	_server_reverse_drag_chain_direction = Vector2.ZERO
	_server_reverse_drag_last_touch_at = -INF
	_server_reverse_drag_chain_touch_queued = false


func _apply_server_reverse_drag_touch(
	ball_target: FootballBall,
	drag_direction: Vector2,
	target_speed: float,
	now: float,
	control_strength: float
) -> void:
	var safe_direction: Vector2 = drag_direction.normalized()
	if safe_direction.is_zero_approx():
		return
	var incoming_velocity: Vector2 = ball_target.linear_velocity
	var target_force: float = maxf(0.0, target_speed)
	var current_along_direction: float = incoming_velocity.dot(safe_direction)
	var desired_speed: float = maxf(
		target_force,
		current_along_direction + target_force * 0.28
	)
	var desired_velocity: Vector2 = safe_direction * desired_speed
	# A dribble touch controls velocity instead of stacking another impulse on
	# top of it, but repeated touches were decaying because the same target speed
	# kept shrinking the relative delta. Keep a meaningful directional floor so
	# each reverse-touch still changes the ball even after the first one.
	var outgoing_velocity: Vector2 = incoming_velocity.lerp(
		desired_velocity,
		clampf(control_strength, 0.0, 1.0)
	)
	var impulse: Vector2 = (
		outgoing_velocity - incoming_velocity
	) * maxf(0.001, ball_target.mass)
	var minimum_delta: float = maxf(
		target_force * 0.16,
		REVERSE_DRAG_CHAIN_MIN_FORCE * 0.08
	)
	var aligned_delta: float = impulse.dot(safe_direction)
	if aligned_delta < minimum_delta:
		impulse += safe_direction * maxf(
			0.0,
			minimum_delta - aligned_delta
		)
	if impulse.length_squared() <= 0.01:
		return
	ball_target.register_kick(
		owner_peer_id,
		display_name,
		team,
		impulse
	)
	ball_target.apply_central_impulse(impulse)
	next_soft_pass_allowed_at = now + REVERSE_DRAG_TOUCH_COOLDOWN_SECONDS
	next_shot_allowed_at = now + REVERSE_DRAG_SHOT_LOCKOUT_SECONDS
	server_last_kick_charge_seconds = 0.0
	server_last_kick_was_soft_pass = true
	server_last_kick_time = now
	_receive_player_action_pulse.rpc(
		ACTION_PULSE_PASS,
		0.68,
		ABILITY_NONE
	)
	_receive_shot_sound.rpc(maxf(120.0, impulse.length()))
	_send_soft_pass_result(true)


func _get_reverse_drag_chain_direction(
	chain_direction: Vector2,
	input_direction: Vector2
) -> Vector2:
	var safe_chain: Vector2 = chain_direction.normalized()
	var safe_input: Vector2 = input_direction.limit_length(1.0)
	if (
		safe_chain.is_zero_approx()
		or safe_input.length() < REVERSE_DRAG_CHAIN_MIN_INPUT_STRENGTH
	):
		return Vector2.ZERO
	safe_input = safe_input.normalized()
	if safe_chain.dot(safe_input) < REVERSE_DRAG_CHAIN_MIN_DIRECTION_DOT:
		return Vector2.ZERO
	return (
		safe_chain * (1.0 - REVERSE_DRAG_CHAIN_STEER_WEIGHT)
		+ safe_input * REVERSE_DRAG_CHAIN_STEER_WEIGHT
	).normalized()


func _try_server_reverse_drag_chain(now: float) -> bool:
	if (
		now > _server_reverse_drag_chain_until
		or _server_reverse_drag_chain_direction.is_zero_approx()
	):
		return false
	var input_direction: Vector2 = (
		_server_reverse_drag_current_input.limit_length(1.0)
	)
	var steered_direction: Vector2 = _get_reverse_drag_chain_direction(
		_server_reverse_drag_chain_direction,
		input_direction
	)
	if steered_direction.is_zero_approx():
		return false
	if (
		now < next_soft_pass_allowed_at
		or now < next_shot_allowed_at
	):
		# Preserve one early press. Human button cadence no longer has to match
		# the exact server touch interval used by the CPU.
		_server_reverse_drag_chain_touch_queued = true
		return true
	var ball_target: FootballBall = _get_closest_ball_in_kick_area()
	if ball_target == null:
		return false
	var elapsed_since_touch: float = maxf(
		0.0,
		now - _server_reverse_drag_last_touch_at
	)
	var cadence_quality: float = clampf(
		(elapsed_since_touch - REVERSE_DRAG_TOUCH_COOLDOWN_SECONDS)
		/ maxf(
			0.001,
			REVERSE_DRAG_CHAIN_WINDOW_SECONDS
			- REVERSE_DRAG_TOUCH_COOLDOWN_SECONDS
		),
		0.0,
		1.0
	)
	var force: float = lerpf(
		REVERSE_DRAG_CHAIN_MIN_FORCE,
		REVERSE_DRAG_CHAIN_MAX_FORCE,
		cadence_quality
	)
	_apply_server_reverse_drag_touch(
		ball_target,
		steered_direction,
		force,
		now,
		REVERSE_DRAG_CHAIN_CONTROL_STRENGTH
	)
	_server_reverse_drag_chain_direction = steered_direction
	_server_reverse_drag_last_touch_at = now
	_server_reverse_drag_chain_until = now + REVERSE_DRAG_CHAIN_WINDOW_SECONDS
	_server_reverse_drag_chain_touch_queued = false
	return true


func _server_update_queued_reverse_drag_touch() -> void:
	if not multiplayer.is_server() or not _server_reverse_drag_chain_touch_queued:
		return
	var now: float = _server_time_seconds()
	if (
		now > _server_reverse_drag_chain_until
		or _server_reverse_drag_chain_direction.is_zero_approx()
	):
		_clear_server_reverse_drag_chain()
		return
	if now < next_soft_pass_allowed_at or now < next_shot_allowed_at:
		return
	# Consume exactly one buffered press. Further touches still require further
	# taps, so this remains a manual dribbling technique rather than auto-control.
	_server_reverse_drag_chain_touch_queued = false
	_try_server_reverse_drag_chain(now)


func _try_server_reverse_drag(now: float) -> bool:
	if not multiplayer.is_server() or cpu_controlled:
		return false
	var initial_drag_ready: bool = (
		now <= _server_reverse_drag_armed_until
		and not _server_reverse_drag_forward_direction.is_zero_approx()
		and not _server_reverse_drag_reverse_direction.is_zero_approx()
	)
	if not initial_drag_ready:
		return _try_server_reverse_drag_chain(now)
	var ball_target: FootballBall = _get_closest_ball_in_kick_area()
	if ball_target == null:
		return false
	var reverse_direction: Vector2 = _server_reverse_drag_reverse_direction.normalized()
	var remaining: float = clampf(
		(_server_reverse_drag_armed_until - now)
		/ REVERSE_DRAG_EXECUTION_WINDOW_SECONDS,
		0.0,
		1.0
	)
	var precision: float = clampf(
		_server_reverse_drag_snap_quality * 0.65 + remaining * 0.35,
		0.0,
		1.0
	)
	var force: float = lerpf(
		REVERSE_DRAG_MIN_FORCE,
		REVERSE_DRAG_MAX_FORCE,
		precision
	)
	_apply_server_reverse_drag_touch(
		ball_target,
		reverse_direction,
		force,
		now,
		REVERSE_DRAG_INITIAL_CONTROL_STRENGTH
	)
	_server_reverse_drag_armed_until = -INF
	_server_reverse_drag_chain_direction = reverse_direction
	_server_reverse_drag_last_touch_at = now
	_server_reverse_drag_chain_until = now + REVERSE_DRAG_CHAIN_WINDOW_SECONDS
	return true


# ================================================================
# SERVER-TIMED CHARGED SHOT
# ================================================================

func _begin_local_charge() -> void:
	if local_is_charging:
		return

	local_is_charging = true
	local_charge_seconds = 0.0
	shot_charge_bar.value = 0.0
	shot_charge_bar.show()
	shot_charge_readout.hide()
	_update_charge_bar()

	if multiplayer.is_server():
		_server_begin_charge()
	else:
		_request_begin_charge.rpc_id(SERVER_PEER_ID)


func _release_local_charge() -> void:
	if not local_is_charging:
		return

	var held_seconds := local_charge_seconds
	local_is_charging = false
	local_charge_seconds = 0.0
	shot_charge_bar.hide()
	shot_charge_readout.hide()
	shot_charge_bar.value = 0.0
	_hide_shot_preview()
	if _should_defer_direct_finish_quick_release():
		# Keep the authoritative charge alive only during the short double-tap
		# window. A second tap replaces it with Volley; otherwise the original
		# tap is committed with its actual held duration when the window expires.
		_local_direct_finish_quick_release_pending = true
		_local_direct_finish_quick_release_seconds = held_seconds
		return

	if multiplayer.is_server():
		_server_release_shot()
	else:
		_request_release_shot.rpc_id(SERVER_PEER_ID)


func _should_defer_direct_finish_quick_release() -> bool:
	if not _local_direct_finish_tap_pending:
		return false
	if not _can_locally_choose_direct_finish():
		return false
	var elapsed := (
		Time.get_ticks_msec() / 1000.0
		- _local_direct_finish_first_tap_at
	)
	return elapsed <= maxf(0.12, direct_finish_double_tap_seconds)


func _commit_pending_direct_finish_quick_shot() -> void:
	if not _local_direct_finish_quick_release_pending:
		return
	var held_seconds := _local_direct_finish_quick_release_seconds
	_local_direct_finish_quick_release_pending = false
	_local_direct_finish_quick_release_seconds = 0.0
	if multiplayer.is_server():
		_server_release_shot(held_seconds)
	else:
		_request_release_shot.rpc_id(SERVER_PEER_ID, held_seconds)


func _cancel_local_charge() -> void:
	local_is_charging = false
	local_charge_seconds = 0.0
	if shot_charge_bar != null:
		shot_charge_bar.hide()
		shot_charge_bar.value = 0.0
	if shot_charge_readout != null:
		shot_charge_readout.hide()
	_hide_shot_preview()


func _update_charge_bar() -> void:
	if shot_charge_bar == null:
		return

	var charge_seconds := _current_maximum_charge_seconds()
	_set_charge_bar_ratio(
		local_charge_seconds / charge_seconds
		if charge_seconds > 0.0
		else 1.0
	)


func _update_replicated_charge(delta: float) -> void:
	if _is_local_player():
		return

	if not replicated_charge_active:
		shot_charge_bar.hide()
		shot_charge_readout.hide()
		shot_charge_bar.value = 0.0
		return

	# Keep the replicated timer advancing for every viewer. The charge bar can
	# stay team/spectator-only, while the subtle full-charge anticipation cue
	# remains readable to opponents as fair competitive telegraphing.
	replicated_charge_seconds = minf(
		replicated_charge_duration,
		replicated_charge_seconds + delta
	)

	if (
		not _is_teammate_of_local_player()
		and not _is_local_viewer_spectator()
	):
		shot_charge_bar.hide()
		shot_charge_readout.hide()
		return
	var ratio := (
		replicated_charge_seconds / replicated_charge_duration
		if replicated_charge_duration > 0.0
		else 1.0
	)
	_set_charge_bar_ratio(ratio)
	shot_charge_bar.show()
	shot_charge_readout.hide()


func _set_charge_bar_ratio(ratio: float) -> void:
	if shot_charge_bar != null:
		var safe_ratio := clampf(ratio, 0.0, 1.0)
		shot_charge_bar.value = safe_ratio
		var zone_color := _get_charge_zone_color(safe_ratio)
		if _charge_fill_style != null:
			_charge_fill_style.bg_color = zone_color
	if shot_charge_readout != null:
		shot_charge_readout.hide()


func _get_charge_zone_name(ratio: float) -> String:
	if ratio < clampf(soft_shot_zone_end, 0.0, 1.0):
		return "SOFT"
	if ratio >= clampf(power_shot_zone_start, 0.0, 1.0):
		return "POWER"
	return "SHOT"


func _get_charge_zone_color(ratio: float) -> Color:
	if ratio < clampf(soft_shot_zone_end, 0.0, 1.0):
		return charge_low_color
	if ratio >= clampf(power_shot_zone_start, 0.0, 1.0):
		return charge_high_color
	return charge_middle_color


func _prepare_shot_bounce_marker() -> void:
	if shot_bounce_marker == null:
		return
	shot_bounce_marker.clear_points()
	var point_count := 28
	for point_index in range(point_count + 1):
		var angle := TAU * float(point_index) / float(point_count)
		shot_bounce_marker.add_point(
			Vector2.from_angle(angle) * 30.0
		)


func _prepare_shot_aim_guide() -> void:
	if shot_aim_guide == null:
		return
	var guide_gradient := Gradient.new()
	guide_gradient.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	guide_gradient.colors = PackedColorArray([
		Color(
			shot_aim_guide_color.r,
			shot_aim_guide_color.g,
			shot_aim_guide_color.b,
			shot_aim_guide_color.a * 0.2
		),
		shot_aim_guide_color,
		Color(
			shot_aim_guide_color.r,
			shot_aim_guide_color.g,
			shot_aim_guide_color.b,
			shot_aim_guide_color.a * 0.2
		)
	])
	shot_aim_guide.gradient = guide_gradient


func _update_local_shot_aim_guide() -> void:
	if shot_aim_guide == null:
		return
	if not controls_enabled or not _local_ball_is_kickable():
		shot_aim_guide.hide()
		return
	_update_shot_aim_guide_geometry()


func _update_spectator_shot_aim_guide() -> void:
	if shot_aim_guide == null or _is_local_player():
		return
	if not _is_local_viewer_spectator():
		shot_aim_guide.hide()
		return
	if (
		not controls_enabled
		or (team != &"red" and team != &"blue")
		or not replicated_charge_active
		or not _local_ball_is_kickable()
	):
		shot_aim_guide.hide()
		return
	_update_shot_aim_guide_geometry()


func _update_shot_aim_guide_geometry() -> void:
	var ball := _get_closest_ball_within_distance(
		maxf(1.0, kick_feedback_detection_distance)
	)
	if ball == null:
		shot_aim_guide.hide()
		return
	var shot_direction := global_position.direction_to(ball.global_position)
	if shot_direction.is_zero_approx():
		shot_direction = server_direction.normalized()
	if shot_direction.is_zero_approx():
		shot_direction = linear_velocity.normalized()
	if shot_direction.is_zero_approx():
		shot_aim_guide.hide()
		return
	if (
		local_ability_active
		and local_active_ability_id == ABILITY_QUICK_TRIGGER
	):
		shot_direction = _get_local_curve_aim_direction(
			shot_direction,
			ball
		)
	var center_angle := shot_direction.angle()
	var half_arc := deg_to_rad(
		clampf(shot_aim_guide_arc_degrees, 8.0, 100.0) * 0.5
	)
	# Keep the aiming arc outside the kick-radius ring. When the ball is near
	# the outer edge, push the arc beyond it so the guide reads as the path
	# continuing behind the ball instead of another kick-range highlight.
	var guide_radius := maxf(
		maxf(20.0, shot_aim_guide_radius),
		global_position.distance_to(ball.global_position)
		+ maxf(20.0, shot_aim_guide_ball_clearance)
	)
	var point_count := maxi(4, shot_aim_guide_point_count)
	shot_aim_guide.clear_points()
	for point_index in range(point_count + 1):
		var ratio := float(point_index) / float(point_count)
		var point_angle := lerpf(
			center_angle - half_arc,
			center_angle + half_arc,
			ratio
		)
		shot_aim_guide.add_point(
			Vector2.from_angle(point_angle) * guide_radius
		)
	shot_aim_guide.show()


func _get_local_curve_aim_direction(
	base_direction: Vector2,
	ball_target: FootballBall
) -> Vector2:
	var safe_base := base_direction.normalized()
	var target_goal := _get_attacking_goal()
	if safe_base.is_zero_approx() or target_goal == null or ball_target == null:
		return safe_base
	var mouth_range := target_goal.get_mouth_y_range()
	var goal_center := Vector2(
		target_goal.get_goal_plane_x(),
		(mouth_range.x + mouth_range.y) * 0.5
	)
	var goal_direction := ball_target.global_position.direction_to(goal_center)
	if goal_direction.is_zero_approx() or safe_base.dot(goal_direction) <= 0.0:
		return safe_base
	var correction := clampf(
		safe_base.angle_to(goal_direction)
		* clampf(curve_shot_goal_assist_strength, 0.0, 1.0),
		-deg_to_rad(maxf(0.0, curve_shot_max_aim_correction_degrees)),
		deg_to_rad(maxf(0.0, curve_shot_max_aim_correction_degrees))
	)
	return safe_base.rotated(correction).normalized()


func _update_local_shot_preview() -> void:
	if (
		shot_direction_preview == null
		or shot_direction_arrow == null
		or shot_bounce_marker == null
	):
		return
	if (
		not local_is_charging
		or not controls_enabled
		or not _local_ball_is_kickable()
		or not local_ability_active
		or local_active_ability_id != ABILITY_META_VISION
	):
		_hide_shot_preview()
		return

	var ball := _get_closest_ball_within_distance(
		maxf(1.0, kick_feedback_detection_distance)
	)
	if ball == null:
		_hide_shot_preview()
		return

	var shot_direction := global_position.direction_to(
		ball.global_position
	)
	if shot_direction.is_zero_approx():
		shot_direction = server_direction.normalized()
	if shot_direction.is_zero_approx():
		_hide_shot_preview()
		return

	var charge_ratio := clampf(
		local_charge_seconds / _current_maximum_charge_seconds(),
		0.0,
		1.0
	)
	var preview_length := lerpf(
		maxf(0.0, shot_preview_minimum_length),
		maxf(
			shot_preview_minimum_length,
			shot_preview_maximum_length
		),
		charge_ratio
	)
	var start_position := ball.global_position
	var cast_position := start_position
	var end_position := start_position
	var remaining_length := preview_length
	var final_direction := shot_direction

	shot_direction_preview.clear_points()
	shot_direction_preview.add_point(to_local(start_position))
	shot_bounce_marker.hide()
	for bounce_index in range(
		maxi(0, shot_preview_maximum_bounces) + 1
	):
		var segment_end := (
			cast_position + final_direction * remaining_length
		)
		var collision := (
			get_world_2d()
			.direct_space_state
			.intersect_ray(
				PhysicsRayQueryParameters2D.create(
					cast_position,
					segment_end,
					shot_preview_wall_collision_mask
				)
			)
		)
		if collision.is_empty():
			end_position = segment_end
			shot_direction_preview.add_point(
				to_local(end_position)
			)
			break

		var hit_position: Vector2 = collision.position
		var hit_normal: Vector2 = (
			collision.normal as Vector2
		).normalized()
		var traveled_length := cast_position.distance_to(
			hit_position
		)
		remaining_length = maxf(
			0.0,
			remaining_length - traveled_length
		)
		end_position = hit_position
		shot_direction_preview.add_point(to_local(hit_position))
		if bounce_index == 0:
			shot_bounce_marker.position = to_local(hit_position)
			shot_bounce_marker.show()
		if (
			bounce_index >= maxi(
				0,
				shot_preview_maximum_bounces
			)
			or remaining_length <= 0.01
			or hit_normal.is_zero_approx()
		):
			break
		final_direction = final_direction.bounce(hit_normal)
		cast_position = (
			hit_position + final_direction * 2.0
		)
		remaining_length = maxf(0.0, remaining_length - 2.0)

	var zone_color := _get_charge_zone_color(charge_ratio)
	var preview_color := Color(
		zone_color.r,
		zone_color.g,
		zone_color.b,
		0.78
	)
	var preview_width := lerpf(8.0, 17.0, charge_ratio)
	shot_direction_preview.default_color = preview_color
	shot_direction_preview.width = preview_width
	shot_bounce_marker.default_color = preview_color
	shot_bounce_marker.width = preview_width * 0.7

	var arrow_tip := to_local(end_position)
	var arrow_back := arrow_tip - final_direction * 70.0
	var arrow_side := final_direction.orthogonal() * 34.0
	shot_direction_arrow.clear_points()
	shot_direction_arrow.add_point(arrow_back + arrow_side)
	shot_direction_arrow.add_point(arrow_tip)
	shot_direction_arrow.add_point(arrow_back - arrow_side)
	shot_direction_arrow.default_color = preview_color
	shot_direction_arrow.width = preview_width
	shot_direction_preview.show()
	shot_direction_arrow.show()


func _hide_shot_preview() -> void:
	if shot_direction_preview != null:
		shot_direction_preview.hide()
	if shot_direction_arrow != null:
		shot_direction_arrow.hide()
	if shot_bounce_marker != null:
		shot_bounce_marker.hide()


func _prepare_kick_range_indicator() -> void:
	if kick_range_indicator == null:
		return
	kick_range_indicator.clear_points()
	var point_count := 64
	var radius := 190.0
	for point_index in range(point_count + 1):
		var angle := (
			TAU * float(point_index) / float(point_count)
		)
		kick_range_indicator.add_point(
			Vector2.from_angle(angle) * radius
		)
	kick_range_indicator.visible = false


func _update_local_kick_feedback(delta: float) -> void:
	if kick_range_indicator == null:
		return

	var should_show := controls_enabled and team != &""
	kick_range_indicator.visible = should_show
	if not should_show:
		_ball_was_kickable = false
		return

	_kick_result_flash_remaining = maxf(
		0.0,
		_kick_result_flash_remaining - delta
	)
	var ball_is_kickable := _local_ball_is_kickable()
	var color := (
		kick_range_ready_color
		if ball_is_kickable
		else kick_range_idle_color
	)
	var width := 13.0 if ball_is_kickable else 6.0
	if _kick_result_flash_remaining > 0.0:
		color = (
			kick_confirmed_color
			if _kick_result_success
			else kick_range_miss_color
		)
		width = 18.0
	kick_range_indicator.default_color = color
	kick_range_indicator.width = width

	if ball_is_kickable and not _ball_was_kickable:
		_pulse_kick_range_indicator()
	_ball_was_kickable = ball_is_kickable


func _local_ball_is_kickable() -> bool:
	for ball_node in get_tree().get_nodes_in_group(
		"football_balls"
	):
		var ball := ball_node as FootballBall
		if (
			ball != null
			and global_position.distance_to(
				ball.global_position
			)
			<= maxf(1.0, kick_feedback_detection_distance)
		):
			return true
	return false


func _pulse_kick_range_indicator() -> void:
	kick_range_indicator.scale = Vector2(0.88, 0.88)
	var tween := create_tween()
	tween.tween_property(
		kick_range_indicator,
		"scale",
		Vector2.ONE,
		0.16
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _is_teammate_of_local_player() -> bool:
	if team == &"" or get_parent() == null:
		return false

	var local_player := get_parent().get_node_or_null(
		str(multiplayer.get_unique_id())
	) as FootballPlayer
	return (
		local_player != null
		and local_player != self
		and local_player.team == team
	)


func _is_local_viewer_spectator() -> bool:
	if get_parent() == null:
		return false
	var local_peer_id := multiplayer.get_unique_id()
	var local_player := get_parent().get_node_or_null(
		str(local_peer_id)
	) as FootballPlayer
	if local_player != null:
		return local_player.team == &"spectator"
	for sibling in get_parent().get_children():
		var candidate := sibling as FootballPlayer
		if (
			candidate != null
			and candidate.owner_peer_id == local_peer_id
			and not candidate.cpu_controlled
		):
			return candidate.team == &"spectator"
	return false


@rpc("any_peer", "call_remote", "reliable")
func _request_begin_charge() -> void:
	if (
		not multiplayer.is_server()
		or multiplayer.get_remote_sender_id() != owner_peer_id
	):
		return

	_server_begin_charge()


@rpc("any_peer", "call_remote", "reliable")
func _request_release_shot(
	deferred_held_seconds: float = -1.0
) -> void:
	if (
		not multiplayer.is_server()
		or multiplayer.get_remote_sender_id() != owner_peer_id
	):
		return

	_server_release_shot(deferred_held_seconds)


func _server_begin_charge() -> void:
	if (
		not multiplayer.is_server()
		or not controls_enabled
		or server_is_charging
	):
		return

	var now := _server_time_seconds()
	if now < next_shot_allowed_at:
		return

	server_haaland_predator_charge_armed = _haaland_predator_is_active(now)
	server_is_charging = true
	server_charge_started_at = now
	_receive_charge_started.rpc(
		_current_maximum_charge_seconds(),
		0.0
	)


func _server_release_shot(
	deferred_held_seconds: float = -1.0
) -> void:
	if not multiplayer.is_server() or not server_is_charging:
		return

	server_is_charging = false
	_receive_charge_stopped.rpc()

	var now := _server_time_seconds()
	var consumed_haaland_predator := server_haaland_predator_charge_armed
	var charge_seconds := _current_maximum_charge_seconds()
	var held_seconds := clampf(
		(
			deferred_held_seconds
			if (
				deferred_held_seconds >= 0.0
				and selected_ability == ABILITY_DIRECT_FINISH
			)
			else now - server_charge_started_at
		),
		0.0,
		charge_seconds
	)
	var charge_ratio := (
		held_seconds / charge_seconds
		if charge_seconds > 0.0
		else 1.0
	)
	if draft_perk_id == 50 and _server_ability_is_active(ABILITY_POWER_STRIKE):
		charge_ratio = 1.0
	var shot_force := lerpf(
		minimum_shot_force,
		maximum_shot_force,
		charge_ratio
	)
	shot_force *= (
		draft_perk_shot_force_multiplier
		* _get_draft_perk_action_shot_multiplier(now)
	)
	var pulse_type: int = ACTION_PULSE_SHOT
	if _server_ability_is_active(ABILITY_POWER_STRIKE):
		pulse_type = ACTION_PULSE_POWER_STRIKE
	elif charge_ratio >= 0.92:
		pulse_type = ACTION_PULSE_FULL_SHOT
	_receive_player_action_pulse.rpc(
		pulse_type,
		lerpf(0.62, 1.0, charge_ratio),
		ABILITY_POWER_STRIKE
		if pulse_type == ACTION_PULSE_POWER_STRIKE
		else ABILITY_NONE
	)
	server_last_kick_charge_seconds = held_seconds
	server_last_kick_was_soft_pass = false
	server_last_kick_time = now
	if _server_ability_is_active(ABILITY_POWER_STRIKE):
		shot_force *= maxf(
			0.0,
			lerpf(
				1.0,
				power_strike_force_multiplier,
				server_ability_strength_scale
			)
		)

	next_shot_allowed_at = now + maxf(0.0, shot_buffer_seconds)
	var shot_connected: bool = false
	if _server_ability_is_active(ABILITY_SIDE_SWIPE):
		shot_connected = _server_execute_side_swipe_kick(
			shot_force,
			false,
			now
		)
	else:
		shot_connected = _hit_ball(shot_force)
	if shot_connected:
		_consume_draft_perk_action_shot()
		trigger_draft_perk(&"shot_connected")
	if consumed_haaland_predator:
		server_haaland_predator_until = 0.0
	server_haaland_predator_charge_armed = false
	server_next_kick_is_pass = false
	if not cpu_controlled:
		if owner_peer_id == multiplayer.get_unique_id():
			_receive_shot_result(shot_connected)
		else:
			_receive_shot_result.rpc_id(
				owner_peer_id,
				shot_connected
			)


func cpu_begin_shot_charge() -> void:
	if cpu_controlled and multiplayer.is_server():
		_server_begin_charge()


func cpu_get_maximum_shot_charge_seconds() -> float:
	return _current_maximum_charge_seconds()


func cpu_has_kickable_ball() -> bool:
	if not cpu_controlled or not multiplayer.is_server():
		return false
	return _get_closest_ball_in_kick_area() != null


func cpu_release_shot() -> void:
	if cpu_controlled and multiplayer.is_server():
		_server_release_shot()


func cpu_cancel_shot_charge() -> void:
	if (
		not cpu_controlled
		or not multiplayer.is_server()
		or not server_is_charging
	):
		return
	server_is_charging = false
	server_next_kick_is_pass = false
	_receive_charge_stopped.rpc()


func cpu_activate_selected_ability() -> bool:
	if not cpu_controlled or not multiplayer.is_server():
		return false
	if (
		server_is_charging
		and selected_ability in [
			ABILITY_HEEL_TURN,
			ABILITY_TIME_SKIP_PASS,
			ABILITY_IRON_ANCHOR,
			ABILITY_BLIND_SPOT,
			ABILITY_BOOGIE_WOOGIE,
			ABILITY_ECHO,
			ABILITY_RETURN_TAG,
			ABILITY_SIDE_SWIPE
		]
	):
		cpu_cancel_shot_charge()
	return _server_activate_ability()


func cpu_get_time_skip_pass_maximum_travel_distance(
	strength_scale: float = 1.0
) -> float:
	# Dead Zone spends a capped fast phase at the launch speed, then instantly
	# drops to its slow phase and brakes to the configured stop speed. This is
	# the real physical ceiling of the ability, which can be lower than the
	# designer-facing receiver search radius.
	var initial_speed := (
		maxf(1.0, time_skip_pass_initial_speed)
		* clampf(strength_scale, 0.1, 1.0)
	)
	var fast_distance := (
		initial_speed
		* maxf(0.02, time_skip_pass_maximum_fast_duration)
	)
	var slow_speed := maxf(0.0, time_skip_pass_slow_speed)
	var stop_speed := clampf(
		time_skip_pass_stop_speed,
		0.0,
		slow_speed
	)
	var deceleration := maxf(0.001, time_skip_pass_stopping_deceleration)
	var slow_distance := maxf(
		0.0,
		(slow_speed * slow_speed - stop_speed * stop_speed)
		/ (2.0 * deceleration)
	)
	return fast_distance + slow_distance


func cpu_set_time_skip_pass_route(
	receiver_peer_id: int,
	target_position: Vector2
) -> void:
	_cpu_time_skip_pass_receiver_peer_id = max(0, receiver_peer_id)
	_cpu_time_skip_pass_target = target_position


func cpu_clear_time_skip_pass_route() -> void:
	_cpu_time_skip_pass_receiver_peer_id = 0
	_cpu_time_skip_pass_target = Vector2.ZERO


func cpu_set_next_kick_is_pass(is_pass: bool) -> void:
	if not cpu_controlled or not multiplayer.is_server():
		return
	server_next_kick_is_pass = is_pass


func cpu_try_return_tag_pass() -> bool:
	if (
		not cpu_controlled
		or not multiplayer.is_server()
		or not controls_enabled
		or server_is_charging
	):
		return false
	var tagged_ball := _get_closest_ball_in_kick_area()
	if tagged_ball == null:
		return false
	return _server_execute_return_tag_pass(tagged_ball)


func cpu_arm_trap_or_volley(
	volley_requested: bool,
	aim_direction: Vector2
) -> bool:
	if (
		not cpu_controlled
		or not multiplayer.is_server()
		or selected_ability != ABILITY_DIRECT_FINISH
		or server_ability_timers_paused
	):
		return false
	var choice_changed := (
		server_direct_finish_volley_requested != volley_requested
	)
	server_direct_finish_volley_requested = volley_requested
	server_direct_finish_aim_direction = aim_direction.normalized()
	if _server_ability_is_active(ABILITY_DIRECT_FINISH):
		if choice_changed:
			_receive_direct_finish_choice.rpc(volley_requested)
		return true
	var activated := _server_activate_ability()
	if not activated:
		server_direct_finish_volley_requested = false
		server_direct_finish_aim_direction = Vector2.ZERO
	return activated


func _server_redline_eject() -> bool:
	if (
		not multiplayer.is_server()
		or not _server_ability_is_active(ABILITY_OVERDRIVE)
	):
		return false
	var direction := server_direction.normalized()
	if direction.is_zero_approx():
		direction = linear_velocity.normalized()
	if direction.is_zero_approx():
		direction = _get_breakaway_attack_direction()
	if direction.is_zero_approx():
		direction = Vector2.RIGHT
	linear_velocity = (
		linear_velocity * 0.35
		+ direction * maxf(1150.0, linear_velocity.length())
	)
	_consume_armed_ability(ABILITY_OVERDRIVE)
	return true


func _server_cancel_goalkeeper_reach() -> bool:
	if (
		not multiplayer.is_server()
		or not _server_ability_is_active(ABILITY_GOALKEEPER_REACH)
	):
		return false
	linear_velocity *= 0.12
	_set_ball_body_collision_enabled(true)
	_goalkeeper_blocked_balls.clear()
	_consume_armed_ability(ABILITY_GOALKEEPER_REACH)
	return true


func _server_enforcer_quick_kick(force_ratio: float = 0.78) -> bool:
	if (
		not multiplayer.is_server()
		or not controls_enabled
		or server_is_charging
		or not _server_ability_is_active(ABILITY_ENFORCER)
	):
		return false
	var now := _server_time_seconds()
	if now < next_shot_allowed_at:
		return false
	var target: FootballPlayer
	var closest_distance := INF
	for body in kick_area.get_overlapping_bodies():
		var candidate := body as FootballPlayer
		if (
			candidate == null
			or candidate == self
			or candidate.team == team
		):
			continue
		var distance := global_position.distance_squared_to(
			candidate.global_position
		)
		if distance < closest_distance:
			closest_distance = distance
			target = candidate
	if target == null:
		return false
	var kick_direction := global_position.direction_to(target.global_position)
	if kick_direction.is_zero_approx():
		kick_direction = server_direction.normalized()
	if kick_direction.is_zero_approx():
		kick_direction = Vector2.RIGHT
	var force := lerpf(
		minimum_shot_force,
		maximum_shot_force,
		clampf(force_ratio, 0.0, 1.0)
	)
	target.apply_central_impulse(
		kick_direction
		* force
		* maxf(
			0.0,
			enforcer_player_kick_force_multiplier
				* server_ability_strength_scale
		)
	)
	next_shot_allowed_at = now + maxf(0.0, shot_buffer_seconds)
	_receive_enforcer_kick_sound.rpc(target.global_position)
	return true


func cpu_enforcer_kick(force_ratio: float = 0.72) -> bool:
	if (
		not cpu_controlled
		or not multiplayer.is_server()
		or not controls_enabled
		or server_is_charging
		or not _server_ability_is_active(ABILITY_ENFORCER)
	):
		return false
	var now := _server_time_seconds()
	if now < next_shot_allowed_at:
		return false
	var target: FootballPlayer
	var closest_distance := INF
	for body in kick_area.get_overlapping_bodies():
		var candidate := body as FootballPlayer
		if (
			candidate == null
			or candidate == self
			or candidate.team == team
		):
			continue
		var distance := global_position.distance_squared_to(
			candidate.global_position
		)
		if distance < closest_distance:
			closest_distance = distance
			target = candidate
	if target == null:
		return false
	var kick_direction := global_position.direction_to(target.global_position)
	if kick_direction.is_zero_approx():
		kick_direction = server_direction.normalized()
	if kick_direction.is_zero_approx():
		kick_direction = Vector2.RIGHT
	var force := lerpf(
		minimum_shot_force,
		maximum_shot_force,
		clampf(force_ratio, 0.0, 1.0)
	)
	target.apply_central_impulse(
		kick_direction
		* force
		* maxf(
			0.0,
			enforcer_player_kick_force_multiplier
			* server_ability_strength_scale
		)
	)
	next_shot_allowed_at = now + maxf(0.0, shot_buffer_seconds)
	_receive_enforcer_kick_sound.rpc(target.global_position)
	return true


func cpu_dribble_touch(
	direction: Vector2,
	force: float
) -> bool:
	if (
		not cpu_controlled
		or not multiplayer.is_server()
		or not controls_enabled
		or server_is_charging
	):
		return false
	var now := _server_time_seconds()
	if now < next_shot_allowed_at:
		return false
	var dribble_direction := direction.normalized()
	if dribble_direction.is_zero_approx():
		return false
	var ball_target := _get_closest_ball_in_kick_area()
	if ball_target == null:
		return false
	var impulse := dribble_direction * maxf(0.0, force)
	impulse = _sanitize_cpu_ball_impulse(
		ball_target,
		impulse,
		&"dribble_touch"
	)
	if impulse.is_zero_approx():
		return false
	ball_target.register_kick(
		owner_peer_id,
		display_name,
		team,
		impulse
	)
	ball_target.apply_central_impulse(impulse)
	next_shot_allowed_at = now + maxf(0.0, shot_buffer_seconds)
	_receive_shot_sound.rpc(force)
	return true


func cpu_execute_first_touch(
	touch_mode: StringName,
	direction: Vector2,
	target_speed: float,
	control_strength: float = 1.0,
	_target_peer_id: int = 0
) -> bool:
	if (
		not cpu_controlled
		or not multiplayer.is_server()
		or not controls_enabled
		or server_is_charging
	):
		return false
	if touch_mode not in [
		&"soft",
		&"directional",
		&"one_touch_pass",
		&"first_time_shot"
	]:
		return false
	var now := _server_time_seconds()
	if now < next_shot_allowed_at:
		return false
	var touch_direction := direction.normalized()
	if touch_direction.is_zero_approx():
		return false
	var ball_target := _get_closest_ball_in_kick_area()
	if ball_target == null:
		return false
	var safe_mass := maxf(0.001, ball_target.mass)
	var incoming_velocity := ball_target.linear_velocity
	var desired_velocity := (
		touch_direction * maxf(0.0, target_speed)
	)
	var committed_kick := touch_mode in [
		&"one_touch_pass",
		&"first_time_shot"
	]
	if not committed_kick:
		desired_velocity = incoming_velocity.lerp(
			desired_velocity,
			clampf(control_strength, 0.0, 1.0)
		)
	var impulse := (
		desired_velocity - incoming_velocity
	) * safe_mass
	impulse = _sanitize_cpu_ball_impulse(
		ball_target,
		impulse,
		&"first_touch"
	)
	if impulse.is_zero_approx():
		return false
	var outgoing_velocity := (
		incoming_velocity + impulse / safe_mass
	)
	server_last_kick_charge_seconds = 0.0
	server_last_kick_was_soft_pass = (
		touch_mode == &"one_touch_pass"
	)
	server_next_kick_is_pass = false
	if committed_kick:
		ball_target.register_kick(
			owner_peer_id,
			display_name,
			team,
			impulse
		)
	else:
		ball_target.register_touch(
			owner_peer_id,
			display_name,
			team,
			incoming_velocity,
			(
				&"first_touch_soft"
				if touch_mode == &"soft"
				else &"first_touch_directional"
			),
			outgoing_velocity
		)
		play_ball_contact_visual(
			impulse.length(),
			touch_direction
		)
	ball_target.apply_central_impulse(impulse)
	var first_touch_lockout := (
		maxf(0.0, shot_buffer_seconds)
		if committed_kick
		else minf(
			0.16,
			maxf(0.06, shot_buffer_seconds * 0.5)
		)
	)
	next_shot_allowed_at = now + first_touch_lockout
	_receive_shot_sound.rpc(
		maxf(120.0, impulse.length())
	)
	return true


@rpc("authority", "call_local", "reliable")
func _receive_shot_result(shot_connected: bool) -> void:
	if not _is_local_player():
		return
	_kick_result_success = shot_connected
	_kick_result_flash_remaining = 0.24
	if kick_range_indicator != null:
		_pulse_kick_range_indicator()


func sync_charge_to_peer(peer_id: int) -> void:
	if not multiplayer.is_server() or peer_id <= 0:
		return

	if not server_is_charging:
		_receive_charge_stopped.rpc_id(peer_id)
		return

	var duration := _current_maximum_charge_seconds()
	var elapsed := clampf(
		_server_time_seconds() - server_charge_started_at,
		0.0,
		duration
	)
	_receive_charge_started.rpc_id(
		peer_id,
		duration,
		elapsed
	)


@rpc("authority", "call_local", "reliable")
func _receive_charge_started(
	charge_duration: float,
	elapsed_seconds: float
) -> void:
	replicated_charge_active = true
	replicated_charge_duration = maxf(0.01, charge_duration)
	replicated_charge_seconds = clampf(
		elapsed_seconds,
		0.0,
		replicated_charge_duration
	)


@rpc("authority", "call_local", "reliable")
func _receive_charge_stopped() -> void:
	replicated_charge_active = false
	replicated_charge_seconds = 0.0
	if not _is_local_player() and shot_charge_bar != null:
		shot_charge_bar.hide()
		shot_charge_bar.value = 0.0
		if shot_charge_readout != null:
			shot_charge_readout.hide()


func _server_time_seconds() -> float:
	# Use a monotonic simulated-physics clock. Multiplying wall time by the
	# current time scale makes this clock jump backwards when training changes
	# from accelerated play to a 1x benchmark, leaving cooldown deadlines far
	# in the future. The project setting remains the base tick rate while the
	# trainer raises the runtime tick rate proportionally to time_scale.
	var base_physics_ticks := maxf(
		1.0,
		float(ProjectSettings.get_setting(
			"physics/common/physics_ticks_per_second",
			60
		))
	)
	return float(Engine.get_physics_frames()) / base_physics_ticks


func _current_maximum_charge_seconds() -> float:
	var multiplier := draft_perk_charge_time_multiplier
	if (
		is_haaland_boss()
		and (
			server_haaland_predator_charge_armed
			or _haaland_predator_is_active(_server_time_seconds())
		)
	):
		multiplier *= clampf(
			haaland_predator_charge_time_multiplier,
			0.25,
			1.0
		)
	return maxf(
		0.01,
		maximum_charge_seconds * multiplier
	)


func activate_haaland_predator_finish(duration: float = -1.0) -> void:
	if not multiplayer.is_server() or not is_haaland_boss():
		return
	var active_duration := (
		haaland_predator_duration if duration < 0.0 else duration
	)
	server_haaland_predator_until = maxf(
		server_haaland_predator_until,
		_server_time_seconds() + maxf(0.0, active_duration)
	)


func _haaland_predator_is_active(now: float = -1.0) -> bool:
	if not is_haaland_boss():
		return false
	if now < 0.0:
		now = _server_time_seconds()
	return now <= server_haaland_predator_until


func get_haaland_intrinsic_perk_name() -> String:
	return "Relentless Nine" if is_haaland_boss() else ""


func _hit_ball(
	force: float,
	use_shot_abilities: bool = true,
	allow_player_kick: bool = true
) -> bool:
	var ball_target: FootballBall = null
	var player_target: FootballPlayer = null
	var closest_player_distance := INF

	for body in kick_area.get_overlapping_bodies():
		var ball := body as FootballBall
		if ball != null:
			ball_target = ball
			continue

		if (
			not allow_player_kick
			or not _server_ability_is_active(ABILITY_ENFORCER)
		):
			continue

		var target_player := body as FootballPlayer
		if (
			target_player == null
			or target_player == self
			or target_player.team == team
		):
			continue

		var distance := global_position.distance_squared_to(
			target_player.global_position
		)
		if distance < closest_player_distance:
			closest_player_distance = distance
			player_target = target_player

	var kicked_player := false
	if player_target != null:
		var player_direction := global_position.direction_to(
			player_target.global_position
		)
		if player_direction.is_zero_approx():
			player_direction = server_direction.normalized()
		if player_direction.is_zero_approx():
			player_direction = Vector2.RIGHT

		player_target.apply_central_impulse(
			player_direction
			* maxf(0.0, force)
			* maxf(
				0.0,
				enforcer_player_kick_force_multiplier
				* server_ability_strength_scale
			)
		)
		_receive_enforcer_kick_sound.rpc(player_target.global_position)
		kicked_player = true

	if ball_target != null:
		var ball_direction := global_position.direction_to(
			ball_target.global_position
		)
		var is_curve_shot := (
			use_shot_abilities
			and _server_ability_is_active(ABILITY_QUICK_TRIGGER)
		)
		var is_power_strike := (
			use_shot_abilities
			and _server_ability_is_active(ABILITY_POWER_STRIKE)
		)
		var is_draft_curve_pass := (
			server_next_kick_is_pass
			and draft_perk_id == 4
			and _server_time_seconds() <= draft_perk_curve_pass_until
		)
		var applied_force := maxf(0.0, force)
		if is_curve_shot:
			ball_direction = (
				_get_curve_assisted_kick_direction(
					ball_direction,
					ball_target
				)
			)
			applied_force *= maxf(
				1.0,
				lerpf(
					1.0,
					curve_shot_force_multiplier,
					server_ability_strength_scale
				)
			)
		var kick_impulse := (
			ball_direction * applied_force
		)
		var original_kick_impulse: Vector2 = kick_impulse
		kick_impulse = _sanitize_cpu_ball_impulse(
			ball_target,
			kick_impulse,
			&"charged_shot"
		)
		if kick_impulse.is_zero_approx():
			return kicked_player
		var nutmeg_target: FootballPlayer = null
		if _server_ability_is_active(ABILITY_NUTMEG):
			nutmeg_target = _find_nutmeg_target(
				ball_target,
				kick_impulse.normalized()
			)
			if nutmeg_target != null:
				_begin_nutmeg_collision_window(
					ball_target,
					nutmeg_target,
					kick_impulse.length(),
					kick_impulse.normalized()
				)
		if (
			cpu_controlled
			and is_curve_shot
			and kick_impulse.distance_squared_to(
				original_kick_impulse
			) > 0.01
		):
			is_curve_shot = false
		ball_target.register_kick(
			owner_peer_id,
			display_name,
			team,
			kick_impulse,
			is_power_strike
		)
		ball_target.apply_central_impulse(
			kick_impulse
		)
		if nutmeg_target != null:
			_consume_armed_ability(ABILITY_NUTMEG)
		if _server_ability_is_active(ABILITY_SNAPBACK) and not is_power_strike:
			_server_arm_snapback_ball(ball_target)
		# Return Tag marks the next normal kick regardless of whether it was
		# released through Pass or Shoot.
		if _server_ability_is_active(ABILITY_RETURN_TAG) and not is_power_strike:
			ball_target.arm_return_tag(
				owner_peer_id,
				display_name,
				team,
				return_tag_mark_duration
				* server_ability_strength_scale
			)
			_consume_return_tag_arming()
		if is_curve_shot:
			var turn_direction := _get_curve_turn_direction(
				ball_target,
				ball_direction
			)
			var blocker := _get_curve_shot_blocker(
				ball_target,
				ball_direction
			)
			var obstacle_position := Vector2.ZERO
			var obstacle_side := 0.0
			var obstacle_clearance := 0.0
			var obstacle_pass_margin := 0.0
			var steering_speed := (
				curve_shot_steering_radians_per_second
				* server_ability_strength_scale
			)
			var curve_duration := curve_shot_ball_duration
			if draft_perk_id == 49:
				steering_speed *= 1.85
				curve_duration += 0.45
			if not blocker.is_empty():
				obstacle_position = blocker.get(
					"position",
					Vector2.ZERO
				)
				obstacle_side = float(
					blocker.get("side", 0.0)
				)
				obstacle_clearance = (
					curve_shot_blocker_avoidance_clearance
					* (1.25 if draft_perk_id == 49 else 1.0)
				)
				obstacle_pass_margin = (
					curve_shot_blocker_pass_margin
				)
				steering_speed *= clampf(
					curve_shot_blocker_steering_multiplier,
					0.1,
					1.0
				)
			ball_target.start_curve_shot(
				turn_direction,
				curve_duration,
				steering_speed,
				curve_shot_minimum_ball_speed,
				obstacle_position,
				ball_direction,
				obstacle_side,
				obstacle_clearance,
				obstacle_pass_margin
			)
			_receive_curve_shot_sound.rpc()
		elif is_draft_curve_pass:
			# Bend It Forward borrows the synchronized curve-ball system, but the
			# effect is armed by an ability and consumed by a pass rather than a shot.
			ball_target.start_curve_shot(
				_get_curve_turn_direction(ball_target, ball_direction),
				1.15,
				maxf(0.75, curve_shot_steering_radians_per_second * 1.35),
				200.0,
				Vector2.ZERO,
				ball_direction
			)
			draft_perk_curve_pass_until = 0.0
		if is_power_strike:
			ball_target.ignite_power_strike(is_haaland_boss())
		_receive_shot_sound.rpc(applied_force, is_power_strike)
		return true

	if kicked_player:
		return true

	return false


func _server_try_instant_nutmeg() -> bool:
	if not multiplayer.is_server() or not _server_ability_is_active(ABILITY_NUTMEG):
		return false
	var ball := _get_closest_ball_in_kick_area()
	if ball == null:
		return false
	var aim_direction := server_direction.normalized()
	if aim_direction.is_zero_approx():
		aim_direction = global_position.direction_to(ball.global_position)
	if aim_direction.is_zero_approx():
		return false
	if _find_nutmeg_target(ball, aim_direction) == null:
		return false
	var auto_force := clampf(
		maximum_shot_force * 0.46,
		minimum_shot_force,
		maximum_shot_force
	)
	return _hit_ball(auto_force, false, false)


func _find_nutmeg_target(
	ball_target: FootballBall,
	kick_direction: Vector2
) -> FootballPlayer:
	if ball_target == null or kick_direction.is_zero_approx():
		return null
	var best_target: FootballPlayer = null
	var best_forward_distance: float = INF
	var direction: Vector2 = kick_direction.normalized()
	var maximum_distance: float = maxf(100.0, nutmeg_probe_distance)
	var lane_width: float = maxf(20.0, nutmeg_lane_half_width)
	var players_parent: Node = get_parent()
	if players_parent == null:
		return null
	for child: Node in players_parent.get_children():
		var opponent := child as FootballPlayer
		if opponent == null or opponent == self or opponent.team == team:
			continue
		var offset: Vector2 = opponent.global_position - ball_target.global_position
		var forward_distance: float = offset.dot(direction)
		if forward_distance <= 0.0 or forward_distance > maximum_distance:
			continue
		var lateral_distance: float = absf(offset.cross(direction))
		if lateral_distance > lane_width:
			continue
		if forward_distance < best_forward_distance:
			best_forward_distance = forward_distance
			best_target = opponent
	return best_target


func _begin_nutmeg_collision_window(
	ball_target: FootballBall,
	opponent: FootballPlayer,
	kick_speed: float,
	kick_direction: Vector2 = Vector2.ZERO
) -> void:
	if ball_target == null or opponent == null:
		return
	ball_target.add_collision_exception_with(opponent)
	var travel_distance: float = ball_target.global_position.distance_to(
		opponent.global_position
	) + maxf(20.0, nutmeg_collision_clearance)
	var ignore_seconds: float = clampf(
		travel_distance / maxf(1.0, kick_speed),
		0.08,
		maxf(0.08, nutmeg_maximum_ignore_seconds)
	)
	# The physics exception alone does not affect Area2D kick detection. Mark
	# the same short window so a CPU being nutmegged cannot clear the ball while
	# it is explicitly passing through that CPU's body.
	ball_target.begin_nutmeg_bypass(opponent, ignore_seconds)
	var exit_direction: Vector2 = kick_direction.normalized()
	if exit_direction.is_zero_approx():
		exit_direction = global_position.direction_to(opponent.global_position)
	_start_nutmeg_chase(exit_direction, nutmeg_exit_impulse)
	_remove_nutmeg_collision_exception_after(
		ball_target,
		opponent,
		ignore_seconds
	)


func _remove_nutmeg_collision_exception_after(
	ball_target: FootballBall,
	opponent: FootballPlayer,
	delay_seconds: float
) -> void:
	await get_tree().create_timer(maxf(0.01, delay_seconds)).timeout
	if is_instance_valid(ball_target) and is_instance_valid(opponent):
		ball_target.remove_collision_exception_with(opponent)


func play_ball_contact_visual(
	force: float,
	direction: Vector2
) -> void:
	if not multiplayer.is_server():
		return
	_receive_ball_contact_visual.rpc(force, direction)


@rpc("authority", "call_local", "unreliable")
func _receive_ball_contact_visual(
	force: float,
	direction: Vector2
) -> void:
	var safe_maximum := maxf(1.0, maximum_shot_force)
	var strength := clampf(force / safe_maximum, 0.18, 1.0)
	_ball_contact_flash_remaining = maxf(
		0.08,
		ball_contact_flash_seconds
	)
	_ball_contact_flash_strength = strength
	_ball_contact_flash_color = _get_badge_team_color()
	_play_portrait_contact_squash(direction, strength)
	queue_redraw()


func _update_ball_contact_visual(delta: float) -> void:
	if _ball_contact_flash_remaining <= 0.0:
		return
	_ball_contact_flash_remaining = maxf(
		0.0,
		_ball_contact_flash_remaining - delta
	)
	queue_redraw()


func _play_portrait_contact_squash(
	direction: Vector2,
	strength: float
) -> void:
	if ability_portrait == null or not ability_portrait.visible:
		return
	if _portrait_impact_tween != null:
		_portrait_impact_tween.kill()

	var amount := (
		clampf(ball_contact_squash_amount, 0.0, 0.5)
		* clampf(strength, 0.18, 1.0)
	)
	var portrait_scale := _get_ability_portrait_presentation_scale()
	ability_portrait.pivot_offset = ability_portrait.size * 0.5
	ability_portrait.rotation = 0.0
	ability_portrait.scale = portrait_scale * Vector2(
		1.0 - amount,
		1.0 + amount * 0.72
	)
	ability_portrait.modulate = _ball_contact_flash_color.lightened(0.42)

	_portrait_impact_tween = create_tween()
	_portrait_impact_tween.tween_property(
		ability_portrait,
		"scale",
		portrait_scale * Vector2(
			1.0 + amount * 0.82,
			1.0 - amount * 0.52
		),
		0.045
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_portrait_impact_tween.parallel().tween_property(
		ability_portrait,
		"modulate",
		Color.WHITE,
		0.11
	)
	_portrait_impact_tween.tween_property(
		ability_portrait,
		"scale",
		portrait_scale,
		0.13
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_portrait_impact_tween.parallel().tween_property(
		ability_portrait,
		"rotation",
		0.0,
		0.13
	)


@rpc("authority", "call_local", "reliable")
func _receive_curve_shot_sound() -> void:
	if curve_shot_audio == null or CURVE_SHOT_SOUND == null:
		return
	curve_shot_audio.stop()
	curve_shot_audio.stream = CURVE_SHOT_SOUND
	curve_shot_audio.volume_db = -5.0
	curve_shot_audio.pitch_scale = 1.0
	curve_shot_audio.play()


@rpc("authority", "call_local", "reliable")
func _receive_direct_finish_volley_sound() -> void:
	if curve_shot_audio == null or CURVE_SHOT_SOUND == null:
		return
	curve_shot_audio.stop()
	curve_shot_audio.stream = CURVE_SHOT_SOUND
	curve_shot_audio.volume_db = -5.5
	curve_shot_audio.pitch_scale = 1.05
	curve_shot_audio.play()


@rpc("authority", "call_local", "reliable")
func _receive_dead_zone_pass_sound() -> void:
	if dead_zone_pass_audio == null or DEAD_ZONE_PASS_SOUND == null:
		return
	dead_zone_pass_audio.stop()
	dead_zone_pass_audio.stream = DEAD_ZONE_PASS_SOUND
	dead_zone_pass_audio.volume_db = -7.0
	dead_zone_pass_audio.pitch_scale = 1.0
	dead_zone_pass_audio.play()


@rpc("authority", "call_local", "reliable")
func _receive_reflex_block_sound() -> void:
	if reflex_block_audio == null or REFLEX_BLOCK_SOUND == null:
		return
	reflex_block_audio.stop()
	reflex_block_audio.stream = REFLEX_BLOCK_SOUND
	reflex_block_audio.volume_db = -4.0
	reflex_block_audio.pitch_scale = 1.0
	reflex_block_audio.play()


@rpc("authority", "call_local", "reliable")
func _receive_enforcer_kick_sound(position: Vector2) -> void:
	_play_world_ability_one_shot(
		ENFORCER_SOUND,
		position,
		ability_sound_volume_db,
		0.93
	)


@rpc("authority", "call_local", "reliable")
func _receive_shot_sound(
	force: float,
	power_strike_active: bool = false
) -> void:
	if power_strike_active and power_strike_shot_sound != null:
		_play_impact_body_layer(force)
		shot_audio.stop()
		shot_audio.stream = power_strike_shot_sound
		shot_audio.volume_db = power_strike_shot_volume_db
		shot_audio.pitch_scale = 1.0
		shot_audio.play()
		return

	var selected_tier: ShotSoundTier = null
	var selected_minimum := -INF

	for tier in shot_sound_tiers:
		if tier == null or tier.sound == null:
			continue

		if (
			force >= tier.minimum_force
			and tier.minimum_force >= selected_minimum
		):
			selected_tier = tier
			selected_minimum = tier.minimum_force

	if selected_tier == null:
		return

	shot_audio.stop()
	shot_audio.stream = selected_tier.sound
	shot_audio.volume_db = selected_tier.volume_db
	shot_audio.pitch_scale = selected_tier.pitch_scale
	shot_audio.play()


func _play_impact_body_layer(force: float) -> void:
	if impact_body_audio == null or BALL_IMPACT_BODY_SOUND == null:
		return
	var minimum_force := maxf(0.0, minimum_shot_force)
	var maximum_force := maxf(minimum_force + 1.0, maximum_shot_force)
	var strength := clampf(
		(force - minimum_force) / (maximum_force - minimum_force),
		0.0,
		1.0
	)
	impact_body_audio.stop()
	impact_body_audio.stream = BALL_IMPACT_BODY_SOUND
	impact_body_audio.volume_db = lerpf(
		impact_body_minimum_volume_db,
		impact_body_maximum_volume_db,
		strength
	)
	impact_body_audio.pitch_scale = lerpf(0.96, 0.86, strength)
	impact_body_audio.play()


func play_goal_replay_shot_sound(
	force: float,
	power_strike_active: bool = false
) -> void:
	_receive_shot_sound(force, power_strike_active)


func set_goal_replay_visual_state(
	active: bool,
	ability_id: int
) -> void:
	var safe_ability := clampi(
		ability_id,
		ABILITY_NONE,
		ABILITY_COUNT
	)
	local_ability_active = active
	local_active_ability_id = (
		safe_ability if active else ABILITY_NONE
	)
	_configure_ability_particle_colors(safe_ability)
	_apply_ability_particle_cosmetic()
	ability_particles.emitting = false
	ability_pulse_particles.emitting = false


# ================================================================
# SERVER-AUTHORITATIVE ABILITIES
# ================================================================

static func get_ability_name(ability_id: int) -> String:
	return str(
		ABILITY_NAMES.get(ability_id, "No Ability")
	)


static func get_ability_description(ability_id: int) -> String:
	return str(ABILITY_DESCRIPTIONS.get(ability_id, ""))


static func sanitize_selected_ability_for_cpu(
	ability_id: int,
	is_cpu_controlled: bool
) -> int:
	var safe_ability_id := clampi(
		ability_id,
		ABILITY_NONE,
		ABILITY_COUNT
	)
	# Meta Vision is a human-only information ability. CPU-controlled players
	# must never own it, even if old encounter/draft/preferences data still
	# contains the old ability id.
	if is_cpu_controlled and safe_ability_id == ABILITY_META_VISION:
		return ABILITY_NONE
	return safe_ability_id


func set_selected_ability(ability_id: int) -> void:
	if not multiplayer.is_server():
		return

	selected_ability = sanitize_selected_ability_for_cpu(
		ability_id,
		cpu_controlled
	)
	reset_ability_runtime()


func set_draft_perk(perk_id: int, definition: Dictionary = {}) -> void:
	if not multiplayer.is_server():
		return
	if perk_id > 0 and is_prestige_boss():
		perk_id = 0
		definition = {}
	draft_perk_id = maxi(0, perk_id)
	draft_perk_double_feature_uses = 0
	draft_perk_copycat_uses_remaining = 0
	draft_perk_speed_multiplier = float(definition.get("speed", 1.0))
	draft_perk_acceleration_multiplier = float(definition.get("acceleration", 1.0))
	draft_perk_shot_force_multiplier = float(definition.get("shot_force", 1.0))
	draft_perk_pass_force_multiplier = float(definition.get("pass_force", 1.0))
	draft_perk_charge_time_multiplier = float(definition.get("charge_time", 1.0))
	draft_perk_cooldown_multiplier = float(definition.get("cooldown", 1.0))
	draft_perk_pass_cooldown_multiplier = float(definition.get("pass_cooldown", 1.0))
	draft_perk_ability_strength_multiplier = float(definition.get("ability_strength", 1.0))
	draft_perk_ability_duration_multiplier = float(definition.get("ability_duration", 1.0))
	_reset_draft_perk_action_state()
	server_burst_charges = _get_effective_burst_max_charges()
	server_elastic_step_charges = _get_effective_elastic_step_max_charges()
	server_mirage_step_charges = _get_effective_mirage_step_max_charges()
	server_breakaway_charges = _get_effective_breakaway_max_charges()
	server_goalkeeper_reach_charges = _get_effective_goalkeeper_reach_max_charges()
	server_boogie_woogie_charges = _get_effective_boogie_woogie_max_charges()
	_receive_burst_charge_state.rpc(
		server_burst_charges,
		_get_effective_burst_max_charges()
	)
	_receive_elastic_step_charge_state.rpc(
		server_elastic_step_charges,
		_get_effective_elastic_step_max_charges()
	)


func clear_draft_perk() -> void:
	set_draft_perk(0, {})


func trigger_draft_perk(event: StringName) -> void:
	if not multiplayer.is_server():
		return
	var now := _server_time_seconds()
	var reduction := 0.0
	if draft_perk_id == 5 and event == &"goals":
		reduction = 4.0
	elif draft_perk_id == 12 and event == &"passes":
		reduction = 2.0
	elif draft_perk_id == 21 and event == &"saves":
		reduction = 4.0
	if reduction > 0.0:
		_reduce_draft_perk_cooldown_seconds(reduction, now)

	match draft_perk_id:
		3:
			if event == &"ability_used" and draft_perk_kickoff_encore_available:
				draft_perk_kickoff_encore_available = false
				_refresh_draft_perk_ability(now)
		4:
			if event == &"ability_used":
				draft_perk_curve_pass_until = now + 5.0
		8:
			if event == &"passes":
				draft_perk_completed_pass_count += 1
				if draft_perk_completed_pass_count >= 3:
					draft_perk_completed_pass_count = 0
					_refresh_draft_perk_ability(now)
		14:
			if event == &"passes":
				_grant_draft_perk_next_pass(1.55, 4.0, now)
		19:
			if event == &"ability_used":
				draft_perk_shot_cycle_until = now + 4.0
			elif event == &"shot_connected" and now <= draft_perk_shot_cycle_until:
				_scale_draft_perk_cooldown(0.60, now)
				draft_perk_shot_cycle_until = 0.0
		20:
			if event == &"goals":
				_reroll_draft_perk_ability(now)
		22:
			if event == &"saves":
				_grant_draft_perk_next_pass(1.65, 6.0, now)
		23:
			if event == &"possession_won":
				_scale_draft_perk_cooldown(0.5, now)
				_grant_draft_perk_movement_boost(1.22, 1.30, 2.0, now)
		24:
			if event == &"conceded":
				_grant_draft_perk_movement_boost(1.30, 1.30, 4.0, now)
				_grant_draft_perk_next_shot(1.25, 5.0, now)
		27:
			if event == &"ability_used":
				_grant_draft_perk_movement_boost(1.20, 1.0, 2.0, now)
		28:
			if event == &"ability_used":
				_grant_draft_perk_next_shot(1.25, 4.0, now)
		29:
			if event == &"passes":
				_grant_draft_perk_movement_boost(1.18, 1.25, 2.5, now)
		30:
			if event == &"passes":
				draft_perk_last_completed_pass_at = now
		31:
			if event == &"ability_used":
				draft_perk_ability_to_pass_until = now + 5.0
			elif event == &"passes" and now <= draft_perk_ability_to_pass_until:
				_reduce_draft_perk_cooldown_seconds(4.0, now)
				draft_perk_ability_to_pass_until = 0.0
		32:
			if event == &"saves":
				_refresh_draft_perk_ability(now)
		33:
			if event == &"conceded":
				_countercharge_draft_perk(now)
		34:
			if (
				event == &"goals"
				and now - server_last_ability_used_at <= 5.0
			):
				_refresh_draft_perk_ability(now)
		35:
			if event == &"passes":
				_grant_draft_perk_next_shot(1.20, 4.0, now)
		38:
			if event == &"conceded":
				draft_perk_next_cooldown_free = true
		39:
			if event == &"ability_used":
				match randi_range(0, 3):
					0:
						_grant_draft_perk_next_shot(1.35, 5.0, now)
					1:
						_grant_draft_perk_next_pass(1.55, 5.0, now)
					2:
						_grant_draft_perk_movement_boost(1.30, 1.30, 2.0, now)
					_:
						_scale_draft_perk_cooldown(0.5, now)
		44:
			if event == &"ability_used":
				draft_perk_double_feature_uses += 1
				if draft_perk_double_feature_uses % 2 == 0:
					if server_ability_active:
						draft_perk_next_cooldown_free = true
					else:
						_refresh_draft_perk_ability(now)
		45:
			if event == &"goals":
				_refresh_draft_perk_ability(now)
				draft_perk_next_cooldown_free = true


func _reset_draft_perk_action_state() -> void:
	draft_perk_action_speed_until = 0.0
	draft_perk_action_speed_multiplier = 1.0
	draft_perk_action_acceleration_until = 0.0
	draft_perk_action_acceleration_multiplier = 1.0
	draft_perk_last_completed_pass_at = -9999.0
	draft_perk_ability_to_pass_until = 0.0
	draft_perk_next_shot_until = 0.0
	draft_perk_next_shot_multiplier = 1.0
	draft_perk_next_pass_until = 0.0
	draft_perk_next_pass_multiplier = 1.0
	draft_perk_curve_pass_until = 0.0
	draft_perk_shot_cycle_until = 0.0
	draft_perk_completed_pass_count = 0
	draft_perk_kickoff_encore_available = true
	draft_perk_next_cooldown_free = false
	draft_perk_reverse_card_available = true
	draft_perk_copycat_uses_remaining = 0


func _get_effective_burst_max_charges() -> int:
	return maxi(1, burst_max_charges + (1 if draft_perk_id == 26 else 0))


func _get_effective_elastic_step_max_charges() -> int:
	return maxi(1, elastic_step_max_charges + (2 if draft_perk_id == 26 else 0))


func _get_effective_mirage_step_max_charges() -> int:
	return 1


func _get_effective_breakaway_max_charges() -> int:
	return 2 if draft_perk_id == 46 else 1


func _get_effective_goalkeeper_reach_max_charges() -> int:
	return 2 if draft_perk_id == 6 else 1


func _get_effective_boogie_woogie_max_charges() -> int:
	return 2 if draft_perk_id == 25 else 1


func _get_ability_mastery_duration_bonus(ability_id: int) -> float:
	if draft_perk_id != 47:
		return 0.0
	match ability_id:
		ABILITY_BREAKAWAY:
			return 0.70
		ABILITY_REFLEX_BLOCK:
			return 0.20
		ABILITY_SNAPBACK:
			return 0.40
		ABILITY_NUTMEG:
			return 0.45
		ABILITY_DECOY_RUN:
			return 0.50
		_:
			return 0.0


func _reduce_draft_perk_cooldown_seconds(seconds: float, now: float) -> void:
	var safe_seconds := maxf(0.0, seconds)
	server_pending_cooldown = maxf(0.0, server_pending_cooldown - safe_seconds)
	if server_ability_cooldown_ends_at > now:
		server_ability_cooldown_ends_at = maxf(
			now,
			server_ability_cooldown_ends_at - safe_seconds
		)
	_sync_draft_perk_cooldown_hud(now)


func _add_draft_perk_cooldown_seconds(
	seconds: float,
	now: float,
	allow_from_ready: bool = false
) -> void:
	var safe_seconds := maxf(0.0, seconds)
	if safe_seconds <= 0.0:
		return
	if server_ability_active or server_pending_cooldown > 0.0:
		server_pending_cooldown += safe_seconds
	elif server_ability_cooldown_ends_at > now:
		server_ability_cooldown_ends_at += safe_seconds
	elif allow_from_ready and selected_ability != ABILITY_NONE:
		server_ability_cooldown_ends_at = now + safe_seconds
	else:
		return
	_sync_draft_perk_cooldown_hud(now)


func consume_draft_perk_reverse_card() -> bool:
	if draft_perk_id != 43 or not draft_perk_reverse_card_available:
		return false
	draft_perk_reverse_card_available = false
	return true


func _scale_draft_perk_cooldown(scale: float, now: float) -> void:
	var safe_scale := clampf(scale, 0.0, 1.0)
	server_pending_cooldown *= safe_scale
	if server_ability_cooldown_ends_at > now:
		server_ability_cooldown_ends_at = (
			now
			+ (server_ability_cooldown_ends_at - now) * safe_scale
		)
	_sync_draft_perk_cooldown_hud(now)


func _refresh_draft_perk_ability(now: float) -> void:
	server_pending_cooldown = 0.0
	server_ability_cooldown_ends_at = 0.0
	_restore_selected_ability_charge_state()
	_sync_draft_perk_cooldown_hud(now)


func _selected_ability_uses_charge_pool() -> bool:
	return selected_ability in [
		ABILITY_BURST_DRIBBLE,
		ABILITY_ELASTIC_STEP,
		ABILITY_BREAKAWAY,
		ABILITY_GOALKEEPER_REACH,
		ABILITY_BOOGIE_WOOGIE,
	]


func _restore_selected_ability_charge_state() -> void:
	match selected_ability:
		ABILITY_BURST_DRIBBLE:
			server_burst_charges = _get_effective_burst_max_charges()
			_receive_burst_charge_state.rpc(
				server_burst_charges,
				_get_effective_burst_max_charges()
			)
		ABILITY_ELASTIC_STEP:
			server_elastic_step_charges = _get_effective_elastic_step_max_charges()
			_receive_elastic_step_charge_state.rpc(
				server_elastic_step_charges,
				_get_effective_elastic_step_max_charges()
			)
		ABILITY_BLIND_SPOT:
			server_mirage_step_charges = _get_effective_mirage_step_max_charges()
		ABILITY_BREAKAWAY:
			server_breakaway_charges = _get_effective_breakaway_max_charges()
		ABILITY_GOALKEEPER_REACH:
			server_goalkeeper_reach_charges = _get_effective_goalkeeper_reach_max_charges()
		ABILITY_BOOGIE_WOOGIE:
			server_boogie_woogie_charges = _get_effective_boogie_woogie_max_charges()


func _refresh_charge_based_selected_ability_if_ready(now: float) -> void:
	if server_ability_active or now < server_ability_cooldown_ends_at:
		return
	match selected_ability:
		ABILITY_BURST_DRIBBLE:
			_refresh_server_burst_charges(now)
		ABILITY_ELASTIC_STEP:
			_refresh_server_elastic_step_charges(now)
		ABILITY_BREAKAWAY:
			if draft_perk_id == 46 and server_breakaway_charges <= 0:
				server_breakaway_charges = _get_effective_breakaway_max_charges()
		ABILITY_GOALKEEPER_REACH:
			if draft_perk_id == 6 and server_goalkeeper_reach_charges <= 0:
				server_goalkeeper_reach_charges = _get_effective_goalkeeper_reach_max_charges()
		ABILITY_BOOGIE_WOOGIE:
			if draft_perk_id == 25 and server_boogie_woogie_charges <= 0:
				server_boogie_woogie_charges = _get_effective_boogie_woogie_max_charges()


func _countercharge_draft_perk(now: float) -> void:
	if _selected_ability_uses_charge_pool():
		_refresh_draft_perk_ability(now)
	else:
		_scale_draft_perk_cooldown(0.5, now)


func _grant_draft_perk_movement_boost(
	speed_multiplier: float,
	acceleration_multiplier: float,
	duration: float,
	now: float = -1.0
) -> void:
	if now < 0.0:
		now = _server_time_seconds()
	draft_perk_action_speed_multiplier = maxf(
		draft_perk_action_speed_multiplier,
		maxf(1.0, speed_multiplier)
	)
	draft_perk_action_acceleration_multiplier = maxf(
		draft_perk_action_acceleration_multiplier,
		maxf(1.0, acceleration_multiplier)
	)
	draft_perk_action_speed_until = maxf(
		draft_perk_action_speed_until,
		now + maxf(0.0, duration)
	)
	draft_perk_action_acceleration_until = maxf(
		draft_perk_action_acceleration_until,
		now + maxf(0.0, duration)
	)


func _grant_draft_perk_next_shot(
	multiplier: float,
	duration: float,
	now: float = -1.0
) -> void:
	if now < 0.0:
		now = _server_time_seconds()
	draft_perk_next_shot_multiplier = maxf(
		draft_perk_next_shot_multiplier,
		maxf(1.0, multiplier)
	)
	draft_perk_next_shot_until = maxf(
		draft_perk_next_shot_until,
		now + maxf(0.0, duration)
	)


func _grant_draft_perk_next_pass(
	multiplier: float,
	duration: float,
	now: float = -1.0
) -> void:
	if now < 0.0:
		now = _server_time_seconds()
	draft_perk_next_pass_multiplier = maxf(
		draft_perk_next_pass_multiplier,
		maxf(1.0, multiplier)
	)
	draft_perk_next_pass_until = maxf(
		draft_perk_next_pass_until,
		now + maxf(0.0, duration)
	)


func _reroll_draft_perk_ability(now: float) -> void:
	if selected_ability <= ABILITY_NONE or ABILITY_COUNT <= 1:
		return
	var previous_ability: int = selected_ability
	var rerolled_ability: int = (
		(previous_ability + owner_peer_id + int(now * 10.0)) % ABILITY_COUNT
	) + 1
	if rerolled_ability == previous_ability:
		rerolled_ability = (rerolled_ability % ABILITY_COUNT) + 1
	set_selected_ability(rerolled_ability)
	_refresh_draft_perk_ability(now)


func _sync_draft_perk_cooldown_hud(now: float) -> void:
	if server_ability_active:
		return
	var remaining := maxf(0.0, server_ability_cooldown_ends_at - now)
	_receive_ability_cooldown_started.rpc(selected_ability, remaining)


func _get_draft_perk_action_shot_multiplier(now: float) -> float:
	if now <= draft_perk_next_shot_until:
		return maxf(1.0, draft_perk_next_shot_multiplier)
	return 1.0


func _consume_draft_perk_action_shot() -> void:
	draft_perk_next_shot_until = 0.0
	draft_perk_next_shot_multiplier = 1.0
	if draft_perk_id == 36:
		draft_perk_next_pass_until = 0.0
		draft_perk_next_pass_multiplier = 1.0


func _get_draft_perk_action_pass_multiplier(now: float) -> float:
	if now <= draft_perk_next_pass_until:
		return maxf(1.0, draft_perk_next_pass_multiplier)
	return 1.0


func _consume_draft_perk_action_pass() -> void:
	draft_perk_next_pass_until = 0.0
	draft_perk_next_pass_multiplier = 1.0
	if draft_perk_id == 36:
		draft_perk_next_shot_until = 0.0
		draft_perk_next_shot_multiplier = 1.0


func set_permanent_overdrive(enabled: bool) -> void:
	if not multiplayer.is_server():
		return
	var was_enabled: bool = server_permanent_overdrive_enabled
	server_permanent_overdrive_enabled = enabled
	if enabled:
		selected_ability = ABILITY_OVERDRIVE
		if not _server_ability_is_active(ABILITY_OVERDRIVE):
			_apply_permanent_overdrive()
	elif was_enabled:
		reset_ability_runtime()


func set_permanent_power_strike(enabled: bool) -> void:
	if not multiplayer.is_server():
		return
	var was_enabled: bool = server_permanent_power_strike_enabled
	server_permanent_power_strike_enabled = enabled
	if enabled:
		selected_ability = ABILITY_POWER_STRIKE
		if not _server_ability_is_active(ABILITY_POWER_STRIKE):
			_apply_permanent_power_strike()
	elif was_enabled:
		reset_ability_runtime()


func set_permanent_elastic_step(enabled: bool) -> void:
	if not multiplayer.is_server():
		return
	var was_enabled: bool = server_permanent_elastic_step_enabled
	server_permanent_elastic_step_enabled = enabled
	if enabled:
		selected_ability = ABILITY_ELASTIC_STEP
		reset_ability_runtime()
	elif was_enabled:
		reset_ability_runtime()


func set_permanent_iron_anchor(enabled: bool) -> void:
	if not multiplayer.is_server():
		return
	var was_enabled: bool = server_permanent_iron_anchor_enabled
	server_permanent_iron_anchor_enabled = enabled
	if enabled:
		selected_ability = ABILITY_IRON_ANCHOR
		reset_ability_runtime()
	elif was_enabled:
		reset_ability_runtime()


func _apply_permanent_iron_anchor() -> void:
	if not server_permanent_iron_anchor_enabled:
		return
	selected_ability = ABILITY_IRON_ANCHOR
	server_ability_cooldown_ends_at = 0.0
	server_pending_cooldown = 0.0
	_receive_ability_cooldown_started.rpc(ABILITY_IRON_ANCHOR, 0.0)


func _apply_permanent_elastic_step() -> void:
	if not server_permanent_elastic_step_enabled:
		return
	selected_ability = ABILITY_ELASTIC_STEP
	server_ability_cooldown_ends_at = 0.0
	server_pending_cooldown = 0.0
	server_elastic_step_charges = _get_effective_elastic_step_max_charges()
	server_next_elastic_step_allowed_at = 0.0
	_receive_ability_cooldown_started.rpc(ABILITY_ELASTIC_STEP, 0.0)
	_receive_elastic_step_charge_state.rpc(
		server_elastic_step_charges,
		_get_effective_elastic_step_max_charges()
	)


func _apply_permanent_overdrive() -> void:
	if not server_permanent_overdrive_enabled:
		return
	server_ability_active = true
	server_active_ability_id = ABILITY_OVERDRIVE
	server_ability_ends_at = 1.0e20
	server_ability_cooldown_ends_at = 0.0
	server_pending_cooldown = 0.0
	server_ability_strength_scale = 1.0
	_receive_ability_started.rpc(ABILITY_OVERDRIVE, 86400.0)


func _apply_permanent_power_strike() -> void:
	if not server_permanent_power_strike_enabled:
		return
	server_ability_active = true
	server_active_ability_id = ABILITY_POWER_STRIKE
	server_ability_ends_at = 1.0e20
	server_ability_cooldown_ends_at = 0.0
	server_pending_cooldown = 0.0
	server_ability_strength_scale = 1.0
	_receive_ability_started.rpc(ABILITY_POWER_STRIKE, 86400.0)


func refresh_permanent_overdrive_visual_for_kickoff() -> void:
	if not multiplayer.is_server():
		return
	# Kickoff resets clear every client-side ability particle system. Re-send the
	# existing permanent effect after that reset has completed so the visual stays
	# continuous across goals without changing the authoritative ability state.
	if server_permanent_overdrive_enabled:
		_receive_ability_started.rpc(ABILITY_OVERDRIVE, 86400.0)
	if server_permanent_power_strike_enabled:
		_receive_ability_started.rpc(ABILITY_POWER_STRIKE, 86400.0)


func _request_local_ability() -> void:
	if selected_ability == ABILITY_NONE:
		return
	if selected_ability == ABILITY_DIRECT_FINISH:
		_cancel_pending_direct_finish_tap()
		if local_is_charging:
			_cancel_local_charge()
		if multiplayer.is_server():
			_server_request_direct_finish_trap(owner_peer_id)
		else:
			_request_direct_finish_trap.rpc_id(SERVER_PEER_ID)
		return

	if multiplayer.is_server():
		_server_activate_ability()
	else:
		_request_activate_ability.rpc_id(SERVER_PEER_ID)


func _request_local_direct_finish_volley() -> void:
	if local_is_charging:
		_cancel_local_charge()
	if multiplayer.is_server():
		_server_request_direct_finish_volley(owner_peer_id)
	else:
		_request_direct_finish_volley.rpc_id(SERVER_PEER_ID)


@rpc("any_peer", "call_remote", "reliable")
func _request_direct_finish_trap() -> void:
	if (
		not multiplayer.is_server()
		or multiplayer.get_remote_sender_id() != owner_peer_id
	):
		return
	_server_request_direct_finish_trap(owner_peer_id)


@rpc("any_peer", "call_remote", "reliable")
func _request_direct_finish_volley() -> void:
	if (
		not multiplayer.is_server()
		or multiplayer.get_remote_sender_id() != owner_peer_id
	):
		return
	_server_request_direct_finish_volley(owner_peer_id)


func _server_request_direct_finish_trap(requester_peer_id: int) -> bool:
	if not _can_server_choose_direct_finish(requester_peer_id):
		return false
	_server_stop_charge_without_shot()
	server_direct_finish_volley_requested = false
	server_direct_finish_aim_direction = Vector2.ZERO
	if _server_ability_is_active(ABILITY_DIRECT_FINISH):
		_receive_direct_finish_choice.rpc(false)
		return true
	return _server_activate_ability()


func _server_request_direct_finish_volley(requester_peer_id: int) -> bool:
	if not _can_server_choose_direct_finish(requester_peer_id):
		return false
	_server_stop_charge_without_shot()
	server_direct_finish_volley_requested = true
	server_direct_finish_aim_direction = Vector2.ZERO
	if _server_ability_is_active(ABILITY_DIRECT_FINISH):
		_receive_direct_finish_choice.rpc(true)
		return true
	var activated := _server_activate_ability()
	if not activated:
		server_direct_finish_volley_requested = false
	return activated


func _can_server_choose_direct_finish(requester_peer_id: int) -> bool:
	return (
		multiplayer.is_server()
		and requester_peer_id == owner_peer_id
		and not cpu_controlled
		and controls_enabled
		and selected_ability == ABILITY_DIRECT_FINISH
		and not server_ability_timers_paused
	)


func _server_stop_charge_without_shot() -> void:
	if not multiplayer.is_server() or not server_is_charging:
		return
	server_is_charging = false
	_receive_charge_stopped.rpc()


func _request_local_pass() -> void:
	if multiplayer.is_server():
		_server_request_pass(owner_peer_id)
	else:
		_request_pass.rpc_id(SERVER_PEER_ID)


func _request_local_soft_pass() -> void:
	if local_is_charging:
		return
	var direction: Vector2 = Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
		"move_down"
	)
	if multiplayer.is_server():
		_server_track_reverse_drag_input(direction)
		_server_soft_pass(owner_peer_id)
	else:
		_request_soft_pass.rpc_id(SERVER_PEER_ID, direction)


@rpc("any_peer", "call_remote", "reliable")
func _request_soft_pass(direction: Vector2 = Vector2.ZERO) -> void:
	if (
		not multiplayer.is_server()
		or multiplayer.get_remote_sender_id() != owner_peer_id
	):
		return
	_server_track_reverse_drag_input(direction)
	_server_soft_pass(owner_peer_id)


func _server_soft_pass(
	requester_peer_id: int,
	allow_cpu_execution: bool = false
) -> bool:
	if (
		not multiplayer.is_server()
		or requester_peer_id != owner_peer_id
		or (cpu_controlled and not allow_cpu_execution)
		or not controls_enabled
		or team == &""
		or server_is_charging
	):
		return false

	var now: float = _server_time_seconds()
	# Reverse-dribble presses are handled before the ordinary pass cooldown.
	# An early chain press is buffered by the mechanic instead of being lost.
	if _try_server_reverse_drag(now):
		return true

	if now < next_soft_pass_allowed_at or now < next_shot_allowed_at:
		_send_soft_pass_result(false)
		return false

	if now <= _server_reverse_drag_chain_until:
		_clear_server_reverse_drag_chain()

	var tagged_ball: FootballBall = _get_closest_ball_in_kick_area()
	if tagged_ball != null and tagged_ball.can_return_tag_for(owner_peer_id, team):
		next_soft_pass_allowed_at = now + maxf(0.05, soft_pass_cooldown_seconds * draft_perk_pass_cooldown_multiplier)
		next_shot_allowed_at = now + maxf(
			shot_buffer_seconds,
			soft_pass_shot_lockout_seconds
		)
		server_last_kick_charge_seconds = 0.0
		server_last_kick_was_soft_pass = true
		server_last_kick_time = now
		if _server_execute_return_tag_pass(tagged_ball):
			_receive_player_action_pulse.rpc(
				ACTION_PULSE_PASS,
				0.9,
				ABILITY_RETURN_TAG
			)
			_send_soft_pass_result(true)
			return true

	if _server_ability_is_active(ABILITY_BREAKAWAY):
		var breakaway_connected: bool = _server_execute_breakaway_pass(now)
		_send_soft_pass_result(breakaway_connected)
		return breakaway_connected

	if _server_ability_is_active(ABILITY_SIDE_SWIPE):
		var side_swipe_perk_pass_multiplier := (
			_get_draft_perk_action_pass_multiplier(now)
		)
		var side_swipe_connected: bool = _server_execute_side_swipe_kick(
			maxf(side_swipe_pass_force, soft_pass_force)
			* draft_perk_pass_force_multiplier
				* side_swipe_perk_pass_multiplier,
			true,
			now
		)
		if side_swipe_connected:
			_consume_draft_perk_action_pass()
			next_soft_pass_allowed_at = now + maxf(0.05, soft_pass_cooldown_seconds * draft_perk_pass_cooldown_multiplier)
			next_shot_allowed_at = now + maxf(
				shot_buffer_seconds,
				soft_pass_shot_lockout_seconds
			)
			_receive_player_action_pulse.rpc(
				ACTION_PULSE_PASS,
				0.9,
				ABILITY_SIDE_SWIPE
			)
		_send_soft_pass_result(side_swipe_connected)
		return side_swipe_connected

	next_soft_pass_allowed_at = now + maxf(0.05, soft_pass_cooldown_seconds * draft_perk_pass_cooldown_multiplier)
	next_shot_allowed_at = now + maxf(
		shot_buffer_seconds,
		soft_pass_shot_lockout_seconds
	)
	_receive_player_action_pulse.rpc(
		ACTION_PULSE_PASS,
		0.78,
		ABILITY_NONE
	)
	server_last_kick_charge_seconds = 0.0
	server_last_kick_was_soft_pass = true
	server_last_kick_time = now

	server_next_kick_is_pass = true
	var perk_pass_multiplier := _get_draft_perk_action_pass_multiplier(now)
	var pass_connected := _hit_ball(
		maxf(
			0.0,
			soft_pass_force
			* draft_perk_pass_force_multiplier
				* perk_pass_multiplier
		),
		false,
		false
	)
	server_next_kick_is_pass = false
	if pass_connected:
		_consume_draft_perk_action_pass()
	_send_soft_pass_result(pass_connected)
	return pass_connected


func cpu_try_soft_pass() -> bool:
	if (
		not cpu_controlled
		or not multiplayer.is_server()
		or not controls_enabled
	):
		return false
	return _server_soft_pass(owner_peer_id, true)


func cpu_try_fast_follow_up_soft_pass() -> bool:
	# Elite CPU Shoot -> Pass combo. The normal pass path correctly respects
	# next_shot_allowed_at, but that means a charged shot's 0.30 s shot buffer
	# expires only after a fast ball has already left the kick area. For this
	# deliberate two-action technique only, allow the pass impulse immediately
	# after the CPU's own connected shot while the ball is still physically in
	# contact. This reuses the normal soft-pass force and ball-hit code; it does
	# not add a CPU-only force multiplier.
	if (
		not cpu_controlled
		or not multiplayer.is_server()
		or not controls_enabled
		or team == &""
		or server_is_charging
	):
		return false
	var now: float = _server_time_seconds()
	if now < next_soft_pass_allowed_at:
		return false
	# Only permit the lockout bypass as an immediate continuation of this
	# player's own shot, never as a general-purpose way around shot cooldowns.
	if now - server_last_kick_time > 0.12:
		return false
	var tagged_ball: FootballBall = _get_closest_ball_in_kick_area()
	if tagged_ball == null or tagged_ball.last_touch_peer_id != owner_peer_id:
		return false
	next_soft_pass_allowed_at = now + maxf(0.05, soft_pass_cooldown_seconds)
	next_shot_allowed_at = now + maxf(
		shot_buffer_seconds,
		soft_pass_shot_lockout_seconds
	)
	_receive_player_action_pulse.rpc(
		ACTION_PULSE_PASS,
		0.78,
		ABILITY_NONE
	)
	server_last_kick_charge_seconds = 0.0
	server_last_kick_was_soft_pass = true
	server_last_kick_time = now
	server_next_kick_is_pass = true
	var pass_connected: bool = _hit_ball(
		maxf(0.0, soft_pass_force),
		false,
		false
	)
	server_next_kick_is_pass = false
	_send_soft_pass_result(pass_connected)
	return pass_connected


func _send_soft_pass_result(succeeded: bool) -> void:
	if owner_peer_id == multiplayer.get_unique_id():
		_receive_shot_result(succeeded)
	else:
		_receive_shot_result.rpc_id(owner_peer_id, succeeded)


func cpu_request_pass() -> bool:
	if (
		not multiplayer.is_server()
		or not cpu_controlled
		or not controls_enabled
	):
		return false
	return _emit_server_pass_request()


@rpc("any_peer", "call_remote", "reliable")
func _request_pass() -> void:
	if (
		not multiplayer.is_server()
		or multiplayer.get_remote_sender_id() != owner_peer_id
	):
		return
	_server_request_pass(owner_peer_id)


func _server_request_pass(requester_peer_id: int) -> void:
	if (
		not multiplayer.is_server()
		or requester_peer_id != owner_peer_id
		or cpu_controlled
		or not controls_enabled
	):
		return
	_emit_server_pass_request()


func _emit_server_pass_request() -> bool:
	var now := _server_time_seconds()
	if now < _next_pass_request_allowed_at:
		return false
	_next_pass_request_allowed_at = now + maxf(0.05, pass_request_cooldown)
	server_pass_request_ends_at = now + maxf(0.1, pass_request_duration)
	_receive_player_action_pulse.rpc(
		ACTION_PULSE_PASS_REQUEST,
		0.68,
		ABILITY_NONE
	)
	_receive_pass_request.rpc(maxf(0.1, pass_request_duration), team)
	return true


@rpc("authority", "call_local", "reliable")
func _receive_pass_request(duration: float, request_team: StringName) -> void:
	if not _local_viewer_is_on_team(request_team):
		return
	_local_pass_request_remaining = maxf(
		_local_pass_request_remaining,
		duration
	)
	pass_request_marker.show()
	pass_request_audio.stop()
	pass_request_audio.play()


func _local_viewer_is_on_team(request_team: StringName) -> bool:
	var local_peer_id := multiplayer.get_unique_id()
	for sibling in get_parent().get_children():
		var player := sibling as FootballPlayer
		if (
			player != null
			and not player.cpu_controlled
			and player.owner_peer_id == local_peer_id
		):
			return player.team == request_team
	return false


func _update_pass_request_visual(delta: float) -> void:
	if _local_pass_request_remaining <= 0.0:
		pass_request_marker.hide()
		return
	_local_pass_request_remaining = maxf(
		0.0,
		_local_pass_request_remaining - delta
	)
	pass_request_marker.visible = _local_pass_request_remaining > 0.0
	var pulse := 1.0 + sin(
		_local_pass_request_remaining * 13.0
	) * 0.08
	pass_request_marker.scale = Vector2.ONE * pulse


func _create_default_pass_request_sound() -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 0.14
	var sample_count := int(float(sample_rate) * duration)
	var audio_data := PackedByteArray()
	audio_data.resize(sample_count * 2)
	for index in range(sample_count):
		var time := float(index) / float(sample_rate)
		var progress := time / duration
		var envelope := sin(PI * progress) * (1.0 - progress)
		var wave := (
			sin(TAU * 660.0 * time) * 0.18
			+ sin(TAU * 880.0 * time) * 0.07
		) * envelope
		audio_data.encode_s16(
			index * 2,
			int(clampf(wave, -1.0, 1.0) * 32767.0)
		)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = audio_data
	return stream


@rpc("any_peer", "call_remote", "reliable")
func _request_activate_ability() -> void:
	if (
		not multiplayer.is_server()
		or multiplayer.get_remote_sender_id() != owner_peer_id
	):
		return

	_server_activate_ability()


func _server_activate_ability() -> bool:
	if (
		multiplayer.is_server()
		and controls_enabled
		and not server_ability_timers_paused
		and server_ability_active
		and server_active_ability_id == ABILITY_HEEL_TURN
	):
		return _server_execute_phantom_heel_followup()
	if (
		multiplayer.is_server()
		and controls_enabled
		and not server_ability_timers_paused
		and server_ability_active
		and server_active_ability_id == ABILITY_SNAPBACK
	):
		return _server_execute_snapback_recall()
	if (
		multiplayer.is_server()
		and controls_enabled
		and not server_ability_timers_paused
		and server_ability_active
		and server_active_ability_id == ABILITY_OVERDRIVE
		and draft_perk_id == 51
	):
		return _server_redline_eject()
	if (
		multiplayer.is_server()
		and controls_enabled
		and not server_ability_timers_paused
		and server_ability_active
		and server_active_ability_id == ABILITY_ENFORCER
		and draft_perk_id == 53
	):
		return _server_enforcer_quick_kick(0.78)
	if (
		multiplayer.is_server()
		and controls_enabled
		and not server_ability_timers_paused
		and server_ability_active
		and server_active_ability_id == ABILITY_GOALKEEPER_REACH
		and draft_perk_id == 54
	):
		return _server_cancel_goalkeeper_reach()
	if (
		not multiplayer.is_server()
		or not controls_enabled
		or server_ability_timers_paused
		or selected_ability == ABILITY_NONE
		or server_ability_active
	):
		return false

	var now := _server_time_seconds()
	if selected_ability == ABILITY_BURST_DRIBBLE:
		_refresh_server_burst_charges(now)
	elif selected_ability == ABILITY_ELASTIC_STEP:
		_refresh_server_elastic_step_charges(now)
	if (
		selected_ability == ABILITY_BREAKAWAY
		and draft_perk_id == 46
		and server_breakaway_charges <= 0
		and now >= server_ability_cooldown_ends_at
	):
		server_breakaway_charges = _get_effective_breakaway_max_charges()
	if (
		selected_ability == ABILITY_GOALKEEPER_REACH
		and draft_perk_id == 6
		and server_goalkeeper_reach_charges <= 0
		and now >= server_ability_cooldown_ends_at
	):
		server_goalkeeper_reach_charges = _get_effective_goalkeeper_reach_max_charges()
	if (
		selected_ability == ABILITY_BOOGIE_WOOGIE
		and draft_perk_id == 25
		and server_boogie_woogie_charges <= 0
		and now >= server_ability_cooldown_ends_at
	):
		server_boogie_woogie_charges = _get_effective_boogie_woogie_max_charges()
	if now < server_ability_cooldown_ends_at:
		return false

	var ability_id := selected_ability
	var strength_scale := 1.0
	var is_copy := false
	if selected_ability == ABILITY_COPYCAT:
		ability_id = _get_copycat_source_ability(now)
		if ability_id == ABILITY_NONE:
			return false
		strength_scale = clampf(
			copycat_strength_multiplier,
			0.1,
			1.0
		)
		is_copy = true

	var activated := _server_execute_ability(
		ability_id,
		strength_scale,
		is_copy,
		now
	)
	if activated:
		_receive_player_action_pulse.rpc(
			ACTION_PULSE_ABILITY,
			1.0,
			ability_id
		)
		server_last_used_ability_id = ability_id
		server_last_ability_used_at = now
		trigger_draft_perk(&"ability_used")
		ability_used.emit(owner_peer_id, team, ability_id)
		if is_copy:
			_server_consume_copycat_memory()
		else:
			_server_offer_copycat_memory_to_teammates(ability_id, now)
	return activated


func _server_execute_ability(
	ability_id: int,
	strength_scale: float,
	is_copy: bool,
	now: float
) -> bool:
	var safe_strength := clampf(strength_scale, 0.1, 1.0)
	var cooldown := _get_ability_cooldown_for(ability_id)
	if is_copy:
		cooldown += maxf(0.0, copycat_extra_cooldown)

	match ability_id:
		ABILITY_BURST_DRIBBLE:
			if (
				not is_copy
				and (
					server_burst_charges <= 0
					or now < server_next_burst_allowed_at
				)
			):
				return false

			var dash_direction := server_direction.normalized()
			if dash_direction.is_zero_approx():
				dash_direction = linear_velocity.normalized()
			if dash_direction.is_zero_approx():
				return false

			if draft_perk_id == 48 and not is_copy:
				linear_velocity *= 0.18
			_capture_burst_ball_speed_limits()
			apply_central_impulse(
				dash_direction
				* burst_impulse
				* safe_strength
			)
			if not is_copy:
				server_burst_charges -= 1
				server_next_burst_allowed_at = (
					now + maxf(0.0, burst_delay_between_dashes)
				)
				_receive_burst_charge_state.rpc(
					server_burst_charges,
					_get_effective_burst_max_charges()
				)
			_start_server_effect(
				burst_duration,
				cooldown
				if is_copy or server_burst_charges <= 0
				else 0.0,
				ability_id,
				safe_strength
			)

		ABILITY_QUICK_TRIGGER:
			_start_server_effect(
				curve_shot_effect_duration,
				cooldown,
				ability_id,
				safe_strength
			)

		ABILITY_POWER_STRIKE:
			_start_server_effect(
				power_strike_duration,
				cooldown,
				ability_id,
				safe_strength
			)

		ABILITY_OVERDRIVE:
			_start_server_effect(
				overdrive_duration + (1.0 if draft_perk_id == 1 else 0.0),
				cooldown,
				ability_id,
				safe_strength
			)

		ABILITY_HEEL_TURN:
			if not _server_heel_turn(safe_strength, cooldown):
				return false

		ABILITY_ENFORCER:
			_start_server_effect(
				enforcer_duration,
				cooldown,
				ability_id,
				safe_strength
			)

		ABILITY_GOALKEEPER_REACH:
			var reach_direction := (
				_get_goalkeeper_reach_direction()
			)
			if reach_direction.is_zero_approx():
				return false

			_goalkeeper_blocked_balls.clear()
			_set_ball_body_collision_enabled(false)
			apply_central_impulse(
				reach_direction
				* goalkeeper_reach_impulse
				* safe_strength
			)
			var reach_cooldown := cooldown
			if not is_copy and draft_perk_id == 6:
				server_goalkeeper_reach_charges = maxi(
					0,
					server_goalkeeper_reach_charges - 1
				)
				if server_goalkeeper_reach_charges > 0:
					reach_cooldown = 0.0
			_start_server_effect(
				goalkeeper_reach_duration,
				reach_cooldown,
				ability_id,
				safe_strength
			)

		ABILITY_TIME_SKIP_PASS:
			if not _server_time_skip_pass(safe_strength):
				return false
			_receive_ability_started.rpc(ability_id, 0.0)
			_start_server_cooldown(cooldown, ability_id)

		ABILITY_DIRECT_FINISH:
			if is_copy:
				if not _server_trap_or_volley(
					safe_strength,
					server_is_charging
					or server_direct_finish_volley_requested
				):
					return false
				server_direct_finish_volley_requested = false
				_receive_ability_started.rpc(ability_id, 0.0)
				_start_server_cooldown(cooldown, ability_id)
			else:
				server_direct_finish_candidate_id = 0
				server_direct_finish_candidate_entered_at = 0.0
				_start_server_effect(
					direct_finish_timing_window,
					cooldown,
					ability_id,
					safe_strength
				)
				_receive_direct_finish_choice.rpc(
					server_direct_finish_volley_requested
				)

		ABILITY_ELASTIC_STEP:
			if (
				not is_copy
				and (
					(
						not server_permanent_elastic_step_enabled
						and server_elastic_step_charges <= 0
					)
					or now < server_next_elastic_step_allowed_at
				)
			):
				return false
			var step_velocity := _get_elastic_step_velocity()
			if step_velocity.is_zero_approx():
				return false

			_set_ball_body_collision_enabled(false)
			linear_velocity = step_velocity * safe_strength
			_apply_elastic_step_ball_touch(step_velocity, safe_strength)
			if not is_copy:
				if not server_permanent_elastic_step_enabled:
					server_elastic_step_charges -= 1
				server_next_elastic_step_allowed_at = (
					0.0
					if server_permanent_elastic_step_enabled
					else now + maxf(0.0, elastic_step_delay_between_uses)
				)
				_receive_elastic_step_charge_state.rpc(
					server_elastic_step_charges,
					_get_effective_elastic_step_max_charges()
				)
			_start_server_effect(
				elastic_step_duration,
				cooldown
				if (
					is_copy
					or (
						not server_permanent_elastic_step_enabled
						and server_elastic_step_charges <= 0
					)
				)
				else 0.0,
				ability_id,
				safe_strength
			)

		ABILITY_META_VISION:
			_start_server_effect(
				meta_vision_duration
				* (safe_strength if is_copy else 1.0),
				cooldown,
				ability_id,
				safe_strength
			)

		ABILITY_REFLEX_BLOCK:
			server_reflex_facing = _get_ability_facing_direction()
			if server_reflex_facing.is_zero_approx():
				return false
			server_reflex_blocked_ball_id = 0
			_start_server_effect(
				reflex_block_duration
					+ _get_ability_mastery_duration_bonus(ABILITY_REFLEX_BLOCK),
				cooldown,
				ability_id,
				safe_strength
			)

		ABILITY_IRON_ANCHOR:
			if not _server_iron_anchor_trap(safe_strength):
				return false
			_receive_ability_started.rpc(ability_id, 0.0)
			_start_server_cooldown(
				0.0
				if server_permanent_iron_anchor_enabled and not is_copy
				else cooldown,
				ability_id
			)

		ABILITY_BLIND_SPOT:
			var blind_spot_origin := global_position
			var carried_ball := _get_closest_ball_in_kick_area()
			if not _prepare_blind_spot_teleport():
				return false
			_teleport_to_blind_spot_target()
			if carried_ball != null:
				_carry_ball_through_blind_spot(
					carried_ball,
					blind_spot_origin,
					safe_strength
				)
				if draft_perk_id == 61 and not is_copy:
					_grant_draft_perk_movement_boost(
						1.18,
						1.45,
						0.9,
						now
					)
			_receive_blind_spot_vfx.rpc(
				blind_spot_origin,
				server_blind_spot_target_position
			)
			_receive_ability_started.rpc(ability_id, 0.0)
			_start_server_cooldown(cooldown, ability_id)

		ABILITY_ECHO:
			_server_spawn_echo(safe_strength)
			_receive_ability_started.rpc(ability_id, 0.0)
			_start_server_cooldown(cooldown, ability_id)

		ABILITY_RETURN_TAG:
			_start_server_effect(
				return_tag_arming_duration
				* (safe_strength if is_copy else 1.0),
				cooldown,
				ability_id,
				safe_strength
			)

		ABILITY_BREAKAWAY:
			_start_server_effect(
				breakaway_arming_duration
				* (safe_strength if is_copy else 1.0),
				cooldown,
				ability_id,
				safe_strength
			)
			# In contact, Breakaway is a readable one-button dribble. Activating it
			# away from the ball still preserves the former armed Pass fallback.
			_server_execute_breakaway_pass(now)

		ABILITY_SNAPBACK:
			server_snapback_ball_id = 0
			server_snapback_touch_serial = 0
			server_snapback_kick_at = 0.0
			_start_server_effect(
				snapback_arming_duration
				* (safe_strength if is_copy else 1.0),
				cooldown,
				ability_id,
				safe_strength
			)

		ABILITY_SIDE_SWIPE:
			_start_server_effect(
				side_swipe_arming_duration
					* (safe_strength if is_copy else 1.0),
				cooldown,
				ability_id,
				safe_strength
			)

		ABILITY_NUTMEG:
			_start_server_effect(
				nutmeg_arming_duration
					* (safe_strength if is_copy else 1.0),
				cooldown,
				ability_id,
				safe_strength
			)
			if not is_copy and draft_perk_id == 7:
				_server_try_instant_nutmeg()

		ABILITY_DECOY_RUN:
			var decoy_direction: Vector2 = server_direction.normalized()
			if decoy_direction.is_zero_approx():
				decoy_direction = linear_velocity.normalized()
			if decoy_direction.is_zero_approx():
				return false
			var decoy_speed: float = maxf(
				linear_velocity.length(),
				maxf(1.0, decoy_run_minimum_speed)
			)
			var decoy_duration: float = (
				decoy_run_duration
				+ _get_ability_mastery_duration_bonus(ABILITY_DECOY_RUN)
			)
			_receive_decoy_run_vfx.rpc(
				global_position,
				decoy_direction * decoy_speed,
				maxf(0.1, decoy_duration)
			)
			_start_server_effect(
				decoy_duration,
				cooldown,
				ability_id,
				safe_strength
			)

		ABILITY_BOOGIE_WOOGIE:
			var first_position := global_position
			var second_position := Vector2.ZERO
			var swap_target: FootballPlayer = null
			var swapped_with_ball := false
			if draft_perk_id == 62 and not is_copy:
				var swap_ball := _get_closest_ball_in_kick_area()
				if swap_ball != null:
					second_position = swap_ball.global_position
					_swap_with_ball(swap_ball)
					swapped_with_ball = true
			if not swapped_with_ball:
				swap_target = _get_nearest_swap_target()
				if swap_target == null:
					return false
				second_position = swap_target.global_position
				_swap_with_player(swap_target)
			_apply_boogie_woogie_shockwave(
				second_position,
				swap_target,
				safe_strength
			)
			_receive_boogie_woogie_vfx.rpc(
				first_position,
				second_position
			)
			var boogie_cooldown := cooldown
			if not is_copy and draft_perk_id == 25:
				server_boogie_woogie_charges = maxi(
					0,
					server_boogie_woogie_charges - 1
				)
				if server_boogie_woogie_charges > 0:
					boogie_cooldown = 0.0
			_receive_ability_started.rpc(ability_id, 0.0)
			_start_server_cooldown(boogie_cooldown, ability_id)

		_:
			return false

	return true


func _start_server_effect(
	duration: float,
	cooldown: float,
	ability_id: int = selected_ability,
	strength_scale: float = 1.0
) -> void:
	var safe_duration := maxf(
		0.0,
		duration * draft_perk_ability_duration_multiplier
	)
	server_active_ability_id = ability_id
	server_ability_strength_scale = clampf(
		strength_scale * draft_perk_ability_strength_multiplier,
		0.1,
		1.5
	)
	server_pending_cooldown = _resolve_ability_cooldown(cooldown)
	server_ability_active = safe_duration > 0.0
	server_ability_ends_at = (
		_server_time_seconds() + safe_duration
	)

	_receive_ability_started.rpc(
		ability_id,
		safe_duration
	)

	if safe_duration <= 0.0:
		if ability_id in [
			ABILITY_GOALKEEPER_REACH,
			ABILITY_ELASTIC_STEP
		]:
			_set_ball_body_collision_enabled(true)
		if ability_id == ABILITY_BURST_DRIBBLE:
			server_burst_ball_speed_limits.clear()
		_start_server_cooldown(cooldown, ability_id)


func _start_server_cooldown(
	cooldown: float,
	ability_id: int = selected_ability
) -> void:
	var had_free_cooldown := draft_perk_next_cooldown_free
	var safe_cooldown: float = _resolve_ability_cooldown(cooldown)
	if had_free_cooldown:
		draft_perk_next_cooldown_free = false
	server_ability_active = false
	server_active_ability_id = ABILITY_NONE
	server_direct_finish_volley_requested = false
	server_direct_finish_candidate_id = 0
	server_direct_finish_candidate_entered_at = 0.0
	server_ability_strength_scale = 1.0
	if ability_id == ABILITY_SNAPBACK:
		server_snapback_ball_id = 0
		server_snapback_touch_serial = 0
		server_snapback_kick_at = 0.0
	server_ability_cooldown_ends_at = (
		_server_time_seconds() + safe_cooldown
	)
	_receive_ability_cooldown_started.rpc(
		ability_id,
		safe_cooldown
	)


func _resolve_ability_cooldown(cooldown: float) -> float:
	if freeplay_cooldowns_disabled or match_cooldowns_disabled:
		return 0.0
	var resolved := maxf(0.0, cooldown * draft_perk_cooldown_multiplier)
	if draft_perk_next_cooldown_free:
		return 0.0
	if (
		resolved > 0.0
		and draft_perk_id == 30
		and _server_time_seconds() - draft_perk_last_completed_pass_at <= 4.0
	):
		resolved *= 0.65
		draft_perk_last_completed_pass_at = -9999.0
	return resolved


func _get_selected_ability_cooldown() -> float:
	return _get_ability_cooldown_for(selected_ability)


func _get_ability_cooldown_for(ability_id: int) -> float:
	match ability_id:
		ABILITY_BURST_DRIBBLE:
			return maxf(0.0, burst_cooldown)
		ABILITY_QUICK_TRIGGER:
			return maxf(0.0, curve_shot_cooldown)
		ABILITY_POWER_STRIKE:
			return maxf(0.0, power_strike_cooldown)
		ABILITY_OVERDRIVE:
			return maxf(0.0, overdrive_cooldown)
		ABILITY_HEEL_TURN:
			return maxf(0.0, heel_turn_cooldown)
		ABILITY_ENFORCER:
			return maxf(0.0, enforcer_cooldown)
		ABILITY_GOALKEEPER_REACH:
			return maxf(0.0, goalkeeper_reach_cooldown)
		ABILITY_TIME_SKIP_PASS:
			return maxf(0.0, time_skip_pass_cooldown)
		ABILITY_DIRECT_FINISH:
			return maxf(0.0, direct_finish_cooldown)
		ABILITY_ELASTIC_STEP:
			return maxf(0.0, elastic_step_cooldown)
		ABILITY_META_VISION:
			return maxf(0.0, meta_vision_cooldown)
		ABILITY_COPYCAT:
			return maxf(0.0, copycat_fallback_cooldown)
		ABILITY_REFLEX_BLOCK:
			return maxf(0.0, reflex_block_cooldown)
		ABILITY_IRON_ANCHOR:
			return maxf(0.0, iron_anchor_cooldown)
		ABILITY_BLIND_SPOT:
			return maxf(0.0, blind_spot_cooldown)
		ABILITY_BOOGIE_WOOGIE:
			return maxf(0.0, boogie_woogie_cooldown)
		ABILITY_ECHO:
			return maxf(0.0, echo_cooldown)
		ABILITY_RETURN_TAG:
			return maxf(0.0, return_tag_cooldown)
		ABILITY_BREAKAWAY:
			return maxf(0.0, breakaway_cooldown)
		ABILITY_SNAPBACK:
			return maxf(0.0, snapback_cooldown)
		ABILITY_SIDE_SWIPE:
			return maxf(0.0, side_swipe_cooldown)
		ABILITY_NUTMEG:
			return maxf(0.0, nutmeg_cooldown)
		ABILITY_DECOY_RUN:
			return maxf(0.0, decoy_run_cooldown)
		_:
			return 0.0


func _update_server_ability() -> void:
	if selected_ability == ABILITY_COPYCAT:
		_refresh_server_copycat_memory(_server_time_seconds())
	if server_permanent_overdrive_enabled:
		if not _server_ability_is_active(ABILITY_OVERDRIVE):
			_apply_permanent_overdrive()
		return
	if server_permanent_power_strike_enabled:
		if not _server_ability_is_active(ABILITY_POWER_STRIKE):
			_apply_permanent_power_strike()
		return
	if not server_ability_active:
		var now := _server_time_seconds()
		_refresh_charge_based_selected_ability_if_ready(now)
		return

	if (
		_server_time_seconds() < server_ability_ends_at
	):
		return

	server_ability_active = false
	var finished_ability := server_active_ability_id
	server_active_ability_id = ABILITY_NONE
	server_ability_strength_scale = 1.0
	var cooldown := server_pending_cooldown
	server_pending_cooldown = 0.0
	server_ability_cooldown_ends_at = (
		_server_time_seconds() + cooldown
	)
	if finished_ability in [
		ABILITY_GOALKEEPER_REACH,
		ABILITY_ELASTIC_STEP
	]:
		_set_ball_body_collision_enabled(true)
	if finished_ability == ABILITY_BURST_DRIBBLE:
		server_burst_ball_speed_limits.clear()
	if finished_ability == ABILITY_HEEL_TURN:
		_clear_phantom_heel_followup()
	if finished_ability == ABILITY_SNAPBACK:
		var marked_ball: FootballBall = _get_ball_by_instance_id(server_snapback_ball_id)
		if marked_ball != null:
			marked_ball.clear_snapback_mark()
		server_snapback_ball_id = 0
		server_snapback_touch_serial = 0
		server_snapback_kick_at = 0.0
	if finished_ability == ABILITY_ELASTIC_STEP:
		_settle_elastic_step_velocity()
	if finished_ability == ABILITY_GOALKEEPER_REACH:
		_goalkeeper_blocked_balls.clear()
	elif finished_ability == ABILITY_REFLEX_BLOCK:
		server_reflex_blocked_ball_id = 0
	elif finished_ability == ABILITY_DIRECT_FINISH:
		server_direct_finish_volley_requested = false
		server_direct_finish_aim_direction = Vector2.ZERO
		server_direct_finish_candidate_id = 0
		server_direct_finish_candidate_entered_at = 0.0
	_receive_ability_effect_ended.rpc(
		finished_ability,
		cooldown
	)


func _refresh_server_burst_charges(now: float) -> void:
	if (
		selected_ability != ABILITY_BURST_DRIBBLE
		or server_ability_timers_paused
		or server_burst_charges > 0
		or server_ability_cooldown_ends_at <= 0.0
		or now < server_ability_cooldown_ends_at
	):
		return

	server_burst_charges = _get_effective_burst_max_charges()
	server_ability_cooldown_ends_at = 0.0
	server_next_burst_allowed_at = 0.0
	_receive_burst_charge_state.rpc(
		server_burst_charges,
		_get_effective_burst_max_charges()
	)


func _refresh_server_elastic_step_charges(now: float) -> void:
	if (
		selected_ability != ABILITY_ELASTIC_STEP
		or server_ability_timers_paused
		or server_elastic_step_charges > 0
		or server_ability_cooldown_ends_at <= 0.0
		or now < server_ability_cooldown_ends_at
	):
		return

	server_elastic_step_charges = _get_effective_elastic_step_max_charges()
	server_ability_cooldown_ends_at = 0.0
	server_next_elastic_step_allowed_at = 0.0
	_receive_elastic_step_charge_state.rpc(
		server_elastic_step_charges,
		_get_effective_elastic_step_max_charges()
	)


func _server_ability_is_active(ability_id: int) -> bool:
	return (
		server_ability_active
		and server_active_ability_id == ability_id
	)


func _refresh_echo_player_collision_mask() -> void:
	# Players only scan the collision layer belonging to the opposing team's
	# Echo. Teammates therefore pass through their own Echo while opponents
	# are physically stopped by it.
	var ball_collision_enabled := (
		collision_mask & BALL_COLLISION_LAYER_VALUE
	) != 0
	var base_mask := _normal_collision_mask
	if base_mask == 0:
		base_mask = collision_mask
	base_mask &= ~ECHO_COLLISION_LAYER_VALUES
	if team == &"red":
		base_mask |= ECHO_BLUE_COLLISION_LAYER_VALUE
	elif team == &"blue":
		base_mask |= ECHO_RED_COLLISION_LAYER_VALUE
	_normal_collision_mask = base_mask
	if ball_collision_enabled:
		collision_mask = _normal_collision_mask
	else:
		collision_mask = (
			_normal_collision_mask
			& ~BALL_COLLISION_LAYER_VALUE
		)


func _set_ball_body_collision_enabled(enabled: bool) -> void:
	if not multiplayer.is_server():
		return

	if enabled:
		collision_mask = _normal_collision_mask
	else:
		collision_mask = (
			_normal_collision_mask
			& ~BALL_COLLISION_LAYER_VALUE
		)

	for node in get_tree().get_nodes_in_group("football_balls"):
		var ball := node as FootballBall
		if ball == null:
			continue
		if enabled:
			remove_collision_exception_with(ball)
		else:
			add_collision_exception_with(ball)


func _capture_burst_ball_speed_limits() -> void:
	server_burst_ball_speed_limits.clear()
	for node in get_tree().get_nodes_in_group("football_balls"):
		var ball := node as FootballBall
		if ball == null:
			continue
		server_burst_ball_speed_limits[ball.get_instance_id()] = maxf(
			ball.linear_velocity.length(),
			maxf(0.0, burst_ball_contact_speed_limit)
		)


func _server_limit_burst_ball_velocity() -> void:
	var control_radius := maxf(0.0, burst_ball_control_radius)
	for node in get_tree().get_nodes_in_group("football_balls"):
		var ball := node as FootballBall
		if (
			ball == null
			or global_position.distance_to(ball.global_position)
			> control_radius
		):
			continue

		var speed_limit := float(
			server_burst_ball_speed_limits.get(
				ball.get_instance_id(),
				maxf(0.0, burst_ball_contact_speed_limit)
			)
		)
		if ball.linear_velocity.length() > speed_limit:
			ball.linear_velocity = (
				ball.linear_velocity.normalized() * speed_limit
			)


func _get_closest_ball_in_kick_area() -> FootballBall:
	var closest_ball: FootballBall = null
	var closest_distance := INF
	for body in kick_area.get_overlapping_bodies():
		var ball := body as FootballBall
		if ball == null:
			continue
		if cpu_controlled and ball.is_nutmeg_bypass_target(self):
			continue
		var distance := global_position.distance_squared_to(
			ball.global_position
		)
		if distance < closest_distance:
			closest_distance = distance
			closest_ball = ball
	return closest_ball


func _server_trap_or_volley(
	strength_scale: float,
	volley_requested: bool
) -> bool:
	var ball: FootballBall = null
	var closest_distance := maxf(
		0.0,
		minf(
			direct_finish_activation_radius,
			direct_finish_contact_distance
		)
	)
	for node in get_tree().get_nodes_in_group("football_balls"):
		var candidate := node as FootballBall
		if candidate == null:
			continue
		var distance := global_position.distance_to(
			candidate.global_position
		)
		if distance <= closest_distance:
			closest_distance = distance
			ball = candidate

	if ball == null:
		server_direct_finish_candidate_id = 0
		server_direct_finish_candidate_entered_at = 0.0
		return false
	var candidate_id := ball.get_instance_id()
	if candidate_id != server_direct_finish_candidate_id:
		server_direct_finish_candidate_id = candidate_id
		server_direct_finish_candidate_entered_at = _server_time_seconds()
	var incoming_velocity := ball.linear_velocity
	if draft_perk_id == 56:
		volley_requested = (
			incoming_velocity.length()
			>= maxf(650.0, direct_finish_minimum_ball_speed * 1.65)
		)
	var required_speed := (
		direct_finish_minimum_ball_speed
		if volley_requested
		else direct_finish_trap_minimum_ball_speed
	)
	if (
		incoming_velocity.length()
		< maxf(0.0, required_speed)
	):
		return false

	var toward_player := ball.global_position.direction_to(
		global_position
	)
	var approach_dot := incoming_velocity.normalized().dot(
		toward_player
	)
	var required_approach_dot := (
		direct_finish_minimum_approach_dot
		if volley_requested
		else direct_finish_trap_minimum_approach_dot
	)
	# Setup can watch a wider area, but Trap/Volley can only consume a ball
	# that has reached a real contact distance and is travelling toward us.
	if approach_dot < clampf(
		maxf(0.05, required_approach_dot),
		-1.0,
		1.0
	):
		return false

	if volley_requested:
		var ball_direction := server_direct_finish_aim_direction.normalized()
		if ball_direction.is_zero_approx():
			ball_direction = server_direction.normalized()
		if ball_direction.is_zero_approx():
			var target_goal := _get_attacking_goal()
			if target_goal != null:
				var mouth_range := target_goal.get_mouth_y_range()
				var goal_center := Vector2(
					target_goal.get_goal_plane_x(),
					(mouth_range.x + mouth_range.y) * 0.5
				)
				ball_direction = ball.global_position.direction_to(
					goal_center
				)
		if ball_direction.is_zero_approx():
			ball_direction = incoming_velocity.normalized()
		if ball_direction.is_zero_approx():
			ball_direction = global_position.direction_to(
				ball.global_position
			)
		if ball_direction.is_zero_approx():
			return false

		var applied_force := (
			maxf(0.0, maximum_shot_force)
			* maxf(0.0, direct_finish_maximum_force_ratio)
			* clampf(strength_scale, 0.1, 1.0)
		)
		var kick_impulse := ball_direction * applied_force
		kick_impulse = _sanitize_cpu_ball_impulse(
			ball,
			kick_impulse,
			&"direct_finish_volley"
		)
		if kick_impulse.is_zero_approx():
			return false
		ball.register_kick(
			owner_peer_id,
			display_name,
			team,
			kick_impulse
		)
		ball.apply_central_impulse(kick_impulse)
		_receive_shot_sound.rpc(applied_force)
		_receive_direct_finish_volley_sound.rpc()
	else:
		var trap_direction := server_direct_finish_aim_direction.normalized()
		if trap_direction.is_zero_approx():
			trap_direction = server_direction.normalized()
		if trap_direction.is_zero_approx():
			trap_direction = global_position.direction_to(
				ball.global_position
			)
		if trap_direction.is_zero_approx():
			trap_direction = -incoming_velocity.normalized()
		if trap_direction.is_zero_approx():
			trap_direction = Vector2.RIGHT
		ball.redirect_ball(
			global_position
			+ trap_direction
			* maxf(0.0, direct_finish_trap_control_distance),
			incoming_velocity
			* clampf(direct_finish_trap_velocity_ratio, 0.0, 1.0),
			owner_peer_id,
			display_name,
			team,
			cpu_controlled
		)
	return true


func _server_update_direct_finish() -> void:
	if not _server_trap_or_volley(
		server_ability_strength_scale,
		server_direct_finish_volley_requested
	):
		return

	if server_is_charging:
		server_is_charging = false
		_receive_charge_stopped.rpc()
	server_direct_finish_volley_requested = false
	server_direct_finish_aim_direction = Vector2.ZERO
	server_direct_finish_candidate_id = 0
	server_direct_finish_candidate_entered_at = 0.0
	server_ability_active = false
	server_active_ability_id = ABILITY_NONE
	server_ability_strength_scale = 1.0
	var cooldown := server_pending_cooldown
	server_pending_cooldown = 0.0
	server_ability_cooldown_ends_at = (
		_server_time_seconds() + cooldown
	)
	_receive_ability_effect_ended.rpc(
		ABILITY_DIRECT_FINISH,
		cooldown
	)


func _get_elastic_step_velocity() -> Vector2:
	var ball := _get_closest_ball_in_kick_area()
	if ball == null:
		return Vector2.ZERO

	var ball_to_player: Vector2 = global_position - ball.global_position
	var radial_direction := ball_to_player.normalized()
	if radial_direction.is_zero_approx():
		radial_direction = ball.global_position.direction_to(
			global_position
		)
	if radial_direction.is_zero_approx():
		radial_direction = Vector2.RIGHT

	var tangent_a := Vector2(
		-radial_direction.y,
		radial_direction.x
	)
	var tangent_b: Vector2 = -tangent_a
	var requested_direction := server_direction.normalized()
	var angle: float = deg_to_rad(elastic_step_orbit_degrees)
	var orbit_distance: float = clampf(
		maxf(1.0, elastic_step_orbit_distance),
		1.0,
		maxf(1.0, ball_to_player.length() * 1.05 + 30.0)
	)
	var offset_a: Vector2 = radial_direction.rotated(angle)
	offset_a *= orbit_distance
	var offset_b: Vector2 = radial_direction.rotated(-angle)
	offset_b *= orbit_distance
	var target_a: Vector2 = ball.global_position + offset_a
	var target_b: Vector2 = ball.global_position + offset_b
	var target_position: Vector2
	var input_difference: float = 0.0
	if not requested_direction.is_zero_approx():
		input_difference = (
			requested_direction.dot(tangent_a)
			- requested_direction.dot(tangent_b)
		)
	if absf(input_difference) > 0.12:
		target_position = target_a if input_difference > 0.0 else target_b
	else:
		var clearance_a: float = _get_elastic_step_position_clearance(target_a)
		var clearance_b: float = _get_elastic_step_position_clearance(target_b)
		target_position = target_a if clearance_a >= clearance_b else target_b

	var travel := (target_position - global_position)
	var away_component: float = travel.dot(radial_direction)
	if away_component > 0.0:
		travel -= radial_direction * away_component
	travel = travel.limit_length(maxf(1.0, elastic_step_max_travel_distance))
	if travel.is_zero_approx():
		return Vector2.ZERO

	var movement_bias: Vector2 = requested_direction
	if movement_bias.is_zero_approx():
		movement_bias = travel.normalized()
	if not movement_bias.is_zero_approx():
		travel = (
			travel * 0.72
			+ movement_bias * maxf(1.0, elastic_step_orbit_distance * 0.45)
		).limit_length(maxf(1.0, elastic_step_max_travel_distance))

	var duration := maxf(0.01, elastic_step_duration)
	var required_speed := travel.length() / duration
	return (
		travel.normalized()
		* minf(maxf(0.0, elastic_step_dash_speed), required_speed)
	)


func _get_elastic_step_position_clearance(position: Vector2) -> float:
	var parent_node: Node = get_parent()
	if parent_node == null:
		return 99999.0
	var closest: float = 99999.0
	for child in parent_node.get_children():
		var opponent: FootballPlayer = child as FootballPlayer
		if (
			opponent == null
			or opponent == self
			or opponent.team == team
			or opponent.team == &""
			or not opponent.controls_enabled
		):
			continue
		closest = minf(closest, position.distance_to(opponent.global_position))
	return closest


func _apply_elastic_step_ball_touch(
	step_velocity: Vector2,
	strength_scale: float
) -> void:
	var ball: FootballBall = _get_closest_ball_in_kick_area()
	if ball == null:
		return
	var forward: Vector2 = _get_breakaway_attack_direction()
	if forward.is_zero_approx():
		forward = step_velocity.normalized()
	var requested: Vector2 = server_direction.normalized()
	var lead_direction: Vector2 = forward
	if not requested.is_zero_approx():
		lead_direction = (
			forward * 0.35
			+ requested * 0.65
		).normalized()
	var carry_direction: Vector2 = step_velocity.normalized()
	if carry_direction.is_zero_approx():
		return
	if lead_direction.is_zero_approx():
		lead_direction = carry_direction
	var lead_weight := clampf(elastic_step_ball_lead_weight, 0.0, 0.3)
	if server_permanent_elastic_step_enabled:
		# Neymar's boss version keeps the ball on the step line. The normal
		# ability retains a little forward lead; repeated boss steps otherwise
		# expose the ball before the player can complete the chosen exit route.
		lead_weight = minf(lead_weight, 0.03)
	var desired_direction: Vector2 = (
		carry_direction * (1.0 - lead_weight)
		+ lead_direction * lead_weight
	).normalized()
	if desired_direction.is_zero_approx():
		desired_direction = carry_direction
	var player_step_speed := (
		step_velocity.length()
		* clampf(strength_scale, 0.1, 1.5)
	)
	var carry_ratio: float = clampf(elastic_step_ball_carry_ratio, 0.5, 1.0)
	if server_permanent_elastic_step_enabled:
		carry_ratio = 1.0
	var target_speed: float = (
		minf(
			maxf(0.0, elastic_step_ball_touch_speed),
			player_step_speed
		)
		* carry_ratio
	)
	if draft_perk_id == 57:
		target_speed *= 1.32
	var desired_velocity: Vector2 = desired_direction * target_speed
	var impulse: Vector2 = (
		desired_velocity - ball.linear_velocity
	) * maxf(0.001, ball.mass)
	impulse = _sanitize_cpu_ball_impulse(ball, impulse, &"elastic_step_touch")
	if impulse.is_zero_approx():
		return
	ball.register_touch(
		owner_peer_id,
		display_name,
		team,
		ball.linear_velocity,
		&"elastic_step",
		desired_velocity
	)
	ball.apply_central_impulse(impulse)


func _keep_elastic_step_inside_kick_range(
	state: PhysicsDirectBodyState2D,
	movement_direction: Vector2
) -> void:
	var ball := _get_closest_ball_within_distance(
		maxf(
			kick_feedback_detection_distance,
			elastic_step_orbit_distance
		) + 120.0
	)
	if ball == null:
		return

	var outward := ball.global_position.direction_to(
		state.transform.origin
	)
	var distance := ball.global_position.distance_to(
		state.transform.origin
	)
	var maximum_distance := minf(
		maxf(1.0, kick_feedback_detection_distance - 8.0),
		maxf(1.0, elastic_step_orbit_distance + 35.0)
	)
	if (
		distance >= maximum_distance
		and state.linear_velocity.dot(outward) > 0.0
	):
		state.linear_velocity -= (
			outward * state.linear_velocity.dot(outward)
		)
	if (
		distance >= maximum_distance
		and movement_direction.dot(outward) > 0.0
	):
		state.apply_central_force(
			-outward * acceleration * 1.5
		)


func _settle_elastic_step_velocity() -> void:
	var ball := _get_closest_ball_within_distance(
		maxf(
			kick_feedback_detection_distance,
			elastic_step_orbit_distance
		) + 120.0
	)
	if ball != null:
		var outward := ball.global_position.direction_to(
			global_position
		)
		var outward_speed := linear_velocity.dot(outward)
		if outward_speed > 0.0:
			linear_velocity -= outward * outward_speed
	linear_velocity = linear_velocity.limit_length(
		maxf(0.0, elastic_step_exit_speed)
	)


func _get_closest_ball_within_distance(
	maximum_distance: float
) -> FootballBall:
	var closest_ball: FootballBall = null
	var closest_distance_squared := (
		maxf(0.0, maximum_distance)
		* maxf(0.0, maximum_distance)
	)
	for node in get_tree().get_nodes_in_group("football_balls"):
		var ball := node as FootballBall
		if ball == null:
			continue
		var distance_squared := global_position.distance_squared_to(
			ball.global_position
		)
		if distance_squared <= closest_distance_squared:
			closest_distance_squared = distance_squared
			closest_ball = ball
	return closest_ball


func _server_iron_anchor_trap(
	strength_scale: float
) -> bool:
	var ball := _get_closest_ball_within_distance(
		maxf(0.0, iron_anchor_trap_radius)
	)
	if ball == null:
		return false

	var safe_strength := clampf(strength_scale, 0.1, 1.0)
	var retained_fraction := lerpf(
		1.0,
		clampf(
			iron_anchor_ball_velocity_retention,
			0.0,
			1.0
		),
		safe_strength
	)
	var trapped_velocity := ball.linear_velocity * retained_fraction
	var trap_position := ball.global_position
	if draft_perk_id == 60:
		var pocket_direction := _get_ability_facing_direction()
		if pocket_direction.is_zero_approx():
			pocket_direction = global_position.direction_to(ball.global_position)
		if pocket_direction.is_zero_approx():
			pocket_direction = Vector2.RIGHT
		trap_position = global_position + pocket_direction * 135.0
		trapped_velocity *= 0.08
	ball.redirect_ball(
		trap_position,
		trapped_velocity,
		owner_peer_id,
		display_name,
		team,
		cpu_controlled
	)
	_receive_iron_anchor_trap_vfx.rpc(trap_position)
	return true


func _prepare_blind_spot_teleport() -> bool:
	var target_player: FootballPlayer = null
	var target_distance_squared := (
		maxf(0.0, blind_spot_search_radius)
		* maxf(0.0, blind_spot_search_radius)
	)
	for node in get_parent().get_children():
		var candidate := node as FootballPlayer
		if (
			candidate == null
			or candidate == self
			or candidate.team == team
			or candidate.team == &""
		):
			continue
		var distance_squared := global_position.distance_squared_to(
			candidate.global_position
		)
		if distance_squared <= target_distance_squared:
			target_distance_squared = distance_squared
			target_player = candidate

	if target_player == null:
		return false

	var through_direction := global_position.direction_to(
		target_player.global_position
	)
	if through_direction.is_zero_approx():
		through_direction = server_direction.normalized()
	if through_direction.is_zero_approx():
		through_direction = Vector2.RIGHT
	var target_position := (
		target_player.global_position
		+ through_direction
		* maxf(0.0, blind_spot_distance_behind_target)
	)
	if (
		target_position.is_equal_approx(global_position)
		or not _is_blind_spot_position_clear(
			target_position,
			target_player
		)
	):
		return false
	server_blind_spot_target_position = target_position
	server_blind_spot_target_player = target_player
	return true


func _is_blind_spot_position_clear(
	target_position: Vector2,
	target_player: FootballPlayer
) -> bool:
	var collision_shape := get_node_or_null(
		"CollisionShape2D"
	) as CollisionShape2D
	if collision_shape == null or collision_shape.shape == null:
		return true

	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = collision_shape.shape
	query.transform = Transform2D(
		global_rotation,
		target_position
		+ collision_shape.position.rotated(global_rotation)
	)
	query.collision_mask = (
		_normal_collision_mask & ~BALL_COLLISION_LAYER_VALUE
	)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.exclude = [get_rid(), target_player.get_rid()]
	return (
		get_world_2d()
		.direct_space_state
		.intersect_shape(query, 1)
		.is_empty()
	)


func _teleport_to_blind_spot_target() -> void:
	var ignored_target := server_blind_spot_target_player
	if is_instance_valid(ignored_target):
		add_collision_exception_with(ignored_target)
		ignored_target.add_collision_exception_with(self)

	freeze = true
	global_position = server_blind_spot_target_position
	linear_velocity = Vector2.ZERO
	_ball_free_linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	reset_physics_interpolation()
	freeze = false
	sleeping = false

	if is_instance_valid(ignored_target):
		var ignore_seconds := maxf(
			0.0,
			blind_spot_enemy_collision_ignore_seconds
		)
		get_tree().create_timer(ignore_seconds).timeout.connect(
			func() -> void:
				if not is_instance_valid(ignored_target):
					return
				remove_collision_exception_with(ignored_target)
				ignored_target.remove_collision_exception_with(self)
		)


func _carry_ball_through_blind_spot(
	ball: FootballBall,
	origin: Vector2,
	strength_scale: float
) -> void:
	if ball == null:
		return
	var through_direction := origin.direction_to(global_position)
	if through_direction.is_zero_approx():
		through_direction = server_direction.normalized()
	if through_direction.is_zero_approx():
		through_direction = Vector2.RIGHT
	var safe_strength := clampf(strength_scale, 0.1, 1.0)
	var carry_distance := maxf(80.0, blind_spot_ball_carry_distance)
	var exit_speed := maxf(0.0, blind_spot_ball_exit_speed)
	if draft_perk_id == 61:
		carry_distance *= 1.55
		exit_speed *= 1.55
	ball.redirect_ball(
		global_position
		+ through_direction
		* carry_distance,
		through_direction
		* exit_speed
		* safe_strength,
		owner_peer_id,
		display_name,
		team,
		cpu_controlled
	)


func _get_nearest_swap_target() -> FootballPlayer:
	if team == &"" or get_parent() == null:
		return null

	var nearest_player: FootballPlayer = null
	var nearest_distance_squared := INF
	for node in get_parent().get_children():
		var candidate := node as FootballPlayer
		if (
			candidate == null
			or candidate == self
			or candidate.team == &""
			or candidate.team == team
		):
			continue
		var distance_squared := global_position.distance_squared_to(
			candidate.global_position
		)
		if distance_squared < nearest_distance_squared:
			nearest_distance_squared = distance_squared
			nearest_player = candidate
	return nearest_player


func _swap_with_player(swap_target: FootballPlayer) -> void:
	var first_position := global_position
	var first_velocity := linear_velocity
	var first_angular_velocity := angular_velocity

	freeze = true
	swap_target.freeze = true
	global_position = swap_target.global_position
	swap_target.global_position = first_position
	linear_velocity = swap_target.linear_velocity
	angular_velocity = swap_target.angular_velocity
	swap_target.linear_velocity = first_velocity
	swap_target.angular_velocity = first_angular_velocity
	reset_physics_interpolation()
	swap_target.reset_physics_interpolation()
	freeze = false
	swap_target.freeze = false
	sleeping = false
	swap_target.sleeping = false


func _swap_with_ball(ball: FootballBall) -> void:
	if ball == null:
		return
	var player_position := global_position
	var player_velocity := linear_velocity
	var ball_position := ball.global_position
	var ball_velocity := ball.linear_velocity
	freeze = true
	global_position = ball_position
	linear_velocity = ball_velocity
	angular_velocity = 0.0
	reset_physics_interpolation()
	freeze = false
	sleeping = false
	ball.redirect_ball(
		player_position,
		player_velocity,
		owner_peer_id,
		display_name,
		team,
		cpu_controlled
	)


func _apply_boogie_woogie_shockwave(
	origin: Vector2,
	swapped_player: FootballPlayer,
	strength_scale: float
) -> void:
	var radius := maxf(0.0, boogie_woogie_shockwave_radius)
	if radius <= 0.0:
		return

	var safe_strength := clampf(strength_scale, 0.1, 1.0)
	for node in get_tree().get_nodes_in_group("football_balls"):
		var ball := node as FootballBall
		if ball == null:
			continue
		var ball_offset := ball.global_position - origin
		var ball_distance := ball_offset.length()
		if ball_distance > radius:
			continue
		var ball_direction := _get_shockwave_direction(ball_offset)
		ball.apply_central_impulse(
			ball_direction
			* maxf(0.0, boogie_woogie_ball_push_impulse)
			* _get_boogie_woogie_shockwave_falloff(
				ball_distance,
				radius
			)
			* safe_strength
		)

	for node in get_parent().get_children():
		var target := node as FootballPlayer
		if (
			target == null
			or target == self
			or target == swapped_player
			or target.team == team
			or target.team == &""
		):
			continue
		var target_offset := target.global_position - origin
		var target_distance := target_offset.length()
		if target_distance > radius:
			continue
		target.apply_central_impulse(
			_get_shockwave_direction(target_offset)
			* maxf(0.0, boogie_woogie_enemy_push_impulse)
			* _get_boogie_woogie_shockwave_falloff(
				target_distance,
				radius
			)
			* safe_strength
		)


func _get_shockwave_direction(offset: Vector2) -> Vector2:
	if not offset.is_zero_approx():
		return offset.normalized()
	var fallback := server_direction.normalized()
	if fallback.is_zero_approx():
		fallback = Vector2.RIGHT
	return fallback


func _get_boogie_woogie_shockwave_falloff(
	distance: float,
	radius: float
) -> float:
	var center_weight := 1.0 - clampf(
		distance / maxf(0.01, radius),
		0.0,
		1.0
	)
	return lerpf(
		clampf(boogie_woogie_edge_force_fraction, 0.0, 1.0),
		1.0,
		center_weight
	)


func _get_copycat_source_ability(now: float) -> int:
	_refresh_server_copycat_memory(now)
	if server_copycat_stored_ability_id != ABILITY_NONE:
		return server_copycat_stored_ability_id
	if (
		freeplay_cooldowns_disabled
		and freeplay_copycat_source_ability not in [
			ABILITY_NONE,
			ABILITY_COPYCAT,
			ABILITY_GOALKEEPER_REACH
		]
	):
		return freeplay_copycat_source_ability
	return ABILITY_NONE


func get_copycat_source_ability(now: float) -> int:
	return _get_copycat_source_ability(now)


func _server_offer_copycat_memory_to_teammates(
	ability_id: int,
	now: float
) -> void:
	if (
		not multiplayer.is_server()
		or selected_ability == ABILITY_COPYCAT
		or ability_id in [
			ABILITY_NONE,
			ABILITY_COPYCAT,
			ABILITY_GOALKEEPER_REACH
		]
	):
		return
	var players_node := get_parent()
	if players_node == null:
		return
	for node in players_node.get_children():
		var teammate := node as FootballPlayer
		if (
			teammate == null
			or teammate == self
			or teammate.team != team
			or teammate.selected_ability != ABILITY_COPYCAT
		):
			continue
		teammate._server_store_copycat_memory(ability_id, now)


func _server_store_copycat_memory(ability_id: int, now: float) -> void:
	if not multiplayer.is_server() or selected_ability != ABILITY_COPYCAT:
		return
	_refresh_server_copycat_memory(now)
	# Once Copycat has captured something, keep that exact ability until it is
	# successfully used or its memory window expires. Later teammate abilities
	# cannot unexpectedly replace the player's prepared copy.
	if server_copycat_stored_ability_id != ABILITY_NONE:
		return
	if ability_id in [ABILITY_NONE, ABILITY_COPYCAT, ABILITY_GOALKEEPER_REACH]:
		return
	var memory := maxf(0.0, copycat_memory_seconds)
	draft_perk_copycat_uses_remaining = 2 if draft_perk_id == 58 else 1
	server_copycat_stored_ability_id = ability_id
	server_copycat_stored_expires_at = (
		now + memory if memory > 0.0 else 0.0
	)
	_receive_copycat_memory.rpc(ability_id, memory)


func _refresh_server_copycat_memory(now: float) -> void:
	if server_copycat_stored_ability_id == ABILITY_NONE:
		return
	if (
		server_copycat_stored_expires_at > 0.0
		and now >= server_copycat_stored_expires_at
	):
		server_copycat_stored_ability_id = ABILITY_NONE
		server_copycat_stored_expires_at = 0.0
		draft_perk_copycat_uses_remaining = 0
		_receive_copycat_memory_cleared.rpc()


func _server_consume_copycat_memory() -> void:
	if not multiplayer.is_server():
		return
	if draft_perk_id == 58 and draft_perk_copycat_uses_remaining > 1:
		draft_perk_copycat_uses_remaining -= 1
		return
	draft_perk_copycat_uses_remaining = 0
	server_copycat_stored_ability_id = ABILITY_NONE
	server_copycat_stored_expires_at = 0.0
	_receive_copycat_memory_cleared.rpc()


func _get_ability_facing_direction() -> Vector2:
	var facing := server_direction.normalized()
	if not facing.is_zero_approx():
		return facing
	facing = linear_velocity.normalized()
	if not facing.is_zero_approx():
		return facing
	var ball := _get_closest_ball_in_kick_area()
	if ball != null:
		return global_position.direction_to(ball.global_position)
	return Vector2.ZERO


func _server_update_reflex_block() -> void:
	var radius := maxf(0.0, reflex_block_radius)
	var facing := server_reflex_facing.normalized()
	if radius <= 0.0 or facing.is_zero_approx():
		return

	var minimum_dot := cos(
		deg_to_rad(
			clampf(reflex_block_cone_degrees, 1.0, 179.0)
			* 0.5
		)
	)
	var closest_ball: FootballBall = null
	var closest_distance := radius
	for node in get_tree().get_nodes_in_group("football_balls"):
		var ball := node as FootballBall
		if (
			ball == null
			or ball.get_instance_id()
			== server_reflex_blocked_ball_id
			or ball.linear_velocity.length()
			< maxf(0.0, reflex_block_minimum_ball_speed)
		):
			continue

		var offset := ball.global_position - global_position
		var distance := offset.length()
		if (
			distance <= closest_distance
			and not offset.is_zero_approx()
			and facing.dot(offset.normalized()) >= minimum_dot
		):
			closest_distance = distance
			closest_ball = ball

	if closest_ball == null:
		return

	server_reflex_blocked_ball_id = closest_ball.get_instance_id()
	var deflect_facing := facing
	if draft_perk_id == 59:
		var attacking_goal := _get_attacking_goal()
		if attacking_goal != null:
			var mouth_range := attacking_goal.get_mouth_y_range()
			var goal_center := Vector2(
				attacking_goal.get_goal_plane_x(),
				(mouth_range.x + mouth_range.y) * 0.5
			)
			var goal_direction := (
				closest_ball.global_position.direction_to(goal_center)
			)
			if not goal_direction.is_zero_approx():
				deflect_facing = goal_direction
	closest_ball.reflex_deflect(
		global_position,
		deflect_facing,
		reflex_block_deflection_degrees,
		reflex_block_speed_retention
		* server_ability_strength_scale,
		reflex_block_speed_limit
		* server_ability_strength_scale,
		owner_peer_id,
		display_name,
		team,
		cpu_controlled
	)
	_receive_reflex_block_sound.rpc()


func _update_meta_vision_visual() -> void:
	var should_show := (
		_is_local_player()
		and local_ability_active
		and local_active_ability_id == ABILITY_META_VISION
	)
	if not should_show:
		_hide_meta_vision_analysis()
		return

	var ball: FootballBall = null
	for node in get_tree().get_nodes_in_group("football_balls"):
		ball = node as FootballBall
		if ball != null:
			break
	if ball == null:
		_hide_meta_vision_analysis()
		return

	var point := ball.global_position
	var velocity := ball.linear_velocity
	var prediction_samples: Array[Vector2] = [point]
	var step_seconds := maxf(
		0.01,
		meta_vision_prediction_step_seconds
	)
	var steps := maxi(4, meta_vision_prediction_steps)
	var ball_radius := _get_meta_vision_ball_radius(ball)
	var bounce_factor := 1.0
	var physics_material := ball.physics_material_override
	if physics_material != null:
		bounce_factor = clampf(
			physics_material.bounce,
			0.0,
			1.0
		)
	meta_vision_trajectory.clear_points()
	meta_vision_trajectory.add_point(to_local(point))
	for _step in range(steps):
		var remaining_seconds := step_seconds
		var bounce_attempts := 0
		while (
			remaining_seconds > 0.0001
			and not velocity.is_zero_approx()
			and bounce_attempts < 3
		):
			var segment_end := (
				point + velocity * remaining_seconds
			)
			var query := PhysicsRayQueryParameters2D.create(
				point,
				segment_end,
				meta_vision_wall_collision_mask
			)
			query.collide_with_areas = false
			query.collide_with_bodies = true
			var collision := (
				get_world_2d()
				.direct_space_state
				.intersect_ray(query)
			)
			if collision.is_empty():
				point = segment_end
				remaining_seconds = 0.0
				break

			var collision_position: Vector2 = collision.position
			var collision_normal: Vector2 = (
				collision.normal as Vector2
			).normalized()
			if collision_normal.is_zero_approx():
				point = segment_end
				remaining_seconds = 0.0
				break

			var contact_center := (
				collision_position
				+ collision_normal
				* (
					ball_radius
					+ maxf(0.0, meta_vision_collision_margin)
				)
			)
			var segment_distance := maxf(
				0.001,
				velocity.length() * remaining_seconds
			)
			var traveled_fraction := clampf(
				point.distance_to(contact_center)
				/ segment_distance,
				0.0,
				1.0
			)
			point = contact_center
			meta_vision_trajectory.add_point(
				to_local(point)
			)
			velocity = (
				velocity.bounce(collision_normal)
				* bounce_factor
			)
			remaining_seconds *= 1.0 - traveled_fraction
			bounce_attempts += 1

		if bounce_attempts >= 3 and remaining_seconds > 0.0:
			point += velocity * remaining_seconds
		velocity /= (
			1.0
			+ maxf(0.0, ball.linear_damp) * step_seconds
		)
		var local_point := to_local(point)
		var last_point_index := (
			meta_vision_trajectory.get_point_count() - 1
		)
		if (
			last_point_index < 0
			or meta_vision_trajectory.get_point_position(
				last_point_index
			).distance_squared_to(local_point) > 0.01
		):
			meta_vision_trajectory.add_point(local_point)
		prediction_samples.append(point)

	meta_vision_landing_marker.clear_points()
	var marker_radius := 55.0
	var marker_segments := 24
	for marker_index in range(marker_segments + 1):
		var angle := TAU * float(marker_index) / marker_segments
		meta_vision_landing_marker.add_point(
			to_local(point)
			+ Vector2.from_angle(angle) * marker_radius
		)
	meta_vision_trajectory.show()
	meta_vision_landing_marker.show()
	_update_meta_vision_intercepts(
		prediction_samples,
		step_seconds
	)
	_update_meta_vision_goal_danger(
		prediction_samples,
		ball.linear_velocity.length()
	)


func _hide_meta_vision_analysis() -> void:
	meta_vision_trajectory.hide()
	meta_vision_landing_marker.hide()
	meta_vision_intercept_path.hide()
	meta_vision_own_intercept_marker.hide()
	meta_vision_enemy_intercept_marker.hide()
	_set_meta_vision_danger_goal(null)


func _update_meta_vision_intercepts(
	prediction_samples: Array[Vector2],
	step_seconds: float
) -> void:
	var own_intercept := _find_meta_vision_intercept(
		self,
		prediction_samples,
		step_seconds
	)
	if own_intercept.is_empty():
		meta_vision_intercept_path.hide()
		meta_vision_own_intercept_marker.hide()
	else:
		var own_point: Vector2 = own_intercept.get(
			"point",
			global_position
		)
		meta_vision_intercept_path.clear_points()
		meta_vision_intercept_path.add_point(Vector2.ZERO)
		meta_vision_intercept_path.add_point(to_local(own_point))
		meta_vision_intercept_path.default_color = (
			meta_vision_own_intercept_color
		)
		_draw_meta_vision_intercept_marker(
			meta_vision_own_intercept_marker,
			own_point,
			meta_vision_own_intercept_color
		)
		meta_vision_intercept_path.show()
		meta_vision_own_intercept_marker.show()

	var earliest_enemy_intercept: Dictionary = {}
	for node in get_parent().get_children():
		var enemy := node as FootballPlayer
		if (
			enemy == null
			or enemy == self
			or enemy.team == &""
			or enemy.team == team
		):
			continue
		var enemy_intercept := _find_meta_vision_intercept(
			enemy,
			prediction_samples,
			step_seconds
		)
		if enemy_intercept.is_empty():
			continue
		if (
			earliest_enemy_intercept.is_empty()
			or float(enemy_intercept.get("time", INF))
			< float(
				earliest_enemy_intercept.get("time", INF)
			)
		):
			earliest_enemy_intercept = enemy_intercept

	if earliest_enemy_intercept.is_empty():
		meta_vision_enemy_intercept_marker.hide()
	else:
		_draw_meta_vision_intercept_marker(
			meta_vision_enemy_intercept_marker,
			earliest_enemy_intercept.get(
				"point",
				global_position
			),
			meta_vision_enemy_intercept_color
		)
		meta_vision_enemy_intercept_marker.show()


func _find_meta_vision_intercept(
	candidate: FootballPlayer,
	prediction_samples: Array[Vector2],
	step_seconds: float
) -> Dictionary:
	if candidate == null:
		return {}
	for sample_index in range(1, prediction_samples.size()):
		var arrival_time := float(sample_index) * step_seconds
		var reachable_distance := (
			_get_meta_vision_reachable_distance(
				candidate,
				arrival_time
			)
			+ maxf(0.0, meta_vision_intercept_reach_margin)
		)
		var sample := prediction_samples[sample_index]
		if (
			candidate.global_position.distance_to(sample)
			<= reachable_distance
		):
			return {
				"point": sample,
				"time": arrival_time
			}
	return {}


func _get_meta_vision_reachable_distance(
	candidate: FootballPlayer,
	seconds: float
) -> float:
	var duration := maxf(0.0, seconds)
	var maximum_speed := maxf(0.0, candidate.max_speed)
	var starting_speed := minf(
		candidate.linear_velocity.length(),
		maximum_speed
	)
	var candidate_acceleration := maxf(
		0.0,
		candidate.acceleration
	)
	if candidate_acceleration <= 0.0:
		return starting_speed * duration

	var acceleration_time := maxf(
		0.0,
		(maximum_speed - starting_speed)
		/ candidate_acceleration
	)
	var accelerating_seconds := minf(duration, acceleration_time)
	var reachable_distance := (
		starting_speed * accelerating_seconds
		+ 0.5
		* candidate_acceleration
		* accelerating_seconds
		* accelerating_seconds
	)
	reachable_distance += (
		maximum_speed
		* maxf(0.0, duration - accelerating_seconds)
	)
	return reachable_distance


func _draw_meta_vision_intercept_marker(
	marker: Line2D,
	world_point: Vector2,
	color: Color
) -> void:
	marker.clear_points()
	var center := to_local(world_point)
	var radius := 64.0
	for offset in [
		Vector2(0.0, -radius),
		Vector2(radius, 0.0),
		Vector2(0.0, radius),
		Vector2(-radius, 0.0),
		Vector2(0.0, -radius)
	]:
		marker.add_point(center + offset)
	marker.default_color = color


func _update_meta_vision_goal_danger(
	prediction_samples: Array[Vector2],
	current_ball_speed: float
) -> void:
	if (
		current_ball_speed
		< maxf(0.0, meta_vision_danger_minimum_ball_speed)
	):
		_set_meta_vision_danger_goal(null)
		return

	var danger_goal: FootballGoal = null
	for node in get_tree().get_nodes_in_group("football_goals"):
		var goal := node as FootballGoal
		if goal == null:
			continue
		var goal_plane_x := goal.get_goal_plane_x()
		var mouth_range := goal.get_mouth_y_range()
		for index in range(1, prediction_samples.size()):
			var start := prediction_samples[index - 1]
			var finish := prediction_samples[index]
			var horizontal_travel := finish.x - start.x
			if (
				is_zero_approx(horizontal_travel)
				or (
					goal_plane_x - start.x
				) * (
					goal_plane_x - finish.x
				) > 0.0
			):
				continue
			var crossing_fraction := clampf(
				(goal_plane_x - start.x) / horizontal_travel,
				0.0,
				1.0
			)
			var crossing_y := lerpf(
				start.y,
				finish.y,
				crossing_fraction
			)
			if (
				crossing_y >= mouth_range.x
				and crossing_y <= mouth_range.y
			):
				danger_goal = goal
				break
		if danger_goal != null:
			break
	_set_meta_vision_danger_goal(danger_goal)


func _set_meta_vision_danger_goal(
	danger_goal: FootballGoal
) -> void:
	for node in get_tree().get_nodes_in_group("football_goals"):
		var goal := node as FootballGoal
		if goal != null:
			goal.set_meta_vision_danger_visible(
				goal == danger_goal
			)


func _get_meta_vision_ball_radius(ball: FootballBall) -> float:
	if ball == null:
		return 0.0

	var collision_shape := ball.get_node_or_null(
		"CollisionShape2D"
	) as CollisionShape2D
	if (
		collision_shape == null
		or not (collision_shape.shape is CircleShape2D)
	):
		return 0.0

	var circle := collision_shape.shape as CircleShape2D
	var shape_scale := collision_shape.global_transform.get_scale()
	return (
		maxf(0.0, circle.radius)
		* maxf(absf(shape_scale.x), absf(shape_scale.y))
	)


func _get_goalkeeper_reach_direction() -> Vector2:
	var reach_direction := server_direction.normalized()
	if not reach_direction.is_zero_approx():
		return reach_direction

	reach_direction = linear_velocity.normalized()
	if not reach_direction.is_zero_approx():
		return reach_direction

	var closest_ball: FootballBall = null
	var closest_distance := INF
	for node in get_tree().get_nodes_in_group("football_balls"):
		var ball := node as FootballBall
		if ball == null:
			continue
		var distance := global_position.distance_squared_to(
			ball.global_position
		)
		if distance < closest_distance:
			closest_distance = distance
			closest_ball = ball

	if closest_ball == null:
		return Vector2.ZERO

	return global_position.direction_to(
		closest_ball.global_position
	)


func _server_update_goalkeeper_reach() -> void:
	for body in goalkeeper_reach_area.get_overlapping_bodies():
		var ball := body as FootballBall
		if ball == null:
			continue

		var ball_id := ball.get_instance_id()
		if _goalkeeper_blocked_balls.has(ball_id):
			continue

		_goalkeeper_blocked_balls[ball_id] = true
		ball.block_from_goalkeeper(
			global_position,
			goalkeeper_ball_speed_retention,
			goalkeeper_ball_speed_limit,
			owner_peer_id,
			display_name,
			team,
			cpu_controlled
		)


func _get_defending_goal() -> FootballGoal:
	for node in get_tree().get_nodes_in_group("football_goals"):
		var goal := node as FootballGoal
		if (
			goal != null
			and StringName(goal.defending_team) == team
		):
			return goal
	return null


func _sanitize_cpu_ball_impulse(
	ball_target: FootballBall,
	proposed_impulse: Vector2,
	touch_kind: StringName
) -> Vector2:
	if (
		not cpu_controlled
		or not cpu_own_goal_prevention_enabled
		or ball_target == null
		or proposed_impulse.is_zero_approx()
	):
		return proposed_impulse

	var own_goal: FootballGoal = _get_defending_goal()
	if own_goal == null:
		return proposed_impulse
	var goal_center: Vector2 = Vector2(
		own_goal.get_goal_plane_x(),
		(
			own_goal.get_mouth_y_range().x
			+ own_goal.get_mouth_y_range().y
		) * 0.5
	)
	if (
		ball_target.global_position.distance_to(goal_center)
		> maxf(300.0, cpu_own_goal_hard_zone_distance)
	):
		return proposed_impulse

	var safe_mass: float = maxf(0.001, ball_target.mass)
	var predicted_velocity: Vector2 = (
		ball_target.linear_velocity
		+ proposed_impulse / safe_mass
	)
	if not _cpu_velocity_crosses_own_goal(
		ball_target.global_position,
		predicted_velocity,
		own_goal
	):
		return proposed_impulse

	var away_x: float = (
		1.0
		if ball_target.global_position.x
		>= own_goal.get_goal_plane_x()
		else -1.0
	)
	var mouth_center_y: float = goal_center.y
	var lateral_sign: float = (
		-1.0
		if ball_target.global_position.y < mouth_center_y
		else 1.0
	)
	var safe_direction: Vector2 = Vector2(
		away_x,
		lateral_sign * cpu_own_goal_safe_lateral_weight
	).normalized()
	var desired_speed: float = maxf(
		cpu_own_goal_safe_forward_speed,
		predicted_velocity.length() * 0.72
	)
	var safe_velocity: Vector2 = safe_direction * desired_speed
	var corrected_impulse: Vector2 = (
		safe_velocity - ball_target.linear_velocity
	) * safe_mass

	_record_cpu_own_goal_safety_event(
		&"redirect",
		touch_kind
	)
	return corrected_impulse


func _cpu_velocity_crosses_own_goal(
	ball_position: Vector2,
	velocity: Vector2,
	own_goal: FootballGoal
) -> bool:
	if velocity.length() < cpu_own_goal_minimum_toward_speed:
		return false
	if absf(velocity.x) < 0.001:
		return false

	var position: Vector2 = ball_position
	var simulated_velocity: Vector2 = velocity
	var remaining_seconds: float = maxf(
		0.1,
		cpu_own_goal_prediction_seconds
	)
	var top_y: float = heel_turn_ball_minimum_y
	var bottom_y: float = heel_turn_ball_maximum_y
	var mouth: Vector2 = own_goal.get_mouth_y_range()
	var goal_x: float = own_goal.get_goal_plane_x()

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
				>= mouth.x - cpu_own_goal_mouth_padding
				and predicted_y
				<= mouth.y + cpu_own_goal_mouth_padding
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


func _get_active_playfield_root() -> Node:
	var current_scene: Node = get_tree().current_scene
	if current_scene == null:
		return null
	if current_scene.get_node_or_null("MatchManager") != null:
		return current_scene
	# The optional supersampling render root keeps Playfield as the real game
	# world inside a SubViewport. Resolve it transparently so world-space VFX and
	# match-manager lookups keep behaving exactly like the legacy direct scene.
	var nested_playfield := current_scene.find_child("Playfield", true, false)
	if nested_playfield != null:
		return nested_playfield
	return current_scene


func _record_cpu_own_goal_safety_event(
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
		team,
		event_kind,
		touch_kind,
		owner_peer_id
	)


func _get_attacking_goal() -> FootballGoal:
	for node in get_tree().get_nodes_in_group("football_goals"):
		var goal := node as FootballGoal
		if (
			goal != null
			and StringName(goal.defending_team) != team
		):
			return goal
	return null


func _get_curve_shot_blocker(
	ball_target: FootballBall,
	shot_direction: Vector2
) -> Dictionary:
	var direction := shot_direction.normalized()
	if ball_target == null or direction.is_zero_approx():
		return {}

	var perpendicular := Vector2(-direction.y, direction.x)
	# Human Curve Shot uses the same simple side-selection language as Side Swipe:
	# hold the side you want the ball to bend toward. CPUs keep their existing
	# automatic blocker choice so their movement intent does not accidentally steer shots.
	var requested_curve_side: float = _get_curve_input_turn_direction(
		ball_target,
		direction
	)
	var maximum_range := maxf(0.0, curve_shot_blocker_search_radius)
	var minimum_forward := maxf(
		0.0,
		curve_shot_blocker_minimum_forward_distance
	)
	var lane_half_width := maxf(
		0.0,
		curve_shot_lane_half_width
	)
	var best_forward := INF
	var result: Dictionary = {}
	for node in get_parent().get_children():
		var candidate := node as FootballPlayer
		if (
			candidate == null
			or candidate == self
			or candidate.team == &""
			or candidate.team == team
			or global_position.distance_to(
				candidate.global_position
			) > maximum_range
		):
			continue

		var offset := (
			candidate.global_position
			- ball_target.global_position
		)
		var forward := offset.dot(direction)
		var lateral := offset.dot(perpendicular)
		if (
			forward < minimum_forward
			or forward > maximum_range
			or absf(lateral) > lane_half_width
			or forward >= best_forward
		):
			continue

		var avoidance_side: float = requested_curve_side
		if is_zero_approx(avoidance_side):
			avoidance_side = -signf(lateral)
		if is_zero_approx(avoidance_side):
			avoidance_side = _get_curve_turn_direction(
				ball_target,
				direction
			)
		if is_zero_approx(avoidance_side):
			avoidance_side = 1.0
		best_forward = forward
		result = {
			"position": candidate.global_position,
			"side": avoidance_side
		}
	return result


func _get_curve_input_turn_direction(
	ball_target: FootballBall,
	shot_direction: Vector2 = Vector2.ZERO
) -> float:
	# CPU movement is tactical intent, not a player's curve-direction command.
	# Keep CPU Curve Shot steering on the existing automatic behavior.
	if cpu_controlled or ball_target == null:
		return 0.0
	var direction: Vector2 = shot_direction.normalized()
	if direction.is_zero_approx():
		direction = global_position.direction_to(ball_target.global_position)
	if direction.is_zero_approx():
		return 0.0
	var input_direction: Vector2 = server_direction.normalized()
	if input_direction.is_zero_approx():
		return 0.0
	var positive_side := Vector2(-direction.y, direction.x).normalized()
	var negative_side := -positive_side
	var positive_score: float = input_direction.dot(positive_side)
	var negative_score: float = input_direction.dot(negative_side)
	# Match Side Swipe's dead-zone so a mostly forward/back movement input does
	# not unexpectedly flip the curve. A clear side hold selects that side.
	if absf(positive_score - negative_score) <= 0.08:
		return 0.0
	return 1.0 if positive_score > negative_score else -1.0


func _get_curve_turn_direction(
	ball_target: FootballBall,
	shot_direction: Vector2 = Vector2.ZERO
) -> float:
	var requested_direction: float = _get_curve_input_turn_direction(
		ball_target,
		shot_direction
	)
	if not is_zero_approx(requested_direction):
		return requested_direction

	# No deliberate side input: preserve the previous automatic curve choice.
	var target_goal := _get_attacking_goal()
	if target_goal == null:
		return 0.0

	var mouth_range := target_goal.get_mouth_y_range()
	var goal_center_y := (mouth_range.x + mouth_range.y) * 0.5
	var vertical_direction := signf(
		goal_center_y - global_position.y
	)
	var horizontal_direction := signf(
		target_goal.get_goal_plane_x() - global_position.x
	)
	if (
		is_zero_approx(vertical_direction)
		or is_zero_approx(horizontal_direction)
	):
		return 0.0

	# Vector2 rotation changes vertical direction based on whether
	# the ball travels left or right, so both signs are needed.
	return vertical_direction * horizontal_direction


func _get_curve_assisted_kick_direction(
	base_direction: Vector2,
	ball_target: FootballBall
) -> Vector2:
	var safe_base := base_direction.normalized()
	var target_goal := _get_attacking_goal()
	if (
		safe_base.is_zero_approx()
		or target_goal == null
		or ball_target == null
	):
		return safe_base

	var mouth_range := target_goal.get_mouth_y_range()
	var goal_center := Vector2(
		target_goal.get_goal_plane_x(),
		(mouth_range.x + mouth_range.y) * 0.5
	)
	var goal_direction := ball_target.global_position.direction_to(
		goal_center
	)
	if (
		goal_direction.is_zero_approx()
		or safe_base.dot(goal_direction) <= 0.0
	):
		return safe_base

	var angle_to_goal := safe_base.angle_to(goal_direction)
	var maximum_correction := deg_to_rad(
		maxf(0.0, curve_shot_max_aim_correction_degrees)
	)
	var correction := clampf(
		angle_to_goal
		* clampf(curve_shot_goal_assist_strength, 0.0, 1.0)
		* server_ability_strength_scale,
		-maximum_correction,
		maximum_correction
	)
	return safe_base.rotated(correction).normalized()


func _server_time_skip_pass(
	strength_scale: float = 1.0
) -> bool:
	var closest_ball: FootballBall = null
	var closest_distance := INF
	for body in kick_area.get_overlapping_bodies():
		var ball := body as FootballBall
		if ball == null:
			continue
		var distance := global_position.distance_squared_to(
			ball.global_position
		)
		if distance < closest_distance:
			closest_distance = distance
			closest_ball = ball

	if closest_ball == null:
		cpu_clear_time_skip_pass_route()
		return false

	var preferred_direction := server_direction.normalized()
	var has_explicit_cpu_target := (
		cpu_controlled
		and not _cpu_time_skip_pass_target.is_zero_approx()
	)
	# A CPU may deliberately aim Dead Zone at a reachable point in the goal.
	# receiver_peer_id == 0 + an explicit target means "do not auto-retarget
	# this into a teammate pass". Normal human/self-pass behavior is unchanged.
	var receiver: FootballPlayer = null
	if not (has_explicit_cpu_target and _cpu_time_skip_pass_receiver_peer_id <= 0):
		receiver = _get_time_skip_pass_receiver(
			closest_ball.global_position,
			preferred_direction
		)
	if _cpu_time_skip_pass_receiver_peer_id > 0:
		var planned_receiver := _get_time_skip_pass_receiver_by_peer_id(
			_cpu_time_skip_pass_receiver_peer_id
		)
		if planned_receiver == null:
			# An explicit CPU route must never silently retarget to somebody else.
			cpu_clear_time_skip_pass_route()
			return false
		receiver = planned_receiver
	var target_position := Vector2.ZERO
	if receiver != null:
		target_position = _cpu_time_skip_pass_target
		if target_position.is_zero_approx():
			target_position = (
				receiver.global_position
				+ receiver.linear_velocity
				* maxf(0.0, time_skip_pass_receiver_lead_seconds)
			)
		var maximum_receiver_distance := minf(
			maxf(300.0, time_skip_pass_maximum_receiver_distance),
			cpu_get_time_skip_pass_maximum_travel_distance(strength_scale)
		)
		if (
			target_position.is_zero_approx()
			or closest_ball.global_position.distance_to(target_position)
			> maximum_receiver_distance * 0.985
		):
			# Dead Zone decelerates to a stop; a target outside its real maximum
			# range is not a valid enhanced pass and must not be fired.
			cpu_clear_time_skip_pass_route()
			return false
	elif has_explicit_cpu_target:
		target_position = _cpu_time_skip_pass_target
		var maximum_travel_distance := (
			cpu_get_time_skip_pass_maximum_travel_distance(strength_scale)
		)
		if (
			target_position.is_zero_approx()
			or closest_ball.global_position.distance_to(target_position)
			> maximum_travel_distance * 0.985
		):
			cpu_clear_time_skip_pass_route()
			return false

	var pass_direction := preferred_direction
	if receiver != null or not target_position.is_zero_approx():
		pass_direction = closest_ball.global_position.direction_to(
			target_position
		)
	if pass_direction.is_zero_approx():
		var attacking_goal := _get_attacking_goal()
		if attacking_goal != null:
			var mouth_range := attacking_goal.get_mouth_y_range()
			var goal_center := Vector2(
				attacking_goal.get_goal_plane_x(),
				(mouth_range.x + mouth_range.y) * 0.5
			)
			pass_direction = closest_ball.global_position.direction_to(
				goal_center
			)
	if pass_direction.is_zero_approx():
		pass_direction = global_position.direction_to(
			closest_ball.global_position
		)
	if pass_direction.is_zero_approx():
		pass_direction = linear_velocity.normalized()
	if pass_direction.is_zero_approx():
		pass_direction = Vector2.RIGHT
	var emergency_self_exit := receiver == null and draft_perk_id == 55
	if receiver == null:
		var self_distance := maxf(300.0, time_skip_pass_self_distance)
		if emergency_self_exit:
			self_distance *= 1.65
		target_position = (
			closest_ball.global_position
			+ pass_direction * self_distance
		)

	var safe_initial_speed := (
		maxf(1.0, time_skip_pass_initial_speed)
		* clampf(strength_scale, 0.1, 1.0)
	)
	var slow_speed := maxf(0.0, time_skip_pass_slow_speed)
	var deceleration := maxf(0.001, time_skip_pass_stopping_deceleration)
	var slow_phase_distance := slow_speed * slow_speed / (2.0 * deceleration)
	var target_distance := closest_ball.global_position.distance_to(
		target_position
	)
	var fast_duration := clampf(
		(target_distance - slow_phase_distance) / safe_initial_speed,
		maxf(0.02, time_skip_pass_minimum_fast_duration),
		maxf(
			maxf(0.02, time_skip_pass_minimum_fast_duration),
			time_skip_pass_maximum_fast_duration
		)
	)

	closest_ball.start_time_skip_pass(
		pass_direction,
		safe_initial_speed,
		fast_duration,
		time_skip_pass_slow_speed,
		time_skip_pass_stopping_deceleration,
		time_skip_pass_stop_speed,
		owner_peer_id,
		display_name,
		team
	)
	_receive_dead_zone_pass_sound.rpc()
	if emergency_self_exit:
		_grant_draft_perk_movement_boost(1.24, 1.55, 1.35)
	cpu_clear_time_skip_pass_route()
	return true


func _get_time_skip_pass_receiver_by_peer_id(
	peer_id: int
) -> FootballPlayer:
	if get_parent() == null or peer_id <= 0:
		return null
	for sibling in get_parent().get_children():
		var candidate := sibling as FootballPlayer
		if (
			candidate != null
			and candidate.owner_peer_id == peer_id
			and candidate.team == team
			and candidate.controls_enabled
		):
			return candidate
	return null


func _get_time_skip_pass_receiver(
	ball_position: Vector2,
	preferred_direction: Vector2
) -> FootballPlayer:
	if get_parent() == null or team == &"":
		return null
	var best_receiver: FootballPlayer = null
	var best_score := INF
	var maximum_distance := maxf(
		300.0,
		time_skip_pass_maximum_receiver_distance
	)
	var minimum_direction_dot := cos(
		deg_to_rad(
			clampf(time_skip_pass_receiver_cone_degrees, 10.0, 180.0)
			* 0.5
		)
	)
	for sibling in get_parent().get_children():
		var candidate := sibling as FootballPlayer
		if (
			candidate == null
			or candidate == self
			or candidate.team != team
			or not candidate.controls_enabled
			or candidate.training_dummy
		):
			continue
		var target_position := (
			candidate.global_position
			+ candidate.linear_velocity
			* maxf(0.0, time_skip_pass_receiver_lead_seconds)
		)
		var target_distance := ball_position.distance_to(target_position)
		if target_distance > maximum_distance:
			continue
		var target_direction := ball_position.direction_to(target_position)
		var direction_dot := 1.0
		if not preferred_direction.is_zero_approx():
			direction_dot = preferred_direction.dot(target_direction)
			if direction_dot < minimum_direction_dot:
				continue
		var candidate_score := (
			target_distance + (1.0 - direction_dot) * 1800.0
		)
		if candidate_score < best_score:
			best_score = candidate_score
			best_receiver = candidate
	return best_receiver


func _server_heel_turn(
	strength_scale: float = 1.0,
	cooldown: float = -1.0
) -> bool:
	for body in kick_area.get_overlapping_bodies():
		var ball := body as FootballBall
		if ball == null:
			continue

		var ball_direction := global_position.direction_to(
			ball.global_position
		)
		if ball_direction.is_zero_approx():
			ball_direction = server_direction.normalized()
		if ball_direction.is_zero_approx():
			ball_direction = Vector2.RIGHT

		var behind_direction: Vector2 = _get_phantom_heel_exit_direction(
			ball,
			ball_direction
		)
		var previous_ball_position := ball.global_position
		var target_ball_position := (
			global_position
			+ behind_direction
			* heel_turn_ball_distance
			* clampf(strength_scale, 0.1, 1.0)
		)
		target_ball_position = _clamp_phantom_heel_ball_target(
			target_ball_position
		)
		ball.redirect_ball(
			target_ball_position,
			behind_direction
			* heel_turn_ball_speed
			* clampf(strength_scale, 0.1, 1.0),
			owner_peer_id,
			display_name,
			team,
			cpu_controlled
		)
		server_phantom_heel_ball_id = int(ball.get_instance_id())
		server_phantom_heel_drag_direction = behind_direction
		server_phantom_heel_followup_ready_at = (
			_server_time_seconds() + maxf(0.0, heel_turn_followup_delay)
		)
		_start_server_effect(
			maxf(
				0.1,
				heel_turn_followup_window
					+ (0.75 if draft_perk_id == 52 else 0.0)
			),
			_get_ability_cooldown_for(ABILITY_HEEL_TURN)
			if cooldown < 0.0
			else cooldown,
			ABILITY_HEEL_TURN,
			strength_scale
		)
		_receive_phantom_heel_vfx.rpc(
			previous_ball_position,
			target_ball_position
		)
		return true

	return false


func _server_execute_phantom_heel_followup() -> bool:
	if (
		not multiplayer.is_server()
		or not _server_ability_is_active(ABILITY_HEEL_TURN)
		or _server_time_seconds() < server_phantom_heel_followup_ready_at
	):
		return false
	var ball: FootballBall = _get_ball_by_instance_id(server_phantom_heel_ball_id)
	var followup_reach := (
		maxf(kick_feedback_detection_distance, heel_turn_ball_distance) + 90.0
	) * (2.15 if draft_perk_id == 52 else 1.0)
	if (
		ball == null
		or global_position.distance_to(ball.global_position) > followup_reach
	):
		return false
	var direction: Vector2 = _get_phantom_heel_followup_direction(ball)
	if direction.is_zero_approx():
		return false
	var strength: float = clampf(server_ability_strength_scale, 0.1, 1.0)
	var previous_ball_position: Vector2 = ball.global_position
	var target_position: Vector2 = _clamp_phantom_heel_ball_target(
		ball.global_position
		+ direction * maxf(1.0, heel_turn_followup_ball_distance) * strength
	)
	var target_velocity: Vector2 = (
		direction
		* maxf(0.0, heel_turn_followup_ball_speed)
		* strength
	)
	ball.redirect_ball(
		target_position,
		target_velocity,
		owner_peer_id,
		display_name,
		team,
		cpu_controlled
	)
	linear_velocity = direction * maxf(0.0, heel_turn_followup_player_step_speed) * strength
	_receive_phantom_heel_vfx.rpc(previous_ball_position, target_position)
	var cooldown: float = server_pending_cooldown
	server_pending_cooldown = 0.0
	_clear_phantom_heel_followup()
	_start_server_cooldown(cooldown, ABILITY_HEEL_TURN)
	return true


func _get_phantom_heel_followup_direction(ball: FootballBall) -> Vector2:
	var forward: Vector2 = _get_breakaway_attack_direction()
	if forward.is_zero_approx():
		forward = -server_phantom_heel_drag_direction
	if forward.is_zero_approx():
		forward = Vector2.RIGHT
	var drag_side: Vector2 = server_phantom_heel_drag_direction.slide(forward).normalized()
	if drag_side.is_zero_approx():
		drag_side = Vector2(-forward.y, forward.x).normalized()
	var opposite_side: Vector2 = -drag_side
	var default_direction: Vector2 = (
		forward
		+ opposite_side * maxf(0.0, heel_turn_followup_side_weight)
	).normalized()
	var requested: Vector2 = server_direction.normalized()
	if not requested.is_zero_approx() and requested.dot(forward) > -0.15:
		var requested_direction: Vector2 = (
			forward
			+ requested * maxf(0.0, heel_turn_followup_side_weight)
		).normalized()
		if not requested_direction.is_zero_approx():
			return requested_direction
	if ball == null:
		return default_direction
	var alternate: Vector2 = (
		forward
		+ drag_side * maxf(0.0, heel_turn_followup_side_weight)
	).normalized()
	var default_clearance: float = _get_side_swipe_lane_clearance(
		ball.global_position,
		default_direction,
		heel_turn_lane_probe_distance
	)
	var alternate_clearance: float = _get_side_swipe_lane_clearance(
		ball.global_position,
		alternate,
		heel_turn_lane_probe_distance
	)
	return default_direction if default_clearance >= alternate_clearance else alternate


func _clear_phantom_heel_followup() -> void:
	server_phantom_heel_ball_id = 0
	server_phantom_heel_drag_direction = Vector2.ZERO
	server_phantom_heel_followup_ready_at = 0.0


func _get_phantom_heel_exit_direction(
	ball: FootballBall,
	ball_direction: Vector2
) -> Vector2:
	var backward: Vector2 = -ball_direction.normalized()
	if backward.is_zero_approx():
		backward = -_get_breakaway_attack_direction()
	if backward.is_zero_approx():
		backward = Vector2.LEFT
	var angle: float = deg_to_rad(
		clampf(heel_turn_exit_angle_degrees, 10.0, 80.0)
	)
	var option_a: Vector2 = backward.rotated(angle).normalized()
	var option_b: Vector2 = backward.rotated(-angle).normalized()
	var requested: Vector2 = server_direction.normalized()
	if not requested.is_zero_approx():
		var requested_a: float = requested.dot(option_a)
		var requested_b: float = requested.dot(option_b)
		if absf(requested_a - requested_b) > 0.08:
			return option_a if requested_a > requested_b else option_b
	var origin: Vector2 = global_position if ball == null else ball.global_position
	var clearance_a: float = _get_side_swipe_lane_clearance(
		origin,
		option_a,
		heel_turn_lane_probe_distance
	)
	var clearance_b: float = _get_side_swipe_lane_clearance(
		origin,
		option_b,
		heel_turn_lane_probe_distance
	)
	return option_a if clearance_a >= clearance_b else option_b


func _clamp_phantom_heel_ball_target(target: Vector2) -> Vector2:
	var safe_target := target
	safe_target.y = clampf(
		safe_target.y,
		heel_turn_ball_minimum_y,
		heel_turn_ball_maximum_y
	)
	if (
		safe_target.x < heel_turn_ball_minimum_x
		or safe_target.x > heel_turn_ball_maximum_x
	):
		if not _target_is_inside_goal_mouth(safe_target):
			safe_target.x = clampf(
				safe_target.x,
				heel_turn_ball_minimum_x,
				heel_turn_ball_maximum_x
			)
	return safe_target


func _target_is_inside_goal_mouth(target: Vector2) -> bool:
	for node in get_tree().get_nodes_in_group("football_goals"):
		var goal := node as FootballGoal
		if goal == null:
			continue
		var mouth_range := goal.get_mouth_y_range()
		if target.y >= mouth_range.x and target.y <= mouth_range.y:
			return true
	return false


@rpc("authority", "call_local", "reliable")
func _receive_phantom_heel_vfx(
	previous_ball_position: Vector2,
	target_ball_position: Vector2
) -> void:
	# Play first. The supplied source is trimmed to remove its silent lead-in,
	# and WAV decoding avoids the delayed MP3 start.
	_play_local_ability_sound(
		PHANTOM_HEEL_SOUND,
		phantom_heel_sound_pitch_scale,
		phantom_heel_sound_volume_db
	)

	var effect_parent := _get_active_playfield_root()
	if effect_parent == null:
		return
	_spawn_phantom_heel_shadow(
		effect_parent,
		previous_ball_position
	)
	_spawn_phantom_heel_particles(
		effect_parent,
		previous_ball_position,
		phantom_heel_particle_color.darkened(0.28),
		0.82
	)
	_spawn_phantom_heel_particles(
		effect_parent,
		target_ball_position,
		phantom_heel_particle_color,
		1.0
	)


@rpc("authority", "call_local", "reliable")
func _receive_blind_spot_vfx(
	start_position: Vector2,
	target_position: Vector2
) -> void:
	var effect_parent := _get_active_playfield_root()
	if effect_parent == null:
		return

	var travel := target_position - start_position
	if travel.is_zero_approx():
		return

	# Mirage Step is a fast spatial slip, so the sound and electricity fire at
	# the actual teleport moment instead of on the earlier ability button press.
	_play_world_ability_one_shot(
		MIRAGE_STEP_SOUND,
		start_position.lerp(target_position, 0.5),
		-3.0,
		1.0
	)
	_spawn_mirage_lightning_path(
		effect_parent,
		start_position,
		target_position
	)
	_spawn_mirage_spark_burst(effect_parent, start_position, 0.88)
	_spawn_mirage_spark_burst(effect_parent, target_position, 1.12)

	_play_mirage_step_shadow(
		effect_parent,
		start_position,
		target_position
	)

	var particles := CPUParticles2D.new()
	particles.name = "BlindSpotParticles"
	particles.top_level = true
	particles.z_index = 5
	particles.emitting = false
	particles.one_shot = true
	particles.amount = maxi(8, blind_spot_particle_amount)
	particles.texture = MIRAGE_STEP_PARTICLE_TEXTURE
	particles.lifetime = maxf(
		0.08,
		blind_spot_particle_lifetime
	)
	particles.explosiveness = 0.96
	particles.local_coords = false
	particles.emission_shape = (
		CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	)
	particles.emission_rect_extents = Vector2(
		travel.length() * 0.5,
		maxf(1.0, blind_spot_particle_path_width)
	)
	particles.direction = Vector2.LEFT
	particles.spread = 32.0
	particles.gravity = Vector2.ZERO
	particles.initial_velocity_min = maxf(
		0.0,
		blind_spot_particle_speed_min
	)
	particles.initial_velocity_max = maxf(
		particles.initial_velocity_min,
		blind_spot_particle_speed_max
	)
	particles.scale_amount_min = maxf(
		0.02,
		blind_spot_particle_scale_min
	)
	particles.scale_amount_max = maxf(
		particles.scale_amount_min,
		blind_spot_particle_scale_max
	)
	particles.color = blind_spot_trail_color
	effect_parent.add_child(particles)
	particles.global_position = start_position + travel * 0.5
	particles.global_rotation = travel.angle()
	particles.restart()

	var cleanup := particles.create_tween()
	cleanup.tween_interval(particles.lifetime + 0.2)
	cleanup.tween_callback(particles.queue_free)


func _spawn_mirage_lightning_path(
	effect_parent: Node,
	start_position: Vector2,
	target_position: Vector2
) -> void:
	var travel := target_position - start_position
	if travel.length_squared() < 64.0:
		return
	var direction := travel.normalized()
	var normal := direction.orthogonal()
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var bolt_colors: Array[Color] = [
		Color(0.92, 0.68, 1.0, 0.98),
		Color(0.74, 0.36, 1.0, 0.94),
		Color(0.54, 0.20, 0.96, 0.88),
	]
	for bolt_index in range(3):
		var bolt := Line2D.new()
		bolt.name = "MirageLightning%d" % bolt_index
		bolt.top_level = true
		bolt.z_index = 9
		bolt.width = 5.0 if bolt_index == 0 else 2.8
		bolt.default_color = bolt_colors[bolt_index]
		bolt.antialiased = true
		var points := PackedVector2Array()
		var segment_count := 9
		for segment_index in range(segment_count + 1):
			var t := float(segment_index) / float(segment_count)
			var base_point := travel * t
			var edge_falloff := sin(PI * t)
			var side_jitter := rng.randf_range(-30.0, 30.0) * edge_falloff
			var forward_jitter := rng.randf_range(-8.0, 8.0) * edge_falloff
			points.append(
				base_point
				+ normal * side_jitter
				+ direction * forward_jitter
			)
		bolt.points = points
		bolt.modulate.a = 0.0
		effect_parent.add_child(bolt)
		bolt.global_position = start_position
		var flash := bolt.create_tween()
		flash.tween_property(bolt, "modulate:a", 1.0, 0.018)
		flash.tween_interval(0.035 + float(bolt_index) * 0.012)
		flash.tween_property(bolt, "modulate:a", 0.0, 0.10)
		flash.tween_callback(bolt.queue_free)


func _spawn_mirage_spark_burst(
	effect_parent: Node,
	position: Vector2,
	intensity: float
) -> void:
	var sparks := CPUParticles2D.new()
	sparks.name = "MirageLightningSparks"
	sparks.top_level = true
	sparks.z_index = 10
	sparks.emitting = false
	sparks.one_shot = true
	sparks.amount = maxi(8, int(round(18.0 * intensity)))
	sparks.texture = ABILITY_PARTICLE_TEXTURES["stars"] as Texture2D
	sparks.lifetime = 0.28
	sparks.explosiveness = 0.98
	sparks.local_coords = false
	sparks.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	sparks.emission_sphere_radius = 28.0 * intensity
	sparks.direction = Vector2.UP
	sparks.spread = 180.0
	sparks.gravity = Vector2.ZERO
	sparks.initial_velocity_min = 95.0 * intensity
	sparks.initial_velocity_max = 285.0 * intensity
	sparks.scale_amount_min = 0.16
	sparks.scale_amount_max = 0.34 * intensity
	sparks.color = Color(0.86, 0.54, 1.0, 0.98)
	effect_parent.add_child(sparks)
	sparks.global_position = position
	sparks.restart()
	var cleanup := sparks.create_tween()
	cleanup.tween_interval(sparks.lifetime + 0.16)
	cleanup.tween_callback(sparks.queue_free)




func _finish_mirage_visibility_restore() -> void:
	self_modulate.a = 1.0
	_mirage_visibility_restore_deadline_usec = 0
	_mirage_visibility_tween = null


func _force_restore_player_render_visibility() -> void:
	if (
		_mirage_visibility_tween != null
		and _mirage_visibility_tween.is_valid()
	):
		_mirage_visibility_tween.kill()
	_mirage_visibility_tween = null
	_mirage_visibility_restore_deadline_usec = 0
	self_modulate.a = 1.0


func _repair_stale_player_render_visibility() -> void:
	var now_usec := Time.get_ticks_usec()
	if (
		_mirage_visibility_restore_deadline_usec > 0
		and now_usec >= _mirage_visibility_restore_deadline_usec
	):
		_force_restore_player_render_visibility()
		return
	if self_modulate.a > 0.01:
		return
	if _mirage_visibility_restore_deadline_usec <= 0:
		_force_restore_player_render_visibility()
		return
	if (
		_mirage_visibility_tween == null
		or not _mirage_visibility_tween.is_valid()
	):
		_force_restore_player_render_visibility()


func _play_mirage_step_shadow(
	effect_parent: Node,
	start_position: Vector2,
	target_position: Vector2
) -> void:
	var duration := maxf(0.08, blind_spot_shadow_step_duration)
	if (
		_mirage_visibility_tween != null
		and _mirage_visibility_tween.is_valid()
	):
		_mirage_visibility_tween.kill()
	self_modulate.a = 0.0
	_mirage_visibility_restore_deadline_usec = (
		Time.get_ticks_usec()
		+ int(round((duration + 0.35) * 1000000.0))
	)
	_mirage_visibility_tween = create_tween()
	_mirage_visibility_tween.tween_interval(duration * 0.66)
	_mirage_visibility_tween.tween_property(
		self,
		"self_modulate:a",
		1.0,
		duration * 0.34
	).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	_mirage_visibility_tween.tween_callback(
		_finish_mirage_visibility_restore
	)

	_spawn_mirage_shadow_portal(
		effect_parent,
		start_position,
		false,
		duration
	)
	_spawn_mirage_shadow_portal(
		effect_parent,
		target_position,
		true,
		duration
	)

	if player_circle == null or player_circle.texture == null:
		return
	var shadow := Sprite2D.new()
	shadow.name = "MirageStepShadow"
	shadow.top_level = true
	shadow.z_index = 7
	shadow.texture = player_circle.texture
	shadow.scale = player_circle.scale * 0.92
	shadow.modulate = blind_spot_shadow_color
	effect_parent.add_child(shadow)
	shadow.global_position = start_position

	var travel := target_position - start_position
	var travel_direction := travel.normalized()
	var arc_side := (
		-1.0 if owner_peer_id % 2 == 0 else 1.0
	)
	var arc_offset := (
		travel_direction.orthogonal()
		* minf(
			maxf(0.0, blind_spot_shadow_arc_distance),
			travel.length() * 0.22
		)
		* arc_side
	)
	var middle_position := (
		start_position.lerp(target_position, 0.42)
		+ arc_offset
	)
	var shadow_tween := shadow.create_tween()
	shadow_tween.tween_property(
		shadow,
		"global_position",
		middle_position,
		duration * 0.42
	).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
	shadow_tween.tween_property(
		shadow,
		"global_position",
		target_position,
		duration * 0.58
	).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	shadow_tween.set_parallel(true)
	shadow_tween.tween_property(
		shadow,
		"modulate:a",
		0.08,
		duration * 0.58
	)
	shadow_tween.tween_property(
		shadow,
		"scale",
		player_circle.scale * 0.68,
		duration * 0.58
	)
	shadow_tween.chain().tween_callback(shadow.queue_free)


func _spawn_mirage_shadow_portal(
	effect_parent: Node,
	portal_position: Vector2,
	arrival: bool,
	duration: float
) -> void:
	var portal := Line2D.new()
	portal.name = "MirageStepArrival" if arrival else "MirageStepVanish"
	portal.top_level = true
	portal.z_index = 6
	portal.width = 16.0
	portal.default_color = (
		blind_spot_trail_color
		if arrival
		else Color(0.24, 0.04, 0.40, 0.96)
	)
	portal.closed = true
	portal.antialiased = true
	portal.points = _make_phantom_heel_circle(125.0, 32)
	effect_parent.add_child(portal)
	portal.global_position = portal_position
	portal.scale = (
		Vector2.ONE * 0.18 if arrival else Vector2.ONE
	)

	var portal_tween := portal.create_tween()
	portal_tween.set_parallel(true)
	portal_tween.tween_property(
		portal,
		"scale",
		Vector2.ONE if arrival else Vector2.ONE * 0.16,
		duration
	).set_trans(Tween.TRANS_QUART).set_ease(
		Tween.EASE_OUT if arrival else Tween.EASE_IN
	)
	portal_tween.tween_property(
		portal,
		"modulate:a",
		0.0,
		duration
	)
	portal_tween.chain().tween_callback(portal.queue_free)


func _play_world_ability_one_shot(
	stream: AudioStream,
	position: Vector2,
	volume_db: float = 0.0,
	pitch_scale: float = 1.0
) -> void:
	if stream == null:
		return
	var effect_parent := _get_active_playfield_root()
	if effect_parent == null:
		return
	var player := AudioStreamPlayer2D.new()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	player.max_distance = 10000.0
	effect_parent.add_child(player)
	player.global_position = position
	player.finished.connect(player.queue_free)
	player.play()


@rpc("authority", "call_local", "reliable")
func _receive_boogie_woogie_vfx(
	first_position: Vector2,
	second_position: Vector2
) -> void:
	var effect_parent := _get_active_playfield_root()
	if effect_parent == null:
		return

	_spawn_phantom_heel_particles(
		effect_parent,
		first_position,
		boogie_woogie_primary_color,
		0.9
	)
	_spawn_phantom_heel_particles(
		effect_parent,
		second_position,
		boogie_woogie_secondary_color,
		1.25
	)
	_spawn_boogie_woogie_shockwave(
		effect_parent,
		second_position
	)
	_play_world_ability_one_shot(
		BOOGIE_WOOGIE_SOUND,
		second_position,
		3.0,
		1.0
	)


func _spawn_boogie_woogie_shockwave(
	effect_parent: Node,
	origin: Vector2
) -> void:
	var ring := Line2D.new()
	ring.name = "BoogieWoogieShockwave"
	ring.top_level = true
	ring.z_index = 6
	ring.width = 14.0
	ring.default_color = boogie_woogie_secondary_color
	ring.closed = true
	ring.antialiased = true
	ring.points = _make_phantom_heel_circle(
		maxf(24.0, boogie_woogie_shockwave_radius),
		40
	)
	effect_parent.add_child(ring)
	ring.global_position = origin
	ring.scale = Vector2.ONE * 0.18

	var tween := ring.create_tween()
	tween.set_parallel(true)
	tween.tween_property(
		ring,
		"scale",
		Vector2.ONE,
		0.34
	).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_property(
		ring,
		"modulate:a",
		0.0,
		0.34
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(ring.queue_free)


@rpc("authority", "call_local", "reliable")
func _receive_iron_anchor_trap_vfx(
	trap_position: Vector2
) -> void:
	var effect_parent := _get_active_playfield_root()
	if effect_parent == null:
		return

	var trap_ring := Line2D.new()
	trap_ring.name = "IronAnchorTrapRing"
	trap_ring.top_level = true
	trap_ring.z_index = 5
	trap_ring.width = 18.0
	trap_ring.default_color = Color(0.42, 0.92, 1.0, 0.95)
	trap_ring.closed = true
	trap_ring.antialiased = true
	trap_ring.add_point(Vector2.ZERO)
	var radius := maxf(8.0, iron_anchor_trap_visual_radius)
	trap_ring.points = _make_phantom_heel_circle(radius, 30)
	effect_parent.add_child(trap_ring)
	trap_ring.global_position = trap_position

	_spawn_phantom_heel_particles(
		effect_parent,
		trap_position,
		Color(0.38, 0.9, 1.0, 1.0),
		1.15
	)

	trap_ring.scale = Vector2.ONE * 0.55
	var tween := trap_ring.create_tween()
	tween.set_parallel(true)
	tween.tween_property(
		trap_ring,
		"scale",
		Vector2.ONE * 1.35,
		0.45
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(
		trap_ring,
		"modulate:a",
		0.0,
		0.45
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(trap_ring.queue_free)


func _spawn_phantom_heel_shadow(
	effect_parent: Node,
	effect_position: Vector2
) -> void:
	var shadow := Node2D.new()
	shadow.name = "PhantomHeelShadow"
	shadow.z_index = 5
	effect_parent.add_child(shadow)
	shadow.global_position = effect_position

	var safe_radius := maxf(1.0, phantom_heel_shadow_radius)
	var rim := Polygon2D.new()
	rim.polygon = _make_phantom_heel_circle(
		safe_radius,
		phantom_heel_shadow_points
	)
	rim.color = phantom_heel_rim_color
	shadow.add_child(rim)

	var core := Polygon2D.new()
	core.polygon = _make_phantom_heel_circle(
		safe_radius * 0.78,
		phantom_heel_shadow_points
	)
	core.color = phantom_heel_shadow_color
	shadow.add_child(core)

	shadow.scale = Vector2.ONE * 0.82
	var duration := maxf(0.05, phantom_heel_shadow_duration)
	var tween := shadow.create_tween()
	tween.set_parallel(true)
	tween.tween_property(
		shadow,
		"scale",
		Vector2.ONE * 1.32,
		duration
	).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_property(
		shadow,
		"modulate:a",
		0.0,
		duration
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(shadow.queue_free)


func _spawn_phantom_heel_particles(
	effect_parent: Node,
	effect_position: Vector2,
	particle_color: Color,
	intensity: float
) -> void:
	var particles := CPUParticles2D.new()
	particles.name = "PhantomHeelParticles"
	particles.z_index = 6
	particles.emitting = false
	particles.one_shot = true
	particles.amount = maxi(
		1,
		roundi(phantom_heel_particle_amount * intensity)
	)
	particles.texture = PHANTOM_HEEL_PARTICLE_TEXTURE
	particles.lifetime = maxf(
		0.05,
		phantom_heel_particle_lifetime
	)
	particles.explosiveness = 0.92
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = (
		maxf(1.0, phantom_heel_shadow_radius) * 0.7
	)
	particles.direction = Vector2.UP
	particles.spread = 180.0
	particles.gravity = Vector2.ZERO
	particles.initial_velocity_min = maxf(
		0.0,
		phantom_heel_particle_speed_min
	)
	particles.initial_velocity_max = maxf(
		particles.initial_velocity_min,
		phantom_heel_particle_speed_max
	)
	particles.scale_amount_min = 0.55
	particles.scale_amount_max = 1.25
	particles.color = particle_color
	effect_parent.add_child(particles)
	particles.global_position = effect_position
	particles.restart()

	var cleanup := particles.create_tween()
	cleanup.tween_interval(particles.lifetime + 0.2)
	cleanup.tween_callback(particles.queue_free)


func _make_phantom_heel_circle(
	radius: float,
	point_count: int
) -> PackedVector2Array:
	var points := PackedVector2Array()
	var safe_count := maxi(3, point_count)
	for point_index in range(safe_count):
		var angle := TAU * float(point_index) / float(safe_count)
		points.append(Vector2.from_angle(angle) * radius)
	return points


func set_match_team_size(team_size: int) -> void:
	_match_team_size = maxi(0, team_size)
	var synchronizer := get_node_or_null("MultiplayerSynchronizer") as MultiplayerSynchronizer
	if synchronizer != null:
		synchronizer.replication_interval = NETWORK_PLAYER_SNAPSHOT_INTERVAL_DEFAULT


func set_large_team_size_multiplier(multiplier: float) -> void:
	_large_team_size_multiplier = clampf(multiplier, 0.5, 1.0)
	if is_node_ready():
		_apply_large_team_size_multiplier()


func _apply_large_team_size_multiplier() -> void:
	if body_collision_shape != null:
		body_collision_shape.scale = (
			_body_collision_base_scale * _large_team_size_multiplier
		)
	_apply_action_pulse_visual_scale(_action_pulse_visual_scale)
	queue_redraw()


func _apply_action_pulse_visual_scale(scale: float) -> void:
	_action_pulse_visual_scale = maxf(0.01, scale)
	var presentation_scale := (
		_action_pulse_visual_scale * _large_team_size_multiplier
	)
	if player_circle != null:
		player_circle.scale = (
			_player_circle_base_scale * presentation_scale
		)
	if ability_portrait != null:
		ability_portrait.scale = (
			_ability_portrait_base_scale * presentation_scale
		)
	var cosmetic_scale := Vector2.ONE * presentation_scale
	if cosmetic_static_sprite != null:
		cosmetic_static_sprite.scale = cosmetic_scale
	if cosmetic_animated_layer != null:
		cosmetic_animated_layer.scale = cosmetic_scale
	if player_glow_fx != null and player_glow_fx.has_method("set_size_multiplier"):
		player_glow_fx.call("set_size_multiplier", presentation_scale)
	queue_redraw()


func _update_movement_direction_arrow() -> void:
	if movement_direction_arrow == null:
		return
	if not bool(
		ProjectSettings.get_setting(
			DIRECTION_INDICATOR_SETTING,
			true
		)
	):
		movement_direction_arrow.hide()
		return
	var local_controlled := controls_enabled and _is_local_player()
	var spectator_view := (
		controls_enabled
		and not _is_local_player()
		and _is_local_viewer_spectator()
		and (team == &"red" or team == &"blue")
	)
	if not local_controlled and not spectator_view:
		movement_direction_arrow.hide()
		return

	var arrow_direction := Vector2.ZERO
	if local_controlled:
		arrow_direction = server_direction.normalized()
		if arrow_direction.is_zero_approx():
			arrow_direction = Input.get_vector(
				"move_left",
				"move_right",
				"move_up",
				"move_down"
			).normalized()
	else:
		if replicated_charge_active:
			var ball := _get_closest_ball_within_distance(
				maxf(1.0, kick_feedback_detection_distance)
			)
			if ball != null:
				arrow_direction = global_position.direction_to(
					ball.global_position
				)
		if arrow_direction.is_zero_approx():
			arrow_direction = linear_velocity.normalized()

	if arrow_direction.is_zero_approx():
		movement_direction_arrow.hide()
		return

	movement_direction_arrow.position = (
		arrow_direction * maxf(60.0, direction_arrow_distance)
	)
	movement_direction_arrow.rotation = arrow_direction.angle()
	movement_direction_arrow.scale = (
		_movement_direction_arrow_base_scale
		* direction_arrow_scale_multiplier
	)
	movement_direction_arrow.modulate = direction_arrow_color
	movement_direction_arrow.show()


@rpc("authority", "call_local", "reliable")
func _receive_player_action_pulse(
	pulse_type: int,
	intensity: float,
	ability_id: int = ABILITY_NONE
) -> void:
	if DisplayServer.get_name() == "headless":
		return

	var safe_intensity: float = clampf(
		intensity,
		0.35,
		1.0
	)
	var pulse_color: Color = _get_player_action_pulse_color(
		pulse_type,
		ability_id
	)
	_action_feedback_type = pulse_type
	_action_feedback_intensity = safe_intensity
	_action_feedback_total = lerpf(0.30, 0.46, safe_intensity)
	if pulse_type == ACTION_PULSE_POWER_STRIKE:
		_action_feedback_total = 0.56
	_action_feedback_remaining = _action_feedback_total
	queue_redraw()
	if movement_direction_arrow != null and movement_direction_arrow.visible:
		movement_direction_arrow.modulate = pulse_color.lerp(
			direction_arrow_color,
			0.78
		)

	if _action_pulse_visual_tween != null:
		_action_pulse_visual_tween.kill()

	var peak_scale := lerpf(1.06, 1.10, safe_intensity)
	_apply_action_pulse_visual_scale(1.0)
	_action_pulse_visual_tween = create_tween()
	_action_pulse_visual_tween.tween_method(
		_apply_action_pulse_visual_scale,
		1.0,
		peak_scale,
		maxf(0.01, action_pulse_attack_seconds)
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_action_pulse_visual_tween.tween_method(
		_apply_action_pulse_visual_scale,
		peak_scale,
		1.0,
		maxf(0.08, action_pulse_release_seconds)
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _make_player_action_pulse_circle(
	radius: float,
	point_count: int
) -> PackedVector2Array:
	var points := PackedVector2Array()
	var safe_count: int = maxi(16, point_count)
	for point_index in range(safe_count):
		var angle: float = (
			TAU
			* float(point_index)
			/ float(safe_count)
		)
		points.append(
			Vector2.from_angle(angle) * radius
		)
	return points



func _update_readability_feedback(delta: float) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var should_redraw: bool = false
	if _action_feedback_remaining > 0.0:
		_action_feedback_remaining = maxf(0.0, _action_feedback_remaining - delta)
		should_redraw = true
	if _ability_activation_cue_remaining > 0.0:
		_ability_activation_cue_remaining = maxf(
			0.0,
			_ability_activation_cue_remaining - delta
		)
		# Ability state visuals are now transform-animated child CanvasItems, so
		# an active ability no longer invalidates the player's root draw list.
	if replicated_charge_active or local_is_charging:
		should_redraw = true
	if should_redraw:
		queue_redraw()


func _get_visual_charge_ratio() -> float:
	if _is_local_player() and local_is_charging:
		var local_duration: float = maxf(0.01, _current_maximum_charge_seconds())
		return clampf(local_charge_seconds / local_duration, 0.0, 1.0)
	if replicated_charge_active:
		return clampf(
			replicated_charge_seconds / maxf(0.01, replicated_charge_duration),
			0.0,
			1.0
		)
	return 0.0


func _draw_charge_anticipation(outer_radius: float) -> void:
	var ratio: float = _get_visual_charge_ratio()
	var start_ratio: float = clampf(full_charge_anticipation_start, 0.0, 0.95)
	if ratio < start_ratio:
		return
	var strength: float = clampf(
		(ratio - start_ratio) / maxf(0.01, 1.0 - start_ratio),
		0.0,
		1.0
	)
	var color: Color = action_pulse_full_shot_color.lerp(Color.WHITE, 0.28)
	var alpha: float = lerpf(0.18, 0.78, strength)
	var radius: float = outer_radius + lerpf(14.0, 24.0, strength)
	# Three compact inward arcs read as "shot loaded" without looking like
	# another ability ring or changing the player's collision silhouette.
	for arc_index in range(3):
		var center_angle: float = -PI * 0.5 + float(arc_index - 1) * 0.42
		draw_arc(
			Vector2.ZERO,
			radius,
			center_angle - 0.13,
			center_angle + 0.13,
			8,
			Color(color, alpha),
			lerpf(3.0, 6.0, strength),
			true
		)
	if strength >= 0.92:
		for tick_index in range(4):
			var angle: float = -PI * 0.5 + float(tick_index) * PI * 0.5
			var direction: Vector2 = Vector2.from_angle(angle)
			draw_line(
				direction * (radius - 10.0),
				direction * (radius + 9.0),
				Color(1.0, 0.93, 0.56, 0.88),
				4.0,
				true
			)


func _draw_action_readability_feedback(outer_radius: float) -> void:
	if _action_feedback_remaining <= 0.0 or _action_feedback_total <= 0.0:
		return
	var remaining_ratio: float = clampf(
		_action_feedback_remaining / _action_feedback_total,
		0.0,
		1.0
	)
	var progress: float = 1.0 - remaining_ratio
	var color: Color = _get_player_action_pulse_color(
		_action_feedback_type,
		ABILITY_POWER_STRIKE if _action_feedback_type == ACTION_PULSE_POWER_STRIKE else ABILITY_NONE
	)
	var radius: float = outer_radius + 14.0 + progress * 28.0
	var alpha: float = pow(remaining_ratio, 1.25)
	match _action_feedback_type:
		ACTION_PULSE_PASS:
			# Two lateral brackets = quick, controlled pass.
			for side in [-1.0, 1.0]:
				var x: float = side * radius
				draw_line(Vector2(x, -18.0), Vector2(x, 18.0), Color(color, alpha * 0.92), 5.0, true)
				draw_line(Vector2(x, -18.0), Vector2(x - side * 10.0, -10.0), Color(color, alpha * 0.72), 4.0, true)
				draw_line(Vector2(x, 18.0), Vector2(x - side * 10.0, 10.0), Color(color, alpha * 0.72), 4.0, true)
		ACTION_PULSE_FULL_SHOT:
			# Full charge gets a compact gold shock ring and four hard ticks.
			draw_arc(Vector2.ZERO, radius, 0.0, TAU, 52, Color(color, alpha * 0.82), 6.0, true)
			for tick_index in range(4):
				var direction: Vector2 = Vector2.from_angle(float(tick_index) * PI * 0.5)
				draw_line(direction * radius, direction * (radius + 20.0), Color(color.lightened(0.2), alpha), 6.0, true)
		ACTION_PULSE_POWER_STRIKE:
			# Power Strike is intentionally unmistakable: double hot ring + 8 rays.
			draw_arc(Vector2.ZERO, radius, 0.0, TAU, 56, Color(color, alpha * 0.92), 8.0, true)
			draw_arc(Vector2.ZERO, radius + 13.0, 0.0, TAU, 56, Color(1.0, 0.72, 0.24, alpha * 0.66), 4.0, true)
			for ray_index in range(8):
				var direction: Vector2 = Vector2.from_angle(float(ray_index) * TAU / 8.0)
				draw_line(direction * (radius + 6.0), direction * (radius + 30.0), Color(color.lightened(0.28), alpha), 6.0, true)
		ACTION_PULSE_SHOT:
			# Normal shot: one clean warm arc, clearly stronger than pass but
			# deliberately below the full-charge and Power Strike effects.
			draw_arc(Vector2.ZERO, radius, -PI * 0.95, -PI * 0.05, 28, Color(color, alpha * 0.78), 5.0, true)
		ACTION_PULSE_PASS_REQUEST:
			draw_arc(Vector2.ZERO, radius, -PI * 0.75, PI * 0.75, 28, Color(color, alpha * 0.72), 4.0, true)
		ACTION_PULSE_ABILITY:
			draw_arc(Vector2.ZERO, radius, 0.0, TAU, 44, Color(color, alpha * 0.55), 4.0, true)


func _draw_ability_readability_feedback(outer_radius: float) -> void:
	var cue_active: bool = _ability_activation_cue_remaining > 0.0
	var active_state: bool = local_ability_active and local_active_ability_id != ABILITY_NONE
	if not cue_active and not active_state:
		return
	var ability_id: int = (
		_ability_activation_cue_id
		if cue_active
		else local_active_ability_id
	)
	var color: Color = _get_ability_action_pulse_color(ability_id)
	var alpha: float = clampf(ability_active_ring_alpha, 0.0, 1.0)
	var radius: float = outer_radius + 17.0
	if cue_active:
		var cue_ratio: float = clampf(
			_ability_activation_cue_remaining / maxf(0.01, _ability_activation_cue_total),
			0.0,
			1.0
		)
		var cue_progress: float = 1.0 - cue_ratio
		radius += cue_progress * 30.0
		alpha = maxf(alpha, pow(cue_ratio, 1.2) * 0.92)
	# Segmented halo communicates that an ability state is currently armed.
	for segment_index in range(8):
		var start_angle: float = float(segment_index) * TAU / 8.0 + 0.07
		draw_arc(
			Vector2.ZERO,
			radius,
			start_angle,
			start_angle + 0.42,
			6,
			Color(color, alpha),
			4.0 if active_state else 5.5,
			true
		)
	_draw_ability_activation_glyph(ability_id, color, alpha, radius)


func _draw_ability_activation_glyph(
	ability_id: int,
	color: Color,
	alpha: float,
	radius: float
) -> void:
	# Tiny vector glyphs mirror the semantic silhouette of each ability icon.
	# They only exist for the short activation cue/active state and stay clear
	# of the portrait so gameplay objects remain dominant.
	var c: Color = Color(color, clampf(alpha, 0.0, 1.0))
	var bright: Color = Color(color.lightened(0.34), clampf(alpha * 0.92, 0.0, 1.0))
	var p: Vector2 = Vector2(radius + 16.0, -radius * 0.52)
	match ability_id:
		ABILITY_BURST_DRIBBLE:
			draw_line(p + Vector2(-18, 0), p + Vector2(14, 0), c, 6.0, true)
			draw_line(p + Vector2(4, -10), p + Vector2(16, 0), bright, 5.0, true)
			draw_line(p + Vector2(4, 10), p + Vector2(16, 0), bright, 5.0, true)
		ABILITY_QUICK_TRIGGER:
			draw_arc(p, 15.0, -2.4, 1.2, 18, c, 5.0, true)
			_draw_circle_aa(p + Vector2(11, -8), 4.0, bright)
		ABILITY_POWER_STRIKE:
			_draw_circle_aa(p, 11.0, c)
			draw_line(p + Vector2(-14, 15), p + Vector2(-2, 2), bright, 5.0, true)
			draw_line(p + Vector2(-3, 18), p + Vector2(7, 5), bright, 5.0, true)
		ABILITY_OVERDRIVE:
			var bolt := PackedVector2Array([p + Vector2(-6,-18), p + Vector2(8,-5), p + Vector2(0,-4), p + Vector2(8,18), p + Vector2(-10,3), p + Vector2(-1,2)])
			draw_polyline(bolt, c, 6.0, true)
		ABILITY_HEEL_TURN:
			draw_arc(p, 15.0, -0.3, 3.8, 18, c, 5.0, true)
			_draw_circle_aa(p + Vector2(-12, 10), 4.0, bright)
		ABILITY_ENFORCER:
			draw_line(p + Vector2(-13, 13), p + Vector2(12, -12), c, 7.0, true)
			draw_line(p + Vector2(-7, -4), p + Vector2(8, 11), bright, 5.0, true)
		ABILITY_GOALKEEPER_REACH:
			_draw_circle_aa(p + Vector2(8, -10), 6.0, bright)
			draw_line(p + Vector2(-14, 12), p + Vector2(2, -3), c, 7.0, true)
			draw_line(p + Vector2(-5, 1), p + Vector2(8, 8), c, 5.0, true)
		ABILITY_TIME_SKIP_PASS:
			for line_index in range(3):
				draw_line(p + Vector2(-18, -10 + line_index * 10), p + Vector2(8, -10 + line_index * 10), c, 4.0, true)
			_draw_circle_aa(p + Vector2(14, 0), 6.0, bright)
		ABILITY_DIRECT_FINISH:
			draw_line(p + Vector2(-15, 14), p + Vector2(8, -10), c, 7.0, true)
			_draw_circle_aa(p + Vector2(13, -14), 5.0, bright)
		ABILITY_ELASTIC_STEP:
			draw_arc(p, 15.0, 0.3, 5.6, 20, c, 5.0, true)
			draw_line(p + Vector2(-7, 13), p + Vector2(10, 13), bright, 5.0, true)
		ABILITY_META_VISION:
			draw_arc(p, 17.0, -2.7, -0.44, 16, c, 5.0, true)
			draw_arc(p, 17.0, 0.44, 2.7, 16, c, 5.0, true)
			_draw_circle_aa(p, 6.0, bright)
		ABILITY_COPYCAT:
			draw_rect(Rect2(p + Vector2(-14,-14), Vector2(20,20)), c, false, 4.0)
			draw_rect(Rect2(p + Vector2(-5,-5), Vector2(20,20)), bright, false, 4.0)
		ABILITY_REFLEX_BLOCK:
			var shield := PackedVector2Array([p + Vector2(0,-17), p + Vector2(15,-9), p + Vector2(12,8), p + Vector2(0,18), p + Vector2(-12,8), p + Vector2(-15,-9), p + Vector2(0,-17)])
			draw_polyline(shield, c, 5.0, true)
			draw_line(p + Vector2(-7,0), p + Vector2(7,0), bright, 4.0, true)
			draw_line(p + Vector2(0,-7), p + Vector2(0,7), bright, 4.0, true)
		ABILITY_IRON_ANCHOR:
			_draw_circle_aa(p + Vector2(0,-10), 5.0, bright, false, 4.0)
			draw_line(p + Vector2(0,-5), p + Vector2(0,14), c, 5.0, true)
			draw_arc(p + Vector2(0,5), 14.0, 0.15, PI - 0.15, 16, c, 5.0, true)
		ABILITY_BLIND_SPOT:
			draw_arc(p, 16.0, 0.4, 5.4, 18, c, 5.0, true)
			draw_line(p + Vector2(-13,-13), p + Vector2(13,13), bright, 4.0, true)
		ABILITY_BOOGIE_WOOGIE:
			_draw_circle_aa(p + Vector2(-8,0), 7.0, c, false, 4.0)
			_draw_circle_aa(p + Vector2(9,0), 7.0, bright, false, 4.0)
			draw_line(p + Vector2(-1,-10), p + Vector2(2,10), c, 4.0, true)
		ABILITY_ECHO:
			_draw_circle_aa(p + Vector2(-7,0), 8.0, c, false, 4.0)
			_draw_circle_aa(p + Vector2(7,0), 8.0, bright, false, 4.0)
		ABILITY_RETURN_TAG:
			draw_arc(p, 15.0, -2.5, 0.6, 18, c, 5.0, true)
			draw_arc(p, 15.0, 0.65, 3.7, 18, bright, 5.0, true)
		ABILITY_BREAKAWAY:
			_draw_circle_aa(p + Vector2(4,-12), 5.0, bright)
			draw_line(p + Vector2(1,-6), p + Vector2(-6,7), c, 5.0, true)
			draw_line(p + Vector2(-5,6), p + Vector2(7,16), c, 5.0, true)
			draw_line(p + Vector2(-4,4), p + Vector2(-15,15), c, 5.0, true)
		ABILITY_SNAPBACK:
			draw_arc(p, 16.0, -0.4, 3.7, 18, c, 5.0, true)
			_draw_circle_aa(p + Vector2(12,-8), 5.0, bright)
		ABILITY_SIDE_SWIPE:
			_draw_circle_aa(p, 7.0, bright)
			draw_line(p + Vector2(-20,0), p + Vector2(-8,0), c, 5.0, true)
			draw_line(p + Vector2(8,0), p + Vector2(20,0), c, 5.0, true)
		_:
			_draw_circle_aa(p, 10.0, c, false, 4.0)


func _configure_ability_particle_motion(ability_id: int) -> void:
	if ability_particles == null or ability_pulse_particles == null:
		return
	# Start from a clean baseline, then give each semantic family a distinct
	# motion profile. The colors remain ability-specific in the existing map.
	ability_particles.amount = 56
	ability_particles.lifetime = 0.72
	ability_particles.emission_sphere_radius = 126.0
	ability_particles.direction = Vector2(0.0, -1.0)
	ability_particles.spread = 180.0
	ability_particles.initial_velocity_min = 75.0
	ability_particles.initial_velocity_max = 190.0
	ability_particles.scale_amount_min = 0.72
	ability_particles.scale_amount_max = 1.26
	ability_pulse_particles.amount = 16
	ability_pulse_particles.lifetime = 0.44
	ability_pulse_particles.emission_sphere_radius = 112.0
	ability_pulse_particles.direction = Vector2(0.0, -1.0)
	ability_pulse_particles.spread = 180.0
	ability_pulse_particles.initial_velocity_min = 28.0
	ability_pulse_particles.initial_velocity_max = 82.0
	ability_pulse_particles.scale_amount_min = 1.25
	ability_pulse_particles.scale_amount_max = 2.0
	match ability_id:
		ABILITY_BURST_DRIBBLE, ABILITY_OVERDRIVE, ABILITY_BREAKAWAY:
			ability_particles.amount = 72
			ability_particles.lifetime = 0.48
			ability_particles.direction = Vector2(-1.0, 0.0)
			ability_particles.spread = 52.0
			ability_particles.initial_velocity_min = 160.0
			ability_particles.initial_velocity_max = 330.0
		ABILITY_POWER_STRIKE, ABILITY_ENFORCER, ABILITY_DIRECT_FINISH:
			ability_particles.amount = 86
			ability_particles.lifetime = 0.62
			ability_particles.initial_velocity_min = 130.0
			ability_particles.initial_velocity_max = 330.0
			ability_pulse_particles.amount = 26
		ABILITY_QUICK_TRIGGER, ABILITY_HEEL_TURN, ABILITY_ELASTIC_STEP, ABILITY_SNAPBACK, ABILITY_SIDE_SWIPE:
			ability_particles.amount = 62
			ability_particles.lifetime = 0.64
			ability_particles.spread = 105.0
			ability_particles.initial_velocity_min = 95.0
			ability_particles.initial_velocity_max = 230.0
		ABILITY_TIME_SKIP_PASS, ABILITY_META_VISION, ABILITY_RETURN_TAG, ABILITY_BOOGIE_WOOGIE:
			ability_particles.amount = 48
			ability_particles.lifetime = 0.88
			ability_particles.initial_velocity_min = 45.0
			ability_particles.initial_velocity_max = 140.0
			ability_pulse_particles.amount = 24
		ABILITY_GOALKEEPER_REACH, ABILITY_REFLEX_BLOCK, ABILITY_IRON_ANCHOR, ABILITY_ECHO:
			ability_particles.amount = 44
			ability_particles.lifetime = 0.82
			ability_particles.initial_velocity_min = 34.0
			ability_particles.initial_velocity_max = 118.0
			ability_pulse_particles.amount = 28
		ABILITY_COPYCAT, ABILITY_BLIND_SPOT:
			ability_particles.amount = 52
			ability_particles.lifetime = 0.76
	_apply_ability_particle_cosmetic()
	if ability_id == ABILITY_BLIND_SPOT:
		ability_particles.texture = MIRAGE_STEP_PARTICLE_TEXTURE
		ability_pulse_particles.texture = MIRAGE_STEP_PARTICLE_TEXTURE


func _get_player_action_pulse_color(
	pulse_type: int,
	ability_id: int
) -> Color:
	match pulse_type:
		ACTION_PULSE_SHOT:
			return action_pulse_shot_color
		ACTION_PULSE_PASS:
			return action_pulse_pass_color
		ACTION_PULSE_PASS_REQUEST:
			return action_pulse_pass_request_color
		ACTION_PULSE_ABILITY:
			return _get_ability_action_pulse_color(
				ability_id
			)
		ACTION_PULSE_FULL_SHOT:
			return action_pulse_full_shot_color
		ACTION_PULSE_POWER_STRIKE:
			return action_pulse_power_strike_color
	return Color.WHITE


func _get_ability_action_pulse_color(
	ability_id: int
) -> Color:
	match ability_id:
		ABILITY_BURST_DRIBBLE:
			return Color(0.12, 0.72, 1.0, 1.0)
		ABILITY_QUICK_TRIGGER:
			return Color(0.72, 0.26, 1.0, 1.0)
		ABILITY_POWER_STRIKE:
			return Color(1.0, 0.04, 0.10, 1.0)
		ABILITY_OVERDRIVE:
			return Color(0.20, 0.52, 1.0, 1.0)
		ABILITY_HEEL_TURN:
			return phantom_heel_particle_color
		ABILITY_ENFORCER:
			return Color(1.0, 0.28, 0.18, 1.0)
		ABILITY_GOALKEEPER_REACH:
			return Color(0.18, 0.70, 1.0, 1.0)
		ABILITY_TIME_SKIP_PASS:
			return Color(0.56, 0.18, 0.96, 1.0)
		ABILITY_DIRECT_FINISH:
			return Color(1.0, 0.38, 0.24, 1.0)
		ABILITY_ELASTIC_STEP:
			return Color(0.18, 1.0, 0.68, 1.0)
		ABILITY_META_VISION:
			return Color(0.06, 1.0, 0.82, 1.0)
		ABILITY_COPYCAT:
			return Color(0.30, 1.0, 0.48, 1.0)
		ABILITY_REFLEX_BLOCK:
			return Color(0.12, 0.88, 1.0, 1.0)
		ABILITY_IRON_ANCHOR:
			return Color(0.20, 0.72, 0.96, 1.0)
		ABILITY_BLIND_SPOT:
			return Color(0.76, 0.28, 1.0, 1.0)
		ABILITY_BOOGIE_WOOGIE:
			return boogie_woogie_primary_color
		ABILITY_ECHO:
			return Color(0.20, 0.78, 1.0, 1.0)
		ABILITY_RETURN_TAG:
			return Color(0.72, 0.34, 1.0, 1.0)
		ABILITY_BREAKAWAY:
			return Color(1.0, 0.54, 0.12, 1.0)
		ABILITY_SNAPBACK:
			return Color(1.0, 0.18, 0.52, 1.0)
		ABILITY_SIDE_SWIPE:
			return Color(0.62, 0.42, 1.0, 1.0)
	return action_pulse_default_ability_color


@rpc("authority", "call_local", "reliable")
func _receive_copycat_memory(ability_id: int, memory_seconds: float) -> void:
	local_copycat_stored_ability_id = clampi(ability_id, ABILITY_NONE, ABILITY_COUNT)
	local_copycat_memory_remaining = maxf(0.0, memory_seconds)


@rpc("authority", "call_local", "reliable")
func _receive_copycat_memory_cleared() -> void:
	local_copycat_stored_ability_id = ABILITY_NONE
	local_copycat_memory_remaining = 0.0


func _start_ability_particle_cosmetic(effect_duration: float) -> void:
	if ability_particles == null or ability_pulse_particles == null:
		return
	var sustained := effect_duration > 0.0
	ability_particles.show()
	ability_pulse_particles.show()
	ability_particles.one_shot = not sustained
	# A sustained effect should stream particles evenly instead of re-firing the
	# full activation burst every particle lifetime. This keeps it readable and
	# cheap even when several duration abilities are active at once.
	ability_particles.explosiveness = 0.12 if sustained else 0.82
	ability_particles.emitting = true
	ability_particles.restart()
	ability_pulse_particles.one_shot = true
	ability_pulse_particles.explosiveness = 0.94
	ability_pulse_particles.emitting = true
	ability_pulse_particles.restart()


@rpc("authority", "call_local", "reliable")
func _receive_ability_started(
	ability_id: int,
	effect_duration: float
) -> void:
	local_ability_active = effect_duration > 0.0
	local_active_ability_id = (
		ability_id
		if effect_duration > 0.0
		else ABILITY_NONE
	)
	local_ability_effect_remaining = effect_duration
	if ability_id == ABILITY_DIRECT_FINISH:
		local_direct_finish_volley_requested = false
	_configure_ability_particle_colors(ability_id)
	_configure_ability_particle_motion(ability_id)
	_ability_activation_cue_id = ability_id
	_ability_activation_cue_total = maxf(0.20, ability_activation_cue_seconds)
	_ability_activation_cue_remaining = _ability_activation_cue_total
	# Keep the shared activation/readability effect and the equipped Ability FX.
	# Instant abilities use the original burst. Abilities with a real active
	# timespan keep the main GPU particle cosmetic emitting until the authoritative
	# effect-ended RPC arrives, while the larger pulse remains an activation burst.
	_start_ability_particle_cosmetic(effect_duration)

	if _is_local_player() and ability_id != ABILITY_HEEL_TURN:
		match ability_id:
			ABILITY_BURST_DRIBBLE:
				_play_local_ability_sound(
					BURST_DRIBBLE_SOUND,
					1.0,
					ability_sound_volume_db
				)
			ABILITY_ELASTIC_STEP:
				_play_local_ability_sound(
					BURST_DRIBBLE_SOUND,
					1.12,
					ability_sound_volume_db
				)
			ABILITY_GOALKEEPER_REACH:
				_play_local_ability_sound(
					BURST_DRIBBLE_SOUND,
					0.90,
					ability_sound_volume_db + 1.0
				)
			ABILITY_QUICK_TRIGGER:
				# Curve Shot gets its cue on the actual curved ball strike, not
				# when the player merely arms the ability.
				pass
			ABILITY_TIME_SKIP_PASS:
				# Dead Zone Pass has a spatial cue on the actual enhanced pass
				# launch, so do not stack the generic ability-used sound here.
				pass
			ABILITY_REFLEX_BLOCK:
				# Reflex Block is intentionally silent when armed. Its dedicated
				# shield cue plays only when an incoming ball is actually deflected.
				pass
			ABILITY_DIRECT_FINISH:
				# Trap stays silent; Volley gets Curve Shot's cue only on contact.
				pass
			ABILITY_BLIND_SPOT:
				# Mirage Step stays silent until its dedicated sound is supplied.
				pass
			ABILITY_BOOGIE_WOOGIE:
				# The supplied clap plays spatially at the actual swap moment.
				pass
			ABILITY_ECHO:
				# Echo's anvil cue plays only when the echo actually blocks a ball.
				pass
			ABILITY_ENFORCER:
				# Enforcer is silent when armed. The dedicated sound plays on
				# every successful player kick so it matches the actual impact.
				pass
			_:
				_play_local_ability_sound(
					ability_used_sound,
					ability_used_pitch_scale,
					ability_sound_volume_db
				)


@rpc("authority", "call_local", "unreliable")
func _receive_decoy_run_vfx(
	origin: Vector2,
	movement_velocity: Vector2,
	duration: float
) -> void:
	var afterimage := FootballDecoyRunAfterimage.new()
	var visual_parent: Node = get_parent()
	if visual_parent == null:
		return
	visual_parent.add_child(afterimage)
	var color := Color(0.62, 0.36, 1.0, 1.0)
	if team == &"blue":
		color = Color(0.20, 0.68, 1.0, 1.0)
	elif team == &"red":
		color = Color(1.0, 0.24, 0.42, 1.0)
	afterimage.setup(origin, movement_velocity, duration, color)
	_decoy_run_visual_generation += 1
	var generation: int = _decoy_run_visual_generation
	self_modulate.a = clampf(decoy_run_player_alpha, 0.15, 0.9)
	_restore_decoy_run_visual_after(duration, generation)


func _restore_decoy_run_visual_after(
	duration: float,
	generation: int
) -> void:
	await get_tree().create_timer(maxf(0.1, duration)).timeout
	if generation == _decoy_run_visual_generation:
		self_modulate.a = 1.0


@rpc("authority", "call_local", "reliable")
func _receive_direct_finish_choice(volley_requested: bool) -> void:
	if (
		local_ability_active
		and local_active_ability_id == ABILITY_DIRECT_FINISH
	):
		local_direct_finish_volley_requested = volley_requested


func _configure_ability_particle_colors(
	ability_id: int
) -> void:
	if ability_id == ABILITY_IRON_ANCHOR and is_satoru_gojo():
		# Keep Gojo's Iron Anchor activation readable as a single purple identity.
		ability_particles.color = Color(0.62, 0.20, 1.0, 1.0)
		ability_pulse_particles.color = Color(0.88, 0.64, 1.0, 0.96)
		return
	match ability_id:
		ABILITY_BURST_DRIBBLE:
			ability_particles.color = Color(0.20, 0.72, 1.0, 1.0)
			ability_pulse_particles.color = Color(
				0.05, 0.28, 0.72, 0.90
			)
		ABILITY_QUICK_TRIGGER:
			ability_particles.color = Color(0.65, 0.24, 1.0, 1.0)
			ability_pulse_particles.color = Color(
				0.22, 0.05, 0.48, 0.92
			)
		ABILITY_POWER_STRIKE:
			ability_particles.color = Color(1.0, 0.10, 0.04, 1.0)
			ability_pulse_particles.color = Color(
				0.62, 0.01, 0.04, 0.94
			)
		ABILITY_OVERDRIVE:
			ability_particles.color = Color(1.0, 0.72, 0.06, 1.0)
			ability_pulse_particles.color = Color(
				0.28, 0.16, 0.88, 0.92
			)
		ABILITY_HEEL_TURN:
			ability_particles.color = phantom_heel_particle_color
			ability_pulse_particles.color = phantom_heel_rim_color
		ABILITY_ENFORCER:
			ability_particles.color = Color(1.0, 0.22, 0.30, 1.0)
			ability_pulse_particles.color = Color(
				0.48, 0.02, 0.08, 0.92
			)
		ABILITY_GOALKEEPER_REACH:
			ability_particles.color = Color(0.18, 0.72, 1.0, 1.0)
			ability_pulse_particles.color = Color(
				0.03, 0.22, 0.58, 0.90
			)
		ABILITY_TIME_SKIP_PASS:
			ability_particles.color = Color(0.57, 0.22, 1.0, 1.0)
			ability_pulse_particles.color = Color(
				0.18, 0.03, 0.42, 0.92
			)
		ABILITY_DIRECT_FINISH:
			ability_particles.color = Color(1.0, 0.34, 0.10, 1.0)
			ability_pulse_particles.color = Color(
				0.48, 0.04, 0.10, 0.92
			)
		ABILITY_ELASTIC_STEP:
			ability_particles.color = Color(0.16, 0.94, 0.58, 1.0)
			ability_pulse_particles.color = Color(
				0.48, 0.16, 0.86, 0.92
			)
		ABILITY_META_VISION:
			ability_particles.color = Color(0.10, 1.0, 0.64, 1.0)
			ability_pulse_particles.color = Color(
				0.02, 0.34, 0.26, 0.90
			)
		ABILITY_COPYCAT:
			ability_particles.color = Color(0.34, 0.95, 0.62, 1.0)
			ability_pulse_particles.color = Color(
				0.56, 0.24, 0.86, 0.92
			)
		ABILITY_REFLEX_BLOCK:
			ability_particles.color = Color(0.16, 0.88, 0.98, 1.0)
			ability_pulse_particles.color = Color(
				0.03, 0.34, 0.42, 0.90
			)
		ABILITY_IRON_ANCHOR:
			ability_particles.color = Color(0.18, 0.72, 0.95, 1.0)
			ability_pulse_particles.color = Color(
				0.08, 0.30, 0.48, 0.90
			)
		ABILITY_BLIND_SPOT:
			ability_particles.color = Color(0.74, 0.34, 1.0, 1.0)
			ability_pulse_particles.color = Color(
				0.28, 0.08, 0.56, 0.92
			)
		ABILITY_BOOGIE_WOOGIE:
			ability_particles.color = boogie_woogie_primary_color
			ability_pulse_particles.color = (
				boogie_woogie_secondary_color
			)
		ABILITY_ECHO:
			ability_particles.color = Color(0.24, 0.82, 1.0, 1.0)
			ability_pulse_particles.color = Color(0.04, 0.28, 0.62, 0.9)
		ABILITY_RETURN_TAG:
			ability_particles.color = Color(0.76, 0.38, 1.0, 1.0)
			ability_pulse_particles.color = Color(0.20, 0.06, 0.48, 0.92)
		ABILITY_BREAKAWAY:
			ability_particles.color = Color(1.0, 0.58, 0.12, 1.0)
			ability_pulse_particles.color = Color(0.52, 0.18, 0.02, 0.92)
		ABILITY_SNAPBACK:
			ability_particles.color = Color(1.0, 0.20, 0.56, 1.0)
			ability_pulse_particles.color = Color(0.48, 0.03, 0.22, 0.92)
		ABILITY_SIDE_SWIPE:
			ability_particles.color = Color(0.66, 0.42, 1.0, 1.0)
			ability_pulse_particles.color = Color(0.10, 0.50, 0.70, 0.92)
		ABILITY_NUTMEG:
			ability_particles.color = Color(1.0, 0.72, 0.12, 1.0)
			ability_pulse_particles.color = Color(0.82, 0.18, 0.08, 0.92)
		ABILITY_DECOY_RUN:
			ability_particles.color = Color(0.58, 0.36, 1.0, 1.0)
			ability_pulse_particles.color = Color(0.10, 0.62, 0.90, 0.90)
		_:
			ability_particles.color = Color(0.04, 0.72, 0.2, 1.0)
			ability_pulse_particles.color = Color(
				0.02, 0.42, 0.1, 0.82
			)


@rpc("authority", "call_local", "reliable")
func _receive_ability_effect_ended(
	_ability_id: int,
	cooldown: float
) -> void:
	local_ability_active = false
	local_active_ability_id = ABILITY_NONE
	local_direct_finish_volley_requested = false
	local_ability_effect_remaining = 0.0
	ability_particles.emitting = false
	ability_pulse_particles.emitting = false
	ability_particles.one_shot = true
	ability_particles.explosiveness = 0.82
	meta_vision_trajectory.hide()
	meta_vision_landing_marker.hide()
	_begin_local_cooldown(cooldown)


@rpc("authority", "call_local", "reliable")
func _receive_ability_cooldown_started(
	_ability_id: int,
	cooldown: float
) -> void:
	local_active_ability_id = ABILITY_NONE
	local_direct_finish_volley_requested = false
	_begin_local_cooldown(cooldown)


@rpc("authority", "call_local", "reliable")
func _receive_burst_charge_state(
	charges: int,
	maximum_charges: int
) -> void:
	local_burst_max_charges = maxi(1, maximum_charges)
	local_burst_charges = clampi(
		charges,
		0,
		local_burst_max_charges
	)


@rpc("authority", "call_local", "reliable")
func _receive_elastic_step_charge_state(
	charges: int,
	maximum_charges: int
) -> void:
	local_elastic_step_max_charges = maxi(1, maximum_charges)
	local_elastic_step_charges = clampi(
		charges,
		0,
		local_elastic_step_max_charges
	)


func _begin_local_cooldown(cooldown: float) -> void:
	local_ability_cooldown_total = maxf(0.0, cooldown)
	local_ability_cooldown_remaining = (
		local_ability_cooldown_total
	)



func _play_local_ability_sound(
	stream: AudioStream,
	pitch: float,
	volume_db: float
) -> void:
	if stream == null:
		return

	ability_audio.stop()
	ability_audio.stream = stream
	ability_audio.volume_db = volume_db
	ability_audio.pitch_scale = pitch
	ability_audio.play()


func _prepare_default_ability_ready_sound() -> void:
	if ability_ready_sound != null:
		return
	var sample_rate := 44100
	var duration := 0.42
	var sample_count := int(ceil(duration * float(sample_rate)))
	var pcm := PackedByteArray()
	pcm.resize(sample_count * 2)
	for sample_index in range(sample_count):
		var time := float(sample_index) / float(sample_rate)
		var attack := clampf(time / 0.018, 0.0, 1.0)
		var decay := pow(
			clampf(1.0 - time / duration, 0.0, 1.0),
			2.15
		)
		var second_time := maxf(0.0, time - 0.065)
		var second_attack := clampf(second_time / 0.014, 0.0, 1.0)
		var second_decay := pow(
			clampf(1.0 - second_time / (duration - 0.065), 0.0, 1.0),
			2.35
		)
		var first_tone := sin(TAU * 523.25 * time)
		var first_shimmer := sin(TAU * 1046.5 * time) * 0.09
		var second_tone := (
			sin(TAU * 783.99 * second_time)
			* second_attack
			* second_decay
		)
		var sample := (
			(first_tone * 0.68 + first_shimmer) * attack * decay
			+ second_tone * 0.38
		) * 0.2
		var signed_sample := int(
			clampf(sample, -1.0, 1.0) * 32767.0
		)
		var encoded_sample := signed_sample & 0xffff
		pcm[sample_index * 2] = encoded_sample & 0xff
		pcm[sample_index * 2 + 1] = (encoded_sample >> 8) & 0xff
	var chime := AudioStreamWAV.new()
	chime.format = AudioStreamWAV.FORMAT_16_BITS
	chime.mix_rate = sample_rate
	chime.stereo = false
	chime.data = pcm
	ability_ready_sound = chime


func _server_spawn_echo(strength_scale: float) -> void:
	if not multiplayer.is_server():
		return
	_server_clear_echo(true)
	server_echo_generation += 1
	server_echo_active = true
	server_echo_position = global_position
	var duration := maxf(0.1, echo_duration) * clampf(strength_scale, 0.35, 1.0)
	server_echo_ends_at = _server_time_seconds() + duration
	server_echo_blocks_remaining = 2 if draft_perk_id == 11 else 1
	server_echo_blocked_ball_ids.clear()
	_receive_echo_spawned.rpc(
		server_echo_position,
		duration,
		server_echo_generation,
		true
	)


func _server_update_echo() -> void:
	if not multiplayer.is_server() or not server_echo_active:
		return
	if _server_time_seconds() >= server_echo_ends_at:
		server_echo_active = false
		server_echo_ends_at = 0.0
		_receive_echo_removed.rpc(server_echo_generation)
		return

	var closest_ball: FootballBall = null
	var closest_distance := maxf(1.0, echo_collision_radius)
	for node in get_tree().get_nodes_in_group("football_balls"):
		var candidate := node as FootballBall
		if (
			candidate == null
			or (
				server_echo_blocked_ball_ids.has(candidate.get_instance_id())
				and int(server_echo_blocked_ball_ids[candidate.get_instance_id()])
				== candidate.get_player_touch_serial()
			)
			or candidate.linear_velocity.length()
			< maxf(0.0, echo_minimum_trigger_speed)
			or candidate.last_touch_team == team
		):
			continue
		var distance := candidate.global_position.distance_to(server_echo_position)
		if distance <= closest_distance:
			closest_distance = distance
			closest_ball = candidate
	if closest_ball == null:
		return

	var was_power_strike := closest_ball.power_strike_visual_active
	closest_ball.block_from_echo(
		server_echo_position,
		echo_stop_speed_limit,
		echo_fast_ball_speed_retention,
		owner_peer_id,
		display_name,
		team,
		cpu_controlled
	)
	server_echo_blocked_ball_ids[closest_ball.get_instance_id()] = (
		closest_ball.get_player_touch_serial()
	)
	server_echo_blocks_remaining = maxi(0, server_echo_blocks_remaining - 1)
	if server_echo_blocks_remaining > 0:
		return
	server_echo_active = false
	server_echo_ends_at = 0.0
	_receive_echo_consumed.rpc(
		server_echo_generation,
		was_power_strike
	)


func _server_clear_echo(remove_visual: bool) -> void:
	if not multiplayer.is_server():
		return
	server_echo_active = false
	server_echo_ends_at = 0.0
	server_echo_blocks_remaining = 1
	server_echo_blocked_ball_ids.clear()
	if remove_visual and server_echo_generation > 0:
		_receive_echo_removed.rpc(server_echo_generation)


func sync_echo_to_peer(peer_id: int) -> void:
	if (
		not multiplayer.is_server()
		or peer_id <= 0
		or not server_echo_active
	):
		return
	var remaining := maxf(0.0, server_echo_ends_at - _server_time_seconds())
	if remaining <= 0.0:
		return
	_receive_echo_spawned.rpc_id(
		peer_id,
		server_echo_position,
		remaining,
		server_echo_generation,
		false
	)


@rpc("authority", "call_local", "reliable")
func _receive_echo_spawned(
	position: Vector2,
	duration: float,
	generation: int,
	play_placement_sound: bool
) -> void:
	_clear_local_echo()
	_local_echo_generation = generation
	var echo := DEFENSE_ECHO_SCRIPT.new() as DefenseEcho
	if echo == null:
		return
	var world_parent := get_parent()
	if world_parent == null:
		world_parent = _get_active_playfield_root()
	if world_parent == null:
		return
	world_parent.add_child(echo)
	echo.configure(
		position,
		duration,
		team,
		_get_selected_portrait(),
		echo_collision_radius
	)
	_local_echo_node = echo
	if play_placement_sound:
		_play_world_ability_one_shot(
			ECHO_PLACEMENT_SOUND,
			position,
			2.0,
			1.0
		)


@rpc("authority", "call_local", "reliable")
func _receive_echo_consumed(
	generation: int,
	was_power_strike: bool
) -> void:
	if generation != _local_echo_generation:
		return
	if is_instance_valid(_local_echo_node):
		_local_echo_node.consume(was_power_strike)


@rpc("authority", "call_local", "reliable")
func _receive_echo_removed(generation: int) -> void:
	if generation != _local_echo_generation:
		return
	_clear_local_echo()


func _clear_local_echo() -> void:
	if is_instance_valid(_local_echo_node):
		_local_echo_node.queue_free()
	_local_echo_node = null
	_local_echo_generation = 0


func _consume_return_tag_arming() -> void:
	if not _server_ability_is_active(ABILITY_RETURN_TAG):
		return
	var cooldown := server_pending_cooldown
	server_pending_cooldown = 0.0
	server_ability_active = false
	server_active_ability_id = ABILITY_NONE
	server_ability_ends_at = 0.0
	server_ability_strength_scale = 1.0
	server_ability_cooldown_ends_at = (
		_server_time_seconds() + maxf(0.0, cooldown)
	)
	_receive_ability_effect_ended.rpc(
		ABILITY_RETURN_TAG,
		cooldown
	)


func _server_execute_return_tag_pass(tagged_ball: FootballBall) -> bool:
	if (
		tagged_ball == null
		or not tagged_ball.can_return_tag_for(owner_peer_id, team)
	):
		return false
	var target_peer_id := tagged_ball.get_return_tag_owner_peer_id()
	var target := _get_player_by_peer_id(target_peer_id)
	if (
		target == null
		or not target.controls_enabled
		or target.team != team
	):
		tagged_ball.clear_return_tag()
		return false
	var target_position: Vector2 = _get_return_tag_target_position(
		tagged_ball,
		target
	)
	var distance := tagged_ball.global_position.distance_to(target_position)
	if distance < maxf(0.0, return_tag_minimum_distance):
		target_position = target.global_position
	var return_speed := clampf(
		maxf(return_tag_return_speed, distance * 1.25),
		maxf(100.0, return_tag_return_speed),
		maxf(return_tag_return_speed, return_tag_maximum_return_speed)
	)
	var returned := tagged_ball.execute_return_tag_pass(
		target_position,
		return_speed,
		owner_peer_id,
		display_name,
		team,
		cpu_controlled
	)
	if returned:
		_receive_shot_sound.rpc(maxf(0.0, soft_pass_force))
	return returned


func cpu_get_return_tag_target(tagged_ball: FootballBall) -> Vector2:
	if tagged_ball == null:
		return Vector2.ZERO
	var target_peer_id: int = tagged_ball.get_return_tag_owner_peer_id()
	var target: FootballPlayer = _get_player_by_peer_id(target_peer_id)
	if target == null or target.team != team or not target.controls_enabled:
		return Vector2.ZERO
	return _get_return_tag_target_position(tagged_ball, target)


func cpu_can_execute_phantom_heel_followup() -> bool:
	if (
		not cpu_controlled
		or not multiplayer.is_server()
		or not _server_ability_is_active(ABILITY_HEEL_TURN)
		or _server_time_seconds() < server_phantom_heel_followup_ready_at
	):
		return false
	var ball: FootballBall = _get_ball_by_instance_id(server_phantom_heel_ball_id)
	var followup_reach := (
		maxf(kick_feedback_detection_distance, heel_turn_ball_distance) + 90.0
	) * (2.15 if draft_perk_id == 52 else 1.0)
	return (
		ball != null
		and global_position.distance_to(ball.global_position)
		<= followup_reach
	)


func _get_return_tag_target_position(
	tagged_ball: FootballBall,
	target: FootballPlayer
) -> Vector2:
	if tagged_ball == null or target == null:
		return Vector2.ZERO
	var forward: Vector2 = target._get_breakaway_attack_direction()
	if forward.is_zero_approx():
		forward = target.linear_velocity.normalized()
	if forward.is_zero_approx():
		forward = tagged_ball.global_position.direction_to(target.global_position)
	if forward.is_zero_approx():
		forward = Vector2.RIGHT
	var base: Vector2 = (
		target.global_position
		+ target.linear_velocity * maxf(0.0, return_tag_lead_seconds)
		+ forward * maxf(0.0, return_tag_forward_lead_distance)
	)
	var side: Vector2 = Vector2(-forward.y, forward.x).normalized()
	var side_distance: float = maxf(0.0, return_tag_side_lead_distance)
	var option_a: Vector2 = base + side * side_distance
	var option_b: Vector2 = base - side * side_distance
	var ball_origin: Vector2 = tagged_ball.global_position
	var base_clearance: float = _get_side_swipe_lane_clearance(
		ball_origin,
		ball_origin.direction_to(base)
	)
	var clearance_a: float = _get_side_swipe_lane_clearance(
		ball_origin,
		ball_origin.direction_to(option_a)
	)
	var clearance_b: float = _get_side_swipe_lane_clearance(
		ball_origin,
		ball_origin.direction_to(option_b)
	)
	if clearance_a > base_clearance + 45.0 and clearance_a >= clearance_b:
		return option_a
	if clearance_b > base_clearance + 45.0:
		return option_b
	return base


func _server_execute_side_swipe_kick(
	requested_force: float,
	is_pass: bool,
	now: float
) -> bool:
	if (
		not multiplayer.is_server()
		or not _server_ability_is_active(ABILITY_SIDE_SWIPE)
	):
		return false
	var ball_target: FootballBall = _get_closest_ball_in_kick_area()
	if ball_target == null:
		return false
	var direction: Vector2 = _get_side_swipe_direction(ball_target)
	if direction.is_zero_approx():
		return false
	var strength: float = maxf(0.1, server_ability_strength_scale)
	var force: float = maxf(0.0, requested_force)
	if is_pass:
		force = maxf(force, side_swipe_pass_force)
	else:
		force = maxf(
			force,
			maximum_shot_force * clampf(side_swipe_minimum_shot_ratio, 0.0, 1.0)
		) * maxf(0.1, side_swipe_shot_force_multiplier)
	force *= strength
	var impulse: Vector2 = direction * force
	impulse = _sanitize_cpu_ball_impulse(
		ball_target,
		impulse,
		&"side_swipe"
	)
	if impulse.is_zero_approx():
		return false
	server_last_kick_charge_seconds = 0.0 if is_pass else maxf(0.0, now - server_charge_started_at)
	server_last_kick_was_soft_pass = is_pass
	server_last_kick_time = now
	server_next_kick_is_pass = is_pass
	ball_target.register_kick(
		owner_peer_id,
		display_name,
		team,
		impulse,
		false
	)
	ball_target.apply_central_impulse(impulse)
	server_next_kick_is_pass = false
	_receive_shot_sound.rpc(force)
	_consume_armed_ability(ABILITY_SIDE_SWIPE)
	return true


func _get_side_swipe_direction(ball_target: FootballBall) -> Vector2:
	if ball_target == null:
		return Vector2.ZERO
	var contact_direction: Vector2 = global_position.direction_to(
		ball_target.global_position
	)
	if contact_direction.is_zero_approx():
		contact_direction = _get_ability_facing_direction()
	if contact_direction.is_zero_approx():
		contact_direction = Vector2.RIGHT
	var side_a: Vector2 = Vector2(
		-contact_direction.y,
		contact_direction.x
	).normalized()
	var side_b: Vector2 = -side_a
	var input_direction: Vector2 = server_direction.normalized()
	if not input_direction.is_zero_approx():
		var a_score: float = input_direction.dot(side_a)
		var b_score: float = input_direction.dot(side_b)
		if absf(a_score - b_score) > 0.08:
			var chosen_side: Vector2 = side_a if a_score > b_score else side_b
			return _blend_side_swipe_forward(chosen_side, contact_direction)
	var blended_a: Vector2 = _blend_side_swipe_forward(side_a, contact_direction)
	var blended_b: Vector2 = _blend_side_swipe_forward(side_b, contact_direction)
	var a_clearance: float = _get_side_swipe_lane_clearance(
		ball_target.global_position,
		blended_a
	)
	var b_clearance: float = _get_side_swipe_lane_clearance(
		ball_target.global_position,
		blended_b
	)
	return blended_a if a_clearance >= b_clearance else blended_b


func _blend_side_swipe_forward(
	side_direction: Vector2,
	contact_direction: Vector2
) -> Vector2:
	var forward_weight: float = clampf(side_swipe_forward_blend, 0.0, 1.0)
	var forward: Vector2 = _get_breakaway_attack_direction()
	if forward.is_zero_approx():
		forward = contact_direction.normalized()
	return (side_direction.normalized() + forward * forward_weight).normalized()


func _get_side_swipe_lane_clearance(
	origin: Vector2,
	direction: Vector2,
	requested_probe_distance: float = -1.0
) -> float:
	var parent_node: Node = get_parent()
	if parent_node == null or direction.is_zero_approx():
		return 99999.0
	var probe_length: float = maxf(
		300.0,
		side_swipe_lane_probe_distance
		if requested_probe_distance < 0.0
		else requested_probe_distance
	)
	var segment: Vector2 = direction.normalized() * probe_length
	var segment_length_squared: float = maxf(1.0, segment.length_squared())
	var minimum_clearance: float = 99999.0
	for child in parent_node.get_children():
		var opponent: FootballPlayer = child as FootballPlayer
		if (
			opponent == null
			or opponent == self
			or opponent.team == team
			or opponent.team == &""
			or not opponent.controls_enabled
		):
			continue
		var relative: Vector2 = opponent.global_position - origin
		var progress: float = clampf(
			relative.dot(segment) / segment_length_squared,
			0.0,
			1.0
		)
		if progress <= 0.03:
			continue
		var closest_point: Vector2 = origin + segment * progress
		var clearance: float = opponent.global_position.distance_to(closest_point)
		minimum_clearance = minf(minimum_clearance, clearance)
	return minimum_clearance


func cpu_try_side_swipe_pass() -> bool:
	if (
		not cpu_controlled
		or not multiplayer.is_server()
		or not controls_enabled
		or not _server_ability_is_active(ABILITY_SIDE_SWIPE)
	):
		return false
	return _server_execute_side_swipe_kick(
		maxf(side_swipe_pass_force, soft_pass_force),
		true,
		_server_time_seconds()
	)


func _server_execute_breakaway_pass(now: float) -> bool:
	if (
		not multiplayer.is_server()
		or not _server_ability_is_active(ABILITY_BREAKAWAY)
		or server_is_charging
	):
		return false
	var ball_target: FootballBall = _get_closest_ball_in_kick_area()
	if ball_target == null:
		# Keep the armed state alive when Pass is pressed too early. This lets
		# the player fake/prepare the move instead of wasting it away from the ball.
		return false

	var strength: float = maxf(0.1, server_ability_strength_scale)
	var direction: Vector2 = _get_breakaway_pass_direction(ball_target)
	if direction.is_zero_approx():
		return false

	var forward_player_speed: float = maxf(
		0.0,
		linear_velocity.dot(direction)
	)
	var desired_speed: float = clampf(
		maxf(
			maxf(600.0, breakaway_ball_speed),
			forward_player_speed
				+ maxf(0.0, breakaway_ball_lead_over_player_speed)
		),
		600.0,
		maxf(
			maxf(600.0, breakaway_ball_speed),
			breakaway_maximum_ball_speed
		)
	) * strength
	var safe_mass: float = maxf(0.001, ball_target.mass)
	var desired_velocity: Vector2 = direction * desired_speed
	var impulse: Vector2 = (
		desired_velocity - ball_target.linear_velocity
	) * safe_mass
	impulse = _sanitize_cpu_ball_impulse(
		ball_target,
		impulse,
		&"breakaway"
	)
	if impulse.is_zero_approx():
		return false

	server_last_kick_charge_seconds = 0.0
	server_last_kick_was_soft_pass = true
	server_last_kick_time = now
	server_next_kick_is_pass = true
	ball_target.register_kick(
		owner_peer_id,
		display_name,
		team,
		impulse,
		false
	)
	ball_target.apply_central_impulse(impulse)
	server_next_kick_is_pass = false

	# The first version accelerated the ball and player almost together, so the
	# touch looked like an ordinary weak pass. Give the ball a real head start,
	# then let the player chase it with a short controllable burst.
	apply_central_impulse(
		direction
		* maxf(0.0, breakaway_player_impulse)
		* strength
	)
	server_breakaway_chase_until = (
		now
		+ maxf(0.08, breakaway_chase_duration) * strength
		+ _get_ability_mastery_duration_bonus(ABILITY_BREAKAWAY)
	)
	server_breakaway_chase_direction = direction
	server_breakaway_chase_strength = strength

	next_soft_pass_allowed_at = now + maxf(0.05, soft_pass_cooldown_seconds)
	next_shot_allowed_at = now + maxf(0.05, breakaway_shot_lockout_seconds)
	_receive_player_action_pulse.rpc(
		ACTION_PULSE_PASS,
		1.0,
		ABILITY_BREAKAWAY
	)
	_receive_shot_sound.rpc(maxf(0.0, soft_pass_force))
	_consume_armed_ability(ABILITY_BREAKAWAY)
	return true


func _get_breakaway_pass_direction(ball_target: FootballBall) -> Vector2:
	if ball_target == null:
		return Vector2.ZERO
	var attack_direction: Vector2 = _get_breakaway_attack_direction()
	var requested_direction: Vector2 = server_direction.normalized()
	var base_direction: Vector2 = attack_direction
	if (
		not requested_direction.is_zero_approx()
		and (
			attack_direction.is_zero_approx()
			or requested_direction.dot(attack_direction)
			>= breakaway_minimum_forward_input_dot
		)
	):
		base_direction = requested_direction
	elif base_direction.is_zero_approx():
		base_direction = linear_velocity.normalized()
	if base_direction.is_zero_approx():
		return Vector2.ZERO

	var origin: Vector2 = ball_target.global_position
	var base_clearance: float = _get_breakaway_lane_clearance(
		origin,
		base_direction
	)
	if base_clearance >= maxf(80.0, breakaway_lane_clearance_threshold):
		return base_direction

	var angle: float = deg_to_rad(
		clampf(breakaway_lane_angle_degrees, 5.0, 40.0)
	)
	var left_direction: Vector2 = base_direction.rotated(-angle).normalized()
	var right_direction: Vector2 = base_direction.rotated(angle).normalized()
	var left_clearance: float = _get_breakaway_lane_clearance(
		origin,
		left_direction
	)
	var right_clearance: float = _get_breakaway_lane_clearance(
		origin,
		right_direction
	)
	var best_direction: Vector2 = base_direction
	var best_clearance: float = base_clearance
	if left_clearance > best_clearance + 25.0:
		best_direction = left_direction
		best_clearance = left_clearance
	if right_clearance > best_clearance + 25.0:
		best_direction = right_direction
	return best_direction


func _get_breakaway_attack_direction() -> Vector2:
	var attacking_goal: FootballGoal = _get_attacking_goal()
	if attacking_goal == null:
		return Vector2.ZERO
	var mouth_range: Vector2 = attacking_goal.get_mouth_y_range()
	var goal_center: Vector2 = Vector2(
		attacking_goal.get_goal_plane_x(),
		(mouth_range.x + mouth_range.y) * 0.5
	)
	return global_position.direction_to(goal_center)


func _start_nutmeg_chase(
	direction: Vector2,
	impulse: float = 0.0
) -> void:
	if not multiplayer.is_server():
		return
	var safe_direction: Vector2 = direction.normalized()
	if safe_direction.is_zero_approx():
		return
	server_nutmeg_chase_until = maxf(
		server_nutmeg_chase_until,
		_server_time_seconds()
			+ maxf(0.0, nutmeg_outplay_duration)
			+ _get_ability_mastery_duration_bonus(ABILITY_NUTMEG)
	)
	server_nutmeg_chase_direction = safe_direction
	if impulse > 0.0:
		apply_central_impulse(safe_direction * impulse)


func _get_breakaway_lane_clearance(
	origin: Vector2,
	direction: Vector2
) -> float:
	if direction.is_zero_approx():
		return 0.0
	var parent_node: Node = get_parent()
	if parent_node == null:
		return 99999.0
	var segment: Vector2 = (
		direction.normalized()
		* maxf(300.0, breakaway_lane_probe_distance)
	)
	var segment_length_squared: float = maxf(1.0, segment.length_squared())
	var minimum_clearance: float = 99999.0
	for child in parent_node.get_children():
		var opponent: FootballPlayer = child as FootballPlayer
		if (
			opponent == null
			or opponent == self
			or opponent.team == &""
			or opponent.team == team
			or not opponent.controls_enabled
		):
			continue
		var relative: Vector2 = opponent.global_position - origin
		var progress: float = clampf(
			relative.dot(segment) / segment_length_squared,
			0.0,
			1.0
		)
		if progress <= 0.04:
			continue
		var closest_point: Vector2 = origin + segment * progress
		var clearance: float = opponent.global_position.distance_to(
			closest_point
		)
		minimum_clearance = minf(minimum_clearance, clearance)
	return minimum_clearance


func cpu_try_breakaway_pass() -> bool:
	if (
		not cpu_controlled
		or not multiplayer.is_server()
		or not controls_enabled
		or not _server_ability_is_active(ABILITY_BREAKAWAY)
	):
		return false
	return _server_execute_breakaway_pass(_server_time_seconds())


func _server_arm_snapback_ball(ball_target: FootballBall) -> void:
	if (
		not multiplayer.is_server()
		or ball_target == null
		or not _server_ability_is_active(ABILITY_SNAPBACK)
	):
		return
	server_snapback_ball_id = ball_target.get_instance_id()
	server_snapback_touch_serial = _get_ball_player_touch_serial(ball_target)
	server_snapback_kick_at = _server_time_seconds()
	var mark_duration: float = maxf(
		0.2,
		snapback_recall_window
			+ _get_ability_mastery_duration_bonus(ABILITY_SNAPBACK)
	)
	server_ability_ends_at = server_snapback_kick_at + mark_duration
	ball_target.arm_snapback_mark(owner_peer_id, team, mark_duration)


func cpu_has_snapback_recall() -> bool:
	return (
		cpu_controlled
		and multiplayer.is_server()
		and _server_ability_is_active(ABILITY_SNAPBACK)
		and server_snapback_ball_id != 0
	)


func cpu_get_snapback_kick_age() -> float:
	if server_snapback_kick_at <= 0.0:
		return 0.0
	return maxf(0.0, _server_time_seconds() - server_snapback_kick_at)


func _server_execute_snapback_recall() -> bool:
	if (
		not multiplayer.is_server()
		or not _server_ability_is_active(ABILITY_SNAPBACK)
		or server_snapback_ball_id == 0
	):
		return false
	var now := _server_time_seconds()
	if now - server_snapback_kick_at < maxf(0.0, snapback_minimum_recall_delay):
		return false
	var ball_target := _get_ball_by_instance_id(server_snapback_ball_id)
	if ball_target == null:
		_consume_armed_ability(ABILITY_SNAPBACK)
		return false
	if (
		ball_target.last_touch_peer_id != owner_peer_id
		or ball_target.last_touch_team != team
		or _get_ball_player_touch_serial(ball_target) != server_snapback_touch_serial
	):
		_consume_armed_ability(ABILITY_SNAPBACK)
		return false
	var target_position: Vector2 = (
		global_position
		+ linear_velocity * maxf(0.0, snapback_lead_seconds)
	)
	var distance := ball_target.global_position.distance_to(target_position)
	if distance > maxf(100.0, snapback_maximum_distance):
		_consume_armed_ability(ABILITY_SNAPBACK)
		return false
	var direction := ball_target.global_position.direction_to(target_position)
	if direction.is_zero_approx():
		_consume_armed_ability(ABILITY_SNAPBACK)
		return false
	var recall_speed := clampf(
		maxf(snapback_recall_speed, distance * 2.2),
		maxf(300.0, snapback_recall_speed),
		maxf(snapback_recall_speed, snapback_maximum_recall_speed)
	) * server_ability_strength_scale
	var safe_mass := maxf(0.001, ball_target.mass)
	var desired_velocity := direction * recall_speed
	var incoming_velocity := ball_target.linear_velocity
	var impulse := (desired_velocity - incoming_velocity) * safe_mass
	impulse = _sanitize_cpu_ball_impulse(ball_target, impulse, &"snapback")
	if impulse.is_zero_approx():
		_consume_armed_ability(ABILITY_SNAPBACK)
		return false
	ball_target.register_touch(
		owner_peer_id,
		display_name,
		team,
		incoming_velocity,
		&"snapback",
		incoming_velocity + impulse / safe_mass
	)
	ball_target.apply_central_impulse(impulse)
	ball_target.start_snapback_recall_curve(
		owner_peer_id,
		team,
		maxf(0.15, snapback_curve_duration),
		recall_speed,
		maxf(0.0, snapback_lead_seconds),
		maxf(1.0, snapback_curve_turn_rate)
	)
	_receive_player_action_pulse.rpc(ACTION_PULSE_ABILITY, 1.0, ABILITY_SNAPBACK)
	_receive_shot_sound.rpc(maxf(soft_pass_force, maximum_shot_force * 0.82))
	_consume_armed_ability(ABILITY_SNAPBACK)
	return true


func _get_ball_player_touch_serial(ball_target: FootballBall) -> int:
	if ball_target == null:
		return -1
	# Keep Snapback safe even if a stale Ball script somehow remains in a local
	# install. The updated FootballBall exposes the real monotonic counter.
	if ball_target.has_method("get_player_touch_serial"):
		return int(ball_target.call("get_player_touch_serial"))
	return int(ball_target.get_meta("player_touch_serial", 0))


func _get_ball_by_instance_id(instance_id: int) -> FootballBall:
	if instance_id == 0:
		return null
	for node in get_tree().get_nodes_in_group("football_balls"):
		var candidate := node as FootballBall
		if candidate != null and candidate.get_instance_id() == instance_id:
			return candidate
	return null


func _consume_armed_ability(ability_id: int) -> void:
	if not _server_ability_is_active(ability_id):
		return
	var cooldown := server_pending_cooldown
	if ability_id == ABILITY_BREAKAWAY and draft_perk_id == 46:
		server_breakaway_charges = maxi(0, server_breakaway_charges - 1)
		if server_breakaway_charges > 0:
			cooldown = 0.0
	server_pending_cooldown = 0.0
	server_ability_active = false
	server_active_ability_id = ABILITY_NONE
	server_ability_ends_at = 0.0
	server_ability_strength_scale = 1.0
	if ability_id == ABILITY_SNAPBACK:
		var marked_ball: FootballBall = _get_ball_by_instance_id(server_snapback_ball_id)
		if marked_ball != null:
			marked_ball.clear_snapback_mark()
		server_snapback_ball_id = 0
		server_snapback_touch_serial = 0
		server_snapback_kick_at = 0.0
	server_ability_cooldown_ends_at = _server_time_seconds() + maxf(0.0, cooldown)
	_receive_ability_effect_ended.rpc(ability_id, cooldown)


func _get_player_by_peer_id(peer_id: int) -> FootballPlayer:
	if peer_id <= 0:
		return null
	var parent := get_parent()
	if parent == null:
		return null
	for child in parent.get_children():
		var candidate := child as FootballPlayer
		if candidate != null and candidate.owner_peer_id == peer_id:
			return candidate
	return null


func reset_ability_runtime() -> void:
	if not multiplayer.is_server():
		return

	_reset_draft_perk_action_state()
	server_haaland_predator_until = 0.0
	server_haaland_predator_charge_armed = false
	server_ability_active = false
	server_active_ability_id = ABILITY_NONE
	server_ability_ends_at = 0.0
	server_ability_cooldown_ends_at = 0.0
	server_pass_request_ends_at = 0.0
	_next_pass_request_allowed_at = 0.0
	server_pending_cooldown = 0.0
	server_ability_strength_scale = 1.0
	server_burst_charges = _get_effective_burst_max_charges()
	server_next_burst_allowed_at = 0.0
	server_burst_ball_speed_limits.clear()
	server_elastic_step_charges = _get_effective_elastic_step_max_charges()
	server_mirage_step_charges = _get_effective_mirage_step_max_charges()
	server_breakaway_charges = _get_effective_breakaway_max_charges()
	server_goalkeeper_reach_charges = _get_effective_goalkeeper_reach_max_charges()
	server_boogie_woogie_charges = _get_effective_boogie_woogie_max_charges()
	server_next_elastic_step_allowed_at = 0.0
	server_last_used_ability_id = ABILITY_NONE
	server_last_ability_used_at = 0.0
	server_copycat_stored_ability_id = ABILITY_NONE
	server_copycat_stored_expires_at = 0.0
	server_reflex_blocked_ball_id = 0
	server_reflex_facing = Vector2.ZERO
	server_snapback_ball_id = 0
	server_snapback_touch_serial = 0
	server_snapback_kick_at = 0.0
	_clear_phantom_heel_followup()
	server_breakaway_chase_until = 0.0
	server_breakaway_chase_direction = Vector2.ZERO
	server_breakaway_chase_strength = 1.0
	server_nutmeg_chase_until = 0.0
	server_nutmeg_chase_direction = Vector2.ZERO
	server_next_kick_is_pass = false
	server_human_first_touch_mode = HUMAN_FIRST_TOUCH_NONE
	server_human_first_touch_direction = Vector2.ZERO
	server_human_first_touch_ends_at = 0.0
	server_human_first_touch_dummy_until = 0.0
	_server_clear_echo(true)
	server_direct_finish_volley_requested = false
	server_direct_finish_aim_direction = Vector2.ZERO
	server_direct_finish_candidate_id = 0
	server_direct_finish_candidate_entered_at = 0.0
	server_ability_timers_paused = false
	server_paused_effect_remaining = 0.0
	server_paused_cooldown_remaining = 0.0
	_goalkeeper_blocked_balls.clear()
	_set_ball_body_collision_enabled(true)
	_receive_burst_charge_state.rpc(
		server_burst_charges,
		_get_effective_burst_max_charges()
	)
	_receive_elastic_step_charge_state.rpc(
		server_elastic_step_charges,
		_get_effective_elastic_step_max_charges()
	)
	_receive_ability_reset.rpc()
	_apply_permanent_overdrive()
	_apply_permanent_power_strike()
	_apply_permanent_elastic_step()
	_apply_permanent_iron_anchor()


@rpc("authority", "call_local", "reliable")
func _receive_ability_reset() -> void:
	_cancel_pending_direct_finish_tap()
	_local_human_first_touch_mode = HUMAN_FIRST_TOUCH_NONE
	_local_human_first_touch_ends_at = 0.0
	local_ability_active = false
	local_active_ability_id = ABILITY_NONE
	local_direct_finish_volley_requested = false
	local_ability_effect_remaining = 0.0
	local_copycat_stored_ability_id = ABILITY_NONE
	local_copycat_memory_remaining = 0.0
	local_ability_cooldown_remaining = 0.0
	local_ability_cooldown_total = 0.0
	_decoy_run_visual_generation += 1
	_force_restore_player_render_visibility()
	local_ability_timers_paused = false
	ability_particles.emitting = false
	ability_pulse_particles.emitting = false
	ability_particles.one_shot = true
	ability_particles.explosiveness = 0.82
	meta_vision_trajectory.hide()
	meta_vision_landing_marker.hide()
	_clear_local_echo()


func reset_ability_for_kickoff() -> void:
	if not multiplayer.is_server():
		return

	reset_ability_runtime()
	if (
		server_permanent_overdrive_enabled
		or server_permanent_power_strike_enabled
		or server_permanent_elastic_step_enabled
		or server_permanent_iron_anchor_enabled
	):
		set_ability_timers_paused(true)
		return
	var cooldown := _get_selected_ability_cooldown()
	if selected_ability != ABILITY_NONE and cooldown > 0.0:
		_start_server_cooldown(cooldown)
	set_ability_timers_paused(true)


func set_ability_timers_paused(paused: bool) -> void:
	if (
		not multiplayer.is_server()
		or server_ability_timers_paused == paused
	):
		return

	var now := _server_time_seconds()
	if paused:
		server_paused_effect_remaining = (
			maxf(0.0, server_ability_ends_at - now)
			if server_ability_active
			else 0.0
		)
		server_paused_cooldown_remaining = maxf(
			0.0,
			server_ability_cooldown_ends_at - now
		)
	else:
		if server_ability_active:
			server_ability_ends_at = (
				now + server_paused_effect_remaining
			)
		if server_paused_cooldown_remaining > 0.0:
			server_ability_cooldown_ends_at = (
				now + server_paused_cooldown_remaining
			)

	server_ability_timers_paused = paused
	_receive_ability_timers_paused.rpc(paused)


@rpc("authority", "call_local", "reliable")
func _receive_ability_timers_paused(paused: bool) -> void:
	local_ability_timers_paused = paused


func get_ability_cooldown_fraction() -> float:
	if local_ability_cooldown_total <= 0.0:
		return 0.0

	return clampf(
		local_ability_cooldown_remaining
		/ local_ability_cooldown_total,
		0.0,
		1.0
	)


func get_ability_status_text() -> String:
	if selected_ability == ABILITY_NONE:
		return "NO ABILITY"
	if (
		selected_ability == ABILITY_DIRECT_FINISH
		and _local_direct_finish_tap_pending
	):
		return "TAP SHOOT AGAIN: VOLLEY"
	if selected_ability == ABILITY_BURST_DRIBBLE:
		if local_ability_active:
			return "DASH  %d/%d" % [
				local_burst_charges,
				local_burst_max_charges
			]
		if local_ability_cooldown_remaining > 0.0:
			return "%.1f  |  %d/%d" % [
				local_ability_cooldown_remaining,
				local_burst_charges,
				local_burst_max_charges
			]
		return "READY  %d/%d" % [
			local_burst_charges,
			local_burst_max_charges
		]
	if selected_ability == ABILITY_ELASTIC_STEP:
		if local_ability_active:
			return "STEP  %d/%d" % [
				local_elastic_step_charges,
				local_elastic_step_max_charges
			]
		if local_ability_cooldown_remaining > 0.0:
			return "%.1f  |  %d/%d" % [
				local_ability_cooldown_remaining,
				local_elastic_step_charges,
				local_elastic_step_max_charges
			]
		return "READY  %d/%d" % [
			local_elastic_step_charges,
			local_elastic_step_max_charges
		]
	if selected_ability == ABILITY_BREAKAWAY and local_ability_active:
		return "PASS: BREAKAWAY  %.1f" % local_ability_effect_remaining
	if selected_ability == ABILITY_SNAPBACK and local_ability_active:
		return "KICK / RECALL  %.1f" % local_ability_effect_remaining
	if selected_ability == ABILITY_SIDE_SWIPE and local_ability_active:
		return "PASS / SHOOT SIDE  %.1f" % local_ability_effect_remaining
	if selected_ability == ABILITY_NUTMEG and local_ability_active:
		return "NEXT TOUCH: NUTMEG  %.1f" % local_ability_effect_remaining
	if selected_ability == ABILITY_DECOY_RUN and local_ability_active:
		return "DECOY RUN  %.1f" % local_ability_effect_remaining
	if (
		selected_ability == ABILITY_COPYCAT
		and local_ability_active
	):
		return "COPY: %s %.1f" % [
			get_ability_name(local_active_ability_id).to_upper(),
			local_ability_effect_remaining
		]
	if (
		selected_ability == ABILITY_COPYCAT
		and local_ability_cooldown_remaining <= 0.0
	):
		var copied_id := local_copycat_stored_ability_id
		if (
			copied_id == ABILITY_NONE
			and freeplay_cooldowns_disabled
			and freeplay_copycat_source_ability not in [
				ABILITY_NONE,
				ABILITY_COPYCAT,
				ABILITY_GOALKEEPER_REACH
			]
		):
			copied_id = freeplay_copycat_source_ability
		if copied_id != ABILITY_NONE:
			return "COPIED: %s" % get_ability_name(copied_id).to_upper()
		return "WAITING FOR COPY"
	if (
		selected_ability == ABILITY_DIRECT_FINISH
		and local_ability_active
	):
		return "%s %.1f" % [
			(
				"VOLLEY ARMED"
				if local_direct_finish_volley_requested
				else "TRAP ARMED"
			),
			local_ability_effect_remaining
		]
	if local_ability_active:
		return "ACTIVE %.1f" % local_ability_effect_remaining
	if local_ability_cooldown_remaining > 0.0:
		return "%.1f" % local_ability_cooldown_remaining
	return "READY"


# ================================================================
# TEAM AND RESET
# ================================================================

func assign_team(
	new_team: StringName,
	new_slot: int
) -> void:
	team_slot = new_slot
	team = new_team


func reset_to_position(
	spawn_position: Vector2
) -> void:
	if not multiplayer.is_server():
		return

	linear_velocity = Vector2.ZERO
	_ball_free_linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	server_direction = Vector2.ZERO
	if server_is_charging:
		_receive_charge_stopped.rpc()
	server_is_charging = false

	global_position = spawn_position
	rotation = 0.0
	# Publish hard resets immediately instead of waiting for the next physics
	# integration callback. This matters after goal replays because the player is
	# frozen while replay playback is active and therefore has no physics tick to
	# refresh the replicated motion fields.
	var parent_node := get_parent() as Node2D
	network_position = (
		parent_node.to_local(spawn_position)
		if parent_node != null
		else spawn_position
	)
	network_linear_velocity = Vector2.ZERO
	reset_physics_interpolation()
	sleeping = false
	_receive_hard_visual_reset.rpc(spawn_position)


@rpc("authority", "call_local", "reliable")
func _receive_hard_visual_reset(spawn_position: Vector2) -> void:
	_decoy_run_visual_generation += 1
	_force_restore_player_render_visibility()
	if multiplayer.is_server():
		return

	# A reliable reset must also reset the render-side network cache. Otherwise a
	# stale pre-replay snapshot can pull the replica back toward the Players
	# parent origin (the apparent bottom-left corner) until the next motion packet.
	var parent_node := get_parent() as Node2D
	var local_spawn := (
		parent_node.to_local(spawn_position)
		if parent_node != null
		else spawn_position
	)
	position = local_spawn
	linear_velocity = Vector2.ZERO
	network_position = local_spawn
	network_linear_velocity = Vector2.ZERO
	_network_target_position = local_spawn
	_network_target_velocity = Vector2.ZERO
	_network_last_snapshot_position = local_spawn
	_network_last_snapshot_velocity = Vector2.ZERO
	_network_snapshot_age = 0.0
	_network_smoothed_snapshot_interval = 1.0 / 60.0
	_network_motion_initialized = true
	_network_last_safe_render_position = local_spawn
	reset_physics_interpolation()


func set_controls_enabled(enabled: bool) -> void:
	controls_enabled = enabled
	server_direction = Vector2.ZERO

	if not enabled:
		_cancel_pending_direct_finish_tap()
		if multiplayer.is_server() and server_is_charging:
			_receive_charge_stopped.rpc()
		server_is_charging = false
		_cancel_local_charge()

	if multiplayer.is_server():
		call_deferred("_apply_controls_state", enabled)


func set_freeplay_mode(enabled: bool) -> void:
	if not multiplayer.is_server():
		return

	freeplay_cooldowns_disabled = enabled
	reset_ability_runtime()


func set_match_cooldowns_disabled(enabled: bool) -> void:
	if not multiplayer.is_server():
		return
	match_cooldowns_disabled = enabled
	if enabled:
		server_pending_cooldown = 0.0
		server_ability_cooldown_ends_at = 0.0
		server_paused_cooldown_remaining = 0.0
		_receive_ability_cooldown_started.rpc(selected_ability, 0.0)


func _apply_controls_state(enabled: bool) -> void:
	if enabled:
		freeze = false
		sleeping = false
	else:
		linear_velocity = Vector2.ZERO
		_ball_free_linear_velocity = Vector2.ZERO
		angular_velocity = 0.0
		server_is_charging = false
		freeze = true


func _is_dictator_mbappe() -> bool:
	return display_name.strip_edges() == DICTATOR_MBAPPE_DISPLAY_NAME


func is_satoru_gojo() -> bool:
	return display_name.strip_edges() == SATORU_GOJO_DISPLAY_NAME


func is_neymar_boss() -> bool:
	return display_name.strip_edges() == NEYMAR_DISPLAY_NAME


func is_haaland_boss() -> bool:
	return (
		display_name.strip_edges() == HAALAND_DISPLAY_NAME
		and server_permanent_power_strike_enabled
	)


func set_neuer_boss_profile(enabled: bool) -> void:
	if not multiplayer.is_server():
		return
	if enabled:
		set_meta("prestige_boss_profile", &"manuel_neuer")
		server_neuer_dead_zone_cooldown_ends_at = 0.0
	else:
		if StringName(get_meta("prestige_boss_profile", &"")) == &"manuel_neuer":
			remove_meta("prestige_boss_profile")
		server_neuer_dead_zone_cooldown_ends_at = 0.0


func is_neuer_boss() -> bool:
	return (
		display_name.strip_edges() == MANUEL_NEUER_DISPLAY_NAME
		and StringName(get_meta("prestige_boss_profile", &"")) == &"manuel_neuer"
	)


func cpu_neuer_dead_zone_pass_is_ready() -> bool:
	return (
		cpu_controlled
		and multiplayer.is_server()
		and is_neuer_boss()
		and controls_enabled
		and not server_ability_timers_paused
		and not server_ability_active
		and _server_time_seconds() >= server_neuer_dead_zone_cooldown_ends_at
	)


func cpu_activate_neuer_dead_zone_pass(
	receiver_peer_id: int,
	target_position: Vector2
) -> bool:
	if not cpu_neuer_dead_zone_pass_is_ready():
		return false
	if receiver_peer_id <= 0 or target_position.is_zero_approx():
		return false
	cpu_set_time_skip_pass_route(receiver_peer_id, target_position)
	var now := _server_time_seconds()
	if not _server_time_skip_pass(1.0):
		return false
	server_neuer_dead_zone_cooldown_ends_at = (
		now + maxf(0.0, time_skip_pass_cooldown)
	)
	_receive_ability_started.rpc(ABILITY_TIME_SKIP_PASS, 0.0)
	_receive_player_action_pulse.rpc(
		ACTION_PULSE_ABILITY,
		1.0,
		ABILITY_TIME_SKIP_PASS
	)
	server_last_used_ability_id = ABILITY_TIME_SKIP_PASS
	server_last_ability_used_at = now
	ability_used.emit(owner_peer_id, team, ABILITY_TIME_SKIP_PASS)
	_server_offer_copycat_memory_to_teammates(ABILITY_TIME_SKIP_PASS, now)
	return true


func is_prestige_boss() -> bool:
	return (
		_is_dictator_mbappe()
		or is_satoru_gojo()
		or is_neymar_boss()
		or is_haaland_boss()
		or is_neuer_boss()
	)


func _update_special_boss_name_shine(delta: float) -> void:
	if name_label == null or (
		not _is_dictator_mbappe()
		and not is_satoru_gojo()
		and not is_neymar_boss()
		and not is_haaland_boss()
		and not is_neuer_boss()
	):
		return
	_dictator_name_shine_time = fposmod(
		_dictator_name_shine_time + maxf(0.0, delta),
		TAU
	)
	var shine: float = 0.5 + sin(_dictator_name_shine_time * 2.4) * 0.5
	if _is_dictator_mbappe():
		name_label.add_theme_color_override(
			"font_color",
			DICTATOR_NAME_GOLD.lerp(DICTATOR_NAME_GOLD_BRIGHT, shine)
		)
		name_label.add_theme_color_override(
			"font_shadow_color",
			Color(DICTATOR_NAME_SHADOW, 0.58 + shine * 0.36)
		)
	elif is_satoru_gojo():
		name_label.add_theme_color_override(
			"font_color",
			GOJO_NAME_PURPLE.lerp(GOJO_NAME_PURPLE_BRIGHT, shine)
		)
		name_label.add_theme_color_override(
			"font_shadow_color",
			Color(GOJO_NAME_SHADOW, 0.58 + shine * 0.36)
		)
	elif is_neymar_boss():
		name_label.add_theme_color_override(
			"font_color",
			NEYMAR_NAME_YELLOW.lerp(NEYMAR_NAME_GREEN, shine)
		)
		name_label.add_theme_color_override(
			"font_shadow_color",
			Color(NEYMAR_NAME_SHADOW, 0.58 + shine * 0.34)
		)
	elif is_haaland_boss():
		name_label.add_theme_color_override(
			"font_color",
			HAALAND_NAME_SKY.lerp(HAALAND_NAME_WHITE, shine)
		)
		name_label.add_theme_color_override(
			"font_shadow_color",
			Color(HAALAND_NAME_SHADOW, 0.58 + shine * 0.34)
		)
	else:
		name_label.add_theme_color_override(
			"font_color",
			NEUER_NAME_TEAL.lerp(NEUER_NAME_WHITE, shine)
		)
		name_label.add_theme_color_override(
			"font_shadow_color",
			Color(NEUER_NAME_SHADOW, 0.58 + shine * 0.34)
		)


func _update_name_label() -> void:
	if name_label == null:
		return

	name_label.text = _get_name_label_text_for_peer(
		multiplayer.get_unique_id()
	)
	if _is_dictator_mbappe():
		name_label.add_theme_color_override("font_color", DICTATOR_NAME_GOLD)
		name_label.add_theme_color_override(
			"font_outline_color",
			DICTATOR_NAME_OUTLINE
		)
		name_label.add_theme_color_override(
			"font_shadow_color",
			DICTATOR_NAME_SHADOW
		)
		return
	if is_satoru_gojo():
		name_label.add_theme_color_override("font_color", GOJO_NAME_PURPLE)
		name_label.add_theme_color_override("font_outline_color", GOJO_NAME_OUTLINE)
		name_label.add_theme_color_override("font_shadow_color", GOJO_NAME_SHADOW)
		return
	if is_neymar_boss():
		name_label.add_theme_color_override("font_color", NEYMAR_NAME_YELLOW)
		name_label.add_theme_color_override(
			"font_outline_color",
			NEYMAR_NAME_OUTLINE
		)
		name_label.add_theme_color_override(
			"font_shadow_color",
			NEYMAR_NAME_SHADOW
		)
		return
	if is_haaland_boss():
		name_label.add_theme_color_override("font_color", HAALAND_NAME_SKY)
		name_label.add_theme_color_override("font_outline_color", HAALAND_NAME_OUTLINE)
		name_label.add_theme_color_override("font_shadow_color", HAALAND_NAME_SHADOW)
		return
	if is_neuer_boss():
		name_label.add_theme_color_override("font_color", NEUER_NAME_TEAL)
		name_label.add_theme_color_override("font_outline_color", NEUER_NAME_OUTLINE)
		name_label.add_theme_color_override("font_shadow_color", NEUER_NAME_SHADOW)
		return
	if _is_local_player() and not cpu_controlled:
		name_label.add_theme_color_override(
			"font_color",
			Color.WHITE
		)
		return

	match team:
		&"blue":
			name_label.add_theme_color_override(
				"font_color",
				blue_name_color
			)
		&"red":
			name_label.add_theme_color_override(
				"font_color",
				red_name_color
			)
		_:
			name_label.add_theme_color_override(
				"font_color",
				neutral_name_color
			)


func _get_name_label_text_for_peer(_local_peer_id: int) -> String:
	var safe_name := display_name.strip_edges()
	if (
		not cpu_controlled
		and owner_peer_id > 0
		and owner_peer_id == _local_peer_id
	):
		return "You"
	return safe_name if not safe_name.is_empty() else "Player"
