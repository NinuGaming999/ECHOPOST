# ECHOPOST

**Every player leaves a ghost.** ECHOPOST is a mobile-first 2D puzzle adventure about recording your movement and using its echo to solve rooms you cannot solve alone.

This repository is the long-term home of the full game. The current source implements a playable vertical slice: movement, touch controls, recording/playback echoes with endpoint validation, pressure switches, gates/exits, three campaign rooms, roaming sentinels, chapter unlocks, local save data, and procedural graphics so it runs without external art assets.

> **Development status:** Early development. The source has not yet had a Godot-engine smoke test in the current build environment. Production art/audio, accessibility options, online echo sharing, and Android release packaging remain future work.

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
- **Touch:** use the on-screen virtual joystick and buttons.

## Core puzzle

1. Record a route to **Switch A** and finish recording while standing on it.
2. Your translucent echo repeats the route and then holds Switch A.
3. Move the real robot onto **Switch B**.
4. When both switches are active, cross the gate and reach the exit.

Later rooms introduce roaming sentinels. The current game uses procedural artwork, making this early version easy to run and extend.

## Project layout

```text
ECHOPOST/
├── project.godot
├── scenes/main.tscn
├── scripts/game.gd
├── scripts/core/echo_track.gd
├── scripts/data/level_catalog.gd
├── scripts/data/progress_store.gd
├── assets/echopost_icon.svg
├── tests/headless_smoke.gd
├── docs/GAME_DESIGN.md
├── docs/ROADMAP.md
├── docs/BUILD_STATUS.md
├── CONTRIBUTING.md
├── LICENSE
└── RUN_TESTS.bat
```

## Smoke tests

With Godot available on PATH, run:

```sh
godot --headless --path . --script res://tests/headless_smoke.gd
```

On Windows, double-click `RUN_TESTS.bat`. The tests cover echo-track timing/interpolation, campaign data and validation, and local save/load boundaries. They must still be executed in Godot to confirm runtime behavior.

## Android

The project is configured for a landscape 1280×720 viewport and the Compatibility renderer. Install matching Godot export templates and configure the Android SDK/JDK in Editor Settings before adding an Android export preset. Set a unique application ID and signing settings before producing a release build. Verify touch controls on real devices before publishing.

## Saves

Progress is stored locally at `user://echopost_save.cfg`. Cloud save and online echo-sharing features are future milestones. See `docs/ROADMAP.md` and `docs/GAME_DESIGN.md`.

## Contributing

Read `CONTRIBUTING.md` and keep changes focused, testable, and compatible with the current stable Godot 4.x release.

## License

MIT; see `LICENSE`. Add only art, music, and sound assets with clear ownership or licensing.
