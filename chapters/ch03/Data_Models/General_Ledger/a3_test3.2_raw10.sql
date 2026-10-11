-- ============================================================================
-- a3_test3.2_raw10.sql
-- Harness case 10 for Documentation/Schema/Data_Models/General_Ledger/a3_test3.2.sql
-- Replace REPLACE_ME_10 with a real work order base ID.
-- Run in SQLCMD mode so :r is supported.
-- ============================================================================

if object_id('tempdb..#a3_test3_2_params') is not null
    drop table #a3_test3_2_params;

create table #a3_test3_2_params (
    WORKORDER_BASE_ID nvarchar(50) not null
);

insert into #a3_test3_2_params (WORKORDER_BASE_ID)
values ('REPLACE_ME_10');

:r .\a3_test3.2.sql

drop table #a3_test3_2_params;