# Premium UI skin

The visual redesign is deliberately a runtime skin layer. It preserves the
existing scenes, signals, node names, controller focus flow, and gameplay.

## Quick revert

Open `Scenes/menu_styler.gd` and set:

```gdscript
const PREMIUM_UI_V2_ENABLED: bool = false
```

Restart the game. This disables the premium colors, borders, depth, hover,
focus, field, slider, tab, and popup styling in one place. The existing
per-screen styles remain intact underneath it.

The small responsive safeguards in the connection/options menu, freeplay
ability chooser, replay prompt, and results screen are intentionally separate:
they keep controls accessible at 720p and narrow heights without affecting
gameplay or input behavior.
