# 02 — Constraints

This chapter lists the technical, organizational, and environmental boundaries that the
architecture *must* respect. Constraints differ from decisions (Chapter 9): they are imposed
from outside and are not negotiable within this project.

## 2.1 Technical Constraints

| #  | Constraint | Rationale / Origin |
|----|------------|--------------------|
| T1 | **Python 3.12 only.** No features requiring 3.13+. | Course toolchain standard; guarantees a single runtime. |
| T2 | **Standard library only at runtime.** No third-party packages may be imported by the game. | Explicit goal NF2; avoids pip installs and supply-chain risk. |
| T3 | **`pytest` is the sole external dependency, test-time only.** It must not appear in any import path used by the game itself. | Testing requirement; quarantined to tests and CI. |
| T4 | **No network, no cloud, no servers, no database.** All persistence is local file I/O. | Goal NF3; the game is single-user and offline. |
| T5 | **Persistence is a local JSON file**, read/written through `pathlib` and `json`. No other formats. | Simplicity and human-readability; matches the context diagram. |
| T6 | **Deterministic domain logic.** Any randomness must come from an injected, seedable source (`random.Random` instance). The domain must never call the module-level `random.*`. | Goal NF1; enables TDD/BDD and reproducible runs. |
| T7 | **Terminal output via `sys.stdout`/`print` only.** No curses, no `rich`, no ANSI libraries. | Keeps portability across plain POSIX terminals. |
| T8 | **Single-process, single-threaded.** No async, no threading, no subprocesses. | The game is turn-based; concurrency adds no value. |

## 2.2 Organizational Constraints

| #  | Constraint | Rationale / Origin |
|----|------------|--------------------|
| O1 | **Sole maintainer / student author.** No team structure, code review, or ownership boundaries to design for. | Course context. |
| O2 | **Built by specialized downstream agents** (requirements, TDD/BDD, CI/CD) after the architecture is approved. The architecture must give those agents clear contracts to work against. | Drives the need for explicit ports and module boundaries. |
| O3 | **No git operations performed by this agent.** Version control is handled by a separate git-agent. | Division of labor; this agent only writes files. |
| O4 | **arc42 + C4 deliverable.** Architecture is expressed in the 12-chapter arc42 template with C4 diagrams. | Course evaluation criterion. |

## 2.3 Conventions and Coding Standards

| #  | Convention | Notes |
|----|------------|-------|
| C1 | Follow **PEP 8**; use 4-space indentation. | Python community default. |
| C2 | **Type hints on all public functions and methods.** | Aids readability and downstream agent work; no runtime type-checking dependency is allowed. |
| C3 | Module, class, and function names use **snake_case** for functions/variables, **PascalCase** for classes. Constants are `UPPER_SNAKE`. | Python convention. |
| C4 | **Ubiquitous language** (see Chapter 12) is used consistently in code identifiers and docstrings. | Domain-Driven Design alignment. |
| C5 | Docstrings on public modules, classes, and functions; inline comments only where non-obvious. | Maintainability without noise. |
| C6 | **Test layout mirrors source layout.** A module `board/grid.py` is tested by `tests/board/test_grid.py`. | Convention required by downstream TDD agents. |
| C7 | **Pure domain modules import nothing from the Presentation or storage adapters.** Enforced structurally (see Chapter 4/5). | Hexagonal architecture rule. |

## 2.4 Operating Environment

| #  | Aspect | Value |
|----|--------|-------|
| E1 | Platform | Any POSIX system with Python 3.12 (Linux, macOS). Windows is best-effort, not a target. |
| E2 | Runtime invocation | `python -m minesweeper` (or equivalent entry point) in a terminal. No GUI, no browser. |
| E3 | Input | Keyboard via `sys.stdin` (single-line commands: reveal/flag coordinates, restart, quit). |
| E4 | Output | Plain text grid + prompts to `sys.stdout`. No colors, no mouse. |
| E5 | File system access | A single JSON file for scores, default under the user's config/data directory; absent or malformed file must degrade gracefully. |
| E6 | Exit | Clean exit codes: `0` on normal quit/win, non-zero only on unexpected errors. |

## 2.5 Relevant laws, standards, and regulations

None apply in a regulatory sense. The project is a local, non-distributed educational game with
no personal data processing, no networking, and no distribution beyond the author's machine.
Licensing is out of scope for this architecture; the repository's own license file governs it.
