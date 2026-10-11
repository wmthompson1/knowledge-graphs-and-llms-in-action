-- I need to run this insert using top 50, pleasse iterate until decrementing rows are exhausted.
-- but select top (50) if not in staging.dbo.my_work_order_link2ship
-- optionally truncate the staging table before starting the iterative insert
-- truncate table staging.dbo.my_work_order_link2ship;
while 1 = 1
begin
    insert into staging.dbo.my_work_order_link2ship (BASE_ID, FLAGGED)
    select top (50) base_id, 0 from dbo.work_order (nolock) where POSTING_CANDIDATE = 'Y'
      and base_id not in (select base_id from staging.dbo.my_work_order_link2ship);

    if @@ROWCOUNT = 0
        break;
end;

-- Verify the number of rows inserted into the staging table
SELECT COUNT(*) FROM staging.dbo.my_work_order_link2ship;
