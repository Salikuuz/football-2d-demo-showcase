# Ball impact knockback modifier fix

The first implementation tried to correct `player.linear_velocity` from a deferred call in `ball.gd`. Godot's rigid-body collision solver and the player's own `_integrate_forces()` could apply velocity again afterward, so a modifier of `0.0` was not reliably zero knockback.

The limiter is now queued by `ball.gd` and enforced inside `FootballPlayer._integrate_forces()` for a short hold period. This is the authoritative physics callback for the player body, so it reliably clamps the velocity component in the ball's travel direction.

## Settings

- `Player Ball Impact Knockback Modifier`
  - `0.0`: zero knockback below the bypass speed.
  - `0.5`: half of the calculated cap below the bypass speed.
  - `1.0`: full calculated cap below the bypass speed.
- `Player Ball Impact Modifier Bypass Speed`
  - At or above this ball speed, the modifier is ignored and normal knockback returns.
- `Player Ball Impact Limit Hold Seconds`
  - How long the player-side limiter remains active after contact. Default: `0.12`.

Recommended values for the requested behavior:

- Modifier: `0.0`
- Bypass speed: `6000.0`
- Receive threshold: `2000.0`
- Full speed threshold: `5000.0`
- Receive max speed: `80.0` (irrelevant below bypass when modifier is 0)
- Max speed: `2000.0`

With those values:

- A 4000-speed ball produces no player knockback.
- A 5999-speed ball produces no player knockback.
- A 6000-speed ball bypasses the modifier and can push the player, capped by the normal impact curve.
