# ECHOPOST — Build Status

**Build label:** Foundation / early playable slice  
**Project engine:** Godot 4.x  
**Target:** Android first, desktop for development and QA

## Implemented in this source

- Standalone Godot project entry point and original SVG icon.
- Main menu, chapter select, instructions, pause, completion, retry, and continue flows.
- Keyboard movement and an on-screen joystick that also supports mouse testing.
- Timestamped route recording, an 8-second recording limit, echo playback, final-position linger, and rejection feedback when a route does not end on Switch A.
- Two-switch gate and portal completion flow.
- Three authored room configurations; later rooms add moving sentinels.
- Local versioned campaign save data and progress clamping.
- Automatic pause on Android/iOS application suspension or application focus loss; held joystick input is cleared, in-progress recording state is preserved, and gameplay never auto-resumes without player input.
- Campaign-data validator, data-layer smoke tests, and a main-scene gameplay integration test, including lifecycle pause/resume assertions.
- Automated GitHub Actions workflow that imports/parses the project and runs both smoke-test scripts.
- README, design document, roadmap, contribution guide, and MIT license.

## Verification status

GitHub Actions run 14 passed on both Godot 4.4.0 and 4.7.2 after the lifecycle-pause code and integration test were added ([run details](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40384700347)). The checks import/parse the project and run data-layer plus gameplay smoke tests, covering invalid echo-route rejection, accepted echo creation, gate activation, and automatic pause while preserving an active recording. No Android APK has been built or tested on a physical device. The source is an early game foundation, not a release-ready claim.

## Next work items

1. Continue expanding integration tests for recording-duration limits, sentinel resets, pause/restart behavior, and full room completion.
2. Play through all three rooms with keyboard and touch input; tune switch radius, sentinel paths, timing, and messaging.
3. Add viewport/safe-area handling and test the game at mobile aspect ratios; the current layout is authored for 1280×720.
4. Expand the campaign with reusable puzzle mechanics, clear checkpoints, and a reliable level validator.
5. Add original character and environment art, animation, audio, accessibility options, safe-area handling, and device-specific QA.
6. Consider online echo sharing only after route validation, abuse reporting, moderation, privacy, and service costs are designed.
