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
	,
	{
		"name": "Glass Horizon",
		"chapter": 2,
		"subtitle": "THREE RELAYS THROUGH A LIVING PATROL",
		"hint": "Chapter II begins with a wider relay weave. Cross RELAY 1, RELAY 2, then RELAY 3 before finishing on SWITCH A. The sentinel patrols the centre lane, so watch its timing.",
		"spawn": Vector2(150, 520),
		"plate_a": Vector2(920, 500),
		"plate_b": Vector2(1050, 220),
		"echo_waypoints": [Vector2(300, 300), Vector2(500, 500), Vector2(700, 250)],
		"memory_shard": Vector2(800, 570),
		"shard_lore": "The horizon relay was built to carry messages between distant outposts. Its last operator kept sending long after the stations went dark.",
		"linger": 8.5,
		"hazard": true,
		"hazard_y": 365.0,
		"hazard_amplitude": 310.0,
		"hazard_speed": 1.55,
		"accent": Color(0.28, 0.86, 1.0)
	},
	{
		"name": "Clockbreak Crossing",
		"chapter": 2,
		"subtitle": "THE GATE OPENS ONCE",
		"hint": "Route through RELAY 1, RELAY 2, then RELAY 3 and finish on SWITCH A. Reach SWITCH B to trigger the 2.8-second pulse window, then cross the barrier immediately.",
		"spawn": Vector2(150, 190),
		"plate_a": Vector2(900, 500),
		"plate_b": Vector2(1050, 220),
		"echo_waypoints": [Vector2(300, 480), Vector2(500, 220), Vector2(700, 500)],
		"memory_shard": Vector2(1030, 540),
		"shard_lore": "The clock keeper left one instruction in the maintenance log: never mistake an open gate for a safe place to wait.",
		"linger": 8.5,
		"gate_open_seconds": 2.8,
		"hazard": false,
		"hazard_y": 365.0,
		"hazard_amplitude": 0.0,
		"hazard_speed": 0.0,
		"accent": Color(1.0, 0.61, 0.34)
	},
	{
		"name": "Switchback Protocol",
		"chapter": 2,
		"subtitle": "THE SWITCH DOES NOT NEED YOU TO STAY",
		"hint": "Guide your echo through both relays and onto SWITCH A. The blacked-out centre jams recorded echoes, not your real robot. Latch SWITCH B and leave it to reach the exit.",
		"spawn": Vector2(150, 500),
		"plate_a": Vector2(930, 500),
		"plate_b": Vector2(1080, 220),
		"plate_b_mode": "toggle",
		"echo_waypoints": [Vector2(300, 250), Vector2(700, 220)],
		"echo_jammer": Vector2(520, 390),
		"echo_jammer_radius": 95.0,
		"memory_shard": Vector2(760, 560),
		"shard_lore": "The switchback crew discovered a quiet path above the blackout. They left the switch latched so the next courier could keep moving.",
		"linger": 9.0,
		"hazard": false,
		"hazard_y": 365.0,
		"hazard_amplitude": 0.0,
		"hazard_speed": 0.0,
		"accent": Color(0.67, 0.48, 1.0)
	},
	{
		"name": "The Last Chorus",
		"chapter": 2,
		"subtitle": "FOUR RELAYS. A BLACKOUT. ONE FINAL WINDOW.",
		"hint": "The final route must cross RELAY 1 → 2 → 3 → 4, stay above the ECHO DEAD ZONE, and finish on SWITCH A. Avoid the sentinel, then reach SWITCH B and cross the 2.8-second gate.",
		"spawn": Vector2(150, 520),
		"plate_a": Vector2(980, 520),
		"plate_b": Vector2(1070, 210),
		"echo_waypoints": [Vector2(290, 300), Vector2(430, 230), Vector2(700, 230), Vector2(850, 450)],
		"echo_jammer": Vector2(520, 390),
		"echo_jammer_radius": 95.0,
		"memory_shard": Vector2(720, 570),
		"shard_lore": "Four voices survived the blackout. The final courier did not leave a name, only a route that still knows how to find its way home.",
		"linger": 7.5,
		"gate_open_seconds": 2.8,
		"hazard": true,
		"hazard_y": 365.0,
		"hazard_amplitude": 330.0,
		"hazard_speed": 1.8,
		"accent": Color(1.0, 0.38, 0.52)
	}

	,
	{
		"name": "Drift Bridge",
		"chapter": 3,
		"subtitle": "THE FLOOR ENDS. THE BRIDGE DOES NOT.",
		"hint": "The dark gap is unsafe ground. Step onto the moving bridge and let it carry you across. Your echo stays on SWITCH A while you ride to SWITCH B.",
		"spawn": Vector2(150, 500),
		"plate_a": Vector2(410, 500),
		"plate_b": Vector2(990, 365),
		"void_zones": [
			{"position": Vector2(570, 112), "size": Vector2(300, 500)}
		],
		"moving_platforms": [
			{"from": Vector2(490, 365), "to": Vector2(950, 365), "size": Vector2(170, 100), "speed": 110.0, "phase": 0.0}
		],
		"memory_shard": Vector2(740, 365),
		"shard_lore": "The bridge keeper left the platform running after the station shut down. It still carries anyone patient enough to wait for it.",
		"linger": 9.5,
		"hazard": false,
		"hazard_y": 365.0,
		"hazard_amplitude": 0.0,
		"hazard_speed": 0.0,
		"accent": Color(0.20, 0.91, 0.88)
	},
	{
		"name": "Phase Relay",
		"chapter": 3,
		"subtitle": "THE SWITCH ONLY LISTENS IN THE RIGHT MOMENT",
		"hint": "Finish the two-relay echo on SWITCH A. SWITCH B pulses on a repeating cycle—be standing on it when its amber ring lights up. The gate gives you 3.2 seconds to cross.",
		"spawn": Vector2(150, 500),
		"plate_a": Vector2(420, 500),
		"plate_b": Vector2(1010, 220),
		"plate_b_mode": "pulse",
		"pulse_period": 5.5,
		"pulse_active_seconds": 2.1,
		"pulse_phase_offset": 1.4,
		"echo_waypoints": [Vector2(300, 270), Vector2(650, 270)],
		"memory_shard": Vector2(800, 500),
		"shard_lore": "The phase keeper never forced the signal through. They learned to listen for the one clear moment when the station answered.",
		"linger": 9.5,
		"gate_open_seconds": 3.2,
		"hazard": false,
		"hazard_y": 365.0,
		"hazard_amplitude": 0.0,
		"hazard_speed": 0.0,
		"accent": Color(1.0, 0.68, 0.30)
	},
	{
		"name": "Twin Signal",
		"chapter": 4,
		"subtitle": "ONE ROUTE IS NOT ENOUGH",
		"hint": "Record Echo 1 from spawn to SWITCH A. Let it settle, then record Echo 2 from A to SWITCH C. Reach SWITCH B while both ghosts hold their plates.",
		"spawn": Vector2(155, 365),
		"plate_a": Vector2(405, 230),
		"plate_c": Vector2(700, 495),
		"plate_b": Vector2(990, 365),
		"echo_slots": 2,
		"memory_shard": Vector2(820, 175),
		"shard_lore": "Two couriers answered the same signal from opposite ends of the station. For the first time, the silence had to make room for a conversation.",
		"linger": 22.0,
		"hazard": false,
		"hazard_y": 365.0,
		"hazard_amplitude": 0.0,
		"hazard_speed": 0.0,
		"accent": Color(0.55, 0.52, 1.0)
	},
	{
		"name": "Convergent Signal",
		"chapter": 4,
		"subtitle": "TWO MEMORIES. ONE MOMENT.",
		"hint": "Set both echoes on A and C, then hold SWITCH B through its pulse. The gate stays open for only 2.4 seconds—cross immediately.",
		"spawn": Vector2(155, 505),
		"plate_a": Vector2(410, 250),
		"plate_c": Vector2(705, 475),
		"plate_b": Vector2(1005, 235),
		"plate_b_mode": "pulse",
		"pulse_period": 6.0,
		"pulse_active_seconds": 2.5,
		"pulse_phase_offset": 0.0,
		"echo_slots": 2,
		"memory_shard": Vector2(850, 510),
		"shard_lore": "The relay answered only when both recorded paths aligned with the same brief pulse. The couriers called it a promise kept together.",
		"linger": 22.0,
		"gate_open_seconds": 2.4,
		"hazard": false,
		"hazard_y": 365.0,
		"hazard_amplitude": 0.0,
		"hazard_speed": 0.0,
		"accent": Color(1.0, 0.64, 0.38)
	},
	{
		"name": "Orbit Crossing",
		"chapter": 5,
		"subtitle": "WAIT FOR THE BRIDGE. RIDE THE SIGNAL.",
		"hint": "Record the two-relay route to SWITCH A. Then cross the VOID on either moving bridge, collect the Memory Shard if you can, and catch SWITCH B's amber pulse. The gate stays open for 3.8 seconds.",
		"spawn": Vector2(150, 500),
		"plate_a": Vector2(370, 500),
		"plate_b": Vector2(1010, 220),
		"echo_waypoints": [Vector2(250, 300), Vector2(410, 360)],
		"void_zones": [
			{"position": Vector2(500, 112), "size": Vector2(400, 500)}
		],
		"moving_platforms": [
			{"from": Vector2(500, 500), "to": Vector2(910, 500), "size": Vector2(180, 92), "speed": 80.0, "phase": 9.4},
			{"from": Vector2(500, 300), "to": Vector2(910, 300), "size": Vector2(180, 92), "speed": 80.0, "phase": 2.2}
		],
		"plate_b_mode": "pulse",
		"pulse_period": 6.0,
		"pulse_active_seconds": 2.5,
		"pulse_phase_offset": 0.65,
		"memory_shard": Vector2(700, 300),
		"shard_lore": "The bridge operators built two routes across the same silence. One carried feet; the other carried the last light left in the station.",
		"linger": 10.5,
		"gate_open_seconds": 3.8,
		"hazard": false,
		"hazard_y": 365.0,
		"hazard_amplitude": 0.0,
		"hazard_speed": 0.0,
		"accent": Color(0.20, 0.91, 0.88)
	},
	{
		"name": "Tandem Relay",
		"chapter": 5,
		"subtitle": "BOTH MEMORIES MUST KNOW THE WAY",
		"hint": "Record Echo 1 to SWITCH A, then Echo 2 to SWITCH C. BOTH routes must cross RELAY 1 and RELAY 2 in order and curve around the ECHO DEAD ZONE. Reach SWITCH B after both ghosts settle.",
		"spawn": Vector2(150, 500),
		"plate_a": Vector2(400, 210),
		"plate_c": Vector2(760, 510),
		"plate_b": Vector2(1050, 360),
		"echo_slots": 2,
		"echo_waypoints": [Vector2(310, 370), Vector2(650, 250)],
		"echo_jammer": Vector2(520, 550),
		"echo_jammer_radius": 78.0,
		"memory_shard": Vector2(860, 180),
		"shard_lore": "Two couriers shared one map but never one destination. The relays kept the route honest when the blackout tried to divide them.",
		"linger": 26.0,
		"hazard": false,
		"hazard_y": 365.0,
		"hazard_amplitude": 0.0,
		"hazard_speed": 0.0,
		"accent": Color(0.72, 0.48, 1.0)
	},
	{
		"name": "The Last Duet",
		"chapter": 5,
		"subtitle": "FOUR RELAYS. TWO ECHOES. ONE LAST WINDOW.",
		"hint": "Send Echo 1 to A and Echo 2 to C. Both recordings must visit RELAY 1 → 2 → 3 → 4 in order and stay outside the ECHO DEAD ZONE. Reach SWITCH B during its pulse, then cross the 4.2-second gate.",
		"spawn": Vector2(150, 520),
		"plate_a": Vector2(820, 520),
		"plate_c": Vector2(820, 200),
		"plate_b": Vector2(1050, 365),
		"echo_slots": 2,
		"echo_waypoints": [Vector2(280, 300), Vector2(420, 480), Vector2(580, 250), Vector2(700, 430)],
		"echo_jammer": Vector2(520, 570),
		"echo_jammer_radius": 78.0,
		"plate_b_mode": "pulse",
		"pulse_period": 6.2,
		"pulse_active_seconds": 2.2,
		"pulse_phase_offset": 1.0,
		"memory_shard": Vector2(680, 560),
		"shard_lore": "The final pair of couriers left no names behind. Their four relays still answer together, even when the station has almost forgotten its own voice.",
		"linger": 26.0,
		"gate_open_seconds": 4.2,
		"hazard": false,
		"hazard_y": 365.0,
		"hazard_amplitude": 0.0,
		"hazard_speed": 0.0,
		"accent": Color(1.0, 0.58, 0.36)
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
		if level.has("echo_slots"):
			var raw_echo_slots: Variant = level["echo_slots"]
			if not (raw_echo_slots is int) or int(raw_echo_slots) != 2:
				errors.append("%s echo_slots must be the supported value 2." % prefix)
			if not level.has("plate_c") or not (level.get("plate_c") is Vector2):
				errors.append("%s two-echo rooms require plate_c as a Vector2." % prefix)
		elif level.has("plate_c"):
			errors.append("%s plate_c requires echo_slots: 2." % prefix)
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
			elif str(raw_plate_b_mode) not in ["hold", "toggle", "pulse"]:
				errors.append("%s plate_b_mode must be 'hold', 'toggle', or 'pulse'." % prefix)
		if str(level.get("plate_b_mode", "hold")) == "pulse":
			for pulse_key in ["pulse_period", "pulse_active_seconds"]:
				if not level.has(pulse_key):
					errors.append("%s pulse switch is missing '%s'." % [prefix, pulse_key])
			var raw_pulse_period: Variant = level.get("pulse_period", 0.0)
			var raw_pulse_active: Variant = level.get("pulse_active_seconds", 0.0)
			if not (raw_pulse_period is int or raw_pulse_period is float):
				errors.append("%s pulse_period must be numeric." % prefix)
			elif not (raw_pulse_active is int or raw_pulse_active is float):
				errors.append("%s pulse_active_seconds must be numeric." % prefix)
			else:
				var pulse_period := float(raw_pulse_period)
				var pulse_active := float(raw_pulse_active)
				if pulse_period < 2.0 or pulse_period > 20.0:
					errors.append("%s pulse_period must be between 2 and 20 seconds." % prefix)
				if pulse_active < 0.5 or pulse_active >= pulse_period:
					errors.append("%s pulse_active_seconds must be at least 0.5 and shorter than its period." % prefix)
			if level.has("pulse_phase_offset"):
				var raw_phase_offset: Variant = level["pulse_phase_offset"]
				if not (raw_phase_offset is int or raw_phase_offset is float):
					errors.append("%s pulse_phase_offset must be numeric." % prefix)
				elif float(raw_phase_offset) < 0.0 or float(raw_phase_offset) > 20.0:
					errors.append("%s pulse_phase_offset must be between 0 and 20 seconds." % prefix)
		if level.has("moving_platforms"):
			var raw_platforms: Variant = level["moving_platforms"]
			if not (raw_platforms is Array):
				errors.append("%s moving_platforms must be an Array." % prefix)
			else:
				if raw_platforms.is_empty():
					errors.append("%s moving_platforms must contain at least one platform." % prefix)
				for platform_index in range(raw_platforms.size()):
					var raw_platform: Variant = raw_platforms[platform_index]
					if not (raw_platform is Dictionary):
						errors.append("%s moving_platforms[%d] must be a Dictionary." % [prefix, platform_index])
						continue
					var platform: Dictionary = raw_platform
					for platform_key in ["from", "to", "size", "speed"]:
						if not platform.has(platform_key):
							errors.append("%s moving_platforms[%d] is missing '%s'." % [prefix, platform_index, platform_key])
					if not (platform.get("from") is Vector2) or not (platform.get("to") is Vector2):
						errors.append("%s moving_platforms[%d] endpoints must be Vector2 values." % [prefix, platform_index])
					if not (platform.get("size") is Vector2):
						errors.append("%s moving_platforms[%d] size must be a Vector2." % [prefix, platform_index])
					if not (platform.get("speed") is int or platform.get("speed") is float):
						errors.append("%s moving_platforms[%d] speed must be numeric." % [prefix, platform_index])
					else:
						var platform_speed := float(platform["speed"])
						if platform_speed < 20.0 or platform_speed > 180.0:
							errors.append("%s moving_platforms[%d] speed must be between 20 and 180." % [prefix, platform_index])
					if platform.get("from") is Vector2 and platform.get("to") is Vector2:
						var platform_from: Vector2 = platform["from"]
						var platform_to: Vector2 = platform["to"]
						if platform_from.distance_to(platform_to) < 100.0:
							errors.append("%s moving_platforms[%d] travel distance must be at least 100 units." % [prefix, platform_index])
						if platform.get("size") is Vector2:
							var platform_size: Vector2 = platform["size"]
							if platform_size.x < 80.0 or platform_size.y < 48.0:
								errors.append("%s moving_platforms[%d] must be at least 80x48 units." % [prefix, platform_index])
							for endpoint in [platform_from, platform_to]:
								if endpoint.x - platform_size.x * 0.5 < 48.0 or endpoint.x + platform_size.x * 0.5 > 1232.0 or endpoint.y - platform_size.y * 0.5 < 112.0 or endpoint.y + platform_size.y * 0.5 > 612.0:
									errors.append("%s moving_platforms[%d] endpoint is outside the playable room." % [prefix, platform_index])
					if platform.has("phase") and not (platform["phase"] is int or platform["phase"] is float):
						errors.append("%s moving_platforms[%d] phase must be numeric." % [prefix, platform_index])

		if level.has("void_zones"):
			var raw_void_zones: Variant = level["void_zones"]
			if not (raw_void_zones is Array):
				errors.append("%s void_zones must be an Array." % prefix)
			else:
				if not level.has("moving_platforms"):
					errors.append("%s void_zones require a moving_platform route." % prefix)
				for void_index in range(raw_void_zones.size()):
					var raw_void: Variant = raw_void_zones[void_index]
					if not (raw_void is Dictionary):
						errors.append("%s void_zones[%d] must be a Dictionary." % [prefix, void_index])
						continue
					var void_zone: Dictionary = raw_void
					if not (void_zone.get("position") is Vector2) or not (void_zone.get("size") is Vector2):
						errors.append("%s void_zones[%d] position and size must be Vector2 values." % [prefix, void_index])
						continue
					var void_position: Vector2 = void_zone["position"]
					var void_size: Vector2 = void_zone["size"]
					if void_size.x <= 0.0 or void_size.y <= 0.0:
						errors.append("%s void_zones[%d] size must be positive." % [prefix, void_index])
					elif void_position.x < 48.0 or void_position.y < 112.0 or void_position.x + void_size.x > 1232.0 or void_position.y + void_size.y > 612.0:
						errors.append("%s void_zones[%d] must remain inside the playable room." % [prefix, void_index])

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
		for point_key in ["spawn", "plate_a", "plate_b", "plate_c", "memory_shard", "echo_waypoint", "echo_jammer"]:
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
		if level.has("plate_c") and level["plate_c"] is Vector2:
			var plate_c_position: Vector2 = level["plate_c"]
			for anchor_key in ["spawn", "plate_a", "plate_b", "memory_shard"]:
				if level.has(anchor_key) and level[anchor_key] is Vector2:
					var anchor_position: Vector2 = level[anchor_key]
					if plate_c_position.distance_to(anchor_position) < 86.0:
						errors.append("%s Switch C must be separated from %s by at least 86 units." % [prefix, anchor_key])

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
