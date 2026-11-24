# Agentic SDLC: Building a Software Factory

In this course I build AI agents for each phase of the software development lifecycle, composing them into a cohesive software factory. Each module delivers a focused agent that automates a specific SDLC activity, from requirements and architecture through CI/CD and test-driven development.

## Course Progress

- [ ] Module 1: Git — workflow agent
- [x] Module 2: Software Architecture — arc42 design agent
- [x] Module 3: Software Requirements — user story derivation agent
- [ ] Module 4: CI/CD — deployment pipeline agent
- [ ] Module 5: TDD/BDD — multi-agent testing system
- [ ] Module 6: Final Project — team software factory

## Architecture

The Minesweeper game is documented as an arc42 architecture, built one chapter at a time. Start
with the [Introduction and Goals](architecture/01-introduction-and-goals.md).

## Requirements

User stories are derived from the architecture by the requirements agent
([.kiro/agents/requirements-agent.json](.kiro/agents/requirements-agent.json)) using DDD and
Pareto prioritization.

Run the agent:

```bash
kiro-cli --tui --agent requirements-agent
```

Input is the arc42 architecture in [architecture/](architecture/) (product description, target
users, and building blocks). Output lands in [docs/user-stories/](docs/user-stories/):

- [README.md](docs/user-stories/README.md) — DDD analysis, ubiquitous language, prioritized story
  list, Pareto progress, and traceability
- `{domain}.md` — one story bundle file per domain (Original + FE + BE + INFRA, GIVEN-WHEN-THEN),
  e.g. [board.md](docs/user-stories/board.md) and [game.md](docs/user-stories/game.md)
