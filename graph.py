from langgraph.checkpoint.memory import MemorySaver
from langgraph.graph import END, START, StateGraph
from nodes import execution_node, human_review_node, triage_node
from state import OrchestratorState

def route_triage(state: OrchestratorState) -> str:
    if state.get("requires_approval"):
        return "human_review"
    return "execution"

def build_graph():
    builder = StateGraph(OrchestratorState)

    builder.add_node("triage", triage_node)
    builder.add_node("human_review", human_review_node)
    builder.add_node("execution", execution_node)

    builder.add_edge(START, "triage")
    builder.add_conditional_edges(
        "triage",
        route_triage,
        {
            "human_review": "human_review",
            "execution": "execution"
        }
    )
    builder.add_edge("human_review", "execution")
    builder.add_edge("execution", END)

    # A checkpointer is mandatory for human-in-the-loop state retention
    checkpointer = MemorySaver()
    return builder.compile(checkpointer=checkpointer)

orchestrator_graph = build_graph()