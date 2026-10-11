---
description: Add or modify a LangGraph node and wire it into the orchestrator graph
agent: agent
---

Update the orchestrator in the root modules: ${input:change:Describe the node or routing change}

- Extend the state in [state.py](../../state.py) if new keys are needed.
- Implement the node in [nodes.py](../../nodes.py), returning only updated keys.
- Register the node and edges in [graph.py](../../graph.py).
- Verify with `poetry run python -c "from graph import graph"` from the repo root.
