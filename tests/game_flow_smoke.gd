extends SceneTree

## Integration smoke test for the main scene's echo puzzle flow.
## Tests the full puzzle flow and restores the saved campaign values after portal completion.
const MainScene = preload("res://scenes/main.tscn")
const EchoTrackScript = preload("res://scripts/core/echo_track.gd")
const LevelCatalog = preload("res://scripts/data/level_catalog.gd")
const ProgressStore = preload("res://scripts/data/progress_store.gd")
const CourierSpriteSheet: Texture2D = preload("res://assets/courier_sprite_sheet.svg")

var failures: int = 0


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var game: Control = MainScene.instantiate()
	root.add_child(game)
	await process_frame

	_test_ambient_background(game)
	_test_courier_sprite_sheet()
	_test_chapter_visual_themes(game)
	_test_chapter_select_layout(game)
	_test_touch_joystick_comfort(game)
	_test_safe_area_input_mapping(game)
	_test_premium_mobile_ui(game)
	_test_memory_shard_collection(game)
	_test_all_memories_restore_signal(game)
	_test_memory_archive_ui(game)
	_test_options_panel(game)
	_test_audio_manager(game)
	_test_color_independent_puzzle_cues(game)
	_test_latch_protocol_switch(game)
	_test_echo_waypoint_requirement(game)
	_test_ordered_echo_waypoints(game)
	_test_three_ordered_echo_waypoints(game)
	_test_relay_timer_combo(game)
	_test_dead_air_protocol(game)
	_test_echo_jammer_route(game)
	_test_timed_gate_requires_crossing(game)
	_test_second_chapter_campaign(game)
	_test_chapter_three_mechanics(game)
	_test_multi_echo_puzzles(game)
	_test_chapter_five_mechanics(game)
	game.call("_start_level", 0)
	_check(int(game.get("screen_state")) == 1, "Starting a chamber should switch the game to PLAYING.")

	_test_lifecycle_pause(game)
	_test_pause_screen_actions(game)
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
	_check(float(game.get("gate_flash_timer")) > 0.0, "Opening a gate should start its brief visual activation flare.")

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
	_check(bool((game.get("pause_panel") as Panel).visible), "Application suspension should show the pause card.")
	_check(bool((game.get("pause_scrim") as ColorRect).visible), "The lifecycle pause scrim should block gameplay controls.")
	_check(str((game.get("pause_detail_label") as Label).text).contains("lost focus"), "The pause card should explain that the app was backgrounded.")
	_check(bool((game.get("audio_manager") as Node).get("app_suspended")), "Application suspension should pause background audio too.")
	_check(game.get("joystick_direction") == Vector2.ZERO, "Lifecycle pause should clear movement input.")
	_check(bool(game.get("is_recording")), "Lifecycle pause should preserve an in-progress recording.")
	_check(is_equal_approx(float(game.get("recording_elapsed")), 1.25), "Lifecycle pause should preserve recording time.")
	game.call("_process", 1.0)
	_check(is_equal_approx(float(game.get("recording_elapsed")), 1.25), "Game timers should not advance while paused.")
	_check(is_equal_approx(float(game.get("gate_open_timer")), 2.0), "The Pulse Lock countdown must freeze while the game is paused.")
	game.call("_notification", Node.NOTIFICATION_APPLICATION_RESUMED)
	_check(not bool((game.get("audio_manager") as Node).get("app_suspended")), "Returning to the app should restore audio availability.")
	_check(int(game.get("screen_state")) == 2, "Returning to the app should not resume gameplay without player input.")
	game.call("_on_pause_pressed")
	_check(int(game.get("screen_state")) == 1, "The player should be able to resume gameplay explicitly.")
	_check(not bool((game.get("pause_panel") as Panel).visible), "Explicit resume should hide the pause card.")
	_check(not bool((game.get("pause_scrim") as ColorRect).visible), "Explicit resume should restore gameplay touch controls.")
	_check(not bool(game.get("joystick_mouse_active")), "Resume must not reactivate a stale joystick press.")


func _test_pause_screen_actions(game: Control) -> void:
	game.call("_start_level", 0)
	game.call("_on_pause_pressed")
	var pause_panel: Panel = game.get("pause_panel")
	var pause_scrim: ColorRect = game.get("pause_scrim")
	_check(int(game.get("screen_state")) == 2 and pause_panel.visible, "The pause button should open the pause card.")
	_check(pause_scrim.visible and pause_scrim.mouse_filter == Control.MOUSE_FILTER_STOP, "The pause scrim should prevent taps from reaching gameplay behind the card.")
	_check(pause_panel.get_node("PauseResumeButton") is Button, "The pause card should provide a prominent Resume action.")
	_check(pause_panel.get_node("PauseRestartButton") is Button, "The pause card should provide a Restart Chamber action.")
	_check(pause_panel.get_node("PauseMenuButton") is Button, "The pause card should provide a Return to Menu action.")
	_check(bool((game.get("record_button") as Button).disabled), "Recording controls should remain disabled while paused.")

	var resume_button := pause_panel.get_node("PauseResumeButton") as Button
	resume_button.emit_signal("pressed")
	_check(int(game.get("screen_state")) == 1 and not pause_panel.visible, "Resume should return to the same live chamber and close the pause card.")

	game.call("_on_pause_pressed")
	game.set("is_recording", true)
	var restart_button := pause_panel.get_node("PauseRestartButton") as Button
	restart_button.emit_signal("pressed")
	_check(int(game.get("screen_state")) == 1 and not bool(game.get("is_recording")), "Restart from the pause card should reset the chamber and clear an unfinished take.")
	_check(not pause_panel.visible and not pause_scrim.visible, "Restart should dismiss the complete pause overlay.")

	game.call("_on_pause_pressed")
	var menu_button := pause_panel.get_node("PauseMenuButton") as Button
	menu_button.emit_signal("pressed")
	_check(int(game.get("screen_state")) == 0, "Return to Main Menu should exit the paused chamber.")
	_check(not pause_panel.visible and not pause_scrim.visible, "Returning to the menu should dismiss the pause overlay.")
	game.call("_start_level", 0)


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
	var expected_impact_position := Vector2(640, 380)
	game.call("_check_sentinel_collision")
	_check(game.get("player_position") == expected_spawn, "Sentinel contact should return the player to the room spawn.")
	_check(game.get("failure_impact_position") == expected_impact_position, "Sentinel contact should preserve the exact hit location for its visual feedback ring.")
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
	var completion_effect_remaining := float(game.get("completion_effect_timer"))
	_check(completion_effect_remaining > 0.0, "Portal completion should start its separate visual burst timer.")

	# The cosmetic timer continues while the completion panel is open, then repeated
	# portal checks must not restart it or award a second completion.
	game.call("_process", 0.05)
	var completion_effect_after_tick := float(game.get("completion_effect_timer"))
	_check(completion_effect_after_tick < completion_effect_remaining, "The completion burst should progress while the completion screen is open.")
	game.call("_check_puzzle_state")
	_check(int(game.get("rooms_completed")) == completed_count, "Repeated portal checks must not count a completed chamber twice.")
	_check(is_equal_approx(float(game.get("completion_effect_timer")), completion_effect_after_tick), "Repeated portal checks must not restart the completion burst.")

	# Restore the original persisted campaign values so running tests never permanently advances a save.
	game.set("unlocked_level", previous_unlocked)
	game.set("rooms_completed", previous_completed)
	game.call("_save_progress")
	game.call("_update_menu_progress")


func _test_courier_sprite_sheet() -> void:
	_check(CourierSpriteSheet.get_width() == 768, "The courier sprite sheet should contain six 128-pixel frames in one row.")
	_check(CourierSpriteSheet.get_height() == 128, "The courier sprite frames should have a consistent 128-pixel height.")


func _test_chapter_visual_themes(game: Control) -> void:
	var expected_names: Array[String] = [
		"SIGNAL ORIGINS",
		"SIGNAL SYNTHESIS",
		"DRIFT & PHASE",
		"TWIN SIGNAL",
		"FINAL ORBIT"
	]
	var previous_primary := Color.TRANSPARENT
	var seen_chapters: Dictionary = {}
	for chapter in range(1, 6):
		var style: Dictionary = game.call("_get_chapter_theme_style", chapter)
		_check(str(style.get("name", "")) == expected_names[chapter - 1], "Chapter %d should have its own named visual identity." % chapter)
		_check(int(style.get("motif", 0)) == chapter, "Chapter %d should select its matching procedural motif." % chapter)
		_check(typeof(style.get("primary")) == TYPE_COLOR and typeof(style.get("secondary")) == TYPE_COLOR, "Each chapter theme should define both background accent colors.")
		var primary: Color = style["primary"]
		var secondary: Color = style["secondary"]
		_check(primary != secondary, "Chapter %d should use two distinct visual accents." % chapter)
		_check(primary != previous_primary, "Every chapter should have a distinct primary palette color.")
		previous_primary = primary
		seen_chapters[chapter] = true
	var first_fallback: Dictionary = game.call("_get_chapter_theme_style", 0)
	var last_fallback: Dictionary = game.call("_get_chapter_theme_style", 99)
	_check(str(first_fallback.get("name", "")) == expected_names[0], "Invalid low chapter numbers should safely use the first theme.")
	_check(str(last_fallback.get("name", "")) == expected_names[4], "Invalid high chapter numbers should safely use the final theme.")

	var catalog_chapters: Dictionary = {}
	for room in LevelCatalog.LEVELS:
		catalog_chapters[int(room.get("chapter", 1))] = true
	_check(catalog_chapters.size() == 5, "The 24-room campaign should include rooms in all five themed chapters.")
	_check(seen_chapters.size() == 5, "All five theme styles should be available to the room renderer.")


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
	var previous_reduced_motion := bool(game.get("reduced_motion"))
	var previous_music := bool(game.get("music_enabled"))
	var previous_sfx := bool(game.get("sfx_enabled"))
	var previous_haptics := bool(game.get("haptics_enabled"))
	var previous_music_volume := float(game.get("music_volume"))
	var previous_sfx_volume := float(game.get("sfx_volume"))
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
	_check(game.get("reduced_motion_button") is Button, "Options should expose a Reduced Motion accessibility setting.")
	_check(game.get("music_button") is Button, "Options should expose a separate Music setting.")
	_check(game.get("sfx_button") is Button, "Options should expose a separate SFX setting.")
	_check(game.get("haptics_button") is Button, "Options should expose an optional Haptics setting.")
	_check(game.get("music_volume_slider") is HSlider, "Options should expose a dedicated Music volume slider.")
	_check(game.get("sfx_volume_slider") is HSlider, "Options should expose a dedicated SFX volume slider.")
	_check(game.get("music_volume_label") is Label and game.get("sfx_volume_label") is Label, "Each volume slider should have a readable percentage label.")
	_check(is_equal_approx((game.get("music_volume_slider") as HSlider).max_value, 100.0), "Volume sliders should use a 0–100 percent range.")
	var options_card: Panel = game.get("options_panel")
	var music_slider_rect := Rect2((game.get("music_volume_slider") as HSlider).position, (game.get("music_volume_slider") as HSlider).size)
	var sfx_slider_rect := Rect2((game.get("sfx_volume_slider") as HSlider).position, (game.get("sfx_volume_slider") as HSlider).size)
	var music_button_rect := Rect2((game.get("music_button") as Button).position, (game.get("music_button") as Button).size)
	var haptics_button_rect := Rect2((game.get("haptics_button") as Button).position, (game.get("haptics_button") as Button).size)
	var back_button_rect := Rect2(options_card.get_node("OptionsBack").position, options_card.get_node("OptionsBack").size)
	_check(not music_slider_rect.intersects(music_button_rect) and not sfx_slider_rect.intersects(haptics_button_rect), "Audio sliders should remain separate from the mute and haptics buttons.")
	_check(back_button_rect.position.y + back_button_rect.size.y <= options_card.size.y, "The Options back button should fit inside the expanded card.")

	game.call("_set_move_speed", 200.0)
	_check(is_equal_approx(float(game.get("player_move_speed")), 200.0), "Selecting SLOW should affect the actual player movement speed.")
	game.call("_set_left_handed_controls", true)
	_check(bool(game.get("left_handed_controls")), "The left-handed setting should update active control state.")
	Engine.max_fps = 120
	game.call("_set_performance_mode", false)
	_check(Engine.max_fps == 0, "Full-effects mode should remove any pre-existing engine FPS cap.")
	_check(not bool(game.get("performance_mode")), "Performance Mode should be switchable off for devices that can handle full effects.")
	_check(str((game.get("performance_button") as Button).text).contains("OFF"), "Options should display the selected performance setting.")
	Engine.max_fps = 45
	game.call("_set_performance_mode", true)
	_check(Engine.max_fps == 0, "Performance Mode should also run without an engine FPS cap.")
	_check(bool(game.get("performance_mode")), "Performance Mode should be switchable back on.")
	game.call("_set_reduced_motion", true)
	_check(bool(game.get("reduced_motion")), "Reduced Motion should be switchable on.")
	_check(str((game.get("reduced_motion_button") as Button).text).contains("ON"), "Options should display the selected Reduced Motion setting.")
	game.call("_set_music_enabled", false)
	_check(not bool(game.get("music_enabled")), "Music should be switchable off independently.")
	_check(not str((game.get("music_button") as Button).text).contains("ON"), "Options should display Music OFF.")
	game.call("_set_sfx_enabled", false)
	_check(not bool(game.get("sfx_enabled")), "SFX should be switchable off independently.")
	game.call("_set_haptics_enabled", true)
	_check(bool(game.get("haptics_enabled")), "Haptics should be independently switchable on.")
	_check(str((game.get("haptics_button") as Button).text).contains("ON"), "Options should display Haptics ON.")
	var music_slider: HSlider = game.get("music_volume_slider")
	var sfx_slider: HSlider = game.get("sfx_volume_slider")
	music_slider.value = 35.0
	_check(is_equal_approx(float(game.get("music_volume")), 0.35), "Dragging the Music slider should update the saved music level.")
	_check(is_equal_approx(float((game.get("audio_manager") as Node).get("music_volume")), 0.35), "Dragging Music should update only the ambient audio channel immediately.")
	_check(str((game.get("music_volume_label") as Label).text).contains("35%"), "Music slider should show its percentage readout.")
	sfx_slider.value = 72.0
	_check(is_equal_approx(float(game.get("sfx_volume")), 0.72), "Dragging the SFX slider should update the saved effects level.")
	_check(is_equal_approx(float((game.get("audio_manager") as Node).get("sfx_volume")), 0.72), "Dragging SFX should update only the effects audio channel immediately.")
	_check(str((game.get("sfx_volume_label") as Label).text).contains("72%"), "SFX slider should show its percentage readout.")
	var animated_test_button: Button = game.get("speed_normal_button")
	animated_test_button.scale = Vector2(0.9, 0.9)
	game.call("_animate_button", animated_test_button, 1.04)
	_check(animated_test_button.scale.is_equal_approx(Vector2.ONE), "Reduced Motion should suppress button scale animations.")
	var frozen_particle_time := float(game.get("particle_time"))
	game.set("screen_state", 0)
	game.call("_process", 0.016)
	_check(is_equal_approx(float(game.get("particle_time")), frozen_particle_time), "Reduced Motion should keep ambient stars static.")
	game.call("_start_level", 17)
	var bridge_before: Array[Vector2] = game.get("platform_positions")
	var bridge_start := bridge_before[0] if not bridge_before.is_empty() else Vector2.ZERO
	var gameplay_time_before := float(game.get("hazard_time"))
	var frozen_courier_time := float(game.get("player_animation_time"))
	game.call("_process", 0.1)
	_check(is_equal_approx(float(game.get("player_animation_time")), frozen_courier_time), "Reduced Motion should freeze decorative courier animation while gameplay continues.")
	var bridge_after: Array[Vector2] = game.get("platform_positions")
	_check(float(game.get("hazard_time")) > gameplay_time_before, "Reduced Motion must not pause gameplay time or moving hazards.")
	_check(not bridge_after.is_empty() and bridge_after[0].distance_to(bridge_start) > 0.0, "Moving bridges must continue operating under Reduced Motion.")
	game.call("_schedule_room_reset", "TEST RESET", "Reduced Motion should avoid the failure-card fade.")
	var failure_card: Panel = game.get("failure_panel")
	_check(is_equal_approx(failure_card.modulate.a, 1.0), "Reduced Motion should show reset feedback without a fade animation.")
	game.call("_start_level", 17)
	game.call("_set_reduced_motion", false)
	_check(not bool(game.get("reduced_motion")), "Reduced Motion should be switchable off again.")
	var previous_courier_time := float(game.get("player_animation_time"))
	game.call("_process", 0.1)
	_check(float(game.get("player_animation_time")) > previous_courier_time, "Courier hover animation should resume when Reduced Motion is switched off.")
	game.set("joystick_touch_index", 0)
	game.set("joystick_direction", Vector2.RIGHT)
	game.call("_update_player", 0.05)
	var courier_direction: Vector2 = game.get("player_visual_velocity")
	_check(courier_direction.x > 0.0 and absf(courier_direction.y) < 0.001, "Courier animation pose should follow the actual horizontal steering direction.")
	game.set("joystick_touch_index", -1)
	game.set("joystick_direction", Vector2.ZERO)
	game.set("joystick_applied_direction", Vector2.ZERO)
	game.call("_update_player", 0.016)
	game.size = Vector2(1280, 720)
	_check(not bool(game.call("_is_joystick_area", Vector2(100, 600))), "Left-handed mode should stop starting a joystick on the left side.")
	_check(bool(game.call("_is_joystick_area", Vector2(1180, 600))), "Left-handed mode should allow starting a joystick on the right side.")

	# Integration tests must restore the player's real stored preferences.
	game.call("_set_move_speed", previous_speed)
	game.call("_set_left_handed_controls", previous_handedness)
	game.call("_set_performance_mode", previous_performance_mode)
	game.call("_set_reduced_motion", previous_reduced_motion)
	game.call("_set_music_enabled", previous_music)
	game.call("_set_sfx_enabled", previous_sfx)
	game.call("_set_haptics_enabled", previous_haptics)
	game.call("_set_music_volume", previous_music_volume)
	game.call("_set_sfx_volume", previous_sfx_volume)
	game.call("_show_menu")
	_check(not bool(panel.visible), "Returning from Options should hide the settings panel.")
	_check(is_equal_approx(float(game.get("player_move_speed")), previous_speed), "The test should restore the original movement speed.")
	_check(bool(game.get("left_handed_controls")) == previous_handedness, "The test should restore the original handedness preference.")
	_check(bool(game.get("reduced_motion")) == previous_reduced_motion, "The test should restore the original Reduced Motion preference.")
	_check(bool(game.get("music_enabled")) == previous_music, "The test should restore the original Music preference.")
	_check(bool(game.get("sfx_enabled")) == previous_sfx, "The test should restore the original SFX preference.")
	_check(bool(game.get("haptics_enabled")) == previous_haptics, "The test should restore the original Haptics preference.")
	_check(is_equal_approx(float(game.get("music_volume")), previous_music_volume), "The test should restore the original Music volume.")
	_check(is_equal_approx(float(game.get("sfx_volume")), previous_sfx_volume), "The test should restore the original SFX volume.")



func _test_audio_manager(game: Control) -> void:
	var manager: Node = game.get("audio_manager")
	_check(is_instance_valid(manager), "The scene should initialize its lightweight audio manager.")
	var music_player := manager.get("music_player") as AudioStreamPlayer
	var sfx_player := manager.get("sfx_player") as AudioStreamPlayer
	var music_stream := music_player.stream as AudioStreamWAV
	_check(music_stream != null, "The ambient music should be generated as a WAV stream.")
	if music_stream != null:
		_check(music_stream.format == AudioStreamWAV.FORMAT_16_BITS and music_stream.mix_rate == 22050, "Ambient music should use compact 16-bit mono PCM at 22.05 kHz.")
		_check(music_stream.loop_mode == AudioStreamWAV.LOOP_FORWARD and music_stream.loop_end == 176400, "Ambient music should loop its eight-second buffer.")
		_check(music_stream.data.size() <= 360000, "The ambient music buffer should remain compact for mobile devices.")
	var effect_streams: Dictionary = manager.get("sfx_streams")
	_check(effect_streams.size() >= 7, "The game should generate distinct feedback sounds for key puzzle events.")
	var echo_effect := effect_streams.get("echo_send") as AudioStreamWAV
	_check(echo_effect != null and echo_effect.loop_mode == AudioStreamWAV.LOOP_DISABLED, "Short feedback effects should not loop.")
	var previous_music := bool(manager.get("music_enabled"))
	var previous_sfx := bool(manager.get("sfx_enabled"))
	var previous_haptics := bool(manager.get("haptics_enabled"))
	var previous_music_volume := float(manager.get("music_volume"))
	var previous_sfx_volume := float(manager.get("sfx_volume"))
	_check(is_equal_approx(music_player.volume_db, linear_to_db(previous_music_volume)), "The ambient player should use the stored Music volume.")
	_check(is_equal_approx(sfx_player.volume_db, linear_to_db(previous_sfx_volume)), "The effects player should use the stored SFX volume.")
	manager.call("set_music_volume", 0.35)
	_check(is_equal_approx(music_player.volume_db, linear_to_db(0.35)), "Music volume changes should apply immediately to the ambient player.")
	manager.call("set_sfx_volume", 0.72)
	_check(is_equal_approx(sfx_player.volume_db, linear_to_db(0.72)), "SFX volume changes should apply immediately to the effects player.")
	manager.call("set_music_volume", 0.0)
	_check(music_player.volume_db <= -79.0, "A zero Music slider value should mute the ambient player without a logarithm error.")
	manager.call("set_sfx_volume", 0.0)
	_check(sfx_player.volume_db <= -79.0, "A zero SFX slider value should mute the effects player without a logarithm error.")
	manager.call("set_music_enabled", false)
	_check(not music_player.playing, "Disabling music should stop the ambient player.")
	manager.call("set_music_enabled", true)
	_check(music_player.playing, "Enabling music should start the ambient loop.")
	manager.call("set_sfx_enabled", false)
	manager.call("play_sfx", "ui")
	_check(not sfx_player.playing, "Disabling SFX should prevent puzzle sounds from playing.")
	manager.call("set_sfx_enabled", true)
	manager.call("play_sfx", "ui")
	_check(sfx_player.playing, "Enabling SFX should allow the short UI feedback stream to play.")
	manager.call("set_haptics_enabled", true)
	_check(bool(manager.get("haptics_enabled")), "The audio manager should retain the independent haptics state.")
	manager.call("set_haptics_enabled", previous_haptics)
	manager.call("set_app_suspended", true)
	_check(bool(music_player.stream_paused), "The ambient loop should pause while the app is suspended.")
	_check(not sfx_player.playing, "Short feedback tones should stop when the app is backgrounded.")
	manager.call("set_app_suspended", false)
	_check(not bool(music_player.stream_paused), "The ambient loop should unpause when the app returns.")
	manager.call("set_music_enabled", previous_music)
	manager.call("set_sfx_enabled", previous_sfx)
	manager.call("set_music_volume", previous_music_volume)
	manager.call("set_sfx_volume", previous_sfx_volume)


func _test_color_independent_puzzle_cues(game: Control) -> void:
	_check(str(game.call("_get_switch_status_label", true)) == "ACTIVE", "An active switch must have an explicit text state independent of its tint.")
	_check(str(game.call("_get_switch_status_label", false)) == "WAITING", "An inactive switch must have a readable waiting state independent of its tint.")
	_check(str(game.call("_get_switch_status_label", false, "PULSE CLOSED")) == "PULSE CLOSED", "Pulse switches must explain a closed active window without relying on color.")
	_check(str(game.call("_get_switch_status_label", false, "MOVE TO B")) == "MOVE TO B", "A live pulse must tell the player to reach Switch B.")
	_check(str(game.call("_get_relay_status_label", false)) == "REQUIRED", "An unlinked relay must explicitly say that it is required.")
	_check(str(game.call("_get_relay_status_label", true)) == "LINKED", "A completed relay must explicitly say that it is linked.")


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
	_check(float(game.get("gate_flash_timer")) > 0.0, "Opening a timed gate should also start the activation flare.")
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


func _test_ambient_background(game: Control) -> void:
	var background: Variant = game.get("background_texture")
	_check(background is Texture2D, "The generated ECHO nebula background should load as an offline texture.")
	if background is Texture2D:
		_check(background.get_width() >= 360 and background.get_height() >= 203, "The bundled ECHO nebula background should have enough resolution for the mobile landscape layout.")
		_check(absf(float(background.get_width()) / float(background.get_height()) - (16.0 / 9.0)) < 0.01, "The ECHO nebula wallpaper should preserve its cinematic 16:9 aspect ratio.")
	var particles: Array = game.get("stars")
	_check(particles.size() == 96, "The ambient background should create a deterministic field of 96 twinkling stars.")
	_check(not particles.is_empty() and particles[0] is Vector4, "Each star should store normalized position, size and twinkle phase.")
	var previous_time := float(game.get("particle_time"))
	game.set("screen_state", 0)
	game.call("_process", 0.016)
	_check(float(game.get("particle_time")) > previous_time, "Ambient stars should keep blinking while the main menu is visible.")



func _test_second_chapter_campaign(game: Control) -> void:
	_check(LevelCatalog.LEVELS.size() == 24, "Chapter V should preserve the twenty-one-room campaign and add three new chambers.")
	var errors: PackedStringArray = LevelCatalog.validate_levels()
	_check(errors.is_empty(), "All Chapter II and later room layouts should pass campaign validation: %s" % "\n".join(errors))
	var last_room: Dictionary = LevelCatalog.get_level(16)
	_check(int(last_room.get("chapter", 0)) == 2, "The final Chapter II chamber should remain in Chapter II.")
	_check(last_room.has("echo_jammer") and last_room.has("echo_waypoints") and last_room.has("gate_open_seconds") and bool(last_room.get("hazard", false)), "The final Chapter II chamber should combine relay order, an echo jammer, a sentinel and a pulse gate.")
	game.call("_update_chapter_buttons")
	var buttons: Array = game.get("chapter_buttons")
	if buttons.size() == 24:
		_check(str((buttons[13] as Button).text).begins_with("CH. II"), "Chapter II chambers should be clearly marked in chamber select.")
		_check(str((buttons[17] as Button).text).begins_with("CH. III"), "Chapter III chambers should be clearly marked in chamber select.")
		_check(str((buttons[19] as Button).text).begins_with("CH. IV"), "Chapter IV chambers should be clearly marked in chamber select.")
		_check(str((buttons[21] as Button).text).begins_with("CH. V"), "Chapter V chambers should be clearly marked in chamber select.")

	# Verify the authored four-relay route can pass around the jammer and reach A
	# within the eight-second recording cap.
	var route = EchoTrackScript.new()
	route.add_sample(0.0, Vector2(150, 520))
	route.add_sample(1.05, Vector2(290, 300))
	route.add_sample(1.70, Vector2(430, 230))
	route.add_sample(2.76, Vector2(700, 230))
	route.add_sample(3.79, Vector2(850, 450))
	route.add_sample(4.38, Vector2(980, 520))
	_check(route.duration() <= 8.0, "The final four-relay route should fit inside the recording limit.")
	_check(game.call("_track_passes_waypoints_in_order", route, last_room["echo_waypoints"], 40.0), "The final authored relay route should visit all four relays in order.")
	_check(not game.call("_track_passes_waypoint", route, last_room["echo_jammer"], float(last_room["echo_jammer_radius"])), "The final authored route should bypass the echo jammer.")
	game.call("_start_level", 16)
	_check(int(game.get("current_level_index")) == 16 and bool((game.get("level_data") as Dictionary).get("hazard", false)), "The final Chapter II room should load its sentinel and gate rules.")

func _test_chapter_three_mechanics(game: Control) -> void:
	_check(LevelCatalog.LEVELS.size() == 24, "The campaign should contain twenty-four chambers after Chapter V is added.")
	var errors: PackedStringArray = LevelCatalog.validate_levels()
	_check(errors.is_empty(), "Chapter III platform and pulse-switch layouts should pass validation: %s" % "\n".join(errors))

	var drift_room: Dictionary = LevelCatalog.get_level(17)
	_check(str(drift_room.get("name", "")) == "Drift Bridge", "Chamber 18 should introduce the moving bridge.")
	game.call("_start_level", 17)
	var drift_platform: Dictionary = (drift_room["moving_platforms"] as Array)[0]
	var platform_start: Vector2 = drift_platform["from"]
	game.set("player_position", platform_start)
	game.set("hazard_time", 0.0)
	game.set("platform_positions", game.call("_get_moving_platform_positions", 0.0))
	game.call("_update_player", 0.1)
	var carried_position: Vector2 = game.get("player_position")
	_check(carried_position.x > platform_start.x + 5.0, "Standing on the bridge should carry the real player with its movement.")
	var stationary_platforms: Array[Vector2] = game.call("_get_moving_platform_positions", 0.0)
	var no_bridge_support: bool = game.call("_is_position_supported", Vector2(700, 365), stationary_platforms)
	_check(not no_bridge_support, "The void gap should block movement when no platform is underneath.")
	var crossing_platforms: Array[Vector2] = game.call("_get_moving_platform_positions", 1.8)
	var bridge_support: bool = game.call("_is_position_supported", crossing_platforms[0], crossing_platforms)
	_check(bridge_support, "The moving bridge should provide safe ground while it crosses the void.")

	var phase_room: Dictionary = LevelCatalog.get_level(18)
	_check(str(phase_room.get("name", "")) == "Phase Relay", "Chamber 19 should introduce the pulse Switch B.")
	game.call("_start_level", 18)
	var phase_data: Dictionary = game.get("level_data")
	var phase_a: Vector2 = phase_data["plate_a"]
	var phase_b: Vector2 = phase_data["plate_b"]
	game.set("echo_visible", true)
	game.set("echo_playing", false)
	game.set("echo_position", phase_a)
	game.set("player_position", phase_b)
	game.set("hazard_time", 3.0)
	_check(not bool(game.call("_is_pulse_switch_active")), "Phase Relay should have a real off-cycle when the pulse switch is not lit.")
	game.call("_check_puzzle_state")
	_check(not bool(game.get("door_open")), "Standing on Switch B outside its pulse window must not open the gate.")
	game.set("hazard_time", 4.3)
	_check(bool(game.call("_is_pulse_switch_active")), "Phase Relay should expose a deterministic live pulse window.")
	game.call("_check_puzzle_state")
	_check(bool(game.get("door_open")), "Echo on A plus the player on B during the pulse should open the gate.")
	_check(is_equal_approx(float(game.get("gate_open_timer")), float(phase_data["gate_open_seconds"])), "The pulse switch should start the authored gate-crossing timer.")
	_check(not bool(game.get("latch_switch_button").visible), "Pulse Switch B should not expose the toggle-latch control.")
	game.call("_start_level", 0)


func _test_multi_echo_puzzles(game: Control) -> void:
	_check(LevelCatalog.LEVELS.size() == 24, "Chapter IV should retain its two-echo chambers in the expanded campaign.")
	var validation_errors: PackedStringArray = LevelCatalog.validate_levels()
	_check(validation_errors.is_empty(), "Two-echo rooms should pass catalog validation: %s" % "\n".join(validation_errors))

	var twin_room: Dictionary = LevelCatalog.get_level(19)
	_check(str(twin_room.get("name", "")) == "Twin Signal", "Chamber 20 should teach recording two independent echoes.")
	_check(int(twin_room.get("echo_slots", 0)) == 2 and twin_room.get("plate_c") is Vector2, "Twin Signal should define two echo slots and Switch C.")
	game.call("_start_level", 19)
	_check(str(game.get("echo_status_label").text).begins_with("ECHOES: 0/2"), "Two-echo HUD should show the linked echo count before recording.")
	var spawn: Vector2 = twin_room["spawn"]
	var plate_a: Vector2 = twin_room["plate_a"]
	var plate_c: Vector2 = twin_room["plate_c"]
	var plate_b: Vector2 = twin_room["plate_b"]
	game.set("player_position", spawn)
	game.call("_on_record_pressed")
	var first_route = EchoTrackScript.new()
	first_route.add_sample(0.0, spawn)
	first_route.add_sample(1.2, plate_a)
	game.set("recording_track", first_route)
	game.set("recording_elapsed", 1.2)
	game.set("player_position", plate_a)
	game.call("_finish_recording")
	_check(int(game.get("echo_slots_recorded")) == 1 and bool(game.get("echo_playing")), "The first recorded track should be released as Echo 1.")
	game.call("_on_record_pressed")
	_check(not bool(game.get("is_recording")), "Echo 2 recording must wait until Echo 1 has finished and settled on A.")
	game.call("_update_echo", 1.3)
	_check(bool(game.get("echo_visible")) and not bool(game.get("echo_playing")) and (game.get("echo_position") as Vector2).distance_to(plate_a) < 1.0, "Echo 1 should settle and hold Switch A.")
	game.call("_on_record_pressed")
	_check(bool(game.get("is_recording")) and int(game.get("recording_slot_index")) == 1, "The second recording should start in Echo 2 mode.")
	var second_route = EchoTrackScript.new()
	second_route.add_sample(0.0, plate_a)
	second_route.add_sample(1.4, plate_c)
	game.set("recording_track", second_route)
	game.set("recording_elapsed", 1.4)
	game.set("player_position", plate_c)
	game.call("_finish_recording")
	_check(int(game.get("echo_slots_recorded")) == 2 and bool(game.get("secondary_echo_playing")), "The second recording should release an independent Echo 2.")
	_check(bool(game.get("echo_visible")) and (game.get("echo_position") as Vector2).distance_to(plate_a) < 1.0, "Recording Echo 2 must not erase Echo 1 from Switch A.")
	game.call("_update_echo", 1.5)
	_check(bool(game.get("secondary_echo_visible")) and not bool(game.get("secondary_echo_playing")) and (game.get("secondary_echo_position") as Vector2).distance_to(plate_c) < 1.0, "Echo 2 should settle on Switch C.")
	game.set("player_position", plate_b)
	game.call("_check_puzzle_state")
	_check(bool(game.get("door_open")), "Echoes holding A and C plus the player on B should open Twin Signal's gate.")
	_check(bool(game.get("record_button").disabled), "The record button should lock after both echo slots have been captured.")
	_check(not (game.get("secondary_echo_track").samples as Array).is_empty(), "Echo 2 should retain its own independent route samples.")
	game.call("_start_level", 19)
	_check(int(game.get("echo_slots_recorded")) == 0 and not bool(game.get("echo_visible")) and not bool(game.get("secondary_echo_visible")), "Restarting a duet room should clear both echo slots and both playback states.")
	_check((game.get("secondary_echo_track").samples as Array).is_empty(), "Restarting a duet room should clear Echo 2's independent route data.")

	var convergence_room: Dictionary = LevelCatalog.get_level(20)
	_check(str(convergence_room.get("name", "")) == "Convergent Signal", "Chamber 21 should combine two echoes with a pulse gate.")
	game.call("_start_level", 20)
	var start_two: Vector2 = convergence_room["spawn"]
	var a_two: Vector2 = convergence_room["plate_a"]
	var c_two: Vector2 = convergence_room["plate_c"]
	var b_two: Vector2 = convergence_room["plate_b"]
	game.set("player_position", start_two)
	game.call("_on_record_pressed")
	var route_a = EchoTrackScript.new()
	route_a.add_sample(0.0, start_two)
	route_a.add_sample(1.1, a_two)
	game.set("recording_track", route_a)
	game.set("recording_elapsed", 1.1)
	game.set("player_position", a_two)
	game.call("_finish_recording")
	game.call("_update_echo", 1.2)
	game.call("_on_record_pressed")
	var route_c = EchoTrackScript.new()
	route_c.add_sample(0.0, a_two)
	route_c.add_sample(1.3, c_two)
	game.set("recording_track", route_c)
	game.set("recording_elapsed", 1.3)
	game.set("player_position", c_two)
	game.call("_finish_recording")
	game.call("_update_echo", 1.4)
	game.set("player_position", b_two)
	game.set("hazard_time", 3.0)
	_check(not bool(game.call("_is_pulse_switch_active")), "Convergent Signal should have a real off-cycle for Switch B.")
	game.call("_check_puzzle_state")
	_check(not bool(game.get("door_open")), "Two echoes alone must not bypass the pulse requirement.")
	game.set("hazard_time", 1.0)
	_check(bool(game.call("_is_pulse_switch_active")), "Convergent Signal should expose a deterministic active pulse window.")
	game.call("_check_puzzle_state")
	_check(bool(game.get("door_open")), "Both settled echoes and the player on B during its pulse should open the gate.")
	_check(is_equal_approx(float(game.get("gate_open_timer")), 2.4), "The duet pulse gate should start its short 2.4-second crossing timer.")
	game.call("_start_level", 0)


func _test_chapter_five_mechanics(game: Control) -> void:
	_check(LevelCatalog.LEVELS.size() == 24, "Chapter V should contain three new chambers, bringing the campaign to twenty-four.")

	var orbit_room: Dictionary = LevelCatalog.get_level(21)
	_check(str(orbit_room.get("name", "")) == "Orbit Crossing", "Chamber 22 should be the double moving-bridge introduction.")
	game.call("_start_level", 21)
	var orbit_platforms: Array[Vector2] = game.call("_get_moving_platform_positions", 0.0)
	_check(orbit_platforms.size() == 2, "Orbit Crossing should calculate both moving bridges.")
	if orbit_platforms.size() == 2:
		_check(bool(game.call("_is_position_supported", orbit_platforms[0], orbit_platforms)), "A point on either moving bridge should remain supported over the void.")
	_check(not bool(game.call("_is_position_supported", Vector2(700, 390), orbit_platforms)), "The space between the two bridge decks should remain unsafe.")
	game.set("hazard_time", 0.5)
	_check(bool(game.call("_is_pulse_switch_active")), "Orbit Crossing should expose its first readable B-switch pulse.")
	game.set("hazard_time", 3.8)
	_check(not bool(game.call("_is_pulse_switch_active")), "Orbit Crossing should include an off-cycle between pulses.")
	var orbit_route: Variant = _make_test_route(orbit_room["spawn"], orbit_room["echo_waypoints"], orbit_room["plate_a"])
	_check(float(orbit_route.duration()) <= 8.0, "Orbit Crossing's ordered echo route should fit inside the recording cap.")
	_check(bool(game.call("_track_passes_waypoints_in_order", orbit_route, orbit_room["echo_waypoints"], 40.0)), "Orbit Crossing's echo route should visit both relays in order.")

	var tandem_room: Dictionary = LevelCatalog.get_level(22)
	_check(str(tandem_room.get("name", "")) == "Tandem Relay", "Chamber 23 should combine two echoes with shared relay checkpoints.")
	game.call("_start_level", 22)
	var tandem_first: Variant = _make_test_route(tandem_room["spawn"], tandem_room["echo_waypoints"], tandem_room["plate_a"])
	var tandem_second: Variant = _make_test_route(tandem_room["plate_a"], tandem_room["echo_waypoints"], tandem_room["plate_c"])
	_check(float(tandem_first.duration()) <= 8.0 and float(tandem_second.duration()) <= 8.0, "Both Tandem Relay recordings should fit inside the eight-second recording cap.")
	_check(bool(game.call("_track_passes_waypoints_in_order", tandem_first, tandem_room["echo_waypoints"], 40.0)), "Tandem Relay's first echo should reach both relays in order.")
	_check(bool(game.call("_track_passes_waypoints_in_order", tandem_second, tandem_room["echo_waypoints"], 40.0)), "Tandem Relay's second echo should repeat the same relay sequence.")
	_check(not bool(game.call("_track_passes_waypoint", tandem_first, tandem_room["echo_jammer"], float(tandem_room["echo_jammer_radius"]))), "Tandem Relay's first route should avoid the echo jammer.")
	_check(not bool(game.call("_track_passes_waypoint", tandem_second, tandem_room["echo_jammer"], float(tandem_room["echo_jammer_radius"]))), "Tandem Relay's second route should avoid the echo jammer.")

	var final_room: Dictionary = LevelCatalog.get_level(23)
	_check(str(final_room.get("name", "")) == "The Last Duet", "Chamber 24 should be the final duet gauntlet.")
	game.call("_start_level", 23)
	var final_first: Variant = _make_test_route(final_room["spawn"], final_room["echo_waypoints"], final_room["plate_a"])
	var final_second: Variant = _make_test_route(final_room["plate_a"], final_room["echo_waypoints"], final_room["plate_c"])
	_check(float(final_first.duration()) <= 8.0 and float(final_second.duration()) <= 8.0, "Both final routes should fit inside the recording cap.")
	_check(bool(game.call("_track_passes_waypoints_in_order", final_first, final_room["echo_waypoints"], 40.0)), "The final Echo 1 route should visit all four relays.")
	_check(bool(game.call("_track_passes_waypoints_in_order", final_second, final_room["echo_waypoints"], 40.0)), "The final Echo 2 route should revisit all four relays.")
	_check(not bool(game.call("_track_passes_waypoint", final_first, final_room["echo_jammer"], float(final_room["echo_jammer_radius"]))), "The final Echo 1 route should bypass the blackout.")
	_check(not bool(game.call("_track_passes_waypoint", final_second, final_room["echo_jammer"], float(final_room["echo_jammer_radius"]))), "The final Echo 2 route should bypass the blackout.")

	# Exercise the complete final duet: Echo 1 settles on A, Echo 2 settles on C,
	# and the player catches B during its pulse to activate the timed gate.
	game.set("player_position", final_room["spawn"])
	game.call("_on_record_pressed")
	game.set("recording_track", final_first)
	game.set("recording_elapsed", final_first.duration())
	game.set("player_position", final_room["plate_a"])
	game.call("_finish_recording")
	_check(int(game.get("echo_slots_recorded")) == 1 and bool(game.get("echo_playing")), "The final Echo 1 should release successfully.")
	game.call("_update_echo", float(final_first.duration()) + 0.05)
	_check(bool(game.get("echo_visible")) and not bool(game.get("echo_playing")), "The final Echo 1 should settle on Switch A.")
	game.call("_on_record_pressed")
	_check(bool(game.get("is_recording")) and int(game.get("recording_slot_index")) == 1, "The final Echo 2 recording should unlock after Echo 1 settles.")
	game.set("recording_track", final_second)
	game.set("recording_elapsed", final_second.duration())
	game.set("player_position", final_room["plate_c"])
	game.call("_finish_recording")
	_check(int(game.get("echo_slots_recorded")) == 2 and bool(game.get("secondary_echo_playing")), "The final Echo 2 should release independently.")
	game.call("_update_echo", float(final_second.duration()) + 0.05)
	game.set("player_position", final_room["plate_b"])
	game.set("hazard_time", 0.5)
	_check(bool(game.call("_is_pulse_switch_active")), "The final B switch should have a deterministic live window for the regression test.")
	game.call("_check_puzzle_state")
	_check(bool(game.get("door_open")), "Both settled echoes plus the live pulse should open the final gate.")
	_check(is_equal_approx(float(game.get("gate_open_timer")), 4.2), "The final duet should start its authored 4.2-second crossing timer.")
	game.call("_start_level", 0)


func _make_test_route(start_position: Vector2, waypoint_values: Array, end_position: Vector2) -> Variant:
	var route = EchoTrackScript.new()
	var previous_position := start_position
	var elapsed := 0.0
	route.add_sample(elapsed, previous_position)
	for waypoint_value in waypoint_values:
		if not (waypoint_value is Vector2):
			continue
		var waypoint_position: Vector2 = waypoint_value
		elapsed += previous_position.distance_to(waypoint_position) / 255.0
		route.add_sample(elapsed, waypoint_position)
		previous_position = waypoint_position
	elapsed += previous_position.distance_to(end_position) / 255.0
	route.add_sample(elapsed, end_position)
	return route


func _test_safe_area_input_mapping(game: Control) -> void:
	var safe_rect: Rect2 = game.get("safe_layout_rect")
	var menu_root: Control = game.get("menu_root")
	var game_hud: Control = game.get("game_hud")
	_check(menu_root.position.is_equal_approx(safe_rect.position), "The main menu should begin at the OS safe-area origin.")
	_check(menu_root.size.is_equal_approx(safe_rect.size), "The main menu should use the OS safe-area dimensions.")
	_check(game_hud.position.is_equal_approx(safe_rect.position), "Gameplay HUD should begin at the OS safe-area origin.")
	_check(game_hud.size.is_equal_approx(safe_rect.size), "Gameplay HUD should use the OS safe-area dimensions.")

	var panel: Panel = game.get("pause_panel")
	game.set("safe_layout_rect", Rect2(Vector2(100.0, 30.0), Vector2(1080.0, 660.0)))
	game.call("_layout_centered_panels")
	var expected_pause_position := Vector2(100.0, 30.0) + (Vector2(1080.0, 660.0) - panel.size) * 0.5
	_check(panel.position.is_equal_approx(expected_pause_position), "Modal cards should center inside the safe rectangle rather than behind display cutouts.")

	var original_handedness := bool(game.get("left_handed_controls"))
	game.set("left_handed_controls", false)
	_check(bool(game.call("_is_joystick_area", Vector2(400.0, 250.0))), "Right-handed movement pickup should use the safe area's left half.")
	_check(not bool(game.call("_is_joystick_area", Vector2(900.0, 250.0))), "Right-handed movement pickup should reject the safe area's right half.")
	_check(not bool(game.call("_is_joystick_area", Vector2(400.0, 80.0))), "Movement pickup should stay clear of the safe area's top HUD.")
	_check(not bool(game.call("_is_joystick_area", Vector2(400.0, 650.0))), "Movement pickup should stay clear of the safe area's bottom action row.")
	game.set("left_handed_controls", true)
	_check(bool(game.call("_is_joystick_area", Vector2(900.0, 250.0))), "Left-handed movement pickup should mirror within the safe area's right half.")
	_check(not bool(game.call("_is_joystick_area", Vector2(400.0, 250.0))), "Left-handed movement pickup should reject the safe area's left half.")
	game.set("left_handed_controls", original_handedness)
	game.set("safe_layout_rect", safe_rect)
	game.call("_layout_centered_panels")


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
	var pause_panel: Panel = game.get("pause_panel")
	_check(options_panel.position.is_equal_approx((game.size - options_panel.size) * 0.5), "Options should remain centered when the viewport changes size.")
	_check(failure_panel.position.is_equal_approx((game.size - failure_panel.size) * 0.5), "The failure/restart card should remain centered when the viewport changes size.")
	_check(pause_panel.position.is_equal_approx((game.size - pause_panel.size) * 0.5), "The pause card should remain centered when the viewport changes size.")
	game.size = Vector2(800, 360)
	game.call("_layout_responsive_ui")
	var fitted_options_size := options_panel.size * options_panel.scale
	_check(fitted_options_size.x <= game.size.x - 24.0 and fitted_options_size.y <= game.size.y - 24.0, "The taller Options card should scale down to fit short landscape screens.")
	_check(options_panel.position.is_equal_approx((game.size - options_panel.size) * 0.5), "Scaled Options should keep its center pivot aligned with the viewport.")
	var fitted_pause_size := pause_panel.size * pause_panel.scale
	_check(fitted_pause_size.x <= game.size.x - 24.0 and fitted_pause_size.y <= game.size.y - 24.0, "The pause card should scale down to fit short landscape screens.")
	_check(pause_panel.position.is_equal_approx((game.size - pause_panel.size) * 0.5), "Scaled pause card should keep its center pivot aligned with the viewport.")
	game.size = Vector2(1480, 820)
	game.call("_layout_responsive_ui")
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
