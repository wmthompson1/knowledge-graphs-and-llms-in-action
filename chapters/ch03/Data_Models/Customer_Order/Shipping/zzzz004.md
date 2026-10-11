AND ADJUSTED_DUE_DATE >= DATEADD(DAY, 1, CAST(GETDATE() AS DATE))

Searched for files matching `**/Documentation/Schema/Data_Models/Customer_Order/Shipping/sp_Shipments_Core_Feed_*.sql`, 3 matches

Read [](file:///c%3A/Users/williamt/source/skillsinc/skills-inc-org/SQL-Projects/Documentation/Schema/Data_Models/Customer_Order/Shipping/sp_Shipments_Core_Feed_02.sql#1-1), lines 1 to 300

Read [](file:///c%3A/Users/williamt/source/skillsinc/skills-inc-org/SQL-Projects/Documentation/Schema/Data_Models/Customer_Order/Shipping/sp_Shipments_Core_Feed_03.sql)

Read [](file:///c%3A/Users/williamt/source/skillsinc/skills-inc-org/SQL-Projects/Documentation/Schema/Data_Models/Customer_Order/Shipping/sp_Shipments_Core_Feed_02.sql#300-300), lines 300 to 349

Read [](file:///c%3A/Users/williamt/source/skillsinc/skills-inc-org/SQL-Projects/Documentation/Schema/Data_Models/Customer_Order/Shipping/sp_Shipments_Core_Feed_03.sql)

Searched for files matching `**/Utilities/SQLMesh/ddl/**/*.sql`, 50 matches

Searched for regex `CREATE TABLE.*(CUSTOMER_ORDER|CUST_ORDER_LINE|SHIPPER|SHIPPER_LINE|RECEIVABLE|RECEIVABLE_LINE|WORK_ORDER|DEMAND_SUPPLY_LINK)` (`**/Utilities/SQLMesh/ddl/**`), 24 results

Read [](file:///c%3A/Users/williamt/source/skillsinc/skills-inc-org/SQL-Projects/Utilities/SQLMesh/ddl/dbo.CUSTOMER_ORDER.sql#1-1), lines 1 to 120

Read [](file:///c%3A/Users/williamt/source/skillsinc/skills-inc-org/SQL-Projects/Utilities/SQLMesh/ddl/dbo.CUST_ORDER_LINE.sql#1-1), lines 1 to 120

Read [](file:///c%3A/Users/williamt/source/skillsinc/skills-inc-org/SQL-Projects/Utilities/SQLMesh/ddl/dbo.SHIPPER.sql)

Read [](file:///c%3A/Users/williamt/source/skillsinc/skills-inc-org/SQL-Projects/Utilities/SQLMesh/ddl/dbo.SHIPPER_LINE.sql)

Read [](file:///c%3A/Users/williamt/source/skillsinc/skills-inc-org/SQL-Projects/Utilities/SQLMesh/ddl/dbo.RECEIVABLE.sql)

Read [](file:///c%3A/Users/williamt/source/skillsinc/skills-inc-org/SQL-Projects/Utilities/SQLMesh/ddl/dbo.RECEIVABLE_LINE.sql)

Read [](file:///c%3A/Users/williamt/source/skillsinc/skills-inc-org/SQL-Projects/Utilities/SQLMesh/ddl/dbo.WORK_ORDER.sql)

Read [](file:///c%3A/Users/williamt/source/skillsinc/skills-inc-org/SQL-Projects/Utilities/SQLMesh/ddl/dbo.DEMAND_SUPPLY_LINK.sql)

No matches found. Your search pattern might be excluded completely by either the search.exclude settings or .*ignore files.
If you believe that it should have results, you can check into the .*ignore files and the exclude setting (here are some excluded patterns for reference:[**/node_modules,**/bower_components,**/*.code-search]).
Then if you want to include those files you can call the tool again by setting "includeIgnoredFiles" to true.

Searching for regex `CREATE TABLE.*PBI_Customer_Shipments|CREATE TABLE.*Feed_01_Core_Intermediate|CREATE TABLE.*Plant_Shipment_Forecast`

Searched for regex `CONVERT\(varchar\(12\),.*23\)|CONVERT\(varchar.*GETDATE\(\)` (`**/Documentation/Schema/Data_Models/Customer_Order/Shipping/*.sql`), 4 results

## Date-field type review for the three shipping feeds

I walked the source schema (canonical DDL under ddl) and compared it against the three feed files. The source columns are all `datetime`, while the feed code mostly casts them to `date` with `CONVERT(DATE, …)`. There are a few places where the value becomes a `varchar` instead, plus a couple of `datetime` comparisons that should be `date`.

### Schema facts
- `CUSTOMER_ORDER.ORDER_DATE`, `CREATE_DATE`, `DESIRED_SHIP_DATE`, `PROMISE_DATE` → `datetime`
- `CUST_ORDER_LINE.DESIRED_SHIP_DATE`, `PROMISE_DATE` → `datetime`
- `SHIPPER.SHIPPED_DATE`, `INVOICED_DATE`, `CREATE_DATE` → `datetime`
- `RECEIVABLE.INVOICE_DATE`, `CREATE_DATE`, `POSTING_DATE` → `datetime`
- `WORK_ORDER.DESIRED_RLS_DATE`, `DESIRED_WANT_DATE` → `datetime`

---

### Findings by file

#### sp_Shipments_Core_Feed_01.sql

| Line(s) | Code | Problem |
|---|---|---|
| ~609 | `CONVERT(varchar(12), DATEADD(DAY, 10, A.DESIRED_RLS_DATE), 23)` | `ADJUSTED_DUE_DATE` is being assigned a `varchar(12)` (ISO `yyyy-mm-dd`) instead of a `DATE`. |
| ~616 | `CONVERT(varchar(12), DATEADD(DAY, 30, A.DESIRED_RLS_DATE), 23)` | Same issue for `CMP-MFG` rows. |
| ~723 | `DATEADD(DAY, 1, CONVERT(varchar(12), GETDATE(), 23))` | `GETDATE()` is converted to `varchar` then back through `DATEADD`, instead of `DATEADD(DAY, 1, CAST(GETDATE() AS DATE))`. |

**Suggested fixes:**

```sql
-- Line ~609
CONVERT(DATE, DATEADD(DAY, 10, A.DESIRED_RLS_DATE))

-- Line ~616
CONVERT(DATE, DATEADD(DAY, 30, A.DESIRED_RLS_DATE))

-- Line ~723
AND ADJUSTED_DUE_DATE >= DATEADD(DAY, 1, CAST(GETDATE() AS DATE))
```

Also note: earlier in the same file `CONVERT(DATE, …)` is used correctly for `ORDER_DATE`, `CREATE_DATE`, `DESIRED_SHIP_DATE`, `SHIPPED_DATE`, `INVOICE_DATE`, and `FILTER_DATE`.

---

#### sp_Shipments_Core_Feed_02.sql

This file is an incomplete copy of Feed 01’s first stage. The date handling I can see is consistent:

- `CONVERT(DATE, CO.ORDER_DATE) AS ORDER_DATE`
- `CONVERT(DATE, CO.CREATE_DATE) AS CREATE_DATE`
- `CONVERT(DATE, ISNULL(COL.DESIRED_SHIP_DATE, CO.DESIRED_SHIP_DATE)) AS DESIRED_SHIP_DATE`
- `CONVERT(DATE, S.SHIPPED_DATE) AS SHIPPED_DATE`
- `CONVERT(DATE, R.INVOICE_DATE) AS INVOICE_DATE`
- `CONVERT(DATE, DATEADD(DD, …)) AS ADJ_DUE_DATE`

No `varchar(12)` date issues found in the visible portion. However, the file is truncated mid-procedure and still references the linked-server table `[SQL-Bi-1].[LIVESupplemental].[dbo].[Plant_Shipment_Forecast]`.

---

#### sp_Shipments_Core_Feed_03.sql

| Line | Code | Problem |
|---|---|---|
| ~128 | `DATEADD(DAY, 1, CONVERT(varchar(12), GETDATE(), 23))` | Same `varchar` round-trip as Feed 01. |

**Suggested fix:**

```sql
AND ADJUSTED_DUE_DATE >= DATEADD(DAY, 1, CAST(GETDATE() AS DATE))
```

The date comparisons `A.[FILTER_DATE] <= A.[ADJUSTED_DUE_DATE]` later in the file are fine if both columns are `date`/`datetime`.

---

### Summary of required changes

1. **Feed 01** — replace two `CONVERT(varchar(12), …, 23)` expressions with `CONVERT(DATE, …)` when setting `ADJUSTED_DUE_DATE`.
2. **Feed 01 & Feed 03** — replace `DATEADD(DAY, 1, CONVERT(varchar(12), GETDATE(), 23))` with `DATEADD(DAY, 1, CAST(GETDATE() AS DATE))`.
3. **Feed 02** — no date-type issues found in the visible portion, but the procedure is incomplete and still has the linked-server dependency.

Do you want me to apply these fixes to the three files?