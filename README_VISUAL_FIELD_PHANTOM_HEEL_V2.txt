FOOTBALL VISUAL / FIELD / PHANTOM HEEL PATCH V2

BASED ON
- Football Visual Impact Upgrade v1
- The current project layout and collision coordinates

CHANGES
1. Ball visual no longer turns toward the kick direction.
2. Ball sprite is held upright even while the RigidBody2D rotates internally.
3. Shot squash is reduced to a very small pulse.
4. Shot camera movement is smaller and has zero rotational shake.
5. The baked white lines and red/blue circles were removed from Download (3).png.
6. New procedural field markings align to the actual playable inner borders:
   left 318, right 7030, top 770, bottom 4230.
7. Penalty areas, goal areas, center circle, spots, arcs, and corners are redrawn.
8. Goal extensions outside the pitch are now shown with subtle net lines and team accents.
9. lol scharingan now plays only when Phantom Heel succeeds, at -5 dB.

INSTALL
Extract the contents into the project root and overwrite the listed files.

FILES
Characters/ball.gd
Characters/player.gd
Scenes/field_visuals.gd
Scenes/match_camera.gd
Download (3).png
Audio/phantom_heel_sharingan.mp3

THIS PATCH DOES NOT TOUCH
- AI/training files
- checkpoints
- multiplayer logic
- ball physics/collision
- ability behavior or cooldowns

LOCAL PARSE TEST
& "C:\Users\salik\Downloads\Godot_v4.7.1-stable_win64.exe" --headless --path "C:\Users\salik\Documents\football-2d-" --editor --quit

TUNING
Ball.gd: impact_squash_amount defaults to 0.055. Set it to 0.0 to disable the remaining tiny pulse.
Player.gd: phantom_heel_sound_volume_db defaults to -5.0.
