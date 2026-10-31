extends RefCounted

## Small, separate preferences file so accessibility choices never reset campaign progress.
const SETTINGS_PATH := "user://echopost_settings.cfg"
const DEFAULT_MOVE_SPEED := 255.0
const SPEED_PRESETS: Array[float] = [200.0, 255.0, 310.0]


static func load_settings(path: String = SETTINGS_PATH) -> Dictionary:
	var result := {
		"move_speed": DEFAULT_MOVE_SPEED,
		"left_handed_controls": false,
		"performance_mode": true,
		"reduced_motion": false,
		"music_enabled": true,
		"sfx_enabled": true,
		"haptics_enabled": false,
		"music_volume": 0.14125375,
		"sfx_volume": 0.89125094
	}
	var config := ConfigFile.new()
	if config.load(path) != OK:
		return result

	result["move_speed"] = _normalize_move_speed(float(config.get_value("controls", "move_speed", DEFAULT_MOVE_SPEED)))
	result["left_handed_controls"] = bool(config.get_value("controls", "left_handed_controls", false))
	result["performance_mode"] = bool(config.get_value("graphics", "performance_mode", true))
	# Older preference files omit this key and receive the safe default.
	result["reduced_motion"] = bool(config.get_value("accessibility", "reduced_motion", false))
	# Audio switches and haptics were introduced in v4; missing keys use safe defaults.
	result["music_enabled"] = bool(config.get_value("audio", "music_enabled", true))
	result["sfx_enabled"] = bool(config.get_value("audio", "sfx_enabled", true))
	result["haptics_enabled"] = bool(config.get_value("accessibility", "haptics_enabled", false))
	# v1-v4 files retain their previous loudness levels unless a saved slider value exists.
	result["music_volume"] = _normalize_volume(float(config.get_value("audio", "music_volume", 0.14125375)))
	result["sfx_volume"] = _normalize_volume(float(config.get_value("audio", "sfx_volume", 0.89125094)))
	return result


static func save_settings(
	move_speed: float,
	left_handed_controls: bool,
	path: String = SETTINGS_PATH,
	performance_mode: bool = true,
	reduced_motion: bool = false,
	music_enabled: bool = true,
	sfx_enabled: bool = true,
	haptics_enabled: bool = false,
	music_volume: float = 0.14125375,
	sfx_volume: float = 0.89125094
) -> int:
	var config := ConfigFile.new()
	config.set_value("meta", "settings_version", 5)
	config.set_value("controls", "move_speed", _normalize_move_speed(move_speed))
	config.set_value("controls", "left_handed_controls", left_handed_controls)
	config.set_value("graphics", "performance_mode", performance_mode)
	config.set_value("accessibility", "reduced_motion", reduced_motion)
	config.set_value("audio", "music_enabled", music_enabled)
	config.set_value("audio", "sfx_enabled", sfx_enabled)
	config.set_value("audio", "music_volume", _normalize_volume(music_volume))
	config.set_value("audio", "sfx_volume", _normalize_volume(sfx_volume))
	config.set_value("accessibility", "haptics_enabled", haptics_enabled)
	return config.save(path)


static func _normalize_volume(raw_volume: float) -> float:
	return clampf(raw_volume, 0.0, 1.0)


static func _normalize_move_speed(raw_speed: float) -> float:
	var closest_speed := DEFAULT_MOVE_SPEED
	var closest_distance := INF
	for preset in SPEED_PRESETS:
		var distance := absf(raw_speed - preset)
		if distance < closest_distance:
			closest_distance = distance
			closest_speed = preset
	return closest_speed
