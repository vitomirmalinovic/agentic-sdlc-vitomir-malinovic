# BOARD-STORY-001: Generate a deterministic board from an injected seed

**Priority**: CORE (Pareto 20%)
**Architecture References**:
- [01 §1.2 Requirements Overview — F2](../../architecture/01-introduction-and-goals.md#12-requirements-overview)
- [01 §1.3 Quality Goals — Testability/Determinism](../../architecture/01-introduction-and-goals.md#13-quality-goals-top-priorities)
- [05 §5.3 Board context](../../architecture/05-building-block-view.md#board-context)
- [06 §6.2 Scenario 1 — Start a New Game](../../architecture/06-runtime-view.md#62-scenario-1--start-a-new-game)
- [09 ADR-004 Deterministic Domain via Injected Seed](../../architecture/09-architecture-decisions.md#adr-004-deterministic-domain-via-injected-seed-and-immutable-transitions)
- [10 §10.2 Q1 — Testability/Determinism (Q1.2 reproducible board)](../../architecture/10-quality-requirements.md#q1--testability--determinism-priority-1)

## Original Story

AS A Player
I WANT a board of my chosen rows, columns, and mine count generated from a seed I can reuse
SO THAT I get a reproducible game whose layout I can replay, share, and test deterministically

### SCENARIO 1: Same seed yields a board with the requested dimensions and mine count

**Scenario ID**: BOARD-STORY-001-S1

**GIVEN**
* The `BoardGenerator` component and a `random.Random(42)` instance

**WHEN**
* `BoardGenerator.generate(rows=3, cols=3, mines=2, rng=random.Random(42))` is called once, and called a second time with an identical `random.Random(42)`

**THEN**
* Both calls return a `Grid` whose `dimensions` equal `(3, 3)`
* Each returned `Grid` contains exactly `2` cells equal to `"*"` (mines) and `7` cells equal to `"."` (safe)
* The two returned `Grid` values are equal (`grid_a == grid_b`)
* `BoardGenerator.generate` reads randomness only from the injected `rng`: reseeding the module-level `random` between the two calls does not change the returned `Grid`

### SCENARIO 2: Boundary mine counts (0 mines and mines == cells) are valid

**Scenario ID**: BOARD-STORY-001-S2

**GIVEN**
* The `BoardGenerator` component and a `random.Random` instance

**WHEN**
* `BoardGenerator.generate(rows=1, cols=1, mines=0, rng=random.Random(7))` is called

**THEN**
* The returned `Grid` has `dimensions == (1, 1)`, `0` cells equal to `"*"`, and `1` cell equal to `"."`

**WHEN**
* `BoardGenerator.generate(rows=3, cols=3, mines=9, rng=random.Random(1))` is called (`mines == rows*cols`, the maximum allowed by the invariant)

**THEN**
* The returned `Grid` has `dimensions == (3, 3)`, exactly `9` cells equal to `"*"`, and `0` cells equal to `"."`

### SCENARIO 3: Invalid configuration raises a domain exception

**Scenario ID**: BOARD-STORY-001-S3

**GIVEN**
* The `BoardGenerator` component and a `random.Random` instance

**WHEN**
* `BoardGenerator.generate(rows=3, cols=3, mines=10, rng=random.Random(1))` is called (`mines > rows*cols`)

**THEN**
* A domain exception (`InvalidBoardConfig`) is raised
* No `Grid` is returned

**WHEN**
* `BoardGenerator.generate(rows=0, cols=3, mines=2, rng=random.Random(1))` is called (zero rows)

**THEN**
* `InvalidBoardConfig` is raised

**WHEN**
* `BoardGenerator.generate(rows=3, cols=3, mines=-1, rng=random.Random(1))` is called (negative mine count)

**THEN**
* `InvalidBoardConfig` is raised

---

## FE: N/A — board generation is a pure domain concern

**Parent**: BOARD-STORY-001

The mine-layout `Grid` is an internal domain value object; the Presentation layer never renders or parses it directly. The player's size/mines/seed input and the call to `BoardGenerator.generate(...)` are owned by CLI-STORY-001 (start a new game) and the loop orchestration in CLI-STORY-004. The `Grid` reaches the terminal only indirectly, as part of a `GameState` rendered by CLI-STORY-002. No distinct FE sub-story exists for this story.

---

## BOARD-BE-001.1: Grid — immutable 2D value object

**Parent**: BOARD-STORY-001
**Component**: Grid (`board/grid.py`)
**Architecture References**:
- [05 §5.3 Board context — Grid](../../architecture/05-building-block-view.md#board-context)
- [08 §8.1 Domain Modeling — Immutability, value objects at seams](../../architecture/08-cross-cutting-concepts.md#81-domain-modeling)
- [12 §12.2 Code/Model Terms — Grid](../../architecture/12-glossary.md#122-codemodel-terms)

AS A Developer
I WANT an immutable `Grid` value object that holds dimensions and per-cell values
SO THAT the mine layout and the later hint field can be passed between contexts safely without aliasing or mutation

### SCENARIO 1: Construction and cell access

**Scenario ID**: BOARD-BE-001.1-S1

**GIVEN**
* A 3x3 layout with mines at `(0,0)` and `(2,2)`, supplied as rows `[["*",".","."], [".",".","."], [".",".","*"]]`

**WHEN**
* `grid = Grid(rows=3, cols=3, cells=[["*",".","."], [".",".","."], [".",".","*"]])` is constructed

**THEN**
* `grid.rows == 3` and `grid.cols == 3`
* `grid.dimensions == (3, 3)`
* `grid.at(0, 0) == "*"`
* `grid.at(2, 2) == "*"`
* `grid.at(1, 1) == "."`

### SCENARIO 2: Immutability and value equality

**Scenario ID**: BOARD-BE-001.1-S2

**GIVEN**
* `grid_a = Grid(3, 3, [["*",".","."], [".",".","."], [".",".","*"]])`
* `grid_b = Grid(3, 3, [["*",".","."], [".",".","."], [".",".","*"]])`

**WHEN**
* `grid_a` and `grid_b` are compared

**THEN**
* `grid_a == grid_b` (value equality by contents)
* `hash(grid_a) == hash(grid_b)` (usable as a dict key / in sets)

**WHEN**
* An attempt is made to mutate a cell via `grid_a.cells[0][0] = "."`

**THEN**
* `TypeError` is raised (the `cells` container is immutable, e.g. a tuple of tuples)
* After the attempt, `grid_a.at(0, 0) == "*"` still holds (the value object is unchanged)

### SCENARIO 3: Shape mismatch and out-of-bounds access raise

**Scenario ID**: BOARD-BE-001.1-S3

**GIVEN**
* The `Grid` constructor

**WHEN**
* `Grid(rows=3, cols=3, cells=[["*",".","."], [".","."]])` is constructed (9 cells expected, only 5 supplied)

**THEN**
* `ValueError` is raised

**WHEN**
* `grid.at(5, 5)` is called on a 3x3 `Grid`

**THEN**
* `IndexError` is raised

---

## BOARD-BE-001.2: BoardGenerator — deterministic mine layout from an injected RNG

**Parent**: BOARD-STORY-001
**Component**: BoardGenerator (`board/generator.py`)
**Architecture References**:
- [01 §1.2 Requirements Overview — F2](../../architecture/01-introduction-and-goals.md#12-requirements-overview)
- [02 §2.1 Technical Constraints — T6 injected random.Random, no module-level random.*](../../architecture/02-constraints.md#21-technical-constraints)
- [05 §5.3 Board context — BoardGenerator](../../architecture/05-building-block-view.md#board-context)
- [06 §6.2 Scenario 1 — Start a New Game](../../architecture/06-runtime-view.md#62-scenario-1--start-a-new-game)
- [08 §8.1 Domain Modeling — Injected randomness](../../architecture/08-cross-cutting-concepts.md#81-domain-modeling)
- [09 ADR-004 Deterministic Domain via Injected Seed](../../architecture/09-architecture-decisions.md#adr-004-deterministic-domain-via-injected-seed-and-immutable-transitions)
- [10 §10.2 Q1 — Q1.2 reproducible board](../../architecture/10-quality-requirements.md#q1--testability--determinism-priority-1)
- [12 §12.2 Code/Model Terms — BoardGenerator, Seed](../../architecture/12-glossary.md#122-codemodel-terms)

AS A Developer
I WANT `BoardGenerator.generate(rows, cols, mines, rng)` to return a mine-layout `Grid` using only the injected `random.Random`
SO THAT the board is reproducible for a given seed and the domain stays free of hidden randomness

### SCENARIO 1: Deterministic layout with exact mine count

**Scenario ID**: BOARD-BE-001.2-S1

**GIVEN**
* `rng = random.Random(42)`

**WHEN**
* `g1 = BoardGenerator.generate(rows=3, cols=3, mines=2, rng=rng)`
* `g2 = BoardGenerator.generate(rows=3, cols=3, mines=2, rng=random.Random(42))`

**THEN**
* `g1.dimensions == (3, 3)`
* `g1` has exactly `2` cells equal to `"*"` and `7` cells equal to `"."`
* `g1 == g2` (identical seed ⇒ identical layout)

**WHEN**
* The module-level `random` is reseeded to two different values between two otherwise identical calls of `BoardGenerator.generate(3, 3, 2, random.Random(42))`

**THEN**
* Both returned `Grid` values are equal (the generator does not read the module-level `random`)

### SCENARIO 2: Boundary mine counts are generated correctly

**Scenario ID**: BOARD-BE-001.2-S2

**GIVEN**
* The `BoardGenerator` component

**WHEN**
* `BoardGenerator.generate(rows=1, cols=1, mines=0, rng=random.Random(7))` is called

**THEN**
* The returned `Grid` has `dimensions == (1, 1)`, `0` cells equal to `"*"`, and `1` cell equal to `"."`

**WHEN**
* `BoardGenerator.generate(rows=3, cols=3, mines=9, rng=random.Random(1))` is called (`mines == rows*cols`)

**THEN**
* The returned `Grid` has exactly `9` cells equal to `"*"` and `0` cells equal to `"."`

### SCENARIO 3: Invalid configuration raises a domain exception

**Scenario ID**: BOARD-BE-001.2-S3

**GIVEN**
* The `BoardGenerator` component

**WHEN**
* `BoardGenerator.generate(rows=3, cols=3, mines=10, rng=random.Random(1))` is called (`mines > rows*cols`)

**THEN**
* `InvalidBoardConfig` is raised and no `Grid` is returned

**WHEN**
* `BoardGenerator.generate(rows=0, cols=3, mines=2, rng=random.Random(1))` is called (non-positive dimension)

**THEN**
* `InvalidBoardConfig` is raised

**WHEN**
* `BoardGenerator.generate(rows=3, cols=3, mines=-1, rng=random.Random(1))` is called (negative mine count)

**THEN**
* `InvalidBoardConfig` is raised

---

## BOARD-INFRA-001.1: Packaging — board generation runs via `python -m minesweeper`, stdlib only

**Parent**: BOARD-STORY-001
**Architecture References**:
- [02 §2.1 Technical Constraints — T1 Python 3.12, T2 stdlib only, T3 pytest test-only](../../architecture/02-constraints.md#21-technical-constraints)
- [02 §2.3 Conventions — C2 type hints, C6 test layout mirrors source](../../architecture/02-constraints.md#23-conventions-and-coding-standards)
- [05 §5.5 Module / Package Layout](../../architecture/05-building-block-view.md#55-module--package-layout)
- [07 §7.3 How the Software Is Run](../../architecture/07-deployment-view.md#73-how-the-software-is-run)
- [08 §8.5 Testing Strategy](../../architecture/08-cross-cutting-concepts.md#85-testing-strategy)
- [09 ADR-001 Technology Stack](../../architecture/09-architecture-decisions.md#adr-001-technology-stack)

AS A Developer
I WANT the `board/` package to be importable and testable under Python 3.12 with the standard library only
SO THAT board generation runs with zero third-party installs and its tests pass locally and in CI

### SCENARIO 1: Runnable with stdlib only

**Scenario ID**: BOARD-INFRA-001.1-S1

**GIVEN**
* The repository checked out on a clean POSIX box with Python 3.12 and no third-party packages installed

**WHEN**
* `python -m minesweeper` is started

**THEN**
* The process begins and reaches board-generation setup
* Modules under `minesweeper/board/` import only standard-library modules (`random`, and `typing` for hints)

**WHEN**
* `python -m pytest tests/board/test_grid.py tests/board/test_generator.py` is run

**THEN**
* All tests pass
* No test imports from `minesweeper.presentation` and no test imports a third-party package (only `pytest`, test-time)

### SCENARIO 2: Test layout mirrors source and runs in CI

**Scenario ID**: BOARD-INFRA-001.1-S2

**GIVEN**
* The pre-commit hook and GitHub Actions workflow (Module 4) configured for Python 3.12

**WHEN**
* The board tests run in CI on Linux

**THEN**
* `tests/board/test_grid.py` mirrors `board/grid.py` and `tests/board/test_generator.py` mirrors `board/generator.py` (convention C6)
* The tests pass; pre-commit format and trailing-whitespace checks pass on the `board/` source files

---

## BOARD-INFRA-001.2: Data store — board state is in-memory only; nothing written to disk

**Parent**: BOARD-STORY-001
**Architecture References**:
- [02 §2.1 Technical Constraints — T4 no database, all persistence local file I/O (scores only)](../../architecture/02-constraints.md#21-technical-constraints)
- [04 §4.4 Key Strategic Choices — value objects, optional removable storage](../../architecture/04-solution-strategy.md#44-key-strategic-choices)
- [08 §8.1 Domain Modeling — Pure core, dependency direction](../../architecture/08-cross-cutting-concepts.md#81-domain-modeling)
- [09 ADR-002 Hexagonal Architecture](../../architecture/09-architecture-decisions.md#adr-002-hexagonal-architecture-ports-and-adapters)

AS A Developer
I WANT board generation to hold its result only in memory as an immutable `Grid`
SO THAT the Board context never touches the file system and stays unit-testable without I/O

### SCENARIO 1: Generation writes nothing to disk

**Scenario ID**: BOARD-INFRA-001.2-S1

**GIVEN**
* `BoardGenerator` and a temporary working directory whose file listing is recorded before the call

**WHEN**
* `BoardGenerator.generate(rows=3, cols=3, mines=2, rng=random.Random(42))` runs in that directory

**THEN**
* The resulting `Grid` is held in memory as an immutable value object
* The set of files in the working directory is unchanged (no file is created or written)

**WHEN**
* The process exits without reaching a win

**THEN**
* No scores file is written by the Board context (the Board context never imports a storage adapter)

### SCENARIO 2: No file-system imports in the Board context

**Scenario ID**: BOARD-INFRA-001.2-S2

**GIVEN**
* The `board/` package source

**WHEN**
* Its imports are inspected (static import check, per risk R1)

**THEN**
* No module under `board/` imports `pathlib`, `json`, `os`, `sys`, or anything from `presentation` (constraint C7)

---

## BOARD-INFRA-001.3: N/A — generation is not a stdin command-cycle transition

**Parent**: BOARD-STORY-001

Board generation is a one-time setup step orchestrated by the `GameLoop` at session start (CLI-STORY-001 / CLI-STORY-004). It is not a stdin command-cycle transition (stdin line → action → new state → render), so it has no event-handling sub-story of its own. The command cycle that consumes the generated board is owned by CLI-STORY-004.

---

## BOARD-INFRA-001.4: Monitoring and observability — DEBUG-log seed and dimensions; report domain exceptions

**Parent**: BOARD-STORY-001
**Architecture References**:
- [02 §2.4 Operating Environment — E6 exit codes](../../architecture/02-constraints.md#24-operating-environment)
- [08 §8.2 Error Handling — domain invariant raises, CLI translates](../../architecture/08-cross-cutting-concepts.md#82-error-handling)
- [08 §8.4 Logging and Diagnostics — stderr logging, DEBUG seed/dimensions](../../architecture/08-cross-cutting-concepts.md#84-logging-and-diagnostics)
- [10 §10.2 Q5 — Robustness (Q5.1 bad input never crashes)](../../architecture/10-quality-requirements.md#q5--robustness)

AS A Developer
I WANT board generation to log its seed and dimensions at DEBUG and to surface invalid configurations cleanly
SO THAT a run is reproducible from the logs and a bad configuration never crashes the game

### SCENARIO 1: DEBUG log of seed and dimensions goes to stderr, not stdout

**Scenario ID**: BOARD-INFRA-001.4-S1

**GIVEN**
* `LOGLEVEL=DEBUG` and the game starting

**WHEN**
* `BoardGenerator.generate(rows=3, cols=3, mines=2, rng=random.Random(42))` runs

**THEN**
* A DEBUG log record is emitted to stderr containing `seed=42`, `rows=3`, `cols=3`, and `mines=2`
* Nothing is written to stdout by the Board context (stdout is reserved for the rendered board, owned by CLI-STORY-002)

### SCENARIO 2: Domain exception is reported and the game re-prompts; fatal errors exit non-zero

**Scenario ID**: BOARD-INFRA-001.4-S2

**GIVEN**
* A configuration that violates the core invariant (`mines > rows*cols`) reaches the core

**WHEN**
* `BoardGenerator.generate` raises `InvalidBoardConfig`

**THEN**
* The `GameLoop` catches the exception, logs it to stderr at `WARNING`, prints a short user-facing error message to stdout, and re-prompts
* The game state is unchanged and the loop continues (does not crash)

**WHEN**
* An unexpected exception (not a domain invariant violation) escapes all handlers

**THEN**
* The process exits with a non-zero code (E6)

# BOARD-STORY-002: Compute the hint field with 8-neighbour counts

**Priority**: CORE (Pareto 20%)
**Architecture References**:
- [01 §1.2 Requirements Overview — F1](../../architecture/01-introduction-and-goals.md#12-requirements-overview)
- [01 §1.3 Quality Goals — Correctness](../../architecture/01-introduction-and-goals.md#13-quality-goals-top-priorities)
- [05 §5.3 Board context](../../architecture/05-building-block-view.md#board-context)
- [06 §6.2 Scenario 1 — Start a New Game](../../architecture/06-runtime-view.md#62-scenario-1--start-a-new-game)
- [08 §8.1 Domain Modeling — Pure core, stateless transitions](../../architecture/08-cross-cutting-concepts.md#81-domain-modeling)
- [09 ADR-003 Bounded Contexts](../../architecture/09-architecture-decisions.md#adr-003-bounded-contexts-board-game-presentation)
- [09 ADR-004 Deterministic Domain via Injected Seed](../../architecture/09-architecture-decisions.md#adr-004-deterministic-domain-via-injected-seed-and-immutable-transitions)
- [10 §10.2 Q2 — Correctness (Q2.1 exact hint field)](../../architecture/10-quality-requirements.md#q2--correctness-priority-2)
- [12 §12.1 Domain Terms — Hint, Hint field](../../architecture/12-glossary.md#121-domain-terms-the-game)
- [12 §12.2 Code/Model Terms — HintComputer](../../architecture/12-glossary.md#122-codemodel-terms)

## Original Story

AS A Player
I WANT each safe cell to show the exact count of mines in its eight neighbours
SO THAT the board gives correct Minesweeper hints and the game rules (flood-fill, win/lose) rest on trustworthy numbers

### SCENARIO 1: Exact hint field for a known layout (happy path)

**Scenario ID**: BOARD-STORY-002-S1

**GIVEN**
* A mine-layout `Grid` of 3x3 with mines at `(0,0)` and `(2,2)`:
  `cells = [["*",".","."], [".",".","."], [".",".","*"]]`

**WHEN**
* `HintComputer.compute(layout)` is called

**THEN**
* The returned hint `Grid` has `dimensions == (3, 3)`
* Cell `(0,0) == "*"` (a mine stays `"*"`, not a count)
* Cells `(0,1) == "1"` and `(0,2) == "0"`
* Cells `(1,0) == "1"`, `(1,1) == "2"`, `(1,2) == "1"`
* Cells `(2,0) == "0"`, `(2,1) == "1"`, `(2,2) == "*"`
* The full hint `Grid` equals `[["*","1","0"], ["1","2","1"], ["0","1","*"]]`

### SCENARIO 2: Boundary layouts — max count 8, no mines, all mines

**Scenario ID**: BOARD-STORY-002-S2

**GIVEN**
* A 3x3 mine-layout `Grid` with mines at all eight non-centre cells:
  `cells = [["*","*","*"], ["*",".","*"], ["*","*","*"]]`

**WHEN**
* `HintComputer.compute(layout)` is called

**THEN**
* Cell `(1,1) == "8"` (eight mine neighbours)
* All eight surrounding cells equal `"*"`

**WHEN**
* A 1x1 mine-layout `Grid` `[["*"]]` is given

**THEN**
* The hint `Grid` equals `[["*"]]`

**WHEN**
* A 1x1 mine-layout `Grid` `[["."]]` is given

**THEN**
* The hint `Grid` equals `[["0"]]`

**WHEN**
* A 2x2 mine-layout `Grid` `[[".","."], [".","."]]` (no mines) is given

**THEN**
* The hint `Grid` equals `[["0","0"], ["0","0"]]`

### SCENARIO 3: Non-conforming layout raises a domain exception (edge/error)

**Scenario ID**: BOARD-STORY-002-S3

**GIVEN**
* A `Grid` whose cells contain a value other than `"*"` or `"."`, e.g. `cells = [["X",".","."], [".",".","."], [".",".","*"]]`

**WHEN**
* `HintComputer.compute(layout)` is called

**THEN**
* `InvalidBoardConfig` is raised (defense in depth, §8.3) and no hint `Grid` is returned

---

## FE: N/A — the hint Grid is an internal domain value

**Parent**: BOARD-STORY-002

The hint `Grid` is consumed by `GameEngine` (GAME-STORY-001 / GAME-STORY-002) and reaches the player only through revealed cells rendered by CLI-STORY-002. The Presentation layer never parses or directly renders the raw hint `Grid`, so no distinct FE sub-story exists for this story.

---

## BOARD-BE-002.1: HintComputer — pure 8-neighbour hint computation

**Parent**: BOARD-STORY-002
**Component**: HintComputer (`board/hints.py`)
**Architecture References**:
- [01 §1.2 Requirements Overview — F1](../../architecture/01-introduction-and-goals.md#12-requirements-overview)
- [05 §5.3 Board context — HintComputer](../../architecture/05-building-block-view.md#board-context)
- [08 §8.1 Domain Modeling — Pure core, value objects at seams](../../architecture/08-cross-cutting-concepts.md#81-domain-modeling)
- [09 ADR-003 Bounded Contexts](../../architecture/09-architecture-decisions.md#adr-003-bounded-contexts-board-game-presentation)
- [10 §10.2 Q2 — Q2.1 exact hint field](../../architecture/10-quality-requirements.md#q2--correctness-priority-2)
- [12 §12.2 Code/Model Terms — HintComputer, Grid](../../architecture/12-glossary.md#122-codemodel-terms)

AS A Developer
I WANT `HintComputer.compute(mine_layout)` to return the hint `Grid` as a pure function
SO THAT hint counts are exact, deterministic, and unit-testable without any I/O

### SCENARIO 1: Exact 8-neighbour counts for a 3x3 layout

**Scenario ID**: BOARD-BE-002.1-S1

**GIVEN**
* A mine-layout `Grid` of 3x3 with mines at `(0,0)` and `(2,2)`:
  `cells = [["*",".","."], [".",".","."], [".",".","*"]]`

**WHEN**
* `HintComputer.compute(layout)` is called

**THEN**
* The returned hint `Grid` equals `[["*","1","0"], ["1","2","1"], ["0","1","*"]]`
* `hint.dimensions == (3, 3)`
* `hint.at(1,1) == "2"` (the centre counts two diagonal mines)
* `hint.at(0,0) == "*"` and `hint.at(2,2) == "*"` (mines stay `"*"`)

### SCENARIO 2: Purity and statelessness

**Scenario ID**: BOARD-BE-002.1-S2

**GIVEN**
* `HintComputer` and the same mine-layout `Grid` supplied twice

**WHEN**
* `HintComputer.compute(layout)` is called twice

**THEN**
* Both calls return equal hint `Grid`s (`h1 == h2`)
* `HintComputer.compute` performs no I/O and uses no random source (it reads only the input `Grid`)
* After the call, every cell of the input `Grid` is unchanged (`layout.at(r,c)` returns its original value for all `r,c`) — the input is not mutated

### SCENARIO 3: Boundary and invalid layout

**Scenario ID**: BOARD-BE-002.1-S3

**GIVEN**
* `HintComputer`

**WHEN**
* A 3x3 layout with mines at all eight non-centre cells `[["*","*","*"], ["*",".","*"], ["*","*","*"]]` is computed

**THEN**
* The hint `Grid` has `at(1,1) == "8"` and all other cells equal `"*"`

**WHEN**
* A layout `Grid` containing a cell value other than `"*"` or `"."` is given

**THEN**
* `InvalidBoardConfig` is raised and no hint `Grid` is returned

---

## BOARD-INFRA-002.1: Packaging — hints module runs via `python -m minesweeper`, stdlib only

**Parent**: BOARD-STORY-002
**Architecture References**:
- [02 §2.1 Technical Constraints — T1, T2, T3](../../architecture/02-constraints.md#21-technical-constraints)
- [02 §2.3 Conventions — C2 type hints, C6 test layout mirrors source](../../architecture/02-constraints.md#23-conventions-and-coding-standards)
- [05 §5.5 Module / Package Layout](../../architecture/05-building-block-view.md#55-module--package-layout)
- [08 §8.5 Testing Strategy](../../architecture/08-cross-cutting-concepts.md#85-testing-strategy)
- [09 ADR-001 Technology Stack](../../architecture/09-architecture-decisions.md#adr-001-technology-stack)

AS A Developer
I WANT `board/hints.py` importable and tested under Python 3.12 with the standard library only
SO THAT hint computation runs with zero third-party installs and its tests pass locally and in CI

### SCENARIO 1: Runnable with stdlib only

**Scenario ID**: BOARD-INFRA-002.1-S1

**GIVEN**
* The repository on a clean POSIX box with Python 3.12 and no third-party packages installed

**WHEN**
* `python -m minesweeper` is started

**THEN**
* `board/hints.py` imports only standard-library modules (e.g. `typing` for hints); it imports nothing from `presentation` and no third-party package

**WHEN**
* `python -m pytest tests/board/test_hints.py` is run

**THEN**
* All tests pass
* No test imports from `minesweeper.presentation` and no test imports a third-party package (only `pytest`, test-time)

### SCENARIO 2: Test layout mirrors source and runs in CI

**Scenario ID**: BOARD-INFRA-002.1-S2

**GIVEN**
* The pre-commit hook and GitHub Actions workflow (Module 4) configured for Python 3.12

**WHEN**
* The hints tests run in CI on Linux

**THEN**
* `tests/board/test_hints.py` mirrors `board/hints.py` (convention C6)
* The tests pass; pre-commit format and trailing-whitespace checks pass on the `board/hints.py` source file

---

## BOARD-INFRA-002.2: Data store — hints are in-memory only; nothing written to disk

**Parent**: BOARD-STORY-002
**Architecture References**:
- [02 §2.1 Technical Constraints — T4 no database, persistence is scores-only](../../architecture/02-constraints.md#21-technical-constraints)
- [08 §8.1 Domain Modeling — Pure core, dependency direction](../../architecture/08-cross-cutting-concepts.md#81-domain-modeling)
- [09 ADR-002 Hexagonal Architecture](../../architecture/09-architecture-decisions.md#adr-002-hexagonal-architecture-ports-and-adapters)

AS A Developer
I WANT `HintComputer.compute` to return an in-memory immutable `Grid` and never touch the file system
SO THAT hint computation stays unit-testable without I/O

### SCENARIO 1: Computation writes nothing to disk

**Scenario ID**: BOARD-INFRA-002.2-S1

**GIVEN**
* A temporary working directory whose file listing is recorded before the call

**WHEN**
* `HintComputer.compute(layout)` runs in that directory

**THEN**
* The returned hint `Grid` is held in memory as an immutable value object
* The set of files in the working directory is unchanged (no file is created or written)

### SCENARIO 2: No file-system imports in the Board context

**Scenario ID**: BOARD-INFRA-002.2-S2

**GIVEN**
* The `board/` package source

**WHEN**
* Its imports are inspected (static import check, per risk R1)

**THEN**
* No module under `board/` (including `hints.py`) imports `pathlib`, `json`, `os`, `sys`, or anything from `presentation` (constraint C7)

---

## BOARD-INFRA-002.3: N/A — hint computation is not a stdin command-cycle transition

**Parent**: BOARD-STORY-002

`HintComputer.compute` is a pure function invoked during setup (CLI-STORY-001) and by `GameEngine` during reveal/flood-fill (GAME-STORY-001 / GAME-STORY-002). It is not driven by a stdin command cycle (stdin line → action → new state → render), so it has no event-handling sub-story; the command cycle that consumes the hints is owned by CLI-STORY-004.

---

## BOARD-INFRA-002.4: Monitoring and observability — domain does not log; invariant violations are reported

**Parent**: BOARD-STORY-002
**Architecture References**:
- [02 §2.4 Operating Environment — E6 exit codes](../../architecture/02-constraints.md#24-operating-environment)
- [08 §8.2 Error Handling — domain invariant raises, CLI translates](../../architecture/08-cross-cutting-concepts.md#82-error-handling)
- [08 §8.4 Logging and Diagnostics — domain does not log](../../architecture/08-cross-cutting-concepts.md#84-logging-and-diagnostics)
- [10 §10.2 Q5 — Robustness](../../architecture/10-quality-requirements.md#q5--robustness)

AS A Developer
I WANT hint computation to stay silent (the domain does not log) and to surface invariant violations cleanly
SO THAT logs stay noise-free and a bad layout never crashes the game

### SCENARIO 1: HintComputer emits no log records

**Scenario ID**: BOARD-INFRA-002.4-S1

**GIVEN**
* A captured log handler and a valid mine-layout `Grid`

**WHEN**
* `HintComputer.compute(layout)` runs

**THEN**
* No log record is emitted by `HintComputer` (the domain does not log, §8.4)
* Nothing is written to stdout by the Board context (stdout is reserved for the rendered board, owned by CLI-STORY-002)

### SCENARIO 2: Invariant violation is reported; fatal errors exit non-zero

**Scenario ID**: BOARD-INFRA-002.4-S2

**GIVEN**
* A non-conforming layout (a cell value other than `"*"` or `"."`) reaches `HintComputer`

**WHEN**
* `HintComputer.compute` raises `InvalidBoardConfig`

**THEN**
* The `GameLoop` catches the exception, logs it to stderr at `WARNING`, prints a short user-facing error message to stdout, and re-prompts
* The game state is unchanged and the loop continues (does not crash)

**WHEN**
* An unexpected exception (not a domain invariant violation) escapes all handlers

**THEN**
* The process exits with a non-zero code (E6)
