# Contributing to ECHOPOST

Thank you for helping build ECHOPOST. The central mechanic is the player-created echo; changes should strengthen clarity, fairness, accessibility, and puzzle depth.

## Development setup

- Use Godot 4.3 or newer.
- Import `project.godot` into Godot and run the main project.
- Keep the game runnable without required third-party plugins.

## Code guidelines

- Prefer small functions with one responsibility.
- Keep gameplay data separate from rendering as level content grows.
- Treat recorded routes as plain data; never execute player-supplied code.
- Avoid per-frame allocations where a reusable value is enough.
- Keep mobile performance and touch usability in mind.
- Document non-obvious puzzle rules and save-format changes.

## Before opening a pull request

1. Run the main scene in Godot.
2. Complete all available rooms using keyboard controls.
3. Test recording while standing still, moving, ending on Switch A, resetting, and pausing.
4. Test touch joystick and the on-screen buttons in a mobile-sized viewport.
5. Confirm progress still loads after restarting the game.
6. Update the README or roadmap if the supported behavior changes.

Please do not commit API tokens, signing keys, personal credentials, or generated Android keystores.
