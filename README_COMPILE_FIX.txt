Replace these files in the hybrid AI project, preserving the same paths.

Functionality fixes:
- ai/hybrid/tactical_observation_builder.gd
- Scenes/cpu_player_ai.gd
- training/hybrid_ai_trainer.gd

Validation updates:
- tests/hybrid_static_validation.py
- training/VALIDATION_REPORT.md

Then close Godot, delete the project's .godot cache folder, reopen Godot 4.7.1,
and run the core test again.
