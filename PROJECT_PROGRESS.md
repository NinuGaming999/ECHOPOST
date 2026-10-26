# ECHOPOST — PROJECT PROGRESS / HANDOFF

> **This file is the continuity record for future ECHOPOST development.** Read it before changing code. The game is deliberately an unfinished long-running project; do not treat the current three-room prototype as complete. After every meaningful code, test, gameplay, or build change, update this file with what changed, why, exact file/line references, current verification results, and the next actionable tasks.

**Repository:** https://github.com/NinuGaming999/ECHOPOST  
**Working branch:** `main`  
**Project root:** repository root; main scene is `res://scenes/main.tscn`  
**Engine:** Godot 4.x; CI tests Godot 4.4.0 and 4.7.2  
**Target:** Android-first landscape game; desktop builds support development and testing  
**Progress snapshot base commit:** `6cbfb8f61da84ab6b5c627ef7fc65207939964ad` (the progress file itself is added immediately after this snapshot)  
**Main controller source blob for the exact line map below:** `5fa29fa19f67c542a601a51df39636ef86bab7cc` (728 lines)  
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
- `scripts/game.gd:L17–L20` and `L34–L39`: already uses the `ECHO_TRACK_SCRIPT = preload(...)` resource and so required no modification. Its previous `Nil.clear()` errors were downstream symptoms, not separate root causes.
- `tests/headless_smoke.gd:L39–L44`: added a regression check that a copied track's script is exactly the preloaded resource, as well as retaining copy independence/interpolation tests.
- Code fix commit: `5179b423d0d00d4a2ee807bc9d621d376b04b49a`.
- Regression-test commit: `3a02e78abafe8c5cd1bb923e2e00b644b5a9c3f7`.
- [Godot CI run 21](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40385871675) passed on Godot 4.4.0 and 4.7.2, including the new regression assertion.

### Mobile lifecycle pause hardening
**Changed:** `scripts/game.gd` and `tests/game_flow_smoke.gd`.

- `scripts/game.gd:L69–L73`: new `_notification(what)` handler listens for `NOTIFICATION_APPLICATION_PAUSED` (Android/iOS backgrounding) and `NOTIFICATION_APPLICATION_FOCUS_OUT`.
- `scripts/game.gd:L76–L86`: `_pause_for_lifecycle()` only pauses when the game was actively playing. It clears touch/mouse joystick state, sets the pause button to **RESUME**, explains the pause to the player, and refreshes rendering/HUD.
- The existing frame loop at `scripts/game.gd:L99–L120` exits early unless the screen state is PLAYING, so recording time, echo time, hazard time, and player movement stop advancing while paused.
- The handler does not erase `recording_track`, set `is_recording` to false, or auto-resume when the application returns. A paused recording can continue after the player explicitly resumes.
- `tests/game_flow_smoke.gd:L23–L24` invokes the lifecycle test and starts a fresh chamber so later tests run from a clean state.
- `tests/game_flow_smoke.gd:L68–L83` simulates application suspension and verifies: state changes to PAUSED; joystick vector is cleared; recording flag/time survive; paused frame processing does not advance recording time; application resume does not bypass the pause screen; manual RESUME restores PLAYING.
- The roadmap and build status were updated in `docs/ROADMAP.md` and `docs/BUILD_STATUS.md`.

This change is covered by an automated headless integration test. It is **not yet a substitute for checking behavior on a real Android device**, including actual app switching and returning from the background.

## 3. Project layout and the job of each file

| Path | Responsibility / current condition |
|---|---|
| `project.godot` | Application name, icon, landscape 1280×720 viewport, canvas-item stretch, compatibility renderer and WASD/arrow input map. |
| `scenes/main.tscn` | Very small main scene: full-rect `Control` attached to `scripts/game.gd`. |
| `scripts/game.gd` | Main controller, menu/HUD construction, player movement, echo recording/playback, puzzle loop, sentinel, save flow, and all procedural rendering. **728 lines in the snapshot documented here; it is the largest refactor target later, but refactor only after tests protect behavior.** |
| `scripts/core/echo_track.gd` | Data-only `RefCounted` script loaded through preloaded script resources; avoids global `class_name` lookup; stores points, clamps timestamps to nondecreasing order, copies tracks, returns duration, interpolates route positions, and holds endpoint outside the timestamp range. |
| `scripts/data/level_catalog.gd` | Three authored level dictionaries plus defensive copy accessor and campaign-data validator. |
| `scripts/data/progress_store.gd` | Versioned local save boundary (`user://echopost_save.cfg`) using `ConfigFile`; defaults safely when save is absent/unreadable and clamps unlocked level to campaign size. |
| `tests/headless_smoke.gd` | Data-layer smoke tests for track order/interpolation/copying, level catalog validation/defensive copying, save/load and unlock clamping. |
| `tests/game_flow_smoke.gd` | Main-scene integration smoke test for invalid route rejection, valid echo creation, gate activation and lifecycle pause/resume. |
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

The following is a **line-accurate index for the controller blob SHA shown at the top of this file**. Use these exact ranges when reading/modifying. Any edit to this file can move later line numbers; always refresh the index and update this handoff when code changes. The function ranges below cover every non-blank controller section; blank separators are intentionally omitted.

- **L1–L4:** Script header, project identity and note about procedural art.
- **L6:** `ScreenState` enum: MENU, PLAYING, PAUSED, COMPLETE.
- **L8–L20:** Room bounds, gate/player/movement/record timing constants and preloads for EchoTrack, LevelCatalog and ProgressStore.
- **L22–L43:** Campaign fields and puzzle runtime state: player/echo position, echo state, track objects, recording accumulators, gate/hazard state, status text, background stars.
- **L45–L48:** Touch/mouse joystick state and direction.
- **L50–L66:** References to dynamic UI roots, labels, buttons, and chapter buttons.
- **L69–L73 — `_notification()`:** Handle application suspension and focus loss; delegate to lifecycle pause.
- **L76–L86 — `_pause_for_lifecycle()`:** Pause only from PLAYING; clear input, keep recording data, update HUD.
- **L89–L96 — `_ready()`:** Initialize drawing stars, saved progress, UI, and initial menu.
- **L99–L120 — `_process()`:** Main frame update: movement, sampling, echo playback, hazards, puzzle state, HUD.
- **L123–L153 — `_input()`:** Map touch and mouse events to virtual joystick interaction.
- **L156–L157 — `_is_joystick_area()`:** Choose where touch can start a joystick.
- **L160–L162 — `_update_joystick()`:** Convert pointer location into a normalized joystick vector.
- **L165–L169 — `_create_stars()`:** Generate deterministic decorative background stars.
- **L172–L177 — `_build_interface()`:** Construct menu, gameplay HUD, completion, help, and chapter panels.
- **L180–L200 — `_build_menu()`:** Create title, continue, chapter-select, help, and progress UI.
- **L203–L222 — `_build_game_hud()`:** Create level labels, pause, record, restart, menu, and control help.
- **L225–L237 — `_build_complete_panel()`:** Create level-complete message and next/replay buttons.
- **L240–L247 — `_build_help_panel()`:** Create instructions for recording and solving a room.
- **L250–L259 — `_build_level_select_panel()`:** Create chapter buttons and navigation back to menu.
- **L262–L276 — `_make_panel()`:** Shared panel styling helper.
- **L279–L291 — `_make_label()`:** Shared label helper and typography defaults.
- **L294–L322 — `_make_button()`:** Shared button styling helper.
- **L325–L337 — `_show_menu()`:** Return to menu and reset transient input/recording state.
- **L340–L341 — `_on_start_pressed()`:** Continue at the currently unlocked chamber.
- **L344–L372 — `_start_level()`:** Initialize level state and show the gameplay HUD.
- **L375–L391 — `_on_record_pressed()`:** Start or stop route recording.
- **L394–L419 — `_finish_recording()`:** Enforce minimum duration and Switch A endpoint; release echo on valid route.
- **L422–L423 — `_add_record_sample()`:** Append a time/position pair to the recording track.
- **L426–L436 — `_update_player()`:** Keyboard + joystick movement, room bounds, and closed-gate blocking.
- **L439–L451 — `_update_echo()`:** Advance echo samples, then let it linger on its endpoint before fading.
- **L454–L461 — `_check_sentinel_collision()`:** Move the player back to spawn when a roaming sentinel hits.
- **L464–L483 — `_check_puzzle_state()`:** Evaluate switch occupancy, open the gate, and trigger portal completion.
- **L486–L506 — `_complete_level()`:** Persist progress and show campaign-completion UI.
- **L509–L513 — `_on_next_level_pressed()`:** Advance to next chamber or replay campaign from chamber one.
- **L516–L517 — `_on_replay_pressed()`:** Restart the current chamber after completion.
- **L520–L521 — `_on_reset_pressed()`:** Restart the current chamber.
- **L524–L537 — `_on_pause_pressed()`:** Toggle manual pause/resume and update input state.
- **L540–L541 — `_open_help()`:** Show instructions panel.
- **L544–L546 — `_open_level_select()`:** Refresh unlock labels and show chapter select.
- **L549–L551 — `_on_chapter_selected()`:** Start only chambers that have been unlocked.
- **L554–L559 — `_update_chapter_buttons()`:** Apply locked/unlocked button states.
- **L562–L567 — `_update_menu_progress()`:** Refresh campaign progress and continue-button text.
- **L570–L591 — `_update_hud()`:** Update level labels, status, echo state, and record button.
- **L594–L597 — `_load_progress()`:** Read persisted campaign progress through ProgressStore.
- **L600–L603 — `_save_progress()`:** Persist progress and warn if the write fails.
- **L606–L615 — `_draw()`:** Draw background and choose menu/room/paused overlay render path.
- **L618–L624 — `_draw_menu_art()`:** Draw menu decorations and robots.
- **L627–L672 — `_draw_room()`:** Draw playfield, switches, gate, portal, hazards, echo path, echo, and player.
- **L675–L683 — `_draw_switch()`:** Draw a pressure switch and its active state.
- **L686–L696 — `_draw_gate()`:** Draw the open or closed gate.
- **L699–L705 — `_draw_portal()`:** Draw the powered/unpowered exit portal.
- **L708–L718 — `_draw_robot()`:** Draw the procedural robot/echo body.
- **L721–L727 — `_draw_joystick()`:** Draw the active touchscreen joystick.

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

### `tests/game_flow_smoke.gd` (89 lines, blob SHA `ca0fb60d0cf8e261170ea60d00f22f60cbe79a57`)
- **L1–L8:** Test harness, main scene and EchoTrack preload.
- **L11–L64:** Instantiate main scene, start a room, run the lifecycle test, reset clean state, test rejection of route ending away from A, test a valid route ending on A, then test gate activation when echo/player occupy A/B.
- **L68–L83:** Lifecycle pause assertions (see section 2).
- **L85–L89:** Shared assertion helper.
- **Known coverage gap:** No automated full-portal completion test yet; recording limit, sentinel collision/reset and repeated pause/restart edge cases still need dedicated assertions.

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

- **Latest completed code + regression-test workflow:** [Godot checks run 21](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40385871675) passed on commit `3a02e78abafe8c5cd1bb923e2e00b644b5a9c3f7`. Both jobs completed successfully: Godot 4.4.0 and Godot 4.7.2. Each job imports/parses the project and runs data-layer and gameplay smoke tests; the new EchoTrack self-reference regression test passed.
- **Previously completed code-fix workflow:** [run 20](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40385850496) also passed on both versions after the EchoTrack implementation was changed and before the extra regression assertion was committed.
- **Lifecycle-pause source/test validation:** still covered by run 21, including `scripts/game.gd:L69–L86` and `tests/game_flow_smoke.gd:L68–L83`.
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
8. **Recording edge cases:** minimum valid recording is 0.65 seconds; a too-short stop currently keeps recording active and explains that the route needs to be longer. Verify that this interaction is understandable on touch.
9. **Hazard edge cases:** sentinel collision resets the real player's position. Verify whether the echo and an active recording should remain unchanged on collision; decide and add tests before redesigning behavior.
10. **Save migration:** save schema is version 1 and locally stored only. No migration tests for future versions or cloud save exist.
11. **Level validation:** checks core required fields and basic bounds, but does not yet enforce all hazard ranges, layout spacing, switch/gate collision assumptions, or portal reachability.
12. **No online features or monetization:** no accounts, backend, community route uploads, cloud saves, ads, analytics or payments are implemented. Do not add these before offline puzzle quality, privacy and moderation are planned.

## 8. Prioritized next steps

### P0 — Keep the project compiling and the handoff current
- [x] Fix Godot 4.4 `Identifier not found: EchoTrack` self-reference in `scripts/core/echo_track.gd:L19–L25`.
- [x] Add a regression assertion for preloaded script identity at `tests/headless_smoke.gd:L39–L44`.
- [x] Verify the code fix and regression test in [run 21](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40385871675): Godot 4.4.0 and 4.7.2 both passed.
- [ ] Ask for / perform a local pull and run the project in the user's Godot 4.4 editor to confirm the same reported error is gone on the actual machine.
- [ ] Every further code change must update this progress file and refresh affected line maps.

### P1 — Core mechanic test coverage
- [ ] Add an integration case for the maximum 8-second recording duration.
- [ ] Add an integration case for the too-short recording interaction.
- [ ] Test sentinel contact and clarify whether it clears recording/echo or only resets player position.
- [ ] Test restart while echo is replaying, while recording, and while paused.
- [ ] Test closing the gate then entering the portal and verify exactly one completion/save event fires.
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
5. Refresh every affected line number after changes. The line map in section 4 is keyed to `scripts/game.gd` blob SHA `5fa29fa19f67c542a601a51df39636ef86bab7cc`; section 5 records current supporting-script and test blob SHAs. If any of those blob SHAs differ after edits, regenerate the corresponding section.
6. Update `PROJECT_PROGRESS.md` in the same development pass as source changes. Record the new commit(s), source hashes/line references, CI URL/result and what the next session should do.
7. Keep this game offline-capable and dependency-light. Never add network accounts, telemetry, uploads, payment or ads as an incidental code change.
8. Don't produce an APK/release claim unless an actual export and install verification were completed.

---

*Handoff note: this file is written to make future work resumable from concrete repository state, not to declare completion. The next session's first action should be checking the newest workflow run, then continue with P1 test coverage before beginning larger gameplay/content changes.*
