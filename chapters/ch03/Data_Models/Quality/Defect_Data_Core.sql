USE LIVE --
GO

-- Defect_Data_Core3
-- Documentation\Schema\Data_Models\Quality\Defect_Data_Core.sql
/**********************************************************************************************

Description:  
Note:   
run at lab 2

Date        Modified By         Change Description
----------  ------------------  ------------------------------------------------------------
08/31/26    William Thompson    Created.

compute dimensions based on 1. lab-2 2 union bew abd old

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


DECLARE @Tester int
declare @part_id nvarchar(250) = NULL; -- --  '313Z7430-504';  -- '313Z7430-504' '70750B-071-MIL-NG';
Set @Tester = 0
DECLARE @workorder_base_id nvarchar(30) = NULL; -- -- 
Declare @resource_id nvarchar(30) = NULL;  -- -- 
DECLARE @NCM_NUMBER NVARCHAR(30) = NULL; -- '50668';
declare @STARTDATE date = '2026-07-01';
declare @ENDDATE date = GETDATE();
declare @DEPARTMENT nvarchar(50) = 'cnc'
declare @FACILITY nvarchar(50) = 'ap2'


SELECT i.* into #IQM_PROCESS
from(
SELECT '_Blank' AS IQM_PROCESS
UNION
SELECT COALESCE(SK_FIN_NCM_PROCESS, SK_MFG_NCM_PROCESS, '_BLANK') AS [IQM_PROCESS]
FROM [sql-bi-1].Datawarehouse.dbo.VQ_NONCONFORMANCE
GROUP BY COALESCE(SK_FIN_NCM_PROCESS, SK_MFG_NCM_PROCESS, '_BLANK')
) i
-- select * from #IQM_PROCESS

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

-- select * from #FACILITY

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
-- select * from #DEPARTMENT

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

  -- select defect_id from #ncm group by defect_id

  /**
	SELECT
       [BASE_ID]   -- 1829456
      ,[PART_ID]
      ,[LOT_ID]
      ,[SPLIT_ID]
      ,[SUB_ID]
      ,SEQUENCE_NO
	FROM #ncm
  **/


  -- S1.2.1.1 Inventory_Transactions_Filtered.sql
-- file path: SQL_Reports/Inventory/Inventory - Transactions AI Review.sql
-- run at sql-lab-2 in prod
-- dw in stage on sql-bi-1

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
select 
'test-map' note
,n.*
, n.[NCM_NUMBER]

,n.PROCESS_ID  -- e.g. CNC
,n.SUBPROCESS_ID  -- e.g. 5-Axis, 4-Axis

, r.Process   -- e.g. CNC
, r.SubProcess -- e.g. 5-Axis, 4-Axis
from route r
join #ncm n
  on r.BASE_ID=n.BASE_ID 
  and r.LOT_ID=n.LOT_ID and
    r.SPLIT_ID = n.SPLIT_ID
    and r.SUB_ID = n.SUB_ID
	and r.SEQUENCE_NO = n.SEQUENCE_NO

order by n.ncm_date, r.BASE_ID, r.LOT_ID