# OPTIMAL ADAPTIVE 1V1 GENERATION PIPELINE
Version 3

PURPOSE
-------
This package manages the repeated self-play loop without changing the actual
learning philosophy by itself. The expensive trainer remains the trainer.
This layer makes each generation reproducible, auditable, recoverable and easy
to compare.

It deliberately DOES NOT automatically invent the next curriculum. The next
curriculum should be based on the previous generation's real failure modes.
That prevents a self-play loop from becoming narrow around one exploit.

WHAT IT ADDS
------------
1. Immutable checkpoint freezing with SHA-256 + model checksum.
2. Deterministic RunId support in the existing coordinator.
3. Exact pre-generation snapshots of champion, elites, config and source hashes.
4. JSON integrity validation for every collected training/evaluation result.
5. Automatic extraction of benchmark quality, win score, goal difference,
   own-goal rate, diversity, exploitability, early rejection and rejection reasons.
6. Cross-play result extraction.
7. Automatic detection of whether the active champion actually changed and,
   where possible, which worker/crossover became champion.
8. Persistent generation registry.
9. Complete analysis ZIP after every run.
10. Automatic diagnostic ZIP even if a future generation crashes partway through.
11. Generation-to-generation comparison command.

IMPORTANT: CURRENT GENERATION 1
-------------------------------
Your current/recovered run is:
20260810_212113

Do NOT restart its 3-hour training.
Let its evaluation finish.

After it finishes, run:

  .\training\collect_1v1_generation.ps1 -RunId 20260810_212113

This creates a file similar to:

  1v1_G001_20260810_212113_analysis_bundle.zip

Upload that ZIP. It contains the evidence needed to design Generation 2.

If you already froze the old Intelligence-15 checkpoint with the earlier helper,
this pipeline recognizes the same canonical file:

  hybrid_ai\1v1\reference_archive\int15_reference_before_adaptive_push.json

Running the new freeze script when that reference already exists NEVER overwrites
it; it only verifies it and creates stronger metadata/locking information.

FROZEN ORIGINAL INTELLIGENCE-15 ANCHOR
--------------------------------------
Only when the current active checkpoint is definitely the historical Intelligence
15 you want as the long-term target for Intelligence 11, run:

  .\training\freeze_1v1_reference.ps1

Never intentionally overwrite that reference later.

FUTURE GENERATIONS
------------------
After I inspect a generation bundle, I will give you the next adaptive config.
Then launch the next generation with:

  .\training\start_1v1_adaptive_generation.ps1 `
      -Config "res://training/<NEXT_GENERATION_CONFIG>.json"

Defaults remain:
- 6 workers
- 3 hours each
- 6x simulation
- 3 concurrent benchmark processes
- 4 elites
- 6 cross-play matches per series
- 3 controlled crossover children

The start script automatically:
- assigns the generation number and RunId,
- freezes the exact pre-run champion and elite pool,
- hashes the source/config,
- starts training,
- performs coordinator evaluation/promotion,
- collects the full result bundle.

If training/evaluation crashes, it still packages the partial run so the compute is
not hidden or casually discarded.

VERIFY LATEST COLLECTED GENERATION
----------------------------------
  .\training\verify_1v1_generation.ps1

COMPARE TWO GENERATIONS
-----------------------
  .\training\compare_1v1_generations.ps1 `
      -RunIdA 20260810_212113 `
      -RunIdB <NEXT_RUN_ID>

WHY THIS IS THE RIGHT LOOP
--------------------------
Generation N is not followed by a blind copy of Generation N's curriculum.
Instead:

  train -> frozen benchmark -> cross-play -> promotion -> collect -> diagnose
  weaknesses -> design next curriculum -> train again

The permanent old-Int15 reference stays fixed while the current Intelligence-15
champion is allowed to move upward. Once the new ladder is clearly stronger, the
difficulty mapping can be shifted so Intelligence 11 targets the old-Int15 skill
level and Intelligence 15 keeps the new strongest policy.
