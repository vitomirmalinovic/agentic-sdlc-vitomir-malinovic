# 12 — Glossary

This glossary is the authoritative source for the ubiquitous language (constraint C4). Identifiers
in code, docstrings, user messages, and the architecture documents use these terms with these
meanings. When a term is ambiguous, this file wins (see [§8.7](08-cross-cutting-concepts.md)).

## 12.1 Domain Terms (the game)

| Term | Definition |
|------|-----------|
| **Field** | The N×M rectangular grid that is the input to the base kata: each cell is either a mine (`*`) or safe (`.`). Also called the *mine field* or *mine layout*. |
| **Mine** | A cell containing an explosive, represented as `*` in the field. Revealing a mine loses the game. |
| **Safe cell** | A cell that is not a mine. Revealing it shows a hint count. |
| **Hint** | The number of mines in a cell's eight neighbours. The base kata replaces each safe cell with its hint; mines stay `*`. |
| **Hint field** | The output of the kata: a grid the same size as the field, where every safe cell shows its hint and every mine stays `*`. |
| **Cell** | A single position in a field/grid, identified by `(row, col)`. |
| **Neighbour** | One of the up to eight cells adjacent to a cell (horizontal, vertical, diagonal). "8-neighbour" and "adjacent" mean the same thing. |
| **Reveal** | The action of uncovering a hidden cell. Revealing a safe cell shows its hint; revealing a mine ends the game in a loss. |
| **Flag** | A marker a player places on a hidden cell to signal a suspected mine. Flags do not reveal; flags can be toggled off (*unflag*). Flags on safe cells do not count toward a win. |
| **Flood-fill** | The automatic cascade that occurs when a cell with hint 0 is revealed: its neighbours are revealed too, and the cascade repeats until it reaches cells with a non-zero hint. Flood-fill never reveals a mine. |
| **Frontier** | The set of cells where flood-fill stops — cells with a non-zero hint that border the connected zero region. |
| **Status** | The game state's phase: `playing`, `won`, or `lost`. |
| **Win** | The status reached when every safe cell is revealed (regardless of flags). |
| **Lose** | The status reached when any mine is revealed. |
| **Difficulty** | A named preset mapping to `(rows, cols, mines)`, e.g. Beginner. Difficulty is a Presentation concept; the domain knows only the numbers. |
| **Seed** | The value used to initialize the random number generator. The same seed yields the same board, making a game reproducible. |
| **Best time** | The fastest recorded clear time for a difficulty, optionally persisted. A casual, optional metric. |

## 12.2 Code/Model Terms

| Term | Definition |
|------|-----------|
| **Grid** | The immutable value object modeling a 2D array of cells with dimensions. Used for both the mine layout and the hint field. Shared across the Board and Game contexts. |
| **GameState** | The immutable value object holding the full game state: the board (Grid), the hints (Grid), each cell's visibility (hidden/revealed/flagged), and the status. |
| **Action** | An immutable record describing a player's move — a `Reveal(row, col)` or `Flag(row, col)` — passed to the engine. |
| **Visibility** | The per-cell state in `GameState`: `hidden`, `revealed`, or `flagged`. Distinct from the field's mine/safe distinction. |
| **BoardGenerator** | The component that builds a mine-layout Grid from `(rows, cols, mines)` and an injected seeded RNG. |
| **HintComputer** | The component that computes the hint field from a mine layout — the base kata, pure and stateless. |
| **GameEngine** | The component that applies an Action to a GameState and returns the next GameState, including flood-fill and win/lose detection. A pure `(state, action) → state` function. |
| **GameLoop** | The Presentation component that orchestrates the session: render → read command → parse → apply action → repeat. |
| **CommandParser** | The Presentation component that turns a line of stdin into an Action (or rejects it). |
| **Renderer** | The Presentation component that turns a GameState into a text grid for stdout. |
| **ScoreAdapter** | The adapter implementing the storage port: reads/writes best-time records to a local JSON file. |

## 12.3 Architecture Terms

| Term | Definition |
|------|-----------|
| **Bounded context** | A coherent area of the model with its own responsibility and language. This system has three: Board, Game, Presentation. |
| **Board (context)** | The context owning field and hint data: generation and hint computation. Pure and stateless. |
| **Game (context)** | The context owning game state and rules: reveal/flag, flood-fill, win/lose. Pure transitions. |
| **Presentation (context)** | The context owning the terminal experience: rendering, parsing, the loop, and the storage adapter. The only context that does I/O. |
| **Domain core** | The Board and Game contexts together; the pure logic with no I/O and no hidden randomness. |
| **Hexagonal architecture** | The organizing structure: a pure core with ports, surrounded by I/O adapters. Adapters depend on the core; the core depends on nothing outward. |
| **Port** | An interface the core exposes that an adapter implements. Here ports are used for testability and clarity, not runtime pluggability. |
| **Adapter** | An implementation of a port that performs I/O — the CLI and the score storage. |
| **Value object** | An immutable data structure identified by its contents, not by identity. `Grid`, `GameState`, and actions are value objects. |
| **Pure function** | A function whose output depends only on its inputs and that has no side effects. `HintComputer` and `GameEngine.apply` are pure. |
| **Determinism** | The property that the same inputs always produce the same output. Achieved here by injecting the RNG seed and keeping the core pure. |
| **Dependency rule** | The one-way rule that adapters depend on the core, never the reverse (C7). |
| **Ubiquitous language** | The shared vocabulary above, used consistently across code and documents. |

## 12.4 Out-of-Scope Terms (to avoid)

These are deliberately *not* part of the system and should not appear in code or docs:

| Term | Why excluded |
|------|--------------|
| Server / service / API | No network, single-process (ADR-005, T4). |
| Database | No DB; only an optional JSON file (ADR-006, T4). |
| Multiplayer / online leaderboard | Single-user, offline (§3.4). |
| Save / resume | No persisted game state (§3.4, D6). |
| Solver / auto-play / AI | Not part of the kata (§3.4). |
| GUI / curses / color | Terminal plain text only (ADR-007, T7). |

---

With Chapter 12, the arc42 documentation set (Chapters 1–12) and all diagrams are complete.
