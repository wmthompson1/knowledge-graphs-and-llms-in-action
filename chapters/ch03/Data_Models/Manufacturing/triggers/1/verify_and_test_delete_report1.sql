CREATE TABLE #ExpediteDeleteLog
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
		NULL,
		NULL,
		N'asc';

-- select * from #ExpediteDeleteLog;

SELECT
		LogDate,
		ProcessInfo,
		[Text]
FROM #ExpediteDeleteLog
ORDER BY LogDate DESC;

-- SELECT
-- 		AttemptDate = CONVERT(date, LogDate),
-- 		AttemptCount = COUNT_BIG(*)
-- FROM #ExpediteDeleteLog
-- GROUP BY CONVERT(date, LogDate)
-- ORDER BY AttemptDate DESC;

DROP TABLE #ExpediteDeleteLog;
GO