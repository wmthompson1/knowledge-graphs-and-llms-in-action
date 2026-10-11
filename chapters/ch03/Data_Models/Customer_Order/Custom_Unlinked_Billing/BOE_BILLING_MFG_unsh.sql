----USE [Datamart]
--Use Live -- lab-2 break-fix William 8/15
--GO

---- =DateAdd(DateInterval.Day, 2-WeekDay(Today), DateAdd(DateInterval.Day, -7, Today()))


---- =DateAdd(DateInterval.Day, 1-WeekDay(Today), Today())

--/****** Object:  StoredProcedure [dbo].[usp_BOE_BILLING_MFG]    Script Date: 8/25/2025 1:43:28 PM ******/
--SET ANSI_NULLS ON
--GO

--SET QUOTED_IDENTIFIER ON
--GO


-- =============================================
-- Author:		traci treffert
-- Create date: 9/17/2019
-- Description:	Boeing Billing for BOE609 MFG
--		converted from original code in Crystal Reports to be used as SSRS report
--		take the logic/process out of hardcoded CR report and put in SQL for ease of maintenance
--		logic to also be included in Gross Margin processing
/*	Update Feb-14-2025 by JC line 160 link DB patch when fail synchronization with DataWarehouse	*/
-- update William 8/25
-- Exec usp_BOE_BILLING_MFG_unsh @startdate = '2026-01-01', @enddate = '2026-08-31'
-- =============================================

--DECLARE @STARTDATE DATE = '2025-08-17';
--DECLARE @ENDDATE DATE = '2025-08-25';

ALTER PROCEDURE [dbo].[usp_BOE_BILLING_MFG_unsh] (@STARTDATE DATE, @ENDDATE DATE) AS


SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SET DEADLOCK_PRIORITY LOW;


DECLARE @CHARGE FLOAT = (SELECT CHARGE FROM [sql-bi-1].LIVESupplemental.dbo.[BOE_Billing_Charges] WHERE [REPORT] = 'usp_BOE_BILLING_MFG')
, @SPECIAL FLOAT = (SELECT SPECIAL FROM [sql-bi-1].LIVESupplemental.dbo.[BOE_Billing_Charges] WHERE [REPORT] = 'usp_BOE_BILLING_MFG')
, @SERVICE FLOAT = (SELECT [SERVICE] FROM [sql-bi-1].LIVESupplemental.dbo.[BOE_Billing_Charges] WHERE [REPORT] = 'usp_BOE_BILLING_MFG')

-- , @STARTDATE DATE = DATEADD(YEAR,-1,DATEADD(DAY,1,(EOMONTH(DATEADD(MONTH,-1,GETDATE())))))
-- , @ENDDATE DATE = GETDATE()-1
;

SELECT 

     -- SPROC
	-- unshipped1
	CONCAT(SPROC, '_unsh') SPROC
	-- unshipped1
	--, 1 AS [UNSHIPPED_FLAG] 

	--, [COST ITEM]
	, CAST ([COST ITEM] AS NVARCHAR(20)) AS [COST ITEM]
	, [POS]
	, [PART NUMBER]
	, [RAMAC]
	, [BILLED QTY]
	, CASE
		WHEN [BILLED QTY] <= 0 THEN 0
		WHEN [Description] LIKE 'Stanchion%' THEN ([Mfg_Unit Setup Hours] + [Mfg_Unit Run Hours]) * [BILLED QTY] 
		WHEN [Description] LIKE 'Cargo Panel%' THEN ([Mfg_Unit Setup Hours] + [Mfg_Unit Run Hours]) * [BILLED QTY] 
		ELSE (SUM(SORT_SETUP) + SUM(SORT_RUN) + (SERVICE_FEE)) 
	END * @CHARGE / NULLIF([BILLED QTY], 0) AS [UNIT PRICE]
	, CASE
		WHEN [BILLED QTY] <= 0 THEN 0
		WHEN [Description] LIKE 'Stanchion%' THEN ([Mfg_Unit Setup Hours] + [Mfg_Unit Run Hours]) * [BILLED QTY] 
		WHEN [Description] LIKE 'Cargo Panel%' THEN ([Mfg_Unit Setup Hours] + [Mfg_Unit Run Hours]) * [BILLED QTY] 
		ELSE (SUM(SORT_SETUP) + SUM(SORT_RUN) + (SERVICE_FEE))
	END * @CHARGE AS [EXTENDED DOLLARS]
	, [EXPEDITE DOLLARS]
	, [SPECIAL FEES]
	, 0 AS [SERVICE_FEES]
	, CASE 
		WHEN [Description] LIKE 'Stanchion%' THEN [Mfg_Unit SETUP Hours] * [BILLED QTY]
		WHEN [Description] LIKE 'Cargo Panel%' THEN [Mfg_Unit SETUP Hours] * [BILLED QTY]
		ELSE SUM(SORT_SETUP) 
	END AS [SETUP HOURS]
	, CASE 
		WHEN [Description] LIKE 'Stanchion%' THEN [Mfg_Unit Run Hours] * [BILLED QTY]
		WHEN [Description] LIKE 'Cargo Panel%' THEN [Mfg_Unit Run Hours] * [BILLED QTY]
		ELSE SUM(SORT_RUN) + (SERVICE_FEE)
	END AS [RUN HOURS]
	, [EXPEDITE HOURS]
	, [PACK SLIPS / DATE]
	, [INVOICE ID]
	, [COMMENTS]
	, '' AS SORTATION
	, CUST_ORDER_ID
	, COL_LINE_NO AS COL_LINE_NO
FROM 
	( SELECT 'MFG' AS SPROC, '0' AS [COST ITEM], '1' AS [POS]
		, COL.PART_ID AS [PART NUMBER]
		, CO.ID AS [RAMAC]
		--, CONVERT(DECIMAL(14, 4), COL.TOTAL_SHIPPED_QTY) AS [BILLED QTY]
		-- unshipped feed 
		, CONVERT(DECIMAL(14, 4), COL.ORDER_QTY) AS [BILLED QTY] 
		, S.INVOICE_ID AS [INVOICE ID]
		, SL.PACKLIST_ID + ',' + STUFF(REPLACE('/' + CONVERT(NVARCHAR(15), INVOICED_DATE, 101), '/0', '/'), 1, 1, '') 
			+ ',MFG,WRAP' AS [PACK SLIPS / DATE]
		, 0 AS [EXPEDITE HOURS]
		, 0 AS [EXPEDITE DOLLARS]
		, ROUND((WO.ACT_SERVICE_COST/@SERVICE), 2) AS SERVICE_FEE
		, CASE
			WHEN WO.ACT_SERVICE_COST > 0 THEN @SPECIAL
			ELSE 0
		END + CASE
			WHEN TOTAL_SHIPPED_QTY < [Batch Qty] AND CB.[Description] LIKE 'Stanchion%' THEN 175
			ELSE 0
		END AS [SPECIAL FEES]
		, CASE
			WHEN CB.[DESCRIPTION] IS NULL THEN ''
			WHEN CB.[Description] LIKE 'Stanchion%' AND COL.TOTAL_SHIPPED_QTY < 3.00        -- Change
				THEN 'QTY ' + CAST(CAST(TOTAL_SHIPPED_QTY AS INT) AS NVARCHAR) + ',MIN LOT,'
			ELSE '' 
		END + CASE
			WHEN CB.[Description] LIKE 'Stanchion%' THEN 'FIXED HOURS'
			WHEN CB.[Description] LIKE 'Cargo Panel%' THEN 'FIXED HOURS'
			--WHEN CB.[DESCRIPTION] IS NULL THEN ''
			ELSE '' 
		END AS [COMMENTS]
		, CASE
			WHEN CB.[Description] LIKE 'Stanchion%' THEN [Mfg_Unit Setup Hours] * COL.TOTAL_SHIPPED_QTY
			WHEN CB.[Description] LIKE 'Cargo Panel%' THEN [Mfg_Unit Setup Hours] * COL.TOTAL_SHIPPED_QTY
			--WHEN CB.[DESCRIPTION] IS NOT NULL THEN 0
			WHEN LT.[TYPE] = 'S' THEN LT.HOURS_WORKED
			ELSE 0
		END AS SORT_SETUP
		, CASE
			WHEN CB.[Description] LIKE 'Stanchion%' THEN [Mfg_Unit Run Hours] * COL.TOTAL_SHIPPED_QTY
			WHEN CB.[Description] LIKE 'Cargo Panel%' THEN [MFG_Unit Run Hours] * COL.TOTAL_SHIPPED_QTY
			--WHEN CB.[DESCRIPTION] IS NOT NULL THEN 0
			WHEN LT.[TYPE] = 'R' THEN LT.HOURS_WORKED
			ELSE 0
		END AS SORT_RUN
		, CB.[DESCRIPTION]
		, CB.[Mfg_Unit Setup Hours]
		, CB.[Mfg_Unit Run Hours]
		, CB.[Batch Qty]
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
		, SR.USER_1
		, SL.SHIPPED_QTY
		, S.INVOICE_ID
		, S.INVOICED_DATE
		, S.PACKLIST_ID
		, SR.RESOURCE_ID
		, WO.ACT_SERVICE_COST
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
    -- ~22 ////////////////////

	INNER JOIN dbo.DEMAND_SUPPLY_LINK DSL ON COL.CUST_ORDER_ID = DSL.DEMAND_BASE_ID
		AND COL.LINE_NO = DSL.DEMAND_SEQ_NO
	INNER JOIN dbo.WORK_ORDER WO ON DSL.SUPPLY_BASE_ID = WO.BASE_ID
		AND DSL.SUPPLY_LOT_ID = WO.LOT_ID
		AND DSL.SUPPLY_SPLIT_ID = WO.SPLIT_ID
	-- select top 1000 CREATE_DATE, * from dbo.WORK_ORDER  order by rowid desc
	INNER JOIN dbo.LABOR_TICKET LT ON WO.BASE_ID = LT.WORKORDER_BASE_ID
		AND WO.LOT_ID = LT.WORKORDER_LOT_ID
		AND WO.SPLIT_ID = LT.WORKORDER_SPLIT_ID
		AND WO.SUB_ID = LT.WORKORDER_SUB_ID
		AND WO.[TYPE] = LT.WORKORDER_TYPE
	-- select top 1000 CREATE_DATE, * from dbo.LABOR_TICKET  order by rowid desc
	INNER JOIN dbo.OPERATION O ON WO.BASE_ID = O.WORKORDER_BASE_ID
		AND WO.LOT_ID = O.WORKORDER_LOT_ID
		AND WO.SPLIT_ID = O.WORKORDER_SPLIT_ID
		AND WO.SUB_ID = O.WORKORDER_SUB_ID
		AND WO.[TYPE] = O.WORKORDER_TYPE
		AND LT.OPERATION_SEQ_NO = O.SEQUENCE_NO
	/* When dbo.SHOP_RESOURCE_SITE synchronization is OK */
	--INNER JOIN dbo.SHOP_RESOURCE_SITE SR ON LT.RESOURCE_ID = SR.RESOURCE_ID
	--AND ISNULL(SR.USER_9, '') != 'BOE BILLING EXCLUDE'       -- Change

	/* When dbo.SHOP_RESOURCE_SITE lost synchronization use [SQL-Lab-2].[LIVE] */
	INNER JOIN [SQL-Lab-2].[LIVE].dbo.SHOP_RESOURCE_SITE SR ON LT.RESOURCE_ID = SR.RESOURCE_ID
		-- wnt 8/23
	LEFT OUTER JOIN [sql-bi-1].LIVESupplemental.dbo.[BOE_Stanchion_Cargo_Bay] CB ON CB.[PART NUMBER] = COL.PART_ID
	WHERE 1=1

		-- 	and COL.CUST_ORDER_ID in (
		-- '002064831',
		-- '002064829',
		-- '002061274',
		-- '002059559',
		-- '002057553')
	
	
		-- unshipped must not have a SHIPPER_LINE record
        AND ISNULL(SL.SHIPPED_QTY, 0) = 0
		AND  SL.CUST_ORDER_ID IS NULL
		AND SL.CUST_ORDER_LINE_NO IS NULL


		AND SR.USER_1 IN (N'D', N'E', N'M')
		AND CO.CUSTOMER_ID = N'BOE609'
		-- wnt 8/25
		AND NOT EXISTS (SELECT 1 FROM [sql-bi-1].LIVESupplemental.dbo.ReportSettings_PartID EX
			WHERE COL.PART_ID = EX.PART_ID
				AND REPORT_NAME = 'usp_BOE_BILLING_MFG'
				AND REPORT_SECTION = 'MAIN EXCLUSION'
		)
		AND CASE
				WHEN COL.PART_ID IN ('411N2001-1', '411A2001-1B') THEN 'OK'
				WHEN LT.WORKORDER_BASE_ID LIKE '%R%' THEN 'NOT OK'
				WHEN WO.PART_ID LIKE '%REWORK%' THEN 'NOT OK'
			ELSE 'OK'
			END = 'OK'
		  -- unshipped use CREATE_DATE -> CONVERT(DATE, CO.CREATE_DATE) 
		and (CONVERT(DATE, CO.CREATE_DATE) ) >= @STARTDATE
		and (CONVERT(DATE, CO.CREATE_DATE)) <= @ENDDATE
	) A

GROUP BY SPROC 
	, [COST ITEM]
	, [POS]
	, [PART NUMBER]
	, [RAMAC]
	, [BILLED QTY]
	, [INVOICE ID]
	, [PACK SLIPS / DATE]
	, [EXPEDITE HOURS]
	, [EXPEDITE DOLLARS]
	, [SPECIAL FEES]
	, [COMMENTS]
	, [Batch Qty]
	, SERVICE_FEE
	, [Description]
	, [Mfg_Unit SETUP Hours]
	, [Mfg_Unit Run Hours]
	, CUST_ORDER_ID
	, COL_LINE_NO
----GO
