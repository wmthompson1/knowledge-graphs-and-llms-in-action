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

-- I created a new ID under udf = PROGRAM_ID  -- > [Vendor Risk] --  > UDF-00118
-- l=2,t=SK_VENDORRISK,c=RISK,o=1

SELECT  
       PROGRAM_ID  -- > [Vendor Risk]
      ,[ID]
      ,[DOCUMENT_ID]
      ,[LABEL]
      ,[DATA_TYPE]
      ,[STRING_VAL]
  FROM [LIVE].[dbo].[USER_DEF_FIELDS]
  where [PROGRAM_ID] like 'VMVNDMNT%'
  and id = 'UDF-00118'
  and document_id is null

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
(SELECT DISTINCT v.ID
FROM VENDOR v
JOIN CTE_PO po
ON Po.VENDOR_ID = V.ID
WHERE 1=1   
AND (v.ID = @VENDOR_ID OR @VENDOR_ID IS NULL)
),
 CTE_USER_DEF_FIELDS_VMPRTMNT AS (
     SELECT
         DOCUMENT_ID,
         MAX(CASE WHEN ID = 'UDF-0000026' THEN STRING_VAL ELSE NULL END) AS [Surface Area],
         MAX(CASE WHEN ID = 'UDF-0000035' THEN STRING_VAL ELSE NULL END) AS [Material Type],
         MAX(CASE WHEN ID = 'UDF-0000036' THEN STRING_VAL ELSE NULL END) AS [Alloy],
         MAX(CASE WHEN ID = 'UDF-0000037' THEN STRING_VAL ELSE NULL END) AS [Length],
         MAX(CASE WHEN ID = 'UDF-0000038' THEN STRING_VAL ELSE NULL END) AS [Width],
         MAX(CASE WHEN ID = 'UDF-0000039' THEN STRING_VAL ELSE NULL END) AS [Thickness],
         MAX(CASE WHEN ID = 'UDF-0000040' THEN BOOL_VAL ELSE NULL END) AS [ITAR],
         MAX(CASE WHEN ID = 'UDF-0000082' THEN STRING_VAL ELSE NULL END) AS [SK-PUR CONTROLLED],
         MAX(CASE WHEN ID = 'UDF-0000084' THEN STRING_VAL ELSE NULL END) AS [SK-PUR Cert Needed],
         MAX(CASE WHEN ID = 'UDF-0000085' THEN STRING_VAL ELSE NULL END) AS [Used on Part ID],
         MAX(CASE WHEN ID = 'UDF-0000091' THEN STRING_VAL ELSE NULL END) AS [Limited Scope],
         MAX(CASE WHEN ID = 'UDF-0000092' THEN STRING_VAL ELSE NULL END) AS [SK-FIN Primer],
         MAX(CASE WHEN ID = 'UDF-0000098' THEN STRING_VAL ELSE NULL END) AS [SK-FIN Topcoat],
         MAX(CASE WHEN ID = 'UDF-0000099' THEN STRING_VAL ELSE NULL END) AS [SK-FIN Topcoat 2],
		 MAX(CASE WHEN ID = 'UDF-0000101' THEN STRING_VAL ELSE NULL END) AS [qc_notes]

     FROM USER_DEF_FIELDS
     WHERE PROGRAM_ID = 'VMPRTMNT'
     GROUP BY DOCUMENT_ID
 )
 ,CTE_USER_DEF_FIELDS_VMVNDMNT AS (
        SELECT
                DOCUMENT_ID,
                MAX(CASE WHEN ID = 'UDF-0000090' THEN BOOL_VAL END) AS [HasVndLimited],
                MAX(CASE WHEN ID = 'UDF-0000093' THEN STRING_VAL END) AS [VendorCertKey1],
                MAX(CASE WHEN ID = 'UDF-0000094' THEN STRING_VAL END) AS [VendorCertExp1],
                MAX(CASE WHEN ID = 'UDF-0000095' THEN STRING_VAL END) AS [VendorCertKey2],
                MAX(CASE WHEN ID = 'UDF-0000096' THEN STRING_VAL END) AS [VendorCertExp2],
                MAX(CASE WHEN ID = 'UDF-0000097' THEN STRING_VAL END) AS [VendorCertKey3],
                MAX(CASE WHEN ID = 'UDF-0000098' THEN STRING_VAL END) AS [VendorCertExp3],
                MAX(CASE WHEN ID = 'UDF-0000102' THEN STRING_VAL END) AS [VendorQCNotes],
                MAX(CASE WHEN ID = 'UDF-00118' THEN STRING_VAL END) AS [Vendor Risk]
        FROM [LIVE].[dbo].[USER_DEF_FIELDS]
        WHERE PROGRAM_ID = 'VMVNDMNT'
            AND [LABEL] IS NULL
        GROUP BY DOCUMENT_ID
 )
-- -- VMMFGWIN_WO
 ,CTE_USER_DEF_FIELDS_VMMFGWIN_WO AS (
    SELECT
        DOCUMENT_ID,
        MAX(CASE WHEN ID = 'UDF-0000086' THEN BOOL_VAL END)   AS [FAI Complete ?]
    FROM Live.dbo.USER_DEF_FIELDS
    WHERE PROGRAM_ID = 'VMMFGWIN_WO'
    AND [LABEL] IS NULL
    GROUP BY DOCUMENT_ID


 )

SELECT
    v.ID AS [Vendor ID],
    v.[NAME] AS [Vendor Name],
    udf.[Vendor Risk],
    udf.[HasVndLimited],
    udf.[VendorQCNotes],
    udf.[VendorCertKey1],
    udf.[VendorCertExp1],
    udf.[VendorCertKey2],
    udf.[VendorCertExp2],
    udf.[VendorCertKey3],
    udf.[VendorCertExp3]
FROM CTE_VENDOR AS cv
INNER JOIN [LIVE].[dbo].[VENDOR] AS v
    ON v.ID = cv.ID
LEFT JOIN CTE_USER_DEF_FIELDS_VMVNDMNT AS udf
    ON udf.DOCUMENT_ID = v.ID
ORDER BY v.ID;
 