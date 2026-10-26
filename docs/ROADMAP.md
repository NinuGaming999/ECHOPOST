# Development Roadmap

This roadmap is the intended path from the initial project foundation to a release-quality mobile game. Items are not complete merely because they appear here.

## Milestone 0 — Project foundation (started)

- [x] Standalone Godot 4 project with no third-party plugins.
- [x] Procedural visual style so the project boots without external assets.
- [x] Desktop movement and touchscreen virtual joystick.
- [x] Record, stop, replay, and linger behavior for one echo.
- [x] Two-switch gate and exit loop.
- [x] Ten authored room layouts with varied switch positions, sentinel patrol patterns, single/two/three-relay ordered-route challenges, a timed-gate crossing, and a toggle-style Switch B.
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
- [ ] Support multiple aspect ratios and device safe areas.
- [ ] Add an in-game level-state debug view for development builds.

## Milestone 2 — Content foundation

- [ ] Create a reusable room scene/data model and a level validation tool.
- [ ] Build 12–20 authored puzzles that teach one new idea at a time.
- [x] Add a required Relay Beacon route checkpoint to Static Bloom and an ordered two-relay route to Chorus Route, including segment-distance validation and clear rejection feedback.
- [x] Add Pulse Lock, a timed gate with a 3.5-second crossing window, timeout/retry handling, and a portal that stays powered after a successful crossing.
- [ ] Add more switch types and carefully constrain puzzle complexity beyond the first toggle switch, ordered three-relay route and timed-gate mechanics.
- [ ] Add checkpoints, better reset messaging, and a campaign map.
- [x] Add one optional Memory Shard per authored chamber (currently ten) with short courier-station lore fragments, local collection persistence, and a Memory Archive to revisit recovered lore.
- [x] Add a non-blocking restored-signal reward when all currently authored memories are recovered, both in the play status and Memory Archive.
- [ ] Expand narrative fragments and authored world storytelling beyond the ten current introductory memories.

## Milestone 3 — Art, animation, and audio

- [ ] Replace temporary procedural robot drawing with a consistent character asset set.
- [ ] Create several visual room themes with clear contrast and low-cost mobile rendering.
- [ ] Animate walking, recording, echo playback, sentinel contact, gate opening, and portal entry.
- [ ] Add original SFX, ambient sound, music, and settings for audio/haptics.
- [ ] Add color-blindness-friendly indicators and accessibility options.

## Milestone 4 — Mobile QA and release preparation

- [ ] Validate lifecycle pause/resume on physical Android devices and unusual background/foreground transitions.
- [ ] Test physical Android devices, low-end GPU performance, and battery use.
- [ ] Tune touch targets, joystick sensitivity, landscape handling, and screen cutouts.
- [ ] Set package ID, icons, versioning, privacy disclosures, crash reporting policy, and signing.
- [ ] Set up release builds and a documented QA checklist.
- [ ] Test a closed beta before public distribution.

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
