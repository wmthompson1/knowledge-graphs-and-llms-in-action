--USE [DataWarehouse]
use staging  -- sql-lab-2
GO

/****** Object:  StoredProcedure [dbo].[usp_SupplierPerformance_LoadDetails]    Script Date: 9/14/2026 7:13:12 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




/**********************************************************************************************
Description: Stored procedure to load details table for Supplier Performance Rating
Note: because large tables were slow via linked server, tables shuttled. Process consolidated lab-2.
Date      Modified By      Change Description
---------- ------------------ ------------------------------------------------------------
04/10/2018  Eric Shafer      Initial creation of the stored procedure
09/14/2026  williamt        Updated procedure for staging environment and round trip to bi-1 via lab2
09/14/2026  williamt        new mapping for new NCM system
09/15/2026  williamt        sql agent job on lab-2 runs from sql agent job on sql-bi-1
09/15/2026  williamt        [Supplier Performance Monthly and Weekly Refresh] -- > [Supplier Performance Shuttle]


tables
-- 1) [sql-bi-1].Datamart.dbo.SK_SUPPLIER_PERFORMANCE_DETAILS  
-- 2) [sql-bi-1].Datamart.dbo.SK_SUPPLIER_PERFORMANCE_DETAILS_HISTORY
-- --------------------------------------------
-- 1) [sql-lab-2].Staging.dbo.SK_SUPPLIER_PERFORMANCE_DETAILS  
-- 2) [sql-lab-2].Staging.dbo.SK_SUPPLIER_PERFORMANCE_DETAILS_HISTORY
**********************************************************************************************/



-- staging
alter PROCEDURE [dbo].usp_SupplierPerformance_LoadDetails AS

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET DEADLOCK_PRIORITY LOW
IF OBJECT_ID('tempdb..#Results') IS NOT NULL DROP TABLE #Results

SET NOCOUNT OFF
DECLARE @TransactionStartDate DATETIME2(7) = SYSDATETIME()
	, @TransactionEndDate DATETIME2(7)
	, @StoredProcedureStartDate DATETIME2(7) = SYSDATETIME()
	, @DurationSeconds INT
	, @Rows INT = 0
	, @RowsPerSecond INT
	, @Error INT
	, @InsertedRows INT = 0
	, @UpdatedRows INT = 0
	, @DeletedRows INT = 0
	, @StoredProcedureName SYSNAME = 
		(SELECT @@SERVERNAME + '.' + DB_NAME() + '.' + s.name + '.' + o.name 
		FROM sys.objects o (NOLOCK) 
		JOIN sys.schemas s (NOLOCK) 
			ON o.schema_id = s.schema_id 
		WHERE o.object_id = @@PROCID)
	, @TargetServer SYSNAME = @@SERVERNAME
	, @TargetDatabase SYSNAME = 'DataWarehouse'
	, @TargetSchema SYSNAME = 'dbo'
	, @TargetTable SYSNAME = 'VQ_OPERATION'
	, @StepId INT = 1
	, @Step VARCHAR(4000)


DECLARE @MergeResult TABLE (ActionTaken VARCHAR(20) NOT NULL);

DECLARE @STARTDATE DATE 
, @ENDDATE DATE = CAST(DATEADD(dd, -DAY(GETDATE()), GETDATE()) AS DATE)

SELECT @STARTDATE = CAST(DATEADD(YEAR, -1, @ENDDATE) AS DATE)
--SELECT @STARTDATE, @ENDDATE
TRUNCATE TABLE staging.dbo.SK_SUPPLIER_PERFORMANCE_DETAILS;

--GET IQM NCM data
--contractor operation;  Has work order information to sequence
;WITH CTE_IQM AS (	
	SELECT NCM_ID, NCM.PRODUCT_REC_ID, DSL.SUPPLY_BASE_ID AS 'SupplierPO'
		, convert(nvarchar(12), DSL.SUPPLY_SEQ_NO) AS 'SupplierPO_LINE'
		, NCM.LOT_SIZE, NCM.ACCEPTED, NCM.REJECTED, NCM.NCM_DATE
	FROM [sql-bi-1].datawarehouse.dbo.VQ_NONCONFORMANCE NCM
	INNER JOIN [sql-bi-1].datawarehouse.dbo.VQ_PRODUCT P ON P.RECORD_ID = NCM.PRODUCT_REC_ID
	-- large tables shuttled to lab-2 
	INNER JOIN VQ_PRODUCTION_ORDER PO ON PO.RECORD_ID = NCM.PROD_ORDER_REC_ID
		AND PO.ALT_ID_1 = 'W'
	-- large tables shuttled to lab-2 
	INNER JOIN VQ_OPERATION O ON O.RECORD_ID = NCM.OPERATION_REC_ID
	INNER JOIN live.dbo.OPERATION OP ON  PO.ALT_ID_2 = OP.WORKORDER_BASE_ID
		AND PO.ALT_ID_3 = OP.WORKORDER_LOT_ID AND PO.ALT_ID_4 = OP.WORKORDER_SPLIT_ID
		AND PO.ALT_ID_5 = OP.WORKORDER_SUB_ID AND O.DISPLAY_ID = OP.SEQUENCE_NO
		AND op.WORKORDER_TYPE = 'W'
	LEFT OUTER JOIN [SQL-IQM-9].[IQM_Baseline_App].DBO.VQ_SUPPLIER s
		ON s.RECORD_ID = NCM.REPORTED_BY_SUPP_REC_ID 
	INNER JOIN live.dbo.DEMAND_SUPPLY_LINK AS DSL
		ON OP.WORKORDER_BASE_ID = DSL.DEMAND_BASE_ID
			AND OP.WORKORDER_LOT_ID = DSL.DEMAND_LOT_ID AND OP.WORKORDER_SPLIT_ID = DSL.DEMAND_SPLIT_ID
			AND OP.WORKORDER_SUB_ID = DSL.DEMAND_SUB_ID AND OP.SEQUENCE_NO = DSL.DEMAND_SEQ_NO
			AND OP.WORKORDER_TYPE ='W'
	INNER JOIN live.DBO.WORK_ORDER AS WO ON DSL.DEMAND_BASE_ID = WO.BASE_ID
		AND DSL.DEMAND_LOT_ID = WO.LOT_ID AND DSL.DEMAND_SPLIT_ID = WO.SPLIT_ID
		AND DSL.DEMAND_SUB_ID = WO.SUB_ID AND DSL.SUPPLY_PART_ID = WO.PART_ID AND WO.[TYPE] ='W'
	
	WHERE NCM.NCM_TYPE = 'SUPPLIER - MAJOR' AND O.CONST_RESOURCE_ID = 'CONTRACTOR'
		AND PO.ALT_ID_2 is not null 

    UNION ALL
    -- linked V2
    -- ~22
	    SELECT 
        -- 'linked ncm' AS note,
		-- NCM.NCM_TYPE_CODE,
        CAST(NCM.NCM_NUMBER AS nvarchar(50)) AS NCM_ID
		-- MAP QUALITY DB 1 PRODUCT_REC_ID TO Quality DB 1?
        , CAST(NCM.PART_ID AS nvarchar(50)) AS PRODUCT_REC_ID  -- Part / Item / PO ID
	        , CASE 
            WHEN CHARINDEX('/', NCM.VENDOR_PO_NUMBER, 1) = 0 THEN NCM.VENDOR_PO_NUMBER
            ELSE SUBSTRING(NCM.VENDOR_PO_NUMBER, 1, CHARINDEX('/', NCM.VENDOR_PO_NUMBER, 1) - 1) 
        END AS 'SupplierPO'
        , SUBSTRING(NCM.VENDOR_PO_NUMBER, LEN(NCM.VENDOR_PO_NUMBER), CHARINDEX('/', NCM.VENDOR_PO_NUMBER, 1) + 1) AS 'SupplierPO_LINE'
        , NCM.LOT_SIZE
        , NCM.ACCEPTED
        , NCM.REJECTED
        , NCM.NCM_DATE

    FROM [sql-lab-2].[NCM].[dbo].[NONCONFORMANCE] NCM WITH (NOLOCK)
	--LEFT OUTER JOIN [sql-lab-2].[Live].[dbo].[OPERATION] OP WITH (NOLOCK)
    LEFT OUTER JOIN live.dbo.[OPERATION] OP WITH (NOLOCK)
		ON NCM.BASE_ID = OP.WORKORDER_BASE_ID
		AND NCM.LOT_ID = OP.WORKORDER_LOT_ID
		AND NCM.SPLIT_ID = OP.WORKORDER_SPLIT_ID
		AND NCM.SUB_ID = OP.WORKORDER_SUB_ID
		AND OP.SEQUENCE_NO = TRY_CONVERT(SMALLINT, NCM.OPERATION_ID)
		AND OP.WORKORDER_TYPE = 'W'
	INNER JOIN live.dbo.DEMAND_SUPPLY_LINK AS DSL
		ON OP.WORKORDER_BASE_ID = DSL.DEMAND_BASE_ID
			AND OP.WORKORDER_LOT_ID = DSL.DEMAND_LOT_ID AND OP.WORKORDER_SPLIT_ID = DSL.DEMAND_SPLIT_ID
			AND OP.WORKORDER_SUB_ID = DSL.DEMAND_SUB_ID AND OP.SEQUENCE_NO = DSL.DEMAND_SEQ_NO
			AND OP.WORKORDER_TYPE ='W'
    LEFT OUTER JOIN [sql-lab-2].[NCM].[dbo].[DISPOSITION_TYPE] DT WITH (NOLOCK)
        ON DT.[DISPOSITION_TYPE_CODE] = NCM.[DISPOSITION_TYPE_CODE]
    LEFT OUTER JOIN [sql-lab-2].[NCM].[dbo].[EMPLOYEE_LOOKUP] MADE_EE WITH (NOLOCK)
        ON MADE_EE.[EMPLOYEE_ID] = NCM.[MADE_BY_EMPLOYEE_ID]
    LEFT OUTER JOIN [sql-lab-2].[NCM].[dbo].[EMPLOYEE_LOOKUP] ASSGN_EE WITH (NOLOCK)
        ON ASSGN_EE.[EMPLOYEE_ID] = NCM.[ASSIGNED_TO_EMPLOYEE_ID]
    LEFT OUTER JOIN [sql-lab-2].[NCM].[dbo].[EMPLOYEE_LOOKUP] DISP_EE WITH (NOLOCK)
        ON DISP_EE.[EMPLOYEE_ID] = NCM.[DISPOSITION_BY_EMPLOYEE_ID]
    LEFT OUTER JOIN [sql-lab-2].[NCM].[dbo].[EMPLOYEE_LOOKUP] DISP_ASSG WITH (NOLOCK)
        ON DISP_ASSG.[EMPLOYEE_ID] = NCM.[DISPOSITION_ASSIGNED_TO_EMPLOYEE_ID]
    LEFT OUTER JOIN [sql-lab-2].[NCM].[dbo].[EMPLOYEE_LOOKUP] VERIFY_BY_EE WITH (NOLOCK)
        ON VERIFY_BY_EE.[EMPLOYEE_ID] = NCM.[VERIFIED_BY_EMPLOYEE_ID]
    WHERE NCM.BASE_ID IS NOT NULL
        AND (NCM.NCM_TYPE_CODE IN ( 'JOB SUPPLIER')) AND OP.RESOURCE_ID = 'CONTRACTOR'
    -- ~22


	UNION ALL
	--not a contractor operation; not associated with a work order (base id/PO.ALT_ID_2 IS NULL)
	SELECT NCM_ID , NCM.PRODUCT_REC_ID
		, CASE 
			WHEN CHARINDEX('/',NCM.PO_NUMBER,1) = 0 THEN NCM.PO_NUMBER
			ELSE SUBSTRING(NCM.PO_NUMBER, 1, CHARINDEX('/',NCM.PO_NUMBER,1)-1) 
		END AS 'SupplierPO'
		, SUBSTRING(NCM.PO_NUMBER, LEN(NCM.PO_NUMBER), CHARINDEX('/',NCM.PO_NUMBER,1)+1) AS 'SupplierPO_LINE'
		, NCM.LOT_SIZE, NCM.ACCEPTED, NCM.REJECTED, NCM.NCM_DATE
	FROM [sql-bi-1].datawarehouse.dbo.VQ_NONCONFORMANCE NCM
	LEFT OUTER JOIN [sql-bi-1].datawarehouse.dbo.VQ_PRODUCT P ON P.RECORD_ID = NCM.PRODUCT_REC_ID
	LEFT OUTER JOIN dbo.VQ_PRODUCTION_ORDER PO ON PO.RECORD_ID = NCM.PROD_ORDER_REC_ID
		AND PO.ALT_ID_1 = 'W'
	LEFT OUTER JOIN dbo.VQ_OPERATION O ON O.RECORD_ID = NCM.OPERATION_REC_ID
	LEFT OUTER JOIN [SQL-IQM-9].[IQM_Baseline_App].DBO.VQ_SUPPLIER s
		ON S.RECORD_ID = NCM.REPORTED_BY_SUPP_REC_ID 
	WHERE NCM.NCM_TYPE = 'SUPPLIER - MAJOR' AND PO.ALT_ID_2 IS NULL

    UNION ALL   
    -- unlinked V2
    -- ~22
 -- Quality Database #2: SQL-Lab-2 / NCM
    SELECT 
       -- --  'unlinked ncm' AS note
          CAST(x.NCM_NUMBER AS nvarchar(50)) AS NCM_ID
        , CAST(x.PART_ID AS nvarchar(50)) AS PRODUCT_REC_ID  -- Part / Item / PO ID

        , CASE 
            WHEN CHARINDEX('/', x.VENDOR_PO_NUMBER, 1) = 0 THEN x.VENDOR_PO_NUMBER
            ELSE SUBSTRING(x.VENDOR_PO_NUMBER, 1, CHARINDEX('/', x.VENDOR_PO_NUMBER, 1) - 1) 
        END AS 'SupplierPO'
        , SUBSTRING(x.VENDOR_PO_NUMBER, LEN(x.VENDOR_PO_NUMBER), CHARINDEX('/', x.VENDOR_PO_NUMBER, 1) + 1)
                AS 'SupplierPO_LINE'
        , x.LOT_SIZE
        , x.ACCEPTED
        , x.REJECTED
        , x.NCM_DATE
 
    FROM [sql-lab-2].[NCM].[dbo].[NONCONFORMANCE] x WITH (NOLOCK)
    LEFT OUTER JOIN [sql-lab-2].[NCM].[dbo].[DISPOSITION_TYPE] DT WITH (NOLOCK)
        ON DT.[DISPOSITION_TYPE_CODE] = x.[DISPOSITION_TYPE_CODE]
    LEFT OUTER JOIN [sql-lab-2].[NCM].[dbo].[EMPLOYEE_LOOKUP] MADE_EE WITH (NOLOCK)
        ON MADE_EE.[EMPLOYEE_ID] = x.[MADE_BY_EMPLOYEE_ID]
    LEFT OUTER JOIN [sql-lab-2].[NCM].[dbo].[EMPLOYEE_LOOKUP] ASSGN_EE WITH (NOLOCK)
        ON ASSGN_EE.[EMPLOYEE_ID] = x.[ASSIGNED_TO_EMPLOYEE_ID]
    LEFT OUTER JOIN [sql-lab-2].[NCM].[dbo].[EMPLOYEE_LOOKUP] DISP_EE WITH (NOLOCK)
        ON DISP_EE.[EMPLOYEE_ID] = x.[DISPOSITION_BY_EMPLOYEE_ID]
    LEFT OUTER JOIN [sql-lab-2].[NCM].[dbo].[EMPLOYEE_LOOKUP] DISP_ASSG WITH (NOLOCK)
        ON DISP_ASSG.[EMPLOYEE_ID] = x.[DISPOSITION_ASSIGNED_TO_EMPLOYEE_ID]
    LEFT OUTER JOIN [sql-lab-2].[NCM].[dbo].[EMPLOYEE_LOOKUP] VERIFY_BY_EE WITH (NOLOCK)
        ON VERIFY_BY_EE.[EMPLOYEE_ID] = x.[VERIFIED_BY_EMPLOYEE_ID]
    WHERE x.BASE_ID IS NULL
        AND (x.NCM_TYPE_CODE IN ('PURCHASING SUPPLIER'))
    -- ~22
)

, CTE_RECEIVED AS  (
	SELECT PO.VENDOR_ID, POL.PURC_ORDER_ID, convert(nvarchar(12), POL.LINE_NO) AS 'PURC_ORDER_LINE_NO'
		, POL.LINE_STATUS AS PO_LINE_STATUS, PO.[STATUS] AS 'PO_STATUS', POL.ORDER_QTY AS 'PO_LINE_ORDERQTY'
		, R.RECEIVED_Date AS 'RDATE', RL.RECEIVED_Qty AS 'TotReceivedQty'
		, CONVERT(DATE, POL.DESIRED_RECV_DATE + 5, 101) as 'DUE_DATE'
		, CONVERT(NVARCHAR,LEFT(CONVERT(VARCHAR, R.RECEIVED_Date, 112), 6)) AS 'YrMth'
	, CASE 
		WHEN R.RECEIVED_DATE <= POL.DESIRED_RECV_DATE + 5 THEN 1
		ELSE 0
	END AS 'OntimeQty'
	, CASE 
		WHEN R.RECEIVED_DATE <= POL.DESIRED_RECV_DATE + 5 THEN 0
		ELSE 1
	END AS 'LateQty'
	, 1 AS 'TotQty', POL.PART_ID
	FROM live.dbo.PURC_ORDER_LINE POL
	INNER JOIN live.dbo.PURCHASE_ORDER PO ON POL.PURC_ORDER_ID = PO.ID
	INNER JOIN live.dbo.RECEIVER_LINE RL ON POL.PURC_ORDER_ID = RL.PURC_ORDER_ID
		AND POL.LINE_NO = RL.PURC_ORDER_LINE_NO AND RL.RECEIVED_QTY > 0
	INNER JOIN live.dbo.RECEIVER R  ON RL.RECEIVER_ID = R.ID
	WHERE ISNULL(POL.VENDOR_PART_ID,'') != 'Tooling' AND POL.PART_ID IS NOT NULL
		AND R.RECEIVED_Date >= @STARTDATE AND R.RECEIVED_Date <= @ENDDATE
		AND DATEDIFF(DAY, ISNULL(POL.DESIRED_RECV_DATE, PO.DESIRED_RECV_DATE), PO.ORDER_DATE) * (-1) >= 0
		AND EXISTS(SELECT 1
			FROM live.dbo.VENDOR V
			WHERE V.ID = PO.VENDOR_ID 
			AND V.USER_2 IN ('APPROVED', 'PENDING')
		)
) 

--INSERT DATA INTO DETAIL TABLE 
--INSERT INTO Datamart.dbo.SK_SUPPLIER_PERFORMANCE_DETAILS
INSERT INTO dbo.SK_SUPPLIER_PERFORMANCE_DETAILS
([VENDOR_ID], [PURC_ORDER_ID], [PURC_ORDER_LINE_NO], [PO_LINE_STATUS], [PO_STATUS]
	, [PO_LINE_ORDERQTY], [rDate], [TotReceivedQty], [TotRejected], [DUE_DATE]
	, [YrMth], [OnTimeQty], [LateQty], [TotQty], [PART_ID]
)

SELECT VENDOR_ID, PURC_ORDER_ID, PURC_ORDER_LINE_NO, PO_LINE_STATUS, PO_STATUS
	, PO_LINE_ORDERQTY, RDate, TotReceivedQty, SUM(ISNULL(NCM.REJECTED,0)) AS 'TotRejected'
	, due_date, YrMth, OntimeQty, LateQty, TotQty, PART_ID
FROM cte_received R
LEFT OUTER JOIN CTE_IQM NCM ON R.PURC_ORDER_ID = NCM.SupplierPO
	AND R.PURC_ORDER_LINE_NO = NCM.SupplierPO_LINE
GROUP BY VENDOR_ID, PURC_ORDER_ID, PURC_ORDER_LINE_NO, PO_LINE_STATUS, PO_STATUS
	, PO_LINE_ORDERQTY, RDate, TotReceivedQty, due_date, YrMth, OntimeQty, LateQty
	, TotQty, PART_ID
ORDER BY VENDOR_ID, rdate



-- --INSERT DATA INTO [SK_SUPPLIER_PERFORMANCE_DETAILS_HISTORY] TABLE 
-- INSERT INTO [dbo].SK_SUPPLIER_PERFORMANCE_DETAILS_HISTORY
-- --SELECT * , GETDATE() AS 'HistoryDate'
-- select *, @StoredProcedureStartDate AS 'HistoryDate'
-- FROM dbo.SK_SUPPLIER_PERFORMANCE_DETAILS
-- ORDER BY VENDOR_ID;

-- GO

/**
SK_SUPPLIER_PERFORMANCE_DETAILS_HISTORY can be loaded here in sql-lab-2/staging or 
sql-bi-1/datamart. See Shuttle

select *, CAST(? AS DATE) AS 'HistoryDate'
FROM dbo.SK_SUPPLIER_PERFORMANCE_DETAILS
ORDER BY VENDOR_ID;

**/

