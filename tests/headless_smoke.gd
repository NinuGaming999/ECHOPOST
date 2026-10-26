extends SceneTree

## Dependency-free smoke tests for the data layer. Run with:
## godot --headless --path . --script res://tests/headless_smoke.gd
const EchoTrackScript = preload("res://scripts/core/echo_track.gd")
const LevelCatalog = preload("res://scripts/data/level_catalog.gd")
const ProgressStore = preload("res://scripts/data/progress_store.gd")
const SettingsStore = preload("res://scripts/data/settings_store.gd")
const TEST_SAVE_PATH := "user://echopost_smoke_test_save.cfg"
const TEST_SETTINGS_PATH := "user://echopost_settings_smoke_test.cfg"

var failures: int = 0


func _initialize() -> void:
	_test_echo_track()
	_test_level_catalog()
	_test_progress_store()
	_test_settings_store()
	if failures == 0:
		print("ECHOPOST smoke tests passed.")
		quit(0)
	else:
		push_error("ECHOPOST smoke tests failed: %d" % failures)
		quit(1)


func _test_echo_track() -> void:
	var track = EchoTrackScript.new()
	_check(track.samples.is_empty(), "A new echo track should be empty.")
	_check(track.duration() == 0.0, "An empty track should have zero duration.")

	track.add_sample(0.0, Vector2(0, 0))
	track.add_sample(1.0, Vector2(100, 0))
	track.add_sample(0.5, Vector2(120, 0))
	_check(is_equal_approx(float(track.samples[2]["t"]), 1.0), "Sample timestamps must never move backwards.")
	_check(is_equal_approx(track.duration(), 1.0), "Track duration should come from its final timestamp.")
	_check(track.position_at(0.0).is_equal_approx(Vector2.ZERO), "Playback should start at the first point.")
	_check(track.position_at(0.5).is_equal_approx(Vector2(50, 0)), "Playback should interpolate smoothly between samples.")
	_check(track.position_at(2.0).is_equal_approx(Vector2(120, 0)), "Playback after the end should hold the final point.")

	var copy = track.copy_track()
	_check(copy.get_script() == EchoTrackScript, "Copied tracks must use their preloaded script resource without global class-name lookup.")
	copy.add_sample(2.0, Vector2(200, 0))
	_check(copy.samples.size() == 4, "The copy should accept new samples.")
	_check(track.samples.size() == 3, "Copying a track must not mutate the source track.")
	_check(is_equal_approx(copy.position_at(2.0).x, 200.0), "Copied tracks should interpolate and hold their own final position.")


func _test_level_catalog() -> void:
	_check(LevelCatalog.LEVELS.size() >= 8, "The early campaign should contain at least eight chambers.")
	_check(LevelCatalog.validate_levels().is_empty(), "The campaign catalog should pass its own level-data validator.")
	var names_seen: Dictionary = {}
	var relay_room_found := false
	var ordered_relay_room_found := false
	var timed_gate_room_found := false
	for index in range(LevelCatalog.LEVELS.size()):
		var level: Dictionary = LevelCatalog.get_level(index)
		var level_name := str(level.get("name", ""))
		_check(not level_name.is_empty(), "Every chamber needs a non-empty name.")
		_check(not names_seen.has(level_name), "Chamber names must be unique: %s" % level_name)
		names_seen[level_name] = true
		if level.has("echo_waypoint"):
			relay_room_found = true
			_check(level["echo_waypoint"] is Vector2, "Optional echo waypoints must use Vector2 positions.")
		if level.has("echo_waypoints"):
			ordered_relay_room_found = true
			_check(level["echo_waypoints"] is Array, "Ordered relay checkpoints must be stored as an Array.")
			if level["echo_waypoints"] is Array:
				_check(level["echo_waypoints"].size() >= 2, "An ordered relay room should require at least two checkpoints.")
				for waypoint in level["echo_waypoints"]:
					_check(waypoint is Vector2, "Every ordered relay checkpoint must use a Vector2 position.")
		if level.has("gate_open_seconds"):
			timed_gate_room_found = true
			var gate_duration: Variant = level["gate_open_seconds"]
			_check(gate_duration is int or gate_duration is float, "Timed gate duration must be numeric.")
			if gate_duration is int or gate_duration is float:
				_check(float(gate_duration) >= 1.0 and float(gate_duration) <= 15.0, "Timed gate duration must be between one and fifteen seconds.")
		_check(level.has("name"), "Each level needs a display name.")
		_check(level.has("spawn"), "Each level needs a spawn position.")
		_check(level.has("plate_a") and level.has("plate_b"), "Each level needs both switch positions.")
		_check(level.has("memory_shard") and level["memory_shard"] is Vector2, "Each level needs a Memory Shard position.")
		_check(not str(level.get("shard_lore", "")).strip_edges().is_empty(), "Each Memory Shard needs a lore fragment.")
		_check(float(level.get("linger", 0.0)) > 0.0, "Each level needs a positive echo linger duration.")
		_check(level["spawn"] is Vector2, "Spawn positions must be Vector2 values.")
	_check(relay_room_found, "The early campaign should include at least one single-relay room.")
	_check(ordered_relay_room_found, "The early campaign should include a room with multiple ordered relay checkpoints.")
	_check(timed_gate_room_found, "The early campaign should include a timed-gate room.")
	var original_name := str(LevelCatalog.LEVELS[0]["name"])
	var isolated_copy: Dictionary = LevelCatalog.get_level(0)
	isolated_copy["name"] = "Changed only in this test copy"
	_check(str(LevelCatalog.LEVELS[0]["name"]) == original_name, "Level reads must not mutate canonical campaign data.")
	_test_level_validator_rejects_bad_drafts()


func _test_level_validator_rejects_bad_drafts() -> void:
	var original_level := LevelCatalog.get_level(0)
	var malformed_level := LevelCatalog.get_level(1)
	malformed_level["name"] = original_level["name"]
	malformed_level["spawn"] = Vector2(210, 210)
	malformed_level["plate_a"] = Vector2(210, 210)
	malformed_level["plate_b"] = Vector2(220, 210)
	malformed_level["hazard_speed"] = -1.0
	malformed_level["echo_waypoint"] = Vector2(-20, 220)
	malformed_level["echo_waypoints"] = [Vector2(-20, 220), "not a point"]
	malformed_level["gate_open_seconds"] = -1.0
	var draft_levels: Array[Dictionary] = [original_level, malformed_level]
	var errors: PackedStringArray = LevelCatalog.validate_level_list(draft_levels)

	_check(_has_error(errors, "duplicate chamber name"), "Validator should reject duplicate chamber names.")
	_check(_has_error(errors, "too close for a meaningful"), "Validator should reject a spawn too close to Switch A.")
	_check(_has_error(errors, "must be separated by at least 86"), "Validator should reject overlapping switch positions.")
	_check(_has_error(errors, "sentinel speed must be greater"), "Validator should reject non-positive sentinel speed.")
	_check(_has_error(errors, "echo_waypoint is outside the playable room"), "Validator should reject a relay beacon outside room bounds.")
	_check(_has_error(errors, "echo_waypoints[0] is outside the playable room"), "Validator should reject an ordered relay outside room bounds.")
	_check(_has_error(errors, "echo_waypoints[1] must be a Vector2"), "Validator should reject malformed waypoint types.")
	_check(_has_error(errors, "gate_open_seconds must be between 1 and 15 seconds"), "Validator should reject invalid timed-gate durations.")


func _has_error(errors: PackedStringArray, fragment: String) -> bool:
	for error_text in errors:
		if error_text.contains(fragment):
			return true
	return false



func _test_progress_store() -> void:
	var save_error: int = ProgressStore.save_progress(2, 7, TEST_SAVE_PATH)
	_check(save_error == OK, "Progress data should be saved successfully.")
	var progress: Dictionary = ProgressStore.load_progress(3, TEST_SAVE_PATH)
	_check(int(progress["unlocked_level"]) == 2, "The save should preserve the unlocked level.")
	_check(int(progress["rooms_completed"]) == 7, "The save should preserve completed-room count.")
	var limited_progress: Dictionary = ProgressStore.load_progress(2, TEST_SAVE_PATH)
	_check(int(limited_progress["unlocked_level"]) == 1, "Progress should be clamped when the campaign is smaller.")

	# Version 2 persists optional Memory Shards and sanitizes duplicate/out-of-range indices.
	var expected_shards := PackedInt32Array([0, 2, 2, 99, -1])
	save_error = ProgressStore.save_progress(1, 9, TEST_SAVE_PATH, expected_shards)
	_check(save_error == OK, "Progress with collected Memory Shards should save successfully.")
	var shard_progress: Dictionary = ProgressStore.load_progress(3, TEST_SAVE_PATH)
	var saved_shards: PackedInt32Array = shard_progress["collected_shards"]
	_check(saved_shards.size() == 2 and saved_shards.has(0) and saved_shards.has(2), "Shard saves should be unique, sorted, and clamped to existing rooms.")

	# A version 1 save from before collectibles existed must still load without losing campaign progress.
	var legacy_config := ConfigFile.new()
	legacy_config.set_value("meta", "save_version", 1)
	legacy_config.set_value("campaign", "unlocked_level", 1)
	legacy_config.set_value("campaign", "rooms_completed", 4)
	_check(legacy_config.save(TEST_SAVE_PATH) == OK, "A legacy v1 test save should be written.")
	var legacy_progress: Dictionary = ProgressStore.load_progress(6, TEST_SAVE_PATH)
	_check(int(legacy_progress["unlocked_level"]) == 1 and int(legacy_progress["rooms_completed"]) == 4, "Version 1 saves should preserve existing campaign progress.")
	var legacy_shards: PackedInt32Array = legacy_progress["collected_shards"]
	_check(legacy_shards.is_empty(), "Version 1 saves should default to no Memory Shards collected.")

	var user_directory := DirAccess.open("user://")
	if user_directory != null:
		user_directory.remove("echopost_smoke_test_save.cfg")



func _test_settings_store() -> void:
	var defaults: Dictionary = SettingsStore.load_settings(TEST_SETTINGS_PATH)
	_check(is_equal_approx(float(defaults["move_speed"]), 255.0), "Missing settings should default to normal movement speed.")
	_check(not bool(defaults["left_handed_controls"]), "Missing settings should default to the standard left-side joystick.")

	var save_error := SettingsStore.save_settings(200.0, true, TEST_SETTINGS_PATH)
	_check(save_error == OK, "Control settings should save to their own preferences file.")
	var saved: Dictionary = SettingsStore.load_settings(TEST_SETTINGS_PATH)
	_check(is_equal_approx(float(saved["move_speed"]), 200.0), "Settings should preserve the selected slow movement preset.")
	_check(bool(saved["left_handed_controls"]), "Settings should preserve left-handed joystick preference.")

	# Unsupported values are normalized to the nearest supported preset rather than saved as arbitrary speeds.
	save_error = SettingsStore.save_settings(999.0, false, TEST_SETTINGS_PATH)
	_check(save_error == OK, "Settings normalization should still produce a writable preferences file.")
	var normalized: Dictionary = SettingsStore.load_settings(TEST_SETTINGS_PATH)
	_check(is_equal_approx(float(normalized["move_speed"]), 310.0), "Out-of-range movement speeds should normalize to the fast preset.")
	_check(not bool(normalized["left_handed_controls"]), "Left-handed preference should be independently changeable.")

	var user_directory := DirAccess.open("user://")
	if user_directory != null:
		user_directory.remove("echopost_settings_smoke_test.cfg")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
