# ECHOPOST — PROJECT PROGRESS / HANDOFF

## 0. Latest verified handoff — Procedural courier animation polish

**Current main merge commit:** `59e024b6323b398ae9efa685ac81dc2ea7371024`  
**Merged pull request:** [#6 — Polish the courier with lightweight hover and echo animations](https://github.com/NinuGaming999/ECHOPOST/pull/6)  
**Godot verification:** [run 41216077479](https://github.com/NinuGaming999/ECHOPOST/actions/runs/41216077479) — success on Godot **4.4.0** and **4.7.2**. Both jobs imported/parsed the project, passed data-layer smoke tests, and passed the full main-scene gameplay smoke tests.

### What changed

- The existing luminous orb remains the courier's core identity, but now reads more clearly as a small signal drone with a horizontal visor, twin stabilizer fins, a floating orbit beacon, and a grounding shadow.
- The live courier gently hovers while idle and leans in its current steering direction. While recording, a restrained amber pulse arc appears around it.
- Both echoes receive a distinct playback shimmer and offset animation phase; the two-echo visual treatment remains distinct through its existing teal/purple tints.
- Decorative courier time advances only during active gameplay and freezes under **Reduced Motion**. Puzzle movement, recording, moving bridges, sentinels, timers and echo playback are unchanged.
- **Performance Mode** keeps the compact rendering path: no additional scene nodes, sprites, imported textures, or per-frame polygon arrays are created for the courier. Full-detail mode retains its existing detailed orbit/highlight path.
- The courier's steering pose is cleared on manual pause, automatic lifecycle pause, room start and automatic failure reset.
- Regression tests verify Reduced Motion freezes the decorative courier clock while gameplay still advances, that the animation resumes after the setting is switched off, and that the pose receives the horizontal steering direction.
- README, game design and roadmap now describe this animation slice and the remaining art tasks.

### Exact current source map

- `scripts/game.gd` — blob `e9be913a3e7d28344393ac50fdc7e8809d3036a7`, 2621 lines:
  - **L48–L49:** decorative animation clock and live steering direction.
  - **L205–L210:** animation clock advances only while actively playing and Reduced Motion is OFF.
  - **L157, L1285, L1778, L1986:** clear the visual steering pose on lifecycle pause, room start, failure reset and manual pause.
  - **L1623:** visual direction derives from the same normalized steering vector used by movement.
  - **L2330–L2336:** animated primary/secondary echoes and live courier draw calls.
  - **L2499–L2585:** procedural courier drone silhouette, steering lean, hover, orbit beacon, echo shimmer and recording arc. Performance Mode stays on the compact no-array path.
- `tests/game_flow_smoke.gd` — blob `5f2dde03baa9b31e0ee2780e225e0d3b5d382a5e`, 1578 lines:
  - **L450–L452:** Reduced Motion freeze regression while the gameplay process continues.
  - **L462–L469:** animation resumes when Reduced Motion is turned off and the visual pose follows horizontal steering.
- `tests/headless_smoke.gd` — blob `2fe303a8ef421a73f4cc75135949619d9d8de918`, 363 lines; unchanged settings/data validation.
- `README.md` — blob `1eea6350b02a34a51e9c9f1ac6b0f49d1d2230c6`, 118 lines; **L39** describes the courier visual identity and accessibility behavior.
- `docs/GAME_DESIGN.md` — blob `2f77acc9bf62149b2dc1b576eb2cb6f5e7af58b7`, 129 lines; **L114–L116** documents the art direction.
- `docs/ROADMAP.md` — blob `8cfa713f49e4772344027ae903a4357c1444bbfa`, 92 lines; **L54–L55** marks this first animation slice complete and leaves contact/gate/portal reactions plus a cohesive sprite set open.

### Verification and remaining limits

- **Godot CI:** run 41216077479 passed both Godot 4.4.0 and 4.7.2, including project import/parse, data tests and the full gameplay smoke suite.
- **Android APK:** the Android export for merge commit `59e024b6323b398ae9efa685ac81dc2ea7371024` has not been confirmed in this handoff. Do not assume the nightly APK includes this courier polish until the export workflow completes successfully.
- **Physical-device QA:** not performed. Inspect the courier at real phone scale, test Reduced Motion on/off, and measure actual low-end-device FPS, battery and heat.
- **Art scope:** this is still original procedural CanvasItem art, not a finished sprite-sheet character. Sentinel-contact, gate-opening and portal-entry reactions, multiple room themes, and the final courier sprite/animation set remain future work.

### Next development tasks

1. Confirm the post-merge Android APK export and install it on a real device for touch, save, lifecycle and visual checks.
2. Add cohesive low-cost themes for the five chapters while keeping room objectives and switch states high-contrast.
3. Add sentinel-contact, gate-opening and portal-entry reactions, then plan a consistent original courier sprite/animation set.
4. Continue 24-room physical-device QA and measure actual low-end performance rather than inferring it from CI.

---


## 0. Latest verified handoff — Independent Music/SFX volume sliders

**Current main merge commit:** `eaaad382c766df9e878d833578f3a707c4465eb9`  
**Merged pull request:** [#5 — Add separate Music and SFX volume sliders](https://github.com/NinuGaming999/ECHOPOST/pull/5)  
**Godot verification:** [run 41199404148](https://github.com/NinuGaming999/ECHOPOST/actions/runs/41199404148) — success on Godot **4.4.0** and **4.7.2**. Both jobs imported/parsed the project and passed the data-layer and complete gameplay smoke tests.

### What changed

- The Options panel now includes independent **Music Volume** and **SFX Volume** sliders, each from **0–100%**, with a live percentage readout.
- Moving either slider immediately adjusts only its own audio player. The existing Music/SFX mute switches and optional Haptics control remain separate.
- Slider positions and percentages refresh from the stored values whenever Options opens or updates. Programmatic UI refresh blocks slider signals so integer-step display rounding cannot change the saved gain.
- The default gains preserve the previous output levels: Music `0.14125375` linear (`-17 dB`) and SFX `0.89125094` linear (`-1 dB`). The visible initial slider values round to approximately **14%** and **89%**.
- Settings are now **schema v5**. Existing v2/v3/v4 settings remain compatible. In particular, v4 Music/SFX mute and Haptics values are preserved, and missing volume fields receive the old output levels.
- The Options card expanded to **540×560** and uses the existing center-pivot scaling so it fits compact landscape screens.
- README, roadmap and game-design notes describe the independent volume controls.

### Exact current source map

- `scripts/core/audio_manager.gd` — blob `38fb2bbc31810b2c3dbc464bc816655816914320`, 185 lines:
  - **L19–L26:** previous-output-compatible Music/SFX defaults and audio state.
  - **L49–L61:** configure both volume values at startup.
  - **L75–L84:** clamp and apply independent linear gains to the two AudioStreamPlayers; zero is mapped to `-80 dB`.
- `scripts/data/settings_store.gd` — blob `7b3cf8822a0f50f785a45f1bfd8dc2e7bdc10d47`, 79 lines:
  - **L9–L36:** default volumes, v2/v3/v4 compatibility, and clamped volume loading.
  - **L40–L67:** schema v5 persistence and 0–1 normalized storage.
- `scripts/game.gd` — blob `0ba0ad51fc8e478a55572268d1054d559dc0444f`, 2555 lines:
  - **L43–L45:** saved Music/SFX volume state.
  - **L524–L590:** expanded Options layout, volume readouts and slider construction.
  - **L577–L589:** 0–100 HSlider configuration.
  - **L695–L707:** separate immediate volume setters.
  - **L730–L759:** ON/OFF controls and percentage refresh; signals are blocked for programmatic slider updates.
  - **L2084–L2100:** load/save of schema v5 preferences.
- `tests/headless_smoke.gd` — blob `2fe303a8ef421a73f4cc75135949619d9d8de918`, 363 lines:
  - **L270–L355:** default-volume checks, v2/v3/v4 migration, v5 persistence and clamping.
- `tests/game_flow_smoke.gd` — blob `7a7c9386ce4b678932ca146fb092bd50e620fbf8`, 1564 lines:
  - **L369–L483:** Options controls, direct slider interaction, live per-channel changes, labels, restore/persistence and expanded-panel layout.
  - **L487–L535:** AudioStreamPlayer gain tests, including zero-volume muting.
  - **L1395–L1401:** compact landscape fit and centered Options assertions.
- `README.md` — blob `fb184159b3dc4c11d046b207b120727ae05264f2`, 118 lines; **L26** describes the sliders/defaults and **L35–L37** documents audio controls.
- `docs/ROADMAP.md` — blob `776a1c915427f415fbc36b2ec10976eca26ce7db`, 91 lines; **L56** marks separate saved volume sliders complete.
- `docs/GAME_DESIGN.md` — blob `b97760673d824c689342b6fd3b2ed2eda4006a8e`, 129 lines; **L57–L59** describes the audio controls.

### Verification and remaining limits

- **Godot CI:** run 41199404148 passed both supported engine versions: project import/parse, data tests and full gameplay smoke tests. The earlier run 41199330877 exposed slider-step rounding of saved values; this was fixed by blocking UI refresh signals and retested successfully on both engines.
- **Android APK:** the post-merge Android export for commit `eaaad382c766df9e878d833578f3a707c4465eb9` has not been confirmed here. Do not assume the current nightly APK contains these sliders until the Android workflow export succeeds.
- **Physical-device QA:** not performed. Check slider touch comfort, audible range, percentage readout size and saved values after app relaunch on real phones.
- **Performance:** sliders only change AudioStreamPlayer gain; no new per-frame processing or imported audio assets were added.

### Next development tasks

1. Confirm the post-merge Android APK export, install it and test both sliders on a real Android phone.
2. Check mute/unmute, saved levels after relaunch, and how the sliders behave on short landscape screens.
3. Tune levels based on actual speaker/headphone listening tests; consider audio-device-specific adjustments only if device tests show a need.
4. Continue the planned character asset/animation polish and visual room themes while preserving Performance Mode and Reduced Motion support.

---

## 0. Previous verified handoff — Procedural audio, puzzle SFX and optional haptics

**Main merge commit at that handoff:** `0e5131a8fb2d27fda134470add527a43bc50191a`  
**Merged pull request:** [#4 — Add procedural ambient audio, puzzle SFX and haptics options](https://github.com/NinuGaming999/ECHOPOST/pull/4)  
**Godot verification:** [run 41196446527](https://github.com/NinuGaming999/ECHOPOST/actions/runs/41196446527) — success on Godot **4.4.0** and **4.7.2**. Both jobs imported/parsed the project and passed the data-layer and complete gameplay smoke tests.

### What changed

- ECHOPOST now generates a quiet **eight-second ambient music loop** locally as mono, 16-bit PCM at **22,050 Hz**. The stream is generated once at startup and looped by Godot; no downloaded music or imported audio asset is needed.
- Seven short original feedback tones are generated once and reused: recording start, echo send, gate opening, Memory Shard pickup, room failure, chamber completion, and a small UI ping.
- **Music** and **SFX** now have independent saved ON/OFF controls in Options. Both default to ON.
- **Haptics** is a separate opt-in setting and defaults to OFF. Short vibration feedback is only invoked on supported Android/iOS/web builds and is clamped to a short duration.
- Haptic use is included in the Android export preset through the standard VIBRATE permission.
- Audio responds to mobile lifecycle changes: the ambient loop pauses and short effects stop when the app is suspended; the loop becomes available again on return. Gameplay still requires an explicit resume.
- Settings are now **schema v4**. Existing v2 and v3 preferences still load; v3 Reduced Motion is preserved, while older files receive Music/SFX ON and Haptics OFF defaults.
- README, roadmap and game-design notes describe the audio layer and remaining production-audio/device-QA work.

### Source map at that handoff

- `scripts/core/audio_manager.gd` — blob `b1ebe2fbc6d19f1f8ff4154066c69b1a2f1dcfa6`, 161 lines:
  - **L1–L27:** sample rate, original note pattern and seven event-tone specifications.
  - **L30–L80:** player setup, independent settings, SFX playback and optional haptics.
  - **L83–L101:** pause/resume behavior for ambient audio.
  - **L104–L161:** one-time PCM generation for the loop and short reusable effects.
- `scripts/data/settings_store.gd` — blob `ffb5469ee782837912c6a131b006fde75b01dff6`, 66 lines:
  - **L10–L25:** defaults and compatibility loading for older v1–v3 preferences.
  - **L28–L53:** schema v4 persistence of Music, SFX and Haptics separately.
- `scripts/game.gd` — blob `ac418268ba249355504ded22f97a4d06f7273b65`, 2486 lines:
  - **L125–L136:** pause/resume audio with application lifecycle notifications.
  - **L518–L565:** compact Options panel with Music/SFX/Haptics controls.
  - **L622–L665:** independent setters and shared feedback hook.
  - **L1279, L1391, L1698, L1750, L1804, L1865:** recording, echo-send, failure, memory, gate-open and chamber-complete cues.
  - **L2017–L2031:** load/save of the complete v4 preference set.
- `tests/headless_smoke.gd` — blob `b47aba94ed860e46bd1a612b5cf63b632eaaf2b7`, 336 lines:
  - **L270–L332:** default values, v2/v3 compatibility, v4 persistence and schema-version assertions.
- `tests/game_flow_smoke.gd` — blob `038d69bdff0c58814a9e716d58a26508418793e0`, 1522 lines:
  - **L30:** audio-manager tests included in the full gameplay suite.
  - **L100–L118:** audio is paused on application suspend and restored on return without resuming gameplay.
  - **L369–L455:** Options exposes and persists independent audio/haptic preferences.
  - **L459–L497:** generated WAV format/loop-size, effects, toggles and suspend/resume regression checks.
- `export_presets.cfg` — blob `cefe781b51012533d639a6ddf3b3bed54e1c6ba2`, 68 lines; **L66** enables Android's standard VIBRATE permission.
- `README.md` — blob `3ecd14ccbedb46ac7aac621e41184bf9138fc7cd`, 118 lines; **L26** describes the controls/defaults and **L35 onward** describes the generated audio.
- `docs/ROADMAP.md` — blob `435c01c92755bff477f060500bdec497295cf5bf`, 90 lines; **L55 and L59** mark the prototype audio and saved toggles as completed; richer production audio and device tuning remain open.
- `docs/GAME_DESIGN.md` — blob `39a3bab93aadf3249f30ba3bafc5ed7e6db34de6`, 129 lines; **L57 onward** describes the current prototype audio/haptic behavior and limitations.

### Verification and remaining limits

- **Godot CI:** run 41196446527 passed both supported engine versions, including project import/parse, data tests and the complete gameplay smoke suite.
- **Android APK:** the post-merge Android export for commit `0e5131a8fb2d27fda134470add527a43bc50191a` has not been confirmed here. Do not assume the latest nightly APK contains these changes until the Android workflow export succeeds.
- **Physical-device QA:** not performed. Listen to the ambient loop and event tones on an actual phone, check relative loudness and looping, and test Haptics on a supported Android device with the option explicitly enabled.
- **Performance:** the audio buffers are generated once at startup and reused; there is no per-frame audio synthesis. Ambient PCM occupies about 345 KiB; the short effect buffers are small.

### Next development tasks

1. Confirm the post-merge Android APK export, install it and listen to all event cues on a physical Android phone.
2. Test opt-in vibration on a device and verify that silent mode, system haptics settings and app suspension behave acceptably.
3. Tune audio levels and consider user-adjustable music/SFX volume sliders after device listening tests.
4. Continue character/room-art polish and full 24-room physical-device QA; this is still an early development build, not a release candidate.

---

## 0. Previous verified handoff — Color-independent puzzle state cues

**Main merge commit at that handoff:** `3c4046c62a1b1b4aa5e5e97f4afb93af20adc65c`  
**Merged pull request:** [#3 — Add color-independent puzzle state cues](https://github.com/NinuGaming999/ECHOPOST/pull/3)  
**Godot verification:** [run 41194278050](https://github.com/NinuGaming999/ECHOPOST/actions/runs/41194278050) — success on Godot **4.4.0** and **4.7.2**. Both jobs imported/parsed the project and passed the data-layer and complete gameplay smoke tests.

### What changed

- Switch A, B and C now show explicit state words beneath their names. The labels cover **ACTIVE**, waiting for the relevant player/echo, and specific B-switch instructions such as **NOT LATCHED**, **PULSE CLOSED**, **MOVE TO B**, and **LATCHED**.
- Switch states now have a check or hollow-circle marker next to the state label, so active/inactive is not communicated by tint alone.
- Relay checkpoints now explicitly show **REQUIRED** or **LINKED**, with an exclamation/check symbol inside the beacon diamond.
- The pulse-window label was moved lower to keep it separate from the new Switch B state label.
- No gameplay rules, timers, room data, settings, extra scene nodes, or per-frame processing were added. Existing rendering uses the same lightweight CanvasItem drawing path.
- README, roadmap and game-design notes describe the new accessibility behavior.

### Source map at that handoff

- `scripts/game.gd` — blob `5cace96ee0cb2c5a3ccc53efc539eda760643063`, 2400 lines:
  - **L2091–L2116:** state text for Switch A, B and C, including toggle/pulse-specific messages.
  - **L2118–L2120:** pulse-window label repositioned below the switch status.
  - **L2195–L2200:** shared switch and relay state-label helpers.
  - **L2203–L2230:** relay warning/check glyph and REQUIRED/LINKED label.
  - **L2289–L2305:** switch state marker and explicit status text.
- `tests/game_flow_smoke.gd` — blob `b9767899deb7cf5fceef56c6af47ac5731140317`, 1459 lines:
  - **L30:** color-independent cue regression test is part of the full game-flow suite.
  - **L436–L442:** active/waiting, pulse-closed/move-to-B, and relay-required/linked label assertions.
- `README.md` — blob `2a9f0ce4369dedd777bb83bcbe07780b75f75574`, 114 lines; **L31 onward** documents puzzle readability/accessibility.
- `docs/ROADMAP.md` — blob `fd5f16cea21e7d18078a98ef03c27e2a1d42f2ca`, 88 lines; **L57** marks color-independent switch/relay indicators complete while audio/haptics settings remain open.
- `docs/GAME_DESIGN.md` — blob `b25fdbc00fe6835ef922ba8ed585a703a27bad5f`, 125 lines; **L57 onward** documents the readable state rules.

### Verification and remaining limits

- **Godot CI:** run 41194278050 passed both supported engine versions, including import/parse, data smoke tests and the complete gameplay smoke suite.
- **Android APK:** the post-merge Android export for commit `3c4046c62a1b1b4aa5e5e97f4afb93af20adc65c` is not confirmed in this handoff. Do not assume the nightly download contains these changes until the Android workflow export succeeds.
- **Physical-device QA:** not performed. Check the new status labels at real phone scale, especially around Switch B's pulse text, and verify touch targets, save persistence, cutouts and lifecycle pause/resume.
- **Performance:** this upgrade adds no scene nodes or per-frame update work; it extends the existing draw routine with a few static shapes and labels.

### Next development tasks

1. Confirm the post-merge Android APK export, install it and inspect switch/relay labels at normal phone viewing distance.
2. Validate the 24 rooms on a physical Android device, including both pulse-switch rooms and the Chapter V two-echo/relay challenges.
3. Add original lightweight sound effects and separate music/SFX/haptics settings without slowing weaker phones.
4. Continue polish of the character assets and animations after device readability/performance checks.

---

## 0. Previous verified handoff — Reduced Motion and compact mobile Options

**Main merge commit at that handoff:** `47b17bb05758a16006c7779c17362007dcb335da`  
**Merged pull request:** [#2 — Add Reduced Motion accessibility and compact Options layout](https://github.com/NinuGaming999/ECHOPOST/pull/2)  
**Godot verification:** [run 41193222360](https://github.com/NinuGaming999/ECHOPOST/actions/runs/41193222360) — success on Godot **4.4.0** and **4.7.2**. Both jobs imported/parsed the project and passed the data-layer and complete gameplay smoke tests.

### What changed

- **Reduced Motion** is now available in Options, separately from Performance Mode. Its default is OFF.
- The separate preference file is now **settings schema v3**. Existing v2 files still load; missing Reduced Motion values default to OFF. Settings remain separate from campaign progress.
- When enabled, Reduced Motion freezes ambient star movement, removes the moving background scan sweep, keeps circuit rails static, suppresses button scale animations, and shows reset cards without a fade.
- Puzzle-critical movement is deliberately unchanged: moving bridges, sentinels, echo playback, pulse switches, gate timers and room resets continue to operate.
- Modal cards now scale down around their center pivot to fit short landscape viewports. The Options card has room for the new control but remains centered and scales to fit compact phones.
- README, roadmap and design documentation now describe Reduced Motion and the 24-room/five-chapter campaign.

### Source map at that handoff

- `scripts/data/settings_store.gd` — blob `0436be3c8d171df8ea8015903778356e1d8ab59a`, 53 lines:
  - **L10–L24:** default settings and v1/v2-compatible loading of the optional Reduced Motion value.
  - **L27–L41:** settings schema v3 save, including the `accessibility/reduced_motion` key.
- `scripts/game.gd` — blob `cbf3f8c4176fb04d6c621dca3b30fabd091a1c66`, 2357 lines:
  - **L38, L158–L160:** setting state and ambient-star freeze.
  - **L501–L525:** expanded Options card and Reduced Motion toggle.
  - **L586–L617:** setting toggle, persistence and on/off label.
  - **L920–L929:** center-pivot modal scaling for compact viewports.
  - **L1083 onward:** suppress UI scale animations.
  - **L1638 onward:** show automatic room-reset feedback without a fade when Reduced Motion is ON.
  - **L1931–L1944:** load/save of the v3 preference.
  - **L2063 and L2076 onward:** static decorative rail and disabled scan sweep.
- `tests/headless_smoke.gd` — blob `dd9853a86928f89d41857afb6aaba1f0dc10f8fe`, 315 lines:
  - **L270–L305:** default OFF, v2 compatibility, v3 persistence, and fallback behavior.
- `tests/game_flow_smoke.gd` — blob `843703ff8a0186bffe80c385435e7d399f8cb818`, 1449 lines:
  - **L365–L431:** Options presence, Reduced Motion toggling, button/star/reset animation suppression, continuing bridge/gameplay motion, and restoration of the saved setting.
  - **L1285 onward:** compact Options card fit and center alignment.
  - **L1175 onward:** Chapter V gameplay regression coverage remains in the suite.
- `scripts/data/level_catalog.gd` — blob `114318ea9f0c701e5db16f0c299a1345e59adf69`, 735 lines; Chapters I–V and all 24 rooms.
- `README.md` — blob `68bd2824c3d194ca1a1db1e150428e5299f2d6b5`, 110 lines; includes Reduced Motion and the 24-room campaign.

### Verification and remaining limits

- **Godot CI:** run 41193222360 passed both supported engine versions, including project import, data tests and the complete gameplay test suite.
- **Android APK:** the Android workflow is configured to run on pushes to `main`, but the post-merge export for this commit has not been confirmed in this handoff. Do not assume the nightly APK already contains Reduced Motion until the export succeeds.
- **Physical-device QA:** not performed. Test the new Option on a real Android phone, especially a short landscape screen; also verify touch targets, save persistence, and lifecycle pause/resume.
- **Performance:** no new per-frame scene nodes or particle emitters were added. Performance Mode remains ON by default for weaker phones; Reduced Motion is independent and OFF by default.

### Next development tasks

1. Install the post-merge nightly APK after its build succeeds and confirm the Reduced Motion toggle persists after closing/reopening the app.
2. Test the Options card and touch buttons on short landscape phones and unusual aspect ratios; verify operating-system safe areas/cutouts on hardware.
3. Play Orbit Crossing, Tandem Relay and The Last Duet on a phone to check bridge boarding, route readability, pulse timing and Memory Shard pickup.
4. Continue the accessibility pass with color-independent cues, audio/haptics settings and reduced-flash review before adding more content.

---

> **This file is the continuity record for future ECHOPOST development.** Read it before changing code. The game is deliberately an unfinished long-running project; do not treat the current twenty-four-room prototype as complete. After every meaningful code, test, gameplay, or build change, update this file with what changed, why, exact file/line references, current verification results, and the next actionable tasks.

**Repository:** https://github.com/NinuGaming999/ECHOPOST  
**Working branch:** `main`  
**Project root:** repository root; main scene is `res://scenes/main.tscn`  
**Engine:** Godot 4.x; CI tests Godot 4.4.0 and 4.7.2  
**Target:** Android-first landscape game; desktop builds support development and testing  
**Current main gameplay commit:** `eaaad382c766df9e878d833578f3a707c4465eb9` — 24-room Chapter V campaign, responsive mobile controls, Reduced Motion, color-independent puzzle cues, procedural ambient audio/SFX, optional haptics and saved Music/SFX volume sliders.  
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
**Current main controller source blob:** `0ba0ad51fc8e478a55572268d1054d559dc0444f` (2555 lines)  
**Current gameplay regression-test blob:** `7a7c9386ce4b678932ca146fb092bd50e620fbf8` (1564 lines)  
**Current settings-store blob:** `7b3cf8822a0f50f785a45f1bfd8dc2e7bdc10d47` (79 lines); schema v5 stores Performance Mode, Reduced Motion, Music/SFX toggles and volume levels, and Haptics separately.  
**Low-end rendering commits:** saved Performance Mode preference [30f1189](https://github.com/NinuGaming999/ECHOPOST/commit/30f1189f7f8c03805b1c58fabf4abc94d5cd9c06), render/route optimization [1904ad8](https://github.com/NinuGaming999/ECHOPOST/commit/1904ad8f9b34a56c30873fba47258ef10e7cc0a1), regression tests [9297624](https://github.com/NinuGaming999/ECHOPOST/commit/929762484dd228eb3ca1d22da3c2ca41d8dc66bf), and final joystick/HUD cleanup [36622a5](https://github.com/NinuGaming999/ECHOPOST/commit/36622a5488f3cb4073b8692ae85a768b62710d43).  
**Latest Godot CI for multi-echo source:** [run 41132293123](https://github.com/NinuGaming999/ECHOPOST/actions/runs/41132293123) passed on Godot 4.4.0 and 4.7.2 for the 21-room Chapter IV revision.  
**Latest Android APK export:** [run 41132293283](https://github.com/NinuGaming999/ECHOPOST/actions/runs/41132293283) succeeded for the 21-room multi-echo gameplay revision and refreshed the nightly APK.  
**Round-glass in-game action HUD:** source [`eeca6c96eed7783176ef704d8889f5f57fe35d52`](https://github.com/NinuGaming999/ECHOPOST/commit/eeca6c96eed7783176ef704d8889f5f57fe35d52), responsive size/minimum fix [`dc7538dc2702e64ac097978c683b26dd5200749d`](https://github.com/NinuGaming999/ECHOPOST/commit/dc7538dc2702e64ac097978c683b26dd5200749d), status/hint safe-lane layout [`7537dcf7f6222b9cdb9d98fe344ccc997d1bc306`](https://github.com/NinuGaming999/ECHOPOST/commit/7537dcf7f6222b9cdb9d98fe344ccc997d1bc306), circular HUD regression tests [`36f598d08cc667d1b610a3c0bbacca88f09d5133`](https://github.com/NinuGaming999/ECHOPOST/commit/36f598d08cc667d1b610a3c0bbacca88f09d5133)  
**Latest Godot CI for the round-control revision:** [run 40860534243](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40860534243) passed on Godot 4.4.0 and 4.7.2.  
**Latest Android APK export for the same code/test commit:** [run 40860534080](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40860534080) succeeded and refreshed the nightly APK.  
**Touch-comfort control commits:** broad floating joystick zone and response curve [`b663ebb6596d8f1bdc6640dc8905e0d48147f853`](https://github.com/NinuGaming999/ECHOPOST/commit/b663ebb6596d8f1bdc6640dc8905e0d48147f853), eased movement/lifecycle and handedness reset [`5839ef7c7236a29487b77cd406a2ed0277f7c789`](https://github.com/NinuGaming999/ECHOPOST/commit/5839ef7c7236a29487b77cd406a2ed0277f7c789), comfort regression tests [`42c8b0c2b6ea1e00b6375dd3a48504b3bc6f198a`](https://github.com/NinuGaming999/ECHOPOST/commit/42c8b0c2b6ea1e00b6375dd3a48504b3bc6f198a)  
**Latest verified Godot CI:** [run 40857698994](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40857698994) passed on Godot 4.4.0 and 4.7.2.  
**Latest Android APK export:** [run 40857698999](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40857698999) succeeded for the same source/test commit.  
**Latest visual refinement commits:** orbit-orb/route glow [`dfa3672fd57cafb7b7b537d57ea606f1272b3004`](https://github.com/NinuGaming999/ECHOPOST/commit/dfa3672fd57cafb7b7b537d57ea606f1272b3004), polished orb renderer [`e7d8edabf723104767f00f176e3e741cc25e74ad`](https://github.com/NinuGaming999/ECHOPOST/commit/e7d8edabf723104767f00f176e3e741cc25e74ad), circuit rails/signal sweep [`204f37d2c12858a590491bb959f57782138a61c8`](https://github.com/NinuGaming999/ECHOPOST/commit/204f37d2c12858a590491bb959f57782138a61c8), logo regression assertions [`42f31a31811570bc224004f833ba4ab333eddbda`](https://github.com/NinuGaming999/ECHOPOST/commit/42f31a31811570bc224004f833ba4ab333eddbda)  
**Latest verified Godot CI:** [run 40851002676](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40851002676) passed on Godot 4.4.0 and 4.7.2.  
**Latest verified Android APK:** [run 40851002626](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40851002626) succeeded for the same source/test commit.  
**Current level catalog blob:** `3a148fbc1211bcc0920bc9d02db718d39a1bf9cd` (656 lines; 21 rooms, Chapter IV and two-echo schema validation)  
**Current data smoke-test blob:** `131fa0b7bb95cb1e8baa485905bc799b6055c3d6` (278 lines; platform, pulse-switch and two-echo schema validation)  
**Supplied ECHO logo:** `assets/echopost_logo.jpg` (blob `7dd3e438e5cd152eb0120e59833c25611f0036f1`)  
**Matching SVG identity icon:** `assets/echopost_icon.svg` (67 lines; blob `0eaae23f67fc11c19a101c2eec6ef3a88f06a543`)  
**Current project-settings blob:** `aaf2ca779d5ca128ec5d41b25f33102d883e045c` (44 lines; project icon uses the supplied ECHO logo)  
**Current Android export-preset blob:** `a0ba9ce2ea2711d37ebcd025df7897435cbbdc01` (67 lines; launcher icon uses the supplied logo and splash background matches the theme)  
**Latest completed Godot CI for current controller/test blobs:** [run 40848778896](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40848778896) passed on Godot 4.4.0 and 4.7.2.  
**Android launcher icon verification:** [run 40848778926](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40848778926) succeeded; the supplied ECHO logo exported as the Android launcher icon and the nightly APK was refreshed. [Direct APK](https://github.com/NinuGaming999/ECHOPOST/releases/download/nightly/ECHOPOST-android.apk).
**Android ETC2/ASTC export fix commit:** `e713071219c15d514e0552c099437c265e22b4e2`  
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

The current source includes twenty-one authored chamber layouts across four signal chapters, including two independent echo slots and Switch C:
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
- **Null Corridor:** a 105-unit purple echo-only jammer rejects any recording whose line segments enter the field. The direct spawn-to-Switch-A route is blocked; a curved route above the field is accepted. The live player can cross the jammer without a collision.
- **Glass Horizon:** three ordered relays and a wide sentinel sweep.
- **Clockbreak Crossing:** three ordered relays followed by a 2.8-second timed gate.
- **Switchback Protocol:** two ordered relays, an echo-only jammer bypass, and a latched Switch B.
- **The Last Chorus:** four ordered relays, an echo-only jammer bypass, a moving sentinel, and a 2.8-second gate window.
- **Drift Bridge:** a moving platform carries the live player across a full-height void zone; unsupported movement into the gap is blocked, and platform time pauses with gameplay.
- **Phase Relay:** Switch B is active only during a repeating pulse window, followed by a 3.2-second timed gate.

The first five rooms teach the two-switch echo mechanic with varied geometry/patrols. Static Bloom introduces a single required gold Relay Beacon; Chorus Route requires two beacons in order; Pulse Lock adds a timed crossing and retry rule; Latch Protocol adds a toggle switch; Triune Relay extends ordered route planning to three checkpoints; Fracture Clock combines the three-relay sequence with a timed crossing; Dead Air Protocol combines four relays, active sentinel evasion and a short timed gate. Relay tests check line segments between samples, so a crossing between samples is valid. Twenty-one rooms across four chapters are still a prototype, not a finished campaign.

The menu identity uses the supplied ECHO logo and a matching cyan geometric SVG icon; room/character art is still drawn procedurally in `scripts/game.gd`. Procedural visuals keep the project importable without an asset pack but are placeholder art, not final art. Each chamber also has one optional Memory Shard that reveals a short courier-network lore fragment.

## 2. Latest work in this development pass

### October 31, 2026 — Chapter III: moving bridges and pulse switches

**Goal:** introduce mechanics that change how the player navigates and times a gate, rather than only recombining earlier relay/sentinel rules.

- Added chamber 18, **Drift Bridge**: a moving platform shuttles across a full-height void zone. The real player is carried by platform displacement while retaining steering; unsupported steps into the gap are blocked. Echo tracks remain world-space recordings and are not moved by the live bridge.
- Added chamber 19, **Phase Relay**: Switch B pulses for 2.1 seconds in a 5.5-second cycle. The player and echo must occupy their switches during the live phase; success starts a 3.2-second gate window.
- Added catalog validation for platform endpoints, deck size, travel distance, speed, void geometry and pulse timing. Added data/gameplay regressions for rider carry, safe support, pulse off/on phases and gate activation.
- Chapter Select labels the two new rooms as Chapter III. Existing saves continue to unlock the additions through normal campaign progress.
- Godot 4.4.0 and 4.7.2 tests plus the Android APK export passed on source commit `6868983cd1ae6dea14a0c730ebe56b3f174f8cf8`.
- Physical Android playtesting remains outstanding; do not infer actual device performance or touch comfort from CI.

### October 31, 2026 — Chapter II campaign expansion

**Goal:** add substantial new content by combining familiar echo mechanics in harder, carefully spaced rooms without introducing new mobile-control complexity.

- Added four authored Chapter II rooms: Glass Horizon, Clockbreak Crossing, Switchback Protocol, and The Last Chorus. Campaign total is 17 rooms (13 original + 4 new).
- Chapter II reuses the existing ordered-relay, sentinel, echo-only jammer, toggle-switch, and timed-gate systems. Older save files retain their unlocked room indices; the new chambers unlock through normal progression.
- Chamber Select prefixes Chapter II rooms with `CH. II`; its scrollable list and the Memory Archive continue to size themselves from `LEVELS.size()`.
- Added a regression test that validates the full catalog, checks all final-room mechanics, verifies the four-relay route bypasses the jammer and fits within the 8-second recording cap, and confirms the final room loads.
- Updated README, game design, roadmap, build status, and continuity notes to reflect the expanded 17-room campaign.
- CI is being run for the current source revision; do not mark this change verified until both Godot versions and the Android export finish.

### October 30, 2026 — Low-end rendering and frame pacing

**Goal:** reduce avoidable CPU/GPU work per frame and provide a saved low-end-device preset without removing puzzle-critical feedback.

- `scripts/game.gd:L545–L558` and `L1651–L1664`: Performance Mode defaults ON for fresh installs and older settings files. It is switchable in Options and stored separately from campaign progress. On mobile it targets 30 FPS for steadier frame pacing; turning it off restores full visual effects and a 60 FPS mobile cap. Desktop/editor pacing is unchanged.
- `scripts/game.gd:L1733–L1849`: halves room-grid density, skips animated corner rails and scan sweep, and lowers tessellation for jammer/relay/switch/gate/portal decorations in Performance Mode. Puzzle cues remain visible.
- `scripts/game.gd:L1925–L1954` and `L1957–L1970`: Performance Mode uses a lower-allocation orb renderer and fewer joystick arc segments.
- `scripts/game.gd:L1974–L1991`: routes are batched into PackedVector2Array polylines. Performance Mode submits one polyline per route instead of three draw calls per segment; full mode retains three glow passes as three batched polylines.
- `scripts/game.gd:L1220–L1242`: Null Corridor's live jammer preview checks each new sampled segment once and caches the result, rather than rescanning the whole recorded route on every rendered frame. Final route validation remains in place.
- `scripts/game.gd:L1598–L1643`: HUD text, tooltips and states are only written when displayed values change.
- `scripts/data/settings_store.gd:L9–L29`: settings schema v2 persists `graphics/performance_mode`; old preference files safely default to ON.
- `tests/headless_smoke.gd:L206–L229` and `tests/game_flow_smoke.gd:L360–L399`, `L907–L959`: cover default-on settings, save/load, Options toggling, and route-segment collision math.
- Source/test commits: [settings schema](https://github.com/NinuGaming999/ECHOPOST/commit/30f1189f7f8c03805b1c58fabf4abc94d5cd9c06), [render and route optimization](https://github.com/NinuGaming999/ECHOPOST/commit/1904ad8f9b34a56c30873fba47258ef10e7cc0a1), [regression suite](https://github.com/NinuGaming999/ECHOPOST/commit/929762484dd228eb3ca1d22da3c2ca41d8dc66bf), [final UI cleanup](https://github.com/NinuGaming999/ECHOPOST/commit/36622a5488f3cb4073b8692ae85a768b62710d43).
- **Godot verification:** [run 41091283098](https://github.com/NinuGaming999/ECHOPOST/actions/runs/41091283098) passed import/parse, data and gameplay-flow tests on both Godot 4.4.0 and 4.7.2.
- **Android verification:** [run 41091282986](https://github.com/NinuGaming999/ECHOPOST/actions/runs/41091282986) exported, integrity-checked and published the APK for the same tested source revision. [Direct APK](https://github.com/NinuGaming999/ECHOPOST/releases/download/nightly/ECHOPOST-android.apk).
- **Measurement boundary:** no physical low-end handset or GPU profiler was available. Code-level work was reduced and CI passed, but actual FPS, battery and thermals still need measurement on hardware.

### October 29, 2026 — Round glass in-game action controls

**Goal:** make the controls look and feel like part of the ECHO world rather than a row of generic rectangular menu buttons, while keeping thumb reach, safe spacing, and action-state clarity first.

- `scripts/game.gd:L310–L344`: the gameplay HUD creates the large primary **REC** circle on the right by default, with the optional Latch circle adjacent to it. Pause, menu and restart are compact round utility controls. The recording button changes to a square/remaining-time label while recording; latch labels stay short enough for a circle.
- `scripts/game.gd:L602–L844`: responsive HUD layout sizes the circle diameter from viewport height, places Record above the bottom utility circles, and mirrors the action cluster to the left when left-handed mode is enabled. The movement hint follows the movement half, becomes a short line on compact screens and hides below 380 units. The center status banner narrows to avoid the side action cluster.
- `scripts/game.gd:L948–L1000`: `_style_game_action_button()` gives in-game actions translucent dark-glass fills, neon-cyan borders, rounded corners, subtle glow and clear hover/pressed/disabled states. It reapplies minimum size, control size and centered pivot together so Godot's theme minimum cannot turn circles back into stretched rectangles during viewport resize.
- `scripts/game.gd:L1549–L1586`: recording state and latch state use concise circular-button labels; the complete action is still available through tooltips and status feedback.
- `tests/game_flow_smoke.gd:L950–L1126`: regression checks cover round shape, transparent fill, right-side default placement, left-handed mirroring, independent action hitboxes, status/movement guidance clearance, and safe bounds/non-overlap at 640×360, 720×360 and 800×320.
- Source/style commits: [HUD circles](https://github.com/NinuGaming999/ECHOPOST/commit/eeca6c96eed7783176ef704d8889f5f57fe35d52), [responsive sizing](https://github.com/NinuGaming999/ECHOPOST/commit/dc7538dc2702e64ac097978c683b26dd5200749d), [compact movement hint and latch labels](https://github.com/NinuGaming999/ECHOPOST/commit/9cee4f5965376756b83bb7c64658337c8db8e4ea), [centered resize pivot](https://github.com/NinuGaming999/ECHOPOST/commit/bae0269a246ce9d1b711daa62cc5881fd48f2e1a), [status/hint spacing](https://github.com/NinuGaming999/ECHOPOST/commit/7537dcf7f6222b9cdb9d98fe344ccc997d1bc306), [regression tests](https://github.com/NinuGaming999/ECHOPOST/commit/36f598d08cc667d1b610a3c0bbacca88f09d5133).
- **Godot verification:** [run 40860534243](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40860534243) passed project import/parse, data smoke and gameplay-flow smoke tests on both Godot 4.4.0 and 4.7.2.
- **Android verification:** [run 40860534080](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40860534080) exported, integrity-checked and published the APK for the same source/test revision. [Nightly download](https://github.com/NinuGaming999/ECHOPOST/releases/download/nightly/ECHOPOST-android.apk).
- **Physical-device QA:** still outstanding. Confirm thumb comfort, safe-area/cutout behavior and action reach on a real phone; the automated checks cover logic/layout, not physical ergonomics.

### October 29, 2026 — Player-comfort touch controls

**Goal:** replace the tiny fixed-corner feel with modern floating-thumb movement while preserving keyboard precision, left-handed play and reliable recording.

- `scripts/game.gd:L186–L226`: touch/mouse input still uses a single tracked movement finger, but pickup is allowed throughout the player's side of the playfield instead of just the outer 23%. Top HUD, center gutter and the full bottom action band are excluded so aiming fingers cannot casually hit Pause, Menu, Record or Restart.
- `scripts/game.gd:L227–L252`: `_is_joystick_area()` applies viewport-relative side zones; `_shape_touch_stick()` uses an 8-unit radial dead zone, remaps short thumb drags to a useful partial range, and caps/normalizes large drags. The floating base anchors where the thumb lands, so players don't have to find a fixed on-screen nub first.
- `scripts/game.gd:L1204–L1228`: keyboard movement stays immediate. Touch input uses a short ease-in curve and faster ease-out; releasing the finger stops the courier quickly without harshly snapping from full speed. Left/right diagonal input is capped to the same maximum speed.
- `scripts/game.gd:L512–L523`: changing handedness clears both target and filtered input, reflows the movement hint to the new side and persists the setting. Suspending the app clears movement smoothing as well so no residual drift survives a pause.
- `scripts/game.gd:L1793–L1808`: the active pad has a larger glass-like base, inner guide ring and a smaller travel puck so the visible thumb indicator stays within the pad. The inactive hint sits on the configured side.
- `tests/game_flow_smoke.gd:L899–L949`: new comfort regressions cover wide pickup zones, protected top/bottom UI, the center gutter, left-handed zone inversion, jitter dead zone, short-drag precision, capped movement/diagonals, ease-in and no residual drift after release. Existing tests continue to check bottom action non-overlap over compact viewports.
- **Godot verification:** [run 40857698994](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40857698994) passed project import/parse, data smoke and gameplay-flow tests on both Godot 4.4.0 and 4.7.2.
- **Android export:** [run 40857698999](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40857698999) exported, archive-checked and published the APK for the exact same code/test commit. [Direct APK](https://github.com/NinuGaming999/ECHOPOST/releases/download/nightly/ECHOPOST-android.apk).
- **Physical-device QA:** still required. Confirm thumb comfort on different screen sizes, test left-handed mode and assess the dead zone/stop easing on an actual phone.

### October 29, 2026 — Supplied ECHO logo and neon-cyan theme

- `assets/echopost_logo.jpg`: the supplied ECHO logo is used on the main menu, as the `project.godot` icon and in Android's `launcher_icons/main_192x192` field.
- `assets/echopost_icon.svg`: matching editable vector identity uses dark navy, a geometric tunnel, orbiting path and signal sphere.
- `project.godot`: deep navy default background and the supplied logo as the project icon (blob `aaf2ca779d5ca128ec5d41b25f33102d883e045c`).
- `export_presets.cfg`: Android launcher icon uses `res://assets/echopost_logo.jpg`; splash background matches the near-black navy theme (blob `a0ba9ce2ea2711d37ebcd025df7897435cbbdc01`).
- `scripts/game.gd:L1500–L1537`: menu background uses a low-contrast geometric tunnel/orbit. Panels/buttons use navy glass surfaces, fine teal/cyan borders and restrained glow. Gameplay room corners have subtle circuit rails and a low-opacity moving signal sweep, while the original grid and objectives remain prominent.
- `scripts/game.gd:L1545–L1662`: room palette and accents use dark teal/cyan; Null Corridor's jammer remains violet and jammed routes remain red for puzzle clarity.
- `scripts/game.gd:L1736–L1783`: player/echo markers now match the logo's signal-orb and orbital ring. Route traces render as layered aura/halo/core strokes, giving live and recorded paths a brighter neon-glass treatment without changing their underlying movement samples.
- Responsive menu: logo appears at 620 design units or taller and hides before compact reflow; intro changes to one line and hides below 340, and progress hides below 280. Full-height layouts restore the logo, two-line intro and normal button positions.
- `tests/game_flow_smoke.gd:L993–L1005`: ten viewport sizes check logo visibility/texture loading and now assert that the menu loads `res://assets/echopost_logo.jpg` and `ProjectSettings.application/config/icon` points to that same supplied logo. Existing tests continue to cover touch-target sizes, menu bounds and HUD action spacing.
- Visual refinement commits: orbit-orb/route glow [`dfa3672fd57cafb7b7b537d57ea606f1272b3004`](https://github.com/NinuGaming999/ECHOPOST/commit/dfa3672fd57cafb7b7b537d57ea606f1272b3004), polished orb renderer [`e7d8edabf723104767f00f176e3e741cc25e74ad`](https://github.com/NinuGaming999/ECHOPOST/commit/e7d8edabf723104767f00f176e3e741cc25e74ad), circuit rails/signal sweep [`204f37d2c12858a590491bb959f57782138a61c8`](https://github.com/NinuGaming999/ECHOPOST/commit/204f37d2c12858a590491bb959f57782138a61c8), logo assertions [`42f31a31811570bc224004f833ba4ab333eddbda`](https://github.com/NinuGaming999/ECHOPOST/commit/42f31a31811570bc224004f833ba4ab333eddbda).
- **Godot verification:** [run 40851002676](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40851002676) passed import/parse, data smoke and gameplay-flow smoke tests on Godot 4.4.0 and 4.7.2.
- **Android verification:** [run 40851002626](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40851002626) exported and published the themed APK, with archive integrity validation and artifact upload. [Nightly APK](https://github.com/NinuGaming999/ECHOPOST/releases/download/nightly/ECHOPOST-android.apk).
- **Physical-device QA:** still open; inspect logo legibility, glow readability, safe areas, touch reach, saves and background/foreground behavior on an actual phone.

### October 27, 2026 — Null Corridor: echo-only jammer puzzle

**Scope:** introduce a route-geometry mechanic that changes how recorded movement is planned, without adding another timer or changing the real player's movement rules.

- `scripts/data/level_catalog.gd:L206–L224`: the thirteenth chamber, **Null Corridor**, defines spawn (150, 500), Switch A (920, 500), Switch B (1060, 220), a purple jammer at (520, 470), radius 105, a Memory Shard, and a new lore fragment. The direct route from spawn to A crosses the jammer; the intended valid route curves through the upper part of the room.
- `scripts/data/level_catalog.gd:L289–L316`: the schema validator checks the jammer position type, requires a numeric radius paired with a position, limits radius to 40–180 units, requires separation from spawn/switches/shard, and applies normal room-bound checks.
- `scripts/game.gd:L948–L1009`: `_finish_recording()` rejects a route if any recorded line segment comes within the jammer radius using the existing nearest-point route checker. It clears the echo/take, explains **ECHO DEAD ZONE**, and schedules the same-room reset with reason **ECHO JAMMED**. The live robot itself is not collision-tested against the jammer.
- `scripts/game.gd:L1441–L1538`: the room renderer draws a dark violet field, two rings, a core marker and an **ECHO DEAD ZONE** label. During recording, a route that crosses the jammer changes from amber to red so the player can see the mistake before sending.
- `tests/headless_smoke.gd:L50–L161`: validates the 17-room campaign, Null Corridor metadata, Chapter II combinations, and malformed jammer/route drafts.
- `tests/game_flow_smoke.gd:L772–L815`: confirms the direct route intersects the field, fails to release an echo and schedules an automatic reset; after reset, a curved route through (330, 300) and (700, 300) stays outside the field and creates a working echo.
- Data commit: [`96d29593ff0d613bc838bc9d9673072272973893`](https://github.com/NinuGaming999/ECHOPOST/commit/96d29593ff0d613bc838bc9d9673072272973893); gameplay/render commit: [`9edd2f74ce9008ea13b5c001ef222bc7f44f0698`](https://github.com/NinuGaming999/ECHOPOST/commit/9edd2f74ce9008ea13b5c001ef222bc7f44f0698); schema tests: [`8e81c985b2b95a98a03313f8cc4467165818c571`](https://github.com/NinuGaming999/ECHOPOST/commit/8e81c985b2b95a98a03313f8cc4467165818c571); gameplay integration test: [`0fa845518310f1d022af98bbc219a96c58a5d48b`](https://github.com/NinuGaming999/ECHOPOST/commit/0fa845518310f1d022af98bbc219a96c58a5d48b).
- **Godot verification:** [run 40550158187](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40550158187) passed project parse/import, data smoke tests and gameplay-flow smoke tests on both Godot 4.4.0 and 4.7.2. The gameplay test verifies both a rejected route and a safe bypass.
- **Android verification:** [run 40550158280](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40550158280) successfully exported, integrity-checked, uploaded, and published the debug APK. [Nightly download](https://github.com/NinuGaming999/ECHOPOST/releases/download/nightly/ECHOPOST-android.apk). Physical-device testing, visual readability and fairness remain outstanding.

### October 27, 2026 — Compact landscape menu and gameplay HUD hardening

**Scope:** keep menu and gameplay touch controls usable on narrow and short landscape screens, including cross-version theme constraints.

- `scripts/game.gd:L562–L731`: for viewports shorter than 420 units, the main menu uses two columns and three rows. Row placement is based on each button's actual theme-enforced size, not just the requested size. Below 340 units, the intro paragraph is hidden and the title/tagline move up; below 280 units, the progress line hides to free space. These elements return when the viewport grows.
- `scripts/game.gd:L695–L728`: the gameplay HUD bottom row now sizes navigation and record/latch actions against the available width so outer controls cannot overlap the center actions. Record/latch text shrinks proportionally; the outer controls shorten to **MENU** and **RESTART** on narrow widths.
- `tests/game_flow_smoke.gd:L911–L960`: main-menu regression checks the original 800×360 case plus 640×360, 800×320, 800×280 and 800×260. It verifies visibility policy, viewport/progress bounds, touch height and pairwise non-overlap.
- `tests/game_flow_smoke.gd:L962–L981`: gameplay HUD controls are checked at 640×360, 720×360 and 800×320 for horizontal clipping, consistent bottom inset and pairwise non-overlap.
- Compact-height source commit: [`c731fb0f81d0229057faf3ffcb9f5bfaa7f89438`](https://github.com/NinuGaming999/ECHOPOST/commit/c731fb0f81d0229057faf3ffcb9f5bfaa7f89438); expanded menu tests: [`9a01c85d687207726b8fff02703fcfc4c638042d`](https://github.com/NinuGaming999/ECHOPOST/commit/9a01c85d687207726b8fff02703fcfc4c638042d); HUD sizing fix: [`c916a86d2ce1e911a33762fa474d270e50f75644`](https://github.com/NinuGaming999/ECHOPOST/commit/c916a86d2ce1e911a33762fa474d270e50f75644); HUD regression tests: [`e60e235282b16209670a2a675df7339e2f8d1bb4`](https://github.com/NinuGaming999/ECHOPOST/commit/e60e235282b16209670a2a675df7339e2f8d1bb4).
- **Godot verification:** [run 40548485659](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40548485659) passed project import/parse, data-layer smoke tests and gameplay-flow smoke tests on both Godot 4.4.0 and 4.7.2.
- **Android verification:** [run 40548485495](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40548485495) exported the APK, passed archive integrity validation, uploaded the Actions artifact and refreshed the [ECHOPOST Nightly APK](https://github.com/NinuGaming999/ECHOPOST/releases/tag/nightly) from the same code/test commit. The APK remains a debug-signed build; physical-device installation/play-testing is still outstanding.

### October 27, 2026 — Android export recovery and mobile-layout CI failures fixed

**Scope:** diagnosis and correction of the Android export configuration error and the responsive-menu regression tests. These are focused reliability fixes; they do not mark the game as finished.

- **Android export root cause:** Godot's Android exporter required ETC2/ASTC texture import. Added `textures/vram_compression/import_etc2_astc=true` to `project.godot` (current blob SHA `e8242ef990cbeecfe7972c65a7bb93d2bf2cbad3`, 44 lines). The export preset is tracked in `export_presets.cfg` (SHA `6c2e8278c715c8eb5e9b98d8ec4b3731d217bea4`, 67 lines). The package ID is `com.ninugaming.echopost`; the preset targets arm64-v8a.
- **Compact menu root cause:** the compact menu layout used a fixed top position that did not reliably respect the actual Intro control bounds across Godot versions and could push the last button down into the progress line. `scripts/game.gd:L562–L664` now derives the initial stack position from the actual Intro bounds and reduces inter-button spacing when needed to fit the progress line. Source change: `0f09dba86c6c01ecc74c967f063a52b5859b2a4d`.
- **Touch-zone test setup root cause:** the wide-view test enabled left-handed joystick mode and accidentally carried that state into the following compact left-side assertion. `tests/game_flow_smoke.gd:L851–L912` now explicitly resets handedness before compact left-zone checks, then tests the right-zone case separately. The compact menu assertion includes measured positions in its failure message for easier diagnosis. Test commit: `d64199633af306574298e3ce5972630ff3379b88`.
- **Verification:** [Godot CI run 40493513243](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40493513243) passed all import/parse, data smoke and game-flow smoke steps on both Godot 4.4.0 and 4.7.2 at source/test commit `d64199633af306574298e3ce5972630ff3379b88`.
- **Android export:** [Android APK run 40493513100](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40493513100) completed successfully for that same source/test commit. Godot exported the APK, `unzip -t` validated the package, and GitHub Actions uploaded/published `ECHOPOST-android.apk` to the [ECHOPOST Nightly Release](https://github.com/NinuGaming999/ECHOPOST/releases/tag/nightly) (about 28.6 MB).
- **Important boundary:** this confirms export and APK archive integrity, **not** installation or gameplay on a physical phone. The APK is a debug-signed testing build, not a production-signed Google Play release. Do not mark real-device QA complete until installation, touch controls, lifecycle pause/resume, saving and all twenty-one rooms have been checked on hardware.

### Automatic room resets and premium, responsive touch UI
**Current feature pass. Changed:** `scripts/game.gd`, `tests/game_flow_smoke.gd`, README, design, roadmap and build-status docs.

- `scripts/game.gd:L131–L180`: a pending failure reset gets its own short timer path, ignores movement/actions, and restarts the current room without another tap. Processing returns immediately on the frame a sentinel collision triggers failure, so puzzle/gate checks do not continue after death.
- `scripts/game.gd:L871–L922`: in rooms with required relay(s), finishing away from Switch A, missing a single beacon, or visiting ordered relays out of sequence clears the attempt and schedules an automatic same-room reset. A short recording still asks the player to keep recording; non-relay endpoint mistakes remain retryable.
- `scripts/game.gd:L1050–L1097`: `_room_requires_relay()` and `_schedule_room_reset()` centralize failure handling. A red SIGNAL LOST/relay-failure card explains why, disables the normal HUD, displays a shrinking reset bar, discards the unfinished take and resets the player position immediately; after 0.85 seconds, `_start_level(current_level_index)` restores the full room state.
- `scripts/game.gd:L524–L654`: new failure-card UI, centered modal layout, responsive menu/HUD placement, a shared darker premium panel/button theme, larger bottom controls (54 design units) and a 48-unit pause target.
- `scripts/game.gd:L698–L755`: common button style now has softened shadows, bordered states and short press/hover tweens. `L562–L660` reflows the menu, pause/status labels, bottom action row, joystick hint and modal panels when the viewport changes. `L219–L231` uses proportional joystick hit regions for either handedness.
- `tests/game_flow_smoke.gd:L851–L903` checks mobile touch heights, viewport-driven anchoring, compact 960×540 menu layout, non-overlapping actions, centered animation pivots and left/right joystick regions.
- Initial reset commit: `ecc3243707091262f791fc700f1abf3d79e43ff0`; latest controller commit: `e2f9b9a0adc876aca3a9527ebea2e95bcbcdf389` (blob `2bbfb07c528b73e128aaf795cebee146075c28ed`, 1537 lines). Latest mobile/reset test commit: `a12b494c2a3b65d454edaf6837cff4fcc06b408f` (blob `c20bf9e555759d5815001b4bef36e9e1583e81f1`, 910 lines). Earlier implementation commits: `02687b13b3aae614acd4125cdb2d0dd2d19b6b5e`, `0d22550fd4518548b5243b565d5a074c566f1cda`, `453beb8e486c63c08502829aa8cc0304968db2f4`, `60b10923fe6196fa26edab18642ea240ee6f167d`, and `81b18268e58f196432ea4c8a7fa47fedeccb2b98`.
- README/design/roadmap/build-status doc commits: `5cfb07bec7396eecc0de548d8fe863b7214ba303`, `522d4b591ec46b6ae7371d060475434b3e2eccf1`, `03e4a4f00d4b2be88c63e7470b50d942fe6bb53f`, and `c3f6a2cb42838b2ad51580b737fad81a80d842d`.
- **Verification note updated on October 27, 2026:** at the time of the original automatic-reset feature note, run 210 was the last known baseline. That statement is now historical and superseded by [Godot CI run 40493513243](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40493513243), which passed the current code/tests on Godot 4.4.0 and 4.7.2. [Android APK run 40493513100](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40493513100) also exported and published the debug APK. Physical-device QA remains outstanding.

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

At that milestone the campaign had twelve rooms, but it was still an early prototype. Triune Relay is logic-tested; its visual readability and actual touch-control difficulty still need manual playtesting.

### All-memory restored-signal reward and dynamic Archive count
**Changed:** `scripts/game.gd`, `tests/game_flow_smoke.gd`, README and design/build/roadmap documentation.

- `scripts/game.gd:L812–L829`: collecting the final uncollected Memory Shard changes the status from the ordinary `MEMORY:` lore message to `SIGNAL RESTORED` plus the final shard's lore. This reward is optional and does not affect gates, room completion or unlocks.
- `scripts/game.gd:L454–L471`: Memory Archive now shows `SIGNAL RESTORED — ALL MEMORIES FOUND` when all room shards are collected; otherwise it shows the live recovered/total count.
- `scripts/game.gd:L313–L372`: the Archive's initial status placeholder uses `LEVELS.size()` instead of a hard-coded six, keeping the UI compatible as the campaign grows.
- `tests/game_flow_smoke.gd:L287–L316`: `_test_all_memories_restore_signal()` simulates collecting the final room's shard through the real pickup path, checks the message/Archive reward, then restores the player's original save values.
- `tests/game_flow_smoke.gd:L319–L347`: Memory Archive UI test covers the normal count or restored-signal state and asserts the displayed denominator matches the live room count.
- The reward source commit is `dd11471aea0f87399f7a816304daaba3ac68df4b`; the dynamic archive placeholder is `f900f967fa83f618e3615f423a9ef613f85bd71a`; the regression coverage is in `04be8ef22ca631b000d14b541bbce2ca0426b5b8` and `7531407e22c8a8068b4d62df90c190272713668d`.
- [Godot CI run 140](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40398632047) passed on both Godot 4.4.0 and 4.7.2, including the full final-shard pickup path and Archive status checks.

This is an optional exploration reward, not a paid gate. At that milestone, all twelve then-existing rooms remained completable without collecting any Memory Shard.

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
| `scripts/game.gd` | Main controller, responsive ECHO logo/menu/theme, gameplay HUD, movement, echo recording/playback, Latch Protocol toggle, ordered-relay feedback, Pulse Lock timer, sentinel, echo-only jammer rejection/visuals, Memory Shard collection/archive, preferences, saves and procedural rendering. **1747 lines in the current source snapshot; refactor incrementally after tests protect behavior.** |
| `scripts/core/echo_track.gd` | Data-only `RefCounted` script loaded through preloaded script resources; avoids global `class_name` lookup; stores points, clamps timestamps to nondecreasing order, copies tracks, returns duration, interpolates route positions, and holds endpoint outside the timestamp range. |
| `scripts/data/level_catalog.gd` | Thirteen room dictionaries, optional shard positions/lore, single/ordered relay requirements, toggle switch, timed-gate and sentinel combinations, plus the echo-only jammer challenge. The defensive-copy accessor and canonical/draft validator cover schema, names, jammer radius/spacing, bounds and hazard/timer tuning. |
| `scripts/data/progress_store.gd` | Version-2 local save boundary (`user://echopost_save.cfg`) using `ConfigFile`; preserves v1 campaign progress and stores normalized Memory Shard room indices. |
| `scripts/data/settings_store.gd` | Separate preference store (`user://echopost_settings.cfg`) for speed and joystick handedness, defaulting safely and normalizing unsupported movement values. |
| `tests/headless_smoke.gd` | Data tests for echo interpolation/copying, 17-room schema including Chapter II's relay/jammer combinations, shard/waypoint/toggle data, Triune Relay, Fracture Clock, Dead Air Protocol and The Last Chorus, malformed jammer/draft validation, v2 shard persistence/sanitization, v1-save compatibility, campaign clamping and isolated control-preference persistence/normalization. |
| `tests/game_flow_smoke.gd` | Main-scene tests for chapter/archive/options UI, supplied logo load/visibility and responsive restoration, Memory Shards, settings, lifecycle pause, recording limits, sentinel/reset, portal completion, Latch Protocol, ordered relays, Fracture Clock, Dead Air Protocol, Null Corridor and timed gates. |
| `RUN_TESTS.bat` | Windows shortcut to run both headless smoke tests if Godot is on PATH. |
| `.github/workflows/godot-checks.yml` | Imports/parses project then runs both tests on a Godot 4.4.0 / 4.7.2 matrix. |
| `assets/echopost_logo.jpg` | Supplied ECHO logo shown in the menu and Android launcher. |
| `assets/echopost_icon.svg` | Matching editable cyan tunnel/orbit identity icon. |
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

This map matches controller blob SHA `f7c75cdd825e4d12335202319fecdb366f0f6423` (1991 lines).

- **L102–L140:** app lifecycle pause, initialization and frame loop setup.
- **L141–L189 — `_process()`:** recording sample/update, echo playback, hazard and puzzle evaluation.
- **L190–L230 — `_input()`; L231–L256:** keyboard/touch input, floating joystick zones, dead zone and analog response.
- **L257–L274:** background stars and interface setup.
- **L275–L312 — `_build_menu()`; L313–L347 — `_build_game_hud()`:** branded menu and round glass gameplay actions.
- **L348–L471:** completion/help/chapter/archive construction.
- **L472–L500 — `_build_options_panel()`:** speed, handedness and Performance Mode controls.
- **L507–L559:** movement presets, handedness, Performance Mode toggling and mobile frame cap.
- **L560–L629:** option labels, archive refresh and failure/reset panel.
- **L630–L872 — `_layout_responsive_ui()`:** responsive menu, circular action placement, left-handed mirror and safe text lanes.
- **L873–L975:** panel, label and common button construction.
- **L976–L1028 — `_style_game_action_button()`:** translucent round in-game action surfaces.
- **L1029–L1063:** press animation and menu/start flow.
- **L1064–L1110 — `_start_level()`:** initialize a chamber and reset controls.
- **L1111–L1157:** Record and Latch actions.
- **L1158–L1219 — `_finish_recording()`:** route endpoint, relay-order and jammer validation.
- **L1220–L1242 — `_add_record_sample()` / `_segment_touches_circle()`:** update cached jammer-overlap status once per new route segment.
- **L1243–L1337:** relay linking/order/progress geometry.
- **L1338–L1362 — `_update_player()`:** keyboard movement and eased touch movement.
- **L1363–L1462:** echo playback, reset, sentinel, shard, timed-gate and puzzle checks.
- **L1463–L1597:** completion, replay/restart, pause, navigation and menu progress.
- **L1598–L1643 — `_update_hud()`:** avoid rewriting identical labels and control states.
- **L1644–L1670:** load/save campaign and settings.
- **L1671–L1725:** draw dispatch and branded menu backdrop.
- **L1726–L1849 — `_draw_room()`:** room grid; optional animated rails/sweep and lower-detail puzzle arcs in Performance Mode.
- **L1850–L1924:** relay, shard, switch, gate and portal drawing.
- **L1925–L1956 — `_draw_robot()`:** low-allocation orb in Performance Mode; full orbit/highlight geometry otherwise.
- **L1957–L1973 — `_draw_joystick()`:** lower arc tessellation in Performance Mode.
- **L1974–L1991 — `_draw_track_path()`:** batched polylines; one route draw in Performance Mode.

## 5. Exact line map — supporting scripts and tests

### `scripts/core/echo_track.gd` (60 lines, blob SHA `9a433129a0cb8b04d9ab55c0964aeb4683ddab3a`)
- **L1–L5:** RefCounted header, class-cache independence note, and timestamp/position sample array.
- **L8–L9:** Clear samples.
- **L12–L16:** Add nonnegative timestamp while guaranteeing timestamps never move backwards.
- **L19–L25:** Copy samples through `get_script().new()`; no global `EchoTrack` lookup, preventing the Godot 4.4 compile error.
- **L28–L31:** Return route duration.
- **L34–L59:** Resolve position before/after route, interpolate between ordered points, and tolerate near-duplicate timestamps.

### `scripts/data/level_catalog.gd` (382 lines, blob SHA `b36787a5440912eafb7b800331e890ab3c51d74e`)
- **L4–L152:** first nine chamber definitions.
- **L153–L169:** Triune Relay's three checkpoints.
- **L170–L187:** Fracture Clock's three relays and 4.5-second timer.
- **L188–L205:** Dead Air Protocol's four relays, sentinel and 1.8-second timer.
- **L206–L224:** Null Corridor jammer, radius and optional lore.
- **L226–L288:** defensive access, required schema, type/name, switch mode and timer validation.
- **L289–L316:** jammer type/radius/pairing, spacing and bounds.
- **L317–L343:** switch/shard/relay spacing validation.
- **L345–L382:** ordered relay arrays, bounds and sentinel patrol checks.

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

### `tests/headless_smoke.gd` (237 lines, current blob SHA `1c3b8ff559adc403d0faee8118ee2be9d52d5e22`)
- **L1–L12:** test runner/preloads and isolated temporary save/settings paths.
- **L15–L25:** run grouped tests and exit nonzero on failed assertions.
- **L28–L47:** timestamp order, interpolation, endpoint hold, script identity and copy independence.
- **L50–L134:** validate thirteen unique rooms, Null Corridor's jammer metadata, all single-/multi-relay data, Triune Relay, Fracture Clock and Dead Air Protocol.
- **L136–L162:** reject malformed drafts, including invalid jammer position/radius, bad route geometry, invalid sentinel/timed-gate parameters and mistyped/out-of-bounds relay points.
- **L164–L169:** validator-message helper.
- **L172–L203:** progress save/load, shard normalization and v1 compatibility.
- **L206–L228:** settings defaults/persistence/normalization.
- **L229–L233:** assertion helper.

### `tests/game_flow_smoke.gd` (1141 lines, blob SHA `cdf19da99cca0d296e0facaf2a239c9060f1bb59`)
- **L1–L12:** test harness and preloads.
- **L13–L92:** orchestration and lifecycle/UI/campaign/recording setup.
- **L93–L241:** lifecycle pause, recording cap/short stop, sentinel reset, restart cleanup and portal completion.
- **L243–L399 — `_test_options_panel()`:** Options speed/handedness settings plus Performance Mode toggle and restoration.
- **L401–L690:** latch, Relay Beacon, ordered relay and Fracture Clock tests.
- **L691–L780:** Dead Air Protocol.
- **L781–L826 — `_test_echo_jammer_route()`:** Null Corridor reject/reset and safe curved bypass.
- **L827–L906:** timed-gate crossing and failure-reset behavior.
- **L907–L959 — `_test_touch_joystick_comfort()`:** floating-thumb zones, dead-zone, easing, diagonal normalization and segment-to-jammer geometry.
- **L960–L1136 — `_test_premium_mobile_ui()`:** round glass controls, handedness mirror, status clearance, logo and compact viewport bounds.
- **L1137–L1141 — `_check()`:** report test failures.

### `tests/headless_smoke.gd` (236 lines, blob SHA `df2d8fa7b4604ba224b9078f3b4ad307bd61daa7`)
- **L206–L229 — `_test_settings_store()`:** Performance Mode defaults ON, persists OFF, and safely defaults ON if the key is missing.

### `scripts/data/settings_store.gd` (43 lines, blob SHA `ae2c241920849d9db196a8462d1caadc5f820048`)
- **L9–L21:** load speed, handedness and the graphics Performance Mode flag, with ON as the fallback.
- **L24–L29:** save settings schema v2 independently from campaign progress.

### `project.godot` (44 lines, blob SHA `aaf2ca779d5ca128ec5d41b25f33102d883e045c`)
- **L1–L10:** Project metadata, app icon, main scene and feature declarations.
- **L12–L18:** 1280×720 viewport/window settings, canvas stretch and landscape orientation.
- **L20–L25:** Compatibility renderer and ETC2/ASTC texture-import support required by Android export.
- **L27–L44:** WASD/arrow input map.

### `export_presets.cfg` (67 lines, blob SHA `a0ba9ce2ea2711d37ebcd025df7897435cbbdc01`)
- **L1–L18:** Android preset declaration and APK output path `build/ECHOPOST-android.apk`.
- **L20–L39:** Android export options, arm64-v8a architecture, version `0.1.0`, package ID `com.ninugaming.echopost` and app name.
- **L40–L67:** Launcher icon fields and Android export option defaults.

### `.github/workflows/android-apk.yml` (148 lines, blob SHA `2f741311fe04afafc3ea7259f18ab4913a39104d`)
- **L1–L25:** Triggers for main pushes, version tags and manual runs; release write permission; concurrency group.
- **L27–L58:** Checkout, Java 17, Android SDK packages and Godot 4.7.2 with export templates.
- **L60–L92:** Headless import, debug signing configuration and Godot Android SDK/JDK editor settings.
- **L94–L111:** Export debug APK, require a nonempty file, validate archive structure, upload a 30-day workflow artifact.
- **L113–L148:** Publish/refresh the `nightly` GitHub prerelease from main and publish an attached APK for `v*` tags. Signing is for testing, not production.

### `scenes/main.tscn` (13 lines)
- **L1–L3:** Scene resource/script declaration.
- **L5–L13:** Full-rect Control root bound to `scripts/game.gd`.

### `.github/workflows/godot-checks.yml` (38 lines)
- **L1–L19:** Push/PR/manual triggers, permissions, runner and Godot 4.4.0/4.7.2 matrix.
- **L21–L29:** Checkout and Godot installation.
- **L30–L38:** Import/parse project and run both smoke-test scripts.

### `RUN_TESTS.bat` (25 lines)
- **L1–L10:** Detect Godot on PATH or print invocation help.
- **L12–L20:** Run data and gameplay tests and return success.
- **L21–L25:** Report failure and return a nonzero exit code.

## 6. Current verification status — be precise

- **Latest completed Godot CI:** [run 41091283098](https://github.com/NinuGaming999/ECHOPOST/actions/runs/41091283098) passed on Godot 4.4.0 and 4.7.2 at commit `36622a5488f3cb4073b8692ae85a768b62710d43`. Both versions passed import/parse, data smoke and gameplay-flow tests, including Performance Mode persistence/toggling, route-segment collision math and mobile UI regressions.
- **Latest Android APK export:** [run 41091282986](https://github.com/NinuGaming999/ECHOPOST/actions/runs/41091282986) succeeded for the same tested revision. Export, ZIP integrity, artifact upload and nightly publication passed. [Direct APK](https://github.com/NinuGaming999/ECHOPOST/releases/download/nightly/ECHOPOST-android.apk).
- **Current code/test hashes:** `scripts/game.gd` = `2f6c7a04ef45606315033b1ef7f52e5a42eb86e5` (2039 lines); `scripts/data/level_catalog.gd` = `416bc2d88c1e3ac9b024a5915d89edfe919a62b0` (463 lines); `scripts/data/settings_store.gd` = `ae2c241920849d9db196a8462d1caadc5f820048` (43 lines); `tests/game_flow_smoke.gd` = `d77eef16b1f5e086b5a625960871f2fa7cd9ff50` (1186 lines); `tests/headless_smoke.gd` = `1c3b8ff559adc403d0faee8118ee2be9d52d5e22` (237 lines).
- **Performance measurement boundary:** no physical low-end handset or GPU profiler was available. The code-level workload is reduced and CI is green, but actual FPS, battery and thermals still need measurement on hardware.
- **Device QA:** touch reach, safe areas/cutouts, save persistence after relaunch, and background/foreground behavior still need physical-device testing.
- **Release boundary:** nightly APK is debug-signed for direct testing, not a production signing key or Google Play-ready release.

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
3. **Small content set:** twenty-one room dictionaries and twenty-one optional Memory Shards now exist, but the core two-switch pattern is still the foundation and there is no full campaign or final narrative ending.
4. **Procedural placeholder visuals:** no authored robot animations, environmental tilesets, VFX or transition animations.
5. **No sound:** recording, rejected route, sentinel hits, gate opening and portal have text/visual feedback only. No SFX, music, mixer, or audio options exist.
6. **Pause behavior needs real device QA:** lifecycle logic and timer freeze are headlessly tested, but actual Android app-switch lifecycle/focus behavior are unverified. The player must tap RESUME after returning.
7. **Mechanic coverage:** one recording slot and the two-switch gate remain core; Dead Air Protocol requires four ordered relays while a sentinel can interrupt recording and a short gate timer pressures the exit run; Null Corridor adds an echo-only jammer and a safe curved bypass. Moving platforms, multi-echo puzzles and deeper combinations remain future work.
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
- [x] Verify current main game code after the compact-menu/joystick regression fix: [Godot CI run 40493513243](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40493513243) passed Godot 4.4.0 and 4.7.2 import/parse, data smoke tests and game-flow tests.
- [x] Fix the 800×360 menu overlap caused by theme-enforced Button minimum heights; [Godot CI run 40546560749](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40546560749) passed both Godot versions at commit `662d1ce3736513d2afc11ffad49e390694d53ef5`.
- [x] Extend compact-menu coverage to five viewports and prevent the 640-wide gameplay HUD row from overlapping; [Godot run 40548485659](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40548485659) passed on Godot 4.4.0/4.7.2, and [APK run 40548485495](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40548485495) exported the source/test commit.
- [x] Add Null Corridor, validate jammer metadata and route rejection, and test an accepted curved bypass; [Godot run 40550158187](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40550158187) and [APK run 40550158280](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40550158280) both passed for the feature commit.
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
- [ ] Continue from thirteen layouts toward 20 authored chambers; add fresh mechanics beyond route geometry, patrol timing, relay order, timed gates and the echo-only jammer.
- [ ] Add checkpoint/lore fragments and a cohesive Act I ending.
- [ ] Replace procedural placeholder art with original coherent art/audio, while keeping clarity and low-cost rendering on mobile.

### P4 — Export and release preparation
- [x] Configure Android package ID `com.ninugaming.echopost`, app version `0.1.0`, app icon, tracked Android export preset and arm64-v8a target.
- [x] Automate debug APK export, ZIP integrity checking, workflow artifact upload and nightly GitHub Release publication. [Android APK run 40493513100](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40493513100) succeeded.
- [x] Confirm the latest mobile-layout-fix APK exported and refreshed the nightly release from commit `662d1ce3736513d2afc11ffad49e390694d53ef5`: [Android APK run 40546560892](https://github.com/NinuGaming999/ECHOPOST/actions/runs/40546560892).
- [ ] Configure protected production signing and complete privacy/storefront disclosures before any public store release.
- [ ] Install the debug APK on a real Android device and verify lifecycle, controls, saves and all twenty-one rooms.
- [ ] Run release QA and a closed beta before public distribution.
- [ ] Only later design online sharing with route bounds validation, upload limits, moderation/reporting, privacy and backend cost controls.

## 9. Rules for the next development session

1. Start by reading this file, `README.md`, `docs/ROADMAP.md`, `docs/BUILD_STATUS.md`, and the most relevant source/tests. Inspect the current GitHub `main` tip; do not blindly assume this documented snapshot is still newest.
2. Check the most recent CI run before modifying code. A workflow run for a commit older than the code currently on `main` does not verify the current code.
3. Choose **one focused improvement** at a time. Make changes in `main` only as permitted by the user/project workflow, and don't claim the project is finished.
4. Test changes with Godot CI or available local Godot. Distinguish passed tests, tests not run, and manual device checks.
5. Refresh every affected line number after changes. Section 4 is keyed to `scripts/game.gd` blob SHA `e207974c69a601907bf1a4793f46ed103d849b7f`; section 5 records the current catalog, test, Android export and workflow blobs. The current gameplay-test blob is `8dfaff640af027beba07ea700be5b2971e0e3afa`. If any of those hashes differ after edits, regenerate the corresponding section.
6. Update `PROJECT_PROGRESS.md` in the same development pass as source changes. Record the new commit(s), source hashes/line references, CI URL/result and what the next session should do.
7. Keep this game offline-capable and dependency-light. Never add network accounts, telemetry, uploads, payment or ads as an incidental code change.
8. Claim APK export only when CI confirms the export and archive-integrity check; claim installation/device verification only after the APK has actually been installed and tested on hardware.

---

*Handoff note: this file is written to make future work resumable from concrete repository state, not to declare completion. The next session's first action should be checking the newest CI run and then installing the current nightly APK on an actual Android device for controls, save persistence and lifecycle testing before further feature work.*
