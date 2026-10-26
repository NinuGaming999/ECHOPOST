# ECHOPOST — PROJECT PROGRESS / HANDOFF

> **This file is the continuity record for future ECHOPOST development.** Read it before changing code. The game is deliberately an unfinished long-running project; do not treat the current twelve-room prototype as complete. After every meaningful code, test, gameplay, or build change, update this file with what changed, why, exact file/line references, current verification results, and the next actionable tasks.

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
**Main controller source blob for the exact line map below:** `e44cb8d66c78b5a0cdb0253f88d8900b57d6d58d` (1490 lines)  
**Triune Relay level-data commit:** `48aa2ccd090f7cda6b74c8d8a9a0bbdd016d9e3d`  
**Initial ten-room schema-test commit (before Fracture Clock):** `76cc6722aea77edc5bba938aa36318271645afc2`  
**Three-relay gameplay test commit:** `9f08fae5aa9a7a8588a01cae3dcad86cad03ca55`  
**Fracture Clock level-data commit:** `ad810770fb2119048497d7b147aa3732a78215c9`  
**Fracture Clock schema-test commit:** `f5eb3f6b847ff2370f54993e77608a68185cb351`  
**Fracture Clock gameplay-test commit:** `4413bcf1a8bdadc3ec14de6ca8fac5433500a849`  
**Relay catalog-test correction:** `9c31dd95c97f1e01b1647fe79a0d02c61bd56066`  
**Timed-gate progress bar code commit:** `2a41dc62625519760775331a72dbdb2c9a0dd4f7`  
**Timed-gate ratio regression-test commit:** `2eca67fde3ab69e52b17ae6151652bc4eea9c2eb`  
**Dynamic relay rejection feedback commit:** `cea513b16e1c849942236c033a504e47048aabb6`  
**Relay feedback regression-test correction:** `9eba2674ae7e64d78eb5011649182722b0bfbd08`  
**Latch Protocol gameplay implementation:** `4dd340a159e818aa2f0ad0cf042163b6b97ceecc`  
**Latch Protocol integration tests:** `8a057283461d7e7a4663e9c4ddedc43aa92fff7c`  
**Latch echo-settled prerequisite commit:** `93d04401105fab9c89e1f5f90fc1865c1df605f7`  
**Latch playback-prerequisite test commit:** `3218a6beeef7506ad56b3d8f5e04ac9f8db7f68e`  
**Dead Air Protocol level commit:** `a2ceca756626f94898a78e1258c452c33096f603`  
**Dead Air Protocol schema-test commit:** `b841ebfd189911ea7454236816ffe7d83b35b00f`  
**Dead Air Protocol gameplay-test commit:** `918fe8ce829d7b922afeae60a439253c027ec7ff`  
**Dead Air Protocol harder gate/layout commit:** `9cb45fa8df21110acb69decec24300216d4c6b6c`  
**Dead Air gate-distance schema assertion:** `8c4827d628f3d1f936f187dd16b3998677007b17`  
**Dead Air timer expectation regression fix:** `25c10df85b2ae529ec0b8ef47c0249983d17e482`
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

The current source includes twelve authored chamber layouts:
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
- **Fracture Clock:** combines three ordered relays with a 4.5-second timed gate crossing.
- **Dead Air Protocol:** four ordered relays, a fast sentinel that can erase the recording, 6.5 seconds of echo linger, Switch B farther back at x=850, and a 1.8-second gate window.

The first five rooms teach the two-switch echo mechanic with varied geometry/patrols. Static Bloom introduces a single required gold Relay Beacon; Chorus Route requires two beacons in order; Pulse Lock adds a timed crossing and retry rule; Latch Protocol adds a toggle switch; Triune Relay extends ordered route planning to three checkpoints; Fracture Clock combines the three-relay sequence with a timed crossing; Dead Air Protocol combines four relays, active sentinel evasion and a short timed gate. Relay tests check line segments between samples, so a crossing between samples is valid. Twelve rooms are still a prototype, not a finished campaign.

The look is currently drawn procedurally in `scripts/game.gd`; the SVG app icon is the main external art asset. Procedural visuals keep the project importable without an asset pack but are placeholder art, not final art. Each chamber also has one optional Memory Shard that reveals a short courier-network lore fragment.

## 2. Latest work in this development pass

### Automatic room resets and premium, responsive touch UI
**Current feature pass. Changed:** `scripts/game.gd`, `tests/game_flow_smoke.gd`, README, design, roadmap and build-status docs.

- `scripts/game.gd:L131–L175`: a pending failure reset gets its own short timer path, ignores movement/actions, and restarts the current room without another tap. Processing returns immediately on the frame a sentinel collision triggers failure, so puzzle/gate checks do not continue after death.
- `scripts/game.gd:L820–L870`: in rooms with required relay(s), finishing away from Switch A, missing a single beacon, or visiting ordered relays out of sequence clears the attempt and schedules an automatic same-room reset. A short recording still asks the player to keep recording; non-relay endpoint mistakes remain retryable.
- `scripts/game.gd:L999–L1045`: `_room_requires_relay()` and `_schedule_room_reset()` centralize failure handling. A red SIGNAL LOST/relay-failure card explains why, disables the normal HUD, displays a shrinking reset bar, discards the unfinished take and resets the player position immediately; after 0.85 seconds, `_start_level(current_level_index)` restores the full room state.
- `scripts/game.gd:L520–L625`: new failure-card UI, centered modal layout, responsive menu/HUD placement, a shared darker premium panel/button theme, larger bottom controls (54 design units) and a 48-unit pause target.
- `scripts/game.gd:L647–L703`: common button style now has softened shadows, bordered states and short press/hover tweens. `L558–L608` reflows the menu, pause/status labels, bottom action row, joystick hint and modal panels when the viewport changes. `L215–L226` uses proportional joystick hit regions for either handedness.
- `tests/game_flow_smoke.gd:L454–L490`, `L498–L545`, `L554–L603`, `L613–L670` and `L681–L769`: failure-reset assertions now cover single, two-, three- and four-relay routes plus sentinel collisions. `L831–L850` advances the timer without user input and verifies the same room returns with echo/recording/gate/latch reset. `L851–L878` checks mobile touch heights, viewport-driven anchoring and left/right joystick regions.
- Code commit: `ecc3243707091262f791fc700f1abf3d79e43ff0` (source blob `e44cb8d66c78b5a0cdb0253f88d8900b57d6d58d`, 1490 lines). Test commit: `aa06feb00b4bcfaec589fe2e62f39255d1fd40a2` (test blob `537101fd955a45c1f2e248ffda31ee22d18b4eae`, 883 lines). UI implementation also includes commits `02687b13b3aae614acd4125cdb2d0dd2d19b6b5e`, `0d22550fd4518548b5243b565d5a074c566f1cda`, `453beb8e486c63c08502829aa8cc0304968db2f4`, and `60b10923fe6196fa26edab18642ea240ee6f167d`.
- README/design/roadmap/build-status doc commits: `242ab9a505ee5de4a796a1e21ebf367da767db16`, `522d4b591ec46b6ae7371d060475434b3e2eccf1`, `03e4a4f00d4b2be88c63e7470b50d942fe6bb53f`, and `237603ac41f2e61a0bcfd3acb3d7c6e587be472a`.
- **Verification:** the last known fully passing CI baseline is run 210, which predates this feature pass. The GitHub integration available here did not expose the latest push-triggered Actions check result, so the new code/tests are **not yet confirmed CI-green**. The controller was manually inspected for line-flow/return-state consistency, but a Godot editor/runtime is not available in this environment. Real-phone touch layout and visual quality still need manual QA.

The automatic reset now treats sentinel death and relay sequence failure as a full room restart rather than leaving the player stranded in a partially failed state. The 0.85-second card is deliberately brief; playtesting should confirm its readability without making repeated failures feel slow.


### Dead Air Protocol: a high-difficulty four-relay sentinel gauntlet
**Changed:** `scripts/data/level_catalog.gd`, `tests/headless_smoke.gd`, `tests/game_flow_smoke.gd`, README, design, roadmap and build-status docs.

- `scripts/data/level_catalog.gd:L188–L205`: adds the twelfth room with four required ordered relays, a moving sentinel, a 6.5-second echo linger, Switch B at x=850, and a 1.8-second timed gate. The level validator also checks relay type, bounds, and spacing from objectives and other checkpoints.
- `tests/headless_smoke.gd:L50–L125`: requires a 12-room campaign; asserts Dead Air Protocol has exactly four waypoints, an active sentinel, Switch B at x=850, the 1.8-second timer and 6.5-second linger. The general schema assertion now permits more than one room combining relays and a timed gate.
- `tests/game_flow_smoke.gd:L674–L760`: proves an out-of-order route is rejected with the full four-relay hint; the correctly ordered route fits under the 8-second record cap and is accepted; the gate opens for exactly 1.8 seconds and closes if the player misses it; sentinel contact sends the player to spawn and erases an unfinished recording.
- Level-data commit: `a2ceca756626f94898a78e1258c452c33096f603`; schema test commit: `b841ebfd189911ea7454236816ffe7d83b35b00f`; gameplay test commit: `918fe8ce829d7b922afeae60a439253c027ec7ff`.
- The first data-only commit exposed an old schema assertion that assumed Fracture Clock was the only room with three relays and a timer. The schema assertion was generalized and then the combined suite passed. A subsequent difficulty review found Switch B was too close to the gate; it was moved back to x=850, making the crossing run 212 units, and the timer was reduced from 2.2 to 1.8 seconds. The final timer assertion was corrected after CI caught one stale expected value.
- [Godot CI run 206](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40412947281) passed on Godot 4.4.0 and 4.7.2 with the final 1.8-second window, farther Switch B placement, four-relay route and sentinel-interruption tests.

**Difficulty intent:** this is deliberately a late-campaign gauntlet. The sentinel can interrupt the real player's recording, so the route must be planned around its moving patrol; four beacons must be crossed in order; then the player must reach B and cross a short gate window. This is logic-tested, not yet manually playtested for fairness or touch-control comfort.

### Latch Protocol: complete the advertised toggle-switch mechanic
**Changed:** `scripts/game.gd` and `tests/game_flow_smoke.gd`; README, design and build-status docs updated.

- `scripts/game.gd:L243–L265`: creates a dedicated `LATCH SWITCH B` button in the gameplay HUD. `_update_hud()` shows it only for rooms whose `plate_b_mode` is `toggle`, changes its label when latched, and disables it while paused or after the gate opens.
- `scripts/game.gd:L145–L153`: keyboard E calls the same action as the touch button.
- `scripts/game.gd:L571–L606`: starting/restarting any room resets `switch_b_latched` to false.
- `scripts/game.gd:L630–L652`: `_on_latch_switch_b_pressed()` requires a toggle room, an echo currently holding Switch A, and the player near Switch B; the echo must be finished playing, not merely passing through A. Otherwise it displays a clear reason. A successful activation toggles B's latch.
- `scripts/game.gd:L891–L930`: puzzle evaluation uses the latched state for toggle rooms rather than requiring the player to remain physically on B. The gate stays open after a valid latch and the status explains the switch/gate state.
- `scripts/game.gd:L1116–L1120`: the drawn Switch B stays visually active while latched even after the player leaves.
- `tests/game_flow_smoke.gd:L387–L446`: verifies the button is visible in Latch Protocol and hidden in hold-switch rooms, standing on B alone does not activate the gate, a missing or still-playing echo cannot latch B, leaving B does not close the gate, E activates the switch, and restart clears the latch.
- Implementation commit: `4dd340a159e818aa2f0ad0cf042163b6b97ceecc`; integration-test commit: `8a057283461d7e7a4663e9c4ddedc43aa92fff7c`.
- [Godot CI run 185](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40402444543) passed on Godot 4.4.0 and 4.7.2, including the new toggle-switch integration tests and the settled-echo prerequisite.

This closes a gap where the level data and hint advertised a toggle switch but the main gameplay controller did not yet implement the button/key action and latched gate state.

### Ordered-relay rejection hints now list the full required sequence
**Changed:** `scripts/game.gd` and `tests/game_flow_smoke.gd`, plus README/design/build-status notes.

- `scripts/game.gd:L632–L646`: when an ordered route is rejected, the game builds the hint from the room's actual `echo_waypoints` array instead of hard-coding only Relay 1 and Relay 2. A three-relay room now says `RELAY 1, then RELAY 2, then RELAY 3`; two-relay rooms keep their shorter message.
- `tests/game_flow_smoke.gd:L459–L462`: Chorus Route still asserts the two-relay hint.
- `tests/game_flow_smoke.gd:L517–L520`: Triune Relay asserts the complete three-relay hint on a reversed route.
- `tests/game_flow_smoke.gd:L552–L572`: Fracture Clock now deliberately submits Relay 1 → Relay 3 → Relay 2 → Switch A first, verifies the route is rejected and the hint names all three relays, then continues with the valid route/timed-gate test.
- The initial test commit `49338ee0ae9cd6e3e697c820b6d64ce9c097ee40` accidentally updated the two-relay assertion instead of the three-relay assertion. The test expectations were corrected in `9eba2674ae7e64d78eb5011649182722b0bfbd08`.
- [Godot CI run 173](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40401469061) passed on Godot 4.4.0 and 4.7.2 after the correction. Both relay-sequence feedback tests and the combined Fracture Clock route test passed.

This makes route rejection actionable as the campaign adds more than two checkpoints; it does not change route acceptance rules.

### Timed-gate progress bar: make the deadline glanceable
**Changed:** `scripts/game.gd`, `tests/game_flow_smoke.gd`, README, design and build-status documentation.

- `scripts/game.gd:L1042–L1046`: new `_get_gate_timer_ratio()` returns the clamped remaining-time fraction based on the current room's authored `gate_open_seconds`; rooms without a timed gate return zero.
- `scripts/game.gd:L1112–L1118`: while a timed gate is open, the playfield now draws a dark track, amber fill and light outline beneath the numeric countdown. The bar starts full, shrinks with the timer, and is absent once the window expires or a permanent gate is powered.
- `tests/game_flow_smoke.gd:L592–L647`: the Pulse Lock test checks a full bar at gate opening, proportional shrinkage after a frame advances the timer, and an empty bar after timeout.
- Code commit: `2a41dc62625519760775331a72dbdb2c9a0dd4f7`; test-expression correction: `2eca67fde3ab69e52b17ae6151652bc4eea9c2eb`.
- [Godot CI run 165](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40401020392) passed on both Godot 4.4.0 and 4.7.2. The tests cover the timer ratio helper's full, partial and empty states, plus the existing eleven-room and gameplay checks.

This is a presentation/usability improvement, not a change to the timer's rules. Actual visibility and contrast on a phone still need manual inspection.

### Fracture Clock: combine three ordered relays with a timed gate
**Changed:** `scripts/data/level_catalog.gd`, `tests/headless_smoke.gd`, `tests/game_flow_smoke.gd`, README, design, roadmap and build-status documentation.

- `scripts/data/level_catalog.gd:L170–L187`: adds the eleventh room, **Fracture Clock**. Its route requires Relay 1 → Relay 2 → Relay 3 → Switch A, and holding both switches then opens a 4.5-second gate.
- `scripts/data/level_catalog.gd:L203–L324`: the same shared validator checks the room's three ordered relay points, objective/shard spacing, room bounds, and timed-gate range. The authored 4.5-second duration is inside the accepted 1–15 second range.
- `scripts/game.gd:L711–L725`: existing ordered-waypoint validation handles all three checkpoints; `L832–L872` handles the timed-gate countdown, crossing and retry behavior. No new special-case runtime branch was required.
- `tests/headless_smoke.gd:L50–L107`: campaign data tests require at least eleven rooms, verify the named Triune Relay has three waypoints, and assert that a three-relay room combines those waypoints with a timed gate. The generic assertion allows multiple three-relay rooms.
- `tests/game_flow_smoke.gd:L30`: registers the combined-puzzle test. `L542–L589`: verifies the Fracture Clock route is accepted, both switches open the gate for exactly 4.5 seconds, and crossing the barrier before timeout keeps the portal powered.
- Level-data commit: `ad810770fb2119048497d7b147aa3732a78215c9`; schema test: `f5eb3f6b847ff2370f54993e77608a68185cb351`; gameplay test: `4413bcf1a8bdadc3ec14de6ca8fac5433500a849`.
- A first schema assertion incorrectly assumed Triune Relay would remain the only three-relay room. The test was generalized in `9c31dd95c97f1e01b1647fe79a0d02c61bd56066`, keeping a separate assertion for the named Triune Relay and allowing Fracture Clock as another valid three-relay room.
- [Godot CI run 157](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40400606810) passed on both Godot 4.4.0 and 4.7.2, including the full combined-route/timed-gate test.

This is a combination challenge, not a new primitive mechanic. Its 4.5-second crossing window still needs human playtesting at slow, normal and fast movement speeds, especially with touch controls.

### Triune Relay: tenth chamber and three-checkpoint ordered route
**Changed:** `scripts/data/level_catalog.gd`, `tests/headless_smoke.gd`, `tests/game_flow_smoke.gd`, README, design, roadmap and build-status documentation.

- `scripts/data/level_catalog.gd:L153–L169`: adds the tenth room, **Triune Relay**, with a long diagonal route and three required relay coordinates. The room reuses the already-general ordered-waypoint mechanism; no special-case gameplay branch was added.
- `scripts/data/level_catalog.gd:L252–L274`: existing validator checks every ordered waypoint is a `Vector2`, in bounds, separated from objectives/shard, and sufficiently far from other waypoints. The new room passes this same validator.
- `scripts/game.gd:L711–L725`: the existing `_track_passes_waypoints_in_order()` iterates the authored waypoint array, so it enforces Relay 1 → Relay 2 → Relay 3 automatically. `L672–L708` derives each beacon's linked visual from first-crossing order.
- `tests/headless_smoke.gd:L50–L96`: campaign tests now require at least ten rooms and assert a named three-relay room exists; canonical catalog validation also catches bad geometry.
- `tests/game_flow_smoke.gd:L27–L30`: runs the new test before the Pulse Lock suite. `L483–L539`: tests that Relay 3 before Relay 2 is rejected, then verifies the full Relay 1 → Relay 2 → Relay 3 → Switch A route is accepted and all three markers show linked.
- Level-data commit: `48aa2ccd090f7cda6b74c8d8a9a0bbdd016d9e3d`; data-test commit: `76cc6722aea77edc5bba938aa36318271645afc2`; gameplay-test commit: `9f08fae5aa9a7a8588a01cae3dcad86cad03ca55`.
- [Godot CI run 147](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40400099108) passed on both Godot 4.4.0 and 4.7.2, including project import/parse, all data tests, existing gameplay tests, and the new three-relay acceptance/rejection test.

The campaign now has twelve rooms, but it is still an early prototype. Triune Relay is logic-tested; its visual readability and actual touch-control difficulty still need manual playtesting.

### All-memory restored-signal reward and dynamic Archive count
**Changed:** `scripts/game.gd`, `tests/game_flow_smoke.gd`, README and design/build/roadmap documentation.

- `scripts/game.gd:L812–L829`: collecting the final uncollected Memory Shard changes the status from the ordinary `MEMORY:` lore message to `SIGNAL RESTORED` plus the final shard's lore. This reward is optional and does not affect gates, room completion or unlocks.
- `scripts/game.gd:L454–L471`: Memory Archive now shows `SIGNAL RESTORED — ALL MEMORIES FOUND` when all room shards are collected; otherwise it shows the live recovered/total count.
- `scripts/game.gd:L313–L372`: the Archive's initial status placeholder uses `LEVELS.size()` instead of a hard-coded six, keeping the UI compatible as the campaign grows.
- `tests/game_flow_smoke.gd:L287–L316`: `_test_all_memories_restore_signal()` simulates collecting the final room's shard through the real pickup path, checks the message/Archive reward, then restores the player's original save values.
- `tests/game_flow_smoke.gd:L319–L347`: Memory Archive UI test covers the normal count or restored-signal state and asserts the displayed denominator matches the live room count.
- The reward source commit is `dd11471aea0f87399f7a816304daaba3ac68df4b`; the dynamic archive placeholder is `f900f967fa83f618e3615f423a9ef613f85bd71a`; the regression coverage is in `04be8ef22ca631b000d14b541bbce2ca0426b5b8` and `7531407e22c8a8068b4d62df90c190272713668d`.
- [Godot CI run 140](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40398632047) passed on both Godot 4.4.0 and 4.7.2, including the full final-shard pickup path and Archive status checks.

This is an optional exploration reward, not a paid gate. All twelve rooms remain completable without collecting any Memory Shard.

### Ordered Relay feedback and Pulse Lock timed gate
**Changed:** `scripts/data/level_catalog.gd`, `scripts/game.gd`, `tests/headless_smoke.gd`, and `tests/game_flow_smoke.gd`, plus README/design/roadmap/build-status documentation.

- `scripts/data/level_catalog.gd:L4–L188`: eleven authored room definitions; Chorus Route has two ordered `echo_waypoints`, Triune Relay has three, Fracture Clock combines three with `gate_open_seconds: 4.5`, Latch Protocol sets `plate_b_mode: "toggle"`, and Pulse Lock defines `gate_open_seconds: 3.5`.
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
- `tests/headless_smoke.gd:L50–L107` and `L110–L134`: verify eleven rooms, single/two-/three-relay data, Fracture Clock's relay/timed-gate combination, toggle/timed-gate schema, malformed waypoint lists and timer bounds.
- `tests/game_flow_smoke.gd:L387–L438`: test wrong/valid ordered-relay routes and linked-state visual logic.
- `tests/game_flow_smoke.gd:L427–L478`: Chorus Route rejects reversed order and accepts the correct two-relay route. `L483–L539` tests Triune Relay's three-checkpoint route rejection/acceptance and linked state. `L542–L589` tests Fracture Clock's three-relay route, 4.5-second gate activation, and crossing. `L592–L644` exercises Pulse Lock timer start, real-frame countdown, timeout, retry latch, rearm and persistent power after crossing.
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
| `scripts/game.gd` | Main controller, menu/HUD construction, movement, echo recording/playback, functional Latch Protocol button/E shortcut and persistent toggle state, dynamic ordered-relay rejection feedback, Pulse Lock timer/progress bar/retry, sentinel, Memory Shard collection/archive, control preferences, save flow and procedural rendering. **1289 lines in the current source snapshot; refactor incrementally after tests protect behavior.** |
| `scripts/core/echo_track.gd` | Data-only `RefCounted` script loaded through preloaded script resources; avoids global `class_name` lookup; stores points, clamps timestamps to nondecreasing order, copies tracks, returns duration, interpolates route positions, and holds endpoint outside the timestamp range. |
| `scripts/data/level_catalog.gd` | Twelve room dictionaries, optional shard positions/lore, one-/two-/three-/four-relay requirements, toggle-switch and combined relay/sentinel/timed-gate challenges, defensive-copy accessor and canonical/draft validator for schema, names, spacing, bounds and hazard/timer tuning. |
| `scripts/data/progress_store.gd` | Version-2 local save boundary (`user://echopost_save.cfg`) using `ConfigFile`; preserves v1 campaign progress and stores normalized Memory Shard room indices. |
| `scripts/data/settings_store.gd` | Separate preference store (`user://echopost_settings.cfg`) for speed and joystick handedness, defaulting safely and normalizing unsupported movement values. |
| `tests/headless_smoke.gd` | Data tests for echo interpolation/copying, twelve-room/shard/waypoint/toggle schema, named Triune Relay and Fracture Clock, Dead Air Protocol's four-relay/sentinel/timed-gate combination, malformed-draft validation, v2 shard persistence/sanitization, v1-save compatibility, campaign clamping and isolated control-preference persistence/normalization. |
| `tests/game_flow_smoke.gd` | Main-scene integration tests for chapter/archive/options UI, Memory Shards, speed presets/handedness, lifecycle pause, record cap/feedback, sentinel cancellation, reset, portal idempotency, Latch Protocol button/E/latch reset, one-/two-/three-/four-relay pass/miss/order/linked state, Fracture Clock, Dead Air Protocol's sentinel interruption and short timer, and timed-gate behavior. |
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

This function index matches source blob SHA `e44cb8d66c78b5a0cdb0253f88d8900b57d6d58d` (1490 lines). It is authoritative for the current source. Older code-line references inside historical feature notes refer to the source revision at the time.

- **L1–L5:** Script header and core duration constants, including the 0.85-second failure-reset transition.
- **L7–L23:** Playfield bounds and preloaded echo, level, progress and settings dependencies.
- **L25–L55:** Campaign/room state, echo track and recording data, sentinel timer, pending reset timer/reason and joystick input.
- **L58–L91:** UI references for menu, gameplay HUD, panels, options, failure card, labels and actions.
- **L94–L102 — `_notification()`:** Reflow UI after viewport resize and pause active play on app suspension/focus loss.
- **L104–L116 — `_pause_for_lifecycle()`:** Lifecycle pause does not interrupt a failure-reset sequence; otherwise clears active joystick input and preserves ongoing recording.
- **L119–L128 — `_ready()`:** Load saved progress/preferences, build UI, apply responsive layout and show menu.
- **L131–L175 — `_process()`:** Advance automatic reset countdown before normal simulation; on expiry restart the same room, and halt further simulation on the frame a sentinel triggers failure.
- **L176–L212 — `_input()`:** Keyboard latch, touch/mouse joystick handling; ignore input during the failure transition.
- **L215–L226 — `_is_joystick_area()`:** Proportional left/right touch regions based on viewport size and handedness.
- **L228–L238:** Joystick normalization and star decoration.
- **L240–L275 — `_build_interface()` / `_build_menu()`:** Construct the screen panels and centered main-menu navigation.
- **L278–L301 — `_build_game_hud()`:** Create top-level status, 48-unit pause button, 54-unit primary record/latch/menu/restart buttons and move tips.
- **L303–L419:** Completion, Help, scrollable chapter select, Memory Archive and Options panels.
- **L421–L517:** Archive/options actions, settings persistence, speed presets and memory list update.
- **L520–L557 — `_build_failure_panel()`:** Premium-styled red-toned failure card with reason, detail, and shrinking progress indicator.
- **L558–L608 — `_layout_responsive_ui()` / `_layout_centered_panels()`:** Reposition menu/HUD/bottom actions for viewport size and center modal panels.
- **L610–L645 — `_make_panel()` / `_make_label()`:** Shared panel depth, border/radius, typography and label construction.
- **L647–L704 — `_make_button()` / `_animate_button()`:** Shared rounded/bordered button states and short hover/press scale tweens.
- **L705–L731 — `_show_menu()` / `_on_start_pressed()`:** Cancel pending reset and return to menu or continue the unlocked room.
- **L732–L773 — `_start_level()`:** Reset room, echo, latch, gate/timer, recording, hazard, input and failure-transition state before showing gameplay.
- **L774–L794 — `_on_record_pressed()`:** Start or finish the player route, ignoring input during failure transition.
- **L795–L819 — `_on_latch_switch_b_pressed()`:** Validate and toggle Switch B in toggle rooms.
- **L820–L870 — `_finish_recording()`:** Validate duration, Switch A endpoint, required single relay and ordered relay sequence. Relay-room endpoint/missed/out-of-order failures schedule automatic restart; non-relay endpoint errors remain retryable.
- **L872–L970:** Track sample insertion, beacon link state, ordered-relay progress checks and segment-distance waypoint evaluation.
- **L971–L998:** Player motion, echo replay/linger and relay-room failure helper.
- **L999–L1034 — `_room_requires_relay()` / `_schedule_room_reset()`:** Clear the failed take, block gameplay inputs, show the transition card and schedule the same-room restart.
- **L1035–L1046 — `_check_sentinel_collision()`:** Sentinel contact is a full room failure; current recording is discarded and the common automatic reset starts.
- **L1047–L1083:** Memory Shard collection and timed-gate timeout/crossing retry logic.
- **L1084–L1125 — `_check_puzzle_state()`:** Evaluate switches, latching, gate, timed retry and portal arrival.
- **L1126–L1215:** Completion/unlock/save flow, pause, navigation, chapter state and progress labels.
- **L1216–L1249 — `_update_hud()`:** Refresh state labels and button captions/disabled states, including disabling record during pending reset.
- **L1250–L1274:** Read/write local progress and control preferences.
- **L1275–L1302:** Background, menu art and timed-gate ratio.
- **L1303–L1382 — `_draw_room()`:** Draw room grid, switches, gate, portal, relays, shard, sentinel, echo/record trail and joystick hint.
- **L1383–L1489:** Procedural Relay Beacon, Memory Shard, switch, gate, portal, robot, joystick and route-path drawing.

## 5. Exact line map — supporting scripts and tests

### `scripts/core/echo_track.gd` (60 lines, blob SHA `9a433129a0cb8b04d9ab55c0964aeb4683ddab3a`)
- **L1–L5:** RefCounted header, class-cache independence note, and timestamp/position sample array.
- **L8–L9:** Clear samples.
- **L12–L16:** Add nonnegative timestamp while guaranteeing timestamps never move backwards.
- **L19–L25:** Copy samples through `get_script().new()`; no global `EchoTrack` lookup, preventing the Godot 4.4 compile error.
- **L28–L31:** Return route duration.
- **L34–L59:** Resolve position before/after route, interpolate between ordered points, and tolerate near-duplicate timestamps.

### `scripts/data/level_catalog.gd` (342 lines, blob SHA `d1c16361a74e957eb16abcba392403e450e8ba02`)
- **L1–L3:** RefCounted catalog and purpose.
- **L4–L152:** First nine room definitions, ending with Latch Protocol's toggle-style Switch B.
- **L153–L169:** Triune Relay's tenth-room definition, including three ordered relay coordinates and optional Memory Shard lore.
- **L170–L187:** Fracture Clock's eleventh-room definition, combining three ordered relays and a 4.5-second timed gate.
- **L188–L205:** Dead Air Protocol's twelfth-room definition, including four ordered relays, a fast sentinel, 6.5-second echo linger, Switch B at x=850, and 1.8-second timed gate.
- **L208–L219:** Defensive-copy level getter, room-count helper and canonical validation entry points.
- **L221–L250:** Validate nonempty campaigns, unique/nonblank names, required keys, core Vector2 positions, lore text and echo linger.
- **L251–L287:** Validate toggle-mode values, timed-gate duration type/range, optional waypoint types/bounds, and spawn/Switch A/Switch B separation.
- **L289–L304:** Validate Memory Shard and single Relay Beacon spacing from objectives.
- **L305–L327:** Validate ordered relay arrays, every waypoint's type/bounds/objective separation, and separation between relay markers.
- **L328–L341:** Validate sentinel patrol keys, height, sweep amplitude and speed.

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

### `tests/headless_smoke.gd` (222 lines, blob SHA `f7e7a273bec2e7d079f544b1ed6f2f2f80b3ac0f`)
- **L1–L12:** Test runner/preloads and isolated temporary save/settings paths.
- **L15–L25:** Run grouped tests and exit nonzero on assertion failure.
- **L28–L47:** Timestamp order, interpolation, endpoint hold, preloaded-script identity and copy independence.
- **L50–L125:** Validate twelve unique rooms, all single-/multi-relay data, named Triune Relay and Fracture Clock, Dead Air Protocol's four relays/active sentinel/6.5-second linger/farther Switch B/1.8-second gate, and malformed-draft validator entry point.
- **L128–L150:** Submit intentionally invalid room drafts and assert errors for duplicate names, route geometry, sentinel parameters, out-of-bounds/mistyped relays and invalid timed-gate durations.
- **L152–L156:** Search validator messages by fragment.
- **L160–L191:** Save/load campaign progress, sanitize shard indices and verify v1 save compatibility.
- **L194–L215:** Verify settings defaults, preference persistence, handedness and speed normalization.
- **L217–L220:** Assertion helper.

### `tests/game_flow_smoke.gd` (883 lines, blob SHA `537101fd955a45c1f2e248ffda31ee22d18b4eae`)
- **L1–L10:** Integration harness, main scene, relay/level/progress preloads.
- **L13–L88:** Run the UI/reset tests and complete puzzle-flow suite.
- **L91–L110:** Lifecycle pause preserves recording and freezes recording/gate time.
- **L112–L128:** Exercise the real frame loop at the exact eight-second recording boundary.
- **L130–L142:** Too-short stop keeps recording active, creates no echo and explains the remedy.
- **L144–L174:** Sentinel contact schedules full room reset, cancels an unfinished take, and the helper verifies reset without user input.
- **L175–L214:** Manual restart clears active recording/echo/timers/gate/input and works from paused state.
- **L215–L240:** Powered portal completion is idempotent and test restores saved progress.
- **L241–L259:** Chapter list scrollable layout.
- **L260–L293:** Memory Shard pickup/lore/save persistence.
- **L294–L325:** Last shard through pickup path and restored-signal reward.
- **L326–L357:** Archive recovered/unfound lore, reward state and dynamic room count.
- **L358–L390:** Options, movement speed presets, and left/right joystick regions.
- **L391–L453:** Latch Protocol switch button visibility, echo-settled prerequisite, E shortcut and restart cleanup.
- **L454–L497:** Static Bloom single Relay Beacon requirement, invalid route rejection and segment-crossing acceptance; the rejection now auto-resets the room.
- **L498–L553:** Chorus Route route-order validation and linked state; reverse order schedules auto-reset.
- **L554–L612:** Triune Relay rejects reversed three-relay order, checks full hint, accepts correct sequence and tests auto-reset.
- **L613–L680:** Fracture Clock rejects bad route with complete hint and auto-resets, then validates a correct route, 4.5-second gate and crossing.
- **L681–L770:** Dead Air Protocol validates invalid/valid four-relay sequence, 1.8-second gate/timeout, plus full room reset on relay failure and sentinel contact.
- **L771–L830:** Pulse Lock start/countdown bar, real-frame countdown, pause freeze, timeout/rearm/retry and crossing.
- **L831–L850 — `_finish_failure_reset()`:** Advance countdown without input and assert the same room returns with failed recording/echo, gate and latch cleared.
- **L851–L878 — `_test_premium_mobile_ui()`:** Touch-target sizing, shared button style, responsive control/modal placement and proportional joystick zones.
- **L879–L882:** Assertion helper.


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

- **Latest passing code/test run:** [Godot CI run 206](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40412947281) passed on both Godot 4.4.0 and 4.7.2. It includes the twelve-room schema and the final Dead Air Protocol four-relay acceptance/rejection, 1.8-second timeout, farther-switch-distance assertion and sentinel-interruption checks, alongside prior Latch Protocol and timed-gate regressions.
- **Triune Relay:** wrong order Relay 1 → Relay 3 → Relay 2 → Switch A is rejected; the correct route is accepted and all three markers become linked. Run 157 passed these assertions.
- **Fracture Clock:** combines the same ordered route mechanic with the timed-gate rule; run 157 passed the integration test and catalog validation. The initial over-specific schema assertion was corrected so a campaign can contain more than one three-relay room.
- **Timed-gate bar:** run 165 passed checks that the bar ratio starts at 1.0, tracks the timer proportionally after a frame, and reaches zero after timeout.
- **Relay feedback:** run 173 passed both the two-relay and three-relay rejection-message assertions, including Fracture Clock's invalid-order attempt.
- **Latch Protocol:** run 179 passed button visibility, echo prerequisite, latch persistence after leaving B, keyboard E, and reset cleanup assertions. Run 185 additionally verifies the echo must finish playback before latching.
- **Previous verification:** run 140 passed the all-memory restored-signal reward; run 122 passed Pulse Lock countdown, pause freeze, timeout closure, retry latch/re-arm, and portal power after crossing.
- **Source hashes:** current `scripts/game.gd` blob SHA is `30343671f2d673b8a19de6fb3bc15e784fc01905` (1289 lines); current `scripts/data/level_catalog.gd` blob SHA is `d1c16361a74e957eb16abcba392403e450e8ba02` (342 lines); current `tests/headless_smoke.gd` blob SHA is `f7e7a273bec2e7d079f544b1ed6f2f2f80b3ac0f` (222 lines); current gameplay-test blob SHA is `e8f0f7a705ef144a235fe10ddacbb661973f472a` (824 lines). Sections 4 and 5 are keyed to these current files.
- **Device QA:** not performed by this assistant. The game has not been manually run in the user's Godot editor or on a physical Android device during this pass.
- **Android export:** no APK built or attached. Android export preset, package identity, export templates, SDK/JDK, signing and real-device testing remain.
- **Quality caveat:** automated tests verify logic, not visual clarity or whether the 1.8-second Dead Air Protocol or 3.5-second Pulse Lock crossing feels fair on touch controls. Both need playtesting at slow/normal/fast speeds.

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

1. **Mobile sizing / safe areas:** menu/HUD/modal layout and joystick hit regions now reflow for viewport changes, but the playfield drawing/positions remain designed around 1280×720. Safe areas, display cutouts, very short screens, and real-device button reach are not validated.
2. **Controller size:** `scripts/game.gd` owns UI construction, gameplay state, input, persistence coordination and drawing. Refactor only incrementally; add tests first so game behavior does not regress.
3. **Small content set:** twelve room dictionaries and twelve optional Memory Shards now exist, but the core two-switch pattern is still the foundation and there is no full campaign or final narrative ending.
4. **Procedural placeholder visuals:** no authored robot animations, environmental tilesets, VFX or transition animations.
5. **No sound:** recording, rejected route, sentinel hits, gate opening and portal have text/visual feedback only. No SFX, music, mixer, or audio options exist.
6. **Pause behavior needs real device QA:** lifecycle logic and timer freeze are headlessly tested, but actual Android app-switch lifecycle/focus behavior are unverified. The player must tap RESUME after returning.
7. **Mechanic coverage:** one recording slot and the two-switch gate remain core; Dead Air Protocol now requires four ordered relays while a sentinel can interrupt recording and a short gate timer pressures the exit run. Moving platforms, checkpoints, multi-echo puzzles and deeper combinations remain future work.
8. **Recording edge cases:** the minimum is now `MIN_RECORD_SECONDS = 0.7` at `scripts/game.gd:L16`; a too-short stop deliberately keeps recording active and tells the player to continue. Verify that this interaction is understandable on touch.
9. **Hazard edge cases:** sentinel contact now cancels the current take and schedules a full same-room restart. Confirm the 0.85-second failure card is readable and the reset feels immediate rather than sluggish in a live playthrough.
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
- [x] Add the eleventh chamber Fracture Clock, combining three ordered relays with a 4.5-second timed gate; [run 157](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40400606810) passed on both Godot versions.
- [x] Add a shrinking amber progress bar to the timed-gate countdown and verify full/partial/empty ratio behavior in [run 165](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40401020392) on both Godot versions.
- [x] Make ordered-route rejection hints list every relay in sequence and verify two-/three-relay feedback plus Fracture Clock's invalid route in [run 173](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40401469061).
- [x] Implement Latch Protocol's actual toggle state, button and E shortcut; verify the echo prerequisite, persistent gate opening, button visibility and restart reset in [run 179](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40401941921).
- [x] Tighten Latch Protocol so the echo must be finished playing and settled on A before B can latch; verify on both Godot versions in [run 185](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40402444543).
- [x] Add Dead Air Protocol: four ordered relays, active sentinel, 6.5-second linger, Switch B farther from the gate and a 1.8-second timer; [run 206](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40412947281) passed on both Godot versions with valid/invalid route, gate-timeout and sentinel-interruption coverage.
- [ ] Ask for / perform a local pull and open the project in the user's Godot 4.4 editor to inspect the live route preview, reset transition and responsive UI on the actual machine.
- [x] Verify Memory Archive and Options UI, speed presets, and left-handed joystick region on both Godot versions in run 82.
- [x] Update this progress file, current source/test blob hashes, and exact line maps for Triune Relay, Fracture Clock and Dead Air Protocol.
- [x] Record automatic same-room reset behavior for sentinel deaths and failed relay routes; add countdown/reset-state regression assertions and viewport/touch UI checks.
- [x] Add responsive HUD/modal reflow, larger primary touch targets and consistent premium button/panel styling.
- [ ] Verify the latest push-triggered GitHub Actions run; the latest available passing baseline (run 210) predates this feature pass and is not evidence for the new changes.
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
- [ ] Continue from twelve layouts toward 20 authored chambers; add fresh mechanics beyond route geometry, patrol timing, relay order and timed gates.
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
5. Refresh every affected line number after changes. The line map in section 4 is keyed to `scripts/game.gd` blob SHA `e44cb8d66c78b5a0cdb0253f88d8900b57d6d58d`; section 5 records current supporting-script and test blob SHAs. If any of those blob SHAs differ after edits, regenerate the corresponding section.
6. Update `PROJECT_PROGRESS.md` in the same development pass as source changes. Record the new commit(s), source hashes/line references, CI URL/result and what the next session should do.
7. Keep this game offline-capable and dependency-light. Never add network accounts, telemetry, uploads, payment or ads as an incidental code change.
8. Don't produce an APK/release claim unless an actual export and install verification were completed.

---

*Handoff note: this file is written to make future work resumable from concrete repository state, not to declare completion. The next session's first action should be checking the newest workflow run, then manually tune Pulse Lock if possible before designing another new mechanic.*
