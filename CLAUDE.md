# Claude Working Rules — Converse-3D

## Workflow rules
1. **One task at a time.** Complete one task fully before moving on. Update the todo list after each completion before starting the next.
2. **≤150 lines per write.** Never emit a single file longer than ~150 lines in one tool call. Build larger files across multiple Edit/Write passes.
3. **Fresh session at 20+ tool calls.** When the conversation grows past ~20 tool calls, ask the user to start a fresh session and hand off via the plan file or a brief status note.

## Project layout
- `Models/` — data types (TrackLayout, GameState, RaceState, CarConfig, TreadConfig, AppScreen)
- `Game/` — SceneKit logic (GameWorld, GameSceneView, BotCar, F1CarBuilder)
- `HUD/` — overlay components (badges, indicators, ControlButton)
- `Screens/` — full-screen SwiftUI views (Splash → CarSelect → TreadSelect → TrackSelect → Ready → Gameplay → Finish)
- `Helpers/` — shared utilities (Formatting)
- `ContentView.swift` — slim root navigator
- `MyApp.swift` — app entry, do not modify

## Conventions
- Pure SwiftUI + SceneKit. No external 3D assets. All geometry built from SCN primitives.
- One top-level type per file. Tightly-coupled helpers (e.g. `CarCard` with `CarSelectScreen`) may co-locate.
- F1-style physics: high topSpeed (55–80), high acceleration (30–45), downforce-modulated grip.
- Bots are non-interactive AI peers that follow track waypoints and respect simple collision pushback.
