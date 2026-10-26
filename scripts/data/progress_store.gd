extends RefCounted

## Local save boundary. Keeping this separate makes cloud-save migration easier later.
const SAVE_PATH := "user://echopost_save.cfg"
const SAVE_VERSION := 1


static func load_progress(level_count: int, path: String = SAVE_PATH) -> Dictionary:
	var result := {"unlocked_level": 0, "rooms_completed": 0}
	var config := ConfigFile.new()
	if config.load(path) == OK:
		var saved_version := int(config.get_value("meta", "save_version", 1))
		if saved_version <= SAVE_VERSION:
			result["unlocked_level"] = clampi(int(config.get_value("campaign", "unlocked_level", 0)), 0, maxi(0, level_count - 1))
			result["rooms_completed"] = maxi(0, int(config.get_value("campaign", "rooms_completed", 0)))
	return result


static func save_progress(unlocked_level: int, rooms_completed: int, path: String = SAVE_PATH) -> int:
	var config := ConfigFile.new()
	config.set_value("meta", "save_version", SAVE_VERSION)
	config.set_value("campaign", "unlocked_level", maxi(0, unlocked_level))
	config.set_value("campaign", "rooms_completed", maxi(0, rooms_completed))
	return config.save(path)
