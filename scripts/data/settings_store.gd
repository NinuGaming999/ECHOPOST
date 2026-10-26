extends RefCounted

## Small, separate preferences file so accessibility choices never reset campaign progress.
const SETTINGS_PATH := "user://echopost_settings.cfg"
const DEFAULT_MOVE_SPEED := 255.0
const SPEED_PRESETS: Array[float] = [200.0, 255.0, 310.0]


static func load_settings(path: String = SETTINGS_PATH) -> Dictionary:
	var result := {
		"move_speed": DEFAULT_MOVE_SPEED,
		"left_handed_controls": false
	}
	var config := ConfigFile.new()
	if config.load(path) != OK:
		return result

	result["move_speed"] = _normalize_move_speed(float(config.get_value("controls", "move_speed", DEFAULT_MOVE_SPEED)))
	result["left_handed_controls"] = bool(config.get_value("controls", "left_handed_controls", false))
	return result


static func save_settings(move_speed: float, left_handed_controls: bool, path: String = SETTINGS_PATH) -> int:
	var config := ConfigFile.new()
	config.set_value("meta", "settings_version", 1)
	config.set_value("controls", "move_speed", _normalize_move_speed(move_speed))
	config.set_value("controls", "left_handed_controls", left_handed_controls)
	return config.save(path)


static func _normalize_move_speed(raw_speed: float) -> float:
	var closest_speed := DEFAULT_MOVE_SPEED
	var closest_distance := INF
	for preset in SPEED_PRESETS:
		var distance := absf(raw_speed - preset)
		if distance < closest_distance:
			closest_distance = distance
			closest_speed = preset
	return closest_speed
