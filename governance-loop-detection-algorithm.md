# Governance Loop Detection Algorithm

## Purpose

This algorithm detects when an orchestrator is entering a governance loop instead of making diagnostic or operational progress. It flags repeated state transitions that generate artifacts without introducing a new empirical fact.

## Core idea

A loop is considered governance-driven when all of the following are true:

- the same blocked state is revisited,
- no new probe or fact is introduced,
- the system emits governance output (log, memo, review, status update),
- the state does not change in a materially informative way.

## Inputs

The algorithm consumes a state history of agent turns:

- `turn_index`
- `node_name`
- `state_snapshot`
- `facts_added` (new probes, files, logs, API responses)
- `artifacts_emitted` (memos, docs, statuses, tickets)
- `status`
- `timestamp`

## Pseudocode

```python
from collections import defaultdict


def detect_governance_loop(history, max_same_blocked_turns=3, min_artifact_count=2):
    """Return a list of suspected governance loops."""
    blocked_signatures = defaultdict(list)
    alerts = []

    for event in history:
        state = event["state_snapshot"]
        if state.get("blocked") is not True:
            continue

        signature = (
            state.get("root_cause_hint"),
            state.get("target_resource"),
            state.get("agent_role"),
            state.get("active_task_id"),
        )
        blocked_signatures[signature].append(event)

    for signature, events in blocked_signatures.items():
        fact_count = 0
        artifact_count = 0
        same_state_repeats = 0

        previous_summary = None
        for event in events:
            fact_count += len(event.get("facts_added", []))
            artifact_count += len(event.get("artifacts_emitted", []))

            summary = event["state_snapshot"].get("blocking_summary")
            if summary == previous_summary:
                same_state_repeats += 1
            previous_summary = summary

        if same_state_repeats >= max_same_blocked_turns and artifact_count >= min_artifact_count:
            if fact_count == 0:
                alerts.append({
                    "signature": signature,
                    "reason": "blocked state revisited with artifacts but no new empirical fact",
                    "turns": len(events),
                })

    return alerts
```

## Detection conditions

Flag a loop when at least one of the following holds:

- repeated blocked state with same summary for N turns,
- governance artifacts emitted but no new probe results,
- no delta in the evidence set across review rounds,
- state transitions are `blocked -> report -> blocked` without new facts,
- review count exceeds a configured maximum for a single unresolved root cause.

## Severity scoring

```python

def score_governance_loop(alert):
    score = 0
    score += min(alert["turns"], 5) * 10
    score += 20 if alert["reason"].find("no new empirical fact") >= 0 else 0
    return score
```

## Example alert

```json
{
  "signature": ["database-init", "manufacturing.db", "architecture-reviewer", "task-1044"],
  "reason": "blocked state revisited with artifacts but no new empirical fact",
  "turns": 5,
  "severity": 70
}
```

## Recommended runtime action

When this alert fires, the orchestrator should:

1. freeze further governance-only artifacts,
2. require a Tier-1 probe or a human approval override,
3. reset the review gate to a bounded evidence check,
4. record the detected loop for telemetry and root-cause analysis.

## Operational note

This detector should not block legitimate human review. It only triggers when the system is re-iterating the same blocked condition without progress-producing evidence.
