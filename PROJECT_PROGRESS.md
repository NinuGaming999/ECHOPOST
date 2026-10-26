# ECHOPOST — PROJECT PROGRESS / HANDOFF

> **This file is the continuity record for future ECHOPOST development.** Read it before changing code. The game is deliberately an unfinished long-running project; do not treat the current six-room prototype as complete. After every meaningful code, test, gameplay, or build change, update this file with what changed, why, exact file/line references, current verification results, and the next actionable tasks.

**Repository:** https://github.com/NinuGaming999/ECHOPOST  
**Working branch:** `main`  
**Project root:** repository root; main scene is `res://scenes/main.tscn`  
**Engine:** Godot 4.x; CI tests Godot 4.4.0 and 4.7.2  
**Target:** Android-first landscape game; desktop builds support development and testing  
**Recording-cap code commit:** `b5f36b6a4f764a595e5dd930e8d6b3cebd5ce3a8`  
**Gameplay-test commit:** `11c3b30de34323c536b0b8302eb8604259248d52`  
**Main controller source blob for the exact line map below:** `3f0ae4c4d61b09e26fd62050540fa999695100d0` (764 lines)  
**Status:** Early playable foundation / vertical slice — **not complete, not release-ready**.

---

## 1. Game vision and current playable loop

ECHOPOST is a mobile-first 2D puzzle adventure about recording a route and letting a ghost echo repeat it. The intended primary loop is:

1. Move around a chamber and inspect Switch A, Switch B, the gate, and exit portal.
2. Press **RECORD ECHO**, move to Switch A, then press **STOP & SEND ECHO** while near A.
3. The ghost plays back the recorded timed route and then lingers at the final point for a level-defined duration.
4. The real player moves to Switch B while the ghost holds A.
5. The two switches open the gate; reaching the portal completes the chamber.
6. Campaign progress is saved locally and the next chamber unlocks.

The current source includes six authored chamber layouts:
- **The First Echo:** basic teach-the-mechanic chamber.
- **Long Memory:** roaming sentinel and a more distant Switch B.
- **Split Signal:** faster/larger sentinel movement and opposite-side switches.
- **Fractured Lane:** a longer diagonal route under a wide patrol.
- **Crosscurrent:** switches in opposite corners and a faster midline patrol.
- **Static Bloom:** a long route and wide sentinel sweep.

These six rooms still share the same core two-switch echo mechanic; they vary route geometry and sentinel patterns rather than introducing six separate mechanics.

The look is currently drawn procedurally in `scripts/game.gd`; the SVG app icon is the main external art asset. Procedural visuals keep the project importable without an asset pack but are placeholder art, not final art.

## 2. Latest work in this development pass

### Godot 4.4 compile failure: EchoTrack self-reference
**Reported by the user:** Godot 4.4 produced `Identifier not found: EchoTrack` at `res://scripts/core/echo_track.gd:20`. That caused the echo script to fail compilation; `scripts/game.gd` could not compile its dependent script, and subsequent `clear()` calls failed because the track variables were `Nil`.

**Root cause:** `echo_track.gd` referenced the global name `EchoTrack` inside its own `copy_track()` method (`EchoTrack.new()`) and its return annotation. This was unnecessarily dependent on Godot's global script-class registration/cache even though all in-repository consumers already load the script with `preload()`.

**Fix committed:**
- `scripts/core/echo_track.gd:L1–L5`: removed `class_name EchoTrack`; the script remains a `RefCounted` resource and is instantiated through preloaded script references.
- `scripts/core/echo_track.gd:L19–L25`: `copy_track()` no longer types its return as the global `EchoTrack` class and instantiates the same resource using `get_script().new()`, then copies all samples.
- `scripts/game.gd:L18–L21` and `L35–L40`: already uses the `ECHO_TRACK_SCRIPT = preload(...)` resource and so required no modification. Its previous `Nil.clear()` errors were downstream symptoms, not separate root causes.
- `tests/headless_smoke.gd:L39–L44`: added a regression check that a copied track's script is exactly the preloaded resource, as well as retaining copy independence/interpolation tests.
- Code fix commit: `5179b423d0d00d4a2ee807bc9d621d376b04b49a`.
- Regression-test commit: `3a02e78abafe8c5cd1bb923e2e00b644b5a9c3f7`.
- [Godot CI run 21](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40385871675) passed on Godot 4.4.0 and 4.7.2, including the new regression assertion.

### Recording duration hardening and gameplay regression tests
**Changed:** `scripts/game.gd` and `tests/game_flow_smoke.gd`.

- `scripts/game.gd:L16–L17`: introduced one minimum-duration constant (`MIN_RECORD_SECONDS = 0.7`) alongside the 8-second maximum.
- `scripts/game.gd:L100–L122`: recording elapsed time is clamped to `MAX_RECORD_SECONDS` before recording samples are written. This prevents a frame delta from producing a route whose final timestamp exceeds eight seconds.
- `scripts/game.gd:L396–L421`: the too-short recording path uses the same `MIN_RECORD_SECONDS` constant and clearer feedback: keep recording until the 0.7-second minimum, then stop on Switch A. It intentionally keeps recording active so the player can continue rather than losing the attempted route.
- `tests/game_flow_smoke.gd:L92–L107`: starts at 7.99 seconds, advances one capped frame, and asserts recording auto-stops, an echo is made when ending at Switch A, and its recorded duration is exactly 8.0 seconds.
- `tests/game_flow_smoke.gd:L110–L121`: asserts a too-short stop does not create an echo, does not discard the ongoing recording, and clearly explains how to continue.
- `tests/game_flow_smoke.gd:L124–L132`: verifies sentinel contact returns the player to the spawn and displays contact feedback.
- The test commit is `11c3b30de34323c536b0b8302eb8604259248d52`; [Godot CI run 25](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40387225782) passed both Godot 4.4.0 and 4.7.2.
- `docs/ROADMAP.md` and `docs/BUILD_STATUS.md` now record the new coverage.

This hardening pass addresses a real frame-step boundary issue and makes the minimum-duration interaction clearer. It adds test coverage, but it does not replace manual play-testing on the user's PC or phone.

### Restart reset and portal-completion regression tests
**Changed:** `tests/game_flow_smoke.gd`.

- `tests/game_flow_smoke.gd:L137–L174`: `_test_restart_clears_state()` creates active recording/echo tracks, advances their timers, opens the gate and holds joystick direction; the real reset handler must return the player to spawn, clear both tracks and timers, hide/stop the echo, close the gate and clear input. It then verifies restarting from PAUSED returns to PLAYING.
- `tests/game_flow_smoke.gd:L177–L200`: `_test_portal_completion_is_idempotent()` sends the player through a powered portal, verifies COMPLETE and the completion panel, ensures the completion count increments once, runs the checker again to prove no duplicate count, and restores the original saved campaign values.
- The test header now accurately says that the suite exercises completion and restores saved progress.
- [Godot CI run 33](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40388464089) passed on Godot 4.4.0 and 4.7.2 with these restart/completion assertions.

### Live recording-route preview
**Changed:** `scripts/game.gd`.

- `scripts/game.gd:L672–L678`: while `is_recording`, the route draws in amber with a ring and START marker at the first sample. This makes the recorded path visible before the echo is sent.
- `scripts/game.gd:L680–L681`: the echo playback trail uses the same helper but remains cyan, distinguishing a saved/replaying echo from the live recording.
- `scripts/game.gd:L756–L762`: `_draw_track_path(track, tint, line_width)` draws the samples; rendering only reads route data and does not change gameplay.
- [Godot CI run 34](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40388600546) passed on Godot 4.4.0 and 4.7.2 after adding the shared renderer helper. Visual quality still needs a manual editor/device check.
### Six-room campaign and scrollable chapter selector
**Changed:** `scripts/data/level_catalog.gd`, `scripts/game.gd`, `tests/headless_smoke.gd`, and `tests/game_flow_smoke.gd`.

- `scripts/data/level_catalog.gd:L4–L89` now contains six room definitions: The First Echo, Long Memory, Split Signal, Fractured Lane, Crosscurrent, and Static Bloom. New rooms vary diagonal route length, opposing-corner switches, hazard height, sentinel sweep width/speed, and accent color.
- `scripts/data/level_catalog.gd:L91–L128` retains the clamped copy accessor and validates room keys, positions, linger durations and hazard fields.
- `scripts/game.gd:L252–L280` creates a `ScrollContainer` named `ChapterScroll` with a `VBoxContainer` list named `ChapterList`. Each level gets a button; the Back button stays below the viewport and does not overlap later rooms.
- `tests/headless_smoke.gd:L47–L65` requires at least six chambers, validates the data schema, checks every chamber name is non-empty and unique, and preserves the defensive-copy assertion.
- `tests/game_flow_smoke.gd:L205–L220` verifies the scroll container, automatic vertical scroll mode and one list button per authored chamber.
- [Godot CI run 39](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40389126011) passed the expanded level catalog; [run 42](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40389230677) passed the scrollable UI and regression tests on Godot 4.4.0 and 4.7.2.
- This is a longer early-game slice, not a finished campaign: new switch types, checkpoints, moving platforms, narrative fragments and physical-device layout testing remain.
### Room-schema validator hardening
**Changed:** `scripts/data/level_catalog.gd` and `tests/headless_smoke.gd`.

- `scripts/data/level_catalog.gd:L99–L100`: `validate_levels()` now delegates to the reusable `validate_level_list(levels)` function so both canonical campaign data and proposed drafts can be checked.
- `scripts/data/level_catalog.gd:L103–L120`: reject an empty list and blank/duplicate chamber names.
- `scripts/data/level_catalog.gd:L121–L136`: check required fields, Vector2 types, positive linger, and all playfield positions.
- `scripts/data/level_catalog.gd:L138–L148`: reject a spawn less than 180 units from Switch A (too short for the intended route) and reject overlapping/near-overlapping A/B switches closer than 86 units.
- `scripts/data/level_catalog.gd:L150–L163`: validate sentinel height, sweep amplitude (0–500) and speed (greater than 0, no more than 4).
- `tests/headless_smoke.gd:L69–L83`: provide a deliberately malformed two-room draft and assert the validator reports duplicate names, too-short route, overlapping switches and negative patrol speed. `L86–L90` is the shared message-fragment helper.
- [Godot CI run 49](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40389764965) passed on Godot 4.4.0 and 4.7.2 with the invalid-draft regression tests.
- The validator is a static data check, not a pathfinding solver: it does not yet prove each room is solvable against the moving sentinel timing.

### Mobile lifecycle pause hardening
**Changed:** `scripts/game.gd` and `tests/game_flow_smoke.gd`.

- `scripts/game.gd:L70–L74`: new `_notification(what)` handler listens for `NOTIFICATION_APPLICATION_PAUSED` (Android/iOS backgrounding) and `NOTIFICATION_APPLICATION_FOCUS_OUT`.
- `scripts/game.gd:L77–L87`: `_pause_for_lifecycle()` only pauses when the game was actively playing. It clears touch/mouse joystick state, sets the pause button to **RESUME**, explains the pause to the player, and refreshes rendering/HUD.
- The existing frame loop at `scripts/game.gd:L100–L122` exits early unless the screen state is PLAYING, so recording time, echo time, hazard time, and player movement stop advancing while paused.
- The handler does not erase `recording_track`, set `is_recording` to false, or auto-resume when the application returns. A paused recording can continue after the player explicitly resumes.
- `tests/game_flow_smoke.gd:L23–L24` invokes the lifecycle test and starts a fresh chamber so later tests run from a clean state.
- `tests/game_flow_smoke.gd:L74–L89` simulates application suspension and verifies: state changes to PAUSED; joystick vector is cleared; recording flag/time survive; paused frame processing does not advance recording time; application resume does not bypass the pause screen; manual RESUME restores PLAYING.
- The roadmap and build status were updated in `docs/ROADMAP.md` and `docs/BUILD_STATUS.md`.

This change is covered by an automated headless integration test. It is **not yet a substitute for checking behavior on a real Android device**, including actual app switching and returning from the background.

## 3. Project layout and the job of each file

| Path | Responsibility / current condition |
|---|---|
| `project.godot` | Application name, icon, landscape 1280×720 viewport, canvas-item stretch, compatibility renderer and WASD/arrow input map. |
| `scenes/main.tscn` | Very small main scene: full-rect `Control` attached to `scripts/game.gd`. |
| `scripts/game.gd` | Main controller, menu/HUD construction, player movement, echo recording/playback, puzzle loop, sentinel, save flow, and all procedural rendering. **730 lines in the snapshot documented here; it is the largest refactor target later, but refactor only after tests protect behavior.** |
| `scripts/core/echo_track.gd` | Data-only `RefCounted` script loaded through preloaded script resources; avoids global `class_name` lookup; stores points, clamps timestamps to nondecreasing order, copies tracks, returns duration, interpolates route positions, and holds endpoint outside the timestamp range. |
| `scripts/data/level_catalog.gd` | Six authored room dictionaries, defensive-copy accessor, canonical/draft validator for schema, names, spacing, position bounds and hazard tuning. |
| `scripts/data/progress_store.gd` | Versioned local save boundary (`user://echopost_save.cfg`) using `ConfigFile`; defaults safely when save is absent/unreadable and clamps unlocked level to campaign size. |
| `tests/headless_smoke.gd` | Data-layer smoke tests for track order/interpolation/copying, six-room catalog schema and unique names, defensive copying, save/load and unlock clamping. |
| `tests/game_flow_smoke.gd` | Main-scene integration tests for scrollable chapter selection, lifecycle pause, recording cap/feedback, sentinel reset, reset cleanup, portal-completion idempotency, invalid endpoint rejection, echo creation and gate activation. |
| `RUN_TESTS.bat` | Windows shortcut to run both headless smoke tests if Godot is on PATH. |
| `.github/workflows/godot-checks.yml` | Imports/parses project then runs both tests on a Godot 4.4.0 / 4.7.2 matrix. |
| `assets/echopost_icon.svg` | Original editable SVG project icon. |
| `README.md` | Setup, controls, current loop, test instructions, save details and Android preparation. |
| `docs/GAME_DESIGN.md` | Design pillars, echo rules, world direction, planned mechanics, art/audio guidance and monetization guardrails. |
| `docs/ROADMAP.md` | Multi-milestone plan; checklist status should reflect real implementation, not intentions. |
| `docs/BUILD_STATUS.md` | Current status and outstanding work; keep consistent with this file. |
| `CONTRIBUTING.md`, `LICENSE` | Contribution rules and MIT license. |

### Current architectural boundaries
- The main scene is intentionally small; most gameplay is currently authored in one `Control` script.
- Echo tracks are pure movement data and must remain non-executable if online sharing is ever added.
- Level data is separated from presentation/controller code, but the level schema and renderer are not yet fully data-driven.
- Progress persistence is separate from gameplay, which is a useful seam for future migration.
- No network service, cloud save, analytics, ads, account system, or online route upload is implemented.

## 4. Exact source line map — `scripts/game.gd`

This function index is line-accurate for source blob SHA `3f0ae4c4d61b09e26fd62050540fa999695100d0` (764 lines). Regenerate after any later edit to this script.

- **L1–L4:** Script header and note that artwork is currently procedural.
- **L6:** `ScreenState` enum: MENU, PLAYING, PAUSED, COMPLETE.
- **L8–L21:** Playfield bounds, movement and recording constants, preloaded scripts/data.
- **L23–L44:** Campaign and runtime puzzle state: player/echo positions, tracks, timers, gate/hazard, status and stars.
- **L46–L49:** Virtual joystick touch/mouse state.
- **L51–L67:** Dynamic UI roots, labels, buttons and chapter-button array.
- **L70–L74 — _notification():** Handle application suspension/focus loss and delegate to lifecycle pause.
- **L77–L87 — _pause_for_lifecycle():** Pause active play; clear joystick input, preserve recording state, and refresh the HUD.
- **L90–L97 — _ready():** Initialize stars, load saved progress, build UI and show the menu.
- **L100–L122 — _process():** Update movement, clamp/sample recording time, advance echoes/hazards, check collisions/puzzle state, and refresh rendering.
- **L125–L155 — _input():** Translate touch/mouse events into virtual joystick input.
- **L158–L159 — _is_joystick_area():** Choose where a touch can start a joystick.
- **L162–L164 — _update_joystick():** Convert pointer offset into a normalized joystick vector.
- **L167–L171 — _create_stars():** Generate deterministic decorative background stars.
- **L174–L179 — _build_interface():** Build the menu, HUD, completion, help, and chapter panels.
- **L182–L202 — _build_menu():** Create title, continue, chapter-select, help, and progress UI.
- **L205–L224 — _build_game_hud():** Create level labels, pause, record, restart, menu and controls UI.
- **L227–L239 — _build_complete_panel():** Create completion message and next/replay buttons.
- **L242–L249 — _build_help_panel():** Build the instructions panel.
- **L252–L280 — _build_level_select_panel():** Create a scrollable chapter list and fixed Back button.
- **L283–L297 — _make_panel():** Shared panel styling.
- **L300–L312 — _make_label():** Shared label typography and placement.
- **L315–L343 — _make_button():** Shared button style and colors.
- **L346–L358 — _show_menu():** Return to menu and clear transient recording/input state.
- **L361–L362 — _on_start_pressed():** Continue at the unlocked chamber.
- **L365–L393 — _start_level():** Initialize room state and show the gameplay HUD.
- **L396–L412 — _on_record_pressed():** Start route recording or attempt to stop/send it.
- **L415–L440 — _finish_recording():** Enforce minimum duration and Switch A endpoint before releasing the echo.
- **L443–L444 — _add_record_sample():** Append a time/position pair to the route track.
- **L447–L457 — _update_player():** Apply movement, clamp to room bounds and block a closed gate.
- **L460–L472 — _update_echo():** Advance echo playback, hold its endpoint temporarily, then fade.
- **L475–L482 — _check_sentinel_collision():** Reset the player to spawn and show sentinel-contact feedback.
- **L485–L504 — _check_puzzle_state():** Evaluate switches, open the gate and detect portal completion.
- **L507–L527 — _complete_level():** Increment completion, unlock progress, save and show the completion panel.
- **L530–L534 — _on_next_level_pressed():** Advance to the next chamber or restart the campaign.
- **L537–L538 — _on_replay_pressed():** Restart the current chamber.
- **L541–L542 — _on_reset_pressed():** Restart the current chamber.
- **L545–L558 — _on_pause_pressed():** Toggle pause/resume and clear stale input.
- **L561–L562 — _open_help():** Show instructions.
- **L565–L567 — _open_level_select():** Refresh chapter labels and show chapter selection.
- **L570–L572 — _on_chapter_selected():** Start a chamber only when it is unlocked.
- **L575–L580 — _update_chapter_buttons():** Update chapter labels and locked/unlocked state.
- **L583–L588 — _update_menu_progress():** Refresh campaign progress and continue label.
- **L591–L612 — _update_hud():** Update chamber title, status, echo timer and record button.
- **L615–L618 — _load_progress():** Load local campaign progress.
- **L621–L624 — _save_progress():** Persist progress and warn on failure.
- **L627–L636 — _draw():** Draw the background and select menu/room/paused render path.
- **L639–L645 — _draw_menu_art():** Draw menu decorations and procedural robots.
- **L648–L698 — _draw_room():** Draw the room, switches, gate, portal, hazards, recording preview, echo trail, actors and joystick.
- **L701–L709 — _draw_switch():** Draw a pressure switch and its state.
- **L712–L722 — _draw_gate():** Draw open/closed gate art.
- **L725–L731 — _draw_portal():** Draw the powered/unpowered exit portal.
- **L734–L744 — _draw_robot():** Draw a procedural player or echo robot.
- **L747–L753 — _draw_joystick():** Draw the touch joystick.
- **L756–L762 — _draw_track_path():** Draw a sampled route in a given tint/width; shared by the recording preview and echo trail.
## 5. Exact line map — supporting scripts and tests

### `scripts/core/echo_track.gd` (60 lines, blob SHA `9a433129a0cb8b04d9ab55c0964aeb4683ddab3a`)
- **L1–L5:** `RefCounted` script header, purpose/comment about avoiding global `class_name` cache, and array of dictionaries shaped like `{"t": timestamp, "p": Vector2}`.
- **L8–L9:** Clear all recorded samples.
- **L12–L16:** Append sample; time is nonnegative and never earlier than the previous sample.
- **L19–L25:** Copy route using `get_script().new()` and append duplicate sample dictionaries; this is the specific Godot 4.4 self-reference fix.
- **L28–L31:** Route duration from the final timestamp; empty route is zero seconds.
- **L34–L59:** Position lookup: handles empty/before-first/after-last times, walks consecutive samples, linearly interpolates between points and handles tiny/duplicate timestamp spans.

### `scripts/data/level_catalog.gd` (164 lines, blob SHA `1ae64585cece1f4316716a5213ca8b9c2d174123`)
- **L1–L3:** RefCounted data script and purpose.
- **L4–L89:** Six room dictionaries; entries are The First Echo (L5–L18), Long Memory (L19–L32), Split Signal (L33–L46), Fractured Lane (L47–L60), Crosscurrent (L61–L74), and Static Bloom (L75–L89).
- **L91–L92:** Clamped copy accessor.
- **L94–L95:** Campaign level count.
- **L98–L128:** Schema/bounds validator including required hazard fields.

### `scripts/data/progress_store.gd` (25 lines, blob SHA `cf3e1c4c830638b0ee3232ee6d56cf51574b680d`)
- **L1–L5:** RefCounted save boundary, `user://echopost_save.cfg`, save schema version 1.
- **L8–L16:** Load/default/clamp behavior; unknown future save versions are not read into current state.
- **L19–L24:** Write save version and campaign unlock/completion count via ConfigFile.

### `tests/headless_smoke.gd` (111 lines, blob SHA `5d1bd092f50a22176eb173ae3dc6d6f265be7f86`)
- **L1–L8:** Test harness, preloaded echo/level/save scripts, separate test save path.
- **L13–L22:** Run data tests and return nonzero if any assertions fail.
- **L25–L44:** Echo track creation, timestamp monotonicity, interpolation/endpoint hold, preloaded script identity and copy independence.
- **L47–L66:** Require six uniquely named rooms, run the catalog validator, check required fields/positions/positive linger and verify level reads return isolated copies.
- **L69–L83:** Pass malformed draft room data to the validator and check duplicate names, short spawn route, overlapping switches and negative sentinel speed are reported.
- **L86–L90:** Shared validator-error fragment helper.
- **L94–L104:** Save/load, unlock clamping and test-file cleanup.
- **L107–L110:** Shared assertion helper.
- **L82–L85:** Shared assertion helper.

### `tests/game_flow_smoke.gd` (227 lines, blob SHA `a6e17f2ab3daecded0e6b5d5c1dfa78d96f8232d`)
- **L1–L9:** Test harness, main scene, preloaded echo-track and level-catalog scripts.
- **L12–L13:** Defer the asynchronous integration runner.
- **L16–L74:** Create the game, test chapter-select layout, then exercise lifecycle pause, 8-second recording cap, too-short feedback, sentinel reset, reset cleanup, portal completion/idempotency, invalid route rejection, accepted echo creation and gate activation.
- **L78–L93:** Lifecycle pause preserves recording data, clears joystick input and requires explicit resume.
- **L96–L111:** Recording caps at eight seconds and emits an exactly 8.0-second route.
- **L114–L125:** Too-short feedback preserves the active recording and creates no echo.
- **L128–L136:** Sentinel contact returns player to spawn and displays feedback.
- **L139–L176:** Reset while route/echo state is populated; confirm timers/tracks/gate/input clear and reset works from pause.
- **L179–L202:** Complete at portal, confirm completion UI and exactly one completion count, then restore previously saved campaign values.
- **L205–L220:** Confirm scrollable chapter selector, vertical auto-scroll, and one row per campaign level.
- **L223–L226:** Shared assertion helper.

### `scenes/main.tscn` (13 lines)
- **L1–L3:** Scene declaration and script external resource.
- **L5–L13:** Full-rect Control root attached to `res://scripts/game.gd`.

### `project.godot` (43 lines)
- **L1–L10:** Config version, application metadata, SVG icon, startup scene and feature/renderer declaration.
- **L12–L18:** 1280×720 viewport/window dimensions, canvas-item stretch and orientation configuration.
- **L20–L24:** Compatibility renderer and background color.
- **L26–L43:** Default left/right/up/down input map with WASD and arrow keys.

### `.github/workflows/godot-checks.yml` (38 lines)
- **L1–L19:** Workflow triggers, read-only permissions, Ubuntu runner and two-version Godot matrix.
- **L21–L29:** Checkout and Godot installer.
- **L30–L38:** Headless editor import/parse then data and gameplay smoke tests.

### `RUN_TESTS.bat` (25 lines)
- **L1–L10:** Detect Godot on PATH and explain missing dependency.
- **L12–L20:** Run both smoke tests and return success if they pass.
- **L21–L25:** Failure handling and nonzero exit.

## 6. Current verification status — be precise

- **Six-room content and scrollable chapter-selector verification:** [Godot checks run 42](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40389230677) passed on both Godot 4.4.0 and 4.7.2. This includes the six-room catalog, scrollable selector, data tests, and gameplay integration suite.
- **Room-validator hardening:** [run 49](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40389764965) passed on both versions with negative-draft tests for duplicate names, short spawn-to-A route, close switches and invalid sentinel speed. `tests/headless_smoke.gd:L47–L90` covers the catalog and malformed drafts.
- **Chapter selector verification:** `scripts/game.gd:L252–L280` builds the `ScrollContainer`/`VBoxContainer`; `tests/game_flow_smoke.gd:L205–L220` verifies scrolling and row count.
- **Live route preview:** [run 34](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40388600546) passed after the live amber recording trace and reusable draw helper were added. The visual layout still needs manual inspection in the editor/on a device.
- **Recording/core regression coverage:** strict 8-second cap, too-short recording feedback, sentinel reset, reset cleanup, portal completion idempotency with save restoration, EchoTrack copy behavior, invalid endpoint rejection, accepted echo creation, gate activation and lifecycle pause.
- **Local device test:** not performed by this assistant. Do not imply the game was launched in the user's Godot editor or on a physical phone.
- **Android APK/export:** no APK has been built or attached. Android export preset, signing, package identity, export templates/SDK/JDK and real-device checks remain.
- **Runtime quality:** automated smoke tests are not a substitute for manually playing all three rooms at actual mobile resolution.


### Commands to run in the repository root on Windows
```powershell
git pull origin main
RUN_TESTS.bat
```

With Godot on PATH, the individual commands are:
```powershell
godot --headless --editor --path . --quit
godot --headless --path . --script res://tests/headless_smoke.gd
godot --headless --path . --script res://tests/game_flow_smoke.gd
```

## 7. Known issues, risks and limitations

1. **Mobile sizing / safe areas:** most layout coordinates and drawing coordinates are hard-coded around 1280×720. Safe areas, short/tall screens, scaling and button reach are not validated.
2. **Controller size:** `scripts/game.gd` owns UI construction, gameplay state, input, persistence coordination and drawing. Refactor only incrementally; add tests first so game behavior does not regress.
3. **Small content set:** six room dictionaries now exist, but the core two-switch pattern is reused and there is no full campaign or final narrative ending.
4. **Procedural placeholder visuals:** no authored robot animations, environmental tilesets, VFX or transition animations.
5. **No sound:** recording, rejected route, sentinel hits, gate opening and portal have text/visual feedback only. No SFX, music, mixer, or audio options exist.
6. **Pause behavior needs real device QA:** the lifecycle logic is headlessly tested but actual Android app-switch lifecycle and focus behavior are unverified. The player must tap RESUME after returning.
7. **Mechanic coverage:** one recording slot, one hold-style Switch A/Switch B puzzle pattern, a single gate and hardcoded portal position. Timed/toggle/sequence switches, moving platforms and checkpoints are ideas only.
8. **Recording edge cases:** the minimum is now `MIN_RECORD_SECONDS = 0.7` at `scripts/game.gd:L16`; a too-short stop deliberately keeps recording active and tells the player to continue. Verify that this interaction is understandable on touch.
9. **Hazard edge cases:** sentinel collision resets the real player's position. Verify whether the echo and an active recording should remain unchanged on collision; decide and add tests before redesigning behavior.
10. **Save migration:** save schema is version 1 and locally stored only. No migration tests for future versions or cloud save exist.
11. **Level validation:** catches schema/name/position/spacing and sentinel tuning errors, but it is not a pathfinding solver and does not prove portal reachability or fairness against the sentinel's phase.
12. **No online features or monetization:** no accounts, backend, community route uploads, cloud saves, ads, analytics or payments are implemented. Do not add these before offline puzzle quality, privacy and moderation are planned.

## 8. Prioritized next steps

### P0 — Keep the project compiling and the handoff current
- [x] Fix Godot 4.4 `Identifier not found: EchoTrack` self-reference in `scripts/core/echo_track.gd:L19–L25`.
- [x] Add a regression assertion for preloaded script identity at `tests/headless_smoke.gd:L39–L44`.
- [x] Verify the code fix and regression test in [run 21](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40385871675): Godot 4.4.0 and 4.7.2 both passed.
- [x] Verify restart cleanup and portal completion in run 33; verify live route-preview parsing in run 34; verify six-room content and scrollable chapter UI in run 42 on both Godot versions.
- [ ] Ask for / perform a local pull and open the project in the user's Godot 4.4 editor to inspect the live route preview and confirm visuals on the actual machine.
- [ ] Every further code change must update this progress file and refresh affected line maps.

### P1 — Core mechanic test coverage
- [x] Add an integration test for automatic recording stop and verify the echo route is exactly 8.0 seconds.
- [x] Test the too-short recording interaction: no echo is created, recording remains active, and the message says to keep recording.
- [x] Test sentinel contact resets the player to the room spawn and displays feedback.
- [ ] Decide whether sentinel contact should clear an active recording/echo, then test the chosen behavior.
- [x] Test restart while recording and echo playback are active, and verify restart from PAUSED clears state.
- [x] Test powered portal completion and ensure the completion count increments exactly once while the test restores the original save values.
- [ ] Test lifecycle focus-out as well as application-paused notification; physical mobile app switching still needs manual QA.
- [x] Expand the level validator for names, spawn-to-A distance, switch separation and sentinel tuning; keep adding solvability/fairness validation as room mechanics grow.

### P2 — Mobile usability before adding lots of content
- [ ] Manually inspect scrollable chapter selection and the live route preview on the user's Godot editor/phone; then review narrow/tall aspect ratios, safe areas and landscape touch reach.
- [ ] Add settings/accessibility pass: left-handed controls, speed/sensitivity, color-independent active-state cues, reduced motion and audio controls.
- [ ] Add visible route-preview quality and better feedback for rejected/too-short routes.
- [ ] Manually play all rooms in Godot desktop and test exported debug builds on at least one real Android device.

### P3 — Build a real campaign / refactor safely
- [ ] Create a reusable room scene/controller separation and richer authored-room schema.
- [ ] Expand from six layouts to 12–20 authored chambers with new puzzle mechanics rather than only changing positions and patrol timing.
- [ ] Add checkpoint/lore fragments and a cohesive Act I ending.
- [ ] Replace procedural placeholder art with original coherent art/audio, while keeping clarity and low-cost rendering on mobile.

### P4 — Export and release preparation
- [ ] Configure unique Android package ID, app version, icons, export preset, signing and privacy disclosures.
- [ ] Build a debug APK, install it and verify lifecycle/controls/saves on a real device.
- [ ] Run release QA and closed beta before public distribution.
- [ ] Only later design online sharing with route bounds validation, upload limits, moderation/reporting, privacy and backend cost controls.

## 9. Rules for the next development session

1. Start by reading this file, `README.md`, `docs/ROADMAP.md`, `docs/BUILD_STATUS.md`, and the most relevant source/tests. Inspect the current GitHub `main` tip; do not blindly assume this documented snapshot is still newest.
2. Check the most recent CI run before modifying code. A workflow run for a commit older than the code currently on `main` does not verify the current code.
3. Choose **one focused improvement** at a time. Make changes in `main` only as permitted by the user/project workflow, and don't claim the project is finished.
4. Test changes with Godot CI or available local Godot. Distinguish passed tests, tests not run, and manual device checks.
5. Refresh every affected line number after changes. The line map in section 4 is keyed to `scripts/game.gd` blob SHA `3f0ae4c4d61b09e26fd62050540fa999695100d0`; section 5 records current supporting-script and test blob SHAs. If any of those blob SHAs differ after edits, regenerate the corresponding section.
6. Update `PROJECT_PROGRESS.md` in the same development pass as source changes. Record the new commit(s), source hashes/line references, CI URL/result and what the next session should do.
7. Keep this game offline-capable and dependency-light. Never add network accounts, telemetry, uploads, payment or ads as an incidental code change.
8. Don't produce an APK/release claim unless an actual export and install verification were completed.

---

*Handoff note: this file is written to make future work resumable from concrete repository state, not to declare completion. The next session's first action should be checking the newest workflow run, then continue with P1 test coverage before beginning larger gameplay/content changes.*
