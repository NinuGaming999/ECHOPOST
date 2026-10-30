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
	_check(LevelCatalog.LEVELS.size() >= 13, "The campaign should contain at least thirteen chambers after the echo-jammer lesson.")
	_check(LevelCatalog.validate_levels().is_empty(), "The campaign catalog should pass its own level-data validator.")
	var names_seen: Dictionary = {}
	var relay_room_found := false
	var ordered_relay_room_found := false
	var timed_gate_room_found := false
	var triple_relay_room_found := false
	var triune_relay_room_found := false
	var relay_timer_combo_found := false
	var fracture_clock_room_found := false
	var dead_air_room_found := false
	var four_relay_hunt_found := false
	var echo_jammer_room_found := false
	for index in range(LevelCatalog.LEVELS.size()):
		var level: Dictionary = LevelCatalog.get_level(index)
		var level_name := str(level.get("name", ""))
		if level_name == "Triune Relay":
			triune_relay_room_found = true
			_check(level.has("echo_waypoints") and level["echo_waypoints"] is Array and level["echo_waypoints"].size() == 3, "Triune Relay should define exactly three ordered checkpoints.")
		if level_name == "Fracture Clock":
			fracture_clock_room_found = true
			_check(level.has("echo_waypoints") and level["echo_waypoints"] is Array and level["echo_waypoints"].size() == 3, "Fracture Clock should retain its three-relay route.")
			_check(is_equal_approx(float(level.get("gate_open_seconds", 0.0)), 4.5), "Fracture Clock should retain its 4.5-second window.")
		if level_name == "Dead Air Protocol":
			dead_air_room_found = true
			_check(level.has("echo_waypoints") and level["echo_waypoints"] is Array and level["echo_waypoints"].size() == 4, "Dead Air Protocol should define four ordered relays.")
			_check(level.has("plate_b") and level["plate_b"] is Vector2 and is_equal_approx(float(level["plate_b"].x), 850.0), "Dead Air Protocol should place Switch B far enough from the gate to require a real crossing run.")
			_check(bool(level.get("hazard", false)), "Dead Air Protocol should keep its active sentinel.")
			_check(is_equal_approx(float(level.get("gate_open_seconds", 0.0)), 1.8), "Dead Air Protocol should use a 1.8-second gate window.")
			_check(is_equal_approx(float(level.get("linger", 0.0)), 6.5), "Dead Air Protocol should use its shorter 6.5-second echo linger.")
		if level_name == "Null Corridor":
			echo_jammer_room_found = true
			_check(level.get("echo_jammer") is Vector2, "Null Corridor should define an echo-only jammer position.")
			_check(is_equal_approx(float(level.get("echo_jammer_radius", 0.0)), 105.0), "Null Corridor should expose a clear 105-unit echo dead zone.")
			_check(str(level.get("hint", "")).contains("ECHO DEAD ZONE"), "Null Corridor's hint should explain the jammer rule.")
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
				if level["echo_waypoints"].size() >= 3:
					triple_relay_room_found = true
				for waypoint in level["echo_waypoints"]:
					_check(waypoint is Vector2, "Every ordered relay checkpoint must use a Vector2 position.")
		if level.has("gate_open_seconds"):
			timed_gate_room_found = true
			if level.has("echo_waypoints") and level["echo_waypoints"] is Array and level["echo_waypoints"].size() >= 3:
				relay_timer_combo_found = true
				if bool(level.get("hazard", false)) and level["echo_waypoints"].size() >= 4:
					four_relay_hunt_found = true
					_check(str(level_name) == "Dead Air Protocol", "The four-relay sentinel/timed-gate challenge should be named Dead Air Protocol.")
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
	_check(triple_relay_room_found, "The campaign should include a three-relay route challenge.")
	_check(triune_relay_room_found, "The campaign should include Triune Relay as a named authored room.")
	_check(relay_timer_combo_found, "The campaign should combine three ordered relays with a timed gate in at least one room.")
	_check(fracture_clock_room_found, "The campaign should retain Fracture Clock as the three-relay timed-gate lesson.")
	_check(dead_air_room_found, "The campaign should include the named Dead Air Protocol challenge.")
	_check(four_relay_hunt_found, "The campaign should combine four ordered relays, an active sentinel, and a timed gate.")
	_check(echo_jammer_room_found, "The campaign should include Null Corridor as a named echo-jammer challenge.")
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
	malformed_level["echo_jammer"] = "not a Vector2"
	malformed_level["echo_jammer_radius"] = 20.0
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
	_check(_has_error(errors, "echo_jammer must be a Vector2"), "Validator should reject malformed jammer positions.")
	_check(_has_error(errors, "echo_jammer_radius must be between 40 and 180 units"), "Validator should reject invalid jammer radii.")
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
	_check(bool(defaults["performance_mode"]), "New settings should default to Performance Mode for weak-device headroom.")

	var save_error := SettingsStore.save_settings(200.0, true, TEST_SETTINGS_PATH, false)
	_check(save_error == OK, "Control settings should save to their own preferences file.")
	var saved: Dictionary = SettingsStore.load_settings(TEST_SETTINGS_PATH)
	_check(is_equal_approx(float(saved["move_speed"]), 200.0), "Settings should preserve the selected slow movement preset.")
	_check(bool(saved["left_handed_controls"]), "Settings should preserve left-handed joystick preference.")
	_check(not bool(saved["performance_mode"]), "Settings should preserve the selected full-visual mode.")

	# Unsupported values are normalized to the nearest supported preset rather than saved as arbitrary speeds.
	save_error = SettingsStore.save_settings(999.0, false, TEST_SETTINGS_PATH)
	_check(save_error == OK, "Settings normalization should still produce a writable preferences file.")
	var normalized: Dictionary = SettingsStore.load_settings(TEST_SETTINGS_PATH)
	_check(is_equal_approx(float(normalized["move_speed"]), 310.0), "Out-of-range movement speeds should normalize to the fast preset.")
	_check(not bool(normalized["left_handed_controls"]), "Left-handed preference should be independently changeable.")
	_check(bool(normalized["performance_mode"]), "An omitted Performance Mode value should safely default to ON.")

	var user_directory := DirAccess.open("user://")
	if user_directory != null:
		user_directory.remove("echopost_settings_smoke_test.cfg")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
