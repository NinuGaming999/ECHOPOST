# ECHOPOST — Build Status

**Build label:** Foundation / early playable slice  
**Project engine:** Godot 4.x  
**Target:** Android first, desktop for development and QA

## Implemented in this source

- Standalone Godot project entry point and original SVG icon.
- Main menu, scrollable chapter select, instructions, pause, completion, retry, and continue flows.
- Keyboard movement and an on-screen joystick that also supports mouse testing.
- Timestamped route recording with a strict 8-second cap (elapsed time is clamped before the final sample), echo playback, final-position linger, live amber route preview while recording, and rejection feedback when a route does not end on Switch A.
- Too-short recording feedback now tells the player to keep recording; the minimum-duration check and displayed 0.7-second requirement share one constant.
- Echo track copies instantiate from their preloaded script resource instead of relying on a global `EchoTrack` class registration; this fixes the Godot 4.4 compile failure reported during local testing.
- Two-switch gate and portal completion flow.
- Six authored room layouts with varied switch positions and sentinel sweep patterns; the chapter list scrolls as the campaign grows.
- One optional Memory Shard and lore fragment per chamber, rendered as a glowing violet diamond; collection is tracked in the menu progress and saved locally.
- Level-catalog validation for unique/non-empty names, room bounds, minimum route distance, switch separation, and safe sentinel patrol height/width/speed; arbitrary draft arrays can be validated without editing the canonical campaign.
- Version-2 local campaign save data, Memory Shard collection persistence, validation of shard indices, and backward-compatible loading of version-1 saves.
- Automatic pause on Android/iOS application suspension or application focus loss; held joystick input is cleared, in-progress recording state is preserved, and gameplay never auto-resumes without player input.
- Campaign-data validator and smoke tests including intentionally malformed room drafts, unique room names, Memory Shard positions/lore, version-2 shard save round-trip, duplicate/out-of-range index sanitization, version-1 save compatibility, collection lore/persistence with save restoration, echo-track copy identity, exact eight-second cap, too-short feedback, sentinel interruption, restart cleanup, portal completion idempotency, scrollable chapter UI, route validation, gate activation and lifecycle pause/resume.
- Automated GitHub Actions workflow that imports/parses the project and runs both smoke-test scripts.
- README, design document, roadmap, contribution guide, and MIT license.

## Verification status

Godot CI run 65 passed on both Godot 4.4.0 and 4.7.2 after Memory Shards, version-2 save persistence, version-1 compatibility, and the collection integration test were added ([run 65](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40390957517)). The checks import/parse the project and run data-layer/gameplay smoke tests, including shard index sanitization, old-save compatibility, displaying lore, and saving collection while restoring test progress afterward. Live visuals and gameplay still need manual inspection in the user's editor/device. No Android APK has been built or tested on a physical device; this remains an early development build, not release-ready.

## Next work items

1. Manually inspect the live route preview, violet Memory Shards, and six-room scrollable chapter selector in Godot; play through the rooms and tune patrol fairness and puzzle pacing.
2. Play through all six rooms with keyboard and touch input; tune switch radius, sentinel paths, timing, and messaging.
3. Add viewport/safe-area handling and test the game at mobile aspect ratios; the current layout is authored for 1280×720.
4. Build toward 12–20 authored chambers and introduce at least one new puzzle mechanic beyond switch placement/sentinel patrol variants.
5. Add original character and environment art, animation, audio, accessibility options, safe-area handling, and device-specific QA.
6. Consider online echo sharing only after route validation, abuse reporting, moderation, privacy, and service costs are designed.
