-- n✅ Optimized Query Structure

SET DATEFIRST 1;
SET NOCOUNT ON;

DECLARE @STARTDATE date = '2026-06-29';
DECLARE @ENDDATE date = '2026-07-05';
declare @timeframe nvarchar(25) = 'LAST WEEK'; 
declare @LISTTYPE nvarchar(25) = 'DEFECTS';
-- Pre-calculate dates
declare @CalcStartDate DATE = dateadd(YEAR, -2, getdate()); -- Example: 2 years back from today
declare @CalcEndDate DATE = getdate(); -- Example: current date

-- Pre-calculate dates
declare @NcmStartDate DATE = dateadd(YEAR, -2, getdate()); -- Example: 2 years back from today
declare @NcmEndDate DATE = getdate(); -- Example: current date
--

-- would you print the elapsed time for the query execution? You can use SET STATISTICS TIME ON; to see 
-- the time taken for parsing, compiling, and executing the query. 
SET STATISTICS TIME ON;

-- would you print the total number of rows returned by the query? You can use @@ROWCOUNT after the SELECT statement to get the number of rows affected by the last statement.
DECLARE @RowCount INT;

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
FROM [sql-bi-1].datawarehouse.dbo.VQ_NONCONFORMANCE NCM
WHERE 1 = 1
-- NCM_DATE >= @CalcStartDate AND NCM_DATE    <= @CalcEndDate; -- Filter NCM by date range if applicable
    AND (
        (@LISTTYPE = 'DEFECTS' 
        AND (NCM.NCM_TYPE NOT IN ('OVERAGE') AND NCM.NCM_TYPE IS NOT NULL)
        AND (NCM.DISPOSITION_TYPE NOT IN ('NON-DISCREPANT', 'OVERAGE') AND NCM.DISPOSITION_TYPE IS NOT NULL)
        )
        OR @LISTTYPE <> 'DEFECTS' 
        )

CREATE INDEX IX_NCM ON #NCM(PROD_ORDER_REC_ID, OPERATION_REC_ID);

-- Main query with local joins
SELECT 
    O.WORKORDER_BASE_ID,
    O.WORKORDER_LOT_ID,
    O.WORKORDER_SPLIT_ID,
    O.WORKORDER_SUB_ID,
    O.SEQUENCE_NO,
    O.RESOURCE_ID,
    O.OPERATION_TYPE,
    O.CLOSE_DATE,
    SR.USER_1 AS BUSUNIT,
    CASE SR.USER_1
        WHEN 'A' THEN 'FIN'
        WHEN 'M' THEN 'MFG'
        WHEN 'O' THEN 'OUTREACH'
        WHEN 'B' THEN 'BALLARD'
        WHEN 'C' THEN 'CLOSED'
        ELSE '_Blank'
    END AS BUSINESS_UNIT,
    SR.USER_2 AS [PRIMARY],
    SR.USER_3 AS [SECONDARY],
    SR.USER_4 AS [SUPERVISOR],
    SR.USER_5 AS [FACILITY],
    SR.USER_7 AS [PROCESS],
    SR.USER_8 AS [DEPARTMENT],
    CASE
        WHEN @TIMEFRAME IN ('LAST WEEK', 'CURRENT WEEK') THEN DATENAME(WEEKDAY, O.CLOSE_DATE)
        WHEN @TIMEFRAME IN ('LAST MONTH', 'CURRENT MONTH', 'OTHER') 
            THEN CONVERT(VARCHAR(15), DATEADD(WEEK, DATEDIFF(WEEK, 0, O.CLOSE_DATE), -1), 101)
        ELSE DATENAME(MONTH, O.CLOSE_DATE)
    END AS [TIMEFRAME],
    CASE
        WHEN @TIMEFRAME IN ('LAST WEEK', 'CURRENT WEEK') THEN CONVERT(NVARCHAR(15), O.CLOSE_DATE, 101)
        WHEN @TIMEFRAME IN ('LAST MONTH', 'CURRENT MONTH', 'OTHER') THEN ''
        ELSE CONVERT(NVARCHAR(15), YEAR(O.CLOSE_DATE))
    END AS [LABEL],
    CASE
        WHEN @TIMEFRAME IN ('LAST WEEK', 'CURRENT WEEK') THEN DATEPART(DD, O.CLOSE_DATE)
        WHEN @TIMEFRAME IN ('LAST MONTH', 'CURRENT MONTH', 'OTHER') 
            THEN DATEPART(WW, DATEADD(WEEK, DATEDIFF(WEEK, 0, O.CLOSE_DATE), -1))
        ELSE DATEPART(MM, O.CLOSE_DATE)
    END AS [CHARTSORT],
    @STARTDATE AS [STARTDATE],
    @ENDDATE AS [ENDDATE],
    NCM.NCM_ID,
    NCM.NCM_DATE,
    IIF(NCM.NCM_ID IS NULL, NULL, 
        COALESCE(NCM.SK_FIN_NCM_PROCESS, NCM.SK_MFG_NCM_PROCESS, '_BLANK')) AS [IQM_PROCESS],
    IIF(NCM.NCM_ID IS NULL, NULL,
        COALESCE(NCM.SK_FIN_NCM_SUBPROCESS, NCM.SK_MFG_NCM_SUBPROCESS, '_BLANK')) AS [IQM_SUBPROCESS],
    IIF(NCM.NCM_ID IS NULL, NULL,
        COALESCE(NCM.USER_DEFINED_4, NCM.USER_DEFINED_7, '_BLANK')) AS [IQM_DEFECT],
    NCM.DISPOSITION_TYPE,
    NCM.NCM_TYPE
    -- execution time version 1.1 is 3:04 
    -- this query will run much faster if you can filter the #NCM table by date range before joining, if applicable
    -- execution time version 1.2 is ___

FROM DBO.OPERATION O
LEFT JOIN DBO.SHOP_RESOURCE_SITE SR  -- Change to INNER if SR is always required
    ON SR.RESOURCE_ID = O.RESOURCE_ID
LEFT JOIN #PO PO
    ON PO.ALT_ID_2 = O.WORKORDER_BASE_ID
    AND PO.ALT_ID_3 = O.WORKORDER_LOT_ID
    AND PO.ALT_ID_4 = O.WORKORDER_SPLIT_ID
    AND PO.ALT_ID_5 = O.WORKORDER_SUB_ID
    AND PO.ALT_ID_1 = O.WORKORDER_TYPE
LEFT JOIN #IO IO
    ON IO.ID = CAST(O.WORKORDER_TYPE AS NVARCHAR(1)) + '~' 
             + CAST(O.WORKORDER_BASE_ID AS NVARCHAR(7)) + '~' 
             + CAST(O.WORKORDER_LOT_ID AS NVARCHAR(1)) + '~' 
             + CAST(O.WORKORDER_SPLIT_ID AS NVARCHAR(1)) + '~' 
             + CAST(O.WORKORDER_SUB_ID AS NVARCHAR(1)) + '~' 
             + CAST(O.SEQUENCE_NO AS NVARCHAR(5))
-- the previous query was written with where clause effectively equijoining #NCM to #PO and #IO, so we can join directly to #NCM using the same keys
LEFT JOIN #NCM NCM
    ON PO.RECORD_ID = NCM.PROD_ORDER_REC_ID
    AND IO.RECORD_ID = NCM.OPERATION_REC_ID
WHERE O.CLOSE_DATE >= @STARTDATE 
  AND O.CLOSE_DATE <= @ENDDATE
  AND O.[STATUS] != 'X'  -- Enable if STATUS column exists
  AND (
        (@LISTTYPE = 'DEFECTS' 
        AND (NCM.NCM_TYPE NOT IN ('OVERAGE') AND NCM.NCM_TYPE IS NOT NULL)
        AND (NCM.DISPOSITION_TYPE NOT IN ('NON-DISCREPANT', 'OVERAGE') AND NCM.DISPOSITION_TYPE IS NOT NULL)
        )
        OR @LISTTYPE <> 'DEFECTS' 
        )
OPTION (RECOMPILE);  -- Use parameter sniffing for date range

set @RowCount = @@ROWCOUNT;
SELECT @RowCount AS TotalRowsReturned;
-- Cleanup
DROP TABLE IF EXISTS #PO, #IO, #NCM;