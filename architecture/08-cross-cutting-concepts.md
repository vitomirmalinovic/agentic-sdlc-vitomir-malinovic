# 08 — Cross-Cutting Concepts

This chapter collects the concepts and conventions that apply across all building blocks, not
to a single one. They are the rules a maintainer (or a downstream agent) must follow anywhere in
the codebase.

## 8.1 Domain Modeling

| Concept | Rule | Where it applies |
|---------|------|------------------|
| **Pure core** | Domain modules (`board/`, `game/`) perform no I/O and hold no hidden state. | Board, Game contexts |
| **Immutability** | `Grid`, `GameState`, and actions are immutable value objects; transitions return a new value, never mutate in place. | Whole core |
| **Stateless transitions** | `GameEngine.apply(state, action) → state` is a pure function of its arguments. | Game context |
| **Injected randomness** | All randomness comes from an injected `random.Random`; no module-level `random.*` in the core (T6). | Board generation |
| **Value objects at seams** | Contexts exchange small immutable data (`Grid`, `GameState`, action records), never shared mutable objects. | Across contexts |
| **Dependency direction** | Adapters depend on the core; the core depends on nothing outward (C7). | Whole system |

## 8.2 Error Handling

Errors are handled close to where they occur, and the game never crashes on bad input.

| Layer | Error class | Handling |
|-------|-------------|----------|
| Presentation — parse | Malformed command, unknown verb, bad coordinate syntax | `CommandParser` rejects it; `GameLoop` prints a short "invalid command" message and re-prompts. The domain is never called. |
| Presentation — file I/O | Missing, unreadable, or malformed score file | `ScoreAdapter` catches it and degrades to "no records" / no-persistence (I3). Not propagated. |
| Domain — invariant | A coordinate out of board bounds reaches the core (defense in depth) | The core raises a domain exception; `GameLoop` catches it and shows a message. The state is unchanged. |
| Domain — idempotent action | Reveal an already-revealed cell; flag an already-flagged cell | No-op: the engine returns an equivalent state (possibly unchanged). No exception. |
| Process — fatal | Any unexpected exception not caught above | The process exits non-zero (E6). Acceptable for a casual game; no save/resume is in scope (§3.4). |

Design rule: **the CLI translates domain exceptions into user messages; the domain never catches
its own exceptions for control flow.** This keeps domain logic clear and the side effects where
they belong — the Presentation adapter.

## 8.3 Input Validation

The only interactive input boundary is `stdin` (interface I1); the score file is a second input
boundary (I3). Validation is applied at the boundary, not deep inside the core.

- **Command syntax** — `CommandParser` validates the verb and the argument shape (e.g.
  `r <row> <col>`, `f <row> <col>`, `restart`, `quit`) before constructing an action.
- **Coordinate range** — the parser checks `row`/`col` against the current board dimensions and
  rejects out-of-range values with a message; no out-of-bounds action is passed on.
- **Numeric parsing** — non-integer or negative values are rejected at parse time.
- **Score file** — `ScoreAdapter` validates that the JSON decodes to the expected record
  shape; anything else is treated as "no records" (I3), not an error.
- **Defense in depth** — the core still guards its own invariants (bounds, mine count ≤ cells),
  so a future caller or a test cannot create an impossible state. These guards raise, they do
  not silently fix input.

## 8.4 Logging and Diagnostics

- **Two output streams, by purpose:** the game grid and prompts go to `stdout`; diagnostics go to
  `stderr`. This keeps logs from corrupting the rendered board (T7 governs the *game* output on
  stdout).
- **Mechanism:** the standard library `logging` module, configured with a named logger
  (e.g. `minesweeper`). Default level `WARNING`; level overridable via the `LOGLEVEL` environment
  variable for debugging. No third-party logging library (T2).
- **What is logged:** unexpected caught exceptions, score-file degradation events, and (at
  `DEBUG`) the seed and dimensions at game start — enough to reproduce a run.
- **What is not logged:** routine player commands or the board contents on every turn (noise).
- The domain does not log. If a domain invariant is violated, it raises; the CLI may log the
  caught exception. Logging stays an adapter concern.

## 8.5 Testing Strategy

Testing is the top-priority quality goal (Chapter 1), so the strategy is a first-class concept.

### Test pyramid

| Level | Scope | Count | I/O? |
|-------|-------|-------|------|
| Unit | Pure domain: `Grid`, `BoardGenerator`, `HintComputer`, `GameState`, `GameEngine` | The large majority | None |
| Integration | Adapters in isolation: `CommandParser`, `Renderer`, `ScoreAdapter` (with temp files / captured streams) | Fewer | Stubbed/fake |
| End-to-end | `GameLoop` driving the real adapters over captured `stdin`/`stdout` | A small handful | Captured |

### Principles

- **Determinism is mandatory.** Tests inject a fixed `random.Random` seed and never read the
  wall clock for assertions. The win-timer uses the real clock only in the Presentation adapter;
  domain tests never depend on it (T6, NF1).
- **No I/O in domain tests.** Board and Game tests import only from `board`/`game` and assert on
  returned values. They never touch `stdin`, `stdout`, or the file system.
- **BDD-ready shape.** Because `GameEngine.apply(state, action) → state` is pure, every scenario
  maps to a Given/When/Then: *Given* an initial `GameState`, *When* an action is applied, *Then*
  the resulting state matches expectations. This is the seam later BDD modules will use.
- **Test layout mirrors source** (C6): `board/grid.py` → `tests/board/test_grid.py`, etc.
- **Tooling:** `pytest` only (T3), quarantined to tests; no runtime import of `pytest` anywhere in
  the game.
- **Adapter tests use fakes:** a fake `ScoreStore` (in-memory) and captured `stdin`/`stdout`,
  keeping them fast and deterministic.

## 8.6 Configuration and Conventions

- **No magic constants in the core.** Board limits, difficulty presets, and the score-file path
  are defined once and passed in, not hardcoded inside domain functions.
- **Difficulty presets** (rows × cols, mines) are a Presentation concern — the player picks a
  difficulty, which maps to parameters; the domain only knows numbers, not named difficulties.
- **Exit codes** (E6): `0` on normal quit or win, non-zero only on unexpected fatal errors.
- **Coding conventions** are fixed in [Chapter 2, §2.3](02-constraints.md) (PEP 8, type hints,
  naming, docstrings, import rules) and are not repeated here.

## 8.7 Ubiquitous Language

Identifiers, docstrings, messages, and this document share one vocabulary (constraint C4). The
authoritative definitions live in [Chapter 12 — Glossary](12-glossary.md): field, hint, reveal,
flag, flood-fill, difficulty, mine, cell, status. When a term is ambiguous, the glossary wins.
