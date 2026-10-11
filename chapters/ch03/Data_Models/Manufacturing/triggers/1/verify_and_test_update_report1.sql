
/**********************************************************************************************
Description: Expedite Field Value Checker Report
Sample:
Date      Modified By      Change Description
---------- ------------------ ------------------------------------------------------------
09/24/2026	WilliamT	Created
**********************************************************************************************/
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET DEADLOCK_PRIORITY LOW
IF OBJECT_ID('tempdb..#Results') IS NOT NULL DROP TABLE #Results

DECLARE @WorkOrderBaseId nvarchar(50) = 'ALL';

select t.loginName, t.rowid, t.oldvalue, t.newvalue as attempted
  , u.STRING_VAL actualValue 
  , isnull(p.IS_APPROVER,'N') Authorized
  , p.id
  , REPLACE(t.loginName,'#', '') idx
  , t.logdate
  , u.DOCUMENT_ID
  ,SUBSTRING(
    u.DOCUMENT_ID,
		CHARINDEX('~', u.DOCUMENT_ID) + 1,
				CHARINDEX('~', u.DOCUMENT_ID, CHARINDEX('~', u.DOCUMENT_ID) + 1)
					 - CHARINDEX('~', u.DOCUMENT_ID) - 1
		) AS WorkOrderBaseId
		into #Results
from TriggerDebug t 
join USER_DEF_FIELDS u
on t.rowid = u.rowid
left join [dbo].[PERSON] p 
on p.ID = REPLACE(t.loginName,'#', '')
where 
cast(logdate as date)  >= cast(getdate() as date)
---where t.ROWID = '4126122';  -- '3976522' -- --  '1712094'

-- select *
-- from #Results;

select logdate, null as processInfo, text = cast('unauthorized update attempt' + ' '+ idx + ' ' + WorkOrderBaseId 
        as nvarchar(max))
from #results
where (WorkOrderBaseId = @WorkOrderBaseId or @WorkOrderBaseId='ALL')
