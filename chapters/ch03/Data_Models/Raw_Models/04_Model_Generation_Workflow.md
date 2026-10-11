# Model Generation Workflow: Extending raw_* Models

## Overview

This document explains how the **generate_matrix_models.py** script creates new SQLMesh Python models dynamically from the masking_matrix.csv configuration. It details the code generation pipeline, customization points, and how to extend it with new raw models.

---

## Architecture

### Design Pattern: Template-Driven Code Generation

The workflow follows this pattern:

```
┌─────────────────────────────────────────┐
│  Read masking_matrix.csv                │
│  Extract distinct table_name entries    │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│  Read schema CSV (for column types)     │
│  Build table → columns mapping          │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│  For each table_name:                   │
│  - Sanitize name for Python filename    │
│  - Generate column definitions          │
│  - Populate MODEL_TEMPLATE              │
│  - Write raw_<table_name>.py file       │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│  Result: raw_operation.py               │
│          raw_vendor.py                  │
│          raw_item.py                    │
│          ... (one per distinct table)   │
└─────────────────────────────────────────┘
```

---

## Execution Flow

### Step 1: Discover Repository Root

**Location**: `scripts/generate_matrix_models.py` (main entry point)

```python
if __name__ == "__main__":
    parser = argparse.ArgumentParser(...)
    parser.add_argument("--masking-matrix", type=str, default=None, help="Path to masking_matrix.csv")
    parser.add_argument("--schema-csv", type=str, default=None, help="Path to schema CSV")
    parser.add_argument("--out-dir", type=str, default=None, help="Output directory")
    args = parser.parse_args()

    # Resolve paths relative to repository root
    repo_root = Path(__file__).resolve().parent.parent
    masking_matrix_path = Path(args.masking_matrix) if args.masking_matrix else \
        repo_root / "certificate_for_receiving" / "masking_matrix.csv"
    schema_csv_path = Path(args.schema_csv) if args.schema_csv else \
        repo_root / "SQL_Data_Schema" / "ERP_Schema" / "SchemaDocumentation_LIVE_Tables_20251124_101520.csv"
    output_dir = Path(args.out_dir) if args.out_dir else \
        repo_root / "Utilities" / "SQLMesh" / "models" / "raw"

    print(f"Repository root: {repo_root}")
    print(f"Masking matrix: {masking_matrix_path}")
    print(f"Schema CSV: {schema_csv_path}")
    print(f"Output directory: {output_dir}")
```

**Behavior**:
- Parse command-line arguments
- Resolve paths relative to repository root
- Default paths: masking_matrix.csv, schema CSV, output directory
- Print diagnostics

### Step 2: Read Table Names from Masking Matrix

**Code**: `generate_matrix_models.read_masking_matrix()`

```python
def read_masking_matrix(path: Path) -> List[str]:
    if not path.exists():
        raise FileNotFoundError(path)
    tables = set()
    with path.open("r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            tbl = (row.get("table_name") or "").strip()
            if tbl:
                tables.add(tbl)
    return sorted(tables)
```

**Example output**:
```python
[
    "OPERATION",
    "OPERATION_CODE",
    "VENDOR",
    "ITEM",
    "USER_DEF_FIELDS"
]
```

### Step 3: Load Schema Documentation

**Code**: `generate_matrix_models.read_schema_csv()`

```python
def read_schema_csv(path: Path) -> Dict[str, List[Dict[str, str]]]:
    """Return mapping table_name.lower() -> list of {column_name, data_type}"""
    if not path.exists():
        raise FileNotFoundError(path)
    mapping: Dict[str, List[Dict[str, str]]] = {}
    with path.open("r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            tbl = (row.get("TABLE_NAME") or row.get("table_name") or "").strip()
            col = (row.get("COLUMN_NAME") or row.get("column_name") or "").strip()
            dtype = (row.get("DATA_TYPE") or row.get("data_type") or "").strip().lower()
            if not tbl or not col:
                continue
            key = tbl.lower()
            mapping.setdefault(key, []).append({"column_name": col, "data_type": dtype})
    return mapping
```

**Example output**:
```python
{
    "operation": [
        {"column_name": "OPERATION_ID", "data_type": "int"},
        {"column_name": "WORKORDER_ID", "data_type": "int"},
        {"column_name": "SEQUENCE_NO", "data_type": "int"},
        {"column_name": "RESOURCE_ID", "data_type": "nvarchar"},
        ...
    ],
    "vendor": [
        {"column_name": "VENDOR_ID", "data_type": "int"},
        {"column_name": "VENDOR_NAME", "data_type": "nvarchar"},
        ...
    ],
    ...
}
```

### Step 4: Map SQL Types to SQLMesh Types

**Code**: `generate_matrix_models.TYPE_MAP`

```python
TYPE_MAP = {
    "int": "int",
    "bigint": "int",
    "smallint": "int",
    "tinyint": "int",
    "bit": "int",
    "nvarchar": "text",
    "varchar": "text",
    "char": "text",
    "nchar": "text",
    "text": "text",
    "decimal": "double",
    "numeric": "double",
    "money": "double",
    "float": "double",
    "real": "double",
    "datetime": "timestamp",
    "datetime2": "timestamp",
    "date": "timestamp",
    "time": "timestamp",
}
```

**Example conversions**:
- SQL `nvarchar(255)` → SQLMesh `text`
- SQL `decimal(10,2)` → SQLMesh `double`
- SQL `datetime2` → SQLMesh `timestamp`

### Step 5: Generate Column Definitions

**Code**: (from main generation loop)

```python
# For each table, build columns dict
for table_name in tables:
    columns = {}
    schema_cols = schema_mapping.get(table_name.lower(), [])
    
    for col_info in schema_cols:
        col_name = col_info["column_name"].lower()
        sql_type = col_info["data_type"].lower()
        sqlmesh_type = TYPE_MAP.get(sql_type, "text")
        columns[col_name] = sqlmesh_type
    
    # Add metadata columns
    columns.update({
        "receiving_id": "text",
        "receiver_id": "text",
        "cert_status": "text",
        "cert_version": "text",
    })
```

**Example output** (for OPERATION table):
```python
{
    "operation_id": "int",
    "workorder_id": "int",
    "sequence_no": "int",
    "resource_id": "text",
    "status": "text",
    ...
    "receiving_id": "text",
    "receiver_id": "text",
    "cert_status": "text",
    "cert_version": "text",
}
```

### Step 6: Sanitize Table Name for Filename

**Code**: `generate_matrix_models.sanitize_name()`

```python
def sanitize_name(name: str) -> str:
    return re.sub(r"[^0-9a-zA-Z_]+", "_", name.lower())
```

**Examples**:
- `USER_DEF_FIELDS` → `user_def_fields`
- `OPERATION-CODE` → `operation_code`
- `ITEM.MASTER` → `item_master`
- `Part/Number` → `part_number`

### Step 7: Populate Model Template

**Code**: MODEL_TEMPLATE (excerpt)

```python
MODEL_TEMPLATE = '''"""
Auto-generated SQLMesh model for table: {table}
Generated by scripts/generate_matrix_models.py
"""
from __future__ import annotations

import importlib
import os
import logging
from pathlib import Path
import typing as t

import pandas as pd
from sqlmesh import ExecutionContext, model

from Utilities.SQLMesh.models.raw import raw_user_def_fields as helper

_CONNECTION_STRING = os.environ.get("STAGING_ODBC", "Driver={{ODBC Driver 18 for SQL Server}};...")

_SELECT_SQL = """
SELECT
{columns}
FROM Staging.dbo.{table_upper} WITH (NOLOCK)
"""

@model(
    "raw.raw_{model_name}",
    kind="FULL",
    columns={columns_dict},
    grain=[{grain}],
    description="Auto-generated model for {table}; masking driven by certificate_for_receiving/masking_matrix.csv"
)
def execute(context: ExecutionContext, **kwargs: t.Any) -> pd.DataFrame:
    # ... (same as raw_user_def_fields.py)
    # Load cert, apply masking, return enriched DataFrame
```

**Template variables**:
- `{table}` - Original table name (e.g., "OPERATION")
- `{model_name}` - Sanitized name (e.g., "operation")
- `{table_upper}` - Upper case table name (e.g., "OPERATION")
- `{columns}` - SQL column SELECT list with aliases (AS lowercase)
- `{columns_dict}` - Python dict of column definitions
- `{grain}` - Grain columns (typically primary key)

### Step 8: Write File to Output Directory

**Code**: (from main generation loop)

```python
for table_name in tables:
    model_name = sanitize_name(table_name)
    output_file = output_dir / f"raw_{model_name}.py"
    
    # Populate template with actual values
    file_content = MODEL_TEMPLATE.format(
        table=table_name,
        model_name=model_name,
        table_upper=table_name.upper(),
        columns=generate_column_select_list(schema_cols),
        columns_dict=repr(columns_dict),
        grain=grain_list
    )
    
    with output_file.open("w", encoding="utf-8") as f:
        f.write(file_content)
    
    print(f"✅ Generated: {output_file}")
```

**Output files**:
```
Utilities/SQLMesh/models/raw/
├─ raw_user_def_fields.py  (template/manual)
├─ raw_operation.py        (generated)
├─ raw_vendor.py           (generated)
├─ raw_item.py             (generated)
└─ raw_*.py                (one per table)
```

---

## Extension Points

### How to Add a New Raw Model

**Scenario**: You need to load a new table `SUPPLIER_PORTAL` with masking rules.

#### Step 1: Add to Masking Matrix

**File**: `certificate_for_receiving/masking_matrix.csv`

```csv
table_name,column_name,masking_type
SUPPLIER_PORTAL,supplier_id,pseudonymize
SUPPLIER_PORTAL,contact_name,redact
SUPPLIER_PORTAL,email,redact
SUPPLIER_PORTAL,portal_access_level,keep
```

#### Step 2: Add Schema Rows (if needed)

**File**: `SQL_Data_Schema/ERP_Schema/SchemaDocumentation_LIVE_Tables_20251124_101520.csv`

```csv
TABLE_NAME,COLUMN_NAME,DATA_TYPE
SUPPLIER_PORTAL,SUPPLIER_ID,int
SUPPLIER_PORTAL,CONTACT_NAME,nvarchar
SUPPLIER_PORTAL,EMAIL,nvarchar
SUPPLIER_PORTAL,PORTAL_ACCESS_LEVEL,varchar
```

#### Step 3: Run Code Generation

```bash
cd c:\Users\williamt\source\skillsinc\skills-inc-org\SQL-Projects
python scripts/generate_matrix_models.py
```

**Output**:
```
✅ Generated: Utilities/SQLMesh/models/raw/raw_supplier_portal.py
```

#### Step 4: Verify Generated File

**Generated file**: `Utilities/SQLMesh/models/raw/raw_supplier_portal.py`

```python
@model(
    "raw.raw_supplier_portal",
    kind="FULL",
    columns={
        "supplier_id": "int",
        "contact_name": "text",
        "email": "text",
        "portal_access_level": "text",
        "receiving_id": "text",
        "receiver_id": "text",
        "cert_status": "text",
        "cert_version": "text",
    },
    grain=[],  # No explicit grain; infer from schema
    description="Auto-generated model for SUPPLIER_PORTAL; masking driven by..."
)
def execute(context: ExecutionContext, **kwargs: t.Any) -> pd.DataFrame:
    # ... loads SUPPLIER_PORTAL, applies masking, returns DataFrame
```

#### Step 5: Test the Model

```bash
cd Utilities/SQLMesh
sqlmesh plan
sqlmesh run --model raw.raw_supplier_portal
```

---

## Customization: Modifying the Template

### Use Case 1: Add Custom Grain Column

**Current template** uses generic grain:
```python
grain=[],  # SQLMesh infers from first column
```

**Custom**: Override in the template to use a specific primary key

**File**: `scripts/generate_matrix_models.py`

```python
# Before writing file, determine grain based on table
grain_mapping = {
    "OPERATION": ["operation_id"],
    "VENDOR": ["vendor_id"],
    "ITEM": ["item_id"],
    "SUPPLIER_PORTAL": ["supplier_id"],
}

grain = grain_mapping.get(table_name.upper(), [])
```

### Use Case 2: Add Custom SELECT Logic

**Scenario**: Table requires WHERE clause (e.g., active records only).

**File**: `scripts/generate_matrix_models.py` (modify MODEL_TEMPLATE)

```python
MODEL_TEMPLATE_WITH_FILTER = '''
_SELECT_SQL = """
SELECT
{columns}
FROM Staging.dbo.{table_upper} WITH (NOLOCK)
WHERE status = 'active'  -- Only load active records
"""
'''
```

Then conditionally use the template:

```python
if table_name.upper() in ["SUPPLIER_PORTAL", "VENDOR"]:
    template = MODEL_TEMPLATE_WITH_FILTER
else:
    template = MODEL_TEMPLATE
```

### Use Case 3: Add Pre-Processing Step

**Scenario**: Table needs data cleaning (e.g., trim whitespace, normalize codes).

**File**: `scripts/generate_matrix_models.py` (add code to execute() function in template)

```python
EXECUTE_PREPROCESSOR = '''
# Preprocess: trim whitespace from text columns
text_cols = [c for c in df.columns if df[c].dtype == 'object']
for col in text_cols:
    df[col] = df[col].str.strip()
'''
```

---

## Command-Line Usage

### Basic Invocation

```bash
# Use defaults (all paths resolved relative to repo root)
python scripts/generate_matrix_models.py
```

### Custom Paths

```bash
# Specify custom masking matrix
python scripts/generate_matrix_models.py --masking-matrix custom/matrix.csv

# Specify custom schema CSV
python scripts/generate_matrix_models.py --schema-csv custom/schema.csv

# Specify custom output directory
python scripts/generate_matrix_models.py --out-dir generated_models/

# All three custom
python scripts/generate_matrix_models.py \
    --masking-matrix custom/matrix.csv \
    --schema-csv custom/schema.csv \
    --out-dir generated_models/
```

---

## Integration with CI/CD

### GitHub Actions Workflow (Example)

```yaml
name: Generate SQLMesh Models

on:
  push:
    paths:
      - 'certificate_for_receiving/masking_matrix.csv'
      - 'SQL_Data_Schema/ERP_Schema/*.csv'

jobs:
  generate:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v3
      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.10'
      - name: Generate Models
        run: |
          cd Utilities\SQLMesh
          python ..\..\scripts\generate_matrix_models.py
      - name: Validate Generated Files
        run: |
          python -m py_compile Utilities\SQLMesh\models\raw\raw_*.py
      - name: Commit Generated Files
        run: |
          git config user.name "Copilot Agent"
          git config user.email "copilot@example.com"
          git add Utilities\SQLMesh\models\raw\raw_*.py
          git commit -m "Auto-generated SQLMesh models from masking_matrix.csv"
          git push
```

---

## Validation & Quality Checks

### Pre-Generation Checks

```python
def validate_masking_matrix(matrix_path: Path) -> bool:
    """Validate masking_matrix.csv structure."""
    df = pd.read_csv(matrix_path, dtype=str)
    required_cols = {"table_name", "column_name", "masking_type"}
    actual_cols = {c.strip().lower() for c in df.columns}
    assert required_cols.issubset(actual_cols), f"Missing columns: {required_cols - actual_cols}"
    return True

def validate_schema_csv(schema_path: Path) -> bool:
    """Validate schema CSV structure."""
    df = pd.read_csv(schema_path, dtype=str)
    required_cols = {"TABLE_NAME", "COLUMN_NAME", "DATA_TYPE"}
    actual_cols = set(df.columns)
    assert required_cols.issubset(actual_cols), f"Missing columns: {required_cols - actual_cols}"
    return True
```

### Post-Generation Checks

```python
def validate_generated_model(model_path: Path) -> bool:
    """Validate generated Python file is syntactically correct."""
    try:
        with model_path.open() as f:
            compile(f.read(), model_path.name, 'exec')
        return True
    except SyntaxError as e:
        logging.error(f"Syntax error in {model_path}: {e}")
        return False
```

---

## Troubleshooting

### ❌ FileNotFoundError: masking_matrix.csv

**Cause**: Script cannot locate masking_matrix.csv

**Solution**:
```bash
# Verify file exists
ls certificate_for_receiving/masking_matrix.csv

# Run with explicit path
python scripts/generate_matrix_models.py \
    --masking-matrix certificate_for_receiving/masking_matrix.csv
```

### ❌ No tables extracted

**Cause**: masking_matrix.csv is empty or has no table_name entries

**Solution**:
```python
# Debug: read masking matrix
import pandas as pd
df = pd.read_csv("certificate_for_receiving/masking_matrix.csv")
print(df.head())
print(df["table_name"].unique())
```

### ❌ Generated file has syntax errors

**Cause**: TYPE_MAP doesn't include SQL type from schema CSV

**Solution**:
```python
# Add missing type to TYPE_MAP
TYPE_MAP = {
    ...
    "smallmoney": "double",
    "image": "text",  # add missing types
}
```

---

## Performance Considerations

### Generation Time

- **Typical**: 100-200ms for 10 tables
- **Bottleneck**: Schema CSV parsing (if >10K rows)

### Optimization: Incremental Generation

Only generate models for tables that changed:

```python
import hashlib

def get_table_hash(table_rows: List[dict]) -> str:
    """Generate hash of table rows to detect changes."""
    return hashlib.sha256(str(table_rows).encode()).hexdigest()

# Track previous hashes
prev_hashes = {}
curr_hashes = {}

for table, cols in schema_mapping.items():
    curr_hash = get_table_hash(cols)
    curr_hashes[table] = curr_hash
    
    if table not in prev_hashes or prev_hashes[table] != curr_hash:
        # Table changed: regenerate model
        generate_model(table, cols)
```

---

## References

- [Import Dependency Graph](00_Import_Dependency_Graph.md)
- [Development Path Lineage](01_Development_Path_Lineage.md)
- [Masking Matrix Schema](02_Masking_Matrix_Schema.md)
