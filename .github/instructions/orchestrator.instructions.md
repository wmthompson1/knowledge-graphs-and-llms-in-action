---
applyTo: "{state,nodes,graph,main}.py"
---

- Use LangGraph 1.0 APIs (`StateGraph`, `START`, `END`).
- State is a `TypedDict` in `state.py`; nodes return partial dicts.
- Retry logic lives in conditional edges in `graph.py`, not inside nodes.
