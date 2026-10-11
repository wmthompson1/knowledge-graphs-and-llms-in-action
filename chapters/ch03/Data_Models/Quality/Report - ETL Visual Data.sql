
/**********************************************************************************************
Description:
Sample:
Date      Modified By      Change Description
---------- ------------------ ------------------------------------------------------------
**********************************************************************************************/
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET DEADLOCK_PRIORITY LOW
IF OBJECT_ID('tempdb..#Results') IS NOT NULL DROP TABLE #Results

-- update to run at lab 2
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET DEADLOCK_PRIORITY LOW

IF OBJECT_ID('tempdb..#Results') IS NOT NULL DROP TABLE #Results
IF OBJECT_ID('tempdb..#NCM') IS NOT NULL DROP TABLE #NCM
IF OBJECT_ID('tempdb..#FACILITY') IS NOT NULL DROP TABLE #FACILITY
-- #DEPARTMENT
IF OBJECT_ID('tempdb..#DEPARTMENT') IS NOT NULL DROP TABLE #DEPARTMENT
IF OBJECT_ID('tempdb..#IQM_PROCESS') IS NOT NULL DROP TABLE #IQM_PROCESS

IF OBJECT_ID('tempdb..#temp1') IS NOT NULL DROP TABLE #temp1
IF OBJECT_ID('tempdb..#temp2') IS NOT NULL DROP TABLE #temp2

declare @STARTDATE date = DATEADD(WEEK, DATEDIFF(WEEK, 7, GETDATE()), 0);
declare @ENDDATE date = DATEADD(WEEK, DATEDIFF(WEEK, 7, GETDATE()), 6);
-- in test, just use FIRST_OF_PRIOR
declare @timeframe nvarchar(25) = 'FIRST_OF_PRIOR'; -- -- 'OTHER    ';  -- --'LAST QUARTER';  -- -- 'LAST YEAR'; -- -- 'LAST WEEK'; 
declare @LISTTYPE nvarchar(25) = 'DEFECTS';
-- in test
declare @DEPARTMENT nvarchar(50) = 'ALL'; -- --  'cnc';
declare @FACILITY nvarchar(50) = 'ALL'; -- -- 'ap2';

DECLARE @IQM_PROCESS NVARCHAR(50) = 'ALL';
DECLARE @IQM_DEFECT NVARCHAR(50) = 'ALL';

-- DECLARE @Tester int
declare @part_id nvarchar(250) = NULL; -- --  '313Z7430-504';  -- '313Z7430-504' '70750B-071-MIL-NG';
-- Set @Tester = 0
DECLARE @workorder_base_id nvarchar(30) = NULL; -- -- 
DECLARE @NCM_NUMBER NVARCHAR(30) = NULL; -- '50668';


-- Pre-calculate dates
DECLARE @CalcStartDate DATE, @CalcEndDate DATE;
SELECT @CalcStartDate = CASE
    WHEN @TIMEFRAME = 'LAST WEEK' THEN DATEADD(WEEK, DATEDIFF(WEEK, 7, GETDATE()), 0)

    WHEN @TIMEFRAME = 'OTHER' THEN @STARTDATE
		/*  */
    WHEN @TIMEFRAME = 'CURRENT WEEK' THEN CONVERT(DATE, DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE()), 0))
    WHEN @TIMEFRAME = 'LAST MONTH' THEN CONVERT(DATE, DATEADD(MM, DATEDIFF(MM, 0, GETDATE()) - 1, 0))
    WHEN @TIMEFRAME = 'CURRENT MONTH' THEN CONVERT(DATE, DATEADD(D, -(DAY(GETDATE()-1)), GETDATE()))
    WHEN @TIMEFRAME = 'CURRENT QUARTER' THEN CONVERT(DATE, DATEADD(QQ, DATEDIFF(QQ, 0, GETDATE()), 0))

	WHEN @TIMEFRAME = 'LAST YEAR' THEN CONVERT(DATE, DATEADD(YEAR, DATEDIFF(YEAR, 0, GETDATE()) - 1, 0))
	WHEN @TIMEFRAME = 'CURRENT YEAR' THEN CONVERT(DATE, DATEADD(YY, DATEDIFF(YY, 0, GETDATE()), 0)) 
	WHEN @TIMEFRAME = 'LAST QUARTER' THEN CONVERT(DATE, DATEADD(QUARTER, DATEDIFF(QUARTER, 0 , GETDATE()) - 1, 0))
    WHEN @TIMEFRAME = 'FIRST_OF_PRIOR' THEN DATEFROMPARTS(YEAR(GETDATE()) - 1, 1, 1)
	ELSE @STARTDATE
END,
@CalcEndDate = CASE
    WHEN @TIMEFRAME = 'LAST WEEK' THEN DATEADD(WEEK, DATEDIFF(WEEK, 7, GETDATE()), 6)
    WHEN @TIMEFRAME = 'OTHER' THEN @ENDDATE
	/* */
    WHEN @TIMEFRAME = 'CURRENT WEEK' THEN CONVERT(DATE, DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE()), 6))
    WHEN @TIMEFRAME = 'LAST MONTH' THEN CONVERT(DATE, DATEADD(D, -(DAY(GETDATE())), GETDATE()))
    WHEN @TIMEFRAME = 'CURRENT MONTH' THEN CONVERT(DATE, EOMONTH(GETDATE()))
    WHEN @TIMEFRAME = 'CURRENT QUARTER' THEN CONVERT(DATE, DATEADD(DD, -1, DATEADD(QQ, DATEDIFF(QQ, 0, GETDATE()) + 1, 0)))

	WHEN @TIMEFRAME = 'LAST YEAR' THEN CONVERT(DATE, DATEADD(YEAR, DATEDIFF(YEAR, 0, GETDATE()), -1))
	WHEN @TIMEFRAME = 'CURRENT YEAR' THEN CONVERT(DATE, DATEADD(YY, DATEDIFF(YY, 0, GETDATE()) + 1, -1))
	WHEN @TIMEFRAME = 'LAST QUARTER' THEN CONVERT(DATE, DATEADD(DD, -1, DATEADD(QQ, DATEDIFF(QQ, 0, GETDATE()), 0)))
    WHEN @TIMEFRAME = 'FIRST_OF_PRIOR' THEN CAST(GETDATE() AS DATE)
	ELSE @ENDDATE
END;

set @STARTDATE = @CalcStartDate;
set @ENDDATE = @CalcEndDate;

PRINT CAST(@STARTDATE AS DATE)
PRINT CAST(@ENDDATE AS DATE);

PRINT CAST(@CalcStartDate AS DATE);
PRINT CAST(@CalcEndDate AS DATE);

-- 0 the grain of the report will be forced to work order, sequence number level
-- 1 operations from iqm system inner join with shop resource and nonconformance data
-- 2 operations from sql-lab-2/ncm system inner join with shop resource and nonconformance data
-- 3 operations that do not include 1 (iqm system operations with defect) AND 
--              donm't include 2 (sql-lab-2/ncm system operations with defect)
-- 1 will have MFG_% OR FIN_%` = 0 depending on the BUSINESSUNIT. Total_% will reflect the sum of MFG_% and FIN_%
-- 2 will have MFG_% OR FIN_%` = 0 depending on the BUSINESSUNIT. Total_% will reflect the sum of MFG_% and FIN_%
-- 3 will have MFG_% OR FIN_%` = 1 depending on the BUSINESSUNIT. Total_% will be 1, the sum of MFG_% and FIN_%
-- The business unit is determined based on the USER_1 field from the shop resource. 
-- WHEN SR.USER_1 = 'A' THEN 'FIN' WHEN SR.USER_1 = 'M' THEN 'MFG'
            
WITH defects as(
SELECT 'IQM' AS SOURCE,
       O.WORKORDER_BASE_ID
       , O.WORKORDER_LOT_ID
       , O.WORKORDER_SPLIT_ID
       , O.WORKORDER_SUB_ID
       , O.WORKORDER_TYPE
       , O.SEQUENCE_NO
       --, O.RESOURCE_ID
       --, O.OPERATION_TYPE
       , O.CLOSE_DATE
       , SR.USER_1 AS BUSINESSUNIT
       , SR.USER_8 AS DEPARTMENT
       , SR.USER_7 AS SUBDEPT
       , SR.USER_4 AS SUPERVISOR
       , SR.USER_5 AS FACILITY
       , n.NCM_ID
	   , n.DISPOSITION_TYPE
       --, n.DISPOSITION_TYPE
	   --, IIF((sr.user_1 = 'M' and n.NCM_ID is null),1,IIF((sr.user_1 = 'M' and n.NCM_ID is not null),0,Null)) as [MFG_%]
        , IIF(sr.user_1 = 'M' ,0,Null) as [MFG_%]
       , IIF((sr.user_1 = 'A' or sr.user_1 = 'B') ,0,Null) as [FIN_%]
	   , IIF(n.ncm_ID is null,1,0) as [Total_%]
       , DATEPART(Week,o.CLOSE_DATE ) as Week_Num
       --, DATEPART(YYYY, O.CLOSE_DATE) AS [YEAR]
       --, DATEPART(MM, O.CLOSE_DATE) AS [MONTH]
       --, DATEPART(QQ, O.CLOSE_DATE) AS [QUARTER]
       --, DATEPART(WW, O.CLOSE_DATE) AS [WEEK]
	   , Format(O.Close_Date,'MM-yyyy') as 'Report Date'
       , CASE
              WHEN SR.USER_1 = 'A' THEN 'FIN'
              WHEN SR.USER_1 = 'M' THEN 'MFG'
              WHEN SR.USER_1 = 'O' THEN 'OUTREACH'
              WHEN SR.USER_1 = 'B' THEN 'FIN'
              WHEN SR.USER_1 = 'C' THEN 'CLOSED'
       END AS BUSUNIT
FROM [sql-lab-2].Live.dbo.OPERATION O (NOLOCK)
INNER JOIN [sql-lab-2].Live.dbo.SHOP_RESOURCE_SITE SR
       ON O.RESOURCE_ID = SR.RESOURCE_ID
INNER JOIN [SQL-BI-1].Datawarehouse.dbo.VQ_OPERATION VQO
       On VQO.ID = o.workorder_type+'~'+o.workorder_base_id+'~'+o.workorder_lot_id+'~'+o.workorder_split_id+'~'+cast(o.workorder_sub_id as varchar)+'~'+cast(o.sequence_no as varchar)
INNER join [SQL-BI-1].Datawarehouse.dbo.vq_nonconformance n on vqo.record_id = n.operation_rec_id

WHERE (1=1) 

AND (O.CLOSE_DATE >= @startdate)
--AND O.CLOSE_DATE IS NOT NULL)
AND (O.CLOSE_DATE <= @enddate   )

AND O.[STATUS] = 'C'
and sr.USER_2 <> 'Penetrant'

UNION ALL


-- new NCM system sql-lab-2/ncm
SELECT 
       'NCM' AS SOURCE,
        r.WORKORDER_BASE_ID
       , r.WORKORDER_LOT_ID
       , r.WORKORDER_SPLIT_ID
       , r.WORKORDER_SUB_ID
       , r.WORKORDER_TYPE
       , r.SEQUENCE_NO
       --, O.RESOURCE_ID
       --, O.OPERATION_TYPE
       , r.CLOSE_DATE
       , r.USER_1 AS BUSINESSUNIT
       , r.USER_8 AS DEPARTMENT
       , r.USER_7 AS SUBDEPT
       , r.USER_4 AS SUPERVISOR
       , r.USER_5 AS FACILITY
       , n.ncm_number AS NCM_ID
	   , n.DISPOSITION_TYPE_code AS DISPOSITION_TYPE
       --, n.DISPOSITION_TYPE
       , IIF(r.user_1 = 'M' ,0,Null) as [MFG_%]
       , IIF((r.user_1 = 'A' or r.user_1 = 'B') ,0,Null) as [FIN_%]
	   , IIF(n.ncm_number is null,1,0) as [Total_%]
       , DATEPART(Week,r.CLOSE_DATE ) as Week_Num

	   , Format(r.Close_Date,'MM-yyyy') as 'Report Date'
       , r.BUSUNIT

from 
(
 -- route
 select
    'work order operations' note
    -- part
    , a.part_id
    , P.STOCK_UM
    -- composite
    , O.WORKORDER_BASE_ID
    , O.WORKORDER_LOT_ID
    , O.WORKORDER_SPLIT_ID
    , O.WORKORDER_SUB_ID
    , O.WORKORDER_TYPE
    -- operation routing
    , o.SEQUENCE_NO
    , o.RESOURCE_ID
    -- work order
    , a.status workorder_status
    , a.base_id
    , a.lot_id
    , a.split_id
    , a.sub_id
    , cast(o.CLOSE_DATE as date) CLOSE_DATE 
    , o.STATUS as OPERATION_STATUS
    -- Resource
    , SR.DESCRIPTION AS RESOURCE_DESCRIPTION
    , SR.USER_5 AS Facility  -- Plant 1 or 2 e.g. AP1, AP2 Auburn Plant 1, Auburn Plant 2
    , SR.USER_6 AS Department  -- Department responsible for the resource, e.g. Receiving, CNC, ASSEMBLY
    , SR.USER_7 AS SubProcess  -- SubProcess associated with the resource
    , SR.USER_8 AS Process  -- Process associated with the resource, aka Reporting_Group
    , SR.USER_1 AS USER_1
    , SR.USER_2 AS USER_2
    , SR.USER_8 AS USER_8
    , SR.USER_7 AS USER_7
    , SR.USER_4 AS USER_4
    , SR.USER_5 AS USER_5
	, CASE
		WHEN @TIMEFRAME IN ('LAST WEEK', 'CURRENT WEEK') THEN DATENAME(WEEKDAY, O.CLOSE_DATE)
    WHEN @TIMEFRAME IN ('LAST MONTH', 'CURRENT MONTH', 'OTHER') THEN CONVERT(VARCHAR(15), DATEADD(WEEK, DATEDIFF(WEEK, CONVERT(DATE, '19000101'), O.CLOSE_DATE), CONVERT(DATE, '18991231')), 101)
		ELSE DATENAME(MONTH, O.CLOSE_DATE)
	END AS [TIMEFRAME]
    , CASE
              WHEN SR.USER_1 = 'A' THEN 'FIN'
              WHEN SR.USER_1 = 'M' THEN 'MFG'
              WHEN SR.USER_1 = 'O' THEN 'OUTREACH'
              WHEN SR.USER_1 = 'B' THEN 'FIN'
              WHEN SR.USER_1 = 'C' THEN 'CLOSED'
       END AS BUSUNIT
  FROM [sql-lab-2].Live.dbo.WORK_ORDER a
  INNER JOIN [sql-lab-2].Live.dbo.OPERATION o
  on o.WORKORDER_BASE_ID=a.BASE_ID 
  and o.WORKORDER_LOT_ID=a.LOT_ID 
  and o.WORKORDER_SPLIT_ID = a.SPLIT_ID
  and o.WORKORDER_SUB_ID = a.SUB_ID
  INNER JOIN [sql-lab-2].Live.dbo.SHOP_RESOURCE SR
		ON SR.ID = O.RESOURCE_ID
  Inner Join [sql-lab-2].Live.dbo.PART P  with (nolock) on a.PART_ID = P.ID
where 1=1
	AND a.Type = 'w'
	AND (a.base_id = @workorder_base_id OR @workorder_base_id IS NULL)
	and o.STATUS = ('C')
	and cast(o.CLOSE_DATE as date) >= @STARTDATE
	AND cast(o.CLOSE_DATE as date) <= @ENDDATE

)
AS r
join [sql-lab-2].ncm.dbo.NONCONFORMANCE n
  on r.BASE_ID=n.BASE_ID 
  and r.LOT_ID=n.LOT_ID and
    r.SPLIT_ID = n.SPLIT_ID
    and r.SUB_ID = n.SUB_ID
	and r.SEQUENCE_NO = n.operation_id  -- ncm_sequence
where 1=1
AND r.operation_status = 'C'
and r.USER_2 <> 'Penetrant'
------ 
	
-- and (n.NCM_NUMBER = @NCM_NUMBER or @NCM_NUMBER is null)
--order by n.ncm_date, r.BASE_ID, r.LOT_ID

)
-- test - verify total_% is 0
-- PASS
, nonDefectiveops as (
    SELECT 'IQM' AS SOURCE,
       O.WORKORDER_BASE_ID
       , O.WORKORDER_LOT_ID
       , O.WORKORDER_SPLIT_ID
       , O.WORKORDER_SUB_ID
       , O.WORKORDER_TYPE
       , O.SEQUENCE_NO
       --, O.RESOURCE_ID
       --, O.OPERATION_TYPE
       , O.CLOSE_DATE
       , SR.USER_1 AS BUSINESSUNIT
       , SR.USER_8 AS DEPARTMENT
       , SR.USER_7 AS SUBDEPT
       , SR.USER_4 AS SUPERVISOR
       , SR.USER_5 AS FACILITY
       , null as NCM_ID
	   , NULL AS DISPOSITION_TYPE
       --, n.DISPOSITION_TYPE
	   , IIF((sr.user_1 = 'M' ),1,NULL) as [MFG_%]
       , IIF(((sr.user_1 = 'A' or sr.user_1 = 'B') ),1,NULL) as [FIN_%]
	   , 1 as [Total_%]
       , DATEPART(Week,o.CLOSE_DATE ) as Week_Num
       --, DATEPART(YYYY, O.CLOSE_DATE) AS [YEAR]
       --, DATEPART(MM, O.CLOSE_DATE) AS [MONTH]
       --, DATEPART(QQ, O.CLOSE_DATE) AS [QUARTER]
       --, DATEPART(WW, O.CLOSE_DATE) AS [WEEK]
	   , Format(O.Close_Date,'MM-yyyy') as 'Report Date'
       , CASE
              WHEN SR.USER_1 = 'A' THEN 'FIN'
              WHEN SR.USER_1 = 'M' THEN 'MFG'
              WHEN SR.USER_1 = 'O' THEN 'OUTREACH'
              WHEN SR.USER_1 = 'B' THEN 'FIN'
              WHEN SR.USER_1 = 'C' THEN 'CLOSED'
       END AS BUSUNIT
FROM [sql-lab-2].Live.dbo.OPERATION O (NOLOCK)
INNER JOIN [sql-lab-2].Live.dbo.SHOP_RESOURCE_SITE SR
       ON O.RESOURCE_ID = SR.RESOURCE_ID
WHERE (1=1) 
and not exists (
    select 1
    from defects d
    where d.WORKORDER_BASE_ID = O.WORKORDER_BASE_ID
      and d.WORKORDER_LOT_ID = O.WORKORDER_LOT_ID
      and d.WORKORDER_SPLIT_ID = O.WORKORDER_SPLIT_ID
      and d.WORKORDER_SUB_ID = O.WORKORDER_SUB_ID
      and d.SEQUENCE_NO = O.SEQUENCE_NO
)

AND (O.CLOSE_DATE >= @startdate)
--AND O.CLOSE_DATE IS NOT NULL)
AND (O.CLOSE_DATE <= @enddate   )

AND O.[STATUS] = 'C'
and sr.USER_2 <> 'Penetrant'

)
select *
from nonDefectiveops
union all 
select *
from defects