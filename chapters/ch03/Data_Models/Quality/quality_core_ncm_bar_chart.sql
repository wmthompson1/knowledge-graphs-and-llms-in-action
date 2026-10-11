-- USE LIVE --
-- GO

-- Documentation\Schema\Data_Models\Quality\quality_core_ncm.sql
/**********************************************************************************************

Description:  quality_core_ncm.sql
Note:   
run at lab 2

Date        Modified By         Change Description
----------  ------------------  ------------------------------------------------------------
08/31/26    William Thompson    Created.


**********************************************************************************************/

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
IF OBJECT_ID('tempdb..#temp3') IS NOT NULL DROP TABLE #temp3
IF OBJECT_ID('tempdb..#temp4') IS NOT NULL DROP TABLE #temp4
IF OBJECT_ID('tempdb..#temp5') IS NOT NULL DROP TABLE #temp5
-- 

declare @STARTDATE date;  --  = DATEADD(WEEK, DATEDIFF(WEEK, 7, GETDATE()), 0)
declare @ENDDATE date; -- = DATEADD(WEEK, DATEDIFF(WEEK, 7, GETDATE()), 6)
-- --  in test
declare @timeframe nvarchar(25) = 'CURRENT YEAR';  -- --'LAST QUARTER';  -- -- 'LAST YEAR'; -- -- 'LAST WEEK'; 
declare @LISTTYPE nvarchar(25) = 'DEFECTS';
-- --
-- in test
declare @DEPARTMENT nvarchar(50) = 'cnc';
declare @FACILITY nvarchar(50) = 'ap2';

-- --  xxxxx
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
    -- ... add other cases
		/*



	*/
    	WHEN @TIMEFRAME = 'CURRENT WEEK' THEN CONVERT(DATE, DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE()), 0))
		WHEN @TIMEFRAME = 'LAST MONTH' THEN CONVERT(DATE, DATEADD(MM, DATEDIFF(MM, 0, GETDATE()) - 1, 0))
		WHEN @TIMEFRAME = 'CURRENT MONTH' THEN CONVERT(DATE, DATEADD(D, -(DAY(GETDATE()-1)), GETDATE()))
		WHEN @TIMEFRAME = 'CURRENT QUARTER' THEN CONVERT(DATE, DATEADD(QQ, DATEDIFF(QQ, 0, GETDATE()), 0))
	WHEN @TIMEFRAME = 'LAST YEAR' THEN CONVERT(DATE, DATEADD(YEAR, DATEDIFF(YEAR, 0, GETDATE()) - 1, 0))
	WHEN @TIMEFRAME = 'CURRENT YEAR' THEN CONVERT(DATE, DATEADD(YY, DATEDIFF(YY, 0, GETDATE()), 0)) 
	WHEN @TIMEFRAME = 'LAST QUARTER' THEN CONVERT(DATE, DATEADD(QUARTER, DATEDIFF(QUARTER, 0 , GETDATE()) - 1, 0))
	ELSE @STARTDATE
END,
@CalcEndDate = CASE
    WHEN @TIMEFRAME = 'LAST WEEK' THEN DATEADD(WEEK, DATEDIFF(WEEK, 7, GETDATE()), 6)
    WHEN @TIMEFRAME = 'OTHER' THEN @ENDDATE
    -- ... add other cases
	/*



	*/

		WHEN @TIMEFRAME = 'CURRENT WEEK' THEN CONVERT(DATE, DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE()), 6))
		WHEN @TIMEFRAME = 'LAST MONTH' THEN CONVERT(DATE, DATEADD(D, -(DAY(GETDATE())), GETDATE()))
		WHEN @TIMEFRAME = 'CURRENT MONTH' THEN CONVERT(DATE, EOMONTH(GETDATE()))
		WHEN @TIMEFRAME = 'CURRENT QUARTER' THEN CONVERT(DATE, DATEADD(DD, -1, DATEADD(QQ, DATEDIFF(QQ, 0, GETDATE()) + 1, 0)))

	WHEN @TIMEFRAME = 'LAST YEAR' THEN CONVERT(DATE, DATEADD(YEAR, DATEDIFF(YEAR, 0, GETDATE()), -1))
	WHEN @TIMEFRAME = 'CURRENT YEAR' THEN CONVERT(DATE, DATEADD(YY, DATEDIFF(YY, 0, GETDATE()) + 1, -1))
	WHEN @TIMEFRAME = 'LAST QUARTER' THEN CONVERT(DATE, DATEADD(DD, -1, DATEADD(QQ, DATEDIFF(QQ, 0, GETDATE()), 0)))
	ELSE @ENDDATE
END;

set @STARTDATE = @CalcStartDate;
set @ENDDATE = @CalcEndDate;

PRINT CAST(@STARTDATE AS DATE)
PRINT CAST(@ENDDATE AS DATE);

PRINT CAST(@CalcStartDate AS DATE);
PRINT CAST(@CalcEndDate AS DATE);

-- new ncm system
With route as (
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

  -- operation routing
  , o.SEQUENCE_NO
  , o.RESOURCE_ID
  , o.OPERATION_TYPE

  -- work order
  , a.status workorder_status
  , a.base_id
  , a.lot_id
  , a.split_id
  , a.sub_id

  , cast(o.CLOSE_DATE as date) CLOSE_DATE 
  , o.STATUS as OPERATION_STATUS

    -- Resource
  ,SR.DESCRIPTION AS RESOURCE_DESCRIPTION
  ,SR.USER_5 AS Facility  -- Plant 1 or 2 e.g. AP1, AP2 Auburn Plant 1, Auburn Plant 2
  ,SR.USER_6 AS Department  -- Department responsible for the resource, e.g. Receiving, CNC, ASSEMBLY
  ,SR.USER_7 AS SubProcess  -- SubProcess associated with the resource
  ,SR.USER_8 AS Process  -- Process associated with the resource, aka Reporting_Group
-- chart

	, CASE
		WHEN @TIMEFRAME IN ('LAST WEEK', 'CURRENT WEEK') THEN DATENAME(WEEKDAY, O.CLOSE_DATE)
    WHEN @TIMEFRAME IN ('LAST MONTH', 'CURRENT MONTH', 'OTHER') THEN CONVERT(VARCHAR(15), DATEADD(WEEK, DATEDIFF(WEEK, CONVERT(DATE, '19000101'), O.CLOSE_DATE), CONVERT(DATE, '18991231')), 101)
		ELSE DATENAME(MONTH, O.CLOSE_DATE)
	END AS [TIMEFRAME]
	, CASE
		WHEN @TIMEFRAME IN ('LAST WEEK', 'CURRENT WEEK') THEN CONVERT(NVARCHAR(15), O.CLOSE_DATE, 101)
		WHEN @TIMEFRAME IN ('LAST MONTH', 'CURRENT MONTH', 'OTHER') THEN ''
		ELSE CONVERT(NVARCHAR(15), YEAR(O.CLOSE_DATE))
	END AS [LABEL]
	, CASE
    WHEN @TIMEFRAME IN ('LAST WEEK', 'CURRENT WEEK') THEN DATEPART(DD, O.CLOSE_DATE)
		WHEN @TIMEFRAME IN ('LAST MONTH', 'CURRENT MONTH', 'OTHER') 
        THEN DATEPART(WW, DATEADD(WEEK, DATEDIFF(WEEK, CONVERT(DATE, '19000101'), O.CLOSE_DATE), CONVERT(DATE, '18991231')))
		ELSE DATEPART(MM, O.CLOSE_DATE)
	END [CHARTSORT]


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
	and o.STATUS not in ('X')
	--and a.STATUS in ('R', 'E', 'H', 'S', 'P', 'F','C')  -- Released, Enroute, Hold, Started, Partially Complete, Finished,Closed
	--and (a.part_id = @Part_ID or @Part_ID IS NULL )
	AND isnull(SR.USER_6,'') != 'PENETRANT'
	AND (SR.USER_8 IN (@DEPARTMENT) OR @DEPARTMENT = 'ALL') -- process e.g.cnc
	AND (SR.USER_5 IN (@FACILITY) OR @FACILITY = 'ALL')   -- plant e.g. plant 1
	and cast(o.CLOSE_DATE as date) >= @STARTDATE
	AND cast(o.CLOSE_DATE as date) <= @ENDDATE
)
select 
          r.WORKORDER_BASE_ID
        , r.WORKORDER_LOT_ID
        , r.WORKORDER_SPLIT_ID
        , r.WORKORDER_SUB_ID
        , r.SEQUENCE_NO

        , r.RESOURCE_ID
        , r.OPERATION_TYPE
        , r.CLOSE_DATE 
        , r.Facility  -- Plant 1 or 2 e.g. AP1, AP2 Auburn Plant 1, Auburn Plant 2
        , r.Department  -- Department responsible for the resource, e.g. Receiving, CNC, ASSEMBLY

	, CASE
		WHEN @TIMEFRAME IN ('LAST WEEK', 'CURRENT WEEK') THEN DATENAME(WEEKDAY, r.CLOSE_DATE)
		WHEN @TIMEFRAME IN ('LAST MONTH', 'CURRENT MONTH', 'OTHER') THEN CONVERT(VARCHAR(15), 
    DATEADD(WEEK, DATEDIFF(WEEK, CONVERT(DATE, '19000101'), r.CLOSE_DATE), CONVERT(DATE, '18991231')), 101)
		ELSE DATENAME(MONTH, r.CLOSE_DATE)
	END AS [TIMEFRAME]
	, CASE
		WHEN @TIMEFRAME IN ('LAST WEEK', 'CURRENT WEEK') THEN CONVERT(NVARCHAR(15), r.CLOSE_DATE, 101)
		WHEN @TIMEFRAME IN ('LAST MONTH', 'CURRENT MONTH', 'OTHER') THEN ''
		ELSE CONVERT(NVARCHAR(15), YEAR(r.CLOSE_DATE))
	END AS [LABEL]
	, CASE
    WHEN @TIMEFRAME IN ('LAST WEEK', 'CURRENT WEEK') THEN DATEPART(DD, r.CLOSE_DATE)
		WHEN @TIMEFRAME IN ('LAST MONTH', 'CURRENT MONTH', 'OTHER') 
        THEN DATEPART(WW, DATEADD(WEEK, DATEDIFF(WEEK, CONVERT(DATE, '19000101'), r.CLOSE_DATE), CONVERT(DATE, '18991231')))
		ELSE DATEPART(MM, r.CLOSE_DATE)
	END [CHARTSORT]

	, @CalcStartDate AS STARTDATE
	, @CalcEndDate AS [ENDDATE]
    , n.NCM_NUMBER as NCM_ID -- -- NCM.NCM_ID
    , n.[NCM_DATE]
	
	, IIF(ISNULL( n.NCM_NUMBER, '_BLANK') = '_BLANK', NULL, COALESCE(n.PROCESS_ID, '_BLANK')) AS [IQM_PROCESS]
	, IIF(ISNULL( n.NCM_NUMBER, '_BLANK') = '_BLANK', NULL, COALESCE(n.SUBPROCESS_ID, '_BLANK')) AS [IQM_SUBPROCESS]
	, IIF(ISNULL( n.NCM_NUMBER, '_BLANK') = '_BLANK', NULL, COALESCE(n.DEFECT_ID, '_BLANK')) AS [IQM_DEFECT]
	, N.DISPOSITION_TYPE_code AS DISPOSITION_TYPE
	, N.NCM_TYPE_code AS NCM_TYPE


from route r
join NCM.dbo.NONCONFORMANCE n
  on r.BASE_ID=n.BASE_ID 
  and r.LOT_ID=n.LOT_ID and
    r.SPLIT_ID = n.SPLIT_ID
    and r.SUB_ID = n.SUB_ID
	and r.SEQUENCE_NO = n.operation_id  -- ncm_sequence
where 1=1
and n.NCM_NUMBER  IS NOT NULL		
-- and n.ncm_type_code NOT IN ('OVERAGE')		
-- and n.DISPOSITION_TYPE_CODE NOT IN ('NON-DISCREPANT', 'OVERAGE')		
	
-- and r.operation_status  != 'X'	
-- and (n.NCM_NUMBER = @NCM_NUMBER or @NCM_NUMBER is null)


order by n.ncm_date, r.BASE_ID, r.LOT_ID