/*
Verifying and Testing Unauthorized Expedite Delete Attempts
===========================================================

Purpose
-------
The dbo.trg_ProtectExpedite_Delete trigger protects Expedite values stored in
Live.dbo.USER_DEF_FIELDS. For an application login that is not an authorized
approver, the trigger builds a message in this form:

		Unauthorized Expedite delete attempt. Login=<login>, Document=<document>

It raises the message at severity 16 with RAISERROR ... WITH LOG and then rolls
back the transaction. WITH LOG writes the event to the SQL Server error log and
to the Windows Application log. The rollback is the enforcement control; the
error-log record is audit and diagnostic evidence that the control fired.

The trigger applies only when all of these conditions are true:

	1. SUSER_SNAME() ends in #, identifying the Visual Manufacturing application
		 login convention used by this implementation.
	2. The normalized login is not a dbo.PERSON row with IS_APPROVER = 'Y'.
	3. A deleted row has PROGRAM_ID = 'VMMFGWIN_WO'.
	4. That row has ID = 'UDF-0000070', the Expedite user-defined field.

An SSMS, SQL Agent, or ETL login whose name does not end in # is intentionally
ignored by the trigger. A test made under such a login is not a valid test of
the unauthorized application path and could delete the row. Use a nonproduction
database or an approved test record, and verify the execution identity before
issuing a DELETE.

Scope and safety
----------------
Run the examples against the SQL Server instance that hosts LIVE. Reading the
error log is instance-scoped, not database-scoped. The examples use fully
qualified object names so that the target is explicit.

Do not test by deleting an arbitrary production row. Prefer a restored test
database with the trigger installed. If production validation is unavoidable,
use a preapproved row and the real unauthorized application workflow. The
trigger itself should roll back a matching unauthorized delete, but a typo in
the predicates, an unexpected login name, or a disabled trigger can turn a
test into a real deletion.

Before testing, confirm the trigger is present and enabled:
*/

USE [LIVE];
GO

SELECT
		TriggerName = tr.[name],
		tr.[is_disabled],
		tr.[is_instead_of_trigger],
		ParentObject = QUOTENAME(OBJECT_SCHEMA_NAME(tr.[parent_id]))
				+ N'.' + QUOTENAME(OBJECT_NAME(tr.[parent_id]))
FROM sys.triggers AS tr
WHERE tr.[name] = N'trg_ProtectExpedite_Delete';
GO

/*
The expected result is one enabled AFTER trigger on dbo.USER_DEF_FIELDS. Review
the deployed definition as well; a source-control file does not prove what is
currently installed on the server.
*/

SELECT OBJECT_DEFINITION(OBJECT_ID(N'dbo.trg_ProtectExpedite_Delete'))
		AS DeployedTriggerDefinition;
GO

/*
1. Reading the SQL Server error log
-----------------------------------
The simplest call returns the current SQL Server error log:
*/

EXEC master.dbo.xp_readerrorlog;
GO

/*
That unfiltered result can be large. xp_readerrorlog accepts positional
parameters that allow the server to filter before returning rows:

	Parameter 1: archive number; 0 is current, 1 is the previous archive.
	Parameter 2: log type; 1 is the SQL Server log, 2 is the SQL Agent log.
	Parameter 3: first text filter.
	Parameter 4: second text filter; both text filters must match.
	Parameter 5: start date/time.
	Parameter 6: end date/time.
	Parameter 7: sort order, N'asc' or N'desc'.

Use the stable prefix rather than the full message because the login and
document portions vary on every event. The following is the primary query for
this control. Newest entries are returned first.
*/

EXEC master.dbo.xp_readerrorlog
		0,
		1,
		N'Unauthorized Expedite delete attempt. Login=',
		NULL,
		NULL,
		NULL,
		N'desc';
GO

/*
The returned columns are normally LogDate, ProcessInfo, and Text. Exact display
names can vary by SQL Server tooling and version. A matching Text value should
look similar to this example:

		Unauthorized Expedite delete attempt. Login=DOMAIN\jsmith#,
		Document=WO-104827

RAISERROR WITH LOG limits the portion written to the error log, so treat the
stable prefix and the leading identity fields as the reliable search surface.
The current trigger message is short enough for ordinary login and document
values, but future additions should keep the logging limit in mind.

To filter for a particular application login, use both search strings. SQL
Server applies them as an AND condition:
*/

DECLARE @LoginFilter nvarchar(255) = N'Login=DOMAIN\jsmith#';

EXEC master.dbo.xp_readerrorlog
		0,
		1,
		N'Unauthorized Expedite delete attempt. Login=',
		@LoginFilter,
		NULL,
		NULL,
		N'desc';
GO

/*
To find a specific work order or document, make the second filter the document
fragment instead. Replace WO-104827 with the expected DOCUMENT_ID.
*/

DECLARE @DocumentFilter nvarchar(255) = N'Document=WO-104827';

EXEC master.dbo.xp_readerrorlog
		0,
		1,
		N'Unauthorized Expedite delete attempt. Login=',
		@DocumentFilter,
		NULL,
		NULL,
		N'desc';
GO

/*
Date filtering is useful for a controlled test window. Capture the UTC/local
relationship before interpreting timestamps: the SQL Server error log normally
uses the server's local time. Adjust these sample values to the server clock.
*/

DECLARE @StartTime datetime = '2026-09-25T09:00:00';
DECLARE @EndTime   datetime = '2026-09-25T10:00:00';

EXEC master.dbo.xp_readerrorlog
		0,
		1,
		N'Unauthorized Expedite delete attempt. Login=',
		NULL,
		@StartTime,
		@EndTime,
		N'asc';
GO

/*
2. Searching archived logs
---------------------------
SQL Server rotates its error log at service startup and whenever
sp_cycle_errorlog is run. After rotation, older events move from archive 0 to
archive 1, then 2, and so on. List available archives before searching them:
*/

EXEC master.dbo.sp_enumerrorlogs;
GO

/*
Search an individual archive by changing only the first parameter:
*/

EXEC master.dbo.xp_readerrorlog
		1,
		1,
		N'Unauthorized Expedite delete attempt. Login=',
		NULL,
		NULL,
		NULL,
		N'desc';
GO

/*
For an incident investigation, repeat that query for each archive reported by
sp_enumerrorlogs whose date range overlaps the incident. Do not call
sp_cycle_errorlog merely to make a test easier: log rotation is an operational
action and can accelerate deletion of the oldest retained archive.

The extended procedure returns a result set rather than a normal relational
table. When results need to be joined, counted, or exported, capture them into
a temporary table. The result shape below is standard for supported SQL Server
versions; verify it on the target version before automating it.
*/

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

SELECT
		LogDate,
		ProcessInfo,
		[Text]
FROM #ExpediteDeleteLog
ORDER BY LogDate DESC;

SELECT
		AttemptDate = CONVERT(date, LogDate),
		AttemptCount = COUNT_BIG(*)
FROM #ExpediteDeleteLog
GROUP BY CONVERT(date, LogDate)
ORDER BY AttemptDate DESC;

DROP TABLE #ExpediteDeleteLog;
GO

/*
Permissions vary by SQL Server version. Reading all error logs is a privileged
server operation. On newer versions, an administrator can grant the dedicated
VIEW ANY ERROR LOG server permission to a monitoring principal. Older versions
commonly require VIEW SERVER STATE or a more privileged role. Grant the least
permission supported by the installed version; do not add an analyst to the
sysadmin role merely to run this report.

RAISERROR ... WITH LOG is also privileged. The deployed trigger executes in the
caller's context unless an execution context or another logging design has been
configured. Before relying on this control, validate with the same low-privilege
application identity used in production. If the caller cannot write the log,
the observed error may be a permission error rather than the intended audit
message. A DBA should then review the trigger execution context or use an
approved centrally logged mechanism. Do not grant broad server permissions to
application users solely to make WITH LOG work.

3. Pre-test identity and target checks
--------------------------------------
Run these checks in the exact session or application connection that will
attempt the delete. They establish whether the trigger will enter its guarded
application path and whether the normalized identity is an approver.
*/

SELECT
		OriginalLogin = ORIGINAL_LOGIN(),
		EffectiveLogin = SUSER_SNAME(),
		IsApplicationLogin =
				CASE WHEN SUSER_SNAME() LIKE N'%#' THEN 1 ELSE 0 END,
		NormalizedPersonId = REPLACE(
				STUFF(SUSER_SNAME(), 1, CHARINDEX(N'\', SUSER_SNAME()), N''),
				N'#',
				N''
		);
GO

SELECT
		p.[ID],
		p.[IS_APPROVER]
FROM [LIVE].[dbo].[PERSON] AS p
WHERE p.[ID] = REPLACE(
		STUFF(SUSER_SNAME(), 1, CHARINDEX(N'\', SUSER_SNAME()), N''),
		N'#',
		N''
);
GO

/*
For an unauthorized-path test, EffectiveLogin must end in # and the PERSON lookup
must either return no row or return IS_APPROVER other than Y. If the login does
not end in #, stop: the trigger intentionally returns before checking deleted
rows. If IS_APPROVER is Y, use a designated unauthorized test identity instead
of altering production authorization data.

Find a preapproved Expedite row. This is discovery only; do not choose a row
without confirming its business impact and retaining its complete key/value
information according to the local recovery procedure.
*/

SELECT TOP (10)
		udf.[ROWID],
		udf.[DOCUMENT_ID],
		udf.[PROGRAM_ID],
		udf.[ID],
		udf.[LABEL],
		udf.[STRING_VAL]
FROM [LIVE].[dbo].[USER_DEF_FIELDS] AS udf
WHERE udf.[PROGRAM_ID] = N'VMMFGWIN_WO'
	AND udf.[ID] = N'UDF-0000070'
ORDER BY udf.[ROWID];
GO

/*
4. Controlled unauthorized-delete test
--------------------------------------
Record a narrow test window and the selected ROWID before the application user
attempts the delete. Replace the placeholder with an approved row identifier.
Do not remove the PROGRAM_ID and ID predicates: they prevent the example from
becoming a broad delete if the wrong ROWID is supplied.
*/

DECLARE @TestRowId int = 0; -- Replace 0 with the approved test ROWID.

IF @TestRowId = 0
		THROW 50000, 'Set @TestRowId to an approved Expedite test row.', 1;

SELECT
		TestStartedAt = SYSDATETIME(),
		EffectiveLogin = SUSER_SNAME(),
		udf.[ROWID],
		udf.[DOCUMENT_ID],
		udf.[STRING_VAL]
FROM [LIVE].[dbo].[USER_DEF_FIELDS] AS udf
WHERE udf.[ROWID] = @TestRowId
	AND udf.[PROGRAM_ID] = N'VMMFGWIN_WO'
	AND udf.[ID] = N'UDF-0000070';
GO

/*
Issue the following DELETE from the designated unauthorized application session.
It should fail with the custom severity-16 message. SQL Server may also report
error 3609 indicating that the transaction ended in the trigger. That secondary
message is expected because the trigger explicitly rolls back the transaction.

Keep identity emulation out of production. In a nonproduction environment, a
DBA may use EXECUTE AS LOGIN with an existing test login whose name follows the
application convention. Put EXECUTE AS, DELETE, and REVERT in separate batches
so REVERT can still run after the DELETE batch is aborted by the trigger.

Example nonproduction identity setup:

		EXECUTE AS LOGIN = N'DOMAIN\expedite_test#';
		GO

Confirm the effective identity, then run the guarded delete:
*/

SELECT
		OriginalLogin = ORIGINAL_LOGIN(),
		EffectiveLogin = SUSER_SNAME();
GO

DECLARE @TestRowId int = 0; -- Replace again because GO starts a new batch.

IF @TestRowId = 0
		THROW 50000, 'Set @TestRowId to an approved Expedite test row.', 1;

DELETE FROM [LIVE].[dbo].[USER_DEF_FIELDS]
WHERE [ROWID] = @TestRowId
	AND [PROGRAM_ID] = N'VMMFGWIN_WO'
	AND [ID] = N'UDF-0000070';
GO

/*
If EXECUTE AS LOGIN was used in nonproduction, restore the original context in
the next batch, even though the DELETE failed:

		REVERT;
		GO

Then verify the protected row still exists. Run this as the test coordinator or
another principal that can read the table.
*/

DECLARE @TestRowId int = 0; -- Set to the same approved test ROWID.

IF @TestRowId = 0
		THROW 50000, 'Set @TestRowId to the tested Expedite ROWID.', 1;

SELECT
		VerificationTime = SYSDATETIME(),
		udf.[ROWID],
		udf.[DOCUMENT_ID],
		udf.[STRING_VAL]
FROM [LIVE].[dbo].[USER_DEF_FIELDS] AS udf
WHERE udf.[ROWID] = @TestRowId
	AND udf.[PROGRAM_ID] = N'VMMFGWIN_WO'
	AND udf.[ID] = N'UDF-0000070';
GO

/*
Finally, search the error log using the stable prefix. Restrict the timestamps
to the recorded test window when practical.
*/

EXEC master.dbo.xp_readerrorlog
		0,
		1,
		N'Unauthorized Expedite delete attempt. Login=',
		NULL,
		NULL,
		NULL,
		N'desc';
GO

/*
The test passes only when all three observations agree:

	1. The DELETE reports the unauthorized-delete message (and possibly 3609).
	2. The same ROWID still exists with its original value after the attempt.
	3. The current SQL Server error log contains the message with the expected
		 EffectiveLogin and DOCUMENT_ID at the test time.

Capture those three items together in the change ticket or test evidence. An
error message alone does not prove rollback, and an intact row alone does not
prove that durable audit evidence was written.

5. Negative and boundary tests
-------------------------------
The following cases distinguish expected trigger behavior from false positives.
Perform destructive-path tests only in nonproduction with disposable data.

Authorized approver:
	A login ending in # whose normalized dbo.PERSON row has IS_APPROVER = 'Y'
	should be allowed to delete the Expedite row. No unauthorized event should be
	logged. Because the delete is real, use disposable data and restore it through
	the approved fixture or deployment process.

Nonapplication login:
	A login not ending in # is outside this trigger's enforcement scope and causes
	an immediate RETURN. Do not use a real Expedite row to demonstrate this path.
	Confirming the identity query is sufficient unless a nonproduction fixture is
	available.

Non-Expedite row:
	A USER_DEF_FIELDS row with a different PROGRAM_ID or ID should not raise this
	message. This verifies that unrelated user-defined fields are unaffected.

Multi-row delete:
	If one statement deletes several rows and any row is an Expedite row, the
	trigger rolls back the entire statement/transaction. The current message uses
	SELECT TOP (1) DOCUMENT_ID without ORDER BY, so the logged document is only one
	representative deleted row and is nondeterministic for a multi-row operation.
	The login and timestamp remain useful, but the message is not a complete list
	of affected documents.

NULL document:
	If DOCUMENT_ID is NULL, the trigger logs Document=NULL. This is expected and
	should not be interpreted as failure to execute the trigger.

6. Troubleshooting missing or unexpected entries
-------------------------------------------------
No error-log row and the delete succeeded:
	Confirm the trigger is enabled, the target row used the exact PROGRAM_ID and
	ID values, and SUSER_SNAME() ended in #. Also confirm that the DELETE reached
	LIVE.dbo.USER_DEF_FIELDS rather than another database or synonym.

No error-log row but the delete failed:
	Read the client error text. A WITH LOG permission failure indicates that the
	trigger reached RAISERROR but its execution context could not write the log.
	Have a DBA review the deployed security design. Also search archive 1 in case
	the error log rotated immediately after the test.

The event appears in Windows but not in xp_readerrorlog:
	Confirm parameter 2 is 1, remove the date range, and search archives listed by
	sp_enumerrorlogs. Verify that the query is connected to the same SQL Server
	instance on which the delete was attempted.

The prefix search returns unrelated historical events:
	Add a second login or document filter and constrain the date range. Remember
	that the two string filters are ANDed. Retain the unfiltered prefix query for
	aggregate monitoring so unexpected identities are not hidden.

Access is denied when running xp_readerrorlog:
	Ask the DBA for the least-privileged server permission supported by the target
	SQL Server version or request that an approved monitoring job export matching
	events. Do not work around the restriction by granting sysadmin.

Operational monitoring
----------------------
A scheduled collector can query the current and recent archived logs for the
stable prefix and forward matches to the organization's monitoring platform.
The collector should checkpoint the last processed LogDate plus enough message
text to avoid duplicate alerts, account for log rotation, and protect login and
document identifiers according to the applicable retention policy.

Alert content should include server/instance, LogDate, ProcessInfo, the complete
available Text, and the source archive number. Alert on repeated attempts by one
login, bursts across several documents, or any attempt outside an approved test
window. The SQL error log is useful evidence, but it is not a purpose-built audit
table: retention depends on log size, restart frequency, rotation policy, and
the number of configured archives. Export events when longer retention or
tamper-resistant audit history is required.

The durable operational conclusion is simple: verify enforcement at the row,
client-error, and server-log layers. All three are needed to show that an
unauthorized Expedite delete was rejected and that the attempt remained visible
for investigation.
*/

