class_name TheodoreRLV2DemonstrationGate
extends RefCounted

const LeaguePromotionGate := preload("res://ai_v2/rl_league_promotion_gate.gd")


static func evaluate(
	dataset_stats: Dictionary,
	validation_before: Dictionary,
	validation_after: Dictionary,
	league_evaluation: Dictionary
) -> Dictionary:
	var reasons: Array[String] = []
	var train_samples: int = int(dataset_stats.get("train_samples", 0))
	var validation_samples: int = int(validation_after.get("samples", 0))
	var before_loss: float = float(validation_before.get("loss", INF))
	var after_loss: float = float(validation_after.get("loss", INF))
	var before_accuracy: float = float(validation_before.get("accuracy", 0.0))
	var after_accuracy: float = float(validation_after.get("accuracy", 0.0))
	var has_training_data: bool = train_samples >= 8
	var has_validation_data: bool = validation_samples >= 4
	var imitation_improved: bool = (
		has_validation_data
		and is_finite(before_loss)
		and is_finite(after_loss)
		and (after_loss < before_loss * 0.995 or after_accuracy > before_accuracy + 0.01)
	)
	if not has_training_data:
		reasons.append("insufficient_training_demonstrations")
	if not has_validation_data:
		reasons.append("insufficient_held_out_demonstrations")
	if has_validation_data and not imitation_improved:
		reasons.append("held_out_imitation_did_not_improve")
	var league_gate: Dictionary = LeaguePromotionGate.evaluate(league_evaluation)
	if not bool(league_gate.get("promoted", false)):
		reasons.append("frozen_league_gate_failed")
	return {
		"promoted": reasons.is_empty(),
		"reasons": reasons,
		"has_training_data": has_training_data,
		"has_validation_data": has_validation_data,
		"imitation_improved": imitation_improved,
		"validation_loss_before": before_loss,
		"validation_loss_after": after_loss,
		"validation_accuracy_before": before_accuracy,
		"validation_accuracy_after": after_accuracy,
		"league_gate": league_gate
	}
