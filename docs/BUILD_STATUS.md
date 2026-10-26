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
- Local versioned campaign save data and progress clamping.
- Automatic pause on Android/iOS application suspension or application focus loss; held joystick input is cleared, in-progress recording state is preserved, and gameplay never auto-resumes without player input.
- Campaign-data validator and smoke tests covering echo-track copy identity, a recording capped to exactly eight seconds, too-short recording feedback, sentinel collision reset, restart cleanup while recording/echoing and from pause, portal completion counting exactly once with save restoration, invalid-route rejection, accepted echo creation, gate activation, and lifecycle pause/resume.
- Automated GitHub Actions workflow that imports/parses the project and runs both smoke-test scripts.
- README, design document, roadmap, contribution guide, and MIT license.

## Verification status

Godot CI run 39 passed on both Godot 4.4.0 and 4.7.2 after the campaign expanded to six chambers ([run 39](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40389126011)). Run 42 also passed both versions after the scrollable chapter selector and UI regression test were added ([run 42](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40389230677)); it imports/parses the project and runs data and gameplay tests. Live route preview and chapter scrolling still need manual inspection in the user's editor/device. No Android APK has been built or tested on a physical device; this remains an early development build, not release-ready.

## Next work items

1. Manually inspect the live route preview and six-room scrollable chapter selector in Godot; play through the new rooms and tune patrol fairness and puzzle pacing.
2. Play through all three rooms with keyboard and touch input; tune switch radius, sentinel paths, timing, and messaging.
3. Add viewport/safe-area handling and test the game at mobile aspect ratios; the current layout is authored for 1280×720.
4. Build toward 12–20 authored chambers and introduce at least one new puzzle mechanic beyond switch placement/sentinel patrol variants.
5. Add original character and environment art, animation, audio, accessibility options, safe-area handling, and device-specific QA.
6. Consider online echo sharing only after route validation, abuse reporting, moderation, privacy, and service costs are designed.
