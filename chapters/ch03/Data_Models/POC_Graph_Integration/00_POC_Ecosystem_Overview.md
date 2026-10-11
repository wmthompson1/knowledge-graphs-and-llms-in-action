---
title: POC Ecosystem Overview
version: 1.0
date: 2024-06-11
status: complete
---

# SQL-Projects Graph Integration POC: Ecosystem Overview

## Executive Summary

The SQL-Projects Graph Integration POC is a multi-layer data ecosystem that synchronizes ERP structure metadata, semantic field definitions, and binding logic from SQL Server (through SQLMesh) into an ArangoDB graph database. The system enables semantic reasoning, field lineage, and intent-aware data binding across manufacturing and inventory domains.

**Key Insight:** The POC is *not* a single monolithic script—it's a highly modular ecosystem with clear separation of concerns across 11 specialized layers.

---

## High-Level Architecture (11 Layers)

```
┌─────────────────────────────────────────────────────────────────────────┐
│  Layer 11: End-to-End Testing (test_e2e_sqlmesh_to_arango.py, ...)     │
├─────────────────────────────────────────────────────────────────────────┤
│  Layer 10: Utilities & Helpers (NetworkX, semantic reasoning, solder)   │
├─────────────────────────────────────────────────────────────────────────┤
│  Layer 9: Persistence Layer (arangodb_persistence.py shim)              │
├─────────────────────────────────────────────────────────────────────────┤
│  Layer 8: Audit & Validation (generate_graph_audit.py)                 │
├─────────────────────────────────────────────────────────────────────────┤
│  Layer 7: Legacy Migration & Cleanup (perspective_cleanup_strategy.py)  │
├─────────────────────────────────────────────────────────────────────────┤
│  Layer 6: Graph Sync Orchestration (run_incremental_graph_sync_path.py) │
├─────────────────────────────────────────────────────────────────────────┤
│  Layer 5: Graph Initialization (initialize_lowercase_graph.py)          │
├─────────────────────────────────────────────────────────────────────────┤
│  Layer 4: Binding Key Generation (graph_key_generation.py)              │
├─────────────────────────────────────────────────────────────────────────┤
│  Layer 3: DDL & Schema Preparation (load_erp_ddl_into_sqlite.py, ...)   │
├─────────────────────────────────────────────────────────────────────────┤
│  Layer 2: Graph Sync Core (graph_sync.py - CENTRAL HUB)                 │
├─────────────────────────────────────────────────────────────────────────┤
│  Layer 1: SQLMesh Models (raw_user_def_fields.py, raw_matrix_driven.py) │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Layer Responsibilities & Key Files

### Layer 1: SQLMesh Models (Data Source)
**Purpose:** Generate raw semantic data from SQL Server via SQLMesh DuckDB backend.

| File | Responsibility |
|------|-----------------|
| `Utilities/SQLMesh/models/raw/masking_helpers.py` | Helper functions for PII masking and data transformations |
| `Utilities/SQLMesh/models/raw/raw_user_def_fields.py` | **PRIMARY:** User-defined field definitions for semantic layer |
| `Utilities/SQLMesh/models/raw/raw_matrix_driven.py` | Matrix-driven field definitions (configurable bindings) |
| `Utilities/SQLMesh/models/raw/raw_last_certified.py` | Last certified state tracking for validation |
| `scripts/generate_matrix_models.py` | Code generator: produces new raw_*.py models from templates |

**Output:** Materialized tables in `raw__dev` or `raw__udf_isolate` DuckDB schemas.

---

### Layer 2: Graph Sync Core (CENTRAL HUB)
**Purpose:** Orchestrate all semantic and structural graph operations; the primary data sync engine.

```python
# hf-space-inventory-sqlgen/graph_sync.py
from graph_key_generation import compile_binding_key

GRAPH_NAME = os.environ.get("ARANGO_DB", "manufacturing_graph")
STRUCTURE_VERTEX_COLLECTION = f"{GRAPH_NAME}_node"
LOGICAL_COMPONENT_FIELD_COLLECTION = "Graph_Component_Fields"
LOGICAL_CONCEPT_COLLECTION = "Graph_Concepts"
LOGICAL_BINDING_EDGE_COLLECTION = "Column_Bindings"

# Key exports:
def get_arango_client() -> ArangoClient
def sync_graph(db_path: str, dry_run: bool, table_filter: str) -> SyncReport
def _filter_structure_data(data: List[Dict]) -> List[Dict]
def load_structure_sqlite_data(conn: sqlite3.Connection) -> List[Dict]
```

**Exports:** All downstream imports depend on `sync_graph()`, `get_arango_client()`, and `_filter_structure_data()`.

**Imported By:** 9+ files across `scripts/` and `hf-space-inventory-sqlgen/`.

---

### Layer 3: DDL & Schema Preparation
**Purpose:** Parse canonical DDL from ERP sources; extract table and foreign-key metadata into SQLite.

| File | Responsibility |
|------|-----------------|
| `scripts/load_erp_ddl_into_sqlite.py` | Parse SQL Server CREATE TABLE DDL; load into `schema_tables` & `schema_foreign_keys` tables |
| `scripts/generate_matrix_models.py` | Generate new SQLMesh raw_*.py models from semantic metadata |
| `scripts/extract_tables_from_data_models.py` | Extract table metadata from Documentation/Schema/Data_Models |
| `scripts/populate_schema_nodes_edges.py` | Populate `manufacturing_graph_node` and FK edges |

**Key Function:**
```python
# scripts/load_erp_ddl_into_sqlite.py
def parse_ddl_file(ddl_path: Path) -> tuple[Dict, List[Dict]]:
    """Parse canonical DDL into table_record and foreign_keys list."""
```

**Input:** Canonical DDL files from `Utilities/SQLMesh/ddl/` (e.g., `dbo.WORK_ORDER.sql`).

**Output:** SQLite tables: `schema_tables`, `schema_columns`, `schema_foreign_keys`, `manufacturing_graph_node`.

---

### Layer 4: Binding Key Generation (UTILITY)
**Purpose:** Compile deterministic, normalized binding keys used throughout the graph.

```python
# scripts/graph_key_generation.py
def compile_binding_key(
    *,
    left_source: str,
    right_target: str,
    path_index: int | str,
    intent_token: str,
    perspective: str,
) -> str:
    """
    Compile a deterministic binding key using the 5-segment formula:
    {left_source}_{right_target}_{path_index}_{intent_token}_{perspective}
    
    Normalizations:
      - left_source: first 3 alphanumeric chars, UPPERCASE
      - right_target: first 3 alphanumeric chars, UPPERCASE
      - path_index: 3-digit zero-padded integer (0-999)
      - intent_token: first 3 alphanumeric chars, UPPERCASE
      - perspective: alphanumeric + underscores, all words joined by underscores
    
    Example:
      Input: left_source='Customer', right_target='Account', path_index=1,
             intent_token='Billing', perspective='Accounts Receivable'
      Output: "CUS_ACC_001_BIL_Accounts_Receivable"
    """
```

**Used By:** `graph_sync.py`, 3+ test files.

---

### Layer 5: Graph Initialization
**Purpose:** Set up ArangoDB database, collections (vertex & edge), and graph definitions.

```python
# scripts/initialize_lowercase_graph.py
def initialize_production_graph():
    """
    1. Create/verify manufacturing_graph database
    2. Create vertex collections: fields, concepts, intents, bindings
    3. Create edge collections: operates_within, elevates, uses_definition, ...
    4. Define graph structure for traversals
    """
```

**Prerequisites:** ArangoDB server running (configured via `ARANGO_*` env vars).

**Collections Created:**
- **Vertex:** `fields`, `concepts`, `intents`, `bindings`, `perspectives`, `manufacturing_graph_node`
- **Edge:** `operates_within`, `elevates`, `uses_definition`, `bound_to`, `can_mean`, `defined_by`, `filters`, `Column_Bindings`, `HAS_COLUMN`, `ATOMIC_FK`

---

### Layer 6: Graph Sync Orchestration
**Purpose:** Coordinate DDL parsing → SQLite loading → graph sync.

```python
# scripts/run_incremental_graph_sync_path.py
def main():
    # 1. Resolve canonical DDL file
    ddl_file = REPO_ROOT / "Utilities" / "SQLMesh" / "ddl" / f"dbo.{table_name}.sql"
    
    # 2. Parse DDL
    table_record, foreign_keys = parse_ddl_file(ddl_file)
    
    # 3. Load into SQLite
    load_structure_sqlite_data(table_record, foreign_keys)
    
    # 4. Sync to ArangoDB
    if args.live_sync:
        sync_graph(table_filter=args.table, dry_run=False)
```

**Exports:**
- `sync_graph()` for incremental table-scoped updates
- Integration point for batch workflows

---

### Layer 7: Legacy Migration & Cleanup
**Purpose:** Track and migrate deprecated graph assets (Stage 1 deprecation plan).

```python
# scripts/perspective_cleanup_strategy.py
@dataclass(frozen=True)
class LegacyAsset:
    name: str              # e.g., "bindings"
    kind: str              # "vertex" | "edge"
    stage: str             # "deprecate_first" | "hold_for_rewrites"
    replacement: str       # Migration target
    rationale: str         # Why deprecated
    blockers: tuple = ()   # Downstream dependencies

LEGACY_ASSETS = (
    LegacyAsset(
        name="bindings",
        kind="vertex",
        stage="deprecate_first",
        replacement="Reviewer manifest + Column_Bindings edge properties",
        rationale="Binding metadata now duplicated; runtime resolves from manifest instead."
    ),
    LegacyAsset(name="bound_to", kind="edge", stage="deprecate_first", ...),
    LegacyAsset(name="defined_by", kind="edge", stage="deprecate_first", ...),
    LegacyAsset(name="filters", kind="edge", stage="deprecate_first", ...),
    # ... more assets
)
```

**Related Files:**
- `scripts/legacy_graph_migration_plan.py` — Orchestrates migration workflows
- `scripts/test_legacy_graph_migration_plan_unitTest.py` — Tests migration logic
- `scripts/test_perspective_cleanup_strategy_unitTest.py` — Tests cleanup strategies

---

### Layer 8: Audit & Validation
**Purpose:** Generate audit reports and validate data integrity across layers.

| File | Responsibility |
|------|-----------------|
| `scripts/generate_graph_audit.py` | Reads SQLite + ArangoDB; writes `graph_audit.md` |
| `scripts/test_logical_sync_contract_regression_unitTest.py` | Validates sync contract invariants |

**Output:** `graph_audit.md` (repo root) with vertex/edge counts, coverage matrix, and validation results.

---

### Layer 9: Persistence Layer (Shim)
**Purpose:** Abstract ArangoDB connection details; unified persistence interface.

```python
# arangodb_persistence.py
@dataclass
class ArangoDBConfig:
    host: str
    username: str
    password: str
    db_name: str

class ArangoDBGraphPersistence:
    def __init__(self, config: ArangoDBConfig)
    def connect() -> ArangoClient
    def get_collection(name: str) -> Collection
    def insert_vertex(collection: str, doc: Dict)
    def insert_edge(collection: str, from_vertex: str, to_vertex: str, props: Dict)
```

**Used By:** Manufacturing semantics entry points (018, 019, 020, 026), backup utilities.

---

### Layer 10: Utilities & Helpers
**Purpose:** Specialized graph operations, semantic reasoning, and domain logic.

| File | Responsibility |
|------|-----------------|
| `scripts/nx_to_arango.py` | Push NetworkX graphs into ArangoDB |
| `scripts/export_arango_to_networkx.py` | Export Arango graphs as NetworkX |
| `scripts/clean_arango.py`, `clean_graph_and_write.py` | Graph cleanup utilities |
| `scripts/query_arango_edges.py`, `remove_duplicate_edges.py` | Edge querying & deduplication |
| `hf-space-inventory-sqlgen/combined_graph_builder.py` | Merge multiple graph sources |
| `hf-space-inventory-sqlgen/semantic_reasoning.py` | Semantic traversal & inference |
| `hf-space-inventory-sqlgen/solder_engine.py`, `solder_engine_extended.py` | Intent-driven field binding logic |

---

### Layer 11: End-to-End Testing
**Purpose:** Integration tests validating the full pipeline from SQLMesh → ArangoDB.

| File | Responsibility |
|------|-----------------|
| `scripts/test_e2e_sqlmesh_to_arango.py` | E2E: DuckDB raw table → Arango bindings collection |
| `hf-space-inventory-sqlgen/test_graph_sync.py` | Unit tests for sync logic |
| `hf-space-inventory-sqlgen/test_graph_sync_live_smoke.py` | Smoke tests against live ArangoDB |
| `hf-space-inventory-sqlgen/test_graph_sync_ui.py` | Gradio UI integration tests |
| `hf-space-inventory-sqlgen/test_app_binding_contract_surfaces.py` | Contract validation tests |

---

## Critical Import Chains

### Primary: Layer 2 Hub → Downstream
```
graph_sync.py exports:
  ├─ sync_graph()
  ├─ get_arango_client()
  ├─ _filter_structure_data()
  └─ load_structure_sqlite_data()

Imported by:
  ├─ graph_sync_ui.py (Gradio UI wrapper)
  ├─ run_incremental_graph_sync_path.py (orchestration)
  ├─ safe_arango_rebuild.py (safe rebuild workflow)
  ├─ sync_arango_edges_with_graph.py (edge operations)
  ├─ legacy_graph_migration_plan.py (Stage 1 migration)
  └─ test_*.py (multiple test suites)
```

### Secondary: Binding Key Generation
```
graph_key_generation.py exports:
  ├─ compile_binding_key()
  └─ compile_binding_key_from_payload()

Used by:
  ├─ graph_sync.py (edge key compilation)
  ├─ test_logical_sync_contract_regression_unitTest.py
  └─ test_e2e_sqlmesh_to_arango.py
```

### Tertiary: DDL Parsing
```
load_erp_ddl_into_sqlite.py exports:
  └─ parse_ddl_file()

Used by:
  ├─ run_incremental_graph_sync_path.py
  └─ test_load_erp_ddl_into_sqlite.py
```

---

## Key Actors & Responsibilities

| Actor | Role |
|-------|------|
| **graph_sync.py** | Central sync engine; orchestrates metadata movement |
| **graph_sync_ui.py** | Gradio UI; exposes sync controls to end users |
| **run_incremental_graph_sync_path.py** | CLI entry point for incremental syncs |
| **initialize_lowercase_graph.py** | First-run setup; collection creation |
| **perspective_cleanup_strategy.py** | Legacy asset tracking & migration planning |
| **graph_key_generation.py** | Deterministic key compilation utility |
| **load_erp_ddl_into_sqlite.py** | DDL parsing & SQLite ingestion |
| **arangodb_persistence.py** | ArangoDB abstraction layer |
| **generate_graph_audit.py** | Audit reporting & validation |

---

## Environment Configuration

**Required Environment Variables:**

| Variable | Default | Purpose |
|----------|---------|---------|
| `ARANGO_HOST` | `http://127.0.0.1:8529` | ArangoDB server URL |
| `ARANGO_USER` | `root` | ArangoDB username |
| `ARANGO_PASSWORD` | — | **REQUIRED:** ArangoDB password |
| `ARANGO_DB` | `manufacturing_graph` | Target database name |
| `SQLMESH_PATH` | `Utilities/SQLMesh` | SQLMesh project root |
| `SQLITE_DB_PATH` | `hf-space-inventory-sqlgen/app_schema/manufacturing.db` | SQLite tracking database |

---

## Next Steps

1. **[01_Layer_Dependencies.md](01_Layer_Dependencies.md)** — Detailed dependency graph and import chains.
2. **[02_Data_Flow_Pipeline.md](02_Data_Flow_Pipeline.md)** — End-to-end data flow with visual swimlanes.
3. **[03_Binding_Key_Generation.md](03_Binding_Key_Generation.md)** — Binding key formula and normalization rules.
4. **[04_Legacy_Migration_Roadmap.md](04_Legacy_Migration_Roadmap.md)** — Stage 1 deprecation and migration strategy.
5. **[05_Running_the_POC.md](05_Running_the_POC.md)** — Operational guide and command reference.

---

## References

- **Graph Model:** ArangoDB multi-model (document + edge)
- **Data Sources:** SQL Server (LIVE, LIVEAccounting) via SQLMesh DuckDB backend
- **Semantic Layer:** SQLite (`manufacturing.db`)
- **Orchestration:** Python 3.9+, pytest for testing
- **Deployment:** Docker optional; can run standalone with env vars

