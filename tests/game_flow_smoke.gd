extends SceneTree

## Integration smoke test for the main scene's echo puzzle flow.
## This deliberately stops after gate activation, before completion writes campaign saves.
const MainScene = preload("res://scenes/main.tscn")
const EchoTrackScript = preload("res://scripts/core/echo_track.gd")

var failures: int = 0


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var game: Control = MainScene.instantiate()
	root.add_child(game)
	await process_frame

	game.call("_start_level", 0)
	_check(int(game.get("screen_state")) == 1, "Starting a chamber should switch the game to PLAYING.")

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


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
