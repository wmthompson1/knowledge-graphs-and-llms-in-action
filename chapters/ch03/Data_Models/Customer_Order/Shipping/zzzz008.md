Read [](file:///c%3A/Users/williamt/source/skillsinc/skills-inc-org/SQL-Projects/Documentation/Schema/Data_Models/Customer_Order/Shipping/sp_Shipments_Core_Feed_02.sql#260-260), lines 260 to 340

I don’t have a file-edit tool available right now, so here is the exact replacement for the broken `CTE_FULL` and `INSERT` sections in sp_Shipments_Core_Feed_02.sql.

### Replace lines 277–294

```sql
, CTE_FULL AS 
(	SELECT 'BASE' AS CTE, * FROM CTE_BS
	UNION ALL
	SELECT 'REMAINING' AS CTE, CUSTOMER_ID, CUST_ORDER_ID, COL_LINE_NO, ORDER_DATE, CREATE_DATE
		, DESIRED_SHIP_DATE, [FILTER_CASE], DESIRED_SHIP_DATE AS 'FILTER_DATE', CO_STATUS
		, [UPDATE_USING_MISC_REF], SERVICE_CHARGE_ID, LINE_TYPE, LINE_ITEM, CHARGE_TYPE, CUST_PART_DESC
		, COL_PARTID, P2ID, PART_ID, [DESCRIPTION], PART_PROD_CODE, PART_COMM_CODE, PLANNER_USER_ID
		, BUYER_USER_ID, SHIP_SHORT, ORDER_QTY, TOTAL_SHIPPED_QTY, UNSHIPPEDQTY, REMQTY, UNIT_PRICE
		, BUS_STREAM, MATERIAL_TYPE, NULL AS 'PACKLIST_ID', NULL AS 'PACKLIST_LINE_NO', NULL AS 'SHIPPED_QTY'
		, NULL AS 'SHIPPED_DATE', NULL AS 'INVOICE_DATE', NULL AS 'INVOICE_ID', NULL AS 'INVOICE_LINE'
		, NULL AS 'INVOICE_AMT' , NULL AS 'INVOICE_QTY'
		, ADJUSTED_DUE_DATE, SHIPPED_AMOUNT, UNSHIPPED_AMOUNT
		, SUPPLY_TYPE, BASE_ID, LOT_ID, SPLIT_ID, SUB_ID, ORDER_STATUS, MFG_COUNT
		, FIN_COUNT, O_COUNT, NULL_COUNT, UPD_BUS_STREAM
	FROM CTE_REMAINING
)
```

### Replace the `GROUP BY` line containing `ADJ_DUE_DATE`

Change:

```sql
, ADJ_DUE_DATE, SHIPPED_AMOUNT, UNSHIPPED_AMOUNT, ADJUSTED_DUE_DATE, SUPPLY_TYPE, BASE_ID
```

to:

```sql
, SHIPPED_AMOUNT, UNSHIPPED_AMOUNT, ADJUSTED_DUE_DATE, SUPPLY_TYPE, BASE_ID
```

### Replace the `INSERT` column list lines

Change:

```sql
, [ADJ_DUE_DATE], [SHIPPED_AMOUNT], [UNSHIPPED_AMOUNT], [ADJUSTED_DUE_DATE], [SUPPLY_TYPE] 
```

to:

```sql
, [SHIPPED_AMOUNT], [UNSHIPPED_AMOUNT], [ADJUSTED_DUE_DATE], [SUPPLY_TYPE] 
```

### Explanation

- `CTE_BASE` only outputs `ADJUSTED_DUE_DATE`; there is no `ADJ_DUE_DATE` in this version of the procedure.
- The `CTE_FULL` remaining-row projection referenced the missing `ADJ_DUE_DATE`, causing the `Invalid column name` error.
- Removing the duplicate/obsolete `ADJ_DUE_DATE` reference from the `SELECT`, `GROUP BY`, and `INSERT` lists resolves it.