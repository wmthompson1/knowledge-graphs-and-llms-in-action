
![alt text](image.png)


## 1
1. Linked Server Joins (Biggest Performance Hit)
The four LEFT OUTER JOIN operations to [sql-bi-1].datawarehouse will cause massive performance issues:
•	Network latency for every row
•	No parallel execution across linked servers
•	Remote server may scan entire tables
Solution:

```sql
-- Option A: Use OPENQUERY to push filtering to the remote server.
-- OPENQUERY requires a literal query string; it cannot take a variable.
SELECT *
INTO #PO
FROM OPENQUERY([sql-bi-1], '
    SELECT RECORD_ID, ALT_ID_1, ALT_ID_2, ALT_ID_3, ALT_ID_4, ALT_ID_5
    FROM datawarehouse.dbo.VQ_PRODUCTION_ORDER
');

CREATE INDEX IX_PO ON #PO(ALT_ID_2, ALT_ID_3, ALT_ID_4, ALT_ID_5, ALT_ID_1);

-- Then join to #PO instead of the remote table.


```

## 2. String Concatenation Join to VQ_OPERATION

```sql
-- This prevents index usage:
ON IO.[ID] = CAST(O.WORKORDER_TYPE AS NVARCHAR(1)) + '~' + CAST(O.WORKORDER_BASE_ID AS NVARCHAR(7)) + ...
```
**Solution:** Materialize this into a temp table with a computed persisted column or calculate once.

# 🟡 Performance Improvements ##
## 4. Pre-calculate Date Variables


## pre-calc date variables

DECLARE @STARTDATE date = '2026-06-29';
DECLARE @ENDDATE date = '2026-07-05';
DECLARE @TIMEFRAME nvarchar(25) = 'LAST WEEK';

-- Calculate once before the query
DECLARE @CalcStartDate DATE = CASE
    WHEN @TIMEFRAME = 'LAST WEEK' THEN CONVERT(DATE, DATEADD(WEEK, DATEDIFF(WEEK, 7, GETDATE()), 0))
    WHEN @TIMEFRAME = 'CURRENT WEEK' THEN CONVERT(DATE, DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE()), 0))
    -- ... etc
    WHEN @TIMEFRAME = 'OTHER' THEN @STARTDATE
    ELSE NULL
END;

DECLARE @CalcEndDate DATE = CASE
    WHEN @TIMEFRAME = 'LAST WEEK' THEN CONVERT(DATE, DATEADD(WEEK, DATEDIFF(WEEK, 7, GETDATE()), 6))
    -- ... etc
    WHEN @TIMEFRAME = 'OTHER' THEN @ENDDATE
    ELSE NULL
END;

##  ✅ Optimized Query Structure