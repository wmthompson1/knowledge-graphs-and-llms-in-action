# Masking Matrix Schema Reference

## Overview

The **masking_matrix.csv** file defines which tables and fields should be loaded by SQLMesh models and what masking policies apply to each field. This document details the CSV format, column definitions, validation rules, and practical examples.

## File Location

```
repository_root/
├─ certificate_for_receiving/
│  ├─ receiving_certificate_RECV-*.json    (certificate metadata)
│  ├─ masking_matrix.csv                   ← THIS FILE
│  └─ masking_type.csv                     (optional: supplementary rules)
```

**Expected path**: `certificate_for_receiving/masking_matrix.csv`

---

## CSV Column Definitions

### Required Columns

| Column Name | Alt Names | Type | Description | Example |
|---|---|---|---|---|
| `table_name` | - | string | Table name or fnmatch pattern | `USER_DEF_FIELDS`, `OPERATION*`, `*_HISTORY` |
| `column_name` | `field_name`, `column` | string | Column to apply masking | `string_val`, `employee_id`, `*` |
| `masking_type` | `mask_action`, `masking_rule` | string | Action to apply | `pseudonymize`, `redact`, `nullify`, `keep` |

### Optional Columns (Ignored but Allowed)

| Column Name | Type | Description | Example |
|---|---|---|---|
| `description` | string | Human-readable context | "Personal identifier subject to GDPR" |
| `severity` | string | Classification level | `high`, `medium`, `low` |
| `category` | string | Data domain | `PII`, `internal`, `public` |
| `notes` | string | Implementation notes | "Hash with RECEIVING_PSEED only" |

---

## Masking Action Types

### Supported Actions

| Action | Aliases | Behavior | Seed Required |
|---|---|---|---|
| **pseudonymize** | `pseudo`, `hash_sha256`, `hmac`, `deterministic_hash` | HMAC-SHA256 hash using RECEIVING_PSEED; reproducible per value | ✅ Yes |
| **redact** | `mask` | Replace all values with `<REDACTED>` | ❌ No |
| **nullify** | `null` | Replace all values with NULL | ❌ No |
| **keep** | `passthrough`, `none` | Leave unchanged | ❌ No |

### Action Decision Matrix

```
┌─────────────────┬───────────────────────┬──────────────┬────────────────┐
│ Action          │ Implementation        │ Reversible   │ Use Case       │
├─────────────────┼───────────────────────┼──────────────┼────────────────┤
│ pseudonymize    │ HMAC-SHA256(seed, val)│ No (1-way)   │ Linkable PII   │
│ redact          │ Literal "<REDACTED>"  │ No           │ Visible PII    │
│ nullify         │ SQL NULL              │ No           │ Optional data  │
│ keep            │ No-op (passthrough)   │ Yes (orig)   │ Public data    │
└─────────────────┴───────────────────────┴──────────────┴────────────────┘
```

---

## CSV Format Rules

### Normalization Rules (Applied by loader)

1. **Column names**: Converted to lowercase and whitespace stripped
   - `Table_Name` → `table_name`
   - `MASKING TYPE` → `masking_type`

2. **Values**: Whitespace stripped, empty cells become ""
   - ` USER_DEF_FIELDS ` → `USER_DEF_FIELDS`
   - (blank cell) → `""`

3. **Case sensitivity**: Values are lowercased during matching
   - `Table_Name` = `table_name` = `TABLE_NAME`
   - Action `Pseudonymize` = `pseudonymize`

### Pattern Matching (fnmatch)

The `table_name` column supports fnmatch wildcard patterns:

| Pattern | Matches | Doesn't Match |
|---|---|---|
| `USER_DEF_FIELDS` | USER_DEF_FIELDS (exact) | USER_DEF_FIELDS_HISTORY |
| `OPERATION*` | OPERATION, OPERATION_CODE, OPERATION_LINE | LINE_OPERATION |
| `*_HISTORY` | OPERATION_HISTORY, ITEM_HISTORY, DOCUMENT_HISTORY | HISTORY, HISTORY_AUDIT |
| `*ITEM*` | ITEM, ITEM_LINE, SKU_ITEM_DETAIL | LINE, DETAIL_ITEM_XREF |
| `[A-Z]*` | Not recommended (standard Python regex not supported; use fnmatch only) | - |

**Matching algorithm**: Uses Python's `fnmatch.fnmatch(table_name.lower(), pattern.lower())`

---

## CSV Examples

### Example 1: Basic USER_DEF_FIELDS Masking

```csv
table_name,column_name,masking_type
USER_DEF_FIELDS,string_val,pseudonymize
USER_DEF_FIELDS,number_val,keep
USER_DEF_FIELDS,date_val,keep
```

**Interpretation**:
- For table `USER_DEF_FIELDS`:
  - Column `string_val` → hash using HMAC-SHA256 (requires RECEIVING_PSEED)
  - Column `number_val` → keep as-is (public data)
  - Column `date_val` → keep as-is (public data)

### Example 2: Multi-Table with Wildcards

```csv
table_name,column_name,masking_type,category
OPERATION,employee_id,pseudonymize,PII
OPERATION,wage_amount,redact,Financial
OPERATION,status,keep,Public
OPERATION*,line_detail,redact,PII
*_HISTORY,*,nullify,Archive
```

**Interpretation**:
- `OPERATION` table:
  - `employee_id` → pseudonymize (track individuals consistently)
  - `wage_amount` → redact (remove visible financial data)
  - `status` → keep (non-sensitive)
- `OPERATION*` table (matches OPERATION, OPERATION_CODE, etc.):
  - `line_detail` → redact (all detail rows)
- `*_HISTORY` table (any table ending in _HISTORY):
  - `*` (all columns) → nullify (archive data)

### Example 3: Severity-Based Policy

```csv
table_name,column_name,masking_type,severity,notes
USER_DEF_FIELDS,string_val,pseudonymize,high,GDPR personal identifier
USER_DEF_FIELDS,number_val,keep,medium,Non-sensitive numeric value
ITEM,item_code,keep,low,Public product codes
ITEM,cost_amount,redact,high,Confidential pricing
VENDOR,vendor_id,pseudonymize,medium,Supplier relationship tracking
VENDOR,contact_email,redact,high,GDPR email data
```

---

## Validation Rules

### Rule 1: Table Name Required
```python
if not pattern.strip():
    logging.warning("Empty table_name in row; skipping")
    # Row is ignored
```

### Rule 2: Column Name Required
```python
if not field.strip():
    logging.warning("Empty column_name for table %s; skipping", table_name)
    # Row is ignored
```

### Rule 3: Action Must Be Recognized
```python
if action not in ("pseudonymize", "redact", "nullify", "keep", ...):
    logging.warning("Unknown action '%s' for field '%s'; skipping", action, field)
    # Row is ignored (but doesn't fail)
```

### Rule 4: Pseudonymize Requires RECEIVING_PSEED
```python
if action in ("pseudonymize", "hash_sha256", ...):
    if not os.environ.get("RECEIVING_PSEED"):
        raise ValueError("Masking policy requires RECEIVING_PSEED environment variable")
    # Execution halts if seed not available
```

### Rule 5: Column Must Exist in DataFrame
```python
if field not in df.columns:
    logging.warning("Column '%s' not found in DataFrame; skipping", field)
    # Field is skipped but doesn't fail
```

---

## Loading Code Reference

### Code: `masking_helpers.load_masking_matrix()`

```python
def load_masking_matrix(path: Path) -> pd.DataFrame:
    if not path.exists():
        raise FileNotFoundError(path)
    df = pd.read_csv(path, dtype=str).fillna("")
    df.columns = [c.strip().lower() for c in df.columns]
    return df
```

**Behavior**:
1. Opens CSV file at `path`
2. All values loaded as strings (dtype=str)
3. Empty cells become "" (not NaN)
4. Column names lowercased and whitespace stripped

### Code: `masking_helpers.get_masking_rules_for_table()`

```python
def get_masking_rules_for_table(table_name: str, mask_df: pd.DataFrame, types_df: pd.DataFrame) -> list[dict]:
    rules = []
    tn = table_name.lower()
    for _, row in mask_df.iterrows():
        pattern = str(row.get("table_name", "")).strip().lower()
        if not pattern:
            continue
        if fnmatch.fnmatch(tn, pattern):
            field = row.get("column_name") or row.get("field_name") or row.get("column") or ""
            mask_action = row.get("masking_type") or row.get("mask_action") or row.get("masking_rule") or ""
            rules.append({
                "field_name": str(field).strip().lower(),
                "mask_action": str(mask_action).strip().lower()
            })
    return rules
```

**Behavior**:
1. Lowercases table_name
2. Iterates rows in masking_matrix DataFrame
3. For each row: extracts pattern (supports fnmatch)
4. If pattern matches table_name, extracts field + action
5. Returns list of {field_name, mask_action} dicts

---

## Masking Type CSV (Optional Supplement)

**File**: `certificate_for_receiving/masking_type.csv`

The optional **masking_type.csv** file can define supplementary masking rule types or overrides. If present, it's loaded alongside masking_matrix.csv.

### Example masking_type.csv

```csv
masking_type,description,function
pseudonymize,HMAC-SHA256 hash,deterministic_pseudonym
redact,Literal redaction mask,lambda x: '<REDACTED>'
nullify,SQL NULL replacement,lambda x: None
keep,Passthrough (no masking),lambda x: x
```

---

## Runtime Environment Variables

### RECEIVING_PSEED (Required for Pseudonymize)

```bash
export RECEIVING_PSEED="my-organization-secret-key-2025"
```

**Purpose**: Seed for HMAC-SHA256 pseudonymization

**Constraints**:
- Must be consistent across all masking passes (for reproducibility)
- Must not be committed to version control
- Should be rotated periodically

**Usage**:
```python
from masking_helpers import deterministic_pseudonym
result = deterministic_pseudonym("Alice", seed=os.environ["RECEIVING_PSEED"], field_name="name")
```

### STAGING_ODBC (For Database Connection)

```bash
export STAGING_ODBC="Driver={ODBC Driver 18 for SQL Server};Server=sql-lab-2;Database=Staging;Trusted_Connection=yes;TrustServerCertificate=yes;"
```

---

## Integration with SQLMesh Models

### raw_user_def_fields.py Usage

```python
mask_matrix_path = resolve_cert_dir() / "masking_matrix.csv"
mask_df = load_masking_matrix(mask_matrix_path)

rules = get_masking_rules_for_table("user_def_fields", mask_df, pd.DataFrame())
# Returns: [{"field_name": "string_val", "mask_action": "pseudonymize"}, ...]

apply_masking_to_df(df, rules, seed=os.environ.get("RECEIVING_PSEED"))
```

### raw_matrix_driven.py Usage

```python
mask_matrix_path = cert_dir / "masking_matrix.csv"
mask_df = load_masking_matrix(mask_matrix_path)

# Extract distinct table names from CSV
table_names = sorted(set(str(x).strip() for x in mask_df.get("table_name", [])))

# For each table: load from Staging, extract rules, apply masking
for table in table_names:
    rules = get_masking_rules_for_table(table, mask_df, pd.DataFrame())
    # Load table, apply rules, append to result
```

---

## CSV Validation Checklist

Before committing masking_matrix.csv:

- [ ] All rows have `table_name`, `column_name`, `masking_type` columns
- [ ] No empty rows (except optional final blank line)
- [ ] All `table_name` values are valid SQL identifiers or fnmatch patterns
- [ ] All `column_name` values are valid SQL identifiers or `*` (wildcard)
- [ ] All `masking_type` values are recognized actions (pseudonymize, redact, nullify, keep)
- [ ] If `pseudonymize` used: RECEIVING_PSEED environment variable is set
- [ ] CSV is UTF-8 encoded (no BOM)
- [ ] No trailing whitespace on rows

---

## Common Mistakes & Troubleshooting

### ❌ Empty Masking Matrix

**Symptom**: No rows loaded, DataFrame is empty

**Cause**: File missing or empty

**Fix**:
```python
# Check file existence
assert Path("certificate_for_receiving/masking_matrix.csv").exists()
# Check non-empty
df = load_masking_matrix(Path(...))
assert not df.empty, "masking_matrix.csv has no data rows"
```

### ❌ Column Not Found

**Symptom**: `KeyError: 'table_name'` or similar

**Cause**: CSV column header mismatch (e.g., `Table Name` instead of `table_name`)

**Fix**:
```python
# Verify column names
df = load_masking_matrix(path)
print(df.columns.tolist())
# Should be: ['table_name', 'column_name', 'masking_type', ...]
```

### ❌ Pattern Not Matching

**Symptom**: Rules extracted for other tables but not the target table

**Cause**: fnmatch pattern incorrect or case sensitivity issue

**Fix**:
```python
import fnmatch
pattern = "OPERATION*"
table_name = "operation_line"
assert fnmatch.fnmatch(table_name.lower(), pattern.lower()), "Pattern doesn't match"
```

### ❌ Pseudonymize Fails

**Symptom**: `ValueError: Masking policy requires RECEIVING_PSEED`

**Cause**: Environment variable not set when masking_type = pseudonymize

**Fix**:
```bash
export RECEIVING_PSEED="my-seed"
python -c "import os; print('SEED SET' if os.environ.get('RECEIVING_PSEED') else 'SEED NOT SET')"
```

---

## References

- [Development Path Lineage](01_Development_Path_Lineage.md) (Phase 3: Matrix Loading, Phase 6: Masking Application)
- [ArangoDB Binding Format](03_ArangoDB_Binding_Format.md)
- [Import Dependency Graph](00_Import_Dependency_Graph.md)
