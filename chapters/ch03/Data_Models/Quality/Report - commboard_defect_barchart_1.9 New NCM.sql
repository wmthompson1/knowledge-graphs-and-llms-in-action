-- Report - commboard_defect_barchart_1.9 New NCM
/**********************************************************************************************

Description:  Report - commboard_defect_barchart_1.9 New NCM
Note:   
   

Date        Modified By         Change Description
----------  ------------------  ------------------------------------------------------------
09/02

**********************************************************************************************/

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET DEADLOCK_PRIORITY LOW
--> VISUAL ENTERPRISE > WORK ORDER REPORTS > COMMBOARD DEFECT CHARTS
SET DATEFIRST 1;

IF OBJECT_ID('tempdb..#Results') IS NOT NULL DROP TABLE #Results
IF OBJECT_ID('tempdb..#NCM') IS NOT NULL DROP TABLE #NCM
IF OBJECT_ID('tempdb..#FACILITY') IS NOT NULL DROP TABLE #FACILITY
-- #DEPARTMENT
IF OBJECT_ID('tempdb..#DEPARTMENT') IS NOT NULL DROP TABLE #DEPARTMENT
-- #DEFECT_NCM_NEW
IF OBJECT_ID('tempdb..#DEFECT_NCM_NEW') IS NOT NULL DROP TABLE #DEFECT_NCM_NEW
--- ==========================================
--- ==========================================
IF OBJECT_ID('tempdb..#IQM_PROCESS') IS NOT NULL DROP TABLE #IQM_PROCESS
IF OBJECT_ID('tempdb..#IQM_DEFECTS') IS NOT NULL DROP TABLE #IQM_DEFECTS

--- ==========================================
--- ==========================================

IF OBJECT_ID('tempdb..#temp1') IS NOT NULL DROP TABLE #temp1
IF OBJECT_ID('tempdb..#temp2') IS NOT NULL DROP TABLE #temp2
IF OBJECT_ID('tempdb..#temp3') IS NOT NULL DROP TABLE #temp3
IF OBJECT_ID('tempdb..#temp4') IS NOT NULL DROP TABLE #temp4
IF OBJECT_ID('tempdb..#temp5') IS NOT NULL DROP TABLE #temp5
-- needed for commboard_defect_barchart
declare @STARTDATE date = DATEADD(WEEK, DATEDIFF(WEEK, 7, GETDATE()), 0);
declare @ENDDATE date = DATEADD(WEEK, DATEDIFF(WEEK, 7, GETDATE()), 6);
-- in test
declare @timeframe nvarchar(25) = 'LAST QUARTER';  -- -- 'LAST YEAR'; -- -- 'LAST WEEK'; 
declare @LISTTYPE nvarchar(25) = 'DEFECTS';
-- 

declare @DEPARTMENT nvarchar(50) = 'cnc';
declare @FACILITY nvarchar(50) = 'ap2';
DECLARE @IQM_PROCESS NVARCHAR(50) = 'ALL';
DECLARE @IQM_DEFECT NVARCHAR(50) = 'ALL';

DECLARE @Tester int
declare @part_id nvarchar(250) = NULL; -- --  '313Z7430-504';  -- '313Z7430-504' '70750B-071-MIL-NG';
Set @Tester = 0
DECLARE @workorder_base_id nvarchar(30) = NULL; -- -- 
Declare @resource_id nvarchar(30) = NULL;  -- -- 
DECLARE @NCM_NUMBER NVARCHAR(30) = NULL; -- '50668';

--- ==========================================
--- ==========================================

SELECT u.* into #IQM_PROCESS
from (
SELECT '_Blank' AS [IQM_DEFECT]
UNION
SELECT COALESCE(USER_DEFINED_4, USER_DEFINED_7, '_Blank') AS [IQM_DEFECT]
FROM [sql-bi-1].datawarehouse.dbo.VQ_NONCONFORMANCE
GROUP BY COALESCE(USER_DEFINED_4, USER_DEFINED_7, '_Blank')
UNION
-- new ncm defects 
select COALESCE(defect_id, '_Blank') as  [IQM_DEFECT]
from [sql-lab-2].ncm.dbo.nonconformance 
group by defect_id
) u
order by 1
-- select * from #IQM_PROCESS

-- FACILITY
SELECT f.* into #FACILITY
from(
SELECT 'Undetermined' AS FACILITY
UNION
SELECT '_Blank' AS [FACILITY]
UNION
SELECT ISNULL(USER_5, '_Blank') AS [FACILITY]
FROM SHOP_RESOURCE_SITE_VIEW
WHERE ([STATUS] != 'O' OR [STATUS] IS NULL)
AND USER_5 != 'ALL'
GROUP BY USER_5
) f

-- DEPARTMENT
SELECT d.* into #DEPARTMENT
from(
SELECT '_Blank' AS DEPARTMENT
UNION
SELECT ISNULL(USER_8, '_Blank') AS DEPARTMENT   -- process
FROM SHOP_RESOURCE_SITE_VIEW
WHERE ([STATUS] != 'O' OR [STATUS] IS NULL)
AND USER_5 != 'ALL'
GROUP BY USER_8
) d

--- ==========================================
--- ==========================================





-- Pre-calculate dates
DECLARE @CalcStartDate DATE, @CalcEndDate DATE;
SELECT @CalcStartDate = CASE
    WHEN @TIMEFRAME = 'LAST WEEK' THEN DATEADD(WEEK, DATEDIFF(WEEK, 7, GETDATE()), 0)

    WHEN @TIMEFRAME = 'OTHER' THEN @STARTDATE
    -- ... add other cases
		/*
		WHEN @TIMEFRAME = 'CURRENT WEEK' THEN CONVERT(DATE, DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE()), 0))
		WHEN @TIMEFRAME = 'LAST MONTH' THEN CONVERT(DATE, DATEADD(MM, DATEDIFF(MM, 0, GETDATE()) - 1, 0))
		WHEN @TIMEFRAME = 'CURRENT MONTH' THEN CONVERT(DATE, DATEADD(D, -(DAY(GETDATE()-1)), GETDATE()))
		
		WHEN @TIMEFRAME = 'CURRENT YEAR' THEN CONVERT(DATE, DATEADD(YY, DATEDIFF(YY, 0, GETDATE()), 0)) 
		
		WHEN @TIMEFRAME = 'CURRENT QUARTER' THEN CONVERT(DATE, DATEADD(QQ, DATEDIFF(QQ, 0, GETDATE()), 0))


	*/
	WHEN @TIMEFRAME = 'LAST YEAR' THEN CONVERT(DATE, DATEADD(YEAR, DATEDIFF(YEAR, 0, GETDATE()) - 1, 0))
	WHEN @TIMEFRAME = 'LAST QUARTER' THEN CONVERT(DATE, DATEADD(QUARTER, DATEDIFF(QUARTER, 0 , GETDATE()) - 1, 0))
	ELSE @STARTDATE
END,
@CalcEndDate = CASE
    WHEN @TIMEFRAME = 'LAST WEEK' THEN DATEADD(WEEK, DATEDIFF(WEEK, 7, GETDATE()), 6)
    WHEN @TIMEFRAME = 'OTHER' THEN @ENDDATE
    -- ... add other cases
	/*

		WHEN @TIMEFRAME = 'CURRENT WEEK' THEN CONVERT(DATE, DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE()), 6))
		WHEN @TIMEFRAME = 'LAST MONTH' THEN CONVERT(DATE, DATEADD(D, -(DAY(GETDATE())), GETDATE()))
		WHEN @TIMEFRAME = 'CURRENT MONTH' THEN CONVERT(DATE, EOMONTH(GETDATE()))

		WHEN @TIMEFRAME = 'CURRENT YEAR' THEN CONVERT(DATE, DATEADD(YY, DATEDIFF(YY, 0, GETDATE()) + 1, -1))
		
		WHEN @TIMEFRAME = 'CURRENT QUARTER' THEN CONVERT(DATE, DATEADD(DD, -1, DATEADD(QQ, DATEDIFF(QQ, 0, GETDATE()) + 1, 0)))

	*/
	WHEN @TIMEFRAME = 'LAST YEAR' THEN CONVERT(DATE, DATEADD(YEAR, DATEDIFF(YEAR, 0, GETDATE()), -1))
	WHEN @TIMEFRAME = 'LAST QUARTER' THEN CONVERT(DATE, DATEADD(DD, -1, DATEADD(QQ, DATEDIFF(QQ, 0, GETDATE()), 0)))
	ELSE @ENDDATE
END;

--PRINT CAST(@STARTDATE AS DATE)
--PRINT CAST(@ENDDATE AS DATE)

--PRINT CAST(@CalcStartDate AS DATE)
--PRINT CAST(@CalcEndDate AS DATE)

-- ============================================

-- ncm new
SELECT 
       [NONCONFORMANCE_ID]
      ,[NCM_NUMBER]
      ,[NCM_TYPE_CODE]
      ,[NCM_DATE]
      ,[NCM_STATUS]
      ,[NCM_CLOSED_DATE]
      ,[BASE_ID]   -- 1829456
      ,[PART_ID]
      ,[LOT_ID]
      ,[SPLIT_ID]
      ,[SUB_ID]
      ,[OPERATION_ID] as SEQUENCE_NO  -- SEQUENCE
      ,[DISPOSITION_BY_TYPE]
      ,[RESOURCE_ID_DESCRIPTION]
      ,[CUST_REF]
      ,[CERT_NUMBER]
      ,[LOT_SIZE]
      ,[ACCEPTED]
      ,[REJECTED]
      ,[VENDOR_PO_NUMBER]
      ,[AS_IS_DIMENSION]
      ,[SHOULD_BE_DIMENSION]
      ,[IS_SUPPLIER_NOTICE_SENT]
      ,[NCM_DESCRIPTION]
      ,[DISPOSITION_TYPE_CODE]
      ,[DISPOSITION_DATE]
      ,[DISPOSITION_CLOSED_DATE]
      ,[DISPOSITION_BY_EMPLOYEE_ID]
      ,[DISPOSITION_ASSIGNED_TO_EMPLOYEE_ID]
      ,[REWORK_QTY]
      ,[SCRAP_QTY]
      ,[OVERAGE_QTY]
      ,[RETURN_QTY]
      ,[ACCEPTED_QTY_DISPOSITION]
      ,[REBUILD_QTY]
      ,[DISPOSITION_NOTES]
      ,[REPORTED_BY_SUPPLIER_ID]
      ,[ROOT_CAUSE_TEXT]
      ,[CORRECTION_TEXT]
      ,[MADE_BY_EMPLOYEE_ID]
      ,[ASSIGNED_TO_EMPLOYEE_ID]
      ,[VERIFICATION_DATE]
      ,[VERIFIED_BY_EMPLOYEE_ID]
      ,[DESTRUCTION_DATE]
      ,[VERIFICATION_CLOSED_DATE]
      ,[VERIFICATION_NOTES]
      ,[CreatedAt]
      ,[UpdatedAt]
      ,[RowPointer]
      ,[NEXT_STEP]
      ,[EMAIL_PLANNING_FOR_REWORK]
      ,[TAG_AREA]
      ,[PROCESS_ID]
      ,[SUBPROCESS_ID]
      ,[DEFECT_ID]
      ,[EMAIL_PLANNING_SENT_AT]
	  INTO #NCM
  FROM NCM.dbo.NONCONFORMANCE
  where 1=1 
    and (NCM_NUMBER = @NCM_NUMBER or @NCM_NUMBER is null)
  ;

-- ============================================

-- 1 --------------

	-- NCM (NEW)------------------------
	-- DEFECTS

With route as (
select
  'work order operations' note
  -- part
  , a.part_id
  , P.STOCK_UM

  -- work order
  , a.status workorder_status
  , a.base_id
  , a.lot_id
  , a.split_id
  , a.sub_id
  -- operation routing
  , o.SEQUENCE_NO
  , o.RESOURCE_ID
  , o.CLOSE_DATE 
  , o.status operation_status

    -- Resource
  ,SR.DESCRIPTION AS RESOURCE_DESCRIPTION
  ,SR.USER_5 AS Facility  -- Plant 1 or 2 e.g. AP1, AP2 Auburn Plant 1, Auburn Plant 2
  ,SR.USER_6 AS Department  -- Department responsible for the resource, e.g. Receiving, CNC, ASSEMBLY
  ,SR.USER_7 AS SubProcess  -- SubProcess associated with the resource
  ,SR.USER_8 AS Process  -- Process associated with the resource, aka Reporting_Group

  from dbo.WORK_ORDER a
  INNER JOIN OPERATION o
  on o.WORKORDER_BASE_ID=a.BASE_ID 
  and o.WORKORDER_LOT_ID=a.LOT_ID and
    o.WORKORDER_SPLIT_ID = a.SPLIT_ID
    and o.WORKORDER_SUB_ID = a.SUB_ID
  LEFT OUTER JOIN SHOP_RESOURCE SR
		ON SR.ID = O.RESOURCE_ID

  Inner Join PART P  with (nolock) on a.PART_ID = P.ID

where 1=1
	AND a.Type = 'w'
	AND (a.base_id = @workorder_base_id OR @workorder_base_id IS NULL)
	--and a.STATUS not in ('X', 'C')
	and a.STATUS not in ('X')
	--and a.STATUS in ('R', 'E', 'H', 'S', 'P', 'F','C')  -- Released, Enroute, Hold, Started, Partially Complete, Finished,Closed
	and (a.part_id = @Part_ID or @Part_ID IS NULL )
	AND (o.RESOURCE_ID = @resource_id OR @resource_id IS NULL)
	AND isnull(SR.USER_6,'') != 'PENETRANT'
	AND (SR.USER_8 IN (@DEPARTMENT) OR @DEPARTMENT = 'ALL') -- process e.g.cnc
	AND (SR.USER_5 IN (@FACILITY) OR @FACILITY = 'ALL')   -- plant e.g. plant 1
	and O.CLOSE_DATE >= @STARTDATE
	AND O.CLOSE_DATE <= @ENDDATE
)
 ------  select * from #ncm
select 
	'ncm-new-defect-count' note
	,n.DEFECT_ID
	,n.[NCM_NUMBER]

	,n.PROCESS_ID  -- e.g. CNC
	,n.SUBPROCESS_ID  -- e.g. 5-Axis, 4-Axis
	,n.NCM_TYPE_CODE
	,n.DISPOSITION_TYPE_CODE


  -- part
  , r.part_id
  , r.STOCK_UM

  -- work order
  , r.workorder_status
  , r.base_id
  , r.lot_id
  , r.split_id
  , r.sub_id
  
  -- operation routing
  , r.SEQUENCE_NO
  , r.RESOURCE_ID
  , r.CLOSE_DATE 
  , r.operation_status

    -- Resource
  ,r.RESOURCE_DESCRIPTION
  ,r.Facility  -- Plant 1 or 2 e.g. AP1, AP2 Auburn Plant 1, Auburn Plant 2
  ,r.Department  -- Department responsible for the resource, e.g. Receiving, CNC, ASSEMBLY
  ,r.SubProcess  -- SubProcess associated with the resource
  ,r.Process  -- Process associated with the resource, aka Reporting_Group
INTO #DEFECT_NCM_NEW
from route r
join #ncm n
  on r.BASE_ID=n.BASE_ID 
  and r.LOT_ID=n.LOT_ID and
    r.SPLIT_ID = n.SPLIT_ID
    and r.SUB_ID = n.SUB_ID
	and r.SEQUENCE_NO = n.SEQUENCE_NO

order by n.ncm_date, r.BASE_ID, r.LOT_ID
;

-- select * from #DEFECT_NCM_NEW
-- 2 --------------


-- NEW FROM #DEFECT_NCM_NEW
SELECT 
      NCM.BASE_ID
	, NCM.LOT_ID
	, NCM.SPLIT_ID
	, NCM.SUB_ID
	, NCM.SEQUENCE_NO
	, NCM.RESOURCE_ID
--	, NCM.OPERATION_TYPE
	, NCM.CLOSE_DATE
	-- , O.USER_5 AS [FACILITY]
	-- , O.USER_8 AS [DEPARTMENT]
	,NCM.FACILITY
	,NCM.DEPARTMENT
	-- 
	, CASE
		WHEN @TIMEFRAME IN ('LAST WEEK', 'CURRENT WEEK') THEN DATENAME(WEEKDAY, ncm.CLOSE_DATE)
		WHEN @TIMEFRAME IN ('LAST MONTH', 'CURRENT MONTH', 'OTHER') THEN CONVERT(VARCHAR(15), DATEADD(WEEK, DATEDIFF(WEEK, 0, ncm.CLOSE_DATE), -1), 101)
		ELSE DATENAME(MONTH, ncm.CLOSE_DATE)
	END AS [TIMEFRAME]

	, CASE
		WHEN @TIMEFRAME IN ('LAST WEEK', 'CURRENT WEEK') THEN CONVERT(NVARCHAR(15), ncm.CLOSE_DATE, 101)
		WHEN @TIMEFRAME IN ('LAST MONTH', 'CURRENT MONTH', 'OTHER') THEN ''
		ELSE CONVERT(NVARCHAR(15), YEAR(ncm.CLOSE_DATE))
	END AS [LABEL]

	, CASE
--		WHEN @TIMEFRAME IN ('LAST WEEK', 'CURRENT WEEK') THEN DATEPART(DD, ncm.CLOSE_DATE)
		WHEN @TIMEFRAME IN ('LAST WEEK', 'CURRENT WEEK') THEN ncm.CLOSE_DATE
		WHEN @TIMEFRAME IN ('LAST MONTH', 'CURRENT MONTH', 'OTHER') 
        THEN DATEPART(WW, DATEADD(WEEK, DATEDIFF(WEEK, 0, ncm.CLOSE_DATE), -1))
		ELSE DATEPART(MM, ncm.CLOSE_DATE)
	END [CHARTSORT]

	,@STARTDATE AS STARTDATE

	, @ENDDATE AS [ENDDATE]
	-- , NCM.NCM_ID
	-- , NCM.NCM_DATE
	-- , IIF(ISNULL(NCM.NCM_ID, '_BLANK') = '_BLANK', NULL, COALESCE(NCM.SK_FIN_NCM_PROCESS, NCM.SK_MFG_NCM_PROCESS, '_BLANK')) AS [IQM_PROCESS]
	-- , IIF(ISNULL(NCM.NCM_ID, '_BLANK') = '_BLANK', NULL, COALESCE(NCM.SK_FIN_NCM_SUBPROCESS, NCM.SK_MFG_NCM_SUBPROCESS, '_BLANK')) AS [IQM_SUBPROCESS]
	-- , IIF(ISNULL(NCM.NCM_ID, '_BLANK') = '_BLANK', NULL, COALESCE(NCM.USER_DEFINED_4, NCM.USER_DEFINED_7, '_BLANK')) AS [IQM_DEFECT]
	-- , NCM.DISPOSITION_TYPE
	-- , NCM.NCM_TYPE

FROM #DEFECT_NCM_NEW NCM
-- --LEFT OUTER JOIN DATAWAREHOUSE.DBO.VQ_PRODUCTION_ORDER PO
-- LEFT OUTER JOIN [sql-bi-1].DATAWAREHOUSE.DBO.VQ_PRODUCTION_ORDER PO
-- 	ON PO.[ALT_ID_2] = O.WORKORDER_BASE_ID
-- 	AND PO.[ALT_ID_3] = O.WORKORDER_LOT_ID
-- 	AND PO.[ALT_ID_4] = O.WORKORDER_SPLIT_ID
-- 	AND PO.[ALT_ID_5] = O.WORKORDER_SUB_ID
-- 	AND PO.[ALT_ID_1] = O.WORKORDER_TYPE
-- --LEFT OUTER JOIN DATAWAREHOUSE.DBO.VQ_OPERATION IO
-- LEFT OUTER JOIN [sql-bi-1].DATAWAREHOUSE.DBO.VQ_OPERATION IO
-- 	ON IO.[ID] = CAST(O.WORKORDER_TYPE AS NVARCHAR(1)) + '~' + CAST(O.WORKORDER_BASE_ID AS NVARCHAR(7)) + '~' 
-- 		+ CAST(O.WORKORDER_LOT_ID AS NVARCHAR(1)) + '~' + CAST(O.WORKORDER_SPLIT_ID AS NVARCHAR(1)) + '~' 
-- 		+ CAST(O.WORKORDER_SUB_ID AS NVARCHAR(1)) + '~' + CAST(O.SEQUENCE_NO AS NVARCHAR(5))
-- --LEFT OUTER JOIN DATAWAREHOUSE.DBO.VQ_NONCONFORMANCE NCM
-- LEFT OUTER JOIN [sql-bi-1].DATAWAREHOUSE.DBO.VQ_NONCONFORMANCE NCM
-- 	ON PO.RECORD_ID = NCM.PROD_ORDER_REC_ID
-- 	AND IO.RECORD_ID = NCM.OPERATION_REC_ID
-- LEFT OUTER JOIN [sql-bi-1].DATAWAREHOUSE.DBO.VQ_PRODUCT P
-- 	ON P.RECORD_ID = NCM.PRODUCT_REC_ID
-- ~22

-- ~
WHERE 1 = 1
AND ncm.CLOSE_DATE BETWEEN @CalcStartDate AND @CalcEndDate

	--	AND (NCM.NCM_TYPE_CODE NOT IN ('OVERAGE') AND NCM.NCM_TYPE_CODE IS NOT NULL)
	--	AND (NCM.DISPOSITION_TYPE_CODE NOT IN ('NON-DISCREPANT', 'OVERAGE') AND NCM.DISPOSITION_TYPE_CODE IS NOT NULL)
	--AND (ISNULL(ncm.FACILITY, '_BLANK') IN (@FACILITY) OR @FACILITY = 'ALL')
	--AND (ISNULL(ncm.DEPARTMENT, '_BLANK') IN (@DEPARTMENT) OR @DEPARTMENT = 'ALL')
	----AND (ISNULL(SR.USER_5, '_BLANK') IN (@FACILITY) )
	----AND (ISNULL(SR.USER_8, '_BLANK') IN (@DEPARTMENT))
	---- in test
	--AND ( COALESCE(NCM.SK_FIN_NCM_PROCESS, NCM.SK_MFG_NCM_PROCESS, '_BLANK') IN (@IQM_PROCESS) OR @IQM_PROCESS = 'ALL')
	--AND ( COALESCE(NCM.USER_DEFINED_4, NCM.USER_DEFINED_7, '_BLANK') IN (@IQM_DEFECT) OR @IQM_DEFECT = 'ALL')

	--AND ( COALESCE(NCM.SK_FIN_NCM_PROCESS, NCM.SK_MFG_NCM_PROCESS, '_BLANK') IN (@IQM_PROCESS) )
	--AND ( COALESCE(NCM.USER_DEFINED_4, NCM.USER_DEFINED_7, '_BLANK') IN (@IQM_DEFECT))

	AND NCM.operation_status != 'X'




	--select * from #NCM

	--SELECT 1
	--FROM [sql-lab-2].live.DBO.OPERATION O
 --   LEFT OUTER JOIN [sql-lab-2].live.DBO.SHOP_RESOURCE_SITE SR
	--ON SR.RESOURCE_ID = O.RESOURCE_ID
	--WHERE 1 = 1
 --   AND ncm.CLOSE_DATE BETWEEN @CalcStartDate AND @CalcEndDate


	