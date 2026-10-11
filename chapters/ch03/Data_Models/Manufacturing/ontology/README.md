# Manufacturing Ontology and Neo4j Projection

This directory defines a portable semantic contract over certified Infor Visual tables. SQLMesh remains the authoritative typed fact boundary. Neo4j stores ontology-aligned nodes, relationships, document links, and agent provenance.

## Files

- `manufacturing.ttl`: OWL vocabulary for Parts, Work Orders, Operations, Requirements, Shop Resources, capacity, UDF definitions and values, external Documents, and Agent Runs.
- `manufacturing.shacl.ttl`: identity, datatype, cardinality, nonnegative-capacity, and exactly-one-UDF-payload constraints.
- `neo4j/schema.cypher`: Neo4j 5 constraints and indexes.
- `neo4j/import_sqlmesh.cypher`: idempotent APOC JDBC import from SQLMesh.
- `neo4j/context_ingestion.cypher`: parameterized document and agent-run ingestion.

`ShopResource` is the Infor entity. There is no synthetic Work Center or Machine hierarchy. `Operation` connects directly to `ShopResource`, and site capacity is represented by `ResourceCapacity`.

## Contract ownership and drift control

The canonical table/column boundary is the certified ERP schema catalog; SQLMesh raw
and staging models are the typed fact projections. This directory's `manufacturing.ttl`
owns the graph vocabulary, `manufacturing.shacl.ttl` owns graph shape expectations,
and the `neo4j/` Cypher scripts own projection and identity semantics. The app-backed
SQLite metadata and ArangoDB semantic graph continue to own intent, concept, and
perspective mappings; Neo4j graph edges do not become a replacement metadata authority.

Changes to classes, relationship types, key formats, joins, cardinalities, or mapping
rules require an explicit contract review before an execution wave. The reviewer
records the source schema evidence, affected SQLMesh projection, vocabulary/SHACL
impact, Cypher identity/join impact, app/metadata impact, migration or compatibility
decision, and acceptance evidence. Do not silently revise canonical documents to
fit an import result or infer a schema from sample production values. Plan 022A's
approved gates and [relationship coverage matrix](../../../../plan/plan-022A-extra/relationship_coverage_matrix.md)
must be reconciled with measured data rather than adjusted to pass.

Run the read-only structural drift check before merging related changes:

```powershell
& .\.venv\Scripts\python.exe scripts\check_manufacturing_ontology_contract.py
& .\.venv\Scripts\python.exe -m pytest scripts\test_manufacturing_ontology_contract.py -q
```

The CI check detects Neo4j labels/relationship types absent from the ontology,
SHACL terms absent from the vocabulary, and imported SQLMesh projections with no
graph model. It does **not** prove live source-to-graph parity, masking policy,
ArangoDB/SQLite intent parity, or idempotence; those require separate evidence and
approval. The receiver-pipeline parity verifier is not an ontology drift check.

## SQLMesh models

Bounded ODBC extraction models are in `Utilities/SQLMesh/models/raw/manufacturing_graph_sources.py`. The existing `raw.raw_user_def_fields` model supplies UDF rows. Graph-ready projections are in `Utilities/SQLMesh/models/staging/graph/`.

Each graph projection emits a stable `source_key`. Composite Work Order, Operation, and Requirement keys preserve every DDL primary-key component. `staging.graph_bom_explosion` recursively expands engineering-master requirements (`WORKORDER_TYPE = 'M'`) and prevents cycles by tracking the part path.

## Load order

1. Materialize the SQLMesh models:

   ```powershell
   & .\.venv\Scripts\sqlmesh.exe -p Utilities\SQLMesh plan dev
   & .\.venv\Scripts\sqlmesh.exe -p Utilities\SQLMesh run dev
   ```

2. Install APOC Extended and a compatible DuckDB JDBC driver in Neo4j's `plugins` directory. Allow `apoc.load.jdbc` in the Neo4j procedure configuration.
3. Run `neo4j/schema.cypher` once.
4. Supply `sqlmeshJdbcUrl`, for example `jdbc:duckdb:C:/repo/Utilities/SQLMesh/db.db`, and run `neo4j/import_sqlmesh.cypher`.
5. Submit connector-produced `$documents` and agent-produced `$agentRun` parameters to `neo4j/context_ingestion.cypher`.

The APOC import is idempotent: nodes use unique `sourceKey` values and relationships use `MERGE`.

## First graph question

The repository validates both polymorphic joins used here:

- `VMMFGWIN_WO` UDFs join through `W~BASE_ID~SUB_ID~LOT_ID~SPLIT_ID`.
- `VMPRTMNT` UDFs join through `PART.ID = USER_DEF_FIELDS.DOCUMENT_ID`.

```cypher
MATCH (workOrder:WorkOrder)-[:HAS_UDF]->(fai:UserDefinedField),
      (workOrder)-[:PRODUCES_PART]->(part:Part)-[:HAS_UDF]->(itar:UserDefinedField)
WHERE fai.programId = 'VMMFGWIN_WO'
  AND fai.fieldId = 'UDF-0000086'
  AND fai.booleanValue = false
  AND itar.programId = 'VMPRTMNT'
  AND itar.fieldId = 'UDF-0000040'
  AND itar.booleanValue = true
RETURN workOrder.sourceKey, workOrder.baseId, part.partId
ORDER BY workOrder.baseId;
```

## Ownership boundary

ERP values flow one way from SQL Server through SQLMesh into Neo4j. File connectors own external document retrieval and access control; the graph stores identifiers, hashes, and links rather than file contents. Agent runs append provenance and do not update ERP facts.
