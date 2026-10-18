# Runtime Watchdog for Infinite Agentic Loops

## Purpose

The runtime watchdog detects when a workflow spins on the same blocked condition without introducing new facts or state-changing progress. It can interrupt the orchestrator before the loop becomes operationally expensive or unrecoverable.

## Detection policy

A loop is flagged when any of the following occur:

- same blocked summary repeated for N cycles,
- same task ID re-enters the same node without new facts,
- same tool or probe is retried with identical arguments,
- governance artifacts increase while fact count remains flat,
- node transitions continue without a meaningful state delta.

## Example runtime watchdog

```python

def runtime_watchdog(history, max_repetitions=3):
    recent = history[-max_repetitions:]
    summaries = [item.get("summary") for item in recent if item.get("summary")]
    facts = [item.get("facts") for item in recent]
    total_fact_count = sum(len(f) for f in facts if isinstance(f, list))

    if len(set(summaries)) == 1 and total_fact_count == 0:
        return {
            "alert": "infinite_agentic_loop_detected",
            "reason": "same blocked summary repeated without new empirical facts",
            "repetitions": len(recent),
        }

    return {"alert": None}
```

## Guardrail behavior

When triggered, the watchdog should:

1. pause the agent graph,
2. emit a structured alert,
3. require a Tier-1 probe or human override,
4. record the loop signature for postmortem analysis.

## Recommended enforcement

```python

def enforce_watchdog(history):
    alert = runtime_watchdog(history)
    if alert["alert"]:
        raise RuntimeError(alert["reason"])
```

## Operational goal

The watchdog is not a general-purpose kill switch. It exists to protect the orchestrator from becoming a documentation machine: a system that keeps repeating a blocked status while manufacturing governance metadata instead of collecting evidence.
