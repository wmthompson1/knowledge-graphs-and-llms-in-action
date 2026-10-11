-- trg_ProtectExpedite_Delete
CREATE OR ALTER TRIGGER dbo.trg_ProtectExpedite_Delete
ON dbo.USER_DEF_FIELDS
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- Ignore SSMS, Agent jobs, ETL, etc.
    IF SUSER_SNAME() NOT LIKE '%#'
    RETURN;

    -- Allow authorized approvers
    IF EXISTS
    (
        SELECT 1
        FROM dbo.PERSON p
        WHERE p.ID = REPLACE(
                    STUFF(SUSER_SNAME(),1,CHARINDEX('\',SUSER_SNAME()),''),
                    '#',''
                  )
          AND p.IS_APPROVER = 'Y'
    )
        RETURN;

    -- Was the Expedite field deleted?
    IF EXISTS
    (
        SELECT 1
        FROM deleted d
        WHERE d.PROGRAM_ID = 'VMMFGWIN_WO'
          AND d.ID = 'UDF-0000070'
          AND NULLIF(LTRIM(RTRIM(d.STRING_VAL)), '') IS NOT NULL
    )
    BEGIN

    DECLARE @msg nvarchar(4000);

    SET @msg =
        'Unauthorized Expedite delete attempt. Login='
        + SUSER_SNAME()
        + ', Document='
        + ISNULL(
            (
                SELECT TOP (1) DOCUMENT_ID
                FROM deleted
            ),
            'NULL'
        );

    RAISERROR(@msg, 16, 1) WITH LOG;

        ROLLBACK TRANSACTION;
        RETURN;
    END
END;
GO