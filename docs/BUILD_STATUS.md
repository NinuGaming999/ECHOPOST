# ECHOPOST — Build Status

**Build label:** Foundation / early playable slice  
**Project engine:** Godot 4.x  
**Target:** Android first, desktop for development and QA

## Implemented in this source

- Standalone Godot project entry point and original SVG icon.
- Main menu, scrollable chapter select, scrollable Memory Archive, instructions, pause, completion, retry, and continue flows.
- Keyboard movement and an on-screen joystick that also supports mouse testing.
- Options panel with slow/normal/fast movement presets and a left-handed joystick option; these preferences persist in a separate settings file, independent from campaign saves.
- Latch Protocol's toggle Switch B is functional: a dedicated on-screen button and keyboard E activate it only when the player is near B and the echo has finished playback and settled on A; the latched state remains active after leaving the switch and resets on room restart.
- Timestamped route recording with a strict 8-second cap (elapsed time is clamped before the final sample), echo playback, final-position linger, live amber route preview while recording, and rejection feedback when a route does not end on Switch A.
- Too-short recording feedback now tells the player to keep recording; the minimum-duration check and displayed 0.7-second requirement share one constant.
- Echo track copies instantiate from their preloaded script resource instead of relying on a global `EchoTrack` class registration; this fixes the Godot 4.4 compile failure reported during local testing.
- Two-switch gate and portal completion flow.
- Eleven authored room layouts with varied switch positions and sentinel sweep patterns; Chorus Route requires two ordered relays, Pulse Lock adds a timed gate crossing, Latch Protocol introduces a toggle-style Switch B, and Triune Relay requires three relays in order, and Fracture Clock combines three relays with a 4.5-second timed gate. The chapter list scrolls as the campaign grows.
- One optional Memory Shard and lore fragment per chamber, rendered as a glowing violet diamond; collection is tracked in menu progress and saved locally. The Memory Archive allows rereading recovered fragments and shows undiscovered rooms. Collecting all eleven restores the courier network's final signal and displays the reward in-game and in the Archive. The archive's default count text uses the live room count rather than a hard-coded number.
- Level-catalog validation for unique/non-empty names, room bounds, minimum route distance, switch separation, and safe sentinel patrol height/width/speed; arbitrary draft arrays can be validated without editing the canonical campaign.
- Version-2 local campaign save data, Memory Shard collection persistence, validation of shard indices, and backward-compatible loading of version-1 saves.
- Separate settings store with default values and normalization to supported movement presets; Options UI/handedness integration tests are green on both supported CI Godot versions.
- Automatic pause on Android/iOS application suspension or application focus loss; held joystick input is cleared, in-progress recording state is preserved, and gameplay never auto-resumes without player input.
- Static Bloom Relay Beacon: its echo recording must pass within the beacon radius and finish on Switch A; segment-distance checking correctly counts crossings between recorded sample points.
- Chorus Route ordered Relay Beacons: the echo recording must cross Relay 1 before Relay 2 and then finish on Switch A. Reversed relay order is rejected; linked/unlinked beacon visuals reflect the encounter order, and waypoint lists are validated for type, bounds, and safe separation.
- Pulse Lock timed gate: both switches open a 3.5-second crossing window. The countdown ticks only while gameplay runs, timeout closes the gate if the player is still before the barrier, leaving either switch rearms a retry, and crossing safely keeps the portal powered. The playfield and HUD display the remaining window, including a shrinking amber progress bar that starts full and empties at timeout.
- Campaign-data validator and smoke tests including intentionally malformed room drafts, unique room names, eleven-room data, three-relay sequence and relay/timed-gate combination, Memory Shard/lore and relay/timed-gate data/bounds, version-2 shard save round-trip and version-1 compatibility, isolated control-preference save/normalization, normal and all-shards-restored pickup/persistence, dynamic Archive count text, echo-track copy identity, exact eight-second cap, too-short feedback, sentinel interruption, restart cleanup including toggle-latch reset, toggle-button/keyboard E validation, portal completion idempotency, scrollable chapter/archive/options UI, direct route rejection, valid relay-segment acceptance, ordered relay sequence and linked-state validation, timed-gate countdown label/bar ratio/timeout/retry/crossing, gate activation and lifecycle pause/resume.
- Automated GitHub Actions workflow that imports/parses the project and runs both smoke-test scripts.
- README, design document, roadmap, contribution guide, and MIT license.

## Verification status

[Godot CI run 173](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40401469061) passed on both Godot 4.4.0 and 4.7.2 after improving ordered-relay rejection hints and adding assertions for the full three-relay sequence. It verifies project import/parse plus data and gameplay smoke tests, including eleven-room data, the timed-gate countdown bar's full/partial/empty states, dynamic relay-sequence feedback, timed-gate activation/crossing, save restoration, and existing gameplay flows.

[Run 82](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40392916662) passed Memory Archive, Options UI, movement presets and left-handed joystick tests; [run 81](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40392848307) passed settings defaults/persistence/normalization; [run 65](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40390957517) passed Memory Shard persistence and version-1 save compatibility. Live visuals and controls still need manual inspection in the user's editor/device. No Android APK has been built or tested on a physical device; this remains an early development build, not release-ready.

## Next work items

1. Manually inspect Static Bloom, Chorus Route, Triune Relay and Fracture Clock beacon/timer visuals, Pulse Lock's countdown indicator, Latch Protocol's toggle switch, live route preview, violet Memory Shards, Memory Archive, Options panel and eleven-room scrollable chapter selector in Godot; test both joystick sides and tune patrol fairness/puzzle pacing.
2. Play through all eleven rooms with keyboard and touch input; tune switch radius, sentinel paths, timing, and messaging.
3. Add viewport/safe-area handling and test the game at mobile aspect ratios; the current layout is authored for 1280×720.
4. Build toward 12–20 authored chambers and introduce mechanics beyond switch placement/sentinel patrol variants; the first toggle switch and three-relay route are now implemented.
5. Add original character and environment art, animation, audio, accessibility options, safe-area handling, and device-specific QA.
6. Consider online echo sharing only after route validation, abuse reporting, moderation, privacy, and service costs are designed.
