
USE NCM --
GO


/**********************************************************************************************

Description:  
Note:   


Date        Modified By         Change Description
----------  ------------------  ------------------------------------------------------------
09/02/26    William Thompson    Created.

**********************************************************************************************/

DECLARE @Tester int
declare @part_id nvarchar(250) = NULL; -- --  '313Z7430-504';  -- '313Z7430-504' '70750B-071-MIL-NG';
Set @Tester = 0
DECLARE @workorder_base_id nvarchar(30) = NULL; -- -- 
Declare @resource_id nvarchar(30) = NULL;  -- -- 
DECLARE @NCM_NUMBER NVARCHAR(30) = '50668';
declare @STARTDATE date = '2026-01-01';
declare @ENDDATE date = GETDATE();
declare @DEPARTMENT nvarchar(50) = 'cnc'
declare @FACILITY nvarchar(50) = 'ap2'

select * 

FROM NCM.[dbo].[NONCONFORMANCE] NCM
LEFT OUTER JOIN NCM.[dbo].[DISPOSITION_TYPE] DT
  ON DT.[DISPOSITION_TYPE_CODE] = NCM.[DISPOSITION_TYPE_CODE]
LEFT OUTER JOIN NCM.[dbo].[EMPLOYEE_LOOKUP] MADE_EE
  ON MADE_EE.[EMPLOYEE_ID] = NCM.[MADE_BY_EMPLOYEE_ID]
LEFT OUTER JOIN NCM.[dbo].[EMPLOYEE_LOOKUP] ASSGN_EE
  ON ASSGN_EE.[EMPLOYEE_ID] = NCM.[ASSIGNED_TO_EMPLOYEE_ID]
LEFT OUTER JOIN NCM.[dbo].[EMPLOYEE_LOOKUP] DISP_EE
  ON DISP_EE.[EMPLOYEE_ID] = NCM.[DISPOSITION_BY_EMPLOYEE_ID]
LEFT OUTER JOIN NCM.[dbo].[EMPLOYEE_LOOKUP] DISP_ASSG
  ON DISP_ASSG.[EMPLOYEE_ID] = NCM.[DISPOSITION_ASSIGNED_TO_EMPLOYEE_ID]
LEFT OUTER JOIN NCM.[dbo].[EMPLOYEE_LOOKUP] VERIFY_BY_EE
  ON VERIFY_BY_EE.[EMPLOYEE_ID] = NCM.[VERIFIED_BY_EMPLOYEE_ID]
WHERE NCM.[NCM_NUMBER] = @NCM_NUMBER