USE [LIVE]
GO

-- ...\WorkOrderDailyStatus\2.1 SP_SK_ETL01_WS.sql
/****** Object:  StoredProcedure [dbo].[SP_SK_ETL01_WS]    Script Date: 12/15/2025 8:55:36 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



/* =============================================
-- would you please review this query and be sure to use database schema. 




*/



IF OBJECT_ID('tempdb..#WODS_Output')IS NOT NULL DROP TABLE #WODS_Output

SET NOCOUNT off;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET DEADLOCK_PRIORITY LOW


wods_query_begins:


IF OBJECT_ID('tempdb..#temp1') IS NOT NULL DROP TABLE #temp1


DECLARE @ReportName NVARCHAR(255) = 'WODS'
	, @cols AS NVARCHAR(MAX)
	, @query AS NVARCHAR(MAX);

SET @cols = STUFF( (  SELECT DISTINCT ',' + QUOTENAME(c.Report_Section) 
	FROM LIVESupplemental.dbo.ReportSettings_ResourceID c
	WHERE c.Report_Name = @ReportName
	FOR XML PATH(''), TYPE
	).value('.', 'NVARCHAR(MAX)'), 1, 1, '')
	
SET @query = 'SELECT Resource, ' + @cols + ' FROM
	(SELECT Resource
		, CAST(Include AS INT)Include
		, Report_Section
	FROM (SELECT [Resource_ID] AS Resource, [Report_Name], [Report_Section], [Reasoning], [Notes], [Include]
		FROM LIVESupplemental.dbo.[ReportSettings_ResourceID] 
		) A
	WHERE A.Report_Name = ''' + @ReportName + '''
	) X
	PIVOT (MAX(Include)
	FOR Report_Section IN (' + @Cols + ')
	)P '
--PRINT @query
--SELECT @query

DECLARE @ReportSettings AS TABLE 
	(Resource NVARCHAR(30)
	, AP1_Review INT
	, [HasASSEMBLY] INT
	, HasAubPri INT
	, HasAubTc INT
	, [HasMasking] INT
	, [IsASSEMBLY] INT
	, IsAUBChemline INT
	, IsAUBFinalInspection INT
	, IsAUBInspection INT
	, IsAUBMASK INT
	, IsAUBPartMark INT
	, IsAUBPenetrant INT
	, IsAubPrime INT
	, IsAUBSand INT
	, IsAUBsetup INT
	, IsAUBtakedown INT
	, IsAUBTC INT
	, [IsMasking] INT
	, RESOURCE_ID_OpType INT
	, RESOURCE_ID_SERVICE INT
	)

INSERT INTO @ReportSettings EXECUTE(@query)
--SELECT * FROM @ReportSettings

IF OBJECT_ID('tempdb..#NOTATIONBYOWNER') IS NOT NULL DROP TABLE #NOTATIONBYOWNER;
IF OBJECT_ID('tempdb..#WORK_ORDER') IS NOT NULL DROP TABLE #WORK_ORDER;
IF OBJECT_ID('tempdb..#USER_DEF_FIELDS') IS NOT NULL DROP TABLE #USER_DEF_FIELDS;
IF OBJECT_ID('tempdb..#USER_DEF_FIELDS_W_48') IS NOT NULL DROP TABLE #USER_DEF_FIELDS_W_48;

-- Started executing query at  Line 11
-- Msg 8156, Level 16, State 1, Line 99
-- The column 'ROWID' was specified multiple times for 'cte_operations'.

with cte_work_order as (
    select
        wo.part_id, wo.status, wo.base_id, wo.lot_id, wo.split_id, wo.sub_id, wo.[TYPE],
        dbo.sfn_current_operation(wo.[TYPE], wo.BASE_ID, wo.LOT_ID, wo.SPLIT_ID, wo.SUB_ID) as CurrentOperation,
		WONUM = 
			(BASE_ID + 
			CASE WHEN ISNULL(SUB_ID,'0') = '0' 
				THEN '' 
				ELSE '-' + SUB_ID 
			END	+ 
			'/' + LOT_ID + 
			CASE WHEN ISNULL(SPLIT_ID,'0') = '0' 
				THEN '' 
				ELSE '.' + SPLIT_ID 
			END)

    from [Live].[dbo].[WORK_ORDER] wo
	where wo.type = 'w'
	and wo.status not in ('X', 'C')
),
cte_operations as (
    -- Avoid duplicate ROWID by not selecting w.*
    select
        o.*,
        w.BASE_ID,
        w.LOT_ID,
        w.SPLIT_ID,
        w.SUB_ID,
        w.[TYPE]
    from [Live].[dbo].[OPERATION] o
    join cte_work_order w
      on w.BASE_ID = o.WORKORDER_BASE_ID
     and w.LOT_ID = o.WORKORDER_LOT_ID
     and w.SPLIT_ID = o.WORKORDER_SPLIT_ID
     and w.SUB_ID = o.WORKORDER_SUB_ID
     and w.[TYPE] = o.WORKORDER_TYPE
),
cte_getlast_review_op_completed as (
	SELECT getlast_review_op_completed = MAX(o.sequence_no)
		 --keys
		 ,o.workorder_type, o.workorder_base_id, o.workorder_lot_id, o.workorder_split_id, o.workorder_sub_id
	FROM cte_operations o
	WHERE 1=1
	AND o.status = 'C'
	AND (o.resource_id like '%review%'
		AND o.resource_id <> 'review' -- is old  
		AND o.resource_id <> 'B1F1-REVIEW')
	GROUP BY o.workorder_type, o.workorder_base_id, o.workorder_lot_id, o.workorder_split_id, o.workorder_sub_id
)
-- please add a cte structure here to extract the operation.close_date for the getlast_review_op_completed and join to work order as well.
, cte_getlast_review_op_completed_close_date as (
	SELECT 
		o.workorder_type, o.workorder_base_id, o.workorder_lot_id, o.workorder_split_id, o.workorder_sub_id,
		MAX(CASE WHEN o.sequence_no = r.getlast_review_op_completed THEN o.close_date END) AS getlast_review_op_completed_close_date
	FROM cte_operations o
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
)

, cte_work_order_final AS (
	select
		w.*,
		r.getlast_review_op_completed,
		c.getlast_review_op_completed_close_date
	from cte_work_order w
	left join cte_getlast_review_op_completed r
		on r.workorder_type = w.[TYPE]
		and r.workorder_base_id = w.BASE_ID
		and r.workorder_lot_id = w.LOT_ID
		and r.workorder_split_id = w.SPLIT_ID
		and r.workorder_sub_id = w.SUB_ID
	left join cte_getlast_review_op_completed_close_date c
		on c.workorder_type = w.[TYPE]
		and c.workorder_base_id = w.BASE_ID
		and c.workorder_lot_id = w.LOT_ID
		and c.workorder_split_id = w.SPLIT_ID
		and c.workorder_sub_id = w.SUB_ID
)

SELECT 
	BASE_ID, LOT_ID, SPLIT_ID, SUB_ID, [TYPE], part_id, status, CurrentOperation, WONUM, getlast_review_op_completed, getlast_review_op_completed_close_date
	FROM cte_work_order_final w
;
