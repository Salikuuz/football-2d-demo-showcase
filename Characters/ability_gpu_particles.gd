class_name FootballAbilityGpuParticles
extends GPUParticles2D

# Compatibility wrapper around GPUParticles2D. Player ability code can keep its
# old CPUParticles-style semantic properties while simulation lives on the GPU.
# This removes the per-particle CPU work that spikes when several abilities are
# active in 4v4-6v6.

var emission_sphere_radius: float:
	get:
		return _material().emission_sphere_radius
	set(value):
		_material().emission_sphere_radius = value

var direction: Vector2:
	get:
		var value := _material().direction
		return Vector2(value.x, value.y)
	set(value):
		_material().direction = Vector3(value.x, value.y, 0.0)

var spread: float:
	get:
		return _material().spread
	set(value):
		_material().spread = value

var gravity: Vector2:
	get:
		var value := _material().gravity
		return Vector2(value.x, value.y)
	set(value):
		_material().gravity = Vector3(value.x, value.y, 0.0)

var initial_velocity_min: float:
	get:
		return _material().initial_velocity_min
	set(value):
		_material().initial_velocity_min = value

var initial_velocity_max: float:
	get:
		return _material().initial_velocity_max
	set(value):
		_material().initial_velocity_max = value

var scale_amount_min: float:
	get:
		return _material().scale_min
	set(value):
		_material().scale_min = value

var scale_amount_max: float:
	get:
		return _material().scale_max
	set(value):
		_material().scale_max = value

var color: Color:
	get:
		return _material().color
	set(value):
		_material().color = value


func _material() -> ParticleProcessMaterial:
	var material := process_material as ParticleProcessMaterial
	if material == null:
		material = ParticleProcessMaterial.new()
		material.gravity = Vector3.ZERO
		process_material = material
	return material
