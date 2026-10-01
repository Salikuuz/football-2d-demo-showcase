2v2 AI deadlock fix

Changed files:
- Scenes/cpu_player_ai.gd
- Scenes/match_manager.gd
- training/hybrid_ai_trainer.gd

What changed:
- The designated goalkeeper can no longer be selected as the defensive presser.
- In 2v2 the outfield CPU always owns the press and the keeper owns the final lane.
- Ball carriers detect prolonged no-progress possession and force a safe pass, shot, or open-space dribble.
- The 2v2 goalkeeper steps forward during safe buildup and becomes a reliable recycle outlet.
- 2v2 backpasses to the goalkeeper are deterministic when no useful forward receiver exists.
- Training records stationary-possession streaks and rejects candidates with long deadlocks.
- Normal-speed verification also rejects stationary-possession candidates.

The runtime safeguards sit above the learned policy and do not rewrite Worker 2's checkpoint.
