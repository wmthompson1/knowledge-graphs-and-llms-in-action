USE [LIVE];
GO

/**********************************************************************************************
Description: Daily unauthorized Expedite update, delete, and insert attempt report.

Set @DailyStartDate to the date to report. The report includes events from midnight on that
date up to, but not including, midnight on the following date.
**********************************************************************************************/
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SET DEADLOCK_PRIORITY LOW;

DECLARE @DailyStartDate date = CONVERT(date, GETDATE());
DECLARE @StartDateTime datetime = CONVERT(datetime, @DailyStartDate);
DECLARE @EndDateTime datetime = DATEADD(day, 1, @StartDateTime);

CREATE TABLE #ExpediteDeleteLog
(
	LogDate datetime,
	ProcessInfo nvarchar(50),
	[Text] nvarchar(max)
);

CREATE TABLE #ExpediteInsertLog
(
	LogDate datetime,
	ProcessInfo nvarchar(50),
	[Text] nvarchar(max)
);

INSERT #ExpediteDeleteLog
EXEC master.dbo.xp_readerrorlog
	0,
	1,
	N'Unauthorized Expedite delete attempt. Login=',
	NULL,
	@StartDateTime,
	@EndDateTime,
	N'asc';

INSERT #ExpediteInsertLog
EXEC master.dbo.xp_readerrorlog
	0,
	1,
	N'Unauthorized Expedite insert attempt. Login=',
	NULL,
	@StartDateTime,
	@EndDateTime,
	N'asc';

;WITH UpdateAttempts AS
(
	SELECT
		EventType = CAST(N'UPDATE' AS nvarchar(10)),
		t.LogDate,
		ProcessInfo = CAST(NULL AS nvarchar(50)),
		[Text] = CAST(
			N'Unauthorized Expedite update attempt. Login=' + t.LoginName
			+ N', Document=' + ISNULL(u.DOCUMENT_ID, N'NULL')
			+ N', AttemptedValue=' + ISNULL(t.NewValue, N'NULL')
			+ N', ActualValue=' + ISNULL(u.STRING_VAL, N'NULL')
			AS nvarchar(max)
		)
	FROM [LIVE].[dbo].[TriggerDebug] AS t
	INNER JOIN [LIVE].[dbo].[USER_DEF_FIELDS] AS u
		ON u.ROWID = t.ROWID
	LEFT JOIN [LIVE].[dbo].[PERSON] AS p
		ON p.ID = REPLACE(
			STUFF(t.LoginName, 1, CHARINDEX(N'\', t.LoginName), N''),
			N'#',
			N''
		)
	WHERE t.LogDate >= @StartDateTime
	  AND t.LogDate < @EndDateTime
	  AND ISNULL(p.IS_APPROVER, N'N') <> N'Y'
),
DeleteAttempts AS
(
	SELECT
		EventType = CAST(N'DELETE' AS nvarchar(10)),
		LogDate,
		ProcessInfo,
		[Text]
	FROM #ExpediteDeleteLog
	WHERE LogDate >= @StartDateTime
	  AND LogDate < @EndDateTime
),
InsertAttempts AS
(
	SELECT
		EventType = CAST(N'INSERT' AS nvarchar(10)),
		LogDate,
		ProcessInfo,
		[Text]
	FROM #ExpediteInsertLog
	WHERE LogDate >= @StartDateTime
	  AND LogDate < @EndDateTime
),
AllAttempts AS
(
	SELECT EventType, LogDate, ProcessInfo, [Text]
	FROM UpdateAttempts

	UNION ALL

	SELECT EventType, LogDate, ProcessInfo, [Text]
	FROM DeleteAttempts

	UNION ALL

	SELECT EventType, LogDate, ProcessInfo, [Text]
	FROM InsertAttempts
)
SELECT
	ReportDate = @DailyStartDate,
	EventType,
	LogDate,
	ProcessInfo,
	[Text]
FROM AllAttempts
ORDER BY LogDate DESC, EventType;

DROP TABLE #ExpediteDeleteLog;
DROP TABLE #ExpediteInsertLog;
GO