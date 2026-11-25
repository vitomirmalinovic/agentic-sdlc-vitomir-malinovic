# User Stories — Minesweeper

Derived from `architecture/` (chapters 01–12) using Domain-Driven Design and Pareto prioritization. Stories are generated one at a time; this file is updated as each bundle is written and approved.

## Domains

| Domain | Bounded context (Ch. 05) | Components | F-goals |
|---|---|---|---|
| BOARD | Board (§5.3) | Grid, BoardGenerator, HintComputer | F1, F2 |
| GAME | Game (§5.3) | GameState, GameEngine | F3, F4, F5, F6, F7 |
| CLI | Presentation (§5.4), minus storage adapter | CommandParser, Renderer, GameLoop | F1–F7 (terminal surface) |
| SCORE | Storage adapter (§5.4, ADR-006) — adapter, not a context | ScoreAdapter | F8 |

## Pareto progress

CORE: 3/3 approved (100% — complete) · SUPPORTING: 0/10 not started · Overall: 3/13 approved

> CORE generation is complete. No further stories are generated in this pass; the ten SUPPORTING stories (CLI-001..004, GAME-002/003/004/005, SCORE-001/002) remain ⬜ not started.

## Prioritized story list

| # | Story ID | Title | Domain | Score | Priority | Status |
|---|----------|-------|--------|-------|----------|--------|
| 1 | BOARD-STORY-001 | Generate a deterministic board from an injected seed | BOARD | 11 | CORE | ✅ approved |
| 2 | BOARD-STORY-002 | Compute the hint field with 8-neighbour counts | BOARD | 11 | CORE | ✅ approved |
| 3 | GAME-STORY-001 | Reveal a safe cell to show its hint | GAME | 11 | CORE | ✅ approved |
| 4 | CLI-STORY-001 | Start a new game with chosen size, mines, and seed | CLI | 11 | SUPPORTING | ⬜ not started |
| 5 | CLI-STORY-004 | Run the interactive game loop with restart and quit | CLI | 11 | SUPPORTING | ⬜ not started |
| 6 | GAME-STORY-002 | Flood-fill cascade when revealing a zero | GAME | 10 | SUPPORTING | ⬜ not started |
| 7 | GAME-STORY-004 | Detect win when all safe cells are revealed | GAME | 9 | SUPPORTING | ⬜ not started |
| 8 | GAME-STORY-005 | Detect loss when a mine is revealed | GAME | 9 | SUPPORTING | ⬜ not started |
| 9 | CLI-STORY-002 | Render the game state to the terminal | CLI | 8 | SUPPORTING | ⬜ not started |
| 10 | CLI-STORY-003 | Parse player commands into game actions | CLI | 8 | SUPPORTING | ⬜ not started |
| 11 | GAME-STORY-003 | Flag and unflag suspected mines | GAME | 7 | SUPPORTING | ⬜ not started |
| 12 | SCORE-STORY-002 | Degrade gracefully on a missing or malformed score file | SCORE | 6 | SUPPORTING | ⬜ not started |
| 13 | SCORE-STORY-001 | Persist best clear times per difficulty to local JSON | SCORE | 5 | SUPPORTING | ⬜ not started |

Status: ⬜ not started · 🟡 drafted · ✅ approved

Generation order: BOARD-001 → BOARD-002 → GAME-001 → GAME-002 → GAME-004 → GAME-005 → CLI-003 → CLI-002 → CLI-001 → CLI-004 → GAME-003 → SCORE-002 → SCORE-001

## Traceability

| Story ID | F-goals | Components | Chapters |
|---|---|---|---|
| BOARD-STORY-001 | F2 | Grid, BoardGenerator | 01, 02, 05, 06, 09, 10, 12 |
| BOARD-STORY-002 | F1 | Grid, HintComputer | 01, 05, 06, 09, 10, 12 |
| GAME-STORY-001 | F3 | GameState, GameEngine | 01, 05, 06, 09, 10 |
| GAME-STORY-002 | F4 | GameState, GameEngine | 01, 05, 06, 10 |
| GAME-STORY-003 | F5 | GameState, GameEngine | 01, 05, 08 |
| GAME-STORY-004 | F6 | GameState, GameEngine | 01, 05, 06, 10 |
| GAME-STORY-005 | F7 | GameState, GameEngine | 01, 05, 06, 10 |
| CLI-STORY-001 | F2 | GameLoop, CommandParser, BoardGenerator, HintComputer, GameState | 01, 05, 06, 07 |
| CLI-STORY-002 | F1–F7 | Renderer, GameState | 05, 06, 07, 09 |
| CLI-STORY-003 | F3, F5 | CommandParser | 05, 06, 08 |
| CLI-STORY-004 | F1–F7 | GameLoop, GameEngine, Renderer, CommandParser | 05, 06, 07, 08 |
| SCORE-STORY-001 | F8 | ScoreAdapter | 01, 03, 05, 07, 09 |
| SCORE-STORY-002 | F8 | ScoreAdapter | 03, 05, 07, 08, 09, 10, 11 |

## DDD Analysis

The system is partitioned into the three bounded contexts from [§5.3–§5.4](../../architecture/05-building-block-view.md) and [§4.3](../../architecture/04-solution-strategy.md#43-bounded-contexts): **Board**, **Game**, and **Presentation** ([ADR-003](../../architecture/09-architecture-decisions.md#adr-003-bounded-contexts-board-game-presentation)). Score storage is a storage *adapter*, not a bounded context ([ADR-006](../../architecture/09-architecture-decisions.md#adr-006-optional-local-json-score-persistence-with-graceful-degradation); [§12.3](../../architecture/12-glossary.md#123-architecture-terms)).

Subdomain classification (Domain-Driven Design):

| Story domain | DDD classification | Bounded context (Ch. 05) | Components | Rationale |
|---|---|---|---|---|
| BOARD | Core | Board | Grid, BoardGenerator, HintComputer | The base kata (hint computation) and deterministic board generation — the correctness and testability anchor (F1, F2; Q1, Q2). |
| GAME | Core | Game | GameState, GameEngine | The game rules — reveal, flag, flood-fill, win/lose — the differentiating heart of the product (F3–F7). |
| CLI | Supporting | Presentation | CommandParser, Renderer, GameLoop | Delivers the core to the player; holds no game logic of its own; a substitutable I/O adapter. |
| SCORE | Generic | — (storage adapter) | ScoreAdapter | Optional persistence (F8); a plain local JSON store that is removable, replaceable, and not differentiating. |

**Core domain (named):** the **Domain Core** — the Board and Game bounded contexts together ([§12.3](../../architecture/12-glossary.md#123-architecture-terms)), the pure logic with no I/O and no hidden randomness. This is where the top-priority quality goals — Testability/Determinism and Correctness ([§1.3](../../architecture/01-introduction-and-goals.md#13-quality-goals-top-priorities)) — live, and where the three CORE Pareto stories (BOARD-STORY-001, BOARD-STORY-002, GAME-STORY-001) sit.

**Dependency direction** ([§8.1](../../architecture/08-cross-cutting-concepts.md#81-domain-modeling), constraint C7): the adapters (CLI, SCORE) depend on the core; the core depends on nothing outward. This one-way rule is what keeps the core unit-testable in isolation and is the single organizing principle of the codebase.

## Ubiquitous Language

Per [§8.7](../../architecture/08-cross-cutting-concepts.md#87-ubiquitous-language), identifiers, docstrings, messages, and these stories share one vocabulary; the authoritative definitions live in [Chapter 12 — Glossary](../../architecture/12-glossary.md). When a term is ambiguous, the glossary wins.

| Term | Meaning | Used in stories |
|---|---|---|
| Field | The N×M rectangular grid; each cell is a mine (`*`) or safe (`.`). Also called the mine layout. | BOARD-001, BOARD-002 |
| Mine | A cell containing an explosive, represented as `*`; revealing it loses the game. | BOARD-001, BOARD-002, GAME-001, GAME-005 |
| Safe cell | A cell that is not a mine; revealing it shows a hint count. | BOARD-002, GAME-001, GAME-004 |
| Hint | The number of mines in a cell's eight neighbours. | BOARD-002, GAME-001, GAME-002 |
| Hint field | A grid the same size as the field; every safe cell shows its hint and every mine stays `*`. | BOARD-002 |
| Cell | A single position in a grid, identified by `(row, col)`. | BOARD-001, BOARD-002, GAME-001 |
| Neighbour | One of the up to eight cells adjacent to a cell (horizontal, vertical, diagonal). | BOARD-002, GAME-002 |
| Reveal | The action of uncovering a hidden cell; a safe cell shows its hint, a mine ends the game in a loss. | GAME-001, GAME-002, GAME-005 |
| Flag | A marker on a hidden cell for a suspected mine; flags do not reveal, can be toggled off, and do not count toward a win. | GAME-003 |
| Flood-fill | The automatic cascade when a cell with hint 0 is revealed: its neighbours are revealed too, repeating until non-zero hints; never reveals a mine. | GAME-002 |
| Frontier | The set of cells where flood-fill stops — non-zero hint cells bordering the connected zero region. | GAME-002 |
| Status | The game phase: `playing`, `won`, or `lost`. | GAME-001, GAME-004, GAME-005 |
| Win | The status reached when every safe cell is revealed, regardless of flags. | GAME-004 |
| Lose | The status reached when any mine is revealed. | GAME-005 |
| Difficulty | A named preset mapping to `(rows, cols, mines)`; a Presentation concept — the domain knows only the numbers. | CLI-001, SCORE-001, SCORE-002 |
| Seed | The value used to initialize the RNG; the same seed yields the same board, making a game reproducible. | BOARD-001, CLI-001 |
| Best time | The fastest recorded clear time for a difficulty, optionally persisted; a casual, optional metric. | SCORE-001, SCORE-002 |
| Grid | The immutable 2D value object with dimensions; used for both the mine layout and the hint field; shared across Board and Game. | BOARD-001, BOARD-002, GAME-001 |
| GameState | The immutable value object holding the board (Grid), the hints (Grid), each cell's visibility, and the status. | GAME-001, GAME-002, GAME-003, GAME-004, GAME-005 |
| Action | An immutable record describing a move — `Reveal(row, col)` or `Flag(row, col)` — passed to the engine. | GAME-001, GAME-003 |
| Visibility | The per-cell state in `GameState`: `hidden`, `revealed`, or `flagged`. | GAME-001 |
| BoardGenerator | The component that builds a mine-layout Grid from `(rows, cols, mines)` and an injected seeded RNG. | BOARD-001 |
| HintComputer | The component that computes the hint field from a mine layout — the base kata, pure and stateless. | BOARD-002 |
| GameEngine | The component that applies an Action to a GameState and returns the next GameState, including flood-fill and win/lose; a pure `(state, action) → state` function. | GAME-001, GAME-002, GAME-003, GAME-004, GAME-005 |
| GameLoop | The Presentation component that orchestrates the session: render → read command → parse → apply action → repeat. | CLI-004 |
| CommandParser | The Presentation component that turns a line of stdin into an Action (or rejects it). | CLI-003 |
| Renderer | The Presentation component that turns a GameState into a text grid for stdout. | CLI-002 |
| ScoreAdapter | The adapter implementing the storage port: reads/writes best-time records to a local JSON file. | SCORE-001, SCORE-002 |
