# Agentic SDLC: Building a Software Factory

In this course I build AI agents for each phase of the software development lifecycle, composing them into a cohesive software factory. Each module delivers a focused agent that automates a specific SDLC activity, from requirements and architecture through CI/CD and test-driven development.

## Course Progress

- [x] Module 1: Git — workflow agent
- [x] Module 2: Software Architecture — arc42 design agent
- [x] Module 3: Software Requirements — user story derivation agent
- [x] Module 4: CI/CD — deployment pipeline agent
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

## CI/CD

The CI/CD agent ([.kiro/agents/cicd-agent.json](.kiro/agents/cicd-agent.json)) generates the
[Dockerfile](Dockerfile) and the GitHub Actions workflow
[.github/workflows/ci.yml](.github/workflows/ci.yml). Every push to `main`, `feature/**` or
`fix/**` and every PR to `main` that touches `minesweeper/`, `tests/`, `Dockerfile`,
`requirements.txt` or the workflow builds the image and runs pytest inside it. There is no cloud
deployment (local single-user game, see [Deployment View](architecture/07-deployment-view.md)).

```bash
kiro-cli --tui --agent cicd-agent
docker build -t kata-tests .     # build the test image
docker run --rm kata-tests       # run the tests in the container
```

The `docker-test` pre-commit hook ([scripts/hooks/docker-test.sh](scripts/hooks/docker-test.sh))
runs the same build and tests before each commit, and skips with a warning when Docker is not
installed.
