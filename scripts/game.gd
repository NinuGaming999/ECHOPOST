extends Control

## ECHOPOST - mobile-first 2D echo puzzle adventure.
## This file deliberately uses procedural art so the project runs without external assets.

enum ScreenState { MENU, PLAYING, PAUSED, COMPLETE }

const ROOM_LEFT := 48.0
const ROOM_RIGHT := 1232.0
const ROOM_TOP := 112.0
const ROOM_BOTTOM := 612.0
const GATE_X := 1080.0
const PLAYER_RADIUS := 15.0
const MOVE_SPEED := 255.0
const RECORD_SAMPLE_STEP := 0.05
const MIN_RECORD_SECONDS := 0.7
const MAX_RECORD_SECONDS := 8.0
const FAILURE_RESET_DURATION := 0.85
const ECHO_TRACK_SCRIPT = preload("res://scripts/core/echo_track.gd")
const LEVEL_CATALOG = preload("res://scripts/data/level_catalog.gd")
const LEVELS: Array[Dictionary] = LEVEL_CATALOG.LEVELS
const PROGRESS_STORE = preload("res://scripts/data/progress_store.gd")
const SETTINGS_STORE = preload("res://scripts/data/settings_store.gd")

var screen_state: ScreenState = ScreenState.MENU
var current_level_index: int = 0
var unlocked_level: int = 0
var rooms_completed: int = 0
var collected_shards: PackedInt32Array = PackedInt32Array()
var player_move_speed: float = MOVE_SPEED
var left_handed_controls: bool = false
var level_data: Dictionary = {}

var player_position: Vector2 = Vector2(160, 365)
var echo_position: Vector2 = Vector2.ZERO
var echo_visible: bool = false
var echo_playing: bool = false
var echo_elapsed: float = 0.0
var echo_linger_left: float = 0.0
var echo_track: Variant = ECHO_TRACK_SCRIPT.new()

var is_recording: bool = false
var recording_elapsed: float = 0.0
var record_sample_accumulator: float = 0.0
var recording_track: Variant = ECHO_TRACK_SCRIPT.new()
var door_open: bool = false
var switch_b_latched: bool = false
var gate_open_timer: float = 0.0
var timed_gate_failed: bool = false
var hazard_time: float = 0.0
var failure_reset_timer: float = 0.0
var failure_reset_reason: String = ""
var status_message: String = "Your route can become someone else's solution."
var stars: Array[Vector3] = []

var joystick_touch_index: int = -1
var joystick_mouse_active: bool = false
var joystick_origin: Vector2 = Vector2.ZERO
var joystick_direction: Vector2 = Vector2.ZERO

var menu_root: Control
var game_hud: Control
var complete_panel: Panel
var help_panel: Panel
var level_select_panel: Panel
var memory_archive_panel: Panel
var options_panel: Panel
var failure_panel: Panel
var failure_title_label: Label
var failure_detail_label: Label
var failure_progress_bar: ProgressBar
var memory_archive_status_label: Label
var memory_archive_title_labels: Array[Label] = []
var memory_archive_lore_labels: Array[Label] = []
var speed_slow_button: Button
var speed_normal_button: Button
var speed_fast_button: Button
var left_handed_button: Button
var menu_progress_label: Label
var level_title_label: Label
var level_hint_label: Label
var echo_status_label: Label
var status_label: Label
var record_button: Button
var latch_switch_button: Button
var pause_button: Button
var start_button: Button
var complete_title_label: Label
var complete_body_label: Label
var next_level_button: Button
var chapter_buttons: Array[Button] = []


func _notification(what: int) -> void:
	# Modal cards stay centered as a phone rotates or the desktop viewport is resized.
	if what == NOTIFICATION_RESIZED:
		call_deferred("_layout_responsive_ui")
	# Stop gameplay time when Android/iOS suspends the app, or when the app loses focus.
	# We intentionally do not auto-resume: the player must explicitly tap RESUME.
	elif what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_pause_for_lifecycle()


func _pause_for_lifecycle() -> void:
	if failure_reset_timer > 0.0:
		return
	if screen_state != ScreenState.PLAYING:
		return
	screen_state = ScreenState.PAUSED
	joystick_touch_index = -1
	joystick_mouse_active = false
	joystick_direction = Vector2.ZERO
	pause_button.text = "RESUME"
	status_message = "Paused automatically because ECHOPOST lost focus. Press RESUME to continue."
	_update_hud()
	queue_redraw()


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_create_stars()
	_load_progress()
	_load_settings()
	_build_interface()
	_layout_responsive_ui()
	_show_menu()
	queue_redraw()


func _process(delta: float) -> void:
	if screen_state != ScreenState.PLAYING:
		return

	# A failed run freezes briefly behind a polished reset card, then reboots the
	# whole room. Keep this timer separate from puzzle time so retries are reliable.
	if failure_reset_timer > 0.0:
		failure_reset_timer = maxf(0.0, failure_reset_timer - minf(delta, 0.05))
		if is_instance_valid(failure_progress_bar):
			failure_progress_bar.value = failure_reset_timer / FAILURE_RESET_DURATION
		if failure_reset_timer <= 0.0:
			var failed_level_index := current_level_index
			var failed_reason := failure_reset_reason
			failure_reset_reason = ""
			if is_instance_valid(failure_panel):
				failure_panel.hide()
			_start_level(failed_level_index)
			status_message = "ROOM RESET — %s. Try a fresh route." % failed_reason
			_update_hud()
		queue_redraw()
		return

	var safe_delta := minf(delta, 0.05)
	_update_player(safe_delta)

	if is_recording:
		# Clamp elapsed time before sampling so frame-step rounding cannot exceed the 8-second cap.
		recording_elapsed = minf(recording_elapsed + safe_delta, MAX_RECORD_SECONDS)
		record_sample_accumulator += safe_delta
		if record_sample_accumulator >= RECORD_SAMPLE_STEP:
			record_sample_accumulator = fmod(record_sample_accumulator, RECORD_SAMPLE_STEP)
			_add_record_sample(recording_elapsed, player_position)
		if recording_elapsed >= MAX_RECORD_SECONDS:
			_finish_recording()

	_update_echo(safe_delta)
	hazard_time += safe_delta
	_check_sentinel_collision()
	if failure_reset_timer > 0.0:
		# Do not continue puzzle evaluation on the same frame that caused failure.
		queue_redraw()
		return
	_check_memory_shard_collection()
	_update_timed_gate(safe_delta)
	_check_puzzle_state()
	_update_hud()
	queue_redraw()


func _input(event: InputEvent) -> void:
	if screen_state != ScreenState.PLAYING or failure_reset_timer > 0.0:
		return

	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and not key_event.echo and key_event.keycode == KEY_E:
			_on_latch_switch_b_pressed()
			return

	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			if _is_joystick_area(touch.position):
				joystick_touch_index = touch.index
				joystick_origin = touch.position
				joystick_direction = Vector2.ZERO
		else:
			if touch.index == joystick_touch_index:
				joystick_touch_index = -1
				joystick_direction = Vector2.ZERO
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index == joystick_touch_index:
			_update_joystick(drag.position)
	elif event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton
		if mouse_button.button_index == MOUSE_BUTTON_LEFT:
			if mouse_button.pressed and _is_joystick_area(mouse_button.position):
				joystick_mouse_active = true
				joystick_origin = mouse_button.position
				joystick_direction = Vector2.ZERO
			elif not mouse_button.pressed:
				joystick_mouse_active = false
				joystick_direction = Vector2.ZERO
	elif event is InputEventMouseMotion and joystick_mouse_active:
		_update_joystick((event as InputEventMouseMotion).position)


func _is_joystick_area(point: Vector2) -> bool:
	# Use viewport proportions instead of hard-coded pixels so touch input remains
	# predictable on phones with different landscape aspect ratios.
	if point.y <= size.y * 0.56:
		return false
	var bottom_action_band := point.y >= size.y - 76.0
	if left_handed_controls:
		# Keep the right-side joystick clear of the bottom restart target.
		return point.x > size.x * 0.77 and not (bottom_action_band and point.x > size.x * 0.85)
	# Keep the left-side joystick clear of the bottom menu target.
	return point.x < size.x * 0.23 and not (bottom_action_band and point.x < size.x * 0.15)


func _update_joystick(point: Vector2) -> void:
	var offset := point - joystick_origin
	joystick_direction = offset.limit_length(64.0) / 64.0


func _create_stars() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 812731
	for i in range(90):
		stars.append(Vector3(rng.randf_range(0.0, 1280.0), rng.randf_range(0.0, 720.0), rng.randf_range(0.6, 1.8)))


func _build_interface() -> void:
	_build_menu()
	_build_game_hud()
	_build_complete_panel()
	_build_help_panel()
	_build_level_select_panel()
	_build_memory_archive_panel()
	_build_options_panel()
	_build_failure_panel()


func _build_menu() -> void:
	menu_root = Control.new()
	menu_root.name = "Menu"
	menu_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(menu_root)

	# Use the logo supplied for the project as the actual menu brand asset.
	var logo := TextureRect.new()
	logo.name = "Logo"
	logo.texture = load("res://assets/echopost_logo.jpg") as Texture2D
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	logo.position = Vector2(553, 7)
	logo.size = Vector2(174, 174)
	menu_root.add_child(logo)

	var title := _make_label(menu_root, "Title", Vector2(100, 184), Vector2(1080, 44), "ECHOPOST", 36, Color(0.82, 1.0, 0.96), HORIZONTAL_ALIGNMENT_CENTER)
	title.add_theme_color_override("font_shadow_color", Color(0.04, 0.93, 0.80, 0.48))
	title.add_theme_constant_override("shadow_offset_x", 0)
	title.add_theme_constant_override("shadow_offset_y", 3)
	_make_label(menu_root, "Tagline", Vector2(180, 232), Vector2(920, 36), "EVERY PLAYER LEAVES A GHOST", 20, Color(0.34, 0.96, 0.88), HORIZONTAL_ALIGNMENT_CENTER)
	_make_label(menu_root, "Intro", Vector2(250, 272), Vector2(780, 58), "Record your movement. Let your echo hold the past\nwhile you find a way into the future.", 17, Color(0.65, 0.80, 0.83), HORIZONTAL_ALIGNMENT_CENTER)

	start_button = _make_button(menu_root, "StartButton", Vector2(475, 340), Vector2(330, 54), "CONTINUE JOURNEY", Color(0.02, 0.28, 0.29), Color(0.02, 0.42, 0.39), 19)
	start_button.pressed.connect(_on_start_pressed)
	var chapters := _make_button(menu_root, "ChaptersButton", Vector2(475, 400), Vector2(330, 50), "CHAPTER SELECT", Color(0.01, 0.075, 0.09), Color(0.02, 0.19, 0.19), 16)
	chapters.pressed.connect(_open_level_select)
	var help := _make_button(menu_root, "HowToPlayButton", Vector2(475, 456), Vector2(330, 48), "HOW TO PLAY", Color(0.01, 0.075, 0.09), Color(0.02, 0.19, 0.19), 16)
	help.pressed.connect(_open_help)
	var archive := _make_button(menu_root, "MemoryArchiveButton", Vector2(475, 510), Vector2(330, 42), "MEMORY ARCHIVE", Color(0.012, 0.065, 0.075), Color(0.035, 0.16, 0.17), 15)
	archive.pressed.connect(_open_memory_archive)
	var options := _make_button(menu_root, "OptionsButton", Vector2(475, 558), Vector2(330, 42), "OPTIONS", Color(0.01, 0.075, 0.09), Color(0.02, 0.19, 0.19), 15)
	options.pressed.connect(_open_options)
	menu_progress_label = _make_label(menu_root, "Progress", Vector2(240, 619), Vector2(800, 28), "CHAMBERS DISCOVERED: 1 / 6   •   MEMORIES: 0 / 6", 13, Color(0.31, 0.61, 0.61), HORIZONTAL_ALIGNMENT_CENTER)
	_make_label(menu_root, "Version", Vector2(22, 688), Vector2(260, 22), "ECHOPOST  •  EARLY DEVELOPMENT BUILD", 10, Color(0.19, 0.40, 0.40), HORIZONTAL_ALIGNMENT_LEFT)


func _build_game_hud() -> void:
	game_hud = Control.new()
	game_hud.name = "GameHUD"
	game_hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(game_hud)

	level_title_label = _make_label(game_hud, "LevelTitle", Vector2(34, 15), Vector2(570, 36), "01  /  THE FIRST ECHO", 22, Color(0.88, 0.95, 1.0), HORIZONTAL_ALIGNMENT_LEFT)
	level_hint_label = _make_label(game_hud, "LevelHint", Vector2(35, 52), Vector2(900, 44), "Record a route that ends on Switch A.", 15, Color(0.55, 0.70, 0.82), HORIZONTAL_ALIGNMENT_LEFT)
	echo_status_label = _make_label(game_hud, "EchoStatus", Vector2(805, 17), Vector2(300, 28), "ECHO: NOT RECORDED", 14, Color(0.42, 0.83, 1.0), HORIZONTAL_ALIGNMENT_RIGHT)
	pause_button = _make_button(game_hud, "PauseButton", Vector2(1110, 12), Vector2(136, 48), "PAUSE", Color(0.12, 0.22, 0.34), Color(0.17, 0.34, 0.48), 14)
	pause_button.pressed.connect(_on_pause_pressed)

	status_label = _make_label(game_hud, "Status", Vector2(270, 610), Vector2(740, 38), "Find the switches.", 15, Color(0.74, 0.84, 0.93), HORIZONTAL_ALIGNMENT_CENTER)
	record_button = _make_button(game_hud, "RecordButton", Vector2(380, 654), Vector2(270, 54), "RECORD ECHO", Color(0.03, 0.47, 0.62), Color(0.04, 0.65, 0.80), 17)
	record_button.pressed.connect(_on_record_pressed)
	latch_switch_button = _make_button(game_hud, "LatchSwitchBButton", Vector2(680, 654), Vector2(270, 54), "LATCH SWITCH B", Color(0.34, 0.25, 0.10), Color(0.52, 0.37, 0.13), 15)
	latch_switch_button.pressed.connect(_on_latch_switch_b_pressed)
	latch_switch_button.hide()
	var reset_button := _make_button(game_hud, "ResetButton", Vector2(1000, 654), Vector2(145, 54), "RESTART ROOM", Color(0.22, 0.18, 0.31), Color(0.32, 0.23, 0.44), 13)
	reset_button.pressed.connect(_on_reset_pressed)
	var menu_button := _make_button(game_hud, "MenuButton", Vector2(34, 654), Vector2(145, 54), "MAIN MENU", Color(0.12, 0.22, 0.34), Color(0.17, 0.34, 0.48), 13)
	menu_button.pressed.connect(_show_menu)
	_make_label(game_hud, "MoveTip", Vector2(34, 615), Vector2(230, 38), "MOVE  •  WASD / ARROWS\nTOUCH  •  LEFT JOYSTICK", 11, Color(0.43, 0.58, 0.70), HORIZONTAL_ALIGNMENT_LEFT)


func _build_complete_panel() -> void:
	complete_panel = _make_panel("CompletePanel", Vector2(390, 175), Vector2(500, 355))
	var content := Control.new()
	content.position = Vector2(28, 25)
	content.size = Vector2(444, 305)
	complete_panel.add_child(content)
	complete_title_label = _make_label(content, "CompleteTitle", Vector2.ZERO, Vector2(444, 68), "CHAMBER CLEARED", 28, Color(0.86, 0.98, 1.0), HORIZONTAL_ALIGNMENT_CENTER)
	complete_body_label = _make_label(content, "CompleteBody", Vector2(0, 74), Vector2(444, 84), "Your echo helped open the way.\nYour route is now part of the journey.", 16, Color(0.62, 0.78, 0.88), HORIZONTAL_ALIGNMENT_CENTER)
	next_level_button = _make_button(content, "NextLevelButton", Vector2(57, 180), Vector2(330, 56), "NEXT CHAMBER", Color(0.04, 0.48, 0.63), Color(0.06, 0.65, 0.80), 18)
	next_level_button.pressed.connect(_on_next_level_pressed)
	var replay := _make_button(content, "ReplayButton", Vector2(57, 246), Vector2(330, 48), "REPLAY THIS CHAMBER", Color(0.13, 0.22, 0.34), Color(0.18, 0.33, 0.47), 14)
	replay.pressed.connect(_on_replay_pressed)
	complete_panel.hide()


func _build_help_panel() -> void:
	help_panel = _make_panel("HelpPanel", Vector2(340, 145), Vector2(600, 430))
	_make_label(help_panel, "HelpTitle", Vector2(28, 24), Vector2(544, 50), "HOW TO LEAVE AN ECHO", 27, Color(0.88, 0.97, 1.0), HORIZONTAL_ALIGNMENT_CENTER)
	var text := "1. Tap RECORD ECHO and move to Switch A.\n\n2. While standing on A, tap STOP & SEND. Your\n   recorded route will replay as a ghost.\n\n3. Move to Switch B while the echo finishes and\n   remains on A. The gate opens when both switches\n   are held at the same time.\n\n4. Reach the portal on the right to continue.\n\nOptional MEMORY SHARDS reveal fragments from the\ncourier network. They never block the exit. Some\nrooms require your recording to cross a RELAY.\n\nSentinels send you back to the entrance; if you\nare recording, the unfinished take is lost."
	_make_label(help_panel, "HelpText", Vector2(40, 83), Vector2(520, 270), text, 16, Color(0.67, 0.80, 0.89), HORIZONTAL_ALIGNMENT_LEFT)
	var close := _make_button(help_panel, "HelpClose", Vector2(185, 360), Vector2(230, 44), "GOT IT", Color(0.04, 0.48, 0.63), Color(0.06, 0.65, 0.80), 16)
	close.pressed.connect(func(): help_panel.hide())
	help_panel.hide()


func _build_level_select_panel() -> void:
	level_select_panel = _make_panel("LevelSelectPanel", Vector2(345, 155), Vector2(590, 410))
	_make_label(level_select_panel, "SelectTitle", Vector2(25, 18), Vector2(540, 46), "CHAMBER SELECT", 27, Color(0.88, 0.97, 1.0), HORIZONTAL_ALIGNMENT_CENTER)

	# Keep the chapter list scrollable so a growing campaign never overlaps the Back button.
	var chapter_scroll := ScrollContainer.new()
	chapter_scroll.name = "ChapterScroll"
	chapter_scroll.position = Vector2(30, 72)
	chapter_scroll.size = Vector2(530, 232)
	chapter_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	chapter_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	level_select_panel.add_child(chapter_scroll)

	var chapter_list := VBoxContainer.new()
	chapter_list.name = "ChapterList"
	chapter_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chapter_list.add_theme_constant_override("separation", 10)
	chapter_scroll.add_child(chapter_list)

	for i in range(LEVELS.size()):
		var button := _make_button(chapter_list, "Chapter_%02d" % (i + 1), Vector2.ZERO, Vector2(500, 56), "", Color(0.12, 0.25, 0.36), Color(0.08, 0.50, 0.65), 17)
		button.custom_minimum_size = Vector2(500, 56)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_on_chapter_selected.bind(i))
		chapter_buttons.append(button)

	var back := _make_button(level_select_panel, "SelectBack", Vector2(175, 320), Vector2(240, 46), "BACK TO MENU", Color(0.16, 0.20, 0.31), Color(0.24, 0.29, 0.42), 15)
	back.pressed.connect(func(): level_select_panel.hide())
	level_select_panel.hide()


func _build_memory_archive_panel() -> void:
	memory_archive_panel = _make_panel("MemoryArchivePanel", Vector2(300, 70), Vector2(680, 570))
	_make_label(memory_archive_panel, "ArchiveTitle", Vector2(24, 18), Vector2(632, 42), "MEMORY ARCHIVE", 27, Color(0.88, 0.97, 1.0), HORIZONTAL_ALIGNMENT_CENTER)
	memory_archive_status_label = _make_label(memory_archive_panel, "ArchiveStatus", Vector2(35, 58), Vector2(610, 26), "MEMORIES RECOVERED: 0 / %d" % LEVELS.size(), 14, Color(0.76, 0.58, 1.0), HORIZONTAL_ALIGNMENT_CENTER)

	var archive_scroll := ScrollContainer.new()
	archive_scroll.name = "ArchiveScroll"
	archive_scroll.position = Vector2(30, 92)
	archive_scroll.size = Vector2(620, 370)
	archive_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	archive_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	memory_archive_panel.add_child(archive_scroll)

	var archive_list := VBoxContainer.new()
	archive_list.name = "ArchiveList"
	archive_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	archive_list.add_theme_constant_override("separation", 9)
	archive_scroll.add_child(archive_list)

	for i in range(LEVELS.size()):
		var row := PanelContainer.new()
		row.name = "MemoryEntry_%02d" % (i + 1)
		row.custom_minimum_size = Vector2(590, 78)
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var row_style := StyleBoxFlat.new()
		row_style.bg_color = Color(0.075, 0.10, 0.16, 0.98)
		row_style.border_color = Color(0.28, 0.36, 0.48, 0.86)
		row_style.set_border_width_all(1)
		row_style.set_corner_radius_all(9)
		row.add_theme_stylebox_override("panel", row_style)

		var entry_text := VBoxContainer.new()
		entry_text.add_theme_constant_override("separation", 3)
		entry_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(entry_text)

		var title_label := Label.new()
		title_label.name = "MemoryTitle"
		title_label.custom_minimum_size = Vector2(0, 24)
		title_label.add_theme_font_size_override("font_size", 14)
		title_label.text = ""
		entry_text.add_child(title_label)
		memory_archive_title_labels.append(title_label)

		var lore_label := Label.new()
		lore_label.name = "MemoryLore"
		lore_label.custom_minimum_size = Vector2(0, 38)
		lore_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lore_label.add_theme_font_size_override("font_size", 12)
		lore_label.text = ""
		entry_text.add_child(lore_label)
		memory_archive_lore_labels.append(lore_label)
		archive_list.add_child(row)

	var back := _make_button(memory_archive_panel, "ArchiveBack", Vector2(220, 490), Vector2(240, 46), "BACK TO MENU", Color(0.16, 0.20, 0.31), Color(0.24, 0.29, 0.42), 15)
	back.pressed.connect(func():
		memory_archive_panel.hide()
		menu_root.show()
	)
	memory_archive_panel.hide()


func _open_memory_archive() -> void:
	_update_memory_archive()
	menu_root.hide()
	memory_archive_panel.show()


func _build_options_panel() -> void:
	options_panel = _make_panel("OptionsPanel", Vector2(370, 155), Vector2(540, 410))
	_make_label(options_panel, "OptionsTitle", Vector2(24, 18), Vector2(492, 42), "OPTIONS", 27, Color(0.88, 0.97, 1.0), HORIZONTAL_ALIGNMENT_CENTER)
	_make_label(options_panel, "SpeedLabel", Vector2(38, 73), Vector2(464, 30), "MOVEMENT SPEED", 16, Color(0.72, 0.83, 0.94), HORIZONTAL_ALIGNMENT_CENTER)

	speed_slow_button = _make_button(options_panel, "SpeedSlow", Vector2(36, 112), Vector2(145, 46), "SLOW", Color(0.12, 0.22, 0.35), Color(0.17, 0.32, 0.48), 15)
	speed_slow_button.pressed.connect(_set_move_speed.bind(200.0))
	speed_normal_button = _make_button(options_panel, "SpeedNormal", Vector2(197, 112), Vector2(145, 46), "NORMAL", Color(0.06, 0.40, 0.55), Color(0.08, 0.56, 0.70), 15)
	speed_normal_button.pressed.connect(_set_move_speed.bind(255.0))
	speed_fast_button = _make_button(options_panel, "SpeedFast", Vector2(358, 112), Vector2(145, 46), "FAST", Color(0.12, 0.22, 0.35), Color(0.17, 0.32, 0.48), 15)
	speed_fast_button.pressed.connect(_set_move_speed.bind(310.0))

	_make_label(options_panel, "SpeedHelp", Vector2(34, 164), Vector2(472, 34), "Changes how quickly the courier moves.", 13, Color(0.55, 0.68, 0.81), HORIZONTAL_ALIGNMENT_CENTER)
	left_handed_button = _make_button(options_panel, "LeftHandedButton", Vector2(62, 218), Vector2(416, 48), "", Color(0.20, 0.15, 0.34), Color(0.34, 0.22, 0.52), 15)
	left_handed_button.pressed.connect(_toggle_left_handed_controls)
	_make_label(options_panel, "HandedHelp", Vector2(35, 272), Vector2(470, 36), "Move the virtual joystick to the right or left side.", 12, Color(0.55, 0.68, 0.81), HORIZONTAL_ALIGNMENT_CENTER)

	var back := _make_button(options_panel, "OptionsBack", Vector2(150, 340), Vector2(240, 44), "BACK TO MENU", Color(0.16, 0.20, 0.31), Color(0.24, 0.29, 0.42), 15)
	back.pressed.connect(func():
		options_panel.hide()
		menu_root.show()
	)
	options_panel.hide()
	_update_options_panel()


func _open_options() -> void:
	_update_options_panel()
	menu_root.hide()
	options_panel.show()


func _set_move_speed(speed: float) -> void:
	player_move_speed = _normalize_move_speed(speed)
	_save_settings()
	_update_options_panel()
	if screen_state == ScreenState.PLAYING:
		status_message = "Movement speed updated."
		_update_hud()
	queue_redraw()


func _normalize_move_speed(speed: float) -> float:
	if is_equal_approx(speed, 200.0):
		return 200.0
	if is_equal_approx(speed, 310.0):
		return 310.0
	return 255.0


func _toggle_left_handed_controls() -> void:
	_set_left_handed_controls(not left_handed_controls)


func _set_left_handed_controls(enabled: bool) -> void:
	left_handed_controls = enabled
	joystick_touch_index = -1
	joystick_mouse_active = false
	joystick_direction = Vector2.ZERO
	_save_settings()
	_update_options_panel()
	queue_redraw()


func _update_options_panel() -> void:
	if not is_instance_valid(speed_slow_button):
		return
	speed_slow_button.text = "SLOW  ✓" if is_equal_approx(player_move_speed, 200.0) else "SLOW"
	speed_normal_button.text = "NORMAL  ✓" if is_equal_approx(player_move_speed, 255.0) else "NORMAL"
	speed_fast_button.text = "FAST  ✓" if is_equal_approx(player_move_speed, 310.0) else "FAST"
	left_handed_button.text = "LEFT-HANDED JOYSTICK: ON" if left_handed_controls else "LEFT-HANDED JOYSTICK: OFF"


func _update_memory_archive() -> void:
	if not is_instance_valid(memory_archive_status_label):
		return
	for i in range(LEVELS.size()):
		var found := collected_shards.has(i)
		var room: Dictionary = LEVELS[i]
		memory_archive_title_labels[i].text = "%02d   %s   •   %s" % [
			i + 1,
			str(room["name"]).to_upper(),
			"RECOVERED" if found else "NOT FOUND"
		]
		memory_archive_title_labels[i].add_theme_color_override("font_color", Color(0.82, 0.68, 1.0) if found else Color(0.48, 0.57, 0.68))
		memory_archive_lore_labels[i].text = str(room["shard_lore"]) if found else "No memory recovered. Find the violet Memory Shard in this chamber."
		memory_archive_lore_labels[i].add_theme_color_override("font_color", Color(0.72, 0.82, 0.92) if found else Color(0.43, 0.51, 0.61))
	if collected_shards.size() >= LEVELS.size():
		memory_archive_status_label.text = "SIGNAL RESTORED — ALL MEMORIES FOUND"
	else:
		memory_archive_status_label.text = "MEMORIES RECOVERED: %d / %d" % [collected_shards.size(), LEVELS.size()]


func _build_failure_panel() -> void:
	failure_panel = _make_panel("FailureResetPanel", Vector2.ZERO, Vector2(520, 194))
	failure_panel.z_index = 100
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.055, 0.045, 0.075, 0.99)
	panel_style.border_color = Color(1.0, 0.34, 0.42, 0.96)
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(22)
	panel_style.shadow_color = Color(0.28, 0.02, 0.08, 0.42)
	panel_style.shadow_size = 20
	panel_style.content_margin_left = 10
	panel_style.content_margin_right = 10
	panel_style.content_margin_top = 8
	panel_style.content_margin_bottom = 8
	failure_panel.add_theme_stylebox_override("panel", panel_style)
	failure_title_label = _make_label(failure_panel, "FailureTitle", Vector2(26, 17), Vector2(468, 42), "SIGNAL LOST", 28, Color(1.0, 0.46, 0.52), HORIZONTAL_ALIGNMENT_CENTER)
	failure_detail_label = _make_label(failure_panel, "FailureDetail", Vector2(34, 62), Vector2(452, 48), "The chamber is restarting.", 15, Color(0.83, 0.85, 0.91), HORIZONTAL_ALIGNMENT_CENTER)
	var reset_caption := _make_label(failure_panel, "ResetCaption", Vector2(34, 116), Vector2(452, 20), "REINITIALIZING CHAMBER", 11, Color(0.57, 0.67, 0.77), HORIZONTAL_ALIGNMENT_CENTER)
	failure_progress_bar = ProgressBar.new()
	failure_progress_bar.name = "ResetProgress"
	failure_progress_bar.position = Vector2(34, 146)
	failure_progress_bar.size = Vector2(452, 12)
	failure_progress_bar.min_value = 0.0
	failure_progress_bar.max_value = 1.0
	failure_progress_bar.value = 1.0
	failure_progress_bar.show_percentage = false
	var progress_track := StyleBoxFlat.new()
	progress_track.bg_color = Color(0.10, 0.12, 0.18)
	progress_track.set_corner_radius_all(6)
	var progress_fill := StyleBoxFlat.new()
	progress_fill.bg_color = Color(1.0, 0.34, 0.42)
	progress_fill.set_corner_radius_all(6)
	failure_progress_bar.add_theme_stylebox_override("background", progress_track)
	failure_progress_bar.add_theme_stylebox_override("fill", progress_fill)
	failure_panel.add_child(failure_progress_bar)
	failure_panel.hide()


func _layout_responsive_ui() -> void:
	# Keep the game world in its 1280×720 design space while the interactive
	# interface adjusts to compact landscape screens and wider desktop windows.
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var center_x := size.x * 0.5
	var compact_height := size.y < 620.0
	var width_scale := clampf(size.x / 1280.0, 0.70, 1.0)
	if is_instance_valid(menu_root):
		var logo := menu_root.get_node_or_null("Logo") as TextureRect
		var title := menu_root.get_node_or_null("Title") as Label
		if logo != null:
			logo.visible = size.y >= 620.0
			var logo_side := 174.0 if size.y >= 620.0 else 140.0
			logo.size = Vector2.ONE * logo_side
			logo.position = Vector2(center_x - logo_side * 0.5, 7.0 if size.y >= 620.0 else 4.0)
		if title != null:
			title.size.x = minf(1080.0, size.x - 32.0)
			if size.y >= 620.0:
				title.size.y = 44.0
				title.position = Vector2(center_x - title.size.x * 0.5, 184.0)
				title.add_theme_font_size_override("font_size", clampi(roundi(36.0 * width_scale), 25, 36))
			elif size.y >= 600.0:
				title.size.y = 34.0
				title.position = Vector2(center_x - title.size.x * 0.5, 146.0)
				title.add_theme_font_size_override("font_size", clampi(roundi(28.0 * width_scale), 23, 28))
			else:
				title.size.y = 62.0
				title.position = Vector2(center_x - title.size.x * 0.5, 48.0)
				title.add_theme_font_size_override("font_size", clampi(roundi(42.0 * width_scale), 30, 42))
		var tagline := menu_root.get_node_or_null("Tagline") as Label
		if tagline != null:
			tagline.size.x = minf(920.0, size.x - 40.0)
			if size.y >= 620.0:
				tagline.size.y = 36.0
				tagline.position = Vector2(center_x - tagline.size.x * 0.5, 232.0)
				tagline.add_theme_font_size_override("font_size", clampi(roundi(20.0 * width_scale), 15, 20))
			elif size.y >= 600.0:
				tagline.size.y = 28.0
				tagline.position = Vector2(center_x - tagline.size.x * 0.5, 181.0)
				tagline.add_theme_font_size_override("font_size", clampi(roundi(15.0 * width_scale), 12, 15))
			else:
				tagline.size.y = 36.0
				tagline.position = Vector2(center_x - tagline.size.x * 0.5, 121.0)
				tagline.add_theme_font_size_override("font_size", clampi(roundi(22.0 * width_scale), 14, 22))
		var intro := menu_root.get_node_or_null("Intro") as Label
		if intro != null:
			intro.size.x = minf(780.0, size.x - 64.0)
			if size.y >= 620.0:
				intro.text = "Record your movement. Let your echo hold the past\nwhile you find a way into the future."
				intro.size.y = 58.0
				intro.position = Vector2(center_x - intro.size.x * 0.5, 272.0)
				intro.add_theme_font_size_override("font_size", clampi(roundi(17.0 * width_scale), 13, 17))
				intro.visible = true
			elif size.y >= 600.0:
				intro.size.y = 40.0
				intro.position = Vector2(center_x - intro.size.x * 0.5, 211.0)
				intro.add_theme_font_size_override("font_size", clampi(roundi(13.0 * width_scale), 10, 13))
				intro.visible = false
			else:
				intro.size.y = 48.0
				intro.position = Vector2(center_x - intro.size.x * 0.5, 165.0)
				intro.add_theme_font_size_override("font_size", clampi(roundi(18.0 * width_scale), 13, 18))
				intro.visible = size.y >= 340.0
		var progress := menu_root.get_node_or_null("Progress") as Label
		if progress != null:
			progress.size.x = minf(800.0, size.x - 32.0)
			progress.visible = size.y >= 280.0
			progress.position = Vector2(center_x - progress.size.x * 0.5, size.y - 60.0 if compact_height else 619.0)
		var menu_button_names := ["StartButton", "ChaptersButton", "HowToPlayButton", "MemoryArchiveButton", "OptionsButton"]
		var normal_button_heights: Array[float] = [54.0, 50.0, 48.0, 42.0, 42.0]
		var normal_button_y: Array[float] = [340.0, 404.0, 458.0, 512.0, 564.0]
		for button_index in range(menu_button_names.size()):
			var centered_button := menu_root.get_node_or_null(menu_button_names[button_index]) as Button
			if centered_button == null:
				continue
			centered_button.size.x = minf(330.0, size.x - 48.0)
			centered_button.pivot_offset = centered_button.size * 0.5
			centered_button.position.x = center_x - centered_button.size.x * 0.5
			# A compact layout may have changed height and y-position. Restore the
			# authored full-height stack whenever the viewport grows back.
			if size.y >= 620.0:
				centered_button.size.y = normal_button_heights[button_index]
				centered_button.position.y = normal_button_y[button_index]
		if compact_height:
			var compact_button_names := ["StartButton", "ChaptersButton", "HowToPlayButton", "MemoryArchiveButton", "OptionsButton"]
			if size.y < 620.0:
				# Very short landscape phones cannot fit a single-column menu without
				# hiding controls. Reflow into two columns with touch-sized buttons.
				var ultra_title := menu_root.get_node_or_null("Title") as Label
				if ultra_title != null:
					ultra_title.position.y = 8.0
					ultra_title.size.y = 46.0
					ultra_title.add_theme_font_size_override("font_size", clampi(roundi(42.0 * width_scale), 30, 42))
				if tagline != null:
					tagline.position.y = 52.0
					tagline.size.y = 28.0
					tagline.add_theme_font_size_override("font_size", clampi(roundi(15.0 * width_scale), 11, 15))
				if intro != null:
					# A single compact line preserves the hint without colliding with the first row.
					intro.text = "Record your route. Let your echo hold the past."
					intro.position.y = 80.0
					intro.size.y = 34.0
					intro.add_theme_font_size_override("font_size", clampi(roundi(12.0 * width_scale), 10, 12))
					intro.visible = size.y >= 340.0
				var ultra_top := 136.0
				if size.y < 340.0:
					# On extra-short landscape screens, reclaim the intro's vertical space.
					if ultra_title != null:
						ultra_title.position.y = 4.0
						ultra_title.size.y = 38.0
						ultra_title.add_theme_font_size_override("font_size", clampi(roundi(34.0 * width_scale), 26, 34))
					if tagline != null:
						tagline.position.y = 42.0
						tagline.size.y = 22.0
						tagline.add_theme_font_size_override("font_size", clampi(roundi(12.0 * width_scale), 10, 12))
					ultra_top = 74.0
				var column_width := (size.x - 48.0) * 0.5
				var row_heights: Array[float] = [0.0, 0.0, 0.0]
				for i in range(compact_button_names.size()):
					var ultra_button := menu_root.get_node_or_null(compact_button_names[i]) as Button
					if ultra_button == null:
						continue
					var column := i % 2
					var row_index := floori(float(i) / 2.0)
					ultra_button.size = Vector2(column_width, 44.0)
					ultra_button.position = Vector2(16.0 + float(column) * (column_width + 16.0), ultra_top)
					ultra_button.pivot_offset = ultra_button.size * 0.5
					# Godot's theme can enforce a taller real minimum than the requested
					# size. Measure it so the following row never overlaps on any version.
					row_heights[row_index] = maxf(row_heights[row_index], ultra_button.size.y)
				var row_y := ultra_top
				for row_index in range(row_heights.size()):
					for i in range(compact_button_names.size()):
						if floori(float(i) / 2.0) != row_index:
							continue
						var row_button := menu_root.get_node_or_null(compact_button_names[i]) as Button
						if row_button != null:
							row_button.position.y = row_y
					row_y += row_heights[row_index] + 6.0
				if progress != null:
					progress.position.y = size.y - 24.0
					progress.size.y = 20.0
			else:
				var compact_top := size.y * 0.43
				if intro != null and intro.visible:
					# Use the actual visible intro bounds to avoid overlapping its text.
					compact_top = maxf(compact_top, intro.position.y + intro.size.y + 20.0)
				elif tagline != null:
					compact_top = maxf(compact_top, tagline.position.y + tagline.size.y + 18.0)
				var measured_button_height := 44.0
				for button_name in compact_button_names:
					var measured_button := menu_root.get_node_or_null(button_name) as Button
					if measured_button != null:
						measured_button.size.y = 44.0
						measured_button_height = maxf(measured_button_height, measured_button.size.y)
				var compact_gap := maxf(clampf(size.y * 0.083, 44.0, 50.0), measured_button_height + 4.0)
				if progress != null and compact_button_names.size() > 1:
					var available_gap := (progress.position.y - compact_top - measured_button_height - 8.0) / float(compact_button_names.size() - 1)
					compact_gap = minf(compact_gap, available_gap)
				for i in range(compact_button_names.size()):
					var compact_button := menu_root.get_node_or_null(compact_button_names[i]) as Button
					if compact_button != null:
						compact_button.position.y = compact_top + float(i) * compact_gap
						compact_button.size.y = 44.0
		var version_label := menu_root.get_node_or_null("Version") as Control
		if version_label != null:
			if size.y < 420.0:
				version_label.hide()
			else:
				version_label.show()
			version_label.position.y = size.y - 24.0
	if is_instance_valid(game_hud):
		if is_instance_valid(level_title_label):
			level_title_label.size.x = minf(570.0, size.x * 0.43)
		if is_instance_valid(echo_status_label):
			echo_status_label.position.x = size.x - 475.0
		if is_instance_valid(pause_button):
			pause_button.position = Vector2(size.x - 170.0, 12.0)
		if is_instance_valid(level_hint_label):
			level_hint_label.size.x = maxf(420.0, size.x - 380.0)
		if is_instance_valid(status_label):
			status_label.size.x = clampf(size.x - 540.0, 420.0, 740.0)
			status_label.position = Vector2(center_x - status_label.size.x * 0.5, size.y - 110.0)
		var move_tip := game_hud.get_node_or_null("MoveTip") as Control
		if move_tip != null:
			move_tip.position.y = size.y - 105.0
		var bottom_menu_control := game_hud.get_node_or_null("MenuButton") as Button
		var record_control := game_hud.get_node_or_null("RecordButton") as Button
		var latch_control := game_hud.get_node_or_null("LatchSwitchBButton") as Button
		var reset_control := game_hud.get_node_or_null("ResetButton") as Button
		var bottom_y := size.y - 66.0
		# Make the bottom action row fit on narrow landscape devices instead of
		# letting fixed minimum widths overlap the menu and restart controls.
		var nav_width := clampf(size.x * 0.14, 92.0, 150.0)
		var action_gap := clampf(size.x * 0.015, 8.0, 18.0)
		var side_margin := maxf(12.0, size.x * 0.025)
		var max_action_width := size.x * 0.5 - side_margin - nav_width - action_gap * 0.5 - 8.0
		var action_width := minf(clampf(size.x * 0.27, 120.0, 270.0), max_action_width)
		if bottom_menu_control != null:
			bottom_menu_control.size.x = nav_width
			bottom_menu_control.text = "MENU" if nav_width < 112.0 else "MAIN MENU"
			bottom_menu_control.add_theme_font_size_override("font_size", clampi(roundi(nav_width * 0.115), 10, 13))
			bottom_menu_control.pivot_offset = bottom_menu_control.size * 0.5
			bottom_menu_control.position = Vector2(side_margin, bottom_y)
		if record_control != null:
			record_control.size.x = action_width
			record_control.add_theme_font_size_override("font_size", clampi(roundi(action_width * 0.085), 10, 17))
			record_control.pivot_offset = record_control.size * 0.5
			record_control.position = Vector2(center_x - action_width - action_gap * 0.5, bottom_y)
		if latch_control != null:
			latch_control.size.x = action_width
			latch_control.add_theme_font_size_override("font_size", clampi(roundi(action_width * 0.075), 10, 15))
			latch_control.pivot_offset = latch_control.size * 0.5
			latch_control.position = Vector2(center_x + action_gap * 0.5, bottom_y)
		if reset_control != null:
			reset_control.size.x = nav_width
			reset_control.text = "RESTART" if nav_width < 112.0 else "RESTART ROOM"
			reset_control.add_theme_font_size_override("font_size", clampi(roundi(nav_width * 0.115), 10, 13))
			reset_control.pivot_offset = reset_control.size * 0.5
			reset_control.position = Vector2(size.x - side_margin - nav_width, bottom_y)
	_layout_centered_panels()


func _layout_centered_panels() -> void:
	for panel in [complete_panel, help_panel, level_select_panel, memory_archive_panel, options_panel, failure_panel]:
		if is_instance_valid(panel):
			panel.position = (size - panel.size) * 0.5


func _make_panel(panel_name: String, panel_position: Vector2, panel_size: Vector2) -> Panel:
	var panel := Panel.new()
	panel.name = panel_name
	panel.position = panel_position
	panel.size = panel_size
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.004, 0.022, 0.032, 0.992)
	style.border_color = Color(0.10, 0.84, 0.77, 0.86)
	style.set_border_width_all(2)
	style.set_corner_radius_all(18)
	style.shadow_color = Color(0.0, 0.52, 0.48, 0.18)
	style.shadow_size = 18
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	return panel


func _make_label(parent: Control, label_name: String, label_position: Vector2, label_size: Vector2, text_value: String, font_size: int, color: Color, alignment: int) -> Label:
	var label := Label.new()
	label.name = label_name
	label.position = label_position
	label.size = label_size
	label.text = text_value
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label


func _make_button(parent: Control, button_name: String, button_position: Vector2, button_size: Vector2, button_text: String, normal_color: Color, hover_color: Color, font_size: int) -> Button:
	var button := Button.new()
	button.name = button_name
	button.position = button_position
	button.size = button_size
	button.custom_minimum_size = Vector2(0, 44)
	button.pivot_offset = button_size * 0.5
	button.text = button_text
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", Color(0.78, 1.0, 0.96))
	button.add_theme_color_override("font_hover_color", Color(0.98, 1.0, 1.0))
	button.add_theme_color_override("font_pressed_color", Color(0.49, 1.0, 0.91))
	button.add_theme_color_override("font_disabled_color", Color(0.30, 0.49, 0.50))
	var primary_button := button_name in ["StartButton", "RecordButton", "NextLevelButton"]
	var archive_button := button_name == "MemoryArchiveButton"
	var normal_fill := Color(0.016, 0.22, 0.21, 0.99) if primary_button else Color(0.006, 0.044, 0.055, 0.99)
	var hover_fill := Color(0.025, 0.36, 0.32, 0.99) if primary_button else Color(0.014, 0.15, 0.16, 0.99)
	if archive_button:
		normal_fill = Color(0.055, 0.035, 0.11, 0.99)
		hover_fill = Color(0.12, 0.06, 0.20, 0.99)
	var edge_color := Color(0.20, 0.98, 0.85, 0.84) if primary_button else Color(0.09, 0.60, 0.61, 0.63)
	if archive_button:
		edge_color = Color(0.46, 0.35, 0.92, 0.72)
	var normal := StyleBoxFlat.new()
	normal.bg_color = normal_fill
	normal.border_color = edge_color
	normal.set_border_width_all(2 if primary_button else 1)
	normal.set_corner_radius_all(13)
	normal.shadow_color = Color(0.0, 0.44, 0.42, 0.13)
	normal.shadow_size = 8 if primary_button else 4
	var hover := StyleBoxFlat.new()
	hover.bg_color = hover_fill
	hover.border_color = Color(0.53, 1.0, 0.92, 0.98)
	hover.set_border_width_all(2)
	hover.set_corner_radius_all(13)
	hover.shadow_color = Color(0.02, 0.80, 0.68, 0.22)
	hover.shadow_size = 10
	var pressed := StyleBoxFlat.new()
	pressed.bg_color = normal_fill.darkened(0.18)
	pressed.border_color = Color(0.28, 0.96, 0.83, 0.9)
	pressed.set_border_width_all(2 if primary_button else 1)
	pressed.set_corner_radius_all(13)
	var disabled := StyleBoxFlat.new()
	disabled.bg_color = Color(0.012, 0.035, 0.044)
	disabled.border_color = Color(0.12, 0.28, 0.30, 0.52)
	disabled.set_border_width_all(1)
	disabled.set_corner_radius_all(13)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)
	button.mouse_entered.connect(_animate_button.bind(button, 1.025))
	button.mouse_exited.connect(_animate_button.bind(button, 1.0))
	button.button_down.connect(_animate_button.bind(button, 0.975))
	button.button_up.connect(_animate_button.bind(button, 1.0))
	parent.add_child(button)
	return button


func _animate_button(button: Button, scale_target: float) -> void:
	if not is_instance_valid(button):
		return
	var animation := create_tween()
	animation.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	animation.tween_property(button, "scale", Vector2.ONE * scale_target, 0.12)


func _show_menu() -> void:
	failure_reset_timer = 0.0
	failure_reset_reason = ""
	if is_instance_valid(failure_panel):
		failure_panel.hide()
	screen_state = ScreenState.MENU
	is_recording = false
	joystick_touch_index = -1
	joystick_mouse_active = false
	joystick_direction = Vector2.ZERO
	menu_root.show()
	game_hud.hide()
	if is_instance_valid(options_panel):
		options_panel.hide()
	complete_panel.hide()
	help_panel.hide()
	level_select_panel.hide()
	if is_instance_valid(memory_archive_panel):
		memory_archive_panel.hide()
	_update_menu_progress()
	queue_redraw()


func _on_start_pressed() -> void:
	_start_level(unlocked_level)


func _start_level(level_index: int) -> void:
	failure_reset_timer = 0.0
	failure_reset_reason = ""
	if is_instance_valid(failure_panel):
		failure_panel.hide()
	current_level_index = clampi(level_index, 0, LEVELS.size() - 1)
	joystick_touch_index = -1
	joystick_mouse_active = false
	joystick_direction = Vector2.ZERO
	level_data = LEVELS[current_level_index]
	player_position = level_data["spawn"]
	echo_position = Vector2.ZERO
	echo_visible = false
	echo_playing = false
	echo_elapsed = 0.0
	echo_linger_left = 0.0
	echo_track.clear()
	is_recording = false
	recording_elapsed = 0.0
	record_sample_accumulator = 0.0
	recording_track.clear()
	door_open = false
	switch_b_latched = false
	gate_open_timer = 0.0
	timed_gate_failed = false
	hazard_time = 0.0
	status_message = str(level_data["hint"])
	screen_state = ScreenState.PLAYING
	menu_root.hide()
	game_hud.show()
	complete_panel.hide()
	help_panel.hide()
	level_select_panel.hide()
	if is_instance_valid(memory_archive_panel):
		memory_archive_panel.hide()
	if is_instance_valid(options_panel):
		options_panel.hide()
	pause_button.text = "PAUSE"
	_update_hud()
	queue_redraw()


func _on_record_pressed() -> void:
	if screen_state != ScreenState.PLAYING or failure_reset_timer > 0.0:
		return
	if not is_recording:
		is_recording = true
		recording_elapsed = 0.0
		record_sample_accumulator = 0.0
		recording_track.clear()
		_add_record_sample(0.0, player_position)
		echo_visible = false
		echo_playing = false
		echo_track.clear()
		status_message = "Recording... move to SWITCH A, then press STOP & SEND."
	else:
		_finish_recording()
	_update_hud()
	queue_redraw()




func _on_latch_switch_b_pressed() -> void:
	if screen_state != ScreenState.PLAYING or failure_reset_timer > 0.0:
		return
	if str(level_data.get("plate_b_mode", "hold")) != "toggle":
		return
	if door_open:
		status_message = "GATE OPEN — cross the barrier and reach the portal."
		_update_hud()
		return

	var echo_on_a := echo_visible and not echo_playing and echo_position.distance_to(level_data["plate_a"]) < 43.0
	if not echo_on_a:
		status_message = "WAIT FOR ECHO — let it hold SWITCH A before latching B."
	elif player_position.distance_to(level_data["plate_b"]) >= 50.0:
		status_message = "MOVE TO SWITCH B — stand close to latch it."
	else:
		switch_b_latched = not switch_b_latched
		if switch_b_latched:
			status_message = "SWITCH B LATCHED — leave it and cross the gate."
		else:
			status_message = "SWITCH B RELEASED — return to B to latch it again."
	_update_hud()
	queue_redraw()


func _finish_recording() -> void:
	if not is_recording:
		return
	if recording_elapsed < MIN_RECORD_SECONDS:
		status_message = "TOO SHORT — keep recording until at least 0.7 seconds, then stop on SWITCH A."
		return
	_add_record_sample(recording_elapsed, player_position)
	is_recording = false
	if player_position.distance_to(level_data["plate_a"]) >= 42.0:
		echo_visible = false
		echo_playing = false
		echo_track.clear()
		status_message = "ROUTE REJECTED — finish the recording on SWITCH A, then try again."
		if _room_requires_relay():
			_schedule_room_reset("ROUTE REJECTED", status_message)
		else:
			_update_hud()
			queue_redraw()
		return
	if level_data.has("echo_waypoints"):
		var required_waypoints: Array = level_data["echo_waypoints"]
		if not _track_passes_waypoints_in_order(recording_track, required_waypoints, 40.0):
			echo_visible = false
			echo_playing = false
			echo_track.clear()
			var relay_sequence := PackedStringArray()
			for relay_index in range(required_waypoints.size()):
				relay_sequence.append("RELAY %d" % (relay_index + 1))
			status_message = "ROUTE REJECTED — pass through %s in order before finishing on SWITCH A." % ", then ".join(relay_sequence)
			_schedule_room_reset("RELAY SEQUENCE FAILED", status_message)
			return
	if level_data.has("echo_waypoint"):
		var relay_position: Vector2 = level_data["echo_waypoint"]
		if not _track_passes_waypoint(recording_track, relay_position, 40.0):
			echo_visible = false
			echo_playing = false
			echo_track.clear()
			status_message = "ROUTE REJECTED — pass through the RELAY BEACON before finishing on SWITCH A."
			_schedule_room_reset("RELAY BEACON MISSED", status_message)
			return
	if level_data.has("echo_jammer"):
		var jammer_position: Vector2 = level_data["echo_jammer"]
		var jammer_radius := float(level_data.get("echo_jammer_radius", 100.0))
		if _track_passes_waypoint(recording_track, jammer_position, jammer_radius):
			echo_visible = false
			echo_playing = false
			echo_track.clear()
			status_message = "ECHO DEAD ZONE — the recorded route crossed the blackout. Reroute around it."
			_schedule_room_reset("ECHO JAMMED", status_message)
			return
	echo_track = recording_track.copy_track()
	echo_playing = echo_track.samples.size() > 1
	echo_visible = echo_playing
	echo_elapsed = 0.0
	echo_linger_left = 0.0
	if echo_track.samples.size() > 0:
		echo_position = echo_track.position_at(0.0)
	status_message = "Echo released. Move to SWITCH B and stay there until the gate opens."
	_update_hud()
	queue_redraw()


func _add_record_sample(sample_time: float, point: Vector2) -> void:
	recording_track.add_sample(sample_time, point)


func _track_passes_waypoint(track: Variant, waypoint: Vector2, radius: float) -> bool:
	return _track_waypoint_progress(track, waypoint, radius, 0.0) >= 0.0


func _is_relay_waypoint_linked(waypoint_index: int) -> bool:
	var waypoints: Array = []
	if level_data.has("echo_waypoints"):
		waypoints = level_data["echo_waypoints"]
	elif level_data.has("echo_waypoint"):
		waypoints = [level_data["echo_waypoint"]]

	if waypoint_index < 0 or waypoint_index >= waypoints.size():
		return false

	var route: Variant = null
	if is_recording:
		route = recording_track
	elif echo_visible:
		route = echo_track
	if route == null:
		return false

	# Evaluate each beacon's first crossing. A later beacon visited before this
	# one invalidates its linked state; the visual indicator mirrors route order.
	var route_progresses: Array[float] = []
	for waypoint_value in waypoints:
		if not (waypoint_value is Vector2):
			return false
		route_progresses.append(_track_waypoint_progress(route, waypoint_value, 40.0, 0.0))

	for required_index in range(waypoint_index + 1):
		if route_progresses[required_index] < 0.0:
			return false
		if required_index > 0 and route_progresses[required_index] <= route_progresses[required_index - 1]:
			return false

	var target_progress := route_progresses[waypoint_index]
	for later_index in range(waypoint_index + 1, route_progresses.size()):
		if route_progresses[later_index] >= 0.0 and route_progresses[later_index] < target_progress:
			return false
	return true


func _track_passes_waypoints_in_order(track: Variant, waypoints: Array, radius: float) -> bool:
	if track.samples.is_empty() or waypoints.is_empty():
		return false

	var minimum_route_progress := 0.0
	for waypoint_value in waypoints:
		if not (waypoint_value is Vector2):
			return false
		var route_progress := _track_waypoint_progress(track, waypoint_value, radius, minimum_route_progress)
		if route_progress < 0.0:
			return false
		# A later relay must be encountered later along the sample path, not merely
		# somewhere in the route. The tiny offset prevents reusing the same crossing.
		minimum_route_progress = route_progress + 0.0001
	return true


func _track_waypoint_progress(track: Variant, waypoint: Vector2, radius: float, minimum_route_progress: float) -> float:
	if track.samples.is_empty():
		return -1.0
	var safe_radius := maxf(0.0, radius)
	var first_position: Vector2 = track.samples.front()["p"]
	if minimum_route_progress <= 0.0 and first_position.distance_to(waypoint) <= safe_radius:
		return 0.0
	if track.samples.size() < 2:
		return -1.0

	var best_progress := -1.0
	for i in range(1, track.samples.size()):
		var from_point: Vector2 = track.samples[i - 1]["p"]
		var to_point: Vector2 = track.samples[i]["p"]
		var segment := to_point - from_point
		var segment_length_squared := segment.length_squared()
		var segment_progress_start := float(i - 1)
		if segment_length_squared <= 0.0001:
			if segment_progress_start + 0.0001 >= minimum_route_progress and from_point.distance_to(waypoint) <= safe_radius:
				if best_progress < 0.0 or segment_progress_start < best_progress:
					best_progress = segment_progress_start
			continue

		var weight := clampf((waypoint - from_point).dot(segment) / segment_length_squared, 0.0, 1.0)
		var closest_point := from_point + segment * weight
		if closest_point.distance_to(waypoint) > safe_radius:
			continue
		var candidate_progress := segment_progress_start + weight
		if candidate_progress + 0.0001 < minimum_route_progress:
			continue
		if best_progress < 0.0 or candidate_progress < best_progress:
			best_progress = candidate_progress
	return best_progress


func _update_player(delta: float) -> void:
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if joystick_direction.length() > 0.12:
		direction = joystick_direction
	var next_position := player_position + direction * player_move_speed * delta
	next_position.x = clampf(next_position.x, ROOM_LEFT + PLAYER_RADIUS + 10.0, ROOM_RIGHT - PLAYER_RADIUS - 10.0)
	next_position.y = clampf(next_position.y, ROOM_TOP + PLAYER_RADIUS + 13.0, ROOM_BOTTOM - PLAYER_RADIUS - 12.0)
	var gate_block_x := GATE_X - PLAYER_RADIUS - 3.0
	if not door_open and player_position.x <= gate_block_x and next_position.x > gate_block_x:
		next_position.x = gate_block_x
	player_position = next_position


func _update_echo(delta: float) -> void:
	if echo_playing:
		echo_elapsed += delta
		echo_position = echo_track.position_at(echo_elapsed)
		if echo_track.samples.size() > 0 and echo_elapsed >= echo_track.duration():
			echo_playing = false
			echo_linger_left = float(level_data.get("linger", 8.0))
			echo_position = echo_track.position_at(echo_track.duration())
	elif echo_visible:
		echo_linger_left -= delta
		if echo_linger_left <= 0.0:
			echo_visible = false
			status_message = "Your echo faded. Record another route ending on SWITCH A."


func _room_requires_relay() -> bool:
	return level_data.has("echo_waypoint") or level_data.has("echo_waypoints")


func _schedule_room_reset(reason: String, detail: String) -> void:
	if failure_reset_timer > 0.0:
		return
	failure_reset_reason = reason
	failure_reset_timer = FAILURE_RESET_DURATION
	status_message = detail
	joystick_touch_index = -1
	joystick_mouse_active = false
	joystick_direction = Vector2.ZERO
	# Discard all run state immediately; the short overlay only gives the player
	# time to read the reason before the complete chamber state is restarted.
	is_recording = false
	recording_elapsed = 0.0
	record_sample_accumulator = 0.0
	recording_track.clear()
	player_position = level_data["spawn"]
	if is_instance_valid(failure_title_label):
		failure_title_label.text = reason.to_upper()
	if is_instance_valid(failure_detail_label):
		failure_detail_label.text = detail
	if is_instance_valid(failure_progress_bar):
		failure_progress_bar.value = 1.0
	if is_instance_valid(failure_panel):
		failure_panel.modulate.a = 0.0
		failure_panel.show()
		var fade := create_tween()
		fade.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		fade.tween_property(failure_panel, "modulate:a", 1.0, 0.16)
	game_hud.hide()
	queue_redraw()


func _check_sentinel_collision() -> void:
	if failure_reset_timer > 0.0 or not bool(level_data.get("hazard", false)):
		return
	var hazard_x := 640.0 + sin(hazard_time * float(level_data["hazard_speed"])) * float(level_data["hazard_amplitude"])
	var sentinel := Vector2(hazard_x, float(level_data["hazard_y"]))
	if player_position.distance_to(sentinel) < 27.0:
		var detail := "SENTINEL CONTACT — recording lost; the whole chamber is resetting."
		if not is_recording:
			detail = "SENTINEL CONTACT — you were caught. The whole chamber is resetting."
		_schedule_room_reset("SENTINEL CONTACT", detail)


func _check_memory_shard_collection() -> void:
	if not level_data.has("memory_shard") or collected_shards.has(current_level_index):
		return
	var shard_position: Vector2 = level_data["memory_shard"]
	if player_position.distance_to(shard_position) > 30.0:
		return

	collected_shards.append(current_level_index)
	collected_shards.sort()
	var lore_fragment := str(level_data.get("shard_lore", "A memory from the courier network survived."))
	if collected_shards.size() >= LEVELS.size():
		status_message = "SIGNAL RESTORED — every courier memory has returned. " + lore_fragment
	else:
		status_message = "MEMORY: " + lore_fragment
	_save_progress()
	_update_menu_progress()
	_update_hud()
	queue_redraw()


func _update_timed_gate(delta: float) -> void:
	if not door_open or gate_open_timer <= 0.0:
		return
	gate_open_timer = maxf(0.0, gate_open_timer - delta)
	if gate_open_timer > 0.0:
		return

	var gate_block_x := GATE_X - PLAYER_RADIUS - 3.0
	if player_position.x <= gate_block_x:
		door_open = false
		timed_gate_failed = true
		status_message = "PULSE GATE CLOSED — leave SWITCH B and return to re-arm the crossing window."
	else:
		# Once the player clears the barrier, the route is committed and the portal stays powered.
		status_message = "GATE CROSSED — the portal remains powered. Reach the exit."


func _check_puzzle_state() -> void:
	if door_open:
		if player_position.distance_to(Vector2(1170, 365)) < 39.0:
			_complete_level()
		return
	var toggle_switch_b := str(level_data.get("plate_b_mode", "hold")) == "toggle"
	var echo_on_a := echo_visible and (not toggle_switch_b or not echo_playing) and echo_position.distance_to(level_data["plate_a"]) < 43.0
	var player_near_b := player_position.distance_to(level_data["plate_b"]) < 43.0
	var player_on_b := switch_b_latched if toggle_switch_b else player_near_b

	# A missed timed-gate window cannot instantly re-open while the player is still
	# holding Switch B. Leave either switch and return to re-arm another attempt.
	if timed_gate_failed and (not echo_on_a or not player_on_b):
		timed_gate_failed = false

	if echo_on_a and player_on_b:
		if timed_gate_failed:
			status_message = "PULSE GATE MISSED — leave SWITCH B and return to try again."
			return
		door_open = true
		gate_open_timer = maxf(0.0, float(level_data.get("gate_open_seconds", 0.0)))
		if gate_open_timer > 0.0:
			status_message = "PULSE GATE OPEN — cross the barrier within %.1f seconds, then reach the portal." % gate_open_timer
		elif toggle_switch_b:
			status_message = "SWITCH B LATCHED — GATE OPEN! Cross the barrier and reach the portal."
		else:
			status_message = "BOTH SWITCHES HELD — GATE OPEN! Reach the portal."
		return
	if is_recording and player_position.distance_to(level_data["plate_a"]) < 42.0:
		status_message = "Good! Stop recording here so your echo holds SWITCH A."
	elif echo_visible and not door_open:
		if not echo_on_a and echo_playing:
			status_message = "Your echo is travelling. Stay near SWITCH B and wait for it to reach A."
		elif not echo_on_a and not echo_playing:
			status_message = "Your echo missed SWITCH A. Record again and finish on the blue switch."
		elif echo_on_a and not player_on_b:
			if toggle_switch_b:
				status_message = "ECHO HOLDS A — move to SWITCH B, then tap LATCH SWITCH B."
			else:
				status_message = "Echo holds A. Move yourself onto SWITCH B."


func _complete_level() -> void:
	if screen_state == ScreenState.COMPLETE:
		return
	screen_state = ScreenState.COMPLETE
	is_recording = false
	rooms_completed += 1
	if current_level_index < LEVELS.size() - 1:
		unlocked_level = maxi(unlocked_level, current_level_index + 1)
		complete_title_label.text = "CHAMBER CLEARED"
		complete_body_label.text = "Your echo helped open the way.\nThe next chamber is now unlocked."
		next_level_button.text = "NEXT CHAMBER"
	else:
		unlocked_level = LEVELS.size() - 1
		complete_title_label.text = "THE SIGNAL CONTINUES"
		complete_body_label.text = "You finished this early campaign.\nYour route is now part of the journey."
		next_level_button.text = "RESTART CAMPAIGN"
	_save_progress()
	_update_menu_progress()
	complete_panel.show()
	_update_hud()
	queue_redraw()


func _on_next_level_pressed() -> void:
	if current_level_index < LEVELS.size() - 1:
		_start_level(current_level_index + 1)
	else:
		_start_level(0)


func _on_replay_pressed() -> void:
	_start_level(current_level_index)


func _on_reset_pressed() -> void:
	if failure_reset_timer > 0.0:
		return
	_start_level(current_level_index)


func _on_pause_pressed() -> void:
	if failure_reset_timer > 0.0:
		return
	if screen_state == ScreenState.PLAYING:
		screen_state = ScreenState.PAUSED
		joystick_touch_index = -1
		joystick_mouse_active = false
		joystick_direction = Vector2.ZERO
		pause_button.text = "RESUME"
		status_message = "Paused. Press RESUME to continue."
	elif screen_state == ScreenState.PAUSED:
		screen_state = ScreenState.PLAYING
		pause_button.text = "PAUSE"
		status_message = "Back in the chamber."
	_update_hud()
	queue_redraw()


func _open_help() -> void:
	help_panel.show()


func _open_level_select() -> void:
	_update_chapter_buttons()
	level_select_panel.show()


func _on_chapter_selected(index: int) -> void:
	if index <= unlocked_level:
		_start_level(index)


func _update_chapter_buttons() -> void:
	for i in range(chapter_buttons.size()):
		var button := chapter_buttons[i]
		var prefix := "UNLOCKED" if i <= unlocked_level else "LOCKED"
		button.text = "%02d   %s   •   %s" % [i + 1, str(LEVELS[i]["name"]).to_upper(), prefix]
		button.disabled = i > unlocked_level


func _update_menu_progress() -> void:
	if is_instance_valid(memory_archive_status_label):
		_update_memory_archive()
	if menu_progress_label:
		menu_progress_label.text = "CHAMBERS DISCOVERED: %d / %d   •   MEMORIES: %d / %d" % [unlocked_level + 1, LEVELS.size(), collected_shards.size(), LEVELS.size()]
	if start_button:
		start_button.text = "CONTINUE JOURNEY  •  %02d" % (unlocked_level + 1)
	_update_chapter_buttons()


func _update_hud() -> void:
	if not is_instance_valid(level_title_label):
		return
	if level_data.is_empty():
		return
	level_title_label.text = "%02d  /  %s" % [current_level_index + 1, str(level_data["name"]).to_upper()]
	level_hint_label.text = str(level_data["subtitle"])
	status_label.text = status_message
	if is_recording:
		record_button.text = "STOP & SEND ECHO  •  %ds" % int(ceil(MAX_RECORD_SECONDS - recording_elapsed))
		echo_status_label.text = "ECHO: RECORDING"
	else:
		record_button.text = "RECORD ECHO"
		if door_open and gate_open_timer > 0.0:
			echo_status_label.text = "GATE: %.1fs TO CROSS" % gate_open_timer
		elif echo_playing:
			echo_status_label.text = "ECHO: REPLAYING ROUTE"
		elif echo_visible:
			echo_status_label.text = "ECHO: %.1fs LEFT" % maxf(0.0, echo_linger_left)
		elif door_open:
			echo_status_label.text = "ECHO: GATE OPEN"
		else:
			echo_status_label.text = "ECHO: READY"
	record_button.disabled = screen_state == ScreenState.PAUSED or screen_state == ScreenState.COMPLETE or failure_reset_timer > 0.0
	if is_instance_valid(latch_switch_button):
		var toggle_mode := str(level_data.get("plate_b_mode", "hold")) == "toggle"
		latch_switch_button.visible = toggle_mode
		latch_switch_button.disabled = screen_state != ScreenState.PLAYING or door_open
		if door_open and switch_b_latched:
			latch_switch_button.text = "SWITCH B LATCHED"
		else:
			latch_switch_button.text = "RELEASE SWITCH B" if switch_b_latched else "LATCH SWITCH B"


func _load_progress() -> void:
	var saved: Dictionary = PROGRESS_STORE.load_progress(LEVELS.size())
	unlocked_level = int(saved["unlocked_level"])
	rooms_completed = int(saved["rooms_completed"])
	collected_shards = saved.get("collected_shards", PackedInt32Array())


func _load_settings() -> void:
	var settings: Dictionary = SETTINGS_STORE.load_settings()
	player_move_speed = float(settings["move_speed"])
	left_handed_controls = bool(settings["left_handed_controls"])


func _save_settings() -> void:
	var error: int = SETTINGS_STORE.save_settings(player_move_speed, left_handed_controls)
	if error != OK:
		push_warning("Could not save control settings. Error code: %s" % error)


func _save_progress() -> void:
	var error: int = PROGRESS_STORE.save_progress(unlocked_level, rooms_completed, PROGRESS_STORE.SAVE_PATH, collected_shards)
	if error != OK:
		push_warning("Could not save campaign progress. Error code: %s" % error)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.002, 0.009, 0.019), true)
	for star in stars:
		draw_circle(Vector2(star.x, star.y), star.z, Color(0.08, 0.60, 0.54, 0.38))
	if screen_state == ScreenState.MENU:
		_draw_menu_art()
		return
	_draw_room()
	if screen_state == ScreenState.PAUSED:
		draw_rect(Rect2(0, 100, size.x, 520), Color(0.002, 0.012, 0.02, 0.38), true)


func _draw_menu_art() -> void:
	var center := size * Vector2(0.5, 0.53)
	var dimension := minf(size.x, size.y)
	# Receding circuit-room outlines echo the supplied logo's geometric tunnel.
	for depth in range(5):
		var inset_x := size.x * (0.07 + float(depth) * 0.042)
		var top_y := size.y * (0.15 + float(depth) * 0.045)
		var bottom_y := size.y * (0.86 - float(depth) * 0.045)
		var corner := dimension * (0.12 - float(depth) * 0.012)
		var points := PackedVector2Array([
			Vector2(inset_x + corner, top_y),
			Vector2(size.x - inset_x - corner, top_y),
			Vector2(size.x - inset_x, top_y + corner),
			Vector2(size.x - inset_x, bottom_y - corner),
			Vector2(size.x - inset_x - corner, bottom_y),
			Vector2(inset_x + corner, bottom_y),
			Vector2(inset_x, bottom_y - corner),
			Vector2(inset_x, top_y + corner),
			Vector2(inset_x + corner, top_y)
		])
		var alpha := 0.045 + float(depth) * 0.012
		draw_polyline(points, Color(0.12, 0.88, 0.77, alpha), 1.4, true)
	# The orbit is intentionally low-contrast; the actual logo remains the focal point.
	for orbit in range(3):
		var radius := dimension * (0.17 + float(orbit) * 0.055)
		draw_arc(center + Vector2(0, 5), radius, -0.4, PI * 1.48, 72, Color(0.10, 0.84, 0.77, 0.07 + float(orbit) * 0.018), 2.0, true)
	var path_points := PackedVector2Array([
		center + Vector2(-dimension * 0.37, dimension * 0.16),
		center + Vector2(-dimension * 0.22, dimension * 0.04),
		center + Vector2(-dimension * 0.01, -dimension * 0.04),
		center + Vector2(dimension * 0.18, -dimension * 0.13),
		center + Vector2(dimension * 0.27, -dimension * 0.25)
	])
	draw_polyline(path_points, Color(0.10, 0.89, 0.80, 0.10), 5.0, true)
	draw_circle(center, dimension * 0.085, Color(0.02, 0.60, 0.55, 0.06))
	draw_arc(center, dimension * 0.085, 0.0, TAU, 64, Color(0.18, 0.96, 0.86, 0.12), 2.0, true)


func _get_gate_timer_ratio() -> float:
	var gate_duration := float(level_data.get("gate_open_seconds", 0.0))
	if gate_duration <= 0.0:
		return 0.0
	return clampf(gate_open_timer / gate_duration, 0.0, 1.0)


func _draw_room() -> void:
	var room_rect := Rect2(ROOM_LEFT, ROOM_TOP, ROOM_RIGHT - ROOM_LEFT, ROOM_BOTTOM - ROOM_TOP)
	draw_rect(room_rect, Color(0.006, 0.025, 0.036), true)
	var accent: Color = level_data.get("accent", Color(0.15, 0.34, 0.45))
	draw_rect(room_rect, Color(0.10, 0.90, 0.80, 0.70), false, 2.0)
	draw_rect(room_rect.grow(-5.0), Color(accent.r, accent.g, accent.b, 0.16), false, 1.0)
	for x in range(int(ROOM_LEFT + 20), int(ROOM_RIGHT), 40):
		draw_line(Vector2(x, ROOM_TOP + 4), Vector2(x, ROOM_BOTTOM - 4), Color(0.06, 0.33, 0.32, 0.30), 1.0)
	for y in range(int(ROOM_TOP + 20), int(ROOM_BOTTOM), 40):
		draw_line(Vector2(ROOM_LEFT + 4, y), Vector2(ROOM_RIGHT - 4, y), Color(0.06, 0.33, 0.32, 0.30), 1.0)

	# Circuit-tunnel corner rails echo the logo without filling the playable space.
	var rail_pulse := 0.18 + (sin(hazard_time * 0.9) + 1.0) * 0.035
	var rail_color := Color(0.12, 0.84, 0.78, rail_pulse)
	var rail_dim := Color(0.07, 0.47, 0.49, rail_pulse * 0.62)
	var rail_segments: Array[PackedVector2Array] = [
		PackedVector2Array([Vector2(ROOM_LEFT + 14, ROOM_TOP + 62), Vector2(ROOM_LEFT + 14, ROOM_TOP + 23), Vector2(ROOM_LEFT + 66, ROOM_TOP + 23), Vector2(ROOM_LEFT + 80, ROOM_TOP + 35)]),
		PackedVector2Array([Vector2(ROOM_RIGHT - 14, ROOM_TOP + 62), Vector2(ROOM_RIGHT - 14, ROOM_TOP + 23), Vector2(ROOM_RIGHT - 66, ROOM_TOP + 23), Vector2(ROOM_RIGHT - 80, ROOM_TOP + 35)]),
		PackedVector2Array([Vector2(ROOM_LEFT + 14, ROOM_BOTTOM - 62), Vector2(ROOM_LEFT + 14, ROOM_BOTTOM - 23), Vector2(ROOM_LEFT + 66, ROOM_BOTTOM - 23), Vector2(ROOM_LEFT + 80, ROOM_BOTTOM - 35)]),
		PackedVector2Array([Vector2(ROOM_RIGHT - 14, ROOM_BOTTOM - 62), Vector2(ROOM_RIGHT - 14, ROOM_BOTTOM - 23), Vector2(ROOM_RIGHT - 66, ROOM_BOTTOM - 23), Vector2(ROOM_RIGHT - 80, ROOM_BOTTOM - 35)])
	]
	for rail_index in range(rail_segments.size()):
		draw_polyline(rail_segments[rail_index], rail_color if rail_index % 2 == 0 else rail_dim, 1.6, true)
		var rail_point: Vector2 = rail_segments[rail_index][1]
		draw_circle(rail_point, 3.0, Color(0.26, 1.0, 0.92, rail_pulse + 0.10))
	# A restrained cyan sweep gives the playfield a live-signal feel; low opacity
	# keeps the switches, route and hazards more legible than the decoration.
	var scan_y := ROOM_TOP + fposmod(hazard_time * 30.0, ROOM_BOTTOM - ROOM_TOP)
	draw_line(Vector2(ROOM_LEFT + 8, scan_y), Vector2(ROOM_RIGHT - 8, scan_y), Color(0.16, 0.89, 0.82, 0.035), 1.0, true)

	if level_data.has("echo_jammer"):
		var jammer_position: Vector2 = level_data["echo_jammer"]
		var jammer_radius := float(level_data.get("echo_jammer_radius", 100.0))
		draw_circle(jammer_position, jammer_radius, Color(0.035, 0.035, 0.13, 0.88))
		draw_arc(jammer_position, jammer_radius, 0.0, TAU, 72, Color(0.76, 0.36, 1.0, 0.96), 4.0, true)
		draw_arc(jammer_position, jammer_radius * 0.72, 0.0, TAU, 64, Color(0.39, 0.22, 0.72, 0.78), 2.0, true)
		draw_circle(jammer_position, 18.0, Color(0.68, 0.28, 0.96, 0.95))
		draw_line(jammer_position + Vector2(-12.0, 0.0), jammer_position + Vector2(12.0, 0.0), Color(0.95, 0.85, 1.0, 0.95), 3.0)
		draw_line(jammer_position + Vector2(0.0, -12.0), jammer_position + Vector2(0.0, 12.0), Color(0.95, 0.85, 1.0, 0.95), 3.0)
		draw_string(ThemeDB.fallback_font, Vector2(jammer_position.x - jammer_radius - 10.0, jammer_position.y - jammer_radius - 9.0), "ECHO DEAD ZONE", HORIZONTAL_ALIGNMENT_CENTER, jammer_radius * 2.0 + 20.0, 13, Color(0.86, 0.67, 1.0, 0.95))

	_draw_switch(level_data["plate_a"], "A", Color(0.23, 0.83, 1.0), echo_visible and echo_position.distance_to(level_data["plate_a"]) < 43.0)
	var switch_b_active := player_position.distance_to(level_data["plate_b"]) < 43.0
	if str(level_data.get("plate_b_mode", "hold")) == "toggle":
		switch_b_active = switch_b_latched
	_draw_switch(level_data["plate_b"], "B", Color(1.0, 0.70, 0.34), switch_b_active)
	_draw_gate()
	_draw_portal(Vector2(1170, 365), door_open)
	if level_data.has("echo_waypoint"):
		_draw_echo_waypoint(
			level_data["echo_waypoint"],
			"RELAY",
			_is_relay_waypoint_linked(0)
		)
	if level_data.has("echo_waypoints"):
		var relay_waypoints: Array = level_data["echo_waypoints"]
		for relay_index in range(relay_waypoints.size()):
			_draw_echo_waypoint(
				relay_waypoints[relay_index],
				"RELAY %d" % (relay_index + 1),
				_is_relay_waypoint_linked(relay_index)
			)
	if level_data.has("memory_shard") and not collected_shards.has(current_level_index):
		_draw_memory_shard(level_data["memory_shard"])

	if bool(level_data.get("hazard", false)):
		var hazard_x := 640.0 + sin(hazard_time * float(level_data["hazard_speed"])) * float(level_data["hazard_amplitude"])
		var sentinel_pos := Vector2(hazard_x, float(level_data["hazard_y"]))
		draw_line(Vector2(hazard_x - 95, sentinel_pos.y), Vector2(hazard_x + 95, sentinel_pos.y), Color(1.0, 0.30, 0.34, 0.16), 3.0)
		draw_circle(sentinel_pos, 24, Color(1.0, 0.24, 0.34, 0.17))
		draw_circle(sentinel_pos, 15, Color(1.0, 0.32, 0.39))
		draw_circle(sentinel_pos + Vector2(-5, -3), 4, Color(1.0, 0.85, 0.87))
		draw_circle(sentinel_pos + Vector2(5, -3), 4, Color(1.0, 0.85, 0.87))

	# Show the player's route as it is being recorded, so the ghost mechanic feels tangible.
	if is_recording and not recording_track.samples.is_empty():
		var live_route_tint := Color(0.18, 0.98, 0.83, 0.84)
		if level_data.has("echo_jammer") and _track_passes_waypoint(
			recording_track,
			level_data["echo_jammer"],
			float(level_data.get("echo_jammer_radius", 100.0))
		):
			live_route_tint = Color(1.0, 0.28, 0.43, 0.88)
		_draw_track_path(recording_track, live_route_tint, 3.5)
		var route_start: Vector2 = recording_track.samples.front()["p"]
		draw_circle(route_start, 12.0, Color(0.18, 0.98, 0.83, 0.14))
		draw_arc(route_start, 12.0, 0.0, TAU, 32, Color(0.50, 1.0, 0.91, 0.96), 2.0, true)
		draw_string(ThemeDB.fallback_font, route_start + Vector2(17, -10), "START", HORIZONTAL_ALIGNMENT_LEFT, 55, 10, Color(0.48, 1.0, 0.91))

	if echo_track.samples.size() > 1 and (echo_playing or echo_visible):
		_draw_track_path(echo_track, Color(0.12, 0.98, 0.82, 0.20), 3.0)
	if echo_visible:
		var echo_alpha := 0.48 if echo_playing else 0.68
		_draw_robot(echo_position, Color(0.24, 1.0, 0.88, echo_alpha), 0.78)
	_draw_robot(player_position, Color(0.83, 0.95, 1.0), 1.0)

	if joystick_touch_index != -1 or joystick_mouse_active or joystick_direction.length() > 0.05:
		_draw_joystick()
	else:
		var joystick_hint := Vector2(size.x - 136.0 if left_handed_controls else 136.0, size.y * 0.77)
		draw_circle(joystick_hint, 44.0, Color(0.12, 0.24, 0.34, 0.16))
		draw_arc(joystick_hint, 44.0, 0, TAU, 40, Color(0.17, 0.73, 0.67, 0.24), 2.0, true)
		draw_circle(joystick_hint, 17.0, Color(0.18, 0.91, 0.82, 0.12))

	if door_open and gate_open_timer > 0.0:
		draw_string(ThemeDB.fallback_font, Vector2(900, 145), "PULSE WINDOW  %.1fs" % gate_open_timer, HORIZONTAL_ALIGNMENT_CENTER, 190, 13, Color(0.47, 1.0, 0.88))
		# The bar gives a second, glanceable cue for the remaining crossing time.
		var timer_bar := Rect2(900, 154, 160, 6)
		draw_rect(timer_bar, Color(0.12, 0.17, 0.22, 0.96), true)
		draw_rect(Rect2(timer_bar.position, Vector2(timer_bar.size.x * _get_gate_timer_ratio(), timer_bar.size.y)), Color(0.18, 0.96, 0.80, 0.98), true)
		draw_rect(timer_bar, Color(0.60, 1.0, 0.93, 0.75), false, 1.0)
	elif door_open:
		draw_string(ThemeDB.fallback_font, Vector2(915, 145), "GATE POWERED", HORIZONTAL_ALIGNMENT_CENTER, 160, 13, Color(0.35, 1.0, 0.77))
	else:
		draw_string(ThemeDB.fallback_font, Vector2(1035, 145), "SEALED", HORIZONTAL_ALIGNMENT_CENTER, 90, 13, Color(0.47, 0.61, 0.72))



func _draw_echo_waypoint(position: Vector2, label: String = "RELAY", linked: bool = false) -> void:
	# Amber means not reached; green means the current route has linked this checkpoint in order.
	var glow := Color(0.24, 1.0, 0.72) if linked else Color(1.0, 0.66, 0.25)
	draw_circle(position, 34.0, Color(glow.r, glow.g, glow.b, 0.10 if linked else 0.08))
	draw_arc(position, 25.0, 0.0, TAU, 48, Color(glow.r, glow.g, glow.b, 0.92 if linked else 0.84), 2.5, true)
	draw_arc(position, 15.0, 0.0, TAU, 48, Color(glow.r, glow.g, glow.b, 0.70 if linked else 0.65), 1.5, true)
	var diamond := PackedVector2Array([
		position + Vector2(0, -13),
		position + Vector2(11, 0),
		position + Vector2(0, 13),
		position + Vector2(-11, 0),
	])
	draw_colored_polygon(diamond, Color(0.64, 1.0, 0.84, 0.97) if linked else Color(1.0, 0.66, 0.27, 0.94))
	var outline := Color(0.91, 1.0, 0.96, 0.99) if linked else Color(1.0, 0.88, 0.62, 0.98)
	draw_polyline(PackedVector2Array([diamond[0], diamond[1], diamond[2], diamond[3], diamond[0]]), outline, 1.5, true)
	var beacon_label := label + " LINKED" if linked else label
	var label_color := Color(0.42, 1.0, 0.77) if linked else Color(1.0, 0.80, 0.47)
	draw_string(ThemeDB.fallback_font, position + Vector2(20, 4), beacon_label, HORIZONTAL_ALIGNMENT_LEFT, 130, 11, label_color)


func _draw_memory_shard(position: Vector2) -> void:
	# Optional collectible: a luminous violet crystal, distinct from both switches.
	draw_circle(position, 30.0, Color(0.72, 0.44, 1.0, 0.08))
	draw_arc(position, 20.0, 0.0, TAU, 48, Color(0.76, 0.50, 1.0, 0.72), 2.0, true)
	var diamond := PackedVector2Array([
		position + Vector2(0, -15),
		position + Vector2(12, 0),
		position + Vector2(0, 15),
		position + Vector2(-12, 0),
		position,
	])
	draw_colored_polygon(PackedVector2Array([diamond[0], diamond[1], diamond[4]]), Color(0.91, 0.76, 1.0, 0.96))
	draw_colored_polygon(PackedVector2Array([diamond[0], diamond[4], diamond[3]]), Color(0.64, 0.35, 0.92, 0.96))
	draw_colored_polygon(PackedVector2Array([diamond[3], diamond[4], diamond[2]]), Color(0.46, 0.23, 0.73, 0.96))
	draw_colored_polygon(PackedVector2Array([diamond[4], diamond[1], diamond[2]]), Color(0.78, 0.55, 1.0, 0.96))
	draw_polyline(PackedVector2Array([diamond[0], diamond[1], diamond[2], diamond[3], diamond[0]]), Color(0.94, 0.82, 1.0, 0.98), 1.5, true)
	draw_string(ThemeDB.fallback_font, position + Vector2(20, 4), "MEMORY", HORIZONTAL_ALIGNMENT_LEFT, 70, 10, Color(0.86, 0.72, 1.0))


func _draw_switch(position: Vector2, letter: String, tint: Color, active: bool) -> void:
	var color := tint if active else tint.darkened(0.45)
	draw_circle(position, 35, Color(tint.r, tint.g, tint.b, 0.09))
	draw_circle(position, 26, Color(tint.r, tint.g, tint.b, 0.12 if active else 0.05))
	draw_arc(position, 25, 0, TAU, 48, color, 3.0, true)
	draw_circle(position, 13, color if active else Color(0.12, 0.18, 0.24))
	draw_circle(position, 5, Color(0.92, 0.98, 1.0) if active else color)
	draw_string(ThemeDB.fallback_font, position + Vector2(-5, 5), letter, HORIZONTAL_ALIGNMENT_CENTER, 12, 13, Color(0.02, 0.08, 0.13) if active else Color(0.82, 0.91, 0.98))
	draw_string(ThemeDB.fallback_font, position + Vector2(-38, 48), "SWITCH " + letter, HORIZONTAL_ALIGNMENT_CENTER, 76, 12, color)


func _draw_gate() -> void:
	if door_open:
		var gate_tint := Color(1.0, 0.75, 0.34) if gate_open_timer > 0.0 else Color(0.25, 1.0, 0.75)
		draw_line(Vector2(GATE_X, ROOM_TOP + 18), Vector2(GATE_X, ROOM_BOTTOM - 18), Color(gate_tint.r, gate_tint.g, gate_tint.b, 0.30), 4.0, true)
		draw_arc(Vector2(GATE_X, 365), 49, -PI / 2, PI / 2, 48, Color(gate_tint.r, gate_tint.g, gate_tint.b, 0.85), 3.0, true)
	else:
		draw_line(Vector2(GATE_X, ROOM_TOP + 18), Vector2(GATE_X, ROOM_BOTTOM - 18), Color(0.36, 0.52, 0.64, 0.75), 5.0, true)
		for y in range(170, 590, 28):
			draw_line(Vector2(GATE_X - 10, y), Vector2(GATE_X + 10, y + 15), Color(0.18, 0.29, 0.38, 0.9), 3.0, true)
		draw_rect(Rect2(GATE_X - 17, 312, 34, 105), Color(0.08, 0.15, 0.22), true)
		draw_rect(Rect2(GATE_X - 17, 312, 34, 105), Color(0.22, 0.64, 0.79), false, 2.0)
		draw_line(Vector2(GATE_X - 8, 325), Vector2(GATE_X + 8, 403), Color(0.27, 0.64, 0.78, 0.60), 2.0, true)


func _draw_portal(position: Vector2, powered: bool) -> void:
	var tint := Color(0.28, 1.0, 0.76) if powered else Color(0.21, 0.45, 0.55)
	draw_circle(position, 37, Color(tint.r, tint.g, tint.b, 0.08))
	draw_arc(position, 29, 0, TAU, 64, tint, 4.0, true)
	draw_arc(position, 19, 0, TAU, 64, Color(tint.r, tint.g, tint.b, 0.50), 2.0, true)
	draw_line(position + Vector2(-8, -14), position + Vector2(9, 14), tint, 3.0, true)
	draw_line(position + Vector2(9, -14), position + Vector2(-8, 14), tint, 3.0, true)


func _draw_robot(position: Vector2, tint: Color, scale_factor: float) -> void:
	# Match the app mark: a luminous signal-orb wrapped in an orbital route.
	# Draw the orbit first so the core appears to sit above the ring.
	var alpha := tint.a
	var orbit_points := PackedVector2Array()
	for i in range(49):
		var angle := TAU * float(i) / 48.0
		var local_point := Vector2(cos(angle) * 23.0, sin(angle) * 9.0).rotated(-0.38) * scale_factor
		orbit_points.append(position + local_point)
	draw_polyline(orbit_points, Color(0.10, 0.91, 0.83, 0.12 * alpha), 7.0 * scale_factor, true)
	draw_polyline(orbit_points, Color(tint.r, tint.g, tint.b, 0.78 * alpha), 1.8 * scale_factor, true)
	# Layered circles create a lightweight faux-glass sphere without textures.
	draw_circle(position, 25.0 * scale_factor, Color(0.05, 0.95, 0.86, 0.075 * alpha))
	draw_circle(position, 18.0 * scale_factor, Color(0.01, 0.08, 0.12, 0.96 * alpha))
	draw_circle(position, 14.5 * scale_factor, Color(tint.r * 0.28, tint.g * 0.72, tint.b * 0.78, 0.96 * alpha))
	draw_arc(position, 18.0 * scale_factor, 0.0, TAU, 48, Color(tint.r, tint.g, tint.b, 0.92 * alpha), 1.7 * scale_factor, true)
	var highlight_points := PackedVector2Array()
	for highlight_index in range(25):
		var highlight_angle := TAU * float(highlight_index) / 24.0
		var highlight_point := Vector2(cos(highlight_angle) * 6.0, sin(highlight_angle) * 2.8).rotated(-0.25)
		highlight_points.append(position + (highlight_point + Vector2(-4.5, -6.0)) * scale_factor)
	draw_colored_polygon(highlight_points, Color(0.90, 1.0, 0.99, 0.62 * alpha))
	draw_circle(position + Vector2(5.0, -2.5) * scale_factor, 2.3 * scale_factor, Color(0.76, 1.0, 0.97, 0.32 * alpha))


func _draw_joystick() -> void:
	var center := joystick_origin
	var offset := joystick_direction * 54.0
	draw_circle(center, 54.0, Color(0.12, 0.24, 0.34, 0.42))
	draw_arc(center, 54.0, 0, TAU, 48, Color(0.40, 0.72, 0.86, 0.48), 2.0, true)
	draw_circle(center + offset, 23.0, Color(0.30, 0.78, 0.94, 0.70))
	draw_arc(center + offset, 23.0, 0, TAU, 32, Color(0.79, 0.94, 1.0, 0.95), 2.0, true)


func _draw_track_path(track: Variant, tint: Color, line_width: float) -> void:
	if track.samples.size() < 2:
		return
	# Three restrained passes make the path feel like the glowing orbit in the logo:
	# a broad aura, a saturated halo, then a crisp core line.
	var aura := Color(tint.r, tint.g, tint.b, tint.a * 0.09)
	var halo := Color(tint.r, tint.g, tint.b, tint.a * 0.28)
	for i in range(1, track.samples.size()):
		var from_point: Vector2 = track.samples[i - 1]["p"]
		var to_point: Vector2 = track.samples[i]["p"]
		draw_line(from_point, to_point, aura, line_width * 4.0, true)
		draw_line(from_point, to_point, halo, line_width * 2.0, true)
		draw_line(from_point, to_point, tint, line_width, true)

