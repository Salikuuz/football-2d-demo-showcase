class_name TheodoreRLV2Interface
extends RefCounted

const Schema := preload("res://ai_v2/rl_schema.gd")
const ObservationBuilder := preload("res://ai_v2/rl_observation_builder.gd")
const ActionCodec := preload("res://ai_v2/rl_action_codec.gd")


static func handshake() -> Dictionary:
	return Schema.contract()


static func observe(
	manager: Node,
	perspective_player: Node,
	field_rect: Rect2,
	server_now: float = -1.0
) -> Dictionary:
	return ObservationBuilder.build(manager, perspective_player, field_rect, server_now)


static func observe_wire(
	manager: Node,
	perspective_player: Node,
	field_rect: Rect2,
	server_now: float = -1.0
) -> Dictionary:
	return ObservationBuilder.to_wire_packet(
		ObservationBuilder.build(manager, perspective_player, field_rect, server_now)
	)


static func sanitize_action(action: Dictionary) -> Dictionary:
	return ActionCodec.sanitize(action)


static func encode_action(action: Dictionary) -> Dictionary:
	return ActionCodec.encode(action)


static func decode_action(continuous, discrete) -> Dictionary:
	return ActionCodec.decode(continuous, discrete)


static func action_wire(action: Dictionary) -> Dictionary:
	return ActionCodec.to_wire_packet(action)
