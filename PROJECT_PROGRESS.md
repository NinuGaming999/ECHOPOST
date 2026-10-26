# ECHOPOST — PROJECT PROGRESS / HANDOFF

> **This file is the continuity record for future ECHOPOST development.** Read it before changing code. The game is deliberately an unfinished long-running project; do not treat the current ten-room prototype as complete. After every meaningful code, test, gameplay, or build change, update this file with what changed, why, exact file/line references, current verification results, and the next actionable tasks.

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
**All-memory signal reward commit:** `dd11471aea0f87399f7a816304daaba3ac68df4b`  
**Dynamic archive count commit:** `f900f967fa83f618e3615f423a9ef613f85bd71a`  
**All-memory reward test commit:** `04be8ef22ca631b000d14b541bbce2ca0426b5b8`  
**Archive count assertion commit:** `7531407e22c8a8068b4d62df90c190272713668d`  
**Main controller source blob for the exact line map below:** `81b5c3c8703fdad0d92cf7c66d91ff96b3c94053` (1217 lines)  
**Triune Relay level-data commit:** `48aa2ccd090f7cda6b74c8d8a9a0bbdd016d9e3d`  
**Ten-room data-schema test commit:** `76cc6722aea77edc5bba938aa36318271645afc2`  
**Three-relay gameplay test commit:** `9f08fae5aa9a7a8588a01cae3dcad86cad03ca55`  
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

The current source includes ten authored chamber layouts:
- **The First Echo:** basic teach-the-mechanic chamber.
- **Long Memory:** roaming sentinel and a more distant Switch B.
- **Split Signal:** faster/larger sentinel movement and opposite-side switches.
- **Fractured Lane:** a longer diagonal route under a wide patrol.
- **Crosscurrent:** switches in opposite corners and a faster midline patrol.
- **Static Bloom:** one required Relay Beacon before Switch A.
- **Chorus Route:** two Relay Beacons must be crossed in order before Switch A.
- **Pulse Lock:** a 3.5-second gate-crossing window, with retry/re-arm behavior if the player misses it.
- **Latch Protocol:** Switch B is a toggle; after activating it, the player can leave the switch and cross the gate.
- **Triune Relay:** three Relay Beacons must be crossed in order before Switch A.

The first five rooms teach the two-switch echo mechanic with varied geometry/patrols. Static Bloom introduces a single required gold Relay Beacon; Chorus Route requires two beacons in order; Pulse Lock adds a timed crossing and retry rule; Latch Protocol adds a toggle switch; Triune Relay extends ordered route planning to three checkpoints. Relay tests check line segments between samples, so a crossing between samples is valid. Ten rooms are still a prototype, not a finished campaign.

The look is currently drawn procedurally in `scripts/game.gd`; the SVG app icon is the main external art asset. Procedural visuals keep the project importable without an asset pack but are placeholder art, not final art. Each chamber also has one optional Memory Shard that reveals a short courier-network lore fragment.

## 2. Latest work in this development pass

### Triune Relay: tenth chamber and three-checkpoint ordered route
**Changed:** `scripts/data/level_catalog.gd`, `tests/headless_smoke.gd`, `tests/game_flow_smoke.gd`, README, design, roadmap and build-status documentation.

- `scripts/data/level_catalog.gd:L153–L169`: adds the tenth room, **Triune Relay**, with a long diagonal route and three required relay coordinates. The room reuses the already-general ordered-waypoint mechanism; no special-case gameplay branch was added.
- `scripts/data/level_catalog.gd:L252–L274`: existing validator checks every ordered waypoint is a `Vector2`, in bounds, separated from objectives/shard, and sufficiently far from other waypoints. The new room passes this same validator.
- `scripts/game.gd:L711–L725`: the existing `_track_passes_waypoints_in_order()` iterates the authored waypoint array, so it enforces Relay 1 → Relay 2 → Relay 3 automatically. `L672–L708` derives each beacon's linked visual from first-crossing order.
- `tests/headless_smoke.gd:L50–L96`: campaign tests now require at least ten rooms and assert a named three-relay room exists; canonical catalog validation also catches bad geometry.
- `tests/game_flow_smoke.gd:L27–L30`: runs the new test before the Pulse Lock suite. `L483–L539`: tests that Relay 3 before Relay 2 is rejected, then verifies the full Relay 1 → Relay 2 → Relay 3 → Switch A route is accepted and all three markers show linked.
- Level-data commit: `48aa2ccd090f7cda6b74c8d8a9a0bbdd016d9e3d`; data-test commit: `76cc6722aea77edc5bba938aa36318271645afc2`; gameplay-test commit: `9f08fae5aa9a7a8588a01cae3dcad86cad03ca55`.
- [Godot CI run 147](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40400099108) passed on both Godot 4.4.0 and 4.7.2, including project import/parse, all data tests, existing gameplay tests, and the new three-relay acceptance/rejection test.

The campaign now has ten rooms, but it is still an early prototype. The new room is logic-tested; its visual readability and actual touch-control difficulty still need manual playtesting.

### All-memory restored-signal reward and dynamic Archive count
**Changed:** `scripts/game.gd`, `tests/game_flow_smoke.gd`, README and design/build/roadmap documentation.

- `scripts/game.gd:L812–L829`: collecting the final uncollected Memory Shard changes the status from the ordinary `MEMORY:` lore message to `SIGNAL RESTORED` plus the final shard's lore. This reward is optional and does not affect gates, room completion or unlocks.
- `scripts/game.gd:L454–L471`: Memory Archive now shows `SIGNAL RESTORED — ALL MEMORIES FOUND` when all room shards are collected; otherwise it shows the live recovered/total count.
- `scripts/game.gd:L313–L372`: the Archive's initial status placeholder uses `LEVELS.size()` instead of a hard-coded six, keeping the UI compatible as the campaign grows.
- `tests/game_flow_smoke.gd:L287–L316`: `_test_all_memories_restore_signal()` simulates collecting the final room's shard through the real pickup path, checks the message/Archive reward, then restores the player's original save values.
- `tests/game_flow_smoke.gd:L319–L347`: Memory Archive UI test covers the normal count or restored-signal state and asserts the displayed denominator matches the live room count.
- The reward source commit is `dd11471aea0f87399f7a816304daaba3ac68df4b`; the dynamic archive placeholder is `f900f967fa83f618e3615f423a9ef613f85bd71a`; the regression coverage is in `04be8ef22ca631b000d14b541bbce2ca0426b5b8` and `7531407e22c8a8068b4d62df90c190272713668d`.
- [Godot CI run 140](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40398632047) passed on both Godot 4.4.0 and 4.7.2, including the full final-shard pickup path and Archive status checks.

This is an optional exploration reward, not a paid gate. All ten rooms remain completable without collecting any Memory Shard.

### Ordered Relay feedback and Pulse Lock timed gate
**Changed:** `scripts/data/level_catalog.gd`, `scripts/game.gd`, `tests/headless_smoke.gd`, and `tests/game_flow_smoke.gd`, plus README/design/roadmap/build-status documentation.

- `scripts/data/level_catalog.gd:L4–L166`: ten authored room definitions; Chorus Route contains two ordered `echo_waypoints`, Triune Relay contains three ordered `echo_waypoints`, Latch Protocol sets `plate_b_mode: "toggle"`, and Pulse Lock defines `gate_open_seconds: 3.5`.
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
- `tests/headless_smoke.gd:L50–L96` and `L99–L120`: verify ten rooms, single/two-/three-relay data, toggle/timed-gate schema, malformed waypoint lists and timer bounds.
- `tests/game_flow_smoke.gd:L387–L438`: test wrong/valid ordered-relay routes and linked-state visual logic.
- `tests/game_flow_smoke.gd:L427–L478`: Chorus Route rejects reversed order and accepts the correct two-relay route. `L483–L539` tests Triune Relay's three-checkpoint route rejection/acceptance and linked state. `L543–L595` exercises Pulse Lock timer start, real-frame countdown, timeout, retry latch, rearm and persistent power after crossing.
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
### Six-room campaign milestone and scrollable chapter selector (historical milestone)
**Changed:** `scripts/data/level_catalog.gd`, `scripts/game.gd`, `tests/headless_smoke.gd`, and `tests/game_flow_smoke.gd`.

- `scripts/data/level_catalog.gd:L4–L101` now contains six room definitions: The First Echo, Long Memory, Split Signal, Fractured Lane, Crosscurrent, and Static Bloom. New rooms vary diagonal route length, opposing-corner switches, hazard height, sentinel sweep width/speed, and accent color.
- `scripts/data/level_catalog.gd:L104–L111` provides the clamped copy accessor/count; `L117–L198` validates room keys, positions, linger durations, shard/waypoint placement and hazard fields.
- `scripts/game.gd:L279–L307` creates a `ScrollContainer` named `ChapterScroll` with a `VBoxContainer` list named `ChapterList`. Each level gets a button; the Back button stays below the viewport and does not overlap later rooms.
- `tests/headless_smoke.gd:L50–L93` now requires at least eight chambers, validates the room schema including relay/timed-gate data, checks non-empty unique names and preserves the defensive-copy assertion.
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
| `scripts/game.gd` | Main controller, menu/HUD construction, movement, echo recording/playback, route checkpoint validation, Pulse Lock timer/retry, toggle-switch puzzle loop, sentinel, Memory Shard collection/archive, control preferences, save flow and procedural rendering. **1217 lines in the current source snapshot; refactor incrementally after tests protect behavior.** |
| `scripts/core/echo_track.gd` | Data-only `RefCounted` script loaded through preloaded script resources; avoids global `class_name` lookup; stores points, clamps timestamps to nondecreasing order, copies tracks, returns duration, interpolates route positions, and holds endpoint outside the timestamp range. |
| `scripts/data/level_catalog.gd` | Ten room dictionaries, optional shard positions/lore, single/two-/three-relay requirements, toggle-switch and Pulse Lock settings, defensive-copy accessor and canonical/draft validator for schema, names, spacing, bounds and hazard/timer tuning. |
| `scripts/data/progress_store.gd` | Version-2 local save boundary (`user://echopost_save.cfg`) using `ConfigFile`; preserves v1 campaign progress and stores normalized Memory Shard room indices. |
| `scripts/data/settings_store.gd` | Separate preference store (`user://echopost_settings.cfg`) for speed and joystick handedness, defaulting safely and normalizing unsupported movement values. |
| `tests/headless_smoke.gd` | Data tests for echo interpolation/copying, ten-room/shard/waypoint/toggle schema, three-relay room presence, malformed-draft validation, v2 shard persistence/sanitization, v1-save compatibility, campaign clamping and isolated control-preference persistence/normalization. |
| `tests/game_flow_smoke.gd` | Main-scene integration tests for chapter/archive/options UI, Memory Shards, speed presets/handedness, lifecycle pause, record cap/feedback, sentinel cancellation, reset, portal idempotency, single/two-/three-relay pass/miss/order/linked state, and timed-gate behavior. |
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

This function index matches source blob SHA `81b5c3c8703fdad0d92cf7c66d91ff96b3c94053` (1217 lines). It is authoritative for the current source. Older code-line references inside historical feature notes refer to the source revision at the time.

- **L1–L4:** Script header and procedural-art note.
- **L6:** `ScreenState` enum (MENU, PLAYING, PAUSED, COMPLETE).
- **L8–L22:** Playfield bounds, player/record timers, EchoTrack/level/progress/settings preloads.
- **L24–L31:** Campaign progress, collected Memory Shards, movement-speed/handedness preferences and current room data.
- **L33–L48:** Player/echo positions, tracks, recording timers, standard/timed-gate state and sentinel clock.
- **L50–L54:** Touch/mouse joystick state.
- **L56–L80:** Menu/HUD, Archive/Options, labels, buttons and chapter references.
- **L85–L89 — `_notification()`:** Handle application suspension/focus loss and delegate to lifecycle pause.
- **L92–L102 — `_pause_for_lifecycle()`:** Pause only active play, clear stale joystick input, preserve recording state, and refresh HUD.
- **L105–L113 — `_ready()`:** Set full-screen layout, seed decoration, load progress/settings, construct UI, and show the menu.
- **L116–L140 — `_process()`:** Advance gameplay only while PLAYING; clamp delta/recording time, move/sample, update echo/hazard/shards/timed gate/puzzle, and redraw.
- **L143–L173 — `_input()`:** Translate touchscreen and mouse gestures into virtual joystick input.
- **L176–L183 — `_is_joystick_area()`:** Choose virtual joystick hit area for selected handedness while preserving bottom-button space.
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
- **L454–L471 — `_update_memory_archive()`:** Show collected lore or discovery hints, progress, and the restored-signal reward.
- **L474–L488 — `_make_panel()`:** Shared panel style constructor.
- **L491–L503 — `_make_label()`:** Shared label constructor and typography.
- **L506–L534 — `_make_button()`:** Shared button constructor and state styling.
- **L537–L553 — `_show_menu()`:** Return to menu, hide overlays, and clear transient recording/input state.
- **L556–L557 — `_on_start_pressed()`:** Continue from the highest unlocked chamber.
- **L560–L594 — `_start_level()`:** Reset room, echo, gate, recording and input state; show gameplay.
- **L597–L613 — `_on_record_pressed()`:** Start recording or finish/send the current route.
- **L616–L661 — `_finish_recording()`:** Enforce minimum duration, Switch A endpoint, single relay or ordered multi-relay requirements, then release a valid echo.
- **L664–L665 — `_add_record_sample()`:** Append one time/position sample to the current take.
- **L668–L669 — `_track_passes_waypoint()`:** Return whether a route reaches a single checkpoint within its radius.
- **L672–L708 — `_is_relay_waypoint_linked()`:** Evaluate first crossings so linked indicators reflect valid relay order.
- **L711–L725 — `_track_passes_waypoints_in_order()`:** Require each ordered waypoint to be visited after the preceding checkpoint.
- **L728–L760 — `_track_waypoint_progress()`:** Find the first eligible route progress where a sample-to-sample segment enters a checkpoint radius.
- **L763–L773 — `_update_player()`:** Apply keyboard/joystick motion, clamp to room bounds, and block crossing a closed gate.
- **L776–L788 — `_update_echo()`:** Advance echo interpolation and fade it after endpoint linger expires.
- **L791–L809 — `_check_sentinel_collision()`:** Return player to spawn; cancel and clear unfinished take to prevent a fake teleport.
- **L812–L829 — `_check_memory_shard_collection()`:** Collect each optional shard once, reveal lore, persist progress, and announce SIGNAL RESTORED when the last memory is found.
- **L832–L846 — `_update_timed_gate()`:** Tick Pulse Lock only during gameplay; timeout closes before the barrier, latches a missed attempt, or preserves power after crossing.
- **L849–L881 — `_check_puzzle_state()`:** Evaluate Switch A/B, timed-window/retry state and portal arrival.
- **L884–L904 — `_complete_level()`:** Guard against duplicate completion, increment completion/unlock state, save and show completion panel.
- **L907–L911 — `_on_next_level_pressed()`:** Advance to next chamber or restart campaign.
- **L914–L915 — `_on_replay_pressed()`:** Restart current chamber from completion UI.
- **L918–L919 — `_on_reset_pressed()`:** Restart current chamber.
- **L922–L935 — `_on_pause_pressed()`:** Toggle manual pause/resume and clear stale joystick state.
- **L938–L939 — `_open_help()`:** Show instructions.
- **L942–L944 — `_open_level_select()`:** Refresh labels and show chapter selector.
- **L947–L949 — `_on_chapter_selected()`:** Start only unlocked rooms.
- **L952–L957 — `_update_chapter_buttons()`:** Refresh chapter labels and disabled states.
- **L960–L967 — `_update_menu_progress()`:** Update room/memory totals, continue button and archive summary.
- **L970–L993 — `_update_hud()`:** Refresh labels, recording controls, echo state, and Pulse Lock countdown.
- **L996–L1000 — `_load_progress()`:** Load campaign progress and collected shard indices.
- **L1003–L1006 — `_load_settings()`:** Load movement speed and joystick-side preferences.
- **L1009–L1012 — `_save_settings()`:** Persist preferences independently of campaign progress.
- **L1015–L1018 — `_save_progress()`:** Save progress and collected shards; warn on failure.
- **L1021–L1030 — `_draw()`:** Draw background then menu/gameplay and the paused overlay.
- **L1033–L1039 — `_draw_menu_art()`:** Draw menu decorations and placeholder robots.
- **L1042–L1110 — `_draw_room()`:** Draw switches, timed/standard gate, portal, linked-state relays, shard, hazard, route preview, actors and joystick hint.
- **L1114–L1131 — `_draw_echo_waypoint()`:** Draw amber unlinked or green linked Relay Beacon marker and label.
- **L1134–L1150 — `_draw_memory_shard()`:** Draw optional violet crystal.
- **L1153–L1161 — `_draw_switch()`:** Draw switch and active/inactive indicator.
- **L1164–L1175 — `_draw_gate()`:** Draw standard gate or amber timed-crossing state.
- **L1178–L1184 — `_draw_portal()`:** Draw powered/unpowered exit portal.
- **L1187–L1197 — `_draw_robot()`:** Draw procedural player/echo robot.
- **L1200–L1206 — `_draw_joystick()`:** Draw active touch joystick.
- **L1209–L1215 — `_draw_track_path()`:** Draw recorded samples as colored route line.

## 5. Exact line map — supporting scripts and tests

### `scripts/core/echo_track.gd` (60 lines, blob SHA `9a433129a0cb8b04d9ab55c0964aeb4683ddab3a`)
- **L1–L5:** RefCounted header, class-cache independence note, and timestamp/position sample array.
- **L8–L9:** Clear samples.
- **L12–L16:** Add nonnegative timestamp while guaranteeing timestamps never move backwards.
- **L19–L25:** Copy samples through `get_script().new()`; no global `EchoTrack` lookup, preventing the Godot 4.4 compile error.
- **L28–L31:** Return route duration.
- **L34–L59:** Resolve position before/after route, interpolate between ordered points, and tolerate near-duplicate timestamps.

### `scripts/data/level_catalog.gd` (306 lines, blob SHA `2cdbd4de93b00be9da42385207756b51ddc70cc6`)
- **L1–L3:** RefCounted catalog and purpose.
- **L4–L152:** First nine room definitions, ending with Latch Protocol's toggle-style Switch B.
- **L153–L169:** Triune Relay's tenth-room definition, including three ordered relay coordinates and optional Memory Shard lore.
- **L171–L179:** Defensive-copy level getter, count helper and validation entry points.
- **L180–L196:** Validate nonempty campaigns, unique/nonblank names, required schema keys, core Vector2 positions, lore text and positive echo linger.
- **L197–L214:** Validate single relay type, toggle-mode values, timed-gate duration type/range, and ordered-waypoint container type.
- **L215–L247:** Validate room bounds, spawn-to-A and A-to-B separation, and Memory Shard/single-relay spacing from objectives.
- **L248–L274:** Validate ordered relay arrays, each waypoint's type/bounds/objective separation, and separation between relay markers.
- **L275–L305:** Validate sentinel patrol keys, height, sweep amplitude and speed.

### `scripts/data/progress_store.gd` (58 lines, blob SHA `c74c684bab3ca4e40b8ea49b995633b795c4974a`)
- **L1–L5:** Local campaign save boundary and schema version 2.
- **L8–L23:** Load/default/clamp campaign values and read collected shard indices, preserving version-1 progress.
- **L26–L37:** Save version, unlocked room, completion count and normalized shard data.
- **L40–L50:** Normalize a shard collection, drop invalid/duplicate/out-of-campaign indices and sort.
- **L53–L58:** Append an in-range shard index only once.

### `scripts/data/settings_store.gd` (40 lines, blob SHA `fd2c065bf2e6807f645449327b247a9e60cf19f3`)
- **L1–L6:** Separate local settings path, schema version and supported movement presets.
- **L9–L20:** Load defaults or read/normalize saved speed and joystick handedness.
- **L23–L28:** Persist control settings independently from campaign progress.
- **L31–L39:** Normalize the requested speed to a supported preset.

### `tests/headless_smoke.gd` (194 lines, blob SHA `4b929b787d5e50d511e8b9c00daaaeca1f11acf1`)
- **L1–L12:** Test runner/preloads and isolated temporary save/settings paths.
- **L15–L25:** Run grouped tests and exit nonzero on assertion failure.
- **L28–L47:** Timestamp order, interpolation, endpoint hold, preloaded-script identity and copy independence.
- **L50–L96:** Check ten unique rooms, shard/lore fields, single/two-/three-relay rooms, and timed-gate configuration.
- **L99–L120:** Submit intentionally invalid room drafts and assert validation errors for duplicate names, route geometry, sentinel parameters, out-of-bounds/mistyped relays and invalid timed-gate durations.
- **L123–L127:** Search error strings by fragment.
- **L131–L161:** Save/load campaign progress, sanitize shard indices and verify v1 save compatibility.
- **L165–L185:** Verify settings defaults, preference persistence, handedness and speed normalization.
- **L188–L191:** Assertion helper.

### `tests/game_flow_smoke.gd` (600 lines, blob SHA `c1143cab363248fd37762563af2f70cc8282a89c`)
- **L1–L10:** Integration harness, main scene, relay/level/progress preloads.
- **L13–L14:** Defer integration test entry point.
- **L17–L82:** Run UI/shards/options, single/two-/three-relay, lifecycle pause, recording limit/feedback, sentinel/reset/portal, and timed gate suite.
- **L86–L104:** Verify pause preserves recording and freezes recording/timed-gate timer.
- **L107–L122:** Exercise real frame loop at the exact eight-second recording boundary.
- **L125–L136:** Too-short stop keeps recording active, creates no echo and explains the remedy.
- **L139–L165:** Sentinel reset and cancellation of interrupted takes.
- **L168–L205:** Restart clears active recording/echo/timers/gate/input and works from pause.
- **L208–L231:** Powered portal completion is idempotent and test restores saved progress.
- **L234–L249:** Chapter list uses scrollable layout for all authored rooms.
- **L253–L282:** Memory Shard pickup, lore message, save and test-progress restoration.
- **L287–L316:** Collect final shard through pickup path and verify restored-signal reward; restore user's original campaign values afterward.
- **L319–L347:** Archive status, recovered/unfound lore, all-memories reward, and dynamic room count.
- **L351–L380:** Options integration for speed presets and right/left joystick sides.
- **L384–L423:** Static Bloom single Relay Beacon requirement and segment-crossing acceptance.
- **L427–L478:** Chorus Route rejects reverse order, accepts correct order, and verifies linked visual state.
- **L483–L539:** Triune Relay rejects an out-of-order three-relay route, accepts Relay 1 → Relay 2 → Relay 3 → Switch A, and verifies all three linked states.
- **L543–L595:** Pulse Lock timer start, real-frame countdown, pause freeze, timeout, retry re-arm and powered exit after crossing.
- **L598–L601:** Shared assertion helper.

### `scenes/main.tscn` (13 lines)
- **L1–L3:** Scene resource/script declaration.
- **L5–L13:** Full-rect Control root bound to `scripts/game.gd`.

### `project.godot` (43 lines)
- **L1–L10:** Project metadata, icon, main scene and feature declarations.
- **L12–L18:** 1280×720 viewport/window settings, canvas stretch mode and orientation.
- **L20–L24:** Compatibility renderer/background configuration.
- **L26–L43:** WASD/arrow input map.

### `.github/workflows/godot-checks.yml` (38 lines)
- **L1–L19:** Push/PR/manual triggers, permissions, runner and Godot 4.4.0/4.7.2 matrix.
- **L21–L29:** Checkout and Godot installation.
- **L30–L38:** Import/parse project and run both smoke-test scripts.

### `RUN_TESTS.bat` (25 lines)
- **L1–L10:** Detect Godot on PATH or print invocation help.
- **L12–L20:** Run data and gameplay tests and return success.
- **L21–L25:** Report failure and return a nonzero exit code.

## 6. Current verification status — be precise

- **Latest passing code/test run:** [Godot CI run 147](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40400099108) passed on both Godot 4.4.0 and 4.7.2. It includes the tenth room, three-relay catalog assertion, and gameplay acceptance/rejection test for Triune Relay, along with all previous data/game-flow tests.
- **Triune Relay:** the wrong order Relay 1 → Relay 3 → Relay 2 → Switch A is rejected; the correct Relay 1 → Relay 2 → Relay 3 → Switch A route is accepted and each marker becomes linked. CI run 147 passed these assertions.
- **Previous verification:** run 140 passed the all-memory restored-signal reward; run 122 passed Pulse Lock countdown, pause freeze, timeout closure, retry latch/re-arm, and portal power after crossing.
- **Source hashes:** current `scripts/game.gd` blob SHA is `81b5c3c8703fdad0d92cf7c66d91ff96b3c94053` (1217 lines); current `scripts/data/level_catalog.gd` blob SHA is `2cdbd4de93b00be9da42385207756b51ddc70cc6` (306 lines); current `tests/headless_smoke.gd` blob SHA is `4b929b787d5e50d511e8b9c00daaaeca1f11acf1` (194 lines); current gameplay-test blob SHA is `c1143cab363248fd37762563af2f70cc8282a89c` (600 lines). Sections 4 and 5 are keyed to these current files.
- **Device QA:** not performed by this assistant. The game has not been manually run in the user's Godot editor or on a physical Android device during this pass.
- **Android export:** no APK built or attached. Android export preset, package identity, export templates, SDK/JDK, signing and real-device testing remain.
- **Quality caveat:** automated tests verify logic, not visual clarity or whether the 3.5-second timed crossing feels fair on touch controls. Playtesting Pulse Lock at slow/normal/fast speeds remains next.

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
3. **Small content set:** ten room dictionaries and ten optional Memory Shards now exist, but the core two-switch pattern is still the foundation and there is no full campaign or final narrative ending.
4. **Procedural placeholder visuals:** no authored robot animations, environmental tilesets, VFX or transition animations.
5. **No sound:** recording, rejected route, sentinel hits, gate opening and portal have text/visual feedback only. No SFX, music, mixer, or audio options exist.
6. **Pause behavior needs real device QA:** lifecycle logic and timer freeze are headlessly tested, but actual Android app-switch lifecycle/focus behavior are unverified. The player must tap RESUME after returning.
7. **Mechanic coverage:** one recording slot and the two-switch gate remain core; Static Bloom requires one relay, Chorus Route two ordered relays, Triune Relay three ordered relays, Pulse Lock a timed gate, and Latch Protocol a toggle Switch B. Moving platforms, checkpoints and multi-echo puzzles remain future work.
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
- [x] Verify ordered-relay order/linked-state regression in [run 119](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40396769674) on both Godot versions.
- [x] Verify Pulse Lock countdown visuals/frame ticking, timer freeze during pause, timeout, retry latch and successful crossing in [run 122](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40397091984) on both Godot versions.
- [x] Verify the all-shards restored-signal reward and dynamic Memory Archive count in [run 140](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40398632047) on both Godot versions.
- [x] Add the tenth chamber Triune Relay and verify a three-relay route is rejected out of order and accepted in order in [run 147](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40400099108) on both Godot versions.
- [ ] Ask for / perform a local pull and open the project in the user's Godot 4.4 editor to inspect the live route preview and confirm visuals on the actual machine.
- [x] Verify Memory Archive and Options UI, speed presets, and left-handed joystick region on both Godot versions in run 82.
- [x] Update this progress file, current source/test blob hashes, and exact line maps for Triune Relay.
- [ ] Every further code change must update this progress file and refresh affected line maps.

### P1 — Core mechanic test coverage
- [x] Add an integration test for automatic recording stop and verify the echo route is exactly 8.0 seconds.
- [x] Test the too-short recording interaction: no echo is created, recording remains active, and the message says to keep recording.
- [x] Test sentinel contact resets the player to the room spawn and displays feedback.
- [x] Decide and test sentinel interruption behavior: contact cancels/clears an unfinished recording and reports “recording lost”; an already released echo is not treated as an unfinished take.
- [x] Test restart while recording and echo playback are active, and verify restart from PAUSED clears state.
- [x] Test powered portal completion and ensure the completion count increments exactly once while the test restores the original save values.
- [ ] Test lifecycle focus-out as well as application-paused notification; physical mobile app switching still needs manual QA.
- [ ] Play Pulse Lock at slow, normal and fast movement speeds and decide whether its 3.5-second window is fair.
- [x] Expand the level validator for room names, route/switch spacing, sentinel tuning and Memory Shard placement/lore.
- [x] Add one optional Memory Shard per room, a short lore message, progress counter, save schema v2, v1 save compatibility, collection/persistence regression tests, and a non-blocking all-shards restored-signal reward.

### P2 — Mobile usability before adding lots of content
- [ ] Manually inspect scrollable chapter selection and the live route preview on the user's Godot editor/phone; then review narrow/tall aspect ratios, safe areas and landscape touch reach.
- [x] Add movement-speed presets and left-handed joystick placement with separate persistent preferences.
- [ ] Expand accessibility: color-independent state cues, reduced motion, audio/haptics, localization and safe-area support.
- [ ] Add visible route-preview quality and better feedback for rejected/too-short routes.
- [ ] Manually play all rooms in Godot desktop and test exported debug builds on at least one real Android device.

### P3 — Build a real campaign / refactor safely
- [ ] Create a reusable room scene/controller separation and richer authored-room schema.
- [ ] Expand from eight layouts to 12–20 authored chambers with new puzzle mechanics beyond route geometry, patrol timing, ordered relay checkpoints and the first timed gate.
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
5. Refresh every affected line number after changes. The line map in section 4 is keyed to `scripts/game.gd` blob SHA `81b5c3c8703fdad0d92cf7c66d91ff96b3c94053`; section 5 records current supporting-script and test blob SHAs. If any of those blob SHAs differ after edits, regenerate the corresponding section.
6. Update `PROJECT_PROGRESS.md` in the same development pass as source changes. Record the new commit(s), source hashes/line references, CI URL/result and what the next session should do.
7. Keep this game offline-capable and dependency-light. Never add network accounts, telemetry, uploads, payment or ads as an incidental code change.
8. Don't produce an APK/release claim unless an actual export and install verification were completed.

---

*Handoff note: this file is written to make future work resumable from concrete repository state, not to declare completion. The next session's first action should be checking the newest workflow run, then manually tune Pulse Lock if possible before designing another new mechanic.*
