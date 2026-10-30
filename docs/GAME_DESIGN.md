# ECHOPOST — Game Design

## North star

Make players feel that a successful run leaves a useful trace in the world. The unique promise is not simply time-rewind puzzles; it is that **a recording of a player's movement becomes a real, reusable actor in a puzzle**.

## Genre and pillars

- **Genre:** 2D puzzle adventure with asynchronous community interaction planned.
- **Target:** Android first, with desktop builds used for development and QA.
- **Session shape:** One room should take roughly one to four minutes after the player understands its trick.
- **Readable puzzles:** Every switch, gate, echo, and hazard should have a clear visual state.
- **Player-created solutions:** Recording and replay are the core verb, not a side feature.
- **Respect the player's time:** Short rooms, instant restarts, locally saved progress, and no energy timers.
- **Fair monetization:** If monetization is added, sell cosmetics or substantial optional expansions; do not sell puzzle solutions or power.

## Current playable loop

1. Enter a chamber and inspect the two switches and exit.
2. Start recording and move to Switch A.
3. Stop the recording; the echo replays the complete path and lingers at its last position.
4. Reach Switch B while the echo is holding A.
5. The gate opens; reach the portal to complete the room.
6. Unlock the next chamber; progress is stored locally.

## Current campaign: nineteen chambers across three signal chapters

The first thirteen chambers establish the two-switch echo rule, sentinels, ordered relays, a latched switch, timed gates and the echo-only jammer. Chapter II adds four synthesis rooms that combine established rules. Chapter III teaches moving-platform support and pulse-timed switches. The campaign remains a content foundation, not a finished game.

- **The First Echo:** a safe introduction to recording, echo playback, and both switches.
- **Long Memory:** introduces the roaming sentinel and separates Switch A from the real player's destination.
- **Split Signal:** moves the switches to opposite sides and increases sentinel speed.
- **Fractured Lane:** asks the player to record a longer diagonal crossing under a wide patrol.
- **Crosscurrent:** places switches in opposite corners and tests route planning before moving toward B.
- **Static Bloom:** uses a long route, wide sentinel sweep, and one required Relay Beacon checkpoint.
- **Chorus Route:** requires two Relay Beacons to be encountered in order within the recorded route, not just somewhere along the path.
- **Pulse Lock:** opens a 3.5-second crossing window when the echo holds A and the player holds B. If the player is still on the entrance side when the window expires, the gate closes and both switches must be released/rearmed for another attempt. A countdown label and shrinking amber bar show the remaining window. Once the player crosses the barrier in time, the portal remains powered.
- **Latch Protocol:** Switch B is a toggle. The player must be near B while the echo holds A, then tap the dedicated LATCH SWITCH B button or press E. The switch stays active after the player leaves it, allowing a clean crossing to the portal. Restarting the room clears the latch.
- **Triune Relay:** requires three Relay Beacons to be crossed in order before the route finishes on Switch A. Skipping or reversing a checkpoint invalidates the recording.
- **Fracture Clock:** combines three ordered Relay Beacons with a 4.5-second timed gate. The route must be valid before the player can use the echo to open the timed crossing.
- **Dead Air Protocol:** the gauntlet room requires four ordered Relay Beacons, records while a fast sentinel patrol can interrupt the player, shortens echo linger to 6.5 seconds, and moves Switch B farther from the gate and leaves only 1.8 seconds to cross it. Sentinel contact during a recording discards the entire take, so both route order and safe movement timing matter.
- **Null Corridor:** a purple 105-unit ECHO DEAD ZONE jams the recorded echo route. The direct path between spawn and Switch A crosses the field and is rejected with an ECHO JAMMED reset; recording a curved route around it succeeds. The real player is unaffected, so the puzzle teaches that recorded and live movement have different hazards.
- **Glass Horizon:** combines three ordered relays with a wide, fast-moving sentinel patrol.
- **Clockbreak Crossing:** combines three ordered relays with a 2.8-second gate crossing.
- **Switchback Protocol:** requires two ordered relays routed above an echo-only jammer, then uses a latched Switch B.
- **The Last Chorus:** the Chapter II finale combines four ordered relays, a jammer bypass, a moving sentinel and a 2.8-second gate window.
- **Drift Bridge:** a full-height void gap blocks ordinary movement. A moving platform shuttles across it; the real player can steer while being carried, and the recorded echo replays its saved world positions.
- **Phase Relay:** Switch B activates only during a repeating 2.1-second pulse in a 5.5-second cycle. Both switches must be linked during the live phase, then a 3.2-second gate window begins.

The chapter selector scrolls so future rooms do not collide with the navigation controls. Each current chamber also contains one optional Memory Shard that reveals a short courier-network memory. Shards are tracked by chamber and saved locally; the menu's scrollable Memory Archive lets players reread recovered fragments and shows undiscovered entries. Version-1 saves migrate without losing unlocked rooms or completion count. Moving platforms, multi-echo puzzles, checkpoints and more varied puzzle rules remain future work; the nineteen current rooms are still a foundation rather than a finished campaign.

## Echo rules

- A recording contains timestamped player positions. A route is accepted only when the final position is on Switch A, so a failed route is explained and can be retried.
- Recording duration is capped to avoid unbounded memory and impossible-to-read paths.
- Echo playback follows recorded samples in time order.
- When playback ends, the echo holds its final recorded position temporarily.
- Echoes press switches by occupying their active area; they do not push the real player or change the recording.
- **Null Corridor echo jammer:** `echo_jammer` and `echo_jammer_radius` define a circular dead zone for recorded routes only. The route is tested against each segment between samples, so even a fast pass through the field is rejected. A crossing route loses its take and triggers a same-room reset; the real player has no movement collision with the field.
- A room may require route checkpoints. Static Bloom's `echo_waypoint` requires crossing one Relay Beacon; Chorus Route requires Relay 1 then Relay 2, and Triune Relay requires Relay 1, Relay 2, then Relay 3, all in path order. The game checks the nearest point on each sample-to-sample line segment so crossings between samples count. Wrong order or a missed checkpoint is rejected with explicit feedback that names every required relay in the correct order.
- Pulse Lock defines `gate_open_seconds`. When both switches activate it, the timer ticks only during PLAYING state; timeout closes the gate if the player has not crossed the barrier. A missed attempt stays latched until the player leaves a switch, so standing still cannot immediately reopen the gate. Crossing the barrier before timeout permanently powers the portal for that room.
- Sentinel contact is a full room failure. The current take is discarded immediately and a brief SIGNAL LOST card explains the cause; after a short visual countdown, the same chamber starts fresh with the echo, switches, gate, timer and recording state cleared. In rooms with required Relay Beacons, a missing/out-of-order relay or a route that ends away from Switch A also triggers this automatic room reset. Ordinary non-relay endpoint mistakes remain retryable without resetting the whole room.
- Every current chamber has an optional Memory Shard at its own authored position. Touching it records that room index in local progress and displays a short lore fragment. The Memory Archive can revisit a recovered fragment later. Recovering all nineteen shards reveals a final “signal restored” reward in the play status and Archive. Missing a shard does not block the switches, gate, exit, or campaign unlocks.
- Save schema version 2 stores the collected room indices. Version 1 saves remain loadable and begin with no Memory Shards collected; duplicate, negative, and out-of-campaign indices are filtered during loading.
- A future online version must validate uploaded recordings and isolate them from executable code. A recording should be data only, never a script.

## Accessibility and usability

- Use generous thumb targets and clear state feedback. Gameplay actions are translucent round glass controls rather than menu-style rectangles: the large Record Echo button is on the right by default, the optional latch circle sits beside it, and round Pause/Menu/Restart controls remain at the edges. The action cluster mirrors to the left in left-handed mode and uses glow/pressed states without hiding the playfield.
- Reposition the circular action cluster, pause button, movement hint and status banner with viewport changes; preserve clear space between the movement zone and action hitboxes. Automated checks cover compact landscapes, but physical-device safe-area, cutout and aspect-ratio QA is still required.
- Keep Performance Mode available for weaker phones. It should simplify decorative effects and route rendering while preserving every puzzle-relevant cue; target steadier mobile frame pacing and verify actual FPS, battery and thermals on physical hardware.
- Add a color-blindness-friendly indicator and text/icon cues, not color alone.
- Basic control preferences are implemented: slow/normal/fast movement presets and left-handed joystick placement, saved separately from campaign progress. Reduced motion, color-independent feedback, audio/haptics toggles, localization, and safe-area tuning remain release accessibility work.
- Keep challenge based on planning and route choice.

## Full-game direction

### World and narrative

A network of abandoned courier stations has lost its original inhabitants. A small courier robot finds that movement memories can survive as echoes. Each station's environmental story is told through architecture, short messages, and environmental details rather than long mandatory cutscenes.

### Campaign structure

- **Act I — Signal:** learn movement, recording, latching switches, doors, and safe resets.
- **Act II — Interference:** moving sentinels, timed platforms, one-way routes, and rooms where the recording must take a longer path.
- **Act I extension — Relay sequence:** Chorus Route introduces an ordered pair of Relay Beacons; Triune Relay asks the player to plan three distinct checkpoints before ending on Switch A; Fracture Clock combines that sequence with a timed gate; Dead Air Protocol asks for four checkpoints while the sentinel hunts the player and then tests a 1.8-second gate window.
- **Act III — Relay:** multi-echo puzzles, multiple recording anchors, and chained rooms that reinterpret earlier mechanics.
- **Post-launch — Shared traces:** player-created echoes, curated community challenges, and a daily featured puzzle, contingent on moderation and backend capacity.

### Future mechanics

- Multiple recording slots with explicit limits.
- Moving platforms and switch types (hold, toggle, timed, sequence); Latch Protocol is the first toggle-switch implementation.
- Ordered multi-relay route checkpoints and a retryable timed gate; the first implementations are Chorus Route and Pulse Lock, with more combinations planned only after usability testing.
- Echo-safe surfaces and echo-only sensors.
- More optional Memory Shards with branching lore fragments, never required to finish the main path.
- A level authoring/validation format separate from gameplay code.
- Accessibility settings and localization.
- Cloud saves and asynchronous community recordings only after a secure backend design exists.

## Art direction

The supplied ECHO logo establishes the visual identity: near-black and deep-navy surfaces, a luminous cyan orbit/sphere, and angular corridor geometry. The main menu uses that logo above the ECHOPOST title; an editable SVG icon echoes the tunnel/orbit motif. Panels use dark glass-like navy surfaces with restrained teal borders and glow, while the menu backdrop uses faint receding corridor outlines. The live player and echo are now signal-orbs with an orbital ring, and recorded paths use three restrained glow passes (aura, halo and crisp core). The playfield adds subtle corner-circuit rails and a low-opacity moving signal sweep. Movement-recording trails are cyan/teal, jammed routes turn red, sentinels retain a red danger cue, and the Null Corridor jammer stays violet. Keep objective and hazard readability ahead of decoration; glow must never obscure puzzle state. Authored environment art, animations and polished VFX remain future work.

## Audio direction

Quiet mechanical ambience, a distinct recording start/stop signal, an echo playback shimmer, an unmistakable gate-open cue, and gentle error feedback. Music should not mask puzzle state cues. No audio files are currently required by the prototype.

## Monetization guardrails

- No paid extra echo slots that make puzzles easier.
- No ads during active puzzle play.
- No paid random rewards.
- Prefer character cosmetics, trails, optional soundtrack/art packs, or a premium one-time purchase.
- Keep core story and puzzle completion achievable without spending.
