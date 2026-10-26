extends RefCounted

## Local save boundary. Keeping this separate makes cloud-save migration easier later.
const SAVE_PATH := "user://echopost_save.cfg"
const SAVE_VERSION := 2


static func load_progress(level_count: int, path: String = SAVE_PATH) -> Dictionary:
	var result := {
		"unlocked_level": 0,
		"rooms_completed": 0,
		"collected_shards": PackedInt32Array()
	}
	var config := ConfigFile.new()
	if config.load(path) == OK:
		var saved_version := int(config.get_value("meta", "save_version", 1))
		# Version 1 saves are still compatible: they simply do not contain Memory Shards yet.
		if saved_version <= SAVE_VERSION:
			result["unlocked_level"] = clampi(int(config.get_value("campaign", "unlocked_level", 0)), 0, maxi(0, level_count - 1))
			result["rooms_completed"] = maxi(0, int(config.get_value("campaign", "rooms_completed", 0)))
			var raw_shards: Variant = config.get_value("campaign", "collected_shards", PackedInt32Array())
			result["collected_shards"] = _normalize_collected_shards(raw_shards, level_count)
	return result


static func save_progress(
	unlocked_level: int,
	rooms_completed: int,
	path: String = SAVE_PATH,
	collected_shards: PackedInt32Array = PackedInt32Array()
) -> int:
	var config := ConfigFile.new()
	config.set_value("meta", "save_version", SAVE_VERSION)
	config.set_value("campaign", "unlocked_level", maxi(0, unlocked_level))
	config.set_value("campaign", "rooms_completed", maxi(0, rooms_completed))
	config.set_value("campaign", "collected_shards", _normalize_collected_shards(collected_shards, 2147483647))
	return config.save(path)


static func _normalize_collected_shards(raw_shards: Variant, level_count: int) -> PackedInt32Array:
	var normalized := PackedInt32Array()
	if raw_shards is PackedInt32Array:
		for raw_index in raw_shards:
			_append_shard_index(normalized, int(raw_index), level_count)
	elif raw_shards is Array:
		for raw_index in raw_shards:
			if raw_index is int:
				_append_shard_index(normalized, raw_index, level_count)
	normalized.sort()
	return normalized


static func _append_shard_index(shards: PackedInt32Array, shard_index: int, level_count: int) -> void:
	if shard_index < 0 or shard_index >= level_count:
		return
	if not shards.has(shard_index):
		shards.append(shard_index)
