class_name EchoTrack
extends RefCounted

## Timestamped, data-only player movement. It is safe to duplicate or persist in a level replay format.
var samples: Array[Dictionary] = []


func clear() -> void:
	samples.clear()


func add_sample(sample_time: float, position: Vector2) -> void:
	var safe_time := maxf(0.0, sample_time)
	if not samples.is_empty():
		safe_time = maxf(safe_time, float(samples.back()["t"]))
	samples.append({"t": safe_time, "p": position})


func copy_track() -> EchoTrack:
	var duplicate_track := EchoTrack.new()
	for sample in samples:
		duplicate_track.samples.append({"t": float(sample["t"]), "p": sample["p"]})
	return duplicate_track


func duration() -> float:
	if samples.is_empty():
		return 0.0
	return float(samples.back()["t"])


func position_at(playback_time: float) -> Vector2:
	if samples.is_empty():
		return Vector2.ZERO
	if playback_time <= float(samples.front()["t"]):
		var first_position: Vector2 = samples.front()["p"]
		return first_position
	if playback_time >= duration():
		var last_position: Vector2 = samples.back()["p"]
		return last_position

	for i in range(1, samples.size()):
		var previous: Dictionary = samples[i - 1]
		var following: Dictionary = samples[i]
		var previous_time := float(previous["t"])
		var following_time := float(following["t"])
		if playback_time <= following_time:
			var span := following_time - previous_time
			if span <= 0.0001:
				var held_position: Vector2 = following["p"]
				return held_position
			var weight := clampf((playback_time - previous_time) / span, 0.0, 1.0)
			var previous_position: Vector2 = previous["p"]
			var following_position: Vector2 = following["p"]
			return previous_position.lerp(following_position, weight)
	var final_position: Vector2 = samples.back()["p"]
	return final_position
