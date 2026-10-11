## suspect code
```sql
SELECT A.*, MAX(DATEADD(DD,-(DAY(FILTER_DATE)-1), FILTER_DATE)) AS FILTER_PERIOD
	, PSF.[Target] AS 'TARGET_GOALS'
INTO #CTE_FINAL
FROM CTE_FULL A
LEFT OUTER JOIN [SQL-Bi-1].[LIVESupplemental].[dbo].[Plant_Shipment_Forecast] PSF
	ON PSF.BusStream = A.BUS_STREAM AND PSF.[Date] = DATEADD(DD,-(DAY(A.FILTER_DATE)-1), A.FILTER_DATE)

GROUP BY CTE, CUSTOMER_ID, CUST_ORDER_ID, COL_LINE_NO, ORDER_DATE, CREATE_DATE, DESIRED_SHIP_DATE
	, [FILTER_CASE], FILTER_DATE, CO_STATUS, [UPDATE_USING_MISC_REF], SERVICE_CHARGE_ID, LINE_TYPE
	, LINE_ITEM, CHARGE_TYPE, CUST_PART_DESC, COL_PARTID, P2ID, PART_ID, [DESCRIPTION], PART_PROD_CODE
	, PART_COMM_CODE, PLANNER_USER_ID, BUYER_USER_ID, SHIP_SHORT, ORDER_QTY, TOTAL_SHIPPED_QTY
	, UNSHIPPEDQTY, REMQTY, UNIT_PRICE, BUS_STREAM, MATERIAL_TYPE, PACKLIST_ID, PACKLIST_LINE_NO
	, SHIPPED_QTY, SHIPPED_DATE, INVOICE_DATE, INVOICE_ID, INVOICE_LINE, INVOICE_AMT, INVOICE_QTY
	, ADJ_DUE_DATE, SHIPPED_AMOUNT, UNSHIPPED_AMOUNT, ADJUSTED_DUE_DATE, SUPPLY_TYPE, BASE_ID
	, LOT_ID, SPLIT_ID, SUB_ID, ORDER_STATUS, MFG_COUNT, FIN_COUNT, O_COUNT, NULL_COUNT
	, UPD_BUS_STREAM, PSF.[Target]
```

My conclusion

Based on everything you've shown:

✅ The problematic field is MAX SHIPPED DATE.

✅ The Power BI diagnostic query is reporting a type mismatch, not a null-value problem.

✅ The root cause is most likely an ETL change that caused MAX SHIPPED DATE to return text or mixed data types instead of a pure date value.

The next place I'd investigate is the exact SQL expression that creates [MAX SHIPPED DATE], because that's where I expect you'll find the bug.

## Response

Nice. I think we've found the trail.

The SQL you posted is unlikely to be the direct source of the error itself because:

MAX(DATEADD(DD,-(DAY(FILTER_DATE)-1), FILTER_DATE)) AS FILTER_PERIOD


returns a date, assuming FILTER_DATE is a date.

What jumps out at me is the GROUP BY combined with the downstream Power BI column name MAX SHIPPED DATE.

My guess is that elsewhere in the ETL there is a similar construct such as:

MAX(SHIPPED_DATE) AS [MAX SHIPPED DATE]


and sometime after that a developer introduced a CASE expression or conversion that changed the output type.

The evidence from Power BI is:

Error column = MAX SHIPPED DATE
Error count = ~47,000 rows
Diagnostic query says type mismatch
Nulls are allowed by the diagnostic query, so the issue is not simply NULL values

That leaves:

Text in a date column
Datetime being treated as another type
A CASE expression returning mixed types

For example:

CASE
    WHEN PACKLIST_ID IS NULL THEN ''
    ELSE MAX(SHIPPED_DATE)
END AS [MAX SHIPPED DATE]


or

CASE
    WHEN SHIPPED_DATE IS NULL THEN 'LATE'
    ELSE CONVERT(VARCHAR(10), SHIPPED_DATE, 101)
END


Both would produce exactly the kind of Power BI errors you're seeing.

What I'd do in SQL Server

Locate where [MAX SHIPPED DATE] is defined.

Then run:

SELECT TOP (100)
       [MAX SHIPPED DATE]
FROM <final_source>
ORDER BY [MAX SHIPPED DATE];


and

SELECT
    SQL_VARIANT_PROPERTY([MAX SHIPPED DATE], 'BaseType') AS BaseType,
    COUNT(*) AS Cnt
FROM <final_source>
GROUP BY SQL_VARIANT_PROPERTY([MAX SHIPPED DATE], 'BaseType');


If it's derived, inspect the source expression.

What I'd do in Power BI

Open the original Total Transactions query and look for the step where:

#"Changed Type"


contains:

{"MAX SHIPPED DATE", type date}


Then temporarily change it to:

{"MAX SHIPPED DATE", type text}


If the errors disappear, you've conclusively proven that Power BI is receiving non-date values in that column.

My conclusion

Based on everything you've shown:

✅ The problematic field is MAX SHIPPED DATE.

✅ The Power BI diagnostic query is reporting a type mismatch, not a null-value problem.

✅ The root cause is most likely an ETL change that caused MAX SHIPPED DATE to return text or mixed data types instead of a pure date value.

The next place I'd investigate is the exact SQL expression that creates [MAX SHIPPED DATE], because that's where I expect you'll find the bug.