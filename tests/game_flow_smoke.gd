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
	_test_all_memories_restore_signal(game)
	_test_memory_archive_ui(game)
	_test_options_panel(game)
	_test_echo_waypoint_requirement(game)
	_test_ordered_echo_waypoints(game)
	_test_three_ordered_echo_waypoints(game)
	_test_relay_timer_combo(game)
	_test_timed_gate_requires_crossing(game)
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
	game.set("door_open", true)
	game.set("gate_open_timer", 2.0)
	game.set("joystick_direction", Vector2.RIGHT)
	game.call("_notification", Node.NOTIFICATION_APPLICATION_PAUSED)
	_check(int(game.get("screen_state")) == 2, "Application suspension should pause active gameplay.")
	_check(game.get("joystick_direction") == Vector2.ZERO, "Lifecycle pause should clear movement input.")
	_check(bool(game.get("is_recording")), "Lifecycle pause should preserve an in-progress recording.")
	_check(is_equal_approx(float(game.get("recording_elapsed")), 1.25), "Lifecycle pause should preserve recording time.")
	game.call("_process", 1.0)
	_check(is_equal_approx(float(game.get("recording_elapsed")), 1.25), "Game timers should not advance while paused.")
	_check(is_equal_approx(float(game.get("gate_open_timer")), 2.0), "The Pulse Lock countdown must freeze while the game is paused.")
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




func _test_all_memories_restore_signal(game: Control) -> void:
	var previous_unlocked := int(game.get("unlocked_level"))
	var previous_completed := int(game.get("rooms_completed"))
	var previous_shards: PackedInt32Array = game.get("collected_shards")
	var level_total := LevelCatalog.LEVELS.size()
	var all_but_last := PackedInt32Array()
	for room_index in range(level_total - 1):
		all_but_last.append(room_index)
	game.set("collected_shards", all_but_last)

	# Collect the final room's shard through the same pickup path used in play.
	game.call("_start_level", level_total - 1)
	var final_room: Dictionary = game.get("level_data")
	game.set("player_position", final_room["memory_shard"])
	game.call("_check_memory_shard_collection")
	var completed_shards: PackedInt32Array = game.get("collected_shards")
	_check(completed_shards.size() == level_total, "Collecting the final Memory Shard should complete the archive.")
	_check(str(game.get("status_message")).begins_with("SIGNAL RESTORED"), "The last Memory Shard should reward the player with the restored-signal message.")

	game.call("_update_memory_archive")
	var archive_status: Label = game.get("memory_archive_status_label")
	_check(str(archive_status.text).contains("SIGNAL RESTORED"), "The Memory Archive should clearly mark the restored-signal reward.")

	# This test must never permanently rewrite a player's campaign or collectibles.
	game.set("unlocked_level", previous_unlocked)
	game.set("rooms_completed", previous_completed)
	game.set("collected_shards", previous_shards)
	game.call("_save_progress")
	game.call("_update_menu_progress")
	game.call("_show_menu")


func _test_memory_archive_ui(game: Control) -> void:
	game.call("_open_memory_archive")
	var panel: Panel = game.get("memory_archive_panel")
	_check(panel.visible, "Opening Memory Archive from the menu should show its panel.")
	var archive_status_label: Label = game.get("memory_archive_status_label")
	var archive_collected_shards: PackedInt32Array = game.get("collected_shards")
	if archive_collected_shards.size() >= LevelCatalog.LEVELS.size():
		_check(str(archive_status_label.text).contains("SIGNAL RESTORED"), "A complete collection should keep the restored-signal status visible.")
	else:
		_check(str(archive_status_label.text).contains("/ %d" % LevelCatalog.LEVELS.size()), "Archive placeholder/count should use the live room count, not a hard-coded six.")
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



func _test_options_panel(game: Control) -> void:
	var previous_speed := float(game.get("player_move_speed"))
	var previous_handedness := bool(game.get("left_handed_controls"))
	game.call("_show_menu")
	var menu_root: Control = game.get("menu_root")
	_check(menu_root.get_node_or_null("OptionsButton") is Button, "The main menu should expose an Options button.")

	game.call("_open_options")
	var panel: Panel = game.get("options_panel")
	_check(panel.visible, "Opening Options should show the settings panel.")
	_check(game.get("speed_slow_button") is Button, "Options should expose the slow movement preset.")
	_check(game.get("speed_normal_button") is Button, "Options should expose the normal movement preset.")
	_check(game.get("speed_fast_button") is Button, "Options should expose the fast movement preset.")
	_check(game.get("left_handed_button") is Button, "Options should expose the left-handed joystick setting.")

	game.call("_set_move_speed", 200.0)
	_check(is_equal_approx(float(game.get("player_move_speed")), 200.0), "Selecting SLOW should affect the actual player movement speed.")
	game.call("_set_left_handed_controls", true)
	_check(bool(game.get("left_handed_controls")), "The left-handed setting should update active control state.")
	game.size = Vector2(1280, 720)
	_check(not bool(game.call("_is_joystick_area", Vector2(100, 600))), "Left-handed mode should stop starting a joystick on the left side.")
	_check(bool(game.call("_is_joystick_area", Vector2(1180, 600))), "Left-handed mode should allow starting a joystick on the right side.")

	# Integration tests must restore the player's real stored preferences.
	game.call("_set_move_speed", previous_speed)
	game.call("_set_left_handed_controls", previous_handedness)
	game.call("_show_menu")
	_check(not bool(panel.visible), "Returning from Options should hide the settings panel.")
	_check(is_equal_approx(float(game.get("player_move_speed")), previous_speed), "The test should restore the original movement speed.")
	_check(bool(game.get("left_handed_controls")) == previous_handedness, "The test should restore the original handedness preference.")



func _test_echo_waypoint_requirement(game: Control) -> void:
	game.call("_start_level", 5)
	var room: Dictionary = game.get("level_data")
	_check(room.has("echo_waypoint"), "Static Bloom should author a required relay beacon.")
	var spawn: Vector2 = room["spawn"]
	var waypoint: Vector2 = room["echo_waypoint"]
	var plate_a: Vector2 = room["plate_a"]

	# The direct spawn-to-A segment should be rejected because it does not pass the relay.
	var direct_track = EchoTrackScript.new()
	direct_track.add_sample(0.0, spawn)
	direct_track.add_sample(2.0, plate_a)
	game.set("recording_track", direct_track)
	game.set("recording_elapsed", 2.0)
	game.set("record_sample_accumulator", 0.0)
	game.set("is_recording", true)
	game.set("player_position", plate_a)
	game.call("_finish_recording")
	_check(not bool(game.get("echo_visible")), "A route that misses the required relay beacon must not create an echo.")
	_check(not bool(game.call("_is_relay_waypoint_linked", 0)), "A route that misses the beacon must leave its marker unlinked.")
	_check(str(game.get("status_message")).contains("RELAY BEACON"), "A rejected relay route should explain the missing beacon.")

	# The beacon should count even when the player only passes near it between sampled points.
	# Neither segment endpoint is the beacon itself; the segment's closest point is inside its radius.
	var relay_track = EchoTrackScript.new()
	relay_track.add_sample(0.0, spawn)
	relay_track.add_sample(0.7, Vector2(300, 300))
	relay_track.add_sample(1.3, Vector2(460, 220))
	relay_track.add_sample(2.0, plate_a)
	game.set("recording_track", relay_track)
	game.set("recording_elapsed", 2.0)
	game.set("record_sample_accumulator", 0.0)
	game.set("is_recording", true)
	game.set("player_position", plate_a)
	_check(bool(game.call("_is_relay_waypoint_linked", 0)), "Crossing the relay during recording should show its linked state immediately.")
	game.call("_finish_recording")
	_check(bool(game.get("echo_visible")), "A route passing through the relay and ending on A should create an echo.")
	_check(bool(game.get("echo_playing")), "An accepted relay route should begin echo playback.")
	_check(bool(game.call("_is_relay_waypoint_linked", 0)), "The accepted echo should retain the linked marker state.")
	game.call("_start_level", 0)



func _test_ordered_echo_waypoints(game: Control) -> void:
	game.call("_start_level", 6)
	var room: Dictionary = game.get("level_data")
	_check(room.has("echo_waypoints"), "Chorus Route should define an ordered list of required relay checkpoints.")
	if not room.has("echo_waypoints"):
		game.call("_start_level", 0)
		return

	var spawn: Vector2 = room["spawn"]
	var plate_a: Vector2 = room["plate_a"]
	var waypoints: Array = room["echo_waypoints"]
	_check(waypoints.size() == 2, "Chorus Route should require exactly two relay checkpoints.")
	if waypoints.size() != 2:
		game.call("_start_level", 0)
		return
	var first_relay: Vector2 = waypoints[0]
	var second_relay: Vector2 = waypoints[1]

	# Crossing both relays is not enough when the route reaches Relay 2 first.
	var out_of_order_track = EchoTrackScript.new()
	out_of_order_track.add_sample(0.0, spawn)
	out_of_order_track.add_sample(1.0, second_relay)
	out_of_order_track.add_sample(2.0, first_relay)
	out_of_order_track.add_sample(3.0, plate_a)
	game.set("recording_track", out_of_order_track)
	game.set("recording_elapsed", 3.0)
	game.set("record_sample_accumulator", 0.0)
	game.set("is_recording", true)
	game.set("player_position", plate_a)
	game.call("_finish_recording")
	_check(not bool(game.get("echo_visible")), "A route that visits the relay checkpoints in reverse order must be rejected.")
	_check(not bool(game.call("_is_relay_waypoint_linked", 0)), "Relay 1 must not show linked when Relay 2 was encountered first.")
	_check(not bool(game.call("_is_relay_waypoint_linked", 1)), "Relay 2 must not show linked when it was visited before Relay 1.")
	_check(str(game.get("status_message")).contains("RELAY 1, then RELAY 2 in order"), "An out-of-order two-relay route should explain the required sequence.")

	# Visiting Relay 1 then Relay 2 before ending on A creates a valid echo.
	var ordered_track = EchoTrackScript.new()
	ordered_track.add_sample(0.0, spawn)
	ordered_track.add_sample(1.0, first_relay)
	ordered_track.add_sample(2.0, second_relay)
	ordered_track.add_sample(3.0, plate_a)
	game.set("recording_track", ordered_track)
	game.set("recording_elapsed", 3.0)
	game.set("record_sample_accumulator", 0.0)
	game.set("is_recording", true)
	game.set("player_position", plate_a)
	game.call("_finish_recording")
	_check(bool(game.get("echo_visible")), "A route passing Relay 1, then Relay 2, and ending on A should create an echo.")
	_check(bool(game.get("echo_playing")), "An accepted ordered-relay route should start echo playback.")
	_check(bool(game.call("_is_relay_waypoint_linked", 0)), "Relay 1 should remain marked linked after a valid route is sent.")
	_check(bool(game.call("_is_relay_waypoint_linked", 1)), "Relay 2 should be marked linked only after Relay 1 in a valid route.")
	game.call("_start_level", 0)



func _test_three_ordered_echo_waypoints(game: Control) -> void:
	game.call("_start_level", 9)
	var room: Dictionary = game.get("level_data")
	_check(str(room.get("name", "")) == "Triune Relay", "The tenth chamber should be Triune Relay.")
	_check(room.has("echo_waypoints"), "Triune Relay should define ordered relay checkpoints.")
	if not room.has("echo_waypoints") or not room["echo_waypoints"] is Array:
		game.call("_start_level", 0)
		return

	var spawn: Vector2 = room["spawn"]
	var plate_a: Vector2 = room["plate_a"]
	var waypoints: Array = room["echo_waypoints"]
	_check(waypoints.size() == 3, "Triune Relay should require exactly three checkpoints.")
	if waypoints.size() != 3:
		game.call("_start_level", 0)
		return

	var first_relay: Vector2 = waypoints[0]
	var second_relay: Vector2 = waypoints[1]
	var third_relay: Vector2 = waypoints[2]

	# Crossing the third relay before the second must not satisfy the full chain.
	var out_of_order_track = EchoTrackScript.new()
	out_of_order_track.add_sample(0.0, spawn)
	out_of_order_track.add_sample(1.0, first_relay)
	out_of_order_track.add_sample(2.0, third_relay)
	out_of_order_track.add_sample(3.0, second_relay)
	out_of_order_track.add_sample(4.0, plate_a)
	game.set("recording_track", out_of_order_track)
	game.set("recording_elapsed", 4.0)
	game.set("record_sample_accumulator", 0.0)
	game.set("is_recording", true)
	game.set("player_position", plate_a)
	game.call("_finish_recording")
	_check(not bool(game.get("echo_visible")), "Triune Relay must reject a route that visits Relay 3 before Relay 2.")
	_check(str(game.get("status_message")).contains("RELAY 1, then RELAY 2, then RELAY 3 in order"), "A failed three-relay route should explain the full checkpoint order.")

	# All three checkpoints in order followed by Switch A should be accepted.
	var ordered_track = EchoTrackScript.new()
	ordered_track.add_sample(0.0, spawn)
	ordered_track.add_sample(1.0, first_relay)
	ordered_track.add_sample(2.0, second_relay)
	ordered_track.add_sample(3.0, third_relay)
	ordered_track.add_sample(4.0, plate_a)
	game.set("recording_track", ordered_track)
	game.set("recording_elapsed", 4.0)
	game.set("record_sample_accumulator", 0.0)
	game.set("is_recording", true)
	game.set("player_position", plate_a)
	game.call("_finish_recording")
	_check(bool(game.get("echo_visible")), "Triune Relay should accept a route crossing Relay 1, Relay 2, Relay 3, then Switch A.")
	_check(bool(game.get("echo_playing")), "A valid three-relay route should start echo playback.")
	for waypoint_index in range(3):
		_check(bool(game.call("_is_relay_waypoint_linked", waypoint_index)), "Each relay should show linked after the full ordered route is accepted.")
	game.call("_start_level", 0)



func _test_relay_timer_combo(game: Control) -> void:
	game.call("_start_level", 10)
	var room: Dictionary = game.get("level_data")
	_check(str(room.get("name", "")) == "Fracture Clock", "The eleventh chamber should be Fracture Clock.")
	_check(room.has("gate_open_seconds"), "Fracture Clock should define a timed gate.")
	_check(room.has("echo_waypoints") and room["echo_waypoints"] is Array and room["echo_waypoints"].size() == 3, "Fracture Clock should combine a timed gate with three ordered relays.")
	if not room.has("gate_open_seconds") or not room.has("echo_waypoints"):
		game.call("_start_level", 0)
		return

	var spawn: Vector2 = room["spawn"]
	var plate_a: Vector2 = room["plate_a"]
	var waypoints: Array = room["echo_waypoints"]

	# The rejection hint must name all three checkpoints, not just the first pair.
	var invalid_route = EchoTrackScript.new()
	invalid_route.add_sample(0.0, spawn)
	invalid_route.add_sample(1.0, waypoints[0])
	invalid_route.add_sample(2.0, waypoints[2])
	invalid_route.add_sample(3.0, waypoints[1])
	invalid_route.add_sample(4.0, plate_a)
	game.set("recording_track", invalid_route)
	game.set("recording_elapsed", 4.0)
	game.set("record_sample_accumulator", 0.0)
	game.set("is_recording", true)
	game.set("player_position", plate_a)
	game.call("_finish_recording")
	_check(not bool(game.get("echo_visible")), "Fracture Clock should reject a route that visits Relay 3 before Relay 2.")
	_check(str(game.get("status_message")).contains("RELAY 1, then RELAY 2, then RELAY 3 in order"), "Fracture Clock's rejection hint should list every required relay.")

	var route = EchoTrackScript.new()
	route.add_sample(0.0, spawn)
	route.add_sample(1.0, waypoints[0])
	route.add_sample(2.0, waypoints[1])
	route.add_sample(3.0, waypoints[2])
	route.add_sample(4.0, plate_a)
	game.set("recording_track", route)
	game.set("recording_elapsed", 4.0)
	game.set("record_sample_accumulator", 0.0)
	game.set("is_recording", true)
	game.set("player_position", plate_a)
	game.call("_finish_recording")
	_check(bool(game.get("echo_visible")), "Fracture Clock should accept the three-relay route before starting its gate puzzle.")
	if not bool(game.get("echo_visible")):
		game.call("_start_level", 0)
		return

	# Simulate the echo settling on A while the player holds B. The combined
	# puzzle should open the gate with its authored 4.5-second crossing window.
	game.set("echo_playing", false)
	game.set("echo_position", plate_a)
	game.set("echo_linger_left", 5.0)
	game.set("player_position", room["plate_b"])
	game.call("_check_puzzle_state")
	_check(bool(game.get("door_open")), "Holding both switches after the relay route should open Fracture Clock.")
	_check(is_equal_approx(float(game.get("gate_open_timer")), 4.5), "Fracture Clock should start its authored 4.5-second gate window.")

	# Crossing the barrier before the countdown expires must preserve portal power.
	game.set("player_position", Vector2(1070, 420))
	game.set("gate_open_timer", 0.02)
	game.call("_update_timed_gate", 0.03)
	_check(bool(game.get("door_open")), "Crossing Fracture Clock's barrier in time should keep the portal powered.")
	_check(str(game.get("status_message")).contains("GATE CROSSED"), "The combined puzzle should explain that the portal remains powered after crossing.")
	game.call("_start_level", 0)



func _test_timed_gate_requires_crossing(game: Control) -> void:
	game.call("_start_level", 7)
	var room: Dictionary = game.get("level_data")
	_check(room.has("gate_open_seconds"), "Pulse Lock should define a timed gate.")
	if not room.has("gate_open_seconds"):
		game.call("_start_level", 0)
		return

	var gate_duration := float(room["gate_open_seconds"])
	var plate_a: Vector2 = room["plate_a"]
	var plate_b: Vector2 = room["plate_b"]
	game.set("echo_visible", true)
	game.set("echo_playing", false)
	game.set("echo_linger_left", 8.0)
	game.set("echo_position", plate_a)
	game.set("player_position", plate_b)
	game.call("_check_puzzle_state")
	_check(bool(game.get("door_open")), "Holding both switches should open the Pulse Lock gate.")
	_check(is_equal_approx(float(game.get("gate_open_timer")), gate_duration), "Opening Pulse Lock should start its authored countdown.")
	_check(is_equal_approx(float(game.call("_get_gate_timer_ratio")), 1.0), "The visual timer bar should start completely full.")

	# Exercise the real frame loop too: the gate countdown must tick during gameplay.
	game.set("gate_open_timer", 2.0)
	game.call("_process", 0.05)
	_check(is_equal_approx(float(game.get("gate_open_timer")), 1.95), "Pulse Lock countdown should decrease by the frame delta while playing.")
	_check(is_equal_approx(float(game.call("_get_gate_timer_ratio")), 1.95 / gate_duration), "The visual timer bar should shrink proportionally as the gate countdown advances.")

	# Let the timer expire while the player still stands on Switch B. The gate
	# should close and must not immediately reopen while the same hold persists.
	game.set("gate_open_timer", 0.02)
	game.call("_update_timed_gate", 0.03)
	_check(not bool(game.get("door_open")), "The timed gate should close if the player does not cross before timeout.")
	_check(is_zero_approx(float(game.call("_get_gate_timer_ratio"))), "The visual timer bar should be empty after the crossing window expires.")
	_check(bool(game.get("timed_gate_failed")), "A missed window should require the player to leave a switch before retrying.")
	game.call("_check_puzzle_state")
	_check(not bool(game.get("door_open")), "The timed gate must not immediately reopen while both switches remain held.")
	_check(str(game.get("status_message")).contains("PULSE GATE MISSED"), "A missed crossing window should explain how to retry.")

	# Releasing Switch B and returning to it rearms the crossing window.
	game.set("player_position", plate_b + Vector2(0, 100))
	game.call("_check_puzzle_state")
	_check(not bool(game.get("timed_gate_failed")), "Leaving Switch B should rearm a fresh timed-gate attempt.")
	game.set("player_position", plate_b)
	game.call("_check_puzzle_state")
	_check(bool(game.get("door_open")), "Returning to Switch B while the echo holds A should reopen Pulse Lock.")
	_check(is_equal_approx(float(game.get("gate_open_timer")), gate_duration), "Retrying should reset the timer to its authored duration.")

	# Once the player has crossed the blocking line, the gate window may expire
	# but must not trap the player on the exit side of the barrier.
	game.set("player_position", Vector2(1070, 420))
	game.set("gate_open_timer", 0.02)
	game.call("_update_timed_gate", 0.03)
	_check(bool(game.get("door_open")), "Crossing the gate before timeout should keep the portal route powered.")
	_check(is_zero_approx(float(game.get("gate_open_timer"))), "The crossing window should stop counting once it expires.")
	_check(str(game.get("status_message")).contains("GATE CROSSED"), "A successful crossing should confirm that the portal remains powered.")
	game.call("_start_level", 0)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
