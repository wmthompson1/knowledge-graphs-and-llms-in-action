/*
    Create Staging.dbo.Store_Merge_DML
    ----------------------------------
    Purpose: Persist generated MERGE statements (see "Create Merge GeneratorV2.sql" and
    "Create Merge Command Template.md") so a generated MERGE command can be reviewed and
    copy-pasted for manual execution instead of re-running the generator each time.

    Column spec reconciled from:
      - Documentation\Operational\Merge_Template\Create Staging Merge DML.md
      - Documentation\Operational\Merge_Template\Create Merge GeneratorV2.sql
        (@TableName / @TableSchema / @SourceTable / @SourceSchema parameters)

    Naming follows the generator's own variable names (TableName/TableSchema = target,
    SourceTable/SourceSchema = source) so rows can be traced back to the generator inputs
    that produced each MergeDML value.
*/

USE Staging;
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'dbo')
BEGIN
    EXEC('CREATE SCHEMA dbo');
END;
GO

IF OBJECT_ID('dbo.Store_Merge_DML', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Store_Merge_DML
    (
        Store_Merge_DML_ID INT IDENTITY(1, 1) NOT NULL
            CONSTRAINT PK_Store_Merge_DML PRIMARY KEY CLUSTERED,
        TableName           SYSNAME         NOT NULL,   -- generator's @TableName   (target table)
        TableSchema         SYSNAME         NOT NULL,   -- generator's @TableSchema (target schema)
        SourceTable         SYSNAME         NOT NULL,   -- generator's @SourceTable
        SourceSchema        SYSNAME         NOT NULL,   -- generator's @SourceSchema
        MergeDML            NVARCHAR(MAX)   NOT NULL,   -- generated MERGE statement, ready to copy/paste
        CreatedDate         DATETIME2(7)    NOT NULL
            CONSTRAINT DF_Store_Merge_DML_CreatedDate DEFAULT (SYSDATETIME()),
        CreatedBy           SYSNAME         NOT NULL
            CONSTRAINT DF_Store_Merge_DML_CreatedBy DEFAULT (SUSER_SNAME())
    );
END;
GO

/*
    Example usage: capture the generator's output straight into this table.

    DECLARE @GeneratedMerge NVARCHAR(MAX) = N'-- paste @SQL output from Create Merge GeneratorV2.sql here';

    INSERT INTO Staging.dbo.Store_Merge_DML
        (TableName, TableSchema, SourceTable, SourceSchema, MergeDML)
    VALUES
        ('OPERATION', 'dbo', 'OPERATION', 'dbo', @GeneratedMerge);

    -- Retrieve for copy/paste (SSMS/ADS: click the cell to open full text, or widen the grid):
    SELECT TableSchema, TableName, SourceSchema, SourceTable, MergeDML, CreatedDate
    FROM Staging.dbo.Store_Merge_DML
    ORDER BY CreatedDate DESC;
*/
