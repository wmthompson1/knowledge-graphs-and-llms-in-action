USE [LIVE]
GO

/****** Object:  Trigger [dbo].[trg_ProtectExpedite]   

where
d.[PROGRAM_ID] = 'VMMFGWIN_WO'
AND d.[ID] = 'UDF-0000070'

select t.loginName, t.rowid, t.oldvalue, t.newvalue as attempted, u.STRING_VAL actualValue 
  , p.IS_APPROVER Authorized
  , p.id
  , REPLACE(t.loginName,'#', '') idx
     
from TriggerDebug t
join USER_DEF_FIELDS u
on t.rowid = u.rowid
left join [dbo].[PERSON] p 
on p.ID = REPLACE(t.loginName,'#', '')


 Script Date: 9/21/2026 11:50:54 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/


---CREATE OR ALTER TRIGGER [dbo].trg_ProtectExpedite
ON [dbo].[USER_DEF_FIELDS]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Ignore SSMS, Agent jobs, ETL, etc.
    IF SUSER_SNAME() NOT LIKE '%#'
    RETURN;

    -- DROP TABLE IF EXISTS dbo.TriggerDebug
    IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'dbo.TriggerDebug') AND type in (N'U'))
    BEGIN
        CREATE TABLE dbo.TriggerDebug
        (
            LoginName nvarchar(256),
            ROWID int,
            OldValue nvarchar(max),
            NewValue nvarchar(max),
            DOCUMENT_ID nvarchar(256),
            LogDate datetime2(0) NOT NULL
                CONSTRAINT DF_TriggerDebug_LogDate DEFAULT (SYSDATETIME())
        );
    END;
    ELSE IF COL_LENGTH(N'dbo.TriggerDebug', N'LogDate') IS NULL
    BEGIN
        ALTER TABLE dbo.TriggerDebug
            ADD LogDate datetime2(0) NOT NULL
                CONSTRAINT DF_TriggerDebug_LogDate DEFAULT (SYSDATETIME()) WITH VALUES;
    END;

    -- debug 
    INSERT dbo.TriggerDebug
    (
        LoginName,
        ROWID,
        OldValue,
        NewValue,
        d.DOCUMENT_ID
    )
    SELECT
        SUSER_SNAME(),
        i.ROWID,
        d.STRING_VAL,
        i.STRING_VAL,
        d.DOCUMENT_ID
    FROM inserted i
    JOIN deleted d
        ON i.ROWID = d.ROWID
    where 1=1
    AND isnull(d.STRING_VAL,'') <> isnull(i.STRING_VAL,'') -- <--
    AND d.[PROGRAM_ID] = 'VMMFGWIN_WO'
    AND d.[ID] = 'UDF-0000070';



    -- If the current user is an authorized approver, allow the update and exit immediately
    -- Strips potential 'DOMAIN\' prefix and '#' suffix/prefix added by Visual MFG to match PERSON.ID format
    IF EXISTS (
        SELECT 1 
        FROM [dbo].[PERSON] p 
        WHERE p.ID = REPLACE(STUFF(SUSER_SNAME(), 1, CHARINDEX('\', SUSER_SNAME()), ''), '#', '')
          AND p.IS_APPROVER = 'Y'
    )
    BEGIN
        RETURN;
    END;

    -- Check if the STRING_VAL column is being updated
    IF UPDATE([STRING_VAL])
    BEGIN
        -- Revert the 'Expedite' field to its old value for unauthorized users
        -- where PROGRAM_ID = 'VMMFGWIN_WO', LABEL IS NULL, and ID = 'UDF-0000070'
        UPDATE udf
        SET udf.[STRING_VAL] = d.[STRING_VAL]
        FROM [dbo].[USER_DEF_FIELDS] udf
        INNER JOIN inserted i ON udf.[ROWID] = i.[ROWID]
        INNER JOIN deleted d ON udf.[ROWID] = d.[ROWID]
        WHERE i.[PROGRAM_ID] = 'VMMFGWIN_WO'
          AND i.[LABEL] IS NULL
          AND i.[ID] = 'UDF-0000070'
          -- Only revert if the value actually changed to avoid redundant updates
          AND (
              isnull(i.[STRING_VAL],'') <> isnull(d.[STRING_VAL],'')

              OR (i.[STRING_VAL] IS NULL AND d.[STRING_VAL] IS NOT NULL) 
              OR (i.[STRING_VAL] IS NOT NULL AND d.[STRING_VAL] IS NULL)

              OR (nullif(i.[STRING_VAL],'') IS NULL AND d.[STRING_VAL] IS NOT NULL) 
              OR (i.[STRING_VAL] IS NOT NULL AND nullif(d.[STRING_VAL],'') IS NULL)
          );
    END
END;


GO

ALTER TABLE [dbo].[USER_DEF_FIELDS] ENABLE TRIGGER [trg_ProtectExpedite]
GO


