CREATE TRIGGER trg_ProtectExpedite ON [dbo].[USER_DEF_FIELDS]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

-- 2
    -- If the current user is an authorized approver, allow the update and exit immediately
    IF EXISTS (
        SELECT 1 
        FROM [dbo].[PERSON] p 
        WHERE p.ID = SUSER_SNAME() -- Or p.ID = SYSTEM_USER depending on your data type
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
            i.[STRING_VAL] <> d.[STRING_VAL] 
            OR (i.[STRING_VAL] IS NULL AND d.[STRING_VAL] IS NOT NULL) 
            OR (i.[STRING_VAL] IS NOT NULL AND d.[STRING_VAL] IS NULL)
        );
    END;

-- 2/

END;

-- 1/
