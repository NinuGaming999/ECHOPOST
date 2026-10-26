extends SceneTree

## Dependency-free smoke tests for the data layer. Run with:
## godot --headless --path . --script res://tests/headless_smoke.gd
const EchoTrackScript = preload("res://scripts/core/echo_track.gd")
const LevelCatalog = preload("res://scripts/data/level_catalog.gd")
const ProgressStore = preload("res://scripts/data/progress_store.gd")
const TEST_SAVE_PATH := "user://echopost_smoke_test_save.cfg"

var failures: int = 0


func _initialize() -> void:
	_test_echo_track()
	_test_level_catalog()
	_test_progress_store()
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
	_check(LevelCatalog.LEVELS.size() >= 6, "The early campaign should contain at least six chambers.")
	_check(LevelCatalog.validate_levels().is_empty(), "The campaign catalog should pass its own level-data validator.")
	var names_seen: Dictionary = {}
	for index in range(LevelCatalog.LEVELS.size()):
		var level: Dictionary = LevelCatalog.get_level(index)
		var level_name := str(level.get("name", ""))
		_check(not level_name.is_empty(), "Every chamber needs a non-empty name.")
		_check(not names_seen.has(level_name), "Chamber names must be unique: %s" % level_name)
		names_seen[level_name] = true
		_check(level.has("name"), "Each level needs a display name.")
		_check(level.has("spawn"), "Each level needs a spawn position.")
		_check(level.has("plate_a") and level.has("plate_b"), "Each level needs both switch positions.")
		_check(float(level.get("linger", 0.0)) > 0.0, "Each level needs a positive echo linger duration.")
		_check(level["spawn"] is Vector2, "Spawn positions must be Vector2 values.")
	var original_name := str(LevelCatalog.LEVELS[0]["name"])
	var isolated_copy: Dictionary = LevelCatalog.get_level(0)
	isolated_copy["name"] = "Changed only in this test copy"
	_check(str(LevelCatalog.LEVELS[0]["name"]) == original_name, "Level reads must not mutate canonical campaign data.")


func _test_progress_store() -> void:
	var save_error: int = ProgressStore.save_progress(2, 7, TEST_SAVE_PATH)
	_check(save_error == OK, "Progress data should be saved successfully.")
	var progress: Dictionary = ProgressStore.load_progress(3, TEST_SAVE_PATH)
	_check(int(progress["unlocked_level"]) == 2, "The save should preserve the unlocked level.")
	_check(int(progress["rooms_completed"]) == 7, "The save should preserve completed-room count.")
	var limited_progress: Dictionary = ProgressStore.load_progress(2, TEST_SAVE_PATH)
	_check(int(limited_progress["unlocked_level"]) == 1, "Progress should be clamped when the campaign is smaller.")
	var user_directory := DirAccess.open("user://")
	if user_directory != null:
		user_directory.remove("echopost_smoke_test_save.cfg")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
