FOOTBALL IMPACT RESTORE - NO DIRECTIONAL BALL ROTATION v2.1

PURPOSE

This corrective patch restores the strong shot/pass impact feedback that was
reduced in the previous patch, while keeping the ball artwork from rotating or
turning toward the shot direction.

RESTORED

- Strong ball squash and rebound
- Strong contact color flash
- Strong translational camera shake
- Original impact timing and intensity
- Existing kick shockwave, sparks, particles and trail remain active

STILL REMOVED

- Ball sprite rotation toward the kick direction
- Direction-dependent visual turning
- Camera rotational tilt

The ball physics, trajectory, angular velocity, kick force and collision are not
changed. This patch only modifies presentation.

INSTALL

Apply after Football_Visual_Field_PhantomHeel_v2_PATCH.
Copy the Characters and Scenes folders into the project root and overwrite:

Characters/ball.gd
Scenes/match_camera.gd
