-- create a field called FLAGGED that defaults to zero

-- 1. ingest the records

-- set the flagged field to zero for all existing records
--ALTER TABLE [Staging].[dbo].[my_work_order]
--	ADD FLAGGED int DEFAULT 0;

-- optionally set the flagged field to zero for all existing records
--UPDATE [Staging].[dbo].[my_work_order]
--SET FLAGGED = 0;

-- Assess the batch master
select * from Staging.dbo.batch_master;

