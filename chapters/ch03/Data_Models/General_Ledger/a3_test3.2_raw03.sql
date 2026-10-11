-- ============================================================================
-- a3_test3.2_raw03.sql
-- Harness case 03 for Documentation/Schema/Data_Models/General_Ledger/a3_test3.2.sql
-- Work order 1796878 verified to exist in Live.dbo.WORK_ORDER.
-- Run in SQLCMD mode so :r is supported.
-- ============================================================================

if object_id('tempdb..#a3_test3_2_params') is not null
    drop table #a3_test3_2_params;

create table #a3_test3_2_params (
    WORKORDER_BASE_ID nvarchar(50) not null
);

insert into #a3_test3_2_params (WORKORDER_BASE_ID)
values ('1796878');

:r .\a3_test3.2.sql

drop table #a3_test3_2_params;