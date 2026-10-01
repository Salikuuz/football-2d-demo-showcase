FOOTBALL ELITE 1V1 V3.8.1 INTENT PARSE FIX

APPLY AFTER V3.8.

ERROR
Identifier "INTENT_SHADOW_DEFEND" not declared in the current scope.

CAUSE
The new kickoff strategies referenced an intent name that does not exist in
cpu_player_ai.gd.

The valid defensive-positioning intent already present in the controller is:
INTENT_COVER

FIXED LOCATIONS
- delayed kickoff waiting phase
- delayed-counter kickoff waiting phase
- fake kickoff retreat phase

All three invalid references were replaced with INTENT_COVER.

VALIDATION
- Every INTENT_* use in cpu_player_ai.gd now has a matching local constant.
- No duplicate functions detected.
- Brackets, braces and parentheses are balanced.
- No AI strategy, timing, shot probability, force, training, action schema,
  camera, visual or gameplay value was changed.

INSTALL
Copy the contents of this folder into:
C:\Users\salik\Documents\football-2d-

Overwrite:
Scenes\cpu_player_ai.gd

LOCAL PARSE TEST
& "C:\Users\salik\Downloads\Godot_v4.7.1-stable_win64.exe" `
  --headless `
  --path "C:\Users\salik\Documents\football-2d-" `
  --editor `
  --quit
