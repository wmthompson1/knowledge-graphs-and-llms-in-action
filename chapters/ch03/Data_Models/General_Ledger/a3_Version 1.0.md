

## Version 0.9 (Retired)

Ontology:

```text
Current Posting
=
Highest DIST_NO Accumulation
-
Second Highest DIST_NO Accumulation
```

Implementation pattern:

```sql
DENSE_RANK() OVER (ORDER BY DIST_NO DESC)
WHERE dist_rank <= 2
```

Then:

```sql
Current - Previous
```

This calculates only the latest posting event. [\[skillsinc-...epoint.com\]](https://skillsinc-my.sharepoint.com/personal/williamt_skillsinc_org/Documents/Microsoft%20Copilot%20Chat%20Files/a3_Version%201.0.sql)

***

## Version 1.0 (Corrected)

Ontology:

```text
Posting Amount for DIST_NO N
=
Accumulation at DIST_NO N
-
Accumulation at Previous Existing DIST_NO
```

Examples:

```text
DIST 1 = 100.00
Posting = 100.00

DIST 2 = 125.00
Posting = 25.00

DIST 3 = 135.00
Posting = 10.00
```

And if DIST\_NO 2 is missing:

```text
DIST 1 = 100.00
DIST 3 = 135.00

Posting for DIST 3
=
135.00 - 100.00
=
35.00
```

which matches your costing utility rules. [\[skillsinc-...epoint.com\]](https://skillsinc-my.sharepoint.com/personal/williamt_skillsinc_org/Documents/Microsoft%20Copilot%20Chat%20Files/a3_Version%20.9.sql), [\[skillsinc-...epoint.com\]](https://skillsinc-my.sharepoint.com/personal/williamt_skillsinc_org/Documents/Microsoft%20Copilot%20Chat%20Files/a3_Version%201.0.sql)

***

## Migration Path

Replace:

```sql
*_ranked
*_top2
*_pivot
```

with:

```sql
*_accum
*_delta
```

using:

```sql
LAG()
OVER
(
    PARTITION BY workorder keys
    ORDER BY DIST_NO
)
```

Example:

```sql
WITH labor_accum AS
(
    SELECT
         WORKORDER_TYPE
        ,WORKORDER_BASE_ID
        ,WORKORDER_LOT_ID
        ,WORKORDER_SPLIT_ID
        ,WORKORDER_SUB_ID
        ,DIST_NO
        ,SUM(ACT_LABOR_COST) AS ACCUM_LABOR_COST
    FROM Live.dbo.WIP_LABOR_DETAIL
    WHERE WORKORDER_BASE_ID = @WORKORDER_BASE_ID
    GROUP BY
         WORKORDER_TYPE
        ,WORKORDER_BASE_ID
        ,WORKORDER_LOT_ID
        ,WORKORDER_SPLIT_ID
        ,WORKORDER_SUB_ID
        ,DIST_NO
),
labor_delta AS
(
    SELECT
         *
        ,LAG(ACCUM_LABOR_COST) OVER
        (
            PARTITION BY
                 WORKORDER_TYPE
                ,WORKORDER_BASE_ID
                ,WORKORDER_LOT_ID
                ,WORKORDER_SPLIT_ID
                ,WORKORDER_SUB_ID
            ORDER BY DIST_NO
        ) AS PREV_ACCUM_LABOR_COST
    FROM labor_accum
)
SELECT
     WORKORDER_BASE_ID
    ,DIST_NO
    ,ACCUM_LABOR_COST
    ,ACCUM_LABOR_COST
       - ISNULL(PREV_ACCUM_LABOR_COST,0) AS LABOR_DELTA
FROM labor_delta;
```

***

## Expected Unit Test

Using your sample labor data:

```text
DIST_NO 1 =      8.69
DIST_NO 2 =  94,463.69
DIST_NO 3 =  95,019.14
DIST_NO 4 =  95,656.48
```

Expected results:

```text
DIST_NO 1  DELTA =      8.69
DIST_NO 2  DELTA = 94,455.00
DIST_NO 3  DELTA =    555.45
DIST_NO 4  DELTA =    637.34
```

The important validation is that:

```text
637.34
=
95,656.48
-
95,019.14
```

not

```text
95,656.48
-
555.45
```

and not a "top two distribution" calculation. [\[skillsinc-...epoint.com\]](https://skillsinc-my.sharepoint.com/personal/williamt_skillsinc_org/Documents/Microsoft%20Copilot%20Chat%20Files/Labor%20Cost%20job%20costing%20query%20version%201%20data%20profile.sql), [\[skillsinc-...epoint.com\]](https://skillsinc-my.sharepoint.com/personal/williamt_skillsinc_org/Documents/Microsoft%20Copilot%20Chat%20Files/a3_Version%201.0.sql)

So from a source-control perspective I'd document the change as:

```text
Version .9
  Latest DIST_NO minus Previous DIST_NO

Version 1.0
  Current Accumulation minus Prior Accumulation
  using LAG() across DIST_NO sequence
```

That is the fundamental design correction driving the new unit tests. [\[skillsinc-...epoint.com\]](https://skillsinc-my.sharepoint.com/personal/williamt_skillsinc_org/Documents/Microsoft%20Copilot%20Chat%20Files/a3_Version%201.0.sql), [\[skillsinc-...epoint.com\]](https://skillsinc-my.sharepoint.com/personal/williamt_skillsinc_org/Documents/Microsoft%20Copilot%20Chat%20Files/a3_Version%20.9.sql)
