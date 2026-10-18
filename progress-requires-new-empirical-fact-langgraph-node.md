# LangGraph Node: "Progress Requires New Empirical Fact"

## Purpose

This node enforces a core invariant in the orchestrator:

> A task may not transition to a new status or report progress unless it introduces a new empirical fact or a concrete hypothesis test.

This prevents the governance loop where the system emits status notes, review summaries, and re-approval requests without changing the underlying diagnosis.

## State contract

```python
from typing import Any, Dict, List, Optional
from typing_extensions import TypedDict


class OrchestratorState(TypedDict, total=False):
    task_id: str
    status: str
    blocked: bool
    summary: str
    facts: List[Dict[str, Any]]
    artifacts: List[str]
    governance_passes: int
    last_fact_hash: Optional[str]
    root_cause_hint: Optional[str]
    human_override: bool
```

## Node logic

```python
import hashlib
import json


def progress_requires_new_empirical_fact(state: dict) -> dict:
    """Reject progress claims that are not grounded in new evidence."""
    facts = state.get("facts", [])
    artifacts = state.get("artifacts", [])
    status = state.get("status")
    blocked = state.get("blocked", False)

    if not facts:
        if blocked and artifacts:
            return {
                "status": "BLOCKED_EVIDENCE_GAP",
                "summary": "Progress halted: new empirical fact required before status update.",
                "governance_passes": state.get("governance_passes", 0) + 1,
            }

    current_fact_hash = hashlib.sha256(
        json.dumps(facts, sort_keys=True).encode("utf-8")
    ).hexdigest()

    if state.get("last_fact_hash") == current_fact_hash and status in {"BLOCKED", "PAUSED"}:
        return {
            "status": "BLOCKED_EVIDENCE_GAP",
            "summary": "No new empirical fact was introduced; governance-only narration is not progress.",
            "governance_passes": state.get("governance_passes", 0) + 1,
        }

    return {
        "status": status or "ACTIVE",
        "last_fact_hash": current_fact_hash,
    }
```

## LangGraph routing behavior

This node should sit immediately after any node that may create a review artifact, audit note, or task update.

```python
from langgraph.graph import END, START, StateGraph


def route_progress_gate(state: dict) -> str:
    if state.get("status") == "BLOCKED_EVIDENCE_GAP":
        return "human_review"
    return "continue"
```

## Enforcement policy

The policy is:

- governance artifacts alone do not count as evidence,
- a fresh probe, file read, log result, or API response does count,
- repeated blocked status without new evidence triggers a hard stop,
- the only legal escape is a new fact or operator override.

## Why it matters

This node blocks the central failure mode: the orchestrator captures the same state, writes a more polished summary, and re-enters the loop. The invariant makes the agent prove each forward motion with a new empirical fact or a direct human decision.
