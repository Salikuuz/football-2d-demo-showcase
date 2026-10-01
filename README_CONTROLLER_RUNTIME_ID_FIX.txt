CONTROLLER RANDOM-DISCONNECT / RUNTIME-ID FIX
=============================================

Confirmed project-side failure
------------------------------
The old controller manager pinned every joypad InputMap binding to the current
Godot device ID. If that ID disappeared, all actions were rebound to fake
device 127 until a strict logical-assignment recovery succeeded.

That is unsafe with SDL / Steam Input because one physical controller can change
runtime representation or return under another device ID. The controller could
still be producing input while the game's actions were listening to device 127.

Godot 4.7 source:
InputMap::ALL_DEVICES = -1.

Fix
---
- All gameplay, movement and controller UI bindings permanently use device -1
  (InputMap ALL_DEVICES).
- Gameplay no longer depends on active_device_id.
- active_device_id is retained only for controller name/glyph/profile/debug UI.
- No fake device 127 exists anymore.
- Automatic controller assignment now self-heals from the first meaningful
  live event after an assignment loss.
- State polling is also allowed to recover an unavailable automatic assignment.
- Manual controller selection stays conservative, but gameplay remains
  wildcarded so a runtime-ID change cannot kill controls.

Why this matches this game
--------------------------
There is only one local human input stream on each client. Device-ID filtering
is therefore unnecessary for gameplay and only adds failure modes.

If a controller still stops after this patch AND Godot's controller lifecycle
log shows no input events / no connected joypad at all, the remaining fault is
below the game layer (Windows / Bluetooth / USB / Steam Input / controller
firmware). This patch removes the confirmed game-side lockout so that distinction
is now clean.

Changed file:
Scenes/controller_support.gd
