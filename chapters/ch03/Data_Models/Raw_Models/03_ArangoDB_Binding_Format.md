# ArangoDB Binding Format & Graph Integration

## Overview

The **bindings** edge collection in ArangoDB stores semantic relationships between user-defined fields and their conceptual targets. This document details the edge document structure, key generation logic, graph traversal patterns, and insertion workflow.

---

## ArangoDB Setup

### Database & Collection Initialization

**Database**: `manufacturing_graph` (created by nx_to_arango.py)

**Collections**:
- `field_components` (vertex collection) - source node namespace
- `concepts` (vertex collection) - target node namespace
- `bindings` (edge collection) - semantic relationships

### Collection Structure

```
field_components/                     concepts/
├─ field_components/user_def_fields  ├─ concepts/part_number
├─ field_components/operation        ├─ concepts/description
├─ field_components/item             ├─ concepts/quantity_on_hand
└─ ...                               └─ ...
```

**Edge flow**: `field_components/* --[bindings]--> concepts/*`

---

## Edge Document Structure

### Complete Field Reference

```json
{
  "_key": "user_def_fields::user_def_fields_to_part_number::seq_42::engineering",
  "_from": "field_components/user_def_fields",
  "_to": "concepts/part_number",
  "binding_key": "user_def_fields::user_def_fields_to_part_number::seq_42::engineering",
  "perspective": "engineering",
  "category": "engineering",
  "logic_type": "conditional_case",
  "program_id": "vmprtmnt",
  "udf_id": "udf-42",
  "friendly_label": "Part Number",
  "poly_type": "string",
  "aliased_to": "part_number",
  "source_value_column": "string_val"
}
```

### Field Descriptions

| Field | Type | Required | Example | Purpose |
|---|---|---|---|---|
| `_key` | string | ✅ Yes | `user_def_fields::user_def_...` | Unique edge identifier (deterministic) |
| `_from` | string | ✅ Yes | `field_components/user_def_fields` | Source vertex reference |
| `_to` | string | ✅ Yes | `concepts/part_number` | Target vertex reference |
| `binding_key` | string | ✅ Yes | `user_def_fields::user_def_...` | Semantic binding identifier (same as `_key`) |
| `perspective` | string | ✅ Yes | `engineering` | Domain/viewpoint (e.g., engineering, accounting, sales) |
| `category` | string | ✅ Yes | `engineering` | Classification (typically matches perspective) |
| `logic_type` | string | ✅ Yes | `conditional_case` | Relationship type (e.g., conditional_case, direct_map, computed) |
| `program_id` | string | ✅ Yes | `vmprtmnt` | Originating program identifier (from raw_user_def_fields.program_id) |
| `udf_id` | string | ✅ Yes | `udf-42` | User-defined field ID (from raw_user_def_fields.id) |
| `friendly_label` | string | ✅ Yes | `Part Number` | Human-readable label (from raw_user_def_fields.label) |
| `poly_type` | string | ✅ Yes | `string` | Polymorphic type (boolean, numeric, string, list) |
| `aliased_to` | string | ✅ Yes | `part_number` | Normalized concept alias (target node name) |
| `source_value_column` | string | ✅ Yes | `string_val` | DuckDB DataFrame column containing the value |

---

## Binding Key Generation

### Key Compilation Function

**Location**: `scripts/test_e2e_sqlmesh_to_arango.py`

```python
def compilePerspectiveBindingKey(binding_meta: dict) -> str:
    """
    Generates a deterministic unique graph edge key for the semantic layer,
    formatting it purely lowercase to enforce consistent graph matching rules.
    """
    type_sel = binding_meta.get("typeSelection", "udf").lower()
    source = binding_meta.get("sourceEntity", "unknown").lower()
    target = binding_meta.get("targetEntity", "unknown").lower()
    seq = binding_meta.get("sequenceNumber", 0)
    cat = binding_meta.get("categorySlug", "general").lower()
    
    # Generate a reproducible, clean alphanumeric binding key string
    raw_key = f"{type_sel}::{source}_to_{target}::seq_{seq}::{cat}"
    clean_key = re.sub(r'[^a-z0-9_:]', '', raw_key.replace(" ", "_"))
    return clean_key
```

### Key Format

**Template**: `{typeSelection}::{sourceEntity}_to_{targetEntity}::seq_{sequenceNumber}::{categorySlug}`

**Component meanings**:
- `typeSelection` - Semantic type (e.g., "User_Def_Fields") → lowercased
- `sourceEntity` - Source table/field (e.g., "user_def_fields") → lowercased
- `targetEntity` - Target concept (e.g., "part_number") → lowercased + sanitized
- `sequenceNumber` - Ordinal identifier (e.g., 42) → integer
- `categorySlug` - Domain category (e.g., "engineering") → lowercased

### Key Generation Examples

**Example 1: Simple UDF binding**
```python
binding_meta = {
    "typeSelection": "User_Def_Fields",
    "sourceEntity": "user_def_fields",
    "targetEntity": "Part Number",
    "sequenceNumber": 42,
    "categorySlug": "engineering"
}
key = compilePerspectiveBindingKey(binding_meta)
# Result: "user_def_fields::user_def_fields_to_part_number::seq_42::engineering"
```

**Example 2: With special characters in target**
```python
binding_meta = {
    "typeSelection": "User_Def_Fields",
    "sourceEntity": "user_def_fields",
    "targetEntity": "Qty. on Hand (SQ)",
    "sequenceNumber": 15,
    "categorySlug": "inventory"
}
key = compilePerspectiveBindingKey(binding_meta)
# Intermediate: "user_def_fields::user_def_fields_to_qty_on_hand_sq::seq_15::inventory"
# Final (cleaned): "user_def_fields::user_def_fields_to_qty_on_hand_sq::seq_15::inventory"
```

**Example 3: VMPRTMNT program bindings**
```python
binding_meta = {
    "typeSelection": "User_Def_Fields",
    "sourceEntity": "user_def_fields",
    "targetEntity": "Equipment ID",
    "sequenceNumber": 5,
    "categorySlug": "maintenance"
}
key = compilePerspectiveBindingKey(binding_meta)
# Result: "user_def_fields::user_def_fields_to_equipment_id::seq_5::maintenance"
```

---

## Concept Alias Generation

### Alias Normalization

**Location**: `scripts/test_e2e_sqlmesh_to_arango.py`

```python
# Input: friendly_label from raw_user_def_fields.label
concept_alias = label.lower()\
    .replace(" (sq in)", "")\              # Remove (SQ IN) suffixes
    .replace(":", "")\                     # Remove colons
    .replace(" ", "_")\                    # Replace spaces with underscores
    .strip()
concept_alias = re.sub(r'[^a-z0-9_]', '', concept_alias)  # Remove non-alphanumeric
```

### Alias Examples

| Input Label | Alias |
|---|---|
| "Part Number" | `part_number` |
| "Qty. on Hand (SQ IN)" | `qty_on_hand_sq_in` → `qty_on_hand` |
| "Equipment ID: Maintenance" | `equipment_id_maintenance` |
| "Description (Multi-Line)" | `description_multi_line` |
| "Status/Phase" | `statusphase` |

---

## Type Mapping

### Data Type → Polymorphic Type

**Location**: `scripts/test_e2e_sqlmesh_to_arango.py`

```python
type_map = {
    1: "boolean",
    3: "numeric",
    5: "string",
    1005: "list"
}

col_map = {
    1: "bool_val",           # Boolean values stored in bool_val column
    3: "number_val",         # Numeric values stored in number_val column
    5: "string_val",         # String values stored in string_val column
    1005: "string_val"       # List values stored in string_val column
}
```

### Type Mapping Decision Logic

```python
poly_type = type_map.get(data_type, "string")    # Default: string
source_col = col_map.get(data_type, "string_val")  # Default: string_val

# For each row:
for prog_id, udf_id, data_type, label in scd_definitions:
    poly_type = type_map.get(data_type, "string")
    source_col = col_map.get(data_type, "string_val")
    # Edge document includes poly_type and source_value_column
```

### Type Mapping Examples

| data_type | poly_type | source_col | Use Case |
|---|---|---|---|
| 1 | boolean | bool_val | True/False flags |
| 3 | numeric | number_val | Quantities, prices |
| 5 | string | string_val | Names, codes, descriptions |
| 1005 | list | string_val | Multi-select values |
| (other) | string | string_val | Default fallback |

---

## Insertion Workflow

### Code: Edge Insertion Loop

**Location**: `scripts/test_e2e_sqlmesh_to_arango.py`

```python
inserted_count = 0
for prog_id, udf_id, data_type, label in scd_definitions:
    poly_type = type_map.get(data_type, "string")
    source_col = col_map.get(data_type, "string_val")
    
    # 1. Normalize concept alias
    concept_alias = label.lower()\
        .replace(" (sq in)", "")\
        .replace(":", "")\
        .replace(" ", "_")\
        .strip()
    concept_alias = re.sub(r'[^a-z0-9_]', '', concept_alias)

    # 2. Compile deterministic key
    compiled_key = compilePerspectiveBindingKey({
        "typeSelection": "User_Def_Fields",
        "sourceEntity": "user_def_fields",
        "targetEntity": concept_alias,
        "sequenceNumber": int(udf_id.split("-")[-1]) if '-' in udf_id else 0,
        "categorySlug": "engineering"
    })

    # 3. Build edge document
    edge_data = {
        "_key": compiled_key,
        "_from": "field_components/user_def_fields",
        "_to": f"concepts/{concept_alias}",
        "binding_key": compiled_key,
        "perspective": "engineering",
        "category": "engineering",
        "logic_type": "conditional_case",
        "program_id": prog_id.lower(),
        "udf_id": udf_id.lower(),
        "friendly_label": label,
        "poly_type": poly_type,
        "aliased_to": concept_alias,
        "source_value_column": source_col
    }

    # 4. Insert into ArangoDB
    print(f"  ⚡ [{inserted_count + 1}/{total_records}] Mapping {udf_id} -> Alias: {concept_alias} (Type: {poly_type})", flush=True)
    db.collection("bindings").insert(edge_data)
    inserted_count += 1

print(f"🏁 Generation Pass Complete. Successfully verified {inserted_count} true edges in 'bindings'.", flush=True)
```

### Insertion Steps

1. **Load DuckDB data**: Query raw_user_def_fields materialized table
2. **For each row**: Extract (program_id, udf_id, data_type, label)
3. **Normalize alias**: Clean concept label into alphanumeric alias
4. **Extract sequence**: Parse udf_id (e.g., "UDF-42" → seq 42)
5. **Compile key**: Call compilePerspectiveBindingKey() with metadata
6. **Build document**: Create edge_data dictionary
7. **Insert**: db.collection("bindings").insert(edge_data)
8. **Log**: Print progress (count and mapping)

---

## Graph Query Patterns

### Query 1: Find All Concepts Mapped from UDFs

```aql
FOR edge IN bindings
  FILTER edge._from == "field_components/user_def_fields"
  RETURN {
    binding_key: edge.binding_key,
    target_concept: edge._to,
    friendly_label: edge.friendly_label,
    poly_type: edge.poly_type,
    source_column: edge.source_value_column
  }
```

### Query 2: Find Bindings by Program

```aql
FOR edge IN bindings
  FILTER edge.program_id == "vmprtmnt"
  SORT edge.binding_key
  RETURN edge
```

### Query 3: Traverse from Field Component to Concepts

```aql
FOR v, e, p IN 1..3 OUTBOUND "field_components/user_def_fields"
  bindings
  RETURN {
    path: p.vertices[*]._id,
    edges: p.edges[*].binding_key,
    final_concept: v._id
  }
```

### Query 4: Find Bindings by Type

```aql
FOR edge IN bindings
  FILTER edge.poly_type == "string"
  RETURN {
    udf_id: edge.udf_id,
    aliased_to: edge.aliased_to,
    friendly_label: edge.friendly_label
  }
```

---

## Data Validation Rules

### Rule 1: Required Fields
```python
assert all(k in edge_data for k in ["_key", "_from", "_to", "binding_key"])
```

### Rule 2: Vertex References Exist
```python
assert edge_data["_from"].startswith("field_components/")
assert edge_data["_to"].startswith("concepts/")
```

### Rule 3: Key Determinism
```python
# Same input metadata → same key
key1 = compilePerspectiveBindingKey(meta)
key2 = compilePerspectiveBindingKey(meta)
assert key1 == key2, "Key generation is non-deterministic"
```

### Rule 4: No Duplicate Keys
```python
# _key must be unique per collection
keys = set()
for edge in all_edges:
    assert edge["_key"] not in keys, f"Duplicate key: {edge['_key']}"
    keys.add(edge["_key"])
```

---

## Connection Configuration

### Environment Variables

```bash
export ARANGO_HOST="http://127.0.0.1:8529"
export ARANGO_USER="root"
export ARANGO_PASSWORD="my-secret-password"
export ARANGO_DB="manufacturing_graph"
```

### Python Connection

```python
from arango import ArangoClient

arango_host = os.getenv("ARANGO_HOST", "http://127.0.0.1:8529")
arango_user = os.getenv("ARANGO_USER", "root")
arango_password = os.getenv("ARANGO_PASSWORD")
arango_db = os.getenv("ARANGO_DB", "manufacturing_graph")

client = ArangoClient(hosts=arango_host)
db = client.db(arango_db, username=arango_user, password=arango_password)

# Clear previous edges (optional)
if db.has_collection("bindings"):
    db.collection("bindings").truncate()

# Insert new edges
db.collection("bindings").insert(edge_data)
```

---

## Error Handling

### Connection Errors

```python
try:
    db = client.db(arango_db, username=arango_user, password=arango_password)
except Exception as e:
    logging.error(f"Failed to connect to ArangoDB: {e}")
    raise
```

### Insertion Errors

```python
try:
    db.collection("bindings").insert(edge_data)
except Exception as e:
    logging.error(f"Failed to insert binding {edge_data.get('_key')}: {e}")
    # Decide: retry, skip, or fail
```

### Validation Errors

```python
if not concept_alias:
    logging.warning(f"Concept alias empty for label: {label}; skipping")
    continue
```

---

## References

- [Development Path Lineage](01_Development_Path_Lineage.md) (Phase 10-12: Binding Generation)
- [Import Dependency Graph](00_Import_Dependency_Graph.md)
- [Masking Matrix Schema](02_Masking_Matrix_Schema.md)
