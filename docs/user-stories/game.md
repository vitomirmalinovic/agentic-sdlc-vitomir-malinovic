# GAME-STORY-001: Reveal a safe cell to show its hint

**Priority**: CORE (Pareto 20%)
**Architecture References**:
- [01 §1.2 Requirements Overview — F3](../../architecture/01-introduction-and-goals.md#12-requirements-overview)
- [01 §1.3 Quality Goals — Testability/Determinism, Correctness](../../architecture/01-introduction-and-goals.md#13-quality-goals-top-priorities)
- [05 §5.3 Game context](../../architecture/05-building-block-view.md#game-context)
- [06 §6.3 Scenario 2 — Reveal a Safe Cell with Flood-Fill](../../architecture/06-runtime-view.md#63-scenario-2--reveal-a-safe-cell-with-flood-fill)
- [08 §8.1 Domain Modeling — Stateless transitions, value objects at seams](../../architecture/08-cross-cutting-concepts.md#81-domain-modeling)
- [08 §8.2 Error Handling — idempotent action, domain invariant raises](../../architecture/08-cross-cutting-concepts.md#82-error-handling)
- [08 §8.3 Input Validation — defense in depth (bounds)](../../architecture/08-cross-cutting-concepts.md#83-input-validation)
- [09 ADR-002 Hexagonal Architecture](../../architecture/09-architecture-decisions.md#adr-002-hexagonal-architecture-ports-and-adapters)
- [09 ADR-004 Deterministic Domain via Injected Seed and Immutable Transitions](../../architecture/09-architecture-decisions.md#adr-004-deterministic-domain-via-injected-seed-and-immutable-transitions)
- [10 §10.2 Q1 — Testability/Determinism (Q1.3 BDD-ready transition)](../../architecture/10-quality-requirements.md#q1--testability--determinism-priority-1)
- [12 §12.1 Domain Terms — Reveal, Safe cell, Cell, Visibility](../../architecture/12-glossary.md#121-domain-terms-the-game)
- [12 §12.2 Code/Model Terms — GameState, GameEngine, Action](../../architecture/12-glossary.md#122-codemodel-terms)

## Original Story

AS A Player
I WANT to reveal a hidden safe cell so that its hint number appears on the board
SO THAT I can uncover the board and work toward winning

### SCENARIO 1: Revealing a hidden safe cell with a non-zero hint shows its number

**Scenario ID**: GAME-STORY-001-S1

**GIVEN**
* An initial `GameState` for a 3x3 board with mines at `(0,0)` and `(2,2)`
* The hint `Grid` for that board is `[["*","1","0"], ["1","2","1"], ["0","1","*"]]`
* Every cell is `hidden` and `status == "playing"`

**WHEN**
* `GameEngine.apply(state, Reveal(0, 1))` is called (cell `(0,1)` is safe with hint `1`, so no flood-fill)

**THEN**
* The returned `GameState` has `visibility_at(0, 1) == "revealed"`
* The hint at `(0,1)` is available as `next.hints.at(0, 1) == "1"`
* All other eight cells remain `hidden` (`visibility_at(r, c) == "hidden"` for every other cell)
* `next.status == "playing"`
* The original `state` is unchanged: `state.visibility_at(0, 1) == "hidden"`

### SCENARIO 2: Revealing an already-revealed cell is a no-op (idempotent)

**Scenario ID**: GAME-STORY-001-S2

**GIVEN**
* A `GameState` in which cell `(0,1)` is already `revealed`

**WHEN**
* `GameEngine.apply(state, Reveal(0, 1))` is called again

**THEN**
* The returned `GameState` equals the input state (`next == state`)
* No exception is raised (§8.2 idempotent action)
* `next.status == "playing"`

### SCENARIO 3: An out-of-bounds reveal reaching the core raises a domain exception

**Scenario ID**: GAME-STORY-001-S3

**GIVEN**
* The initial 3x3 `GameState`

**WHEN**
* `GameEngine.apply(state, Reveal(5, 5))` is called (`(5,5)` is outside the 3x3 board)

**THEN**
* A domain exception (`CellOutOfBounds`) is raised
* No new `GameState` is returned
* The original `state` is unchanged

---

## FE: N/A — the reveal transition is a pure domain concern

**Parent**: GAME-STORY-001

The reveal transition `(state, Reveal(r,c)) → state` is pure domain logic in `GameEngine`. The player's reveal command is parsed by CLI-STORY-003, driven by the GameLoop in CLI-STORY-004, and the revealed hint number is drawn to the terminal by CLI-STORY-002. The Presentation layer adds no distinct behavior to the transition itself, so no FE sub-story exists for this story.

---

## GAME-BE-001.1: GameState — immutable game state value object

**Parent**: GAME-STORY-001
**Component**: GameState (`game/state.py`)
**Architecture References**:
- [05 §5.3 Game context — GameState](../../architecture/05-building-block-view.md#game-context)
- [08 §8.1 Domain Modeling — Immutability, value objects at seams](../../architecture/08-cross-cutting-concepts.md#81-domain-modeling)
- [09 ADR-004 Deterministic Domain via Injected Seed and Immutable Transitions](../../architecture/09-architecture-decisions.md#adr-004-deterministic-domain-via-injected-seed-and-immutable-transitions)
- [12 §12.2 Code/Model Terms — GameState, Visibility, Status](../../architecture/12-glossary.md#122-codemodel-terms)

AS A Developer
I WANT an immutable `GameState` holding the board, the hints, per-cell visibility, and the status
SO THAT game transitions are pure, deterministic, and unit-testable without I/O

### SCENARIO 1: Initial state from a board and its hint field

**Scenario ID**: GAME-BE-001.1-S1

**GIVEN**
* A 3x3 mine-layout `Grid` `board` with mines at `(0,0)` and `(2,2)`
* The hint `Grid` `hints == [["*","1","0"], ["1","2","1"], ["0","1","*"]]`

**WHEN**
* `state = GameState.initial(board=board, hints=hints)` is constructed

**THEN**
* `state.dimensions == (3, 3)`
* `state.status == "playing"`
* `state.visibility_at(0, 0) == "hidden"` and `state.visibility_at(1, 1) == "hidden"` (all nine cells are `hidden`)
* `state.board.at(0, 0) == "*"` and `state.hints.at(1, 1) == "2"`

### SCENARIO 2: Immutability and value equality

**Scenario ID**: GAME-BE-001.1-S2

**GIVEN**
* `state_a = GameState.initial(board, hints)` and `state_b = GameState.initial(board, hints)` from equal data

**WHEN**
* `state_a` and `state_b` are compared

**THEN**
* `state_a == state_b` (value equality by contents)
* `hash(state_a) == hash(state_b)` (usable as a dict key / in sets)
* `GameState` exposes no mutating setter; an attempt to assign `state_a.cells[0][0] = "x"` raises `TypeError` (visibility/board/hints are immutable containers)

### SCENARIO 3: Invalid visibility or status raises

**Scenario ID**: GAME-BE-001.1-S3

**GIVEN**
* The `GameState` constructor

**WHEN**
* A `GameState` is built with a visibility value other than `"hidden"`, `"revealed"`, or `"flagged"` (e.g. `"unknown"`)

**THEN**
* `ValueError` is raised

**WHEN**
* A `GameState` is built with a `status` other than `"playing"`, `"won"`, or `"lost"`

**THEN**
* `ValueError` is raised

---

## GAME-BE-001.2: GameEngine.apply — pure reveal transition

**Parent**: GAME-STORY-001
**Component**: GameEngine (`game/engine.py`)
**Architecture References**:
- [01 §1.2 Requirements Overview — F3](../../architecture/01-introduction-and-goals.md#12-requirements-overview)
- [05 §5.3 Game context — GameEngine](../../architecture/05-building-block-view.md#game-context)
- [06 §6.3 Scenario 2 — Reveal a Safe Cell with Flood-Fill](../../architecture/06-runtime-view.md#63-scenario-2--reveal-a-safe-cell-with-flood-fill)
- [08 §8.1 Domain Modeling — Stateless transitions](../../architecture/08-cross-cutting-concepts.md#81-domain-modeling)
- [08 §8.2 Error Handling — idempotent action](../../architecture/08-cross-cutting-concepts.md#82-error-handling)
- [08 §8.3 Input Validation — defense in depth (bounds)](../../architecture/08-cross-cutting-concepts.md#83-input-validation)
- [09 ADR-004 Deterministic Domain via Injected Seed and Immutable Transitions](../../architecture/09-architecture-decisions.md#adr-004-deterministic-domain-via-injected-seed-and-immutable-transitions)
- [10 §10.2 Q1 — Q1.3 BDD-ready transition](../../architecture/10-quality-requirements.md#q1--testability--determinism-priority-1)
- [12 §12.2 Code/Model Terms — GameEngine, Action, Reveal](../../architecture/12-glossary.md#122-codemodel-terms)

AS A Developer
I WANT `GameEngine.apply(state, Reveal(r, c))` to return the next `GameState` with that safe cell revealed
SO THAT reveal is a pure, deterministic, BDD-ready `(state, action) → state` transition

### SCENARIO 1: Revealing a hidden safe cell with a non-zero hint

**Scenario ID**: GAME-BE-001.2-S1

**GIVEN**
* `state = GameState.initial(board, hints)` for the 3x3 board (mines at `(0,0)` and `(2,2)`), all cells `hidden`, `status == "playing"`
* The hint at `(0,1)` is `"1"` (non-zero, so no flood-fill)

**WHEN**
* `next = GameEngine.apply(state, Reveal(0, 1))`

**THEN**
* `next.visibility_at(0, 1) == "revealed"`
* `next.visibility_at(0, 0) == "hidden"` and every other cell stays `hidden`
* `next.hints.at(0, 1) == "1"` (the revealed cell's hint)
* `next.status == "playing"`
* `next != state` and `state.visibility_at(0, 1) == "hidden"` (the input state is unchanged)
* `GameEngine.apply` performs no I/O and uses no random source

### SCENARIO 2: Revealing an already-revealed cell is a no-op

**Scenario ID**: GAME-BE-001.2-S2

**GIVEN**
* `state1 = GameEngine.apply(initial, Reveal(0, 1))` (cell `(0,1)` is `revealed`)

**WHEN**
* `state2 = GameEngine.apply(state1, Reveal(0, 1))`

**THEN**
* `state2 == state1` (equivalent state, no change)
* No exception is raised (§8.2 idempotent action)

### SCENARIO 3: An out-of-bounds reveal raises a domain exception

**Scenario ID**: GAME-BE-001.2-S3

**GIVEN**
* The initial 3x3 `GameState`

**WHEN**
* `GameEngine.apply(state, Reveal(5, 5))` is called (`(5,5)` is out of bounds)

**THEN**
* `CellOutOfBounds` is raised and no `GameState` is returned
* The original `state` is unchanged

---

## GAME-INFRA-001.1: Packaging — game state and engine run via `python -m minesweeper`, stdlib only

**Parent**: GAME-STORY-001
**Architecture References**:
- [02 §2.1 Technical Constraints — T1, T2, T3](../../architecture/02-constraints.md#21-technical-constraints)
- [02 §2.3 Conventions — C2 type hints, C6 test layout mirrors source](../../architecture/02-constraints.md#23-conventions-and-coding-standards)
- [05 §5.5 Module / Package Layout](../../architecture/05-building-block-view.md#55-module--package-layout)
- [08 §8.5 Testing Strategy](../../architecture/08-cross-cutting-concepts.md#85-testing-strategy)
- [09 ADR-001 Technology Stack](../../architecture/09-architecture-decisions.md#adr-001-technology-stack)

AS A Developer
I WANT the `game/` package importable and testable under Python 3.12 with the standard library only
SO THAT reveal transitions run with zero third-party installs and their tests pass locally and in CI

### SCENARIO 1: Runnable with stdlib only

**Scenario ID**: GAME-INFRA-001.1-S1

**GIVEN**
* The repository on a clean POSIX box with Python 3.12 and no third-party packages installed

**WHEN**
* `python -m minesweeper` is started

**THEN**
* `game/state.py` and `game/engine.py` import only standard-library modules (e.g. `typing`); they import nothing from `presentation` and no third-party package

**WHEN**
* `python -m pytest tests/game/test_state.py tests/game/test_engine.py` is run

**THEN**
* All tests pass
* No test imports from `minesweeper.presentation` and no test imports a third-party package (only `pytest`, test-time)

### SCENARIO 2: Test layout mirrors source and runs in CI

**Scenario ID**: GAME-INFRA-001.1-S2

**GIVEN**
* The pre-commit hook and GitHub Actions workflow (Module 4) configured for Python 3.12

**WHEN**
* The game tests run in CI on Linux

**THEN**
* `tests/game/test_state.py` mirrors `game/state.py` and `tests/game/test_engine.py` mirrors `game/engine.py` (convention C6)
* The tests pass; pre-commit format and trailing-whitespace checks pass on the `game/` source files

---

## GAME-INFRA-001.2: Data store — game state is in-memory only; nothing written to disk

**Parent**: GAME-STORY-001
**Architecture References**:
- [02 §2.1 Technical Constraints — T4 no database, persistence is scores-only](../../architecture/02-constraints.md#21-technical-constraints)
- [08 §8.1 Domain Modeling — Pure core, dependency direction](../../architecture/08-cross-cutting-concepts.md#81-domain-modeling)
- [09 ADR-002 Hexagonal Architecture](../../architecture/09-architecture-decisions.md#adr-002-hexagonal-architecture-ports-and-adapters)

AS A Developer
I WANT `GameEngine.apply` to return an in-memory immutable `GameState` and never touch the file system
SO THAT the Game context stays unit-testable without I/O

### SCENARIO 1: Applying an action writes nothing to disk

**Scenario ID**: GAME-INFRA-001.2-S1

**GIVEN**
* A temporary working directory whose file listing is recorded before the call

**WHEN**
* `GameEngine.apply(state, Reveal(0, 1))` runs in that directory

**THEN**
* The returned `GameState` is held in memory as an immutable value object
* The set of files in the working directory is unchanged (no file is created or written)

### SCENARIO 2: No file-system imports in the Game context

**Scenario ID**: GAME-INFRA-001.2-S2

**GIVEN**
* The `game/` package source

**WHEN**
* Its imports are inspected (static import check, per risk R1)

**THEN**
* No module under `game/` imports `pathlib`, `json`, `os`, `sys`, or anything from `presentation` (constraint C7)

---

## GAME-INFRA-001.3: N/A — the engine is a pure transition, not the command cycle

**Parent**: GAME-STORY-001

`GameEngine.apply(state, action)` is a pure `(state, action) → state` function called once per command by the `GameLoop`. The stdin command cycle (stdin line → action → new state → render) is owned by CLI-STORY-004, so this story has no event-handling sub-story of its own.

---

## GAME-INFRA-001.4: Monitoring and observability — domain does not log; invariant violations are reported

**Parent**: GAME-STORY-001
**Architecture References**:
- [02 §2.4 Operating Environment — E6 exit codes](../../architecture/02-constraints.md#24-operating-environment)
- [08 §8.2 Error Handling — domain invariant raises, CLI translates](../../architecture/08-cross-cutting-concepts.md#82-error-handling)
- [08 §8.4 Logging and Diagnostics — domain does not log](../../architecture/08-cross-cutting-concepts.md#84-logging-and-diagnostics)
- [10 §10.2 Q5 — Robustness (Q5.1 bad input never crashes)](../../architecture/10-quality-requirements.md#q5--robustness)

AS A Developer
I WANT the reveal transition to stay silent (the domain does not log) and to surface invariant violations cleanly
SO THAT logs stay noise-free and a bad action never crashes the game

### SCENARIO 1: GameEngine emits no log records

**Scenario ID**: GAME-INFRA-001.4-S1

**GIVEN**
* A captured log handler, a valid `GameState`, and `Reveal(0, 1)`

**WHEN**
* `GameEngine.apply(state, Reveal(0, 1))` runs

**THEN**
* No log record is emitted by `GameEngine` (the domain does not log, §8.4)
* Nothing is written to stdout by the Game context (stdout is reserved for the rendered board, owned by CLI-STORY-002)

### SCENARIO 2: Invariant violation is reported; fatal errors exit non-zero

**Scenario ID**: GAME-INFRA-001.4-S2

**GIVEN**
* An out-of-bounds `Reveal(5, 5)` reaches the core

**WHEN**
* `GameEngine.apply` raises `CellOutOfBounds`

**THEN**
* The `GameLoop` catches the exception, logs it to stderr at `WARNING`, prints a short user-facing error message to stdout, and re-prompts
* The game state is unchanged and the loop continues (does not crash)

**WHEN**
* An unexpected exception (not a domain invariant violation) escapes all handlers

**THEN**
* The process exits with a non-zero code (E6)
