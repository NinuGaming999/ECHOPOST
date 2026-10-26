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

## Current early campaign: eight chambers

The current eight chambers progress from the basic two-switch echo rule to route checkpoints and a short timed-gate crossing. They are a content foundation, not the final campaign.

- **The First Echo:** a safe introduction to recording, echo playback, and both switches.
- **Long Memory:** introduces the roaming sentinel and separates Switch A from the real player's destination.
- **Split Signal:** moves the switches to opposite sides and increases sentinel speed.
- **Fractured Lane:** asks the player to record a longer diagonal crossing under a wide patrol.
- **Crosscurrent:** places switches in opposite corners and tests route planning before moving toward B.
- **Static Bloom:** uses a long route, wide sentinel sweep, and one required Relay Beacon checkpoint.
- **Chorus Route:** requires two Relay Beacons to be encountered in order within the recorded route, not just somewhere along the path.
- **Pulse Lock:** opens a 3.5-second crossing window when the echo holds A and the player holds B. If the player is still on the entrance side when the window expires, the gate closes and both switches must be released/rearmed for another attempt. Once the player crosses the barrier in time, the portal remains powered.

The chapter selector scrolls so future rooms do not collide with the navigation controls. Each current chamber also contains one optional Memory Shard that reveals a short courier-network memory. Shards are tracked by chamber and saved locally; the menu's scrollable Memory Archive lets players reread recovered fragments and shows undiscovered entries. Version-1 saves migrate without losing unlocked rooms or completion count. New switch types, checkpoints, moving platforms, and truly different puzzle rules remain future work; do not describe the six current rooms as six distinct mechanics.

## Echo rules

- A recording contains timestamped player positions. A route is accepted only when the final position is on Switch A, so a failed route is explained and can be retried.
- Recording duration is capped to avoid unbounded memory and impossible-to-read paths.
- Echo playback follows recorded samples in time order.
- When playback ends, the echo holds its final recorded position temporarily.
- Echoes press switches by occupying their active area; they do not push the real player or change the recording.
- A room may require route checkpoints. Static Bloom's `echo_waypoint` requires crossing one Relay Beacon; Chorus Route's `echo_waypoints` array requires Relay 1 then Relay 2 in path order. The game checks the nearest point on each sample-to-sample line segment so crossings between samples count. Wrong order or a missed checkpoint is rejected with explicit feedback.
- Pulse Lock defines `gate_open_seconds`. When both switches activate it, the timer ticks only during PLAYING state; timeout closes the gate if the player has not crossed the barrier. A missed attempt stays latched until the player leaves a switch, so standing still cannot immediately reopen the gate. Crossing the barrier before timeout permanently powers the portal for that room.
- Sentinel contact returns the player to the chamber entrance. If the player is still recording, that unfinished take is cancelled and discarded rather than saving a fake teleport back to spawn. Already-released echo behavior is separate from the unfinished take.
- Every current chamber has an optional Memory Shard at its own authored position. Touching it records that room index in local progress and displays a short lore fragment. The Memory Archive can revisit a recovered fragment later. Missing a shard does not block the switches, gate, exit, or campaign unlocks.
- Save schema version 2 stores the collected room indices. Version 1 saves remain loadable and begin with no Memory Shards collected; duplicate, negative, and out-of-campaign indices are filtered during loading.
- A future online version must validate uploaded recordings and isolate them from executable code. A recording should be data only, never a script.

## Accessibility and usability

- Use generous touch targets and avoid requiring precise timing on a small touchscreen.
- Add a color-blindness-friendly indicator and text/icon cues, not color alone.
- Basic control preferences are implemented: slow/normal/fast movement presets and left-handed joystick placement, saved separately from campaign progress. Reduced motion, color-independent feedback, audio/haptics toggles, localization, and safe-area tuning remain release accessibility work.
- Keep challenge based on planning and route choice.

## Full-game direction

### World and narrative

A network of abandoned courier stations has lost its original inhabitants. A small courier robot finds that movement memories can survive as echoes. Each station's environmental story is told through architecture, short messages, and environmental details rather than long mandatory cutscenes.

### Campaign structure

- **Act I — Signal:** learn movement, recording, latching switches, doors, and safe resets.
- **Act II — Interference:** moving sentinels, timed platforms, one-way routes, and rooms where the recording must take a longer path.
- **Act I extension — Chorus Route:** an ordered pair of Relay Beacons teaches players to plan a route through more than one required checkpoint before ending on Switch A.
- **Act III — Relay:** multi-echo puzzles, multiple recording anchors, and chained rooms that reinterpret earlier mechanics.
- **Post-launch — Shared traces:** player-created echoes, curated community challenges, and a daily featured puzzle, contingent on moderation and backend capacity.

### Future mechanics

- Multiple recording slots with explicit limits.
- Moving platforms and switch types (hold, toggle, timed, sequence).
- Ordered multi-relay route checkpoints and a retryable timed gate; the first implementations are Chorus Route and Pulse Lock, with more combinations planned only after usability testing.
- Echo-safe surfaces and echo-only sensors.
- More optional Memory Shards with branching lore fragments, never required to finish the main path.
- A level authoring/validation format separate from gameplay code.
- Accessibility settings and localization.
- Cloud saves and asynchronous community recordings only after a secure backend design exists.

## Art direction

A dark, calm, high-contrast mechanical world with luminous cyan echoes and distinct switch colors. The robot should remain readable against all floors. Procedural art in the first milestone is a placeholder for a consistent authored art set, not the final asset style.

## Audio direction

Quiet mechanical ambience, a distinct recording start/stop signal, an echo playback shimmer, an unmistakable gate-open cue, and gentle error feedback. Music should not mask puzzle state cues. No audio files are currently required by the prototype.

## Monetization guardrails

- No paid extra echo slots that make puzzles easier.
- No ads during active puzzle play.
- No paid random rewards.
- Prefer character cosmetics, trails, optional soundtrack/art packs, or a premium one-time purchase.
- Keep core story and puzzle completion achievable without spending.
