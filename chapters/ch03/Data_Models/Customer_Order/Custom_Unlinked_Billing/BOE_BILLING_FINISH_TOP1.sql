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


-- =============================================

DECLARE @STARTDATE DATE = '2025-08-18';
DECLARE @ENDDATE DATE = '2026-08-24';

--CREATE PROCEDURE [dbo].[usp_BOE_BILLING_FINISH] (@STARTDATE DATE, @ENDDATE DATE) 
--AS

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET DEADLOCK_PRIORITY LOW

DECLARE @CHARGE DECIMAL(14, 4) = (SELECT CHARGE FROM [SQL-BI-1].LIVESupplemental.dbo.[BOE_Billing_Charges] WHERE [REPORT] = 'usp_BOE_BILLING_FINISH')
;

DECLARE @RAMAC NVARCHar(50) = '001989493';


with raw as(

SELECT 'FIN' AS SPROC 

		, CO.ID AS [RAMAC]
        , COL.LINE_NO
        , LT.TRANSACTION_ID
        , SRE.RESOURCE_ID AS RESOURCE_ID
        , S.INVOICE_ID
		, S.INVOICED_DATE
        , COL.PART_ID
        , S.PACKLIST_ID + ',' + STUFF(REPLACE('/' + CONVERT(NVARCHAR(15), S.INVOICED_DATE, 101), '/0', '/'), 1, 1, '') 
			+ ',FIN,WRAP' AS [PACK SLIPS / DATE]  
        , ROW_NUMBER() over (order by (select null)) row_uid


		-- , 0 AS [COST ITEM]
		-- , '1' AS [POS]
		-- , COL.PART_ID AS [PART NUMBER]

		, CONVERT(DECIMAL(14, 4), COL.TOTAL_SHIPPED_QTY) AS [BILLED QTY]
		, 0 AS [EXPEDITE DOLLARS]
		, 0 AS [EXPEDITE HOURS]



--> VERIFICATION FIELDS
		, LT.WORKORDER_BASE_ID
		, LT.HOURS_WORKED
	
		, COL.TOTAL_SHIPPED_QTY
		, LT.[TYPE]

		, CO.CUSTOMER_ID

		, SRE.RESOURCE_ID AS EXC_RESOURCE_ID
		, SRE.USER_1 AS EXC_SKILLSTYPE
		, SRI.RESOURCE_ID AS INC_RESOURCE_ID
		, SRI.USER_1 AS INC_SKILLSTYPE
		, CONVERT(DECIMAL(14, 4), SRI.USER_10) AS INC_CHARGE
		, SL.SHIPPED_QTY

		, S.PACKLIST_ID
		, WO.ACT_SERVICE_COST
		, CB.[Description]
		, CB.[Batch Qty]
		, CONVERT(DECIMAL(14, 4), [Finish_Unit Run Hours]) AS [Finish_Unit Run Hours]
	FROM dbo.SHIPPER S
	INNER JOIN dbo.SHIPPER_LINE SL
		ON S.PACKLIST_ID = SL.PACKLIST_ID
	INNER JOIN dbo.CUST_ORDER_LINE COL
		ON SL.CUST_ORDER_ID = COL.CUST_ORDER_ID
		AND SL.CUST_ORDER_LINE_NO = COL.LINE_NO
	INNER JOIN dbo.CUSTOMER_ORDER CO
		ON COL.CUST_ORDER_ID = CO.ID
	INNER JOIN dbo.DEMAND_SUPPLY_LINK DSL
		ON COL.CUST_ORDER_ID = DSL.DEMAND_BASE_ID
		AND COL.LINE_NO = DSL.DEMAND_SEQ_NO
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
	WHERE 1=1
    and (CO.ID = @RAMAC OR @RAMAC IS NULL)
    
    and SL.SHIPPED_QTY > 0
		AND SRE.USER_1 != N'M'
		AND CO.CUSTOMER_ID = N'BOE609'
		AND CASE
			WHEN COL.PART_ID = '411N2001-1' THEN 'OK'
			WHEN LT.WORKORDER_BASE_ID LIKE '%R%' THEN 'NOT OK'
			WHEN WO.PART_ID LIKE '%REWORK%' THEN 'NOT OK'
			ELSE 'OK'
		END = 'OK'
		AND (S.INVOICED_DATE >= @STARTDATE AND S.INVOICED_DATE <= @ENDDATE)
)
select *
from raw

order by SPROC, RAMAC, RESOURCE_ID, TRANSACTION_ID