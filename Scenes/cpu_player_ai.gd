class_name CPUPlayerAI
extends Node


const LEGACY_MAX_INTELLIGENCE: int = 15
const MAX_INTELLIGENCE: int = 20

# INT 20 is the full trained champion. Lower levels keep the same checkpoint
# but progressively reduce how strongly the learned policy overrides the safe
# built-in football logic. No speed, kick-power, or physics cheats are used.
const LEGACY_CHAMPION_UTILIZATION_AT_15: float = 0.72

const PACKAGED_HYBRID_1V1_CHECKPOINT: String = (
	"res://training/hybrid_checkpoints/1v1_active.json"
)
const PACKAGED_HYBRID_2V2_CHECKPOINT: String = (
	"res://training/hybrid_checkpoints/2v2_active.json"
)
const PACKAGED_HYBRID_3V3_CHECKPOINT: String = (
	"res://training/hybrid_checkpoints/3v3_active.json"
)
const PACKAGED_HYBRID_4V4_CHECKPOINT: String = (
	"res://training/hybrid_checkpoints/4v4_active.json"
)

const HybridTacticalAdapterScript := preload(
	"res://ai/hybrid/tactical_adapter.gd"
)
const TeamPlayPlannerScript := preload(
	"res://ai/team_play/team_play_planner.gd"
)
const AttackingPlannerScript := preload(
	"res://ai/offense/attacking_planner.gd"
)
const AbilityThreatModelScript := preload(
	"res://ai/ability/ability_threat_model.gd"
)
const RLV2RuntimeControllerScript := preload(
	"res://ai_v2/rl_runtime_controller.gd"
)

const TEAM_RED: StringName = &"red"
const TEAM_BLUE: StringName = &"blue"
const CPU_STRATEGY_BALANCED: StringName = &"balanced"
const CPU_STRATEGY_DIRECT: StringName = &"direct"
const CPU_STRATEGY_COUNTER: StringName = &"counter"
const CPU_STRATEGY_POSSESSION: StringName = &"possession"
const CPU_STRATEGY_HIGH_PRESS: StringName = &"high_press"
const CPU_STRATEGY_WALL_PLAY: StringName = &"wall_play"
const CPU_STRATEGY_ABILITY_COMBO: StringName = &"ability_combo"
const CPU_COMBO_ONE_TWO: StringName = &"one_two"
const CPU_COMBO_THIRD_MAN: StringName = &"third_man"
const CPU_COMBO_WIDE_SWITCH: StringName = &"wide_switch"
const CPU_COMBO_WALL_RELAY: StringName = &"wall_relay"
const CPU_COMBO_ABILITY_CHAIN: StringName = &"ability_chain"
const CPU_COMBO_DEAD_ZONE_TRAP_VOLLEY: StringName = &"dead_zone_trap_volley"
const CPU_COMBO_POWER_STRIKE_TRAP_VOLLEY: StringName = &"power_strike_trap_volley"
const CPU_COMBO_OVERDRIVE_DEAD_ZONE: StringName = &"overdrive_dead_zone"
const CPU_COMBO_GOALKEEPER_REBOUND: StringName = &"goalkeeper_rebound"

const TRAINED_PROFILE_PATH: String = (
	"res://training/best_cpu_profile.json"
)
const TRAINING_PARAMETER_RANGES: Dictionary = {
	"dribble_choice_chance": Vector2(0.16, 0.78),
	"advance_play_chance": Vector2(0.15, 0.82),
	"coordinated_ability_play_chance": Vector2(0.08, 0.78),
	"support_ball_lane_blend": Vector2(0.15, 0.78),
	"pass_lead_seconds": Vector2(0.05, 0.42),
	"cpu_receiver_forward_lead": Vector2(80.0, 620.0),
	"minimum_forward_pass_progress": Vector2(180.0, 1100.0),
	"pass_lane_clearance": Vector2(130.0, 420.0),
	"elite_pass_lookahead_weight": Vector2(0.25, 1.0),
	"wall_dribble_choice_chance": Vector2(0.05, 0.68),
	"creative_shot_chance": Vector2(0.08, 0.72),
	"creative_wall_shot_chance": Vector2(0.04, 0.62),
	"double_bank_shot_chance": Vector2(0.01, 0.42),
	"double_bank_minimum_route_clearance": Vector2(110.0, 440.0),
	"double_bank_minimum_scoring_speed": Vector2(60.0, 720.0),
	"double_bank_value_advantage": Vector2(40.0, 620.0),
	"ability_improvisation_chance": Vector2(0.05, 0.62),
	"defensive_block_ball_blend": Vector2(0.12, 0.72),
	"dynamic_cover_center_blend": Vector2(0.08, 0.72),
	"dynamic_forward_width": Vector2(320.0, 1250.0),
	"shot_aim_vertical_spread": Vector2(70.0, 360.0),
	"required_shot_alignment": Vector2(0.42, 0.9),
	"release_shot_alignment": Vector2(0.32, 0.82),
	"separation_strength": Vector2(0.25, 1.35),
	"pass_pressure_radius": Vector2(380.0, 1150.0),
	"contested_ball_radius": Vector2(340.0, 720.0),
	"contest_yield_seconds": Vector2(0.14, 0.68),
	"contest_escape_choice_chance": Vector2(0.12, 0.82),
	"ball_chaser_commitment_seconds": Vector2(0.25, 1.2),
	"ball_chaser_takeover_ratio": Vector2(0.48, 0.9),
	"support_distance_behind_ball": Vector2(480.0, 1450.0),
	"support_minimum_teammate_spacing": Vector2(300.0, 900.0),
	"off_ball_run_behind_distance": Vector2(280.0, 900.0),
	"off_ball_return_lane_depth": Vector2(300.0, 950.0),
	"off_ball_return_lane_width": Vector2(420.0, 1250.0),
	"off_ball_cover_distance": Vector2(700.0, 1650.0),
	"off_ball_rebound_goal_distance": Vector2(850.0, 1850.0),
	"off_ball_transition_recovery_seconds": Vector2(0.55, 1.8),
	"dynamic_forward_distance": Vector2(620.0, 1650.0),
	"defensive_anchor_distance": Vector2(1350.0, 2900.0),
	"midfield_anchor_distance": Vector2(2200.0, 4200.0),
	"striker_anchor_distance": Vector2(3200.0, 4900.0),
	"goalkeeper_depth": Vector2(420.0, 1550.0),
	"goalkeeper_chase_distance": Vector2(850.0, 2400.0)
}

const INTENT_IDLE: StringName = &"idle"
const INTENT_CHASE: StringName = &"chase_ball"
const INTENT_DRIBBLE: StringName = &"dribble"
const INTENT_SHOOT: StringName = &"shoot"
const INTENT_PASS: StringName = &"pass"
const INTENT_RECEIVE: StringName = &"receive"
const INTENT_COVER: StringName = &"cover"
const INTENT_FORWARD_RUN: StringName = &"forward_run"
const INTENT_WIDE_SUPPORT: StringName = &"wide_support"
const INTENT_MARK: StringName = &"mark"
const INTENT_ENFORCE: StringName = &"enforce"
const INTENT_GOALKEEP: StringName = &"goalkeep"

const ACTION_NONE: StringName = &"none"
const ACTION_GET_BALL: StringName = &"get_ball"
const ACTION_ATTACK: StringName = &"attack"
const ACTION_PASS: StringName = &"pass"
const ACTION_SHOOT: StringName = &"shoot"
const ACTION_SUPPORT: StringName = &"support"
const ACTION_DEFEND: StringName = &"defend"
const ACTION_GOALKEEP: StringName = &"goalkeep"
const ACTION_ABILITY: StringName = &"ability"
const ACTION_KICKOFF: StringName = &"kickoff"

const ACTION_COMMITMENT_DEFAULT_SECONDS: float = 0.16
const ACTION_COMMITMENT_BALL_SECONDS: float = 0.32
const ACTION_COMMITMENT_KICKOFF_SECONDS: float = 0.40

# 5v5/6v6 can field ten to twelve tactical brains. Their continuous movement,
# charging, first-touch execution and committed actions still run every 60 Hz
# physics tick, but expensive full tactical replans are distributed across three
# physics phases. This prevents several elite CPUs from rebuilding observations,
# pass candidates and team plans on the same frame. 4v4 and smaller are unchanged.
const FIVE_PLUS_TACTICAL_DECISION_PHASES: int = 3

const ACTION_INTERRUPT_RECONSIDER: StringName = &"reconsider"
const ACTION_INTERRUPT_IMMEDIATE: StringName = &"immediate"

const FIRST_TOUCH_NONE: StringName = &"none"
const FIRST_TOUCH_SOFT: StringName = &"soft"
const FIRST_TOUCH_DIRECTIONAL: StringName = &"directional"
const FIRST_TOUCH_PASS: StringName = &"one_touch_pass"
const FIRST_TOUCH_SHOT: StringName = &"first_time_shot"
const FIRST_TOUCH_DUMMY: StringName = &"dummy"

const TACTICAL_ROLE_STRIKER: StringName = &"striker"
const TACTICAL_ROLE_PLAYMAKER: StringName = &"playmaker"
const TACTICAL_ROLE_DEFENDER: StringName = &"defender"
const TACTICAL_ROLE_GOALKEEPER: StringName = &"goalkeeper"

# 4v4+ needs an actual team shape rather than more agents applying the small-team
# logic around the same ball. These formation roles are intentionally separate
# from the legacy tactical roles so 1v1-3v3 behaviour stays unchanged.
const LARGE_TEAM_ROLE_DEFENDER: StringName = &"defender"
const LARGE_TEAM_ROLE_MIDFIELDER: StringName = &"midfielder"
const LARGE_TEAM_ROLE_WINGER: StringName = &"winger"
const LARGE_TEAM_ROLE_STRIKER: StringName = &"striker"

const CPU_PERSONALITY_AUTO: StringName = &"auto"
const CPU_PERSONALITY_DIRECT: StringName = &"direct"
const CPU_PERSONALITY_TECHNICAL: StringName = &"technical"
const CPU_PERSONALITY_POSSESSION: StringName = &"possession"
const CPU_PERSONALITY_AGGRESSIVE: StringName = &"aggressive"
const CPU_PERSONALITY_COUNTERATTACKER: StringName = &"counterattacker"
const CPU_PERSONALITY_ADAPTIVE: StringName = &"adaptive"
const CPU_PERSONALITIES: Array[StringName] = [
	CPU_PERSONALITY_DIRECT,
	CPU_PERSONALITY_TECHNICAL,
	CPU_PERSONALITY_POSSESSION,
	CPU_PERSONALITY_AGGRESSIVE,
	CPU_PERSONALITY_COUNTERATTACKER,
	CPU_PERSONALITY_ADAPTIVE
]


@export_category("Hybrid Tactical Policy")
@export var hybrid_tactical_policy_enabled: bool = true
@export_file("*.json")
var hybrid_tactical_checkpoint_path: String = (
	"user://hybrid_ai/1v1/active.json"
)
@export var hybrid_team_size_checkpoints_enabled: bool = true
@export_file("*.json")
var hybrid_2v2_checkpoint_path: String = (
	"user://hybrid_ai/2v2/active.json"
)
@export_file("*.json")
var hybrid_3v3_checkpoint_path: String = (
	"user://hybrid_ai/3v3/active.json"
)
@export_file("*.json")
var hybrid_4v4_checkpoint_path: String = (
	"user://hybrid_ai/4v4/active.json"
)
@export_range(0.04, 0.5, 0.01)
var hybrid_tactical_decision_interval: float = 0.06
@export var hybrid_debug_logging: bool = false

@export_category("Value Attacking Planner")
@export var value_attacking_planner_enabled: bool = true
@export var value_attacking_minimum_score: float = 250.0
@export var value_attacking_replan_seconds: float = 0.12
@export var value_attacking_touch_cooldown: float = 0.18

@export_category("Tactical Roles")
@export var tactical_roles_enabled: bool = true
@export var striker_support_bonus: float = 420.0
@export var playmaker_support_bonus: float = 390.0
@export var defender_support_bonus: float = 470.0
@export var large_team_football_shape_enabled: bool = true
@export var large_team_defensive_zone_blend: float = 0.58
@export var large_team_minimum_support_spacing: float = 820.0
@export var large_team_pass_preference_bonus: float = 185.0
@export var large_team_shape_discipline_enabled: bool = true
@export var large_team_second_ball_distance: float = 980.0
@export var large_team_non_chaser_ball_clearance: float = 760.0
@export var large_team_release_pass_pressure_radius: float = 980.0
@export var large_team_release_pass_crowd_radius: float = 820.0
@export var large_team_shape_cache_seconds: float = 0.24
@export var large_team_second_ball_cache_seconds: float = 0.08
@export var large_team_release_pass_scan_seconds: float = 0.08

@export_category("CPU Personality")
@export_enum("auto", "direct", "technical", "possession", "aggressive", "counterattacker", "adaptive")
var cpu_personality: String = "auto"
@export_range(0, 20, 1)
var skill_level_override: int = 0
@export_range(0.0, 1.0, 0.01)
var personality_strength: float = 0.82
@export var personality_adaptation_window_seconds: float = 18.0

@export_category("Competitive CPU")
@export var perfect_execution_mode: bool = true
@export var innate_meta_vision: bool = false
@export_range(0.0, 1.0, 0.01)
var one_vs_one_control_priority: float = 1.0
@export var one_vs_one_finish_distance: float = 1550.0
@export var one_vs_one_finish_lane: float = 185.0
@export var one_vs_one_bypass_margin: float = 180.0
@export var one_vs_one_followup_arrival_margin: float = 0.10
@export var one_vs_one_bypass_forward_distance: float = 920.0
@export var one_vs_one_bypass_lateral_distance: float = 760.0

@export_category("Elite 1v1 Space Play")
@export var one_vs_one_space_play_enabled: bool = true
@export var one_vs_one_space_play_minimum_score: float = 520.0
@export var one_vs_one_space_play_minimum_progress: float = 430.0
@export var one_vs_one_space_play_minimum_bypass: float = 120.0
@export var one_vs_one_space_play_minimum_route_clearance: float = 115.0
@export var one_vs_one_space_play_minimum_recovery_margin: float = 0.02
@export var one_vs_one_space_play_maximum_control_gap: float = 0.36
@export var one_vs_one_space_play_lead_seconds: float = 0.08
@export var one_vs_one_space_play_commit_seconds: float = 1.35
@export var one_vs_one_space_play_cooldown_seconds: float = 0.18
@export var one_vs_one_space_play_minimum_force: float = 980.0
@export var one_vs_one_space_play_maximum_force: float = 2425.0
@export var one_vs_one_space_play_wall_bonus: float = 470.0
@export var one_vs_one_space_play_shooting_lane_target: float = 360.0
@export var one_vs_one_space_play_straight_line_penalty: float = 680.0

@export_category("Elite Finishing Scan")
@export_range(0.50, 0.99, 0.01)
var elite_full_charge_goal_probability: float = 0.80
@export_range(0.30, 0.95, 0.01)
var elite_controlled_shot_probability: float = 0.50
@export var elite_finish_goal_samples: int = 11
@export var elite_finish_wall_samples: int = 6
@export var elite_finish_maximum_scan_distance: float = 6100.0
@export var elite_finish_minimum_lane_clearance: float = 72.0
@export var elite_finish_controlled_minimum_ratio: float = 0.56
@export var elite_finish_controlled_maximum_ratio: float = 0.84
@export var elite_finish_reaction_seconds: float = 0.12
@export var elite_finish_goal_margin: float = 72.0
@export var elite_finish_wall_probability_penalty: float = 0.04
@export var elite_finish_through_defender_bonus: float = 0.15
@export var elite_finish_open_lane_bonus: float = 0.12
@export var elite_finish_close_range_bonus: float = 0.10
@export var elite_finish_defender_behind_bonus: float = 0.10
@export var elite_finish_interrupt_space_play: bool = true

@export_category("Competitive Kickoff")
@export var kickoff_strategy_enabled: bool = true
@export var kickoff_center_tolerance: float = 125.0
@export var kickoff_ball_speed_tolerance: float = 90.0
@export var kickoff_delayed_wait_seconds: float = 0.28
@export var kickoff_fake_retreat_distance: float = 420.0
@export var kickoff_possession_touch_force: float = 1380.0
@export var kickoff_wall_touch_force: float = 1660.0
@export var kickoff_aggressive_touch_force: float = 2300.0
@export var kickoff_counter_touch_force: float = 2050.0
@export var kickoff_opponent_rush_speed: float = 720.0
@export var kickoff_side_offset: float = 260.0
@export var kickoff_strategy_commit_seconds: float = 2.4

@export_category("Decision Timing")
@export var decision_interval: float = 0.045
@export var decision_interval_jitter: float = 0.012
@export_category("High Tempo CPU Thinking")
@export var high_tempo_thinking_enabled: bool = true
@export_range(0.005, 0.05, 0.001)
var high_tempo_elite_decision_seconds: float = 0.014
@export_range(0.0, 0.02, 0.001)
var high_tempo_elite_decision_jitter: float = 0.001
@export_range(0.02, 0.5, 0.01)
var high_tempo_possession_commit_seconds: float = 0.08
@export_range(0.02, 0.5, 0.01)
var high_tempo_team_sequence_commit_seconds: float = 0.10
@export_range(0, 16, 1)
var high_tempo_extra_pass_plans: int = 10
@export_range(0, 20, 1)
var high_tempo_extra_goal_samples: int = 10
@export var ball_prediction_seconds: float = 0.16
@export var intention_prediction_seconds: float = 0.65
@export_range(0.0, 1.0, 0.01)
var intention_target_blend: float = 0.48

@export_category("Human-like Behaviour")
# Difficulty should primarily affect tactical evaluation. Keep the old physical
# hesitation/misread simulation available for experiments, but disabled for live
# CPU levels so INT 10 and INT 20 execute the action they selected with the same
# reliable movement/kick machinery.
@export var legacy_skill_execution_errors_enabled: bool = false
@export_range(0.0, 1.0, 0.001)
var mistake_chance_per_decision: float = 0.002
@export_range(0.0, 1.0, 0.01)
var missed_read_chance: float = 0.035
@export var hesitation_min_seconds: float = 0.015
@export var hesitation_max_seconds: float = 0.055
@export var perception_error_refresh_seconds: float = 0.7
@export var maximum_ball_read_error: float = 72.0
@export var maximum_shot_aim_error: float = 82.0
@export_range(0.0, 0.01, 0.0001)
var elite_mistake_chance_floor: float = 0.0008
@export_range(0.0, 0.25, 0.005)
var elite_perception_error_ratio: float = 0.035
@export_range(0.0, 0.25, 0.005)
var elite_missed_read_ratio: float = 0.04

@export_category("Movement")
@export var target_tolerance: float = 75.0
@export var strike_position_distance: float = 205.0
@export var separation_radius: float = 360.0
@export var separation_strength: float = 0.75
@export var stuck_check_seconds: float = 0.65
@export var stuck_movement_threshold: float = 22.0
@export var stuck_sidestep_strength: float = 0.7

@export_category("Possession Deadlock Prevention")
@export var possession_deadlock_seconds: float = 1.15
@export var possession_deadlock_ball_movement: float = 115.0
@export var possession_deadlock_forward_progress: float = 90.0
@export var possession_deadlock_retry_seconds: float = 0.8
@export var deadlock_escape_route_distance: float = 980.0
@export var deadlock_escape_minimum_clearance: float = 150.0
@export var two_vs_two_keeper_build_up_depth: float = 1180.0
@export var two_vs_two_keeper_outlet_space: float = 360.0

@export_category("2v2 Rotation and Distribution")
@export var two_vs_two_rotation_enabled: bool = true
@export var two_vs_two_rotation_minimum_progress: float = 3150.0
@export var two_vs_two_rotation_goal_distance: float = 3000.0
@export var two_vs_two_defender_join_goal_distance: float = 2450.0
@export var two_vs_two_rotation_trailing_distance: float = 560.0
@export var two_vs_two_rotation_lateral_distance: float = 690.0
@export var two_vs_two_outlet_follow_seconds: float = 2.8
@export var two_vs_two_outlet_follow_distance: float = 920.0
@export var goalkeeper_controlled_outlet_enabled: bool = true
@export var goalkeeper_controlled_outlet_speed: float = 1120.0
@export var goalkeeper_distribution_force_clearance: float = 105.0
@export var defensive_power_pass_minimum_distance: float = 1750.0
@export var defensive_power_pass_minimum_progress: float = 900.0

@export_category("Relative Loose Ball Roles")
@export var relative_loose_ball_roles_enabled: bool = true
@export var relative_loose_ball_prediction_seconds: float = 0.32
@export var relative_loose_ball_race_margin_seconds: float = 0.16
# A genuinely loose ball still needs one CPU to contest it even when the race
# is close. The old logic only claimed balls the CPU was already clearly first
# to, which let the defensive role system pull everyone toward an imaginary
# carrier while the ball sat recoverable in open space.
@export var relative_loose_ball_contest_margin_seconds: float = 0.52
@export var relative_loose_ball_commit_seconds: float = 0.95
@export var relative_loose_ball_takeover_ratio: float = 0.88
@export var relative_loose_ball_minimum_opponent_space: float = 260.0
@export var goalkeeper_secure_collection_speed: float = 2200.0
@export var goalkeeper_uncontested_carry_enabled: bool = true

@export_category("Team Ball Ownership")
@export var team_ball_actor_enabled: bool = true

@export_category("Fast Team Attack")
@export var obvious_pass_override_enabled: bool = true
@export var obvious_pass_blocked_shot_lane: float = 285.0
@export_range(0.0, 1.0, 0.01)
var obvious_pass_minimum_quality: float = 0.58
@export var obvious_pass_minimum_route_clearance: float = 175.0
@export var obvious_pass_minimum_interception_margin: float = 0.02
@export var obvious_pass_minimum_receiver_space: float = 360.0
@export var obvious_pass_human_bonus: float = 230.0
@export_range(0.3, 1.0, 0.01)
var obvious_pass_charge_multiplier: float = 0.72
@export var fast_finish_enabled: bool = true
@export var fast_finish_maximum_distance: float = 3000.0
@export var fast_finish_minimum_lane: float = 300.0
@export_range(0.3, 1.0, 0.01)
var fast_finish_charge_multiplier: float = 0.68
@export var live_shot_retarget_enabled: bool = true

@export_category("Possession Action Arbiter")
@export var possession_action_arbiter_enabled: bool = true
@export var possession_action_minimum_score: float = 430.0
@export var possession_action_minimum_advantage: float = 105.0
@export var possession_action_commit_seconds: float = 0.28
@export var possession_action_recovery_window_seconds: float = 2.2
@export var possession_action_recovery_pass_bonus: float = 420.0
@export var possession_action_requested_pass_bonus: float = 760.0
@export var possession_action_blocked_shot_pass_bonus: float = 520.0
@export var possession_action_open_shot_bonus: float = 360.0
@export var possession_action_close_shot_distance: float = 2550.0
@export var possession_action_shot_intercept_margin: float = 0.02
@export var possession_action_dribble_probe_distance: float = 950.0

@export_category("Dribbling")
@export_range(0.0, 1.0, 0.01)
var dribble_choice_chance: float = 0.44
@export var dribble_commit_seconds: float = 0.9
@export var dribble_touch_force: float = 390.0
@export var dribble_touch_interval: float = 0.42
@export var dribble_minimum_goal_distance: float = 1750.0
@export var dribble_minimum_space: float = 430.0
@export var dribble_lateral_avoidance: float = 0.42
@export_range(1, 20, 1) var reverse_dribble_minimum_level: int = 9

@export_category("Contested Ball")
@export var contested_ball_radius: float = 540.0
@export var contested_ball_maximum_speed: float = 1350.0
@export var contest_yield_seconds: float = 0.32
@export var contest_reengage_seconds: float = 0.85
@export var contest_angle_distance: float = 470.0
@export var contest_role_rotation_seconds: float = 1.4
@export var contest_escape_touch_force: float = 680.0
@export var contest_escape_touch_interval: float = 0.8
@export_range(0.0, 1.0, 0.01)
var contest_escape_choice_chance: float = 0.38
@export var ball_chaser_commitment_seconds: float = 0.72
@export_range(0.1, 0.98, 0.01)
var ball_chaser_takeover_ratio: float = 0.7

@export_category("Coordinated Defense")
@export var defensive_ball_win_retry_seconds: float = 0.34
@export var defensive_ball_win_clear_force: float = 720.0

@export_category("Formation")
@export var goalkeeper_depth: float = 650.0
@export var goalkeeper_chase_distance: float = 1350.0
@export var goalkeeper_mouth_padding: float = 150.0
@export_range(1, 20, 1) var advanced_goal_line_save_minimum_level: int = 9
@export var support_distance_behind_ball: float = 850.0
@export var support_ball_lane_blend: float = 0.4
@export var defensive_anchor_distance: float = 2050.0
@export var midfield_anchor_distance: float = 3150.0
@export var striker_anchor_distance: float = 4050.0
@export var dynamic_cover_distance: float = 900.0
@export var dynamic_cover_center_blend: float = 0.28
@export var dynamic_forward_distance: float = 1050.0
@export var dynamic_forward_width: float = 680.0
@export var dynamic_wide_distance: float = 240.0
@export var dynamic_wide_width: float = 980.0

@export_category("Planned Pass Support")
@export_range(0.0, 1.0, 0.01)
var advance_play_chance: float = 0.42
@export_range(0.0, 1.0, 0.01)
var coordinated_ability_play_chance: float = 0.3
@export var advance_play_duration: float = 1.35
@export var advance_play_retry_seconds: float = 0.55
@export var support_forward_run_distance: float = 1050.0
@export var support_diagonal_run_distance: float = 720.0
@export var support_minimum_lane_clearance: float = 190.0
@export var support_minimum_teammate_spacing: float = 430.0
@export var overdrive_through_run_minimum_distance: float = 1250.0
@export var overdrive_through_run_maximum_distance: float = 2200.0
@export var overdrive_through_run_lateral_range: float = 900.0
@export var overdrive_through_run_duration: float = 2.25
@export var overdrive_through_run_retry_seconds: float = 2.0

@export_category("Passing")
@export var minimum_pass_distance: float = 420.0
@export var maximum_pass_distance: float = 3400.0
@export var pass_lead_seconds: float = 0.18
@export var cpu_receiver_forward_lead: float = 280.0
@export var pass_intention_seconds: float = 1.8
@export var minimum_pass_charge_seconds: float = 0.2
@export var maximum_pass_charge_seconds: float = 0.82
@export var pass_pressure_radius: float = 720.0
@export var pass_lane_clearance: float = 235.0
@export var minimum_forward_pass_progress: float = 560.0
@export var build_up_pass_goal_distance: float = 4200.0
@export var pass_plan_lock_seconds: float = 0.3
@export var avoid_passes_near_goal_distance: float = 1900.0
@export var committed_shot_goal_distance: float = 3650.0
@export_range(0.0, 1.0, 0.01)
var creative_shot_chance: float = 0.24
@export_range(0.0, 1.0, 0.01)
var creative_wall_shot_chance: float = 0.18
@export_range(0.0, 1.0, 0.01)
var double_bank_shot_chance: float = 0.14
@export var double_bank_minimum_route_clearance: float = 210.0
@export var double_bank_minimum_scoring_speed: float = 180.0
@export var double_bank_value_advantage: float = 170.0
@export var creative_shot_minimum_interval: float = 1.1
@export var creative_shot_maximum_interval: float = 2.4
@export var requested_pass_score_bonus: float = 1200.0
@export_range(0.0, 1.0, 0.01)
var elite_build_up_minimum_skill: float = 0.78
@export var elite_backpass_opening_score: float = 720.0
@export var elite_backpass_minimum_distance: float = 650.0
@export var elite_backpass_minimum_keeper_space: float = 520.0
@export var goalkeeper_distribution_maximum_distance: float = 4700.0
@export var goalkeeper_distribution_wide_bonus: float = 0.42
@export var goalkeeper_distribution_switch_bonus: float = 0.28

@export_category("Advanced Team Play")
@export var advanced_team_play_enabled: bool = true
@export_range(0.0, 1.0, 0.01)
var advanced_team_play_minimum_quality: float = 0.52
@export_range(-0.5, 1.5, 0.01)
var advanced_team_play_minimum_interception_margin: float = -0.02
@export_range(0.0, 1.0, 0.01)
var advanced_team_play_maximum_counter_risk: float = 0.78
@export var advanced_team_play_plan_lock_seconds: float = 0.48
@export var advanced_team_play_support_enabled: bool = true
@export var advanced_team_play_preserve_worker_two: bool = true

@export_category("Explicit Off-Ball Movement")
@export var explicit_off_ball_movement_enabled: bool = true
@export var off_ball_shooting_phase_goal_distance: float = 2550.0
@export var off_ball_run_behind_distance: float = 460.0
@export var off_ball_run_behind_lateral_distance: float = 650.0
@export var off_ball_run_behind_minimum_space: float = 320.0
@export var off_ball_goal_line_buffer: float = 620.0
@export var off_ball_goalkeeper_exclusion_distance: float = 820.0
@export var off_ball_default_defender_line_depth: float = 1320.0
@export var off_ball_return_lane_depth: float = 520.0
@export var off_ball_return_lane_width: float = 720.0
@export var off_ball_width_forward_distance: float = 320.0
@export var off_ball_width_wall_margin: float = 390.0
@export var off_ball_decoy_line_offset: float = 180.0
@export var off_ball_decoy_lateral_distance: float = 1040.0
@export var off_ball_decoy_desired_marker_distance: float = 520.0
@export var off_ball_cover_distance: float = 1050.0
@export_range(0.0, 1.0, 0.01)
var off_ball_cover_center_blend: float = 0.58
@export var off_ball_far_post_depth: float = 720.0
@export var off_ball_far_post_mouth_padding: float = 165.0
@export var off_ball_rebound_goal_distance: float = 1280.0
@export var off_ball_rebound_side_offset: float = 520.0
@export var off_ball_rebound_advance_distance: float = 620.0
@export var off_ball_transition_recovery_seconds: float = 1.15
@export var off_ball_transition_ball_depth: float = 920.0
@export var off_ball_transition_lane_spacing: float = 620.0
@export var off_ball_transition_advanced_extra_depth: float = 480.0
@export var off_ball_transition_arrival_tolerance: float = 170.0

@export_category("Shared Team Sequence")
@export var shared_team_sequence_enabled: bool = true
@export_range(0.0, 1.0, 0.01)
var shared_team_sequence_advisory_confidence: float = 0.48
@export_range(0.0, 1.0, 0.01)
var shared_team_sequence_force_confidence: float = 0.78
@export var shared_team_sequence_minimum_route_clearance: float = 175.0
@export var shared_team_sequence_minimum_arrival_margin: float = 0.10
@export var shared_team_sequence_commit_seconds: float = 0.42

@export_category("Elite Combination Play")
@export_range(0.0, 1.0, 0.01)
var elite_combination_minimum_skill: float = 0.9
@export var elite_combination_lifetime: float = 3.2
@export var elite_one_two_run_distance: float = 1150.0
@export var elite_third_man_lead_distance: float = 720.0
@export var elite_pass_lookahead_weight: float = 0.72
@export var elite_counterpress_radius: float = 2350.0
@export var elite_counterpress_lane_blend: float = 0.42
@export var elite_normal_shot_distance: float = 2450.0
@export var elite_minimum_shot_lane: float = 300.0
@export var elite_open_long_shot_lane: float = 520.0
@export var elite_retention_dribble_seconds: float = 0.72

@export_category("CPU Pass Requests")
@export var pass_request_minimum_interval: float = 2.2
@export var pass_request_maximum_interval: float = 4.0
@export var pass_request_retry_interval: float = 0.4
@export var pass_request_minimum_distance: float = 520.0
@export var pass_request_maximum_distance: float = 3000.0
@export var pass_request_minimum_openness: float = 470.0
@export var pass_request_minimum_lane_clearance: float = 190.0
@export var pass_request_minimum_score: float = 480.0

@export_category("Elite Follow-up Finish")
@export var fast_follow_up_finish_enabled: bool = true
@export_range(1, 20, 1)
var fast_follow_up_finish_minimum_level: int = 13
@export var fast_follow_up_finish_window_seconds: float = 0.44
@export var fast_follow_up_finish_minimum_ball_speed: float = 620.0
@export var fast_follow_up_finish_minimum_distance: float = 520.0
@export var fast_follow_up_finish_maximum_distance: float = 5000.0
@export var fast_follow_up_finish_minimum_lane_clearance: float = 120.0
@export var fast_follow_up_finish_tactical_score_bonus: float = 540.0
@export var fast_follow_up_finish_power_strike_score_bonus: float = 180.0
@export_range(-1.0, 1.0, 0.01)
var fast_follow_up_finish_minimum_alignment: float = 0.28

@export_category("Golden Goal Tactics")
@export var overtime_shot_goal_distance: float = 4700.0
@export var overtime_minimum_shot_lane: float = 210.0
@export var overtime_forward_run_bonus: float = 520.0
@export var overtime_wide_support_bonus: float = 280.0
@export var overtime_human_receiver_bonus: float = 420.0
@export var overtime_direct_play_distance: float = 5000.0

@export_category("Pass Reception")
@export var incoming_pass_minimum_speed: float = 260.0
@export var incoming_pass_maximum_seconds: float = 3.0
@export var incoming_pass_lane_width: float = 680.0
@export var incoming_pass_receiver_advantage: float = 90.0

@export_category("CPU First Touch")
@export var cpu_first_touch_enabled: bool = true
@export var first_touch_plan_timeout_seconds: float = 3.2
@export var first_touch_replan_distance: float = 440.0
@export var first_touch_contact_offset: float = 105.0
@export var first_touch_minimum_approach_speed: float = 120.0
@export var first_touch_soft_target_speed: float = 330.0
@export var first_touch_directional_target_speed: float = 760.0
@export var first_touch_pass_minimum_speed: float = 1120.0
@export var first_touch_pass_maximum_speed: float = 2250.0
@export var first_touch_shot_minimum_speed: float = 2050.0
@export var first_touch_shot_maximum_speed: float = 2950.0
@export var first_touch_maximum_control_speed: float = 2350.0
@export var first_touch_directional_pressure_distance: float = 900.0
@export var first_touch_shot_maximum_distance: float = 2550.0
@export var first_touch_shot_minimum_lane: float = 175.0
@export var first_touch_pass_minimum_score: float = 470.0
@export var first_touch_pass_minimum_distance: float = 430.0
@export var first_touch_pass_maximum_distance: float = 2850.0
@export var first_touch_dummy_minimum_skill: float = 0.68
@export var first_touch_dummy_minimum_speed: float = 620.0
@export var first_touch_dummy_maximum_lateral_gap: float = 350.0
@export var first_touch_dummy_minimum_forward_gap: float = 260.0
@export var first_touch_dummy_maximum_forward_gap: float = 1500.0
@export var first_touch_dummy_sidestep_distance: float = 270.0
@export var first_touch_dummy_passed_distance: float = 150.0
@export var first_touch_action_cooldown_seconds: float = 0.22

@export_category("Wall Play")
@export var ball_wall_top_y: float = 806.0
@export var ball_wall_bottom_y: float = 4194.0
@export var wall_route_edge_padding: float = 360.0
@export var wall_route_minimum_clearance: float = 245.0
@export var wall_route_required_advantage: float = 95.0
@export var wall_route_length_penalty: float = 0.055
@export_range(0.0, 1.0, 0.01)
var wall_dribble_choice_chance: float = 0.28
@export var wall_dribble_touch_force: float = 2500.0
@export var wall_dribble_forward_distance: float = 950.0
@export var wall_dribble_commit_seconds: float = 2.6

@export_category("Double-Bank Wall Shots")
@export var double_bank_goalkeeper_clearance: float = 250.0
@export var double_bank_goal_mouth_padding: float = 84.0
@export var double_bank_debug_overlay_enabled: bool = false
@export var double_bank_debug_maximum_points: int = 180

@export_category("Ability Tactics")
@export var direct_finish_support_goal_distance: float = 1150.0
@export var direct_finish_support_side_offset: float = 520.0
@export var mirage_setup_force: float = 620.0
@export var mirage_setup_delay: float = 0.09
@export var mirage_setup_enemy_distance: float = 700.0
@export var enforcer_pressure_distance: float = 185.0
@export var enforcer_kick_retry_seconds: float = 0.48
@export_range(0.0, 1.0, 0.01)
var enforcer_kick_force_ratio: float = 0.76
@export var ability_ready_threat_multiplier: float = 0.62
@export var power_strike_minimum_safe_lane: float = 185.0
@export var power_strike_cover_distance: float = 2600.0
@export var power_strike_activation_goal_distance: float = 6500.0
@export var power_strike_cover_required_distance: float = 3400.0
@export var power_strike_distribution_minimum_distance: float = 2100.0
@export var power_strike_distribution_maximum_distance: float = 6200.0
@export var power_strike_distribution_minimum_progress: float = 1250.0
@export var power_strike_distribution_minimum_lane: float = 175.0
@export var power_strike_distribution_support_depth: float = 1150.0
@export var power_strike_distribution_charge_seconds: float = 0.42
@export var power_strike_cpu_fast_charge_enabled: bool = true
@export_range(0.2, 1.2, 0.01)
var power_strike_cpu_minimum_charge_seconds: float = 0.22
@export_range(0.25, 1.4, 0.01)
var power_strike_cpu_long_charge_seconds: float = 0.34
@export var curve_shot_distribution_minimum_distance: float = 1050.0
@export var curve_shot_distribution_maximum_distance: float = 4100.0
@export var curve_shot_distribution_minimum_progress: float = 520.0
@export var curve_shot_distribution_maximum_direct_lane: float = 330.0
@export var curve_shot_distribution_minimum_lane: float = 52.0
@export var curve_shot_distribution_charge_seconds: float = 0.76
@export_range(1.0, 4.0, 0.05)
var power_strike_improvisation_multiplier: float = 2.15
@export var ability_interception_reach_bonus: float = 150.0
@export var curve_shot_minimum_goal_distance: float = 1050.0
@export var curve_shot_maximum_goal_distance: float = 3900.0
@export var burst_dribble_maximum_ball_speed: float = 1150.0
@export var burst_gap_close_minimum_distance: float = 700.0
@export var burst_gap_close_maximum_distance: float = 1750.0
@export var burst_gap_close_prediction_seconds: float = 0.22
@export var burst_gap_close_dash_distance: float = 560.0
@export var burst_gap_close_minimum_gain: float = 260.0
@export var dead_zone_receiver_advantage: float = 180.0
@export var dead_zone_minimum_open_space: float = 360.0
@export var dead_zone_self_pass_probe_distance: float = 1450.0
@export_category("Dead Zone Pass to Trap or Volley")
@export var dead_zone_combo_minimum_distance: float = 700.0
@export var dead_zone_combo_maximum_distance: float = 3900.0
@export var dead_zone_combo_minimum_forward_progress: float = 320.0
@export var dead_zone_combo_receiver_reach: float = 980.0
@export var dead_zone_combo_minimum_pass_clearance: float = 185.0
@export var dead_zone_combo_minimum_scoring_clearance: float = 185.0
@export var dead_zone_combo_commit_seconds: float = 1.65
@export var dead_zone_combo_lifetime_seconds: float = 2.8
@export_category("Goalkeeper Rebound Follow-up")
@export var goalkeeper_rebound_minimum_shot_distance: float = 1200.0
@export var goalkeeper_rebound_minimum_collection_speed: float = 260.0
@export var goalkeeper_rebound_collection_seconds: float = 0.55
@export var goalkeeper_rebound_lifetime_seconds: float = 2.2
@export var goalkeeper_rebound_maximum_clear_goal_lane: float = 560.0
@export var reflex_block_minimum_threat_speed: float = 620.0
@export var iron_anchor_control_pressure_radius: float = 620.0
@export var boogie_woogie_minimum_position_gain: float = 480.0
@export var trap_or_volley_receive_lane_bonus: float = 620.0
@export var overdrive_forward_run_bonus: float = 460.0
@export var overdrive_cover_role_penalty: float = 1050.0
@export var defensive_support_role_bonus: float = 420.0
@export var dribble_support_role_bonus: float = 240.0
@export_range(0.0, 1.0, 0.01)
var ability_improvisation_chance: float = 0.24
@export var ability_improvisation_min_interval: float = 0.55
@export var ability_improvisation_max_interval: float = 0.95

@export_category("Opponent Ability Awareness")
@export var opponent_ability_awareness_enabled: bool = true
@export var shared_ability_team_plan_enabled: bool = true
@export_range(0.0, 1.0, 0.01)
var ability_defense_minimum_threat: float = 0.46
@export_range(0.0, 1.0, 0.01)
var ability_emergency_threat: float = 0.72
@export var power_strike_lane_standoff: float = 520.0
@export var bypass_threat_goal_side_buffer: float = 610.0
@export var ability_goalkeeper_deep_blend: float = 0.22
@export var ability_threat_cache_seconds: float = 0.10

@export_category("Defending")
@export var marking_distance: float = 430.0
@export var defensive_block_ball_blend: float = 0.34
@export var possession_distance_advantage: float = 180.0
@export var defensive_cover_distance: float = 920.0
@export var defensive_cover_lateral_blend: float = 0.72
@export var own_goal_danger_radius: float = 1900.0
@export var emergency_clear_touch_force: float = 1450.0
@export var emergency_clear_touch_interval: float = 0.28
@export var emergency_clear_forward_distance: float = 2300.0
@export var emergency_clear_lateral_distance: float = 620.0

@export_category("Anticipatory Goal Defense")
@export var anticipatory_defense_maximum_goal_distance: float = 4100.0
@export var anticipatory_defense_ball_standoff: float = 520.0
@export var anticipatory_defense_keeper_depth: float = 360.0
@export var anticipatory_defense_goal_mouth_padding: float = 115.0
@export var anticipatory_defense_aim_flip_threshold: float = 250.0
@export var anticipatory_defense_fake_guard_seconds: float = 0.24
@export var anticipatory_defense_minimum_charge_read: float = 0.12
@export var anticipatory_defense_orbit_speed: float = 240.0
@export var anticipatory_defense_beaten_margin: float = 160.0
@export_range(0.0, 1.0, 0.01)
var anticipatory_defense_open_corner_weight: float = 0.24
@export_range(0.0, 1.0, 0.01)
var anticipatory_defense_center_weight: float = 0.34

@export_category("Pre-Shot Threat Reader")
@export var pre_shot_reader_enabled: bool = true
@export_range(0.0, 1.0, 0.01)
var pre_shot_reader_minimum_confidence: float = 0.58
@export_range(0.0, 1.0, 0.01)
var pre_shot_reader_emergency_risk: float = 0.72
@export_range(1, 6, 1)
var pre_shot_reader_maximum_bounces: int = 4
@export_range(0.0, 16.0, 0.5)
var pre_shot_reader_angle_uncertainty_degrees: float = 7.0
@export_range(0.0, 0.4, 0.01)
var pre_shot_reader_release_lead_seconds: float = 0.12
@export var pre_shot_reader_minimum_route_speed: float = 420.0
@export var pre_shot_reader_self_pass_gate_depth: float = 820.0
@export var pre_shot_reader_self_pass_lateral_margin: float = 230.0
@export_range(0.0, 1.0, 0.01)
var pre_shot_reader_route_blend: float = 0.92

@export_category("One Versus One Tactics")
@export var one_vs_one_keeper_danger_distance: float = 1450.0
@export var one_vs_one_counter_race_margin: float = 210.0
@export var one_vs_one_counter_window_seconds: float = 1.45
@export var one_vs_one_elastic_commit_seconds: float = 1.25
@export var one_vs_one_elastic_pressure_distance: float = 1050.0
@export var one_vs_one_power_opening_lane: float = 390.0
@export var one_vs_one_power_lateral_weight: float = 0.92
@export var one_vs_one_power_forward_weight: float = 0.46

@export_category("Local Duel / Solo Attack")
@export var local_duel_detection_radius: float = 1150.0
@export var local_duel_second_defender_margin: float = 460.0
@export var local_duel_maximum_ball_speed: float = 1800.0
@export var local_duel_commit_seconds: float = 1.35
@export var local_duel_direction_lock_seconds: float = 0.34
@export var local_duel_probe_distance: float = 900.0
@export_range(0.0, 1.0, 0.01)
var local_duel_minimum_dribble_chance: float = 0.62
@export_range(0.0, 1.0, 0.01)
var local_duel_pressure_chance_bonus: float = 0.28

@export_category("Duel Resolution / Loose Ball Recovery")
@export var duel_touch_window_seconds: float = 0.36
@export var duel_resolution_seconds: float = 0.82
@export var duel_contact_detection_radius: float = 620.0
@export var duel_prediction_horizon_seconds: float = 1.25
@export var duel_prediction_step_seconds: float = 0.08
@export var duel_equal_arrival_margin_seconds: float = 0.11
@export var duel_clear_loss_margin_seconds: float = 0.26
@export var duel_rechallenge_margin_seconds: float = 0.34
@export var duel_goal_side_standoff: float = 215.0
@export var duel_control_touch_force: float = 520.0
@export var duel_touch_retry_seconds: float = 0.18

@export_category("Shooting")
@export var minimum_shot_charge_seconds: float = 0.32
@export var maximum_shot_charge_seconds: float = 0.92
@export var power_strike_requires_full_charge: bool = true
@export var full_charge_goal_distance: float = 5200.0
@export var goalkeeper_clear_charge_seconds: float = 0.38
@export var required_shot_alignment: float = 0.7
@export var kick_distance_margin: float = 18.0
@export var committed_kick_contact_margin: float = 28.0
@export var committed_ball_follow_prediction_seconds: float = 0.10
@export var committed_ball_follow_speed_threshold: float = 90.0
@export_range(0.0, 1.0, 0.01)
var committed_ball_velocity_follow_strength: float = 0.42
@export var shot_aim_vertical_spread: float = 210.0
@export var shot_contact_reacquire_seconds: float = 0.38
@export_range(0.0, 1.0, 0.01)
var release_shot_alignment: float = 0.55
@export var shot_precharge_distance: float = 1350.0
@export var shot_precharge_cancel_distance: float = 1750.0
@export var shot_precharge_max_hold_seconds: float = 2.0
@export var committed_shot_executor_max_seconds: float = 1.45
@export var committed_shot_executor_delivery_max_seconds: float = 2.35
@export var committed_shot_recent_kick_grace_seconds: float = 0.10
@export_range(0.0, 1.0, 0.01)
var shot_precharge_alignment: float = 0.28
@export var shot_charge_opponent_control_margin: float = 170.0
# Generic attack plans should only start charging when contact is imminent.
# The larger shot_precharge_distance is reserved for a verified teammate
# delivery/first-touch plan, where charging early is actually intentional.
@export var generic_shot_precharge_contact_multiplier: float = 2.65
@export var generic_shot_precharge_max_arrival_seconds: float = 0.72
@export var charged_pass_release_minimum_lane: float = 105.0
@export var charged_pass_release_minimum_interception_margin: float = -0.04
@export var charged_pass_release_minimum_receiver_margin: float = -0.10

@export_category("Committed Possession Executors")
@export var committed_possession_executors_enabled: bool = true
@export var committed_get_ball_executor_max_seconds: float = 0.40
@export var committed_pass_executor_max_seconds: float = 1.65
@export var committed_attack_executor_max_seconds: float = 0.38
@export var committed_attack_ball_loss_distance: float = 1450.0

@export_category("Committed Defensive Role Executors")
@export var committed_role_executors_enabled: bool = true
@export var committed_defend_executor_max_seconds: float = 0.30
@export var committed_goalkeep_executor_max_seconds: float = 0.24
@export var committed_goalkeeper_max_field_depth: float = 2600.0
@export var committed_final_defender_goal_side_margin: float = 120.0

@export_category("Committed Ability Executor")
@export var committed_ability_executor_enabled: bool = true
@export var committed_ability_executor_max_seconds: float = 0.46
@export var committed_ability_instant_hold_seconds: float = 0.12
@export var committed_ability_movement_distance: float = 1050.0

@export_category("Action Reconsideration")
@export var committed_reconsideration_enabled: bool = true
@export var committed_support_reconsider_seconds: float = 0.20

@export_category("Shot Integrity")
@export var prevent_intentional_shot_misses: bool = true
@export var shot_integrity_goal_margin: float = 90.0
@export var shot_integrity_goal_plane_tolerance: float = 480.0

@export_category("Penalty Shootout")
@export var penalty_aim_post_margin: float = 90.0
@export_range(0.0, 1.0, 0.01)
var penalty_corner_bias: float = 0.82
@export var penalty_corner_band_width: float = 190.0
@export var penalty_goalkeeper_commit_distance: float = 120.0
@export_range(0.5, 1.0, 0.01)
var penalty_minimum_charge_ratio: float = 0.90
@export_range(0.0, 1.0, 0.01)
var penalty_goalkeeper_prediction: float = 0.32

@export_category("Playable Area")
@export var minimum_field_x: float = 360.0
@export var maximum_field_x: float = 6970.0
@export var minimum_field_y: float = 680.0
@export var maximum_field_y: float = 4320.0


var controlled_player: FootballPlayer
var match_manager
var ball: FootballBall

var _decision_accumulator: float = 0.0
var _next_decision_delay: float = 0.08
# Part 3 large-team tactical budget/event state. These values only gate the
# expensive high-level decision rebuild; mechanical execution remains 60 Hz.
var _large_team_tactical_budget_interval: float = 0.0
var _large_team_tactical_budget_tier: StringName = &""
var _large_team_last_global_event_serial: int = -1
var _large_team_last_peer_event_serial: int = -1
var _large_team_event_wake_pending: bool = false
var _large_team_event_wake_immediate: bool = false
var _large_team_last_wake_reason: StringName = &""
var _was_cpu_thinking: bool = false
var _movement_target: Vector2 = Vector2.ZERO
var _trained_ability_use_biases: Dictionary = {}
var _shot_target: Vector2 = Vector2.ZERO
var _next_creative_shot_at: float = 0.0
var _planned_destination: Vector2 = Vector2.ZERO
var _planned_route_distance: float = 0.0
var _plan_uses_wall: bool = false
var _plan_uses_double_bank: bool = false
var _double_bank_required_charge_seconds: float = 0.0
var _planned_receiver: FootballPlayer
var _plan_is_pass: bool = false
var _plan_expires_at: float = 0.0
var _desired_charge_seconds: float = 0.0
var _human_demo_plan: Dictionary = {}
var _human_demo_plan_started_at: float = 0.0
var _human_demo_action_index: int = 0
var _human_demo_last_fingerprint: String = ""
var _human_demo_reuse_block_until: float = 0.0
var _charge_elapsed: float = 0.0
var _shot_was_precharged: bool = false
var _charge_is_goalkeeper_clear: bool = false
var _stuck_elapsed: float = 0.0
var _stuck_recovery_remaining: float = 0.0
var _last_stuck_position: Vector2 = Vector2.ZERO
var _stuck_side: float = 1.0
var _possession_deadlock_elapsed: float = 0.0
var _possession_deadlock_anchor_ball: Vector2 = Vector2.ZERO
var _possession_deadlock_anchor_player: Vector2 = Vector2.ZERO
var _next_possession_deadlock_escape_at: float = 0.0
var _two_vs_two_outlet_follow_until: float = 0.0
var _two_vs_two_outlet_follow_target: Vector2 = Vector2.ZERO
var _large_team_cached_roster: Array[FootballPlayer] = []
var _large_team_cached_assignments: Dictionary = {}
var _large_team_cached_lane_offsets: Dictionary = {}
var _large_team_shape_cache_until: float = -INF
var _large_team_second_ball_cache_until: float = -INF
var _large_team_second_ball_cached_peer_id: int = 0
var _large_team_second_ball_cached_chaser_peer_id: int = -1
var _next_large_team_release_pass_scan_at: float = -INF
var _rng = RandomNumberGenerator.new()
var _hesitation_remaining: float = 0.0
var _perception_error: Vector2 = Vector2.ZERO
var _next_perception_refresh_at: float = 0.0
var _dribble_until: float = 0.0
var _next_dribble_touch_at: float = 0.0
var _next_emergency_clear_touch_at: float = 0.0
var _contest_yield_until: float = 0.0
var _next_contest_yield_allowed_at: float = 0.0
var _next_contest_escape_at: float = 0.0
var _next_ability_decision_at: float = 0.0
var _next_ability_improvisation_at: float = 0.0
var _opponent_ability_threat_cache: Dictionary = {}
var _opponent_ability_threat_cache_until: float = 0.0
var _last_ability_defense_role: StringName = &""
var _last_ability_defense_target: Vector2 = Vector2.ZERO
var _mirage_activate_after: float = 0.0
var _mirage_setup_target: FootballPlayer
var _wall_dribble_until: float = 0.0
var _wall_dribble_destination: Vector2 = Vector2.ZERO
var _wall_dribble_bounce: Vector2 = Vector2.ZERO
var _wall_dribble_kicked: bool = false
var _wall_dribble_start_position: Vector2 = Vector2.ZERO
var _wall_dribble_training_outcome_recorded: bool = false
var _one_vs_one_space_play_plan: Dictionary = {}
var _one_vs_one_space_play_until: float = 0.0
var _one_vs_one_space_play_next_allowed_at: float = 0.0
var _one_vs_one_space_play_kicked: bool = false
var _one_vs_one_space_play_last_side: float = 1.0
var _elite_finish_plan: Dictionary = {}
var _elite_forced_charge_ratio: float = -1.0
var _kickoff_strategy: StringName = &""
var _kickoff_strategy_started_at: float = -INF
var _kickoff_strategy_until: float = 0.0
var _kickoff_touch_completed: bool = false
var _kickoff_sequence_index: int = 0
var _kickoff_last_ball_centered: bool = false
var _kickoff_side: float = 1.0
var _goalkeeper_reach_target: Vector2 = Vector2.ZERO
var _enforcer_target: FootballPlayer
var _next_enforcer_kick_at: float = 0.0
var _planned_support_position: Vector2 = Vector2.ZERO
var _planned_support_until: float = 0.0
var _next_support_plan_at: float = 0.0
var _planned_support_intent: StringName = INTENT_IDLE
var _last_off_ball_role: StringName = &""
var _last_off_ball_reason: String = ""
var _last_off_ball_target: Vector2 = Vector2.ZERO
var _off_ball_team_had_possession: bool = false
var _off_ball_transition_recovery_until: float = 0.0
var _off_ball_transition_previous_role: StringName = &""
var _last_team_ball_actor_peer_id: int = 0
var _last_team_ball_actor_reason: String = ""
var _relative_loose_ball_claim_cache_frame: int = -1
var _relative_loose_ball_claim_cache: Dictionary = {}
var _active_team_count_cache_frame: int = -1
var _active_team_count_cache: int = 0
var _checkpoint_team_count_cache_frame: int = -1
var _checkpoint_team_count_cache: int = 0
var _overdrive_through_run_target: Vector2 = Vector2.ZERO
var _overdrive_through_run_until: float = 0.0
var _next_overdrive_through_run_at: float = 0.0
var _overdrive_breakaway_window_until: float = 0.0
var _overdrive_breakaway_finish_until: float = 0.0
var _overdrive_breakaway_target: Vector2 = Vector2.ZERO
var _burst_gap_close_target: Vector2 = Vector2.ZERO
var _burst_gap_close_until: float = 0.0
var _tactical_intent_action: StringName = INTENT_IDLE
var _tactical_intent_target: Vector2 = Vector2.ZERO
var _tactical_intent_peer_id: int = 0
# Cached pure-data plan produced by the shared 5v5/6v6 worker snapshot.
# It is consumed only on the main physics thread.
var _large_team_parallel_plan_frame: int = -1
var _large_team_parallel_plan: Dictionary = {}
var _committed_action: StringName = ACTION_NONE
var _committed_action_target: Vector2 = Vector2.ZERO
var _committed_action_target_peer_id: int = 0
var _committed_action_source_intent: StringName = INTENT_IDLE
var _committed_action_started_at: float = -INF
var _committed_action_minimum_until: float = -INF
var _committed_action_revision: int = 0
var _committed_action_last_interrupt_reason: String = ""
var _committed_action_last_interrupt_class: StringName = &""
var _committed_action_last_denied_interrupt_reason: String = ""
var _committed_action_last_denied_interrupt_class: StringName = &""
var _committed_action_last_reconsideration_reason: String = ""
var _shot_executor_active: bool = false
var _shot_executor_started_at: float = -INF
var _shot_executor_target: Vector2 = Vector2.ZERO
var _shot_executor_kick_time_at_start: float = -INF
var _shot_executor_last_result: String = ""
var _possession_executor_action: StringName = ACTION_NONE
var _possession_executor_started_at: float = -INF
var _possession_executor_target: Vector2 = Vector2.ZERO
var _possession_executor_route_target: Vector2 = Vector2.ZERO
var _possession_executor_route_distance: float = 0.0
var _possession_executor_target_peer_id: int = 0
var _possession_executor_kick_time_at_start: float = -INF
var _possession_executor_uses_wall: bool = false
var _possession_executor_uses_double_bank: bool = false
var _possession_executor_attack_direction: Vector2 = Vector2.ZERO
var _possession_executor_last_result: String = ""
var _role_executor_action: StringName = ACTION_NONE
var _role_executor_started_at: float = -INF
var _role_executor_target: Vector2 = Vector2.ZERO
var _role_executor_target_peer_id: int = 0
var _role_executor_source_intent: StringName = INTENT_IDLE
var _role_executor_defensive_role: StringName = &""
var _role_executor_kickoff_role: StringName = &""
var _role_executor_last_result: String = ""
var _ability_executor_active: bool = false
var _ability_executor_started_at: float = -INF
var _ability_executor_hold_until: float = -INF
var _ability_executor_ability_id: int = FootballPlayer.ABILITY_NONE
var _ability_executor_preparation_ability_id: int = FootballPlayer.ABILITY_NONE
var _ability_executor_target: Vector2 = Vector2.ZERO
var _ability_executor_movement_target: Vector2 = Vector2.ZERO
var _ability_executor_target_peer_id: int = 0
var _ability_executor_source_intent: StringName = INTENT_IDLE
var _ability_executor_direction: Vector2 = Vector2.ZERO
var _ability_executor_last_result: String = ""
var _next_pass_request_at: float = 0.0
var _fast_follow_up_finish_until: float = -INF
var _fast_follow_up_finish_target: Vector2 = Vector2.ZERO
var _penalty_attempt_serial: int = -1
var _penalty_shot_target: Vector2 = Vector2.ZERO
var _one_vs_one_counter_until: float = 0.0
var _solo_attack_until: float = 0.0
var _solo_attack_direction_lock_until: float = 0.0
var _solo_attack_direction: Vector2 = Vector2.ZERO
var _solo_attack_defender_peer_id: int = 0
var _neymar_elastic_direction: Vector2 = Vector2.ZERO
var _neymar_elastic_direction_until: float = 0.0
var _last_controlled_ball_touch_at: float = -INF
var _cpu_first_touch_plan: Dictionary = {}
var _cpu_first_touch_plan_until: float = 0.0
var _next_cpu_first_touch_at: float = 0.0
var _last_cpu_first_touch_mode: StringName = FIRST_TOUCH_NONE
var _last_opponent_ball_touch_at: float = -INF
var _last_opponent_ball_touch_peer_id: int = 0
var _duel_resolution_until: float = 0.0
var _duel_resolution_opponent_peer_id: int = 0
var _duel_resolution_outcome: StringName = &""
var _duel_resolution_target: Vector2 = Vector2.ZERO
var _next_duel_control_touch_at: float = 0.0
var _defense_read_carrier_peer_id: int = 0
var _defense_last_read_y: float = 0.0
var _defense_last_read_at: float = -INF
var _defense_last_aim_change_at: float = -INF
var _defense_fake_guard_until: float = 0.0
var _defense_contact_carrier_peer_id: int = 0
var _defense_last_contact_direction: Vector2 = Vector2.ZERO
var _defense_contact_direction_changed_at: float = -INF
var _double_bank_debug_overlay: Node2D
var _double_bank_debug_predicted_line: Line2D
var _double_bank_debug_actual_line: Line2D
var _double_bank_debug_bounce_markers: Line2D
var _double_bank_debug_label: Label
var _double_bank_debug_actual_points: PackedVector2Array = PackedVector2Array()
var _hybrid_tactical_adapter: HybridTacticalAdapter
var _hybrid_loaded_checkpoint_path: String = ""
var _next_hybrid_checkpoint_refresh_at: float = 0.0
var _hybrid_checkpoint_team_size: int = 0
var _team_play_planner
var _attacking_planner
var _attack_value_debug_state: Dictionary = {}
var _attack_value_plan_until: float = 0.0
var _next_value_attack_touch_at: float = 0.0
var _active_team_pass_plan: Dictionary = {}
var _active_team_pass_plan_until: float = 0.0
var _planned_pass_kind: StringName = &""
var _possession_action_lock_until: float = 0.0
var _possession_action_lock: StringName = &""
var _last_secure_recovery_at: float = -INF
var _last_team_sequence_plan_id: String = ""
var _last_team_sequence_action: StringName = &"none"
var _last_team_sequence_confidence: float = 0.0
var _team_sequence_commit_until: float = 0.0
var _resolved_cpu_personality: StringName = CPU_PERSONALITY_ADAPTIVE
var _opponent_style_samples: float = 0.0
var _opponent_wall_kicks: float = 0.0
var _opponent_forward_kicks: float = 0.0
var _opponent_control_kicks: float = 0.0
var _opponent_style_last_decay_at: float = 0.0
var _ai_v2_runtime: TheodoreRLV2RuntimeController
var _ai_v2_last_reason: String = "not_initialized"
var _ai_v2_last_action: Dictionary = {}


func setup(
	player: FootballPlayer,
	manager,
	match_ball: FootballBall
) -> void:
	controlled_player = player
	match_manager = manager
	ball = match_ball
	_last_stuck_position = (
		player.global_position if player != null else Vector2.ZERO
	)
	_rng.seed = int(player.owner_peer_id * 7919 + 104729)
	_resolve_cpu_personality()
	_next_decision_delay = _get_next_decision_delay()
	_next_pass_request_at = (
		_server_time_seconds() + _rng.randf_range(0.7, 1.6)
	)
	_team_play_planner = TeamPlayPlannerScript.new()
	_team_play_planner.setup(self)
	_attacking_planner = AttackingPlannerScript.new()
	_attacking_planner.setup(self)
	_ai_v2_runtime = RLV2RuntimeControllerScript.new()
	_initialize_hybrid_tactical_policy()
	# Roster completion is asynchronous, so retain the lightweight refresh.
	# Spread it by logical player ID to keep multiple CPUs from checking on the
	# same frame while the lobby finishes spawning.
	_next_hybrid_checkpoint_refresh_at = (
		_server_time_seconds()
		+ float(absi(int(player.owner_peer_id)) % 8) * 0.07
	)
	apply_training_profile(load_saved_training_profile())
	_initialize_large_team_tactical_budget_state()
	if (
		is_instance_valid(ball)
		and not ball.player_touch_registered.is_connected(
			_on_ball_player_touch_registered
		)
	):
		ball.player_touch_registered.connect(
			_on_ball_player_touch_registered
		)
	if (
		is_instance_valid(ball)
		and not ball.player_kicked.is_connected(_on_ball_player_kicked_for_personality)
	):
		ball.player_kicked.connect(_on_ball_player_kicked_for_personality)
	set_physics_process(true)


static func get_default_training_profile() -> Dictionary:
	var profile = {
		"dribble_choice_chance": 0.44,
		"advance_play_chance": 0.42,
		"coordinated_ability_play_chance": 0.3,
		"support_ball_lane_blend": 0.4,
		"pass_lead_seconds": 0.18,
		"cpu_receiver_forward_lead": 280.0,
		"minimum_forward_pass_progress": 560.0,
		"pass_lane_clearance": 235.0,
		"elite_pass_lookahead_weight": 0.72,
		"wall_dribble_choice_chance": 0.28,
		"creative_shot_chance": 0.24,
		"creative_wall_shot_chance": 0.18,
		"double_bank_shot_chance": 0.14,
		"double_bank_minimum_route_clearance": 210.0,
		"double_bank_minimum_scoring_speed": 180.0,
		"double_bank_value_advantage": 170.0,
		"ability_improvisation_chance": 0.24,
		"defensive_block_ball_blend": 0.34,
		"dynamic_cover_center_blend": 0.28,
		"dynamic_forward_width": 680.0,
		"shot_aim_vertical_spread": 210.0,
		"required_shot_alignment": 0.7,
		"release_shot_alignment": 0.55,
		"separation_strength": 0.75,
		"pass_pressure_radius": 720.0,
		"contested_ball_radius": 540.0,
		"contest_yield_seconds": 0.32,
		"contest_escape_choice_chance": 0.38,
		"ball_chaser_commitment_seconds": 0.72,
		"ball_chaser_takeover_ratio": 0.7,
		"support_distance_behind_ball": 850.0,
		"support_minimum_teammate_spacing": 430.0,
		"off_ball_run_behind_distance": 460.0,
		"off_ball_return_lane_depth": 520.0,
		"off_ball_return_lane_width": 720.0,
		"off_ball_cover_distance": 1050.0,
		"off_ball_rebound_goal_distance": 1280.0,
		"off_ball_transition_recovery_seconds": 1.15,
		"dynamic_forward_distance": 1050.0,
		"defensive_anchor_distance": 2050.0,
		"midfield_anchor_distance": 3150.0,
		"striker_anchor_distance": 4050.0,
		"goalkeeper_depth": 650.0,
		"goalkeeper_chase_distance": 1350.0
	}
	for ability_id in range(1, FootballPlayer.ABILITY_COUNT + 1):
		profile["ability_use_bias_%d" % ability_id] = 1.0
	return profile


static func get_training_parameter_ranges() -> Dictionary:
	var ranges = TRAINING_PARAMETER_RANGES.duplicate(true)
	for ability_id in range(1, FootballPlayer.ABILITY_COUNT + 1):
		ranges["ability_use_bias_%d" % ability_id] = Vector2(0.55, 1.8)
	return ranges


static func load_saved_training_profile() -> Dictionary:
	if not FileAccess.file_exists(TRAINED_PROFILE_PATH):
		return _apply_human_adaptive_overlay(get_default_training_profile())
	var file = FileAccess.open(TRAINED_PROFILE_PATH, FileAccess.READ)
	if file == null:
		return _apply_human_adaptive_overlay(get_default_training_profile())
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		return _apply_human_adaptive_overlay(get_default_training_profile())
	var document = parsed as Dictionary
	var parameters: Variant = document.get("parameters", document)
	if not (parameters is Dictionary):
		return _apply_human_adaptive_overlay(get_default_training_profile())
	var profile = get_default_training_profile()
	for parameter_name in get_training_parameter_ranges():
		if (parameters as Dictionary).has(parameter_name):
			profile[parameter_name] = float(
				(parameters as Dictionary)[parameter_name]
			)
	return _apply_human_adaptive_overlay(profile)


static func _apply_human_adaptive_overlay(profile: Dictionary) -> Dictionary:
	var result = profile.duplicate(true)
	var tree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return result
	var learner = tree.root.get_node_or_null("HumanLearningManager")
	if learner == null or not learner.has_method("get_adaptive_profile_overlay"):
		return result
	var overlay = learner.call("get_adaptive_profile_overlay") as Dictionary
	var learned_parameters = overlay.get("parameters", {}) as Dictionary
	var blend = clampf(float(overlay.get("blend", 0.0)), 0.0, 0.25)
	for parameter_variant in get_training_parameter_ranges().keys():
		var parameter_name = str(parameter_variant)
		if not learned_parameters.has(parameter_name):
			continue
		var limits: Vector2 = get_training_parameter_ranges()[parameter_name]
		result[parameter_name] = clampf(
			lerpf(
				float(result[parameter_name]),
				float(learned_parameters[parameter_name]),
				blend
			),
			limits.x,
			limits.y
		)
	return result


func apply_training_profile(profile: Dictionary) -> void:
	var ranges = get_training_parameter_ranges()
	for parameter_variant in ranges.keys():
		var parameter_name = str(parameter_variant)
		if not profile.has(parameter_name):
			continue
		var limits: Vector2 = ranges[parameter_name]
		var value = clampf(
			float(profile[parameter_name]),
			limits.x,
			limits.y
		)
		if parameter_name.begins_with("ability_use_bias_"):
			var ability_id = parameter_name.trim_prefix(
				"ability_use_bias_"
			).to_int()
			_trained_ability_use_biases[ability_id] = value
			continue
		set(
			parameter_name,
			value
		)
	var hybrid_document: Variant = profile.get("hybrid_policy", profile.get("__hybrid_policy", null))
	if hybrid_document is Dictionary:
		apply_hybrid_policy_document(hybrid_document as Dictionary)


func _resolve_hybrid_tactical_checkpoint_path() -> String:
	var checkpoint_candidates: Array[String] = []
	# Checkpoint selection describes the configured match, not whether controls
	# happen to be enabled on this exact frame. During every countdown all player
	# controls are disabled; using that transient state selected the 1v1 file and
	# then made every CPU synchronously reload the large team checkpoint after GO.
	var active_team_size: int = _get_checkpoint_team_player_count()
	if hybrid_team_size_checkpoints_enabled:
		match clampi(active_team_size, 1, 4):
			4:
				checkpoint_candidates.append(hybrid_4v4_checkpoint_path)
				checkpoint_candidates.append(PACKAGED_HYBRID_4V4_CHECKPOINT)
				checkpoint_candidates.append(hybrid_3v3_checkpoint_path)
				checkpoint_candidates.append(PACKAGED_HYBRID_3V3_CHECKPOINT)
				checkpoint_candidates.append(hybrid_2v2_checkpoint_path)
				checkpoint_candidates.append(PACKAGED_HYBRID_2V2_CHECKPOINT)
			3:
				checkpoint_candidates.append(hybrid_3v3_checkpoint_path)
				checkpoint_candidates.append(PACKAGED_HYBRID_3V3_CHECKPOINT)
				checkpoint_candidates.append(hybrid_2v2_checkpoint_path)
				checkpoint_candidates.append(PACKAGED_HYBRID_2V2_CHECKPOINT)
			2:
				checkpoint_candidates.append(hybrid_2v2_checkpoint_path)
				checkpoint_candidates.append(PACKAGED_HYBRID_2V2_CHECKPOINT)
	checkpoint_candidates.append(hybrid_tactical_checkpoint_path)
	checkpoint_candidates.append("user://hybrid_ai/1v1/active.json")
	checkpoint_candidates.append(PACKAGED_HYBRID_1V1_CHECKPOINT)
	checkpoint_candidates.append("res://training/hybrid_checkpoints/active.json")
	var seen: Dictionary = {}
	for checkpoint_path in checkpoint_candidates:
		if checkpoint_path.is_empty() or seen.has(checkpoint_path):
			continue
		seen[checkpoint_path] = true
		if FileAccess.file_exists(checkpoint_path):
			return checkpoint_path
	return "res://training/hybrid_checkpoints/active.json"


func _get_checkpoint_team_player_count() -> int:
	var physics_frame := int(Engine.get_physics_frames())
	if _checkpoint_team_count_cache_frame == physics_frame:
		return _checkpoint_team_count_cache
	_checkpoint_team_count_cache_frame = physics_frame
	var count: int = 0
	for teammate: FootballPlayer in _get_teammates():
		if (
			is_instance_valid(teammate)
			and teammate.team == controlled_player.team
		):
			count += 1
	_checkpoint_team_count_cache = count
	return count


func _initialize_hybrid_tactical_policy() -> void:
	_hybrid_checkpoint_team_size = _get_checkpoint_team_player_count()
	var checkpoint_path: String = _resolve_hybrid_tactical_checkpoint_path()
	_hybrid_loaded_checkpoint_path = checkpoint_path
	_hybrid_tactical_adapter = HybridTacticalAdapterScript.new()
	_hybrid_tactical_adapter.setup(
		self,
		checkpoint_path,
		hybrid_tactical_policy_enabled,
		hybrid_tactical_decision_interval,
		false
	)


func _refresh_hybrid_tactical_checkpoint_if_needed() -> void:
	if (
		match_manager == null
		or match_manager.cpu_training_mode
		or not hybrid_team_size_checkpoints_enabled
	):
		return
	var now: float = _server_time_seconds()
	if now < _next_hybrid_checkpoint_refresh_at:
		return
	_next_hybrid_checkpoint_refresh_at = now + 0.75
	var current_team_size: int = _get_checkpoint_team_player_count()
	if current_team_size == _hybrid_checkpoint_team_size:
		return
	_hybrid_checkpoint_team_size = current_team_size
	var checkpoint_path: String = _resolve_hybrid_tactical_checkpoint_path()
	if checkpoint_path == _hybrid_loaded_checkpoint_path:
		return
	_initialize_hybrid_tactical_policy()


func apply_hybrid_policy_document(document: Dictionary) -> bool:
	if _hybrid_tactical_adapter == null:
		_initialize_hybrid_tactical_policy()
	return _hybrid_tactical_adapter.apply_policy_document(document)


func get_hybrid_policy_document() -> Dictionary:
	if _hybrid_tactical_adapter == null:
		return {}
	return _hybrid_tactical_adapter.get_policy_document()


func get_hybrid_ai_debug_state() -> Dictionary:
	if _hybrid_tactical_adapter == null:
		return {
			"enabled": false,
			"last_error": "adapter_not_initialized"
		}
	var state = _hybrid_tactical_adapter.get_debug_state()
	var threat = _get_opponent_ability_threat_state()
	state["ability_threat"] = str(threat.get(
		"primary_threat",
		&"none"
	))
	state["ability_threat_score"] = float(threat.get(
		"primary_score",
		0.0
	))
	state["ability_threat_peer_id"] = int(threat.get(
		"primary_peer_id",
		0
	))
	state["ability_defense_role"] = str(_last_ability_defense_role)
	state["ability_plan_target"] = _last_ability_defense_target
	var sequence_plan = _get_shared_team_sequence_plan()
	state["team_sequence_action"] = str(sequence_plan.get("action", &"none"))
	state["team_sequence_confidence"] = float(
		sequence_plan.get("confidence", 0.0)
	)
	state["team_sequence_role"] = str(
		_get_shared_team_sequence_assignment().get("role", &"")
	)
	state["team_sequence_plan_id"] = str(sequence_plan.get("plan_id", ""))
	state["first_touch_mode"] = str(
		_cpu_first_touch_plan.get("mode", _last_cpu_first_touch_mode)
	)
	state["first_touch_target"] = _cpu_first_touch_plan.get(
		"target_position",
		Vector2.ZERO
	)
	state["off_ball_role"] = str(_last_off_ball_role)
	state["off_ball_reason"] = _last_off_ball_reason
	state["off_ball_target"] = _last_off_ball_target
	state["team_ball_actor_peer_id"] = _last_team_ball_actor_peer_id
	state["team_ball_actor_reason"] = _last_team_ball_actor_reason
	state["off_ball_recovery_remaining"] = maxf(
		0.0,
		_off_ball_transition_recovery_until - _server_time_seconds()
	)
	state["tactical_role"] = str(_get_tactical_role(controlled_player))
	state["cpu_personality"] = str(_resolved_cpu_personality)
	state["personality_strategy"] = str(_get_personality_strategy())
	state["personality_planning_depth"] = _get_personality_planning_depth()
	state["intelligence"] = get_effective_skill_level()
	state["elite_skill_extension"] = get_elite_skill_extension_ratio()
	state["champion_utilization"] = get_champion_utilization_ratio()
	state["legacy_skill_execution_errors_enabled"] = legacy_skill_execution_errors_enabled
	state["execution_authority_committed"] = _has_committed_execution_authority()
	state["opponent_style"] = _get_observed_opponent_style()
	state["attack_intent"] = str(_attack_value_debug_state.get("action", &"none"))
	state["attack_target"] = _attack_value_debug_state.get("target", Vector2.ZERO)
	state["attack_destination"] = _attack_value_debug_state.get("destination", Vector2.ZERO)
	state["shot_quality"] = float(_attack_value_debug_state.get("shot_quality", 0.0))
	state["pass_quality"] = float(_attack_value_debug_state.get("pass_quality", 0.0))
	state["attack_pressure"] = float(_attack_value_debug_state.get("pressure", 0.0))
	state["wall_self_pass_active"] = _wall_dribble_until > _server_time_seconds()
	state["wall_self_pass_kicked"] = _wall_dribble_kicked
	state["wall_self_pass_destination"] = _wall_dribble_destination
	state["attack_reason"] = str(_attack_value_debug_state.get("reason", ""))
	state["attack_rejected"] = _attack_value_debug_state.get("rejected", PackedStringArray())
	state["attack_candidate_scores"] = _attack_value_debug_state.get("candidate_scores", {})
	state["ai_v2_runtime_enabled"] = (
		_ai_v2_runtime != null and _ai_v2_runtime.enabled
	)
	state["ai_v2_runtime_reason"] = _ai_v2_last_reason
	state["ai_v2_runtime_action"] = _ai_v2_last_action.duplicate(true)
	return state


func set_hybrid_training_mode(
	enabled: bool,
	exploration_override: float = -1.0
) -> void:
	if _hybrid_tactical_adapter == null:
		_initialize_hybrid_tactical_policy()
	_hybrid_tactical_adapter.set_training_mode(
		enabled,
		exploration_override
	)


func reset_hybrid_episode() -> void:
	if _hybrid_tactical_adapter != null:
		_hybrid_tactical_adapter.reset_episode()
	if _team_play_planner != null:
		_team_play_planner.reset()
	_clear_active_team_pass_plan()
	_clear_one_vs_one_space_play_state()
	_clear_elite_finish_plan()
	_clear_kickoff_strategy()
	_clear_cpu_first_touch_plan()
	_last_off_ball_role = &""
	_last_off_ball_reason = ""
	_last_off_ball_target = Vector2.ZERO
	_off_ball_team_had_possession = false
	_off_ball_transition_recovery_until = 0.0
	_off_ball_transition_previous_role = &""
	_last_team_ball_actor_peer_id = 0
	_last_team_ball_actor_reason = ""
	_possession_action_lock_until = 0.0
	_possession_action_lock = &""
	_abort_committed_shot_executor("episode_reset", true)
	_abort_committed_possession_executor("episode_reset", true)
	_abort_committed_role_executor("episode_reset")
	_abort_committed_ability_executor("episode_reset")
	_interrupt_action_commitment("episode_reset")
	_last_secure_recovery_at = -INF
	_large_team_shape_cache_until = -INF
	_large_team_cached_roster.clear()
	_large_team_cached_assignments.clear()
	_large_team_cached_lane_offsets.clear()
	_large_team_second_ball_cache_until = -INF
	_large_team_second_ball_cached_peer_id = 0
	_large_team_second_ball_cached_chaser_peer_id = -1
	_next_large_team_release_pass_scan_at = -INF
	_attack_value_debug_state.clear()
	_attack_value_plan_until = 0.0
	_next_value_attack_touch_at = 0.0
	if _ai_v2_runtime != null:
		_ai_v2_runtime.reset_agent(controlled_player)
	_ai_v2_last_reason = "episode_reset"
	_ai_v2_last_action.clear()


func _physics_process(delta: float) -> void:
	var kickoff_profile_enabled: bool = (
		OS.is_debug_build()
		and is_instance_valid(match_manager)
		and match_manager.has_method("is_kickoff_profile_active")
		and bool(match_manager.call("is_kickoff_profile_active"))
	)
	var runtime_profile_enabled: bool = (
		OS.is_debug_build()
		and is_instance_valid(match_manager)
		and match_manager.has_method("is_runtime_spike_profile_active")
		and bool(match_manager.call("is_runtime_spike_profile_active"))
	)
	var profile_enabled: bool = (
		kickoff_profile_enabled or runtime_profile_enabled
	)
	var profile_total_started_usec: int = (
		Time.get_ticks_usec() if profile_enabled else 0
	)
	var profile_stage_started_usec: int = profile_total_started_usec
	_record_double_bank_debug_trajectory()
	_refresh_hybrid_tactical_checkpoint_if_needed()
	_record_kickoff_profile_stage(
		profile_enabled,
		&"checkpoint_and_debug",
		profile_stage_started_usec
	)
	var can_think_now: bool = _can_think()
	if not can_think_now:
		_was_cpu_thinking = false
		_reset_possession_deadlock_watch()
		_stop_cpu_input()
		_record_cpu_profile_total(
			profile_enabled,
			profile_total_started_usec
		)
		return
	if not _was_cpu_thinking:
		_was_cpu_thinking = true
		_prime_cpu_decision_phase()
	profile_stage_started_usec = Time.get_ticks_usec()
	_update_cpu_first_touch_awareness()
	_record_kickoff_profile_stage(
		profile_enabled,
		&"first_touch_awareness",
		profile_stage_started_usec
	)
	profile_stage_started_usec = (
		Time.get_ticks_usec() if profile_enabled else 0
	)
	var handled_first_touch: bool = _update_cpu_first_touch_execution()
	_record_kickoff_profile_stage(
		profile_enabled,
		&"first_touch_execution",
		profile_stage_started_usec
	)
	if handled_first_touch:
		_apply_movement_input(delta)
		_record_cpu_profile_total(
			profile_enabled,
			profile_total_started_usec
		)
		return
	_update_possession_deadlock_watch(delta)
	if (
		not legacy_skill_execution_errors_enabled
		or _has_committed_execution_authority()
		or _uses_perfect_execution()
		or _has_active_meta_vision()
		or not _cpu_first_touch_plan.is_empty()
	):
		_hesitation_remaining = 0.0
	else:
		_hesitation_remaining = maxf(
			0.0,
			_hesitation_remaining - delta
		)
		if _hesitation_remaining > 0.0 and _has_obvious_play():
			_hesitation_remaining = 0.0
	if _hesitation_remaining > 0.0:
		controlled_player.server_direction = Vector2.ZERO
		_record_cpu_profile_total(
			profile_enabled,
			profile_total_started_usec
		)
		return

	var charge_was_active: bool = controlled_player.server_is_charging
	_update_charge(delta)
	# Shoot -> Pass is one continuous mechanical sequence. Once the first kick
	# has queued the follow-up, let that continuation run before generic action
	# executors can claim the next frame. Parts 2-7 made those executors more
	# authoritative, which was correct, but it also made the existing elite
	# kick-pass technique unnecessarily rare whenever the immediate same-frame
	# soft pass missed contact and needed its short recovery window.
	if _update_fast_follow_up_finish():
		_apply_movement_input(delta)
		_record_cpu_profile_total(
			profile_enabled,
			profile_total_started_usec
		)
		return
	if _update_committed_ability_executor(delta):
		_apply_movement_input(delta)
		_record_cpu_profile_total(
			profile_enabled,
			profile_total_started_usec
		)
		return
	if _update_committed_shot_executor(delta, charge_was_active):
		_apply_movement_input(delta)
		_record_cpu_profile_total(
			profile_enabled,
			profile_total_started_usec
		)
		return
	if _update_committed_possession_executor(delta, charge_was_active):
		_apply_movement_input(delta)
		_record_cpu_profile_total(
			profile_enabled,
			profile_total_started_usec
		)
		return
	if _update_committed_role_executor(delta):
		_apply_movement_input(delta)
		_record_cpu_profile_total(
			profile_enabled,
			profile_total_started_usec
		)
		return
	# High-value attacking ability windows disappear much faster than a normal
	# tactical decision cycle. Give Power Strike / Curve Shot a tiny reflex layer
	# every physics tick so a ready carrier does not spend another half-second
	# dribbling while the defense closes the lane.
	if _update_high_tempo_attack_reflex():
		_apply_movement_input(delta)
		_record_cpu_profile_total(
			profile_enabled,
			profile_total_started_usec
		)
		return
	_refresh_large_team_tactical_budget_and_events()
	_decision_accumulator += delta
	if _decision_accumulator >= _next_decision_delay:
		var tactical_phase_open := (
			_large_team_event_wake_immediate
			or _large_team_tactical_decision_phase_is_open()
		)
		if (
			_should_defer_tactical_reconsideration()
			or not tactical_phase_open
		):
			# Keep the evaluator ready to run on the first safe frame. Short action
			# commitments still have priority, and 5v5/6v6 deliberately phase full
			# replans so ten or twelve brains cannot spike one physics tick together.
			_decision_accumulator = _next_decision_delay
		else:
			_decision_accumulator = 0.0
			_next_decision_delay = _get_next_decision_delay()
			if (
				not _uses_perfect_execution()
				and _roll_human_mistake()
			):
				_record_cpu_profile_total(
					profile_enabled,
					profile_total_started_usec
				)
				return
			profile_stage_started_usec = Time.get_ticks_usec()
			_update_decision()
			_large_team_event_wake_pending = false
			_large_team_event_wake_immediate = false
			_record_kickoff_profile_stage(
				profile_enabled,
				&"decision",
				profile_stage_started_usec
			)

	profile_stage_started_usec = Time.get_ticks_usec()
	_apply_cpu_first_touch_movement_override()
	_apply_movement_input(delta)
	_record_kickoff_profile_stage(
		profile_enabled,
		&"movement",
		profile_stage_started_usec
	)
	_record_cpu_profile_total(
		profile_enabled,
		profile_total_started_usec
	)


func _record_kickoff_profile_stage(
	enabled: bool,
	stage: StringName,
	started_usec: int
) -> void:
	if not enabled or not is_instance_valid(match_manager):
		return
	var elapsed_usec: int = Time.get_ticks_usec() - started_usec
	match_manager.call(
		"record_kickoff_cpu_profile",
		stage,
		elapsed_usec
	)
	if match_manager.has_method("record_runtime_cpu_profile"):
		match_manager.call(
			"record_runtime_cpu_profile",
			controlled_player.owner_peer_id,
			stage,
			elapsed_usec
		)


func _record_cpu_profile_total(
	enabled: bool,
	started_usec: int
) -> void:
	if (
		not enabled
		or started_usec <= 0
		or not is_instance_valid(match_manager)
		or not match_manager.has_method("record_runtime_cpu_profile")
	):
		return
	match_manager.call(
		"record_runtime_cpu_profile",
		controlled_player.owner_peer_id,
		&"total",
		Time.get_ticks_usec() - started_usec
	)


func begin_runtime_subsystem_profile() -> int:
	if (
		OS.is_debug_build()
		and is_instance_valid(match_manager)
		and match_manager.has_method("is_runtime_spike_profile_active")
		and bool(match_manager.call("is_runtime_spike_profile_active"))
	):
		return Time.get_ticks_usec()
	return 0


func end_runtime_subsystem_profile(
	stage: StringName,
	started_usec: int
) -> void:
	if (
		started_usec <= 0
		or not is_instance_valid(match_manager)
		or not match_manager.has_method("record_runtime_cpu_profile")
	):
		return
	match_manager.call(
		"record_runtime_cpu_profile",
		controlled_player.owner_peer_id,
		stage,
		Time.get_ticks_usec() - started_usec
	)


func _get_large_team_tactical_budget() -> Dictionary:
	if (
		not is_instance_valid(controlled_player)
		or not is_instance_valid(match_manager)
		or not match_manager.has_method("get_cpu_tactical_update_budget")
	):
		return {}
	return match_manager.call(
		"get_cpu_tactical_update_budget",
		controlled_player.owner_peer_id,
		controlled_player.team
	) as Dictionary


func _initialize_large_team_tactical_budget_state() -> void:
	_large_team_tactical_budget_interval = 0.0
	_large_team_tactical_budget_tier = &""
	_large_team_event_wake_pending = false
	_large_team_event_wake_immediate = false
	_large_team_last_wake_reason = &""
	var budget := _get_large_team_tactical_budget()
	if budget.is_empty():
		# MatchManager event serials start at zero. Controllers are often attached
		# before a 5v5/6v6 roster is complete, so retain that zero baseline; a real
		# event that happens before the first large-team budget query must still wake
		# the affected CPU instead of being swallowed as initialization.
		_large_team_last_global_event_serial = 0
		_large_team_last_peer_event_serial = 0
		return
	_large_team_tactical_budget_interval = maxf(0.0, float(budget.get("interval", 0.0)))
	_large_team_tactical_budget_tier = StringName(budget.get("tier", &""))
	_large_team_last_global_event_serial = int(budget.get("global_event_serial", 0))
	_large_team_last_peer_event_serial = int(budget.get("peer_event_serial", 0))


func _refresh_large_team_tactical_budget_and_events() -> void:
	var budget := _get_large_team_tactical_budget()
	if budget.is_empty():
		_large_team_tactical_budget_interval = 0.0
		_large_team_tactical_budget_tier = &""
		_large_team_event_wake_pending = false
		_large_team_event_wake_immediate = false
		return
	_large_team_tactical_budget_interval = maxf(0.0, float(budget.get("interval", 0.0)))
	_large_team_tactical_budget_tier = StringName(budget.get("tier", &""))
	var global_serial := int(budget.get("global_event_serial", 0))
	var peer_serial := int(budget.get("peer_event_serial", 0))
	# The first observed state establishes the baseline instead of forcing all
	# twelve CPUs to replan together on their first playable physics tick.
	if _large_team_last_global_event_serial < 0:
		_large_team_last_global_event_serial = 0
	if _large_team_last_peer_event_serial < 0:
		_large_team_last_peer_event_serial = 0
	var global_wake := global_serial != _large_team_last_global_event_serial
	var peer_wake := peer_serial != _large_team_last_peer_event_serial
	if not global_wake and not peer_wake:
		return
	_large_team_last_global_event_serial = global_serial
	_large_team_last_peer_event_serial = peer_serial
	_large_team_event_wake_pending = true
	_large_team_event_wake_immediate = bool(budget.get("critical", false))
	_large_team_last_wake_reason = StringName(
		budget.get(
			"peer_event_reason" if peer_wake else "global_event_reason",
			&"world_event"
		)
	)
	# Arm a new high-level decision immediately. Non-critical players still obey
	# the 5v5/6v6 phase staggering; the current ball actor/receiver/keeper can
	# bypass that phase once so urgent events do not feel sluggish.
	_decision_accumulator = maxf(_decision_accumulator, _next_decision_delay)


func get_large_team_tactical_budget_debug_state() -> Dictionary:
	return {
		"tier": _large_team_tactical_budget_tier,
		"interval": _large_team_tactical_budget_interval,
		"wake_pending": _large_team_event_wake_pending,
		"wake_immediate": _large_team_event_wake_immediate,
		"wake_reason": _large_team_last_wake_reason,
		"global_event_serial": _large_team_last_global_event_serial,
		"peer_event_serial": _large_team_last_peer_event_serial,
	}


func _large_team_tactical_decision_phase_is_open() -> bool:
	if not is_instance_valid(controlled_player) or not is_instance_valid(match_manager):
		return true
	var active_team_size: int = _get_active_team_player_count()
	if active_team_size < 5:
		return true
	var phase_count: int = FIVE_PLUS_TACTICAL_DECISION_PHASES
	var slot_index: int = controlled_player.team_slot
	if slot_index < 0:
		slot_index = abs(controlled_player.owner_peer_id)
	var team_phase: int = 0 if controlled_player.team == TEAM_BLUE else 1
	# Multiplying by two keeps consecutive slots apart while the team offset
	# interleaves the opposing side. In 6v6 this yields exactly four possible
	# full replans per physics frame instead of twelve.
	var assigned_phase: int = (slot_index * 2 + team_phase) % phase_count
	return int(Engine.get_physics_frames() % phase_count) == assigned_phase


func _prime_cpu_decision_phase() -> void:
	# Elite CPUs intentionally keep the same reaction interval, but they must not
	# all execute their expensive tactical update on the exact same physics frame.
	# 4v4 previously woke eight brains together after GO, causing a short CPU spike.
	_next_decision_delay = _get_next_decision_delay()
	var slot_index: int = maxi(0, controlled_player.team_slot)
	var team_phase: int = 0 if controlled_player.team == TEAM_BLUE else 1
	var phase_index: int = (slot_index * 2 + team_phase) % 8
	var phase_fraction: float = float(phase_index) / 8.0
	_decision_accumulator = _next_decision_delay * phase_fraction


func _update_possession_deadlock_watch(delta: float) -> void:
	if (
		not _team_likely_has_possession()
		or not controlled_player.cpu_has_kickable_ball()
		or _get_likely_team_ball_carrier() != controlled_player
		or controlled_player.server_is_charging
	):
		_reset_possession_deadlock_watch()
		return
	if _possession_deadlock_anchor_ball.is_zero_approx():
		_possession_deadlock_anchor_ball = ball.global_position
		_possession_deadlock_anchor_player = controlled_player.global_position
		_possession_deadlock_elapsed = 0.0
		return
	var forward_progress = (
		ball.global_position.x - _possession_deadlock_anchor_ball.x
	) * _get_attack_sign()
	var player_forward_progress = (
		controlled_player.global_position.x
		- _possession_deadlock_anchor_player.x
	) * _get_attack_sign()
	var meaningful_action = (
		forward_progress >= maxf(20.0, possession_deadlock_forward_progress)
		or player_forward_progress
		>= maxf(40.0, possession_deadlock_forward_progress * 1.15)
		or ball.linear_velocity.length() >= 520.0
	)
	if meaningful_action:
		_possession_deadlock_anchor_ball = ball.global_position
		_possession_deadlock_anchor_player = controlled_player.global_position
		_possession_deadlock_elapsed = 0.0
		return
	_possession_deadlock_elapsed += maxf(0.0, delta)


func _reset_possession_deadlock_watch() -> void:
	_possession_deadlock_elapsed = 0.0
	_possession_deadlock_anchor_ball = Vector2.ZERO
	_possession_deadlock_anchor_player = Vector2.ZERO


func _possession_deadlock_is_ready() -> bool:
	return (
		_possession_deadlock_elapsed
		>= maxf(0.35, possession_deadlock_seconds)
		and _server_time_seconds() >= _next_possession_deadlock_escape_at
	)


func _can_think() -> bool:
	return (
		multiplayer.is_server()
		and is_instance_valid(controlled_player)
		and controlled_player.cpu_controlled
		and controlled_player.controls_enabled
		and is_instance_valid(match_manager)
		and match_manager.game_has_started
		and not match_manager.round_resetting
		and not match_manager.freeplay_active
		and is_instance_valid(ball)
		and controlled_player.team in [
			TEAM_BLUE,
			TEAM_RED
		]
	)


func _stop_cpu_input() -> void:
	if not is_instance_valid(controlled_player):
		return
	controlled_player.server_direction = Vector2.ZERO
	_reset_cpu_charge_tracking()
	_clear_duel_resolution_state()
	_clear_defensive_shot_read()
	_clear_cpu_first_touch_plan()
	_possession_action_lock_until = 0.0
	_possession_action_lock = &""
	_abort_committed_shot_executor("cpu_input_stopped", false)
	_abort_committed_possession_executor("cpu_input_stopped", false)
	_abort_committed_role_executor("cpu_input_stopped")
	_abort_committed_ability_executor("cpu_input_stopped")
	_interrupt_action_commitment("cpu_input_stopped")


func _set_tactical_intent(
	action: StringName,
	target: Vector2,
	target_peer_id: int = 0
) -> void:
	_tactical_intent_action = action
	_tactical_intent_target = target
	_tactical_intent_peer_id = target_peer_id


func _publish_tactical_intent() -> void:
	# While an ability is the chosen high-level action, keep publishing the
	# underlying football intent for teammate awareness, but do not let that
	# intent claim a second executor on the same frame.
	if not _ability_executor_active:
		_sync_action_commitment_from_tactical_intent()
		if _tactical_intent_action == INTENT_SHOOT:
			_try_claim_committed_shot_executor()
		elif _tactical_intent_action in [INTENT_CHASE, INTENT_PASS, INTENT_DRIBBLE]:
			_try_claim_committed_possession_executor()
		_try_claim_committed_role_executor()
	match_manager.set_cpu_tactical_intention(
		controlled_player.owner_peer_id,
		controlled_player.team,
		_tactical_intent_action,
		_tactical_intent_target,
		_tactical_intent_peer_id
	)


func _sync_action_commitment_from_tactical_intent() -> void:
	var action := _get_high_level_action_for_tactical_intent(
		_tactical_intent_action
	)
	if action == ACTION_NONE:
		return
	_begin_action_commitment(
		action,
		_tactical_intent_target,
		_tactical_intent_peer_id,
		_get_action_commitment_minimum_seconds(action),
		_tactical_intent_action
	)


func _kickoff_role_is_live() -> bool:
	# Preserve the pure commitment mapping used by isolated tests/tools: an
	# already-active kickoff strategy is enough to identify KICKOFF even before
	# a live player/ball scene has been wired into this controller.
	if (
		_kickoff_strategy != &""
		and _server_time_seconds() <= _kickoff_strategy_until
	):
		return true
	if (
		not kickoff_strategy_enabled
		or not is_instance_valid(ball)
		or not is_instance_valid(controlled_player)
		or (
			is_instance_valid(match_manager)
			and match_manager.penalty_shootout_active
		)
	):
		return false
	if not _is_kickoff_ball_state():
		return false
	if _get_active_team_player_count() <= 1:
		return true
	return _get_locked_kickoff_role() != &""


func _has_committed_execution_authority() -> bool:
	return (
		_ability_executor_active
		or _shot_executor_active
		or _possession_executor_action != ACTION_NONE
		or _role_executor_action != ACTION_NONE
	)


func _get_high_level_action_for_tactical_intent(
	intent: StringName
) -> StringName:
	if _kickoff_role_is_live():
		return ACTION_KICKOFF
	match intent:
		INTENT_CHASE:
			# Chasing a loose ball is GET_BALL. Pressing an opponent who actually
			# controls it is DEFEND, so the possession executor and defensive role
			# executor never fight over the same movement frame. Keep the pure intent
			# mapping safe for isolated tests/controllers that have not been setup yet.
			var live_defensive_press := (
				is_instance_valid(controlled_player)
				and is_instance_valid(ball)
				and is_instance_valid(match_manager)
				and _opponent_has_live_ball_control()
			)
			return ACTION_DEFEND if live_defensive_press else ACTION_GET_BALL
		INTENT_DRIBBLE:
			return ACTION_ATTACK
		INTENT_PASS:
			return ACTION_PASS
		INTENT_SHOOT:
			return ACTION_SHOOT
		INTENT_RECEIVE, INTENT_FORWARD_RUN, INTENT_WIDE_SUPPORT:
			return ACTION_SUPPORT
		INTENT_COVER, INTENT_MARK, INTENT_ENFORCE:
			return ACTION_DEFEND
		INTENT_GOALKEEP:
			return ACTION_GOALKEEP
	return ACTION_NONE


func _get_action_commitment_minimum_seconds(action: StringName) -> float:
	match action:
		ACTION_GET_BALL, ACTION_ATTACK, ACTION_SHOOT, ACTION_PASS:
			return ACTION_COMMITMENT_BALL_SECONDS
		ACTION_SUPPORT:
			return maxf(ACTION_COMMITMENT_DEFAULT_SECONDS, committed_support_reconsider_seconds)
		ACTION_DEFEND:
			return minf(0.22, maxf(0.12, committed_defend_executor_max_seconds))
		ACTION_GOALKEEP:
			return minf(0.20, maxf(0.12, committed_goalkeep_executor_max_seconds))
		ACTION_KICKOFF:
			return ACTION_COMMITMENT_KICKOFF_SECONDS
		ACTION_ABILITY:
			return maxf(0.08, committed_ability_instant_hold_seconds)
	return ACTION_COMMITMENT_DEFAULT_SECONDS


func _begin_action_commitment(
	action: StringName,
	target: Vector2,
	target_peer_id: int = 0,
	minimum_seconds: float = -1.0,
	source_intent: StringName = INTENT_IDLE
) -> void:
	if action == ACTION_NONE:
		return
	if _ability_executor_active and action != ACTION_ABILITY:
		return
	if _shot_executor_active and action != ACTION_SHOOT:
		return
	if (
		_possession_executor_action != ACTION_NONE
		and action != _possession_executor_action
	):
		return
	if (
		_role_executor_action != ACTION_NONE
		and action != _role_executor_action
	):
		return
	var same_action := (
		_committed_action == action
		and _committed_action_target_peer_id == target_peer_id
	)
	if same_action:
		_committed_action_target = target
		_committed_action_source_intent = source_intent
		return
	var now := _server_time_seconds()
	var duration := minimum_seconds
	if duration < 0.0:
		duration = _get_action_commitment_minimum_seconds(action)
	_committed_action = action
	_committed_action_target = target
	_committed_action_target_peer_id = target_peer_id
	_committed_action_source_intent = source_intent
	_committed_action_started_at = now
	_committed_action_minimum_until = now + maxf(0.0, duration)
	_committed_action_revision += 1


func _interrupt_action_commitment(reason: String) -> void:
	if _committed_action == ACTION_NONE:
		return
	_committed_action_last_interrupt_reason = reason
	_committed_action_last_interrupt_class = _classify_action_interrupt_reason(reason)
	_committed_action = ACTION_NONE
	_committed_action_target = Vector2.ZERO
	_committed_action_target_peer_id = 0
	_committed_action_source_intent = INTENT_IDLE
	_committed_action_started_at = -INF
	_committed_action_minimum_until = -INF
	_committed_action_revision += 1


func _action_commitment_minimum_is_active() -> bool:
	return (
		_committed_action != ACTION_NONE
		and _server_time_seconds() < _committed_action_minimum_until
	)


func _classify_action_interrupt_reason(reason: String) -> StringName:
	# Only genuinely meaningful world-state changes are allowed to break a
	# commitment immediately. Ordinary "maybe there is a slightly better plan"
	# reconsideration waits until the current action has had its minimum window.
	match reason:
		"episode_reset", "cpu_input_stopped", \
		"ability_activation_failed", "ability_executor_invalid_state", \
		"ability_executor_missing_ability", \
		"shot_executor_invalid_state", "shot_charge_cancelled", \
		"shot_ball_stolen", "shot_ball_unreachable", "shot_lane_blocked", \
		"possession_executor_invalid_state", "unsupported_possession_executor", \
		"get_ball_opponent_control", "get_ball_kickoff", \
		"get_ball_goal_emergency", "get_ball_actor_changed", \
		"pass_charge_cancelled", "pass_ball_stolen", \
		"pass_receiver_unavailable", "pass_route_invalidated", \
		"attack_ball_stolen", "attack_goal_emergency", \
		"attack_actor_changed", "attack_ball_lost", \
		"role_executor_invalid_state", "unsupported_role_executor", \
		"defense_assignment_missing", "defense_became_goalkeeper", \
		"defense_role_changed", "defense_target_missing", \
		"goalkeeper_role_lost", "kickoff_role_changed":
			return ACTION_INTERRUPT_IMMEDIATE
	return ACTION_INTERRUPT_RECONSIDER


func _action_interrupt_is_allowed(reason: String, force: bool = false) -> bool:
	var interrupt_class := _classify_action_interrupt_reason(reason)
	if (
		force
		or not committed_reconsideration_enabled
		or _committed_action == ACTION_NONE
		or interrupt_class == ACTION_INTERRUPT_IMMEDIATE
		or not _action_commitment_minimum_is_active()
	):
		return true
	_committed_action_last_denied_interrupt_reason = reason
	_committed_action_last_denied_interrupt_class = interrupt_class
	return false


func _arm_tactical_reconsideration(reason: String) -> void:
	_committed_action_last_reconsideration_reason = reason
	_decision_accumulator = maxf(_decision_accumulator, _next_decision_delay)


func _has_immediate_tactical_reconsideration_trigger() -> bool:
	if (
		_committed_action == ACTION_NONE
		or not is_instance_valid(controlled_player)
		or not is_instance_valid(ball)
		or not is_instance_valid(match_manager)
	):
		return false
	if not controlled_player.controls_enabled:
		return true
	var kickoff_live := _kickoff_role_is_live()
	if kickoff_live != (_committed_action == ACTION_KICKOFF):
		return true
	if (
		_ball_is_in_own_goal_danger()
		and _committed_action not in [ACTION_DEFEND, ACTION_GOALKEEP, ACTION_KICKOFF]
	):
		return true
	if (
		_opponent_has_live_ball_control()
		and _committed_action in [ACTION_ATTACK, ACTION_PASS, ACTION_SHOOT, ACTION_SUPPORT]
	):
		return true
	if (
		controlled_player.cpu_has_kickable_ball()
		and _committed_action in [ACTION_GET_BALL, ACTION_SUPPORT]
	):
		return true
	if (
		_team_likely_has_possession()
		and _committed_action == ACTION_DEFEND
		and not _ball_is_in_own_goal_danger()
	):
		return true
	return false


func _tactical_reconsideration_is_locked() -> bool:
	return (
		committed_reconsideration_enabled
		and _committed_action != ACTION_NONE
		and _action_commitment_minimum_is_active()
		and not _has_immediate_tactical_reconsideration_trigger()
	)


func _should_defer_tactical_reconsideration() -> bool:
	if not _tactical_reconsideration_is_locked():
		if (
			committed_reconsideration_enabled
			and _committed_action != ACTION_NONE
			and _action_commitment_minimum_is_active()
			and _has_immediate_tactical_reconsideration_trigger()
		):
			_committed_action_last_reconsideration_reason = "immediate_world_state_change"
		return false
	_committed_action_last_denied_interrupt_reason = "tactical_reconsideration"
	_committed_action_last_denied_interrupt_class = ACTION_INTERRUPT_RECONSIDER
	return true


func get_action_commitment_debug_state() -> Dictionary:
	var now := _server_time_seconds()
	return {
		"action": str(_committed_action),
		"target": _committed_action_target,
		"target_peer_id": _committed_action_target_peer_id,
		"source_intent": str(_committed_action_source_intent),
		"started_at": _committed_action_started_at,
		"minimum_until": _committed_action_minimum_until,
		"minimum_remaining": maxf(
			0.0,
			_committed_action_minimum_until - now
		),
		"minimum_active": _action_commitment_minimum_is_active(),
		"revision": _committed_action_revision,
		"last_interrupt_reason": _committed_action_last_interrupt_reason,
		"last_interrupt_class": str(_committed_action_last_interrupt_class),
		"last_denied_interrupt_reason": _committed_action_last_denied_interrupt_reason,
		"last_denied_interrupt_class": str(_committed_action_last_denied_interrupt_class),
		"last_reconsideration_reason": _committed_action_last_reconsideration_reason,
		"reconsideration_locked": _tactical_reconsideration_is_locked(),
		"execution_authority": _get_execution_authority_name(),
		"ability_executor_active": _ability_executor_active,
		"ability_executor_ability_id": _ability_executor_ability_id,
		"ability_executor_target": _ability_executor_target,
		"ability_executor_target_peer_id": _ability_executor_target_peer_id,
		"ability_executor_elapsed": (
			maxf(0.0, now - _ability_executor_started_at)
			if _ability_executor_active
			else 0.0
		),
		"ability_executor_last_result": _ability_executor_last_result,
		"shot_executor_active": _shot_executor_active,
		"shot_executor_target": _shot_executor_target,
		"shot_executor_elapsed": (
			maxf(0.0, now - _shot_executor_started_at)
			if _shot_executor_active
			else 0.0
		),
		"shot_executor_last_result": _shot_executor_last_result,
		"possession_executor_action": str(_possession_executor_action),
		"possession_executor_target": _possession_executor_target,
		"possession_executor_target_peer_id": _possession_executor_target_peer_id,
		"possession_executor_elapsed": (
			maxf(0.0, now - _possession_executor_started_at)
			if _possession_executor_action != ACTION_NONE
			else 0.0
		),
		"possession_executor_last_result": _possession_executor_last_result,
		"role_executor_action": str(_role_executor_action),
		"role_executor_target": _role_executor_target,
		"role_executor_target_peer_id": _role_executor_target_peer_id,
		"role_executor_defensive_role": str(_role_executor_defensive_role),
		"role_executor_kickoff_role": str(_role_executor_kickoff_role),
		"role_executor_elapsed": (
			maxf(0.0, now - _role_executor_started_at)
			if _role_executor_action != ACTION_NONE
			else 0.0
		),
		"role_executor_last_result": _role_executor_last_result
	}


func _get_execution_authority_name() -> String:
	if _ability_executor_active:
		return "ability_executor"
	if _shot_executor_active:
		return "shot_executor"
	match _possession_executor_action:
		ACTION_GET_BALL:
			return "get_ball_executor"
		ACTION_PASS:
			return "pass_executor"
		ACTION_ATTACK:
			return "attack_executor"
	match _role_executor_action:
		ACTION_DEFEND:
			return "defend_executor"
		ACTION_GOALKEEP:
			return "goalkeep_executor"
		ACTION_KICKOFF:
			return "kickoff_executor"
	return "legacy"



func _ability_uses_movement_authority(ability_id: int) -> bool:
	return ability_id in [
		FootballPlayer.ABILITY_BURST_DRIBBLE,
		FootballPlayer.ABILITY_OVERDRIVE,
		FootballPlayer.ABILITY_HEEL_TURN,
		FootballPlayer.ABILITY_ELASTIC_STEP,
		FootballPlayer.ABILITY_BLIND_SPOT,
		FootballPlayer.ABILITY_BREAKAWAY,
		FootballPlayer.ABILITY_SNAPBACK,
		FootballPlayer.ABILITY_SIDE_SWIPE,
		FootballPlayer.ABILITY_NUTMEG,
		FootballPlayer.ABILITY_DECOY_RUN
	]


func _ability_is_defensive_tactical_option(ability_id: int) -> bool:
	return ability_id in [
		FootballPlayer.ABILITY_ENFORCER,
		FootballPlayer.ABILITY_GOALKEEPER_REACH,
		FootballPlayer.ABILITY_REFLEX_BLOCK,
		FootballPlayer.ABILITY_IRON_ANCHOR,
		FootballPlayer.ABILITY_ECHO
	]


func _ability_candidate_matches_tactical_action(
	ability_id: int,
	intent: StringName
) -> bool:
	# Abilities are candidates inside the currently selected football action,
	# not a second brain with permission to override an unrelated responsibility.
	# Planned combo/demo/penalty callers can explicitly force a known-safe request.
	if ability_id == FootballPlayer.ABILITY_NONE:
		return false
	if _kickoff_role_is_live():
		return false
	match ability_id:
		FootballPlayer.ABILITY_QUICK_TRIGGER, FootballPlayer.ABILITY_POWER_STRIKE:
			return intent in [INTENT_SHOOT, INTENT_PASS]
		FootballPlayer.ABILITY_TIME_SKIP_PASS, FootballPlayer.ABILITY_RETURN_TAG:
			return intent in [INTENT_PASS, INTENT_DRIBBLE, INTENT_RECEIVE]
		FootballPlayer.ABILITY_DIRECT_FINISH:
			return intent in [INTENT_RECEIVE, INTENT_SHOOT]
		FootballPlayer.ABILITY_BURST_DRIBBLE, FootballPlayer.ABILITY_HEEL_TURN, FootballPlayer.ABILITY_ELASTIC_STEP, FootballPlayer.ABILITY_BLIND_SPOT, FootballPlayer.ABILITY_NUTMEG:
			return intent in [INTENT_DRIBBLE, INTENT_CHASE, INTENT_RECEIVE]
		FootballPlayer.ABILITY_OVERDRIVE:
			# Overdrive is valid both as an on-ball burst and as a committed
			# recovery/support run. It still cannot invent a goalkeeper job.
			return intent in [
				INTENT_DRIBBLE, INTENT_CHASE, INTENT_RECEIVE,
				INTENT_FORWARD_RUN, INTENT_WIDE_SUPPORT, INTENT_COVER, INTENT_MARK
			]
		FootballPlayer.ABILITY_BREAKAWAY:
			return intent in [INTENT_DRIBBLE, INTENT_CHASE, INTENT_RECEIVE, INTENT_PASS]
		FootballPlayer.ABILITY_SNAPBACK, FootballPlayer.ABILITY_SIDE_SWIPE:
			return intent in [INTENT_DRIBBLE, INTENT_CHASE, INTENT_RECEIVE, INTENT_PASS, INTENT_SHOOT]
		FootballPlayer.ABILITY_DECOY_RUN:
			return intent in [INTENT_DRIBBLE, INTENT_FORWARD_RUN, INTENT_WIDE_SUPPORT, INTENT_RECEIVE]
		FootballPlayer.ABILITY_ENFORCER:
			# Enforcer can deliberately create space while carrying/receiving as
			# well as act as a defensive physical challenge.
			return intent in [INTENT_DRIBBLE, INTENT_RECEIVE, INTENT_CHASE, INTENT_COVER, INTENT_MARK, INTENT_ENFORCE]
		FootballPlayer.ABILITY_REFLEX_BLOCK, FootballPlayer.ABILITY_ECHO:
			return intent in [INTENT_CHASE, INTENT_COVER, INTENT_MARK, INTENT_ENFORCE, INTENT_GOALKEEP]
		FootballPlayer.ABILITY_GOALKEEPER_REACH:
			return intent == INTENT_GOALKEEP
		FootballPlayer.ABILITY_IRON_ANCHOR:
			return intent in [INTENT_GOALKEEP, INTENT_CHASE, INTENT_RECEIVE, INTENT_COVER]
		FootballPlayer.ABILITY_BOOGIE_WOOGIE:
			return intent in [INTENT_DRIBBLE, INTENT_CHASE, INTENT_COVER, INTENT_MARK]
		FootballPlayer.ABILITY_META_VISION, FootballPlayer.ABILITY_COPYCAT:
			return intent != INTENT_IDLE
	return intent != INTENT_IDLE


func _resolve_ability_tactical_context_intent(ability_id: int) -> StringName:
	# Normal gameplay reaches ability evaluation with a football intent already
	# selected. A few legacy/boss/test entry points call the evaluator directly;
	# in that case derive one obvious context first instead of letting the ability
	# subsystem behave like a second independent brain.
	if _tactical_intent_action != INTENT_IDLE:
		return _tactical_intent_action
	if not is_instance_valid(controlled_player) or not is_instance_valid(ball):
		return INTENT_IDLE

	var has_kickable_ball := controlled_player.cpu_has_kickable_ball()
	if ability_id in [
		FootballPlayer.ABILITY_QUICK_TRIGGER,
		FootballPlayer.ABILITY_POWER_STRIKE
	]:
		return INTENT_SHOOT if has_kickable_ball else INTENT_IDLE
	if ability_id in [
		FootballPlayer.ABILITY_TIME_SKIP_PASS,
		FootballPlayer.ABILITY_RETURN_TAG
	]:
		if is_instance_valid(_planned_receiver):
			return INTENT_PASS
		return INTENT_DRIBBLE if has_kickable_ball else INTENT_IDLE
	if ability_id == FootballPlayer.ABILITY_DIRECT_FINISH:
		return INTENT_RECEIVE
	if ability_id == FootballPlayer.ABILITY_ENFORCER and has_kickable_ball:
		return INTENT_DRIBBLE
	if _ability_uses_movement_authority(ability_id):
		if ability_id == FootballPlayer.ABILITY_DECOY_RUN:
			return INTENT_FORWARD_RUN if _team_likely_has_possession() else INTENT_IDLE
		return INTENT_DRIBBLE if has_kickable_ball else INTENT_IDLE
	if _ability_is_defensive_tactical_option(ability_id):
		if _is_designated_goalkeeper(controlled_player):
			return INTENT_GOALKEEP
		return INTENT_CHASE if not _team_likely_has_possession() else INTENT_COVER
	return INTENT_IDLE


func _get_ability_executor_hold_seconds(ability_id: int) -> float:
	if _ability_uses_movement_authority(ability_id):
		return maxf(0.16, committed_ability_executor_max_seconds)
	if _ability_is_defensive_tactical_option(ability_id):
		return maxf(0.10, minf(0.20, committed_ability_executor_max_seconds))
	return maxf(0.08, minf(
		committed_ability_instant_hold_seconds,
		committed_ability_executor_max_seconds
	))


func _resolve_ability_action_target() -> Vector2:
	if not _tactical_intent_target.is_zero_approx():
		return _tactical_intent_target
	if not _planned_destination.is_zero_approx():
		return _planned_destination
	if not _shot_target.is_zero_approx():
		return _shot_target
	if is_instance_valid(controlled_player):
		return controlled_player.global_position
	return Vector2.ZERO


func _request_ability_action(
	ability_id: int,
	target: Vector2 = Vector2.ZERO,
	target_peer_id: int = 0,
	source_intent: StringName = INTENT_IDLE,
	preparation_ability_id: int = FootballPlayer.ABILITY_NONE,
	force_planned: bool = false,
	prepare_direction: bool = true
) -> bool:
	if (
		not committed_ability_executor_enabled
		or ability_id == FootballPlayer.ABILITY_NONE
		or not is_instance_valid(controlled_player)
		or not is_instance_valid(ball)
		or _kickoff_role_is_live()
	):
		return false
	# Trap or Volley can end before this short executor hold does (for example,
	# the reception is consumed or the player runtime is reset). In that case the
	# physical ability is already over, so keeping ACTION_ABILITY alive would only
	# block the next legitimate reception. Release that stale authority first.
	if (
		_ability_executor_active
		and _ability_executor_ability_id == FootballPlayer.ABILITY_DIRECT_FINISH
		and not controlled_player.server_ability_active
	):
		_complete_committed_ability_executor("direct_finish_runtime_ended")
	if (
		_ability_executor_active
		or _shot_executor_active
		or _possession_executor_action != ACTION_NONE
		or _role_executor_action != ACTION_NONE
	):
		return false
	if controlled_player.selected_ability != ability_id:
		return false
	if not _cpu_ability_is_ready():
		return false
	if preparation_ability_id == FootballPlayer.ABILITY_NONE:
		preparation_ability_id = ability_id
	if source_intent == INTENT_IDLE:
		source_intent = _resolve_ability_tactical_context_intent(
			preparation_ability_id
		)
	# Copycat must obey the tactical role of the copied ability, not the very
	# permissive COPYCAT wrapper. This prevents an offensive copied move from
	# stealing a defensive/goalkeeper responsibility.
	var tactical_ability_id := preparation_ability_id
	if not force_planned and not _ability_candidate_matches_tactical_action(
		tactical_ability_id,
		source_intent
	):
		return false
	if target.is_zero_approx():
		target = _resolve_ability_action_target()

	_ability_executor_active = true
	_ability_executor_started_at = _server_time_seconds()
	_ability_executor_hold_until = (
		_ability_executor_started_at
		+ _get_ability_executor_hold_seconds(preparation_ability_id)
	)
	_ability_executor_ability_id = ability_id
	_ability_executor_preparation_ability_id = preparation_ability_id
	_ability_executor_target = target
	_ability_executor_target_peer_id = target_peer_id
	_ability_executor_source_intent = source_intent
	_ability_executor_movement_target = _movement_target
	_ability_executor_direction = Vector2.ZERO
	_ability_executor_last_result = "activating"
	_begin_action_commitment(
		ACTION_ABILITY,
		target,
		target_peer_id,
		_get_action_commitment_minimum_seconds(ACTION_ABILITY),
		source_intent
	)

	if prepare_direction:
		_prepare_ability_direction(preparation_ability_id)
	_ability_executor_direction = controlled_player.server_direction.normalized()
	if _ability_uses_movement_authority(preparation_ability_id):
		if _ability_executor_direction.is_zero_approx():
			_ability_executor_direction = controlled_player.global_position.direction_to(
				target
			)
		if _ability_executor_direction.is_zero_approx():
			_ability_executor_direction = Vector2(_get_attack_sign(), 0.0)
		_ability_executor_movement_target = _clamp_to_field(
			controlled_player.global_position
			+ _ability_executor_direction
			* maxf(320.0, committed_ability_movement_distance)
		)

	var activated := false
	if ability_id == FootballPlayer.ABILITY_DIRECT_FINISH:
		activated = controlled_player.cpu_arm_trap_or_volley(
			controlled_player.server_direct_finish_volley_requested,
			controlled_player.server_direct_finish_aim_direction
		)
	else:
		activated = controlled_player.cpu_activate_selected_ability()
	if not activated:
		_abort_committed_ability_executor("ability_activation_failed")
		return false
	_ability_executor_last_result = "active"
	return true



func _request_planned_selected_ability(
	preparation_ability_id: int = FootballPlayer.ABILITY_NONE
) -> bool:
	if not is_instance_valid(controlled_player):
		return false
	var target_peer_id := 0
	if is_instance_valid(_planned_receiver):
		target_peer_id = _planned_receiver.owner_peer_id
	var source_intent := _tactical_intent_action
	if source_intent == INTENT_IDLE:
		source_intent = INTENT_PASS if _plan_is_pass else INTENT_SHOOT
	return _request_ability_action(
		controlled_player.selected_ability,
		_resolve_ability_action_target(),
		target_peer_id,
		source_intent,
		preparation_ability_id,
		true
	)


func _adopt_active_ability_followup(
	ability_id: int,
	target: Vector2 = Vector2.ZERO,
	target_peer_id: int = 0
) -> bool:
	if (
		not committed_ability_executor_enabled
		or _ability_executor_active
		or _shot_executor_active
		or _possession_executor_action != ACTION_NONE
		or _role_executor_action != ACTION_NONE
		or not is_instance_valid(controlled_player)
		or not controlled_player.server_ability_active
		or controlled_player.server_active_ability_id != ability_id
	):
		return false
	if target.is_zero_approx():
		target = _resolve_ability_action_target()
	_ability_executor_active = true
	_ability_executor_started_at = _server_time_seconds()
	_ability_executor_hold_until = (
		_ability_executor_started_at
		+ maxf(0.10, committed_ability_instant_hold_seconds)
	)
	_ability_executor_ability_id = ability_id
	_ability_executor_preparation_ability_id = ability_id
	_ability_executor_target = target
	_ability_executor_target_peer_id = target_peer_id
	_ability_executor_source_intent = _tactical_intent_action
	_ability_executor_movement_target = _movement_target
	_prepare_ability_direction(ability_id)
	_ability_executor_direction = controlled_player.server_direction.normalized()
	_ability_executor_last_result = "followup_pending"
	_begin_action_commitment(
		ACTION_ABILITY,
		target,
		target_peer_id,
		_get_action_commitment_minimum_seconds(ACTION_ABILITY),
		_ability_executor_source_intent
	)
	return true


func _abort_committed_ability_executor(reason: String) -> bool:
	if not _ability_executor_active:
		return false
	if not _action_interrupt_is_allowed(reason):
		return false
	_ability_executor_active = false
	_ability_executor_started_at = -INF
	_ability_executor_hold_until = -INF
	_ability_executor_ability_id = FootballPlayer.ABILITY_NONE
	_ability_executor_preparation_ability_id = FootballPlayer.ABILITY_NONE
	_ability_executor_target = Vector2.ZERO
	_ability_executor_movement_target = Vector2.ZERO
	_ability_executor_target_peer_id = 0
	_ability_executor_source_intent = INTENT_IDLE
	_ability_executor_direction = Vector2.ZERO
	_ability_executor_last_result = reason
	_interrupt_action_commitment(reason)
	if reason not in ["episode_reset", "cpu_input_stopped"]:
		_arm_tactical_reconsideration(reason)
	return true


func _complete_committed_ability_executor(reason: String) -> void:
	if not _ability_executor_active:
		return
	_ability_executor_active = false
	_ability_executor_started_at = -INF
	_ability_executor_hold_until = -INF
	_ability_executor_ability_id = FootballPlayer.ABILITY_NONE
	_ability_executor_preparation_ability_id = FootballPlayer.ABILITY_NONE
	_ability_executor_target = Vector2.ZERO
	_ability_executor_movement_target = Vector2.ZERO
	_ability_executor_target_peer_id = 0
	_ability_executor_source_intent = INTENT_IDLE
	_ability_executor_direction = Vector2.ZERO
	_ability_executor_last_result = reason
	_interrupt_action_commitment(reason)



func _handoff_committed_ability_executor(reason: String) -> void:
	if not _ability_executor_active:
		return
	var source_intent := _ability_executor_source_intent
	var target := _ability_executor_target
	var movement_target := _ability_executor_movement_target
	var target_peer_id := _ability_executor_target_peer_id
	_complete_committed_ability_executor(reason)
	_movement_target = movement_target
	_set_tactical_intent(source_intent, target, target_peer_id)
	# Handoff is immediate: the next executor may claim on the same physics tick,
	# so using an ability never creates an artificial dead frame before the shot,
	# pass, dribble, defensive role, or support action resumes.
	match _get_high_level_action_for_tactical_intent(source_intent):
		ACTION_SHOOT:
			_try_claim_committed_shot_executor()
		ACTION_GET_BALL, ACTION_PASS, ACTION_ATTACK:
			_try_claim_committed_possession_executor()
		ACTION_DEFEND, ACTION_GOALKEEP, ACTION_KICKOFF:
			_try_claim_committed_role_executor()


func _update_committed_ability_executor(_delta: float) -> bool:
	if not _ability_executor_active:
		return false
	if (
		not is_instance_valid(controlled_player)
		or not is_instance_valid(ball)
		or not is_instance_valid(match_manager)
	):
		_abort_committed_ability_executor("ability_executor_invalid_state")
		return false
	var ability_id := _ability_executor_ability_id
	if ability_id == FootballPlayer.ABILITY_NONE:
		_abort_committed_ability_executor("ability_executor_missing_ability")
		return false

	# Active two-stage abilities finish their own physical sequence here. This
	# keeps the follow-up input under the same ACTION_ABILITY authority instead
	# of letting the generic decision loop fire a second, independent command.
	if controlled_player.server_ability_active:
		var active_ability_id := controlled_player.server_active_ability_id
		if active_ability_id == ability_id:
			match ability_id:
				FootballPlayer.ABILITY_HEEL_TURN:
					if (
						controlled_player.cpu_can_execute_phantom_heel_followup()
						and _phantom_heel_followup_is_useful()
						and controlled_player.cpu_activate_selected_ability()
					):
						_handoff_committed_ability_executor("heel_turn_followup")
						return false
				FootballPlayer.ABILITY_SIDE_SWIPE:
					if (
						controlled_player.cpu_has_kickable_ball()
						and (_plan_is_pass or _side_swipe_escape_touch_is_useful())
						and controlled_player.cpu_try_side_swipe_pass()
					):
						_handoff_committed_ability_executor("side_swipe_touch")
						return false
				FootballPlayer.ABILITY_BREAKAWAY:
					if (
						controlled_player.cpu_has_kickable_ball()
						and _breakaway_trigger_is_useful()
						and controlled_player.cpu_try_breakaway_pass()
					):
						_handoff_committed_ability_executor("breakaway_release")
						return false
				FootballPlayer.ABILITY_SNAPBACK:
					if (
						controlled_player.cpu_has_snapback_recall()
						and _snapback_recall_is_useful()
						and controlled_player.cpu_activate_selected_ability()
					):
						_handoff_committed_ability_executor("snapback_recall")
						return false

	if _ability_uses_movement_authority(
		_ability_executor_preparation_ability_id
	):
		if not _ability_executor_direction.is_zero_approx():
			_ability_executor_movement_target = _clamp_to_field(
				controlled_player.global_position
				+ _ability_executor_direction
				* maxf(320.0, committed_ability_movement_distance)
			)
	_movement_target = _ability_executor_movement_target
	_publish_committed_executor_intent(
		_ability_executor_source_intent,
		_ability_executor_target,
		_ability_executor_target_peer_id
	)
	_begin_action_commitment(
		ACTION_ABILITY,
		_ability_executor_target,
		_ability_executor_target_peer_id,
		_get_action_commitment_minimum_seconds(ACTION_ABILITY),
		_ability_executor_source_intent
	)

	var now := _server_time_seconds()
	if now >= _ability_executor_hold_until:
		_handoff_committed_ability_executor("ability_handoff")
		return false
	if (
		now - _ability_executor_started_at
		>= maxf(0.12, committed_ability_executor_max_seconds + 0.20)
	):
		_handoff_committed_ability_executor("ability_executor_timeout")
		return false
	return true


func _try_claim_committed_role_executor() -> bool:
	if (
		not committed_role_executors_enabled
		or _ability_executor_active
		or _shot_executor_active
		or _possession_executor_action != ACTION_NONE
		or _role_executor_action != ACTION_NONE
		or not is_instance_valid(controlled_player)
		or not is_instance_valid(ball)
		or not is_instance_valid(match_manager)
		or match_manager.penalty_shootout_active
	):
		return false
	var action := _get_high_level_action_for_tactical_intent(
		_tactical_intent_action
	)
	var designated_goalkeeper := _is_designated_goalkeeper(controlled_player)
	# Keeper branches sometimes intentionally publish COVER while acting as the
	# final containment player. The movement authority is still GOALKEEP: this
	# prevents a generic defensive/attacking subsystem from treating the keeper
	# like an ordinary outfielder during that short responsibility window.
	if action == ACTION_DEFEND and designated_goalkeeper:
		action = ACTION_GOALKEEP
	if action not in [ACTION_DEFEND, ACTION_GOALKEEP, ACTION_KICKOFF]:
		return false
	if action == ACTION_DEFEND:
		if _team_likely_has_possession():
			return false
	elif action == ACTION_GOALKEEP:
		if not designated_goalkeeper:
			return false
	elif not _kickoff_role_is_live():
		return false

	_role_executor_action = action
	_role_executor_started_at = _server_time_seconds()
	_role_executor_target = _tactical_intent_target
	_role_executor_target_peer_id = _tactical_intent_peer_id
	_role_executor_source_intent = _tactical_intent_action
	_role_executor_defensive_role = &""
	_role_executor_kickoff_role = &""
	_role_executor_last_result = "active"
	if action == ACTION_DEFEND:
		var assignment: Dictionary = match_manager.get_cpu_defensive_assignment(
			controlled_player.team,
			controlled_player.owner_peer_id
		)
		_role_executor_defensive_role = StringName(
			assignment.get("role", &"")
		)
	elif action == ACTION_KICKOFF:
		_role_executor_kickoff_role = _get_locked_kickoff_role()
	_begin_action_commitment(
		action,
		_role_executor_target,
		_role_executor_target_peer_id,
		_get_action_commitment_minimum_seconds(action),
		_role_executor_source_intent
	)
	return true


func _abort_committed_role_executor(reason: String) -> bool:
	if _role_executor_action == ACTION_NONE:
		return false
	if not _action_interrupt_is_allowed(reason):
		return false
	_role_executor_action = ACTION_NONE
	_role_executor_started_at = -INF
	_role_executor_target = Vector2.ZERO
	_role_executor_target_peer_id = 0
	_role_executor_source_intent = INTENT_IDLE
	_role_executor_defensive_role = &""
	_role_executor_kickoff_role = &""
	_role_executor_last_result = reason
	_interrupt_action_commitment(reason)
	if reason not in ["episode_reset", "cpu_input_stopped"]:
		_arm_tactical_reconsideration(reason)
	return true


func _complete_committed_role_executor(reason: String) -> void:
	if _role_executor_action == ACTION_NONE:
		return
	_role_executor_action = ACTION_NONE
	_role_executor_started_at = -INF
	_role_executor_target = Vector2.ZERO
	_role_executor_target_peer_id = 0
	_role_executor_source_intent = INTENT_IDLE
	_role_executor_defensive_role = &""
	_role_executor_kickoff_role = &""
	_role_executor_last_result = reason
	_interrupt_action_commitment(reason)


func _update_committed_role_executor(_delta: float) -> bool:
	if _role_executor_action == ACTION_NONE:
		return false
	if (
		not is_instance_valid(controlled_player)
		or not is_instance_valid(ball)
		or not is_instance_valid(match_manager)
	):
		_abort_committed_role_executor("role_executor_invalid_state")
		return false
	match _role_executor_action:
		ACTION_DEFEND:
			return _update_committed_defend_executor()
		ACTION_GOALKEEP:
			return _update_committed_goalkeep_executor()
		ACTION_KICKOFF:
			return _update_committed_kickoff_executor()
	_abort_committed_role_executor("unsupported_role_executor")
	return false


func _update_committed_defend_executor() -> bool:
	if _team_likely_has_possession():
		_complete_committed_role_executor("defense_possession_won")
		return false
	if _is_designated_goalkeeper(controlled_player):
		_abort_committed_role_executor("defense_became_goalkeeper")
		return false
	var assignment: Dictionary = match_manager.get_cpu_defensive_assignment(
		controlled_player.team,
		controlled_player.owner_peer_id
	)
	var role := StringName(assignment.get("role", &""))
	if role.is_empty():
		_abort_committed_role_executor("defense_assignment_missing")
		return false
	if not _role_executor_defensive_role.is_empty() and role != _role_executor_defensive_role:
		_abort_committed_role_executor("defense_role_changed")
		return false
	var elapsed := _server_time_seconds() - _role_executor_started_at
	if elapsed >= maxf(0.16, committed_defend_executor_max_seconds):
		_complete_committed_role_executor("defense_replan")
		_decision_accumulator = _next_decision_delay
		return false

	var target := _get_committed_defensive_role_target(assignment, role)
	if target.is_zero_approx():
		_abort_committed_role_executor("defense_target_missing")
		return false
	_role_executor_defensive_role = role
	_role_executor_target = target
	_role_executor_target_peer_id = int(assignment.get("target_peer_id", 0))
	_movement_target = target
	var intent := INTENT_COVER
	match role:
		&"press":
			intent = INTENT_CHASE
		&"mark":
			intent = INTENT_MARK
	_begin_action_commitment(
		ACTION_DEFEND,
		target,
		_role_executor_target_peer_id,
		_get_action_commitment_minimum_seconds(ACTION_DEFEND),
		intent
	)
	_publish_committed_executor_intent(
		intent,
		target,
		_role_executor_target_peer_id
	)
	if role in [&"press", &"cover", &"final"]:
		_try_defensive_ball_win()
	return true


func _get_committed_defensive_role_target(
	assignment: Dictionary,
	role: StringName
) -> Vector2:
	var own_goal := _get_own_goal()
	if own_goal == null:
		return _clamp_to_field(
			assignment.get("target_position", _get_predicted_ball_position())
		)
	var assigned_target: Vector2 = assignment.get("target_position", Vector2.ZERO)
	match role:
		&"press":
			if assigned_target.is_zero_approx():
				assigned_target = _get_primary_defensive_press_position(own_goal)
		&"cover":
			if assigned_target.is_zero_approx():
				assigned_target = _get_defensive_lane_cover_position(own_goal)
		&"final":
			if assigned_target.is_zero_approx():
				assigned_target = _get_defensive_lane_cover_position(own_goal)
			assigned_target = _enforce_final_defender_goal_side(assigned_target)
		&"mark":
			var mark := _get_opponent_by_peer_id(
				int(assignment.get("target_peer_id", 0))
			)
			if mark != null:
				assigned_target = _get_goal_side_mark_position(mark, own_goal)
			elif assigned_target.is_zero_approx():
				assigned_target = _get_defensive_lane_cover_position(own_goal)
	return _clamp_to_field(assigned_target)


func _enforce_final_defender_goal_side(target: Vector2) -> Vector2:
	var own_goal := _get_own_goal()
	if own_goal == null or target.is_zero_approx():
		return target
	var goal_center := _get_goal_center(own_goal)
	var threat_position := _get_execution_predicted_ball_position()
	var carrier := _get_likely_opponent_ball_carrier()
	if carrier != null:
		threat_position = carrier.global_position
	var attack_sign := _get_attack_sign()
	var target_progress := (target.x - goal_center.x) * attack_sign
	var threat_progress := (threat_position.x - goal_center.x) * attack_sign
	var maximum_progress := maxf(
		80.0,
		threat_progress - maxf(0.0, committed_final_defender_goal_side_margin)
	)
	if target_progress > maximum_progress:
		target.x = goal_center.x + attack_sign * maximum_progress
	return _clamp_to_field(target)


func _update_committed_goalkeep_executor() -> bool:
	if not _is_designated_goalkeeper(controlled_player):
		_abort_committed_role_executor("goalkeeper_role_lost")
		return false
	if _goalkeeper_has_secure_ball_control():
		_complete_committed_role_executor("goalkeeper_secure_control")
		_decision_accumulator = _next_decision_delay
		return false
	var elapsed := _server_time_seconds() - _role_executor_started_at
	if elapsed >= maxf(0.14, committed_goalkeep_executor_max_seconds):
		_complete_committed_role_executor("goalkeeper_replan")
		_decision_accumulator = _next_decision_delay
		return false
	var target := _clamp_goalkeeper_authority_target(_role_executor_target)
	var own_goal := _get_own_goal()
	if own_goal != null and (
		_opponent_has_live_ball_control()
		or not _predict_own_goal_threat(1.15).is_empty()
	):
		var live_y := _predict_goalkeeper_y(own_goal, target.x)
		target.y = lerpf(target.y, live_y, 0.64)
		target = _clamp_goalkeeper_authority_target(target)
	_role_executor_target = target
	_movement_target = target
	_begin_action_commitment(
		ACTION_GOALKEEP,
		target,
		_role_executor_target_peer_id,
		_get_action_commitment_minimum_seconds(ACTION_GOALKEEP),
		INTENT_GOALKEEP
	)
	_publish_committed_executor_intent(
		INTENT_GOALKEEP,
		target,
		_role_executor_target_peer_id
	)
	return true


func _clamp_goalkeeper_authority_target(target: Vector2) -> Vector2:
	var own_goal := _get_own_goal()
	if own_goal == null or target.is_zero_approx():
		return _clamp_to_field(target)
	var goal_center := _get_goal_center(own_goal)
	var attack_sign := _get_attack_sign()
	var progress := (target.x - goal_center.x) * attack_sign
	var maximum_depth := maxf(900.0, committed_goalkeeper_max_field_depth)
	if controlled_player != null and controlled_player.is_neuer_boss():
		maximum_depth = maxf(maximum_depth, 3400.0)
	progress = clampf(
		progress,
		80.0,
		maximum_depth
	)
	target.x = goal_center.x + attack_sign * progress
	return _clamp_to_field(target)


func _update_committed_kickoff_executor() -> bool:
	if not _kickoff_role_is_live():
		_complete_committed_role_executor("kickoff_finished")
		_decision_accumulator = _next_decision_delay
		return false
	var current_role := _get_locked_kickoff_role()
	if (
		_get_active_team_player_count() > 1
		and not _role_executor_kickoff_role.is_empty()
		and not current_role.is_empty()
		and current_role != _role_executor_kickoff_role
	):
		_abort_committed_role_executor("kickoff_role_changed")
		return false
	if not current_role.is_empty():
		_role_executor_kickoff_role = current_role
	if not _update_competitive_kickoff_strategy():
		_complete_committed_role_executor("kickoff_strategy_finished")
		_decision_accumulator = _next_decision_delay
		return false
	_role_executor_target = _movement_target
	_role_executor_target_peer_id = _tactical_intent_peer_id
	_begin_action_commitment(
		ACTION_KICKOFF,
		_movement_target,
		_role_executor_target_peer_id,
		_get_action_commitment_minimum_seconds(ACTION_KICKOFF),
		_tactical_intent_action
	)
	_publish_committed_executor_intent(
		_tactical_intent_action,
		_tactical_intent_target,
		_tactical_intent_peer_id
	)
	return true


func _shot_executor_target_is_goal_bound() -> bool:
	if (
		controlled_player == null
		or not is_instance_valid(controlled_player)
		or ball == null
		or not is_instance_valid(ball)
		or _plan_is_pass
		or _shot_target.is_zero_approx()
	):
		return false
	var opponent_goal := _get_opponent_goal()
	if opponent_goal == null:
		return false
	var final_target := _planned_destination
	if final_target.is_zero_approx():
		final_target = _shot_target
	var mouth_range := opponent_goal.get_mouth_y_range()
	var half_height := maxf(0.0, (mouth_range.y - mouth_range.x) * 0.5)
	var margin := minf(
		maxf(0.0, shot_integrity_goal_margin),
		maxf(0.0, half_height - 1.0)
	)
	return (
		absf(final_target.x - opponent_goal.get_goal_plane_x())
		<= maxf(1.0, shot_integrity_goal_plane_tolerance)
		and final_target.y >= mouth_range.x + margin
		and final_target.y <= mouth_range.y - margin
	)


func _try_claim_committed_shot_executor() -> bool:
	if _ability_executor_active:
		return false
	if _shot_executor_active:
		_shot_target = _shot_executor_target
		if not _plan_uses_wall and not _plan_uses_double_bank:
			_planned_destination = _shot_executor_target
		_begin_action_commitment(
			ACTION_SHOOT,
			_shot_executor_target,
			0,
			_get_action_commitment_minimum_seconds(ACTION_SHOOT),
			INTENT_SHOOT
		)
		return true
	if (
		_tactical_intent_action != INTENT_SHOOT
		or _plan_is_pass
		or not _shot_executor_target_is_goal_bound()
		or (
			_kickoff_strategy != &""
			and _server_time_seconds() <= _kickoff_strategy_until
		)
	):
		return false
	var now := _server_time_seconds()
	if (
		not controlled_player.server_is_charging
		and now - controlled_player.server_last_kick_time
		<= maxf(0.0, committed_shot_recent_kick_grace_seconds)
	):
		return false
	_shot_executor_active = true
	_shot_executor_started_at = now
	_shot_executor_target = _shot_target
	_shot_executor_kick_time_at_start = controlled_player.server_last_kick_time
	_shot_executor_last_result = "active"
	if not _cpu_first_touch_plan.is_empty():
		var first_touch_mode := StringName(
			_cpu_first_touch_plan.get("mode", FIRST_TOUCH_NONE)
		)
		if first_touch_mode != FIRST_TOUCH_SHOT:
			_clear_cpu_first_touch_plan()
	_begin_action_commitment(
		ACTION_SHOOT,
		_shot_executor_target,
		0,
		_get_action_commitment_minimum_seconds(ACTION_SHOOT),
		INTENT_SHOOT
	)
	return true


func _abort_committed_shot_executor(
	reason: String,
	cancel_charge: bool = true
) -> bool:
	if not _shot_executor_active:
		return false
	if not _action_interrupt_is_allowed(reason):
		return false
	if (
		cancel_charge
		and is_instance_valid(controlled_player)
		and controlled_player.server_is_charging
	):
		controlled_player.cpu_cancel_shot_charge()
		_reset_cpu_charge_tracking()
	_shot_executor_active = false
	_shot_executor_started_at = -INF
	_shot_executor_target = Vector2.ZERO
	_shot_executor_kick_time_at_start = -INF
	_shot_executor_last_result = reason
	_interrupt_action_commitment(reason)
	if reason not in ["episode_reset", "cpu_input_stopped"]:
		_arm_tactical_reconsideration(reason)
	return true


func _complete_committed_shot_executor(reason: String) -> void:
	if not _shot_executor_active:
		return
	_shot_executor_active = false
	_shot_executor_started_at = -INF
	_shot_executor_target = Vector2.ZERO
	_shot_executor_kick_time_at_start = -INF
	_shot_executor_last_result = reason
	_interrupt_action_commitment(reason)


func _committed_direct_shot_route_is_open() -> bool:
	if _plan_uses_wall or _plan_uses_double_bank:
		return true
	if _shot_executor_target.is_zero_approx():
		return false
	var goal_distance := ball.global_position.distance_to(
		_shot_executor_target
	)
	var live_lane := _minimum_segment_clearance(
		ball.global_position,
		_shot_executor_target
	)
	var minimum_live_lane := maxf(
		95.0,
		_required_direct_shot_lane(goal_distance) * 0.68
	)
	return live_lane >= minimum_live_lane


func _try_retarget_blocked_committed_shot() -> bool:
	if (
		not live_shot_retarget_enabled
		or _plan_uses_wall
		or _plan_uses_double_bank
	):
		return false
	var opponent_goal := _get_opponent_goal()
	if opponent_goal == null:
		return false
	var live_target := _get_best_live_direct_shot_target(opponent_goal)
	if live_target.is_zero_approx():
		return false
	var goal_distance := ball.global_position.distance_to(live_target)
	var live_lane := _minimum_segment_clearance(
		ball.global_position,
		live_target
	)
	var minimum_live_lane := maxf(
		95.0,
		_required_direct_shot_lane(goal_distance) * 0.68
	)
	if live_lane < minimum_live_lane:
		return false
	_shot_executor_target = live_target
	_shot_target = live_target
	_planned_destination = live_target
	_planned_route_distance = goal_distance
	_begin_action_commitment(
		ACTION_SHOOT,
		live_target,
		0,
		_get_action_commitment_minimum_seconds(ACTION_SHOOT),
		INTENT_SHOOT
	)
	return true


func _update_committed_shot_executor(
	_delta: float,
	charge_was_active: bool
) -> bool:
	if not _shot_executor_active:
		return false
	if (
		controlled_player == null
		or not is_instance_valid(controlled_player)
		or ball == null
		or not is_instance_valid(ball)
	):
		_abort_committed_shot_executor("shot_executor_invalid_state", false)
		return false
	if (
		controlled_player.server_last_kick_time
		> _shot_executor_kick_time_at_start + 0.0001
	):
		_complete_committed_shot_executor("shot_released")
		return true
	if charge_was_active and not controlled_player.server_is_charging:
		_abort_committed_shot_executor("shot_charge_cancelled", false)
		return false
	if _opponent_has_live_ball_control():
		_abort_committed_shot_executor("shot_ball_stolen", true)
		return false
	var elapsed := _server_time_seconds() - _shot_executor_started_at
	var maximum_seconds := maxf(0.35, committed_shot_executor_max_seconds)
	if _has_verified_incoming_teammate_delivery():
		maximum_seconds = maxf(
			maximum_seconds,
			committed_shot_executor_delivery_max_seconds
		)
	if elapsed >= maximum_seconds:
		_abort_committed_shot_executor("shot_executor_timeout", true)
		return false
	var ball_distance := controlled_player.global_position.distance_to(
		ball.global_position
	)
	if (
		not _has_verified_incoming_teammate_delivery()
		and ball_distance
		> maxf(
			shot_precharge_cancel_distance,
			controlled_player.kick_feedback_detection_distance * 2.8
		)
	):
		_abort_committed_shot_executor("shot_ball_unreachable", true)
		return false
	_shot_target = _shot_executor_target
	if not _plan_uses_wall and not _plan_uses_double_bank:
		_planned_destination = _shot_executor_target
		_planned_route_distance = ball.global_position.distance_to(
			_shot_executor_target
		)
	if not _committed_direct_shot_route_is_open():
		if not _try_retarget_blocked_committed_shot():
			_abort_committed_shot_executor("shot_lane_blocked", true)
			return false
	_movement_target = _get_committed_strike_position(_shot_executor_target)
	_set_tactical_intent(INTENT_SHOOT, _shot_executor_target)
	_begin_action_commitment(
		ACTION_SHOOT,
		_shot_executor_target,
		0,
		_get_action_commitment_minimum_seconds(ACTION_SHOOT),
		INTENT_SHOOT
	)
	if not controlled_player.server_is_charging:
		_try_begin_shot(false)
	if is_instance_valid(match_manager):
		match_manager.set_cpu_tactical_intention(
			controlled_player.owner_peer_id,
			controlled_player.team,
			INTENT_SHOOT,
			_shot_executor_target,
			0
		)
	return true


func _try_claim_committed_possession_executor() -> bool:
	if (
		not committed_possession_executors_enabled
		or _ability_executor_active
		or _shot_executor_active
		or _possession_executor_action != ACTION_NONE
		or not _cpu_first_touch_plan.is_empty()
		or not is_instance_valid(controlled_player)
		or not is_instance_valid(ball)
	):
		return false
	var action := _get_high_level_action_for_tactical_intent(
		_tactical_intent_action
	)
	if action not in [ACTION_GET_BALL, ACTION_PASS, ACTION_ATTACK]:
		return false
	if action == ACTION_GET_BALL:
		if (
			_tactical_intent_peer_id > 0
			or _duel_resolution_until > _server_time_seconds()
			or controlled_player.cpu_has_kickable_ball()
			or _opponent_has_live_ball_control()
			or _is_kickoff_ball_state()
		):
			return false
		if _get_active_team_player_count() > 1:
			var actor := _get_team_ball_actor()
			if actor != null and actor != controlled_player:
				return false
	elif action == ACTION_PASS:
		if (
			not _plan_is_pass
			or not is_instance_valid(_planned_receiver)
			or not _planned_receiver.controls_enabled
			or _planned_receiver.team != controlled_player.team
			or _planned_destination.is_zero_approx()
		):
			return false
		if (
			controlled_player.server_ability_active
			and controlled_player.server_active_ability_id in [
				FootballPlayer.ABILITY_TIME_SKIP_PASS,
				FootballPlayer.ABILITY_RETURN_TAG
			]
		):
			return false
	elif action == ACTION_ATTACK:
		if (
			not controlled_player.cpu_has_kickable_ball()
			or controlled_player.server_ability_active
			or _wall_dribble_until > _server_time_seconds()
			or _one_vs_one_space_play_until > _server_time_seconds()
			or _duel_resolution_until > _server_time_seconds()
		):
			return false
		if _get_active_team_player_count() > 1:
			var actor := _get_team_ball_actor()
			if actor != null and actor != controlled_player:
				return false

	_possession_executor_action = action
	_possession_executor_started_at = _server_time_seconds()
	_possession_executor_target_peer_id = _tactical_intent_peer_id
	_possession_executor_kick_time_at_start = controlled_player.server_last_kick_time
	_possession_executor_route_distance = _planned_route_distance
	_possession_executor_uses_wall = _plan_uses_wall
	_possession_executor_uses_double_bank = _plan_uses_double_bank
	_possession_executor_attack_direction = Vector2.ZERO
	_possession_executor_last_result = "active"
	match action:
		ACTION_PASS:
			_possession_executor_target = _planned_destination
			_possession_executor_route_target = _shot_target
			_possession_executor_target_peer_id = _planned_receiver.owner_peer_id
		ACTION_ATTACK:
			_possession_executor_target = _tactical_intent_target
			if _possession_executor_target.is_zero_approx():
				_possession_executor_target = _shot_target
			_possession_executor_route_target = _possession_executor_target
			_possession_executor_attack_direction = ball.global_position.direction_to(
				_possession_executor_target
			)
			if _possession_executor_attack_direction.is_zero_approx():
				_possession_executor_attack_direction = Vector2(
					_get_attack_sign(),
					0.0
				)
		_:
			_possession_executor_target = _tactical_intent_target
			_possession_executor_route_target = _tactical_intent_target
	_begin_action_commitment(
		action,
		_possession_executor_target,
		_possession_executor_target_peer_id,
		_get_action_commitment_minimum_seconds(action),
		_tactical_intent_action
	)
	return true


func _abort_committed_possession_executor(
	reason: String,
	cancel_charge: bool = true
) -> bool:
	if _possession_executor_action == ACTION_NONE:
		return false
	if not _action_interrupt_is_allowed(reason):
		return false
	if (
		cancel_charge
		and is_instance_valid(controlled_player)
		and controlled_player.server_is_charging
		and _possession_executor_action == ACTION_PASS
	):
		controlled_player.cpu_cancel_shot_charge()
		_reset_cpu_charge_tracking()
	_possession_executor_action = ACTION_NONE
	_possession_executor_started_at = -INF
	_possession_executor_target = Vector2.ZERO
	_possession_executor_route_target = Vector2.ZERO
	_possession_executor_route_distance = 0.0
	_possession_executor_target_peer_id = 0
	_possession_executor_kick_time_at_start = -INF
	_possession_executor_uses_wall = false
	_possession_executor_uses_double_bank = false
	_possession_executor_attack_direction = Vector2.ZERO
	_possession_executor_last_result = reason
	_interrupt_action_commitment(reason)
	if reason not in ["episode_reset", "cpu_input_stopped"]:
		_arm_tactical_reconsideration(reason)
	return true


func _complete_committed_possession_executor(reason: String) -> void:
	if _possession_executor_action == ACTION_NONE:
		return
	_possession_executor_action = ACTION_NONE
	_possession_executor_started_at = -INF
	_possession_executor_target = Vector2.ZERO
	_possession_executor_route_target = Vector2.ZERO
	_possession_executor_route_distance = 0.0
	_possession_executor_target_peer_id = 0
	_possession_executor_kick_time_at_start = -INF
	_possession_executor_uses_wall = false
	_possession_executor_uses_double_bank = false
	_possession_executor_attack_direction = Vector2.ZERO
	_possession_executor_last_result = reason
	_interrupt_action_commitment(reason)


func _publish_committed_executor_intent(
	intent: StringName,
	target: Vector2,
	target_peer_id: int = 0
) -> void:
	_set_tactical_intent(intent, target, target_peer_id)
	if not is_instance_valid(match_manager):
		return
	match_manager.set_cpu_tactical_intention(
		controlled_player.owner_peer_id,
		controlled_player.team,
		intent,
		target,
		target_peer_id
	)


func _update_committed_possession_executor(
	_delta: float,
	charge_was_active: bool
) -> bool:
	if _possession_executor_action == ACTION_NONE:
		return false
	if (
		not is_instance_valid(controlled_player)
		or not is_instance_valid(ball)
	):
		_abort_committed_possession_executor(
			"possession_executor_invalid_state",
			false
		)
		return false
	match _possession_executor_action:
		ACTION_GET_BALL:
			return _update_committed_get_ball_executor()
		ACTION_PASS:
			return _update_committed_pass_executor(charge_was_active)
		ACTION_ATTACK:
			return _update_committed_attack_executor()
	_abort_committed_possession_executor("unsupported_possession_executor", true)
	return false


func _update_committed_get_ball_executor() -> bool:
	if controlled_player.cpu_has_kickable_ball():
		_complete_committed_possession_executor("ball_collected")
		return false
	if _opponent_has_live_ball_control():
		_abort_committed_possession_executor("get_ball_opponent_control", false)
		return false
	if _is_kickoff_ball_state():
		_abort_committed_possession_executor("get_ball_kickoff", false)
		return false
	if (
		_is_designated_goalkeeper(controlled_player)
		and not _predict_own_goal_threat(1.25).is_empty()
	):
		_abort_committed_possession_executor("get_ball_goal_emergency", false)
		return false
	if _get_active_team_player_count() > 1:
		var actor := _get_team_ball_actor()
		if actor != null and actor != controlled_player:
			_abort_committed_possession_executor("get_ball_actor_changed", false)
			return false
	var elapsed := _server_time_seconds() - _possession_executor_started_at
	if elapsed >= maxf(0.32, committed_get_ball_executor_max_seconds):
		_complete_committed_possession_executor("get_ball_replan")
		return false
	var target := _get_execution_predicted_ball_position()
	_possession_executor_target = target
	_possession_executor_route_target = target
	_movement_target = target
	_begin_action_commitment(
		ACTION_GET_BALL,
		target,
		0,
		_get_action_commitment_minimum_seconds(ACTION_GET_BALL),
		INTENT_CHASE
	)
	_publish_committed_executor_intent(INTENT_CHASE, target)
	return true


func _update_committed_pass_executor(charge_was_active: bool) -> bool:
	if (
		controlled_player.server_last_kick_time
		> _possession_executor_kick_time_at_start + 0.0001
	):
		_complete_committed_possession_executor("pass_released")
		return true
	if charge_was_active and not controlled_player.server_is_charging:
		_abort_committed_possession_executor("pass_charge_cancelled", false)
		return false
	if _opponent_has_live_ball_control():
		_abort_committed_possession_executor("pass_ball_stolen", true)
		return false
	var receiver := _get_teammate_by_peer_id(
		_possession_executor_target_peer_id
	)
	if (
		receiver == null
		or not receiver.controls_enabled
		or receiver.team != controlled_player.team
	):
		_abort_committed_possession_executor("pass_receiver_unavailable", true)
		return false
	var elapsed := _server_time_seconds() - _possession_executor_started_at
	if elapsed >= maxf(0.45, committed_pass_executor_max_seconds):
		_abort_committed_possession_executor("pass_executor_timeout", true)
		return false
	_plan_is_pass = true
	_planned_receiver = receiver
	_planned_destination = _possession_executor_target
	_shot_target = _possession_executor_route_target
	_plan_uses_wall = _possession_executor_uses_wall
	_plan_uses_double_bank = _possession_executor_uses_double_bank
	_planned_route_distance = (
		_possession_executor_route_distance
		if _possession_executor_route_distance > 0.0
		else ball.global_position.distance_to(_planned_destination)
	)
	if (
		controlled_player.server_is_charging
		and not _charged_pass_release_is_viable()
	):
		_abort_committed_possession_executor("pass_route_invalidated", true)
		return false
	_movement_target = _get_committed_strike_position(_shot_target)
	_begin_action_commitment(
		ACTION_PASS,
		_planned_destination,
		receiver.owner_peer_id,
		_get_action_commitment_minimum_seconds(ACTION_PASS),
		INTENT_PASS
	)
	_publish_committed_executor_intent(
		INTENT_PASS,
		_planned_destination,
		receiver.owner_peer_id
	)
	if not controlled_player.server_is_charging:
		_try_begin_shot(false)
	return true


func _update_committed_attack_executor() -> bool:
	if _opponent_has_live_ball_control():
		_abort_committed_possession_executor("attack_ball_stolen", false)
		return false
	if _ball_is_in_own_goal_danger():
		_abort_committed_possession_executor("attack_goal_emergency", false)
		return false
	if _get_active_team_player_count() > 1:
		var actor := _get_team_ball_actor()
		if actor != null and actor != controlled_player:
			_abort_committed_possession_executor("attack_actor_changed", false)
			return false
	if (
		controlled_player.global_position.distance_to(ball.global_position)
		> maxf(
			committed_attack_ball_loss_distance,
			controlled_player.kick_feedback_detection_distance * 3.0
		)
	):
		_abort_committed_possession_executor("attack_ball_lost", false)
		return false
	var elapsed := _server_time_seconds() - _possession_executor_started_at
	if elapsed >= maxf(0.20, committed_attack_executor_max_seconds):
		_complete_committed_possession_executor("attack_replan")
		return false
	var direction := ball.global_position.direction_to(
		_possession_executor_target
	)
	if direction.is_zero_approx():
		direction = _possession_executor_attack_direction
	if direction.is_zero_approx():
		direction = Vector2(_get_attack_sign(), 0.0)
	_possession_executor_attack_direction = direction.normalized()
	_shot_target = _possession_executor_target
	_movement_target = (
		_get_execution_predicted_ball_position()
		- _possession_executor_attack_direction
		* maxf(120.0, strike_position_distance * 0.86)
	)
	var now := _server_time_seconds()
	var contact_direction := controlled_player.global_position.direction_to(
		ball.global_position
	)
	if (
		now >= _next_dribble_touch_at
		and controlled_player.global_position.distance_to(ball.global_position)
		<= controlled_player.kick_feedback_detection_distance
		and contact_direction.dot(_possession_executor_attack_direction) >= 0.7
	):
		var touch_force := dribble_touch_force
		var active_team_size := _get_checkpoint_team_player_count()
		if active_team_size >= 3:
			touch_force *= 1.12 if active_team_size == 3 else 1.18
		if controlled_player.cpu_dribble_touch(
			_possession_executor_attack_direction,
			touch_force
		):
			_next_dribble_touch_at = now + maxf(0.1, dribble_touch_interval)
	_begin_action_commitment(
		ACTION_ATTACK,
		_possession_executor_target,
		0,
		_get_action_commitment_minimum_seconds(ACTION_ATTACK),
		INTENT_DRIBBLE
	)
	_publish_committed_executor_intent(
		INTENT_DRIBBLE,
		_possession_executor_target
	)
	return true


func _get_effective_player_intention(player: FootballPlayer) -> Dictionary:
	if not is_instance_valid(player):
		return {}
	var declared = match_manager.get_cpu_tactical_intention(
		player.owner_peer_id
	)
	if not declared.is_empty():
		return declared
	for teammate_intent in match_manager.get_cpu_team_intentions(player.team):
		if (
			StringName(teammate_intent.get("action", &"")) == INTENT_PASS
			and int(teammate_intent.get("target_peer_id", 0))
			== player.owner_peer_id
		):
			return {
				"action": INTENT_RECEIVE,
				"target_position": teammate_intent.get(
					"target_position",
					player.global_position
				),
				"target_peer_id": int(teammate_intent.get("peer_id", 0)),
				"inferred": true
			}
	return _infer_player_intention(player)


func _infer_player_intention(player: FootballPlayer) -> Dictionary:
	var movement = player.server_direction.normalized()
	if movement.is_zero_approx() and player.linear_velocity.length() > 80.0:
		movement = player.linear_velocity.normalized()
	var predicted_position = _clamp_to_field(
		player.global_position
		+ player.linear_velocity * maxf(0.1, intention_prediction_seconds)
	)
	var attack_sign = (
		1.0
		if player.team == TEAM_BLUE
		else -1.0
	)
	var attack_direction = Vector2(attack_sign, 0.0)
	var ball_distance = player.global_position.distance_to(ball.global_position)
	if player.server_pass_request_ends_at > _server_time_seconds():
		return {
			"action": INTENT_FORWARD_RUN,
			"target_position": predicted_position,
			"target_peer_id": 0,
			"inferred": true
		}
	if player.server_is_charging:
		var aim_direction = movement
		if aim_direction.is_zero_approx():
			aim_direction = attack_direction
		var goal_target = Vector2(
			maximum_field_x if attack_sign > 0.0 else minimum_field_x,
			(minimum_field_y + maximum_field_y) * 0.5
		)
		var goal_alignment = aim_direction.dot(
			player.global_position.direction_to(goal_target)
		)
		var aimed_teammate: FootballPlayer
		var teammate_alignment = -1.0
		var player_team = (
			match_manager.blue_players
			if player.team == TEAM_BLUE
			else match_manager.red_players
		)
		for teammate in player_team:
			if (
				not is_instance_valid(teammate)
				or teammate == player
				or not teammate.controls_enabled
			):
				continue
			var alignment = aim_direction.dot(
				player.global_position.direction_to(teammate.global_position)
			)
			if alignment > teammate_alignment:
				teammate_alignment = alignment
				aimed_teammate = teammate
		if (
			aimed_teammate != null
			and teammate_alignment > goal_alignment + 0.12
			and teammate_alignment > 0.68
		):
			return {
				"action": INTENT_PASS,
				"target_position": aimed_teammate.global_position,
				"target_peer_id": aimed_teammate.owner_peer_id,
				"inferred": true
			}
		return {
			"action": INTENT_SHOOT,
			"target_position": goal_target,
			"target_peer_id": 0,
			"inferred": true
		}
	if ball_distance <= player.kick_feedback_detection_distance * 1.4:
		return {
			"action": INTENT_DRIBBLE,
			"target_position": (
				predicted_position
				+ attack_direction * dynamic_forward_distance * 0.65
			),
			"target_peer_id": 0,
			"inferred": true
		}
	var toward_ball = player.global_position.direction_to(ball.global_position)
	if (
		ball_distance < 1750.0
		and not movement.is_zero_approx()
		and movement.dot(toward_ball) > 0.42
	):
		return {
			"action": INTENT_CHASE,
			"target_position": ball.global_position,
			"target_peer_id": 0,
			"inferred": true
		}
	if not movement.is_zero_approx() and movement.dot(attack_direction) > 0.32:
		return {
			"action": INTENT_FORWARD_RUN,
			"target_position": predicted_position,
			"target_peer_id": 0,
			"inferred": true
		}
	if (
		(player.global_position.x - ball.global_position.x) * attack_sign
		< -420.0
	):
		return {
			"action": INTENT_COVER,
			"target_position": predicted_position,
			"target_peer_id": 0,
			"inferred": true
		}
	return {
		"action": INTENT_WIDE_SUPPORT,
		"target_position": predicted_position,
		"target_peer_id": 0,
		"inferred": true
	}


func _update_high_tempo_attack_reflex() -> bool:
	if (
		not high_tempo_thinking_enabled
		or controlled_player == null
		or ball == null
		or controlled_player.server_is_charging
		or not controlled_player.cpu_has_kickable_ball()
		or _ball_is_in_own_goal_danger()
		or not _team_likely_has_possession()
	):
		return false
	var secure_actor := _get_secure_team_ball_actor()
	if secure_actor != null and secure_actor != controlled_player:
		return false
	if controlled_player.selected_ability not in [
		FootballPlayer.ABILITY_POWER_STRIKE,
		FootballPlayer.ABILITY_QUICK_TRIGGER
	]:
		return false
	if (
		not _cpu_ability_is_ready()
		and not _has_active_ability(controlled_player.selected_ability)
	):
		return false
	var opponent_goal := _get_opponent_goal()
	if opponent_goal == null:
		return false
	return _try_execute_priority_attack_ability_teamplay(opponent_goal)


func _get_high_tempo_strength() -> float:
	if not high_tempo_thinking_enabled:
		return 0.0
	return clampf(
		inverse_lerp(0.55, 1.0, get_champion_utilization_ratio()),
		0.0,
		1.0
	)


func _get_high_tempo_plan_duration(
	base_seconds: float,
	elite_floor_seconds: float
) -> float:
	return lerpf(
		maxf(elite_floor_seconds, base_seconds),
		maxf(0.02, elite_floor_seconds),
		_get_high_tempo_strength()
	)


func _get_dynamic_pass_search_count(base_count: int) -> int:
	return maxi(
		base_count,
		base_count + int(round(
			float(maxi(0, high_tempo_extra_pass_plans))
			* _get_high_tempo_strength()
		))
	)


func _get_dynamic_goal_sample_count(base_count: int) -> int:
	var count := base_count + int(round(
		float(maxi(0, high_tempo_extra_goal_samples))
		* _get_high_tempo_strength()
	))
	if count % 2 == 0:
		count += 1
	return maxi(5, count)


func _update_decision() -> void:
	_set_tactical_intent(INTENT_IDLE, controlled_player.global_position)
	# Kickoff is a tiny deterministic state. Handle it before the general loose-ball,
	# duel, offense and defense planners so GO does not wake every expensive branch
	# at once in 4v4.
	if _update_competitive_kickoff_strategy():
		_movement_target = _clamp_to_field(_movement_target)
		_publish_tactical_intent()
		return
	_refresh_one_vs_one_context()
	_refresh_solo_attack_state()
	_refresh_duel_resolution_state()
	if _has_active_ability(FootballPlayer.ABILITY_OVERDRIVE):
		# Preserve a short finishing window after the speed effect expires. The
		# ball can arrive on the final frame of Overdrive, so checking only the
		# currently-active effect would discard the breakaway immediately.
		_overdrive_breakaway_window_until = (
			_server_time_seconds() + 1.2
		)
	if _try_execute_return_tag_return():
		_movement_target = _clamp_to_field(_movement_target)
		_publish_tactical_intent()
		return
	if match_manager.penalty_shootout_active:
		_clear_duel_resolution_state()
		_update_penalty_decision()
		_movement_target = _clamp_to_field(_movement_target)
		_publish_tactical_intent()
		return
	if _update_relative_loose_ball_claim_decision():
		_movement_target = _clamp_to_field(_movement_target)
		_publish_tactical_intent()
		return
	if _update_duel_resolution_decision():
		_movement_target = _clamp_to_field(_movement_target)
		_publish_tactical_intent()
		return
	if _update_active_one_vs_one_space_play():
		_movement_target = _clamp_to_field(_movement_target)
		_publish_tactical_intent()
		return
	if _update_active_wall_dribble_break():
		_movement_target = _clamp_to_field(_movement_target)
		_publish_tactical_intent()
		return
	var core_defense_has_priority = _core_defense_has_priority()
	var team_actor_requires_support := (
		not core_defense_has_priority
		and _team_ball_actor_requires_support()
	)
	if core_defense_has_priority:
		# Demonstrations are advisory attacking knowledge. They must never delay
		# goalkeeper positioning, a press assignment, or an emergency clearance.
		_clear_human_demo_plan(true)
		if _is_designated_goalkeeper(controlled_player):
			_update_goalkeeper_decision()
		else:
			_update_outfield_decision()
	elif team_actor_requires_support:
		_clear_human_demo_plan(true)
		_update_outfield_decision()
	elif _try_update_ai_v2_runtime_decision():
		pass
	elif _update_human_demonstration_decision():
		_ensure_non_idle_tactical_fallback()
		_movement_target = _clamp_to_field(_movement_target)
		_publish_tactical_intent()
		return
	elif _is_designated_goalkeeper(controlled_player):
		_update_goalkeeper_decision()
	else:
		_update_outfield_decision()
	_consider_cpu_pass_request()
	# Resolve any genuinely undecided legacy branch before ability evaluation.
	# This guarantees that an ability always competes *inside* one football job
	# instead of becoming the thing that invents a job for itself.
	_ensure_non_idle_tactical_fallback()
	# Ability use is now a candidate inside the tactical action that was just
	# selected. Give it first refusal before the normal SHOOT/PASS/ATTACK/DEFEND
	# executor claims authority, otherwise the ability subsystem can only fire by
	# racing another executor on a later frame.
	var ability_action_chosen := _consider_ability_use()
	if ability_action_chosen and _ability_executor_active:
		_movement_target = _clamp_to_field(_movement_target)
		_publish_tactical_intent()
		return
	if _try_claim_committed_shot_executor():
		_movement_target = _get_committed_strike_position(_shot_target)
		_movement_target = _clamp_to_field(_movement_target)
		_publish_tactical_intent()
		return
	_ensure_non_idle_tactical_fallback()
	_movement_target = _clamp_to_field(_movement_target)
	_publish_tactical_intent()


func _try_update_ai_v2_runtime_decision() -> bool:
	if _ai_v2_runtime == null or not _ai_v2_runtime.enabled:
		_ai_v2_last_reason = "disabled"
		_ai_v2_last_action.clear()
		return false
	var field_rect := Rect2(
		minimum_field_x,
		minimum_field_y,
		maximum_field_x - minimum_field_x,
		maximum_field_y - minimum_field_y
	)
	var proposal: Dictionary = _ai_v2_runtime.request_intent(
		match_manager,
		controlled_player,
		field_rect,
		_server_time_seconds(),
		_get_checkpoint_team_player_count()
	)
	_ai_v2_last_reason = str(proposal.get("reason", "rejected"))
	if not bool(proposal.get("accepted", false)):
		_ai_v2_last_action.clear()
		return false
	var action: Dictionary = proposal.get("action", {}) as Dictionary
	_ai_v2_last_action = action.duplicate(true)
	var opponent_goal: FootballGoal = _get_opponent_goal()
	if opponent_goal == null:
		_ai_v2_last_reason = "missing_opponent_goal"
		return false
	var kick_mode: int = int(action.get("kick_mode", 0))
	# V2 is advisory at the tactical layer. It may choose SHOOT/PASS and a
	# receiver, but it no longer dictates charge duration or raw kick power. The
	# committed executor calculates the legal physical delivery from live state.
	if kick_mode == 1:
		var shot_target: Vector2 = _get_best_live_direct_shot_target(
			opponent_goal
		)
		if shot_target.is_zero_approx():
			_ai_v2_last_reason = "shot_has_no_safe_goal_target"
			return false
		_elite_forced_charge_ratio = -1.0
		if not _execute_decisive_shot(shot_target):
			_ai_v2_last_reason = "shot_rejected_by_live_planner"
			return false
		if not controlled_player.server_is_charging:
			_elite_forced_charge_ratio = -1.0
		_ai_v2_last_reason = "executed_safe_shot"
		return true
	if kick_mode == 2:
		var receiver: FootballPlayer = _get_ai_v2_receiver(
			int(action.get("receiver_slot", 0))
		)
		if receiver == null:
			_ai_v2_last_reason = "pass_receiver_unavailable"
			return false
		var pass_plan: Dictionary = _get_ai_v2_pass_plan(
			receiver,
			opponent_goal
		)
		if pass_plan.is_empty():
			_ai_v2_last_reason = "pass_rejected_by_live_planner"
			return false
		_elite_forced_charge_ratio = -1.0
		if not _execute_decisive_pass(pass_plan, opponent_goal):
			_ai_v2_last_reason = "pass_execution_failed"
			return false
		if not controlled_player.server_is_charging:
			_elite_forced_charge_ratio = -1.0
		_ai_v2_last_reason = "executed_safe_pass"
		return true

	var move_direction: Vector2 = action.get("move", Vector2.ZERO)
	if move_direction.length_squared() <= 0.01:
		_ai_v2_last_reason = "neutral_action_fallback"
		return false
	_clear_attack_plan()
	_movement_target = _clamp_to_field(
		controlled_player.global_position
		+ move_direction.normalized() * 950.0
	)
	var ball_distance: float = controlled_player.global_position.distance_to(
		ball.global_position
	)
	var movement_intent: StringName = (
		INTENT_DRIBBLE
		if ball_distance <= controlled_player.kick_feedback_detection_distance * 1.35
		else INTENT_FORWARD_RUN
		if move_direction.x * _get_attack_sign() > 0.20
		else INTENT_WIDE_SUPPORT
	)
	_set_tactical_intent(movement_intent, _movement_target)
	if bool(action.get("pass_request", false)):
		controlled_player.cpu_request_pass()
	# ability_trigger is intentionally advisory only. The normal ability candidate
	# comparison runs immediately after this tactical choice and is the single
	# authority allowed to start an ability executor.
	_ai_v2_last_reason = "selected_safe_tactical_movement"
	return true


func _get_ai_v2_receiver(relative_slot: int) -> FootballPlayer:
	if relative_slot <= 0:
		return null
	var teammates: Array[FootballPlayer] = []
	for teammate: FootballPlayer in _get_teammates():
		if (
			is_instance_valid(teammate)
			and teammate != controlled_player
			and teammate.controls_enabled
		):
			teammates.append(teammate)
	teammates.sort_custom(func(first: FootballPlayer, second: FootballPlayer) -> bool:
		if first.team_slot != second.team_slot:
			if first.team_slot < 0:
				return false
			if second.team_slot < 0:
				return true
			return first.team_slot < second.team_slot
		return first.owner_peer_id < second.owner_peer_id
	)
	var index: int = relative_slot - 1
	return teammates[index] if index >= 0 and index < teammates.size() else null


func _get_ai_v2_pass_plan(
	receiver: FootballPlayer,
	opponent_goal: FootballGoal
) -> Dictionary:
	for plan: Dictionary in _get_ranked_team_pass_plans(
		opponent_goal,
		8,
		true
	):
		if int(plan.get("receiver_peer_id", 0)) == receiver.owner_peer_id:
			return plan.duplicate(true)
	var fallback: Dictionary = _build_best_direct_pass_fallback(opponent_goal)
	if int(fallback.get("receiver_peer_id", 0)) == receiver.owner_peer_id:
		return fallback
	return {}


func _core_defense_has_priority() -> bool:
	if _is_designated_goalkeeper(controlled_player):
		return true
	# A loose or opponent-controlled ball is handled by the deterministic
	# press/cover/final-role system. Human demonstrations resume once this team
	# has stable possession, so learned attacks cannot strand a defender.
	return not _team_likely_has_possession()


func _ensure_non_idle_tactical_fallback() -> void:
	if _tactical_intent_action != INTENT_IDLE:
		return
	_clear_attack_plan()
	if _core_defense_has_priority():
		_movement_target = _get_defensive_position()
		if _tactical_intent_action == INTENT_IDLE:
			_set_tactical_intent(INTENT_COVER, _movement_target)
		return
	var team_ball_actor := _get_team_ball_actor()
	if team_ball_actor != null:
		if team_ball_actor == controlled_player:
			_movement_target = ball.global_position
			_set_tactical_intent(INTENT_CHASE, _movement_target)
			return
		_movement_target = _get_attacking_support_position()
		_set_tactical_intent(INTENT_WIDE_SUPPORT, _movement_target)
		return
	if _is_primary_ball_chaser():
		_movement_target = ball.global_position
		_set_tactical_intent(INTENT_CHASE, _movement_target)
		return
	_movement_target = _get_attacking_support_position()
	_set_tactical_intent(INTENT_WIDE_SUPPORT, _movement_target)


func _update_human_demonstration_decision() -> bool:
	var learner = get_tree().root.get_node_or_null("HumanLearningManager")
	if learner == null or not learner.has_method("get_contextual_demonstration"):
		_clear_human_demo_plan()
		return false
	var context = match_manager._build_human_demo_snapshot(controlled_player)
	if context.is_empty():
		_clear_human_demo_plan()
		return false
	context["live_team"] = str(controlled_player.team)
	var now = _server_time_seconds()
	if _human_demo_plan.is_empty():
		if now < _human_demo_reuse_block_until:
			return false
		var selected = learner.call("get_contextual_demonstration", context) as Dictionary
		if selected.is_empty():
			return false
		var fingerprint = str(selected.get("fingerprint", ""))
		if fingerprint == _human_demo_last_fingerprint and now < _human_demo_reuse_block_until + 1.5:
			return false
		_human_demo_plan = selected
		_human_demo_plan_started_at = now
		_human_demo_action_index = 0
	var actions = _human_demo_plan.get("adapted_actions", []) as Array
	if actions.is_empty() or now - _human_demo_plan_started_at > 4.5:
		_clear_human_demo_plan(true)
		return false
	if not _human_demo_context_still_valid(context, _human_demo_plan.get("context", {}) as Dictionary):
		_clear_human_demo_plan(true)
		return false
	while _human_demo_action_index < actions.size():
		var action = actions[_human_demo_action_index] as Dictionary
		var due_at = maxf(0.0, float(action.get("dt", 0.0)))
		if now - _human_demo_plan_started_at + 0.04 < due_at:
			_movement_target = _demo_action_target(action)
			_set_tactical_intent(INTENT_WIDE_SUPPORT, _movement_target)
			return true
		var action_kind = str(action.get("kind", "movement"))
		if action_kind in ["movement", "reception", "recovery", "interception", "defense"]:
			var setup_target = _demo_action_target(action)
			if controlled_player.global_position.distance_to(setup_target) > maxf(70.0, target_tolerance):
				if not _execute_human_demo_action(action):
					_clear_human_demo_plan(true)
					return false
				return true
		if not _execute_human_demo_action(action):
			_clear_human_demo_plan(true)
			return false
		_human_demo_action_index += 1
		if controlled_player.server_is_charging:
			return true
	if _human_demo_action_index >= actions.size():
		_clear_human_demo_plan(true)
	return true


func _execute_human_demo_action(action: Dictionary) -> bool:
	var kind = str(action.get("kind", "movement"))
	var target = _demo_action_target(action)
	match kind:
		"movement", "reception", "recovery", "interception", "defense":
			if controlled_player.global_position.distance_to(target) > 2400.0:
				return false
			_movement_target = target
			_set_tactical_intent(INTENT_RECEIVE if kind == "reception" else INTENT_WIDE_SUPPORT, target)
			return true
		"ability":
			var ability_id = int(action.get("ability_id", 0))
			if ability_id <= 0 or controlled_player.selected_ability != ability_id or not _cpu_ability_is_ready():
				return false
			_movement_target = target
			_set_tactical_intent(INTENT_DRIBBLE, target)
			return _request_ability_action(
				ability_id,
				target,
				0,
				INTENT_DRIBBLE,
				ability_id,
				true
			)
		"kick", "pass":
			return _execute_human_demo_kick(action, target, kind == "pass")
	return false


func _execute_human_demo_kick(action: Dictionary, target: Vector2, is_pass: bool) -> bool:
	var attack_sign = _get_attack_sign()
	if (target.x - ball.global_position.x) * attack_sign < -220.0:
		return false
	if _minimum_segment_clearance(ball.global_position, target) < 85.0:
		return false
	var ball_distance = controlled_player.global_position.distance_to(ball.global_position)
	if ball_distance > maxf(shot_precharge_distance, controlled_player.kick_feedback_detection_distance * 1.45):
		return false
	_plan_is_pass = is_pass
	_planned_receiver = _nearest_demo_teammate_to(target) if is_pass else null
	if is_pass and not is_instance_valid(_planned_receiver):
		return false
	_set_planned_route(target, false, not is_pass)
	_movement_target = _get_strike_position(target)
	_set_tactical_intent(INTENT_PASS if is_pass else INTENT_SHOOT, target, _planned_receiver.owner_peer_id if is_instance_valid(_planned_receiver) else 0)
	_try_begin_shot(false)
	if controlled_player.server_is_charging:
		var demonstrated_charge = clampf(float(action.get("charge", _desired_charge_seconds)), 0.05, controlled_player.cpu_get_maximum_shot_charge_seconds())
		_desired_charge_seconds = demonstrated_charge
		return true
	return controlled_player.cpu_has_kickable_ball()


func _human_demo_context_still_valid(live: Dictionary, source: Dictionary) -> bool:
	if str(live.get("possession", "loose")) != str(source.get("possession", "loose")):
		return false
	var source_ability = int(source.get("ability_id", 0))
	if source_ability > 0 and controlled_player.selected_ability != source_ability:
		return false
	var live_ball = live.get("ball", []) as Array
	var source_ball = source.get("ball", []) as Array
	if live_ball.size() < 2 or source_ball.size() < 2:
		return false
	return Vector2(float(live_ball[0]), float(live_ball[1])).distance_to(Vector2(float(source_ball[0]), float(source_ball[1]))) <= 0.24


func _demo_action_target(action: Dictionary) -> Vector2:
	var normalized = action.get("target", [0.5, 0.5]) as Array
	if normalized.size() < 2:
		return controlled_player.global_position
	var x = clampf(float(normalized[0]), 0.0, 1.0)
	var y = clampf(float(normalized[1]), 0.0, 1.0)
	if controlled_player.team == TEAM_RED:
		x = 1.0 - x
	return Vector2(lerpf(minimum_field_x, maximum_field_x, x), lerpf(minimum_field_y, maximum_field_y, y))


func _nearest_demo_teammate_to(target: Vector2) -> FootballPlayer:
	var roster = match_manager.blue_players if controlled_player.team == TEAM_BLUE else match_manager.red_players
	var best: FootballPlayer
	var best_distance = INF
	for teammate in roster:
		if teammate == controlled_player or not is_instance_valid(teammate) or not teammate.controls_enabled:
			continue
		var distance = teammate.global_position.distance_to(target)
		if distance < best_distance:
			best_distance = distance
			best = teammate
	return best if best_distance <= 1000.0 else null


func _clear_human_demo_plan(block_reuse: bool = false) -> void:
	if not _human_demo_plan.is_empty():
		_human_demo_last_fingerprint = str(_human_demo_plan.get("fingerprint", ""))
	_human_demo_plan.clear()
	_human_demo_action_index = 0
	if block_reuse:
		_human_demo_reuse_block_until = _server_time_seconds() + 1.25


func _update_penalty_decision() -> void:
	if controlled_player.owner_peer_id == match_manager.penalty_kicker_peer_id:
		_update_penalty_kicker_decision()
		return
	if (
		controlled_player.owner_peer_id
		== match_manager.penalty_goalkeeper_peer_id
	):
		_update_penalty_goalkeeper_decision()
		return
	_movement_target = controlled_player.global_position


func _update_penalty_kicker_decision() -> void:
	var opponent_goal = _get_opponent_goal()
	if opponent_goal == null:
		_movement_target = ball.global_position
		return
	if _penalty_attempt_serial != match_manager.penalty_attempt_serial:
		_penalty_attempt_serial = match_manager.penalty_attempt_serial
		_penalty_shot_target = _pick_penalty_shot_target(opponent_goal)
	elif not controlled_player.server_is_charging:
		_retarget_penalty_away_from_committed_keeper(opponent_goal)
	_shot_target = _penalty_shot_target
	_planned_destination = _shot_target
	_planned_route_distance = ball.global_position.distance_to(_shot_target)
	_plan_is_pass = false
	_planned_receiver = null
	_movement_target = _get_strike_position(_shot_target)
	_set_tactical_intent(INTENT_SHOOT, _shot_target)
	if (
		_cpu_ability_is_ready()
		and controlled_player.selected_ability in [
			FootballPlayer.ABILITY_QUICK_TRIGGER,
			FootballPlayer.ABILITY_POWER_STRIKE,
			FootballPlayer.ABILITY_OVERDRIVE,
			FootballPlayer.ABILITY_META_VISION
		]
	):
		_request_ability_action(
			controlled_player.selected_ability,
			_shot_target,
			0,
			INTENT_SHOOT,
			controlled_player.selected_ability,
			true
		)
	_try_begin_shot(false)


func _pick_penalty_shot_target(opponent_goal: FootballGoal) -> Vector2:
	var mouth_range := opponent_goal.get_mouth_y_range()
	var mouth_height := maxf(1.0, mouth_range.y - mouth_range.x)
	var margin := minf(
		maxf(55.0, penalty_aim_post_margin),
		maxf(55.0, mouth_height * 0.34)
	)
	var minimum_y := mouth_range.x + margin
	var maximum_y := mouth_range.y - margin
	if maximum_y <= minimum_y:
		return Vector2(opponent_goal.get_goal_plane_x(), (mouth_range.x + mouth_range.y) * 0.5)

	var target_y: float
	if _rng.randf() <= clampf(penalty_corner_bias, 0.0, 1.0):
		var corner_band := minf(
			maxf(0.0, penalty_corner_band_width),
			(maximum_y - minimum_y) * 0.28
		)
		var aim_top := _rng.randi_range(0, 1) == 0
		if aim_top:
			target_y = minimum_y + _rng.randf_range(0.0, corner_band)
		else:
			target_y = maximum_y - _rng.randf_range(0.0, corner_band)
	else:
		# Keep a smaller number of less extreme penalties so the CPU is dangerous
		# without becoming a deterministic corner-shot machine.
		target_y = _rng.randf_range(minimum_y, maximum_y)

	return Vector2(opponent_goal.get_goal_plane_x(), target_y)


func _retarget_penalty_away_from_committed_keeper(
	opponent_goal: FootballGoal
) -> void:
	var goalkeeper := _get_penalty_goalkeeper()
	if goalkeeper == null or not is_instance_valid(goalkeeper):
		return
	var mouth_range := opponent_goal.get_mouth_y_range()
	var center_y := (mouth_range.x + mouth_range.y) * 0.5
	var keeper_offset := goalkeeper.global_position.y - center_y
	if absf(keeper_offset) < maxf(0.0, penalty_goalkeeper_commit_distance):
		return
	var target_offset := _penalty_shot_target.y - center_y
	if is_zero_approx(target_offset) or signf(target_offset) != signf(keeper_offset):
		return

	# If the goalkeeper guesses before the kick is committed, switch to the
	# opposite corner. Once charge begins the target is locked, so a late/reactive
	# save still has a fair chance.
	var mouth_height := maxf(1.0, mouth_range.y - mouth_range.x)
	var margin := minf(
		maxf(55.0, penalty_aim_post_margin),
		maxf(55.0, mouth_height * 0.34)
	)
	var minimum_y := mouth_range.x + margin
	var maximum_y := mouth_range.y - margin
	var corner_band := minf(
		maxf(0.0, penalty_corner_band_width),
		maxf(0.0, (maximum_y - minimum_y) * 0.28)
	)
	_penalty_shot_target.y = (
		minimum_y + _rng.randf_range(0.0, corner_band)
		if keeper_offset > 0.0
		else maximum_y - _rng.randf_range(0.0, corner_band)
	)


func _get_penalty_goalkeeper() -> FootballPlayer:
	if match_manager == null:
		return null
	var goalkeeper_peer_id := int(match_manager.penalty_goalkeeper_peer_id)
	if goalkeeper_peer_id <= 0:
		return null
	for opponent in _get_opponents():
		if (
			is_instance_valid(opponent)
			and opponent.owner_peer_id == goalkeeper_peer_id
		):
			return opponent
	return null


func _is_active_penalty_kicker() -> bool:
	return (
		match_manager != null
		and match_manager.penalty_shootout_active
		and match_manager.penalty_attempt_active
		and controlled_player != null
		and controlled_player.owner_peer_id == match_manager.penalty_kicker_peer_id
	)


func _update_penalty_goalkeeper_decision() -> void:
	var own_goal = _get_own_goal()
	if own_goal == null:
		_movement_target = controlled_player.global_position
		return
	var mouth_range = own_goal.get_mouth_y_range()
	var predicted_y = (
		ball.global_position.y
		+ ball.linear_velocity.y
		* maxf(0.0, penalty_goalkeeper_prediction)
	)
	_movement_target = Vector2(
		controlled_player.global_position.x,
		clampf(predicted_y, mouth_range.x, mouth_range.y)
	)
	_set_tactical_intent(INTENT_GOALKEEP, _movement_target)
	if (
		ball.linear_velocity.length() > 650.0
		and _cpu_ability_is_ready()
		and controlled_player.selected_ability in [
			FootballPlayer.ABILITY_GOALKEEPER_REACH,
			FootballPlayer.ABILITY_REFLEX_BLOCK,
			FootballPlayer.ABILITY_IRON_ANCHOR,
			FootballPlayer.ABILITY_META_VISION
		]
	):
		_request_ability_action(
			controlled_player.selected_ability,
			_movement_target,
			0,
			INTENT_GOALKEEP,
			controlled_player.selected_ability,
			true
		)


func _update_outfield_decision() -> void:
	var opponent_goal = _get_opponent_goal()
	if opponent_goal == null:
		_movement_target = ball.global_position
		_set_tactical_intent(INTENT_CHASE, _movement_target)
		return
	var announced_receive_intention = match_manager.get_cpu_pass_intention(
		controlled_player.owner_peer_id
	)
	var receive_intention = _get_live_receive_intention(
		announced_receive_intention
	)
	var trap_volley_combo = _get_trap_or_volley_combo_plan()
	var is_trap_volley_combo_receiver = (
		not trap_volley_combo.is_empty()
		and int(trap_volley_combo.get("receiver_peer_id", 0))
		== controlled_player.owner_peer_id
	)
	if (
		is_trap_volley_combo_receiver
		and not announced_receive_intention.is_empty()
		and receive_intention.is_empty()
	):
		# The announced stopping point can no longer be reached. Cancel the
		# paired action instead of letting this receiver chase a stale pass.
		_cancel_trap_or_volley_combo_plan()
		trap_volley_combo = {}
		is_trap_volley_combo_receiver = false
	if _update_overdrive_dead_zone_runner():
		# This receiver has been assigned a through-ball run. Keep it out of the
		# normal chase/support branches until the named plan is completed or
		# cancelled.
		return
	if _update_goalkeeper_rebound_follower(opponent_goal):
		# A rebound follower must not peel toward the initial shot. It owns only
		# the predicted collection point until the save actually occurs.
		return
	if receive_intention.is_empty():
		receive_intention = _get_detected_pass_reception()
	var team_has_possession := _team_likely_has_possession()
	var team_ball_actor := _get_team_ball_actor()
	var owns_team_ball_action := (
		not team_ball_actor_enabled
		or team_ball_actor == null
		or team_ball_actor == controlled_player
	)
	var opponent_has_control := _opponent_has_live_ball_control()
	var large_team_controlled_defense := (
		is_large_team_football_shape_active()
		and not team_has_possession
		and opponent_has_control
	)
	var primary_ball_chaser := false
	if large_team_controlled_defense:
		# Do not run the generic nearest-ball arbitration first and then overwrite
		# it. In 4v4+ the shared defensive assignment already owns this decision.
		# Skipping the redundant team scan matters when 10-12 CPUs think together.
		var large_team_defense_assignment: Dictionary = (
			match_manager.get_cpu_defensive_assignment(
				controlled_player.team,
				controlled_player.owner_peer_id
			)
		)
		primary_ball_chaser = (
			StringName(large_team_defense_assignment.get("role", &""))
			== &"press"
		)
	else:
		primary_ball_chaser = (
			team_ball_actor == controlled_player
			if team_ball_actor != null and not opponent_has_control
			else _is_primary_ball_chaser()
		)
	_update_off_ball_possession_transition(team_has_possession)
	if not team_has_possession:
		_planned_support_until = 0.0
		_planned_support_position = Vector2.ZERO
		_planned_support_intent = INTENT_IDLE
	var requested_receiver = _get_active_pass_request_receiver()
	if (
		requested_receiver != null
		and requested_receiver.cpu_controlled
		and _get_ai_skill() >= elite_combination_minimum_skill
	):
		var active_combination = match_manager.get_cpu_combination_plan(
			controlled_player.team
		)
		if (
			not active_combination.is_empty()
			and int(active_combination.get("receiver_peer_id", 0))
			== controlled_player.owner_peer_id
		):
			requested_receiver = null
	if (
		primary_ball_chaser
		and _ball_is_in_own_goal_danger()
		and (
			not _is_true_one_vs_one()
			or _one_vs_one_requires_emergency_defense()
		)
	):
		_update_emergency_clearance()
	elif _prepare_trap_or_volley_reception(
		receive_intention,
		opponent_goal
	):
		pass
	elif (
		not receive_intention.is_empty()
		and not controlled_player.server_is_charging
	):
		if _try_prepare_elite_combination_relay(receive_intention):
			pass
		elif _prepare_cpu_first_touch_reception(
			receive_intention,
			opponent_goal
		):
			pass
		else:
			_clear_attack_plan()
			_movement_target = receive_intention.get(
				"position",
				controlled_player.global_position
			)
			_set_tactical_intent(
				INTENT_RECEIVE,
				_movement_target,
				int(receive_intention.get("passer_peer_id", 0))
			)
	elif (
		owns_team_ball_action
		and controlled_player.cpu_has_kickable_ball()
		and _try_execute_fast_finish(opponent_goal)
	):
		# A clear direct goal is more valuable than an optional request, combo,
		# dribble or Enforcer pressure play. Take it before lower-value branches.
		pass
	elif (
		_has_active_ability(FootballPlayer.ABILITY_ENFORCER)
		and (team_has_possession or primary_ball_chaser)
		and (
			not is_large_team_football_shape_active()
			or primary_ball_chaser
			or owns_team_ball_action
		)
	):
		_clear_attack_plan()
		_movement_target = _get_enforcer_pressure_position()
		_set_tactical_intent(
			INTENT_ENFORCE,
			_movement_target,
			_enforcer_target.owner_peer_id
			if is_instance_valid(_enforcer_target)
			else 0
		)
		_try_enforcer_kick()
	elif (
		owns_team_ball_action
		and controlled_player.cpu_has_kickable_ball()
		and requested_receiver != null
		and _try_execute_requested_pass_fast(requested_receiver)
	):
		pass
	elif (
		owns_team_ball_action
		and controlled_player.cpu_has_kickable_ball()
		and _try_execute_priority_attack_ability_teamplay(opponent_goal)
	):
		pass
	elif (
		owns_team_ball_action
		and controlled_player.cpu_has_kickable_ball()
		and _try_execute_shared_team_sequence(opponent_goal)
	):
		pass
	elif (
		owns_team_ball_action
		and controlled_player.cpu_has_kickable_ball()
		and _try_execute_large_team_release_pass(opponent_goal)
	):
		pass
	elif (
		owns_team_ball_action
		and controlled_player.cpu_has_kickable_ball()
		and _try_execute_decisive_possession_action(opponent_goal)
	):
		pass
	elif (
		owns_team_ball_action
		and controlled_player.cpu_has_kickable_ball()
		and _try_execute_obvious_team_pass(opponent_goal)
	):
		pass
	elif (
		team_has_possession
		and not owns_team_ball_action
		and _update_large_team_attacking_shape()
	):
		pass
	elif (
		not team_has_possession
		and not primary_ball_chaser
		and _update_large_team_non_chaser_shape()
	):
		pass
	elif (
		team_has_possession
		and primary_ball_chaser
		and _try_resolve_possession_deadlock(opponent_goal)
	):
		pass
	elif (
		owns_team_ball_action
		and controlled_player.cpu_has_kickable_ball()
		and _try_execute_value_attacking_plan(opponent_goal)
	):
		pass
	elif (
		not team_has_possession
		and _update_ability_aware_defense()
	):
		pass
	elif (
		not team_has_possession
		and _update_off_ball_transition_recovery(
			primary_ball_chaser
		)
	):
		pass
	elif (
		hybrid_tactical_policy_enabled
		and _hybrid_tactical_adapter != null
		and (not team_has_possession or owns_team_ball_action)
		and _hybrid_tactical_adapter.try_handle_outfield_decision()
	):
		if hybrid_debug_logging:
			var hybrid_state: Dictionary = _hybrid_tactical_adapter.get_debug_state()
			if bool(hybrid_state.get("fallback_active", false)):
				print("HYBRID CPU fallback: ", hybrid_state.get("fallback_reason", ""))
	elif not team_has_possession:
		# Defending is team-owned. Bypassing the shared roles here made every
		# nearby CPU chase the same stale point behind the carrier.
		if controlled_player.server_is_charging:
			controlled_player.cpu_cancel_shot_charge()
			_reset_cpu_charge_tracking()
		_clear_attack_plan()
		if not _update_anticipatory_carrier_defense():
			_movement_target = _get_defensive_position()
			_try_defensive_ball_win()
	elif primary_ball_chaser and owns_team_ball_action:
		if _update_overdrive_breakaway_finish(opponent_goal):
			pass
		elif _try_execute_elite_finish_scan(
			opponent_goal,
			true
		):
			pass
		elif _try_begin_one_vs_one_space_play(
			opponent_goal,
			false
		):
			_update_one_vs_one_space_play()
			_set_tactical_intent(
				INTENT_DRIBBLE,
				_shot_target
			)
		elif (
			_server_time_seconds() < _solo_attack_until
			and _should_dribble(opponent_goal)
		):
			_clear_attack_plan()
			_update_dribble(opponent_goal)
			_set_tactical_intent(INTENT_DRIBBLE, _shot_target)
		elif requested_receiver != null:
			_follow_pass_request(requested_receiver)
			_set_tactical_intent(
				INTENT_PASS,
				_shot_target,
				requested_receiver.owner_peer_id
			)
		elif _try_setup_mirage_step():
			pass
		elif _try_break_contested_ball_brawl(opponent_goal):
			pass
		elif _should_yield_contested_ball():
			_clear_attack_plan()
			_movement_target = _get_contest_angle_position()
		elif _should_dribble(opponent_goal):
			_clear_attack_plan()
			_update_dribble(opponent_goal)
			_set_tactical_intent(INTENT_DRIBBLE, _shot_target)
		else:
			var attack_plan_ready = _update_attack_plan(opponent_goal)
			if not attack_plan_ready:
				_update_dribble(opponent_goal)
				_set_tactical_intent(INTENT_DRIBBLE, _shot_target)
			else:
				_movement_target = _get_strike_position(_shot_target)
				var instant_ability_used = _activate_planned_ball_ability()
				if (
					not instant_ability_used
					and not _is_waiting_for_overdrive_dead_zone_runner()
				):
					_try_begin_shot(false)
				_set_tactical_intent(
					INTENT_PASS if _plan_is_pass else INTENT_SHOOT,
					_shot_target,
					_planned_receiver.owner_peer_id
					if is_instance_valid(_planned_receiver)
					else 0
				)
	elif team_has_possession:
		_clear_attack_plan()
		_movement_target = _get_attacking_support_position()
		if _tactical_intent_action == INTENT_IDLE:
			_set_tactical_intent(INTENT_WIDE_SUPPORT, _movement_target)
	else:
		_clear_attack_plan()
		_movement_target = _get_defensive_position()


func _large_team_push_target_away_from_ball(
	target: Vector2,
	minimum_distance: float
) -> Vector2:
	if not is_instance_valid(ball):
		return _clamp_to_field(target)
	var predicted_ball := _get_predicted_ball_position()
	if predicted_ball.is_zero_approx():
		predicted_ball = ball.global_position
	var offset := target - predicted_ball
	if offset.length() >= minimum_distance:
		return _clamp_to_field(target)
	if offset.is_zero_approx():
		var role := get_large_team_football_role(controlled_player)
		var lane_sign := -1.0 if controlled_player.team_slot % 2 == 0 else 1.0
		offset = Vector2(-_get_attack_sign(), lane_sign)
		if role in [LARGE_TEAM_ROLE_WINGER, LARGE_TEAM_ROLE_STRIKER]:
			offset.x = _get_attack_sign() * 0.35
	return _clamp_to_field(
		predicted_ball + offset.normalized() * minimum_distance
	)


func _get_large_team_attacking_fallback_position(
	carrier: FootballPlayer
) -> Vector2:
	if not is_instance_valid(carrier):
		return _get_large_team_defensive_zone_position(controlled_player)
	var attack_sign := _get_attack_sign()
	var role := get_large_team_football_role(controlled_player)
	var center_y := (minimum_field_y + maximum_field_y) * 0.5
	var lane_y := center_y + _get_large_team_role_lane_offset(
		controlled_player,
		role
	)
	var depth := -520.0
	match role:
		LARGE_TEAM_ROLE_DEFENDER:
			depth = -1250.0
		LARGE_TEAM_ROLE_MIDFIELDER:
			depth = -520.0
		LARGE_TEAM_ROLE_WINGER:
			depth = 260.0
		LARGE_TEAM_ROLE_STRIKER:
			depth = 980.0
	var target := Vector2(
		carrier.global_position.x + attack_sign * depth,
		lane_y
	)
	return _large_team_push_target_away_from_ball(
		target,
		maxf(620.0, large_team_minimum_support_spacing)
	)


func _update_large_team_attacking_shape() -> bool:
	if (
		not large_team_shape_discipline_enabled
		or not is_large_team_football_shape_active()
		or not _team_likely_has_possession()
	):
		return false
	var carrier := _get_likely_team_ball_carrier()
	if carrier == null or carrier == controlled_player:
		return false
	if controlled_player.server_is_charging:
		controlled_player.cpu_cancel_shot_charge()
		_reset_cpu_charge_tracking()
	_clear_attack_plan()
	var parallel_plan := _get_large_team_parallel_plan()
	if (
		not parallel_plan.is_empty()
		and bool(parallel_plan.get("shape_valid", false))
		and StringName(parallel_plan.get("shape_phase", &"")) == &"attack"
	):
		var parallel_target: Vector2 = parallel_plan.get("shape_target", Vector2.ZERO)
		if not parallel_target.is_zero_approx():
			_movement_target = _clamp_to_field(parallel_target)
			_set_tactical_intent(
				StringName(parallel_plan.get("shape_intent", INTENT_WIDE_SUPPORT)),
				_movement_target,
				int(parallel_plan.get("shape_target_peer_id", carrier.owner_peer_id))
			)
			return true
	var assignment := _get_team_play_support_assignment()
	var target := Vector2.ZERO
	var intent := INTENT_WIDE_SUPPORT
	var target_peer_id := carrier.owner_peer_id
	if not assignment.is_empty():
		target = assignment.get("position", Vector2.ZERO)
		intent = StringName(assignment.get("intent", INTENT_WIDE_SUPPORT))
	if target.is_zero_approx():
		target = _get_large_team_attacking_fallback_position(carrier)
	target = _large_team_push_target_away_from_ball(
		target,
		maxf(620.0, large_team_non_chaser_ball_clearance)
	)
	_movement_target = target
	_set_tactical_intent(intent, target, target_peer_id)
	return true


func _get_large_team_second_ball_supporter_peer_id() -> int:
	if not is_large_team_football_shape_active() or not is_instance_valid(ball):
		return 0
	var now := _server_time_seconds()
	var committed_chaser := int(match_manager.get_cpu_ball_chaser(
		controlled_player.team
	))
	if (
		now < _large_team_second_ball_cache_until
		and committed_chaser == _large_team_second_ball_cached_chaser_peer_id
	):
		return _large_team_second_ball_cached_peer_id
	var predicted_ball := _get_predicted_ball_position()
	if predicted_ball.is_zero_approx():
		predicted_ball = ball.global_position
	var attack_sign := _get_attack_sign()
	var anchor := predicted_ball - Vector2(
		attack_sign * maxf(700.0, large_team_second_ball_distance),
		0.0
	)
	var best_peer_id := 0
	var best_score := INF
	var assignments := _get_large_team_formation_assignments()
	for teammate: FootballPlayer in _get_large_team_cpu_outfield_roster():
		if teammate.owner_peer_id == committed_chaser:
			continue
		var role := StringName(assignments.get(
			teammate.owner_peer_id,
			_get_large_team_natural_role(teammate)
		))
		var score := teammate.global_position.distance_to(anchor)
		match role:
			LARGE_TEAM_ROLE_MIDFIELDER:
				score -= 280.0
			LARGE_TEAM_ROLE_WINGER:
				score -= 90.0
			LARGE_TEAM_ROLE_DEFENDER:
				score += 220.0
			LARGE_TEAM_ROLE_STRIKER:
				score += 80.0
		if score < best_score:
			best_score = score
			best_peer_id = teammate.owner_peer_id
	_large_team_second_ball_cached_chaser_peer_id = committed_chaser
	_large_team_second_ball_cached_peer_id = best_peer_id
	_large_team_second_ball_cache_until = (
		now + maxf(0.04, large_team_second_ball_cache_seconds)
	)
	return best_peer_id


func _get_large_team_loose_shape_position() -> Vector2:
	var predicted_ball := _get_predicted_ball_position()
	if predicted_ball.is_zero_approx():
		predicted_ball = ball.global_position
	var second_ball_peer_id := _get_large_team_second_ball_supporter_peer_id()
	if second_ball_peer_id == controlled_player.owner_peer_id:
		var lane_sign := -1.0 if controlled_player.team_slot % 2 == 0 else 1.0
		var second_target := predicted_ball + Vector2(
			-_get_attack_sign() * maxf(700.0, large_team_second_ball_distance),
			lane_sign * 420.0
		)
		return _large_team_push_target_away_from_ball(
			second_target,
			maxf(620.0, large_team_non_chaser_ball_clearance)
		)
	var zone_target := _get_large_team_defensive_zone_position(controlled_player)
	if zone_target.is_zero_approx():
		zone_target = controlled_player.global_position
	return _large_team_push_target_away_from_ball(
		zone_target,
		maxf(680.0, large_team_non_chaser_ball_clearance)
	)


func _update_large_team_non_chaser_shape() -> bool:
	if (
		not large_team_shape_discipline_enabled
		or not is_large_team_football_shape_active()
		or _ball_is_in_own_goal_danger()
	):
		return false
	if controlled_player.server_is_charging:
		controlled_player.cpu_cancel_shot_charge()
		_reset_cpu_charge_tracking()
	_clear_attack_plan()
	var parallel_plan := _get_large_team_parallel_plan()
	if (
		not parallel_plan.is_empty()
		and bool(parallel_plan.get("shape_valid", false))
		and StringName(parallel_plan.get("shape_phase", &"")) in [&"defense", &"loose"]
	):
		var parallel_target: Vector2 = parallel_plan.get("shape_target", Vector2.ZERO)
		if not parallel_target.is_zero_approx():
			_movement_target = _clamp_to_field(parallel_target)
			_set_tactical_intent(
				StringName(parallel_plan.get("shape_intent", INTENT_COVER)),
				_movement_target,
				int(parallel_plan.get("shape_target_peer_id", 0))
			)
			return true
	var target := Vector2.ZERO
	var intent := INTENT_COVER
	var target_peer_id := 0
	if _opponent_has_live_ball_control():
		var assignment: Dictionary = match_manager.get_cpu_defensive_assignment(
			controlled_player.team,
			controlled_player.owner_peer_id
		)
		if not assignment.is_empty():
			target = resolve_cpu_defensive_assignment_target(assignment)
			target_peer_id = int(assignment.get("target_peer_id", 0))
			var role := StringName(assignment.get("role", &"cover"))
			if role == &"mark":
				intent = INTENT_MARK
			elif role == &"final":
				intent = INTENT_COVER
	if target.is_zero_approx():
		target = _get_large_team_loose_shape_position()
		intent = (
			INTENT_RECEIVE
			if _get_large_team_second_ball_supporter_peer_id()
			== controlled_player.owner_peer_id
			else INTENT_COVER
		)
	_movement_target = target
	_set_tactical_intent(intent, target, target_peer_id)
	return true


func _count_large_team_crowd_near_ball(radius: float) -> int:
	if not is_instance_valid(ball):
		return 0
	var count := 0
	for teammate: FootballPlayer in _get_teammates():
		if (
			is_instance_valid(teammate)
			and teammate.controls_enabled
			and teammate != controlled_player
			and teammate.global_position.distance_to(ball.global_position) <= radius
		):
			count += 1
	for opponent: FootballPlayer in _get_opponents():
		if (
			is_instance_valid(opponent)
			and opponent.controls_enabled
			and opponent.global_position.distance_to(ball.global_position) <= radius
		):
			count += 1
	return count


func _try_execute_large_team_release_pass(
	opponent_goal: FootballGoal
) -> bool:
	if (
		not large_team_shape_discipline_enabled
		or not is_large_team_football_shape_active()
		or opponent_goal == null
		or not controlled_player.cpu_has_kickable_ball()
		or controlled_player.server_is_charging
		or _ball_is_in_own_goal_danger()
	):
		return false
	var goal_center := _get_goal_center(opponent_goal)
	var goal_distance := ball.global_position.distance_to(goal_center)
	if goal_distance <= 1350.0:
		var shot_target := _get_best_live_direct_shot_target(opponent_goal)
		if not shot_target.is_zero_approx() and _shot_target_is_viable(shot_target):
			return false
	var pressure := _nearest_opponent_distance(ball.global_position)
	var crowd_count := _count_large_team_crowd_near_ball(
		maxf(520.0, large_team_release_pass_crowd_radius)
	)
	var should_release := (
		pressure <= maxf(520.0, large_team_release_pass_pressure_radius)
		or crowd_count >= 2
	)
	# The generic possession planner below this branch already evaluates passes
	# in open play. The anti-brawl scan only needs to exist when there is an
	# actual crowd/pressure trigger; doing another full ranked pass search every
	# elite decision was duplicate work and caused 4v4-6v6 frame spikes.
	if not should_release:
		return false
	var now := _server_time_seconds()
	if now < _next_large_team_release_pass_scan_at:
		return false
	_next_large_team_release_pass_scan_at = (
		now + maxf(0.05, large_team_release_pass_scan_seconds)
	)
	var plans := _get_ranked_team_pass_plans(
		opponent_goal,
		_get_dynamic_pass_search_count(10),
		true
	)
	var direct_fallback := _build_best_direct_pass_fallback(opponent_goal)
	if not direct_fallback.is_empty():
		plans.append(direct_fallback)
	var best_plan: Dictionary = {}
	var best_score := -INF
	for plan_variant in plans:
		if not plan_variant is Dictionary:
			continue
		var plan := plan_variant as Dictionary
		if not _team_pass_plan_is_acceptable(plan):
			continue
		var receiver := _get_teammate_by_peer_id(
			int(plan.get("receiver_peer_id", 0))
		)
		if receiver == null or receiver == controlled_player:
			continue
		var quality := float(plan.get("quality", 0.0))
		var clearance := float(plan.get("route_clearance", 0.0))
		var openness := float(plan.get("openness", 0.0))
		var interception_margin := float(plan.get("interception_margin", -2.0))
		var receiver_margin := float(plan.get("receiver_margin", -2.0))
		if (
			quality < 0.52
			or clearance < 125.0
			or openness < 250.0
			or interception_margin < -0.02
			or receiver_margin < -0.06
		):
			continue
		var progress := float(plan.get("forward_progress", 0.0))
		var lateral_separation := absf(
			receiver.global_position.y - ball.global_position.y
		)
		var receiver_distance := receiver.global_position.distance_to(
			ball.global_position
		)
		var score := (
			quality * 980.0
			+ minf(clearance, 1200.0) * 0.30
			+ minf(openness, 1400.0) * 0.26
			+ clampf(interception_margin, -0.1, 0.8) * 390.0
			+ clampf(receiver_margin, -0.1, 0.8) * 230.0
			+ maxf(0.0, progress) * 0.18
			+ minf(lateral_separation, 1500.0) * 0.12
			+ minf(receiver_distance, 1800.0) * 0.07
			+ _get_large_team_pass_tactical_bonus(plan, receiver)
		)
		if score > best_score:
			best_score = score
			best_plan = plan.duplicate(true)
	if best_plan.is_empty():
		return false
	if not _apply_team_pass_plan(
		best_plan,
		opponent_goal,
		_server_time_seconds()
	):
		return false
	if _hybrid_tactical_adapter != null:
		_hybrid_tactical_adapter.clear_active_decision()
	_movement_target = _get_strike_position(_shot_target)
	_set_tactical_intent(
		INTENT_PASS,
		_planned_destination,
		_planned_receiver.owner_peer_id
		if is_instance_valid(_planned_receiver)
		else 0
	)
	_try_begin_shot(false)
	if controlled_player.server_is_charging:
		_desired_charge_seconds = maxf(
			0.09,
			_desired_charge_seconds
			* clampf(obvious_pass_charge_multiplier, 0.3, 1.0)
		)
	return true


func _update_off_ball_possession_transition(
	team_has_possession: bool
) -> void:
	if not explicit_off_ball_movement_enabled:
		_off_ball_team_had_possession = team_has_possession
		_off_ball_transition_recovery_until = 0.0
		return
	if team_has_possession:
		_off_ball_team_had_possession = true
		_off_ball_transition_recovery_until = 0.0
		return
	if not _off_ball_team_had_possession:
		return
	_off_ball_team_had_possession = false
	_off_ball_transition_previous_role = _last_off_ball_role
	_off_ball_transition_recovery_until = (
		_server_time_seconds()
		+ maxf(0.2, off_ball_transition_recovery_seconds)
	)


func _update_off_ball_transition_recovery(
	primary_ball_chaser: bool
) -> bool:
	if (
		not explicit_off_ball_movement_enabled
		or primary_ball_chaser
		or _server_time_seconds()
		>= _off_ball_transition_recovery_until
		or _ball_is_in_own_goal_danger()
		or not _predict_own_goal_threat(1.45).is_empty()
	):
		return false
	var own_goal := _get_own_goal()
	if own_goal == null:
		return false
	var goal_center := _get_goal_center(own_goal)
	var attack_sign := _get_attack_sign()
	var center_y := (minimum_field_y + maximum_field_y) * 0.5
	var recovery_x := (
		ball.global_position.x
		- attack_sign * maxf(300.0, off_ball_transition_ball_depth)
	)
	var advanced_role := _off_ball_transition_previous_role in [
		&"run_behind",
		&"decoy",
		&"far_post",
		&"rebound"
	]
	if advanced_role:
		recovery_x -= (
			attack_sign
			* maxf(0.0, off_ball_transition_advanced_extra_depth)
		)
	var goal_side_limit := goal_center.x + attack_sign * 520.0
	if attack_sign > 0.0:
		recovery_x = maxf(recovery_x, goal_side_limit)
	else:
		recovery_x = minf(recovery_x, goal_side_limit)
	var lane_index := _get_off_ball_recovery_lane_index()
	var lane_offset := float(lane_index) * maxf(
		220.0,
		off_ball_transition_lane_spacing
	)
	var recovery_y := clampf(
		center_y + lane_offset,
		minimum_field_y + 320.0,
		maximum_field_y - 320.0
	)
	var recovery_target := _clamp_to_field(Vector2(
		recovery_x,
		recovery_y
	))
	if controlled_player.global_position.distance_to(recovery_target) <= maxf(
		80.0,
		off_ball_transition_arrival_tolerance
	):
		return false
	_clear_attack_plan()
	_movement_target = recovery_target
	_last_off_ball_role = &"transition_recovery"
	_last_off_ball_reason = "rotate_back_immediately_after_possession_loss"
	_last_off_ball_target = recovery_target
	_set_tactical_intent(
		INTENT_COVER,
		recovery_target,
		int(ball.last_touch_peer_id)
	)
	return true


func _get_off_ball_recovery_lane_index() -> int:
	var eligible: Array[FootballPlayer] = []
	for teammate in _get_teammates():
		if (
			not is_instance_valid(teammate)
			or not teammate.controls_enabled
			or teammate == _get_likely_team_ball_carrier()
		):
			continue
		eligible.append(teammate)
	eligible.sort_custom(func(a: FootballPlayer, b: FootballPlayer) -> bool:
		return a.owner_peer_id < b.owner_peer_id
	)
	var own_index := eligible.find(controlled_player)
	if own_index < 0:
		return 0
	var count := eligible.size()
	if count <= 1:
		return 0
	if count == 2:
		return -1 if own_index == 0 else 1
	var centered_index := own_index - int(floor(float(count - 1) * 0.5))
	return clampi(centered_index, -2, 2)


func _try_resolve_possession_deadlock(
	opponent_goal: FootballGoal
) -> bool:
	if not _possession_deadlock_is_ready():
		return false
	_next_possession_deadlock_escape_at = (
		_server_time_seconds() + maxf(0.25, possession_deadlock_retry_seconds)
	)
	_reset_possession_deadlock_watch()
	if controlled_player.server_is_charging:
		controlled_player.cpu_cancel_shot_charge()
		_reset_cpu_charge_tracking()
	_clear_attack_plan()

	# A deadlock escape must preserve football intent. The old order always
	# preferred a teammate -- usually the 2v2 goalkeeper -- before checking a
	# clear shot or an open forward carry. That removed the freeze but created
	# unnatural panic backpasses every few seconds.
	var goal_target = _get_shot_target(opponent_goal)
	var goal_distance = ball.global_position.distance_to(goal_target)
	var goal_clearance = _minimum_segment_clearance(
		ball.global_position,
		goal_target
	)
	if (
		goal_distance <= 2850.0
		and goal_clearance
		>= maxf(125.0, deadlock_escape_minimum_clearance * 0.9)
	):
		_plan_is_pass = false
		_planned_receiver = null
		_plan_expires_at = _server_time_seconds() + 0.5
		_set_planned_route(goal_target, true, true)
		_movement_target = _get_strike_position(_shot_target)
		_set_tactical_intent(INTENT_SHOOT, _shot_target)
		_try_begin_shot(false)
		return true

	var escape_direction = _get_deadlock_escape_direction()
	var escape_target = _clamp_to_field(
		ball.global_position
		+ escape_direction * maxf(420.0, deadlock_escape_route_distance)
	)
	var escape_clearance = _minimum_segment_clearance(
		ball.global_position,
		escape_target
	)
	var escape_openness = _nearest_opponent_distance(escape_target)
	var escape_progress = (
		escape_target.x - ball.global_position.x
	) * _get_attack_sign()
	if (
		escape_progress >= 180.0
		and escape_clearance
		>= maxf(115.0, deadlock_escape_minimum_clearance * 0.76)
		and escape_openness >= 300.0
	):
		_execute_deadlock_dribble(escape_direction, escape_target)
		return true

	var receiver = _select_deadlock_outlet()
	if receiver != null:
		var destination = _get_lead_pass_target(receiver)
		_plan_is_pass = true
		_planned_receiver = receiver
		_plan_expires_at = _server_time_seconds() + 0.65
		_set_planned_route(destination, true, false)
		match_manager.set_cpu_pass_intention(
			controlled_player.owner_peer_id,
			receiver.owner_peer_id,
			_planned_destination,
			pass_intention_seconds
		)
		_movement_target = _get_strike_position(_shot_target)
		_set_tactical_intent(
			INTENT_PASS,
			_shot_target,
			receiver.owner_peer_id
		)
		_try_begin_shot(false)
		return true

	_execute_deadlock_dribble(escape_direction, escape_target)
	return true


func _execute_deadlock_dribble(
	escape_direction: Vector2,
	escape_target: Vector2
) -> void:
	_shot_target = escape_target
	_movement_target = (
		ball.global_position
		- escape_direction * maxf(115.0, strike_position_distance * 0.78)
	)
	_set_tactical_intent(INTENT_DRIBBLE, escape_target)
	controlled_player.cpu_dribble_touch(
		escape_direction,
		maxf(dribble_touch_force * 1.55, 620.0)
	)
	_dribble_until = _server_time_seconds() + 0.7


func _select_deadlock_outlet() -> FootballPlayer:
	var best: FootballPlayer
	var best_score = -INF
	var active_count = _get_active_team_player_count()
	for teammate in _get_teammates():
		if (
			not is_instance_valid(teammate)
			or teammate == controlled_player
			or not teammate.controls_enabled
		):
			continue
		var target = _get_lead_pass_target(teammate)
		var distance = ball.global_position.distance_to(target)
		if distance < 280.0 or distance > maximum_pass_distance:
			continue
		var clearance = _minimum_segment_clearance(
			ball.global_position,
			target
		)
		var required_clearance = maxf(
			90.0,
			deadlock_escape_minimum_clearance
		)
		var two_player_keeper_outlet = (
			_is_designated_goalkeeper(teammate)
			and active_count == 2
		)
		if two_player_keeper_outlet:
			required_clearance *= 0.78
			var carrier_pressure = _nearest_opponent_distance(
				ball.global_position
			)
			var forward_direction = Vector2(_get_attack_sign(), 0.0)
			var forward_target = _clamp_to_field(
				ball.global_position
				+ forward_direction
				* maxf(520.0, deadlock_escape_route_distance * 0.78)
			)
			var forward_clearance = _minimum_segment_clearance(
				ball.global_position,
				forward_target
			)
			# Do not manufacture a keeper backpass while the carrier has room to
			# advance. The keeper remains available under real pressure or when
			# the direct escape corridor is closed.
			if (
				carrier_pressure > pass_pressure_radius * 0.82
				and forward_clearance
				>= deadlock_escape_minimum_clearance * 0.9
			):
				continue
		if clearance < required_clearance:
			continue
		var openness = _nearest_opponent_distance(target)
		if openness < 250.0:
			continue
		var forward_progress = (
			target.x - ball.global_position.x
		) * _get_attack_sign()
		var score = (
			clearance * 0.7
			+ openness * 0.65
			+ forward_progress * 0.28
			- distance * 0.08
		)
		if two_player_keeper_outlet:
			score += 145.0
		if score > best_score:
			best_score = score
			best = teammate
	return best


func _get_deadlock_escape_direction() -> Vector2:
	var attack_sign = _get_attack_sign()
	var candidates: Array[Vector2] = [
		Vector2(attack_sign, 0.0),
		Vector2(attack_sign, -0.55).normalized(),
		Vector2(attack_sign, 0.55).normalized(),
		Vector2(attack_sign * 0.35, -1.0).normalized(),
		Vector2(attack_sign * 0.35, 1.0).normalized(),
		Vector2(0.0, -1.0),
		Vector2(0.0, 1.0)
	]
	var best_direction = Vector2(attack_sign, 0.0)
	var best_score = -INF
	for direction in candidates:
		var target = _clamp_to_field(
			ball.global_position
			+ direction * maxf(420.0, deadlock_escape_route_distance)
		)
		var clearance = _minimum_segment_clearance(
			ball.global_position,
			target
		)
		var openness = _nearest_opponent_distance(target)
		var forward_progress = (
			target.x - ball.global_position.x
		) * attack_sign
		var wall_margin = minf(
			target.y - minimum_field_y,
			maximum_field_y - target.y
		)
		var score = (
			clearance * 0.82
			+ openness * 0.72
			+ forward_progress * 0.42
			+ minf(wall_margin, 500.0) * 0.12
		)
		if score > best_score:
			best_score = score
			best_direction = direction
	return best_direction


func _get_large_team_parallel_plan() -> Dictionary:
	if (
		not is_instance_valid(match_manager)
		or not is_instance_valid(controlled_player)
		or not match_manager.has_method("get_large_team_parallel_plan")
	):
		return {}
	var physics_frame := int(Engine.get_physics_frames())
	if _large_team_parallel_plan_frame != physics_frame:
		_large_team_parallel_plan_frame = physics_frame
		_large_team_parallel_plan = match_manager.get_large_team_parallel_plan(
			controlled_player.owner_peer_id
		)
	return _large_team_parallel_plan


func _get_active_team_player_count() -> int:
	var physics_frame := int(Engine.get_physics_frames())
	if _active_team_count_cache_frame == physics_frame:
		return _active_team_count_cache
	_active_team_count_cache_frame = physics_frame
	if (
		is_instance_valid(match_manager)
		and match_manager.has_method("get_cpu_shared_active_count")
	):
		_active_team_count_cache = match_manager.get_cpu_shared_active_count(
			controlled_player.team
		)
		return _active_team_count_cache
	var count := 0
	for teammate in _get_teammates():
		if is_instance_valid(teammate) and teammate.controls_enabled:
			count += 1
	_active_team_count_cache = count
	return count


func is_large_team_football_shape_active() -> bool:
	return (
		large_team_football_shape_enabled
		and is_instance_valid(controlled_player)
		and _get_active_team_player_count() >= 4
	)


func _get_large_team_natural_role(player: FootballPlayer) -> StringName:
	if not is_instance_valid(player):
		return LARGE_TEAM_ROLE_MIDFIELDER
	var football_role := StringName(
		player.get_meta("pve_ranked_football_role", &"")
	)
	match football_role:
		&"defender", &"holding", &"goalkeeper":
			return LARGE_TEAM_ROLE_DEFENDER
		&"winger":
			return LARGE_TEAM_ROLE_WINGER
		&"striker":
			return LARGE_TEAM_ROLE_STRIKER
		&"forward_creator":
			return LARGE_TEAM_ROLE_STRIKER
		&"midfielder", &"creator":
			return LARGE_TEAM_ROLE_MIDFIELDER
	match FootballPlayer.get_ability_role(player.selected_ability):
		FootballPlayer.ABILITY_ROLE_DEFENSE:
			return LARGE_TEAM_ROLE_DEFENDER
		FootballPlayer.ABILITY_ROLE_ATTACK:
			return LARGE_TEAM_ROLE_STRIKER
	return LARGE_TEAM_ROLE_MIDFIELDER


func _get_large_team_role_fit(
	player: FootballPlayer,
	role: StringName
) -> float:
	if not is_instance_valid(player):
		return -INF
	var football_role := StringName(
		player.get_meta("pve_ranked_football_role", &"")
	)
	var score := 0.0
	match role:
		LARGE_TEAM_ROLE_DEFENDER:
			score = _get_tactical_defender_score(player)
			match football_role:
				&"defender": score += 5.0
				&"holding": score += 4.0
				&"midfielder": score += 1.0
				&"winger", &"striker", &"forward_creator": score -= 3.0
		LARGE_TEAM_ROLE_STRIKER:
			score = _get_tactical_striker_score(player)
			match football_role:
				&"striker": score += 5.0
				&"forward_creator": score += 3.5
				&"winger": score += 2.5
				&"defender", &"holding": score -= 3.0
		LARGE_TEAM_ROLE_WINGER:
			match football_role:
				&"winger": score += 11.0
				&"forward_creator": score += 7.0
				&"creator": score += 5.0
				&"midfielder": score += 3.5
				&"striker": score += 2.5
				&"holding": score -= 2.0
				&"defender": score -= 4.0
			match FootballPlayer.get_ability_role(player.selected_ability):
				FootballPlayer.ABILITY_ROLE_ATTACK:
					score += 2.0
				FootballPlayer.ABILITY_ROLE_PLAYMAKER:
					score += 1.4
				FootballPlayer.ABILITY_ROLE_DEFENSE:
					score -= 2.5
			if player.selected_ability in [
				FootballPlayer.ABILITY_OVERDRIVE,
				FootballPlayer.ABILITY_BREAKAWAY,
				FootballPlayer.ABILITY_BURST_DRIBBLE,
				FootballPlayer.ABILITY_ELASTIC_STEP
			]:
				score += 2.0
		_:
			match football_role:
				&"midfielder": score += 10.0
				&"creator": score += 9.0
				&"forward_creator": score += 5.0
				&"holding": score += 4.5
				&"winger": score += 2.0
				&"striker": score -= 1.0
				&"defender": score -= 1.5
			match FootballPlayer.get_ability_role(player.selected_ability):
				FootballPlayer.ABILITY_ROLE_PLAYMAKER:
					score += 3.0
				FootballPlayer.ABILITY_ROLE_DEFENSE:
					score += 0.5
	return score


func _build_large_team_cpu_outfield_roster() -> Array[FootballPlayer]:
	var roster: Array[FootballPlayer] = []
	for teammate: FootballPlayer in _get_teammates():
		if (
			is_instance_valid(teammate)
			and teammate.controls_enabled
			and teammate.cpu_controlled
			and not _is_designated_goalkeeper(teammate)
		):
			roster.append(teammate)
	roster.sort_custom(func(first: FootballPlayer, second: FootballPlayer) -> bool:
		if first.team_slot != second.team_slot:
			return first.team_slot < second.team_slot
		return first.owner_peer_id < second.owner_peer_id
	)
	return roster


func _pick_large_team_role_player(
	available: Array[FootballPlayer],
	role: StringName
) -> FootballPlayer:
	var best: FootballPlayer
	var best_score := -INF
	for candidate: FootballPlayer in available:
		var score := _get_large_team_role_fit(candidate, role)
		if (
			score > best_score
			or (
				is_equal_approx(score, best_score)
				and (
					best == null
					or candidate.team_slot < best.team_slot
					or (
						candidate.team_slot == best.team_slot
						and candidate.owner_peer_id < best.owner_peer_id
					)
				)
			)
		):
			best = candidate
			best_score = score
	return best


func _refresh_large_team_shape_cache_if_needed() -> void:
	var now := _server_time_seconds()
	if now < _large_team_shape_cache_until and not _large_team_cached_roster.is_empty():
		return
	_large_team_cached_roster = _build_large_team_cpu_outfield_roster()
	_large_team_cached_assignments.clear()
	var available: Array[FootballPlayer] = []
	available.assign(_large_team_cached_roster)
	if not available.is_empty():
		var defender_slots := 1 if available.size() >= 2 else 0
		if available.size() >= 5:
			defender_slots = 2
		var striker_slots := 1 if available.size() >= 2 else 0
		var winger_slots := 1 if available.size() >= 4 else 0
		for _slot in range(defender_slots):
			var defender := _pick_large_team_role_player(available, LARGE_TEAM_ROLE_DEFENDER)
			if defender == null:
				break
			_large_team_cached_assignments[defender.owner_peer_id] = LARGE_TEAM_ROLE_DEFENDER
			available.erase(defender)
		for _slot in range(striker_slots):
			var striker := _pick_large_team_role_player(available, LARGE_TEAM_ROLE_STRIKER)
			if striker == null:
				break
			_large_team_cached_assignments[striker.owner_peer_id] = LARGE_TEAM_ROLE_STRIKER
			available.erase(striker)
		for _slot in range(winger_slots):
			var winger := _pick_large_team_role_player(available, LARGE_TEAM_ROLE_WINGER)
			if winger == null:
				break
			_large_team_cached_assignments[winger.owner_peer_id] = LARGE_TEAM_ROLE_WINGER
			available.erase(winger)
		for midfielder: FootballPlayer in available:
			_large_team_cached_assignments[midfielder.owner_peer_id] = LARGE_TEAM_ROLE_MIDFIELDER
	# Precompute lane offsets with the already slot-sorted roster. The old path
	# allocated and sorted a same-role array every time any defender/support
	# target was requested.
	_large_team_cached_lane_offsets.clear()
	for cached_role: StringName in [
		LARGE_TEAM_ROLE_DEFENDER,
		LARGE_TEAM_ROLE_MIDFIELDER,
		LARGE_TEAM_ROLE_WINGER,
		LARGE_TEAM_ROLE_STRIKER
	]:
		var role_players: Array[FootballPlayer] = []
		for teammate: FootballPlayer in _large_team_cached_roster:
			if StringName(_large_team_cached_assignments.get(teammate.owner_peer_id, &"")) == cached_role:
				role_players.append(teammate)
		for role_index in range(role_players.size()):
			var role_player := role_players[role_index]
			var lane_offset := 0.0
			if role_players.size() >= 2:
				var fraction := float(role_index) / float(maxi(1, role_players.size() - 1))
				match cached_role:
					LARGE_TEAM_ROLE_DEFENDER: lane_offset = lerpf(-690.0, 690.0, fraction)
					LARGE_TEAM_ROLE_MIDFIELDER: lane_offset = lerpf(-560.0, 560.0, fraction)
					LARGE_TEAM_ROLE_WINGER: lane_offset = lerpf(-1280.0, 1280.0, fraction)
					LARGE_TEAM_ROLE_STRIKER: lane_offset = lerpf(-360.0, 360.0, fraction)
			else:
				match cached_role:
					LARGE_TEAM_ROLE_WINGER: lane_offset = -1260.0 if role_player.team_slot % 2 == 0 else 1260.0
					LARGE_TEAM_ROLE_MIDFIELDER: lane_offset = -430.0 if role_player.team_slot % 2 == 0 else 430.0
					LARGE_TEAM_ROLE_STRIKER: lane_offset = -220.0 if role_player.team_slot % 2 == 0 else 220.0
			_large_team_cached_lane_offsets[role_player.owner_peer_id] = lane_offset
	var cache_phase := float(abs(controlled_player.owner_peer_id) % 7) * 0.009
	_large_team_shape_cache_until = (
		now + maxf(0.10, large_team_shape_cache_seconds) + cache_phase
	)


func _get_large_team_cpu_outfield_roster() -> Array[FootballPlayer]:
	_refresh_large_team_shape_cache_if_needed()
	return _large_team_cached_roster


func _get_large_team_formation_assignments() -> Dictionary:
	if not is_large_team_football_shape_active():
		return {}
	_refresh_large_team_shape_cache_if_needed()
	return _large_team_cached_assignments


func get_large_team_football_role(player: FootballPlayer) -> StringName:
	if not is_instance_valid(player):
		return LARGE_TEAM_ROLE_MIDFIELDER
	if _is_designated_goalkeeper(player):
		return TACTICAL_ROLE_GOALKEEPER
	if not is_large_team_football_shape_active():
		return _get_large_team_natural_role(player)
	_refresh_large_team_shape_cache_if_needed()
	return StringName(_large_team_cached_assignments.get(
		player.owner_peer_id,
		_get_large_team_natural_role(player)
	))


func _get_large_team_role_lane_offset(
	player: FootballPlayer,
	role: StringName
) -> float:
	if not is_instance_valid(player):
		return 0.0
	_refresh_large_team_shape_cache_if_needed()
	if _large_team_cached_lane_offsets.has(player.owner_peer_id):
		return float(_large_team_cached_lane_offsets[player.owner_peer_id])
	# Fallback only matters during a transient roster/cache boundary.
	if role == LARGE_TEAM_ROLE_WINGER:
		return -1260.0 if player.team_slot % 2 == 0 else 1260.0
	if role == LARGE_TEAM_ROLE_MIDFIELDER:
		return -430.0 if player.team_slot % 2 == 0 else 430.0
	if role == LARGE_TEAM_ROLE_STRIKER:
		return -220.0 if player.team_slot % 2 == 0 else 220.0
	return 0.0


func _get_large_team_defensive_zone_position(
	player: FootballPlayer
) -> Vector2:
	if not is_large_team_football_shape_active() or not is_instance_valid(player):
		return Vector2.ZERO
	var own_goal := _get_own_goal()
	var opponent_goal := _get_opponent_goal()
	if own_goal == null or opponent_goal == null:
		return Vector2.ZERO
	var own_goal_center := _get_goal_center(own_goal)
	var opponent_goal_center := _get_goal_center(opponent_goal)
	var attack_sign := _get_attack_sign()
	var field_length := maxf(
		1.0,
		absf(opponent_goal_center.x - own_goal_center.x)
	)
	var ball_progress := clampf(
		(ball.global_position.x - own_goal_center.x) * attack_sign / field_length,
		0.0,
		1.0
	)
	var role := get_large_team_football_role(player)
	var desired_progress := 0.44
	var maximum_ahead_of_ball := -0.04
	var ball_y_blend := 0.30
	match role:
		LARGE_TEAM_ROLE_DEFENDER:
			desired_progress = lerpf(0.20, 0.38, ball_progress)
			maximum_ahead_of_ball = -0.08
			ball_y_blend = 0.26
		LARGE_TEAM_ROLE_MIDFIELDER:
			desired_progress = lerpf(0.34, 0.52, ball_progress)
			maximum_ahead_of_ball = -0.04
			ball_y_blend = 0.34
		LARGE_TEAM_ROLE_WINGER:
			desired_progress = lerpf(0.40, 0.56, ball_progress)
			maximum_ahead_of_ball = 0.01
			ball_y_blend = 0.16
		LARGE_TEAM_ROLE_STRIKER:
			desired_progress = lerpf(0.47, 0.63, ball_progress)
			maximum_ahead_of_ball = 0.08
			ball_y_blend = 0.20
	desired_progress = minf(
		desired_progress,
		ball_progress + maximum_ahead_of_ball
	)
	desired_progress = clampf(desired_progress, 0.08, 0.76)
	var center_y := (minimum_field_y + maximum_field_y) * 0.5
	var lane_y := center_y + _get_large_team_role_lane_offset(player, role)
	lane_y = lerpf(lane_y, ball.global_position.y, ball_y_blend)
	lane_y = clampf(
		lane_y,
		minimum_field_y + 360.0,
		maximum_field_y - 360.0
	)
	return _clamp_to_field(Vector2(
		own_goal_center.x + attack_sign * field_length * desired_progress,
		lane_y
	))


func resolve_cpu_defensive_assignment_target(
	assignment: Dictionary
) -> Vector2:
	if assignment.is_empty():
		return Vector2.ZERO
	var role := StringName(assignment.get("role", &""))
	var base_target: Vector2 = assignment.get("target_position", Vector2.ZERO)
	var marked_opponent: FootballPlayer
	if role == &"mark":
		marked_opponent = _get_opponent_by_peer_id(
			int(assignment.get("target_peer_id", 0))
		)
		if marked_opponent != null:
			var own_goal := _get_own_goal()
			if own_goal != null:
				base_target = _get_goal_side_mark_position(
					marked_opponent,
					own_goal
				)
	if not is_large_team_football_shape_active() or role == &"press":
		return base_target
	var zone_target := _get_large_team_defensive_zone_position(controlled_player)
	if zone_target.is_zero_approx():
		return base_target
	if base_target.is_zero_approx():
		return zone_target
	var zone_blend := clampf(large_team_defensive_zone_blend, 0.0, 0.9)
	match role:
		&"final":
			zone_blend *= 0.30
		&"cover":
			zone_blend *= 0.72
		&"mark":
			zone_blend *= 1.0
	if marked_opponent != null:
		var own_goal := _get_own_goal()
		if own_goal != null:
			var threat_distance := marked_opponent.global_position.distance_to(
				_get_goal_center(own_goal)
			)
			if threat_distance < 2200.0:
				zone_blend *= 0.42
			elif threat_distance < 3200.0:
				zone_blend *= 0.68
	return _clamp_to_field(base_target.lerp(zone_target, zone_blend))


func _try_prepare_elite_combination_relay(
	receive_intention: Dictionary
) -> bool:
	if _get_ai_skill() < elite_combination_minimum_skill:
		return false
	var plan = match_manager.get_cpu_combination_plan(controlled_player.team)
	if (
		plan.is_empty()
		or int(plan.get("receiver_peer_id", 0))
		!= controlled_player.owner_peer_id
	):
		return false
	var pass_kind = StringName(plan.get("pass_kind", &""))
	if pass_kind in [
		&"through",
		&"diagonal_split",
		&"blindside",
		&"square",
		&"cutback",
		&"overlap",
		&"underlap",
		&"pressure_escape",
		&"layoff",
		&"recycle"
	]:
		# These passes are designed to make the receiver attack the opening, not
		# blindly bounce the ball back and destroy the advantage.
		return false
	var next_player = _get_teammate_by_peer_id(
		int(plan.get("next_peer_id", 0))
	)
	if next_player == null:
		return false
	var ball_distance = controlled_player.global_position.distance_to(
		ball.global_position
	)
	if ball_distance > maxf(shot_precharge_distance, 1450.0):
		return false
	var destination = _get_lead_pass_target(next_player)
	var planned_next_target: Vector2 = plan.get(
		"next_run_target",
		destination
	)
	destination = _clamp_to_field(destination.lerp(planned_next_target, 0.72))
	var direct_clearance = _minimum_segment_clearance(
		ball.global_position,
		destination
	)
	var wall_route = _get_best_wall_route(destination)
	if (
		direct_clearance < pass_lane_clearance * 0.64
		and (
			wall_route.is_empty()
			or float(wall_route.get("clearance", 0.0))
			< wall_route_minimum_clearance
		)
	):
		return false
	_plan_is_pass = true
	_planned_receiver = next_player
	_plan_expires_at = _server_time_seconds() + 0.55
	_set_planned_route(destination, true, false)
	match_manager.set_cpu_pass_intention(
		controlled_player.owner_peer_id,
		next_player.owner_peer_id,
		_planned_destination,
		pass_intention_seconds
	)
	_movement_target = _get_strike_position(_shot_target)
	_set_tactical_intent(
		INTENT_RECEIVE,
		_movement_target,
		int(receive_intention.get("passer_peer_id", 0))
	)
	_try_begin_shot(false)
	return true


func _update_goalkeeper_decision() -> void:
	var own_goal = _get_own_goal()
	var opponent_goal = _get_opponent_goal()
	if own_goal == null or opponent_goal == null:
		_movement_target = ball.global_position
		_set_tactical_intent(INTENT_GOALKEEP, _movement_target)
		return

	_shot_target = _get_shot_target(opponent_goal)
	if not controlled_player.server_is_charging:
		_plan_is_pass = false
		_planned_receiver = null
	var skill = _get_ai_skill()
	var receive_intention = match_manager.get_cpu_pass_intention(
		controlled_player.owner_peer_id
	)
	var ball_distance = controlled_player.global_position.distance_to(
		ball.global_position
	)
	var defensive_assignment = match_manager.get_cpu_defensive_assignment(
		controlled_player.team,
		controlled_player.owner_peer_id
	)
	var final_lane_target: Vector2 = defensive_assignment.get(
		"target_position",
		Vector2.ZERO
	)
	if (
		StringName(defensive_assignment.get("role", &"")) == &"final"
		and not _team_likely_has_possession()
		and not final_lane_target.is_zero_approx()
		and final_lane_target.distance_to(_get_goal_center(own_goal)) <= 1550.0
		and ball_distance > controlled_player.kick_feedback_detection_distance
	):
		# In a three-player side the keeper is the third containment role. This
		# is still a conservative goal-side lane, not a free chase upfield.
		_movement_target = _clamp_to_field(final_lane_target)
		_set_tactical_intent(INTENT_COVER, _movement_target)
		return
	if (
		not receive_intention.is_empty()
		and ball_distance
		> controlled_player.kick_feedback_detection_distance * 0.82
	):
		var receive_target: Vector2 = receive_intention.get(
			"position",
			_get_predicted_ball_position()
		)
		_movement_target = _clamp_to_field(
			receive_target.lerp(_get_predicted_ball_position(), 0.55)
		)
		_set_tactical_intent(
			INTENT_RECEIVE,
			_movement_target,
			int(receive_intention.get("passer_peer_id", 0))
		)
		return
	var goalkeeper_has_control = _goalkeeper_has_secure_ball_control()
	if (
		goalkeeper_controlled_outlet_enabled
		and goalkeeper_has_control
		and _get_active_team_player_count() > 1
		and _update_goalkeeper_distribution(opponent_goal, true)
	):
		return
	if (
		goalkeeper_has_control
		and goalkeeper_uncontested_carry_enabled
		and _get_active_team_player_count() > 1
		and not _ball_is_in_own_goal_danger()
	):
		# No usable outlet exists right now. Do not freeze on the ball waiting for
		# the deadlock timer; carry into open space and let the next decision cycle
		# pass, shoot, or continue the play from the new shape.
		_clear_attack_plan()
		_update_dribble(opponent_goal)
		_set_tactical_intent(INTENT_DRIBBLE, _shot_target)
		return
	if (
		controlled_player.cpu_has_kickable_ball()
		and _possession_deadlock_is_ready()
		and _try_resolve_possession_deadlock(opponent_goal)
	):
		return
	if (
		skill >= elite_build_up_minimum_skill
		and ball_distance
		<= controlled_player.kick_feedback_detection_distance * 1.1
		and (
			ball.last_touch_peer_id == controlled_player.owner_peer_id
			or not _last_ball_touch_was_opponent()
		)
		and _update_goalkeeper_distribution(opponent_goal, false)
	):
		return
	var ball_goal_distance = ball.global_position.distance_to(
		_get_goal_center(own_goal)
	)
	var threat = _predict_own_goal_threat(lerpf(0.85, 2.4, skill))
	if (
		ball_goal_distance <= maxf(200.0, goalkeeper_chase_distance)
		or not threat.is_empty()
		and ball_goal_distance <= lerpf(1650.0, 2850.0, skill)
	):
		_update_emergency_clearance()
		_set_tactical_intent(INTENT_GOALKEEP, _movement_target)
		return

	var goal_center = _get_goal_center(own_goal)
	var attack_sign = _get_attack_sign()
	var ability_keeper_target = _get_ability_aware_goalkeeper_target(own_goal)
	if not ability_keeper_target.is_zero_approx():
		_movement_target = ability_keeper_target
		_set_tactical_intent(INTENT_GOALKEEP, _movement_target)
		return
	var opponent_carrier = _get_likely_opponent_ball_carrier()
	if opponent_carrier != null:
		var anticipatory_target = _get_anticipatory_goal_defense_position(
			opponent_carrier,
			own_goal,
			true
		)
		if not anticipatory_target.is_zero_approx():
			_movement_target = anticipatory_target
			_set_tactical_intent(
				INTENT_GOALKEEP,
				_movement_target,
				opponent_carrier.owner_peer_id
			)
			return
	var sweeper_target = _get_goalkeeper_sweeper_target(own_goal, skill)
	if not sweeper_target.is_zero_approx():
		if (
			controlled_player.global_position.distance_to(ball.global_position)
			<= controlled_player.kick_feedback_detection_distance
		):
			_update_emergency_clearance()
			_set_tactical_intent(INTENT_GOALKEEP, _movement_target)
			return
		_movement_target = sweeper_target
		_set_tactical_intent(INTENT_GOALKEEP, _movement_target)
		return

	if (
		_team_likely_has_possession()
		and _get_active_team_player_count() == 2
		and _server_time_seconds() < _two_vs_two_outlet_follow_until
		and not _two_vs_two_outlet_follow_target.is_zero_approx()
		and threat.is_empty()
	):
		var follow_target = _two_vs_two_outlet_follow_target
		var carrier = _get_likely_team_ball_carrier()
		if carrier != null and carrier != controlled_player:
			follow_target = _get_two_vs_two_rotation_support_position(carrier)
			if follow_target.is_zero_approx():
				follow_target = _two_vs_two_outlet_follow_target
		_movement_target = _clamp_to_field(follow_target)
		_set_tactical_intent(
			INTENT_WIDE_SUPPORT,
			_movement_target,
			carrier.owner_peer_id if carrier != null else 0
		)
		return

	var dynamic_depth = lerpf(
		maxf(100.0, goalkeeper_depth * 0.55),
		maxf(100.0, goalkeeper_depth),
		skill
	)
	var team_has_possession = _team_likely_has_possession()
	var active_team_count = _get_active_team_player_count()
	if team_has_possession:
		dynamic_depth += lerpf(80.0, 520.0, skill)
		if active_team_count == 2 and ball_goal_distance > 2100.0:
			# In 2v2 the keeper is the only recycle option. Step high enough to
			# create a real passing lane, but stay goal-side of the ball.
			dynamic_depth = maxf(
				dynamic_depth,
				minf(
					maxf(700.0, two_vs_two_keeper_build_up_depth),
					ball_goal_distance * 0.48
				)
			)
	var keeper_x = (
		own_goal.get_goal_plane_x()
		+ attack_sign * dynamic_depth
	)
	var target_y = _predict_goalkeeper_y(own_goal, keeper_x)
	if team_has_possession:
		var ball_blend = lerpf(0.12, 0.42, skill)
		if active_team_count == 2:
			ball_blend = maxf(ball_blend, 0.52)
		target_y = lerpf(goal_center.y, ball.global_position.y, ball_blend)
	_movement_target = Vector2(keeper_x, target_y)
	_set_tactical_intent(INTENT_GOALKEEP, _movement_target)


func _goalkeeper_has_secure_ball_control() -> bool:
	if not controlled_player.cpu_has_kickable_ball():
		return false
	if ball.last_touch_peer_id == controlled_player.owner_peer_id:
		return true
	var opponent_space = _nearest_opponent_distance(ball.global_position)
	return (
		ball.linear_velocity.length()
		<= maxf(
			120.0,
			maxf(
				goalkeeper_controlled_outlet_speed,
				goalkeeper_secure_collection_speed
			)
		)
		and opponent_space >= 170.0
	)


func _update_goalkeeper_distribution(
	opponent_goal: FootballGoal,
	force_outlet: bool = false
) -> bool:
	if controlled_player.server_is_charging:
		return _plan_is_pass and is_instance_valid(_planned_receiver)
	var plan = _select_goalkeeper_distribution_plan(
		opponent_goal,
		force_outlet
	)
	if plan.is_empty():
		return false
	var receiver: FootballPlayer = plan.get("receiver") as FootballPlayer
	if not is_instance_valid(receiver):
		return false
	var destination: Vector2 = plan.get(
		"target",
		_get_lead_pass_target(receiver)
	)
	var use_power = bool(plan.get("power", false))
	_plan_is_pass = true
	_planned_receiver = receiver
	_plan_expires_at = (
		_server_time_seconds() + maxf(0.55, pass_plan_lock_seconds)
	)
	_set_planned_route(destination, true, false)
	var intention_duration = (
		maxf(pass_intention_seconds, 2.1)
		if use_power
		else pass_intention_seconds
	)
	match_manager.set_cpu_pass_intention(
		controlled_player.owner_peer_id,
		receiver.owner_peer_id,
		_planned_destination,
		intention_duration
	)
	_register_elite_combination_play(
		receiver,
		_planned_destination,
		opponent_goal
	)
	_movement_target = _get_strike_position(_shot_target)
	_set_tactical_intent(
		INTENT_PASS,
		_planned_destination,
		receiver.owner_peer_id
	)
	if _get_active_team_player_count() == 2:
		_two_vs_two_outlet_follow_until = (
			_server_time_seconds()
			+ maxf(0.8, two_vs_two_outlet_follow_seconds)
		)
		var follow_side = signf(
			receiver.global_position.y - ball.global_position.y
		)
		if is_zero_approx(follow_side):
			follow_side = -1.0 if ball.global_position.y > 2500.0 else 1.0
		_two_vs_two_outlet_follow_target = _clamp_to_field(
			destination
			- Vector2(
				_get_attack_sign()
				* maxf(420.0, two_vs_two_outlet_follow_distance),
				follow_side * 360.0
			)
		)
	if _try_neuer_dead_zone_distribution(receiver, _planned_destination):
		return true
	if (
		use_power
		and controlled_player.selected_ability
		== FootballPlayer.ABILITY_POWER_STRIKE
		and _cpu_ability_is_ready()
	):
		_request_ability_action(
			FootballPlayer.ABILITY_POWER_STRIKE,
			_shot_target,
			receiver.owner_peer_id,
			INTENT_PASS,
			FootballPlayer.ABILITY_POWER_STRIKE,
			true
		)
	_try_begin_shot(false)
	return true


func _try_neuer_dead_zone_distribution(
	receiver: FootballPlayer,
	destination: Vector2
) -> bool:
	if (
		controlled_player == null
		or ball == null
		or not controlled_player.is_neuer_boss()
		or not is_instance_valid(receiver)
		or destination.is_zero_approx()
		or not controlled_player.cpu_neuer_dead_zone_pass_is_ready()
	):
		return false
	var route_distance := ball.global_position.distance_to(destination)
	var maximum_route := controlled_player.cpu_get_time_skip_pass_maximum_travel_distance()
	if route_distance > maximum_route * 0.97:
		return false
	var direct_clearance := _minimum_segment_clearance(
		ball.global_position,
		destination
	)
	if direct_clearance < maxf(90.0, goalkeeper_distribution_force_clearance):
		return false
	var pass_direction := ball.global_position.direction_to(destination)
	if pass_direction.is_zero_approx():
		return false
	controlled_player.server_direction = pass_direction
	return controlled_player.cpu_activate_neuer_dead_zone_pass(
		receiver.owner_peer_id,
		destination
	)


func _select_goalkeeper_distribution_plan(
	opponent_goal: FootballGoal,
	force_outlet: bool
) -> Dictionary:
	var best_plan: Dictionary = {}
	var best_score = -INF
	var best_forced_plan: Dictionary = {}
	var best_forced_score = -INF
	var attack_sign = _get_attack_sign()
	var center_y = (minimum_field_y + maximum_field_y) * 0.5
	var power_available = (
		controlled_player.selected_ability
		== FootballPlayer.ABILITY_POWER_STRIKE
		and (
			_cpu_ability_is_ready()
			or _has_active_ability(FootballPlayer.ABILITY_POWER_STRIKE)
		)
	)
	for teammate in _get_teammates():
		if (
			not is_instance_valid(teammate)
			or teammate == controlled_player
			or not teammate.controls_enabled
			or _is_designated_goalkeeper(teammate)
		):
			continue
		var teammate_position = teammate.global_position
		var lead_target = _get_lead_pass_target(teammate)
		var side = signf(teammate_position.y - center_y)
		if is_zero_approx(side):
			side = -1.0 if ball.global_position.y > center_y else 1.0
		var candidate_targets: Array[Dictionary] = [
			{
				"target": teammate_position + teammate.linear_velocity * 0.08,
				"bias": 140.0 if force_outlet else 55.0,
				"power": false
			},
			{
				"target": lead_target,
				"bias": 210.0 if force_outlet else 105.0,
				"power": false
			},
			{
				"target": teammate_position
				+ teammate.linear_velocity * 0.12
				+ Vector2(attack_sign * 280.0, side * 220.0),
				"bias": 165.0,
				"power": false
			}
		]
		if power_available:
			var raw_distance = ball.global_position.distance_to(
				teammate_position
			)
			candidate_targets.append({
				"target": teammate_position
				+ teammate.linear_velocity * 0.18
				+ Vector2(
					attack_sign * clampf(raw_distance * 0.19, 520.0, 1050.0),
					side * 120.0
				),
				"bias": 390.0,
				"power": true
			})
		for candidate in candidate_targets:
			var target = _clamp_to_field(
				candidate.get("target", teammate_position)
			)
			var use_power = bool(candidate.get("power", false))
			var distance = ball.global_position.distance_to(target)
			var maximum_distance = (
				power_strike_distribution_maximum_distance
				if use_power
				else goalkeeper_distribution_maximum_distance
			)
			if distance < minimum_pass_distance * 0.62 or distance > maximum_distance:
				continue
			var forward_progress = (
				target.x - ball.global_position.x
			) * attack_sign
			if use_power and (
				distance < maxf(
					defensive_power_pass_minimum_distance,
					power_strike_distribution_minimum_distance * 0.72
				)
				or forward_progress
				< maxf(
					defensive_power_pass_minimum_progress,
					power_strike_distribution_minimum_progress * 0.55
				)
			):
				continue
			var direct_clearance = _minimum_segment_clearance(
				ball.global_position,
				target
			)
			var wall_route = _get_best_wall_route(target)
			var wall_clearance = float(
				wall_route.get("clearance", 0.0)
			)
			var required_clearance = (
				maxf(75.0, goalkeeper_distribution_force_clearance)
				if force_outlet
				else pass_lane_clearance * 0.72
			)
			if use_power:
				required_clearance = maxf(
					80.0,
					minf(
						required_clearance,
						power_strike_distribution_minimum_lane
					)
				)
			var route_clearance = maxf(direct_clearance, wall_clearance)
			var route_is_safe = route_clearance >= required_clearance
			var openness = _nearest_opponent_distance(target)
			var receiver_time = _estimate_duel_player_arrival_seconds(
				teammate,
				target
			)
			var launch_force = controlled_player.maximum_shot_force
			if use_power:
				launch_force *= maxf(
					1.0,
					controlled_player.power_strike_force_multiplier
				)
			var uses_wall = (
				wall_clearance > direct_clearance + 35.0
				and wall_clearance >= wall_route_minimum_clearance
			)
			var route_distance = (
				float(wall_route.get("distance", distance))
				if uses_wall
				else distance
			)
			var ball_time = _estimate_elite_ball_travel_time(
				route_distance,
				launch_force,
				uses_wall
			)
			var arrival_penalty = 0.0
			if not is_inf(ball_time):
				arrival_penalty = maxf(0.0, receiver_time - ball_time - 0.45) * 260.0
			var score = (
				float(candidate.get("bias", 0.0))
				+ minf(route_clearance, 1300.0) * 0.48
				+ minf(openness, 1500.0) * 0.42
				+ forward_progress * 0.31
				- distance * 0.055
				- arrival_penalty
			)
			if force_outlet:
				score += 260.0
			if use_power:
				score += 280.0
			if teammate.server_pass_request_ends_at > _server_time_seconds():
				score += requested_pass_score_bonus * 0.55
			var candidate_plan = {
				"receiver": teammate,
				"target": target,
				"power": use_power,
				"score": score
			}
			if route_is_safe and score > best_score:
				best_score = score
				best_plan = candidate_plan
			elif (
				force_outlet
				and not use_power
				and route_clearance >= 25.0
				and score > best_forced_score
			):
				# After a save, holding the ball indefinitely is worse than using
				# the safest available outlet. Power Strike is not forced through
				# a blocked lane; the fallback is always an ordinary controlled pass.
				best_forced_score = score
				best_forced_plan = candidate_plan
	if not best_plan.is_empty():
		return best_plan
	return best_forced_plan if force_outlet else {}


func _select_goalkeeper_distribution_target(
	opponent_goal: FootballGoal
) -> FootballPlayer:
	var best_receiver: FootballPlayer
	var best_score = -INF
	var center_y = (minimum_field_y + maximum_field_y) * 0.5
	for teammate in _get_teammates():
		if (
			not is_instance_valid(teammate)
			or teammate == controlled_player
			or not teammate.controls_enabled
			or _is_designated_goalkeeper(teammate)
		):
			continue
		var target = _get_lead_pass_target(teammate)
		var distance = ball.global_position.distance_to(target)
		if (
			distance < minimum_pass_distance
			or distance > goalkeeper_distribution_maximum_distance
		):
			continue
		var direct_clearance = _minimum_segment_clearance(
			ball.global_position,
			target
		)
		var wall_route = _get_best_wall_route(target)
		var wall_clearance = float(wall_route.get("clearance", 0.0))
		if (
			direct_clearance < pass_lane_clearance * 0.82
			and wall_clearance < wall_route_minimum_clearance
		):
			continue
		var openness = _nearest_opponent_distance(target)
		var forward_progress = (
			target.x - ball.global_position.x
		) * _get_attack_sign()
		var width = absf(target.y - center_y)
		var switch_distance = absf(target.y - ball.global_position.y)
		var receiver_intention = _get_effective_player_intention(teammate)
		var receiver_action = StringName(
			receiver_intention.get("action", &"")
		)
		var intention_bonus = (
			420.0
			if receiver_action in [INTENT_WIDE_SUPPORT, INTENT_FORWARD_RUN, INTENT_RECEIVE]
			else 0.0
		)
		var score = (
			openness * 0.46
			+ maxf(direct_clearance, wall_clearance) * 0.34
			+ forward_progress * 0.24
			+ width * goalkeeper_distribution_wide_bonus
			+ switch_distance * goalkeeper_distribution_switch_bonus
			- distance * 0.065
			+ intention_bonus
			+ _get_receiver_ability_bonus(
				teammate,
				target,
				ball.global_position.distance_to(_get_goal_center(opponent_goal))
			)
		)
		if score > best_score:
			best_score = score
			best_receiver = teammate
	return best_receiver


func _get_goalkeeper_sweeper_target(
	own_goal: FootballGoal,
	skill: float
) -> Vector2:
	if skill < 0.2:
		return Vector2.ZERO
	if _team_likely_has_possession():
		return Vector2.ZERO
	var goal_center = _get_goal_center(own_goal)
	var attack_sign = _get_attack_sign()
	var field_progress = (
		(ball.global_position.x - goal_center.x) * attack_sign
	)
	var neuer_sweeper := controlled_player != null and controlled_player.is_neuer_boss()
	var maximum_sweep_depth = lerpf(900.0, 2450.0, skill)
	if neuer_sweeper:
		maximum_sweep_depth = maxf(maximum_sweep_depth, 3400.0)
	if field_progress < 0.0 or field_progress > maximum_sweep_depth:
		return Vector2.ZERO

	var prediction_seconds := lerpf(0.18, 0.82, skill)
	if neuer_sweeper:
		prediction_seconds = maxf(prediction_seconds, 1.02)
	var predicted_ball = ball.global_position + ball.linear_velocity * prediction_seconds
	predicted_ball.y = _reflect_y_inside_ball_walls(predicted_ball.y)
	var keeper_distance = controlled_player.global_position.distance_to(predicted_ball)
	var opponent_carrier = _get_likely_opponent_ball_carrier()
	var opponent_distance = INF
	if opponent_carrier != null:
		opponent_distance = opponent_carrier.global_position.distance_to(predicted_ball)

	var loose_speed_floor := lerpf(780.0, 360.0, skill)
	if neuer_sweeper:
		loose_speed_floor *= 0.72
	var loose_or_passed_ball = ball.linear_velocity.length() > loose_speed_floor
	var race_margin := lerpf(260.0, -80.0, skill)
	if neuer_sweeper:
		race_margin = -210.0
	var can_win_race = keeper_distance + race_margin < opponent_distance
	if loose_or_passed_ball and can_win_race:
		return _clamp_to_field(predicted_ball)

	if opponent_carrier != null and (skill >= 0.5 or neuer_sweeper):
		var carrier_goal_distance = opponent_carrier.global_position.distance_to(goal_center)
		var keeper_goal_distance = controlled_player.global_position.distance_to(goal_center)
		var carrier_is_advancing = (
			opponent_carrier.linear_velocity.x * -attack_sign > 40.0
			or ball.last_touch_peer_id == opponent_carrier.owner_peer_id
		)
		var challenge_distance := lerpf(2300.0, 3500.0, skill)
		if neuer_sweeper:
			challenge_distance = maxf(challenge_distance, 4200.0)
		if (
			carrier_is_advancing
			and carrier_goal_distance < challenge_distance
			and keeper_goal_distance < maximum_sweep_depth
		):
			var cut_ratio := lerpf(0.22, 0.42, skill)
			if neuer_sweeper:
				cut_ratio = maxf(cut_ratio, 0.50)
			var cut_distance = minf(
				maximum_sweep_depth,
				carrier_goal_distance * cut_ratio
			)
			var cut_target = goal_center + goal_center.direction_to(
				opponent_carrier.global_position
			) * cut_distance
			return _clamp_to_field(cut_target)
	return Vector2.ZERO


func _ball_is_in_own_goal_danger() -> bool:
	var own_goal = _get_own_goal()
	if own_goal == null:
		return false
	return ball.global_position.distance_to(
		_get_goal_center(own_goal)
	) <= maxf(300.0, own_goal_danger_radius)


func _update_emergency_clearance() -> void:
	_clear_attack_plan()
	_dribble_until = 0.0
	_wall_dribble_until = 0.0
	_wall_dribble_kicked = false
	_clear_one_vs_one_space_play_state()
	_plan_is_pass = false
	_planned_receiver = null
	_shot_target = _get_safe_own_goal_clearance_target()
	_planned_destination = _shot_target
	_planned_route_distance = ball.global_position.distance_to(
		_shot_target
	)
	var emergency_strike_position: Vector2 = _get_strike_position(_shot_target)
	_movement_target = _skill_gate_advanced_goal_line_save_position(
		emergency_strike_position
	)
	_set_tactical_intent(INTENT_SHOOT, _shot_target)

	var now = _server_time_seconds()
	var ball_distance = controlled_player.global_position.distance_to(
		ball.global_position
	)
	var safe_direction = ball.global_position.direction_to(
		_shot_target
	)
	if (
		now >= _next_emergency_clear_touch_at
		and ball_distance
		<= controlled_player.kick_feedback_detection_distance
		and not safe_direction.is_zero_approx()
	):
		if controlled_player.server_is_charging:
			controlled_player.cpu_cancel_shot_charge()
			_reset_cpu_charge_tracking()
		if controlled_player.cpu_dribble_touch(
			safe_direction,
			emergency_clear_touch_force
		):
			_next_emergency_clear_touch_at = (
				now + maxf(0.1, emergency_clear_touch_interval)
			)
			return
	_try_begin_shot(true)


func _skill_gate_advanced_goal_line_save_position(
	strike_position: Vector2
) -> Vector2:
	if get_effective_skill_level() >= advanced_goal_line_save_minimum_level:
		return strike_position
	if not _is_designated_goalkeeper(controlled_player):
		return strike_position
	if not is_instance_valid(ball):
		return strike_position

	# Backing deeper toward the CPU's own goal to get perfectly behind a ball is
	# a high-skill goalkeeper technique. Lower-intelligence keepers still chase,
	# block and clear normally, but they approach the ball directly instead of
	# performing the spectacular reverse collection/setup inside the goal mouth.
	var attack_sign: float = _get_attack_sign()
	var setup_progress: float = (strike_position.x - ball.global_position.x) * attack_sign
	if setup_progress >= -20.0:
		return strike_position

	var predicted_ball: Vector2 = _get_predicted_ball_position()
	var direct_target: Vector2 = predicted_ball
	# Keep the low-level keeper on the field side of the ball whenever possible,
	# so a ball already in front of it does not make it retreat into its own net.
	direct_target.x += attack_sign * 24.0
	return _clamp_to_field(direct_target)


func _get_safe_own_goal_clearance_target() -> Vector2:
	var attack_sign: float = _get_attack_sign()
	var own_goal: FootballGoal = _get_own_goal()
	var goal_center: Vector2 = (
		_get_goal_center(own_goal)
		if own_goal != null
		else ball.global_position
	)
	var forward_distances: Array[float] = [
		maxf(700.0, emergency_clear_forward_distance * 0.75),
		maxf(1050.0, emergency_clear_forward_distance),
		maxf(1450.0, emergency_clear_forward_distance * 1.35),
		maxf(1900.0, emergency_clear_forward_distance * 1.75)
	]
	var lateral_distance: float = maxf(
		420.0,
		emergency_clear_lateral_distance
	)
	var lateral_offsets: Array[float] = [
		-lateral_distance,
		-lateral_distance * 0.55,
		0.0,
		lateral_distance * 0.55,
		lateral_distance
	]
	var best_target: Vector2 = _clamp_to_field(
		ball.global_position
		+ Vector2(attack_sign * forward_distances[0], 0.0)
	)
	var best_score: float = -INF
	for forward_distance in forward_distances:
		for lateral_offset in lateral_offsets:
			var raw_target: Vector2 = (
				ball.global_position
				+ Vector2(
					attack_sign * forward_distance,
					lateral_offset
				)
			)
			var target: Vector2 = _clamp_to_field(raw_target)
			var route_clearance: float = (
				_minimum_segment_clearance(
					ball.global_position,
					target
				)
			)
			var forward_progress: float = (
				target.x - ball.global_position.x
			) * attack_sign
			var own_goal_separation: float = (
				target.distance_to(goal_center)
			)
			var wall_margin: float = minf(
				target.y - minimum_field_y,
				maximum_field_y - target.y
			)
			var clamp_penalty: float = raw_target.distance_to(
				target
			)
			var score: float = (
				forward_progress * 0.82
				+ route_clearance * 1.15
				+ own_goal_separation * 0.32
				+ minf(wall_margin, 620.0) * 0.14
				- clamp_penalty * 1.8
			)
			if absf(lateral_offset) < 120.0:
				score -= 180.0
			if score > best_score:
				best_score = score
				best_target = target
	return best_target


func _update_relative_loose_ball_claim_decision() -> bool:
	var claim = _get_relative_loose_ball_claim()
	if claim.is_empty():
		return false
	if int(claim.get("peer_id", 0)) != controlled_player.owner_peer_id:
		return false
	if controlled_player.cpu_has_kickable_ball():
		# Once the claimant has actually collected the ball, return to the normal
		# carrier/keeper controller so it can pass, dribble, shoot, or recycle.
		return false
	if controlled_player.server_is_charging:
		controlled_player.cpu_cancel_shot_charge()
		_reset_cpu_charge_tracking()
	_clear_human_demo_plan(true)
	_clear_attack_plan()
	_movement_target = claim.get(
		"target_position",
		ball.global_position
	)
	_set_tactical_intent(INTENT_CHASE, _movement_target)
	return true


func _get_relative_loose_ball_claim() -> Dictionary:
	# Several tactical branches can ask this identical team race question in the
	# same physics tick. The first call may commit a chaser; subsequent calls use
	# that exact result instead of rerunning all teammate/opponent arrival math.
	var physics_frame := int(Engine.get_physics_frames())
	if _relative_loose_ball_claim_cache_frame == physics_frame:
		return _relative_loose_ball_claim_cache
	_relative_loose_ball_claim_cache_frame = physics_frame
	_relative_loose_ball_claim_cache = _compute_relative_loose_ball_claim()
	return _relative_loose_ball_claim_cache


func _compute_relative_loose_ball_claim() -> Dictionary:
	if (
		not relative_loose_ball_roles_enabled
		or not is_instance_valid(ball)
		or _get_active_team_player_count() <= 1
		or _is_kickoff_ball_state()
	):
		return {}
	# A real shot crossing our goal line remains goalkeeper work. The relative
	# role system is for loose balls, rebounds, weak passes, and abandoned balls.
	if not _predict_own_goal_threat(1.85).is_empty():
		return {}
	if _any_player_has_secure_live_ball_control(_get_teammates(), false):
		return {}
	if _any_player_has_secure_live_ball_control(_get_opponents(), true):
		return {}

	var speed = ball.linear_velocity.length()
	var lookahead = clampf(
		maxf(0.08, relative_loose_ball_prediction_seconds)
		+ speed / 9000.0,
		0.12,
		0.58
	)
	var predicted_ball = ball.global_position
	var damping = maxf(0.0, ball.linear_damp)
	if damping > 0.001:
		predicted_ball += (
			ball.linear_velocity
			* ((1.0 - exp(-damping * lookahead)) / damping)
		)
	else:
		predicted_ball += ball.linear_velocity * lookahead
	predicted_ball.y = _reflect_y_inside_ball_walls(predicted_ball.y)
	predicted_ball = _clamp_to_field(predicted_ball)

	var best_player: FootballPlayer
	var best_arrival = INF
	for teammate in _get_teammates():
		if not is_instance_valid(teammate) or not teammate.controls_enabled:
			continue
		var arrival = _estimate_duel_player_arrival_seconds(
			teammate,
			predicted_ball
		)
		var receive_intention = match_manager.get_cpu_pass_intention(
			teammate.owner_peer_id
		)
		if not receive_intention.is_empty():
			# Respect an announced receiver, but only as a preference. A much closer
			# teammate can still take over a genuinely loose or broken pass.
			arrival -= 0.28
		if not teammate.cpu_controlled:
			if _human_is_claiming_ball(teammate, predicted_ball):
				arrival -= 0.22
			else:
				arrival += 0.42
		if (
			arrival < best_arrival
			or (
				is_equal_approx(arrival, best_arrival)
				and best_player != null
				and teammate.owner_peer_id < best_player.owner_peer_id
			)
		):
			best_arrival = arrival
			best_player = teammate
	if best_player == null or not best_player.cpu_controlled:
		return {}

	var nearest_opponent_arrival = INF
	var nearest_opponent_space = INF
	for opponent in _get_opponents():
		if not is_instance_valid(opponent) or not opponent.controls_enabled:
			continue
		nearest_opponent_arrival = minf(
			nearest_opponent_arrival,
			_estimate_duel_player_arrival_seconds(opponent, predicted_ball)
		)
		nearest_opponent_space = minf(
			nearest_opponent_space,
			opponent.global_position.distance_to(predicted_ball)
		)
	var race_margin = maxf(0.04, relative_loose_ball_race_margin_seconds)
	var contest_margin = maxf(
		race_margin,
		relative_loose_ball_contest_margin_seconds
	)
	# Do not require the CPU to already be winning the race before assigning a
	# claimant. If neither side controls the ball, a close race is exactly when
	# somebody should attack the loose ball instead of falling into a cover role.
	# Only abandon the chase when the opponent is decisively first.
	if best_arrival > nearest_opponent_arrival + contest_margin:
		return {}
	if (
		nearest_opponent_space
		< maxf(120.0, relative_loose_ball_minimum_opponent_space * 0.55)
		and best_arrival > nearest_opponent_arrival + contest_margin * 0.72
	):
		return {}

	var committed_peer_id = match_manager.commit_cpu_ball_chaser(
		controlled_player.team,
		best_player.owner_peer_id,
		best_player.global_position.distance_to(predicted_ball),
		maxf(0.25, relative_loose_ball_commit_seconds),
		clampf(relative_loose_ball_takeover_ratio, 0.55, 0.98)
	)
	var committed_player = _get_teammate_by_peer_id(committed_peer_id)
	if committed_player == null or not committed_player.cpu_controlled:
		return {}
	var committed_arrival = _estimate_duel_player_arrival_seconds(
		committed_player,
		predicted_ball
	)
	if committed_arrival > nearest_opponent_arrival + contest_margin:
		return {}
	return {
		"peer_id": committed_player.owner_peer_id,
		"target_position": predicted_ball,
		"arrival": committed_arrival,
		"opponent_arrival": nearest_opponent_arrival
	}


func _team_ball_actor_requires_support() -> bool:
	if not team_ball_actor_enabled or not _team_likely_has_possession():
		return false
	var actor := _get_team_ball_actor()
	return actor != null and actor != controlled_player


func _player_has_secure_live_ball_control(player: FootballPlayer) -> bool:
	if (
		not is_instance_valid(player)
		or not player.controls_enabled
		or not is_instance_valid(ball)
	):
		return false
	if player.cpu_controlled:
		if not player.cpu_has_kickable_ball():
			return false
		var control_distance := maxf(
			120.0,
			player.kick_feedback_detection_distance
		)
		return (
			player.owner_peer_id == ball.last_touch_peer_id
			or player.server_is_charging
			or ball.linear_velocity.length() <= 760.0
			or player.global_position.distance_to(ball.global_position)
			<= control_distance * 0.72
		)
	var human_control_distance := maxf(
		150.0,
		player.kick_feedback_detection_distance * 1.05
	)
	return (
		player.global_position.distance_to(ball.global_position)
		<= human_control_distance
		and (
			player.server_is_charging
			or player.owner_peer_id == ball.last_touch_peer_id
			or _human_is_claiming_ball(player, ball.global_position)
		)
	)


func _get_secure_team_ball_actor() -> FootballPlayer:
	if not team_ball_actor_enabled or not is_instance_valid(ball):
		return null
	var secure_players: Array[FootballPlayer] = []
	for teammate: FootballPlayer in _get_teammates():
		if _player_has_secure_live_ball_control(teammate):
			secure_players.append(teammate)
	if secure_players.is_empty():
		return null
	for teammate: FootballPlayer in secure_players:
		if teammate.owner_peer_id == ball.last_touch_peer_id:
			return teammate
	var committed_peer_id: int = int(match_manager.get_cpu_ball_chaser(
		controlled_player.team
	))
	if committed_peer_id > 0:
		for teammate: FootballPlayer in secure_players:
			if teammate.owner_peer_id == committed_peer_id:
				return teammate
	var best_player: FootballPlayer
	var best_score := INF
	for teammate: FootballPlayer in secure_players:
		var score := teammate.global_position.distance_to(ball.global_position)
		if teammate.server_is_charging:
			score -= 220.0
		if not teammate.cpu_controlled:
			score -= 40.0
		if (
			score < best_score
			or (
				is_equal_approx(score, best_score)
				and best_player != null
				and teammate.owner_peer_id < best_player.owner_peer_id
			)
		):
			best_score = score
			best_player = teammate
	return best_player


func _get_announced_team_ball_receiver() -> FootballPlayer:
	if not is_instance_valid(match_manager):
		return null
	var best_receiver: FootballPlayer
	var best_distance := INF
	for teammate: FootballPlayer in _get_teammates():
		if not is_instance_valid(teammate) or not teammate.controls_enabled:
			continue
		var intention: Dictionary = match_manager.get_cpu_pass_intention(
			teammate.owner_peer_id
		)
		if intention.is_empty():
			continue
		var passer: FootballPlayer = _get_teammate_by_peer_id(
			int(intention.get("passer_peer_id", 0))
		)
		if passer == null:
			continue
		var receive_position: Vector2 = intention.get(
			"position",
			teammate.global_position
		)
		var distance := teammate.global_position.distance_to(receive_position)
		if (
			distance < best_distance
			or (
				is_equal_approx(distance, best_distance)
				and best_receiver != null
				and teammate.owner_peer_id < best_receiver.owner_peer_id
			)
		):
			best_distance = distance
			best_receiver = teammate
	return best_receiver


func _record_team_ball_actor(
	actor: FootballPlayer,
	reason: String
) -> FootballPlayer:
	_last_team_ball_actor_peer_id = (
		actor.owner_peer_id if is_instance_valid(actor) else 0
	)
	_last_team_ball_actor_reason = reason
	return actor


func _get_team_ball_actor() -> FootballPlayer:
	if (
		not team_ball_actor_enabled
		or not is_instance_valid(controlled_player)
		or not is_instance_valid(ball)
		or _get_active_team_player_count() <= 1
	):
		return _record_team_ball_actor(null, "legacy")
	var parallel_plan := _get_large_team_parallel_plan()
	if not parallel_plan.is_empty():
		var snapshot_possession := StringName(parallel_plan.get("possession_team", &""))
		var snapshot_actor_peer_id := int(parallel_plan.get("ball_actor_peer_id", 0))
		if snapshot_possession == controlled_player.team and snapshot_actor_peer_id > 0:
			var snapshot_actor := _get_teammate_by_peer_id(snapshot_actor_peer_id)
			if is_instance_valid(snapshot_actor) and snapshot_actor.controls_enabled:
				return _record_team_ball_actor(snapshot_actor, "parallel_possession")
		elif snapshot_possession in [TEAM_BLUE, TEAM_RED]:
			return _record_team_ball_actor(null, "parallel_opponent_control")
		var snapshot_chaser_peer_id := int(parallel_plan.get("ball_chaser_peer_id", 0))
		if snapshot_chaser_peer_id > 0:
			var snapshot_chaser := _get_teammate_by_peer_id(snapshot_chaser_peer_id)
			if is_instance_valid(snapshot_chaser) and snapshot_chaser.controls_enabled:
				return _record_team_ball_actor(snapshot_chaser, "parallel_loose_chaser")
	var secure_actor := _get_secure_team_ball_actor()
	if secure_actor != null:
		return _record_team_ball_actor(secure_actor, "secure_control")
	if _opponent_has_live_ball_control():
		return _record_team_ball_actor(null, "opponent_control")
	var announced_receiver := _get_announced_team_ball_receiver()
	if announced_receiver != null:
		return _record_team_ball_actor(
			announced_receiver,
			"announced_receiver"
		)
	var committed_peer_id: int = int(match_manager.get_cpu_ball_chaser(
		controlled_player.team
	))
	var committed_actor := _get_teammate_by_peer_id(committed_peer_id)
	if (
		committed_actor != null
		and committed_actor.controls_enabled
	):
		return _record_team_ball_actor(
			committed_actor,
			"loose_ball_commitment"
		)
	var loose_claim := _get_relative_loose_ball_claim()
	if not loose_claim.is_empty():
		var claimed_actor := _get_teammate_by_peer_id(
			int(loose_claim.get("peer_id", 0))
		)
		if claimed_actor != null:
			return _record_team_ball_actor(
				claimed_actor,
				"loose_ball_claim"
			)
	if _team_likely_has_possession():
		var likely_carrier := _get_likely_team_ball_carrier()
		if likely_carrier != null:
			return _record_team_ball_actor(
				likely_carrier,
				"inferred_possession"
			)
	return _record_team_ball_actor(null, "unassigned")


func _any_player_has_secure_live_ball_control(
	players: Array[FootballPlayer],
	_is_opponent: bool
) -> bool:
	for player: FootballPlayer in players:
		if _player_has_secure_live_ball_control(player):
			return true
	return false


func _is_primary_ball_chaser() -> bool:
	var parallel_plan := _get_large_team_parallel_plan()
	if not parallel_plan.is_empty() and parallel_plan.has("primary_ball_chaser"):
		return bool(parallel_plan.get("primary_ball_chaser", false))
	var relative_claim = _get_relative_loose_ball_claim()
	if not relative_claim.is_empty():
		return (
			int(relative_claim.get("peer_id", 0))
			== controlled_player.owner_peer_id
		)
	var teammates = (
		match_manager.blue_players
		if controlled_player.team
		== TEAM_BLUE
		else match_manager.red_players
	)
	var predicted_ball = _get_predicted_ball_position()
	var nominal_goalkeeper = match_manager.get_designated_cpu_goalkeeper(
		controlled_player.team
	)
	var own_goal = _get_own_goal()
	var own_goal_center = (
		_get_goal_center(own_goal)
		if own_goal != null
		else controlled_player.global_position
	)
	var real_goal_threat = not _predict_own_goal_threat(1.65).is_empty()
	var best_player: FootballPlayer
	var best_arrival = INF
	for teammate in teammates:
		if (
			not is_instance_valid(teammate)
			or not teammate.controls_enabled
		):
			continue
		if (
			not teammate.cpu_controlled
			and not _human_is_claiming_ball(
				teammate,
				predicted_ball
			)
		):
			continue
		var arrival = _estimate_duel_player_arrival_seconds(
			teammate,
			predicted_ball
		)
		if teammate == nominal_goalkeeper:
			if real_goal_threat:
				continue
			var ball_goal_distance = predicted_ball.distance_to(
				own_goal_center
			)
			# Goalkeeper is a relative role, not a permanent exclusion. Add a small
			# safety cost near goal, but let the keeper own a clearly faster loose
			# ball recovery when the goal is not under threat.
			arrival += clampf(
				inverse_lerp(2600.0, 900.0, ball_goal_distance),
				0.0,
				1.0
			) * 0.34
		if not teammate.cpu_controlled:
			arrival -= 0.10
		if (
			arrival < best_arrival
			or (
				is_equal_approx(arrival, best_arrival)
				and best_player != null
				and teammate.owner_peer_id < best_player.owner_peer_id
			)
		):
			best_arrival = arrival
			best_player = teammate
	if best_player == null:
		return false
	var commitment_distance = maxf(
		0.0,
		best_arrival * maxf(1.0, best_player.max_speed)
	)
	var committed_peer_id = match_manager.commit_cpu_ball_chaser(
		controlled_player.team,
		best_player.owner_peer_id,
		commitment_distance,
		ball_chaser_commitment_seconds,
		ball_chaser_takeover_ratio
	)
	return committed_peer_id == controlled_player.owner_peer_id


func _human_is_claiming_ball(
	player: FootballPlayer,
	ball_position: Vector2
) -> bool:
	var distance = player.global_position.distance_to(ball_position)
	if (
		player.server_is_charging
		or distance
		<= player.kick_feedback_detection_distance * 1.2
	):
		return true
	if distance > 1750.0:
		return false
	var toward_ball = player.global_position.direction_to(ball_position)
	var input_direction = player.server_direction.normalized()
	if (
		not input_direction.is_zero_approx()
		and input_direction.dot(toward_ball) > 0.32
	):
		return true
	return (
		player.linear_velocity.length() > 220.0
		and player.linear_velocity.normalized().dot(toward_ball) > 0.45
	)


func _get_live_receive_intention(intention: Dictionary) -> Dictionary:
	if intention.is_empty():
		return {}
	# A pass intention is advisory, while live ball control is authoritative.
	# If an opponent has intercepted/settled the ball, do not keep running or
	# precharging for a stale teammate pass that no longer exists.
	if _opponent_has_live_ball_control():
		match_manager.clear_cpu_pass_intention(
			controlled_player.owner_peer_id
		)
		return {}
	var passer_peer_id = int(intention.get("passer_peer_id", 0))
	var passer = _get_teammate_by_peer_id(passer_peer_id)
	var passer_is_preparing_kick = (
		is_instance_valid(passer)
		and (
			passer.server_is_charging
			or passer.global_position.distance_to(ball.global_position)
			<= passer.kick_feedback_detection_distance + 180.0
		)
	)
	if ball.last_touch_peer_id != passer_peer_id:
		return intention if passer_is_preparing_kick else {}
	if ball.linear_velocity.length() < incoming_pass_minimum_speed * 0.6:
		return intention if passer_is_preparing_kick else {}

	# Once the pass has actually left the foot, abandon the static announced
	# point. Recalculate where this receiver can meet the live, damped ball,
	# including top/bottom wall bounces.
	var parallel_plan := _get_large_team_parallel_plan()
	var live_candidate: Dictionary = {}
	var parallel_large_team: bool = (
		is_instance_valid(match_manager)
		and match_manager.has_method("is_large_team_parallel_ai_active")
		and bool(match_manager.call("is_large_team_parallel_ai_active"))
	)
	if (
		not parallel_plan.is_empty()
		and bool(parallel_plan.get("reception_evaluated", false))
	):
		live_candidate = parallel_plan.get("reception", {}) as Dictionary
	elif parallel_large_team:
		# The worker result normally arrives within a frame or two. Keep the
		# announced receive point meanwhile instead of recomputing the same ball
		# trajectory synchronously on the physics thread for several CPUs.
		return intention
	else:
		live_candidate = _get_reception_candidate(controlled_player)
	if live_candidate.is_empty():
		return {}
	var live_intention = intention.duplicate()
	live_intention["position"] = live_candidate.get(
		"position",
		controlled_player.global_position
	)
	live_intention["score"] = live_candidate.get("score", INF)
	live_intention["time"] = live_candidate.get("time", 0.0)
	live_intention["detected"] = true
	return live_intention


func _get_detected_pass_reception() -> Dictionary:
	var parallel_plan := _get_large_team_parallel_plan()
	if (
		not parallel_plan.is_empty()
		and bool(parallel_plan.get("reception_evaluated", false))
	):
		return parallel_plan.get("reception", {}) as Dictionary
	if (
		is_instance_valid(match_manager)
		and match_manager.has_method("is_large_team_parallel_ai_active")
		and bool(match_manager.call("is_large_team_parallel_ai_active"))
	):
		# Do not fall back to the O(players * trajectory_samples) synchronous
		# receiver scan while a large-team worker result is still in flight.
		return {}
	if (
		ball.linear_velocity.length() < incoming_pass_minimum_speed
		or ball.last_touch_peer_id == controlled_player.owner_peer_id
		or ball.get_last_touch_peer_id_for_team(controlled_player.team)
		!= ball.last_touch_peer_id
	):
		return {}
	var own_candidate = _get_reception_candidate(controlled_player)
	if own_candidate.is_empty():
		return {}
	var own_score = float(own_candidate.get("score", INF))
	for teammate in _get_teammates():
		if (
			not is_instance_valid(teammate)
			or teammate == controlled_player
			or not teammate.controls_enabled
			or teammate.owner_peer_id == ball.last_touch_peer_id
		):
			continue
		var candidate = _get_reception_candidate(teammate)
		if candidate.is_empty():
			continue
		var teammate_score = float(candidate.get("score", INF))
		if (
			teammate_score + incoming_pass_receiver_advantage < own_score
			or (
				absf(teammate_score - own_score)
				<= incoming_pass_receiver_advantage
				and teammate.owner_peer_id
				< controlled_player.owner_peer_id
			)
		):
			return {}
	return {
		"position": own_candidate.get(
			"position",
			controlled_player.global_position
		),
		"score": own_candidate.get("score", INF),
		"time": own_candidate.get("time", 0.0),
		"passer_peer_id": ball.last_touch_peer_id,
		"detected": true
	}


func _get_reception_candidate(player: FootballPlayer) -> Dictionary:
	var step_seconds = 0.08
	var prediction_seconds = maxf(0.2, incoming_pass_maximum_seconds)
	var predicted_position = ball.global_position
	var predicted_velocity = ball.linear_velocity
	var elapsed = 0.0
	var best_distance = INF
	var best_position = predicted_position
	var best_time = 0.0
	var damping = maxf(0.0, ball.linear_damp)
	while elapsed < prediction_seconds:
		var current_step = minf(step_seconds, prediction_seconds - elapsed)
		if damping > 0.001:
			predicted_velocity *= exp(-damping * current_step)
		predicted_position += predicted_velocity * current_step
		if predicted_position.y < ball_wall_top_y:
			predicted_position.y = (
				ball_wall_top_y
				+ (ball_wall_top_y - predicted_position.y)
			)
			predicted_velocity.y = absf(predicted_velocity.y) * 0.8
		elif predicted_position.y > ball_wall_bottom_y:
			predicted_position.y = (
				ball_wall_bottom_y
				- (predicted_position.y - ball_wall_bottom_y)
			)
			predicted_velocity.y = -absf(predicted_velocity.y) * 0.8
		elapsed += current_step
		var player_prediction = (
			player.global_position + player.linear_velocity * elapsed * 0.35
		)
		var distance = player_prediction.distance_to(predicted_position)
		if distance < best_distance:
			best_distance = distance
			best_position = predicted_position
			best_time = elapsed
		if predicted_velocity.length() < incoming_pass_minimum_speed * 0.45:
			break
	if best_distance > incoming_pass_lane_width:
		return {}
	return {
		"position": _clamp_to_field(best_position),
		"score": best_distance + best_time * 34.0,
		"time": best_time
	}


func _update_cpu_first_touch_awareness() -> void:
	if (
		not cpu_first_touch_enabled
		or not is_instance_valid(controlled_player)
		or not is_instance_valid(ball)
		or not is_instance_valid(match_manager)
		or _is_designated_goalkeeper(controlled_player)
		or controlled_player.server_is_charging
		or _server_time_seconds() < _next_cpu_first_touch_at
	):
		_clear_cpu_first_touch_plan()
		return
	if ball.can_return_tag_for(
		controlled_player.owner_peer_id,
		controlled_player.team
	):
		_clear_cpu_first_touch_plan()
		return
	if (
		ball.last_touch_peer_id <= 0
		or ball.last_touch_peer_id == controlled_player.owner_peer_id
		or ball.get_last_touch_peer_id_for_team(controlled_player.team)
		!= ball.last_touch_peer_id
		or ball.linear_velocity.length()
		< incoming_pass_minimum_speed * 0.55
	):
		_clear_cpu_first_touch_plan()
		return
	var combination_plan = match_manager.get_cpu_combination_plan(
		controlled_player.team
	)
	if (
		not combination_plan.is_empty()
		and int(combination_plan.get("receiver_peer_id", 0))
		== controlled_player.owner_peer_id
	):
		_clear_cpu_first_touch_plan()
		return
	if (
		controlled_player.selected_ability
		== FootballPlayer.ABILITY_DIRECT_FINISH
		and _player_ability_is_available(
			controlled_player,
			FootballPlayer.ABILITY_DIRECT_FINISH
		)
	):
		_clear_cpu_first_touch_plan()
		return
	var receive_intention = _get_live_receive_intention(
		match_manager.get_cpu_pass_intention(
			controlled_player.owner_peer_id
		)
	)
	if receive_intention.is_empty():
		receive_intention = _get_detected_pass_reception()
	if receive_intention.is_empty():
		_clear_cpu_first_touch_plan()
		return
	_ensure_cpu_first_touch_plan(
		receive_intention,
		_get_opponent_goal()
	)


func _prepare_cpu_first_touch_reception(
	receive_intention: Dictionary,
	opponent_goal: FootballGoal
) -> bool:
	if not cpu_first_touch_enabled or receive_intention.is_empty():
		return false
	_ensure_cpu_first_touch_plan(receive_intention, opponent_goal)
	if _cpu_first_touch_plan.is_empty():
		return false
	_clear_attack_plan()
	_apply_cpu_first_touch_movement_override()
	var mode = StringName(
		_cpu_first_touch_plan.get("mode", FIRST_TOUCH_NONE)
	)
	var target_peer_id = int(
		_cpu_first_touch_plan.get("target_peer_id", 0)
	)
	var target_position: Vector2 = _cpu_first_touch_plan.get(
		"target_position",
		_movement_target
	)
	match mode:
		FIRST_TOUCH_SHOT:
			_set_tactical_intent(INTENT_SHOOT, target_position)
		FIRST_TOUCH_PASS:
			_set_tactical_intent(
				INTENT_PASS,
				target_position,
				target_peer_id
			)
		FIRST_TOUCH_DUMMY:
			_set_tactical_intent(
				INTENT_FORWARD_RUN,
				_movement_target,
				target_peer_id
			)
		_:
			_set_tactical_intent(
				INTENT_RECEIVE,
				_movement_target,
				int(receive_intention.get("passer_peer_id", 0))
			)
	if mode in [FIRST_TOUCH_SHOT, FIRST_TOUCH_PASS]:
		_try_precharge_first_touch_action(
			mode,
			target_position,
			target_peer_id,
			receive_intention
		)
	return true


func _try_precharge_first_touch_action(
	mode: StringName,
	target_position: Vector2,
	target_peer_id: int,
	receive_intention: Dictionary
) -> void:
	if controlled_player.server_is_charging or target_position.is_zero_approx():
		return
	var arrival_seconds = maxf(0.0, float(receive_intention.get("time", 0.0)))
	if arrival_seconds <= 0.04 or arrival_seconds > shot_precharge_max_hold_seconds + 0.45:
		return
	var ball_distance = controlled_player.global_position.distance_to(ball.global_position)
	if ball_distance > maxf(shot_precharge_distance, controlled_player.kick_feedback_detection_distance * 1.45):
		return

	var reception_position: Vector2 = receive_intention.get(
		"position",
		controlled_player.global_position
	)
	_plan_is_pass = mode == FIRST_TOUCH_PASS
	_planned_receiver = (
		_get_teammate_by_peer_id(target_peer_id)
		if _plan_is_pass and target_peer_id > 0
		else null
	)
	if _plan_is_pass and not is_instance_valid(_planned_receiver):
		return
	_plan_uses_wall = false
	_plan_uses_double_bank = false
	_planned_destination = target_position
	_shot_target = target_position
	_planned_route_distance = reception_position.distance_to(target_position)
	_plan_expires_at = _server_time_seconds() + maxf(0.7, arrival_seconds + 0.55)
	_try_begin_shot(false)


func _ensure_cpu_first_touch_plan(
	receive_intention: Dictionary,
	opponent_goal: FootballGoal
) -> void:
	if receive_intention.is_empty() or opponent_goal == null:
		_clear_cpu_first_touch_plan()
		return
	var source_peer_id = int(
		receive_intention.get(
			"passer_peer_id",
			ball.last_touch_peer_id
		)
	)
	if source_peer_id <= 0:
		source_peer_id = ball.last_touch_peer_id
	var reception_position: Vector2 = receive_intention.get(
		"position",
		controlled_player.global_position
	)
	reception_position = _clamp_to_field(reception_position)
	if (
		not _cpu_first_touch_plan.is_empty()
		and int(_cpu_first_touch_plan.get("source_peer_id", 0))
		== source_peer_id
		and _server_time_seconds() < _cpu_first_touch_plan_until
	):
		var previous_position: Vector2 = _cpu_first_touch_plan.get(
			"reception_position",
			reception_position
		)
		_cpu_first_touch_plan["reception_position"] = reception_position
		_cpu_first_touch_plan["incoming_direction"] = (
			ball.linear_velocity.normalized()
		)
		if (
			previous_position.distance_to(reception_position)
			<= maxf(80.0, first_touch_replan_distance)
		):
			return
	_cpu_first_touch_plan = _build_cpu_first_touch_plan(
		reception_position,
		opponent_goal,
		source_peer_id
	)
	if _cpu_first_touch_plan.is_empty():
		_cpu_first_touch_plan_until = 0.0
		return
	var arrival_seconds = maxf(
		0.0,
		float(receive_intention.get("time", 0.0))
	)
	_cpu_first_touch_plan_until = (
		_server_time_seconds()
		+ clampf(
			arrival_seconds + 1.0,
			0.75,
			maxf(0.8, first_touch_plan_timeout_seconds)
		)
	)


func _build_cpu_first_touch_plan(
	reception_position: Vector2,
	opponent_goal: FootballGoal,
	source_peer_id: int
) -> Dictionary:
	var incoming_velocity = ball.linear_velocity
	var incoming_speed = incoming_velocity.length()
	var incoming_direction = incoming_velocity.normalized()
	if incoming_direction.is_zero_approx():
		return {}
	var shot_plan = _get_first_touch_shot_plan(
		reception_position,
		opponent_goal,
		incoming_direction,
		incoming_speed
	)
	if not shot_plan.is_empty():
		shot_plan["source_peer_id"] = source_peer_id
		shot_plan["reception_position"] = reception_position
		shot_plan["incoming_direction"] = incoming_direction
		return shot_plan
	var dummy_plan = _get_first_touch_dummy_plan(
		reception_position,
		incoming_direction,
		incoming_speed
	)
	if not dummy_plan.is_empty():
		dummy_plan["source_peer_id"] = source_peer_id
		dummy_plan["reception_position"] = reception_position
		dummy_plan["incoming_direction"] = incoming_direction
		return dummy_plan
	var pass_plan = _get_first_touch_pass_plan(
		reception_position,
		incoming_direction
	)
	if not pass_plan.is_empty():
		pass_plan["source_peer_id"] = source_peer_id
		pass_plan["reception_position"] = reception_position
		pass_plan["incoming_direction"] = incoming_direction
		return pass_plan
	if (
		ball.power_strike_visual_active
		or incoming_speed > maxf(
			incoming_pass_minimum_speed,
			first_touch_maximum_control_speed
		)
	):
		return {}
	var control_plan = _get_first_touch_control_plan(
		reception_position,
		incoming_direction,
		incoming_speed
	)
	control_plan["source_peer_id"] = source_peer_id
	control_plan["reception_position"] = reception_position
	control_plan["incoming_direction"] = incoming_direction
	return control_plan


func _get_first_touch_shot_plan(
	reception_position: Vector2,
	opponent_goal: FootballGoal,
	incoming_direction: Vector2,
	incoming_speed: float
) -> Dictionary:
	var goal_distance = reception_position.distance_to(
		_get_goal_center(opponent_goal)
	)
	if goal_distance > maxf(600.0, first_touch_shot_maximum_distance):
		return {}
	var mouth_range = opponent_goal.get_mouth_y_range()
	var margin = minf(
		120.0,
		maxf(45.0, (mouth_range.y - mouth_range.x) * 0.18)
	)
	var minimum_y = mouth_range.x + margin
	var maximum_y = mouth_range.y - margin
	if maximum_y <= minimum_y:
		return {}
	var goalkeeper = match_manager.get_designated_cpu_goalkeeper(
		TEAM_RED if controlled_player.team == TEAM_BLUE else TEAM_BLUE
	)
	var best_target = Vector2.ZERO
	var best_score = -INF
	for sample_index in range(9):
		var ratio = float(sample_index) / 8.0
		var candidate = Vector2(
			opponent_goal.get_goal_plane_x(),
			lerpf(minimum_y, maximum_y, ratio)
		)
		var shot_direction = reception_position.direction_to(candidate)
		if shot_direction.is_zero_approx():
			continue
		var redirect_alignment = incoming_direction.dot(shot_direction)
		if redirect_alignment < -0.08:
			continue
		var lane = _minimum_segment_clearance(
			reception_position,
			candidate
		)
		if lane < maxf(90.0, first_touch_shot_minimum_lane):
			continue
		var keeper_separation = 500.0
		if is_instance_valid(goalkeeper):
			var predicted_keeper = (
				goalkeeper.global_position
				+ goalkeeper.linear_velocity * 0.12
			)
			keeper_separation = absf(
				candidate.y - predicted_keeper.y
			)
		var score = (
			lane * 1.4
			+ keeper_separation * 0.55
			+ redirect_alignment * 260.0
			- goal_distance * 0.08
		)
		if score > best_score:
			best_score = score
			best_target = candidate
	if best_target.is_zero_approx():
		return {}
	var target_speed = clampf(
		first_touch_shot_minimum_speed
		+ goal_distance * 0.24
		+ incoming_speed * 0.12,
		first_touch_shot_minimum_speed,
		first_touch_shot_maximum_speed
	)
	return {
		"mode": FIRST_TOUCH_SHOT,
		"target_position": best_target,
		"target_speed": target_speed,
		"control_strength": 1.0,
		"target_peer_id": 0
	}


func _get_first_touch_pass_plan(
	reception_position: Vector2,
	incoming_direction: Vector2
) -> Dictionary:
	var best_plan: Dictionary = {}
	var best_score = -INF
	var attack_sign = _get_attack_sign()
	for teammate in _get_teammates():
		if (
			not is_instance_valid(teammate)
			or teammate == controlled_player
			or not teammate.controls_enabled
			or _is_designated_goalkeeper(teammate)
		):
			continue
		var target = _get_lead_pass_target(teammate)
		var distance = reception_position.distance_to(target)
		if (
			distance < maxf(180.0, first_touch_pass_minimum_distance)
			or distance > maxf(
				first_touch_pass_minimum_distance + 1.0,
				first_touch_pass_maximum_distance
			)
		):
			continue
		var pass_direction = reception_position.direction_to(target)
		if pass_direction.is_zero_approx():
			continue
		var redirect_alignment = incoming_direction.dot(pass_direction)
		if redirect_alignment < -0.32:
			continue
		var lane = _minimum_segment_clearance(reception_position, target)
		if lane < maxf(105.0, pass_lane_clearance * 0.62):
			continue
		var receiver_space = _nearest_opponent_distance(target)
		var forward_progress = (
			target.x - reception_position.x
		) * attack_sign
		var current_goal_distance = reception_position.distance_to(
			_get_goal_center(_get_opponent_goal())
		)
		var receiver_goal_distance = target.distance_to(
			_get_goal_center(_get_opponent_goal())
		)
		var goal_progress = current_goal_distance - receiver_goal_distance
		var pass_requested = (
			teammate.server_pass_request_ends_at
			> _server_time_seconds()
		)
		var receiver_is_meaningfully_better = (
			goal_progress >= 420.0
			or forward_progress >= 620.0
			or receiver_space
			>= _nearest_opponent_distance(reception_position) + 240.0
		)
		var under_reception_pressure = (
			_nearest_opponent_distance(reception_position)
			<= first_touch_directional_pressure_distance * 1.08
		)
		if (
			not pass_requested
			and not receiver_is_meaningfully_better
			and not under_reception_pressure
		):
			continue
		var score = (
			lane * 1.0
			+ receiver_space * 0.42
			+ forward_progress * 0.26
			+ goal_progress * 0.22
			+ redirect_alignment * 180.0
			- distance * 0.09
		)
		if pass_requested:
			score += 280.0
		if score > best_score:
			best_score = score
			var target_speed = clampf(
				first_touch_pass_minimum_speed + distance * 0.38,
				first_touch_pass_minimum_speed,
				first_touch_pass_maximum_speed
			)
			best_plan = {
				"mode": FIRST_TOUCH_PASS,
				"target_position": target,
				"target_speed": target_speed,
				"control_strength": 1.0,
				"target_peer_id": teammate.owner_peer_id,
				"score": score
			}
	if best_score < first_touch_pass_minimum_score:
		return {}
	return best_plan


func _get_first_touch_dummy_plan(
	reception_position: Vector2,
	incoming_direction: Vector2,
	incoming_speed: float
) -> Dictionary:
	if (
		_get_ai_skill() < first_touch_dummy_minimum_skill
		or incoming_speed < first_touch_dummy_minimum_speed
	):
		return {}
	var lateral = Vector2(-incoming_direction.y, incoming_direction.x)
	var best_teammate: FootballPlayer
	var best_target = Vector2.ZERO
	var best_score = -INF
	for teammate in _get_teammates():
		if (
			not is_instance_valid(teammate)
			or teammate == controlled_player
			or not teammate.controls_enabled
			or _is_designated_goalkeeper(teammate)
		):
			continue
		var offset = teammate.global_position - reception_position
		var forward_gap = offset.dot(incoming_direction)
		var lateral_gap = absf(offset.dot(lateral))
		if (
			forward_gap < first_touch_dummy_minimum_forward_gap
			or forward_gap > first_touch_dummy_maximum_forward_gap
			or lateral_gap > first_touch_dummy_maximum_lateral_gap
		):
			continue
		var lane = _minimum_segment_clearance(
			reception_position,
			teammate.global_position
		)
		if lane < maxf(120.0, pass_lane_clearance * 0.58):
			continue
		var teammate_space = _nearest_opponent_distance(
			teammate.global_position
		)
		var score = (
			lane * 0.9
			+ teammate_space * 0.55
			+ forward_gap * 0.24
			- lateral_gap * 0.75
		)
		if score > best_score:
			best_score = score
			best_teammate = teammate
			best_target = teammate.global_position
	if not is_instance_valid(best_teammate):
		return {}
	var side_one = _clamp_to_field(
		reception_position + lateral * first_touch_dummy_sidestep_distance
	)
	var side_two = _clamp_to_field(
		reception_position - lateral * first_touch_dummy_sidestep_distance
	)
	var side_target = (
		side_one
		if _nearest_opponent_distance(side_one)
		>= _nearest_opponent_distance(side_two)
		else side_two
	)
	return {
		"mode": FIRST_TOUCH_DUMMY,
		"target_position": best_target,
		"movement_position": side_target,
		"target_speed": 0.0,
		"control_strength": 0.0,
		"target_peer_id": best_teammate.owner_peer_id,
		"score": best_score
	}


func _get_first_touch_control_plan(
	reception_position: Vector2,
	incoming_direction: Vector2,
	incoming_speed: float
) -> Dictionary:
	var best_direction = _select_first_touch_control_direction(
		reception_position,
		incoming_direction
	)
	var pressure = _nearest_opponent_distance(reception_position)
	var mode = FIRST_TOUCH_SOFT
	var target_speed = first_touch_soft_target_speed
	if (
		pressure <= first_touch_directional_pressure_distance
		or incoming_speed > first_touch_directional_target_speed * 1.9
	):
		mode = FIRST_TOUCH_DIRECTIONAL
		target_speed = first_touch_directional_target_speed
	var control_strength = clampf(
		lerpf(
			0.92,
			0.62,
			incoming_speed / maxf(1.0, first_touch_maximum_control_speed)
		),
		0.56,
		0.96
	)
	if mode == FIRST_TOUCH_SOFT:
		control_strength = minf(0.96, control_strength + 0.12)
	return {
		"mode": mode,
		"target_position": (
			reception_position + best_direction * 900.0
		),
		"target_speed": target_speed,
		"control_strength": control_strength,
		"target_peer_id": 0
	}


func _select_first_touch_control_direction(
	reception_position: Vector2,
	incoming_direction: Vector2
) -> Vector2:
	var attack_forward = Vector2(_get_attack_sign(), 0.0)
	var candidates: Array[Vector2] = [
		attack_forward,
		attack_forward.rotated(deg_to_rad(-24.0)),
		attack_forward.rotated(deg_to_rad(24.0)),
		attack_forward.rotated(deg_to_rad(-48.0)),
		attack_forward.rotated(deg_to_rad(48.0)),
		attack_forward.rotated(deg_to_rad(-72.0)),
		attack_forward.rotated(deg_to_rad(72.0))
	]
	var nearest_opponent = _get_nearest_opponent_to(reception_position)
	if is_instance_valid(nearest_opponent):
		var escape = nearest_opponent.global_position.direction_to(
			reception_position
		)
		if not escape.is_zero_approx():
			candidates.append(
				(escape * 0.72 + attack_forward * 0.48).normalized()
			)
	var best_direction = attack_forward
	var best_score = -INF
	for candidate in candidates:
		var direction = candidate.normalized()
		if direction.is_zero_approx():
			continue
		var target = _clamp_to_field(
			reception_position + direction * 760.0
		)
		var actual_direction = reception_position.direction_to(target)
		if actual_direction.is_zero_approx():
			continue
		var space = _nearest_opponent_distance(target)
		var lane = _minimum_segment_clearance(
			reception_position,
			target
		)
		var progress = (
			target.x - reception_position.x
		) * _get_attack_sign()
		var redirect_alignment = incoming_direction.dot(actual_direction)
		var wall_margin = minf(
			target.y - minimum_field_y,
			maximum_field_y - target.y
		)
		var score = (
			space * 0.72
			+ lane * 0.62
			+ progress * 0.38
			+ redirect_alignment * 95.0
			+ minf(500.0, wall_margin) * 0.14
		)
		if score > best_score:
			best_score = score
			best_direction = actual_direction
	return best_direction.normalized()


func _update_cpu_first_touch_execution() -> bool:
	if _cpu_first_touch_plan.is_empty():
		return false
	if not _cpu_first_touch_plan_is_valid():
		_clear_cpu_first_touch_plan()
		return false
	var mode = StringName(
		_cpu_first_touch_plan.get("mode", FIRST_TOUCH_NONE)
	)
	if mode == FIRST_TOUCH_DUMMY:
		var incoming_direction: Vector2 = _cpu_first_touch_plan.get(
			"incoming_direction",
			ball.linear_velocity.normalized()
		)
		if incoming_direction.is_zero_approx():
			incoming_direction = ball.linear_velocity.normalized()
		if (
			not incoming_direction.is_zero_approx()
			and (ball.global_position - controlled_player.global_position).dot(
				incoming_direction
			) >= first_touch_dummy_passed_distance
		):
			_last_cpu_first_touch_mode = FIRST_TOUCH_DUMMY
			_clear_cpu_first_touch_plan()
			_next_cpu_first_touch_at = (
				_server_time_seconds()
				+ maxf(0.05, first_touch_action_cooldown_seconds)
			)
		return false
	if (
		mode in [FIRST_TOUCH_SHOT, FIRST_TOUCH_PASS]
		and controlled_player.server_is_charging
	):
		# The release is owned by the normal charged-shot path. This lets the CPU
		# visibly hold a kick before an anticipated reception instead of always
		# waiting for contact and then tapping the ball.
		return false
	if not controlled_player.cpu_has_kickable_ball():
		return false
	var toward_player = ball.global_position.direction_to(
		controlled_player.global_position
	)
	var approach_speed = ball.linear_velocity.dot(toward_player)
	if (
		approach_speed < first_touch_minimum_approach_speed
		and controlled_player.global_position.distance_to(
			ball.global_position
		) > controlled_player.kick_feedback_detection_distance * 0.62
	):
		return false
	var target_position: Vector2 = _cpu_first_touch_plan.get(
		"target_position",
		ball.global_position + Vector2(_get_attack_sign(), 0.0) * 900.0
	)
	var direction = ball.global_position.direction_to(target_position)
	if direction.is_zero_approx():
		direction = Vector2(_get_attack_sign(), 0.0)
	var target_speed = float(
		_cpu_first_touch_plan.get(
			"target_speed",
			first_touch_directional_target_speed
		)
	)
	var control_strength = float(
		_cpu_first_touch_plan.get("control_strength", 1.0)
	)
	var stored_mode = mode
	var stored_target_peer_id = int(
		_cpu_first_touch_plan.get("target_peer_id", 0)
	)
	if controlled_player.server_is_charging:
		controlled_player.cpu_cancel_shot_charge()
	var succeeded = controlled_player.cpu_execute_first_touch(
		mode,
		direction,
		target_speed,
		control_strength,
		stored_target_peer_id
	)
	if not succeeded:
		return false
	if stored_mode == FIRST_TOUCH_PASS and stored_target_peer_id > 0:
		match_manager.set_cpu_pass_intention(
			controlled_player.owner_peer_id,
			stored_target_peer_id,
			target_position,
			pass_intention_seconds
		)
	_last_cpu_first_touch_mode = stored_mode
	_next_cpu_first_touch_at = (
		_server_time_seconds()
		+ maxf(0.05, first_touch_action_cooldown_seconds)
	)
	_clear_cpu_first_touch_plan()
	_clear_attack_plan()
	_movement_target = _clamp_to_field(
		controlled_player.global_position + direction * 420.0
	)
	return true


func _cpu_first_touch_plan_is_valid() -> bool:
	if (
		_cpu_first_touch_plan.is_empty()
		or _server_time_seconds() >= _cpu_first_touch_plan_until
		or not is_instance_valid(ball)
		or not is_instance_valid(controlled_player)
	):
		return false
	var source_peer_id = int(
		_cpu_first_touch_plan.get("source_peer_id", 0)
	)
	if source_peer_id <= 0:
		return false
	return (
		ball.last_touch_peer_id == source_peer_id
		and ball.get_last_touch_peer_id_for_team(
			controlled_player.team
		) == source_peer_id
	)


func _apply_cpu_first_touch_movement_override() -> void:
	if _cpu_first_touch_plan.is_empty():
		return
	var mode = StringName(
		_cpu_first_touch_plan.get("mode", FIRST_TOUCH_NONE)
	)
	if mode == FIRST_TOUCH_DUMMY:
		_movement_target = _cpu_first_touch_plan.get(
			"movement_position",
			controlled_player.global_position
		)
		return
	var reception_position: Vector2 = _cpu_first_touch_plan.get(
		"reception_position",
		ball.global_position
	)
	var target_position: Vector2 = _cpu_first_touch_plan.get(
		"target_position",
		reception_position + Vector2(_get_attack_sign(), 0.0)
	)
	var outgoing_direction = reception_position.direction_to(
		target_position
	)
	if outgoing_direction.is_zero_approx():
		outgoing_direction = Vector2(_get_attack_sign(), 0.0)
	var offset = 0.0
	if mode in [FIRST_TOUCH_PASS, FIRST_TOUCH_SHOT]:
		offset = maxf(40.0, first_touch_contact_offset)
	_movement_target = _clamp_to_field(
		reception_position - outgoing_direction * offset
	)


func _clear_cpu_first_touch_plan() -> void:
	_cpu_first_touch_plan.clear()
	_cpu_first_touch_plan_until = 0.0


func _should_dribble(opponent_goal: FootballGoal) -> bool:
	var now = _server_time_seconds()
	if _is_overdrive_breakaway_finish_committed(now):
		# A clear Overdrive breakaway is a finishing sequence, not a normal
		# possession carry. In particular, do not feed it through the lateral
		# avoidance logic, which treats trailing defenders as a reason to turn.
		_dribble_until = 0.0
		_wall_dribble_until = 0.0
		_clear_solo_attack_state()
		return false
	if (
		_ball_is_in_own_goal_danger()
		and (
			not _is_true_one_vs_one()
			or _one_vs_one_requires_emergency_defense()
		)
	):
		_dribble_until = 0.0
		_wall_dribble_until = 0.0
		_clear_solo_attack_state()
		return false
	if (
		_get_active_pass_request_receiver() != null
		and now >= _solo_attack_until
	):
		_dribble_until = 0.0
		_wall_dribble_until = 0.0
		_clear_solo_attack_state()
		return false
	if (
		match_manager.is_overtime
		and ball.global_position.distance_to(
			_get_goal_center(opponent_goal)
		) < overtime_direct_play_distance
	):
		# In golden goal range, create a shot or final pass instead of
		# restarting another possession dribble.
		_dribble_until = 0.0
		_wall_dribble_until = 0.0
		_clear_solo_attack_state()
		return false
	if now < _dribble_until:
		var ready_shot_ability: int = controlled_player.selected_ability
		if (
			ready_shot_ability in [
				FootballPlayer.ABILITY_POWER_STRIKE,
				FootballPlayer.ABILITY_QUICK_TRIGGER
			]
			and _cpu_ability_is_ready()
			and _shot_ability_is_useful(ready_shot_ability)
		):
			# A dribble already did its job if a real shot window has opened.
			# Do not carry an attacking ability through the rest of the possession.
			_dribble_until = 0.0
			_clear_solo_attack_state()
			return false
		var goal_center = _get_goal_center(opponent_goal)
		var goal_distance = ball.global_position.distance_to(goal_center)
		var clear_finishing_lane = (
			goal_distance < dribble_minimum_goal_distance
			and _minimum_segment_clearance(
				ball.global_position,
				goal_center
			) >= maxf(140.0, elite_minimum_shot_lane * 0.58)
		)
		if now < _solo_attack_until and clear_finishing_lane:
			# A solo carry has opened the shot. Release the commitment instead
			# of carrying past the useful shooting window.
			_dribble_until = 0.0
			_clear_solo_attack_state()
			return false
		elif (
			_get_relevant_duel_opponent() != null
			and controlled_player.selected_ability
			== FootballPlayer.ABILITY_POWER_STRIKE
			and not _one_vs_one_power_opening_is_needed(opponent_goal)
		):
			# The lateral carry achieved its purpose. Stop dribbling and take
			# the newly opened Power Strike before the opponent can recover.
			_dribble_until = 0.0
			_clear_solo_attack_state()
			return false
		else:
			return true
	if controlled_player.server_is_charging:
		return false
	if (
		_has_active_ability(FootballPlayer.ABILITY_POWER_STRIKE)
		or _has_active_ability(FootballPlayer.ABILITY_QUICK_TRIGGER)
	):
		# Once a shot ability is running, use its short window to create a
		# strike instead of entering another possession-dribble loop.
		return false
	if (
		_is_true_one_vs_one()
		and _team_likely_has_possession()
		and not _one_vs_one_shot_has_finish_or_followup(
			_get_goal_center(opponent_goal)
		)
	):
		var one_vs_one_opponent: FootballPlayer = (
			_get_one_vs_one_opponent()
		)
		if one_vs_one_opponent != null:
			_begin_solo_attack(
				opponent_goal,
				one_vs_one_opponent,
				now,
				maxf(0.55, dribble_commit_seconds)
			)
		_dribble_until = now + maxf(
			0.35,
			dribble_commit_seconds
		)
		return true
	if _should_commit_one_vs_one_dribble(opponent_goal, now):
		return true
	if _should_commit_local_duel_dribble(opponent_goal, now):
		return true
	if (
		ball.linear_velocity.length() > 1750.0
		or ball.global_position.distance_to(
			_get_goal_center(opponent_goal)
		) < dribble_minimum_goal_distance
		or now < _plan_expires_at
	):
		return false
	if _try_begin_wall_dribble():
		return true
	var opponent_space = _nearest_opponent_distance(ball.global_position)
	var effective_dribble_chance = dribble_choice_chance
	var active_team_size = _get_checkpoint_team_player_count()
	if active_team_size >= 3:
		# 3v3/4v4 is too crowded for endless micro-touches. Preserve dribbling
		# as a real threat, especially for dribble abilities, but make passing,
		# shooting and bait/combination plans the default under traffic.
		var crowded_multiplier = 0.52 if active_team_size == 3 else 0.38
		if controlled_player.selected_ability in [
			FootballPlayer.ABILITY_BURST_DRIBBLE,
			FootballPlayer.ABILITY_ELASTIC_STEP,
			FootballPlayer.ABILITY_BLIND_SPOT,
			FootballPlayer.ABILITY_BREAKAWAY,
			FootballPlayer.ABILITY_SNAPBACK,
			FootballPlayer.ABILITY_NUTMEG
		]:
			crowded_multiplier += 0.16
		effective_dribble_chance *= crowded_multiplier
	if _get_ai_skill() >= elite_combination_minimum_skill:
		# Keep the trained value authoritative. Elite logic may add a small
		# situational bonus, but it must not replace a successfully trained
		# dribbling preference with a lower fixed constant.
		if controlled_player.selected_ability in [
			FootballPlayer.ABILITY_BURST_DRIBBLE,
			FootballPlayer.ABILITY_ELASTIC_STEP,
			FootballPlayer.ABILITY_BLIND_SPOT
		]:
			effective_dribble_chance += 0.12
		if not match_manager.get_cpu_combination_plan(
			controlled_player.team
		).is_empty():
			effective_dribble_chance *= 0.72
	if opponent_space < dribble_minimum_space:
		var pressure_ratio = 1.0 - clampf(
			opponent_space / maxf(1.0, dribble_minimum_space),
			0.0,
			1.0
		)
		if active_team_size >= 3 and _has_other_active_teammate():
			# In crowded team modes pressure is usually a cue to release the ball,
			# not to start another light-touch dribble loop.
			effective_dribble_chance -= lerpf(0.05, 0.18, pressure_ratio)
		else:
			effective_dribble_chance += lerpf(0.06, 0.16, pressure_ratio)
	effective_dribble_chance = clampf(
		effective_dribble_chance,
		0.05,
		0.95
	)
	if _rng.randf() > effective_dribble_chance:
		return false
	_dribble_until = now + maxf(0.15, dribble_commit_seconds)
	return true


func _get_one_vs_one_bypass_target(
	opponent_goal: FootballGoal,
	opponent_override: FootballPlayer = null
) -> Vector2:
	if opponent_goal == null or not is_instance_valid(ball):
		return ball.global_position if is_instance_valid(ball) else Vector2.ZERO

	var opponent = opponent_override
	if opponent == null:
		opponent = _get_one_vs_one_opponent()
	if opponent == null:
		opponent = _get_relevant_duel_opponent()
	if opponent == null:
		return _clamp_to_field(
			ball.global_position
			+ Vector2(
				_get_attack_sign()
				* maxf(420.0, one_vs_one_bypass_forward_distance),
				0.0
			)
		)

	var preview_plan: Dictionary = (
		_get_one_vs_one_space_play_preview(
			opponent_goal
		)
	)
	if not preview_plan.is_empty():
		return preview_plan.get(
			"destination",
			ball.global_position
		) as Vector2

	var attack_sign: float = _get_attack_sign()
	var goal_center: Vector2 = _get_goal_center(opponent_goal)
	var forward: Vector2 = ball.global_position.direction_to(goal_center)
	if forward.is_zero_approx():
		forward = Vector2(attack_sign, 0.0)
	var lateral: Vector2 = Vector2(-forward.y, forward.x)
	var predicted_opponent: Vector2 = (
		opponent.global_position
		+ opponent.linear_velocity * 0.24
	)

	var desired_forward: float = maxf(
		maxf(520.0, one_vs_one_bypass_forward_distance),
		(
			predicted_opponent.x
			- ball.global_position.x
		) * attack_sign
		+ maxf(120.0, one_vs_one_bypass_margin)
	)

	var forward_samples: Array[float] = [
		desired_forward * 0.78,
		desired_forward,
		desired_forward * 1.22
	]
	var lateral_samples: Array[float] = [
		-one_vs_one_bypass_lateral_distance,
		-one_vs_one_bypass_lateral_distance * 0.58,
		0.0,
		one_vs_one_bypass_lateral_distance * 0.58,
		one_vs_one_bypass_lateral_distance
	]

	var best_target: Vector2 = _clamp_to_field(
		ball.global_position + forward * desired_forward
	)
	var best_score: float = -INF
	for forward_distance in forward_samples:
		for lateral_distance in lateral_samples:
			var raw_target: Vector2 = (
				ball.global_position
				+ forward * forward_distance
				+ lateral * lateral_distance
			)
			var target: Vector2 = _clamp_to_field(raw_target)
			var bypass_margin: float = (
				target.x - predicted_opponent.x
			) * attack_sign
			var defender_line_clearance: float = _distance_to_segment(
				predicted_opponent,
				ball.global_position,
				target
			)
			var route_clearance: float = minf(
				_minimum_segment_clearance(
					ball.global_position,
					target
				),
				1500.0
			)
			var own_arrival: float = _estimate_duel_player_arrival_seconds(
				controlled_player,
				target
			)
			var opponent_arrival: float = (
				_estimate_duel_player_arrival_seconds(
					opponent,
					target
				)
			)
			var retention_margin: float = opponent_arrival - own_arrival
			var goal_progress: float = (
				target.x - ball.global_position.x
			) * attack_sign
			var wall_margin: float = minf(
				target.y - minimum_field_y,
				maximum_field_y - target.y
			)
			var clamp_penalty: float = raw_target.distance_to(target)
			var score: float = (
				goal_progress * 0.72
				+ maxf(0.0, bypass_margin) * 1.55
				+ defender_line_clearance * 1.05
				+ route_clearance * 0.36
				+ retention_margin * 1100.0
				+ minf(wall_margin, 620.0) * 0.10
				- clamp_penalty * 1.7
			)
			if bypass_margin < one_vs_one_bypass_margin:
				score -= (
					one_vs_one_bypass_margin - bypass_margin
				) * 1.35
			if retention_margin < -0.05:
				score -= 720.0
			if score > best_score:
				best_score = score
				best_target = target
	return best_target


func _one_vs_one_shot_has_finish_or_followup(
	goal_target: Vector2
) -> bool:
	if not _is_true_one_vs_one():
		return true
	var opponent: FootballPlayer = _get_one_vs_one_opponent()
	var opponent_goal: FootballGoal = _get_opponent_goal()
	if opponent == null or opponent_goal == null:
		return true

	var goal_distance: float = ball.global_position.distance_to(
		goal_target
	)
	var lane_clearance: float = _minimum_segment_clearance(
		ball.global_position,
		goal_target
	)
	var attack_sign: float = _get_attack_sign()
	var ball_bypass_margin: float = (
		ball.global_position.x - opponent.global_position.x
	) * attack_sign
	var player_bypass_margin: float = (
		controlled_player.global_position.x
		- opponent.global_position.x
	) * attack_sign
	var defender_beaten: bool = (
		maxf(ball_bypass_margin, player_bypass_margin)
		>= maxf(80.0, one_vs_one_bypass_margin)
	)

	var clear_finish: bool = (
		goal_distance
		<= maxf(650.0, one_vs_one_finish_distance)
		and lane_clearance
		>= maxf(90.0, one_vs_one_finish_lane)
	)
	if clear_finish:
		return true

	# Level 13+ understands the existing Shoot -> Pass acceleration tech. A
	# clean ranged lane is therefore a real follow-up plan instead of a shot the
	# old 1v1 gate rejects simply because the defender has not been dribbled past.
	if (
		get_effective_skill_level() >= fast_follow_up_finish_minimum_level
		and goal_distance >= maxf(0.0, fast_follow_up_finish_minimum_distance)
		and goal_distance <= maxf(
			fast_follow_up_finish_minimum_distance,
			fast_follow_up_finish_maximum_distance
		)
		and lane_clearance >= maxf(
			90.0,
			fast_follow_up_finish_minimum_lane_clearance
		)
	):
		return true

	var own_ball_arrival: float = _estimate_duel_player_arrival_seconds(
		controlled_player,
		ball.global_position
	)
	var opponent_ball_arrival: float = (
		_estimate_duel_player_arrival_seconds(
			opponent,
			ball.global_position
		)
	)
	var retains_next_action: bool = (
		own_ball_arrival
		<= opponent_ball_arrival
		+ maxf(0.0, one_vs_one_followup_arrival_margin)
	)
	return (
		defender_beaten
		and retains_next_action
		and lane_clearance >= maxf(70.0, one_vs_one_finish_lane * 0.55)
	)


func _update_overdrive_breakaway_finish(
	opponent_goal: FootballGoal
) -> bool:
	var now = _server_time_seconds()
	var committed = _is_overdrive_breakaway_finish_committed(now)
	if not committed:
		var opportunity = _get_overdrive_breakaway_opportunity(
			opponent_goal
		)
		if opportunity.is_empty():
			return false
		_overdrive_breakaway_target = opportunity.get(
			"target",
			Vector2.ZERO
		)
		_overdrive_breakaway_finish_until = now + 1.15
		committed = not _overdrive_breakaway_target.is_zero_approx()
	if not committed:
		return false

	# Keep the chosen goal area stable through the shot setup. Re-evaluating it
	# every decision tick made a clean run oscillate between dribble and shoot.
	_shot_target = _overdrive_breakaway_target
	_planned_destination = _shot_target
	_planned_route_distance = ball.global_position.distance_to(_shot_target)
	_plan_is_pass = false
	_planned_receiver = null
	_plan_uses_wall = false
	_plan_expires_at = maxf(
		_plan_expires_at,
		_overdrive_breakaway_finish_until
	)
	_dribble_until = 0.0
	_wall_dribble_until = 0.0
	_wall_dribble_kicked = false
	_movement_target = _get_strike_position(_shot_target)
	_set_tactical_intent(INTENT_SHOOT, _shot_target)
	_try_begin_shot(false)
	return true


func _is_overdrive_breakaway_finish_committed(now: float) -> bool:
	if (
		now >= _overdrive_breakaway_finish_until
		or _overdrive_breakaway_target.is_zero_approx()
		or not _team_likely_has_possession()
	):
		return false
	if controlled_player.global_position.distance_to(ball.global_position) > maxf(
		shot_precharge_distance,
		controlled_player.kick_feedback_detection_distance * 1.75
	):
		return false
	# A defender recovering goal-side or into the strike lane is a real loss of
	# the breakaway. Small pressure changes behind the ball are intentionally
	# ignored so the CPU does not panic-turn away from the net.
	if _has_outfield_opponent_goal_side_of_ball():
		return false
	return _get_overdrive_breakaway_lane_clearance(
		_overdrive_breakaway_target
	) >= 160.0


func _get_overdrive_breakaway_opportunity(
	opponent_goal: FootballGoal
) -> Dictionary:
	var now = _server_time_seconds()
	if (
		controlled_player.selected_ability
		!= FootballPlayer.ABILITY_OVERDRIVE
		or now >= _overdrive_breakaway_window_until
		or not _team_likely_has_possession()
	):
		return {}
	var ball_distance = controlled_player.global_position.distance_to(
		ball.global_position
	)
	if ball_distance > maxf(
		shot_precharge_distance,
		controlled_player.kick_feedback_detection_distance * 1.75
	):
		return {}
	var goal_center = _get_goal_center(opponent_goal)
	var goal_distance = ball.global_position.distance_to(goal_center)
	if goal_distance < 520.0 or goal_distance > committed_shot_goal_distance * 1.18:
		return {}
	var forward_progress = (
		goal_center.x - ball.global_position.x
	) * _get_attack_sign()
	if forward_progress < 320.0:
		return {}
	if _has_outfield_opponent_goal_side_of_ball():
		return {}
	if _nearest_outfield_opponent_distance(ball.global_position) < 470.0:
		return {}

	var target = _get_best_overdrive_breakaway_target(opponent_goal)
	if target.is_zero_approx():
		return {}
	var lane_clearance = _get_overdrive_breakaway_lane_clearance(
		target
	)
	if lane_clearance < 300.0:
		return {}
	return {
		"target": target,
		"lane_clearance": lane_clearance,
		"goal_distance": goal_distance
	}


func _get_best_overdrive_breakaway_target(
	opponent_goal: FootballGoal
) -> Vector2:
	var mouth_range = opponent_goal.get_mouth_y_range()
	var minimum_y = mouth_range.x + 140.0
	var maximum_y = mouth_range.y - 140.0
	var center_y = (minimum_y + maximum_y) * 0.5
	var goalkeeper = match_manager.get_designated_cpu_goalkeeper(
		TEAM_RED
		if controlled_player.team == TEAM_BLUE
		else TEAM_BLUE
	)
	var goalkeeper_y = center_y
	if is_instance_valid(goalkeeper):
		goalkeeper_y = goalkeeper.global_position.y
	var best_target = Vector2.ZERO
	var best_score = -INF
	for sample_index in range(9):
		var ratio = float(sample_index) / 8.0
		var candidate = Vector2(
			opponent_goal.get_goal_plane_x(),
			lerpf(minimum_y, maximum_y, ratio)
		)
		var lane_clearance = _get_overdrive_breakaway_lane_clearance(
			candidate
		)
		var goalkeeper_separation = absf(candidate.y - goalkeeper_y)
		var center_penalty = absf(candidate.y - center_y) * 0.08
		var score = (
			lane_clearance * 1.2
			+ goalkeeper_separation * 0.85
			- center_penalty
		)
		if score > best_score:
			best_score = score
			best_target = candidate
	return best_target


func _get_overdrive_breakaway_lane_clearance(
	target: Vector2
) -> float:
	var goalkeeper = match_manager.get_designated_cpu_goalkeeper(
		TEAM_RED
		if controlled_player.team == TEAM_BLUE
		else TEAM_BLUE
	)
	var clearance = INF
	for opponent in _get_opponents():
		if (
			not is_instance_valid(opponent)
			or not opponent.controls_enabled
			or opponent == goalkeeper
		):
			continue
		clearance = minf(
			clearance,
			_distance_to_segment(
				opponent.global_position,
				ball.global_position,
				target
			) - _get_ability_interception_bonus(opponent)
		)
	return clearance


func _has_outfield_opponent_goal_side_of_ball() -> bool:
	var goalkeeper = match_manager.get_designated_cpu_goalkeeper(
		TEAM_RED
		if controlled_player.team == TEAM_BLUE
		else TEAM_BLUE
	)
	for opponent in _get_opponents():
		if (
			not is_instance_valid(opponent)
			or not opponent.controls_enabled
			or opponent == goalkeeper
		):
			continue
		if (
			(opponent.global_position.x - ball.global_position.x)
			* _get_attack_sign()
			> 90.0
		):
			return true
	return false


func _nearest_outfield_opponent_distance(position: Vector2) -> float:
	var goalkeeper = match_manager.get_designated_cpu_goalkeeper(
		TEAM_RED
		if controlled_player.team == TEAM_BLUE
		else TEAM_BLUE
	)
	var nearest = INF
	for opponent in _get_opponents():
		if (
			is_instance_valid(opponent)
			and opponent.controls_enabled
			and opponent != goalkeeper
		):
			nearest = minf(
				nearest,
				opponent.global_position.distance_to(position)
			)
	return nearest


func _update_dribble(opponent_goal: FootballGoal) -> void:
	if (
		_ball_is_in_own_goal_danger()
		and (
			not _is_true_one_vs_one()
			or _one_vs_one_requires_emergency_defense()
		)
	):
		_update_emergency_clearance()
		return
	if _server_time_seconds() < _wall_dribble_until:
		_update_wall_dribble()
		return
	_wall_dribble_kicked = false
	var now = _server_time_seconds()
	var direction = ball.global_position.direction_to(
		_get_goal_center(opponent_goal)
	)
	var nearest_opponent = _get_nearest_opponent_to(
		ball.global_position
	)
	var solo_opponent = _get_solo_attack_defender()
	var using_solo_direction = (
		now < _solo_attack_until
		and solo_opponent != null
	)
	if _is_true_one_vs_one() and nearest_opponent != null:
		var bypass_target: Vector2 = _get_one_vs_one_bypass_target(
			opponent_goal,
			nearest_opponent
		)
		var bypass_direction: Vector2 = (
			ball.global_position.direction_to(bypass_target)
		)
		if not bypass_direction.is_zero_approx():
			direction = bypass_direction
			using_solo_direction = true
			solo_opponent = nearest_opponent
	elif using_solo_direction:
		if (
			now >= _solo_attack_direction_lock_until
			or _solo_attack_direction.is_zero_approx()
		):
			_solo_attack_direction = _select_committed_solo_direction(
				opponent_goal,
				solo_opponent
			)
			_solo_attack_direction_lock_until = (
				now + maxf(0.12, local_duel_direction_lock_seconds)
			)
		direction = _solo_attack_direction
	elif (
		_get_relevant_duel_opponent() != null
		and nearest_opponent != null
		and controlled_player.selected_ability
		== FootballPlayer.ABILITY_ELASTIC_STEP
		and controlled_player.global_position.distance_to(
			nearest_opponent.global_position
		) <= maxf(300.0, one_vs_one_elastic_pressure_distance)
	):
		var elastic_direction = _get_elastic_escape_direction()
		direction = (
			elastic_direction * 0.82 + direction * 0.56
		).normalized()
	elif (
		_get_relevant_duel_opponent() != null
		and nearest_opponent != null
		and controlled_player.selected_ability
		== FootballPlayer.ABILITY_POWER_STRIKE
		and _one_vs_one_power_opening_is_needed(opponent_goal)
	):
		direction = _get_one_vs_one_power_opening_direction(
			opponent_goal,
			nearest_opponent
		)
	if nearest_opponent != null and not using_solo_direction:
		var away = nearest_opponent.global_position.direction_to(
			ball.global_position
		)
		direction = (
			direction
			+ away * dribble_lateral_avoidance
		).normalized()
	direction = _skill_gate_reverse_dribble_direction(direction)
	if direction.is_zero_approx():
		direction = Vector2(_get_attack_sign(), 0.0)
	_shot_target = ball.global_position + direction * 1200.0
	_movement_target = (
		_get_predicted_ball_position()
		- direction * maxf(120.0, strike_position_distance * 0.86)
	)

	var touch_force = dribble_touch_force
	var active_team_size = _get_checkpoint_team_player_count()
	if active_team_size >= 3 and not using_solo_direction:
		touch_force *= 1.12 if active_team_size == 3 else 1.18
	if using_solo_direction and solo_opponent != null:
		var solo_pressure = 1.0 - clampf(
			solo_opponent.global_position.distance_to(ball.global_position)
			/ maxf(1.0, local_duel_detection_radius),
			0.0,
			1.0
		)
		touch_force = lerpf(
			dribble_touch_force,
			minf(contest_escape_touch_force, dribble_touch_force * 1.55),
			solo_pressure
		)
	var contact_direction = controlled_player.global_position.direction_to(
		ball.global_position
	)
	if (
		now >= _next_dribble_touch_at
		and controlled_player.global_position.distance_to(
			ball.global_position
		) <= controlled_player.kick_feedback_detection_distance
		and contact_direction.dot(direction) >= 0.7
	):
		if controlled_player.cpu_dribble_touch(
			direction,
			touch_force
		):
			_next_dribble_touch_at = (
				now + maxf(0.1, dribble_touch_interval)
			)


func _is_kickoff_ball_state() -> bool:
	if (
		not kickoff_strategy_enabled
		or not is_instance_valid(ball)
		or not is_instance_valid(controlled_player)
		or not is_instance_valid(match_manager)
		or not controlled_player.controls_enabled
		or not bool(
			match_manager.get(
				"_match_clock_waiting_for_kickoff"
			)
		)
	):
		return false
	var center = Vector2(
		(minimum_field_x + maximum_field_x) * 0.5,
		(minimum_field_y + maximum_field_y) * 0.5
	)
	return (
		ball.global_position.distance_to(center) <= kickoff_center_tolerance
		and ball.linear_velocity.length() <= kickoff_ball_speed_tolerance
	)


func _select_competitive_kickoff_strategy() -> StringName:
	var opponent: FootballPlayer = _get_one_vs_one_opponent()
	if opponent == null:
		return &"possession"
	var opponent_rushing = (
		opponent.linear_velocity.length() >= kickoff_opponent_rush_speed
		or opponent.global_position.distance_to(ball.global_position)
		< controlled_player.global_position.distance_to(ball.global_position) - 110.0
	)
	if opponent_rushing:
		match _kickoff_sequence_index % 3:
			0:
				return &"delayed_counter"
			1:
				return &"fake"
			_:
				return &"aggressive"
	match _kickoff_sequence_index % 5:
		0:
			return &"possession"
		1:
			return &"delayed"
		2:
			return &"wall_control"
		3:
			return &"aggressive"
		_:
			return &"fake"


func _begin_competitive_kickoff_strategy() -> void:
	if _get_active_team_player_count() > 1:
		var own_eta: float = _estimate_kickoff_arrival_seconds(controlled_player)
		var opponent_eta: float = _get_fastest_opponent_kickoff_eta()
		# The locked first man commits. If an opponent with a speed advantage
		# (for example permanent Overdrive) can contest the ball first, meet the
		# challenge aggressively instead of performing a fake retreat.
		_kickoff_strategy = (
			&"aggressive"
			if opponent_eta <= own_eta + 0.10
			else &"possession"
		)
	else:
		_kickoff_strategy = _select_competitive_kickoff_strategy()
	_kickoff_strategy_started_at = _server_time_seconds()
	_kickoff_strategy_until = _kickoff_strategy_started_at + kickoff_strategy_commit_seconds
	_kickoff_touch_completed = false
	_kickoff_side *= -1.0
	_kickoff_sequence_index += 1


func _get_coordinated_kickoff_taker() -> FootballPlayer:
	if (
		match_manager != null
		and match_manager.has_method("get_cpu_kickoff_taker")
	):
		var locked_taker := match_manager.call(
			"get_cpu_kickoff_taker",
			controlled_player.team
		) as FootballPlayer
		if locked_taker != null:
			return locked_taker

	# Fallback only for isolated tests/custom scenes that do not use the manager
	# reset pipeline. Live matches use the locked reset-time assignment above.
	var best_player: FootballPlayer
	var best_eta: float = INF
	for teammate in _get_teammates():
		if (
			not is_instance_valid(teammate)
			or not teammate.controls_enabled
			or not teammate.cpu_controlled
		):
			continue
		var eta: float = _estimate_kickoff_arrival_seconds(teammate)
		if eta < best_eta:
			best_eta = eta
			best_player = teammate
	return best_player


func _get_kickoff_effective_speed(player: FootballPlayer) -> float:
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
		speed *= 1.15
	return speed


func _estimate_kickoff_arrival_seconds(player: FootballPlayer) -> float:
	if player == null or not is_instance_valid(ball):
		return INF
	return (
		player.global_position.distance_to(ball.global_position)
		/ _get_kickoff_effective_speed(player)
	)


func _get_fastest_opponent_kickoff_eta() -> float:
	var best_eta: float = INF
	for opponent in _get_opponents():
		if not is_instance_valid(opponent) or not opponent.controls_enabled:
			continue
		best_eta = minf(
			best_eta,
			_estimate_kickoff_arrival_seconds(opponent)
		)
	return best_eta


func _get_locked_kickoff_role() -> StringName:
	if (
		match_manager != null
		and match_manager.has_method("get_cpu_kickoff_role")
	):
		return StringName(
			match_manager.call("get_cpu_kickoff_role", controlled_player)
		)
	return &""




func _get_kickoff_support_target(
	center: Vector2,
	taker: FootballPlayer
) -> Vector2:
	var attack_sign: float = _get_attack_sign()
	var role: StringName = _get_locked_kickoff_role()
	var spawn_side: float = (
		-1.0
		if controlled_player.global_position.y < center.y
		else 1.0
	)

	match role:
		&"goal_cover":
			return _clamp_to_field(
				center + Vector2(-attack_sign * 1780.0, 0.0)
			)
		&"cheat":
			# Rocket-League-style second man: stay close enough to collect a
			# dead kickoff/rebound without double-committing into the first touch.
			return _clamp_to_field(
				center + Vector2(-attack_sign * 520.0, spawn_side * 120.0)
			)
		&"wide":
			return _clamp_to_field(
				center + Vector2(-attack_sign * 760.0, spawn_side * 760.0)
			)
		&"cover":
			return _clamp_to_field(
				center + Vector2(-attack_sign * 1180.0, spawn_side * 260.0)
			)

	# Fallback for custom scenes without prepared kickoff metadata.
	var designated_keeper: FootballPlayer = match_manager.get_designated_cpu_goalkeeper(
		controlled_player.team
	)
	if controlled_player == designated_keeper:
		return _clamp_to_field(
			center + Vector2(-attack_sign * 1780.0, 0.0)
		)
	return _clamp_to_field(
		center + Vector2(-attack_sign * 720.0, spawn_side * 520.0)
	)


func _update_competitive_kickoff_strategy() -> bool:
	var centered_now: bool = _is_kickoff_ball_state()
	var center: Vector2 = Vector2(
		(minimum_field_x + maximum_field_x) * 0.5,
		(minimum_field_y + maximum_field_y) * 0.5
	)

	# In team modes exactly one CPU per side attacks the stationary kickoff ball.
	# The old logic independently gave every CPU the same kickoff plan, so 4v4
	# produced an eight-body pile-up plus eight synchronized tactical updates.
	if centered_now and _get_active_team_player_count() > 1:
		var kickoff_taker: FootballPlayer = _get_coordinated_kickoff_taker()
		if kickoff_taker != null and kickoff_taker != controlled_player:
			_clear_kickoff_strategy()
			_kickoff_last_ball_centered = true
			_movement_target = _get_kickoff_support_target(center, kickoff_taker)
			_set_tactical_intent(INTENT_COVER, _movement_target)
			return true

	if centered_now and not _kickoff_last_ball_centered:
		_begin_competitive_kickoff_strategy()
	_kickoff_last_ball_centered = centered_now
	if _kickoff_strategy == &"":
		return false
	var now: float = _server_time_seconds()
	if now >= _kickoff_strategy_until:
		_clear_kickoff_strategy()
		return false
	var attack_sign: float = _get_attack_sign()
	var elapsed: float = now - _kickoff_strategy_started_at
	var opponent: FootballPlayer = _get_one_vs_one_opponent()
	var side_target: Vector2 = _clamp_to_field(
		center + Vector2(attack_sign * 760.0, _kickoff_side * kickoff_side_offset)
	)
	match _kickoff_strategy:
		&"delayed":
			if elapsed < kickoff_delayed_wait_seconds:
				_movement_target = controlled_player.global_position
				_set_tactical_intent(INTENT_COVER, center)
				return true
			_movement_target = _get_strike_position(side_target)
			_try_kickoff_touch(side_target, kickoff_counter_touch_force)
		&"delayed_counter":
			if elapsed < kickoff_delayed_wait_seconds * 1.35:
				_movement_target = _clamp_to_field(
					center + Vector2(-attack_sign * 260.0, _kickoff_side * 120.0)
				)
				_set_tactical_intent(INTENT_COVER, center)
				return true
			var counter_target: Vector2 = side_target
			if opponent != null:
				counter_target = _clamp_to_field(
					opponent.global_position + Vector2(
						attack_sign * 720.0,
						-_kickoff_side * 360.0
					)
				)
			_movement_target = _get_strike_position(counter_target)
			_try_kickoff_touch(counter_target, kickoff_counter_touch_force)
		&"fake":
			if ball.linear_velocity.length() < 260.0:
				_movement_target = _clamp_to_field(
					center + Vector2(
						-attack_sign * kickoff_fake_retreat_distance,
						_kickoff_side * 230.0
					)
				)
				_set_tactical_intent(INTENT_COVER, ball.global_position)
				return true
			_movement_target = _predict_ball_position_for_seconds(0.32)
			_set_tactical_intent(INTENT_CHASE, _movement_target)
		&"wall_control":
			var wall_y: float = (
				minimum_field_y + 150.0
				if _kickoff_side < 0.0
				else maximum_field_y - 150.0
			)
			var wall_target: Vector2 = _clamp_to_field(
				Vector2(center.x + attack_sign * 920.0, wall_y)
			)
			_movement_target = _get_strike_position(wall_target)
			_try_kickoff_touch(wall_target, kickoff_wall_touch_force)
		&"aggressive":
			var aggressive_target: Vector2 = _clamp_to_field(
				center + Vector2(
					attack_sign * 1280.0,
					_kickoff_side * 150.0
				)
			)
			_movement_target = _get_strike_position(aggressive_target)
			_try_kickoff_touch(aggressive_target, kickoff_aggressive_touch_force)
		_:
			_movement_target = _get_strike_position(side_target)
			_try_kickoff_touch(side_target, kickoff_possession_touch_force)
	_set_tactical_intent(INTENT_DRIBBLE, _movement_target)
	if _kickoff_touch_completed and ball.linear_velocity.length() > 320.0:
		_clear_kickoff_strategy()
	return true


func _try_kickoff_touch(target: Vector2, requested_force: float) -> void:
	if _kickoff_touch_completed or not controlled_player.cpu_has_kickable_ball():
		return
	var direction: Vector2 = ball.global_position.direction_to(target)
	if direction.is_zero_approx():
		return
	var contact_direction = controlled_player.global_position.direction_to(ball.global_position)
	if contact_direction.dot(direction) < 0.48:
		return
	if controlled_player.cpu_dribble_touch(
		direction,
		clampf(requested_force, controlled_player.minimum_shot_force, controlled_player.maximum_shot_force)
	):
		_kickoff_touch_completed = true


func _clear_kickoff_strategy() -> void:
	_kickoff_strategy = &""
	_kickoff_strategy_started_at = -INF
	_kickoff_strategy_until = 0.0
	_kickoff_touch_completed = false


func _get_elite_finish_preview(
	opponent_goal: FootballGoal
) -> Dictionary:
	if (
		opponent_goal == null
		or not is_instance_valid(ball)
		or not is_instance_valid(controlled_player)
		or ball.global_position.distance_to(
			_get_goal_center(opponent_goal)
		) > elite_finish_maximum_scan_distance
	):
		return {}
	return _scan_elite_goal_trajectories(
		opponent_goal,
		_get_one_vs_one_opponent()
	)


func _scan_elite_goal_trajectories(
	opponent_goal: FootballGoal,
	opponent: FootballPlayer
) -> Dictionary:
	var mouth: Vector2 = opponent_goal.get_mouth_y_range()
	var margin: float = maxf(20.0, elite_finish_goal_margin)
	var minimum_y: float = mouth.x + margin
	var maximum_y: float = mouth.y - margin
	if maximum_y <= minimum_y:
		return {}
	var goal_x: float = opponent_goal.get_goal_plane_x()
	var best_plan: Dictionary = {}
	var best_probability: float = -INF
	var count: int = _get_dynamic_goal_sample_count(
		maxi(5, elite_finish_goal_samples)
	) + int(round(get_elite_skill_extension_ratio() * 4.0))
	for index in range(count):
		var ratio: float = float(index) / float(count - 1)
		var target = Vector2(goal_x, lerpf(minimum_y, maximum_y, ratio))
		for force_ratio in [1.0, elite_finish_controlled_maximum_ratio, elite_finish_controlled_minimum_ratio]:
			var plan = _evaluate_elite_goal_route(
				target,
				force_ratio,
				false,
				Vector2.ZERO,
				opponent
			)
			var probability: float = float(plan.get("goal_probability", -INF))
			if probability > best_probability:
				best_probability = probability
				best_plan = plan
	var wall_count: int = maxi(
		2,
		elite_finish_wall_samples
		+ int(round(
			float(maxi(0, high_tempo_extra_goal_samples)) * 0.45
			* _get_high_tempo_strength()
		))
	) + int(round(get_elite_skill_extension_ratio() * 2.0))
	for index in range(wall_count):
		var ratio: float = float(index) / float(wall_count - 1)
		var target = Vector2(goal_x, lerpf(minimum_y, maximum_y, ratio))
		var wall_route: Dictionary = _get_best_wall_route(target)
		if wall_route.is_empty():
			continue
		var bounce: Vector2 = wall_route.get("bounce", Vector2.ZERO) as Vector2
		for force_ratio in [1.0, elite_finish_controlled_maximum_ratio]:
			var plan = _evaluate_elite_goal_route(
				target,
				force_ratio,
				true,
				bounce,
				opponent
			)
			var probability: float = float(plan.get("goal_probability", -INF))
			if probability > best_probability:
				best_probability = probability
				best_plan = plan
	return best_plan


func _evaluate_elite_goal_route(
	goal_target: Vector2,
	force_ratio: float,
	uses_wall: bool,
	wall_bounce: Vector2,
	opponent: FootballPlayer
) -> Dictionary:
	var launch_target: Vector2 = (
		wall_bounce if uses_wall else goal_target
	)
	var force: float = lerpf(
		controlled_player.minimum_shot_force,
		controlled_player.maximum_shot_force,
		clampf(force_ratio, 0.0, 1.0)
	)
	var first_distance: float = ball.global_position.distance_to(
		launch_target
	)
	var second_distance: float = (
		wall_bounce.distance_to(goal_target)
		if uses_wall
		else 0.0
	)
	var ball_time: float = _estimate_elite_route_time(
		first_distance,
		second_distance,
		force,
		uses_wall
	)
	if not is_finite(ball_time):
		return {}

	var launch_clearance: float = _minimum_segment_clearance(
		ball.global_position,
		launch_target
	)
	var final_clearance: float = launch_clearance
	if uses_wall:
		final_clearance = _minimum_segment_clearance(
			wall_bounce,
			goal_target
		)
	var route_clearance: float = minf(
		launch_clearance,
		final_clearance
	)

	var opponent_intercept_time: float = INF
	var ball_intercept_time: float = ball_time
	var opponent_route_distance: float = INF
	var intercept_point: Vector2 = goal_target
	var intercept_on_second_segment: bool = false

	if opponent != null:
		var first_point: Vector2 = _closest_point_on_segment(
			opponent.global_position,
			ball.global_position,
			launch_target
		)
		var first_opponent_distance: float = (
			opponent.global_position.distance_to(first_point)
		)
		intercept_point = first_point
		opponent_route_distance = first_opponent_distance

		if uses_wall:
			var second_point: Vector2 = _closest_point_on_segment(
				opponent.global_position,
				wall_bounce,
				goal_target
			)
			var second_opponent_distance: float = (
				opponent.global_position.distance_to(second_point)
			)
			if second_opponent_distance < first_opponent_distance:
				intercept_point = second_point
				opponent_route_distance = second_opponent_distance
				intercept_on_second_segment = true

		opponent_intercept_time = _estimate_duel_player_arrival_seconds(
			opponent,
			intercept_point
		)
		ball_intercept_time = _estimate_elite_time_to_route_point(
			intercept_point,
			launch_target,
			first_distance,
			force,
			uses_wall,
			intercept_on_second_segment
		)

	var timing_margin: float = (
		opponent_intercept_time
		+ elite_finish_reaction_seconds
		- ball_intercept_time
	)
	var route_quality: float = clampf(
		(route_clearance - 36.0) / 430.0,
		0.0,
		1.0
	)
	var timing_quality: float = clampf(
		(timing_margin + 0.12) / 0.48,
		0.0,
		1.0
	)
	var speed_quality: float = clampf(force_ratio, 0.0, 1.0)
	var goal_distance: float = ball.global_position.distance_to(
		goal_target
	)
	var distance_quality: float = clampf(
		1.0
		- goal_distance
		/ maxf(1.0, elite_finish_maximum_scan_distance),
		0.0,
		1.0
	)
	var attack_sign: float = _get_attack_sign()
	var defender_behind_ball: bool = false
	if opponent != null:
		defender_behind_ball = (
			(opponent.global_position.x - ball.global_position.x)
			* attack_sign < -80.0
		)
	var open_lane: bool = (
		opponent == null
		or opponent_route_distance >= 300.0
		or timing_margin >= 0.16
	)

	var probability: float = (
		0.12
		+ route_quality * 0.27
		+ timing_quality * 0.41
		+ speed_quality * 0.12
		+ distance_quality * 0.08
	)
	if open_lane:
		probability += elite_finish_open_lane_bonus
	if goal_distance <= 2250.0:
		probability += elite_finish_close_range_bonus
	if defender_behind_ball:
		probability += elite_finish_defender_behind_bonus
	if (
		opponent != null
		and opponent_route_distance < 210.0
		and force_ratio >= 0.94
		and timing_margin >= -0.06
	):
		probability += elite_finish_through_defender_bonus
	if uses_wall:
		probability -= elite_finish_wall_probability_penalty
	if (
		route_clearance < elite_finish_minimum_lane_clearance
		and timing_margin < 0.02
	):
		probability -= 0.18
	if timing_margin < -0.10:
		probability -= 0.30

	return {
		"goal_target": goal_target,
		"launch_target": launch_target,
		"uses_wall": uses_wall,
		"wall_bounce": wall_bounce,
		"force_ratio": force_ratio,
		"ball_time": ball_time,
		"ball_intercept_time": ball_intercept_time,
		"opponent_intercept_time": opponent_intercept_time,
		"timing_margin": timing_margin,
		"route_clearance": route_clearance,
		"open_lane": open_lane,
		"goal_probability": clampf(probability, 0.0, 0.99)
	}


func _estimate_elite_route_time(
	first_distance: float,
	second_distance: float,
	launch_force: float,
	uses_wall: bool
) -> float:
	var first_time: float = _estimate_elite_ball_travel_time(
		first_distance,
		launch_force,
		false
	)
	if not is_finite(first_time):
		return INF
	if not uses_wall:
		return first_time
	var damping: float = maxf(0.0, ball.linear_damp)
	var speed_at_wall: float = maxf(
		1.0,
		launch_force * exp(-damping * first_time)
	)
	var post_wall_speed: float = (
		speed_at_wall
		* maxf(0.30, _get_double_bank_wall_restitution())
	)
	var second_time: float = _estimate_elite_ball_travel_time(
		second_distance,
		post_wall_speed,
		false
	)
	if not is_finite(second_time):
		return INF
	return first_time + second_time


func _estimate_elite_time_to_route_point(
	route_point: Vector2,
	launch_target: Vector2,
	first_distance: float,
	launch_force: float,
	uses_wall: bool,
	on_second_segment: bool
) -> float:
	if not uses_wall or not on_second_segment:
		return _estimate_elite_ball_travel_time(
			ball.global_position.distance_to(route_point),
			launch_force,
			false
		)
	var first_time: float = _estimate_elite_ball_travel_time(
		first_distance,
		launch_force,
		false
	)
	if not is_finite(first_time):
		return INF
	var damping: float = maxf(0.0, ball.linear_damp)
	var speed_at_wall: float = maxf(
		1.0,
		launch_force * exp(-damping * first_time)
	)
	var post_wall_speed: float = (
		speed_at_wall
		* maxf(0.30, _get_double_bank_wall_restitution())
	)
	var second_time: float = _estimate_elite_ball_travel_time(
		launch_target.distance_to(route_point),
		post_wall_speed,
		false
	)
	if not is_finite(second_time):
		return INF
	return first_time + second_time


func _closest_point_on_segment(
	point: Vector2,
	start: Vector2,
	end: Vector2
) -> Vector2:
	var segment: Vector2 = end - start
	var length_squared: float = segment.length_squared()
	if length_squared <= 0.001:
		return start
	var ratio: float = clampf((point - start).dot(segment) / length_squared, 0.0, 1.0)
	return start + segment * ratio


func _estimate_elite_ball_travel_time(
	route_distance: float,
	launch_force: float,
	uses_wall: bool
) -> float:
	var effective_speed: float = maxf(1.0, launch_force)
	if uses_wall:
		effective_speed *= maxf(0.30, _get_double_bank_wall_restitution())
	var damping: float = maxf(0.0, ball.linear_damp)
	if damping <= 0.001:
		return route_distance / effective_speed
	var maximum_distance: float = effective_speed / damping
	if route_distance >= maximum_distance * 0.99:
		return INF
	return -log(maxf(0.0001, 1.0 - route_distance * damping / effective_speed)) / damping


func _try_execute_elite_finish_scan(
	opponent_goal: FootballGoal,
	require_kickable_ball: bool
) -> bool:
	if (
		opponent_goal == null
		or controlled_player.server_is_charging
		or (require_kickable_ball and not controlled_player.cpu_has_kickable_ball())
	):
		return false
	var plan: Dictionary = _scan_elite_goal_trajectories(
		opponent_goal,
		_get_one_vs_one_opponent()
	)
	if plan.is_empty():
		return false
	var probability: float = float(plan.get("goal_probability", 0.0))
	if probability < elite_controlled_shot_probability:
		return false
	var charge_ratio: float = clampf(
		float(plan.get("force_ratio", 0.7)),
		elite_finish_controlled_minimum_ratio,
		elite_finish_controlled_maximum_ratio
	)
	if probability >= elite_full_charge_goal_probability:
		charge_ratio = 1.0
	var launch_target: Vector2 = plan.get("launch_target", _get_goal_center(opponent_goal)) as Vector2
	_clear_one_vs_one_space_play_state()
	_elite_finish_plan = plan.duplicate(true)
	_elite_forced_charge_ratio = charge_ratio
	_shot_target = launch_target
	_planned_destination = plan.get("goal_target", launch_target) as Vector2
	_planned_route_distance = (
		ball.global_position.distance_to(launch_target)
		if not bool(plan.get("uses_wall", false))
		else ball.global_position.distance_to(launch_target) + launch_target.distance_to(_planned_destination)
	)
	_plan_is_pass = false
	_planned_receiver = null
	_plan_uses_double_bank = false
	_movement_target = _get_strike_position(launch_target)
	_set_tactical_intent(INTENT_SHOOT, launch_target)
	_try_begin_shot(false)
	return true


func _clear_elite_finish_plan() -> void:
	_elite_finish_plan.clear()
	_elite_forced_charge_ratio = -1.0


func _get_one_vs_one_space_play_preview(
	opponent_goal: FootballGoal
) -> Dictionary:
	if (
		not one_vs_one_space_play_enabled
		or not _is_true_one_vs_one()
		or opponent_goal == null
		or not is_instance_valid(ball)
		or not is_instance_valid(controlled_player)
	):
		return {}
	var opponent: FootballPlayer = _get_one_vs_one_opponent()
	if opponent == null:
		return {}
	return _scan_one_vs_one_space_play(
		opponent_goal,
		opponent
	)


func _scan_one_vs_one_space_play(
	opponent_goal: FootballGoal,
	opponent: FootballPlayer
) -> Dictionary:
	if (
		opponent_goal == null
		or opponent == null
		or not is_instance_valid(ball)
	):
		return {}

	var attack_sign: float = _get_attack_sign()
	var goal_center: Vector2 = _get_goal_center(opponent_goal)
	var forward: Vector2 = ball.global_position.direction_to(
		goal_center
	)
	if forward.is_zero_approx():
		forward = Vector2(attack_sign, 0.0)
	var lateral: Vector2 = Vector2(-forward.y, forward.x)
	var predicted_opponent: Vector2 = (
		opponent.global_position
		+ opponent.linear_velocity * 0.24
	)
	var defender_forward_distance: float = (
		predicted_opponent.x - ball.global_position.x
	) * attack_sign
	var minimum_forward: float = maxf(
		one_vs_one_space_play_minimum_progress,
		defender_forward_distance
		+ one_vs_one_space_play_minimum_bypass
	)

	var forward_samples: Array[float] = [
		maxf(minimum_forward, 560.0),
		maxf(minimum_forward + 180.0, 760.0),
		maxf(minimum_forward + 390.0, 980.0),
		maxf(minimum_forward + 650.0, 1240.0),
		maxf(minimum_forward + 920.0, 1510.0)
	]
	var lateral_reach: float = minf(
		maxf(520.0, one_vs_one_bypass_lateral_distance * 1.45),
		(maximum_field_y - minimum_field_y) * 0.34
	)
	var lateral_samples: Array[float] = [
		-lateral_reach,
		-lateral_reach * 0.72,
		-lateral_reach * 0.42,
		-lateral_reach * 0.18,
		0.0,
		lateral_reach * 0.18,
		lateral_reach * 0.42,
		lateral_reach * 0.72,
		lateral_reach
	]

	var best_plan: Dictionary = {}
	var best_score: float = -INF
	for forward_distance in forward_samples:
		for lateral_distance in lateral_samples:
			var raw_target: Vector2 = (
				ball.global_position
				+ forward * forward_distance
				+ lateral * lateral_distance
			)
			var target: Vector2 = _clamp_to_field(raw_target)
			var clamp_distance: float = raw_target.distance_to(
				target
			)
			if clamp_distance > 260.0:
				continue
			var progress: float = (
				target.x - ball.global_position.x
			) * attack_sign
			if progress < one_vs_one_space_play_minimum_progress:
				continue
			var bypass_margin: float = (
				target.x - predicted_opponent.x
			) * attack_sign
			if (
				bypass_margin
				< one_vs_one_space_play_minimum_bypass
			):
				continue

			var direct_plan: Dictionary = (
				_score_one_vs_one_space_route(
					opponent_goal,
					opponent,
					predicted_opponent,
					target,
					{},
					false,
					lateral_distance,
					clamp_distance
				)
			)
			if (
				not direct_plan.is_empty()
				and float(
					direct_plan.get("score", -INF)
				) > best_score
			):
				best_score = float(
					direct_plan.get("score", -INF)
				)
				best_plan = direct_plan

			var wall_route: Dictionary = _get_best_wall_route(
				target
			)
			if wall_route.is_empty():
				continue
			var wall_plan: Dictionary = (
				_score_one_vs_one_space_route(
					opponent_goal,
					opponent,
					predicted_opponent,
					target,
					wall_route,
					true,
					lateral_distance,
					clamp_distance
				)
			)
			if (
				not wall_plan.is_empty()
				and float(
					wall_plan.get("score", -INF)
				) > best_score
			):
				best_score = float(
					wall_plan.get("score", -INF)
				)
				best_plan = wall_plan
	return best_plan


func _score_one_vs_one_space_route(
	opponent_goal: FootballGoal,
	opponent: FootballPlayer,
	predicted_opponent: Vector2,
	destination: Vector2,
	wall_route: Dictionary,
	uses_wall: bool,
	lateral_distance: float,
	clamp_distance: float
) -> Dictionary:
	var route_distance: float = (
		float(wall_route.get("distance", 0.0))
		if uses_wall
		else ball.global_position.distance_to(destination)
	)
	if route_distance <= 1.0:
		return {}

	var launch_target: Vector2 = destination
	if uses_wall:
		launch_target = wall_route.get(
			"bounce",
			destination
		) as Vector2
	var route_clearance: float = (
		float(wall_route.get("clearance", -INF))
		if uses_wall
		else _minimum_segment_clearance(
			ball.global_position,
			destination
		)
	)
	if (
		route_clearance
		< one_vs_one_space_play_minimum_route_clearance
	):
		return {}

	var attack_sign: float = _get_attack_sign()
	var bypass_margin: float = (
		destination.x - predicted_opponent.x
	) * attack_sign
	if (
		bypass_margin
		< one_vs_one_space_play_minimum_bypass
	):
		return {}

	var own_arrival: float = _estimate_duel_player_arrival_seconds(
		controlled_player,
		destination
	)
	var opponent_arrival: float = (
		_estimate_duel_player_arrival_seconds(
			opponent,
			destination
		)
	)
	var desired_ball_time: float = clampf(
		own_arrival
		- maxf(0.0, one_vs_one_space_play_lead_seconds),
		0.24,
		1.55
	)
	var required_force: float = (
		_get_one_vs_one_self_pass_force(
			route_distance,
			desired_ball_time,
			uses_wall
		)
	)
	var ball_arrival: float = (
		_estimate_one_vs_one_self_pass_time(
			route_distance,
			required_force,
			uses_wall
		)
	)
	if not is_finite(ball_arrival):
		return {}

	var control_time: float = maxf(
		own_arrival,
		ball_arrival
	)
	var recovery_margin: float = (
		opponent_arrival - control_time
	)
	var control_gap: float = own_arrival - ball_arrival
	if (
		recovery_margin
		< one_vs_one_space_play_minimum_recovery_margin
		or control_gap
		> one_vs_one_space_play_maximum_control_gap
	):
		return {}

	var goal_center: Vector2 = _get_goal_center(
		opponent_goal
	)
	var shooting_lane: float = _minimum_segment_clearance(
		destination,
		goal_center
	)
	var destination_space: float = minf(
		_nearest_opponent_distance(destination),
		1450.0
	)
	var goal_distance: float = destination.distance_to(
		goal_center
	)
	var goal_progress: float = (
		destination.x - ball.global_position.x
	) * attack_sign
	var direct_route_clearance: float = (
		_minimum_segment_clearance(
			ball.global_position,
			destination
		)
	)
	var defender_launch_clearance: float = _distance_to_segment(
		predicted_opponent,
		ball.global_position,
		launch_target
	)
	var shooting_area_quality: float = clampf(
		shooting_lane
		/ maxf(
			1.0,
			one_vs_one_space_play_shooting_lane_target
		),
		0.0,
		1.6
	) + clampf(
		1.0 - goal_distance / 4300.0,
		0.0,
		1.0
	) * 0.7

	var score: float = (
		goal_progress * 0.38
		+ maxf(0.0, bypass_margin) * 0.95
		+ route_clearance * 0.72
		+ destination_space * 0.24
		+ shooting_lane * 0.72
		+ recovery_margin * 1450.0
		+ shooting_area_quality * 390.0
		- route_distance * 0.075
		- clamp_distance * 1.15
		- absf(control_gap - 0.08) * 460.0
	)
	if absf(lateral_distance) < 135.0:
		score -= (
			one_vs_one_space_play_straight_line_penalty
			* clampf(
				1.0
				- defender_launch_clearance / 520.0,
				0.0,
				1.0
			)
		)
	if uses_wall:
		score += one_vs_one_space_play_wall_bonus
		score += maxf(
			0.0,
			route_clearance - direct_route_clearance
		) * 0.82
		if direct_route_clearance < 260.0:
			score += 260.0
		var bounce: Vector2 = wall_route.get(
			"bounce",
			destination
		)
		var bounce_side: float = signf(
			bounce.y
			- (minimum_field_y + maximum_field_y) * 0.5
		)
		if (
			not is_zero_approx(bounce_side)
			and bounce_side
			!= _one_vs_one_space_play_last_side
		):
			score += 95.0
	else:
		if defender_launch_clearance < 190.0:
			score -= 340.0

	return {
		"destination": destination,
		"launch_target": launch_target,
		"uses_wall": uses_wall,
		"bounce": wall_route.get(
			"bounce",
			destination
		),
		"route_distance": route_distance,
		"route_clearance": route_clearance,
		"direct_route_clearance": direct_route_clearance,
		"force": required_force,
		"force_ratio": inverse_lerp(
			one_vs_one_space_play_minimum_force,
			one_vs_one_space_play_maximum_force,
			required_force
		),
		"ball_arrival": ball_arrival,
		"own_arrival": own_arrival,
		"opponent_arrival": opponent_arrival,
		"recovery_margin": recovery_margin,
		"control_gap": control_gap,
		"shooting_lane": shooting_lane,
		"shooting_area_quality": shooting_area_quality,
		"bypass_margin": bypass_margin,
		"score": score
	}


func _get_one_vs_one_self_pass_force(
	route_distance: float,
	desired_seconds: float,
	uses_wall: bool
) -> float:
	var safe_seconds: float = maxf(0.12, desired_seconds)
	var damping: float = maxf(0.0, ball.linear_damp)
	var required_speed: float = (
		route_distance / safe_seconds
	)
	if damping > 0.001:
		required_speed = (
			route_distance
			* damping
			/ maxf(
				0.04,
				1.0 - exp(-damping * safe_seconds)
			)
		)
	if uses_wall:
		var restitution: float = maxf(
			0.25,
			_get_double_bank_wall_restitution()
		)
		required_speed /= sqrt(restitution)
		required_speed *= 1.035
	return clampf(
		required_speed,
		maxf(
			controlled_player.minimum_shot_force,
			one_vs_one_space_play_minimum_force
		),
		minf(
			controlled_player.maximum_shot_force * 0.86,
			one_vs_one_space_play_maximum_force
		)
	)


func _estimate_one_vs_one_self_pass_time(
	route_distance: float,
	launch_force: float,
	uses_wall: bool
) -> float:
	var effective_speed: float = maxf(1.0, launch_force)
	if uses_wall:
		effective_speed *= sqrt(
			maxf(
				0.25,
				_get_double_bank_wall_restitution()
			)
		)
	var damping: float = maxf(0.0, ball.linear_damp)
	if damping <= 0.001:
		return route_distance / effective_speed
	var maximum_distance: float = effective_speed / damping
	if route_distance >= maximum_distance * 0.985:
		return INF
	return -log(
		maxf(
			0.0001,
			1.0 - route_distance * damping / effective_speed
		)
	) / damping


func _try_begin_one_vs_one_space_play(
	opponent_goal: FootballGoal,
	force_attempt: bool = false
) -> bool:
	var now: float = _server_time_seconds()
	if (
		not one_vs_one_space_play_enabled
		or not _is_true_one_vs_one()
		or opponent_goal == null
		or _ball_is_in_own_goal_danger()
		or controlled_player.server_is_charging
	):
		return false
	if (
		not _one_vs_one_space_play_plan.is_empty()
		and now < _one_vs_one_space_play_until
	):
		return true
	if (
		now < _one_vs_one_space_play_next_allowed_at
		or not controlled_player.cpu_has_kickable_ball()
		or ball.linear_velocity.length() > 760.0
	):
		return false

	var opponent: FootballPlayer = _get_one_vs_one_opponent()
	if opponent == null:
		return false
	var plan: Dictionary = _scan_one_vs_one_space_play(
		opponent_goal,
		opponent
	)
	if plan.is_empty():
		return false
	var plan_score: float = float(
		plan.get("score", -INF)
	)
	var required_plan_score: float = (
		one_vs_one_space_play_minimum_score * 0.72
		if force_attempt
		else one_vs_one_space_play_minimum_score
	)
	if plan_score < required_plan_score:
		return false

	var direct_goal_clearance: float = (
		_minimum_segment_clearance(
			ball.global_position,
			_get_goal_center(opponent_goal)
		)
	)
	var defender_blocks_forward: bool = (
		_distance_to_segment(
			opponent.global_position,
			ball.global_position,
			_get_goal_center(opponent_goal)
		) < 440.0
	)
	var creates_shooting_area: bool = (
		float(
			plan.get(
				"shooting_area_quality",
				0.0
			)
		) >= 0.82
	)
	if (
		not force_attempt
		and not bool(plan.get("uses_wall", false))
		and not defender_blocks_forward
		and direct_goal_clearance >= 520.0
		and not creates_shooting_area
	):
		return false

	_one_vs_one_space_play_plan = plan.duplicate(true)
	_one_vs_one_space_play_until = (
		now
		+ maxf(
			0.7,
			one_vs_one_space_play_commit_seconds
		)
	)
	_one_vs_one_space_play_next_allowed_at = (
		now
		+ maxf(
			0.1,
			one_vs_one_space_play_cooldown_seconds
		)
	)
	_one_vs_one_space_play_kicked = false
	_dribble_until = maxf(
		_dribble_until,
		_one_vs_one_space_play_until
	)
	_contest_yield_until = 0.0
	return true


func _update_one_vs_one_space_play() -> void:
	if _one_vs_one_space_play_plan.is_empty():
		return

	var destination: Vector2 = (
		_one_vs_one_space_play_plan.get(
			"destination",
			ball.global_position
		) as Vector2
	)
	var launch_target: Vector2 = (
		_one_vs_one_space_play_plan.get(
			"launch_target",
			destination
		) as Vector2
	)
	_planned_destination = destination
	_shot_target = (
		destination
		if _one_vs_one_space_play_kicked
		else launch_target
	)
	_plan_is_pass = false
	_planned_receiver = null

	if not _one_vs_one_space_play_kicked:
		_movement_target = _get_strike_position(
			launch_target
		)
		var launch_direction: Vector2 = (
			ball.global_position.direction_to(
				launch_target
			)
		)
		var contact_direction: Vector2 = (
			controlled_player.global_position.direction_to(
				ball.global_position
			)
		)
		if (
			not launch_direction.is_zero_approx()
			and contact_direction.dot(
				launch_direction
			) >= 0.60
			and controlled_player.cpu_dribble_touch(
				launch_direction,
				float(
					_one_vs_one_space_play_plan.get(
						"force",
						one_vs_one_space_play_minimum_force
					)
				)
			)
		):
			_one_vs_one_space_play_kicked = true
			var bounce: Vector2 = (
				_one_vs_one_space_play_plan.get(
					"bounce",
					destination
				) as Vector2
			)
			var side: float = signf(
				bounce.y
				- (
					minimum_field_y
					+ maximum_field_y
				) * 0.5
			)
			if not is_zero_approx(side):
				_one_vs_one_space_play_last_side = side
			_movement_target = destination
		return

	var opponent: FootballPlayer = _get_one_vs_one_opponent()
	if controlled_player.cpu_has_kickable_ball():
		_clear_one_vs_one_space_play_state()
		if opponent != null:
			var opponent_goal: FootballGoal = _get_opponent_goal()
			if opponent_goal != null:
				_begin_solo_attack(
					opponent_goal,
					opponent,
					_server_time_seconds(),
					maxf(
						0.35,
						local_duel_commit_seconds * 0.65
					)
				)
		return

	if opponent != null:
		var interception: Dictionary = (
			_get_duel_interception_data(opponent)
		)
		var intercept_position: Vector2 = (
			interception.get(
				"position",
				destination
			) as Vector2
		)
		var own_arrival: float = float(
			interception.get("own_arrival", INF)
		)
		var opponent_arrival: float = float(
			interception.get(
				"opponent_arrival",
				INF
			)
		)
		if (
			ball.last_touch_peer_id
			== opponent.owner_peer_id
			and opponent_arrival + 0.08
			< own_arrival
		):
			_clear_one_vs_one_space_play_state()
			_try_begin_duel_resolution(
				opponent.owner_peer_id,
				_server_time_seconds()
			)
			return
		_movement_target = intercept_position
	else:
		_movement_target = destination


func _update_active_one_vs_one_space_play() -> bool:
	if _one_vs_one_space_play_plan.is_empty():
		return false
	var now: float = _server_time_seconds()
	if (
		elite_finish_interrupt_space_play
		and controlled_player.cpu_has_kickable_ball()
	):
		var finish_goal: FootballGoal = _get_opponent_goal()
		if (
			finish_goal != null
			and _try_execute_elite_finish_scan(
				finish_goal,
				true
			)
		):
			_clear_one_vs_one_space_play_state()
			return true
	if (
		now >= _one_vs_one_space_play_until
		or _ball_is_in_own_goal_danger()
	):
		_clear_one_vs_one_space_play_state()
		return false
	_update_one_vs_one_space_play()
	_set_tactical_intent(
		INTENT_RECEIVE
		if _one_vs_one_space_play_kicked
		else INTENT_DRIBBLE,
		_movement_target
	)
	return true


func _clear_one_vs_one_space_play_state() -> void:
	_one_vs_one_space_play_plan.clear()
	_one_vs_one_space_play_until = 0.0
	_one_vs_one_space_play_kicked = false


func _try_begin_wall_dribble(force_attempt: bool = false) -> bool:
	if (
		_ball_is_in_own_goal_danger()
		or controlled_player.global_position.distance_to(ball.global_position)
		> controlled_player.kick_feedback_detection_distance
		or _nearest_opponent_distance(ball.global_position) > 720.0
	):
		return false
	var destination = _clamp_to_field(
		ball.global_position
		+ Vector2(
			_get_attack_sign() * wall_dribble_forward_distance,
			0.0
		)
	)
	var direct_clearance = _minimum_segment_clearance(
		ball.global_position,
		destination
	)
	var wall_route = _get_best_wall_route(destination)
	if wall_route.is_empty():
		return false
	if force_attempt:
		var opponent = _get_nearest_opponent_to(ball.global_position)
		if opponent == null:
			return false
		var progress_beyond_opponent = (
			destination.x - opponent.global_position.x
		) * _get_attack_sign()
		var own_arrival = _estimate_duel_player_arrival_seconds(
			controlled_player,
			destination
		)
		var opponent_arrival = _estimate_duel_player_arrival_seconds(
			opponent,
			destination
		)
		if (
			progress_beyond_opponent < 260.0
			or opponent_arrival + 0.24 < own_arrival
		):
			return false
	else:
		if (
			direct_clearance > 430.0
			or float(wall_route.get("clearance", 0.0))
			< maxf(wall_route_minimum_clearance, direct_clearance + 120.0)
		):
			return false
		if (
			not _has_active_meta_vision()
			and _rng.randf() > wall_dribble_choice_chance
		):
			return false
	_wall_dribble_destination = destination
	_wall_dribble_bounce = wall_route.get("bounce", destination)
	_wall_dribble_kicked = false
	_wall_dribble_start_position = ball.global_position
	_wall_dribble_training_outcome_recorded = false
	_wall_dribble_until = (
		_server_time_seconds() + maxf(0.4, wall_dribble_commit_seconds)
	)
	_dribble_until = maxf(_dribble_until, _wall_dribble_until)
	_contest_yield_until = 0.0
	_record_wall_self_pass_training_attempt()
	return true


func _update_wall_dribble() -> void:
	_movement_target = _wall_dribble_destination
	_shot_target = (
		_wall_dribble_destination
		if _wall_dribble_kicked
		else _wall_dribble_bounce
	)
	_planned_destination = _wall_dribble_destination
	if _wall_dribble_kicked:
		return
	var direction = ball.global_position.direction_to(_wall_dribble_bounce)
	var contact_direction = controlled_player.global_position.direction_to(
		ball.global_position
	)
	if (
		not direction.is_zero_approx()
		and contact_direction.dot(direction) >= 0.62
		and controlled_player.cpu_dribble_touch(
			direction,
			wall_dribble_touch_force
		)
	):
		_wall_dribble_kicked = true
		_shot_target = _wall_dribble_destination


func _update_active_wall_dribble_break() -> bool:
	var now = _server_time_seconds()
	if _wall_dribble_until <= now:
		if _wall_dribble_until > 0.0:
			if _wall_dribble_kicked:
				_record_wall_self_pass_training_outcome(false)
			_clear_wall_dribble_state()
		return false
	if _ball_is_in_own_goal_danger():
		if _wall_dribble_kicked:
			_record_wall_self_pass_training_outcome(false)
		_clear_wall_dribble_state()
		return false
	var opponent = _get_nearest_opponent_to(ball.global_position)
	if not _wall_dribble_kicked:
		_update_wall_dribble()
		_set_tactical_intent(INTENT_DRIBBLE, _shot_target)
		return true
	if controlled_player.cpu_has_kickable_ball():
		_record_wall_self_pass_training_outcome(true)
		_clear_wall_dribble_state()
		var opponent_goal = _get_opponent_goal()
		if opponent_goal != null and opponent != null:
			_begin_solo_attack(
				opponent_goal,
				opponent,
				now,
				maxf(0.45, local_duel_commit_seconds * 0.7)
			)
		return false
	if opponent != null:
		var interception = _get_duel_interception_data(opponent)
		var intercept_position: Vector2 = interception.get(
			"position",
			_wall_dribble_destination
		)
		var own_arrival = float(interception.get("own_arrival", INF))
		var opponent_arrival = float(
			interception.get("opponent_arrival", INF)
		)
		if (
			ball.last_touch_peer_id == opponent.owner_peer_id
			and opponent_arrival + maxf(0.08, duel_clear_loss_margin_seconds)
			< own_arrival
		):
			_record_wall_self_pass_training_outcome(false)
			_clear_wall_dribble_state()
			_try_begin_duel_resolution(opponent.owner_peer_id, now)
			return _update_duel_resolution_decision()
		_movement_target = intercept_position
		if (
			controlled_player.global_position.distance_to(_movement_target)
			<= 24.0
			and controlled_player.global_position.distance_to(ball.global_position)
			> controlled_player.kick_feedback_detection_distance * 0.85
		):
			_movement_target = ball.global_position
	else:
		_movement_target = _wall_dribble_destination
	_set_tactical_intent(INTENT_RECEIVE, _movement_target)
	return true


func _record_wall_self_pass_training_attempt() -> void:
	if (
		match_manager == null
		or controlled_player == null
		or not match_manager.has_method("record_cpu_defense_event")
	):
		return
	match_manager.record_cpu_defense_event(
		controlled_player.team,
		&"wall_self_pass_attempts"
	)


func _record_wall_self_pass_training_outcome(success: bool) -> void:
	if _wall_dribble_training_outcome_recorded:
		return
	_wall_dribble_training_outcome_recorded = true
	if (
		match_manager == null
		or controlled_player == null
		or ball == null
		or not match_manager.has_method("record_cpu_defense_event")
	):
		return
	if not success:
		match_manager.record_cpu_defense_event(
			controlled_player.team,
			&"wall_self_pass_failures"
		)
		return
	# Do not count the frame immediately after the kick as a "recovery". The ball
	# must actually have travelled far enough for this to represent a wall play.
	var travel_pixels: float = ball.global_position.distance_to(
		_wall_dribble_start_position
	)
	if travel_pixels < 260.0:
		return
	match_manager.record_cpu_defense_event(
		controlled_player.team,
		&"wall_self_pass_recoveries"
	)
	# Reward only actual forward progress. A pointless bank that comes straight
	# back to the carrier is measurable, but receives no creative-progress credit.
	var progress_pixels: float = (
		(ball.global_position.x - _wall_dribble_start_position.x)
		* _get_attack_sign()
	)
	if progress_pixels > 90.0:
		match_manager.record_cpu_defense_event(
			controlled_player.team,
			&"wall_self_pass_progress",
			clampf(progress_pixels / 900.0, 0.0, 1.5)
		)


func _clear_wall_dribble_state() -> void:
	_wall_dribble_until = 0.0
	_wall_dribble_destination = Vector2.ZERO
	_wall_dribble_bounce = Vector2.ZERO
	_wall_dribble_kicked = false
	_wall_dribble_start_position = Vector2.ZERO
	_wall_dribble_training_outcome_recorded = false


func _try_setup_mirage_step() -> bool:
	if _ball_is_in_own_goal_danger():
		_mirage_setup_target = null
		_mirage_activate_after = 0.0
		return false
	if (
		is_instance_valid(_mirage_setup_target)
		and _mirage_activate_after > 0.0
	):
		if _server_time_seconds() > _mirage_activate_after + 0.8:
			_mirage_setup_target = null
			_mirage_activate_after = 0.0
			return false
		_movement_target = _mirage_setup_target.global_position + Vector2(
			_get_attack_sign() * 320.0,
			0.0
		)
		return true
	if (
		controlled_player.selected_ability
		!= FootballPlayer.ABILITY_BLIND_SPOT
		or not _cpu_ability_is_ready()
		or ball.linear_velocity.length() > 1250.0
		or controlled_player.global_position.distance_to(
			ball.global_position
		) > controlled_player.kick_feedback_detection_distance
	):
		return false
	var opponent = _get_nearest_opponent_to(ball.global_position)
	if opponent == null:
		return false
	var distance = ball.global_position.distance_to(opponent.global_position)
	var forward_progress = (
		opponent.global_position.x - ball.global_position.x
	) * _get_attack_sign()
	if (
		distance > mirage_setup_enemy_distance
		or forward_progress < 80.0
	):
		return false

	var through_direction = controlled_player.global_position.direction_to(
		opponent.global_position
	)
	if through_direction.is_zero_approx():
		through_direction = Vector2(_get_attack_sign(), 0.0)
	var behind_target = (
		opponent.global_position
		+ through_direction
		* controlled_player.blind_spot_distance_behind_target
	)
	_mirage_setup_target = opponent
	_mirage_activate_after = (
		_server_time_seconds() + maxf(0.01, mirage_setup_delay * 0.35)
	)
	_shot_target = behind_target
	_planned_destination = behind_target
	_movement_target = behind_target
	return true


func _should_yield_contested_ball() -> bool:
	# This function compares opponents, not teammates. An opponent must never be
	# granted a free touch by deliberately stopping during a live 50/50.
	_contest_yield_until = 0.0
	return false


func _try_break_contested_ball_brawl(
	opponent_goal: FootballGoal
) -> bool:
	var now = _server_time_seconds()
	if (
		now < _next_contest_escape_at
		or controlled_player.server_is_charging
		or _ball_is_in_own_goal_danger()
		or ball.linear_velocity.length() > contested_ball_maximum_speed * 0.9
		or controlled_player.global_position.distance_to(ball.global_position)
		> controlled_player.kick_feedback_detection_distance
	):
		return false
	var opponent = _get_nearest_opponent_to(ball.global_position)
	if (
		opponent == null
		or opponent.global_position.distance_to(ball.global_position)
		> minf(contested_ball_radius, 520.0)
	):
		return false

	if _try_begin_wall_dribble(true):
		_update_wall_dribble()
		_set_tactical_intent(INTENT_DRIBBLE, _shot_target)
		return true

	var local_duel = _get_relevant_duel_opponent() != null
	var escape_chance = clampf(contest_escape_choice_chance, 0.0, 1.0)
	if not local_duel:
		if match_manager != null and match_manager.cpu_training_mode:
			escape_chance = maxf(escape_chance, 0.62)
		else:
			escape_chance = lerpf(
			escape_chance * 0.55,
			escape_chance,
			_get_ai_skill()
		)
		if _rng.randf() > escape_chance:
			_next_contest_escape_at = now + 0.2
			return false

	var goal_center = _get_goal_center(opponent_goal)
	var forward = ball.global_position.direction_to(goal_center)
	if forward.is_zero_approx():
		forward = Vector2(_get_attack_sign(), 0.0)
	var lateral = Vector2(-forward.y, forward.x)
	var predicted_opponent = (
		opponent.global_position + opponent.linear_velocity * 0.2
	)
	var best_target = ball.global_position + forward * 1150.0
	var best_direction = forward
	var best_score = -INF
	var escape_sides: Array[float] = [-1.0, 1.0]
	for side: float in escape_sides:
		var candidate_direction: Vector2 = (
			forward * 0.72 + lateral * side * 0.78
		).normalized()
		var candidate_target: Vector2 = _clamp_to_field(
			ball.global_position + candidate_direction * 1250.0
		)
		candidate_direction = ball.global_position.direction_to(candidate_target)
		if candidate_direction.is_zero_approx():
			continue
		var lane_clearance = _distance_to_segment(
			predicted_opponent,
			ball.global_position + candidate_direction * 180.0,
			candidate_target
		)
		var progress = (
			candidate_target.x - ball.global_position.x
		) * _get_attack_sign()
		var progress_beyond_opponent = (
			candidate_target.x - predicted_opponent.x
		) * _get_attack_sign()
		var own_arrival = _estimate_duel_player_arrival_seconds(
			controlled_player,
			candidate_target
		)
		var opponent_arrival = _estimate_duel_player_arrival_seconds(
			opponent,
			candidate_target
		)
		var retention_margin = opponent_arrival - own_arrival
		var candidate_score = (
			lane_clearance * 1.2
			+ progress * 0.5
			+ progress_beyond_opponent * 0.72
			+ retention_margin * 1050.0
		)
		if progress_beyond_opponent < 220.0:
			candidate_score -= 900.0
		if opponent_arrival + 0.12 < own_arrival:
			candidate_score -= 720.0
		if candidate_score > best_score:
			best_score = candidate_score
			best_target = candidate_target
			best_direction = candidate_direction

	if best_direction.is_zero_approx():
		return false
	var escape_force = contest_escape_touch_force
	if local_duel:
		escape_force = maxf(escape_force, wall_dribble_touch_force * 0.72)
	if not controlled_player.cpu_dribble_touch(
		best_direction,
		escape_force
	):
		return false
	_next_contest_escape_at = now + maxf(0.2, contest_escape_touch_interval)
	_next_contest_yield_allowed_at = _next_contest_escape_at
	_shot_target = best_target
	_planned_destination = best_target
	_movement_target = best_target
	if local_duel:
		_solo_attack_until = now + maxf(0.65, local_duel_commit_seconds)
		_solo_attack_defender_peer_id = opponent.owner_peer_id
		_solo_attack_direction = best_direction
		_solo_attack_direction_lock_until = _solo_attack_until
		_dribble_until = maxf(_dribble_until, _solo_attack_until)
	_set_tactical_intent(INTENT_DRIBBLE, _movement_target)
	return true


func _get_contest_angle_position() -> Vector2:
	var attack_direction = Vector2(_get_attack_sign(), 0.0)
	var side = (
		-1.0
		if controlled_player.owner_peer_id % 4 < 2
		else 1.0
	)
	return (
		ball.global_position
		- attack_direction * 180.0
		+ Vector2(0.0, side * contest_angle_distance)
	)


func _get_strike_position(goal_target: Vector2) -> Vector2:
	var predicted_ball = _get_predicted_ball_position()
	return _get_strike_position_for_ball(goal_target, predicted_ball, false)


func _get_committed_strike_position(goal_target: Vector2) -> Vector2:
	# Once a kick is committed, do not park on the outer edge of KickArea. The
	# ball can still be carrying dribble/rebound velocity while the shot charges;
	# sitting near the overlap boundary created the visible chase -> stop -> lose
	# contact -> retry loop. Track a slightly shorter, live contact point instead.
	var follow_seconds = clampf(
		committed_ball_follow_prediction_seconds,
		0.0,
		0.18
	)
	var tracked_ball = _predict_ball_position_for_execution_seconds(follow_seconds)
	return _get_strike_position_for_ball(goal_target, tracked_ball, true)


func _get_strike_position_for_ball(
	goal_target: Vector2,
	tracked_ball: Vector2,
	committed: bool
) -> Vector2:
	var shot_direction = tracked_ball.direction_to(goal_target)
	if shot_direction.is_zero_approx():
		shot_direction = Vector2(_get_attack_sign(), 0.0)
	var contact_radius = _get_cpu_kick_contact_radius()
	var contact_margin = (
		maxf(kick_distance_margin, committed_kick_contact_margin)
		if committed
		else maxf(8.0, kick_distance_margin)
	)
	var strike_distance = minf(
		maxf(80.0, strike_position_distance),
		maxf(80.0, contact_radius - contact_margin)
	)
	return tracked_ball - shot_direction * strike_distance


func _get_cpu_kick_contact_radius() -> float:
	if controlled_player == null or not is_instance_valid(controlled_player):
		return 190.0
	var fallback = maxf(80.0, controlled_player.kick_feedback_detection_distance * 0.70)
	var kick_area = controlled_player.kick_area
	if kick_area == null or not is_instance_valid(kick_area):
		return fallback
	var collision_shape = kick_area.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision_shape == null or not collision_shape.shape is CircleShape2D:
		return fallback
	var circle = collision_shape.shape as CircleShape2D
	var shape_scale = collision_shape.global_scale
	var radius_scale = minf(absf(shape_scale.x), absf(shape_scale.y))
	return maxf(80.0, circle.radius * maxf(0.01, radius_scale))


func _get_best_team_pass_plan(
	opponent_goal: FootballGoal,
	force_refresh: bool = false
) -> Dictionary:
	var ranked = _get_ranked_team_pass_plans(
		opponent_goal,
		1,
		force_refresh
	)
	return ranked[0].duplicate(true) if not ranked.is_empty() else {}


func _get_ranked_team_pass_plans(
	opponent_goal: FootballGoal,
	maximum_plans: int = 6,
	force_refresh: bool = false
) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if (
		not advanced_team_play_enabled
		or _team_play_planner == null
		or opponent_goal == null
		or controlled_player == null
		or ball == null
		or _is_true_one_vs_one()
		or maximum_plans <= 0
	):
		return result
	for plan in _team_play_planner.get_ranked_pass_plans(
		opponent_goal,
		maximum_plans * 2,
		force_refresh
	):
		if not _team_pass_plan_is_acceptable(plan):
			continue
		result.append(plan.duplicate(true))
		if result.size() >= maximum_plans:
			break
	return result


func _required_direct_shot_lane(goal_distance: float) -> float:
	var distance_ratio = clampf(
		inverse_lerp(850.0, 5000.0, goal_distance),
		0.0,
		1.0
	)
	var required = lerpf(
		110.0,
		maxf(360.0, elite_open_long_shot_lane * 0.78),
		distance_ratio
	)
	if (
		controlled_player != null
		and controlled_player.selected_ability
		== FootballPlayer.ABILITY_POWER_STRIKE
		and (
			_cpu_ability_is_ready()
			or _has_active_ability(FootballPlayer.ABILITY_POWER_STRIKE)
		)
	):
		required *= 0.78
	return maxf(80.0, required)


func _get_best_live_direct_shot_target(
	opponent_goal: FootballGoal
) -> Vector2:
	if opponent_goal == null or ball == null:
		return Vector2.ZERO
	var mouth_range = opponent_goal.get_mouth_y_range()
	var margin = clampf(
		shot_integrity_goal_margin,
		45.0,
		maxf(46.0, (mouth_range.y - mouth_range.x) * 0.34)
	)
	var minimum_y = mouth_range.x + margin
	var maximum_y = mouth_range.y - margin
	if maximum_y <= minimum_y:
		return _get_goal_center(opponent_goal)
	var current_target = _shot_target
	var opponent_keeper = match_manager.get_designated_cpu_goalkeeper(
		TEAM_RED
		if controlled_player.team == TEAM_BLUE
		else TEAM_BLUE
	)
	var best_target = Vector2(
		opponent_goal.get_goal_plane_x(),
		(minimum_y + maximum_y) * 0.5
	)
	var best_score = -INF
	var live_goal_samples: int = _get_dynamic_goal_sample_count(11)
	for sample_index in range(live_goal_samples):
		var ratio = float(sample_index) / float(live_goal_samples - 1)
		var candidate = Vector2(
			opponent_goal.get_goal_plane_x(),
			lerpf(minimum_y, maximum_y, ratio)
		)
		var clearance = _minimum_segment_clearance(
			ball.global_position,
			candidate
		)
		var target_space = _nearest_opponent_distance(candidate)
		var keeper_separation = 0.0
		if is_instance_valid(opponent_keeper):
			var predicted_keeper = (
				opponent_keeper.global_position
				+ opponent_keeper.linear_velocity * 0.18
			)
			keeper_separation = absf(candidate.y - predicted_keeper.y)
		var retarget_penalty = 0.0
		if not current_target.is_zero_approx():
			retarget_penalty = absf(candidate.y - current_target.y) * 0.035
		var score = (
			clearance * 1.55
			+ target_space * 0.22
			+ keeper_separation * 0.46
			- retarget_penalty
		)
		if score > best_score:
			best_score = score
			best_target = candidate
	return best_target


func _shot_target_is_viable(target: Vector2) -> bool:
	if target.is_zero_approx() or ball == null:
		return false
	var goal_distance = ball.global_position.distance_to(target)
	var lane = _minimum_segment_clearance(
		ball.global_position,
		target
	)
	var required_lane = _required_direct_shot_lane(goal_distance)
	if goal_distance <= 900.0:
		required_lane = maxf(105.0, required_lane * 0.72)
	if lane < required_lane:
		return false
	# Geometric clearance alone still allowed shots directly into a defender who
	# could step into the route before the ball arrived. Check the time race at
	# several points along the lane as the final release gate.
	var interception_margin = _direct_shot_interception_margin(target)
	var required_margin = (
		-0.03
		if goal_distance <= 850.0
		else maxf(-0.02, possession_action_shot_intercept_margin)
	)
	return interception_margin >= required_margin


func _get_obvious_open_pass_plan(
	opponent_goal: FootballGoal
) -> Dictionary:
	if (
		not obvious_pass_override_enabled
		or opponent_goal == null
		or ball == null
		or controlled_player == null
		or not controlled_player.cpu_has_kickable_ball()
		or _get_active_team_player_count() < 2
		or _ball_is_in_own_goal_danger()
	):
		return {}
	var goal_center = _get_goal_center(opponent_goal)
	var best_shot_target = _get_best_live_direct_shot_target(
		opponent_goal
	)
	if best_shot_target.is_zero_approx():
		best_shot_target = goal_center
	var goal_distance = ball.global_position.distance_to(
		best_shot_target
	)
	if goal_distance <= 950.0:
		return {}
	var best_shot_lane = _minimum_segment_clearance(
		ball.global_position,
		best_shot_target
	)
	var shot_blocked = best_shot_lane < maxf(
		obvious_pass_blocked_shot_lane,
		_required_direct_shot_lane(goal_distance) * 0.88
	)
	var carrier_pressure = _nearest_opponent_distance(
		ball.global_position
	)
	var ranked_plans = _get_ranked_team_pass_plans(
		opponent_goal,
		_get_dynamic_pass_search_count(8),
		true
	)
	var best_plan: Dictionary = {}
	var best_score = -INF
	for plan_variant in ranked_plans:
		if not plan_variant is Dictionary:
			continue
		var plan = plan_variant as Dictionary
		var receiver = _get_teammate_by_peer_id(
			int(plan.get("receiver_peer_id", 0))
		)
		if receiver == null or receiver == controlled_player:
			continue
		var pass_kind = StringName(plan.get("kind", &"lead"))
		if (
			pass_kind == &"recycle"
			and carrier_pressure > pass_pressure_radius
		):
			continue
		var quality = float(plan.get("quality", 0.0))
		var route_clearance = float(
			plan.get("route_clearance", 0.0)
		)
		var interception_margin = float(
			plan.get("interception_margin", -2.0)
		)
		var receiver_margin = float(
			plan.get("receiver_margin", -2.0)
		)
		var openness = float(plan.get("openness", 0.0))
		var forward_progress = float(
			plan.get("forward_progress", 0.0)
		)
		var goal_gain = float(plan.get("goal_gain", 0.0))
		var destination: Vector2 = plan.get(
			"destination",
			receiver.global_position
		)
		if destination.is_zero_approx():
			continue
		if (
			quality < obvious_pass_minimum_quality
			or route_clearance
			< maxf(
				obvious_pass_minimum_route_clearance,
				pass_lane_clearance * 0.70
			)
			or interception_margin
			< obvious_pass_minimum_interception_margin
			or receiver_margin < -0.08
			or openness < obvious_pass_minimum_receiver_space
		):
			continue
		var receiver_goal_lane = _minimum_segment_clearance(
			destination,
			goal_center
		)
		var pass_requested = (
			receiver.server_pass_request_ends_at
			> _server_time_seconds()
		)
		var receiver_is_human = not receiver.cpu_controlled
		var receiver_advantage = (
			goal_gain >= 100.0
			or forward_progress >= 300.0
			or receiver_goal_lane >= best_shot_lane + 90.0
		)
		if shot_blocked:
			if (
				not receiver_advantage
				and not pass_requested
				and not (
					receiver_is_human
					and openness
					>= obvious_pass_minimum_receiver_space * 1.25
				)
			):
				continue
		elif (
			not pass_requested
			and not (
				receiver_is_human
				and quality >= 0.74
				and goal_gain >= 240.0
				and receiver_goal_lane >= best_shot_lane + 120.0
			)
		):
			continue
		var score = (
			quality * 920.0
			+ route_clearance * 0.34
			+ openness * 0.32
			+ interception_margin * 430.0
			+ receiver_margin * 230.0
			+ maxf(0.0, goal_gain) * 0.20
			+ maxf(0.0, receiver_goal_lane - best_shot_lane) * 0.38
			+ (obvious_pass_human_bonus if receiver_is_human else 0.0)
			+ (requested_pass_score_bonus if pass_requested else 0.0)
		)
		if score > best_score:
			best_score = score
			best_plan = plan.duplicate(true)
			best_plan["obvious_pass_reason"] = (
				"blocked_shot_open_receiver"
				if shot_blocked
				else "human_final_pass_advantage"
			)
			best_plan["blocked_shot_lane"] = best_shot_lane
	if not best_plan.is_empty():
		return best_plan
	if not shot_blocked:
		return {}
	# Safe fallback for the exact 2v2 situation where the advanced planner has
	# no named combination but a clearly open teammate is available diagonally.
	for teammate in _get_teammates():
		if (
			not is_instance_valid(teammate)
			or teammate == controlled_player
			or not teammate.controls_enabled
			or _is_designated_goalkeeper(teammate)
		):
			continue
		var target = _get_lead_pass_target(teammate)
		var distance = ball.global_position.distance_to(target)
		var clearance = _minimum_segment_clearance(
			ball.global_position,
			target
		)
		var openness = _nearest_opponent_distance(target)
		var progress = (
			target.x - ball.global_position.x
		) * _get_attack_sign()
		if (
			distance < minimum_pass_distance * 0.72
			or distance > maximum_pass_distance
			or clearance
			< maxf(
				obvious_pass_minimum_route_clearance,
				pass_lane_clearance * 0.76
			)
			or openness < obvious_pass_minimum_receiver_space
			or progress < -120.0
		):
			continue
		return {
			"available": true,
			"quality": 0.68,
			"kind": &"lead",
			"receiver_peer_id": teammate.owner_peer_id,
			"destination": target,
			"route_target": target,
			"route_distance": distance,
			"route_clearance": clearance,
			"direct_clearance": clearance,
			"interception_margin": 0.10,
			"receiver_margin": 0.08,
			"openness": openness,
			"forward_progress": progress,
			"goal_gain": (
				ball.global_position.distance_to(goal_center)
				- target.distance_to(goal_center)
			),
			"chain_value": 0.0,
			"counter_risk": 0.30,
			"defensive_error_value": 180.0,
			"uses_wall": false,
			"reason": "obvious_open_teammate",
			"obvious_pass_reason": "blocked_shot_open_teammate"
		}
	return {}


func _try_execute_decisive_possession_action(
	opponent_goal: FootballGoal
) -> bool:
	if (
		not possession_action_arbiter_enabled
		or opponent_goal == null
		or controlled_player == null
		or ball == null
		or not controlled_player.cpu_has_kickable_ball()
		or controlled_player.server_is_charging
		or _get_active_team_player_count() <= 1
		or _ball_is_in_own_goal_danger()
	):
		return false
	var now = _server_time_seconds()
	if (
		now < _possession_action_lock_until
		and _possession_action_lock == INTENT_DRIBBLE
		and _get_checkpoint_team_player_count() < 3
	):
		_update_dribble(opponent_goal)
		_set_tactical_intent(INTENT_DRIBBLE, _shot_target)
		return true

	var shot_candidate = _build_decisive_shot_candidate(opponent_goal)
	var pass_candidate = _build_decisive_pass_candidate(
		opponent_goal,
		shot_candidate
	)
	var dribble_candidate = _build_decisive_dribble_candidate(
		opponent_goal
	)
	var candidates: Array[Dictionary] = []
	if not shot_candidate.is_empty():
		candidates.append(shot_candidate)
	if not pass_candidate.is_empty():
		candidates.append(pass_candidate)
	if not dribble_candidate.is_empty():
		candidates.append(dribble_candidate)
	if candidates.is_empty():
		return false
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("score", -INF)) > float(b.get("score", -INF))
	)
	var best = candidates[0]
	var best_score = float(best.get("score", -INF))
	var second_score = (
		float(candidates[1].get("score", -INF))
		if candidates.size() > 1
		else -INF
	)
	var forced = bool(best.get("forced", false))
	# INT 20 is the full champion, so let the existing possession arbiter act on
	# smaller but still meaningful tactical edges instead of falling through to
	# a second planner whenever the top two choices are merely close. Lower
	# intelligence levels keep the exact old thresholds.
	var champion_thresholds: Vector2 = _get_possession_arbiter_thresholds()
	var minimum_score: float = champion_thresholds.x
	var minimum_advantage: float = champion_thresholds.y
	if best_score < minimum_score:
		return false
	if (
		not forced
		and not is_inf(second_score)
		and best_score - second_score
		< maxf(0.0, minimum_advantage)
	):
		# Worker 2 remains in control when two actions are genuinely close. The
		# arbiter only corrects obvious football mistakes and high-value plays.
		return false
	var action = StringName(best.get("action", &""))
	var executed = false
	match action:
		INTENT_PASS:
			executed = _execute_decisive_pass(
				best.get("plan", {}) as Dictionary,
				opponent_goal
			)
		INTENT_SHOOT:
			executed = _execute_decisive_shot(
				best.get("target", Vector2.ZERO) as Vector2
			)
		INTENT_DRIBBLE:
			executed = _execute_decisive_dribble(opponent_goal)
	if executed:
		_possession_action_lock = action
		_possession_action_lock_until = (
			now + _get_high_tempo_plan_duration(
				possession_action_commit_seconds,
				high_tempo_possession_commit_seconds
			)
		)
	return executed


func _is_full_champion_intelligence() -> bool:
	return get_effective_skill_level() >= MAX_INTELLIGENCE


func _get_elite_tactical_upgrade_strength() -> float:
	# Champions League (INT 17-19) should use the same upgraded tactical tools
	# as Theodore League, just with a slightly softer edge. Keep INT 20 as the
	# full ceiling while making 17/18/19 progressively close to it.
	var level: int = get_effective_skill_level()
	if level < 17:
		return 0.0
	return clampf(0.70 + float(level - 17) * 0.10, 0.0, 1.0)


func _get_possession_arbiter_thresholds() -> Vector2:
	var minimum_score: float = possession_action_minimum_score
	var minimum_advantage: float = possession_action_minimum_advantage
	var elite_strength: float = _get_elite_tactical_upgrade_strength()
	if elite_strength > 0.0:
		minimum_score *= lerpf(1.0, 0.88, elite_strength)
		minimum_advantage *= lerpf(1.0, 0.55, elite_strength)
	return Vector2(minimum_score, minimum_advantage)


func _get_champion_pass_tactical_bonus(
	plan: Dictionary,
	team_size: int
) -> float:
	# Elite CPUs share the same deterministic look-ahead. Champions League uses
	# most of the bonus, while Theodore League still receives the full value.
	var elite_strength: float = _get_elite_tactical_upgrade_strength()
	if elite_strength <= 0.0 or plan.is_empty():
		return 0.0
	var chain_value: float = maxf(
		0.0,
		float(plan.get("chain_value", 0.0))
	)
	var defensive_error_value: float = maxf(
		0.0,
		float(plan.get("defensive_error_value", 0.0))
	)
	var counter_risk: float = clampf(
		float(plan.get("counter_risk", 1.0)),
		0.0,
		1.0
	)
	var interception_margin: float = float(
		plan.get("interception_margin", -2.0)
	)
	var receiver_margin: float = float(
		plan.get("receiver_margin", -2.0)
	)
	var bonus: float = (
		minf(chain_value, 1100.0) * 0.30
		+ minf(defensive_error_value, 760.0) * 0.34
		- counter_risk * 285.0
	)
	if interception_margin >= 0.16 and receiver_margin >= 0.10:
		bonus += 90.0
	if team_size >= 3:
		match StringName(plan.get("kind", &"lead")):
			&"third_man":
				bonus += 190.0
			&"one_two":
				bonus += 160.0
			&"through", &"blindside", &"cutback":
				bonus += 120.0
			&"diagonal_split", &"overlap", &"underlap":
				bonus += 95.0
	return bonus * elite_strength


func _get_shared_team_sequence_required_confidence(team_size: int) -> float:
	var required_confidence: float = shared_team_sequence_force_confidence
	# INT 17-19 can also trust strong 3v3+ sequences earlier, but Theodore
	# League keeps the most aggressive trigger. Route and arrival safety gates
	# remain unchanged for every level.
	var elite_strength: float = _get_elite_tactical_upgrade_strength()
	if elite_strength > 0.0 and team_size >= 3:
		var elite_floor: float = maxf(
			shared_team_sequence_advisory_confidence + 0.12,
			shared_team_sequence_force_confidence - 0.08
		)
		required_confidence = lerpf(
			shared_team_sequence_force_confidence,
			elite_floor,
			elite_strength
		)
	return required_confidence


func _build_decisive_shot_candidate(
	opponent_goal: FootballGoal
) -> Dictionary:
	var target = _get_best_live_direct_shot_target(opponent_goal)
	if target.is_zero_approx():
		return {}
	var distance = ball.global_position.distance_to(target)
	var lane = _minimum_segment_clearance(ball.global_position, target)
	var required_lane = _required_direct_shot_lane(distance)
	var interception_margin = _direct_shot_interception_margin(target)
	var power_strike_available: bool = (
		controlled_player.selected_ability == FootballPlayer.ABILITY_POWER_STRIKE
		and (
			_cpu_ability_is_ready()
			or _has_active_ability(FootballPlayer.ABILITY_POWER_STRIKE)
		)
		and distance <= power_strike_activation_goal_distance
		and distance >= 700.0
	)
	if power_strike_available:
		# The whole point of Power Strike is that a merely playable lane can be
		# worth testing. Keep a real safety floor, but stop requiring the same
		# clean lane as an ordinary shot. This creates occasional high-value/lucky
		# attempts without allowing shots straight through a defender.
		required_lane = maxf(
			maxf(105.0, power_strike_minimum_safe_lane * 0.72),
			required_lane * 0.68
		)
	var minimum_interception_margin: float = maxf(
		-0.04,
		possession_action_shot_intercept_margin
	)
	if power_strike_available:
		minimum_interception_margin = minf(
			minimum_interception_margin,
			-0.08
		)
	var viable = (
		lane >= required_lane
		and interception_margin >= minimum_interception_margin
	)
	if not viable:
		return {
			"action": INTENT_SHOOT,
			"target": target,
			"score": -INF,
			"blocked": true,
			"lane": lane,
			"required_lane": required_lane,
			"interception_margin": interception_margin
		}
	var pressure = _nearest_opponent_distance(ball.global_position)
	var score = (
		minf(lane, 1400.0) * 0.92
		+ maxf(0.0, 4200.0 - distance) * 0.20
		+ clampf(interception_margin, -0.2, 0.8) * 520.0
		+ minf(pressure, 900.0) * 0.10
	)
	var opponent_ability_threat = _get_opponent_ability_threat_state()
	var defensive_stop_threat = float(
		opponent_ability_threat.get("defensive_stop_threat", 0.0)
	)
	if defensive_stop_threat > 0.0:
		# Reflex Block, Iron Anchor and Goalkeeper Reach make weak central shots
		# much worse. Force the attack to move the defense or find a cleaner angle.
		score -= defensive_stop_threat * (
			480.0
			+ maxf(0.0, required_lane * 1.35 - lane) * 1.8
		)
	if power_strike_available:
		score += 520.0
		if controlled_player.is_haaland_boss():
			score += 220.0

	# The existing Shoot -> Pass acceleration is one of Theodore Ball's strongest
	# high-skill shot mechanics. It was mechanically available, but the tactical
	# arbiter valued the first kick exactly like an ordinary shot, so elite CPUs
	# often chose a safe pass/dribble before the combo ever had a chance to run.
	# Give a *viable* combo lane extra tactical value without bypassing the normal
	# shot-safety checks above. This makes INT 13+ consider the technique more
	# often, with the preference scaling up toward INT 20.
	var follow_up_skill: int = get_effective_skill_level()
	var follow_up_min_distance: float = fast_follow_up_finish_minimum_distance
	var follow_up_max_distance: float = fast_follow_up_finish_maximum_distance
	if follow_up_skill >= fast_follow_up_finish_minimum_level:
		follow_up_min_distance *= 0.62
		follow_up_max_distance = maxf(follow_up_max_distance, 5600.0)
	var follow_up_lane_floor: float = maxf(
		70.0,
		fast_follow_up_finish_minimum_lane_clearance * 0.60
	)
	var follow_up_tactically_viable: bool = (
		fast_follow_up_finish_enabled
		and follow_up_skill >= fast_follow_up_finish_minimum_level
		and distance >= maxf(0.0, follow_up_min_distance)
		and distance <= maxf(follow_up_min_distance, follow_up_max_distance)
		and lane >= follow_up_lane_floor
	)
	if follow_up_tactically_viable:
		var elite_progress: float = clampf(
			float(follow_up_skill - fast_follow_up_finish_minimum_level)
			/ maxf(1.0, float(20 - fast_follow_up_finish_minimum_level)),
			0.0,
			1.0
		)
		score += fast_follow_up_finish_tactical_score_bonus * lerpf(
			0.65,
			1.0,
			elite_progress
		)
		if power_strike_available:
			score += fast_follow_up_finish_power_strike_score_bonus
	if distance <= maxf(900.0, possession_action_close_shot_distance):
		score += possession_action_open_shot_bonus
	if distance > 4300.0:
		score -= (
			(distance - 4300.0)
			* (0.08 if power_strike_available else 0.24)
		)
	# The value planner already understands personality. Keep the lower-level
	# possession arbiter consistent too, otherwise a boss can fall through to a
	# generic dribble decision immediately after its preferred shooting plan.
	score += _get_personality_action_bias(&"direct_shot")
	return {
		"action": INTENT_SHOOT,
		"target": target,
		"score": score,
		"blocked": false,
		"lane": lane,
		"required_lane": required_lane,
		"interception_margin": interception_margin,
		"forced": (
			distance <= 1500.0
			and lane >= required_lane * 1.22
			and interception_margin >= 0.10
		)
	}


func _get_large_team_pass_tactical_bonus(
	plan: Dictionary,
	receiver: FootballPlayer
) -> float:
	if not is_large_team_football_shape_active() or not is_instance_valid(receiver):
		return 0.0
	var quality := float(plan.get("quality", 0.0))
	var clearance := float(plan.get("route_clearance", 0.0))
	var openness := float(plan.get("openness", 0.0))
	var interception_margin := float(plan.get("interception_margin", -1.0))
	var receiver_margin := float(plan.get("receiver_margin", -1.0))
	var progress := float(plan.get("forward_progress", 0.0))
	var kind := StringName(plan.get("kind", &"lead"))
	var safe_route := (
		quality >= 0.48
		and clearance >= 120.0
		and openness >= 220.0
		and interception_margin >= -0.03
		and receiver_margin >= -0.08
	)
	if not safe_route:
		return 0.0

	# In 4v4+ reward moving the defense before rewarding another solo carry.
	# The bonus is deliberately conditional on an actually safe route so this
	# cannot turn into blind passing just because more teammates exist.
	var bonus := large_team_pass_preference_bonus * clampf(quality, 0.48, 0.96)
	bonus += minf(clearance, 1000.0) * 0.07
	bonus += minf(openness, 1200.0) * 0.055
	bonus += maxf(0.0, progress) * 0.07
	match kind:
		&"through", &"diagonal_split", &"wide_switch":
			bonus += 155.0
		&"one_two", &"third_man", &"overlap", &"underlap":
			bonus += 135.0
		&"square", &"cutback", &"layoff":
			bonus += 85.0
		&"recycle":
			# Recycle is football when pressure forces it, not an excuse to pass
			# backwards forever in open space.
			if _nearest_opponent_distance(ball.global_position) <= pass_pressure_radius:
				bonus += 95.0
			else:
				bonus -= 135.0

	var receiver_role := get_large_team_football_role(receiver)
	if receiver_role in [LARGE_TEAM_ROLE_WINGER, LARGE_TEAM_ROLE_STRIKER] and progress > 220.0:
		bonus += 70.0
	elif receiver_role == LARGE_TEAM_ROLE_MIDFIELDER and kind in [&"square", &"layoff", &"third_man"]:
		bonus += 55.0
	return bonus


func _build_decisive_pass_candidate(
	opponent_goal: FootballGoal,
	shot_candidate: Dictionary
) -> Dictionary:
	var plans = _get_ranked_team_pass_plans(
		opponent_goal,
		_get_dynamic_pass_search_count(8),
		true
	)
	var direct_fallback = _build_best_direct_pass_fallback(opponent_goal)
	if not direct_fallback.is_empty():
		plans.append(direct_fallback)
	var sequence_pass_plan = _get_shared_team_sequence_pass_plan()
	if not sequence_pass_plan.is_empty():
		plans.append(sequence_pass_plan)
	var requested_receiver = _get_active_pass_request_receiver()
	var recent_recovery = (
		_server_time_seconds() - _last_secure_recovery_at
		<= maxf(0.1, possession_action_recovery_window_seconds)
	)
	var shot_blocked = (
		shot_candidate.is_empty()
		or bool(shot_candidate.get("blocked", true))
		or float(shot_candidate.get("score", -INF)) == -INF
	)
	var best: Dictionary = {}
	var best_score = -INF
	for plan_variant in plans:
		if not plan_variant is Dictionary:
			continue
		var plan = plan_variant as Dictionary
		if not _team_pass_plan_is_acceptable(plan):
			continue
		var receiver = _get_teammate_by_peer_id(
			int(plan.get("receiver_peer_id", 0))
		)
		if receiver == null or receiver == controlled_player:
			continue
		var quality = float(plan.get("quality", 0.0))
		var route_clearance = float(plan.get("route_clearance", 0.0))
		var openness = float(plan.get("openness", 0.0))
		var interception_margin = float(
			plan.get("interception_margin", -2.0)
		)
		var receiver_margin = float(plan.get("receiver_margin", -2.0))
		var forward_progress = float(plan.get("forward_progress", 0.0))
		var goal_gain = float(plan.get("goal_gain", 0.0))
		var pass_requested = (
			requested_receiver != null
			and receiver == requested_receiver
		)
		var score = (
			quality * 1080.0
			+ minf(route_clearance, 1300.0) * 0.36
			+ minf(openness, 1500.0) * 0.30
			+ clampf(interception_margin, -0.3, 1.0) * 440.0
			+ clampf(receiver_margin, -0.3, 1.0) * 260.0
			+ forward_progress * 0.25
			+ maxf(0.0, goal_gain) * 0.18
		)
		if pass_requested:
			score += possession_action_requested_pass_bonus
		if recent_recovery:
			score += possession_action_recovery_pass_bonus
		if shot_blocked:
			score += possession_action_blocked_shot_pass_bonus
		if not receiver.cpu_controlled:
			score += 165.0
		if bool(plan.get("sequence_plan", false)):
			score += (
				float(plan.get("sequence_confidence", 0.0)) * 430.0
				+ float(plan.get("continuation_value", 0.0)) * 310.0
			)

		# The advanced pass planner already calculates second-action value, how
		# much the pass distorts the defense, and counterattack exposure. Feed those
		# existing values into the full champion's arbiter instead of throwing that
		# information away before the final decision.
		score += _get_champion_pass_tactical_bonus(
			plan,
			_get_checkpoint_team_player_count()
		)
		score += _get_ability_aware_receiver_pass_bonus(
			receiver,
			plan,
			shot_blocked
		)
		score += _get_large_team_pass_tactical_bonus(plan, receiver)
		var pass_kind = StringName(plan.get("kind", &"lead"))
		if (
			pass_kind == &"recycle"
			and not recent_recovery
			and _nearest_opponent_distance(ball.global_position)
			> pass_pressure_radius
		):
			score -= 360.0
		if forward_progress < -350.0 and not recent_recovery:
			score -= absf(forward_progress) * 0.34
		if score > best_score:
			best_score = score
			best = {
				"action": INTENT_PASS,
				"plan": plan.duplicate(true),
				"score": score,
				"forced": pass_requested or recent_recovery and shot_blocked
			}
	return best


func _build_best_direct_pass_fallback(
	opponent_goal: FootballGoal
) -> Dictionary:
	var best: Dictionary = {}
	var best_score = -INF
	var goal_center = _get_goal_center(opponent_goal)
	var under_pressure = (
		_nearest_opponent_distance(ball.global_position)
		<= pass_pressure_radius
	)
	for teammate in _get_teammates():
		if (
			not is_instance_valid(teammate)
			or teammate == controlled_player
			or not teammate.controls_enabled
		):
			continue
		var target = _get_lead_pass_target(teammate)
		var distance = ball.global_position.distance_to(target)
		if (
			distance < minimum_pass_distance * 0.65
			or distance > maximum_pass_distance
		):
			continue
		var clearance = _minimum_segment_clearance(
			ball.global_position,
			target
		)
		var openness = _nearest_opponent_distance(target)
		if clearance < 95.0 or openness < 220.0:
			continue
		var launch_speed = lerpf(
			controlled_player.minimum_shot_force,
			controlled_player.maximum_shot_force,
			0.68
		)
		var ball_time = _estimate_elite_ball_travel_time(
			distance,
			launch_speed,
			false
		)
		if not is_finite(ball_time):
			continue
		var receiver_arrival = _estimate_duel_player_arrival_seconds(
			teammate,
			target
		)
		var opponent_arrival = INF
		for opponent in _get_opponents():
			if not is_instance_valid(opponent) or not opponent.controls_enabled:
				continue
			opponent_arrival = minf(
				opponent_arrival,
				_estimate_duel_player_arrival_seconds(opponent, target)
			)
		var interception_margin = opponent_arrival - ball_time
		var receiver_margin = opponent_arrival - receiver_arrival
		if interception_margin < -0.04 or receiver_margin < -0.12:
			continue
		var forward_progress = (
			target.x - ball.global_position.x
		) * _get_attack_sign()
		var goal_gain = (
			ball.global_position.distance_to(goal_center)
			- target.distance_to(goal_center)
		)
		var quality = clampf(
			0.42
			+ clearance / 1900.0
			+ openness / 3200.0
			+ clampf(interception_margin, -0.1, 0.7) * 0.28
			+ clampf(receiver_margin, -0.1, 0.7) * 0.18
			+ maxf(0.0, forward_progress) / 6200.0,
			0.0,
			0.96
		)
		var counter_risk = clampf(
			0.22
			+ maxf(0.0, -forward_progress) / 2200.0
			+ maxf(0.0, 340.0 - openness) / 700.0,
			0.0,
			0.92
		)
		var score = (
			quality * 950.0
			+ clearance * 0.34
			+ openness * 0.27
			+ forward_progress * 0.22
			+ goal_gain * 0.12
		)
		if teammate.server_pass_request_ends_at > _server_time_seconds():
			score += possession_action_requested_pass_bonus
		if score <= best_score:
			continue
		best_score = score
		best = {
			"available": true,
			"quality": quality,
			"kind": &"pressure_escape" if under_pressure else &"lead",
			"receiver_peer_id": teammate.owner_peer_id,
			"destination": target,
			"route_target": target,
			"route_distance": distance,
			"route_clearance": clearance,
			"direct_clearance": clearance,
			"interception_margin": interception_margin,
			"receiver_margin": receiver_margin,
			"openness": openness,
			"forward_progress": forward_progress,
			"goal_gain": goal_gain,
			"chain_value": maxf(0.0, openness - 260.0) * 0.32,
			"counter_risk": counter_risk,
			"defensive_error_value": (
				180.0 if forward_progress > 280.0 else 90.0
			),
			"uses_wall": false,
			"under_pressure": under_pressure,
			"reason": "direct_arrival_safe_pass"
		}
	return best


func _build_decisive_dribble_candidate(
	opponent_goal: FootballGoal
) -> Dictionary:
	var direction = _get_deadlock_escape_direction()
	if direction.is_zero_approx():
		return {}
	var target = _clamp_to_field(
		ball.global_position
		+ direction * maxf(420.0, possession_action_dribble_probe_distance)
	)
	var clearance = _minimum_segment_clearance(
		ball.global_position,
		target
	)
	var openness = _nearest_opponent_distance(target)
	var progress = (
		target.x - ball.global_position.x
	) * _get_attack_sign()
	var goal_gain = (
		ball.global_position.distance_to(_get_goal_center(opponent_goal))
		- target.distance_to(_get_goal_center(opponent_goal))
	)
	var score = (
		minf(clearance, 1300.0) * 0.43
		+ minf(openness, 1500.0) * 0.34
		+ progress * 0.30
		+ goal_gain * 0.12
	)
	var team_size: int = _get_checkpoint_team_player_count()
	if team_size >= 3 and _has_other_active_teammate():
		# Larger teams should circulate the ball through their shape instead of
		# turning every possession into another individual carry. 1v1-3v3 keep
		# their old balance; only 4v4+ gets the stronger team-play bias.
		score *= 0.68 if team_size == 3 else 0.42
		if (
			controlled_player.selected_ability in [
				FootballPlayer.ABILITY_POWER_STRIKE,
				FootballPlayer.ABILITY_QUICK_TRIGGER
			]
			and _cpu_ability_is_ready()
		):
			score *= 0.55
	if progress < 40.0:
		score -= (40.0 - progress) * 0.70
	if _nearest_opponent_distance(ball.global_position) < 280.0:
		score -= 180.0
	score += _get_personality_action_bias(&"carry")
	return {
		"action": INTENT_DRIBBLE,
		"target": target,
		"score": score,
		"forced": false
	}


func _execute_decisive_pass(
	plan: Dictionary,
	opponent_goal: FootballGoal
) -> bool:
	if not _apply_team_pass_plan(
		plan,
		opponent_goal,
		_server_time_seconds()
	):
		return false
	if _hybrid_tactical_adapter != null:
		_hybrid_tactical_adapter.clear_active_decision()
	_movement_target = _get_strike_position(_shot_target)
	_set_tactical_intent(
		INTENT_PASS,
		_planned_destination,
		_planned_receiver.owner_peer_id
		if is_instance_valid(_planned_receiver)
		else 0
	)
	_try_begin_shot(false)
	if controlled_player.server_is_charging:
		_desired_charge_seconds = maxf(
			0.09,
			_desired_charge_seconds
			* clampf(obvious_pass_charge_multiplier, 0.3, 1.0)
		)
	return true


func _execute_decisive_shot(target: Vector2) -> bool:
	if target.is_zero_approx() or not _shot_target_is_viable(target):
		return false
	if _hybrid_tactical_adapter != null:
		_hybrid_tactical_adapter.clear_active_decision()
	_clear_attack_plan()
	_plan_is_pass = false
	_planned_receiver = null
	_plan_expires_at = _server_time_seconds() + 0.30
	_set_planned_route(target, false, true)
	_movement_target = _get_strike_position(_shot_target)
	_set_tactical_intent(INTENT_SHOOT, _shot_target)
	var instant_ability_used = _activate_planned_ball_ability()
	if not instant_ability_used:
		_try_begin_shot(false)
	if (
		controlled_player.server_is_charging
		and not _power_strike_requires_maximum_charge()
	):
		var distance_ratio = clampf(
			ball.global_position.distance_to(target)
			/ maxf(1.0, full_charge_goal_distance),
			0.24,
			0.74
		)
		_desired_charge_seconds = minf(
			_desired_charge_seconds,
			maxf(
				0.08,
				controlled_player.cpu_get_maximum_shot_charge_seconds()
				* distance_ratio
				* clampf(fast_finish_charge_multiplier, 0.3, 1.0)
			)
		)
	return true


func _execute_decisive_dribble(
	opponent_goal: FootballGoal
) -> bool:
	if _hybrid_tactical_adapter != null:
		_hybrid_tactical_adapter.clear_active_decision()
	_clear_attack_plan()
	_update_dribble(opponent_goal)
	_set_tactical_intent(INTENT_DRIBBLE, _shot_target)
	return true


func _direct_shot_interception_margin(target: Vector2) -> float:
	if target.is_zero_approx() or ball == null or controlled_player == null:
		return -INF
	var distance = ball.global_position.distance_to(target)
	var launch_speed = lerpf(
		controlled_player.minimum_shot_force,
		controlled_player.maximum_shot_force,
		0.82
	)
	if (
		controlled_player.selected_ability
		== FootballPlayer.ABILITY_POWER_STRIKE
		and (
			_cpu_ability_is_ready()
			or _has_active_ability(FootballPlayer.ABILITY_POWER_STRIKE)
		)
	):
		launch_speed *= maxf(
			1.0,
			controlled_player.power_strike_force_multiplier
		)
	var total_time = _estimate_elite_ball_travel_time(
		distance,
		launch_speed,
		false
	)
	if not is_finite(total_time):
		return -INF
	var minimum_margin = INF
	var sample_ratios: Array[float] = [0.22, 0.40, 0.58, 0.74, 0.88]
	var opponent_keeper = match_manager.get_designated_cpu_goalkeeper(
		TEAM_RED
		if controlled_player.team == TEAM_BLUE
		else TEAM_BLUE
	)
	for opponent in _get_opponents():
		if (
			not is_instance_valid(opponent)
			or not opponent.controls_enabled
			or opponent == opponent_keeper
		):
			continue
		for ratio in sample_ratios:
			var sample_position = ball.global_position.lerp(target, ratio)
			var ball_arrival = total_time * ratio
			var opponent_arrival = _estimate_duel_player_arrival_seconds(
				opponent,
				sample_position
			)
			minimum_margin = minf(
				minimum_margin,
				opponent_arrival - ball_arrival
			)
	return minimum_margin


func _try_execute_requested_pass_fast(
	receiver: FootballPlayer
) -> bool:
	if (
		not is_instance_valid(receiver)
		or receiver == controlled_player
		or not receiver.controls_enabled
	):
		return false
	_follow_pass_request(receiver)
	if (
		not _plan_is_pass
		or not is_instance_valid(_planned_receiver)
		or _planned_receiver != receiver
	):
		return false
	if _hybrid_tactical_adapter != null:
		_hybrid_tactical_adapter.clear_active_decision()
	_set_tactical_intent(
		INTENT_PASS,
		_shot_target,
		receiver.owner_peer_id
	)
	if controlled_player.server_is_charging:
		_desired_charge_seconds = maxf(
			0.10,
			_desired_charge_seconds * 0.68
		)
	return true


func _try_execute_obvious_team_pass(
	opponent_goal: FootballGoal
) -> bool:
	var plan = _get_obvious_open_pass_plan(opponent_goal)
	if plan.is_empty():
		return false
	var receiver = _get_teammate_by_peer_id(
		int(plan.get("receiver_peer_id", 0))
	)
	if receiver == null:
		return false
	if (
		_plan_is_pass
		and is_instance_valid(_planned_receiver)
		and _planned_receiver == receiver
		and controlled_player.server_is_charging
	):
		return true
	if controlled_player.server_is_charging:
		controlled_player.cpu_cancel_shot_charge()
		_reset_cpu_charge_tracking()
	_clear_attack_plan()
	if not _apply_team_pass_plan(
		plan,
		opponent_goal,
		_server_time_seconds()
	):
		return false
	if _hybrid_tactical_adapter != null:
		_hybrid_tactical_adapter.clear_active_decision()
	_movement_target = _get_strike_position(_shot_target)
	_set_tactical_intent(
		INTENT_PASS,
		_shot_target,
		receiver.owner_peer_id
	)
	_try_begin_shot(false)
	if controlled_player.server_is_charging:
		_desired_charge_seconds = maxf(
			0.12,
			_desired_charge_seconds
			* clampf(obvious_pass_charge_multiplier, 0.3, 1.0)
		)
	return true


func _try_execute_fast_finish(
	opponent_goal: FootballGoal
) -> bool:
	if (
		not fast_finish_enabled
		or opponent_goal == null
		or controlled_player == null
		or ball == null
		or _ball_is_in_own_goal_danger()
	):
		return false
	if controlled_player.server_is_charging:
		return not _plan_is_pass
	var target = _get_best_live_direct_shot_target(opponent_goal)
	if target.is_zero_approx():
		return false
	var distance = ball.global_position.distance_to(target)
	if distance > fast_finish_maximum_distance:
		return false
	var lane = _minimum_segment_clearance(
		ball.global_position,
		target
	)
	if lane < maxf(
		fast_finish_minimum_lane,
		_required_direct_shot_lane(distance) * 0.90
	):
		return false
	if _hybrid_tactical_adapter != null:
		_hybrid_tactical_adapter.clear_active_decision()
	_clear_attack_plan()
	_plan_is_pass = false
	_planned_receiver = null
	_plan_expires_at = _server_time_seconds() + 0.22
	_set_planned_route(target, false, true)
	_movement_target = _get_strike_position(_shot_target)
	_set_tactical_intent(INTENT_SHOOT, _shot_target)
	var instant_ability_used = _activate_planned_ball_ability()
	if not instant_ability_used:
		_try_begin_shot(false)
	return true


func _get_shared_team_sequence_plan() -> Dictionary:
	if (
		not shared_team_sequence_enabled
		or match_manager == null
		or controlled_player == null
		or not match_manager.has_method("get_cpu_team_sequence_plan")
	):
		return {}
	var plan_variant: Variant = match_manager.call(
		"get_cpu_team_sequence_plan",
		controlled_player.team
	)
	if not plan_variant is Dictionary:
		return {}
	var plan = plan_variant as Dictionary
	if (
		plan.is_empty()
		or float(plan.get("confidence", 0.0))
		< shared_team_sequence_advisory_confidence
	):
		return {}
	return plan


func _get_shared_team_sequence_assignment() -> Dictionary:
	if (
		not shared_team_sequence_enabled
		or match_manager == null
		or controlled_player == null
		or not match_manager.has_method("get_cpu_team_sequence_assignment")
	):
		return {}
	var assignment_variant: Variant = match_manager.call(
		"get_cpu_team_sequence_assignment",
		controlled_player.team,
		controlled_player.owner_peer_id
	)
	if not assignment_variant is Dictionary:
		return {}
	return assignment_variant as Dictionary


func _get_shared_team_sequence_pass_plan() -> Dictionary:
	var sequence = _get_shared_team_sequence_plan()
	if sequence.is_empty():
		return {}
	if (
		StringName(sequence.get("phase", &"")) != &"attack"
		or int(sequence.get("actor_peer_id", 0))
		!= controlled_player.owner_peer_id
	):
		return {}
	var action = StringName(sequence.get("action", &"none"))
	if action not in [&"pass", &"wall_pass", &"one_two", &"third_man"]:
		return {}
	var confidence = float(sequence.get("confidence", 0.0))
	var kind = StringName(sequence.get("kind", &"lead"))
	if action == &"one_two":
		kind = &"one_two"
	elif action == &"third_man":
		kind = &"third_man"
	elif action == &"wall_pass":
		kind = &"wall_bank"
	return {
		"available": true,
		"quality": clampf(0.50 + confidence * 0.46, 0.0, 0.98),
		"kind": kind,
		"receiver_peer_id": int(sequence.get("receiver_peer_id", 0)),
		"destination": sequence.get("destination", Vector2.ZERO),
		"route_target": sequence.get("route_target", Vector2.ZERO),
		"bounce": sequence.get("bounce", Vector2.ZERO),
		"uses_wall": bool(sequence.get("uses_wall", false)),
		"route_distance": float(sequence.get("route_distance", 0.0)),
		"route_clearance": float(sequence.get("route_clearance", 0.0)),
		"direct_clearance": float(sequence.get("direct_clearance", 0.0)),
		"interception_margin": float(sequence.get("arrival_margin", -1.0)),
		"receiver_margin": float(sequence.get("receiver_margin", -1.0)),
		"openness": float(sequence.get("openness", 0.0)),
		"forward_progress": float(sequence.get("forward_progress", 0.0)),
		"goal_gain": float(sequence.get("goal_gain", 0.0)),
		"chain_value": float(sequence.get("continuation_value", 0.0)) * 900.0,
		"continuation_value": float(sequence.get("continuation_value", 0.0)),
		"counter_risk": float(sequence.get("counter_risk", 1.0)),
		"defensive_error_value": float(
			sequence.get("defensive_error_value", 0.0)
		),
		"sequence_plan": true,
		"sequence_confidence": confidence,
		"sequence_plan_id": str(sequence.get("plan_id", "")),
		"next_peer_id": int(sequence.get("next_peer_id", 0)),
		"actor_run_target": sequence.get("actor_run_target", Vector2.ZERO),
		"next_run_target": sequence.get("next_run_target", Vector2.ZERO),
		"reason": str(sequence.get("reason", "shared_team_sequence"))
	}


func _try_execute_shared_team_sequence(
	opponent_goal: FootballGoal
) -> bool:
	if (
		not shared_team_sequence_enabled
		or opponent_goal == null
		or controlled_player == null
		or ball == null
		or controlled_player.server_is_charging
		or not controlled_player.cpu_has_kickable_ball()
		or _ball_is_in_own_goal_danger()
	):
		return false
	var sequence = _get_shared_team_sequence_plan()
	if sequence.is_empty():
		return false
	if (
		int(sequence.get("actor_peer_id", 0))
		!= controlled_player.owner_peer_id
		or not bool(sequence.get("force_execute", false))
	):
		return false
	var confidence = float(sequence.get("confidence", 0.0))
	var required_confidence: float = (
		_get_shared_team_sequence_required_confidence(
			_get_checkpoint_team_player_count()
		)
	)
	if confidence < required_confidence:
		return false
	var pass_plan = _get_shared_team_sequence_pass_plan()
	if pass_plan.is_empty():
		return false
	var destination = pass_plan.get("destination", Vector2.ZERO) as Vector2
	if destination.is_zero_approx():
		return false
	var live_clearance = _minimum_segment_clearance(
		ball.global_position,
		destination
	)
	if bool(pass_plan.get("uses_wall", false)):
		var bounce = pass_plan.get("bounce", Vector2.ZERO) as Vector2
		if bounce.is_zero_approx():
			return false
		live_clearance = minf(
			_minimum_segment_clearance(ball.global_position, bounce),
			_minimum_segment_clearance(bounce, destination)
		)
	if (
		live_clearance < shared_team_sequence_minimum_route_clearance
		or float(pass_plan.get("interception_margin", -1.0))
		< shared_team_sequence_minimum_arrival_margin
	):
		return false
	if not _execute_decisive_pass(pass_plan, opponent_goal):
		return false
	_last_team_sequence_plan_id = str(sequence.get("plan_id", ""))
	_last_team_sequence_action = StringName(sequence.get("action", &"pass"))
	_last_team_sequence_confidence = confidence
	_team_sequence_commit_until = (
		_server_time_seconds()
		+ _get_high_tempo_plan_duration(
			shared_team_sequence_commit_seconds,
			high_tempo_team_sequence_commit_seconds
		)
	)
	return true


func _team_pass_plan_is_acceptable(plan: Dictionary) -> bool:
	if plan.is_empty() or not bool(plan.get("available", false)):
		return false
	var quality = float(plan.get("quality", 0.0))
	var interception_margin = float(
		plan.get("interception_margin", -2.0)
	)
	var counter_risk = float(plan.get("counter_risk", 1.0))
	var pass_kind = StringName(plan.get("kind", &""))
	if pass_kind == &"recycle" and _ball_is_in_own_goal_danger():
		return false
	if bool(plan.get("sequence_plan", false)):
		return (
			float(plan.get("sequence_confidence", 0.0))
			>= shared_team_sequence_advisory_confidence
			and float(plan.get("route_clearance", 0.0))
			>= maxf(105.0, shared_team_sequence_minimum_route_clearance * 0.62)
			and interception_margin
			>= maxf(-0.04, shared_team_sequence_minimum_arrival_margin - 0.16)
			and counter_risk <= 0.72
		)
	if (
		quality < advanced_team_play_minimum_quality
		or interception_margin
		< advanced_team_play_minimum_interception_margin
		or counter_risk > advanced_team_play_maximum_counter_risk
	):
		return false
	if not advanced_team_play_preserve_worker_two:
		return true
	# Worker 2 remains the primary decision-maker. The planner only replaces a
	# generic pass when the route has a clear tactical purpose or unusually high
	# certainty; otherwise the existing learned/legacy choice remains untouched.
	var purposeful = (
		float(plan.get("chain_value", 0.0)) >= 280.0
		or float(plan.get("defensive_error_value", 0.0)) >= 150.0
		or pass_kind in [
			&"pressure_escape",
			&"cutback",
			&"wide_switch",
			&"third_man",
			&"one_two",
			&"wall_bank",
			&"blindside"
		]
		or (
			pass_kind == &"square"
			and (
				bool(plan.get("under_pressure", false))
				or float(plan.get("defensive_error_value", 0.0)) >= 170.0
			)
		)
		or (
			pass_kind == &"recycle"
			and (
				bool(plan.get("under_pressure", false))
				or quality >= 0.82
			)
		)
	)
	return purposeful or quality >= minf(
		0.92,
		advanced_team_play_minimum_quality + 0.10
	)


func _apply_team_pass_plan(
	plan: Dictionary,
	opponent_goal: FootballGoal,
	now: float
) -> bool:
	if not _team_pass_plan_is_acceptable(plan):
		return false
	var receiver = _get_teammate_by_peer_id(
		int(plan.get("receiver_peer_id", 0))
	)
	if receiver == null:
		return false
	var destination: Vector2 = plan.get(
		"destination",
		receiver.global_position
	)
	if destination.is_zero_approx():
		return false
	_clear_attack_plan()
	_active_team_pass_plan = plan.duplicate(true)
	_active_team_pass_plan_until = now + maxf(
		0.25,
		advanced_team_play_plan_lock_seconds
	)
	_planned_pass_kind = StringName(plan.get("kind", &"lead"))
	_plan_is_pass = true
	_planned_receiver = receiver
	_plan_expires_at = _active_team_pass_plan_until
	_planned_destination = _clamp_to_field(destination)
	_plan_uses_wall = bool(plan.get("uses_wall", false))
	_plan_uses_double_bank = false
	_double_bank_required_charge_seconds = 0.0
	_planned_route_distance = maxf(
		ball.global_position.distance_to(_planned_destination),
		float(plan.get("route_distance", 0.0))
	)
	if _plan_uses_wall:
		var bounce: Vector2 = plan.get("bounce", Vector2.ZERO)
		if bounce.is_zero_approx():
			_clear_active_team_pass_plan()
			return false
		_shot_target = bounce
	else:
		_shot_target = _planned_destination
	match_manager.set_cpu_pass_intention(
		controlled_player.owner_peer_id,
		receiver.owner_peer_id,
		_planned_destination,
		pass_intention_seconds
	)
	_register_elite_combination_play(
		receiver,
		_planned_destination,
		opponent_goal
	)
	return true


func _clear_active_team_pass_plan() -> void:
	_active_team_pass_plan.clear()
	_active_team_pass_plan_until = 0.0
	_planned_pass_kind = &""


func _get_active_team_pass_plan_for_receiver(
	receiver_peer_id: int
) -> Dictionary:
	if (
		receiver_peer_id <= 0
		or _active_team_pass_plan.is_empty()
		or _server_time_seconds() > _active_team_pass_plan_until
		or int(_active_team_pass_plan.get("receiver_peer_id", 0))
		!= receiver_peer_id
	):
		return {}
	return _active_team_pass_plan.duplicate(true)


func _get_team_play_support_assignment() -> Dictionary:
	if (
		not advanced_team_play_support_enabled
		or not explicit_off_ball_movement_enabled
		or _team_play_planner == null
		or _ball_is_in_own_goal_danger()
	):
		return {}
	var carrier = _get_likely_team_ball_carrier()
	if carrier == null or carrier == controlled_player:
		return {}
	var assignment: Dictionary = {}
	if (
		is_large_team_football_shape_active()
		and is_instance_valid(match_manager)
		and match_manager.has_method("get_large_team_support_assignment")
	):
		assignment = match_manager.get_large_team_support_assignment(
			controlled_player.team,
			controlled_player.owner_peer_id,
			carrier,
			_team_play_planner
		)
	else:
		assignment = _team_play_planner.get_support_assignment(carrier)
	if not assignment.is_empty():
		_last_off_ball_role = StringName(assignment.get("role", &""))
		_last_off_ball_reason = str(assignment.get("reason", ""))
		_last_off_ball_target = assignment.get(
			"position",
			Vector2.ZERO
		)
	return assignment


func get_team_play_debug_state() -> Dictionary:
	var support = _get_team_play_support_assignment()
	return {
		"enabled": advanced_team_play_enabled,
		"active_pass_kind": str(_planned_pass_kind),
		"active_pass_quality": float(
			_active_team_pass_plan.get("quality", 0.0)
		),
		"active_pass_reason": str(
			_active_team_pass_plan.get("reason", "")
		),
		"support_role": str(support.get("role", "")),
		"support_reason": str(support.get("reason", "")),
		"support_target": support.get("position", Vector2.ZERO),
		"transition_recovery_remaining": maxf(
			0.0,
			_off_ball_transition_recovery_until - _server_time_seconds()
		),
		"possession_arbiter_action": str(_possession_action_lock),
		"possession_arbiter_lock_remaining": maxf(
			0.0,
			_possession_action_lock_until - _server_time_seconds()
		),
		"ability_threat": str(
			_get_opponent_ability_threat_state().get(
				"primary_threat",
				&"none"
			)
		),
		"ability_threat_score": float(
			_get_opponent_ability_threat_state().get(
				"primary_score",
				0.0
			)
		),
		"ability_defense_role": str(_last_ability_defense_role),
		"team_sequence_action": str(_last_team_sequence_action),
		"team_sequence_confidence": _last_team_sequence_confidence,
		"team_sequence_plan_id": _last_team_sequence_plan_id,
		"team_sequence_role": str(
			_get_shared_team_sequence_assignment().get("role", &"")
		)
	}


func get_training_team_pass_plan() -> Dictionary:
	# Called synchronously by the self-play trainer from the ball kick signal.
	# Do not reject the plan only because its short decision lock expired while
	# the player was charging; the actual kick still belongs to this plan.
	if not _plan_is_pass or _active_team_pass_plan.is_empty():
		return {}
	return _active_team_pass_plan.duplicate(true)


func _get_attacking_support_position() -> Vector2:
	var sequence_assignment = _get_shared_team_sequence_assignment()
	if not sequence_assignment.is_empty():
		var sequence_target: Vector2 = sequence_assignment.get(
			"target_position",
			Vector2.ZERO
		)
		var sequence_role = StringName(
			sequence_assignment.get("role", &"")
		)
		if (
			not sequence_target.is_zero_approx()
			and sequence_role not in [&"actor", &"collector"]
		):
			var sequence_intent = StringName(
				sequence_assignment.get("intent", INTENT_WIDE_SUPPORT)
			)
			_set_tactical_intent(
				sequence_intent,
				sequence_target,
				int(sequence_assignment.get("target_peer_id", 0))
			)
			return _clamp_to_field(sequence_target)
	var shared_assignment = _get_shared_ability_team_assignment()
	if not shared_assignment.is_empty():
		var shared_target: Vector2 = shared_assignment.get(
			"target_position",
			Vector2.ZERO
		)
		if not shared_target.is_zero_approx():
			var shared_intent = StringName(
				shared_assignment.get("intent", INTENT_WIDE_SUPPORT)
			)
			_set_tactical_intent(
				shared_intent,
				shared_target,
				int(shared_assignment.get("carrier_peer_id", 0))
			)
			return _clamp_to_field(shared_target)
	var rotation_target = _get_two_vs_two_rotation_support_position(
		_get_likely_team_ball_carrier()
	)
	if not rotation_target.is_zero_approx():
		return rotation_target
	var ability_experiment_target = _get_coordinated_ability_run_position()
	if not ability_experiment_target.is_zero_approx():
		return ability_experiment_target
	var combination_target = _get_elite_combination_support_position()
	if not combination_target.is_zero_approx():
		return combination_target
	if (
		controlled_player.selected_ability
		== FootballPlayer.ABILITY_DIRECT_FINISH
		and (
			_cpu_ability_is_ready()
			or _has_active_ability(
				FootballPlayer.ABILITY_DIRECT_FINISH
			)
		)
	):
		return _get_direct_finish_support_position()
	var power_distribution_target = _get_power_distribution_support_position()
	if not power_distribution_target.is_zero_approx():
		return power_distribution_target
	var haaland_run_target = _get_haaland_predator_run_position()
	if not haaland_run_target.is_zero_approx():
		return haaland_run_target
	var team_assignment = _get_team_play_support_assignment()
	if not team_assignment.is_empty():
		var team_target: Vector2 = team_assignment.get(
			"position",
			Vector2.ZERO
		)
		if not team_target.is_zero_approx():
			var team_intent = StringName(
				team_assignment.get("intent", INTENT_WIDE_SUPPORT)
			)
			_set_tactical_intent(
				team_intent,
				team_target,
				_get_likely_team_ball_carrier().owner_peer_id
				if _get_likely_team_ball_carrier() != null
				else 0
			)
			return team_target
	var planned_support = _get_advance_play_support_position()
	if not planned_support.is_zero_approx():
		return planned_support
	return _get_dynamic_cover_position(ball.global_position)



func _get_haaland_predator_run_position() -> Vector2:
	# Haaland is an out-and-out number nine. Reuse the normal SUPPORT/FORWARD_RUN
	# executor, but give him a boss-specific target that attacks the space behind
	# the defense instead of drifting into generic support lanes. Explicit team
	# sequences and ability combinations are resolved before this helper.
	if (
		controlled_player == null
		or not controlled_player.is_haaland_boss()
		or _ball_is_in_own_goal_danger()
		or not _team_likely_has_possession()
		or _is_designated_goalkeeper(controlled_player)
	):
		return Vector2.ZERO
	var carrier = _get_likely_team_ball_carrier()
	if carrier == null or carrier == controlled_player:
		return Vector2.ZERO
	if (
		carrier.global_position.distance_to(ball.global_position)
		> carrier.kick_feedback_detection_distance + 360.0
	):
		return Vector2.ZERO
	var opponent_goal: FootballGoal = _get_opponent_goal()
	if opponent_goal == null:
		return Vector2.ZERO
	var attack_sign: float = _get_attack_sign()
	var goal_center: Vector2 = _get_goal_center(opponent_goal)
	var carrier_goal_distance: float = carrier.global_position.distance_to(goal_center)
	var depth_from_goal: float = clampf(
		carrier_goal_distance * 0.24,
		maxf(680.0, off_ball_goal_line_buffer),
		1380.0
	)
	var target_x: float = goal_center.x - attack_sign * depth_from_goal
	if carrier_goal_distance > 4200.0:
		target_x = carrier.global_position.x + attack_sign * clampf(
			carrier_goal_distance * 0.34,
			1250.0,
			2150.0
		)
	var forward_progress: float = (target_x - carrier.global_position.x) * attack_sign
	if forward_progress < 520.0:
		return Vector2.ZERO

	var mouth: Vector2 = opponent_goal.get_mouth_y_range()
	var mouth_center_y: float = (mouth.x + mouth.y) * 0.5
	var mouth_half: float = maxf(180.0, absf(mouth.y - mouth.x) * 0.5)
	var center_y: float = (minimum_field_y + maximum_field_y) * 0.5
	var carrier_side: float = signf(carrier.global_position.y - center_y)
	if is_zero_approx(carrier_side):
		carrier_side = 1.0 if controlled_player.global_position.y >= center_y else -1.0
	var candidate_ys: Array[float] = [
		mouth_center_y - carrier_side * mouth_half * 0.72,
		mouth_center_y,
		mouth_center_y + carrier_side * mouth_half * 0.54
	]
	var best_target := Vector2.ZERO
	var best_score: float = -INF
	for target_y: float in candidate_ys:
		var candidate := _clamp_to_field(Vector2(target_x, target_y))
		var route_clearance: float = _minimum_segment_clearance(
			carrier.global_position,
			candidate
		)
		var arrival_space: float = _nearest_opponent_distance(candidate)
		var goal_distance: float = candidate.distance_to(goal_center)
		var score: float = (
			minf(route_clearance, 1100.0) * 0.58
			+ minf(arrival_space, 1150.0) * 0.42
			- goal_distance * 0.06
		)
		if score > best_score:
			best_score = score
			best_target = candidate
	if best_target.is_zero_approx():
		return Vector2.ZERO
	var pass_lane: float = _minimum_segment_clearance(
		carrier.global_position,
		best_target
	)
	if (
		pass_lane >= maxf(145.0, pass_lane_clearance * 0.58)
		and best_target.distance_to(goal_center) <= 3150.0
	):
		controlled_player.cpu_request_pass()
	_set_tactical_intent(
		INTENT_FORWARD_RUN,
		best_target,
		carrier.owner_peer_id
	)
	return best_target

func _get_coordinated_ability_run_position() -> Vector2:
	if (
		controlled_player.selected_ability
		!= FootballPlayer.ABILITY_OVERDRIVE
		or not _player_ability_is_available(
			controlled_player,
			FootballPlayer.ABILITY_OVERDRIVE
		)
		or _ball_is_in_own_goal_danger()
	):
		_overdrive_through_run_until = 0.0
		_overdrive_through_run_target = Vector2.ZERO
		return Vector2.ZERO
	var now = _server_time_seconds()
	var carrier = _get_likely_team_ball_carrier()
	if carrier == null or carrier == controlled_player:
		return Vector2.ZERO
	var through_ball_plan = _get_overdrive_dead_zone_plan()
	if (
		not through_ball_plan.is_empty()
		and int(through_ball_plan.get("receiver_peer_id", 0))
		== controlled_player.owner_peer_id
	):
		var committed_target: Vector2 = through_ball_plan.get(
			"next_run_target",
			Vector2.ZERO
		)
		if not committed_target.is_zero_approx():
			_overdrive_through_run_target = committed_target
			_overdrive_through_run_until = maxf(
				_server_time_seconds() + 0.25,
				float(through_ball_plan.get("expires_msec", 0)) / 1000.0
			)
			_set_tactical_intent(
				INTENT_FORWARD_RUN,
				committed_target,
				int(through_ball_plan.get("initiator_peer_id", 0))
			)
			return committed_target
	if (
		now < _overdrive_through_run_until
		and not _overdrive_through_run_target.is_zero_approx()
	):
		_set_tactical_intent(
			INTENT_FORWARD_RUN,
			_overdrive_through_run_target,
			carrier.owner_peer_id
		)
		return _overdrive_through_run_target
	if (
		now < _next_overdrive_through_run_at
		or carrier.global_position.distance_to(ball.global_position)
		> carrier.kick_feedback_detection_distance + 280.0
	):
		return Vector2.ZERO

	_next_overdrive_through_run_at = (
		now + maxf(0.4, overdrive_through_run_retry_seconds)
	)
	var experiment_chance = clampf(
		coordinated_ability_play_chance,
		0.0,
		1.0
	)
	if match_manager != null and match_manager.cpu_training_mode:
		experiment_chance = maxf(experiment_chance, 0.68)
	else:
		experiment_chance = lerpf(
			experiment_chance * 0.45,
			experiment_chance,
			_get_ai_skill()
		)
	if _rng.randf() > experiment_chance:
		return Vector2.ZERO

	var best_target = _get_overdrive_through_run_target_for(
		controlled_player,
		carrier
	)
	if best_target.is_zero_approx():
		return Vector2.ZERO

	_overdrive_through_run_target = best_target
	_overdrive_through_run_until = (
		now + maxf(0.8, overdrive_through_run_duration)
	)
	_next_overdrive_through_run_at = (
		_overdrive_through_run_until
		+ maxf(0.4, overdrive_through_run_retry_seconds)
	)
	controlled_player.cpu_request_pass()
	_set_tactical_intent(
		INTENT_FORWARD_RUN,
		best_target,
		carrier.owner_peer_id
	)
	return best_target


func _get_overdrive_through_run_target_for(
	runner: FootballPlayer,
	carrier: FootballPlayer
) -> Vector2:
	if not is_instance_valid(runner) or not is_instance_valid(carrier):
		return Vector2.ZERO
	var attack_sign = _get_attack_sign()
	var best_target = Vector2.ZERO
	var best_score = -INF
	for candidate_index in range(8):
		var run_distance = _rng.randf_range(
			maxf(700.0, overdrive_through_run_minimum_distance),
			maxf(
				maxf(700.0, overdrive_through_run_minimum_distance),
				overdrive_through_run_maximum_distance
			)
		)
		var lateral_offset = _rng.randf_range(
			-overdrive_through_run_lateral_range,
			overdrive_through_run_lateral_range
		)
		if candidate_index < 2:
			lateral_offset = (
				-0.55 if candidate_index == 0 else 0.55
			) * overdrive_through_run_lateral_range
		var candidate = _clamp_to_field(
			ball.global_position
			+ Vector2(attack_sign * run_distance, lateral_offset)
		)
		var pass_distance = ball.global_position.distance_to(candidate)
		var runner_distance = runner.global_position.distance_to(candidate)
		if (
			pass_distance < minimum_pass_distance
			or pass_distance > maximum_pass_distance
			or runner_distance < 560.0
			or runner_distance > overdrive_through_run_maximum_distance * 1.45
		):
			continue
		var direct_clearance = _minimum_segment_clearance(
			ball.global_position,
			candidate
		)
		var wall_route = _get_best_wall_route(candidate)
		var wall_clearance = (
			float(wall_route.get("clearance", 0.0))
			if not wall_route.is_empty()
			else 0.0
		)
		var route_clearance = maxf(direct_clearance, wall_clearance)
		if route_clearance < support_minimum_lane_clearance * 0.7:
			continue
		var openness = _nearest_opponent_distance(candidate)
		var race_advantage = openness - runner_distance * 0.56
		var progress = (candidate.x - ball.global_position.x) * attack_sign
		var score = (
			openness * 0.52
			+ route_clearance * 0.38
			+ race_advantage * 0.34
			+ progress * 0.18
			- runner_distance * 0.08
		)
		if score > best_score:
			best_score = score
			best_target = candidate
	return best_target


func _get_elite_combination_support_position() -> Vector2:
	if _get_ai_skill() < elite_combination_minimum_skill:
		return Vector2.ZERO
	var possession_team = match_manager.get_cpu_possession_team()
	if (
		possession_team in [
			TEAM_BLUE,
			TEAM_RED
		]
		and possession_team != controlled_player.team
	):
		return Vector2.ZERO
	var plan = match_manager.get_cpu_combination_plan(controlled_player.team)
	if plan.is_empty():
		return Vector2.ZERO
	var peer_id = controlled_player.owner_peer_id
	var receiver_id = int(plan.get("receiver_peer_id", 0))
	if peer_id == receiver_id:
		return Vector2.ZERO
	var initiator_id = int(plan.get("initiator_peer_id", 0))
	var next_id = int(plan.get("next_peer_id", 0))
	if peer_id == initiator_id:
		var initiator_target: Vector2 = plan.get(
			"initiator_run_target",
			controlled_player.global_position
		)
		_set_tactical_intent(INTENT_FORWARD_RUN, initiator_target, receiver_id)
		return _clamp_to_field(initiator_target)
	if peer_id == next_id:
		var next_target: Vector2 = plan.get(
			"next_run_target",
			controlled_player.global_position
		)
		_set_tactical_intent(INTENT_FORWARD_RUN, next_target, receiver_id)
		return _clamp_to_field(next_target)
	return Vector2.ZERO


func _get_advance_play_support_position() -> Vector2:
	var now = _server_time_seconds()
	if (
		now < _planned_support_until
		and not _planned_support_position.is_zero_approx()
	):
		_set_tactical_intent(
			_planned_support_intent,
			_planned_support_position
		)
		return _planned_support_position
	if now < _next_support_plan_at:
		return Vector2.ZERO
	_next_support_plan_at = now + maxf(0.15, advance_play_retry_seconds)
	_planned_support_position = Vector2.ZERO
	_planned_support_until = 0.0
	_planned_support_intent = INTENT_IDLE
	var carrier = _get_likely_team_ball_carrier()
	if carrier == null or carrier == controlled_player:
		return Vector2.ZERO

	var support_shape = _get_dynamic_support_shape(carrier)
	var cover_target: Vector2 = support_shape.get(
		"cover",
		_get_dynamic_cover_position(carrier.global_position)
	)
	var forward_target: Vector2 = support_shape.get("forward", cover_target)
	var wide_target: Vector2 = support_shape.get("wide", cover_target)
	var cover_player = _closest_support_player_to(carrier, cover_target, null)
	var declared_cover = _get_declared_intent_player(INTENT_COVER, carrier)
	if declared_cover != null:
		cover_player = declared_cover
	var runner_player = _closest_support_player_to(
		carrier,
		forward_target,
		cover_player
	)
	var declared_runner = _get_declared_intent_player(
		INTENT_FORWARD_RUN,
		carrier
	)
	if declared_runner != null and declared_runner != cover_player:
		runner_player = declared_runner
	if controlled_player == cover_player:
		_planned_support_position = cover_target
		_planned_support_intent = INTENT_COVER
		_set_tactical_intent(INTENT_COVER, cover_target)
	elif controlled_player == runner_player:
		_planned_support_position = forward_target
		_planned_support_intent = INTENT_FORWARD_RUN
		_set_tactical_intent(INTENT_FORWARD_RUN, forward_target)
	else:
		_planned_support_position = wide_target
		_planned_support_intent = INTENT_WIDE_SUPPORT
		_set_tactical_intent(INTENT_WIDE_SUPPORT, wide_target)
	_planned_support_until = now + maxf(0.35, advance_play_duration)
	return _planned_support_position


func _get_dynamic_support_shape(carrier: FootballPlayer) -> Dictionary:
	var attack_sign = _get_attack_sign()
	var origin = carrier.global_position
	var projected_origin = origin + carrier.linear_velocity * 0.18
	var carrier_intention = _get_effective_player_intention(carrier)
	var carrier_action = StringName(carrier_intention.get("action", &""))
	if carrier_action in [
		INTENT_DRIBBLE,
		INTENT_PASS,
		INTENT_SHOOT,
		INTENT_CHASE
	]:
		var declared_target: Vector2 = carrier_intention.get(
			"target_position",
			projected_origin
		)
		var prediction_offset = (
			declared_target - origin
		).limit_length(dynamic_forward_distance)
		projected_origin = projected_origin.lerp(
			origin + prediction_offset,
			clampf(intention_target_blend, 0.0, 1.0)
		)
	var center_y = (minimum_field_y + maximum_field_y) * 0.5
	var upper_forward = _clamp_to_field(
		projected_origin + Vector2(
			attack_sign * dynamic_forward_distance,
			-dynamic_forward_width
		)
	)
	var lower_forward = _clamp_to_field(
		projected_origin + Vector2(
			attack_sign * dynamic_forward_distance,
			dynamic_forward_width
		)
	)
	var upper_score = _support_space_score(origin, upper_forward)
	var lower_score = _support_space_score(origin, lower_forward)
	var forward_target = (
		upper_forward if upper_score >= lower_score else lower_forward
	)
	var forward_side = signf(forward_target.y - projected_origin.y)
	if is_zero_approx(forward_side):
		forward_side = -1.0
	var cover_target = Vector2(
		projected_origin.x - attack_sign * dynamic_cover_distance,
		lerpf(
			projected_origin.y,
			center_y,
			clampf(dynamic_cover_center_blend, 0.0, 1.0)
		)
	)
	var wide_target = Vector2(
		projected_origin.x + attack_sign * dynamic_wide_distance,
		projected_origin.y - forward_side * dynamic_wide_width
	)
	var skill = _get_ai_skill()
	var team_strategy = _get_team_strategy()
	match team_strategy:
		CPU_STRATEGY_DIRECT:
			forward_target.x += attack_sign * lerpf(120.0, 520.0, skill)
		CPU_STRATEGY_COUNTER:
			forward_target.x += attack_sign * lerpf(220.0, 760.0, skill)
			cover_target.x -= attack_sign * 240.0
		CPU_STRATEGY_POSSESSION:
			forward_target = forward_target.lerp(projected_origin, 0.2)
			wide_target.y -= forward_side * lerpf(120.0, 420.0, skill)
		CPU_STRATEGY_HIGH_PRESS:
			cover_target.x += attack_sign * lerpf(160.0, 480.0, skill)
			wide_target.x += attack_sign * 260.0
		CPU_STRATEGY_WALL_PLAY:
			wide_target.y = (
				ball_wall_top_y + wall_route_edge_padding
				if wide_target.y < center_y
				else ball_wall_bottom_y - wall_route_edge_padding
			)
		CPU_STRATEGY_ABILITY_COMBO:
			forward_target.x += attack_sign * lerpf(180.0, 620.0, skill)
			wide_target.y -= forward_side * lerpf(140.0, 360.0, skill)
	if match_manager.is_overtime:
		# Keep the cover target intact: golden goal still punishes a double
		# commit. Only the runner and wide outlet become more aggressive.
		forward_target.x += attack_sign * overtime_forward_run_bonus
		wide_target.x += attack_sign * overtime_wide_support_bonus
	if _player_ability_is_available(
		carrier,
		FootballPlayer.ABILITY_POWER_STRIKE
	):
		# One player stays behind a potential high-speed rebound while
		# the other support option leaves the shooter's lane.
		cover_target.x -= attack_sign * 520.0
		wide_target.y -= forward_side * 260.0
	if _player_ability_is_available(
		carrier,
		FootballPlayer.ABILITY_TIME_SKIP_PASS
	):
		# Dead Zone Pass rewards a receiver arriving beyond the carrier,
		# rather than standing next to the stopping point.
		forward_target.x += attack_sign * 320.0
	if _player_ability_is_available(
		carrier,
		FootballPlayer.ABILITY_HEEL_TURN
	):
		# Phantom Heel needs a real backward outlet to turn pressure into a pass.
		cover_target.x += attack_sign * 220.0
		cover_target.y = lerpf(cover_target.y, ball.global_position.y, 0.38)
	if _player_ability_is_available(
		carrier,
		FootballPlayer.ABILITY_QUICK_TRIGGER
	):
		# A second runner attacks the space beyond the defender Curve Shot bends around.
		forward_target.x += attack_sign * 240.0
		wide_target.y -= forward_side * 180.0
	if _player_ability_is_available(
		carrier,
		FootballPlayer.ABILITY_OVERDRIVE
	):
		# Leave a through-ball lane in front of a speed boost while retaining
		# one player behind the play if the run does not work.
		forward_target.x += attack_sign * 380.0
		cover_target.x -= attack_sign * 180.0
	if _player_ability_is_available(
		carrier,
		FootballPlayer.ABILITY_BLIND_SPOT
	):
		# Pull support away from the closest defender so Mirage Step has an
		# isolated body to cross, then offer an outlet beyond the teleport.
		forward_target.x += attack_sign * 260.0
		wide_target.y -= forward_side * 300.0
	if _player_ability_is_available(
		carrier,
		FootballPlayer.ABILITY_ENFORCER
	):
		# Attack the space that should open when the carrier removes a marker.
		forward_target.x += attack_sign * 300.0
	if _player_ability_is_available(
		carrier,
		FootballPlayer.ABILITY_META_VISION
	):
		# Meta Vision can read the longer diagonal and wall return, so provide
		# two separated destinations instead of clustering around the ball.
		forward_target.x += attack_sign * 260.0
		wide_target.y -= forward_side * 260.0
	if _player_ability_is_available(
		carrier,
		FootballPlayer.ABILITY_BOOGIE_WOOGIE
	):
		# Be ready for the ball displaced by the arrival shockwave without
		# standing beside the opponent that will be swapped.
		wide_target = wide_target.lerp(
			ball.global_position + Vector2(attack_sign * 520.0, -forward_side * 620.0),
			0.42
		)
	if _player_ability_is_available(
		carrier,
		FootballPlayer.ABILITY_IRON_ANCHOR
	):
		# Give a momentum trap a nearby first-time outlet instead of watching it stop.
		wide_target.x = lerpf(wide_target.x, ball.global_position.x, 0.35)
		wide_target.y = lerpf(wide_target.y, ball.global_position.y, 0.28)
	if (
		_player_ability_is_available(
			carrier,
			FootballPlayer.ABILITY_BURST_DRIBBLE
		)
		or _player_ability_is_available(
			carrier,
			FootballPlayer.ABILITY_ELASTIC_STEP
		)
	):
		wide_target.y -= forward_side * 220.0
	return {
		"cover": _clamp_to_field(cover_target),
		"forward": _clamp_to_field(forward_target),
		"wide": _clamp_to_field(wide_target)
	}


func _support_space_score(origin: Vector2, target: Vector2) -> float:
	return (
		minf(_minimum_segment_clearance(origin, target), 1300.0) * 0.52
		+ minf(_nearest_opponent_distance(target), 1500.0) * 0.48
	)


func _closest_support_player_to(
	carrier: FootballPlayer,
	target: Vector2,
	excluded_player: FootballPlayer
) -> FootballPlayer:
	var closest_player: FootballPlayer
	var closest_score = INF
	for teammate in _get_teammates():
		if (
			not is_instance_valid(teammate)
			or teammate == carrier
			or teammate == excluded_player
			or not teammate.controls_enabled
			or _is_designated_goalkeeper(teammate)
		):
			continue
		if (
			teammate.server_ability_active
			and teammate.server_active_ability_id
			== FootballPlayer.ABILITY_ENFORCER
		):
			continue
		var score = teammate.global_position.distance_to(target)
		score -= _get_support_role_ability_bonus(
			teammate,
			target,
			carrier
		)
		if (
			score < closest_score
			or (
				is_equal_approx(score, closest_score)
				and closest_player != null
				and teammate.owner_peer_id < closest_player.owner_peer_id
			)
		):
			closest_score = score
			closest_player = teammate
	return closest_player


func _get_support_role_ability_bonus(
	player: FootballPlayer,
	target: Vector2,
	carrier: FootballPlayer
) -> float:
	if not is_instance_valid(player) or not is_instance_valid(carrier):
		return 0.0
	var attack_sign = _get_attack_sign()
	var forward_progress = (target.x - carrier.global_position.x) * attack_sign
	var lateral_distance = absf(target.y - carrier.global_position.y)
	var is_forward_run = forward_progress > 360.0
	var is_cover = forward_progress < -260.0
	var role_bonus: float = _get_role_support_bias(
		player,
		forward_progress,
		lateral_distance
	)
	if player.is_haaland_boss():
		# The boss should be the team's penalty-box runner, not the safety valve.
		if is_forward_run:
			role_bonus += striker_support_bonus * 1.10 + 180.0
		elif is_cover:
			role_bonus -= striker_support_bonus * 0.88
	match FootballPlayer.get_ability_role(player.selected_ability):
		FootballPlayer.ABILITY_ROLE_ATTACK:
			if is_forward_run:
				role_bonus += dribble_support_role_bonus * 0.18
		FootballPlayer.ABILITY_ROLE_PLAYMAKER:
			if lateral_distance > 420.0:
				role_bonus += dribble_support_role_bonus * 0.14
		FootballPlayer.ABILITY_ROLE_DEFENSE:
			if is_cover:
				role_bonus += defensive_support_role_bonus * 0.18
	if not _player_ability_is_available(player, player.selected_ability):
		return role_bonus
	var ability_bonus = 0.0
	match player.selected_ability:
		FootballPlayer.ABILITY_DIRECT_FINISH:
			ability_bonus = (
				trap_or_volley_receive_lane_bonus if is_forward_run else 0.0
			)
		FootballPlayer.ABILITY_OVERDRIVE:
			if is_forward_run:
				ability_bonus = overdrive_forward_run_bonus
			elif is_cover:
				ability_bonus = -overdrive_cover_role_penalty
		FootballPlayer.ABILITY_BURST_DRIBBLE, FootballPlayer.ABILITY_ELASTIC_STEP, FootballPlayer.ABILITY_BLIND_SPOT, FootballPlayer.ABILITY_BREAKAWAY, FootballPlayer.ABILITY_SNAPBACK, FootballPlayer.ABILITY_NUTMEG:
			ability_bonus = (
				dribble_support_role_bonus
				if is_forward_run or lateral_distance > 520.0
				else 0.0
			)
		FootballPlayer.ABILITY_POWER_STRIKE:
			if (
				is_cover
				and _team_has_selected_ability(
					FootballPlayer.ABILITY_DIRECT_FINISH
				)
				and _get_team_strategy() in [
					CPU_STRATEGY_DIRECT,
					CPU_STRATEGY_COUNTER,
					CPU_STRATEGY_ABILITY_COMBO
				]
			):
				ability_bonus = defensive_support_role_bonus * 1.45
			elif is_forward_run:
				ability_bonus = dribble_support_role_bonus * 0.45
		FootballPlayer.ABILITY_QUICK_TRIGGER:
			ability_bonus = (
				dribble_support_role_bonus * 0.7 if is_forward_run else 0.0
			)
		FootballPlayer.ABILITY_TIME_SKIP_PASS:
			ability_bonus = (
				dribble_support_role_bonus * 1.15
				if lateral_distance > 320.0 and not is_cover
				else dribble_support_role_bonus * 0.35
			)
		FootballPlayer.ABILITY_META_VISION:
			ability_bonus = dribble_support_role_bonus * (0.72 if not is_cover else 0.28)
		FootballPlayer.ABILITY_RETURN_TAG:
			ability_bonus = dribble_support_role_bonus * (0.95 if is_forward_run or lateral_distance > 360.0 else 0.35)
		FootballPlayer.ABILITY_SIDE_SWIPE:
			ability_bonus = dribble_support_role_bonus * (0.9 if lateral_distance > 380.0 else 0.3)
		FootballPlayer.ABILITY_BOOGIE_WOOGIE:
			ability_bonus = dribble_support_role_bonus * (
				0.62 if not is_cover and forward_progress > 80.0 else 0.24
			)
		FootballPlayer.ABILITY_HEEL_TURN:
			ability_bonus = dribble_support_role_bonus * (
				0.55 if lateral_distance > 260.0 else 0.22
			)
		FootballPlayer.ABILITY_COPYCAT:
			ability_bonus = dribble_support_role_bonus * 0.24
		FootballPlayer.ABILITY_DECOY_RUN:
			# Decoy Run itself is the off-ball value, so prefer a forward support
			# lane but don't make this player demand possession.
			ability_bonus = dribble_support_role_bonus * (0.32 if is_forward_run else 0.1)
		FootballPlayer.ABILITY_IRON_ANCHOR, FootballPlayer.ABILITY_REFLEX_BLOCK, FootballPlayer.ABILITY_ECHO, FootballPlayer.ABILITY_GOALKEEPER_REACH:
			ability_bonus = defensive_support_role_bonus * (0.82 if is_cover else -0.22 if is_forward_run else 0.2)
		FootballPlayer.ABILITY_ENFORCER:
			ability_bonus = defensive_support_role_bonus * (0.45 if is_cover else 0.18)
	return role_bonus + ability_bonus


func _get_receiver_attack_value(
	receiver: FootballPlayer,
	reception: Vector2,
	goal_center: Vector2
) -> float:
	if (
		not is_instance_valid(receiver)
		or not receiver.controls_enabled
		or reception.is_zero_approx()
		or goal_center.is_zero_approx()
	):
		return 0.0
	var goal_distance: float = reception.distance_to(goal_center)
	var lane: float = _minimum_segment_clearance(reception, goal_center)
	var space: float = _nearest_opponent_distance(reception)
	var goal_value: float = 1.0 - clampf(
		(goal_distance - 650.0) / 4200.0,
		0.0,
		1.0
	)
	var lane_value: float = clampf(lane / 620.0, 0.0, 1.0)
	var space_value: float = clampf(space / 900.0, 0.0, 1.0)
	var value: float = (
		goal_value * 0.46
		+ lane_value * 0.34
		+ space_value * 0.20
	)
	var ability_id: int = receiver.selected_ability
	if _player_ability_is_available(receiver, ability_id):
		match ability_id:
			FootballPlayer.ABILITY_DIRECT_FINISH:
				if goal_distance <= 2850.0:
					value += 0.36
			FootballPlayer.ABILITY_POWER_STRIKE:
				if goal_distance <= power_strike_activation_goal_distance:
					value += 0.30
			FootballPlayer.ABILITY_QUICK_TRIGGER:
				if (
					goal_distance >= curve_shot_minimum_goal_distance * 0.72
					and goal_distance <= curve_shot_maximum_goal_distance * 1.08
				):
					value += 0.27
			FootballPlayer.ABILITY_TIME_SKIP_PASS:
				value += 0.18
			FootballPlayer.ABILITY_RETURN_TAG:
				value += 0.18
			FootballPlayer.ABILITY_SIDE_SWIPE:
				value += 0.16
			FootballPlayer.ABILITY_OVERDRIVE, FootballPlayer.ABILITY_BREAKAWAY:
				value += 0.20
			FootballPlayer.ABILITY_META_VISION:
				value += 0.12
			FootballPlayer.ABILITY_BURST_DRIBBLE, FootballPlayer.ABILITY_ELASTIC_STEP, FootballPlayer.ABILITY_BLIND_SPOT, FootballPlayer.ABILITY_NUTMEG:
				if space < 780.0:
					value += 0.12
	match _get_tactical_role(receiver):
		TACTICAL_ROLE_STRIKER:
			value += 0.10
		TACTICAL_ROLE_PLAYMAKER:
			value += 0.05
	if receiver.is_haaland_boss():
		# Feeding Haaland is more valuable because the completed pass activates
		# Relentless Nine and his permanent Power Strike can finish immediately.
		value += 0.16
		if goal_distance <= 3300.0:
			value += 0.12
		if lane >= 240.0:
			value += 0.07
	return clampf(value, 0.0, 1.45)


func _get_best_team_second_ball_value(goal_center: Vector2) -> float:
	if goal_center.is_zero_approx():
		return 0.0
	var best: float = 0.0
	for teammate in _get_teammates():
		if (
			not is_instance_valid(teammate)
			or teammate == controlled_player
			or not teammate.controls_enabled
			or _is_designated_goalkeeper(teammate)
		):
			continue
		var proximity: float = 1.0 - clampf(
			(teammate.global_position.distance_to(goal_center) - 500.0)
			/ 2500.0,
			0.0,
			1.0
		)
		var attack_value: float = _get_receiver_attack_value(
			teammate,
			teammate.global_position,
			goal_center
		)
		best = maxf(
			best,
			clampf(proximity * 0.46 + attack_value * 0.62, 0.0, 1.35)
		)
	return best


func _get_power_distribution_support_position() -> Vector2:
	# This used to inspect the OFF-BALL player's ability, which meant teammates
	# did not actually react to a Power Strike carrier. Build the support shape
	# from the ball carrier's ready attack ability instead: one player protects
	# the counter, one attacks the far-post/second-ball lane, and extra teammates
	# provide a cutback/continuation option. This makes the whole team play off
	# Power Strike / Curve Shot rather than waiting for a clean solo goal.
	var carrier = _get_likely_team_ball_carrier()
	if (
		carrier == null
		or carrier == controlled_player
		or _ball_is_in_own_goal_danger()
		or _is_designated_goalkeeper(controlled_player)
	):
		return Vector2.ZERO
	var carrier_ability: int = carrier.selected_ability
	if carrier_ability not in [
		FootballPlayer.ABILITY_POWER_STRIKE,
		FootballPlayer.ABILITY_QUICK_TRIGGER
	]:
		return Vector2.ZERO
	if not _player_ability_is_available(carrier, carrier_ability):
		return Vector2.ZERO

	var opponent_goal: FootballGoal = _get_opponent_goal()
	if opponent_goal == null:
		return Vector2.ZERO
	var attack_sign: float = _get_attack_sign()
	var goal_center: Vector2 = _get_goal_center(opponent_goal)
	var carrier_goal_distance: float = carrier.global_position.distance_to(goal_center)
	var cover_target: Vector2 = _get_dynamic_cover_position(carrier.global_position)
	var shot_window: float = (
		4700.0
		if carrier_ability == FootballPlayer.ABILITY_POWER_STRIKE
		else curve_shot_maximum_goal_distance
	)
	# In a 3v3 the nominal goalkeeper already supplies the safety layer. Do not
	# sacrifice the only other outfield teammate by forcing them behind the ball.
	# In 4v4+, keep an extra cover only while the attack is still being built from
	# deep; once the empowered carrier enters chance-creation range, attack the
	# second ball with the available outfielders and rely on transition recovery.
	var cover_player: FootballPlayer
	if (
		_get_active_team_player_count() >= 4
		and carrier_goal_distance > shot_window
	):
		cover_player = _closest_support_player_to(
			carrier,
			cover_target,
			null
		)
	if controlled_player == cover_player:
		_set_tactical_intent(INTENT_COVER, cover_target, carrier.owner_peer_id)
		return cover_target

	var center_y: float = (minimum_field_y + maximum_field_y) * 0.5
	var far_side: float = 1.0 if carrier.global_position.y <= center_y else -1.0
	var rebound_depth: float = maxf(780.0, off_ball_rebound_goal_distance)
	var attack_target: Vector2
	if carrier_goal_distance <= shot_window:
		attack_target = Vector2(
			goal_center.x - attack_sign * rebound_depth,
			goal_center.y + far_side * off_ball_rebound_side_offset
		)
	else:
		# From deeper positions, a Power/Curve carrier can use the empowered kick
		# as a driven delivery. Give a teammate an advanced lane to receive it.
		attack_target = carrier.global_position + Vector2(
			attack_sign * clampf(carrier_goal_distance * 0.30, 1050.0, 1850.0),
			far_side * clampf(off_ball_rebound_side_offset * 0.82, 320.0, 620.0)
		)
	attack_target = _clamp_to_field(attack_target)
	var runner_player: FootballPlayer = _closest_support_player_to(
		carrier,
		attack_target,
		cover_player
	)
	if controlled_player == runner_player:
		_set_tactical_intent(INTENT_FORWARD_RUN, attack_target, carrier.owner_peer_id)
		return attack_target

	# A third outfielder should not pile into the same rebound point. Sit on the
	# opposite cutback lane so a save/deflection or received driven pass has an
	# immediate continuation instead of forcing another dribble.
	var continuation_target: Vector2 = _clamp_to_field(Vector2(
		goal_center.x - attack_sign * (rebound_depth + 620.0),
		goal_center.y - far_side * maxf(520.0, off_ball_rebound_side_offset * 1.15)
	))
	_set_tactical_intent(
		INTENT_WIDE_SUPPORT,
		continuation_target,
		carrier.owner_peer_id
	)
	return continuation_target


func _get_dynamic_cover_position(reference_position: Vector2) -> Vector2:
	var center_y = (minimum_field_y + maximum_field_y) * 0.5
	return _clamp_to_field(Vector2(
		reference_position.x - _get_attack_sign() * dynamic_cover_distance,
		lerpf(
			reference_position.y,
			center_y,
			clampf(dynamic_cover_center_blend, 0.0, 1.0)
		)
	))


func _add_support_candidate(
	candidates: Array[Dictionary],
	position: Vector2,
	origin: Vector2,
	third_player_run: bool
) -> void:
	candidates.append({
		"position": _clamp_to_field(position),
		"origin": origin,
		"third_player": third_player_run
	})


func _get_likely_team_ball_carrier() -> FootballPlayer:
	var parallel_plan := _get_large_team_parallel_plan()
	if not parallel_plan.is_empty():
		var parallel_carrier_peer_id := int(parallel_plan.get("ball_actor_peer_id", 0))
		if parallel_carrier_peer_id > 0:
			var parallel_carrier := _get_teammate_by_peer_id(parallel_carrier_peer_id)
			if is_instance_valid(parallel_carrier) and parallel_carrier.controls_enabled:
				return parallel_carrier
	var best_player: FootballPlayer
	var best_score = INF
	for teammate in _get_teammates():
		if not is_instance_valid(teammate) or not teammate.controls_enabled:
			continue
		var score = teammate.global_position.distance_to(ball.global_position)
		var intention = _get_effective_player_intention(teammate)
		var action = StringName(intention.get("action", &""))
		if action in [
			INTENT_CHASE,
			INTENT_DRIBBLE,
			INTENT_SHOOT,
			INTENT_PASS
		]:
			score -= 340.0
		if teammate.owner_peer_id == ball.last_touch_peer_id:
			score -= 260.0
		if score < best_score:
			best_score = score
			best_player = teammate
	return best_player


func _get_likely_first_pass_receiver(
	carrier: FootballPlayer
) -> FootballPlayer:
	var attack_sign = _get_attack_sign()
	var best_receiver: FootballPlayer
	var best_score = -INF
	for teammate in _get_teammates():
		if (
			not is_instance_valid(teammate)
			or teammate == carrier
			or teammate == controlled_player
			or not teammate.controls_enabled
			or _is_designated_goalkeeper(teammate)
		):
			continue
		var clearance = _minimum_segment_clearance(
			carrier.global_position,
			teammate.global_position
		)
		if clearance < pass_lane_clearance * 0.72:
			continue
		var forward_progress = (
			teammate.global_position.x - carrier.global_position.x
		) * attack_sign
		var score = (
			forward_progress * 0.55
			+ _nearest_opponent_distance(teammate.global_position) * 0.36
			+ minf(clearance, 1100.0) * 0.24
		)
		if score > best_score:
			best_score = score
			best_receiver = teammate
	return best_receiver


func _nearest_other_teammate_distance(position: Vector2) -> float:
	var nearest = INF
	for teammate in _get_teammates():
		if (
			not is_instance_valid(teammate)
			or teammate == controlled_player
			or not teammate.controls_enabled
		):
			continue
		nearest = minf(nearest, teammate.global_position.distance_to(position))
	return nearest


func _get_direct_finish_support_position() -> Vector2:
	var opponent_goal = _get_opponent_goal()
	if opponent_goal == null:
		return ball.global_position
	var goal_center = _get_goal_center(opponent_goal)
	var attack_sign = _get_attack_sign()
	var candidate_x = (
		goal_center.x
		- attack_sign * direct_finish_support_goal_distance
	)
	var mouth_range = opponent_goal.get_mouth_y_range()
	var upper_candidate = Vector2(
		candidate_x,
		clampf(
			goal_center.y - direct_finish_support_side_offset,
			mouth_range.x + 180.0,
			mouth_range.y - 180.0
		)
	)
	var lower_candidate = Vector2(
		candidate_x,
		clampf(
			goal_center.y + direct_finish_support_side_offset,
			mouth_range.x + 180.0,
			mouth_range.y - 180.0
		)
	)
	var upper_score = (
		_nearest_opponent_distance(upper_candidate)
		+ _minimum_segment_clearance(ball.global_position, upper_candidate)
	)
	var lower_score = (
		_nearest_opponent_distance(lower_candidate)
		+ _minimum_segment_clearance(ball.global_position, lower_candidate)
	)
	return upper_candidate if upper_score >= lower_score else lower_candidate


func _get_enforcer_pressure_position() -> Vector2:
	var target: FootballPlayer
	var best_relevance = -INF
	for opponent in _get_opponents():
		if not is_instance_valid(opponent) or not opponent.controls_enabled:
			continue
		var player_distance = controlled_player.global_position.distance_to(
			opponent.global_position
		)
		var ball_distance = opponent.global_position.distance_to(
			ball.global_position
		)
		var carrier_bonus = 720.0 if opponent.owner_peer_id == ball.last_touch_peer_id else 0.0
		var shot_lane_bonus = 0.0
		if not _shot_target.is_zero_approx():
			shot_lane_bonus = maxf(
				0.0,
				700.0 - _distance_to_segment(
					opponent.global_position,
					ball.global_position,
					_shot_target
				)
			)
		var relevance = (
			carrier_bonus
			+ shot_lane_bonus
			+ maxf(0.0, 1050.0 - ball_distance) * 0.65
			- player_distance * 0.32
			+ _get_player_ability_threat(opponent) * 0.24
		)
		if relevance > best_relevance:
			best_relevance = relevance
			target = opponent
	if target == null:
		target = _get_nearest_opponent_to(controlled_player.global_position)
	if target == null:
		_enforcer_target = null
		return ball.global_position
	_enforcer_target = target
	var lead_position = (
		target.global_position + target.linear_velocity * 0.1
	)
	var approach_direction = controlled_player.global_position.direction_to(
		lead_position
	)
	return lead_position + approach_direction * minf(
		60.0,
		enforcer_pressure_distance
	)


func _try_enforcer_kick() -> void:
	var now = _server_time_seconds()
	if now < _next_enforcer_kick_at or not is_instance_valid(_enforcer_target):
		return
	if controlled_player.cpu_enforcer_kick(enforcer_kick_force_ratio):
		_next_enforcer_kick_at = now + maxf(0.12, enforcer_kick_retry_seconds)


func _get_own_goal_center_or_ball() -> Vector2:
	var own_goal = _get_own_goal()
	return _get_goal_center(own_goal) if own_goal != null else ball.global_position


func _get_defensive_position() -> Vector2:
	var own_goal = _get_own_goal()
	if own_goal == null:
		return _get_dynamic_cover_position(ball.global_position)
	var assignment = match_manager.get_cpu_defensive_assignment(
		controlled_player.team,
		controlled_player.owner_peer_id
	)
	var role = StringName(assignment.get("role", &""))
	var assigned_target := resolve_cpu_defensive_assignment_target(assignment)
	if role == &"press":
		var press_target = (
			assigned_target
			if not assigned_target.is_zero_approx()
			else _get_primary_defensive_press_position(own_goal)
		)
		_set_tactical_intent(INTENT_CHASE, press_target)
		return press_target
	if role == &"cover":
		var lane_cover = (
			assigned_target
			if not assigned_target.is_zero_approx()
			else _get_defensive_lane_cover_position(own_goal)
		)
		_set_tactical_intent(INTENT_COVER, lane_cover)
		return lane_cover
	if role == &"final":
		var final_lane = (
			assigned_target
			if not assigned_target.is_zero_approx()
			else _get_defensive_lane_cover_position(own_goal)
		)
		_set_tactical_intent(INTENT_COVER, final_lane)
		return final_lane
	if role == &"mark":
		var assigned_mark = _get_opponent_by_peer_id(
			int(assignment.get("target_peer_id", 0))
		)
		if not assigned_target.is_zero_approx():
			_set_tactical_intent(
				INTENT_MARK,
				assigned_target,
				assigned_mark.owner_peer_id if assigned_mark != null else 0
			)
			return assigned_target

	# Fallback only while a team assignment is unavailable (for example during
	# a reset). Normal defending is coordinated through the shared assignment.
	var counterpress_target = _get_elite_counterpress_position(own_goal)
	if not counterpress_target.is_zero_approx():
		_set_tactical_intent(INTENT_MARK, counterpress_target)
		return counterpress_target
	var cover_target = _get_defensive_cover_target(own_goal)
	var cover_player = _get_temporary_cover_player(cover_target)
	if controlled_player == cover_player:
		_set_tactical_intent(INTENT_COVER, cover_target)
		return cover_target
	var mark = _select_marking_target()
	if mark == null:
		_set_tactical_intent(INTENT_COVER, cover_target)
		return cover_target

	var own_goal_center = _get_goal_center(own_goal)
	var toward_goal = mark.global_position.direction_to(
		own_goal_center
	)
	var ability_marking_distance = _get_ability_aware_marking_distance(mark)
	var mark_position = (
		mark.global_position
		+ toward_goal * ability_marking_distance
	)
	if _get_team_strategy() == CPU_STRATEGY_HIGH_PRESS:
		mark_position = mark.global_position + toward_goal * lerpf(
		ability_marking_distance,
		ability_marking_distance * 0.48,
		_get_ai_skill()
	)
	mark_position.y = lerpf(
		mark_position.y,
		ball.global_position.y,
		clampf(defensive_block_ball_blend, 0.0, 1.0) * 0.35
	)
	_set_tactical_intent(
		INTENT_MARK,
		mark_position,
		mark.owner_peer_id
	)
	return mark_position


func _update_anticipatory_carrier_defense() -> bool:
	var own_goal = _get_own_goal()
	var carrier = _get_likely_opponent_ball_carrier()
	if own_goal == null or carrier == null or not _opponent_controls_ball(carrier):
		return false
	var assignment = match_manager.get_cpu_defensive_assignment(
		controlled_player.team,
		controlled_player.owner_peer_id
	)
	var role = StringName(assignment.get("role", &""))
	if not _is_true_one_vs_one() and role not in [&"press", &"final"]:
		return false
	var target = _get_anticipatory_goal_defense_position(
		carrier,
		own_goal,
		false
	)
	if target.is_zero_approx():
		return false
	_movement_target = target
	_set_tactical_intent(
		INTENT_MARK,
		_movement_target,
		carrier.owner_peer_id
	)
	if controlled_player.global_position.distance_to(ball.global_position) <= (
		controlled_player.kick_feedback_detection_distance
	):
		_try_defensive_ball_win()
	return true


func _opponent_controls_ball(opponent: FootballPlayer) -> bool:
	if not is_instance_valid(opponent) or not opponent.controls_enabled:
		return false
	var control_distance = maxf(
		opponent.kick_feedback_detection_distance * 1.45,
		330.0
	)
	var ball_distance = opponent.global_position.distance_to(ball.global_position)
	if ball_distance > control_distance:
		return false
	var recent_touch = ball.last_touch_peer_id == opponent.owner_peer_id
	var defender_distance = controlled_player.global_position.distance_to(
		ball.global_position
	)
	var clearly_first_to_slow_ball = (
		ball.linear_velocity.length() <= 950.0
		and ball_distance + 90.0 < defender_distance
	)
	return recent_touch or opponent.server_is_charging or clearly_first_to_slow_ball


func _opponent_has_live_ball_control() -> bool:
	for opponent in _get_opponents():
		if _opponent_controls_ball(opponent):
			return true
	return false


func _has_verified_incoming_teammate_delivery() -> bool:
	# Early precharge is only justified when the CPU is the named/detected
	# receiver of a real teammate delivery. This keeps the anticipation mechanic
	# while preventing a CPU from charging for a ball an opponent owns.
	if _opponent_has_live_ball_control():
		return false
	var intention = _get_live_receive_intention(
		match_manager.get_cpu_pass_intention(
			controlled_player.owner_peer_id
		)
	)
	if intention.is_empty():
		intention = _get_detected_pass_reception()
	if intention.is_empty():
		return false
	var passer_peer_id = int(intention.get("passer_peer_id", 0))
	var passer = _get_teammate_by_peer_id(passer_peer_id)
	if not is_instance_valid(passer):
		return false
	# Once the pass left the foot, it must still be travelling generally toward
	# this receiver/reception point. Before release, a charging teammate is a
	# valid announced delivery as long as the intention is still live.
	if ball.last_touch_peer_id == passer_peer_id:
		var reception_position: Vector2 = intention.get(
			"position",
			controlled_player.global_position
		)
		var toward_reception = ball.global_position.direction_to(
			reception_position
		)
		return (
			ball.linear_velocity.length() >= incoming_pass_minimum_speed * 0.55
			and (
				toward_reception.is_zero_approx()
				or ball.linear_velocity.normalized().dot(toward_reception) > 0.25
			)
		)
	return passer.server_is_charging


func _get_anticipatory_goal_defense_position(
	carrier: FootballPlayer,
	own_goal: FootballGoal,
	as_goalkeeper: bool
) -> Vector2:
	if (
		not is_instance_valid(carrier)
		or own_goal == null
		or not _opponent_controls_ball(carrier)
	):
		return Vector2.ZERO
	var goal_center = _get_goal_center(own_goal)
	var carrier_goal_distance = carrier.global_position.distance_to(goal_center)
	if carrier_goal_distance > maxf(
		900.0,
		anticipatory_defense_maximum_goal_distance
	):
		return Vector2.ZERO
	var read = _get_defensive_shot_read(carrier, own_goal)
	if read.is_empty():
		return Vector2.ZERO
	var shot_target: Vector2 = read.get("target", goal_center)
	var route_confidence = float(read.get("route_confidence", 0.0))
	var route_threat = float(read.get("route_threat", 0.0))
	var route_risk = route_confidence * route_threat
	var route_intercept: Vector2 = read.get(
		"route_intercept",
		Vector2.ZERO
	)
	var route_goal_position: Vector2 = read.get(
		"route_goal_position",
		Vector2.ZERO
	)
	if as_goalkeeper:
		if not route_goal_position.is_zero_approx():
			shot_target = route_goal_position
		var keeper_x = (
			own_goal.get_goal_plane_x()
			+ _get_attack_sign()
			* maxf(120.0, anticipatory_defense_keeper_depth)
		)
		var keeper_y = _get_line_y_at_x(
			ball.global_position,
			shot_target,
			keeper_x,
			shot_target.y
		)
		if (
			route_risk >= pre_shot_reader_minimum_confidence * 0.72
			and not route_goal_position.is_zero_approx()
		):
			keeper_y = route_goal_position.y
		elif (
			route_risk >= pre_shot_reader_minimum_confidence * 0.72
			and not route_intercept.is_zero_approx()
		):
			keeper_y = lerpf(
				keeper_y,
				route_intercept.y,
				clampf(route_risk, 0.0, 1.0)
			)
		var mouth_range = own_goal.get_mouth_y_range()
		keeper_y = clampf(
			keeper_y,
			mouth_range.x + goalkeeper_mouth_padding,
			mouth_range.y - goalkeeper_mouth_padding
		)
		return _clamp_to_field(Vector2(keeper_x, keeper_y))

	# The learned policy keeps control. This route point only improves the target
	# supplied to its existing shadow/protect actions when the read is reliable.
	if (
		route_risk >= pre_shot_reader_minimum_confidence * 0.72
		and not route_intercept.is_zero_approx()
	):
		var route_target = route_intercept
		var defender_goal_distance = controlled_player.global_position.distance_to(
			goal_center
		)
		var defender_is_beaten = (
			carrier_goal_distance
			+ maxf(0.0, anticipatory_defense_beaten_margin)
			< defender_goal_distance
		)
		if defender_is_beaten:
			var safety_depth = minf(
				maxf(420.0, carrier_goal_distance * 0.34),
				1050.0
			)
			var safety_target = goal_center + goal_center.direction_to(
				ball.global_position
			) * safety_depth
			route_target = route_target.lerp(safety_target, 0.42)
		return _clamp_to_field(route_target)

	var ball_to_target = ball.global_position.direction_to(shot_target)
	if ball_to_target.is_zero_approx():
		ball_to_target = ball.global_position.direction_to(goal_center)
	if ball_to_target.is_zero_approx():
		return Vector2.ZERO
	var shot_distance = ball.global_position.distance_to(shot_target)
	var standoff = clampf(
		anticipatory_defense_ball_standoff
		+ carrier_goal_distance * 0.045,
		360.0,
		760.0
	)
	if controlled_player.is_satoru_gojo():
		# Gojo plays the existing anticipatory defense from a deeper cushion so
		# he protects the goal instead of turning his boss profile into a constant
		# high press. He still steps in once the normal defensive read sees a win.
		standoff = minf(980.0, standoff + 180.0)
	standoff = minf(standoff, shot_distance * 0.58)
	var target = ball.global_position + ball_to_target * standoff
	var defender_goal_distance = controlled_player.global_position.distance_to(
		goal_center
	)
	var defender_is_beaten = (
		carrier_goal_distance
		+ maxf(0.0, anticipatory_defense_beaten_margin)
		< defender_goal_distance
	)
	if defender_is_beaten:
		var safety_depth = minf(
			maxf(420.0, carrier_goal_distance * 0.34),
			1050.0
		)
		var safety_target = goal_center + goal_center.direction_to(
			ball.global_position
		) * safety_depth
		target = target.lerp(safety_target, 0.58)
	return _clamp_to_field(target)


func _get_defensive_shot_read(
	carrier: FootballPlayer,
	own_goal: FootballGoal
) -> Dictionary:
	var now = _server_time_seconds()
	var mouth_range = own_goal.get_mouth_y_range()
	var minimum_y = mouth_range.x + maxf(
		70.0,
		anticipatory_defense_goal_mouth_padding
	)
	var maximum_y = mouth_range.y - maxf(
		70.0,
		anticipatory_defense_goal_mouth_padding
	)
	if minimum_y > maximum_y:
		var fallback_center = (mouth_range.x + mouth_range.y) * 0.5
		minimum_y = fallback_center
		maximum_y = fallback_center
	var center_y = (minimum_y + maximum_y) * 0.5
	var goal_x = own_goal.get_goal_plane_x()

	# Real kicks use the carrier-to-ball contact line. Movement direction is only
	# a fallback; treating movement as aim was the main reason bank/power setups
	# could look harmless until after release.
	var aim_direction = carrier.global_position.direction_to(
		ball.global_position
	)
	if aim_direction.is_zero_approx():
		aim_direction = carrier.server_direction.normalized()
	if aim_direction.is_zero_approx():
		aim_direction = carrier.linear_velocity.normalized()
	if aim_direction.is_zero_approx():
		aim_direction = ball.global_position.direction_to(
			Vector2(goal_x, center_y)
		)
	var ray_y = _get_ray_y_at_x(
		ball.global_position,
		aim_direction,
		goal_x,
		center_y
	)
	ray_y = clampf(ray_y, minimum_y, maximum_y)
	var maximum_charge = maxf(
		0.01,
		carrier.cpu_get_maximum_shot_charge_seconds()
	)
	var charge_ratio = 0.0
	if carrier.server_is_charging:
		charge_ratio = clampf(
			(now - carrier.server_charge_started_at) / maximum_charge,
			0.0,
			1.0
		)
	var relative = ball.global_position.direction_to(carrier.global_position)
	var tangential_speed = 0.0
	if not relative.is_zero_approx():
		tangential_speed = absf(
			carrier.linear_velocity.dot(Vector2(-relative.y, relative.x))
		)
	var orbiting_ball = tangential_speed >= maxf(
		60.0,
		anticipatory_defense_orbit_speed
	)
	if _defense_read_carrier_peer_id != carrier.owner_peer_id:
		_defense_read_carrier_peer_id = carrier.owner_peer_id
		_defense_last_read_y = ray_y
		_defense_last_read_at = now
		_defense_last_aim_change_at = now
		_defense_fake_guard_until = 0.0
	else:
		var elapsed = now - _defense_last_read_at
		if (
			elapsed <= 0.38
			and absf(ray_y - _defense_last_read_y)
			>= maxf(80.0, anticipatory_defense_aim_flip_threshold)
		):
			_defense_last_aim_change_at = now
			if (
				not carrier.server_is_charging
				or charge_ratio < anticipatory_defense_minimum_charge_read
			):
				_defense_fake_guard_until = now + maxf(
					0.05,
					anticipatory_defense_fake_guard_seconds
				)
		_defense_last_read_y = ray_y
		_defense_last_read_at = now
	var aim_stable_seconds = maxf(0.0, now - _defense_last_aim_change_at)
	var aim_trust = 0.22
	if carrier.server_is_charging:
		aim_trust = lerpf(0.42, 0.9, charge_ratio)
		if aim_stable_seconds < 0.08 and charge_ratio < 0.34:
			aim_trust *= 0.62
	if orbiting_ball and charge_ratio < 0.42:
		aim_trust *= 0.48
	if now < _defense_fake_guard_until and charge_ratio < 0.38:
		aim_trust *= 0.2
	var open_corner_y = (
		maximum_y
		if controlled_player.global_position.y <= center_y
		else minimum_y
	)
	var center_weight = clampf(
		anticipatory_defense_center_weight,
		0.0,
		1.0
	)
	var corner_weight = clampf(
		anticipatory_defense_open_corner_weight,
		0.0,
		1.0
	)
	if now < _defense_fake_guard_until:
		center_weight += 0.34
		corner_weight *= 0.55
	var total_weight = maxf(0.001, aim_trust + center_weight + corner_weight)
	var predicted_y = (
		ray_y * aim_trust
		+ center_y * center_weight
		+ open_corner_y * corner_weight
	) / total_weight
	predicted_y = clampf(predicted_y, minimum_y, maximum_y)

	var route_read = _get_pre_shot_route_read(
		carrier,
		own_goal,
		charge_ratio,
		aim_stable_seconds,
		orbiting_ball
	)
	if not route_read.is_empty():
		var route_confidence = float(
			route_read.get("route_confidence", 0.0)
		)
		var route_target: Vector2 = route_read.get(
			"route_target",
			Vector2.ZERO
		)
		if not route_target.is_zero_approx():
			var route_weight = clampf(
				float(route_read.get("route_risk", 0.0))
				* pre_shot_reader_route_blend,
				0.0,
				1.0
			)
			predicted_y = lerpf(
				predicted_y,
				clampf(route_target.y, minimum_y, maximum_y),
				route_weight
			)

	var result = {
		"target": Vector2(goal_x, predicted_y),
		"charge_ratio": charge_ratio,
		"orbiting": orbiting_ball,
		"fake_guard": now < _defense_fake_guard_until,
		"route_confidence": 0.0,
		"route_threat": 0.0,
		"route_risk": 0.0,
		"route_type": &"none",
		"route_intercept": Vector2.ZERO,
		"route_goal_position": Vector2.ZERO,
		"route_ball_arrival": INF,
		"route_own_arrival": INF,
		"route_emergency": false
	}
	for key_variant in route_read.keys():
		result[key_variant] = route_read[key_variant]
	result["target"] = Vector2(goal_x, predicted_y)
	return result


func _get_pre_shot_route_read(
	carrier: FootballPlayer,
	own_goal: FootballGoal,
	charge_ratio: float,
	aim_stable_seconds: float,
	orbiting_ball: bool
) -> Dictionary:
	if (
		not pre_shot_reader_enabled
		or not is_instance_valid(carrier)
		or own_goal == null
		or ball == null
	):
		return {}
	var contact_distance = carrier.global_position.distance_to(
		ball.global_position
	)
	var maximum_contact_distance = maxf(
		180.0,
		carrier.kick_feedback_detection_distance * 1.22
	)
	if contact_distance > maximum_contact_distance:
		return {}
	var base_direction = carrier.global_position.direction_to(
		ball.global_position
	)
	if base_direction.is_zero_approx():
		return {}

	var now = _server_time_seconds()
	if _defense_contact_carrier_peer_id != carrier.owner_peer_id:
		_defense_contact_carrier_peer_id = carrier.owner_peer_id
		_defense_last_contact_direction = base_direction
		_defense_contact_direction_changed_at = now
	else:
		var direction_change = absf(
			_defense_last_contact_direction.angle_to(base_direction)
		)
		if direction_change >= deg_to_rad(2.5):
			_defense_contact_direction_changed_at = now
		_defense_last_contact_direction = base_direction
	var contact_stable_seconds = maxf(
		0.0,
		now - _defense_contact_direction_changed_at
	)
	var contact_factor = clampf(
		1.0 - contact_distance / maximum_contact_distance,
		0.0,
		1.0
	)
	var stability_factor = clampf(
		maxf(contact_stable_seconds, aim_stable_seconds) / 0.24,
		0.0,
		1.0
	)
	var setup_confidence = (
		0.30
		+ contact_factor * 0.27
		+ stability_factor * 0.23
	)
	if carrier.server_is_charging:
		setup_confidence += 0.12 + charge_ratio * 0.18
	else:
		setup_confidence += 0.05
	if orbiting_ball and charge_ratio < 0.38:
		setup_confidence *= 0.72
	if now < _defense_fake_guard_until and charge_ratio < 0.38:
		setup_confidence *= 0.42
	setup_confidence = clampf(setup_confidence, 0.0, 1.0)

	var direction_hypotheses: Array[Dictionary] = []
	_append_shot_direction_hypothesis(
		direction_hypotheses,
		base_direction,
		1.0,
		&"contact"
	)
	var release_lead = maxf(0.0, pre_shot_reader_release_lead_seconds)
	if carrier.server_is_charging:
		release_lead *= lerpf(0.72, 1.28, charge_ratio)
	var future_carrier = (
		carrier.global_position + carrier.linear_velocity * release_lead
	)
	var future_ball = (
		ball.global_position + ball.linear_velocity * release_lead * 0.35
	)
	var future_direction = future_carrier.direction_to(future_ball)
	_append_shot_direction_hypothesis(
		direction_hypotheses,
		future_direction,
		0.86,
		&"release_lead"
	)
	var uncertainty = deg_to_rad(
		maxf(0.0, pre_shot_reader_angle_uncertainty_degrees)
	)
	if uncertainty > 0.001:
		_append_shot_direction_hypothesis(
			direction_hypotheses,
			base_direction.rotated(-uncertainty),
			0.58,
			&"left_edge"
		)
		_append_shot_direction_hypothesis(
			direction_hypotheses,
			base_direction.rotated(uncertainty),
			0.58,
			&"right_edge"
		)

	var force_hypotheses = _build_opponent_shot_force_hypotheses(
		carrier,
		charge_ratio
	)
	var best_read: Dictionary = {}
	var best_score = -INF
	for direction_data in direction_hypotheses:
		var direction: Vector2 = direction_data.get(
			"direction",
			Vector2.ZERO
		)
		if direction.is_zero_approx():
			continue
		var direction_weight = float(
			direction_data.get("weight", 0.0)
		)
		for force_data in force_hypotheses:
			var force = float(force_data.get("force", 0.0))
			var force_weight = float(force_data.get("weight", 0.0))
			var ball_mass = maxf(0.01, ball.mass)
			var initial_velocity = (
				ball.linear_velocity + direction * (force / ball_mass)
			)
			initial_velocity = initial_velocity.limit_length(
				maxf(1.0, ball.maximum_speed)
			)
			var route = _simulate_pre_shot_route(
				initial_velocity,
				carrier,
				own_goal
			)
			if route.is_empty():
				continue
			var route_confidence = clampf(
				setup_confidence * direction_weight * force_weight,
				0.0,
				1.0
			)
			var route_threat = float(route.get("route_threat", 0.0))
			var route_risk = route_confidence * route_threat
			var score = route_risk
			if bool(route.get("route_scores_goal", false)):
				score += 0.08
			if score <= best_score:
				continue
			best_score = score
			best_read = route.duplicate(true)
			best_read["route_confidence"] = route_confidence
			best_read["route_risk"] = route_risk
			best_read["route_force_kind"] = force_data.get(
				"kind",
				&"unknown"
			)
			best_read["route_direction_kind"] = direction_data.get(
				"kind",
				&"unknown"
			)
	if best_read.is_empty():
		return {}
	var risk = float(best_read.get("route_risk", 0.0))
	if risk < pre_shot_reader_minimum_confidence * 0.55:
		return {}
	best_read["route_emergency"] = (
		risk >= pre_shot_reader_emergency_risk
	)
	return best_read


func _build_opponent_shot_force_hypotheses(
	carrier: FootballPlayer,
	charge_ratio: float
) -> Array[Dictionary]:
	var hypotheses: Array[Dictionary] = []
	var minimum_force = maxf(0.0, carrier.minimum_shot_force)
	var maximum_force = maxf(minimum_force, carrier.maximum_shot_force)
	if carrier.server_is_charging:
		var current_force = lerpf(
			minimum_force,
			maximum_force,
			clampf(charge_ratio, 0.0, 1.0)
		)
		_append_shot_force_hypothesis(
			hypotheses,
			current_force,
			1.0,
			&"charged"
		)
		_append_shot_force_hypothesis(
			hypotheses,
			maximum_force,
			lerpf(0.42, 0.78, charge_ratio),
			&"full_charge"
		)
	else:
		_append_shot_force_hypothesis(
			hypotheses,
			minimum_force,
			0.74,
			&"quick_shot"
		)
		_append_shot_force_hypothesis(
			hypotheses,
			carrier.soft_pass_force,
			0.62,
			&"soft_pass"
		)
		_append_shot_force_hypothesis(
			hypotheses,
			lerpf(minimum_force, maximum_force, 0.55),
			0.42,
			&"sudden_release"
		)

	var power_selected = (
		carrier.selected_ability == FootballPlayer.ABILITY_POWER_STRIKE
	)
	var power_active = (
		carrier.server_ability_active
		and carrier.server_active_ability_id
		== FootballPlayer.ABILITY_POWER_STRIKE
	)
	var power_ready = (
		power_selected
		and carrier.server_ability_cooldown_ends_at
		<= _server_time_seconds()
	)
	if power_active or power_ready:
		var power_multiplier = clampf(
			carrier.power_strike_force_multiplier,
			1.0,
			2.4
		)
		var power_weight = 1.0 if power_active else 0.52
		if carrier.server_is_charging and not power_active:
			power_weight = lerpf(0.58, 0.82, charge_ratio)
		_append_shot_force_hypothesis(
			hypotheses,
			maximum_force * power_multiplier,
			power_weight,
			&"power_strike"
		)
	return hypotheses


func _append_shot_force_hypothesis(
	hypotheses: Array[Dictionary],
	force: float,
	weight: float,
	kind: StringName
) -> void:
	var safe_force = maxf(0.0, force)
	if safe_force <= 0.0 or weight <= 0.0:
		return
	for index in range(hypotheses.size()):
		var existing: Dictionary = hypotheses[index]
		if absf(float(existing.get("force", 0.0)) - safe_force) > 90.0:
			continue
		if weight > float(existing.get("weight", 0.0)):
			existing["weight"] = weight
			existing["kind"] = kind
			hypotheses[index] = existing
		return
	hypotheses.append({
		"force": safe_force,
		"weight": clampf(weight, 0.0, 1.0),
		"kind": kind
	})


func _append_shot_direction_hypothesis(
	hypotheses: Array[Dictionary],
	direction: Vector2,
	weight: float,
	kind: StringName
) -> void:
	var safe_direction = direction.normalized()
	if safe_direction.is_zero_approx() or weight <= 0.0:
		return
	for index in range(hypotheses.size()):
		var existing: Dictionary = hypotheses[index]
		var existing_direction: Vector2 = existing.get(
			"direction",
			Vector2.ZERO
		)
		if (
			not existing_direction.is_zero_approx()
			and absf(existing_direction.angle_to(safe_direction)) < 0.025
		):
			if weight > float(existing.get("weight", 0.0)):
				existing["weight"] = weight
				existing["kind"] = kind
				hypotheses[index] = existing
			return
	hypotheses.append({
		"direction": safe_direction,
		"weight": clampf(weight, 0.0, 1.0),
		"kind": kind
	})


func _simulate_pre_shot_route(
	initial_velocity: Vector2,
	carrier: FootballPlayer,
	own_goal: FootballGoal
) -> Dictionary:
	if initial_velocity.length() < maxf(
		120.0,
		pre_shot_reader_minimum_route_speed
	):
		return {}
	var position = ball.global_position
	var velocity = initial_velocity
	var elapsed = 0.0
	var bounce_count = 0
	var route_points: Array[Vector2] = [position]
	var route_times: Array[float] = [0.0]
	var wall_bounds = _get_double_bank_wall_bounds()
	var top_wall = wall_bounds.x
	var bottom_wall = wall_bounds.y
	var goal_x = own_goal.get_goal_plane_x()
	var mouth_range = own_goal.get_mouth_y_range()
	var radius = maxf(
		_get_double_bank_collision_radius(),
		maxf(0.0, ball.arena_ball_radius)
	)
	var gate_x = (
		goal_x
		+ _get_attack_sign()
		* maxf(280.0, pre_shot_reader_self_pass_gate_depth)
	)
	var gate_crossing: Dictionary = {}
	var restitution = _get_double_bank_wall_restitution()
	for _bounce_iteration in range(
		maxi(1, pre_shot_reader_maximum_bounces) + 1
	):
		var direction = velocity.normalized()
		if direction.is_zero_approx():
			break
		var goal_distance = INF
		if absf(direction.x) > 0.001:
			var possible_goal_distance = (goal_x - position.x) / direction.x
			if possible_goal_distance > 0.5:
				goal_distance = possible_goal_distance
		var wall_distance = INF
		if direction.y < -0.001:
			var possible_top_distance = (top_wall - position.y) / direction.y
			if possible_top_distance > 0.5:
				wall_distance = possible_top_distance
		elif direction.y > 0.001:
			var possible_bottom_distance = (
				(bottom_wall - position.y) / direction.y
			)
			if possible_bottom_distance > 0.5:
				wall_distance = possible_bottom_distance
		var next_distance = minf(goal_distance, wall_distance)
		if next_distance >= INF * 0.5:
			break
		var segment_result = _simulate_double_bank_segment(
			velocity,
			next_distance
		)
		if segment_result.is_empty():
			break
		var segment_time = float(segment_result.get("time", 0.0))
		var end_position = position + direction * next_distance
		if (
			gate_crossing.is_empty()
			and absf(end_position.x - position.x) > 0.001
			and (position.x - gate_x) * (end_position.x - gate_x) <= 0.0
		):
			var gate_ratio = clampf(
				(gate_x - position.x) / (end_position.x - position.x),
				0.0,
				1.0
			)
			gate_crossing = {
				"position": position.lerp(end_position, gate_ratio),
				"time": elapsed + segment_time * gate_ratio,
				"bounce_count": bounce_count,
				"speed": velocity.length()
			}
		velocity = segment_result.get("velocity", Vector2.ZERO)
		elapsed += segment_time
		route_points.append(end_position)
		route_times.append(elapsed)
		if goal_distance <= wall_distance:
			var inside_mouth = (
				end_position.y >= mouth_range.x + radius
				and end_position.y <= mouth_range.y - radius
			)
			if inside_mouth:
				var intercept = _select_pre_shot_route_intercept(
					route_points,
					route_times,
					bounce_count > 0
				)
				var remaining_speed = velocity.length()
				var speed_factor = clampf(
					remaining_speed / 5200.0,
					0.0,
					1.0
				)
				var time_factor = 1.0 - clampf(elapsed / 2.4, 0.0, 1.0)
				var threat = clampf(
					0.58
					+ speed_factor * 0.24
					+ time_factor * 0.20
					+ minf(0.08, float(bounce_count) * 0.035),
					0.0,
					1.0
				)
				return {
					"route_type": (
						&"direct_goal"
						if bounce_count == 0
						else &"wall_goal"
					),
					"route_target": end_position,
					"route_goal_position": end_position,
					"route_intercept": intercept.get(
						"position",
						end_position
					),
					"route_ball_arrival": float(
						intercept.get("ball_arrival", elapsed)
					),
					"route_own_arrival": float(
						intercept.get("own_arrival", INF)
					),
					"route_threat": threat,
					"route_scores_goal": true,
					"route_bounces": bounce_count,
					"route_remaining_speed": remaining_speed
				}
			return _evaluate_pre_shot_breakthrough(
				gate_crossing,
				carrier,
				bounce_count
			)
		position = end_position
		velocity.y = -velocity.y * restitution
		bounce_count += 1
		if velocity.length() < pre_shot_reader_minimum_route_speed:
			break
	return _evaluate_pre_shot_breakthrough(
		gate_crossing,
		carrier,
		bounce_count
	)


func _select_pre_shot_route_intercept(
	route_points: Array[Vector2],
	route_times: Array[float],
	prefer_post_bounce: bool
) -> Dictionary:
	if route_points.size() < 2 or route_times.size() != route_points.size():
		return {}
	var best: Dictionary = {}
	var best_score = INF
	for segment_index in range(route_points.size() - 1):
		if prefer_post_bounce and segment_index == 0:
			continue
		var start: Vector2 = route_points[segment_index]
		var finish: Vector2 = route_points[segment_index + 1]
		var start_time: float = route_times[segment_index]
		var finish_time: float = route_times[segment_index + 1]
		for sample_index in range(1, 6):
			var ratio = float(sample_index) / 5.0
			var candidate = start.lerp(finish, ratio)
			if candidate.distance_to(ball.global_position) < 260.0:
				continue
			var ball_arrival = lerpf(start_time, finish_time, ratio)
			var own_arrival = _estimate_duel_player_arrival_seconds(
				controlled_player,
				candidate
			)
			var arrival_margin = own_arrival - ball_arrival
			if arrival_margin > 0.14:
				continue
			var score = ball_arrival + maxf(0.0, arrival_margin) * 1.8
			if score < best_score:
				best_score = score
				best = {
					"position": candidate,
					"ball_arrival": ball_arrival,
					"own_arrival": own_arrival
				}
	if not best.is_empty():
		return best
	var fallback_position: Vector2 = route_points[-1]
	return {
		"position": fallback_position,
		"ball_arrival": route_times[-1],
		"own_arrival": _estimate_duel_player_arrival_seconds(
			controlled_player,
			fallback_position
		)
	}


func _evaluate_pre_shot_breakthrough(
	gate_crossing: Dictionary,
	carrier: FootballPlayer,
	bounce_count: int
) -> Dictionary:
	if gate_crossing.is_empty():
		return {}
	var crossing: Vector2 = gate_crossing.get(
		"position",
		Vector2.ZERO
	)
	if crossing.is_zero_approx():
		return {}
	var ball_arrival = float(gate_crossing.get("time", INF))
	var own_arrival = _estimate_duel_player_arrival_seconds(
		controlled_player,
		crossing
	)
	var attacker_arrival = _estimate_duel_player_arrival_seconds(
		carrier,
		crossing
	)
	var attacker_control_time = maxf(ball_arrival, attacker_arrival)
	var defender_delay = own_arrival - attacker_control_time
	var lateral_gap = absf(
		crossing.y - controlled_player.global_position.y
	)
	var is_wall_play = bounce_count > 0 or int(
		gate_crossing.get("bounce_count", 0)
	) > 0
	var minimum_lateral_gap = maxf(
		120.0,
		pre_shot_reader_self_pass_lateral_margin
	)
	if (
		lateral_gap < minimum_lateral_gap
		and defender_delay <= 0.08
	):
		return {}
	var speed_factor = clampf(
		float(gate_crossing.get("speed", 0.0)) / 4600.0,
		0.0,
		1.0
	)
	var delay_factor = clampf((defender_delay + 0.10) / 0.75, 0.0, 1.0)
	var lateral_factor = clampf(
		lateral_gap / maxf(1.0, minimum_lateral_gap * 2.4),
		0.0,
		1.0
	)
	var threat = clampf(
		0.34
		+ delay_factor * 0.34
		+ lateral_factor * 0.20
		+ speed_factor * 0.12
		+ (0.08 if is_wall_play else 0.0),
		0.0,
		0.92
	)
	return {
		"route_type": &"wall_self_pass" if is_wall_play else &"through_ball",
		"route_target": crossing,
		"route_goal_position": Vector2.ZERO,
		"route_intercept": crossing,
		"route_ball_arrival": ball_arrival,
		"route_own_arrival": own_arrival,
		"route_threat": threat,
		"route_scores_goal": false,
		"route_bounces": bounce_count,
		"route_attacker_arrival": attacker_arrival
	}


func _get_ray_y_at_x(
	origin: Vector2,
	direction: Vector2,
	target_x: float,
	fallback_y: float
) -> float:
	if absf(direction.x) < 0.001:
		return fallback_y
	var travel = (target_x - origin.x) / direction.x
	if travel <= 0.0:
		return fallback_y
	return origin.y + direction.y * travel


func _get_line_y_at_x(
	start: Vector2,
	end: Vector2,
	target_x: float,
	fallback_y: float
) -> float:
	var delta = end - start
	if absf(delta.x) < 0.001:
		return fallback_y
	var ratio = (target_x - start.x) / delta.x
	return lerpf(start.y, end.y, ratio)


func _clear_defensive_shot_read() -> void:
	_defense_read_carrier_peer_id = 0
	_defense_last_read_y = 0.0
	_defense_last_read_at = -INF
	_defense_last_aim_change_at = -INF
	_defense_fake_guard_until = 0.0
	_defense_contact_carrier_peer_id = 0
	_defense_last_contact_direction = Vector2.ZERO
	_defense_contact_direction_changed_at = -INF


func _get_primary_defensive_press_position(
	own_goal: FootballGoal
) -> Vector2:
	if own_goal == null:
		return _get_predicted_ball_position()
	var threat = _predict_own_goal_threat(2.6)
	if not threat.is_empty():
		# When a shot is already goal-bound, protect the crossing line instead of
		# chasing a ball the presser cannot physically reach.
		var threat_position: Vector2 = threat.get(
			"position",
			ball.global_position
		)
		return _clamp_to_field(Vector2(
		own_goal.get_goal_plane_x() + _get_attack_sign() * 185.0,
		threat_position.y
	))
	var carrier = _get_likely_opponent_ball_carrier()
	if carrier != null:
		var goal_center = _get_goal_center(own_goal)
		var goal_side_standoff = minf(
			carrier.global_position.distance_to(goal_center) * 0.32,
			lerpf(310.0, 150.0, _get_ai_skill())
		)
		return _clamp_to_field(
			carrier.global_position
			+ carrier.global_position.direction_to(goal_center)
			* goal_side_standoff
		)
	var interception_target = _get_predicted_ball_position()
	if _can_achieve_defensive_interception(interception_target):
		return interception_target
	return _get_defensive_lane_cover_position(own_goal)


func _can_achieve_defensive_interception(target: Vector2) -> bool:
	var ball_speed = ball.linear_velocity.length()
	if ball_speed < 260.0:
		return true
	var ball_to_target = ball.global_position.direction_to(target)
	if ball_to_target.is_zero_approx():
		return true
	if ball.linear_velocity.normalized().dot(ball_to_target) < 0.2:
		return false
	var ball_arrival = ball.global_position.distance_to(target) / ball_speed
	var estimated_player_speed = maxf(
		900.0,
		controlled_player.max_speed * lerpf(0.42, 0.68, _get_ai_skill())
	)
	var player_arrival = controlled_player.global_position.distance_to(
		target
	) / estimated_player_speed
	return player_arrival <= ball_arrival + 0.18


func _try_defensive_ball_win() -> void:
	if match_manager == null or ball == null:
		return
	var assignment = match_manager.get_cpu_defensive_assignment(
		controlled_player.team,
		controlled_player.owner_peer_id
	)
	var role = StringName(assignment.get("role", &""))
	if role not in [&"press", &"cover", &"final"]:
		return
	var contact_distance = controlled_player.kick_feedback_detection_distance
	if controlled_player.global_position.distance_to(ball.global_position) > contact_distance:
		return
	var carrier = _get_likely_opponent_ball_carrier()
	if carrier != null and carrier.global_position.distance_to(ball.global_position) < contact_distance * 0.9:
		var carrier_to_ball = carrier.global_position.direction_to(ball.global_position)
		var carrier_to_defender = carrier.global_position.direction_to(controlled_player.global_position)
		if (
			not carrier_to_ball.is_zero_approx()
			and not carrier_to_defender.is_zero_approx()
			and carrier_to_ball.dot(carrier_to_defender) < -0.08
		):
			# The defender is trailing behind the carrier. Keep the goal-side / side
			# approach and do not repeatedly kick through the player's body.
			match_manager.record_cpu_defense_event(
				controlled_player.team,
				&"contact_without_ball_win"
			)
			return
	var now = _server_time_seconds()
	if now < _next_emergency_clear_touch_at:
		return
	var clearance_direction = ball.global_position.direction_to(
		_get_safe_own_goal_clearance_target()
	)
	if clearance_direction.is_zero_approx():
		return
	if controlled_player.cpu_dribble_touch(
		clearance_direction,
		defensive_ball_win_clear_force
	):
		_next_emergency_clear_touch_at = now + maxf(
			0.12,
			defensive_ball_win_retry_seconds
		)
		match_manager.record_cpu_defense_event(controlled_player.team, &"ball_recoveries")
		match_manager.record_cpu_defense_event(controlled_player.team, &"successful_containment")
	else:
		match_manager.record_cpu_defense_event(
			controlled_player.team,
			&"contact_without_ball_win"
		)


func _get_defensive_lane_cover_position(
	own_goal: FootballGoal
) -> Vector2:
	var cover_target = _get_defensive_cover_target(own_goal)
	var carrier = _get_likely_opponent_ball_carrier()
	if carrier == null:
		return cover_target
	var goal_center = _get_goal_center(own_goal)
	var lane_target = carrier.global_position.lerp(goal_center, 0.46)
	# A cover defender protects the carrier-to-goal lane first, not the carrier
	# itself. This leaves the committed presser free to challenge.
	return _clamp_to_field(cover_target.lerp(lane_target, 0.62))


func _get_goal_side_mark_position(
	mark: FootballPlayer,
	own_goal: FootballGoal
) -> Vector2:
	var toward_goal = mark.global_position.direction_to(
		_get_goal_center(own_goal)
	)
	var mark_position = mark.global_position + toward_goal * (
		_get_ability_aware_marking_distance(mark)
	)
	mark_position.y = lerpf(
		mark_position.y,
		ball.global_position.y,
		clampf(defensive_block_ball_blend, 0.0, 1.0) * 0.35
	)
	mark_position = _clamp_to_field(mark_position)
	_set_tactical_intent(INTENT_MARK, mark_position, mark.owner_peer_id)
	return mark_position


func _get_opponent_by_peer_id(peer_id: int) -> FootballPlayer:
	if peer_id <= 0:
		return null
	if (
		is_instance_valid(match_manager)
		and match_manager.has_method("get_cpu_shared_player")
	):
		var shared_player: FootballPlayer = match_manager.get_cpu_shared_player(peer_id) as FootballPlayer
		if (
			is_instance_valid(shared_player)
			and shared_player.controls_enabled
			and shared_player.team != controlled_player.team
		):
			return shared_player
		return null
	for opponent in _get_opponents():
		if (
			is_instance_valid(opponent)
			and opponent.controls_enabled
			and opponent.owner_peer_id == peer_id
		):
			return opponent
	return null


func _get_elite_counterpress_position(own_goal: FootballGoal) -> Vector2:
	if (
		_get_ai_skill() < elite_combination_minimum_skill
		or _team_likely_has_possession()
		or _ball_is_in_own_goal_danger()
		or ball.global_position.distance_to(_get_goal_center(own_goal))
		> elite_counterpress_radius * 2.4
	):
		return Vector2.ZERO
	var carrier = _get_likely_opponent_ball_carrier()
	if carrier == null:
		return Vector2.ZERO
	var committed_chaser = match_manager.get_cpu_ball_chaser(
		controlled_player.team
	)
	if controlled_player.owner_peer_id == committed_chaser:
		return Vector2.ZERO
	var pressing_support = _get_elite_counterpress_support_player(carrier)
	if pressing_support != controlled_player:
		return Vector2.ZERO
	var nearest_distance = controlled_player.global_position.distance_to(
		carrier.global_position
	)
	if nearest_distance > elite_counterpress_radius:
		return Vector2.ZERO

	var outlet: FootballPlayer
	var outlet_score = -INF
	var opponent_attack_sign = -_get_attack_sign()
	for opponent in _get_opponents():
		if (
			not is_instance_valid(opponent)
			or opponent == carrier
			or not opponent.controls_enabled
		):
			continue
		var predicted_outlet = opponent.global_position + opponent.linear_velocity * 0.3
		var pass_distance = carrier.global_position.distance_to(predicted_outlet)
		if pass_distance < 380.0 or pass_distance > maximum_pass_distance:
			continue
		var threat_progress = (
			predicted_outlet.x - carrier.global_position.x
		) * opponent_attack_sign
		var score = (
			threat_progress * 0.45
			+ _nearest_team_distance_to_position(
				_get_teammates(),
				predicted_outlet
			) * 0.25
			- pass_distance * 0.08
		)
		if score > outlet_score:
			outlet_score = score
			outlet = opponent
	if outlet != null:
		var outlet_target = outlet.global_position + outlet.linear_velocity * 0.3
		return _clamp_to_field(
			carrier.global_position.lerp(
				outlet_target,
				clampf(elite_counterpress_lane_blend, 0.2, 0.68)
			)
		)
	var toward_goal = carrier.global_position.direction_to(_get_goal_center(own_goal))
	return _clamp_to_field(carrier.global_position + toward_goal * 340.0)


func _get_elite_counterpress_support_player(
	carrier: FootballPlayer
) -> FootballPlayer:
	if not is_instance_valid(carrier):
		return null
	var committed_chaser = match_manager.get_cpu_ball_chaser(
		controlled_player.team
	)
	var pressing_support: FootballPlayer
	var nearest_distance = INF
	for teammate in _get_teammates():
		if (
			not is_instance_valid(teammate)
			or not teammate.controls_enabled
			or _is_designated_goalkeeper(teammate)
			or teammate.owner_peer_id == committed_chaser
		):
			continue
		var distance = teammate.global_position.distance_to(
			carrier.global_position
		)
		if (
			distance < nearest_distance
			or (
				is_equal_approx(distance, nearest_distance)
				and pressing_support != null
				and teammate.owner_peer_id < pressing_support.owner_peer_id
			)
		):
			nearest_distance = distance
			pressing_support = teammate
	return pressing_support


func _get_defensive_cover_target(own_goal: FootballGoal) -> Vector2:
	var own_goal_center = _get_goal_center(own_goal)
	var toward_goal = ball.global_position.direction_to(own_goal_center)
	var cover_distance = maxf(200.0, defensive_cover_distance)
	var opponent_carrier = _get_likely_opponent_ball_carrier()
	if opponent_carrier != null:
		var carrier_threat = _get_player_ability_threat(opponent_carrier)
		cover_distance += clampf(carrier_threat * 0.32, 0.0, 420.0)
	var cover_target = (
		ball.global_position
		+ toward_goal * cover_distance
	)
	cover_target.y = lerpf(
		own_goal_center.y,
		cover_target.y,
		clampf(defensive_cover_lateral_blend, 0.0, 1.0)
	)
	return _clamp_to_field(cover_target)


func _get_temporary_cover_player(target: Vector2) -> FootballPlayer:
	var committed_chaser = match_manager.get_cpu_ball_chaser(
		controlled_player.team
	)
	var pressing_support: FootballPlayer
	if (
		_get_ai_skill() >= elite_combination_minimum_skill
		and not _team_likely_has_possession()
	):
		pressing_support = _get_elite_counterpress_support_player(
			_get_likely_opponent_ball_carrier()
		)
	var closest_player: FootballPlayer
	var declared_cover = _get_declared_intent_player(INTENT_COVER, null)
	if (
		declared_cover != null
		and declared_cover.owner_peer_id != committed_chaser
		and declared_cover != pressing_support
	):
		return declared_cover
	var closest_distance = INF
	for teammate in _get_teammates():
		if (
			not is_instance_valid(teammate)
			or not teammate.controls_enabled
			or _is_designated_goalkeeper(teammate)
			or teammate.owner_peer_id == committed_chaser
			or teammate == pressing_support
		):
			continue
		var distance = teammate.global_position.distance_squared_to(target)
		if (
			distance < closest_distance
			or (
				is_equal_approx(distance, closest_distance)
				and closest_player != null
				and teammate.owner_peer_id < closest_player.owner_peer_id
			)
		):
			closest_distance = distance
			closest_player = teammate
	return closest_player


func _get_declared_intent_player(
	action: StringName,
	excluded_player: FootballPlayer
) -> FootballPlayer:
	for teammate in _get_teammates():
		if (
			not is_instance_valid(teammate)
			or teammate == excluded_player
			or not teammate.controls_enabled
		):
			continue
		var intention = _get_effective_player_intention(teammate)
		if StringName(intention.get("action", &"")) == action:
			return teammate
	return null


func _get_lane_y(slot: int) -> float:
	match slot:
		1:
			return 1500.0
		2:
			return 3500.0
		_:
			return 2500.0


func _activate_planned_ball_ability() -> bool:
	if controlled_player.global_position.distance_to(
		ball.global_position
	) > controlled_player.kick_feedback_detection_distance:
		# A committed Trap-or-Volley pair must not leave a stale receiver intention
		# behind when the passer loses its contact before it can activate.
		if not _get_trap_or_volley_combo_plan().is_empty():
			_cancel_trap_or_volley_combo_plan()
		if not _get_overdrive_dead_zone_plan().is_empty():
			_cancel_overdrive_dead_zone_plan()
		return false
	match controlled_player.selected_ability:
		FootballPlayer.ABILITY_BREAKAWAY:
			if _breakaway_is_useful():
				return _request_planned_selected_ability()
		FootballPlayer.ABILITY_SNAPBACK:
			if _snapback_is_useful():
				return _request_planned_selected_ability()
		FootballPlayer.ABILITY_RETURN_TAG:
			if _return_tag_is_useful():
				return _request_planned_selected_ability()
		FootballPlayer.ABILITY_SIDE_SWIPE:
			if _side_swipe_is_useful():
				return _request_planned_selected_ability()
		FootballPlayer.ABILITY_NUTMEG:
			if _nutmeg_is_useful():
				return _request_planned_selected_ability()
		FootballPlayer.ABILITY_DECOY_RUN:
			if _decoy_run_is_useful():
				return _request_planned_selected_ability()
		FootballPlayer.ABILITY_TIME_SKIP_PASS:
			# Dead Zone Pass is never a substitute for a mid-range goal shot.
			# It may only fire on a physically reachable teammate route, or on the
			# deliberate defender-splitting self-pass selected by
			# _dead_zone_pass_is_useful().
			if (
				_plan_is_pass
				and not _plan_uses_wall
				and is_instance_valid(_planned_receiver)
				and _planned_receiver.team == controlled_player.team
				and _planned_receiver.controls_enabled
			):
				var dead_zone_combo = _get_dead_zone_trap_volley_plan()
				var overdrive_combo = _get_overdrive_dead_zone_plan()
				var active_combo = (
					overdrive_combo
					if not overdrive_combo.is_empty()
					else dead_zone_combo
				)
				if (
					not active_combo.is_empty()
					and _get_attacking_reception_delivery(active_combo)
					!= &"dead_zone"
				):
					return false
				if not active_combo.is_empty() and not _cpu_ability_is_ready():
					return false
				if not active_combo.is_empty() and not overdrive_combo.is_empty():
					var runner = _get_teammate_by_peer_id(
						int(overdrive_combo.get("receiver_peer_id", 0))
					)
					if (
						runner == null
						or not runner._server_ability_is_active(
							FootballPlayer.ABILITY_OVERDRIVE
						)
					):
						return false
				var route_distance: float = ball.global_position.distance_to(
					_planned_destination
				)
				var maximum_route: float = maxf(
					300.0,
					controlled_player.time_skip_pass_maximum_receiver_distance
				)
				if (
					_planned_destination.is_zero_approx()
					or route_distance > maximum_route * 0.98
					or not _is_pass_lane_safe(_planned_destination)
				):
					# The enhanced ball physically cannot reach this route safely.
					# Keep the ordinary pass plan instead of burning Dead Zone.
					return false
				if active_combo.is_empty() and not _dead_zone_pass_is_useful():
					return false
				var pass_direction: Vector2 = ball.global_position.direction_to(
					_planned_destination
				)
				if pass_direction.is_zero_approx():
					return false
				controlled_player.server_direction = pass_direction
				# Always preserve the exact evaluated receiver/lead point. Previously only
				# combo routes were pinned, so a normal Dead Zone decision could retarget.
				controlled_player.cpu_set_time_skip_pass_route(
					_planned_receiver.owner_peer_id,
					_planned_destination
				)
				var activated: bool = _request_planned_selected_ability()
				if not activated and not active_combo.is_empty():
					if not overdrive_combo.is_empty():
						_cancel_overdrive_dead_zone_plan()
					else:
						_cancel_dead_zone_trap_volley_plan()
				return activated
			if not _plan_is_pass and not _plan_uses_wall:
				if _dead_zone_goal_shot_is_useful():
					var goal_target := _shot_target
					if goal_target.is_zero_approx():
						goal_target = _planned_destination
					controlled_player.server_direction = (
						ball.global_position.direction_to(goal_target)
					)
					# receiver_peer_id == 0 pins an explicit goal route so the ability
					# cannot auto-retarget to a nearby teammate at activation time.
					controlled_player.cpu_set_time_skip_pass_route(0, goal_target)
					return _request_planned_selected_ability()
				if not _dead_zone_pass_is_useful():
					return false
				controlled_player.cpu_clear_time_skip_pass_route()
				controlled_player.server_direction = ball.global_position.direction_to(
					_planned_destination
				)
				return _request_planned_selected_ability()
		FootballPlayer.ABILITY_HEEL_TURN:
			if _heel_turn_is_useful():
				return _request_planned_selected_ability()
		FootballPlayer.ABILITY_IRON_ANCHOR:
			if ball.linear_velocity.length() > 520.0:
				return _request_planned_selected_ability()
		FootballPlayer.ABILITY_POWER_STRIKE:
			var power_combo = _get_power_strike_trap_volley_plan()
			if _cpu_ability_is_ready():
				match_manager.record_cpu_defense_event(
					controlled_player.team,
					&"power_strike_opportunities"
				)
			if (
				not power_combo.is_empty()
				and _get_attacking_reception_delivery(power_combo)
				!= &"power_strike"
			):
				controlled_player.server_direction = ball.global_position.direction_to(
					_shot_target
				)
				return false
			if not power_combo.is_empty() and not _cpu_ability_is_ready():
				controlled_player.server_direction = ball.global_position.direction_to(
					_shot_target
				)
				return false
			if (
				_is_power_strike_distribution_plan()
				and _cpu_ability_is_ready()
			):
				controlled_player.server_direction = (
					ball.global_position.direction_to(_shot_target)
				)
				var activated = _request_planned_selected_ability()
				if activated:
					match_manager.record_cpu_defense_event(
						controlled_player.team,
						&"power_strike_combination_uses"
					)
				if (
					not activated
					and not _get_power_strike_trap_volley_plan().is_empty()
				):
					_cancel_trap_or_volley_combo_plan()
				return activated
			elif _shot_ability_is_useful(
				FootballPlayer.ABILITY_POWER_STRIKE
			):
				controlled_player.server_direction = (
					ball.global_position.direction_to(_shot_target)
				)
				var standalone_activated = _request_planned_selected_ability()
				if standalone_activated:
					match_manager.record_cpu_defense_event(
						controlled_player.team,
						&"power_strike_standalone_uses"
					)
				return standalone_activated
		FootballPlayer.ABILITY_QUICK_TRIGGER:
			if (
				_is_curve_shot_distribution_plan()
				and _cpu_ability_is_ready()
			):
				controlled_player.server_direction = (
					ball.global_position.direction_to(_shot_target)
				)
				return _request_planned_selected_ability()
			if _shot_ability_is_useful(
				FootballPlayer.ABILITY_QUICK_TRIGGER
			):
				controlled_player.server_direction = (
					ball.global_position.direction_to(_shot_target)
				)
				return _request_planned_selected_ability()
	return false


func _try_plan_priority_power_strike_shot(
	opponent_goal: FootballGoal,
	now: float
) -> bool:
	if (
		opponent_goal == null
		or controlled_player == null
		or ball == null
		or controlled_player.selected_ability
		!= FootballPlayer.ABILITY_POWER_STRIKE
		or (
			not _cpu_ability_is_ready()
			and not _has_active_ability(FootballPlayer.ABILITY_POWER_STRIKE)
		)
		or not controlled_player.cpu_has_kickable_ball()
	):
		return false
	var target := _get_best_live_direct_shot_target(opponent_goal)
	if target.is_zero_approx():
		return false
	var distance := ball.global_position.distance_to(target)
	if (
		distance < 620.0
		or distance > power_strike_activation_goal_distance * 1.08
	):
		return false
	var lane := _minimum_segment_clearance(ball.global_position, target)
	var interception_margin := _direct_shot_interception_margin(target)
	var team_size := _get_active_team_player_count()
	var second_ball_value := _get_best_team_second_ball_value(
		_get_goal_center(opponent_goal)
	)
	var minimum_lane := maxf(
		78.0,
		power_strike_minimum_safe_lane * (0.44 if team_size >= 3 else 0.58)
	)
	if second_ball_value >= 0.58:
		minimum_lane *= 0.84
	var minimum_margin := -0.48 if team_size >= 3 else -0.25
	if (
		lane < minimum_lane
		or interception_margin < minimum_margin
	):
		return false
	_clear_attack_plan()
	_plan_is_pass = false
	_planned_receiver = null
	_planned_pass_kind = &"power_strike_fast_shot"
	_plan_expires_at = now + _get_high_tempo_plan_duration(
		pass_plan_lock_seconds,
		0.08
	)
	_set_planned_route(target, true, true)
	return true


func _try_execute_priority_attack_ability_teamplay(
	opponent_goal: FootballGoal,
	now_override: float = -1.0
) -> bool:
	# Team-shaping attacking abilities deserve first refusal before generic
	# dribble/pass sequences. Previously the Power Strike / Curve distribution
	# logic lived inside the value planner, so an earlier shared-sequence choice
	# could keep an ability carrier in ordinary possession play for several
	# decisions. This is still conditional football logic: if no useful teammate
	# route exists, the normal shot/pass/dribble planner remains in control.
	if (
		opponent_goal == null
		or controlled_player == null
		or ball == null
		or controlled_player.server_is_charging
		or not controlled_player.cpu_has_kickable_ball()
		or _ball_is_in_own_goal_danger()
		or _get_active_team_player_count() <= 1
	):
		return false
	var now: float = (
		now_override if now_override >= 0.0 else _server_time_seconds()
	)
	var planned: bool = false
	match controlled_player.selected_ability:
		FootballPlayer.ABILITY_POWER_STRIKE:
			planned = _try_plan_power_strike_distribution(opponent_goal, now)
			if not planned:
				planned = _try_plan_priority_power_strike_shot(
					opponent_goal,
					now
				)
		FootballPlayer.ABILITY_QUICK_TRIGGER:
			planned = _try_plan_curve_shot_distribution(opponent_goal, now)
	if not planned:
		return false
	_movement_target = _get_strike_position(_shot_target)
	_set_tactical_intent(
		INTENT_PASS if _plan_is_pass else INTENT_SHOOT,
		_shot_target,
		_planned_receiver.owner_peer_id
		if is_instance_valid(_planned_receiver)
		else 0
	)
	# Activate and start charging on the same decision tick. The old two-step
	# sequence made attacking abilities visibly hesitate under pressure.
	_activate_planned_ball_ability()
	if (
		_has_active_ability(controlled_player.selected_ability)
		or not _cpu_ability_is_ready()
	):
		_try_begin_shot(false)
	var shot_executor_claimed := false
	if not _plan_is_pass and _tactical_intent_action == INTENT_SHOOT:
		shot_executor_claimed = _try_claim_committed_shot_executor()
	return (
		controlled_player.server_is_charging
		or _plan_is_pass
		or shot_executor_claimed
	)


func _try_execute_value_attacking_plan(
	opponent_goal: FootballGoal
) -> bool:
	if (
		not value_attacking_planner_enabled
		or _attacking_planner == null
		or opponent_goal == null
		or controlled_player == null
		or ball == null
		or controlled_player.server_is_charging
		or _ball_is_in_own_goal_danger()
	):
		return false
	var now: float = _server_time_seconds()
	if _try_execute_priority_attack_ability_teamplay(opponent_goal, now):
		return true
	var plan: Dictionary = {}
	if (
		now < _attack_value_plan_until
		and not _attack_value_debug_state.is_empty()
	):
		plan = _attack_value_debug_state.duplicate(true)
	else:
		var attacking_profile_started_usec: int = begin_runtime_subsystem_profile()
		var plan_variant: Variant = _attacking_planner.evaluate(opponent_goal)
		end_runtime_subsystem_profile(
			&"offense_candidate_evaluation",
			attacking_profile_started_usec
		)
		if plan_variant is Dictionary:
			plan = plan_variant as Dictionary
		_attack_value_debug_state = plan.duplicate(true)
		_attack_value_plan_until = now + _get_high_tempo_plan_duration(
			value_attacking_replan_seconds,
			0.035
		)
	if plan.is_empty():
		return false
	if float(plan.get("score", -INF)) < value_attacking_minimum_score:
		return false
	var action: StringName = StringName(plan.get("action", &""))
	var target: Vector2 = plan.get("target", Vector2.ZERO) as Vector2
	var destination: Vector2 = plan.get(
		"destination",
		target
	) as Vector2
	if target.is_zero_approx() and action not in [
		AttackingPlannerScript.ACTION_CARRY,
		AttackingPlannerScript.ACTION_RESET
	]:
		return false
	match action:
		AttackingPlannerScript.ACTION_PASS, AttackingPlannerScript.ACTION_ONE_TWO:
			var pass_plan_variant: Variant = plan.get("pass_plan", {})
			if not pass_plan_variant is Dictionary:
				return false
			var pass_plan: Dictionary = pass_plan_variant as Dictionary
			if not _apply_team_pass_plan(pass_plan, opponent_goal, now):
				_attack_value_plan_until = 0.0
				return false
			_movement_target = _get_strike_position(_shot_target)
			_set_tactical_intent(
				INTENT_PASS,
				_shot_target,
				int(plan.get("receiver_peer_id", 0))
			)
			_try_begin_shot(false)
			return true
		AttackingPlannerScript.ACTION_DIRECT_SHOT:
			_clear_attack_plan()
			_plan_is_pass = false
			_planned_receiver = null
			_plan_expires_at = now + 0.34
			_set_planned_route(destination, false, true)
			_movement_target = _get_strike_position(_shot_target)
			_set_tactical_intent(INTENT_SHOOT, _shot_target)
			var ability_used: bool = _activate_planned_ball_ability()
			if not ability_used:
				_try_begin_shot(false)
			return true
		AttackingPlannerScript.ACTION_WALL_SHOT:
			_clear_attack_plan()
			_plan_is_pass = false
			_planned_receiver = null
			_plan_expires_at = now + 0.42
			_planned_destination = destination
			_shot_target = target
			_planned_route_distance = float(plan.get(
				"route_distance",
				ball.global_position.distance_to(target)
				+ target.distance_to(destination)
			))
			_plan_uses_wall = true
			_plan_uses_double_bank = false
			_movement_target = _get_strike_position(_shot_target)
			_set_tactical_intent(INTENT_SHOOT, _shot_target)
			_try_begin_shot(false)
			return true
		AttackingPlannerScript.ACTION_REBOUND:
			_clear_attack_plan()
			_plan_is_pass = false
			_planned_receiver = null
			_plan_expires_at = now + 0.32
			_planned_destination = destination
			_shot_target = target
			_planned_route_distance = ball.global_position.distance_to(target)
			_plan_uses_wall = false
			_plan_uses_double_bank = false
			_movement_target = _get_strike_position(_shot_target)
			_set_tactical_intent(INTENT_SHOOT, _shot_target)
			_try_begin_shot(false)
			return true
		AttackingPlannerScript.ACTION_SELF_PASS:
			_clear_attack_plan()
			target = _skill_gate_reverse_dribble_target(target)
			var self_pass_direction: Vector2 = ball.global_position.direction_to(target)
			if self_pass_direction.is_zero_approx():
				return false
			_shot_target = target
			_movement_target = target
			_set_tactical_intent(INTENT_DRIBBLE, target)
			if now >= _next_value_attack_touch_at:
				controlled_player.cpu_dribble_touch(
					self_pass_direction,
					maxf(dribble_touch_force * 1.82, 760.0)
				)
				_next_value_attack_touch_at = now + maxf(
					0.10,
					value_attacking_touch_cooldown
				)
			_dribble_until = now + 0.72
			return true
		AttackingPlannerScript.ACTION_CARRY:
			_clear_attack_plan()
			target = _skill_gate_reverse_dribble_target(target)
			var carry_direction: Vector2 = ball.global_position.direction_to(target)
			if carry_direction.is_zero_approx():
				return false
			_shot_target = target
			_movement_target = target
			_set_tactical_intent(INTENT_DRIBBLE, target)
			if now >= _next_value_attack_touch_at:
				controlled_player.cpu_dribble_touch(
					carry_direction,
					maxf(dribble_touch_force * 0.92, 390.0)
				)
				_next_value_attack_touch_at = now + maxf(
					0.12,
					value_attacking_touch_cooldown
				)
			_dribble_until = now + 0.42
			return true
		AttackingPlannerScript.ACTION_RESET:
			var receiver_peer_id: int = int(plan.get("receiver_peer_id", 0))
			if receiver_peer_id > 0:
				var receiver: FootballPlayer = _get_teammate_by_peer_id(
					receiver_peer_id
				)
				if receiver != null:
					_clear_attack_plan()
					_plan_is_pass = true
					_planned_receiver = receiver
					_plan_expires_at = now + 0.42
					_set_planned_route(destination, false, false)
					match_manager.set_cpu_pass_intention(
						controlled_player.owner_peer_id,
						receiver.owner_peer_id,
						_planned_destination,
						pass_intention_seconds
					)
					_movement_target = _get_strike_position(_shot_target)
					_set_tactical_intent(
						INTENT_PASS,
						_shot_target,
						receiver.owner_peer_id
					)
					_try_begin_shot(false)
					return true
			target = _skill_gate_reverse_dribble_target(target)
			var reset_direction: Vector2 = ball.global_position.direction_to(target)
			if reset_direction.is_zero_approx():
				return false
			_clear_attack_plan()
			_shot_target = target
			_movement_target = target
			_set_tactical_intent(INTENT_DRIBBLE, target)
			if now >= _next_value_attack_touch_at:
				controlled_player.cpu_dribble_touch(
					reset_direction,
					maxf(dribble_touch_force * 0.72, 320.0)
				)
				_next_value_attack_touch_at = now + maxf(
					0.14,
					value_attacking_touch_cooldown
				)
			_dribble_until = now + 0.46
			return true
	return false


func _get_tactical_role(player: FootballPlayer = null) -> StringName:
	if not tactical_roles_enabled:
		return &""
	var target_player: FootballPlayer = player
	if target_player == null:
		target_player = controlled_player
	if not is_instance_valid(target_player):
		return &""
	if _is_designated_goalkeeper(target_player):
		return TACTICAL_ROLE_GOALKEEPER

	# Large matches need a real small-sided football shape rather than assigning
	# every extra outfielder through the old striker/playmaker/defender heuristic.
	# Keep the public tactical roles compatible with the existing planners while
	# deriving them from the richer defender/midfielder/winger/striker formation.
	if is_large_team_football_shape_active():
		match get_large_team_football_role(target_player):
			LARGE_TEAM_ROLE_DEFENDER:
				return TACTICAL_ROLE_DEFENDER
			LARGE_TEAM_ROLE_STRIKER:
				return TACTICAL_ROLE_STRIKER
			LARGE_TEAM_ROLE_MIDFIELDER, LARGE_TEAM_ROLE_WINGER:
				return TACTICAL_ROLE_PLAYMAKER

	var roster: Array[FootballPlayer] = []
	if is_instance_valid(controlled_player) and controlled_player.team == target_player.team:
		roster.append(controlled_player)
	for teammate in _get_teammates():
		if (
			is_instance_valid(teammate)
			and teammate.team == target_player.team
			and teammate not in roster
		):
			roster.append(teammate)

	var outfield: Array[FootballPlayer] = []
	for teammate in roster:
		if (
			is_instance_valid(teammate)
			and teammate.controls_enabled
			and not _is_designated_goalkeeper(teammate)
		):
			outfield.append(teammate)
	if target_player not in outfield:
		return TACTICAL_ROLE_PLAYMAKER
	if outfield.size() <= 1:
		return TACTICAL_ROLE_STRIKER

	# Do not assign formation roles by peer-id order. That was the reason a
	# midfielder such as Bellingham could become the deepest player while a
	# teammate with Iron Anchor stayed higher. Pick the anchor and finisher from
	# football role + equipped ability, then leave the remaining player(s) as
	# playmakers/connectors.
	var defender: FootballPlayer = null
	var defender_score: float = -INF
	for candidate in outfield:
		var score := _get_tactical_defender_score(candidate)
		if (
			score > defender_score
			or (
				is_equal_approx(score, defender_score)
				and (
					defender == null
					or candidate.owner_peer_id < defender.owner_peer_id
				)
			)
		):
			defender_score = score
			defender = candidate

	var striker: FootballPlayer = null
	var striker_score: float = -INF
	for candidate in outfield:
		if candidate == defender and outfield.size() >= 3:
			continue
		var score := _get_tactical_striker_score(candidate)
		if (
			score > striker_score
			or (
				is_equal_approx(score, striker_score)
				and (
					striker == null
					or candidate.owner_peer_id < striker.owner_peer_id
				)
			)
		):
			striker_score = score
			striker = candidate

	if outfield.size() == 2:
		# In 2v2 only create a dedicated defender when someone is genuinely
		# suited to it; otherwise keep the classic playmaker + striker shape.
		if defender_score >= 6.0:
			return TACTICAL_ROLE_DEFENDER if target_player == defender else TACTICAL_ROLE_STRIKER
		return TACTICAL_ROLE_STRIKER if target_player == striker else TACTICAL_ROLE_PLAYMAKER

	if target_player == defender:
		return TACTICAL_ROLE_DEFENDER
	if target_player == striker:
		return TACTICAL_ROLE_STRIKER
	return TACTICAL_ROLE_PLAYMAKER


func _get_tactical_defender_score(player: FootballPlayer) -> float:
	if not is_instance_valid(player):
		return -INF
	var score := 0.0
	var football_role := StringName(player.get_meta("pve_ranked_football_role", &""))
	match football_role:
		&"goalkeeper":
			score += 10.0
		&"defender":
			score += 8.0
		&"holding":
			score += 6.5
		&"midfielder":
			score += 2.0
		&"creator":
			score += 0.5
		&"forward_creator":
			score -= 1.0
		&"winger":
			score -= 2.0
		&"striker":
			score -= 3.0

	match FootballPlayer.get_ability_role(player.selected_ability):
		FootballPlayer.ABILITY_ROLE_DEFENSE:
			score += 6.0
		FootballPlayer.ABILITY_ROLE_PLAYMAKER:
			score += 1.0
		FootballPlayer.ABILITY_ROLE_ATTACK:
			score -= 2.5
	match player.selected_ability:
		FootballPlayer.ABILITY_IRON_ANCHOR:
			score += 3.0
		FootballPlayer.ABILITY_GOALKEEPER_REACH:
			score += 4.0
		FootballPlayer.ABILITY_REFLEX_BLOCK:
			score += 2.5
		FootballPlayer.ABILITY_ECHO:
			score += 2.2
		FootballPlayer.ABILITY_ENFORCER:
			score += 1.4
	return score


func _get_tactical_striker_score(player: FootballPlayer) -> float:
	if not is_instance_valid(player):
		return -INF
	var score := 0.0
	var football_role := StringName(player.get_meta("pve_ranked_football_role", &""))
	match football_role:
		&"striker":
			score += 8.0
		&"winger":
			score += 6.5
		&"forward_creator":
			score += 5.5
		&"creator":
			score += 3.5
		&"midfielder":
			score += 2.0
		&"holding":
			score -= 1.0
		&"defender":
			score -= 2.0
		&"goalkeeper":
			score -= 4.0

	match FootballPlayer.get_ability_role(player.selected_ability):
		FootballPlayer.ABILITY_ROLE_ATTACK:
			score += 5.0
		FootballPlayer.ABILITY_ROLE_PLAYMAKER:
			score += 1.5
		FootballPlayer.ABILITY_ROLE_DEFENSE:
			score -= 4.0
	match player.selected_ability:
		FootballPlayer.ABILITY_POWER_STRIKE, FootballPlayer.ABILITY_DIRECT_FINISH:
			score += 2.2
		FootballPlayer.ABILITY_QUICK_TRIGGER:
			score += 2.0
		FootballPlayer.ABILITY_OVERDRIVE, FootballPlayer.ABILITY_BREAKAWAY:
			score += 1.6
	return score


func _get_role_support_bias(
	player: FootballPlayer,
	forward_progress: float,
	lateral_distance: float
) -> float:
	var role: StringName = _get_tactical_role(player)
	var is_forward_run: bool = forward_progress > 360.0
	var is_cover: bool = forward_progress < -260.0
	match role:
		TACTICAL_ROLE_STRIKER:
			if is_forward_run:
				return striker_support_bonus
			if is_cover:
				return -striker_support_bonus * 0.62
		TACTICAL_ROLE_PLAYMAKER:
			if lateral_distance > 360.0:
				return playmaker_support_bonus * 0.72
			if is_cover:
				return playmaker_support_bonus * 0.38
			return playmaker_support_bonus * 0.24
		TACTICAL_ROLE_DEFENDER:
			if is_cover:
				return defender_support_bonus
			if is_forward_run:
				return -defender_support_bonus * 0.78
		TACTICAL_ROLE_GOALKEEPER:
			if is_cover:
				return defender_support_bonus * 1.25
			if is_forward_run:
				return -defender_support_bonus * 1.7
	return 0.0


func _update_attack_plan(opponent_goal: FootballGoal) -> bool:
	var now = _server_time_seconds()
	if controlled_player.server_is_charging:
		return true
	if _continue_overdrive_dead_zone_plan(opponent_goal, now):
		return true
	if _continue_trap_or_volley_combo_plan(opponent_goal, now):
		return true
	var requested_receiver = _get_active_pass_request_receiver()
	if requested_receiver != null:
		_follow_pass_request(requested_receiver)
		return true
	var goal_target = _get_shot_target(opponent_goal)
	var goal_distance = ball.global_position.distance_to(goal_target)
	if _try_plan_power_strike_distribution(opponent_goal, now):
		return true
	if _try_plan_overdrive_dead_zone(opponent_goal, now):
		return true
	if _try_plan_dead_zone_trap_volley(opponent_goal, now):
		return true
	var should_commit_shot = goal_distance <= committed_shot_goal_distance
	var skill = _get_ai_skill()
	match _get_team_strategy():
		CPU_STRATEGY_DIRECT:
			should_commit_shot = goal_distance <= lerpf(
				committed_shot_goal_distance,
				committed_shot_goal_distance + 850.0,
				skill
			)
		CPU_STRATEGY_COUNTER:
			should_commit_shot = should_commit_shot or (
				goal_distance < committed_shot_goal_distance + 450.0
				and _minimum_pass_lane_clearance(goal_target) > 230.0
			)
		CPU_STRATEGY_POSSESSION:
			should_commit_shot = should_commit_shot and (
				goal_distance < committed_shot_goal_distance * 0.82
				or _minimum_pass_lane_clearance(goal_target) > 430.0
			)
	if match_manager.is_overtime:
		var shot_lane = _minimum_pass_lane_clearance(goal_target)
		should_commit_shot = (
			goal_distance <= overtime_shot_goal_distance
			and (
				shot_lane >= overtime_minimum_shot_lane
				or goal_distance <= 1700.0
			)
		)
	if skill >= elite_combination_minimum_skill:
		should_commit_shot = _elite_shot_is_worth_taking(
			goal_target,
			goal_distance
		)
		if (
			should_commit_shot
			and goal_distance > 1050.0
			and _minimum_pass_lane_clearance(goal_target) < 390.0
			and _has_elite_final_pass_option(opponent_goal)
		):
			# Keep moving a blocked defense when a genuine final pass is open.
			should_commit_shot = false
	if (
		_has_active_ability(FootballPlayer.ABILITY_POWER_STRIKE)
		and goal_distance <= power_strike_activation_goal_distance
		and goal_distance >= 700.0
		and not _ball_is_in_own_goal_danger()
	):
		var live_power_target = _get_best_live_direct_shot_target(
			opponent_goal
		)
		if not live_power_target.is_zero_approx():
			goal_target = live_power_target
			goal_distance = ball.global_position.distance_to(goal_target)
		var live_power_lane = _minimum_segment_clearance(
			ball.global_position,
			goal_target
		)
		# Power Strike is not permission to blast the ball through a defender.
		# It becomes a shot only when at least one goal route is actually open;
		# otherwise the normal pass/carry planner gets the decision.
		should_commit_shot = live_power_lane >= maxf(
			power_strike_minimum_safe_lane,
			_required_direct_shot_lane(goal_distance) * 0.72
		)
	elif (
		_has_active_ability(FootballPlayer.ABILITY_QUICK_TRIGGER)
		and goal_distance <= curve_shot_maximum_goal_distance
		and goal_distance >= curve_shot_minimum_goal_distance * 0.7
	):
		should_commit_shot = true
	if _is_true_one_vs_one() and should_commit_shot:
		# Haaland is deliberately a ranged 1v1 boss. His permanent Power Strike
		# already passed the normal live-lane safety test above, so do not force
		# him to dribble past the defender before taking a clean snipe. Other
		# CPUs still use the normal 1v1 finish/follow-up gate.
		if not controlled_player.is_haaland_boss():
			should_commit_shot = (
				_one_vs_one_shot_has_finish_or_followup(
					goal_target
				)
			)
	var creative_shot_allowed: bool = (
		not _is_true_one_vs_one()
		or _one_vs_one_shot_has_finish_or_followup(
			goal_target
		)
	)
	if (
		creative_shot_allowed
		and _try_plan_creative_shot(
			goal_target,
			goal_distance,
			now,
			should_commit_shot
		)
	):
		return true
	if should_commit_shot:
		_planned_receiver = null
		_plan_is_pass = false
		_plan_expires_at = now + maxf(0.3, pass_plan_lock_seconds)
		_set_planned_route(goal_target, true, true)
		return true
	if (
			now < _plan_expires_at
			and (
				not _plan_is_pass
				or is_instance_valid(_planned_receiver)
			)
	):
		if _plan_is_pass and is_instance_valid(_planned_receiver):
			var locked_team_plan = _get_active_team_pass_plan_for_receiver(
				_planned_receiver.owner_peer_id
			)
			if locked_team_plan.is_empty():
				_set_planned_route(
					_get_lead_pass_target(_planned_receiver),
					controlled_player.selected_ability
					!= FootballPlayer.ABILITY_TIME_SKIP_PASS,
					false
				)
		return true
	var advanced_pass_plan = _get_best_team_pass_plan(
		opponent_goal,
		true
	)
	if _apply_team_pass_plan(advanced_pass_plan, opponent_goal, now):
		return true
	var receiver = _select_pass_target(opponent_goal)
	if receiver == null and skill >= elite_combination_minimum_skill:
		# No useful pass and no quality shot is a possession-retention state, not
		# permission to blast the ball into empty space from midfield.
		_planned_receiver = null
		_plan_is_pass = false
		_plan_expires_at = 0.0
		_plan_uses_wall = false
		_planned_route_distance = 0.0
		_planned_destination = Vector2.ZERO
		_dribble_until = now + maxf(0.2, elite_retention_dribble_seconds)
		return false
	_plan_is_pass = receiver != null
	_planned_receiver = receiver
	var effective_plan_lock = pass_plan_lock_seconds
	if skill >= elite_combination_minimum_skill:
		effective_plan_lock = lerpf(
			pass_plan_lock_seconds,
			0.07,
			remap(
				skill,
				elite_combination_minimum_skill,
				1.0,
				0.4,
				1.0
			)
		)
	# 16-20 improves decision cadence, not physics or impossible mechanics.
	effective_plan_lock = lerpf(
		effective_plan_lock,
		0.045,
		get_elite_skill_extension_ratio()
	)
	_plan_expires_at = now + maxf(0.04, effective_plan_lock)
	var destination = (
		_get_lead_pass_target(receiver)
		if receiver != null
		else goal_target
	)
	_set_planned_route(
		destination,
		receiver == null or controlled_player.selected_ability
		!= FootballPlayer.ABILITY_TIME_SKIP_PASS,
		receiver == null
	)
	if receiver != null:
		match_manager.set_cpu_pass_intention(
			controlled_player.owner_peer_id,
			receiver.owner_peer_id,
			_planned_destination,
			pass_intention_seconds
		)
		_register_elite_combination_play(
			receiver,
			_planned_destination,
			opponent_goal
		)
	return true


func _try_plan_creative_shot(
	goal_target: Vector2,
	goal_distance: float,
	now: float,
	regular_shot_available: bool
) -> bool:
	if (
		now < _next_creative_shot_at
		or _ball_is_in_own_goal_danger()
		or controlled_player.global_position.distance_to(ball.global_position)
		> maxf(
			controlled_player.kick_feedback_detection_distance * 1.15,
			shot_precharge_distance
		)
	):
		return false
	var maximum_distance = committed_shot_goal_distance * 1.28
	if controlled_player.selected_ability == FootballPlayer.ABILITY_POWER_STRIKE:
		maximum_distance = maxf(
			maximum_distance,
			power_strike_activation_goal_distance
		)
	if goal_distance < 850.0 or goal_distance > maximum_distance:
		return false
	var attempt_chance = clampf(creative_shot_chance, 0.0, 1.0)
	var wall_chance = clampf(creative_wall_shot_chance, 0.0, 1.0)
	if match_manager != null and match_manager.cpu_training_mode:
		attempt_chance = maxf(attempt_chance, 0.46)
		wall_chance = maxf(wall_chance, 0.22)
	if controlled_player.selected_ability == FootballPlayer.ABILITY_POWER_STRIKE:
		attempt_chance = maxf(attempt_chance, 0.48)
		wall_chance = maxf(wall_chance, 0.18)
	if _rng.randf() > attempt_chance:
		_next_creative_shot_at = now + _rng.randf_range(0.3, 0.7)
		return false
	_next_creative_shot_at = now + _rng.randf_range(
		maxf(0.35, creative_shot_minimum_interval),
		maxf(
			maxf(0.35, creative_shot_minimum_interval),
			creative_shot_maximum_interval
		)
	)
	var opponent_goal = _get_opponent_goal()
	var double_bank_route: Dictionary = {}
	if opponent_goal != null:
		double_bank_route = _get_best_double_bank_shot_route(
			opponent_goal
		)
	var choose_double_bank = (
		not double_bank_route.is_empty()
		and _double_bank_route_beats_other_shots(
			double_bank_route,
			goal_target
		)
		and _rng.randf() < clampf(double_bank_shot_chance, 0.0, 1.0)
	)
	if choose_double_bank:
		_planned_receiver = null
		_plan_is_pass = false
		_plan_expires_at = now + maxf(0.45, pass_plan_lock_seconds)
		_plan_double_bank_shot(double_bank_route, goal_target)
		return true
	var wall_route = _get_best_wall_route(goal_target)
	var direct_clearance = _minimum_segment_clearance(
		ball.global_position,
		goal_target
	)
	var wall_clearance = float(wall_route.get("clearance", 0.0))
	var wall_advantage = wall_clearance - direct_clearance
	var meaningful_wall_route = (
		not wall_route.is_empty()
		and wall_clearance >= maxf(
			70.0,
			wall_route_minimum_clearance * 0.72
		)
		and (
			(
				not regular_shot_available
				and direct_clearance
				< _required_direct_shot_lane(goal_distance)
			)
			or wall_advantage >= maxf(
				145.0,
				wall_route_required_advantage
			)
		)
	)
	var choose_wall = (
		meaningful_wall_route
		and _rng.randf() < wall_chance
	)
	if not choose_wall and not regular_shot_available:
		# A failed regular-shot test is not permission to manufacture a low-value
		# direct blast. Let the caller keep possession, dribble or find a pass.
		return false
	if regular_shot_available and not choose_wall:
		return false
	_planned_receiver = null
	_plan_is_pass = false
	_plan_expires_at = now + maxf(0.3, pass_plan_lock_seconds)
	if choose_wall:
		_planned_destination = goal_target
		_shot_target = wall_route.get("bounce", goal_target)
		_planned_route_distance = float(wall_route.get(
			"distance",
			ball.global_position.distance_to(_shot_target)
		))
		_plan_uses_wall = true
		_plan_uses_double_bank = false
		_double_bank_required_charge_seconds = 0.0
	else:
		_set_planned_route(goal_target, false, true)
	return true


func _get_dead_zone_trap_volley_plan() -> Dictionary:
	var plan = _get_trap_or_volley_combo_plan()
	return (
		plan
		if StringName(plan.get("play_type", &""))
		== CPU_COMBO_DEAD_ZONE_TRAP_VOLLEY
		else {}
	)


func _get_power_strike_trap_volley_plan() -> Dictionary:
	var plan = _get_trap_or_volley_combo_plan()
	return (
		plan
		if StringName(plan.get("play_type", &""))
		== CPU_COMBO_POWER_STRIKE_TRAP_VOLLEY
		else {}
	)


func _get_overdrive_dead_zone_plan() -> Dictionary:
	if match_manager == null:
		return {}
	var plan = match_manager.get_cpu_combination_plan(controlled_player.team)
	return (
		plan
		if StringName(plan.get("play_type", &""))
		== CPU_COMBO_OVERDRIVE_DEAD_ZONE
		else {}
	)


func _get_trap_or_volley_combo_plan() -> Dictionary:
	if match_manager == null:
		return {}
	var plan = match_manager.get_cpu_combination_plan(
		controlled_player.team
	)
	if StringName(plan.get("play_type", &"")) not in [
		CPU_COMBO_DEAD_ZONE_TRAP_VOLLEY,
		CPU_COMBO_POWER_STRIKE_TRAP_VOLLEY
	]:
		return {}
	return plan


func _cancel_dead_zone_trap_volley_plan() -> void:
	var plan = _get_dead_zone_trap_volley_plan()
	if plan.is_empty():
		return
	_cancel_trap_or_volley_combo_plan()


func _cancel_trap_or_volley_combo_plan() -> void:
	var plan = _get_trap_or_volley_combo_plan()
	if plan.is_empty():
		return
	var receiver_peer_id = int(plan.get("receiver_peer_id", 0))
	match_manager.clear_cpu_pass_intention(receiver_peer_id)
	match_manager.clear_cpu_combination_plan(controlled_player.team)
	controlled_player.cpu_clear_time_skip_pass_route()
	if (
		_plan_is_pass
		and is_instance_valid(_planned_receiver)
		and _planned_receiver.owner_peer_id == receiver_peer_id
	):
		_clear_attack_plan()


func _cancel_overdrive_dead_zone_plan() -> void:
	var plan = _get_overdrive_dead_zone_plan()
	if plan.is_empty():
		return
	var receiver_peer_id = int(plan.get("receiver_peer_id", 0))
	match_manager.clear_cpu_pass_intention(receiver_peer_id)
	match_manager.clear_cpu_combination_plan(controlled_player.team)
	controlled_player.cpu_clear_time_skip_pass_route()
	if (
		_plan_is_pass
		and is_instance_valid(_planned_receiver)
		and _planned_receiver.owner_peer_id == receiver_peer_id
	):
		_clear_attack_plan()


func _get_goalkeeper_rebound_plan() -> Dictionary:
	if match_manager == null:
		return {}
	var plan = match_manager.get_cpu_combination_plan(controlled_player.team)
	return (
		plan
		if StringName(plan.get("play_type", &""))
		== CPU_COMBO_GOALKEEPER_REBOUND
		else {}
	)


func _cancel_goalkeeper_rebound_plan() -> void:
	var plan = _get_goalkeeper_rebound_plan()
	if plan.is_empty():
		return
	match_manager.clear_cpu_pass_intention(
		int(plan.get("receiver_peer_id", 0))
	)
	match_manager.clear_cpu_combination_plan(controlled_player.team)


func _get_goalkeeper_rebound_prediction(
	goal: FootballGoal,
	shot_direction: Vector2,
	shot_distance: float
) -> Dictionary:
	if goal == null or shot_direction.is_zero_approx():
		return {}
	var defending_team = (
		TEAM_RED
		if controlled_player.team == TEAM_BLUE
		else TEAM_BLUE
	)
	var keeper = match_manager.get_designated_cpu_goalkeeper(defending_team)
	if (
		keeper == null
		or not keeper.controls_enabled
		or shot_distance < goalkeeper_rebound_minimum_shot_distance
	):
		return {}
	var toward_keeper = ball.global_position.direction_to(keeper.global_position)
	if shot_direction.dot(toward_keeper) < 0.78:
		return {}
	var lateral_miss = absf(
		(ball.global_position - keeper.global_position).cross(shot_direction)
	)
	var ordinary_save_radius = keeper.kick_feedback_detection_distance + 120.0
	var reach_available = _player_ability_is_available(
		keeper,
		FootballPlayer.ABILITY_GOALKEEPER_REACH
	)
	var can_reach = lateral_miss <= (
		keeper.goalkeeper_reach_radius + ordinary_save_radius
		if reach_available
		else ordinary_save_radius
	)
	if not can_reach:
		return {}
	var charge_ratio = clampf(
		_desired_charge_seconds
		/ maxf(0.01, controlled_player.cpu_get_maximum_shot_charge_seconds()),
		0.0,
		1.0
	)
	var incoming_speed = lerpf(
		controlled_player.minimum_shot_force,
		controlled_player.maximum_shot_force,
		charge_ratio
	) / maxf(0.01, ball.mass)
	var travel_seconds = ball.global_position.distance_to(keeper.global_position) / maxf(1.0, incoming_speed)
	incoming_speed *= exp(-maxf(0.0, ball.linear_damp) * travel_seconds)
	var retention = 0.0
	var speed_limit = INF
	if reach_available:
		retention = clampf(keeper.goalkeeper_ball_speed_retention, 0.0, 1.0)
		speed_limit = maxf(0.0, keeper.goalkeeper_ball_speed_limit)
	else:
		# Ordinary keeper contact uses the ball's real material bounce. It is less
		# reliable than Reach, so the follower still waits for the actual touch.
		var material = ball.physics_material_override as PhysicsMaterial
		retention = material.bounce if material != null else 0.0
	var rebound_speed = minf(incoming_speed * retention, speed_limit)
	if rebound_speed < goalkeeper_rebound_minimum_collection_speed:
		return {}
	var rebound_direction = -shot_direction.normalized()
	var collection = _clamp_to_field(
		keeper.global_position
		+ rebound_direction
		* rebound_speed
		* maxf(0.15, goalkeeper_rebound_collection_seconds)
	)
	return {
		"keeper": keeper,
		"save_position": keeper.global_position,
		"collection_position": collection,
		"rebound_direction": rebound_direction,
		"rebound_speed": rebound_speed,
		"reach_save": reach_available
	}


func _try_plan_goalkeeper_rebound_followup(
	goal: FootballGoal,
	shot_direction: Vector2,
	shot_distance: float
) -> void:
	if (
		goal == null
		or not _get_goalkeeper_rebound_plan().is_empty()
		or _minimum_segment_clearance(ball.global_position, _shot_target)
		>= goalkeeper_rebound_maximum_clear_goal_lane
	):
		return
	var prediction = _get_goalkeeper_rebound_prediction(
		goal,
		shot_direction,
		shot_distance
	)
	if prediction.is_empty():
		return
	var collection: Vector2 = prediction.get("collection_position", Vector2.ZERO)
	var keeper = prediction.get("keeper") as FootballPlayer
	var best_follower: FootballPlayer
	var best_score = -INF
	for teammate in _get_teammates():
		if (
			not is_instance_valid(teammate)
			or teammate == controlled_player
			or not teammate.controls_enabled
			or _is_designated_goalkeeper(teammate)
		):
			continue
		var reach_distance = teammate.global_position.distance_to(collection)
		var pressure = _nearest_opponent_distance(collection)
		if reach_distance > pressure * 1.08 + 120.0:
			continue
		var score = pressure - reach_distance * 0.72
		if teammate.is_haaland_boss():
			# A true number nine attacks the second ball. Prefer Haaland whenever he
			# can physically reach the predicted rebound without breaking safety.
			score += 460.0
		if score > best_score:
			best_score = score
			best_follower = teammate
	if best_follower == null:
		return
	match_manager.set_cpu_combination_plan(
		controlled_player.team,
		CPU_COMBO_GOALKEEPER_REBOUND,
		controlled_player.owner_peer_id,
		best_follower.owner_peer_id,
		keeper.owner_peer_id,
		prediction.get("save_position", keeper.global_position),
		collection,
		goalkeeper_rebound_lifetime_seconds
	)


func _get_rebound_finish_target(goal: FootballGoal, keeper: FootballPlayer) -> Vector2:
	var mouth = goal.get_mouth_y_range()
	var lower = mouth.x + 130.0
	var upper = mouth.y - 130.0
	var keeper_y = keeper.global_position.y if keeper != null else (lower + upper) * 0.5
	var target_y = lower if keeper_y > (lower + upper) * 0.5 else upper
	return Vector2(goal.get_goal_plane_x(), target_y)


func _update_goalkeeper_rebound_follower(opponent_goal: FootballGoal) -> bool:
	var plan = _get_goalkeeper_rebound_plan()
	if plan.is_empty() or int(plan.get("receiver_peer_id", 0)) != controlled_player.owner_peer_id:
		return false
	var keeper = _get_opponent_by_peer_id(int(plan.get("next_peer_id", 0)))
	var collection: Vector2 = plan.get("next_run_target", Vector2.ZERO)
	if keeper == null or collection.is_zero_approx():
		_cancel_goalkeeper_rebound_plan()
		return false
	var phase = StringName(plan.get("phase", &"setup"))
	if phase == &"setup":
		if controlled_player.global_position.distance_to(collection) > _nearest_opponent_distance(collection) * 1.08 + 120.0:
			_cancel_goalkeeper_rebound_plan()
			return false
		_movement_target = collection
		_set_tactical_intent(INTENT_FORWARD_RUN, collection, keeper.owner_peer_id)
		return true
	if (
		phase != &"rebound"
		or ball.last_touch_peer_id != keeper.owner_peer_id
		or ball.linear_velocity.length() < goalkeeper_rebound_minimum_collection_speed
	):
		_cancel_goalkeeper_rebound_plan()
		return false
	var actual_direction = ball.linear_velocity.normalized()
	var expected_direction = keeper.global_position.direction_to(collection)
	if (
		expected_direction.is_zero_approx()
		or actual_direction.dot(expected_direction) < 0.25
		or controlled_player.global_position.distance_to(ball.global_position)
		> _nearest_opponent_distance(ball.global_position) * 1.08 + 160.0
	):
		_cancel_goalkeeper_rebound_plan()
		return false
	_movement_target = _clamp_to_field(_get_predicted_ball_position())
	_set_tactical_intent(INTENT_RECEIVE, _movement_target, keeper.owner_peer_id)
	if controlled_player.cpu_has_kickable_ball():
		_shot_target = _get_rebound_finish_target(opponent_goal, keeper)
		_plan_is_pass = false
		_set_planned_route(_shot_target, true, true)
		_try_begin_shot(false)
	return true


func _overdrive_runner_can_win_race(
	runner: FootballPlayer,
	target: Vector2
) -> bool:
	if not is_instance_valid(runner) or target.is_zero_approx():
		return false
	var runner_distance = runner.global_position.distance_to(target)
	var opponent_distance = _nearest_opponent_distance(target)
	return opponent_distance > runner_distance * 0.72 + 110.0


func _update_overdrive_dead_zone_runner() -> bool:
	var plan = _get_overdrive_dead_zone_plan()
	if plan.is_empty():
		return false
	if int(plan.get("receiver_peer_id", 0)) != controlled_player.owner_peer_id:
		return false
	var run_target: Vector2 = plan.get("next_run_target", Vector2.ZERO)
	if (
		run_target.is_zero_approx()
		or _ball_is_in_own_goal_danger()
		or not _player_ability_is_available(
			controlled_player,
			FootballPlayer.ABILITY_OVERDRIVE
		)
		or not _overdrive_runner_can_win_race(controlled_player, run_target)
	):
		_cancel_overdrive_dead_zone_plan()
		return false
	_overdrive_through_run_target = run_target
	_overdrive_through_run_until = maxf(
		_server_time_seconds() + 0.25,
		float(plan.get("expires_msec", 0)) / 1000.0
	)
	controlled_player.server_direction = controlled_player.global_position.direction_to(
		run_target
	)
	_movement_target = run_target
	_set_tactical_intent(
		INTENT_FORWARD_RUN,
		run_target,
		int(plan.get("initiator_peer_id", 0))
	)
	if not _has_active_ability(FootballPlayer.ABILITY_OVERDRIVE):
		_request_ability_action(
			FootballPlayer.ABILITY_OVERDRIVE,
			run_target,
			int(plan.get("initiator_peer_id", 0)),
			INTENT_FORWARD_RUN,
			FootballPlayer.ABILITY_OVERDRIVE,
			true
		)
	return true


func _is_waiting_for_overdrive_dead_zone_runner() -> bool:
	var plan = _get_overdrive_dead_zone_plan()
	if (
		plan.is_empty()
		or int(plan.get("initiator_peer_id", 0))
		!= controlled_player.owner_peer_id
	):
		return false
	var runner = _get_teammate_by_peer_id(
		int(plan.get("receiver_peer_id", 0))
	)
	return (
		runner != null
		and not runner._server_ability_is_active(
			FootballPlayer.ABILITY_OVERDRIVE
		)
	)


func _continue_overdrive_dead_zone_plan(
	_opponent_goal: FootballGoal,
	now: float
) -> bool:
	var plan = _get_overdrive_dead_zone_plan()
	if plan.is_empty():
		return false
	if int(plan.get("initiator_peer_id", 0)) != controlled_player.owner_peer_id:
		return false
	var runner = _get_teammate_by_peer_id(
		int(plan.get("receiver_peer_id", 0))
	)
	var reception: Vector2 = plan.get("next_run_target", Vector2.ZERO)
	if (
		runner == null
		or reception.is_zero_approx()
		or not _player_ability_is_available(
			runner,
			FootballPlayer.ABILITY_OVERDRIVE
		)
		or runner.global_position.distance_to(reception)
		> overdrive_through_run_maximum_distance * 1.45
		or not _overdrive_runner_can_win_race(runner, reception)
		or _minimum_segment_clearance(ball.global_position, reception)
		< dead_zone_combo_minimum_pass_clearance
	):
		_cancel_overdrive_dead_zone_plan()
		return false
	_plan_is_pass = true
	_planned_receiver = runner
	_plan_expires_at = maxf(
		now + dead_zone_combo_commit_seconds,
		float(plan.get("expires_msec", 0)) / 1000.0
	)
	_set_planned_route(reception, false, false)
	match_manager.set_cpu_pass_intention(
		controlled_player.owner_peer_id,
		runner.owner_peer_id,
		reception,
		dead_zone_combo_lifetime_seconds
	)
	return true


func _continue_trap_or_volley_combo_plan(
	opponent_goal: FootballGoal,
	now: float
) -> bool:
	var plan = _get_trap_or_volley_combo_plan()
	if plan.is_empty():
		return false
	if int(plan.get("initiator_peer_id", 0)) != controlled_player.owner_peer_id:
		return false
	var receiver = _get_teammate_by_peer_id(
		int(plan.get("receiver_peer_id", 0))
	)
	var reception: Vector2 = plan.get("next_run_target", Vector2.ZERO)
	if (
		receiver == null
		or reception.is_zero_approx()
		or receiver.global_position.distance_to(reception)
		> dead_zone_combo_receiver_reach * 1.35
		or _minimum_segment_clearance(ball.global_position, reception)
		< dead_zone_combo_minimum_pass_clearance * 0.68
	):
		_cancel_trap_or_volley_combo_plan()
		return false
	_plan_is_pass = true
	_planned_receiver = receiver
	_plan_expires_at = maxf(
		now + dead_zone_combo_commit_seconds,
		float(plan.get("expires_msec", 0)) / 1000.0
	)
	_set_planned_route(
		reception,
		_get_attacking_reception_delivery(plan) == &"power_strike",
		false
	)
	match_manager.set_cpu_pass_intention(
		controlled_player.owner_peer_id,
		receiver.owner_peer_id,
		reception,
		dead_zone_combo_lifetime_seconds
	)
	return true


func _continue_dead_zone_trap_volley_plan(
	opponent_goal: FootballGoal,
	now: float
) -> bool:
	var plan = _get_dead_zone_trap_volley_plan()
	if plan.is_empty():
		return false
	return _continue_trap_or_volley_combo_plan(opponent_goal, now)


func _get_attacking_reception_delivery(plan: Dictionary) -> StringName:
	return StringName(plan.get("delivery", &"normal"))


func _set_attacking_reception_plan(
	play_type: StringName,
	receiver: FootballPlayer,
	reception: Vector2,
	lifetime: float,
	delivery: StringName
) -> void:
	match_manager.set_cpu_pass_intention(
		controlled_player.owner_peer_id,
		receiver.owner_peer_id,
		reception,
		lifetime
	)
	match_manager.set_cpu_combination_plan(
		controlled_player.team,
		play_type,
		controlled_player.owner_peer_id,
		receiver.owner_peer_id,
		receiver.owner_peer_id,
		ball.global_position,
		reception,
		lifetime,
		{"delivery": delivery}
	)


func _try_plan_dead_zone_trap_volley(
	opponent_goal: FootballGoal,
	now: float
) -> bool:
	if (
		controlled_player.selected_ability
		!= FootballPlayer.ABILITY_TIME_SKIP_PASS
		or _ball_is_in_own_goal_danger()
		or controlled_player.global_position.distance_to(ball.global_position)
		> controlled_player.kick_feedback_detection_distance
	):
		return false
	var attack_sign = _get_attack_sign()
	var goal_center = _get_goal_center(opponent_goal)
	var best_receiver: FootballPlayer
	var best_reception = Vector2.ZERO
	var best_score = -INF
	for teammate in _get_teammates():
		if (
			not is_instance_valid(teammate)
			or teammate == controlled_player
			or not teammate.controls_enabled
			or teammate.selected_ability
			!= FootballPlayer.ABILITY_DIRECT_FINISH
			or _is_designated_goalkeeper(teammate)
		):
			continue
		var reception = _clamp_to_field(
			teammate.global_position
			+ teammate.linear_velocity * minf(0.28, pass_lead_seconds + 0.1)
			+ Vector2(
				attack_sign * minf(460.0, cpu_receiver_forward_lead + 160.0),
				0.0
			)
		)
		var pass_distance = ball.global_position.distance_to(reception)
		var forward_progress = (
			reception.x - ball.global_position.x
		) * attack_sign
		if (
			pass_distance < dead_zone_combo_minimum_distance
			or pass_distance > minf(
				dead_zone_combo_maximum_distance,
				controlled_player.time_skip_pass_maximum_receiver_distance
			)
			or forward_progress < dead_zone_combo_minimum_forward_progress
			or teammate.global_position.distance_to(reception)
			> dead_zone_combo_receiver_reach
		):
			continue
		var pass_clearance = _minimum_segment_clearance(
			ball.global_position,
			reception
		)
		if pass_clearance < dead_zone_combo_minimum_pass_clearance:
			continue
		var reception_space = _nearest_opponent_distance(reception)
		if reception_space < dead_zone_minimum_open_space:
			continue
		var scoring_target = _get_dead_zone_scoring_target(
			reception,
			opponent_goal
		)
		var scoring_clearance = (
			_minimum_segment_clearance(reception, scoring_target)
			if not scoring_target.is_zero_approx()
			else 0.0
		)
		var score = (
			forward_progress * 0.6
			+ reception_space * 0.32
			+ pass_clearance * 0.2
			+ scoring_clearance * 0.25
			- reception.distance_to(goal_center) * 0.1
		)
		if score > best_score:
			best_score = score
			best_receiver = teammate
			best_reception = reception
	if best_receiver == null:
		return false
	_plan_is_pass = true
	_planned_receiver = best_receiver
	_plan_expires_at = now + dead_zone_combo_commit_seconds
	_set_planned_route(best_reception, false, false)
	_set_attacking_reception_plan(
		CPU_COMBO_DEAD_ZONE_TRAP_VOLLEY,
		best_receiver,
		best_reception,
		dead_zone_combo_lifetime_seconds,
		&"dead_zone" if _cpu_ability_is_ready() else &"normal"
	)
	return true


func _try_plan_overdrive_dead_zone(
	opponent_goal: FootballGoal,
	now: float
) -> bool:
	if (
		controlled_player.selected_ability
		!= FootballPlayer.ABILITY_TIME_SKIP_PASS
		or _ball_is_in_own_goal_danger()
		or controlled_player.global_position.distance_to(ball.global_position)
		> controlled_player.kick_feedback_detection_distance
	):
		return false
	var best_runner: FootballPlayer
	var best_reception = Vector2.ZERO
	var best_score = -INF
	var attack_sign = _get_attack_sign()
	var goal_center = _get_goal_center(opponent_goal)
	for teammate in _get_teammates():
		if (
			not is_instance_valid(teammate)
			or teammate == controlled_player
			or not teammate.controls_enabled
			or teammate.selected_ability
			!= FootballPlayer.ABILITY_OVERDRIVE
			or _is_designated_goalkeeper(teammate)
			or not _player_ability_is_available(
				teammate,
				FootballPlayer.ABILITY_OVERDRIVE
			)
		):
			continue
		var reception = _get_overdrive_through_run_target_for(
			teammate,
			controlled_player
		)
		if reception.is_zero_approx():
			continue
		var pass_distance = ball.global_position.distance_to(reception)
		var forward_progress = (
			reception.x - ball.global_position.x
		) * attack_sign
		var runner_distance = teammate.global_position.distance_to(reception)
		var pass_clearance = _minimum_segment_clearance(
			ball.global_position,
			reception
		)
		if (
			pass_distance < dead_zone_combo_minimum_distance
			or pass_distance > minf(
				dead_zone_combo_maximum_distance,
				controlled_player.time_skip_pass_maximum_receiver_distance
			)
			or forward_progress < dead_zone_combo_minimum_forward_progress
			or runner_distance > overdrive_through_run_maximum_distance * 1.45
			or pass_clearance < dead_zone_combo_minimum_pass_clearance
			or not _overdrive_runner_can_win_race(teammate, reception)
		):
			continue
		var score = (
			forward_progress * 0.62
			+ _nearest_opponent_distance(reception) * 0.32
			+ pass_clearance * 0.24
			- reception.distance_to(goal_center) * 0.1
		)
		if score > best_score:
			best_score = score
			best_runner = teammate
			best_reception = reception
	if best_runner == null:
		return false
	_plan_is_pass = true
	_planned_receiver = best_runner
	_plan_expires_at = now + dead_zone_combo_commit_seconds
	_set_planned_route(best_reception, false, false)
	_set_attacking_reception_plan(
		CPU_COMBO_OVERDRIVE_DEAD_ZONE,
		best_runner,
		best_reception,
		dead_zone_combo_lifetime_seconds,
		&"dead_zone" if _cpu_ability_is_ready() else &"normal"
	)
	return true


func _get_dead_zone_scoring_target(
	reception: Vector2,
	opponent_goal: FootballGoal
) -> Vector2:
	var mouth = opponent_goal.get_mouth_y_range()
	var best_target = Vector2.ZERO
	var best_clearance = -INF
	for sample_index in range(5):
		var ratio = float(sample_index) / 4.0
		var candidate = Vector2(
			opponent_goal.get_goal_plane_x(),
			lerpf(mouth.x + 120.0, mouth.y - 120.0, ratio)
		)
		var clearance = _minimum_segment_clearance(reception, candidate)
		if clearance > best_clearance:
			best_clearance = clearance
			best_target = candidate
	return best_target


func _count_delivery_bypassed_defenders(
	start: Vector2,
	target: Vector2
) -> int:
	var attack_sign: float = _get_attack_sign()
	var total_progress: float = (target.x - start.x) * attack_sign
	if total_progress < 260.0:
		return 0
	var bypassed: int = 0
	for opponent in _get_opponents():
		if not is_instance_valid(opponent) or not opponent.controls_enabled:
			continue
		var opponent_progress: float = (
			opponent.global_position.x - start.x
		) * attack_sign
		if opponent_progress < 120.0 or opponent_progress > total_progress - 80.0:
			continue
		# Count defenders in the same broad attacking channel, not only bodies
		# directly in the ball lane. A split pass between two defenders should be
		# recognized as line-breaking even though neither defender is hit.
		if _distance_to_segment(opponent.global_position, start, target) <= 1250.0:
			bypassed += 1
	return bypassed


func _get_ability_delivery_transition_value(
	receiver: FootballPlayer,
	target: Vector2,
	goal_center: Vector2
) -> float:
	if not is_instance_valid(receiver) or target.is_zero_approx():
		return 0.0
	var receiver_value: float = _get_receiver_attack_value(
		receiver, target, goal_center
	) / 1.45
	var target_space: float = clampf(
		_nearest_opponent_distance(target) / 1050.0,
		0.0,
		1.0
	)
	var line_breaks: int = _count_delivery_bypassed_defenders(
		ball.global_position, target
	)
	var line_break_value: float = clampf(float(line_breaks) / 2.0, 0.0, 1.0)
	var lateral_switch: float = clampf(
		absf(target.y - ball.global_position.y) / 1500.0,
		0.0,
		1.0
	)
	return clampf(
		receiver_value * 0.46
		+ target_space * 0.22
		+ line_break_value * 0.24
		+ lateral_switch * 0.12,
		0.0,
		1.25
	)


func _try_plan_power_strike_distribution(
	opponent_goal: FootballGoal,
	now: float
) -> bool:
	# A named cross is an option, never a reservation. If the carrier has a
	# clear, high-value Power Strike now, taking it is better than waiting for a
	# teammate to become the perfect Trap-or-Volley target.
	if (
		_cpu_ability_is_ready()
		and controlled_player.cpu_has_kickable_ball()
		and opponent_goal != null
	):
		var direct_target = _get_shot_target(opponent_goal)
		var direct_distance = ball.global_position.distance_to(direct_target)
		var direct_clearance = _minimum_segment_clearance(
			ball.global_position,
			direct_target
		)
		if (
			direct_distance <= power_strike_activation_goal_distance * 0.72
			and direct_distance >= 700.0
			and direct_clearance >= power_strike_distribution_minimum_lane * 1.3
		):
			return false
	if (
		controlled_player.selected_ability
		!= FootballPlayer.ABILITY_POWER_STRIKE
		or _get_ai_skill() < 0.58
		or _ball_is_in_own_goal_danger()
		or _get_active_team_player_count() <= 1
	):
		return false
	var carrier_pressure_distance: float = _nearest_opponent_distance(
		ball.global_position
	)
	var pressure_urgency: float = 1.0 - clampf(
		(carrier_pressure_distance - 180.0) / 900.0,
		0.0,
		1.0
	)

	var best_receiver: FootballPlayer
	var best_target = Vector2.ZERO
	var best_score = -INF
	var attack_sign = _get_attack_sign()
	var goal_center = _get_goal_center(opponent_goal)
	var active_team_size: int = _get_active_team_player_count()
	var minimum_delivery_distance: float = power_strike_distribution_minimum_distance
	var minimum_delivery_progress: float = power_strike_distribution_minimum_progress
	if active_team_size >= 4:
		minimum_delivery_distance *= 0.46
		minimum_delivery_progress *= 0.24
	elif active_team_size >= 3:
		minimum_delivery_distance *= 0.54
		minimum_delivery_progress *= 0.32
	var power_delivery_ready = (
		_cpu_ability_is_ready()
		or _has_active_ability(FootballPlayer.ABILITY_POWER_STRIKE)
	)
	for teammate in _get_teammates():
		if (
			not is_instance_valid(teammate)
			or teammate == controlled_player
			or not teammate.controls_enabled
			or _is_designated_goalkeeper(teammate)
		):
			continue
		var target = _get_lead_pass_target(teammate)
		if _get_active_team_player_count() == 2:
			var raw_distance = ball.global_position.distance_to(
				teammate.global_position
			)
			target = _clamp_to_field(
				target
				+ Vector2(
					attack_sign * clampf(raw_distance * 0.16, 360.0, 900.0),
					0.0
				)
			)
		var distance = ball.global_position.distance_to(target)
		var forward_progress = (
			target.x - ball.global_position.x
		) * attack_sign
		if (
			distance < minimum_delivery_distance
			or distance > power_strike_distribution_maximum_distance
			or forward_progress < minimum_delivery_progress
		):
			continue
		var direct_clearance = _minimum_segment_clearance(
			ball.global_position,
			target
		)
		var line_breaks: int = _count_delivery_bypassed_defenders(
			ball.global_position, target
		)
		var transition_value: float = _get_ability_delivery_transition_value(
			teammate, target, goal_center
		)
		var required_delivery_lane: float = maxf(
			82.0, power_strike_distribution_minimum_lane
		)
		if power_delivery_ready:
			# Driven deliveries are valuable specifically when they punch through a
			# rotating block. Keep a real collision-safe floor, but do not demand
			# the pristine ordinary-pass lane that made Gojo keep dribbling.
			required_delivery_lane *= (0.62 if active_team_size >= 3 else 0.78)
			if line_breaks >= 1 or transition_value >= 0.72:
				required_delivery_lane *= 0.82
		var route_available = direct_clearance >= maxf(82.0, required_delivery_lane)
		if not power_delivery_ready:
			# Ordinary crosses must stand on their own: no Power Strike reach or
			# wall-route assumptions are permitted once the ability is unavailable.
			route_available = route_available and distance <= maximum_pass_distance
		elif not route_available:
			var wall_route = _get_best_wall_route(target)
			route_available = (
				not wall_route.is_empty()
				and float(wall_route.get("clearance", 0.0))
				>= wall_route_minimum_clearance
			)
		if not route_available:
			continue
		var receiver_attack_value: float = _get_receiver_attack_value(
			teammate, target, goal_center
		)
		var score = (
			forward_progress * 0.42
			+ minf(_nearest_opponent_distance(target), 1200.0) * 0.28
			- target.distance_to(goal_center) * 0.08
			+ direct_clearance * 0.12
			+ receiver_attack_value * 760.0
			+ transition_value * 760.0
			+ float(line_breaks) * 210.0
			+ pressure_urgency * 230.0
		)
		if receiver_attack_value >= 0.72:
			score += 160.0
		if absf(target.y - ball.global_position.y) >= 1050.0:
			score += 120.0
		if teammate.server_pass_request_ends_at > now:
			score += requested_pass_score_bonus
		if score > best_score:
			best_score = score
			best_receiver = teammate
			best_target = target
	if best_receiver == null:
		return false
	var delivery: StringName = (
		&"power_strike"
		if power_delivery_ready
		else &"normal"
	)

	_clear_attack_plan()
	_plan_is_pass = true
	_planned_receiver = best_receiver
	_planned_pass_kind = &"power_strike_delivery" if delivery == &"power_strike" else &"lead"
	_plan_expires_at = now + _get_high_tempo_plan_duration(
		pass_plan_lock_seconds,
		0.10
	)
	_set_planned_route(best_target, delivery == &"power_strike", false)
	_register_elite_combination_play(
		best_receiver,
		_planned_destination,
		opponent_goal
	)
	match_manager.set_cpu_pass_intention(
		controlled_player.owner_peer_id,
		best_receiver.owner_peer_id,
		_planned_destination,
		maxf(pass_intention_seconds, 2.4)
	)
	if (
		best_receiver.selected_ability
		== FootballPlayer.ABILITY_DIRECT_FINISH
	):
		# Direct Finish can still turn the long outlet into a Trap-or-Volley
		# combination. Other receivers simply collect the fast pass normally.
		_set_attacking_reception_plan(
			CPU_COMBO_POWER_STRIKE_TRAP_VOLLEY,
			best_receiver,
			_planned_destination,
			maxf(pass_intention_seconds, 2.4),
			delivery
		)
	return true


func _try_plan_curve_shot_distribution(
	opponent_goal: FootballGoal,
	now: float
) -> bool:
	if (
		controlled_player.selected_ability
		!= FootballPlayer.ABILITY_QUICK_TRIGGER
		or _get_ai_skill() < 0.62
		or _ball_is_in_own_goal_danger()
		or _get_active_team_player_count() <= 1
		or not (
			_cpu_ability_is_ready()
			or _has_active_ability(FootballPlayer.ABILITY_QUICK_TRIGGER)
		)
	):
		return false
	var goal_center: Vector2 = _get_goal_center(opponent_goal)
	var direct_goal_distance: float = ball.global_position.distance_to(goal_center)
	var direct_goal_lane: float = _minimum_segment_clearance(
		ball.global_position,
		goal_center
	)
	if (
		direct_goal_distance >= curve_shot_minimum_goal_distance
		and direct_goal_distance <= curve_shot_maximum_goal_distance
		and direct_goal_lane >= 260.0
		and _get_best_team_second_ball_value(goal_center) < 0.82
	):
		return false

	var attack_sign: float = _get_attack_sign()
	var carrier_pressure_distance: float = _nearest_opponent_distance(ball.global_position)
	var pressure_urgency: float = 1.0 - clampf(
		(carrier_pressure_distance - 180.0) / 900.0,
		0.0,
		1.0
	)
	var best_receiver: FootballPlayer
	var best_target := Vector2.ZERO
	var best_score := -INF
	for teammate in _get_teammates():
		if (
			not is_instance_valid(teammate)
			or teammate == controlled_player
			or not teammate.controls_enabled
			or _is_designated_goalkeeper(teammate)
		):
			continue
		var target: Vector2 = _get_lead_pass_target(teammate)
		var distance: float = ball.global_position.distance_to(target)
		var forward_progress: float = (
			target.x - ball.global_position.x
		) * attack_sign
		if (
			distance < curve_shot_distribution_minimum_distance
			or distance > curve_shot_distribution_maximum_distance
			or forward_progress < curve_shot_distribution_minimum_progress
		):
			continue
		var direct_clearance: float = _minimum_segment_clearance(
			ball.global_position,
			target
		)
		var target_space: float = _nearest_opponent_distance(target)
		if target_space < 260.0:
			continue
		var receiver_value: float = _get_receiver_attack_value(
			teammate, target, goal_center
		)
		var line_breaks: int = _count_delivery_bypassed_defenders(
			ball.global_position, target
		)
		var transition_value: float = _get_ability_delivery_transition_value(
			teammate, target, goal_center
		)
		var maximum_curve_lane: float = curve_shot_distribution_maximum_direct_lane
		if line_breaks >= 1 or transition_value >= 0.72:
			maximum_curve_lane = maxf(maximum_curve_lane, 500.0)
		if (
			direct_clearance < curve_shot_distribution_minimum_lane
			or direct_clearance > maximum_curve_lane
		):
			continue
		if receiver_value < 0.34 and transition_value < 0.62:
			continue
		var score: float = (
			forward_progress * 0.34
			+ target_space * 0.24
			+ receiver_value * 720.0
			+ transition_value * 680.0
			+ float(line_breaks) * 180.0
			+ pressure_urgency * 170.0
			+ maxf(0.0, maximum_curve_lane - direct_clearance) * 0.24
		)
		if teammate.server_pass_request_ends_at > now:
			score += requested_pass_score_bonus
		if score > best_score:
			best_score = score
			best_receiver = teammate
			best_target = target
	if best_receiver == null:
		return false

	_clear_attack_plan()
	_plan_is_pass = true
	_planned_receiver = best_receiver
	_planned_pass_kind = &"curve_delivery"
	_plan_expires_at = now + maxf(0.48, pass_plan_lock_seconds)
	_set_planned_route(best_target, false, false)
	match_manager.set_cpu_pass_intention(
		controlled_player.owner_peer_id,
		best_receiver.owner_peer_id,
		_planned_destination,
		maxf(pass_intention_seconds, 2.0)
	)
	_register_elite_combination_play(
		best_receiver,
		_planned_destination,
		opponent_goal
	)
	return true


func _is_curve_shot_distribution_plan() -> bool:
	return (
		controlled_player.selected_ability
		== FootballPlayer.ABILITY_QUICK_TRIGGER
		and _plan_is_pass
		and is_instance_valid(_planned_receiver)
		and _planned_pass_kind == &"curve_delivery"
	)


func _elite_shot_is_worth_taking(
	goal_target: Vector2,
	goal_distance: float
) -> bool:
	var shot_lane = _minimum_pass_lane_clearance(goal_target)
	if goal_distance <= 1050.0:
		return shot_lane >= 105.0
	var maximum_distance = maxf(1200.0, elite_normal_shot_distance)
	var lane_relief = 0.0
	var ability_is_available = (
		_cpu_ability_is_ready()
		or _has_active_ability(controlled_player.selected_ability)
	)
	if ability_is_available:
		match controlled_player.selected_ability:
			FootballPlayer.ABILITY_POWER_STRIKE:
				maximum_distance = maxf(
					maximum_distance,
					power_strike_activation_goal_distance
				)
				lane_relief = 105.0
			FootballPlayer.ABILITY_QUICK_TRIGGER:
				maximum_distance = maxf(
					maximum_distance,
					curve_shot_maximum_goal_distance
				)
				lane_relief = 70.0
			FootballPlayer.ABILITY_DIRECT_FINISH:
				maximum_distance += 300.0
				lane_relief = 45.0
	if _get_team_strategy() == CPU_STRATEGY_DIRECT:
		maximum_distance += 260.0
	if match_manager.is_overtime:
		maximum_distance += 420.0
		lane_relief += 35.0
	if goal_distance > maximum_distance:
		return false
	var distance_ratio = clampf(
		inverse_lerp(1050.0, maximum_distance, goal_distance),
		0.0,
		1.0
	)
	var required_lane = lerpf(
		elite_minimum_shot_lane,
		elite_open_long_shot_lane,
		distance_ratio
	) - lane_relief
	return shot_lane >= maxf(120.0, required_lane)


func _has_elite_final_pass_option(opponent_goal: FootballGoal) -> bool:
	var goal_center = _get_goal_center(opponent_goal)
	var current_goal_distance = ball.global_position.distance_to(goal_center)
	for teammate in _get_teammates():
		if (
			not is_instance_valid(teammate)
			or teammate == controlled_player
			or not teammate.controls_enabled
			or _is_designated_goalkeeper(teammate)
		):
			continue
		var target = _get_lead_pass_target(teammate)
		if target.distance_to(goal_center) >= current_goal_distance + 180.0:
			continue
		if (
			_nearest_opponent_distance(target) >= 430.0
			and _minimum_segment_clearance(ball.global_position, target)
			>= pass_lane_clearance * 0.76
		):
			return true
	return false


func _register_elite_combination_play(
	receiver: FootballPlayer,
	receiver_target: Vector2,
	opponent_goal: FootballGoal
) -> void:
	if (
		_get_ai_skill() < elite_combination_minimum_skill
		or not is_instance_valid(receiver)
		or _is_designated_goalkeeper(receiver)
	):
		return
	var attack_sign = _get_attack_sign()
	var initiator_is_goalkeeper = _is_designated_goalkeeper(
		controlled_player
	)
	var team_plan = _get_active_team_pass_plan_for_receiver(
		receiver.owner_peer_id
	)
	if team_plan.is_empty() and _team_play_planner != null:
		team_plan = _team_play_planner.get_cached_pass_plan_for_receiver(
			receiver.owner_peer_id
		)
	var pass_kind = StringName(team_plan.get("kind", &""))
	if pass_kind == &"" and _planned_pass_kind in [
		&"power_strike_delivery",
		&"curve_delivery"
	]:
		# Ability-driven deliveries are not automatic one-touch return passes.
		# Classify the advantage they created so the receiver attacks the opening
		# while the rest of the team makes the continuation run.
		var delivery_progress: float = (
			receiver_target.x - ball.global_position.x
		) * attack_sign
		var delivery_lateral: float = absf(
			receiver_target.y - ball.global_position.y
		)
		if delivery_lateral >= 1050.0:
			pass_kind = &"wide_switch"
		elif delivery_progress >= 420.0:
			pass_kind = &"through"
		else:
			pass_kind = &"pressure_escape"

	var nearest_defender = _get_nearest_opponent_to(
		controlled_player.global_position
	)
	var lateral_escape = 0.0
	if nearest_defender != null:
		lateral_escape = signf(
			controlled_player.global_position.y
			- nearest_defender.global_position.y
		) * 380.0
	var initiator_run_target = _clamp_to_field(
		controlled_player.global_position
		+ Vector2(
			attack_sign * elite_one_two_run_distance,
			lateral_escape
		)
	)
	if initiator_is_goalkeeper:
		initiator_run_target = controlled_player.global_position
	elif not team_plan.is_empty():
		var planned_initiator_target: Vector2 = team_plan.get(
			"follow_up_target",
			Vector2.ZERO
		)
		if (
			int(team_plan.get("follow_up_peer_id", 0))
			== controlled_player.owner_peer_id
			and not planned_initiator_target.is_zero_approx()
		):
			initiator_run_target = _clamp_to_field(
				planned_initiator_target
			)

	var best_third_player: FootballPlayer
	var best_third_target = Vector2.ZERO
	var best_third_score = -INF
	var requested_follow_up_peer = int(
		team_plan.get("follow_up_peer_id", 0)
	)
	if (
		requested_follow_up_peer > 0
		and requested_follow_up_peer
		!= controlled_player.owner_peer_id
	):
		best_third_player = _get_teammate_by_peer_id(
			requested_follow_up_peer
		)
		if (
			best_third_player != null
			and best_third_player != receiver
		):
			best_third_target = team_plan.get(
				"follow_up_target",
				_get_lead_pass_target(best_third_player)
			)
			best_third_score = maxf(
				540.0,
				float(team_plan.get("chain_value", 0.0))
			)
		else:
			best_third_player = null

	if best_third_player == null:
		for candidate in _get_teammates():
			if (
				not is_instance_valid(candidate)
				or candidate == controlled_player
				or candidate == receiver
				or not candidate.controls_enabled
				or _is_designated_goalkeeper(candidate)
			):
				continue
			var candidate_target = _clamp_to_field(
				candidate.global_position
				+ candidate.linear_velocity * 0.25
				+ Vector2(
					attack_sign * elite_third_man_lead_distance,
					0.0
				)
			)
			var relay_clearance = _minimum_segment_clearance(
				receiver_target,
				candidate_target
			)
			if relay_clearance < pass_lane_clearance * 0.66:
				continue
			var candidate_score = (
				_nearest_opponent_distance(candidate_target) * 0.42
				+ relay_clearance * 0.34
				+ (
					candidate_target.x - receiver_target.x
				) * attack_sign * 0.36
				+ _get_receiver_ability_bonus(
					candidate,
					candidate_target,
					receiver_target.distance_to(
						_get_goal_center(opponent_goal)
					)
				) * 1.4
			)
			if candidate_score > best_third_score:
				best_third_score = candidate_score
				best_third_player = candidate
				best_third_target = candidate_target

	var play_type = CPU_COMBO_ONE_TWO
	var next_player = controlled_player
	var next_target = initiator_run_target
	if best_third_player != null and best_third_score > 520.0:
		play_type = CPU_COMBO_THIRD_MAN
		next_player = best_third_player
		next_target = best_third_target

	match pass_kind:
		&"one_two":
			play_type = CPU_COMBO_ONE_TWO
			next_player = controlled_player
			next_target = initiator_run_target
		&"third_man":
			if best_third_player != null:
				play_type = CPU_COMBO_THIRD_MAN
				next_player = best_third_player
				next_target = best_third_target
		&"wide_switch", &"cutback", &"overlap":
			play_type = CPU_COMBO_WIDE_SWITCH
		&"wall_bank":
			play_type = CPU_COMBO_WALL_RELAY
		_:
			if initiator_is_goalkeeper:
				if best_third_player == null:
					return
				play_type = CPU_COMBO_WIDE_SWITCH
				next_player = best_third_player
				next_target = best_third_target
			elif _plan_uses_wall:
				play_type = CPU_COMBO_WALL_RELAY
			elif absf(receiver_target.y - ball.global_position.y) > 1050.0:
				play_type = CPU_COMBO_WIDE_SWITCH

	if (
		receiver.selected_ability in [
			FootballPlayer.ABILITY_TIME_SKIP_PASS,
			FootballPlayer.ABILITY_HEEL_TURN,
			FootballPlayer.ABILITY_META_VISION,
			FootballPlayer.ABILITY_IRON_ANCHOR
		]
		or next_player.selected_ability in [
			FootballPlayer.ABILITY_DIRECT_FINISH,
			FootballPlayer.ABILITY_OVERDRIVE,
			FootballPlayer.ABILITY_POWER_STRIKE,
			FootballPlayer.ABILITY_QUICK_TRIGGER
		]
	):
		play_type = CPU_COMBO_ABILITY_CHAIN

	var metadata = {
		"pass_kind": pass_kind,
		"receiver_target": receiver_target,
		"team_plan_quality": float(team_plan.get("quality", 0.0)),
		"interception_margin": float(
			team_plan.get("interception_margin", 0.0)
		),
		"receiver_margin": float(
			team_plan.get("receiver_margin", 0.0)
		),
		"chain_value": float(team_plan.get("chain_value", 0.0)),
		"counter_risk": float(team_plan.get("counter_risk", 0.0)),
		"defensive_error_value": float(
			team_plan.get("defensive_error_value", 0.0)
		),
		"team_plan_reason": str(team_plan.get("reason", "")),
		"team_play_version": 1
	}
	match_manager.set_cpu_combination_plan(
		controlled_player.team,
		play_type,
		controlled_player.owner_peer_id,
		receiver.owner_peer_id,
		next_player.owner_peer_id,
		initiator_run_target,
		next_target,
		elite_combination_lifetime,
		metadata
	)


func _get_active_pass_request_receiver() -> FootballPlayer:
	var now = _server_time_seconds()
	var requested_receiver: FootballPlayer
	var latest_request_end = now
	for teammate in _get_teammates():
		if (
			not is_instance_valid(teammate)
			or teammate == controlled_player
			or not teammate.controls_enabled
			or teammate.server_pass_request_ends_at <= now
		):
			continue
		if teammate.server_pass_request_ends_at > latest_request_end:
			latest_request_end = teammate.server_pass_request_ends_at
			requested_receiver = teammate
	return requested_receiver


func _consider_cpu_pass_request() -> void:
	var now = _server_time_seconds()
	if (
		now < _next_pass_request_at
		or controlled_player.server_is_charging
		or _is_primary_ball_chaser()
		or not _team_likely_has_possession()
		or _ball_is_in_own_goal_danger()
	):
		return

	var carrier = _get_likely_team_ball_carrier()
	if (
		carrier == null
		or carrier == controlled_player
		or carrier.global_position.distance_to(ball.global_position)
		> controlled_player.kick_feedback_detection_distance + 260.0
	):
		_next_pass_request_at = now + pass_request_retry_interval
		return

	var carrier_intention = _get_effective_player_intention(carrier)
	if (
		carrier.server_is_charging
		and StringName(carrier_intention.get("action", &""))
		== INTENT_SHOOT
	):
		_next_pass_request_at = now + pass_request_retry_interval
		return

	# A human request has priority, and only one CPU teammate calls at once.
	for teammate in _get_teammates():
		if (
			not is_instance_valid(teammate)
			or teammate == controlled_player
			or not teammate.controls_enabled
			or teammate.server_pass_request_ends_at <= now
		):
			continue
		_next_pass_request_at = now + pass_request_retry_interval
		return

	var own_score = _get_cpu_pass_request_score(controlled_player)
	if own_score < pass_request_minimum_score:
		_next_pass_request_at = now + pass_request_retry_interval
		return

	# The best available CPU option calls for it. This prevents a chorus of
	# markers while still letting the ball carrier make the final decision.
	for teammate in _get_teammates():
		if (
			not is_instance_valid(teammate)
			or teammate == controlled_player
			or not teammate.cpu_controlled
			or not teammate.controls_enabled
			or teammate == carrier
			or _is_designated_goalkeeper(teammate)
		):
			continue
		var teammate_score = _get_cpu_pass_request_score(teammate)
		if (
			teammate_score > own_score + 1.0
			or (
				is_equal_approx(teammate_score, own_score)
				and teammate.owner_peer_id
				< controlled_player.owner_peer_id
			)
		):
			_next_pass_request_at = now + pass_request_retry_interval
			return

	if controlled_player.cpu_request_pass():
		var request_interval_scale = 1.0
		if _get_ai_skill() >= elite_combination_minimum_skill:
			request_interval_scale = lerpf(
				0.62,
				0.34,
				remap(
					_get_ai_skill(),
					elite_combination_minimum_skill,
					1.0,
					0.0,
					1.0
				)
			)
		_next_pass_request_at = now + _rng.randf_range(
			maxf(0.3, pass_request_minimum_interval) * request_interval_scale,
			maxf(pass_request_minimum_interval, pass_request_maximum_interval)
			* request_interval_scale
		)
	else:
		_next_pass_request_at = now + pass_request_retry_interval


func _get_cpu_pass_request_score(candidate: FootballPlayer) -> float:
	if (
		not is_instance_valid(candidate)
		or not candidate.controls_enabled
		or _is_designated_goalkeeper(candidate)
	):
		return -INF
	var target = _clamp_to_field(
		candidate.global_position + candidate.linear_velocity * 0.22
	)
	var intention = _get_effective_player_intention(candidate)
	var action = StringName(intention.get("action", &""))
	if action in [INTENT_RECEIVE, INTENT_FORWARD_RUN, INTENT_WIDE_SUPPORT]:
		var intended_target: Vector2 = intention.get("target_position", target)
		var maximum_intention_distance = 900.0
		var intention_blend = clampf(intention_target_blend, 0.0, 1.0)
		if (
			action == INTENT_FORWARD_RUN
			and candidate.selected_ability == FootballPlayer.ABILITY_OVERDRIVE
			and _player_ability_is_available(
				candidate,
				FootballPlayer.ABILITY_OVERDRIVE
			)
		):
			maximum_intention_distance = maxf(
				1200.0,
				overdrive_through_run_maximum_distance
			)
			intention_blend = maxf(intention_blend, 0.88)
		target = _clamp_to_field(target.lerp(
			candidate.global_position
			+ (intended_target - candidate.global_position).limit_length(
				maximum_intention_distance
			),
			intention_blend
		))
	var distance = ball.global_position.distance_to(target)
	if (
		distance < pass_request_minimum_distance
		or distance > pass_request_maximum_distance
	):
		return -INF
	var openness = _nearest_opponent_distance(target)
	var lane_clearance = _minimum_segment_clearance(
		ball.global_position,
		target
	)
	if (
		openness < pass_request_minimum_openness
		or lane_clearance < pass_request_minimum_lane_clearance
	):
		return -INF
	var forward_progress = (
		target.x - ball.global_position.x
	) * _get_attack_sign()
	var intention_bonus = 0.0
	if action == INTENT_FORWARD_RUN:
		intention_bonus = 330.0
		if candidate.selected_ability == FootballPlayer.ABILITY_OVERDRIVE:
			intention_bonus += 280.0
	elif action in [INTENT_WIDE_SUPPORT, INTENT_RECEIVE]:
		intention_bonus = 190.0
	elif action in [INTENT_COVER, INTENT_MARK, INTENT_GOALKEEP]:
		intention_bonus = -220.0
	var safe_outlet_bonus = 0.0
	var carrier = _get_likely_team_ball_carrier()
	if (
		carrier != null
		and _nearest_opponent_distance(carrier.global_position)
		<= pass_pressure_radius
		and forward_progress >= -420.0
	):
		safe_outlet_bonus = 260.0
	var opponent_goal = _get_opponent_goal()
	var goal_distance = (
		ball.global_position.distance_to(_get_goal_center(opponent_goal))
		if opponent_goal != null
		else 3000.0
	)
	return (
		openness * 0.48
		+ lane_clearance * 0.42
		+ forward_progress * 0.18
		- distance * 0.06
		+ intention_bonus
		+ safe_outlet_bonus
		+ _get_receiver_ability_bonus(candidate, target, goal_distance)
	)


func _follow_pass_request(receiver: FootballPlayer) -> void:
	if not is_instance_valid(receiver) or not receiver.controls_enabled:
		return
	_dribble_until = 0.0
	_wall_dribble_until = 0.0
	_wall_dribble_kicked = false
	if (
		controlled_player.server_is_charging
		and (
			not _plan_is_pass
			or _planned_receiver != receiver
		)
	):
		controlled_player.cpu_cancel_shot_charge()
		_reset_cpu_charge_tracking()
	var destination = _get_lead_pass_target(receiver)
	var pass_distance = ball.global_position.distance_to(destination)
	var direct_clearance = _minimum_segment_clearance(
		ball.global_position,
		destination
	)
	var wall_route = _get_best_wall_route(destination)
	var direct_is_usable = (
		direct_clearance >= pass_lane_clearance * 0.72
	)
	var wall_is_usable = (
		not wall_route.is_empty()
		and float(wall_route.get("clearance", 0.0))
		>= wall_route_minimum_clearance
	)
	_shot_target = destination
	_movement_target = _get_strike_position(destination)
	if (
		pass_distance < 120.0
		or pass_distance > maximum_pass_distance
		or (not direct_is_usable and not wall_is_usable)
	):
		if controlled_player.server_is_charging:
			controlled_player.cpu_cancel_shot_charge()
			_reset_cpu_charge_tracking()
		_planned_receiver = null
		_plan_is_pass = false
		_plan_expires_at = 0.0
		_plan_uses_wall = false
		return
	var now = _server_time_seconds()
	_plan_is_pass = true
	_planned_receiver = receiver
	_plan_expires_at = now + maxf(0.2, pass_plan_lock_seconds)
	_set_planned_route(
		destination,
		controlled_player.selected_ability
		!= FootballPlayer.ABILITY_TIME_SKIP_PASS,
		false
	)
	match_manager.set_cpu_pass_intention(
		controlled_player.owner_peer_id,
		receiver.owner_peer_id,
		_planned_destination,
		pass_intention_seconds
	)
	var opponent_goal = _get_opponent_goal()
	if opponent_goal != null:
		_register_elite_combination_play(
			receiver,
			_planned_destination,
			opponent_goal
		)
	_movement_target = _get_strike_position(_shot_target)
	var instant_ability_used = _activate_planned_ball_ability()
	if not instant_ability_used:
		_try_begin_shot(false)


func _clear_attack_plan() -> void:
	if controlled_player.server_is_charging:
		return
	_planned_receiver = null
	_plan_is_pass = false
	_plan_expires_at = 0.0
	_plan_uses_wall = false
	_plan_uses_double_bank = false
	_double_bank_required_charge_seconds = 0.0
	_planned_route_distance = 0.0
	_planned_destination = Vector2.ZERO
	_clear_active_team_pass_plan()


func _set_planned_route(
	destination: Vector2,
	allow_wall: bool,
	for_shot: bool
) -> void:
	_planned_destination = destination
	_shot_target = destination
	_plan_uses_wall = false
	_plan_uses_double_bank = false
	_double_bank_required_charge_seconds = 0.0
	_planned_route_distance = ball.global_position.distance_to(destination)
	if not allow_wall:
		return
	var direct_clearance = _minimum_segment_clearance(
		ball.global_position,
		destination
	)
	var wall_route = _get_best_wall_route(destination)
	if wall_route.is_empty():
		return
	var wall_clearance = float(wall_route.get("clearance", 0.0))
	var required_wall_advantage = wall_route_required_advantage
	if _get_ai_skill() >= elite_combination_minimum_skill:
		required_wall_advantage = lerpf(
			wall_route_required_advantage,
			22.0,
			remap(
				_get_ai_skill(),
				elite_combination_minimum_skill,
				1.0,
				0.45,
				1.0
			)
		)
	var wall_is_better = (
		wall_clearance >= wall_route_minimum_clearance
		and wall_clearance
		>= direct_clearance + required_wall_advantage
	)
	var power_wall_opportunity = (
		for_shot
		and controlled_player.selected_ability
		== FootballPlayer.ABILITY_POWER_STRIKE
		and wall_clearance
		> direct_clearance
		+ maxf(145.0, required_wall_advantage)
	)
	var blocked_direct_pass = (
		not for_shot
		and direct_clearance < pass_lane_clearance
		and wall_clearance >= wall_route_minimum_clearance
	)
	if (
		not wall_is_better
		and not power_wall_opportunity
		and not blocked_direct_pass
	):
		return
	_shot_target = wall_route.get("bounce", destination)
	_planned_route_distance = float(
		wall_route.get("distance", _planned_route_distance)
	)
	_plan_uses_wall = true


func _select_pass_target(
	opponent_goal: FootballGoal
) -> FootballPlayer:
	var teammates = _get_teammates()
	var requested_receiver = _get_active_pass_request_receiver()
	if (
		requested_receiver != null
		and (
			not requested_receiver.cpu_controlled
			or _get_ai_skill() < elite_combination_minimum_skill
		)
	):
		return requested_receiver
	var combination_receiver = _get_elite_combination_pass_receiver()
	if combination_receiver != null:
		return combination_receiver
	if requested_receiver != null:
		return requested_receiver
	var team_pass_plan = _get_best_team_pass_plan(
		opponent_goal,
		false
	)
	if _team_pass_plan_is_acceptable(team_pass_plan):
		var team_receiver = _get_teammate_by_peer_id(
			int(team_pass_plan.get("receiver_peer_id", 0))
		)
		if team_receiver != null:
			return team_receiver
	var teammate_requested_pass = false
	var request_check_time = _server_time_seconds()
	for teammate in teammates:
		if (
			is_instance_valid(teammate)
			and teammate.server_pass_request_ends_at
			> request_check_time
		):
			teammate_requested_pass = true
			break
	if (
		not _has_active_meta_vision()
		and not match_manager.is_overtime
		and not teammate_requested_pass
		and _rng.randf() < missed_read_chance * lerpf(
			2.4,
			elite_missed_read_ratio,
			_get_ai_skill()
		)
	):
		return null
	var goal_distance = ball.global_position.distance_to(
		_get_goal_center(opponent_goal)
	)
	if goal_distance <= avoid_passes_near_goal_distance:
		return null

	var nearest_pressure = _nearest_opponent_distance(
		controlled_player.global_position
	)
	var pressured = nearest_pressure <= pass_pressure_radius
	var best_receiver: FootballPlayer
	var best_score = -INF
	for teammate in teammates:
		if (
			not is_instance_valid(teammate)
			or teammate == controlled_player
			or not teammate.controls_enabled
			or _is_designated_goalkeeper(teammate)
		):
			continue
		var pass_requested = (
			teammate.server_pass_request_ends_at
			> _server_time_seconds()
		)
		var target = _get_lead_pass_target(teammate)
		var distance = ball.global_position.distance_to(target)
		var direct_clearance = _minimum_segment_clearance(
			ball.global_position,
			target
		)
		var direct_is_safe = direct_clearance >= maxf(
			1.0,
			pass_lane_clearance
		)
		var wall_route: Dictionary = {}
		if (
			not direct_is_safe
			and controlled_player.selected_ability
			!= FootballPlayer.ABILITY_TIME_SKIP_PASS
		):
			wall_route = _get_best_wall_route(target)
		var wall_is_safe = (
			not wall_route.is_empty()
			and float(wall_route.get("clearance", 0.0))
			>= wall_route_minimum_clearance
		)
		if (
			distance < minimum_pass_distance
			or distance > maximum_pass_distance
			or (not direct_is_safe and not wall_is_safe)
		):
			continue

		var forward_progress = (
			target.x - ball.global_position.x
		) * _get_attack_sign()
		if (
			not pressured
			and not pass_requested
			and forward_progress < minimum_forward_pass_progress
			and goal_distance < build_up_pass_goal_distance
		):
			continue
		if (
			match_manager.is_overtime
			and not pass_requested
			and forward_progress < 120.0
		):
			continue

		var openness = _nearest_opponent_distance(target)
		var goal_gain = (
			goal_distance
			- target.distance_to(_get_goal_center(opponent_goal))
		)
		var lane_bonus = (
			direct_clearance
			if direct_is_safe
			else float(wall_route.get("clearance", 0.0))
		)
		var route_penalty = 0.0
		if wall_is_safe and not direct_is_safe:
			route_penalty = (
				float(wall_route.get("distance", distance))
				- distance
			) * wall_route_length_penalty
		var score = (
			forward_progress * 0.62
			+ goal_gain * 0.38
			+ openness * 0.32
			+ lane_bonus * 0.18
			- distance * 0.1
			- route_penalty
		)
		var ability_bonus = _get_receiver_ability_bonus(
			teammate,
			target,
			goal_distance
		)
		score += _get_elite_pass_chain_bonus(
			teammate,
			target,
			opponent_goal
		)
		if _get_team_strategy() == CPU_STRATEGY_ABILITY_COMBO:
			ability_bonus *= lerpf(1.0, 1.85, _get_ai_skill())
		score += ability_bonus
		match _get_team_strategy():
			CPU_STRATEGY_DIRECT, CPU_STRATEGY_COUNTER:
				score += forward_progress * lerpf(0.08, 0.32, _get_ai_skill())
			CPU_STRATEGY_POSSESSION:
				score += openness * 0.28 + lane_bonus * 0.22 - distance * 0.035
			CPU_STRATEGY_WALL_PLAY:
				if wall_is_safe:
					score += lerpf(100.0, 460.0, _get_ai_skill())
		if teammate.cpu_controlled:
			if not match_manager.is_overtime:
				score += 80.0
		elif match_manager.is_overtime:
			# In golden goal, do not quietly prefer another CPU over an open
			# human teammate who can choose the finish themselves.
			score += overtime_human_receiver_bonus
		var receiver_intention = _get_effective_player_intention(teammate)
		var receiver_action = StringName(
			receiver_intention.get("action", &"")
		)
		if receiver_action in [INTENT_RECEIVE, INTENT_FORWARD_RUN]:
			score += 240.0
		elif receiver_action == INTENT_COVER and not pass_requested:
			score -= 110.0
		if pass_requested:
			score += requested_pass_score_bonus
		if score > best_score:
			best_score = score
			best_receiver = teammate
	var goalkeeper_outlet = _get_elite_goalkeeper_backpass(
		best_receiver,
		best_score,
		pressured
	)
	if goalkeeper_outlet != null:
		return goalkeeper_outlet
	return best_receiver


func _get_elite_goalkeeper_backpass(
	best_forward_receiver: FootballPlayer,
	best_forward_score: float,
	pressured: bool
) -> FootballPlayer:
	var skill = _get_ai_skill()
	if (
		skill < elite_build_up_minimum_skill
		or match_manager.is_overtime
		or _is_designated_goalkeeper(controlled_player)
		or not _team_likely_has_possession()
		or _ball_is_in_own_goal_danger()
	):
		return null
	var two_player_team = _get_active_team_player_count() == 2
	var weak_forward_opening = (
		best_forward_receiver == null
		or best_forward_score < elite_backpass_opening_score
	)
	if not two_player_team and not pressured and not weak_forward_opening:
		return null
	var goalkeeper = match_manager.get_designated_cpu_goalkeeper(
		controlled_player.team
	)
	if (
		not is_instance_valid(goalkeeper)
		or goalkeeper == controlled_player
		or not goalkeeper.controls_enabled
	):
		return null
	var target = _clamp_to_field(
		goalkeeper.global_position
		+ goalkeeper.linear_velocity * 0.12
		+ Vector2(_get_attack_sign() * (230.0 if two_player_team else 150.0), 0.0)
	)
	var distance = ball.global_position.distance_to(target)
	var minimum_outlet_distance = (
		320.0 if two_player_team else elite_backpass_minimum_distance
	)
	var required_keeper_space = (
		maxf(240.0, two_vs_two_keeper_outlet_space)
		if two_player_team
		else elite_backpass_minimum_keeper_space
	)
	var required_lane = pass_lane_clearance * (0.68 if two_player_team else 0.9)
	if (
		distance < minimum_outlet_distance
		or distance > maximum_pass_distance
		or _nearest_opponent_distance(target) < required_keeper_space
		or _minimum_segment_clearance(ball.global_position, target) < required_lane
	):
		return null
	var use_backpass_chance = (
		1.0
		if two_player_team
		else remap(
			skill,
			elite_build_up_minimum_skill,
			1.0,
			0.2,
			1.0
		)
	)
	if _rng.randf() > clampf(use_backpass_chance, 0.0, 1.0):
		return null
	return goalkeeper


func _get_elite_combination_pass_receiver() -> FootballPlayer:
	if (
		_get_ai_skill() < elite_combination_minimum_skill
		or _ball_is_in_own_goal_danger()
	):
		return null
	var plan = match_manager.get_cpu_combination_plan(controlled_player.team)
	if (
		plan.is_empty()
		or int(plan.get("receiver_peer_id", 0))
		!= controlled_player.owner_peer_id
	):
		return null
	if StringName(plan.get("pass_kind", &"")) in [
		&"through",
		&"diagonal_split",
		&"blindside",
		&"square",
		&"cutback",
		&"overlap",
		&"underlap",
		&"pressure_escape",
		&"layoff",
		&"recycle"
	]:
		return null
	var next_player = _get_teammate_by_peer_id(
		int(plan.get("next_peer_id", 0))
	)
	if next_player == null or next_player == controlled_player:
		return null
	var target = _get_lead_pass_target(next_player)
	var planned_next_target: Vector2 = plan.get(
		"next_run_target",
		target
	)
	target = _clamp_to_field(target.lerp(planned_next_target, 0.72))
	var distance = ball.global_position.distance_to(target)
	if distance < minimum_pass_distance or distance > maximum_pass_distance:
		return null
	var direct_clearance = _minimum_segment_clearance(
		ball.global_position,
		target
	)
	var wall_route = _get_best_wall_route(target)
	if (
		direct_clearance < pass_lane_clearance * 0.64
		and (
			wall_route.is_empty()
			or float(wall_route.get("clearance", 0.0))
			< wall_route_minimum_clearance
		)
	):
		return null
	return next_player


func _get_elite_pass_chain_bonus(
	receiver: FootballPlayer,
	receiver_target: Vector2,
	opponent_goal: FootballGoal
) -> float:
	var skill = _get_ai_skill()
	if skill < elite_combination_minimum_skill:
		return 0.0
	var best_follow_up = 0.0
	for third_player in _get_teammates():
		if (
			not is_instance_valid(third_player)
			or third_player == controlled_player
			or third_player == receiver
			or not third_player.controls_enabled
			or _is_designated_goalkeeper(third_player)
		):
			continue
		var third_target = _clamp_to_field(
			third_player.global_position
			+ third_player.linear_velocity * 0.28
			+ Vector2(
				_get_attack_sign() * elite_third_man_lead_distance,
				0.0
			)
		)
		var relay_distance = receiver_target.distance_to(third_target)
		if relay_distance < 380.0 or relay_distance > maximum_pass_distance:
			continue
		var relay_clearance = _minimum_segment_clearance(
			receiver_target,
			third_target
		)
		if relay_clearance < pass_lane_clearance * 0.68:
			continue
		var forward_progress = (
			third_target.x - receiver_target.x
		) * _get_attack_sign()
		var third_space = _nearest_opponent_distance(third_target)
		var ability_chain_bonus = _get_receiver_ability_bonus(
			third_player,
			third_target,
			receiver_target.distance_to(_get_goal_center(opponent_goal))
		)
		var follow_up_score = (
			forward_progress * 0.34
			+ minf(relay_clearance, 1200.0) * 0.28
			+ minf(third_space, 1300.0) * 0.32
			+ ability_chain_bonus * 1.25
			- relay_distance * 0.055
		)
		best_follow_up = maxf(best_follow_up, follow_up_score)

	var one_two_target = _clamp_to_field(
		controlled_player.global_position
		+ Vector2(_get_attack_sign() * elite_one_two_run_distance, 0.0)
	)
	var return_clearance = _minimum_segment_clearance(
		receiver_target,
		one_two_target
	)
	var return_space = _nearest_opponent_distance(one_two_target)
	var one_two_score = (
		minf(return_clearance, 1200.0) * 0.3
		+ minf(return_space, 1300.0) * 0.34
		+ maxf(
			0.0,
			(one_two_target.x - receiver_target.x) * _get_attack_sign()
		) * 0.3
	)
	var quality = maxf(best_follow_up, one_two_score)
	var level_weight = remap(
		skill,
		elite_combination_minimum_skill,
		1.0,
		0.25,
		1.0
	)
	return quality * elite_pass_lookahead_weight * level_weight


func _get_teammate_by_peer_id(peer_id: int) -> FootballPlayer:
	if peer_id <= 0:
		return null
	if (
		is_instance_valid(match_manager)
		and match_manager.has_method("get_cpu_shared_player")
	):
		var shared_player: FootballPlayer = match_manager.get_cpu_shared_player(peer_id) as FootballPlayer
		if (
			is_instance_valid(shared_player)
			and shared_player.controls_enabled
			and shared_player.team == controlled_player.team
		):
			return shared_player
		return null
	for teammate in _get_teammates():
		if (
			is_instance_valid(teammate)
			and teammate.owner_peer_id == peer_id
			and teammate.controls_enabled
		):
			return teammate
	return null


func _get_lead_pass_target(receiver: FootballPlayer) -> Vector2:
	if not is_instance_valid(receiver):
		return ball.global_position
	var team_plan = _get_active_team_pass_plan_for_receiver(
		receiver.owner_peer_id
	)
	if team_plan.is_empty() and _team_play_planner != null:
		team_plan = _team_play_planner.get_cached_pass_plan_for_receiver(
			receiver.owner_peer_id
		)
	if (
		not team_plan.is_empty()
		and _team_pass_plan_is_acceptable(team_plan)
	):
		var exact_destination: Vector2 = team_plan.get(
			"destination",
			Vector2.ZERO
		)
		if not exact_destination.is_zero_approx():
			return _clamp_to_field(exact_destination)
	var forward_lead = (
		cpu_receiver_forward_lead
		if receiver.cpu_controlled
		else 0.0
	)
	var movement_lead = _clamp_to_field(
		receiver.global_position
		+ receiver.linear_velocity * maxf(0.0, pass_lead_seconds)
		+ Vector2(_get_attack_sign() * forward_lead, 0.0)
	)
	var intention = _get_effective_player_intention(receiver)
	var action = StringName(intention.get("action", &""))
	if action in [INTENT_RECEIVE, INTENT_FORWARD_RUN, INTENT_WIDE_SUPPORT]:
		var intended_target: Vector2 = intention.get(
			"target_position",
			movement_lead
		)
		var maximum_intention_distance = 900.0
		var target_blend = clampf(intention_target_blend, 0.0, 1.0)
		if (
			action == INTENT_FORWARD_RUN
			and receiver.selected_ability == FootballPlayer.ABILITY_OVERDRIVE
			and _player_ability_is_available(
				receiver,
				FootballPlayer.ABILITY_OVERDRIVE
			)
		):
			maximum_intention_distance = maxf(
				1200.0,
				overdrive_through_run_maximum_distance
			)
			target_blend = maxf(target_blend, 0.88)
		var limited_target = (
			receiver.global_position
			+ (intended_target - receiver.global_position).limit_length(
				maximum_intention_distance
			)
		)
		movement_lead = movement_lead.lerp(
			limited_target,
			target_blend
		)
	return _clamp_to_field(movement_lead)


func _is_pass_lane_safe(target: Vector2) -> bool:
	return (
		_minimum_pass_lane_clearance(target)
		>= maxf(1.0, pass_lane_clearance)
	)


func _minimum_pass_lane_clearance(target: Vector2) -> float:
	var minimum_clearance = INF
	var pass_vector = target - ball.global_position
	var lane_start = ball.global_position
	if not pass_vector.is_zero_approx():
		lane_start += pass_vector.normalized() * minf(
			300.0,
			pass_vector.length() * 0.18
		)
	for opponent in _get_opponents():
		if not is_instance_valid(opponent):
			continue
		minimum_clearance = minf(
			minimum_clearance,
			_distance_to_segment(
				opponent.global_position,
				lane_start,
				target
			) - _get_ability_interception_bonus(opponent)
		)
	return minimum_clearance


func _minimum_segment_clearance(
	segment_start: Vector2,
	segment_end: Vector2
) -> float:
	var minimum_clearance = INF
	for opponent in _get_opponents():
		if not is_instance_valid(opponent) or not opponent.controls_enabled:
			continue
		minimum_clearance = minf(
			minimum_clearance,
			_distance_to_segment(
				opponent.global_position,
				segment_start,
				segment_end
			) - _get_ability_interception_bonus(opponent)
		)
	return minimum_clearance


func _get_best_wall_route(destination: Vector2) -> Dictionary:
	if (
		match_manager is FootballMatchManager
		and (match_manager as FootballMatchManager).is_fun_mutator_enabled(
			FootballMatchManager.FUN_NO_WALLS
		)
	):
		return {}
	var best_route: Dictionary = {}
	var best_score = -INF
	for wall_y_value in [ball_wall_top_y, ball_wall_bottom_y]:
		var wall_y: float = float(wall_y_value)
		var reflected_target = Vector2(
			destination.x,
			wall_y * 2.0 - destination.y
		)
		var denominator: float = (
			reflected_target.y - ball.global_position.y
		)
		if absf(denominator) < 1.0:
			continue
		var intersection_ratio: float = (
			wall_y - ball.global_position.y
		) / denominator
		if intersection_ratio <= 0.05 or intersection_ratio >= 0.95:
			continue
		var bounce_point = ball.global_position.lerp(
			reflected_target,
			intersection_ratio
		)
		if (
			bounce_point.x
			< minimum_field_x + wall_route_edge_padding
			or bounce_point.x
			> maximum_field_x - wall_route_edge_padding
		):
			continue
		var first_length = ball.global_position.distance_to(bounce_point)
		var second_length = bounce_point.distance_to(destination)
		if first_length < 360.0 or second_length < 360.0:
			continue
		var clearance = minf(
			_minimum_segment_clearance(
				ball.global_position,
				bounce_point
			),
			_minimum_segment_clearance(
				bounce_point,
				destination
			)
		)
		var route_distance = first_length + second_length
		var score = clearance - route_distance * wall_route_length_penalty
		if score > best_score:
			best_score = score
			best_route = {
				"bounce": bounce_point,
				"clearance": clearance,
				"distance": route_distance
			}
	return best_route


func _get_best_double_bank_shot_route(
	opponent_goal: FootballGoal
) -> Dictionary:
	if (
		match_manager is FootballMatchManager
		and (match_manager as FootballMatchManager).is_fun_mutator_enabled(
			FootballMatchManager.FUN_NO_WALLS
		)
	):
		return {}
	if opponent_goal == null or ball == null or controlled_player == null:
		return {}
	var launch_speed_limit = _get_double_bank_launch_speed_limit()
	if launch_speed_limit <= 0.0:
		return {}
	var mouth_range = opponent_goal.get_mouth_y_range()
	var radius = maxf(0.0, ball.arena_ball_radius)
	var mouth_padding = maxf(0.0, double_bank_goal_mouth_padding) + radius
	var minimum_target_y = mouth_range.x + mouth_padding
	var maximum_target_y = mouth_range.y - mouth_padding
	if minimum_target_y >= maximum_target_y:
		set_double_bank_debug_rejection("goal mouth is too narrow for ball radius")
		return {}
	var best_route: Dictionary = {}
	var best_value = -INF
	var geometry_rejections = 0
	var clearance_rejections = 0
	var goalkeeper_rejections = 0
	var speed_rejections = 0
	for first_wall_value in [true, false]:
		var first_hits_top = bool(first_wall_value)
		for target_index in range(7):
			var target_ratio = float(target_index) / 6.0
			var target_y = lerpf(
				minimum_target_y,
				maximum_target_y,
				target_ratio
			)
			var route = _simulate_double_bank_shot_route(
				opponent_goal,
				first_hits_top,
				target_y,
				launch_speed_limit
			)
			if route.is_empty():
				geometry_rejections += 1
				continue
			var clearance = _get_double_bank_route_clearance(route)
			if clearance < maxf(0.0, double_bank_minimum_route_clearance):
				clearance_rejections += 1
				continue
			var goalkeeper_clearance = _get_double_bank_goalkeeper_clearance(
				route,
				opponent_goal
			)
			if goalkeeper_clearance < maxf(
				0.0,
				double_bank_goalkeeper_clearance
			):
				goalkeeper_rejections += 1
				continue
			var required_speed = _get_double_bank_required_launch_speed(
				opponent_goal,
				first_hits_top,
				target_y,
				launch_speed_limit
			)
			if required_speed <= 0.0:
				speed_rejections += 1
				continue
			route["clearance"] = clearance
			route["goalkeeper_clearance"] = goalkeeper_clearance
			route["required_launch_speed"] = required_speed
			route["charge_seconds"] = _get_double_bank_charge_seconds(
				required_speed
			)
			var route_value = (
				clearance
				+ goalkeeper_clearance * 0.55
				+ float(route.get("remaining_speed", 0.0)) * 0.3
				- float(route.get("distance", 0.0))
				* wall_route_length_penalty
			)
			route["value"] = route_value
			if route_value > best_value:
				best_value = route_value
				best_route = route
	if best_route.is_empty():
		var rejection_reason = "no valid geometry"
		if clearance_rejections >= geometry_rejections and clearance_rejections >= goalkeeper_rejections:
			rejection_reason = "defender route clearance"
		elif goalkeeper_rejections >= geometry_rejections:
			rejection_reason = "goalkeeper covers crossing"
		elif speed_rejections > geometry_rejections:
			rejection_reason = "insufficient post-bounce speed"
		set_double_bank_debug_rejection(rejection_reason)
	return best_route


func _simulate_double_bank_shot_route(
	opponent_goal: FootballGoal,
	first_hits_top: bool,
	goal_target_y: float,
	launch_speed: float
) -> Dictionary:
	if launch_speed <= 0.0:
		return {}
	var wall_bounds = _get_double_bank_wall_bounds()
	var top_wall: float = wall_bounds.x
	var bottom_wall: float = wall_bounds.y
	var first_wall = top_wall if first_hits_top else bottom_wall
	var second_wall = bottom_wall if first_hits_top else top_wall
	var start = ball.global_position
	var goal_x = opponent_goal.get_goal_plane_x()
	var first_vertical = first_wall - start.y
	if absf(first_vertical) < 1.0:
		return {}
	var restitution = _get_double_bank_wall_restitution()
	if restitution <= 0.05:
		return {}
	# The first bounce is solved analytically, then the second bounce and goal
	# crossing are verified with the same normal-component restitution the ball
	# receives from its physics material. This is not the simpler mirrored-line
	# construction, which would be wrong once a bounce loses vertical speed.
	var coefficient = (
		(second_wall - first_wall) / -restitution
		+ (goal_target_y - second_wall) / (restitution * restitution)
	) / first_vertical
	if absf(1.0 + coefficient) < 0.001:
		return {}
	var first_x = (
		goal_x + coefficient * start.x
	) / (1.0 + coefficient)
	var field_x_bounds = _get_double_bank_field_x_bounds()
	if (
		first_x < field_x_bounds.x + wall_route_edge_padding
		or first_x > field_x_bounds.y - wall_route_edge_padding
		or (first_x - start.x) * _get_attack_sign() < 120.0
	):
		return {}
	var bounce_one = Vector2(first_x, first_wall)
	var first_direction = start.direction_to(bounce_one)
	if first_direction.is_zero_approx():
		return {}
	var first_slope = first_vertical / (first_x - start.x)
	var second_slope = -restitution * first_slope
	if absf(second_slope) < 0.001:
		return {}
	var second_x = first_x + (second_wall - first_wall) / second_slope
	if (
		second_x < field_x_bounds.x + wall_route_edge_padding
		or second_x > field_x_bounds.y - wall_route_edge_padding
	):
		return {}
	var bounce_two = Vector2(second_x, second_wall)
	if (goal_x - second_x) * _get_attack_sign() < 120.0:
		return {}
	var third_slope = -restitution * second_slope
	var final_y = second_wall + third_slope * (goal_x - second_x)
	var mouth_range = opponent_goal.get_mouth_y_range()
	var radius = maxf(0.0, ball.arena_ball_radius)
	if (
		final_y < mouth_range.x + radius
		or final_y > mouth_range.y - radius
	):
		return {}

	var first_length = start.distance_to(bounce_one)
	var second_length = bounce_one.distance_to(bounce_two)
	var third_length = bounce_two.distance_to(Vector2(goal_x, final_y))
	if first_length < 180.0 or second_length < 300.0 or third_length < 180.0:
		return {}
	var velocity = first_direction * launch_speed
	var travel_time = 0.0
	var first_result = _simulate_double_bank_segment(
		velocity,
		first_length
	)
	if first_result.is_empty():
		return {}
	velocity = first_result.get("velocity", Vector2.ZERO)
	travel_time += float(first_result.get("time", 0.0))
	velocity.y = -velocity.y * restitution
	if velocity.normalized().dot(bounce_one.direction_to(bounce_two)) < 0.995:
		return {}
	var second_result = _simulate_double_bank_segment(
		velocity,
		second_length
	)
	if second_result.is_empty():
		return {}
	velocity = second_result.get("velocity", Vector2.ZERO)
	travel_time += float(second_result.get("time", 0.0))
	velocity.y = -velocity.y * restitution
	if velocity.normalized().dot(bounce_two.direction_to(Vector2(goal_x, final_y))) < 0.995:
		return {}
	var third_result = _simulate_double_bank_segment(
		velocity,
		third_length
	)
	if third_result.is_empty():
		return {}
	velocity = third_result.get("velocity", Vector2.ZERO)
	travel_time += float(third_result.get("time", 0.0))
	if velocity.length() < maxf(0.0, double_bank_minimum_scoring_speed):
		return {}
	return {
		"start_position": start,
		"bounce_one": bounce_one,
		"bounce_two": bounce_two,
		"goal_position": Vector2(goal_x, final_y),
		"distance": first_length + second_length + third_length,
		"remaining_speed": velocity.length(),
		"travel_time": travel_time,
		"first_hits_top": first_hits_top
	}


func _simulate_double_bank_segment(
	velocity: Vector2,
	distance: float
) -> Dictionary:
	var initial_speed = velocity.length()
	if initial_speed <= 0.01 or distance <= 0.0:
		return {}
	var damping = maxf(0.0, ball.linear_damp)
	var final_speed = initial_speed - damping * distance
	if final_speed <= 0.01:
		return {}
	var travel_time = distance / initial_speed
	if damping > 0.001:
		travel_time = log(initial_speed / final_speed) / damping
	return {
		"velocity": velocity.normalized() * final_speed,
		"time": travel_time
	}


func _get_double_bank_wall_bounds() -> Vector2:
	var physical_bounds = _get_physical_double_bank_wall_bounds()
	if physical_bounds.x < physical_bounds.y:
		return physical_bounds
	if ball.arena_containment_enabled:
		var bounds = ball.arena_playable_bounds.abs()
		var radius = maxf(0.0, ball.arena_ball_radius)
		return Vector2(
			bounds.position.y + radius,
			bounds.end.y - radius
		)
	return Vector2(ball_wall_top_y, ball_wall_bottom_y)


func _get_physical_double_bank_wall_bounds() -> Vector2:
	if ball == null or ball.get_parent() == null:
		return Vector2.ZERO
	var field_boundary = ball.get_parent().get_node_or_null(
		"BallFieldBoundary"
	)
	if field_boundary == null:
		return Vector2.ZERO
	var top_line = field_boundary.get_node_or_null(
		"TopLine"
	) as CollisionShape2D
	var bottom_line = field_boundary.get_node_or_null(
		"BottomLine"
	) as CollisionShape2D
	if (
		top_line == null
		or bottom_line == null
		or not top_line.shape is RectangleShape2D
		or not bottom_line.shape is RectangleShape2D
	):
		return Vector2.ZERO
	var top_shape = top_line.shape as RectangleShape2D
	var bottom_shape = bottom_line.shape as RectangleShape2D
	var top_half_height = (
		top_shape.size.y * absf(top_line.global_scale.y) * 0.5
	)
	var bottom_half_height = (
		bottom_shape.size.y * absf(bottom_line.global_scale.y) * 0.5
	)
	var ball_radius = _get_double_bank_collision_radius()
	var ball_shape_offset_y = _get_double_bank_collision_offset_y()
	return Vector2(
		top_line.global_position.y
		+ top_half_height
		+ ball_radius
		- ball_shape_offset_y,
		bottom_line.global_position.y
		- bottom_half_height
		- ball_radius
		- ball_shape_offset_y
	)


func _get_double_bank_collision_radius() -> float:
	if ball == null:
		return 0.0
	var collision_shape = ball.get_node_or_null(
		"CollisionShape2D"
	) as CollisionShape2D
	if collision_shape != null and collision_shape.shape is CircleShape2D:
		var circle = collision_shape.shape as CircleShape2D
		return circle.radius * maxf(
			absf(collision_shape.global_scale.x),
			absf(collision_shape.global_scale.y)
		)
	return maxf(0.0, ball.arena_ball_radius)


func _get_double_bank_collision_offset_y() -> float:
	if ball == null:
		return 0.0
	var collision_shape = ball.get_node_or_null(
		"CollisionShape2D"
	) as CollisionShape2D
	if collision_shape == null:
		return 0.0
	return collision_shape.global_position.y - ball.global_position.y


func _get_double_bank_field_x_bounds() -> Vector2:
	if ball.arena_containment_enabled:
		var bounds = ball.arena_playable_bounds.abs()
		var radius = maxf(0.0, ball.arena_ball_radius)
		return Vector2(
			bounds.position.x + radius,
			bounds.end.x - radius
		)
	return Vector2(minimum_field_x, maximum_field_x)


func _get_double_bank_wall_restitution() -> float:
	# If no physical touch line is present, FootballBall's containment recovery
	# is the real bounce source rather than the rigid body's material.
	var physical_bounds = _get_physical_double_bank_wall_bounds()
	if physical_bounds.x >= physical_bounds.y and ball.arena_containment_enabled:
		return clampf(ball.arena_recovery_bounce, 0.05, 1.0)
	var material = ball.physics_material_override as PhysicsMaterial
	if material != null:
		return clampf(material.bounce, 0.05, 1.0)
	return 0.8


func _get_double_bank_launch_speed_limit() -> float:
	var multiplier = 1.0
	if (
		controlled_player.selected_ability == FootballPlayer.ABILITY_POWER_STRIKE
		and (
			_cpu_ability_is_ready()
			or _has_active_ability(FootballPlayer.ABILITY_POWER_STRIKE)
		)
	):
		multiplier = maxf(1.0, controlled_player.power_strike_force_multiplier)
	return maxf(0.0, controlled_player.maximum_shot_force * multiplier)


func _get_double_bank_required_launch_speed(
	opponent_goal: FootballGoal,
	first_hits_top: bool,
	goal_target_y: float,
	maximum_speed: float
) -> float:
	var multiplier = maxf(
		1.0,
		_get_double_bank_launch_speed_limit()
		/ maxf(1.0, controlled_player.maximum_shot_force)
	)
	var low = controlled_player.minimum_shot_force * multiplier
	var high = maximum_speed
	if _simulate_double_bank_shot_route(
		opponent_goal,
		first_hits_top,
		goal_target_y,
		high
	).is_empty():
		return 0.0
	for _iteration in range(12):
		var middle = (low + high) * 0.5
		if _simulate_double_bank_shot_route(
			opponent_goal,
			first_hits_top,
			goal_target_y,
			middle
		).is_empty():
			low = middle
		else:
			high = middle
	return high


func _get_double_bank_charge_seconds(required_speed: float) -> float:
	var multiplier = maxf(
		1.0,
		_get_double_bank_launch_speed_limit()
		/ maxf(1.0, controlled_player.maximum_shot_force)
	)
	var minimum_speed = controlled_player.minimum_shot_force * multiplier
	var maximum_speed = controlled_player.maximum_shot_force * multiplier
	var ratio = inverse_lerp(minimum_speed, maximum_speed, required_speed)
	return clampf(
		ratio,
		0.0,
		1.0
	) * controlled_player.cpu_get_maximum_shot_charge_seconds()


func _get_double_bank_route_clearance(route: Dictionary) -> float:
	var goalkeeper = match_manager.get_designated_cpu_goalkeeper(
		TEAM_RED
		if controlled_player.team == TEAM_BLUE
		else TEAM_BLUE
	)
	var bounce_one: Vector2 = route.get(
		"bounce_one",
		ball.global_position
	)
	var bounce_two: Vector2 = route.get(
		"bounce_two",
		ball.global_position
	)
	var goal_position: Vector2 = route.get(
		"goal_position",
		ball.global_position
	)
	var points: Array[Vector2] = [
		ball.global_position,
		bounce_one,
		bounce_two,
		goal_position
	]
	var clearance = INF
	for opponent in _get_opponents():
		if (
			not is_instance_valid(opponent)
			or not opponent.controls_enabled
			or opponent == goalkeeper
		):
			continue
		for point_index in range(points.size() - 1):
			clearance = minf(
				clearance,
				_distance_to_segment(
					opponent.global_position,
					points[point_index],
					points[point_index + 1]
				) - _get_ability_interception_bonus(opponent)
			)
	return clearance


func _get_double_bank_goalkeeper_clearance(
	route: Dictionary,
	opponent_goal: FootballGoal
) -> float:
	var goalkeeper = match_manager.get_designated_cpu_goalkeeper(
		TEAM_RED
		if controlled_player.team == TEAM_BLUE
		else TEAM_BLUE
	)
	if not is_instance_valid(goalkeeper):
		return INF
	var goal_position: Vector2 = route.get(
		"goal_position",
		_get_goal_center(opponent_goal)
	)
	var predicted_y = (
		goalkeeper.global_position
		+ goalkeeper.linear_velocity * minf(
			1.25,
			float(route.get("travel_time", 0.0))
		)
	).y
	return absf(goal_position.y - predicted_y)


func _double_bank_route_beats_other_shots(
	route: Dictionary,
	direct_goal_target: Vector2
) -> bool:
	var direct_value = (
		_minimum_segment_clearance(
			ball.global_position,
			direct_goal_target
		) - ball.global_position.distance_to(direct_goal_target)
		* wall_route_length_penalty
	)
	var single_wall_value = -INF
	var single_wall_route = _get_best_wall_route(direct_goal_target)
	if not single_wall_route.is_empty():
		single_wall_value = (
			float(single_wall_route.get("clearance", 0.0))
			- float(single_wall_route.get("distance", 0.0))
			* wall_route_length_penalty
		)
	return float(route.get("value", -INF)) >= maxf(
		direct_value,
		single_wall_value
	) + maxf(0.0, double_bank_value_advantage)


func _plan_double_bank_shot(
	route: Dictionary,
	goal_target: Vector2
) -> void:
	_planned_destination = route.get("goal_position", goal_target)
	_shot_target = route.get("bounce_one", goal_target)
	_planned_route_distance = float(route.get(
		"distance",
		ball.global_position.distance_to(_shot_target)
	))
	_plan_uses_wall = true
	_plan_uses_double_bank = true
	_double_bank_required_charge_seconds = float(route.get(
		"charge_seconds",
		0.0
	))
	_begin_double_bank_debug_route(route, "planned")


func _begin_double_bank_debug_route(route: Dictionary, reason: String) -> void:
	if not double_bank_debug_overlay_enabled:
		return
	_ensure_double_bank_debug_overlay()
	if _double_bank_debug_overlay == null:
		return
	var bounce_one: Vector2 = route.get("bounce_one", ball.global_position)
	var bounce_two: Vector2 = route.get("bounce_two", bounce_one)
	var goal_position: Vector2 = route.get("goal_position", bounce_two)
	var points = PackedVector2Array([
		ball.global_position,
		bounce_one,
		bounce_two,
		goal_position
	])
	_double_bank_debug_predicted_line.points = points
	_double_bank_debug_actual_line.clear_points()
	_double_bank_debug_actual_points = PackedVector2Array([ball.global_position])
	_double_bank_debug_bounce_markers.points = PackedVector2Array([
		bounce_one + Vector2(-42.0, -42.0),
		bounce_one + Vector2(42.0, 42.0),
		bounce_two + Vector2(-42.0, 42.0),
		bounce_two + Vector2(42.0, -42.0)
	])
	_double_bank_debug_label.text = "DOUBLE BANK: %s" % reason.to_upper()
	_double_bank_debug_label.global_position = ball.global_position + Vector2(40.0, -135.0)
	_double_bank_debug_overlay.show()


func set_double_bank_debug_rejection(reason: String) -> void:
	if not double_bank_debug_overlay_enabled:
		return
	_ensure_double_bank_debug_overlay()
	if _double_bank_debug_overlay == null:
		return
	_double_bank_debug_predicted_line.clear_points()
	_double_bank_debug_actual_line.clear_points()
	_double_bank_debug_bounce_markers.clear_points()
	_double_bank_debug_label.text = "DOUBLE BANK REJECTED: %s" % reason
	_double_bank_debug_label.global_position = (
		ball.global_position + Vector2(40.0, -135.0)
	)
	_double_bank_debug_overlay.show()


func _record_double_bank_debug_trajectory() -> void:
	if (
		not double_bank_debug_overlay_enabled
		or _double_bank_debug_overlay == null
		or not _double_bank_debug_overlay.visible
		or ball == null
	):
		return
	if ball.linear_velocity.length() < 180.0:
		return
	if _double_bank_debug_actual_points.size() >= maxi(
		2,
		double_bank_debug_maximum_points
	):
		return
	if (
		not _double_bank_debug_actual_points.is_empty()
		and _double_bank_debug_actual_points[
			_double_bank_debug_actual_points.size() - 1
		].distance_to(ball.global_position) < 8.0
	):
		return
	_double_bank_debug_actual_points.append(ball.global_position)
	_double_bank_debug_actual_line.points = _double_bank_debug_actual_points


func _ensure_double_bank_debug_overlay() -> void:
	if _double_bank_debug_overlay != null:
		return
	if match_manager == null or not match_manager.get_parent() is Node2D:
		return
	var field = match_manager.get_parent() as Node2D
	_double_bank_debug_overlay = Node2D.new()
	_double_bank_debug_overlay.name = "CPUDoubleBankDebugOverlay"
	_double_bank_debug_overlay.z_index = 30
	field.add_child(_double_bank_debug_overlay)
	_double_bank_debug_predicted_line = Line2D.new()
	_double_bank_debug_predicted_line.width = 13.0
	_double_bank_debug_predicted_line.default_color = Color(0.15, 0.9, 1.0, 0.88)
	_double_bank_debug_predicted_line.antialiased = true
	_double_bank_debug_overlay.add_child(_double_bank_debug_predicted_line)
	_double_bank_debug_actual_line = Line2D.new()
	_double_bank_debug_actual_line.width = 9.0
	_double_bank_debug_actual_line.default_color = Color(1.0, 0.56, 0.12, 0.92)
	_double_bank_debug_actual_line.antialiased = true
	_double_bank_debug_overlay.add_child(_double_bank_debug_actual_line)
	_double_bank_debug_bounce_markers = Line2D.new()
	_double_bank_debug_bounce_markers.width = 16.0
	_double_bank_debug_bounce_markers.default_color = Color(1.0, 0.92, 0.18, 0.98)
	_double_bank_debug_bounce_markers.antialiased = true
	_double_bank_debug_overlay.add_child(_double_bank_debug_bounce_markers)
	_double_bank_debug_label = Label.new()
	_double_bank_debug_label.add_theme_font_size_override("font_size", 24)
	_double_bank_debug_label.add_theme_color_override(
		"font_color",
		Color(1.0, 0.92, 0.42, 1.0)
	)
	_double_bank_debug_label.add_theme_color_override(
		"font_outline_color",
		Color(0.0, 0.0, 0.0, 1.0)
	)
	_double_bank_debug_label.add_theme_constant_override("outline_size", 6)
	_double_bank_debug_overlay.add_child(_double_bank_debug_label)


func _distance_to_segment(
	point: Vector2,
	segment_start: Vector2,
	segment_end: Vector2
) -> float:
	var segment = segment_end - segment_start
	var length_squared = segment.length_squared()
	if length_squared <= 0.001:
		return point.distance_to(segment_start)
	var ratio = clampf(
		(point - segment_start).dot(segment) / length_squared,
		0.0,
		1.0
	)
	return point.distance_to(segment_start + segment * ratio)


func _team_likely_has_possession() -> bool:
	var parallel_plan := _get_large_team_parallel_plan()
	if not parallel_plan.is_empty() and parallel_plan.has("team_has_possession"):
		return bool(parallel_plan.get("team_has_possession", false))
	var stable_team = match_manager.get_cpu_possession_team()
	if stable_team in [
		TEAM_BLUE,
		TEAM_RED
	]:
		return stable_team == controlled_player.team
	var opponent_team := TEAM_RED if controlled_player.team == TEAM_BLUE else TEAM_BLUE
	var own_distance: float = (
		match_manager.get_cpu_shared_nearest_ball_distance(controlled_player.team)
		if match_manager.has_method("get_cpu_shared_nearest_ball_distance")
		else _nearest_team_distance_to_ball(_get_teammates())
	)
	var opponent_distance: float = (
		match_manager.get_cpu_shared_nearest_ball_distance(opponent_team)
		if match_manager.has_method("get_cpu_shared_nearest_ball_distance")
		else _nearest_team_distance_to_ball(_get_opponents())
	)
	if own_distance + possession_distance_advantage <= opponent_distance:
		return true
	for teammate in _get_teammates():
		if (
			is_instance_valid(teammate)
			and teammate.owner_peer_id == ball.last_touch_peer_id
		):
			return own_distance + 40.0 <= opponent_distance
	return false


func _nearest_team_distance_to_ball(
	players: Array[FootballPlayer]
) -> float:
	var nearest = INF
	for player in players:
		if is_instance_valid(player) and player.controls_enabled:
			nearest = minf(
				nearest,
				player.global_position.distance_to(ball.global_position)
			)
	return nearest


func _nearest_team_distance_to_position(
	players: Array[FootballPlayer],
	position: Vector2
) -> float:
	var nearest = INF
	for player in players:
		if is_instance_valid(player) and player.controls_enabled:
			nearest = minf(
				nearest,
				player.global_position.distance_to(position)
			)
	return nearest


func _select_marking_target() -> FootballPlayer:
	var own_goal = _get_own_goal()
	if own_goal == null:
		return null
	var best_target: FootballPlayer
	var best_score = INF
	var opponent_carrier = _get_likely_opponent_ball_carrier()
	var committed_chaser = match_manager.get_cpu_ball_chaser(
		controlled_player.team
	)
	for opponent in _get_opponents():
		if (
			not is_instance_valid(opponent)
			or not opponent.controls_enabled
			or (
				committed_chaser > 0
				and opponent == opponent_carrier
			)
			or (
				_is_designated_goalkeeper(opponent)
			)
		):
			continue
		var goal_threat = opponent.global_position.distance_to(
			_get_goal_center(own_goal)
		)
		var ball_relevance = opponent.global_position.distance_to(
			ball.global_position
		)
		var marking_travel = controlled_player.global_position.distance_to(
			opponent.global_position
		)
		var score = (
			goal_threat * 0.42
			+ ball_relevance * 0.24
			+ marking_travel * 0.34
		)
		score -= _get_player_ability_threat(opponent)
		var opponent_intention = _get_effective_player_intention(opponent)
		var opponent_action = StringName(
			opponent_intention.get("action", &"")
		)
		if opponent_action in [
			INTENT_RECEIVE,
			INTENT_FORWARD_RUN,
			INTENT_SHOOT
		]:
			score -= 360.0
		if not _is_closest_available_marker(opponent):
			score += 1600.0
		if _teammate_intends_to_mark(opponent.owner_peer_id):
			score += 1250.0
		if score < best_score:
			best_score = score
			best_target = opponent
	return best_target


func _teammate_intends_to_mark(opponent_peer_id: int) -> bool:
	for intention in match_manager.get_cpu_team_intentions(
		controlled_player.team
	):
		if (
			int(intention.get("peer_id", 0))
			!= controlled_player.owner_peer_id
			and StringName(intention.get("action", &"")) == INTENT_MARK
			and int(intention.get("target_peer_id", 0)) == opponent_peer_id
		):
			return true
	return false


func _is_closest_available_marker(opponent: FootballPlayer) -> bool:
	var own_distance = controlled_player.global_position.distance_squared_to(
		opponent.global_position
	)
	for teammate in _get_teammates():
		if (
			not is_instance_valid(teammate)
			or teammate == controlled_player
			or not teammate.controls_enabled
			or _is_designated_goalkeeper(teammate)
		):
			continue
		if (
			teammate.owner_peer_id
			== match_manager.get_cpu_ball_chaser(controlled_player.team)
		):
			continue
		var teammate_distance = teammate.global_position.distance_squared_to(
			opponent.global_position
		)
		if (
			teammate_distance < own_distance
			or (
				is_equal_approx(teammate_distance, own_distance)
				and teammate.owner_peer_id < controlled_player.owner_peer_id
			)
		):
			return false
	return true


func _nearest_opponent_distance(position: Vector2) -> float:
	# Ball pressure is one of the hottest repeated spatial queries and is already
	# captured by the Part 1 world model once per physics frame. Arbitrary points
	# keep the original direct scan: with only six opponents that is cheaper than
	# dictionary-cache overhead unless the point is genuinely team-shared.
	if (
		match_manager != null
		and controlled_player != null
		and ball != null
		and position == ball.global_position
		and match_manager.has_method("get_cpu_shared_nearest_ball_distance")
	):
		var opponent_team := TEAM_RED if controlled_player.team == TEAM_BLUE else TEAM_BLUE
		return match_manager.get_cpu_shared_nearest_ball_distance(opponent_team)
	var nearest = INF
	for opponent in _get_opponents():
		if is_instance_valid(opponent) and opponent.controls_enabled:
			nearest = minf(
				nearest,
				opponent.global_position.distance_to(position)
			)
	return nearest


func _get_nearest_opponent_to(
	position: Vector2
) -> FootballPlayer:
	var nearest_opponent: FootballPlayer
	var nearest_distance = INF
	for opponent in _get_opponents():
		if not is_instance_valid(opponent) or not opponent.controls_enabled:
			continue
		var distance = opponent.global_position.distance_squared_to(
			position
		)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_opponent = opponent
	return nearest_opponent


func _get_teammates() -> Array[FootballPlayer]:
	return (
		match_manager.blue_players
		if controlled_player.team == TEAM_BLUE
		else match_manager.red_players
	)


func _team_has_selected_ability(ability_id: int) -> bool:
	for teammate in _get_teammates():
		if (
			is_instance_valid(teammate)
			and teammate.controls_enabled
			and teammate.selected_ability == ability_id
		):
			return true
	return false


func _get_opponents() -> Array[FootballPlayer]:
	return (
		match_manager.red_players
		if controlled_player.team == TEAM_BLUE
		else match_manager.blue_players
	)


func _get_local_duel_opponent() -> FootballPlayer:
	if (
		not is_instance_valid(controlled_player)
		or not is_instance_valid(ball)
		or controlled_player.server_is_charging
	):
		return null
	var owns_recent_touch = (
		ball.last_touch_peer_id == controlled_player.owner_peer_id
	)
	if not _team_likely_has_possession() and not owns_recent_touch:
		return null
	if (
		controlled_player.global_position.distance_to(ball.global_position)
		> controlled_player.kick_feedback_detection_distance * 1.18
		or ball.linear_velocity.length()
		> maxf(250.0, local_duel_maximum_ball_speed)
	):
		return null
	var nearest_opponent: FootballPlayer
	var nearest_distance = INF
	var second_distance = INF
	for opponent in _get_opponents():
		if not is_instance_valid(opponent) or not opponent.controls_enabled:
			continue
		var distance = opponent.global_position.distance_to(
			ball.global_position
		)
		if distance < nearest_distance:
			second_distance = nearest_distance
			nearest_distance = distance
			nearest_opponent = opponent
		elif distance < second_distance:
			second_distance = distance
	if (
		nearest_opponent == null
		or nearest_distance > maxf(250.0, local_duel_detection_radius)
	):
		return null
	if (
		second_distance <= local_duel_detection_radius * 1.15
		and second_distance
		< nearest_distance + maxf(100.0, local_duel_second_defender_margin)
	):
		# Two defenders can close the ball together. Let the contested-ball and
		# team-play systems handle that rather than pretending it is a duel.
		return null
	return nearest_opponent


func _get_relevant_duel_opponent() -> FootballPlayer:
	var true_one_vs_one_opponent = _get_one_vs_one_opponent()
	if true_one_vs_one_opponent != null:
		return true_one_vs_one_opponent
	return _get_local_duel_opponent()


func _should_commit_local_duel_dribble(
	opponent_goal: FootballGoal,
	now: float
) -> bool:
	var opponent = _get_local_duel_opponent()
	if opponent == null:
		return false
	if now < _solo_attack_until:
		if (
			controlled_player.selected_ability in [
				FootballPlayer.ABILITY_POWER_STRIKE,
				FootballPlayer.ABILITY_QUICK_TRIGGER
			]
			and _cpu_ability_is_ready()
			and _shot_ability_is_useful(controlled_player.selected_ability)
		):
			_dribble_until = 0.0
			_clear_solo_attack_state()
			return false
		return true
	var goal_center = _get_goal_center(opponent_goal)
	var goal_distance = ball.global_position.distance_to(goal_center)
	var goal_lane = _minimum_segment_clearance(
		ball.global_position,
		goal_center
	)
	if (
		goal_distance < dribble_minimum_goal_distance
		and goal_lane >= maxf(140.0, elite_minimum_shot_lane * 0.58)
	):
		return false
	var opponent_distance = opponent.global_position.distance_to(
		ball.global_position
	)
	var pressure_ratio = 1.0 - clampf(
		opponent_distance / maxf(1.0, local_duel_detection_radius),
		0.0,
		1.0
	)
	var forward = ball.global_position.direction_to(goal_center)
	if forward.is_zero_approx():
		forward = Vector2(_get_attack_sign(), 0.0)
	var defender_direction = ball.global_position.direction_to(
		opponent.global_position
	)
	var blocks_goalward_lane = maxf(
		0.0,
		forward.dot(defender_direction)
	)
	var commit_chance = maxf(
		dribble_choice_chance,
		local_duel_minimum_dribble_chance
	)
	commit_chance += pressure_ratio * local_duel_pressure_chance_bonus
	commit_chance += blocks_goalward_lane * 0.12
	var local_team_size: int = _get_checkpoint_team_player_count()
	if local_team_size >= 3 and _has_other_active_teammate():
		# The old local-duel floor (>= 0.62 before pressure bonuses) was the main
		# reason 3v3/4v4 carriers kept choosing another dribble despite having
		# teammates, shots and abilities available. Dense modes should still beat
		# a defender when it is valuable, but solo duels are no longer the default.
		commit_chance *= 0.62 if local_team_size == 3 else 0.46
		if controlled_player.selected_ability in [
			FootballPlayer.ABILITY_BURST_DRIBBLE,
			FootballPlayer.ABILITY_ELASTIC_STEP,
			FootballPlayer.ABILITY_BLIND_SPOT,
			FootballPlayer.ABILITY_BREAKAWAY,
			FootballPlayer.ABILITY_NUTMEG
		]:
			commit_chance += 0.10
		elif (
			controlled_player.selected_ability in [
				FootballPlayer.ABILITY_POWER_STRIKE,
				FootballPlayer.ABILITY_QUICK_TRIGGER,
				FootballPlayer.ABILITY_TIME_SKIP_PASS
			]
			and _cpu_ability_is_ready()
		):
			commit_chance *= 0.58
	if controlled_player.selected_ability in [
		FootballPlayer.ABILITY_BURST_DRIBBLE,
		FootballPlayer.ABILITY_ELASTIC_STEP,
		FootballPlayer.ABILITY_BLIND_SPOT
	]:
		commit_chance += 0.1
	commit_chance = clampf(commit_chance, 0.05, 0.96)
	if _rng.randf() > commit_chance:
		return false
	_begin_solo_attack(
		opponent_goal,
		opponent,
		now,
		maxf(local_duel_commit_seconds, dribble_commit_seconds)
	)
	return true


func _begin_solo_attack(
	opponent_goal: FootballGoal,
	opponent: FootballPlayer,
	now: float,
	duration: float
) -> void:
	_solo_attack_until = now + maxf(0.25, duration)
	_solo_attack_defender_peer_id = opponent.owner_peer_id
	_solo_attack_direction = _select_committed_solo_direction(
		opponent_goal,
		opponent
	)
	_solo_attack_direction_lock_until = (
		now + maxf(0.12, local_duel_direction_lock_seconds)
	)
	_dribble_until = maxf(_dribble_until, _solo_attack_until)
	_wall_dribble_until = 0.0
	_wall_dribble_kicked = false


func _refresh_solo_attack_state() -> void:
	if _solo_attack_until <= 0.0:
		return
	var now = _server_time_seconds()
	if now >= _solo_attack_until:
		_clear_solo_attack_state()
		return
	var owns_recent_touch = (
		ball.last_touch_peer_id == controlled_player.owner_peer_id
	)
	if (
		(not _team_likely_has_possession() and not owns_recent_touch)
		or controlled_player.global_position.distance_to(ball.global_position)
		> controlled_player.kick_feedback_detection_distance * 1.72
		or ball.linear_velocity.length()
		> maxf(700.0, local_duel_maximum_ball_speed * 1.35)
	):
		_dribble_until = minf(_dribble_until, now)
		_clear_solo_attack_state()


func _clear_solo_attack_state() -> void:
	_solo_attack_until = 0.0
	_solo_attack_direction_lock_until = 0.0
	_solo_attack_direction = Vector2.ZERO
	_solo_attack_defender_peer_id = 0


func _get_solo_attack_defender() -> FootballPlayer:
	if _solo_attack_defender_peer_id > 0:
		for opponent in _get_opponents():
			if (
				is_instance_valid(opponent)
				and opponent.controls_enabled
				and opponent.owner_peer_id
				== _solo_attack_defender_peer_id
			):
				return opponent
	return _get_relevant_duel_opponent()


func _select_committed_solo_direction(
	opponent_goal: FootballGoal,
	opponent: FootballPlayer
) -> Vector2:
	var forward = ball.global_position.direction_to(
		_get_goal_center(opponent_goal)
	)
	if forward.is_zero_approx():
		forward = Vector2(_get_attack_sign(), 0.0)
	if (
		controlled_player.selected_ability
		== FootballPlayer.ABILITY_ELASTIC_STEP
		and controlled_player.global_position.distance_to(
			opponent.global_position
		) <= maxf(300.0, one_vs_one_elastic_pressure_distance)
	):
		var elastic_direction = _get_elastic_escape_direction()
		return (elastic_direction * 0.82 + forward * 0.56).normalized()
	if (
		controlled_player.selected_ability
		== FootballPlayer.ABILITY_POWER_STRIKE
		and _one_vs_one_power_opening_is_needed(opponent_goal)
	):
		return _get_one_vs_one_power_opening_direction(
			opponent_goal,
			opponent
		)
	return _select_solo_attack_direction(opponent_goal, opponent)


func _select_solo_attack_direction(
	opponent_goal: FootballGoal,
	opponent: FootballPlayer
) -> Vector2:
	var bypass_target: Vector2 = _get_one_vs_one_bypass_target(
		opponent_goal,
		opponent
	)
	var bypass_direction: Vector2 = ball.global_position.direction_to(
		bypass_target
	)
	if not bypass_direction.is_zero_approx():
		return bypass_direction
	var goal_center = _get_goal_center(opponent_goal)
	var forward = ball.global_position.direction_to(goal_center)
	if forward.is_zero_approx():
		forward = Vector2(_get_attack_sign(), 0.0)
	var lateral = Vector2(-forward.y, forward.x)
	var away = opponent.global_position.direction_to(ball.global_position)
	var candidates: Array[Vector2] = [
		forward,
		(forward * 0.92 + lateral * 0.38).normalized(),
		(forward * 0.92 - lateral * 0.38).normalized(),
		(forward * 0.78 + lateral * 0.62).normalized(),
		(forward * 0.78 - lateral * 0.62).normalized(),
		(forward * 0.74 + away * 0.58).normalized()
	]
	var predicted_opponent = (
		opponent.global_position + opponent.linear_velocity * 0.24
	)
	var probe_distance = clampf(
		local_duel_probe_distance,
		420.0,
		760.0
	)
	var best_direction = forward
	var best_score = -INF
	for candidate in candidates:
		if candidate.is_zero_approx():
			continue
		var raw_target = ball.global_position + candidate * probe_distance
		var target = _clamp_to_field(raw_target)
		var progress = (
			target.x - ball.global_position.x
		) * _get_attack_sign()
		var defender_line_clearance = _distance_to_segment(
			predicted_opponent,
			ball.global_position,
			target
		)
		var route_clearance = minf(
			_minimum_segment_clearance(ball.global_position, target),
			1600.0
		)
		var scoring_lane = minf(
			_minimum_segment_clearance(target, goal_center),
			1600.0
		)
		var defender_target_distance = predicted_opponent.distance_to(target)
		var wall_margin = minf(
			target.y - minimum_field_y,
			maximum_field_y - target.y
		)
		var clamp_penalty = raw_target.distance_to(target)
		var movement_read = -candidate.y * opponent.linear_velocity.y * 0.16
		var own_arrival = _estimate_duel_player_arrival_seconds(
			controlled_player,
			target
		)
		var opponent_arrival = _estimate_duel_player_arrival_seconds(
			opponent,
			target
		)
		var retention_margin = opponent_arrival - own_arrival
		var predicted_player = (
			controlled_player.global_position
			+ controlled_player.linear_velocity * 0.22
		)
		var next_touch_distance = predicted_player.distance_to(target)
		var lateral_commitment = absf(candidate.dot(lateral))
		var score = (
			progress * 0.82
			+ defender_line_clearance * 1.06
			+ route_clearance * 0.52
			+ scoring_lane * 0.34
			+ defender_target_distance * 0.24
			+ minf(wall_margin, 700.0) * 0.14
			+ retention_margin * 980.0
			+ movement_read
			- next_touch_distance * 0.42
			- lateral_commitment * 120.0
			- clamp_penalty * 1.8
		)
		if opponent_arrival <= own_arrival + 0.05:
			score -= 620.0
		if progress < 80.0:
			score -= (80.0 - progress) * 1.35
		if score > best_score:
			best_score = score
			best_direction = candidate
	return best_direction.normalized()


func _on_ball_player_touch_registered(
	peer_id: int,
	_player_name: String,
	player_team: StringName,
	incoming_velocity: Vector2
) -> void:
	if (
		peer_id <= 0
		or not is_instance_valid(controlled_player)
		or not is_instance_valid(ball)
		or player_team not in [
			TEAM_BLUE,
			TEAM_RED
		]
	):
		return
	if not _cpu_first_touch_plan.is_empty():
		var first_touch_source = int(
			_cpu_first_touch_plan.get("source_peer_id", 0)
		)
		if (
			peer_id == controlled_player.owner_peer_id
			or peer_id != first_touch_source
		):
			_clear_cpu_first_touch_plan()
	var now = _server_time_seconds()
	if peer_id == controlled_player.owner_peer_id:
		_last_controlled_ball_touch_at = now
		var nominal_goalkeeper = match_manager.get_designated_cpu_goalkeeper(
			controlled_player.team
		)
		var own_goal = _get_own_goal()
		var incoming_toward_own_goal = false
		if own_goal != null and not incoming_velocity.is_zero_approx():
			var toward_goal = ball.global_position.direction_to(
				_get_goal_center(own_goal)
			)
			incoming_toward_own_goal = (
				not toward_goal.is_zero_approx()
				and incoming_velocity.normalized().dot(toward_goal) > 0.22
			)
		if (
			nominal_goalkeeper == controlled_player
			or incoming_toward_own_goal
			or now - _last_opponent_ball_touch_at <= 1.8
		):
			_last_secure_recovery_at = now
		if (
			_last_opponent_ball_touch_peer_id > 0
			and now - _last_opponent_ball_touch_at
			<= maxf(0.05, duel_touch_window_seconds)
		):
			_try_begin_duel_resolution(
				_last_opponent_ball_touch_peer_id,
				now
			)
		return
	if player_team == controlled_player.team:
		return
	_last_opponent_ball_touch_at = now
	_last_opponent_ball_touch_peer_id = peer_id
	var recent_controlled_touch = (
		now - _last_controlled_ball_touch_at
		<= maxf(0.05, duel_touch_window_seconds)
	)
	var interrupted_solo_attack = now < _solo_attack_until
	var touching_opponent = _get_opponent_by_peer_id(peer_id)
	var near_contested_ball = false
	if touching_opponent != null:
		var own_contest_radius = maxf(
			controlled_player.kick_feedback_detection_distance * 1.9,
			340.0
		)
		var opponent_contest_radius = maxf(
			touching_opponent.kick_feedback_detection_distance * 1.55,
			300.0
		)
		near_contested_ball = (
			controlled_player.global_position.distance_to(ball.global_position)
			<= own_contest_radius
			and touching_opponent.global_position.distance_to(
				ball.global_position
			) <= opponent_contest_radius
		)
	if (
		recent_controlled_touch
		or interrupted_solo_attack
		or near_contested_ball
	):
		_try_begin_duel_resolution(peer_id, now)


func _try_begin_duel_resolution(
	opponent_peer_id: int,
	now: float
) -> void:
	var opponent = _get_opponent_by_peer_id(opponent_peer_id)
	if opponent == null:
		return
	var detection_radius = maxf(
		controlled_player.kick_feedback_detection_distance * 1.35,
		duel_contact_detection_radius
	)
	if (
		controlled_player.global_position.distance_to(ball.global_position)
		> detection_radius
		or opponent.global_position.distance_to(ball.global_position)
		> detection_radius
	):
		return
	_duel_resolution_until = maxf(
		_duel_resolution_until,
		now + maxf(0.2, duel_resolution_seconds)
	)
	_duel_resolution_opponent_peer_id = opponent_peer_id
	_duel_resolution_outcome = &"contested"
	_duel_resolution_target = ball.global_position
	_cancel_stale_duel_plans()


func _cancel_stale_duel_plans() -> void:
	if controlled_player.server_is_charging:
		controlled_player.cpu_cancel_shot_charge()
		_reset_cpu_charge_tracking()
	_clear_attack_plan()
	_clear_solo_attack_state()
	_dribble_until = 0.0
	_clear_wall_dribble_state()
	_contest_yield_until = 0.0
	_planned_support_until = 0.0
	_planned_support_position = Vector2.ZERO
	_planned_support_intent = INTENT_IDLE


func _refresh_duel_resolution_state() -> void:
	if _duel_resolution_until <= 0.0:
		return
	var now = _server_time_seconds()
	var opponent = _get_duel_resolution_opponent()
	if (
		now >= _duel_resolution_until
		or opponent == null
		or not opponent.controls_enabled
	):
		_clear_duel_resolution_state()
		return
	var maximum_relevant_distance = maxf(
		duel_contact_detection_radius * 3.0,
		controlled_player.kick_feedback_detection_distance * 5.0
	)
	if (
		controlled_player.global_position.distance_to(ball.global_position)
		> maximum_relevant_distance
		and opponent.global_position.distance_to(ball.global_position)
		> maximum_relevant_distance
	):
		_clear_duel_resolution_state()


func _clear_duel_resolution_state() -> void:
	_duel_resolution_until = 0.0
	_duel_resolution_opponent_peer_id = 0
	_duel_resolution_outcome = &""
	_duel_resolution_target = Vector2.ZERO


func _get_duel_resolution_opponent() -> FootballPlayer:
	if _duel_resolution_opponent_peer_id <= 0:
		return null
	return _get_opponent_by_peer_id(_duel_resolution_opponent_peer_id)


func _update_duel_resolution_decision() -> bool:
	if _duel_resolution_until <= _server_time_seconds():
		return false
	var opponent = _get_duel_resolution_opponent()
	if opponent == null:
		_clear_duel_resolution_state()
		return false
	var own_goal = _get_own_goal()
	if (
		_is_designated_goalkeeper(controlled_player)
		and own_goal != null
		and not _predict_own_goal_threat(1.25).is_empty()
	):
		# A goal-bound shot outranks a loose-ball duel. The normal goalkeeper
		# branch has the exact crossing-line positioning for this case.
		_clear_duel_resolution_state()
		return false
	var interception = _get_duel_interception_data(opponent)
	var intercept_position: Vector2 = interception.get(
		"position",
		_get_predicted_ball_position()
	)
	var own_arrival = float(interception.get("own_arrival", INF))
	var opponent_arrival = float(interception.get("opponent_arrival", INF))
	var outcome = _classify_duel_outcome(
		opponent,
		own_arrival,
		opponent_arrival
	)
	_duel_resolution_outcome = outcome
	match outcome:
		&"won":
			if (
				ball.last_touch_peer_id == controlled_player.owner_peer_id
				and controlled_player.cpu_has_kickable_ball()
			):
				_clear_duel_resolution_state()
				return false
			_duel_resolution_target = intercept_position
			_movement_target = intercept_position
			_set_tactical_intent(INTENT_CHASE, _movement_target)
			return true
		&"lost":
			if (
				own_arrival
				<= opponent_arrival
				+ maxf(0.05, duel_rechallenge_margin_seconds)
			):
				_duel_resolution_target = _get_duel_challenge_position(
					intercept_position,
					opponent
				)
				_movement_target = _duel_resolution_target
				_set_tactical_intent(
					INTENT_CHASE,
					_movement_target,
					opponent.owner_peer_id
				)
				_try_duel_control_touch(opponent)
				return true
			var predictive_recovery = Vector2.ZERO
			if own_goal != null:
				predictive_recovery = _get_anticipatory_goal_defense_position(
					opponent,
					own_goal,
					_is_designated_goalkeeper(controlled_player)
				)
			_duel_resolution_target = (
				predictive_recovery
				if not predictive_recovery.is_zero_approx()
				else _get_duel_goal_side_recovery_position(
					opponent,
					intercept_position
				)
			)
			_movement_target = _duel_resolution_target
			_set_tactical_intent(
				INTENT_MARK,
				_movement_target,
				opponent.owner_peer_id
			)
			return true
		_:
			var opponent_goal = _get_opponent_goal()
			if (
				opponent_goal != null
				and controlled_player.cpu_has_kickable_ball()
				and _try_break_contested_ball_brawl(opponent_goal)
			):
				_clear_duel_resolution_state()
				return true
			_duel_resolution_target = _get_duel_challenge_position(
				intercept_position,
				opponent
			)
			_movement_target = _duel_resolution_target
			_set_tactical_intent(
				INTENT_CHASE,
				_movement_target,
				opponent.owner_peer_id
			)
			_try_duel_control_touch(opponent)
			return true


func _classify_duel_outcome(
	opponent: FootballPlayer,
	own_arrival: float,
	opponent_arrival: float
) -> StringName:
	var own_ball_distance = controlled_player.global_position.distance_to(
		ball.global_position
	)
	var opponent_ball_distance = opponent.global_position.distance_to(
		ball.global_position
	)
	var own_control_distance = (
		controlled_player.kick_feedback_detection_distance * 1.12
	)
	var opponent_control_distance = (
		opponent.kick_feedback_detection_distance * 1.12
	)
	var own_has_control = (
		ball.last_touch_peer_id == controlled_player.owner_peer_id
		and own_ball_distance <= own_control_distance
	)
	var opponent_has_control = (
		ball.last_touch_peer_id == opponent.owner_peer_id
		and opponent_ball_distance <= opponent_control_distance
	)
	if (
		own_has_control
		and own_arrival
		<= opponent_arrival + maxf(0.02, duel_equal_arrival_margin_seconds)
	):
		return &"won"
	if (
		opponent_has_control
		and opponent_arrival
		+ maxf(0.05, duel_clear_loss_margin_seconds)
		< own_arrival
	):
		return &"lost"
	if (
		own_arrival + maxf(0.05, duel_clear_loss_margin_seconds)
		< opponent_arrival
	):
		return &"won"
	if (
		opponent_arrival + maxf(0.05, duel_clear_loss_margin_seconds)
		< own_arrival
	):
		return &"lost"
	return &"contested"


func _get_duel_interception_data(
	opponent: FootballPlayer
) -> Dictionary:
	# Part 2 shares the deterministic ball trajectory across every CPU in this
	# physics frame. Arrival evaluation stays per player, but now uses the exact
	# O(1) spatial solver rather than the old 12-iteration binary search.
	if (
		match_manager != null
		and is_instance_valid(opponent)
		and is_equal_approx(duel_prediction_step_seconds, 0.08)
		and is_equal_approx(duel_prediction_horizon_seconds, 1.25)
		and is_equal_approx(ball_wall_top_y, 806.0)
		and is_equal_approx(ball_wall_bottom_y, 4194.0)
		and is_equal_approx(minimum_field_x, 360.0)
		and is_equal_approx(maximum_field_x, 6970.0)
		and is_equal_approx(minimum_field_y, 680.0)
		and is_equal_approx(maximum_field_y, 4320.0)
		and match_manager.has_method("get_cpu_shared_ball_trajectory")
	):
		var shared_trajectory := match_manager.get_cpu_shared_ball_trajectory() as Array
		if not shared_trajectory.is_empty():
			var best_data: Dictionary = {}
			for sample_variant in shared_trajectory:
				var sample := sample_variant as Dictionary
				var elapsed := float(sample.get("seconds", 0.0))
				best_data = _make_duel_interception_data(
					opponent,
					sample.get("position", ball.global_position) as Vector2,
					elapsed
				)
				if elapsed <= 0.0:
					continue
				var first_arrival := minf(
					float(best_data.get("own_arrival", INF)),
					float(best_data.get("opponent_arrival", INF))
				)
				if first_arrival <= elapsed + 0.08:
					break
				if float(sample.get("speed", 0.0)) < 45.0:
					break
			if not best_data.is_empty():
				return best_data
	var step_seconds = maxf(0.04, duel_prediction_step_seconds)
	var horizon_seconds = maxf(
		step_seconds,
		duel_prediction_horizon_seconds
	)
	var predicted_position = ball.global_position
	var predicted_velocity = ball.linear_velocity
	var damping = maxf(0.0, ball.linear_damp)
	var elapsed = 0.0
	var best_data = _make_duel_interception_data(
		opponent,
		predicted_position,
		0.0
	)
	while elapsed < horizon_seconds:
		var current_step = minf(
			step_seconds,
			horizon_seconds - elapsed
		)
		if damping > 0.001:
			predicted_velocity *= exp(-damping * current_step)
		predicted_position += predicted_velocity * current_step
		if predicted_position.y < ball_wall_top_y:
			predicted_position.y = (
				ball_wall_top_y
				+ (ball_wall_top_y - predicted_position.y)
			)
			predicted_velocity.y = absf(predicted_velocity.y) * 0.8
		elif predicted_position.y > ball_wall_bottom_y:
			predicted_position.y = (
				ball_wall_bottom_y
				- (predicted_position.y - ball_wall_bottom_y)
			)
			predicted_velocity.y = -absf(predicted_velocity.y) * 0.8
		predicted_position = _clamp_to_field(predicted_position)
		elapsed += current_step
		best_data = _make_duel_interception_data(
			opponent,
			predicted_position,
			elapsed
		)
		var first_arrival = minf(
			float(best_data.get("own_arrival", INF)),
			float(best_data.get("opponent_arrival", INF))
		)
		if first_arrival <= elapsed + 0.08:
			break
		if predicted_velocity.length() < 45.0:
			break
	return best_data


func _make_duel_interception_data(
	opponent: FootballPlayer,
	position: Vector2,
	ball_arrival: float
) -> Dictionary:
	return {
		"position": position,
		"ball_arrival": ball_arrival,
		"own_arrival": _estimate_duel_player_arrival_seconds(
			controlled_player,
			position
		),
		"opponent_arrival": _estimate_duel_player_arrival_seconds(
			opponent,
			position
		)
	}


func _estimate_duel_player_arrival_seconds(
	player: FootballPlayer,
	target: Vector2
) -> float:
	if not is_instance_valid(player):
		return INF
	return SharedAISpatialProcessor.estimate_arrival_seconds(
		player.global_position,
		player.linear_velocity,
		player.max_speed,
		player.acceleration,
		maxf(40.0, player.kick_feedback_detection_distance * 0.72),
		target,
		maxf(1.8, duel_prediction_horizon_seconds + 0.8)
	)


func _get_duel_reachable_distance(
	player: FootballPlayer,
	target: Vector2,
	seconds: float
) -> float:
	var duration = maxf(0.0, seconds)
	var direction = player.global_position.direction_to(target)
	var starting_speed = maxf(0.0, player.linear_velocity.dot(direction))
	var maximum_speed = maxf(0.0, player.max_speed)
	starting_speed = minf(starting_speed, maximum_speed)
	var acceleration = maxf(0.0, player.acceleration)
	if acceleration <= 0.0:
		return starting_speed * duration
	var acceleration_time = maxf(
		0.0,
		(maximum_speed - starting_speed) / acceleration
	)
	var accelerating_seconds = minf(duration, acceleration_time)
	var reachable_distance = (
		starting_speed * accelerating_seconds
		+ 0.5 * acceleration * accelerating_seconds * accelerating_seconds
	)
	reachable_distance += (
		maximum_speed * maxf(0.0, duration - accelerating_seconds)
	)
	return reachable_distance


func _get_duel_challenge_position(
	intercept_position: Vector2,
	opponent: FootballPlayer
) -> Vector2:
	var own_goal = _get_own_goal()
	if own_goal == null:
		return intercept_position
	var goal_center = _get_goal_center(own_goal)
	var goal_side = intercept_position.direction_to(goal_center)
	if goal_side.is_zero_approx():
		goal_side = Vector2(-_get_attack_sign(), 0.0)
	var opponent_motion = opponent.linear_velocity.normalized()
	var lateral_read = Vector2(-goal_side.y, goal_side.x)
	var side_sign = -signf(opponent_motion.dot(lateral_read))
	if is_zero_approx(side_sign):
		side_sign = -1.0 if opponent.global_position.y < intercept_position.y else 1.0
	var challenge = (
		intercept_position
		+ goal_side * maxf(70.0, duel_goal_side_standoff * 0.52)
		+ lateral_read * side_sign * 78.0
	)
	if (
		challenge.distance_to(controlled_player.global_position)
		<= maxf(20.0, target_tolerance)
		and controlled_player.global_position.distance_to(ball.global_position)
		> controlled_player.kick_feedback_detection_distance * 0.85
	):
		challenge = intercept_position
	return _clamp_to_field(challenge)


func _get_duel_goal_side_recovery_position(
	opponent: FootballPlayer,
	intercept_position: Vector2
) -> Vector2:
	var own_goal = _get_own_goal()
	if own_goal == null:
		return intercept_position
	var goal_center = _get_goal_center(own_goal)
	var predicted_carrier = opponent.global_position + opponent.linear_velocity * 0.24
	var threat_position = predicted_carrier.lerp(intercept_position, 0.46)
	var goal_side = threat_position.direction_to(goal_center)
	if goal_side.is_zero_approx():
		goal_side = Vector2(-_get_attack_sign(), 0.0)
	var recovery = threat_position + goal_side * maxf(
		90.0,
		duel_goal_side_standoff
	)
	return _clamp_to_field(recovery)


func _try_duel_control_touch(opponent: FootballPlayer) -> void:
	var now = _server_time_seconds()
	if (
		now < _next_duel_control_touch_at
		or controlled_player.global_position.distance_to(ball.global_position)
		> controlled_player.kick_feedback_detection_distance
	):
		return
	var direction = Vector2(_get_attack_sign(), 0.0)
	if _ball_is_in_own_goal_danger():
		direction = ball.global_position.direction_to(
			_get_safe_own_goal_clearance_target()
		)
	else:
		var opponent_goal = _get_opponent_goal()
		if opponent_goal != null:
			direction = ball.global_position.direction_to(
				_get_goal_center(opponent_goal)
			)
		var away = opponent.global_position.direction_to(ball.global_position)
		if not away.is_zero_approx():
			direction = (direction * 0.82 + away * 0.38).normalized()
	direction = _skill_gate_reverse_dribble_direction(direction)
	if direction.is_zero_approx():
		return
	if controlled_player.cpu_dribble_touch(
		direction,
		maxf(0.0, duel_control_touch_force)
	):
		_next_duel_control_touch_at = (
			now + maxf(0.08, duel_touch_retry_seconds)
		)


func _skill_gate_reverse_dribble_direction(direction: Vector2) -> Vector2:
	var normalized_direction: Vector2 = direction.normalized()
	if normalized_direction.is_zero_approx():
		return Vector2.ZERO
	if get_effective_skill_level() >= reverse_dribble_minimum_level:
		return normalized_direction

	# Reverse dribbling is an advanced possession technique. Lower-intelligence
	# CPUs may still carry sideways or forward, but they should not deliberately
	# drag the ball back toward their own goal.
	var attack_sign: float = _get_attack_sign()
	if normalized_direction.x * attack_sign >= -0.02:
		return normalized_direction

	var lateral_direction := Vector2(0.0, normalized_direction.y)
	if absf(lateral_direction.y) >= 0.12:
		return lateral_direction.normalized()
	return Vector2(attack_sign, 0.0)


func _skill_gate_reverse_dribble_target(target: Vector2) -> Vector2:
	if not is_instance_valid(ball):
		return target
	var offset: Vector2 = target - ball.global_position
	if offset.is_zero_approx():
		return target
	var gated_direction: Vector2 = _skill_gate_reverse_dribble_direction(offset)
	if gated_direction.is_zero_approx():
		return target
	if gated_direction.dot(offset.normalized()) >= 0.999:
		return target
	return _clamp_to_field(
		ball.global_position + gated_direction * offset.length()
	)


func _is_true_one_vs_one() -> bool:
	var active_teammates = 0
	for teammate in _get_teammates():
		if is_instance_valid(teammate) and teammate.controls_enabled:
			active_teammates += 1
	var active_opponents = 0
	for opponent in _get_opponents():
		if is_instance_valid(opponent) and opponent.controls_enabled:
			active_opponents += 1
	return active_teammates == 1 and active_opponents == 1


func _get_one_vs_one_opponent() -> FootballPlayer:
	if not _is_true_one_vs_one():
		return null
	for opponent in _get_opponents():
		if is_instance_valid(opponent) and opponent.controls_enabled:
			return opponent
	return null


func _refresh_one_vs_one_context() -> void:
	if not _is_true_one_vs_one():
		_one_vs_one_counter_until = 0.0
		return
	var opponent = _get_one_vs_one_opponent()
	if opponent == null or not _last_ball_touch_was_opponent():
		return
	var cpu_distance = controlled_player.global_position.distance_to(
		ball.global_position
	)
	var opponent_distance = opponent.global_position.distance_to(
		ball.global_position
	)
	var opponent_lost_contact = (
		opponent_distance
		> controlled_player.kick_feedback_detection_distance * 1.1
	)
	var cpu_wins_race = (
		cpu_distance + maxf(0.0, one_vs_one_counter_race_margin)
		< opponent_distance
	)
	if opponent_lost_contact and cpu_wins_race:
		_one_vs_one_counter_until = (
			_server_time_seconds()
			+ maxf(0.2, one_vs_one_counter_window_seconds)
		)


func _one_vs_one_counter_is_active() -> bool:
	return (
		_is_true_one_vs_one()
		and _server_time_seconds() < _one_vs_one_counter_until
	)


func _one_vs_one_requires_emergency_defense() -> bool:
	if not _is_true_one_vs_one():
		return true
	if not _predict_own_goal_threat(2.35).is_empty():
		return true
	var opponent = _get_one_vs_one_opponent()
	if opponent == null:
		return false
	var opponent_distance = opponent.global_position.distance_to(
		ball.global_position
	)
	var cpu_distance = controlled_player.global_position.distance_to(
		ball.global_position
	)
	return (
		_last_ball_touch_was_opponent()
		and opponent_distance
		<= controlled_player.kick_feedback_detection_distance * 1.3
		and opponent_distance + maxf(0.0, one_vs_one_counter_race_margin)
		< cpu_distance
	)


func _should_commit_one_vs_one_dribble(
	opponent_goal: FootballGoal,
	now: float
) -> bool:
	var opponent = _get_relevant_duel_opponent()
	if opponent == null:
		return false
	var ball_distance = controlled_player.global_position.distance_to(
		ball.global_position
	)
	if (
		ball_distance
		> controlled_player.kick_feedback_detection_distance * 1.08
		or ball.linear_velocity.length() > 1650.0
	):
		return false
	var opponent_distance = controlled_player.global_position.distance_to(
		opponent.global_position
	)
	match controlled_player.selected_ability:
		FootballPlayer.ABILITY_ELASTIC_STEP:
			if (
				opponent_distance >= 210.0
				and opponent_distance
				<= maxf(350.0, one_vs_one_elastic_pressure_distance)
			):
				_begin_solo_attack(
					opponent_goal,
					opponent,
					now,
					maxf(0.25, one_vs_one_elastic_commit_seconds)
				)
				return true
		FootballPlayer.ABILITY_POWER_STRIKE:
			if (
				opponent_distance < 1450.0
				and _one_vs_one_power_opening_is_needed(opponent_goal)
			):
				_begin_solo_attack(
					opponent_goal,
					opponent,
					now,
					maxf(0.45, dribble_commit_seconds)
				)
				return true
		FootballPlayer.ABILITY_ENFORCER, FootballPlayer.ABILITY_GOALKEEPER_REACH, FootballPlayer.ABILITY_REFLEX_BLOCK, FootballPlayer.ABILITY_IRON_ANCHOR:
			if _one_vs_one_counter_is_active():
				_begin_solo_attack(
					opponent_goal,
					opponent,
					now,
					maxf(0.4, dribble_commit_seconds * 0.85)
				)
				return true
	return false


func _one_vs_one_power_opening_is_needed(
	opponent_goal: FootballGoal
) -> bool:
	if opponent_goal == null:
		return false
	var goal_target = _get_goal_center(opponent_goal)
	if ball.global_position.distance_to(goal_target) < 950.0:
		return false
	return (
		_minimum_segment_clearance(ball.global_position, goal_target)
		< maxf(100.0, one_vs_one_power_opening_lane)
	)


func _get_one_vs_one_power_opening_direction(
	opponent_goal: FootballGoal,
	opponent: FootballPlayer
) -> Vector2:
	var goal_target = _get_goal_center(opponent_goal)
	var forward = ball.global_position.direction_to(goal_target)
	if forward.is_zero_approx():
		forward = Vector2(_get_attack_sign(), 0.0)
	var lateral = Vector2(-forward.y, forward.x)
	var first_direction = (
		forward * maxf(0.1, one_vs_one_power_forward_weight)
		+ lateral * maxf(0.1, one_vs_one_power_lateral_weight)
	).normalized()
	var second_direction = (
		forward * maxf(0.1, one_vs_one_power_forward_weight)
		- lateral * maxf(0.1, one_vs_one_power_lateral_weight)
	).normalized()
	var first_target = _clamp_to_field(
		ball.global_position + first_direction * 820.0
	)
	var second_target = _clamp_to_field(
		ball.global_position + second_direction * 820.0
	)
	var first_score: float = (
		opponent.global_position.distance_to(first_target)
		+ _minimum_segment_clearance(first_target, goal_target) * 1.25
	)
	var second_score: float = (
		opponent.global_position.distance_to(second_target)
		+ _minimum_segment_clearance(second_target, goal_target) * 1.25
	)
	return first_direction if first_score >= second_score else second_direction


func _is_designated_goalkeeper(player: FootballPlayer) -> bool:
	if not is_instance_valid(player) or not player.cpu_controlled:
		return false
	var designated = match_manager.get_designated_cpu_goalkeeper(player.team)
	if designated != player:
		return false
	var team_players = (
		match_manager.blue_players
		if player.team == TEAM_BLUE
		else match_manager.red_players
	)
	var active_player_count = 0
	for teammate in team_players:
		if is_instance_valid(teammate) and teammate.controls_enabled:
			active_player_count += 1
	if active_player_count > 1:
		if not _team_likely_has_possession():
			var defensive_assignment = (
				match_manager.get_cpu_defensive_assignment(
					player.team,
					player.owner_peer_id
				)
			)
			if (
				StringName(defensive_assignment.get("role", &""))
				== &"press"
				and _predict_own_goal_threat(1.45).is_empty()
			):
				# In safe 2v2 states the nominal goalkeeper may be the closer
				# presser while the teammate rotates into the final lane. Treat
				# the assignment as the live role instead of ignoring it.
				return false
		var loose_ball_claim = _get_relative_loose_ball_claim()
		if (
			not loose_ball_claim.is_empty()
			and int(loose_ball_claim.get("peer_id", 0))
			== player.owner_peer_id
		):
			# Goalkeeper is only a nominal defensive role. When the ball is truly
			# free and this player wins the race, temporarily treat them as the
			# active outfield claimant instead of pinning them to the goal line.
			return false
		if _offensive_keeper_rotation_is_available(player):
			return false
		return true
	# In a true 1v1 the only CPU is not a permanent goalkeeper. It drops into
	# goal only for a real immediate threat, then becomes an outfield player
	# again so its equipped ability can define its attack.
	var own_goal = (
		match_manager.blue_goal
		if player.team == TEAM_BLUE
		else match_manager.red_goal
	)
	if own_goal == null or not is_instance_valid(ball):
		return true
	if _one_vs_one_goalkeeper_emergency_is_real(own_goal):
		return true
	var ball_goal_distance = ball.global_position.distance_to(
		_get_goal_center(own_goal)
	)
	if ball_goal_distance > maxf(400.0, one_vs_one_keeper_danger_distance):
		return false
	var opponent_distance = _nearest_opponent_distance(ball.global_position)
	var player_distance = player.global_position.distance_to(ball.global_position)
	return (
		_last_ball_touch_was_opponent()
		and opponent_distance + maxf(0.0, one_vs_one_counter_race_margin)
		< player_distance
	)


func _one_vs_one_goalkeeper_emergency_is_real(
	own_goal: FootballGoal
) -> bool:
	var opponent = _get_one_vs_one_opponent()
	var goal_center = _get_goal_center(own_goal)
	if opponent != null and _opponent_controls_ball(opponent):
		var opponent_goal_distance = opponent.global_position.distance_to(
			goal_center
		)
		var defender_goal_distance = controlled_player.global_position.distance_to(
			goal_center
		)
		var defender_is_beaten = (
			opponent_goal_distance
			+ maxf(0.0, anticipatory_defense_beaten_margin)
			< defender_goal_distance
		)
		var direction_to_goal = opponent.global_position.direction_to(goal_center)
		var carrier_is_advancing = (
			not direction_to_goal.is_zero_approx()
			and (
				opponent.linear_velocity.dot(direction_to_goal) > 80.0
				or opponent.server_direction.dot(direction_to_goal) > 0.18
			)
		)
		if (
			opponent_goal_distance
			<= maxf(900.0, anticipatory_defense_maximum_goal_distance)
			and (
				defender_is_beaten
				or opponent.server_is_charging
				or carrier_is_advancing
				and opponent_goal_distance
				<= maxf(900.0, one_vs_one_keeper_danger_distance * 1.75)
			)
		):
			return true
	var threat = _predict_own_goal_threat(1.75)
	if threat.is_empty():
		return false
	var toward_goal = ball.global_position.direction_to(goal_center)
	var ball_is_actually_attacking_goal = (
		ball.linear_velocity.length() > 450.0
		and not toward_goal.is_zero_approx()
		and ball.linear_velocity.normalized().dot(toward_goal) > 0.28
	)
	return ball_is_actually_attacking_goal


func _two_vs_two_attacking_rotation_active() -> bool:
	if (
		not two_vs_two_rotation_enabled
		or _get_active_team_player_count() != 2
		or not _team_likely_has_possession()
		or _get_ai_skill() < 0.48
	):
		return false
	var own_goal = _get_own_goal()
	var opponent_goal = _get_opponent_goal()
	if own_goal == null or opponent_goal == null:
		return false
	if not _predict_own_goal_threat(2.0).is_empty():
		return false
	var own_goal_center = _get_goal_center(own_goal)
	var ball_progress = (
		ball.global_position.x - own_goal_center.x
	) * _get_attack_sign()
	var opponent_goal_distance = ball.global_position.distance_to(
		_get_goal_center(opponent_goal)
	)
	return (
		ball_progress >= maxf(900.0, two_vs_two_rotation_minimum_progress)
		or opponent_goal_distance
		<= maxf(900.0, two_vs_two_rotation_goal_distance)
	)


func _offensive_keeper_rotation_is_available(
	player: FootballPlayer
) -> bool:
	if not _two_vs_two_attacking_rotation_active():
		return false
	var ability_role = FootballPlayer.get_ability_role(
		player.selected_ability
	)
	if ability_role != FootballPlayer.ABILITY_ROLE_DEFENSE:
		return true
	var opponent_goal = _get_opponent_goal()
	if opponent_goal == null:
		return false
	# A true defensive specialist joins later than a normal player, but it does
	# join. This prevents one CPU from spending every attack on its own goal line
	# while still keeping the final lane protected until the ball reaches the
	# opponent's final third.
	return ball.global_position.distance_to(
		_get_goal_center(opponent_goal)
	) <= maxf(1100.0, two_vs_two_defender_join_goal_distance)


func _get_two_vs_two_rotation_support_position(
	carrier: FootballPlayer
) -> Vector2:
	if (
		not _two_vs_two_attacking_rotation_active()
		or carrier == null
		or carrier == controlled_player
		or not is_instance_valid(carrier)
	):
		return Vector2.ZERO
	var opponent_goal = _get_opponent_goal()
	if opponent_goal == null:
		return Vector2.ZERO
	var goal_center = _get_goal_center(opponent_goal)
	var attack_sign = _get_attack_sign()
	var center_y = (minimum_field_y + maximum_field_y) * 0.5
	var carrier_side = signf(carrier.global_position.y - center_y)
	if is_zero_approx(carrier_side):
		carrier_side = -1.0 if ball.global_position.y > center_y else 1.0
	var support_side = -carrier_side
	var goal_distance = ball.global_position.distance_to(goal_center)
	var trailing_distance = maxf(
		260.0,
		two_vs_two_rotation_trailing_distance
	)
	var lateral_distance = maxf(
		320.0,
		two_vs_two_rotation_lateral_distance
	)
	var upper_target = Vector2.ZERO
	var lower_target = Vector2.ZERO
	if goal_distance <= maxf(1500.0, two_vs_two_defender_join_goal_distance):
		var finish_x = goal_center.x - attack_sign * 720.0
		upper_target = _clamp_to_field(Vector2(
			finish_x,
			goal_center.y - lateral_distance * 0.78
		))
		lower_target = _clamp_to_field(Vector2(
			finish_x,
			goal_center.y + lateral_distance * 0.78
		))
	else:
		var support_x = ball.global_position.x - attack_sign * trailing_distance
		upper_target = _clamp_to_field(Vector2(
			support_x,
			carrier.global_position.y - lateral_distance
		))
		lower_target = _clamp_to_field(Vector2(
			support_x,
			carrier.global_position.y + lateral_distance
		))
	var preferred = upper_target if support_side < 0.0 else lower_target
	var alternate = lower_target if support_side < 0.0 else upper_target
	if (
		_nearest_opponent_distance(alternate)
		> _nearest_opponent_distance(preferred) + 170.0
	):
		preferred = alternate
	var forward_progress = (
		preferred.x - carrier.global_position.x
	) * attack_sign
	_set_tactical_intent(
		INTENT_FORWARD_RUN if forward_progress > 120.0 else INTENT_WIDE_SUPPORT,
		preferred,
		carrier.owner_peer_id
	)
	return preferred


func _is_outfield_defender(player: FootballPlayer) -> bool:
	if not is_instance_valid(player):
		return false
	if _get_tactical_role(player) == TACTICAL_ROLE_DEFENDER:
		return true
	return player.selected_ability in [
		FootballPlayer.ABILITY_ENFORCER,
		FootballPlayer.ABILITY_REFLEX_BLOCK,
		FootballPlayer.ABILITY_IRON_ANCHOR,
		FootballPlayer.ABILITY_ECHO
	]


func _power_strike_requires_maximum_charge() -> bool:
	return (
		power_strike_requires_full_charge
		and not power_strike_cpu_fast_charge_enabled
		and controlled_player != null
		and is_instance_valid(controlled_player)
		and not _plan_is_pass
		and _has_active_ability(FootballPlayer.ABILITY_POWER_STRIKE)
	)


func _get_cpu_power_strike_charge_seconds(
	target_distance: float = -1.0,
	is_distribution: bool = false
) -> float:
	if controlled_player == null or not is_instance_valid(controlled_player):
		return 0.0
	var maximum_charge := controlled_player.cpu_get_maximum_shot_charge_seconds()
	if not power_strike_cpu_fast_charge_enabled:
		return maximum_charge
	var distance := target_distance
	if distance < 0.0 and ball != null and not _shot_target.is_zero_approx():
		distance = ball.global_position.distance_to(_shot_target)
	var distance_ratio := clampf(
		distance / maxf(1.0, power_strike_activation_goal_distance),
		0.0,
		1.0
	)
	var skill_speed := _get_high_tempo_strength()
	var minimum_charge := lerpf(
		power_strike_cpu_minimum_charge_seconds * 1.30,
		power_strike_cpu_minimum_charge_seconds,
		skill_speed
	)
	var long_charge := lerpf(
		power_strike_cpu_long_charge_seconds * 1.18,
		power_strike_cpu_long_charge_seconds,
		skill_speed
	)
	var desired := lerpf(minimum_charge, long_charge, distance_ratio)
	if is_distribution:
		desired = maxf(
			desired,
			lerpf(
				power_strike_distribution_charge_seconds * 1.18,
				power_strike_distribution_charge_seconds,
				skill_speed
			)
		)
	return clampf(desired, 0.20, maximum_charge)


func _enforce_power_strike_charge_requirement() -> void:
	if (
		controlled_player == null
		or not is_instance_valid(controlled_player)
		or not _has_active_ability(FootballPlayer.ABILITY_POWER_STRIKE)
	):
		return
	if _plan_is_pass:
		return
	if power_strike_cpu_fast_charge_enabled:
		# Power Strike already multiplies kick force. Holding the normal 1.5 s
		# maximum made elite CPUs stand on the ball long enough to be tackled.
		# Use the ability-aware charge directly instead of preserving the slower
		# generic shot heuristic.
		_desired_charge_seconds = _get_cpu_power_strike_charge_seconds(
			_planned_route_distance,
			false
		)
		return
	if _power_strike_requires_maximum_charge():
		_desired_charge_seconds = (
			controlled_player.cpu_get_maximum_shot_charge_seconds()
		)


func _try_begin_shot(goalkeeper_clear: bool) -> void:
	if controlled_player.server_is_charging:
		return
	if not _shot_plan_passes_integrity_check(goalkeeper_clear):
		_plan_expires_at = 0.0
		return
	var ball_distance = controlled_player.global_position.distance_to(
		ball.global_position
	)
	var has_ball_contact = controlled_player.cpu_has_kickable_ball()
	var precharging = not has_ball_contact
	if precharging and not _precharge_approach_is_viable(ball_distance):
		return

	if (
		live_shot_retarget_enabled
		and not _is_active_penalty_kicker()
		and not _shot_executor_active
		and not _plan_is_pass
		and not goalkeeper_clear
		and not _plan_uses_wall
		and not _plan_uses_double_bank
	):
		var live_goal = _get_opponent_goal()
		var live_target = _get_best_live_direct_shot_target(live_goal)
		if not live_target.is_zero_approx():
			_planned_destination = live_target
			_shot_target = live_target
			_planned_route_distance = ball.global_position.distance_to(
				live_target
			)
	var predicted_ball = _get_predicted_ball_position()
	var desired_direction = predicted_ball.direction_to(
		_shot_target
	)
	var contact_direction = controlled_player.global_position.direction_to(
		predicted_ball
	)
	var minimum_alignment = (
		shot_precharge_alignment if precharging else required_shot_alignment
	)
	if (
		power_strike_cpu_fast_charge_enabled
		and _has_active_ability(FootballPlayer.ABILITY_POWER_STRIKE)
	):
		# Start holding the empowered kick while circling behind the ball. Release
		# still uses the strict live contact/goal checks below, so this saves setup
		# time without spraying the shot in the wrong direction.
		minimum_alignment = minf(
			minimum_alignment,
			0.18 if _get_active_team_player_count() >= 3 else 0.26
		)
	if (
		desired_direction.is_zero_approx()
		or contact_direction.dot(desired_direction)
		< minimum_alignment
	):
		return
	var target_distance = (
		_planned_route_distance
		if _planned_route_distance > 0.0
		else ball.global_position.distance_to(_shot_target)
	)
	_desired_charge_seconds = goalkeeper_clear_charge_seconds
	if _plan_is_pass and is_instance_valid(_planned_receiver):
		_desired_charge_seconds = lerpf(
			minimum_pass_charge_seconds,
			maximum_pass_charge_seconds,
			clampf(
				target_distance / maxf(1.0, maximum_pass_distance),
				0.0,
				1.0
			)
		)
		if _is_power_strike_distribution_plan():
			_desired_charge_seconds = _get_cpu_power_strike_charge_seconds(
				target_distance,
				true
			)
		elif _is_curve_shot_distribution_plan():
			_desired_charge_seconds = maxf(
				_desired_charge_seconds,
				curve_shot_distribution_charge_seconds
			)
	elif not goalkeeper_clear:
		_desired_charge_seconds = lerpf(
			minimum_shot_charge_seconds,
			maximum_shot_charge_seconds,
			clampf(
				target_distance / maxf(1.0, full_charge_goal_distance),
				0.0,
				1.0
			)
		)
		if (
			fast_finish_enabled
			and not _plan_uses_wall
			and not _plan_uses_double_bank
			and target_distance <= fast_finish_maximum_distance
			and _minimum_segment_clearance(
				ball.global_position,
				_shot_target
			) >= maxf(
				fast_finish_minimum_lane,
				_required_direct_shot_lane(target_distance) * 0.88
			)
		):
			_desired_charge_seconds = maxf(
				0.16,
				_desired_charge_seconds
				* clampf(fast_finish_charge_multiplier, 0.3, 1.0)
			)
	if _plan_uses_double_bank:
		# Preserve the charge proven sufficient by the double-bank simulation;
		# the generic distance heuristic is not aware of bounce energy loss.
		_desired_charge_seconds = maxf(
			_desired_charge_seconds,
			_double_bank_required_charge_seconds
		)
	if _elite_forced_charge_ratio >= 0.0:
		_desired_charge_seconds = (
			controlled_player.cpu_get_maximum_shot_charge_seconds()
			* clampf(_elite_forced_charge_ratio, 0.0, 1.0)
		)
	# Power Strike is a limited-duration finishing ability. Releasing it at
	# partial charge wastes the cooldown and produces a weaker version of the
	# exact action the CPU committed to. This rule is intentionally applied
	# after every normal, fast-finish and elite shot-charge heuristic. A named
	# Power Strike distribution remains a pass and keeps its calibrated force.
	_enforce_power_strike_charge_requirement()
	if _is_active_penalty_kicker() and not _plan_is_pass:
		_desired_charge_seconds = maxf(
			_desired_charge_seconds,
			controlled_player.cpu_get_maximum_shot_charge_seconds()
			* clampf(penalty_minimum_charge_ratio, 0.5, 1.0)
		)
	_desired_charge_seconds = minf(
		_desired_charge_seconds,
		controlled_player.cpu_get_maximum_shot_charge_seconds()
	)
	_charge_elapsed = 0.0
	_shot_was_precharged = precharging
	_charge_is_goalkeeper_clear = goalkeeper_clear
	if not _plan_is_pass:
		_try_plan_goalkeeper_rebound_followup(
			_get_opponent_goal(),
			desired_direction,
			target_distance
		)
	controlled_player.cpu_begin_shot_charge()
	if not controlled_player.server_is_charging:
		_reset_cpu_charge_tracking()


func _precharge_approach_is_viable(ball_distance: float) -> bool:
	if _shot_target.is_zero_approx():
		return false
	if _plan_is_pass and not is_instance_valid(_planned_receiver):
		return false
	if _opponent_has_live_ball_control():
		return false

	var verified_delivery = _has_verified_incoming_teammate_delivery()
	if verified_delivery:
		return ball_distance <= maxf(
			shot_precharge_distance,
			controlled_player.kick_feedback_detection_distance * 1.45
		)

	# Generic shot/pass plans may precharge a loose/owned ball only when the CPU
	# can actually reach kicking contact very soon. The old `relative speed >
	# -180` check accepted a stationary ball from 1000+ px away and was the
	# reason CPUs visibly held charge while an opponent was playing elsewhere.
	var contact_distance_limit = minf(
		shot_precharge_distance,
		controlled_player.kick_feedback_detection_distance
		* maxf(1.35, generic_shot_precharge_contact_multiplier)
	)
	if ball_distance > contact_distance_limit:
		return false
	var arrival_seconds = _estimate_duel_player_arrival_seconds(
		controlled_player,
		ball.global_position
	)
	if arrival_seconds > maxf(0.18, generic_shot_precharge_max_arrival_seconds):
		return false
	var nearest_opponent = _nearest_opponent_distance(ball.global_position)
	return (
		_team_likely_has_possession()
		or ball_distance + shot_charge_opponent_control_margin < nearest_opponent
	)


func _charged_direct_shot_release_is_viable() -> bool:
	if _is_active_penalty_kicker():
		return true
	if (
		_plan_is_pass
		or _charge_is_goalkeeper_clear
		or _plan_uses_wall
		or _plan_uses_double_bank
	):
		return true
	var opponent_goal = _get_opponent_goal()
	if opponent_goal == null:
		return false
	var live_target = _get_best_live_direct_shot_target(opponent_goal)
	if live_target.is_zero_approx():
		return false
	var goal_distance = ball.global_position.distance_to(live_target)
	var live_lane = _minimum_segment_clearance(
		ball.global_position,
		live_target
	)
	# Do not use the full predictive shot-selection gate here: that gate is
	# intentionally conservative and can reject otherwise valid open shots. At
	# release time we only need to prevent the obvious failure seen in the clip:
	# physically kicking a charged shot straight into a defender who is already
	# occupying the lane.
	var minimum_live_lane = maxf(
		95.0,
		_required_direct_shot_lane(goal_distance) * 0.68
	)
	if live_lane < minimum_live_lane:
		return false
	_planned_destination = live_target
	_shot_target = live_target
	_planned_route_distance = goal_distance
	return true


func _charged_pass_release_is_viable() -> bool:
	if not _plan_is_pass:
		return true
	if (
		not is_instance_valid(_planned_receiver)
		or _planned_receiver.team != controlled_player.team
		or not _planned_receiver.controls_enabled
	):
		return false
	# Wall-bank passes have a different first segment and are already validated
	# by their route planner. The ordinary straight pass is rechecked here at the
	# actual release frame so a defender stepping into the lane cannot turn a
	# charged pass into an obvious gift.
	if _plan_uses_wall:
		return true
	var destination = _planned_destination
	if destination.is_zero_approx():
		destination = _shot_target
	if destination.is_zero_approx():
		return false
	var distance = ball.global_position.distance_to(destination)
	var maximum_delivery_distance: float = maximum_pass_distance * 1.12
	if _is_power_strike_distribution_plan():
		# The whole point of a Power Strike delivery is that it can connect a
		# farther teammate than an ordinary pass. The old generic release guard
		# silently cancelled those plans above ~3.8k even though the planner
		# deliberately allows them up to the Power Strike distribution range.
		maximum_delivery_distance = power_strike_distribution_maximum_distance * 1.04
	elif _is_curve_shot_distribution_plan():
		maximum_delivery_distance = curve_shot_distribution_maximum_distance * 1.04
	if distance > maximum_delivery_distance:
		return false
	var lane_clearance = _minimum_pass_lane_clearance(destination)
	if _is_curve_shot_distribution_plan():
		if (
			lane_clearance < curve_shot_distribution_minimum_lane
			or lane_clearance > curve_shot_distribution_maximum_direct_lane * 1.2
		):
			return false
	elif lane_clearance < maxf(80.0, charged_pass_release_minimum_lane):
		return false
	var charge_ratio = clampf(
		_desired_charge_seconds
		/ maxf(0.01, controlled_player.cpu_get_maximum_shot_charge_seconds()),
		0.0,
		1.0
	)
	var launch_speed = lerpf(
		controlled_player.minimum_shot_force,
		controlled_player.maximum_shot_force,
		charge_ratio
	)
	if _is_power_strike_distribution_plan():
		# Release safety must predict the kick we are ACTUALLY about to make. The
		# old check used ordinary shot speed, so long Power Strike deliveries were
		# judged ~2x slower than reality and cancelled as "interceptable" even when
		# the empowered ball would reach the teammate first.
		launch_speed *= maxf(
			1.0,
			lerpf(
				1.0,
				controlled_player.power_strike_force_multiplier,
				controlled_player.server_ability_strength_scale
			)
		)
	var ball_time = _estimate_elite_ball_travel_time(
		distance,
		launch_speed,
		false
	)
	if not is_finite(ball_time):
		return false
	var receiver_arrival = _estimate_duel_player_arrival_seconds(
		_planned_receiver,
		destination
	)
	var opponent_arrival = INF
	for opponent in _get_opponents():
		if not is_instance_valid(opponent) or not opponent.controls_enabled:
			continue
		opponent_arrival = minf(
			opponent_arrival,
			_estimate_duel_player_arrival_seconds(opponent, destination)
		)
	return (
		opponent_arrival - ball_time
		>= charged_pass_release_minimum_interception_margin
		and opponent_arrival - receiver_arrival
		>= charged_pass_release_minimum_receiver_margin
	)


func _update_charge(delta: float) -> void:
	if not controlled_player.server_is_charging:
		_reset_cpu_charge_tracking()
		return

	_charge_elapsed += delta
	# Keep this as a live invariant as well as an initial planning rule. Some
	# decisive-shot paths shorten their charge after _try_begin_shot(), and a
	# policy may be swapped while the button is already being held.
	_enforce_power_strike_charge_requirement()
	if (
		live_shot_retarget_enabled
		and not _is_active_penalty_kicker()
		and not _shot_executor_active
		and not _plan_is_pass
		and not _charge_is_goalkeeper_clear
		and not _plan_uses_wall
		and not _plan_uses_double_bank
	):
		var live_goal = _get_opponent_goal()
		var live_target = _get_best_live_direct_shot_target(live_goal)
		if not live_target.is_zero_approx():
			_planned_destination = live_target
			_shot_target = live_target
			_planned_route_distance = ball.global_position.distance_to(
				live_target
			)
	# Keep circling behind the live ball throughout the charge instead of
	# committing to the position it occupied when charging began.
	_movement_target = _get_committed_strike_position(_shot_target)
	var ball_distance = controlled_player.global_position.distance_to(
		ball.global_position
	)
	if _charged_shot_opportunity_is_lost(ball_distance):
		controlled_player.cpu_cancel_shot_charge()
		_reset_cpu_charge_tracking()
		return

	if _charge_elapsed < maxf(0.05, _desired_charge_seconds):
		return
	var desired_direction = ball.global_position.direction_to(_shot_target)
	var contact_direction = controlled_player.global_position.direction_to(
		ball.global_position
	)
	var contact_aligned = (
		not desired_direction.is_zero_approx()
		and contact_direction.dot(desired_direction)
		>= release_shot_alignment
	)
	if (
		contact_aligned
		and get_effective_skill_level() >= 13
		and not _plan_is_pass
		and not _charge_is_goalkeeper_clear
		and not _plan_uses_wall
		and not _plan_uses_double_bank
	):
		contact_aligned = _elite_direct_contact_path_hits_goal()
	if controlled_player.cpu_has_kickable_ball() and contact_aligned:
		# Revalidate on the exact physics frame of release. During a long charge a
		# defender can take the lane or a receiver can lose the race. Do not fire a
		# stale shot/pass directly into that opponent.
		var release_route_viable = (
			_charged_pass_release_is_viable()
			if _plan_is_pass
			else _charged_direct_shot_release_is_viable()
		)
		if not release_route_viable:
			var stale_receiver_id = (
				_planned_receiver.owner_peer_id
				if _plan_is_pass and is_instance_valid(_planned_receiver)
				else 0
			)
			controlled_player.cpu_cancel_shot_charge()
			_reset_cpu_charge_tracking()
			_plan_expires_at = 0.0
			if stale_receiver_id > 0:
				match_manager.clear_cpu_pass_intention(stale_receiver_id)
			return
		if not _shot_plan_passes_integrity_check(
			_charge_is_goalkeeper_clear
		):
			controlled_player.cpu_cancel_shot_charge()
			_reset_cpu_charge_tracking()
			_plan_expires_at = 0.0
			return
		var queued_fast_follow_up: bool = false
		if not _plan_is_pass:
			_queue_fast_follow_up_finish()
			queued_fast_follow_up = _fast_follow_up_finish_until != -INF
		var completed_precharged_first_touch = (
			not _cpu_first_touch_plan.is_empty()
			and StringName(_cpu_first_touch_plan.get("mode", FIRST_TOUCH_NONE))
			in [FIRST_TOUCH_SHOT, FIRST_TOUCH_PASS]
		)
		var completed_first_touch_mode = StringName(
			_cpu_first_touch_plan.get("mode", FIRST_TOUCH_NONE)
		)
		controlled_player.cpu_set_next_kick_is_pass(_plan_is_pass)
		controlled_player.cpu_release_shot()
		if completed_precharged_first_touch:
			_last_cpu_first_touch_mode = completed_first_touch_mode
			_clear_cpu_first_touch_plan()
		# A normal shot starts FootballPlayer's shot-buffer lockout. Waiting for
		# that lockout before pressing Pass made the intended elite Kick -> Pass
		# combo practically impossible: by then a full-power shot had already left
		# the player's kick area. Execute the queued second action immediately
		# while the just-kicked ball is still in contact. If contact was lost due
		# to physics/collision displacement, keep the existing short follow-up
		# recovery window as a fallback.
		if (
			queued_fast_follow_up
			and controlled_player.cpu_try_fast_follow_up_soft_pass()
		):
			_clear_fast_follow_up_finish()
		_reset_cpu_charge_tracking()
		_plan_expires_at = _server_time_seconds() + 0.65
		return
	# A pre-charged bot is allowed to hold full power while closing the final
	# distance. A charge started in contact uses the shorter recovery window.
	var hold_seconds = (
		shot_precharge_max_hold_seconds
		if _shot_was_precharged
		else shot_contact_reacquire_seconds
	)
	if (
		_charge_elapsed
		>= _desired_charge_seconds + maxf(0.05, hold_seconds)
	):
		controlled_player.cpu_cancel_shot_charge()
		_reset_cpu_charge_tracking()
		_plan_expires_at = 0.0


func _elite_direct_contact_path_hits_goal() -> bool:
	# Charged CPU kicks use the physical player -> ball contact vector in
	# FootballPlayer._hit_ball(). For elite CPUs, verify that this exact vector
	# reaches the goal mouth before releasing instead of only trusting the
	# planned target. This prevents collision-shifted "perfect" shots from
	# becoming obvious misses.
	if controlled_player == null or ball == null:
		return false
	var opponent_goal := _get_opponent_goal()
	if opponent_goal == null:
		return false
	var contact_direction := controlled_player.global_position.direction_to(
		ball.global_position
	)
	if contact_direction.is_zero_approx() or absf(contact_direction.x) < 0.001:
		return false
	var goal_x: float = opponent_goal.get_goal_plane_x()
	var seconds_to_plane: float = (goal_x - ball.global_position.x) / contact_direction.x
	if seconds_to_plane <= 0.0:
		return false
	var crossing_y: float = (
		ball.global_position.y
		+ contact_direction.y * seconds_to_plane
	)
	var mouth := opponent_goal.get_mouth_y_range()
	var half_height: float = maxf(0.0, (mouth.y - mouth.x) * 0.5)
	var margin: float = minf(
		maxf(45.0, shot_integrity_goal_margin),
		maxf(0.0, half_height - 1.0)
	)
	return (
		crossing_y >= mouth.x + margin
		and crossing_y <= mouth.y - margin
	)


func _shot_plan_passes_integrity_check(
	goalkeeper_clear: bool
) -> bool:
	if (
		not prevent_intentional_shot_misses
		or goalkeeper_clear
		or _plan_is_pass
		or _tactical_intent_action != INTENT_SHOOT
	):
		return true

	var opponent_goal = _get_opponent_goal()
	if opponent_goal == null:
		return false

	var final_target = _planned_destination
	if final_target.is_zero_approx():
		final_target = _shot_target
	if final_target.is_zero_approx():
		return false

	var mouth_range = opponent_goal.get_mouth_y_range()
	var half_height = maxf(
		0.0,
		(mouth_range.y - mouth_range.x) * 0.5
	)
	var margin = minf(
		maxf(0.0, shot_integrity_goal_margin),
		maxf(0.0, half_height - 1.0)
	)
	var target_is_inside_mouth = (
		final_target.y >= mouth_range.x + margin
		and final_target.y <= mouth_range.y - margin
	)
	var target_reaches_goal_plane = (
		absf(
			final_target.x - opponent_goal.get_goal_plane_x()
		) <= maxf(1.0, shot_integrity_goal_plane_tolerance)
	)
	return target_is_inside_mouth and target_reaches_goal_plane


func _charged_shot_opportunity_is_lost(ball_distance: float) -> bool:
	# Physical opponent control beats stale last-touch/possession bookkeeping.
	# Never keep holding a shot while an opponent has settled the ball.
	if _opponent_has_live_ball_control():
		return true
	var maximum_distance = (
		maxf(shot_precharge_distance, shot_precharge_cancel_distance)
		if _shot_was_precharged
		else controlled_player.kick_feedback_detection_distance * 1.3
	)
	if ball_distance > maximum_distance or _shot_target.is_zero_approx():
		return true
	if _plan_is_pass and not is_instance_valid(_planned_receiver):
		return true
	if _charge_is_goalkeeper_clear:
		return false
	var opponent_distance = _nearest_opponent_distance(ball.global_position)
	var incoming_to_player = (
		ball.linear_velocity.length() > 260.0
		and ball.linear_velocity.normalized().dot(
			ball.global_position.direction_to(
				controlled_player.global_position
			)
		) > 0.42
	)
	return (
		_last_ball_touch_was_opponent()
		and not incoming_to_player
		and opponent_distance + shot_charge_opponent_control_margin
		< ball_distance
	)


func _reset_cpu_charge_tracking() -> void:
	_charge_elapsed = 0.0
	_shot_was_precharged = false
	_charge_is_goalkeeper_clear = false
	_elite_forced_charge_ratio = -1.0


static func is_fast_follow_up_finish_opportunity(
	skill_level: int,
	minimum_level: int,
	ball_speed: float,
	forward_alignment: float,
	lane_clearance: float,
	target_distance: float,
	minimum_ball_speed: float,
	minimum_alignment: float,
	minimum_lane_clearance: float,
	minimum_distance: float,
	maximum_distance: float
) -> bool:
	return (
		skill_level >= maxi(1, minimum_level)
		and ball_speed >= maxf(0.0, minimum_ball_speed)
		and forward_alignment >= clampf(minimum_alignment, -1.0, 1.0)
		and lane_clearance >= maxf(0.0, minimum_lane_clearance)
		and target_distance >= maxf(0.0, minimum_distance)
		and target_distance <= maxf(minimum_distance, maximum_distance)
	)


func _queue_fast_follow_up_finish() -> void:
	_clear_fast_follow_up_finish()
	var is_haaland_power_strike: bool = (
		controlled_player != null
		and controlled_player.is_haaland_boss()
		and controlled_player.selected_ability == FootballPlayer.ABILITY_POWER_STRIKE
	)
	if (
		not fast_follow_up_finish_enabled
		or (
			not is_haaland_power_strike
			and get_effective_skill_level() < fast_follow_up_finish_minimum_level
		)
		or _plan_is_pass
		or _plan_uses_double_bank
	):
		return
	var opponent_goal: FootballGoal = _get_opponent_goal()
	if opponent_goal == null:
		return
	var target: Vector2 = _shot_target
	if target.is_zero_approx():
		target = _get_best_live_direct_shot_target(opponent_goal)
	if target.is_zero_approx():
		return
	var target_distance: float = ball.global_position.distance_to(target)
	# A wall shot's first target is the bounce point, but the meaningful shot
	# distance is the complete bank route to goal. Reuse that existing route
	# distance so level 13+ can perform the same Shoot -> Pass acceleration
	# tech on angled bank shots instead of only straight shots.
	if _plan_uses_wall and _planned_route_distance > 0.0:
		target_distance = _planned_route_distance
	var queue_min_distance: float = fast_follow_up_finish_minimum_distance
	var queue_max_distance: float = fast_follow_up_finish_maximum_distance
	if get_effective_skill_level() >= fast_follow_up_finish_minimum_level:
		queue_min_distance *= 0.62
		queue_max_distance = maxf(queue_max_distance, 5600.0)
	if is_haaland_power_strike:
		queue_min_distance = minf(queue_min_distance, 180.0)
		queue_max_distance = maxf(queue_max_distance, 6400.0)
	if (
		target_distance < maxf(0.0, queue_min_distance)
		or target_distance > maxf(queue_min_distance, queue_max_distance)
	):
		return
	_fast_follow_up_finish_target = target
	var recovery_window: float = maxf(0.08, fast_follow_up_finish_window_seconds)
	if get_effective_skill_level() >= 15:
		recovery_window = maxf(recovery_window, 0.62)
	if controlled_player.is_haaland_boss():
		recovery_window = maxf(recovery_window, 0.78)
	_fast_follow_up_finish_until = (
		_server_time_seconds()
		+ maxf(0.05, controlled_player.shot_buffer_seconds)
		+ recovery_window
	)


func _clear_fast_follow_up_finish() -> void:
	_fast_follow_up_finish_until = -INF
	_fast_follow_up_finish_target = Vector2.ZERO


func _update_fast_follow_up_finish() -> bool:
	if _fast_follow_up_finish_until == -INF:
		return false
	var now: float = _server_time_seconds()
	if (
		now > _fast_follow_up_finish_until
		or not is_instance_valid(ball)
		or ball.last_touch_peer_id != controlled_player.owner_peer_id
	):
		_clear_fast_follow_up_finish()
		return false
	var opponent_goal: FootballGoal = _get_opponent_goal()
	if opponent_goal == null:
		_clear_fast_follow_up_finish()
		return false
	var target: Vector2 = _fast_follow_up_finish_target
	if target.is_zero_approx():
		target = _get_best_live_direct_shot_target(opponent_goal)
	var target_direction: Vector2 = ball.global_position.direction_to(target)
	if target_direction.is_zero_approx():
		_clear_fast_follow_up_finish()
		return false
	var forward_alignment: float = 1.0
	if not ball.linear_velocity.is_zero_approx():
		forward_alignment = ball.linear_velocity.normalized().dot(target_direction)
	var target_distance: float = ball.global_position.distance_to(target)
	if _plan_uses_wall and _planned_route_distance > 0.0:
		target_distance = _planned_route_distance
	var lane_clearance: float = _minimum_segment_clearance(
		ball.global_position,
		target
	)
	var effective_level: int = get_effective_skill_level()
	var is_haaland_signature: bool = controlled_player.is_haaland_boss()
	var elite_follow_up: bool = effective_level >= fast_follow_up_finish_minimum_level
	# Shoot -> Pass is a real high-level mechanic, not a guaranteed scoring
	# conversion. Elite CPUs should be willing to use it as pressure even when
	# the lane is imperfect, and Haaland should attempt it as his signature shot
	# whenever the physical follow-up is still plausible.
	var follow_min_speed: float = fast_follow_up_finish_minimum_ball_speed
	var follow_min_alignment: float = fast_follow_up_finish_minimum_alignment
	var follow_min_lane: float = fast_follow_up_finish_minimum_lane_clearance
	var follow_min_distance: float = fast_follow_up_finish_minimum_distance
	var follow_max_distance: float = fast_follow_up_finish_maximum_distance
	if elite_follow_up:
		follow_min_speed *= 0.66
		follow_min_alignment = minf(follow_min_alignment, 0.04)
		follow_min_lane *= 0.36
		follow_min_distance *= 0.62
		follow_max_distance = maxf(follow_max_distance, 5600.0)
	if is_haaland_signature:
		follow_min_speed = minf(follow_min_speed, 250.0)
		follow_min_alignment = minf(follow_min_alignment, -0.16)
		follow_min_lane = 0.0
		follow_min_distance = minf(follow_min_distance, 180.0)
		follow_max_distance = maxf(follow_max_distance, 6400.0)
	if not is_fast_follow_up_finish_opportunity(
		effective_level,
		fast_follow_up_finish_minimum_level,
		ball.linear_velocity.length(),
		forward_alignment,
		lane_clearance,
		target_distance,
		follow_min_speed,
		follow_min_alignment,
		follow_min_lane,
		follow_min_distance,
		follow_max_distance
	):
		_clear_fast_follow_up_finish()
		return false
	# Preserve the actual human sequence: recover behind the moving ball, then
	# use the normal Pass action only after the existing shot lockout ends. The
	# added soft-pass impulse accelerates the live shot; it is never a CPU-only
	# force or a disguised teammate pass.
	_movement_target = _get_strike_position(target)
	_set_tactical_intent(INTENT_SHOOT, target)
	if not controlled_player.cpu_has_kickable_ball():
		return true
	var contact_direction: Vector2 = controlled_player.global_position.direction_to(
		ball.global_position
	)
	var follow_contact_alignment: float = required_shot_alignment
	if effective_level >= fast_follow_up_finish_minimum_level:
		follow_contact_alignment = minf(follow_contact_alignment, 0.38)
	if is_haaland_signature:
		follow_contact_alignment = minf(follow_contact_alignment, 0.12)
	if contact_direction.dot(target_direction) < follow_contact_alignment:
		return true
	if (
		now < controlled_player.next_shot_allowed_at
		or now < controlled_player.next_soft_pass_allowed_at
	):
		return true
	var finished: bool = controlled_player.cpu_try_soft_pass()
	_clear_fast_follow_up_finish()
	return finished


func _apply_movement_input(delta: float) -> void:
	var offset = _movement_target - controlled_player.global_position
	var direction = Vector2.ZERO
	var now = _server_time_seconds()
	var resolving_duel = _duel_resolution_until > now
	var collecting_self_pass = _wall_dribble_until > now
	var committed_ball_action = (
		controlled_player.server_is_charging
		or _tactical_intent_action in [INTENT_SHOOT, INTENT_PASS]
	)
	var precision_movement = (
		resolving_duel or collecting_self_pass or committed_ball_action
	)
	var effective_tolerance = (
		12.0 if precision_movement else maxf(10.0, target_tolerance)
	)
	if offset.length() > effective_tolerance:
		direction = offset.normalized()

	# A moving ball must not make a committed shooter pulse between full movement
	# and a complete stop. Even while the relative strike point is inside the tiny
	# precision tolerance, carry some of the ball's velocity so the player keeps
	# the same behind-ball relationship throughout charge/release.
	if (
		committed_ball_action
		and is_instance_valid(ball)
		and ball.linear_velocity.length()
		>= maxf(20.0, committed_ball_follow_speed_threshold)
		and controlled_player.global_position.distance_to(ball.global_position)
		<= _get_cpu_kick_contact_radius() * 1.65
	):
		var velocity_follow = (
			ball.linear_velocity / maxf(1.0, controlled_player.max_speed)
		).limit_length(
			clampf(committed_ball_velocity_follow_strength, 0.0, 1.0)
		)
		if offset.length() <= effective_tolerance:
			direction = velocity_follow
		else:
			direction += velocity_follow

	if (
		not precision_movement
		and not _has_active_ability(FootballPlayer.ABILITY_ENFORCER)
	):
		direction += _get_separation_steering() * separation_strength
	direction += _get_active_enemy_ability_avoidance()
	if precision_movement and offset.length() > effective_tolerance:
		var required_direction = offset.normalized()
		if direction.dot(required_direction) < 0.15:
			# Goal-side duel recovery and self-pass collection are committed
			# routes. Generic avoidance must not reverse them or freeze the CPU.
			direction = required_direction
	_update_stuck_recovery(delta, offset.length())
	_stuck_recovery_remaining = maxf(
		0.0,
		_stuck_recovery_remaining - delta
	)
	if _stuck_recovery_remaining > 0.0:
		direction += Vector2(-direction.y, direction.x) * (
			stuck_sidestep_strength * _stuck_side
		)
	controlled_player.server_direction = direction.limit_length(1.0)


func _get_active_enemy_ability_avoidance() -> Vector2:
	var avoidance = Vector2.ZERO
	for opponent in _get_opponents():
		if (
			not is_instance_valid(opponent)
			or not opponent.controls_enabled
			or not opponent.server_ability_active
		):
			continue
		var distance = controlled_player.global_position.distance_to(
			opponent.global_position
		)
		var safe_direction = opponent.global_position.direction_to(
			controlled_player.global_position
		)
		match opponent.server_active_ability_id:
			FootballPlayer.ABILITY_ENFORCER:
				if distance < 900.0:
					avoidance += safe_direction * (1.0 - distance / 900.0) * 1.25
			FootballPlayer.ABILITY_BURST_DRIBBLE, FootballPlayer.ABILITY_ELASTIC_STEP, FootballPlayer.ABILITY_BLIND_SPOT, FootballPlayer.ABILITY_BREAKAWAY, FootballPlayer.ABILITY_SNAPBACK:
				if distance < 650.0 and not _is_primary_ball_chaser():
					avoidance += safe_direction * (1.0 - distance / 650.0) * 0.55
	return avoidance


func _get_separation_steering() -> Vector2:
	if match_manager.players_parent == null:
		return Vector2.ZERO
	var steering = Vector2.ZERO
	var safe_radius = maxf(1.0, separation_radius)
	for child in match_manager.players_parent.get_children():
		var other = child as FootballPlayer
		if (
			other == null
			or other == controlled_player
			or other.training_dummy
		):
			continue
		var away = other.global_position.direction_to(
			controlled_player.global_position
		)
		var distance = controlled_player.global_position.distance_to(
			other.global_position
		)
		if distance < safe_radius and distance > 0.1:
			steering += away * (1.0 - distance / safe_radius)
	return steering.limit_length(1.0)


func _update_stuck_recovery(delta: float, target_distance: float) -> void:
	if target_distance <= target_tolerance * 2.0:
		_stuck_elapsed = 0.0
		_last_stuck_position = controlled_player.global_position
		return
	_stuck_elapsed += delta
	if _stuck_elapsed < maxf(0.1, stuck_check_seconds):
		return
	var moved = controlled_player.global_position.distance_to(
		_last_stuck_position
	)
	if moved < stuck_movement_threshold:
		_stuck_side *= -1.0
		_stuck_recovery_remaining = maxf(
			0.2,
			stuck_check_seconds * 0.75
		)
	_stuck_elapsed = 0.0
	_last_stuck_position = controlled_player.global_position


func _predict_ball_position_for_seconds(
	seconds: float
) -> Vector2:
	_refresh_perception_error()
	var predicted: Vector2 = (
		ball.global_position
		+ ball.linear_velocity * maxf(0.0, seconds)
		+ _perception_error
	)
	predicted.y = _reflect_y_inside_ball_walls(predicted.y)
	return _clamp_to_field(predicted)


func _get_predicted_ball_position() -> Vector2:
	return _predict_ball_position_for_seconds(
		ball_prediction_seconds
	)


func _predict_ball_position_for_execution_seconds(
	seconds: float
) -> Vector2:
	# Executors operate on the real simulated ball once the tactical brain has
	# committed. Any intelligence/perception error belongs to choosing the action,
	# not to physically walking to or striking a ball that was already selected.
	var predicted: Vector2 = (
		ball.global_position
		+ ball.linear_velocity * maxf(0.0, seconds)
	)
	predicted.y = _reflect_y_inside_ball_walls(predicted.y)
	return _clamp_to_field(predicted)


func _get_execution_predicted_ball_position() -> Vector2:
	return _predict_ball_position_for_execution_seconds(
		ball_prediction_seconds
	)


func _predict_goalkeeper_y(
	goal: FootballGoal,
	keeper_x: float
) -> float:
	var target_y = ball.global_position.y
	if absf(ball.linear_velocity.x) > 25.0:
		var travel_seconds = (
			keeper_x - ball.global_position.x
		) / ball.linear_velocity.x
		if travel_seconds > 0.0 and travel_seconds < 2.5:
			target_y += ball.linear_velocity.y * travel_seconds
			target_y = _reflect_y_inside_ball_walls(target_y)
	var mouth_range = goal.get_mouth_y_range()
	return clampf(
		target_y,
		mouth_range.x + goalkeeper_mouth_padding,
		mouth_range.y - goalkeeper_mouth_padding
	)


func _reflect_y_inside_ball_walls(raw_y: float) -> float:
	var reflected_y = raw_y
	for _bounce_index in range(6):
		if reflected_y < ball_wall_top_y:
			reflected_y = (
				ball_wall_top_y + (ball_wall_top_y - reflected_y)
			)
		elif reflected_y > ball_wall_bottom_y:
			reflected_y = (
				ball_wall_bottom_y
				- (reflected_y - ball_wall_bottom_y)
			)
		else:
			break
	return clampf(reflected_y, ball_wall_top_y, ball_wall_bottom_y)


func _get_shot_target(goal: FootballGoal) -> Vector2:
	_refresh_perception_error()
	var skill = _get_ai_skill()
	if _has_active_meta_vision() or skill >= 0.86:
		return _get_meta_vision_shot_target(goal)
	var center = _get_goal_center(goal)
	var phase = (
		float(controlled_player.owner_peer_id % 17) * 0.73
		+ float(Time.get_ticks_msec()) * 0.00055
	)
	center.y += sin(phase) * maxf(
		0.0,
		shot_aim_vertical_spread * lerpf(1.55, 0.18, skill)
	)
	center.y += clampf(
		_perception_error.y,
		-maximum_shot_aim_error * lerpf(1.45, 0.15, skill),
		maximum_shot_aim_error * lerpf(1.45, 0.15, skill)
	)
	var mouth_range = goal.get_mouth_y_range()
	center.y = clampf(center.y, mouth_range.x + 120.0, mouth_range.y - 120.0)
	return center


func _get_meta_vision_shot_target(goal: FootballGoal) -> Vector2:
	var mouth_range = goal.get_mouth_y_range()
	var minimum_y = mouth_range.x + 120.0
	var maximum_y = mouth_range.y - 120.0
	var center_y = (minimum_y + maximum_y) * 0.5
	var best_target = Vector2(goal.get_goal_plane_x(), center_y)
	var best_score = -INF
	var opponent_keeper = match_manager.get_designated_cpu_goalkeeper(
		TEAM_RED
		if controlled_player.team == TEAM_BLUE
		else TEAM_BLUE
	)
	var predicted_keeper_y = center_y
	if is_instance_valid(opponent_keeper):
		var travel_seconds = ball.global_position.distance_to(best_target) / maxf(
			900.0,
			ball.linear_velocity.length()
		)
		predicted_keeper_y = (
			opponent_keeper.global_position
			+ opponent_keeper.linear_velocity * minf(0.85, travel_seconds)
		).y
	var sample_count: int = 13 + int(round(
		get_elite_skill_extension_ratio() * 4.0
	))
	for sample_index in range(sample_count):
		var ratio = float(sample_index) / float(maxi(1, sample_count - 1))
		var candidate = Vector2(
			goal.get_goal_plane_x(),
			lerpf(minimum_y, maximum_y, ratio)
		)
		var lane_clearance = _minimum_pass_lane_clearance(candidate)
		var target_openness = _nearest_opponent_distance(candidate)
		var center_penalty = absf(candidate.y - center_y) * 0.025
		var keeper_separation = absf(candidate.y - predicted_keeper_y)
		var score = (
			lane_clearance * 1.35
			+ target_openness * 0.35
			+ keeper_separation * lerpf(0.18, 0.72, _get_ai_skill())
			- center_penalty
		)
		if score > best_score:
			best_score = score
			best_target = candidate
	return best_target


func _get_goal_center(goal: FootballGoal) -> Vector2:
	var mouth_range = goal.get_mouth_y_range()
	return Vector2(
		goal.get_goal_plane_x(),
		(mouth_range.x + mouth_range.y) * 0.5
	)


func _get_attack_sign() -> float:
	return (
		1.0
		if controlled_player.team == TEAM_BLUE
		else -1.0
	)


func _get_own_goal() -> FootballGoal:
	return (
		match_manager.blue_goal
		if controlled_player.team == TEAM_BLUE
		else match_manager.red_goal
	)


func _get_opponent_goal() -> FootballGoal:
	return (
		match_manager.red_goal
		if controlled_player.team == TEAM_BLUE
		else match_manager.blue_goal
	)


func _server_time_seconds() -> float:
	# Use a monotonic simulated-physics clock. Multiplying wall time by the
	# current time scale makes this clock jump backwards when training changes
	# from accelerated play to a 1x benchmark, leaving cooldown deadlines far
	# in the future. The project setting remains the base tick rate while the
	# trainer raises the runtime tick rate proportionally to time_scale.
	var base_physics_ticks = maxf(
		1.0,
		float(ProjectSettings.get_setting(
			"physics/common/physics_ticks_per_second",
			60
		))
	)
	return float(Engine.get_physics_frames()) / base_physics_ticks


func _get_ai_skill() -> float:
	return get_effective_skill_ratio()


func get_effective_skill_level() -> int:
	if skill_level_override > 0:
		return clampi(skill_level_override, 1, MAX_INTELLIGENCE)
	if match_manager == null:
		return 8
	return clampi(match_manager.cpu_ai_level, 1, MAX_INTELLIGENCE)


func get_effective_skill_ratio() -> float:
	# Intelligence 1-15 keeps the exact existing curve. Using 19 as the new
	# denominator would silently make every old CPU weaker, which is explicitly
	# not what the 20-level extension is for.
	var legacy_level: int = mini(
		get_effective_skill_level(),
		LEGACY_MAX_INTELLIGENCE
	)
	var linear_ratio: float = clampf(
		(float(legacy_level) - 1.0) / 14.0,
		0.0,
		1.0
	)
	return pow(linear_ratio, 1.35)


func get_elite_skill_extension_ratio() -> float:
	return clampf(
		(float(get_effective_skill_level()) - float(LEGACY_MAX_INTELLIGENCE))
		/ float(MAX_INTELLIGENCE - LEGACY_MAX_INTELLIGENCE),
		0.0,
		1.0
	)


func get_champion_utilization_ratio() -> float:
	# One brain, one ceiling:
	# INT 15 = 72% of learned policy
	# INT 16 = 77.6%
	# INT 17 = 83.2%
	# INT 18 = 88.8%
	# INT 19 = 94.4%
	# INT 20 = 100% (the current verified champion)
	var level: int = get_effective_skill_level()
	if level <= LEGACY_MAX_INTELLIGENCE:
		return clampf(
			get_effective_skill_ratio()
			* LEGACY_CHAMPION_UTILIZATION_AT_15,
			0.0,
			LEGACY_CHAMPION_UTILIZATION_AT_15
		)
	return lerpf(
		LEGACY_CHAMPION_UTILIZATION_AT_15,
		1.0,
		get_elite_skill_extension_ratio()
	)


func set_skill_level_override(level: int) -> void:
	var next_level: int = clampi(level, 0, MAX_INTELLIGENCE)
	if skill_level_override == next_level:
		return
	skill_level_override = next_level
	# A rung can reuse an existing controller. Refresh all skill-dependent
	# timing and perception immediately so it cannot continue briefly with the
	# previous rung's cadence/error state.
	_decision_accumulator = 0.0
	_next_decision_delay = _get_next_decision_delay()
	_hesitation_remaining = 0.0
	_perception_error = Vector2.ZERO
	_next_perception_refresh_at = 0.0
	_next_ability_decision_at = 0.0
	_next_ability_improvisation_at = 0.0
	_initialize_large_team_tactical_budget_state()


func _get_team_strategy() -> StringName:
	if match_manager == null or controlled_player == null:
		return CPU_STRATEGY_BALANCED
	var personality_strategy: StringName = _get_personality_strategy()
	if personality_strategy != CPU_STRATEGY_BALANCED:
		return personality_strategy
	return match_manager.get_cpu_team_strategy(controlled_player.team)


func set_cpu_personality(personality: StringName) -> void:
	if personality == CPU_PERSONALITY_AUTO:
		cpu_personality = "auto"
	else:
		cpu_personality = str(personality)
	_resolve_cpu_personality()


func get_cpu_personality() -> StringName:
	return _resolved_cpu_personality


func _resolve_cpu_personality() -> void:
	var requested: StringName = StringName(cpu_personality.to_lower())
	if requested in CPU_PERSONALITIES:
		_resolved_cpu_personality = requested
		return
	if controlled_player == null:
		_resolved_cpu_personality = CPU_PERSONALITY_ADAPTIVE
		return
	# Deterministic diversity: teammates keep stable identities between runs,
	# while both teams still receive a mixture of styles.
	var index: int = int(abs(int(controlled_player.owner_peer_id) * 17 + int(controlled_player.team_slot) * 31)) % CPU_PERSONALITIES.size()
	_resolved_cpu_personality = CPU_PERSONALITIES[index]


func _get_personality_strategy() -> StringName:
	match _resolved_cpu_personality:
		CPU_PERSONALITY_DIRECT:
			return CPU_STRATEGY_DIRECT
		CPU_PERSONALITY_TECHNICAL:
			return CPU_STRATEGY_WALL_PLAY
		CPU_PERSONALITY_POSSESSION:
			return CPU_STRATEGY_POSSESSION
		CPU_PERSONALITY_AGGRESSIVE:
			# Aggressive players attack space immediately with possession, then
			# counter-press at full intensity when the ball is lost.
			return (
				CPU_STRATEGY_DIRECT
				if _team_likely_has_possession()
				else CPU_STRATEGY_HIGH_PRESS
			)
		CPU_PERSONALITY_COUNTERATTACKER:
			return CPU_STRATEGY_COUNTER
		CPU_PERSONALITY_ADAPTIVE:
			return _get_adaptive_personality_strategy()
	return CPU_STRATEGY_BALANCED


func _get_adaptive_personality_strategy() -> StringName:
	if match_manager == null or controlled_player == null:
		return CPU_STRATEGY_BALANCED
	var own_score: int = int(match_manager.blue_score if controlled_player.team == TEAM_BLUE else match_manager.red_score)
	var other_score: int = int(match_manager.red_score if controlled_player.team == TEAM_BLUE else match_manager.blue_score)
	if own_score < other_score:
		return CPU_STRATEGY_DIRECT if _team_likely_has_possession() else CPU_STRATEGY_HIGH_PRESS
	if own_score > other_score:
		return CPU_STRATEGY_POSSESSION if _team_likely_has_possession() else CPU_STRATEGY_COUNTER
	var observed: Dictionary = _get_observed_opponent_style()
	match StringName(observed.get("style", &"balanced")):
		&"wall_heavy":
			return CPU_STRATEGY_HIGH_PRESS
		&"direct_heavy":
			return CPU_STRATEGY_COUNTER
		&"control_heavy":
			return CPU_STRATEGY_HIGH_PRESS
	if _ball_is_in_own_goal_danger():
		return CPU_STRATEGY_COUNTER
	return match_manager.get_cpu_team_strategy(controlled_player.team)


func _get_personality_planning_depth() -> float:
	var skill: float = _get_ai_skill()
	var style_bonus: float = 0.0
	match _resolved_cpu_personality:
		CPU_PERSONALITY_TECHNICAL, CPU_PERSONALITY_POSSESSION:
			style_bonus = 0.08
		CPU_PERSONALITY_ADAPTIVE:
			style_bonus = 0.13
		CPU_PERSONALITY_DIRECT, CPU_PERSONALITY_AGGRESSIVE:
			style_bonus = -0.04
	return clampf(lerpf(0.25, 1.0, skill) + style_bonus, 0.2, 1.0)


func _is_dictator_mbappe_cpu() -> bool:
	return (
		controlled_player != null
		and is_instance_valid(controlled_player)
		and controlled_player.display_name.strip_edges() == "Dictator Mbappe"
	)


func _get_personality_action_bias(action: StringName) -> float:
	var strength: float = clampf(personality_strength, 0.0, 1.0)
	var bias: float = 0.0
	if _is_dictator_mbappe_cpu():
		# Dictator's permanent Overdrive already gives him elite carrying power.
		# Without an explicit finishing preference the generic space score can
		# therefore make carrying win over perfectly good shots for several plans
		# in a row. Keep the dribble threat, but convert good angles much sooner.
		if action == &"direct_shot":
			bias += 300.0
		elif action == &"wall_shot":
			bias += 175.0
		elif action == &"rebound_setup":
			bias += 110.0
		elif action == &"self_pass":
			bias += 35.0
		elif action == &"carry":
			bias -= 210.0
		elif action == &"reset_possession":
			bias -= 180.0
	if controlled_player != null and controlled_player.is_haaland_boss():
		# Reuse the normal possession-action scoring, but make Haaland behave like
		# a ranged pressure specialist: take accurate long shots and use viable
		# bank angles instead of spending most possessions carrying the ball.
		if action == &"direct_shot":
			bias += 460.0
		elif action == &"wall_shot":
			bias += 310.0
		elif action == &"rebound_setup":
			bias += 120.0
		elif action == &"carry":
			bias -= 220.0
		elif action == &"reset_possession":
			bias -= 110.0
		elif action in [&"pass", &"one_two"]:
			bias -= 35.0
		var predator_active: bool = (
			controlled_player.server_haaland_predator_until
			>= _server_time_seconds()
		)
		if predator_active:
			# A completed feed should feel like a striker trigger: attack the finish
			# immediately instead of receiving the ball and restarting build-up.
			if action == &"direct_shot":
				bias += 330.0
			elif action == &"wall_shot":
				bias += 180.0
			elif action == &"rebound_setup":
				bias += 210.0
			elif action == &"carry":
				bias -= 180.0
			elif action == &"reset_possession":
				bias -= 150.0
			elif action in [&"pass", &"one_two"]:
				bias -= 105.0
	match _resolved_cpu_personality:
		CPU_PERSONALITY_DIRECT:
			if action in [&"direct_shot", &"self_pass", &"carry"]:
				bias += 150.0
			if action in [&"reset_possession", &"pass"]:
				bias -= 70.0
		CPU_PERSONALITY_TECHNICAL:
			if action in [&"wall_shot", &"self_pass", &"one_two"]:
				bias += 170.0
			if action == &"direct_shot":
				bias -= 45.0
		CPU_PERSONALITY_POSSESSION:
			if action in [&"pass", &"one_two", &"reset_possession", &"carry"]:
				bias += 145.0
			if action in [&"wall_shot", &"direct_shot"]:
				bias -= 55.0
		CPU_PERSONALITY_AGGRESSIVE:
			if action in [&"direct_shot", &"self_pass", &"rebound_setup"]:
				bias += 130.0
			if action == &"reset_possession":
				bias -= 105.0
		CPU_PERSONALITY_COUNTERATTACKER:
			# Counterattackers should turn recovered space into immediate pressure.
			# Long direct shots and bank shots are preferred over endlessly dribbling,
			# while self-passes remain available when the shooting lane is not ready.
			if action == &"direct_shot":
				bias += 220.0
			elif action == &"wall_shot":
				bias += 195.0
			elif action == &"rebound_setup":
				bias += 95.0
			elif action == &"self_pass":
				bias += 70.0
			elif action in [&"carry", &"pass"]:
				bias += 25.0
			elif action == &"reset_possession":
				bias -= 95.0
		CPU_PERSONALITY_ADAPTIVE:
			var observed: Dictionary = _get_observed_opponent_style()
			match StringName(observed.get("style", &"balanced")):
				&"wall_heavy":
					if action in [&"carry", &"pass", &"one_two"]:
						bias += 95.0
				&"direct_heavy":
					if action in [&"reset_possession", &"pass", &"self_pass"]:
						bias += 90.0
				&"control_heavy":
					if action in [&"direct_shot", &"self_pass", &"rebound_setup"]:
						bias += 90.0
	return bias * strength


func _on_ball_player_kicked_for_personality(
	_peer_id: int,
	_player_name: String,
	player_team: StringName,
	kick_position: Vector2,
	predicted_velocity: Vector2
) -> void:
	if controlled_player == null or player_team == controlled_player.team:
		return
	if player_team not in [TEAM_BLUE, TEAM_RED]:
		return
	_decay_opponent_style_samples()
	_opponent_style_samples += 1.0
	var attack_sign: float = 1.0 if player_team == TEAM_BLUE else -1.0
	var forward_speed: float = predicted_velocity.x * attack_sign
	var goal: FootballGoal = _get_own_goal()
	var used_wall_route: bool = false
	if goal != null and absf(predicted_velocity.x) > 0.01:
		var time_to_goal: float = (goal.get_goal_plane_x() - kick_position.x) / predicted_velocity.x
		if time_to_goal > 0.0:
			var projected_y: float = kick_position.y + predicted_velocity.y * time_to_goal
			used_wall_route = projected_y < minimum_field_y or projected_y > maximum_field_y
	if used_wall_route:
		_opponent_wall_kicks += 1.0
	elif forward_speed >= 1450.0:
		_opponent_forward_kicks += 1.0
	else:
		_opponent_control_kicks += 1.0


func _decay_opponent_style_samples() -> void:
	var now: float = _server_time_seconds()
	if _opponent_style_last_decay_at <= 0.0:
		_opponent_style_last_decay_at = now
		return
	var elapsed: float = now - _opponent_style_last_decay_at
	if elapsed < maxf(3.0, personality_adaptation_window_seconds * 0.35):
		return
	var retain: float = pow(0.5, elapsed / maxf(4.0, personality_adaptation_window_seconds))
	_opponent_style_samples *= retain
	_opponent_wall_kicks *= retain
	_opponent_forward_kicks *= retain
	_opponent_control_kicks *= retain
	_opponent_style_last_decay_at = now


func _get_observed_opponent_style() -> Dictionary:
	_decay_opponent_style_samples()
	var total: float = maxf(1.0, _opponent_style_samples)
	var wall_share: float = _opponent_wall_kicks / total
	var direct_share: float = _opponent_forward_kicks / total
	var control_share: float = _opponent_control_kicks / total
	var style: StringName = &"balanced"
	if _opponent_style_samples >= 4.0:
		if wall_share >= 0.34:
			style = &"wall_heavy"
		elif direct_share >= 0.58:
			style = &"direct_heavy"
		elif control_share >= 0.58:
			style = &"control_heavy"
	return {
		"style": str(style),
		"samples": _opponent_style_samples,
		"wall_share": wall_share,
		"direct_share": direct_share,
		"control_share": control_share
	}


func _uses_perfect_execution() -> bool:
	# The hardest CPU keeps the old deterministic execution. Lower difficulties
	# still use the same tactical systems, but execution quality now scales with
	# skill instead of every level receiving perfect inputs for free.
	return perfect_execution_mode and _get_ai_skill() >= 0.92


func _get_next_decision_delay() -> float:
	var skill = _get_ai_skill()
	var tempo: float = _get_high_tempo_strength()
	var base_delay: float = 0.08
	if _uses_perfect_execution() or _has_active_meta_vision():
		var legacy_delay: float = minf(0.032, maxf(0.020, decision_interval))
		var elite_delay: float = lerpf(
			legacy_delay,
			maxf(0.008, high_tempo_elite_decision_seconds),
			tempo
		)
		var elite_jitter: float = (
			maxf(0.0, high_tempo_elite_decision_jitter) * tempo
		)
		base_delay = maxf(
			0.008,
			elite_delay
			+ _rng.randf_range(-elite_jitter, elite_jitter)
		)
	else:
		var scaled_interval = lerpf(
			maxf(0.14, decision_interval * 2.2),
			maxf(0.036, decision_interval * 0.62),
			skill
		)
		var scaled_jitter = lerpf(
			maxf(0.065, decision_interval_jitter * 2.0),
			maxf(0.002, decision_interval_jitter * 0.10),
			skill
		)
		var high_tempo_interval: float = lerpf(
			scaled_interval,
			maxf(0.012, high_tempo_elite_decision_seconds * 1.35),
			tempo
		)
		base_delay = maxf(
			0.010,
			high_tempo_interval
			+ _rng.randf_range(
				-scaled_jitter * (1.0 - tempo * 0.8),
				scaled_jitter * (1.0 - tempo * 0.8)
			)
		)
	# On 5v5/6v6 the significance budget is a minimum tactical interval, not a
	# simulation-rate change. Critical actors retain the fast cadence while
	# distant formation players stop rebuilding expensive plans unnecessarily.
	var budget := _get_large_team_tactical_budget()
	if not budget.is_empty():
		base_delay = maxf(base_delay, float(budget.get("interval", 0.0)))
	return base_delay


func _roll_human_mistake() -> bool:
	if not legacy_skill_execution_errors_enabled:
		return false
	if _uses_perfect_execution():
		return false
	var skill = _get_ai_skill()
	if _has_active_meta_vision() or _has_obvious_play():
		return false
	var effective_mistake_chance = lerpf(
		maxf(0.018, mistake_chance_per_decision * 5.0),
		maxf(0.0, elite_mistake_chance_floor),
		skill
	)
	if _rng.randf() >= effective_mistake_chance:
		return false
	_hesitation_remaining = _rng.randf_range(
		maxf(0.0, hesitation_min_seconds) * lerpf(2.2, 0.2, skill),
		maxf(hesitation_min_seconds, hesitation_max_seconds)
		* lerpf(2.7, 0.2, skill)
	)
	controlled_player.server_direction = Vector2.ZERO
	return true


func _has_obvious_play() -> bool:
	if _incoming_ball_threat(1050.0, 320.0):
		return true
	if controlled_player.cpu_has_kickable_ball():
		if _get_active_pass_request_receiver() != null:
			return true
		if (
			_server_time_seconds() - _last_secure_recovery_at
			<= maxf(0.1, possession_action_recovery_window_seconds)
		):
			return true
	var loose_claim = _get_relative_loose_ball_claim()
	if (
		not loose_claim.is_empty()
		and int(loose_claim.get("peer_id", 0))
		== controlled_player.owner_peer_id
	):
		return true
	# Hesitation may create believable attacking mistakes, but it must never
	# make a CPU watch an opponent carry or contest the ball. Defensive role
	# assignment already decides whether this player presses, covers, or marks.
	if (
		not _team_likely_has_possession()
		and _get_likely_opponent_ball_carrier() != null
	):
		return true
	var opponent_goal = _get_opponent_goal()
	if opponent_goal != null:
		var close_to_ball = (
			controlled_player.global_position.distance_to(ball.global_position)
			< controlled_player.kick_feedback_detection_distance * 1.25
		)
		var goal_target = _get_goal_center(opponent_goal)
		if (
			close_to_ball
			and ball.global_position.distance_to(goal_target)
			< committed_shot_goal_distance
			and _minimum_segment_clearance(
				ball.global_position,
				goal_target
			) > 170.0
		):
			return true
	if _is_designated_goalkeeper(controlled_player):
		return not _predict_own_goal_threat(2.2).is_empty()
	return false


func _refresh_perception_error() -> void:
	var skill = _get_ai_skill()
	if _uses_perfect_execution() or _has_active_meta_vision():
		_perception_error = Vector2.ZERO
		_next_perception_refresh_at = 0.0
		return
	var now = _server_time_seconds()
	if now < _next_perception_refresh_at:
		return
	_next_perception_refresh_at = (
		now + lerpf(
			maxf(0.85, perception_error_refresh_seconds * 1.35),
			0.12,
			skill
		)
	)
	var radius = maxf(0.0, maximum_ball_read_error) * lerpf(
		2.25,
		elite_perception_error_ratio,
		skill
	)
	_perception_error = Vector2(
		_rng.randf_range(-radius, radius),
		_rng.randf_range(-radius, radius)
	)


func _consider_ability_use() -> bool:
	var now: float = _server_time_seconds()
	if _ability_executor_active:
		return true
	if controlled_player.server_ability_active:
		var active_ability_id: int = controlled_player.server_active_ability_id
		var wants_followup := false
		match active_ability_id:
			FootballPlayer.ABILITY_HEEL_TURN:
				wants_followup = (
					controlled_player.cpu_can_execute_phantom_heel_followup()
					and _phantom_heel_followup_is_useful()
				)
			FootballPlayer.ABILITY_SIDE_SWIPE:
				wants_followup = (
					controlled_player.cpu_has_kickable_ball()
					and (_plan_is_pass or _side_swipe_escape_touch_is_useful())
				)
			FootballPlayer.ABILITY_BREAKAWAY:
				wants_followup = (
					controlled_player.cpu_has_kickable_ball()
					and _breakaway_trigger_is_useful()
				)
			FootballPlayer.ABILITY_SNAPBACK:
				wants_followup = (
					controlled_player.cpu_has_snapback_recall()
					and _snapback_recall_is_useful()
				)
		if wants_followup:
			return _adopt_active_ability_followup(
				active_ability_id,
				_resolve_ability_action_target(),
				_tactical_intent_peer_id
			)
		return false
	if (
		controlled_player.selected_ability == FootballPlayer.ABILITY_NONE
		or now < _next_ability_decision_at
		or not _cpu_ability_is_ready()
	):
		return false
	var skill = _get_ai_skill()
	var ability_think_scale = lerpf(1.55, 0.55, skill)
	ability_think_scale *= lerpf(
		1.0,
		0.76,
		get_elite_skill_extension_ratio()
	)
	if _get_team_strategy() == CPU_STRATEGY_ABILITY_COMBO:
		ability_think_scale *= 0.72
	var is_neymar_elastic_boss: bool = (
		controlled_player.is_neymar_boss()
		and controlled_player.selected_ability == FootballPlayer.ABILITY_ELASTIC_STEP
	)
	if is_neymar_elastic_boss:
		# Unlimited charges are not an excuse to button-mash. Neymar gets a
		# quick but readable rhythm so each step can finish and the ball can
		# settle into the selected escape lane before another feint begins.
		_next_ability_decision_at = now + _rng.randf_range(0.18, 0.28)
	else:
		_next_ability_decision_at = (
			now + _rng.randf_range(0.16, 0.34) * ability_think_scale
		)

	var ability_id = controlled_player.selected_ability
	# The tactical action chosen earlier this decision is authoritative. Ability
	# usefulness only competes inside a compatible football action (attack/pass/
	# shot/defense); it can no longer override a different responsibility just
	# because its own subsystem found a locally-valid activation window.
	var ability_tactical_intent := _resolve_ability_tactical_context_intent(
		ability_id
	)
	if ability_tactical_intent == INTENT_IDLE:
		return false
	if _tactical_intent_action == INTENT_IDLE:
		_set_tactical_intent(
			ability_tactical_intent,
			_resolve_ability_action_target(),
			_tactical_intent_peer_id
		)
	if not _ability_candidate_matches_tactical_action(
		ability_id,
		ability_tactical_intent
	):
		return false

	var should_activate = false
	match ability_id:
		FootballPlayer.ABILITY_BURST_DRIBBLE:
			should_activate = _burst_dribble_is_useful()
		FootballPlayer.ABILITY_QUICK_TRIGGER, FootballPlayer.ABILITY_POWER_STRIKE:
			should_activate = _shot_ability_is_useful(ability_id)
		FootballPlayer.ABILITY_OVERDRIVE:
			should_activate = _overdrive_is_useful()
		FootballPlayer.ABILITY_HEEL_TURN:
			should_activate = _heel_turn_is_useful()
		FootballPlayer.ABILITY_ENFORCER:
			should_activate = _enforcer_is_useful()
		FootballPlayer.ABILITY_GOALKEEPER_REACH:
			should_activate = _goalkeeper_reach_is_needed()
		FootballPlayer.ABILITY_TIME_SKIP_PASS:
			should_activate = _dead_zone_pass_is_useful()
		FootballPlayer.ABILITY_DIRECT_FINISH:
			should_activate = _trap_or_volley_is_useful()
		FootballPlayer.ABILITY_ELASTIC_STEP:
			should_activate = _elastic_step_is_useful()
		FootballPlayer.ABILITY_META_VISION:
			should_activate = _meta_vision_is_useful()
		FootballPlayer.ABILITY_COPYCAT:
			should_activate = _copycat_is_useful(now)
		FootballPlayer.ABILITY_REFLEX_BLOCK:
			should_activate = _reflex_block_is_useful()
		FootballPlayer.ABILITY_IRON_ANCHOR:
			should_activate = _iron_anchor_is_useful()
		FootballPlayer.ABILITY_BLIND_SPOT:
			should_activate = _mirage_step_is_useful()
		FootballPlayer.ABILITY_BOOGIE_WOOGIE:
			should_activate = _boogie_woogie_is_useful()
		FootballPlayer.ABILITY_ECHO:
			should_activate = _echo_is_useful()
		FootballPlayer.ABILITY_RETURN_TAG:
			should_activate = _return_tag_is_useful()
		FootballPlayer.ABILITY_BREAKAWAY:
			should_activate = _breakaway_is_useful()
		FootballPlayer.ABILITY_SNAPBACK:
			should_activate = _snapback_is_useful()
		FootballPlayer.ABILITY_SIDE_SWIPE:
			should_activate = _side_swipe_is_useful()
		FootballPlayer.ABILITY_NUTMEG:
			should_activate = _nutmeg_is_useful()
		FootballPlayer.ABILITY_DECOY_RUN:
			should_activate = _decoy_run_is_useful()

	# Neymar's bespoke evaluator is authoritative. Generic combination and
	# improvisation fallbacks are intentionally skipped because their broad
	# pressure windows were causing the no-cooldown boss to spam bad steps.
	if not should_activate and not is_neymar_elastic_boss:
		should_activate = _elite_combination_ability_is_useful(ability_id)
	if not should_activate and not is_neymar_elastic_boss:
		should_activate = _should_improvise_ability(ability_id, now)
	if not should_activate and not is_neymar_elastic_boss:
		should_activate = _training_ability_exploration_is_useful(
			ability_id,
			now
		)

	if not should_activate:
		return false
	if (
		not is_neymar_elastic_boss
		and not _has_active_meta_vision()
		and _rng.randf()
		< missed_read_chance * lerpf(1.8, elite_missed_read_ratio, skill)
	):
		return false

	var preparation_ability_id = ability_id
	if ability_id == FootballPlayer.ABILITY_COPYCAT:
		preparation_ability_id = _get_copycat_source_ability(now)
		if preparation_ability_id == FootballPlayer.ABILITY_NONE:
			return false
	var activated := _request_ability_action(
		ability_id,
		_resolve_ability_action_target(),
		_tactical_intent_peer_id,
		ability_tactical_intent,
		preparation_ability_id,
		false
	)
	if activated and is_neymar_elastic_boss:
		var committed_direction: Vector2 = _ability_executor_direction
		if not committed_direction.is_zero_approx():
			_neymar_elastic_direction = committed_direction
			_neymar_elastic_direction_until = now + 0.52
			_solo_attack_direction = committed_direction
			_solo_attack_direction_lock_until = now + 0.42
			_dribble_until = maxf(_dribble_until, now + 0.48)
			_shot_target = _clamp_to_field(
				ball.global_position + committed_direction * 1250.0
			)
			_planned_destination = _shot_target
			_ability_executor_target = _shot_target
			_ability_executor_movement_target = _shot_target
			_set_tactical_intent(INTENT_DRIBBLE, _shot_target)
			_ability_executor_source_intent = INTENT_DRIBBLE
	if activated and ability_id == FootballPlayer.ABILITY_BLIND_SPOT:
		_mirage_setup_target = null
		_mirage_activate_after = 0.0
	return activated


func _elite_combination_ability_is_useful(ability_id: int) -> bool:
	if _get_ai_skill() < elite_combination_minimum_skill:
		return false
	var plan = match_manager.get_cpu_combination_plan(controlled_player.team)
	if plan.is_empty():
		return false
	var peer_id = controlled_player.owner_peer_id
	var is_initiator = int(plan.get("initiator_peer_id", 0)) == peer_id
	var is_receiver = int(plan.get("receiver_peer_id", 0)) == peer_id
	var is_next_runner = int(plan.get("next_peer_id", 0)) == peer_id
	if not is_initiator and not is_receiver and not is_next_runner:
		return false
	var ball_distance = controlled_player.global_position.distance_to(
		ball.global_position
	)
	var kick_distance = controlled_player.kick_feedback_detection_distance
	var nearest_pressure = _nearest_opponent_distance(
		controlled_player.global_position
	)
	match ability_id:
		FootballPlayer.ABILITY_TIME_SKIP_PASS:
			return (
				is_receiver
				and ball_distance <= kick_distance * 1.15
				and _dead_zone_pass_is_useful()
			)
		FootballPlayer.ABILITY_HEEL_TURN:
			return (
				is_receiver
				and ball_distance <= kick_distance
				and nearest_pressure < 920.0
			)
		FootballPlayer.ABILITY_META_VISION:
			return is_receiver and ball_distance < 1650.0
		FootballPlayer.ABILITY_IRON_ANCHOR:
			return (
				is_receiver
				and ball_distance <= controlled_player.iron_anchor_trap_radius * 1.2
				and ball.linear_velocity.length() > 430.0
			)
		FootballPlayer.ABILITY_OVERDRIVE:
			var run_target: Vector2 = plan.get(
				"next_run_target",
				controlled_player.global_position
			)
			return (
				is_next_runner
				and controlled_player.global_position.distance_to(run_target) > 620.0
			)
		FootballPlayer.ABILITY_DIRECT_FINISH:
			return is_next_runner and _incoming_ball_threat(1500.0, 180.0)
		FootballPlayer.ABILITY_BURST_DRIBBLE, FootballPlayer.ABILITY_ELASTIC_STEP:
			return (
				is_receiver
				and ball_distance <= kick_distance * 1.2
				and nearest_pressure < 850.0
			)
		FootballPlayer.ABILITY_BLIND_SPOT:
			return (
				is_receiver
				and ball_distance <= kick_distance * 1.25
				and nearest_pressure < 760.0
			)
		FootballPlayer.ABILITY_ENFORCER:
			return is_initiator and nearest_pressure < 680.0
		FootballPlayer.ABILITY_RETURN_TAG:
			return (
				is_initiator
				and _plan_is_pass
				and ball_distance <= kick_distance * 1.2
			)
		FootballPlayer.ABILITY_SIDE_SWIPE:
			return (
				(is_initiator or is_receiver)
				and ball_distance <= kick_distance * 1.15
				and _nearest_opponent_distance(ball.global_position) < 1050.0
			)
		FootballPlayer.ABILITY_ECHO:
			return _echo_is_useful()
		FootballPlayer.ABILITY_BREAKAWAY:
			return is_receiver and ball_distance <= kick_distance * 1.15 and nearest_pressure < 900.0
		FootballPlayer.ABILITY_SNAPBACK:
			return is_initiator and ball_distance <= kick_distance * 1.15 and nearest_pressure < 850.0
		FootballPlayer.ABILITY_POWER_STRIKE, FootballPlayer.ABILITY_QUICK_TRIGGER:
			var opponent_goal = _get_opponent_goal()
			return (
				is_next_runner
				and opponent_goal != null
				and ball_distance <= kick_distance * 1.3
				and ball.global_position.distance_to(_get_goal_center(opponent_goal))
				< committed_shot_goal_distance * 1.15
			)
	return false


func _should_improvise_ability(ability_id: int, now: float) -> bool:
	if now < _next_ability_improvisation_at:
		return false
	_next_ability_improvisation_at = now + _rng.randf_range(
		maxf(0.2, ability_improvisation_min_interval),
		maxf(
			maxf(0.2, ability_improvisation_min_interval),
			ability_improvisation_max_interval
		)
	)

	var effective_ability = ability_id
	if ability_id == FootballPlayer.ABILITY_COPYCAT:
		effective_ability = _get_copycat_source_ability(now)
		if effective_ability == FootballPlayer.ABILITY_NONE:
			return false

	if not _ability_has_improvisation_window(effective_ability):
		return false

	var chance = clampf(ability_improvisation_chance, 0.0, 1.0)
	chance *= float(_trained_ability_use_biases.get(effective_ability, 1.0))
	match effective_ability:
		FootballPlayer.ABILITY_POWER_STRIKE:
			chance *= power_strike_improvisation_multiplier
		FootballPlayer.ABILITY_QUICK_TRIGGER, FootballPlayer.ABILITY_TIME_SKIP_PASS, FootballPlayer.ABILITY_RETURN_TAG, FootballPlayer.ABILITY_BREAKAWAY, FootballPlayer.ABILITY_SNAPBACK, FootballPlayer.ABILITY_SIDE_SWIPE:
			chance *= 1.35
		FootballPlayer.ABILITY_BURST_DRIBBLE, FootballPlayer.ABILITY_ELASTIC_STEP, FootballPlayer.ABILITY_BLIND_SPOT:
			chance *= 1.1
		FootballPlayer.ABILITY_HEEL_TURN, FootballPlayer.ABILITY_ENFORCER:
			chance *= 0.8
		FootballPlayer.ABILITY_GOALKEEPER_REACH, FootballPlayer.ABILITY_REFLEX_BLOCK, FootballPlayer.ABILITY_IRON_ANCHOR, FootballPlayer.ABILITY_ECHO:
			chance *= 0.65
	return _rng.randf() < clampf(chance, 0.0, 0.9)


func _training_ability_exploration_is_useful(
	ability_id: int,
	now: float
) -> bool:
	if match_manager == null or not match_manager.cpu_training_mode:
		return false
	if (
		controlled_player.server_last_ability_used_at > 0.0
		and now - controlled_player.server_last_ability_used_at < 8.0
	):
		return false
	var effective_ability = ability_id
	if ability_id == FootballPlayer.ABILITY_COPYCAT:
		effective_ability = _get_copycat_source_ability(now)
		if effective_ability == FootballPlayer.ABILITY_NONE:
			return false
	var ball_distance = controlled_player.global_position.distance_to(
		ball.global_position
	)
	var kick_distance = maxf(
		80.0,
		controlled_player.kick_feedback_detection_distance
	)
	match effective_ability:
		FootballPlayer.ABILITY_POWER_STRIKE, FootballPlayer.ABILITY_QUICK_TRIGGER:
			return (
				_is_primary_ball_chaser()
				and ball_distance <= kick_distance * 1.1
				and not _ball_is_in_own_goal_danger()
			)
		FootballPlayer.ABILITY_TIME_SKIP_PASS:
			# Even exploration must respect the real Dead Zone route. Otherwise the
			# trainer teaches itself the same out-of-range pseudo-shot we reject in
			# live play.
			return (
				ball_distance <= kick_distance * 1.15
				and _dead_zone_pass_is_useful()
			)
		FootballPlayer.ABILITY_BURST_DRIBBLE, FootballPlayer.ABILITY_ELASTIC_STEP, FootballPlayer.ABILITY_HEEL_TURN, FootballPlayer.ABILITY_DIRECT_FINISH, FootballPlayer.ABILITY_IRON_ANCHOR, FootballPlayer.ABILITY_BLIND_SPOT, FootballPlayer.ABILITY_BREAKAWAY, FootballPlayer.ABILITY_SNAPBACK, FootballPlayer.ABILITY_SIDE_SWIPE:
			return ball_distance <= kick_distance * 1.15
		FootballPlayer.ABILITY_ENFORCER:
			return _nearest_opponent_distance(
				controlled_player.global_position
			) < 900.0
		FootballPlayer.ABILITY_GOALKEEPER_REACH, FootballPlayer.ABILITY_REFLEX_BLOCK:
			return (
				ball_distance < 1700.0
				and _last_ball_touch_was_opponent()
			)
		FootballPlayer.ABILITY_OVERDRIVE, FootballPlayer.ABILITY_META_VISION:
			return (
				_is_primary_ball_chaser()
				or ball_distance < 2300.0
			)
		FootballPlayer.ABILITY_BOOGIE_WOOGIE:
			return _get_nearest_opponent_to(
				controlled_player.global_position
			) != null
	return false


func _ability_has_improvisation_window(ability_id: int) -> bool:
	var ball_distance = controlled_player.global_position.distance_to(
		ball.global_position
	)
	var kick_distance = maxf(
		80.0,
		controlled_player.kick_feedback_detection_distance
	)
	var attacking_shot_available = _has_improvised_shot_opportunity()

	match ability_id:
		FootballPlayer.ABILITY_QUICK_TRIGGER:
			return attacking_shot_available
		FootballPlayer.ABILITY_POWER_STRIKE:
			return (
				attacking_shot_available
				and _power_strike_improvisation_is_safe()
			)
		FootballPlayer.ABILITY_OVERDRIVE, FootballPlayer.ABILITY_META_VISION:
			return attacking_shot_available
		FootballPlayer.ABILITY_TIME_SKIP_PASS:
			# Dead Zone is a pass/self-pass tool, never a generic shot improvisation.
			return (
				ball_distance <= kick_distance
				and _dead_zone_pass_is_useful()
			)
		FootballPlayer.ABILITY_BURST_DRIBBLE:
			return (
				attacking_shot_available
				and ball.linear_velocity.length()
				< maxf(200.0, burst_dribble_maximum_ball_speed)
			)
		FootballPlayer.ABILITY_ELASTIC_STEP:
			return (
				attacking_shot_available
				and _nearest_opponent_distance(ball.global_position) < 1050.0
			)
		FootballPlayer.ABILITY_HEEL_TURN:
			return (
				ball_distance <= kick_distance
				and not _ball_is_in_own_goal_danger()
				and _nearest_opponent_distance(ball.global_position) < 780.0
			)
		FootballPlayer.ABILITY_DIRECT_FINISH:
			return (
				_incoming_ball_threat(1300.0, 190.0)
				and not _ball_is_in_own_goal_danger()
			)
		FootballPlayer.ABILITY_BLIND_SPOT:
			return (
				attacking_shot_available
				and _get_nearest_opponent_to(
					controlled_player.global_position
				) != null
				and _nearest_opponent_distance(
					controlled_player.global_position
				) < 900.0
			)
		FootballPlayer.ABILITY_ENFORCER:
			return (
				_get_nearest_opponent_to(
					controlled_player.global_position
				) != null
				and _nearest_opponent_distance(
					controlled_player.global_position
				) < 650.0
			)
		FootballPlayer.ABILITY_REFLEX_BLOCK:
			return (
				_last_ball_touch_was_opponent()
				and _incoming_ball_threat(1300.0, 430.0)
			)
		FootballPlayer.ABILITY_IRON_ANCHOR:
			return (
				ball_distance <= controlled_player.iron_anchor_trap_radius
				and ball.linear_velocity.length() > 380.0
			)
		FootballPlayer.ABILITY_GOALKEEPER_REACH:
			return (
				_is_designated_goalkeeper(controlled_player)
				and _incoming_ball_threat(1150.0, 520.0)
			)
		FootballPlayer.ABILITY_ECHO:
			return _echo_is_useful()
		FootballPlayer.ABILITY_RETURN_TAG:
			return _return_tag_is_useful()
		FootballPlayer.ABILITY_BREAKAWAY:
			return _breakaway_is_useful()
		FootballPlayer.ABILITY_SNAPBACK:
			return _snapback_is_useful()
		FootballPlayer.ABILITY_SIDE_SWIPE:
			return _side_swipe_is_useful()
		FootballPlayer.ABILITY_NUTMEG:
			return _nutmeg_is_useful()
		FootballPlayer.ABILITY_DECOY_RUN:
			return _decoy_run_is_useful()
	return false


func _has_improvised_shot_opportunity() -> bool:
	if (
		_plan_is_pass
		or _ball_is_in_own_goal_danger()
		or not _is_primary_ball_chaser()
	):
		return false
	var opponent_goal = _get_opponent_goal()
	if opponent_goal == null:
		return false
	var ball_distance = controlled_player.global_position.distance_to(
		ball.global_position
	)
	if (
		ball_distance
		> controlled_player.kick_feedback_detection_distance * 1.15
	):
		return false
	var goal_target = _get_goal_center(opponent_goal)
	return (
		ball.global_position.distance_to(goal_target)
		<= committed_shot_goal_distance * 1.25
		and _minimum_segment_clearance(
			ball.global_position,
			goal_target
		) > 85.0
	)


func _power_strike_improvisation_is_safe() -> bool:
	if _ball_is_in_own_goal_danger():
		return false
	var opponent_goal = _get_opponent_goal()
	if opponent_goal == null:
		return false
	var goal_target = _get_goal_center(opponent_goal)
	var goal_distance = ball.global_position.distance_to(goal_target)
	if goal_distance < 720.0:
		return false
	var lane_clearance = _minimum_segment_clearance(
		ball.global_position,
		goal_target
	)
	var minimum_lane: float = maxf(
		80.0,
		power_strike_minimum_safe_lane * 0.72
	)
	var second_ball_value: float = _get_best_team_second_ball_value(
		_get_goal_center(opponent_goal)
	)
	if lane_clearance < minimum_lane:
		if (
			second_ball_value < 0.68
			or lane_clearance < maxf(80.0, minimum_lane * 0.72)
		):
			return false
	return (
		_team_has_counter_cover()
		or second_ball_value >= 0.62
		or not _has_other_active_teammate()
		or goal_distance <= power_strike_cover_required_distance
	)


func _has_active_meta_vision() -> bool:
	if not is_instance_valid(controlled_player):
		return false
	if (
		controlled_player.cpu_controlled
		and innate_meta_vision
		and _get_ai_skill() >= 0.92
	):
		return true
	return (
		controlled_player.server_ability_active
		and controlled_player.server_active_ability_id
		== FootballPlayer.ABILITY_META_VISION
	)


func _prepare_ability_direction(ability_id: int) -> void:
	match ability_id:
		FootballPlayer.ABILITY_BREAKAWAY, FootballPlayer.ABILITY_SNAPBACK, FootballPlayer.ABILITY_SIDE_SWIPE:
			if not _planned_destination.is_zero_approx():
				controlled_player.server_direction = ball.global_position.direction_to(_planned_destination)
			else:
				controlled_player.server_direction = Vector2(_get_attack_sign(), 0.0)
		FootballPlayer.ABILITY_RETURN_TAG:
			if not _planned_destination.is_zero_approx():
				controlled_player.server_direction = (
					ball.global_position.direction_to(_planned_destination)
				)
		FootballPlayer.ABILITY_TIME_SKIP_PASS:
			if not _planned_destination.is_zero_approx():
				controlled_player.server_direction = (
					ball.global_position.direction_to(
						_planned_destination
					)
				)
		FootballPlayer.ABILITY_BURST_DRIBBLE:
			var dribble_direction = Vector2.ZERO
			if (
				_server_time_seconds() < _burst_gap_close_until
				and not _burst_gap_close_target.is_zero_approx()
			):
				dribble_direction = (
					controlled_player.global_position.direction_to(
						_burst_gap_close_target
					)
				)
			else:
				dribble_direction = ball.global_position.direction_to(
					_shot_target
				)
			if dribble_direction.is_zero_approx():
				dribble_direction = Vector2(_get_attack_sign(), 0.0)
			controlled_player.server_direction = dribble_direction
		FootballPlayer.ABILITY_ELASTIC_STEP:
			controlled_player.server_direction = (
				_get_elastic_escape_direction()
			)
		FootballPlayer.ABILITY_HEEL_TURN:
			# Pick a real pressure escape before the first heel drag. The player
			# ability then remembers that side and cuts across the opposite side
			# when the CPU commits its follow-up input.
			controlled_player.server_direction = (
				_get_elastic_escape_direction()
			)
		FootballPlayer.ABILITY_QUICK_TRIGGER, FootballPlayer.ABILITY_POWER_STRIKE:
			controlled_player.server_direction = (
				ball.global_position.direction_to(_shot_target)
			)
		FootballPlayer.ABILITY_DIRECT_FINISH:
			var opponent_goal = _get_opponent_goal()
			if opponent_goal != null:
				controlled_player.server_direct_finish_volley_requested = (
					_should_direct_finish_volley(opponent_goal)
				)
				controlled_player.server_direct_finish_aim_direction = (
					controlled_player.global_position.direction_to(
						_get_meta_vision_shot_target(opponent_goal)
						if _has_active_meta_vision()
						else _get_goal_center(opponent_goal)
					)
				)
		FootballPlayer.ABILITY_REFLEX_BLOCK:
			controlled_player.server_direction = (
				_get_reflex_block_facing()
			)
		FootballPlayer.ABILITY_IRON_ANCHOR:
			controlled_player.server_direction = (
				controlled_player.global_position.direction_to(
					ball.global_position
				)
			)
		FootballPlayer.ABILITY_GOALKEEPER_REACH:
			if not _goalkeeper_reach_target.is_zero_approx():
				controlled_player.server_direction = (
					controlled_player.global_position.direction_to(
						_goalkeeper_reach_target
					)
				)


func _get_reflex_block_facing() -> Vector2:
	var ball_offset = controlled_player.global_position.direction_to(
		ball.global_position
	)
	if ball_offset.is_zero_approx():
		return Vector2(_get_attack_sign(), 0.0)
	var opponent_goal = _get_opponent_goal()
	if opponent_goal == null:
		return ball_offset
	var counter_direction = controlled_player.global_position.direction_to(
		_get_goal_center(opponent_goal)
	)
	var deflection_angle = deg_to_rad(
		clampf(
			controlled_player.reflex_block_deflection_degrees,
			0.0,
			90.0
		)
	)
	var minimum_facing_dot = cos(
		deg_to_rad(
			clampf(
				controlled_player.reflex_block_cone_degrees,
				1.0,
				179.0
			) * 0.5
		)
	)
	for side in [-1.0, 1.0]:
		var candidate = counter_direction.rotated(-side * deflection_angle)
		var actual_side = signf(candidate.cross(ball_offset))
		if (
			actual_side == side
			and candidate.dot(ball_offset) >= minimum_facing_dot
		):
			return candidate
	return ball_offset


func _burst_dribble_is_useful() -> bool:
	var gap_close_target = _get_burst_gap_close_target()
	if not gap_close_target.is_zero_approx():
		_burst_gap_close_target = gap_close_target
		_burst_gap_close_until = _server_time_seconds() + 0.42
		return true

	var ball_distance = controlled_player.global_position.distance_to(
		ball.global_position
	)
	if (
		not _is_primary_ball_chaser()
		or _ball_is_in_own_goal_danger()
		or ball_distance >= 610.0
		or ball.linear_velocity.length()
		> maxf(100.0, burst_dribble_maximum_ball_speed)
	):
		return false
	var opponent = _get_nearest_opponent_to(controlled_player.global_position)
	if opponent == null:
		return false
	var opponent_distance = controlled_player.global_position.distance_to(
		opponent.global_position
	)
	if opponent_distance < 230.0 or opponent_distance > 1050.0:
		return false
	var dash_direction = ball.global_position.direction_to(_shot_target)
	if dash_direction.is_zero_approx():
		dash_direction = Vector2(_get_attack_sign(), 0.0)
	var destination = _clamp_to_field(
		controlled_player.global_position + dash_direction * 560.0
	)
	var current_space = _nearest_opponent_distance(
		controlled_player.global_position
	)
	var destination_space = _nearest_opponent_distance(destination)
	var defender_blocks_route = (
		_distance_to_segment(
			opponent.global_position,
			ball.global_position,
			destination
		) < 310.0
	)
	return (
		_server_time_seconds() < _dribble_until
		or defender_blocks_route
		or destination_space > current_space + 80.0
		or opponent.global_position.distance_to(ball.global_position) < 520.0
	)


func _get_burst_gap_close_target() -> Vector2:
	if not is_instance_valid(controlled_player) or not is_instance_valid(ball):
		return Vector2.ZERO

	var receive_intention = match_manager.get_cpu_pass_intention(
		controlled_player.owner_peer_id
	)
	if receive_intention.is_empty():
		receive_intention = _get_detected_pass_reception()
	if not receive_intention.is_empty():
		var receive_position: Vector2 = receive_intention.get(
			"position",
			controlled_player.global_position
		)
		if _burst_gap_close_target_is_valid(receive_position, true):
			return receive_position

	if not _is_primary_ball_chaser():
		return Vector2.ZERO

	var ball_distance = controlled_player.global_position.distance_to(
		ball.global_position
	)
	if (
		ball_distance < maxf(300.0, burst_gap_close_minimum_distance)
		or ball_distance > maxf(
			burst_gap_close_minimum_distance,
			burst_gap_close_maximum_distance
		)
	):
		return Vector2.ZERO

	if _team_likely_has_possession():
		var carrier = _get_likely_team_ball_carrier()
		if (
			is_instance_valid(carrier)
			and carrier != controlled_player
			and carrier.global_position.distance_to(ball.global_position)
			<= carrier.kick_feedback_detection_distance * 1.2
		):
			return Vector2.ZERO

	var prediction_seconds = maxf(
		0.0,
		burst_gap_close_prediction_seconds
	)
	var target = (
		_predict_ball_position_for_seconds(prediction_seconds)
		if ball.linear_velocity.length() > 120.0
		else ball.global_position
	)
	return target if _burst_gap_close_target_is_valid(target) else Vector2.ZERO


func _burst_gap_close_target_is_valid(
	target: Vector2,
	allow_team_possession: bool = false
) -> bool:
	if target.is_zero_approx():
		return false
	var distance = controlled_player.global_position.distance_to(target)
	var minimum_distance = maxf(300.0, burst_gap_close_minimum_distance)
	var maximum_distance = maxf(
		minimum_distance,
		burst_gap_close_maximum_distance
	)
	if distance < minimum_distance or distance > maximum_distance:
		return false

	var direction = controlled_player.global_position.direction_to(target)
	if direction.is_zero_approx():
		return false
	var control_distance = maxf(
		150.0,
		controlled_player.kick_feedback_detection_distance * 0.68
	)
	var dash_distance = minf(
		maxf(180.0, burst_gap_close_dash_distance),
		maxf(0.0, distance - control_distance)
	)
	if dash_distance < 180.0:
		return false
	var destination = _clamp_to_field(
		controlled_player.global_position + direction * dash_distance
	)
	var distance_gain = distance - destination.distance_to(target)
	if distance_gain < maxf(120.0, burst_gap_close_minimum_gain):
		return false

	var opponent_carrier = _get_likely_opponent_ball_carrier()
	var defensive_chase = (
		not _team_likely_has_possession()
		and is_instance_valid(opponent_carrier)
		and opponent_carrier.global_position.distance_to(ball.global_position)
		<= opponent_carrier.kick_feedback_detection_distance * 1.25
	)
	var loose_ball_race = (
		_nearest_opponent_distance(target) < distance + 420.0
		or ball.linear_velocity.length() > 360.0
	)
	return (
		allow_team_possession
		or defensive_chase
		or loose_ball_race
		or _ball_is_in_own_goal_danger()
		or not _team_likely_has_possession()
	)


func _enforcer_is_useful() -> bool:
	if _ball_is_in_own_goal_danger() and not _is_primary_ball_chaser():
		return false
	var best_relevance = -INF
	for opponent in _get_opponents():
		if not is_instance_valid(opponent) or not opponent.controls_enabled:
			continue
		var player_distance = controlled_player.global_position.distance_to(
			opponent.global_position
		)
		if player_distance > 820.0:
			continue
		var ball_relevance = maxf(
			0.0,
			1050.0 - opponent.global_position.distance_to(ball.global_position)
		)
		var lane_relevance = 0.0
		if not _shot_target.is_zero_approx():
			lane_relevance = maxf(
				0.0,
				620.0 - _distance_to_segment(
					opponent.global_position,
					ball.global_position,
					_shot_target
				)
			)
		best_relevance = maxf(
			best_relevance,
			ball_relevance + lane_relevance - player_distance * 0.25
		)
	return best_relevance > 180.0


func _dead_zone_goal_shot_is_useful() -> bool:
	if (
		_plan_is_pass
		or _plan_uses_wall
		or _ball_is_in_own_goal_danger()
		or controlled_player.global_position.distance_to(ball.global_position)
		>= controlled_player.kick_feedback_detection_distance
	):
		return false
	var opponent_goal := _get_opponent_goal()
	if opponent_goal == null:
		return false
	var target := _shot_target
	if target.is_zero_approx():
		target = _planned_destination
	if target.is_zero_approx():
		return false
	# Only treat this as a Dead Zone goal shot when the current plan is actually
	# aimed into the goal mouth. A dribble/self-pass target must never qualify.
	var mouth := opponent_goal.get_mouth_y_range()
	if (
		absf(target.x - opponent_goal.get_goal_plane_x()) > 80.0
		or target.y < mouth.x + 55.0
		or target.y > mouth.y - 55.0
	):
		return false
	var goal_distance := ball.global_position.distance_to(target)
	var maximum_travel := (
		controlled_player.cpu_get_time_skip_pass_maximum_travel_distance()
	)
	if goal_distance > maximum_travel * 0.965:
		# This is the important range gate: if Dead Zone will brake before the
		# goal line, keep the ordinary charged shot instead.
		return false
	var lane := _minimum_segment_clearance(ball.global_position, target)
	var required_lane := maxf(
		85.0,
		_required_direct_shot_lane(goal_distance) * 0.68
	)
	return lane >= required_lane


func _dead_zone_pass_is_useful() -> bool:
	if (
		_plan_uses_wall
		or _ball_is_in_own_goal_danger()
		or controlled_player.global_position.distance_to(ball.global_position)
		>= controlled_player.kick_feedback_detection_distance
	):
		return false
	var maximum_receiver_distance = minf(
		maxf(300.0, controlled_player.time_skip_pass_maximum_receiver_distance),
		controlled_player.cpu_get_time_skip_pass_maximum_travel_distance()
	)
	if _plan_is_pass and is_instance_valid(_planned_receiver):
		var route_distance = ball.global_position.distance_to(_planned_destination)
		if route_distance > maximum_receiver_distance * 0.98:
			# The ability cannot physically deliver this route. Keep the normal
			# pass/shot plan instead of turning Dead Zone into a bad long shot.
			return false
		if not _is_pass_lane_safe(_shot_target):
			return false
		var receiver_distance = _planned_receiver.global_position.distance_to(
			_planned_destination
		)
		var opponent_distance = _nearest_opponent_distance(_planned_destination)
		var receiver_intention = _get_effective_player_intention(_planned_receiver)
		var receiver_action = StringName(receiver_intention.get("action", &""))
		var receiver_is_attacking_space = receiver_action in [
			INTENT_RECEIVE,
			INTENT_FORWARD_RUN,
			INTENT_WIDE_SUPPORT
		]
		return (
			_planned_receiver.global_position.distance_to(ball.global_position) > 360.0
			and opponent_distance >= dead_zone_minimum_open_space
			and (
				opponent_distance - receiver_distance >= dead_zone_receiver_advantage
				or receiver_is_attacking_space
			)
		)

	# Reachable direct goal shots are handled by _dead_zone_goal_shot_is_useful()
	# before this helper. Otherwise, team modes still require an actual receiver
	# route; the defender-splitting self-pass remains available in true 1v1.
	if _has_other_active_teammate():
		return false

	# Without a receiver in 1v1, Dead Zone is only a purposeful self-pass through
	# a defender. A clear shooting lane should stay a normal charged shot.
	var opponent_goal = _get_opponent_goal()
	if opponent_goal == null:
		return false
	var goal_target = _get_goal_center(opponent_goal)
	if ball.global_position.distance_to(goal_target) <= 1850.0:
		return false
	var nearest_opponent = _get_nearest_opponent_to(ball.global_position)
	var forward = ball.global_position.direction_to(goal_target)
	if forward.is_zero_approx():
		forward = Vector2(_get_attack_sign(), 0.0)
	var self_pass_target = _clamp_to_field(
		ball.global_position + forward * maxf(500.0, dead_zone_self_pass_probe_distance)
	)
	var defender_in_front = (
		nearest_opponent != null
		and nearest_opponent.global_position.distance_to(ball.global_position) > 240.0
		and nearest_opponent.global_position.distance_to(ball.global_position) < 1050.0
		and _distance_to_segment(
			nearest_opponent.global_position,
			ball.global_position,
			self_pass_target
		) < 380.0
	)
	if defender_in_front and _nearest_opponent_distance(self_pass_target) > 430.0:
		_planned_destination = self_pass_target
		_shot_target = self_pass_target
		_plan_is_pass = false
		_planned_receiver = null
		return true
	return false


func _prepare_trap_or_volley_reception(
	receive_intention: Dictionary,
	opponent_goal: FootballGoal
) -> bool:
	if (
		controlled_player.selected_ability
		!= FootballPlayer.ABILITY_DIRECT_FINISH
		or receive_intention.is_empty()
		or opponent_goal == null
		or (
			not _cpu_ability_is_ready()
			and not _has_active_ability(
				FootballPlayer.ABILITY_DIRECT_FINISH
			)
		)
	):
		return false
	var receive_position: Vector2 = receive_intention.get(
		"position",
		_get_predicted_ball_position()
	)
	receive_position = _clamp_to_field(receive_position)
	var goal_target = _get_shot_target(opponent_goal)
	var ability_active = _has_active_ability(
		FootballPlayer.ABILITY_DIRECT_FINISH
	)
	var trap_volley_combo = _get_trap_or_volley_combo_plan()
	var is_trap_volley_combo_receiver = (
		not trap_volley_combo.is_empty()
		and int(trap_volley_combo.get("receiver_peer_id", 0))
		== controlled_player.owner_peer_id
	)
	var volley_requested = (
		controlled_player.server_direct_finish_volley_requested
		if ability_active
		else _has_clear_dead_zone_volley_lane(
			receive_position,
			opponent_goal
		)
		if is_trap_volley_combo_receiver
		else _should_direct_finish_volley_at(
			opponent_goal,
			receive_position
		)
	)
	var reception_aim = (
		controlled_player.server_direct_finish_aim_direction
		if ability_active
		else Vector2.ZERO
	)
	if reception_aim.is_zero_approx():
		reception_aim = receive_position.direction_to(goal_target)
		if not volley_requested:
			reception_aim = _get_trap_reception_direction(
				receive_position,
				goal_target
			)
	if reception_aim.is_zero_approx():
		reception_aim = Vector2(_get_attack_sign(), 0.0)

	# A volley needs the receiver just behind the contact point. A trap meets the
	# ball directly and cushions it into the safest forward control lane.
	_movement_target = receive_position
	if volley_requested:
		_movement_target -= reception_aim * minf(
			120.0,
			maxf(60.0, strike_position_distance)
		)
	_movement_target = _clamp_to_field(_movement_target)
	_shot_target = goal_target
	_planned_destination = goal_target
	_plan_is_pass = false
	_planned_receiver = null
	_set_tactical_intent(
		INTENT_RECEIVE,
		_movement_target,
		int(receive_intention.get("passer_peer_id", 0))
	)

	var ball_speed = ball.linear_velocity.length()
	var ball_to_reception = ball.global_position.direction_to(receive_position)
	var is_incoming = (
		ball_speed >= maxf(
			controlled_player.direct_finish_trap_minimum_ball_speed,
			80.0
		)
		and not ball_to_reception.is_zero_approx()
		and ball.linear_velocity.normalized().dot(ball_to_reception) > 0.35
	)
	var arrival_seconds = (
		ball.global_position.distance_to(receive_position) / ball_speed
		if ball_speed > 0.0
		else INF
	)
	var arm_window = maxf(
		0.25,
		controlled_player.direct_finish_timing_window - 0.2
	)
	var should_arm := (
		is_trap_volley_combo_receiver
		or _has_active_ability(FootballPlayer.ABILITY_DIRECT_FINISH)
		or is_incoming and arrival_seconds <= arm_window
	)
	if should_arm:
		if ability_active:
			# Once armed, updating the trap/volley choice is part of the same active
			# ability execution rather than a new tactical activation.
			controlled_player.cpu_arm_trap_or_volley(
				volley_requested,
				reception_aim
			)
		else:
			controlled_player.server_direct_finish_volley_requested = volley_requested
			controlled_player.server_direct_finish_aim_direction = reception_aim
			controlled_player.server_direction = reception_aim
			_request_ability_action(
				FootballPlayer.ABILITY_DIRECT_FINISH,
				goal_target,
				int(receive_intention.get("passer_peer_id", 0)),
				INTENT_RECEIVE,
				FootballPlayer.ABILITY_DIRECT_FINISH,
				true,
				false
			)
	return true


func _has_clear_dead_zone_volley_lane(
	reception: Vector2,
	opponent_goal: FootballGoal
) -> bool:
	var target = _get_dead_zone_scoring_target(reception, opponent_goal)
	return (
		not target.is_zero_approx()
		and reception.distance_to(target) < 3500.0
		and _minimum_segment_clearance(reception, target)
		>= dead_zone_combo_minimum_scoring_clearance
	)


func _get_trap_reception_direction(
	receive_position: Vector2,
	goal_target: Vector2
) -> Vector2:
	var forward = receive_position.direction_to(goal_target)
	if forward.is_zero_approx():
		forward = Vector2(_get_attack_sign(), 0.0)
	var best_direction = forward
	var best_space = -INF
	for angle in [0.0, -0.55, 0.55]:
		var direction = forward.rotated(float(angle)).normalized()
		var control_point = _clamp_to_field(
			receive_position
			+ direction
			* maxf(300.0, controlled_player.direct_finish_trap_control_distance)
		)
		var space = _nearest_opponent_distance(control_point)
		if space > best_space:
			best_space = space
			best_direction = direction
	return best_direction


func _trap_or_volley_is_useful() -> bool:
	var receive_intention = match_manager.get_cpu_pass_intention(
		controlled_player.owner_peer_id
	)
	if receive_intention.is_empty():
		receive_intention = _get_detected_pass_reception()
	var prepared_reception = (
		not receive_intention.is_empty()
		and ball.linear_velocity.length() >= 180.0
		and controlled_player.global_position.distance_to(ball.global_position)
		< 1350.0
	)
	if not prepared_reception and not _incoming_ball_threat(1100.0, 210.0):
		return false
	var opponent_goal = _get_opponent_goal()
	if opponent_goal == null:
		return false
	if _should_direct_finish_volley(opponent_goal):
		return true
	# Trap an awkward or pressured reception to remove its momentum.
	return (
		prepared_reception
		or _nearest_opponent_distance(controlled_player.global_position) < 760.0
		or _ball_is_in_own_goal_danger()
		or ball.linear_velocity.length() > 1250.0
	)


func _should_direct_finish_volley(opponent_goal) -> bool:
	return _should_direct_finish_volley_at(
		opponent_goal,
		ball.global_position
	)


func _should_direct_finish_volley_at(
	opponent_goal,
	reception_position: Vector2
) -> bool:
	if opponent_goal == null or _ball_is_in_own_goal_danger():
		return false
	var goal_target = _get_goal_center(opponent_goal)
	var goal_distance = reception_position.distance_to(goal_target)
	return (
		goal_distance < 3300.0
		and _minimum_segment_clearance(reception_position, goal_target) > 170.0
		and ball.linear_velocity.dot(
			reception_position.direction_to(goal_target)
		) > -900.0
	)


func _reflex_block_is_useful() -> bool:
	if (
		not _last_ball_touch_was_opponent()
		or not _incoming_ball_threat(
			1500.0,
			maxf(250.0, reflex_block_minimum_threat_speed)
		)
	):
		return false
	var threat = _predict_own_goal_threat(2.6)
	if not threat.is_empty():
		return true
	# In midfield, spend Reflex Block only when the deflection starts a counter
	# or prevents an opponent from collecting the fast ball uncontested.
	var opponent_goal = _get_opponent_goal()
	var facing = _get_reflex_block_facing()
	var counter_target = controlled_player.global_position + facing * 1000.0
	return (
		opponent_goal != null
		and facing.dot(Vector2(_get_attack_sign(), 0.0)) > 0.2
		and _nearest_opponent_distance(counter_target) > 420.0
	)


func _iron_anchor_is_useful() -> bool:
	var ball_distance = controlled_player.global_position.distance_to(
		ball.global_position
	)
	if ball_distance >= controlled_player.iron_anchor_trap_radius:
		return false
	var speed = ball.linear_velocity.length()
	if not _predict_own_goal_threat(2.8).is_empty():
		return speed > 260.0
	var opponent_pressure = _nearest_opponent_distance(ball.global_position)
	var teammate_pass = (
		not _last_ball_touch_was_opponent()
		and ball.last_touch_peer_id != 0
	)
	if teammate_pass and opponent_pressure > iron_anchor_control_pressure_radius:
		return false
	return (
		speed > 760.0
		and opponent_pressure < iron_anchor_control_pressure_radius
		and _is_primary_ball_chaser()
	)


func _shot_ability_is_useful(ability_id: int) -> bool:
	if _plan_is_pass:
		return false
	var opponent_goal = _get_opponent_goal()
	if opponent_goal == null:
		return false
	var ball_distance = controlled_player.global_position.distance_to(
		ball.global_position
	)
	var goal_distance = ball.global_position.distance_to(
		_get_goal_center(opponent_goal)
	)
	var maximum_ability_shot_distance = committed_shot_goal_distance
	if ability_id == FootballPlayer.ABILITY_POWER_STRIKE:
		maximum_ability_shot_distance = maxf(
			committed_shot_goal_distance,
			power_strike_activation_goal_distance
		)
	if (
		ball_distance >= controlled_player.kick_feedback_detection_distance
		or goal_distance > maximum_ability_shot_distance
	):
		return false
	if ability_id == FootballPlayer.ABILITY_POWER_STRIKE:
		if match_manager != null and match_manager.cpu_training_mode:
			return (
				not _ball_is_in_own_goal_danger()
				and goal_distance >= 700.0
				and _minimum_pass_lane_clearance(_shot_target) >= 75.0
			)
		if _is_true_one_vs_one():
			var direct_lane = _minimum_segment_clearance(
				ball.global_position,
				_get_goal_center(opponent_goal)
			)
			return (
				not _one_vs_one_power_opening_is_needed(opponent_goal)
				and direct_lane >= maxf(100.0, one_vs_one_power_opening_lane)
				and not _one_vs_one_requires_emergency_defense()
			)
		return _power_strike_risk_is_acceptable(goal_distance)
	if ability_id == FootballPlayer.ABILITY_QUICK_TRIGGER:
		var shot_clearance = _minimum_pass_lane_clearance(_shot_target)
		return (
			goal_distance >= curve_shot_minimum_goal_distance
			and goal_distance <= curve_shot_maximum_goal_distance
			and shot_clearance >= 110.0
			and (
				shot_clearance < 620.0
				or goal_distance > 1900.0
			)
		)
	return true


func _is_power_strike_distribution_plan() -> bool:
	if (
		controlled_player.selected_ability
		!= FootballPlayer.ABILITY_POWER_STRIKE
		or not _plan_is_pass
		or not is_instance_valid(_planned_receiver)
	):
		return false
	var route_distance = (
		_planned_route_distance
		if _planned_route_distance > 0.0
		else ball.global_position.distance_to(_planned_destination)
	)
	var forward_progress = (
		_planned_destination.x - ball.global_position.x
	) * _get_attack_sign()
	var distance_ratio: float = 0.72
	var progress_ratio: float = 0.55
	if _get_active_team_player_count() >= 3:
		distance_ratio = 0.52
		progress_ratio = 0.32
	return (
		route_distance
		>= maxf(
			defensive_power_pass_minimum_distance * distance_ratio,
			power_strike_distribution_minimum_distance * distance_ratio
		)
		and forward_progress
		>= maxf(
			defensive_power_pass_minimum_progress * progress_ratio,
			power_strike_distribution_minimum_progress * progress_ratio
		)
	)


func _get_copycat_source_ability(now: float) -> int:
	if controlled_player == null:
		return FootballPlayer.ABILITY_NONE
	return controlled_player.get_copycat_source_ability(now)


func _copycat_is_useful(now: float) -> bool:
	var copied_ability = _get_copycat_source_ability(now)
	match copied_ability:
		FootballPlayer.ABILITY_BURST_DRIBBLE:
			return _burst_dribble_is_useful()
		FootballPlayer.ABILITY_QUICK_TRIGGER, FootballPlayer.ABILITY_POWER_STRIKE:
			return _shot_ability_is_useful(copied_ability)
		FootballPlayer.ABILITY_OVERDRIVE:
			return _overdrive_is_useful()
		FootballPlayer.ABILITY_HEEL_TURN:
			return _heel_turn_is_useful()
		FootballPlayer.ABILITY_ENFORCER:
			return _enforcer_is_useful()
		FootballPlayer.ABILITY_TIME_SKIP_PASS:
			return _dead_zone_pass_is_useful()
		FootballPlayer.ABILITY_DIRECT_FINISH:
			return _trap_or_volley_is_useful()
		FootballPlayer.ABILITY_ELASTIC_STEP:
			return _elastic_step_is_useful()
		FootballPlayer.ABILITY_META_VISION:
			return _meta_vision_is_useful()
		FootballPlayer.ABILITY_REFLEX_BLOCK:
			return _reflex_block_is_useful()
		FootballPlayer.ABILITY_IRON_ANCHOR:
			return _iron_anchor_is_useful()
		FootballPlayer.ABILITY_BLIND_SPOT:
			return _mirage_step_is_useful()
		FootballPlayer.ABILITY_BOOGIE_WOOGIE:
			return _boogie_woogie_is_useful()
		FootballPlayer.ABILITY_ECHO:
			return _echo_is_useful()
		FootballPlayer.ABILITY_RETURN_TAG:
			return _return_tag_is_useful()
		FootballPlayer.ABILITY_BREAKAWAY:
			return _breakaway_is_useful()
		FootballPlayer.ABILITY_SNAPBACK:
			return _snapback_is_useful()
		FootballPlayer.ABILITY_SIDE_SWIPE:
			return _side_swipe_is_useful()
		FootballPlayer.ABILITY_NUTMEG:
			return _nutmeg_is_useful()
		FootballPlayer.ABILITY_DECOY_RUN:
			return _decoy_run_is_useful()
	return false


func _try_execute_return_tag_return() -> bool:
	if (
		ball == null
		or not controlled_player.cpu_has_kickable_ball()
		or controlled_player.server_is_charging
		or not ball.can_return_tag_for(
			controlled_player.owner_peer_id,
			controlled_player.team
		)
	):
		return false
	var owner := _get_teammate_by_peer_id(
		ball.get_return_tag_owner_peer_id()
	)
	if owner == null or not owner.controls_enabled:
		return false
	var target: Vector2 = controlled_player.cpu_get_return_tag_target(ball)
	if target.is_zero_approx():
		return false
	var distance := ball.global_position.distance_to(target)
	if distance < 220.0 or distance > maximum_pass_distance * 1.15:
		return false
	if _minimum_segment_clearance(ball.global_position, target) < 115.0:
		return false
	if _ball_is_in_own_goal_danger():
		var own_goal := _get_own_goal()
		if own_goal != null:
			var current_safety := ball.global_position.distance_to(
				_get_goal_center(own_goal)
			)
			var target_safety := target.distance_to(_get_goal_center(own_goal))
			if target_safety < current_safety + 120.0:
				return false
	controlled_player.server_direction = ball.global_position.direction_to(target)
	if not controlled_player.cpu_try_return_tag_pass():
		return false
	_movement_target = target
	_set_tactical_intent(
		INTENT_PASS,
		target,
		owner.owner_peer_id
	)
	_plan_expires_at = 0.0
	_reset_cpu_charge_tracking()
	return true


func _breakaway_is_useful() -> bool:
	if (
		_ball_is_in_own_goal_danger()
		or not controlled_player.cpu_has_kickable_ball()
		or not _team_likely_has_possession()
	):
		return false
	# A clean immediate finish is better than knocking the ball away from a
	# scoring chance. Breakaway is for beating the player in front of us.
	if _has_improvised_shot_opportunity():
		return false
	var opponent: FootballPlayer = _get_nearest_opponent_to(
		controlled_player.global_position
	)
	if opponent == null:
		return false
	var pressure: float = controlled_player.global_position.distance_to(
		opponent.global_position
	)
	if pressure < 180.0 or pressure > 1250.0:
		return false
	var attack_sign: float = _get_attack_sign()
	var forward_delta: float = (
		opponent.global_position.x - controlled_player.global_position.x
	) * attack_sign
	if forward_delta < 35.0 or forward_delta > 1450.0:
		return false
	var opponent_goal: FootballGoal = _get_opponent_goal()
	if opponent_goal == null:
		return false
	var goal_distance: float = ball.global_position.distance_to(
		_get_goal_center(opponent_goal)
	)
	if goal_distance <= 820.0:
		return false
	# Make sure there is actually room beyond the defender. The player-side
	# Breakaway implementation performs a more exact left/right lane probe.
	var chase_point: Vector2 = controlled_player.global_position + Vector2(
		attack_sign * minf(1050.0, maxf(620.0, forward_delta + 360.0)),
		0.0
	)
	return _nearest_opponent_distance(chase_point) >= 210.0


func _breakaway_trigger_is_useful() -> bool:
	if not _breakaway_is_useful():
		return false
	var opponent: FootballPlayer = _get_nearest_opponent_to(
		controlled_player.global_position
	)
	if opponent == null:
		return false
	var attack_sign: float = _get_attack_sign()
	var forward_delta: float = (
		opponent.global_position.x - controlled_player.global_position.x
	) * attack_sign
	# Do not instantly consume the armed fake at maximum distance. Commit when
	# the defender is close enough that the self-pass can genuinely beat them.
	return forward_delta >= 30.0 and forward_delta <= 980.0


func _side_swipe_is_useful() -> bool:
	if (
		_ball_is_in_own_goal_danger()
		or not controlled_player.cpu_has_kickable_ball()
		or not _team_likely_has_possession()
	):
		return false
	var pressure: float = _nearest_opponent_distance(ball.global_position)
	var lateral_space: float = _get_side_swipe_lateral_space_score()
	if _plan_is_pass:
		return (
		pressure < 1600.0
			and not _plan_uses_wall
			and lateral_space >= 240.0
		)
	var opponent_goal: FootballGoal = _get_opponent_goal()
	if opponent_goal == null:
		return false
	var goal_distance: float = ball.global_position.distance_to(
		_get_goal_center(opponent_goal)
	)
	# As a shot, Side Swipe is valuable when the direct approach is crowded
	# but a lateral angle exists. As a dribble escape, it can be used farther
	# out when pressure is close.
	return (
		(lateral_space >= 260.0 and pressure <= 1150.0)
		and (
			goal_distance <= committed_shot_goal_distance * 1.15
			or pressure <= 820.0
		)
	)


func _nutmeg_is_useful() -> bool:
	if (
		_ball_is_in_own_goal_danger()
		or not controlled_player.cpu_has_kickable_ball()
		or not _team_likely_has_possession()
	):
		return false
	var opponent: FootballPlayer = _get_nearest_opponent_to(ball.global_position)
	if opponent == null:
		return false
	var attack_direction := Vector2(_get_attack_sign(), 0.0)
	if not _planned_destination.is_zero_approx():
		attack_direction = ball.global_position.direction_to(_planned_destination)
	var offset: Vector2 = opponent.global_position - ball.global_position
	var forward: float = offset.dot(attack_direction.normalized())
	var lateral: float = absf(offset.cross(attack_direction.normalized()))
	return (
		forward > 20.0
		and forward <= controlled_player.nutmeg_probe_distance
		and lateral <= controlled_player.nutmeg_lane_half_width
	)


func _decoy_run_is_useful() -> bool:
	if _ball_is_in_own_goal_danger():
		return false
	var pressure: float = _nearest_opponent_distance(
		controlled_player.global_position
	)
	return (
		pressure <= 720.0
		and controlled_player.linear_velocity.length() >= 180.0
		and (
			controlled_player.cpu_has_kickable_ball()
			or _team_likely_has_possession()
		)
	)


func _side_swipe_escape_touch_is_useful() -> bool:
	if _plan_is_pass:
		return true
	if controlled_player.server_is_charging:
		# Let the charged shot release through the normal Side Swipe shot path.
		return false
	var pressure: float = _nearest_opponent_distance(ball.global_position)
	return pressure <= 850.0 and _get_side_swipe_lateral_space_score() >= 250.0


func _get_side_swipe_lateral_space_score() -> float:
	var probe_distance: float = 720.0
	var upper_target: Vector2 = _clamp_to_field(
		ball.global_position + Vector2(0.0, -probe_distance)
	)
	var lower_target: Vector2 = _clamp_to_field(
		ball.global_position + Vector2(0.0, probe_distance)
	)
	return maxf(
		_nearest_opponent_distance(upper_target),
		_nearest_opponent_distance(lower_target)
	)


func _snapback_is_useful() -> bool:
	if (
		_ball_is_in_own_goal_danger()
		or not controlled_player.cpu_has_kickable_ball()
		or not _team_likely_has_possession()
	):
		return false
	# Do not turn away a genuinely clean finish. Otherwise use Snapback as a
	# bait-and-recover tool when a defender can reasonably commit to the kick.
	if _has_improvised_shot_opportunity() and not _plan_is_pass:
		return false
	var pressure: float = _nearest_opponent_distance(
		controlled_player.global_position
	)
	var opponent: FootballPlayer = _get_nearest_opponent_to(
		controlled_player.global_position
	)
	if opponent == null:
		return false
	var forward_delta: float = (
		opponent.global_position.x - controlled_player.global_position.x
	) * _get_attack_sign()
	var defender_can_commit: bool = forward_delta > -120.0 and forward_delta < 1250.0
	return defender_can_commit and pressure >= 170.0 and pressure <= 1200.0


func _snapback_recall_is_useful() -> bool:
	if not controlled_player.cpu_has_snapback_recall():
		return false
	var age: float = controlled_player.cpu_get_snapback_kick_age()
	if age < 0.12:
		return false
	var predicted_player_position: Vector2 = (
		controlled_player.global_position
		+ controlled_player.linear_velocity * 0.16
	)
	var ball_distance: float = ball.global_position.distance_to(
		predicted_player_position
	)
	var pressure_to_ball: float = _nearest_opponent_distance(ball.global_position)
	var ball_to_player: Vector2 = ball.global_position.direction_to(
		predicted_player_position
	)
	var ball_moving_away: bool = (
		not ball.linear_velocity.is_zero_approx()
		and ball.linear_velocity.normalized().dot(ball_to_player) < -0.10
	)
	# Recall early when the bait has pulled the ball away or an opponent is
	# threatening it. Otherwise wait a little to make the fake convincing, but
	# never sit on the longer mark until it expires.
	return (
		(pressure_to_ball <= 980.0 and age >= 0.18)
		or (ball_moving_away and ball_distance >= 360.0 and age >= 0.20)
		or age >= 0.62
	)


func _return_tag_is_useful() -> bool:
	if (
		not _plan_is_pass
		or not is_instance_valid(_planned_receiver)
		or _planned_receiver.team != controlled_player.team
		or not _planned_receiver.controls_enabled
		or not controlled_player.cpu_has_kickable_ball()
		or _ball_is_in_own_goal_danger()
		or _plan_uses_wall
	):
		return false
	var pass_distance: float = ball.global_position.distance_to(_shot_target)
	if pass_distance < 280.0 or pass_distance > maximum_pass_distance * 1.08:
		return false
	var first_lane_clearance: float = _minimum_segment_clearance(
		ball.global_position,
		_shot_target
	)
	if first_lane_clearance < 80.0:
		return false
	var owner_return_target: Vector2 = (
		controlled_player.global_position
		+ Vector2(_get_attack_sign(), 0.0) * 500.0
		+ controlled_player.linear_velocity * 0.22
	)
	var receiver_target: Vector2 = (
		_planned_receiver.global_position
		+ _planned_receiver.linear_velocity * 0.24
	)
	var return_lane: float = _minimum_segment_clearance(
		receiver_target,
		owner_return_target
	)
	var owner_space: float = _nearest_opponent_distance(owner_return_target)
	var receiver_space: float = _nearest_opponent_distance(receiver_target)
	return (
		return_lane >= 85.0
		and owner_space >= 210.0
		and receiver_space >= 145.0
	)


func _echo_is_useful() -> bool:
	var own_goal: FootballGoal = _get_own_goal()
	if own_goal == null:
		return false
	var own_goal_center: Vector2 = _get_goal_center(own_goal)
	var player_goal_distance: float = controlled_player.global_position.distance_to(
		own_goal_center
	)
	if player_goal_distance > 2700.0:
		return false

	# A real incoming shot takes priority even if our last touch technically
	# makes the possession heuristic say the team still owns the ball. Echo now
	# fully blocks any ball type, so use it as an actual emergency shot blocker.
	var threat: Dictionary = _predict_own_goal_threat(2.5)
	if not threat.is_empty():
		var intercept_point: Vector2 = threat.get(
			"intercept_position",
			ball.global_position
		)
		return (
			controlled_player.global_position.distance_to(intercept_point) <= 1120.0
			and controlled_player.global_position.distance_to(ball.global_position) <= 1750.0
		)

	var ball_speed: float = ball.linear_velocity.length()
	if ball_speed >= 650.0:
		var to_goal: Vector2 = ball.global_position.direction_to(own_goal_center)
		var velocity_direction: Vector2 = ball.linear_velocity.normalized()
		var moving_toward_goal: bool = velocity_direction.dot(to_goal) >= 0.55
		var goal_segment: Vector2 = own_goal_center - ball.global_position
		var goal_segment_length_sq: float = maxf(1.0, goal_segment.length_squared())
		var player_relative: Vector2 = (
			controlled_player.global_position - ball.global_position
		)
		var lane_progress: float = clampf(
			player_relative.dot(goal_segment) / goal_segment_length_sq,
			0.0,
			1.0
		)
		var closest_lane_point: Vector2 = (
			ball.global_position + goal_segment * lane_progress
		)
		var player_lane_distance: float = controlled_player.global_position.distance_to(
			closest_lane_point
		)
		var player_on_lane: bool = (
			lane_progress >= 0.04
			and lane_progress <= 0.94
			and player_lane_distance <= 620.0
		)
		if moving_toward_goal and player_on_lane:
			return true

	if _team_likely_has_possession():
		return false
	var carrier: FootballPlayer = _get_likely_opponent_ball_carrier()
	if carrier == null:
		return false
	var carrier_distance: float = controlled_player.global_position.distance_to(
		carrier.global_position
	)
	var between_ball_and_goal: bool = (
		ball.global_position.direction_to(own_goal_center).dot(
			ball.global_position.direction_to(controlled_player.global_position)
		) > 0.38
	)
	return carrier_distance <= 1050.0 and between_ball_and_goal


func _meta_vision_is_useful() -> bool:
	if _plan_uses_wall:
		return true
	var speed = ball.linear_velocity.length()
	var ball_distance = controlled_player.global_position.distance_to(
		ball.global_position
	)
	var nearby_pressure = _nearest_opponent_distance(ball.global_position)
	var own_goal = _get_own_goal()
	var defensive_emergency = (
		own_goal != null
		and speed > 950.0
		and ball.global_position.distance_to(_get_goal_center(own_goal))
		< 2200.0
	)
	if defensive_emergency:
		return true
	if (
		speed > 1550.0
		and ball_distance < 1450.0
		and nearby_pressure < 900.0
	):
		return true
	if not _is_primary_ball_chaser() or ball_distance > 950.0:
		return false
	var opponent_goal = _get_opponent_goal()
	if opponent_goal == null:
		return false
	var goal_target = _get_goal_center(opponent_goal)
	return (
		nearby_pressure < 720.0
		and _minimum_segment_clearance(
			ball.global_position,
			goal_target
		) < 520.0
	)


func _cpu_ability_is_ready() -> bool:
	return (
		not controlled_player.server_ability_active
		and not controlled_player.server_ability_timers_paused
		and _server_time_seconds()
		>= controlled_player.server_ability_cooldown_ends_at
	)


func _player_ability_is_available(
	player: FootballPlayer,
	ability_id: int
) -> bool:
	if (
		not is_instance_valid(player)
		or not player.controls_enabled
		or ability_id == FootballPlayer.ABILITY_NONE
	):
		return false
	if player.server_ability_active:
		return player.server_active_ability_id == ability_id
	if player.selected_ability != ability_id:
		return false
	return (
		not player.server_ability_timers_paused
		and _server_time_seconds()
		>= player.server_ability_cooldown_ends_at
	)


func _get_player_ability_threat(player: FootballPlayer) -> float:
	if not is_instance_valid(player):
		return 0.0
	var ability_id = (
		player.server_active_ability_id
		if player.server_ability_active
		else player.selected_ability
	)
	if not _player_ability_is_available(player, ability_id):
		return 0.0
	var base_threat = 0.0
	match ability_id:
		FootballPlayer.ABILITY_POWER_STRIKE:
			base_threat = 820.0
		FootballPlayer.ABILITY_DIRECT_FINISH:
			base_threat = 620.0
		FootballPlayer.ABILITY_QUICK_TRIGGER:
			base_threat = 560.0
		FootballPlayer.ABILITY_TIME_SKIP_PASS:
			base_threat = 500.0
		FootballPlayer.ABILITY_META_VISION:
			base_threat = 520.0
		FootballPlayer.ABILITY_OVERDRIVE:
			base_threat = 470.0
		FootballPlayer.ABILITY_BURST_DRIBBLE, FootballPlayer.ABILITY_ELASTIC_STEP, FootballPlayer.ABILITY_BLIND_SPOT:
			base_threat = 440.0
		FootballPlayer.ABILITY_BOOGIE_WOOGIE:
			base_threat = 460.0
		FootballPlayer.ABILITY_RETURN_TAG:
			base_threat = 520.0
		FootballPlayer.ABILITY_BREAKAWAY:
			base_threat = 500.0
		FootballPlayer.ABILITY_SNAPBACK:
			base_threat = 540.0
		FootballPlayer.ABILITY_SIDE_SWIPE:
			base_threat = 470.0
		FootballPlayer.ABILITY_NUTMEG:
			base_threat = 510.0
		FootballPlayer.ABILITY_DECOY_RUN:
			base_threat = 390.0
		FootballPlayer.ABILITY_ECHO:
			base_threat = 320.0
		FootballPlayer.ABILITY_ENFORCER:
			base_threat = 380.0
		FootballPlayer.ABILITY_GOALKEEPER_REACH, FootballPlayer.ABILITY_REFLEX_BLOCK, FootballPlayer.ABILITY_IRON_ANCHOR:
			base_threat = 260.0
		_:
			base_threat = 180.0
	if (
		player.server_ability_active
		and player.server_active_ability_id == ability_id
	):
		return base_threat * 1.25
	return base_threat * clampf(
		ability_ready_threat_multiplier,
		0.0,
		1.0
	)


func _get_ability_aware_marking_distance(
	opponent: FootballPlayer
) -> float:
	var distance = maxf(120.0, marking_distance)
	if not is_instance_valid(opponent):
		return distance
	var ability_id = opponent.selected_ability
	if not _player_ability_is_available(opponent, ability_id):
		return distance
	match ability_id:
		FootballPlayer.ABILITY_DIRECT_FINISH:
			# Deny the receiving window before Trap or Volley can trigger.
			return maxf(190.0, distance * 0.58)
		FootballPlayer.ABILITY_POWER_STRIKE:
			return distance + 210.0
		FootballPlayer.ABILITY_QUICK_TRIGGER:
			# Pressure before the curve is launched; do not be its only obstacle.
			return distance + 140.0
		FootballPlayer.ABILITY_OVERDRIVE:
			return distance + 120.0
		FootballPlayer.ABILITY_HEEL_TURN:
			return distance + 90.0
		FootballPlayer.ABILITY_BURST_DRIBBLE, FootballPlayer.ABILITY_ELASTIC_STEP, FootballPlayer.ABILITY_BLIND_SPOT:
			return distance + 180.0
		FootballPlayer.ABILITY_ENFORCER:
			if opponent.server_ability_active:
				return distance + 260.0
		FootballPlayer.ABILITY_TIME_SKIP_PASS:
			return distance + 100.0
		FootballPlayer.ABILITY_META_VISION:
			return distance + 110.0
		FootballPlayer.ABILITY_BOOGIE_WOOGIE:
			return distance + 150.0
		FootballPlayer.ABILITY_RETURN_TAG:
			return distance + 130.0
		FootballPlayer.ABILITY_BREAKAWAY:
			# Give the attacker room rather than stepping directly into the self-pass.
			return distance + 210.0
		FootballPlayer.ABILITY_SNAPBACK:
			# Do not overcommit into the recall bait.
			return distance + 180.0
		FootballPlayer.ABILITY_SIDE_SWIPE:
			return distance + 120.0
		FootballPlayer.ABILITY_NUTMEG:
			# Defend slightly side-on so the ball route is not directly through us.
			return distance + 170.0
		FootballPlayer.ABILITY_DECOY_RUN:
			# Keep enough reaction room to read the real body after the visual fake.
			return distance + 110.0
	return distance


func _get_ability_interception_bonus(opponent: FootballPlayer) -> float:
	if not is_instance_valid(opponent):
		return 0.0
	var ability_id = opponent.selected_ability
	if not _player_ability_is_available(opponent, ability_id):
		return 0.0
	var multiplier = 0.0
	match ability_id:
		FootballPlayer.ABILITY_META_VISION:
			multiplier = 1.3
		FootballPlayer.ABILITY_GOALKEEPER_REACH:
			multiplier = 1.55
		FootballPlayer.ABILITY_OVERDRIVE:
			multiplier = 1.15
		FootballPlayer.ABILITY_BURST_DRIBBLE, FootballPlayer.ABILITY_ELASTIC_STEP:
			multiplier = 0.7
		FootballPlayer.ABILITY_BOOGIE_WOOGIE:
			multiplier = 0.9
	if opponent.server_ability_active:
		multiplier *= 1.2
	return maxf(0.0, ability_interception_reach_bonus) * multiplier


func _get_receiver_ability_bonus(
	receiver: FootballPlayer,
	target: Vector2,
	goal_distance: float
) -> float:
	if not is_instance_valid(receiver):
		return 0.0
	var ability_id = receiver.selected_ability
	if not _player_ability_is_available(receiver, ability_id):
		return 0.0
	var target_space = minf(_nearest_opponent_distance(target), 1000.0)
	var forward_progress = (target.x - ball.global_position.x) * _get_attack_sign()
	var opponent_goal = _get_opponent_goal()
	var target_goal_distance = (
		target.distance_to(_get_goal_center(opponent_goal))
		if opponent_goal != null
		else goal_distance
	)

	match ability_id:
		FootballPlayer.ABILITY_DIRECT_FINISH:
			return 560.0 if target_goal_distance < 3600.0 else 190.0
		FootballPlayer.ABILITY_POWER_STRIKE:
			if (
				_team_has_selected_ability(FootballPlayer.ABILITY_DIRECT_FINISH)
				and _get_team_strategy() == CPU_STRATEGY_ABILITY_COMBO
				and forward_progress < -260.0
			):
				return 760.0
			if target_goal_distance <= 4300.0 and target_space >= 360.0:
				return 330.0 + minf(120.0, target_space * 0.12)
			return 80.0
		FootballPlayer.ABILITY_QUICK_TRIGGER:
			# Curve Shot wants the ball in an attacking shooting pocket, not on
			# the deepest safety line.
			if target_goal_distance >= 850.0 and target_goal_distance <= 3900.0:
				return 300.0 + minf(90.0, target_space * 0.09)
			return 60.0
		FootballPlayer.ABILITY_TIME_SKIP_PASS:
			# Dead Zone Pass is a creator tool. Prefer open central/half-space
			# receptions from which another teammate can be released.
			if forward_progress >= -260.0 and target_space >= 340.0:
				return 250.0 + minf(80.0, target_space * 0.08)
			return 105.0
		FootballPlayer.ABILITY_META_VISION:
			return 190.0 if forward_progress >= -320.0 else 110.0
		FootballPlayer.ABILITY_RETURN_TAG:
			return 245.0 if target_space > 420.0 else 100.0
		FootballPlayer.ABILITY_SIDE_SWIPE:
			return 225.0 if target_space > 360.0 else 80.0
		FootballPlayer.ABILITY_OVERDRIVE:
			return 190.0 + target_space * 0.17 if forward_progress > 180.0 else 95.0
		FootballPlayer.ABILITY_BURST_DRIBBLE, FootballPlayer.ABILITY_ELASTIC_STEP, FootballPlayer.ABILITY_BLIND_SPOT, FootballPlayer.ABILITY_BREAKAWAY, FootballPlayer.ABILITY_SNAPBACK, FootballPlayer.ABILITY_NUTMEG:
			return 135.0 + target_space * 0.13 if forward_progress >= 0.0 else 65.0
		FootballPlayer.ABILITY_HEEL_TURN:
			return 150.0 if target_space > 330.0 else 20.0
		FootballPlayer.ABILITY_BOOGIE_WOOGIE:
			return 115.0 if target_space > 500.0 else -80.0
		FootballPlayer.ABILITY_COPYCAT:
			return 120.0 if target_space > 380.0 else 45.0
		FootballPlayer.ABILITY_DECOY_RUN:
			return 130.0 if forward_progress > 220.0 else 55.0
		FootballPlayer.ABILITY_REFLEX_BLOCK, FootballPlayer.ABILITY_IRON_ANCHOR, FootballPlayer.ABILITY_ECHO, FootballPlayer.ABILITY_GOALKEEPER_REACH:
			# Defensive abilities are valuable as a recycle/safety outlet, not as
			# the player the team should force into the final attacking line.
			if forward_progress <= -180.0:
				return 190.0
			if forward_progress >= 500.0:
				return -150.0
			return 35.0
		FootballPlayer.ABILITY_ENFORCER:
			return 80.0 if forward_progress < 420.0 else 10.0
	return 0.0


func _get_likely_opponent_ball_carrier() -> FootballPlayer:
	var best_player: FootballPlayer
	var best_score = INF
	for opponent in _get_opponents():
		if not is_instance_valid(opponent) or not opponent.controls_enabled:
			continue
		var score = opponent.global_position.distance_to(ball.global_position)
		if opponent.owner_peer_id == ball.last_touch_peer_id:
			score -= 280.0
		if score < best_score:
			best_score = score
			best_player = opponent
	return best_player


func _power_strike_risk_is_acceptable(goal_distance: float) -> bool:
	if _ball_is_in_own_goal_danger() or goal_distance < 820.0:
		return false
	var lane_clearance = _minimum_pass_lane_clearance(_shot_target)
	var has_cover = _team_has_counter_cover()
	var solo_attacker = not _has_other_active_teammate()
	if _plan_uses_wall:
		return (
			has_cover
			or solo_attacker
			or goal_distance < power_strike_cover_required_distance
		)
	var opponent_goal: FootballGoal = _get_opponent_goal()
	var goal_center: Vector2 = (
		_get_goal_center(opponent_goal)
		if opponent_goal != null
		else Vector2.ZERO
	)
	var second_ball_value: float = _get_best_team_second_ball_value(goal_center)
	var normal_power_lane: float = maxf(80.0, power_strike_minimum_safe_lane)
	if lane_clearance < normal_power_lane:
		if (
			second_ball_value < 0.62
			or lane_clearance < maxf(82.0, normal_power_lane * 0.52)
		):
			return false
	# Skilled attackers should actually exploit Power Strike when they have a
	# playable lane. Requiring perfect counter-cover made them carry the ready
	# ability through most matches without ever firing it.
	if (
		_get_ai_skill() >= 0.62
		and _is_primary_ball_chaser()
		and (
			has_cover
			or solo_attacker
			or second_ball_value >= 0.62
			or goal_distance <= power_strike_cover_required_distance + 850.0
		)
	):
		return true
	var opponent_team := TEAM_RED if controlled_player.team == TEAM_BLUE else TEAM_BLUE
	var opponent_race: float = (
		match_manager.get_cpu_shared_nearest_ball_distance(opponent_team)
		if match_manager.has_method("get_cpu_shared_nearest_ball_distance")
		else _nearest_team_distance_to_ball(_get_opponents())
	)
	var teammate_race = _nearest_other_teammate_distance(
		ball.global_position
	)
	if (
		goal_distance > power_strike_cover_required_distance
		and (
			(not has_cover and not solo_attacker)
			or (
				not solo_attacker
				and opponent_race + 140.0 < teammate_race
			)
		)
	):
		return false
	return true


func _team_has_counter_cover() -> bool:
	var attack_sign = _get_attack_sign()
	for teammate in _get_teammates():
		if (
			not is_instance_valid(teammate)
			or teammate == controlled_player
			or not teammate.controls_enabled
		):
			continue
		var relative_progress = (
			teammate.global_position.x - ball.global_position.x
		) * attack_sign
		if (
			relative_progress < -180.0
			and teammate.global_position.distance_to(ball.global_position)
			<= maxf(600.0, power_strike_cover_distance)
		):
			return true
	return false


func _has_other_active_teammate() -> bool:
	for teammate in _get_teammates():
		if (
			is_instance_valid(teammate)
			and teammate != controlled_player
			and teammate.controls_enabled
		):
			return true
	return false


func _get_opponent_ability_threat_state() -> Dictionary:
	if not opponent_ability_awareness_enabled:
		return {}
	var now = _server_time_seconds()
	if (
		now <= _opponent_ability_threat_cache_until
		and not _opponent_ability_threat_cache.is_empty()
	):
		return _opponent_ability_threat_cache
	var own_goal = _get_own_goal()
	var own_goal_position = (
		_get_goal_center(own_goal)
		if own_goal != null
		else ball.global_position
	)
	_opponent_ability_threat_cache = (
		AbilityThreatModelScript.analyze_team(
			_get_opponents(),
			ball.global_position,
			own_goal_position,
			maxf(1.0, maximum_field_x - minimum_field_x),
			now,
			ball.linear_velocity
		)
	)
	_opponent_ability_threat_cache_until = (
		now + maxf(0.02, ability_threat_cache_seconds)
	)
	return _opponent_ability_threat_cache


func _get_shared_ability_team_assignment() -> Dictionary:
	if (
		not shared_ability_team_plan_enabled
		or match_manager == null
		or not match_manager.has_method(
			"get_cpu_ability_team_assignment"
		)
	):
		return {}
	var assignment = match_manager.get_cpu_ability_team_assignment(
		controlled_player.team,
		controlled_player.owner_peer_id
	) as Dictionary
	if assignment.is_empty():
		return {}
	var target: Vector2 = assignment.get(
		"target_position",
		Vector2.ZERO
	)
	if target.is_zero_approx():
		return {}
	return assignment


func _update_ability_aware_defense() -> bool:
	if (
		not opponent_ability_awareness_enabled
		or _team_likely_has_possession()
	):
		return false
	var threat = _get_opponent_ability_threat_state()
	var threat_score = float(threat.get("primary_score", 0.0))
	var goal_threat = float(threat.get("goal_threat", 0.0))
	var counter_threat = float(threat.get("counter_threat", 0.0))
	if maxf(threat_score, maxf(goal_threat, counter_threat)) < (
		ability_defense_minimum_threat
	):
		return false
	var assignment = _get_shared_ability_team_assignment()
	if assignment.is_empty():
		return false
	var target: Vector2 = assignment.get(
		"target_position",
		Vector2.ZERO
	)
	if target.is_zero_approx():
		return false
	if controlled_player.server_is_charging:
		controlled_player.cpu_cancel_shot_charge()
		_reset_cpu_charge_tracking()
	_clear_attack_plan()
	_last_ability_defense_role = StringName(
		assignment.get("role", &"cover")
	)
	_last_ability_defense_target = _clamp_to_field(target)
	_movement_target = _last_ability_defense_target
	var target_peer_id = int(assignment.get("target_peer_id", 0))
	if _last_ability_defense_role == &"press":
		_set_tactical_intent(
			INTENT_CHASE,
			_movement_target,
			target_peer_id
		)
		_try_defensive_ball_win()
	else:
		_set_tactical_intent(
			INTENT_COVER,
			_movement_target,
			target_peer_id
		)
	return true


func _get_ability_aware_goalkeeper_target(
	own_goal: FootballGoal
) -> Vector2:
	if (
		not opponent_ability_awareness_enabled
		or own_goal == null
		or _team_likely_has_possession()
	):
		return Vector2.ZERO
	var threat = _get_opponent_ability_threat_state()
	var goal_threat = maxf(
		float(threat.get("goal_threat", 0.0)),
		float(threat.get("power_shot_threat", 0.0))
	)
	if goal_threat < ability_defense_minimum_threat:
		return Vector2.ZERO
	var goal_center = _get_goal_center(own_goal)
	var actor = _get_opponent_by_peer_id(
		int(threat.get("primary_peer_id", 0))
	)
	var source = (
		actor.global_position
		if actor != null
		else ball.global_position
	)
	var target_y = source.y
	if actor != null and actor.server_is_charging:
		var aim = actor.server_direction.normalized()
		if not aim.is_zero_approx():
			target_y = _get_ray_y_at_x(
				ball.global_position,
				aim,
				goal_center.x,
				goal_center.y
			)
	var mouth = own_goal.get_mouth_y_range()
	target_y = clampf(
		target_y,
		mouth.x + anticipatory_defense_goal_mouth_padding,
		mouth.y - anticipatory_defense_goal_mouth_padding
	)
	var toward_field = goal_center.direction_to(ball.global_position)
	if toward_field.is_zero_approx():
		toward_field = Vector2(_get_attack_sign(), 0.0)
	var depth = lerpf(
		anticipatory_defense_keeper_depth,
		110.0,
		clampf(goal_threat, 0.0, 1.0)
	)
	return _clamp_to_field(
		Vector2(goal_center.x, target_y) + toward_field * depth
	)


func _get_ability_aware_receiver_pass_bonus(
	receiver: FootballPlayer,
	plan: Dictionary,
	shot_blocked: bool
) -> float:
	if receiver == null or not is_instance_valid(receiver):
		return 0.0
	var now = _server_time_seconds()
	var receiver_ready = (
		receiver.selected_ability != FootballPlayer.ABILITY_NONE
		and receiver.server_ability_cooldown_ends_at <= now + 0.02
	)
	var forward_progress = float(plan.get("forward_progress", 0.0))
	var openness = float(plan.get("openness", 0.0))
	var bonus = 0.0
	if receiver_ready:
		var receiver_ability: int = receiver.selected_ability
		if receiver_ability == FootballPlayer.ABILITY_DIRECT_FINISH:
			bonus += 360.0 if forward_progress > 220.0 else 180.0
		elif receiver_ability in [
			FootballPlayer.ABILITY_OVERDRIVE,
			FootballPlayer.ABILITY_BURST_DRIBBLE,
			FootballPlayer.ABILITY_BLIND_SPOT
		]:
			bonus += 260.0 if forward_progress > 300.0 else 110.0
		elif receiver_ability == FootballPlayer.ABILITY_POWER_STRIKE:
			bonus += 300.0 if openness >= 420.0 else 120.0
		elif receiver_ability in [
			FootballPlayer.ABILITY_TIME_SKIP_PASS,
			FootballPlayer.ABILITY_QUICK_TRIGGER,
			FootballPlayer.ABILITY_HEEL_TURN
		]:
			bonus += 170.0
	if (
		match_manager != null
		and match_manager.has_method("get_cpu_ability_team_assignment")
	):
		var assignment = match_manager.get_cpu_ability_team_assignment(
			controlled_player.team,
			receiver.owner_peer_id
		) as Dictionary
		var shared_role = StringName(assignment.get("role", &""))
		match shared_role:
			&"runner":
				bonus += 260.0 if forward_progress > 220.0 else 90.0
			&"connector":
				bonus += 150.0
			&"safety":
				bonus += 45.0 if shot_blocked else -25.0
	if shot_blocked:
		bonus *= 1.2
	return bonus


func _has_active_ability(ability_id: int) -> bool:
	return (
		controlled_player.server_ability_active
		and controlled_player.server_active_ability_id == ability_id
	)


func _overdrive_is_useful() -> bool:
	var ball_distance = controlled_player.global_position.distance_to(
		ball.global_position
	)
	if (
		_server_time_seconds() < _overdrive_through_run_until
		and not _overdrive_through_run_target.is_zero_approx()
		and controlled_player.global_position.distance_to(
			_overdrive_through_run_target
		) > 480.0
		and _team_likely_has_possession()
	):
		# Accelerate before the through ball is played. Waiting until the ball is
		# already moving removes the speed advantage this coordinated run needs.
		return true
	var receive_intention = match_manager.get_cpu_pass_intention(
		controlled_player.owner_peer_id
	)
	if receive_intention.is_empty():
		receive_intention = _get_detected_pass_reception()
	if not receive_intention.is_empty() and ball_distance > 720.0:
		var receive_position: Vector2 = receive_intention.get(
			"position",
			controlled_player.global_position
		)
		var opponent_race_distance = _nearest_opponent_distance(
			receive_position
		)
		return (
			controlled_player.global_position.distance_to(receive_position)
			> 520.0
			and opponent_race_distance > 300.0
		)
	if not _is_primary_ball_chaser() or ball_distance < 900.0:
		return false
	var own_goal = _get_own_goal()
	if own_goal == null:
		return false
	var moving_toward_own_goal = (
		ball.linear_velocity.length() > 450.0
		and ball.linear_velocity.normalized().dot(
			ball.global_position.direction_to(_get_goal_center(own_goal))
		) > 0.35
	)
	var loose_ball_advantage = (
		_nearest_opponent_distance(ball.global_position)
		> ball_distance * 0.72
	)
	return moving_toward_own_goal or loose_ball_advantage


func _last_ball_touch_was_opponent() -> bool:
	if ball.last_touch_peer_id == 0:
		return false
	return (
		ball.get_last_touch_peer_id_for_team(controlled_player.team)
		!= ball.last_touch_peer_id
	)


func _heel_turn_is_useful() -> bool:
	if (
		controlled_player.global_position.distance_to(ball.global_position)
		>= controlled_player.kick_feedback_detection_distance
		or _nearest_opponent_distance(ball.global_position) >= 650.0
	):
		return false
	var heel_target = controlled_player.global_position + (
		ball.global_position.direction_to(controlled_player.global_position)
		* controlled_player.heel_turn_ball_distance
	)
	if heel_target != _clamp_to_field(heel_target):
		return false
	var own_goal = _get_own_goal()
	if (
		own_goal != null
		and heel_target.distance_to(_get_goal_center(own_goal))
		< ball.global_position.distance_to(_get_goal_center(own_goal)) - 80.0
	):
		return false
	for teammate in _get_teammates():
		if (
			not is_instance_valid(teammate)
			or teammate == controlled_player
			or not teammate.controls_enabled
		):
			continue
		var backward_progress = (
			teammate.global_position.x - controlled_player.global_position.x
		) * _get_attack_sign()
		if (
			backward_progress < -180.0
			and _minimum_segment_clearance(
				ball.global_position,
				teammate.global_position
			) > 180.0
		):
			return true
	return _nearest_opponent_distance(controlled_player.global_position) < 430.0


func _phantom_heel_followup_is_useful() -> bool:
	if (
		ball == null
		or not controlled_player.cpu_can_execute_phantom_heel_followup()
		or _ball_is_in_own_goal_danger()
	):
		return false
	var direction: Vector2 = controlled_player.call(
		"_get_phantom_heel_followup_direction",
		ball
	) as Vector2
	if direction.is_zero_approx():
		return false
	var target: Vector2 = _clamp_to_field(
		ball.global_position
		+ direction * controlled_player.heel_turn_followup_ball_distance
	)
	var forward_progress: float = (
		target.x - ball.global_position.x
	) * _get_attack_sign()
	return (
		forward_progress > 60.0
		and _nearest_opponent_distance(target) >= 150.0
	)


func _elastic_step_is_useful() -> bool:
	if controlled_player.is_neymar_boss():
		return _neymar_elastic_step_is_useful()
	if (
		(
			_ball_is_in_own_goal_danger()
			and (
				not _is_true_one_vs_one()
				or _one_vs_one_requires_emergency_defense()
			)
		)
		or controlled_player.global_position.distance_to(ball.global_position)
		>= 620.0
		or _nearest_opponent_distance(controlled_player.global_position)
		>= 780.0
	):
		return false
	var escape_direction = _get_elastic_escape_direction()
	if escape_direction.is_zero_approx():
		return false
	var escape_target = _clamp_to_field(
		ball.global_position + escape_direction * 520.0
	)
	# The orbit itself wrong-foots the nearby marker. Requiring a huge probe-space
	# gain made CPUs ignore it in the exact tight 1v1 situations it is built for.
	var required_space_gain: float = -20.0 if _is_true_one_vs_one() else 45.0
	return (
		_nearest_opponent_distance(escape_target)
		> _nearest_opponent_distance(controlled_player.global_position)
		+ required_space_gain
	)


func _get_elastic_escape_direction() -> Vector2:
	if controlled_player.is_neymar_boss():
		return _get_neymar_elastic_escape_direction()
	var opponent = _get_nearest_opponent_to(controlled_player.global_position)
	if opponent == null:
		return Vector2(_get_attack_sign(), 0.0)
	var away = opponent.global_position.direction_to(
		controlled_player.global_position
	)
	var forward = Vector2(_get_attack_sign(), 0.0)
	var first_side = Vector2(-away.y, away.x).normalized()
	var second_side = -first_side
	var first_direction = (forward * 0.48 + first_side * 0.88).normalized()
	var second_direction = (forward * 0.48 + second_side * 0.88).normalized()
	var probe_distance = 760.0
	var first_space = _nearest_opponent_distance(
		controlled_player.global_position + first_direction * probe_distance
	)
	var second_space = _nearest_opponent_distance(
		controlled_player.global_position + second_direction * probe_distance
	)
	return first_direction if first_space >= second_space else second_direction


func _neymar_elastic_step_is_useful() -> bool:
	if (
		ball == null
		or _ball_is_in_own_goal_danger()
		or controlled_player.global_position.distance_to(ball.global_position)
		> controlled_player.kick_feedback_detection_distance * 1.06
		or ball.linear_velocity.length() > 2100.0
	):
		return false
	var opponent: FootballPlayer = _get_nearest_opponent_to(ball.global_position)
	if opponent == null:
		return false
	var pressure_distance: float = controlled_player.global_position.distance_to(
		opponent.global_position
	)
	# Save the trick for a real duel. At longer range normal dribbling and passing
	# preserve the ability's surprise instead of advertising it continuously.
	if pressure_distance > 920.0:
		return false
	var escape_direction: Vector2 = _get_neymar_elastic_escape_direction()
	if escape_direction.is_zero_approx():
		return false
	var origin: Vector2 = ball.global_position
	var escape_target: Vector2 = _clamp_to_field(
		origin + escape_direction * 680.0
	)
	var current_clearance: float = _nearest_opponent_distance(
		controlled_player.global_position
	)
	var target_clearance: float = _nearest_opponent_distance(escape_target)
	var route_clearance: float = _minimum_segment_clearance(
		origin,
		escape_target
	)
	var forward_progress: float = (
		(escape_target.x - origin.x) * _get_attack_sign()
	)
	return (
		target_clearance >= current_clearance + 45.0
		or (
			pressure_distance <= 470.0
			and target_clearance >= 310.0
		)
		or (
			forward_progress >= 180.0
			and route_clearance >= 260.0
		)
	)


func _get_neymar_elastic_escape_direction() -> Vector2:
	if ball == null:
		return Vector2(_get_attack_sign(), 0.0)
	var origin: Vector2 = ball.global_position
	var opponent: FootballPlayer = _get_nearest_opponent_to(origin)
	if opponent == null:
		return Vector2(_get_attack_sign(), 0.0)
	var opponent_goal: FootballGoal = _get_opponent_goal()
	var forward: Vector2 = Vector2(_get_attack_sign(), 0.0)
	if opponent_goal != null:
		forward = origin.direction_to(_get_goal_center(opponent_goal))
	if forward.is_zero_approx():
		forward = Vector2(_get_attack_sign(), 0.0)
	var predicted_opponent: Vector2 = (
		opponent.global_position + opponent.linear_velocity * 0.24
	)
	var away_from_pressure: Vector2 = predicted_opponent.direction_to(origin)
	var candidate_angles: Array[float] = [
		-1.02,
		-0.72,
		-0.44,
		-0.20,
		0.20,
		0.44,
		0.72,
		1.02,
	]
	var best_direction: Vector2 = Vector2.ZERO
	var best_score: float = -INF
	var now: float = _server_time_seconds()
	for angle: float in candidate_angles:
		var direction: Vector2 = forward.rotated(angle).normalized()
		var raw_target: Vector2 = origin + direction * 680.0
		var target: Vector2 = _clamp_to_field(raw_target)
		var clamped_distance: float = raw_target.distance_to(target)
		var destination_clearance: float = _nearest_opponent_distance(target)
		var route_clearance: float = _minimum_segment_clearance(origin, target)
		var predicted_clearance: float = target.distance_to(predicted_opponent)
		var forward_progress: float = (
			(target.x - origin.x) * _get_attack_sign()
		)
		var score: float = (
			destination_clearance * 1.10
			+ minf(route_clearance, 900.0) * 0.62
			+ predicted_clearance * 0.34
			+ forward_progress * 0.30
			+ direction.dot(away_from_pressure) * 135.0
			- clamped_distance * 2.4
		)
		# Once the first feint has opened a good lane, finish the burst through it
		# instead of immediately zig-zagging back into the defender.
		if (
			now < _neymar_elastic_direction_until
			and not _neymar_elastic_direction.is_zero_approx()
		):
			score += direction.dot(_neymar_elastic_direction) * 175.0
		if score > best_score:
			best_score = score
			best_direction = direction
	return best_direction


func _incoming_ball_threat(
	maximum_distance: float,
	minimum_speed: float
) -> bool:
	if (
		ball.linear_velocity.length() < minimum_speed
		or controlled_player.global_position.distance_to(
			ball.global_position
		) > maximum_distance
	):
		return false
	var toward_player = ball.global_position.direction_to(
		controlled_player.global_position
	)
	return ball.linear_velocity.normalized().dot(toward_player) > 0.58


func _goalkeeper_reach_is_needed() -> bool:
	if not _is_designated_goalkeeper(controlled_player):
		return false
	var own_goal = _get_own_goal()
	if own_goal == null:
		return false
	var threat = _predict_own_goal_threat(3.0)
	if threat.is_empty():
		_goalkeeper_reach_target = Vector2.ZERO
		return false
	_goalkeeper_reach_target = threat.get(
		"position",
		_get_goal_center(own_goal)
	)
	var reach_distance = controlled_player.global_position.distance_to(
		_goalkeeper_reach_target
	)
	return (
		reach_distance > controlled_player.kick_feedback_detection_distance * 0.72
		and reach_distance < 1150.0
		and float(threat.get("time", 99.0)) < 2.2
	)


func _predict_own_goal_threat(maximum_seconds: float) -> Dictionary:
	var own_goal = _get_own_goal()
	if own_goal == null or ball.linear_velocity.length() < 300.0:
		return {}
	var goal_x = own_goal.get_goal_plane_x()
	var mouth_range = own_goal.get_mouth_y_range()
	var position = ball.global_position
	var velocity = ball.linear_velocity
	var elapsed = 0.0
	var step_seconds = 0.06
	var damping = maxf(0.0, ball.linear_damp)
	while elapsed < maximum_seconds:
		var previous = position
		var current_step = minf(step_seconds, maximum_seconds - elapsed)
		if damping > 0.001:
			velocity *= exp(-damping * current_step)
		position += velocity * current_step
		if position.y < ball_wall_top_y:
			position.y = ball_wall_top_y + (ball_wall_top_y - position.y)
			velocity.y = absf(velocity.y) * 0.8
		elif position.y > ball_wall_bottom_y:
			position.y = (
				ball_wall_bottom_y - (position.y - ball_wall_bottom_y)
			)
			velocity.y = -absf(velocity.y) * 0.8
		elapsed += current_step
		if (previous.x - goal_x) * (position.x - goal_x) <= 0.0:
			var x_distance: float = position.x - previous.x
			var ratio: float = (
				0.0
				if absf(x_distance) < 0.001
				else (goal_x - previous.x) / x_distance
			)
			var crossing_y = lerpf(previous.y, position.y, ratio)
			if (
				crossing_y >= mouth_range.x - 80.0
				and crossing_y <= mouth_range.y + 80.0
			):
				return {
					"position": Vector2(goal_x, crossing_y),
					"time": elapsed
				}
			return {}
		if velocity.length() < 180.0:
			break
	return {}


func _mirage_step_is_useful() -> bool:
	if (
		not is_instance_valid(_mirage_setup_target)
		or _mirage_activate_after <= 0.0
		or _server_time_seconds() < _mirage_activate_after
	):
		return false
	var opponent = _mirage_setup_target
	var forward_progress = (
		opponent.global_position.x
		- controlled_player.global_position.x
	) * _get_attack_sign()
	var behind_target = opponent.global_position + Vector2(
		_get_attack_sign() * 360.0,
		0.0
	)
	return (
		not _ball_is_in_own_goal_danger()
		and forward_progress > 40.0
		and controlled_player.global_position.distance_to(
			opponent.global_position
		) < 920.0
		and behind_target == _clamp_to_field(behind_target)
		and _nearest_opponent_distance(behind_target) > 210.0
	)


func _boogie_woogie_is_useful() -> bool:
	if match_manager.players_parent == null:
		return false
	var nearest_player: FootballPlayer
	var nearest_distance = INF
	for child in match_manager.players_parent.get_children():
		var candidate = child as FootballPlayer
		if (
			candidate == null
			or candidate == controlled_player
			or not candidate.controls_enabled
			or candidate.team == controlled_player.team
			or candidate.team == &""
		):
			continue
		var distance = controlled_player.global_position.distance_squared_to(
			candidate.global_position
		)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_player = candidate
	if nearest_player == null:
		return false
	var destination = nearest_player.global_position
	var target_near_ball = destination.distance_to(
		ball.global_position
	) < 720.0
	var improves_ball_access = (
		destination.distance_to(ball.global_position)
		+ 260.0
		< controlled_player.global_position.distance_to(ball.global_position)
	)
	var forward_gain = (
		destination.x
		- controlled_player.global_position.x
	) * _get_attack_sign()
	var own_goal = _get_own_goal()
	if (
		own_goal != null
		and destination.distance_to(_get_goal_center(own_goal)) < 1350.0
		and _ball_is_in_own_goal_danger()
	):
		return false
	var tactical_disruption = (
		target_near_ball
		and forward_gain > 220.0
	)
	return (
		target_near_ball
		and (
			improves_ball_access
			or forward_gain > boogie_woogie_minimum_position_gain
			or tactical_disruption
		)
	)


func _clamp_to_field(position: Vector2) -> Vector2:
	return Vector2(
		clampf(position.x, minimum_field_x, maximum_field_x),
		clampf(position.y, minimum_field_y, maximum_field_y)
	)
