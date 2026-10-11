
/*
please create the union from Quality Database #2 SQL
see Documentation\plan\plan-021-quality-database-1-iqm-schema -->
Documentation\plan\plan-020-quality-database-2-schema
use the mapping documents  created by SME:
Documentation\Schema\Data_Models\Quality\Mapping – Old Quality IQM To New Quality NCM.docx
utoilize availabletools in existing code base.

*/

DECLARE @date1 date = '09/01/2026';
DECLARE @date2 date = '09/07/2026';

-- Quality database #1: SQL-IQM-9 / IQM_Baseline_App
SELECT
		CAST(NCM_ID AS nvarchar(30)) AS NCM_ID,
		DISPOSITION_TYPE,
		DATEPART(WEEK, DATEADD(DAY, -1, NCM_DATE)) AS [week],
		DATEPART(MONTH, NCM_DATE) AS [month],
		CONVERT(varchar(7), DATEPART(MONTH, NCM_DATE)) + ' - ' + CONVERT(varchar(4), DATEPART(YEAR, NCM_DATE)) AS [m/yyyy],
		NCM_DATE,
		NCM_TYPE,
		SK_FIN_NCM_PROCESS
FROM [SQL-IQM-9].[IQM_Baseline_App].[dbo].[VQ_NONCONFORMANCE] WITH (NOLOCK)
WHERE STATUS = 'Closed'
	AND DISPOSITION_TYPE IN ('REWORK', 'CONTINUE')
	AND NCM_TYPE <> 'OVERAGE'
	AND SK_FIN_NCM_PROCESS = 'Paint'
	AND NCM_DATE >= @date1
	AND NCM_DATE <= @date2

UNION ALL

-- Quality database #2: sql-lab-2 / NCM
SELECT
		CAST(NCM_NUMBER AS nvarchar(30)) AS NCM_ID,
		DISPOSITION_TYPE_CODE AS DISPOSITION_TYPE,
		DATEPART(WEEK, DATEADD(DAY, -1, NCM_DATE)) AS [week],
		DATEPART(MONTH, NCM_DATE) AS [month],
		CONVERT(varchar(7), DATEPART(MONTH, NCM_DATE)) + ' - ' + CONVERT(varchar(4), DATEPART(YEAR, NCM_DATE)) AS [m/yyyy],
		NCM_DATE,
		NCM_TYPE_CODE AS NCM_TYPE,
		PROCESS_ID AS SK_FIN_NCM_PROCESS
FROM [sql-lab-2].[NCM].[dbo].[NONCONFORMANCE] WITH (NOLOCK)
WHERE NCM_STATUS = 'Closed'
	AND DISPOSITION_TYPE_CODE IN ('REWORK', 'CONTINUE')
	AND NCM_TYPE_CODE <> 'OVERAGE'
	AND PROCESS_ID = 'Paint'
	AND NCM_DATE >= @date1
	AND NCM_DATE <= @date2

ORDER BY NCM_DATE ASC;

