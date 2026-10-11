-- create a field called FLAGGED that defaults to zero

-- 1. ingest the records

-- view
select 
   flagged, count(*) as countof
from staging.[dbo].[My_LABOR_TICKET]
where 1=1
group by flagged;


from staging.[dbo].[My_LABOR_TICKET]
where 1=1;

-- set the flagged field to zero for all existing records
ALTER TABLE [dbo].[My_LABOR_TICKET]
	ADD FLAGGED int DEFAULT 0;

-- optionally set the flagged field to zero for all existing records
UPDATE [dbo].[My_LABOR_TICKET]
SET FLAGGED = 0;

-- Assess the batch master
select * from staging.dbo.batch_master;

