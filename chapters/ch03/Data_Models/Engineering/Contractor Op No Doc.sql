-- ems without doc refs
-- Perspective: Engineering
-- Report: C:\Users\williamt\OneDrive - Skills Inc GCC High\Documents\sql\20260807 Shannen - Contractor Op No Doc\zzz-111 wo with ems with doc refs missing doc refs.sql
-- Target Audience: P2 Planning Group (Weekly Report / Initial Scoping)
/**********************************************************************************************
Description:
Sample:
Date      Modified By      Change Description
--------- ------------------ ------------------------------------------------------------
08/10/2026	williamt		created

1817652 may have a part level document attached

 wo 1817652 may not have operation level document references
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

With em As(
-- 1. ems with doc refs
SELECT 
    wo.type,
	case when wo.type = 'w' then base_id
	else null end base_id,

    wo.PART_ID PART_ID,
   -- p.[DESCRIPTION] AS PART_DESCRIPTION,
    wo.BASE_ID AS MASTER_BASE_ID,
	wo.LOT_ID,
	wo.SPLIT_ID,
	wo.SUB_ID,
    o.SEQUENCE_NO AS OP_SEQUENCE_NO,
    o.RESOURCE_ID,
    o.OPERATION_TYPE,
    p.PLANNER_USER_ID,
    p.BUYER_USER_ID,
    -- Document count attached directly to the Part Master
    (SELECT COUNT(*) 
     FROM Live.dbo.DOCUMENT_REFERENCE dr 
     WHERE dr.ID = wo.PART_ID
    ) AS PART_LEVEL_DOC_COUNT,
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
   AND wo.[TYPE] = 'M' -- 'M' denotes Engineering Master
   AND o.RESOURCE_ID = 'CONTRACTOR'
  AND isnull(p.BUYER_USER_ID,'') NOT LIKE '%boe609%'
  ---- Filter to find operations where no document is linked to this specific contractor sequence
  ---- ~22 testing williamt 8/7
  AND EXISTS (
      SELECT 1 
      FROM Live.dbo.DOCUMENT_REF_WO drw
      WHERE drw.WORKORDER_TYPE = o.WORKORDER_TYPE
        AND drw.WORKORDER_BASE_ID = o.WORKORDER_BASE_ID
        AND drw.WORKORDER_LOT_ID = o.WORKORDER_LOT_ID
        AND drw.WORKORDER_SPLIT_ID = o.WORKORDER_SPLIT_ID
        AND drw.WORKORDER_SUB_ID = o.WORKORDER_SUB_ID
        AND drw.SEQUENCE_NO = o.SEQUENCE_NO
       )
) -- / em
, WO_0 as (

-- 2. wo's with ems with doc refs, that are missing doc refs
SELECT 
    wo.type,
	wo.create_date,
	case when wo.type = 'w' then base_id
	else null end base_id,

    wo.PART_ID PART_ID,
   -- p.[DESCRIPTION] AS PART_DESCRIPTION,
    null AS MASTER_BASE_ID,
	wo.LOT_ID,
	wo.SPLIT_ID,
	wo.SUB_ID,
    o.SEQUENCE_NO AS OP_SEQUENCE_NO,
    o.RESOURCE_ID,
    o.OPERATION_TYPE,
    p.PLANNER_USER_ID,
    p.BUYER_USER_ID,
    -- Document count attached directly to the Part Master
    (SELECT COUNT(*) 
     FROM Live.dbo.DOCUMENT_REFERENCE dr 
     WHERE dr.ID = wo.PART_ID
    ) AS PART_LEVEL_DOC_COUNT,
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
   AND wo.[TYPE] = 'W' -- 'M' denotes Engineering Master
   AND o.RESOURCE_ID = 'CONTRACTOR'
  AND isnull(p.BUYER_USER_ID,'') NOT LIKE '%boe609%'
  ---- Filter to find operations where no document is linked to this specific contractor sequence
  ---- ~22 testing williamt 8/7
  AND not EXISTS (
      SELECT 1 
      FROM Live.dbo.DOCUMENT_REF_WO drw
      WHERE drw.WORKORDER_TYPE = o.WORKORDER_TYPE
        AND drw.WORKORDER_BASE_ID = o.WORKORDER_BASE_ID
        AND drw.WORKORDER_LOT_ID = o.WORKORDER_LOT_ID
        AND drw.WORKORDER_SPLIT_ID = o.WORKORDER_SPLIT_ID
        AND drw.WORKORDER_SUB_ID = o.WORKORDER_SUB_ID
        AND drw.SEQUENCE_NO = o.SEQUENCE_NO
       )

AND  EXISTS (
      SELECT 1 
      FROM em 
      WHERE 'm' = em.TYPE
	    and 'w' = wo.type
		and wo.SPLIT_ID = em.SPLIT_ID
		and wo.sub_id = em.SUB_ID
        AND wo.Part_ID = em.Part_ID
		AND o.SEQUENCE_NO = em.OP_SEQUENCE_NO
       )
) -- / wo

select * from WO_0 wo
where CREATE_DATE >='2025-01-01'
ORDER BY 
    wo.base_id, 
    wo.PART_ID 
   -- o.SEQUENCE_NO;


      --SELECT drw.* 
      --FROM Live.dbo.DOCUMENT_REF_WO drw
      --WHERE drw.WORKORDER_TYPE like '%' ---- = o.WORKORDER_TYPE
      --  AND drw.WORKORDER_BASE_ID = @part_id  ----o.WORKORDER_BASE_ID
      --  --AND drw.WORKORDER_LOT_ID = o.WORKORDER_LOT_ID
      --  --AND drw.WORKORDER_SPLIT_ID = o.WORKORDER_SPLIT_ID
      --  --AND drw.WORKORDER_SUB_ID = o.WORKORDER_SUB_ID
      --  --AND drw.SEQUENCE_NO = o.SEQUENCE_NO
       