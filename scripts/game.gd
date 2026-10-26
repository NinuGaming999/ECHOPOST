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
var gate_open_timer: float = 0.0
var timed_gate_failed: bool = false
var hazard_time: float = 0.0
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
var pause_button: Button
var start_button: Button
var complete_title_label: Label
var complete_body_label: Label
var next_level_button: Button
var chapter_buttons: Array[Button] = []


func _notification(what: int) -> void:
	# Stop gameplay time when Android/iOS suspends the app, or when the app loses focus.
	# We intentionally do not auto-resume: the player must explicitly tap RESUME.
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_pause_for_lifecycle()


func _pause_for_lifecycle() -> void:
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
	_show_menu()
	queue_redraw()


func _process(delta: float) -> void:
	if screen_state != ScreenState.PLAYING:
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
	_check_memory_shard_collection()
	_update_timed_gate(safe_delta)
	_check_puzzle_state()
	_update_hud()
	queue_redraw()


func _input(event: InputEvent) -> void:
	if screen_state != ScreenState.PLAYING:
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
	if point.y <= size.y * 0.56:
		return false
	if left_handed_controls:
		# Reserve the lower-right restart button area when the joystick is moved to the right.
		return point.x > size.x - 285.0 and not (point.y > 650.0 and point.x > size.x - 300.0)
	# Reserve the lower-left main-menu button area for the default left-side joystick.
	return point.x < 285.0 and not (point.y > 650.0 and point.x < 180.0)


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


func _build_menu() -> void:
	menu_root = Control.new()
	menu_root.name = "Menu"
	menu_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(menu_root)

	var title := _make_label(menu_root, "Title", Vector2(100, 135), Vector2(1080, 100), "ECHOPOST", 70, Color(0.86, 0.97, 1.0), HORIZONTAL_ALIGNMENT_CENTER)
	title.add_theme_color_override("font_shadow_color", Color(0.1, 0.7, 1.0, 0.55))
	title.add_theme_constant_override("shadow_offset_x", 0)
	title.add_theme_constant_override("shadow_offset_y", 4)
	_make_label(menu_root, "Tagline", Vector2(180, 235), Vector2(920, 42), "EVERY PLAYER LEAVES A GHOST", 22, Color(0.39, 0.85, 1.0), HORIZONTAL_ALIGNMENT_CENTER)
	_make_label(menu_root, "Intro", Vector2(250, 280), Vector2(780, 58), "Record your movement. Let your echo hold the past\nwhile you find a way into the future.", 18, Color(0.70, 0.78, 0.88), HORIZONTAL_ALIGNMENT_CENTER)

	start_button = _make_button(menu_root, "StartButton", Vector2(475, 348), Vector2(330, 54), "CONTINUE JOURNEY", Color(0.06, 0.45, 0.62), Color(0.08, 0.61, 0.78), 20)
	start_button.pressed.connect(_on_start_pressed)
	var chapters := _make_button(menu_root, "ChaptersButton", Vector2(475, 409), Vector2(330, 50), "CHAPTER SELECT", Color(0.12, 0.22, 0.35), Color(0.17, 0.32, 0.48), 17)
	chapters.pressed.connect(_open_level_select)
	var help := _make_button(menu_root, "HowToPlayButton", Vector2(475, 466), Vector2(330, 48), "HOW TO PLAY", Color(0.12, 0.22, 0.35), Color(0.17, 0.32, 0.48), 17)
	help.pressed.connect(_open_help)
	var archive := _make_button(menu_root, "MemoryArchiveButton", Vector2(475, 520), Vector2(330, 42), "MEMORY ARCHIVE", Color(0.20, 0.15, 0.34), Color(0.34, 0.22, 0.52), 15)
	archive.pressed.connect(_open_memory_archive)
	var options := _make_button(menu_root, "OptionsButton", Vector2(475, 567), Vector2(330, 42), "OPTIONS", Color(0.12, 0.22, 0.35), Color(0.17, 0.32, 0.48), 16)
	options.pressed.connect(_open_options)
	menu_progress_label = _make_label(menu_root, "Progress", Vector2(240, 619), Vector2(800, 28), "CHAMBERS DISCOVERED: 1 / 6   •   MEMORIES: 0 / 6", 14, Color(0.49, 0.61, 0.73), HORIZONTAL_ALIGNMENT_CENTER)
	_make_label(menu_root, "Version", Vector2(22, 688), Vector2(260, 22), "ECHOPOST  •  EARLY DEVELOPMENT BUILD", 10, Color(0.30, 0.42, 0.55), HORIZONTAL_ALIGNMENT_LEFT)


func _build_game_hud() -> void:
	game_hud = Control.new()
	game_hud.name = "GameHUD"
	game_hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(game_hud)

	level_title_label = _make_label(game_hud, "LevelTitle", Vector2(34, 15), Vector2(570, 36), "01  /  THE FIRST ECHO", 22, Color(0.88, 0.95, 1.0), HORIZONTAL_ALIGNMENT_LEFT)
	level_hint_label = _make_label(game_hud, "LevelHint", Vector2(35, 52), Vector2(900, 44), "Record a route that ends on Switch A.", 15, Color(0.55, 0.70, 0.82), HORIZONTAL_ALIGNMENT_LEFT)
	echo_status_label = _make_label(game_hud, "EchoStatus", Vector2(805, 17), Vector2(300, 28), "ECHO: NOT RECORDED", 14, Color(0.42, 0.83, 1.0), HORIZONTAL_ALIGNMENT_RIGHT)
	pause_button = _make_button(game_hud, "PauseButton", Vector2(1120, 17), Vector2(126, 40), "PAUSE", Color(0.12, 0.22, 0.34), Color(0.17, 0.34, 0.48), 14)
	pause_button.pressed.connect(_on_pause_pressed)

	status_label = _make_label(game_hud, "Status", Vector2(300, 626), Vector2(680, 34), "Find the switches.", 15, Color(0.74, 0.84, 0.93), HORIZONTAL_ALIGNMENT_CENTER)
	record_button = _make_button(game_hud, "RecordButton", Vector2(380, 665), Vector2(270, 44), "RECORD ECHO", Color(0.03, 0.47, 0.62), Color(0.04, 0.65, 0.80), 17)
	record_button.pressed.connect(_on_record_pressed)
	var reset_button := _make_button(game_hud, "ResetButton", Vector2(1000, 665), Vector2(145, 44), "RESTART ROOM", Color(0.22, 0.18, 0.31), Color(0.32, 0.23, 0.44), 13)
	reset_button.pressed.connect(_on_reset_pressed)
	var menu_button := _make_button(game_hud, "MenuButton", Vector2(34, 665), Vector2(145, 44), "MAIN MENU", Color(0.12, 0.22, 0.34), Color(0.17, 0.34, 0.48), 13)
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
	memory_archive_status_label = _make_label(memory_archive_panel, "ArchiveStatus", Vector2(35, 58), Vector2(610, 26), "RECOVERED: 0 / 6", 14, Color(0.76, 0.58, 1.0), HORIZONTAL_ALIGNMENT_CENTER)

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
	memory_archive_status_label.text = "MEMORIES RECOVERED: %d / %d" % [collected_shards.size(), LEVELS.size()]


func _make_panel(panel_name: String, panel_position: Vector2, panel_size: Vector2) -> Panel:
	var panel := Panel.new()
	panel.name = panel_name
	panel.position = panel_position
	panel.size = panel_size
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.045, 0.075, 0.12, 0.98)
	style.border_color = Color(0.20, 0.60, 0.76, 0.95)
	style.set_border_width_all(2)
	style.set_corner_radius_all(18)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.30)
	style.shadow_size = 12
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
	button.text = button_text
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", Color(0.92, 0.97, 1.0))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_disabled_color", Color(0.36, 0.43, 0.50))
	var normal := StyleBoxFlat.new()
	normal.bg_color = normal_color
	normal.set_corner_radius_all(11)
	var hover := StyleBoxFlat.new()
	hover.bg_color = hover_color
	hover.set_corner_radius_all(11)
	var pressed := StyleBoxFlat.new()
	pressed.bg_color = normal_color.darkened(0.25)
	pressed.set_corner_radius_all(11)
	var disabled := StyleBoxFlat.new()
	disabled.bg_color = Color(0.10, 0.13, 0.19)
	disabled.set_corner_radius_all(11)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)
	parent.add_child(button)
	return button


func _show_menu() -> void:
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
	if screen_state != ScreenState.PLAYING:
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
		_update_hud()
		queue_redraw()
		return
	if level_data.has("echo_waypoints"):
		var required_waypoints: Array = level_data["echo_waypoints"]
		if not _track_passes_waypoints_in_order(recording_track, required_waypoints, 40.0):
			echo_visible = false
			echo_playing = false
			echo_track.clear()
			status_message = "ROUTE REJECTED — pass through RELAY 1, then RELAY 2 in order before finishing on SWITCH A."
			_update_hud()
			queue_redraw()
			return
	if level_data.has("echo_waypoint"):
		var relay_position: Vector2 = level_data["echo_waypoint"]
		if not _track_passes_waypoint(recording_track, relay_position, 40.0):
			echo_visible = false
			echo_playing = false
			echo_track.clear()
			status_message = "ROUTE REJECTED — pass through the RELAY BEACON before finishing on SWITCH A."
			_update_hud()
			queue_redraw()
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

	# A beacon is only considered linked after the route reaches it in sequence.
	var minimum_route_progress := 0.0
	for i in range(waypoint_index + 1):
		var waypoint_value: Variant = waypoints[i]
		if not (waypoint_value is Vector2):
			return false
		var route_progress := _track_waypoint_progress(route, waypoint_value, 40.0, minimum_route_progress)
		if route_progress < 0.0:
			return false
		minimum_route_progress = route_progress + 0.0001
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


func _check_sentinel_collision() -> void:
	if not bool(level_data.get("hazard", false)):
		return
	var hazard_x := 640.0 + sin(hazard_time * float(level_data["hazard_speed"])) * float(level_data["hazard_amplitude"])
	var sentinel := Vector2(hazard_x, float(level_data["hazard_y"]))
	if player_position.distance_to(sentinel) < 27.0:
		player_position = level_data["spawn"]
		if is_recording:
			# A collision interrupts the current take. Keeping it would create a
			# misleading recorded "teleport" from the contact point back to spawn.
			is_recording = false
			recording_elapsed = 0.0
			record_sample_accumulator = 0.0
			recording_track.clear()
			status_message = "SENTINEL CONTACT — recording lost; returned to the chamber entrance."
		else:
			status_message = "SENTINEL CONTACT — returned to the chamber entrance."
		_update_hud()
		queue_redraw()


func _check_memory_shard_collection() -> void:
	if not level_data.has("memory_shard") or collected_shards.has(current_level_index):
		return
	var shard_position: Vector2 = level_data["memory_shard"]
	if player_position.distance_to(shard_position) > 30.0:
		return

	collected_shards.append(current_level_index)
	collected_shards.sort()
	status_message = "MEMORY: " + str(level_data.get("shard_lore", "A memory from the courier network survived."))
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
	var echo_on_a := echo_visible and echo_position.distance_to(level_data["plate_a"]) < 43.0
	var player_on_b := player_position.distance_to(level_data["plate_b"]) < 43.0

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
	_start_level(current_level_index)


func _on_pause_pressed() -> void:
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
	record_button.disabled = screen_state == ScreenState.PAUSED or screen_state == ScreenState.COMPLETE


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
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.025, 0.041, 0.073), true)
	for star in stars:
		draw_circle(Vector2(star.x, star.y), star.z, Color(0.19, 0.36, 0.49, 0.44))
	if screen_state == ScreenState.MENU:
		_draw_menu_art()
		return
	_draw_room()
	if screen_state == ScreenState.PAUSED:
		draw_rect(Rect2(0, 100, size.x, 520), Color(0.02, 0.03, 0.06, 0.34), true)


func _draw_menu_art() -> void:
	for i in range(5):
		var x := 140.0 + float(i) * 250.0
		draw_arc(Vector2(x, 358), 56.0 + float(i) * 7.0, 0, TAU, 72, Color(0.09, 0.38, 0.56, 0.18), 2.0, true)
	draw_line(Vector2(150, 360), Vector2(1120, 360), Color(0.12, 0.45, 0.64, 0.22), 2.0, true)
	_draw_robot(Vector2(310, 360), Color(0.30, 0.85, 1.0, 0.78), 1.0)
	_draw_robot(Vector2(960, 360), Color(0.70, 0.47, 1.0, 0.25), 0.75)


func _draw_room() -> void:
	var room_rect := Rect2(ROOM_LEFT, ROOM_TOP, ROOM_RIGHT - ROOM_LEFT, ROOM_BOTTOM - ROOM_TOP)
	draw_rect(room_rect, Color(0.055, 0.085, 0.13), true)
	var accent: Color = level_data.get("accent", Color(0.15, 0.34, 0.45))
	draw_rect(room_rect, Color(accent.r, accent.g, accent.b, 0.56), false, 3.0)
	for x in range(int(ROOM_LEFT + 20), int(ROOM_RIGHT), 40):
		draw_line(Vector2(x, ROOM_TOP + 4), Vector2(x, ROOM_BOTTOM - 4), Color(0.13, 0.23, 0.31, 0.35), 1.0)
	for y in range(int(ROOM_TOP + 20), int(ROOM_BOTTOM), 40):
		draw_line(Vector2(ROOM_LEFT + 4, y), Vector2(ROOM_RIGHT - 4, y), Color(0.13, 0.23, 0.31, 0.35), 1.0)

	_draw_switch(level_data["plate_a"], "A", Color(0.23, 0.83, 1.0), echo_visible and echo_position.distance_to(level_data["plate_a"]) < 43.0)
	_draw_switch(level_data["plate_b"], "B", Color(1.0, 0.70, 0.34), player_position.distance_to(level_data["plate_b"]) < 43.0)
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
		_draw_track_path(recording_track, Color(1.0, 0.69, 0.31, 0.62), 3.5)
		var route_start: Vector2 = recording_track.samples.front()["p"]
		draw_circle(route_start, 12.0, Color(1.0, 0.69, 0.31, 0.12))
		draw_arc(route_start, 12.0, 0.0, TAU, 32, Color(1.0, 0.76, 0.40, 0.92), 2.0, true)
		draw_string(ThemeDB.fallback_font, route_start + Vector2(17, -10), "START", HORIZONTAL_ALIGNMENT_LEFT, 55, 10, Color(1.0, 0.80, 0.50))

	if echo_track.samples.size() > 1 and (echo_playing or echo_visible):
		_draw_track_path(echo_track, Color(0.29, 0.82, 1.0, 0.17), 3.0)
	if echo_visible:
		var echo_alpha := 0.48 if echo_playing else 0.68
		_draw_robot(echo_position, Color(0.28, 0.84, 1.0, echo_alpha), 0.78)
	_draw_robot(player_position, Color(0.83, 0.95, 1.0), 1.0)

	if joystick_touch_index != -1 or joystick_mouse_active or joystick_direction.length() > 0.05:
		_draw_joystick()
	else:
		var joystick_hint := Vector2(size.x - 136.0 if left_handed_controls else 136.0, 555)
		draw_circle(joystick_hint, 44.0, Color(0.12, 0.24, 0.34, 0.16))
		draw_arc(joystick_hint, 44.0, 0, TAU, 40, Color(0.40, 0.72, 0.86, 0.27), 2.0, true)
		draw_circle(joystick_hint, 17.0, Color(0.30, 0.78, 0.94, 0.14))

	if door_open:
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
	var body_size := Vector2(24, 25) * scale_factor
	draw_circle(position, 22.0 * scale_factor, Color(tint.r, tint.g, tint.b, 0.10 * tint.a))
	draw_line(position + Vector2(0, -13) * scale_factor, position + Vector2(0, -20) * scale_factor, tint, 2.0 * scale_factor, true)
	draw_circle(position + Vector2(0, -21) * scale_factor, 3.0 * scale_factor, tint)
	draw_rect(Rect2(position - body_size * 0.5 + Vector2(0, 4) * scale_factor, body_size), tint, true)
	draw_rect(Rect2(position - body_size * 0.5 + Vector2(0, 4) * scale_factor, body_size), Color(0.30, 0.58, 0.73, tint.a), false, 2.0 * scale_factor)
	draw_circle(position + Vector2(-5, -2) * scale_factor, 2.5 * scale_factor, Color(0.03, 0.12, 0.18, tint.a))
	draw_circle(position + Vector2(5, -2) * scale_factor, 2.5 * scale_factor, Color(0.03, 0.12, 0.18, tint.a))
	draw_line(position + Vector2(-7, 18) * scale_factor, position + Vector2(-11, 23) * scale_factor, tint, 3.0 * scale_factor, true)
	draw_line(position + Vector2(7, 18) * scale_factor, position + Vector2(11, 23) * scale_factor, tint, 3.0 * scale_factor, true)


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
	for i in range(1, track.samples.size()):
		var from_point: Vector2 = track.samples[i - 1]["p"]
		var to_point: Vector2 = track.samples[i]["p"]
		draw_line(from_point, to_point, tint, line_width, true)

