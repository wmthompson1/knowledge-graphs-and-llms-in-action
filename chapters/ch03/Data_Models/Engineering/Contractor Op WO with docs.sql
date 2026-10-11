-- Documentation\Schema\Data_Models\Engineering\Contractor Op WO with docs.sql
-- C:\Users\williamt\source\skillsinc\skills-inc-org\SQL-Projects\Documentation\Schema\Data_Models\Engineering\Contractor Op WO with docs.sql
/**********************************************************************************************
Description:
Sample:
Date      Modified By      Change Description
--------- ------------------ ------------------------------------------------------------
08/10/2026	williamt		created

1817652 may have a part level document attached

 SEE Documentation\Schema\Data_Models\Engineering\Contractor Op WO with docs.sql
 wo 1817652 may not have operation level document references
 so I need to change this query to get docs
 by work order
**********************************************************************************************/
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET DEADLOCK_PRIORITY LOW
IF OBJECT_ID('tempdb..#Results') IS NOT NULL DROP TABLE #Results


 --declare @part_id nvarchar(50) = null; -- --  '115W2730-15'

--select wo.BASE_ID, wo.TYPE
--FROM Live.dbo.WORK_ORDER wo
--INNER JOIN Live.dbo.OPERATION o
--  ON wo.BASE_ID = o.WORKORDER_BASE_ID
--   AND wo.LOT_ID = o.WORKORDER_LOT_ID
--   AND wo.SPLIT_ID = o.WORKORDER_SPLIT_ID
--   AND wo.SUB_ID = o.WORKORDER_SUB_ID
-- AND wo.TYPE = o.WORKORDER_TYPE
--LEFT OUTER JOIN Live.dbo.PART p
--   ON wo.BASE_ID = p.ID
--WHERE 1=1 
--  and wo.BASE_ID like @part_id
--  AND o.RESOURCE_ID = 'CONTRACTOR'
;

-- for work_orded type w get docs
declare @base_id nvarchar(50) = '1817652'; -- --  '115W2730-15'
declare @lot_id nvarchar(50) = '1'; -- --  '115W2730-15'
DECLARE @SUB_ID nvarchar(50) = '1'; -- --  '115W2730-15'

With wo As(
-- 1. Work orders
SELECT 
    wo.type,
    wo.CREATE_DATE,
    wo.BASE_ID AS WORKORDER_BASE_ID,

    wo.PART_ID PART_ID,
   -- p.[DESCRIPTION] AS PART_DESCRIPTION,
	wo.LOT_ID,
	wo.SPLIT_ID,
	wo.SUB_ID,
    o.SEQUENCE_NO AS OP_SEQUENCE_NO,
    o.RESOURCE_ID,
    o.OPERATION_TYPE,
    p.PLANNER_USER_ID,
    p.BUYER_USER_ID,
    -- Document count attached directly to the Work Order operation sequence
    (SELECT COUNT(*) 
     FROM Live.dbo.DOCUMENT_REF_WO drw 
     WHERE drw.WORKORDER_TYPE = o.WORKORDER_TYPE
       AND drw.WORKORDER_BASE_ID = o.WORKORDER_BASE_ID
       AND drw.WORKORDER_LOT_ID = o.WORKORDER_LOT_ID
       AND drw.WORKORDER_SPLIT_ID = o.WORKORDER_SPLIT_ID
       AND drw.WORKORDER_SUB_ID = o.WORKORDER_SUB_ID
       AND drw.SEQUENCE_NO = o.SEQUENCE_NO
    ) AS OP_LEVEL_DOC_COUNT
--   '' X
FROM Live.dbo.WORK_ORDER wo
INNER JOIN Live.dbo.OPERATION o
    ON wo.BASE_ID = o.WORKORDER_BASE_ID
    AND wo.LOT_ID = o.WORKORDER_LOT_ID
    AND wo.SPLIT_ID = o.WORKORDER_SPLIT_ID
    AND wo.SUB_ID = o.WORKORDER_SUB_ID
    AND WO.TYPE = O.WORKORDER_TYPE
LEFT OUTER JOIN LIVE.DBO.PART P
    ON WO.BASE_ID = P.ID
WHERE 1=1 
  -- AND (wo.BASE_ID  = @part_id or @part_id is null)
   and wo.BASE_ID = @base_id
   AND wo.[TYPE] = 'W' -- 'W' denotes Work Order
  AND NOT EXISTS (
      SELECT 1
      FROM Live.dbo.DOCUMENT_REF_WO AS drw
      WHERE drw.WORKORDER_TYPE = o.WORKORDER_TYPE
        AND drw.WORKORDER_BASE_ID = o.WORKORDER_BASE_ID
        AND drw.WORKORDER_LOT_ID = o.WORKORDER_LOT_ID
        AND drw.WORKORDER_SPLIT_ID = o.WORKORDER_SPLIT_ID
        AND drw.WORKORDER_SUB_ID = o.WORKORDER_SUB_ID
        AND drw.SEQUENCE_NO = o.SEQUENCE_NO
  )
   ---AND o.RESOURCE_ID = 'CONTRACTOR'
  ---AND isnull(p.BUYER_USER_ID,'') NOT LIKE '%boe609%'
  ---- Filter to find operations where no document is linked to this specific contractor sequence
  ---- ~22 testing williamt 8/7
--   AND EXISTS (
--       SELECT 1 
--       FROM Live.dbo.DOCUMENT_REF_WO drw
--       WHERE drw.WORKORDER_TYPE = o.WORKORDER_TYPE
--         AND drw.WORKORDER_BASE_ID = o.WORKORDER_BASE_ID
--         AND drw.WORKORDER_LOT_ID = o.WORKORDER_LOT_ID
--         AND drw.WORKORDER_SPLIT_ID = o.WORKORDER_SPLIT_ID
--         AND drw.WORKORDER_SUB_ID = o.WORKORDER_SUB_ID
--         AND drw.SEQUENCE_NO = o.SEQUENCE_NO
--        )
) -- / wo
-- select * from wo
, EM_0 as (

-- 2. Engineering Masters with document references
SELECT 
    wo.type,
	wo.create_date,
    wo.BASE_ID AS MASTER_BASE_ID,

    wo.PART_ID PART_ID,
   -- p.[DESCRIPTION] AS PART_DESCRIPTION,
	wo.LOT_ID,
	wo.SPLIT_ID,
	wo.SUB_ID,
    o.SEQUENCE_NO AS OP_SEQUENCE_NO,
    o.RESOURCE_ID,
    o.OPERATION_TYPE,
    p.PLANNER_USER_ID,
    p.BUYER_USER_ID,
    dr.DOCUMENT_ID AS PART_LEVEL_DOCUMENT_ID,
    dr.LINE_NO AS PART_DOCUMENT_LINE_NO,
    dr.SOURCE_TYPE AS PART_DOCUMENT_SOURCE_TYPE,
    -- Document count attached directly to the Master Operation Sequence
    (SELECT COUNT(*) 
     FROM Live.dbo.DOCUMENT_REF_WO drw 
     WHERE drw.WORKORDER_TYPE = o.WORKORDER_TYPE
       AND drw.WORKORDER_BASE_ID = o.WORKORDER_BASE_ID
       AND drw.WORKORDER_LOT_ID = o.WORKORDER_LOT_ID
       AND drw.WORKORDER_SPLIT_ID = o.WORKORDER_SPLIT_ID
       AND drw.WORKORDER_SUB_ID = o.WORKORDER_SUB_ID
       AND drw.SEQUENCE_NO = o.SEQUENCE_NO
    ) AS OP_LEVEL_DOC_COUNT
--   '' X
FROM  Live.dbo.WORK_ORDER wo
INNER JOIN Live.dbo.OPERATION o
    ON wo.BASE_ID = o.WORKORDER_BASE_ID
    AND wo.LOT_ID = o.WORKORDER_LOT_ID
    AND wo.SPLIT_ID = o.WORKORDER_SPLIT_ID
    AND wo.SUB_ID = o.WORKORDER_SUB_ID
    AND WO.TYPE = O.WORKORDER_TYPE
LEFT OUTER JOIN LIVE.DBO.PART P
    ON WO.BASE_ID = P.ID

-- part doc
left join Live.dbo.DOCUMENT_REFERENCE dr 
     on dr.ID = wo.PART_ID

WHERE 1=1 
  -- AND (wo.BASE_ID  = @part_id or @part_id is null)
   AND wo.[TYPE] = 'M' -- 'M' denotes Engineering Master
   --and wo.BASE_ID = @base_id
--    AND o.RESOURCE_ID = 'CONTRACTOR'
--   AND isnull(p.BUYER_USER_ID,'') NOT LIKE '%boe609%'
  ---- Filter to find operations where no document is linked to this specific contractor sequence
  ---- ~22 testing williamt 8/7
  AND (
      dr.DOCUMENT_ID IS NOT NULL
      OR EXISTS (
          SELECT 1
          FROM Live.dbo.DOCUMENT_REF_WO AS drw
          WHERE drw.WORKORDER_TYPE = o.WORKORDER_TYPE
            AND drw.WORKORDER_BASE_ID = o.WORKORDER_BASE_ID
            AND drw.WORKORDER_LOT_ID = o.WORKORDER_LOT_ID
            AND drw.WORKORDER_SPLIT_ID = o.WORKORDER_SPLIT_ID
            AND drw.WORKORDER_SUB_ID = o.WORKORDER_SUB_ID
            AND drw.SEQUENCE_NO = o.SEQUENCE_NO
      )
  )

) -- / wo

SELECT
    workOrder.TYPE,
    workOrder.CREATE_DATE,
    workOrder.WORKORDER_BASE_ID,
    engineeringMaster.MASTER_BASE_ID,
    workOrder.PART_ID,
    workOrder.LOT_ID,
    workOrder.SPLIT_ID,
    workOrder.SUB_ID,
    workOrder.OP_SEQUENCE_NO,
    workOrder.RESOURCE_ID,
    workOrder.OPERATION_TYPE,
    workOrder.OP_LEVEL_DOC_COUNT AS WORKORDER_OP_LEVEL_DOC_COUNT,
    engineeringMaster.PART_LEVEL_DOCUMENT_ID,
    engineeringMaster.PART_DOCUMENT_LINE_NO,
    engineeringMaster.PART_DOCUMENT_SOURCE_TYPE,
    engineeringMaster.OP_LEVEL_DOC_COUNT AS MASTER_OP_LEVEL_DOC_COUNT
FROM wo AS workOrder
INNER JOIN EM_0 AS engineeringMaster
    ON engineeringMaster.PART_ID = workOrder.PART_ID
   AND engineeringMaster.SPLIT_ID = workOrder.SPLIT_ID
   AND engineeringMaster.SUB_ID = workOrder.SUB_ID
   AND engineeringMaster.OP_SEQUENCE_NO = workOrder.OP_SEQUENCE_NO
WHERE workOrder.CREATE_DATE >= '2025-01-01'
-- ORDER BY 
--     wo.base_id, 
--     wo.PART_ID 
--    -- o.SEQUENCE_NO;


--       --SELECT drw.* 
--       --FROM Live.dbo.DOCUMENT_REF_WO drw
--       --WHERE drw.WORKORDER_TYPE like '%' ---- = o.WORKORDER_TYPE
--       --  AND drw.WORKORDER_BASE_ID = @part_id  ----o.WORKORDER_BASE_ID
--       --  --AND drw.WORKORDER_LOT_ID = o.WORKORDER_LOT_ID
--       --  --AND drw.WORKORDER_SPLIT_ID = o.WORKORDER_SPLIT_ID
--       --  --AND drw.WORKORDER_SUB_ID = o.WORKORDER_SUB_ID
--       --  --AND drw.SEQUENCE_NO = o.SEQUENCE_NO
       