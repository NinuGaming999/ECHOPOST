# ECHOPOST — Build Status

**Build label:** Foundation / early playable slice  
**Project engine:** Godot 4.x  
**Target:** Android first, desktop for development and QA

## Implemented in this source

- Standalone Godot project entry point and original SVG icon.
- Main menu, scrollable chapter select, scrollable Memory Archive, instructions, pause, completion, retry, and continue flows.
- Keyboard movement and an on-screen joystick that also supports mouse testing.
- Options panel with slow/normal/fast movement presets and a left-handed joystick option; these preferences persist in a separate settings file, independent from campaign saves.
- Timestamped route recording with a strict 8-second cap (elapsed time is clamped before the final sample), echo playback, final-position linger, live amber route preview while recording, and rejection feedback when a route does not end on Switch A.
- Too-short recording feedback now tells the player to keep recording; the minimum-duration check and displayed 0.7-second requirement share one constant.
- Echo track copies instantiate from their preloaded script resource instead of relying on a global `EchoTrack` class registration; this fixes the Godot 4.4 compile failure reported during local testing.
- Two-switch gate and portal completion flow.
- Eight authored room layouts with varied switch positions and sentinel sweep patterns; Chorus Route adds a two-relay sequence that must be crossed in order, and Pulse Lock adds a timed gate crossing. The chapter list scrolls as the campaign grows.
- One optional Memory Shard and lore fragment per chamber, rendered as a glowing violet diamond; collection is tracked in menu progress and saved locally. The Memory Archive allows rereading recovered fragments and shows undiscovered rooms. Collecting all eight restores the courier network's final signal and displays the reward in-game and in the Archive. The archive's default count text uses the live room count rather than a hard-coded number.
- Level-catalog validation for unique/non-empty names, room bounds, minimum route distance, switch separation, and safe sentinel patrol height/width/speed; arbitrary draft arrays can be validated without editing the canonical campaign.
- Version-2 local campaign save data, Memory Shard collection persistence, validation of shard indices, and backward-compatible loading of version-1 saves.
- Separate settings store with default values and normalization to supported movement presets; Options UI/handedness integration tests are green on both supported CI Godot versions.
- Automatic pause on Android/iOS application suspension or application focus loss; held joystick input is cleared, in-progress recording state is preserved, and gameplay never auto-resumes without player input.
- Static Bloom Relay Beacon: its echo recording must pass within the beacon radius and finish on Switch A; segment-distance checking correctly counts crossings between recorded sample points.
- Chorus Route ordered Relay Beacons: the echo recording must cross Relay 1 before Relay 2 and then finish on Switch A. Reversed relay order is rejected; linked/unlinked beacon visuals reflect the encounter order, and waypoint lists are validated for type, bounds, and safe separation.
- Pulse Lock timed gate: both switches open a 3.5-second crossing window. The countdown ticks only while gameplay runs, timeout closes the gate if the player is still before the barrier, leaving either switch rearms a retry, and crossing safely keeps the portal powered. The playfield and HUD display the remaining window.
- Campaign-data validator and smoke tests including intentionally malformed room drafts, unique room names, Memory Shard/lore and relay/timed-gate data/bounds, version-2 shard save round-trip and version-1 compatibility, isolated control-preference save/normalization, normal and all-shards-restored pickup/persistence, dynamic Archive count text, echo-track copy identity, exact eight-second cap, too-short feedback, sentinel interruption, restart cleanup, portal completion idempotency, scrollable chapter/archive/options UI, direct route rejection, valid relay-segment acceptance, ordered relay sequence and linked-state validation, timed-gate countdown/timeout/retry/crossing, gate activation and lifecycle pause/resume.
- Automated GitHub Actions workflow that imports/parses the project and runs both smoke-test scripts.
- README, design document, roadmap, contribution guide, and MIT license.

## Verification status

[Godot CI run 122](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40397091984) passed on both Godot 4.4.0 and 4.7.2 after Pulse Lock, ordered-relay linked-state correction, and timer regression tests were added. It verifies project import/parse plus data and gameplay smoke tests, including reversed/correct relay order, timed-gate countdown in the real frame loop, timer freeze while paused, timeout closure, retry lockout, and permanent portal power after a successful crossing.

[Run 82](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40392916662) passed Memory Archive, Options UI, movement presets and left-handed joystick tests; [run 81](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40392848307) passed settings defaults/persistence/normalization; [run 65](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40390957517) passed Memory Shard persistence and version-1 save compatibility. Live visuals and controls still need manual inspection in the user's editor/device. No Android APK has been built or tested on a physical device; this remains an early development build, not release-ready.

## Next work items

1. Manually inspect Static Bloom and Chorus Route relay visuals, Pulse Lock's countdown indicator, live route preview, violet Memory Shards, Memory Archive, Options panel and eight-room scrollable chapter selector in Godot; test both joystick sides and tune patrol fairness/puzzle pacing.
2. Play through all eight rooms with keyboard and touch input; tune switch radius, sentinel paths, timing, and messaging.
3. Add viewport/safe-area handling and test the game at mobile aspect ratios; the current layout is authored for 1280×720.
4. Build toward 12–20 authored chambers and introduce at least one new puzzle mechanic beyond switch placement/sentinel patrol variants.
5. Add original character and environment art, animation, audio, accessibility options, safe-area handling, and device-specific QA.
6. Consider online echo sharing only after route validation, abuse reporting, moderation, privacy, and service costs are designed.
