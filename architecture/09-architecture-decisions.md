# 09 — Architecture Decisions

This chapter records the significant decisions and their rationale. Each ADR follows the
Status / Context / Decision / Rationale / Consequences format. Constraints from Chapter 2 are
not repeated as decisions unless a real choice among alternatives was made.

---

### ADR-001: Technology Stack
- **Status:** Accepted
- **Context:** The system must implement the Minesweeper kata as a local, playable terminal game.
  The course standardizes on Python; the top quality goal is testability/determinism; the runtime
  must be local with no cloud and no servers (T4).
- **Decision:**
  - **Language/runtime:** Python 3.12.
  - **Runtime dependencies:** standard library only — `random`, `json`, `pathlib`, `logging`,
    `sys`. No third-party packages may be imported by the game.
  - **Test tooling:** `pytest`, test-time only; never imported by the game (T3).
  - **Data storage:** a local JSON file for optional best-time records.
  - **Entry point:** `python -m minesweeper`.
- **Rationale:** The standard library covers every need (RNG, JSON, paths, logging, stdin/stdout),
  so stdlib-only gives zero-install portability and no supply-chain exposure. `pytest` is the de
  facto Python test tool; quarantining it to tests keeps the runtime pure. JSON is human-readable
  and more than sufficient for a handful of best-time records. Alternatives rejected: a non-Python
  stack (course requires Python); third-party libs such as `rich`/`click` (would violate the
  stdlib-only rule and each would need its own ADR); SQLite (overkill and conflicts with the no-DB
  constraint T4); `pickle` for scores (not human-readable and a deserialization risk).
- **Consequences:**
  - *Positive:* zero runtime installs, fully portable, trivial to run and test.
  - *Negative:* no fancy UI primitives, manual argument parsing, no ORM — the JSON record schema
    must be maintained by hand.

---

### ADR-002: Hexagonal Architecture (Ports and Adapters)
- **Status:** Accepted
- **Context:** The highest-priority quality goal is testability/determinism, which requires the
  domain logic to be exercisable without the terminal, the file system, or wall-clock randomness.
  Downstream agents also need clear contracts to build against (O2).
- **Decision:** Organize the code as hexagonal architecture. The domain core (Board, Game
  contexts) performs no I/O and exposes ports; the CLI and the score storage are adapters that plug
  into those ports. The dependency rule is one-way: adapters depend on the core, never the reverse
  (C7).
- **Rationale:** Isolating pure logic makes it unit-testable in complete isolation and gives
  downstream agents explicit seams. Alternatives rejected: classic layering (UI → logic → data),
  which couples logic to data access and is harder to test in isolation; a single-file script,
  which is simplest but untestable and offers no seams for agents.
- **Consequences:**
  - *Positive:* the domain is fully unit-testable without I/O; adapters are substitutable with
    fakes; contracts are explicit.
  - *Negative:* more modules/files than a script; a thin port indirection that has no runtime
    benefit in a single-user game (kept for testability, not pluggability); ongoing discipline to
    keep the core pure, enforced structurally and by tests.

---

### ADR-003: Bounded Contexts (Board, Game, Presentation)
- **Status:** Accepted
- **Context:** The domain has two genuinely distinct concerns — the pure kata transformation
  (board generation + hint counts) and the stateful game rules (reveal/flag/flood-fill/win-lose) —
  plus a terminal interaction concern. A coherent DDD decomposition is needed.
- **Decision:** Three bounded contexts: **Board** (generation, hints), **Game** (state, rules,
  transitions), **Presentation** (CLI). Score storage is an adapter, not a context. Each context
  owns its ubiquitous language (Chapter 12) and its own folder. `Grid` is a shared value object
  at the Board/Game seam.
- **Rationale:** The kata transformation is reusable and testable in isolation; the game rules are
  stateful and operate over board data; the terminal is pure I/O. The split mirrors the real
  responsibilities and lets later BDD target each context. Alternatives rejected: one
  "Minesweeper" context (loses the testable seams and mixes pure and stateful logic); splitting
  Board into separate "Generation" and "Hints" contexts (too fine-grained; they share `Grid` and
  belong together).
- **Consequences:**
  - *Positive:* clear responsibilities; each context testable independently; a natural target for
    BDD scenarios.
  - *Negative:* one value object (`Grid`) spans two contexts; kept manageable by making it
    immutable so the sharing is safe.

---

### ADR-004: Deterministic Domain via Injected Seed and Immutable Transitions
- **Status:** Accepted
- **Context:** Tests must be reproducible. Hidden randomness, wall-clock dependence, or mutable
  state would make tests flaky and block the TDD/BDD modules.
- **Decision:** All randomness flows from an injected `random.Random` instance seeded by the
  caller; the core never uses module-level `random.*` (T6). `GameState` is immutable and
  `GameEngine.apply(state, action) → state` is a pure function. The wall-clock timer lives only in
  the Presentation adapter.
- **Rationale:** Reproducible boards and transitions yield deterministic unit tests, and the pure
  `(state, action) → state` shape maps directly onto BDD Given/When/Then. Alternatives rejected:
  monkeypatching the `random` module in tests (fragile and couples tests to implementation);
  mutable in-place state transitions (untestable and error-prone).
- **Consequences:**
  - *Positive:* fully deterministic tests; BDD-ready seams; no flakiness from the clock or RNG.
  - *Negative:* the caller must supply a seed (minor ceremony); immutability allocates new state
    objects per action, which is negligible at board sizes here.

---

### ADR-005: Single-Process, Single-User, Local Deployment
- **Status:** Accepted
- **Context:** The game is single-user and turn-based, with no online or multi-user requirement
  (T4, T8). Simplicity is a top quality goal.
- **Decision:** Run as one Python process, single-threaded, with no network port, no server, and no
  database. The Domain Core is loaded in-process with the CLI, not as a separate process.
- **Rationale:** Concurrency and distribution add no value for a turn-based single-user game and
  would import deployment complexity for nothing. This matches constraints T4/T8 and the
  simplicity goal. Alternatives rejected: a client-server split (overkill, needs deployment); a
  separate core process with IPC (complexity with no benefit); threads or async (no benefit, adds
  risk).
- **Consequences:**
  - *Positive:* the simplest possible deployment — one command, no infrastructure.
  - *Negative:* not scalable (irrelevant here); no remote or multi-player play (explicitly out of
    scope, §3.4).

---

### ADR-006: Optional Local JSON Score Persistence with Graceful Degradation
- **Status:** Accepted
- **Context:** F8 asks for optional best-time tracking per difficulty. It is the lowest-priority
  functional goal, so it must never compromise the core game and should be removable.
- **Decision:** Persist best times to a local JSON file behind a storage port; `ScoreAdapter`
  implements it. A missing, unreadable, or malformed file degrades to "no records" rather than
  raising (I3). The feature is fully optional — removing the adapter disables F8 without affecting
  any rule.
- **Rationale:** JSON is human-readable and handled by the stdlib; the data volume is tiny.
  Graceful degradation keeps F8 genuinely optional. Alternatives rejected: SQLite (conflicts with
  the no-DB constraint T4 and is overkill); in-memory-only (loses F8 across sessions); always-on
  with a hard failure on a bad file (poor UX for a casual game).
- **Consequences:**
  - *Positive:* optional, removable, no crash on bad data; the domain stays unaware of storage.
  - *Negative:* the JSON record schema is hand-maintained; records are not portable across
    machines (out of scope).

---

### ADR-007: Plain-Text Terminal Rendering (No curses)
- **Status:** Accepted
- **Context:** The game must render in a terminal portably across POSIX systems (T7, E1). `curses`
  is in the standard library but is platform-specific and heavyweight for a grid.
- **Decision:** Render the board as plain text to `sys.stdout` only — no `curses`, no ANSI escape
  libraries, no colors. Each turn reprints the grid as text lines.
- **Rationale:** Plain text maximizes portability across plain POSIX terminals, has no
  platform-specific risk, and is the simplest possible rendering. Alternatives rejected: `curses`
  (stdlib but non-portable and overkill for a static grid); `rich`/`colorama` (third-party,
  violates the stdlib-only rule); raw ANSI escapes (fragile across terminals, conflicts with T7).
- **Consequences:**
  - *Positive:* dependency-free, portable, simple; works in any terminal.
  - *Negative:* no colors, cursor control, or mouse input; the board is fully redrawn each turn,
    which is fine at the small board sizes involved.
