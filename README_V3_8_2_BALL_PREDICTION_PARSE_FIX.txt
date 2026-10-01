FOOTBALL ELITE 1V1 V3.8.2 BALL-PREDICTION PARSE FIX

APPLY AFTER V3.8.1.

ERROR
Function "_predict_ball_position()" not found in base self.

CAUSE
The fake-kickoff branch called:
_predict_ball_position(0.32)

That function did not exist. The older controller only had:
_get_predicted_ball_position()

FIX
- Adds _predict_ball_position_for_seconds(seconds).
- Fake kickoff now predicts the ball 0.32 seconds ahead using that helper.
- _get_predicted_ball_position() now delegates to the same helper using the
  existing ball_prediction_seconds setting.
- Wall reflection, field clamping and perception behavior are preserved.

VALIDATION
- Scanned every implicit underscore-prefixed local function call in the full
  cpu_player_ai.gd file.
- Undeclared local calls remaining: 0.
- Undeclared INTENT_* references remaining: 0.
- Duplicate functions remaining: 0.
- Parentheses, brackets and braces are balanced.
- No kickoff strategy, shot logic, AI value, force, timing, training,
  action-space, visual, physics or camera setting was changed.

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
