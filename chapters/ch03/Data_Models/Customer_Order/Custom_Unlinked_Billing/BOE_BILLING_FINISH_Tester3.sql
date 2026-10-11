--USE [Datamart]
--GO

--/****** Object:  StoredProcedure [dbo].[usp_BOE_BILLING_FINISH]    Script Date: 8/26/2025 8:44:37 AM ******/
--SET ANSI_NULLS ON
--GO

--SET QUOTED_IDENTIFIER ON
--GO

/**********************************************************************************************
Description:
Sample:
Date      Modified By      Change Description
---------- ------------------ ------------------------------------------------------------
09/13/2019	traci treffert	Created


how will it register as unshipped in the feed?


## Shipments Core Feed 1

```sql
SELECT * FROM LIVESupplemental.dbo.PBI_Customer_Shipments_complement 
WHERE FILTER_DATE >= '2025-01-01'
```


## BOE Billing Core Feed 2

```sql
Select top 10 
   PackSlip, [unit price], [extended dollars], [expedite dollars], [special fees], [setup hours], [run hours], [expedite hours], [pack slips / date], [invoice id], [comments]
FROM LIVESupplemental.dbo.Feed_02_Core_BOE_Billing
```


williamt, ai:
Notice what is missing from group by
```
COL.CUST_ORDER_ID
COL.LINE_NO

```
The query begins with Customer Order Line as the driving table, but after joining to 
labor transactions and grouping, the final result grain becomes approximately:

```
Invoice
 + Pack Slip
 + Part Number
 + RAMAC (Customer Order)
 + Billed Quantity
 + Billing Attributes
 ```

 So the query is not strictly maintained at Customer Order Line level. It is more accurately 
 a shipped/invoiced billing line summarized from labor-ticket detail. The aggregation against 
 LABOR_TICKET prevents labor duplication, but the final grain is determined by the GROUP BY, 
 which does not include the customer order line key.

**/

-- exec usp_BOE_BILLING_FINISH @startdate = '2026-08-01', @enddate = '2026-08-31'
-- =============================================



----ALTER PROCEDURE [dbo].[usp_BOE_BILLING_FINISH] (@STARTDATE DATE, @ENDDATE DATE) AS


SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET DEADLOCK_PRIORITY LOW

DECLARE @CHARGE DECIMAL(14, 4) = (SELECT CHARGE FROM [SQL-BI-1].LIVESupplemental.dbo.[BOE_Billing_Charges] WHERE [REPORT] = 'usp_BOE_BILLING_FINISH')
;

DECLARE @STARTDATE DATE = '2026-08-01';
DECLARE @ENDDATE DATE = '2026-08-31';
Declare @cust_order_id NVARCHAR(50) = '002060914';   -- 002057414  -- 002060914

SELECT  
-- SPROC
-- unshipped
  CONCAT(SPROC, '_unsh') SPROC
  , 1 AS [UNSHIPPED_FLAG]
	--, [COST ITEM]
	, CAST ([COST ITEM] AS NVARCHAR(20)) AS [COST ITEM]
	, [POS]
	, [PART NUMBER]
	, [RAMAC]
    -- Include the ordered quantity for reference
	,  [BILLED QTY]
	, CASE
		WHEN [BILLED QTY] <= 0 THEN 0.
		WHEN [Description] LIKE 'Stanchion%' THEN [Finish_Unit Run Hours] * [BILLED QTY] * @CHARGE / ISNULL([BILLED QTY], 1)
		WHEN [Description] LIKE 'Cargo Panel%' THEN [Finish_Unit Run Hours] * [BILLED QTY] * @CHARGE / ISNULL([BILLED QTY], 1)
		ELSE (SUM(SORT_SETUP) + SUM(SORT_RUN)) * @CHARGE / ISNULL([BILLED QTY], 1)
	END AS [UNIT PRICE]
	, CASE 
		WHEN [BILLED QTY] <= 0. THEN 0.
		WHEN [Description] LIKE 'Stanchion%' THEN [Finish_Unit Run Hours] * [BILLED QTY] * @CHARGE
		WHEN [Description] LIKE 'Cargo Panel%' THEN [Finish_Unit Run Hours] * [BILLED QTY] * @CHARGE
		ELSE (SUM(SORT_SETUP) + SUM(SORT_RUN)) * @CHARGE
	END AS [EXTENDED DOLLARS]
	, [EXPEDITE DOLLARS]
	, [SPECIAL FEES]
	, 0 AS [SERVICE_FEES]
	, CASE 
		WHEN [Description] IS NOT NULL THEN 0.
		ELSE SUM(SORT_SETUP)
	END AS [SETUP HOURS]
	, CASE 
		WHEN [BILLED QTY] <= 0. THEN 0.
		WHEN [Description] LIKE 'Stanchion%' THEN [Finish_Unit Run Hours] * [BILLED QTY]
		WHEN [Description] LIKE 'Cargo Panel%' THEN [Finish_Unit Run Hours] * [BILLED QTY]
		ELSE SUM(SORT_RUN) 
	END AS [RUN HOURS]
	, [EXPEDITE HOURS]
	, [PACK SLIPS / DATE]  
	, INVOICE_ID AS [INVOICE ID]
	, COMMENTS
	, '' AS SORTATION
	, CUST_ORDER_ID
	, COL_LINE_NO AS COL_LINE_NO

FROM 
	(SELECT 'FIN' AS SPROC 
		--, 0 AS [COST ITEM]
		, CAST ('0' AS NVARCHAR(20)) AS [COST ITEM]
		, '1' AS [POS]
		, COL.PART_ID AS [PART NUMBER]
		, CO.ID AS [RAMAC]
		--, CONVERT(DECIMAL(14, 4), COL.TOTAL_SHIPPED_QTY) AS [BILLED QTY]
        -- unshipped feed
		, CONVERT(DECIMAL(14, 4), COL.ORDER_QTY) AS [BILLED QTY]
		, 0 AS [EXPEDITE DOLLARS]
		, 0 AS [EXPEDITE HOURS]
		, S.PACKLIST_ID + ',' + STUFF(REPLACE('/' + CONVERT(NVARCHAR(15), S.INVOICED_DATE, 101), '/0', '/'), 1, 1, '') 
			+ ',FIN,WRAP' AS [PACK SLIPS / DATE]  

		, CASE
			WHEN CB.[PART NUMBER] IS NULL THEN ''
			WHEN CB.[Description] LIKE 'Stanchion%' THEN 'FIXED HOURS'
			WHEN CB.[Description] LIKE 'Cargo Panel%' THEN 'FIXED HOURS'
			ELSE '' 
		END AS [COMMENTS]

		, 0 AS [SPECIAL FEES]

		, CASE
			WHEN CB.[Description] IS NOT NULL THEN 0.
			WHEN LT.[TYPE] = 'S' THEN CONVERT(DECIMAL(14, 4), LT.HOURS_WORKED)
			ELSE 0.
		END AS SORT_SETUP

		, CASE
			WHEN CB.[Description] LIKE 'Stanchion%' THEN [Finish_Unit Run Hours] * COL.TOTAL_SHIPPED_QTY
			WHEN CB.[Description] LIKE 'Cargo Panel%' THEN [Finish_Unit Run Hours] * COL.TOTAL_SHIPPED_QTY
--			WHEN CB.[Description] IS NOT NULL THEN 0.
			WHEN COL.PART_ID LIKE '437W8500%' AND CONVERT(DECIMAL(14, 4), SRI.USER_10) IS NOT NULL
				THEN CONVERT(DECIMAL(14, 4), SRI.USER_10)
			WHEN LT.[TYPE] = 'R' THEN CONVERT(DECIMAL(14, 4), LT.HOURS_WORKED)
			ELSE 0.
		END AS SORT_RUN

--> VERIFICATION FIELDS
		, LT.WORKORDER_BASE_ID
		, LT.HOURS_WORKED
		, COL.PART_ID
		, COL.CUST_ORDER_ID
		, COL.LINE_NO AS COL_LINE_NO
		, COL.TOTAL_SHIPPED_QTY
		, LT.[TYPE]
		, LT.TRANSACTION_ID
		, CO.CUSTOMER_ID
		, SRE.RESOURCE_ID AS EXC_RESOURCE_ID
		, SRE.USER_1 AS EXC_SKILLSTYPE
		, SRI.RESOURCE_ID AS INC_RESOURCE_ID
		, SRI.USER_1 AS INC_SKILLSTYPE
		, CONVERT(DECIMAL(14, 4), SRI.USER_10) AS INC_CHARGE
		, SL.SHIPPED_QTY
		, S.INVOICE_ID
		, S.INVOICED_DATE
		, S.PACKLIST_ID
		, WO.ACT_SERVICE_COST
		, CB.[Description]
		, CB.[Batch Qty]
		, CONVERT(DECIMAL(14, 4), [Finish_Unit Run Hours]) AS [Finish_Unit Run Hours]
    -- unshipped feed
    -- -- ~22
	-- FROM dbo.SHIPPER S
	-- INNER JOIN dbo.SHIPPER_LINE SL
	-- 	ON S.PACKLIST_ID = SL.PACKLIST_ID
    -- -- ~22
	-- INNER JOIN dbo.CUST_ORDER_LINE COL
	-- 	ON SL.CUST_ORDER_ID = COL.CUST_ORDER_ID
	-- 	AND SL.CUST_ORDER_LINE_NO = COL.LINE_NO
	-- INNER JOIN dbo.CUSTOMER_ORDER CO
	-- 	ON COL.CUST_ORDER_ID = CO.ID
    -- -- ~22
    -- unshipped
	from dbo.CUST_ORDER_LINE COL
	INNER JOIN dbo.CUSTOMER_ORDER CO
		ON COL.CUST_ORDER_ID = CO.ID
    -- ~22
	LEFT JOIN dbo.SHIPPER_LINE SL
		ON SL.CUST_ORDER_ID = COL.CUST_ORDER_ID
		AND SL.CUST_ORDER_LINE_NO = COL.LINE_NO
	LEFT JOIN dbo.SHIPPER S
    		ON S.PACKLIST_ID = SL.PACKLIST_ID
    -- ~22
	INNER JOIN dbo.DEMAND_SUPPLY_LINK DSL
		ON COL.CUST_ORDER_ID = DSL.DEMAND_BASE_ID
		AND COL.LINE_NO = DSL.DEMAND_SEQ_NO
    -- ~22 ////////////////////

	INNER JOIN dbo.WORK_ORDER WO
		ON DSL.SUPPLY_BASE_ID = WO.BASE_ID
		AND DSL.SUPPLY_LOT_ID = WO.LOT_ID
		AND DSL.SUPPLY_SPLIT_ID = WO.SPLIT_ID
	INNER JOIN dbo.LABOR_TICKET LT
		ON WO.BASE_ID = LT.WORKORDER_BASE_ID
		AND WO.LOT_ID = LT.WORKORDER_LOT_ID
		AND WO.SPLIT_ID = LT.WORKORDER_SPLIT_ID
		AND WO.SUB_ID = LT.WORKORDER_SUB_ID
		AND WO.[TYPE] = LT.WORKORDER_TYPE
	INNER JOIN dbo.SHOP_RESOURCE_SITE SRE
		ON LT.RESOURCE_ID = SRE.RESOURCE_ID
		--AND ISNULL(SRE.USER_9, '') != 'BOE BILLING EXCLUDE'
	LEFT OUTER JOIN dbo.SHOP_RESOURCE_SITE SRI
		ON LT.RESOURCE_ID = SRI.RESOURCE_ID
		--AND ISNULL(SRI.USER_9, '') = 'BOE BILLING INCLUDE'
	--LEFT OUTER JOIN CTE_INCLUDE CTE
	--	ON CTE.RESOURCE_ID = SR.RESOURCE_ID
	--	AND COL.PART_ID LIKE '437W8500%'
	LEFT OUTER JOIN [SQL-BI-1].LIVESupplemental.dbo.[BOE_Stanchion_Cargo_Bay] CB
		ON CB.[PART NUMBER] = COL.PART_ID
	WHERE 1 = 1
       -- unshipped
        AND ISNULL(SL.SHIPPED_QTY, 0) = 0
		AND SRE.USER_1 != N'M'
		AND CO.CUSTOMER_ID = N'BOE609'
        AND (CO.ID = @cust_order_id or @cust_order_id IS NULL)
		AND CASE
			WHEN COL.PART_ID = '411N2001-1' THEN 'OK'
			WHEN LT.WORKORDER_BASE_ID LIKE '%R%' THEN 'NOT OK'
			WHEN WO.PART_ID LIKE '%REWORK%' THEN 'NOT OK'
			ELSE 'OK'
		END = 'OK'
		-- -- AND (S.INVOICED_DATE >= @STARTDATE AND S.INVOICED_DATE <= @ENDDATE)
        -- unshipped feed
        AND COALESCE(COL.DESIRED_SHIP_DATE, CO.DESIRED_SHIP_DATE) >= @StartDate
        AND COALESCE(COL.DESIRED_SHIP_DATE, CO.DESIRED_SHIP_DATE) <= @EndDate

--		AND CO.ID = '001761716'

	) A
GROUP BY SPROC 
	, [COST ITEM]
	, [POS]
	, [PART NUMBER]
	, [Description] 
	, [RAMAC]
	, [BILLED QTY]
   -- , [ORDERED QTY]
	, [EXPEDITE HOURS]
	, [EXPEDITE DOLLARS]
	, [SPECIAL FEES]
	, [PACK SLIPS / DATE]  
	, INVOICE_ID
	, COMMENTS
	, [Finish_Unit Run Hours]
	, [Batch Qty] 
	, CUST_ORDER_ID
	, COL_LINE_NO

--GO