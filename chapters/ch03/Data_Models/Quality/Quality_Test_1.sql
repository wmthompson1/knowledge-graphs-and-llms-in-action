-- Option A: Use OPENQUERY to push filtering to the remote server.
-- OPENQUERY requires a literal query string; it cannot accept a variable.
SELECT *
INTO #PO
FROM OPENQUERY([sql-bi-1], '
	SELECT RECORD_ID, ALT_ID_1, ALT_ID_2, ALT_ID_3, ALT_ID_4, ALT_ID_5
	FROM datawarehouse.dbo.VQ_PRODUCTION_ORDER
');
CREATE INDEX IX_PO ON #PO(ALT_ID_2, ALT_ID_3, ALT_ID_4, ALT_ID_5, ALT_ID_1);

-- Then join to #PO instead of remote table