---
title: Running the POC - Operational Guide
version: 1.0
date: 2024-06-11
status: complete
---

# Running the POC: Step-by-Step Operational Guide

## Overview

This guide provides **command-by-command** instructions for running the SQL-Projects Graph Integration POC. All commands assume you're working in the SQL-Projects repository root on Windows (PowerShell).

---

## Prerequisites Checklist

Before starting, verify:

- [ ] Python 3.9+ installed (`python --version`)
- [ ] `.venv` virtual environment created (`python -m venv .venv`)
- [ ] Virtual environment activated (`.\.venv\Scripts\Activate.ps1`)
- [ ] Dependencies installed (`pip install -r requirements.txt`)
- [ ] ArangoDB 3.10+ running locally or accessible via network
- [ ] SQL Server LIVE & LIVEAccounting databases accessible
- [ ] `.env` file populated with credentials (see Environment Configuration)

---

## Environment Configuration

### Create .env File

**File:** `scripts/.env` (or repo root `.env`)

```bash
# ArangoDB
ARANGO_HOST=http://127.0.0.1:8529
ARANGO_USER=root
ARANGO_PASSWORD=your_secure_password
ARANGO_DB=manufacturing_graph

# SQL Server (optional for DDL extraction)
MSSQL_CONNECTION_STRING=Server=YOUR_SERVER;Database=LIVE;Integrated Security=true;TrustServerCertificate=true

# SQLMesh
SQLMESH_PATH=Utilities/SQLMesh

# SQLite tracking DB
SQLITE_DB_PATH=hf-space-inventory-sqlgen/app_schema/manufacturing.db
```

### Load Environment Variables

```powershell
# In PowerShell session
$env:ARANGO_HOST = "http://127.0.0.1:8529"
$env:ARANGO_USER = "root"
$env:ARANGO_PASSWORD = "your_password"
$env:ARANGO_DB = "manufacturing_graph"

# Or use dotenv
pip install python-dotenv
# Automatically loaded by scripts on import
```

---

## Step-by-Step Execution

### Step 1: Start ArangoDB (One-Time Setup)

**Goal:** Ensure ArangoDB server is running.

```powershell
# Option A: Docker (easiest)
docker run -d -p 8529:8529 -e ARANGO_ROOT_PASSWORD=your_password arangodb/arangodb:latest

# Option B: Local ArangoDB installation (Windows)
# Start ArangoDB service via Services app or:
net start arangodb3

# Option C: Manual start (development)
# Download from https://www.arangodb.com/download/
# Unzip and run: .\bin\arangod.exe --console

# Verify: Open browser to http://127.0.0.1:8529
# Login: root / your_password
```

---

### Step 2: Initialize the Graph Database (First Run Only)

**Goal:** Create ArangoDB database, collections, and graph structure.

```powershell
# Activate virtual environment
cd c:\Users\williamt\source\skillsinc\skills-inc-org\SQL-Projects
.\.venv\Scripts\Activate.ps1

# Run initialization script
python scripts/initialize_lowercase_graph.py

# Expected output:
#   ✔ Created lowercase Document collection: 'fields'
#   ✔ Lowercase Document collection 'concepts' already exists.
#   ✔ Lowercase Document collection 'intents' already exists.
#   🚀 Created CRITICAL lowercase Edge collection: 'bindings'
#   ...
```

**Verification:**
```powershell
# Check collections exist in ArangoDB
python -c "
import sys
sys.path.insert(0, 'hf-space-inventory-sqlgen')
from graph_sync import get_arango_client, GRAPH_NAME
client = get_arango_client()
db = client.db(GRAPH_NAME, username='root', password='your_password')
print('Collections:', [c['name'] for c in db.collections()])
"
```

---

### Step 3: Extract Canonical DDL from SQL Server (First Run)

**Goal:** Generate authoritative DDL files from SQL Server schema.

```powershell
# Option A: Use PowerShell script (automated)
$ErrorActionPreference = 'Stop'
$serverInstance = "YOUR_SERVER"
$databases = @('LIVE', 'LIVEAccounting')
$outputDir = ".\Utilities\SQLMesh\ddl"
$useIntegratedAuth = $true
$trustCert = $true

& ".\Documentation\Schema\ddl-extract\extract-schema.ps1" `
    -ServerInstance $serverInstance `
    -Databases $databases `
    -OutputDir $outputDir `
    -UseIntegratedAuth:$useIntegratedAuth `
    -TrustServerCertificate:$trustCert

# Option B: Manual (if PowerShell script unavailable)
# Import DDL manually; verify files exist:
dir Utilities\SQLMesh\ddl\*.sql | head -10

# Expected files:
#   dbo.WORK_ORDER.sql
#   dbo.OPERATION.sql
#   dbo.RESOURCE.sql
#   dbo.PART.sql
#   ... (one file per table)
```

**Verification:**
```powershell
# Check DDL files exist and are valid SQL
ls Utilities\SQLMesh\ddl\ | measure-object | select count
# Should show >50 DDL files

# Spot-check a file
gc Utilities\SQLMesh\ddl\dbo.WORK_ORDER.sql | head -20
```

---

### Step 4: Load DDL into SQLite Tracking Database

**Goal:** Parse canonical DDL files; populate SQLite `schema_tables`, `schema_columns`, etc.

```powershell
# Run DDL loader
python scripts/load_erp_ddl_into_sqlite.py

# Expected output:
#   Parsing: dbo.WORK_ORDER.sql
#   ✓ Inserted 1 table record
#   ✓ Inserted 23 column records
#   ✓ Inserted 3 foreign key records
#   ...
#   Total: X tables, Y columns, Z foreign keys
```

**Verification:**
```powershell
# Query SQLite to verify loaded data
python -c "
import sqlite3
db = sqlite3.connect('hf-space-inventory-sqlgen/app_schema/manufacturing.db')
cursor = db.cursor()

# Count tables
tables = cursor.execute('SELECT COUNT(*) FROM schema_tables').fetchone()[0]
print(f'Tables: {tables}')

# Count columns
columns = cursor.execute('SELECT COUNT(*) FROM schema_columns').fetchone()[0]
print(f'Columns: {columns}')

# Count foreign keys
fks = cursor.execute('SELECT COUNT(*) FROM schema_foreign_keys').fetchone()[0]
print(f'Foreign Keys: {fks}')

db.close()
"
# Expected: 50+ tables, 500+ columns, 100+ foreign keys
```

---

### Step 5: Run SQLMesh Models (Optional - For Semantic Layer)

**Goal:** Materialize SQLMesh `raw_user_def_fields.py` and other raw models.

```powershell
# Navigate to SQLMesh project
cd Utilities\SQLMesh

# List available models
sqlmesh ls

# Materialize raw models
sqlmesh run --select raw.raw_user_def_fields

# Or run all raw models
sqlmesh run --select raw.*

# Expected output:
#   Running: raw__dev.raw_user_def_fields
#   ✓ Created table (XX rows)
#   Running: raw__dev.raw_matrix_driven
#   ✓ Created table (YY rows)

# Return to repo root
cd ..\..
```

**Verification:**
```powershell
# Query DuckDB to verify materialized data
python -c "
import duckdb
con = duckdb.connect(':memory:')

# Attach DuckDB from SQLMesh
con.execute('PRAGMA database_list')

# Query raw model
try:
    result = con.execute('SELECT COUNT(*) FROM raw__dev.raw_user_def_fields').fetchall()
    print(f'raw_user_def_fields rows: {result[0][0]}')
except:
    print('raw_user_def_fields not yet materialized (optional)')
"
```

---

### Step 6: Run Core Graph Sync (Dry-Run First)

**Goal:** Test graph sync without modifying ArangoDB; verify counts.

```powershell
# Dry-run: count vertices/edges ready to sync
cd hf-space-inventory-sqlgen
python graph_sync.py --dry-run --structure-only

# Expected output:
#   [DRY RUN]
#   Vertices ready: X (manufacturing_graph_node)
#   Edges ready: Y (ATOMIC_FK)
#   Ready to sync to ArangoDB

cd ..
```

**Advanced Options:**
```powershell
# Dry-run with table filter (single table)
cd hf-space-inventory-sqlgen
python graph_sync.py --dry-run --table WORK_ORDER

# Dry-run with full semantic layer (intents, perspectives, concepts, bindings)
python graph_sync.py --dry-run

cd ..
```

---

### Step 7: Execute Live Graph Sync

**Goal:** Synchronize DDL metadata to ArangoDB (write operation).

```powershell
# Live sync: create/update vertices and edges in ArangoDB
cd hf-space-inventory-sqlgen
python graph_sync.py

# Expected output:
#   [LIVE SYNC]
#   ✓ Connected to ArangoDB (manufacturing_graph)
#   ✓ Syncing manufacturing_graph_node vertices
#   ✓ Syncing ATOMIC_FK edges
#   ✓ Syncing semantic collections (intents, perspectives, concepts, ...)
#   ✓ Syncing Column_Bindings edges (logical contract)
#   
#   Summary:
#   Vertices synced: ABC
#   Edges synced: XYZ
#   Success: True

cd ..
```

**Options:**
```powershell
cd hf-space-inventory-sqlgen

# Sync only structure (tables & FKs), skip semantic layer
python graph_sync.py --structure-only

# Sync single table and its dependencies
python graph_sync.py --table WORK_ORDER --max-depth 2

cd ..
```

---

### Step 8: Verify Sync in ArangoDB Web UI

**Goal:** Visually confirm vertices and edges were created.

```powershell
# 1. Open browser: http://127.0.0.1:8529
# 2. Login: root / your_password
# 3. Select database: manufacturing_graph
# 4. Collections tab:
#    ✓ manufacturing_graph_node (50+ documents)
#    ✓ ATOMIC_FK (100+ documents)
#    ✓ intents (1–10 documents)
#    ✓ perspectives (1–10 documents)
#    ✓ concepts (10–100 documents)
#    ✓ fields (100–1000 documents)
#    ✓ Column_Bindings (100–1000 documents)
# 5. Graphs tab:
#    ✓ manufacturing_graph (should show in list)
#    ✓ Visualize to explore relationships
```

---

### Step 9: Run Audit & Generate Report

**Goal:** Validate sync success; generate audit markdown.

```powershell
# Generate audit report
python scripts/generate_graph_audit.py

# Expected output:
#   Reading SQLite schema...
#   Querying ArangoDB...
#   Coverage analysis...
#   Writing graph_audit.md (repo root)
#
# Output file: graph_audit.md (tab-delimited coverage matrix)
```

**Review Audit:**
```powershell
# Open and inspect audit report
type graph_audit.md | head -50

# Expected sections:
# 1. Summary (counts, success)
# 2. Vertex coverage (tables synced, missing)
# 3. Edge coverage (FKs synced, missing)
# 4. Validation results (✓ all checks pass)
```

---

### Step 10: Run Tests (Comprehensive Validation)

**Goal:** Execute full test suite to validate all layers.

```powershell
# All tests
python -m pytest . -v

# Or run specific test suites:

# Unit tests (fast)
python -m pytest scripts/test_graph_key_generation.py -v

# DDL parsing tests
python -m pytest scripts/test_load_erp_ddl_into_sqlite.py -v

# Graph sync tests
python -m pytest hf-space-inventory-sqlgen/test_graph_sync.py -v

# Legacy migration tests
python -m pytest scripts/test_legacy_graph_migration_plan_unitTest.py -v

# E2E tests (slow; requires live ArangoDB)
python -m pytest scripts/test_e2e_sqlmesh_to_arango.py -v -s

# Expected: All tests PASS
```

---

## Gradio UI Mode (Optional)

**Goal:** Run graph sync via Gradio web interface.

```powershell
# Start FastAPI + Gradio app
cd hf-space-inventory-sqlgen
python app.py

# Expected output:
#   Running on http://0.0.0.0:7860
#   Gradio app started successfully
#   Navigate to: http://127.0.0.1:7860

# In browser:
# 1. Open http://127.0.0.1:7860
# 2. "Graph Sync" tab:
#    - Toggle "Dry Run" checkbox
#    - Enter table filter (optional)
#    - Click "Run Graph Sync"
# 3. View results in report area
# 4. Check ArangoDB Web UI for updates

# Press Ctrl+C to stop
```

---

## Incremental Sync Workflow

**Goal:** Add new table to graph after initial setup.

```powershell
# 1. Assume new table "INVOICE" added to SQL Server
# 2. Extract DDL manually or via PowerShell script
# 3. Place DDL file: Utilities\SQLMesh\ddl\dbo.INVOICE.sql

# 4. Run incremental sync
cd hf-space-inventory-sqlgen
python ../scripts/run_incremental_graph_sync_path.py --table INVOICE --live-sync

# Expected output:
#   Resolving DDL: Utilities\SQLMesh\ddl\dbo.INVOICE.sql
#   Parsing DDL...
#   Loading into SQLite...
#   Syncing INVOICE vertex + 5 FK edges to ArangoDB
#   ✓ Success
```

---

## Troubleshooting

### Issue 1: "Failed to connect to ArangoDB"

**Symptoms:**
```
ConnectionError: [Errno 10061] No connection could be made because the target machine actively refused it
```

**Solutions:**
1. Verify ArangoDB is running: `http://127.0.0.1:8529` in browser
2. Check credentials in `.env`: `ARANGO_PASSWORD` is set
3. Verify network: `ping 127.0.0.1`
4. Restart ArangoDB: `net stop arangodb3 && net start arangodb3`

---

### Issue 2: "FileNotFoundError: manufacturing.db not found"

**Symptoms:**
```
FileNotFoundError: [Errno 2] No such file or directory: 'hf-space-inventory-sqlgen/app_schema/manufacturing.db'
```

**Solutions:**
1. Run Step 4 first (load DDL into SQLite)
2. Verify path: `ls hf-space-inventory-sqlgen/app_schema/`
3. Create manually: `python -m sqlite3 hf-space-inventory-sqlgen/app_schema/manufacturing.db ".schema"`

---

### Issue 3: "ValueError: perspective must contain at least 1 alphanumeric character"

**Symptoms:**
```
ValueError: perspective must contain at least 1 alphanumeric character
```

**Solutions:**
1. Check input data in SQLite: `SELECT perspective FROM ... WHERE perspective IS NULL OR perspective = ''`
2. Clean perspective column: `UPDATE ... SET perspective = 'general' WHERE perspective = ''`
3. Rerun graph sync

---

### Issue 4: "Regex parse failure: unparseable DDL"

**Symptoms:**
```
[WARN] Unparseable DDL: dbo.SOME_TABLE.sql (line 42)
```

**Solutions:**
1. Inspect DDL file manually: `type Utilities\SQLMesh\ddl\dbo.SOME_TABLE.sql`
2. Check for edge-case SQL syntax (e.g., comments, CTEs, non-standard types)
3. Re-generate DDL from SQL Server (may have schema drift)
4. Log the issue; extract table manually as workaround

---

### Issue 5: "Duplicate key violation in ArangoDB"

**Symptoms:**
```
ArangoServerError: [ERR 1210] unique constraint violated
```

**Solutions:**
1. Sync ran twice with same data → Normal; graph is idempotent (safe to rerun)
2. Delete existing collection: `python scripts/clean_arango.py --collection manufacturing_graph_node`
3. Rerun sync

---

### Issue 6: "SQLMesh model not materialized"

**Symptoms:**
```
DatabaseError: No such table: raw__dev.raw_user_def_fields
```

**Solutions:**
1. Navigate to `Utilities\SQLMesh` and run: `sqlmesh run --select raw.raw_user_def_fields`
2. Verify model exists: `sqlmesh ls | grep raw_user_def_fields`
3. Check for compilation errors: `sqlmesh lint`

---

## Monitoring & Performance

### Monitor ArangoDB Query Performance

```powershell
# Query slow-log
python -c "
import sys
sys.path.insert(0, 'hf-space-inventory-sqlgen')
from graph_sync import get_arango_client, GRAPH_NAME

client = get_arango_client()
db = client.db(GRAPH_NAME, ...)

# Example: Slow graph traversal
result = db.aql.execute(
    '''
    FOR vertex IN GRAPH 'manufacturing_graph'
        RETURN COUNT(vertex)
    ''',
    profile=True  # Enable profiling
)
print(result.profile)
"
```

### Monitor Graph Size

```powershell
# Vertex/edge counts
python -c "
import sys
sys.path.insert(0, 'hf-space-inventory-sqlgen')
from graph_sync import get_arango_client, GRAPH_NAME

client = get_arango_client()
db = client.db(GRAPH_NAME, ...)

# Count collections
for coll_name in db.collections():
    coll = db.collection(coll_name)
    print(f'{coll_name}: {len(coll)} documents')
"
```

---

## Backup & Recovery

### Backup ArangoDB Graph

```powershell
# Export full graph to JSON
python scripts/export_arango_to_networkx.py --output manufacturing_graph_backup.json

# Or use native ArangoDB dump
docker exec arangodb arangodump --output-directory /backup --overwrite true

# Or via web UI: http://127.0.0.1:8529 → Tools → Export
```

### Restore Graph from Backup

```powershell
# Restore from JSON
python -c "
import sys
import json
from pathlib import Path
sys.path.insert(0, 'hf-space-inventory-sqlgen')
from graph_sync import get_arango_client, GRAPH_NAME

with open('manufacturing_graph_backup.json') as f:
    backup = json.load(f)

client = get_arango_client()
db = client.db(GRAPH_NAME, ...)

# Restore vertices
for vertex in backup['vertices']:
    collection = db.collection(vertex['collection'])
    collection.insert(vertex['data'])

# Restore edges
for edge in backup['edges']:
    collection = db.collection(edge['collection'])
    collection.insert(edge['data'])

print('Restored successfully')
"

# Or via native ArangoDB restore
docker exec arangodb arangorestore --input-directory /backup
```

---

## Command Quick Reference

| Task | Command |
|------|---------|
| Start ArangoDB | `docker run -d -p 8529:8529 arangodb/arangodb` |
| Initialize graph | `python scripts/initialize_lowercase_graph.py` |
| Extract DDL | `& ".\Documentation\Schema\ddl-extract\extract-schema.ps1" ...` |
| Load DDL into SQLite | `python scripts/load_erp_ddl_into_sqlite.py` |
| Dry-run sync | `cd hf-space-inventory-sqlgen && python graph_sync.py --dry-run` |
| Live sync | `cd hf-space-inventory-sqlgen && python graph_sync.py` |
| Generate audit | `python scripts/generate_graph_audit.py` |
| Run all tests | `python -m pytest . -v` |
| Run Gradio UI | `cd hf-space-inventory-sqlgen && python app.py` |
| Clean graph | `python scripts/clean_arango.py --collection manufacturing_graph_node` |
| Check collections | `python scripts/list_arango_collections.py` |
| Export graph | `python scripts/export_arango_to_networkx.py --output backup.json` |
| Verify Arango | `python scripts/verify_arango.py` |
| Incremental sync | `python scripts/run_incremental_graph_sync_path.py --table TABLE_NAME --live-sync` |

---

## Next Steps After Initial Setup

1. **Explore graph:** Open ArangoDB Web UI at http://127.0.0.1:8529; visualize vertices/edges
2. **Run queries:** Test AQL queries against graph (see [02_Data_Flow_Pipeline.md](02_Data_Flow_Pipeline.md))
3. **Stage 1 migration:** If ready, begin legacy asset deprecation (see [04_Legacy_Migration_Roadmap.md](04_Legacy_Migration_Roadmap.md))
4. **Integrate downstream:** Connect Solder engine, semantic reasoning, or HF Space app
5. **Production deployment:** Plan for containerization, CD/CI, and monitoring

---

## References & Support

| Resource | Link |
|----------|------|
| **Architecture Overview** | [00_POC_Ecosystem_Overview.md](00_POC_Ecosystem_Overview.md) |
| **Dependency Graph** | [01_Layer_Dependencies.md](01_Layer_Dependencies.md) |
| **Data Flow Diagram** | [02_Data_Flow_Pipeline.md](02_Data_Flow_Pipeline.md) |
| **Binding Key Formula** | [03_Binding_Key_Generation.md](03_Binding_Key_Generation.md) |
| **Legacy Migration** | [04_Legacy_Migration_Roadmap.md](04_Legacy_Migration_Roadmap.md) |
| **ArangoDB Docs** | https://www.arangodb.com/docs/ |
| **SQLMesh Docs** | https://sqlmesh.readthedocs.io/ |
| **GitHub Issues** | SQL-Projects repo issues (use `[graph-poc]` label) |

---

**Last Updated:** 2024-06-11  
**POC Version:** 1.0  
**Status:** Production Ready ✓

