-- Report: QUALITY > DEPARTMENT DEFECTS
-- Description: This report retrieves department defects from the NCM (Non-Conformance Management) system, including details about the product, customer, production order, defect, disposition, and related metadata.
/**********************************************************************************************
Description:
Sample:
Date      Modified By      Change Description
---------- ------------------ ------------------------------------------------------------
2026-09-17 GitHub Copilot     Per user-request-20260917.md: Assigned_to now sources the Operator
                              (MADE_BY_EMPLOYEE_ID, formatted 'ID - First Last' via LIVE.dbo.EMPLOYEE,
                              matching the OPERATOR field expression used on the NCM website reports)
                              instead of DISPOSITION_ASSIGNED_TO_EMPLOYEE_ID; added blank FEATURE
                              column to align with the IQM report; added REWORK_STEPS aggregated from
                              NCM.dbo.NCM_REWORK_STEP; renamed DISPOSITION alias to DISPOSITION_NOTES.
**********************************************************************************************/

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET DEADLOCK_PRIORITY LOW
IF OBJECT_ID('tempdb..#Results') IS NOT NULL DROP TABLE #Results

declare @startDate DATETIME2(7) = SYSDATETIME()
declare @endDate DATETIME2(7) = SYSDATETIME()
declare @Assigned_TO NVARCHAR(MAX) = '_Blank' -- placeholder for assigned operators filter
declare @ncmtype NVARCHAR(MAX) = '_Blank' -- placeholder for NCM type filter
declare @ncmstatus NVARCHAR(MAX) = '_Blank' -- placeholder for NCM status filter
declare @disptype NVARCHAR(MAX) = '_Blank' -- placeholder for disposition type filter
declare @process NVARCHAR(MAX) = '_Blank' -- placeholder for process filter
declare @subprocess NVARCHAR(MAX) = '_Blank' -- placeholder for subprocess filter
declare @busunit NVARCHAR(MAX) = '_Blank' -- placeholder for business unit filter
declare @defect NVARCHAR(MAX) = '_Blank' -- placeholder for defect filter


SELECT
    NCM.[NCM_NUMBER] AS [NCM_ID]
  , NCM.[PART_ID] AS [PRODUCT_ID]
  , COA.[CUSTOMER_ID]
  , CONCAT(
      COALESCE(NULLIF(NCM.[BASE_ID], ''), NCM.[NCM_NUMBER]),
      '/',
      COALESCE(NULLIF(NCM.[LOT_ID], ''), '1')
    ) AS [PRODUCTION_ORDER_ID]
  , NCM.[LOT_SIZE]
  , NCM.[ACCEPTED]
  , NCM.[REJECTED]
  , NCM.[NCM_DATE]
  , NCM.[AS_IS_DIMENSION] AS [ASIS_DIM]
  , NCM.[SHOULD_BE_DIMENSION] AS [SHOULD_BE_DIM]
  , ISNULL(NCM.[PROCESS_ID], '') AS [PROCESS]
  , ISNULL(NCM.[SUBPROCESS_ID], '') AS [SUBPROCESS]
  , ISNULL(NCM.[DEFECT_ID], '') AS [DEFECT]
  , CAST(NULL AS NVARCHAR(60)) AS [FEATURE] -- blank placeholder to column-align with the IQM report for copy/paste
  , ISNULL(NCM.[DISPOSITION_TYPE_CODE], '') AS [DISPOSITION_TYPE]
  , NCM.[DISPOSITION_NOTES] AS [DISPOSITION_NOTES]
  , ISNULL(NCM.[DISPOSITION_BY_EMPLOYEE_ID], '_Blank') AS [DISP_BY]
  , ISNULL(RWK.[REWORK_STEPS], '_Blank') AS [REWORK_STEPS]
  , ISNULL(MADE_EE.[ID] + ' - ' + MADE_EE.[FIRST_NAME] + ' ' + MADE_EE.[LAST_NAME], '_Blank') AS [Assigned_to]
  , ISNULL(NCM.[NCM_STATUS], '') AS [NCM_STATUS]
  , ISNULL(NCM.[TAG_AREA], '') AS [BUSINESS_UNIT]
  , ISNULL(NCM.[NCM_TYPE_CODE], '') AS [NCM_TYPE]
  , NCM.[ROOT_CAUSE_TEXT] AS [SK_ROOT_CAUSE]
  , NCM.[CORRECTION_TEXT] AS [SK_ROOT_CAUSE_ANALYSIS]
  , P.[PLANNER_USER_ID]
FROM NCM.[dbo].[NONCONFORMANCE] NCM
LEFT JOIN [LIVE].[dbo].[PART] P
    ON P.[ID] = NCM.[PART_ID]
-- Operator: the employee who made/reported the NCM (matches the OPERATOR field expression on the NCM website reports), replaces DISPOSITION_ASSIGNED_TO_EMPLOYEE_ID
LEFT JOIN [LIVE].[dbo].[EMPLOYEE] MADE_EE
    ON NCM.[MADE_BY_EMPLOYEE_ID] = CAST(MADE_EE.[ID] AS NVARCHAR(50))
OUTER APPLY (
    SELECT TOP (1)
        CO.[CUSTOMER_ID]
    FROM [LIVE].[dbo].[DEMAND_SUPPLY_LINK] DSL
    INNER JOIN [LIVE].[dbo].[CUSTOMER_ORDER] CO
        ON CO.[ID] = DSL.[DEMAND_BASE_ID]
    WHERE DSL.[SUPPLY_BASE_ID] = NCM.[BASE_ID]
      AND DSL.[SUPPLY_LOT_ID]  = NCM.[LOT_ID]
      AND DSL.[DEMAND_TYPE]    = 'CO'
    ORDER BY DSL.[DEMAND_BASE_ID]
) COA
-- Rework steps: all step rows logged against this NCM in NCM.dbo.NCM_REWORK_STEP
OUTER APPLY (
    SELECT STRING_AGG(RS.[OPERATION], ', ') WITHIN GROUP (ORDER BY RS.[NCM_REWORK_STEP_ID]) AS [REWORK_STEPS]
    FROM NCM.[dbo].[NCM_REWORK_STEP] RS
    WHERE RS.[NONCONFORMANCE_ID] = NCM.[NONCONFORMANCE_ID]
      AND NULLIF(RS.[OPERATION], '') IS NOT NULL
) RWK
WHERE ISNULL(NCM.[NCM_TYPE_CODE], '_Blank') IN (@NCMTYPE)
  AND ISNULL(NCM.[NCM_STATUS], '_Blank') IN (@NCMSTATUS)
  AND ISNULL(NCM.[DISPOSITION_TYPE_CODE], '_Blank') IN (@DISPTYPE)
  AND ISNULL(NCM.[PROCESS_ID], '_BLANK') IN (@PROCESS)
  AND ISNULL(NCM.[SUBPROCESS_ID], '_BLANK') IN (@SUBPROCESS)
  AND ISNULL(NCM.[TAG_AREA], '_Blank') IN (@BUSUNIT)
  AND ISNULL(NCM.[DEFECT_ID], '_Blank') IN (@DEFECT)
  AND NCM.[NCM_DATE] >= @StartDate
  AND NCM.[NCM_DATE] <= @EndDate
  AND ISNULL(NCM.[MADE_BY_EMPLOYEE_ID], '_Blank') IN (@Assigned_TO)