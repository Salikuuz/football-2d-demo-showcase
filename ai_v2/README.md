# Theodore Ball AI V2 — Part 1 contract

This folder defines the Deep-RL observation/action contract only. It does not control players and does not replace the current CPU AI.

## Observation contract

All agents see the field in a canonical frame where their own goal is on the left and attack is toward positive X. Red-team states are mirrored on X before entering the policy.

Entity slots are stable by `team_slot`, then `owner_peer_id`. A teammate does not change slots because somebody moved closer to the ball.

The vector always reserves one self slot, three teammate slots, and four opponent slots. Missing slots are zero-filled, so 1v1 through 4v4 share one observation shape.

Every player slot exposes movement, velocity, ball-arrival estimate, charge/pass state, selected and active ability one-hots, cooldown/readiness, permanent boss ability flags, mobility multipliers, and human/CPU control type.

Human teammates are first-class observations. The policy can see that a teammate is human, their movement intent, charge state, pass request, first-touch request, ability state, position, velocity, and ball-arrival estimate. Later team policies can therefore cooperate with real players instead of assuming every teammate is another AI.

## Action contract

Continuous actions:

- movement X/Y
- aim X/Y
- kick strength

Discrete actions:

- no kick / shot / pass
- ability trigger
- pass request
- receive mode: none / trap / volley / dummy
- receiver slot: none / teammate 0 / teammate 1 / teammate 2

Part 1 only validates and serializes actions. Execution is intentionally not connected yet.

## Part 2 headless environment

`rl_headless_environment.gd` is the isolated, fixed-step training match used for throughput work. It creates only a match-state node, a ball, two goals, and the requested players. It has no UI, rendering resources, camera, sounds, particles, replays, cosmetics, networking, or live CPU planner. It consumes the Part 1 action contract and produces the exact Part 1 observation vector without changing live matches.

The simulator mirrors the live field dimensions, player/ball radii, movement acceleration and damping, ball damping and wall bounce, goal mouth, charge range, and kick range. It is intentionally deterministic and reusable across episode resets. Part 2 does not yet train a policy or install one into gameplay.

Run the focused environment gate:

```powershell
$env:THEODORE_RL_V2_HEADLESS = '1'
& 'C:\Users\salik\Downloads\Godot_v4.7.1-stable_win64.exe' --headless --log-file '.\training\ai-v2-part2-test.log' --path 'C:\Users\salik\Documents\football-2d-' --script res://tests/ai_v2_headless_environment_test.gd
```

Run the bounded 1/4/8/16/32-environment benchmark:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File '.\training\run_ai_v2_part2_benchmark.ps1' -EnvironmentCounts '1,4,8,16,32'
```

The benchmark launches isolated Godot worker processes, enforces timeouts, and records steps/second, matches/hour, CPU use, peak RAM, worst simulation tick, process completion, and stable node counts under `training/benchmarks/`. Portable GPU-utilization sampling is reported as unavailable because the workers run with the renderer disabled; GPU training begins in a later part.

## Part 3 neural 1v1 baseline

Part 3 adds an isolated dependency-free actor-critic policy and PPO-style clipped updates. The neural policy consumes the complete Part 1 observation, emits the complete hybrid action contract, and plays full 1v1 matches inside the Part 2 fixed-step environment. The opponent adapter is frozen and records the identity of the packaged current 1v1 checkpoint. Live PvE continues to use the existing CPU; Part 3 checkpoints are written only below `training/ai_v2/checkpoints/`.

The reward is deliberately compact: goals/concedes and match wins/losses dominate, with only small possession-progress and danger-prevention shaping. Promotion requires complete games on both field sides, at least eight evaluation matches, a 55% win rate, and positive goal difference. A smoke run cannot promote.

Run the focused tests:

```powershell
$env:THEODORE_RL_V2_HEADLESS = '1'
& 'C:\Users\salik\Downloads\Godot_v4.7.1-stable_win64.exe' --headless --log-file '.\training\ai-v2-part3-test.log' --path 'C:\Users\salik\Documents\football-2d-' --script res://tests/ai_v2_part3_neural_baseline_test.gd
```

Run bounded smoke training and full-game evaluation:

```powershell
$env:THEODORE_RL_V2_HEADLESS = '1'
& 'C:\Users\salik\Downloads\Godot_v4.7.1-stable_win64.exe' --headless --log-file '.\training\ai-v2-part3-smoke.log' --path 'C:\Users\salik\Documents\football-2d-' --script res://training/ai_v2_part3_trainer.gd -- --mode smoke --updates 2 --rollout-steps 96 --evaluation-matches 4 --timeout-seconds 120
```

Or use the bounded runner (recommended):

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File '.\training\run_ai_v2_part3.ps1' -Mode smoke
```

Longer training uses `--mode train`. Add `--promote` only when intentionally allowing a candidate that passes the strict evaluation gate to become the isolated V2 champion. This still does not replace the live-game CPU.

## Part 4 self-play league

Part 4 removes Part 3's single-opponent training assumption. Each update samples a seeded persistent opponent pool containing the frozen Theodore champion, aggressive, defensive, passing and ability specialists, randomized variants, the current isolated V2 champion when present, and prior promoted V2 snapshots. Each opponent keeps Elo and matchup statistics in `training/ai_v2/league/1v1_league.json`.

Promotion now requires complete games on both field sides against the broad pool. A candidate must win overall, remain at least even with the current champion category, avoid catastrophic regression against specialists and randomized opponents, and finish with positive goal difference. Promotion writes a frozen historical checkpoint before updating the isolated V2 champion. The live game still uses the existing CPU.

Run the focused gate:

```powershell
$env:THEODORE_RL_V2_HEADLESS = '1'
& 'C:\Users\salik\Downloads\Godot_v4.7.1-stable_win64.exe' --headless --log-file '.\training\ai-v2-part4-test.log' --path 'C:\Users\salik\Documents\football-2d-' --script res://tests/ai_v2_part4_self_play_league_test.gd
```

Run bounded league smoke training:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File '.\training\run_ai_v2_part4.ps1' -Mode smoke
```

Longer training uses `-Mode train`. `-Promote` is still explicit and succeeds only after the broad league gate passes.

## Part 5 human demonstrations

Part 5 connects the existing authoritative human recorder to V2. The importer converts privacy-safe canonical states into the exact V2 observation contract and maps movement, aim, kick strength, pass targets, and ability timing into supervised actor targets. Positive outcome-scored sequences warm-start the neural candidate; recorded failures and own goals remain negative evaluation evidence and are never copied.

The resulting checkpoint still has to improve on held-out demonstrations and pass the complete Part 4 league gate. Optional PPO updates can continue immediately after imitation, so human play provides a starting distribution rather than a permanent ceiling. No Part 5 checkpoint controls live PvE CPUs.

Run the bounded pipeline from PowerShell:

```powershell
& '.\training\run_ai_v2_part5.ps1' -Mode smoke
& '.\training\run_ai_v2_part5.ps1' -Mode train -ImitationEpochs 8 -RlUpdates 4 -MatchesPerOpponent 4
```

Add `-Promote` only when you intentionally want a candidate that passes both gates written to the isolated V2 champion and history.

## Difficulty

Lower-ELO behavior is intentionally not implemented in Part 1. The contract reserves difficulty scaling for later runtime policy profiles so lower ranks can keep the same football knowledge while using weaker/rarer coordination, less memory, slower replanning, more stochastic choices, or a reduced policy mixture without retraining a separate incompatible observation format.

## Part 6 shared 2v2 team intelligence

Part 6 upgrades the isolated policy to a recurrent shared-team architecture. Both teammates use the same neural weights and the same Part 1 observation/action contract, while each stable team slot retains separate memory. A pooled prior-step team memory lets one teammate's developing intent influence the next decisions of the other without merging their identities or actions.

The 2v2 trainer gives both teammates the same outcome credit but stores their own observations, actions, receiver selections and recurrent states. Memory is cleared on goals, match termination and episode reset so a plan cannot leak into the next kickoff. Part 3-5 feed-forward checkpoints remain loadable and can be upgraded into a Part 6 recurrent warm start.

Part 6 has a separate persistent 2v2 candidate, champion, history and league. Promotion requires the broad football gate plus evidence that the policy actually exercised passing or receiver-targeting actions; two independent dribblers cannot qualify merely by winning a small sample. The current live PvE AI remains untouched.

Run the focused test:

```powershell
$env:THEODORE_RL_V2_HEADLESS = '1'
& 'C:\Users\salik\Downloads\Godot_v4.7.1-stable_win64.exe' --headless --path 'C:\Users\salik\Documents\football-2d-' --script res://tests/ai_v2_part6_team_memory_test.gd
```

Run the bounded isolated pipeline:

```powershell
& '.\training\run_ai_v2_part6.ps1' -Mode smoke
& '.\training\run_ai_v2_part6.ps1' -Mode train -Updates 40 -RolloutSteps 512 -MatchesPerOpponent 4 -EpisodeSeconds 20
```

Add `-Promote` only when intentionally allowing a candidate that passes the full 2v2 league gate to become the isolated 2v2 champion. Part 6 establishes trainable memory and shared coordination, but a smoke run does not prove learned passing quality or emergent combination play; those require sustained training and match evaluation.

## Part 7 variable-size and human-teammate team intelligence

Part 7 removes the Part 6 trainer's fixed 2v2 assumption. One recurrent shared-weight policy now trains and evaluates with stable slots in 2v2, 3v3 and 4v4. The original Part 3 1v1 path and observation shape remain valid and are regression-tested; Part 7 does not overwrite its champion.

Mixed-team rollouts mark one teammate as human and expose that teammate through the existing privacy-safe observation contract: position, velocity, movement intent, pass request, charge/reception intent and ability state. A deterministic scripted fixture supplies realistic training actions for that slot, while PPO updates are written only for CPU-controlled slots. No live input is read and no human behavior is copied into the neural batch. This teaches the CPUs to adapt around a real player instead of assuming all teammates share their controller.

The isolated multiteam promotion gate requires successful 2v2, 3v3 and 4v4 league evaluations on both sides plus completed mixed-human evaluation at every size. Lower-ELO coordination frequency and execution mistakes remain intentionally deferred to a later runtime-difficulty layer.

Run the focused test:

```powershell
$env:THEODORE_RL_V2_HEADLESS = '1'
& 'C:\Users\salik\Downloads\Godot_v4.7.1-stable_win64.exe' --headless --path 'C:\Users\salik\Documents\football-2d-' --script res://tests/ai_v2_part7_multiteam_test.gd
```

Run the bounded isolated pipeline:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File '.\training\run_ai_v2_part7.ps1' -Mode smoke
powershell.exe -NoProfile -ExecutionPolicy Bypass -File '.\training\run_ai_v2_part7.ps1' -Mode train -UpdatesPerSize 24 -RolloutSteps 512 -MatchesPerOpponent 4 -EpisodeSeconds 20
```

`-Promote` remains explicit. A candidate is never promoted merely because a smoke run completed, and none of these checkpoints control the current live PvE AI yet.

## Part 8 V2-versus-current-AI evaluation tournament

Part 8 is evaluation only. It does not train, promote, or connect V2 to live gameplay. The isolated 1v1 and multiteam candidates play paired blue/red matches against the frozen current-AI hybrid checkpoints in 1v1, 2v2, 3v3, and 4v4. Deterministic scenario rotation varies formations, field variants, score/time states, ability loadouts, player archetype modifiers, current-AI tactical profiles, starting positions, and seeds. The paired side design prevents a favorable starting score or field side from benefiting only V2.

### Fundamentals repair warm start

If a candidate requests actions outside authoritative contact range or has not yet
learned mirrored movement, rebuild its basic movement/kick warm start before PPO:

```powershell
& 'C:\Users\salik\Downloads\Godot_v4.7.1-stable_win64.exe' --headless --path 'C:\Users\salik\Documents\football-2d-' --script res://training/ai_v2_fundamentals_trainer.gd -- --scenarios 6 --epochs 2 --learning-rate 0.00012 --fresh true
```

This curriculum uses the real headless environment, canonicalizes both teams into
one attack direction, teaches both legal shots and passes, and writes only the
isolated candidate checkpoints. `--fresh true` intentionally discards existing
candidate weights; omit it to refine a repaired candidate. Run Part 3 and Part 7
PPO afterward to learn outcome quality, passing, abilities, and team tactics. Do
not run the full Part 8 tournament until a short Part 8 smoke evaluation shows
meaningful action evidence in all four team sizes.

Telemetry is taken from executed simulator events rather than policy requests. Reports compare goals, wins, possession safety, successful kicks, shots, completed passes, line breaks, ability activation coverage, double commits, rebounds, goalkeeper mistakes, kickoff mistakes, and own goals. Mixed human-teammate fixtures remain required in 2v2-4v4 so a policy cannot qualify by cooperating only with neural teammates.

The readiness gate requires at least 100 completed matches per size, balanced field sides, broad scenario coverage, and ten mixed-human matches per multiteam size. It also rejects qualitative regressions. Passing the gate means only that the candidate is eligible for a later controlled runtime trial; `promotion_performed` is always false in Part 8.

Run focused tests:

```powershell
$env:THEODORE_RL_V2_HEADLESS = '1'
& 'C:\Users\salik\Downloads\Godot_v4.7.1-stable_win64.exe' --headless --path 'C:\Users\salik\Documents\football-2d-' --script res://tests/ai_v2_part8_tournament_test.gd
```

Run a bounded smoke tournament or the full evidence tournament:

```powershell
& '.\training\run_ai_v2_part8.ps1' -Mode smoke
& '.\training\run_ai_v2_part8.ps1' -Mode tournament -MatchesPerSize 100 -MixedMatches 10 -EpisodeSeconds 20 -TimeoutSeconds 5400
```

The runner uses four concurrent Godot workers by default, one for each team size, then merges their reports through the same readiness gate. Pass `-Parallel $false` only for diagnosis. The report is written to `training/ai_v2/evaluation/part8_latest.json`. The evaluator mirrors core movement and ball physics, but rendered map art, UI, networking, and live scene effects remain outside this headless evidence phase.

## Part 9 guarded live-runtime bridge

Part 9 adds an experimental advisory bridge from the isolated V2 candidate to
the server-authoritative live CPU. It remains disabled by default through
`ai_v2/runtime/enabled=false` in `project.godot`; therefore this part does not
silently replace the current Ranked, PvE, or ladder CPU.

When explicitly enabled for a controlled trial, the bridge selects the isolated
1v1 checkpoint for 1v1 and the multiteam checkpoint for 2v2-4v4. Recurrent state
is kept separately for each logical CPU and reset with the existing AI episode
reset. The neural policy may advise attacking/support movement, a shot, a pass,
an ability consideration, or a pass request only after deterministic kickoff,
duel, goalkeeper, and emergency-defense handling. Shots and passes are converted
to existing live plans and must pass the current goal-mouth, lane, reachability,
interception, possession, and charge checks. Missing/corrupt checkpoints,
non-finite output, neutral output, unavailable receivers, or rejected live plans
fall through to the current CPU in the same decision tick.

Run the focused bounded check (normally under 15 seconds; hard timeout 120 seconds):

```powershell
$Godot = 'C:\Users\salik\Downloads\Godot_v4.7.1-stable_win64.exe'
$Project = 'C:\Users\salik\Documents\football-2d-'
$process = Start-Process -FilePath $Godot -ArgumentList @(
  '--headless', '--path', $Project,
  '--script', 'res://tests/ai_v2_part9_runtime_integration_test.gd'
) -PassThru -NoNewWindow
if (-not $process.WaitForExit(120000)) {
  Stop-Process -Id $process.Id -Force
  throw 'Part 9 test timed out after 120 seconds'
}
exit $process.ExitCode
```

Part 10 will provide the separate WSL/PyTorch GPU training backend and checkpoint
conversion. It is not enabled or simulated by this runtime bridge.
