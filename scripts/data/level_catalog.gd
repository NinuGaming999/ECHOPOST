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
		"linger": 8.5,
		"hazard": true,
		"hazard_y": 360.0,
		"hazard_amplitude": 315.0,
		"hazard_speed": 1.55,
		"accent": Color(0.78, 0.52, 1.0)
	}
]

static func get_level(index: int) -> Dictionary:
	return LEVELS[clampi(index, 0, LEVELS.size() - 1)].duplicate(true)

static func level_count() -> int:
	return LEVELS.size()


## Validate data before a campaign build; authoring tools and smoke tests use this too.
static func validate_levels() -> PackedStringArray:
	var errors := PackedStringArray()
	if LEVELS.is_empty():
		errors.append("Campaign must contain at least one level.")
		return errors

	for index in range(LEVELS.size()):
		var level: Dictionary = LEVELS[index]
		var prefix := "Level %d" % (index + 1)
		for required_key in ["name", "subtitle", "hint", "spawn", "plate_a", "plate_b", "linger", "hazard", "accent"]:
			if not level.has(required_key):
				errors.append("%s is missing '%s'." % [prefix, required_key])
		if not level.has("spawn") or not (level["spawn"] is Vector2):
			errors.append("%s spawn must be a Vector2." % prefix)
		if not level.has("plate_a") or not (level["plate_a"] is Vector2):
			errors.append("%s plate_a must be a Vector2." % prefix)
		if not level.has("plate_b") or not (level["plate_b"] is Vector2):
			errors.append("%s plate_b must be a Vector2." % prefix)
		if not level.has("linger") or float(level.get("linger", 0.0)) <= 0.0:
			errors.append("%s must use a positive echo linger duration." % prefix)
		for point_key in ["spawn", "plate_a", "plate_b"]:
			if level.has(point_key) and level[point_key] is Vector2:
				var point: Vector2 = level[point_key]
				if point.x < 63.0 or point.x > 1217.0 or point.y < 140.0 or point.y > 597.0:
					errors.append("%s %s is outside the playable room." % [prefix, point_key])
		if bool(level.get("hazard", false)):
			for hazard_key in ["hazard_y", "hazard_amplitude", "hazard_speed"]:
				if not level.has(hazard_key):
					errors.append("%s hazard is missing '%s'." % [prefix, hazard_key])
	return errors
