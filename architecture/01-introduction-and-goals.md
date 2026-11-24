# 01 — Introduction and Goals

## 1.1 Introduction

This system is an extension of the [Minesweeper kata](https://codingdojo.org/kata/Minesweeper/) into a
playable terminal game.

The **base kata** is a pure transformation: given an N×M field where some cells contain mines
(`*`) and the rest are safe (`.`), compute a *hint field* where every safe cell shows the number
of mines in its eight neighbouring cells (and mines stay `*`).

The **game extension** turns that transformation into an interactive session: the player picks a
board size and a mine count, the board is generated randomly from a seedable source, and the
player then reveals or flags cells. Revealing a 0 flood-fills its neighbours automatically;
revealing a mine loses; revealing every safe cell wins. Optionally, the best (fastest) clear
times per difficulty are persisted in a local JSON file.

The implementation is deliberately small and local: Python 3.12, standard library only, no cloud,
no servers, no database, runs in any terminal.

## 1.2 Requirements Overview

### Functional goals

| #  | Goal | Notes |
|----|------|-------|
| F1 | Compute the hint field from a mine layout using 8-neighbour adjacency. | The base kata, as a pure function. |
| F2 | Generate a board of configurable rows, columns, and mine count from a seedable RNG. | Seed makes generation deterministic and reproducible. |
| F3 | Reveal a cell; reveal mines and non-mines. | Core game action. |
| F4 | Flood-fill: revealing a 0 automatically reveals its neighbours, cascading. | Repeats until the frontier is non-zero. |
| F5 | Flag and unflag cells to mark suspected mines. | Flags do not reveal; flags can be removed. |
| F6 | Win when every non-mine cell is revealed. | Flags on safe cells don't count as revealed. |
| F7 | Lose when a mine is revealed. | Game over, show the full board. |
| F8 | Optionally persist best clear times per difficulty to a local JSON file. | Non-essential; may be disabled. |

### Non-functional goals

| # | Goal | Notes |
|---|------|-------|
| NF1 | Domain logic is pure and deterministic. | RNG seed is injected; no hidden I/O in the core → enables TDD/BDD. |
| NF2 | Standard library only at runtime. | No pip installs to run the game; every external dep needs an ADR. |
| NF3 | Local single-user execution. | No network, no cloud, no server process. |
| NF4 | Clear separation of concerns via hexagonal architecture. | Domain core knows nothing of the CLI or storage. |
| NF5 | Portable across POSIX terminals. | No platform-specific dependencies. |

## 1.3 Quality Goals (top priorities)

The following quality attributes are the ones that most strongly shape the architecture, listed in
priority order:

1. **Testability / Determinism.** The domain (board, hints, rules) must be unit-testable without
   the CLI, the file system, or wall-clock randomness. This is the single most important driver —
   it is what makes the later TDD/BDD modules possible.

2. **Correctness.** Hint counts, flood-fill, and win/lose detection must be exact. The base kata
   rules are the correctness anchor.

3. **Simplicity / Maintainability.** KISS and YAGNI: the smallest design that satisfies the goals.
   No premature extension points, no speculative features.

4. **Portability.** Runs anywhere Python 3.12 runs, with only the standard library.

## 1.4 Stakeholders

| Stakeholder | Interest |
|-------------|----------|
| Player | An unambiguous, responsive terminal game with correct rules and optional best-time tracking. |
| Developer / Maintainer | A small codebase that is easy to read, test, and extend — especially along the bounded contexts. |
| Course evaluators | A coherent arc42 architecture that downstream agents (requirements, TDD/BDD, CI/CD) can build on. |

## 1.5 Glossary pointers

Domain-specific terms (field, hint, reveal, flag, flood-fill, difficulty) are defined consistently
in [Chapter 12 — Glossary](12-glossary.md). The bounded contexts (Board, Game, Presentation)
introduced above are elaborated in Chapters 4 and 5.
