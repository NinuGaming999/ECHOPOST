extends SceneTree

## Integration smoke test for the main scene's echo puzzle flow.
## Tests the full puzzle flow and restores the saved campaign values after portal completion.
const MainScene = preload("res://scenes/main.tscn")
const EchoTrackScript = preload("res://scripts/core/echo_track.gd")
const LevelCatalog = preload("res://scripts/data/level_catalog.gd")
const ProgressStore = preload("res://scripts/data/progress_store.gd")

var failures: int = 0


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var game: Control = MainScene.instantiate()
	root.add_child(game)
	await process_frame

	_test_chapter_select_layout(game)
	_test_memory_shard_collection(game)
	_test_memory_archive_ui(game)
	game.call("_start_level", 0)
	_check(int(game.get("screen_state")) == 1, "Starting a chamber should switch the game to PLAYING.")

	_test_lifecycle_pause(game)
	game.call("_start_level", 0)

	_test_recording_duration_limit(game)
	game.call("_start_level", 0)
	_test_too_short_recording(game)
	_test_sentinel_reset(game)
	_test_restart_clears_state(game)
	_test_portal_completion_is_idempotent(game)
	game.call("_start_level", 0)

	var invalid_track = EchoTrackScript.new()
	invalid_track.add_sample(0.0, Vector2(160, 365))
	invalid_track.add_sample(1.0, Vector2(845, 365))
	game.set("recording_track", invalid_track)
	game.set("recording_elapsed", 1.0)
	game.set("is_recording", true)
	game.set("player_position", Vector2(845, 365))
	game.call("_finish_recording")
	_check(not bool(game.get("is_recording")), "Finishing a recording should stop record mode.")
	_check(not bool(game.get("echo_visible")), "A route ending away from Switch A must not create an echo.")
	_check(str(game.get("status_message")).begins_with("ROUTE REJECTED"), "Rejected routes should explain why they failed.")

	var valid_track = EchoTrackScript.new()
	valid_track.add_sample(0.0, Vector2(160, 365))
	valid_track.add_sample(1.0, Vector2(430, 365))
	game.set("recording_track", valid_track)
	game.set("recording_elapsed", 1.0)
	game.set("is_recording", true)
	game.set("player_position", Vector2(430, 365))
	game.call("_finish_recording")
	_check(bool(game.get("echo_visible")), "A route ending on Switch A should create a visible echo.")
	_check(bool(game.get("echo_playing")), "An accepted route should begin replaying.")

	game.set("echo_playing", false)
	game.set("echo_position", Vector2(430, 365))
	game.set("echo_visible", true)
	game.set("player_position", Vector2(845, 365))
	game.call("_check_puzzle_state")
	_check(bool(game.get("door_open")), "An echo on Switch A and the player on Switch B should open the gate.")
	_check(str(game.get("status_message")).contains("GATE OPEN"), "Gate activation should provide feedback.")

	game.queue_free()
	await process_frame
	if failures == 0:
		print("ECHOPOST game-flow smoke tests passed.")
		quit(0)
	else:
		push_error("ECHOPOST game-flow smoke tests failed: %d" % failures)
		quit(1)



func _test_lifecycle_pause(game: Control) -> void:
	game.set("is_recording", true)
	game.set("recording_elapsed", 1.25)
	game.set("joystick_direction", Vector2.RIGHT)
	game.call("_notification", Node.NOTIFICATION_APPLICATION_PAUSED)
	_check(int(game.get("screen_state")) == 2, "Application suspension should pause active gameplay.")
	_check(game.get("joystick_direction") == Vector2.ZERO, "Lifecycle pause should clear movement input.")
	_check(bool(game.get("is_recording")), "Lifecycle pause should preserve an in-progress recording.")
	_check(is_equal_approx(float(game.get("recording_elapsed")), 1.25), "Lifecycle pause should preserve recording time.")
	game.call("_process", 1.0)
	_check(is_equal_approx(float(game.get("recording_elapsed")), 1.25), "Game timers should not advance while paused.")
	game.call("_notification", Node.NOTIFICATION_APPLICATION_RESUMED)
	_check(int(game.get("screen_state")) == 2, "Returning to the app should not resume gameplay without player input.")
	game.call("_on_pause_pressed")
	_check(int(game.get("screen_state")) == 1, "The player should be able to resume gameplay explicitly.")
	_check(not bool(game.get("joystick_mouse_active")), "Resume must not reactivate a stale joystick press.")


func _test_recording_duration_limit(game: Control) -> void:
	var track = EchoTrackScript.new()
	track.add_sample(0.0, Vector2(160, 365))
	game.set("recording_track", track)
	game.set("recording_elapsed", 7.99)
	game.set("record_sample_accumulator", 0.0)
	game.set("is_recording", true)
	game.set("player_position", Vector2(430, 365))

	# _process clamps delta to 0.05 seconds; deliberately start close to the cap
	# to catch any frame-step overshoot beyond the configured maximum.
	game.call("_process", 1.0)
	_check(not bool(game.get("is_recording")), "Recording should auto-stop at the maximum duration.")
	_check(bool(game.get("echo_visible")), "A max-duration route ending on Switch A should still create an echo.")
	var finished_track = game.get("echo_track")
	_check(is_equal_approx(float(finished_track.duration()), 8.0), "The saved echo route must never exceed eight seconds.")


func _test_too_short_recording(game: Control) -> void:
	var track = EchoTrackScript.new()
	track.add_sample(0.0, Vector2(160, 365))
	game.set("recording_track", track)
	game.set("recording_elapsed", 0.2)
	game.set("record_sample_accumulator", 0.0)
	game.set("is_recording", true)
	game.set("player_position", Vector2(430, 365))
	game.call("_finish_recording")
	_check(bool(game.get("is_recording")), "A too-short stop should let the player continue recording rather than silently discard the route.")
	_check(not bool(game.get("echo_visible")), "A too-short recording must not create an echo.")
	_check(str(game.get("status_message")).begins_with("TOO SHORT"), "A too-short recording should clearly explain how to continue.")


func _test_sentinel_reset(game: Control) -> void:
	game.call("_start_level", 1)
	game.set("hazard_time", 0.0)
	game.set("player_position", Vector2(640, 380))
	var level: Dictionary = game.get("level_data")
	var expected_spawn: Vector2 = level["spawn"]
	game.call("_check_sentinel_collision")
	_check(game.get("player_position") == expected_spawn, "Sentinel contact should return the player to the room spawn.")
	_check(str(game.get("status_message")).begins_with("SENTINEL CONTACT"), "Sentinel contact should explain why the player was reset.")

	# A recording interrupted by a sentinel must not contain a fake teleport to spawn.
	var interrupted_track = EchoTrackScript.new()
	interrupted_track.add_sample(0.0, Vector2(500, 380))
	interrupted_track.add_sample(1.0, Vector2(640, 380))
	game.set("recording_track", interrupted_track)
	game.set("is_recording", true)
	game.set("recording_elapsed", 1.4)
	game.set("record_sample_accumulator", 0.03)
	game.set("player_position", Vector2(640, 380))
	game.set("hazard_time", 0.0)
	game.call("_check_sentinel_collision")
	var cleared_track = game.get("recording_track")
	_check(not bool(game.get("is_recording")), "Sentinel contact should cancel an active recording.")
	_check(is_zero_approx(float(game.get("recording_elapsed"))), "Sentinel contact should reset recording time.")
	_check(is_zero_approx(float(game.get("record_sample_accumulator"))), "Sentinel contact should reset the sample accumulator.")
	_check(cleared_track.samples.is_empty(), "Sentinel contact should clear the interrupted route instead of recording a teleport.")
	_check(str(game.get("status_message")).contains("recording lost"), "The collision message should explain that the interrupted recording was lost.")


func _test_restart_clears_state(game: Control) -> void:
	game.call("_start_level", 0)
	var expected_spawn: Vector2 = game.get("level_data")["spawn"]
	var recording = EchoTrackScript.new()
	recording.add_sample(0.0, expected_spawn)
	recording.add_sample(1.0, Vector2(430, 365))
	var echo = EchoTrackScript.new()
	echo.add_sample(0.0, expected_spawn)
	echo.add_sample(1.0, Vector2(430, 365))

	game.set("is_recording", true)
	game.set("recording_elapsed", 1.75)
	game.set("record_sample_accumulator", 0.03)
	game.set("recording_track", recording)
	game.set("echo_track", echo)
	game.set("echo_visible", true)
	game.set("echo_playing", true)
	game.set("echo_elapsed", 0.5)
	game.set("echo_linger_left", 4.0)
	game.set("door_open", true)
	game.set("joystick_direction", Vector2.RIGHT)
	game.call("_on_reset_pressed")

	_check(int(game.get("screen_state")) == 1, "Restart should return the chamber to PLAYING.")
	_check(game.get("player_position") == expected_spawn, "Restart should return the player to the authored spawn.")
	_check(not bool(game.get("is_recording")), "Restart should stop an in-progress recording.")
	_check(is_zero_approx(float(game.get("recording_elapsed"))), "Restart should reset the recording timer.")
	_check((game.get("recording_track") as RefCounted).get("samples").is_empty(), "Restart should clear the unsubmitted recording track.")
	_check(not bool(game.get("echo_visible")) and not bool(game.get("echo_playing")), "Restart should hide and stop an echo.")
	_check((game.get("echo_track") as RefCounted).get("samples").is_empty(), "Restart should clear the previous echo track.")
	_check(not bool(game.get("door_open")), "Restart should close the gate again.")
	_check(game.get("joystick_direction") == Vector2.ZERO, "Restart should clear held joystick direction.")

	# The restart button is also available from a paused chamber; it must recover a clean playable state.
	game.call("_on_pause_pressed")
	game.call("_on_reset_pressed")
	_check(int(game.get("screen_state")) == 1, "Restarting a paused chamber should return to PLAYING.")
	_check(not bool(game.get("is_recording")) and not bool(game.get("echo_visible")), "Restart from pause should also clear recording and echo state.")


func _test_portal_completion_is_idempotent(game: Control) -> void:
	# Save the in-memory campaign values so this integration test restores the user's actual
	# progress file after exercising the real completion/save path.
	var previous_unlocked := int(game.get("unlocked_level"))
	var previous_completed := int(game.get("rooms_completed"))
	game.call("_start_level", 0)
	game.set("door_open", true)
	game.set("player_position", Vector2(1170, 365))
	game.call("_check_puzzle_state")

	_check(int(game.get("screen_state")) == 3, "Entering the powered portal should complete the chamber.")
	_check(bool(game.get("complete_panel").visible), "Portal completion should show the completion panel.")
	_check(int(game.get("rooms_completed")) == previous_completed + 1, "Completing a chamber should count exactly one completion.")
	var completed_count := int(game.get("rooms_completed"))

	# Calling the state checker again must not award a second completion or write an extra count.
	game.call("_check_puzzle_state")
	_check(int(game.get("rooms_completed")) == completed_count, "Repeated portal checks must not count a completed chamber twice.")

	# Restore the original persisted campaign values so running tests never permanently advances a save.
	game.set("unlocked_level", previous_unlocked)
	game.set("rooms_completed", previous_completed)
	game.call("_save_progress")
	game.call("_update_menu_progress")


func _test_chapter_select_layout(game: Control) -> void:
	game.call("_open_level_select")
	var panel: Panel = game.get("level_select_panel")
	var scroll_node := panel.get_node_or_null("ChapterScroll")
	_check(scroll_node is ScrollContainer, "Chapter select should use a ScrollContainer so longer campaigns do not overlap navigation.")
	var buttons: Array = game.get("chapter_buttons")
	_check(buttons.size() == LevelCatalog.LEVELS.size(), "Chapter select should create one button for every campaign chamber.")

	if scroll_node is ScrollContainer:
		var scroll := scroll_node as ScrollContainer
		_check(scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_AUTO, "Chapter select should enable vertical scrolling when content exceeds the viewport.")
		var list_node := scroll.get_node_or_null("ChapterList")
		_check(list_node is VBoxContainer, "Scrollable chapter rows should use a VBoxContainer.")
		if list_node is VBoxContainer:
			_check(list_node.get_child_count() == LevelCatalog.LEVELS.size(), "The scroll list should contain every authored chamber.")
	game.call("_show_menu")



func _test_memory_shard_collection(game: Control) -> void:
	# Temporarily make room 1's shard uncollected, then restore all saved campaign fields.
	var previous_unlocked := int(game.get("unlocked_level"))
	var previous_completed := int(game.get("rooms_completed"))
	var previous_shards: PackedInt32Array = game.get("collected_shards")
	var test_shards: PackedInt32Array = previous_shards.duplicate()
	var existing_index := test_shards.find(0)
	if existing_index >= 0:
		test_shards.remove_at(existing_index)
	game.set("collected_shards", test_shards)

	game.call("_start_level", 0)
	var room: Dictionary = game.get("level_data")
	var shard_position: Vector2 = room["memory_shard"]
	game.set("player_position", shard_position)
	game.call("_check_memory_shard_collection")

	var collected: PackedInt32Array = game.get("collected_shards")
	_check(collected.has(0), "Touching an uncollected Memory Shard should mark it collected.")
	_check(str(game.get("status_message")).contains(str(room["shard_lore"])), "Collecting a shard should reveal its lore fragment.")
	var persisted: Dictionary = ProgressStore.load_progress(LevelCatalog.LEVELS.size())
	var saved_shards: PackedInt32Array = persisted["collected_shards"]
	_check(saved_shards.has(0), "Collecting a Memory Shard should persist it to the local save.")

	# Restore existing user progress after testing persistence.
	game.set("unlocked_level", previous_unlocked)
	game.set("rooms_completed", previous_completed)
	game.set("collected_shards", previous_shards)
	game.call("_save_progress")
	game.call("_update_menu_progress")



func _test_memory_archive_ui(game: Control) -> void:
	game.call("_open_memory_archive")
	var panel: Panel = game.get("memory_archive_panel")
	_check(panel.visible, "Opening Memory Archive from the menu should show its panel.")
	var scroll_node := panel.get_node_or_null("ArchiveScroll")
	_check(scroll_node is ScrollContainer, "The Memory Archive should use scrolling for its story entries.")
	var title_labels: Array = game.get("memory_archive_title_labels")
	var lore_labels: Array = game.get("memory_archive_lore_labels")
	_check(title_labels.size() == LevelCatalog.LEVELS.size(), "Memory Archive should create one title for each chamber.")
	_check(lore_labels.size() == LevelCatalog.LEVELS.size(), "Memory Archive should create one lore entry for each chamber.")

	var already_collected: PackedInt32Array = game.get("collected_shards")
	var first_title: String = str(title_labels[0].text)
	var first_lore: String = str(lore_labels[0].text)
	if already_collected.has(0):
		_check(first_title.contains("RECOVERED"), "An already-collected shard should remain marked as recovered in the archive.")
		_check(first_lore.contains("A courier logged this station"), "The archive should preserve a recovered lore fragment.")
	else:
		_check(first_title.contains("NOT FOUND"), "An uncollected shard should be marked as not found.")
		_check(first_lore.contains("No memory recovered"), "Uncollected entries should explain where their lore comes from.")

	game.call("_show_menu")
	_check(not bool(panel.visible), "Returning to the menu should close the Memory Archive panel.")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
