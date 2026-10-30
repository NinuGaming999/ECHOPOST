# ECHOPOST

[![Godot checks](https://github.com/NinuGaming999/ECHOPOST/actions/workflows/godot-checks.yml/badge.svg)](https://github.com/NinuGaming999/ECHOPOST/actions/workflows/godot-checks.yml) [![Android APK](https://github.com/NinuGaming999/ECHOPOST/actions/workflows/android-apk.yml/badge.svg)](https://github.com/NinuGaming999/ECHOPOST/actions/workflows/android-apk.yml)

**Every player leaves a ghost.** ECHOPOST is a mobile-first 2D puzzle adventure about recording your movement and using its echo to solve rooms you cannot solve alone.

This repository is the long-term home of the full game. The current source implements an early playable slice: keyboard/touch movement, recording/playback echoes with endpoint and Relay Beacon validation, layered cyan neon route trails, pressure switches, hold/toggle/timed gates, exits, twenty-four chamber layouts across five signal chapters, two independently recorded echoes, roaming sentinels, an echo-only jammer puzzle, optional Memory Shards with lore fragments, scrollable chapter selection, chapter unlocks and versioned local save data. Gameplay art is mostly procedural, with the supplied ECHO logo used on the menu, project icon and Android launcher.

> **Development status:** Early development. Automated Godot CI parses the project and runs smoke tests on every push and pull request. Android APK builds are automated, but the game still needs real-device QA and production art/audio. Online echo sharing and broader accessibility options remain future work.

## Run the game

1. Install a stable Godot 4.x release from https://godotengine.org/.
2. Clone or download this repository.
3. In Godot Project Manager, choose **Import** and select `project.godot`.
4. Press **F5** to run the project.

No third-party plugin, paid asset, API key, or server is required for the current build.

## Controls

- **WASD / arrow keys:** move.
- **Record Echo:** begin recording your route; press again to release the echo.
- **Restart Room:** restart the current puzzle.
- **Pause:** freeze or resume play.
- **Options:** choose slow/normal/fast movement, mirror the joystick/actions for left-handed play, and toggle **Performance Mode**. It is ON by default, reduces optional effects and route-rendering work, and targets 30 FPS on mobile. Turn it OFF on faster devices to restore the full neon effects and 60 FPS mobile cap.
- **Latch Switch B / E:** in Latch Protocol, stand near Switch B after the echo holds A, then tap LATCH SWITCH B or press E. The switch stays latched when you leave it.
- **Touch movement:** touch and drag anywhere on the left side of the playfield to move (right side when left-handed mode is enabled). A floating, dead-zone joystick gives fine control with short drags and eases in/out so movement does not snap or drift. The top HUD, center gutter and bottom action row are protected from movement input.
- **Touch actions:** use the large translucent round **REC** button on the right to record/send an echo; the optional Switch B latch is the smaller round control beside it. Round **Pause**, **Menu** and **Restart** controls stay at the top/bottom edges. In left-handed mode, the Record/Latch cluster mirrors to the left.

## Visual identity

The supplied ECHO logo sets a dark navy and neon-cyan theme. A new 16:9 cosmic-nebula backdrop adds a ringed signal planet, distant cyan skyline and orbital horizon; twinkling cyan/teal stars animate over the scene. The player and echo remain glowing orbit-orbs; recorded paths retain their layered cyan glow. Performance Mode reduces the ambient star count and skips glint rays so the backdrop stays lightweight.

## Core puzzle

1. Record a route to **Switch A** and finish recording while standing on it.
2. Your translucent echo repeats the route and then holds Switch A.
3. Move the real robot onto **Switch B**.
4. When both switches are active, cross the gate and reach the exit.

Later rooms introduce roaming sentinels and longer diagonal routes. A sentinel hit now counts as a room failure: the take is erased, a short SIGNAL LOST card appears, and the entire current chamber automatically restarts. In relay rooms, missing a required beacon, visiting beacons out of order, or finishing away from Switch A also triggers an automatic restart after the failure reason is shown; no manual RESTART ROOM tap is needed. The menu, HUD and modal cards follow viewport changes, while the recording, latch, restart and menu controls use larger touch targets and subtle press/hover animation. On very short landscape screens below 420 design units high, the main menu switches to a two-column layout and calculates rows from each button's real theme-enforced height. Under 340 units it hides the intro; under 280 it hides the progress line. Regression tests cover 800×620, 800×600, 800×580, 800×540, 800×500, 800×480, 800×360, 640×360, 800×320, 800×280 and 800×260 viewports. The bottom gameplay action row also calculates widths from the available space and shortens the outer labels on narrow screens; regression checks keep menu, record, latch and restart controls separate at 640×360, 720×360 and 800×320. While recording, a glowing cyan trace shows the route being captured and the starting point; it turns red if it crosses Null Corridor's jammer. After sending, the echo trail appears in teal. The first five rooms teach the two-switch echo mechanic with different layouts and patrol patterns. Chapter II begins after Null Corridor and recombines the relay, jammer, sentinel, toggle-switch and timed-gate rules into four late-campaign challenges. **Static Bloom** adds one required Relay Beacon, while **Chorus Route** requires Relay 1 then Relay 2 in order before finishing on Switch A; reversed order is rejected, and beacon crossings between samples count. **Pulse Lock** adds a 3.5-second gate window after both switches are held: cross the gate before time runs out, or leave the switch and try again. A countdown label and shrinking amber bar show the remaining window; after crossing safely, the exit remains powered. **Latch Protocol** teaches a toggle-style Switch B: once the echo holds A, stand on B and tap LATCH SWITCH B or press E. The switch stays latched after activation, so you can leave it and cross the gate. **Triune Relay** raises the route challenge to three ordered beacons before Switch A; the route is rejected if any beacon is visited out of sequence, and the hint lists the required relays in order. **Fracture Clock** combines three ordered relays with a 4.5-second timed gate, so players must plan the echo route and then cross the barrier before the window closes. **Dead Air Protocol** is the gauntlet: four ordered relays, a fast moving sentinel that can erase the recording on contact, a shorter 6.5-second echo linger, Switch B farther from the gate, and a 1.8-second gate window. **Null Corridor** adds an echo-only ECHO DEAD ZONE: the recorded route must curve around the purple jammer, while the real robot can cross it. A jammed recording is rejected and triggers the automatic same-room reset. Chapter II adds four advanced rooms: **Glass Horizon** combines three relays with a wide sentinel sweep; **Clockbreak Crossing** puts a three-relay route ahead of a 2.8-second gate; **Switchback Protocol** combines two relays, an echo-only jammer and a latched Switch B; **The Last Chorus** combines four ordered relays, a jammer bypass, a moving sentinel and a 2.8-second gate. Chapter III introduces **Drift Bridge**, a moving bridge across a full-height void gap, and **Phase Relay**, a repeating pulse switch. Chapter IV adds **Twin Signal**, where two independently recorded echoes hold Switches A and C while the real player reaches B, and **Convergent Signal**, which combines the duet with a pulse-timed Switch B and a 2.4-second gate window. Chapter V expands the duet challenge: **Orbit Crossing** adds two moving bridges over a void and a pulse gate; **Tandem Relay** requires both echoes to trace the same ordered relays while avoiding a jammer; **The Last Duet** combines two echoes, four ordered relays, a jammer and a 4.2-second pulse gate. The campaign now has twenty-four rooms across five signal chapters and remains in active development. Each room also has one optional violet Memory Shard. Touch it to reveal a short courier-network lore fragment; collecting it is saved locally and is never required to open the gate or exit. Use **MEMORY ARCHIVE** from the main menu to revisit recovered fragments and see which rooms still hide a memory. Recover all twenty-four shards to restore the courier network's final signal; the reward appears in-game and in the Archive. Older version-1 campaign saves still load, with Memory Shards starting uncollected.

## Project layout

```text
ECHOPOST/
├── project.godot
├── export_presets.cfg
├── scenes/main.tscn
├── scripts/game.gd
├── scripts/core/echo_track.gd
├── scripts/data/level_catalog.gd
├── scripts/data/progress_store.gd
├── scripts/data/settings_store.gd
├── assets/echopost_logo.jpg
├── assets/echopost_icon.svg
├── tests/headless_smoke.gd
├── tests/game_flow_smoke.gd
├── .github/workflows/godot-checks.yml
├── .github/workflows/android-apk.yml
├── docs/GAME_DESIGN.md
├── docs/ROADMAP.md
├── docs/BUILD_STATUS.md
├── PROJECT_PROGRESS.md
├── CONTRIBUTING.md
├── LICENSE
└── RUN_TESTS.bat
```

## Smoke tests

With Godot available on PATH, run both tests:

```sh
godot --headless --path . --script res://tests/headless_smoke.gd
godot --headless --path . --script res://tests/game_flow_smoke.gd
```

On Windows, run `RUN_TESTS.bat`. The data tests cover echo-track timing/interpolation, campaign validation, and save/load boundaries. The data smoke tests also verify that control/graphics preferences save independently from campaign progress, including the default-on and persisted Performance Mode setting, and validate timed-gate/ordered-relay room data. The gameplay integration test verifies recording limits, short-recording feedback, independently captured two-echo routes and Switch C, duet gate conditions, pulse-gated duet timing, automatic full-room resets after sentinel contact and failed relay routes, reset-state cleanup, responsive/premium UI sizing and anchoring, logo texture/visibility and full-layout restoration across ten viewport sizes, compact 960×540 menu reflow and non-overlapping bottom touch controls, idempotent portal completion with save restoration, chapter/archive/options layouts, Memory Shard lore persistence, single/two-/three-/four-relay routes, linked-state feedback, timed-gate countdown/timeout/retry/crossing, Fracture Clock, and Dead Air Protocol, the Null Corridor jammer's blocked-route/reset and safe-bypass cases, plus lifecycle pause, Performance Mode toggling/persistence, and the incremental jammer segment-intersection helper. GitHub Actions installs Godot and runs these tests on each push and pull request. See `PROJECT_PROGRESS.md` for the exact source map, known gaps, recent CI results, and next tasks.

## Android APK

An automated GitHub Actions workflow builds an installable Android APK on every push to `main` and publishes the latest development build as the **ECHOPOST Nightly APK** prerelease.

**[Download the latest ECHOPOST APK from GitHub Releases](https://github.com/NinuGaming999/ECHOPOST/releases/tag/nightly)**

The APK is a **debug-signed development build for direct device testing**, not a production-signed Google Play release. The preset targets 64-bit ARM Android devices and uses landscape orientation. Because the nightly signing key is for testing, uninstall an older nightly build first if Android refuses to update it.

To create a versioned GitHub release, push a version tag after reviewing the build, for example:

```sh
git tag v0.1.0
git push origin v0.1.0
```

The Android workflow builds the APK and attaches it to that versioned release. Before publishing to Google Play, configure and protect a dedicated release keystore, create a production-signed build, and test the app on real devices.

## Saves

Campaign progress and collected memories are stored at `user://echopost_save.cfg`. Control and graphics preferences are stored separately at `user://echopost_settings.cfg`, so changing speed, joystick side or Performance Mode does not reset progress. Cloud save and online echo-sharing features are future milestones. See `docs/ROADMAP.md` and `docs/GAME_DESIGN.md`.

## Contributing

Read `CONTRIBUTING.md` and keep changes focused, testable, and compatible with the current stable Godot 4.x release.

## License

MIT; see `LICENSE`. Add only art, music, and sound assets with clear ownership or licensing.
