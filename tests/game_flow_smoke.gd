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
	_test_touch_joystick_comfort(game)
	_test_premium_mobile_ui(game)
	_test_memory_shard_collection(game)
	_test_all_memories_restore_signal(game)
	_test_memory_archive_ui(game)
	_test_options_panel(game)
	_test_latch_protocol_switch(game)
	_test_echo_waypoint_requirement(game)
	_test_ordered_echo_waypoints(game)
	_test_three_ordered_echo_waypoints(game)
	_test_relay_timer_combo(game)
	_test_dead_air_protocol(game)
	_test_echo_jammer_route(game)
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
	_finish_failure_reset(game)

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
	_finish_failure_reset(game)


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
	var previous_performance_mode := bool(game.get("performance_mode"))
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
	_check(game.get("performance_button") is Button, "Options should expose a Performance Mode setting.")

	game.call("_set_move_speed", 200.0)
	_check(is_equal_approx(float(game.get("player_move_speed")), 200.0), "Selecting SLOW should affect the actual player movement speed.")
	game.call("_set_left_handed_controls", true)
	_check(bool(game.get("left_handed_controls")), "The left-handed setting should update active control state.")
	game.call("_set_performance_mode", false)
	_check(not bool(game.get("performance_mode")), "Performance Mode should be switchable off for devices that can handle full effects.")
	_check(str((game.get("performance_button") as Button).text).contains("OFF"), "Options should display the selected performance setting.")
	game.call("_set_performance_mode", true)
	_check(bool(game.get("performance_mode")), "Performance Mode should be switchable back on.")
	game.size = Vector2(1280, 720)
	_check(not bool(game.call("_is_joystick_area", Vector2(100, 600))), "Left-handed mode should stop starting a joystick on the left side.")
	_check(bool(game.call("_is_joystick_area", Vector2(1180, 600))), "Left-handed mode should allow starting a joystick on the right side.")

	# Integration tests must restore the player's real stored preferences.
	game.call("_set_move_speed", previous_speed)
	game.call("_set_left_handed_controls", previous_handedness)
	game.call("_set_performance_mode", previous_performance_mode)
	game.call("_show_menu")
	_check(not bool(panel.visible), "Returning from Options should hide the settings panel.")
	_check(is_equal_approx(float(game.get("player_move_speed")), previous_speed), "The test should restore the original movement speed.")
	_check(bool(game.get("left_handed_controls")) == previous_handedness, "The test should restore the original handedness preference.")



func _test_latch_protocol_switch(game: Control) -> void:
	game.call("_start_level", 8)
	var room: Dictionary = game.get("level_data")
	var latch_button: Button = game.get("latch_switch_button")
	_check(str(room.get("plate_b_mode", "")) == "toggle", "Latch Protocol should configure Switch B as a toggle.")
	_check(latch_button is Button and latch_button.visible, "Latch Protocol should show a dedicated LATCH SWITCH B button.")

	var plate_a: Vector2 = room["plate_a"]
	var plate_b: Vector2 = room["plate_b"]
	game.set("echo_visible", true)
	game.set("echo_playing", false)
	game.set("echo_position", plate_a)
	game.set("player_position", plate_b)
	game.set("switch_b_latched", false)
	game.call("_check_puzzle_state")
	_check(not bool(game.get("door_open")), "Standing on Switch B must not activate a toggle switch before it is latched.")

	latch_button.emit_signal("pressed")
	_check(bool(game.get("switch_b_latched")), "Tapping LATCH SWITCH B while the echo holds A should latch the switch.")
	game.call("_check_puzzle_state")
	_check(bool(game.get("door_open")), "A latched Switch B and an echo on A should open the gate.")
	game.set("player_position", Vector2(650, 500))
	game.call("_check_puzzle_state")
	_check(bool(game.get("door_open")), "Leaving a latched Switch B should not close the gate.")
	game.call("_update_hud")
	_check(str(latch_button.text).contains("LATCHED"), "The circular control should communicate that Switch B is latched and the gate opened.")

	# The player cannot latch B before the echo is holding A.
	game.call("_start_level", 8)
	room = game.get("level_data")
	plate_a = room["plate_a"]
	plate_b = room["plate_b"]
	game.set("player_position", plate_b)
	game.set("echo_visible", false)
	latch_button.emit_signal("pressed")
	_check(not bool(game.get("switch_b_latched")), "Switch B must not latch before an echo reaches A.")
	_check(str(game.get("status_message")).begins_with("WAIT FOR ECHO"), "An early latch attempt should explain that the echo must hold A first.")

	# Being at A while the echo is still travelling is not enough; it must settle.
	game.set("echo_visible", true)
	game.set("echo_playing", true)
	game.set("echo_position", plate_a)
	latch_button.emit_signal("pressed")
	_check(not bool(game.get("switch_b_latched")), "Switch B must not latch while the echo is still playing its route.")
	_check(str(game.get("status_message")).begins_with("WAIT FOR ECHO"), "The latch hint should ask the player to wait until the echo settles on A.")

	# Keyboard E is the desktop equivalent of tapping the dedicated button.
	game.set("echo_playing", false)
	game.set("echo_position", plate_a)
	var latch_key := InputEventKey.new()
	latch_key.keycode = KEY_E
	latch_key.pressed = true
	game.call("_input", latch_key)
	_check(bool(game.get("switch_b_latched")), "Pressing E near Switch B should latch Switch B.")
	game.call("_check_puzzle_state")
	_check(bool(game.get("door_open")), "The keyboard latch action should activate the two-switch gate.")

	game.call("_start_level", 0)
	_check(not bool(game.get("switch_b_latched")), "Restarting a room should clear any previous toggle latch.")
	_check(not bool(latch_button.visible), "The latch button should be hidden in rooms that use a hold switch.")



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
	_finish_failure_reset(game)

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
	_finish_failure_reset(game)

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
	_finish_failure_reset(game)

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
	_finish_failure_reset(game)

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



func _test_dead_air_protocol(game: Control) -> void:
	game.call("_start_level", 11)
	var room: Dictionary = game.get("level_data")
	_check(str(room.get("name", "")) == "Dead Air Protocol", "The twelfth chamber should be Dead Air Protocol.")
	_check(bool(room.get("hazard", false)), "Dead Air Protocol should activate the moving sentinel.")
	_check(room.has("gate_open_seconds") and is_equal_approx(float(room.get("gate_open_seconds", 0.0)), 1.8), "Dead Air Protocol should use a 1.8-second gate.")
	_check(room.has("echo_waypoints") and room["echo_waypoints"] is Array and room["echo_waypoints"].size() == 4, "Dead Air Protocol should require four ordered relays.")
	if not room.has("echo_waypoints") or not room["echo_waypoints"] is Array or room["echo_waypoints"].size() != 4:
		game.call("_start_level", 0)
		return

	var spawn: Vector2 = room["spawn"]
	var plate_a: Vector2 = room["plate_a"]
	var plate_b: Vector2 = room["plate_b"]
	var waypoints: Array = room["echo_waypoints"]

	# A skipped checkpoint must reject the take and name the full sequence.
	var invalid_route = EchoTrackScript.new()
	invalid_route.add_sample(0.0, spawn)
	invalid_route.add_sample(1.35, waypoints[0])
	invalid_route.add_sample(2.7, waypoints[2])
	invalid_route.add_sample(4.2, waypoints[1])
	invalid_route.add_sample(5.45, waypoints[3])
	invalid_route.add_sample(6.9, plate_a)
	game.set("recording_track", invalid_route)
	game.set("recording_elapsed", 6.9)
	game.set("record_sample_accumulator", 0.0)
	game.set("is_recording", true)
	game.set("player_position", plate_a)
	game.call("_finish_recording")
	_check(not bool(game.get("echo_visible")), "Dead Air Protocol should reject relays visited out of order.")
	_check(str(game.get("status_message")).contains("RELAY 1, then RELAY 2, then RELAY 3, then RELAY 4 in order"), "Dead Air Protocol should explain the complete four-relay sequence.")
	_finish_failure_reset(game)

	# A full four-relay route fits inside the eight-second recording cap.
	var valid_route = EchoTrackScript.new()
	valid_route.add_sample(0.0, spawn)
	valid_route.add_sample(1.35, waypoints[0])
	valid_route.add_sample(2.7, waypoints[1])
	valid_route.add_sample(4.2, waypoints[2])
	valid_route.add_sample(5.45, waypoints[3])
	valid_route.add_sample(6.9, plate_a)
	game.set("recording_track", valid_route)
	game.set("recording_elapsed", 6.9)
	game.set("record_sample_accumulator", 0.0)
	game.set("is_recording", true)
	game.set("player_position", plate_a)
	game.call("_finish_recording")
	_check(bool(game.get("echo_visible")), "Dead Air Protocol should accept all four relays in order before Switch A.")
	if not bool(game.get("echo_visible")):
		game.call("_start_level", 0)
		return

	# The gate opens with the authored short window; missing it before the
	# barrier must close the gate and latch a retry requirement.
	game.set("echo_playing", false)
	game.set("echo_position", plate_a)
	game.set("echo_linger_left", 6.0)
	game.set("player_position", plate_b)
	game.call("_check_puzzle_state")
	_check(bool(game.get("door_open")), "An accepted route plus Switch B should open Dead Air Protocol.")
	_check(is_equal_approx(float(game.get("gate_open_timer")), 1.8), "Dead Air Protocol should start its authored 1.8-second timer.")
	game.set("gate_open_timer", 0.01)
	game.call("_update_timed_gate", 0.02)
	_check(not bool(game.get("door_open")), "Dead Air Protocol should close if its short window expires before the barrier.")
	_check(bool(game.get("timed_gate_failed")), "Missing the Dead Air Protocol window should require a switch release before retry.")

	# Sentinel contact during a new take must erase the recording and return to spawn.
	game.call("_start_level", 11)
	room = game.get("level_data")
	var reset_spawn: Vector2 = room["spawn"]
	var interrupted_track = EchoTrackScript.new()
	interrupted_track.add_sample(0.0, reset_spawn)
	interrupted_track.add_sample(1.0, Vector2(400, 400))
	game.set("recording_track", interrupted_track)
	game.set("is_recording", true)
	game.set("recording_elapsed", 1.0)
	game.set("record_sample_accumulator", 0.0)
	game.set("hazard_time", 0.0)
	game.set("player_position", Vector2(640, float(room["hazard_y"])))
	game.call("_check_sentinel_collision")
	_check(game.get("player_position") == reset_spawn, "The Dead Air Protocol sentinel should send the player back to spawn.")
	_check(not bool(game.get("is_recording")), "Sentinel contact should cancel the active Dead Air Protocol recording.")
	_check(game.get("recording_track").samples.is_empty(), "Sentinel contact should erase the interrupted route.")
	_check(str(game.get("status_message")).begins_with("SENTINEL CONTACT — recording lost"), "Sentinel interruption should explain why the route was lost.")
	_finish_failure_reset(game)
	game.call("_start_level", 0)



func _test_echo_jammer_route(game: Control) -> void:
	game.call("_start_level", 12)
	var room: Dictionary = game.get("level_data")
	_check(str(room.get("name", "")) == "Null Corridor", "The thirteenth chamber should be Null Corridor.")
	_check(room.get("echo_jammer") is Vector2, "Null Corridor should author an echo-only jammer.")
	if not room.get("echo_jammer") is Vector2:
		game.call("_start_level", 0)
		return

	var spawn: Vector2 = room["spawn"]
	var plate_a: Vector2 = room["plate_a"]
	var jammer: Vector2 = room["echo_jammer"]
	var jammer_radius := float(room.get("echo_jammer_radius", 100.0))
	var blocked_track = EchoTrackScript.new()
	blocked_track.add_sample(0.0, spawn)
	blocked_track.add_sample(3.0, plate_a)
	_check(bool(game.call("_track_passes_waypoint", blocked_track, jammer, jammer_radius)), "A straight route through Null Corridor should cross the echo dead zone.")
	game.set("recording_track", blocked_track)
	game.set("recording_elapsed", 3.0)
	game.set("record_sample_accumulator", 0.0)
	game.set("is_recording", true)
	game.set("player_position", plate_a)
	game.call("_finish_recording")
	_check(not bool(game.get("echo_visible")), "A recording that crosses the dead zone must not release an echo.")
	_check(str(game.get("status_message")).contains("ECHO DEAD ZONE"), "A jammed route should explain that the recorded path crossed the blackout.")
	_check(str(game.get("failure_reset_reason")) == "ECHO JAMMED", "A jammed route should schedule a clear same-room reset.")
	_finish_failure_reset(game)

	# Bend above the field. None of these segments should enter the jammer radius,
	# so the echo remains valid even though the straight line between switches is blocked.
	var safe_track = EchoTrackScript.new()
	safe_track.add_sample(0.0, spawn)
	safe_track.add_sample(0.9, Vector2(330, 300))
	safe_track.add_sample(2.2, Vector2(700, 300))
	safe_track.add_sample(3.5, plate_a)
	_check(not bool(game.call("_track_passes_waypoint", safe_track, jammer, jammer_radius)), "A curved route around the dead zone should stay clear.")
	game.set("recording_track", safe_track)
	game.set("recording_elapsed", 3.5)
	game.set("record_sample_accumulator", 0.0)
	game.set("is_recording", true)
	game.set("player_position", plate_a)
	game.call("_finish_recording")
	_check(bool(game.get("echo_visible")) and bool(game.get("echo_playing")), "A route that bends around the jammer should release a working echo.")
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




func _finish_failure_reset(game: Control) -> void:
	var reset_timer := float(game.get("failure_reset_timer"))
	_check(reset_timer > 0.0, "A failed relay or sentinel contact should schedule an automatic room reset.")
	_check(bool(game.get("failure_panel").visible), "A failure should show the reset overlay.")
	_check(not bool(game.get("game_hud").visible), "The normal HUD should not accept taps during the reset transition.")
	var failed_level_index := int(game.get("current_level_index"))
	for _frame in range(24):
		if float(game.get("failure_reset_timer")) <= 0.0:
			break
		game.call("_process", 0.05)
	_check(is_zero_approx(float(game.get("failure_reset_timer"))), "The automatic reset countdown should finish without input.")
	_check(int(game.get("current_level_index")) == failed_level_index, "A room failure should restart the same chamber.")
	_check(bool(game.get("game_hud").visible) and not bool(game.get("failure_panel").visible), "Room restart should restore the HUD and dismiss the failure overlay.")
	_check(not bool(game.get("is_recording")), "Room restart should clear recording state.")
	_check(not bool(game.get("echo_visible")) and not bool(game.get("echo_playing")), "Room restart should clear the released echo.")
	_check(not bool(game.get("door_open")), "Room restart should close the gate.")
	_check(not bool(game.get("switch_b_latched")), "Room restart should clear the toggle latch.")
	_check(str(game.get("status_message")).begins_with("ROOM RESET"), "The restarted room should confirm that automatic recovery completed.")


func _test_touch_joystick_comfort(game: Control) -> void:
	var previous_size := game.size
	var previous_handedness := bool(game.get("left_handed_controls"))
	game.size = Vector2(1280, 720)
	game.set("left_handed_controls", false)
	_check(bool(game.call("_is_joystick_area", Vector2(500, 380))), "Floating movement should start anywhere in the left-side playfield, not only at the corner.")
	_check(not bool(game.call("_is_joystick_area", Vector2(700, 380))), "The center gutter should remain clear between left/right touch movement zones.")
	_check(not bool(game.call("_is_joystick_area", Vector2(500, 80))), "The top HUD must not accidentally start movement.")
	_check(not bool(game.call("_is_joystick_area", Vector2(500, 690))), "The bottom action row must remain excluded from movement touch zones.")
	game.set("left_handed_controls", true)
	_check(bool(game.call("_is_joystick_area", Vector2(800, 380))), "Left-handed mode should move the floating movement zone to the right half.")
	_check(not bool(game.call("_is_joystick_area", Vector2(500, 380))), "Left-handed mode should stop movement pickup on the left half.")

	var dead_input: Vector2 = game.call("_shape_touch_stick", Vector2(4.0, 2.0))
	_check(dead_input == Vector2.ZERO, "Tiny finger jitter should be swallowed by the radial dead zone.")
	var precision_input: Vector2 = game.call("_shape_touch_stick", Vector2(22.0, 0.0))
	_check(precision_input.x > 0.0 and precision_input.x < 1.0, "Short thumb drags should provide proportional precision movement.")
	var full_input: Vector2 = game.call("_shape_touch_stick", Vector2(100.0, 0.0))
	_check(is_equal_approx(full_input.x, 1.0), "Long thumb drags should cap at full movement without losing direction.")
	var diagonal_input: Vector2 = game.call("_shape_touch_stick", Vector2(100.0, 100.0))
	_check(is_equal_approx(diagonal_input.length(), 1.0), "Diagonal joystick input should be normalized so diagonal travel is not faster.")
	_check(bool(game.call("_segment_touches_circle", Vector2(0, 0), Vector2(100, 0), Vector2(50, 5), 6.0)), "A route segment that clips the jammer must be detected.")
	_check(not bool(game.call("_segment_touches_circle", Vector2(0, 0), Vector2(100, 0), Vector2(50, 8), 6.0)), "A route segment outside the jammer radius must remain valid.")

	# Input accelerates gently and settles quickly when the thumb is released.
	game.set("player_position", Vector2(160.0, 365.0))
	game.set("joystick_mouse_active", false)
	game.set("joystick_touch_index", 2)
	game.set("joystick_direction", Vector2.RIGHT)
	game.set("joystick_applied_direction", Vector2.ZERO)
	var start_position: Vector2 = game.get("player_position")
	game.call("_update_player", 0.02)
	var eased_input: Vector2 = game.get("joystick_applied_direction")
	_check(eased_input.x > 0.0 and eased_input.x < 1.0, "Touch movement should ramp in smoothly rather than jump instantly to full speed.")
	_check((game.get("player_position") as Vector2).x > start_position.x, "Smoothed touch input should still move the player immediately.")
	var prior_release_strength := eased_input.length()
	game.set("joystick_direction", Vector2.ZERO)
	game.set("joystick_touch_index", -1)
	game.call("_update_player", 0.02)
	var release_strength: Vector2 = game.get("joystick_applied_direction")
	_check(release_strength.length() < prior_release_strength and release_strength.length() > 0.0, "Releasing the thumb should ease movement to a stop.")
	for _frame in range(24):
		game.call("_update_player", 0.02)
	_check(game.get("joystick_applied_direction") == Vector2.ZERO, "Touch movement should settle fully instead of leaving drift.")
	game.set("joystick_direction", Vector2.ZERO)
	game.set("joystick_applied_direction", Vector2.ZERO)
	game.set("joystick_touch_index", -1)
	game.set("joystick_mouse_active", false)
	game.set("left_handed_controls", previous_handedness)
	game.size = previous_size
	game.call("_layout_responsive_ui")


func _test_premium_mobile_ui(game: Control) -> void:
	var previous_handedness := bool(game.get("left_handed_controls"))
	var record: Button = game.get("record_button")
	var latch: Button = game.get("latch_switch_button")
	var pause: Button = game.get("pause_button")
	var menu_button := game.get("game_hud").get_node("MenuButton") as Button
	var restart_button := game.get("game_hud").get_node("ResetButton") as Button
	var status_banner: Label = game.get("status_label")
	var movement_hint := game.get("game_hud").get_node("MoveTip") as Label
	game.set("left_handed_controls", false)
	_check(record.size.y >= 52.0, "The primary recording control should have a phone-friendly touch height.")
	_check(latch.size.y >= 52.0, "The latch control should have a phone-friendly touch height.")
	_check(menu_button.size.y >= 52.0 and restart_button.size.y >= 52.0, "Bottom navigation and restart controls should have generous touch targets.")
	_check(pause.size.y >= 46.0, "The pause control should be easy to hit on a touchscreen.")
	_check(record.get_theme_stylebox("normal") != null, "Buttons should use the shared premium visual style.")
	game.size = Vector2(1480, 820)
	game.call("_layout_responsive_ui")
	var options_panel: Panel = game.get("options_panel")
	var failure_panel: Panel = game.get("failure_panel")
	_check(options_panel.position.is_equal_approx((game.size - options_panel.size) * 0.5), "Options should remain centered when the viewport changes size.")
	_check(failure_panel.position.is_equal_approx((game.size - failure_panel.size) * 0.5), "The failure/restart card should remain centered when the viewport changes size.")
	_check(record.position.x > game.size.x * 0.5 and record.position.y + record.size.y <= game.size.y - restart_button.size.y - 16.0, "Record Echo should sit on the right above bottom utility controls in the default layout.")
	_check(is_equal_approx(record.size.x, record.size.y) and record.size.y >= 68.0, "Record Echo should remain a large circular touch target.")
	_check(restart_button.position.y >= 0.0 and restart_button.position.y + restart_button.size.y <= game.size.y - 12.0, "The restart circle should stay inside the bottom safe inset (y %.1f, h %.1f, viewport %.1f)." % [restart_button.position.y, restart_button.size.y, game.size.y])
	_check(menu_button.position.x + menu_button.size.x <= game.size.x * 0.5, "The menu circle should stay on the opposite side from the default record control.")
	_check(restart_button.position.x + restart_button.size.x <= game.size.x, "The restart action should remain inside the viewport.")
	var record_style := record.get_theme_stylebox("normal") as StyleBoxFlat
	_check(record_style != null and record_style.corner_radius_top_left >= record.size.y * 0.4, "Record Echo should use a genuinely round button style.")
	_check(record_style != null and record_style.bg_color.a < 0.7, "Record Echo should have a transparent glass fill so the game remains visible underneath.")
	_check(record.pivot_offset.is_equal_approx(record.size * 0.5) and latch.pivot_offset.is_equal_approx(latch.size * 0.5), "Responsive action buttons should keep their press animation centered after resizing.")
	var wide_status_rect := Rect2(status_banner.position, status_banner.size)
	_check(not wide_status_rect.intersects(Rect2(record.position, record.size)) and not wide_status_rect.intersects(Rect2(latch.position, latch.size)), "The status banner should stay out of the right-side action cluster.")
	_check(movement_hint.visible and not Rect2(movement_hint.position, movement_hint.size).intersects(wide_status_rect), "The movement hint should avoid the status banner on a wide screen.")
	_check(bool(game.call("_is_joystick_area", Vector2(100, 700))), "The left joystick area should adapt to a wider/taller viewport.")
	game.set("left_handed_controls", true)
	game.call("_layout_responsive_ui")
	_check(record.position.x < game.size.x * 0.5, "Left-handed mode should mirror the circular action cluster to the left side.")
	var mirrored_status_rect := Rect2(status_banner.position, status_banner.size)
	_check(not mirrored_status_rect.intersects(Rect2(record.position, record.size)) and not mirrored_status_rect.intersects(Rect2(latch.position, latch.size)), "The status banner should stay clear when action buttons are mirrored.")
	_check(bool(game.call("_is_joystick_area", Vector2(1400, 700))), "The right joystick area should adapt in left-handed mode.")

	# Compact-landscape checks need explicit handedness setup: this test previously
	# carried the wide-viewport left-handed value into the following left-side check.
	game.set("left_handed_controls", false)
	game.size = Vector2(960, 540)
	game.call("_layout_responsive_ui")
	var title := game.get("menu_root").get_node("Title") as Label
	var intro := game.get("menu_root").get_node("Intro") as Label
	var progress := game.get("menu_root").get_node("Progress") as Label
	var start := game.get("menu_root").get_node("StartButton") as Button
	var options := game.get("menu_root").get_node("OptionsButton") as Button
	_check(title.position.x >= 0.0 and title.size.x <= game.size.x, "Menu typography should fit a narrower landscape viewport.")
	_check(start.position.y > intro.position.y + intro.size.y, "Compact menu navigation should start below the intro text.")
	_check(
		options.position.y + options.size.y <= progress.position.y,
		"Compact menu controls should finish before the progress line (options bottom %.1f, progress y %.1f, start y %.1f, intro bottom %.1f)." % [
			options.position.y + options.size.y,
			progress.position.y,
			start.position.y,
			intro.position.y + intro.size.y
		]
	)
	var compact_record_rect := Rect2(record.position, record.size)
	var compact_latch_rect := Rect2(latch.position, latch.size)
	var compact_menu_rect := Rect2(menu_button.position, menu_button.size)
	var compact_reset_rect := Rect2(restart_button.position, restart_button.size)
	_check(record.position.y + record.size.y <= restart_button.position.y, "Compact Record Echo circle should sit above bottom utility circles.")
	_check(record.position.x >= 0.0 and record.position.x + record.size.x <= game.size.x, "Compact Record Echo circle must stay inside the viewport.")
	_check(not compact_record_rect.intersects(compact_menu_rect), "Compact menu and Record Echo circles must not overlap.")
	_check(not compact_record_rect.intersects(compact_latch_rect), "Compact Record Echo and latch circles must not overlap.")
	_check(not compact_record_rect.intersects(compact_reset_rect), "Compact Record Echo and restart circles must not overlap.")
	_check(restart_button.position.x + restart_button.size.x <= game.size.x, "Compact restart control should remain inside the right edge.")
	_check(record.pivot_offset.is_equal_approx(record.size * 0.5) and restart_button.pivot_offset.is_equal_approx(restart_button.size * 0.5), "Compact touch controls should keep centered press animations.")
	var compact_status_rect := Rect2(status_banner.position, status_banner.size)
	_check(not compact_status_rect.intersects(compact_record_rect) and not compact_status_rect.intersects(compact_latch_rect), "The compact status banner must not overlap the action circles.")
	_check(movement_hint.visible and not Rect2(movement_hint.position, movement_hint.size).intersects(compact_status_rect), "Compact movement guidance should not cover the status banner.")
	_check(bool(game.call("_is_joystick_area", Vector2(170, 450))), "The compact left joystick zone should avoid the menu button.")
	game.set("left_handed_controls", true)
	_check(bool(game.call("_is_joystick_area", Vector2(780, 450))), "The compact right joystick zone should avoid the restart button.")

	# Extra-short landscape phones need a two-column menu; a single column cannot
	# fit the full navigation stack above the progress indicator at 360px height.
	game.set("left_handed_controls", false)
	game.size = Vector2(800, 360)
	game.call("_layout_responsive_ui")
	var ultra_menu: Control = game.get("menu_root")
	var ultra_progress := ultra_menu.get_node("Progress") as Label
	var ultra_names := ["StartButton", "ChaptersButton", "HowToPlayButton", "MemoryArchiveButton", "OptionsButton"]
	var ultra_buttons: Array[Button] = []
	for button_name in ultra_names:
		var ultra_button := ultra_menu.get_node(button_name) as Button
		ultra_buttons.append(ultra_button)
		_check(ultra_button.position.x >= 0.0 and ultra_button.position.x + ultra_button.size.x <= game.size.x, "Ultra-compact menu buttons must remain inside the viewport.")
		_check(ultra_button.position.y + ultra_button.size.y <= ultra_progress.position.y, "Ultra-compact menu buttons must remain above the progress line.")
		_check(ultra_button.size.y >= 40.0, "Ultra-compact menu buttons must retain usable touch height.")
	for i in range(ultra_buttons.size()):
		for j in range(i + 1, ultra_buttons.size()):
			var first_rect := Rect2(ultra_buttons[i].position, ultra_buttons[i].size)
			var second_rect := Rect2(ultra_buttons[j].position, ultra_buttons[j].size)
			_check(not first_rect.intersects(second_rect), "Ultra-compact menu overlap: %s %s vs %s %s." % [ultra_names[i], str(first_rect), ultra_names[j], str(second_rect)])

	# Recheck narrower and shorter landscape shapes. The intro should be reclaimed
	# below 340 units, and the progress line hidden only when there is no safe room.
	var compact_test_sizes: Array[Vector2] = [
		Vector2(800, 620),
		Vector2(800, 600),
		Vector2(800, 580),
		Vector2(800, 540),
		Vector2(800, 500),
		Vector2(800, 480),
		Vector2(640, 360),
		Vector2(800, 320),
		Vector2(800, 280),
		Vector2(800, 260)
	]
	for compact_size in compact_test_sizes:
		game.size = compact_size
		game.call("_layout_responsive_ui")
		var compact_progress := ultra_menu.get_node("Progress") as Label
		var compact_intro := ultra_menu.get_node("Intro") as Label
		var compact_logo := ultra_menu.get_node("Logo") as TextureRect
		var expected_intro_visible := compact_size.y >= 340.0
		_check(compact_intro.visible == expected_intro_visible, "Compact menu intro visibility must adapt to available height.")
		_check(compact_logo.visible == (compact_size.y >= 620.0), "The supplied brand logo should show on the full-height menu and hide before compact reflow.")
		_check(compact_logo.texture != null, "The supplied logo texture must be loaded into the menu.")
		if compact_logo.texture != null:
			_check(compact_logo.texture.resource_path == "res://assets/echopost_logo.jpg", "The menu must use the supplied ECHO logo asset, not a placeholder.")
		_check(str(ProjectSettings.get_setting("application/config/icon")) == "res://assets/echopost_logo.jpg", "The supplied ECHO logo must also be the actual Godot project icon.")
		_check(compact_progress.visible == (compact_size.y >= 280.0), "Compact menu progress should hide only when the screen is too short.")
		var compact_buttons: Array[Button] = []
		for button_name in ultra_names:
			var compact_button := ultra_menu.get_node(button_name) as Button
			compact_buttons.append(compact_button)
			_check(compact_button.position.x >= 0.0 and compact_button.position.x + compact_button.size.x <= game.size.x, "Compact menu button must stay inside viewport width at %s." % str(compact_size))
			_check(compact_button.position.y >= 0.0 and compact_button.position.y + compact_button.size.y <= game.size.y, "Compact menu button must stay inside viewport height at %s." % str(compact_size))
			if compact_progress.visible:
				_check(compact_button.position.y + compact_button.size.y <= compact_progress.position.y, "Compact menu button must stay above progress at %s." % str(compact_size))
			_check(compact_button.size.y >= 40.0, "Compact menu button must retain a usable touch height at %s." % str(compact_size))
		for i in range(compact_buttons.size()):
			for j in range(i + 1, compact_buttons.size()):
				var first_rect := Rect2(compact_buttons[i].position, compact_buttons[i].size)
				var second_rect := Rect2(compact_buttons[j].position, compact_buttons[j].size)
				_check(not first_rect.intersects(second_rect), "Compact menu overlap at %s: %s %s vs %s %s." % [str(compact_size), ultra_names[i], str(first_rect), ultra_names[j], str(second_rect)])

	# Record Echo now sits beside the opposite-side movement zone; utility circles
	# stay at the bottom. Verify fit, round action hitboxes and no overlap on phones.
	var gameplay_hud := game.get("game_hud") as Control
	var hud_menu := gameplay_hud.get_node("MenuButton") as Button
	var hud_reset := gameplay_hud.get_node("ResetButton") as Button
	var hud_record := game.get("record_button") as Button
	var hud_latch := game.get("latch_switch_button") as Button
	var hud_status := game.get("status_label") as Label
	var hud_hint := gameplay_hud.get_node("MoveTip") as Label
	var hud_sizes: Array[Vector2] = [Vector2(640, 360), Vector2(720, 360), Vector2(800, 320)]
	for hud_size in hud_sizes:
		game.size = hud_size
		game.call("_layout_responsive_ui")
		var hud_buttons: Array[Button] = [hud_menu, hud_record, hud_latch, hud_reset, pause]
		for hud_button in hud_buttons:
			_check(hud_button.position.x >= 0.0 and hud_button.position.x + hud_button.size.x <= game.size.x, "Gameplay HUD control must fit the viewport at %s: %s." % [str(hud_size), hud_button.name])
		_check(hud_record.position.y + hud_record.size.y <= hud_reset.position.y, "Primary action circle should remain above bottom utility buttons at %s." % str(hud_size))
		var record_rect := Rect2(hud_record.position, hud_record.size)
		var latch_rect := Rect2(hud_latch.position, hud_latch.size)
		_check(not record_rect.intersects(latch_rect), "Record and latch circles must not overlap at %s." % str(hud_size))
		var status_rect := Rect2(hud_status.position, hud_status.size)
		_check(not status_rect.intersects(record_rect) and not status_rect.intersects(latch_rect), "Status banner should clear circular controls at %s." % str(hud_size))
		_check(not hud_hint.visible, "Compact movement guidance should hide on very short viewports to preserve control space.")
		for i in range(hud_buttons.size()):
			for j in range(i + 1, hud_buttons.size()):
				var first_hud_rect := Rect2(hud_buttons[i].position, hud_buttons[i].size)
				var second_hud_rect := Rect2(hud_buttons[j].position, hud_buttons[j].size)
				_check(not first_hud_rect.intersects(second_hud_rect), "Gameplay HUD overlap at %s: %s %s vs %s %s." % [str(hud_size), hud_buttons[i].name, str(first_hud_rect), hud_buttons[j].name, str(second_hud_rect)])
	game.size = Vector2(1280, 720)
	game.call("_layout_responsive_ui")
	game.call("_set_left_handed_controls", previous_handedness)
	game.call("_show_menu")

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
