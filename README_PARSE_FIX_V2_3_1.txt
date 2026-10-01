FOOTBALL VISUAL CAMERA SMOOTHING V2.3.1 PARSE FIX

Fixes:
Parser Error: Cannot infer the type of "start" variable because the value doesn't have a set type.

Cause:
The side loop used an untyped temporary value. Godot treated it as Variant,
which made the calculated Vector2 start position ambiguous.

Changed:
- Explicit Array[float] for the two sides.
- Explicit float loop type.
- Explicit Vector2 types for start and finish positions.
- Explicit types for other draw variables in the same function.

Install after Visual Camera + Smoothing v2.3.
Copy the Scenes folder into the project root and overwrite:
Scenes/kick_feedback_fx.gd
