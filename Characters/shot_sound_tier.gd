class_name ShotSoundTier
extends Resource


@export var minimum_force: float = 0.0
@export var sound: AudioStream
@export_range(-80.0, 24.0, 0.1)
var volume_db: float = 0.0
@export_range(0.1, 4.0, 0.01)
var pitch_scale: float = 1.0
