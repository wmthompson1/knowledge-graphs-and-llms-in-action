-- inadvertently skipped a few fields in the previous version of this file.  Added them here.  Also, changed the data type for ITAR Controlled to BOOL_VAL instead of STRING_VAL.  It is a bit field, so BOOL_VAL is more appropriate.
-- see Documentation\Schema\Data_Models\User_Defined\VM_Collection_All_User_Def_Fields_VMDOCMNT.sql
-- polymorphic query to pivot user-defined fields for document reference.  This is a generic query that can be used for any program_id, but it is currently hard-coded for VMDOCMNT.  The query can be modified to accept a program_id parameter if needed.

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
08/12/2026  William T          Initial creation
**********************************************************************************************/


SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET DEADLOCK_PRIORITY LOW
IF OBJECT_ID('tempdb..#Results') IS NOT NULL DROP TABLE #Results
if OBJECT_ID('tempdb..#program_id') IS NOT NULL DROP TABLE #program_id


declare @PART_ID NVARCHAR(50) = NULL; -- 'BACB30FM6-7';
DECLARE @VENDOR_ID NVARCHAR(50) = NULL;  ---'3VPREC';
declare @PURC_ORD_ID NVARCHAR(50) = NULL; --- '180033';
declare @cc_in nvarchar(255) = 'raw material, Standards, Details';
DECLARE @START_DATE DATE = '2026-05-01'; 
DECLARE @END_DATE DATE = GETDATE();

DECLARE @PROGRAM_ID_ROWID INT = 2;
DECLARE @PROGRAM_ID NVARCHAR(50) = NULL;


select
   ROW_NUMBER() over (order by PROGRAM_ID ) rn
   ,program_id
   into #program_id
from (
select 
 PROGRAM_ID
FROM USER_DEF_FIELDS --WHERE PROGRAM_ID = 'VMMFGWIN_WO' 
WHERE 1=1
AND PROGRAM_ID <> 'STATIC_DATA'
and document_id is null
GROUP BY PROGRAM_ID
) x
;

--select * from #program_id

SELECT @PROGRAM_ID = program_id
FROM #program_id
WHERE rn = @PROGRAM_ID_ROWID;   

IF @PROGRAM_ID IS NULL
BEGIN
       THROW 50000, 'No PROGRAM_ID found for the selected @PROGRAM_ID_ROWID.', 1;
END;

DECLARE @PivotColumns NVARCHAR(MAX);
DECLARE @DynamicSQL NVARCHAR(MAX);

SELECT @PivotColumns = STUFF((
       SELECT CHAR(13) + CHAR(10)
              + '    , MAX(CASE WHEN ID = ''' + REPLACE(ID, '''', '''''') + ''' THEN '
              + CASE
                     WHEN UPPER(CONVERT(NVARCHAR(50), DATA_TYPE)) IN ('B', 'BOOL', 'BOOLEAN', 'BIT')
                            OR LABEL LIKE '%(Check for Yes)%'
                            OR LABEL LIKE '%(Yes if checked)%'
                            THEN 'BOOL_VAL'
                     WHEN UPPER(CONVERT(NVARCHAR(50), DATA_TYPE)) IN ('D', 'DATE', 'DATETIME')
                            OR LABEL LIKE '%Date:%'
                            THEN 'DATE_VAL'
                     WHEN UPPER(CONVERT(NVARCHAR(50), DATA_TYPE)) IN ('N', 'NUMBER', 'NUMERIC', 'DECIMAL')
                            THEN 'NUMBER_VAL'
                     ELSE 'STRING_VAL'
                END
              + ' ELSE NULL END) AS ' + QUOTENAME(LTRIM(RTRIM(LABEL)))
       FROM USER_DEF_FIELDS
       WHERE PROGRAM_ID = @PROGRAM_ID
       AND DOCUMENT_ID IS NULL
       AND LABEL IS NOT NULL
       ORDER BY ID
       FOR XML PATH(''), TYPE
).value('.', 'NVARCHAR(MAX)'), 1, 0, '');

IF @PivotColumns IS NULL OR LEN(@PivotColumns) = 0
BEGIN
       THROW 50001, 'No user-defined field labels found for the selected @PROGRAM_ID.', 1;
END;

SET @DynamicSQL = N'
IF OBJECT_ID(''tempdb..#Results'') IS NOT NULL DROP TABLE #Results;

SELECT
       1 AS CountOf
       , DOCUMENT_ID AS ID'
       + @PivotColumns + N'
INTO #Results
FROM Live.dbo.USER_DEF_FIELDS
WHERE PROGRAM_ID = @PROGRAM_ID
AND DOCUMENT_ID IS NOT NULL
GROUP BY DOCUMENT_ID;

SELECT * FROM #Results;
';

PRINT 'Selected from #program_id:  ' + @PROGRAM_ID;
PRINT @DynamicSQL;

EXEC sys.sp_executesql
       @DynamicSQL,
       N'@PROGRAM_ID NVARCHAR(50)',
       @PROGRAM_ID = @PROGRAM_ID;

