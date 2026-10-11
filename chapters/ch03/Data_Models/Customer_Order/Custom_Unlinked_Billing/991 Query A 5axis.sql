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

Exec usp_BOE_BILLING_5AXIS @startdate = '2026-07-01', @enddate = '2026-07-31'
	, cast( N'1' as nvarchar(20))  AS [POS]
******************************************************************************************/

-- DECLARE @STARTDATE DATE = '2026-06-01';
-- DECLARE @ENDDATE DATE = '2026-08-24';

--alter PROCEDURE [dbo].[usp_BOE_BILLING_5AXIS] (@STARTDATE DATE, @ENDDATE DATE) AS

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET DEADLOCK_PRIORITY LOW
IF OBJECT_ID('tempdb..#Results') IS NOT NULL DROP TABLE #Results;

IF OBJECT_ID('Staging.dbo.QueryA_Shape') IS NOT NULL DROP TABLE Staging.dbo.QueryA_Shape;

-- 105
DECLARE @CHARGE FLOAT = (SELECT CHARGE FROM [SQL-BI-1].LIVESupplemental.dbo.[BOE_Billing_Charges] WHERE [REPORT] = 'usp_BOE_BILLING_5AXIS') --> $80
, @STARTDATE DATE = '6/1/2026' 
, @ENDDATE DATE = '8/31/2026'
;
/** I have indicated local terminology in comments where applicable */
SELECT 
     '5AXIS' AS SPROC 
	, 0 AS [COST ITEM]
    -- cast( N'<nnn>' as nvarchar(20) 
	, cast( N'1' as nvarchar(20))  AS [POS]
	-- local to this customer, ties to part number, not the customer order:
	, COL.PART_ID AS [PART NUMBER]
	-- local to this customer, ties to the customer order, not the part number
	, CO.ID AS [RAMAC]
	, COL.TOTAL_SHIPPED_QTY AS [BILLED QTY]
	, (AX.[Setup Time] + (AX.[Run Time] * COL.TOTAL_SHIPPED_QTY)) * @CHARGE / COL.TOTAL_SHIPPED_QTY AS [UNIT PRICE]
	, (AX.[Setup Time] + (AX.[Run Time] * COL.TOTAL_SHIPPED_QTY)) * @CHARGE AS [EXTENDED DOLLARS]
--> tt20211012:
	--, (AX.[Setup Time] + AX.[Run Time]) * @CHARGE / COL.TOTAL_SHIPPED_QTY AS [UNIT PRICE]
	--, (AX.[Setup Time] + AX.[Run Time]) * @CHARGE AS [EXTENDED DOLLARS]
	, CAST(0. AS FLOAT) AS [EXPEDITE DOLLARS]
	, 0 AS [SPECIAL FEE]
	, 0 AS SERVICE_FEE
	, AX.[Setup Time] AS [SETUP HOURS]
--> tt20211012: request per Luke
	--, AX.[Run Time] AS [RUN HOURS]
	, AX.[Run Time] * COL.TOTAL_SHIPPED_QTY AS [RUN HOURS]
	, 0 AS [EXPEDITE HOURS]
	, S.PACKLIST_ID + ',' + STUFF(REPLACE('/' + CONVERT(NVARCHAR(15), INVOICED_DATE, 101), '/0', '/'), 1, 1, '') 
		+ ',AXIS,WRAP' AS [PACK SLIPS / DATE]
	, S.INVOICE_ID AS [INVOICE ID]
	---, 'FIXED HOURS' AS COMMENTS
    , CAST('FIXED HOURS' AS varchar(20)) AS COMMENTS
	, CAST('' AS varchar(1)) AS SORTATION
    into #Results
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
		AND (S.INVOICED_DATE >= @STARTDATE AND S.INVOICED_DATE <= @ENDDATE)
GROUP BY COL.PART_ID
	, CO.ID
	, COL.TOTAL_SHIPPED_QTY
	, S.PACKLIST_ID
	, S.INVOICED_DATE
	, S.INVOICE_ID
	, AX.[Setup Time] 
	, AX.[SFC Count]
	, AX.[Run Time]
--GO
;

select * into Staging.dbo.QueryA_Shape
from #results
ORDER BY [RAMAC];
-- ~22 williamt 8/18/2026 in test
	-- , [COID]
	-- , [COLINE]

-- get shape of result in order to compare and conform for union with other billing reports
-- please be sure to use Staging.information_schema.tables and columns to get the shape of the result 
-- set for comparison with other billing reports
SELECT
t.TABLE_TYPE 
,'sqlserver' dbms,t.TABLE_CATALOG,t.TABLE_SCHEMA
,t.TABLE_NAME,c.COLUMN_NAME,c.ORDINAL_POSITION,c.DATA_TYPE
,c.CHARACTER_MAXIMUM_LENGTH
FROM Staging.INFORMATION_SCHEMA.TABLES t 
LEFT JOIN Staging.INFORMATION_SCHEMA.COLUMNS c ON t.TABLE_CATALOG=c.TABLE_CATALOG AND t.TABLE_SCHEMA=c.TABLE_SCHEMA AND t.TABLE_NAME=c.TABLE_NAME 
LEFT JOIN(Staging.INFORMATION_SCHEMA.KEY_COLUMN_USAGE k JOIN Staging.INFORMATION_SCHEMA.TABLE_CONSTRAINTS n ON k.CONSTRAINT_CATALOG=n.CONSTRAINT_CATALOG 
AND k.CONSTRAINT_SCHEMA=n.CONSTRAINT_SCHEMA AND k.CONSTRAINT_NAME=n.CONSTRAINT_NAME LEFT JOIN Staging.INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS r 
ON k.CONSTRAINT_CATALOG=r.CONSTRAINT_CATALOG AND k.CONSTRAINT_SCHEMA=r.CONSTRAINT_SCHEMA AND k.CONSTRAINT_NAME=r.CONSTRAINT_NAME)ON c.TABLE_CATALOG=k.TABLE_CATALOG 
AND c.TABLE_SCHEMA=k.TABLE_SCHEMA AND c.TABLE_NAME=k.TABLE_NAME AND c.COLUMN_NAME=k.COLUMN_NAME LEFT JOIN Staging.INFORMATION_SCHEMA.KEY_COLUMN_USAGE k2 ON k.ORDINAL_POSITION=k2.ORDINAL_POSITION AND r.UNIQUE_CONSTRAINT_CATALOG=k2.CONSTRAINT_CATALOG AND r.UNIQUE_CONSTRAINT_SCHEMA=k2.CONSTRAINT_SCHEMA AND r.UNIQUE_CONSTRAINT_NAME=k2.CONSTRAINT_NAME 
WHERE (1=1) 
and t.TABLE_NAME like 'QueryA_Shape'
order by 
 t.TABLE_CATALOG, t.TABLE_NAME, c.ORDINAL_POSITION
 ;