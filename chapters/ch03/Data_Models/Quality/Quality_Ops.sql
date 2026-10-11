
-- ud_workorder_id is a concatenation of the workorder identifiers to create a unique identifier for the workorder.
-- This is used to join to the VQ_OPERATION table in the data warehouse.

/**********************************************************************************************
Description:
Sample:
Date      Modified By      Change Description
---------- ------------------ ------------------------------------------------------------
**********************************************************************************************/
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET DEADLOCK_PRIORITY LOW
IF OBJECT_ID('tempdb..#Results') IS NOT NULL DROP TABLE #Results
IF OBJECT_ID('tempdb..#x') IS NOT NULL DROP TABLE #x
IF OBJECT_ID('tempdb..#PO') IS NOT NULL DROP TABLE #PO
IF OBJECT_ID('tempdb..#IO') IS NOT NULL DROP TABLE #IO
IF OBJECT_ID('tempdb..#NCM') IS NOT NULL DROP TABLE #NCM
IF OBJECT_ID('tempdb..#PRODUCT') IS NOT NULL DROP TABLE #PRODUCT    



declare @STARTDATE date = '2026-06-29';
declare @endDATE date = '2026-07-05';
declare @timeframe nvarchar(25) = 'LAST WEEK'; 
declare @LISTTYPE nvarchar(25) = 'DEFECTS';

-- Pre-calculate dates
DECLARE @CalcStartDate DATE, @CalcEndDate DATE;
SELECT @CalcStartDate = CASE
    WHEN @TIMEFRAME = 'LAST WEEK' THEN DATEADD(WEEK, DATEDIFF(WEEK, 7, GETDATE()), 0)
    WHEN @TIMEFRAME = 'OTHER' THEN @STARTDATE
    -- ... add other cases
END,
@CalcEndDate = CASE
    WHEN @TIMEFRAME = 'LAST WEEK' THEN DATEADD(WEEK, DATEDIFF(WEEK, 7, GETDATE()), 6)
    WHEN @TIMEFRAME = 'OTHER' THEN @ENDDATE
    -- ... add other cases
END;

-- Stage remote data locally FIRST
SELECT RECORD_ID, ALT_ID_1, ALT_ID_2, ALT_ID_3, ALT_ID_4, ALT_ID_5
INTO #PO
FROM [sql-bi-1].datawarehouse.dbo.VQ_PRODUCTION_ORDER
WHERE 1=1; -- Add date filters if possible

CREATE INDEX IX_PO ON #PO(ALT_ID_2, ALT_ID_3, ALT_ID_4, ALT_ID_5, ALT_ID_1) INCLUDE (RECORD_ID);

-- Stage VQ_OPERATION with pre-built key
SELECT 
    RECORD_ID,
    ID,
    -- Parse the ID if you need individual components
    CAST(SUBSTRING(ID, 1, CHARINDEX('~', ID)-1) AS NVARCHAR(1)) AS WORKORDER_TYPE,
    CAST(SUBSTRING(ID, CHARINDEX('~', ID)+1, CHARINDEX('~', ID, CHARINDEX('~', ID)+1) - CHARINDEX('~', ID)-1) AS NVARCHAR(7)) AS WORKORDER_BASE_ID,
    CAST(SUBSTRING(ID, CHARINDEX('~', ID, CHARINDEX('~', ID)+1)+1, CHARINDEX('~', ID, CHARINDEX('~', ID, CHARINDEX('~', ID)+1)+1) - CHARINDEX('~', ID, CHARINDEX('~', ID)+1)-1) AS NVARCHAR(1)) AS WORKORDER_LOT_ID,
    CAST(SUBSTRING(ID, CHARINDEX('~', ID, CHARINDEX('~', ID, CHARINDEX('~', ID)+1)+1)+1, CHARINDEX('~', ID, CHARINDEX('~', ID, CHARINDEX('~', ID, CHARINDEX('~', ID)+1)+1)+1) - CHARINDEX('~', ID, CHARINDEX('~', ID, CHARINDEX('~', ID)+1)+1)-1) AS NVARCHAR(1)) AS WORKORDER_SPLIT_ID,
    CAST(SUBSTRING(ID, CHARINDEX('~', ID, CHARINDEX('~', ID, CHARINDEX('~', ID, CHARINDEX('~', ID)+1)+1)+1)+1, CHARINDEX('~', ID, CHARINDEX('~', ID, CHARINDEX('~', ID, CHARINDEX('~', ID, CHARINDEX('~', ID)+1)+1)+1)+1) - CHARINDEX('~', ID, CHARINDEX('~', ID, CHARINDEX('~', ID, CHARINDEX('~', ID)+1)+1)+1)-1) AS NVARCHAR(1)) AS WORKORDER_SUB_ID,
    CAST(SUBSTRING(ID, CHARINDEX('~', ID, CHARINDEX('~', ID, CHARINDEX('~', ID, CHARINDEX('~', ID, CHARINDEX('~', ID)+1)+1)+1)+1)+1, LEN(ID)) AS NVARCHAR(5)) AS SEQUENCE_NO
INTO #IO
FROM [sql-bi-1].datawarehouse.dbo.VQ_OPERATION;

CREATE INDEX IX_IO ON #IO(ID) INCLUDE (RECORD_ID);

-- Stage NCM data
SELECT PROD_ORDER_REC_ID, OPERATION_REC_ID, NCM_ID, NCM_DATE, 
       SK_FIN_NCM_PROCESS, SK_MFG_NCM_PROCESS, SK_FIN_NCM_SUBPROCESS, 
       SK_MFG_NCM_SUBPROCESS, USER_DEFINED_4, USER_DEFINED_7,
       DISPOSITION_TYPE, NCM_TYPE, PRODUCT_REC_ID
INTO #NCM
FROM [sql-bi-1].datawarehouse.dbo.VQ_NONCONFORMANCE;

CREATE INDEX IX_NCM ON #NCM(PROD_ORDER_REC_ID, OPERATION_REC_ID);

-- stage product data
SELECT P.RECORD_ID, P.PRODUCT_ID 
INTO #PRODUCT  
FROM [sql-bi-1].datawarehouse.dbo.VQ_PRODUCT P;



With cte_operation as (
select 
 CAST(O.WORKORDER_TYPE AS NVARCHAR(1)) + '~' + CAST(O.WORKORDER_BASE_ID AS NVARCHAR(7)) + '~' 
        + CAST(O.WORKORDER_LOT_ID AS NVARCHAR(1)) + '~' + CAST(O.WORKORDER_SPLIT_ID AS NVARCHAR(1)) + '~' 
        + CAST(O.WORKORDER_SUB_ID AS NVARCHAR(1)) + '~' + CAST(O.SEQUENCE_NO AS NVARCHAR(5)) AS ud_workorder_id
        ,o.*
from OPERATION O
WHERE (
            O.CLOSE_DATE >= @STARTDATE AND O.CLOSE_DATE <= @ENDDATE
    )
),
cte_shop_resource as(
SELECT 
      SR.USER_1 AS BUSUNIT
    , CASE
        WHEN SR.USER_1 = 'A' THEN 'FIN'
        WHEN SR.USER_1 = 'M' THEN 'MFG'
        WHEN SR.USER_1 = 'O' THEN 'OUTREACH'
        WHEN SR.USER_1 = 'B' THEN 'BALLARD'
        WHEN SR.USER_1 = 'C' THEN 'CLOSED'
        ELSE '_Blank'
    END AS BUSINESS_UNIT

    , SR.USER_2 AS [PRIMARY]
    , SR.USER_3 AS [SECONDARY]
    , SR.USER_4 AS [SUPERVISOR]
    , SR.USER_5 AS [FACILITY]
    , SR.USER_7 AS [PROCESS]
    , SR.USER_8 AS [DEPARTMENT]
    ,sr.* 
FROM cte_operation O
JOIN DBO.SHOP_RESOURCE_SITE SR
    ON SR.RESOURCE_ID = O.RESOURCE_ID
),
cte_product as(
    select p.*
    from #NCM NCM
  left join #PRODUCT P
    ON P.RECORD_ID = NCM.PRODUCT_REC_ID
)
select * 
from cte_operation o
left join cte_shop_resource sr
    on sr.RESOURCE_ID = o.RESOURCE_ID   
LEFT JOIN #PO PO
    ON PO.[ALT_ID_2] = O.WORKORDER_BASE_ID
    AND PO.[ALT_ID_3] = O.WORKORDER_LOT_ID
    AND PO.[ALT_ID_4] = O.WORKORDER_SPLIT_ID
    AND PO.[ALT_ID_5] = O.WORKORDER_SUB_ID
    AND PO.[ALT_ID_1] = O.WORKORDER_TYPE
LEFT JOIN #IO IO
    ON IO.[ID] = CAST(O.WORKORDER_TYPE AS NVARCHAR(1)) + '~' + CAST(O.WORKORDER_BASE_ID AS NVARCHAR(7)) + '~' 
        + CAST(O.WORKORDER_LOT_ID AS NVARCHAR(1)) + '~' + CAST(O.WORKORDER_SPLIT_ID AS NVARCHAR(1)) + '~' 
        + CAST(O.WORKORDER_SUB_ID AS NVARCHAR(1)) + '~' + CAST(O.SEQUENCE_NO AS NVARCHAR(5))
LEFT JOIN #NCM NCM
    ON PO.RECORD_ID = NCM.PROD_ORDER_REC_ID
    AND IO.RECORD_ID = NCM.OPERATION_REC_ID
LEFT JOIN #PRODUCT P
    ON P.RECORD_ID = NCM.PRODUCT_REC_ID
WHERE (
            O.CLOSE_DATE >= @STARTDATE AND O.CLOSE_DATE <= @ENDDATE
    )
    AND (
        (@LISTTYPE = 'DEFECTS' 
        AND (NCM.NCM_TYPE NOT IN ('OVERAGE') AND NCM.NCM_TYPE IS NOT NULL)
        AND (NCM.DISPOSITION_TYPE NOT IN ('NON-DISCREPANT', 'OVERAGE') AND NCM.DISPOSITION_TYPE IS NOT NULL)
        )
        OR @LISTTYPE <> 'DEFECTS' 
        )