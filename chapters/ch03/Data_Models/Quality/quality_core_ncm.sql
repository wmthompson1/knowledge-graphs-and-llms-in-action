USE LIVE --
GO

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

declare @STARTDATE date = DATEADD(WEEK, DATEDIFF(WEEK, 7, GETDATE()), 0);
declare @ENDDATE date = DATEADD(WEEK, DATEDIFF(WEEK, 7, GETDATE()), 6);
-- in test
declare @timeframe nvarchar(25) = 'CURRENT YEAR';  -- --'LAST QUARTER';  -- -- 'LAST YEAR'; -- -- 'LAST WEEK'; 
declare @LISTTYPE nvarchar(25) = 'DEFECTS';
-- 
-- in test
declare @DEPARTMENT nvarchar(50) = 'cnc';
declare @FACILITY nvarchar(50) = 'ap2';

-- xxxxx
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
		WHEN @TIMEFRAME = 'CURRENT WEEK' THEN CONVERT(DATE, DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE()), 0))
		WHEN @TIMEFRAME = 'LAST MONTH' THEN CONVERT(DATE, DATEADD(MM, DATEDIFF(MM, 0, GETDATE()) - 1, 0))
		WHEN @TIMEFRAME = 'CURRENT MONTH' THEN CONVERT(DATE, DATEADD(D, -(DAY(GETDATE()-1)), GETDATE()))
		WHEN @TIMEFRAME = 'CURRENT QUARTER' THEN CONVERT(DATE, DATEADD(QQ, DATEDIFF(QQ, 0, GETDATE()), 0))


	*/
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

		WHEN @TIMEFRAME = 'CURRENT WEEK' THEN CONVERT(DATE, DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE()), 6))
		WHEN @TIMEFRAME = 'LAST MONTH' THEN CONVERT(DATE, DATEADD(D, -(DAY(GETDATE())), GETDATE()))
		WHEN @TIMEFRAME = 'CURRENT MONTH' THEN CONVERT(DATE, EOMONTH(GETDATE()))
		WHEN @TIMEFRAME = 'CURRENT QUARTER' THEN CONVERT(DATE, DATEADD(DD, -1, DATEADD(QQ, DATEDIFF(QQ, 0, GETDATE()) + 1, 0)))

	*/
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
	and (a.part_id = @Part_ID or @Part_ID IS NULL )
	AND isnull(SR.USER_6,'') != 'PENETRANT'
	AND (SR.USER_8 IN (@DEPARTMENT) OR @DEPARTMENT = 'ALL') -- process e.g.cnc
	AND (SR.USER_5 IN (@FACILITY) OR @FACILITY = 'ALL')   -- plant e.g. plant 1
	and cast(o.CLOSE_DATE as date) >= @STARTDATE
	AND cast(o.CLOSE_DATE as date) <= @ENDDATE
)
select 
        'test-map' note
        -- composite 
        , r.WORKORDER_BASE_ID
        , r.WORKORDER_LOT_ID
        , r.WORKORDER_SPLIT_ID
        , r.WORKORDER_SUB_ID
        , r.SEQUENCE_NO
        -- operation routing
        , r.SEQUENCE_NO
        , r.RESOURCE_ID
        , r.CLOSE_DATE 
        , r.OPERATION_STATUS
        -- Resource
        ,r.RESOURCE_DESCRIPTION
        ,r.Facility  -- Plant 1 or 2 e.g. AP1, AP2 Auburn Plant 1, Auburn Plant 2
        ,r.Department  -- Department responsible for the resource, e.g. Receiving, CNC, ASSEMBLY
        ,r.SubProcess  -- SubProcess associated with the resource
        ,r.Process  -- Process associated with the resource, aka Reporting_Group
        -- ncm new
        ,n.[NCM_NUMBER]
        -- ncm core fields
      ,n.[NONCONFORMANCE_ID]
     -- ,n.[NCM_NUMBER]
      ,n.[NCM_TYPE_CODE]
      ,n.[NCM_DATE]
      ,n.[NCM_STATUS]
      ,n.[NCM_CLOSED_DATE]
      -- composite
      ,n.[BASE_ID]   -- 1829456
      ,n.[PART_ID]
      ,n.[LOT_ID]
      ,n.[SPLIT_ID]
      ,n.[SUB_ID]
      ,n.operation_id NCM_SEQUENCE_NO  -- SEQUENCE
      ,n.[DISPOSITION_BY_TYPE]
      ,n.[RESOURCE_ID_DESCRIPTION]
      ,n.[CUST_REF]
      ,n.[CERT_NUMBER]
      ,n.[LOT_SIZE]
      ,n.[ACCEPTED]
      ,n.[REJECTED]
      ,n.[VENDOR_PO_NUMBER]
      ,n.[AS_IS_DIMENSION]
      ,n.[SHOULD_BE_DIMENSION]
      ,n.[IS_SUPPLIER_NOTICE_SENT]
      ,n.[NCM_DESCRIPTION]
      ,n.[DISPOSITION_TYPE_CODE]
      ,n.[DISPOSITION_DATE]
      ,n.[DISPOSITION_CLOSED_DATE]
      ,n.[DISPOSITION_BY_EMPLOYEE_ID]
      ,n.[DISPOSITION_ASSIGNED_TO_EMPLOYEE_ID]
      ,n.[REWORK_QTY]
      ,n.[SCRAP_QTY]
      ,n.[OVERAGE_QTY]
      ,n.[RETURN_QTY]
      ,n.[ACCEPTED_QTY_DISPOSITION]
      ,n.[REBUILD_QTY]
      ,n.[DISPOSITION_NOTES]
      ,n.[REPORTED_BY_SUPPLIER_ID]
      ,n.[ROOT_CAUSE_TEXT]
      ,n.[CORRECTION_TEXT]
      ,n.[MADE_BY_EMPLOYEE_ID]
      ,n.[ASSIGNED_TO_EMPLOYEE_ID]
      ,n.[VERIFICATION_DATE]
      ,n.[VERIFIED_BY_EMPLOYEE_ID]
      ,n.[DESTRUCTION_DATE]
      ,n.[VERIFICATION_CLOSED_DATE]
      ,n.[VERIFICATION_NOTES]
      ,n.[CreatedAt]
      ,n.[UpdatedAt]
      ,n.[RowPointer]
      ,n.[NEXT_STEP]
      ,n.[EMAIL_PLANNING_FOR_REWORK]
      ,n.[TAG_AREA]
    -- ,n.[PROCESS_ID]
    -- ,n.[SUBPROCESS_ID]
      ,n.[DEFECT_ID]
      ,n.[EMAIL_PLANNING_SENT_AT]
        ,n.PROCESS_ID  -- e.g. CNC
        ,n.SUBPROCESS_ID  -- e.g. 5-Axis, 4-Axis
        , r.PROCESS   -- e.g. CNC
        , r.SUBPROCESS -- e.g. 5-Axis, 4-Axis
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

	,@CalcStartDate AS STARTDATE

	, @CalcEndDate AS [ENDDATE]
        -- chart

    , n.NCM_NUMBER -- -- NCM.NCM_ID
	, n.NCM_TYPE_CODE  -- -- NCM.NCM_DATE
	, IIF(ISNULL( n.NCM_NUMBER, '_BLANK') = '_BLANK', NULL, COALESCE(n.PROCESS_ID, '_BLANK')) AS [IQM_PROCESS]
	, IIF(ISNULL( n.NCM_NUMBER, '_BLANK') = '_BLANK', NULL, COALESCE(n.SUBPROCESS_ID, '_BLANK')) AS [IQM_SUBPROCESS]
	, IIF(ISNULL( n.NCM_NUMBER, '_BLANK') = '_BLANK', NULL, COALESCE(n.DEFECT_ID, '_BLANK')) AS [IQM_DEFECT]
	, N.DISPOSITION_TYPE_code
	, N.NCM_TYPE_code

from route r
join NCM.dbo.NONCONFORMANCE n
  on r.BASE_ID=n.BASE_ID 
  and r.LOT_ID=n.LOT_ID and
    r.SPLIT_ID = n.SPLIT_ID
    and r.SUB_ID = n.SUB_ID
	and r.SEQUENCE_NO = n.operation_id  -- ncm_sequence
where 1=1
-- and n.NCM_NUMBER  IS NOT NULL		
-- and n.ncm_type_code NOT IN ('OVERAGE')		
-- and n.DISPOSITION_TYPE_CODE NOT IN ('NON-DISCREPANT', 'OVERAGE')		
	
-- and r.operation_status  != 'X'	
-- and (n.NCM_NUMBER = @NCM_NUMBER or @NCM_NUMBER is null)


order by n.ncm_date, r.BASE_ID, r.LOT_ID