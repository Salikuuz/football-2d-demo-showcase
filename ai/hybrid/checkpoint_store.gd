class_name HybridCheckpointStore
extends RefCounted


const Schema := preload("res://ai/hybrid/tactical_schema.gd")
const Policy := preload("res://ai/hybrid/tactical_policy.gd")

const DEFAULT_ACTIVE_PATH: String = "res://training/hybrid_checkpoints/active.json"


static func load_checkpoint(path: String = DEFAULT_ACTIVE_PATH) -> Dictionary:
	var primary := _load_checkpoint_file(path)
	primary["requested_path"] = path
	if bool(primary.get("ok", false)):
		return primary

	# An interrupted rename or an actually damaged active file must not erase the
	# last known-good champion. Try the atomic-save backup before giving up.
	var backup_path := path + ".previous"
	if FileAccess.file_exists(backup_path):
		var backup := _load_checkpoint_file(backup_path)
		backup["requested_path"] = path
		if bool(backup.get("ok", false)):
			backup["recovered_from_backup"] = true
			backup["primary_error"] = primary.duplicate(true)
			return backup
	return primary


static func _load_checkpoint_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {
			"ok": false,
			"error": "checkpoint_missing",
			"path": path
		}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {
			"ok": false,
			"error": "checkpoint_open_failed",
			"path": path
		}
	var raw_text := file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(raw_text)
	if not parsed is Dictionary:
		return {
			"ok": false,
			"error": "checkpoint_invalid_json",
			"path": path
		}
	var stored_document := parsed as Dictionary
	var validation := validate_checkpoint(stored_document)
	validation["path"] = path
	if bool(validation.get("ok", false)):
		# The runtime document receives current safe defaults and new observation
		# weights, but its stored checksum is validated before that migration.
		var runtime_document := stored_document.duplicate(true)
		runtime_document["policy"] = (
			validation.get("policy", {}) as Dictionary
		).duplicate(true)
		runtime_document["model_checksum"] = str(
			validation.get("model_checksum", "")
		)
		runtime_document["checkpoint_checksum_mode"] = str(
			validation.get("checksum_mode", "unknown")
		)
		runtime_document["checkpoint_migration_required"] = bool(
			validation.get("migration_applied", false)
		)
		validation["document"] = runtime_document
	return validation


static func validate_checkpoint(document: Dictionary) -> Dictionary:
	if int(document.get("checkpoint_version", 0)) != Schema.CHECKPOINT_VERSION:
		return {
			"ok": false,
			"error": "checkpoint_version_mismatch",
			"expected": Schema.CHECKPOINT_VERSION,
			"actual": int(document.get("checkpoint_version", 0))
		}
	if int(document.get("observation_version", 0)) != Schema.OBSERVATION_VERSION:
		return {
			"ok": false,
			"error": "observation_version_mismatch",
			"expected": Schema.OBSERVATION_VERSION,
			"actual": int(document.get("observation_version", 0))
		}
	if int(document.get("action_space_version", 0)) != Schema.ACTION_SPACE_VERSION:
		return {
			"ok": false,
			"error": "action_space_version_mismatch",
			"expected": Schema.ACTION_SPACE_VERSION,
			"actual": int(document.get("action_space_version", 0))
		}

	var stored_policy_variant: Variant = document.get("policy", {})
	if not stored_policy_variant is Dictionary:
		return {"ok": false, "error": "policy_missing_or_invalid"}
	var stored_policy := (
		stored_policy_variant as Dictionary
	).duplicate(true)
	if stored_policy.is_empty():
		return {"ok": false, "error": "policy_missing_or_invalid"}
	if not _legacy_document_is_structurally_safe(
		document,
		stored_policy
	):
		return {
			"ok": false,
			"error": "checkpoint_structure_invalid"
		}

	var normalized_policy := Policy.normalize_policy_document(
		stored_policy
	)
	if normalized_policy.is_empty():
		return {"ok": false, "error": "policy_missing_or_invalid"}

	var expected_checksum := str(
		document.get("model_checksum", "")
	)
	var stored_policy_checksum := calculate_policy_checksum(
		stored_policy
	)
	var normalized_policy_checksum := calculate_policy_checksum(
		normalized_policy
	)

	var checksum_mode := "missing"
	var legacy_checksum_mismatch := false
	if expected_checksum.is_empty():
		checksum_mode = "missing"
	elif expected_checksum == stored_policy_checksum:
		checksum_mode = "exact_stored_policy"
	elif expected_checksum == normalized_policy_checksum:
		checksum_mode = "current_normalized_policy"
	else:
		# Older trainer versions calculated the checksum from a normalized
		# in-memory policy, then wrote a different/sparser policy document.
		# Later default-weight additions make that historical normalized form
		# impossible to reconstruct byte-for-byte. The document is accepted
		# only after strict version, model-type, and policy-structure checks,
		# and must be rewritten immediately by the repair/migration command.
		checksum_mode = "legacy_normalization_mismatch"
		legacy_checksum_mismatch = true

	return {
		"ok": true,
		"model_checksum": normalized_policy_checksum,
		"stored_model_checksum": expected_checksum,
		"stored_policy_checksum": stored_policy_checksum,
		"checksum_mode": checksum_mode,
		"legacy_checksum_mismatch": legacy_checksum_mismatch,
		"migration_applied": (
			legacy_checksum_mismatch
			or normalized_policy_checksum != stored_policy_checksum
			or expected_checksum != normalized_policy_checksum
		),
		"policy": normalized_policy
	}


static func _legacy_document_is_structurally_safe(
	document: Dictionary,
	policy: Dictionary
) -> bool:
	if str(document.get("model_type", "")) != (
		"hybrid_linear_tactical_policy"
	):
		return false
	if int(document.get("training_steps", 0)) < 0:
		return false
	if int(document.get("simulated_matches", 0)) < 0:
		return false
	var bias_variant: Variant = policy.get("bias", {})
	var weights_variant: Variant = policy.get("weights", {})
	if not bias_variant is Dictionary:
		return false
	if not weights_variant is Dictionary:
		return false
	var bias := bias_variant as Dictionary
	var weights := weights_variant as Dictionary
	var known_action_entries := 0
	for action in Schema.ALL_ACTIONS:
		var action_name := str(action)
		if bias.has(action_name):
			known_action_entries += 1
		if (
			weights.has(action_name)
			and weights[action_name] is Dictionary
		):
			known_action_entries += 1
	return known_action_entries >= Schema.ALL_ACTIONS.size()


static func create_checkpoint(
	policy: Dictionary,
	metadata: Dictionary = {},
	legacy_parameters: Dictionary = {}
) -> Dictionary:
	var normalized_policy := Policy.normalize_policy_document(policy)
	var created_unix := int(Time.get_unix_time_from_system())
	var document := {
		"checkpoint_version": Schema.CHECKPOINT_VERSION,
		"observation_version": Schema.OBSERVATION_VERSION,
		"action_space_version": Schema.ACTION_SPACE_VERSION,
		"model_type": "hybrid_linear_tactical_policy",
		"created_unix": created_unix,
		"training_steps": int(metadata.get("training_steps", 0)),
		"simulated_matches": int(metadata.get("simulated_matches", 0)),
		"curriculum_stage": str(metadata.get("curriculum_stage", "full_match")),
		"random_seed": int(metadata.get("random_seed", 0)),
		"reward_version": int(metadata.get("reward_version", 2)),
		"parent_checkpoint": str(metadata.get("parent_checkpoint", "")),
		"benchmark_results": metadata.get("benchmark_results", {}),
		"opponent_pool_state": metadata.get("opponent_pool_state", {}),
		"training_configuration": metadata.get("training_configuration", {}),
		"legacy_parameters": legacy_parameters.duplicate(true),
		"policy": normalized_policy
	}
	document["model_checksum"] = calculate_policy_checksum(normalized_policy)
	return document


static func save_checkpoint(path: String, document: Dictionary) -> Dictionary:
	var validation := validate_checkpoint(document)
	if not bool(validation.get("ok", false)):
		return validation

	# Every successful save rewrites the policy in the current normalized form.
	# This performs a one-way migration and gives the updated document a checksum
	# that remains tied to its exact stored bytes rather than future defaults.
	var write_document := document.duplicate(true)
	write_document["policy"] = (
		validation.get("policy", {}) as Dictionary
	).duplicate(true)
	write_document["model_checksum"] = str(
		validation.get("model_checksum", "")
	)
	var absolute_directory := ProjectSettings.globalize_path(path.get_base_dir())
	var directory_error := DirAccess.make_dir_recursive_absolute(absolute_directory)
	if directory_error != OK:
		return {
			"ok": false,
			"error": "checkpoint_directory_create_failed",
			"code": directory_error,
			"path": path
		}
	var temporary_path := path + ".tmp"
	var file := FileAccess.open(temporary_path, FileAccess.WRITE)
	if file == null:
		return {
			"ok": false,
			"error": "checkpoint_write_failed",
			"path": temporary_path
		}
	file.store_string(JSON.stringify(write_document, "\t", false))
	file.flush()
	file.close()
	var directory := DirAccess.open(path.get_base_dir())
	if directory == null:
		return {
			"ok": false,
			"error": "checkpoint_directory_open_failed",
			"path": path.get_base_dir()
		}
	var backup_path := path + ".previous"
	var moved_existing := false
	if FileAccess.file_exists(path):
		if FileAccess.file_exists(backup_path):
			directory.remove(backup_path.get_file())
		var backup_error := directory.rename(path.get_file(), backup_path.get_file())
		if backup_error != OK:
			directory.remove(temporary_path.get_file())
			return {
				"ok": false,
				"error": "checkpoint_backup_rename_failed",
				"code": backup_error,
				"path": path
			}
		moved_existing = true
	var rename_error := directory.rename(temporary_path.get_file(), path.get_file())
	if rename_error != OK:
		# Never leave the active checkpoint missing after a failed final rename.
		if moved_existing and FileAccess.file_exists(backup_path):
			directory.rename(backup_path.get_file(), path.get_file())
		return {
			"ok": false,
			"error": "checkpoint_atomic_rename_failed",
			"code": rename_error,
			"path": path
		}
	return {
		"ok": true,
		"path": path,
		"model_checksum": str(write_document.get("model_checksum", ""))
	}


static func calculate_policy_checksum(policy: Dictionary) -> String:
	var canonical := JSON.stringify(_sort_variant(policy), "", false)
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(canonical.to_utf8_buffer())
	return context.finish().hex_encode()


static func default_checkpoint() -> Dictionary:
	return create_checkpoint(
		Policy.get_default_policy_document(),
		{
			"training_steps": 0,
			"simulated_matches": 0,
			"curriculum_stage": "full_match",
			"random_seed": 104729,
			"reward_version": 2,
			"parent_checkpoint": "",
			"benchmark_results": {},
			"opponent_pool_state": {},
			"training_configuration": {"source": "safe_default"}
		}
	)


static func _sort_variant(value: Variant) -> Variant:
	if value is Dictionary:
		var source := value as Dictionary
		var keys := source.keys()
		keys.sort_custom(func(a: Variant, b: Variant) -> bool:
			return str(a) < str(b)
		)
		var result: Dictionary = {}
		for key in keys:
			result[str(key)] = _sort_variant(source[key])
		return result
	if value is Array:
		var result_array: Array = []
		for item in value as Array:
			result_array.append(_sort_variant(item))
		return result_array
	return value
