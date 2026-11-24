# 10 — Quality Requirements

This chapter presents the quality tree and concrete scenarios. The priorities are inherited
from [Chapter 1, §1.3](01-introduction-and-goals.md); this chapter makes them measurable.

## 10.1 Quality Tree

```
Minesweeper quality
├── Testability / Determinism   (priority 1 — top driver)
│   ├── Domain unit-testable without I/O
│   ├── Reproducible runs (seeded RNG)
│   └── BDD-ready pure state transitions
├── Correctness                 (priority 2)
│   ├── Hint computation exact (the kata)
│   ├── Flood-fill correct
│   └── Win/lose detection exact
├── Simplicity / Maintainability (priority 3)
│   ├── Small modules, single responsibility
│   ├── No speculative features (YAGNI)
│   └── Readable by a single maintainer / downstream agent
├── Portability                  (priority 4)
│   ├── Runs on any POSIX system with Python 3.12
│   └── Standard library only, no platform-specific deps
├── Robustness
│   ├── Graceful degradation on bad input
│   └── Graceful degradation on bad/missing score file
└── Usability
    ├── Responsive single-player session
    └── Clear, unambiguous prompts and messages
```

Performance is intentionally **not** a top node: a turn-based terminal game for a single human has
no meaningful performance pressure at the board sizes involved. It is noted only as a backstop
scenario in §10.2.

## 10.2 Concrete Scenarios

Each scenario uses the standard form: **Source** → **Stimulus** on **Artifact** under
**Environment**, producing a **Response** measured by **Measure**.

### Q1 — Testability / Determinism (priority 1)

**Scenario Q1.1 — domain tested without I/O**
- **Source:** Developer / automated test (`pytest`)
- **Stimulus:** Run the domain test suite (`tests/board`, `tests/game`)
- **Artifact:** Domain Core (`board/`, `game/`)
- **Environment:** CI or local, no terminal, no file system
- **Response:** Tests exercise generation, hints, reveal, flood-fill, win/lose
- **Measure:** 100% of domain tests pass; none import from `presentation`, none touch
  `stdin`/`stdout`/files; no test reads the wall clock or uses module-level randomness.

**Scenario Q1.2 — reproducible board**
- **Source:** Developer
- **Stimulus:** Generate two boards with identical `(rows, cols, mines, seed)`
- **Artifact:** `BoardGenerator`
- **Environment:** Any machine
- **Response:** Two identical mine layouts
- **Measure:** Byte-identical `Grid` output for the same seed, always.

**Scenario Q1.3 — BDD-ready transition**
- **Source:** BDD module / test
- **Stimulus:** Given a known `GameState`, apply an action, assert the next state
- **Artifact:** `GameEngine.apply`
- **Environment:** Unit test, pure
- **Response:** Returns the exact next `GameState`
- **Measure:** The transition is a pure function — same inputs ⇒ same output, with no observable
  side effects; expressible directly as Given/When/Then.

### Q2 — Correctness (priority 2)

**Scenario Q2.1 — exact hint field**
- **Source:** Test
- **Stimulus:** Provide a known mine layout
- **Artifact:** `HintComputer`
- **Environment:** Unit test
- **Response:** Produce the hint field
- **Measure:** Every safe cell shows the exact count of mines in its 8 neighbours; every mine stays
  `*`. Verified against the published kata examples.

**Scenario Q2.2 — correct flood-fill**
- **Source:** Test
- **Stimulus:** Reveal a cell whose hint count is 0
- **Artifact:** `GameEngine` flood-fill
- **Environment:** Unit test
- **Response:** Reveal the cell and cascade to neighbours
- **Measure:** The cascade stops exactly at cells with count > 0; no mine is revealed by
  flood-fill; no cell outside the connected zero-region is revealed.

**Scenario Q2.3 — exact win/lose**
- **Source:** Test
- **Stimulus:** Reveal the last safe cell; separately, reveal a mine
- **Artifact:** `GameEngine` status detection
- **Environment:** Unit test
- **Response:** Set status `won` / `lost`
- **Measure:** Win iff every non-mine cell is revealed (flags on safe cells do not count as
  revealed); lose iff any mine is revealed. No false win, no false loss.

### Q3 — Simplicity / Maintainability (priority 3)

**Scenario Q3.1 — readable by a maintainer**
- **Source:** New maintainer / downstream agent
- **Stimulus:** Read a single context module to make a change
- **Artifact:** Any module in `board/`, `game/`, or `presentation/`
- **Environment:** Source only
- **Response:** Understand the module's responsibility
- **Measure:** Each module has one responsibility, public functions carry type hints and
  docstrings, and the module imports nothing outside its allowed dependencies (C7). No module
  exceeds a small, agreed size threshold (e.g. ~150 lines).

**Scenario Q3.2 — no speculative features**
- **Source:** Architecture review
- **Stimulus:** Audit the codebase for unused abstraction
- **Artifact:** Whole system
- **Environment:** Source
- **Response:** Only the goals F1–F8 and the cross-cutting concepts are implemented
- **Measure:** No extension points, plugins, or configurability exist that no scenario in
  Chapters 1 or 6 requires.

### Q4 — Portability (priority 4)

**Scenario Q4.1 — runs on a clean POSIX box**
- **Source:** Evaluator
- **Stimulus:** Clone the repo and run `python -m minesweeper` on Linux and on macOS
- **Artifact:** Whole system
- **Environment:** Clean Python 3.12, no pip install
- **Response:** The game starts and is playable
- **Measure:** Starts with zero third-party imports; behavior identical across both platforms;
  no curses/ANSI/platform calls.

### Q5 — Robustness

**Scenario Q5.1 — bad input never crashes**
- **Source:** Player
- **Stimulus:** Type a malformed command or out-of-range coordinate
- **Artifact:** `CommandParser` / `GameLoop`
- **Environment:** Live terminal session
- **Response:** Show a short error message and re-prompt
- **Measure:** The game does not crash or exit; the state is unchanged; the loop continues.

**Scenario Q5.2 — bad score file degrades**
- **Source:** File system
- **Stimulus:** The scores JSON is missing, unreadable, or malformed
- **Artifact:** `ScoreAdapter`
- **Environment:** Game start or win
- **Response:** Treat as "no records"; continue without persistence
- **Measure:** No exception escapes to the game loop; the game is fully playable; a later win may
  write a fresh valid file.

### Q6 — Usability

**Scenario Q6.1 — responsive session**
- **Source:** Player
- **Stimulus:** Enter a command
- **Artifact:** `GameLoop`
- **Environment:** Interactive terminal
- **Response:** Render the updated board and prompt
- **Measure:** The re-render is perceptually instantaneous (well under 100 ms) at any supported
  board size; no waiting state is shown to a human.

### Backstop — Performance

**Scenario P1 — large supported board**
- **Source:** Test
- **Stimulus:** Generate and fully flood-reveal a large board (e.g. 30×30, ~150 mines)
- **Artifact:** `BoardGenerator`, `HintComputer`, `GameEngine`
- **Environment:** Unit/benchmark test
- **Response:** Complete generation and a full reveal cascade
- **Measure:** Completes in well under 1 second on a typical machine. Not a design driver —
  recorded only to confirm the backstop holds.

## 10.3 Priority Summary

| Priority | Attribute | Anchored by |
|----------|-----------|-------------|
| 1 | Testability / Determinism | Q1.1, Q1.2, Q1.3 — enforced structurally (Ch.5, Ch.8) |
| 2 | Correctness | Q2.1, Q2.2, Q2.3 — the kata rules |
| 3 | Simplicity / Maintainability | Q3.1, Q3.2 — KISS/YAGNI |
| 4 | Portability | Q4.1 — stdlib-only, POSIX |
| — | Robustness | Q5.1, Q5.2 — graceful degradation |
| — | Usability | Q6.1 — responsiveness |
| backstop | Performance | P1 — non-driver |

The scenarios in Q1 and Q2 are the contract the downstream TDD/BDD agents will implement
against; the others guard the non-functional goals without over-constraining the design.
