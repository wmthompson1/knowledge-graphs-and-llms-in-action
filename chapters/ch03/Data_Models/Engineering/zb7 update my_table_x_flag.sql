declare @BatchSize int = 1000;                -- rows per auto-generated batch
declare @AutoPopulateBatches bit = 1;          -- set 1 to create batches from @SourceTable when batch_master is empty
declare @SourceTable nvarchar(128) = 'Staging.dbo.my_work_order_link2ship';
declare @TargetTable nvarchar(128) = 'live.dbo.work_order';
declare @BatchMasterTable nvarchar(128) = 'Staging.dbo.batch_master_work_order_link2ship';
declare @ID_Field NVARCHAR(50) = 'BASE_ID'
declare @Message nvarchar(4000);


select * from Staging.dbo.batch_master_work_order_link2ship;
select * from Staging.dbo.my_work_order_link2ship;
--