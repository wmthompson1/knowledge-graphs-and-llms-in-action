USE [LIVE]
GO

/****** Object:  View [dbo].[vw_PART_DATA]    Script Date: 1/30/2026 12:10:47 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/**
AI Generated SQL View to consolidate Part data for reporting and analysis. This view combines data from the PART, 
PART_SITE, PART_BINARY, DOCUMENT, DOCUMENT_REFERENCE, and USER_DEF_FIELDS tables to provide a comprehensive dataset 
for each part, including specifications, costs, inventory levels, and user-defined fields.

The query in Part_Profile_2.sql has been refactored to consolidate the USER_DEF_FIELDS joins by pivoting the 
data into a single CTE_USER_DEF_FIELDS. This should improve performance and readability. 
Let me know if you need further adjustments or optimizations!

**/

----CREATE VIEW [dbo].[vw_PART_DATA] AS 

declare @PART_ID NVARCHAR(50) = NULL; -- 'BACB30FM6-7';
DECLARE @VENDOR_ID NVARCHAR(50) = NULL;  ---'3VPREC';
declare @PURC_ORD_ID NVARCHAR(50) = NULL; --- '180033';
declare @cc_in nvarchar(255) = 'raw material, Standards, Details';
DECLARE @START_DATE DATE = '2026-05-01'; 
DECLARE @END_DATE DATE = GETDATE();

WITH CTE_WO AS
(
Select
  '07) FAI' note
  , Count(WO.Base_ID) countOf
  --, allocation_type, customer_id, WO.getlast_review_op_completed_close_date,rm_ready
  ,WO.BASE_ID, WO.LOT_ID, WO.SPLIT_ID, WO.SUB_ID, WO.[TYPE]
from LIVESupplemental.dbo.WODS_Output_ETL WO (nolock)
WHERE customer_id like '%'
and wo.status in ('U','F')
and wo.rm_ready ='NO'
and getlast_review_op_completed_close_date <= dateadd(day,0,getdate())
group by WO.BASE_ID, WO.LOT_ID, WO.SPLIT_ID, WO.SUB_ID, WO.[TYPE]

)
 ,CTE_USER_DEF_FIELDS_VMMFGWIN_WO AS (
    SELECT
        DOCUMENT_ID,
        MAX(CASE WHEN ID = 'UDF-0000086' THEN BOOL_VAL END)   AS [FAI Complete ?]
    FROM Live.dbo.USER_DEF_FIELDS
    WHERE PROGRAM_ID = 'VMMFGWIN_WO'
    AND [LABEL] IS NULL
    and ID IN ('UDF-0000086')
    and document_id like 'W%'
    GROUP BY DOCUMENT_ID


 )
SELECT 
    '07) FAI' note
  , Count(WO.Base_ID) countOf
    -- U1.[FAI Complete ?], WO.BASE_ID, WO.LOT_ID, WO.SPLIT_ID, WO.SUB_ID, WO.[TYPE]
FROM CTE_WO Wo
LEFT OUTER JOIN CTE_USER_DEF_FIELDS_VMMFGWIN_WO U1
	ON U1.DOCUMENT_ID = N'W~' + Wo.BASE_ID + N'~' + Wo.SUB_ID + N'~' + Wo.LOT_ID + N'~' + Wo.SPLIT_ID  
WHERE Wo.TYPE='W'
and U1.[FAI Complete ?] = 1
