-- quality_core_iqm
/**********************************************************************************************

Description:  CommBoard Quality (Department)_1.2.sql
Note:   
   

Date        Modified By         Change Description
----------  ------------------  ------------------------------------------------------------


**********************************************************************************************/


SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET DEADLOCK_PRIORITY LOW

IF OBJECT_ID('tempdb..#Results') IS NOT NULL DROP TABLE #Results


--declare @STARTDATE date = DATEADD(WEEK, DATEDIFF(WEEK, 7, GETDATE()), 0);
declare @STARTDATE date = CONVERT(DATE, DATEADD(QQ, DATEDIFF(QQ, 0, GETDATE()), 0))
--declare @ENDDATE date = DATEADD(WEEK, DATEDIFF(WEEK, 7, GETDATE()), 6);
declare @ENDDATE date = CONVERT(DATE, DATEADD(DD, -1, DATEADD(QQ, DATEDIFF(QQ, 0, GETDATE()) + 1, 0)))

-- in test
declare @timeframe nvarchar(25) =  'CURRENT QUARTER'  -- -- 'LAST QUARTER';  -- -- 'LAST YEAR'; -- -- 'LAST WEEK'; 
declare @LISTTYPE nvarchar(25) = 'DEFECTS';
-- 

declare @DEPARTMENT nvarchar(50) = 'CNC';
declare @FACILITY nvarchar(50) = 'AP2';
DECLARE @IQM_PROCESS NVARCHAR(50) = 'ALL';
DECLARE @IQM_DEFECT NVARCHAR(50) = 'ALL';

DECLARE @Tester int
declare @part_id nvarchar(250) = NULL; -- --  '313Z7430-504';  -- '313Z7430-504' '70750B-071-MIL-NG';
Set @Tester = 0
DECLARE @workorder_base_id nvarchar(30) = NULL; -- -- 
Declare @resource_id nvarchar(30) = NULL;  -- -- 
DECLARE @NCM_NUMBER NVARCHAR(30) = NULL; -- '50668';

SELECT 
     ISNULL(NCM.USER_DEFINED_4, NCM.USER_DEFINED_7) AS DEFECT
   , NCM.NCM_ID 
   , NCM.NCM_TYPE 
   , NCM.DISPOSITION_TYPE 
   , NCM.SITE_ID
-- OPS
   , cast(O.CLOSE_DATE as date) CLOSE_DATE 
   , O.[STATUS] -- != 'X'
-- Ops Resource
   , SR.USER_6  -- != 'PENETRANT'
   , SR.USER_8  -- IN (@DEPARTMENT)
   , SR.USER_5  -- IN (@FACILITY)
--FROM OPERATION O
--INNER JOIN SHOP_RESOURCE SR
--	ON SR.ID = O.RESOURCE_ID
	FROM [sql-lab-2].live.DBO.OPERATION O
	INNER JOIN [sql-lab-2].live.DBO.SHOP_RESOURCE_SITE SR
		ON SR.RESOURCE_ID = O.RESOURCE_ID
INNER JOIN 
[sql-bi-1].datawarehouse.dbo.VQ_PRODUCTION_ORDER PO
	ON PO.[ALT_ID_2] = O.WORKORDER_BASE_ID
	AND PO.[ALT_ID_3] = O.WORKORDER_LOT_ID
	AND PO.[ALT_ID_4] = O.WORKORDER_SPLIT_ID
	AND PO.[ALT_ID_5] = O.WORKORDER_SUB_ID
	AND PO.[ALT_ID_1] = O.WORKORDER_TYPE
INNER JOIN 
[SQL-BI-1].datawarehouse.dbo.VQ_OPERATION OI
	ON OI.[ID] = CAST(O.WORKORDER_TYPE AS NVARCHAR(1)) + '~' + CAST(O.WORKORDER_BASE_ID AS NVARCHAR(7)) + '~' 
		+ CAST(O.WORKORDER_LOT_ID AS NVARCHAR(1)) + '~' + CAST(O.WORKORDER_SPLIT_ID AS NVARCHAR(1)) + '~' 
		+ CAST(O.WORKORDER_SUB_ID AS NVARCHAR(1)) + '~' + CAST(O.SEQUENCE_NO AS NVARCHAR(5))
INNER JOIN 
[sql-bi-1].datawarehouse.dbo.VQ_NONCONFORMANCE NCM
	ON PO.RECORD_ID = NCM.PROD_ORDER_REC_ID
	AND OI.RECORD_ID = NCM.OPERATION_REC_ID
INNER JOIN 
[sql-bi-1].datawarehouse.dbo.VQ_PRODUCT P
	ON P.RECORD_ID = NCM.PRODUCT_REC_ID
WHERE 1=1 
    and cast(O.CLOSE_DATE as date) >= @STARTDATE
	AND cast(O.CLOSE_DATE as date) <= @ENDDATE
	AND (NCM.SITE_ID = 'SK01' OR NCM.SITE_ID IS NULL)
	AND NCM.NCM_ID IS NOT NULL
	AND NCM.NCM_TYPE NOT IN ('OVERAGE')
	AND NCM.DISPOSITION_TYPE NOT IN ('NON-DISCREPANT', 'OVERAGE')
	AND SR.USER_6 != 'PENETRANT'
	AND SR.USER_8 IN (@DEPARTMENT)
	AND SR.USER_5 IN (@FACILITY)
	AND O.[STATUS] != 'X'
;