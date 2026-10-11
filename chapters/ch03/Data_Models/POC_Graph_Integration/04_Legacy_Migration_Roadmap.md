---
title: Legacy Migration Roadmap
version: 1.0
date: 2024-06-11
status: complete
---

# Legacy Migration Roadmap: Stage 1 Deprecation Plan

## Executive Summary

The POC graph is transitioning from **Stage 0 (legacy perspective traversal)** to **Stage 1 (logical component binding)** over the next 2–3 release cycles. This document outlines which assets are deprecated, why, and how downstream consumers must adapt.

**Key Principle:** Deprecated assets remain in the graph (read-only) until all dependent systems are migrated.

---

## Stage 1: Deprecate-First Assets (HIGHEST PRIORITY)

### Asset 1: bindings (Vertex Collection)

| Attribute | Value |
|-----------|-------|
| **Kind** | Vertex (document) |
| **Current Role** | Stores intent-to-field binding metadata |
| **Replacement** | Reviewer manifest (`ground_truth/reviewer_manifest.json`) + `Column_Bindings` edge properties |
| **Rationale** | Binding vertices duplicate metadata now stored in manifest and edge properties; no current code traverses bindings directly |
| **Timeline** | Deprecate v1.2 → Remove v1.4 |
| **Blockers** | `bound_to`, `defined_by`, `filters` edges depend on this vertex |

**Before (Stage 0):**
```aql
# Query bindings vertex directly
FOR doc IN bindings
    FILTER doc._key == "CUS_ACC_001_BIL_Accounts_Receivable"
    RETURN {
        intent: doc.intent,
        category: doc.category,
        discriminator: doc.discriminator_clause
    }
```

**After (Stage 1):**
```aql
# Read from Column_Bindings edge instead
FOR edge IN Column_Bindings
    FILTER edge._key == "CUS_ACC_001_BIL_Accounts_Receivable"
    RETURN {
        intent: edge.intent,
        category: edge.perspective,
        discriminator: edge.discriminator_clause
    }
```

**Migration Step:**
1. ✓ Load reviewer manifest into `Column_Bindings` edge properties (DONE: `graph_sync.py`)
2. ⏳ **Rewrite downstream consumers** to query `Column_Bindings` instead of `bindings` vertex
3. ⏳ Run `legacy_graph_migration_plan.py` to delete `bindings` vertices
4. ⏳ Remove `bindings` vertex collection definition

---

### Asset 2: bound_to (Edge Collection)

| Attribute | Value |
|-----------|-------|
| **Kind** | Edge |
| **Current Role** | Connects intents → bindings vertices |
| **Replacement** | Primary binding key stored in SQLite + `Column_Bindings` edge properties |
| **Rationale** | The intent-to-binding handoff is redundant once downstream stop expecting standalone `bindings` vertices |
| **Timeline** | Deprecate v1.2 → Remove v1.4 |
| **Blockers** | Solder engine, semantic reasoning (need rewrite) |

**Before (Stage 0):**
```aql
# Traverse intent → binding via bound_to edge
FOR intent IN intents
    FOR edge IN bound_to
        FILTER edge._from == intent._id
        FOR binding IN bindings
            FILTER binding._id == edge._to
            RETURN { intent, binding }
```

**After (Stage 1):**
```aql
# Bindings metadata stored in Column_Bindings properties
FOR edge IN Column_Bindings
    FILTER STARTS_WITH(edge.intent, "BIL")  -- filter by intent
    RETURN {
        intent: edge.intent,
        binding_key: edge._key,
        field: edge._from,
        concept: edge._to
    }
```

**Migration Step:**
1. ✓ Populate `Column_Bindings` edges with intent/perspective properties (DONE: `graph_sync.py`)
2. ⏳ **Rewrite traversal logic** to query `Column_Bindings` directly
3. ⏳ Delete `bound_to` edges via `legacy_graph_migration_plan.py`
4. ⏳ Remove `bound_to` edge collection definition

---

### Asset 3: defined_by (Edge Collection)

| Attribute | Value |
|-----------|-------|
| **Kind** | Edge |
| **Current Role** | Component scoping: connects binding → perspective (helper edge) |
| **Replacement** | `Column_Bindings.perspective` edge property |
| **Rationale** | Component scoping now lives directly on `Column_Bindings` edge; no runtime code traverses `defined_by` |
| **Timeline** | Deprecate v1.2 → Remove v1.4 |
| **Blockers** | None identified (helper edge, low usage) |

**Before (Stage 0):**
```aql
FOR edge IN defined_by
    RETURN {
        binding: edge._from,
        perspective: edge._to,
        component: edge.component_name
    }
```

**After (Stage 1):**
```aql
FOR edge IN Column_Bindings
    RETURN {
        binding_key: edge._key,
        perspective: edge.perspective,
        component: edge.component_name
    }
```

**Migration Step:**
1. ✓ Populate `Column_Bindings.perspective` and `component_name` properties (DONE: `graph_sync.py`)
2. ⏳ **Search codebase** for `defined_by` traversals (likely low usage)
3. ⏳ Delete `defined_by` edges
4. ⏳ Remove `defined_by` edge collection definition

---

### Asset 4: filters (Edge Collection)

| Attribute | Value |
|-----------|-------|
| **Kind** | Edge |
| **Current Role** | Component filter semantics: connect binding → filter expression (helper edge) |
| **Replacement** | `Column_Bindings.discriminator_clause` + `discriminator_field_name` edge properties |
| **Rationale** | Filter semantics preserved on logical contract; no runtime traversal depends on this helper edge |
| **Timeline** | Deprecate v1.2 → Remove v1.4 |
| **Blockers** | None identified (helper edge, low usage) |

**Before (Stage 0):**
```aql
FOR edge IN filters
    RETURN {
        binding: edge._from,
        filter_expr: edge.filter_expression,
        field_name: edge.field_name
    }
```

**After (Stage 1):**
```aql
FOR edge IN Column_Bindings
    RETURN {
        binding_key: edge._key,
        filter_expr: edge.discriminator_clause,
        field_name: edge.discriminator_field_name
    }
```

**Migration Step:**
1. ✓ Populate `Column_Bindings.discriminator_clause` and `discriminator_field_name` properties (DONE: `graph_sync.py`)
2. ⏳ **Search codebase** for `filters` edge traversals
3. ⏳ Delete `filters` edges
4. ⏳ Remove `filters` edge collection definition

---

## Stage 2: Hold-for-Rewrites Assets (DEFERRED)

These assets remain longer pending major rewrites in downstream systems.

### Asset 5: intents (Vertex Collection)

| Attribute | Value |
|-----------|-------|
| **Kind** | Vertex (document) |
| **Current Role** | Semantic intent definitions (e.g., "Billing", "Operations") |
| **Status** | **PROTECTED** — Do NOT delete in Stage 1 |
| **Timeline** | Hold → Evaluate v1.4 (dependent on Solder rewrite) |
| **Reason** | Core semantic layer; Solder engine & semantic reasoning depend on intent traversal |

**Protected:** `intents` remains, but `intents` → `bindings` edge (`bound_to`) will be removed in Stage 1.

---

### Asset 6: perspectives (Vertex Collection)

| Attribute | Value |
|-----------|-------|
| **Kind** | Vertex (document) |
| **Current Role** | Domain perspectives (e.g., "Accounts Receivable", "Work Order Operations") |
| **Status** | **PROTECTED** — Do NOT delete in Stage 1 |
| **Timeline** | Hold → Evaluate v1.4 (dependent on Solder rewrite) |
| **Reason** | Core semantic layer; navigation & inference depend on perspective traversal |

**Protected:** `perspectives` remains, but traversal patterns will shift to `Column_Bindings.perspective` property.

---

### Asset 7: concepts (Vertex Collection)

| Attribute | Value |
|-----------|-------|
| **Kind** | Vertex (document) |
| **Current Role** | Business concepts (e.g., "accounts_receivable", "customer") |
| **Status** | **PROTECTED** — Do NOT delete in Stage 1 |
| **Timeline** | Hold → Evaluate v1.4 (dependent on semantic reasoning rewrite) |
| **Reason** | Core semantic layer; inference rules depend on concept definitions |

**Protected:** `concepts` remains. Edges connecting to concepts (`can_mean`, `elevates`) will be re-evaluated in Stage 1 based on Column_Bindings logical contract.

---

## Protected Assets (DO NOT MODIFY IN STAGE 1)

### Semantic Vertex Collections (Core Layer)
- ✓ `intents` — Intent definitions
- ✓ `perspectives` — Domain perspectives
- ✓ `concepts` — Business concepts
- ✓ `fields` — Field definitions
- ✓ `Graph_Component_Fields` — Logical component structure
- ✓ `Graph_Concepts` — Logical concept structure

### Semantic Edge Collections (Core Layer)
- ✓ `operates_within` — Intent → perspective
- ✓ `elevates` — Intent → concept
- ✓ `uses_definition` — Perspective → concept
- ✓ `can_mean` — Field → concept
- ✓ `Column_Bindings` — Logical binding edges (**NEW**, primary contract)

### Structural Collections (DDL-Derived)
- ✓ `manufacturing_graph_node` — Tables & columns (vertices)
- ✓ `HAS_COLUMN` — Table → column edges
- ✓ `ATOMIC_FK` — Foreign key edges

---

## Stage 1 Migration Timeline

### Phase 1 (v1.1 → v1.2, 4 weeks)
**Goal:** Populate replacement assets; begin testing.

- [x] **Week 1–2:** Populate `Column_Bindings` edges with intent/perspective/discriminator properties (DONE in `graph_sync.py`)
- [x] **Week 2–3:** Load reviewer manifest into SQLite; verify parity with bindings vertices
- [ ] **Week 3–4:** Deploy v1.2; run in parallel mode (keep old + new edges)

**Deliverable:** `graph_sync.py` Stage 1 output; `Column_Bindings` edges fully populated.

---

### Phase 2 (v1.2 → v1.3, 4 weeks)
**Goal:** Rewrite downstream consumers.

- [ ] **Week 1–2:** Identify all downstream consumers of deprecated assets
  - Grep for: `bound_to`, `defined_by`, `filters` traversals
  - Inspect: `solder_engine.py`, `semantic_reasoning.py`, `hf-space-inventory-sqlgen/app.py`
- [ ] **Week 2–3:** Rewrite consumers to use `Column_Bindings` + manifest instead
- [ ] **Week 3–4:** Deploy v1.3; test with new query patterns
- [ ] Run automated parity tests (new vs. old results must match)

**Deliverable:** Rewritten Solder engine & semantic reasoning using `Column_Bindings`.

---

### Phase 3 (v1.3 → v1.4, 2 weeks)
**Goal:** Remove deprecated assets from graph.

- [ ] **Week 1:** Run `legacy_graph_migration_plan.py` on staging environment
  - Delete `bindings` vertices
  - Delete `bound_to` edges
  - Delete `defined_by` edges
  - Delete `filters` edges
- [ ] **Week 1–2:** Verify graph integrity; audit edge counts
- [ ] **Week 2:** Deploy v1.4 to production (clean graph)

**Deliverable:** Clean ArangoDB graph with only Stage 1 assets.

---

## Code: Legacy Migration Plan

```python
# scripts/legacy_graph_migration_plan.py
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
SCRIPTS_DIR = REPO_ROOT / "scripts"
HF_SPACE_DIR = REPO_ROOT / "hf-space-inventory-sqlgen"

for candidate in (SCRIPTS_DIR, HF_SPACE_DIR):
    candidate_str = str(candidate)
    if candidate_str not in sys.path:
        sys.path.insert(0, candidate_str)

import graph_sync
from perspective_cleanup_strategy import LEGACY_ASSETS

PLAN_ID = "plan-legacy-graph-migration"
STAGE1_ASSET_NAMES = ("bindings", "bound_to", "defined_by", "filters")
PROTECTED_VERTEX_NAMES = ("intents", "perspectives", "concepts", "fields")
PROTECTED_EDGE_NAMES = ("operates_within", "elevates", "uses_definition", "can_mean")

def build_cleanup_spec(repo_root: Path) -> dict:
    """Build cleanup specification for Stage 1 deprecation."""
    report = graph_sync.sync_graph(dry_run=True)
    
    spec = {
        "plan_id": PLAN_ID,
        "stage": "deprecate_first",
        "expected_counts": {
            "pre_cleanup": {
                "bindings": report.vertices_synced.get("bindings", 0),
                "bound_to": report.edges_synced.get("bound_to", 0),
                "defined_by": report.edges_synced.get("defined_by", 0),
                "filters": report.edges_synced.get("filters", 0),
            },
            "post_cleanup": {
                "bindings": 0,
                "bound_to": 0,
                "defined_by": 0,
                "filters": 0,
            }
        },
        "protected_assets": {
            "vertices": PROTECTED_VERTEX_NAMES,
            "edges": PROTECTED_EDGE_NAMES,
        },
        "new_logical_contract": {
            "vertices": [
                "intents", "perspectives", "concepts", "fields",
                "Graph_Component_Fields", "Graph_Concepts"
            ],
            "edges": [
                "operates_within", "elevates", "uses_definition",
                "can_mean", "Column_Bindings",
                "HAS_COLUMN", "ATOMIC_FK"
            ]
        }
    }
    return spec

def main() -> int:
    parser = argparse.ArgumentParser(description="Build legacy graph migration plan")
    parser.add_argument("--dry-run", action="store_true", default=True)
    parser.add_argument("--live", action="store_true", help="Execute live cleanup (requires confirmation)")
    args = parser.parse_args()
    
    spec = build_cleanup_spec(REPO_ROOT)
    
    if args.dry_run and not args.live:
        print(json.dumps(spec, indent=2))
        return 0
    
    if args.live:
        print("WARNING: This will delete legacy assets from ArangoDB")
        confirmation = input("Type 'yes' to confirm: ")
        if confirmation != "yes":
            print("Cancelled.")
            return 1
        
        # Execute cleanup on live graph
        client = graph_sync.get_arango_client()
        db = client.db(graph_sync.GRAPH_NAME, ...)
        
        # Delete in order (edges before vertices)
        for edge_collection in ("bound_to", "defined_by", "filters"):
            db.delete_collection(edge_collection)
            print(f"✓ Deleted edge collection: {edge_collection}")
        
        db.delete_collection("bindings")
        print(f"✓ Deleted vertex collection: bindings")
        
        print("\nPost-cleanup verification:")
        report = graph_sync.sync_graph(dry_run=True)
        print(json.dumps(spec["expected_counts"]["post_cleanup"], indent=2))
        return 0

if __name__ == "__main__":
    raise SystemExit(main())
```

---

## Deprecation Strategy: perspective_cleanup_strategy.py

```python
# scripts/perspective_cleanup_strategy.py
from __future__ import annotations

from dataclasses import asdict, dataclass

@dataclass(frozen=True)
class LegacyAsset:
    name: str              # Collection name
    kind: str              # "vertex" | "edge"
    stage: str             # "deprecate_first" | "hold_for_rewrites"
    replacement: str       # What replaces this asset
    rationale: str         # Why deprecated
    blockers: tuple[str, ...] = ()  # Dependent downstream systems

LEGACY_ASSETS: tuple[LegacyAsset, ...] = (
    LegacyAsset(
        name="bindings",
        kind="vertex",
        stage="deprecate_first",
        replacement="Reviewer manifest + Column_Bindings edge properties",
        rationale="Binding metadata now duplicated; runtime resolves from manifest & edge properties.",
        blockers=("Solder engine", "semantic reasoning", "hf-space app"),
    ),
    LegacyAsset(
        name="bound_to",
        kind="edge",
        stage="deprecate_first",
        replacement="Column_Bindings properties + SQLite primary_binding_key",
        rationale="Intent-to-binding handoff redundant once bindings vertex deprecated.",
        blockers=("Solder engine", "semantic reasoning"),
    ),
    LegacyAsset(
        name="defined_by",
        kind="edge",
        stage="deprecate_first",
        replacement="Column_Bindings.perspective + component_name",
        rationale="Component scoping now on Column_Bindings; no traversal depends on edge.",
        blockers=(),
    ),
    LegacyAsset(
        name="filters",
        kind="edge",
        stage="deprecate_first",
        replacement="Column_Bindings.discriminator_clause + discriminator_field_name",
        rationale="Filter semantics preserved on logical contract; no runtime traversal needed.",
        blockers=(),
    ),
    LegacyAsset(
        name="intents",
        kind="vertex",
        stage="hold_for_rewrites",
        replacement="Retained; no deletion planned",
        rationale="Core semantic layer; Solder & semantic reasoning depend on intent traversal.",
        blockers=(),
    ),
)
```

---

## Checklist: Stage 1 Execution

- [ ] **Phase 1:** `Column_Bindings` edges fully populated + properties set (manifest loaded)
- [ ] **Phase 2:** All downstream consumers identified & rewritten
- [ ] **Phase 2:** Automated tests verify new query results match old results
- [ ] **Phase 3:** Staging environment cleanup tested successfully
- [ ] **Phase 3:** Production backup taken before deletion
- [ ] **Phase 3:** Graph audit confirms expected post-cleanup counts
- [ ] **Phase 3:** Monitoring alerts set up for any broken queries

---

## Rollback Plan

If issues discovered during Phase 3:

1. **Restore from backup** taken before deletion
2. **Revert code** to v1.3 (rollback Solder/semantic reasoning rewrites)
3. **Hold Phase 3** longer; identify root cause
4. **Re-plan** with additional stakeholder input

---

## FAQ

**Q: Can we delete all 4 Stage-1 assets at once?**  
A: No. Delete edges first (`bound_to`, `defined_by`, `filters`), then vertices (`bindings`). Order matters for referential integrity.

**Q: What if a downstream consumer still uses `bound_to`?**  
A: Phase 2 blocks Phase 3. Grep codebase; rewrite all consumers before deletion.

**Q: Can we keep `bindings` longer?**  
A: Yes. Stages are estimates; push Phase 3 to v1.5 or v1.6 if needed. Priority: all consumers migrated first.

**Q: What about `intents` & `perspectives`? Are they safe?**  
A: **YES.** These are **PROTECTED** in Stage 1. Only deprecated assets (Stage-1 list) are removed.

---

## References

- **Tracking File:** `scripts/perspective_cleanup_strategy.py`
- **Migration Orchestrator:** `scripts/legacy_graph_migration_plan.py`
- **Tests:** `scripts/test_legacy_graph_migration_plan_unitTest.py`
- **Related:** [01_Layer_Dependencies.md](01_Layer_Dependencies.md), [00_POC_Ecosystem_Overview.md](00_POC_Ecosystem_Overview.md)

---

## Next: Operational Guide

See **[05_Running_the_POC.md](05_Running_the_POC.md)** for step-by-step operational procedures.

