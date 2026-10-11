from typing import Any, Dict
from langgraph.types import interrupt
from state import OrchestratorState

def triage_node(state: OrchestratorState) -> Dict[str, Any]:
    """Evaluates whether the requested action needs human sign-off."""
    # Example logic: Any mutating operation or sensitive perspective requires review
    sensitive_perspectives = {"Inventory_Transactions", "General_Ledger", "Visual_Admin"}
    needs_review = state.get("target_perspective") in sensitive_perspectives
    return {"requires_approval": needs_review}

def human_review_node(state: OrchestratorState) -> Dict[str, Any]:
    """Pauses execution and surfaces the payload to an operator."""
    # Interrupt execution and wait for an external resume payload
    review_response = interrupt({
        "reason": "Human approval required prior to downstream dispatch",
        "perspective": state.get("target_perspective"),
        "payload": state.get("query_payload")
    })
    
    # review_response is populated when the graph is resumed with Command(resume=...)
    return {
        "is_approved": review_response.get("approved", False),
        "approval_comments": review_response.get("comments", "")
    }

def execution_node(state: OrchestratorState) -> Dict[str, Any]:
    """Executes the action once approved or if approval was bypassed."""
    if state.get("requires_approval") and not state.get("is_approved"):
        return {
            "execution_result": {
                "status": "REJECTED",
                "details": state.get("approval_comments", "Action rejected by operator.")
            }
        }
    
    return {
        "execution_result": {
            "status": "SUCCESS",
            "details": f"Dispatched payload for {state.get('target_perspective')}"
        }
    }