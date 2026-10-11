from typing import Annotated, Any, Dict, List, Optional
from typing_extensions import TypedDict
from langgraph.graph.message import add_messages

class OrchestratorState(TypedDict):
    messages: Annotated[List[Dict[str, Any]], add_messages]
    target_perspective: str
    query_payload: Dict[str, Any]
    requires_approval: bool
    is_approved: Optional[bool]
    approval_comments: Optional[str]
    execution_result: Optional[Dict[str, Any]]