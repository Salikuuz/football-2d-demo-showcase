FOOTBALL NETWORKED PLAYER ACTION PULSE V4.0

APPLY AFTER THE CURRENT VISUAL/PLAYER PATCHES.

PURPOSE
Adds a visible expanding pulse around the circular player badge whenever the
player performs an important input action.

NETWORKING
- The server decides when the pulse happens.
- The server sends one reliable authority RPC to every peer.
- The pulse is visible to the acting player, teammates, opponents and host.
- It is not a local-client-only effect.
- Headless training/server instances skip visual node creation to avoid
  unnecessary training overhead.

TRIGGERS

CHARGED SHOT
- Triggers when the authoritative shot charge is released.
- It does not require the player to hit the ball.
- Charge amount controls the pulse intensity.
- Applies to human and CPU charged-shot releases.

SOFT PASS
- Triggers when a valid soft-pass input is accepted.
- It does not require ball contact.
- Cooldown-rejected pass spam does not create pulses.

PASS REQUEST
- Triggers when an accepted teammate pass request is sent.
- The existing pass-request marker remains unchanged.

ABILITY
- Triggers only when the authoritative ability activation succeeds.
- No pulse occurs when the ability is unavailable, on cooldown or fails its
  activation conditions.
- Copycat uses the color of the ability it actually copied.

COLORS
- Shot: warm white/gold.
- Soft pass: cyan.
- Pass request: green.
- Ability: one unique theme color for every ability.
- Power Strike remains red.
- Phantom Heel uses its existing Sharingan-red theme.

VISUAL
- Expanding antialiased Line2D ring around the existing player badge.
- Fast 45 ms appearance.
- Smooth 240 ms expansion/fade.
- Multiple rapid actions can display overlapping pulses.
- Does not rotate, recolor, replace or rescale the actual player portrait.
- Does not change collision, movement, inputs, cooldowns, shot force, ball,
  camera, AI, training, UI or field layout.

FILE
Characters\player.gd

INSTALL
It is safest to apply after the currently running AI training round and its
coordinator benchmark have finished.

Copy the contents of this folder into:
C:\Users\salik\Documents\football-2d-

Allow overwriting:
Characters\player.gd

LOCAL PARSE TEST
& "C:\Users\salik\Downloads\Godot_v4.7.1-stable_win64.exe" `
  --headless `
  --path "C:\Users\salik\Documents\football-2d-" `
  --editor `
  --quit

MULTIPLAYER TEST
1. Host with two game instances.
2. Release a charged shot without touching the ball.
3. Both instances should see the warm pulse.
4. Press soft pass away from the ball.
5. Both instances should see the cyan pulse.
6. Activate an available ability.
7. Both instances should see the ability-colored pulse.
8. Press an ability while it is on cooldown.
9. No pulse should occur.
