-- ============================================================================
-- a3_test3.2_harness.sql
-- Master harness for running 11 work-order test cases against a3_test3.2.sql.
--
-- Usage:
--   1) Open this file in SSMS/Azure Data Studio with SQLCMD mode enabled, OR
--   2) Run from CLI: sqlcmd -S Crunch2018 -d Crunch0626 -i a3_test3.2_harness.sql
--
-- Each rawXX file sets #a3_test3_2_params.WORKORDER_BASE_ID and includes
-- a3_test3.2.sql via :r.
-- ============================================================================

-- 1796878
print 'Running case raw01';
:r .\a3_test3.2_raw01.sql
go

-- 1801921
print 'Running case raw02';
:r .\a3_test3.2_raw02.sql
go

-- 1810250
print 'Running case raw03';
:r .\a3_test3.2_raw03.sql
go

-- print 'Running case raw04';
-- :r .\a3_test3.2_raw04.sql
-- go

-- print 'Running case raw05';
-- :r .\a3_test3.2_raw05.sql
-- go

-- print 'Running case raw06';
-- :r .\a3_test3.2_raw06.sql
-- go

-- print 'Running case raw07';
-- :r .\a3_test3.2_raw07.sql
-- go

-- print 'Running case raw08';
-- :r .\a3_test3.2_raw08.sql
-- go

-- print 'Running case raw09';
-- :r .\a3_test3.2_raw09.sql
-- go

-- print 'Running case raw10';
-- :r .\a3_test3.2_raw10.sql
-- go

-- print 'Running case raw11';
-- :r .\a3_test3.2_raw11.sql
-- go
