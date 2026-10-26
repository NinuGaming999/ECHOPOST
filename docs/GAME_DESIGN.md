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

## Current early campaign: six chambers

The current six chambers deliberately vary route length, switch placement, and sentinel patrols while teaching the same two-switch echo mechanic. They are a content foundation, not the final campaign.

- **The First Echo:** a safe introduction to recording, echo playback, and both switches.
- **Long Memory:** introduces the roaming sentinel and separates Switch A from the real player's destination.
- **Split Signal:** moves the switches to opposite sides and increases sentinel speed.
- **Fractured Lane:** asks the player to record a longer diagonal crossing under a wide patrol.
- **Crosscurrent:** places switches in opposite corners and tests route planning before moving toward B.
- **Static Bloom:** uses a long route and wide sentinel sweep to create a busier timing puzzle.

The chapter selector scrolls so future rooms do not collide with the navigation controls. New switch types, checkpoints, moving platforms, and truly different puzzle rules remain future work; do not describe the six current rooms as six distinct mechanics.

## Echo rules

- A recording contains timestamped player positions. A route is accepted only when the final position is on Switch A, so a failed route is explained and can be retried.
- Recording duration is capped to avoid unbounded memory and impossible-to-read paths.
- Echo playback follows recorded samples in time order.
- When playback ends, the echo holds its final recorded position temporarily.
- Echoes press switches by occupying their active area; they do not push the real player or change the recording.
- A future online version must validate uploaded recordings and isolate them from executable code. A recording should be data only, never a script.

## Accessibility and usability

- Use generous touch targets and avoid requiring precise timing on a small touchscreen.
- Add a color-blindness-friendly indicator and text/icon cues, not color alone.
- Offer reduced motion, adjustable movement speed, haptics/audio toggles, and left-handed controls before release.
- Keep challenge based on planning and route choice.

## Full-game direction

### World and narrative

A network of abandoned courier stations has lost its original inhabitants. A small courier robot finds that movement memories can survive as echoes. Each station's environmental story is told through architecture, short messages, and environmental details rather than long mandatory cutscenes.

### Campaign structure

- **Act I — Signal:** learn movement, recording, latching switches, doors, and safe resets.
- **Act II — Interference:** moving sentinels, timed platforms, one-way routes, and rooms where the recording must take a longer path.
- **Act III — Relay:** multi-echo puzzles, multiple recording anchors, and chained rooms that reinterpret earlier mechanics.
- **Post-launch — Shared traces:** player-created echoes, curated community challenges, and a daily featured puzzle, contingent on moderation and backend capacity.

### Future mechanics

- Multiple recording slots with explicit limits.
- Moving platforms and switch types (hold, toggle, timed, sequence).
- Echo-safe surfaces and echo-only sensors.
- Optional collectibles that reveal lore, never required to finish the main path.
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
