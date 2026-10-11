---
title: SQL-Projects Graph Integration POC - Complete Documentation
version: 1.0
date: 2024-06-11
status: complete
---

# SQL-Projects Graph Integration POC: Complete Documentation Suite

## 📚 Documentation Index

Welcome to the comprehensive technical documentation for the SQL-Projects Graph Integration Proof of Concept (POC). This 6-part suite provides deep architectural insights, implementation details, and operational procedures for the entire ecosystem.

---

## 📄 Document Overview

### Part 1: [00_POC_Ecosystem_Overview.md](00_POC_Ecosystem_Overview.md)
**Purpose:** High-level architecture and layer responsibilities  
**Audience:** Architects, team leads, new contributors  
**Contains:**
- 11-layer architecture diagram
- Responsibility matrix for each layer
- Critical import chains
- Environment configuration

**Key Sections:**
- Complete layer diagram (ASCII + description)
- 11 specialized layer descriptions
- File responsibilities table
- Critical actors & their roles

---

### Part 2: [01_Layer_Dependencies.md](01_Layer_Dependencies.md)
**Purpose:** Detailed dependency graph and import relationships  
**Audience:** Backend developers, integration engineers  
**Contains:**
- Mermaid dependency diagram (11 layers + imports)
- File-to-file dependency matrix
- Python import chains (actual code)
- Circular dependency prevention patterns

**Key Sections:**
- Full Mermaid graph showing all imports
- Direct import chain from Layer 2 hub (graph_sync.py)
- DDL parsing chain (load_erp_ddl_into_sqlite.py)
- Binding key generation chain (graph_key_generation.py)
- Persistence layer chain (arangodb_persistence.py)
- Legacy migration chain
- Test import hierarchy

---

### Part 3: [02_Data_Flow_Pipeline.md](02_Data_Flow_Pipeline.md)
**Purpose:** End-to-end data movement with error handling  
**Audience:** Data engineers, operators, troubleshooters  
**Contains:**
- Swimlane diagram (Stage 1 → Stage 7)
- Stage-by-stage process descriptions
- Example: WORK_ORDER complete flow
- Error scenarios & recovery procedures

**Key Sections:**
- Swimlane sequence diagram (7 stages + actors)
- Detailed process: ERP DDL extraction → SQLite load → graph sync
- Code examples for each stage
- Error handling at each layer
- Complete data example (WORK_ORDER table flow)
- Error scenarios table with recovery steps

---

### Part 4: [03_Binding_Key_Generation.md](03_Binding_Key_Generation.md)
**Purpose:** Deterministic binding key compilation rules  
**Audience:** Semantic layer engineers, data scientists  
**Contains:**
- 5-segment key formula (LEFT_RIGHT_PATH_INTENT_PERSPECTIVE)
- Normalization rules for each segment
- Complete workflow example
- Graph usage patterns
- Unit test suite

**Key Sections:**
- Formula breakdown (5 segments + constraints)
- Normalization algorithms (3 rules + examples)
- Complete input → output example
- Graph usage: Column_Bindings edges
- Code reference (full graph_key_generation.py)
- Testing & validation suite

---

### Part 5: [04_Legacy_Migration_Roadmap.md](04_Legacy_Migration_Roadmap.md)
**Purpose:** Stage 1 deprecation plan for legacy graph assets  
**Audience:** Product owners, migration coordinators, downstream consumers  
**Contains:**
- Stage 1 assets (deprecate-first): bindings, bound_to, defined_by, filters
- Stage 2 assets (hold-for-rewrites): intents, perspectives, concepts
- Protected assets (do not modify)
- 3-phase migration timeline (v1.1 → v1.4)
- Code: legacy_graph_migration_plan.py

**Key Sections:**
- 4 Stage-1 deprecated assets (detailed)
- 3 Stage-2 held assets (protected)
- 3-phase migration timeline (weeks 1–10)
- Execution checklist
- Rollback plan
- FAQ (common questions)

---

### Part 6: [05_Running_the_POC.md](05_Running_the_POC.md)
**Purpose:** Step-by-step operational procedures  
**Audience:** Operators, DevOps, QA, first-time users  
**Contains:**
- Prerequisites checklist
- Environment setup
- 10 sequential execution steps (with expected output)
- Gradio UI mode
- Troubleshooting guide (6 common issues)
- Backup & recovery procedures
- Quick command reference table

**Key Sections:**
- Checklist (Python, venv, ArangoDB, SQL Server)
- .env configuration
- Step 1–10 with PowerShell commands & verification
- Gradio UI optional mode
- Incremental sync workflow
- Troubleshooting matrix (Issue → Symptoms → Solutions)
- Monitoring & performance
- Backup & recovery procedures
- Quick command reference

---

## 🗺️ Navigation Map

```
START HERE (New to POC?)
  ↓
[00_POC_Ecosystem_Overview.md] ← Architecture overview
  ↓
[05_Running_the_POC.md] ← Get it running (practical)
  ↓
[02_Data_Flow_Pipeline.md] ← Understand data movement
  ├→ [01_Layer_Dependencies.md] ← Deep dive: imports & relationships
  ├→ [03_Binding_Key_Generation.md] ← Semantic layer details
  └→ [04_Legacy_Migration_Roadmap.md] ← Plan migrations

ADVANCED / SPECIALIZED TOPICS
  ├→ [03_Binding_Key_Generation.md] ← Key compilation formula
  ├→ [01_Layer_Dependencies.md] ← Circular dependency prevention
  ├→ [04_Legacy_Migration_Roadmap.md] ← Migration strategy
  └→ [05_Running_the_POC.md#troubleshooting] ← Troubleshooting
```

---

## 🎯 Quick Start for Different Roles

### Architect / Tech Lead
**Start with:** [00_POC_Ecosystem_Overview.md](00_POC_Ecosystem_Overview.md)  
**Then read:** [01_Layer_Dependencies.md](01_Layer_Dependencies.md), [04_Legacy_Migration_Roadmap.md](04_Legacy_Migration_Roadmap.md)  
**Time commitment:** 30 minutes

### Backend Developer
**Start with:** [05_Running_the_POC.md](05_Running_the_POC.md) (Steps 1–5)  
**Then read:** [01_Layer_Dependencies.md](01_Layer_Dependencies.md), [03_Binding_Key_Generation.md](03_Binding_Key_Generation.md)  
**Time commitment:** 1–2 hours

### Data Engineer / Operator
**Start with:** [05_Running_the_POC.md](05_Running_the_POC.md) (Steps 1–10)  
**Then read:** [02_Data_Flow_Pipeline.md](02_Data_Flow_Pipeline.md)  
**Time commitment:** 1 hour (+ hands-on time)

### QA / Tester
**Start with:** [05_Running_the_POC.md](05_Running_the_POC.md#step-10-run-tests)  
**Then read:** [02_Data_Flow_Pipeline.md](02_Data_Flow_Pipeline.md#error-scenarios--recovery) (error scenarios)  
**Time commitment:** 30 minutes

### DevOps / SRE
**Start with:** [05_Running_the_POC.md](05_Running_the_POC.md#monitoring--performance)  
**Then read:** [00_POC_Ecosystem_Overview.md](00_POC_Ecosystem_Overview.md#environment-configuration)  
**Time commitment:** 30 minutes

---

## 📊 Architecture Snapshot

```
┌─────────────────────────────────────────────────────────────────────┐
│  LAYER 11: End-to-End Testing (test_e2e_sqlmesh_to_arango.py, ...)  │
├─────────────────────────────────────────────────────────────────────┤
│  LAYER 10: Utilities & Helpers (NetworkX, semantic reasoning, ...)   │
├─────────────────────────────────────────────────────────────────────┤
│  LAYER 9: Persistence (arangodb_persistence.py)                      │
├─────────────────────────────────────────────────────────────────────┤
│  LAYER 8: Audit & Validation (generate_graph_audit.py)              │
├─────────────────────────────────────────────────────────────────────┤
│  LAYER 7: Legacy Migration (perspective_cleanup_strategy.py)         │
├─────────────────────────────────────────────────────────────────────┤
│  LAYER 6: Orchestration (run_incremental_graph_sync_path.py)        │
├─────────────────────────────────────────────────────────────────────┤
│  LAYER 5: Graph Init (initialize_lowercase_graph.py)                 │
├─────────────────────────────────────────────────────────────────────┤
│  LAYER 4: Binding Keys (graph_key_generation.py) ← Utility Layer     │
├─────────────────────────────────────────────────────────────────────┤
│  LAYER 3: DDL & Schema (load_erp_ddl_into_sqlite.py, ...)            │
├─────────────────────────────────────────────────────────────────────┤
│  LAYER 2: Graph Sync Core ★ HUB (graph_sync.py) ← CENTRAL IMPORT    │
├─────────────────────────────────────────────────────────────────────┤
│  LAYER 1: SQLMesh Models (raw_user_def_fields.py, ...)              │
└─────────────────────────────────────────────────────────────────────┘
```

**Key Insights:**
- **Layer 2** (graph_sync.py) is the **central hub** — 9+ files import from it
- **Layer 4** (graph_key_generation.py) is a **utility** — no circular dependencies
- **Layers 5–11** are orchestration, testing, and infrastructure
- **Layers 1–3** are data sources and preparation

---

## 🔄 Data Flow at a Glance

```
SQL Server LIVE
    ↓
[Canonical DDL Files] (Utilities/SQLMesh/ddl/)
    ↓
[Layer 3: DDL Parser] → load_erp_ddl_into_sqlite.py
    ↓
[SQLite Semantic Layer] (hf-space-inventory-sqlgen/manufacturing.db)
    ↓
[Layer 4: Key Generation] → compile_binding_key()
    ↓
[Layer 2: Graph Sync Core] ★ sync_graph()
    ↓
[ArangoDB Graph] (manufacturing_graph database)
    ├─ Vertices: manufacturing_graph_node, intents, perspectives, concepts, fields
    ├─ Edges: operates_within, elevates, uses_definition, can_mean, Column_Bindings, ATOMIC_FK
    └─ Collections: HAS_COLUMN, bound_to (legacy), defined_by (legacy), filters (legacy)
    ↓
[Layer 8: Audit] → generate_graph_audit.py
```

---

## 📋 Key Concepts Reference

| Concept | Definition | Document |
|---------|-----------|----------|
| **Binding Key** | 5-segment deterministic identifier for semantic edges | [03_Binding_Key_Generation.md](03_Binding_Key_Generation.md) |
| **Graph Sync Core** | Central hub coordinating all sync operations (graph_sync.py) | [01_Layer_Dependencies.md](01_Layer_Dependencies.md) |
| **Semantic Layer** | SQLite database tracking intents, perspectives, field definitions | [02_Data_Flow_Pipeline.md](02_Data_Flow_Pipeline.md) |
| **Column_Bindings** | Logical edge collection storing field-to-concept bindings | [03_Binding_Key_Generation.md](03_Binding_Key_Generation.md) |
| **DDL Extraction** | Parsing SQL Server CREATE TABLE statements into structured metadata | [02_Data_Flow_Pipeline.md](02_Data_Flow_Pipeline.md#stage-1-erp-ddl-extraction) |
| **Legacy Asset** | Deprecated graph collection (bindings, bound_to, defined_by, filters) | [04_Legacy_Migration_Roadmap.md](04_Legacy_Migration_Roadmap.md) |
| **Stage 1 Migration** | Transition from legacy perspective traversal to logical component binding | [04_Legacy_Migration_Roadmap.md](04_Legacy_Migration_Roadmap.md) |
| **Dry-Run Sync** | Test graph sync without writing to ArangoDB | [05_Running_the_POC.md](05_Running_the_POC.md#step-6-run-core-graph-sync-dry-run-first) |

---

## 🛠️ Tools & Technologies

| Component | Role | Configuration |
|-----------|------|----------------|
| **SQL Server** | ERP source (LIVE, LIVEAccounting) | Via DDL extraction script |
| **SQLMesh** | Analytics engine (DuckDB-backed) | Utilities/SQLMesh/ |
| **SQLite** | Semantic layer & tracking DB | hf-space-inventory-sqlgen/app_schema/manufacturing.db |
| **ArangoDB** | Multi-model graph database | http://127.0.0.1:8529 (configurable) |
| **Python 3.9+** | Implementation language | .venv virtual environment |
| **FastAPI** | REST API (optional) | hf-space-inventory-sqlgen/app.py |
| **Gradio** | Web UI (optional) | hf-space-inventory-sqlgen/graph_sync_ui.py |

---

## ✅ Pre-Requisites Checklist

Before starting, verify:

- [ ] Python 3.9+ installed
- [ ] Virtual environment created (`.venv/`)
- [ ] Dependencies installed (`requirements.txt`)
- [ ] ArangoDB running (docker or local)
- [ ] SQL Server accessible (for DDL extraction; optional for testing)
- [ ] .env file configured with credentials
- [ ] Utilities/SQLMesh/ddl/ directory exists with DDL files

**Quick Setup:** See [05_Running_the_POC.md#prerequisites-checklist](05_Running_the_POC.md#prerequisites-checklist)

---

## 🚀 Quick Start Commands

```powershell
# Step 1: Activate venv
.\.venv\Scripts\Activate.ps1

# Step 2: Initialize graph database
python scripts/initialize_lowercase_graph.py

# Step 3: Load DDL into SQLite
python scripts/load_erp_ddl_into_sqlite.py

# Step 4: Dry-run graph sync
cd hf-space-inventory-sqlgen
python graph_sync.py --dry-run

# Step 5: Live sync
python graph_sync.py

# Step 6: Generate audit report
cd ..
python scripts/generate_graph_audit.py

# Step 7: View results
type graph_audit.md | head -50
```

**Detailed instructions:** See [05_Running_the_POC.md](05_Running_the_POC.md)

---

## 🔗 Cross-Document References

### From Overview → Implementation Details
```
[00_POC_Ecosystem_Overview.md]
  → "Layer 2 is the CENTRAL HUB"
  → See [01_Layer_Dependencies.md] for actual imports
```

### From Dependencies → Data Flow
```
[01_Layer_Dependencies.md]
  → "graph_sync.py imports graph_key_generation.py"
  → See [02_Data_Flow_Pipeline.md] for how keys are used
```

### From Data Flow → Binding Keys
```
[02_Data_Flow_Pipeline.md]
  → "Stage 5: Binding Key Compilation"
  → See [03_Binding_Key_Generation.md] for formula details
```

### From Binding Keys → Legacy Migration
```
[03_Binding_Key_Generation.md]
  → "Column_Bindings replaces bindings vertex"
  → See [04_Legacy_Migration_Roadmap.md] for migration plan
```

### From Migration → Operations
```
[04_Legacy_Migration_Roadmap.md]
  → "Phase 1: Populate Column_Bindings edges"
  → See [05_Running_the_POC.md] for how to execute
```

---

## 🐛 Troubleshooting Flowchart

```
Something not working?
  ↓
Check error message
  ├→ "Connection refused" → [05_Running_the_POC.md#issue-1](05_Running_the_POC.md#issue-1-failed-to-connect-to-arangodb)
  ├→ "File not found" → [05_Running_the_POC.md#issue-2](05_Running_the_POC.md#issue-2-filenotfounderror)
  ├→ "ValueError" → [05_Running_the_POC.md#issue-3](05_Running_the_POC.md#issue-3-valueerror)
  ├→ "Parse failure" → [05_Running_the_POC.md#issue-4](05_Running_the_POC.md#issue-4-regex-parse-failure)
  ├→ "Duplicate key" → [05_Running_the_POC.md#issue-5](05_Running_the_POC.md#issue-5-duplicate-key-violation)
  └→ "Model not found" → [05_Running_the_POC.md#issue-6](05_Running_the_POC.md#issue-6-sqlmesh-model-not-materialized)
```

---

## 📞 Support & Escalation

| Question Type | Document | Contact |
|---------------|----------|---------|
| "How do I...?" | [05_Running_the_POC.md](05_Running_the_POC.md) | Team lead |
| "Why is...?" | [02_Data_Flow_Pipeline.md](02_Data_Flow_Pipeline.md) or [04_Legacy_Migration_Roadmap.md](04_Legacy_Migration_Roadmap.md) | Architecture team |
| "What imports...?" | [01_Layer_Dependencies.md](01_Layer_Dependencies.md) | Backend team |
| "How do I generate keys?" | [03_Binding_Key_Generation.md](03_Binding_Key_Generation.md) | Semantic layer team |
| Something else | [00_POC_Ecosystem_Overview.md](00_POC_Ecosystem_Overview.md) | Product owner |

---

## 📝 Document Maintenance

| File | Last Updated | Status | Owner |
|------|--------------|--------|-------|
| 00_POC_Ecosystem_Overview.md | 2024-06-11 | ✓ Complete | Architecture |
| 01_Layer_Dependencies.md | 2024-06-11 | ✓ Complete | Backend |
| 02_Data_Flow_Pipeline.md | 2024-06-11 | ✓ Complete | Data Engineering |
| 03_Binding_Key_Generation.md | 2024-06-11 | ✓ Complete | Semantic Layer |
| 04_Legacy_Migration_Roadmap.md | 2024-06-11 | ✓ Complete | Product |
| 05_Running_the_POC.md | 2024-06-11 | ✓ Complete | DevOps/SRE |

**When to Update:**
- Architecture changes → Update 00_POC_Ecosystem_Overview.md + 01_Layer_Dependencies.md
- New data flow stages → Update 02_Data_Flow_Pipeline.md
- Key generation changes → Update 03_Binding_Key_Generation.md
- Migration plan updates → Update 04_Legacy_Migration_Roadmap.md
- New operational procedures → Update 05_Running_the_POC.md

---

## 📚 Additional Resources

### Official Documentation
- [ArangoDB Documentation](https://www.arangodb.com/docs/)
- [SQLMesh Documentation](https://sqlmesh.readthedocs.io/)
- [SQL Server Documentation](https://learn.microsoft.com/en-us/sql/sql-server/)

### Related Files in This Repo
- `Utilities/SQLMesh/ddl/` — Canonical DDL files
- `hf-space-inventory-sqlgen/app_schema/` — SQLite schema & reviewer manifest
- `scripts/` — Layer 3–8 implementation
- `Documentation/Schema/Data_Models/` — Business data models

### Configuration Files
- `.env` — Environment variables (credentials, paths)
- `dab-config.json` — DAB metadata server configuration
- `copilot-instructions.md` — GitHub Copilot conventions

---

## 🎓 Learning Path Recommendation

**Week 1: Foundation**
- Day 1–2: Read [00_POC_Ecosystem_Overview.md](00_POC_Ecosystem_Overview.md)
- Day 3: Follow [05_Running_the_POC.md](05_Running_the_POC.md) (Steps 1–5)
- Day 4–5: Explore ArangoDB Web UI; run Step 6–10

**Week 2: Deep Dive**
- Day 1–2: Read [01_Layer_Dependencies.md](01_Layer_Dependencies.md)
- Day 3–4: Read [02_Data_Flow_Pipeline.md](02_Data_Flow_Pipeline.md)
- Day 5: Read [03_Binding_Key_Generation.md](03_Binding_Key_Generation.md)

**Week 3: Advanced**
- Day 1–2: Read [04_Legacy_Migration_Roadmap.md](04_Legacy_Migration_Roadmap.md)
- Day 3–5: Modify POC (extend with custom data, layers, or integrations)

---

## 🏁 Success Criteria

After reading this documentation, you should be able to:

- [ ] **Understand** the 11-layer architecture and responsibilities of each layer
- [ ] **Identify** which imports/files are used by graph_sync.py (central hub)
- [ ] **Trace** data flow from SQL Server → SQLite → ArangoDB
- [ ] **Compile** deterministic binding keys using the 5-segment formula
- [ ] **Explain** the Stage 1 legacy migration plan
- [ ] **Execute** all 10 steps to run the POC (from scratch)
- [ ] **Troubleshoot** common issues using the provided guides
- [ ] **Navigate** this 6-part documentation suite efficiently

---

**Version:** 1.0  
**Last Updated:** 2024-06-11  
**Status:** Production Ready ✓  

**Next Step:** Choose your role above and start reading!

