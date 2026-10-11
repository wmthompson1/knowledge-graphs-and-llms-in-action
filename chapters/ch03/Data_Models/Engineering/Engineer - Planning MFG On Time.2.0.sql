--use DataWarehouse

-- C:\Users\williamt\source\skillsinc\skills-inc-org\SQL-Projects\Documentation\Schema\Data_Models\Engineering\Engineer - Planning On Time.2 snippet.sql
-- Planning MFG On Time.2 Snippet.sql
-- Category: Engineering
-- PLANNING
-- Data Model
-- Engineer - Planning On Time.2 snippet.sql
/* Planning MFG On Time 
Separates CMP and Non-CMP by Planner_user_id on the part table.
Sliding year for showing trends

-- calculating the start_date
-- if the desired release date is before the create date then it is a replacement so use the create date
-- if the base_id contains an R then it is a rework work order and it is expected to use the create date
-- if the desired release date is after the create date then it is regular

-- calculating Ontime/Late
-- updated 06/12/2026 - start date = date of review operation
-- if the start_date is MFG-CMP then only 4 work days is allowed for completion
-- if the start_date is MFG-NON-CMP then only 7 work days is allowed for completion 
*/

/**********************************************************************************************
Description:
Sample:
Date      Modified By      Change Description
---------- ------------------ ------------------------------------------------------------
06/12/2026 William T.        Initial development
06/16/2026 William T.			Update start date calculation to use the last review operation completed close date for regular work orders, 
06/16/2026 William T.		 Update start date calculation for replacement and rework work orders to use the difference between the create date and desired release date, 

✓ RM_READY converted to numeric (1 = materials not ready)  
✓ MFG orders now require `RM_READY <> 1` to be marked ON-TIME  
✓ FIN orders unaffected by material availability  
added getlast_review_op_completed_close_date to the final select for potential use in Power BI report as a filter or additional data point to understand if work orders are waiting on review or waiting on materials, or both.

1. re:start date - determine where check for rework will take place, which cte.
2. add additional cte block after cte_getlast_review_op_completed_close_date to shape start_date, use search for rework (base_id like '*') 

**********************************************************************************************/
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET DEADLOCK_PRIORITY LOW
IF OBJECT_ID('tempdb..#Results') IS NOT NULL DROP TABLE #Results


    DECLARE @in_commodity_code_rm nvarchar(MAX) = N'raw material';
	DECLARE @BASE_ID VARCHAR(50) = NULL -- '1742636'; -- for testing only, to be removed later, or can be used to filter for specific work order in the final version

; WITH CTE_WOx AS 
(  
  SELECT CASE 
  WHEN P.PLANNER_USER_ID LIKE 'MFG-HOURLY%' THEN 'MFG-CMP' 
  WHEN P.PLANNER_USER_ID = 'FIN-HOURLY' THEN 'FIN-CMP' 
  WHEN P.PLANNER_USER_ID = 'FIN' THEN 'FIN-NON-CMP' 
  WHEN LEFT(P.PLANNER_USER_ID, 3) = 'MFG' THEN 'MFG-NON-CMP' 
  ELSE P.PLANNER_USER_ID
 END AS CMP_NON_CMP
 , CASE 
  WHEN WO.BASE_ID NOT LIKE '%R%' AND DATEDIFF(DD, WO.CREATE_DATE,WO.DESIRED_RLS_DATE) < 0 THEN 'REPLACEMENT'
  WHEN WO.BASE_ID LIKE '%R%' AND DATEDIFF(DD, WO.CREATE_DATE,WO.DESIRED_RLS_DATE) < 0 THEN 'REWORK'
  ELSE 'REGULAR'
 END AS WO_CATEGORY
 , WO.BASE_ID, WO.LOT_ID, WO.SPLIT_ID, WO.SUB_ID, WO.[TYPE], WO.PART_ID, P.PLANNER_USER_ID
 , CONVERT(DATE, WO.CREATE_DATE) AS CREATE_DATE, WO.DESIRED_RLS_DATE, WO.PRINTED_DATE

 -- moved top cte_shape_start_date to calculate start date after determining if it is a rework or not, and to use the getlast_review_op_completed_close_date for regular work orders instead of the desired release date, to account for time spent waiting in review which is separate from waiting on materials, and is important to consider when looking at on-time vs late.
--  , CASE 
--   WHEN WO.BASE_ID NOT LIKE '%R%' AND DATEDIFF(DD, WO.CREATE_DATE, WO.DESIRED_RLS_DATE) < 0 THEN CONVERT(DATE, WO.CREATE_DATE) -- REPLACEMENT
--   WHEN WO.BASE_ID LIKE '%R%' AND DATEDIFF(DD, WO.CREATE_DATE, WO.DESIRED_RLS_DATE) < 0 THEN CONVERT(DATE, WO.CREATE_DATE) -- REWORK
--   ELSE CONVERT(DATE, WO.DESIRED_RLS_DATE)--'REGULAR'
--  END AS [START_DATE]
 FROM WORK_ORDER WO
 INNER JOIN PART P ON WO.PART_ID = P.ID
 WHERE (1=1)
   AND (WO.BASE_ID = @BASE_ID OR @BASE_ID IS NULL)   -- for testing only, to be removed later, or can be used to filter for specific work order in the final version
  -- -LEFT(P.PLANNER_USER_ID, 3) = 'MFG'
  -- --AND CONVERT(DATE, WO.DESIRED_RLS_DATE) >= '2024-12-01'--GETDATE() - 400
  AND CONVERT(DATE, WO.DESIRED_RLS_DATE) >= '2024-12-01'
  AND CONVERT(DATE, WO.DESIRED_RLS_DATE) < GETDATE() +30
  AND WO.[TYPE] = 'W' AND WO.SUB_ID = '0' AND WO.SPLIT_ID = '0'
 /****************** union to add history last year from SQL-Lab-2 LIVEARC ******************/
-- UNION 
-- 	 SELECT CASE 
-- 	  WHEN P.PLANNER_USER_ID LIKE 'MFG-HOURLY%' THEN 'MFG-CMP' 
-- 	  WHEN P.PLANNER_USER_ID = 'FIN-HOURLY' THEN 'FIN-CMP' 
-- 	  WHEN P.PLANNER_USER_ID = 'FIN' THEN 'FIN-NON-CMP' 
-- 	  WHEN LEFT(P.PLANNER_USER_ID, 3) = 'MFG' THEN 'MFG-NON-CMP' 
-- 	  ELSE P.PLANNER_USER_ID
-- 	 END AS CMP_NON_CMP
-- 	 , CASE 
-- 	  WHEN WO.BASE_ID NOT LIKE '%R%' AND DATEDIFF(DD, WO.CREATE_DATE,WO.DESIRED_RLS_DATE) < 0 THEN 'REPLACEMENT'
-- 	  WHEN WO.BASE_ID LIKE '%R%' AND DATEDIFF(DD, WO.CREATE_DATE,WO.DESIRED_RLS_DATE) < 0 THEN 'REWORK'
-- 	  ELSE 'REGULAR'
-- 	 END AS WO_CATEGORY
-- 	 , WO.BASE_ID, WO.LOT_ID, WO.SPLIT_ID, WO.SUB_ID, WO.[TYPE], WO.PART_ID, P.PLANNER_USER_ID
-- 	 , CONVERT(DATE, WO.CREATE_DATE) AS CREATE_DATE, WO.DESIRED_RLS_DATE, WO.PRINTED_DATE
-- 	 , CASE 
-- 	  WHEN WO.BASE_ID NOT LIKE '%R%' AND DATEDIFF(DD, WO.CREATE_DATE, WO.DESIRED_RLS_DATE) < 0 THEN CONVERT(DATE, WO.CREATE_DATE) -- REPLACEMENT
-- 	  WHEN WO.BASE_ID LIKE '%R%' AND DATEDIFF(DD, WO.CREATE_DATE, WO.DESIRED_RLS_DATE) < 0 THEN CONVERT(DATE, WO.CREATE_DATE) -- REWORK
-- 	  ELSE CONVERT(DATE, WO.DESIRED_RLS_DATE)--'REGULAR'
-- 	 END AS [START_DATE]
--  FROM [SQL-Lab-2].[LIVEARC].dbo.WORK_ORDER WO
--  INNER JOIN [SQL-Lab-2].[LIVEARC].dbo.PART P ON WO.PART_ID = P.ID
--  WHERE (1=1)
--    AND (WO.BASE_ID = @BASE_ID OR @BASE_ID IS NULL)   -- for testing only
--   -- --LEFT(P.PLANNER_USER_ID, 3) = 'MFG'
--   AND CONVERT(DATE, WO.DESIRED_RLS_DATE) >= '2024-01-01'
--   AND CONVERT(DATE, WO.DESIRED_RLS_DATE) < '2024-12-01'
--   AND WO.[TYPE] = 'W' AND WO.SUB_ID = '0' AND WO.SPLIT_ID = '0'
)
-- ~22
-- material availaility (1 = no)
, cte_tester2 as (
	select
		a.WORKORDER_BASE_ID, a.WORKORDER_LOT_ID, a.WORKORDER_SPLIT_ID, a.WORKORDER_SUB_ID, a.WORKORDER_TYPE
		--,STRING_AGG(CONVERT(varchar(50), a.PART_ID), ', ') AS PART_ID_CSV
		,STRING_AGG(CONVERT(varchar(50), iif(
			(iif((a.CALC_QTY - a.ISSUED_QTY) <= b.QTY_ON_HAND, 0, 1)) 
			> 0, a.PART_ID,NULL)), ', ') AS PART_ID_CSV2
	--	,STRING_AGG(CONVERT(varchar(50), b.COMMODITY_CODE), ', ') AS COMMODITY_CODE_CSV
		, iif(
			sum(iif((a.CALC_QTY - a.ISSUED_QTY) <= b.QTY_ON_HAND, 0, 1)) 
			> 0, 1,0)
		as 'available'
		,max(iif((a.CALC_QTY - a.ISSUED_QTY) <= b.QTY_ON_HAND, NULL, IIF( b.commodity_code in ('standards','details'),'sta_det',null))) as commodity_code
	--	into #RAW_MATERIAL_WODsX
	FROM REQUIREMENT a WITH (NOLOCK)  --//#VM: change from [SQL-LAB-1] to [SQL-LAB-2]
	INNER JOIN PART b WITH (NOLOCK) on a.PART_ID = b.ID  
		and b.COMMODITY_CODE IN (
    SELECT LTRIM(RTRIM(value))
    FROM STRING_SPLIT(@in_commodity_code_rm, ',')
    )
	-- -- INNER JOIN WORK_ORDER c WITH (NOLOCK) ON 
	-- -- CTE_WO
	INNER JOIN CTE_WOx c WITH (NOLOCK) ON 
		a.WORKORDER_BASE_ID = c.BASE_ID and a.WORKORDER_LOT_ID = c.LOT_ID and a.WORKORDER_SPLIT_ID = c.SPLIT_ID and a.WORKORDER_SUB_ID = c.SUB_ID
	WHERE 1=1 
	-- in test 2.2.2
	and c.type = 'w'
	and a.SUBORD_WO_SUB_ID is null

	group by
	a.WORKORDER_BASE_ID, a.WORKORDER_LOT_ID, a.WORKORDER_SPLIT_ID, a.WORKORDER_SUB_ID, a.WORKORDER_TYPE

	having 
	iif(
		sum(iif(a.CALC_QTY <= b.QTY_ON_HAND, 0, 1)) 
		> 0, 1,0) > 0

), cte_getlast_review_op_completed as (
	-- ignre this in test
	SELECT getlast_review_op_completed = MAX(o.sequence_no)
		 --keys
		 ,o.workorder_type, o.workorder_base_id, o.workorder_lot_id, o.workorder_split_id, o.workorder_sub_id
	FROM operation o
		JOIN CTE_WOx w  -- work order
		ON o.workorder_type = w.[TYPE]
		AND o.workorder_base_id = w.BASE_ID
		AND o.workorder_lot_id = w.LOT_ID
		AND o.workorder_split_id = w.SPLIT_ID
		AND o.workorder_sub_id = w.SUB_ID
	WHERE 1=1
	AND o.status = 'C'
	AND (o.resource_id like '%review%'
		AND o.resource_id <> 'review' -- is old  
		AND o.resource_id <> 'B1F1-REVIEW')
	GROUP BY o.workorder_type, o.workorder_base_id, o.workorder_lot_id, o.workorder_split_id, o.workorder_sub_id
)
, cte_getlast_review_op_completed_close_date as (
	SELECT 
		o.workorder_type, o.workorder_base_id, o.workorder_lot_id, o.workorder_split_id, o.workorder_sub_id,
		MAX(CASE WHEN o.sequence_no = r.getlast_review_op_completed THEN o.close_date END) AS getlast_review_op_completed_close_date
	FROM operation o
	JOIN cte_getlast_review_op_completed r
		ON r.workorder_type = o.workorder_type
		AND r.workorder_base_id = o.workorder_base_id
		AND r.workorder_lot_id = o.workorder_lot_id
		AND r.workorder_split_id = o.workorder_split_id
		AND r.workorder_sub_id = o.workorder_sub_id
	WHERE 1=1
	AND o.status = 'C'
	AND (ISNULL(o.resource_id, '') like '%review%'
		AND ISNULL(o.resource_id, '') <> 'review' -- is old  
		AND ISNULL(o.resource_id, '') <> 'B1F1-REVIEW')
	GROUP BY o.workorder_type, o.workorder_base_id, o.workorder_lot_id, o.workorder_split_id, o.workorder_sub_id
), cte_shape_start_date as (
	SELECT BASE_ID, LOT_ID, SPLIT_ID, SUB_ID, [TYPE],
	  getlast_review_op_completed_close_date,
	  -- replace wo.desired_release_date with the getlast_review_op_completed_close_date for regular work orders, to account for time spent waiting in review which is separate from waiting on materials, and is important to consider when looking at on-time vs late.
	  -- update 06/16/2026 for replacement and rework work orders, use the difference between the create date and WO.DESIRED_RLS_DATE   
		CASE 
		WHEN WO.BASE_ID NOT LIKE '%R%' AND DATEDIFF(DD, WO.CREATE_DATE, WO.DESIRED_RLS_DATE ) < 0 THEN CONVERT(DATE, WO.CREATE_DATE) -- REPLACEMENT
		WHEN WO.BASE_ID LIKE '%R%' AND DATEDIFF(DD, WO.CREATE_DATE, WO.DESIRED_RLS_DATE ) < 0 THEN CONVERT(DATE, WO.CREATE_DATE) -- REWORK
		ELSE CONVERT(DATE, WO.DESIRED_RLS_DATE) --'REGULAR'
		END AS [START_DATE]
	FROM CTE_WOx WO
	JOIN cte_getlast_review_op_completed_close_date r
		ON r.workorder_base_id = WO.BASE_ID
		AND r.workorder_lot_id = WO.LOT_ID
		AND r.workorder_split_id = WO.SPLIT_ID   
		AND r.workorder_sub_id = WO.SUB_ID
		AND r.workorder_type = WO.[TYPE]


), CTE_WO as (
select w.* 
  ,iif(t2.available = 1, 1, 0) as RM_READY
  ,r.getlast_review_op_completed_close_date
  ,s.START_DATE
from CTE_WOx w
  --- ignore this is in test
	join cte_shape_start_date s
		ON s.BASE_ID = w.BASE_ID
		AND s.LOT_ID = w.LOT_ID
		AND s.SPLIT_ID = w.SPLIT_ID
		AND s.SUB_ID = w.SUB_ID
		AND s.[TYPE] = w.[TYPE]
	LEFT JOIN cte_tester2 t2
		ON t2.WORKORDER_BASE_ID = w.BASE_ID
		AND t2.WORKORDER_LOT_ID = w.LOT_ID
		AND t2.WORKORDER_SPLIT_ID = w.SPLIT_ID
		AND t2.WORKORDER_SUB_ID = w.SUB_ID
		AND t2.WORKORDER_TYPE = w.[TYPE]
    LEFT JOIN cte_getlast_review_op_completed_close_date r
        ON r.workorder_base_id = w.BASE_ID
        AND r.workorder_lot_id = w.LOT_ID
        AND r.workorder_split_id = w.SPLIT_ID   
        AND r.workorder_sub_id = w.SUB_ID
        AND r.workorder_type = w.[TYPE]
        
)
-- ~22

, CTE_WO2 AS 
(SELECT DISTINCT 
	CMP_NON_CMP, 
	WO_CATEGORY, 
	BASE_ID, 
	LOT_ID, 
	SPLIT_ID, 
	SUB_ID,
	[TYPE], 
	PART_ID, 
	PLANNER_USER_ID, 
	CREATE_DATE, 
	DESIRED_RLS_DATE, 
	PRINTED_DATE,
	-- start date is based on the last review operation completed close date, to account for time spent waiting in review	
	DATENAME(DW, [START_DATE]) AS DAYNAME, 

	-- CASE 
	-- 	WHEN DATEPART(WEEKDAY, [START_DATE]) = 7 THEN DATEADD(DW, 2, [START_DATE]) 
	-- 	WHEN DATEPART(WEEKDAY, [START_DATE]) = 1 THEN DATEADD(DW, 1, [START_DATE]) 
	-- 	ELSE [START_DATE]
	-- END AS START_DATE_ADJ,
	RM_READY,
	-- calculate weekdate next to the start date, if the start date falls on a weekend, adjust to the following Monday
		CASE 
		WHEN DATEPART(WEEKDAY, [START_DATE]) = 7 THEN DATEADD(DW, 2, [START_DATE]) 
		WHEN DATEPART(WEEKDAY, [START_DATE]) = 1 THEN DATEADD(DW, 1, [START_DATE]) 
		ELSE [START_DATE]
	END AS START_DATE_ADJ
	
FROM CTE_WO
)

, CTE_WAITDAYS AS
(SELECT WO.CMP_NON_CMP, WO_CATEGORY, WO.BASE_ID , WO.LOT_ID , WO.SPLIT_ID, WO.SUB_ID
	, WO.[TYPE], WO.PART_ID, PLANNER_USER_ID, WO.CREATE_DATE , WO.DESIRED_RLS_DATE
	, O.CLOSE_DATE, O.[STATUS], O.RESOURCE_ID, O.OPERATION_TYPE, WO.PRINTED_DATE 
	, WO.START_DATE_ADJ
	, DATEDIFF(DW,WO.START_DATE_ADJ, COALESCE(O.CLOSE_DATE, WO.PRINTED_DATE, GETDATE())) AS WAIT_DAYS
	-- plan: additional condiition added to lines 273 - 274: (AND RM_READY <> 1) , to consider work orders that are waiting on materials as late, 
	-- for manufacturing orders.
	-- manufacturing requires materials so use material availability to determine on-time vs late, finishing doesn't require materials so use original logic

     ,CASE 
		WHEN CMP_NON_CMP = 'MFG-NON-CMP'  AND DATEDIFF(DW, WO.START_DATE_ADJ, COALESCE(O.CLOSE_DATE, WO.PRINTED_DATE, GETDATE())) <= 7 THEN 'ON-TIME'
		WHEN CMP_NON_CMP = 'MFG-CMP'  AND DATEDIFF(DW, WO.START_DATE_ADJ, COALESCE(O.CLOSE_DATE, WO.PRINTED_DATE, GETDATE())) <= 4 THEN 'ON-TIME'
	
	-- finishing doesn't require materials so use original logic
	-- m2: instead of wo.start_date_adj, use getlast_review_op_completed_close_date as the start date for calculating on-time vs late, to account for the time work orders are waiting in review, separate from waiting on materials.
		WHEN CMP_NON_CMP = 'FIN-NON-CMP' AND DATEDIFF(DW, WO.START_DATE_ADJ, COALESCE(O.CLOSE_DATE, WO.PRINTED_DATE, GETDATE())) <= 2 THEN 'ON-TIME'
		WHEN CMP_NON_CMP = 'FIN-CMP' AND DATEDIFF(DW, WO.START_DATE_ADJ, COALESCE(O.CLOSE_DATE, WO.PRINTED_DATE, GETDATE())) <= 2 THEN 'ON-TIME'
		ELSE
           CASE
           WHEN WO.RM_READY = 1 THEN 'ON-TIME' -- if waiting for materials then not counted as late 
           ELSE 'LATE' -- if not waiting for materials then counted as late
           END
	    END AS ONTIME_LATE
	, RM_READY
	--, getlast_review_op_completed_close_date
FROM CTE_WO2 WO
INNER JOIN OPERATION O ON WO.TYPE = O.WORKORDER_TYPE
	AND WO.BASE_ID = O.WORKORDER_BASE_ID AND WO.LOT_ID = O.WORKORDER_LOT_ID
	AND WO.SPLIT_ID = O.WORKORDER_SPLIT_ID AND WO.SUB_ID = O.WORKORDER_SUB_ID
WHERE 1 = 1 -- -- O.RESOURCE_ID LIKE '%REVIEW%'
	AND (isnull(o.resource_id, '') like '%review%'
		AND ISNULL(o.resource_id, '') <> 'review' -- is old  
		AND ISNULL(o.resource_id,'') <> 'B1F1-REVIEW')
	AND O.OPERATION_TYPE NOT IN ('MFG-ORDER-ENTRY', 'FIN-ORDER-ENTRY')
	AND O.[STATUS] NOT IN ('X')
	-- report goes back a year, so change date filter to match the same sliding year as the main query
	AND WO.CREATE_DATE >= '2025-11-01' AND WO.CREATE_DATE < GETDATE() + 30
/****************** union to add history last year from SQL-Lab-2 LIVEARC ******************/
-- UNION
-- SELECT WO.CMP_NON_CMP, WO_CATEGORY, WO.BASE_ID , WO.LOT_ID, WO.SPLIT_ID, WO.SUB_ID
-- 	, WO.[TYPE], WO.PART_ID, PLANNER_USER_ID, WO.CREATE_DATE , WO.DESIRED_RLS_DATE
-- 	, O.CLOSE_DATE, O.[STATUS], O.RESOURCE_ID, O.OPERATION_TYPE, WO.PRINTED_DATE 
-- 	, WO.START_DATE_ADJ
-- 	, DATEDIFF(DW,WO.START_DATE_ADJ, COALESCE(O.CLOSE_DATE, WO.PRINTED_DATE, GETDATE())) AS WAIT_DAYS
-- 	-- plan: additional condiition added to lines 303 - 305: (AND RM_READY <> 1) , to consider work orders that are waiting on materials as late, for manufacturing orders.  
-- 	-- manufacturing requires materials so use material availability to determine on-time vs late, finishing doesn't require materials so use original logic
-- 	-- m2: instead of wo.start_date_adj, use getlast_review_op_completed_close_date as the start date for calculating on-time vs late, to account for the time work orders are waiting in review, separate from waiting on materials.
-- 	,    CASE 
--        	WHEN CMP_NON_CMP = 'MFG-NON-CMP'  AND WO.RM_READY <> 1 AND DATEDIFF(DW, WO.getlast_review_op_completed_close_date, COALESCE(O.CLOSE_DATE, WO.PRINTED_DATE, GETDATE())) <= 7 THEN 'ON-TIME'
-- 		WHEN CMP_NON_CMP = 'MFG-CMP'  AND WO.RM_READY <> 1 AND DATEDIFF(DW, WO.getlast_review_op_completed_close_date, COALESCE(O.CLOSE_DATE, WO.PRINTED_DATE, GETDATE())) <= 4 THEN 'ON-TIME'
	
--     -- finishing doesn't require materials so use original logic
-- 	-- m2: instead of wo.start_date_adj, use getlast_review_op_completed_close_date as the start date for calculating on-time vs late, to account for the time work orders are waiting in review, separate from waiting on materials.

-- 		WHEN CMP_NON_CMP = 'FIN-NON-CMP' AND DATEDIFF(DW, WO.getlast_review_op_completed_close_date, COALESCE(O.CLOSE_DATE, WO.PRINTED_DATE, GETDATE())) <= 2 THEN 'ON-TIME'
-- 		WHEN CMP_NON_CMP = 'FIN-CMP' AND DATEDIFF(DW, WO.getlast_review_op_completed_close_date, COALESCE(O.CLOSE_DATE, WO.PRINTED_DATE, GETDATE())) <= 2 THEN 'ON-TIME'
-- 		ELSE 'LATE'
-- 	    END AS ONTIME_LATE
-- 	, RM_READY
-- 	, getlast_review_op_completed_close_date
-- FROM CTE_WO2 WO
-- INNER JOIN [SQL-Lab-2].[LIVEARC].dbo.OPERATION O ON WO.TYPE = O.WORKORDER_TYPE
-- 	AND WO.BASE_ID = O.WORKORDER_BASE_ID AND WO.LOT_ID = O.WORKORDER_LOT_ID
-- 	AND WO.SPLIT_ID = O.WORKORDER_SPLIT_ID AND WO.SUB_ID = O.WORKORDER_SUB_ID
-- WHERE O.RESOURCE_ID LIKE '%REVIEW%'
-- 	AND O.OPERATION_TYPE NOT IN ('MFG-ORDER-ENTRY', 'FIN-ORDER-ENTRY')
-- 	AND O.[STATUS] NOT IN ('X')
-- 	-- change date filter to match the same sliding year as the main query
-- 	AND WO.CREATE_DATE >= '2024-01-01' AND WO.CREATE_DATE < '2024-12-01'
)

SELECT CMP_NON_CMP, WO_CATEGORY, BASE_ID, LOT_ID, SPLIT_ID, SUB_ID
	, [TYPE], PART_ID, RESOURCE_ID, OPERATION_TYPE, PLANNER_USER_ID
	, CREATE_DATE, DESIRED_RLS_DATE, CLOSE_DATE, [STATUS], PRINTED_DATE
	, START_DATE_ADJ, WAIT_DAYS, ONTIME_LATE
	, CONVERT(VARCHAR(4), YEAR(START_DATE_ADJ)) + '-' + RIGHT('00' + CONVERT(VARCHAR(2), MONTH(START_DATE_ADJ)), 2) AS START_LABEL
	, RM_READY
	--, getlast_review_op_completed_close_date
FROM CTE_WAITDAYS





