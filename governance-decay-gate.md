# Governance Decay Gate

## Purpose

The governance decay gate prevents a review process from repeatedly re-opening the same issue without adding new evidence. It enforces a bounded review lifecycle and prevents indefinite approval churn.

## Review lifecycle

- Pass 1: Review the original plan and failure state.
- Pass 2: Review only the delta since the last attempt.
- Pass 3: Force a decision: approve, reject, or escalate to operator review.
- Further passes are illegal without new empirical fact.

## Pseudocode

```python

def governance_decay_gate(governance_passes: int, new_fact_count: int, force_human: bool = False):
    if force_human:
        return "ESCALATE_TO_HUMAN"

    if governance_passes >= 3 and new_fact_count == 0:
        return "HARD_FAIL"

    if governance_passes >= 2 and new_fact_count == 0:
        return "REVIEW_ONLY_DELTA"

    return "CONTINUE"
```

## Conceptual rule

Once a governance system has consumed its finite review budget, it must either:

- approve,
- reject,
- or escalate to explicit human intervention.

No additional “status update” without new evidence is permitted.

## Why it matters

This gate interrupts the agentic bureaucracy loop by preventing review cycles from becoming a substitute for action. The system can still be audited, but it cannot endlessly defer the decision under a governance narrative.
