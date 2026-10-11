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
 CTE_USER_DEF_FIELDS_VMPRTMNT AS (
     SELECT
         DOCUMENT_ID,
         -- please change the values on lines 77-93 to match the desired labels
         MAX(CASE WHEN ID = 'UDF-0000026' THEN STRING_VAL ELSE NULL END) AS [Surface Area (sq in)],
         MAX(CASE WHEN ID = 'UDF-0000035' THEN STRING_VAL ELSE NULL END) AS [Material Type],
         MAX(CASE WHEN ID = 'UDF-0000036' THEN STRING_VAL ELSE NULL END) AS [Alloy],
         MAX(CASE WHEN ID = 'UDF-0000037' THEN STRING_VAL ELSE NULL END) AS [Length],
         MAX(CASE WHEN ID = 'UDF-0000038' THEN STRING_VAL ELSE NULL END) AS [Width],

         MAX(CASE WHEN ID = 'UDF-0000039' THEN STRING_VAL ELSE NULL END) AS [Thickness],
         MAX(CASE WHEN ID = 'UDF-0000040' THEN BOOL_VAL ELSE NULL END) AS [ITAR Controlled (Yes if checked)],
         MAX(CASE WHEN ID = 'UDF-0000082' THEN STRING_VAL ELSE NULL END) AS [Controlled],
         MAX(CASE WHEN ID = 'UDF-0000084' THEN STRING_VAL ELSE NULL END) AS [Certifications Needed],
         MAX(CASE WHEN ID = 'UDF-0000085' THEN STRING_VAL ELSE NULL END) AS [Used on Part ID],

         MAX(CASE WHEN ID = 'UDF-0000091' THEN STRING_VAL ELSE NULL END) AS [Limited Scope],
         MAX(CASE WHEN ID = 'UDF-0000092' THEN STRING_VAL ELSE NULL END) AS [Primer],
         MAX(CASE WHEN ID = 'UDF-0000098' THEN STRING_VAL ELSE NULL END) AS [Topcoat 2],
         MAX(CASE WHEN ID = 'UDF-0000099' THEN STRING_VAL ELSE NULL END) AS [Topcoat],
		 MAX(CASE WHEN ID = 'UDF-0000101' THEN STRING_VAL ELSE NULL END) AS [QC Notes:],

         MAX(CASE WHEN ID = 'UDF-0000103' THEN STRING_VAL ELSE NULL END) AS [Frozen Process],
         MAX(CASE WHEN ID = 'UDF-00115' THEN STRING_VAL ELSE NULL END) AS [Supplier Controlled Drawing],
         MAX(CASE WHEN ID = 'UDF-00116' THEN STRING_VAL ELSE NULL END) AS [New User Defined Field]

         --,add missing user defined fields here as needed - Topcoat 2, Topcoat, QC Notes, Frozen Process, Supplier Controlled Drawing

     FROM USER_DEF_FIELDS
     WHERE PROGRAM_ID = 'VMPRTMNT'
     GROUP BY DOCUMENT_ID
 )

 ,CTE_USER_DEF_FIELDS_VMMFGWIN_WO AS (
    SELECT
        DOCUMENT_ID,
        MAX(CASE WHEN ID = 'UDF-0000086' THEN BOOL_VAL END)   AS [FAI Complete ?]
    FROM Live.dbo.USER_DEF_FIELDS
    WHERE PROGRAM_ID = 'VMMFGWIN_WO'
    AND [LABEL] IS NULL
    GROUP BY DOCUMENT_ID


 ), VMPRTMNT AS ( 
SELECT 
 1 CountOf
 -- would you create a virtual table so I can check the count of columns against
 -- select count(*) FROM USER_DEF_FIELDS WHERE PROGRAM_ID = 'VMPRTMNT' and program_id is null
    , UI.DOCUMENT_ID AS ID  -- alias for name of actual key
    , UI.[Surface Area (sq in)]
    , UI.[Material Type]
    , UI.Alloy
    , UI.[Length]
    , UI.[Width]
    , UI.[Thickness]
    , UI.[ITAR Controlled (Yes if checked)]
    , UI.[Controlled]
    , UI.[Certifications Needed]
    , UI.[Used on Part ID]
    , UI.[Limited Scope]
    , UI.[Primer]
    , UI.[Topcoat 2]
    , UI.[Topcoat]
    , UI.[QC Notes:]
    , UI.[Frozen Process]
    , UI.[Supplier Controlled Drawing]



FROM CTE_USER_DEF_FIELDS_VMPRTMNT UI
WHERE 1=1
 )
select * from VMPRTMNT;
-- select * from #Results;








 