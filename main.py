from typing import Any, Dict, Optional
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from langgraph.types import Command
from graph import orchestrator_graph

app = FastAPI(title="LangGraph HITL Orchestrator")

class RunRequest(BaseModel):
    thread_id: str
    perspective: str
    payload: Dict[str, Any]

class ResumeRequest(BaseModel):
    thread_id: str
    approved: bool
    comments: Optional[str] = None

@app.post("/orchestrate")
async def start_orchestration(req: RunRequest):
    config = {"configurable": {"thread_id": req.thread_id}}
    initial_input = {
        "target_perspective": req.perspective,
        "query_payload": req.payload,
        "messages": []
    }
    
    # Run until complete or until interrupted by human_review_node
    events = []
    for event in orchestrator_graph.stream(initial_input, config=config):
        events.append(event)
    
    # Check current state to see if interrupted
    snapshot = orchestrator_graph.get_state(config)
    if snapshot.next:
        return {
            "status": "PAUSED",
            "thread_id": req.thread_id,
            "next_node": snapshot.next,
            "tasks": [task.interrupts for task in snapshot.tasks if task.interrupts]
        }
    
    return {
        "status": "COMPLETED",
        "thread_id": req.thread_id,
        "final_state": snapshot.values
    }

@app.get("/state/{thread_id}")
async def get_thread_state(thread_id: str):
    config = {"configurable": {"thread_id": thread_id}}
    snapshot = orchestrator_graph.get_state(config)
    if not snapshot:
        raise HTTPException(status_code=404, detail="Thread not found")
    return {
        "values": snapshot.values,
        "next": snapshot.next,
        "tasks": [task.interrupts for task in snapshot.tasks if task.interrupts]
    }

@app.post("/resume")
async def resume_orchestration(req: ResumeRequest):
    config = {"configurable": {"thread_id": req.thread_id}}
    snapshot = orchestrator_graph.get_state(config)
    
    if not snapshot.next:
        raise HTTPException(status_code=400, detail="Thread is not in a paused state")
    
    resume_payload = {
        "approved": req.approved,
        "comments": req.comments or ""
    }
    
    # Resume execution with operator verdict
    events = []
    for event in orchestrator_graph.stream(Command(resume=resume_payload), config=config):
        events.append(event)
        
    final_snapshot = orchestrator_graph.get_state(config)
    return {
        "status": "COMPLETED",
        "thread_id": req.thread_id,
        "final_state": final_snapshot.values
    }