# ECHOPOST — PROJECT PROGRESS / HANDOFF

> **This file is the continuity record for future ECHOPOST development.** Read it before changing code. The game is deliberately an unfinished long-running project; do not treat the current six-room prototype as complete. After every meaningful code, test, gameplay, or build change, update this file with what changed, why, exact file/line references, current verification results, and the next actionable tasks.

**Repository:** https://github.com/NinuGaming999/ECHOPOST  
**Working branch:** `main`  
**Project root:** repository root; main scene is `res://scenes/main.tscn`  
**Engine:** Godot 4.x; CI tests Godot 4.4.0 and 4.7.2  
**Target:** Android-first landscape game; desktop builds support development and testing  
**Recording-cap code commit:** `b5f36b6a4f764a595e5dd930e8d6b3cebd5ce3a8`  
**Gameplay-test commit:** `11c3b30de34323c536b0b8302eb8604259248d52`  
**Latest feature/test commits:** game `35136940975cd771faeba1c9321857477dac4d2d`; save store `2b41d14ea8acd86098ddd3fd3c4e4169116b421d`; integration tests `6bc7d5dd40ed76dc38c16255d59dc5029c715310`  
**Main controller source blob for the exact line map below:** `e4791a7b57c9a5972e0c5db1ae459f587ae99fa4` (910 lines)  
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

The look is currently drawn procedurally in `scripts/game.gd`; the SVG app icon is the main external art asset. Procedural visuals keep the project importable without an asset pack but are placeholder art, not final art. Each chamber also has one optional Memory Shard that reveals a short courier-network lore fragment.

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

- `scripts/game.gd:L683–L689`: while `is_recording`, the route draws in amber with a ring and START marker at the first sample. This makes the recorded path visible before the echo is sent.
- `scripts/game.gd:L691–L692`: the echo playback trail uses the same helper but remains cyan, distinguishing a saved/replaying echo from the live recording.
- `scripts/game.gd:L767–L773`: `_draw_track_path(track, tint, line_width)` draws the samples; rendering only reads route data and does not change gameplay.
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

### Sentinel collision safely cancels unfinished recordings
**Changed:** `scripts/game.gd` and `tests/game_flow_smoke.gd`.

- `scripts/game.gd:L475–L493`: after returning the player to the authored spawn, collision handling checks `is_recording`. If the player was recording, the game now stops that take, resets both recording timers, clears `recording_track`, updates the HUD, and redraws.
- Why: if the recording continued after the player was teleported to spawn, the ghost would replay a false route that jumps from the sentinel collision point back to the entrance. A clear “recording lost” message prevents the player from trusting that route.
- `tests/game_flow_smoke.gd:L128–L154`: the sentinel test now verifies ordinary spawn reset and the interrupted-recording case: recording flag/timers reset, route samples cleared, and the user-facing message explains the loss.
- [Godot CI run 54](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40390169866) passed on Godot 4.4.0 and 4.7.2 with the sentinel-collision cancellation regression test.

### Optional Memory Shards and save-schema version 2
**Changed:** `scripts/data/level_catalog.gd`, `scripts/game.gd`, `scripts/data/progress_store.gd`, `tests/headless_smoke.gd`, and `tests/game_flow_smoke.gd`.

- `scripts/data/level_catalog.gd:L12–L93` now gives each of the six rooms a `memory_shard: Vector2` pickup point and a `shard_lore` fragment. The six shards are optional; they never gate Switch A/B, the exit, or campaign unlocking.
- `scripts/data/level_catalog.gd:L133–L172` requires the new fields, validates nonempty lore, bounds the shard position to the room, and keeps it at least 60 units away from spawn/A/B so the collectible is not hidden under a core objective.
- `scripts/game.gd:L27` adds `collected_shards` as a `PackedInt32Array` of room indices. The game checks pickup in `L121` and collects a shard in `_check_memory_shard_collection()` at `L590–L603` when the player comes within 30 units. Collection displays the room's lore, persists the room index, refreshes the menu counters/archive and redraws.
- `scripts/game.gd:L704–L711` shows `MEMORIES: collected / six` in the menu progress line and updates the archive count. `L738–L748` loads and saves collection with the campaign. `L786–L787` draws an uncollected shard; `_draw_memory_shard()` at `L828–L844` renders a violet crystal labelled MEMORY.
- `scripts/game.gd:L247–L254` explains in help that shards are optional and sentinels can destroy an unfinished take.
- `scripts/data/progress_store.gd:L5` increments the save schema to version 2. `L8–L23` loads the old campaign fields and a normalized shard array; version-1 saves still load unlocked rooms/completion count and default to no shards. `L26–L37` persists shards; `L40–L58` sanitizes duplicate, negative and out-of-range indices.
- `tests/headless_smoke.gd:L60–L61` checks every room includes a valid shard position and nonempty lore. `L96–L126` tests shard collection save round-trip, duplicate/invalid index sanitization, and compatibility with a handcrafted version-1 save.
- `tests/game_flow_smoke.gd:L245–L274` simulates touching the first shard, checks the lore message and persisted collection, then restores the original saved progress so the test does not permanently alter the player's save.
- [Godot CI run 65](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40390957517) passed on Godot 4.4.0 and 4.7.2, including the room-data/parser tests, save migration tests and collection/persistence integration test.
- The feature gives the campaign a light optional exploration reward, but it is not yet a branching narrative or a full collectible journal. Actual touch reach and pickup readability still need manual play-testing.

### Memory Archive: revisit recovered lore
**Changed:** `scripts/game.gd`, `tests/game_flow_smoke.gd`, `README.md`, `docs/GAME_DESIGN.md`, `docs/BUILD_STATUS.md`, and `docs/ROADMAP.md`.

- `scripts/game.gd:L204–L205` adds the **MEMORY ARCHIVE** button to the main menu.
- `scripts/game.gd:L288–L347` builds a scrollable archive panel with six entries, one for each chamber. Each row has a title/status and a lore line. The fixed Back button stays outside the scrolling list.
- `scripts/game.gd:L350–L353` opens the archive after refreshing its text; `L356–L370` shows the recovered fragment for collected shards and a clear discovery hint for missing ones.
- `scripts/game.gd:L436–L450` hides the archive when returning to the main menu; `L457–L487` closes it when starting a chamber; `L704–L711` refreshes its progress label when collection changes.
- `tests/game_flow_smoke.gd:L278–L300` verifies the archive opens, uses a ScrollContainer, creates title/lore rows for all rooms, shows the correct recovered/not-found state for room 1, and closes when returning to the menu.
- Archive implementation commit: `35417013566ede232f7dbacb0c36f2a5f10c5349`; archive integration-test commit: `7918208cd0d8c8d7422240f11cefadd9020d4cc8`.
- **CI status at this snapshot:** run 72 (`https://github.com/NinuGaming999/ECHOPOST/actions/runs/40391672248`) and doc-triggered runs 73–77 were still reported as in progress when checked. The runner status was not yet available as a completed pass/fail; do not mark the archive as verified until a completed run includes the current source and tests.
- The archive is a simple readable list, not a visual novel or branching narrative. Larger text, localization, and accessibility adjustments still need manual QA.

### Mobile lifecycle pause hardening
**Changed:** `scripts/game.gd` and `tests/game_flow_smoke.gd`.

- `scripts/game.gd:L70–L74`: new `_notification(what)` handler listens for `NOTIFICATION_APPLICATION_PAUSED` (Android/iOS backgrounding) and `NOTIFICATION_APPLICATION_FOCUS_OUT`.
- `scripts/game.gd:L77–L87`: `_pause_for_lifecycle()` only pauses when the game was actively playing. It clears touch/mouse joystick state, sets the pause button to **RESUME**, explains the pause to the player, and refreshes rendering/HUD.
- The existing frame loop at `scripts/game.gd:L100–L122` exits early unless the screen state is PLAYING, so recording time, echo time, hazard time, and player movement stop advancing while paused.
- The handler does not erase `recording_track`, set `is_recording` to false, or auto-resume when the application returns. A paused recording can continue after the player explicitly resumes.
- `tests/game_flow_smoke.gd:L25–L26` invokes the lifecycle test and starts a fresh chamber so later tests run from a clean state.
- `tests/game_flow_smoke.gd:L78–L93` simulates application suspension and verifies: state changes to PAUSED; joystick vector is cleared; recording flag/time survive; paused frame processing does not advance recording time; application resume does not bypass the pause screen; manual RESUME restores PLAYING.
- The roadmap and build status were updated in `docs/ROADMAP.md` and `docs/BUILD_STATUS.md`.

This change is covered by an automated headless integration test. It is **not yet a substitute for checking behavior on a real Android device**, including actual app switching and returning from the background.

## 3. Project layout and the job of each file

| Path | Responsibility / current condition |
|---|---|
| `project.godot` | Application name, icon, landscape 1280×720 viewport, canvas-item stretch, compatibility renderer and WASD/arrow input map. |
| `scenes/main.tscn` | Very small main scene: full-rect `Control` attached to `scripts/game.gd`. |
| `scripts/game.gd` | Main controller, menu/HUD construction, player movement, echo recording/playback, puzzle loop, sentinel, save flow, and all procedural rendering. **910 lines in the snapshot documented here; it is the largest refactor target later, but refactor only after tests protect behavior.** |
| `scripts/core/echo_track.gd` | Data-only `RefCounted` script loaded through preloaded script resources; avoids global `class_name` lookup; stores points, clamps timestamps to nondecreasing order, copies tracks, returns duration, interpolates route positions, and holds endpoint outside the timestamp range. |
| `scripts/data/level_catalog.gd` | Six authored room dictionaries with shard positions/lore, defensive-copy accessor, canonical/draft validator for schema, names, spacing, position bounds, shard placement and hazard tuning. |
| `scripts/data/progress_store.gd` | Version-2 local save boundary (`user://echopost_save.cfg`) using `ConfigFile`; preserves v1 campaign progress and stores normalized Memory Shard room indices. |
| `tests/headless_smoke.gd` | Data-layer smoke tests for echo interpolation/copying, six-room/shard schema, malformed-draft validation, v2 shard persistence/sanitization, v1-save compatibility, and campaign progress clamping. |
| `tests/game_flow_smoke.gd` | Main-scene integration tests for scrollable chapter selection, Memory Shard lore/persistence, Memory Archive display, lifecycle pause, recording cap/feedback, sentinel recording cancellation, reset cleanup, portal-completion idempotency, route validation, echo creation and gate activation. |
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

This function index is line-accurate for source blob SHA `e4791a7b57c9a5972e0c5db1ae459f587ae99fa4` (910 lines). Regenerate it after any further edit to this script.

- **L1–L4:** Script header and procedural-art note.
- **L6:** `ScreenState` enum.
- **L8–L21:** Room bounds, movement/recording constants and preloaded scripts/data.
- **L23–L44:** Campaign and runtime state: player/echo, tracks/timers, gate/hazard, status text and stars.
- **L27:** `collected_shards` tracks room indices whose optional Memory Shards have been collected.
- **L46–L49:** Touch/mouse joystick state.
- **L51–L67:** Dynamic UI references, including Memory Archive labels/panel.
- **L71–L75 — `_notification()`:** Handle application suspension/focus loss and delegate to lifecycle pause.
- **L78–L88 — `_pause_for_lifecycle()`:** Pause active play; clear joystick input, preserve recording state, and refresh the HUD.
- **L91–L98 — `_ready()`:** Initialize stars, load saved progress, build UI and show the menu.
- **L101–L124 — `_process()`:** Update movement, clamp/sample recording time, advance echoes/hazards, check collisions, collect Memory Shards and evaluate puzzles.
- **L127–L157 — `_input()`:** Translate touch/mouse events into virtual joystick input.
- **L160–L161 — `_is_joystick_area()`:** Choose where touch can start a joystick.
- **L164–L166 — `_update_joystick()`:** Convert pointer offset into a normalized joystick vector.
- **L169–L173 — `_create_stars()`:** Generate deterministic decorative background stars.
- **L176–L182 — `_build_interface()`:** Build menu, gameplay HUD, completion, help, chapter selector and Memory Archive.
- **L185–L207 — `_build_menu()`:** Create title, continue, chapter-select, help, Memory Archive button and progress UI.
- **L210–L229 — `_build_game_hud()`:** Create level labels, pause, record, restart, menu and control help.
- **L232–L244 — `_build_complete_panel()`:** Create completion message and next/replay buttons.
- **L247–L254 — `_build_help_panel()`:** Build instructions including optional Memory Shards and sentinel recording loss.
- **L257–L285 — `_build_level_select_panel()`:** Create a scrollable chapter list and fixed Back button.
- **L288–L347 — `_build_memory_archive_panel()`:** Build the scrollable archive with one recovered/not-found entry per room and a Back button.
- **L350–L353 — `_open_memory_archive()`:** Refresh archive text, hide the main menu and show the archive panel.
- **L356–L370 — `_update_memory_archive()`:** Display recovered lore for collected shards and a discovery hint for missing ones.
- **L373–L387 — `_make_panel()`:** Shared panel styling.
- **L390–L402 — `_make_label()`:** Shared label typography and placement.
- **L405–L433 — `_make_button()`:** Shared button style and colors.
- **L436–L450 — `_show_menu()`:** Return to menu, hide panels and clear transient recording/input state.
- **L453–L454 — `_on_start_pressed()`:** Continue at the unlocked chamber.
- **L457–L487 — `_start_level()`:** Initialize room state, close overlay panels and show gameplay HUD.
- **L490–L506 — `_on_record_pressed()`:** Start route recording or attempt to stop/send it.
- **L509–L534 — `_finish_recording()`:** Enforce minimum duration and Switch A endpoint before releasing the echo.
- **L537–L538 — `_add_record_sample()`:** Append a timestamp/position pair to the current route.
- **L541–L551 — `_update_player()`:** Apply movement, clamp to room bounds and block a closed gate.
- **L554–L566 — `_update_echo()`:** Advance echo playback, hold its endpoint temporarily, then fade.
- **L569–L587 — `_check_sentinel_collision()`:** Reset the player to spawn; cancel and clear an interrupted recording to avoid a fake teleport.
- **L590–L603 — `_check_memory_shard_collection()`:** Collect a room's optional shard once, reveal lore, persist its index and refresh the HUD/menu/archive.
- **L606–L625 — `_check_puzzle_state()`:** Evaluate switches, open the gate and detect portal completion.
- **L628–L648 — `_complete_level()`:** Increment completion, unlock progress, save and show the completion panel.
- **L651–L655 — `_on_next_level_pressed()`:** Advance to the next chamber or restart the campaign.
- **L658–L659 — `_on_replay_pressed()`:** Restart the current chamber.
- **L662–L663 — `_on_reset_pressed()`:** Restart the current chamber.
- **L666–L679 — `_on_pause_pressed()`:** Toggle pause/resume and clear stale joystick input.
- **L682–L683 — `_open_help()`:** Show instructions.
- **L686–L688 — `_open_level_select()`:** Refresh chapter labels and show chapter selection.
- **L691–L693 — `_on_chapter_selected()`:** Start a chamber only when it is unlocked.
- **L696–L701 — `_update_chapter_buttons()`:** Update chapter labels and locked/unlocked state.
- **L704–L711 — `_update_menu_progress()`:** Refresh campaign and Memory Shard counts; refresh archive if it exists.
- **L714–L735 — `_update_hud()`:** Update chamber title, status, echo timer and record button.
- **L738–L742 — `_load_progress()`:** Load local campaign progress, including migrated Memory Shard indices.
- **L745–L748 — `_save_progress()`:** Persist campaign progress and collected Memory Shards.
- **L751–L760 — `_draw()`:** Draw the background and choose menu/room/paused render path.
- **L763–L769 — `_draw_menu_art()`:** Draw menu decorations and procedural robots.
- **L772–L824 — `_draw_room()`:** Draw the room, switches, gate, portal, hazards, uncollected shard, live recording preview, echo trail and actors.
- **L828–L844 — `_draw_memory_shard()`:** Draw the optional collectible as a glowing violet crystal with a label.
- **L847–L855 — `_draw_switch()`:** Draw a pressure switch and its state.
- **L858–L868 — `_draw_gate()`:** Draw open/closed gate art.
- **L871–L877 — `_draw_portal()`:** Draw the powered/unpowered exit portal.
- **L880–L890 — `_draw_robot()`:** Draw a procedural player or echo robot.
- **L893–L899 — `_draw_joystick()`:** Draw the active touch joystick.
- **L902–L908 — `_draw_track_path()`:** Draw a sampled route in a given tint/width; shared by recording preview and echo trail.
## 5. Exact line map — supporting scripts and tests

### `scripts/core/echo_track.gd` (60 lines, blob SHA `9a433129a0cb8b04d9ab55c0964aeb4683ddab3a`)
- **L1–L5:** `RefCounted` script header, purpose/comment about avoiding global `class_name` cache, and array of dictionaries shaped like `{"t": timestamp, "p": Vector2}`.
- **L8–L9:** Clear all recorded samples.
- **L12–L16:** Append sample; time is nonnegative and never earlier than the previous sample.
- **L19–L25:** Copy route using `get_script().new()` and append duplicate sample dictionaries; this is the specific Godot 4.4 self-reference fix.
- **L28–L31:** Route duration from the final timestamp; empty route is zero seconds.
- **L34–L59:** Position lookup: handles empty/before-first/after-last times, walks consecutive samples, linearly interpolates between points and handles tiny/duplicate timestamp spans.

### `scripts/data/level_catalog.gd` (188 lines, blob SHA `c98f0dc765b13c5cfc5fe1930afd4638a6665032`)
- **L1–L3:** RefCounted script and catalog purpose.
- **L4–L101:** Six room dictionaries. Each now includes spawn/A/B, `memory_shard`, `shard_lore`, linger, hazard tuning and accent color.
- **L103–L104:** Clamped defensive-copy getter.
- **L106–L107:** Campaign count helper.
- **L111–L112:** Validate the canonical `LEVELS` array using the same draft validator.
- **L116–L132:** Arbitrary draft-list validation, empty-campaign rejection, and nonempty/unique names.
- **L133–L145:** Required fields, Memory Shard Vector2 and nonempty lore validation.
- **L146–L152:** Positive linger and room-bounds validation for spawn, switches and shard.
- **L154–L158:** Enforce minimum meaningful spawn-to-Switch-A route.
- **L160–L164:** Enforce Switch A/B separation.
- **L166–L172:** Keep Memory Shards away from spawn and pressure switches.
- **L174–L186:** Require hazard fields and bound patrol height, width and speed.

### `scripts/data/progress_store.gd` (58 lines, blob SHA `c74c684bab3ca4e40b8ea49b995633b795c4974a`)
- **L1–L5:** `RefCounted` save boundary, `user://echopost_save.cfg`, schema version 2.
- **L8–L13:** Load result defaults, including an empty `PackedInt32Array` for shard indices.
- **L14–L23:** Load readable v1/v2 saves; retain/clamp campaign progress and normalize any shard array. V1 saves have no shard field, so their collection defaults to empty.
- **L26–L37:** Write version 2 and campaign fields plus the normalized shard collection.
- **L40–L50:** Accept packed arrays or ordinary arrays, filter invalid values, deduplicate and sort.
- **L53–L58:** Append one shard index only if it is nonnegative, within the supplied level count, and not already present.

### `tests/headless_smoke.gd` (133 lines, blob SHA `1a56182e462a63f9992166941327310b55dfd693`)
- **L1–L8:** Test harness, preloaded echo/level/save scripts, and a separate temporary save path.
- **L13–L22:** Execute data tests and return nonzero if assertions fail.
- **L25–L44:** Echo track monotonic timestamps, interpolation, endpoint hold, preloaded script identity and copy independence.
- **L47–L68:** Require six uniquely named valid rooms; check required switch/shard/lore fields, positive linger and defensive copies.
- **L71–L85:** Deliberately invalid room drafts test duplicate names, too-short spawn route, close switches and negative sentinel speed.
- **L88–L92:** Error-message substring helper.
- **L96–L126:** Campaign save/load, unlock clamping, shard-array normalization, and legacy v1-save compatibility.
- **L129–L132:** Shared assertion helper.

### `tests/game_flow_smoke.gd` (307 lines, blob SHA `890bb36746ee3acce9247fc65791bbf0042100b0`)
- **L1–L10:** Scene/test preloads and counters.
- **L13–L14:** Defer the integration test runner.
- **L17–L77:** Test scrollable chapter selector, shard collection, Memory Archive UI, lifecycle pause, record cap/feedback, sentinel cancellation, restart cleanup, portal idempotency, invalid/valid routes and gate activation.
- **L81–L96:** Lifecycle pause preserving active recording state, clearing joystick and requiring manual resume.
- **L99–L114:** Maximum eight-second recording route.
- **L117–L128:** Too-short recording response.
- **L131–L157:** Sentinel spawn reset and cancelled interrupted route.
- **L160–L197:** Restart cleanup and restart from paused.
- **L200–L223:** Portal completion count exactly once, then restore existing save.
- **L226–L241:** Scrollable chapter selector/row count.
- **L245–L274:** Memory Shard pickup, lore, persistence, and restoration of original progress.
- **L278–L300:** Memory Archive panel, scroll list, all six entries, recovered/missing state, and back-to-menu behavior.
- **L303–L306:** Shared assertion helper.

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

- **Memory Shard/save-migration baseline:** [Godot checks run 65](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40390957517) passed on Godot 4.4.0 and 4.7.2. It verifies optional shard collection, version-2 save round-trip/sanitization and version-1 save compatibility.
- **Memory Archive source and UI test:** run 72 (`https://github.com/NinuGaming999/ECHOPOST/actions/runs/40391672248`) was still in progress when this handoff was last inspected. Check the newest GitHub Actions run before declaring the archive verified.
- **Six-room content, route preview, level validation, recording cap, sentinel interruption, restart/portal tests:** previous passing runs listed above remain the established baseline.
- **Local device test:** not performed by this assistant. Shard reach, archive readability, route preview and chapter scrolling still need manual inspection in Godot/Android.
- **Android APK/export:** no APK has been built or attached; export templates, package ID, signing and real-device QA remain.
- **Runtime quality:** automated checks are not a substitute for manually playing all six rooms and validating difficulty/fairness.


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
3. **Small content set:** six room dictionaries and six optional Memory Shards now exist, but the core two-switch pattern is reused and there is no full campaign or final narrative ending.
4. **Procedural placeholder visuals:** no authored robot animations, environmental tilesets, VFX or transition animations.
5. **No sound:** recording, rejected route, sentinel hits, gate opening and portal have text/visual feedback only. No SFX, music, mixer, or audio options exist.
6. **Pause behavior needs real device QA:** the lifecycle logic is headlessly tested but actual Android app-switch lifecycle and focus behavior are unverified. The player must tap RESUME after returning.
7. **Mechanic coverage:** one recording slot, one hold-style Switch A/Switch B puzzle pattern, a single gate and hardcoded portal position. Timed/toggle/sequence switches, moving platforms and checkpoints are ideas only.
8. **Recording edge cases:** the minimum is now `MIN_RECORD_SECONDS = 0.7` at `scripts/game.gd:L16`; a too-short stop deliberately keeps recording active and tells the player to continue. Verify that this interaction is understandable on touch.
9. **Hazard edge cases:** collision now cancels an unfinished recording so it cannot include a fake teleport to spawn. Already-released echoes are separate; their behavior on sentinel contact still needs deliberate playtesting.
10. **Save migration:** schema version 2 now persists Memory Shard indices; version-1 campaign progress is backward-compatible and tested. Future-version behavior and cloud saves are not designed.
11. **Level validation:** catches schema/name/position/spacing and sentinel tuning errors, but it is not a pathfinding solver and does not prove portal reachability or fairness against the sentinel's phase.
12. **No online features or monetization:** no accounts, backend, community route uploads, cloud saves, ads, analytics or payments are implemented. Do not add these before offline puzzle quality, privacy and moderation are planned.

## 8. Prioritized next steps

### P0 — Keep the project compiling and the handoff current
- [x] Fix Godot 4.4 `Identifier not found: EchoTrack` self-reference in `scripts/core/echo_track.gd:L19–L25`.
- [x] Add a regression assertion for preloaded script identity at `tests/headless_smoke.gd:L39–L44`.
- [x] Verify the code fix and regression test in [run 21](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40385871675): Godot 4.4.0 and 4.7.2 both passed.
- [x] Verify restart/portal flows (run 33), route preview (run 34), six-room chapter UI (run 42), room validation (run 49), sentinel interruption (run 54), and Memory Shards plus v1 save compatibility (run 65) on both Godot versions.
- [ ] Confirm the Memory Archive integration-test workflow passes before marking it verified.
- [ ] Ask for / perform a local pull and open the project in the user's Godot 4.4 editor to inspect the live route preview and confirm visuals on the actual machine.
- [ ] Verify Memory Archive integration-test run 72 (or a newer source-inclusive run); update this file and `docs/BUILD_STATUS.md` with its final status.
- [ ] Every further code change must update this progress file and refresh affected line maps.

### P1 — Core mechanic test coverage
- [x] Add an integration test for automatic recording stop and verify the echo route is exactly 8.0 seconds.
- [x] Test the too-short recording interaction: no echo is created, recording remains active, and the message says to keep recording.
- [x] Test sentinel contact resets the player to the room spawn and displays feedback.
- [x] Decide and test sentinel interruption behavior: contact cancels/clears an unfinished recording and reports “recording lost”; an already released echo is not treated as an unfinished take.
- [x] Test restart while recording and echo playback are active, and verify restart from PAUSED clears state.
- [x] Test powered portal completion and ensure the completion count increments exactly once while the test restores the original save values.
- [ ] Test lifecycle focus-out as well as application-paused notification; physical mobile app switching still needs manual QA.
- [x] Expand the level validator for room names, route/switch spacing, sentinel tuning and Memory Shard placement/lore.
- [x] Add one optional Memory Shard per room, a short lore message, progress counter, save schema v2, v1 save compatibility, and collection/persistence regression tests.

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
5. Refresh every affected line number after changes. The line map in section 4 is keyed to `scripts/game.gd` blob SHA `e4791a7b57c9a5972e0c5db1ae459f587ae99fa4`; section 5 records current supporting-script and test blob SHAs. If any of those blob SHAs differ after edits, regenerate the corresponding section.
6. Update `PROJECT_PROGRESS.md` in the same development pass as source changes. Record the new commit(s), source hashes/line references, CI URL/result and what the next session should do.
7. Keep this game offline-capable and dependency-light. Never add network accounts, telemetry, uploads, payment or ads as an incidental code change.
8. Don't produce an APK/release claim unless an actual export and install verification were completed.

---

*Handoff note: this file is written to make future work resumable from concrete repository state, not to declare completion. The next session's first action should be checking the newest workflow run, then continue with P1 test coverage before beginning larger gameplay/content changes.*
