---
title: Binding Key Generation
version: 1.0
date: 2024-06-11
status: complete
---

# Binding Key Generation: Deterministic Key Compilation

## Overview

Binding keys are **deterministic, normalized identifiers** for semantic edges in the ArangoDB graph. They enable reproducible, consistent field binding definitions across environments and time periods.

**File:** `scripts/graph_key_generation.py`

---

## The 5-Segment Formula

```
{LEFT}_{RIGHT}_{PATH}_{INTENT}_{PERSPECTIVE}
```

### Segment Definitions

| Segment | Type | Length | Normalization | Example |
|---------|------|--------|----------------|---------|
| **LEFT** | Fixed Token | 3 chars | First 3 alphanumeric, UPPERCASE | `CUS` (from "Customer Account") |
| **RIGHT** | Fixed Token | 3 chars | First 3 alphanumeric, UPPERCASE | `ACC` (from "Account Receivable") |
| **PATH** | Index | 3 digits | Zero-padded integer (0–999) | `001`, `042`, `999` |
| **INTENT** | Fixed Token | 3 chars | First 3 alphanumeric, UPPERCASE | `BIL`, `INV`, `OPE` |
| **PERSPECTIVE** | Variable | 1–N chars | Alphanumeric + underscores, preserved case | `Accounts_Receivable`, `Work_Order_Operations` |

### Complete Formula

```python
def compile_binding_key(
    *,
    left_source: str,
    right_target: str,
    path_index: int | str,
    intent_token: str,
    perspective: str,
) -> str:
    """Compile deterministic binding key: L_R_P_I_PERSPECTIVE"""
    left_segment = _normalize_fixed_token(left_source, field_name="left_source")
    right_segment = _normalize_fixed_token(right_target, field_name="right_target")
    path_segment = _normalize_path_index(path_index)
    intent_segment = _normalize_fixed_token(intent_token, field_name="intent_token")
    perspective_segment = _normalize_perspective(perspective)
    return f"{left_segment}_{right_segment}_{path_segment}_{intent_segment}_{perspective_segment}"
```

---

## Normalization Rules

### Rule 1: Fixed Token Normalization (LEFT, RIGHT, INTENT)

**Purpose:** Create consistent 3-character identifiers from variable-length strings.

**Algorithm:**
```python
def _normalize_fixed_token(value: str, *, field_name: str) -> str:
    """
    1. Strip leading/trailing whitespace
    2. Keep only alphanumeric characters (a-z, A-Z, 0-9)
    3. Validate at least 3 alphanumeric chars remain
    4. Take first 3 characters
    5. Convert to UPPERCASE
    """
    normalized = "".join(ch for ch in value.strip() if ch.isalnum())
    if len(normalized) < 3:
        raise ValueError(f"{field_name} must contain at least 3 alphanumeric characters")
    return normalized[:3].upper()
```

**Examples:**
```python
_normalize_fixed_token("Customer Account", field_name="left_source")
# Step 1: "Customer Account" → "Customer Account" (trim)
# Step 2: "CustomerAccount" → "CustomerAccount" (alphanumeric only)
# Step 3: ✓ 15 chars ≥ 3
# Step 4: "Cus"
# Step 5: "CUS"

_normalize_fixed_token("AR", field_name="right_target")
# Step 2: "AR" → "AR"
# Step 3: ✗ 2 chars < 3 → ValueError

_normalize_fixed_token("A&R (Accounts @ Receivable)", field_name="right_target")
# Step 2: "ARAccountsReceivable"
# Step 3: ✓ 19 chars ≥ 3
# Step 4: "ARA"
# Step 5: "ARA"

_normalize_fixed_token("123ABC", field_name="intent_token")
# Step 2: "123ABC"
# Step 3: ✓ 6 chars ≥ 3
# Step 4: "123"
# Step 5: "123"  (digits are valid alphanumeric)
```

**Error Cases:**
- Input: `"X"` → ValueError: "left_source must contain at least 3 alphanumeric characters"
- Input: `"@#$"` → ValueError: "right_target must contain at least 3 alphanumeric characters"
- Input: `"A-B-C"` → Success: `"ABC"` (hyphens stripped)

---

### Rule 2: Path Index Normalization (PATH)

**Purpose:** Create consistent 3-digit identifiers for binding path sequences.

**Algorithm:**
```python
def _normalize_path_index(path_index: int | str) -> str:
    """
    1. Convert to string and strip whitespace
    2. Validate string contains only digits
    3. Convert to integer
    4. Validate in range [0, 999]
    5. Return zero-padded 3-digit string
    """
    normalized = str(path_index).strip()
    if not normalized.isdigit():
        raise ValueError("path_index must be numeric")
    
    path_value = int(normalized)
    if path_value < 0 or path_value > 999:
        raise ValueError("path_index must be between 0 and 999")
    
    return f"{path_value:03d}"  # Zero-padded to 3 digits
```

**Examples:**
```python
_normalize_path_index(0)        → "000"
_normalize_path_index(1)        → "001"
_normalize_path_index(42)       → "042"
_normalize_path_index(999)      → "999"
_normalize_path_index("001")    → "001"
_normalize_path_index("1")      → "001"
_normalize_path_index("  42  ") → "042"
_normalize_path_index(-1)       → ValueError: "path_index must be between 0 and 999"
_normalize_path_index(1000)     → ValueError: "path_index must be between 0 and 999"
_normalize_path_index("ABC")    → ValueError: "path_index must be numeric"
```

**Rationale:** Allows up to 1000 distinct binding paths (0–999) per intent–perspective pair; zero-padding ensures stable sorting and consistent length in keys.

---

### Rule 3: Perspective Normalization (PERSPECTIVE)

**Purpose:** Preserve semantic meaning while enabling consistent key matching.

**Algorithm:**
```python
def _normalize_perspective(perspective: str) -> str:
    """
    1. Strip leading/trailing whitespace
    2. Split on whitespace to get word parts
    3. For each part, keep only alphanumeric characters
    4. Join non-empty parts with underscores
    5. Validate at least one alphanumeric character remains
    """
    normalized_parts = [
        "".join(ch for ch in part if ch.isalnum())
        for part in perspective.strip().split()
    ]
    normalized = "_".join(part for part in normalized_parts if part)
    if not normalized:
        raise ValueError("perspective must contain at least 1 alphanumeric character")
    return normalized
```

**Examples:**
```python
_normalize_perspective("Accounts Receivable")
# Split: ["Accounts", "Receivable"]
# Alphanumeric: ["Accounts", "Receivable"]
# Join: "Accounts_Receivable"

_normalize_perspective("Work Order Operations & Planning")
# Split: ["Work", "Order", "Operations", "&", "Planning"]
# Alphanumeric: ["Work", "Order", "Operations", "", "Planning"]
# Join: "Work_Order_Operations_Planning"

_normalize_perspective("AR-GL-Module (v2)")
# Split: ["AR-GL-Module", "(v2)"]
# Alphanumeric: ["ARGLModule", "v2"]
# Join: "ARGLModule_v2"

_normalize_perspective("  Multi   Word   Perspective  ")
# Split: ["Multi", "Word", "Perspective"]
# Alphanumeric: ["Multi", "Word", "Perspective"]
# Join: "Multi_Word_Perspective"

_normalize_perspective("@#$%")  → ValueError: "perspective must contain at least 1 alphanumeric character"
_normalize_perspective("A B")   → "A_B"
_normalize_perspective("")      → ValueError: "perspective must contain at least 1 alphanumeric character"
```

**Rationale:** Underscores preserve word boundaries while maintaining readability; alphanumeric-only filtering removes special characters that might cause issues in downstream systems.

---

## Complete Example Workflow

### Input Scenario
```python
{
    "left_source": "Customer Account",
    "right_target": "Accounts Receivable",
    "path_index": 1,
    "intent_token": "Billing",
    "perspective": "Accounts Receivable AR Cycle"
}
```

### Step-by-Step Normalization

```python
# LEFT normalization
left_source = "Customer Account"
→ _normalize_fixed_token("Customer Account", field_name="left_source")
→ "CustomerAccount" (alphanumeric only)
→ "Cus" (first 3)
→ "CUS" (uppercase)

# RIGHT normalization
right_target = "Accounts Receivable"
→ _normalize_fixed_token("Accounts Receivable", field_name="right_target")
→ "AccountsReceivable" (alphanumeric only)
→ "Acc" (first 3)
→ "ACC" (uppercase)

# PATH normalization
path_index = 1
→ _normalize_path_index(1)
→ "1" (string)
→ 1 (int)
→ "001" (zero-padded)

# INTENT normalization
intent_token = "Billing"
→ _normalize_fixed_token("Billing", field_name="intent_token")
→ "Billing" (alphanumeric only)
→ "Bil" (first 3)
→ "BIL" (uppercase)

# PERSPECTIVE normalization
perspective = "Accounts Receivable AR Cycle"
→ _normalize_perspective("Accounts Receivable AR Cycle")
→ ["Accounts", "Receivable", "AR", "Cycle"] (split)
→ ["Accounts", "Receivable", "AR", "Cycle"] (alphanumeric)
→ "Accounts_Receivable_AR_Cycle" (join)
```

### Final Output
```python
compile_binding_key(
    left_source="Customer Account",
    right_target="Accounts Receivable",
    path_index=1,
    intent_token="Billing",
    perspective="Accounts Receivable AR Cycle"
)
→ "CUS_ACC_001_BIL_Accounts_Receivable_AR_Cycle"
```

---

## Graph Usage: Where Keys Appear

### 1. Column_Bindings Edges
```aql
FOR edge IN Column_Bindings
    FILTER edge._key == "CUS_ACC_001_BIL_Accounts_Receivable_AR_Cycle"
    RETURN edge
```

**Edge Properties:**
```json
{
    "_key": "CUS_ACC_001_BIL_Accounts_Receivable_AR_Cycle",
    "_from": "fields/customer_account_id",
    "_to": "concepts/accounts_receivable",
    "intent": "BIL",
    "perspective": "Accounts_Receivable_AR_Cycle",
    "path_index": 1,
    "binding_status": "active"
}
```

### 2. Intent-to-Binding Navigation
```aql
LET binding_key = "CUS_ACC_001_BIL_Accounts_Receivable_AR_Cycle"

FOR edge IN bound_to
    FILTER edge._to == CONCAT("bindings/", binding_key)
    RETURN {
        intent: edge._from,
        binding: edge._to,
        binding_key: binding_key
    }
```

### 3. Semantic Layer Query
```python
# SQLite: reviewer_manifest.json stores primary_binding_key
manifest = load_json("hf-space-inventory-sqlgen/app_schema/ground_truth/reviewer_manifest.json")

for record in manifest:
    binding_key = compile_binding_key_from_payload(record)
    # binding_key = "CUS_ACC_001_BIL_Accounts_Receivable_AR_Cycle"
    assert binding_key == record["primary_binding_key"]
```

---

## Code Reference: graph_key_generation.py

```python
from __future__ import annotations
from collections.abc import Mapping
from typing import Any

def _normalize_fixed_token(value: str, *, field_name: str) -> str:
    normalized = "".join(ch for ch in value.strip() if ch.isalnum())
    if len(normalized) < 3:
        raise ValueError(f"{field_name} must contain at least 3 alphanumeric characters")
    return normalized[:3].upper()

def _normalize_path_index(path_index: int | str) -> str:
    normalized = str(path_index).strip()
    if not normalized.isdigit():
        raise ValueError("path_index must be numeric")
    path_value = int(normalized)
    if path_value < 0 or path_value > 999:
        raise ValueError("path_index must be between 0 and 999")
    return f"{path_value:03d}"

def _normalize_perspective(perspective: str) -> str:
    normalized_parts = [
        "".join(ch for ch in part if ch.isalnum())
        for part in perspective.strip().split()
    ]
    normalized = "_".join(part for part in normalized_parts if part)
    if not normalized:
        raise ValueError("perspective must contain at least 1 alphanumeric character")
    return normalized

def compile_binding_key(
    *,
    left_source: str,
    right_target: str,
    path_index: int | str,
    intent_token: str,
    perspective: str,
) -> str:
    """Compile a deterministic binding key using the shared baseline formula."""
    left_segment = _normalize_fixed_token(left_source, field_name="left_source")
    right_segment = _normalize_fixed_token(right_target, field_name="right_target")
    path_segment = _normalize_path_index(path_index)
    intent_segment = _normalize_fixed_token(intent_token, field_name="intent_token")
    perspective_segment = _normalize_perspective(perspective)
    return f"{left_segment}_{right_segment}_{path_segment}_{intent_segment}_{perspective_segment}"

def compile_binding_key_from_payload(payload: Mapping[str, Any]) -> str:
    """Compile a binding key from a staged payload dictionary."""
    return compile_binding_key(
        left_source=str(payload["left_source"]),
        right_target=str(payload["right_target"]),
        path_index=payload["path_index"],
        intent_token=str(payload["intent_token"]),
        perspective=str(payload["perspective"]),
    )
```

---

## Testing & Validation

### Unit Tests (scripts/test_graph_key_generation.py)

```python
import pytest
from graph_key_generation import compile_binding_key, compile_binding_key_from_payload

def test_fixed_token_normalization():
    assert _normalize_fixed_token("Customer Account", field_name="left") == "CUS"
    assert _normalize_fixed_token("AR", field_name="right") → ValueError
    assert _normalize_fixed_token("A-B-C", field_name="intent") == "ABC"

def test_path_index_normalization():
    assert _normalize_path_index(0) == "000"
    assert _normalize_path_index(42) == "042"
    assert _normalize_path_index(999) == "999"
    assert _normalize_path_index(1000) → ValueError

def test_perspective_normalization():
    assert _normalize_perspective("Accounts Receivable") == "Accounts_Receivable"
    assert _normalize_perspective("@#$") → ValueError
    assert _normalize_perspective("A B C") == "A_B_C"

def test_compile_binding_key():
    key = compile_binding_key(
        left_source="Customer",
        right_target="Account",
        path_index=1,
        intent_token="Billing",
        perspective="AR"
    )
    assert key == "CUS_ACC_001_BIL_AR"

def test_compile_binding_key_from_payload():
    payload = {
        "left_source": "Customer",
        "right_target": "Account",
        "path_index": 1,
        "intent_token": "Billing",
        "perspective": "AR"
    }
    key = compile_binding_key_from_payload(payload)
    assert key == "CUS_ACC_001_BIL_AR"

def test_determinism():
    """Same inputs always produce same key"""
    key1 = compile_binding_key(
        left_source="Customer Account",
        right_target="Accounts Receivable",
        path_index=1,
        intent_token="Billing",
        perspective="Accounts Receivable"
    )
    key2 = compile_binding_key(
        left_source="Customer Account",
        right_target="Accounts Receivable",
        path_index=1,
        intent_token="Billing",
        perspective="Accounts Receivable"
    )
    assert key1 == key2
```

---

## Best Practices

### ✓ DO

- Use deterministic, normalized keys for reproducibility across runs
- Validate inputs before compilation (raise on invalid data)
- Store binding keys in SQLite/manifest for audit trail
- Test normalization on real-world field names

### ✗ DON'T

- Hardcode keys; always compile dynamically
- Use UUIDs or random keys (defeats determinism purpose)
- Skip validation; let errors propagate early
- Change normalization rules without migration plan

---

## References

- **Used By:** `graph_sync.py`, `test_e2e_sqlmesh_to_arango.py`, `test_logical_sync_contract_regression_unitTest.py`
- **Related:** `Column_Bindings` edge collection in ArangoDB; `reviewer_manifest.json` in `hf-space-inventory-sqlgen/app_schema/ground_truth/`

---

## Next: Legacy Migration Roadmap

See **[04_Legacy_Migration_Roadmap.md](04_Legacy_Migration_Roadmap.md)** for Stage 1 deprecation strategy.

