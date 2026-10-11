

--USE LIVE --
-- GO
-- CommBoard Quality (Facility)_2.0.sql

/**********************************************************************************************

Description:  CommBoard Quality (Department)_2.0.sql
Note:   
   

Date        Modified By         Change Description
----------  ------------------  ------------------------------------------------------------
9/4         williamt


The CommBoard Quality (Facility) has a different graikn in  the defect list dataset

**********************************************************************************************/

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET DEADLOCK_PRIORITY LOW;
SET DATEFIRST 1;

IF OBJECT_ID('tempdb..#Results') IS NOT NULL DROP TABLE #Results
IF OBJECT_ID('tempdb..#NCM') IS NOT NULL DROP TABLE #NCM
IF OBJECT_ID('tempdb..#FACILITY') IS NOT NULL DROP TABLE #FACILITY
-- #DEPARTMENT
IF OBJECT_ID('tempdb..#DEPARTMENT') IS NOT NULL DROP TABLE #DEPARTMENT
IF OBJECT_ID('tempdb..#IQM_PROCESS') IS NOT NULL DROP TABLE #IQM_PROCESS
IF OBJECT_ID('tempdb..#IQM_DEFECTS') IS NOT NULL DROP TABLE #IQM_DEFECTS

-- DEFECT_NCM_NEW
IF OBJECT_ID('tempdb..#DEFECT_NCM_NEW') IS NOT NULL DROP TABLE #DEFECT_NCM_NEW
---- DEFECT_COUNT
--IF OBJECT_ID('tempdb..#DEFECT_COUNT') IS NOT NULL DROP TABLE #DEFECT_COUNT
---- DEFECT_COUNT2
--IF OBJECT_ID('tempdb..#DEFECT_COUNT2') IS NOT NULL DROP TABLE #DEFECT_COUNT2
-- DEFECT_LIST
IF OBJECT_ID('tempdb..#DEFECT_LIST') IS NOT NULL DROP TABLE #DEFECT_LIST
-- #DEFECT_IQM
IF OBJECT_ID('tempdb..#DEFECT_IQM') IS NOT NULL DROP TABLE #DEFECT_IQM

IF OBJECT_ID('tempdb..#temp1') IS NOT NULL DROP TABLE #temp1
IF OBJECT_ID('tempdb..#temp2') IS NOT NULL DROP TABLE #temp2
IF OBJECT_ID('tempdb..#temp3') IS NOT NULL DROP TABLE #temp3
IF OBJECT_ID('tempdb..#temp4') IS NOT NULL DROP TABLE #temp4
IF OBJECT_ID('tempdb..#temp5') IS NOT NULL DROP TABLE #temp5

 --declare @STARTDATE date = DATEADD(WEEK, DATEDIFF(WEEK, 7, GETDATE()), 0);
--declare @STARTDATE date = CONVERT(DATE, DATEADD(QQ, DATEDIFF(QQ, 0, GETDATE()), 0))
 --declare @ENDDATE date = DATEADD(WEEK, DATEDIFF(WEEK, 7, GETDATE()), 6);
--declare @ENDDATE date = CONVERT(DATE, DATEADD(DD, -1, DATEADD(QQ, DATEDIFF(QQ, 0, GETDATE()) + 1, 0)))

-- in test
--declare @timeframe nvarchar(25) =  'CURRENT QUARTER'  -- -- 'LAST QUARTER';  -- -- 'LAST YEAR'; -- -- 'LAST WEEK'; 
declare @LISTTYPE nvarchar(25) = 'DEFECTS';
-- 

--declare @DEPARTMENT nvarchar(50) = 'CNC';
--declare @FACILITY nvarchar(50) = 'AP2';
DECLARE @IQM_PROCESS NVARCHAR(50) = 'ALL';
DECLARE @IQM_DEFECT NVARCHAR(50) = 'ALL';

DECLARE @Tester int
--declare @part_id nvarchar(250) = NULL; -- --  '313Z7430-504';  -- '313Z7430-504' '70750B-071-MIL-NG';
Set @Tester = 0
DECLARE @workorder_base_id nvarchar(30) = NULL; -- -- 
Declare @resource_id nvarchar(30) = NULL;  -- -- 
DECLARE @NCM_NUMBER NVARCHAR(30) = NULL; -- '50668';

--- ========================================== ~22
--- ========================================== ~22
-- #IQM_PROCESS
-- !LookupIQMProcess

SELECT p.* 
  into #temp1
FROM (
SELECT '_Blank' AS [IQM_PROCESS]
UNION
SELECT COALESCE(SK_FIN_NCM_PROCESS, SK_MFG_NCM_PROCESS, '_BLANK') AS [IQM_PROCESS]
FROM [sql-bi-1].Datawarehouse.dbo.VQ_NONCONFORMANCE
GROUP BY COALESCE(SK_FIN_NCM_PROCESS, SK_MFG_NCM_PROCESS, '_BLANK')
UNION
select COALESCE(PROCESS_ID, '_BLANK') AS [IQM_PROCESS] 
FROM NCM.dbo.NONCONFORMANCE
GROUP BY COALESCE(PROCESS_ID, '_BLANK')
) p
order by 1
;

--- ========================================== ~22
--- ========================================== ~22
-- #IQM_DEFECTS
-- ! LookupIQMDefects
SELECT u.* into #IQM_DEFECTS
from (
-- old iqm
SELECT '_Blank' AS [IQM_DEFECT]
UNION
SELECT COALESCE(USER_DEFINED_4, USER_DEFINED_7, '_Blank') AS [IQM_DEFECT]
FROM [sql-bi-1].datawarehouse.dbo.VQ_NONCONFORMANCE
GROUP BY COALESCE(USER_DEFINED_4, USER_DEFINED_7, '_Blank')
UNION
 -- new ncm defects 
select COALESCE(defect_id, '_Blank') as  [IQM_DEFECT]
from [sql-lab-2].ncm.dbo.nonconformance 
group by COALESCE(defect_id, '_Blank')
) u
order by 1
-- select * from ##IQM_DEFECTS

--- ========================================== ~22
--- ========================================== ~22
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

--- ========================================== ~22
--- ========================================== ~22
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
--- ==================same as dept========================

SELECT '_Blank' AS [REPTGROUP]
UNION
SELECT ISNULL(USER_8, '_Blank') AS [REPTGROUP]
FROM SHOP_RESOURCE_SITE_VIEW
WHERE ([STATUS] != 'O' OR [STATUS] IS NULL)
AND USER_5 != 'ALL'
GROUP BY USER_8

--- ==========================================
--- ==========================================


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




---- Pre-calculate dates
--DECLARE @CalcStartDate DATE, @CalcEndDate DATE;
--SELECT @CalcStartDate = CASE
--    WHEN @TIMEFRAME = 'LAST WEEK' THEN DATEADD(WEEK, DATEDIFF(WEEK, 7, GETDATE()), 0)

--    WHEN @TIMEFRAME = 'OTHER' THEN @STARTDATE
--    -- ... add other cases
--		/*
--		WHEN @TIMEFRAME = 'CURRENT WEEK' THEN CONVERT(DATE, DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE()), 0))
--		WHEN @TIMEFRAME = 'LAST MONTH' THEN CONVERT(DATE, DATEADD(MM, DATEDIFF(MM, 0, GETDATE()) - 1, 0))
--		WHEN @TIMEFRAME = 'CURRENT MONTH' THEN CONVERT(DATE, DATEADD(D, -(DAY(GETDATE()-1)), GETDATE()))
		
--		WHEN @TIMEFRAME = 'CURRENT YEAR' THEN CONVERT(DATE, DATEADD(YY, DATEDIFF(YY, 0, GETDATE()), 0)) 
		
--		WHEN @TIMEFRAME = 'CURRENT QUARTER' THEN CONVERT(DATE, DATEADD(QQ, DATEDIFF(QQ, 0, GETDATE()), 0))


--	*/
--	WHEN @TIMEFRAME = 'LAST YEAR' THEN CONVERT(DATE, DATEADD(YEAR, DATEDIFF(YEAR, 0, GETDATE()) - 1, 0))
--	WHEN @TIMEFRAME = 'LAST QUARTER' THEN CONVERT(DATE, DATEADD(QUARTER, DATEDIFF(QUARTER, 0 , GETDATE()) - 1, 0))
--	ELSE @STARTDATE
--END,
--@CalcEndDate = CASE
--    WHEN @TIMEFRAME = 'LAST WEEK' THEN DATEADD(WEEK, DATEDIFF(WEEK, 7, GETDATE()), 6)
--    WHEN @TIMEFRAME = 'OTHER' THEN @ENDDATE
--    -- ... add other cases
--	/*

--		WHEN @TIMEFRAME = 'CURRENT WEEK' THEN CONVERT(DATE, DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE()), 6))
--		WHEN @TIMEFRAME = 'LAST MONTH' THEN CONVERT(DATE, DATEADD(D, -(DAY(GETDATE())), GETDATE()))
--		WHEN @TIMEFRAME = 'CURRENT MONTH' THEN CONVERT(DATE, EOMONTH(GETDATE()))

--		WHEN @TIMEFRAME = 'CURRENT YEAR' THEN CONVERT(DATE, DATEADD(YY, DATEDIFF(YY, 0, GETDATE()) + 1, -1))
		
--		WHEN @TIMEFRAME = 'CURRENT QUARTER' THEN CONVERT(DATE, DATEADD(DD, -1, DATEADD(QQ, DATEDIFF(QQ, 0, GETDATE()) + 1, 0)))

--	*/
--	WHEN @TIMEFRAME = 'LAST YEAR' THEN CONVERT(DATE, DATEADD(YEAR, DATEDIFF(YEAR, 0, GETDATE()), -1))
--	WHEN @TIMEFRAME = 'LAST QUARTER' THEN CONVERT(DATE, DATEADD(DD, -1, DATEADD(QQ, DATEDIFF(QQ, 0, GETDATE()), 0)))
--	ELSE @ENDDATE
--END;

--PRINT CAST(@STARTDATE AS DATE)
--PRINT CAST(@ENDDATE AS DATE)

--PRINT CAST(@CalcStartDate AS DATE)
--PRINT CAST(@CalcEndDate AS DATE)

-- datefirst
--SELECT @@DATEFIRST AS DateFirstSetting;



---- this week not prior!!!
--SELECT DATEADD(
--    DAY,
--    1 - DATEPART(WEEKDAY, CAST(GETDATE() AS date)),
--    CAST(GETDATE() AS date)
--) AS ThisWeekStartDate;

 --would you transform this vba from reporting services to sql server t-sql? It's rendering 8/24/2026
 --SET DATEFIRST 1;
 --x=DateAdd(DateInterval.Day, -6,DateAdd(DateInterval.Day, 1-Weekday(today),Today))
-- Transformed vba to sql for start date
SET DATEFIRST 1;
DECLARE @TEST_START DATE =
DATEADD(
    DAY,
    -7 - (DATEPART(WEEKDAY, CAST(GETDATE() AS date)) - 1),
    CAST(GETDATE() AS date)
) 
-- SELECT @TEST_START TEST_START;

-- prompt:
 --would you transform this vba from reporting services to sql server t-sql?
 --=DateAdd(DateInterval.Day, -0,DateAdd(DateInterval.Day, 1-Weekday(today),Today))
-- -- Transformed vba to sql for end date

SET DATEFIRST 1;

DECLARE @TEST_END date =
    DATEADD(
        DAY,
        -1,
        DATEADD(
            DAY,
            1 - DATEPART(WEEKDAY, CAST(GETDATE() AS date)),
            CAST(GETDATE() AS date)
        )
    );

--SELECT @TEST_END AS TEST_END;

-- 1 --------------
-- @STARTDATE =DateAdd(DateInterval.Day, -6,DateAdd(DateInterval.Day, 1-Weekday(today),Today))
-- @ENDDATE =DateAdd(DateInterval.Day, -0,DateAdd(DateInterval.Day, 1-Weekday(today),Today))
    DECLARE @OPS_COUNT FLOAT = 
	(SELECT COUNT(*)
	FROM [sql-lab-2].live.DBO.OPERATION O
	LEFT OUTER JOIN  [sql-lab-2].live.DBO.SHOP_RESOURCE_SITE SR
		ON SR.RESOURCE_ID = O.RESOURCE_ID
	WHERE O.CLOSE_DATE >= @STARTDATE
		AND O.CLOSE_DATE <= @ENDDATE
		AND SR.USER_5 IN (@FACILITY)
		-- AND SR.USER_8 IN (@DEPARTMENT)
    	                  AND O.[STATUS] != 'X'
	GROUP BY
	--SR.USER_8, 
	SR.USER_5
	)
--SELECT @OPS_COUNT AS OPS_COUNT
print Cast(@OPS_COUNT as NVARCHAR) + '<'

-- DEFECT COUNT IQM
-- ~221
 DECLARE @DEFECT_COUNT1 FLOAT =
	(SELECT COUNT(*) 
	FROM [sql-lab-2].live.DBO.OPERATION O
	INNER JOIN [sql-lab-2].live.DBO.SHOP_RESOURCE_SITE SR
		ON SR.RESOURCE_ID = O.RESOURCE_ID
	INNER JOIN 
        [sql-bi-1].datawarehouse.dbo.VQ_PRODUCTION_ORDER PO
		ON PO.[ALT_ID_2] = O.WORKORDER_BASE_ID
		AND PO.[ALT_ID_3] = O.WORKORDER_LOT_ID
		AND PO.[ALT_ID_4] = O.WORKORDER_SPLIT_ID
		AND PO.[ALT_ID_5] = O.WORKORDER_SUB_ID
		AND PO.[ALT_ID_1] = O.WORKORDER_TYPE
	INNER JOIN 
       [sql-bi-1].datawarehouse.dbo.VQ_OPERATION OI
		ON OI.[ID] = CAST(O.WORKORDER_TYPE AS NVARCHAR(1)) + '~' + CAST(O.WORKORDER_BASE_ID AS NVARCHAR(7)) + '~' 
			+ CAST(O.WORKORDER_LOT_ID AS NVARCHAR(1)) + '~' + CAST(O.WORKORDER_SPLIT_ID AS NVARCHAR(1)) + '~' 
			+ CAST(O.WORKORDER_SUB_ID AS NVARCHAR(1)) + '~' + CAST(O.SEQUENCE_NO AS NVARCHAR(5))
	INNER JOIN 
		[sql-bi-1].datawarehouse.dbo.VQ_NONCONFORMANCE NCM
		ON PO.RECORD_ID = NCM.PROD_ORDER_REC_ID
		AND OI.RECORD_ID = NCM.OPERATION_REC_ID
		INNER JOIN 
		[sql-bi-1].datawarehouse.dbo.VQ_PRODUCT P
		ON P.RECORD_ID = NCM.PRODUCT_REC_ID
	WHERE O.CLOSE_DATE >= @STARTDATE
		AND O.CLOSE_DATE <= @ENDDATE
		AND (NCM.SITE_ID = 'SK01' OR NCM.SITE_ID IS NULL)
		AND NCM.NCM_ID IS NOT NULL
		AND NCM.NCM_TYPE NOT IN ('OVERAGE')
		AND NCM.DISPOSITION_TYPE NOT IN ('NON-DISCREPANT', 'OVERAGE')
		AND SR.USER_6 != 'PENETRANT'
	--	AND SR.USER_8 IN (@DEPARTMENT)
		AND SR.USER_5 IN (@FACILITY)
  	                   AND O.[STATUS] != 'X'
	GROUP BY
	    -- SR.USER_8,
		SR.USER_5
	)
--SELECT ISNULL(@DEFECT_COUNT1, 0) AS DEFECT_COUNT1

-- Defect List iqm old -----------------------------------

SELECT 
      ISNULL(NCM.USER_DEFINED_4, NCM.USER_DEFINED_7) AS DEFECT
	, ISNULL(Sr.USER_8, '_Blank') AS DEPARTMENT   -- process
	, COUNT(*) AS [DEFECT_COUNT]
			--FROM OPERATION O
			--INNER JOIN SHOP_RESOURCE SR
			--	ON SR.ID = O.RESOURCE_ID
		INTO #DEFECT_IQM
	FROM [sql-lab-2].live.DBO.OPERATION O
	INNER JOIN [sql-lab-2].live.DBO.SHOP_RESOURCE_SITE SR
		ON SR.RESOURCE_ID = O.RESOURCE_ID
INNER JOIN 
[sql-bi-1].datawarehouse.dbo.VQ_PRODUCTION_ORDER PO
	ON PO.[ALT_ID_2] = O.WORKORDER_BASE_ID
	AND PO.[ALT_ID_3] = O.WORKORDER_LOT_ID
	AND PO.[ALT_ID_4] = O.WORKORDER_SPLIT_ID
	AND PO.[ALT_ID_5] = O.WORKORDER_SUB_ID
	AND PO.[ALT_ID_1] = O.WORKORDER_TYPE
INNER JOIN 
[SQL-BI-1].datawarehouse.dbo.VQ_OPERATION OI
	ON OI.[ID] = CAST(O.WORKORDER_TYPE AS NVARCHAR(1)) + '~' + CAST(O.WORKORDER_BASE_ID AS NVARCHAR(7)) + '~' 
		+ CAST(O.WORKORDER_LOT_ID AS NVARCHAR(1)) + '~' + CAST(O.WORKORDER_SPLIT_ID AS NVARCHAR(1)) + '~' 
		+ CAST(O.WORKORDER_SUB_ID AS NVARCHAR(1)) + '~' + CAST(O.SEQUENCE_NO AS NVARCHAR(5))
INNER JOIN 
[sql-bi-1].datawarehouse.dbo.VQ_NONCONFORMANCE NCM
	ON PO.RECORD_ID = NCM.PROD_ORDER_REC_ID
	AND OI.RECORD_ID = NCM.OPERATION_REC_ID
INNER JOIN 
[sql-bi-1].datawarehouse.dbo.VQ_PRODUCT P
	ON P.RECORD_ID = NCM.PRODUCT_REC_ID
WHERE O.CLOSE_DATE >= @STARTDATE
	AND O.CLOSE_DATE <= @ENDDATE
	AND (NCM.SITE_ID = 'SK01' OR NCM.SITE_ID IS NULL)
	AND NCM.NCM_ID IS NOT NULL
	AND NCM.NCM_TYPE NOT IN ('OVERAGE')
	AND NCM.DISPOSITION_TYPE NOT IN ('NON-DISCREPANT', 'OVERAGE')
	AND SR.USER_6 != 'PENETRANT'
--	AND SR.USER_8 IN (@DEPARTMENT)
	AND SR.USER_5 IN (@FACILITY)
	AND O.[STATUS] != 'X'
GROUP BY SR.USER_8
	, SR.USER_5
	, ISNULL(NCM.USER_DEFINED_4, NCM.USER_DEFINED_7)
;

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

    -- Resource
  ,SR.DESCRIPTION AS RESOURCE_DESCRIPTION
  ,SR.USER_5 AS Facility  -- Plant 1 or 2 e.g. AP1, AP2 Auburn Plant 1, Auburn Plant 2
  ,SR.USER_6 AS Departmentx  -- Department responsible for the resource, e.g. Receiving, CNC, ASSEMBLY
  ,SR.USER_7 AS SubProcess  -- SubProcess associated with the resource
  ,SR.USER_8 AS Process  -- Process associated with the resource, aka Reporting_Group
  ,SR.USER_8 AS Department   --  aka Reporting_Group
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
	--and (a.part_id = @Part_ID or @Part_ID IS NULL )
	AND (o.RESOURCE_ID = @resource_id OR @resource_id IS NULL)
	AND isnull(SR.USER_6,'') != 'PENETRANT'
--	AND (SR.USER_8 IN (@DEPARTMENT) ) -- process e.g.cnc
	AND (SR.USER_5 IN (@FACILITY) )   -- plant e.g. plant 1
	and O.CLOSE_DATE >= @STARTDATE
	AND O.CLOSE_DATE <= @ENDDATE
)
select 
	'ncm-new-defect-count' note
	,isnull(n.DEFECT_ID, '_blank') DEFECT_ID
	, n.[NCM_NUMBER]

	,n.PROCESS_ID  -- e.g. CNC
	,n.SUBPROCESS_ID  -- e.g. 5-Axis, 4-Axis

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

    -- Resource
  ,r.RESOURCE_DESCRIPTION
  ,r.Facility  -- Plant 1 or 2 e.g. AP1, AP2 Auburn Plant 1, Auburn Plant 2
  ,r.Departmentx -- Department responsible for the resource, e.g. Receiving, CNC, ASSEMBLY
  ,r.SubProcess  -- SubProcess associated with the resource
  ,r.Process    -- Process associated with the resource, aka Reporting_Group
  ,r.Department -- Process associated with the resource, aka Reporting_Group
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

 DECLARE @DEFECT_COUNT2 FLOAT =
	(SELECT COUNT(*) FROM #DEFECT_NCM_NEW);

--SELECT @DEFECT_COUNT2 DEFECT_COUNT2;

-- Defect List NCM NEW + iqm------add dept ~22
select  Department, c.DEFECT, SUM(DEFECT_COUNT) DEFECT_COUNT
   INTO #DEFECT_LIST
from (
SELECT
   isnull(DEFECT_ID, '_blank' ) DEFECT
   ,Department
   ,COUNT(*) DEFECT_COUNT
FROM #DEFECT_NCM_NEW
GROUP BY isnull(DEFECT_ID, '_blank' ), Department
UNION ALL
select 
    DEFECT, Department
   ,DEFECT_COUNT
from #DEFECT_IQM
) c
group by 
 DEFECT
 ,Department
;

-- DEFECT_COUNT
DECLARE @DEFECT_COUNT FLOAT =
	(SELECT ISNULL(@DEFECT_COUNT1,0) + ISNULL(@DEFECT_COUNT2,0));

-- ~22
--SELECT @DEFECT_COUNT DEFECT_COUNT;

SELECT * FROM #DEFECT_LIST;

---- PERCENTAGE
--select  1.0 - CAST(
--isnull(@DEFECT_COUNT / nullif(@OPS_COUNT,0),0) 
--AS DECIMAL (15,4) ) as PERCENTAGE