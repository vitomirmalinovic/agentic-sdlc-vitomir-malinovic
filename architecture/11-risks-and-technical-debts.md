# 11 — Risks and Technical Debts

This chapter lists the risks that could undermine the architecture's goals and the technical debts
the design carries, with their origin and a mitigation or payoff plan. Several items trace back
to trade-offs accepted in Chapters 4, 9, and 10.

## 11.1 Risks

Risks are rated by **probability** and **impact** (Low / Medium / High). The numbering is for
reference, not ranking; priority is reflected in the mitigation effort.

| # | Risk | Probability | Impact | Mitigation |
|---|------|-------------|--------|------------|
| R1 | **Core purity erosion.** Someone adds I/O, the wall clock, or module-level `random.*` to `board/` or `game/`, silently breaking determinism and testability — the #1 goal. | Medium | High | Enforce structurally: folder layout + import rule (C7); add a CI/import-linter check that `board`/`game` import nothing from `presentation` and nothing that does I/O; a test asserting no `random.random()`-style calls in the core. |
| R2 | **Determinism fragility from non-deterministic iteration.** Iterating over a `set` or relying on dict order assumptions can make tests flaky across runs. | Medium | Medium | Mandate seeded `random.Random` and insertion-ordered iteration (lists/dicts) in domain code; lint against bare `set` iteration in tests. Python 3.12 dict ordering is stable, but set ordering is not. |
| R3 | **JSON score schema drift / silent data loss.** The hand-maintained record format changes without a version, so old files are misread or silently overwritten. | Medium | Medium | Validate the record shape in `ScoreAdapter` (Ch.8); add a `version` field to the JSON; write a test that loads an old fixture and a malformed file to confirm degradation. |
| R4 | **Downstream-agent contract drift.** The requirements/TDD/CI agents (O2) implement against these contracts; ambiguity lets them diverge from the architecture. | Medium | High | Keep contracts explicit (ports, glossary Ch.12, scenarios Q1/Q2 in Ch.10); one ubiquitous language; review agent output against this document. |
| R5 | **Platform-specific behavior.** Something works on the author's macOS but fails on Linux CI (encoding, terminal assumptions, line endings). | Low | Medium | Plain text only (T7); explicit UTF-8; no terminal-width or cursor assumptions; run CI on Linux. |
| R6 | **Scope creep beyond F1–F8.** Save/resume, solver, colors, multiplayer creep in, violating YAGNI and growing complexity. | Medium | Medium | Change control: every new feature or dependency needs an ADR; out-of-scope list (§3.4) is the gate. |
| R7 | **Timer unfairness.** The wall-clock best-time is skewed by system load or background work, making records uncomparable. | Low | Low | Best-time is optional and casual (F8); document the limitation; never let it affect rules. |
| R8 | **Adapter under-testing.** I/O bugs in `CommandParser`/`Renderer`/`ScoreAdapter` slip through if only the domain is tested. | Medium | Medium | Integration tests for adapters with captured streams and a fake store (Ch.8 pyramid); a few end-to-end `GameLoop` tests. |

### Top risks elaborated

- **R1 (core purity erosion)** is the single most important risk because the entire testability
  strategy — and the downstream TDD/BDD plan — rests on a pure core. It is mitigated by *structure
  plus automation*, not by goodwill: the folder layout makes the dependency direction visible, and
  an import check plus a domain test make a violation fail loudly.
- **R4 (contract drift)** matters because this architecture is a handoff artifact. Its mitigation
  is documentation discipline: the glossary and the Q1/Q2 scenarios are the contract, and they are
  kept consistent across chapters rather than restated differently each time.

## 11.2 Technical Debts

Debts are either *deliberate* (a conscious trade-off) or *incidental* (something to clean up
later). Each carries the reason it was accepted and a payoff plan.

| # | Debt | Type | Origin / Rationale | Payoff plan |
|---|------|------|---------------------|-------------|
| D1 | **Ports without runtime pluggability.** The hexagonal ports exist for testability, not because adapters are swapped at runtime. | Deliberate | Ch.4 trade-off; ADR-002. | Keep; the cost is negligible indirection, the value is testability. Revisit only if a second UI or store is genuinely needed. |
| D2 | **Hand-rolled interactive command parsing.** The REPL command protocol is parsed by hand, not by a library. | Deliberate | `argparse` suits CLI flags, not a line-based game REPL; stdlib-only. | Keep for the small fixed verb set; if the command grammar grows, introduce a tiny parser table. No third-party CLI lib (ADR-001). |
| D3 | **Manual JSON record schema.** No schema library validates the scores file. | Deliberate / risk-linked | stdlib-only; tiny data (ADR-001, R3). | Add a `version` field and a validation function in `ScoreAdapter` with fixture tests; revisit only if records grow. |
| D4 | **Full-board redraw each turn.** The board is reprinted in full rather than diff-updated. | Deliberate | Plain-text, no curses (ADR-007); simplest portable option. | Keep at supported board sizes; only worth changing if large boards become a goal (they are out of scope, §3.4). |
| D5 | **Immutable `GameState` reallocated per action.** Every transition allocates a new state object. | Deliberate | Determinism and clarity (ADR-004). | Keep; the cost is negligible at these board sizes. Revisit only if very large boards appear. |
| D6 | **No save/resume.** A crashed or quit game cannot be continued. | Deliberate out-of-scope | §3.4; a casual terminal game. | Leave out unless a stakeholder asks; adding it would need an ADR and a persistence design. |
| D7 | **Single-user/single-process assumption baked in.** Multi-user or remote play would require a rewrite, not an extension. | Deliberate | ADR-005; matches all current goals. | Document clearly; do not let code quietly grow remote assumptions. If needed, a new ADR supersedes ADR-005. |
| D8 | **Difficulty presets live in Presentation.** "Difficulty" maps to numbers in Presentation; the domain knows only numbers. | Deliberate | The domain stays free of presentation concepts. | Acceptable while difficulty is just a preset lookup; if difficulty rules become logic, move them behind a port. |

## 11.3 Net Assessment

The architecture carries mostly *deliberate*, low-cost debts that are direct consequences of the
simplicity and stdlib-only goals — none of them block the quality goals. The one risk that would
be expensive if it materializes (R1, purity erosion) is cheap to automate against, and that
automation is the recommended first CI check. No debt here requires action before the downstream
agents can begin; they are the ones who will both benefit from and help enforce these rules.
