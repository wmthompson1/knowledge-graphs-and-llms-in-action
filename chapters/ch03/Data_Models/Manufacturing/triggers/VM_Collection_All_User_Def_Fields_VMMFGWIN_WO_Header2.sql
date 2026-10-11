--USE [LIVE]
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
declare @BASE_ID nvarchar(50) = '1817346'; 
declare @SUB_ID nvarchar(50) = NULL;
declare @LOT_ID nvarchar(50) = NULL;
declare @SPLIT_ID nvarchar(50) = NULL;
declare @TYPE nvarchar(50) = NULL;


WITH CTE_APP AS
(

select id, [IS_APPROVER] from [dbo].[PERSON]
where 1=1
and IS_APPROVER = 'Y'

-- I need to build the  conditional for the trigger of a polymorphic table called USER_DEF_FIELDS, which is used to store user-defined fields for various programs. The trigger should check if the current user is an approver before allowing updates to certain fields, specifically the 'Expedite' field in the VMMFGWIN_WO program.
-- user defined fields. I need to revert one field in particular if the user is not listed in the person table as is_approver = 'Y'
--  For USER_DEF_FIELDS table where:
--  PROGRAM_ID = 'VMMFGWIN_WO'
--  [LABEL] IS NULL
--  ID = 'UDF-0000070' 

)
-- VMMFGWIN_WO
 ,CTE_USER_DEF_FIELDS_VMMFGWIN_WO AS (
    SELECT
        DOCUMENT_ID,
        PROGRAM_ID,
        label,
           MAX(CASE WHEN ID = 'UDF-0000070' THEN STRING_VAL END) AS [EXP/FLT]
    FROM Live.dbo.USER_DEF_FIELDS
    WHERE PROGRAM_ID = 'VMMFGWIN_WO'
    AND [LABEL] IS NULL
    GROUP BY DOCUMENT_ID, PROGRAM_ID, LABEL


 )

-- select * from CTE_USER_DEF_FIELDS_VMMFGWIN_WO
-- where DOCUMENT_ID like 'W%';  -- work order document ids start with w in our system, this is just to filter down to relevant records for testing
SELECT 
 1 CountOf,
    u1.[EXP/FLT], M.COMMODITY_CODE, M.PART_ID, M.BASE_ID, M.LOT_ID
    , M.SPLIT_ID, M.SUB_ID, M.[TYPE], M.DESIRED_QTY, M.DESIRED_RLS_DATE

    ,U1.DOCUMENT_ID,
    U1.PROGRAM_ID,
    U1.label
FROM WORK_ORDER M
inner JOIN CTE_USER_DEF_FIELDS_VMMFGWIN_WO U1
	ON U1.DOCUMENT_ID = N'W~' + M.BASE_ID + N'~' + M.SUB_ID + N'~' + M.LOT_ID + N'~' + M.SPLIT_ID  

WHERE M.TYPE='W'
and M.BASE_ID = @BASE_ID
        and NOT EXISTS (
            SELECT 1 
            FROM DBO.person p 
            WHERE p.id = SUSER_SNAME() -- Or p.id = SYSTEM_USER depending on your data type
            AND p.IS_APPROVER = 'Y'
        )
