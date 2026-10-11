# Comparison: Misplaced `SP_SK_ETL03_CUST_SHIP` code in `zza_SP_SK_ETL01_CUST_SHIP.sql`

## Important note about file names
- The canonical implementation of **`SP_SK_ETL03_CUST_SHIP`** is in [`sp_Shipments_Core_Feed_03.sql`](sp_Shipments_Core_Feed_03.sql).
- [`zza_SP_SK_ETL03_CUST_SHIP.sql`](zza_SP_SK_ETL03_CUST_SHIP.sql) is **misnamed** — its header and body are actually `SP_SK_ETL02_CUST_SHIP` (identical to [`sp_Shipments_Core_Feed_02.sql`](sp_Shipments_Core_Feed_02.sql)).

## Problem statement
The test file [`zza_SP_SK_ETL01_CUST_SHIP.sql`](zza_SP_SK_ETL01_CUST_SHIP.sql) contains a block of `SP_SK_ETL03_CUST_SHIP` logic embedded inside `SP_SK_ETL01_CUST_SHIP`. The block spans roughly lines 586–698 and is currently wrapped in a comment (`/* ... */`), so it is inactive. The note file [`zza_SP_SK_ETL01_CUST_SHIP.md`](zza_SP_SK_ETL01_CUST_SHIP.md) flags this for review.

## Where each block lives

| Source | File | Lines | Procedure declared | Status of the block |
|---|---|---|---|---|
| Misplaced code | [`zza_SP_SK_ETL01_CUST_SHIP.sql`](zza_SP_SK_ETL01_CUST_SHIP.sql) | ~586–698 | `SP_SK_ETL01_CUST_SHIP` | Commented out (`/* ... */`) |
| Canonical code | [`sp_Shipments_Core_Feed_03.sql`](sp_Shipments_Core_Feed_03.sql) | ~53–164 | `sp_Shipments_Core_Feed_03` (`SP_SK_ETL03_CUST_SHIP`) | Active |

## High-level structure of both blocks

Both blocks perform the same conceptual steps after the core shipment data has been loaded into an intermediate table:

1. Fix `ADJUSTED_DUE_DATE` for `CMP-FIN` / `CMP-MFG` using `CO_DESIRED_SHIP_DATE`.
2. Fix `ADJUSTED_DUE_DATE` for `MFG` using `CUST_ORDER_LINE.PROMISE_DATE`.
3. Fix `ADJUSTED_DUE_DATE` for `FIN` using `CUSTOMER_ORDER.DESIRED_SHIP_DATE` (with a +1 day adjustment for `AERMAN` / `AMTRIB`).
4. Fix `ADJUSTED_DUE_DATE` for `FIN_MFG` using `CUSTOMER_ORDER.DESIRED_SHIP_DATE`.
5. Delete rows where `TOTAL_SHIPPED_QTY = 0` and `ADJUSTED_DUE_DATE` is in the future.
6. Recalculate `ON_TIME1` / `LATE1` based on `FILTER_DATE <= ADJUSTED_DUE_DATE`.

## Key differences

### 1. Target intermediate table
- **Misplaced block:** operates on `LIVESupplemental.dbo.PBI_Customer_Shipments_complement_OT`.
- **Canonical block:** operates on `LIVESupplemental.dbo.Feed_01_Core_Intermediate_complement_OT`.

This is the most important divergence: the ETL01 test file references the legacy complement table, while the canonical Core Feed 03 uses the newer `Feed_01_Core_Intermediate_*` table.

### 2. LIVEARC branches
- **Misplaced block:** contains active `LIVEARC` branches for `MFG`, `FIN`, and `FIN_MFG` (e.g., joins to `[SQL-Lab-2].[LIVEARC].dbo.CUST_ORDER_LINE` / `CUSTOMER_ORDER`) and filters by `A.BASE_TABLE = 'LIVEARC'`.
- **Canonical block:** the `LIVEARC` branches are commented out. Only the `LIVE` branches remain active.

### 3. `BASE_TABLE` filter
- **Misplaced block:** explicitly filters `A.BASE_TABLE = 'LIVE'` for the `LIVE` branches.
- **Canonical block:** the `BASE_TABLE` filter is commented out for all branches.

### 4. Delete future unshipped rows
- **Misplaced block:** contains an active `DELETE`:
  ```sql
  DELETE FROM LIVESupplemental.dbo.PBI_Customer_Shipments_complement_OT
  WHERE TOTAL_SHIPPED_QTY = 0
    AND ADJUSTED_DUE_DATE >= DATEADD(DAY, 1, CONVERT(varchar(12), GETDATE(), 23))
  ```
- **Canonical block:** contains a similar `DELETE` against `Feed_01_Core_Intermediate_complement_OT`, but uses `CAST(GETDATE() AS DATE)` instead of the `CONVERT(varchar(12), GETDATE(), 23)` style.

### 5. On-time / late recalculation
- **Misplaced block:** the `ON_TIME1` / `LATE1` recalculation is present but is **inside the closing `*/`** of the comment block, so it is inactive.
- **Canonical block:** the recalculation is **active**.

### 6. Final insert / truncate
- **Misplaced block:** does **not** include the final `TRUNCATE`/`INSERT` into `Feed_01_Core_Intermediate_complement_OT_01` because it is only a fragment of ETL03.
- **Canonical block:** ends with:
  ```sql
  TRUNCATE TABLE LIVESupplemental.dbo.Feed_01_Core_Intermediate_complement_OT_01
  INSERT INTO LIVESupplemental.dbo.Feed_01_Core_Intermediate_complement_OT_01
  SELECT * FROM LIVESupplemental.dbo.Feed_01_Core_Intermediate_complement_OT
  ```

### 7. Activation state
- **Misplaced block:** the entire ETL03-like section is wrapped in `/* ... */` in [`zza_SP_SK_ETL01_CUST_SHIP.sql`](zza_SP_SK_ETL01_CUST_SHIP.sql), so it has no runtime effect.
- **Canonical block:** the logic is the main body of [`sp_Shipments_Core_Feed_03.sql`](sp_Shipments_Core_Feed_03.sql) and runs as part of that procedure.

## Summary
The code in [`zza_SP_SK_ETL01_CUST_SHIP.sql`](zza_SP_SK_ETL01_CUST_SHIP.sql) is a slightly older or test variant of `SP_SK_ETL03_CUST_SHIP`. It differs from the canonical implementation mainly by:

- Targeting `PBI_Customer_Shipments_complement_OT` instead of `Feed_01_Core_Intermediate_complement_OT`.
- Still including active `LIVEARC` branches and `BASE_TABLE` filters.
- Being commented out and therefore inactive.

Because it is inactive and the canonical logic already lives in [`sp_Shipments_Core_Feed_03.sql`](sp_Shipments_Core_Feed_03.sql), the block in [`zza_SP_SK_ETL01_CUST_SHIP.sql`](zza_SP_SK_ETL01_CUST_SHIP.sql) appears to be leftover exploratory / test code that should be removed if the test file is promoted to production.

## Related files
- [`zza_SP_SK_ETL01_CUST_SHIP.md`](zza_SP_SK_ETL01_CUST_SHIP.md) — original note identifying the misplaced code.
- [`zza_SP_SK_ETL01_CUST_SHIP.sql`](zza_SP_SK_ETL01_CUST_SHIP.sql) — ETL01 test file containing the misplaced block.
- [`sp_Shipments_Core_Feed_03.sql`](sp_Shipments_Core_Feed_03.sql) — canonical ETL03 implementation.
- [`zza_SP_SK_ETL03_CUST_SHIP.sql`](zza_SP_SK_ETL03_CUST_SHIP.sql) — misnamed; actually contains ETL02 code.
