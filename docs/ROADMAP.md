# Development Roadmap

This roadmap is the intended path from the initial project foundation to a release-quality mobile game. Items are not complete merely because they appear here.

## Milestone 0 — Project foundation (started)

- [x] Standalone Godot 4 project with no third-party plugins.
- [x] Procedural visual style so the project boots without external assets.
- [x] Desktop movement and touchscreen virtual joystick.
- [x] Record, stop, replay, and linger behavior for one echo.
- [x] Two-switch gate and exit loop.
- [x] Nineteen authored room layouts with varied switch positions, sentinel patrol patterns, single/two/three/four-relay ordered-route challenges, a timed-gate crossing, a toggle-style Switch B, a three-relay/timed-gate combination, and a four-relay/sentinel/short-timer gauntlet.
- [x] Moving sentinel in later rooms.
- [x] Chapter unlocks, local save data, and a scrollable chapter selector.
- [x] Separate echo-track, level-catalog, and progress-store code from the main scene.
- [x] README, design notes, roadmap, and contributor guidance.
- [ ] Run the project in the Godot editor and fix any engine-version issues (requires a Godot 4 engine run).

## Milestone 1 — Core mechanic hardening

- [x] Add headless tests for echo timestamp ordering, interpolation/copying, campaign-data validation, save/load, and unlock clamping.
- [ ] Add remaining engine-level tests for lifecycle focus-out and save-failure edge cases. Recording cap, too-short recording, sentinel reset/cancelled interrupted take, restart cleanup, portal completion idempotency, ordered relay sequence, timed-gate timeout/retry/crossing, gate conditions, and lifecycle pause now have smoke coverage.
- [x] Add schema validation and diagnostics for level catalog data, including arbitrary draft lists, unique names, route/switch spacing, room bounds, and sentinel tuning.
- [x] Add clear feedback for invalid recording endpoints and a live route preview while recording.
- [x] Auto-pause active gameplay when the app loses focus or Android/iOS suspends it; clear held joystick input and require explicit player resume.
- [x] Add movement-speed presets and left-handed joystick placement, persisted separately from campaign progress.
- [x] Automatically reset the whole chamber after sentinel contact or a failed relay route, with a short readable reset card and no extra restart tap.
- [x] Add responsive bottom HUD placement, centered modal cards, larger primary touch targets, consistent premium button/panel styling and subtle button feedback animations.
- [ ] Support multiple aspect ratios and device safe areas.
- [ ] Add an in-game level-state debug view for development builds.

## Milestone 2 — Content foundation

- [ ] Create a reusable room scene/data model and a level validation tool.
- [ ] Build 20–24 authored puzzles that teach one new idea at a time.
- [x] Add a required Relay Beacon route checkpoint to Static Bloom and an ordered two-relay route to Chorus Route, including segment-distance validation and clear rejection feedback.
- [x] Add Pulse Lock, a timed gate with a 3.5-second crossing window, timeout/retry handling, and a portal that stays powered after a successful crossing.
- [x] Add an echo-only signal-jammer/dead-zone room; reject recordings whose sample segments enter the field and auto-reset after failure, while allowing a safe curved route.
- [x] Add a repeating pulse Switch B that only activates during a short authored phase window.
- [x] Add moving bridge platforms with rider carry and void-zone support checks; echoes continue to replay the recorded world-space route.
- [ ] Add more switch types and carefully constrain puzzle complexity beyond the toggle and pulse switches, moving platforms, ordered four-relay route, and combined relay/sentinel/timed-gate gauntlet.
- [ ] Add checkpoints, better reset messaging, and a campaign map.
- [x] Add one optional Memory Shard per authored chamber (currently nineteen) with short courier-station lore fragments, local collection persistence, and a Memory Archive to revisit recovered lore.
- [x] Add a non-blocking restored-signal reward when all currently authored memories are recovered, both in the play status and Memory Archive.
- [ ] Expand narrative fragments and authored world storytelling beyond the nineteen current introductory memories.

## Milestone 3 — Art, animation, and audio

- [x] Establish an initial ECHO logo/neon-cyan visual identity: supplied logo, dark navy panels, matching geometric SVG icon and cyan-to-red route feedback. Authored character animation, multiple room art packs and audio remain future work.
- [ ] Replace temporary procedural robot drawing with a consistent character asset set.
- [ ] Create several visual room themes with clear contrast and low-cost mobile rendering.
- [ ] Animate walking, recording, echo playback, sentinel contact, gate opening, and portal entry.
- [ ] Add original SFX, ambient sound, music, and settings for audio/haptics.
- [ ] Add color-blindness-friendly indicators and accessibility options.

## Milestone 4 — Mobile QA and release preparation

- [ ] Validate lifecycle pause/resume on physical Android devices and unusual background/foreground transitions.
- [ ] Install the current debug APK and test all nineteen rooms, touch controls, save persistence and app relaunch on a real Android device.
- [x] Add saved Performance Mode with reduced decorative rendering, batched route polylines and a 30 FPS mobile target; both supported Godot CI versions pass the settings/rendering regressions.
- [ ] Measure low-end GPU performance, actual FPS, battery/thermals, aspect ratios and safe areas on physical devices.
- [ ] Tune touch targets, joystick sensitivity, landscape handling, and screen cutouts based on device tests.
- [x] Set the Android package ID (`com.ninugaming.echopost`), version (`0.1.0`), app icon and tracked arm64-v8a debug export preset.
- [x] Automate Android debug APK export, ZIP integrity validation, Actions artifact upload and nightly GitHub Release publication. [Successful export run](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40493513100).
- [ ] Configure protected production release signing and finalize privacy/storefront disclosures; debug builds are not production releases.
- [ ] Document the device QA checklist and test a closed beta before public distribution.

## Milestone 5 — Asynchronous community system (optional, after core game quality)

- [ ] Design a small secure backend for account identities and uploaded route data.
- [ ] Validate route size, duration, movement bounds, room version, and sample rates on the server.
- [ ] Add reporting, moderation, rate limits, and retention controls before public uploads.
- [ ] Add curated daily challenge recordings and a community gallery.
- [ ] Keep offline play fully functional if the service is unavailable.

## Milestone 6 — Release and post-launch

- [ ] Finish the campaign and accessibility pass.
- [ ] Commission or create original store art, screenshots, icon, and trailer.
- [ ] Complete privacy/security review and storefront requirements.
- [ ] Publish a release candidate and resolve critical/blocking defects.
- [ ] Plan additional worlds based on playtest data rather than adding grind systems.
