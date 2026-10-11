-- VMDOCMNT

/**********************************************************************************************
Description: VMDOCMNT
Sample:
Date      Modified By      Change Description
---------- ------------------ ------------------------------------------------------------
08/12/2026  William T          Initial creation

boolval is a bit field, 1 = true, 0 = false
[ITAR Controlled (Yes if checked)]
**********************************************************************************************/

DECLARE @PROGRAM_ID NVARCHAR(50) = 'VMDOCMNT';
IF OBJECT_ID('tempdb..#Results') IS NOT NULL DROP TABLE #Results;

declare @BASE_ID NVARCHAR(50) = NULL; -- 'BACB30FM6-7';
DECLARE @LOT_ID NVARCHAR(50) = NULL;  ---'1';
declare @PART_ID NVARCHAR(50) = NULL; -- 'BACB30FM6-7';
DECLARE @VENDOR_ID NVARCHAR(50) = NULL;  ---'3VPREC';
declare @PURC_ORD_ID NVARCHAR(50) = NULL; --- '180033';
declare @cc_in nvarchar(255) = 'raw material, Standards, Details';
DECLARE @START_DATE DATE = '2026-05-01'; 
DECLARE @END_DATE DATE = GETDATE();

wITH udf AS (

SELECT
       1 AS CountOf
       , DOCUMENT_ID AS ID
    , MAX(CASE WHEN ID = 'UDF-0000031' THEN STRING_VAL ELSE NULL END) AS [Location]
    , MAX(CASE WHEN ID = 'UDF-0000032' THEN STRING_VAL ELSE NULL END) AS [ADCN]
    , MAX(CASE WHEN ID = 'UDF-0000033' THEN STRING_VAL ELSE NULL END) AS [Serial Number]
    , MAX(CASE WHEN ID = 'UDF-0000034' THEN STRING_VAL ELSE NULL END) AS [MFG Note]
    , MAX(CASE WHEN ID = 'UDF-0000050' THEN STRING_VAL ELSE NULL END) AS [Property]
    , MAX(CASE WHEN ID = 'UDF-0000051' THEN BOOL_VAL ELSE NULL END) AS [ITAR Controlled (Yes if checked)]
    , MAX(CASE WHEN ID = 'UDF-0000052' THEN STRING_VAL ELSE NULL END) AS [Status]
    , MAX(CASE WHEN ID = 'UDF-0000053' THEN STRING_VAL ELSE NULL END) AS [Received Date]
    , MAX(CASE WHEN ID = 'UDF-0000054' THEN STRING_VAL ELSE NULL END) AS [Stamped Revision]
    , MAX(CASE WHEN ID = 'UDF-0000055' THEN STRING_VAL ELSE NULL END) AS [Number of Pieces]
    , MAX(CASE WHEN ID = 'UDF-0000056' THEN STRING_VAL ELSE NULL END) AS [Usage Instructions]
    , MAX(CASE WHEN ID = 'UDF-0000057' THEN STRING_VAL ELSE NULL END) AS [AUTM]
    , MAX(CASE WHEN ID = 'UDF-0000058' THEN STRING_VAL ELSE NULL END) AS [Category]
    , MAX(CASE WHEN ID = 'UDF-0000059' THEN STRING_VAL ELSE NULL END) AS [Current Location]
FROM Live.dbo.USER_DEF_FIELDS
WHERE PROGRAM_ID = @PROGRAM_ID
AND DOCUMENT_ID IS NOT NULL
GROUP BY DOCUMENT_ID)

SELECT * FROM udf;
