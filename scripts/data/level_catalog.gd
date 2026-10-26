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
		for point_key in ["spawn", "plate_a", "plate_b", "memory_shard", "echo_waypoint"]:
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
