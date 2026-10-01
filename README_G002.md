# Generation 2 — targeted true 1v1

This package was built from `1v1_G001_20260810_212113_analysis_bundle.zip`.

## What G001 proved

Worker 3 is the verified G001 1v1 winner:

- promotion passed
- 14/14 frozen suite matches completed
- win score: 0.6786
- goal difference: +0.50 per match
- average reward: +10.015
- own-goal rate: 0
- diversity gate passed
- exploitability collapse: false

Its weakest frozen matchups were `original_1v1` and `passing_1v1`.

## Important bug found

G001 was intended to be dedicated 1v1, but its curriculum advanced itself to
`full_2v2` starting at generation 75. G002 disables curriculum advancement and
hard-locks `team_size = 1`, so this cannot happen again.

## G002 curriculum

Kickoff drills fall from 60% of scenario slots to 25%. They remain in training
so the G001 kickoff improvement is preserved.

New true-1v1 drills:

- `central_duel`
- `pressure_escape`
- `finishing_duel`

The opponent distribution also increases scripted/specialist exposure to attack
the passing, counterpress and solo-duel weaknesses seen in the G001 evidence.

## Run

The optimal adaptive pipeline from the previous package must already be installed.

From the project root:

```powershell
.\training\prepare_and_start_G002.ps1
```

The script first:

1. validates G001 worker 3 and its benchmark;
2. reconstructs the exact pre-G001 Intelligence-15 reference from the worker's
   preserved `history/league_main.json` if the original freeze was missed;
3. backs up the current active checkpoint;
4. selects the verified G001 worker-3 1v1 champion;
5. starts G002 through the adaptive generation manager.

When it finishes, upload the generated G002 analysis bundle.
