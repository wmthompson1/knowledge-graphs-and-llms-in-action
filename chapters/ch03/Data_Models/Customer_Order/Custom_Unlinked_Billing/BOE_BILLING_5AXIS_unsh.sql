--USE [Datamart]
--GO

--/****** Object:  StoredProcedure [dbo].[usp_BOE_BILLING_5AXIS]    Script Date: 8/26/2025 9:03:26 AM ******/
--SET ANSI_NULLS ON
--GO

--SET QUOTED_IDENTIFIER ON
--GO




/******************************************************************************************
-- Author:		traci treffert
-- Create date: 9/17/2019
-- Description:	Boeing Billing for BOE609 5AXIS
--		converted from original code in Crystal Reports to be used as SSRS report
--		take the logic/process out of hardcoded CR report and put in SQL for ease of maintenance
--		logic to also be included in Gross Margin processing
-- 
--> tt20211012: We need the calculations updated for the 5-AXIS CMP report.
When an item falls under fixed hours, the formula for the extended dollars needs to reflect ((Setup Time + (Run Time x Qty))*80) - 
This uses the run time listed on the fixed hours table.
For example PN 112T8108-515 that ships with a quantity of 6 = ((1.45 + ( 6 x 2.95)) x 80)
On the report we would like the run hours to be updated as well (Run time * qty) using the example above = (6 x 2.95) = 17.70

RAMAC is not a Boeing-specific acronym for a customer order. Instead, it is a historic 
computing term created by IBM in 1956 standing for Random Access Method of Accounting 
and Control.

Exec usp_BOE_BILLING_5AXIS_unsh @startdate = '2024-07-01', @enddate = '2026-07-31'
******************************************************************************************/

-- DECLARE @STARTDATE DATE = '2026-06-01';
-- DECLARE @ENDDATE DATE = '2026-08-24';

alter PROCEDURE [dbo].[usp_BOE_BILLING_5AXIS_unsh] (@STARTDATE DATE, @ENDDATE DATE)
AS

-- Each process query is a separate stored procedure, but the final result is a single feed table.

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET DEADLOCK_PRIORITY LOW
IF OBJECT_ID('tempdb..#Results') IS NOT NULL DROP TABLE #Results

-- 105
DECLARE @CHARGE FLOAT = (SELECT CHARGE FROM [SQL-BI-1].LIVESupplemental.dbo.[BOE_Billing_Charges] WHERE [REPORT] = 'usp_BOE_BILLING_5AXIS') --> $80
--, @STARTDATE DATE = '10/1/2021' 
--, @ENDDATE DATE = '10/31/2021'
;
/** I have indicated local terminology in comments where applicable */
SELECT 
    -- '5AXIS' AS SPROC
-- unshipped1
  CONCAT('5AXIS', '_unsh') SPROC 
   -- unshipped1
  -- , 1 AS [UNSHIPPED_FLAG]

	--, 0 AS [COST ITEM]
	, CAST ('0' AS NVARCHAR(20)) AS [COST ITEM]
	, cast( N'1' as nvarchar(20))  AS [POS]
	-- local to this customer, ties to part number, not the customer order:
	, COL.PART_ID AS [PART NUMBER]
	-- local to this customer, ties to the customer order, not the part number
	, CO.ID AS [RAMAC]
	, COL.TOTAL_SHIPPED_QTY AS [BILLED QTY]
	--, (AX.[Setup Time] + (AX.[Run Time] * COL.TOTAL_SHIPPED_QTY)) * @CHARGE / COL.TOTAL_SHIPPED_QTY AS [UNIT PRICE]
	, (AX.[Setup Time] + (AX.[Run Time] * COL.TOTAL_SHIPPED_QTY)) * @CHARGE / COL.ORDER_QTY AS [UNIT PRICE]

	, (AX.[Setup Time] + (AX.[Run Time] * COL.TOTAL_SHIPPED_QTY)) * @CHARGE AS [EXTENDED DOLLARS]

--> tt20211012:
	--, (AX.[Setup Time] + AX.[Run Time]) * @CHARGE / COL.TOTAL_SHIPPED_QTY AS [UNIT PRICE]
	--, (AX.[Setup Time] + AX.[Run Time]) * @CHARGE AS [EXTENDED DOLLARS]
	, 0 AS [EXPEDITE DOLLARS]
	, 0 AS [SPECIAL FEES]
	, 0 AS SERVICE_FEE
	, AX.[Setup Time] AS [SETUP HOURS]
--> tt20211012: request per Luke
	--, AX.[Run Time] AS [RUN HOURS]
	, AX.[Run Time] * COL.TOTAL_SHIPPED_QTY AS [RUN HOURS]
	, 0 AS [EXPEDITE HOURS]
	, S.PACKLIST_ID + ',' + STUFF(REPLACE('/' + CONVERT(NVARCHAR(15), INVOICED_DATE, 101), '/0', '/'), 1, 1, '') 
		+ ',AXIS,WRAP' AS [PACK SLIPS / DATE]
	, S.INVOICE_ID AS [INVOICE ID]
	, 'FIXED HOURS' AS COMMENTS
	, '' AS SORTATION
	, col.CUST_ORDER_ID
	, col.LINE_NO AS COL_LINE_NO
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
	INNER JOIN dbo.SHOP_RESOURCE_SITE SR
		ON LT.RESOURCE_ID = SR.RESOURCE_ID
		AND ISNULL(SR.USER_9, '') != 'BOE BILLING EXCLUDE'
	LEFT OUTER JOIN [SQL-BI-1].LIVESupplemental.dbo.[BOE_Billing_5AXIS] AX
--	INNER JOIN LIVESupplemental.dbo.[BOE_Billing_5AXIS] AX
		ON AX.[Part ID] = COL.PART_ID
	WHERE SL.SHIPPED_QTY > 0
		AND SR.USER_1 IN (N'D', N'E', N'M')
		AND CO.CUSTOMER_ID = N'BOE609'
		AND EXISTS (SELECT 1 FROM [SQL-BI-1].LIVESupplemental.dbo.ReportSettings_PartID EX
			WHERE COL.PART_ID = EX.PART_ID
				AND REPORT_NAME = 'usp_BOE_BILLING_5AXIS'
				AND REPORT_SECTION = 'MAIN INCLUSION'
		)
		AND CASE
			WHEN COL.PART_ID IN ('411N2001-1', '411A2001-1B') THEN 'OK'
			WHEN LT.WORKORDER_BASE_ID LIKE '%R%' THEN 'NOT OK'
			WHEN WO.PART_ID LIKE '%REWORK%' THEN 'NOT OK'
			ELSE 'OK'
		END = 'OK'
		--AND (S.INVOICED_DATE >= @STARTDATE AND S.INVOICED_DATE <= @ENDDATE)
		-- unshipped use CREATE_DATE -> CONVERT(DATE, CO.CREATE_DATE) 
		and (CONVERT(DATE, CO.CREATE_DATE) ) >= @STARTDATE
		and (CONVERT(DATE, CO.CREATE_DATE)) <= @ENDDATE

GROUP BY COL.PART_ID
	, CO.ID
	, COL.TOTAL_SHIPPED_QTY
	, COL.ORDER_QTY
	, S.PACKLIST_ID
	, S.INVOICED_DATE
	, S.INVOICE_ID
	, AX.[Setup Time] 
	, AX.[SFC Count]
	, AX.[Run Time]
	, col.CUST_ORDER_ID
	, col.LINE_NO 
--GO
--