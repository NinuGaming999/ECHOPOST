# ECHOPOST — PROJECT PROGRESS / HANDOFF

> **This file is the continuity record for future ECHOPOST development.** Read it before changing code. The game is deliberately an unfinished long-running project; do not treat the current three-room prototype as complete. After every meaningful code, test, gameplay, or build change, update this file with what changed, why, exact file/line references, current verification results, and the next actionable tasks.

**Repository:** https://github.com/NinuGaming999/ECHOPOST  
**Working branch:** `main`  
**Project root:** repository root; main scene is `res://scenes/main.tscn`  
**Engine:** Godot 4.x; CI tests Godot 4.4.0 and 4.7.2  
**Target:** Android-first landscape game; desktop builds support development and testing  
**Recording-cap code commit:** `b5f36b6a4f764a595e5dd930e8d6b3cebd5ce3a8`  
**Gameplay-test commit:** `11c3b30de34323c536b0b8302eb8604259248d52`  
**Main controller source blob for the exact line map below:** `6a34625754b63f4576cea80ff9e397062176cb85` (745 lines)  
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

The current source includes three chamber definitions:
- **The First Echo:** basic teach-the-mechanic chamber.
- **Long Memory:** roaming sentinel and a more distant, differently placed Switch B.
- **Split Signal:** faster/larger sentinel movement and more separated switch positions.

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

- `scripts/game.gd:L653–L659`: while `is_recording`, the route draws in amber with a ring and START marker at the first sample. This makes the recorded path visible before the echo is sent.
- `scripts/game.gd:L661–L662`: the echo playback trail uses the same helper but remains cyan, distinguishing a saved/replaying echo from the live recording.
- `scripts/game.gd:L737–L743`: new `_draw_track_path(track, tint, line_width)` helper draws the samples; rendering only reads route data and does not change gameplay.
- [Godot CI run 34](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40388600546) passed on Godot 4.4.0 and 4.7.2 after adding the shared renderer helper. Visual quality still needs a manual editor/device check.
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
| `scripts/data/level_catalog.gd` | Three authored level dictionaries plus defensive copy accessor and campaign-data validator. |
| `scripts/data/progress_store.gd` | Versioned local save boundary (`user://echopost_save.cfg`) using `ConfigFile`; defaults safely when save is absent/unreadable and clamps unlocked level to campaign size. |
| `tests/headless_smoke.gd` | Data-layer smoke tests for track order/interpolation/copying, level catalog validation/defensive copying, save/load and unlock clamping. |
| `tests/game_flow_smoke.gd` | Main-scene integration tests for lifecycle pause, recording cap/feedback, sentinel reset, reset cleanup, portal-completion idempotency, invalid endpoint rejection, valid echo creation, and gate activation. |
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

This function index is line-accurate for source blob SHA `6a34625754b63f4576cea80ff9e397062176cb85` (745 lines). Regenerate it whenever this file changes.

- **L1–L4:** Script header and note that artwork is procedural.
- **L6:** `ScreenState` enum: MENU, PLAYING, PAUSED, COMPLETE.
- **L8–L21:** Room bounds, player/movement constants, minimum/maximum recording duration and preloaded resources.
- **L23–L44:** Campaign and runtime state: player/echo, route tracks, recording timers, gate/hazard, status and stars.
- **L46–L49:** Touch/mouse joystick state.
- **L51–L67:** Dynamic UI roots, labels, buttons and chapter button array.
- **L70–L74 — _notification():** Handle application suspension/focus loss and delegate to lifecycle pause.
- **L77–L87 — _pause_for_lifecycle():** Pause only active play; clear joystick input, preserve recording state, and refresh the HUD.
- **L90–L97 — _ready():** Initialize stars, saved progress, UI, and the initial menu.
- **L100–L122 — _process():** Update movement, clamp and sample recording time, advance echo/hazard state, check collisions/puzzle state, and refresh the HUD.
- **L125–L155 — _input():** Map touch/mouse events to the virtual joystick.
- **L158–L159 — _is_joystick_area():** Choose where touch can start a joystick.
- **L162–L164 — _update_joystick():** Convert pointer offset into a normalized joystick vector.
- **L167–L171 — _create_stars():** Generate deterministic decorative stars.
- **L174–L179 — _build_interface():** Build menu, HUD, completion, help, and chapter-selection panels.
- **L182–L202 — _build_menu():** Create the title, continue, chapter-select, help, and progress UI.
- **L205–L224 — _build_game_hud():** Create level labels, pause, recording, restart, menu, and control-help UI.
- **L227–L239 — _build_complete_panel():** Create completion text and next/replay buttons.
- **L242–L249 — _build_help_panel():** Build instructions for recording and solving a chamber.
- **L252–L261 — _build_level_select_panel():** Create locked/unlocked chamber buttons and back navigation.
- **L264–L278 — _make_panel():** Shared panel styling.
- **L281–L293 — _make_label():** Shared label typography and placement.
- **L296–L324 — _make_button():** Shared button style, hover state, and colors.
- **L327–L339 — _show_menu():** Return to the menu and clear transient recording/input state.
- **L342–L343 — _on_start_pressed():** Continue at the currently unlocked chamber.
- **L346–L374 — _start_level():** Initialize room state and show gameplay UI.
- **L377–L393 — _on_record_pressed():** Start recording or attempt to stop and send a route.
- **L396–L421 — _finish_recording():** Enforce minimum duration and Switch A endpoint before releasing the echo.
- **L424–L425 — _add_record_sample():** Append a timestamped position to the current route.
- **L428–L438 — _update_player():** Apply keyboard/joystick movement, enforce bounds, and block a closed gate.
- **L441–L453 — _update_echo():** Advance timed echo playback, then linger and fade.
- **L456–L463 — _check_sentinel_collision():** Reset the player to spawn and show feedback on sentinel contact.
- **L466–L485 — _check_puzzle_state():** Evaluate switches, open the gate, and trigger portal completion.
- **L488–L508 — _complete_level():** Increment completion, unlock progress, save, and show completion UI.
- **L511–L515 — _on_next_level_pressed():** Advance to the next chamber or restart the campaign.
- **L518–L519 — _on_replay_pressed():** Restart the current chamber.
- **L522–L523 — _on_reset_pressed():** Restart the current chamber.
- **L526–L539 — _on_pause_pressed():** Toggle pause/resume and clear stale joystick input.
- **L542–L543 — _open_help():** Show the help panel.
- **L546–L548 — _open_level_select():** Refresh chapter buttons and open chapter select.
- **L551–L553 — _on_chapter_selected():** Start a chamber only if it is unlocked.
- **L556–L561 — _update_chapter_buttons():** Apply locked/unlocked chapter text and disabled state.
- **L564–L569 — _update_menu_progress():** Refresh campaign progress and continue-button label.
- **L572–L593 — _update_hud():** Refresh level title, status, echo timer, and recording control state.
- **L596–L599 — _load_progress():** Load local campaign progress through ProgressStore.
- **L602–L605 — _save_progress():** Persist campaign progress and warn on write failure.
- **L608–L617 — _draw():** Draw background and choose menu/room/paused rendering.
- **L620–L626 — _draw_menu_art():** Draw menu decorations and procedural robots.
- **L629–L679 — _draw_room():** Draw playfield, switches, gate, portal, hazard, live route preview, echo trail, echo, player and joystick.
- **L682–L690 — _draw_switch():** Draw a pressure switch and its state.
- **L693–L703 — _draw_gate():** Draw the open or closed gate.
- **L706–L712 — _draw_portal():** Draw the exit's powered/unpowered state.
- **L715–L725 — _draw_robot():** Draw the procedural player or ghost robot.
- **L728–L734 — _draw_joystick():** Draw the active virtual joystick.
- **L737–L743 — _draw_track_path():** Render a sampled route using a tint and width; shared by live and echo trails.
## 5. Exact line map — supporting scripts and tests

### `scripts/core/echo_track.gd` (60 lines, blob SHA `9a433129a0cb8b04d9ab55c0964aeb4683ddab3a`)
- **L1–L5:** `RefCounted` script header, purpose/comment about avoiding global `class_name` cache, and array of dictionaries shaped like `{"t": timestamp, "p": Vector2}`.
- **L8–L9:** Clear all recorded samples.
- **L12–L16:** Append sample; time is nonnegative and never earlier than the previous sample.
- **L19–L25:** Copy route using `get_script().new()` and append duplicate sample dictionaries; this is the specific Godot 4.4 self-reference fix.
- **L28–L31:** Route duration from the final timestamp; empty route is zero seconds.
- **L34–L59:** Position lookup: handles empty/before-first/after-last times, walks consecutive samples, linearly interpolates between points and handles tiny/duplicate timestamp spans.

### `scripts/data/level_catalog.gd` (87 lines, blob SHA `b9d35ba7feda149debddb3f31fb728fc319d9069`)
- **L1–L3:** RefCounted data holder and its purpose.
- **L4–L47:** Three level dictionaries. Required practical fields include `name`, `subtitle`, `hint`, `spawn`, `plate_a`, `plate_b`, `linger`, `hazard`, `hazard_y`, `hazard_amplitude`, `hazard_speed`, `accent`.
- **L49–L50:** Safe/clamped index accessor returning a duplicate dictionary.
- **L52–L53:** Level count helper.
- **L56–L86:** Validator: nonempty campaign; required keys; Vector2 types for spawn/switches; positive linger; key positions constrained to playfield; required hazard keys for hazard rooms. It does **not yet** validate every tuning range or all render-specific assumptions.

### `scripts/data/progress_store.gd` (25 lines, blob SHA `cf3e1c4c830638b0ee3232ee6d56cf51574b680d`)
- **L1–L5:** RefCounted save boundary, `user://echopost_save.cfg`, save schema version 1.
- **L8–L16:** Load/default/clamp behavior; unknown future save versions are not read into current state.
- **L19–L24:** Write save version and campaign unlock/completion count via ConfigFile.

### `tests/headless_smoke.gd` (80 lines, blob SHA `ba642740ee18a93b5f45b7d3283f1c352615e1bc`)
- **L1–L8:** Test harness and preloads; EchoTrack is intentionally loaded as a script resource, not a global class; temp save path is separate from the real campaign save.
- **L13–L22:** Run tests and exit nonzero if any assertion fails.
- **L25–L37:** Timestamp ordering, duration, interpolation and endpoint holding.
- **L39–L44:** Regression coverage for copy script identity, copy independence, and interpolation after adding a sample to the copy.
- **L47–L60:** Campaign count/schema validation, required data, Vector2 spawn, and defensive-copy behavior.
- **L63–L73:** Save/load values, clamping to a smaller campaign and removal of temp save.
- **L76–L80:** Shared assertion helper.

### `tests/game_flow_smoke.gd` (206 lines, blob SHA `466bb3af7408f7f235ce45cfa5aaeea18dbab7f2`)
- **L1–L8:** Test harness, main scene preload and preloaded echo-track script.
- **L11–L12:** Defer the asynchronous integration test runner.
- **L15–L72:** Instantiate the main scene; run lifecycle, maximum-duration, too-short, sentinel, restart-cleanup and portal-idempotency tests; then test invalid route rejection, valid echo creation, and two-switch gate activation.
- **L76–L91:** Application pause, preserved recording time, cleared joystick input, explicit resume.
- **L94–L109:** Automatic recording stop at eight seconds and exact 8.0-second echo duration.
- **L112–L123:** Too-short feedback and preservation of the active recording.
- **L126–L134:** Sentinel contact returns player to spawn and displays feedback.
- **L137–L174:** Restart clears recording/echo tracks and timers, closes gate, clears joystick; restart from PAUSED also returns to PLAYING.
- **L177–L200:** Complete a chamber through the portal, verify completion panel and one count only, then restore previous saved progress.
- **L202–L205:** Shared assertion helper.
- **Remaining gap:** Lifecycle focus-out needs physical device QA; save-write failure and final-campaign edge cases need more targeted coverage.
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

- **Restart and portal completion verification:** [Godot checks run 33](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40388464089) passed on both Godot 4.4.0 and 4.7.2, including restart cleanup and portal-completion idempotency at `tests/game_flow_smoke.gd:L137–L200`.
- **Live route-preview verification:** [Godot checks run 34](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40388600546) passed both Godot versions after `scripts/game.gd:L653–L662` and `L737–L743` added the live preview and shared path helper. The visual quality still requires manual inspection in the editor/on a device.
- **Recording cap verification:** `scripts/game.gd:L100–L122` clamps elapsed recording time before sampling; `tests/game_flow_smoke.gd:L94–L109` verifies the echo duration equals 8.0 seconds.
- **Other gameplay regressions:** too-short feedback, sentinel reset, EchoTrack copy behavior, invalid endpoint rejection, valid echo creation, gate activation, and lifecycle pause all remain covered.
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
3. **Small content set:** only three room dictionaries exist. There is no full campaign or final narrative ending.
4. **Procedural placeholder visuals:** no authored robot animations, environmental tilesets, VFX or transition animations.
5. **No sound:** recording, rejected route, sentinel hits, gate opening and portal have text/visual feedback only. No SFX, music, mixer, or audio options exist.
6. **Pause behavior needs real device QA:** the lifecycle logic is headlessly tested but actual Android app-switch lifecycle and focus behavior are unverified. The player must tap RESUME after returning.
7. **Mechanic coverage:** one recording slot, one hold-style Switch A/Switch B puzzle pattern, a single gate and hardcoded portal position. Timed/toggle/sequence switches, moving platforms and checkpoints are ideas only.
8. **Recording edge cases:** the minimum is now `MIN_RECORD_SECONDS = 0.7` at `scripts/game.gd:L16`; a too-short stop deliberately keeps recording active and tells the player to continue. Verify that this interaction is understandable on touch.
9. **Hazard edge cases:** sentinel collision resets the real player's position. Verify whether the echo and an active recording should remain unchanged on collision; decide and add tests before redesigning behavior.
10. **Save migration:** save schema is version 1 and locally stored only. No migration tests for future versions or cloud save exist.
11. **Level validation:** checks core required fields and basic bounds, but does not yet enforce all hazard ranges, layout spacing, switch/gate collision assumptions, or portal reachability.
12. **No online features or monetization:** no accounts, backend, community route uploads, cloud saves, ads, analytics or payments are implemented. Do not add these before offline puzzle quality, privacy and moderation are planned.

## 8. Prioritized next steps

### P0 — Keep the project compiling and the handoff current
- [x] Fix Godot 4.4 `Identifier not found: EchoTrack` self-reference in `scripts/core/echo_track.gd:L19–L25`.
- [x] Add a regression assertion for preloaded script identity at `tests/headless_smoke.gd:L39–L44`.
- [x] Verify the code fix and regression test in [run 21](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40385871675): Godot 4.4.0 and 4.7.2 both passed.
- [x] Verify restart cleanup and portal-completion idempotency in run 33; verify live route-preview parsing and all smoke tests in run 34 on Godot 4.4.0 and 4.7.2.
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
- [ ] Expand level validator for hazard tuning, non-overlapping/usable positions and portal/gate assumptions.

### P2 — Mobile usability before adding lots of content
- [ ] Review and redesign layout for narrow and tall aspect ratios, safe areas and landscape touch reach.
- [ ] Add settings/accessibility pass: left-handed controls, speed/sensitivity, color-independent active-state cues, reduced motion and audio controls.
- [ ] Add visible route-preview quality and better feedback for rejected/too-short routes.
- [ ] Manually play all rooms in Godot desktop and test exported debug builds on at least one real Android device.

### P3 — Build a real campaign / refactor safely
- [ ] Create a reusable room data format and, later, a reusable room scene/controller separation.
- [ ] Plan 12–20 authored chambers with a mechanic progression rather than repeating the same puzzle with only changed positions.
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
5. Refresh every affected line number after changes. The line map in section 4 is keyed to `scripts/game.gd` blob SHA `6a34625754b63f4576cea80ff9e397062176cb85`; section 5 records current supporting-script and test blob SHAs. If any of those blob SHAs differ after edits, regenerate the corresponding section.
6. Update `PROJECT_PROGRESS.md` in the same development pass as source changes. Record the new commit(s), source hashes/line references, CI URL/result and what the next session should do.
7. Keep this game offline-capable and dependency-light. Never add network accounts, telemetry, uploads, payment or ads as an incidental code change.
8. Don't produce an APK/release claim unless an actual export and install verification were completed.

---

*Handoff note: this file is written to make future work resumable from concrete repository state, not to declare completion. The next session's first action should be checking the newest workflow run, then continue with P1 test coverage before beginning larger gameplay/content changes.*
