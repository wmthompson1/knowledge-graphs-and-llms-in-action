# Workspace instructions

This repository (`knowledge-graphs-and-llms-in-action`) hosts book chapters (`chapters/`), data (`data/`, `kb/`, `ontology/`), and utilities (`Utilities/`, `util/`, `replit_integrations/`). Paths below are relative to the repository root.

## LangGraph orchestrator (repo root modules)
- `state.py`: `TypedDict` state schema.
- `nodes.py`: node functions; return only the state keys they update.
- `graph.py`: `StateGraph` with conditional retry routing; exports compiled `graph`.
- `main.py`: FastAPI app exposing `POST /orchestrate`.
- Dependencies are managed by the root `pyproject.toml` (Poetry). Run from the repo root: `poetry run uvicorn main:app --reload`.
- Work in place on the root files above; do not create new subdirectories, project roots, or scaffold folders (e.g. `app/`, `src/`) unless explicitly requested. Keep the existing `pyproject.toml`/virtual environments; do not init new ones.
- Do not modify chapter code under `chapters/` when working on the orchestrator.
