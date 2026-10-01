class_name FootballMatchManager
extends Node


const GOAL_REACTION_CONTACT_SOUND: AudioStream = preload(
	"res://mixkit-hitting-soccer-ball-2112-godot.wav"
)

const CPU_PLAYER_AI_SCRIPT_PATH: String = "res://Scenes/cpu_player_ai.gd"
const CPU_TEAM_SEQUENCE_PLANNER_PATH: String = (
	"res://ai/team_play/team_sequence_planner.gd"
)
const LARGE_TEAM_PARALLEL_BRAIN_PATH: String = (
	"res://ai/large_team/parallel_snapshot_brain.gd"
)
# Per-CPU worker jobs only pay off when the machine has enough logical CPUs to
# leave headroom for Godot's main/render/physics/audio work. On smaller CPUs the
# existing staggered 5v5/6v6 AI path remains faster and is used automatically.
const LARGE_TEAM_PARALLEL_MINIMUM_LOGICAL_PROCESSORS: int = 12
const AbilityThreatModelScript = preload(
	"res://ai/ability/ability_threat_model.gd"
)
const SharedAISpatialProcessorScript = preload(
	"res://ai/shared/shared_spatial_processor.gd"
)
const INGAME_PAUSE_OVERLAY_SCRIPT: Script = preload(
	"res://Scenes/ingame_pause_overlay.gd"
)
const DRAFT_PANEL_SCENE: PackedScene = preload(
	"res://Scenes/champions_league_draft_panel.tscn"
)



signal roster_changed(red_count: int, blue_count: int)
signal roster_details_changed(roster: Dictionary)
signal score_changed(red_score: int, blue_score: int)
signal tournament_score_changed(
	leg_red_score: int,
	leg_blue_score: int,
	aggregate_red_score: int,
	aggregate_blue_score: int,
	leg: int,
	enabled: bool,
	sudden_death: bool
)
signal timer_changed(display_seconds: int, overtime: bool)
signal announcement_changed(message: String)
signal countdown_changed(message: String)
signal field_variant_changed(variant_index: int)
signal team_introduction_changed(
	team: StringName,
	player_names: Array
)
signal match_settings_changed(
	regulation_seconds: float,
	goals_to_win: int
)
signal cpu_settings_changed(
	blue_cpu_count: int,
	red_cpu_count: int
)
signal cpu_difficulty_changed(level: int)
signal cpu_ability_preferences_changed(
	blue_preferences: Array,
	red_preferences: Array
)
signal tournament_mode_changed(enabled: bool)
signal ranked_mode_changed(enabled: bool)
signal champions_league_mode_changed(enabled: bool)
signal draft_state_changed(snapshot: Dictionary)
signal draft_wins_changed(snapshot: Dictionary)
signal fun_mutators_changed(settings: Dictionary)
signal ranked_draft_changed(snapshot: Dictionary)
signal ladder_state_changed(snapshot: Dictionary)
signal singleplayer_ranked_state_changed(snapshot: Dictionary)
signal halftime_changed(active: bool, seconds_remaining: int)
signal tournament_tiebreak_changed(
	phase: StringName,
	extra_time_period: int,
	penalty_red_score: int,
	penalty_blue_score: int,
	penalty_red_attempts: int,
	penalty_blue_attempts: int,
	penalty_turn: StringName,
	penalty_attempt_active: bool
)
signal goal_focus_requested(scorer_peer_id: int)
signal goal_replay_state_changed(
	active: bool,
	votes: int,
	total_voters: int,
	slow_motion: bool
)
signal goal_replay_presentation_changed(active: bool, presentation: Dictionary)

signal team_join_result(success: bool, team: StringName)
signal ability_selection_result(
	success: bool,
	ability_id: int,
	message: String
)
signal ready_state_result(
	success: bool,
	ready: bool,
	message: String
)
signal match_start_result(success: bool, message: String)
signal match_started
signal match_ended(winning_team: StringName)
signal match_cancelled
signal freeplay_started
signal freeplay_ended
signal freeplay_ability_changed(ability_id: int)
signal leaderboard_changed(entries: Array)
signal player_stat_earned(
	peer_id: int,
	stat_name: StringName
)
signal match_results_ready(
	winning_team: StringName,
	entries: Array
)
signal results_dismissed


const TEAM_RED: StringName = &"red"
const TEAM_BLUE: StringName = &"blue"
const TEAM_SPECTATOR: StringName = &"spectator"
const NO_TEAM: StringName = &""
const SERVER_PEER_ID: int = 1
const RANKED_CANCEL_GRACE_SECONDS: float = 60.0
const LOBBY_PLAYER_PARK_POSITION: Vector2 = Vector2(-2000.0, -2000.0)
const LARGE_TEAM_PRESENTATION_MIN_TEAM_SIZE: int = 4
const FOUR_V_FOUR_ENTITY_SCALE: float = 0.88
const FIVE_PLUS_ENTITY_SCALE: float = 0.75
const CPU_ID_BASE: int = 1000000
const CPU_ABILITY_ATTACK: int = 0
const CPU_ABILITY_PLAYMAKER: int = 1
const CPU_ABILITY_FLEXIBLE: int = 2
const CPU_ABILITY_DEFENSE: int = 3
const CPU_ABILITY_RANDOM: int = -1
const FUN_LOW_FRICTION: StringName = &"low_friction"
const FUN_HEAVY_BALL: StringName = &"heavy_ball"
const FUN_SMALL_GOALS: StringName = &"small_goals"
const FUN_NO_COOLDOWNS: StringName = &"no_cooldowns"
const FUN_FASTER_BALL: StringName = &"faster_ball"
const FUN_NO_WALLS: StringName = &"no_walls"
const FUN_ABILITY_DRAFT: StringName = &"ability_draft"
const FUN_DUPLICATE_ABILITIES: StringName = &"duplicate_abilities"
const FUN_ROTATING_LOADOUTS: StringName = &"rotating_loadouts"
const FUN_DICTATOR_MBAPPE: StringName = &"dictator_mbappe"
const FUN_SATORU_GOJO: StringName = &"satoru_gojo"
const FUN_NEYMAR_JR: StringName = &"neymar_jr"
const FUN_ERLING_HAALAND: StringName = &"erling_haaland"
const FUN_MANUEL_NEUER: StringName = &"manuel_neuer"
const CPU_STRATEGY_BALANCED: StringName = &"balanced"
const CPU_STRATEGY_DIRECT: StringName = &"direct"
const CPU_STRATEGY_COUNTER: StringName = &"counter"
const CPU_STRATEGY_POSSESSION: StringName = &"possession"
const CPU_STRATEGY_HIGH_PRESS: StringName = &"high_press"
const CPU_STRATEGY_WALL_PLAY: StringName = &"wall_play"
const CPU_STRATEGY_ABILITY_COMBO: StringName = &"ability_combo"
const CPU_STRATEGY_FAILURE_ATTACK: StringName = &"attack"
const CPU_STRATEGY_FAILURE_DEFENSE: StringName = &"defense"
const CPU_COMBO_ONE_TWO: StringName = &"one_two"
const CPU_COMBO_THIRD_MAN: StringName = &"third_man"
const CPU_COMBO_WIDE_SWITCH: StringName = &"wide_switch"
const CPU_COMBO_WALL_RELAY: StringName = &"wall_relay"
const CPU_COMBO_ABILITY_CHAIN: StringName = &"ability_chain"
const CPU_COMBO_DEAD_ZONE_TRAP_VOLLEY: StringName = &"dead_zone_trap_volley"
const CPU_COMBO_POWER_STRIKE_TRAP_VOLLEY: StringName = &"power_strike_trap_volley"
const CPU_COMBO_OVERDRIVE_DEAD_ZONE: StringName = &"overdrive_dead_zone"
const CPU_COMBO_GOALKEEPER_REBOUND: StringName = &"goalkeeper_rebound"
const CPU_POSSESSION_TOUCH_LOCK_MSEC: int = 650
const CPU_POSSESSION_SWITCH_CONFIRM_MSEC: int = 180
const CPU_POSSESSION_DISTANCE_MARGIN: float = 150.0
const CPU_POSSESSION_FLIGHT_SPEED: float = 260.0
# Part 3: expensive tactical reconsideration uses gameplay-significance budgets
# only in 5v5/6v6. Movement, physics, first-touch execution and committed actions
# still update every 60 Hz physics tick.
const CPU_TACTICAL_BUDGET_MIN_TEAM_SIZE: int = 5
const CPU_TACTICAL_TIER_CRITICAL: StringName = &"critical"
const CPU_TACTICAL_TIER_HIGH: StringName = &"high"
const CPU_TACTICAL_TIER_NORMAL: StringName = &"normal"
const CPU_TACTICAL_TIER_LOW: StringName = &"low"
const CPU_TACTICAL_CRITICAL_INTERVAL: float = 0.045
const CPU_TACTICAL_HIGH_INTERVAL: float = 0.075
const CPU_TACTICAL_NORMAL_INTERVAL: float = 0.110
const CPU_TACTICAL_LOW_INTERVAL: float = 0.160
const CPU_PLAN_MINIMUM_X: float = 318.0
const CPU_PLAN_MAXIMUM_X: float = 7030.0
const CPU_PLAN_MINIMUM_Y: float = 770.0
const CPU_PLAN_MAXIMUM_Y: float = 4230.0
const TIEBREAK_NONE: StringName = &""
const TIEBREAK_EXTRA_TIME: StringName = &"extra_time"
const TIEBREAK_EXTRA_BREAK: StringName = &"extra_break"
const TIEBREAK_PENALTIES: StringName = &"penalties"
const RANKED_DRAFT_NONE: StringName = &""
const RANKED_DRAFT_TRANSITION: StringName = &"transition"
const RANKED_DRAFT_PREFERENCE: StringName = &"preference"
const RANKED_DRAFT_PROTECT: StringName = &"protect"
const RANKED_DRAFT_BAN: StringName = &"ban"
const RANKED_DRAFT_PICK: StringName = &"pick"
const RANKED_STAGE_GAME_ONE: StringName = &"game_one"
const RANKED_STAGE_GAME_TWO: StringName = &"game_two"
const RANKED_STAGE_EXTRA_TIME: StringName = &"extra_time"
const DRAFT_STAGE_NONE: StringName = &""
const DRAFT_STAGE_LEG_ONE: StringName = &"leg_one"
const DRAFT_STAGE_LEG_TWO: StringName = &"leg_two"
const DRAFT_KIND_ABILITY: StringName = &"ability"
const DRAFT_KIND_PERK: StringName = &"perk"
const DRAFT_PICK_SECONDS: int = 25
const DRAFT_REVIEW_SECONDS: int = 5
const DRAFT_CARD_COUNT: int = 5
const DRAFT_SAVE_PATH: String = "user://draft_leaderboard.cfg"
# Draft uses every currently playable ability. ABILITY_NONE is not a card; CPU
# hands still remove Meta Vision below so enemy CPUs can never receive it.
const DRAFT_SEASONAL_POOL: Array[int] = [
	FootballPlayer.ABILITY_BURST_DRIBBLE,
	FootballPlayer.ABILITY_QUICK_TRIGGER,
	FootballPlayer.ABILITY_POWER_STRIKE,
	FootballPlayer.ABILITY_OVERDRIVE,
	FootballPlayer.ABILITY_HEEL_TURN,
	FootballPlayer.ABILITY_ENFORCER,
	FootballPlayer.ABILITY_GOALKEEPER_REACH,
	FootballPlayer.ABILITY_TIME_SKIP_PASS,
	FootballPlayer.ABILITY_DIRECT_FINISH,
	FootballPlayer.ABILITY_ELASTIC_STEP,
	FootballPlayer.ABILITY_META_VISION,
	FootballPlayer.ABILITY_COPYCAT,
	FootballPlayer.ABILITY_REFLEX_BLOCK,
	FootballPlayer.ABILITY_IRON_ANCHOR,
	FootballPlayer.ABILITY_BLIND_SPOT,
	FootballPlayer.ABILITY_BOOGIE_WOOGIE,
	FootballPlayer.ABILITY_ECHO,
	FootballPlayer.ABILITY_RETURN_TAG,
	FootballPlayer.ABILITY_BREAKAWAY,
	FootballPlayer.ABILITY_SNAPBACK,
	FootballPlayer.ABILITY_SIDE_SWIPE,
	FootballPlayer.ABILITY_NUTMEG,
	FootballPlayer.ABILITY_DECOY_RUN,
]
const DRAFT_PERKS: Array[Dictionary] = [
	{"id": 1, "name": "Extended Overdrive", "description": "Overdrive lasts 1 second longer.", "role": &"mobility", "ability": FootballPlayer.ABILITY_OVERDRIVE},
	{"id": 2, "name": "Quick Release", "description": "Charge full shots 24% faster.", "role": &"attack", "charge_time": 0.76},
	{"id": 3, "name": "Kickoff Encore", "description": "The first ability you use after every kickoff instantly readies again.", "role": &"ability"},
	{"id": 4, "name": "Bend It Forward", "description": "Use your ability, then your next pass within 5s bends through the lane.", "role": &"playmaker"},
	{"id": 5, "name": "Hot Streak", "description": "Scoring removes 4s from your current ability cooldown.", "role": &"attack"},
	{"id": 6, "name": "Second Reach", "description": "Goalkeeper's Reach gets 1 extra dive before its cooldown starts.", "role": &"defense", "ability": FootballPlayer.ABILITY_GOALKEEPER_REACH},
	{"id": 7, "name": "Nutmeg Instinct", "description": "Pressing Ability with a valid nutmeg lane immediately kicks the ball through the defender; otherwise Nutmeg stays armed normally.", "role": &"attack", "ability": FootballPlayer.ABILITY_NUTMEG},
	{"id": 8, "name": "Triple Rhythm", "description": "Every third completed pass instantly refreshes your ability.", "role": &"playmaker"},
	{"id": 9, "name": "Squad Circuit", "description": "Using your ability removes 3s from every teammate's cooldown. Yours is 12% longer.", "role": &"ability", "cooldown": 1.12},
	{"id": 10, "name": "Mirror Charge", "description": "Whenever an opponent uses an ability, your remaining cooldown is cut in half.", "role": &"flexible"},
	{"id": 11, "name": "Reinforced Echo", "description": "Echo survives its first ball block and disappears after the second.", "role": &"defense", "ability": FootballPlayer.ABILITY_ECHO},
	{"id": 12, "name": "Give and Go", "description": "Completed passes remove 2s from your ability cooldown. Pass recovers 18% faster.", "role": &"playmaker", "pass_cooldown": 0.82},
	{"id": 13, "name": "Power Delivery", "description": "A completed pass gives its receiver +30% force on their next shot within 5s.", "role": &"playmaker"},
	{"id": 14, "name": "Rocket Return", "description": "After a completed pass, your next pass within 4s launches with +55% force.", "role": &"playmaker"},
	{"id": 15, "name": "Full-Team Break", "description": "A completed pass gives you and the receiver +20% speed and acceleration for 2s.", "role": &"mobility"},
	{"id": 16, "name": "Rapid Recharge", "description": "Ability cooldowns are 20% shorter.", "role": &"ability", "cooldown": 0.80},
	{"id": 17, "name": "Overclocked Core", "description": "+18% ability strength, 8% longer cooldown.", "role": &"ability", "ability_strength": 1.18, "cooldown": 1.08},
	{"id": 18, "name": "Extended Cut", "description": "Abilities last 20% longer.", "role": &"ability", "ability_duration": 1.20},
	{"id": 19, "name": "Shot Cycle", "description": "Land a shot within 4s after using your ability to erase 40% of its cooldown.", "role": &"attack"},
	{"id": 20, "name": "Goal Roulette", "description": "Scoring rerolls your ability into a different one and readies it instantly.", "role": &"ability"},
	{"id": 21, "name": "Last Stand", "description": "Making a save removes 4s from your current ability cooldown.", "role": &"defense"},
	{"id": 22, "name": "Keeper Launcher", "description": "A save loads your next pass within 6s with +65% force.", "role": &"defense"},
	{"id": 23, "name": "Possession Thief", "description": "Win possession from the other team to halve your cooldown and gain a 2s burst.", "role": &"defense"},
	{"id": 24, "name": "Revenge Rush", "description": "After conceding, gain +30% movement for 4s and load your next shot with +25% force.", "role": &"defense"},
	{"id": 25, "name": "Double Clap", "description": "Boogie Woogie gets 1 extra swap before its cooldown starts.", "role": &"playmaker", "ability": FootballPlayer.ABILITY_BOOGIE_WOOGIE},
	{"id": 26, "name": "Multi-Cast", "description": "Burst Dribble gets 1 extra dash; Elastic Step gets 2 extra steps.", "role": &"ability", "abilities": [FootballPlayer.ABILITY_BURST_DRIBBLE, FootballPlayer.ABILITY_ELASTIC_STEP]},
	{"id": 27, "name": "Afterburner", "description": "Using your ability grants +20% speed for 2 seconds.", "role": &"mobility"},
	{"id": 28, "name": "Loaded Follow-Up", "description": "After using your ability, your next shot within 4 seconds has +25% force.", "role": &"attack"},
	{"id": 29, "name": "One-Two Engine", "description": "Completing a pass grants +18% speed and +25% acceleration for 2.5 seconds.", "role": &"playmaker"},
	{"id": 30, "name": "Combo Window", "description": "Use your ability within 4 seconds of a completed pass to refund 35% of its cooldown.", "role": &"playmaker"},
	{"id": 31, "name": "Ability Relay", "description": "Complete a pass within 5 seconds after using your ability to remove 4 seconds of cooldown.", "role": &"playmaker"},
	{"id": 32, "name": "Clutch Catalyst", "description": "Making a save instantly refreshes your ability.", "role": &"defense"},
	{"id": 33, "name": "Countercharge", "description": "After conceding, refill ability charges or cut the current cooldown in half.", "role": &"defense"},
	{"id": 34, "name": "Finisher Loop", "description": "Score within 5 seconds after using your ability to refresh it instantly.", "role": &"attack"},
	{"id": 35, "name": "First-Time Finish", "description": "After completing a pass, your next shot within 4 seconds has +20% force.", "role": &"attack"},
	{"id": 36, "name": "Hot Potato", "description": "Receive a completed pass: for 4s your next shot OR pass gets +45% force. Using either spends the charge.", "role": &"playmaker"},
	{"id": 37, "name": "Backdoor Deal", "description": "Use your ability, then complete a pass within 5s to instantly ready the receiver's ability.", "role": &"playmaker"},
	{"id": 38, "name": "Free Refill", "description": "After conceding, your next ability creates no cooldown.", "role": &"defense"},
	{"id": 39, "name": "Loaded Dice", "description": "Every ability use rolls one prize: a power shot, power pass, movement burst, or half cooldown.", "role": &"ability"},
	{"id": 40, "name": "Black Market", "description": "Win possession to remove 3s from your cooldown and add 3s to the opponent you took it from.", "role": &"defense"},
	{"id": 41, "name": "Chase Scene", "description": "Whenever an opponent uses an ability, gain +30% speed and acceleration for 2s.", "role": &"mobility"},
	{"id": 42, "name": "Victory Tax", "description": "Scoring adds 2.5s to every opponent's current ability cooldown.", "role": &"attack"},
	{"id": 43, "name": "Reverse Card", "description": "The first enemy ability after each kickoff gets +3s cooldown while your remaining cooldown is halved.", "role": &"flexible"},
	{"id": 44, "name": "Double Feature", "description": "Every second ability use instantly readies itself again for an immediate encore.", "role": &"ability"},
	{"id": 45, "name": "Overflow", "description": "Scoring instantly readies your ability and makes its next use create no cooldown.", "role": &"ability"},
	{"id": 46, "name": "Twin Breakaway", "description": "Breakaway gets +1 charge, letting you use it twice in a row before cooldown.", "role": &"ability", "ability": FootballPlayer.ABILITY_BREAKAWAY},
	{"id": 47, "name": "Ability Mastery", "description": "Upgrades select abilities: Breakaway chase +0.7s, Reflex Block +0.2s, Snapback recall +0.4s, Nutmeg burst +0.45s, Decoy Run +0.5s.", "role": &"ability", "abilities": [FootballPlayer.ABILITY_BREAKAWAY, FootballPlayer.ABILITY_REFLEX_BLOCK, FootballPlayer.ABILITY_SNAPBACK, FootballPlayer.ABILITY_NUTMEG, FootballPlayer.ABILITY_DECOY_RUN]},
	{"id": 48, "name": "Vector Break", "description": "Burst Dribble erases most of your old momentum before each dash, letting you snap into hard direction changes instead of drifting through them.", "role": &"mobility", "ability": FootballPlayer.ABILITY_BURST_DRIBBLE},
	{"id": 49, "name": "Magnus Overload", "description": "Curve Shot bends much harder and stays curved longer, making late obstacle-wrapping shots dramatically easier to shape.", "role": &"attack", "ability": FootballPlayer.ABILITY_QUICK_TRIGGER},
	{"id": 50, "name": "Tap Cannon", "description": "While Power Strike is active, even a tap shot is released at full charge. You still aim normally, but charging is no longer required.", "role": &"attack", "ability": FootballPlayer.ABILITY_POWER_STRIKE},
	{"id": 51, "name": "Redline Eject", "description": "Press Ability again during Overdrive to end it early and cash the remaining state into an immediate directional burst.", "role": &"mobility", "ability": FootballPlayer.ABILITY_OVERDRIVE},
	{"id": 52, "name": "Phantom Magnet", "description": "Phantom Heel's second input stays available longer and can reconnect from much farther away, rescuing combos that would normally fall out of reach.", "role": &"playmaker", "ability": FootballPlayer.ABILITY_HEEL_TURN},
	{"id": 53, "name": "Bruiser Trigger", "description": "While Enforcer is active, press Ability again to instantly shoulder-kick the nearest opponent in your kick area without charging a shot.", "role": &"defense", "ability": FootballPlayer.ABILITY_ENFORCER},
	{"id": 54, "name": "Handbrake Dive", "description": "Press Ability again during Goalkeeper's Reach to cancel the dive, kill your momentum, and regain control immediately.", "role": &"defense", "ability": FootballPlayer.ABILITY_GOALKEEPER_REACH},
	{"id": 55, "name": "Emergency Exit", "description": "If Dead Zone Pass finds no teammate, it becomes a long self-pass into your running lane and launches you after it with a short chase burst.", "role": &"playmaker", "ability": FootballPlayer.ABILITY_TIME_SKIP_PASS},
	{"id": 56, "name": "Instinct Finish", "description": "Trap or Volley reads the incoming ball for you: fast arrivals are volleyed, slower playable arrivals are trapped. No manual choice required.", "role": &"attack", "ability": FootballPlayer.ABILITY_DIRECT_FINISH},
	{"id": 57, "name": "Slingshot Step", "description": "Elastic Step carries the ball out of the orbit faster and farther into your chosen exit lane, turning the dodge itself into a dribble launch.", "role": &"playmaker", "ability": FootballPlayer.ABILITY_ELASTIC_STEP},
	{"id": 58, "name": "Persistent Memory", "description": "Copycat keeps a captured teammate ability for two successful casts before forgetting it instead of consuming the memory after one.", "role": &"ability", "ability": FootballPlayer.ABILITY_COPYCAT},
	{"id": 59, "name": "Perfect Parry", "description": "Reflex Block redirects a successful save toward the center of the opponent's goal instead of merely deflecting it away.", "role": &"defense", "ability": FootballPlayer.ABILITY_REFLEX_BLOCK},
	{"id": 60, "name": "Pocket Anchor", "description": "Iron Anchor deadens the trapped ball into a controllable pocket directly in front of you instead of leaving it where the interception happened.", "role": &"defense", "ability": FootballPlayer.ABILITY_IRON_ANCHOR},
	{"id": 61, "name": "Shadow Carry", "description": "Mirage Step carries the ball farther through the target, kicks it out faster, and gives you a brief acceleration burst to stay attached to the escape.", "role": &"mobility", "ability": FootballPlayer.ABILITY_BLIND_SPOT},
	{"id": 62, "name": "Boogie Ball", "description": "If the ball is in your kick area, Boogie Woogie swaps you with the ball itself. With no nearby ball, it keeps its normal opponent swap.", "role": &"playmaker", "ability": FootballPlayer.ABILITY_BOOGIE_WOOGIE},
]
const LADDER_MAX_RUNG: int = 12
const LADDER_SAVE_PATH: String = "user://seasonal_ladder.cfg"
const LADDER_FINAL_BOSS_NAME: String = "Golden Striker"
const SATORU_GOJO_BOSS_NAME: String = "Satoru Gojo"
const NEYMAR_BOSS_NAME: String = "Neymar Jr"
const HAALAND_BOSS_NAME: String = "Erling Haaland"
const MANUEL_NEUER_BOSS_NAME: String = "Manuel Neuer"
const SINGLEPLAYER_RANKED_SAVE_PATH: String = (
	"user://singleplayer_ranked.cfg"
)
const SINGLEPLAYER_RANKED_MMR_STEP: int = 30
const PVE_RANKED_MMR_STEP_PER_200: int = 5
const PVE_RANKED_MMR_MAX_ADJUSTMENT: int = 15
const PVE_RANKED_HIGH_OPPONENT_PROTECTION_START_GAP: int = 100
const PVE_RANKED_HIGH_OPPONENT_PROTECTION_FULL_GAP: int = 250
const PVE_RANKED_HIGH_OPPONENT_LOSS_REDUCTION_MAX: int = 10
const PVE_RANKED_MIN_MMR: int = 0
const PVE_RANKED_STARTING_MMR: int = 500
const CPU_LEGACY_MAX_INTELLIGENCE: int = 15
const CPU_MAX_INTELLIGENCE: int = 20
const PVE_RANKED_CHAMPIONS_BOSS_CHANCE: float = 0.40
const PVE_RANKED_SLOWDOWN_MMR: int = 800
const PVE_RANKED_OPPONENT_MMR_BY_DIVISION: Array[int] = [
	0, 250, 550, 950, 1300, 1650
]
const SINGLEPLAYER_RANKED_DIVISION_THRESHOLDS: Array[int] = [
	0,
	300,
	600,
	900,
	1200,
	1500
]
# Add future bosses here without changing matchmaking or progression code.
# `profile` selects the existing special-profile implementation.
const SINGLEPLAYER_RANKED_BOSSES: Array[Dictionary] = [
	{
		"id": &"dictator_mbappe",
		"name": LADDER_FINAL_BOSS_NAME,
		"ability": 4,
		"personality": &"aggressive",
		"profile": &"dictator_mbappe"
	},
	{
		"id": &"satoru_gojo",
		"name": SATORU_GOJO_BOSS_NAME,
		"ability": FootballPlayer.ABILITY_IRON_ANCHOR,
		"personality": &"counterattacker",
		"profile": &"satoru_gojo"
	},
	{
		"id": &"neymar_jr",
		"name": NEYMAR_BOSS_NAME,
		"ability": FootballPlayer.ABILITY_ELASTIC_STEP,
		"personality": &"technical",
		"profile": &"neymar_jr"
	},
	{
		"id": &"erling_haaland",
		"name": HAALAND_BOSS_NAME,
		"ability": FootballPlayer.ABILITY_POWER_STRIKE,
		"personality": &"aggressive",
		"profile": &"erling_haaland"
	},
	{
		"id": &"manuel_neuer",
		"name": MANUEL_NEUER_BOSS_NAME,
		"ability": FootballPlayer.ABILITY_GOALKEEPER_REACH,
		"secondary_ability": FootballPlayer.ABILITY_TIME_SKIP_PASS,
		"personality": &"adaptive",
		"profile": &"manuel_neuer"
	}
]
const LADDER_FUNNY_CPU_NAMES: Array[String] = [
	"Alex Storm",
	"Milo Vega",
	"Jonas Falk",
	"Leo Hartmann",
	"Emil Costa",
	"Noah Voss",
	"Luca Moretti",
	"Finn Adler",
	"Elias Berg",
	"Samir Kaya",
	"Tom Becker",
	"Nico Brandt",
	"Max Keller",
	"Ben Wagner",
	"David Silva Jr",
	"Marco Stein",
	"Julian Wolf",
	"Rayan Demir",
	"Felix Sommer",
	"Adam Novak",
	"Leon Kruger",
	"Yusuf Aydin",
	"Mika Lorenz",
	"Daniel Costa",
	"Robin Weiss",
	"Kerem Yilmaz",
	"Paul Winter",
	"Oskar Neumann",
	"Tim Berger",
	"Deniz Arslan",
	"Jan Hoffmann",
	"Anton Richter",
	"Can Kaplan",
	"Louis Schmitt",
	"Jonas Peters",
	"Emre Sahin",
	"Fabian Koch",
	"Malik Hassan",
	"Simon Roth",
	"Kevin Braun"
]

# PvE Ranked uses neutral fictional identities in the lower divisions.
const PVE_RANKED_FUNNY_NAMES_BY_DIVISION: Dictionary = {
	1: [
		"Alex Storm", "Milo Vega", "Jonas Falk", "Leo Hartmann",
		"Emil Costa", "Noah Voss", "Luca Moretti", "Finn Adler",
		"Elias Berg", "Samir Kaya", "Tom Becker", "Nico Brandt",
		"Max Keller", "Ben Wagner", "Marco Stein", "Julian Wolf"
	],
	2: [
		"Rayan Demir", "Felix Sommer", "Adam Novak", "Leon Kruger",
		"Yusuf Aydin", "Mika Lorenz", "Daniel Costa", "Robin Weiss",
		"Kerem Yilmaz", "Paul Winter", "Oskar Neumann", "Tim Berger"
	],
	3: [
		"Deniz Arslan", "Jan Hoffmann", "Anton Richter", "Can Kaplan",
		"Louis Schmitt", "Jonas Peters", "Emre Sahin", "Fabian Koch"
	],
	4: [
		"Malik Hassan", "Simon Roth", "Kevin Braun", "David Silva Jr"
	]
}

# Football identities are also tiered. Bundesliga introduces recognizable
# players; Champions is the modern superstar tier; Theodore mixes the very
# strongest modern names with all-time legends around its guaranteed boss.
const PVE_RANKED_FOOTBALL_NAMES_BY_DIVISION: Dictionary = {
	4: [
		"Jamal Musiala", "Florian Wirtz", "Bukayo Saka", "Pedri",
		"Federico Valverde", "Declan Rice", "Enzo Fernandez", "William Saliba",
		"Lamine Yamal", "Ousmane Dembele", "Thomas Muller", "Toni Kroos"
	],
	5: [
		"Erling Haaland", "Kylian Mbappe", "Lionel Messi", "Cristiano Ronaldo",
		"Vinicius Junior", "Jude Bellingham", "Mohamed Salah", "Kevin De Bruyne",
		"Neymar Junior", "Rodri", "Lamine Yamal", "Ousmane Dembele",
		"Thierry Henry", "Marco van Basten", "Virgil van Dijk", "Antonio Rudiger",
		"Thibaut Courtois", "Alisson Becker"
	],
	6: [
		"Pele", "Diego Maradona", "Ronaldo Nazario", "Johan Cruyff",
		"Zinedine Zidane", "Ronaldinho", "Lionel Messi", "Cristiano Ronaldo",
		"Erling Haaland", "Kylian Mbappe", "Paolo Maldini", "Franz Beckenbauer",
		"Roberto Carlos", "Garrincha", "Manuel Neuer", "Gianluigi Buffon"
	]
}
const PVE_RANKED_BUNDESLIGA_FOOTBALLER_CHANCE: float = 0.58
const PVE_RANKED_UPPER_DIVISION_GUEST_INTERVAL: int = 5
const PVE_RANKED_ELITE_DRAFT_ABILITY_CHANGE_CHANCE: float = 0.40
const LADDER_ELITE_NAMES_BY_ABILITY: Dictionary = {
	0: ["Johan Cruyff", "Pele"],
	1: ["Lionel Messi", "Kylian Mbappe", "Thierry Henry", "Lamine Yamal"],
	2: ["Alessandro Del Piero", "Ousmane Dembele", "Bukayo Saka"],
	3: ["Roberto Carlos", "Cristiano Ronaldo", "Pele"],
	4: ["Vinicius Junior", "Gareth Bale"],
	5: ["Ronaldinho", "Neymar Junior", "Lamine Yamal"],
	6: ["Enzo Fernandez", "Federico Valverde"],
	7: ["Manuel Neuer", "Gianluigi Buffon"],
	8: ["Kevin De Bruyne", "Toni Kroos", "Pedri"],
	9: ["Marco van Basten", "Erling Haaland", "Pele"],
	10: ["Neymar Junior", "Jamal Musiala", "Florian Wirtz"],
	11: ["Luka Modric", "Andrea Pirlo", "Pedri"],
	12: ["Johan Cruyff", "Florian Wirtz"],
	13: ["Zinedine Zidane", "Thibaut Courtois", "Iker Casillas"],
	14: ["Rodri", "Claude Makelele", "Declan Rice"],
	15: ["Diego Maradona", "Lamine Yamal"],
	16: ["N'Golo Kante", "Andres Iniesta"],
	17: ["Paolo Maldini", "Franz Beckenbauer", "William Saliba"],
	18: ["Xavi Hernandez", "David Beckham", "Pedri"],
	19: ["Jude Bellingham", "Ronaldo Nazario", "Kaka", "Ousmane Dembele"],
	20: ["David Beckham", "Mohamed Salah", "Bukayo Saka"],
	21: ["Garrincha", "Luis Figo", "Ousmane Dembele", "Lamine Yamal"],
	22: ["Jamal Musiala", "Ronaldinho", "Ousmane Dembele"],
	23: ["Thomas Muller", "Filippo Inzaghi", "Florian Wirtz"]
}

# PvE Ranked elite names now carry recognizable football identities instead of
# every non-boss CPU falling back to the deterministic `auto` personality.
# The selected ability can still nudge a compatible elite into the style that
# best expresses that specific kit (for example Messi + Burst Dribble stays
# technical, while a pace specialist with Breakaway becomes a counterattacker).
const PVE_RANKED_ELITE_PERSONALITY_BY_NAME: Dictionary = {
	"Lionel Messi": &"technical",
	"Kylian Mbappe": &"counterattacker",
	"Thierry Henry": &"counterattacker",
	"Lamine Yamal": &"technical",
	"Alessandro Del Piero": &"technical",
	"Ousmane Dembele": &"technical",
	"Bukayo Saka": &"counterattacker",
	"Roberto Carlos": &"direct",
	"Cristiano Ronaldo": &"direct",
	"Pele": &"adaptive",
	"Vinicius Junior": &"counterattacker",
	"Gareth Bale": &"counterattacker",
	"Ronaldinho": &"technical",
	"Neymar Junior": &"technical",
	"Enzo Fernandez": &"possession",
	"Federico Valverde": &"aggressive",
	"Manuel Neuer": &"adaptive",
	"Gianluigi Buffon": &"adaptive",
	"Kevin De Bruyne": &"possession",
	"Toni Kroos": &"possession",
	"Pedri": &"possession",
	"Marco van Basten": &"direct",
	"Erling Haaland": &"direct",
	"Jamal Musiala": &"technical",
	"Florian Wirtz": &"technical",
	"Luka Modric": &"possession",
	"Andrea Pirlo": &"possession",
	"Johan Cruyff": &"adaptive",
	"Zinedine Zidane": &"adaptive",
	"Thibaut Courtois": &"adaptive",
	"Iker Casillas": &"adaptive",
	"Rodri": &"possession",
	"Claude Makelele": &"aggressive",
	"Declan Rice": &"aggressive",
	"Diego Maradona": &"technical",
	"N'Golo Kante": &"aggressive",
	"Andres Iniesta": &"possession",
	"Paolo Maldini": &"adaptive",
	"Franz Beckenbauer": &"adaptive",
	"William Saliba": &"aggressive",
	"Xavi Hernandez": &"possession",
	"David Beckham": &"possession",
	"Jude Bellingham": &"aggressive",
	"Ronaldo Nazario": &"counterattacker",
	"Kaka": &"counterattacker",
	"Mohamed Salah": &"counterattacker",
	"Garrincha": &"technical",
	"Luis Figo": &"technical",
	"Thomas Muller": &"adaptive",
	"Filippo Inzaghi": &"direct",
	"Virgil van Dijk": &"adaptive",
	"Antonio Rudiger": &"aggressive",
	"Alisson Becker": &"adaptive"
}
const LADDER_ENCOUNTERS: Array[Dictionary] = [
	{
		"name": "Rookie Circuit",
		"strategy": CPU_STRATEGY_BALANCED,
		"band": 1,
		"count": Vector2i(1, 2),
		"abilities": [10, 22, 7, 8],
		"personalities": [&"adaptive", &"technical", &"possession", &"direct"]
	},
	{
		"name": "Street Press",
		"strategy": CPU_STRATEGY_HIGH_PRESS,
		"band": 1,
		"count": Vector2i(1, 3),
		"abilities": [1, 6, 13, 22],
		"personalities": [&"aggressive", &"direct", &"counterattacker", &"adaptive"]
	},
	{
		"name": "Alley Break",
		"strategy": CPU_STRATEGY_COUNTER,
		"band": 1,
		"count": Vector2i(1, 3),
		"abilities": [19, 5, 13, 1],
		"personalities": [&"counterattacker", &"technical", &"adaptive", &"aggressive"]
	},
	{
		"name": "Wall Runners",
		"strategy": CPU_STRATEGY_WALL_PLAY,
		"band": 2,
		"count": Vector2i(2, 4),
		"abilities": [3, 9, 5, 10],
		"personalities": [&"technical", &"direct", &"possession", &"adaptive"]
	},
	{
		"name": "Counter Current",
		"strategy": CPU_STRATEGY_COUNTER,
		"band": 2,
		"count": Vector2i(2, 4),
		"abilities": [4, 8, 7, 19],
		"personalities": [&"counterattacker", &"possession", &"adaptive", &"direct"]
	},
	{
		"name": "Iron Curtain",
		"strategy": CPU_STRATEGY_BALANCED,
		"band": 3,
		"count": Vector2i(2, 4),
		"abilities": [14, 13, 6, 2],
		"personalities": [&"possession", &"aggressive", &"counterattacker", &"technical"]
	},
	{
		"name": "Orbit Keepers",
		"strategy": CPU_STRATEGY_POSSESSION,
		"band": 3,
		"count": Vector2i(3, 4),
		"abilities": [8, 16, 14, 9],
		"personalities": [&"possession", &"technical", &"adaptive", &"direct"]
	},
	{
		"name": "Phantom Circuit",
		"strategy": CPU_STRATEGY_ABILITY_COMBO,
		"band": 4,
		"count": Vector2i(3, 4),
		"abilities": [15, 20, 10, 23],
		"personalities": [&"technical", &"adaptive", &"aggressive", &"counterattacker"]
	},
	{
		"name": "Voltage Attack",
		"strategy": CPU_STRATEGY_DIRECT,
		"band": 4,
		"count": Vector2i(3, 4),
		"abilities": [3, 4, 9, 22],
		"personalities": [&"direct", &"counterattacker", &"technical", &"aggressive"]
	},
	{
		"name": "Final Constellation",
		"strategy": CPU_STRATEGY_ABILITY_COMBO,
		"band": 5,
		"count": Vector2i(4, 4),
		"abilities": [3, 9, 8, 4],
		"personalities": [&"direct", &"technical", &"possession", &"adaptive"]
	}
]


@export_category("Match Settings")
@export var regulation_seconds: float = 150.0
@export var goals_to_win: int = 10
@export var tournament_mode: bool = false
@export var ranked_mode: bool = false
@export var champions_league_mode: bool = false
@export_category("Fun Match Mutators")
@export var fun_low_friction_ball_damp: float = 0.12
@export var fun_heavy_ball_mass_multiplier: float = 2.0
@export var fun_heavy_ball_size_multiplier: float = 1.35
@export var fun_faster_ball_speed_multiplier: float = 1.35
@export var fun_small_goal_scale: float = 0.72
@export var fun_rotating_loadout_seconds: float = 20.0
@export_range(1, 20, 1)
var cpu_ai_level: int = 8
@export var goal_processing_delay: float = 5.0
@export var countdown_seconds: int = 3
@export var announcement_seconds: float = 4.0
@export var team_introduction_seconds: float = 4.35
@export var team_introduction_gap_seconds: float = 0.18
@export var tournament_halftime_seconds: float = 30.0
@export_category("Ranked Rules")
@export_range(3, 30, 1)
var ranked_preference_seconds: int = 20
@export_range(1, 6, 1)
var ranked_transition_seconds: int = 5
@export_range(3, 30, 1)
var ranked_vote_seconds: int = 15
@export_range(5, 60, 1)
var ranked_pick_seconds: int = 30
@export var ranked_total_extra_time_seconds: float = 150.0
@export var ranked_penalty_kicker_distance_from_ball: float = 640.0
@export_category("Tournament Tiebreak")
@export_range(0.05, 0.5, 0.01)
var tournament_extra_time_period_ratio: float = 1.0 / 4.0
@export var tournament_extra_time_minimum_seconds: float = 10.0
@export var tournament_pre_extra_time_break_seconds: float = 5.0
@export var tournament_extra_time_break_seconds: float = 5.0
@export_range(1, 10, 1)
var penalty_kicks_per_team: int = 5
@export var penalty_attempt_seconds: float = 4.0
@export_range(1, 5, 1)
var penalty_countdown_seconds: int = 3
@export var penalty_spot_distance_from_goal: float = 1650.0
@export_range(1.0, 64.0, 1.0)
var penalty_ball_move_start_threshold: float = 10.0
@export var penalty_kicker_distance_from_ball: float = 420.0
@export var penalty_goalkeeper_distance_from_line: float = 90.0
@export var penalty_staging_y: float = 5000.0
@export_range(1, 64, 1)
var field_variant_count: int = 18

@export_category("CPU Self-Play Training")
@export var cpu_training_mode: bool = false

@export_category("Development Profiling")
@export var kickoff_profiling_enabled: bool = false
@export_range(4, 30, 1)
var kickoff_profile_frame_count: int = 12
@export var runtime_spike_profiling_enabled: bool = false
@export_range(16.0, 100.0, 1.0)
var runtime_spike_threshold_msec: float = 24.0
@export_range(0.25, 10.0, 0.25)
var runtime_spike_report_cooldown_seconds: float = 1.0

@export_category("Shared Team Sequence Planner")
@export var cpu_team_sequence_planner_enabled: bool = true
@export_range(0.1, 1.0, 0.01)
var cpu_team_sequence_cache_seconds: float = 0.44

@export_category("Goal Replay")
@export_range(1.0, 12.0, 0.1)
var goal_replay_history_seconds: float = 6.0
@export_range(5.0, 60.0, 1.0)
var goal_replay_capture_rate: float = 20.0
@export_range(0.1, 1.0, 0.01)
var goal_replay_max_frame_gap_seconds: float = 0.35
@export_range(0.0, 12.0, 0.1)
var goal_replay_focus_seconds: float = 6.0
@export_range(0.0, 2.0, 0.05)
var goal_replay_slow_motion_lead_seconds: float = 0.75
@export_range(0.0, 1.5, 0.05)
var goal_replay_slow_motion_follow_seconds: float = 0.3
@export_range(0.05, 1.0, 0.01)
var goal_replay_slow_motion_scale: float = 0.32

@export_category("Quick Chat")
@export var quick_chat_messages: Array[String] = [
	"Guter Schuss!",
	"Guter Pass!",
	"Was für eine Parade!",
	"Ich verteidige!",
	"Ich passe!",
	"In die Mitte!",
	"Entschuldigung!",
	"GG!"
]
@export var quick_chat_bubble_seconds: float = 2.4
@export var quick_chat_cooldown_seconds: float = 0.75
@export_range(0.0, 1.0, 0.01)
var cpu_quick_chat_goal_chance: float = 0.75
@export_range(0.0, 1.0, 0.01)
var cpu_quick_chat_goal_reply_chance: float = 0.18
@export_range(0.0, 1.0, 0.01)
var cpu_quick_chat_midgame_chance: float = 0.50
@export_range(5.0, 90.0, 1.0)
var cpu_quick_chat_midgame_min_seconds: float = 13.0
@export_range(5.0, 120.0, 1.0)
var cpu_quick_chat_midgame_max_seconds: float = 28.0
@export_range(0.0, 20.0, 0.25)
var cpu_quick_chat_global_cooldown_seconds: float = 6.5

@export_category("CPU Adaptive Strategy")
@export_range(1, 20, 1)
var cpu_strategy_adaptation_minimum_level: int = 7
@export var cpu_strategy_evaluation_seconds: float = 6.0
@export var cpu_strategy_switch_cooldown_seconds: float = 18.0
@export_range(1, 5, 1)
var cpu_strategy_failure_windows_required: int = 2
@export var cpu_attack_progress_minimum: float = 420.0
@export var cpu_defense_relief_minimum: float = 320.0

@export_category("Shot and Save Detection")
@export var minimum_shot_speed: float = 300.0
@export var goal_mouth_vertical_padding: float = 0.0
@export var minimum_save_threat_speed: float = 140.0
@export var save_goal_mouth_margin: float = 260.0
@export var save_detection_distance_from_goal: float = 1700.0
@export var save_confirmation_seconds: float = 0.6

@export_category("Completed Pass Detection")
@export var completed_pass_max_seconds: float = 2.5
@export var completed_pass_minimum_distance: float = 140.0

@export_category("Goal Sound")
@export var goal_scored_sound: AudioStream
@export var dictator_mbappe_goal_sound: AudioStream
@export var satoru_gojo_goal_sound: AudioStream
@export_range(-80.0, 24.0, 0.1)
var goal_sound_volume_db: float = 0.0
@export_range(0.1, 4.0, 0.01)
var goal_sound_pitch_scale: float = 1.0

@export_category("Goal Reaction")
# Keep the foundation natural: a recorded football contact is layered twice
# for the quick arcade punch. A real crowd recording can be assigned here
# without changing the goal-theme/cosmetic system.
@export var goal_reaction_crowd_sound: AudioStream
@export_range(-40.0, 6.0, 0.1)
var goal_reaction_crowd_volume_db: float = -10.5

@export_range(1, 6, 1)
var min_players_per_team: int = 1

@export_range(1, 6, 1)
var max_players_per_team: int = 6
@export_range(0, 8, 1) var max_spectators: int = 4


@export_category("Network Players")
@export var players_parent: Node2D
@export var training_dummy_scene: PackedScene

@export_category("Freeplay Training")
@export var freeplay_dummy_offset_from_ball: Vector2 = Vector2(
	720.0,
	0.0
)
@export var freeplay_ball_launch_distance: float = 1250.0
@export var freeplay_ball_launch_speed: float = 4300.0
@export var freeplay_ball_minimum_x: float = 150.0
@export var freeplay_ball_maximum_x: float = 7200.0
@export var freeplay_ball_minimum_y: float = 850.0
@export var freeplay_ball_maximum_y: float = 4150.0


@export_category("Goals and Ball")
@export var red_goal: FootballGoal
@export var blue_goal: FootballGoal
@export var ball: FootballBall
@export var ball_spawn: Marker2D


@export_category("Player Spawn Positions")
@export var red_player_spawns: Array[Marker2D] = []
@export var blue_player_spawns: Array[Marker2D] = []


var red_score: int = 0
var blue_score: int = 0

# These arrays are authoritative only on the server.
var red_players: Array[FootballPlayer] = []
var blue_players: Array[FootballPlayer] = []

var round_resetting: bool = false
var game_has_started: bool = false
var freeplay_active: bool = false
var is_overtime: bool = false
var regulation_time_remaining: float = 150.0
var overtime_elapsed: float = 0.0
var ranked_active_match_elapsed: float = 0.0
var _pve_ranked_abandonment_protection_armed: bool = false
var current_field_variant: int = 0
var field_variant_locked: bool = false
var _human_demo_sample_accumulator: float = 0.0
var _human_demo_recent_completed_passes: Dictionary = {}
var _human_demo_pending_result: Dictionary = {}
var _cpu_benchmark_metrics: Dictionary = {}
var _hybrid_ai_diagnostics: Dictionary = {}
var leaderboard_snapshot: Array = []
var match_results_available: bool = false
var last_winning_team: StringName = NO_TEAM
var tournament_leg: int = 1
var tournament_leg_red_goals: int = 0
var tournament_leg_blue_goals: int = 0
var tournament_sudden_death: bool = false
var tournament_halftime_active: bool = false
var tournament_halftime_remaining: int = 0
var draft_active: bool = false
var draft_stage: StringName = DRAFT_STAGE_NONE
var draft_kind: StringName = DRAFT_KIND_ABILITY
var draft_seconds_remaining: int = 0
var draft_review_active: bool = false
var draft_hands: Dictionary = {}
var draft_picks: Dictionary = {}
var draft_leg_one_picks: Dictionary = {}
var draft_perk_picks: Dictionary = {}
var draft_leg_one_perks: Dictionary = {}
var draft_match_seed: int = 0
var _draft_generation: int = 0
var _draft_initial_complete: bool = false
var _draft_matchup_introduction_complete: bool = false
var _draft_matchup_introduction_pending: bool = false
var draft_wins: Dictionary = {"1v1": 0, "2v2": 0, "4v4": 0, "5v5": 0, "6v6": 0, "overall": 0}
var ranked_draft_active: bool = false
var ranked_draft_stage: StringName = RANKED_DRAFT_NONE
var ranked_draft_phase: StringName = RANKED_DRAFT_NONE
var ranked_draft_turn_team: StringName = NO_TEAM
var ranked_draft_seconds_remaining: int = 0
var ranked_draft_transition_title: String = ""
var ranked_draft_transition_subtitle: String = ""
var ranked_protected_abilities: Dictionary = {}
var ranked_banned_abilities: Dictionary = {}
var ranked_previous_used_abilities: Dictionary = {}
var tournament_tiebreak_phase: StringName = TIEBREAK_NONE
var tournament_extra_time_period: int = 0
var tournament_extra_time_remaining: float = 0.0
var penalty_shootout_active: bool = false
var penalty_red_score: int = 0
var penalty_blue_score: int = 0
var penalty_red_attempts: int = 0
var penalty_blue_attempts: int = 0
var penalty_turn: StringName = NO_TEAM
var penalty_attempt_active: bool = false
var penalty_attempt_time_remaining: float = 0.0
var _penalty_attempt_clock_started: bool = false
var _penalty_ball_start_position: Vector2 = Vector2.ZERO
var penalty_kicker_peer_id: int = 0
var penalty_goalkeeper_peer_id: int = 0
var penalty_attempt_serial: int = 0
var _last_penalty_kicker_peer_by_team: Dictionary = {}

var _timer_sync_accumulator: float = 0.0
var _timer_sync_serial: int = 0
var _last_received_timer_sync_serial: int = -1
var _match_clock_waiting_for_kickoff: bool = false
var _reset_generation: int = 0
var _announcement_generation: int = 0
var _current_announcement: String = ""
var _current_countdown: String = ""
var _current_introduction_team: StringName = NO_TEAM
var _current_introduction_names: Array = []
var _team_introduction_skip_requested: bool = false
var _player_statistics: Dictionary = {}
var _active_shot: Dictionary = {}
var _previous_authoritative_ball_position: Vector2 = Vector2.ZERO
var _save_check_generation: int = 0
var _ready_players: Dictionary = {}
var _pending_pass: Dictionary = {}
var _cpu_pass_intentions: Dictionary = {}
var _cpu_ball_commitments: Dictionary = {}
var _cpu_defensive_assignments: Dictionary = {}
var _cpu_defensive_telemetry: Dictionary = {}
var _cpu_tactical_intentions: Dictionary = {}
var _cpu_combination_plans: Dictionary = {}
var _cpu_ability_team_plans: Dictionary = {}
var _cpu_team_sequence_plans: Dictionary = {}
var _cpu_team_sequence_frame_cache: Dictionary = {}
# 5v5/6v6 high-core machines build the expensive pure-data team sequence plans
# asynchronously. The physics thread only submits snapshots and consumes completed
# results; it never waits for a worker task.
var _cpu_team_sequence_async_tasks: Dictionary = {}
# Large-team off-ball support is a team-level decision. Keeping this shared avoids
# every CPU independently rebuilding the same full support map on one frame.
var _cpu_large_team_support_cache: Dictionary = {}
# Part 1 shared AI world model. The active rosters, per-player state, ball state,
# and common distance/control facts are captured once per physics frame and then
# reused by every CPU system. This keeps the current AI decisions intact while
# removing repeated 10-12 player scans and duplicate snapshot construction.
var _cpu_shared_world_model: Dictionary = {}
var _cpu_shared_world_frame: int = -1
var _cpu_shared_world_serial: int = 0
var _cpu_shared_world_blue_roster_size: int = -1
var _cpu_shared_world_red_roster_size: int = -1
# Part 2 spatial layer derived from the Part 1 world snapshot. This holds the
# once-per-frame pairwise distance matrix, shared pressure query cache, ball
# trajectory samples and per-player arrival estimates.
var _cpu_shared_spatial_model: Dictionary = {}
var _cpu_shared_spatial_frame: int = -1
# Part 3 event-driven tactical scheduler. Global events wake the large-team brains
# after a kick/possession swing/shot, while peer events wake only the affected
# receiver/chaser. The per-frame budget cache is derived from the Part 1 world
# model and therefore does not rescan the SceneTree.
var _cpu_tactical_global_event_serial: int = 0
var _cpu_tactical_global_event_reason: StringName = &""
var _cpu_tactical_peer_event_serials: Dictionary = {}
var _cpu_tactical_peer_event_reasons: Dictionary = {}
var _cpu_tactical_budget_frame: int = -1
var _cpu_tactical_budget_cache: Dictionary = {}
var _cpu_tactical_last_blue_chaser_peer_id: int = 0
var _cpu_tactical_last_red_chaser_peer_id: int = 0
var _cpu_possession_evaluated_frame: int = -1
var _cpu_team_sequence_planner
# 5v5/6v6: one immutable world snapshot is shared by all CPU brains. The
# RefCounted planner runs only copied-data math on WorkerThreadPool threads; the
# MatchManager/players remain exclusively owned by the main physics thread.
var _large_team_parallel_brain
var _large_team_parallel_plans: Dictionary = {}
var _large_team_parallel_result_frame: int = -1
var _large_team_parallel_submit_frame: int = -1
var _large_team_parallel_service_frame: int = -1
var _large_team_parallel_active_cache_frame: int = -1
var _large_team_parallel_active_cached: bool = false
# Part 4: significance-aware scheduling for the worker-side tactical prepass.
var _large_team_parallel_next_due_msec: Dictionary = {}
var _large_team_parallel_seen_global_event_serial: Dictionary = {}
var _large_team_parallel_seen_peer_event_serial: Dictionary = {}
var _cpu_possession_team: StringName = NO_TEAM
var _cpu_possession_candidate_team: StringName = NO_TEAM
var _cpu_possession_candidate_since_msec: int = 0
var _cpu_last_touch_team: StringName = NO_TEAM
var _cpu_last_touch_peer_id: int = 0
var _cpu_last_touch_msec: int = 0
var _freeplay_training_dummy: FootballPlayer
var requested_blue_cpu_count: int = 0
var requested_red_cpu_count: int = 0
var ladder_mode: bool = false
var ladder_rung: int = 1
var ladder_best_rung: int = 0
var ladder_season_clears: int = 0
var ladder_run_seed: int = 0
var ladder_encounter: Dictionary = {}
var ladder_last_result: StringName = &""
var ladder_human_team: StringName = TEAM_BLUE
var ladder_cpu_team: StringName = TEAM_RED
var ladder_progress_path: String = LADDER_SAVE_PATH
var _ladder_prepare_pending: bool = false
var singleplayer_ranked_mode: bool = false
var pve_ranked_multiplayer_mode: bool = false
var _pve_ranked_player_profiles: Dictionary = {}
# PvE Ranked matchmaking is party-based. The highest-rated HUMAN in the
# selected party slot set determines the CPU division/intelligence. Each
# player's personal MMR is still updated from that player's own rating.
var pve_ranked_matchmaking_mmr: int = PVE_RANKED_STARTING_MMR
var pve_ranked_matchmaking_matches: int = 0
var singleplayer_ranked_last_boss_id: StringName = &""
var singleplayer_ranked_boss_rotation_index: int = -1
var pve_ranked_matchmaking_division: int = 1
var pve_ranked_matchmaking_locked: bool = false
var singleplayer_ranked_mmr: int = PVE_RANKED_STARTING_MMR
var singleplayer_ranked_matches: int = 0
var singleplayer_ranked_team_size: int = 1
var singleplayer_ranked_division: int = 1
var singleplayer_ranked_human_team: StringName = TEAM_BLUE
var singleplayer_ranked_cpu_team: StringName = TEAM_RED
var singleplayer_ranked_last_change: int = 0
var singleplayer_ranked_last_result: StringName = &""
var singleplayer_ranked_encounter: Dictionary = {}
var singleplayer_ranked_progress_path: String = (
	SINGLEPLAYER_RANKED_SAVE_PATH
)
var _singleplayer_ranked_prepare_pending: bool = false
var _cpu_team_strategies: Dictionary = {
	TEAM_BLUE: CPU_STRATEGY_BALANCED,
	TEAM_RED: CPU_STRATEGY_BALANCED
}
var _cpu_strategy_adaptation: Dictionary = {}
var blue_cpu_ability_preferences: Array[int] = [-1, -1, -1, -1, -1, -1]
var red_cpu_ability_preferences: Array[int] = [-1, -1, -1, -1, -1, -1]
var _next_cpu_id: int = CPU_ID_BASE
var _large_team_presentation_active: bool = false
var _large_team_entity_multiplier: float = 1.0
var _large_team_team_size: int = 0
var _draft_panel: ChampionsLeagueDraftPanel
var _cpu_reconcile_scheduled: bool = false
var _cpu_ability_rng := RandomNumberGenerator.new()
var _default_regulation_seconds: float
var _default_goals_to_win: int
var _default_tournament_mode: bool
var _default_ranked_mode: bool
var _default_cpu_ai_level: int
var fun_mutators: Dictionary = {}
var _fun_rotation_remaining: float = 0.0
var _fun_runtime_applied: bool = false
var _fun_default_ball_damp: float = 0.0
var _fun_default_ball_mass: float = 1.0
var _fun_default_ball_maximum_speed: float = 0.0
var _fun_default_ball_containment: bool = true
var _fun_default_ball_goal_mouth_y: Vector2 = Vector2(1727.5, 3272.5)
var _fun_default_visual_goal_mouth_y: Vector2 = Vector2(1727.5, 3272.5)
var _fun_boundary_defaults: Dictionary = {}
var _fun_dictator_cpu: FootballPlayer
var _fun_dictator_original_name: String = ""
var _fun_dictator_original_ability: int = FootballPlayer.ABILITY_NONE
var _fun_dictator_original_cosmetic_loadout: Dictionary = {}
var _fun_dictator_original_personality: StringName = &"auto"
var _fun_dictator_original_skill_override: int = 0
var _fun_gojo_cpu: FootballPlayer
var _fun_gojo_original_name: String = ""
var _fun_gojo_original_ability: int = FootballPlayer.ABILITY_NONE
var _fun_gojo_original_cosmetic_loadout: Dictionary = {}
var _fun_gojo_original_personality: StringName = &"auto"
var _fun_gojo_original_skill_override: int = 0
var _fun_neymar_cpu: FootballPlayer
var _fun_neymar_original_name: String = ""
var _fun_neymar_original_ability: int = FootballPlayer.ABILITY_NONE
var _fun_neymar_original_cosmetic_loadout: Dictionary = {}
var _fun_neymar_original_personality: StringName = &"auto"
var _fun_neymar_original_skill_override: int = 0
var _fun_haaland_cpu: FootballPlayer
var _fun_haaland_original_name: String = ""
var _fun_haaland_original_ability: int = FootballPlayer.ABILITY_NONE
var _fun_haaland_original_cosmetic_loadout: Dictionary = {}
var _fun_haaland_original_personality: StringName = &"auto"
var _fun_haaland_original_skill_override: int = 0
var _fun_neuer_cpu: FootballPlayer
var _fun_neuer_original_name: String = ""
var _fun_neuer_original_ability: int = FootballPlayer.ABILITY_NONE
var _fun_neuer_original_cosmetic_loadout: Dictionary = {}
var _fun_neuer_original_personality: StringName = &"auto"
var _fun_neuer_original_skill_override: int = 0
var _halftime_generation: int = 0
var _tiebreak_generation: int = 0
var _penalty_first_team: StringName = NO_TEAM
var _ranked_draft_generation: int = 0
var _ranked_draft_phase_serial: int = 0
var _ranked_draft_first_team: StringName = NO_TEAM
var _ranked_draft_next_phase: StringName = RANKED_DRAFT_NONE
var _ranked_draft_next_team: StringName = NO_TEAM
var _ranked_draft_preferences: Dictionary = {}
var _ranked_draft_votes: Dictionary = {}
var _ranked_draft_picks: Dictionary = {}
var _ranked_initial_draft_complete: bool = false
var _ranked_overtime_draft_complete: bool = false
var _ranked_penalty_goalkeepers: Dictionary = {}
# Penalty defenders temporarily get Goalkeeper's Reach even if their normal
# loadout uses another ability. Keep the original ability so alternating turns
# do not leave a previous goalkeeper stuck with the penalty-only override.
var _penalty_goalkeeper_original_abilities: Dictionary = {}
var _penalty_reach_override_peer_id: int = 0
var _quick_chat_last_sent_at: Dictionary = {}
var _cpu_quick_chat_time_remaining: float = 0.0
var _cpu_quick_chat_global_last_sent_at: float = -1000.0
var goal_replay_active: bool = false
var goal_replay_slow_motion: bool = false
var goal_replay_presentation: Dictionary = {}
var _goal_replay_frames: Array[Dictionary] = []
var _goal_replay_events: Array[Dictionary] = []
var _goal_replay_capture_accumulator: float = 0.0
var _goal_replay_generation: int = 0
var _goal_replay_skip_votes: Dictionary = {}
var _goal_replay_skip_requested: bool = false
var _goal_replay_last_vote_count: int = -1
var _goal_replay_last_voter_count: int = -1
var _goal_replay_ball_visual_state: Array = []
var _goal_replay_player_visual_states: Dictionary = {}
var _kickoff_profile_pending: bool = false
var _kickoff_profile_active: bool = false
var _kickoff_profile_generation: int = 0
var _kickoff_profile_reset_usec: int = 0
var _kickoff_profile_transition_usec: int = 0
var _kickoff_profile_frames_seen: int = 0
var _kickoff_profile_longest_frame_msec: float = 0.0
var _kickoff_profile_cpu_total_usec: int = 0
var _kickoff_profile_cpu_longest_usec: int = 0
var _kickoff_profile_cpu_updates: int = 0
var _kickoff_profile_cpu_by_stage: Dictionary = {}
var _runtime_profile_cpu_by_peer: Dictionary = {}
var _runtime_profile_by_stage: Dictionary = {}
var _runtime_profile_last_report_msec: int = -1000000
var _runtime_profile_physics_frame: int = -1

@onready var goal_audio: AudioStreamPlayer = $GoalAudio
var _goal_reaction_contact_audio: AudioStreamPlayer
var _goal_reaction_sting_audio: AudioStreamPlayer
var _goal_reaction_crowd_audio: AudioStreamPlayer
var _goal_reaction_generation: int = 0
var _goal_theme_stream_cache: Dictionary = {}
var _ingame_pause_overlay: CanvasLayer


func _exit_tree() -> void:
	# Do not wait for pure-data AI workers during teardown. Their runner/result
	# boxes keep themselves alive until the short task exits.
	_cpu_team_sequence_async_tasks.clear()
	if _large_team_parallel_brain != null:
		_large_team_parallel_brain.call("shutdown")


func _ready() -> void:
	_setup_goal_reaction_audio()
	_resolve_local_pve_ranked_abandonment_if_pending()
	_load_draft_wins()
	_create_ingame_pause_overlay()
	_create_draft_panel()
	set_process(
		OS.is_debug_build()
		and (
			kickoff_profiling_enabled
			or runtime_spike_profiling_enabled
		)
	)
	_default_regulation_seconds = regulation_seconds
	_default_goals_to_win = goals_to_win
	_default_tournament_mode = tournament_mode
	_default_ranked_mode = ranked_mode
	_default_cpu_ai_level = cpu_ai_level
	fun_mutators = _default_fun_mutators()
	_capture_fun_mutator_runtime_defaults()
	_cpu_ability_rng.seed = Time.get_ticks_usec()
	_initialize_cpu_team_sequence_planner()
	_initialize_large_team_parallel_brain()
	var session_network_manager := get_parent().get_node_or_null(
		"NetworkManager"
	) as NetworkManager
	if (
		session_network_manager != null
		and not session_network_manager.session_ended.is_connected(
			_on_network_session_ended
		)
	):
		session_network_manager.session_ended.connect(
			_on_network_session_ended
		)
	connect_goal(red_goal)
	connect_goal(blue_goal)
	if ball != null:
		if not ball.player_touch_registered.is_connected(
			_on_ball_player_touch
		):
			ball.player_touch_registered.connect(
				_on_ball_player_touch
			)
		if not ball.player_kicked.is_connected(_on_ball_kicked):
			ball.player_kicked.connect(_on_ball_kicked)
		if not ball.wall_collision_replay_event.is_connected(
			_on_ball_wall_collision_replay_event
		):
			ball.wall_collision_replay_event.connect(
				_on_ball_wall_collision_replay_event
			)
	_validate_assignments()

	if players_parent != null:
		players_parent.child_entered_tree.connect(
			_on_player_entered
		)
		players_parent.child_exiting_tree.connect(
			_on_player_exiting
		)
		for child in players_parent.get_children():
			if child is FootballPlayer:
				_connect_player_learning_signal(child as FootballPlayer)

	regulation_time_remaining = regulation_seconds
	score_changed.emit(red_score, blue_score)
	tournament_score_changed.emit(
		tournament_leg_red_goals,
		tournament_leg_blue_goals,
		red_score,
		blue_score,
		tournament_leg,
		tournament_mode,
		tournament_sudden_death
	)
	timer_changed.emit(int(ceil(regulation_time_remaining)), false)
	roster_changed.emit(0, 0)
	roster_details_changed.emit(_empty_roster())
	match_settings_changed.emit(regulation_seconds, goals_to_win)
	cpu_settings_changed.emit(
		requested_blue_cpu_count,
		requested_red_cpu_count
	)
	cpu_difficulty_changed.emit(cpu_ai_level)
	cpu_ability_preferences_changed.emit(
		blue_cpu_ability_preferences.duplicate(),
		red_cpu_ability_preferences.duplicate()
	)
	tournament_mode_changed.emit(tournament_mode)
	ranked_mode_changed.emit(ranked_mode)
	champions_league_mode_changed.emit(champions_league_mode)
	fun_mutators_changed.emit(fun_mutators.duplicate(true))
	ranked_draft_changed.emit(_build_ranked_draft_snapshot(NO_TEAM))
	halftime_changed.emit(false, 0)
	_emit_tournament_tiebreak_state()
	leaderboard_changed.emit([])
	goal_replay_state_changed.emit(false, 0, 0, false)
	ladder_state_changed.emit(get_ladder_snapshot())
	singleplayer_ranked_state_changed.emit(
		get_singleplayer_ranked_snapshot()
	)


func configure_ladder_session(
	enabled: bool,
	start_from_beginning: bool = false
) -> bool:
	if not multiplayer.is_server() or game_has_started:
		return false
	ladder_mode = enabled
	ladder_last_result = &""
	_ladder_prepare_pending = false
	if not enabled:
		ladder_rung = 1
		ladder_run_seed = 0
		ladder_encounter.clear()
		ladder_human_team = TEAM_BLUE
		ladder_cpu_team = TEAM_RED
		_broadcast_ladder_state()
		return true
	_load_ladder_progress()
	if start_from_beginning:
		ladder_rung = 1
		ladder_run_seed = 0
		ladder_last_result = &""
	if ladder_run_seed == 0:
		ladder_run_seed = int(Time.get_unix_time_from_system()) ^ Time.get_ticks_msec()
	_prepare_ladder_encounter()
	return true


func get_ladder_snapshot() -> Dictionary:
	return {
		"enabled": ladder_mode,
		"rung": ladder_rung,
		"max_rung": LADDER_MAX_RUNG,
		"best_rung": ladder_best_rung,
		"season_clears": ladder_season_clears,
		"run_seed": ladder_run_seed,
		"last_result": str(ladder_last_result),
		"human_team": str(ladder_human_team),
		"cpu_team": str(ladder_cpu_team),
		"encounter": ladder_encounter.duplicate(true)
	}


func _prepare_ladder_encounter() -> void:
	if not ladder_mode or not multiplayer.is_server():
		return
	var unlocked_band: int = clampi(
		1 + int((float(ladder_rung - 1) * 4.0) / float(LADDER_MAX_RUNG - 1)),
		1,
		5
	)
	var eligible: Array[Dictionary] = []
	for encounter: Dictionary in LADDER_ENCOUNTERS:
		var band: int = int(encounter.get("band", 1))
		if band <= unlocked_band and band >= maxi(1, unlocked_band - 1):
			eligible.append(encounter)
	if eligible.is_empty():
		eligible.append(LADDER_ENCOUNTERS[0])
	var rng := RandomNumberGenerator.new()
	rng.seed = ladder_run_seed + (ladder_rung * 7919)
	var source: Dictionary = eligible[rng.randi_range(0, eligible.size() - 1)]
	ladder_human_team = TEAM_BLUE if rng.randi_range(0, 1) == 0 else TEAM_RED
	ladder_cpu_team = _opponent_team(ladder_human_team)
	_clear_ladder_cpu_players()
	_assign_ladder_human_party()
	var party_size: int = _get_ladder_human_party_size()
	var count_range: Vector2i = source.get("count", Vector2i(1, 4)) as Vector2i
	var rung_maximum: int = 1 + int(ceil(float(ladder_rung) / 2.5))
	var party_pressure_bonus: int = (
		1 if party_size < max_players_per_team and rng.randf() < minf(0.82, 0.28 + float(ladder_rung) * 0.045) else 0
	)
	var minimum_count: int = clampi(maxi(count_range.x, party_size), 1, max_players_per_team)
	var maximum_count: int = clampi(
		maxi(minimum_count, maxi(rung_maximum, party_size + party_pressure_bonus)),
		minimum_count,
		max_players_per_team
	)
	if ladder_rung >= LADDER_MAX_RUNG - 1:
		minimum_count = max_players_per_team
		maximum_count = max_players_per_team
	var enemy_count: int = rng.randi_range(minimum_count, maximum_count)
	# PvE ladder opponents always use the fully featured CPU decision set.
	# Rung progression still raises the ceiling, but never drops below level 6.
	var base_level: int = clampi(5 + ladder_rung, 6, 15)
	var levels: Array[int] = []
	var level_offsets: Array[int] = [-1, 1, 0, 2, -2, 1]
	for index: int in range(enemy_count):
		levels.append(clampi(base_level + level_offsets[index], 6, 15))
	ladder_encounter = source.duplicate(true)
	ladder_encounter["enemy_count"] = enemy_count
	ladder_encounter["cpu_levels"] = levels
	ladder_encounter["rung"] = ladder_rung
	ladder_encounter["human_team"] = str(ladder_human_team)
	ladder_encounter["cpu_team"] = str(ladder_cpu_team)
	ladder_encounter["party_size"] = party_size
	regulation_seconds = 180.0
	goals_to_win = 5
	# Ladder rungs keep the two-game Champions League aggregate format, but
	# Ranked's draft, bans, protects, and ability lockouts stay disabled.
	tournament_mode = true
	ranked_mode = false
	fun_mutators = _default_fun_mutators()
	requested_blue_cpu_count = enemy_count if ladder_cpu_team == TEAM_BLUE else 0
	requested_red_cpu_count = enemy_count if ladder_cpu_team == TEAM_RED else 0
	blue_cpu_ability_preferences = [
		CPU_ABILITY_RANDOM,
		CPU_ABILITY_RANDOM,
		CPU_ABILITY_RANDOM,
		CPU_ABILITY_RANDOM,
		CPU_ABILITY_RANDOM,
		CPU_ABILITY_RANDOM
	]
	red_cpu_ability_preferences = [
		CPU_ABILITY_RANDOM,
		CPU_ABILITY_RANDOM,
		CPU_ABILITY_RANDOM,
		CPU_ABILITY_RANDOM,
		CPU_ABILITY_RANDOM,
		CPU_ABILITY_RANDOM
	]
	var abilities: Array = (source.get("abilities", []) as Array).duplicate()
	if ladder_rung >= LADDER_MAX_RUNG:
		while abilities.size() < enemy_count:
			abilities.append(FootballPlayer.ABILITY_NONE)
		abilities[0] = FootballPlayer.ABILITY_OVERDRIVE
	ladder_encounter["cpu_names"] = _build_ladder_cpu_names(
		rng,
		abilities,
		enemy_count
	)
	var encounter_preferences: Array[int] = []
	for index: int in range(max_players_per_team):
		encounter_preferences.append(
			int(abilities[index]) if index < abilities.size() else CPU_ABILITY_RANDOM
		)
	if ladder_cpu_team == TEAM_BLUE:
		blue_cpu_ability_preferences = encounter_preferences.duplicate()
	else:
		red_cpu_ability_preferences = encounter_preferences.duplicate()
	cpu_ai_level = levels.max() if not levels.is_empty() else base_level
	_cpu_team_strategies[ladder_cpu_team] = StringName(
		source.get("strategy", CPU_STRATEGY_BALANCED)
	)
	_reset_ranked_draft_state()
	_ready_players.clear()
	_reconcile_cpu_players()
	_apply_ladder_cpu_profiles()
	match_settings_changed.emit(regulation_seconds, goals_to_win)
	cpu_settings_changed.emit(requested_blue_cpu_count, requested_red_cpu_count)
	cpu_difficulty_changed.emit(cpu_ai_level)
	cpu_ability_preferences_changed.emit(
		blue_cpu_ability_preferences.duplicate(),
		red_cpu_ability_preferences.duplicate()
	)
	tournament_mode_changed.emit(true)
	ranked_mode_changed.emit(false)
	fun_mutators_changed.emit(fun_mutators.duplicate(true))
	refresh_roster()
	_save_ladder_progress()
	_broadcast_ladder_state()


func _get_ladder_human_party_size() -> int:
	var count: int = 0
	if players_parent != null:
		for node: Node in players_parent.get_children():
			var player := node as FootballPlayer
			if (
				player != null
				and not player.cpu_controlled
				and player.team != TEAM_SPECTATOR
			):
				count += 1
	return clampi(maxi(1, count), 1, max_players_per_team)


func _clear_ladder_cpu_players() -> void:
	var existing_cpus: Array[FootballPlayer] = []
	for player: FootballPlayer in red_players + blue_players:
		if is_instance_valid(player) and player.cpu_controlled:
			existing_cpus.append(player)
	for cpu: FootballPlayer in existing_cpus:
		_remove_cpu_player(cpu)


func _assign_ladder_human_party() -> void:
	if players_parent == null:
		return
	for node: Node in players_parent.get_children():
		var player := node as FootballPlayer
		if (
			player == null
			or player.cpu_controlled
			or player.team == TEAM_SPECTATOR
		):
			continue
		if player.team != ladder_human_team:
			join_team(player, ladder_human_team)


func _refresh_ladder_party_configuration() -> void:
	if ladder_mode and multiplayer.is_server() and not game_has_started:
		_prepare_ladder_encounter()


func _build_ladder_cpu_names(
	rng: RandomNumberGenerator,
	abilities: Array,
	count: int
) -> Array[String]:
	var result: Array[String] = []
	if ladder_rung < 9:
		var shuffled_names: Array[String] = LADDER_FUNNY_CPU_NAMES.duplicate()
		# Shuffle the complete pool for every stage. The encounter RNG is seeded by
		# the saved ladder run and rung, so names move between stages while a saved
		# run still reconstructs the exact same opponents after loading.
		for shuffle_index: int in range(shuffled_names.size() - 1, 0, -1):
			var swap_index: int = rng.randi_range(0, shuffle_index)
			var held_name: String = shuffled_names[shuffle_index]
			shuffled_names[shuffle_index] = shuffled_names[swap_index]
			shuffled_names[swap_index] = held_name
		for index: int in range(count):
			result.append(shuffled_names[index])
		return result
	var used_names: Dictionary = {}
	for index: int in range(count):
		if ladder_rung >= LADDER_MAX_RUNG and index == 0:
			result.append(LADDER_FINAL_BOSS_NAME)
			used_names[LADDER_FINAL_BOSS_NAME] = true
			continue
		var ability_id: int = (
			int(abilities[index])
			if index < abilities.size()
			else FootballPlayer.ABILITY_NONE
		)
		var candidates: Array = LADDER_ELITE_NAMES_BY_ABILITY.get(
			ability_id,
			LADDER_ELITE_NAMES_BY_ABILITY[FootballPlayer.ABILITY_NONE]
		) as Array
		var selected_name: String = str(candidates[index % candidates.size()])
		for candidate_variant: Variant in candidates:
			var candidate_name: String = str(candidate_variant)
			if not used_names.has(candidate_name):
				selected_name = candidate_name
				break
		if used_names.has(selected_name):
			selected_name = "%s %d" % [selected_name, index + 1]
		used_names[selected_name] = true
		result.append(selected_name)
	return result


func _apply_ladder_cpu_profiles() -> void:
	if not ladder_mode:
		return
	var cpus: Array[FootballPlayer] = []
	var cpu_team_players: Array[FootballPlayer] = (
		red_players if ladder_cpu_team == TEAM_RED else blue_players
	)
	for player: FootballPlayer in cpu_team_players:
		if is_instance_valid(player) and player.cpu_controlled:
			cpus.append(player)
	cpus.sort_custom(
		func(first: FootballPlayer, second: FootballPlayer) -> bool:
			return first.team_slot < second.team_slot
	)
	var levels: Array = ladder_encounter.get("cpu_levels", []) as Array
	var personalities: Array = ladder_encounter.get("personalities", []) as Array
	var cpu_names: Array = ladder_encounter.get("cpu_names", []) as Array
	for index: int in range(cpus.size()):
		var cpu: FootballPlayer = cpus[index]
		var is_final_boss: bool = ladder_rung >= LADDER_MAX_RUNG and index == 0
		cpu.set_permanent_overdrive(is_final_boss)
		cpu.display_name = (
			str(cpu_names[index])
			if index < cpu_names.size()
			else "Ladder Rival %d" % (index + 1)
		)
		if is_final_boss:
			_apply_dictator_mbappe_profile(cpu)
		var controller := cpu.get_node_or_null("CPUController") as CPUPlayerAI
		if controller == null:
			continue
		if not is_final_boss:
			var level: int = int(levels[index]) if index < levels.size() else cpu_ai_level
			controller.set_skill_level_override(level)
			if index < personalities.size():
				controller.set_cpu_personality(StringName(personalities[index]))


func _resolve_ladder_result(winning_team: StringName) -> void:
	if not ladder_mode or not multiplayer.is_server():
		return
	if winning_team == ladder_human_team:
		ladder_best_rung = maxi(ladder_best_rung, ladder_rung)
		if ladder_rung >= LADDER_MAX_RUNG:
			ladder_season_clears += 1
			_award_ladder_challenge_completion_to_party()
			ladder_last_result = &"cleared"
			ladder_rung = 1
			ladder_run_seed = int(Time.get_unix_time_from_system()) ^ Time.get_ticks_msec()
		else:
			ladder_last_result = &"won"
			ladder_rung += 1
	else:
		ladder_last_result = &"lost"
		ladder_rung = 1
		ladder_run_seed = int(Time.get_unix_time_from_system()) ^ Time.get_ticks_msec()
	_ladder_prepare_pending = true
	_save_ladder_progress()
	_broadcast_ladder_state()


func has_local_ladder_challenge_completion() -> bool:
	# The marker is test-only and never written by normal progression.
	# It makes visual verification independent of ConfigFile formatting while
	# the real permanent reward still comes from profile.completed / clears.
	if FileAccess.file_exists("user://ladder_champion_visual_test.flag"):
		return true
	var config := ConfigFile.new()
	if config.load(ladder_progress_path) != OK:
		return false
	return (
		bool(config.get_value("profile", "completed", false))
		or int(config.get_value("season", "clears", 0)) > 0
	)


func _persist_local_ladder_challenge_completion() -> void:
	var config := ConfigFile.new()
	config.load(ladder_progress_path)
	config.set_value("profile", "completed", true)
	var error: Error = config.save(ladder_progress_path)
	if error != OK:
		push_warning(
			"Could not save ladder champion status: %s"
			% error_string(error)
		)


func _award_ladder_challenge_completion_to_party() -> void:
	if not multiplayer.is_server():
		return
	var human_players: Array[FootballPlayer] = (
		blue_players if ladder_human_team == TEAM_BLUE else red_players
	)
	var awarded_peers: Dictionary = {}
	for player: FootballPlayer in human_players:
		if (
			not is_instance_valid(player)
			or player.cpu_controlled
			or player.owner_peer_id <= 0
			or awarded_peers.has(player.owner_peer_id)
		):
			continue
		awarded_peers[player.owner_peer_id] = true
		if player.owner_peer_id == multiplayer.get_unique_id():
			_receive_ladder_challenge_completion()
		else:
			_receive_ladder_challenge_completion.rpc_id(
				player.owner_peer_id
			)


@rpc("authority", "call_remote", "reliable")
func _receive_ladder_challenge_completion() -> void:
	_persist_local_ladder_challenge_completion()
	var session_network_manager := get_parent().get_node_or_null(
		"NetworkManager"
	) as NetworkManager
	if session_network_manager != null:
		session_network_manager.refresh_local_cosmetic_loadout.call_deferred()


func _load_ladder_progress() -> void:
	var config := ConfigFile.new()
	if config.load(ladder_progress_path) != OK:
		return
	ladder_best_rung = clampi(
		int(config.get_value("season", "best_rung", 0)),
		0,
		LADDER_MAX_RUNG
	)
	ladder_season_clears = maxi(
		0,
		int(config.get_value("season", "clears", 0))
	)
	ladder_rung = clampi(
		int(config.get_value("active_run", "rung", 1)),
		1,
		LADDER_MAX_RUNG
	)
	ladder_run_seed = int(config.get_value("active_run", "seed", 0))


func _save_ladder_progress() -> void:
	var config := ConfigFile.new()
	config.set_value("season", "best_rung", ladder_best_rung)
	config.set_value("season", "clears", ladder_season_clears)
	if ladder_season_clears > 0:
		config.set_value("profile", "completed", true)
	config.set_value("active_run", "rung", ladder_rung)
	config.set_value("active_run", "seed", ladder_run_seed)
	var error: Error = config.save(ladder_progress_path)
	if error != OK:
		push_warning("Could not save seasonal ladder progress: %s" % error_string(error))


func _broadcast_ladder_state() -> void:
	if multiplayer.is_server():
		_receive_ladder_state.rpc(get_ladder_snapshot())


@rpc("authority", "call_local", "reliable")
func _receive_ladder_state(snapshot: Dictionary) -> void:
	ladder_mode = bool(snapshot.get("enabled", false))
	ladder_rung = int(snapshot.get("rung", 1))
	ladder_best_rung = int(snapshot.get("best_rung", 0))
	ladder_season_clears = int(snapshot.get("season_clears", 0))
	ladder_run_seed = int(snapshot.get("run_seed", 0))
	ladder_last_result = StringName(snapshot.get("last_result", ""))
	ladder_human_team = StringName(snapshot.get("human_team", str(TEAM_BLUE)))
	ladder_cpu_team = StringName(snapshot.get("cpu_team", str(TEAM_RED)))
	ladder_encounter = (snapshot.get("encounter", {}) as Dictionary).duplicate(true)
	ladder_state_changed.emit(get_ladder_snapshot())


func configure_singleplayer_ranked_session(team_size: int) -> bool:
	return configure_pve_ranked_session(team_size, false)


func configure_pve_ranked_session(
	team_size: int,
	multiplayer_session: bool
) -> bool:
	if not multiplayer.is_server() or game_has_started:
		return false
	ladder_mode = false
	_ladder_prepare_pending = false
	singleplayer_ranked_mode = true
	pve_ranked_multiplayer_mode = multiplayer_session
	# PvE Ranked uses the same visible card draft as the standalone Draft mode.
	# MMR, CPU matchmaking and divisions remain PvE-specific; only the match
	# format/loadout flow is shared.
	champions_league_mode = true
	_reset_draft_state(true)
	for player: FootballPlayer in _get_draft_players():
		player.clear_draft_perk()
	singleplayer_ranked_team_size = clampi(
		team_size,
		1,
		max_players_per_team
	)
	singleplayer_ranked_last_change = 0
	singleplayer_ranked_last_result = &""
	_singleplayer_ranked_prepare_pending = false
	_load_singleplayer_ranked_progress()
	_pve_ranked_player_profiles.clear()
	_pve_ranked_player_profiles[multiplayer.get_unique_id()] = {
		"mmr": singleplayer_ranked_mmr,
		"matches": singleplayer_ranked_matches
	}
	_receive_champions_league_mode.rpc(true)
	_prepare_singleplayer_ranked_match()
	return true


func get_singleplayer_ranked_snapshot() -> Dictionary:
	return {
		"enabled": singleplayer_ranked_mode,
		"multiplayer": pve_ranked_multiplayer_mode,
		"mmr": singleplayer_ranked_mmr,
		"matches": singleplayer_ranked_matches,
		"matchmaking_mmr": pve_ranked_matchmaking_mmr,
		"matchmaking_matches": pve_ranked_matchmaking_matches,
		"matchmaking_division": pve_ranked_matchmaking_division,
		"matchmaking_division_name": get_singleplayer_ranked_division_name(
			pve_ranked_matchmaking_division
		),
		"matchmaking_locked": pve_ranked_matchmaking_locked,
		"team_size": singleplayer_ranked_team_size,
		"division": singleplayer_ranked_division,
		"division_name": get_singleplayer_ranked_division_name(
			singleplayer_ranked_division
		),
		"next_division_mmr": _get_singleplayer_next_division_mmr(),
		"human_team": str(singleplayer_ranked_human_team),
		"cpu_team": str(singleplayer_ranked_cpu_team),
		"last_change": singleplayer_ranked_last_change,
		"last_result": str(singleplayer_ranked_last_result),
		"encounter": singleplayer_ranked_encounter.duplicate(true)
	}


func refresh_singleplayer_ranked_profile() -> Dictionary:
	_load_singleplayer_ranked_progress()
	var snapshot: Dictionary = get_singleplayer_ranked_snapshot()
	singleplayer_ranked_state_changed.emit(snapshot)
	return snapshot


static func get_singleplayer_ranked_division_for_mmr(mmr: int) -> int:
	var safe_mmr: int = maxi(PVE_RANKED_MIN_MMR, mmr)
	var division: int = 1
	for index: int in range(
		SINGLEPLAYER_RANKED_DIVISION_THRESHOLDS.size()
	):
		if safe_mmr >= SINGLEPLAYER_RANKED_DIVISION_THRESHOLDS[index]:
			division = index + 1
	return clampi(division, 1, 6)


static func get_singleplayer_ranked_division_name(division: int) -> String:
	var names: Array[String] = [
		"KREISLIGA",
		"BEZIRKSLIGA",
		"REGIONALLIGA",
		"BUNDESLIGA",
		"CHAMPIONS LEAGUE",
		"THEODORE LEAGUE"
	]
	return names[clampi(division, 1, names.size()) - 1]


static func get_pve_ranked_intelligence_range(division: int) -> Vector2i:
	# The same trained champion is used in every league; the rank controls how
	# much of it is unlocked. Theodore is always the full INT 20 ceiling.
	var ranges: Array[Vector2i] = [
		Vector2i(1, 3),
		Vector2i(4, 6),
		Vector2i(7, 10),
		Vector2i(14, 16),
		Vector2i(17, 19),
		Vector2i(20, 20)
	]
	return ranges[clampi(division, 1, ranges.size()) - 1]


static func get_singleplayer_ranked_division_color(division: int) -> Color:
	# Distinct league colors used everywhere PvE Ranked is shown.
	match clampi(division, 1, 6):
		1:
			return Color("c88758") # bronze
		2:
			return Color("cbd8e6") # silver
		3:
			return Color("ffd35c") # gold
		4:
			return Color("ef454f") # Bundesliga / static red
		5:
			return Color("b083ff") # Champions League / animated purple
		_:
			return Color("5af0a6") # Theodore League / animated emerald


static func get_singleplayer_ranked_division_shine_color(division: int) -> Color:
	match clampi(division, 1, 6):
		1:
			return Color("ffd6a8")
		2:
			return Color("ffffff")
		3:
			return Color("fff3a5")
		4:
			return Color("ffb2b8") # subtle red highlight only; not animated
		5:
			return Color("ead7ff") # bright violet shimmer
		_:
			return Color("c9ffe3") # Theodore bright emerald shimmer; no gold


static func singleplayer_ranked_division_is_animated(division: int) -> bool:
	# Only the two prestige leagues animate. Bundesliga intentionally stays still.
	return clampi(division, 1, 6) >= 5


static func get_pve_ranked_opponent_mmr(division: int) -> int:
	return PVE_RANKED_OPPONENT_MMR_BY_DIVISION[
		clampi(division, 1, PVE_RANKED_OPPONENT_MMR_BY_DIVISION.size()) - 1
	]


static func calculate_pve_ranked_mmr_change(
	player_mmr: int,
	opponent_mmr: int,
	won: bool,
	highest_opponent_mmr: int = -1
) -> int:
	var safe_player_mmr: int = maxi(PVE_RANKED_MIN_MMR, player_mmr)
	var rating_gap: int = opponent_mmr - safe_player_mmr
	var adjustment: int = clampi(
		int(absf(float(rating_gap)) / 200.0) * PVE_RANKED_MMR_STEP_PER_200,
		0,
		PVE_RANKED_MMR_MAX_ADJUSTMENT
	)
	var change: int
	if won:
		change = SINGLEPLAYER_RANKED_MMR_STEP + (
			adjustment if rating_gap > 0 else -adjustment
		)
	else:
		change = -SINGLEPLAYER_RANKED_MMR_STEP + (
			adjustment if rating_gap > 0 else -adjustment
		)
	if safe_player_mmr >= PVE_RANKED_SLOWDOWN_MMR:
		change = int(round(float(change) * (0.5 if won else 0.75)))

	# A promoted/elite CPU can make a team considerably harder than the normal
	# division rating suggests. On a loss, soften the penalty when even one
	# opponent is clearly above the player's rating. This never changes win gains
	# and tops out at 10 MMR of protection.
	if not won and highest_opponent_mmr >= 0:
		var peak_gap: int = highest_opponent_mmr - safe_player_mmr
		if peak_gap >= PVE_RANKED_HIGH_OPPONENT_PROTECTION_START_GAP:
			var protection_t: float = clampf(
				float(
					peak_gap - PVE_RANKED_HIGH_OPPONENT_PROTECTION_START_GAP
				) / float(
					PVE_RANKED_HIGH_OPPONENT_PROTECTION_FULL_GAP
					- PVE_RANKED_HIGH_OPPONENT_PROTECTION_START_GAP
				),
				0.0,
				1.0
			)
			var loss_reduction: int = int(round(lerpf(
				4.0,
				float(PVE_RANKED_HIGH_OPPONENT_LOSS_REDUCTION_MAX),
				protection_t
			)))
			change = mini(-1, change + loss_reduction)
	return change


func _get_singleplayer_next_division_mmr() -> int:
	if singleplayer_ranked_division >= 6:
		return -1
	return SINGLEPLAYER_RANKED_DIVISION_THRESHOLDS[
		singleplayer_ranked_division
	]


func _get_pve_ranked_party_humans() -> Array[FootballPlayer]:
	var humans: Array[FootballPlayer] = []
	var team_players: Array[FootballPlayer] = (
		blue_players
		if singleplayer_ranked_human_team == TEAM_BLUE
		else red_players
	)
	for player: FootballPlayer in team_players:
		if is_instance_valid(player) and not player.cpu_controlled:
			humans.append(player)
	return humans


func _get_pve_ranked_matchmaking_profile(
	require_all_profiles: bool = false
) -> Dictionary:
	var humans: Array[FootballPlayer] = _get_pve_ranked_party_humans()
	if humans.is_empty():
		return {}

	var highest_mmr: int = PVE_RANKED_MIN_MMR
	var highest_matches: int = 0
	var found_profile: bool = false
	for player: FootballPlayer in humans:
		if not _pve_ranked_player_profiles.has(player.owner_peer_id):
			if require_all_profiles:
				return {}
			continue
		var profile: Dictionary = _pve_ranked_player_profiles[
			player.owner_peer_id
		] as Dictionary
		var profile_mmr: int = maxi(
			PVE_RANKED_MIN_MMR,
			int(profile.get("mmr", PVE_RANKED_STARTING_MMR))
		)
		var profile_matches: int = maxi(0, int(profile.get("matches", 0)))
		if not found_profile or profile_mmr > highest_mmr:
			highest_mmr = profile_mmr
			highest_matches = profile_matches
			found_profile = true
		elif profile_mmr == highest_mmr:
			highest_matches = maxi(highest_matches, profile_matches)

	if not found_profile:
		return {
			"mmr": singleplayer_ranked_mmr,
			"matches": singleplayer_ranked_matches
		}
	return {
		"mmr": highest_mmr,
		"matches": highest_matches
	}


func _pve_ranked_all_party_profiles_received() -> bool:
	var humans: Array[FootballPlayer] = _get_pve_ranked_party_humans()
	if humans.is_empty():
		return false
	for player: FootballPlayer in humans:
		if not _pve_ranked_player_profiles.has(player.owner_peer_id):
			return false
	return true


func _pve_ranked_all_party_humans_ready() -> bool:
	var humans: Array[FootballPlayer] = _get_pve_ranked_party_humans()
	if humans.is_empty():
		return false
	for player: FootballPlayer in humans:
		if not _ready_players.has(player.owner_peer_id):
			return false
	return true


func _apply_pve_ranked_rules_for_matchmaking_division() -> void:
	# Every PvE Ranked division now uses Draft's two three-minute legs. Division
	# still controls opponent intelligence, MMR and boss selection.
	regulation_seconds = 180.0
	goals_to_win = 10
	tournament_mode = true
	ranked_mode = false
	champions_league_mode = true
	tournament_halftime_seconds = float(DRAFT_PICK_SECONDS)
	fun_mutators = _default_fun_mutators()


func _stage_singleplayer_ranked_matchmaking(randomize_team_side: bool) -> void:
	# Ranked lobby phase: humans and their abilities are visible, but NO CPU
	# lineup exists yet. This keeps the opponent hidden and lets all party MMR
	# profiles arrive before matchmaking is locked.
	_clear_all_cpu_players()
	if randomize_team_side:
		var side_rng := RandomNumberGenerator.new()
		side_rng.seed = (
			int(Time.get_unix_time_from_system())
			^ (singleplayer_ranked_matches * 7919)
			^ Time.get_ticks_msec()
		)
		singleplayer_ranked_human_team = (
			TEAM_BLUE if side_rng.randi_range(0, 1) == 0 else TEAM_RED
		)
		singleplayer_ranked_cpu_team = _opponent_team(
			singleplayer_ranked_human_team
		)

	_assign_singleplayer_ranked_human()
	var profile: Dictionary = _get_pve_ranked_matchmaking_profile(false)
	pve_ranked_matchmaking_mmr = maxi(
		PVE_RANKED_MIN_MMR,
		int(profile.get("mmr", singleplayer_ranked_mmr))
	)
	pve_ranked_matchmaking_matches = maxi(
		0,
		int(profile.get("matches", singleplayer_ranked_matches))
	)
	pve_ranked_matchmaking_division = get_singleplayer_ranked_division_for_mmr(
		pve_ranked_matchmaking_mmr
	)
	singleplayer_ranked_division = pve_ranked_matchmaking_division
	pve_ranked_matchmaking_locked = false
	_apply_pve_ranked_rules_for_matchmaking_division()

	requested_blue_cpu_count = 0
	requested_red_cpu_count = 0
	blue_cpu_ability_preferences = _build_singleplayer_cpu_preferences(
		TEAM_BLUE,
		[]
	)
	red_cpu_ability_preferences = _build_singleplayer_cpu_preferences(
		TEAM_RED,
		[]
	)
	cpu_ai_level = 1
	singleplayer_ranked_encounter = {
		"matchmaking_pending": true,
		"matchmaking_locked": false,
		"matchmaking_mmr": pve_ranked_matchmaking_mmr,
		"matchmaking_division": pve_ranked_matchmaking_division,
		"human_team_size": singleplayer_ranked_team_size,
		"opponent_team_size": singleplayer_ranked_team_size
	}

	_reset_ranked_draft_state()
	_ready_players.clear()
	_reconcile_cpu_players()
	match_settings_changed.emit(regulation_seconds, goals_to_win)
	cpu_settings_changed.emit(0, 0)
	cpu_difficulty_changed.emit(cpu_ai_level)
	cpu_ability_preferences_changed.emit(
		blue_cpu_ability_preferences.duplicate(),
		red_cpu_ability_preferences.duplicate()
	)
	tournament_mode_changed.emit(tournament_mode)
	ranked_mode_changed.emit(false)
	fun_mutators_changed.emit(fun_mutators.duplicate(true))
	refresh_roster()
	_broadcast_singleplayer_ranked_state()


func _prepare_singleplayer_ranked_match(
	finalize_matchmaking: bool = false
) -> void:
	if not singleplayer_ranked_mode or not multiplayer.is_server():
		return
	if not finalize_matchmaking:
		_stage_singleplayer_ranked_matchmaking(true)
		return
	if (
		not _pve_ranked_all_party_humans_ready()
		or not _pve_ranked_all_party_profiles_received()
	):
		return

	_clear_all_cpu_players()
	var profile: Dictionary = _get_pve_ranked_matchmaking_profile(true)
	if profile.is_empty():
		return
	pve_ranked_matchmaking_mmr = maxi(
		PVE_RANKED_MIN_MMR,
		int(profile.get("mmr", singleplayer_ranked_mmr))
	)
	pve_ranked_matchmaking_matches = maxi(
		0,
		int(profile.get("matches", singleplayer_ranked_matches))
	)
	pve_ranked_matchmaking_division = get_singleplayer_ranked_division_for_mmr(
		pve_ranked_matchmaking_mmr
	)
	singleplayer_ranked_division = pve_ranked_matchmaking_division
	pve_ranked_matchmaking_locked = true

	var rng := RandomNumberGenerator.new()
	rng.seed = (
		int(Time.get_unix_time_from_system())
		^ (pve_ranked_matchmaking_matches * 7919)
		^ (pve_ranked_matchmaking_mmr * 101)
		^ Time.get_ticks_msec()
	)
	_assign_singleplayer_ranked_human()
	_randomize_singleplayer_ranked_main_player_slot(rng)
	var human_count: int = _singleplayer_ranked_human_count()

	_apply_pve_ranked_rules_for_matchmaking_division()
	# Bosses are prestige encounters, not the main difficulty scaler. Champions
	# League gets at most one boss and only in 40% of matches. Theodore League
	# always contains exactly one boss. The rest of the difficulty gap comes
	# from the new Intelligence 16-20 CPU tiers.
	var boss_count: int = 0
	if singleplayer_ranked_division == 5:
		boss_count = 1 if rng.randf() < PVE_RANKED_CHAMPIONS_BOSS_CHANCE else 0
	elif singleplayer_ranked_division >= 6:
		boss_count = 1
	var boss_start_index: int = 0
	if boss_count > 0 and not SINGLEPLAYER_RANKED_BOSSES.is_empty():
		boss_start_index = _pick_singleplayer_ranked_boss_start_index(rng)
	var opponent_team_size: int = maxi(
		singleplayer_ranked_team_size,
		boss_count
	)
	var promoted_opponent_count: int = _roll_singleplayer_ranked_promoted_opponents(
		rng,
		opponent_team_size,
		boss_count
	)
	requested_blue_cpu_count = (
		maxi(0, singleplayer_ranked_team_size - human_count)
		if singleplayer_ranked_human_team == TEAM_BLUE
		else opponent_team_size
	)
	requested_red_cpu_count = (
		maxi(0, singleplayer_ranked_team_size - human_count)
		if singleplayer_ranked_human_team == TEAM_RED
		else opponent_team_size
	)

	var blue_abilities: Array[int] = _draw_singleplayer_ranked_abilities(
		rng,
		requested_blue_cpu_count
	)
	var red_abilities: Array[int] = _draw_singleplayer_ranked_abilities(
		rng,
		requested_red_cpu_count
	)
	var opponent_abilities: Array[int] = (
		blue_abilities
		if singleplayer_ranked_cpu_team == TEAM_BLUE
		else red_abilities
	)
	for boss_index: int in range(boss_count):
		if boss_index >= opponent_abilities.size():
			break
		var boss: Dictionary = SINGLEPLAYER_RANKED_BOSSES[
			(boss_start_index + boss_index) % SINGLEPLAYER_RANKED_BOSSES.size()
		]
		opponent_abilities[boss_index] = int(boss.get("ability", 0))
	blue_cpu_ability_preferences = _build_singleplayer_cpu_preferences(
		TEAM_BLUE,
		blue_abilities
	)
	red_cpu_ability_preferences = _build_singleplayer_cpu_preferences(
		TEAM_RED,
		red_abilities
	)

	var blue_levels: Array[int] = _build_singleplayer_ranked_levels(
		rng,
		requested_blue_cpu_count,
		TEAM_BLUE == singleplayer_ranked_cpu_team,
		promoted_opponent_count if TEAM_BLUE == singleplayer_ranked_cpu_team else 0
	)
	var red_levels: Array[int] = _build_singleplayer_ranked_levels(
		rng,
		requested_red_cpu_count,
		TEAM_RED == singleplayer_ranked_cpu_team,
		promoted_opponent_count if TEAM_RED == singleplayer_ranked_cpu_team else 0
	)
	# Bosses use the top of their league's champion utilization.
	# Champions bosses are INT 19; Theodore bosses are the full INT 20 champion.
	if boss_count > 0:
		var boss_intelligence: int = (
			20 if singleplayer_ranked_division >= 6 else 19
		)
		var opponent_levels: Array[int] = (
			blue_levels
			if singleplayer_ranked_cpu_team == TEAM_BLUE
			else red_levels
		)
		for boss_index: int in range(mini(boss_count, opponent_levels.size())):
			opponent_levels[boss_index] = boss_intelligence
	var blue_mmrs: Array[int] = _build_singleplayer_ranked_cpu_mmrs(
		rng,
		requested_blue_cpu_count,
		TEAM_BLUE == singleplayer_ranked_cpu_team,
		promoted_opponent_count if TEAM_BLUE == singleplayer_ranked_cpu_team else 0
	)
	var red_mmrs: Array[int] = _build_singleplayer_ranked_cpu_mmrs(
		rng,
		requested_red_cpu_count,
		TEAM_RED == singleplayer_ranked_cpu_team,
		promoted_opponent_count if TEAM_RED == singleplayer_ranked_cpu_team else 0
	)
	var used_cpu_names: Dictionary = {}
	var blue_names: Array[String] = _build_singleplayer_ranked_names(
		rng,
		blue_abilities,
		TEAM_BLUE == singleplayer_ranked_cpu_team,
		boss_count,
		boss_start_index,
		used_cpu_names,
		promoted_opponent_count if TEAM_BLUE == singleplayer_ranked_cpu_team else 0
	)
	var red_names: Array[String] = _build_singleplayer_ranked_names(
		rng,
		red_abilities,
		TEAM_RED == singleplayer_ranked_cpu_team,
		boss_count,
		boss_start_index,
		used_cpu_names,
		promoted_opponent_count if TEAM_RED == singleplayer_ranked_cpu_team else 0
	)
	# Real football identities own their kit instead of inheriting a random role.
	# This is what prevents a Messi-type forward from becoming the nominal defender
	# simply because the pre-name random ability roll happened to be defensive.
	_apply_singleplayer_ranked_footballer_ability_profiles(
		rng, blue_names, blue_abilities,
		boss_count if TEAM_BLUE == singleplayer_ranked_cpu_team else 0
	)
	_apply_singleplayer_ranked_footballer_ability_profiles(
		rng, red_names, red_abilities,
		boss_count if TEAM_RED == singleplayer_ranked_cpu_team else 0
	)
	blue_cpu_ability_preferences = _build_singleplayer_cpu_preferences(TEAM_BLUE, blue_abilities)
	red_cpu_ability_preferences = _build_singleplayer_cpu_preferences(TEAM_RED, red_abilities)
	singleplayer_ranked_encounter = {
		"matchmaking_pending": false,
		"matchmaking_locked": true,
		"matchmaking_mmr": pve_ranked_matchmaking_mmr,
		"matchmaking_division": pve_ranked_matchmaking_division,
		"blue_levels": blue_levels,
		"red_levels": red_levels,
		"blue_mmrs": blue_mmrs,
		"red_mmrs": red_mmrs,
		"blue_names": blue_names,
		"red_names": red_names,
		"blue_abilities": blue_abilities,
		"red_abilities": red_abilities,
		"boss_count": boss_count,
		"boss_start_index": boss_start_index,
		"promoted_opponent_count": promoted_opponent_count,
		"upper_division_guest_count": promoted_opponent_count,
		"human_team_size": singleplayer_ranked_team_size,
		"opponent_team_size": opponent_team_size
	}
	var all_levels: Array[int] = blue_levels.duplicate()
	all_levels.append_array(red_levels)
	cpu_ai_level = all_levels.max() if not all_levels.is_empty() else 1
	_reset_ranked_draft_state()
	# Humans were already ready before the hidden opponent was generated. Keep
	# those ready flags; CPU ready flags are added synchronously while spawning.
	_reconcile_cpu_players()
	_apply_singleplayer_ranked_cpu_profiles()
	match_settings_changed.emit(regulation_seconds, goals_to_win)
	cpu_settings_changed.emit(
		requested_blue_cpu_count,
		requested_red_cpu_count
	)
	cpu_difficulty_changed.emit(cpu_ai_level)
	cpu_ability_preferences_changed.emit(
		blue_cpu_ability_preferences.duplicate(),
		red_cpu_ability_preferences.duplicate()
	)
	tournament_mode_changed.emit(tournament_mode)
	ranked_mode_changed.emit(false)
	fun_mutators_changed.emit(fun_mutators.duplicate(true))
	refresh_roster()
	_broadcast_singleplayer_ranked_state()


func _assign_singleplayer_ranked_human() -> void:
	if players_parent == null:
		return
	var assigned_humans: int = 0
	for node: Node in players_parent.get_children():
		var player := node as FootballPlayer
		if player == null or player.cpu_controlled:
			continue
		if assigned_humans < singleplayer_ranked_team_size:
			assigned_humans += 1
			if player.team == singleplayer_ranked_human_team:
				continue
			_make_room_for_human(singleplayer_ranked_human_team, player)
			join_team(player, singleplayer_ranked_human_team)
		elif pve_ranked_multiplayer_mode and player.team != TEAM_SPECTATOR:
			join_team(player, TEAM_SPECTATOR)


func _randomize_singleplayer_ranked_main_player_slot(
	rng: RandomNumberGenerator
) -> void:
	# Singleplayer PvE Ranked used to reserve the first free team slot for the
	# human every match. Randomizing the human's formation slot gives each
	# encounter a different starting role/angle while CPUs simply fill the
	# remaining slots through the existing reconciliation path. Multiplayer PvE
	# keeps stable human slots so party members never get silently rearranged.
	if pve_ranked_multiplayer_mode or players_parent == null or rng == null:
		return
	var slot_count := clampi(
		singleplayer_ranked_team_size,
		1,
		max_players_per_team
	)
	if slot_count <= 1:
		return
	var human_team_players: Array[FootballPlayer] = (
		blue_players
		if singleplayer_ranked_human_team == TEAM_BLUE
		else red_players
	)
	for player: FootballPlayer in human_team_players:
		if not is_instance_valid(player) or player.cpu_controlled:
			continue
		player.assign_team(
			singleplayer_ranked_human_team,
			rng.randi_range(0, slot_count - 1)
		)
		return


func _singleplayer_ranked_human_count() -> int:
	var human_count: int = 0
	var team_players: Array[FootballPlayer] = (
		blue_players
		if singleplayer_ranked_human_team == TEAM_BLUE
		else red_players
	)
	for player: FootballPlayer in team_players:
		if is_instance_valid(player) and not player.cpu_controlled:
			human_count += 1
	return human_count


func _refresh_pve_ranked_party_configuration() -> void:
	if (
		not singleplayer_ranked_mode
		or not pve_ranked_multiplayer_mode
		or not multiplayer.is_server()
		or game_has_started
		or pve_ranked_matchmaking_locked
	):
		return
	# A party join/leave invalidates ready state and keeps matchmaking in the
	# human-only staging phase. Do not reveal or spawn the opponent early.
	_stage_singleplayer_ranked_matchmaking(false)


func _clear_all_cpu_players() -> void:
	var cpus: Array[FootballPlayer] = []
	for player: FootballPlayer in red_players + blue_players:
		if is_instance_valid(player) and player.cpu_controlled:
			cpus.append(player)
	for cpu: FootballPlayer in cpus:
		_remove_cpu_player(cpu)


func _draw_singleplayer_ranked_abilities(
	rng: RandomNumberGenerator,
	count: int
) -> Array[int]:
	var pool: Array[int] = []
	for ability_id: int in range(1, FootballPlayer.ABILITY_COUNT + 1):
		# Meta Vision is intentionally human-only. Ranked CPU opponents should
		# always receive a real gameplay ability instead of an information overlay.
		if ability_id == FootballPlayer.ABILITY_META_VISION:
			continue
		pool.append(ability_id)
	for index: int in range(pool.size() - 1, 0, -1):
		var swap_index: int = rng.randi_range(0, index)
		var held: int = pool[index]
		pool[index] = pool[swap_index]
		pool[swap_index] = held
	var result: Array[int] = []
	for index: int in range(mini(count, pool.size())):
		result.append(pool[index])
	return result


func _build_singleplayer_cpu_preferences(
	team: StringName,
	abilities: Array[int]
) -> Array[int]:
	var result: Array[int] = []
	result.resize(max_players_per_team)
	result.fill(CPU_ABILITY_RANDOM)
	var human_slot: int = -1
	var team_players: Array[FootballPlayer] = (
		blue_players if team == TEAM_BLUE else red_players
	)
	for player: FootballPlayer in team_players:
		if is_instance_valid(player) and not player.cpu_controlled:
			human_slot = player.team_slot
			break
	var ability_index: int = 0
	for slot: int in range(max_players_per_team):
		if slot == human_slot:
			continue
		if ability_index >= abilities.size():
			break
		result[slot] = abilities[ability_index]
		ability_index += 1
	return result


func _roll_singleplayer_ranked_promoted_opponents(
	rng: RandomNumberGenerator,
	opponent_count: int,
	boss_count: int = 0
) -> int:
	# A single next-division visitor appears on a controlled cadence instead of
	# clustering randomly. This gives roughly one cameo every five ranked games,
	# never more than one, and never stacks a Champions boss + Theodore visitor.
	# Theodore is already the ceiling so it has no higher-division guest.
	if opponent_count <= 0 or singleplayer_ranked_division >= 6 or boss_count > 0:
		return 0
	if pve_ranked_matchmaking_matches < PVE_RANKED_UPPER_DIVISION_GUEST_INTERVAL - 1:
		return 0
	var upcoming_match_number: int = pve_ranked_matchmaking_matches + 1
	if upcoming_match_number % PVE_RANKED_UPPER_DIVISION_GUEST_INTERVAL != 0:
		return 0
	return 1


func _build_singleplayer_ranked_levels(
	rng: RandomNumberGenerator,
	count: int,
	is_opponent: bool,
	promoted_count: int = 0
) -> Array[int]:
	# Every league pulls from the same current champion checkpoint.
	# Bundesliga is held back, Champions is near-ceiling, Theodore is full INT 20.
	var division_index: int = clampi(singleplayer_ranked_division, 1, 6) - 1
	var selected_range: Vector2i = get_pve_ranked_intelligence_range(
		singleplayer_ranked_division
	)
	var next_range: Vector2i = get_pve_ranked_intelligence_range(
		mini(6, singleplayer_ranked_division + 1)
	)
	var result: Array[int] = []
	for index: int in range(count):
		var use_promoted_level: bool = is_opponent and index < promoted_count
		var level_range: Vector2i = next_range if use_promoted_level else selected_range
		var level: int = rng.randi_range(level_range.x, level_range.y)
		if is_opponent and not use_promoted_level and singleplayer_ranked_division <= 3:
			level = mini(level_range.y, level + rng.randi_range(0, 1))
		result.append(level)
	return result


func _build_singleplayer_ranked_cpu_mmrs(
	rng: RandomNumberGenerator,
	count: int,
	is_opponent: bool,
	promoted_count: int = 0
) -> Array[int]:
	var division_index: int = clampi(singleplayer_ranked_division, 1, 6) - 1
	var division_min: int = SINGLEPLAYER_RANKED_DIVISION_THRESHOLDS[division_index]
	var division_max: int = (
		SINGLEPLAYER_RANKED_DIVISION_THRESHOLDS[division_index + 1] - 1
		if division_index + 1 < SINGLEPLAYER_RANKED_DIVISION_THRESHOLDS.size()
		else maxi(division_min + 299, pve_ranked_matchmaking_mmr + 180)
	)
	var center_mmr: int = clampi(
		pve_ranked_matchmaking_mmr + (25 if is_opponent else 0),
		division_min,
		division_max
	)
	var generated_min: int = maxi(division_min, center_mmr - 70)
	var generated_max: int = mini(division_max, center_mmr + 70)
	var result: Array[int] = []
	for index: int in range(count):
		if (
			is_opponent
			and index < promoted_count
			and division_index + 1 < SINGLEPLAYER_RANKED_DIVISION_THRESHOLDS.size()
		):
			var next_min: int = SINGLEPLAYER_RANKED_DIVISION_THRESHOLDS[division_index + 1]
			var next_max: int = (
				SINGLEPLAYER_RANKED_DIVISION_THRESHOLDS[division_index + 2] - 1
				if division_index + 2 < SINGLEPLAYER_RANKED_DIVISION_THRESHOLDS.size()
				else next_min + 299
			)
			result.append(rng.randi_range(next_min, mini(next_max, next_min + 90)))
		else:
			result.append(rng.randi_range(generated_min, generated_max))
	return result


func _pick_singleplayer_ranked_boss_start_index(
	rng: RandomNumberGenerator
) -> int:
	if SINGLEPLAYER_RANKED_BOSSES.is_empty():
		return 0
	var boss_total: int = SINGLEPLAYER_RANKED_BOSSES.size()
	if boss_total == 1:
		singleplayer_ranked_last_boss_id = StringName(
			SINGLEPLAYER_RANKED_BOSSES[0].get("id", &"")
		)
		singleplayer_ranked_boss_rotation_index = -1
		_save_singleplayer_ranked_progress()
		return 0

	# Prestige encounters are intentionally random rather than walking the boss
	# array like a visible list. Avoid only an immediate duplicate when another
	# boss is available; every other boss has the same chance each encounter.
	var candidates: Array[int] = []
	for boss_index: int in range(boss_total):
		var boss_id := StringName(
			SINGLEPLAYER_RANKED_BOSSES[boss_index].get("id", &"")
		)
		if (
			boss_total > 1
			and singleplayer_ranked_last_boss_id != &""
			and boss_id == singleplayer_ranked_last_boss_id
		):
			continue
		candidates.append(boss_index)
	if candidates.is_empty():
		for boss_index: int in range(boss_total):
			candidates.append(boss_index)
	var selected_index: int = candidates[
		rng.randi_range(0, candidates.size() - 1)
	]
	singleplayer_ranked_last_boss_id = StringName(
		SINGLEPLAYER_RANKED_BOSSES[selected_index].get("id", &"")
	)
	# Keep the legacy save field inert for backwards compatibility.
	singleplayer_ranked_boss_rotation_index = -1
	_save_singleplayer_ranked_progress()
	return selected_index


func _build_singleplayer_ranked_names(
	rng: RandomNumberGenerator,
	abilities: Array[int],
	is_opponent: bool,
	boss_count: int,
	boss_start_index: int,
	used_names: Dictionary,
	promoted_count: int = 0
) -> Array[String]:
	var result: Array[String] = []
	for index: int in range(abilities.size()):
		var selected_name: String = ""
		if is_opponent and index < boss_count:
			var boss: Dictionary = SINGLEPLAYER_RANKED_BOSSES[
				(boss_start_index + index) % SINGLEPLAYER_RANKED_BOSSES.size()
			]
			selected_name = str(boss.get("name", "Ranked Boss"))
		elif is_opponent and index < promoted_count:
			# The visitor is represented by the NEXT league's actual identity pool,
			# not merely a higher intelligence value with a local-league name.
			selected_name = _pick_singleplayer_ranked_division_name(
				rng,
				mini(6, singleplayer_ranked_division + 1),
				abilities[index],
				used_names,
				true
			)
		else:
			selected_name = _pick_singleplayer_ranked_division_name(
				rng,
				singleplayer_ranked_division,
				abilities[index],
				used_names,
				false
			)
		if selected_name.is_empty():
			selected_name = "Ranked CPU %d" % (used_names.size() + 1)
		used_names[selected_name] = true
		result.append(selected_name)
	return result


func _pick_singleplayer_ranked_division_name(
	rng: RandomNumberGenerator,
	division: int,
	ability_id: int,
	used_names: Dictionary,
	force_upper_identity: bool = false
) -> String:
	var safe_division: int = clampi(division, 1, 6)
	if safe_division <= 3:
		return _pick_singleplayer_ranked_name_from_pool(
			rng,
			PVE_RANKED_FUNNY_NAMES_BY_DIVISION.get(safe_division, []) as Array,
			used_names
		)

	if safe_division == 4 and not force_upper_identity:
		# Bundesliga deliberately feels transitional: roughly half recognizable
		# footballers and half of the remaining higher-tier joke identities.
		if rng.randf() >= PVE_RANKED_BUNDESLIGA_FOOTBALLER_CHANCE:
			var funny_pick: String = _pick_singleplayer_ranked_name_from_pool(
				rng,
				PVE_RANKED_FUNNY_NAMES_BY_DIVISION.get(4, []) as Array,
				used_names
			)
			if not funny_pick.is_empty():
				return funny_pick

	var football_pool: Array = PVE_RANKED_FOOTBALL_NAMES_BY_DIVISION.get(
		safe_division,
		[]
	) as Array
	var football_pick: String = _pick_singleplayer_ranked_elite_name(
		ability_id,
		used_names,
		football_pool
	)
	if not football_pick.is_empty():
		return football_pick

	# If an unusually large team exhausts a league pool, stay inside that
	# league's identity tier before falling back to a generic CPU name.
	return _pick_singleplayer_ranked_name_from_pool(
		rng,
		football_pool,
		used_names
	)


func _pick_singleplayer_ranked_name_from_pool(
	rng: RandomNumberGenerator,
	pool: Array,
	used_names: Dictionary
) -> String:
	if pool.is_empty():
		return ""
	var available: Array[String] = []
	for candidate_variant: Variant in pool:
		var candidate_name: String = str(candidate_variant)
		if not used_names.has(candidate_name):
			available.append(candidate_name)
	if available.is_empty():
		return ""
	return available[rng.randi_range(0, available.size() - 1)]


func _pick_singleplayer_ranked_elite_name(
	ability_id: int,
	used_names: Dictionary,
	allowed_names: Array = []
) -> String:
	var allowed_lookup: Dictionary = {}
	for allowed_variant: Variant in allowed_names:
		allowed_lookup[str(allowed_variant)] = true
	var restrict_to_pool: bool = not allowed_names.is_empty()
	var candidates: Array = LADDER_ELITE_NAMES_BY_ABILITY.get(
		ability_id,
		LADDER_ELITE_NAMES_BY_ABILITY[FootballPlayer.ABILITY_NONE]
	) as Array
	for candidate_variant: Variant in candidates:
		var candidate_name: String = str(candidate_variant)
		if (
			not used_names.has(candidate_name)
			and (not restrict_to_pool or allowed_lookup.has(candidate_name))
		):
			return candidate_name

	# If the hand-authored ability list has no in-tier match, choose by actual
	# football field role before falling back. This is what keeps a defensive
	# slot on Rodri / Van Dijk / Courtois instead of assigning it to Messi.
	if restrict_to_pool:
		var best_role_name: String = ""
		var best_role_fit: int = -100000
		for allowed_variant: Variant in allowed_names:
			var allowed_name: String = str(allowed_variant)
			if used_names.has(allowed_name):
				continue
			var role_fit: int = _get_singleplayer_ranked_footballer_ability_role_fit(
				allowed_name, ability_id
			)
			if role_fit > best_role_fit:
				best_role_fit = role_fit
				best_role_name = allowed_name
		if not best_role_name.is_empty():
			return best_role_name
		return ""

	for fallback_variant: Variant in LADDER_ELITE_NAMES_BY_ABILITY.values():
		var fallback_candidates: Array = fallback_variant as Array
		for fallback_name_variant: Variant in fallback_candidates:
			var fallback_name: String = str(fallback_name_variant)
			if not used_names.has(fallback_name):
				return fallback_name
	return ""


func _get_singleplayer_ranked_footballer_role(player_name: String) -> StringName:
	match player_name:
		LADDER_FINAL_BOSS_NAME:
			return &"winger"
		SATORU_GOJO_BOSS_NAME:
			return &"forward_creator"
		NEYMAR_BOSS_NAME:
			return &"forward_creator"
		"Manuel Neuer", "Gianluigi Buffon", "Thibaut Courtois", "Iker Casillas", "Alisson Becker":
			return &"goalkeeper"
		"Paolo Maldini", "Franz Beckenbauer", "William Saliba", "Virgil van Dijk", "Antonio Rudiger", "Roberto Carlos":
			return &"defender"
		"Rodri", "Claude Makelele", "Declan Rice", "N'Golo Kante":
			return &"holding"
		"Enzo Fernandez", "Federico Valverde", "Luka Modric", "Andrea Pirlo", "Xavi Hernandez", "David Beckham", "Jude Bellingham", "Toni Kroos":
			return &"midfielder"
		"Kevin De Bruyne", "Pedri", "Jamal Musiala", "Florian Wirtz", "Andres Iniesta", "Zinedine Zidane", "Kaka":
			return &"creator"
		"Kylian Mbappe", "Lamine Yamal", "Ousmane Dembele", "Bukayo Saka", "Vinicius Junior", "Gareth Bale", "Mohamed Salah", "Garrincha", "Luis Figo":
			return &"winger"
		"Erling Haaland", "Cristiano Ronaldo", "Marco van Basten", "Filippo Inzaghi", "Ronaldo Nazario", "Thierry Henry":
			return &"striker"
		"Lionel Messi", "Pele", "Neymar Junior", "Ronaldinho", "Diego Maradona", "Johan Cruyff", "Thomas Muller", "Alessandro Del Piero":
			return &"forward_creator"
	return &""


func _get_singleplayer_ranked_footballer_ability_role_fit(
	player_name: String,
	ability_id: int
) -> int:
	var football_role: StringName = _get_singleplayer_ranked_footballer_role(player_name)
	if football_role == &"":
		return -100
	if ability_id == FootballPlayer.ABILITY_GOALKEEPER_REACH:
		return 200 if football_role == &"goalkeeper" else -80
	var ability_role: StringName = FootballPlayer.get_ability_role(ability_id)
	match ability_role:
		FootballPlayer.ABILITY_ROLE_DEFENSE:
			match football_role:
				&"defender":
					return 150
				&"holding":
					return 130
				&"goalkeeper":
					return 110
				&"midfielder":
					return 35
				&"creator":
					return -20
				&"winger", &"striker", &"forward_creator":
					return -80
		FootballPlayer.ABILITY_ROLE_PLAYMAKER:
			match football_role:
				&"creator":
					return 150
				&"midfielder":
					return 140
				&"holding":
					return 125
				&"forward_creator":
					return 115
				&"winger":
					return 70
				&"defender":
					return 40
				&"goalkeeper", &"striker":
					return 10
		FootballPlayer.ABILITY_ROLE_ATTACK:
			match football_role:
				&"striker":
					return 155
				&"winger":
					return 145
				&"forward_creator":
					return 135
				&"creator":
					return 70
				&"midfielder":
					return 35
				&"holding", &"defender", &"goalkeeper":
					return -70
		FootballPlayer.ABILITY_ROLE_FLEXIBLE:
			match football_role:
				&"forward_creator", &"midfielder", &"creator":
					return 130
				&"winger", &"holding":
					return 105
				&"striker", &"defender":
					return 90
				&"goalkeeper":
					return 45
	return 0


func _get_singleplayer_ranked_footballer_ability_pool(player_name: String) -> Array[int]:
	# A handful of signature players get an even tighter kit; everyone else is
	# driven by the field-role archetype below. This keeps recognizable identity
	# while still reusing the game's existing ability mechanics.
	match player_name:
		"Lionel Messi":
			return [FootballPlayer.ABILITY_BURST_DRIBBLE, FootballPlayer.ABILITY_NUTMEG, FootballPlayer.ABILITY_HEEL_TURN, FootballPlayer.ABILITY_TIME_SKIP_PASS]
		"Erling Haaland":
			return [FootballPlayer.ABILITY_DIRECT_FINISH, FootballPlayer.ABILITY_POWER_STRIKE, FootballPlayer.ABILITY_QUICK_TRIGGER, FootballPlayer.ABILITY_OVERDRIVE]
		"Kylian Mbappe":
			return [FootballPlayer.ABILITY_BREAKAWAY, FootballPlayer.ABILITY_OVERDRIVE, FootballPlayer.ABILITY_BURST_DRIBBLE, FootballPlayer.ABILITY_DIRECT_FINISH]
		"Cristiano Ronaldo":
			return [FootballPlayer.ABILITY_POWER_STRIKE, FootballPlayer.ABILITY_DIRECT_FINISH, FootballPlayer.ABILITY_QUICK_TRIGGER, FootballPlayer.ABILITY_OVERDRIVE]
		"Kevin De Bruyne":
			return [FootballPlayer.ABILITY_TIME_SKIP_PASS, FootballPlayer.ABILITY_DECOY_RUN, FootballPlayer.ABILITY_RETURN_TAG, FootballPlayer.ABILITY_SIDE_SWIPE]
		"Neymar Junior", "Ronaldinho":
			return [FootballPlayer.ABILITY_NUTMEG, FootballPlayer.ABILITY_ELASTIC_STEP, FootballPlayer.ABILITY_BURST_DRIBBLE, FootballPlayer.ABILITY_HEEL_TURN]
		"Rodri":
			return [FootballPlayer.ABILITY_ECHO, FootballPlayer.ABILITY_IRON_ANCHOR, FootballPlayer.ABILITY_RETURN_TAG, FootballPlayer.ABILITY_ENFORCER]
		"Roberto Carlos":
			return [FootballPlayer.ABILITY_POWER_STRIKE, FootballPlayer.ABILITY_OVERDRIVE, FootballPlayer.ABILITY_IRON_ANCHOR, FootballPlayer.ABILITY_SIDE_SWIPE]
		"David Beckham":
			return [FootballPlayer.ABILITY_SIDE_SWIPE, FootballPlayer.ABILITY_TIME_SKIP_PASS, FootballPlayer.ABILITY_RETURN_TAG, FootballPlayer.ABILITY_POWER_STRIKE]

	var role: StringName = _get_singleplayer_ranked_footballer_role(player_name)
	match role:
		&"goalkeeper":
			return [FootballPlayer.ABILITY_GOALKEEPER_REACH, FootballPlayer.ABILITY_REFLEX_BLOCK, FootballPlayer.ABILITY_IRON_ANCHOR]
		&"defender":
			return [FootballPlayer.ABILITY_IRON_ANCHOR, FootballPlayer.ABILITY_REFLEX_BLOCK, FootballPlayer.ABILITY_ENFORCER, FootballPlayer.ABILITY_ECHO]
		&"holding":
			return [FootballPlayer.ABILITY_ECHO, FootballPlayer.ABILITY_IRON_ANCHOR, FootballPlayer.ABILITY_ENFORCER, FootballPlayer.ABILITY_RETURN_TAG]
		&"midfielder":
			return [FootballPlayer.ABILITY_SIDE_SWIPE, FootballPlayer.ABILITY_TIME_SKIP_PASS, FootballPlayer.ABILITY_RETURN_TAG, FootballPlayer.ABILITY_OVERDRIVE]
		&"creator":
			return [FootballPlayer.ABILITY_DECOY_RUN, FootballPlayer.ABILITY_TIME_SKIP_PASS, FootballPlayer.ABILITY_BURST_DRIBBLE, FootballPlayer.ABILITY_RETURN_TAG]
		&"winger":
			return [FootballPlayer.ABILITY_BURST_DRIBBLE, FootballPlayer.ABILITY_BREAKAWAY, FootballPlayer.ABILITY_ELASTIC_STEP, FootballPlayer.ABILITY_NUTMEG]
		&"striker":
			return [FootballPlayer.ABILITY_DIRECT_FINISH, FootballPlayer.ABILITY_POWER_STRIKE, FootballPlayer.ABILITY_QUICK_TRIGGER, FootballPlayer.ABILITY_OVERDRIVE]
		&"forward_creator":
			return [FootballPlayer.ABILITY_BURST_DRIBBLE, FootballPlayer.ABILITY_NUTMEG, FootballPlayer.ABILITY_DIRECT_FINISH, FootballPlayer.ABILITY_HEEL_TURN]
	return []


func _apply_singleplayer_ranked_footballer_ability_profiles(
	rng: RandomNumberGenerator,
	names: Array[String],
	abilities: Array[int],
	boss_count: int = 0
) -> void:
	if names.is_empty() or abilities.is_empty():
		return
	var used: Dictionary = {}
	# Boss slots retain their handcrafted abilities.
	for index: int in range(mini(boss_count, abilities.size())):
		used[abilities[index]] = true
	for index: int in range(mini(names.size(), abilities.size())):
		if index < boss_count:
			continue
		var player_name: String = names[index]
		var preferred: Array[int] = _get_singleplayer_ranked_footballer_ability_pool(player_name)
		if preferred.is_empty():
			used[abilities[index]] = true
			continue
		var football_role: StringName = _get_singleplayer_ranked_footballer_role(player_name)
		var start_index: int = (
			0
			if football_role == &"goalkeeper"
			else rng.randi_range(0, preferred.size() - 1)
		)
		var selected: int = preferred[start_index]
		for offset: int in range(preferred.size()):
			var candidate: int = preferred[(start_index + offset) % preferred.size()]
			if candidate == FootballPlayer.ABILITY_META_VISION:
				continue
			if not used.has(candidate):
				selected = candidate
				break
		if selected == FootballPlayer.ABILITY_META_VISION:
			selected = FootballPlayer.ABILITY_NONE
		abilities[index] = selected
		if selected != FootballPlayer.ABILITY_NONE:
			used[selected] = true


func _get_singleplayer_ranked_football_role_defense_bias(player: FootballPlayer) -> float:
	if player == null:
		return 0.0
	var role: StringName = StringName(player.get_meta("pve_ranked_football_role", &""))
	match role:
		&"goalkeeper":
			return -900.0
		&"defender":
			return -620.0
		&"holding":
			return -430.0
		&"midfielder":
			return -140.0
		&"creator":
			return 100.0
		&"winger":
			return 260.0
		&"striker":
			return 360.0
		&"forward_creator":
			return 320.0
	return 0.0


func _get_singleplayer_ranked_ability_personality_hint(ability_id: int) -> StringName:
	match ability_id:
		FootballPlayer.ABILITY_POWER_STRIKE, FootballPlayer.ABILITY_QUICK_TRIGGER, FootballPlayer.ABILITY_DIRECT_FINISH:
			return &"direct"
		FootballPlayer.ABILITY_BURST_DRIBBLE, FootballPlayer.ABILITY_HEEL_TURN, FootballPlayer.ABILITY_ELASTIC_STEP, FootballPlayer.ABILITY_BLIND_SPOT, FootballPlayer.ABILITY_BOOGIE_WOOGIE, FootballPlayer.ABILITY_SNAPBACK, FootballPlayer.ABILITY_SIDE_SWIPE, FootballPlayer.ABILITY_NUTMEG:
			return &"technical"
		FootballPlayer.ABILITY_TIME_SKIP_PASS, FootballPlayer.ABILITY_META_VISION, FootballPlayer.ABILITY_RETURN_TAG:
			return &"possession"
		FootballPlayer.ABILITY_OVERDRIVE, FootballPlayer.ABILITY_BREAKAWAY:
			return &"counterattacker"
		FootballPlayer.ABILITY_ENFORCER, FootballPlayer.ABILITY_REFLEX_BLOCK, FootballPlayer.ABILITY_ECHO:
			return &"aggressive"
		FootballPlayer.ABILITY_GOALKEEPER_REACH, FootballPlayer.ABILITY_IRON_ANCHOR, FootballPlayer.ABILITY_COPYCAT, FootballPlayer.ABILITY_DECOY_RUN:
			return &"adaptive"
	return &"adaptive"


func _get_singleplayer_ranked_cpu_personality(
	player_name: String,
	ability_id: int
) -> StringName:
	# Special bosses retain their handcrafted personalities/profile logic.
	if player_name == LADDER_FINAL_BOSS_NAME:
		return CPUPlayerAI.CPU_PERSONALITY_AGGRESSIVE
	if player_name == SATORU_GOJO_BOSS_NAME:
		return CPUPlayerAI.CPU_PERSONALITY_COUNTERATTACKER
	if player_name == NEYMAR_BOSS_NAME:
		return CPUPlayerAI.CPU_PERSONALITY_TECHNICAL
	if player_name == HAALAND_BOSS_NAME:
		return CPUPlayerAI.CPU_PERSONALITY_AGGRESSIVE

	var ability_style: StringName = _get_singleplayer_ranked_ability_personality_hint(
		ability_id
	)
	var named_style: StringName = StringName(
		PVE_RANKED_ELITE_PERSONALITY_BY_NAME.get(player_name, &"")
	)
	if named_style == &"":
		# Funny/lower-division CPUs get personality from their selected ability,
		# so even early PvE opponents no longer all feel behaviorally identical.
		return ability_style
	if named_style == ability_style:
		return named_style

	# Strongly identity-defining abilities may nudge a compatible player toward
	# that style, while avoiding nonsense such as turning a controller into a
	# permanent high-pressure attacker just because of one defensive ability.
	if ability_id in [
		FootballPlayer.ABILITY_OVERDRIVE,
		FootballPlayer.ABILITY_BREAKAWAY
	] and named_style in [&"direct", &"technical", &"counterattacker"]:
		return &"counterattacker"
	if ability_id in [
		FootballPlayer.ABILITY_BURST_DRIBBLE,
		FootballPlayer.ABILITY_HEEL_TURN,
		FootballPlayer.ABILITY_ELASTIC_STEP,
		FootballPlayer.ABILITY_BLIND_SPOT,
		FootballPlayer.ABILITY_BOOGIE_WOOGIE,
		FootballPlayer.ABILITY_SNAPBACK,
		FootballPlayer.ABILITY_SIDE_SWIPE,
		FootballPlayer.ABILITY_NUTMEG
	] and named_style in [&"technical", &"adaptive"]:
		return &"technical"
	if ability_id in [
		FootballPlayer.ABILITY_TIME_SKIP_PASS,
		FootballPlayer.ABILITY_META_VISION,
		FootballPlayer.ABILITY_RETURN_TAG
	] and named_style in [&"possession", &"adaptive"]:
		return &"possession"
	if ability_id in [
		FootballPlayer.ABILITY_POWER_STRIKE,
		FootballPlayer.ABILITY_QUICK_TRIGGER,
		FootballPlayer.ABILITY_DIRECT_FINISH
	] and named_style in [&"direct", &"counterattacker"]:
		return &"direct"
	return named_style


func _apply_singleplayer_ranked_cpu_profiles() -> void:
	if not singleplayer_ranked_mode:
		return
	_apply_singleplayer_ranked_team_profiles(TEAM_BLUE)
	_apply_singleplayer_ranked_team_profiles(TEAM_RED)


func _apply_singleplayer_ranked_team_profiles(team: StringName) -> void:
	var team_players: Array[FootballPlayer] = (
		blue_players if team == TEAM_BLUE else red_players
	)
	var cpus: Array[FootballPlayer] = []
	for player: FootballPlayer in team_players:
		if is_instance_valid(player) and player.cpu_controlled:
			cpus.append(player)
	cpus.sort_custom(
		func(first: FootballPlayer, second: FootballPlayer) -> bool:
			return first.team_slot < second.team_slot
	)
	var prefix: String = "blue" if team == TEAM_BLUE else "red"
	var levels: Array = singleplayer_ranked_encounter.get(
		prefix + "_levels",
		[]
	) as Array
	var names: Array = singleplayer_ranked_encounter.get(
		prefix + "_names",
		[]
	) as Array
	var abilities: Array = singleplayer_ranked_encounter.get(
		prefix + "_abilities",
		[]
	) as Array
	var mmrs: Array = singleplayer_ranked_encounter.get(
		prefix + "_mmrs",
		[]
	) as Array
	var boss_count: int = (
		int(singleplayer_ranked_encounter.get("boss_count", 0))
		if team == singleplayer_ranked_cpu_team
		else 0
	)
	var boss_start_index: int = int(
		singleplayer_ranked_encounter.get("boss_start_index", 0)
	)
	for index: int in range(cpus.size()):
		var cpu: FootballPlayer = cpus[index]
		var ranked_intelligence: int = (
			int(levels[index]) if index < levels.size() else cpu_ai_level
		)
		cpu.display_name = (
			str(names[index])
			if index < names.size()
			else "Ranked CPU %d" % (index + 1)
		)
		cpu.set_meta(
			"pve_ranked_mmr",
			int(mmrs[index]) if index < mmrs.size() else singleplayer_ranked_mmr
		)
		cpu.set_meta(
			"pve_ranked_football_role",
			_get_singleplayer_ranked_footballer_role(cpu.display_name)
		)
		cpu.set_meta(
			"pve_ranked_signature_ability",
			int(abilities[index]) if index < abilities.size() else cpu.selected_ability
		)
		var controller := cpu.get_node_or_null("CPUController") as CPUPlayerAI
		if controller != null:
			controller.set_skill_level_override(ranked_intelligence)
			controller.set_cpu_personality(
				_get_singleplayer_ranked_cpu_personality(
					cpu.display_name,
					cpu.selected_ability
				)
			)
		if index < boss_count:
			_apply_singleplayer_ranked_boss(
				cpu,
				index,
				boss_start_index,
				ranked_intelligence
			)
		else:
			cpu.set_permanent_overdrive(false)
			cpu.set_permanent_power_strike(false)
			cpu.set_permanent_elastic_step(false)
			cpu.set_permanent_iron_anchor(false)
			cpu.set_neuer_boss_profile(false)


func _apply_singleplayer_ranked_boss(
	cpu: FootballPlayer,
	boss_index: int,
	boss_start_index: int,
	ranked_intelligence: int
) -> void:
	if cpu == null or SINGLEPLAYER_RANKED_BOSSES.is_empty():
		return
	var boss: Dictionary = SINGLEPLAYER_RANKED_BOSSES[
		(boss_start_index + boss_index) % SINGLEPLAYER_RANKED_BOSSES.size()
	]
	match StringName(boss.get("profile", &"")):
		&"dictator_mbappe":
			_apply_dictator_mbappe_profile(cpu)
		&"satoru_gojo":
			_apply_satoru_gojo_profile(cpu)
		&"neymar_jr":
			_apply_neymar_profile(cpu)
		&"erling_haaland":
			_apply_haaland_profile(cpu)
		&"manuel_neuer":
			_apply_manuel_neuer_profile(cpu)
		_:
			cpu.set_selected_ability(int(boss.get("ability", 0)))
			var controller := cpu.get_node_or_null("CPUController") as CPUPlayerAI
			if controller != null:
				controller.set_cpu_personality(
					StringName(boss.get("personality", &"adaptive"))
				)
	# The reusable Fun boss profiles intentionally remain Intelligence 15. PvE
	# Ranked reapplies the encounter's league intelligence here so a Champions
	# or Theodore boss is not accidentally downgraded back to the legacy cap.
	var ranked_controller := cpu.get_node_or_null("CPUController") as CPUPlayerAI
	if ranked_controller != null:
		ranked_controller.set_skill_level_override(
			clampi(ranked_intelligence, 1, CPU_MAX_INTELLIGENCE)
		)


func _get_singleplayer_ranked_opponent_average_mmr() -> int:
	var opponents: Array[FootballPlayer] = (
		blue_players if singleplayer_ranked_cpu_team == TEAM_BLUE else red_players
	)
	var total_mmr: int = 0
	var opponent_count: int = 0
	for opponent: FootballPlayer in opponents:
		if not is_instance_valid(opponent) or not opponent.cpu_controlled:
			continue
		total_mmr += maxi(
			PVE_RANKED_MIN_MMR,
			int(opponent.get_meta("pve_ranked_mmr", singleplayer_ranked_mmr))
		)
		opponent_count += 1
	if opponent_count <= 0:
		return -1
	return int(round(float(total_mmr) / float(opponent_count)))


func _get_singleplayer_ranked_highest_opponent_mmr() -> int:
	var opponents: Array[FootballPlayer] = (
		blue_players if singleplayer_ranked_cpu_team == TEAM_BLUE else red_players
	)
	var highest_mmr: int = -1
	for opponent: FootballPlayer in opponents:
		if not is_instance_valid(opponent) or not opponent.cpu_controlled:
			continue
		highest_mmr = maxi(
			highest_mmr,
			maxi(
				PVE_RANKED_MIN_MMR,
				int(opponent.get_meta("pve_ranked_mmr", singleplayer_ranked_mmr))
			)
		)
	return highest_mmr


func _resolve_singleplayer_ranked_result(
	winning_team: StringName
) -> void:
	if not singleplayer_ranked_mode or not multiplayer.is_server():
		return
	var won: bool = winning_team == singleplayer_ranked_human_team
	var nominal_opponent_mmr: int = get_pve_ranked_opponent_mmr(
		singleplayer_ranked_division
	)
	var actual_opponent_mmr: int = _get_singleplayer_ranked_opponent_average_mmr()
	# Use the MMR of the team that actually spawned. This matters when a ranked
	# encounter contains a promoted CPU from the next division.
	var opponent_mmr: int = (
		actual_opponent_mmr if actual_opponent_mmr >= 0 else nominal_opponent_mmr
	)
	var highest_opponent_mmr: int = _get_singleplayer_ranked_highest_opponent_mmr()
	var host_peer_id: int = multiplayer.get_unique_id()
	var human_peer_ids: Array[int] = []
	for player: FootballPlayer in (
		blue_players if singleplayer_ranked_human_team == TEAM_BLUE else red_players
	):
		if is_instance_valid(player) and not player.cpu_controlled:
			human_peer_ids.append(player.owner_peer_id)
	if human_peer_ids.is_empty():
		human_peer_ids.append(host_peer_id)
	for peer_id: int in human_peer_ids:
		var profile: Dictionary = _pve_ranked_player_profiles.get(
			peer_id,
			{
				"mmr": singleplayer_ranked_mmr,
				"matches": singleplayer_ranked_matches
			}
		) as Dictionary
		if not pve_ranked_multiplayer_mode and peer_id == host_peer_id:
			profile = {
				"mmr": singleplayer_ranked_mmr,
				"matches": singleplayer_ranked_matches
			}
		var profile_mmr: int = maxi(
			PVE_RANKED_MIN_MMR,
			int(profile.get("mmr", PVE_RANKED_STARTING_MMR))
		)
		var change: int = calculate_pve_ranked_mmr_change(
			profile_mmr,
			opponent_mmr,
			won,
			highest_opponent_mmr
		)
		var updated_mmr: int = maxi(PVE_RANKED_MIN_MMR, profile_mmr + change)
		var updated_matches: int = maxi(0, int(profile.get("matches", 0))) + 1
		_pve_ranked_player_profiles[peer_id] = {
			"mmr": updated_mmr,
			"matches": updated_matches
		}
		if peer_id == host_peer_id:
			singleplayer_ranked_mmr = updated_mmr
			singleplayer_ranked_matches = updated_matches
			singleplayer_ranked_last_change = change
		elif pve_ranked_multiplayer_mode:
			_receive_pve_ranked_local_result.rpc_id(
				peer_id,
				updated_mmr,
				updated_matches,
				change,
				won
			)
	singleplayer_ranked_division = (
		get_singleplayer_ranked_division_for_mmr(
			singleplayer_ranked_mmr
		)
	)
	singleplayer_ranked_last_result = (
		&"won"
		if winning_team == singleplayer_ranked_human_team
		else &"lost"
	)
	_singleplayer_ranked_prepare_pending = true
	_clear_local_pve_ranked_abandonment_pending()
	_save_singleplayer_ranked_progress()
	_broadcast_singleplayer_ranked_state()


@rpc("authority", "call_local", "reliable")
func _receive_pve_ranked_local_result(
	updated_mmr: int,
	updated_matches: int,
	change: int,
	won: bool
) -> void:
	singleplayer_ranked_mmr = maxi(PVE_RANKED_MIN_MMR, updated_mmr)
	singleplayer_ranked_matches = maxi(0, updated_matches)
	singleplayer_ranked_last_change = change
	singleplayer_ranked_last_result = &"won" if won else &"lost"
	singleplayer_ranked_division = get_singleplayer_ranked_division_for_mmr(
		singleplayer_ranked_mmr
	)
	_clear_local_pve_ranked_abandonment_pending()
	_save_singleplayer_ranked_progress()
	singleplayer_ranked_state_changed.emit(get_singleplayer_ranked_snapshot())


@rpc("any_peer", "call_remote", "reliable")
func _submit_pve_ranked_profile(mmr: int, matches: int) -> void:
	if not multiplayer.is_server() or not singleplayer_ranked_mode:
		return
	var sender: int = multiplayer.get_remote_sender_id()
	if sender <= 0:
		return
	_pve_ranked_player_profiles[sender] = {
		"mmr": maxi(PVE_RANKED_MIN_MMR, mmr),
		"matches": maxi(0, matches)
	}
	refresh_roster()
	# A client can hit READY at nearly the same moment its profile reaches the
	# host. Retry finalization after profile receipt so matchmaking never hangs.
	if _pve_ranked_all_party_humans_ready():
		_start_singleplayer_ranked_when_ready.call_deferred()


func _load_singleplayer_ranked_progress() -> void:
	var config := ConfigFile.new()
	if config.load(singleplayer_ranked_progress_path) != OK:
		singleplayer_ranked_mmr = PVE_RANKED_STARTING_MMR
		singleplayer_ranked_matches = 0
		singleplayer_ranked_last_boss_id = &""
		singleplayer_ranked_boss_rotation_index = -1
	else:
		singleplayer_ranked_mmr = maxi(
			PVE_RANKED_MIN_MMR,
			int(config.get_value("rank", "mmr", PVE_RANKED_STARTING_MMR))
		)
		singleplayer_ranked_matches = maxi(
			0,
			int(config.get_value("rank", "matches", 0))
		)
		singleplayer_ranked_last_boss_id = StringName(
			config.get_value("rank", "last_boss_id", "")
		)
		# Preserve rotation position for saves made while this slot was Ronaldinho.
		if singleplayer_ranked_last_boss_id == &"ronaldinho":
			singleplayer_ranked_last_boss_id = &"neymar_jr"
		singleplayer_ranked_boss_rotation_index = int(
			config.get_value("rank", "boss_rotation_index", -1)
		)
		# Older saves only stored the previous boss id. Derive the next slot once
		# so the rotation becomes deterministic and survives every lobby/profile
		# refresh instead of depending on a transient in-memory last-boss value.
		if (
			singleplayer_ranked_boss_rotation_index < 0
			and singleplayer_ranked_last_boss_id != &""
		):
			for boss_index: int in range(SINGLEPLAYER_RANKED_BOSSES.size()):
				var saved_boss_id := StringName(
					SINGLEPLAYER_RANKED_BOSSES[boss_index].get("id", &"")
				)
				if saved_boss_id == singleplayer_ranked_last_boss_id:
					singleplayer_ranked_boss_rotation_index = (
						(boss_index + 1) % maxi(1, SINGLEPLAYER_RANKED_BOSSES.size())
					)
					break
	singleplayer_ranked_division = (
		get_singleplayer_ranked_division_for_mmr(
			singleplayer_ranked_mmr
		)
	)


func _save_singleplayer_ranked_progress() -> void:
	var config := ConfigFile.new()
	config.set_value("rank", "mmr", singleplayer_ranked_mmr)
	config.set_value("rank", "matches", singleplayer_ranked_matches)
	config.set_value(
		"rank",
		"last_boss_id",
		str(singleplayer_ranked_last_boss_id)
	)
	config.set_value(
		"rank",
		"boss_rotation_index",
		singleplayer_ranked_boss_rotation_index
	)
	var error: Error = config.save(singleplayer_ranked_progress_path)
	if error != OK:
		push_warning(
			"Could not save single-player ranked progress: %s"
			% error_string(error)
		)


func _broadcast_singleplayer_ranked_state() -> void:
	if multiplayer.is_server():
		_receive_singleplayer_ranked_state.rpc(
			get_singleplayer_ranked_snapshot()
		)


@rpc("authority", "call_local", "reliable")
func _receive_singleplayer_ranked_state(snapshot: Dictionary) -> void:
	var preserve_local_profile: bool = (
		bool(snapshot.get("multiplayer", false))
		and not multiplayer.is_server()
	)
	var local_profile: Dictionary = _read_singleplayer_ranked_progress()
	singleplayer_ranked_mode = bool(snapshot.get("enabled", false))
	pve_ranked_multiplayer_mode = bool(snapshot.get("multiplayer", false))
	if preserve_local_profile:
		singleplayer_ranked_mmr = int(local_profile.get("mmr", PVE_RANKED_STARTING_MMR))
		singleplayer_ranked_matches = int(local_profile.get("matches", 0))
	else:
		singleplayer_ranked_mmr = int(snapshot.get("mmr", PVE_RANKED_STARTING_MMR))
		singleplayer_ranked_matches = int(snapshot.get("matches", 0))
	singleplayer_ranked_team_size = int(snapshot.get("team_size", 1))
	pve_ranked_matchmaking_mmr = int(
		snapshot.get("matchmaking_mmr", singleplayer_ranked_mmr)
	)
	pve_ranked_matchmaking_matches = int(
		snapshot.get("matchmaking_matches", singleplayer_ranked_matches)
	)
	pve_ranked_matchmaking_division = int(
		snapshot.get(
			"matchmaking_division",
			get_singleplayer_ranked_division_for_mmr(pve_ranked_matchmaking_mmr)
		)
	)
	pve_ranked_matchmaking_locked = bool(
		snapshot.get("matchmaking_locked", false)
	)
	singleplayer_ranked_division = (
		get_singleplayer_ranked_division_for_mmr(singleplayer_ranked_mmr)
		if preserve_local_profile
		else int(snapshot.get("division", 1))
	)
	singleplayer_ranked_human_team = StringName(
		snapshot.get("human_team", str(TEAM_BLUE))
	)
	singleplayer_ranked_cpu_team = StringName(
		snapshot.get("cpu_team", str(TEAM_RED))
	)
	if not preserve_local_profile:
		singleplayer_ranked_last_change = int(
			snapshot.get("last_change", 0)
		)
		singleplayer_ranked_last_result = StringName(
			snapshot.get("last_result", "")
		)
	singleplayer_ranked_encounter = (
		snapshot.get("encounter", {}) as Dictionary
	).duplicate(true)
	singleplayer_ranked_state_changed.emit(
		get_singleplayer_ranked_snapshot()
	)
	if singleplayer_ranked_mode and preserve_local_profile:
		_submit_pve_ranked_profile.rpc_id(
			SERVER_PEER_ID,
			singleplayer_ranked_mmr,
			singleplayer_ranked_matches
		)


func _read_singleplayer_ranked_progress() -> Dictionary:
	var config := ConfigFile.new()
	if config.load(singleplayer_ranked_progress_path) != OK:
		return {"mmr": PVE_RANKED_STARTING_MMR, "matches": 0}
	return {
		"mmr": maxi(
			PVE_RANKED_MIN_MMR,
			int(config.get_value("rank", "mmr", PVE_RANKED_STARTING_MMR))
		),
		"matches": maxi(0, int(config.get_value("rank", "matches", 0))),
		"last_boss_id": str(config.get_value("rank", "last_boss_id", ""))
	}


func _on_network_session_ended() -> void:
	_abort_human_demonstration_recording()
	# MatchManager is persistent across menu sessions. Draft used to survive a
	# disconnect here, which made every subsequently launched mode start its card
	# flow. Clear both the mode flag and all per-match picks/perks unconditionally.
	champions_league_mode = false
	_reset_draft_state(true)
	for player: FootballPlayer in _get_draft_players():
		player.clear_draft_perk()
	ladder_mode = false
	ladder_rung = 1
	ladder_run_seed = 0
	ladder_encounter.clear()
	ladder_last_result = &""
	ladder_human_team = TEAM_BLUE
	ladder_cpu_team = TEAM_RED
	_ladder_prepare_pending = false
	singleplayer_ranked_mode = false
	pve_ranked_multiplayer_mode = false
	_pve_ranked_player_profiles.clear()
	pve_ranked_matchmaking_mmr = PVE_RANKED_STARTING_MMR
	pve_ranked_matchmaking_matches = 0
	pve_ranked_matchmaking_division = 1
	pve_ranked_matchmaking_locked = false
	singleplayer_ranked_team_size = 1
	singleplayer_ranked_human_team = TEAM_BLUE
	singleplayer_ranked_cpu_team = TEAM_RED
	singleplayer_ranked_last_change = 0
	singleplayer_ranked_last_result = &""
	singleplayer_ranked_encounter.clear()
	_singleplayer_ranked_prepare_pending = false
	regulation_seconds = _default_regulation_seconds
	goals_to_win = _default_goals_to_win
	tournament_mode = _default_tournament_mode
	ranked_mode = _default_ranked_mode
	fun_mutators = _default_fun_mutators()
	_restore_fun_mutator_runtime()
	cpu_ai_level = _default_cpu_ai_level
	requested_blue_cpu_count = 0
	requested_red_cpu_count = 0
	blue_cpu_ability_preferences = [
		CPU_ABILITY_RANDOM,
		CPU_ABILITY_RANDOM,
		CPU_ABILITY_RANDOM,
		CPU_ABILITY_RANDOM,
		CPU_ABILITY_RANDOM,
		CPU_ABILITY_RANDOM
	]
	red_cpu_ability_preferences = [
		CPU_ABILITY_RANDOM,
		CPU_ABILITY_RANDOM,
		CPU_ABILITY_RANDOM,
		CPU_ABILITY_RANDOM,
		CPU_ABILITY_RANDOM,
		CPU_ABILITY_RANDOM
	]

	red_score = 0
	blue_score = 0
	tournament_leg = 1
	tournament_leg_red_goals = 0
	tournament_leg_blue_goals = 0
	tournament_sudden_death = false
	tournament_halftime_active = false
	tournament_halftime_remaining = 0
	_halftime_generation += 1
	_reset_ranked_draft_state()
	_reset_tournament_tiebreak_state()
	_quick_chat_last_sent_at.clear()
	_cpu_quick_chat_global_last_sent_at = -1000.0
	_clear_goal_replay_state()
	regulation_time_remaining = regulation_seconds
	overtime_elapsed = 0.0
	ranked_active_match_elapsed = 0.0
	_pve_ranked_abandonment_protection_armed = false
	is_overtime = false
	game_has_started = false
	freeplay_active = false
	round_resetting = false
	_match_clock_waiting_for_kickoff = false
	match_results_available = false
	last_winning_team = NO_TEAM
	red_players.clear()
	blue_players.clear()
	_ready_players.clear()
	_active_shot.clear()
	_pending_pass.clear()
	_cpu_pass_intentions.clear()
	_cpu_ball_commitments.clear()
	_cpu_tactical_intentions.clear()
	_cpu_combination_plans.clear()
	_cpu_team_sequence_plans.clear()
	_reset_cpu_possession_state()
	_cpu_team_strategies[TEAM_BLUE] = CPU_STRATEGY_BALANCED
	_cpu_team_strategies[TEAM_RED] = CPU_STRATEGY_BALANCED
	_cpu_strategy_adaptation.clear()
	_current_introduction_team = NO_TEAM
	_current_introduction_names.clear()
	current_field_variant = 0
	field_variant_locked = false
	field_variant_changed.emit(current_field_variant)

	match_settings_changed.emit(regulation_seconds, goals_to_win)
	cpu_settings_changed.emit(0, 0)
	cpu_difficulty_changed.emit(cpu_ai_level)
	cpu_ability_preferences_changed.emit(
		blue_cpu_ability_preferences.duplicate(),
		red_cpu_ability_preferences.duplicate()
	)
	tournament_mode_changed.emit(tournament_mode)
	ranked_mode_changed.emit(ranked_mode)
	champions_league_mode_changed.emit(false)
	draft_state_changed.emit(_build_draft_snapshot(multiplayer.get_unique_id()))
	fun_mutators_changed.emit(fun_mutators.duplicate(true))
	ranked_draft_changed.emit(_build_ranked_draft_snapshot(NO_TEAM))
	_receive_score(
		0,
		0,
		0,
		0,
		1,
		tournament_mode,
		false
	)
	timer_changed.emit(int(ceil(regulation_time_remaining)), false)
	roster_changed.emit(0, 0)
	roster_details_changed.emit(_empty_roster())
	leaderboard_snapshot.clear()
	leaderboard_changed.emit([])
	halftime_changed.emit(false, 0)
	_emit_tournament_tiebreak_state()
	ladder_state_changed.emit(get_ladder_snapshot())
	singleplayer_ranked_state_changed.emit(
		get_singleplayer_ranked_snapshot()
	)


func _physics_process(delta: float) -> void:
	var profile_started_usec: int = 0
	if _runtime_spike_profile_is_enabled():
		profile_started_usec = Time.get_ticks_usec()
	_run_match_physics(delta)
	if profile_started_usec > 0:
		record_runtime_profile_stage(
			&"match_manager",
			Time.get_ticks_usec() - profile_started_usec
		)


func _run_match_physics(delta: float) -> void:
	if not multiplayer.is_server():
		return
	_update_swept_goal_detection()

	if not game_has_started:
		return
	if round_resetting or _match_clock_waiting_for_kickoff:
		_resample_cpu_strategy_adaptation()
		return

	if freeplay_active:
		return

	ranked_active_match_elapsed += delta
	if (
		singleplayer_ranked_mode
		and not _pve_ranked_abandonment_protection_armed
		and ranked_active_match_elapsed >= RANKED_CANCEL_GRACE_SECONDS
	):
		_pve_ranked_abandonment_protection_armed = true
		_receive_pve_ranked_abandonment_armed.rpc()

	_update_fun_rotating_loadouts(delta)
	_update_cpu_quick_chat(delta)

	_human_demo_sample_accumulator += delta
	if _human_demo_sample_accumulator >= 0.10:
		_human_demo_sample_accumulator = 0.0
		_record_human_demonstration_frame()

	_capture_goal_replay(delta)

	if penalty_shootout_active:
		if (
			penalty_attempt_active
			and not _penalty_attempt_clock_started
			and _penalty_ball_has_moved_from_start()
		):
			_penalty_attempt_clock_started = true
			_broadcast_timer()
		if penalty_attempt_active and _penalty_attempt_clock_started:
			penalty_attempt_time_remaining = maxf(
				0.0,
				penalty_attempt_time_remaining - delta
			)
			if penalty_attempt_time_remaining <= 0.0:
				_complete_penalty_attempt(false)
		_timer_sync_accumulator += delta
		if _timer_sync_accumulator >= 0.1:
			_timer_sync_accumulator = 0.0
			_broadcast_timer()
		return

	_update_active_shot()
	_update_cpu_strategy_adaptation()

	if tournament_tiebreak_phase == TIEBREAK_EXTRA_TIME:
		tournament_extra_time_remaining = maxf(
			0.0,
			tournament_extra_time_remaining - delta
		)
		if tournament_extra_time_remaining <= 0.0:
			_finish_tournament_extra_time_period()
	elif is_overtime:
		overtime_elapsed += delta
	else:
		regulation_time_remaining = maxf(
			0.0,
			regulation_time_remaining - delta
		)

		if regulation_time_remaining <= 0.0:
			_finish_regulation()

	_timer_sync_accumulator += delta
	if _timer_sync_accumulator >= 0.1:
		_timer_sync_accumulator = 0.0
		_broadcast_timer()


func _process(delta: float) -> void:
	_process_runtime_spike_profile(delta)
	if _kickoff_profile_active:
		_kickoff_profile_frames_seen += 1
		_kickoff_profile_longest_frame_msec = maxf(
			_kickoff_profile_longest_frame_msec,
			delta * 1000.0
		)
		if _kickoff_profile_frames_seen >= maxi(4, kickoff_profile_frame_count):
			_finish_kickoff_profile()


func is_runtime_spike_profile_active() -> bool:
	return _runtime_spike_profile_is_enabled()


func record_runtime_cpu_profile(
	peer_id: int,
	stage: StringName,
	elapsed_usec: int
) -> void:
	if not _runtime_spike_profile_is_enabled() or elapsed_usec < 0:
		return
	_prepare_runtime_profile_physics_frame()
	_runtime_profile_by_stage[stage] = (
		int(_runtime_profile_by_stage.get(stage, 0)) + elapsed_usec
	)
	if stage == &"total" and peer_id > 0:
		_runtime_profile_cpu_by_peer[peer_id] = (
			int(_runtime_profile_cpu_by_peer.get(peer_id, 0)) + elapsed_usec
		)


func record_runtime_profile_stage(
	stage: StringName,
	elapsed_usec: int
) -> void:
	if not _runtime_spike_profile_is_enabled() or elapsed_usec < 0:
		return
	_prepare_runtime_profile_physics_frame()
	_runtime_profile_by_stage[stage] = (
		int(_runtime_profile_by_stage.get(stage, 0)) + elapsed_usec
	)


func _runtime_spike_profile_is_enabled() -> bool:
	return (
		OS.is_debug_build()
		and runtime_spike_profiling_enabled
		and game_has_started
	)


func _prepare_runtime_profile_physics_frame() -> void:
	var physics_frame: int = Engine.get_physics_frames()
	if physics_frame == _runtime_profile_physics_frame:
		return
	_runtime_profile_physics_frame = physics_frame
	_runtime_profile_cpu_by_peer.clear()
	_runtime_profile_by_stage.clear()


func _process_runtime_spike_profile(delta: float) -> void:
	if not _runtime_spike_profile_is_enabled():
		_clear_runtime_spike_profile_frame()
		return
	var frame_msec: float = delta * 1000.0
	var now_msec: int = Time.get_ticks_msec()
	var cooldown_msec: int = int(
		maxf(0.25, runtime_spike_report_cooldown_seconds) * 1000.0
	)
	if (
		frame_msec >= maxf(16.0, runtime_spike_threshold_msec)
		and now_msec - _runtime_profile_last_report_msec >= cooldown_msec
	):
		_runtime_profile_last_report_msec = now_msec
		_print_runtime_spike_report(frame_msec)


func _print_runtime_spike_report(frame_msec: float) -> void:
	var largest_stage: StringName = &"unattributed"
	var largest_stage_usec: int = 0
	for stage_variant: Variant in _runtime_profile_by_stage.keys():
		var stage: StringName = StringName(stage_variant)
		if stage == &"total":
			continue
		var elapsed_usec: int = int(_runtime_profile_by_stage[stage_variant])
		if elapsed_usec > largest_stage_usec:
			largest_stage_usec = elapsed_usec
			largest_stage = stage
	var cpu_parts: PackedStringArray = PackedStringArray()
	var cpu_total_usec: int = 0
	for peer_variant: Variant in _runtime_profile_cpu_by_peer.keys():
		var peer_id: int = int(peer_variant)
		var elapsed_usec: int = int(_runtime_profile_cpu_by_peer[peer_variant])
		cpu_total_usec += elapsed_usec
		cpu_parts.append(
			"CPU %d %.3fms" % [peer_id, float(elapsed_usec) / 1000.0]
		)
	var physics_active_objects: int = int(Performance.get_monitor(
		Performance.PHYSICS_2D_ACTIVE_OBJECTS
	))
	var physics_collision_pairs: int = int(Performance.get_monitor(
		Performance.PHYSICS_2D_COLLISION_PAIRS
	))
	var physics_islands: int = int(Performance.get_monitor(
		Performance.PHYSICS_2D_ISLAND_COUNT
	))
	var node_count: int = int(Performance.get_monitor(
		Performance.OBJECT_NODE_COUNT
	))
	print(
		"FRAME SPIKE %.3fms | physics=%.3fms | process=%.3fms | AI total=%.3fms | %s | stages=%s | physics2d active=%d pairs=%d islands=%d | nodes=%d replay_frames=%d | suspected=%s (%.3fms)"
		% [
			frame_msec,
			float(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)) * 1000.0,
			float(Performance.get_monitor(Performance.TIME_PROCESS)) * 1000.0,
			float(cpu_total_usec) / 1000.0,
			", ".join(cpu_parts),
			_runtime_profile_by_stage,
			physics_active_objects,
			physics_collision_pairs,
			physics_islands,
			node_count,
			_goal_replay_frames.size(),
			str(largest_stage),
			float(largest_stage_usec) / 1000.0
		]
	)


func _clear_runtime_spike_profile_frame() -> void:
	_runtime_profile_cpu_by_peer.clear()
	_runtime_profile_by_stage.clear()
	_runtime_profile_physics_frame = -1


func is_kickoff_profile_active() -> bool:
	return _kickoff_profile_active


func record_kickoff_cpu_profile(
	_stage: StringName,
	elapsed_usec: int
) -> void:
	if not _kickoff_profile_active or elapsed_usec < 0:
		return
	_kickoff_profile_cpu_total_usec += elapsed_usec
	_kickoff_profile_cpu_longest_usec = maxi(
		_kickoff_profile_cpu_longest_usec,
		elapsed_usec
	)
	_kickoff_profile_cpu_updates += 1
	_kickoff_profile_cpu_by_stage[_stage] = (
		int(_kickoff_profile_cpu_by_stage.get(_stage, 0))
		+ elapsed_usec
	)


func _begin_kickoff_profile(reset_usec: int) -> void:
	if not kickoff_profiling_enabled or not OS.is_debug_build():
		return
	_kickoff_profile_generation += 1
	_kickoff_profile_pending = true
	_kickoff_profile_active = false
	_kickoff_profile_reset_usec = maxi(0, reset_usec)


func _activate_kickoff_profile(transition_usec: int) -> void:
	if not _kickoff_profile_pending:
		return
	_kickoff_profile_pending = false
	_kickoff_profile_active = true
	_kickoff_profile_transition_usec = maxi(0, transition_usec)
	_kickoff_profile_frames_seen = 0
	_kickoff_profile_longest_frame_msec = 0.0
	_kickoff_profile_cpu_total_usec = 0
	_kickoff_profile_cpu_longest_usec = 0
	_kickoff_profile_cpu_updates = 0
	_kickoff_profile_cpu_by_stage.clear()


func _finish_kickoff_profile() -> void:
	if not _kickoff_profile_active:
		return
	_kickoff_profile_active = false
	print(
		"KICKOFF PROFILE #%d | reset=%.3f ms | GO transition=%.3f ms | longest frame=%.3f ms | CPU measured=%.3f ms across %d stages | longest CPU stage=%.3f ms | stages=%s"
		% [
			_kickoff_profile_generation,
			float(_kickoff_profile_reset_usec) / 1000.0,
			float(_kickoff_profile_transition_usec) / 1000.0,
			_kickoff_profile_longest_frame_msec,
			float(_kickoff_profile_cpu_total_usec) / 1000.0,
			_kickoff_profile_cpu_updates,
			float(_kickoff_profile_cpu_longest_usec) / 1000.0,
			_kickoff_profile_cpu_by_stage
		]
	)


# ================================================================
# TEAM REQUESTS
# ================================================================

func request_join_team(team: StringName) -> void:
	if multiplayer.is_server():
		_server_join_team(multiplayer.get_unique_id(), team)
	else:
		_request_join_team.rpc_id(SERVER_PEER_ID, team)


@rpc("any_peer", "call_remote", "reliable")
func _request_join_team(team: StringName) -> void:
	if not multiplayer.is_server():
		return

	_server_join_team(multiplayer.get_remote_sender_id(), team)


func request_leave_team() -> void:
	if multiplayer.is_server():
		_server_leave_team(multiplayer.get_unique_id())
	else:
		_request_leave_team.rpc_id(SERVER_PEER_ID)


@rpc("any_peer", "call_remote", "reliable")
func _request_leave_team() -> void:
	if not multiplayer.is_server():
		return

	_server_leave_team(multiplayer.get_remote_sender_id())


func _server_join_team(peer_id: int, team: StringName) -> void:
	if not multiplayer.is_server():
		return

	var player := _get_player(peer_id)
	if player == null:
		_send_team_join_result(peer_id, false, team)
		return
	_make_room_for_human(team, player)

	var joined := join_team(player, team)
	if joined:
		_schedule_cpu_reconcile()
	_send_team_join_result(peer_id, joined, team)


func _server_leave_team(peer_id: int) -> void:
	if not multiplayer.is_server():
		return

	var player := _get_player(peer_id)
	if player == null:
		_send_team_join_result(peer_id, false, NO_TEAM)
		return

	var left := leave_team(player)
	if left:
		_schedule_cpu_reconcile()
	_send_team_join_result(peer_id, left, NO_TEAM)


func _get_player(peer_id: int) -> FootballPlayer:
	if peer_id <= 0 or players_parent == null:
		return null
	if _cpu_shared_world_frame == int(Engine.get_physics_frames()):
		var cached_player := (
			_cpu_shared_world_model.get("players_by_peer", {}) as Dictionary
		).get(peer_id) as FootballPlayer
		if is_instance_valid(cached_player):
			return cached_player
	return players_parent.get_node_or_null(
		str(peer_id)
	) as FootballPlayer


func _send_team_join_result(
	peer_id: int,
	success: bool,
	team: StringName
) -> void:
	if peer_id == multiplayer.get_unique_id():
		_receive_team_join_result(success, team)
	else:
		_receive_team_join_result.rpc_id(
			peer_id,
			success,
			team
		)


@rpc("authority", "call_remote", "reliable")
func _receive_team_join_result(
	success: bool,
	team: StringName
) -> void:
	team_join_result.emit(success, team)


func request_select_ability(ability_id: int) -> void:
	if multiplayer.is_server():
		_server_select_ability(
			multiplayer.get_unique_id(),
			ability_id
		)
	else:
		_request_select_ability.rpc_id(
			SERVER_PEER_ID,
			ability_id
		)


@rpc("any_peer", "call_remote", "reliable")
func _request_select_ability(ability_id: int) -> void:
	if not multiplayer.is_server():
		return

	_server_select_ability(
		multiplayer.get_remote_sender_id(),
		ability_id
	)


func request_set_ready(ready: bool) -> void:
	if multiplayer.is_server():
		_server_set_ready(multiplayer.get_unique_id(), ready)
	else:
		_request_set_ready.rpc_id(SERVER_PEER_ID, ready)


@rpc("any_peer", "call_remote", "reliable")
func _request_set_ready(ready: bool) -> void:
	if not multiplayer.is_server():
		return

	_server_set_ready(
		multiplayer.get_remote_sender_id(),
		ready
	)


func _server_set_ready(peer_id: int, ready: bool) -> void:
	if not multiplayer.is_server():
		return

	var player := _get_player(peer_id)
	if (
		player == null
		or game_has_started
		or player.team not in [TEAM_RED, TEAM_BLUE]
	):
		_send_ready_state_result(
			peer_id,
			false,
			false,
			"Join a team before readying up."
		)
		return

	if ready:
		_ready_players[peer_id] = true
	else:
		_ready_players.erase(peer_id)

	refresh_roster()
	_send_ready_state_result(
		peer_id,
		true,
		ready,
		"You are ready." if ready else "You are no longer ready."
	)
	if singleplayer_ranked_mode and ready:
		_start_singleplayer_ranked_when_ready.call_deferred()


func _start_singleplayer_ranked_when_ready() -> void:
	if (
		not singleplayer_ranked_mode
		or not multiplayer.is_server()
		or game_has_started
	):
		return
	# Real matchmaking flow: the enemy lineup does not exist until the entire
	# human party is ready AND every human MMR profile has reached the host.
	if not _pve_ranked_all_party_humans_ready():
		return
	if not _pve_ranked_all_party_profiles_received():
		return
	if not pve_ranked_matchmaking_locked:
		_prepare_singleplayer_ranked_match(true)
	if not pve_ranked_matchmaking_locked:
		return
	if _get_start_error().is_empty():
		_server_start_match(SERVER_PEER_ID)


func _send_ready_state_result(
	peer_id: int,
	success: bool,
	ready: bool,
	message: String
) -> void:
	if peer_id == multiplayer.get_unique_id():
		_receive_ready_state_result(success, ready, message)
	else:
		_receive_ready_state_result.rpc_id(
			peer_id,
			success,
			ready,
			message
		)


@rpc("authority", "call_remote", "reliable")
func _receive_ready_state_result(
	success: bool,
	ready: bool,
	message: String
) -> void:
	ready_state_result.emit(success, ready, message)


func _server_select_ability(
	peer_id: int,
	ability_id: int
) -> void:
	var player := _get_player(peer_id)
	if (
		player == null
		or ranked_mode
		or (game_has_started and not tournament_halftime_active)
		or player.team not in [TEAM_RED, TEAM_BLUE]
		or ability_id < FootballPlayer.ABILITY_NONE
		or ability_id > FootballPlayer.ABILITY_COUNT
	):
		_send_ability_selection_result(
			peer_id,
			false,
			ability_id,
			(
				"Use the Ranked draft to choose an ability."
				if ranked_mode
				else "Join a team before choosing an ability."
			)
		)
		return

	var teammates := (
		red_players
		if player.team == TEAM_RED
		else blue_players
	)
	var yielded_random_cpu := false
	for teammate in teammates:
		if (
			not is_fun_mutator_enabled(FUN_DUPLICATE_ABILITIES)
			and ability_id != FootballPlayer.ABILITY_NONE
			and is_instance_valid(teammate)
			and teammate != player
			and teammate.selected_ability == ability_id
		):
			if (
				(tournament_halftime_active or singleplayer_ranked_mode)
				and teammate.cpu_controlled
				and (
					singleplayer_ranked_mode
					or _get_cpu_ability_preference(
						teammate.team,
						teammate.team_slot
					) == CPU_ABILITY_RANDOM
				)
			):
				if singleplayer_ranked_mode:
					_reassign_singleplayer_ranked_cpu_ability(
						teammate,
						ability_id,
						teammates
					)
				else:
					teammate.set_selected_ability(
						FootballPlayer.ABILITY_NONE
					)
				yielded_random_cpu = true
				continue
			var teammate_name := teammate.display_name.strip_edges()
			if teammate_name.is_empty():
				teammate_name = "A teammate"
			_send_ability_selection_result(
				peer_id,
				false,
				ability_id,
				"%s is already selected by %s."
				% [
					FootballPlayer.get_ability_name(ability_id),
					teammate_name
				]
			)
			return

	player.set_selected_ability(ability_id)
	if yielded_random_cpu and not singleplayer_ranked_mode:
		_apply_cpu_halftime_ability_preferences(
			player.team,
			teammates,
			false
		)
	if not tournament_halftime_active:
		_ready_players.erase(peer_id)
	refresh_roster()
	_send_ability_selection_result(
		peer_id,
		true,
		ability_id,
		(
			"Ability deselected."
			if ability_id == FootballPlayer.ABILITY_NONE
			else "Selected %s." % (
				FootballPlayer.get_ability_name(ability_id)
			)
		)
	)


func _reassign_singleplayer_ranked_cpu_ability(
	cpu: FootballPlayer,
	reserved_ability: int,
	teammates: Array[FootballPlayer]
) -> void:
	var used: Dictionary = {reserved_ability: true}
	for teammate: FootballPlayer in teammates:
		if teammate != cpu and teammate.selected_ability != FootballPlayer.ABILITY_NONE:
			used[teammate.selected_ability] = true
	var replacement: int = FootballPlayer.ABILITY_NONE
	for ability_id: int in range(1, FootballPlayer.ABILITY_COUNT + 1):
		if ability_id == FootballPlayer.ABILITY_META_VISION:
			continue
		if not used.has(ability_id):
			replacement = ability_id
			break
	cpu.set_selected_ability(replacement)
	var preferences: Array[int] = (
		blue_cpu_ability_preferences
		if cpu.team == TEAM_BLUE
		else red_cpu_ability_preferences
	)
	if cpu.team_slot >= 0 and cpu.team_slot < preferences.size():
		preferences[cpu.team_slot] = replacement


func _send_ability_selection_result(
	peer_id: int,
	success: bool,
	ability_id: int,
	message: String
) -> void:
	if peer_id == multiplayer.get_unique_id():
		_receive_ability_selection_result(
			success,
			ability_id,
			message
		)
	else:
		_receive_ability_selection_result.rpc_id(
			peer_id,
			success,
			ability_id,
			message
		)


@rpc("authority", "call_remote", "reliable")
func _receive_ability_selection_result(
	success: bool,
	ability_id: int,
	message: String
) -> void:
	ability_selection_result.emit(
		success,
		ability_id,
		message
	)


# ================================================================
# TEAM MANAGEMENT - SERVER ONLY
# ================================================================

func join_team(
	player: FootballPlayer,
	new_team: StringName
) -> bool:
	if not multiplayer.is_server() or player == null or ranked_draft_active:
		return false
	if (
		ladder_mode
		and not player.cpu_controlled
		and new_team in [TEAM_RED, TEAM_BLUE]
		and new_team != ladder_human_team
	):
		return false
	if (
		singleplayer_ranked_mode
		and not player.cpu_controlled
		and new_team in [TEAM_RED, TEAM_BLUE]
		and new_team != singleplayer_ranked_human_team
	):
		return false

	if new_team == TEAM_SPECTATOR:
		if (
			player.team != TEAM_SPECTATOR
			and _human_spectator_count() >= max_spectators
		):
			return false
		_remove_player_from_teams(player)
		_ready_players.erase(player.owner_peer_id)
		player.assign_team(TEAM_SPECTATOR, -1)
		player.set_selected_ability(FootballPlayer.ABILITY_NONE)
		player.set_controls_enabled(false)
		player.reset_to_position(LOBBY_PLAYER_PARK_POSITION)
		refresh_roster()
		return true

	if game_has_started:
		return false

	if new_team != TEAM_RED and new_team != TEAM_BLUE:
		return false

	_prune_team_arrays()

	if player.team == new_team:
		return true

	var target_players := (
		red_players
		if new_team == TEAM_RED
		else blue_players
	)

	if target_players.size() >= max_players_per_team:
		return false

	var free_slot := _find_free_slot(target_players)
	if free_slot == -1:
		return false

	_remove_player_from_teams(player)
	target_players.append(player)

	_ready_players.erase(player.owner_peer_id)
	player.assign_team(new_team, free_slot)
	player.set_selected_ability(FootballPlayer.ABILITY_NONE)
	player.set_controls_enabled(false)

	# Lobby selection only reserves the team slot. Keep the character parked
	# until the normal match-start reset places everyone on the field.
	player.reset_to_position(LOBBY_PLAYER_PARK_POSITION)

	refresh_roster()
	return true


func leave_team(player: FootballPlayer) -> bool:
	if (
		not multiplayer.is_server()
		or player == null
		or game_has_started
		or ranked_draft_active
	):
		return false

	_remove_player_from_teams(player)
	_ready_players.erase(player.owner_peer_id)
	player.assign_team(NO_TEAM, -1)
	player.set_selected_ability(FootballPlayer.ABILITY_NONE)
	player.set_controls_enabled(false)
	refresh_roster()
	return true


func _remove_player_from_teams(player: FootballPlayer) -> void:
	red_players.erase(player)
	blue_players.erase(player)


func _human_spectator_count() -> int:
	if players_parent == null:
		return 0
	var count: int = 0
	for child in players_parent.get_children():
		var spectator := child as FootballPlayer
		if (
			spectator != null
			and not spectator.cpu_controlled
			and spectator.team == TEAM_SPECTATOR
		):
			count += 1
	return count


func _prune_team_arrays() -> void:
	var valid_red: Array[FootballPlayer] = []
	var valid_blue: Array[FootballPlayer] = []

	for player in red_players:
		if (
			is_instance_valid(player)
			and player.get_parent() == players_parent
			and player.team == TEAM_RED
			and player not in valid_red
		):
			valid_red.append(player)

	for player in blue_players:
		if (
			is_instance_valid(player)
			and player.get_parent() == players_parent
			and player.team == TEAM_BLUE
			and player not in valid_blue
		):
			valid_blue.append(player)

	red_players = valid_red
	blue_players = valid_blue


func _find_free_slot(
	players: Array[FootballPlayer]
) -> int:
	for slot in range(max_players_per_team):
		var slot_is_used := false

		for existing_player in players:
			if (
				is_instance_valid(existing_player)
				and existing_player.team_slot == slot
			):
				slot_is_used = true
				break

		if not slot_is_used:
			return slot

	return -1


func _get_player_spawn(
	team: StringName,
	slot: int
) -> Marker2D:
	var spawn_list: Array[Marker2D]

	if team == TEAM_RED:
		spawn_list = red_player_spawns
	elif team == TEAM_BLUE:
		spawn_list = blue_player_spawns
	else:
		return null

	if slot < 0 or slot >= spawn_list.size():
		return null

	return spawn_list[slot]


# ================================================================
# SERVER-OWNED CPU PLAYER LIFECYCLE
# ================================================================

func _schedule_cpu_reconcile() -> void:
	if _cpu_reconcile_scheduled:
		return
	_cpu_reconcile_scheduled = true
	call_deferred("_reconcile_cpu_players")


func _reconcile_cpu_players() -> void:
	_cpu_reconcile_scheduled = false
	if not _can_manage_cpu_players():
		return

	_prune_team_arrays()
	_reconcile_cpu_team(
		TEAM_BLUE,
		requested_blue_cpu_count
	)
	_reconcile_cpu_team(
		TEAM_RED,
		requested_red_cpu_count
	)
	_assign_cpu_team_abilities(blue_players)
	_assign_cpu_team_abilities(red_players)
	refresh_roster()


func _can_manage_cpu_players() -> bool:
	if (
		not multiplayer.is_server()
		or players_parent == null
		or game_has_started
		or freeplay_active
	):
		return false

	var network_manager := get_parent().get_node_or_null(
		"NetworkManager"
	) as NetworkManager
	return (
		network_manager != null
		and network_manager.current_mode
		not in [
			NetworkManager.NetworkMode.NONE,
			NetworkManager.NetworkMode.FREEPLAY
		]
	)


func _reconcile_cpu_team(
	team: StringName,
	desired_cpu_count: int
) -> void:
	var team_players := (
		red_players if team == TEAM_RED else blue_players
	)
	var cpu_players: Array[FootballPlayer] = []
	for player in team_players:
		if is_instance_valid(player) and player.cpu_controlled:
			cpu_players.append(player)

	var human_count := team_players.size() - cpu_players.size()
	var cpu_target := clampi(
		desired_cpu_count,
		0,
		maxi(0, max_players_per_team - human_count)
	)
	while cpu_players.size() > cpu_target:
		var cpu: FootballPlayer = cpu_players.pop_back()
		_remove_cpu_player(cpu)

	while cpu_players.size() < cpu_target:
		var created: FootballPlayer = _spawn_cpu_for_team(team)
		if created == null:
			break
		cpu_players.append(created)


func _spawn_cpu_for_team(team: StringName) -> FootballPlayer:
	var network_manager := get_parent().get_node_or_null(
		"NetworkManager"
	) as NetworkManager
	if network_manager == null:
		return null

	var team_players := (
		red_players if team == TEAM_RED else blue_players
	)
	var free_slot := _find_free_slot(team_players)
	if free_slot < 0:
		return null

	var cpu_id := _allocate_cpu_id()
	var team_name := "Red" if team == TEAM_RED else "Blue"
	var cpu := network_manager.spawn_cpu_player(
		cpu_id,
		"%s CPU %d" % [team_name, free_slot + 1]
	)
	if cpu == null:
		return null

	cpu.cpu_controlled = true
	cpu.assign_team(team, free_slot)
	cpu.set_selected_ability(FootballPlayer.ABILITY_NONE)
	cpu.set_controls_enabled(false)
	_assign_random_cpu_quick_chat_loadout(cpu)
	team_players.append(cpu)
	_ready_players[cpu_id] = true
	_attach_cpu_controller(cpu)
	var spawn := _get_player_spawn(team, free_slot)
	if game_has_started and spawn != null:
		cpu.reset_to_position(spawn.global_position)
	else:
		cpu.reset_to_position(LOBBY_PLAYER_PARK_POSITION)
	return cpu


func _attach_cpu_controller(cpu: FootballPlayer) -> void:
	if (
		not is_instance_valid(cpu)
		or not cpu.cpu_controlled
		or cpu.has_node("CPUController")
	):
		return
	var cpu_script := load(CPU_PLAYER_AI_SCRIPT_PATH) as Script
	if cpu_script == null:
		push_error("CPU AI script could not be loaded: %s" % CPU_PLAYER_AI_SCRIPT_PATH)
		return
	var controller: Node = cpu_script.new()
	if controller == null:
		push_error("Could not create CPU player controller.")
		return
	controller.name = "CPUController"
	cpu.add_child(controller)
	controller.setup(cpu, self, ball)
	if ladder_mode and cpu.team == ladder_cpu_team:
		_apply_ladder_cpu_profiles.call_deferred()
	elif singleplayer_ranked_mode:
		_apply_singleplayer_ranked_cpu_profiles.call_deferred()


func _allocate_cpu_id() -> int:
	while players_parent.has_node(str(_next_cpu_id)):
		_next_cpu_id += 1
	var cpu_id := _next_cpu_id
	_next_cpu_id += 1
	return cpu_id


func _remove_cpu_player(cpu: FootballPlayer) -> void:
	if not is_instance_valid(cpu) or not cpu.cpu_controlled:
		return
	_remove_player_from_teams(cpu)
	_ready_players.erase(cpu.owner_peer_id)
	cpu.queue_free()


func _make_room_for_human(
	team: StringName,
	player: FootballPlayer
) -> void:
	if (
		player == null
		or player.cpu_controlled
		or player.team == team
		or team not in [TEAM_RED, TEAM_BLUE]
	):
		return

	_prune_team_arrays()
	var target_players := (
		red_players if team == TEAM_RED else blue_players
	)
	if target_players.size() < max_players_per_team:
		return

	for index in range(target_players.size() - 1, -1, -1):
		var candidate := target_players[index]
		if is_instance_valid(candidate) and candidate.cpu_controlled:
			_remove_cpu_player(candidate)
			return


# ================================================================
# ROSTER SYNCHRONIZATION
# ================================================================

func refresh_roster() -> void:
	if not multiplayer.is_server():
		return

	call_deferred("_broadcast_roster")


func sync_state_to_peer(peer_id: int) -> void:
	if not multiplayer.is_server() or peer_id <= 0:
		return

	var display_seconds := _get_display_seconds()

	_receive_score.rpc_id(
		peer_id,
		red_score,
		blue_score,
		tournament_leg_red_goals,
		tournament_leg_blue_goals,
		tournament_leg,
		tournament_mode,
		tournament_sudden_death
	)
	_receive_timer.rpc_id(
		peer_id,
		_timer_sync_serial,
		maxi(0, display_seconds),
		is_overtime
	)
	_receive_announcement.rpc_id(
		peer_id,
		_current_announcement
	)
	_receive_countdown.rpc_id(peer_id, _current_countdown)
	_receive_field_variant.rpc_id(peer_id, current_field_variant)
	_receive_team_introduction.rpc_id(
		peer_id,
		_current_introduction_team,
		_current_introduction_names
	)
	_receive_match_settings.rpc_id(
		peer_id,
		regulation_seconds,
		goals_to_win
	)
	_receive_cpu_settings.rpc_id(
		peer_id,
		requested_blue_cpu_count,
		requested_red_cpu_count
	)
	_receive_cpu_difficulty.rpc_id(peer_id, cpu_ai_level)
	_receive_ladder_state.rpc_id(peer_id, get_ladder_snapshot())
	_receive_singleplayer_ranked_state.rpc_id(
		peer_id,
		get_singleplayer_ranked_snapshot()
	)
	_receive_tournament_mode.rpc_id(peer_id, tournament_mode)
	_receive_ranked_mode.rpc_id(peer_id, ranked_mode)
	_receive_champions_league_mode.rpc_id(peer_id, champions_league_mode)
	_receive_draft_state.rpc_id(peer_id, _build_draft_snapshot(peer_id))
	_receive_fun_mutators.rpc_id(peer_id, fun_mutators)
	_receive_ranked_draft_snapshot.rpc_id(
		peer_id,
		_build_ranked_draft_snapshot(_get_player_team_for_peer(peer_id))
	)
	_receive_tournament_tiebreak_state.rpc_id(
		peer_id,
		tournament_tiebreak_phase,
		tournament_extra_time_period,
		penalty_red_score,
		penalty_blue_score,
		penalty_red_attempts,
		penalty_blue_attempts,
		penalty_turn,
		penalty_attempt_active,
		penalty_kicker_peer_id,
		penalty_goalkeeper_peer_id,
		penalty_attempt_serial
	)
	_receive_goal_replay_state.rpc_id(
		peer_id,
		goal_replay_active,
		_goal_replay_skip_votes.size(),
		_get_goal_replay_voter_ids().size(),
		goal_replay_slow_motion
	)
	_receive_goal_replay_presentation.rpc_id(
		peer_id,
		goal_replay_active,
		goal_replay_presentation
	)
	if ball != null:
		ball.sync_visual_to_peer(peer_id)
	for child in players_parent.get_children():
		var player := child as FootballPlayer
		if player != null:
			player.sync_charge_to_peer(peer_id)
			player.sync_echo_to_peer(peer_id)
	_receive_leaderboard.rpc_id(
		peer_id,
		leaderboard_snapshot
	)

	if game_has_started:
		_receive_match_started.rpc_id(peer_id)
		if (
			singleplayer_ranked_mode
			and ranked_active_match_elapsed >= RANKED_CANCEL_GRACE_SECONDS
		):
			_receive_pve_ranked_abandonment_armed.rpc_id(peer_id)
	elif match_results_available:
		_receive_match_ended.rpc_id(
			peer_id,
			last_winning_team,
			leaderboard_snapshot
		)


func _broadcast_roster() -> void:
	if not multiplayer.is_server() or players_parent == null:
		return

	_prune_team_arrays()

	var roster := _empty_roster()
	roster["host_peer_id"] = multiplayer.get_unique_id()
	var seen_peer_ids: Dictionary = {}

	for child in players_parent.get_children():
		var player := child as FootballPlayer
		if player == null or player.training_dummy:
			continue

		if seen_peer_ids.has(player.owner_peer_id):
			continue
		seen_peer_ids[player.owner_peer_id] = true

		var player_name := player.display_name
		if player_name.strip_edges().is_empty():
			player_name = "Player %d" % player.owner_peer_id

		var entry := {
			"name": player_name,
			"peer_id": player.owner_peer_id,
			"battle_pass_complete": bool(
				player.cosmetic_loadout.get(
					"battle_pass_complete",
					false
				)
			),
			"pve_ladder_champion": bool(
				player.cosmetic_loadout.get(
					"pve_ladder_champion",
					false
				)
			),
			"ability": player.selected_ability,
			"ready": (
				player.cpu_controlled
				or _ready_players.has(player.owner_peer_id)
			),
			"cpu": player.cpu_controlled,
			"team_slot": player.team_slot
		}
		if singleplayer_ranked_mode:
			# PvE Ranked party UI only: expose the already-resolved visual IDs used
			# by this FootballPlayer. This reuses the existing cosmetic system and
			# does not alter player state, matchmaking, or gameplay replication.
			entry["cosmetic_preview"] = {
				"skin_id": player.get_cosmetic_item_id(
					FootballCosmeticInventory.SLOT_PLAYER_SKIN
				),
				"skin_color_index": player.get_player_skin_color_index(),
				"frame_palette_id": player.get_cosmetic_item_id(
					FootballCosmeticInventory.SLOT_FRAME_PALETTE
				),
				"player_material_id": player.get_cosmetic_item_id(
					FootballCosmeticInventory.SLOT_PLAYER_MATERIAL
				),
				"team_primary_color_index": int(player.cosmetic_loadout.get(
					"team_primary_color_%s" % str(player.team),
					0
				))
			}
			if player.cpu_controlled:
				entry["mmr"] = maxi(0, int(player.get_meta(
					"pve_ranked_mmr",
					singleplayer_ranked_mmr
				)))
			else:
				var ranked_profile: Dictionary = _pve_ranked_player_profiles.get(
					player.owner_peer_id,
					{
						"mmr": singleplayer_ranked_mmr,
						"matches": singleplayer_ranked_matches
					}
				) as Dictionary
				entry["mmr"] = maxi(0, int(ranked_profile.get(
					"mmr",
					singleplayer_ranked_mmr
				)))

		match player.team:
			TEAM_RED:
				roster["red"].append(entry)
			TEAM_BLUE:
				roster["blue"].append(entry)
			TEAM_SPECTATOR:
				roster["spectators"].append(entry)
			_:
				roster["unassigned"].append(entry)

	_receive_roster.rpc(roster)


func _empty_roster() -> Dictionary:
	return {
		"host_peer_id": 1,
		"red": [],
		"blue": [],
		"spectators": [],
		"unassigned": []
	}


@rpc("authority", "call_local", "reliable")
func _receive_roster(roster: Dictionary) -> void:
	var red_entries: Array = roster.get("red", [])
	var blue_entries: Array = roster.get("blue", [])
	_set_large_team_presentation(
		mini(red_entries.size(), blue_entries.size())
	)

	roster_changed.emit(
		red_entries.size(),
		blue_entries.size()
	)
	roster_details_changed.emit(roster)


func _set_large_team_presentation(team_size: int) -> void:
	_large_team_team_size = maxi(0, team_size)
	_large_team_presentation_active = (
		team_size >= LARGE_TEAM_PRESENTATION_MIN_TEAM_SIZE
	)
	# 4v4 keeps the larger, more readable player/ball presentation. 5v5 and
	# 6v6 use the original 25% reduction so the extra bodies still have room.
	_large_team_entity_multiplier = (
		FIVE_PLUS_ENTITY_SCALE
		if team_size >= 5
		else FOUR_V_FOUR_ENTITY_SCALE
		if team_size == 4
		else 1.0
	)
	if ball != null:
		ball.set_large_team_size_multiplier(_large_team_entity_multiplier)
	if players_parent == null:
		return
	for child: Node in players_parent.get_children():
		var player := child as FootballPlayer
		if player == null or player.training_dummy:
			continue
		player.set_large_team_size_multiplier(_large_team_entity_multiplier)
		player.set_match_team_size(_large_team_team_size)


func _apply_large_team_scale_to_player(player: FootballPlayer) -> void:
	if player == null or player.training_dummy:
		return
	player.set_large_team_size_multiplier(_large_team_entity_multiplier)
	player.set_match_team_size(_large_team_team_size)


func _on_player_entered(node: Node) -> void:
	if node is FootballPlayer:
		var player := node as FootballPlayer
		_apply_large_team_scale_to_player(player)
		if not multiplayer.is_server():
			return
		_connect_player_learning_signal(player)
		refresh_roster()
		if ladder_mode and not player.cpu_controlled and not game_has_started:
			_refresh_ladder_party_configuration.call_deferred()
		if (
			singleplayer_ranked_mode
			and not player.cpu_controlled
			and not game_has_started
		):
			if pve_ranked_multiplayer_mode:
				_refresh_pve_ranked_party_configuration.call_deferred()
			else:
				_assign_singleplayer_ranked_human.call_deferred()


func _connect_player_learning_signal(player: FootballPlayer) -> void:
	if (
		player != null
		and not player.ability_used.is_connected(_on_player_ability_used)
	):
		player.ability_used.connect(_on_player_ability_used)


func _on_player_exiting(node: Node) -> void:
	if not multiplayer.is_server() or node is not FootballPlayer:
		return

	var player := node as FootballPlayer
	_ranked_draft_votes.erase(player.owner_peer_id)
	_ranked_draft_picks.erase(player.owner_peer_id)
	_ranked_draft_preferences.erase(player.owner_peer_id)
	_remove_player_from_teams(player)
	_ready_players.erase(player.owner_peer_id)
	refresh_roster()
	_schedule_cpu_reconcile()
	if ladder_mode and not player.cpu_controlled and not game_has_started:
		_refresh_ladder_party_configuration.call_deferred()
	if (
		singleplayer_ranked_mode
		and pve_ranked_multiplayer_mode
		and not player.cpu_controlled
		and not game_has_started
	):
		_refresh_pve_ranked_party_configuration.call_deferred()
	if goal_replay_active:
		call_deferred("_refresh_goal_replay_vote_state")
	if ranked_draft_active:
		call_deferred("_broadcast_ranked_draft_snapshot")
		_try_autocomplete_ranked_phase.call_deferred()


# ================================================================
# HOST MIGRATION RECOVERY
# ================================================================

func prepare_local_for_network_host_migration() -> void:
	# A surviving client must not be punished because somebody ELSE was the host
	# that disappeared. Also force-clear a synchronized host pause before the
	# Steam transport is rebuilt.
	if _ingame_pause_overlay != null:
		_ingame_pause_overlay.call("force_clear_network_pause")
	elif get_tree().paused:
		get_tree().paused = false
	if singleplayer_ranked_mode:
		_clear_local_pve_ranked_abandonment_pending()
	if game_has_started or goal_replay_active or tournament_halftime_active:
		_receive_match_cancelled()


func prepare_for_network_host_migration(was_match_active: bool) -> void:
	if not multiplayer.is_server():
		return
	# Live simulation is intentionally not hot-migrated. Client snapshots are
	# excellent for lobby state but not authoritative enough for a ball that may
	# be mid-collision. Safely return the remaining party to the same mode's lobby
	# without awarding a result/MMR change.
	if was_match_active:
		# prepare_local_for_network_host_migration() may already have cleared the
		# client's presentation flag before this peer was promoted to server. Set
		# it briefly so cancel_match() performs the full authoritative reset.
		if not game_has_started:
			game_has_started = true
		cancel_match()
	else:
		_ready_players.clear()
		_reset_ranked_draft_state()

	if singleplayer_ranked_mode and pve_ranked_multiplayer_mode:
		_pve_ranked_player_profiles.clear()
		var local_profile: Dictionary = _read_singleplayer_ranked_progress()
		_pve_ranked_player_profiles[multiplayer.get_unique_id()] = {
			"mmr": int(local_profile.get("mmr", PVE_RANKED_STARTING_MMR)),
			"matches": int(local_profile.get("matches", 0))
		}
		pve_ranked_matchmaking_locked = false
		singleplayer_ranked_encounter = {}

	refresh_roster()


func finish_network_host_migration_rebuild() -> void:
	if not multiplayer.is_server():
		return
	if ladder_mode:
		_refresh_ladder_party_configuration.call_deferred()
	elif singleplayer_ranked_mode and pve_ranked_multiplayer_mode:
		_refresh_pve_ranked_party_configuration.call_deferred()
	else:
		_schedule_cpu_reconcile()
	refresh_roster()


# ================================================================
# IN-GAME PAUSE / FORFEIT SAFETY
# ================================================================

func _create_ingame_pause_overlay() -> void:
	if _ingame_pause_overlay != null:
		return
	_ingame_pause_overlay = INGAME_PAUSE_OVERLAY_SCRIPT.new()
	_ingame_pause_overlay.name = "IngamePauseOverlay"
	add_child(_ingame_pause_overlay)
	_ingame_pause_overlay.call("setup", self)


func _create_draft_panel() -> void:
	if _draft_panel != null:
		return
	_draft_panel = DRAFT_PANEL_SCENE.instantiate() as ChampionsLeagueDraftPanel
	_draft_panel.name = "DraftPanel"
	_draft_panel.manager = self
	get_parent().add_child.call_deferred(_draft_panel)


func can_locally_pause_match_simulation() -> bool:
	# Solo sessions can pause locally. Online sessions are paused globally only
	# by the current server/host through the synchronized pause overlay.
	return multiplayer.get_peers().is_empty()


func can_host_pause_online_match() -> bool:
	return multiplayer.is_server() and not multiplayer.get_peers().is_empty()


func get_ranked_cancel_grace_remaining() -> float:
	return maxf(
		0.0,
		RANKED_CANCEL_GRACE_SECONDS - ranked_active_match_elapsed
	)


func ranked_cancel_grace_is_active() -> bool:
	if not (singleplayer_ranked_mode or ladder_mode or ranked_mode):
		return false
	return ranked_active_match_elapsed < RANKED_CANCEL_GRACE_SECONDS


func cancel_match_is_forfeit() -> bool:
	return (
		(singleplayer_ranked_mode or ladder_mode or ranked_mode)
		and not ranked_cancel_grace_is_active()
	)


func get_cancel_match_confirmation_copy() -> Dictionary:
	if ranked_cancel_grace_is_active():
		var seconds_left: int = maxi(
			1,
			int(ceil(get_ranked_cancel_grace_remaining()))
		)
		return {
			"title": "CANCEL MATCH?",
			"body": (
				"You are still inside the first-minute grace period. "
				+ "Cancelling now records NO ranked result and NO Ladder loss.\n\n"
				+ "Free-cancel window: %d second%s remaining."
			) % [
				seconds_left,
				"" if seconds_left == 1 else "s"
			],
			"confirm": "CANCEL MATCH"
		}

	if singleplayer_ranked_mode:
		return {
			"title": "FORFEIT RANKED MATCH?",
			"body": (
				"The first-minute grace period has ended. "
				+ "This counts as a LOSS and applies the normal MMR loss. "
				+ "Closing the game or disconnecting now also counts as an abandonment."
			),
			"confirm": "FORFEIT MATCH"
		}
	if ladder_mode:
		return {
			"title": "FORFEIT LADDER MATCH?",
			"body": (
				"The first-minute grace period has ended. "
				+ "This counts as a LOSS and resets the current 12-match Ladder run."
			),
			"confirm": "FORFEIT MATCH"
		}
	if ranked_mode:
		return {
			"title": "FORFEIT RANKED MATCH?",
			"body": (
				"The first-minute grace period has ended. "
				+ "This ends the match as a loss for the host's team."
			),
			"confirm": "FORFEIT MATCH"
		}
	return {
		"title": "CANCEL MATCH?",
		"body": "Return everyone to the pregame lobby without a match result?",
		"confirm": "CANCEL MATCH"
	}


func _get_requesting_human_team(peer_id: int) -> StringName:
	for player: FootballPlayer in blue_players:
		if (
			is_instance_valid(player)
			and not player.cpu_controlled
			and player.owner_peer_id == peer_id
		):
			return TEAM_BLUE
	for player: FootballPlayer in red_players:
		if (
			is_instance_valid(player)
			and not player.cpu_controlled
			and player.owner_peer_id == peer_id
		):
			return TEAM_RED
	return NO_TEAM


func _server_cancel_or_forfeit_match(requester_id: int) -> bool:
	if not multiplayer.is_server() or not game_has_started:
		return false
	if requester_id != SERVER_PEER_ID:
		return false

	# Keep the old no-result cancel behavior during the first 60 seconds of
	# actual live gameplay.
	if ranked_cancel_grace_is_active():
		return cancel_match()

	if singleplayer_ranked_mode:
		end_match(singleplayer_ranked_cpu_team)
		return true

	if ladder_mode:
		end_match(ladder_cpu_team)
		return true

	if ranked_mode:
		var forfeiting_team: StringName = _get_requesting_human_team(
			requester_id
		)
		if forfeiting_team == NO_TEAM:
			forfeiting_team = TEAM_BLUE
		end_match(_opponent_team(forfeiting_team))
		return true

	return cancel_match()


# ================================================================
# PVE RANKED ABANDONMENT PROTECTION
# ================================================================

func _get_local_pve_ranked_opponent_rating_snapshot() -> Dictionary:
	var prefix: String = str(singleplayer_ranked_cpu_team)
	var mmrs: Array = singleplayer_ranked_encounter.get(
		prefix + "_mmrs",
		[]
	) as Array
	var total: int = 0
	var count: int = 0
	var highest: int = -1
	for value: Variant in mmrs:
		var opponent_mmr: int = maxi(
			PVE_RANKED_MIN_MMR,
			int(value)
		)
		total += opponent_mmr
		count += 1
		highest = maxi(highest, opponent_mmr)
	if count <= 0:
		var fallback: int = get_pve_ranked_opponent_mmr(
			singleplayer_ranked_division
		)
		return {
			"average": fallback,
			"highest": fallback
		}
	return {
		"average": int(round(float(total) / float(count))),
		"highest": highest
	}


func _mark_local_pve_ranked_abandonment_pending() -> void:
	if not singleplayer_ranked_mode or cpu_training_mode:
		return
	var config := ConfigFile.new()
	if config.load(singleplayer_ranked_progress_path) != OK:
		config = ConfigFile.new()
		config.set_value("rank", "mmr", singleplayer_ranked_mmr)
		config.set_value("rank", "matches", singleplayer_ranked_matches)

	var opponent_snapshot: Dictionary = (
		_get_local_pve_ranked_opponent_rating_snapshot()
	)
	config.set_value("abandonment", "pending", true)
	config.set_value(
		"abandonment",
		"opponent_mmr",
		int(opponent_snapshot.get(
			"average",
			get_pve_ranked_opponent_mmr(singleplayer_ranked_division)
		))
	)
	config.set_value(
		"abandonment",
		"highest_opponent_mmr",
		int(opponent_snapshot.get(
			"highest",
			get_pve_ranked_opponent_mmr(singleplayer_ranked_division)
		))
	)
	config.set_value(
		"abandonment",
		"started_unix",
		int(Time.get_unix_time_from_system())
	)
	var error: Error = config.save(singleplayer_ranked_progress_path)
	if error != OK:
		push_warning(
			"Could not write PvE Ranked abandonment marker: %s"
			% error_string(error)
		)


func _clear_local_pve_ranked_abandonment_pending() -> void:
	var config := ConfigFile.new()
	if config.load(singleplayer_ranked_progress_path) != OK:
		return
	if config.has_section("abandonment"):
		config.erase_section("abandonment")
		var error: Error = config.save(singleplayer_ranked_progress_path)
		if error != OK:
			push_warning(
				"Could not clear PvE Ranked abandonment marker: %s"
				% error_string(error)
			)


func _resolve_local_pve_ranked_abandonment_if_pending() -> void:
	var config := ConfigFile.new()
	if config.load(singleplayer_ranked_progress_path) != OK:
		return
	if not bool(config.get_value("abandonment", "pending", false)):
		return

	var current_mmr: int = maxi(
		PVE_RANKED_MIN_MMR,
		int(config.get_value(
			"rank",
			"mmr",
			PVE_RANKED_STARTING_MMR
		))
	)
	var current_matches: int = maxi(
		0,
		int(config.get_value("rank", "matches", 0))
	)
	var opponent_mmr: int = maxi(
		PVE_RANKED_MIN_MMR,
		int(config.get_value(
			"abandonment",
			"opponent_mmr",
			current_mmr
		))
	)
	var highest_opponent_mmr: int = maxi(
		opponent_mmr,
		int(config.get_value(
			"abandonment",
			"highest_opponent_mmr",
			opponent_mmr
		))
	)
	var change: int = calculate_pve_ranked_mmr_change(
		current_mmr,
		opponent_mmr,
		false,
		highest_opponent_mmr
	)
	var updated_mmr: int = maxi(
		PVE_RANKED_MIN_MMR,
		current_mmr + change
	)
	config.set_value("rank", "mmr", updated_mmr)
	config.set_value("rank", "matches", current_matches + 1)
	config.erase_section("abandonment")
	var error: Error = config.save(singleplayer_ranked_progress_path)
	if error == OK:
		print(
			"[PvERanked] Applied abandonment loss: ",
			current_mmr,
			" -> ",
			updated_mmr,
			" (",
			change,
			")"
		)
	else:
		push_warning(
			"Could not save PvE Ranked abandonment result: %s"
			% error_string(error)
		)


# ================================================================
# MATCH START
# ================================================================

func request_start_match() -> void:
	if multiplayer.is_server():
		_server_start_match(multiplayer.get_unique_id())
	else:
		_request_start_match.rpc_id(SERVER_PEER_ID)


func request_cancel_match() -> void:
	if multiplayer.is_server():
		_server_cancel_or_forfeit_match(multiplayer.get_unique_id())
	else:
		_request_cancel_match.rpc_id(SERVER_PEER_ID)


func request_host_ball_reset() -> void:
	if not multiplayer.is_server():
		return
	reset_ball_by_host()


func request_skip_halftime() -> void:
	if multiplayer.is_server():
		_skip_tournament_halftime(multiplayer.get_unique_id())
	else:
		_request_skip_halftime.rpc_id(SERVER_PEER_ID)


@rpc("any_peer", "call_remote", "reliable")
func _request_skip_halftime() -> void:
	if not multiplayer.is_server():
		return
	_skip_tournament_halftime(multiplayer.get_remote_sender_id())


func _skip_tournament_halftime(requester_id: int) -> void:
	if (
		requester_id != SERVER_PEER_ID
		or not tournament_halftime_active
		or ranked_mode
	):
		return
	tournament_halftime_remaining = 0
	_halftime_generation += 1
	_complete_tournament_halftime()


func _assign_random_cpu_quick_chat_loadout(cpu: FootballPlayer) -> void:
	if cpu == null or not cpu.cpu_controlled:
		return
	var pool: Array[String] = []
	for item_id_variant: Variant in FootballCosmeticInventory.CATALOG.keys():
		var item_id: String = str(item_id_variant)
		var item: Dictionary = FootballCosmeticInventory.CATALOG[item_id] as Dictionary
		if (
			StringName(item.get("slot", &"")) == FootballCosmeticInventory.SLOT_QUICK_CHAT
			and FootballCosmeticInventory.is_catalog_item_obtainable(item)
		):
			pool.append(item_id)
	if pool.is_empty():
		return
	var loadout: Array[String] = []
	while (
		loadout.size() < FootballCosmeticInventory.QUICK_CHAT_SLOT_COUNT
		and not pool.is_empty()
	):
		var pick_index: int = _cpu_ability_rng.randi_range(0, pool.size() - 1)
		loadout.append(pool[pick_index])
		pool.remove_at(pick_index)
	cpu.cosmetic_loadout["quick_chat"] = loadout


func _reset_cpu_quick_chat_timer(first_roll: bool = false) -> void:
	var minimum_delay: float = maxf(5.0, cpu_quick_chat_midgame_min_seconds)
	var maximum_delay: float = maxf(minimum_delay, cpu_quick_chat_midgame_max_seconds)
	if first_roll:
		minimum_delay = maxf(7.0, minimum_delay * 0.65)
		maximum_delay = maxf(minimum_delay, maximum_delay * 0.85)
	_cpu_quick_chat_time_remaining = _cpu_ability_rng.randf_range(
		minimum_delay,
		maximum_delay
	)


func _update_cpu_quick_chat(delta: float) -> void:
	if cpu_training_mode or penalty_shootout_active or goal_replay_active:
		return
	_cpu_quick_chat_time_remaining -= delta
	if _cpu_quick_chat_time_remaining > 0.0:
		return
	_reset_cpu_quick_chat_timer()
	if not _cpu_quick_chat_global_cooldown_ready():
		return
	if _cpu_ability_rng.randf() > clampf(cpu_quick_chat_midgame_chance, 0.0, 1.0):
		return
	var candidates: Array[FootballPlayer] = _get_cpu_quick_chat_candidates()
	if candidates.is_empty():
		return
	var cpu: FootballPlayer = candidates[
		_cpu_ability_rng.randi_range(0, candidates.size() - 1)
	]
	_send_random_cpu_quick_chat(cpu)


func _get_cpu_quick_chat_candidates(team_filter: StringName = &"") -> Array[FootballPlayer]:
	var candidates: Array[FootballPlayer] = []
	for player: FootballPlayer in blue_players:
		if (
			is_instance_valid(player)
			and player.cpu_controlled
			and (team_filter == &"" or player.team == team_filter)
		):
			candidates.append(player)
	for player: FootballPlayer in red_players:
		if (
			is_instance_valid(player)
			and player.cpu_controlled
			and (team_filter == &"" or player.team == team_filter)
		):
			candidates.append(player)
	return candidates


func _cpu_quick_chat_global_cooldown_ready() -> bool:
	var now: float = Time.get_ticks_msec() / 1000.0
	return (
		now - _cpu_quick_chat_global_last_sent_at
		>= maxf(0.0, cpu_quick_chat_global_cooldown_seconds)
	)


func _send_random_cpu_quick_chat(
	cpu: FootballPlayer,
	bypass_global_cooldown: bool = false,
	bypass_peer_cooldown: bool = false
) -> bool:
	if (
		not game_has_started
		or cpu == null
		or not is_instance_valid(cpu)
		or not cpu.cpu_controlled
	):
		return false
	if not bypass_global_cooldown and not _cpu_quick_chat_global_cooldown_ready():
		return false
	var item_ids: Array[String] = cpu.get_quick_chat_item_ids()
	if item_ids.is_empty():
		return false
	var slot_count: int = mini(
		FootballCosmeticInventory.QUICK_CHAT_SLOT_COUNT,
		item_ids.size()
	)
	if slot_count <= 0:
		return false
	var message_index: int = _cpu_ability_rng.randi_range(0, slot_count - 1)
	var now: float = Time.get_ticks_msec() / 1000.0
	var peer_last_sent: float = float(
		_quick_chat_last_sent_at.get(cpu.owner_peer_id, -1000.0)
	)
	if (
		not bypass_peer_cooldown
		and now - peer_last_sent < maxf(0.0, quick_chat_cooldown_seconds)
	):
		return false
	if bypass_peer_cooldown:
		# Goal reactions are event-driven. Make the 75% goal roll mean an actual
		# reaction instead of silently losing it because that CPU happened to chat
		# a fraction of a second before the goal.
		_quick_chat_last_sent_at.erase(cpu.owner_peer_id)
	_server_quick_chat(cpu.owner_peer_id, message_index)
	_cpu_quick_chat_global_last_sent_at = now
	return true


func _maybe_schedule_cpu_goal_quick_chat(
	scoring_team: StringName,
	scorer_peer_id: int
) -> void:
	if cpu_training_mode:
		return
	if _cpu_ability_rng.randf() > clampf(cpu_quick_chat_goal_chance, 0.0, 1.0):
		return
	var scoring_cpus: Array[FootballPlayer] = _get_cpu_quick_chat_candidates(scoring_team)
	var conceding_team: StringName = TEAM_RED if scoring_team == TEAM_BLUE else TEAM_BLUE
	var conceding_cpus: Array[FootballPlayer] = _get_cpu_quick_chat_candidates(conceding_team)
	if scoring_cpus.is_empty() and conceding_cpus.is_empty():
		return

	# A goal reaction should read as a celebration first, not as a random player
	# from either team talking. If the scorer is a CPU, make the scorer react.
	# If a human scored, use one of their CPU teammates. The conceding side is
	# reserved mainly for the optional reply chain below.
	var chosen: FootballPlayer = null
	var scorer: FootballPlayer = _get_player(scorer_peer_id)
	if scorer != null and scorer.cpu_controlled and scoring_cpus.has(scorer):
		chosen = scorer
	elif not scoring_cpus.is_empty():
		if scorer != null:
			var nearest_distance: float = INF
			for candidate: FootballPlayer in scoring_cpus:
				var candidate_distance: float = candidate.global_position.distance_squared_to(
					scorer.global_position
				)
				if candidate_distance < nearest_distance:
					nearest_distance = candidate_distance
					chosen = candidate
		else:
			chosen = scoring_cpus[_cpu_ability_rng.randi_range(0, scoring_cpus.size() - 1)]
	elif not conceding_cpus.is_empty():
		# Human-only scoring team: still allow the CPU opponent to react so the
		# feature remains visible in 1vCPU and similar setups.
		chosen = conceding_cpus[_cpu_ability_rng.randi_range(0, conceding_cpus.size() - 1)]
	if chosen == null:
		return
	var delay: float = _cpu_ability_rng.randf_range(0.30, 0.90)
	get_tree().create_timer(delay).timeout.connect(
		_send_cpu_goal_quick_chat.bind(chosen, scoring_team, conceding_team),
		CONNECT_ONE_SHOT
	)


func _send_cpu_goal_quick_chat(
	chosen: FootballPlayer,
	scoring_team: StringName,
	conceding_team: StringName
) -> void:
	# Goal reactions are event-driven, so they are allowed to interrupt the normal
	# mid-game silence window. They still reset that window afterwards.
	if not _send_random_cpu_quick_chat(chosen, true, true):
		return
	if _cpu_ability_rng.randf() > clampf(cpu_quick_chat_goal_reply_chance, 0.0, 1.0):
		return
	var reply_candidates: Array[FootballPlayer] = []
	# Most replies come from the other side, which makes the exchange read like
	# an actual reaction instead of two teammates firing canned messages together.
	if _cpu_ability_rng.randf() < 0.68:
		reply_candidates = _get_cpu_quick_chat_candidates(conceding_team)
	else:
		reply_candidates = _get_cpu_quick_chat_candidates(scoring_team)
	if chosen != null:
		reply_candidates.erase(chosen)
	if reply_candidates.is_empty():
		for cpu: FootballPlayer in _get_cpu_quick_chat_candidates():
			if cpu != chosen:
				reply_candidates.append(cpu)
	if reply_candidates.is_empty():
		return
	var reply_cpu: FootballPlayer = reply_candidates[
		_cpu_ability_rng.randi_range(0, reply_candidates.size() - 1)
	]
	var reply_delay: float = _cpu_ability_rng.randf_range(1.15, 2.25)
	get_tree().create_timer(reply_delay).timeout.connect(
		_send_random_cpu_quick_chat.bind(reply_cpu, true, true),
		CONNECT_ONE_SHOT
	)


func request_quick_chat(message_index: int) -> void:
	if multiplayer.is_server():
		_server_quick_chat(multiplayer.get_unique_id(), message_index)
	else:
		_request_quick_chat.rpc_id(SERVER_PEER_ID, message_index)


@rpc("any_peer", "call_remote", "reliable")
func _request_quick_chat(message_index: int) -> void:
	if not multiplayer.is_server():
		return
	_server_quick_chat(
		multiplayer.get_remote_sender_id(),
		message_index
	)


func _server_quick_chat(peer_id: int, message_index: int) -> void:
	if (
		not game_has_started
		or message_index < 0
		or message_index >= FootballCosmeticInventory.QUICK_CHAT_SLOT_COUNT
	):
		return
	var player := _get_player(peer_id)
	if (
		player == null
		or player.team not in [TEAM_RED, TEAM_BLUE]
	):
		return
	var now := Time.get_ticks_msec() / 1000.0
	var last_sent := float(_quick_chat_last_sent_at.get(peer_id, -1000.0))
	if now - last_sent < maxf(0.0, quick_chat_cooldown_seconds):
		return
	_quick_chat_last_sent_at[peer_id] = now
	var message: String = _get_quick_chat_message_for_peer(
		player,
		message_index
	)
	if message.is_empty():
		return
	_receive_quick_chat.rpc(
		peer_id,
		message,
		maxf(0.5, quick_chat_bubble_seconds)
	)


func _get_quick_chat_message_for_peer(
	player: FootballPlayer,
	message_index: int
) -> String:
	if player != null:
		var item_ids: Array[String] = player.get_quick_chat_item_ids()
		if message_index >= 0 and message_index < item_ids.size():
			var payload: String = FootballCosmeticInventory.get_quick_chat_payload(
				item_ids[message_index]
			)
			if not payload.is_empty():
				return payload
	if message_index >= 0 and message_index < quick_chat_messages.size():
		return quick_chat_messages[message_index]
	return ""


@rpc("authority", "call_local", "reliable")
func _receive_quick_chat(
	peer_id: int,
	message: String,
	duration: float
) -> void:
	var player := _get_player(peer_id)
	if player != null:
		player.show_quick_chat(message, duration)


func reset_ball_by_host() -> bool:
	if (
		not multiplayer.is_server()
		or not game_has_started
		or freeplay_active
		or ball == null
		or ball_spawn == null
	):
		return false

	_active_shot.clear()
	_pending_pass.clear()
	_cpu_pass_intentions.clear()
	_cpu_ball_commitments.clear()
	_cpu_tactical_intentions.clear()
	_cpu_combination_plans.clear()
	_reset_cpu_possession_state()
	_save_check_generation += 1
	ball.reset_ball(ball_spawn.global_position)
	return true


@rpc("any_peer", "call_remote", "reliable")
func _request_cancel_match() -> void:
	if not multiplayer.is_server():
		return

	# Match-wide cancel/forfeit remains a host control. Ranked modes route
	# through the forfeit path so this can never erase a pending loss.
	var sender: int = multiplayer.get_remote_sender_id()
	if sender != SERVER_PEER_ID:
		return

	_server_cancel_or_forfeit_match(sender)


@rpc("any_peer", "call_remote", "reliable")
func _request_start_match() -> void:
	if not multiplayer.is_server():
		return

	_server_start_match(multiplayer.get_remote_sender_id())


func _server_start_match(requester_id: int) -> void:
	if not multiplayer.is_server():
		return

	if requester_id != SERVER_PEER_ID:
		_send_match_start_result(
			requester_id,
			false,
			"Only the host can start the match."
		)
		return

	var validation_error := _get_start_error()
	if not validation_error.is_empty():
		_send_match_start_result(
			requester_id,
			false,
			validation_error
		)
		return

	if ranked_mode and not _ranked_initial_draft_complete:
		_start_ranked_draft(RANKED_STAGE_GAME_ONE)
		_send_match_start_result(
			requester_id,
			true,
			"Ranked draft started."
		)
		return
	if champions_league_mode and not _draft_initial_complete:
		if not _draft_matchup_introduction_complete:
			_start_draft_matchup_introduction()
			_send_match_start_result(
				requester_id,
				true,
				"Matchup presentation started."
			)
			return
		_start_draft_phase(DRAFT_STAGE_LEG_ONE)
		_send_match_start_result(
			requester_id,
			true,
			"Draft started. Pick one of your five cards."
		)
		return

	var started := start_match()
	_send_match_start_result(
		requester_id,
		started,
		"Match started." if started
		else "Match could not start."
	)


func _send_match_start_result(
	peer_id: int,
	success: bool,
	message: String
) -> void:
	if peer_id == multiplayer.get_unique_id():
		_receive_match_start_result(success, message)
	else:
		_receive_match_start_result.rpc_id(
			peer_id,
			success,
			message
		)


@rpc("authority", "call_remote", "reliable")
func _receive_match_start_result(
	success: bool,
	message: String
) -> void:
	match_start_result.emit(success, message)


func _get_start_error() -> String:
	_prune_team_arrays()

	if game_has_started:
		return "The match has already started."

	if red_players.size() < min_players_per_team:
		return "Red needs at least one player."

	if blue_players.size() < min_players_per_team:
		return "Blue needs at least one player."

	for player in red_players:
		if (
			not player.cpu_controlled
			and not _ready_players.has(player.owner_peer_id)
		):
			return "Every player must ready up before the match starts."

	for player in blue_players:
		if (
			not player.cpu_controlled
			and not _ready_players.has(player.owner_peer_id)
		):
			return "Every player must ready up before the match starts."

	if red_player_spawns.size() < max_players_per_team:
		return "Not enough Red spawn positions are assigned."

	if blue_player_spawns.size() < max_players_per_team:
		return "Not enough Blue spawn positions are assigned."

	if ball == null or ball_spawn == null:
		return "Ball or BallSpawn is not assigned."

	return ""


# ================================================================
# HOST MATCH SETTINGS
# ================================================================

static func _default_fun_mutators() -> Dictionary:
	return {
		FUN_LOW_FRICTION: false,
		FUN_HEAVY_BALL: false,
		FUN_SMALL_GOALS: false,
		FUN_NO_COOLDOWNS: false,
		FUN_FASTER_BALL: false,
		FUN_NO_WALLS: false,
		FUN_ABILITY_DRAFT: false,
		FUN_DUPLICATE_ABILITIES: false,
		FUN_ROTATING_LOADOUTS: false,
		FUN_DICTATOR_MBAPPE: false,
		FUN_SATORU_GOJO: false,
		FUN_NEYMAR_JR: false,
		FUN_ERLING_HAALAND: false,
		FUN_MANUEL_NEUER: false,
	}


func get_fun_mutators() -> Dictionary:
	return fun_mutators.duplicate(true)


func is_fun_mutator_enabled(mutator_id: StringName) -> bool:
	return not ranked_mode and bool(fun_mutators.get(mutator_id, false))


func update_fun_mutators(new_settings: Dictionary) -> bool:
	if not multiplayer.is_server() or game_has_started:
		return false
	var sanitized: Dictionary = _sanitize_fun_mutators(new_settings)
	if ranked_mode:
		sanitized = _default_fun_mutators()
	_receive_fun_mutators.rpc(sanitized)
	return true


func _sanitize_fun_mutators(source: Dictionary) -> Dictionary:
	var sanitized: Dictionary = _default_fun_mutators()
	for key_variant: Variant in sanitized.keys():
		var key := StringName(key_variant)
		sanitized[key] = bool(source.get(key, false))
	return sanitized


@rpc("authority", "call_local", "reliable")
func _receive_fun_mutators(settings: Dictionary) -> void:
	fun_mutators = _sanitize_fun_mutators(settings)
	if ranked_mode:
		fun_mutators = _default_fun_mutators()
	fun_mutators_changed.emit(fun_mutators.duplicate(true))


func update_match_settings(
	new_regulation_seconds: float,
	new_goals_to_win: int
) -> bool:
	if not multiplayer.is_server() or game_has_started:
		return false

	regulation_seconds = clampf(
		new_regulation_seconds,
		30.0,
		3600.0
	)
	goals_to_win = clampi(new_goals_to_win, 1, 99)
	regulation_time_remaining = regulation_seconds
	overtime_elapsed = 0.0
	is_overtime = false

	_receive_match_settings.rpc(
		regulation_seconds,
		goals_to_win
	)
	_broadcast_timer()
	return true


func update_tournament_mode(enabled: bool) -> bool:
	if not multiplayer.is_server() or game_has_started:
		return false
	tournament_mode = enabled
	if champions_league_mode and not enabled:
		champions_league_mode = false
		regulation_seconds = _default_regulation_seconds
		regulation_time_remaining = regulation_seconds
		tournament_halftime_seconds = 30.0
		fun_mutators[FUN_ABILITY_DRAFT] = false
		_receive_champions_league_mode.rpc(false)
		_receive_match_settings.rpc(regulation_seconds, goals_to_win)
		_receive_fun_mutators.rpc(fun_mutators)
	if ranked_mode:
		ranked_mode = false
		_receive_ranked_mode.rpc(false)
	_receive_tournament_mode.rpc(tournament_mode)
	_broadcast_score()
	return true


@rpc("authority", "call_local", "reliable")
func _receive_tournament_mode(enabled: bool) -> void:
	tournament_mode = enabled
	tournament_mode_changed.emit(tournament_mode)


func update_ranked_mode(enabled: bool) -> bool:
	# Compatibility for older UI/scripts: the removed protect/ban/lockout mode
	# now resolves to the supported card Draft instead of activating ranked_mode.
	return configure_draft_session(enabled)


@rpc("authority", "call_local", "reliable")
func _receive_ranked_mode(enabled: bool) -> void:
	ranked_mode = enabled
	ranked_mode_changed.emit(ranked_mode)


func update_champions_league_mode(enabled: bool) -> bool:
	return configure_draft_session(enabled)


func configure_draft_session(enabled: bool) -> bool:
	if not multiplayer.is_server() or game_has_started:
		return false
	if ladder_mode and enabled:
		return false
	champions_league_mode = enabled
	ranked_mode = false
	_reset_ranked_draft_state()
	_ready_players.clear()
	if enabled:
		tournament_mode = true
		regulation_seconds = 180.0
		regulation_time_remaining = regulation_seconds
		tournament_halftime_seconds = float(DRAFT_PICK_SECONDS)
		fun_mutators = _default_fun_mutators()
		_reset_draft_state(true)
		_receive_match_settings.rpc(regulation_seconds, goals_to_win)
		_receive_fun_mutators.rpc(fun_mutators)
	else:
		_reset_draft_state(true)
		for player: FootballPlayer in _get_draft_players():
			player.clear_draft_perk()
		_clear_all_selected_abilities()
		tournament_mode = _default_tournament_mode
		regulation_seconds = _default_regulation_seconds
		regulation_time_remaining = regulation_seconds
		tournament_halftime_seconds = 30.0
		_receive_match_settings.rpc(regulation_seconds, goals_to_win)
	_receive_ranked_mode.rpc(false)
	_receive_tournament_mode.rpc(tournament_mode)
	_receive_champions_league_mode.rpc(champions_league_mode)
	_broadcast_timer()
	_broadcast_score()
	refresh_roster()
	return true


@rpc("authority", "call_local", "reliable")
func _receive_champions_league_mode(enabled: bool) -> void:
	champions_league_mode = enabled
	champions_league_mode_changed.emit(champions_league_mode)


func request_draft_pick(ability_id: int) -> void:
	if multiplayer.is_server():
		_server_accept_draft_pick(multiplayer.get_unique_id(), ability_id)
	else:
		_request_draft_pick.rpc_id(SERVER_PEER_ID, ability_id)


@rpc("any_peer", "call_remote", "reliable")
func _request_draft_pick(ability_id: int) -> void:
	if multiplayer.is_server():
		_server_accept_draft_pick(multiplayer.get_remote_sender_id(), ability_id)


func _server_accept_draft_pick(peer_id: int, ability_id: int) -> bool:
	var active_picks: Dictionary = draft_perk_picks if draft_kind == DRAFT_KIND_PERK else draft_picks
	if not multiplayer.is_server() or not draft_active or active_picks.has(peer_id):
		return false
	var player := _get_player(peer_id)
	if player != null and player.is_prestige_boss():
		return false
	var hand: Array = draft_hands.get(peer_id, []) as Array
	if player == null or ability_id not in hand:
		return false
	if draft_kind == DRAFT_KIND_PERK:
		if draft_stage == DRAFT_STAGE_LEG_TWO and ability_id == int(draft_leg_one_perks.get(peer_id, -1)):
			return false
		draft_perk_picks[peer_id] = ability_id
		player.set_draft_perk(ability_id, get_draft_perk_definition(ability_id))
	else:
		if draft_stage == DRAFT_STAGE_LEG_TWO and ability_id == int(
			draft_leg_one_picks.get(peer_id, FootballPlayer.ABILITY_NONE)
		):
			return false
		draft_picks[peer_id] = ability_id
		player.set_selected_ability(ability_id)
	_broadcast_draft_state()
	if _draft_every_player_picked():
		_finish_draft_phase.call_deferred(_draft_generation)
	return true


func _start_draft_phase(
	stage: StringName,
	kind: StringName = DRAFT_KIND_ABILITY
) -> void:
	if not multiplayer.is_server() or not champions_league_mode:
		return
	_draft_generation += 1
	var generation := _draft_generation
	draft_active = true
	draft_review_active = false
	draft_stage = stage
	draft_kind = kind
	draft_seconds_remaining = DRAFT_PICK_SECONDS
	draft_hands.clear()
	if kind == DRAFT_KIND_PERK:
		draft_perk_picks.clear()
	else:
		draft_picks.clear()
	if stage == DRAFT_STAGE_LEG_ONE:
		draft_match_seed = int(Time.get_unix_time_from_system()) ^ Time.get_ticks_msec()
	for player: FootballPlayer in _get_draft_players():
		if player.is_prestige_boss():
			draft_hands[player.owner_peer_id] = []
			if kind == DRAFT_KIND_PERK:
				player.clear_draft_perk()
				draft_perk_picks[player.owner_peer_id] = 0
			else:
				draft_picks[player.owner_peer_id] = player.selected_ability
			continue
		# PvE Ranked football stars keep their recognizable ability pool instead of
		# drawing a generic five-card hand. Most drafts retain their signature kit,
		# but each elite independently has a 40% chance to switch to another ability
		# that already belongs to that footballer's existing profile.
		if _pve_ranked_elite_cpu_keeps_ability(player, kind):
			draft_hands[player.owner_peer_id] = []
			var signature_ability: int = int(player.get_meta(
				"pve_ranked_signature_ability",
				player.selected_ability
			))
			var elite_draft_ability: int = _roll_pve_ranked_elite_draft_ability(
				player,
				signature_ability
			)
			player.set_selected_ability(elite_draft_ability)
			draft_picks[player.owner_peer_id] = elite_draft_ability
			continue
		draft_hands[player.owner_peer_id] = _build_draft_hand(player.owner_peer_id, stage, kind)
	for player: FootballPlayer in _get_draft_players():
		if not player.cpu_controlled:
			continue
		var cpu_hand: Array = draft_hands.get(player.owner_peer_id, []) as Array
		if not cpu_hand.is_empty():
			_server_accept_draft_pick(
				player.owner_peer_id,
				_pick_random_draft_card(cpu_hand)
			)
	_broadcast_draft_state()
	if _draft_every_player_picked():
		_finish_draft_phase.call_deferred(generation)
	else:
		_run_draft_timer(generation)


func _pve_ranked_elite_cpu_keeps_ability(
	player: FootballPlayer,
	kind: StringName
) -> bool:
	return (
		singleplayer_ranked_mode
		and kind == DRAFT_KIND_ABILITY
		and player != null
		and player.cpu_controlled
		and _get_singleplayer_ranked_footballer_role(player.display_name) != &""
	)


func _roll_pve_ranked_elite_draft_ability(
	player: FootballPlayer,
	signature_ability: int
) -> int:
	if player == null:
		return signature_ability
	var alternatives: Array[int] = []
	for ability_id: int in _get_singleplayer_ranked_footballer_ability_pool(
		player.display_name
	):
		if (
			ability_id == signature_ability
			or ability_id == FootballPlayer.ABILITY_NONE
			or ability_id == FootballPlayer.ABILITY_META_VISION
			or alternatives.has(ability_id)
		):
			continue
		alternatives.append(ability_id)
	if (
		alternatives.is_empty()
		or _cpu_ability_rng.randf() >= PVE_RANKED_ELITE_DRAFT_ABILITY_CHANGE_CHANCE
	):
		return signature_ability
	return alternatives[_cpu_ability_rng.randi_range(0, alternatives.size() - 1)]


func _run_draft_timer(generation: int) -> void:
	while generation == _draft_generation and draft_active and draft_seconds_remaining > 0:
		await get_tree().create_timer(1.0).timeout
		if generation != _draft_generation or not draft_active:
			return
		draft_seconds_remaining -= 1
		_broadcast_draft_state()
	_finish_draft_phase(generation)


func _finish_draft_phase(generation: int) -> void:
	if generation != _draft_generation or not draft_active or draft_review_active:
		return
	var active_picks: Dictionary = draft_perk_picks if draft_kind == DRAFT_KIND_PERK else draft_picks
	for player: FootballPlayer in _get_draft_players():
		if active_picks.has(player.owner_peer_id):
			continue
		var hand: Array = draft_hands.get(player.owner_peer_id, []) as Array
		if not hand.is_empty():
			var random_pick: int = _pick_random_draft_card(hand)
			active_picks[player.owner_peer_id] = random_pick
			if draft_kind == DRAFT_KIND_PERK:
				player.set_draft_perk(
					random_pick,
					get_draft_perk_definition(random_pick)
				)
			else:
				player.set_selected_ability(random_pick)
	if draft_kind == DRAFT_KIND_PERK and draft_stage == DRAFT_STAGE_LEG_ONE:
		draft_leg_one_perks = draft_perk_picks.duplicate(true)
	elif draft_kind == DRAFT_KIND_ABILITY and draft_stage == DRAFT_STAGE_LEG_ONE:
		draft_leg_one_picks = draft_picks.duplicate(true)
	var completed_stage := draft_stage
	var completed_kind := draft_kind
	if completed_kind == DRAFT_KIND_PERK:
		_start_draft_review(completed_stage)
		return
	draft_active = false
	draft_seconds_remaining = 0
	_broadcast_draft_state()
	draft_stage = DRAFT_STAGE_NONE
	_start_draft_phase.call_deferred(completed_stage, DRAFT_KIND_PERK)


func _start_draft_review(completed_stage: StringName) -> void:
	if not multiplayer.is_server() or not champions_league_mode:
		return
	_draft_generation += 1
	var generation := _draft_generation
	draft_active = true
	draft_review_active = true
	draft_stage = completed_stage
	draft_kind = DRAFT_KIND_PERK
	draft_seconds_remaining = DRAFT_REVIEW_SECONDS
	_broadcast_draft_state()
	_run_draft_review(generation, completed_stage)


func _run_draft_review(generation: int, completed_stage: StringName) -> void:
	while (
		generation == _draft_generation
		and draft_active
		and draft_review_active
		and draft_seconds_remaining > 0
	):
		await get_tree().create_timer(1.0).timeout
		if (
			generation != _draft_generation
			or not draft_active
			or not draft_review_active
		):
			return
		draft_seconds_remaining -= 1
		_broadcast_draft_state()
	if (
		generation != _draft_generation
		or not draft_active
		or not draft_review_active
	):
		return
	draft_active = false
	draft_review_active = false
	draft_seconds_remaining = 0
	_broadcast_draft_state()
	draft_stage = DRAFT_STAGE_NONE
	if completed_stage == DRAFT_STAGE_LEG_ONE:
		_draft_initial_complete = true
		start_match()
	else:
		_begin_tournament_leg_two()


func _pick_random_draft_card(hand: Array) -> int:
	if hand.is_empty():
		return -1
	return int(hand[_cpu_ability_rng.randi_range(0, hand.size() - 1)])


func _build_draft_hand(
	peer_id: int,
	stage: StringName,
	kind: StringName = DRAFT_KIND_ABILITY
) -> Array[int]:
	var candidates: Array[int] = []
	var ability_upgrade_candidates: Array[int] = []
	if kind == DRAFT_KIND_PERK:
		var drafted_ability := int(
			draft_picks.get(
				peer_id,
				draft_leg_one_picks.get(peer_id, FootballPlayer.ABILITY_NONE)
			)
		)
		for perk: Dictionary in DRAFT_PERKS:
			var required_ability := int(perk.get("ability", -1))
			if required_ability >= 0 and required_ability != drafted_ability:
				continue
			var supported_abilities: Array = perk.get("abilities", []) as Array
			if (
				not supported_abilities.is_empty()
				and not supported_abilities.has(drafted_ability)
			):
				continue
			var perk_id := int(perk.get("id", 0))
			candidates.append(perk_id)
			if required_ability >= 0 or not supported_abilities.is_empty():
				ability_upgrade_candidates.append(perk_id)
	else:
		candidates = DRAFT_SEASONAL_POOL.duplicate()
		var draft_player := _get_player(peer_id)
		if draft_player != null and draft_player.cpu_controlled:
			candidates.erase(FootballPlayer.ABILITY_META_VISION)
	if stage == DRAFT_STAGE_LEG_TWO:
		var locked_card := int(
			draft_leg_one_perks.get(peer_id, -1)
			if kind == DRAFT_KIND_PERK
			else draft_leg_one_picks.get(peer_id, -1)
		)
		candidates.erase(locked_card)
		ability_upgrade_candidates.erase(locked_card)
	var rng := RandomNumberGenerator.new()
	rng.seed = (
		int(draft_match_seed)
		^ (peer_id * 1103515245)
		^ (0x5f3759df if stage == DRAFT_STAGE_LEG_TWO else 0x13579bdf)
		^ (0x2468ace if kind == DRAFT_KIND_PERK else 0)
	)
	for index in range(candidates.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var value := candidates[index]
		candidates[index] = candidates[swap_index]
		candidates[swap_index] = value
	var result: Array[int] = []
	for index in range(mini(DRAFT_CARD_COUNT, candidates.size())):
		result.append(candidates[index])

	# Ability-specific perks used to be diluted by roughly forty generic perks,
	# making upgrades such as Magnus Overload or Tap Cannon almost invisible in
	# normal play. Keep the existing seeded shuffle, but guarantee one compatible
	# ability upgrade whenever at least one is still available for this leg.
	if kind == DRAFT_KIND_PERK and not ability_upgrade_candidates.is_empty():
		var upgrade_already_visible := false
		for perk_id: int in result:
			if ability_upgrade_candidates.has(perk_id):
				upgrade_already_visible = true
				break
		if not upgrade_already_visible and not result.is_empty():
			for perk_id: int in candidates:
				if ability_upgrade_candidates.has(perk_id):
					result[result.size() - 1] = perk_id
					break
	return result


func _get_draft_players() -> Array[FootballPlayer]:
	var result: Array[FootballPlayer] = []
	for player: FootballPlayer in blue_players + red_players:
		if is_instance_valid(player) and player.team in [TEAM_BLUE, TEAM_RED]:
			result.append(player)
	return result


func _draft_every_player_picked() -> bool:
	var players := _get_draft_players()
	var active_picks: Dictionary = draft_perk_picks if draft_kind == DRAFT_KIND_PERK else draft_picks
	if players.is_empty():
		return false
	for player: FootballPlayer in players:
		if player.is_prestige_boss():
			continue
		if not active_picks.has(player.owner_peer_id):
			return false
	return true


func _build_draft_snapshot(viewer_peer_id: int) -> Dictionary:
	var viewer := _get_player(viewer_peer_id)
	var viewer_team: StringName = viewer.team if viewer != null else NO_TEAM
	var visible_picks: Array[Dictionary] = []
	var active_picks: Dictionary = draft_perk_picks if draft_kind == DRAFT_KIND_PERK else draft_picks
	for player: FootballPlayer in _get_draft_players():
		var picked: bool = active_picks.has(player.owner_peer_id)
		visible_picks.append({
			"peer_id": player.owner_peer_id,
			"name": player.display_name,
			"team": player.team,
			"picked": picked,
			"ability": int(active_picks.get(player.owner_peer_id, -1))
				if picked and player.team == viewer_team else -1,
		})
	return {
		"enabled": champions_league_mode,
		"active": draft_active,
		"review": draft_review_active,
		"team": viewer_team,
		"stage": draft_stage,
		"kind": draft_kind,
		"seconds": draft_seconds_remaining,
		"hand": (draft_hands.get(viewer_peer_id, []) as Array).duplicate(),
		"selected": int(active_picks.get(viewer_peer_id, -1)),
		"ability_pick": int(draft_picks.get(viewer_peer_id, -1)),
		"perk_pick": int(draft_perk_picks.get(viewer_peer_id, -1)),
		"leg_one_locked": int(
			draft_leg_one_perks.get(viewer_peer_id, -1)
			if draft_kind == DRAFT_KIND_PERK
			else draft_leg_one_picks.get(viewer_peer_id, -1)
		),
		"picks": visible_picks,
	}


func _broadcast_draft_state() -> void:
	if not multiplayer.is_server():
		return
	_receive_draft_state(_build_draft_snapshot(multiplayer.get_unique_id()))
	for peer_id: int in multiplayer.get_peers():
		_receive_draft_state.rpc_id(peer_id, _build_draft_snapshot(peer_id))


@rpc("authority", "call_remote", "reliable")
func _receive_draft_state(snapshot: Dictionary) -> void:
	draft_active = bool(snapshot.get("active", false))
	draft_review_active = bool(snapshot.get("review", false))
	draft_stage = StringName(snapshot.get("stage", DRAFT_STAGE_NONE))
	draft_kind = StringName(snapshot.get("kind", DRAFT_KIND_ABILITY))
	draft_seconds_remaining = int(snapshot.get("seconds", 0))
	draft_state_changed.emit(snapshot)


func _reset_draft_state(clear_locked: bool = false) -> void:
	_draft_generation += 1
	draft_active = false
	draft_review_active = false
	draft_stage = DRAFT_STAGE_NONE
	draft_kind = DRAFT_KIND_ABILITY
	draft_seconds_remaining = 0
	draft_hands.clear()
	draft_picks.clear()
	draft_perk_picks.clear()
	_draft_initial_complete = false
	_draft_matchup_introduction_complete = false
	_draft_matchup_introduction_pending = false
	_team_introduction_skip_requested = false
	if clear_locked:
		draft_leg_one_picks.clear()
		draft_leg_one_perks.clear()


static func get_draft_perk_definition(perk_id: int) -> Dictionary:
	for perk: Dictionary in DRAFT_PERKS:
		if int(perk.get("id", 0)) == perk_id:
			return perk.duplicate(true)
	return {}


func get_draft_wins_snapshot() -> Dictionary:
	return draft_wins.duplicate(true)


func _load_draft_wins() -> void:
	var config := ConfigFile.new()
	if config.load(DRAFT_SAVE_PATH) == OK:
		for scope: String in ["1v1", "2v2", "4v4", "5v5", "6v6", "overall"]:
			draft_wins[scope] = maxi(0, int(config.get_value("wins", scope, 0)))
	draft_wins_changed.emit(get_draft_wins_snapshot())


func _record_local_draft_win(winning_team: StringName, entries: Array) -> void:
	if not champions_league_mode or winning_team == NO_TEAM:
		return
	var local_peer_id := multiplayer.get_unique_id()
	var local_won := false
	var red_count := 0
	var blue_count := 0
	for value: Variant in entries:
		if value is not Dictionary:
			continue
		var entry := value as Dictionary
		var team := StringName(entry.get("team", NO_TEAM))
		if team == TEAM_RED:
			red_count += 1
		elif team == TEAM_BLUE:
			blue_count += 1
		if int(entry.get("peer_id", 0)) == local_peer_id and team == winning_team:
			local_won = true
	if not local_won:
		return
	var team_size := maxi(red_count, blue_count)
	var scope := (
		"1v1"
		if team_size <= 1
		else "2v2"
		if team_size <= 2
		else "4v4"
		if team_size <= 4
		else "5v5"
		if team_size <= 5
		else "6v6"
	)
	draft_wins[scope] = int(draft_wins.get(scope, 0)) + 1
	draft_wins["overall"] = int(draft_wins.get("overall", 0)) + 1
	var config := ConfigFile.new()
	for key: String in ["1v1", "2v2", "4v4", "5v5", "6v6", "overall"]:
		config.set_value("wins", key, int(draft_wins.get(key, 0)))
	config.save(DRAFT_SAVE_PATH)
	draft_wins_changed.emit(get_draft_wins_snapshot())


func request_ranked_draft_choice(ability_id: int) -> void:
	if multiplayer.is_server():
		_server_ranked_draft_choice(multiplayer.get_unique_id(), ability_id)
	else:
		_request_ranked_draft_choice.rpc_id(SERVER_PEER_ID, ability_id)


@rpc("any_peer", "call_remote", "reliable")
func _request_ranked_draft_choice(ability_id: int) -> void:
	if multiplayer.is_server():
		_server_ranked_draft_choice(
			multiplayer.get_remote_sender_id(),
			ability_id
		)


func _server_ranked_draft_choice(peer_id: int, ability_id: int) -> void:
	if not multiplayer.is_server() or not ranked_draft_active:
		_send_ability_selection_result(
			peer_id, false, ability_id, "The Ranked draft is not active."
		)
		return
	var player := _get_player(peer_id)
	if player == null or player.cpu_controlled or player.team not in [TEAM_BLUE, TEAM_RED]:
		_send_ability_selection_result(
			peer_id, false, ability_id, "Only active team players can vote or pick."
		)
		return
	var accepted := false
	var message := ""
	if ranked_draft_phase == RANKED_DRAFT_PREFERENCE:
		accepted = _store_ranked_preference(player, ability_id)
		message = (
			"Preferred ability shared with your team. This is not your final pick."
			if accepted
			else "That ability is unavailable for this game."
		)
	elif ranked_draft_phase == RANKED_DRAFT_PICK:
		accepted = _store_ranked_pick(player, ability_id)
		message = (
			"Ranked ability locked."
			if accepted
			else "That ability is banned, locked, or already chosen by a teammate."
		)
	elif player.team == ranked_draft_turn_team:
		accepted = _ranked_vote_is_legal(player.team, ranked_draft_phase, ability_id)
		if accepted:
			_ranked_draft_votes[peer_id] = ability_id
		message = "Vote recorded." if accepted else "That vote is not legal this round."
	else:
		message = "The other team is voting now."
	_send_ability_selection_result(peer_id, accepted, ability_id, message)
	_broadcast_ranked_draft_snapshot()
	if accepted:
		_try_autocomplete_ranked_phase.call_deferred()


func _start_ranked_draft(stage: StringName) -> void:
	if not multiplayer.is_server() or not ranked_mode or ranked_draft_active:
		return
	_ranked_draft_generation += 1
	var generation := _ranked_draft_generation
	ranked_draft_active = true
	ranked_draft_stage = stage
	_ranked_draft_first_team = (
		TEAM_BLUE if _cpu_ability_rng.randi_range(0, 1) == 0 else TEAM_RED
	)
	ranked_protected_abilities = {TEAM_BLUE: FootballPlayer.ABILITY_NONE, TEAM_RED: FootballPlayer.ABILITY_NONE}
	ranked_banned_abilities = {TEAM_BLUE: FootballPlayer.ABILITY_NONE, TEAM_RED: FootballPlayer.ABILITY_NONE}
	_ranked_draft_preferences.clear()
	_ranked_draft_votes.clear()
	_ranked_draft_picks.clear()
	_clear_all_selected_abilities()
	refresh_roster()
	_begin_ranked_draft_transition(
		generation,
		"TEAM INTENTIONS",
		"Show teammates what you would like to play. This does not lock your final choice.",
		RANKED_DRAFT_PREFERENCE,
		NO_TEAM
	)


func _begin_ranked_draft_transition(
	generation: int,
	title: String,
	subtitle: String,
	next_phase: StringName,
	next_team: StringName
) -> void:
	if generation != _ranked_draft_generation or not ranked_draft_active:
		return
	_ranked_draft_phase_serial += 1
	var phase_serial := _ranked_draft_phase_serial
	ranked_draft_phase = RANKED_DRAFT_TRANSITION
	ranked_draft_turn_team = NO_TEAM
	ranked_draft_transition_title = title
	ranked_draft_transition_subtitle = subtitle
	_ranked_draft_next_phase = next_phase
	_ranked_draft_next_team = next_team
	ranked_draft_seconds_remaining = maxi(0, ranked_transition_seconds)
	_broadcast_ranked_draft_snapshot()
	if ranked_draft_seconds_remaining <= 0:
		_begin_ranked_draft_phase(generation, next_phase, next_team)
		return
	_run_ranked_draft_transition(generation, phase_serial)


func _run_ranked_draft_transition(
	generation: int,
	phase_serial: int
) -> void:
	while (
		generation == _ranked_draft_generation
		and phase_serial == _ranked_draft_phase_serial
		and ranked_draft_active
		and ranked_draft_phase == RANKED_DRAFT_TRANSITION
		and ranked_draft_seconds_remaining > 0
	):
		await get_tree().create_timer(1.0).timeout
		if (
			generation != _ranked_draft_generation
			or phase_serial != _ranked_draft_phase_serial
			or not ranked_draft_active
		):
			return
		ranked_draft_seconds_remaining = maxi(0, ranked_draft_seconds_remaining - 1)
		_broadcast_ranked_draft_snapshot()
	if (
		generation != _ranked_draft_generation
		or phase_serial != _ranked_draft_phase_serial
		or not ranked_draft_active
		or ranked_draft_phase != RANKED_DRAFT_TRANSITION
	):
		return
	_begin_ranked_draft_phase(
		generation,
		_ranked_draft_next_phase,
		_ranked_draft_next_team
	)


func _begin_ranked_draft_phase(
	generation: int,
	phase: StringName,
	turn_team: StringName
) -> void:
	if generation != _ranked_draft_generation or not ranked_draft_active:
		return
	_ranked_draft_phase_serial += 1
	var phase_serial := _ranked_draft_phase_serial
	ranked_draft_phase = phase
	ranked_draft_turn_team = turn_team
	ranked_draft_transition_title = ""
	ranked_draft_transition_subtitle = ""
	_ranked_draft_next_phase = RANKED_DRAFT_NONE
	_ranked_draft_next_team = NO_TEAM
	_ranked_draft_votes.clear()
	match phase:
		RANKED_DRAFT_PREFERENCE:
			ranked_draft_seconds_remaining = maxi(1, ranked_preference_seconds)
			_seed_ranked_cpu_preferences()
		RANKED_DRAFT_PICK:
			ranked_draft_seconds_remaining = maxi(1, ranked_pick_seconds)
			_seed_ranked_cpu_picks()
		_:
			ranked_draft_seconds_remaining = maxi(1, ranked_vote_seconds)
			_seed_ranked_cpu_votes()
	_broadcast_ranked_draft_snapshot()
	_run_ranked_draft_phase(generation, phase_serial)
	_try_autocomplete_ranked_phase.call_deferred()


func _run_ranked_draft_phase(
	generation: int,
	phase_serial: int
) -> void:
	while (
		generation == _ranked_draft_generation
		and phase_serial == _ranked_draft_phase_serial
		and ranked_draft_active
		and ranked_draft_seconds_remaining > 0
	):
		await get_tree().create_timer(1.0).timeout
		if (
			generation != _ranked_draft_generation
			or phase_serial != _ranked_draft_phase_serial
			or not ranked_draft_active
		):
			return
		ranked_draft_seconds_remaining = maxi(0, ranked_draft_seconds_remaining - 1)
		_broadcast_ranked_draft_snapshot()
	if (
		generation != _ranked_draft_generation
		or phase_serial != _ranked_draft_phase_serial
		or not ranked_draft_active
	):
		return
	_finish_or_wait_ranked_phase()


func _finish_or_wait_ranked_phase() -> void:
	if (
		ranked_draft_phase == RANKED_DRAFT_PICK
		and not _ranked_phase_has_every_choice()
	):
		# The final-pick countdown is guidance, never permission to spawn a
		# connected player with no ability. Stay here until all active players
		# lock a legal choice; accepted picks trigger the normal autocomplete.
		ranked_draft_seconds_remaining = 0
		_broadcast_ranked_draft_snapshot()
		return
	_advance_ranked_draft_phase()


func _try_autocomplete_ranked_phase() -> void:
	if (
		not multiplayer.is_server()
		or not ranked_draft_active
		or ranked_draft_phase == RANKED_DRAFT_TRANSITION
		or not _ranked_phase_has_every_choice()
	):
		return
	_advance_ranked_draft_phase()


func _ranked_phase_has_every_choice() -> bool:
	var required_players: Array[FootballPlayer] = []
	var choices: Dictionary = {}
	match ranked_draft_phase:
		RANKED_DRAFT_PREFERENCE:
			required_players = _get_valid_team_players(TEAM_BLUE)
			required_players.append_array(_get_valid_team_players(TEAM_RED))
			choices = _ranked_draft_preferences
		RANKED_DRAFT_PICK:
			required_players = _get_valid_team_players(TEAM_BLUE)
			required_players.append_array(_get_valid_team_players(TEAM_RED))
			choices = _ranked_draft_picks
		RANKED_DRAFT_PROTECT, RANKED_DRAFT_BAN:
			required_players = _get_valid_team_players(ranked_draft_turn_team)
			choices = _ranked_draft_votes
		_:
			return false
	if required_players.is_empty():
		return false
	for player in required_players:
		if not choices.has(player.owner_peer_id):
			return false
		if ranked_draft_phase == RANKED_DRAFT_PICK:
			var ability_id := int(choices.get(
				player.owner_peer_id,
				FootballPlayer.ABILITY_NONE
			))
			if (
				ability_id == FootballPlayer.ABILITY_NONE
				or not _ranked_pick_is_legal_for_team(player.team, ability_id)
			):
				return false
	return true


func _advance_ranked_draft_phase() -> void:
	if not multiplayer.is_server() or not ranked_draft_active:
		return
	if ranked_draft_phase == RANKED_DRAFT_PICK:
		_finish_ranked_draft()
		return
	if ranked_draft_phase == RANKED_DRAFT_PREFERENCE:
		_begin_ranked_draft_transition(
			_ranked_draft_generation,
			_ranked_team_name(_ranked_draft_first_team) + " PROTECTS FIRST",
			"Protect one planned ability from the opponent's ban.",
			RANKED_DRAFT_PROTECT,
			_ranked_draft_first_team
		)
		return
	_resolve_ranked_team_vote()
	var other_team := _opponent_team(ranked_draft_turn_team)
	if ranked_draft_phase == RANKED_DRAFT_PROTECT:
		if ranked_draft_turn_team == _ranked_draft_first_team:
			_begin_ranked_draft_transition(
				_ranked_draft_generation,
				_ranked_team_name(other_team) + " PROTECTS",
				"The other team now protects one ability.",
				RANKED_DRAFT_PROTECT,
				other_team
			)
		else:
			_begin_ranked_draft_transition(
				_ranked_draft_generation,
				_ranked_team_name(_ranked_draft_first_team) + " BANS FIRST",
				"Ban one unprotected ability from the opponent.",
				RANKED_DRAFT_BAN,
				_ranked_draft_first_team
			)
	elif ranked_draft_phase == RANKED_DRAFT_BAN:
		if ranked_draft_turn_team == _ranked_draft_first_team:
			_begin_ranked_draft_transition(
				_ranked_draft_generation,
				_ranked_team_name(other_team) + " BANS",
				"The other team now chooses its ban.",
				RANKED_DRAFT_BAN,
				other_team
			)
		else:
			_begin_ranked_draft_transition(
				_ranked_draft_generation,
				"FINAL ABILITY PICKS",
				"Lock a legal ability. Your opponents cannot see it until the draft closes.",
				RANKED_DRAFT_PICK,
				NO_TEAM
			)


func _ranked_team_name(team: StringName) -> String:
	return "BLUE TEAM" if team == TEAM_BLUE else "RED TEAM"


func _store_ranked_preference(player: FootballPlayer, ability_id: int) -> bool:
	if ability_id <= FootballPlayer.ABILITY_NONE or ability_id > FootballPlayer.ABILITY_COUNT:
		return false
	if not _ranked_pick_is_legal_for_team(player.team, ability_id):
		return false
	_ranked_draft_preferences[player.owner_peer_id] = ability_id
	return true


func _seed_ranked_cpu_preferences() -> void:
	for team in [TEAM_BLUE, TEAM_RED]:
		for player in _get_valid_team_players(team):
			if not player.cpu_controlled:
				continue
			var ability_id := _choose_ranked_cpu_preference(player)
			if ability_id != FootballPlayer.ABILITY_NONE:
				_ranked_draft_preferences[player.owner_peer_id] = ability_id


func _choose_ranked_cpu_preference(cpu: FootballPlayer) -> int:
	var candidates := _get_ranked_legal_abilities(cpu.team, false)
	var best_ability := FootballPlayer.ABILITY_NONE
	var best_score := -INF
	for value in candidates:
		var ability_id := int(value)
		var score := _score_ranked_ability(cpu, ability_id, cpu.team)
		if score > best_score:
			best_score = score
			best_ability = ability_id
	return best_ability


func _resolve_ranked_team_vote() -> void:
	var counts: Dictionary = {}
	for player in _get_valid_team_players(ranked_draft_turn_team):
		if not _ranked_draft_votes.has(player.owner_peer_id):
			continue
		var ability_id := int(_ranked_draft_votes[player.owner_peer_id])
		if not _ranked_vote_is_legal(
			ranked_draft_turn_team,
			ranked_draft_phase,
			ability_id
		):
			continue
		counts[ability_id] = int(counts.get(ability_id, 0)) + 1
	var selected := FootballPlayer.ABILITY_NONE
	var best_votes := -1
	var sorted_candidates: Array = counts.keys()
	sorted_candidates.sort()
	for value in sorted_candidates:
		var ability_id := int(value)
		var vote_count := int(counts[ability_id])
		if vote_count > best_votes:
			best_votes = vote_count
			selected = ability_id
	if selected == FootballPlayer.ABILITY_NONE:
		selected = _choose_ranked_default_vote(
			ranked_draft_turn_team,
			ranked_draft_phase
		)
	if ranked_draft_phase == RANKED_DRAFT_PROTECT:
		ranked_protected_abilities[ranked_draft_turn_team] = selected
	else:
		var target_team := _opponent_team(ranked_draft_turn_team)
		ranked_banned_abilities[target_team] = selected
		_clear_illegal_ranked_picks(target_team)


func _seed_ranked_cpu_votes() -> void:
	if ranked_draft_phase not in [RANKED_DRAFT_PROTECT, RANKED_DRAFT_BAN]:
		return
	for player in _get_valid_team_players(ranked_draft_turn_team):
		if not player.cpu_controlled:
			continue
		var ability_id := _choose_ranked_cpu_vote(
			player,
			ranked_draft_phase
		)
		if ability_id != FootballPlayer.ABILITY_NONE:
			_ranked_draft_votes[player.owner_peer_id] = ability_id


func _seed_ranked_cpu_picks() -> void:
	for team in [TEAM_BLUE, TEAM_RED]:
		var used: Dictionary = {}
		for player in _get_valid_team_players(team):
			if not player.cpu_controlled:
				continue
			var ability_id := _choose_ranked_cpu_pick(player, used)
			if ability_id != FootballPlayer.ABILITY_NONE:
				_ranked_draft_picks[player.owner_peer_id] = ability_id
				used[ability_id] = true
			else:
				_ranked_draft_picks.erase(player.owner_peer_id)


func _choose_ranked_cpu_vote(cpu: FootballPlayer, phase: StringName) -> int:
	var evaluated_team := cpu.team if phase == RANKED_DRAFT_PROTECT else _opponent_team(cpu.team)
	var candidates := _get_ranked_legal_abilities(evaluated_team, phase == RANKED_DRAFT_BAN)
	if candidates.is_empty():
		return FootballPlayer.ABILITY_NONE
	var best_ability := int(candidates[0])
	var best_score := -INF
	for value in candidates:
		var ability_id := int(value)
		var score := _score_ranked_ability(cpu, ability_id, evaluated_team)
		if phase == RANKED_DRAFT_PROTECT:
			for teammate in _get_valid_team_players(cpu.team):
				if int(_ranked_draft_preferences.get(teammate.owner_peer_id, FootballPlayer.ABILITY_NONE)) == ability_id:
					score += 18.0
		if phase == RANKED_DRAFT_BAN:
			score += 6.0 if FootballPlayer.get_ability_role(ability_id) == FootballPlayer.ABILITY_ROLE_ATTACK else 0.0
		if score > best_score:
			best_score = score
			best_ability = ability_id
	return best_ability


func _choose_ranked_default_vote(team: StringName, phase: StringName) -> int:
	var players := _get_valid_team_players(team)
	var evaluator: FootballPlayer = players[0] if not players.is_empty() else null
	if evaluator == null:
		return FootballPlayer.ABILITY_NONE
	return _choose_ranked_cpu_vote(evaluator, phase)


func _choose_ranked_cpu_pick(cpu: FootballPlayer, used: Dictionary) -> int:
	var candidates := _get_ranked_legal_abilities(cpu.team, false)
	var best_ability := FootballPlayer.ABILITY_NONE
	var best_score := -INF
	for value in candidates:
		var ability_id := int(value)
		if used.has(ability_id) or _ranked_team_pick_has_ability(cpu.team, ability_id):
			continue
		var score := _score_ranked_ability(cpu, ability_id, cpu.team)
		if int(_ranked_draft_preferences.get(cpu.owner_peer_id, FootballPlayer.ABILITY_NONE)) == ability_id:
			score += 24.0
		if score > best_score:
			best_score = score
			best_ability = ability_id
	return best_ability


func _score_ranked_ability(cpu: FootballPlayer, ability_id: int, team: StringName) -> float:
	var review := _get_cpu_halftime_team_review(team)
	var team_abilities := _get_team_ability_set(team, cpu)
	var opponent_abilities := _get_team_ability_set(_opponent_team(team))
	return _score_cpu_halftime_ability(
		cpu,
		ability_id,
		review,
		team_abilities,
		opponent_abilities
	)


func _store_ranked_pick(player: FootballPlayer, ability_id: int) -> bool:
	if ability_id <= FootballPlayer.ABILITY_NONE or ability_id > FootballPlayer.ABILITY_COUNT:
		return false
	if not _ranked_pick_is_legal_for_team(player.team, ability_id):
		return false
	if _ranked_team_pick_has_ability(player.team, ability_id, player.owner_peer_id):
		return false
	_ranked_draft_picks[player.owner_peer_id] = ability_id
	return true


func _ranked_pick_is_legal_for_team(team: StringName, ability_id: int) -> bool:
	if ability_id <= FootballPlayer.ABILITY_NONE or ability_id > FootballPlayer.ABILITY_COUNT:
		return ability_id == FootballPlayer.ABILITY_NONE
	if int(ranked_banned_abilities.get(team, FootballPlayer.ABILITY_NONE)) == ability_id:
		return false
	var previous: Array = ranked_previous_used_abilities.get(team, []) as Array
	return ability_id not in previous


func _ranked_vote_is_legal(team: StringName, phase: StringName, ability_id: int) -> bool:
	if ability_id <= FootballPlayer.ABILITY_NONE or ability_id > FootballPlayer.ABILITY_COUNT:
		return false
	var evaluated_team := team if phase == RANKED_DRAFT_PROTECT else _opponent_team(team)
	var previous: Array = ranked_previous_used_abilities.get(evaluated_team, []) as Array
	if ability_id in previous:
		return false
	if phase == RANKED_DRAFT_BAN:
		return int(ranked_protected_abilities.get(evaluated_team, FootballPlayer.ABILITY_NONE)) != ability_id
	return phase == RANKED_DRAFT_PROTECT


func _get_ranked_legal_abilities(team: StringName, for_ban: bool) -> Array[int]:
	var result: Array[int] = []
	for ability_id in range(FootballPlayer.ABILITY_NONE + 1, FootballPlayer.ABILITY_COUNT + 1):
		if for_ban:
			if _ranked_vote_is_legal(_opponent_team(team), RANKED_DRAFT_BAN, ability_id):
				result.append(ability_id)
		elif _ranked_pick_is_legal_for_team(team, ability_id):
			result.append(ability_id)
	return result


func _ranked_team_pick_has_ability(team: StringName, ability_id: int, ignored_peer_id: int = 0) -> bool:
	for player in _get_valid_team_players(team):
		if player.owner_peer_id == ignored_peer_id:
			continue
		if int(_ranked_draft_picks.get(player.owner_peer_id, FootballPlayer.ABILITY_NONE)) == ability_id:
			return true
	return false


func _clear_illegal_ranked_picks(team: StringName) -> void:
	for player in _get_valid_team_players(team):
		var ability_id := int(_ranked_draft_picks.get(player.owner_peer_id, FootballPlayer.ABILITY_NONE))
		if ability_id != FootballPlayer.ABILITY_NONE and not _ranked_pick_is_legal_for_team(team, ability_id):
			_ranked_draft_picks.erase(player.owner_peer_id)


func _finish_ranked_draft() -> void:
	if not multiplayer.is_server() or not ranked_draft_active:
		return
	var completed_stage := ranked_draft_stage
	for player in _get_all_match_players():
		var ability_id := int(_ranked_draft_picks.get(player.owner_peer_id, FootballPlayer.ABILITY_NONE))
		if not _ranked_pick_is_legal_for_team(player.team, ability_id):
			ability_id = FootballPlayer.ABILITY_NONE
		player.set_selected_ability(ability_id)
	var next_previous: Dictionary = {TEAM_BLUE: [], TEAM_RED: []}
	for team in [TEAM_BLUE, TEAM_RED]:
		var used: Array[int] = []
		for player in _get_valid_team_players(team):
			if player.selected_ability != FootballPlayer.ABILITY_NONE and player.selected_ability not in used:
				used.append(player.selected_ability)
		next_previous[team] = used
	ranked_previous_used_abilities = next_previous
	ranked_draft_active = false
	_ranked_draft_phase_serial += 1
	ranked_draft_phase = RANKED_DRAFT_NONE
	ranked_draft_turn_team = NO_TEAM
	ranked_draft_seconds_remaining = 0
	ranked_draft_transition_title = ""
	ranked_draft_transition_subtitle = ""
	_ranked_draft_next_phase = RANKED_DRAFT_NONE
	_ranked_draft_next_team = NO_TEAM
	_ranked_draft_preferences.clear()
	_ranked_draft_votes.clear()
	refresh_roster()
	_broadcast_ranked_draft_snapshot()
	match completed_stage:
		RANKED_STAGE_GAME_ONE:
			_ranked_initial_draft_complete = true
			if not start_match():
				_ranked_initial_draft_complete = false
				_clear_all_selected_abilities()
				refresh_roster()
				_send_match_start_result(
					SERVER_PEER_ID,
					false,
					"The roster changed during the draft. Ready up and start again."
				)
		RANKED_STAGE_GAME_TWO:
			_begin_tournament_leg_two()
		RANKED_STAGE_EXTRA_TIME:
			_ranked_overtime_draft_complete = true
			_start_tournament_extra_time()


func _clear_all_selected_abilities() -> void:
	for player in _get_all_match_players():
		player.set_selected_ability(FootballPlayer.ABILITY_NONE)


func _reset_ranked_draft_state() -> void:
	_ranked_draft_generation += 1
	_ranked_draft_phase_serial += 1
	ranked_draft_active = false
	ranked_draft_stage = RANKED_DRAFT_NONE
	ranked_draft_phase = RANKED_DRAFT_NONE
	ranked_draft_turn_team = NO_TEAM
	ranked_draft_seconds_remaining = 0
	ranked_draft_transition_title = ""
	ranked_draft_transition_subtitle = ""
	ranked_protected_abilities.clear()
	ranked_banned_abilities.clear()
	ranked_previous_used_abilities = {TEAM_BLUE: [], TEAM_RED: []}
	_ranked_draft_votes.clear()
	_ranked_draft_picks.clear()
	_ranked_draft_preferences.clear()
	_ranked_draft_next_phase = RANKED_DRAFT_NONE
	_ranked_draft_next_team = NO_TEAM
	_ranked_initial_draft_complete = false
	_ranked_overtime_draft_complete = false
	_ranked_penalty_goalkeepers.clear()


func _opponent_team(team: StringName) -> StringName:
	return TEAM_RED if team == TEAM_BLUE else TEAM_BLUE


func _get_player_team_for_peer(peer_id: int) -> StringName:
	var player := _get_player(peer_id)
	return player.team if player != null else NO_TEAM


func _build_ranked_draft_snapshot(viewer_team: StringName) -> Dictionary:
	var pick_entries: Array[Dictionary] = []
	for player in _get_all_match_players():
		var has_pick := _ranked_draft_picks.has(player.owner_peer_id)
		var has_preference := _ranked_draft_preferences.has(player.owner_peer_id)
		var can_reveal := not ranked_draft_active or player.team == viewer_team
		pick_entries.append({
			"peer_id": player.owner_peer_id,
			"name": player.display_name,
			"team": player.team,
			"cpu": player.cpu_controlled,
			"picked": has_pick,
			"preferred": has_preference,
			"preference": (
				int(_ranked_draft_preferences.get(player.owner_peer_id, FootballPlayer.ABILITY_NONE))
				if can_reveal
				else -2
			),
			"ability": (
				int(_ranked_draft_picks.get(player.owner_peer_id, FootballPlayer.ABILITY_NONE))
				if can_reveal
				else -2
			)
		})
	var visible_votes: Dictionary = {}
	if viewer_team == ranked_draft_turn_team:
		for player in _get_valid_team_players(viewer_team):
			if _ranked_draft_votes.has(player.owner_peer_id):
				visible_votes[player.owner_peer_id] = int(_ranked_draft_votes[player.owner_peer_id])
	return {
		"active": ranked_draft_active,
		"stage": ranked_draft_stage,
		"phase": ranked_draft_phase,
		"turn_team": ranked_draft_turn_team,
		"seconds": ranked_draft_seconds_remaining,
		"phase_serial": _ranked_draft_phase_serial,
		"waiting_for_choices": (
			ranked_draft_active
			and ranked_draft_phase == RANKED_DRAFT_PICK
			and ranked_draft_seconds_remaining <= 0
			and not _ranked_phase_has_every_choice()
		),
		"transition_title": ranked_draft_transition_title,
		"transition_subtitle": ranked_draft_transition_subtitle,
		"viewer_team": viewer_team,
		"first_team": _ranked_draft_first_team,
		"protected": ranked_protected_abilities.duplicate(true),
		"banned_for": ranked_banned_abilities.duplicate(true),
		"previous_used": ranked_previous_used_abilities.duplicate(true),
		"votes": visible_votes,
		"picks": pick_entries
	}


func _broadcast_ranked_draft_snapshot() -> void:
	if not multiplayer.is_server():
		return
	_receive_ranked_draft_snapshot(_build_ranked_draft_snapshot(_get_player_team_for_peer(multiplayer.get_unique_id())))
	for peer_id in multiplayer.get_peers():
		_receive_ranked_draft_snapshot.rpc_id(
			peer_id,
			_build_ranked_draft_snapshot(_get_player_team_for_peer(peer_id))
		)


@rpc("authority", "call_remote", "reliable")
func _receive_ranked_draft_snapshot(snapshot: Dictionary) -> void:
	ranked_draft_active = bool(snapshot.get("active", false))
	ranked_draft_stage = StringName(snapshot.get("stage", RANKED_DRAFT_NONE))
	ranked_draft_phase = StringName(snapshot.get("phase", RANKED_DRAFT_NONE))
	ranked_draft_turn_team = StringName(snapshot.get("turn_team", NO_TEAM))
	ranked_draft_seconds_remaining = int(snapshot.get("seconds", 0))
	ranked_protected_abilities = (snapshot.get("protected", {}) as Dictionary).duplicate(true)
	ranked_banned_abilities = (snapshot.get("banned_for", {}) as Dictionary).duplicate(true)
	ranked_previous_used_abilities = (snapshot.get("previous_used", {}) as Dictionary).duplicate(true)
	ranked_draft_changed.emit(snapshot)


func update_cpu_settings(
	blue_cpu_count: int,
	red_cpu_count: int
) -> bool:
	if not multiplayer.is_server() or game_has_started:
		return false

	requested_blue_cpu_count = clampi(
		blue_cpu_count,
		0,
		max_players_per_team
	)
	requested_red_cpu_count = clampi(
		red_cpu_count,
		0,
		max_players_per_team
	)
	_receive_cpu_settings.rpc(
		requested_blue_cpu_count,
		requested_red_cpu_count
	)
	_reconcile_cpu_players()
	return true


func update_cpu_difficulty(level: int) -> bool:
	if not multiplayer.is_server() or game_has_started:
		return false
	cpu_ai_level = clampi(level, 1, CPU_MAX_INTELLIGENCE)
	_receive_cpu_difficulty.rpc(cpu_ai_level)
	return true


func update_cpu_ability_preferences(
	blue_preferences: Array,
	red_preferences: Array
) -> bool:
	if (
		not multiplayer.is_server()
		or (game_has_started and not tournament_halftime_active)
	):
		return false
	blue_cpu_ability_preferences = _sanitize_cpu_ability_preferences(
		blue_preferences,
		blue_players
	)
	red_cpu_ability_preferences = _sanitize_cpu_ability_preferences(
		red_preferences,
		red_players
	)
	if tournament_halftime_active:
		_apply_cpu_halftime_ability_preferences(
			TEAM_BLUE,
			blue_players,
			false
		)
		_apply_cpu_halftime_ability_preferences(
			TEAM_RED,
			red_players,
			false
		)
	else:
		_apply_cpu_ability_preferences(TEAM_BLUE, blue_players)
		_apply_cpu_ability_preferences(TEAM_RED, red_players)
	cpu_ability_preferences_changed.emit(
		blue_cpu_ability_preferences.duplicate(),
		red_cpu_ability_preferences.duplicate()
	)
	refresh_roster()
	return true


func _sanitize_cpu_ability_preferences(
	preferences: Array,
	team_players: Array[FootballPlayer]
) -> Array[int]:
	var result: Array[int] = []
	result.resize(max_players_per_team)
	result.fill(CPU_ABILITY_RANDOM)
	var used: Dictionary = {}
	for player in team_players:
		if (
			is_instance_valid(player)
			and not player.cpu_controlled
			and player.selected_ability != FootballPlayer.ABILITY_NONE
		):
			used[player.selected_ability] = true
	for slot in range(max_players_per_team):
		if slot >= preferences.size():
			continue
		var ability_id := int(preferences[slot])
		if ability_id == FootballPlayer.ABILITY_META_VISION:
			ability_id = CPU_ABILITY_RANDOM
		if ability_id < CPU_ABILITY_RANDOM or ability_id > FootballPlayer.ABILITY_COUNT:
			ability_id = CPU_ABILITY_RANDOM
		if ability_id != CPU_ABILITY_RANDOM and ability_id != FootballPlayer.ABILITY_NONE:
			if used.has(ability_id):
				ability_id = CPU_ABILITY_RANDOM
			else:
				used[ability_id] = true
		result[slot] = ability_id
	return result


func _apply_cpu_ability_preferences(
	_team: StringName,
	team_players: Array[FootballPlayer]
) -> void:
	_assign_cpu_team_abilities(team_players)


func _adapt_cpu_abilities_for_second_leg() -> void:
	_apply_cpu_halftime_ability_preferences(
		TEAM_BLUE,
		blue_players,
		true
	)
	_apply_cpu_halftime_ability_preferences(
		TEAM_RED,
		red_players,
		true
	)
	cpu_ability_preferences_changed.emit(
		blue_cpu_ability_preferences.duplicate(),
		red_cpu_ability_preferences.duplicate()
	)
	refresh_roster()


func _apply_cpu_halftime_ability_preferences(
	team: StringName,
	team_players: Array[FootballPlayer],
	force_review: bool
) -> void:
	var used: Dictionary = {}
	var cpu_players: Array[FootballPlayer] = []
	for player in team_players:
		if not is_instance_valid(player):
			continue
		if player.cpu_controlled:
			cpu_players.append(player)
		elif player.selected_ability != FootballPlayer.ABILITY_NONE:
			used[player.selected_ability] = true
	cpu_players.sort_custom(
		func(first: FootballPlayer, second: FootballPlayer) -> bool:
			return first.team_slot < second.team_slot
	)

	# Manual host picks are authoritative. Random slots are reviewed afterwards
	# so a counter-pick can never steal a manually reserved ability.
	for cpu in cpu_players:
		var preference := _get_cpu_ability_preference(team, cpu.team_slot)
		if preference == CPU_ABILITY_RANDOM:
			continue
		if (
			preference != FootballPlayer.ABILITY_NONE
			and used.has(preference)
		):
			preference = FootballPlayer.ABILITY_NONE
		cpu.set_selected_ability(preference)
		if preference != FootballPlayer.ABILITY_NONE:
			used[preference] = true

	for cpu in cpu_players:
		if _get_cpu_ability_preference(team, cpu.team_slot) != CPU_ABILITY_RANDOM:
			continue
		var current := cpu.selected_ability
		var current_is_available := (
			current != FootballPlayer.ABILITY_NONE
			and not used.has(current)
		)
		var selected := current if current_is_available else FootballPlayer.ABILITY_NONE
		if force_review or selected == FootballPlayer.ABILITY_NONE:
			selected = _choose_cpu_halftime_ability(cpu, used)
		cpu.set_selected_ability(selected)
		if selected != FootballPlayer.ABILITY_NONE:
			used[selected] = true


func _choose_cpu_halftime_ability(
	cpu: FootballPlayer,
	used: Dictionary
) -> int:
	var review := _get_cpu_halftime_team_review(cpu.team)
	var team_abilities := _get_team_ability_set(cpu.team, cpu)
	var opponent_team := TEAM_RED if cpu.team == TEAM_BLUE else TEAM_BLUE
	var opponent_abilities := _get_team_ability_set(opponent_team)
	var candidates: Array[int] = []
	for category in [
		CPU_ABILITY_ATTACK,
		CPU_ABILITY_PLAYMAKER,
		CPU_ABILITY_FLEXIBLE,
		CPU_ABILITY_DEFENSE
	]:
		for ability_variant in _get_cpu_category_pool(category):
			var ability_id := int(ability_variant)
			if ability_id == FootballPlayer.ABILITY_META_VISION:
				continue
			if not used.has(ability_id) and ability_id not in candidates:
				candidates.append(ability_id)
	if candidates.is_empty():
		return FootballPlayer.ABILITY_NONE
	var best_ability := candidates[0]
	var best_score := -INF
	for ability_id in candidates:
		var score := _score_cpu_halftime_ability(
			cpu,
			ability_id,
			review,
			team_abilities,
			opponent_abilities
		)
		score += _cpu_ability_rng.randf_range(0.0, 5.0)
		if score > best_score:
			best_score = score
			best_ability = ability_id
	return best_ability


func _score_cpu_halftime_ability(
	cpu: FootballPlayer,
	ability_id: int,
	review: Dictionary,
	team_abilities: Dictionary,
	opponent_abilities: Dictionary
) -> float:
	var attack_need := float(review.get("attack_need", 0.5))
	var defense_need := float(review.get("defense_need", 0.5))
	var score := 10.0
	match FootballPlayer.get_ability_role(ability_id):
		FootballPlayer.ABILITY_ROLE_ATTACK:
			score += attack_need * 46.0
		FootballPlayer.ABILITY_ROLE_PLAYMAKER:
			score += (attack_need + defense_need) * 23.0
		FootballPlayer.ABILITY_ROLE_FLEXIBLE:
			score += 18.0
		FootballPlayer.ABILITY_ROLE_DEFENSE:
			score += defense_need * 48.0

	match ability_id:
		FootballPlayer.ABILITY_POWER_STRIKE:
			score += attack_need * 24.0
			if team_abilities.has(FootballPlayer.ABILITY_DIRECT_FINISH):
				score += 44.0
		FootballPlayer.ABILITY_DIRECT_FINISH:
			score += attack_need * 28.0
			if (
				team_abilities.has(FootballPlayer.ABILITY_POWER_STRIKE)
				or team_abilities.has(FootballPlayer.ABILITY_TIME_SKIP_PASS)
				or team_abilities.has(FootballPlayer.ABILITY_QUICK_TRIGGER)
			):
				score += 38.0
		FootballPlayer.ABILITY_TIME_SKIP_PASS:
			if team_abilities.has(FootballPlayer.ABILITY_DIRECT_FINISH):
				score += 34.0
		FootballPlayer.ABILITY_OVERDRIVE:
			score += attack_need * 20.0
			if team_abilities.has(FootballPlayer.ABILITY_TIME_SKIP_PASS):
				score += 22.0
		FootballPlayer.ABILITY_QUICK_TRIGGER:
			score += attack_need * 18.0
			if _ability_set_has_defender(opponent_abilities):
				score += 22.0
		FootballPlayer.ABILITY_BURST_DRIBBLE, FootballPlayer.ABILITY_ELASTIC_STEP, FootballPlayer.ABILITY_BLIND_SPOT:
			if _ability_set_has_defender(opponent_abilities):
				score += 18.0
		FootballPlayer.ABILITY_META_VISION:
			score += (attack_need + defense_need) * 15.0
		FootballPlayer.ABILITY_ENFORCER:
			if _ability_set_has_dribbler(opponent_abilities):
				score += 38.0
		FootballPlayer.ABILITY_REFLEX_BLOCK:
			if opponent_abilities.has(FootballPlayer.ABILITY_POWER_STRIKE):
				score += 46.0
			if opponent_abilities.has(FootballPlayer.ABILITY_DIRECT_FINISH):
				score += 24.0
		FootballPlayer.ABILITY_IRON_ANCHOR:
			if opponent_abilities.has(FootballPlayer.ABILITY_POWER_STRIKE):
				score += 30.0
			if _ability_set_has_dribbler(opponent_abilities):
				score += 20.0
		FootballPlayer.ABILITY_GOALKEEPER_REACH:
			if (
				opponent_abilities.has(FootballPlayer.ABILITY_POWER_STRIKE)
				or opponent_abilities.has(FootballPlayer.ABILITY_DIRECT_FINISH)
			):
				score += 36.0
		FootballPlayer.ABILITY_ECHO:
			score += defense_need * 24.0
			if opponent_abilities.has(FootballPlayer.ABILITY_POWER_STRIKE):
				score -= 12.0
		FootballPlayer.ABILITY_RETURN_TAG:
			score += attack_need * 22.0
			if team_abilities.size() >= 2:
				score += 18.0
		FootballPlayer.ABILITY_BREAKAWAY:
			score += attack_need * 26.0
			if _ability_set_has_defender(opponent_abilities):
				score += 24.0
		FootballPlayer.ABILITY_SNAPBACK:
			score += attack_need * 22.0
			if _ability_set_has_defender(opponent_abilities):
				score += 20.0
			if team_abilities.has(FootballPlayer.ABILITY_DIRECT_FINISH):
				score += 12.0
		FootballPlayer.ABILITY_SIDE_SWIPE:
			score += attack_need * 26.0
			if _ability_set_has_defender(opponent_abilities):
				score += 22.0
			if team_abilities.has(FootballPlayer.ABILITY_RETURN_TAG):
				score += 10.0
		FootballPlayer.ABILITY_NUTMEG:
			score += attack_need * 20.0
			if _ability_set_has_defender(opponent_abilities):
				score += 28.0
		FootballPlayer.ABILITY_DECOY_RUN:
			score += attack_need * 16.0 + defense_need * 4.0
			if _ability_set_has_defender(opponent_abilities):
				score += 14.0
		FootballPlayer.ABILITY_BOOGIE_WOOGIE:
			score += (attack_need + defense_need) * 12.0
			if _ability_set_has_dribbler(opponent_abilities):
				score += 20.0

	var stats: Dictionary = _player_statistics.get(cpu.owner_peer_id, {})
	var value_points := (
		int(stats.get("goals", 0)) * 8
		+ int(stats.get("saves", 0)) * 2
		+ int(stats.get("passes", 0))
	)
	var team_average := float(review.get("average_value", 0.0))
	if ability_id == cpu.selected_ability:
		score += 16.0 + maxf(0.0, float(value_points) - team_average) * 1.8
		var current_role := FootballPlayer.get_ability_role(ability_id)
		if current_role == FootballPlayer.ABILITY_ROLE_ATTACK and attack_need > 0.72:
			score -= 18.0
		elif current_role == FootballPlayer.ABILITY_ROLE_DEFENSE and defense_need > 0.72:
			score -= 18.0
	return score


func _get_cpu_halftime_team_review(team: StringName) -> Dictionary:
	var state: Dictionary = _cpu_strategy_adaptation.get(team, {})
	var attack_windows := int(state.get("attack_windows", 0))
	var defense_windows := int(state.get("defense_windows", 0))
	var attack_rate := 0.5
	var defense_rate := 0.5
	if attack_windows > 0:
		attack_rate = float(state.get("attack_successes", 0)) / float(attack_windows)
	if defense_windows > 0:
		defense_rate = float(state.get("defense_successes", 0)) / float(defense_windows)
	var total_value := 0.0
	var player_count := 0
	for value in _player_statistics.values():
		if value is not Dictionary:
			continue
		var entry := value as Dictionary
		if StringName(entry.get("team", NO_TEAM)) != team:
			continue
		total_value += (
			int(entry.get("goals", 0)) * 8
			+ int(entry.get("saves", 0)) * 2
			+ int(entry.get("passes", 0))
		)
		player_count += 1
	var own_goals := (
		tournament_leg_blue_goals if team == TEAM_BLUE
		else tournament_leg_red_goals
	)
	var opponent_goals := (
		tournament_leg_red_goals if team == TEAM_BLUE
		else tournament_leg_blue_goals
	)
	var attack_need := 1.0 - attack_rate
	var defense_need := 1.0 - defense_rate
	# Goals only provide a small tie-breaker; the primary review is whether the
	# team could advance attacks and relieve pressure during live play.
	if own_goals == 0:
		attack_need += 0.1
	if opponent_goals > own_goals:
		defense_need += 0.08
	return {
		"attack_need": clampf(attack_need, 0.0, 1.0),
		"defense_need": clampf(defense_need, 0.0, 1.0),
		"average_value": (
			total_value / float(player_count) if player_count > 0 else 0.0
		)
	}


func _get_team_ability_set(
	team: StringName,
	excluded_player: FootballPlayer = null
) -> Dictionary:
	var abilities: Dictionary = {}
	var players := blue_players if team == TEAM_BLUE else red_players
	for player in players:
		if (
			is_instance_valid(player)
			and player != excluded_player
			and player.selected_ability != FootballPlayer.ABILITY_NONE
		):
			abilities[player.selected_ability] = true
	return abilities


func _ability_set_has_defender(abilities: Dictionary) -> bool:
	for ability_variant in abilities.keys():
		if _is_cpu_defensive_ability(int(ability_variant)):
			return true
	return false


func _ability_set_has_dribbler(abilities: Dictionary) -> bool:
	return (
		abilities.has(FootballPlayer.ABILITY_BURST_DRIBBLE)
		or abilities.has(FootballPlayer.ABILITY_ELASTIC_STEP)
		or abilities.has(FootballPlayer.ABILITY_BLIND_SPOT)
		or abilities.has(FootballPlayer.ABILITY_OVERDRIVE)
	)


func _get_cpu_ability_preference(team: StringName, slot: int) -> int:
	var preferences := (
		red_cpu_ability_preferences
		if team == TEAM_RED
		else blue_cpu_ability_preferences
	)
	if slot < 0 or slot >= preferences.size():
		return CPU_ABILITY_RANDOM
	return int(preferences[slot])


func refresh_cpu_players() -> void:
	if not multiplayer.is_server():
		return
	_schedule_cpu_reconcile()


@rpc("authority", "call_local", "reliable")
func _receive_cpu_settings(
	blue_cpu_count: int,
	red_cpu_count: int
) -> void:
	requested_blue_cpu_count = clampi(
		blue_cpu_count,
		0,
		max_players_per_team
	)
	requested_red_cpu_count = clampi(
		red_cpu_count,
		0,
		max_players_per_team
	)
	cpu_settings_changed.emit(
		requested_blue_cpu_count,
		requested_red_cpu_count
	)


@rpc("authority", "call_local", "reliable")
func _receive_cpu_difficulty(level: int) -> void:
	cpu_ai_level = clampi(level, 1, CPU_MAX_INTELLIGENCE)
	cpu_difficulty_changed.emit(cpu_ai_level)


@rpc("authority", "call_local", "reliable")
func _receive_match_settings(
	new_regulation_seconds: float,
	new_goals_to_win: int
) -> void:
	regulation_seconds = new_regulation_seconds
	goals_to_win = new_goals_to_win
	match_settings_changed.emit(
		regulation_seconds,
		goals_to_win
	)


func _capture_fun_mutator_runtime_defaults() -> void:
	if ball != null:
		_fun_default_ball_damp = ball.linear_damp
		_fun_default_ball_mass = ball.mass
		_fun_default_ball_maximum_speed = ball.maximum_speed
		_fun_default_ball_containment = ball.arena_containment_enabled
		_fun_default_ball_goal_mouth_y = ball.arena_goal_mouth_y
	var field_visuals := get_parent().get_node_or_null("FieldVisuals")
	if field_visuals != null:
		_fun_default_visual_goal_mouth_y = field_visuals.get("goal_mouth_y") as Vector2
	_fun_boundary_defaults.clear()
	for shape: CollisionShape2D in _get_fun_collision_shapes():
		var shape_size: Vector2 = Vector2.ZERO
		if shape.shape is RectangleShape2D:
			shape_size = (shape.shape as RectangleShape2D).size
		_fun_boundary_defaults[String(shape.get_path())] = {
			"position": shape.position,
			"size": shape_size,
			"disabled": shape.disabled,
		}


func _get_fun_collision_shapes() -> Array[CollisionShape2D]:
	var result: Array[CollisionShape2D] = []
	var field_root: Node = get_parent()
	if field_root == null:
		return result
	for body_name: String in ["BallFieldBoundary", "Walls"]:
		var body := field_root.get_node_or_null(body_name)
		if body == null:
			continue
		for child: Node in body.get_children():
			if child is CollisionShape2D:
				result.append(child as CollisionShape2D)
	return result


func _apply_fun_mutator_runtime() -> void:
	_restore_fun_mutator_runtime()
	if ranked_mode:
		return
	if ball != null:
		if is_fun_mutator_enabled(FUN_LOW_FRICTION):
			ball.linear_damp = maxf(0.0, fun_low_friction_ball_damp)
		if is_fun_mutator_enabled(FUN_HEAVY_BALL):
			ball.mass = _fun_default_ball_mass * maxf(1.0, fun_heavy_ball_mass_multiplier)
			ball.set_fun_size_multiplier(
				clampf(fun_heavy_ball_size_multiplier, 1.0, 2.0)
			)
		if is_fun_mutator_enabled(FUN_FASTER_BALL):
			ball.maximum_speed = _fun_default_ball_maximum_speed * maxf(1.0, fun_faster_ball_speed_multiplier)
			ball.fun_kick_speed_multiplier = maxf(1.0, fun_faster_ball_speed_multiplier)
		ball.arena_containment_enabled = (
			_fun_default_ball_containment
			and not is_fun_mutator_enabled(FUN_NO_WALLS)
		)
	var goal_scale: float = 1.0
	if is_fun_mutator_enabled(FUN_SMALL_GOALS):
		goal_scale = clampf(fun_small_goal_scale, 0.4, 0.95)
	_apply_fun_goal_scale(goal_scale)
	_set_fun_no_cooldowns(
		is_fun_mutator_enabled(FUN_NO_COOLDOWNS)
	)
	_apply_fun_dictator_mbappe()
	_apply_fun_satoru_gojo()
	_apply_fun_neymar_jr()
	_apply_fun_erling_haaland()
	_apply_fun_manuel_neuer()
	var no_walls: bool = is_fun_mutator_enabled(FUN_NO_WALLS)
	for shape: CollisionShape2D in _get_fun_collision_shapes():
		shape.set_deferred("disabled", no_walls)
	_fun_rotation_remaining = maxf(3.0, fun_rotating_loadout_seconds)
	_fun_runtime_applied = true


func _set_fun_no_cooldowns(enabled: bool) -> void:
	if not multiplayer.is_server():
		return
	for player: FootballPlayer in _get_all_match_players():
		player.set_match_cooldowns_disabled(enabled)


func _apply_fun_dictator_mbappe() -> void:
	if not multiplayer.is_server():
		return
	if not is_fun_mutator_enabled(FUN_DICTATOR_MBAPPE):
		_restore_fun_dictator_mbappe()
		return
	if is_instance_valid(_fun_dictator_cpu):
		_apply_dictator_mbappe_profile(_fun_dictator_cpu)
		return
	var target_team: StringName = _get_fun_dictator_target_team()
	var candidates: Array[FootballPlayer] = []
	var target_players: Array[FootballPlayer] = (
		red_players if target_team == TEAM_RED else blue_players
	)
	for player: FootballPlayer in target_players:
		if is_instance_valid(player) and player.cpu_controlled:
			candidates.append(player)
	if candidates.is_empty():
		for player: FootballPlayer in _get_all_match_players():
			if player.cpu_controlled:
				candidates.append(player)
	if candidates.is_empty():
		return
	candidates.sort_custom(
		func(first: FootballPlayer, second: FootballPlayer) -> bool:
			return first.team_slot < second.team_slot
	)
	_fun_dictator_cpu = candidates[0]
	_fun_dictator_original_name = _fun_dictator_cpu.display_name
	_fun_dictator_original_ability = _fun_dictator_cpu.selected_ability
	_fun_dictator_original_cosmetic_loadout = _fun_dictator_cpu.cosmetic_loadout.duplicate(true)
	var controller := _fun_dictator_cpu.get_node_or_null("CPUController") as CPUPlayerAI
	if controller != null:
		_fun_dictator_original_personality = controller.get_cpu_personality()
		_fun_dictator_original_skill_override = controller.skill_level_override
	_apply_dictator_mbappe_profile(_fun_dictator_cpu)


func _apply_dictator_mbappe_profile(cpu: FootballPlayer) -> void:
	if not multiplayer.is_server() or not is_instance_valid(cpu):
		return
	cpu.set_neuer_boss_profile(false)
	cpu.set_permanent_power_strike(false)
	cpu.set_permanent_elastic_step(false)
	cpu.set_permanent_iron_anchor(false)
	cpu.display_name = LADDER_FINAL_BOSS_NAME
	cpu.clear_draft_perk()
	cpu.cosmetic_loadout = _build_dictator_mbappe_cosmetic_loadout(
		cpu.cosmetic_loadout
	)
	cpu.set_permanent_overdrive(true)
	var controller := cpu.get_node_or_null("CPUController") as CPUPlayerAI
	if controller != null:
		controller.set_skill_level_override(15)
		controller.set_cpu_personality(CPUPlayerAI.CPU_PERSONALITY_AGGRESSIVE)


func _apply_fun_satoru_gojo() -> void:
	if not multiplayer.is_server():
		return
	if not is_fun_mutator_enabled(FUN_SATORU_GOJO):
		_restore_fun_satoru_gojo()
		return
	if is_instance_valid(_fun_gojo_cpu):
		_apply_satoru_gojo_profile(_fun_gojo_cpu)
		return
	var target_team: StringName = _get_fun_dictator_target_team()
	var candidates: Array[FootballPlayer] = []
	var target_players: Array[FootballPlayer] = (
		red_players if target_team == TEAM_RED else blue_players
	)
	for player: FootballPlayer in target_players:
		if is_instance_valid(player) and player.cpu_controlled and player != _fun_dictator_cpu:
			candidates.append(player)
	if candidates.is_empty():
		for player: FootballPlayer in _get_all_match_players():
			if is_instance_valid(player) and player.cpu_controlled and player != _fun_dictator_cpu:
				candidates.append(player)
	if candidates.is_empty():
		return
	candidates.sort_custom(
		func(first: FootballPlayer, second: FootballPlayer) -> bool:
			return first.team_slot < second.team_slot
	)
	_fun_gojo_cpu = candidates[0]
	_fun_gojo_original_name = _fun_gojo_cpu.display_name
	_fun_gojo_original_ability = _fun_gojo_cpu.selected_ability
	_fun_gojo_original_cosmetic_loadout = _fun_gojo_cpu.cosmetic_loadout.duplicate(true)
	var controller := _fun_gojo_cpu.get_node_or_null("CPUController") as CPUPlayerAI
	if controller != null:
		_fun_gojo_original_personality = controller.get_cpu_personality()
		_fun_gojo_original_skill_override = controller.skill_level_override
	_apply_satoru_gojo_profile(_fun_gojo_cpu)


func _get_fun_boss_candidate(excluded_players: Array) -> FootballPlayer:
	var target_team: StringName = _get_fun_dictator_target_team()
	var target_players: Array[FootballPlayer] = (
		red_players if target_team == TEAM_RED else blue_players
	)
	var candidates: Array[FootballPlayer] = []
	for player: FootballPlayer in target_players:
		if (
			is_instance_valid(player)
			and player.cpu_controlled
			and not excluded_players.has(player)
		):
			candidates.append(player)
	if candidates.is_empty():
		for player: FootballPlayer in _get_all_match_players():
			if (
				is_instance_valid(player)
				and player.cpu_controlled
				and not excluded_players.has(player)
			):
				candidates.append(player)
	if candidates.is_empty():
		return null
	candidates.sort_custom(
		func(first: FootballPlayer, second: FootballPlayer) -> bool:
			return first.team_slot < second.team_slot
	)
	return candidates[0]


func _apply_fun_neymar_jr() -> void:
	if not multiplayer.is_server():
		return
	if not is_fun_mutator_enabled(FUN_NEYMAR_JR):
		_restore_fun_neymar_jr()
		return
	if is_instance_valid(_fun_neymar_cpu):
		_apply_neymar_profile(_fun_neymar_cpu)
		return
	_fun_neymar_cpu = _get_fun_boss_candidate([
		_fun_dictator_cpu,
		_fun_gojo_cpu,
	])
	if not is_instance_valid(_fun_neymar_cpu):
		return
	_fun_neymar_original_name = _fun_neymar_cpu.display_name
	_fun_neymar_original_ability = _fun_neymar_cpu.selected_ability
	_fun_neymar_original_cosmetic_loadout = _fun_neymar_cpu.cosmetic_loadout.duplicate(true)
	var controller := _fun_neymar_cpu.get_node_or_null("CPUController") as CPUPlayerAI
	if controller != null:
		_fun_neymar_original_personality = controller.get_cpu_personality()
		_fun_neymar_original_skill_override = controller.skill_level_override
	_apply_neymar_profile(_fun_neymar_cpu)


func _apply_fun_erling_haaland() -> void:
	if not multiplayer.is_server():
		return
	if not is_fun_mutator_enabled(FUN_ERLING_HAALAND):
		_restore_fun_erling_haaland()
		return
	if is_instance_valid(_fun_haaland_cpu):
		_apply_haaland_profile(_fun_haaland_cpu)
		return
	_fun_haaland_cpu = _get_fun_boss_candidate([
		_fun_dictator_cpu,
		_fun_gojo_cpu,
		_fun_neymar_cpu,
	])
	if not is_instance_valid(_fun_haaland_cpu):
		return
	_fun_haaland_original_name = _fun_haaland_cpu.display_name
	_fun_haaland_original_ability = _fun_haaland_cpu.selected_ability
	_fun_haaland_original_cosmetic_loadout = _fun_haaland_cpu.cosmetic_loadout.duplicate(true)
	var controller := _fun_haaland_cpu.get_node_or_null("CPUController") as CPUPlayerAI
	if controller != null:
		_fun_haaland_original_personality = controller.get_cpu_personality()
		_fun_haaland_original_skill_override = controller.skill_level_override
	_apply_haaland_profile(_fun_haaland_cpu)


func _apply_fun_manuel_neuer() -> void:
	if not multiplayer.is_server():
		return
	if not is_fun_mutator_enabled(FUN_MANUEL_NEUER):
		_restore_fun_manuel_neuer()
		return
	if is_instance_valid(_fun_neuer_cpu):
		_apply_manuel_neuer_profile(_fun_neuer_cpu)
		return
	_fun_neuer_cpu = _get_fun_boss_candidate([
		_fun_dictator_cpu,
		_fun_gojo_cpu,
		_fun_neymar_cpu,
		_fun_haaland_cpu,
	])
	if not is_instance_valid(_fun_neuer_cpu):
		return
	_fun_neuer_original_name = _fun_neuer_cpu.display_name
	_fun_neuer_original_ability = _fun_neuer_cpu.selected_ability
	_fun_neuer_original_cosmetic_loadout = (
		_fun_neuer_cpu.cosmetic_loadout.duplicate(true)
	)
	var controller := _fun_neuer_cpu.get_node_or_null("CPUController") as CPUPlayerAI
	if controller != null:
		_fun_neuer_original_personality = controller.get_cpu_personality()
		_fun_neuer_original_skill_override = controller.skill_level_override
	_apply_manuel_neuer_profile(_fun_neuer_cpu)


func _apply_satoru_gojo_profile(cpu: FootballPlayer) -> void:
	if not multiplayer.is_server() or not is_instance_valid(cpu):
		return
	cpu.set_neuer_boss_profile(false)
	cpu.set_permanent_overdrive(false)
	cpu.set_permanent_elastic_step(false)
	cpu.set_permanent_power_strike(false)
	cpu.display_name = SATORU_GOJO_BOSS_NAME
	cpu.clear_draft_perk()
	cpu.cosmetic_loadout = _build_satoru_gojo_cosmetic_loadout(cpu.cosmetic_loadout)
	cpu.set_permanent_iron_anchor(true)
	var controller := cpu.get_node_or_null("CPUController") as CPUPlayerAI
	if controller != null:
		controller.set_skill_level_override(15)
		controller.set_cpu_personality(CPUPlayerAI.CPU_PERSONALITY_COUNTERATTACKER)


func _apply_neymar_profile(cpu: FootballPlayer) -> void:
	if not multiplayer.is_server() or not is_instance_valid(cpu):
		return
	cpu.set_neuer_boss_profile(false)
	cpu.set_permanent_overdrive(false)
	cpu.set_permanent_power_strike(false)
	cpu.set_permanent_iron_anchor(false)
	cpu.display_name = NEYMAR_BOSS_NAME
	cpu.clear_draft_perk()
	cpu.cosmetic_loadout = _build_neymar_cosmetic_loadout(cpu.cosmetic_loadout)
	cpu.set_permanent_elastic_step(true)
	var controller := cpu.get_node_or_null("CPUController") as CPUPlayerAI
	if controller != null:
		controller.set_skill_level_override(15)
		controller.set_cpu_personality(CPUPlayerAI.CPU_PERSONALITY_TECHNICAL)


func _apply_haaland_profile(cpu: FootballPlayer) -> void:
	if not multiplayer.is_server() or not is_instance_valid(cpu):
		return
	cpu.set_neuer_boss_profile(false)
	cpu.set_permanent_overdrive(false)
	cpu.set_permanent_elastic_step(false)
	cpu.set_permanent_iron_anchor(false)
	cpu.display_name = HAALAND_BOSS_NAME
	cpu.clear_draft_perk()
	cpu.cosmetic_loadout = _build_haaland_cosmetic_loadout(cpu.cosmetic_loadout)
	cpu.set_permanent_power_strike(true)
	var controller := cpu.get_node_or_null("CPUController") as CPUPlayerAI
	if controller != null:
		controller.set_skill_level_override(15)
		controller.set_cpu_personality(CPUPlayerAI.CPU_PERSONALITY_AGGRESSIVE)


func _apply_manuel_neuer_profile(cpu: FootballPlayer) -> void:
	if not multiplayer.is_server() or not is_instance_valid(cpu):
		return
	cpu.set_permanent_overdrive(false)
	cpu.set_permanent_elastic_step(false)
	cpu.set_permanent_power_strike(false)
	cpu.set_permanent_iron_anchor(false)
	cpu.display_name = MANUEL_NEUER_BOSS_NAME
	cpu.clear_draft_perk()
	cpu.cosmetic_loadout = _build_manuel_neuer_cosmetic_loadout(
		cpu.cosmetic_loadout
	)
	cpu.set_selected_ability(FootballPlayer.ABILITY_GOALKEEPER_REACH)
	cpu.set_neuer_boss_profile(true)
	var controller := cpu.get_node_or_null("CPUController") as CPUPlayerAI
	if controller != null:
		controller.set_skill_level_override(15)
		controller.set_cpu_personality(CPUPlayerAI.CPU_PERSONALITY_ADAPTIVE)


func _build_dictator_mbappe_cosmetic_loadout(base_loadout: Dictionary) -> Dictionary:
	var loadout: Dictionary = base_loadout.duplicate(true)
	loadout["player_skin"] = "player_skin.celestial_seraph"
	loadout["player_skin_blue"] = "player_skin.celestial_seraph"
	loadout["player_skin_red"] = "player_skin.celestial_seraph"
	loadout["team_player_skins_enabled"] = false
	loadout["player_skin_color_index"] = 2
	loadout["player_skin_color_blue"] = 2
	loadout["player_skin_color_red"] = 2
	loadout["special_team_color_override"] = (
		FootballCosmeticInventory.DICTATOR_TEAM_COLOR_OVERRIDE
	)
	loadout["frame_palette"] = "frame_palette.golden_touch"
	loadout["frame_palette_blue"] = "frame_palette.golden_touch"
	loadout["frame_palette_red"] = "frame_palette.golden_touch"
	loadout["player_material"] = "player_material.pearlescent"
	loadout["player_material_blue"] = "player_material.pearlescent"
	loadout["player_material_red"] = "player_material.pearlescent"
	loadout["goal_explosion"] = "goal_explosion.crown_burst"
	loadout["goal_explosion_blue"] = "goal_explosion.crown_burst"
	loadout["goal_explosion_red"] = "goal_explosion.crown_burst"
	loadout["goal_explosion_color_index"] = 2
	loadout["player_banner"] = "player_banner.dictator"
	loadout["player_banner_blue"] = "player_banner.dictator"
	loadout["player_banner_red"] = "player_banner.dictator"
	loadout["ability_particle"] = "ability_particle.starfall"
	loadout["ability_particle_blue"] = "ability_particle.starfall"
	loadout["ability_particle_red"] = "ability_particle.starfall"
	loadout["player_subtitle"] = "PACE IS POWER"
	return FootballCosmeticInventory.sanitize_catalog_network_loadout(loadout)


func _build_satoru_gojo_cosmetic_loadout(base_loadout: Dictionary) -> Dictionary:
	var loadout: Dictionary = base_loadout.duplicate(true)
	loadout["player_skin"] = "player_skin.infinity_sorcerer"
	loadout["player_skin_blue"] = "player_skin.infinity_sorcerer"
	loadout["player_skin_red"] = "player_skin.infinity_sorcerer"
	loadout["team_player_skins_enabled"] = false
	loadout["player_skin_color_index"] = 6
	loadout["player_skin_color_blue"] = 6
	loadout["player_skin_color_red"] = 6
	loadout["special_team_color_override"] = FootballCosmeticInventory.GOJO_TEAM_COLOR_OVERRIDE
	loadout["frame_palette"] = "frame_palette.eclipse"
	loadout["frame_palette_blue"] = "frame_palette.eclipse"
	loadout["frame_palette_red"] = "frame_palette.eclipse"
	loadout["player_material"] = "player_material.vortex"
	loadout["player_material_blue"] = "player_material.vortex"
	loadout["player_material_red"] = "player_material.vortex"
	loadout["goal_explosion"] = "goal_explosion.cyclone"
	loadout["goal_explosion_blue"] = "goal_explosion.cyclone"
	loadout["goal_explosion_red"] = "goal_explosion.cyclone"
	loadout["goal_explosion_color_index"] = 6
	loadout["player_banner"] = "player_banner.gojo"
	loadout["player_banner_blue"] = "player_banner.gojo"
	loadout["player_banner_red"] = "player_banner.gojo"
	loadout["ability_particle"] = "ability_particle.comet_sparks"
	loadout["ability_particle_blue"] = "ability_particle.comet_sparks"
	loadout["ability_particle_red"] = "ability_particle.comet_sparks"
	loadout["player_subtitle"] = "Honored One"
	return FootballCosmeticInventory.sanitize_catalog_network_loadout(loadout)


func _build_neymar_cosmetic_loadout(base_loadout: Dictionary) -> Dictionary:
	var loadout: Dictionary = base_loadout.duplicate(true)
	loadout["player_skin"] = "player_skin.brazilian_prince_10"
	loadout["player_skin_blue"] = "player_skin.brazilian_prince_10"
	loadout["player_skin_red"] = "player_skin.brazilian_prince_10"
	loadout["team_player_skins_enabled"] = false
	loadout["player_skin_color_index"] = -1
	loadout["player_skin_color_blue"] = -1
	loadout["player_skin_color_red"] = -1
	loadout["special_team_color_override"] = (
		FootballCosmeticInventory.NEYMAR_TEAM_COLOR_OVERRIDE
	)
	loadout["frame_palette"] = "frame_palette.golden_touch"
	loadout["frame_palette_blue"] = "frame_palette.golden_touch"
	loadout["frame_palette_red"] = "frame_palette.golden_touch"
	loadout["player_material"] = "player_material.stardust"
	loadout["player_material_blue"] = "player_material.stardust"
	loadout["player_material_red"] = "player_material.stardust"
	loadout["goal_explosion"] = "goal_explosion.stadium_roar"
	loadout["goal_explosion_blue"] = "goal_explosion.stadium_roar"
	loadout["goal_explosion_red"] = "goal_explosion.stadium_roar"
	loadout["goal_explosion_color_index"] = 4
	loadout["player_banner"] = "player_banner.neymar_jr"
	loadout["player_banner_blue"] = "player_banner.neymar_jr"
	loadout["player_banner_red"] = "player_banner.neymar_jr"
	# The goal theme remains a placeholder until its dedicated audio arrives.
	loadout["goal_theme"] = "goal_theme.classic"
	loadout["goal_theme_blue"] = "goal_theme.classic"
	loadout["goal_theme_red"] = "goal_theme.classic"
	loadout["ability_particle"] = "ability_particle.arcane_orbit"
	loadout["ability_particle_blue"] = "ability_particle.arcane_orbit"
	loadout["ability_particle_red"] = "ability_particle.arcane_orbit"
	loadout["player_subtitle"] = "THE BRAZILIAN PRINCE"
	return FootballCosmeticInventory.sanitize_catalog_network_loadout(loadout)


func _build_haaland_cosmetic_loadout(base_loadout: Dictionary) -> Dictionary:
	var loadout: Dictionary = base_loadout.duplicate(true)
	loadout["player_skin"] = "player_skin.nordic_terminator_9"
	loadout["player_skin_blue"] = "player_skin.nordic_terminator_9"
	loadout["player_skin_red"] = "player_skin.nordic_terminator_9"
	loadout["team_player_skins_enabled"] = false
	loadout["player_skin_color_index"] = -1
	loadout["player_skin_color_blue"] = -1
	loadout["player_skin_color_red"] = -1
	loadout["special_team_color_override"] = (
		FootballCosmeticInventory.HAALAND_TEAM_COLOR_OVERRIDE
	)
	loadout["frame_palette"] = "frame_palette.frost_prism"
	loadout["frame_palette_blue"] = "frame_palette.frost_prism"
	loadout["frame_palette_red"] = "frame_palette.frost_prism"
	loadout["player_material"] = "player_material.carbon_fiber"
	loadout["player_material_blue"] = "player_material.carbon_fiber"
	loadout["player_material_red"] = "player_material.carbon_fiber"
	loadout["goal_explosion"] = "goal_explosion.electric_net"
	loadout["goal_explosion_blue"] = "goal_explosion.electric_net"
	loadout["goal_explosion_red"] = "goal_explosion.electric_net"
	loadout["goal_explosion_color_index"] = 5
	loadout["player_banner"] = "player_banner.erling_haaland"
	loadout["player_banner_blue"] = "player_banner.erling_haaland"
	loadout["player_banner_red"] = "player_banner.erling_haaland"
	loadout["goal_theme"] = "goal_theme.classic"
	loadout["goal_theme_blue"] = "goal_theme.classic"
	loadout["goal_theme_red"] = "goal_theme.classic"
	loadout["ability_particle"] = "ability_particle.comet_sparks"
	loadout["ability_particle_blue"] = "ability_particle.comet_sparks"
	loadout["ability_particle_red"] = "ability_particle.comet_sparks"
	loadout["player_subtitle"] = "THE TERMINATOR"
	return FootballCosmeticInventory.sanitize_catalog_network_loadout(loadout)


func _build_manuel_neuer_cosmetic_loadout(base_loadout: Dictionary) -> Dictionary:
	var loadout: Dictionary = base_loadout.duplicate(true)
	loadout["player_skin"] = "player_skin.obsidian_wall"
	loadout["player_skin_blue"] = "player_skin.obsidian_wall"
	loadout["player_skin_red"] = "player_skin.obsidian_wall"
	loadout["team_player_skins_enabled"] = false
	loadout["player_skin_color_index"] = -1
	loadout["player_skin_color_blue"] = -1
	loadout["player_skin_color_red"] = -1
	loadout["frame_palette"] = "frame_palette.obsidian_guard"
	loadout["frame_palette_blue"] = "frame_palette.obsidian_guard"
	loadout["frame_palette_red"] = "frame_palette.obsidian_guard"
	loadout["player_material"] = "player_material.brushed_metal"
	loadout["player_material_blue"] = "player_material.brushed_metal"
	loadout["player_material_red"] = "player_material.brushed_metal"
	loadout["goal_explosion"] = "goal_explosion.ice_breaker"
	loadout["goal_explosion_blue"] = "goal_explosion.ice_breaker"
	loadout["goal_explosion_red"] = "goal_explosion.ice_breaker"
	loadout["goal_explosion_color_index"] = 5
	loadout["player_banner"] = "player_banner.manuel_neuer"
	loadout["player_banner_blue"] = "player_banner.manuel_neuer"
	loadout["player_banner_red"] = "player_banner.manuel_neuer"
	loadout["goal_theme"] = "goal_theme.classic"
	loadout["goal_theme_blue"] = "goal_theme.classic"
	loadout["goal_theme_red"] = "goal_theme.classic"
	loadout["ability_particle"] = "ability_particle.bubble_pop"
	loadout["ability_particle_blue"] = "ability_particle.bubble_pop"
	loadout["ability_particle_red"] = "ability_particle.bubble_pop"
	loadout["player_subtitle"] = "THE SWEEPER KEEPER"
	return FootballCosmeticInventory.sanitize_catalog_network_loadout(loadout)


func _get_fun_dictator_target_team() -> StringName:
	var host_player: FootballPlayer = _get_player(SERVER_PEER_ID)
	if host_player != null and host_player.team in [TEAM_BLUE, TEAM_RED]:
		return TEAM_RED if host_player.team == TEAM_BLUE else TEAM_BLUE
	var blue_has_human: bool = false
	var red_has_human: bool = false
	for player: FootballPlayer in blue_players:
		blue_has_human = blue_has_human or (
			is_instance_valid(player) and not player.cpu_controlled
		)
	for player: FootballPlayer in red_players:
		red_has_human = red_has_human or (
			is_instance_valid(player) and not player.cpu_controlled
		)
	if blue_has_human != red_has_human:
		return TEAM_RED if blue_has_human else TEAM_BLUE
	return TEAM_RED


func _restore_fun_dictator_mbappe() -> void:
	if not multiplayer.is_server():
		return
	if is_instance_valid(_fun_dictator_cpu):
		_fun_dictator_cpu.set_permanent_overdrive(false)
		_fun_dictator_cpu.display_name = _fun_dictator_original_name
		_fun_dictator_cpu.cosmetic_loadout = (
			_fun_dictator_original_cosmetic_loadout.duplicate(true)
		)
		_fun_dictator_cpu.set_selected_ability(_fun_dictator_original_ability)
		var controller := _fun_dictator_cpu.get_node_or_null("CPUController") as CPUPlayerAI
		if controller != null:
			controller.set_skill_level_override(_fun_dictator_original_skill_override)
			controller.set_cpu_personality(_fun_dictator_original_personality)
	_fun_dictator_cpu = null
	_fun_dictator_original_name = ""
	_fun_dictator_original_ability = FootballPlayer.ABILITY_NONE
	_fun_dictator_original_cosmetic_loadout.clear()
	_fun_dictator_original_personality = &"auto"
	_fun_dictator_original_skill_override = 0


func _restore_fun_satoru_gojo() -> void:
	if not multiplayer.is_server():
		return
	if is_instance_valid(_fun_gojo_cpu):
		_fun_gojo_cpu.set_permanent_iron_anchor(false)
		_fun_gojo_cpu.display_name = _fun_gojo_original_name
		_fun_gojo_cpu.cosmetic_loadout = _fun_gojo_original_cosmetic_loadout.duplicate(true)
		_fun_gojo_cpu.set_selected_ability(_fun_gojo_original_ability)
		var controller := _fun_gojo_cpu.get_node_or_null("CPUController") as CPUPlayerAI
		if controller != null:
			controller.set_skill_level_override(_fun_gojo_original_skill_override)
			controller.set_cpu_personality(_fun_gojo_original_personality)
	_fun_gojo_cpu = null
	_fun_gojo_original_name = ""
	_fun_gojo_original_ability = FootballPlayer.ABILITY_NONE
	_fun_gojo_original_cosmetic_loadout.clear()
	_fun_gojo_original_personality = &"auto"
	_fun_gojo_original_skill_override = 0


func _restore_fun_neymar_jr() -> void:
	if not multiplayer.is_server():
		return
	if is_instance_valid(_fun_neymar_cpu):
		_fun_neymar_cpu.set_permanent_elastic_step(false)
		_fun_neymar_cpu.display_name = _fun_neymar_original_name
		_fun_neymar_cpu.cosmetic_loadout = _fun_neymar_original_cosmetic_loadout.duplicate(true)
		_fun_neymar_cpu.set_selected_ability(_fun_neymar_original_ability)
		var controller := _fun_neymar_cpu.get_node_or_null("CPUController") as CPUPlayerAI
		if controller != null:
			controller.set_skill_level_override(_fun_neymar_original_skill_override)
			controller.set_cpu_personality(_fun_neymar_original_personality)
	_fun_neymar_cpu = null
	_fun_neymar_original_name = ""
	_fun_neymar_original_ability = FootballPlayer.ABILITY_NONE
	_fun_neymar_original_cosmetic_loadout.clear()
	_fun_neymar_original_personality = &"auto"
	_fun_neymar_original_skill_override = 0


func _restore_fun_erling_haaland() -> void:
	if not multiplayer.is_server():
		return
	if is_instance_valid(_fun_haaland_cpu):
		_fun_haaland_cpu.set_permanent_power_strike(false)
		_fun_haaland_cpu.display_name = _fun_haaland_original_name
		_fun_haaland_cpu.cosmetic_loadout = _fun_haaland_original_cosmetic_loadout.duplicate(true)
		_fun_haaland_cpu.set_selected_ability(_fun_haaland_original_ability)
		var controller := _fun_haaland_cpu.get_node_or_null("CPUController") as CPUPlayerAI
		if controller != null:
			controller.set_skill_level_override(_fun_haaland_original_skill_override)
			controller.set_cpu_personality(_fun_haaland_original_personality)
	_fun_haaland_cpu = null
	_fun_haaland_original_name = ""
	_fun_haaland_original_ability = FootballPlayer.ABILITY_NONE
	_fun_haaland_original_cosmetic_loadout.clear()
	_fun_haaland_original_personality = &"auto"
	_fun_haaland_original_skill_override = 0


func _restore_fun_manuel_neuer() -> void:
	if not multiplayer.is_server():
		return
	if is_instance_valid(_fun_neuer_cpu):
		_fun_neuer_cpu.set_neuer_boss_profile(false)
		_fun_neuer_cpu.display_name = _fun_neuer_original_name
		_fun_neuer_cpu.cosmetic_loadout = (
			_fun_neuer_original_cosmetic_loadout.duplicate(true)
		)
		_fun_neuer_cpu.set_selected_ability(_fun_neuer_original_ability)
		var controller := _fun_neuer_cpu.get_node_or_null("CPUController") as CPUPlayerAI
		if controller != null:
			controller.set_skill_level_override(_fun_neuer_original_skill_override)
			controller.set_cpu_personality(_fun_neuer_original_personality)
	_fun_neuer_cpu = null
	_fun_neuer_original_name = ""
	_fun_neuer_original_ability = FootballPlayer.ABILITY_NONE
	_fun_neuer_original_cosmetic_loadout.clear()
	_fun_neuer_original_personality = &"auto"
	_fun_neuer_original_skill_override = 0


func _apply_fun_goal_scale(scale_factor: float) -> void:
	if red_goal != null:
		red_goal.set_mouth_scale(scale_factor)
	if blue_goal != null:
		blue_goal.set_mouth_scale(scale_factor)
	if ball == null:
		return
	var original_mouth: Vector2 = _fun_default_ball_goal_mouth_y
	var center_y: float = (original_mouth.x + original_mouth.y) * 0.5
	var half_height: float = (original_mouth.y - original_mouth.x) * 0.5 * scale_factor
	ball.arena_goal_mouth_y = Vector2(center_y - half_height, center_y + half_height)
	var field_visuals := get_parent().get_node_or_null("FieldVisuals")
	if field_visuals != null and field_visuals.has_method("set_goal_mouth_y"):
		field_visuals.call("set_goal_mouth_y", ball.arena_goal_mouth_y)
	var bounds: Rect2 = ball.arena_playable_bounds.abs()
	var upper_height: float = maxf(20.0, center_y - half_height - bounds.position.y)
	var lower_height: float = maxf(20.0, bounds.end.y - center_y - half_height)
	for side_name: String in ["Left", "Right"]:
		var upper := get_parent().get_node_or_null("BallFieldBoundary/%sUpperLine" % side_name) as CollisionShape2D
		var lower := get_parent().get_node_or_null("BallFieldBoundary/%sLowerLine" % side_name) as CollisionShape2D
		_set_fun_side_boundary(upper, bounds.position.y + upper_height * 0.5, upper_height)
		_set_fun_side_boundary(lower, center_y + half_height + lower_height * 0.5, lower_height)


func _set_fun_side_boundary(shape: CollisionShape2D, center_y: float, height: float) -> void:
	if shape == null or shape.shape is not RectangleShape2D:
		return
	shape.shape = shape.shape.duplicate(true)
	var rectangle := shape.shape as RectangleShape2D
	rectangle.size.y = height
	shape.position.y = center_y


func _restore_fun_mutator_runtime() -> void:
	_restore_fun_manuel_neuer()
	_restore_fun_erling_haaland()
	_restore_fun_neymar_jr()
	_restore_fun_satoru_gojo()
	_restore_fun_dictator_mbappe()
	_set_fun_no_cooldowns(false)
	if ball != null:
		ball.linear_damp = _fun_default_ball_damp
		ball.mass = _fun_default_ball_mass
		ball.set_fun_size_multiplier(1.0)
		ball.maximum_speed = _fun_default_ball_maximum_speed
		ball.fun_kick_speed_multiplier = 1.0
		ball.arena_containment_enabled = _fun_default_ball_containment
		ball.arena_goal_mouth_y = _fun_default_ball_goal_mouth_y
	if red_goal != null:
		red_goal.set_mouth_scale(1.0)
	if blue_goal != null:
		blue_goal.set_mouth_scale(1.0)
	var field_visuals := get_parent().get_node_or_null("FieldVisuals")
	if field_visuals != null and field_visuals.has_method("set_goal_mouth_y"):
		field_visuals.call("set_goal_mouth_y", _fun_default_visual_goal_mouth_y)
	for shape: CollisionShape2D in _get_fun_collision_shapes():
		var saved_variant: Variant = _fun_boundary_defaults.get(String(shape.get_path()), null)
		if saved_variant is not Dictionary:
			continue
		var saved := saved_variant as Dictionary
		shape.position = saved.get("position", shape.position) as Vector2
		shape.set_deferred("disabled", bool(saved.get("disabled", false)))
		var saved_size := saved.get("size", Vector2.ZERO) as Vector2
		if shape.shape is RectangleShape2D and saved_size != Vector2.ZERO:
			shape.shape = shape.shape.duplicate(true)
			(shape.shape as RectangleShape2D).size = saved_size
	_fun_runtime_applied = false
	_fun_rotation_remaining = 0.0


func _assign_fun_draft_loadouts() -> void:
	_assign_fun_draft_team(blue_players)
	_assign_fun_draft_team(red_players)
	_apply_fun_dictator_mbappe()
	_apply_fun_satoru_gojo()
	_apply_fun_neymar_jr()
	_apply_fun_erling_haaland()
	_apply_fun_manuel_neuer()
	refresh_roster()


func _assign_fun_draft_team(team_players: Array[FootballPlayer]) -> void:
	var used: Dictionary = {}
	var allow_duplicates: bool = is_fun_mutator_enabled(FUN_DUPLICATE_ABILITIES)
	for player: FootballPlayer in team_players:
		if not is_instance_valid(player):
			continue
		var selected: int = _draw_fun_ability(used, allow_duplicates)
		if player.cpu_controlled and selected == FootballPlayer.ABILITY_META_VISION:
			var cpu_candidates: Array[int] = []
			for ability_id: int in range(1, FootballPlayer.ABILITY_COUNT + 1):
				if ability_id == FootballPlayer.ABILITY_META_VISION:
					continue
				if allow_duplicates or not used.has(ability_id):
					cpu_candidates.append(ability_id)
			if not cpu_candidates.is_empty():
				selected = cpu_candidates[_cpu_ability_rng.randi_range(0, cpu_candidates.size() - 1)]
		player.set_selected_ability(selected)
		if not allow_duplicates:
			used[selected] = true


func _draw_fun_ability(used: Dictionary, allow_duplicates: bool) -> int:
	var candidates: Array[int] = []
	for ability_id: int in range(1, FootballPlayer.ABILITY_COUNT + 1):
		if allow_duplicates or not used.has(ability_id):
			candidates.append(ability_id)
	if candidates.is_empty():
		return FootballPlayer.ABILITY_NONE
	return candidates[_cpu_ability_rng.randi_range(0, candidates.size() - 1)]


func _update_fun_rotating_loadouts(delta: float) -> void:
	if not is_fun_mutator_enabled(FUN_ROTATING_LOADOUTS):
		return
	_fun_rotation_remaining -= delta
	if _fun_rotation_remaining > 0.0:
		return
	_fun_rotation_remaining = maxf(3.0, fun_rotating_loadout_seconds)
	_assign_fun_draft_loadouts()
	_show_announcement("ABILITIES ROTATED", 1.2)


func start_match() -> bool:
	if not multiplayer.is_server():
		return false

	var validation_error := _get_start_error()
	if not validation_error.is_empty():
		return false

	red_score = 0
	blue_score = 0
	tournament_leg = 1
	tournament_leg_red_goals = 0
	tournament_leg_blue_goals = 0
	tournament_sudden_death = false
	tournament_halftime_active = false
	tournament_halftime_remaining = 0
	_halftime_generation += 1
	_reset_tournament_tiebreak_state()
	_quick_chat_last_sent_at.clear()
	_cpu_quick_chat_global_last_sent_at = -1000.0
	_reset_cpu_quick_chat_timer(true)
	regulation_time_remaining = regulation_seconds
	overtime_elapsed = 0.0
	is_overtime = false
	match_results_available = false
	last_winning_team = NO_TEAM
	_clear_goal_replay_state()
	_active_shot.clear()
	_cpu_ball_commitments.clear()
	_cpu_tactical_intentions.clear()
	_cpu_combination_plans.clear()
	_reset_cpu_possession_state()
	_save_check_generation += 1
	if not ranked_mode and not champions_league_mode:
		if (
			is_fun_mutator_enabled(FUN_ABILITY_DRAFT)
			or is_fun_mutator_enabled(FUN_ROTATING_LOADOUTS)
		):
			_assign_fun_draft_loadouts()
		else:
			_assign_cpu_abilities_for_match()
	_select_cpu_team_strategies()
	_initialize_match_statistics()
	_select_new_field_variant()
	game_has_started = true
	_apply_fun_mutator_runtime()
	round_resetting = true
	_human_demo_sample_accumulator = 0.0
	_human_demo_recent_completed_passes.clear()
	_reset_cpu_benchmark_metrics()
	_begin_human_demonstration_recording()
	_timer_sync_accumulator = 0.0
	_ready_players.clear()

	_prepare_all_abilities_for_kickoff()

	refresh_roster()
	_broadcast_score()
	_broadcast_tournament_tiebreak_state()
	_broadcast_timer()
	_broadcast_match_started()
	_set_all_players_enabled(false)
	if ball != null:
		ball.set_play_enabled(false)
	if cpu_training_mode:
		_start_reset_countdown(true)
	elif champions_league_mode and _draft_matchup_introduction_complete:
		# Draft presents the matchup before the first hand is dealt. Do not show
		# the same overview again between the perk pick and kickoff.
		_start_reset_countdown(true)
	else:
		_start_team_introduction()
	return true


func _assign_cpu_abilities_for_match() -> void:
	_assign_cpu_team_abilities(blue_players)
	_assign_cpu_team_abilities(red_players)


func _assign_cpu_team_abilities(
	team_players: Array[FootballPlayer]
) -> void:
	if is_fun_mutator_enabled(FUN_DUPLICATE_ABILITIES):
		for player: FootballPlayer in team_players:
			if not is_instance_valid(player) or not player.cpu_controlled:
				continue
			var selected: int = _get_cpu_ability_preference(
				player.team,
				player.team_slot
			)
			if selected == CPU_ABILITY_RANDOM or selected == FootballPlayer.ABILITY_META_VISION:
				selected = _draw_random_cpu_ability({})
			player.set_selected_ability(selected)
		return
	var used: Dictionary = {}
	for player in team_players:
		if (
			is_instance_valid(player)
			and not player.cpu_controlled
			and player.selected_ability != FootballPlayer.ABILITY_NONE
		):
			used[player.selected_ability] = true

	var cpu_players: Array[FootballPlayer] = []
	for player in team_players:
		if is_instance_valid(player) and player.cpu_controlled:
			cpu_players.append(player)
	cpu_players.sort_custom(
		func(first: FootballPlayer, second: FootballPlayer) -> bool:
			return first.team_slot < second.team_slot
	)

	var random_cpus: Array[FootballPlayer] = []
	for cpu in cpu_players:
		var selected := _get_cpu_ability_preference(cpu.team, cpu.team_slot)
		if selected == FootballPlayer.ABILITY_META_VISION:
			selected = CPU_ABILITY_RANDOM
		if selected == CPU_ABILITY_RANDOM:
			random_cpus.append(cpu)
			continue
		if (
			selected != FootballPlayer.ABILITY_NONE
			and used.has(selected)
		):
			random_cpus.append(cpu)
			continue
		cpu.set_selected_ability(selected)
		if selected != FootballPlayer.ABILITY_NONE:
			used[selected] = true

	var combo_package := _choose_cpu_combo_package(
		team_players,
		used,
		random_cpus.size()
	)
	var combo_chance := clampf(
		(float(cpu_ai_level) - 8.0) / 7.0,
		0.0,
		1.0
	)
	for cpu in random_cpus:
		var selected := FootballPlayer.ABILITY_NONE
		if _cpu_ability_rng.randf() <= combo_chance:
			selected = _draw_combo_cpu_ability(combo_package, used)
		if selected == FootballPlayer.ABILITY_NONE:
			selected = _draw_random_cpu_ability(used)
		cpu.set_selected_ability(selected)
		if selected != FootballPlayer.ABILITY_NONE:
			used[selected] = true


func _choose_cpu_combo_package(
	team_players: Array[FootballPlayer],
	used: Dictionary,
	random_cpu_count: int
) -> Array[int]:
	var packages: Array[Array] = [
		[
			FootballPlayer.ABILITY_TIME_SKIP_PASS,
			FootballPlayer.ABILITY_DIRECT_FINISH,
			FootballPlayer.ABILITY_OVERDRIVE,
			FootballPlayer.ABILITY_IRON_ANCHOR
		],
		[
			FootballPlayer.ABILITY_ENFORCER,
			FootballPlayer.ABILITY_POWER_STRIKE,
			FootballPlayer.ABILITY_META_VISION,
			FootballPlayer.ABILITY_REFLEX_BLOCK
		],
		[
			FootballPlayer.ABILITY_ELASTIC_STEP,
			FootballPlayer.ABILITY_BLIND_SPOT,
			FootballPlayer.ABILITY_QUICK_TRIGGER,
			FootballPlayer.ABILITY_GOALKEEPER_REACH
		],
		[
			FootballPlayer.ABILITY_HEEL_TURN,
			FootballPlayer.ABILITY_BURST_DRIBBLE,
			FootballPlayer.ABILITY_POWER_STRIKE,
			FootballPlayer.ABILITY_IRON_ANCHOR
		],
		[
			FootballPlayer.ABILITY_QUICK_TRIGGER,
			FootballPlayer.ABILITY_DIRECT_FINISH,
			FootballPlayer.ABILITY_OVERDRIVE,
			FootballPlayer.ABILITY_REFLEX_BLOCK
		],
		[
			FootballPlayer.ABILITY_BURST_DRIBBLE,
			FootballPlayer.ABILITY_TIME_SKIP_PASS,
			FootballPlayer.ABILITY_POWER_STRIKE,
			FootballPlayer.ABILITY_GOALKEEPER_REACH
		],
		[
			FootballPlayer.ABILITY_BLIND_SPOT,
			FootballPlayer.ABILITY_ELASTIC_STEP,
			FootballPlayer.ABILITY_OVERDRIVE,
			FootballPlayer.ABILITY_IRON_ANCHOR
		],
		[
			FootballPlayer.ABILITY_POWER_STRIKE,
			FootballPlayer.ABILITY_HEEL_TURN,
			FootballPlayer.ABILITY_META_VISION,
			FootballPlayer.ABILITY_REFLEX_BLOCK
		],
		[
			FootballPlayer.ABILITY_DIRECT_FINISH,
			FootballPlayer.ABILITY_QUICK_TRIGGER,
			FootballPlayer.ABILITY_ENFORCER,
			FootballPlayer.ABILITY_GOALKEEPER_REACH
		],
		[
			FootballPlayer.ABILITY_OVERDRIVE,
			FootballPlayer.ABILITY_TIME_SKIP_PASS,
			FootballPlayer.ABILITY_BURST_DRIBBLE,
			FootballPlayer.ABILITY_IRON_ANCHOR
		],
		[
			FootballPlayer.ABILITY_ELASTIC_STEP,
			FootballPlayer.ABILITY_POWER_STRIKE,
			FootballPlayer.ABILITY_COPYCAT,
			FootballPlayer.ABILITY_REFLEX_BLOCK
		],
		[
			FootballPlayer.ABILITY_BLIND_SPOT,
			FootballPlayer.ABILITY_QUICK_TRIGGER,
			FootballPlayer.ABILITY_DIRECT_FINISH,
			FootballPlayer.ABILITY_GOALKEEPER_REACH
		],
		[
			FootballPlayer.ABILITY_BURST_DRIBBLE,
			FootballPlayer.ABILITY_HEEL_TURN,
			FootballPlayer.ABILITY_META_VISION,
			FootballPlayer.ABILITY_ENFORCER
		],
		[
			FootballPlayer.ABILITY_POWER_STRIKE,
			FootballPlayer.ABILITY_TIME_SKIP_PASS,
			FootballPlayer.ABILITY_OVERDRIVE,
			FootballPlayer.ABILITY_REFLEX_BLOCK
		],
		[
			FootballPlayer.ABILITY_DIRECT_FINISH,
			FootballPlayer.ABILITY_ELASTIC_STEP,
			FootballPlayer.ABILITY_COPYCAT,
			FootballPlayer.ABILITY_IRON_ANCHOR
		],
		[
			FootballPlayer.ABILITY_QUICK_TRIGGER,
			FootballPlayer.ABILITY_HEEL_TURN,
			FootballPlayer.ABILITY_BURST_DRIBBLE,
			FootballPlayer.ABILITY_GOALKEEPER_REACH
		],
		[
			FootballPlayer.ABILITY_OVERDRIVE,
			FootballPlayer.ABILITY_META_VISION,
			FootballPlayer.ABILITY_ENFORCER,
			FootballPlayer.ABILITY_IRON_ANCHOR
		],
		[
			FootballPlayer.ABILITY_BLIND_SPOT,
			FootballPlayer.ABILITY_TIME_SKIP_PASS,
			FootballPlayer.ABILITY_POWER_STRIKE,
			FootballPlayer.ABILITY_REFLEX_BLOCK
		],
		[
			FootballPlayer.ABILITY_BURST_DRIBBLE,
			FootballPlayer.ABILITY_QUICK_TRIGGER,
			FootballPlayer.ABILITY_COPYCAT,
			FootballPlayer.ABILITY_GOALKEEPER_REACH
		],
		[
			FootballPlayer.ABILITY_DIRECT_FINISH,
			FootballPlayer.ABILITY_HEEL_TURN,
			FootballPlayer.ABILITY_OVERDRIVE,
			FootballPlayer.ABILITY_IRON_ANCHOR
		],
		[
			FootballPlayer.ABILITY_POWER_STRIKE,
			FootballPlayer.ABILITY_ELASTIC_STEP,
			FootballPlayer.ABILITY_META_VISION,
			FootballPlayer.ABILITY_GOALKEEPER_REACH
		],
		[
			FootballPlayer.ABILITY_BLIND_SPOT,
			FootballPlayer.ABILITY_HEEL_TURN,
			FootballPlayer.ABILITY_ENFORCER,
			FootballPlayer.ABILITY_REFLEX_BLOCK
		],
		[
			FootballPlayer.ABILITY_BURST_DRIBBLE,
			FootballPlayer.ABILITY_TIME_SKIP_PASS,
			FootballPlayer.ABILITY_DIRECT_FINISH,
			FootballPlayer.ABILITY_IRON_ANCHOR
		],
		[
			FootballPlayer.ABILITY_QUICK_TRIGGER,
			FootballPlayer.ABILITY_OVERDRIVE,
			FootballPlayer.ABILITY_COPYCAT,
			FootballPlayer.ABILITY_GOALKEEPER_REACH
		],
		[
			FootballPlayer.ABILITY_POWER_STRIKE,
			FootballPlayer.ABILITY_BLIND_SPOT,
			FootballPlayer.ABILITY_TIME_SKIP_PASS,
			FootballPlayer.ABILITY_IRON_ANCHOR
		],
		[
			FootballPlayer.ABILITY_DIRECT_FINISH,
			FootballPlayer.ABILITY_META_VISION,
			FootballPlayer.ABILITY_OVERDRIVE,
			FootballPlayer.ABILITY_REFLEX_BLOCK
		],
		[
			FootballPlayer.ABILITY_BURST_DRIBBLE,
			FootballPlayer.ABILITY_ELASTIC_STEP,
			FootballPlayer.ABILITY_ENFORCER,
			FootballPlayer.ABILITY_GOALKEEPER_REACH
		],
		[
			FootballPlayer.ABILITY_QUICK_TRIGGER,
			FootballPlayer.ABILITY_HEEL_TURN,
			FootballPlayer.ABILITY_COPYCAT,
			FootballPlayer.ABILITY_IRON_ANCHOR
		]
	]
	var best_package: Array[int] = []
	var best_score := -INF
	for package_variant in packages:
		var package: Array = package_variant
		var score := _cpu_ability_rng.randf_range(0.0, 2.0)
		for ability_variant in package:
			var ability_id := int(ability_variant)
			if used.has(ability_id):
				score += 18.0
			else:
				score += 9.0
		for player in team_players:
			if (
				is_instance_valid(player)
				and player.selected_ability in package
			):
				score += 14.0
		if score > best_score:
			best_score = score
			best_package.clear()
			for ability_variant in package:
				best_package.append(int(ability_variant))
	_shuffle_cpu_ints(best_package)
	if random_cpu_count >= 2 and not _used_has_defensive_cpu_ability(used):
		_move_available_defender_to_front(best_package, used)
	return best_package


func _used_has_defensive_cpu_ability(used: Dictionary) -> bool:
	for ability_variant in used.keys():
		if _is_cpu_defensive_ability(int(ability_variant)):
			return true
	return false


func _move_available_defender_to_front(
	combo_package: Array[int],
	used: Dictionary
) -> void:
	for index in range(combo_package.size()):
		var ability_id := combo_package[index]
		if used.has(ability_id) or not _is_cpu_defensive_ability(ability_id):
			continue
		combo_package.remove_at(index)
		combo_package.push_front(ability_id)
		return


func _is_cpu_defensive_ability(ability_id: int) -> bool:
	return (
		FootballPlayer.get_ability_role(ability_id)
		== FootballPlayer.ABILITY_ROLE_DEFENSE
	)


func _draw_combo_cpu_ability(
	combo_package: Array[int],
	used: Dictionary
) -> int:
	for ability_id in combo_package:
		if ability_id == FootballPlayer.ABILITY_META_VISION:
			continue
		if not used.has(ability_id):
			return ability_id
	return FootballPlayer.ABILITY_NONE


func _select_cpu_team_strategies() -> void:
	if ladder_mode:
		_cpu_team_strategies[ladder_human_team] = _choose_cpu_team_strategy(
			blue_players if ladder_human_team == TEAM_BLUE else red_players
		)
		_cpu_team_strategies[ladder_cpu_team] = StringName(
			ladder_encounter.get("strategy", CPU_STRATEGY_BALANCED)
		)
		_apply_ladder_cpu_profiles()
	else:
		_cpu_team_strategies[TEAM_BLUE] = _choose_cpu_team_strategy(blue_players)
		_cpu_team_strategies[TEAM_RED] = _choose_cpu_team_strategy(red_players)
	_reset_cpu_strategy_adaptation()


func _choose_cpu_team_strategy(
	team_players: Array[FootballPlayer]
) -> StringName:
	if cpu_ai_level <= 3:
		return CPU_STRATEGY_BALANCED
	var abilities: Dictionary = {}
	for player in team_players:
		if is_instance_valid(player):
			abilities[player.selected_ability] = true
	var has_finishing_combo := (
		abilities.has(FootballPlayer.ABILITY_DIRECT_FINISH)
		and (
			abilities.has(FootballPlayer.ABILITY_TIME_SKIP_PASS)
			or abilities.has(FootballPlayer.ABILITY_QUICK_TRIGGER)
			or abilities.has(FootballPlayer.ABILITY_META_VISION)
		)
	)
	var has_power_distribution_combo := (
		abilities.has(FootballPlayer.ABILITY_POWER_STRIKE)
		and abilities.has(FootballPlayer.ABILITY_DIRECT_FINISH)
	)
	var has_breakaway_combo := (
		abilities.has(FootballPlayer.ABILITY_OVERDRIVE)
		and (
			abilities.has(FootballPlayer.ABILITY_TIME_SKIP_PASS)
			or abilities.has(FootballPlayer.ABILITY_IRON_ANCHOR)
			or abilities.has(FootballPlayer.ABILITY_REFLEX_BLOCK)
		)
	)
	var has_pressure_combo := (
		abilities.has(FootballPlayer.ABILITY_ENFORCER)
		and (
			abilities.has(FootballPlayer.ABILITY_BURST_DRIBBLE)
			or abilities.has(FootballPlayer.ABILITY_POWER_STRIKE)
			or abilities.has(FootballPlayer.ABILITY_BLIND_SPOT)
		)
	)
	if cpu_ai_level >= 10 and has_power_distribution_combo:
		return CPU_STRATEGY_ABILITY_COMBO
	if cpu_ai_level >= 11 and has_finishing_combo:
		return CPU_STRATEGY_ABILITY_COMBO
	if cpu_ai_level >= 10 and has_breakaway_combo:
		return CPU_STRATEGY_COUNTER
	if cpu_ai_level >= 10 and has_pressure_combo:
		return CPU_STRATEGY_HIGH_PRESS
	var available: Array[StringName] = [CPU_STRATEGY_BALANCED]
	if cpu_ai_level >= 4:
		available.append(CPU_STRATEGY_DIRECT)
		available.append(CPU_STRATEGY_COUNTER)
	if cpu_ai_level >= 7:
		available.append(CPU_STRATEGY_POSSESSION)
		available.append(CPU_STRATEGY_HIGH_PRESS)
	if cpu_ai_level >= 10:
		available.append(CPU_STRATEGY_WALL_PLAY)
	if cpu_ai_level >= 13:
		available.append(CPU_STRATEGY_ABILITY_COMBO)
	return available[_cpu_ability_rng.randi_range(0, available.size() - 1)]


func get_cpu_team_strategy(team: StringName) -> StringName:
	return StringName(
		_cpu_team_strategies.get(team, CPU_STRATEGY_BALANCED)
	)


func _reset_cpu_strategy_adaptation() -> void:
	_cpu_strategy_adaptation.clear()
	var now := Time.get_ticks_msec() / 1000.0
	var ball_x := ball.global_position.x if is_instance_valid(ball) else 0.0
	var possession := get_cpu_possession_team()
	for team in [TEAM_BLUE, TEAM_RED]:
		_cpu_strategy_adaptation[team] = {
			"sample_ball_x": ball_x,
			"sample_possession": possession,
			"next_evaluation_at": now + maxf(
				1.0,
				cpu_strategy_evaluation_seconds
			),
			"next_switch_at": now + maxf(
				1.0,
				cpu_strategy_switch_cooldown_seconds
			),
			"attack_failures": 0,
			"defense_failures": 0,
			"last_strategy": StringName(),
			"last_switch_reason": StringName(),
			"strategy_failures": {},
			"attack_windows": 0,
			"attack_successes": 0,
			"defense_windows": 0,
			"defense_successes": 0
		}


func _update_cpu_strategy_adaptation() -> void:
	if (
		cpu_ai_level < cpu_strategy_adaptation_minimum_level
		or not is_instance_valid(ball)
	):
		return
	if _cpu_strategy_adaptation.is_empty():
		_reset_cpu_strategy_adaptation()
	var now := Time.get_ticks_msec() / 1000.0
	var possession := get_cpu_possession_team()
	for team in [TEAM_BLUE, TEAM_RED]:
		var state: Dictionary = _cpu_strategy_adaptation.get(team, {})
		if state.is_empty() or now < float(state.get("next_evaluation_at", 0.0)):
			continue
		_evaluate_cpu_strategy_window(team, state, possession, now)
		_cpu_strategy_adaptation[team] = state


func _resample_cpu_strategy_adaptation() -> void:
	if _cpu_strategy_adaptation.is_empty() or not is_instance_valid(ball):
		return
	var now := Time.get_ticks_msec() / 1000.0
	var possession := get_cpu_possession_team()
	for team in [TEAM_BLUE, TEAM_RED]:
		var state: Dictionary = _cpu_strategy_adaptation.get(team, {})
		if state.is_empty():
			continue
		state["sample_ball_x"] = ball.global_position.x
		state["sample_possession"] = possession
		state["next_evaluation_at"] = now + maxf(
			1.0,
			cpu_strategy_evaluation_seconds
		)
		_cpu_strategy_adaptation[team] = state


func _evaluate_cpu_strategy_window(
	team: StringName,
	state: Dictionary,
	possession: StringName,
	now: float
) -> void:
	var opponent := TEAM_RED if team == TEAM_BLUE else TEAM_BLUE
	var attack_sign := 1.0 if team == TEAM_BLUE else -1.0
	var sample_ball_x := float(
		state.get("sample_ball_x", ball.global_position.x)
	)
	var forward_progress := (
		ball.global_position.x - sample_ball_x
	) * attack_sign
	var sample_possession := StringName(
		state.get("sample_possession", NO_TEAM)
	)
	var field_progress := _get_cpu_attack_field_progress(
		team,
		ball.global_position.x
	)
	var attack_relevant := (
		sample_possession == team or possession == team
	)
	var defense_relevant := (
		sample_possession == opponent
		or possession == opponent
		or field_progress < 0.48
	)
	var attack_worked := (
		forward_progress >= maxf(80.0, cpu_attack_progress_minimum)
		or (possession == team and field_progress >= 0.68)
	)
	var defense_worked := (
		possession == team
		or forward_progress >= maxf(80.0, cpu_defense_relief_minimum)
		or field_progress >= 0.56
	)
	var attack_failures := int(state.get("attack_failures", 0))
	var defense_failures := int(state.get("defense_failures", 0))
	if attack_relevant:
		state["attack_windows"] = int(state.get("attack_windows", 0)) + 1
		if attack_worked:
			state["attack_successes"] = int(
				state.get("attack_successes", 0)
			) + 1
		attack_failures = 0 if attack_worked else attack_failures + 1
	else:
		attack_failures = maxi(0, attack_failures - 1)
	if defense_relevant:
		state["defense_windows"] = int(state.get("defense_windows", 0)) + 1
		if defense_worked:
			state["defense_successes"] = int(
				state.get("defense_successes", 0)
			) + 1
		defense_failures = 0 if defense_worked else defense_failures + 1
	else:
		defense_failures = maxi(0, defense_failures - 1)
	state["attack_failures"] = attack_failures
	state["defense_failures"] = defense_failures

	var failure_reason := StringName()
	var required_windows := maxi(1, cpu_strategy_failure_windows_required)
	if defense_failures >= required_windows and (
		possession == opponent or field_progress < 0.42
	):
		failure_reason = CPU_STRATEGY_FAILURE_DEFENSE
	elif attack_failures >= required_windows:
		failure_reason = CPU_STRATEGY_FAILURE_ATTACK
	if not failure_reason.is_empty() and now >= float(
		state.get("next_switch_at", 0.0)
	):
		_adapt_cpu_team_strategy(team, failure_reason, state, now)

	state["sample_ball_x"] = ball.global_position.x
	state["sample_possession"] = possession
	state["next_evaluation_at"] = now + maxf(
		1.0,
		cpu_strategy_evaluation_seconds
	)


func _adapt_cpu_team_strategy(
	team: StringName,
	failure_reason: StringName,
	state: Dictionary,
	now: float
) -> void:
	var current := get_cpu_team_strategy(team)
	var strategy_failures: Dictionary = state.get("strategy_failures", {})
	strategy_failures[current] = int(strategy_failures.get(current, 0)) + 1
	state["strategy_failures"] = strategy_failures
	var replacement := _choose_adaptive_cpu_team_strategy(
		team,
		failure_reason,
		state
	)
	if replacement != current:
		_cpu_team_strategies[team] = replacement
		state["last_strategy"] = current
		state["last_switch_reason"] = failure_reason
	state["attack_failures"] = 0
	state["defense_failures"] = 0
	state["next_switch_at"] = now + maxf(
		1.0,
		cpu_strategy_switch_cooldown_seconds
	)


func _choose_adaptive_cpu_team_strategy(
	team: StringName,
	failure_reason: StringName,
	state: Dictionary
) -> StringName:
	var players := blue_players if team == TEAM_BLUE else red_players
	var abilities: Dictionary = {}
	for player in players:
		if is_instance_valid(player) and player.controls_enabled:
			abilities[player.selected_ability] = true
	var candidates: Array[StringName] = [
		CPU_STRATEGY_BALANCED,
		CPU_STRATEGY_DIRECT,
		CPU_STRATEGY_COUNTER,
		CPU_STRATEGY_POSSESSION,
		CPU_STRATEGY_HIGH_PRESS
	]
	if cpu_ai_level >= 10:
		candidates.append(CPU_STRATEGY_WALL_PLAY)
	if cpu_ai_level >= 11:
		candidates.append(CPU_STRATEGY_ABILITY_COMBO)
	var current := get_cpu_team_strategy(team)
	var last_strategy := StringName(state.get("last_strategy", StringName()))
	var strategy_failures: Dictionary = state.get("strategy_failures", {})
	var best_strategy := CPU_STRATEGY_BALANCED
	var best_score := -INF
	for candidate in candidates:
		if candidate == current:
			continue
		var score := _get_adaptive_cpu_strategy_score(
			candidate,
			failure_reason,
			abilities
		)
		score -= float(strategy_failures.get(candidate, 0)) * 28.0
		if candidate == last_strategy:
			score -= 16.0
		score += _cpu_ability_rng.randf_range(0.0, 4.0)
		if score > best_score:
			best_score = score
			best_strategy = candidate
	return best_strategy


func _get_adaptive_cpu_strategy_score(
	strategy: StringName,
	failure_reason: StringName,
	abilities: Dictionary
) -> float:
	var score := 0.0
	if failure_reason == CPU_STRATEGY_FAILURE_ATTACK:
		match strategy:
			CPU_STRATEGY_DIRECT:
				score = 44.0
			CPU_STRATEGY_ABILITY_COMBO:
				score = 38.0
			CPU_STRATEGY_POSSESSION:
				score = 32.0
			CPU_STRATEGY_WALL_PLAY:
				score = 27.0
			CPU_STRATEGY_HIGH_PRESS:
				score = 21.0
			CPU_STRATEGY_COUNTER:
				score = 18.0
			_:
				score = 14.0
	else:
		match strategy:
			CPU_STRATEGY_COUNTER:
				score = 44.0
			CPU_STRATEGY_HIGH_PRESS:
				score = 40.0
			CPU_STRATEGY_POSSESSION:
				score = 30.0
			CPU_STRATEGY_BALANCED:
				score = 25.0
			CPU_STRATEGY_WALL_PLAY:
				score = 20.0
			CPU_STRATEGY_ABILITY_COMBO:
				score = 16.0
			_:
				score = 10.0

	var has_power_strike := abilities.has(FootballPlayer.ABILITY_POWER_STRIKE)
	var has_trap_or_volley := abilities.has(FootballPlayer.ABILITY_DIRECT_FINISH)
	if has_power_strike and has_trap_or_volley:
		if strategy == CPU_STRATEGY_ABILITY_COMBO:
			score += 92.0
		elif strategy == CPU_STRATEGY_DIRECT:
			score += 58.0
		elif strategy == CPU_STRATEGY_COUNTER:
			score += 38.0
	elif has_power_strike:
		if strategy == CPU_STRATEGY_DIRECT:
			score += 32.0
		elif strategy == CPU_STRATEGY_COUNTER:
			score += 22.0
	if abilities.has(FootballPlayer.ABILITY_ENFORCER):
		if strategy == CPU_STRATEGY_HIGH_PRESS:
			score += 34.0
	if (
		abilities.has(FootballPlayer.ABILITY_REFLEX_BLOCK)
		or abilities.has(FootballPlayer.ABILITY_IRON_ANCHOR)
		or abilities.has(FootballPlayer.ABILITY_GOALKEEPER_REACH)
	):
		if strategy == CPU_STRATEGY_COUNTER:
			score += 28.0
		elif strategy == CPU_STRATEGY_BALANCED:
			score += 14.0
	if abilities.has(FootballPlayer.ABILITY_META_VISION):
		if strategy == CPU_STRATEGY_POSSESSION:
			score += 32.0
		elif strategy == CPU_STRATEGY_WALL_PLAY:
			score += 14.0
	if (
		abilities.has(FootballPlayer.ABILITY_TIME_SKIP_PASS)
		or abilities.has(FootballPlayer.ABILITY_QUICK_TRIGGER)
	):
		if strategy == CPU_STRATEGY_ABILITY_COMBO:
			score += 24.0
	if (
		abilities.has(FootballPlayer.ABILITY_BREAKAWAY)
		or abilities.has(FootballPlayer.ABILITY_NUTMEG)
	):
		if strategy == CPU_STRATEGY_COUNTER:
			score += 30.0
		elif strategy == CPU_STRATEGY_DIRECT:
			score += 20.0
	if (
		abilities.has(FootballPlayer.ABILITY_SNAPBACK)
		or abilities.has(FootballPlayer.ABILITY_SIDE_SWIPE)
		or abilities.has(FootballPlayer.ABILITY_RETURN_TAG)
	):
		if strategy == CPU_STRATEGY_ABILITY_COMBO:
			score += 28.0
		elif strategy == CPU_STRATEGY_WALL_PLAY:
			score += 14.0
	if abilities.has(FootballPlayer.ABILITY_BOOGIE_WOOGIE):
		if strategy == CPU_STRATEGY_HIGH_PRESS:
			score += 18.0
		elif strategy == CPU_STRATEGY_COUNTER:
			score += 14.0
	if abilities.has(FootballPlayer.ABILITY_DECOY_RUN):
		if strategy == CPU_STRATEGY_COUNTER:
			score += 14.0
		elif strategy == CPU_STRATEGY_ABILITY_COMBO:
			score += 10.0
	return score


func _get_cpu_attack_field_progress(
	team: StringName,
	ball_x: float
) -> float:
	var left_x := 360.0
	var right_x := 6970.0
	if is_instance_valid(red_goal) and is_instance_valid(blue_goal):
		left_x = minf(red_goal.get_goal_plane_x(), blue_goal.get_goal_plane_x())
		right_x = maxf(red_goal.get_goal_plane_x(), blue_goal.get_goal_plane_x())
	var blue_progress := inverse_lerp(left_x, right_x, ball_x)
	return clampf(
		blue_progress if team == TEAM_BLUE else 1.0 - blue_progress,
		0.0,
		1.0
	)


func get_cpu_skill_ratio() -> float:
	# Do not rescale Intelligence 1-15 when extending the ceiling to 20. Existing
	# tactics that use this legacy ratio therefore behave exactly as before.
	var legacy_level: int = mini(cpu_ai_level, CPU_LEGACY_MAX_INTELLIGENCE)
	return clampf((float(legacy_level) - 1.0) / 14.0, 0.0, 1.0)


func _draw_random_cpu_ability(used: Dictionary) -> int:
	var candidates: Array[int] = []
	for category in [
		CPU_ABILITY_ATTACK,
		CPU_ABILITY_PLAYMAKER,
		CPU_ABILITY_FLEXIBLE,
		CPU_ABILITY_DEFENSE
	]:
		candidates.append_array(_get_cpu_category_pool(category))
	_shuffle_cpu_ints(candidates)
	for ability_id in candidates:
		if not used.has(ability_id):
			return ability_id
	return FootballPlayer.ABILITY_NONE


func _get_cpu_category_pool(category: int) -> Array[int]:
	match category:
		CPU_ABILITY_ATTACK:
			return FootballPlayer.get_ability_ids_for_role(
				FootballPlayer.ABILITY_ROLE_ATTACK
			)
		CPU_ABILITY_PLAYMAKER:
			var playmaker_pool := FootballPlayer.get_ability_ids_for_role(
				FootballPlayer.ABILITY_ROLE_PLAYMAKER
			)
			# Meta Vision is human-only, so never offer it to CPU players. Boogie
			# Woogie is allowed: CPU usage logic
			# already evaluates whether a swap is tactically useful.
			playmaker_pool.erase(FootballPlayer.ABILITY_META_VISION)
			return playmaker_pool
		CPU_ABILITY_FLEXIBLE:
			var flexible_pool := FootballPlayer.get_ability_ids_for_role(
				FootballPlayer.ABILITY_ROLE_FLEXIBLE
			)
			# Random CPUs should always receive an active ability.
			flexible_pool.erase(FootballPlayer.ABILITY_NONE)
			return flexible_pool
		CPU_ABILITY_DEFENSE:
			return FootballPlayer.get_ability_ids_for_role(
				FootballPlayer.ABILITY_ROLE_DEFENSE
			)
	return []


func _shuffle_cpu_ints(values: Array[int]) -> void:
	for index in range(values.size() - 1, 0, -1):
		var other := _cpu_ability_rng.randi_range(0, index)
		var temporary := values[index]
		values[index] = values[other]
		values[other] = temporary


func start_freeplay() -> bool:
	if (
		not multiplayer.is_server()
		or game_has_started
		or players_parent == null
		or ball == null
		or ball_spawn == null
	):
		return false

	var player := _get_player(multiplayer.get_unique_id())
	if player == null:
		return false

	red_players.clear()
	blue_players.clear()
	blue_players.append(player)
	_ready_players.clear()
	_player_statistics.clear()
	_active_shot.clear()
	_save_check_generation += 1
	_reset_generation += 1
	red_score = 0
	blue_score = 0
	is_overtime = false
	round_resetting = false
	match_results_available = false
	last_winning_team = NO_TEAM
	freeplay_active = true
	game_has_started = true
	_match_clock_waiting_for_kickoff = false

	player.assign_team(TEAM_BLUE, 0)
	player.set_selected_ability(
		FootballPlayer.ABILITY_BURST_DRIBBLE
	)
	player.set_freeplay_mode(true)
	var spawn := _get_player_spawn(TEAM_BLUE, 0)
	if spawn != null:
		player.reset_to_position(spawn.global_position)
	player.set_controls_enabled(true)
	_spawn_freeplay_training_dummy()

	ball.reset_ball(ball_spawn.global_position)
	ball.set_play_enabled(true)
	_broadcast_score()
	_receive_announcement.rpc("")
	_receive_countdown.rpc("")
	refresh_roster()
	freeplay_started.emit()
	freeplay_ability_changed.emit(player.selected_ability)
	return true


func stop_freeplay() -> bool:
	if not multiplayer.is_server() or not freeplay_active:
		return false

	freeplay_active = false
	game_has_started = false
	round_resetting = false
	_match_clock_waiting_for_kickoff = false
	_reset_generation += 1
	_announcement_generation += 1
	_active_shot.clear()
	_save_check_generation += 1

	var player := _get_player(multiplayer.get_unique_id())
	if player != null:
		player.set_controls_enabled(false)
		player.set_freeplay_mode(false)
		player.set_selected_ability(FootballPlayer.ABILITY_NONE)
		player.assign_team(NO_TEAM, -1)
	_remove_freeplay_training_dummy()

	red_players.clear()
	blue_players.clear()
	if ball != null:
		ball.reset_ball(ball_spawn.global_position)
		ball.set_play_enabled(false)
	_receive_announcement.rpc("")
	_receive_countdown.rpc("")
	freeplay_ended.emit()
	return true


func set_freeplay_ability(ability_id: int) -> bool:
	if not multiplayer.is_server() or not freeplay_active:
		return false

	var player := _get_player(multiplayer.get_unique_id())
	if player == null:
		return false

	var safe_ability := clampi(
		ability_id,
		FootballPlayer.ABILITY_NONE,
		FootballPlayer.ABILITY_COUNT
	)
	if (
		safe_ability == FootballPlayer.ABILITY_COPYCAT
		and player.selected_ability not in [
			FootballPlayer.ABILITY_NONE,
			FootballPlayer.ABILITY_COPYCAT,
			FootballPlayer.ABILITY_GOALKEEPER_REACH
		]
	):
		player.freeplay_copycat_source_ability = (
			player.selected_ability
		)
	player.set_selected_ability(safe_ability)
	player.set_controls_enabled(true)
	freeplay_ability_changed.emit(safe_ability)
	return true


func cycle_freeplay_ability(direction: int) -> bool:
	if not multiplayer.is_server() or not freeplay_active:
		return false

	var player := _get_player(multiplayer.get_unique_id())
	if player == null:
		return false

	var ability_id := player.selected_ability + signi(direction)
	if ability_id > FootballPlayer.ABILITY_COUNT:
		ability_id = FootballPlayer.ABILITY_NONE
	elif ability_id < FootballPlayer.ABILITY_NONE:
		ability_id = FootballPlayer.ABILITY_COUNT
	return set_freeplay_ability(ability_id)


func reset_freeplay_ball() -> bool:
	if (
		not multiplayer.is_server()
		or not freeplay_active
		or ball == null
		or ball_spawn == null
	):
		return false

	ball.reset_ball(ball_spawn.global_position)
	ball.set_play_enabled(true)
	return true


func reset_freeplay_player() -> bool:
	if not multiplayer.is_server() or not freeplay_active:
		return false

	var player := _get_player(multiplayer.get_unique_id())
	var spawn := _get_player_spawn(TEAM_BLUE, 0)
	if player == null or spawn == null:
		return false

	player.reset_to_position(spawn.global_position)
	player.set_controls_enabled(true)
	_reset_freeplay_training_dummy()
	return true


func send_freeplay_ball_at_player() -> bool:
	if (
		not multiplayer.is_server()
		or not freeplay_active
		or ball == null
	):
		return false

	var player := _get_player(multiplayer.get_unique_id())
	if player == null:
		return false

	var horizontal_side := (
		1.0
		if (
			ball_spawn == null
			or player.global_position.x <= ball_spawn.global_position.x
		)
		else -1.0
	)
	var launch_position := (
		player.global_position
		+ Vector2.RIGHT
		* horizontal_side
		* maxf(100.0, freeplay_ball_launch_distance)
	)
	launch_position.x = clampf(
		launch_position.x,
		freeplay_ball_minimum_x,
		freeplay_ball_maximum_x
	)
	launch_position.y = clampf(
		player.global_position.y,
		freeplay_ball_minimum_y,
		freeplay_ball_maximum_y
	)
	var launch_direction := launch_position.direction_to(
		player.global_position
	)
	if launch_direction.is_zero_approx():
		return false

	ball.redirect_ball(
		launch_position,
		launch_direction * maxf(0.0, freeplay_ball_launch_speed),
		0,
		"Training Launcher",
		TEAM_RED
	)
	ball.set_play_enabled(true)
	return true


func _spawn_freeplay_training_dummy() -> void:
	if (
		not multiplayer.is_server()
		or players_parent == null
		or training_dummy_scene == null
		or is_instance_valid(_freeplay_training_dummy)
	):
		return

	var dummy := training_dummy_scene.instantiate() as FootballPlayer
	if dummy == null:
		push_warning("The freeplay training dummy scene is not a FootballPlayer.")
		return

	dummy.name = "FreeplayTrainingDummy"
	dummy.owner_peer_id = 0
	dummy.display_name = "Training Dummy"
	dummy.training_dummy = true
	players_parent.add_child(dummy, true)
	dummy.assign_team(TEAM_RED, 0)
	dummy.set_selected_ability(FootballPlayer.ABILITY_NONE)
	dummy.set_controls_enabled(false)
	_freeplay_training_dummy = dummy
	_reset_freeplay_training_dummy()


func _reset_freeplay_training_dummy() -> void:
	if not is_instance_valid(_freeplay_training_dummy):
		return

	var dummy_position := (
		ball_spawn.global_position
		+ freeplay_dummy_offset_from_ball
		if ball_spawn != null
		else Vector2(4400.0, 2480.0)
	)
	_freeplay_training_dummy.reset_to_position(dummy_position)
	_freeplay_training_dummy.set_controls_enabled(false)


func _remove_freeplay_training_dummy() -> void:
	if not is_instance_valid(_freeplay_training_dummy):
		_freeplay_training_dummy = null
		return
	_freeplay_training_dummy.queue_free()
	_freeplay_training_dummy = null


# ================================================================
# TIMER AND OVERTIME
# ================================================================

func _finish_regulation() -> void:
	if (
		not multiplayer.is_server()
		or not game_has_started
		or freeplay_active
	):
		return

	regulation_time_remaining = 0.0
	if tournament_mode and tournament_tiebreak_phase == TIEBREAK_NONE:
		_finish_tournament_leg()
		return

	if red_score == blue_score:
		is_overtime = true
		overtime_elapsed = 0.0
		_broadcast_timer()
		_show_announcement("OVERTIME - Golden Goal", 3.0)
	elif red_score > blue_score:
		end_match(TEAM_RED)
	else:
		end_match(TEAM_BLUE)


func _finish_tournament_leg() -> void:
	if not multiplayer.is_server() or not game_has_started:
		return
	round_resetting = true
	_set_all_players_enabled(false)
	if ball != null:
		ball.set_play_enabled(false)
	if tournament_leg == 1:
		_start_tournament_halftime()
		return
	if red_score == blue_score:
		_start_tournament_extra_time()
		return
	end_match(TEAM_RED if red_score > blue_score else TEAM_BLUE)


func _start_tournament_extra_time() -> void:
	if not multiplayer.is_server() or not game_has_started:
		return
	if ranked_mode and not _ranked_overtime_draft_complete:
		tournament_sudden_death = true
		is_overtime = true
		round_resetting = true
		_set_all_players_enabled(false)
		if ball != null:
			ball.set_play_enabled(false)
		_start_ranked_draft(RANKED_STAGE_EXTRA_TIME)
		return
	tournament_sudden_death = true
	is_overtime = true
	overtime_elapsed = 0.0
	penalty_shootout_active = false
	penalty_attempt_active = false
	penalty_attempt_time_remaining = 0.0
	tournament_tiebreak_phase = TIEBREAK_EXTRA_BREAK
	tournament_extra_time_period = 0
	tournament_extra_time_remaining = maxf(
		0.0,
		tournament_pre_extra_time_break_seconds
	)
	_show_announcement("AGGREGATE TIED - EXTRA TIME", 3.0)
	_broadcast_score()
	_broadcast_tournament_tiebreak_state()
	_broadcast_timer()
	_tiebreak_generation += 1
	_run_extra_time_break(_tiebreak_generation)


func _get_extra_time_period_seconds() -> float:
	if ranked_mode:
		return maxf(1.0, ranked_total_extra_time_seconds * 0.5)
	return maxf(
		maxf(1.0, tournament_extra_time_minimum_seconds),
		regulation_seconds
		* maxf(0.01, tournament_extra_time_period_ratio)
	)


func _finish_tournament_extra_time_period() -> void:
	if (
		not multiplayer.is_server()
		or not game_has_started
		or tournament_tiebreak_phase != TIEBREAK_EXTRA_TIME
	):
		return
	tournament_extra_time_remaining = 0.0
	round_resetting = true
	_match_clock_waiting_for_kickoff = false
	_set_all_players_enabled(false)
	if ball != null:
		ball.set_play_enabled(false)
	if tournament_extra_time_period < 2:
		_start_extra_time_break()
		return
	if red_score != blue_score:
		end_match(TEAM_RED if red_score > blue_score else TEAM_BLUE)
		return
	_start_penalty_shootout()


func _start_extra_time_break() -> void:
	_tiebreak_generation += 1
	var generation := _tiebreak_generation
	tournament_tiebreak_phase = TIEBREAK_EXTRA_BREAK
	tournament_extra_time_remaining = maxf(
		0.0,
		tournament_extra_time_break_seconds
	)
	_show_announcement("EXTRA-TIME BREAK", 2.0)
	_broadcast_tournament_tiebreak_state()
	_broadcast_timer()
	_run_extra_time_break(generation)


func _run_extra_time_break(generation: int) -> void:
	while (
		generation == _tiebreak_generation
		and game_has_started
		and tournament_tiebreak_phase == TIEBREAK_EXTRA_BREAK
		and tournament_extra_time_remaining > 0.0
	):
		await get_tree().create_timer(1.0).timeout
		if generation != _tiebreak_generation:
			return
		tournament_extra_time_remaining = maxf(
			0.0,
			tournament_extra_time_remaining - 1.0
		)
		_broadcast_timer()
	if generation != _tiebreak_generation or not game_has_started:
		return
	_begin_tournament_extra_time_period(
		1 if tournament_extra_time_period <= 0 else 2
	)


func _begin_tournament_extra_time_period(period: int) -> void:
	tournament_tiebreak_phase = TIEBREAK_EXTRA_TIME
	tournament_extra_time_period = clampi(period, 1, 2)
	tournament_extra_time_remaining = _get_extra_time_period_seconds()
	_show_announcement(
		"EXTRA TIME - PERIOD %d OF 2" % tournament_extra_time_period,
		3.0
	)
	_broadcast_tournament_tiebreak_state()
	_broadcast_timer()
	_prepare_all_abilities_for_kickoff()
	_start_reset_countdown(true)


func _start_tournament_halftime() -> void:
	if not multiplayer.is_server() or tournament_halftime_active:
		return
	_halftime_generation += 1
	var generation := _halftime_generation
	tournament_halftime_active = true
	if champions_league_mode:
		tournament_halftime_remaining = maxi(
			0,
			int(ceil(tournament_halftime_seconds))
		)
		_receive_halftime_state.rpc(true, tournament_halftime_remaining)
		_run_tournament_halftime(generation)
		return
	if ranked_mode:
		tournament_halftime_remaining = (
			maxi(1, ranked_vote_seconds) * 4
			+ maxi(1, ranked_pick_seconds)
		)
		_receive_halftime_state.rpc(true, tournament_halftime_remaining)
		_start_ranked_draft(RANKED_STAGE_GAME_TWO)
		return
	_adapt_cpu_abilities_for_second_leg()
	tournament_halftime_remaining = maxi(
		0,
		int(ceil(tournament_halftime_seconds))
	)
	_receive_halftime_state.rpc(
		true,
		tournament_halftime_remaining
	)
	_run_tournament_halftime(generation)


func _run_tournament_halftime(generation: int) -> void:
	while (
		generation == _halftime_generation
		and tournament_halftime_active
		and tournament_halftime_remaining > 0
		and game_has_started
	):
		await get_tree().create_timer(1.0).timeout
		if generation != _halftime_generation:
			return
		tournament_halftime_remaining = maxi(
			0,
			tournament_halftime_remaining - 1
		)
		_receive_halftime_state.rpc(
			true,
			tournament_halftime_remaining
		)
	if (
		generation != _halftime_generation
		or not game_has_started
	):
		return
	_complete_tournament_halftime()


func _complete_tournament_halftime() -> void:
	if not multiplayer.is_server() or not game_has_started:
		return
	if champions_league_mode:
		tournament_halftime_active = false
		tournament_halftime_remaining = 0
		_receive_halftime_state.rpc(false, 0)
		_start_draft_phase(DRAFT_STAGE_LEG_TWO)
		return
	_begin_tournament_leg_two()


func _begin_tournament_leg_two() -> void:
	tournament_halftime_active = false
	tournament_halftime_remaining = 0
	_receive_halftime_state.rpc(false, 0)
	tournament_leg = 2
	tournament_leg_red_goals = 0
	tournament_leg_blue_goals = 0
	regulation_time_remaining = regulation_seconds
	overtime_elapsed = 0.0
	is_overtime = false
	_ranked_overtime_draft_complete = false
	_select_cpu_team_strategies()
	_select_new_field_variant()
	_show_announcement(
		"SECOND LEG - Aggregate Red %d : %d Blue" % [red_score, blue_score],
		3.0
	)
	_broadcast_score()
	_broadcast_timer()
	_prepare_all_abilities_for_kickoff()
	_start_reset_countdown()


@rpc("authority", "call_local", "reliable")
func _receive_halftime_state(
	active: bool,
	seconds_remaining: int
) -> void:
	tournament_halftime_active = active
	tournament_halftime_remaining = maxi(0, seconds_remaining)
	halftime_changed.emit(
		tournament_halftime_active,
		tournament_halftime_remaining
	)


func _start_penalty_shootout() -> void:
	if not multiplayer.is_server() or not game_has_started:
		return
	_tiebreak_generation += 1
	tournament_tiebreak_phase = TIEBREAK_PENALTIES
	tournament_extra_time_remaining = 0.0
	penalty_shootout_active = true
	penalty_red_score = 0
	penalty_blue_score = 0
	penalty_red_attempts = 0
	penalty_blue_attempts = 0
	penalty_attempt_active = false
	penalty_attempt_time_remaining = 0.0
	_penalty_attempt_clock_started = false
	_penalty_ball_start_position = Vector2.ZERO
	penalty_kicker_peer_id = 0
	penalty_goalkeeper_peer_id = 0
	penalty_attempt_serial = 0
	_last_penalty_kicker_peer_by_team.clear()
	if ranked_mode:
		for team in [TEAM_BLUE, TEAM_RED]:
			var selected_goalkeeper := _select_penalty_goalkeeper(team)
			if selected_goalkeeper != null:
				_ranked_penalty_goalkeepers[team] = selected_goalkeeper.owner_peer_id
		_clear_all_selected_abilities()
		refresh_roster()
	_penalty_first_team = (
		TEAM_BLUE if _cpu_ability_rng.randi_range(0, 1) == 0 else TEAM_RED
	)
	penalty_turn = _penalty_first_team
	round_resetting = true
	_set_all_players_enabled(false)
	if ball != null:
		ball.set_play_enabled(false)
	_show_announcement("PENALTY SHOOTOUT", 2.5)
	_broadcast_tournament_tiebreak_state()
	_broadcast_timer()
	_begin_penalty_attempt_after_delay()


func _begin_penalty_attempt_after_delay() -> void:
	var generation := _tiebreak_generation
	await get_tree().create_timer(1.5).timeout
	if (
		generation != _tiebreak_generation
		or not game_has_started
		or not penalty_shootout_active
	):
		return
	_begin_penalty_attempt()


func _begin_penalty_attempt() -> void:
	if (
		not multiplayer.is_server()
		or not game_has_started
		or not penalty_shootout_active
	):
		return
	_tiebreak_generation += 1
	var generation := _tiebreak_generation
	round_resetting = true
	penalty_attempt_active = false
	penalty_attempt_time_remaining = 0.0
	_penalty_attempt_clock_started = false
	_penalty_ball_start_position = Vector2.ZERO
	_set_all_players_enabled(false)
	var kicker := _select_penalty_kicker(penalty_turn)
	var defending_team := (
		TEAM_RED if penalty_turn == TEAM_BLUE else TEAM_BLUE
	)
	var goalkeeper := _select_penalty_goalkeeper(defending_team)
	if kicker == null:
		end_match(defending_team)
		return
	if goalkeeper == null:
		end_match(penalty_turn)
		return
	penalty_kicker_peer_id = kicker.owner_peer_id
	penalty_goalkeeper_peer_id = goalkeeper.owner_peer_id
	penalty_attempt_serial += 1
	_setup_penalty_positions(kicker, goalkeeper)
	if ball != null:
		_penalty_ball_start_position = ball.global_position
	var team_name := "BLUE" if penalty_turn == TEAM_BLUE else "RED"
	_show_announcement(
		"%s PENALTY - %s" % [team_name, kicker.display_name],
		2.0
	)
	_broadcast_tournament_tiebreak_state()
	_broadcast_timer()
	_run_penalty_countdown(generation)


func _run_penalty_countdown(generation: int) -> void:
	for number in range(maxi(1, penalty_countdown_seconds), 0, -1):
		if (
			generation != _tiebreak_generation
			or not game_has_started
			or not penalty_shootout_active
		):
			return
		_receive_countdown.rpc(str(number))
		await get_tree().create_timer(1.0).timeout
	if generation != _tiebreak_generation or not game_has_started:
		return
	_receive_countdown.rpc("SHOOT")
	penalty_attempt_active = true
	penalty_attempt_time_remaining = maxf(1.0, penalty_attempt_seconds)
	_penalty_attempt_clock_started = false
	if ball != null:
		_penalty_ball_start_position = ball.global_position
	round_resetting = false
	_set_penalty_participants_enabled(true)
	if ball != null:
		ball.set_play_enabled(true)
	_broadcast_tournament_tiebreak_state()
	_broadcast_timer()
	await get_tree().create_timer(0.75).timeout
	if generation == _tiebreak_generation:
		_receive_countdown.rpc("")


func _penalty_ball_has_moved_from_start() -> bool:
	if ball == null:
		return false
	return ball.global_position.distance_to(_penalty_ball_start_position) >= maxf(
		1.0,
		penalty_ball_move_start_threshold
	)


func _setup_penalty_positions(
	kicker: FootballPlayer,
	goalkeeper: FootballPlayer
) -> void:
	# The defending player should always have the dedicated save tool during a
	# shootout, regardless of their normal/drafted ability. Restore the previous
	# attempt's keeper first because that player may now be this attempt's kicker.
	_restore_penalty_goalkeeper_reach_override()
	_enable_penalty_goalkeeper_reach(goalkeeper)
	var target_goal := _target_goal_for_team(penalty_turn)
	if target_goal == null or ball == null:
		return
	var mouth_range := target_goal.get_mouth_y_range()
	var center_y := (mouth_range.x + mouth_range.y) * 0.5
	var goal_x := target_goal.get_goal_plane_x()
	var attack_direction := 1.0 if penalty_turn == TEAM_BLUE else -1.0
	var penalty_spot := Vector2(
		goal_x - attack_direction * maxf(300.0, penalty_spot_distance_from_goal),
		center_y
	)
	var kicker_position := penalty_spot - Vector2(
		attack_direction * maxf(
			120.0,
			ranked_penalty_kicker_distance_from_ball
			if ranked_mode
			else penalty_kicker_distance_from_ball
		),
		0.0
	)
	# Start the defender just inside the goal rather than out in front of the
	# line. This gives the player the full goal mouth to react across and makes
	# Goalkeeper's Reach a real save option instead of requiring a pre-guess.
	var goalkeeper_position := Vector2(
		goal_x + attack_direction * maxf(
			40.0,
			penalty_goalkeeper_distance_from_line
		),
		center_y
	)
	var staging_index := 0
	for player in _get_all_match_players():
		if player == kicker:
			player.reset_to_position(kicker_position)
		elif player == goalkeeper:
			player.reset_to_position(goalkeeper_position)
		else:
			var staging_x := 800.0 + float(staging_index) * 420.0
			player.reset_to_position(Vector2(staging_x, penalty_staging_y))
			staging_index += 1
	ball.reset_ball(penalty_spot)
	ball.set_play_enabled(false)


func _enable_penalty_goalkeeper_reach(goalkeeper: FootballPlayer) -> void:
	if goalkeeper == null or not multiplayer.is_server():
		return
	var peer_id := goalkeeper.owner_peer_id
	if peer_id <= 0:
		return
	_penalty_goalkeeper_original_abilities[peer_id] = goalkeeper.selected_ability
	_penalty_reach_override_peer_id = peer_id
	goalkeeper.set_selected_ability(FootballPlayer.ABILITY_GOALKEEPER_REACH)


func _restore_penalty_goalkeeper_reach_override() -> void:
	if not multiplayer.is_server() or _penalty_reach_override_peer_id <= 0:
		return
	var peer_id := _penalty_reach_override_peer_id
	_penalty_reach_override_peer_id = 0
	var original_ability := int(
		_penalty_goalkeeper_original_abilities.get(
			peer_id,
			FootballPlayer.ABILITY_NONE
		)
	)
	_penalty_goalkeeper_original_abilities.erase(peer_id)
	var player := _get_player(peer_id)
	if player != null:
		player.set_selected_ability(original_ability)


func _get_all_match_players() -> Array[FootballPlayer]:
	var result: Array[FootballPlayer] = []
	for player in blue_players:
		if is_instance_valid(player):
			result.append(player)
	for player in red_players:
		if is_instance_valid(player):
			result.append(player)
	return result


func get_designated_cpu_goalkeeper(
	team: StringName
) -> FootballPlayer:
	if team != TEAM_BLUE and team != TEAM_RED:
		return null
	if _cpu_shared_world_frame == int(Engine.get_physics_frames()):
		var peer_key := "blue_goalkeeper_peer_id" if team == TEAM_BLUE else "red_goalkeeper_peer_id"
		var peer_id := int(_cpu_shared_world_model.get(peer_key, 0))
		if peer_id > 0:
			var cached := (
				_cpu_shared_world_model.get("players_by_peer", {}) as Dictionary
			).get(peer_id) as FootballPlayer
			if is_instance_valid(cached):
				return cached
	var team_players := blue_players if team == TEAM_BLUE else red_players
	var candidates: Array[FootballPlayer] = []
	for player in team_players:
		if is_instance_valid(player) and player.cpu_controlled:
			candidates.append(player)
	return _select_designated_cpu_goalkeeper_from_candidates(candidates)


func _get_cpu_goalkeeper_suitability(player: FootballPlayer) -> float:
	if player == null:
		return -INF

	var football_role: StringName = StringName(
		player.get_meta("pve_ranked_football_role", &"")
	)
	var role_score: float = 0.0
	match football_role:
		&"goalkeeper":
			role_score = 900.0
		&"defender":
			role_score = 260.0
		&"holding":
			role_score = 210.0
		&"midfielder":
			role_score = 55.0
		&"creator":
			role_score = -70.0
		&"winger":
			role_score = -180.0
		&"striker":
			role_score = -220.0
		&"forward_creator":
			role_score = -190.0

	var ability_id: int = player.selected_ability
	var ability_role: StringName = FootballPlayer.get_ability_role(ability_id)
	var ability_score: float = 0.0
	match ability_role:
		FootballPlayer.ABILITY_ROLE_DEFENSE:
			# A true defensive ability must beat generic midfield/playmaker kits.
			# This fixes cases such as Zidane + Iron Anchor being pushed forward
			# while Bellingham + Dead Zone Pass accidentally became the keeper.
			ability_score = 430.0 + float(_get_cpu_defensive_ability_rating(ability_id))
		FootballPlayer.ABILITY_ROLE_FLEXIBLE:
			ability_score = 145.0 + float(_get_cpu_defensive_ability_rating(ability_id))
		FootballPlayer.ABILITY_ROLE_PLAYMAKER:
			ability_score = 35.0 + float(_get_cpu_defensive_ability_rating(ability_id))
		FootballPlayer.ABILITY_ROLE_ATTACK:
			ability_score = -70.0 + float(_get_cpu_defensive_ability_rating(ability_id))
		_:
			ability_score = float(_get_cpu_defensive_ability_rating(ability_id))

	# Prestige bosses are designed to create offense. In a team match another CPU
	# must cover goal unless the boss is literally the only CPU on that side.
	if player.is_prestige_boss() and not player.is_neuer_boss():
		role_score -= 1000.0
	if player.is_neuer_boss():
		role_score += 1450.0
	if player.server_permanent_overdrive_enabled:
		role_score -= 240.0
	if player.server_permanent_power_strike_enabled:
		role_score -= 180.0

	return role_score + ability_score


func _get_cpu_defensive_ability_rating(ability_id: int) -> int:
	var role := FootballPlayer.get_ability_role(ability_id)
	match role:
		FootballPlayer.ABILITY_ROLE_DEFENSE:
			match ability_id:
				FootballPlayer.ABILITY_GOALKEEPER_REACH:
					return 100
				FootballPlayer.ABILITY_REFLEX_BLOCK:
					return 94
				FootballPlayer.ABILITY_IRON_ANCHOR:
					return 90
				FootballPlayer.ABILITY_ENFORCER:
					return 84
			return 80
		FootballPlayer.ABILITY_ROLE_FLEXIBLE:
			return 60
		FootballPlayer.ABILITY_ROLE_PLAYMAKER:
			match ability_id:
				FootballPlayer.ABILITY_META_VISION:
					return 58
				FootballPlayer.ABILITY_HEEL_TURN:
					return 48
				FootballPlayer.ABILITY_ELASTIC_STEP:
					return 34
				FootballPlayer.ABILITY_QUICK_TRIGGER:
					return 18
				FootballPlayer.ABILITY_TIME_SKIP_PASS:
					return 16
			return 30
		FootballPlayer.ABILITY_ROLE_ATTACK:
			match ability_id:
				FootballPlayer.ABILITY_DIRECT_FINISH:
					return 24
				FootballPlayer.ABILITY_BURST_DRIBBLE:
					return 12
				FootballPlayer.ABILITY_BLIND_SPOT:
					return 10
				FootballPlayer.ABILITY_OVERDRIVE:
					return 3
				FootballPlayer.ABILITY_POWER_STRIKE:
					return 1
			return 8
	return 10


func _get_cpu_kickoff_effective_speed(player: FootballPlayer) -> float:
	if player == null:
		return 1.0
	var speed: float = maxf(1.0, player.max_speed)
	if (
		player.server_permanent_overdrive_enabled
		or (
			player.server_ability_active
			and player.server_active_ability_id == FootballPlayer.ABILITY_OVERDRIVE
		)
	):
		speed *= maxf(1.0, player.overdrive_speed_multiplier)
	if player.server_permanent_power_strike_enabled and player.is_haaland_boss():
		speed *= maxf(1.0, player.haaland_boss_speed_multiplier)
	return speed


func _prepare_cpu_kickoff_roles_for_team(team: StringName) -> void:
	if team != TEAM_BLUE and team != TEAM_RED:
		return
	var team_players: Array[FootballPlayer] = (
		blue_players if team == TEAM_BLUE else red_players
	)
	var cpus: Array[FootballPlayer] = []
	for player in team_players:
		if is_instance_valid(player) and player.cpu_controlled:
			cpus.append(player)
	if cpus.is_empty():
		return

	var center: Vector2 = (
		ball_spawn.global_position
		if ball_spawn != null
		else Vector2.ZERO
	)
	var designated_keeper: FootballPlayer = get_designated_cpu_goalkeeper(team)
	var ranked: Array[Dictionary] = []
	for player in cpus:
		var distance: float = player.global_position.distance_to(center)
		var effective_speed: float = _get_cpu_kickoff_effective_speed(player)
		var eta: float = distance / effective_speed
		if player == designated_keeper and cpus.size() > 1:
			eta += 10.0
		ranked.append({
			"player": player,
			"eta": eta,
			"distance": distance,
			"speed": effective_speed
		})
	ranked.sort_custom(
		func(first: Dictionary, second: Dictionary) -> bool:
			var first_eta: float = float(first.get("eta", INF))
			var second_eta: float = float(second.get("eta", INF))
			if not is_equal_approx(first_eta, second_eta):
				return first_eta < second_eta
			var first_distance: float = float(first.get("distance", INF))
			var second_distance: float = float(second.get("distance", INF))
			if not is_equal_approx(first_distance, second_distance):
				return first_distance < second_distance
			var first_player := first.get("player") as FootballPlayer
			var second_player := second.get("player") as FootballPlayer
			if first_player.team_slot != second_player.team_slot:
				return first_player.team_slot < second_player.team_slot
			return first_player.owner_peer_id < second_player.owner_peer_id
	)

	var taker: FootballPlayer = ranked[0].get("player") as FootballPlayer
	for player in cpus:
		player.set_meta("cpu_kickoff_role", &"cover")
		player.set_meta("cpu_kickoff_taker_peer_id", taker.owner_peer_id)
		player.set_meta("cpu_kickoff_rank", 99)

	taker.set_meta("cpu_kickoff_role", &"taker")
	taker.set_meta("cpu_kickoff_rank", 0)

	var support_rank: int = 1
	for entry in ranked:
		var player := entry.get("player") as FootballPlayer
		if player == taker:
			continue
		if player == designated_keeper and cpus.size() > 1:
			player.set_meta("cpu_kickoff_role", &"goal_cover")
		else:
			match support_rank:
				1:
					player.set_meta("cpu_kickoff_role", &"cheat")
				2:
					player.set_meta("cpu_kickoff_role", &"cover")
				_:
					player.set_meta("cpu_kickoff_role", &"wide")
			support_rank += 1
		player.set_meta("cpu_kickoff_rank", support_rank)


func _prepare_cpu_kickoff_roles() -> void:
	_prepare_cpu_kickoff_roles_for_team(TEAM_BLUE)
	_prepare_cpu_kickoff_roles_for_team(TEAM_RED)


func get_cpu_kickoff_taker(team: StringName) -> FootballPlayer:
	var team_players: Array[FootballPlayer] = (
		blue_players if team == TEAM_BLUE else red_players
	)
	for player in team_players:
		if (
			is_instance_valid(player)
			and player.cpu_controlled
			and StringName(player.get_meta("cpu_kickoff_role", &"")) == &"taker"
		):
			return player
	# Safety fallback for unusual custom scenes that skipped a normal reset.
	_prepare_cpu_kickoff_roles_for_team(team)
	for player in team_players:
		if (
			is_instance_valid(player)
			and player.cpu_controlled
			and StringName(player.get_meta("cpu_kickoff_role", &"")) == &"taker"
		):
			return player
	return null


func get_cpu_kickoff_role(player: FootballPlayer) -> StringName:
	if player == null:
		return &""
	return StringName(player.get_meta("cpu_kickoff_role", &""))




func _get_valid_team_players(team: StringName) -> Array[FootballPlayer]:
	var source := blue_players if team == TEAM_BLUE else red_players
	var result: Array[FootballPlayer] = []
	for player in source:
		if is_instance_valid(player):
			result.append(player)
	result.sort_custom(
		func(a: FootballPlayer, b: FootballPlayer) -> bool:
			return a.team_slot < b.team_slot
	)
	return result


func _select_penalty_kicker(team: StringName) -> FootballPlayer:
	var players := _get_valid_team_players(team)
	if players.is_empty():
		return null
	if players.size() == 1:
		return players[0]

	var last_peer_id := int(_last_penalty_kicker_peer_by_team.get(team, 0))
	if last_peer_id > 0:
		for index in range(players.size()):
			if players[index].owner_peer_id == last_peer_id:
				return players[(index + 1) % players.size()]

	var attempt_index := (
		penalty_blue_attempts if team == TEAM_BLUE else penalty_red_attempts
	)
	return players[attempt_index % players.size()]


func _select_penalty_goalkeeper(team: StringName) -> FootballPlayer:
	var players := _get_valid_team_players(team)
	if players.is_empty():
		return null
	if ranked_mode and _ranked_penalty_goalkeepers.has(team):
		var saved_peer_id := int(_ranked_penalty_goalkeepers[team])
		for saved_player in players:
			if saved_player.owner_peer_id == saved_peer_id:
				return saved_player
	for player in players:
		if player.selected_ability == FootballPlayer.ABILITY_GOALKEEPER_REACH:
			return player
	var cpu_goalkeeper := get_designated_cpu_goalkeeper(team)
	if cpu_goalkeeper != null:
		return cpu_goalkeeper
	return players[0]


func _set_penalty_participants_enabled(enabled: bool) -> void:
	for player in _get_all_match_players():
		var participates := player.owner_peer_id in [
			penalty_kicker_peer_id,
			penalty_goalkeeper_peer_id
		]
		player.set_controls_enabled(enabled and participates)


func _complete_penalty_attempt(scored: bool) -> void:
	if (
		not multiplayer.is_server()
		or not penalty_shootout_active
		or not penalty_attempt_active
	):
		return
	_tiebreak_generation += 1
	var generation := _tiebreak_generation
	var completed_team := penalty_turn
	if penalty_kicker_peer_id > 0:
		_last_penalty_kicker_peer_by_team[completed_team] = penalty_kicker_peer_id
	penalty_attempt_active = false
	penalty_attempt_time_remaining = 0.0
	_penalty_attempt_clock_started = false
	_penalty_ball_start_position = Vector2.ZERO
	round_resetting = true
	_match_clock_waiting_for_kickoff = false
	_set_all_players_enabled(false)
	if ball != null:
		ball.set_play_enabled(false)
	if completed_team == TEAM_RED:
		penalty_red_attempts += 1
		if scored:
			penalty_red_score += 1
	else:
		penalty_blue_attempts += 1
		if scored:
			penalty_blue_score += 1
	_broadcast_tournament_tiebreak_state()
	_broadcast_timer()
	var team_name := "BLUE" if completed_team == TEAM_BLUE else "RED"
	_show_announcement(
		"%s SCORES" % team_name if scored else "%s MISSES" % team_name,
		1.5
	)
	var winner := _get_penalty_winner()
	if winner != NO_TEAM:
		_finish_penalty_shootout_after_delay(generation, winner)
		return
	penalty_turn = TEAM_RED if completed_team == TEAM_BLUE else TEAM_BLUE
	_broadcast_tournament_tiebreak_state()
	_begin_next_penalty_after_delay(generation)


func _begin_next_penalty_after_delay(generation: int) -> void:
	await get_tree().create_timer(1.5).timeout
	if (
		generation != _tiebreak_generation
		or not game_has_started
		or not penalty_shootout_active
	):
		return
	_begin_penalty_attempt()


func _finish_penalty_shootout_after_delay(
	generation: int,
	winner: StringName
) -> void:
	await get_tree().create_timer(1.8).timeout
	if generation != _tiebreak_generation or not game_has_started:
		return
	_restore_penalty_goalkeeper_reach_override()
	end_match(winner)


func _get_penalty_winner() -> StringName:
	var quota := maxi(1, penalty_kicks_per_team)
	if penalty_red_attempts <= quota and penalty_blue_attempts <= quota:
		var red_remaining := maxi(0, quota - penalty_red_attempts)
		var blue_remaining := maxi(0, quota - penalty_blue_attempts)
		if penalty_red_score > penalty_blue_score + blue_remaining:
			return TEAM_RED
		if penalty_blue_score > penalty_red_score + red_remaining:
			return TEAM_BLUE
	if (
		penalty_red_attempts >= quota
		and penalty_blue_attempts >= quota
		and penalty_red_attempts == penalty_blue_attempts
		and penalty_red_score != penalty_blue_score
	):
		return TEAM_RED if penalty_red_score > penalty_blue_score else TEAM_BLUE
	return NO_TEAM


func _reset_tournament_tiebreak_state() -> void:
	_restore_penalty_goalkeeper_reach_override()
	_penalty_goalkeeper_original_abilities.clear()
	_tiebreak_generation += 1
	tournament_tiebreak_phase = TIEBREAK_NONE
	tournament_extra_time_period = 0
	tournament_extra_time_remaining = 0.0
	penalty_shootout_active = false
	penalty_red_score = 0
	penalty_blue_score = 0
	penalty_red_attempts = 0
	penalty_blue_attempts = 0
	penalty_turn = NO_TEAM
	penalty_attempt_active = false
	penalty_attempt_time_remaining = 0.0
	_penalty_attempt_clock_started = false
	_penalty_ball_start_position = Vector2.ZERO
	penalty_kicker_peer_id = 0
	penalty_goalkeeper_peer_id = 0
	penalty_attempt_serial = 0
	_last_penalty_kicker_peer_by_team.clear()
	_penalty_first_team = NO_TEAM


func _emit_tournament_tiebreak_state() -> void:
	tournament_tiebreak_changed.emit(
		tournament_tiebreak_phase,
		tournament_extra_time_period,
		penalty_red_score,
		penalty_blue_score,
		penalty_red_attempts,
		penalty_blue_attempts,
		penalty_turn,
		penalty_attempt_active
	)


func _broadcast_tournament_tiebreak_state() -> void:
	if not multiplayer.is_server():
		return
	_receive_tournament_tiebreak_state.rpc(
		tournament_tiebreak_phase,
		tournament_extra_time_period,
		penalty_red_score,
		penalty_blue_score,
		penalty_red_attempts,
		penalty_blue_attempts,
		penalty_turn,
		penalty_attempt_active,
		penalty_kicker_peer_id,
		penalty_goalkeeper_peer_id,
		penalty_attempt_serial
	)


@rpc("authority", "call_local", "reliable")
func _receive_tournament_tiebreak_state(
	phase: StringName,
	extra_time_period: int,
	new_penalty_red_score: int,
	new_penalty_blue_score: int,
	new_penalty_red_attempts: int,
	new_penalty_blue_attempts: int,
	new_penalty_turn: StringName,
	new_penalty_attempt_active: bool,
	new_penalty_kicker_peer_id: int,
	new_penalty_goalkeeper_peer_id: int,
	new_penalty_attempt_serial: int
) -> void:
	tournament_tiebreak_phase = phase
	tournament_extra_time_period = extra_time_period
	penalty_shootout_active = phase == TIEBREAK_PENALTIES
	penalty_red_score = new_penalty_red_score
	penalty_blue_score = new_penalty_blue_score
	penalty_red_attempts = new_penalty_red_attempts
	penalty_blue_attempts = new_penalty_blue_attempts
	penalty_turn = new_penalty_turn
	penalty_attempt_active = new_penalty_attempt_active
	penalty_kicker_peer_id = new_penalty_kicker_peer_id
	penalty_goalkeeper_peer_id = new_penalty_goalkeeper_peer_id
	penalty_attempt_serial = new_penalty_attempt_serial
	_emit_tournament_tiebreak_state()


func _broadcast_timer() -> void:
	if not multiplayer.is_server():
		return

	var display_seconds := _get_display_seconds()
	_timer_sync_serial += 1
	_receive_timer.rpc(_timer_sync_serial, display_seconds, is_overtime)


func _get_display_seconds() -> int:
	if tournament_tiebreak_phase in [
		TIEBREAK_EXTRA_TIME,
		TIEBREAK_EXTRA_BREAK
	]:
		return maxi(0, int(ceil(tournament_extra_time_remaining)))
	if penalty_shootout_active:
		return maxi(0, int(ceil(penalty_attempt_time_remaining)))
	return (
		int(floor(overtime_elapsed))
		if is_overtime
		else int(ceil(regulation_time_remaining))
	)


@rpc("authority", "call_local", "unreliable")
func _receive_timer(
	sync_serial: int,
	display_seconds: int,
	overtime: bool
) -> void:
	if sync_serial <= _last_received_timer_sync_serial:
		return
	_last_received_timer_sync_serial = sync_serial
	is_overtime = overtime
	timer_changed.emit(maxi(0, display_seconds), overtime)


func _select_new_field_variant() -> void:
	if not multiplayer.is_server():
		return
	if field_variant_locked:
		_receive_field_variant(current_field_variant)
		_receive_field_variant.rpc(current_field_variant)
		return
	var variant_count := maxi(1, field_variant_count)
	var next_variant := 0
	if variant_count > 1:
		next_variant = _cpu_ability_rng.randi_range(
			0,
			variant_count - 2
		)
		if next_variant >= current_field_variant:
			next_variant += 1
	_receive_field_variant(next_variant)
	_receive_field_variant.rpc(next_variant)


func request_field_variant(variant_index: int) -> void:
	if multiplayer.is_server():
		# A local/offline lobby can report peer ID 0 before its network
		# peer has fully initialized.  It is still the authoritative host.
		var requester_id := multiplayer.get_unique_id()
		if requester_id <= 0:
			requester_id = SERVER_PEER_ID
		_server_set_field_variant(requester_id, variant_index)
	else:
		_request_field_variant.rpc_id(SERVER_PEER_ID, variant_index)


@rpc("any_peer", "call_remote", "reliable")
func _request_field_variant(variant_index: int) -> void:
	if multiplayer.is_server():
		_server_set_field_variant(multiplayer.get_remote_sender_id(), variant_index)


func _server_set_field_variant(requester_id: int, variant_index: int) -> void:
	if (
		not multiplayer.is_server()
		or requester_id != SERVER_PEER_ID
		or game_has_started
	):
		return
	field_variant_locked = true
	_receive_field_variant(variant_index)
	_receive_field_variant.rpc(variant_index)


@rpc("authority", "call_remote", "reliable")
func _receive_field_variant(variant_index: int) -> void:
	current_field_variant = posmod(
		variant_index,
		maxi(1, field_variant_count)
	)
	field_variant_changed.emit(current_field_variant)


# ================================================================
# GOALS AND ANNOUNCEMENTS
# ================================================================

func _on_ball_kicked(
	peer_id: int,
	player_name: String,
	player_team: StringName,
	kick_position: Vector2,
	predicted_velocity: Vector2
) -> void:
	if (
		not multiplayer.is_server()
		or not game_has_started
		or freeplay_active
	):
		return
	if player_team != TEAM_RED and player_team != TEAM_BLUE:
		return

	_notify_cpu_tactical_global_event(&"ball_kicked")
	_notify_cpu_tactical_peer_event(peer_id, &"just_kicked")
	var incoming_velocity := (
		ball.linear_velocity if ball != null else Vector2.ZERO
	)
	var kick_velocity_delta := predicted_velocity - incoming_velocity
	var kick_force := kick_velocity_delta.length() * (
		maxf(0.001, ball.mass) if ball != null else 1.0
	)
	var kicking_player := _get_player(peer_id)
	var power_strike_active := (
		kicking_player != null
		and kicking_player._server_ability_is_active(
			FootballPlayer.ABILITY_POWER_STRIKE
		)
	)
	_record_goal_replay_event({
		"type": &"kick",
		"peer_id": peer_id,
		"team": player_team,
		"position": kick_position,
		"direction": kick_velocity_delta.normalized(),
		"intensity": clampf(kick_force / 3000.0, 0.2, 1.0),
		"force": kick_force,
		"power_strike": power_strike_active
	})
	_record_human_learning_kick(
		kicking_player,
		player_team,
		kick_position,
		predicted_velocity
	)
	_record_human_demonstration_kick(
		kicking_player,
		player_team,
		kick_position,
		predicted_velocity,
		kick_force
	)

	# After a goal, GO releases the players but the match clock remains
	# frozen until the first real kickoff is struck.
	if _match_clock_waiting_for_kickoff:
		_match_clock_waiting_for_kickoff = false
		_timer_sync_accumulator = 0.0
	if penalty_shootout_active:
		return

	_pending_pass = {
		"peer_id": peer_id,
		"team": player_team,
		"position": kick_position,
		"time_msec": Time.get_ticks_msec()
	}
	_active_shot.clear()
	var target_goal := _target_goal_for_team(player_team)
	if (
		target_goal == null
		or predicted_velocity.length()
		< maxf(0.0, minimum_save_threat_speed)
		or (
			target_goal.get_goal_plane_x() - kick_position.x
		) * predicted_velocity.x <= 0.0
	):
		return

	_notify_cpu_tactical_global_event(&"shot_started")
	_active_shot = {
		"shooter_peer_id": peer_id,
		"attacking_team": player_team,
		"defending_team": (
			TEAM_BLUE
			if player_team == TEAM_RED
			else TEAM_RED
		),
		"target_goal": target_goal,
		"travel_direction": signf(predicted_velocity.x)
	}


func _on_player_ability_used(
	peer_id: int,
	player_team: StringName,
	ability_id: int
) -> void:
	if (
		not multiplayer.is_server()
		or not game_has_started
		or freeplay_active
		or player_team != TEAM_RED and player_team != TEAM_BLUE
		or ability_id <= FootballPlayer.ABILITY_NONE
	):
		return
	var player := _get_player(peer_id)
	if player == null:
		return
	_apply_draft_ability_reaction_perks(player)
	if player.cpu_controlled:
		return
	var under_pressure := false
	for opponent in _get_opponents_for_team(player_team):
		if opponent.global_position.distance_to(player.global_position) < 620.0:
			under_pressure = true
			break
	var context_quality := _get_human_ability_context_quality(
		player,
		player_team,
		ability_id,
		under_pressure
	)
	_deliver_human_learning_ability_used(
		peer_id,
		player_team,
		ability_id,
		context_quality,
		under_pressure
	)
	_record_human_demonstration_event(player, &"ability", {
		"ability_id": ability_id,
		"cooldown_ready": true,
		"under_pressure": under_pressure,
		"context_quality": context_quality,
		"move": _normalized_demo_direction(player.server_direction, player_team),
		"aim": _normalized_demo_direction(player.server_direction, player_team),
		"target": _normalize_demo_position(ball.global_position, player_team)
	})


func _apply_draft_ability_reaction_perks(source: FootballPlayer) -> void:
	if not champions_league_mode or source == null:
		return
	if source.draft_perk_id == 9:
		for teammate: FootballPlayer in _get_valid_team_players(source.team):
			if teammate == source:
				continue
			var teammate_now: float = teammate._server_time_seconds()
			teammate._reduce_draft_perk_cooldown_seconds(3.0, teammate_now)
	for opponent: FootballPlayer in _get_opponents_for_team(source.team):
		if not is_instance_valid(opponent):
			continue
		var opponent_now: float = opponent._server_time_seconds()
		if opponent.draft_perk_id == 10:
			opponent._scale_draft_perk_cooldown(0.5, opponent_now)
		elif opponent.draft_perk_id == 41:
			opponent._grant_draft_perk_movement_boost(
				1.30,
				1.30,
				2.0,
				opponent_now
			)
		elif (
			opponent.draft_perk_id == 43
			and opponent.consume_draft_perk_reverse_card()
		):
			source._add_draft_perk_cooldown_seconds(
				3.0,
				source._server_time_seconds(),
				true
			)
			opponent._scale_draft_perk_cooldown(0.5, opponent_now)


func _get_human_ability_context_quality(
	player: FootballPlayer,
	player_team: StringName,
	ability_id: int,
	under_pressure: bool
) -> float:
	if ball == null:
		return 0.0
	var ball_distance := player.global_position.distance_to(ball.global_position)
	var kick_distance := maxf(100.0, player.kick_feedback_detection_distance)
	var close_to_ball := clampf(1.0 - ball_distance / (kick_distance * 2.4), 0.0, 1.0)
	var attack_goal := _target_goal_for_team(player_team)
	var own_goal := red_goal if player_team == TEAM_RED else blue_goal
	var attack_value := 0.0
	if attack_goal != null:
		attack_value = clampf(
			1.0 - ball.global_position.distance_to(
				_get_goal_center(attack_goal)
			) / 6500.0,
			0.0,
			1.0
		)
	var danger_value := 0.0
	if own_goal != null:
		var to_goal: Vector2 = _get_goal_center(own_goal) - ball.global_position
		var moving_toward_goal := ball.linear_velocity.dot(to_goal.normalized())
		danger_value = clampf(
			ball.linear_velocity.length() / 1900.0,
			0.0,
			1.0
		) * (1.0 if moving_toward_goal > 0.0 else 0.35)
	match FootballPlayer.get_ability_role(ability_id):
		FootballPlayer.ABILITY_ROLE_DEFENSE:
			return maxf(danger_value, close_to_ball * 0.55)
		FootballPlayer.ABILITY_ROLE_ATTACK:
			return clampf(
				attack_value * 0.62 + close_to_ball * 0.28
				+ (0.15 if under_pressure else 0.0),
				0.0,
				1.0
			)
		_:
			return clampf(
				attack_value * 0.42 + close_to_ball * 0.34
				+ (0.18 if under_pressure else 0.0),
				0.0,
				1.0
			)


func _deliver_human_learning_ability_used(
	peer_id: int,
	team: StringName,
	ability_id: int,
	context_quality: float,
	under_pressure: bool
) -> void:
	if peer_id == multiplayer.get_unique_id():
		_apply_human_learning_ability_used(
			peer_id, team, ability_id, context_quality, under_pressure
		)
	else:
		_receive_human_learning_ability_used.rpc_id(
			peer_id, peer_id, team, ability_id, context_quality, under_pressure
		)


@rpc("authority", "call_remote", "reliable")
func _receive_human_learning_ability_used(
	peer_id: int,
	team: StringName,
	ability_id: int,
	context_quality: float,
	under_pressure: bool
) -> void:
	if peer_id == multiplayer.get_unique_id():
		_apply_human_learning_ability_used(
			peer_id, team, ability_id, context_quality, under_pressure
		)


func _apply_human_learning_ability_used(
	peer_id: int,
	team: StringName,
	ability_id: int,
	context_quality: float,
	under_pressure: bool
) -> void:
	var learner := get_tree().root.get_node_or_null("HumanLearningManager")
	if learner != null and learner.has_method("record_human_ability_used"):
		learner.call(
			"record_human_ability_used", peer_id, team, ability_id,
			context_quality, under_pressure
		)


func _record_human_learning_kick(
	player: FootballPlayer,
	team: StringName,
	kick_position: Vector2,
	predicted_velocity: Vector2
) -> void:
	if player == null or player.cpu_controlled:
		return
	var attack_sign := 1.0 if team == TEAM_BLUE else -1.0
	var forward_progress := clampf(
		predicted_velocity.x * attack_sign / 1800.0,
		-1.0,
		1.0
	)
	var shot_quality := 0.0
	var used_wall := false
	var target_goal := _target_goal_for_team(team)
	if target_goal != null and absf(predicted_velocity.x) > 1.0:
		var time_to_goal := (
			target_goal.get_goal_plane_x() - kick_position.x
		) / predicted_velocity.x
		if time_to_goal > 0.0:
			var projected_y := kick_position.y + predicted_velocity.y * time_to_goal
			var mouth := target_goal.get_mouth_y_range()
			var mouth_center := (mouth.x + mouth.y) * 0.5
			shot_quality = clampf(
				1.0 - absf(projected_y - mouth_center) / 1100.0,
				0.0,
				1.0
			)
			used_wall = projected_y < 750.0 or projected_y > 4250.0
	var under_pressure := false
	for opponent in _get_opponents_for_team(team):
		if opponent.global_position.distance_to(kick_position) < 520.0:
			under_pressure = true
			break
	var ability_id := FootballPlayer.ABILITY_NONE
	if player.server_ability_active:
		ability_id = player.server_active_ability_id
	elif (
		player.server_last_used_ability_id != FootballPlayer.ABILITY_NONE
		and float(Time.get_ticks_msec()) / 1000.0 - player.server_last_ability_used_at <= 2.5
	):
		ability_id = player.server_last_used_ability_id
	_deliver_human_learning_kick(
		player.owner_peer_id,
		team,
		forward_progress,
		shot_quality,
		used_wall,
		ability_id,
		under_pressure
	)


func _get_opponents_for_team(team: StringName) -> Array[FootballPlayer]:
	return red_players if team == TEAM_BLUE else blue_players


func _deliver_human_learning_kick(
	peer_id: int,
	team: StringName,
	forward_progress: float,
	shot_quality: float,
	used_wall: bool,
	ability_id: int,
	under_pressure: bool
) -> void:
	if peer_id == multiplayer.get_unique_id():
		_apply_human_learning_kick(
			peer_id, team, forward_progress, shot_quality,
			used_wall, ability_id, under_pressure
		)
	else:
		_receive_human_learning_kick.rpc_id(
			peer_id, peer_id, team, forward_progress, shot_quality,
			used_wall, ability_id, under_pressure
		)


@rpc("authority", "call_remote", "reliable")
func _receive_human_learning_kick(
	peer_id: int,
	team: StringName,
	forward_progress: float,
	shot_quality: float,
	used_wall: bool,
	ability_id: int,
	under_pressure: bool
) -> void:
	if peer_id != multiplayer.get_unique_id():
		return
	_apply_human_learning_kick(
		peer_id, team, forward_progress, shot_quality,
		used_wall, ability_id, under_pressure
	)


func _apply_human_learning_kick(
	peer_id: int,
	team: StringName,
	forward_progress: float,
	shot_quality: float,
	used_wall: bool,
	ability_id: int,
	under_pressure: bool
) -> void:
	var learner := get_tree().root.get_node_or_null("HumanLearningManager")
	if learner != null and learner.has_method("record_human_kick"):
		learner.call(
			"record_human_kick", peer_id, team, forward_progress,
			shot_quality, used_wall, ability_id, under_pressure
		)


func _deliver_human_learning_goal(peer_id: int, team: StringName) -> void:
	if peer_id == multiplayer.get_unique_id():
		_apply_human_learning_goal(peer_id, team)
	else:
		_receive_human_learning_goal.rpc_id(peer_id, peer_id, team)


@rpc("authority", "call_remote", "reliable")
func _receive_human_learning_goal(peer_id: int, team: StringName) -> void:
	if peer_id == multiplayer.get_unique_id():
		_apply_human_learning_goal(peer_id, team)


func _apply_human_learning_goal(peer_id: int, team: StringName) -> void:
	var learner := get_tree().root.get_node_or_null("HumanLearningManager")
	if learner != null and learner.has_method("record_human_goal"):
		learner.call("record_human_goal", peer_id, team)


func _deliver_human_learning_match_finished() -> void:
	var delivered: Dictionary = {}
	for player in _get_all_match_players():
		if player.cpu_controlled or delivered.has(player.owner_peer_id):
			continue
		delivered[player.owner_peer_id] = true
		if player.owner_peer_id == multiplayer.get_unique_id():
			_apply_human_learning_match_finished()
		else:
			_receive_human_learning_match_finished.rpc_id(player.owner_peer_id)


@rpc("authority", "call_remote", "reliable")
func _receive_human_learning_match_finished() -> void:
	_apply_human_learning_match_finished()


func _apply_human_learning_match_finished() -> void:
	var learner := get_tree().root.get_node_or_null("HumanLearningManager")
	if learner != null and learner.has_method("finish_human_match"):
		learner.call("finish_human_match")


func _human_demonstration_learner() -> Node:
	return get_tree().root.get_node_or_null("HumanLearningManager")


func _human_demo_time() -> float:
	return float(Time.get_ticks_msec()) / 1000.0


func _reset_cpu_benchmark_metrics() -> void:
	_cpu_benchmark_metrics = {
		TEAM_BLUE: {
			"goals": 0,
			"assists": 0,
			"completed_passes": 0,
			"turnovers": 0,
			"saves": 0,
			"goals_against": 0,
			"own_goals": 0,
			"avoidable_own_goals": 0,
			"forced_deflection_own_goals": 0,
			"dangerous_own_goal_touch_attempts": 0,
			"dangerous_own_goal_touch_rejections": 0,
			"own_goal_prevention_redirects": 0
		},
		TEAM_RED: {
			"goals": 0,
			"assists": 0,
			"completed_passes": 0,
			"turnovers": 0,
			"saves": 0,
			"goals_against": 0,
			"own_goals": 0,
			"avoidable_own_goals": 0,
			"forced_deflection_own_goals": 0,
			"dangerous_own_goal_touch_attempts": 0,
			"dangerous_own_goal_touch_rejections": 0,
			"own_goal_prevention_redirects": 0
		}
	}
	_hybrid_ai_diagnostics.clear()


func record_hybrid_ai_decision(
	peer_id: int,
	action: String,
	score: float,
	reason: String
) -> void:
	var entry := _hybrid_ai_diagnostics.get(peer_id, {
		"decisions": 0,
		"fallbacks": 0,
		"action_usage": {},
		"fallback_reasons": {}
	}) as Dictionary
	entry["decisions"] = int(entry.get("decisions", 0)) + 1
	entry["last_action"] = action
	entry["last_score"] = score
	entry["last_reason"] = reason
	var usage := entry.get("action_usage", {}) as Dictionary
	usage[action] = int(usage.get(action, 0)) + 1
	entry["action_usage"] = usage
	_hybrid_ai_diagnostics[peer_id] = entry


func record_hybrid_ai_fallback(peer_id: int, reason: String) -> void:
	var entry := _hybrid_ai_diagnostics.get(peer_id, {
		"decisions": 0,
		"fallbacks": 0,
		"action_usage": {},
		"fallback_reasons": {}
	}) as Dictionary
	entry["fallbacks"] = int(entry.get("fallbacks", 0)) + 1
	entry["last_fallback_reason"] = reason
	var reasons := entry.get("fallback_reasons", {}) as Dictionary
	reasons[reason] = int(reasons.get(reason, 0)) + 1
	entry["fallback_reasons"] = reasons
	_hybrid_ai_diagnostics[peer_id] = entry


func get_hybrid_ai_diagnostics(peer_id: int = 0) -> Dictionary:
	if peer_id > 0:
		return (_hybrid_ai_diagnostics.get(peer_id, {}) as Dictionary).duplicate(true)
	return _hybrid_ai_diagnostics.duplicate(true)


func _increment_cpu_benchmark_metric(team: StringName, metric: String, amount: int = 1) -> void:
	if team not in [TEAM_BLUE, TEAM_RED]:
		return
	if _cpu_benchmark_metrics.is_empty():
		_reset_cpu_benchmark_metrics()
	var metrics := _cpu_benchmark_metrics.get(team, {}) as Dictionary
	metrics[metric] = int(metrics.get(metric, 0)) + amount
	_cpu_benchmark_metrics[team] = metrics


func record_cpu_own_goal_safety_event(
	team: StringName,
	event_kind: StringName,
	touch_kind: StringName,
	peer_id: int = 0
) -> void:
	if team not in [TEAM_BLUE, TEAM_RED]:
		return
	match event_kind:
		&"attempt":
			_increment_cpu_benchmark_metric(
				team,
				"dangerous_own_goal_touch_attempts"
			)
		&"rejection":
			_increment_cpu_benchmark_metric(
				team,
				"dangerous_own_goal_touch_rejections"
			)
		&"redirect":
			_increment_cpu_benchmark_metric(
				team,
				"dangerous_own_goal_touch_attempts"
			)
			_increment_cpu_benchmark_metric(
				team,
				"own_goal_prevention_redirects"
			)
	if cpu_training_mode:
		print(
			"OWN-GOAL SAFETY | team=%s | event=%s | kind=%s | peer=%d"
			% [str(team), str(event_kind), str(touch_kind), peer_id]
		)


func get_cpu_benchmark_metrics(team: StringName) -> Dictionary:
	var metrics := (_cpu_benchmark_metrics.get(team, {}) as Dictionary).duplicate(true)
	var passes := float(metrics.get("completed_passes", 0))
	var turnovers := float(metrics.get("turnovers", 0))
	var saves := float(metrics.get("saves", 0))
	var conceded := float(metrics.get("goals_against", 0))
	metrics["possession_safety"] = passes / maxf(1.0, passes + turnovers)
	metrics["defense"] = saves / maxf(1.0, saves + conceded)
	return metrics


func _begin_human_demonstration_recording() -> void:
	if not multiplayer.is_server() or cpu_training_mode or freeplay_active:
		return
	_human_demo_pending_result.clear()
	var learner := _human_demonstration_learner()
	if learner == null or not learner.has_method("begin_authoritative_match"):
		return
	var roster: Array = []
	for player in _get_all_match_players():
		roster.append({
			"peer_id": player.owner_peer_id,
			"team": player.team,
			"cpu": player.cpu_controlled
		})
	learner.call("begin_authoritative_match", roster, {
		"field_variant": current_field_variant,
		"regulation_seconds": regulation_seconds,
		"goals_to_win": goals_to_win,
		"tournament": tournament_mode,
		"field_bounds": [360.0, 680.0, 6970.0, 4320.0]
	})


func _abort_human_demonstration_recording() -> void:
	_human_demo_pending_result.clear()
	var learner := _human_demonstration_learner()
	if learner != null and learner.has_method("abort_authoritative_match"):
		learner.call("abort_authoritative_match")


func _queue_human_demonstration_recording(winning_team: StringName) -> void:
	if cpu_training_mode:
		return
	var learner := _human_demonstration_learner()
	if (
		learner == null
		or not learner.has_method("has_active_authoritative_match")
		or not bool(learner.call("has_active_authoritative_match"))
	):
		return
	_human_demo_pending_result = {
		"winning_team": winning_team,
		"blue_score": blue_score,
		"red_score": red_score
	}


func has_pending_human_demonstration_recording() -> bool:
	return multiplayer.is_server() and not _human_demo_pending_result.is_empty()


func resolve_pending_human_demonstration_recording(save_recording: bool) -> Dictionary:
	if not multiplayer.is_server() or _human_demo_pending_result.is_empty():
		return {"ok": false, "error": "no_pending_recording"}
	var learner := _human_demonstration_learner()
	var result: Dictionary = {"ok": true, "saved": false}
	if learner == null:
		result = {"ok": false, "error": "learner_unavailable"}
	elif save_recording and learner.has_method("finish_authoritative_match"):
		result = learner.call("finish_authoritative_match", _human_demo_pending_result) as Dictionary
		result["ok"] = not result.is_empty()
		result["saved"] = bool(result.get("ok", false))
		if bool(result.get("saved", false)):
			_deliver_human_learning_match_finished()
	elif learner.has_method("abort_authoritative_match"):
		learner.call("abort_authoritative_match")
	_human_demo_pending_result.clear()
	return result


func _record_human_demonstration_frame() -> void:
	var learner := _human_demonstration_learner()
	if learner == null or not learner.has_method("record_authoritative_frame") or ball == null:
		return
	var snapshots: Dictionary = {}
	for player in _get_all_match_players():
		if player.cpu_controlled:
			continue
		snapshots[player.owner_peer_id] = _build_human_demo_snapshot(player)
	learner.call("record_authoritative_frame", _human_demo_time(), snapshots)


func _build_human_demo_snapshot(player: FootballPlayer) -> Dictionary:
	var team := player.team
	var teammates: Array = []
	var opponents: Array = []
	var own_roster := blue_players if team == TEAM_BLUE else red_players
	var opponent_roster := red_players if team == TEAM_BLUE else blue_players
	for teammate in own_roster:
		if teammate == player or not is_instance_valid(teammate):
			continue
		teammates.append({
			"position": _normalize_demo_position(teammate.global_position, team),
			"velocity": _normalized_demo_velocity(teammate.linear_velocity, team),
			"ability_id": teammate.selected_ability
		})
	for opponent in opponent_roster:
		if not is_instance_valid(opponent):
			continue
		opponents.append({
			"position": _normalize_demo_position(opponent.global_position, team),
			"velocity": _normalized_demo_velocity(opponent.linear_velocity, team),
			"ability_id": opponent.selected_ability
		})
	teammates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return _demo_array_distance(a.get("position", []), _normalize_demo_position(player.global_position, team)) < _demo_array_distance(b.get("position", []), _normalize_demo_position(player.global_position, team)))
	opponents.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return _demo_array_distance(a.get("position", []), _normalize_demo_position(player.global_position, team)) < _demo_array_distance(b.get("position", []), _normalize_demo_position(player.global_position, team)))
	if teammates.size() > 3:
		teammates.resize(3)
	if opponents.size() > 4:
		opponents.resize(4)
	var target_goal := _target_goal_for_team(team)
	var goal_position := _get_goal_center(target_goal)
	var goalkeeper_position := goal_position
	var goalkeeper_distance := INF
	for opponent in opponent_roster:
		if not is_instance_valid(opponent):
			continue
		var distance := opponent.global_position.distance_to(goal_position)
		if distance < goalkeeper_distance:
			goalkeeper_distance = distance
			goalkeeper_position = opponent.global_position
	var possession := "loose"
	if _cpu_last_touch_peer_id == player.owner_peer_id:
		possession = "self"
	elif _cpu_possession_team == team:
		possession = "team"
	elif _cpu_possession_team in [TEAM_BLUE, TEAM_RED]:
		possession = "opponent"
	var now := _human_demo_time()
	var cooldown := maxf(0.0, player.server_ability_cooldown_ends_at - now)
	var pressure := false
	for opponent in opponent_roster:
		if is_instance_valid(opponent) and opponent.global_position.distance_to(player.global_position) < 620.0:
			pressure = true
			break
	return {
		"actor": _normalize_demo_position(player.global_position, team),
		"actor_velocity": _normalized_demo_velocity(player.linear_velocity, team),
		"ball": _normalize_demo_position(ball.global_position, team),
		"ball_velocity": _normalized_demo_velocity(ball.linear_velocity, team),
		"possession": possession,
		"teammates": teammates,
		"opponents": opponents,
		"goal": _normalize_demo_position(goal_position, team),
		"goalkeeper": _normalize_demo_position(goalkeeper_position, team),
		"move": _normalized_demo_direction(player.server_direction, team),
		"aim": _normalized_demo_direction(player.server_direction, team),
		"charging": player.server_is_charging,
		"charge": maxf(0.0, now - player.server_charge_started_at) if player.server_is_charging else 0.0,
		"ability_id": player.selected_ability,
		"active_ability_id": player.server_active_ability_id if player.server_ability_active else FootballPlayer.ABILITY_NONE,
		"ability_active": player.server_ability_active,
		"cooldown": cooldown,
		"cooldown_ready": cooldown <= 0.0,
		"under_pressure": pressure,
		"attack_direction": [1.0, 0.0]
	}


func _record_human_demonstration_event(
	player: FootballPlayer,
	event_type: StringName,
	data: Dictionary = {}
) -> void:
	if player == null or player.cpu_controlled:
		return
	var learner := _human_demonstration_learner()
	if learner != null and learner.has_method("record_authoritative_event"):
		learner.call("record_authoritative_event", player.owner_peer_id, event_type, _human_demo_time(), data)


func _record_human_demonstration_kick(
	player: FootballPlayer,
	team: StringName,
	kick_position: Vector2,
	predicted_velocity: Vector2,
	kick_force: float
) -> void:
	if player == null or player.cpu_controlled:
		return
	var direction := (predicted_velocity - (ball.linear_velocity if ball != null else Vector2.ZERO)).normalized()
	var ability_id := FootballPlayer.ABILITY_NONE
	if player.server_ability_active:
		ability_id = player.server_active_ability_id
	elif (
		player.server_last_used_ability_id != FootballPlayer.ABILITY_NONE
		and _human_demo_time() - player.server_last_ability_used_at <= 2.5
	):
		ability_id = player.server_last_used_ability_id
	var target := kick_position + direction * 1600.0
	var target_role := "space"
	var combination_id := "ordinary"
	var nearest_alignment := 0.78
	var target_peer_id := 0
	var target_teammate_position := Vector2.ZERO
	var roster := blue_players if team == TEAM_BLUE else red_players
	for teammate in roster:
		if teammate == player or not is_instance_valid(teammate):
			continue
		var alignment := direction.dot(kick_position.direction_to(teammate.global_position))
		if alignment > nearest_alignment:
			nearest_alignment = alignment
			target_teammate_position = teammate.global_position
			target = kick_position + direction * kick_position.distance_to(teammate.global_position)
			target_peer_id = teammate.owner_peer_id
			target_role = "teammate_0"
			if ability_id > FootballPlayer.ABILITY_NONE and teammate.selected_ability > FootballPlayer.ABILITY_NONE:
				combination_id = "ability_%d_to_%d" % [
					ability_id,
					teammate.selected_ability
				]
	var goal := _target_goal_for_team(team)
	if goal != null and direction.dot(kick_position.direction_to(_get_goal_center(goal))) > 0.82:
		target = _get_goal_center(goal)
		target_role = "goal"
	var normalized_target := _normalize_demo_position(target, team)
	var lead := [0.0, 0.0]
	if target_role == "teammate_0":
		var normalized_teammate := _normalize_demo_position(target_teammate_position, team)
		lead = [
			float(normalized_target[0]) - float(normalized_teammate[0]),
			float(normalized_target[1]) - float(normalized_teammate[1])
		]
	_record_human_demonstration_event(player, &"pass" if player.server_last_kick_was_soft_pass or target_peer_id > 0 else &"kick", {
		"position": _normalize_demo_position(kick_position, team),
		"velocity": _normalized_demo_velocity(predicted_velocity, team),
		"aim": _normalized_demo_direction(direction, team),
		"move": _normalized_demo_direction(player.server_direction, team),
		"target": normalized_target,
		"target_role": target_role,
		"lead": lead,
		"target_peer_id": target_peer_id,
		"combination_id": combination_id,
		"charge": player.server_last_kick_charge_seconds,
		"force": kick_force,
		"pass_type": "soft" if player.server_last_kick_was_soft_pass else "charged",
		"ability_id": ability_id,
		"cooldown_ready": true
	})


func _normalize_demo_position(position: Vector2, team: StringName) -> Array:
	var x := clampf((position.x - 360.0) / (6970.0 - 360.0), 0.0, 1.0)
	var y := clampf((position.y - 680.0) / (4320.0 - 680.0), 0.0, 1.0)
	if team == TEAM_RED:
		x = 1.0 - x
	return [snappedf(x, 0.0001), snappedf(y, 0.0001)]


func _normalized_demo_velocity(velocity: Vector2, team: StringName) -> Array:
	var normalized := velocity / 3200.0
	if team == TEAM_RED:
		normalized.x *= -1.0
	return [snappedf(normalized.x, 0.0001), snappedf(normalized.y, 0.0001)]


func _normalized_demo_direction(direction: Vector2, team: StringName) -> Array:
	var normalized := direction.normalized()
	if team == TEAM_RED:
		normalized.x *= -1.0
	return [snappedf(normalized.x, 0.0001), snappedf(normalized.y, 0.0001)]


func _demo_array_distance(a_value: Variant, b_value: Variant) -> float:
	var a := a_value as Array
	var b := b_value as Array
	if a.size() < 2 or b.size() < 2:
		return INF
	return Vector2(float(a[0]), float(a[1])).distance_to(Vector2(float(b[0]), float(b[1])))


func _on_ball_wall_collision_replay_event(speed: float) -> void:
	if (
		not multiplayer.is_server()
		or not game_has_started
		or round_resetting
		or goal_replay_active
	):
		return
	_record_goal_replay_event({
		"type": &"wall_collision",
		"speed": maxf(0.0, speed),
		"position": (
			ball.global_position if ball != null else Vector2.ZERO
		)
	})


func _record_goal_replay_event(event_data: Dictionary) -> void:
	if not multiplayer.is_server() or goal_replay_active:
		return
	var stored := event_data.duplicate(true)
	stored["time_msec"] = Time.get_ticks_msec()
	_goal_replay_events.append(stored)


func _on_ball_player_touch(
	peer_id: int,
	player_name: String,
	player_team: StringName,
	incoming_velocity: Vector2
) -> void:
	if (
		not multiplayer.is_server()
		or not game_has_started
		or freeplay_active
		or penalty_shootout_active
	):
		return
	var previous_touch_team := _cpu_last_touch_team
	var previous_touch_peer_id := _cpu_last_touch_peer_id
	var touched_player := _get_player(peer_id)
	if touched_player != null and not touched_player.cpu_controlled:
		var event_type: StringName = &"reception"
		if previous_touch_team in [TEAM_BLUE, TEAM_RED] and previous_touch_team != player_team:
			event_type = &"interception"
		_record_human_demonstration_event(touched_player, event_type, {
			"incoming_velocity": _normalized_demo_velocity(incoming_velocity, player_team),
			"target": _normalize_demo_position(ball.global_position, player_team),
			"ability_id": touched_player.server_active_ability_id if touched_player.server_ability_active else FootballPlayer.ABILITY_NONE
		})
	if previous_touch_team in [TEAM_BLUE, TEAM_RED] and previous_touch_team != player_team:
		var losing_player := _get_player(previous_touch_peer_id)
		if losing_player != null and not losing_player.cpu_controlled:
			_record_human_demonstration_event(losing_player, &"possession_loss", {
				"to_peer_id": peer_id,
				"ball": _normalize_demo_position(ball.global_position, losing_player.team)
			})
	_update_cpu_possession_from_touch(peer_id, player_team)
	_resolve_completed_pass_touch(
		peer_id,
		player_team
	)
	if _active_shot.is_empty():
		return

	var shooter_peer_id := int(
		_active_shot.get("shooter_peer_id", 0)
	)
	if peer_id == shooter_peer_id:
		return

	var defending_team := StringName(
		_active_shot.get("defending_team", NO_TEAM)
	)
	var target_goal := (
		_active_shot.get("target_goal") as FootballGoal
	)
	var save_was_possible := (
		player_team == defending_team
		and _is_save_threat(
			ball.global_position,
			incoming_velocity,
			target_goal
		)
	)

	_active_shot.clear()
	var shooter := _get_player(shooter_peer_id)
	if shooter != null and not shooter.cpu_controlled:
		_record_human_demonstration_event(shooter, &"shot_result", {
			"on_target": save_was_possible,
			"blocked": true
		})
	if not save_was_possible:
		return

	_save_check_generation += 1
	var generation := _save_check_generation
	_resolve_save_candidate.call_deferred(
		generation,
		peer_id,
		player_name,
		player_team,
		target_goal
	)


func _resolve_completed_pass_touch(
	receiver_peer_id: int,
	receiver_team: StringName
) -> void:
	if _pending_pass.is_empty():
		return

	var passer_peer_id := int(
		_pending_pass.get("peer_id", 0)
	)
	var passer_team := StringName(
		_pending_pass.get("team", NO_TEAM)
	)
	var kick_position := Vector2(
		_pending_pass.get("position", Vector2.ZERO)
	)
	var kick_time_msec := int(
		_pending_pass.get("time_msec", 0)
	)
	var elapsed_seconds := (
		float(Time.get_ticks_msec() - kick_time_msec)
		/ 1000.0
	)
	var travelled_distance := (
		ball.global_position.distance_to(kick_position)
		if ball != null
		else 0.0
	)
	_cpu_pass_intentions.erase(receiver_peer_id)

	var passer := _get_player(passer_peer_id)
	# Any new player touch resolves this pass attempt.
	_pending_pass.clear()
	if (
		receiver_peer_id <= 0
		or receiver_peer_id == passer_peer_id
		or receiver_team != passer_team
		or elapsed_seconds
		> maxf(0.1, completed_pass_max_seconds)
		or travelled_distance
		< maxf(0.0, completed_pass_minimum_distance)
	):
		if passer != null and not passer.cpu_controlled:
			_record_human_demonstration_event(passer, &"pass_failed", {
				"receiver_peer_id": receiver_peer_id,
				"travel_seconds": elapsed_seconds
			})
		return

	_increment_player_stat(passer_peer_id, "passes")
	_apply_completed_pass_draft_perks(
		passer,
		_get_player(receiver_peer_id)
	)
	_increment_cpu_benchmark_metric(passer_team, "completed_passes")
	_human_demo_recent_completed_passes[passer_team] = {
		"passer_peer_id": passer_peer_id,
		"receiver_peer_id": receiver_peer_id,
		"time": _human_demo_time()
	}
	if passer != null and not passer.cpu_controlled:
		_record_human_demonstration_event(passer, &"pass_completed", {
			"receiver_peer_id": receiver_peer_id,
			"travel_seconds": elapsed_seconds,
			"target_role": "teammate_0"
		})


func _apply_completed_pass_draft_perks(
	passer: FootballPlayer,
	receiver: FootballPlayer
) -> void:
	if (
		passer == null
		or receiver == null
		or passer.team != receiver.team
	):
		return
	# Haaland's Relentless Nine is an intrinsic boss trait. A completed feed
	# activates it in every game mode without assigning a Draft perk to him.
	if receiver.is_haaland_boss():
		receiver.activate_haaland_predator_finish()
	if not champions_league_mode:
		return
	if passer.draft_perk_id == 13:
		receiver._grant_draft_perk_next_shot(
			1.30,
			5.0,
			receiver._server_time_seconds()
		)
	elif passer.draft_perk_id == 15:
		passer._grant_draft_perk_movement_boost(
			1.20,
			1.20,
			2.0,
			passer._server_time_seconds()
		)
		receiver._grant_draft_perk_movement_boost(
			1.20,
			1.20,
			2.0,
			receiver._server_time_seconds()
		)
	elif (
		passer.draft_perk_id == 37
		and passer.server_last_ability_used_at > 0.0
		and passer._server_time_seconds() - passer.server_last_ability_used_at <= 5.0
	):
		receiver._refresh_draft_perk_ability(receiver._server_time_seconds())
	if receiver.draft_perk_id == 36:
		var receiver_now := receiver._server_time_seconds()
		receiver._grant_draft_perk_next_shot(1.45, 4.0, receiver_now)
		receiver._grant_draft_perk_next_pass(1.45, 4.0, receiver_now)


func _update_cpu_possession_from_touch(
	peer_id: int,
	player_team: StringName
) -> void:
	if peer_id <= 0 or player_team not in [TEAM_BLUE, TEAM_RED]:
		return
	_notify_cpu_tactical_global_event(&"player_touch")
	_notify_cpu_tactical_peer_event(peer_id, &"received_ball_touch")
	var now_msec := Time.get_ticks_msec()
	var previous_team := _cpu_possession_team
	var previous_peer_id := _cpu_last_touch_peer_id
	_cpu_last_touch_team = player_team
	_cpu_last_touch_peer_id = peer_id
	_cpu_last_touch_msec = now_msec
	invalidate_cpu_shared_world_model()
	_cpu_possession_team = player_team
	_cpu_possession_candidate_team = NO_TEAM
	_cpu_possession_candidate_since_msec = 0

	if previous_team in [TEAM_BLUE, TEAM_RED] and previous_team != player_team:
		_increment_cpu_benchmark_metric(previous_team, "turnovers")
		var possession_winner := _get_player(peer_id)
		if possession_winner != null:
			possession_winner.trigger_draft_perk(&"possession_won")
			if possession_winner.draft_perk_id == 40:
				var winner_now := possession_winner._server_time_seconds()
				possession_winner._reduce_draft_perk_cooldown_seconds(3.0, winner_now)
				var possession_victim := _get_player(previous_peer_id)
				if (
					possession_victim != null
					and possession_victim.team != possession_winner.team
				):
					possession_victim._add_draft_perk_cooldown_seconds(
						3.0,
						possession_victim._server_time_seconds(),
						true
					)
		# A real turnover invalidates chase ownership and all short-lived tactical
		# declarations immediately. CPUs must react to the new play, not finish
		# the run they planned before possession changed.
		_cpu_ball_commitments.clear()
		_cpu_tactical_intentions.clear()

	# A touch by the intended passer is the actual kick and keeps its receiving
	# instruction alive. Any other touch resolves that instruction, including an
	# interception or a teammate collecting a loose ball.
	for receiver_key in _cpu_pass_intentions.keys():
		var intention := _cpu_pass_intentions.get(receiver_key, {}) as Dictionary
		if int(intention.get("passer_peer_id", 0)) != peer_id:
			_cpu_pass_intentions.erase(receiver_key)

	_update_cpu_combination_plan_from_touch(peer_id, player_team, now_msec)


func _update_cpu_combination_plan_from_touch(
	peer_id: int,
	player_team: StringName,
	now_msec: int
) -> void:
	for team_key in _cpu_combination_plans.keys():
		var plan_team := StringName(team_key)
		var plan := _cpu_combination_plans.get(team_key, {}) as Dictionary
		if plan_team != player_team:
			if StringName(plan.get("play_type", &"")) == CPU_COMBO_GOALKEEPER_REBOUND:
				var expected_keeper_peer_id := int(plan.get("next_peer_id", 0))
				if peer_id == expected_keeper_peer_id:
					# The planned save occurred. Keep the follower's reservation alive
					# just long enough to react to the real rebound velocity.
					plan["phase"] = &"rebound"
					plan["last_touch_peer_id"] = peer_id
					plan["expires_msec"] = now_msec + 1400
					_cpu_combination_plans[team_key] = plan
					continue
				_cpu_pass_intentions.erase(
					int(plan.get("receiver_peer_id", 0))
				)
			_cpu_combination_plans.erase(team_key)
			continue
		var phase := StringName(plan.get("phase", &"setup"))
		var initiator_peer_id := int(plan.get("initiator_peer_id", 0))
		var receiver_peer_id := int(plan.get("receiver_peer_id", 0))
		var next_peer_id := int(plan.get("next_peer_id", 0))
		var play_type := StringName(plan.get("play_type", &""))
		if play_type in [
			CPU_COMBO_DEAD_ZONE_TRAP_VOLLEY,
			CPU_COMBO_POWER_STRIKE_TRAP_VOLLEY,
			CPU_COMBO_OVERDRIVE_DEAD_ZONE
		]:
			if peer_id == receiver_peer_id:
				# Receiving is the final action: do not transform this play into a
				# generic relay and pull the player away from its contact point.
				_cpu_combination_plans.erase(team_key)
			elif peer_id != initiator_peer_id:
				_cpu_combination_plans.erase(team_key)
			continue
		if play_type == CPU_COMBO_GOALKEEPER_REBOUND:
			if peer_id == receiver_peer_id:
				_cpu_pass_intentions.erase(receiver_peer_id)
				_cpu_combination_plans.erase(team_key)
			elif peer_id != initiator_peer_id:
				_cpu_pass_intentions.erase(receiver_peer_id)
				_cpu_combination_plans.erase(team_key)
			continue
		if phase == &"relay" and peer_id == next_peer_id:
			_cpu_combination_plans.erase(team_key)
		elif peer_id == receiver_peer_id:
			plan["phase"] = &"relay"
			plan["last_touch_peer_id"] = peer_id
			plan["expires_msec"] = now_msec + 1400
			_cpu_combination_plans[team_key] = plan
		elif phase == &"setup" and peer_id == initiator_peer_id:
			plan["last_touch_peer_id"] = peer_id
			_cpu_combination_plans[team_key] = plan
		else:
			_cpu_combination_plans.erase(team_key)


func invalidate_cpu_shared_world_model() -> void:
	_cpu_shared_world_frame = -1
	_cpu_shared_world_blue_roster_size = -1
	_cpu_shared_world_red_roster_size = -1
	_cpu_shared_spatial_frame = -1
	_cpu_shared_spatial_model.clear()
	_cpu_tactical_budget_frame = -1
	_cpu_tactical_budget_cache.clear()
	_cpu_possession_evaluated_frame = -1


func get_cpu_shared_world_model() -> Dictionary:
	if not multiplayer.is_server() or ball == null or not is_instance_valid(ball):
		return {}
	var physics_frame := int(Engine.get_physics_frames())
	if (
		_cpu_shared_world_frame == physics_frame
		and _cpu_shared_world_blue_roster_size == blue_players.size()
		and _cpu_shared_world_red_roster_size == red_players.size()
		and not _cpu_shared_world_model.is_empty()
	):
		return _cpu_shared_world_model
	_cpu_shared_world_model = _build_cpu_shared_world_model(physics_frame)
	_cpu_shared_world_frame = physics_frame
	_cpu_shared_world_blue_roster_size = blue_players.size()
	_cpu_shared_world_red_roster_size = red_players.size()
	_cpu_shared_world_serial += 1
	_cpu_shared_world_model["build_serial"] = _cpu_shared_world_serial
	return _cpu_shared_world_model


func _build_cpu_shared_world_model(physics_frame: int) -> Dictionary:
	var ball_position := ball.global_position
	var ball_velocity := ball.linear_velocity
	var server_now := (
		float(Time.get_ticks_msec()) / 1000.0
		* maxf(1.0, Engine.time_scale)
	)
	var blue_active: Array[FootballPlayer] = []
	var red_active: Array[FootballPlayer] = []
	var blue_goalkeeper_candidates: Array[FootballPlayer] = []
	var red_goalkeeper_candidates: Array[FootballPlayer] = []
	var blue_snapshots: Array[Dictionary] = []
	var red_snapshots: Array[Dictionary] = []
	var players_by_peer: Dictionary = {}
	var snapshots_by_peer: Dictionary = {}
	var distance_by_peer: Dictionary = {}
	var control_by_peer: Dictionary = {}
	var blue_nearest_ball_distance := INF
	var red_nearest_ball_distance := INF
	var blue_nearest_ball_peer_id: int = 0
	var red_nearest_ball_peer_id: int = 0
	var blue_has_control := false
	var red_has_control := false

	# First pass: collect the active world and common spatial facts. Goalkeeper
	# candidates are collected here too so designation does not rescan the roster.
	for team_variant in [TEAM_BLUE, TEAM_RED]:
		var team := StringName(team_variant)
		var roster: Array[FootballPlayer] = blue_players if team == TEAM_BLUE else red_players
		for player: FootballPlayer in roster:
			if not is_instance_valid(player):
				continue
			if player.cpu_controlled:
				if team == TEAM_BLUE:
					blue_goalkeeper_candidates.append(player)
				else:
					red_goalkeeper_candidates.append(player)
			if not player.controls_enabled:
				continue
			var distance_to_ball := player.global_position.distance_to(ball_position)
			var has_control := distance_to_ball <= maxf(
				100.0,
				player.kick_feedback_detection_distance * 1.05
			)
			players_by_peer[player.owner_peer_id] = player
			distance_by_peer[player.owner_peer_id] = distance_to_ball
			control_by_peer[player.owner_peer_id] = has_control
			if team == TEAM_BLUE:
				blue_active.append(player)
				if distance_to_ball < blue_nearest_ball_distance:
					blue_nearest_ball_distance = distance_to_ball
					blue_nearest_ball_peer_id = player.owner_peer_id
				blue_has_control = blue_has_control or has_control
			else:
				red_active.append(player)
				if distance_to_ball < red_nearest_ball_distance:
					red_nearest_ball_distance = distance_to_ball
					red_nearest_ball_peer_id = player.owner_peer_id
				red_has_control = red_has_control or has_control

	var blue_goalkeeper := _select_designated_cpu_goalkeeper_from_candidates(blue_goalkeeper_candidates)
	var red_goalkeeper := _select_designated_cpu_goalkeeper_from_candidates(red_goalkeeper_candidates)

	# Second pass builds the canonical actor snapshots once. Both the large-team
	# worker brain and team-sequence planner consume these same dictionaries.
	for player: FootballPlayer in blue_active:
		var actor := _cpu_shared_world_actor_snapshot(
			player,
			player == blue_goalkeeper,
			server_now,
			float(distance_by_peer.get(player.owner_peer_id, INF)),
			bool(control_by_peer.get(player.owner_peer_id, false))
		)
		blue_snapshots.append(actor)
		snapshots_by_peer[player.owner_peer_id] = actor
	for player: FootballPlayer in red_active:
		var actor := _cpu_shared_world_actor_snapshot(
			player,
			player == red_goalkeeper,
			server_now,
			float(distance_by_peer.get(player.owner_peer_id, INF)),
			bool(control_by_peer.get(player.owner_peer_id, false))
		)
		red_snapshots.append(actor)
		snapshots_by_peer[player.owner_peer_id] = actor

	var last_touch_team := NO_TEAM
	var last_touch_player := players_by_peer.get(ball.last_touch_peer_id) as FootballPlayer
	if is_instance_valid(last_touch_player):
		last_touch_team = last_touch_player.team
	return {
		"physics_frame": physics_frame,
		"ball_position": ball_position,
		"ball_velocity": ball_velocity,
		"ball_linear_damp": ball.linear_damp,
		"last_touch_peer_id": ball.last_touch_peer_id,
		"last_touch_team": last_touch_team,
		"blue_active_players": blue_active,
		"red_active_players": red_active,
		"blue_snapshots": blue_snapshots,
		"red_snapshots": red_snapshots,
		"players_by_peer": players_by_peer,
		"snapshots_by_peer": snapshots_by_peer,
		"blue_active_count": blue_active.size(),
		"red_active_count": red_active.size(),
		"blue_nearest_ball_distance": blue_nearest_ball_distance,
		"red_nearest_ball_distance": red_nearest_ball_distance,
		"blue_nearest_ball_peer_id": blue_nearest_ball_peer_id,
		"red_nearest_ball_peer_id": red_nearest_ball_peer_id,
		"blue_has_control": blue_has_control,
		"red_has_control": red_has_control,
		# Exact CPU movement bounds/walls used by the Part 2 pure-data trajectory
		# processor. These match the authored CPU controller defaults.
		"ai_field_bounds": Rect2(360.0, 680.0, 6610.0, 3640.0),
		"ball_wall_top_y": 806.0,
		"ball_wall_bottom_y": 4194.0,
		"blue_goalkeeper_peer_id": blue_goalkeeper.owner_peer_id if is_instance_valid(blue_goalkeeper) else 0,
		"red_goalkeeper_peer_id": red_goalkeeper.owner_peer_id if is_instance_valid(red_goalkeeper) else 0,
	}


func _select_designated_cpu_goalkeeper_from_candidates(
	candidates: Array[FootballPlayer]
) -> FootballPlayer:
	var best_goalkeeper: FootballPlayer
	var best_rating: float = -INF
	for player: FootballPlayer in candidates:
		if not is_instance_valid(player):
			continue
		var rating: float = _get_cpu_goalkeeper_suitability(player)
		if (
			rating > best_rating
			or (
				is_equal_approx(rating, best_rating)
				and best_goalkeeper != null
				and (
					player.team_slot < best_goalkeeper.team_slot
					or (
						player.team_slot == best_goalkeeper.team_slot
						and player.owner_peer_id < best_goalkeeper.owner_peer_id
					)
				)
			)
		):
			best_rating = rating
			best_goalkeeper = player
	return best_goalkeeper


func _cpu_shared_world_actor_snapshot(
	player: FootballPlayer,
	is_goalkeeper: bool,
	server_now: float,
	distance_to_ball: float,
	has_control: bool
) -> Dictionary:
	return {
		"peer_id": player.owner_peer_id,
		"team": player.team,
		"team_slot": player.team_slot,
		"position": player.global_position,
		"velocity": player.linear_velocity,
		"max_speed": player.max_speed,
		"acceleration": player.acceleration,
		"control_radius": maxf(40.0, player.kick_feedback_detection_distance * 0.72),
		"enabled": player.controls_enabled,
		"cpu_controlled": player.cpu_controlled,
		"goalkeeper": is_goalkeeper,
		"has_ball": player.cpu_has_kickable_ball(),
		"has_control": has_control,
		"distance_to_ball": distance_to_ball,
		"charging": player.server_is_charging,
		"role": _large_team_parallel_natural_role(player),
		"ability_id": player.selected_ability,
		"ability_active_id": player.server_active_ability_id,
		"ability_ready": (
			player.selected_ability != FootballPlayer.ABILITY_NONE
			and player.server_ability_cooldown_ends_at <= server_now
		),
	}


func get_cpu_shared_active_players(team: StringName) -> Array:
	var world := get_cpu_shared_world_model()
	if team == TEAM_BLUE:
		return world.get("blue_active_players", []) as Array
	if team == TEAM_RED:
		return world.get("red_active_players", []) as Array
	return []


func get_cpu_shared_active_count(team: StringName) -> int:
	var world := get_cpu_shared_world_model()
	if team == TEAM_BLUE:
		return int(world.get("blue_active_count", 0))
	if team == TEAM_RED:
		return int(world.get("red_active_count", 0))
	return 0


func get_cpu_shared_player(peer_id: int) -> FootballPlayer:
	if peer_id <= 0:
		return null
	var world := get_cpu_shared_world_model()
	return world.get("players_by_peer", {}).get(peer_id) as FootballPlayer


func get_cpu_shared_nearest_ball_distance(team: StringName) -> float:
	var world := get_cpu_shared_world_model()
	if team == TEAM_BLUE:
		return float(world.get("blue_nearest_ball_distance", INF))
	if team == TEAM_RED:
		return float(world.get("red_nearest_ball_distance", INF))
	return INF


func _notify_cpu_tactical_global_event(reason: StringName) -> void:
	_cpu_tactical_global_event_serial += 1
	_cpu_tactical_global_event_reason = reason
	_cpu_tactical_budget_frame = -1


func _notify_cpu_tactical_peer_event(peer_id: int, reason: StringName) -> void:
	if peer_id <= 0:
		return
	_cpu_tactical_peer_event_serials[peer_id] = (
		int(_cpu_tactical_peer_event_serials.get(peer_id, 0)) + 1
	)
	_cpu_tactical_peer_event_reasons[peer_id] = reason
	_cpu_tactical_budget_frame = -1


func _cpu_tactical_interval_for_tier(tier: StringName) -> float:
	match tier:
		CPU_TACTICAL_TIER_CRITICAL:
			return CPU_TACTICAL_CRITICAL_INTERVAL
		CPU_TACTICAL_TIER_HIGH:
			return CPU_TACTICAL_HIGH_INTERVAL
		CPU_TACTICAL_TIER_LOW:
			return CPU_TACTICAL_LOW_INTERVAL
		_:
			return CPU_TACTICAL_NORMAL_INTERVAL


func _build_cpu_tactical_budget_cache() -> void:
	var world := get_cpu_shared_world_model()
	_cpu_tactical_budget_cache.clear()
	if world.is_empty():
		return
	var blue_count := int(world.get("blue_active_count", 0))
	var red_count := int(world.get("red_active_count", 0))
	if maxi(blue_count, red_count) < CPU_TACTICAL_BUDGET_MIN_TEAM_SIZE:
		return
	var possession_team := get_cpu_possession_team()
	var blue_chaser := int(world.get("blue_nearest_ball_peer_id", 0))
	var red_chaser := int(world.get("red_nearest_ball_peer_id", 0))
	# Becoming the nearest ball actor is an individual wake event. This keeps the
	# chaser handoff responsive even if that player was previously on a low-rate
	# off-ball tactical budget.
	if blue_chaser > 0 and blue_chaser != _cpu_tactical_last_blue_chaser_peer_id:
		_notify_cpu_tactical_peer_event(blue_chaser, &"became_ball_chaser")
	if red_chaser > 0 and red_chaser != _cpu_tactical_last_red_chaser_peer_id:
		_notify_cpu_tactical_peer_event(red_chaser, &"became_ball_chaser")
	_cpu_tactical_last_blue_chaser_peer_id = blue_chaser
	_cpu_tactical_last_red_chaser_peer_id = red_chaser

	var shot_defending_team := StringName(_active_shot.get("defending_team", NO_TEAM))
	var shot_active := not _active_shot.is_empty()
	var snapshots := (world.get("blue_snapshots", []) as Array) + (world.get("red_snapshots", []) as Array)
	for actor_variant in snapshots:
		var actor := actor_variant as Dictionary
		var peer_id := int(actor.get("peer_id", 0))
		if peer_id <= 0:
			continue
		var team := StringName(actor.get("team", NO_TEAM))
		var distance_to_ball := float(actor.get("distance_to_ball", INF))
		var team_nearest := (
			float(world.get("blue_nearest_ball_distance", INF))
			if team == TEAM_BLUE
			else float(world.get("red_nearest_ball_distance", INF))
		)
		var is_chaser := peer_id == (blue_chaser if team == TEAM_BLUE else red_chaser)
		var is_receiver := _cpu_pass_intentions.has(peer_id)
		var is_goalkeeper := bool(actor.get("goalkeeper", false))
		var has_control := bool(actor.get("has_control", false)) or bool(actor.get("has_ball", false))
		var tier := CPU_TACTICAL_TIER_LOW
		var reason := &"far_off_ball"
		if has_control or is_chaser or is_receiver:
			tier = CPU_TACTICAL_TIER_CRITICAL
			reason = &"direct_ball_actor"
		elif shot_active and team == shot_defending_team and is_goalkeeper:
			tier = CPU_TACTICAL_TIER_CRITICAL
			reason = &"shot_goalkeeper"
		elif shot_active and team == shot_defending_team:
			tier = CPU_TACTICAL_TIER_HIGH
			reason = &"shot_defense"
		elif distance_to_ball <= team_nearest + 500.0 or distance_to_ball <= 1000.0:
			tier = CPU_TACTICAL_TIER_HIGH
			reason = &"near_play"
		elif distance_to_ball <= 2200.0 or possession_team == team:
			tier = CPU_TACTICAL_TIER_NORMAL
			reason = &"shape_support"
		_cpu_tactical_budget_cache[peer_id] = {
			"tier": tier,
			"interval": _cpu_tactical_interval_for_tier(tier),
			"critical": tier == CPU_TACTICAL_TIER_CRITICAL,
			"reason": reason,
		}


func get_cpu_tactical_update_budget(peer_id: int, team: StringName) -> Dictionary:
	if not multiplayer.is_server() or peer_id <= 0:
		return {}
	var world := get_cpu_shared_world_model()
	if world.is_empty():
		return {}
	var team_count := (
		int(world.get("blue_active_count", 0))
		if team == TEAM_BLUE
		else int(world.get("red_active_count", 0))
	)
	if team_count < CPU_TACTICAL_BUDGET_MIN_TEAM_SIZE:
		return {}
	var frame := int(world.get("physics_frame", -1))
	if _cpu_tactical_budget_frame != frame:
		_build_cpu_tactical_budget_cache()
		# Event discovery during the build (for example a new nearest chaser) can
		# invalidate the cache token. Stamp the completed frame afterwards so the
		# remaining CPUs reuse this one result instead of rebuilding it 12 times.
		_cpu_tactical_budget_frame = frame
	var result := (_cpu_tactical_budget_cache.get(peer_id, {}) as Dictionary).duplicate(false)
	if result.is_empty():
		result = {
			"tier": CPU_TACTICAL_TIER_NORMAL,
			"interval": CPU_TACTICAL_NORMAL_INTERVAL,
			"critical": false,
			"reason": &"fallback",
		}
	result["global_event_serial"] = _cpu_tactical_global_event_serial
	result["global_event_reason"] = _cpu_tactical_global_event_reason
	result["peer_event_serial"] = int(_cpu_tactical_peer_event_serials.get(peer_id, 0))
	result["peer_event_reason"] = StringName(_cpu_tactical_peer_event_reasons.get(peer_id, &""))
	return result


func get_cpu_shared_spatial_model() -> Dictionary:
	var world := get_cpu_shared_world_model()
	if world.is_empty():
		return {}
	var physics_frame := int(world.get("physics_frame", -1))
	if (
		_cpu_shared_spatial_frame == physics_frame
		and not _cpu_shared_spatial_model.is_empty()
	):
		return _cpu_shared_spatial_model
	_cpu_shared_spatial_model = SharedAISpatialProcessorScript.build(world)
	_cpu_shared_spatial_frame = physics_frame
	return _cpu_shared_spatial_model


func get_cpu_shared_nearest_opponent_query(
	team: StringName,
	position: Vector2
) -> Dictionary:
	var spatial := get_cpu_shared_spatial_model()
	if spatial.is_empty():
		return {"peer_id": 0, "distance": INF}
	return SharedAISpatialProcessorScript.query_nearest_opponent(
		spatial,
		team,
		position
	)


func get_cpu_shared_ball_trajectory() -> Array:
	var spatial := get_cpu_shared_spatial_model()
	return spatial.get("ball_trajectory", []) as Array


func get_cpu_shared_pair_distance(
	first_peer_id: int,
	second_peer_id: int
) -> float:
	var spatial := get_cpu_shared_spatial_model()
	if spatial.is_empty():
		return INF
	return float(SharedAISpatialProcessorScript.query_pair_distance(
		spatial,
		first_peer_id,
		second_peer_id
	))


func get_cpu_shared_player_arrival_seconds(
	peer_id: int,
	target: Vector2,
	high_seconds: float = 2.05
) -> float:
	var spatial := get_cpu_shared_spatial_model()
	if spatial.is_empty():
		return INF
	return float(SharedAISpatialProcessorScript.query_player_arrival_seconds(
		spatial,
		peer_id,
		target,
		high_seconds
	))


func get_cpu_shared_duel_interception_data(
	own_peer_id: int,
	opponent_peer_id: int
) -> Dictionary:
	var spatial := get_cpu_shared_spatial_model()
	if spatial.is_empty():
		return {}
	return SharedAISpatialProcessorScript.query_duel_interception(
		spatial,
		own_peer_id,
		opponent_peer_id
	)


func get_cpu_possession_team() -> StringName:
	if not multiplayer.is_server() or ball == null:
		return NO_TEAM
	var physics_frame := int(Engine.get_physics_frames())
	if _cpu_possession_evaluated_frame == physics_frame:
		return _cpu_possession_team
	_cpu_possession_evaluated_frame = physics_frame
	var world := get_cpu_shared_world_model()
	var now_msec := Time.get_ticks_msec()
	var blue_distance := float(world.get("blue_nearest_ball_distance", INF))
	var red_distance := float(world.get("red_nearest_ball_distance", INF))
	var blue_has_control := bool(world.get("blue_has_control", false))
	var red_has_control := bool(world.get("red_has_control", false))
	var opponent_has_taken_control := (
		(_cpu_last_touch_team == TEAM_BLUE and red_has_control and not blue_has_control)
		or (_cpu_last_touch_team == TEAM_RED and blue_has_control and not red_has_control)
	)
	var has_recent_team_touch := (
		_cpu_last_touch_team in [TEAM_BLUE, TEAM_RED]
		and now_msec - _cpu_last_touch_msec
		<= CPU_POSSESSION_TOUCH_LOCK_MSEC
	)
	var ball_is_still_in_team_flight := (
		_cpu_last_touch_team in [TEAM_BLUE, TEAM_RED]
		and ball.linear_velocity.length() >= CPU_POSSESSION_FLIGHT_SPEED
	)
	# A fast ball used to stay owned by the last-touch team indefinitely until
	# the opponent registered a kick. That made CPUs remain in attacking
	# positions while a human was already physically dribbling the ball away.
	# Keep the existing touch/flight lock only while the opponent has not clearly
	# taken control.
	if (has_recent_team_touch or ball_is_still_in_team_flight) and not opponent_has_taken_control:
		_cpu_possession_team = _cpu_last_touch_team
		_cpu_possession_candidate_team = NO_TEAM
		_cpu_possession_candidate_since_msec = 0
		return _cpu_possession_team

	var candidate_team := NO_TEAM
	if blue_distance + CPU_POSSESSION_DISTANCE_MARGIN < red_distance:
		candidate_team = TEAM_BLUE
	elif red_distance + CPU_POSSESSION_DISTANCE_MARGIN < blue_distance:
		candidate_team = TEAM_RED
	if candidate_team == NO_TEAM:
		# When neither side has actual control and the previous kick/touch lock has
		# expired, possession is genuinely neutral. Keeping the old team here made
		# CPUs run attacking/cover shapes around a ball nobody owned.
		if (
			not blue_has_control
			and not red_has_control
			and not has_recent_team_touch
			and not ball_is_still_in_team_flight
		):
			if _cpu_possession_team != NO_TEAM:
				_cpu_possession_team = NO_TEAM
				_notify_cpu_tactical_global_event(&"possession_became_loose")
				_cpu_possession_candidate_team = NO_TEAM
				_cpu_possession_candidate_since_msec = 0
				_cpu_ball_commitments.clear()
				_cpu_tactical_intentions.clear()
			return NO_TEAM
		return _cpu_possession_team
	if _cpu_possession_team == NO_TEAM:
		_cpu_possession_team = candidate_team
		_notify_cpu_tactical_global_event(&"possession_claimed")
		return _cpu_possession_team
	if candidate_team == _cpu_possession_team:
		_cpu_possession_candidate_team = NO_TEAM
		_cpu_possession_candidate_since_msec = 0
		return _cpu_possession_team
	if candidate_team != _cpu_possession_candidate_team:
		_cpu_possession_candidate_team = candidate_team
		_cpu_possession_candidate_since_msec = now_msec
		return _cpu_possession_team
	if (
		now_msec - _cpu_possession_candidate_since_msec
		>= CPU_POSSESSION_SWITCH_CONFIRM_MSEC
	):
		_cpu_possession_team = candidate_team
		_notify_cpu_tactical_global_event(&"possession_switched")
		_cpu_possession_candidate_team = NO_TEAM
		_cpu_possession_candidate_since_msec = 0
		_cpu_ball_commitments.clear()
		_cpu_tactical_intentions.clear()
		_cpu_pass_intentions.clear()
		_cpu_combination_plans.clear()
		_cpu_ability_team_plans.clear()
	return _cpu_possession_team


func _team_has_player_in_ball_control_range(
	players: Array[FootballPlayer]
) -> bool:
	if ball == null:
		return false
	for player in players:
		if not is_instance_valid(player) or not player.controls_enabled:
			continue
		if player.global_position.distance_to(ball.global_position) <= maxf(
			100.0,
			player.kick_feedback_detection_distance * 1.05
		):
			return true
	return false


func _nearest_active_player_distance_to_ball(
	players: Array[FootballPlayer]
) -> float:
	var nearest_distance := INF
	for player in players:
		if is_instance_valid(player) and player.controls_enabled:
			nearest_distance = minf(
				nearest_distance,
				player.global_position.distance_to(ball.global_position)
			)
	return nearest_distance


func _reset_cpu_possession_state() -> void:
	_cpu_shared_world_model.clear()
	_cpu_shared_world_frame = -1
	_cpu_shared_world_blue_roster_size = -1
	_cpu_shared_world_red_roster_size = -1
	_cpu_shared_spatial_model.clear()
	_cpu_shared_spatial_frame = -1
	_cpu_tactical_budget_frame = -1
	_cpu_tactical_budget_cache.clear()
	_cpu_tactical_global_event_serial = 0
	_cpu_tactical_global_event_reason = &""
	_cpu_tactical_peer_event_serials.clear()
	_cpu_tactical_peer_event_reasons.clear()
	_cpu_tactical_last_blue_chaser_peer_id = 0
	_cpu_tactical_last_red_chaser_peer_id = 0
	_cpu_possession_evaluated_frame = -1
	_cpu_defensive_assignments.clear()
	_cpu_team_sequence_frame_cache.clear()
	_large_team_parallel_plans.clear()
	_large_team_parallel_result_frame = -1
	_large_team_parallel_submit_frame = -1
	_large_team_parallel_service_frame = -1
	_large_team_parallel_next_due_msec.clear()
	_large_team_parallel_seen_global_event_serial.clear()
	_large_team_parallel_seen_peer_event_serial.clear()
	_cpu_team_sequence_async_tasks.clear()
	_cpu_ability_team_plans.clear()
	_cpu_large_team_support_cache.clear()
	_cpu_possession_team = NO_TEAM
	_cpu_possession_candidate_team = NO_TEAM
	_cpu_possession_candidate_since_msec = 0
	_cpu_last_touch_team = NO_TEAM
	_cpu_last_touch_peer_id = 0
	_cpu_last_touch_msec = 0


func get_large_team_support_assignment(
	team: StringName,
	requester_peer_id: int,
	carrier: FootballPlayer,
	planner
) -> Dictionary:
	if (
		team not in [TEAM_BLUE, TEAM_RED]
		or requester_peer_id <= 0
		or carrier == null
		or not is_instance_valid(carrier)
		or planner == null
		or not planner.has_method("get_support_assignments")
		or ball == null
		or not is_instance_valid(ball)
	):
		return {}
	var cache_key := str(team)
	var now := float(Time.get_ticks_msec()) / 1000.0
	var ball_position := ball.global_position
	var carrier_peer_id := carrier.owner_peer_id
	var active_count := get_cpu_shared_active_count(team)
	var cached: Dictionary = _cpu_large_team_support_cache.get(cache_key, {})
	var cached_ball: Vector2 = cached.get("ball_position", Vector2.INF)
	var cache_valid := (
		not cached.is_empty()
		and now <= float(cached.get("expires_at", -INF))
		and int(cached.get("carrier_peer_id", 0)) == carrier_peer_id
		and int(cached.get("active_count", -1)) == active_count
		and cached_ball.distance_to(ball_position) <= 210.0
	)
	if not cache_valid:
		var assignments_variant: Variant = planner.call(
			"get_support_assignments",
			carrier
		)
		var assignments: Dictionary = (
			assignments_variant as Dictionary
			if assignments_variant is Dictionary
			else {}
		)
		cached = {
			"expires_at": now + 0.42,
			"ball_position": ball_position,
			"carrier_peer_id": carrier_peer_id,
			"active_count": active_count,
			"assignments": assignments.duplicate(true)
		}
		_cpu_large_team_support_cache[cache_key] = cached
	var cached_assignments: Dictionary = cached.get("assignments", {})
	return (
		cached_assignments.get(str(requester_peer_id), {}) as Dictionary
	).duplicate(true)


func set_cpu_pass_intention(
	passer_peer_id: int,
	receiver_peer_id: int,
	receive_position: Vector2,
	lifetime_seconds: float = 1.8
) -> void:
	if (
		not multiplayer.is_server()
		or passer_peer_id <= 0
		or receiver_peer_id <= 0
		or passer_peer_id == receiver_peer_id
	):
		return
	_notify_cpu_tactical_peer_event(receiver_peer_id, &"incoming_pass")
	_cpu_pass_intentions[receiver_peer_id] = {
		"passer_peer_id": passer_peer_id,
		"position": receive_position,
		"expires_msec": (
			Time.get_ticks_msec()
			+ int(maxf(0.2, lifetime_seconds) * 1000.0)
		)
	}


func get_cpu_pass_intention(receiver_peer_id: int) -> Dictionary:
	if not multiplayer.is_server():
		return {}
	var intention := _cpu_pass_intentions.get(
		receiver_peer_id,
		{}
	) as Dictionary
	if intention.is_empty():
		return {}
	if Time.get_ticks_msec() > int(
		intention.get("expires_msec", 0)
	):
		_cpu_pass_intentions.erase(receiver_peer_id)
		return {}
	return intention


func clear_cpu_pass_intention(receiver_peer_id: int) -> void:
	if multiplayer.is_server() and receiver_peer_id > 0:
		_cpu_pass_intentions.erase(receiver_peer_id)


func commit_cpu_ball_chaser(
	team: StringName,
	candidate_peer_id: int,
	candidate_distance: float,
	lifetime_seconds: float = 0.7,
	takeover_ratio: float = 0.72
) -> int:
	if (
		not multiplayer.is_server()
		or candidate_peer_id <= 0
		or team not in [TEAM_BLUE, TEAM_RED]
	):
		return 0
	var now_msec := Time.get_ticks_msec()
	var commitment := _cpu_ball_commitments.get(team, {}) as Dictionary
	var current_peer_id := int(commitment.get("peer_id", 0))
	var current_distance := float(commitment.get("distance", INF))
	var expired := now_msec > int(commitment.get("expires_msec", 0))
	var candidate_is_current := current_peer_id == candidate_peer_id
	var clearly_better := (
		candidate_distance
		< current_distance * clampf(takeover_ratio, 0.1, 0.98)
	)
	if (
		commitment.is_empty()
		or expired
		or candidate_is_current
		or clearly_better
	):
		_cpu_ball_commitments[team] = {
			"peer_id": candidate_peer_id,
			"distance": maxf(0.0, candidate_distance),
			"expires_msec": (
				now_msec
				+ int(maxf(0.15, lifetime_seconds) * 1000.0)
			)
		}
		return candidate_peer_id
	return current_peer_id


func get_cpu_ball_chaser(team: StringName) -> int:
	if not multiplayer.is_server():
		return 0
	var commitment := _cpu_ball_commitments.get(team, {}) as Dictionary
	if commitment.is_empty():
		return 0
	if Time.get_ticks_msec() > int(commitment.get("expires_msec", 0)):
		_cpu_ball_commitments.erase(team)
		return 0
	return int(commitment.get("peer_id", 0))


func get_cpu_defensive_assignment(
	team: StringName,
	player_peer_id: int
) -> Dictionary:
	if (
		not multiplayer.is_server()
		or ball == null
		or team not in [TEAM_BLUE, TEAM_RED]
		or player_peer_id <= 0
	):
		return {}
	var now_msec := Time.get_ticks_msec()
	var cached := _cpu_defensive_assignments.get(team, {}) as Dictionary
	if (
		not cached.is_empty()
		and now_msec <= int(cached.get("expires_msec", 0))
		and _cpu_defensive_assignment_is_valid(team, cached)
	):
		return (cached.get("players", {}) as Dictionary).get(
			player_peer_id,
			{}
		) as Dictionary
	var assignment := _build_cpu_defensive_assignment(team, cached)
	_cpu_defensive_assignments[team] = assignment
	return (assignment.get("players", {}) as Dictionary).get(
		player_peer_id,
		{}
	) as Dictionary


func record_cpu_defense_event(
	team: StringName,
	metric: StringName,
	amount: float = 1.0
) -> void:
	if team not in [TEAM_BLUE, TEAM_RED] or metric.is_empty():
		return
	if not _cpu_defensive_telemetry.has(team):
		_cpu_defensive_telemetry[team] = {}
	var team_metrics := _cpu_defensive_telemetry[team] as Dictionary
	team_metrics[metric] = float(team_metrics.get(metric, 0.0)) + amount
	_cpu_defensive_telemetry[team] = team_metrics


func get_cpu_defense_telemetry(team: StringName) -> Dictionary:
	return (_cpu_defensive_telemetry.get(team, {}) as Dictionary).duplicate()


func reset_cpu_defense_telemetry() -> void:
	_cpu_defensive_telemetry.clear()


func _cpu_defensive_assignment_is_valid(
	team: StringName,
	assignment: Dictionary
) -> bool:
	var players := assignment.get("players", {}) as Dictionary
	for peer_id_variant in players.keys():
		var player := _get_player(int(peer_id_variant))
		if (
			player == null
			or not player.controls_enabled
			or not player.cpu_controlled
			or player.team != team
		):
			return false
	var presser_peer_id := int(assignment.get("presser_peer_id", 0))
	var presser := _get_player(presser_peer_id)
	if presser != null and ball != null:
		var opponent_team := TEAM_RED if team == TEAM_BLUE else TEAM_BLUE
		var world := get_cpu_shared_world_model()
		var opponents := get_cpu_shared_active_players(opponent_team)
		var opponent_has_control := bool(
			world.get(
				"red_has_control" if opponent_team == TEAM_RED else "blue_has_control",
				false
			)
		)
		var cached_carrier_peer_id := int(assignment.get("carrier_peer_id", 0))
		# A cached carrier assignment becomes nonsense as soon as the ball is loose,
		# and a loose-ball assignment must likewise be rebuilt when someone gains
		# control. Replan immediately instead of waiting up to 1.25 seconds.
		if (cached_carrier_peer_id > 0) != opponent_has_control:
			return false
		var carrier: FootballPlayer
		var carrier_distance := INF
		for opponent in opponents:
			if not is_instance_valid(opponent) or not opponent.controls_enabled:
				continue
			var distance: float = opponent.global_position.distance_to(ball.global_position)
			if opponent.owner_peer_id == ball.last_touch_peer_id:
				distance -= 280.0
			if distance < carrier_distance:
				carrier_distance = distance
				carrier = opponent
		if carrier != null and presser.global_position.distance_to(carrier.global_position) > 720.0:
			var roster := blue_players if team == TEAM_BLUE else red_players
			for candidate in roster:
				if (
					is_instance_valid(candidate)
					and candidate.controls_enabled
					and candidate.cpu_controlled
					and candidate.owner_peer_id != presser_peer_id
					and candidate.global_position.distance_to(carrier.global_position)
					< presser.global_position.distance_to(carrier.global_position) * 0.78
				):
					# A beaten/trailing presser is a safety exception: hand off now
					# instead of waiting for the normal role commitment expiry.
					return false
	return not players.is_empty()


func _build_cpu_defensive_assignment(
	team: StringName,
	previous: Dictionary
) -> Dictionary:
	var opponent_team := TEAM_RED if team == TEAM_BLUE else TEAM_BLUE
	var world := get_cpu_shared_world_model()
	var roster := get_cpu_shared_active_players(team)
	var opponents := get_cpu_shared_active_players(opponent_team)
	var own_goal := blue_goal if team == TEAM_BLUE else red_goal
	var goalkeeper := get_designated_cpu_goalkeeper(team)
	var all_cpu_players: Array[FootballPlayer] = []
	var outfield_players: Array[FootballPlayer] = []
	for player in roster:
		if (
			is_instance_valid(player)
			and player.controls_enabled
			and player.cpu_controlled
		):
			all_cpu_players.append(player)
			if player != goalkeeper:
				outfield_players.append(player)
	if all_cpu_players.is_empty() or own_goal == null:
		return {"players": {}, "expires_msec": Time.get_ticks_msec() + 300}
	var own_goal_center := Vector2(
		own_goal.get_goal_plane_x(),
		(own_goal.get_mouth_y_range().x + own_goal.get_mouth_y_range().y) * 0.5
	)
	var carrier: FootballPlayer
	var carrier_score := INF
	var opponent_has_control := bool(
		world.get(
			"red_has_control" if opponent_team == TEAM_RED else "blue_has_control",
			false
		)
	)
	if opponent_has_control:
		for opponent in opponents:
			if not is_instance_valid(opponent) or not opponent.controls_enabled:
				continue
			var score: float = opponent.global_position.distance_to(ball.global_position)
			if opponent.owner_peer_id == ball.last_touch_peer_id:
				score -= 280.0
			if score < carrier_score:
				carrier_score = score
				carrier = opponent
	var predicted_carrier := ball.global_position
	var toward_goal := ball.global_position.direction_to(own_goal_center)
	var wall_side := 1.0
	if carrier != null:
		predicted_carrier = carrier.global_position + carrier.linear_velocity * 0.38
		predicted_carrier.y = clampf(predicted_carrier.y, 880.0, 4120.0)
		toward_goal = predicted_carrier.direction_to(own_goal_center)
		wall_side = -1.0 if predicted_carrier.y < 2500.0 else 1.0
	else:
		# Nobody owns the ball: organize around where the ball itself is going,
		# not around whichever opponent happens to be nearest to it.
		predicted_carrier = ball.global_position + ball.linear_velocity * 0.24
		predicted_carrier.y = clampf(predicted_carrier.y, 880.0, 4120.0)
		toward_goal = predicted_carrier.direction_to(own_goal_center)
		wall_side = -1.0 if predicted_carrier.y < 2500.0 else 1.0
	if toward_goal.is_zero_approx():
		toward_goal = Vector2.RIGHT if own_goal_center.x > predicted_carrier.x else Vector2.LEFT
	var press_target := predicted_carrier
	if carrier != null:
		press_target = (
			predicted_carrier
			+ toward_goal * 250.0
			+ Vector2.UP * wall_side * 190.0
		)
	var cover_target := (
		predicted_carrier
		+ toward_goal * 500.0
		- Vector2.UP * wall_side * 245.0
	)
	var final_target := predicted_carrier.lerp(own_goal_center, 0.67)
	final_target = final_target.lerp(predicted_carrier, 0.16)

	var ball_goal_distance := ball.global_position.distance_to(own_goal_center)
	var carrier_goal_distance := (
		carrier.global_position.distance_to(own_goal_center)
		if carrier != null
		else ball_goal_distance
	)
	var ball_toward_goal := false
	if ball.linear_velocity.length() > 420.0:
		var live_goal_direction := ball.global_position.direction_to(own_goal_center)
		ball_toward_goal = (
			not live_goal_direction.is_zero_approx()
			and ball.linear_velocity.normalized().dot(live_goal_direction) > 0.30
		)
	var immediate_goal_threat := (
		ball_goal_distance < 2050.0
		or carrier_goal_distance < 2350.0
		or ball_toward_goal
	)

	var press_candidates: Array[FootballPlayer] = outfield_players.duplicate()
	var dynamic_two_player_rotation := (
		all_cpu_players.size() == 2
		and is_instance_valid(goalkeeper)
		and not immediate_goal_threat
	)
	if dynamic_two_player_rotation:
		var rotating_cover: FootballPlayer
		for candidate in all_cpu_players:
			if candidate != goalkeeper:
				rotating_cover = candidate
				break
		if rotating_cover != null:
			var keeper_press_distance := goalkeeper.global_position.distance_to(
				press_target
			)
			var cover_press_distance := rotating_cover.global_position.distance_to(
				press_target
			)
			var cover_goal_distance := rotating_cover.global_position.distance_to(
				own_goal_center
			)
			var keeper_goal_distance := goalkeeper.global_position.distance_to(
				own_goal_center
			)
			var cover_can_rotate_back := (
				cover_goal_distance <= ball_goal_distance * 0.78
				or cover_goal_distance <= keeper_goal_distance + 720.0
			)
			if (
				cover_can_rotate_back
				and keeper_press_distance
				< cover_press_distance * 0.86
			):
				# The nominal goalkeeper is currently the better defender to engage.
				# The teammate becomes the live final defender until the next handoff.
				press_candidates = all_cpu_players.duplicate()
	if press_candidates.is_empty():
		press_candidates = all_cpu_players.duplicate()

	var presser := _choose_cpu_defensive_player(
		press_candidates,
		press_target,
		int(previous.get("presser_peer_id", 0)),
		1.32 if all_cpu_players.size() == 2 else 1.45
	)
	var remaining: Array[FootballPlayer] = all_cpu_players.duplicate()
	if presser != null:
		remaining.erase(presser)
	var cover: FootballPlayer
	var final_defender: FootballPlayer
	if all_cpu_players.size() == 2:
		if not remaining.is_empty():
			final_defender = _choose_cpu_defensive_player(
				remaining,
				final_target,
				int(previous.get("final_peer_id", 0)),
				1.28,
				1.0
			)
	else:
		var cover_candidates: Array[FootballPlayer] = []
		for candidate in remaining:
			if candidate != goalkeeper:
				cover_candidates.append(candidate)
		cover = _choose_cpu_defensive_player(
			cover_candidates,
			cover_target,
			int(previous.get("cover_peer_id", 0)),
			1.35,
			0.35
		)
		if cover != null:
			remaining.erase(cover)
		var final_candidates: Array[FootballPlayer] = remaining.duplicate()
		final_defender = _choose_cpu_defensive_player(
			final_candidates,
			final_target,
			int(previous.get("final_peer_id", 0)),
			1.35,
			1.0
		)
		if final_defender != null:
			remaining.erase(final_defender)
		elif (
			is_instance_valid(goalkeeper)
			and goalkeeper.controls_enabled
			and goalkeeper.cpu_controlled
			and goalkeeper != presser
			and goalkeeper != cover
		):
			final_defender = goalkeeper

	var player_roles: Dictionary = {}
	if presser != null:
		player_roles[presser.owner_peer_id] = {
			"role": &"press",
			"target_peer_id": carrier.owner_peer_id if carrier != null else 0,
			"target_position": _clamp_cpu_defensive_target(press_target),
			"approach_lane": -wall_side
		}
	if cover != null:
		player_roles[cover.owner_peer_id] = {
			"role": &"cover",
			"target_peer_id": carrier.owner_peer_id if carrier != null else 0,
			"target_position": _clamp_cpu_defensive_target(cover_target),
			"approach_lane": wall_side
		}
	if final_defender != null:
		player_roles[final_defender.owner_peer_id] = {
			"role": &"final",
			"target_peer_id": carrier.owner_peer_id if carrier != null else 0,
			"target_position": _clamp_cpu_defensive_target(final_target),
			"approach_lane": 0.0
		}
	var previous_presser := int(previous.get("presser_peer_id", 0))
	if previous_presser > 0 and presser != null and previous_presser != presser.owner_peer_id:
		record_cpu_defense_event(team, &"role_handoffs")
		var old_presser := _get_player(previous_presser)
		if (
			old_presser != null
			and carrier != null
			and old_presser.global_position.distance_to(predicted_carrier) > 560.0
		):
			record_cpu_defense_event(team, &"defenders_bypassed")
	if presser != null and cover != null:
		var presser_target: Vector2 = player_roles[presser.owner_peer_id].get(
			"target_position",
			Vector2.ZERO
		)
		var cover_target_for_metric: Vector2 = player_roles[cover.owner_peer_id].get(
			"target_position",
			Vector2.ZERO
		)
		if presser_target.distance_to(cover_target_for_metric) < 210.0:
			record_cpu_defense_event(team, &"same_lane_defenders")
	var used_opponents: Dictionary = {}
	for defender in remaining:
		var mark := _choose_cpu_defensive_mark(
			opponents,
			used_opponents,
			carrier,
			own_goal_center,
			defender
		)
		player_roles[defender.owner_peer_id] = {
			"role": &"mark",
			"target_peer_id": mark.owner_peer_id if mark != null else 0
		}
		if mark != null:
			used_opponents[mark.owner_peer_id] = true
	return {
		"players": player_roles,
		"presser_peer_id": presser.owner_peer_id if presser != null else 0,
		"cover_peer_id": cover.owner_peer_id if cover != null else 0,
		"final_peer_id": final_defender.owner_peer_id if final_defender != null else 0,
		"carrier_peer_id": carrier.owner_peer_id if carrier != null else 0,
		"expires_msec": (
			Time.get_ticks_msec()
			+ _get_cpu_defensive_assignment_lifetime_msec(
				all_cpu_players.size()
			)
		)
	}


func _get_cpu_defensive_assignment_lifetime_msec(
	active_cpu_count: int
) -> int:
	if active_cpu_count <= 2:
		return 620
	# Champions League now receives most of Theodore League's quicker 3v3/4v4
	# defensive reshaping. INT 17 starts clearly faster than the old 1250 ms
	# cadence, INT 18/19 get progressively closer, and INT 20 stays at 480 ms.
	if cpu_ai_level >= 17:
		var elite_strength: float = clampf(
			0.70 + float(cpu_ai_level - 17) * 0.10,
			0.0,
			1.0
		)
		return int(round(lerpf(1250.0, 480.0, elite_strength)))
	return 1250


func _clamp_cpu_defensive_target(target: Vector2) -> Vector2:
	return Vector2(clampf(target.x, 420.0, 6980.0), clampf(target.y, 860.0, 4140.0))


func _choose_cpu_defensive_player(
	candidates: Array[FootballPlayer],
	target: Vector2,
	previous_peer_id: int,
	retention_ratio: float,
	football_role_bias_strength: float = 0.0
) -> FootballPlayer:
	var best: FootballPlayer
	var best_score: float = INF
	var previous: FootballPlayer
	var previous_score: float = INF
	for candidate in candidates:
		var distance: float = candidate.global_position.distance_to(target)
		var score: float = distance + (
			_get_singleplayer_ranked_football_role_defense_bias(candidate)
			* football_role_bias_strength
		)
		if candidate.owner_peer_id == previous_peer_id:
			previous = candidate
			previous_score = score
		if score < best_score:
			best_score = score
			best = candidate
	if previous != null and previous_score <= best_score * retention_ratio:
		return previous
	return best


func _choose_cpu_defensive_mark(
	opponents: Array[FootballPlayer],
	used_opponents: Dictionary,
	carrier: FootballPlayer,
	own_goal_center: Vector2,
	defender: FootballPlayer
) -> FootballPlayer:
	var best: FootballPlayer
	var best_score := INF
	for opponent in opponents:
		if (
			not is_instance_valid(opponent)
			or not opponent.controls_enabled
			or opponent == carrier
			or used_opponents.has(opponent.owner_peer_id)
		):
			continue
		var goal_threat := opponent.global_position.distance_to(own_goal_center)
		var lane_distance := _distance_to_segment(
			opponent.global_position,
			ball.global_position,
			own_goal_center
		)
		var score := (
			goal_threat * 0.48
			+ lane_distance * 0.62
			+ defender.global_position.distance_to(opponent.global_position) * 0.22
		)
		if opponent.owner_peer_id == ball.last_touch_peer_id:
			score -= 420.0
		if score < best_score:
			best_score = score
			best = opponent
	return best


func _distance_to_segment(
	point: Vector2,
	segment_start: Vector2,
	segment_end: Vector2
) -> float:
	var segment := segment_end - segment_start
	var length_squared := segment.length_squared()
	if length_squared <= 0.001:
		return point.distance_to(segment_start)
	var ratio := clampf(
		(point - segment_start).dot(segment) / length_squared,
		0.0,
		1.0
	)
	return point.distance_to(segment_start + segment * ratio)


func set_cpu_tactical_intention(
	peer_id: int,
	team: StringName,
	action: StringName,
	target_position: Vector2,
	target_peer_id: int = 0,
	lifetime_seconds: float = 0.45
) -> void:
	if not multiplayer.is_server() or peer_id <= 0:
		return
	_cpu_tactical_intentions[peer_id] = {
		"peer_id": peer_id,
		"team": team,
		"action": action,
		"target_position": target_position,
		"target_peer_id": target_peer_id,
		"expires_msec": (
			Time.get_ticks_msec()
			+ int(maxf(0.15, lifetime_seconds) * 1000.0)
		)
	}


func get_cpu_tactical_intention(peer_id: int) -> Dictionary:
	if not multiplayer.is_server():
		return {}
	var intention := _cpu_tactical_intentions.get(peer_id, {}) as Dictionary
	if intention.is_empty():
		return {}
	if Time.get_ticks_msec() > int(intention.get("expires_msec", 0)):
		_cpu_tactical_intentions.erase(peer_id)
		return {}
	return intention


func get_cpu_team_intentions(team: StringName) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not multiplayer.is_server():
		return result
	for peer_id_variant in _cpu_tactical_intentions.keys():
		var peer_id := int(peer_id_variant)
		var intention := get_cpu_tactical_intention(peer_id)
		if (
			not intention.is_empty()
			and StringName(intention.get("team", &"")) == team
		):
			result.append(intention)
	return result


func _initialize_large_team_parallel_brain() -> void:
	if _large_team_parallel_brain != null:
		return
	var planner_script := load(LARGE_TEAM_PARALLEL_BRAIN_PATH) as Script
	if planner_script == null:
		push_error(
			"Large-team parallel brain could not be loaded: %s"
			% LARGE_TEAM_PARALLEL_BRAIN_PATH
		)
		return
	_large_team_parallel_brain = planner_script.new()


func is_large_team_parallel_ai_active() -> bool:
	return _large_team_parallel_active()


func _large_team_parallel_active() -> bool:
	var physics_frame := int(Engine.get_physics_frames())
	if physics_frame == _large_team_parallel_active_cache_frame:
		return _large_team_parallel_active_cached
	_large_team_parallel_active_cache_frame = physics_frame
	_large_team_parallel_active_cached = false
	# The iOS-friendly/default Godot Web export is intentionally single-threaded.
	# Never submit WorkerThreadPool jobs there; Parts 1-3 (shared world/spatial
	# state + significance budgets) remain active as the deterministic fallback.
	if OS.has_feature("web"):
		return false
	if OS.get_processor_count() < LARGE_TEAM_PARALLEL_MINIMUM_LOGICAL_PROCESSORS:
		return false
	if not multiplayer.is_server() or ball == null or not is_instance_valid(ball):
		return false
	var world := get_cpu_shared_world_model()
	var blue_active := int(world.get("blue_active_count", 0))
	var red_active := int(world.get("red_active_count", 0))
	_large_team_parallel_active_cached = maxi(blue_active, red_active) >= 5
	return _large_team_parallel_active_cached


func get_large_team_parallel_plan(peer_id: int) -> Dictionary:
	if peer_id <= 0 or not _large_team_parallel_active():
		return {}
	if _large_team_parallel_brain == null:
		_initialize_large_team_parallel_brain()
	if _large_team_parallel_brain == null:
		return {}
	# Service the shared worker batch once per physics frame, not once for every
	# CPU asking for its plan. Twelve bots used to repeat the same poll loop.
	var physics_frame := int(Engine.get_physics_frames())
	if _large_team_parallel_service_frame != physics_frame:
		_large_team_parallel_service_frame = physics_frame
		_poll_large_team_parallel_brain()
		_submit_large_team_parallel_snapshot_if_needed()
	var plan := _large_team_parallel_plans.get(peer_id, {}) as Dictionary
	if plan.is_empty():
		return {}
	# Part 4 keeps low-significance off-ball plans alive for their own tactical
	# budget instead of forcing every worker-side plan to refresh at ~30 Hz.
	var plan_frame := int(plan.get("snapshot_frame", -1))
	var age_frames := int(Engine.get_physics_frames()) - plan_frame
	var plan_team := StringName(plan.get("team", NO_TEAM))
	var budget := get_cpu_tactical_update_budget(peer_id, plan_team)
	var interval := maxf(
		0.0,
		float(budget.get("interval", CPU_TACTICAL_NORMAL_INTERVAL))
	)
	var maximum_age_frames := clampi(
		int(ceil(interval * 60.0)) + 3,
		6,
		14
	)
	if age_frames < 0 or age_frames > maximum_age_frames:
		return {}
	return plan


func _poll_large_team_parallel_brain() -> void:
	if _large_team_parallel_brain == null:
		return
	var result_variant: Variant = _large_team_parallel_brain.call("poll")
	if not result_variant is Dictionary:
		return
	_accept_large_team_parallel_result(result_variant)


func _accept_large_team_parallel_result(result_variant: Variant) -> void:
	if not result_variant is Dictionary:
		return
	var result := result_variant as Dictionary
	if result.is_empty():
		return
	_large_team_parallel_result_frame = maxi(
		_large_team_parallel_result_frame,
		int(result.get("physics_frame", -1))
	)
	var completed_plans := result.get("plans", {}) as Dictionary
	for peer_variant in completed_plans.keys():
		var peer_id := int(peer_variant)
		var completed_plan := completed_plans.get(peer_variant, {}) as Dictionary
		if peer_id > 0 and not completed_plan.is_empty():
			_large_team_parallel_plans[peer_id] = completed_plan


func _submit_large_team_parallel_snapshot_if_needed() -> void:
	if _large_team_parallel_brain == null:
		return
	var physics_frame := int(Engine.get_physics_frames())
	if physics_frame == _large_team_parallel_submit_frame:
		return
	var snapshot := _build_large_team_parallel_snapshot(physics_frame)
	if snapshot.is_empty():
		return
	if bool(_large_team_parallel_brain.call("submit", snapshot)):
		_large_team_parallel_submit_frame = physics_frame
		_commit_large_team_parallel_schedule(snapshot)


func _build_large_team_parallel_snapshot(physics_frame: int) -> Dictionary:
	var world := get_cpu_shared_world_model()
	if world.is_empty():
		return {}
	var blue_active := world.get("blue_snapshots", []) as Array
	var red_active := world.get("red_snapshots", []) as Array
	if blue_active.size() < 5 and red_active.size() < 5:
		return {}
	var agents: Array[Dictionary] = []
	var schedule_meta: Dictionary = {}
	var now_msec := Time.get_ticks_msec()
	for actor_variant in blue_active + red_active:
		var actor := actor_variant as Dictionary
		if not bool(actor.get("cpu_controlled", false)):
			continue
		var peer_id := int(actor.get("peer_id", 0))
		var team := StringName(actor.get("team", NO_TEAM))
		if peer_id <= 0 or team not in [TEAM_BLUE, TEAM_RED]:
			continue
		var budget := get_cpu_tactical_update_budget(peer_id, team)
		var interval := maxf(
			0.0,
			float(budget.get("interval", CPU_TACTICAL_NORMAL_INTERVAL))
		)
		var tier := StringName(budget.get("tier", CPU_TACTICAL_TIER_NORMAL))
		var global_serial := int(budget.get("global_event_serial", 0))
		var peer_serial := int(budget.get("peer_event_serial", 0))
		var next_due := int(_large_team_parallel_next_due_msec.get(peer_id, 0))
		var global_wake := global_serial != int(
			_large_team_parallel_seen_global_event_serial.get(peer_id, global_serial)
		)
		var peer_wake := peer_serial != int(
			_large_team_parallel_seen_peer_event_serial.get(peer_id, peer_serial)
		)
		var existing_plan := _large_team_parallel_plans.get(peer_id, {}) as Dictionary
		var plan_age := (
			physics_frame - int(existing_plan.get("snapshot_frame", -1000))
			if not existing_plan.is_empty()
			else 1000
		)
		var maximum_plan_age := clampi(
			int(ceil(interval * 60.0)) + 2,
			5,
			13
		)
		var due := (
			existing_plan.is_empty()
			or now_msec >= next_due
			or peer_wake
			or plan_age > maximum_plan_age
			or (
				global_wake
				and tier in [CPU_TACTICAL_TIER_CRITICAL, CPU_TACTICAL_TIER_HIGH]
			)
		)
		if not due:
			continue
		var scheduled_actor := actor.duplicate(false)
		scheduled_actor["part4_worker_high_priority"] = (
			peer_wake
			or tier in [CPU_TACTICAL_TIER_CRITICAL, CPU_TACTICAL_TIER_HIGH]
		)
		agents.append(scheduled_actor)
		schedule_meta[peer_id] = {
			"interval": interval,
			"global_event_serial": global_serial,
			"peer_event_serial": peer_serial,
		}
	if agents.is_empty():
		return {}

	var blue_assignments: Dictionary = {}
	var red_assignments: Dictionary = {}
	var possession := get_cpu_possession_team()
	if possession == TEAM_RED and not blue_active.is_empty():
		var first_blue_cpu := _first_cpu_peer_id(blue_active)
		if first_blue_cpu > 0:
			get_cpu_defensive_assignment(TEAM_BLUE, first_blue_cpu)
			blue_assignments = ((_cpu_defensive_assignments.get(TEAM_BLUE, {}) as Dictionary).get("players", {}) as Dictionary).duplicate(true)
	elif possession == TEAM_BLUE and not red_active.is_empty():
		var first_red_cpu := _first_cpu_peer_id(red_active)
		if first_red_cpu > 0:
			get_cpu_defensive_assignment(TEAM_RED, first_red_cpu)
			red_assignments = ((_cpu_defensive_assignments.get(TEAM_RED, {}) as Dictionary).get("players", {}) as Dictionary).duplicate(true)

	return {
		"physics_frame": physics_frame,
		"agents": agents,
		"part4_schedule_meta": schedule_meta,
		"part4_schedule_now_msec": now_msec,
		"blue_players": blue_active,
		"red_players": red_active,
		"possession_team": possession,
		"blue_chaser_peer_id": get_cpu_ball_chaser(TEAM_BLUE),
		"red_chaser_peer_id": get_cpu_ball_chaser(TEAM_RED),
		"blue_defensive_assignments": blue_assignments,
		"red_defensive_assignments": red_assignments,
		"ball_position": world.get("ball_position", ball.global_position),
		"ball_velocity": world.get("ball_velocity", ball.linear_velocity),
		"ball_linear_damp": world.get("ball_linear_damp", ball.linear_damp),
		"last_touch_peer_id": int(world.get("last_touch_peer_id", ball.last_touch_peer_id)),
		"last_touch_team": StringName(world.get("last_touch_team", NO_TEAM)),
		"blue_goal": _cpu_plan_goal_center(blue_goal),
		"red_goal": _cpu_plan_goal_center(red_goal),
		"minimum_x": CPU_PLAN_MINIMUM_X,
		"maximum_x": CPU_PLAN_MAXIMUM_X,
		"minimum_y": CPU_PLAN_MINIMUM_Y,
		"maximum_y": CPU_PLAN_MAXIMUM_Y,
		"incoming_pass_minimum_speed": 260.0,
		"incoming_pass_maximum_seconds": 3.0,
		"incoming_pass_lane_width": 680.0,
		"incoming_pass_receiver_advantage": 90.0,
		"ball_wall_top_y": 806.0,
		"ball_wall_bottom_y": 4194.0,
		"large_team_defensive_zone_blend": 0.58
	}


func _commit_large_team_parallel_schedule(snapshot: Dictionary) -> void:
	var schedule_meta := snapshot.get("part4_schedule_meta", {}) as Dictionary
	var now_msec := int(
		snapshot.get("part4_schedule_now_msec", Time.get_ticks_msec())
	)
	for peer_variant in schedule_meta.keys():
		var peer_id := int(peer_variant)
		var meta := schedule_meta.get(peer_variant, {}) as Dictionary
		if peer_id <= 0:
			continue
		var interval := maxf(
			0.0,
			float(meta.get("interval", CPU_TACTICAL_NORMAL_INTERVAL))
		)
		_large_team_parallel_next_due_msec[peer_id] = (
			now_msec + maxi(1, int(round(interval * 1000.0)))
		)
		_large_team_parallel_seen_global_event_serial[peer_id] = int(
			meta.get("global_event_serial", 0)
		)
		_large_team_parallel_seen_peer_event_serial[peer_id] = int(
			meta.get("peer_event_serial", 0)
		)


func _first_cpu_peer_id(players: Array[Dictionary]) -> int:
	for actor: Dictionary in players:
		if bool(actor.get("cpu_controlled", false)):
			return int(actor.get("peer_id", 0))
	return 0


func _large_team_parallel_natural_role(player: FootballPlayer) -> StringName:
	var football_role := StringName(player.get_meta("pve_ranked_football_role", &""))
	match football_role:
		&"defender", &"holding", &"goalkeeper": return &"defender"
		&"winger": return &"winger"
		&"striker", &"forward_creator": return &"striker"
		&"midfielder", &"creator": return &"midfielder"
	match FootballPlayer.get_ability_role(player.selected_ability):
		FootballPlayer.ABILITY_ROLE_DEFENSE: return &"defender"
		FootballPlayer.ABILITY_ROLE_ATTACK: return &"striker"
	return &"midfielder"


func _initialize_cpu_team_sequence_planner() -> void:
	if _cpu_team_sequence_planner != null:
		return
	var planner_script := load(CPU_TEAM_SEQUENCE_PLANNER_PATH) as Script
	if planner_script == null:
		push_error(
			"Team sequence planner could not be loaded: %s"
			% CPU_TEAM_SEQUENCE_PLANNER_PATH
		)
		return
	_cpu_team_sequence_planner = planner_script.new()


func get_cpu_team_sequence_plan(team: StringName) -> Dictionary:
	# Team sequence state is shared by every CPU on the team. Compute/validate it
	# at most once per physics frame; the other 4-6 brains consume the exact same
	# immutable result instead of repeating roster scans and cache validation.
	var physics_frame := int(Engine.get_physics_frames())
	var frame_entry := _cpu_team_sequence_frame_cache.get(team, {}) as Dictionary
	if int(frame_entry.get("frame", -1)) == physics_frame:
		return frame_entry.get("plan", {}) as Dictionary
	var plan := _compute_cpu_team_sequence_plan(team)
	_cpu_team_sequence_frame_cache[team] = {
		"frame": physics_frame,
		"plan": plan
	}
	return plan


func _compute_cpu_team_sequence_plan(team: StringName) -> Dictionary:
	if (
		not multiplayer.is_server()
		or not cpu_team_sequence_planner_enabled
		or ball == null
		or team not in [TEAM_BLUE, TEAM_RED]
	):
		return {}
	if _cpu_team_sequence_planner == null:
		_initialize_cpu_team_sequence_planner()
	if _cpu_team_sequence_planner == null:
		return {}

	var parallel_async := _large_team_parallel_active()
	if parallel_async:
		_poll_cpu_team_sequence_async_job(team)

	var world := get_cpu_shared_world_model()
	var active_team: Array = (
		world.get("blue_active_players", []) as Array
		if team == TEAM_BLUE
		else world.get("red_active_players", []) as Array
	)
	var active_opponents: Array = (
		world.get("red_active_players", []) as Array
		if team == TEAM_BLUE
		else world.get("blue_active_players", []) as Array
	)
	if active_team.is_empty():
		return {}
	var now_msec := Time.get_ticks_msec()
	var possession := get_cpu_possession_team()
	var carrier: FootballPlayer
	if possession == team:
		carrier = _cpu_plan_likely_carrier(active_team)
	var carrier_peer_id := carrier.owner_peer_id if carrier != null else 0
	var cached := _cpu_team_sequence_plans.get(team, {}) as Dictionary
	if _cpu_team_sequence_plan_matches_live_state(
		cached,
		now_msec,
		carrier_peer_id,
		possession,
		190.0,
		0
	):
		return cached

	var sequence_profile_started_usec: int = (
		Time.get_ticks_usec()
		if _runtime_spike_profile_is_enabled()
		else 0
	)
	var own_goal := blue_goal if team == TEAM_BLUE else red_goal
	var opponent_goal := red_goal if team == TEAM_BLUE else blue_goal
	var own_goal_center := _cpu_plan_goal_center(own_goal)
	var opponent_goal_center := _cpu_plan_goal_center(opponent_goal)
	var opponent_goal_mouth := Vector2(
		opponent_goal_center.y - 772.5,
		opponent_goal_center.y + 772.5
	)
	if opponent_goal != null:
		opponent_goal_mouth = opponent_goal.get_mouth_y_range()
	var own_snapshots: Array = (
		world.get("blue_snapshots", []) as Array
		if team == TEAM_BLUE
		else world.get("red_snapshots", []) as Array
	)
	var opponent_snapshots: Array = (
		world.get("red_snapshots", []) as Array
		if team == TEAM_BLUE
		else world.get("blue_snapshots", []) as Array
	)
	var snapshot := {
		"team": team,
		"team_size": active_team.size(),
		"opponent_size": active_opponents.size(),
		"now_msec": now_msec,
		"possession_team": possession,
		"carrier_peer_id": carrier_peer_id,
		"last_touch_peer_id": ball.last_touch_peer_id,
		"ball_position": ball.global_position,
		"ball_velocity": ball.linear_velocity,
		"own_goal": own_goal_center,
		"opponent_goal": opponent_goal_center,
		"opponent_goal_mouth": opponent_goal_mouth,
		"attack_sign": 1.0 if team == TEAM_BLUE else -1.0,
		"field_bounds": Rect2(
			CPU_PLAN_MINIMUM_X,
			CPU_PLAN_MINIMUM_Y,
			CPU_PLAN_MAXIMUM_X - CPU_PLAN_MINIMUM_X,
			CPU_PLAN_MAXIMUM_Y - CPU_PLAN_MINIMUM_Y
		),
		"own_players": own_snapshots,
		"opponents": opponent_snapshots
	}

	# On the same high-core 5v5/6v6 path as the per-player snapshot brain, the
	# sequence evaluator is pure data and substantial enough to run as its own
	# non-blocking worker task. This removes its worst ~20 ms main-thread spikes.
	if parallel_async:
		_submit_cpu_team_sequence_async_job(
			team,
			snapshot,
			cached,
			now_msec,
			carrier_peer_id,
			possession
		)
		if sequence_profile_started_usec > 0:
			record_runtime_profile_stage(
				&"team_sequence_snapshot_submit",
				Time.get_ticks_usec() - sequence_profile_started_usec
			)
		# A very recently expired plan is preferable to stalling the physics frame.
		# Only reuse it while the actor/possession still match and the ball has not
		# moved far from its anchor; otherwise the normal CPU fallback handles this
		# frame until the worker result arrives.
		if _cpu_team_sequence_plan_matches_live_state(
			cached,
			now_msec,
			carrier_peer_id,
			possession,
			360.0,
			260
		):
			return cached
		return {}

	var plan_variant: Variant = _cpu_team_sequence_planner.call(
		"build_plan",
		snapshot,
		cached
	)
	if sequence_profile_started_usec > 0:
		record_runtime_profile_stage(
			&"team_sequence_planner",
			Time.get_ticks_usec() - sequence_profile_started_usec
		)
	if not plan_variant is Dictionary:
		return {}
	var plan := plan_variant as Dictionary
	if plan.is_empty():
		return {}
	plan["possession_anchor"] = possession
	plan["expires_msec"] = maxi(
		int(plan.get("expires_msec", now_msec)),
		now_msec + int(maxf(0.10, cpu_team_sequence_cache_seconds) * 1000.0)
	)
	_cpu_team_sequence_plans[team] = plan
	return plan


func _cpu_team_sequence_plan_matches_live_state(
	plan: Dictionary,
	now_msec: int,
	carrier_peer_id: int,
	possession: StringName,
	ball_tolerance: float,
	expiry_grace_msec: int
) -> bool:
	return (
		not plan.is_empty()
		and now_msec <= int(plan.get("expires_msec", 0)) + maxi(0, expiry_grace_msec)
		and int(plan.get("actor_peer_id", 0)) == carrier_peer_id
		and StringName(plan.get("possession_anchor", NO_TEAM)) == possession
		and (plan.get("ball_anchor", ball.global_position) as Vector2)
		.distance_to(ball.global_position) <= maxf(1.0, ball_tolerance)
	)


func _submit_cpu_team_sequence_async_job(
	team: StringName,
	snapshot: Dictionary,
	previous_plan: Dictionary,
	now_msec: int,
	carrier_peer_id: int,
	possession: StringName
) -> void:
	if _cpu_team_sequence_async_tasks.has(team):
		return
	var runner = _cpu_team_sequence_planner.get_script().new()
	if runner == null or not runner.has_method("run_async_job"):
		return
	var result_box: Array = [{}]
	var task_id := WorkerThreadPool.add_task(
		runner.run_async_job.bind(snapshot, previous_plan, result_box),
		false,
		"%s team sequence" % str(team)
	)
	if task_id < 0:
		return
	_cpu_team_sequence_async_tasks[team] = {
		"id": task_id,
		"runner": runner,
		"box": result_box,
		"submitted_msec": now_msec,
		"carrier_peer_id": carrier_peer_id,
		"possession": possession,
		"ball_anchor": snapshot.get("ball_position", Vector2.ZERO),
		"reset_generation": _reset_generation
	}


func _poll_cpu_team_sequence_async_job(team: StringName) -> void:
	var task := _cpu_team_sequence_async_tasks.get(team, {}) as Dictionary
	if task.is_empty():
		return
	var task_id := int(task.get("id", -1))
	if task_id < 0 or not WorkerThreadPool.is_task_completed(task_id):
		return
	# Safe because completion was already observed; this never waits on AI work.
	WorkerThreadPool.wait_for_task_completion(task_id)
	_cpu_team_sequence_async_tasks.erase(team)
	if int(task.get("reset_generation", -1)) != _reset_generation:
		return
	if ball == null or not is_instance_valid(ball):
		return
	var submitted_possession := StringName(task.get("possession", NO_TEAM))
	if get_cpu_possession_team() != submitted_possession:
		return
	if (task.get("ball_anchor", ball.global_position) as Vector2).distance_to(
		ball.global_position
	) > 520.0:
		return
	var box := task.get("box", []) as Array
	if box.is_empty() or not box[0] is Dictionary:
		return
	var plan := box[0] as Dictionary
	if plan.is_empty():
		return
	var submitted_msec := int(task.get("submitted_msec", Time.get_ticks_msec()))
	plan["possession_anchor"] = submitted_possession
	plan["expires_msec"] = maxi(
		int(plan.get("expires_msec", submitted_msec)),
		Time.get_ticks_msec()
		+ int(maxf(0.10, cpu_team_sequence_cache_seconds) * 1000.0)
	)
	_cpu_team_sequence_plans[team] = plan


func get_cpu_team_sequence_assignment(
	team: StringName,
	peer_id: int
) -> Dictionary:
	if peer_id <= 0:
		return {}
	var plan := get_cpu_team_sequence_plan(team)
	return (plan.get("assignments", {}) as Dictionary).get(
		peer_id,
		{}
	) as Dictionary


func get_cpu_ability_team_plan(team: StringName) -> Dictionary:
	if (
		not multiplayer.is_server()
		or ball == null
		or team not in [TEAM_BLUE, TEAM_RED]
	):
		return {}
	var now_msec := Time.get_ticks_msec()
	var cached := _cpu_ability_team_plans.get(team, {}) as Dictionary
	if (
		not cached.is_empty()
		and now_msec <= int(cached.get("expires_msec", 0))
		and (cached.get("ball_anchor", ball.global_position) as Vector2)
		.distance_to(ball.global_position) <= 260.0
	):
		return cached.duplicate(true)
	var plan := _build_cpu_ability_team_plan(team)
	_cpu_ability_team_plans[team] = plan
	return plan.duplicate(true)


func get_cpu_ability_team_assignment(
	team: StringName,
	peer_id: int
) -> Dictionary:
	if peer_id <= 0:
		return {}
	var plan := get_cpu_ability_team_plan(team)
	return (plan.get("assignments", {}) as Dictionary).get(
		peer_id,
		{}
	) as Dictionary


func _build_cpu_ability_team_plan(team: StringName) -> Dictionary:
	var roster := blue_players if team == TEAM_BLUE else red_players
	var opponents := red_players if team == TEAM_BLUE else blue_players
	var own_goal := blue_goal if team == TEAM_BLUE else red_goal
	var opponent_goal := red_goal if team == TEAM_BLUE else blue_goal
	var own_goal_center := _cpu_plan_goal_center(own_goal)
	var opponent_goal_center := _cpu_plan_goal_center(opponent_goal)
	var active_team: Array[FootballPlayer] = []
	var active_cpus: Array[FootballPlayer] = []
	var active_opponents: Array[FootballPlayer] = []
	for player in roster:
		if is_instance_valid(player) and player.controls_enabled:
			active_team.append(player)
			if player.cpu_controlled:
				active_cpus.append(player)
	for opponent in opponents:
		if is_instance_valid(opponent) and opponent.controls_enabled:
			active_opponents.append(opponent)
	var server_now := (
		float(Time.get_ticks_msec()) / 1000.0
		* maxf(1.0, Engine.time_scale)
	)
	var threat: Dictionary = AbilityThreatModelScript.analyze_team(
		active_opponents,
		ball.global_position,
		own_goal_center,
		maxf(1.0, absf(opponent_goal_center.x - own_goal_center.x)),
		server_now,
		ball.linear_velocity
	) as Dictionary
	var possession := get_cpu_possession_team()
	var assignments: Dictionary = {}
	var carrier := _cpu_plan_likely_carrier(active_team)
	var opponent_carrier := _cpu_plan_likely_carrier(active_opponents)
	var attack_sign := 1.0 if team == TEAM_BLUE else -1.0
	var center_y := (
		own_goal_center.y + opponent_goal_center.y
	) * 0.5
	var phase: StringName = &"loose"
	if possession == team:
		phase = &"attack"
		var supporters: Array[FootballPlayer] = []
		for cpu in active_cpus:
			if cpu != carrier:
				supporters.append(cpu)

		# Reserve a real defensive anchor before assigning runner/connector roles.
		# This is what makes Iron Anchor / defensive footballers stay behind while
		# a Dead Zone Pass midfielder becomes the connector instead of the safety.
		var safety_cpu: FootballPlayer = null
		var safety_score: float = -INF
		if active_team.size() >= 3:
			for candidate in supporters:
				var candidate_score := _cpu_plan_defensive_support_priority(candidate)
				if candidate_score > safety_score:
					safety_score = candidate_score
					safety_cpu = candidate
		if safety_score < 3.5 and active_team.size() < 4:
			# In 3v3 only dedicate a safety when someone actually fits the role.
			# In 4v4 always keep one player behind to preserve team structure even
			# when the lineup happens to contain only attacking/playmaking abilities.
			safety_cpu = null

		var attacking_supporters: Array[FootballPlayer] = []
		for candidate in supporters:
			if candidate != safety_cpu:
				attacking_supporters.append(candidate)
		attacking_supporters.sort_custom(
			func(first: FootballPlayer, second: FootballPlayer) -> bool:
				return (
					_cpu_plan_support_priority(first, server_now)
					> _cpu_plan_support_priority(second, server_now)
				)
		)
		var ordered_supporters: Array[FootballPlayer] = attacking_supporters.duplicate()
		if safety_cpu != null:
			ordered_supporters.append(safety_cpu)
		var field_progress := clampf(
			absf(ball.global_position.x - own_goal_center.x)
			/ maxf(1.0, absf(opponent_goal_center.x - own_goal_center.x)),
			0.0,
			1.0
		)
		var far_side_sign := (
			-1.0 if ball.global_position.y >= center_y else 1.0
		)
		for index in range(ordered_supporters.size()):
			var cpu := ordered_supporters[index]
			var role: StringName = &"safety"
			var target := ball.global_position + Vector2(
				-attack_sign * 1050.0,
				(center_y - ball.global_position.y) * 0.42
			)
			if cpu != safety_cpu:
				var attacking_index := attacking_supporters.find(cpu)
				if attacking_index == 0:
					role = &"runner" if field_progress >= 0.38 else &"connector"
					if role == &"runner":
						target = ball.global_position + Vector2(
							attack_sign * 1050.0,
							far_side_sign * 920.0
						)
					else:
						target = ball.global_position + Vector2(
							attack_sign * 260.0,
							far_side_sign * 780.0
						)
				else:
					role = &"connector"
					target = ball.global_position + Vector2(
						attack_sign * 180.0,
						-far_side_sign * 760.0
					)
			target = _cpu_plan_clamp_target(target)
			assignments[cpu.owner_peer_id] = {
				"role": role,
				"intent": (
					&"forward_run" if role == &"runner"
					else &"cover" if role == &"safety"
					else &"wide_support"
				),
				"target_position": target,
				"carrier_peer_id": (
					carrier.owner_peer_id if carrier != null else 0
				),
				"ability_aware": true
			}
	elif possession in [TEAM_BLUE, TEAM_RED] and possession != team:
		phase = &"defense"
		var primary_threat_peer := int(threat.get("primary_peer_id", 0))
		for cpu in active_cpus:
			var base_assignment := get_cpu_defensive_assignment(
				team,
				cpu.owner_peer_id
			)
			var role := StringName(base_assignment.get("role", &"cover"))
			var target: Vector2 = base_assignment.get(
				"target_position",
				cpu.global_position
			)
			var actor := _get_player(primary_threat_peer)
			if actor == null:
				actor = opponent_carrier
			if actor != null:
				var pressure_actor := (
					opponent_carrier
					if opponent_carrier != null
					else actor
				)
				var power_threat := float(threat.get(
					"power_shot_threat",
					0.0
				))
				var combination_threat := maxf(
					float(threat.get("combination_threat", 0.0)),
					float(threat.get("first_time_finish_threat", 0.0))
				)
				if power_threat >= 0.48:
					# The presser still closes the current carrier. The cover player
					# separately protects the goal-side lane of the ready Power
					# Strike receiver. This prevents both defenders from chasing
					# the ball and gifting the counter shot shown in the clip.
					if role == &"press":
						var pressure_goalward := pressure_actor.global_position.direction_to(
							own_goal_center
						)
						target = pressure_actor.global_position + pressure_goalward * 480.0
						if actor != pressure_actor:
							var passing_lane_guard := ball.global_position.lerp(
								actor.global_position,
								0.54
							)
							target = target.lerp(passing_lane_guard, 0.24)
					else:
						var shooter_goalward := actor.global_position.direction_to(
							own_goal_center
						)
						target = actor.global_position + shooter_goalward * (
							760.0 if role == &"cover" else 1120.0
						)
						if role == &"final":
							target = own_goal_center.lerp(target, 0.34)
				elif combination_threat >= 0.50 and actor != pressure_actor:
					if role == &"press":
						var carrier_goalward := pressure_actor.global_position.direction_to(
							own_goal_center
						)
						target = pressure_actor.global_position + carrier_goalward * 430.0
					else:
						target = actor.global_position + actor.global_position.direction_to(
							own_goal_center
						) * 620.0
				elif float(threat.get("bypass_threat", 0.0)) >= 0.52:
					var bypass_actor := pressure_actor
					var toward_goal := bypass_actor.global_position.direction_to(
						own_goal_center
					)
					if role == &"press":
						target = bypass_actor.global_position + toward_goal * 610.0
					else:
						target = target.lerp(own_goal_center, 0.24)
			assignments[cpu.owner_peer_id] = {
				"role": role,
				"intent": &"cover" if role != &"press" else &"chase_ball",
				"target_position": _cpu_plan_clamp_target(target),
				"target_peer_id": (
					actor.owner_peer_id if actor != null else 0
				),
				"ability_aware": true
			}
	else:
		phase = &"loose"
	return {
		"team": team,
		"phase": phase,
		"carrier_peer_id": carrier.owner_peer_id if carrier != null else 0,
		"opponent_carrier_peer_id": (
			opponent_carrier.owner_peer_id if opponent_carrier != null else 0
		),
		"threat": threat,
		"assignments": assignments,
		"ball_anchor": ball.global_position,
		"expires_msec": Time.get_ticks_msec() + 180
	}


func _cpu_plan_likely_carrier(
	players: Array[FootballPlayer]
) -> FootballPlayer:
	var best: FootballPlayer
	var best_score := INF
	for player in players:
		if not is_instance_valid(player) or not player.controls_enabled:
			continue
		if player.cpu_has_kickable_ball():
			return player
		var score := player.global_position.distance_to(ball.global_position)
		if player.owner_peer_id == ball.last_touch_peer_id:
			score -= 360.0
		if score < best_score:
			best_score = score
			best = player
	return best


func _cpu_plan_support_priority(
	player: FootballPlayer,
	server_now: float = -1.0
) -> float:
	var score := 0.0
	match FootballPlayer.get_ability_role(player.selected_ability):
		FootballPlayer.ABILITY_ROLE_ATTACK:
			score += 3.0
		FootballPlayer.ABILITY_ROLE_PLAYMAKER:
			score += 2.0
		FootballPlayer.ABILITY_ROLE_FLEXIBLE:
			score += 1.0
		FootballPlayer.ABILITY_ROLE_DEFENSE:
			score += 0.2

	var football_role := StringName(player.get_meta("pve_ranked_football_role", &""))
	match football_role:
		&"striker":
			score += 2.4
		&"winger":
			score += 2.1
		&"forward_creator":
			score += 1.7
		&"creator":
			score += 1.2
		&"midfielder":
			score += 0.9
		&"holding":
			score -= 0.8
		&"defender":
			score -= 1.5
		&"goalkeeper":
			score -= 2.0

	var ability_ready := true
	if server_now >= 0.0:
		ability_ready = (
			player.selected_ability != FootballPlayer.ABILITY_NONE
			and player.server_ability_cooldown_ends_at <= server_now + 0.02
		)
	if ability_ready:
		match player.selected_ability:
			FootballPlayer.ABILITY_DIRECT_FINISH:
				score += 1.8
			FootballPlayer.ABILITY_POWER_STRIKE:
				score += 1.7
			FootballPlayer.ABILITY_QUICK_TRIGGER:
				score += 1.6
			FootballPlayer.ABILITY_OVERDRIVE, FootballPlayer.ABILITY_BREAKAWAY:
				score += 1.5
			FootballPlayer.ABILITY_BURST_DRIBBLE, FootballPlayer.ABILITY_BLIND_SPOT, FootballPlayer.ABILITY_ELASTIC_STEP, FootballPlayer.ABILITY_NUTMEG:
				score += 1.2
			FootballPlayer.ABILITY_TIME_SKIP_PASS:
				score += 1.05
			FootballPlayer.ABILITY_RETURN_TAG, FootballPlayer.ABILITY_META_VISION, FootballPlayer.ABILITY_SIDE_SWIPE:
				score += 0.8
			FootballPlayer.ABILITY_BOOGIE_WOOGIE, FootballPlayer.ABILITY_HEEL_TURN:
				score += 0.65
			FootballPlayer.ABILITY_SNAPBACK:
				score += 0.75
			FootballPlayer.ABILITY_COPYCAT:
				score += 0.35
			FootballPlayer.ABILITY_DECOY_RUN:
				# Decoy Run is more valuable off-ball than as the main pass target.
				score += 0.15
	return score


func _cpu_plan_defensive_support_priority(player: FootballPlayer) -> float:
	if not is_instance_valid(player):
		return -INF
	var score := 0.0
	match FootballPlayer.get_ability_role(player.selected_ability):
		FootballPlayer.ABILITY_ROLE_DEFENSE:
			score += 4.5
		FootballPlayer.ABILITY_ROLE_FLEXIBLE:
			score += 0.5
		FootballPlayer.ABILITY_ROLE_PLAYMAKER:
			score -= 0.5
		FootballPlayer.ABILITY_ROLE_ATTACK:
			score -= 1.5
	match player.selected_ability:
		FootballPlayer.ABILITY_IRON_ANCHOR:
			score += 2.5
		FootballPlayer.ABILITY_GOALKEEPER_REACH:
			score += 2.8
		FootballPlayer.ABILITY_REFLEX_BLOCK:
			score += 2.0
		FootballPlayer.ABILITY_ECHO:
			score += 1.8
		FootballPlayer.ABILITY_ENFORCER:
			score += 1.1
	var football_role := StringName(player.get_meta("pve_ranked_football_role", &""))
	match football_role:
		&"goalkeeper":
			score += 4.0
		&"defender":
			score += 3.2
		&"holding":
			score += 2.6
		&"midfielder":
			score += 0.6
		&"creator":
			score -= 0.8
		&"forward_creator":
			score -= 1.2
		&"winger":
			score -= 1.5
		&"striker":
			score -= 2.0
	return score


func _cpu_plan_goal_center(goal: FootballGoal) -> Vector2:
	if goal == null:
		return ball.global_position if ball != null else Vector2.ZERO
	return Vector2(
		goal.get_goal_plane_x(),
		(goal.get_mouth_y_range().x + goal.get_mouth_y_range().y) * 0.5
	)


func _cpu_plan_clamp_target(target: Vector2) -> Vector2:
	return Vector2(
		clampf(target.x, CPU_PLAN_MINIMUM_X + 120.0, CPU_PLAN_MAXIMUM_X - 120.0),
		clampf(target.y, CPU_PLAN_MINIMUM_Y + 120.0, CPU_PLAN_MAXIMUM_Y - 120.0)
	)


func set_cpu_combination_plan(
	team: StringName,
	play_type: StringName,
	initiator_peer_id: int,
	receiver_peer_id: int,
	next_peer_id: int,
	initiator_run_target: Vector2,
	next_run_target: Vector2,
	lifetime_seconds: float = 3.0,
	metadata: Dictionary = {}
) -> void:
	if (
		not multiplayer.is_server()
		or team not in [TEAM_BLUE, TEAM_RED]
		or initiator_peer_id <= 0
		or receiver_peer_id <= 0
	):
		return
	var plan := {
		"play_type": play_type,
		"phase": &"setup",
		"initiator_peer_id": initiator_peer_id,
		"receiver_peer_id": receiver_peer_id,
		"next_peer_id": next_peer_id,
		"initiator_run_target": initiator_run_target,
		"next_run_target": next_run_target,
		"expires_msec": (
			Time.get_ticks_msec()
			+ int(maxf(0.5, lifetime_seconds) * 1000.0)
		)
	}
	plan.merge(metadata, true)
	_cpu_combination_plans[team] = plan


func get_cpu_combination_plan(team: StringName) -> Dictionary:
	if not multiplayer.is_server():
		return {}
	var plan := _cpu_combination_plans.get(team, {}) as Dictionary
	if plan.is_empty():
		return {}
	if Time.get_ticks_msec() > int(plan.get("expires_msec", 0)):
		if StringName(plan.get("play_type", &"")) in [
			CPU_COMBO_DEAD_ZONE_TRAP_VOLLEY,
			CPU_COMBO_POWER_STRIKE_TRAP_VOLLEY,
			CPU_COMBO_OVERDRIVE_DEAD_ZONE,
			CPU_COMBO_GOALKEEPER_REBOUND
		]:
			_cpu_pass_intentions.erase(
				int(plan.get("receiver_peer_id", 0))
			)
		_cpu_combination_plans.erase(team)
		return {}
	return plan


func clear_cpu_combination_plan(team: StringName) -> void:
	if multiplayer.is_server():
		_cpu_combination_plans.erase(team)


func _resolve_save_candidate(
	generation: int,
	peer_id: int,
	player_name: String,
	player_team: StringName,
	target_goal: FootballGoal
) -> void:
	var confirmation_duration := maxf(
		0.05,
		save_confirmation_seconds
	)
	var deadline_msec := (
		Time.get_ticks_msec()
		+ int(confirmation_duration * 1000.0)
	)

	while Time.get_ticks_msec() <= deadline_msec:
		await get_tree().physics_frame
		if (
			generation != _save_check_generation
			or not game_has_started
			or round_resetting
			or ball == null
			or target_goal == null
		):
			return

		var goal_direction := signf(
			target_goal.get_goal_plane_x()
			- ball.global_position.x
		)
		if (
			is_zero_approx(goal_direction)
			or ball.linear_velocity.x * goal_direction <= 0.0
			or not _trajectory_enters_goal(
				ball.global_position,
				ball.linear_velocity,
				target_goal
			)
		):
			_ensure_player_stat(peer_id, player_name, player_team)
			_increment_player_stat(peer_id, "saves")
			_increment_cpu_benchmark_metric(player_team, "saves")
			var saving_player := _get_player(peer_id)
			if saving_player != null and not saving_player.cpu_controlled:
				_record_human_demonstration_event(saving_player, &"defense", {
					"save": true,
					"target": _normalize_demo_position(ball.global_position, player_team),
					"incoming_velocity": _normalized_demo_velocity(ball.linear_velocity, player_team)
				})
			return


func _update_active_shot() -> void:
	if _active_shot.is_empty() or ball == null:
		return

	var target_goal := (
		_active_shot.get("target_goal") as FootballGoal
	)
	if target_goal == null:
		_active_shot.clear()
		return

	var travel_direction := float(
		_active_shot.get("travel_direction", 0.0)
	)
	if (
		ball.linear_velocity.length()
		< maxf(0.0, minimum_save_threat_speed)
		or is_zero_approx(travel_direction)
		or ball.linear_velocity.x * travel_direction <= 0.0
		or (
			ball.global_position.x
			- target_goal.get_goal_plane_x()
		) * travel_direction >= 0.0
	):
		var shooter := _get_player(int(_active_shot.get("shooter_peer_id", 0)))
		if shooter != null and not shooter.cpu_controlled:
			_record_human_demonstration_event(shooter, &"shot_result", {
				"on_target": false,
				"blocked": false
			})
		_active_shot.clear()


func _is_save_threat(
	start_position: Vector2,
	velocity: Vector2,
	target_goal: FootballGoal
) -> bool:
	if (
		target_goal == null
		or velocity.length()
		< maxf(0.0, minimum_save_threat_speed)
		or is_zero_approx(velocity.x)
	):
		return false

	var distance_to_goal := (
		target_goal.get_goal_plane_x() - start_position.x
	)
	if distance_to_goal * velocity.x <= 0.0:
		return false

	var time_to_goal := distance_to_goal / velocity.x
	var projected_y := (
		start_position.y + velocity.y * time_to_goal
	)
	var mouth_range := target_goal.get_mouth_y_range()
	var margin := maxf(0.0, save_goal_mouth_margin)
	var expanded_top := mouth_range.x - margin
	var expanded_bottom := mouth_range.y + margin
	if (
		projected_y >= expanded_top
		and projected_y <= expanded_bottom
	):
		return true

	return (
		absf(distance_to_goal)
		<= maxf(0.0, save_detection_distance_from_goal)
		and start_position.y >= expanded_top
		and start_position.y <= expanded_bottom
	)


func _target_goal_for_team(
	attacking_team: StringName
) -> FootballGoal:
	return red_goal if attacking_team == TEAM_BLUE else blue_goal


func _get_goal_center(goal: FootballGoal) -> Vector2:
	if goal == null:
		return Vector2.ZERO
	var mouth := goal.get_mouth_y_range()
	return Vector2(
		goal.get_goal_plane_x(),
		(mouth.x + mouth.y) * 0.5
	)


func _trajectory_enters_goal(
	start_position: Vector2,
	velocity: Vector2,
	target_goal: FootballGoal
) -> bool:
	if (
		target_goal == null
		or velocity.length() < maxf(0.0, minimum_shot_speed)
		or is_zero_approx(velocity.x)
	):
		return false

	var time_to_goal := (
		target_goal.get_goal_plane_x() - start_position.x
	) / velocity.x
	if time_to_goal <= 0.0:
		return false

	var projected_y := (
		start_position.y + velocity.y * time_to_goal
	)
	var mouth_range := target_goal.get_mouth_y_range()
	var padding := maxf(0.0, goal_mouth_vertical_padding)
	return (
		projected_y >= mouth_range.x + padding
		and projected_y <= mouth_range.y - padding
	)


func _initialize_match_statistics() -> void:
	_player_statistics.clear()
	_pending_pass.clear()
	_cpu_pass_intentions.clear()
	_cpu_ball_commitments.clear()
	_cpu_tactical_intentions.clear()
	_cpu_combination_plans.clear()
	_reset_cpu_possession_state()
	if players_parent == null:
		_broadcast_leaderboard()
		return

	for child in players_parent.get_children():
		var player := child as FootballPlayer
		if (
			player == null
			or player.training_dummy
			or (
				player.team != TEAM_RED
				and player.team != TEAM_BLUE
			)
		):
			continue
		_ensure_player_stat(
			player.owner_peer_id,
			player.display_name,
			player.team
		)
	_broadcast_leaderboard()


func _ensure_player_stat(
	peer_id: int,
	player_name: String,
	player_team: StringName
) -> void:
	if peer_id <= 0:
		return

	if not _player_statistics.has(peer_id):
		_player_statistics[peer_id] = {
			"peer_id": peer_id,
			"name": player_name,
			"team": player_team,
			"goals": 0,
			"saves": 0,
			"passes": 0
		}
		return

	var entry := _player_statistics[peer_id] as Dictionary
	entry["name"] = player_name
	entry["team"] = player_team


func _increment_player_stat(
	peer_id: int,
	stat_name: String
) -> void:
	if not _player_statistics.has(peer_id):
		return

	var entry := _player_statistics[peer_id] as Dictionary
	entry[stat_name] = int(entry.get(stat_name, 0)) + 1
	var perk_player := _get_player(peer_id)
	if perk_player != null:
		perk_player.trigger_draft_perk(StringName(stat_name))
	_receive_player_stat_earned.rpc(
		peer_id,
		StringName(stat_name)
	)
	_broadcast_leaderboard()


@rpc("authority", "call_local", "reliable")
func _receive_player_stat_earned(
	peer_id: int,
	stat_name: StringName
) -> void:
	player_stat_earned.emit(peer_id, stat_name)


func _build_leaderboard_snapshot() -> Array:
	var entries: Array = []
	for value in _player_statistics.values():
		if value is Dictionary:
			entries.append((value as Dictionary).duplicate(true))
	entries.sort_custom(_compare_stat_entries)
	return entries


func _compare_stat_entries(
	first: Dictionary,
	second: Dictionary
) -> bool:
	var first_team := StringName(first.get("team", NO_TEAM))
	var second_team := StringName(second.get("team", NO_TEAM))
	if first_team != second_team:
		return first_team == TEAM_BLUE

	var first_goals := int(first.get("goals", 0))
	var second_goals := int(second.get("goals", 0))
	if first_goals != second_goals:
		return first_goals > second_goals
	return str(first.get("name", "")) < str(
		second.get("name", "")
	)


func _broadcast_leaderboard() -> void:
	if not multiplayer.is_server():
		return
	_receive_leaderboard.rpc(_build_leaderboard_snapshot())


@rpc("authority", "call_local", "reliable")
func _receive_leaderboard(entries: Array) -> void:
	leaderboard_snapshot = entries.duplicate(true)
	leaderboard_changed.emit(leaderboard_snapshot)


func dismiss_match_results() -> void:
	match_results_available = false
	if ladder_mode and multiplayer.is_server() and _ladder_prepare_pending:
		_ladder_prepare_pending = false
		ladder_last_result = &""
		_prepare_ladder_encounter()
	if (
		singleplayer_ranked_mode
		and multiplayer.is_server()
		and _singleplayer_ranked_prepare_pending
	):
		_singleplayer_ranked_prepare_pending = false
		singleplayer_ranked_last_result = &""
		_prepare_singleplayer_ranked_match()
	results_dismissed.emit()


# ================================================================
# SERVER-AUTHORITATIVE GOAL REPLAY
# ================================================================

func _goal_replay_max_frame_gap_msec() -> int:
	var minimum_from_capture_rate := (
		3.0 / maxf(1.0, goal_replay_capture_rate)
	)
	return maxi(
		1,
		int(
			round(
				maxf(
					goal_replay_max_frame_gap_seconds,
					minimum_from_capture_rate
				) * 1000.0
			)
		)
	)


func _reset_goal_replay_capture_segment() -> void:
	_goal_replay_frames.clear()
	_goal_replay_events.clear()
	_goal_replay_capture_accumulator = 0.0


func _capture_goal_replay(delta: float) -> void:
	if goal_replay_active or ball == null:
		return
	_goal_replay_capture_accumulator += maxf(0.0, delta)
	var capture_interval := 1.0 / maxf(1.0, goal_replay_capture_rate)
	if _goal_replay_capture_accumulator < capture_interval:
		return
	_goal_replay_capture_accumulator = fmod(
		_goal_replay_capture_accumulator,
		capture_interval
	)
	_capture_goal_replay_frame()


func _capture_goal_replay_frame() -> void:
	if not multiplayer.is_server() or ball == null:
		return
	var now_msec := Time.get_ticks_msec()
	if not _goal_replay_frames.is_empty():
		var previous_time_msec := int(
			_goal_replay_frames.back().get("time_msec", now_msec)
		)
		var capture_gap_msec := now_msec - previous_time_msec
		if (
			capture_gap_msec <= 0
			or capture_gap_msec > _goal_replay_max_frame_gap_msec()
		):
			# A reset, replay, pause or long hitch created a discontinuity.
			# Never interpolate across it: begin a fresh replay segment.
			_reset_goal_replay_capture_segment()
	var player_states: Dictionary = {}
	for player in _get_all_match_players():
		player_states[player.owner_peer_id] = {
			"position": player.global_position,
			"rotation": player.global_rotation,
			"linear_velocity": player.linear_velocity,
			"angular_velocity": player.angular_velocity,
			"ability_active": player.server_ability_active,
			"ability_id": player.server_active_ability_id
		}
	_goal_replay_frames.append({
		"time_msec": now_msec,
		"last_touch_peer_id": ball.last_touch_peer_id,
		"ball_position": ball.global_position,
		"ball_rotation": ball.global_rotation,
		"ball_linear_velocity": ball.linear_velocity,
		"ball_angular_velocity": ball.angular_velocity,
		"ball_power_strike": ball.power_strike_visual_active,
		"ball_curve_shot": ball.curve_shot_visual_active,
		"ball_time_skip": ball.time_skip_visual_active,
		"players": player_states
	})
	_trim_goal_replay_frames(now_msec)


func _trim_goal_replay_frames(now_msec: int) -> void:
	var cutoff_msec := now_msec - int(
		maxf(1.0, goal_replay_history_seconds) * 1000.0
	)
	while (
		_goal_replay_frames.size() > 1
		and int(
			_goal_replay_frames[0].get("time_msec", now_msec)
		) < cutoff_msec
	):
		_goal_replay_frames.pop_front()
	while (
		not _goal_replay_events.is_empty()
		and int(
			_goal_replay_events[0].get("time_msec", now_msec)
		) < cutoff_msec
	):
		_goal_replay_events.pop_front()


func _build_contiguous_goal_replay_frames(
	source_frames: Array[Dictionary]
) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if source_frames.is_empty():
		return result
	var start_index := source_frames.size() - 1
	var maximum_gap_msec := _goal_replay_max_frame_gap_msec()
	while start_index > 0:
		var current_time := int(
			source_frames[start_index].get("time_msec", 0)
		)
		var previous_time := int(
			source_frames[start_index - 1].get("time_msec", current_time)
		)
		var frame_gap := current_time - previous_time
		if frame_gap <= 0 or frame_gap > maximum_gap_msec:
			break
		start_index -= 1
	for index in range(start_index, source_frames.size()):
		result.append(source_frames[index].duplicate(true))
	return result


func _filter_goal_replay_events_for_frames(
	source_events: Array[Dictionary],
	frames: Array[Dictionary]
) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if frames.is_empty():
		return result
	var first_time_msec := int(frames[0].get("time_msec", 0))
	var final_time_msec := int(
		frames[frames.size() - 1].get("time_msec", first_time_msec)
	)
	for event_data in source_events:
		var event_time_msec := int(
			event_data.get("time_msec", first_time_msec - 1)
		)
		if (
			event_time_msec >= first_time_msec
			and event_time_msec <= final_time_msec
		):
			result.append(event_data.duplicate(true))
	return result


func request_skip_goal_replay() -> void:
	if multiplayer.is_server():
		_server_skip_goal_replay(multiplayer.get_unique_id())
	else:
		_request_skip_goal_replay.rpc_id(SERVER_PEER_ID)


@rpc("any_peer", "call_remote", "reliable")
func _request_skip_goal_replay() -> void:
	if not multiplayer.is_server():
		return
	_server_skip_goal_replay(multiplayer.get_remote_sender_id())


func _server_skip_goal_replay(peer_id: int) -> void:
	if not multiplayer.is_server() or not goal_replay_active:
		return
	if not _get_goal_replay_voter_ids().has(peer_id):
		return
	_goal_replay_skip_votes[peer_id] = true
	_refresh_goal_replay_vote_state(true)


func _get_goal_replay_voter_ids() -> Array[int]:
	var voter_ids: Array[int] = []
	if not multiplayer.is_server():
		return voter_ids
	var local_peer_id := multiplayer.get_unique_id()
	if local_peer_id > 0:
		voter_ids.append(local_peer_id)
	for peer_variant in multiplayer.get_peers():
		var peer_id := int(peer_variant)
		if peer_id > 0 and not voter_ids.has(peer_id):
			voter_ids.append(peer_id)
	return voter_ids


func _refresh_goal_replay_vote_state(force_broadcast: bool = false) -> void:
	if not multiplayer.is_server() or not goal_replay_active:
		return
	var voter_ids := _get_goal_replay_voter_ids()
	for voted_peer_variant in _goal_replay_skip_votes.keys():
		var voted_peer_id := int(voted_peer_variant)
		if not voter_ids.has(voted_peer_id):
			_goal_replay_skip_votes.erase(voted_peer_variant)
	var vote_count := _goal_replay_skip_votes.size()
	var voter_count := voter_ids.size()
	_goal_replay_skip_requested = (
		voter_count > 0 and vote_count >= voter_count
	)
	if (
		force_broadcast
		or vote_count != _goal_replay_last_vote_count
		or voter_count != _goal_replay_last_voter_count
	):
		_goal_replay_last_vote_count = vote_count
		_goal_replay_last_voter_count = voter_count
		_receive_goal_replay_state.rpc(
			true,
			vote_count,
			voter_count,
			goal_replay_slow_motion
		)


@rpc("authority", "call_local", "reliable")
func _receive_goal_replay_start_snapshot(frame: Dictionary) -> void:
	if ball != null:
		_apply_goal_replay_body_sample(ball, frame, frame, 0.0, true)
		ball.reset_physics_interpolation()
	var player_states: Dictionary = frame.get("players", {})
	for peer_variant in player_states.keys():
		var peer_id := int(peer_variant)
		var player := _get_player(peer_id)
		if player == null:
			continue
		var player_state: Dictionary = player_states.get(peer_variant, {})
		_apply_goal_replay_body_sample(
			player,
			player_state,
			player_state,
			0.0,
			false
		)
		player.reset_physics_interpolation()


func _play_goal_replay(
	frames: Array[Dictionary],
	events: Array[Dictionary],
	scorer_peer_id: int,
	scored_into_goal_team: StringName
) -> void:
	if not multiplayer.is_server() or frames.is_empty():
		return
	_goal_replay_generation += 1
	var generation := _goal_replay_generation
	goal_replay_active = true
	goal_replay_slow_motion = false
	_goal_replay_skip_requested = false
	_goal_replay_skip_votes.clear()
	_goal_replay_last_vote_count = -1
	_goal_replay_last_voter_count = -1
	_goal_replay_ball_visual_state.clear()
	_goal_replay_player_visual_states.clear()
	goal_replay_presentation = _build_goal_replay_presentation(
		scorer_peer_id,
		scored_into_goal_team
	)
	_receive_goal_replay_presentation.rpc(
		true,
		goal_replay_presentation
	)
	_set_all_players_enabled(false)
	if ball != null:
		ball.set_play_enabled(false)
		ball.prepare_for_goal_replay()
	_refresh_goal_replay_vote_state(true)

	var first_time_msec := int(frames[0].get("time_msec", 0))
	var final_time_msec := int(
		frames[frames.size() - 1].get("time_msec", first_time_msec)
	)
	var replay_duration := maxf(
		0.0,
		float(final_time_msec - first_time_msec) / 1000.0
	)
	var slow_motion_window := _find_goal_replay_slow_motion_window(
		frames,
		scorer_peer_id
	)
	var playback_time := 0.0
	# Snap every peer to the first recorded frame before playback begins.
	# This prevents normal network/physics interpolation from showing a
	# fake slow rewind from the live post-goal positions.
	_receive_goal_replay_start_snapshot.rpc(frames[0])
	_apply_goal_replay_sample(frames, playback_time)
	_play_goal_replay_events(
		events,
		first_time_msec,
		-0.001,
		playback_time
	)

	while (
		generation == _goal_replay_generation
		and game_has_started
		and playback_time < replay_duration
		and not _goal_replay_skip_requested
	):
		await get_tree().physics_frame
		if generation != _goal_replay_generation:
			return
		_refresh_goal_replay_vote_state()
		var should_slow := (
			playback_time >= slow_motion_window.x
			and playback_time <= slow_motion_window.y
		)
		if should_slow != goal_replay_slow_motion:
			goal_replay_slow_motion = should_slow
			_refresh_goal_replay_vote_state(true)
		var playback_scale := (
			clampf(goal_replay_slow_motion_scale, 0.05, 1.0)
			if goal_replay_slow_motion
			else 1.0
		)
		var previous_playback_time := playback_time
		playback_time = minf(
			replay_duration,
			playback_time
			+ get_physics_process_delta_time() * playback_scale
		)
		_apply_goal_replay_sample(frames, playback_time)
		_play_goal_replay_events(
			events,
			first_time_msec,
			previous_playback_time,
			playback_time
		)

	if generation != _goal_replay_generation:
		return
	var replay_was_skipped := _goal_replay_skip_requested
	goal_replay_active = false
	goal_replay_slow_motion = false
	_goal_replay_skip_requested = false
	_goal_replay_skip_votes.clear()
	_receive_goal_replay_state.rpc(false, 0, 0, false)
	goal_replay_presentation.clear()
	_receive_goal_replay_presentation.rpc(false, {})
	_clear_goal_replay_visuals()
	if (
		playback_time >= replay_duration
		and not replay_was_skipped
		and ball != null
	):
		ball.play_goal_explosion(
			scored_into_goal_team,
			1.35,
			_get_goal_explosion_cosmetic_id(scorer_peer_id),
			_get_goal_explosion_color_index(scorer_peer_id)
		)


func _find_goal_replay_slow_motion_start(
	frames: Array[Dictionary],
	scorer_peer_id: int
) -> float:
	return _find_goal_replay_slow_motion_window(
		frames,
		scorer_peer_id
	).x


func _find_goal_replay_slow_motion_window(
	frames: Array[Dictionary],
	scorer_peer_id: int
) -> Vector2:
	if frames.size() < 2:
		return Vector2.ZERO
	var first_time_msec := int(frames[0].get("time_msec", 0))
	var final_time_msec := int(
		frames[frames.size() - 1].get("time_msec", first_time_msec)
	)
	var target_touch_peer_id := int(
		frames[frames.size() - 1].get("last_touch_peer_id", 0)
	)
	if target_touch_peer_id <= 0:
		target_touch_peer_id = scorer_peer_id
	var touch_time := float(final_time_msec - first_time_msec) / 1000.0
	for index in range(frames.size() - 1, 0, -1):
		var current_touch := int(
			frames[index].get("last_touch_peer_id", 0)
		)
		var previous_touch := int(
			frames[index - 1].get("last_touch_peer_id", 0)
		)
		if (
			current_touch == target_touch_peer_id
			and current_touch != previous_touch
		):
			touch_time = float(
				int(frames[index].get("time_msec", first_time_msec))
				- first_time_msec
			) / 1000.0
			break
	return Vector2(
		maxf(
			0.0,
			touch_time
			- maxf(0.0, goal_replay_slow_motion_lead_seconds)
		),
		minf(
			float(final_time_msec - first_time_msec) / 1000.0,
			touch_time
			+ maxf(0.0, goal_replay_slow_motion_follow_seconds)
		)
	)


func _play_goal_replay_events(
	events: Array[Dictionary],
	first_time_msec: int,
	from_playback_time: float,
	to_playback_time: float
) -> void:
	if not multiplayer.is_server() or events.is_empty():
		return
	for event_data in events:
		var event_time := float(
			int(event_data.get("time_msec", first_time_msec))
			- first_time_msec
		) / 1000.0
		if (
			event_time <= from_playback_time
			or event_time > to_playback_time + 0.0001
		):
			continue
		_receive_goal_replay_event.rpc(event_data)


@rpc("authority", "call_local", "unreliable")
func _receive_goal_replay_event(event_data: Dictionary) -> void:
	var event_type := StringName(event_data.get("type", &""))
	match event_type:
		&"kick":
			var peer_id := int(event_data.get("peer_id", 0))
			var player := _get_player(peer_id)
			if player != null:
				player.play_goal_replay_shot_sound(
					float(event_data.get("force", 0.0)),
					bool(event_data.get("power_strike", false))
				)
			if ball != null:
				ball.play_goal_replay_kick_feedback(
					event_data.get("position", ball.global_position),
					StringName(event_data.get("team", NO_TEAM)),
					event_data.get("direction", Vector2.RIGHT),
					float(event_data.get("intensity", 0.5))
				)
		&"wall_collision":
			if ball != null:
				ball.play_goal_replay_collision_sound()


func _sync_goal_replay_ball_visuals(frame: Dictionary) -> void:
	var state: Array = [
		bool(frame.get("ball_power_strike", false)),
		bool(frame.get("ball_curve_shot", false)),
		bool(frame.get("ball_time_skip", false))
	]
	if state == _goal_replay_ball_visual_state:
		return
	_goal_replay_ball_visual_state = state.duplicate()
	_receive_goal_replay_ball_visual_state.rpc(
		bool(state[0]),
		bool(state[1]),
		bool(state[2])
	)


@rpc("authority", "call_local", "reliable")
func _receive_goal_replay_ball_visual_state(
	power_strike_active: bool,
	curve_active: bool,
	time_skip_active: bool
) -> void:
	if ball != null:
		ball.set_goal_replay_visual_state(
			power_strike_active,
			curve_active,
			time_skip_active
		)


func _sync_goal_replay_player_visual(
	peer_id: int,
	player_state: Dictionary
) -> void:
	var active := bool(player_state.get("ability_active", false))
	var ability_id := int(
		player_state.get("ability_id", FootballPlayer.ABILITY_NONE)
	)
	var state := Vector2i(1 if active else 0, ability_id)
	if _goal_replay_player_visual_states.get(peer_id) == state:
		return
	_goal_replay_player_visual_states[peer_id] = state
	_receive_goal_replay_player_visual_state.rpc(
		peer_id,
		active,
		ability_id
	)


@rpc("authority", "call_local", "reliable")
func _receive_goal_replay_player_visual_state(
	peer_id: int,
	active: bool,
	ability_id: int
) -> void:
	var player := _get_player(peer_id)
	if player != null:
		player.set_goal_replay_visual_state(active, ability_id)


func _clear_goal_replay_visuals() -> void:
	if multiplayer.is_server():
		_receive_goal_replay_ball_visual_state.rpc(false, false, false)
		for peer_variant in _goal_replay_player_visual_states.keys():
			_receive_goal_replay_player_visual_state.rpc(
				int(peer_variant),
				false,
				FootballPlayer.ABILITY_NONE
			)
	_goal_replay_ball_visual_state.clear()
	_goal_replay_player_visual_states.clear()


func _apply_goal_replay_sample(
	frames: Array[Dictionary],
	playback_time: float
) -> void:
	if frames.is_empty() or ball == null:
		return
	var first_time_msec := int(frames[0].get("time_msec", 0))
	var target_time_msec := first_time_msec + int(
		maxf(0.0, playback_time) * 1000.0
	)
	var left_index := 0
	while (
		left_index + 1 < frames.size()
		and int(
			frames[left_index + 1].get("time_msec", target_time_msec)
		) <= target_time_msec
	):
		left_index += 1
	var right_index := mini(left_index + 1, frames.size() - 1)
	var left_frame: Dictionary = frames[left_index]
	var right_frame: Dictionary = frames[right_index]
	var left_time := int(left_frame.get("time_msec", target_time_msec))
	var right_time := int(right_frame.get("time_msec", left_time))
	var weight := 0.0
	if right_time > left_time:
		weight = clampf(
			float(target_time_msec - left_time)
			/ float(right_time - left_time),
			0.0,
			1.0
		)
	_apply_goal_replay_body_sample(ball, left_frame, right_frame, weight, true)
	_sync_goal_replay_ball_visuals(left_frame)
	var left_players: Dictionary = left_frame.get("players", {})
	var right_players: Dictionary = right_frame.get("players", {})
	for peer_variant in left_players.keys():
		var peer_id := int(peer_variant)
		var player := _get_player(peer_id)
		if player == null:
			continue
		var left_state: Dictionary = left_players.get(peer_variant, {})
		var right_state: Dictionary = right_players.get(
			peer_variant,
			left_state
		)
		_apply_goal_replay_body_sample(
			player,
			left_state,
			right_state,
			weight,
			false
		)
		_sync_goal_replay_player_visual(peer_id, left_state)


func _apply_goal_replay_body_sample(
	body: RigidBody2D,
	left_state: Dictionary,
	right_state: Dictionary,
	weight: float,
	is_ball: bool
) -> void:
	var position_key := "ball_position" if is_ball else "position"
	var rotation_key := "ball_rotation" if is_ball else "rotation"
	var velocity_key := (
		"ball_linear_velocity" if is_ball else "linear_velocity"
	)
	var angular_key := (
		"ball_angular_velocity" if is_ball else "angular_velocity"
	)
	var left_position: Vector2 = left_state.get(
		position_key,
		body.global_position
	)
	var right_position: Vector2 = right_state.get(
		position_key,
		left_position
	)
	var left_rotation := float(left_state.get(rotation_key, body.global_rotation))
	var right_rotation := float(right_state.get(rotation_key, left_rotation))
	var left_velocity: Vector2 = left_state.get(velocity_key, Vector2.ZERO)
	var right_velocity: Vector2 = right_state.get(velocity_key, left_velocity)
	body.global_position = left_position.lerp(right_position, weight)
	body.global_rotation = lerp_angle(left_rotation, right_rotation, weight)
	body.linear_velocity = left_velocity.lerp(right_velocity, weight)
	body.angular_velocity = lerpf(
		float(left_state.get(angular_key, 0.0)),
		float(right_state.get(angular_key, 0.0)),
		weight
	)
	_publish_goal_replay_network_state(body, is_ball)


func _publish_goal_replay_network_state(
	body: RigidBody2D,
	is_ball: bool
) -> void:
	# Replay bodies are deliberately frozen. Frozen RigidBody2D instances do not
	# run their normal _integrate_forces() publisher, so without this explicit
	# update clients keep receiving the last live-match snapshot while the host
	# moves through the replay. That stale target is what could pin remote players
	# near the Players parent origin/bottom-left corner.
	if is_ball and body is FootballBall:
		var replay_ball := body as FootballBall
		replay_ball.network_position = replay_ball.position
		replay_ball.network_linear_velocity = replay_ball.linear_velocity
		replay_ball.network_rotation = replay_ball.rotation
		replay_ball.network_angular_velocity = replay_ball.angular_velocity
		return

	if body is FootballPlayer:
		var replay_player := body as FootballPlayer
		var parent_node := replay_player.get_parent() as Node2D
		replay_player.network_position = (
			parent_node.to_local(replay_player.global_position)
			if parent_node != null
			else replay_player.global_position
		)
		replay_player.network_linear_velocity = replay_player.linear_velocity


func _clear_goal_replay_state() -> void:
	_goal_replay_generation += 1
	goal_replay_active = false
	goal_replay_slow_motion = false
	_goal_replay_frames.clear()
	_goal_replay_events.clear()
	_goal_replay_capture_accumulator = 0.0
	_goal_replay_skip_votes.clear()
	_goal_replay_skip_requested = false
	_goal_replay_last_vote_count = -1
	_goal_replay_last_voter_count = -1
	_goal_replay_ball_visual_state.clear()
	_goal_replay_player_visual_states.clear()
	goal_replay_presentation.clear()
	goal_replay_state_changed.emit(false, 0, 0, false)
	goal_replay_presentation_changed.emit(false, {})


func _cancel_goal_replay() -> void:
	var was_active := goal_replay_active
	if was_active:
		_clear_goal_replay_visuals()
	_clear_goal_replay_state()
	if was_active and multiplayer.is_server():
		_receive_goal_replay_state.rpc(false, 0, 0, false)
		_receive_goal_replay_presentation.rpc(false, {})


@rpc("authority", "call_local", "reliable")
func _receive_goal_replay_state(
	active: bool,
	votes: int,
	total_voters: int,
	slow_motion: bool
) -> void:
	# Goal themes belong to the goal/replay presentation. Stop them as soon as
	# that presentation ends (including a voted skip) so they cannot bleed into
	# the following kickoff. This runs locally on every peer through the RPC.
	if not active and goal_audio != null:
		goal_audio.stop()
	goal_replay_active = active
	goal_replay_slow_motion = slow_motion
	goal_replay_state_changed.emit(
		active,
		maxi(0, votes),
		maxi(0, total_voters),
		slow_motion
	)


@rpc("authority", "call_local", "reliable")
func _receive_goal_replay_presentation(
	active: bool,
	presentation: Dictionary
) -> void:
	goal_replay_presentation = (
		presentation.duplicate(true) if active else {}
	)
	goal_replay_presentation_changed.emit(
		active,
		goal_replay_presentation
	)


func connect_goal(goal: FootballGoal) -> void:
	if goal == null:
		push_error("A goal was not assigned in MatchManager.")
		return

	if not goal.goal_scored.is_connected(_on_goal_scored):
		goal.goal_scored.connect(_on_goal_scored)


func _update_swept_goal_detection() -> void:
	if ball == null:
		_previous_authoritative_ball_position = Vector2.ZERO
		return
	var current_position := ball.global_position
	if (
		not game_has_started
		or round_resetting
	):
		_previous_authoritative_ball_position = current_position
		return
	if _previous_authoritative_ball_position == Vector2.ZERO:
		_previous_authoritative_ball_position = current_position
		return
	var previous_position := _previous_authoritative_ball_position
	_previous_authoritative_ball_position = current_position
	var travel_x := current_position.x - previous_position.x
	if absf(travel_x) < 0.001:
		return

	var goals: Array[FootballGoal] = [blue_goal, red_goal]
	for goal: FootballGoal in goals:
		if goal == null:
			continue
		var goal_x: float = goal.get_goal_plane_x()
		var crossing_ratio: float = (
			goal_x - previous_position.x
		) / travel_x
		if crossing_ratio < 0.0 or crossing_ratio > 1.0:
			continue
		var crossing_y := lerpf(
			previous_position.y,
			current_position.y,
			crossing_ratio
		)
		var mouth: Vector2 = goal.get_mouth_y_range()
		if crossing_y < mouth.x or crossing_y > mouth.y:
			continue
		var scoring_team := (
			TEAM_BLUE
			if goal.defending_team == "red"
			else TEAM_RED
		)
		_on_goal_scored(str(scoring_team))
		return


func _clear_goalkeeper_rebound_plans() -> void:
	for team_key in _cpu_combination_plans.keys():
		var plan := _cpu_combination_plans.get(team_key, {}) as Dictionary
		if StringName(plan.get("play_type", &"")) == CPU_COMBO_GOALKEEPER_REBOUND:
			_cpu_pass_intentions.erase(
				int(plan.get("receiver_peer_id", 0))
			)
			_cpu_combination_plans.erase(team_key)


func _setup_goal_reaction_audio() -> void:
	_goal_reaction_contact_audio = AudioStreamPlayer.new()
	_goal_reaction_contact_audio.name = "GoalReactionContactAudio"
	_goal_reaction_contact_audio.stream = GOAL_REACTION_CONTACT_SOUND
	add_child(_goal_reaction_contact_audio)

	_goal_reaction_sting_audio = AudioStreamPlayer.new()
	_goal_reaction_sting_audio.name = "GoalReactionStingAudio"
	_goal_reaction_sting_audio.stream = GOAL_REACTION_CONTACT_SOUND
	add_child(_goal_reaction_sting_audio)

	_goal_reaction_crowd_audio = AudioStreamPlayer.new()
	_goal_reaction_crowd_audio.name = "GoalReactionCrowdAudio"
	add_child(_goal_reaction_crowd_audio)


@rpc("authority", "call_local", "reliable")
func _receive_goal_reaction() -> void:
	_goal_reaction_generation += 1
	var generation: int = _goal_reaction_generation

	# Immediate real-ball contact: short and dry enough to read through the
	# explosion/theme audio without turning into another synthetic impact.
	if _goal_reaction_contact_audio != null:
		_goal_reaction_contact_audio.stop()
		_goal_reaction_contact_audio.stream = GOAL_REACTION_CONTACT_SOUND
		_goal_reaction_contact_audio.volume_db = -5.5
		_goal_reaction_contact_audio.pitch_scale = 0.92
		_goal_reaction_contact_audio.play()

	# A lower, quieter copy of the same recorded football hit supplies the
	# arcade goal pop. No generated tone, bell, synth, or cinematic boom.
	_play_goal_reaction_sting_later(generation)

	# Only play this when a genuine crowd recording is assigned. The existing
	# GoalFX stadium-roar asset is procedurally generated, so it is deliberately
	# not used as a fallback for the normal goal reaction.
	if (
		_goal_reaction_crowd_audio != null
		and goal_reaction_crowd_sound != null
	):
		_goal_reaction_crowd_audio.stop()
		_goal_reaction_crowd_audio.stream = goal_reaction_crowd_sound
		_goal_reaction_crowd_audio.volume_db = goal_reaction_crowd_volume_db
		_goal_reaction_crowd_audio.pitch_scale = 1.0
		_goal_reaction_crowd_audio.play()
		_stop_goal_crowd_later(generation)


func _stop_goal_crowd_later(generation: int) -> void:
	await get_tree().create_timer(3.2).timeout
	if generation != _goal_reaction_generation:
		return
	if _goal_reaction_crowd_audio != null and _goal_reaction_crowd_audio.playing:
		var tween := create_tween()
		tween.tween_property(
			_goal_reaction_crowd_audio,
			"volume_db",
			-32.0,
			0.55
		)
		tween.tween_callback(_goal_reaction_crowd_audio.stop)


func _play_goal_reaction_sting_later(generation: int) -> void:
	await get_tree().create_timer(0.045).timeout
	if generation != _goal_reaction_generation:
		return
	if _goal_reaction_sting_audio == null:
		return
	_goal_reaction_sting_audio.stop()
	_goal_reaction_sting_audio.stream = GOAL_REACTION_CONTACT_SOUND
	_goal_reaction_sting_audio.volume_db = -11.5
	_goal_reaction_sting_audio.pitch_scale = 0.72
	_goal_reaction_sting_audio.play()


func _on_goal_scored(team: String) -> void:
	if (
		not multiplayer.is_server()
		or not game_has_started
		or round_resetting
	):
		return

	var scoring_team := StringName(team)
	if scoring_team != TEAM_RED and scoring_team != TEAM_BLUE:
		return
	if not cpu_training_mode:
		_receive_goal_reaction.rpc()
	var scored_into_goal_team := (
		TEAM_BLUE
		if scoring_team == TEAM_RED
		else TEAM_RED
	)
	_clear_goalkeeper_rebound_plans()
	if penalty_shootout_active:
		if not penalty_attempt_active:
			return
		var penalty_scorer_id: int = 0
		if ball != null:
			penalty_scorer_id = ball.get_last_touch_peer_id_for_team(
				scoring_team
			)
			ball.play_goal_explosion(
				scored_into_goal_team,
				1.25,
				_get_goal_explosion_cosmetic_id(penalty_scorer_id),
				_get_goal_explosion_color_index(penalty_scorer_id)
			)
			ball.slow_ball()
		var penalty_goal_theme_id: String = _get_goal_theme_cosmetic_id(
			penalty_scorer_id
		)
		if penalty_goal_theme_id != "goal_theme.classic":
			_receive_goal_sound.rpc(&"", penalty_goal_theme_id)
		else:
			_receive_goal_sound.rpc()
		_complete_penalty_attempt(scoring_team == penalty_turn)
		return

	if freeplay_active:
		round_resetting = true
		_reset_generation += 1
		var generation := _reset_generation
		if ball != null:
			var practice_scorer_id: int = ball.get_last_touch_peer_id_for_team(
				scoring_team
			)
			ball.play_goal_explosion(
				scored_into_goal_team,
				0.65,
				_get_goal_explosion_cosmetic_id(practice_scorer_id),
				_get_goal_explosion_color_index(practice_scorer_id)
			)
			ball.slow_ball()
		_receive_freeplay_goal_impact_sound.rpc()
		_show_announcement("Practice goal!", 1.0)
		await get_tree().create_timer(0.65).timeout
		if (
			not freeplay_active
			or generation != _reset_generation
		):
			return
		reset_freeplay_ball()
		round_resetting = false
		return

	# Lock goal counting immediately, but allow the current motion to
	# continue briefly while the synchronized announcement is shown.
	_capture_goal_replay_frame()
	var replay_frames: Array[Dictionary] = (
		_build_contiguous_goal_replay_frames(_goal_replay_frames)
	)
	var replay_events: Array[Dictionary] = (
		_filter_goal_replay_events_for_frames(
			_goal_replay_events,
			replay_frames
		)
	)
	round_resetting = true
	_active_shot.clear()
	_save_check_generation += 1
	_prepare_all_abilities_for_kickoff()
	_increment_cpu_benchmark_metric(scoring_team, "goals")
	_increment_cpu_benchmark_metric(scored_into_goal_team, "goals_against")
	for defender: FootballPlayer in (
		blue_players if scored_into_goal_team == TEAM_BLUE else red_players
	):
		if is_instance_valid(defender):
			defender.trigger_draft_perk(&"conceded")

	var scorer_name := ""
	var scorer_peer_id := 0
	if ball != null:
		scorer_name = ball.get_last_touch_name_for_team(
			scoring_team
		).strip_edges()
		scorer_peer_id = ball.get_last_touch_peer_id_for_team(
			scoring_team
		)
		if not cpu_training_mode:
			ball.play_goal_explosion(
				scored_into_goal_team,
				maxf(1.8, goal_replay_focus_seconds),
				_get_goal_explosion_cosmetic_id(scorer_peer_id),
				_get_goal_explosion_color_index(scorer_peer_id),
				true
			)
			ball.slow_ball()

	if scorer_peer_id > 0:
		var credited_scorer: FootballPlayer = _get_player(scorer_peer_id)
		var boss_goal_sound_id: StringName = _get_boss_goal_sound_id(credited_scorer)
		var scorer_goal_theme_id: String = _get_goal_theme_cosmetic_id(
			scorer_peer_id
		)
		if not cpu_training_mode:
			if boss_goal_sound_id != &"":
				_receive_goal_sound.rpc(boss_goal_sound_id)
			elif scorer_goal_theme_id != "goal_theme.classic":
				_receive_goal_sound.rpc(&"", scorer_goal_theme_id)
		_increment_player_stat(scorer_peer_id, "goals")
		var scorer := _get_player(scorer_peer_id)
		if scorer != null and champions_league_mode and scorer.draft_perk_id == 42:
			for taxed_opponent: FootballPlayer in _get_opponents_for_team(scorer.team):
				if is_instance_valid(taxed_opponent):
					taxed_opponent._add_draft_perk_cooldown_seconds(
						2.5,
						taxed_opponent._server_time_seconds(),
						false
					)
		if scorer != null and not scorer.cpu_controlled:
			_record_human_demonstration_event(scorer, &"goal", {
				"scoring_team": scoring_team,
				"ability_id": scorer.server_last_used_ability_id
			})
			_deliver_human_learning_goal(scorer_peer_id, scoring_team)
		if not cpu_training_mode:
			_receive_goal_focus.rpc(scorer_peer_id)
	if not cpu_training_mode:
		goal_replay_presentation = _build_goal_replay_presentation(
			scorer_peer_id,
			scored_into_goal_team
		)
		_receive_goal_replay_presentation.rpc(
			true,
			goal_replay_presentation
		)
	var recent_pass := _human_demo_recent_completed_passes.get(scoring_team, {}) as Dictionary
	if (
		not recent_pass.is_empty()
		and int(recent_pass.get("receiver_peer_id", 0)) == scorer_peer_id
		and int(recent_pass.get("passer_peer_id", 0)) != scorer_peer_id
		and _human_demo_time() - float(recent_pass.get("time", 0.0)) <= 10.0
	):
		_increment_cpu_benchmark_metric(scoring_team, "assists")
		var assister := _get_player(int(recent_pass.get("passer_peer_id", 0)))
		if assister != null and not assister.cpu_controlled:
			_record_human_demonstration_event(assister, &"assist", {
				"scorer_peer_id": scorer_peer_id
			})
	if ball != null and ball.last_touch_peer_id > 0:
		var final_toucher := _get_player(ball.last_touch_peer_id)
		if (
			final_toucher != null
			and final_toucher.team == scored_into_goal_team
		):
			_increment_cpu_benchmark_metric(
				scored_into_goal_team,
				"own_goals"
			)
			var forced_deflection: bool = (
				ball.last_touch_kind
				in [&"goalkeeper_block", &"reflex_deflect"]
			)
			if forced_deflection:
				_increment_cpu_benchmark_metric(
					scored_into_goal_team,
					"forced_deflection_own_goals"
				)
			else:
				_increment_cpu_benchmark_metric(
					scored_into_goal_team,
					"avoidable_own_goals"
				)
			if cpu_training_mode:
				print(
					"OWN GOAL DIAGNOSTIC | team=%s | peer=%d | kind=%s | incoming=%s | outgoing=%s | safety_redirected=%s"
					% [
						str(scored_into_goal_team),
						ball.last_touch_peer_id,
						str(ball.last_touch_kind),
						str(ball.last_touch_incoming_velocity),
						str(ball.last_touch_outgoing_velocity),
						str(ball.last_touch_safety_redirected)
					]
				)
			if not final_toucher.cpu_controlled:
				_record_human_demonstration_event(final_toucher, &"own_goal", {
					"scoring_team": scoring_team
				})
	var conceding_roster := blue_players if scored_into_goal_team == TEAM_BLUE else red_players
	for conceding_player in conceding_roster:
		if is_instance_valid(conceding_player) and not conceding_player.cpu_controlled:
			_record_human_demonstration_event(conceding_player, &"shot_conceded", {
				"scoring_team": scoring_team,
				"own_goal": ball != null and ball.last_touch_peer_id == conceding_player.owner_peer_id
			})

	if scoring_team == TEAM_RED:
		red_score += 1
		if tournament_mode:
			tournament_leg_red_goals += 1
	else:
		blue_score += 1
		if tournament_mode:
			tournament_leg_blue_goals += 1

	_broadcast_score()
	_maybe_schedule_cpu_goal_quick_chat(scoring_team, scorer_peer_id)
	if cpu_training_mode:
		if (
			is_overtime
			or red_score >= goals_to_win
			or blue_score >= goals_to_win
		):
			call_deferred("end_match", scoring_team)
		else:
			call_deferred("_start_reset_countdown", true)
		return
	# The replay already reproduces the relevant kick, wall-contact, and goal
	# explosion audio. Do not start the goal whistle beneath the scorer-focus
	# and replay sequence; it otherwise plays over the replay camera.

	var display_team := (
		"Red" if scoring_team == TEAM_RED else "Blue"
	)
	var announcement := "%s team scored!" % display_team
	if not scorer_name.is_empty():
		announcement = "%s has scored!" % scorer_name
	_show_announcement(announcement, announcement_seconds)

	var should_end_after_replay := (
		is_overtime
		and not tournament_mode
	)
	if (
		not tournament_mode
		and (
			red_score >= goals_to_win
			or blue_score >= goals_to_win
		)
	):
		should_end_after_replay = true

	await get_tree().create_timer(
		maxf(0.0, goal_replay_focus_seconds)
	).timeout

	if not game_has_started:
		return
	await _play_goal_replay(
		replay_frames,
		replay_events,
		scorer_peer_id,
		scored_into_goal_team
	)

	if not game_has_started:
		return
	if should_end_after_replay:
		end_match(scoring_team)
		return

	_start_reset_countdown(true)


func _get_goal_explosion_cosmetic_id(scorer_peer_id: int) -> String:
	var scorer: FootballPlayer = _get_player(scorer_peer_id)
	if scorer == null:
		return "goal_explosion.classic"
	return scorer.get_cosmetic_item_id(
		FootballCosmeticInventory.SLOT_GOAL_EXPLOSION
	)


func _get_goal_explosion_color_index(scorer_peer_id: int) -> int:
	var scorer: FootballPlayer = _get_player(scorer_peer_id)
	if scorer == null:
		return FootballCosmeticInventory.PLAYER_SKIN_ORIGINAL_COLOR
	return FootballCosmeticInventory.sanitize_goal_explosion_color_index(
		int(scorer.cosmetic_loadout.get("goal_explosion_color_index", -1))
	)


func _build_goal_replay_presentation(
	scorer_peer_id: int,
	scored_into_goal_team: StringName
) -> Dictionary:
	var scorer: FootballPlayer = _get_player(scorer_peer_id)
	var scoring_team: StringName = (
		TEAM_RED if scored_into_goal_team == TEAM_BLUE else TEAM_BLUE
	)
	var scorer_name: String = (
		scorer.display_name.strip_edges()
		if scorer != null
		else "%s Team" % ("Red" if scoring_team == TEAM_RED else "Blue")
	)
	if scorer_name.is_empty():
		scorer_name = "Player"
	var loadout: Dictionary = (
		scorer.cosmetic_loadout
		if scorer != null
		else FootballCosmeticInventory.get_default_network_loadout()
	)
	var sanitized: Dictionary = (
		FootballCosmeticInventory.sanitize_catalog_network_loadout(loadout)
	)
	return {
		"scorer_peer_id": scorer_peer_id,
		"scorer_name": scorer_name.left(32),
		"subtitle": str(sanitized.get("player_subtitle", "")),
		"banner_id": str(
			scorer.get_cosmetic_item_id(
				FootballCosmeticInventory.SLOT_PLAYER_BANNER
			)
			if scorer != null
			else sanitized.get("player_banner", "player_banner.classic")
		),
		"banner_color_index": int(sanitized.get(
			"player_banner_color_%s" % str(scoring_team),
			sanitized.get("player_banner_color_index", -1)
		)),
		"team": scoring_team,
	}


func _get_goal_theme_cosmetic_id(scorer_peer_id: int) -> String:
	var scorer: FootballPlayer = _get_player(scorer_peer_id)
	if scorer == null:
		return "goal_theme.classic"
	var goal_theme_id: String = scorer.get_cosmetic_item_id(
		FootballCosmeticInventory.SLOT_GOAL_THEME
	)
	var catalog_item: Dictionary = FootballCosmeticInventory.CATALOG.get(
		goal_theme_id, {}
	) as Dictionary
	if (
		catalog_item.is_empty()
		or StringName(catalog_item.get("slot", &""))
		!= FootballCosmeticInventory.SLOT_GOAL_THEME
	):
		return "goal_theme.classic"
	return goal_theme_id


func _get_goal_theme_stream(goal_theme_id: String) -> AudioStream:
	if goal_theme_id.is_empty() or goal_theme_id == "goal_theme.classic":
		return null
	if _goal_theme_stream_cache.has(goal_theme_id):
		return _goal_theme_stream_cache[goal_theme_id] as AudioStream
	var catalog_item: Dictionary = FootballCosmeticInventory.CATALOG.get(
		goal_theme_id, {}
	) as Dictionary
	if StringName(catalog_item.get("slot", &"")) != FootballCosmeticInventory.SLOT_GOAL_THEME:
		return null
	var audio_path: String = str(catalog_item.get("audio_path", ""))
	if audio_path.is_empty() or not ResourceLoader.exists(audio_path, "AudioStream"):
		return null
	var stream: AudioStream = ResourceLoader.load(audio_path, "AudioStream") as AudioStream
	if stream != null:
		_goal_theme_stream_cache[goal_theme_id] = stream
	return stream


func _is_dictator_mbappe_goal_scorer(scorer: FootballPlayer) -> bool:
	return (
		scorer != null
		and scorer.cpu_controlled
		and scorer.display_name.strip_edges() == LADDER_FINAL_BOSS_NAME
	)


func _get_boss_goal_sound_id(scorer: FootballPlayer) -> StringName:
	if _is_dictator_mbappe_goal_scorer(scorer):
		return &"dictator_mbappe"
	if scorer != null and scorer.cpu_controlled and scorer.is_satoru_gojo():
		return &"satoru_gojo"
	return &""


@rpc("authority", "call_local", "reliable")
func _receive_goal_sound(
	boss_goal_sound_id: StringName = &"",
	goal_theme_id: String = ""
) -> void:
	var sound: AudioStream = goal_scored_sound
	if boss_goal_sound_id == &"":
		var goal_theme_stream: AudioStream = _get_goal_theme_stream(goal_theme_id)
		if goal_theme_stream != null:
			sound = goal_theme_stream
	match boss_goal_sound_id:
		&"dictator_mbappe":
			sound = dictator_mbappe_goal_sound
		&"satoru_gojo":
			sound = satoru_gojo_goal_sound
	if sound == null:
		return

	goal_audio.stop()
	goal_audio.stream = sound
	goal_audio.volume_db = goal_sound_volume_db
	goal_audio.pitch_scale = (
		1.0
		if boss_goal_sound_id != &"" or not goal_theme_id.is_empty()
		else goal_sound_pitch_scale
	)
	goal_audio.play()


@rpc("authority", "call_local", "reliable")
func _receive_freeplay_goal_impact_sound() -> void:
	var screen_visual_fx: Node = get_parent().get_node_or_null(
		"ScreenVisualFX"
	)
	if (
		screen_visual_fx != null
		and screen_visual_fx.has_method("play_goal_impact_sound")
	):
		screen_visual_fx.call("play_goal_impact_sound")


@rpc("authority", "call_local", "reliable")
func _receive_goal_focus(scorer_peer_id: int) -> void:
	goal_focus_requested.emit(scorer_peer_id)


func _show_announcement(message: String, duration: float) -> void:
	if not multiplayer.is_server():
		return

	_announcement_generation += 1
	var generation := _announcement_generation
	_receive_announcement.rpc(message)
	_clear_announcement_later(generation, duration)


func _clear_announcement_later(
	generation: int,
	duration: float
) -> void:
	await get_tree().create_timer(duration).timeout

	if (
		multiplayer.is_server()
		and generation == _announcement_generation
	):
		_receive_announcement.rpc("")


@rpc("authority", "call_local", "reliable")
func _receive_announcement(message: String) -> void:
	_current_announcement = message
	announcement_changed.emit(message)


# ================================================================
# SCORE SYNCHRONIZATION
# ================================================================

func _broadcast_score() -> void:
	if multiplayer.is_server():
		_receive_score.rpc(
			red_score,
			blue_score,
			tournament_leg_red_goals,
			tournament_leg_blue_goals,
			tournament_leg,
			tournament_mode,
			tournament_sudden_death
		)


@rpc("authority", "call_local", "reliable")
func _receive_score(
	new_red_score: int,
	new_blue_score: int,
	new_leg_red_score: int,
	new_leg_blue_score: int,
	new_tournament_leg: int,
	new_tournament_mode: bool,
	new_tournament_sudden_death: bool
) -> void:
	red_score = new_red_score
	blue_score = new_blue_score
	tournament_leg_red_goals = new_leg_red_score
	tournament_leg_blue_goals = new_leg_blue_score
	tournament_leg = new_tournament_leg
	tournament_mode = new_tournament_mode
	tournament_sudden_death = new_tournament_sudden_death
	tournament_score_changed.emit(
		tournament_leg_red_goals,
		tournament_leg_blue_goals,
		red_score,
		blue_score,
		tournament_leg,
		tournament_mode,
		tournament_sudden_death
	)
	score_changed.emit(red_score, blue_score)


# ================================================================
# PRE-MATCH TEAM INTRODUCTION
# ================================================================

func _start_draft_matchup_introduction() -> void:
	if (
		not multiplayer.is_server()
		or _draft_matchup_introduction_pending
		or _draft_matchup_introduction_complete
	):
		return
	if cpu_training_mode:
		_draft_matchup_introduction_complete = true
		_start_draft_phase(DRAFT_STAGE_LEG_ONE)
		return

	_draft_matchup_introduction_pending = true
	_team_introduction_skip_requested = false
	var generation := _draft_generation
	_receive_team_introduction.rpc(
		&"versus",
		_build_team_introduction_payload()
	)
	await _wait_for_team_introduction(generation, false)
	if (
		generation != _draft_generation
		or not champions_league_mode
		or game_has_started
	):
		_draft_matchup_introduction_pending = false
		return

	_receive_team_introduction.rpc(NO_TEAM, [])
	await get_tree().create_timer(
		maxf(0.0, team_introduction_gap_seconds)
	).timeout
	if (
		generation != _draft_generation
		or not champions_league_mode
		or game_has_started
	):
		_draft_matchup_introduction_pending = false
		return

	_draft_matchup_introduction_pending = false
	_draft_matchup_introduction_complete = true
	_start_draft_phase(DRAFT_STAGE_LEG_ONE)

func _start_team_introduction() -> void:
	if not multiplayer.is_server():
		return

	_reset_generation += 1
	_team_introduction_skip_requested = false
	var generation := _reset_generation
	_run_team_introduction(generation)


func _run_team_introduction(generation: int) -> void:
	_receive_team_introduction.rpc(
		&"versus",
		_build_team_introduction_payload()
	)
	await _wait_for_team_introduction(generation, true)
	if generation != _reset_generation or not game_has_started:
		return

	_receive_team_introduction.rpc(NO_TEAM, [])
	await get_tree().create_timer(
		maxf(0.0, team_introduction_gap_seconds)
	).timeout
	if generation != _reset_generation or not game_has_started:
		return

	_start_reset_countdown(true)


func _wait_for_team_introduction(
	generation: int,
	require_started_match: bool
) -> void:
	var elapsed := 0.0
	var duration := maxf(0.4, team_introduction_seconds * 2.0)
	while elapsed < duration:
		var step := minf(0.05, duration - elapsed)
		await get_tree().create_timer(step).timeout
		elapsed += step
		if require_started_match:
			if generation != _reset_generation or not game_has_started:
				return
		elif generation != _draft_generation or not champions_league_mode:
			return
		# Keep the first beat intact so the click that started the match cannot
		# accidentally dismiss the presentation on the same input event.
		if _team_introduction_skip_requested and elapsed >= 1.0:
			return


func _build_team_introduction_payload() -> Array:
	return [
		_get_team_introduction_names(blue_players),
		_get_team_introduction_names(red_players),
		_build_team_introduction_context()
	]


func _build_team_introduction_context() -> Dictionary:
	var team_size := maxi(blue_players.size(), red_players.size())
	var mode_title := "MATCHUP"
	var context := "%dV%d" % [team_size, team_size]
	var accent := Color(0.82, 0.69, 1.0)
	if singleplayer_ranked_mode:
		var division := clampi(
			pve_ranked_matchmaking_division,
			1,
			SINGLEPLAYER_RANKED_DIVISION_THRESHOLDS.size()
		)
		mode_title = "PVE RANKED"
		context = "%s  •  TWO-LEG DRAFT  •  %dV%d" % [
			get_singleplayer_ranked_division_name(division),
			team_size,
			team_size
		]
		accent = get_singleplayer_ranked_division_color(division)
	elif champions_league_mode:
		mode_title = "DRAFT"
		context = "TWO-LEG CARD MATCH  •  %dV%d" % [team_size, team_size]
	elif tournament_mode:
		mode_title = "TOURNAMENT"
		context = "TWO LEGS  •  %dV%d" % [team_size, team_size]
	return {
		"mode_title": mode_title,
		"context": context,
		"accent": accent,
		"host_can_skip": true
	}


func _get_team_introduction_names(
	players: Array[FootballPlayer]
) -> Array:
	var lineup: Array[Dictionary] = []
	for slot in range(max_players_per_team):
		for player in players:
			if (
				is_instance_valid(player)
				and player.team_slot == slot
			):
				var player_name := player.display_name.strip_edges()
				if player_name.is_empty():
					player_name = "Player %d" % player.owner_peer_id
				var loadout: Dictionary = (
					FootballCosmeticInventory.sanitize_catalog_network_loadout(
						player.cosmetic_loadout
					)
				)
				var ranked_mmr := maxi(0, int(player.get_meta(
					"pve_ranked_mmr",
					singleplayer_ranked_mmr
				)))
				if not player.cpu_controlled:
					var profile: Dictionary = _pve_ranked_player_profiles.get(
						player.owner_peer_id,
						{"mmr": singleplayer_ranked_mmr}
					) as Dictionary
					ranked_mmr = maxi(0, int(profile.get(
						"mmr",
						singleplayer_ranked_mmr
					)))
				lineup.append({
					"name": player_name,
					"peer_id": player.owner_peer_id,
					"cpu": player.cpu_controlled,
					"boss": player.is_prestige_boss(),
					"mmr": ranked_mmr if singleplayer_ranked_mode else -1,
					"subtitle": str(loadout.get("player_subtitle", "")),
					"banner_id": player.get_cosmetic_item_id(
						FootballCosmeticInventory.SLOT_PLAYER_BANNER
					),
					"banner_color_index": int(loadout.get(
						"player_banner_color_%s" % str(player.team),
						loadout.get("player_banner_color_index", -1)
					))
				})
				break
	return lineup


func request_skip_team_introduction() -> void:
	if multiplayer.is_server():
		_server_skip_team_introduction(multiplayer.get_unique_id())
	else:
		_request_skip_team_introduction.rpc_id(SERVER_PEER_ID)


@rpc("any_peer", "call_remote", "reliable")
func _request_skip_team_introduction() -> void:
	if multiplayer.is_server():
		_server_skip_team_introduction(multiplayer.get_remote_sender_id())


func _server_skip_team_introduction(requester_id: int) -> void:
	if (
		not multiplayer.is_server()
		or requester_id != SERVER_PEER_ID
		or _current_introduction_team != &"versus"
	):
		return
	_team_introduction_skip_requested = true


@rpc("authority", "call_local", "reliable")
func _receive_team_introduction(
	team: StringName,
	player_names: Array
) -> void:
	_current_introduction_team = team
	_current_introduction_names = player_names.duplicate()
	team_introduction_changed.emit(
		team,
		_current_introduction_names.duplicate()
	)


# ================================================================
# SERVER-AUTHORITATIVE RESET COUNTDOWN
# ================================================================

func _start_reset_countdown(
	wait_for_ball_kick: bool = false
) -> void:
	if not multiplayer.is_server():
		return

	_reset_generation += 1
	var generation := _reset_generation
	round_resetting = true
	_match_clock_waiting_for_kickoff = false
	var reset_started_usec: int = Time.get_ticks_usec()

	_set_all_players_enabled(false)
	_reset_positions()

	if ball != null:
		ball.set_play_enabled(false)
	_begin_kickoff_profile(Time.get_ticks_usec() - reset_started_usec)

	_run_countdown(generation, wait_for_ball_kick)


func _run_countdown(
	generation: int,
	wait_for_ball_kick: bool
) -> void:
	for number in range(countdown_seconds, 0, -1):
		if generation != _reset_generation or not game_has_started:
			return

		_receive_countdown.rpc(str(number))
		await get_tree().create_timer(1.0).timeout

	if generation != _reset_generation or not game_has_started:
		return

	var transition_started_usec: int = Time.get_ticks_usec()
	_receive_countdown.rpc("GO")
	_set_all_ability_timers_paused(false)
	_refresh_permanent_overdrive_visuals_for_kickoff()
	_set_all_players_enabled(true)
	if ball != null:
		ball.set_play_enabled(true)
	_match_clock_waiting_for_kickoff = wait_for_ball_kick
	round_resetting = false
	_activate_kickoff_profile(
		Time.get_ticks_usec() - transition_started_usec
	)

	await get_tree().create_timer(0.75).timeout
	if generation == _reset_generation:
		_receive_countdown.rpc("")


@rpc("authority", "call_local", "reliable")
func _receive_countdown(message: String) -> void:
	_current_countdown = message
	countdown_changed.emit(message)


func _reset_positions() -> void:
	if ball == null or ball_spawn == null:
		push_error("Ball or BallSpawn was not assigned.")
		return

	# Position resets are hard teleports and must start a new replay segment.
	# Keeping a pre-reset frame makes the replay interpolate every body across
	# the entire capture pause before the real goal sequence begins.
	_reset_goal_replay_capture_segment()
	_pending_pass.clear()
	_cpu_pass_intentions.clear()
	_cpu_ball_commitments.clear()
	_cpu_tactical_intentions.clear()
	_cpu_combination_plans.clear()
	_reset_cpu_possession_state()
	ball.reset_ball(ball_spawn.global_position)
	_reset_team_players(red_players, TEAM_RED)
	_reset_team_players(blue_players, TEAM_BLUE)
	# Lock kickoff roles from the reset positions. Recomputing "closest" every
	# frame caused the original taker to sprint forward, become second-closest,
	# then retreat while a teammate took over.
	_prepare_cpu_kickoff_roles()


func _reset_team_players(
	players: Array[FootballPlayer],
	team: StringName
) -> void:
	for player in players:
		if not is_instance_valid(player):
			continue

		var spawn := _get_player_spawn(team, player.team_slot)
		if spawn != null:
			player.reset_to_position(spawn.global_position)


func _set_all_players_enabled(enabled: bool) -> void:
	if not multiplayer.is_server():
		return

	for player in red_players:
		if is_instance_valid(player):
			player.set_controls_enabled(enabled)

	for player in blue_players:
		if is_instance_valid(player):
			player.set_controls_enabled(enabled)


func _prepare_all_abilities_for_kickoff() -> void:
	if not multiplayer.is_server():
		return

	for player in red_players:
		if is_instance_valid(player):
			player.reset_ability_for_kickoff()

	for player in blue_players:
		if is_instance_valid(player):
			player.reset_ability_for_kickoff()


func _set_all_ability_timers_paused(paused: bool) -> void:
	if not multiplayer.is_server():
		return

	for player in red_players:
		if is_instance_valid(player):
			player.set_ability_timers_paused(paused)

	for player in blue_players:
		if is_instance_valid(player):
			player.set_ability_timers_paused(paused)


func _refresh_permanent_overdrive_visuals_for_kickoff() -> void:
	if not multiplayer.is_server():
		return

	for player in red_players:
		if is_instance_valid(player):
			player.refresh_permanent_overdrive_visual_for_kickoff()

	for player in blue_players:
		if is_instance_valid(player):
			player.refresh_permanent_overdrive_visual_for_kickoff()


# ================================================================
# MATCH START/END SYNCHRONIZATION
# ================================================================

func _broadcast_match_started() -> void:
	if multiplayer.is_server():
		_receive_match_started.rpc()


@rpc("authority", "call_local", "reliable")
func _receive_match_started() -> void:
	game_has_started = true
	match_results_available = false
	ranked_active_match_elapsed = 0.0
	_pve_ranked_abandonment_protection_armed = false
	_apply_fun_mutator_runtime()
	match_started.emit()


@rpc("authority", "call_local", "reliable")
func _receive_pve_ranked_abandonment_armed() -> void:
	if not singleplayer_ranked_mode:
		return
	_pve_ranked_abandonment_protection_armed = true
	_mark_local_pve_ranked_abandonment_pending()


func end_match(winning_team: StringName) -> void:
	if not multiplayer.is_server() or not game_has_started:
		return
	if not cpu_training_mode:
		_queue_human_demonstration_recording(winning_team)

	_cancel_goal_replay()
	_reset_ranked_draft_state()
	_broadcast_ranked_draft_snapshot()
	game_has_started = false
	field_variant_locked = false
	round_resetting = true
	_match_clock_waiting_for_kickoff = false
	match_results_available = true
	last_winning_team = winning_team
	_resolve_ladder_result(winning_team)
	_resolve_singleplayer_ranked_result(winning_team)
	_tiebreak_generation += 1
	penalty_attempt_active = false
	penalty_attempt_time_remaining = 0.0
	_penalty_attempt_clock_started = false
	_penalty_ball_start_position = Vector2.ZERO
	tournament_halftime_active = false
	tournament_halftime_remaining = 0
	_halftime_generation += 1
	_receive_halftime_state.rpc(false, 0)
	_ready_players.clear()
	_reset_generation += 1
	_save_check_generation += 1
	_active_shot.clear()
	_pending_pass.clear()
	_cpu_pass_intentions.clear()
	_cpu_ball_commitments.clear()
	_cpu_tactical_intentions.clear()
	_cpu_combination_plans.clear()
	_reset_cpu_possession_state()
	_set_all_players_enabled(false)
	if ranked_mode:
		_clear_all_selected_abilities()

	if ball != null:
		ball.set_play_enabled(false)

	_broadcast_timer()
	refresh_roster()
	_receive_countdown.rpc("")
	_receive_team_introduction.rpc(NO_TEAM, [])
	_broadcast_leaderboard()
	_receive_match_ended.rpc(
		winning_team,
		leaderboard_snapshot
	)


func cancel_match() -> bool:
	if not multiplayer.is_server() or not game_has_started:
		return false
	_abort_human_demonstration_recording()

	_cancel_goal_replay()
	_reset_ranked_draft_state()
	_broadcast_ranked_draft_snapshot()
	game_has_started = false
	field_variant_locked = false
	round_resetting = false
	_match_clock_waiting_for_kickoff = false
	is_overtime = false
	regulation_time_remaining = regulation_seconds
	overtime_elapsed = 0.0
	red_score = 0
	blue_score = 0
	tournament_leg = 1
	tournament_leg_red_goals = 0
	tournament_leg_blue_goals = 0
	tournament_sudden_death = false
	tournament_halftime_active = false
	tournament_halftime_remaining = 0
	_halftime_generation += 1
	_reset_tournament_tiebreak_state()
	_reset_generation += 1
	_announcement_generation += 1
	_save_check_generation += 1
	_active_shot.clear()
	_pending_pass.clear()
	_cpu_pass_intentions.clear()
	_cpu_ball_commitments.clear()
	_cpu_tactical_intentions.clear()
	_cpu_combination_plans.clear()
	_reset_cpu_possession_state()
	match_results_available = false
	last_winning_team = NO_TEAM
	_ready_players.clear()
	if ranked_mode:
		_clear_all_selected_abilities()

	_set_all_players_enabled(false)
	_reset_positions()
	if ball != null:
		ball.set_play_enabled(false)

	_receive_announcement.rpc("")
	_receive_countdown.rpc("")
	_receive_team_introduction.rpc(NO_TEAM, [])
	_receive_halftime_state.rpc(false, 0)
	_broadcast_tournament_tiebreak_state()
	_broadcast_score()
	_broadcast_timer()
	refresh_roster()
	_receive_match_cancelled.rpc()
	return true


@rpc("authority", "call_local", "reliable")
func _receive_match_ended(
	winning_team: StringName,
	entries: Array
) -> void:
	_record_local_draft_win(winning_team, entries)
	if goal_replay_active:
		_clear_goal_replay_state()
	game_has_started = false
	_restore_fun_mutator_runtime()
	_pve_ranked_abandonment_protection_armed = false
	ranked_active_match_elapsed = 0.0
	field_variant_locked = false
	round_resetting = true
	match_results_available = true
	last_winning_team = winning_team
	leaderboard_snapshot = entries.duplicate(true)
	leaderboard_changed.emit(leaderboard_snapshot)
	match_ended.emit(winning_team)
	match_results_ready.emit(
		winning_team,
		leaderboard_snapshot
	)
	_reset_draft_state(true)


@rpc("authority", "call_local", "reliable")
func _receive_match_cancelled() -> void:
	_reset_draft_state(true)
	if singleplayer_ranked_mode:
		_clear_local_pve_ranked_abandonment_pending()
	_pve_ranked_abandonment_protection_armed = false
	ranked_active_match_elapsed = 0.0
	if goal_replay_active:
		_clear_goal_replay_state()
	game_has_started = false
	_restore_fun_mutator_runtime()
	field_variant_locked = false
	round_resetting = false
	is_overtime = false
	match_results_available = false
	match_cancelled.emit()


# ================================================================
# VALIDATION
# ================================================================

func _validate_assignments() -> void:
	if players_parent == null:
		push_warning("Assign Players Parent in MatchManager.")

	if red_player_spawns.size() < max_players_per_team:
		push_warning(
			"Assign at least %d red player spawns."
			% max_players_per_team
		)

	if blue_player_spawns.size() < max_players_per_team:
		push_warning(
			"Assign at least %d blue player spawns."
			% max_players_per_team
		)
