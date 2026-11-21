# 04 — Solution Strategy

This chapter describes the fundamental approach taken to satisfy the goals and constraints from
Chapters 1 and 2. It states the strategy at a conceptual level; concrete building blocks are
detailed in Chapter 5, decisions in Chapter 9, and cross-cutting concerns in Chapter 8.

## 4.1 Strategy Overview

The system is a **single-process, terminal application** built with a **hexagonal (ports and
adapters) structure** over three **bounded contexts**. The domain logic — board generation, hint
computation, and the game rules — lives in a pure core that performs no I/O and holds no
hidden randomness. The terminal interface and the optional JSON score storage are thin adapters
around that core.

```
                        Presentation (adapter)
                               │  CLI I/O
                               ▼
   ┌─────────────────────────────────────────────┐
   │   Board context   │   Game context           │   ← pure domain core
   │  (generate, hints)│  (state, rules, loop)    │      no I/O, no random.*
   └─────────────────────────────────────────────┘
                               ▲
                               │  port: read/write records
                   Storage (adapter)  ← optional, local JSON
```

The arrow directions express the dependency rule: adapters depend on the core; the core depends
on nothing outward. This is the single organizing principle for the whole codebase.

## 4.2 How the Strategy Meets the Quality Goals

| Quality goal (Ch.1) | How the strategy addresses it |
|---------------------|-------------------------------|
| **Testability / Determinism** (1st priority) | The domain core takes an injected `random.Random` seed and has no I/O, so every game scenario is reproducible and unit-testable without the terminal or file system. The CLI and storage adapters are the only side-effecting code, and they are thin. |
| **Correctness** | The base kata is an isolated pure function (hint field from a mine layout). Win/lose and flood-fill are pure state transitions in the Game context. Each rule can be tested exhaustively in isolation. |
| **Simplicity / Maintainability** | Three small contexts, each with a single responsibility. No framework, no abstraction layers beyond what the ports require. YAGNI governs every extension. |
| **Portability** | Standard library only at runtime; the core has no platform assumptions; adapters use only `sys.stdin`/`stdout` and `pathlib`/`json`. |

## 4.3 Bounded Contexts

The system is partitioned into three contexts, each with its own ubiquitous language (Chapter 12)
and its own folder. They communicate only through explicitly defined ports (data passed as plain
value objects), never by reaching into each other's internals.

### Board context
Owns the *mine field* and the *hint field*. Responsibilities: generate a randomized board from an
injected seed, and compute the 8-neighbour hint counts. This is where the base kata lives. It is
entirely pure and stateless beyond the data it returns.

### Game context
Owns the *game state* and the *rules*. Responsibilities: track which cells are revealed/flagged,
apply a reveal (with flood-fill) or a flag toggle, and decide win/lose. It depends on the Board
context for board data but not for I/O. State transitions are pure functions of (state, action) →
state, which keeps them deterministic and testable.

### Presentation context
Owns the *terminal experience*. Responsibilities: render the board to text, read commands, parse
coordinates, and drive the Game context through its port. This is the only place that touches
`sys.stdin`/`sys.stdout`. It owns no game logic.

A *Storage adapter* sits beside Presentation, not as a context but as a port implementation: it
reads and writes best-time records to a local JSON file. The Game (or a thin orchestration layer)
defines the port; the adapter implements it.

## 4.4 Key Strategic Choices

1. **Ports and adapters over layering.** Rather than a layered "UI → logic → data" stack, the core
   exposes ports and adapters plug into them. This is what lets the domain be tested in complete
   isolation (goal NF1) and keeps I/O substitutable.

2. **Determinism by construction, not by configuration.** Randomness is never implicit. The
   domain receives a `random.Random` instance (seeded by the caller); tests pass a fixed seed.
   There is no module-level `random.*` use in the core (constraint T6).

3. **Value objects at the boundaries.** Contexts exchange small, immutable data structures (e.g.
   a `Grid`, a `Cell`, a game `State`) rather than sharing mutable objects. This keeps the pure
   core free of aliasing surprises and makes state transitions trivial to assert on.

4. **Standard library first.** No runtime dependency is added without an ADR (constraint T2).
   `pytest` is the only external package and is quarantined to tests (constraint T3).

5. **Optional persistence as a removable adapter.** Score storage is an adapter behind a port;
   the game runs normally when it is absent or the JSON file is malformed (interface I3). This
   respects YAGNI — the feature is F8, the lowest-priority functional goal.

## 4.5 Top-Level Component Decomposition (preview)

Chapter 5 expands this into C4 Container and Component diagrams, but the strategy fixes the
shape now:

| Container | Technology | Responsibility |
|-----------|------------|----------------|
| CLI app | Python 3.12 (`python -m minesweeper`) | Entry point; wires adapters to the core; runs the loop. |
| Domain core | Python 3.12 modules (stdlib only) | Board and Game contexts; pure logic. |
| Score store | Local JSON file | Optional best-time records. |

The CLI app is the only executable container; the domain core and the JSON file are not
independently deployable. Chapter 7 makes the single-process deployment explicit.

## 4.6 Risks and Trade-offs of the Strategy

- **More files than a single-file script.** The hexagonal split costs a few extra modules. The
  payoff is testability and the clean contracts that downstream agents need (constraint O2); this
  is an accepted trade-off, tracked in Chapter 11.
- **Ports add a thin indirection.** A local single-user game does not *need* swappable adapters at
  runtime. We keep the ports anyway because their value is testability and clarity, not runtime
  pluggability — and they carry no runtime cost.
- **Discipline required to keep the core pure.** The architecture depends on the domain never
  importing an adapter. This is enforced structurally (folder layout + import rules, constraint
  C7) and by tests, rather than by a tool.

## 4.7 Mapping to Later Chapters

| Topic | Chapter |
|-------|---------|
| Concrete containers and components (C4) | 5 |
| Runtime flows for key scenarios (sequences) | 6 |
| Deployment on a single machine | 7 |
| Error handling, logging, validation, testing | 8 |
| Recorded decisions, incl. the technology stack (ADR-001) | 9 |
| Quality tree and scenarios | 10 |
| Risks and technical debt | 11 |
