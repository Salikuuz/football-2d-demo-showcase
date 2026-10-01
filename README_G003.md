# G003 — Champion Fusion / True 1v1

G002 did not produce a main-champion promotion, but it produced the exact donor
we needed.

## G002 result

Worker 4:
- full 26-match gate win score: 0.5577 (promotion floor 0.560)
- +0.385 goal difference per match
- zero own goals
- diversity passed
- no exploitability collapse

Its actual 1v1 result set was 8 wins, 2 draws, 4 losses with 20–10 goals.

G002 solved the old champion's `original_1v1` and `passing_1v1` weaknesses, but
Worker 4 regressed against the previous champion and several defensive/wall
styles. That is catastrophic forgetting, not a lack of learning.

## G003 solution

Do not throw away either policy.

The launcher creates three deliberate fusion seeds:

1. `control`
   - base = current main champion
   - donor = G002 Worker 4
   - transfers Worker 4's control/dribble/pass-related action group

2. `offense`
   - base = current main champion
   - donor = G002 Worker 4
   - transfers Worker 4's attacking/finishing action group

3. `defense`
   - base = G002 Worker 4
   - donor = current main champion
   - restores the champion's defensive/duel action group into Worker 4

Every worker also has a 32% explicit frozen-main-champion opponent anchor. A
candidate therefore cannot cheaply improve on scripted weaknesses while
forgetting how to play the champion.

The final promotion benchmark is now `team_sizes: [1]`. This generation is for
the best possible 1v1 policy. 2v2/3v3/4v4 transfer can be measured after a new
champion exists and later improved with dedicated coordination training.

## Run

Install this ZIP over the project. Keep the optimal adaptive pipeline installed.

Then:

```powershell
.\training\prepare_and_start_G003.ps1
```

Default:
- 6 workers
- 4 hours each
- 24 worker-hours
- 6x simulation speed
- hard-locked 1v1

You can use `-Hours 3` if you explicitly want a shorter run, but the G003 default
is 4 hours because the goal is refinement/fusion rather than another broad
search.

When it finishes, upload the generated G003 analysis bundle.
