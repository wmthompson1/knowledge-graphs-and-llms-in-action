-- create a field called FLAGGED that defaults to zero

-- 1. ingest the records

-- set the flagged field to zero for all existing records

set nocount on;
set xact_abort off;
set lock_timeout 10000;

-- ---------------------------------------------------------------------------
-- Configurable variables
-- ---------------------------------------------------------------------------
declare @BatchSize int = 1000;                -- rows per auto-generated batch
declare @AutoPopulateBatches bit = 1;          -- set 1 to create batches from @SourceTable when batch_master is empty
declare @SourceTable nvarchar(128) = 'Staging.dbo.my_labor_ticket';
declare @TargetTable nvarchar(128) = 'live.dbo.labor_ticket';
declare @BatchMasterTable nvarchar(128) = 'Staging.dbo.batch_master_labor_ticket';
declare @ID_Field NVARCHAR(50) = 'Transaction_ID'


-- ALTER TABLE [Staging].[dbo].[my_labor_ticket]
-- 	ADD FLAGGED int DEFAULT 0;

-- optionally set the flagged field to zero for all existing records
UPDATE [Staging].[dbo].[my_labor_ticket]
SET FLAGGED = 0;

-- Assess the batch master
select * from Staging.dbo.batch_master_labor_ticket;
