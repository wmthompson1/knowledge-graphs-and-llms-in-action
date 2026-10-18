from langgraph.checkpoint.memory import MemorySaver
from langgraph.graph import END, START, StateGraph
from nodes import (
    decay_gate_node,
    empirical_fact_gate_node,
    execution_node,
    human_review_node,
    run_tier1_diagnostics,
    triage_node,
)
from state import OrchestratorState

MAX_SCRUTINY_CYCLES = 2


def route_triage(state: OrchestratorState) -> str:
    if state.get("requires_approval"):
        return "tier1_probes"
    return "execution"


def route_after_fact_gate(state: OrchestratorState) -> str:
    if state.get("loop_detected"):
        return "human_review"

    if state.get("review_iteration_count", 0) >= MAX_SCRUTINY_CYCLES:
        return "human_review"

    if state.get("requires_approval"):
        return "human_review"

    return "execution"


def build_graph():
    builder = StateGraph(OrchestratorState)

    builder.add_node("triage", triage_node)
    builder.add_node("tier1_probes", run_tier1_diagnostics)
    builder.add_node("decay_gate", decay_gate_node)
    builder.add_node("fact_gate", empirical_fact_gate_node)
    builder.add_node("human_review", human_review_node)
    builder.add_node("execution", execution_node)

    builder.add_edge(START, "triage")
    builder.add_edge("triage", "tier1_probes")
    builder.add_edge("tier1_probes", "decay_gate")
    builder.add_edge("decay_gate", "fact_gate")
    builder.add_conditional_edges(
        "fact_gate",
        route_after_fact_gate,
        {
            "human_review": "human_review",
            "execution": "execution",
        },
    )
    builder.add_edge("human_review", "execution")
    builder.add_edge("execution", END)

    checkpointer = MemorySaver()
    return builder.compile(checkpointer=checkpointer)

orchestrator_graph = build_graph()