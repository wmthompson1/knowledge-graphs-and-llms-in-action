set nocount on;
set xact_abort off;
set lock_timeout 10000;

-- ---------------------------------------------------------------------------
-- Working variables
-- ---------------------------------------------------------------------------
declare @BatchId int;
declare @StartId nvarchar(30);
declare @EndId nvarchar(30);
declare @TotalBatches int;
declare @CompletedBatches int = 0;
declare @FailedBatches int = 0;
declare @UpdatedRows int = 0;
declare @RetryCount int;
declare @MaxRetries int = 12;
declare @RowsAffected int;
declare @Abort bit = 0;
declare @ErrorMessage nvarchar(2048);
declare @start_BatchId int = 1;
declare @end_batchid int = 1;
declare @Message nvarchar(4000);

-- ---------------------------------------------------------------------------
-- update WORK_ORDER table in batches of 50 based on INVENTORY_TRANS conditions
-- These record id's are then loaded into the staging table for further processing.
-- ---------------------------------------------------------------------------


    while 1 = 1
    begin
        begin try
            begin transaction;

            -- Update in batches of 50 until no more matching rows are affected.
            set @RowsAffected = 1;
            while @RowsAffected > 0
            begin
                update top (50) t
                set posting_candidate = 'Y'
                from dbo.WORK_ORDER t
                where t.[TYPE] = 'W'
                  and t.SUB_ID = '0'
                  and t.posting_candidate <> 'Y'
                  and exists (
                      select 1
                      from dbo.INVENTORY_TRANS it
                      where it.WORKORDER_BASE_ID = t.BASE_ID
                        and it.POSTING_CANDIDATE = 'Y'
                  );

                set @RowsAffected = @@rowcount;
                set @UpdatedRows += @RowsAffected;
                -- I need a progress indicator here, e.g., print the number of updated rows so far.
                set @Message = concat('Updated rows so far: ', @UpdatedRows);
                print @Message;
            end;

            commit transaction;
            break;
        end try
        begin catch
            if xact_state() <> 0
            begin
                rollback transaction;
            end;

            set @ErrorMessage = concat('Error ', error_number(), ', severity ', error_severity(), ', state ', error_state(), ', line ', error_line(), ': ', error_message());
            raiserror(@ErrorMessage, 0, 1) with nowait;
            break;
        end catch;
    end;




