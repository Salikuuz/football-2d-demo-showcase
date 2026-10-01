# Cosmetic inventory foundation

The `CosmeticInventory` autoload owns the local cosmetic catalog, unlocked
item IDs, and equipped loadout. The Locker edits that loadout. Player skins,
goal explosions, and quick-chat selections now resolve from validated IDs and
replicate through the existing authoritative player/network path. Banner IDs
are synchronized now and will be displayed by the later goal-card pass.

## Current slots

- `player_skin`
- `goal_explosion`
- `player_banner`
- eight `quick_chat` entries, including future emoji entries

## Editing quick chats

All selectable quick-chat definitions live in the `CATALOG` dictionary in
`Scenes/cosmetic_inventory.gd`. Entries whose IDs begin with `quick_chat.` use:

- `name`: the label shown in the Locker;
- `payload`: the text or emoji shown beside the player;
- `owned_by_default`: whether a fresh profile owns it immediately.

`DEFAULT_QUICK_CHAT_LOADOUT` in that same file controls the eight messages and
their order on a fresh player's wheel. Keep every catalog ID unique and keep
the default list at exactly eight entries. The older `quick_chat_messages`
array in `match_manager.gd` is only a compatibility fallback when a player has
no cosmetic loadout; normal play resolves the equipped catalog entries.

Saved and network-facing values are stable catalog IDs. They never contain
resource paths supplied by another client. The local profile is suitable for
development, but paid ownership must eventually be validated by Steam or an
authoritative backend rather than trusted from this editable local file.

## Locker assignment

Quick chats are assigned through the same eight-direction layout used during
a match. Selecting a reward and pressing `Place on Wheel` opens that layout;
choosing a direction moves the message there. If the message already occupies
another direction, the two positions swap, so duplicate entries cannot appear.

Player finishes default to one shared `Both` selection for backward
compatibility. Selecting `Blue` or `Red` enables independent team finishes.
These IDs are validated and replicated as part of the existing cosmetic
loadout, and the player resolves the correct finish after its team assignment.

## Goal-replay presentation

The scorer's equipped banner is displayed in a bottom-center goal card during
the replay. Players can edit a separately validated, single-line subtitle from
the Locker's Banner category. The skip vote is a compact bottom-right control,
and a replay-only vignette frames the action without blocking input or play.
Banner/subtitle content remains separate from stored player names and chat.

## First Touch Pass

The main menu Battle Pass awards local season XP once per completed match.
Goals, saves, passes, and winning add modest bonuses on top of participation.
Unlocked tiers are claimed into the same `CosmeticInventory` used by the
Locker; the pass does not maintain a duplicate ownership list. Season 01 has
50 horizontal tiers arranged as five ten-tier pages. Every tier grants a real
catalog item: a player finish, goal explosion, scorer banner, or quick chat.
The old eight-tier preseason XP migrates forward, while its claimed tier flags
do not suppress the replacement rewards. This local profile remains a
development progression system, not a secure store or paid entitlement
backend.

Battle Pass reward order lives in `Scenes/battle_pass.gd`. Cosmetic names,
rarity, colors, patterns, and quick-chat payloads live in the `CATALOG` in
`Scenes/cosmetic_inventory.gd`. New catalog entries can therefore be restyled
without changing the player save IDs or tier progression.
