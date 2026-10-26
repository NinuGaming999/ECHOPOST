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
- Campaign-data validator, data-layer smoke tests, and a main-scene gameplay integration test.
- Automated GitHub Actions workflow that imports/parses the project and runs both smoke-test scripts.
- README, design document, roadmap, contribution guide, and MIT license.

## Verification status

The Godot project import/parse step and data-layer tests passed in GitHub Actions. The gameplay integration test is now included in the workflow; its latest run should be checked on the Actions page before treating it as verified. No Android APK has been built or tested on a physical device. The source is an early game foundation, not a release-ready claim.

## Next work items

1. Confirm the latest workflow passes the gameplay integration test; fix any regressions it catches.
2. Play through all three rooms with keyboard and touch input; tune switch radius, sentinel paths, timing, and messaging.
3. Refactor the main controller into smaller scene/controller/renderer components as room count grows.
4. Expand the campaign with reusable puzzle mechanics, clear checkpoints, and a reliable level validator.
5. Add original character and environment art, animation, audio, accessibility options, safe-area handling, and device-specific QA.
6. Consider online echo sharing only after route validation, abuse reporting, moderation, privacy, and service costs are designed.
