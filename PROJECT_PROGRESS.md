# ECHOPOST — PROJECT PROGRESS / HANDOFF

> **This file is the continuity record for future ECHOPOST development.** Read it before changing code. The game is deliberately an unfinished long-running project; do not treat the current eight-room prototype as complete. After every meaningful code, test, gameplay, or build change, update this file with what changed, why, exact file/line references, current verification results, and the next actionable tasks.

**Repository:** https://github.com/NinuGaming999/ECHOPOST  
**Working branch:** `main`  
**Project root:** repository root; main scene is `res://scenes/main.tscn`  
**Engine:** Godot 4.x; CI tests Godot 4.4.0 and 4.7.2  
**Target:** Android-first landscape game; desktop builds support development and testing  
**Recording-cap code commit:** `b5f36b6a4f764a595e5dd930e8d6b3cebd5ce3a8`  
**Gameplay-test commit:** `11c3b30de34323c536b0b8302eb8604259248d52`  
**Options source fix commit:** `45ee5b1b5b6854fea8f17934897a539a47abd0da`  
**Settings store commit:** `2def61fffff0679c21f09c7f3da1fe6fb79bb2ed`  
**Options integration test commit:** `ef4e77b48736604fa9cb2b7e41afb769ec503ad4`  
**Relay Beacon source commit:** `4989b12597ff1f9977607865e7cf7c5e86ae4b43`  
**Relay test commits:** `4ba4d9cf849bfe3e8d3ac8914ba7c4e77f3b5990`, `f6781f6ddf0d9532ecb2c1adb31ebdd671d532b7`, `dc9b79d223f50e0e9737d2b2edce437060c7a3af`, `2cb03959726094c526140b3e63282f0440453e74`  
**Pulse Lock source commit:** `42db7af4ac20e0713011df4e2cfa08c68086d1a7`  
**Ordered-relay linked-state correction:** `74fa81eefae19cc08b05052c07e5da91f26018f7`  
**Reverse-route assertion correction:** `5bacf273819e2a420f03f40468e5385b1e447733`  
**Pulse Lock countdown visual:** `00f238cdc158a4ab8a6f141c1e1f930d412e78e6`  
**Pulse Lock timer regression test:** `d8d67302b109c3e4336ee54863c831698ad31691`  
**Main controller source blob for the exact line map below:** `c96db82800a0f7e43104a11041965342628b830d` (1210 lines)  
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

The current source includes eight authored chamber layouts:
- **The First Echo:** basic teach-the-mechanic chamber.
- **Long Memory:** roaming sentinel and a more distant Switch B.
- **Split Signal:** faster/larger sentinel movement and opposite-side switches.
- **Fractured Lane:** a longer diagonal route under a wide patrol.
- **Crosscurrent:** switches in opposite corners and a faster midline patrol.
- **Static Bloom:** long route, wide sentinel sweep, and one required Relay Beacon before Switch A.
- **Chorus Route:** two Relay Beacons must be crossed in order before Switch A.
- **Pulse Lock:** holding both switches opens a 3.5-second gate-crossing window; a missed window requires re-arming, while a successful crossing keeps the exit powered.

The first five rooms teach the two-switch echo mechanic with varied geometry/patrols. Static Bloom introduces a single required gold Relay Beacon; Chorus Route requires two beacons in order; Pulse Lock adds a timed crossing and retry rule. Relay tests check line segments between samples, so a crossing between samples is valid. Eight rooms are still a prototype, not a finished campaign.

The look is currently drawn procedurally in `scripts/game.gd`; the SVG app icon is the main external art asset. Procedural visuals keep the project importable without an asset pack but are placeholder art, not final art. Each chamber also has one optional Memory Shard that reveals a short courier-network lore fragment.

## 2. Latest work in this development pass

### Ordered Relay feedback and Pulse Lock timed gate
**Changed:** `scripts/data/level_catalog.gd`, `scripts/game.gd`, `tests/headless_smoke.gd`, and `tests/game_flow_smoke.gd`, plus README/design/roadmap/build-status documentation.

- `scripts/data/level_catalog.gd:L4–L137`: eight authored room definitions; Chorus Route contains ordered `echo_waypoints`, and Pulse Lock defines `gate_open_seconds: 3.5`.
- `scripts/data/level_catalog.gd:L151–L265`: reusable validator checks waypoint-array/type/bounds/separation and requires numeric `gate_open_seconds` within 1–15 seconds.
- `scripts/game.gd:L669–L705`: `_is_relay_waypoint_linked()` computes the first crossing for every beacon and refuses to mark a checkpoint linked if the route encountered a later beacon first.
- `scripts/game.gd:L708–L757`: path validators enforce Relay 1 → Relay 2 order and count crossings along sample-to-sample segments.
- `scripts/game.gd:L36–L47`: `gate_open_timer` and `timed_gate_failed` hold Pulse Lock countdown/retry state.
- `scripts/game.gd:L116–L140`: the countdown advances only inside PLAYING frames; pausing freezes the timed window.
- `scripts/game.gd:L557–L591`: starting/restarting a room resets the timer and missed-window latch.
- `scripts/game.gd:L825–L839`: `_update_timed_gate()` closes the gate when time expires before the barrier; after a successful crossing, the portal remains powered.
- `scripts/game.gd:L842–L874`: both switches arm the timed crossing; failed attempts stay latched until one switch is left.
- `scripts/game.gd:L963–L986`: HUD reports the active timed-gate countdown.
- `scripts/game.gd:L1035–L1103` and `L1157–L1168`: linked relay visuals and amber timed-gate rendering; the playfield displays pulse seconds.
- `tests/headless_smoke.gd:L50–L93` and `L96–L117`: verify eight rooms, single/ordered relays, timed-gate schema, malformed waypoint lists and timer bounds.
- `tests/game_flow_smoke.gd:L387–L438`: test wrong/valid ordered-relay routes and linked-state visual logic.
- `tests/game_flow_smoke.gd:L442–L494`: exercise Pulse Lock timer start, real-frame countdown, timeout, retry latch, rearm and persistent power after crossing.
- `tests/game_flow_smoke.gd:L85–L103`: verify the gate countdown does not advance while paused.
- A failed visual-state expectation on a reversed route was corrected: Relay 1 must not be marked linked if Relay 2 was encountered first. [CI run 119](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40396769674) passed both Godot 4.4.0 and 4.7.2.
- The complete Pulse Lock code and timer-test path passed [CI run 122](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40397091984) on both supported Godot versions.

Pulse Lock still needs hands-on playtesting to determine whether 3.5 seconds feels fair at each movement-speed preset and on real touch controls. CI verifies logic, not human timing comfort.

### Godot 4.4 compile failure: EchoTrack self-reference
**Reported by the user:** Godot 4.4 produced `Identifier not found: EchoTrack` at `res://scripts/core/echo_track.gd:20`. That caused the echo script to fail compilation; `scripts/game.gd` could not compile its dependent script, and subsequent `clear()` calls failed because the track variables were `Nil`.

**Root cause:** `echo_track.gd` referenced the global name `EchoTrack` inside its own `copy_track()` method (`EchoTrack.new()`) and its return annotation. This was unnecessarily dependent on Godot's global script-class registration/cache even though all in-repository consumers already load the script with `preload()`.

**Fix committed:**
- `scripts/core/echo_track.gd:L1–L5`: removed `class_name EchoTrack`; the script remains a `RefCounted` resource and is instantiated through preloaded script references.
- `scripts/core/echo_track.gd:L19–L25`: `copy_track()` no longer types its return as the global `EchoTrack` class and instantiates the same resource using `get_script().new()`, then copies all samples.
- `scripts/game.gd:L18–L22` and `L39–L44`: already uses the `ECHO_TRACK_SCRIPT = preload(...)` resource and so required no modification. Its previous `Nil.clear()` errors were downstream symptoms, not separate root causes.
- `tests/headless_smoke.gd:L42–L47`: added a regression check that a copied track's script is exactly the preloaded resource, as well as retaining copy independence/interpolation tests.
- Code fix commit: `5179b423d0d00d4a2ee807bc9d621d376b04b49a`.
- Regression-test commit: `3a02e78abafe8c5cd1bb923e2e00b644b5a9c3f7`.
- [Godot CI run 21](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40385871675) passed on Godot 4.4.0 and 4.7.2, including the new regression assertion.

### Recording duration hardening and gameplay regression tests
**Changed:** `scripts/game.gd` and `tests/game_flow_smoke.gd`.

- `scripts/game.gd:L16–L17`: introduced one minimum-duration constant (`MIN_RECORD_SECONDS = 0.7`) alongside the 8-second maximum.
- `scripts/game.gd:L114–L137`: recording elapsed time is clamped to `MAX_RECORD_SECONDS` before recording samples are written. This prevents a frame delta from producing a route whose final timestamp exceeds eight seconds.
- `scripts/game.gd:L611–L612`: the too-short recording path uses the same `MIN_RECORD_SECONDS` constant and clearer feedback: keep recording until the 0.7-second minimum, then stop on Switch A. It intentionally keeps recording active so the player can continue rather than losing the attempted route.
- `tests/game_flow_smoke.gd:L101–L116`: starts at 7.99 seconds, advances one capped frame, and asserts recording auto-stops, an echo is made when ending at Switch A, and its recorded duration is exactly 8.0 seconds.
- `tests/game_flow_smoke.gd:L119–L130`: asserts a too-short stop does not create an echo, does not discard the ongoing recording, and clearly explains how to continue.
- `tests/game_flow_smoke.gd:L133–L159`: verifies sentinel contact returns the player to the spawn and displays contact feedback.
- The test commit is `11c3b30de34323c536b0b8302eb8604259248d52`; [Godot CI run 25](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40387225782) passed both Godot 4.4.0 and 4.7.2.
- `docs/ROADMAP.md` and `docs/BUILD_STATUS.md` now record the new coverage.

This hardening pass addresses a real frame-step boundary issue and makes the minimum-duration interaction clearer. It adds test coverage, but it does not replace manual play-testing on the user's PC or phone.

### Restart reset and portal-completion regression tests
**Changed:** `tests/game_flow_smoke.gd`.

- `tests/game_flow_smoke.gd:L162–L199`: `_test_restart_clears_state()` creates active recording/echo tracks, advances their timers, opens the gate and holds joystick direction; the real reset handler must return the player to spawn, clear both tracks and timers, hide/stop the echo, close the gate and clear input. It then verifies restarting from PAUSED returns to PLAYING.
- `tests/game_flow_smoke.gd:L202–L225`: `_test_portal_completion_is_idempotent()` sends the player through a powered portal, verifies COMPLETE and the completion panel, ensures the completion count increments once, runs the checker again to prove no duplicate count, and restores the original saved campaign values.
- The test header now accurately says that the suite exercises completion and restores saved progress.
- [Godot CI run 33](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40388464089) passed on Godot 4.4.0 and 4.7.2 with these restart/completion assertions.

### Live recording-route preview
**Changed:** `scripts/game.gd`.

- `scripts/game.gd:L945–L951`: while `is_recording`, the route draws in amber with a ring and START marker at the first sample. This makes the recorded path visible before the echo is sent.
- `scripts/game.gd:L953–L954`: the echo playback trail uses the same helper but remains cyan, distinguishing a saved/replaying echo from the live recording.
- `scripts/game.gd:L1065–L1071`: `_draw_track_path(track, tint, line_width)` draws the samples; rendering only reads route data and does not change gameplay.
- [Godot CI run 34](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40388600546) passed on Godot 4.4.0 and 4.7.2 after adding the shared renderer helper. Visual quality still needs a manual editor/device check.
### Six-room campaign and scrollable chapter selector
**Changed:** `scripts/data/level_catalog.gd`, `scripts/game.gd`, `tests/headless_smoke.gd`, and `tests/game_flow_smoke.gd`.

- `scripts/data/level_catalog.gd:L4–L101` now contains six room definitions: The First Echo, Long Memory, Split Signal, Fractured Lane, Crosscurrent, and Static Bloom. New rooms vary diagonal route length, opposing-corner switches, hazard height, sentinel sweep width/speed, and accent color.
- `scripts/data/level_catalog.gd:L104–L111` provides the clamped copy accessor/count; `L117–L198` validates room keys, positions, linger durations, shard/waypoint placement and hazard fields.
- `scripts/game.gd:L279–L307` creates a `ScrollContainer` named `ChapterScroll` with a `VBoxContainer` list named `ChapterList`. Each level gets a button; the Back button stays below the viewport and does not overlap later rooms.
- `tests/headless_smoke.gd:L50–L76` requires at least six chambers, validates the data schema, checks every chamber name is non-empty and unique, and preserves the defensive-copy assertion.
- `tests/game_flow_smoke.gd:L228–L243` verifies the scroll container, automatic vertical scroll mode and one list button per authored chamber.
- [Godot CI run 39](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40389126011) passed the expanded level catalog; [run 42](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40389230677) passed the scrollable UI and regression tests on Godot 4.4.0 and 4.7.2.
- This is a longer early-game slice, not a finished campaign: new switch types, checkpoints, moving platforms, narrative fragments and physical-device layout testing remain.
### Room-schema validator hardening
**Changed:** `scripts/data/level_catalog.gd` and `tests/headless_smoke.gd`.

- `scripts/data/level_catalog.gd:L112–L113`: `validate_levels()` now delegates to the reusable `validate_level_list(levels)` function so both canonical campaign data and proposed drafts can be checked.
- `scripts/data/level_catalog.gd:L117–L132`: reject an empty list and blank/duplicate chamber names.
- `scripts/data/level_catalog.gd:L133–L148`: check required fields, Vector2 types, positive linger, and all playfield positions.
- `scripts/data/level_catalog.gd:L150–L164`: reject a spawn less than 180 units from Switch A (too short for the intended route) and reject overlapping/near-overlapping A/B switches closer than 86 units.
- `scripts/data/level_catalog.gd:L174–L198`: validate sentinel height, sweep amplitude (0–500) and speed (greater than 0, no more than 4).
- `tests/headless_smoke.gd:L79–L95`: provide a deliberately malformed two-room draft and assert the validator reports duplicate names, too-short route, overlapping switches and negative patrol speed. `L86–L90` is the shared message-fragment helper.
- [Godot CI run 49](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40389764965) passed on Godot 4.4.0 and 4.7.2 with the invalid-draft regression tests.
- The validator is a static data check, not a pathfinding solver: it does not yet prove each room is solvable against the moving sentinel timing.

### Sentinel collision safely cancels unfinished recordings
**Changed:** `scripts/game.gd` and `tests/game_flow_smoke.gd`.

- `scripts/game.gd:L702–L720`: after returning the player to the authored spawn, collision handling checks `is_recording`. If the player was recording, the game now stops that take, resets both recording timers, clears `recording_track`, updates the HUD, and redraws.
- Why: if the recording continued after the player was teleported to spawn, the ghost would replay a false route that jumps from the sentinel collision point back to the entrance. A clear “recording lost” message prevents the player from trusting that route.
- `tests/game_flow_smoke.gd:L133–L159`: the sentinel test now verifies ordinary spawn reset and the interrupted-recording case: recording flag/timers reset, route samples cleared, and the user-facing message explains the loss.
- [Godot CI run 54](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40390169866) passed on Godot 4.4.0 and 4.7.2 with the sentinel-collision cancellation regression test.

### Optional Memory Shards and save-schema version 2
**Changed:** `scripts/data/level_catalog.gd`, `scripts/game.gd`, `scripts/data/progress_store.gd`, `tests/headless_smoke.gd`, and `tests/game_flow_smoke.gd`.

- `scripts/data/level_catalog.gd:L12–L101` now gives each of the six rooms a `memory_shard: Vector2` pickup point and a `shard_lore` fragment. The six shards are optional; they never gate Switch A/B, the exit, or campaign unlocking.
- `scripts/data/level_catalog.gd:L133–L172` requires the new fields, validates nonempty lore, bounds the shard position to the room, and keeps it at least 60 units away from spawn/A/B so the collectible is not hidden under a core objective.
- `scripts/game.gd:L28` adds `collected_shards` as a `PackedInt32Array` of room indices. The game checks pickup in `L130–L133` and collects a shard in `_check_memory_shard_collection()` at `L723–L736` when the player comes within 30 units. Collection displays the room's lore, persists the room index, refreshes the menu counters/archive and redraws.
- `scripts/game.gd:L837–L844` shows `MEMORIES: collected / six` in the menu progress line and updates the archive count. `L871–L875` loads and `L890–L893` saves collection with the campaign. `L917–L971` draws room objects including an uncollected shard; `_draw_memory_shard()` at `L991–L1007` renders a violet crystal labelled MEMORY.
- `scripts/game.gd:L269–L276` explains in help that shards are optional and sentinels can destroy an unfinished take.
- `scripts/data/progress_store.gd:L5` increments the save schema to version 2. `L8–L23` loads the old campaign fields and a normalized shard array; version-1 saves still load unlocked rooms/completion count and default to no shards. `L26–L37` persists shards; `L40–L58` sanitizes duplicate, negative and out-of-range indices.
- `tests/headless_smoke.gd:L50–L76` checks every room includes a valid shard position and nonempty lore. `L96–L126` tests shard collection save round-trip, duplicate/invalid index sanitization, and compatibility with a handcrafted version-1 save.
- `tests/game_flow_smoke.gd:L247–L276` simulates touching the first shard, checks the lore message and persisted collection, then restores the original saved progress so the test does not permanently alter the player's save.
- [Godot CI run 65](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40390957517) passed on Godot 4.4.0 and 4.7.2, including the room-data/parser tests, save migration tests and collection/persistence integration test.
- The feature gives the campaign a light optional exploration reward, but it is not yet a branching narrative or a full collectible journal. Actual touch reach and pickup readability still need manual play-testing.

### Memory Archive: revisit recovered lore
**Changed:** `scripts/game.gd`, `tests/game_flow_smoke.gd`, `README.md`, `docs/GAME_DESIGN.md`, `docs/BUILD_STATUS.md`, and `docs/ROADMAP.md`.

- `scripts/game.gd:L205–L229` adds the **MEMORY ARCHIVE** button to the main menu.
- `scripts/game.gd:L310–L369` builds a scrollable archive panel with six entries, one for each chamber. Each row has a title/status and a lore line. The fixed Back button stays outside the scrolling list.
- `scripts/game.gd:L372–L375` opens the archive after refreshing its text; `L451–L465` shows the recovered fragment for collected shards and a clear discovery hint for missing ones.
- `scripts/game.gd:L531–L547` hides the archive when returning to the main menu; `L554–L586` closes it when starting a chamber; `L837–L844` refreshes its progress label when collection changes.
- `tests/game_flow_smoke.gd:L280–L302` verifies the archive opens, uses a ScrollContainer, creates title/lore rows for all rooms, shows the correct recovered/not-found state for room 1, and closes when returning to the menu.
- Archive implementation commit: `35417013566ede232f7dbacb0c36f2a5f10c5349`; archive integration-test commit: `7918208cd0d8c8d7422240f11cefadd9020d4cc8`.
- **CI status at this snapshot:** run 72 (`https://github.com/NinuGaming999/ECHOPOST/actions/runs/40391672248`) and doc-triggered runs 73–77 were still reported as in progress when checked. The runner status was not yet available as a completed pass/fail; do not mark the archive as verified until a completed run includes the current source and tests.
- The archive is a simple readable list, not a visual novel or branching narrative. Larger text, localization, and accessibility adjustments still need manual QA.

### Options screen: movement speed and left-handed joystick
**Changed:** `scripts/game.gd`, `scripts/data/settings_store.gd`, `tests/headless_smoke.gd`, `tests/game_flow_smoke.gd`, README and the design/build/roadmap documents.

- `scripts/game.gd:L21–L22` preloads the standalone settings store; `L29–L30` holds active speed and handedness. `_ready()` loads these separately from campaign progress at `L103–L111`.
- `scripts/game.gd:L224–L227` adds the Options button and shifts menu controls to fit it.
- `scripts/game.gd:L378–L401` builds **SLOW** (200), **NORMAL** (255), **FAST** (310), and the left-handed joystick toggle.
- `scripts/game.gd:L404–L407` opens Options; `L410–L425` normalizes speed to a supported preset; `L432–L439` updates handedness and clears held input; `L442–L448` refreshes selected labels.
- `scripts/game.gd:L173–L180` moves the joystick hit region to the right in left-handed mode and preserves bottom-button areas. `L674–L684` uses the selected speed for actual movement; `L963–L966` moves the idle joystick hint.
- `scripts/game.gd:L878–L887` loads and saves settings separately from `user://echopost_save.cfg`; control preferences live at `user://echopost_settings.cfg`.
- `scripts/data/settings_store.gd:L4–L6` defines the path/default/presets; `L9–L20` loads settings; `L23–L28` saves them; `L31–L39` normalizes unsupported speeds.
- `tests/headless_smoke.gd:L140–L160` covers defaults, save/load and speed normalization.
- `tests/game_flow_smoke.gd:L306–L335` tests Options visibility, presets, speed changes, right-side joystick hit-testing and restoring previous user settings.
- [Godot CI run 81](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40392848307) passed the settings-store tests; [run 82](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40392916662) passed the integrated Options/handedness test and all smoke tests on Godot 4.4.0 and 4.7.2.

This is a basic accessibility foundation, not a full settings suite. Audio, haptics, reduced motion, safe-area tuning and broad localization remain future work.

### Relay Beacon: first required route-checkpoint mechanic
**Changed:** `scripts/data/level_catalog.gd`, `scripts/game.gd`, `tests/headless_smoke.gd`, `tests/game_flow_smoke.gd`, README and design/roadmap/build notes.

- `scripts/data/level_catalog.gd:L86–L95` gives Static Bloom a required `echo_waypoint` at `Vector2(380, 260)` and changes the room hint to tell players to pass the relay, then finish on A. The other five rooms do not have this field and retain their existing rules.
- `scripts/data/level_catalog.gd:L133–L148` validates a waypoint's type and includes it in room-bound checks. `L177–L185` makes the waypoint spatially separate from spawn, switches and the optional Memory Shard.
- `scripts/game.gd:L608–L643` checks the required waypoint after the normal “finish on Switch A” validation and before releasing an echo. A miss rejects the route and gives explicit **RELAY BEACON** feedback.
- `scripts/game.gd:L650–L671` implements `_track_passes_waypoint()`. For each adjacent pair of recorded points it projects the waypoint onto the segment, clamps the projection to that segment, and measures distance to the closest point. This correctly accepts walking through the beacon between sampled positions.
- `scripts/game.gd:L917–L971` draws the room's special objects; `L975–L988` draws the gold Relay Beacon marker labelled **RELAY**. The Relay is distinct from the optional violet Memory Shard.
- `tests/headless_smoke.gd:L50–L76` requires at least one relay room and a Vector2 waypoint. `L79–L95` deliberately gives a draft a waypoint outside the room and expects the validator to reject it.
- `tests/game_flow_smoke.gd:L339–L375` tests two cases: a direct spawn-to-A route that skips the beacon must be rejected, while a route whose segment crosses within 40 units of the relay between samples must be accepted.
- [Godot CI run 95](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40394410577) passed on Godot 4.4.0 and 4.7.2, including the validator and route-segment tests.
- This is the first required route checkpoint only in Static Bloom; it does not replace the two-switch gate, and the first five rooms remain unchanged.

### Mobile lifecycle pause hardening
**Changed:** `scripts/game.gd` and `tests/game_flow_smoke.gd`.

- `scripts/game.gd:L83–L87`: new `_notification(what)` handler listens for `NOTIFICATION_APPLICATION_PAUSED` (Android/iOS backgrounding) and `NOTIFICATION_APPLICATION_FOCUS_OUT`.
- `scripts/game.gd:L90–L100`: `_pause_for_lifecycle()` only pauses when the game was actively playing. It clears touch/mouse joystick state, sets the pause button to **RESUME**, explains the pause to the player, and refreshes rendering/HUD.
- The existing frame loop at `scripts/game.gd:L114–L137` exits early unless the screen state is PLAYING, so recording time, echo time, hazard time, and player movement stop advancing while paused.
- The handler does not erase `recording_track`, set `is_recording` to false, or auto-resume when the application returns. A paused recording can continue after the player explicitly resumes.
- `tests/game_flow_smoke.gd:L17–L79` runs the integration sequence including the lifecycle test and starts a fresh chamber so later tests run from a clean state.
- `tests/game_flow_smoke.gd:L83–L98` simulates application suspension and verifies: state changes to PAUSED; joystick vector is cleared; recording flag/time survive; paused frame processing does not advance recording time; application resume does not bypass the pause screen; manual RESUME restores PLAYING.
- The roadmap and build status were updated in `docs/ROADMAP.md` and `docs/BUILD_STATUS.md`.

This change is covered by an automated headless integration test. It is **not yet a substitute for checking behavior on a real Android device**, including actual app switching and returning from the background.

## 3. Project layout and the job of each file

| Path | Responsibility / current condition |
|---|---|
| `project.godot` | Application name, icon, landscape 1280×720 viewport, canvas-item stretch, compatibility renderer and WASD/arrow input map. |
| `scenes/main.tscn` | Very small main scene: full-rect `Control` attached to `scripts/game.gd`. |
| `scripts/game.gd` | Main controller, menu/HUD construction, movement, echo recording/playback, route checkpoint validation, puzzle loop, sentinel, Memory Shard collection/archive, control preferences, save flow and procedural rendering. **1073 lines in the snapshot documented here; refactor incrementally after tests protect behavior.** |
| `scripts/core/echo_track.gd` | Data-only `RefCounted` script loaded through preloaded script resources; avoids global `class_name` lookup; stores points, clamps timestamps to nondecreasing order, copies tracks, returns duration, interpolates route positions, and holds endpoint outside the timestamp range. |
| `scripts/data/level_catalog.gd` | Six room dictionaries, optional shard positions/lore, one required Relay Beacon waypoint in Static Bloom, defensive-copy accessor and canonical/draft validator for schema, names, spacing, bounds and hazard tuning. |
| `scripts/data/progress_store.gd` | Version-2 local save boundary (`user://echopost_save.cfg`) using `ConfigFile`; preserves v1 campaign progress and stores normalized Memory Shard room indices. |
| `scripts/data/settings_store.gd` | Separate preference store (`user://echopost_settings.cfg`) for speed and joystick handedness, defaulting safely and normalizing unsupported movement values. |
| `tests/headless_smoke.gd` | Data tests for echo interpolation/copying, six-room/shard/waypoint schema, malformed-draft validation, v2 shard persistence/sanitization, v1-save compatibility, campaign clamping and isolated control-preference persistence/normalization. |
| `tests/game_flow_smoke.gd` | Main-scene integration tests for chapter/archive/options UI, Memory Shards, speed presets/handedness, lifecycle pause, record cap/feedback, sentinel cancellation, reset, portal idempotency, Relay Beacon pass/miss, and gate activation. |
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

This function index matches source blob SHA `c96db82800a0f7e43104a11041965342628b830d` (1210 lines). It is authoritative for the current source. Older code-line references inside the historical change notes above refer to their source state when that change was made.

- **L1–L4:** Script header and procedural-art note.
- **L6:** `ScreenState` enum (MENU, PLAYING, PAUSED, COMPLETE).
- **L8–L22:** Playfield bounds, player/record timers, EchoTrack/level/progress/settings preloads.
- **L24–L31:** Campaign progress, collected Memory Shards, speed/handedness settings and current room data.
- **L33–L48:** Player/echo state, tracks, recording timers, standard/timed-gate state and sentinel clock.
- **L50–L54:** Touch/mouse joystick state.
- **L56–L80:** Dynamic menu/HUD, Archive/Options, labels, buttons and chapter references.
- **L85–L89 — `_notification()`:** Handle application suspension/focus loss and delegate to lifecycle pause.
- **L92–L102 — `_pause_for_lifecycle()`:** Pause only active play, clear stale joystick input, preserve recording state, and refresh HUD.
- **L105–L113 — `_ready()`:** Set full-screen layout, seed decoration, load progress/settings, construct UI, and show the menu.
- **L116–L140 — `_process()`:** Advance gameplay only while PLAYING; clamp delta and recording time, move/sample, update echo/hazard/shards/timed gate/puzzle, then redraw.
- **L143–L173 — `_input()`:** Translate touchscreen and mouse gestures into virtual joystick input.
- **L176–L183 — `_is_joystick_area()`:** Choose the virtual joystick hit area for left- or right-handed mode while preserving bottom-button space.
- **L186–L188 — `_update_joystick()`:** Convert pointer offset from joystick origin into normalized movement.
- **L191–L195 — `_create_stars()`:** Generate stable decorative star positions.
- **L198–L205 — `_build_interface()`:** Construct menu, HUD, completion, help, chapter, Memory Archive, and Options panels.
- **L208–L232 — `_build_menu()`:** Create navigation buttons and campaign/memory progress.
- **L235–L254 — `_build_game_hud()`:** Create gameplay status, pause/record/reset/menu buttons, and control tips.
- **L257–L269 — `_build_complete_panel()`:** Create room-completion, next-room and replay UI.
- **L272–L279 — `_build_help_panel()`:** Explain recording, Relay Beacon, Memory Shard, sentinel, and gate rules.
- **L282–L310 — `_build_level_select_panel()`:** Build scrollable chapter list with fixed Back navigation.
- **L313–L372 — `_build_memory_archive_panel()`:** Create scrollable rows for recovered or undiscovered lore entries.
- **L375–L378 — `_open_memory_archive()`:** Refresh lore rows and switch from menu to archive.
- **L381–L404 — `_build_options_panel()`:** Build movement-speed presets, handedness setting, and Back button.
- **L407–L410 — `_open_options()`:** Refresh selected preference labels and show Options.
- **L413–L420 — `_set_move_speed()`:** Normalize, apply, persist and display movement speed.
- **L423–L428 — `_normalize_move_speed()`:** Restrict movement speed to supported presets.
- **L431–L432 — `_toggle_left_handed_controls()`:** Flip joystick handedness.
- **L435–L442 — `_set_left_handed_controls()`:** Apply handedness, cancel held input, save preferences, and redraw.
- **L445–L451 — `_update_options_panel()`:** Mark selected speed and handedness in Options.
- **L454–L468 — `_update_memory_archive()`:** Show collected lore or a find-the-shard hint for each chamber.
- **L471–L485 — `_make_panel()`:** Shared panel style constructor.
- **L488–L500 — `_make_label()`:** Shared label constructor and typography.
- **L503–L531 — `_make_button()`:** Shared button constructor and state styling.
- **L534–L550 — `_show_menu()`:** Return to menu, hide overlays, and clear transient recording/input state.
- **L553–L554 — `_on_start_pressed()`:** Continue from the highest unlocked chamber.
- **L557–L591 — `_start_level()`:** Reset room, echo, gate, recording and input state; show gameplay.
- **L594–L610 — `_on_record_pressed()`:** Start recording or finish/send the current route.
- **L613–L658 — `_finish_recording()`:** Enforce minimum duration, Switch A endpoint, single relay or ordered multi-relay requirements, then release a valid echo.
- **L661–L662 — `_add_record_sample()`:** Append one time/position sample to the current take.
- **L665–L666 — `_track_passes_waypoint()`:** Return whether a route reaches a single checkpoint within its radius.
- **L669–L705 — `_is_relay_waypoint_linked()`:** Evaluate first crossing of all beacons so the linked indicator reflects valid path order.
- **L708–L722 — `_track_passes_waypoints_in_order()`:** Require each ordered waypoint to be visited after the preceding checkpoint.
- **L725–L757 — `_track_waypoint_progress()`:** Find the first eligible route progress where a sample-to-sample segment enters a checkpoint radius.
- **L760–L770 — `_update_player()`:** Apply keyboard/joystick motion, clamp to room bounds, and block crossing a closed gate.
- **L773–L785 — `_update_echo()`:** Advance echo interpolation and fade it after endpoint linger expires.
- **L788–L806 — `_check_sentinel_collision()`:** Return player to spawn; cancel and clear unfinished take to prevent a fake teleport.
- **L809–L822 — `_check_memory_shard_collection()`:** Collect each optional shard once, reveal lore, persist progress, and update Archive.
- **L825–L839 — `_update_timed_gate()`:** Tick Pulse Lock only during gameplay; timeout closes before the barrier, latches a missed attempt, or preserves power after crossing.
- **L842–L874 — `_check_puzzle_state()`:** Evaluate Switch A/B, timed-window/retry state and portal arrival.
- **L877–L897 — `_complete_level()`:** Guard against duplicate completion, increment completion/unlock state, save and show completion panel.
- **L900–L904 — `_on_next_level_pressed()`:** Advance to next chamber or restart campaign.
- **L907–L908 — `_on_replay_pressed()`:** Restart current chamber from completion UI.
- **L911–L912 — `_on_reset_pressed()`:** Restart current chamber.
- **L915–L928 — `_on_pause_pressed()`:** Toggle manual pause/resume and clear stale joystick state.
- **L931–L932 — `_open_help()`:** Show instructions.
- **L935–L937 — `_open_level_select()`:** Refresh labels and show chapter selector.
- **L940–L942 — `_on_chapter_selected()`:** Start only unlocked rooms.
- **L945–L950 — `_update_chapter_buttons()`:** Refresh chapter labels and disabled states.
- **L953–L960 — `_update_menu_progress()`:** Update room/memory totals, continue button and archive summary.
- **L963–L986 — `_update_hud()`:** Refresh labels, recording controls, echo state, and Pulse Lock countdown.
- **L989–L993 — `_load_progress()`:** Load campaign progress and collected shard indices.
- **L996–L999 — `_load_settings()`:** Load movement speed and joystick-side preferences.
- **L1002–L1005 — `_save_settings()`:** Persist preferences independently of campaign progress.
- **L1008–L1011 — `_save_progress()`:** Save progress and collected shards; warn on failure.
- **L1014–L1023 — `_draw()`:** Draw background then menu/gameplay and the paused overlay.
- **L1026–L1032 — `_draw_menu_art()`:** Draw menu decorations and placeholder robots.
- **L1035–L1103 — `_draw_room()`:** Draw switches, timed/standard gate, portal, linked-state relays, shard, hazard, route preview, actors and joystick hint.
- **L1107–L1124 — `_draw_echo_waypoint()`:** Draw amber unlinked or green linked Relay Beacon marker and label.
- **L1127–L1143 — `_draw_memory_shard()`:** Draw optional violet crystal.
- **L1146–L1154 — `_draw_switch()`:** Draw switch and active/inactive indicator.
- **L1157–L1168 — `_draw_gate()`:** Draw standard gate or amber timed-crossing state.
- **L1171–L1177 — `_draw_portal()`:** Draw powered/unpowered exit portal.
- **L1180–L1190 — `_draw_robot()`:** Draw procedural player/echo robot.
- **L1193–L1199 — `_draw_joystick()`:** Draw active touch joystick.
- **L1202–L1208 — `_draw_track_path()`:** Draw recorded samples as colored route line.

## 5. Exact line map — supporting scripts and tests

### `scripts/core/echo_track.gd` (60 lines, blob SHA `9a433129a0cb8b04d9ab55c0964aeb4683ddab3a`)
- **L1–L5:** `RefCounted` script header, purpose/comment about avoiding global `class_name` cache, and array of dictionaries shaped like `{"t": timestamp, "p": Vector2}`.
- **L8–L9:** Clear all recorded samples.
- **L12–L16:** Append sample; time is nonnegative and never earlier than the previous sample.
- **L19–L25:** Copy route using `get_script().new()` and append duplicate sample dictionaries; this is the specific Godot 4.4 self-reference fix.
- **L28–L31:** Route duration from the final timestamp; empty route is zero seconds.
- **L34–L59:** Position lookup: handles empty/before-first/after-last times, walks consecutive samples, linearly interpolates between points and handles tiny/duplicate timestamp spans.

### `scripts/data/level_catalog.gd` (199 lines, blob SHA `96b8808cf6944d1b66a703930e3972a59b837139`)
- **L1–L3:** RefCounted campaign catalog.
- **L4–L101:** Six room dictionaries. Static Bloom has `echo_waypoint` at L92; the other rooms don't require a relay.
- **L104–L111:** Clamped defensive-copy getter and campaign count.
- **L112–L116:** Canonical validation delegates to the reusable draft validator.
- **L117–L132:** Reject empty draft lists and blank/duplicate room names.
- **L133–L148:** Required schema, waypoint type, required shard/lore fields, Vector2 point checks and playfield bounds.
- **L150–L164:** Minimum spawn-to-A route and switch separation checks.
- **L166–L172:** Keep optional Memory Shards away from spawn and core switches.
- **L174–L186:** Validate sentinel tuning.
- **L177–L185:** Validate Relay Beacon separation from spawn, switches and shard when present.


### `scripts/data/progress_store.gd` (58 lines, blob SHA `c74c684bab3ca4e40b8ea49b995633b795c4974a`)
- **L1–L5:** `RefCounted` save boundary, `user://echopost_save.cfg`, schema version 2.
- **L8–L13:** Load result defaults, including an empty `PackedInt32Array` for shard indices.
- **L14–L23:** Load readable v1/v2 saves; retain/clamp campaign progress and normalize any shard array. V1 saves have no shard field, so their collection defaults to empty.
- **L26–L37:** Write version 2 and campaign fields plus the normalized shard collection.
- **L40–L50:** Accept packed arrays or ordinary arrays, filter invalid values, deduplicate and sort.
- **L53–L58:** Append one shard index only if it is nonnegative, within the supplied level count, and not already present.

### `scripts/data/settings_store.gd` (40 lines, blob SHA `fd2c065bf2e6807f645449327b247a9e60cf19f3`)
- **L1–L6:** RefCounted settings boundary, separate `user://echopost_settings.cfg` path, default speed 255 and supported speed presets 200/255/310.
- **L9–L20:** Load preference defaults when the file is missing/unreadable; otherwise load and normalize movement speed and read left-handed mode.
- **L23–L28:** Persist settings version, movement speed and joystick handedness separately from campaign progress.
- **L31–L39:** Normalize arbitrary speeds to the nearest supported preset.

### `tests/headless_smoke.gd` (167 lines, blob SHA `06ca403b64d9873a7fa37a31f9eaac5be1a69a38`)
- **L1–L10:** Test harness and preloaded data scripts/temp paths.
- **L15–L25:** Run tests and exit nonzero on assertion failure.
- **L28–L47:** Echo track timestamp order, interpolation, endpoint hold, script identity and copy independence.
- **L50–L76:** Verify six uniquely named/valid rooms, Memory Shard data and at least one relay room with a Vector2 waypoint.
- **L79–L95:** Invalid draft checks for duplicate names, route/switch spacing, sentinel speed and a relay waypoint outside the room.
- **L98–L102:** Error-fragment helper.
- **L106–L136:** Campaign save/load, shard normalization and v1 save compatibility.
- **L140–L160:** Control-preference defaults, persistence and speed normalization.
- **L163–L166:** Assertion helper.

### `tests/game_flow_smoke.gd` (382 lines, blob SHA `9cf7b31e88dad3ffca0670090d122c9501dc8a20`)
- **L1–L10:** Test harness/preloads.
- **L13–L14:** Defer the integration runner.
- **L17–L79:** Test chapter/archive/options UI, shards, lifecycle pause, recording cap/feedback, sentinel cancellation, reset cleanup, portal idempotency, relay pass/miss, route acceptance/rejection and gate activation.
- **L83–L98:** Lifecycle pause behavior.
- **L101–L116:** Eight-second recording cap.
- **L119–L130:** Too-short recording.
- **L133–L159:** Sentinel contact cancels the unfinished recording.
- **L162–L199:** Restart clears active tracks/timers/gate/input and works from pause.
- **L202–L225:** Portal completion idempotency and saved-progress restore.
- **L228–L243:** Scrollable chapter selector.
- **L247–L276:** Shard collection, lore and save restoration.
- **L280–L302:** Memory Archive UI and recovered/unfound rows.
- **L306–L335:** Options/speed/left-handed joystick behavior.
- **L339–L375:** Static Bloom Relay Beacon route acceptance/rejection; valid route crosses beacon between samples.
- **L378–L381:** Assertion helper.

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

- **Latest verified source:** [Godot CI run 95](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40394410577) passed both Godot 4.4.0 and 4.7.2 on commit `2cb03959726094c526140b3e63282f0440453e74`. It includes the Static Bloom Relay Beacon, malformed-waypoint validator test, direct-route rejection, and route-segment crossing acceptance test.
- **Options and Memory Archive:** run 82 passed the options/handedness UI and archive tests on both Godot versions.
- **Settings and Memory Shard persistence:** runs 81 and 65 passed settings persistence and version-1 campaign save compatibility respectively.
- **Device QA:** not performed; visual readability of Relay Beacon, route preview, memory collectibles, Archive and Options still needs manual testing in Godot/Android.
- **Android APK/export:** no APK built or attached; export templates, package ID, signing and device tests remain.
- **Campaign quality:** six rooms exist; only Static Bloom currently uses the new required waypoint mechanic.

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
7. **Mechanic coverage:** one recording slot and the two-switch gate remain core; Static Bloom now also requires a route through one Relay Beacon. Timed/toggle/sequence switches, multiple relays, moving platforms, checkpoints and multi-echo puzzles remain future work.
8. **Recording edge cases:** the minimum is now `MIN_RECORD_SECONDS = 0.7` at `scripts/game.gd:L16`; a too-short stop deliberately keeps recording active and tells the player to continue. Verify that this interaction is understandable on touch.
9. **Hazard edge cases:** collision now cancels an unfinished recording so it cannot include a fake teleport to spawn. Already-released echoes are separate; their behavior on sentinel contact still needs deliberate playtesting.
10. **Save migration/preferences:** schema version 2 persists Memory Shard indices and version-1 campaign progress remains loadable; speed/handedness use a separate v1 settings file. Future-version behavior and cloud saves are not designed.
11. **Level validation:** catches schema/name/position/spacing and sentinel tuning errors, but it is not a pathfinding solver and does not prove portal reachability or fairness against the sentinel's phase.
12. **No online features or monetization:** no accounts, backend, community route uploads, cloud saves, ads, analytics or payments are implemented. Do not add these before offline puzzle quality, privacy and moderation are planned.

## 8. Prioritized next steps

### P0 — Keep the project compiling and the handoff current
- [x] Fix Godot 4.4 `Identifier not found: EchoTrack` self-reference in `scripts/core/echo_track.gd:L19–L25`.
- [x] Add a regression assertion for preloaded script identity at `tests/headless_smoke.gd:L42–L47`.
- [x] Verify the code fix and regression test in [run 21](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40385871675): Godot 4.4.0 and 4.7.2 both passed.
- [x] Verify restart/portal flows (run 33), route preview (run 34), six-room chapter UI (run 42), room validation (run 49), sentinel interruption (run 54), and Memory Shards plus v1 save compatibility (run 65) on both Godot versions.
- [x] Verify the Relay Beacon requirement, invalid-waypoint validator, and between-sample route-crossing test in run 95 on both Godot versions.
- [ ] Ask for / perform a local pull and open the project in the user's Godot 4.4 editor to inspect the live route preview and confirm visuals on the actual machine.
- [x] Verify Memory Archive and Options UI, speed presets, and left-handed joystick region on both Godot versions in run 82.
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
- [x] Add movement-speed presets and left-handed joystick placement with separate persistent preferences.
- [ ] Expand accessibility: color-independent state cues, reduced motion, audio/haptics, localization and safe-area support.
- [ ] Add visible route-preview quality and better feedback for rejected/too-short routes.
- [ ] Manually play all rooms in Godot desktop and test exported debug builds on at least one real Android device.

### P3 — Build a real campaign / refactor safely
- [ ] Create a reusable room scene/controller separation and richer authored-room schema.
- [ ] Expand from six layouts to 12–20 authored chambers with new puzzle mechanics beyond route geometry, patrol timing and the first Relay Beacon checkpoint.
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
5. Refresh every affected line number after changes. The line map in section 4 is keyed to `scripts/game.gd` blob SHA `d8accd3fe98eb478c0720371b6f8e4f93f901421`; section 5 records current supporting-script and test blob SHAs. If any of those blob SHAs differ after edits, regenerate the corresponding section.
6. Update `PROJECT_PROGRESS.md` in the same development pass as source changes. Record the new commit(s), source hashes/line references, CI URL/result and what the next session should do.
7. Keep this game offline-capable and dependency-light. Never add network accounts, telemetry, uploads, payment or ads as an incidental code change.
8. Don't produce an APK/release claim unless an actual export and install verification were completed.

---

*Handoff note: this file is written to make future work resumable from concrete repository state, not to declare completion. The next session's first action should be checking the newest workflow run, then continue with P1 test coverage before beginning larger gameplay/content changes.*
