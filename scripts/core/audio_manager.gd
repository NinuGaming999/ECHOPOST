extends Node

## Generates a compact ambient loop and short original feedback tones in memory.
## No imported audio assets, streaming threads, or per-frame synthesis are required.
const SAMPLE_RATE := 22050
const MUSIC_SECONDS := 8.0
const MUSIC_NOTES: Array[float] = [440.0, 392.0, 349.23, 392.0, 440.0, 523.25, 392.0, 329.63]

const EFFECT_SPECS: Dictionary = {
	"record_start": {"start_hz": 360.0, "end_hz": 620.0, "duration": 0.16, "second_hz": 0.0, "gain": 0.13},
	"echo_send": {"start_hz": 520.0, "end_hz": 880.0, "duration": 0.24, "second_hz": 660.0, "gain": 0.14},
	"gate_open": {"start_hz": 300.0, "end_hz": 720.0, "duration": 0.42, "second_hz": 480.0, "gain": 0.13},
	"memory": {"start_hz": 720.0, "end_hz": 1180.0, "duration": 0.34, "second_hz": 1440.0, "gain": 0.11},
	"failure": {"start_hz": 290.0, "end_hz": 105.0, "duration": 0.30, "second_hz": 0.0, "gain": 0.14},
	"complete": {"start_hz": 440.0, "end_hz": 880.0, "duration": 0.72, "second_hz": 660.0, "gain": 0.13},
	"ui": {"start_hz": 480.0, "end_hz": 640.0, "duration": 0.09, "second_hz": 0.0, "gain": 0.08},
}

var music_enabled: bool = true
var sfx_enabled: bool = true
var haptics_enabled: bool = false

var music_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer
var sfx_streams: Dictionary = {}


func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.name = "AmbientMusic"
	music_player.volume_db = -17.0
	add_child(music_player)
	music_player.stream = _build_ambient_music()

	sfx_player = AudioStreamPlayer.new()
	sfx_player.name = "FeedbackSFX"
	sfx_player.volume_db = -1.0
	add_child(sfx_player)

	for effect_name in EFFECT_SPECS.keys():
		sfx_streams[effect_name] = _build_effect_stream(str(effect_name))


func configure(enable_music: bool, enable_sfx: bool, enable_haptics: bool) -> void:
	music_enabled = enable_music
	sfx_enabled = enable_sfx
	haptics_enabled = enable_haptics
	_sync_music()


func set_music_enabled(enabled: bool) -> void:
	music_enabled = enabled
	_sync_music()


func set_sfx_enabled(enabled: bool) -> void:
	sfx_enabled = enabled
	if not sfx_enabled and is_instance_valid(sfx_player):
		sfx_player.stop()


func set_haptics_enabled(enabled: bool) -> void:
	haptics_enabled = enabled


func play_sfx(effect_name: String) -> void:
	if not sfx_enabled or not is_instance_valid(sfx_player):
		return
	if not sfx_streams.has(effect_name):
		return
	sfx_player.stop()
	sfx_player.stream = sfx_streams[effect_name] as AudioStream
	sfx_player.play()


func pulse_haptic(duration_ms: int = 28, amplitude: float = 0.25) -> void:
	if not haptics_enabled:
		return
	if not (OS.has_feature("android") or OS.has_feature("ios") or OS.has_feature("web")):
		return
	Input.vibrate_handheld(clampi(duration_ms, 10, 120), clampf(amplitude, 0.0, 1.0))


func _sync_music() -> void:
	if not is_instance_valid(music_player):
		return
	if music_enabled:
		if not music_player.playing:
			music_player.play()
	else:
		music_player.stop()


func _build_ambient_music() -> AudioStreamWAV:
	var frame_count := int(SAMPLE_RATE * MUSIC_SECONDS)
	var pcm := PackedByteArray()
	pcm.resize(frame_count * 2)
	for frame in range(frame_count):
		var time_seconds := float(frame) / float(SAMPLE_RATE)
		var slow_breath := 0.78 + 0.22 * sin(TAU * time_seconds / MUSIC_SECONDS)
		var low_pad := sin(TAU * 110.0 * time_seconds) * 0.040
		var fifth_pad := sin(TAU * 165.0 * time_seconds) * 0.023
		var octave_pad := sin(TAU * 220.0 * time_seconds) * 0.014
		var note_index := int(floor(time_seconds)) % MUSIC_NOTES.size()
		var note_time := fposmod(time_seconds, 1.0)
		var note_envelope := exp(-5.2 * note_time)
		var soft_note := sin(TAU * MUSIC_NOTES[note_index] * note_time) * note_envelope * 0.018
		var sample := clampf((low_pad + fifth_pad + octave_pad) * slow_breath + soft_note, -0.20, 0.20)
		pcm.encode_s16(frame * 2, int(round(sample * 32767.0)))

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = pcm
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = frame_count
	return stream


func _build_effect_stream(effect_name: String) -> AudioStreamWAV:
	var spec: Dictionary = EFFECT_SPECS[effect_name]
	var duration := float(spec["duration"])
	var frame_count := maxi(1, int(SAMPLE_RATE * duration))
	var start_hz := float(spec["start_hz"])
	var end_hz := float(spec["end_hz"])
	var second_hz := float(spec["second_hz"])
	var gain := float(spec["gain"])
	var pcm := PackedByteArray()
	pcm.resize(frame_count * 2)

	for frame in range(frame_count):
		var time_seconds := float(frame) / float(SAMPLE_RATE)
		var progress := float(frame) / float(frame_count)
		var frequency_sweep := start_hz * time_seconds + 0.5 * (end_hz - start_hz) * time_seconds * progress
		var phase := TAU * frequency_sweep
		var envelope := exp(-3.2 * progress) * (1.0 - progress)
		var tone := sin(phase) + 0.22 * sin(phase * 2.0)
		if second_hz > 0.0:
			tone += 0.16 * sin(TAU * second_hz * time_seconds)
		var sample := clampf(tone * envelope * gain, -0.22, 0.22)
		pcm.encode_s16(frame * 2, int(round(sample * 32767.0)))

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = pcm
	stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	return stream
