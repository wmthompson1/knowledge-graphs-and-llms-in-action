CREATE OR ALTER TRIGGER dbo.trg_ProtectExpedite_Insert
ON dbo.USER_DEF_FIELDS
AFTER INSERT
AS
BEGIN

    IF SUSER_SNAME() NOT LIKE '%#'
        RETURN;

    IF EXISTS
    (
        SELECT 1
        FROM dbo.PERSON p
        WHERE p.ID = REPLACE(SUSER_SNAME(),'#','')
          AND p.IS_APPROVER = 'Y'
    )
        RETURN;

    IF EXISTS
    (
        SELECT 1
        FROM inserted i
        WHERE i.PROGRAM_ID = 'VMMFGWIN_WO'
          AND i.ID = 'UDF-0000070'
          AND NULLIF(LTRIM(RTRIM(i.STRING_VAL)), '') IS NOT NULL
    )
    BEGIN
        RAISERROR(
            'You are not authorized to create an Expedite value.',
            16,
            1
        );

            DECLARE @msg nvarchar(4000);

    SET @msg =
        'Unauthorized Expedite insert attempt. Login='
        + SUSER_SNAME()
        + ', Document='
        + ISNULL(
            (
                SELECT TOP (1) DOCUMENT_ID
                FROM inserted
            ),
            'NULL'
        );
        
        RAISERROR(@msg, 16, 1) WITH LOG;

        ROLLBACK TRANSACTION;
        RETURN;
    END
END;
GO
