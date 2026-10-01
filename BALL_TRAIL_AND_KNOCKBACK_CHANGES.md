# Ball trail and player-impact knockback

## Speed trail

The ball uses two Line2D trails plus GPUParticles2D. The trail starts at
`speed_trail_start_speed` and reaches full visual intensity at
`speed_trail_full_speed`.

## Knockback controls

The controls are exported from `Characters/ball.gd` and can also be edited on
the Ball root node in `Characters/ball.tscn`.

- `player_ball_impact_knockback_modifier`: Scales impact knockback while the
  incoming ball is below the bypass speed. `0.0` removes impact knockback,
  `0.5` keeps half, and `1.0` keeps the normal calculated knockback.
- `player_ball_impact_modifier_bypass_speed`: At this ball speed or faster, the
  modifier is ignored and normal knockback returns. The default is `6000.0`.
- `player_ball_impact_receive_speed_threshold`: Beginning of the original
  smooth knockback curve.
- `player_ball_impact_full_speed_threshold`: Speed where that curve reaches its
  normal maximum.
- `player_ball_impact_receive_max_speed`: Normal low-speed impact cap before the
  modifier is applied.
- `player_ball_impact_max_speed`: Normal high-speed impact cap.
- `goalkeeper_saving_ball_impact_receive_max_speed` and
  `goalkeeper_saving_ball_impact_max_speed`: Separate caps while Goalkeeper
  Reach or Reflex Block is active.

With the included defaults, a 4000-speed ball produces no impact knockback
because the modifier is `0.0` and 4000 is below the 6000 bypass speed. At 6000
or faster, the modifier is ignored and normal high-speed knockback is allowed.
Intentional player movement in the same direction as the ball is preserved.
The system limits the player's outward velocity; it never lowers the ball's
speed.
