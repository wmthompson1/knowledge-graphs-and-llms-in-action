use DataWarehouse

/* Planning MFG On Time 
Separates CMP and Non-CMP by Planner_user_id on the part table.
Sliding year for showing trends

-- calculating the start_date
-- if the desired release date is before the create date then it is a replacement so use the create date
-- if the base_id contains an R then it is a rework work order and it is expected to use the create date
-- if the desired release date is after the create date then it is regular

-- calculating Ontime/Late
-- if the start_date is MFG-CMP then only 4 work days is allowed for completion
-- if the start_date is MFG-NON-CMP then only 7 work days is allowed for completion 
*/

    DECLARE @in_commodity_code_rm nvarchar(MAX) = N'raw material';

; WITH CTE_WOx AS 
(  SELECT CASE 
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
 , CASE 
  WHEN WO.BASE_ID NOT LIKE '%R%' AND DATEDIFF(DD, WO.CREATE_DATE, WO.DESIRED_RLS_DATE) < 0 THEN CONVERT(DATE, WO.CREATE_DATE) -- REPLACEMENT
  WHEN WO.BASE_ID LIKE '%R%' AND DATEDIFF(DD, WO.CREATE_DATE, WO.DESIRED_RLS_DATE) < 0 THEN CONVERT(DATE, WO.CREATE_DATE) -- REWORK
  ELSE CONVERT(DATE, WO.DESIRED_RLS_DATE)--'REGULAR'
 END AS [START_DATE]
 FROM WORK_ORDER WO
 INNER JOIN PART P ON WO.PART_ID = P.ID
 WHERE (1=1)
  --LEFT(P.PLANNER_USER_ID, 3) = 'MFG'
  --AND CONVERT(DATE, WO.DESIRED_RLS_DATE) >= '2024-12-01'--GETDATE() - 400
  AND CONVERT(DATE, WO.DESIRED_RLS_DATE) >= '2024-12-01'
  AND CONVERT(DATE, WO.DESIRED_RLS_DATE) < GETDATE() +30
  AND WO.[TYPE] = 'W' AND WO.SUB_ID = '0' AND WO.SPLIT_ID = '0'
 /****************** union to add history last year from SQL-Lab-2 LIVEARC ******************/
UNION 
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
 , CASE 
  WHEN WO.BASE_ID NOT LIKE '%R%' AND DATEDIFF(DD, WO.CREATE_DATE, WO.DESIRED_RLS_DATE) < 0 THEN CONVERT(DATE, WO.CREATE_DATE) -- REPLACEMENT
  WHEN WO.BASE_ID LIKE '%R%' AND DATEDIFF(DD, WO.CREATE_DATE, WO.DESIRED_RLS_DATE) < 0 THEN CONVERT(DATE, WO.CREATE_DATE) -- REWORK
  ELSE CONVERT(DATE, WO.DESIRED_RLS_DATE)--'REGULAR'
 END AS [START_DATE]
 FROM [SQL-Lab-2].[LIVEARC].dbo.WORK_ORDER WO
 INNER JOIN [SQL-Lab-2].[LIVEARC].dbo.PART P ON WO.PART_ID = P.ID
 WHERE (1=1)
  --LEFT(P.PLANNER_USER_ID, 3) = 'MFG'
  AND CONVERT(DATE, WO.DESIRED_RLS_DATE) >= '2024-01-01'
  AND CONVERT(DATE, WO.DESIRED_RLS_DATE) < '2024-12-01'
  AND WO.[TYPE] = 'W' AND WO.SUB_ID = '0' AND WO.SPLIT_ID = '0'
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
	AND (o.resource_id like '%review%'
		AND o.resource_id <> 'review' -- is old  
		AND o.resource_id <> 'B1F1-REVIEW')
	GROUP BY o.workorder_type, o.workorder_base_id, o.workorder_lot_id, o.workorder_split_id, o.workorder_sub_id

), CTE_WO as (
select w.* 
  ,iif(t2.available = 1, 'NO', NULL) as RM_READY
  ,r.getlast_review_op_completed_close_date
from CTE_WOx w
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
(SELECT distinct CMP_NON_CMP, WO_CATEGORY, BASE_ID, LOT_ID, SPLIT_ID, SUB_ID
 , [TYPE], PART_ID, PLANNER_USER_ID, CREATE_DATE, DESIRED_RLS_DATE, PRINTED_DATE
 , DATENAME(DW, [START_DATE]) AS DAYNAME, [START_DATE]
 , CASE 
  WHEN DATEPART(WEEKDAY, [START_DATE]) = 7 THEN DATEADD(DW, 2, [START_DATE]) 
  WHEN DATEPART(WEEKDAY, [START_DATE]) = 1 THEN DATEADD(DW, 1, [START_DATE]) 
  ELSE [START_DATE]
 END AS START_DATE_ADJ
 , RM_READY
 , getlast_review_op_completed_close_date
FROM CTE_WO
)

select * from CTE_WO2;

/*
; WITH CTE_WO AS 
(  SELECT CASE 
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
 , CASE 
  WHEN WO.BASE_ID NOT LIKE '%R%' AND DATEDIFF(DD, WO.CREATE_DATE, WO.DESIRED_RLS_DATE) < 0 THEN CONVERT(DATE, WO.CREATE_DATE) -- REPLACEMENT
  WHEN WO.BASE_ID LIKE '%R%' AND DATEDIFF(DD, WO.CREATE_DATE, WO.DESIRED_RLS_DATE) < 0 THEN CONVERT(DATE, WO.CREATE_DATE) -- REWORK
  ELSE CONVERT(DATE, WO.DESIRED_RLS_DATE)--'REGULAR'
 END AS [START_DATE]
 FROM WORK_ORDER WO
 INNER JOIN PART P
  ON WO.PART_ID = P.ID
 WHERE (1=1)
  --LEFT(P.PLANNER_USER_ID, 3) = 'MFG'
  --AND CONVERT(DATE, WO.DESIRED_RLS_DATE) >= '2024-12-01'--GETDATE() - 400
  AND CONVERT(DATE, WO.DESIRED_RLS_DATE) >= '2024-12-01'
  AND WO.[TYPE] = 'W'
  AND WO.SUB_ID = '0'
  AND WO.SPLIT_ID = '0'
 /****************** union to add history last year from SQL-Lab-2 LIVEARC ******************/
UNION 
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
 , CASE 
  WHEN WO.BASE_ID NOT LIKE '%R%' AND DATEDIFF(DD, WO.CREATE_DATE, WO.DESIRED_RLS_DATE) < 0 THEN CONVERT(DATE, WO.CREATE_DATE) -- REPLACEMENT
  WHEN WO.BASE_ID LIKE '%R%' AND DATEDIFF(DD, WO.CREATE_DATE, WO.DESIRED_RLS_DATE) < 0 THEN CONVERT(DATE, WO.CREATE_DATE) -- REWORK
  ELSE CONVERT(DATE, WO.DESIRED_RLS_DATE)--'REGULAR'
 END AS [START_DATE]
 FROM [SQL-Lab-2].[LIVEARC].dbo.WORK_ORDER WO
 INNER JOIN [SQL-Lab-2].[LIVEARC].dbo.PART P
  ON WO.PART_ID = P.ID
 WHERE (1=1)
  --LEFT(P.PLANNER_USER_ID, 3) = 'MFG'
  AND CONVERT(DATE, WO.DESIRED_RLS_DATE) >= '2024-01-01'
  AND CONVERT(DATE, WO.DESIRED_RLS_DATE) < '2024-12-01'
  AND WO.[TYPE] = 'W'
  AND WO.SUB_ID = '0'
  AND WO.SPLIT_ID = '0'
)

, CTE_WO2 AS 
(SELECT distinct CMP_NON_CMP
 , WO_CATEGORY
 , BASE_ID
 , LOT_ID 
 , SPLIT_ID
 , SUB_ID
 , [TYPE]
 , PART_ID
 , PLANNER_USER_ID
 , CREATE_DATE
 , DESIRED_RLS_DATE
 , PRINTED_DATE
 , DATENAME(DW, [START_DATE]) AS DAYNAME
 , [START_DATE]
 , CASE 
  WHEN DATEPART(WEEKDAY, [START_DATE]) = 7 THEN DATEADD(DW, 2, [START_DATE]) 
  WHEN DATEPART(WEEKDAY, [START_DATE]) = 1 THEN DATEADD(DW, 1, [START_DATE]) 
  ELSE [START_DATE]
 END AS START_DATE_ADJ
FROM CTE_WO
)

, CTE_WAITDAYS AS
(SELECT WO.CMP_NON_CMP
 , WO_CATEGORY
 , WO.BASE_ID 
 , WO.LOT_ID 
 , WO.SPLIT_ID
 , WO.SUB_ID
 , WO.[TYPE]
 , WO.PART_ID
 , PLANNER_USER_ID
 , WO.CREATE_DATE 
 , WO.DESIRED_RLS_DATE
 , O.CLOSE_DATE
 , O.[STATUS]
 , O.RESOURCE_ID
 , O.OPERATION_TYPE
 , WO.PRINTED_DATE 
 , WO.START_DATE_ADJ
 , DATEDIFF(DW,WO.START_DATE_ADJ, COALESCE(O.CLOSE_DATE, WO.PRINTED_DATE, GETDATE())) AS WAIT_DAYS
 -- would you change these ontime-late blocks 1) so that start_date_adj is getlast_review_op_completed_close_date? and 2) it is conditional upon material
 -- being ready (RN_READY can't be no for MFG orders  )
 , 
 CASE WHEN WO.RM_READY = 'NO' THEN 'LATE'
 ELSE
    CASE 
      WHEN CMP_NON_CMP = 'MFG-NON-CMP' AND DATEDIFF(DW, WO.START_DATE_ADJ, COALESCE(O.CLOSE_DATE, WO.PRINTED_DATE, GETDATE())) <= 7 THEN 'ON-TIME'
      WHEN CMP_NON_CMP = 'MFG-CMP' AND DATEDIFF(DW, WO.START_DATE_ADJ, COALESCE(O.CLOSE_DATE, WO.PRINTED_DATE, GETDATE())) <= 4 THEN 'ON-TIME'
      WHEN CMP_NON_CMP = 'FIN-NON-CMP' AND DATEDIFF(DW, WO.START_DATE_ADJ, COALESCE(O.CLOSE_DATE, WO.PRINTED_DATE, GETDATE())) <= 2 THEN 'ON-TIME'
      WHEN CMP_NON_CMP = 'FIN-CMP' AND DATEDIFF(DW, WO.START_DATE_ADJ, COALESCE(O.CLOSE_DATE, WO.PRINTED_DATE, GETDATE())) <= 2 THEN 'ON-TIME'
      ELSE 'LATE'
    END 
  END AS ONTIME_LATE

FROM CTE_WO2 WO
INNER JOIN [SQL-Lab-2].[LIVEARC].dbo.OPERATION O
 ON WO.TYPE = O.WORKORDER_TYPE
 AND WO.BASE_ID = O.WORKORDER_BASE_ID
 AND WO.LOT_ID = O.WORKORDER_LOT_ID
 AND WO.SPLIT_ID = O.WORKORDER_SPLIT_ID
 AND WO.SUB_ID = O.WORKORDER_SUB_ID
WHERE O.RESOURCE_ID LIKE '%REVIEW%'
 AND O.OPERATION_TYPE NOT IN ('MFG-ORDER-ENTRY', 'FIN-ORDER-ENTRY')
 AND O.[STATUS] NOT IN ('X')
)

SELECT CMP_NON_CMP
 , WO_CATEGORY
 , BASE_ID
 , LOT_ID 
 , SPLIT_ID
 , SUB_ID
 , [TYPE]
 , PART_ID
 , RESOURCE_ID
 , OPERATION_TYPE
 , PLANNER_USER_ID
 , CREATE_DATE
 , DESIRED_RLS_DATE
 , CLOSE_DATE
 , [STATUS]
 , PRINTED_DATE
 , START_DATE_ADJ
 , WAIT_DAYS
 , ONTIME_LATE
 , CONVERT(VARCHAR(4), YEAR(START_DATE_ADJ)) + '-' + RIGHT('00' + CONVERT(VARCHAR(2), MONTH(START_DATE_ADJ)), 2) AS START_LABEL
FROM CTE_WAITDAYS
*/