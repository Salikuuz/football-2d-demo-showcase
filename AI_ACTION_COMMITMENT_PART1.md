# AI Action Commitment - Part 1

## What changed

The live CPU AI now exposes one high-level action commitment alongside the existing tactical intent system:

`NONE`, `GET_BALL`, `ATTACK`, `PASS`, `SHOOT`, `SUPPORT`, `DEFEND`, `GOALKEEP`, `ABILITY`, `KICKOFF`.

This reuses the existing `CPUPlayerAI` tactical-intent path rather than adding another parallel brain. Every published tactical intent is translated into one high-level action and recorded with:

- action
- live target
- target peer ID
- source tactical intent
- start time
- minimum commitment window
- revision number
- last interrupt reason

A target may move without restarting the commitment. Switching action or switching a pass receiver creates a new commitment. Kickoff internals are intentionally represented as one `KICKOFF` action.

## Important Part 1 safety rule

The commitment layer is observational only in Part 1. `execution_authority` remains `legacy` and no tactical branch is blocked by commitment timing yet. This means the architecture can be tested before it changes match behavior.

`get_action_commitment_debug_state()` exposes the state for tests/debugging.

## Current live control-flow audit

The authoritative live AI is still `Scenes/cpu_player_ai.gd`.

Per physics tick, the important order is:

1. first-touch awareness/execution
2. active shot/pass charge update
3. high-tempo attack reflex
4. fast follow-up finish
5. timed tactical decision
6. first-touch movement override
7. generic movement application

Inside the normal tactical decision, priority currently flows through:

1. competitive kickoff
2. Return Tag return
3. penalty logic
4. relative loose-ball claim
5. duel resolution
6. active 1v1 space play
7. active wall-dribble break
8. core defense / goalkeeper priority
9. AI V2 proposal when allowed
10. human-demonstration proposal
11. normal goalkeeper or outfield planner
12. pass-request consideration
13. ability consideration

This confirms the main architectural problem: the tactical decision is not the only place that can influence execution.

## Existing input writers that can compete

The generic final movement writer is `_apply_movement_input()`, which converts `_movement_target` into `server_direction`.

There are also direct `server_direction` writers outside that path, especially in:

- goalkeeper Power Strike distribution
- `_activate_planned_ball_ability()`
- `_update_overdrive_dead_zone_runner()`
- `_prepare_ability_direction()`
- `_try_execute_return_tag_return()`
- human-mistake/hesitation handling
- stop/disable handling

Shot execution is already partially centralized: `_try_begin_shot()` starts charge and `_update_charge()` follows the live ball, validates contact, validates the final lane and releases/cancels the kick. Part 2 should reuse this instead of inventing a second shooting system.

## Part 2 target

Make `SHOOT` the first action that actually owns execution for a short commitment window.

The intended migration path is:

`shot evaluator -> SHOOT commitment -> existing shot plan/charge executor -> movement/input`

During an active `SHOOT`, ordinary outfield positioning, generic ball chasing and unrelated tactical replanning should not replace the shot. Only explicit hard interrupts should be allowed to break it.

This lets us validate the architecture on one action before moving PASS, GET_BALL, defense, kickoff and abilities behind the same authority layer.
