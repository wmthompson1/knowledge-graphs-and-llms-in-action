No matches found. Your search pattern might be excluded completely by either the search.exclude settings or .*ignore files.
If you believe that it should have results, you can check into the .*ignore files and the exclude setting (here are some excluded patterns for reference:[**/node_modules,**/bower_components,**/*.code-search]).
Then if you want to include those files you can call the tool again by setting "includeIgnoredFiles" to true.

No matches found. Your search pattern might be excluded completely by either the search.exclude settings or .*ignore files.
If you believe that it should have results, you can check into the .*ignore files and the exclude setting (here are some excluded patterns for reference:[**/node_modules,**/bower_components,**/*.code-search]).
Then if you want to include those files you can call the tool again by setting "includeIgnoredFiles" to true.

Searched for regex `ISNULL\([^)]*(DATE|date|SHIP|INVOICE|RLS|DUE)[^)]*,\s*''\)` (`**/Documentation/Schema/Data_Models/Customer_Order/Shipping/*.sql`), 3 results

No matches found. Your search pattern might be excluded completely by either the search.exclude settings or .*ignore files.
If you believe that it should have results, you can check into the .*ignore files and the exclude setting (here are some excluded patterns for reference:[**/node_modules,**/bower_components,**/*.code-search]).
Then if you want to include those files you can call the tool again by setting "includeIgnoredFiles" to true.

Searched for regex `CONVERT\(varchar\([^)]*\),[^,]+,\s*23\)` (`**/Documentation/Schema/Data_Models/Customer_Order/Shipping/*.sql`), 2 results

No matches found. Your search pattern might be excluded completely by either the search.exclude settings or .*ignore files.
If you believe that it should have results, you can check into the .*ignore files and the exclude setting (here are some excluded patterns for reference:[**/node_modules,**/bower_components,**/*.code-search]).
Then if you want to include those files you can call the tool again by setting "includeIgnoredFiles" to true.

Searched for regex `ISNULL\([^\n]*,\s*''\)` (`**/Documentation/Schema/Data_Models/Customer_Order/Shipping/*.sql`), 16 results

No matches found. Your search pattern might be excluded completely by either the search.exclude settings or .*ignore files.
If you believe that it should have results, you can check into the .*ignore files and the exclude setting (here are some excluded patterns for reference:[**/node_modules,**/bower_components,**/*.code-search]).
Then if you want to include those files you can call the tool again by setting "includeIgnoredFiles" to true.

Searched for regex `CONVERT\(varchar` (`**/Documentation/Schema/Data_Models/Customer_Order/Shipping/*.sql`), 4 results

No matches found. Your search pattern might be excluded completely by either the search.exclude settings or .*ignore files.
If you believe that it should have results, you can check into the .*ignore files and the exclude setting (here are some excluded patterns for reference:[**/node_modules,**/bower_components,**/*.code-search]).
Then if you want to include those files you can call the tool again by setting "includeIgnoredFiles" to true.

Searched for regex `THEN\s+''|ELSE\s+''` (`**/Documentation/Schema/Data_Models/Customer_Order/Shipping/*.sql`), 15 results

## Search results for date-to-string anti-patterns

I searched the three shipping feed procedures for the four patterns you listed.

### Pattern 1: `CONVERT(varchar, SomeDate, 23)` / `CONVERT(varchar(N), SomeDate, 23)`

**Found 4 matches in 2 files:**

| File | Line | Match |
|---|---|---|
| sp_Shipments_Core_Feed_01.sql | 609 | `CONVERT(varchar(12), DATEADD(DAY, 10, A.DESIRED_RLS_DATE), 23)` |
| sp_Shipments_Core_Feed_01.sql | 616 | `CONVERT(varchar(12), DATEADD(DAY, 30, A.DESIRED_RLS_DATE), 23)` |
| sp_Shipments_Core_Feed_01.sql | 723 | `DATEADD(DAY, 1, CONVERT(varchar(12), GETDATE(), 23))` |
| sp_Shipments_Core_Feed_03.sql | 128 | `DATEADD(DAY, 1, CONVERT(varchar(12), GETDATE(), 23))` |

All four are date-to-`varchar(12)` round-trips. Lines 609/616 assign `varchar` to `ADJUSTED_DUE_DATE`; lines 723/128 compare `ADJUSTED_DUE_DATE` against a `varchar`-cast `GETDATE()`.

### Pattern 2: `CAST(SomeDate AS varchar)`

**Found 0 matches.**

### Pattern 3: `ISNULL(SomeDate, '')`

**Found 0 matches on date columns.**  
The only `ISNULL(x, '')` hits are on string columns (`INVOICE_ID`, `USER_1`, `SKILLS_TYPE`, `CUSTOMER_ID`), which is fine.

### Pattern 4: `CASE WHEN SomeDate IS NULL THEN '' ELSE SomeDate END`

**Found 0 matches.**

---

### Additional related hits

The `CONVERT(DATE, …)` casts elsewhere in the files are correct (e.g., `CONVERT(DATE, CO.ORDER_DATE)`, `CONVERT(DATE, S.SHIPPED_DATE)`). The only problematic conversions are the four `varchar(12), 23` instances listed above.

### Recommended replacements

```sql
-- Feed 01, line ~609
CONVERT(DATE, DATEADD(DAY, 10, A.DESIRED_RLS_DATE))

-- Feed 01, line ~616
CONVERT(DATE, DATEADD(DAY, 30, A.DESIRED_RLS_DATE))

-- Feed 01 line ~723 and Feed 03 line ~128
DATEADD(DAY, 1, CAST(GETDATE() AS DATE))
```

Do you want me to apply these four replacements?