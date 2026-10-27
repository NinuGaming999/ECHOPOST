extends RefCounted

## Single source of truth for campaign room layouts and tuning.
const LEVELS: Array[Dictionary] = [
	{
		"name": "The First Echo",
		"subtitle": "LEARN TO LEAVE SOMETHING BEHIND",
		"hint": "Record a route that ENDS on SWITCH A. Your echo repeats it. Reach SWITCH B while it holds A.",
		"spawn": Vector2(160, 365),
		"plate_a": Vector2(430, 365),
		"plate_b": Vector2(845, 365),
		"memory_shard": Vector2(700, 185),
		"shard_lore": "A courier logged this station as waiting for a reply. No reply ever arrived.",
		"linger": 9.5,
		"hazard": false,
		"hazard_y": 365.0,
		"hazard_amplitude": 0.0,
		"hazard_speed": 0.0,
		"accent": Color(0.24, 0.88, 1.0)
	},
	{
		"name": "Long Memory",
		"subtitle": "THE ROOM DOES NOT WAIT FOR YOU",
		"hint": "End your recording on SWITCH A. Watch the roaming sentinel, then reach the distant SWITCH B.",
		"spawn": Vector2(155, 505),
		"plate_a": Vector2(355, 505),
		"plate_b": Vector2(910, 250),
		"memory_shard": Vector2(700, 530),
		"shard_lore": "This patrol was built to escort couriers. Its last route loops forever.",
		"linger": 9.0,
		"hazard": true,
		"hazard_y": 380.0,
		"hazard_amplitude": 250.0,
		"hazard_speed": 1.05,
		"accent": Color(1.0, 0.69, 0.31)
	},
	{
		"name": "Split Signal",
		"subtitle": "TWO PLACES. ONE MEMORY.",
		"hint": "A longer route and a faster sentinel. Finish on A, then keep moving until the gate opens.",
		"spawn": Vector2(155, 220),
		"plate_a": Vector2(360, 220),
		"plate_b": Vector2(920, 510),
		"memory_shard": Vector2(700, 245),
		"shard_lore": "Three signals arrived at once. Someone answered only one, then the line went silent.",
		"linger": 8.5,
		"hazard": true,
		"hazard_y": 360.0,
		"hazard_amplitude": 315.0,
		"hazard_speed": 1.55,
		"accent": Color(0.78, 0.52, 1.0)
	},
	{
		"name": "Fractured Lane",
		"subtitle": "TAKE THE LONG TURN",
		"hint": "Switch A is across the chamber. Record the diagonal route, avoid the sweeping sentinel, and end on A.",
		"spawn": Vector2(150, 525),
		"plate_a": Vector2(510, 245),
		"plate_b": Vector2(930, 500),
		"memory_shard": Vector2(760, 270),
		"shard_lore": "This lane was once a garden corridor. The lights still wake for footsteps.",
		"linger": 9.0,
		"hazard": true,
		"hazard_y": 385.0,
		"hazard_amplitude": 280.0,
		"hazard_speed": 1.25,
		"accent": Color(0.38, 0.92, 0.72)
	},
	{
		"name": "Crosscurrent",
		"subtitle": "READ THE ROOM BEFORE YOU MOVE",
		"hint": "The switches pull you to opposite corners. Let the echo finish its crossing before you commit to B.",
		"spawn": Vector2(150, 180),
		"plate_a": Vector2(540, 500),
		"plate_b": Vector2(945, 225),
		"memory_shard": Vector2(760, 500),
		"shard_lore": "A map of the station is scratched out here. Someone wanted the route forgotten.",
		"linger": 8.75,
		"hazard": true,
		"hazard_y": 345.0,
		"hazard_amplitude": 300.0,
		"hazard_speed": 1.6,
		"accent": Color(0.55, 0.68, 1.0)
	},
	{
		"name": "Static Bloom",
		"subtitle": "THE LAST SIGNAL IS WIDE AWAKE",
		"hint": "The relay beacon must appear in your recorded route. Visit the glowing relay, then finish on A before crossing to B.",
		"spawn": Vector2(155, 500),
		"plate_a": Vector2(620, 350),
		"plate_b": Vector2(960, 195),
		"echo_waypoint": Vector2(380, 260),
		"memory_shard": Vector2(780, 300),
		"shard_lore": "The last courier left a message: if the echo reaches you, the signal survived.",
		"linger": 9.5,
		"hazard": true,
		"hazard_y": 410.0,
		"hazard_amplitude": 330.0,
		"hazard_speed": 1.45,
		"accent": Color(0.96, 0.56, 0.84)
	},
	{
		"name": "Chorus Route",
		"subtitle": "TWO RELAYS. ONE MEMORY.",
		"hint": "Your recording must cross RELAY 1, then RELAY 2, and finish on SWITCH A. The order matters.",
		"spawn": Vector2(155, 500),
		"plate_a": Vector2(710, 250),
		"plate_b": Vector2(980, 500),
		"echo_waypoints": [Vector2(310, 320), Vector2(520, 475)],
		"memory_shard": Vector2(870, 340),
		"shard_lore": "The relay crew learned to send a chorus one note at a time. The order was the message.",
		"linger": 9.5,
		"hazard": false,
		"hazard_y": 365.0,
		"hazard_amplitude": 0.0,
		"hazard_speed": 0.0,
		"accent": Color(0.98, 0.77, 0.36)
	},
	{
		"name": "Pulse Lock",
		"subtitle": "THE WINDOW IS SHORT",
		"hint": "Hold both switches to open the pulse gate. Cross the gate before its 3.5-second window closes; once across, reach the portal.",
		"spawn": Vector2(155, 420),
		"plate_a": Vector2(410, 420),
		"plate_b": Vector2(860, 420),
		"memory_shard": Vector2(680, 200),
		"shard_lore": "The pulse gate held for one breath. The couriers learned to cross together, never one at a time.",
		"linger": 9.0,
		"gate_open_seconds": 3.5,
		"hazard": false,
		"hazard_y": 365.0,
		"hazard_amplitude": 0.0,
		"hazard_speed": 0.0,
		"accent": Color(0.96, 0.48, 0.32)
	},
	{
		"name": "Latch Protocol",
		"subtitle": "SET IT. LEAVE IT.",
		"hint": "Record a route that ends on SWITCH A. When your echo holds A, stand near SWITCH B and tap LATCH SWITCH B (or press E). You can leave B and cross the gate.",
		"spawn": Vector2(155, 500),
		"plate_a": Vector2(380, 500),
		"plate_b": Vector2(760, 500),
		"plate_b_mode": "toggle",
		"memory_shard": Vector2(980, 260),
		"shard_lore": "The last crew learned a switch did not need a hand, only a deliberate signal.",
		"linger": 9.0,
		"hazard": false,
		"hazard_y": 365.0,
		"hazard_amplitude": 0.0,
		"hazard_speed": 0.0,
		"accent": Color(0.34, 0.92, 0.74)
	},
	{
		"name": "Triune Relay",
		"subtitle": "THREE NOTES. ONE SIGNAL.",
		"hint": "Your echo must cross RELAY 1, RELAY 2, then RELAY 3—in that order—before ending on SWITCH A. Plan the full route before you send it.",
		"spawn": Vector2(155, 500),
		"plate_a": Vector2(870, 440),
		"plate_b": Vector2(1010, 205),
		"echo_waypoints": [Vector2(310, 280), Vector2(510, 480), Vector2(690, 250)],
		"memory_shard": Vector2(700, 570),
		"shard_lore": "Three relay keepers left their final signal in sequence. The station only understood them when nobody skipped a voice.",
		"linger": 9.0,
		"hazard": false,
		"hazard_y": 365.0,
		"hazard_amplitude": 0.0,
		"hazard_speed": 0.0,
		"accent": Color(0.42, 0.82, 1.0)
	},
	{
		"name": "Fracture Clock",
		"subtitle": "THE ROUTE AND THE WINDOW",
		"hint": "Cross RELAY 1, RELAY 2, then RELAY 3 before finishing on SWITCH A. When your echo holds A and you stand on B, the gate opens for 4.5 seconds—cross the barrier before it closes.",
		"spawn": Vector2(150, 220),
		"plate_a": Vector2(820, 500),
		"plate_b": Vector2(1000, 220),
		"echo_waypoints": [Vector2(300, 470), Vector2(470, 230), Vector2(650, 470)],
		"memory_shard": Vector2(900, 310),
		"shard_lore": "The clock and relay were built by different crews. Their final message survived only when every signal arrived before the gate fell silent.",
		"linger": 9.0,
		"gate_open_seconds": 4.5,
		"hazard": false,
		"hazard_y": 365.0,
		"hazard_amplitude": 0.0,
		"hazard_speed": 0.0,
		"accent": Color(1.0, 0.55, 0.35)
	},
	{
		"name": "Dead Air Protocol",
		"subtitle": "FOUR RELAYS. ONE HUNT. NO TIME TO WASTE.",
		"hint": "Record RELAY 1 → RELAY 2 → RELAY 3 → RELAY 4 → SWITCH A in order. The sentinel patrols while you record and contact erases your take. Once the echo settles on A and you reach B, cross the gate within 1.8 seconds.",
		"spawn": Vector2(150, 525),
		"plate_a": Vector2(820, 205),
		"plate_b": Vector2(850, 500),
		"echo_waypoints": [Vector2(270, 290), Vector2(430, 500), Vector2(580, 250), Vector2(690, 470)],
		"memory_shard": Vector2(750, 560),
		"shard_lore": "The final courier sent four relays while a sentinel hunted the signal. The station kept the route, but lost the name of the one who ran it.",
		"linger": 6.5,
		"gate_open_seconds": 1.8,
		"hazard": true,
		"hazard_y": 365.0,
		"hazard_amplitude": 350.0,
		"hazard_speed": 2.05,
		"accent": Color(1.0, 0.32, 0.42)
	},
	{
		"name": "Null Corridor",
		"subtitle": "THE ECHO CANNOT CROSS THE BLACKOUT",
		"hint": "Record a curved route around the glowing ECHO DEAD ZONE, then finish on SWITCH A. The real robot can cross the blackout safely; only your recorded echo is disrupted.",
		"spawn": Vector2(150, 500),
		"plate_a": Vector2(920, 500),
		"plate_b": Vector2(1060, 220),
		"echo_jammer": Vector2(520, 470),
		"echo_jammer_radius": 105.0,
		"memory_shard": Vector2(730, 220),
		"shard_lore": "The blackout was installed to stop copied routes. The original couriers learned to bend their paths around silence.",
		"linger": 9.5,
		"hazard": false,
		"hazard_y": 365.0,
		"hazard_amplitude": 0.0,
		"hazard_speed": 0.0,
		"accent": Color(0.72, 0.43, 1.0)
	}
]

static func get_level(index: int) -> Dictionary:
	return LEVELS[clampi(index, 0, LEVELS.size() - 1)].duplicate(true)

static func level_count() -> int:
	return LEVELS.size()


## Validate data before a campaign build; authoring tools and smoke tests use this too.
static func validate_levels() -> PackedStringArray:
	return validate_level_list(LEVELS)


## Validate arbitrary room data too, so editor tooling and tests can check invalid drafts before adding them.
static func validate_level_list(levels: Array[Dictionary]) -> PackedStringArray:
	var errors := PackedStringArray()
	if levels.is_empty():
		errors.append("Campaign must contain at least one level.")
		return errors

	var seen_names: Dictionary = {}
	for index in range(levels.size()):
		var level: Dictionary = levels[index]
		var prefix := "Level %d" % (index + 1)
		var level_name := str(level.get("name", "")).strip_edges()
		if level_name.is_empty():
			errors.append("%s must have a non-empty name." % prefix)
		elif seen_names.has(level_name):
			errors.append("%s uses duplicate chamber name '%s'." % [prefix, level_name])
		else:
			seen_names[level_name] = true
		for required_key in ["name", "subtitle", "hint", "spawn", "plate_a", "plate_b", "memory_shard", "shard_lore", "linger", "hazard", "accent"]:
			if not level.has(required_key):
				errors.append("%s is missing '%s'." % [prefix, required_key])
		if not level.has("spawn") or not (level["spawn"] is Vector2):
			errors.append("%s spawn must be a Vector2." % prefix)
		if not level.has("plate_a") or not (level["plate_a"] is Vector2):
			errors.append("%s plate_a must be a Vector2." % prefix)
		if not level.has("plate_b") or not (level["plate_b"] is Vector2):
			errors.append("%s plate_b must be a Vector2." % prefix)
		if not level.has("memory_shard") or not (level["memory_shard"] is Vector2):
			errors.append("%s memory_shard must be a Vector2." % prefix)
		if str(level.get("shard_lore", "")).strip_edges().is_empty():
			errors.append("%s shard_lore must not be empty." % prefix)
		if not level.has("linger") or float(level.get("linger", 0.0)) <= 0.0:
			errors.append("%s must use a positive echo linger duration." % prefix)
		if level.has("echo_waypoint") and not (level["echo_waypoint"] is Vector2):
			errors.append("%s echo_waypoint must be a Vector2." % prefix)
		if level.has("plate_b_mode"):
			var raw_plate_b_mode: Variant = level["plate_b_mode"]
			if not (raw_plate_b_mode is String):
				errors.append("%s plate_b_mode must be a string." % prefix)
			elif str(raw_plate_b_mode) not in ["hold", "toggle"]:
				errors.append("%s plate_b_mode must be 'hold' or 'toggle'." % prefix)
		if level.has("gate_open_seconds"):
			var raw_gate_duration: Variant = level["gate_open_seconds"]
			if not (raw_gate_duration is int or raw_gate_duration is float):
				errors.append("%s gate_open_seconds must be numeric." % prefix)
			else:
				var gate_duration := float(raw_gate_duration)
				if gate_duration < 1.0 or gate_duration > 15.0:
					errors.append("%s gate_open_seconds must be between 1 and 15 seconds." % prefix)
		if level.has("echo_waypoints") and not (level["echo_waypoints"] is Array):
			errors.append("%s echo_waypoints must be an Array of Vector2 positions." % prefix)
		if level.has("echo_jammer") and not (level["echo_jammer"] is Vector2):
			errors.append("%s echo_jammer must be a Vector2." % prefix)
		if level.has("echo_jammer_radius") and not level.has("echo_jammer"):
			errors.append("%s echo_jammer_radius requires an echo_jammer position." % prefix)
		if level.has("echo_jammer"):
			if not level.has("echo_jammer_radius"):
				errors.append("%s echo_jammer requires echo_jammer_radius." % prefix)
			else:
				var raw_jammer_radius: Variant = level["echo_jammer_radius"]
				if not (raw_jammer_radius is int or raw_jammer_radius is float):
					errors.append("%s echo_jammer_radius must be numeric." % prefix)
				else:
					var jammer_radius := float(raw_jammer_radius)
					if jammer_radius < 40.0 or jammer_radius > 180.0:
						errors.append("%s echo_jammer_radius must be between 40 and 180 units." % prefix)
					if level["echo_jammer"] is Vector2:
						var jammer_position: Vector2 = level["echo_jammer"]
						for anchor_key in ["spawn", "plate_a", "plate_b", "memory_shard"]:
							if level.has(anchor_key) and level[anchor_key] is Vector2:
								var anchor_position: Vector2 = level[anchor_key]
								if jammer_position.distance_to(anchor_position) < jammer_radius + 40.0:
									errors.append("%s echo jammer must be separated from %s." % [prefix, anchor_key])
		for point_key in ["spawn", "plate_a", "plate_b", "memory_shard", "echo_waypoint", "echo_jammer"]:
			if level.has(point_key) and level[point_key] is Vector2:
				var point: Vector2 = level[point_key]
				if point.x < 63.0 or point.x > 1217.0 or point.y < 140.0 or point.y > 597.0:
					errors.append("%s %s is outside the playable room." % [prefix, point_key])

		if level.has("spawn") and level["spawn"] is Vector2 and level.has("plate_a") and level["plate_a"] is Vector2:
			var spawn: Vector2 = level["spawn"]
			var plate_a: Vector2 = level["plate_a"]
			if spawn.distance_to(plate_a) < 180.0:
				errors.append("%s spawn and Switch A are too close for a meaningful minimum-length recording." % prefix)

		if level.has("plate_a") and level["plate_a"] is Vector2 and level.has("plate_b") and level["plate_b"] is Vector2:
			var plate_a_position: Vector2 = level["plate_a"]
			var plate_b_position: Vector2 = level["plate_b"]
			if plate_a_position.distance_to(plate_b_position) < 86.0:
				errors.append("%s Switch A and Switch B must be separated by at least 86 units." % prefix)

		if level.has("memory_shard") and level["memory_shard"] is Vector2:
			var shard_position: Vector2 = level["memory_shard"]
			for anchor_key in ["spawn", "plate_a", "plate_b"]:
				if level.has(anchor_key) and level[anchor_key] is Vector2:
					var anchor_position: Vector2 = level[anchor_key]
					if shard_position.distance_to(anchor_position) < 60.0:
						errors.append("%s memory shard must be separated from %s." % [prefix, anchor_key])

		if level.has("echo_waypoint") and level["echo_waypoint"] is Vector2:
			var waypoint_position: Vector2 = level["echo_waypoint"]
			for anchor_key in ["spawn", "plate_a", "plate_b", "memory_shard"]:
				if level.has(anchor_key) and level[anchor_key] is Vector2:
					var anchor_position: Vector2 = level[anchor_key]
					if waypoint_position.distance_to(anchor_position) < 70.0:
						errors.append("%s echo waypoint must be separated from %s." % [prefix, anchor_key])

		if level.has("echo_waypoints") and level["echo_waypoints"] is Array:
			var raw_waypoints: Array = level["echo_waypoints"]
			if raw_waypoints.is_empty():
				errors.append("%s must have at least one echo waypoint when echo_waypoints is authored." % prefix)
			var validated_waypoints: Array[Vector2] = []
			for waypoint_index in range(raw_waypoints.size()):
				var raw_waypoint: Variant = raw_waypoints[waypoint_index]
				if not (raw_waypoint is Vector2):
					errors.append("%s echo_waypoints[%d] must be a Vector2." % [prefix, waypoint_index])
					continue
				var sequence_waypoint: Vector2 = raw_waypoint
				if sequence_waypoint.x < 63.0 or sequence_waypoint.x > 1217.0 or sequence_waypoint.y < 140.0 or sequence_waypoint.y > 597.0:
					errors.append("%s echo_waypoints[%d] is outside the playable room." % [prefix, waypoint_index])
				for anchor_key in ["spawn", "plate_a", "plate_b", "memory_shard"]:
					if level.has(anchor_key) and level[anchor_key] is Vector2:
						var anchor_position: Vector2 = level[anchor_key]
						if sequence_waypoint.distance_to(anchor_position) < 70.0:
							errors.append("%s echo waypoint %d must be separated from %s." % [prefix, waypoint_index + 1, anchor_key])
				for previous_waypoint in validated_waypoints:
					if sequence_waypoint.distance_to(previous_waypoint) < 70.0:
						errors.append("%s ordered echo waypoints must be separated by at least 70 units." % prefix)
				validated_waypoints.append(sequence_waypoint)

		if bool(level.get("hazard", false)):
			for hazard_key in ["hazard_y", "hazard_amplitude", "hazard_speed"]:
				if not level.has(hazard_key):
					errors.append("%s hazard is missing '%s'." % [prefix, hazard_key])
			var hazard_y := float(level.get("hazard_y", 0.0))
			var hazard_amplitude := float(level.get("hazard_amplitude", -1.0))
			var hazard_speed := float(level.get("hazard_speed", 0.0))
			if hazard_y < 140.0 or hazard_y > 597.0:
				errors.append("%s sentinel patrol height is outside the room." % prefix)
			if hazard_amplitude < 0.0 or hazard_amplitude > 500.0:
				errors.append("%s sentinel patrol width must be between 0 and 500." % prefix)
			if hazard_speed <= 0.0 or hazard_speed > 4.0:
				errors.append("%s sentinel speed must be greater than 0 and no more than 4." % prefix)
	return errors
