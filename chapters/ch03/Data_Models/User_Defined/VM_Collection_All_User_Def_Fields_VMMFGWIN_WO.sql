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
/**********************************************************************************************
Description:
Sample:
Date      Modified By      Change Description
---------- ------------------ ------------------------------------------------------------
**********************************************************************************************/
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET DEADLOCK_PRIORITY LOW
IF OBJECT_ID('tempdb..#Results') IS NOT NULL DROP TABLE #Results
if OBJECT_ID('tempdb..#ColumnCount') IS NOT NULL DROP TABLE #ColumnCount


declare @PART_ID NVARCHAR(50) = NULL; -- 'BACB30FM6-7';
DECLARE @VENDOR_ID NVARCHAR(50) = NULL;  ---'3VPREC';
declare @PURC_ORD_ID NVARCHAR(50) = NULL; --- '180033';
declare @cc_in nvarchar(255) = 'raw material, Standards, Details';
DECLARE @START_DATE DATE = '2026-05-01'; 
DECLARE @END_DATE DATE = GETDATE();

WITH CTE_PO AS
(

SELECT po.ID as PURC_ORD_ID, po.VENDOR_ID, po.ORDER_DATE, POL.PART_ID, pol.LINE_NO PO_LINE_NO, po.rowid
       ,p.COMMODITY_CODE
FROM PURCHASE_ORDER PO
LEFT OUTER JOIN PURC_ORDER_LINE POL
	ON PO.ID = POL.PURC_ORDER_ID 
LEFT OUTER JOIN PART P
	ON POL.PART_ID = P.ID
LEFT OUTER JOIN EMPLOYEE EE
	ON PO.BUYER = EE.[USER_ID]
WHERE 1=1 
and (pol.part_id = @part_id or @PART_ID is null)
AND (po.ID = @PURC_ORD_ID OR @PURC_ORD_ID IS NULL)
--and (p.COMMODITY_CODE in (@cc_in)) -- --  ('raw material', 'Standards', 'Details')
 AND (PO.ORDER_DATE >= @START_DATE OR @START_DATE IS NULL)
 AND (PO.ORDER_DATE <= @END_DATE OR @END_DATE IS NULL)

and p.COMMODITY_CODE IN (
    SELECT LTRIM(RTRIM(value))
    FROM STRING_SPLIT(@cc_in, ',')
)

),
CTE_VENDOR AS
(SELECT v.ID 
FROM VENDOR v
JOIN CTE_PO po
ON Po.VENDOR_ID = V.ID
WHERE 1=1   
AND (v.ID = @VENDOR_ID OR @VENDOR_ID IS NULL)
--AND v.ID = @VENDOR_ID
),
 CTE_USER_DEF_FIELDS_TEST AS (
    SELECT
        DOCUMENT_ID,
        MAX(CASE WHEN ID = 'UDF-0000059' THEN STRING_VAL END) AS [EM Revision],
        MAX(CASE WHEN ID = 'UDF-0000060' THEN BOOL_VAL END)   AS [Expedite (Check for Yes)],
        MAX(CASE WHEN ID = 'UDF-0000061' THEN BOOL_VAL END)   AS [New Part (Check for Yes)],
        MAX(CASE WHEN ID = 'UDF-0000070' THEN STRING_VAL END) AS [EXP/FLT],
        MAX(CASE WHEN ID = 'UDF-0000071' THEN STRING_VAL END) AS [QEA(EMPID-Initials): ],
        MAX(CASE WHEN ID = 'UDF-0000072' THEN STRING_VAL END) AS [FAI Approval Date:],
        MAX(CASE WHEN ID = 'UDF-0000073' THEN BOOL_VAL END)   AS [Label Required (Check for Yes)],
        MAX(CASE WHEN ID = 'UDF-0000074' THEN STRING_VAL END) AS [CERTS REQUIRED],
        MAX(CASE WHEN ID = 'UDF-0000086' THEN BOOL_VAL END) AS [FAI Complete ?]
    FROM Live.dbo.USER_DEF_FIELDS
    WHERE PROGRAM_ID = 'VMMFGWIN_WO'
    GROUP BY DOCUMENT_ID
 )

 ,CTE_USER_DEF_FIELDS_VMMFGWIN_WO AS (
    SELECT
        DOCUMENT_ID,
        MAX(CASE WHEN ID = 'UDF-0000086' THEN BOOL_VAL END)   AS [FAI Complete ?]
    FROM Live.dbo.USER_DEF_FIELDS
    WHERE PROGRAM_ID = 'VMMFGWIN_WO'
    GROUP BY DOCUMENT_ID


 ), VMPRTMNT AS ( 
SELECT 
 1 CountOf
 -- would you create a virtual table so I can check the count of columns against
 -- select count(*) FROM USER_DEF_FIELDS WHERE PROGRAM_ID = 'VMPRTMNT' and program_id is null
    , UI.DOCUMENT_ID AS ID  -- alias for name of actual key

    , UI.[EM Revision]
    , UI.[Expedite (Check for Yes)]
    , UI.[New Part (Check for Yes)]
    , UI.[EXP/FLT]
    , UI.[QEA(EMPID-Initials): ]
    , UI.[FAI Approval Date:]
    , UI.[Label Required (Check for Yes)]
    , UI.[CERTS REQUIRED]
    , UI.[FAI Complete ?]


FROM CTE_USER_DEF_FIELDS_TEST UI
WHERE 1=1
 )
, LabelSetVMPRTMNT AS (
    SELECT COUNT(*) AS TotalCount
    FROM USER_DEF_FIELDS
    WHERE PROGRAM_ID = 'VMMFGWIN_WO'
    AND [LABEL] IS NULL
)
-- -- how to select column count of virtual table #Results
select *
into #Results
from VMPRTMNT
;
select count(*) - 2 as ColumnCount
into #ColumnCount
from tempdb.sys.columns
where object_id = object_id('tempdb..#Results')
;
--select * from #Results;
with udf_column_count AS (
  select 
   count(*) udf_column_count
-- LABEL, DATA_TYPE, * 
FROM USER_DEF_FIELDS WHERE PROGRAM_ID = 'VMMFGWIN_WO' 
and document_id is null
)

select CC.ColumnCount, udf_column_count 
, iif(CC.ColumnCount = udf_column_count, 'Match', iif(CC.ColumnCount < udf_column_count, 'Missing', 'Mismatch')) AS ColumnComparison
from udf_column_count
join #ColumnCount CC
on 1=1;

WITH Find_Missing_Columns AS (
-- would you find the missing columns for VMPRTMNT
-- no, too many in your result. We know it to be 15 - 17 = 2 missing columns

select 
 LABEL
FROM USER_DEF_FIELDS WHERE PROGRAM_ID = 'VMMFGWIN_WO' 
and document_id is null
    AND LABEL NOT IN ( 

        SELECT name AS COLUMN_NAME
        FROM tempdb.sys.columns
        WHERE object_id = object_id('tempdb..#Results')
    )
)
SELECT * FROM Find_Missing_Columns;


--select * from #Results;

/*
CTE_USER_DEF_FIELDS_TEST label set:
EM Revision
Expedite (Check for Yes)
New Part (Check for Yes)
EXP/FLT
QEA(EMPID-Initials): 
FAI Approval Date:
Label Required (Check for Yes)
CERTS REQUIRED


*/








 