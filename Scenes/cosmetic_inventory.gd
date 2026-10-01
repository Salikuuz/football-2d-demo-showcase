class_name FootballCosmeticInventory
extends Node


signal inventory_changed
signal loadout_changed(slot: StringName, item_id: String)
signal visual_preferences_changed
signal trade_up_completed(consumed_ids: Array[String], reward_id: String)

const SCHEMA_VERSION: int = 13
const DEFAULT_SAVE_PATH: String = "user://cosmetic_inventory.cfg"
const QUICK_CHAT_SLOT_COUNT: int = 8
const PLAYER_SUBTITLE_MAX_LENGTH: int = 48
const TRADE_UP_ITEM_COUNT: int = 5
const RARITY_ORDER: Array[String] = [
	"common", "uncommon", "rare", "epic", "legendary"
]

const SLOT_PLAYER_SKIN: StringName = &"player_skin"
const SLOT_GOAL_EXPLOSION: StringName = &"goal_explosion"
const SLOT_GOAL_THEME: StringName = &"goal_theme"
const SLOT_PLAYER_BANNER: StringName = &"player_banner"
const SLOT_ABILITY_PARTICLE: StringName = &"ability_particle"
const SLOT_FRAME_PALETTE: StringName = &"frame_palette"
const SLOT_PLAYER_MATERIAL: StringName = &"player_material"
const SLOT_TEAM_COLOR: StringName = &"team_color"
const SLOT_QUICK_CHAT: StringName = &"quick_chat"
const SLOT_PLAYER_SUBTITLE: StringName = &"player_subtitle"
const SLOT_PLAYER_SKIN_COLOR: StringName = &"player_skin_color"
const SLOT_PLAYER_BANNER_COLOR: StringName = &"player_banner_color"
const SLOT_GOAL_EXPLOSION_COLOR: StringName = &"goal_explosion_color"
const SLOT_TEAM_PRIMARY_COLOR: StringName = &"team_primary_color"
const DICTATOR_TEAM_COLOR_OVERRIDE: String = "e5b52f"
const GOJO_TEAM_COLOR_OVERRIDE: String = "8f43ff"
const NEYMAR_TEAM_COLOR_OVERRIDE: String = "f6d32d"
const HAALAND_TEAM_COLOR_OVERRIDE: String = "6cabdd"
const PLAYER_SKIN_ORIGINAL_COLOR: int = -1
const PLAYER_SKIN_COLORS: Array[Dictionary] = [
	{"name": "Red", "primary": "ef3b4f", "secondary": "ff9aa5"},
	{"name": "Orange", "primary": "f47b32", "secondary": "ffd09b"},
	{"name": "Gold", "primary": "e5b52f", "secondary": "fff0a0"},
	{"name": "Green", "primary": "35b96f", "secondary": "aaf2c6"},
	{"name": "Cyan", "primary": "2bc8cf", "secondary": "b8fbff"},
	{"name": "Blue", "primary": "347ee8", "secondary": "b9d8ff"},
	{"name": "Purple", "primary": "8b55df", "secondary": "d9c2ff"},
	{"name": "Pink", "primary": "e74f9d", "secondary": "ffc2df"},
	{"name": "White", "primary": "d9e0e7", "secondary": "ffffff"},
	{"name": "Black", "primary": "252a33", "secondary": "9099a8"},
]
const GOAL_EXPLOSION_COLORS: Array[Dictionary] = PLAYER_SKIN_COLORS
const PLAYER_BANNER_COLORS: Array[Dictionary] = PLAYER_SKIN_COLORS
const BLUE_TEAM_COLORS: Array[Dictionary] = [
	{"id": "team_color.blue_royal", "name": "Royal Blue", "color": "258dff"},
	{"id": "team_color.blue_sky", "name": "Sky Blue", "color": "43c6ff"},
	{"id": "team_color.blue_cobalt", "name": "Cobalt", "color": "3159e8"},
	{"id": "team_color.blue_cyan", "name": "Cyan", "color": "19d2d8"},
	{"id": "team_color.blue_teal", "name": "Teal", "color": "18a99a"},
	{"id": "team_color.blue_indigo", "name": "Indigo", "color": "6954db"},
	{"id": "team_color.blue_violet", "name": "Violet", "color": "9257e8"},
	{"id": "team_color.blue_ice", "name": "Ice", "color": "9de9ff"},
	{"id": "team_color.blue_navy", "name": "Navy", "color": "193d83"},
	{"id": "team_color.blue_mint", "name": "Mint", "color": "53d7ad"},
]
const RED_TEAM_COLORS: Array[Dictionary] = [
	{"id": "team_color.red_crimson", "name": "Crimson", "color": "ff304f"},
	{"id": "team_color.red_scarlet", "name": "Scarlet", "color": "e9273f"},
	{"id": "team_color.red_orange", "name": "Orange", "color": "ff783e"},
	{"id": "team_color.red_amber", "name": "Amber", "color": "f2aa35"},
	{"id": "team_color.red_gold", "name": "Gold", "color": "e4bd42"},
	{"id": "team_color.red_coral", "name": "Coral", "color": "ff6f70"},
	{"id": "team_color.red_rose", "name": "Rose", "color": "e84b91"},
	{"id": "team_color.red_magenta", "name": "Magenta", "color": "cf3ccc"},
	{"id": "team_color.red_burgundy", "name": "Burgundy", "color": "982d46"},
	{"id": "team_color.red_copper", "name": "Copper", "color": "bd673b"},
]

const SINGLE_EQUIP_SLOTS: Array[StringName] = [
	SLOT_PLAYER_SKIN,
	SLOT_FRAME_PALETTE,
	SLOT_PLAYER_MATERIAL,
	SLOT_GOAL_EXPLOSION,
	SLOT_GOAL_THEME,
	SLOT_PLAYER_BANNER,
	SLOT_ABILITY_PARTICLE,
]

# Catalog entries use stable IDs rather than resource paths in saved or
# networked loadouts. Visual resources can be attached to these IDs later
# without invalidating player inventories.
const CATALOG: Dictionary = {
	"frame_palette.classic_touch": {"slot": SLOT_FRAME_PALETTE, "name": "Classic Touch", "rarity": "common", "blue": ["55d8ff", "f4fbff", "258dff"], "red": ["ff765c", "fff1df", "ff304f"], "owned_by_default": true},
	"frame_palette.cosmic_rift": {"slot": SLOT_FRAME_PALETTE, "name": "Cosmic Rift", "rarity": "rare", "blue": ["69efff", "d9c4ff", "6657ff"], "red": ["ff55bd", "ffd56a", "ff375f"], "owned_by_default": false},
	"frame_palette.street_gold": {"slot": SLOT_FRAME_PALETTE, "name": "Street Gold", "rarity": "uncommon", "blue": ["ffd34f", "8ff3ff", "297dff"], "red": ["ff783e", "ffe079", "ff334e"], "owned_by_default": false},
	"frame_palette.frost_prism": {"slot": SLOT_FRAME_PALETTE, "name": "Frost Prism", "rarity": "uncommon", "blue": ["a8efff", "ffffff", "48a8ff"], "red": ["ff8da8", "f6ffff", "ff435d"], "owned_by_default": false},
	"frame_palette.royal_crest": {"slot": SLOT_FRAME_PALETTE, "name": "Royal Crest", "rarity": "rare", "blue": ["ffd34f", "f7fbff", "347ee8"], "red": ["ffbd42", "fff1bf", "e63b50"], "owned_by_default": false},
	"frame_palette.emberline": {"slot": SLOT_FRAME_PALETTE, "name": "Emberline", "rarity": "uncommon", "blue": ["ff9b38", "77edff", "3688ff"], "red": ["ff6a32", "fff0a0", "ff304a"], "owned_by_default": false},
	"frame_palette.neon_circuit": {"slot": SLOT_FRAME_PALETTE, "name": "Neon Circuit", "rarity": "rare", "blue": ["79ff9d", "9df6ff", "277eff"], "red": ["b6ff62", "fff1b0", "ff3d57"], "owned_by_default": false},
	"frame_palette.eclipse": {"slot": SLOT_FRAME_PALETTE, "name": "Eclipse", "rarity": "uncommon", "blue": ["a77cff", "75eaff", "405bff"], "red": ["cb72ff", "ff9fcf", "ed3857"], "owned_by_default": false},
	"frame_palette.aerial_crown": {"slot": SLOT_FRAME_PALETTE, "name": "Aerial Crown", "rarity": "rare", "blue": ["ecfbff", "ffd85a", "3da5ff"], "red": ["fff8ed", "ffc15a", "ff4658"], "owned_by_default": false},
	"frame_palette.crimson_bloom": {"slot": SLOT_FRAME_PALETTE, "name": "Crimson Bloom", "rarity": "common", "blue": ["ff5fbb", "f5fbff", "318cff"], "red": ["ff4b59", "ffd16a", "ef2845"], "owned_by_default": false},
	"frame_palette.chrome_pulse": {"slot": SLOT_FRAME_PALETTE, "name": "Chrome Pulse", "rarity": "rare", "blue": ["7ae5ff", "ffffff", "438dff"], "red": ["ff6f79", "ffffff", "ee334e"], "owned_by_default": false},
	"frame_palette.mint_gold": {"slot": SLOT_FRAME_PALETTE, "name": "Mint Gold", "rarity": "common", "blue": ["6fffd0", "ffd75d", "268cff"], "red": ["7fffc2", "ffba93", "f13c55"], "owned_by_default": false},
	"frame_palette.sunset_gate": {"slot": SLOT_FRAME_PALETTE, "name": "Sunset Gate", "rarity": "uncommon", "blue": ["ffd15a", "78eaff", "397cff"], "red": ["ff8752", "fff0a4", "f23850"], "owned_by_default": false},
	"frame_palette.obsidian_guard": {"slot": SLOT_FRAME_PALETTE, "name": "Obsidian Guard", "rarity": "rare", "blue": ["61d9ff", "dcecff", "287dff"], "red": ["ff4d62", "e8edf5", "da263f"], "owned_by_default": false},
	"frame_palette.golden_touch": {"slot": SLOT_FRAME_PALETTE, "name": "Golden Touch", "rarity": "rare", "blue": ["ffd84f", "edf8ff", "3b83ff"], "red": ["ffd052", "fff0c2", "e53b4e"], "owned_by_default": false},
	"frame_palette.dark_vanguard": {"slot": SLOT_FRAME_PALETTE, "name": "Dark Vanguard", "rarity": "rare", "blue": ["3fdcff", "a989ff", "246eff"], "red": ["ff3654", "ffc650", "d91f3d"], "owned_by_default": false},
	"frame_palette.abyssal": {"slot": SLOT_FRAME_PALETTE, "name": "Abyssal", "rarity": "rare", "blue": ["66eeff", "bb8cff", "394fff"], "red": ["ff4fb7", "ff9b5f", "d72a5b"], "owned_by_default": false},
	"frame_palette.celestial": {"slot": SLOT_FRAME_PALETTE, "name": "Celestial", "rarity": "rare", "blue": ["ffd75a", "c6f7ff", "4488ff"], "red": ["ffd15a", "ffb5cb", "e63a50"], "owned_by_default": false},
	"frame_palette.omega": {"slot": SLOT_FRAME_PALETTE, "name": "Omega", "rarity": "rare", "blue": ["ff60ca", "68f4ff", "3c6eff"], "red": ["ff5c43", "6ffff0", "ed2548"], "owned_by_default": false},
	"player_material.matte": {"slot": SLOT_PLAYER_MATERIAL, "name": "Matte", "rarity": "common", "material_style": "matte", "owned_by_default": true},
	"player_material.anodized": {"slot": SLOT_PLAYER_MATERIAL, "name": "Anodized", "rarity": "common", "material_style": "anodized", "owned_by_default": false},
	"player_material.brushed_metal": {"slot": SLOT_PLAYER_MATERIAL, "name": "Brushed Metal", "rarity": "common", "material_style": "brushed", "owned_by_default": false},
	"player_material.carbon_fiber": {"slot": SLOT_PLAYER_MATERIAL, "name": "Carbon Fiber", "rarity": "common", "material_style": "carbon", "owned_by_default": false},
	"player_material.pearlescent": {"slot": SLOT_PLAYER_MATERIAL, "name": "Pearlescent", "rarity": "common", "material_style": "pearl", "animated": true, "owned_by_default": false},
	"player_material.circuit": {"slot": SLOT_PLAYER_MATERIAL, "name": "Neon Circuit", "rarity": "common", "material_style": "circuit", "animated": true, "owned_by_default": false},
	"player_material.stardust": {"slot": SLOT_PLAYER_MATERIAL, "name": "Stardust", "rarity": "common", "material_style": "stardust", "animated": true, "owned_by_default": false},
	"player_material.vortex": {"slot": SLOT_PLAYER_MATERIAL, "name": "Vortex", "rarity": "common", "material_style": "vortex", "animated": true, "owned_by_default": false},
	"team_color.blue_royal": {"slot": SLOT_TEAM_COLOR, "name": "Blue · Royal", "team": "blue", "color_index": 0, "rarity": "common", "owned_by_default": true},
	"team_color.blue_sky": {"slot": SLOT_TEAM_COLOR, "name": "Blue · Sky", "team": "blue", "color_index": 1, "rarity": "common", "owned_by_default": false},
	"team_color.blue_cobalt": {"slot": SLOT_TEAM_COLOR, "name": "Blue · Cobalt", "team": "blue", "color_index": 2, "rarity": "common", "owned_by_default": false},
	"team_color.blue_cyan": {"slot": SLOT_TEAM_COLOR, "name": "Blue · Cyan", "team": "blue", "color_index": 3, "rarity": "common", "owned_by_default": false},
	"team_color.blue_teal": {"slot": SLOT_TEAM_COLOR, "name": "Blue · Teal", "team": "blue", "color_index": 4, "rarity": "common", "owned_by_default": false},
	"team_color.blue_indigo": {"slot": SLOT_TEAM_COLOR, "name": "Blue · Indigo", "team": "blue", "color_index": 5, "rarity": "common", "owned_by_default": false},
	"team_color.blue_violet": {"slot": SLOT_TEAM_COLOR, "name": "Blue · Violet", "team": "blue", "color_index": 6, "rarity": "common", "owned_by_default": false},
	"team_color.blue_ice": {"slot": SLOT_TEAM_COLOR, "name": "Blue · Ice", "team": "blue", "color_index": 7, "rarity": "common", "owned_by_default": false},
	"team_color.blue_navy": {"slot": SLOT_TEAM_COLOR, "name": "Blue · Navy", "team": "blue", "color_index": 8, "rarity": "common", "owned_by_default": false},
	"team_color.blue_mint": {"slot": SLOT_TEAM_COLOR, "name": "Blue · Mint", "team": "blue", "color_index": 9, "rarity": "common", "owned_by_default": false},
	"team_color.red_crimson": {"slot": SLOT_TEAM_COLOR, "name": "Red · Crimson", "team": "red", "color_index": 0, "rarity": "common", "owned_by_default": true},
	"team_color.red_scarlet": {"slot": SLOT_TEAM_COLOR, "name": "Red · Scarlet", "team": "red", "color_index": 1, "rarity": "common", "owned_by_default": false},
	"team_color.red_orange": {"slot": SLOT_TEAM_COLOR, "name": "Red · Orange", "team": "red", "color_index": 2, "rarity": "common", "owned_by_default": false},
	"team_color.red_amber": {"slot": SLOT_TEAM_COLOR, "name": "Red · Amber", "team": "red", "color_index": 3, "rarity": "common", "owned_by_default": false},
	"team_color.red_gold": {"slot": SLOT_TEAM_COLOR, "name": "Red · Gold", "team": "red", "color_index": 4, "rarity": "common", "owned_by_default": false},
	"team_color.red_coral": {"slot": SLOT_TEAM_COLOR, "name": "Red · Coral", "team": "red", "color_index": 5, "rarity": "common", "owned_by_default": false},
	"team_color.red_rose": {"slot": SLOT_TEAM_COLOR, "name": "Red · Rose", "team": "red", "color_index": 6, "rarity": "common", "owned_by_default": false},
	"team_color.red_magenta": {"slot": SLOT_TEAM_COLOR, "name": "Red · Magenta", "team": "red", "color_index": 7, "rarity": "common", "owned_by_default": false},
	"team_color.red_burgundy": {"slot": SLOT_TEAM_COLOR, "name": "Red · Burgundy", "team": "red", "color_index": 8, "rarity": "common", "owned_by_default": false},
	"team_color.red_copper": {"slot": SLOT_TEAM_COLOR, "name": "Red · Copper", "team": "red", "color_index": 9, "rarity": "common", "owned_by_default": false},
	"player_skin.classic": {
		"slot": SLOT_PLAYER_SKIN,
		"name": "Classic",
		"rarity": "common",
		"frame_style": "classic_rails",
		"owned_by_default": true,
	},
	"player_skin.andromeda": {
		"slot": SLOT_PLAYER_SKIN,
		"name": "Andromeda",
		"rarity": "rare",
		"primary": "7838eb",
		"secondary": "bff4ff",
		"pattern": "galaxy",
		"outer_deco": "orbit",
		"frame_style": "cosmic_gate",
		"animated": true,
		"owned_by_default": false,
	},
	"goal_explosion.classic": {
		"slot": SLOT_GOAL_EXPLOSION,
		"name": "Classic Team Burst",
		"rarity": "common",
		"owned_by_default": true,
	},
	"goal_theme.classic": {
		"slot": SLOT_GOAL_THEME,
		"name": "Classic",
		"rarity": "common",
		"owned_by_default": true,
	},
	"goal_explosion.andromeda": {
		"slot": SLOT_GOAL_EXPLOSION,
		"name": "Andromeda Collapse",
		"rarity": "epic",
		"owned_by_default": false,
	},
	"player_banner.classic": {
		"slot": SLOT_PLAYER_BANNER,
		"name": "Classic",
		"rarity": "common",
		"owned_by_default": true,
	},
	"player_banner.andromeda": {
		"slot": SLOT_PLAYER_BANNER,
		"name": "Andromeda",
		"rarity": "rare",
		"primary": "6d3ee8",
		"secondary": "9defff",
		"pattern": "galaxy",
		"frame_style": "cosmic",
		"animated": true,
		"owned_by_default": false,
	},
	"ability_particle.classic": {
		"slot": SLOT_ABILITY_PARTICLE,
		"name": "Classic Aura",
		"rarity": "common",
		"pattern": "classic",
		"texture_path": "res://Characters/ability_particle.svg",
		"owned_by_default": true,
	},
	"ability_particle.velocity_streaks": {"slot": SLOT_ABILITY_PARTICLE, "name": "Velocity Streaks", "rarity": "uncommon", "pattern": "streaks", "texture_path": "res://Assets/cosmetics/particles/velocity_streak.svg", "primary": "58d8ff", "secondary": "ffffff", "owned_by_default": false},
	"ability_particle.starfall": {"slot": SLOT_ABILITY_PARTICLE, "name": "Starfall", "rarity": "rare", "pattern": "stars", "texture_path": "res://Assets/cosmetics/particles/star_particle.svg", "primary": "ffe56a", "secondary": "fffbd5", "owned_by_default": false},
	"ability_particle.arcane_orbit": {"slot": SLOT_ABILITY_PARTICLE, "name": "Arcane Orbit", "rarity": "rare", "pattern": "orbits", "texture_path": "res://Assets/cosmetics/particles/orbit_particle.svg", "primary": "b56cff", "secondary": "76f5ff", "owned_by_default": false},
	"ability_particle.prism_shards": {"slot": SLOT_ABILITY_PARTICLE, "name": "Prism Shards", "rarity": "epic", "pattern": "shards", "texture_path": "res://Assets/cosmetics/particles/prism_shard.svg", "primary": "ff65c8", "secondary": "69efff", "owned_by_default": false},
	"ability_particle.void_wisps": {"slot": SLOT_ABILITY_PARTICLE, "name": "Void Wisps", "rarity": "legendary", "pattern": "wisps", "texture_path": "res://Assets/cosmetics/particles/void_wisp.svg", "primary": "8d4cff", "secondary": "dfc5ff", "owned_by_default": false},
	"ability_particle.bubble_pop": {"slot": SLOT_ABILITY_PARTICLE, "name": "Bubble Pop", "rarity": "rare", "pattern": "bubbles", "texture_path": "res://Assets/cosmetics/particles/bubble_particle.svg", "primary": "63e8ff", "secondary": "e5fbff", "owned_by_default": false},
	"ability_particle.comet_sparks": {"slot": SLOT_ABILITY_PARTICLE, "name": "Comet Sparks", "rarity": "epic", "pattern": "comets", "texture_path": "res://Assets/cosmetics/particles/comet_spark.svg", "primary": "ffad38", "secondary": "fff2a8", "owned_by_default": false},
	"player_skin.street_striker": {"slot": SLOT_PLAYER_SKIN, "name": "Street Striker", "rarity": "uncommon", "primary": "d85a36", "secondary": "ffd0a6", "pattern": "chevrons", "outer_deco": "speed_tabs", "frame_style": "velocity_cut", "animated": true, "owned_by_default": false},
	"player_skin.frostline": {"slot": SLOT_PLAYER_SKIN, "name": "Frostline", "rarity": "rare", "primary": "71d9ff", "secondary": "e8fbff", "pattern": "frost", "outer_deco": "ice_points", "frame_style": "crystal_edge", "animated": true, "owned_by_default": false},
	"player_skin.royal_guard": {"slot": SLOT_PLAYER_SKIN, "name": "Royal Guard", "rarity": "epic", "primary": "c99a2e", "secondary": "fff0a8", "pattern": "crown", "outer_deco": "crown_points", "frame_style": "royal_seal", "animated": true, "owned_by_default": false},
	"player_skin.ember": {"slot": SLOT_PLAYER_SKIN, "name": "Ember Forward", "rarity": "rare", "primary": "ff542e", "secondary": "ffcf48", "pattern": "flame", "outer_deco": "flame_crown", "frame_style": "ember_rail", "animated": true, "owned_by_default": false},
	"player_skin.neon_pitch": {"slot": SLOT_PLAYER_SKIN, "name": "Neon Pitch", "rarity": "epic", "primary": "28e38c", "secondary": "c8ff4c", "pattern": "rings", "outer_deco": "orbit", "frame_style": "neon_circuit", "animated": true, "owned_by_default": false},
	"player_skin.shadow_play": {"slot": SLOT_PLAYER_SKIN, "name": "Shadow Play", "rarity": "rare", "primary": "5b5878", "secondary": "b9b5d8", "pattern": "halves", "outer_deco": "shadow_crescents", "frame_style": "eclipse", "animated": true, "owned_by_default": false},
	"player_skin.aerial_ace": {"slot": SLOT_PLAYER_SKIN, "name": "Aerial Ace", "rarity": "epic", "primary": "4ab3df", "secondary": "ffffff", "pattern": "wings", "outer_deco": "wings", "frame_style": "aerial_fins", "animated": true, "owned_by_default": false},
	"player_skin.crimson_press": {"slot": SLOT_PLAYER_SKIN, "name": "Crimson Press", "rarity": "rare", "primary": "d52f45", "secondary": "ff9a8f", "pattern": "stripes", "outer_deco": "pressure_spikes", "frame_style": "pressure_slash", "animated": true, "owned_by_default": false},
	"player_skin.chrome_touch": {"slot": SLOT_PLAYER_SKIN, "name": "Chrome Touch", "rarity": "epic", "primary": "9ba9b4", "secondary": "f4fbff", "pattern": "cross", "outer_deco": "brackets", "frame_style": "chrome_hex", "animated": true, "owned_by_default": false},
	"player_skin.mint_control": {"slot": SLOT_PLAYER_SKIN, "name": "Mint Control", "rarity": "rare", "primary": "5ce1b6", "secondary": "d9fff5", "pattern": "dots", "outer_deco": "dot_orbit", "frame_style": "control_nodes", "animated": true, "owned_by_default": false},
	"player_skin.sunset_playmaker": {"slot": SLOT_PLAYER_SKIN, "name": "Sunset Playmaker", "rarity": "epic", "primary": "f77655", "secondary": "ffd76a", "pattern": "sunburst", "outer_deco": "sun_rays", "frame_style": "sun_gate", "animated": true, "owned_by_default": false},
	"player_skin.obsidian_wall": {"slot": SLOT_PLAYER_SKIN, "name": "Obsidian Wall", "rarity": "legendary", "primary": "252b35", "secondary": "78d9ff", "pattern": "facets", "outer_deco": "shield_facets", "frame_style": "fortress", "owned_by_default": false},
	"player_skin.golden_touch": {"slot": SLOT_PLAYER_SKIN, "name": "Golden Touch", "rarity": "legendary", "primary": "d8a82e", "secondary": "fff0a4", "pattern": "rings", "outer_deco": "double_halo", "frame_style": "champion_halo", "animated": true, "owned_by_default": false},
	"player_skin.dark_vanguard": {"slot": SLOT_PLAYER_SKIN, "name": "Dark Vanguard", "rarity": "legendary", "primary": "0b0d16", "secondary": "ef334d", "pattern": "vanguard", "outer_deco": "dark_aura", "frame_style": "vanguard_armor", "animated": true, "owned_by_default": false},
	"player_skin.abyssal_sovereign": {"slot": SLOT_PLAYER_SKIN, "name": "Abyssal Sovereign", "rarity": "legendary", "primary": "17072f", "secondary": "8cf5ff", "pattern": "event_horizon", "outer_deco": "void_tendrils", "frame_style": "singularity_crown", "animated": true, "owned_by_default": false},
	"player_skin.celestial_seraph": {"slot": SLOT_PLAYER_SKIN, "name": "Celestial Seraph", "rarity": "legendary", "primary": "e8b943", "secondary": "f5ffff", "pattern": "celestial_runes", "outer_deco": "astral_wings", "frame_style": "seraphic_throne", "animated": true, "owned_by_default": false},
	"player_skin.omega_reactor": {"slot": SLOT_PLAYER_SKIN, "name": "Omega Reactor", "rarity": "legendary", "primary": "ff257d", "secondary": "72ffdc", "pattern": "reactor_core", "outer_deco": "plasma_blades", "frame_style": "omega_reactor", "animated": true, "owned_by_default": false},
	"player_skin.infinity_sorcerer": {"slot": SLOT_PLAYER_SKIN, "name": "Infinity Sorcerer", "rarity": "legendary", "primary": "5a16c9", "secondary": "e1c7ff", "pattern": "event_horizon", "outer_deco": "void_tendrils", "frame_style": "singularity_crown", "animated": true, "owned_by_default": false, "obtainable": false},
	"player_skin.brazilian_prince_10": {"slot": SLOT_PLAYER_SKIN, "name": "Brazilian Prince 10", "rarity": "legendary", "primary": "ffd928", "secondary": "28dfff", "pattern": "samba_flux", "outer_deco": "trickster_ribbons", "frame_style": "joga_bonito", "animated": true, "owned_by_default": false, "obtainable": false},
	"player_skin.nordic_terminator_9": {"slot": SLOT_PLAYER_SKIN, "name": "Nordic Terminator 9", "rarity": "legendary", "primary": "68cfff", "secondary": "f7fdff", "pattern": "thunder_core", "outer_deco": "nordic_lightning", "frame_style": "terminator_engine", "animated": true, "owned_by_default": false, "obtainable": false},
	"goal_explosion.goal_rush": {"slot": SLOT_GOAL_EXPLOSION, "name": "Goal Rush", "rarity": "uncommon", "primary": "4ba7ff", "secondary": "ffffff", "pattern": "rays", "owned_by_default": false},
	"goal_explosion.confetti_cup": {"slot": SLOT_GOAL_EXPLOSION, "name": "Confetti Cup", "rarity": "rare", "primary": "ffd13b", "secondary": "f04f78", "pattern": "confetti", "owned_by_default": false},
	"goal_explosion.ember_burst": {"slot": SLOT_GOAL_EXPLOSION, "name": "Ember Burst", "rarity": "rare", "primary": "ff4f2e", "secondary": "ffc43d", "pattern": "flame", "owned_by_default": false},
	"goal_explosion.electric_net": {"slot": SLOT_GOAL_EXPLOSION, "name": "Electric Net", "rarity": "epic", "primary": "35cfff", "secondary": "dfff52", "pattern": "electric", "owned_by_default": false},
	"goal_explosion.cyclone": {"slot": SLOT_GOAL_EXPLOSION, "name": "Touchline Cyclone", "rarity": "epic", "primary": "8f78ff", "secondary": "e7ddff", "pattern": "vortex", "owned_by_default": false},
	"goal_explosion.pixel_break": {"slot": SLOT_GOAL_EXPLOSION, "name": "Pixel Break", "rarity": "rare", "primary": "ef58be", "secondary": "59e7ff", "pattern": "pixel", "owned_by_default": false},
	"goal_explosion.crown_burst": {"slot": SLOT_GOAL_EXPLOSION, "name": "Crown Burst", "rarity": "legendary", "primary": "e2b33d", "secondary": "fff3ad", "pattern": "crown", "owned_by_default": false},
	"goal_explosion.ice_breaker": {"slot": SLOT_GOAL_EXPLOSION, "name": "Ice Breaker", "rarity": "epic", "primary": "64d8ff", "secondary": "effcff", "pattern": "frost", "owned_by_default": false},
	"goal_explosion.comet_strike": {"slot": SLOT_GOAL_EXPLOSION, "name": "Comet Strike", "rarity": "legendary", "primary": "ff7849", "secondary": "fff0c1", "pattern": "comet", "owned_by_default": false},
	"goal_explosion.trophy_lift": {"slot": SLOT_GOAL_EXPLOSION, "name": "Trophy Lift", "rarity": "legendary", "primary": "f0bd3d", "secondary": "ffffff", "pattern": "trophy", "owned_by_default": false},
	"goal_explosion.stadium_roar": {"slot": SLOT_GOAL_EXPLOSION, "name": "Stadium Roar", "rarity": "legendary", "primary": "4cf09a", "secondary": "fff47a", "pattern": "stadium", "owned_by_default": false},
	"player_banner.blueprint": {"slot": SLOT_PLAYER_BANNER, "name": "Yunger Caesar", "rarity": "uncommon", "primary": "d9ae52", "secondary": "fff0bd", "pattern": "grid", "frame_style": "royal", "image_path": "res://Assets/banners/caesars_vision.png", "owned_by_default": false},
	"player_banner.night_match": {"slot": SLOT_PLAYER_BANNER, "name": "Flash Frame", "rarity": "rare", "primary": "d77e9c", "secondary": "ffffff", "pattern": "floodlights", "frame_style": "glitch", "image_path": "res://Assets/banners/flash_frame.jpg", "owned_by_default": false},
	"player_banner.golden_boot": {"slot": SLOT_PLAYER_BANNER, "name": "Alvin Ascendant", "rarity": "epic", "primary": "d22f35", "secondary": "ffd33d", "pattern": "boot", "frame_style": "champion", "image_path": "res://Assets/banners/alvin_full.jpg", "owned_by_default": false},
	"player_banner.striker": {"slot": SLOT_PLAYER_BANNER, "name": "BekoIpad", "rarity": "epic", "primary": "74b3d8", "secondary": "f0ffff", "pattern": "nine", "frame_style": "champion", "image_path": "res://Assets/banners/cena_dynasty.jpg", "owned_by_default": false},
	"player_banner.finals": {"slot": SLOT_PLAYER_BANNER, "name": "Midnight Shift", "rarity": "epic", "primary": "ef9455", "secondary": "fff0d8", "pattern": "spotlight", "frame_style": "flame", "image_path": "res://Assets/banners/midnight_shift.jpg", "owned_by_default": false},
	"player_banner.elite": {"slot": SLOT_PLAYER_BANNER, "name": "Extra Time", "rarity": "legendary", "primary": "f6f6f6", "secondary": "74bfff", "pattern": "chevrons", "frame_style": "vanguard", "image_path": "res://Assets/banners/extra_time.jpg", "owned_by_default": false},
	"player_banner.champion": {"slot": SLOT_PLAYER_BANNER, "name": "Final Whistle", "rarity": "legendary", "primary": "46c68f", "secondary": "ffffff", "pattern": "crown", "frame_style": "champion", "image_path": "res://Assets/banners/final_whistle.jpg", "owned_by_default": false},
	"player_banner.dark_vanguard": {"slot": SLOT_PLAYER_BANNER, "name": "Dark Vanguard", "rarity": "legendary", "primary": "23293a", "secondary": "ed3f50", "pattern": "vanguard", "frame_style": "vanguard", "owned_by_default": false},
	"player_banner.ex_shadow_bean": {"slot": SLOT_PLAYER_BANNER, "name": "Ex Shadow Bean", "rarity": "legendary", "primary": "5d23a8", "secondary": "9dff67", "pattern": "shadow", "frame_style": "glitch", "image_path": "res://Characters/killerbean.jpg", "animated": true, "owned_by_default": false},
	"player_banner.dictator": {"slot": SLOT_PLAYER_BANNER, "name": "Golden Champion", "rarity": "legendary", "primary": "e6b72f", "secondary": "fff1a1", "pattern": "crown", "frame_style": "champion", "animated": true, "owned_by_default": false, "obtainable": false},
	"player_banner.gojo": {"slot": SLOT_PLAYER_BANNER, "name": "Satoru Gojo", "rarity": "legendary", "primary": "8f43ff", "secondary": "ff6bcb", "pattern": "void", "frame_style": "singularity_crown", "image_path": "res://Characters/gojo.jpg", "animated": true, "owned_by_default": false, "obtainable": false},
	"player_banner.erling_haaland": {"slot": SLOT_PLAYER_BANNER, "name": "Erling Haaland", "rarity": "legendary", "primary": "68cfff", "secondary": "f7fdff", "pattern": "electric", "frame_style": "electric", "image_path": "res://haaland.png", "animated": true, "owned_by_default": false, "obtainable": false},
	"player_banner.manuel_neuer": {"slot": SLOT_PLAYER_BANNER, "name": "Manuel Neuer", "rarity": "legendary", "primary": "d9ff45", "secondary": "f7fff0", "pattern": "shield", "frame_style": "vanguard", "image_path": "res://Assets/banners/manuel_neuer.png", "animated": true, "owned_by_default": false, "obtainable": false},
	"player_banner.triple_threat": {"slot": SLOT_PLAYER_BANNER, "name": "Triple Threat", "rarity": "epic", "primary": "d64b3b", "secondary": "ffd965", "pattern": "trio", "frame_style": "champion", "image_path": "res://Assets/banners/triple_chipmunks.jpg", "owned_by_default": false},
	"player_banner.ember_hatch": {"slot": SLOT_PLAYER_BANNER, "name": "Ember Hatch", "rarity": "epic", "primary": "ff8a3d", "secondary": "ffe38a", "pattern": "ember", "frame_style": "flame", "image_path": "res://Assets/banners/ember_hatch.png", "owned_by_default": false},
	"player_banner.solar_stride": {"slot": SLOT_PLAYER_BANNER, "name": "Solar Stride", "rarity": "epic", "primary": "ff9e35", "secondary": "fff1b8", "pattern": "sunburst", "frame_style": "electric", "image_path": "res://Assets/banners/solar_stride.jpeg", "owned_by_default": false},
	"player_banner.lone_wolf": {"slot": SLOT_PLAYER_BANNER, "name": "Lone Wolf", "rarity": "legendary", "primary": "b7b2a1", "secondary": "eef2ff", "pattern": "frost", "frame_style": "vanguard", "image_path": "res://Assets/banners/lone_wolf.jpg", "owned_by_default": false},
	"quick_chat.nice_shot": {
		"slot": SLOT_QUICK_CHAT,
		"name": "Guter Schuss!",
		"payload": "Guter Schuss!",
		"owned_by_default": true,
	},
	"quick_chat.great_pass": {
		"slot": SLOT_QUICK_CHAT,
		"name": "Guter Pass!",
		"payload": "Guter Pass!",
		"owned_by_default": true,
	},
	"quick_chat.what_a_save": {
		"slot": SLOT_QUICK_CHAT,
		"name": "Was für eine Parade!",
		"payload": "Was für eine Parade!",
		"owned_by_default": true,
	},
	"quick_chat.defending": {
		"slot": SLOT_QUICK_CHAT,
		"name": "Ich verteidige!",
		"payload": "Ich verteidige!",
		"owned_by_default": true,
	},
	"quick_chat.passing": {
		"slot": SLOT_QUICK_CHAT,
		"name": "Ich passe!",
		"payload": "Ich passe!",
		"owned_by_default": true,
	},
	"quick_chat.centering": {
		"slot": SLOT_QUICK_CHAT,
		"name": "In die Mitte!",
		"payload": "In die Mitte!",
		"owned_by_default": true,
	},
	"quick_chat.sorry": {
		"slot": SLOT_QUICK_CHAT,
		"name": "Entschuldigung!",
		"payload": "Entschuldigung!",
		"owned_by_default": true,
	},
	"quick_chat.gg": {
		"slot": SLOT_QUICK_CHAT,
		"name": "GG!",
		"payload": "GG!",
		"owned_by_default": true,
	},
	"quick_chat.emoji_fire": {
		"slot": SLOT_QUICK_CHAT,
		"name": "Stark gespielt!",
		"payload": "Stark gespielt!",
		"owned_by_default": false,
	},
	"quick_chat.emoji_star": {
		"slot": SLOT_QUICK_CHAT,
		"name": "Sauber!",
		"payload": "Sauber!",
		"owned_by_default": false,
	},
	"quick_chat.emoji_heart": {
		"slot": SLOT_QUICK_CHAT,
		"name": "Heart",
		"payload": "♥",
		"owned_by_default": false,
	},
	"quick_chat.emoji_snow": {
		"slot": SLOT_QUICK_CHAT,
		"name": "Cool geblieben!",
		"payload": "Cool geblieben!",
		"owned_by_default": false,
	},
	"quick_chat.lets_go": {
		"slot": SLOT_QUICK_CHAT,
		"name": "Los geht's!",
		"payload": "Los geht's!",
		"owned_by_default": false,
	},
	"quick_chat.locked_in": {"slot": SLOT_QUICK_CHAT, "name": "Fokus!", "payload": "Fokus!", "rarity": "common", "primary": "72bfff", "owned_by_default": false},
	"quick_chat.calculated": {"slot": SLOT_QUICK_CHAT, "name": "Berechnet!", "payload": "Berechnet!", "rarity": "uncommon", "primary": "8ed8ff", "owned_by_default": false},
	"quick_chat.wall_play": {"slot": SLOT_QUICK_CHAT, "name": "Über die Bande!", "payload": "Über die Bande!", "rarity": "uncommon", "primary": "9bc7e8", "owned_by_default": false},
	"quick_chat.one_more": {"slot": SLOT_QUICK_CHAT, "name": "Noch eins!", "payload": "Noch eins!", "rarity": "rare", "primary": "ff9f67", "owned_by_default": false},
	"quick_chat.my_ball": {"slot": SLOT_QUICK_CHAT, "name": "Mein Ball!", "payload": "Mein Ball!", "rarity": "rare", "primary": "8ae6ba", "owned_by_default": false},
	"quick_chat.play_wide": {"slot": SLOT_QUICK_CHAT, "name": "Spiel breit!", "payload": "Spiel breit!", "rarity": "rare", "primary": "81d4f5", "owned_by_default": false},
	"quick_chat.switch": {"slot": SLOT_QUICK_CHAT, "name": "Seitenwechsel!", "payload": "Seitenwechsel!", "rarity": "rare", "primary": "c7a0ff", "owned_by_default": false},
	"quick_chat.center_it": {"slot": SLOT_QUICK_CHAT, "name": "In die Mitte!", "payload": "In die Mitte!", "rarity": "rare", "primary": "ffac8d", "owned_by_default": false},
	"quick_chat.hold_line": {"slot": SLOT_QUICK_CHAT, "name": "Linie halten!", "payload": "Linie halten!", "rarity": "epic", "primary": "78c8ff", "owned_by_default": false},
	"quick_chat.counter": {"slot": SLOT_QUICK_CHAT, "name": "Konter!", "payload": "Konter!", "rarity": "epic", "primary": "ff8d64", "owned_by_default": false},
	"quick_chat.clutch": {"slot": SLOT_QUICK_CHAT, "name": "Clutch!", "payload": "Clutch!", "rarity": "epic", "primary": "ffd25d", "owned_by_default": false},
	"quick_chat.game_on": {"slot": SLOT_QUICK_CHAT, "name": "Weiter geht's!", "payload": "Weiter geht's!", "rarity": "legendary", "primary": "65f0a8", "owned_by_default": false},
}

const DEFAULT_SINGLE_LOADOUT: Dictionary = {
	SLOT_PLAYER_SKIN: "player_skin.classic",
	SLOT_FRAME_PALETTE: "frame_palette.classic_touch",
	SLOT_PLAYER_MATERIAL: "player_material.matte",
	SLOT_GOAL_EXPLOSION: "goal_explosion.classic",
	SLOT_GOAL_THEME: "goal_theme.classic",
	SLOT_PLAYER_BANNER: "player_banner.classic",
	SLOT_ABILITY_PARTICLE: "ability_particle.classic",
}

const DEFAULT_QUICK_CHAT_LOADOUT: Array[String] = [
	"quick_chat.nice_shot",
	"quick_chat.great_pass",
	"quick_chat.what_a_save",
	"quick_chat.defending",
	"quick_chat.passing",
	"quick_chat.centering",
	"quick_chat.sorry",
	"quick_chat.gg",
]

var _save_path: String = DEFAULT_SAVE_PATH
var _owned_ids: Dictionary = {}
var _equipped: Dictionary = {}
var _team_equipped: Dictionary = {&"blue": {}, &"red": {}}
var _quick_chat_loadout: Array[String] = []
var _player_subtitle: String = ""
var _team_player_skins_enabled: bool = false
var _show_field_ability_icons: bool = true
var _player_skin_color_index: int = PLAYER_SKIN_ORIGINAL_COLOR
var _team_player_skin_colors: Dictionary = {
	&"blue": PLAYER_SKIN_ORIGINAL_COLOR,
	&"red": PLAYER_SKIN_ORIGINAL_COLOR,
}
var _goal_explosion_color_index: int = PLAYER_SKIN_ORIGINAL_COLOR
var _player_banner_color_index: int = PLAYER_SKIN_ORIGINAL_COLOR
var _team_player_banner_colors: Dictionary = {
	&"blue": PLAYER_SKIN_ORIGINAL_COLOR,
	&"red": PLAYER_SKIN_ORIGINAL_COLOR,
}
var _team_primary_color_indices: Dictionary = {&"blue": 0, &"red": 0}
var _team_player_skins: Dictionary = {
	&"blue": "player_skin.classic",
	&"red": "player_skin.classic",
}


func _ready() -> void:
	if OS.has_environment("THEODORE_RL_V2_HEADLESS"):
		return
	load_profile()


func load_profile(path: String = DEFAULT_SAVE_PATH) -> Error:
	_save_path = path
	_reset_to_defaults()
	var config := ConfigFile.new()
	var load_error: Error = config.load(_save_path)
	if load_error == ERR_FILE_NOT_FOUND:
		return save_profile()
	if load_error != OK:
		push_warning(
			"Cosmetic inventory could not be read; defaults were restored: %s"
			% error_string(load_error)
		)
		return load_error

	var stored_version: int = int(config.get_value("profile", "version", 0))
	if stored_version <= 0 or stored_version > SCHEMA_VERSION:
		push_warning(
			"Unsupported cosmetic inventory version %d; defaults were restored."
			% stored_version
		)
		return ERR_INVALID_DATA

	var stored_owned: Array = config.get_value("inventory", "owned_ids", []) as Array
	for owned_variant: Variant in stored_owned:
		var owned_id: String = str(owned_variant)
		if CATALOG.has(owned_id):
			_owned_ids[owned_id] = true

	for slot: StringName in SINGLE_EQUIP_SLOTS:
		var fallback_id: String = str(DEFAULT_SINGLE_LOADOUT[slot])
		var stored_id: String = str(
			config.get_value("loadout", str(slot), fallback_id)
		)
		_equipped[slot] = (
			stored_id
			if _can_equip(slot, stored_id)
			else fallback_id
		)
	for team: StringName in [&"blue", &"red"]:
		var team_loadout: Dictionary = _team_equipped.get(team, {}) as Dictionary
		for slot: StringName in SINGLE_EQUIP_SLOTS:
			var global_id: String = get_equipped_item_id(slot)
			var key: String = "%s_%s" % [str(slot), str(team)]
			var team_item_id: String = str(config.get_value("loadout", key, global_id))
			team_loadout[slot] = (
				team_item_id if _can_equip(slot, team_item_id) else global_id
			)
		_team_equipped[team] = team_loadout
	_team_player_skins_enabled = bool(
		config.get_value("loadout", "team_player_skins_enabled", false)
	)
	for team: StringName in [&"blue", &"red"]:
		var team_skin_id: String = str(config.get_value(
			"loadout",
			"player_skin_%s" % str(team),
			get_equipped_item_id(SLOT_PLAYER_SKIN)
		))
		_team_player_skins[team] = (
			team_skin_id
			if _can_equip(SLOT_PLAYER_SKIN, team_skin_id)
			else get_equipped_item_id(SLOT_PLAYER_SKIN)
		)
	_goal_explosion_color_index = sanitize_goal_explosion_color_index(
		int(config.get_value(
			"loadout",
			"goal_explosion_color_index",
			PLAYER_SKIN_ORIGINAL_COLOR
		))
	)
	_player_banner_color_index = sanitize_player_banner_color_index(
		int(config.get_value(
			"loadout",
			"player_banner_color_index",
			PLAYER_SKIN_ORIGINAL_COLOR
		))
	)
	for team: StringName in [&"blue", &"red"]:
		_team_player_banner_colors[team] = sanitize_player_banner_color_index(
			int(config.get_value(
				"loadout",
				"player_banner_color_%s" % str(team),
				_player_banner_color_index
			))
		)

	var stored_quick_chat: Array = config.get_value(
		"loadout",
		"quick_chat",
		DEFAULT_QUICK_CHAT_LOADOUT
	) as Array
	_apply_valid_quick_chat_loadout(stored_quick_chat)
	_player_subtitle = sanitize_player_subtitle(
		str(config.get_value("profile", "player_subtitle", ""))
	)
	_show_field_ability_icons = bool(
		config.get_value("visuals", "show_field_ability_icons", true)
	)
	_player_skin_color_index = sanitize_player_skin_color_index(
		int(config.get_value(
			"loadout",
			"player_skin_color_index",
			PLAYER_SKIN_ORIGINAL_COLOR
		))
	)
	for team: StringName in [&"blue", &"red"]:
		_team_player_skin_colors[team] = sanitize_player_skin_color_index(
			int(config.get_value(
				"loadout",
				"player_skin_color_%s" % str(team),
				_player_skin_color_index
			))
		)
		_team_primary_color_indices[team] = sanitize_team_primary_color_index(
			team,
			int(config.get_value(
				"loadout",
				"team_primary_color_%s" % str(team),
				0
			))
		)
	inventory_changed.emit()
	return OK


func save_profile() -> Error:
	var config := ConfigFile.new()
	config.set_value("profile", "version", SCHEMA_VERSION)
	config.set_value("profile", "player_subtitle", _player_subtitle)
	config.set_value(
		"visuals",
		"show_field_ability_icons",
		_show_field_ability_icons
	)
	config.set_value(
		"loadout",
		"goal_explosion_color_index",
		_goal_explosion_color_index
	)
	config.set_value(
		"loadout",
		"player_banner_color_index",
		_player_banner_color_index
	)
	for team: StringName in [&"blue", &"red"]:
		config.set_value(
			"loadout",
			"player_banner_color_%s" % str(team),
			get_player_banner_color_for_team(team)
		)
		config.set_value(
			"loadout",
			"player_skin_color_%s" % str(team),
			get_player_skin_color_for_team(team)
		)
		config.set_value(
			"loadout",
			"team_primary_color_%s" % str(team),
			get_team_primary_color_index(team)
		)
	config.set_value("inventory", "owned_ids", get_owned_ids())
	config.set_value(
		"loadout",
		"player_skin_color_index",
		_player_skin_color_index
	)
	for slot: StringName in SINGLE_EQUIP_SLOTS:
		config.set_value("loadout", str(slot), get_equipped_item_id(slot))
	for team: StringName in [&"blue", &"red"]:
		for slot: StringName in SINGLE_EQUIP_SLOTS:
			config.set_value(
				"loadout",
				"%s_%s" % [str(slot), str(team)],
				get_equipped_item_id_for_team(slot, team)
			)
	config.set_value("loadout", "team_player_skins_enabled", _team_player_skins_enabled)
	for team: StringName in [&"blue", &"red"]:
		config.set_value(
			"loadout",
			"player_skin_%s" % str(team),
			get_player_skin_for_team(team)
		)
	config.set_value("loadout", "quick_chat", get_quick_chat_loadout())
	return config.save(_save_path)


func get_catalog_item(item_id: String) -> Dictionary:
	if not CATALOG.has(item_id):
		return {}
	return (CATALOG[item_id] as Dictionary).duplicate(true)


func get_catalog_items(slot: StringName = &"") -> Array[Dictionary]:
	var items: Array[Dictionary] = []
	for item_id_variant: Variant in CATALOG.keys():
		var item_id: String = str(item_id_variant)
		var item: Dictionary = CATALOG[item_id] as Dictionary
		if not is_catalog_item_obtainable(item):
			continue
		if not slot.is_empty() and item.get("slot", &"") != slot:
			continue
		var result: Dictionary = item.duplicate(true)
		result["id"] = item_id
		result["owned"] = is_owned(item_id)
		items.append(result)
	items.sort_custom(
		func(left: Dictionary, right: Dictionary) -> bool:
			return str(left.get("name", "")) < str(right.get("name", ""))
	)
	return items


func get_owned_ids() -> Array[String]:
	var result: Array[String] = []
	for item_id_variant: Variant in _owned_ids.keys():
		result.append(str(item_id_variant))
	result.sort()
	return result


func is_owned(item_id: String) -> bool:
	return bool(_owned_ids.get(item_id, false))


func unlock_item(item_id: String, persist: bool = true) -> bool:
	if (
		not CATALOG.has(item_id)
		or not is_catalog_item_obtainable(CATALOG[item_id] as Dictionary)
		or is_owned(item_id)
	):
		return false
	_owned_ids[item_id] = true
	if persist:
		save_profile()
	inventory_changed.emit()
	return true


func is_item_equipped_anywhere(item_id: String) -> bool:
	if item_id.is_empty():
		return false
	if _quick_chat_loadout.has(item_id):
		return true
	for equipped_variant: Variant in _equipped.values():
		if str(equipped_variant) == item_id:
			return true
	for team_skin_variant: Variant in _team_player_skins.values():
		if str(team_skin_variant) == item_id:
			return true
	for team_loadout_variant: Variant in _team_equipped.values():
		var team_loadout := team_loadout_variant as Dictionary
		for equipped_variant: Variant in team_loadout.values():
			if str(equipped_variant) == item_id:
				return true
	for team: StringName in [&"blue", &"red"]:
		if get_team_primary_color_item_id(
			team, get_team_primary_color_index(team)
		) == item_id:
			return true
	return false


func get_trade_up_candidates(rarity: String) -> Array[String]:
	var candidates: Array[String] = []
	if _next_rarity(rarity).is_empty():
		return candidates
	for item_id: String in get_owned_ids():
		var item: Dictionary = CATALOG.get(item_id, {}) as Dictionary
		if (
			str(item.get("rarity", "common")) == rarity
			and not bool(item.get("owned_by_default", false))
			and not is_item_equipped_anywhere(item_id)
		):
			candidates.append(item_id)
	return candidates


func can_trade_up(item_ids: Array[String]) -> bool:
	return _validate_trade_up(item_ids).is_empty()


func trade_up(item_ids: Array[String], rng_seed: int = -1) -> Dictionary:
	var error_message: String = _validate_trade_up(item_ids)
	if not error_message.is_empty():
		return {"ok": false, "error": error_message}
	var source_item: Dictionary = CATALOG[item_ids[0]] as Dictionary
	var source_rarity: String = str(source_item.get("rarity", "common"))
	var target_rarity: String = _next_rarity(source_rarity)
	var reward_pool: Array[String] = []
	for item_id_variant: Variant in CATALOG.keys():
		var item_id: String = str(item_id_variant)
		var item: Dictionary = CATALOG[item_id] as Dictionary
		if (
			is_catalog_item_obtainable(item)
			and str(item.get("rarity", "common")) == target_rarity
			and not is_owned(item_id)
		):
			reward_pool.append(item_id)
	if reward_pool.is_empty():
		return {"ok": false, "error": "No unowned %s reward remains." % target_rarity}
	reward_pool.sort()
	var random := RandomNumberGenerator.new()
	if rng_seed >= 0:
		random.seed = rng_seed
	else:
		random.randomize()
	var reward_id: String = reward_pool[random.randi_range(0, reward_pool.size() - 1)]
	for item_id: String in item_ids:
		_owned_ids.erase(item_id)
	_owned_ids[reward_id] = true
	var save_error: Error = save_profile()
	if save_error != OK:
		for item_id: String in item_ids:
			_owned_ids[item_id] = true
		_owned_ids.erase(reward_id)
		return {"ok": false, "error": error_string(save_error)}
	inventory_changed.emit()
	trade_up_completed.emit(item_ids.duplicate(), reward_id)
	return {
		"ok": true,
		"consumed_ids": item_ids.duplicate(),
		"reward_id": reward_id,
		"reward": get_catalog_item(reward_id),
	}


func _validate_trade_up(item_ids: Array[String]) -> String:
	if item_ids.size() != TRADE_UP_ITEM_COUNT:
		return "Select exactly %d cosmetics." % TRADE_UP_ITEM_COUNT
	var used: Dictionary = {}
	var rarity: String = ""
	for item_id: String in item_ids:
		if used.has(item_id):
			return "A cosmetic can only be used once."
		used[item_id] = true
		if not CATALOG.has(item_id) or not is_owned(item_id):
			return "Every traded cosmetic must be owned."
		var item: Dictionary = CATALOG[item_id] as Dictionary
		if bool(item.get("owned_by_default", false)):
			return "Starter cosmetics cannot be traded."
		if is_item_equipped_anywhere(item_id):
			return "Unequip every cosmetic before trading it."
		var item_rarity: String = str(item.get("rarity", "common"))
		if rarity.is_empty():
			rarity = item_rarity
		elif rarity != item_rarity:
			return "All five cosmetics must have the same rarity."
	if _next_rarity(rarity).is_empty():
		return "Legendary cosmetics cannot be traded up."
	return ""


func _next_rarity(rarity: String) -> String:
	var index: int = RARITY_ORDER.find(rarity)
	if index < 0 or index + 1 >= RARITY_ORDER.size():
		return ""
	return RARITY_ORDER[index + 1]


func equip_item(slot: StringName, item_id: String, persist: bool = true) -> bool:
	if not SINGLE_EQUIP_SLOTS.has(slot) or not _can_equip(slot, item_id):
		return false
	if str(_equipped.get(slot, "")) == item_id:
		return true
	_equipped[slot] = item_id
	for team: StringName in [&"blue", &"red"]:
		var team_loadout: Dictionary = _team_equipped.get(team, {}) as Dictionary
		team_loadout[slot] = item_id
		_team_equipped[team] = team_loadout
	if slot == SLOT_PLAYER_SKIN:
		_team_player_skins_enabled = false
	if persist:
		save_profile()
	loadout_changed.emit(slot, item_id)
	return true


func equip_quick_chat(index: int, item_id: String, persist: bool = true) -> bool:
	if (
		index < 0
		or index >= QUICK_CHAT_SLOT_COUNT
		or not _can_equip(SLOT_QUICK_CHAT, item_id)
	):
		return false
	var existing_index: int = _quick_chat_loadout.find(item_id)
	if existing_index >= 0 and existing_index != index:
		# Swapping preserves a complete eight-position wheel while guaranteeing
		# that one message never occupies two directions.
		var displaced_id: String = _quick_chat_loadout[index]
		_quick_chat_loadout[existing_index] = displaced_id
	_quick_chat_loadout[index] = item_id
	if persist:
		save_profile()
	loadout_changed.emit(SLOT_QUICK_CHAT, item_id)
	return true


func get_equipped_item_id(slot: StringName) -> String:
	return str(_equipped.get(slot, DEFAULT_SINGLE_LOADOUT.get(slot, "")))


func get_equipped_item_id_for_team(slot: StringName, team: StringName) -> String:
	if team not in [&"blue", &"red"]:
		return get_equipped_item_id(slot)
	if slot == SLOT_PLAYER_SKIN:
		return get_player_skin_for_team(team)
	var team_loadout: Dictionary = _team_equipped.get(team, {}) as Dictionary
	return str(team_loadout.get(slot, get_equipped_item_id(slot)))


func equip_item_for_team(
	slot: StringName,
	team: StringName,
	item_id: String,
	persist: bool = true
) -> bool:
	if (
		not SINGLE_EQUIP_SLOTS.has(slot)
		or team not in [&"blue", &"red"]
		or not _can_equip(slot, item_id)
	):
		return false
	if slot == SLOT_PLAYER_SKIN:
		return equip_player_skin_for_team(team, item_id, persist)
	var team_loadout: Dictionary = _team_equipped.get(team, {}) as Dictionary
	team_loadout[slot] = item_id
	_team_equipped[team] = team_loadout
	if persist:
		save_profile()
	loadout_changed.emit(slot, item_id)
	return true


func are_team_player_skins_enabled() -> bool:
	return _team_player_skins_enabled


func set_team_player_skins_enabled(enabled: bool, persist: bool = true) -> bool:
	if _team_player_skins_enabled == enabled:
		return true
	_team_player_skins_enabled = enabled
	if persist:
		save_profile()
	loadout_changed.emit(SLOT_PLAYER_SKIN, get_equipped_item_id(SLOT_PLAYER_SKIN))
	return true


func get_player_skin_for_team(team: StringName) -> String:
	if not _team_player_skins_enabled or team not in [&"blue", &"red"]:
		return get_equipped_item_id(SLOT_PLAYER_SKIN)
	return str(_team_player_skins.get(team, get_equipped_item_id(SLOT_PLAYER_SKIN)))


func equip_player_skin_for_team(
	team: StringName,
	item_id: String,
	persist: bool = true
) -> bool:
	if team not in [&"blue", &"red"] or not _can_equip(SLOT_PLAYER_SKIN, item_id):
		return false
	_team_player_skins_enabled = true
	_team_player_skins[team] = item_id
	var team_loadout: Dictionary = _team_equipped.get(team, {}) as Dictionary
	team_loadout[SLOT_PLAYER_SKIN] = item_id
	_team_equipped[team] = team_loadout
	if persist:
		save_profile()
	loadout_changed.emit(SLOT_PLAYER_SKIN, item_id)
	return true


func get_quick_chat_loadout() -> Array[String]:
	return _quick_chat_loadout.duplicate()


func get_quick_chat_payloads() -> Array[String]:
	var payloads: Array[String] = []
	for item_id: String in _quick_chat_loadout:
		var item: Dictionary = CATALOG.get(item_id, {}) as Dictionary
		payloads.append(str(item.get("payload", "")))
	return payloads


func get_player_subtitle() -> String:
	return _player_subtitle


func set_player_subtitle(value: String, persist: bool = true) -> bool:
	var sanitized: String = sanitize_player_subtitle(value)
	if sanitized == _player_subtitle:
		return true
	_player_subtitle = sanitized
	if persist:
		save_profile()
	loadout_changed.emit(SLOT_PLAYER_SUBTITLE, sanitized)
	return true


func get_show_field_ability_icons() -> bool:
	return _show_field_ability_icons


func get_player_skin_color_index() -> int:
	return _player_skin_color_index


func set_player_skin_color_index(index: int, persist: bool = true) -> bool:
	var sanitized_index: int = sanitize_player_skin_color_index(index)
	if (
		sanitized_index == _player_skin_color_index
		and get_player_skin_color_for_team(&"blue") == sanitized_index
		and get_player_skin_color_for_team(&"red") == sanitized_index
	):
		return true
	_player_skin_color_index = sanitized_index
	_team_player_skin_colors[&"blue"] = sanitized_index
	_team_player_skin_colors[&"red"] = sanitized_index
	if persist:
		save_profile()
	loadout_changed.emit(
		SLOT_PLAYER_SKIN_COLOR,
		str(_player_skin_color_index)
	)
	return true


func get_player_skin_color_for_team(team: StringName) -> int:
	if team not in [&"blue", &"red"]:
		return _player_skin_color_index
	return sanitize_player_skin_color_index(
		int(_team_player_skin_colors.get(team, _player_skin_color_index))
	)


func set_player_skin_color_for_team(
	team: StringName,
	index: int,
	persist: bool = true
) -> bool:
	if team not in [&"blue", &"red"]:
		return false
	var sanitized_index: int = sanitize_player_skin_color_index(index)
	if get_player_skin_color_for_team(team) == sanitized_index:
		return true
	_team_player_skin_colors[team] = sanitized_index
	var blue_index: int = get_player_skin_color_for_team(&"blue")
	var red_index: int = get_player_skin_color_for_team(&"red")
	if blue_index == red_index:
		_player_skin_color_index = blue_index
	if persist:
		save_profile()
	loadout_changed.emit(SLOT_PLAYER_SKIN_COLOR, str(sanitized_index))
	return true


static func sanitize_player_skin_color_index(index: int) -> int:
	return (
		index
		if index >= 0 and index < PLAYER_SKIN_COLORS.size()
		else PLAYER_SKIN_ORIGINAL_COLOR
	)


static func apply_player_skin_color(
	_item_id: String,
	item: Dictionary,
	color_index: int
) -> Dictionary:
	var result: Dictionary = item.duplicate(true)
	var safe_index: int = sanitize_player_skin_color_index(color_index)
	if safe_index < 0:
		return result
	var palette: Dictionary = PLAYER_SKIN_COLORS[safe_index]
	result["primary"] = str(palette["primary"])
	result["secondary"] = str(palette["secondary"])
	return result


func get_team_primary_color_index(team: StringName) -> int:
	var safe_team: StringName = team if team in [&"blue", &"red"] else &"blue"
	return int(_team_primary_color_indices.get(safe_team, 0))


func set_team_primary_color_index(
	team: StringName,
	index: int,
	persist: bool = true
) -> bool:
	if team not in [&"blue", &"red"]:
		return false
	var safe_index: int = sanitize_team_primary_color_index(team, index)
	var color_item_id: String = get_team_primary_color_item_id(team, safe_index)
	if not is_owned(color_item_id):
		return false
	if get_team_primary_color_index(team) == safe_index:
		return true
	_team_primary_color_indices[team] = safe_index
	if persist:
		save_profile()
	loadout_changed.emit(SLOT_TEAM_PRIMARY_COLOR, "%s:%d" % [str(team), safe_index])
	return true


func get_team_primary_color(team: StringName) -> Color:
	return get_team_primary_color_from_index(team, get_team_primary_color_index(team))


static func sanitize_team_primary_color_index(team: StringName, index: int) -> int:
	var palette: Array[Dictionary] = BLUE_TEAM_COLORS if team == &"blue" else RED_TEAM_COLORS
	return clampi(index, 0, palette.size() - 1)


static func get_team_primary_color_from_index(team: StringName, index: int) -> Color:
	var safe_team: StringName = team if team in [&"blue", &"red"] else &"blue"
	var palette: Array[Dictionary] = BLUE_TEAM_COLORS if safe_team == &"blue" else RED_TEAM_COLORS
	var safe_index: int = sanitize_team_primary_color_index(safe_team, index)
	return Color(str(palette[safe_index]["color"]))


static func get_team_primary_color_item_id(team: StringName, index: int) -> String:
	var safe_team: StringName = team if team in [&"blue", &"red"] else &"blue"
	var palette: Array[Dictionary] = BLUE_TEAM_COLORS if safe_team == &"blue" else RED_TEAM_COLORS
	var safe_index: int = sanitize_team_primary_color_index(safe_team, index)
	return str(palette[safe_index]["id"])


static func apply_player_skin_team_profile(
	palette_item_id: String,
	item: Dictionary,
	team: StringName
) -> Dictionary:
	var result: Dictionary = item.duplicate(true)
	var safe_team: StringName = team if team in [&"blue", &"red"] else &"blue"
	var palette: Dictionary = CATALOG.get(
		palette_item_id,
		CATALOG["frame_palette.classic_touch"]
	) as Dictionary
	if palette.get("slot", &"") != SLOT_FRAME_PALETTE:
		palette = CATALOG["frame_palette.classic_touch"] as Dictionary
	var colors: Array = palette.get(str(safe_team), []) as Array
	if colors.size() < 3:
		return result
	var chosen_primary: Color = _valid_catalog_color(
		result, "primary", Color("71869d")
	)
	var chosen_secondary: Color = _valid_catalog_color(
		result, "secondary", Color.WHITE
	)
	var profile_accent := Color(str(colors[0]))
	var profile_highlight := Color(str(colors[1]))
	result["frame_primary"] = profile_accent.lerp(chosen_primary, 0.28).to_html()
	result["frame_secondary"] = profile_highlight.lerp(
		chosen_secondary, 0.18
	).to_html()
	result["team_glow"] = str(colors[2])
	return result


static func _valid_catalog_color(
	item: Dictionary,
	key: String,
	fallback: Color
) -> Color:
	var html: String = str(item.get(key, ""))
	return Color(html) if Color.html_is_valid(html) else fallback


func get_goal_explosion_color_index() -> int:
	return _goal_explosion_color_index


func set_goal_explosion_color_index(
	index: int,
	persist: bool = true
) -> bool:
	var sanitized_index: int = sanitize_goal_explosion_color_index(index)
	if sanitized_index == _goal_explosion_color_index:
		return true
	_goal_explosion_color_index = sanitized_index
	if persist:
		save_profile()
	loadout_changed.emit(
		SLOT_GOAL_EXPLOSION_COLOR,
		str(_goal_explosion_color_index)
	)
	return true


static func sanitize_goal_explosion_color_index(index: int) -> int:
	return (
		index
		if index >= 0 and index < GOAL_EXPLOSION_COLORS.size()
		else PLAYER_SKIN_ORIGINAL_COLOR
	)


static func apply_goal_explosion_color(
	item: Dictionary,
	color_index: int
) -> Dictionary:
	var result: Dictionary = item.duplicate(true)
	var safe_index: int = sanitize_goal_explosion_color_index(color_index)
	if safe_index < 0:
		return result
	var palette: Dictionary = GOAL_EXPLOSION_COLORS[safe_index]
	result["primary"] = str(palette["primary"])
	result["secondary"] = str(palette["secondary"])
	result["custom_color"] = true
	return result


func get_player_banner_color_index() -> int:
	return _player_banner_color_index


func set_player_banner_color_index(index: int, persist: bool = true) -> bool:
	var safe_index: int = sanitize_player_banner_color_index(index)
	if (
		safe_index == _player_banner_color_index
		and get_player_banner_color_for_team(&"blue") == safe_index
		and get_player_banner_color_for_team(&"red") == safe_index
	):
		return true
	_player_banner_color_index = safe_index
	_team_player_banner_colors[&"blue"] = safe_index
	_team_player_banner_colors[&"red"] = safe_index
	if persist:
		save_profile()
	loadout_changed.emit(SLOT_PLAYER_BANNER_COLOR, str(safe_index))
	return true


func get_player_banner_color_for_team(team: StringName) -> int:
	if team not in [&"blue", &"red"]:
		return _player_banner_color_index
	return sanitize_player_banner_color_index(
		int(_team_player_banner_colors.get(team, _player_banner_color_index))
	)


func set_player_banner_color_for_team(
	team: StringName,
	index: int,
	persist: bool = true
) -> bool:
	if team not in [&"blue", &"red"]:
		return false
	var safe_index: int = sanitize_player_banner_color_index(index)
	if get_player_banner_color_for_team(team) == safe_index:
		return true
	_team_player_banner_colors[team] = safe_index
	var blue_index: int = get_player_banner_color_for_team(&"blue")
	var red_index: int = get_player_banner_color_for_team(&"red")
	if blue_index == red_index:
		_player_banner_color_index = blue_index
	if persist:
		save_profile()
	loadout_changed.emit(SLOT_PLAYER_BANNER_COLOR, str(safe_index))
	return true


static func sanitize_player_banner_color_index(index: int) -> int:
	return (
		index
		if index >= 0 and index < PLAYER_BANNER_COLORS.size()
		else PLAYER_SKIN_ORIGINAL_COLOR
	)


static func apply_player_banner_color(
	item: Dictionary,
	color_index: int
) -> Dictionary:
	var result: Dictionary = item.duplicate(true)
	var safe_index: int = sanitize_player_banner_color_index(color_index)
	if safe_index < 0:
		return result
	var palette: Dictionary = PLAYER_BANNER_COLORS[safe_index]
	result["primary"] = str(palette["primary"])
	result["secondary"] = str(palette["secondary"])
	result["image_tint"] = str(palette["primary"])
	result["custom_color"] = true
	return result


func set_show_field_ability_icons(
	enabled: bool,
	persist: bool = true
) -> bool:
	if _show_field_ability_icons == enabled:
		return true
	_show_field_ability_icons = enabled
	if persist:
		save_profile()
	visual_preferences_changed.emit()
	return true


func get_network_loadout() -> Dictionary:
	var battle_pass := get_node_or_null("/root/BattlePass") as FootballBattlePass
	var battle_pass_complete: bool = (
		battle_pass != null
		and battle_pass.get_level() >= battle_pass.get_max_level()
	)
	return {
		"version": SCHEMA_VERSION,
		"battle_pass_complete": battle_pass_complete,
		"player_skin": get_equipped_item_id(SLOT_PLAYER_SKIN),
		"frame_palette": get_equipped_item_id(SLOT_FRAME_PALETTE),
		"frame_palette_blue": get_equipped_item_id_for_team(SLOT_FRAME_PALETTE, &"blue"),
		"frame_palette_red": get_equipped_item_id_for_team(SLOT_FRAME_PALETTE, &"red"),
		"player_material": get_equipped_item_id(SLOT_PLAYER_MATERIAL),
		"player_material_blue": get_equipped_item_id_for_team(SLOT_PLAYER_MATERIAL, &"blue"),
		"player_material_red": get_equipped_item_id_for_team(SLOT_PLAYER_MATERIAL, &"red"),
		"team_player_skins_enabled": _team_player_skins_enabled,
		"player_skin_blue": get_player_skin_for_team(&"blue"),
		"player_skin_red": get_player_skin_for_team(&"red"),
		"player_skin_color_index": _player_skin_color_index,
		"player_skin_color_blue": get_player_skin_color_for_team(&"blue"),
		"player_skin_color_red": get_player_skin_color_for_team(&"red"),
		"team_primary_color_blue": get_team_primary_color_index(&"blue"),
		"team_primary_color_red": get_team_primary_color_index(&"red"),
		"special_team_color_override": "",
		"goal_explosion": get_equipped_item_id(SLOT_GOAL_EXPLOSION),
		"goal_explosion_blue": get_equipped_item_id_for_team(SLOT_GOAL_EXPLOSION, &"blue"),
		"goal_explosion_red": get_equipped_item_id_for_team(SLOT_GOAL_EXPLOSION, &"red"),
		"goal_explosion_color_index": _goal_explosion_color_index,
		"goal_theme": get_equipped_item_id(SLOT_GOAL_THEME),
		"goal_theme_blue": get_equipped_item_id_for_team(SLOT_GOAL_THEME, &"blue"),
		"goal_theme_red": get_equipped_item_id_for_team(SLOT_GOAL_THEME, &"red"),
		"player_banner": get_equipped_item_id(SLOT_PLAYER_BANNER),
		"player_banner_blue": get_equipped_item_id_for_team(SLOT_PLAYER_BANNER, &"blue"),
		"player_banner_red": get_equipped_item_id_for_team(SLOT_PLAYER_BANNER, &"red"),
		"player_banner_color_index": _player_banner_color_index,
		"player_banner_color_blue": get_player_banner_color_for_team(&"blue"),
		"player_banner_color_red": get_player_banner_color_for_team(&"red"),
		"ability_particle": get_equipped_item_id(SLOT_ABILITY_PARTICLE),
		"ability_particle_blue": get_equipped_item_id_for_team(SLOT_ABILITY_PARTICLE, &"blue"),
		"ability_particle_red": get_equipped_item_id_for_team(SLOT_ABILITY_PARTICLE, &"red"),
		"player_subtitle": _player_subtitle,
		"quick_chat": get_quick_chat_loadout(),
	}


func sanitize_network_loadout(payload: Dictionary) -> Dictionary:
	return sanitize_catalog_network_loadout(payload)


static func get_default_network_loadout() -> Dictionary:
	return {
		"version": SCHEMA_VERSION,
		"battle_pass_complete": false,
		"player_skin": str(DEFAULT_SINGLE_LOADOUT[SLOT_PLAYER_SKIN]),
		"frame_palette": str(DEFAULT_SINGLE_LOADOUT[SLOT_FRAME_PALETTE]),
		"frame_palette_blue": str(DEFAULT_SINGLE_LOADOUT[SLOT_FRAME_PALETTE]),
		"frame_palette_red": str(DEFAULT_SINGLE_LOADOUT[SLOT_FRAME_PALETTE]),
		"player_material": str(DEFAULT_SINGLE_LOADOUT[SLOT_PLAYER_MATERIAL]),
		"player_material_blue": str(DEFAULT_SINGLE_LOADOUT[SLOT_PLAYER_MATERIAL]),
		"player_material_red": str(DEFAULT_SINGLE_LOADOUT[SLOT_PLAYER_MATERIAL]),
		"team_player_skins_enabled": false,
		"player_skin_blue": str(DEFAULT_SINGLE_LOADOUT[SLOT_PLAYER_SKIN]),
		"player_skin_red": str(DEFAULT_SINGLE_LOADOUT[SLOT_PLAYER_SKIN]),
		"player_skin_color_index": PLAYER_SKIN_ORIGINAL_COLOR,
		"player_skin_color_blue": PLAYER_SKIN_ORIGINAL_COLOR,
		"player_skin_color_red": PLAYER_SKIN_ORIGINAL_COLOR,
		"team_primary_color_blue": 0,
		"team_primary_color_red": 0,
		"special_team_color_override": "",
		"goal_explosion": str(DEFAULT_SINGLE_LOADOUT[SLOT_GOAL_EXPLOSION]),
		"goal_explosion_blue": str(DEFAULT_SINGLE_LOADOUT[SLOT_GOAL_EXPLOSION]),
		"goal_explosion_red": str(DEFAULT_SINGLE_LOADOUT[SLOT_GOAL_EXPLOSION]),
		"goal_explosion_color_index": PLAYER_SKIN_ORIGINAL_COLOR,
		"goal_theme": str(DEFAULT_SINGLE_LOADOUT[SLOT_GOAL_THEME]),
		"goal_theme_blue": str(DEFAULT_SINGLE_LOADOUT[SLOT_GOAL_THEME]),
		"goal_theme_red": str(DEFAULT_SINGLE_LOADOUT[SLOT_GOAL_THEME]),
		"player_banner": str(DEFAULT_SINGLE_LOADOUT[SLOT_PLAYER_BANNER]),
		"player_banner_blue": str(DEFAULT_SINGLE_LOADOUT[SLOT_PLAYER_BANNER]),
		"player_banner_red": str(DEFAULT_SINGLE_LOADOUT[SLOT_PLAYER_BANNER]),
		"player_banner_color_index": PLAYER_SKIN_ORIGINAL_COLOR,
		"player_banner_color_blue": PLAYER_SKIN_ORIGINAL_COLOR,
		"player_banner_color_red": PLAYER_SKIN_ORIGINAL_COLOR,
		"ability_particle": str(DEFAULT_SINGLE_LOADOUT[SLOT_ABILITY_PARTICLE]),
		"ability_particle_blue": str(DEFAULT_SINGLE_LOADOUT[SLOT_ABILITY_PARTICLE]),
		"ability_particle_red": str(DEFAULT_SINGLE_LOADOUT[SLOT_ABILITY_PARTICLE]),
		"player_subtitle": "",
		"quick_chat": DEFAULT_QUICK_CHAT_LOADOUT.duplicate(),
	}


static func get_quick_chat_payload(item_id: String) -> String:
	if not _catalog_item_matches_slot(SLOT_QUICK_CHAT, item_id):
		return ""
	var item: Dictionary = CATALOG[item_id] as Dictionary
	return str(item.get("payload", ""))


static func sanitize_player_subtitle(value: String) -> String:
	var sanitized: String = value.strip_edges()
	sanitized = sanitized.replace("\r", " ").replace("\n", " ").replace("\t", " ")
	while sanitized.contains("  "):
		sanitized = sanitized.replace("  ", " ")
	return sanitized.left(PLAYER_SUBTITLE_MAX_LENGTH)


static func sanitize_catalog_network_loadout(payload: Dictionary) -> Dictionary:
	var sanitized: Dictionary = {
		"version": SCHEMA_VERSION,
		"battle_pass_complete": bool(
			payload.get("battle_pass_complete", false)
		),
		# Non-cosmetic prestige metadata that must survive the same network
		# sanitation path used by FootballPlayer.cosmetic_loadout.
		"pve_ladder_champion": bool(
			payload.get("pve_ladder_champion", false)
		),
	}
	for slot: StringName in SINGLE_EQUIP_SLOTS:
		var fallback_id: String = str(DEFAULT_SINGLE_LOADOUT[slot])
		var item_id: String = str(payload.get(str(slot), fallback_id))
		sanitized[str(slot)] = (
			item_id
			if _catalog_item_matches_slot(slot, item_id)
			else fallback_id
		)
		for team: StringName in [&"blue", &"red"]:
			var slot_team_key: String = "%s_%s" % [str(slot), str(team)]
			var slot_team_item_id: String = str(payload.get(slot_team_key, sanitized[str(slot)]))
			sanitized[slot_team_key] = (
				slot_team_item_id
				if _catalog_item_matches_slot(slot, slot_team_item_id)
				else sanitized[str(slot)]
			)
	var base_player_skin: String = str(sanitized["player_skin"])
	sanitized["player_skin_color_index"] = sanitize_player_skin_color_index(
		int(payload.get(
			"player_skin_color_index",
			PLAYER_SKIN_ORIGINAL_COLOR
		))
	)
	for team: StringName in [&"blue", &"red"]:
		var color_key: String = "player_skin_color_%s" % str(team)
		sanitized[color_key] = sanitize_player_skin_color_index(
			int(payload.get(color_key, sanitized["player_skin_color_index"]))
		)
	var banner_color_index: int = sanitize_player_banner_color_index(
		int(payload.get("player_banner_color_index", PLAYER_SKIN_ORIGINAL_COLOR))
	)
	sanitized["player_banner_color_index"] = banner_color_index
	for team: StringName in [&"blue", &"red"]:
		var banner_color_key: String = "player_banner_color_%s" % str(team)
		sanitized[banner_color_key] = sanitize_player_banner_color_index(
			int(payload.get(banner_color_key, banner_color_index))
		)
		var primary_key: String = "team_primary_color_%s" % str(team)
		sanitized[primary_key] = sanitize_team_primary_color_index(
			team,
			int(payload.get(primary_key, 0))
		)
	var requested_team_color_override: String = str(
		payload.get("special_team_color_override", "")
	).to_lower()
	if (
		requested_team_color_override == DICTATOR_TEAM_COLOR_OVERRIDE
		and str(sanitized.get("player_banner", "")) == "player_banner.dictator"
	):
		sanitized["special_team_color_override"] = DICTATOR_TEAM_COLOR_OVERRIDE
	elif (
		requested_team_color_override == GOJO_TEAM_COLOR_OVERRIDE
		and str(sanitized.get("player_banner", "")) == "player_banner.gojo"
	):
		sanitized["special_team_color_override"] = GOJO_TEAM_COLOR_OVERRIDE
	elif (
		requested_team_color_override == NEYMAR_TEAM_COLOR_OVERRIDE
		and str(sanitized.get("player_skin", "")) == "player_skin.brazilian_prince_10"
	):
		sanitized["special_team_color_override"] = NEYMAR_TEAM_COLOR_OVERRIDE
	elif (
		requested_team_color_override == HAALAND_TEAM_COLOR_OVERRIDE
		and str(sanitized.get("player_skin", "")) == "player_skin.nordic_terminator_9"
	):
		sanitized["special_team_color_override"] = HAALAND_TEAM_COLOR_OVERRIDE
	else:
		sanitized["special_team_color_override"] = ""
	sanitized["goal_explosion_color_index"] = sanitize_goal_explosion_color_index(
		int(payload.get(
			"goal_explosion_color_index",
			PLAYER_SKIN_ORIGINAL_COLOR
		))
	)
	sanitized["team_player_skins_enabled"] = bool(
		payload.get("team_player_skins_enabled", false)
	)
	for team: StringName in [&"blue", &"red"]:
		var team_key: String = "player_skin_%s" % str(team)
		var team_skin_id: String = str(payload.get(team_key, base_player_skin))
		sanitized[team_key] = (
			team_skin_id
			if _catalog_item_matches_slot(SLOT_PLAYER_SKIN, team_skin_id)
			else base_player_skin
		)
	sanitized["player_subtitle"] = sanitize_player_subtitle(
		str(payload.get("player_subtitle", ""))
	)
	var quick_chat: Array[String] = []
	var used_quick_chat: Dictionary = {}
	var supplied_quick_chat: Array = payload.get("quick_chat", []) as Array
	for index: int in range(QUICK_CHAT_SLOT_COUNT):
		var fallback_id: String = DEFAULT_QUICK_CHAT_LOADOUT[index]
		var item_id: String = (
			str(supplied_quick_chat[index])
			if index < supplied_quick_chat.size()
			else fallback_id
		)
		var safe_item_id: String = (
			item_id
			if _catalog_item_matches_slot(SLOT_QUICK_CHAT, item_id)
			else fallback_id
		)
		if used_quick_chat.has(safe_item_id):
			safe_item_id = _first_unused_default_quick_chat(used_quick_chat, index)
		quick_chat.append(safe_item_id)
		used_quick_chat[safe_item_id] = true
	sanitized["quick_chat"] = quick_chat
	return sanitized


func _reset_to_defaults() -> void:
	_owned_ids.clear()
	for item_id_variant: Variant in CATALOG.keys():
		var item_id: String = str(item_id_variant)
		var item: Dictionary = CATALOG[item_id] as Dictionary
		if bool(item.get("owned_by_default", false)):
			_owned_ids[item_id] = true
	_equipped = DEFAULT_SINGLE_LOADOUT.duplicate(true)
	_team_equipped = {
		&"blue": DEFAULT_SINGLE_LOADOUT.duplicate(true),
		&"red": DEFAULT_SINGLE_LOADOUT.duplicate(true),
	}
	_quick_chat_loadout = DEFAULT_QUICK_CHAT_LOADOUT.duplicate()
	_player_subtitle = ""
	_show_field_ability_icons = true
	_player_skin_color_index = PLAYER_SKIN_ORIGINAL_COLOR
	_team_player_skin_colors = {
		&"blue": PLAYER_SKIN_ORIGINAL_COLOR,
		&"red": PLAYER_SKIN_ORIGINAL_COLOR,
	}
	_team_primary_color_indices = {&"blue": 0, &"red": 0}
	_goal_explosion_color_index = PLAYER_SKIN_ORIGINAL_COLOR
	_player_banner_color_index = PLAYER_SKIN_ORIGINAL_COLOR
	_team_player_banner_colors = {
		&"blue": PLAYER_SKIN_ORIGINAL_COLOR,
		&"red": PLAYER_SKIN_ORIGINAL_COLOR,
	}
	_team_player_skins_enabled = false
	_team_player_skins = {
		&"blue": str(DEFAULT_SINGLE_LOADOUT[SLOT_PLAYER_SKIN]),
		&"red": str(DEFAULT_SINGLE_LOADOUT[SLOT_PLAYER_SKIN]),
	}


func _apply_valid_quick_chat_loadout(stored: Array) -> void:
	_quick_chat_loadout.clear()
	var used: Dictionary = {}
	for index: int in range(QUICK_CHAT_SLOT_COUNT):
		var fallback_id: String = DEFAULT_QUICK_CHAT_LOADOUT[index]
		var item_id: String = str(stored[index]) if index < stored.size() else fallback_id
		var safe_item_id: String = (
			item_id
			if _can_equip(SLOT_QUICK_CHAT, item_id)
			else fallback_id
		)
		if used.has(safe_item_id):
			safe_item_id = _first_unused_owned_quick_chat(used, index)
		_quick_chat_loadout.append(safe_item_id)
		used[safe_item_id] = true


func _first_unused_owned_quick_chat(used: Dictionary, preferred_index: int) -> String:
	var fallback_id: String = DEFAULT_QUICK_CHAT_LOADOUT[preferred_index]
	if _can_equip(SLOT_QUICK_CHAT, fallback_id) and not used.has(fallback_id):
		return fallback_id
	for item_id_variant: Variant in CATALOG.keys():
		var item_id: String = str(item_id_variant)
		if _can_equip(SLOT_QUICK_CHAT, item_id) and not used.has(item_id):
			return item_id
	return fallback_id


static func _first_unused_default_quick_chat(used: Dictionary, preferred_index: int) -> String:
	var preferred: String = DEFAULT_QUICK_CHAT_LOADOUT[preferred_index]
	if not used.has(preferred):
		return preferred
	for item_id: String in DEFAULT_QUICK_CHAT_LOADOUT:
		if not used.has(item_id):
			return item_id
	return preferred


func _can_equip(slot: StringName, item_id: String) -> bool:
	return is_owned(item_id) and _catalog_item_matches_slot(slot, item_id)


static func _catalog_item_matches_slot(slot: StringName, item_id: String) -> bool:
	if not CATALOG.has(item_id):
		return false
	var item: Dictionary = CATALOG[item_id] as Dictionary
	return item.get("slot", &"") == slot


static func is_catalog_item_obtainable(item: Dictionary) -> bool:
	return bool(item.get("obtainable", true))
