
/*

management has requested that only these users have access to update the USER_DEF_FIELDS table's
value for user_def_fields table, a polymorphic table that stores user-defined fields.

table 'USER_DEF_FIELDS'
		  and ACTION = 'UPDATE'
		  and id like '%UDF-0000070%'

# where
``` sql
[PROGRAM_ID] = 'VMMFGWIN_WO'
          AND [LABEL] IS NULL
          AND [ID] = 'UDF-0000070'
```

SELECT [ROWID]
      ,[ID]
      ,[NAME]
      ,[IS_APPROVER]
  FROM [dbo].[PERSON]
  where 1=1
  and id in ('monicad','Shannen','bob','ellenM','Cathie')

*/

/**********************************************************************************************
Description:
Sample:
Date      Modified By      Change Description
---------- ------------------ ------------------------------------------------------------

-- note - visual adds '#' to the end of the user name e.g. CATHIE#
SELECT 
    'Authorized' AS [Note],
    [ROWID]
      ,[ID]
      ,[NAME]
      ,[IS_APPROVER]
 
  FROM [dbo].[PERSON]
  where 1=1
  and id in ('monicad','Shannen','bob','ellenM','Cathie')

**********************************************************************************************/
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SET DEADLOCK_PRIORITY LOW;
IF OBJECT_ID('tempdb..#Results') IS NOT NULL DROP TABLE #Results;
IF OBJECT_ID('tempdb..#TestUsers') IS NOT NULL DROP TABLE #TestUsers;
IF OBJECT_ID('tempdb..#AUTHORIZED') IS NOT NULL DROP TABLE #AUTHORIZED;

-- Visual has '#' after user name:
-- test with '#' after user name using faux record?
create table #TestUsers (UserName nvarchar(256));
insert into #TestUsers (UserName) values ('monicad#'), ('Shannen#'), ('bob#'), ('Cathie#');

create table #AUTHORIZED (UserName nvarchar(256));
insert into #AUTHORIZED (UserName) values ('monicad#'), ('Shannen#'), ('bob#'), ('Cathie#');

/* Diagnostic 1: trigger deployment and current execution identity. */
SELECT
    '1' note,
    DB_NAME() AS [Database_Name],
    SUSER_SNAME() AS [SUSER_SNAME],
    ORIGINAL_LOGIN() AS [ORIGINAL_LOGIN],
    t.[name] AS [Trigger_Name],
    OBJECT_SCHEMA_NAME(t.[parent_id]) AS [Parent_Schema],
    OBJECT_NAME(t.[parent_id]) AS [Parent_Table],
    t.[is_disabled] AS [Is_Disabled],
    t.[is_instead_of_trigger] AS [Is_Instead_Of],
    CASE
        WHEN t.[object_id] IS NULL THEN 'FAIL: trigger not found in this database'
        WHEN t.[is_disabled] = 1 THEN 'FAIL: trigger is disabled'
        ELSE 'PASS: trigger exists and is enabled'
    END AS [Diagnostic_Result]
FROM (VALUES (N'trg_ProtectExpedite')) expected([Trigger_Name])
LEFT JOIN sys.triggers t
     ON t.[name] = expected.[Trigger_Name]
    AND t.[parent_id] = OBJECT_ID(N'dbo.USER_DEF_FIELDS');

/* Diagnostic 2: compare trigger principal normalization with PERSON.ID.
   Case-insensitive by requirement: comparisons use UPPER() on both sides so the match
   does not depend on the database/column collation. Update trg_ProtectExpedite to match. */
DECLARE @LoginName nvarchar(256) = SUSER_SNAME();
DECLARE @LoginWithoutHash nvarchar(256) =
    REPLACE(STUFF(@LoginName, 1, CHARINDEX('\', @LoginName), ''), '#', '');

SELECT
    '2' note,
    @LoginName AS [Login_Name],
    @LoginWithoutHash AS [Login_Compared_By_Attached_Trigger],
    p.[ID] AS [Person_ID],
    p.[IS_APPROVER],
    CASE WHEN p.[ID] IS NULL THEN 'FAIL: no matching PERSON row'
         WHEN p.[IS_APPROVER] = 'Y' THEN 'INFO: login is authorized; trigger intentionally returns'
         ELSE 'PASS: login is unauthorized and should be reverted'
    END AS [Diagnostic_Result]
FROM (VALUES (1)) v([Row_Exists])
LEFT JOIN dbo.PERSON p
    ON UPPER(p.[ID]) = UPPER(@LoginWithoutHash);

/* Diagnostic 2b: replay the full trigger expression (domain-strip + '#'-strip) against faux Visual-style user names. */
SELECT
    '2b' note,
    t.[UserName] AS [Visual_UserName],
    REPLACE(STUFF(t.[UserName], 1, CHARINDEX('\', t.[UserName]), ''), '#', '') AS [UserName_Without_Hash],
    p.[ID] AS [Person_ID],
    p.[IS_APPROVER],
    CASE WHEN p.[ID] IS NULL THEN 'FAIL: no matching PERSON row'
         WHEN p.[IS_APPROVER] = 'Y' THEN 'INFO: login is authorized; trigger intentionally returns'
         ELSE 'PASS: login is unauthorized and should be reverted'
    END AS [Diagnostic_Result]
FROM #TestUsers t
LEFT JOIN dbo.PERSON p
    ON UPPER(p.[ID]) = UPPER(REPLACE(STUFF(t.[UserName], 1, CHARINDEX('\', t.[UserName]), ''), '#', ''));

/* Diagnostic 2c: emulate observed HISTORY_DATA USER_ID values with a faux PERSON set
   (ELLENM authorized; JOANNC and TERRIC not) since real PERSON approval flags are out of scope here. */

IF OBJECT_ID('tempdb..#TestPerson') IS NOT NULL DROP TABLE #TestPerson;
create table #TestPerson (ID nvarchar(256), IS_APPROVER nchar(1));
insert into #TestPerson (ID, IS_APPROVER) values ('ELLENM', 'Y'), ('JOANNC', 'N'), ('TERRIC', 'N');

IF OBJECT_ID('tempdb..#TestHistoryUsers') IS NOT NULL DROP TABLE #TestHistoryUsers;
create table #TestHistoryUsers (UserName nvarchar(256));
insert into #TestHistoryUsers (UserName) values ('JOANNC#'), ('TERRIC#'), ('ELLENM#');

SELECT
    '2c' note,
    h.[UserName] AS [History_USER_ID],
    REPLACE(STUFF(h.[UserName], 1, CHARINDEX('\', h.[UserName]), ''), '#', '') AS [UserName_Without_Hash],
    tp.[ID] AS [Person_ID],
    tp.[IS_APPROVER],
    CASE WHEN tp.[ID] IS NULL THEN 'FAIL: no matching PERSON row'
         WHEN tp.[IS_APPROVER] = 'Y' THEN 'INFO: login is authorized; trigger intentionally returns'
         ELSE 'PASS: login is unauthorized and should be reverted'
    END AS [Diagnostic_Result]
FROM #TestHistoryUsers h
LEFT JOIN #TestPerson tp
    ON UPPER(tp.[ID]) = UPPER(REPLACE(STUFF(h.[UserName], 1, CHARINDEX('\', h.[UserName]), ''), '#', ''));

/* Diagnostic 3: verify the target rows and the documented VMMFGWIN_WO key format. */
SELECT
    udf.[ROWID],
    udf.[PROGRAM_ID],
    udf.[ID] AS [UDF_ID],
    udf.[DOCUMENT_ID],
    udf.[LABEL],
    udf.[STRING_VAL],
    wo.[TYPE] AS [WORKORDER_TYPE],
    wo.[BASE_ID] AS [WORKORDER_BASE_ID],
    wo.[SUB_ID] AS [WORKORDER_SUB_ID],
    wo.[LOT_ID] AS [WORKORDER_LOT_ID],
    wo.[SPLIT_ID] AS [WORKORDER_SPLIT_ID],
    CASE WHEN udf.[DOCUMENT_ID] = N'W~' + wo.[BASE_ID] + N'~' + wo.[SUB_ID] + N'~' + wo.[LOT_ID] + N'~' + wo.[SPLIT_ID]
         THEN 'PASS: UDF document key matches work order'
         ELSE 'FAIL: UDF document key does not match work order'
    END AS [Diagnostic_Result]
FROM dbo.USER_DEF_FIELDS udf WITH (NOLOCK)
LEFT JOIN dbo.WORK_ORDER wo WITH (NOLOCK)
    ON udf.[DOCUMENT_ID] = N'W~' + wo.[BASE_ID] + N'~' + wo.[SUB_ID] + N'~' + wo.[LOT_ID] + N'~' + wo.[SPLIT_ID]
WHERE udf.[PROGRAM_ID] = 'VMMFGWIN_WO'
  AND udf.[LABEL] IS NULL
  AND udf.[ID] = 'UDF-0000070';

/* Diagnostic 4: show the deployed trigger body and whether it contains the target predicate. */
SELECT
    OBJECT_DEFINITION(OBJECT_ID(N'dbo.trg_ProtectExpedite')) AS [Trigger_Definition],
    CASE WHEN OBJECT_DEFINITION(OBJECT_ID(N'dbo.trg_ProtectExpedite')) LIKE '%UDF-0000070%'
         THEN 'PASS: target UDF predicate is deployed'
         ELSE 'FAIL: target UDF predicate is absent or trigger is absent'
    END AS [Diagnostic_Result];


with audit_data as (
    select 1 ccol
)
-- SELECT
--     h.primary_key,
--     h.OLD_VALUE,
--     h.NEW_VALUE,
--     h.[USER_ID],
--     UPPER(REPLACE(STUFF(h.[USER_ID], 1, CHARINDEX('\', h.[USER_ID]), ''), '#', '')) AS [UserName_Without_Hash],
--     Parts.PROGRAM_ID,
--     Parts.UDF_ID,
--     Parts.WORKORDER_TYPE,
--     Parts.WORKORDER_BASE_ID,
--     Parts.WORKORDER_LOT_ID,
--     Parts.WORKORDER_SPLIT_ID,
--     Parts.WORKORDER_SUB_ID,
--     Parts.FIELD_8,
--     Parts.FIELD_9
-- FROM dbo.HISTORY_DATA h WITH (NOLOCK)
-- CROSS APPLY
-- (
--     SELECT
--         MAX(CASE WHEN j.[key] = 0 THEN j.value END) AS PROGRAM_ID,
--         MAX(CASE WHEN j.[key] = 1 THEN j.value END) AS UDF_ID,
--         MAX(CASE WHEN j.[key] = 2 THEN j.value END) AS WORKORDER_TYPE,
--         MAX(CASE WHEN j.[key] = 3 THEN j.value END) AS WORKORDER_BASE_ID,
--         MAX(CASE WHEN j.[key] = 4 THEN j.value END) AS WORKORDER_SUB_ID,
--         MAX(CASE WHEN j.[key] = 5 THEN j.value END) AS WORKORDER_LOT_ID,
--         MAX(CASE WHEN j.[key] = 6 THEN j.value END) AS WORKORDER_SPLIT_ID,
--         MAX(CASE WHEN j.[key] = 7 THEN j.value END) AS FIELD_8,
--         MAX(CASE WHEN j.[key] = 8 THEN j.value END) AS FIELD_9
--     FROM OPENJSON(
--         N'["' +
--         REPLACE(
--             STRING_ESCAPE(h.primary_key, 'json'),
--             N'~',
--             N'","'
--         ) +
--         N'"]'
--     ) j
-- ) Parts
-- WHERE h.tbl_name = 'USER_DEF_FIELDS'
--   AND h.ACTION = 'UPDATE'
--   AND h.primary_key LIKE '%UDF-0000070%'
-- )
-- -- please use Documentation\Schema\Data_Models\User_Defined for alias reference
-- -- please project field names for the audit_data CTE

SELECT 
1 AS [RowCount]
, 'Authorized' AS [Note]
  , wo.TYPE
  , wo.BASE_ID
  , wo.SUB_ID
  , wo.LOT_ID
  , wo.SPLIT_ID


-- -- , udf.STRING_VAL AS [Expedite] 

--INTO #Results 
FROM dbo.WORK_ORDER wo
-- on audit_data.WORKORDER_TYPE = wo.TYPE
-- and audit_data.WORKORDER_BASE_ID = wo.BASE_ID
-- and audit_data.WORKORDER_LOT_ID = wo.LOT_ID
-- and audit_data.WORKORDER_SPLIT_ID = wo.SPLIT_ID
-- and audit_data.WORKORDER_SUB_ID = wo.SUB_ID
join dbo.USER_DEF_FIELDS udf
on udf.DOCUMENT_ID = wo.TYPE
    + '~' + wo.BASE_ID
    + '~' + wo.SUB_ID
    + '~' + wo.LOT_ID
    + '~' + wo.SPLIT_ID
and udf.PROGRAM_ID = 'VMMFGWIN_WO'
and udf.LABEL IS NULL
and udf.ID = 'UDF-0000070'
where 1=1
-- 1747596
-- and audit_data.WORKORDER_BASE_ID = '1747596'
order by wo.BASE_ID, wo.LOT_ID
;
--select * from #Results;
