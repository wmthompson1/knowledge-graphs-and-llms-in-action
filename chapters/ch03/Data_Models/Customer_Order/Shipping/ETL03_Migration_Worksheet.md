# ETL03 Migration Worksheet

## Source of truth
- **Canonical ETL03 implementation:** [`sp_Shipments_Core_Feed_03.sql`](sp_Shipments_Core_Feed_03.sql) (in `Documentation/Schema/Data_Models/Customer_Order/Shipping/`)
- **Procedure name in canonical file:** `sp_Shipments_Core_Feed_03` (the commented header references `SP_SK_ETL03_CUST_SHIP`)

## Current ETL03 implementations
Three files now contain the same legacy/current `SP_SK_ETL03_CUST_SHIP` implementation:

| File | Location | Lines | Table used | Notes |
|---|---|---|---|---|
| [`zza_SP_SK_ETL03_CUST_SHIP.sql`](zza_SP_SK_ETL03_CUST_SHIP.sql) | `Documentation/Schema/Data_Models/Customer_Order/Shipping/` | 1–160 | `LIVESupplemental.dbo.PBI_Customer_Shipments_complement_OT` | **Corrected test file** — now declares `SP_SK_ETL03_CUST_SHIP` instead of the misnamed ETL02 code. |
| [`x3.sql`](../10%20Sales/x3.sql) | `Documentation/Schema/Data_Models/Customer_Order/10 Sales/` | 1–160 | `LIVESupplemental.dbo.PBI_Customer_Shipments_complement_OT` | Legacy copy. |
| [`403 SP_SK_ETL03_CUST_SHIP.sql`](../../Receivables/403%20SP_SK_ETL03_CUST_SHIP.sql) | `Documentation/Schema/Data_Models/Receivables/` | 1–161 | `LIVESupplemental.dbo.PBI_Customer_Shipments_complement_OT` | Legacy copy. |

> **Note:** `x3.sql`, `403 SP_SK_ETL03_CUST_SHIP.sql`, and the corrected `zza_SP_SK_ETL03_CUST_SHIP.sql` are functionally identical (modulo line-wrapping). The canonical source `sp_Shipments_Core_Feed_03.sql` uses a different intermediate table and a cleaner code style.

## Target ETL03 procedure
The canonical Core Feed 03 procedure uses the newer intermediate table:

- **File:** [`sp_Shipments_Core_Feed_03.sql`](sp_Shipments_Core_Feed_03.sql)
- **Table:** `LIVESupplemental.dbo.Feed_01_Core_Intermediate_complement_OT`
- **Final output table:** `LIVESupplemental.dbo.Feed_01_Core_Intermediate_complement_OT_01`

## Required deltas (current → target)

### 1. Intermediate table rename
- **Current:** `PBI_Customer_Shipments_complement_OT`
- **Target:** `Feed_01_Core_Intermediate_complement_OT`
- **Impact:** All `DELETE`, `UPDATE`, `TRUNCATE`, `INSERT`, and `SELECT` statements in the procedure must reference the new table.

### 2. Final output table rename
- **Current:** `PBI_Customer_Shipments_complement_OT_01`
- **Target:** `Feed_01_Core_Intermediate_complement_OT_01`

### 3. `LIVEARC` branches
- **Current:** Active `LIVEARC` branches for `MFG`, `FIN`, and `FIN_MFG` using `[SQL-Lab-2].[LIVEARC]`.
- **Target:** `LIVEARC` branches are commented out; only `LIVE` branches remain active.
- **Decision needed:** Is `LIVEARC` still required in production?

### 4. `BASE_TABLE` filter
- **Current:** `AND A.BASE_TABLE = 'LIVE'` / `'LIVEARC'` filters are active.
- **Target:** `BASE_TABLE` filters are commented out.
- **Decision needed:** Is the `BASE_TABLE` column still relevant after the table rename?

### 5. Date-casting style
- **Current:** `DATEADD(DAY, 1, CONVERT(varchar(12), GETDATE(), 23))`
- **Target:** `DATEADD(DAY, 1, CAST(GETDATE() AS DATE))`
- **Rationale:** `CAST(GETDATE() AS DATE)` is clearer and avoids implicit varchar conversion.

### 6. CBO delete filter
- **Current:** `DELETE ... WHERE COL_UDF6 = 'CBO' AND BUS_STREAM = 'MFG'`
- **Target:** `DELETE ... WHERE ORDER_STATUS = 'CANCELLED'` only (the CBO filter is commented out in the canonical version).
- **Decision needed:** Should the CBO exclusion be retained?

### 7. Self-join pattern
- **Current:** Many `UPDATE` statements include `INNER JOIN LIVESupplemental.dbo.PBI_Customer_Shipments_complement_OT B WITH (NOLOCK) ON A.RowID = B.RowID` combined with `WHERE a.RowID = b.RowID`.
- **Target:** The canonical procedure removes this redundant self-join for several updates.
- **Rationale:** The self-join does not change the row set because the join condition and the `WHERE` clause are equivalent.

## Files **not** to use as source of truth
- [`zza_SP_SK_ETL01_CUST_SHIP.sql`](zza_SP_SK_ETL01_CUST_SHIP.sql) — contains a misplaced/commented copy of ETL03 logic embedded inside ETL01.
- [`zza_SP_SK_ETL03_CUST_SHIP.sql`](zza_SP_SK_ETL03_CUST_SHIP.sql) — misnamed; actually contains `SP_SK_ETL02_CUST_SHIP` code.

## Schema contract notes
- Neither the current nor the target procedure uses an explicit column list in the final `INSERT`; both use `INSERT INTO ... SELECT * FROM <intermediate_table>`.
- The schema contract therefore depends on the column definitions of the intermediate tables:
  - Current: `LIVESupplemental.dbo.PBI_Customer_Shipments_complement_OT`
  - Target: `LIVESupplemental.dbo.Feed_01_Core_Intermediate_complement_OT`
- **Validation constraint:** Any database access must use a valid receiving certificate and the approved pre-stage server (`Crunch2018` / `Crunch0626`). Direct connections to `SQL-LAB-1` / `lab-01` or production ERP servers are not permitted. A prior parse/metadata check against `SQL-LAB-1 / LIVE` is therefore invalid and must not be used as evidence.

## CTE / UNION notes
- The ETL03 procedure does **not** contain CTEs or `UNION` operators. The CTEs (`CTE_BASE`, `CTE_PIVOT`, `CTE_BS`, `CTE_REMAINING`, `CTE_FULL`) and the `UNION ALL` issue that required the recent `ADJ_DUE_DATE` → `ADJUSTED_DUE_DATE` fix belong to **ETL02** (`sp_Shipments_Core_Feed_02.sql`), not ETL03.
- This migration worksheet is therefore focused on table references, date-casting, `LIVEARC` branches, `BASE_TABLE` filters, and the CBO exclusion.

## Open decisions before migration
1. **Which current file is the migration target?** `x3.sql` or `403 SP_SK_ETL03_CUST_SHIP.sql` (or a new test file)?
2. **Should the procedure be renamed?** The canonical file uses `sp_Shipments_Core_Feed_03`; the legacy files use `SP_SK_ETL03_CUST_SHIP`.
3. **Should the intermediate table be renamed?** Current uses `PBI_Customer_Shipments_complement_OT`; target uses `Feed_01_Core_Intermediate_complement_OT`.
4. **Should `LIVEARC` support be retained or dropped?**
5. **Should the `BASE_TABLE` filter be retained or dropped?**
6. **Should the CBO exclusion (`COL_UDF6 = 'CBO'`) be retained or dropped?**
