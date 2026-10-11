-- Verify and test report for unauthorized Expedite insert attempts
CREATE TABLE #ExpediteInsertLog
(
		LogDate datetime,
		ProcessInfo nvarchar(50),
		[Text] nvarchar(max)
);

INSERT #ExpediteInsertLog
EXEC master.dbo.xp_readerrorlog
		0,
		1,
		N'Unauthorized Expedite insert attempt. Login=',
		NULL,
		NULL,
		NULL,
		N'asc';

SELECT
		LogDate,
		ProcessInfo,
		[Text]
FROM #ExpediteInsertLog
ORDER BY LogDate DESC;

-- SELECT
-- 		AttemptDate = CONVERT(date, LogDate),
-- 		AttemptCount = COUNT_BIG(*)
-- FROM #ExpediteInsertLog
-- GROUP BY CONVERT(date, LogDate)
-- ORDER BY AttemptDate DESC;

DROP TABLE #ExpediteInsertLog;
GO