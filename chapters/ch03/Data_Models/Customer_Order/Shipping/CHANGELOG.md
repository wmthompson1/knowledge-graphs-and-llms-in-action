# Changelog — Customer Order Shipping Core Feeds

This file captures break-fix changes and architectural lessons for the shipping core feed stored procedures in this directory.

---

## 2026-08-04 — `sp_Shipments_Core_Feed_02.sql`: Fix `CTE_FULL` UNION column mismatch and standardize on `ADJUSTED_DUE_DATE`

### Affected file
- [sp_Shipments_Core_Feed_02.sql](sp_Shipments_Core_Feed_02.sql)

### Symptoms
Compilation failed with:

```
Msg 205, Level 16, State 1, Procedure sp_Shipments_Core_Feed_02, Line <n>
All queries combined using a UNION, INTERSECT or EXCEPT operator must have an equal number of expressions in their target lists.
```

### Root cause
`CTE_FULL` combined two branches with `UNION ALL`:

```sql
, CTE_FULL AS
(
    SELECT 'BASE' AS CTE, *
    FROM CTE_BS

    UNION ALL

    SELECT 'REMAINING' AS CTE,
           CUSTOMER_ID, CUST_ORDER_ID, ..., ADJUSTED_DUE_DATE, ...
    FROM CTE_REMAINING
)
```

The `BASE` branch used `SELECT *`, which implicitly inherited every column from `CTE_BS` — including `ADJ_DUE_DATE`. The `REMAINING` branch used an explicit projection that omitted `ADJ_DUE_DATE` in favor of `ADJUSTED_DUE_DATE`. The mismatch produced Msg 205.

This was an instance of a broader anti-pattern:

> `SELECT *` inside a `UNION` or `UNION ALL` creates a hidden dependency on the upstream column list. Whenever a column is added, renamed, or removed, the two branches can silently drift out of alignment.

### What was changed
1. Replaced `SELECT 'BASE' AS CTE, *` with the same explicit column list used in the `REMAINING` branch.
2. Removed `ADJ_DUE_DATE` from the `CTE_FULL` projection so only `ADJUSTED_DUE_DATE` flows downstream.
3. Updated the `GROUP BY` in the final `SELECT` to remove the obsolete `ADJ_DUE_DATE` reference.
4. Updated the `INSERT` column list and source `SELECT` to use only `ADJUSTED_DUE_DATE`.

### Result
Both branches of `CTE_FULL` now have identical, explicit column layouts, and the pipeline consistently uses `ADJUSTED_DUE_DATE`.

### Commit
- `fd64cb470a9e07a8c05f7267fc24af6f99d0ff07`

### Related notes
- Raw session logs: [zzzz008.md](zzzz008.md), [zzzz009.md](zzzz009.md), [zzzz010.md](zzzz010.md), [zzzz011.md](zzzz011.md)

---

## 2026-08-04 — `zza_SP_SK_ETL03_CUST_SHIP.sql`: Correct procedure name and align with canonical ETL03

### Affected file
- [zza_SP_SK_ETL03_CUST_SHIP.sql](zza_SP_SK_ETL03_CUST_SHIP.sql)

### Problem
- `zza_SP_SK_ETL03_CUST_SHIP.sql` was misnamed and actually contained `SP_SK_ETL02_CUST_SHIP` code.
- The legacy/current `SP_SK_ETL03_CUST_SHIP` code was also duplicated in [x3.sql](../10%20Sales/x3.sql) and [403 SP_SK_ETL03_CUST_SHIP.sql](../../Receivables/403%20SP_SK_ETL03_CUST_SHIP.sql).
- The canonical Core Feed 03 implementation in [sp_Shipments_Core_Feed_03.sql](sp_Shipments_Core_Feed_03.sql) uses a cleaner style (no `LIVEARC` branches, no `BASE_TABLE` filters, modern date casting).

### What was changed
1. Replaced the contents of `zza_SP_SK_ETL03_CUST_SHIP.sql` with the corrected `SP_SK_ETL03_CUST_SHIP` code.
2. Removed the `LIVEARC` branches for `MFG`, `FIN`, and `FIN_MFG`.
3. Removed the `BASE_TABLE = 'LIVE'` filters from the remaining `LIVE` branches.
4. Modernized the future-date delete from `CONVERT(varchar(12), GETDATE(), 23)` to `CAST(GETDATE() AS DATE)`.
5. Retained the legacy `PBI_Customer_Shipments_complement_OT` table interface, the CBO exclusion, and the redundant self-joins to minimize behavioral risk.

### Validation
> **⚠️ Invalidated.** The compile-only parse check, metadata check, and row-count capture were run against `SQL-LAB-1 / LIVE`. That connection violated the receiving-certificate policy and the explicit prohibition against `lab-01`. These results must not be relied upon.
>
> Valid database validation must use a current receiving certificate (e.g., `certificate_for_receiving/receiving_certificate_RECV-2026-07-28-002.json`) and the approved pre-stage server `Crunch2018` / `Crunch0626`, via the workflow in `certificate_for_receiving/border_crossing_ground_truth.py`.

### Related files
- [ETL03_Migration_Worksheet.md](ETL03_Migration_Worksheet.md)
- [SP_SK_ETL03_comparison.md](SP_SK_ETL03_comparison.md)
- [sp_Shipments_Core_Feed_03.sql](sp_Shipments_Core_Feed_03.sql)
