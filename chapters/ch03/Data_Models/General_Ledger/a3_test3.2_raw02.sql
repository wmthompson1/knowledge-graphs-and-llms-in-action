-- ============================================================================
-- a3_test3.2_raw02.sql
-- Harness case 02 for Documentation/Schema/Data_Models/General_Ledger/a3_test3.2.sql
-- Run in SQLCMD mode so :r is supported.
-- ============================================================================

if object_id('tempdb..#a3_test3_2_params') is not null
    drop table #a3_test3_2_params;

create table #a3_test3_2_params (
    WORKORDER_BASE_ID nvarchar(50) not null
);

insert into #a3_test3_2_params (WORKORDER_BASE_ID)
values ('1771611');

:r .\a3_test3.2.sql

drop table #a3_test3_2_params;