-- S1.2.1.1 Inventory_Transactions_Filtered.sql
-- file path: SQL_Reports/Inventory/Inventory - Transactions AI Review.sql
-- run at sql-lab-2 in prod
-- dw in stage on sql-bi-1



/**********************************************************************************************
Code Base 3.2
Description:   Reconcile trace inventory trans to inventory trans to On hand
Note:   allows maintainable code with grain to transaction id.
        There are two levels of aggregation 1 - xact id 2 - part
        Whether or not all transactions trace does not impact test,
        but rather allows a dataset to render the difference in transaction
        in case the is a variance with the amounts.    
Code Base: 3.2.4 Inventory - On Hand Reconciled    

Date        Modified By         Change Description
----------  ------------------  ------------------------------------------------------------
08/03/20    William Thompson    Created.
12/10/25    William Thompson    Updated for Code Base 3.2.4 - Determine location of parts 
12/12/25    William Thompson    Updated for Code Base S1.2.1.1 part_id used in join 


**********************************************************************************************/


SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET DEADLOCK_PRIORITY LOW

IF OBJECT_ID('tempdb..#Results') IS NOT NULL DROP TABLE #Results
IF OBJECT_ID('tempdb..#trace_inv_trans') IS NOT NULL DROP TABLE #trace_inv_trans
IF OBJECT_ID('tempdb..#trace_profile') IS NOT NULL DROP TABLE #trace_profile
IF OBJECT_ID('tempdb..#Trace') IS NOT NULL DROP TABLE #Trace
IF OBJECT_ID('tempdb..#part_trace_maint') IS NOT NULL DROP TABLE #part_trace_maint

IF OBJECT_ID('tempdb..#inventory_trans') IS NOT NULL DROP TABLE #inventory_trans
IF OBJECT_ID('tempdb..#ixact_agg_by_part') IS NOT NULL DROP TABLE #ixact_agg_by_part

IF OBJECT_ID('tempdb..#planning_on_hand') IS NOT NULL DROP TABLE #planning_on_hand
IF OBJECT_ID('tempdb..#tixact_agg_by_xact_id') IS NOT NULL DROP TABLE #tixact_agg_by_xact_id
IF OBJECT_ID('tempdb..#tixact_agg_by_part_id') IS NOT NULL DROP TABLE #tixact_agg_by_part_id
IF OBJECT_ID('tempdb..#results_agg') IS NOT NULL DROP TABLE #results_agg

IF OBJECT_ID('Datawarehouse.managedData.Inventory_On_Hand_Reconcilable') IS NOT NULL DROP TABLE Datawarehouse.managedData.Inventory_On_Hand_Reconcilable
-- #Inventory_On_Hand_Reconcilable
IF OBJECT_ID('tempdb..#Inventory_On_Hand_Reconcilable') IS NOT NULL DROP TABLE #Inventory_On_Hand_Reconcilable

IF OBJECT_ID('tempdb..#temp1') IS NOT NULL DROP TABLE #temp1
IF OBJECT_ID('tempdb..#temp2') IS NOT NULL DROP TABLE #temp2
IF OBJECT_ID('tempdb..#temp3') IS NOT NULL DROP TABLE #temp3
IF OBJECT_ID('tempdb..#temp4') IS NOT NULL DROP TABLE #temp4
IF OBJECT_ID('tempdb..#temp5') IS NOT NULL DROP TABLE #temp5


DECLARE @Tester int

declare @part_id nvarchar(250) = NULL; -- --  '313Z7430-504';  -- '313Z7430-504' '70750B-071-MIL-NG';
declare @resource_id nvarchar(30) = NULL;

Set @Tester = 0
DECLARE @workorder_base_id nvarchar(30) = NULL; -- -- '1803245' -- '1802575' --'1789047'; --'1670717'; -- '1801171'; -- '1793687'
declare @start_date datetime = '2026-01-01'; -- -- '2024-01-01';

with sched as (
select
  'work order operations' note
  -- part
  , a.part_id

  -- work order
  , a.status workorder_status
  , a.base_id
  , a.lot_id
  , a.split_id
  , a.sub_id
  , a.[TYPE] AS workorder_type
  -- key
		,a.BASE_ID + CASE WHEN ISNULL(a.SUB_ID,'0') = '0' 
			THEN '' 
			ELSE '-' + a.SUB_ID 
			END	+ 
			'/' + a.LOT_ID + 
			CASE WHEN ISNULL(a.SPLIT_ID,'0') = '0' 
			THEN '' 
			ELSE '.' + a.SPLIT_ID 
			END AS WO_NUM
  -- operation routing
  , o.SEQUENCE_NO

  , o.RESOURCE_ID
  , P.STOCK_UM

    -- Resource
  ,SR.DESCRIPTION AS RESOURCE_DESCRIPTION
  ,SR.USER_5 AS Facility  -- Plant 1 or 2 e.g. AP1, AP2 Auburn Plant 1, Auburn Plant 2
  ,SR.USER_6 AS Department  -- Department responsible for the resource, e.g. Receiving, CNC, ASSEMBLY
  ,SR.USER_7 AS Process  -- Process associated with the resource
  ,SR.USER_8 AS Reporting_Group  -- Reporting group for the resource

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
  and a.STATUS not in ('X', 'C')
  and a.STATUS in ('R', 'E', 'H', 'S', 'P', 'F','C')  -- Released, Enroute, Hold, Started, Partially Complete, Finished,Closed
  and (a.part_id = @Part_ID or @Part_ID IS NULL )
  AND (o.RESOURCE_ID = @resource_id OR @resource_id IS NULL)
), 
cte_LastClockOut AS (
            SELECT LT.WORKORDER_BASE_ID, LT.WORKORDER_LOT_ID, LT.WORKORDER_SPLIT_ID
                , LT.WORKORDER_SUB_ID, LT.WORKORDER_TYPE, MAX(LT.CLOCK_OUT) AS LAST_CLOCK_OUT
            FROM LABOR_TICKET LT
            WHERE EXISTS (SELECT 1 FROM sched WO
                  WHERE LT.WORKORDER_BASE_ID = WO.BASE_ID AND LT.WORKORDER_LOT_ID = WO.LOT_ID
                        AND LT.WORKORDER_SPLIT_ID = WO.SPLIT_ID AND LT.WORKORDER_SUB_ID = WO.SUB_ID
                        AND LT.WORKORDER_TYPE = WO.workorder_type
               )
            and lt.CLOCK_IN >= @start_date
            GROUP BY LT.WORKORDER_BASE_ID, LT.WORKORDER_LOT_ID, LT.WORKORDER_SPLIT_ID
                , LT.WORKORDER_SUB_ID, LT.WORKORDER_TYPE
)
SELECT
  s.WO_NUM,
  lco.LAST_CLOCK_OUT
FROM sched AS s
--LEFT JOIN cte_LastClockOut AS lco
INNER JOIN cte_LastClockOut AS lco
  ON lco.WORKORDER_BASE_ID = s.BASE_ID
   AND lco.WORKORDER_LOT_ID = s.LOT_ID
   AND lco.WORKORDER_SPLIT_ID = s.SPLIT_ID
   AND lco.WORKORDER_SUB_ID = s.SUB_ID
   AND lco.WORKORDER_TYPE = s.workorder_type
ORDER BY s.BASE_ID, s.LOT_ID, s.SPLIT_ID, s.SUB_ID, s.SEQUENCE_NO;