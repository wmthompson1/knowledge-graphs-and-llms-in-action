import hashlib
import json
import os
import subprocess
from typing import Any, Dict
from langgraph.types import interrupt
from state import OrchestratorState

# --- Tier-1 Diagnostic Probes (Read-Only / Non-Mutating) ---

def run_tier1_diagnostics(state: OrchestratorState) -> Dict[str, Any]:
    """Auto-authorized, read-only probe layer to gather empirical telemetry."""
    diagnostics: Dict[str, Any] = {}

    db_path = "manufacturing.db"
    if os.path.exists(db_path):
        diagnostics["manufacturing_db_size_bytes"] = os.path.getsize(db_path)
    else:
        diagnostics["manufacturing_db_size_bytes"] = -1

    try:
        result = subprocess.run(
            ["docker", "info", "--format", "{{.ServerVersion}}"],
            capture_output=True,
            text=True,
            timeout=3,
        )
        diagnostics["docker_daemon_active"] = result.returncode == 0
        diagnostics["docker_version"] = result.stdout.strip() if result.returncode == 0 else None
    except Exception as exc:
        diagnostics["docker_daemon_active"] = False
        diagnostics["docker_error"] = str(exc)

    return {"diagnostic_probe_results": diagnostics}

# --- Governance Decay & Empirical Fact Enforcement ---

def empirical_fact_gate_node(state: OrchestratorState) -> Dict[str, Any]:
    """Enforces that execution cannot repeat a review without a new empirical probe result."""
    current_diagnostics = state.get("diagnostic_probe_results", {})
    recorded_facts = state.get("empirical_facts", [])

    diag_str = json.dumps(current_diagnostics, sort_keys=True)
    fact_hash = hashlib.sha256(diag_str.encode()).hexdigest()[:12]

    known_hashes = [fact.get("hash") for fact in recorded_facts]
    is_novel_fact = fact_hash not in known_hashes

    state_repr = (
        f"{state.get('target_perspective')}-{diag_str}-"
        f"{state.get('review_iteration_count', 0)}"
    )
    current_fingerprint = hashlib.sha256(state_repr.encode()).hexdigest()[:12]
    fingerprints = state.get("state_fingerprints", [])
    loop_flag = fingerprints.count(current_fingerprint) >= 2

    updated_facts = list(recorded_facts)
    if is_novel_fact:
        updated_facts.append({"hash": fact_hash, "data": current_diagnostics})

    return {
        "empirical_facts": updated_facts,
        "state_fingerprints": fingerprints + [current_fingerprint],
        "loop_detected": loop_flag,
    }


def decay_gate_node(state: OrchestratorState) -> Dict[str, Any]:
    """Increments review count and caps max review deliberations."""
    count = state.get("review_iteration_count", 0) + 1
    return {"review_iteration_count": count}


def triage_node(state: OrchestratorState) -> Dict[str, Any]:
    """Evaluates whether the requested action needs human sign-off."""
    sensitive_perspectives = {"Inventory_Transactions", "General_Ledger", "Visual_Admin"}
    needs_review = state.get("target_perspective") in sensitive_perspectives
    return {"requires_approval": needs_review}


def human_review_node(state: OrchestratorState) -> Dict[str, Any]:
    """Pauses execution and surfaces empirical diagnostic facts to the operator."""
    review_response = interrupt({
        "reason": "Human approval required prior to downstream dispatch",
        "iteration": state.get("review_iteration_count", 1),
        "perspective": state.get("target_perspective"),
        "empirical_diagnostics": state.get("diagnostic_probe_results", {}),
        "loop_warning": state.get("loop_detected", False),
        "payload": state.get("query_payload"),
    })

    return {
        "is_approved": review_response.get("approved", False),
        "approval_comments": review_response.get("comments", ""),
    }


def execution_node(state: OrchestratorState) -> Dict[str, Any]:
    """Executes the action once approved or if approval was bypassed."""
    if state.get("requires_approval") and not state.get("is_approved"):
        return {
            "execution_result": {
                "status": "REJECTED",
                "details": state.get("approval_comments", "Action rejected by operator."),
            }
        }

    return {
        "execution_result": {
            "status": "SUCCESS",
            "details": f"Dispatched payload for {state.get('target_perspective')}",
            "diagnostics_used": state.get("diagnostic_probe_results"),
        }
    }