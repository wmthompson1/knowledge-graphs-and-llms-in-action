-- ============================================================================
-- a3_Version 1.0_unit_test.sql
-- Unit test for the accumulation-prior delta rule in a3_Version 1.0.sql
--
-- Test 1: Sequential DIST_NO values
-- Test 2: Missing DIST_NO gap handled by previous existing DIST_NO
-- ============================================================================

set nocount on;

if object_id('tempdb..#sequential_actual') is not null drop table #sequential_actual;
if object_id('tempdb..#sequential_expected') is not null drop table #sequential_expected;
if object_id('tempdb..results') is not null drop table #results;

;with sequential_sample as (
    select *
    from (values
        ('W', '1818464', 1, 0, 0, 1, cast(8.69 as decimal(18,2))),
        ('W', '1818464', 1, 0, 0, 2, cast(94463.69 as decimal(18,2))),
        ('W', '1818464', 1, 0, 0, 3, cast(95019.14 as decimal(18,2))),
        ('W', '1818464', 1, 0, 0, 4, cast(95656.48 as decimal(18,2)))
    ) v(
        WORKORDER_TYPE,
        WORKORDER_BASE_ID,
        WORKORDER_LOT_ID,
        WORKORDER_SPLIT_ID,
        WORKORDER_SUB_ID,
        DIST_NO,
        ACCUM_LABOR_COST
    )
), sequential_actual as (
    select
        WORKORDER_TYPE,
        WORKORDER_BASE_ID,
        WORKORDER_LOT_ID,
        WORKORDER_SPLIT_ID,
        WORKORDER_SUB_ID,
        DIST_NO,
        ACCUM_LABOR_COST,
        ACCUM_LABOR_COST - isnull(
            lag(ACCUM_LABOR_COST) over (
                partition by
                    WORKORDER_TYPE,
                    WORKORDER_BASE_ID,
                    WORKORDER_LOT_ID,
                    WORKORDER_SPLIT_ID,
                    WORKORDER_SUB_ID
                order by DIST_NO
            ), 0
        ) as LABOR_DELTA
    from sequential_sample
)
select *
into #sequential_actual
from sequential_actual;

;with sequential_expected as (
    select *
    from (values
        ('W', '1818464', 1, 0, 0, 1, cast(8.69 as decimal(18,2)), cast(8.69 as decimal(18,2))),
        ('W', '1818464', 1, 0, 0, 2, cast(94463.69 as decimal(18,2)), cast(94455.00 as decimal(18,2))),
        ('W', '1818464', 1, 0, 0, 3, cast(95019.14 as decimal(18,2)), cast(555.45 as decimal(18,2))),
        ('W', '1818464', 1, 0, 0, 4, cast(95656.48 as decimal(18,2)), cast(637.34 as decimal(18,2)))
    ) v(
        WORKORDER_TYPE,
        WORKORDER_BASE_ID,
        WORKORDER_LOT_ID,
        WORKORDER_SPLIT_ID,
        WORKORDER_SUB_ID,
        DIST_NO,
        ACCUM_LABOR_COST,
        LABOR_DELTA
    )
)
select *
into #sequential_expected
from sequential_expected;

if exists (
    select * from #sequential_actual
    except
    select * from #sequential_expected
)
    throw 51001, 'Version 1.0 unit test failed: sequential sample mismatch.', 1;

-- Output the computed LABOR_DELTA values to the screen.
select
    WORKORDER_TYPE,
    WORKORDER_BASE_ID,
    WORKORDER_LOT_ID,
    WORKORDER_SPLIT_ID,
    WORKORDER_SUB_ID,
    DIST_NO,
    ACCUM_LABOR_COST,
    LABOR_DELTA
from #sequential_actual
order by DIST_NO;


---- good. now compare the ground truth with the expected results.
select
    a.WORKORDER_TYPE,
    a.WORKORDER_BASE_ID,
    a.WORKORDER_LOT_ID,
    a.WORKORDER_SPLIT_ID,
    a.WORKORDER_SUB_ID,
    a.DIST_NO,
    a.ACCUM_LABOR_COST - e.ACCUM_LABOR_COST as ACCUM_LABOR_COST_DIFF,
    a.LABOR_DELTA - e.LABOR_DELTA as LABOR_DELTA_DIFF
into #results
from #sequential_expected e
join #sequential_actual a on e.WORKORDER_TYPE = a.WORKORDER_TYPE
    and e.WORKORDER_BASE_ID = a.WORKORDER_BASE_ID
    and e.WORKORDER_LOT_ID = a.WORKORDER_LOT_ID
    and e.WORKORDER_SPLIT_ID = a.WORKORDER_SPLIT_ID
    and e.WORKORDER_SUB_ID = a.WORKORDER_SUB_ID
    and e.DIST_NO = a.DIST_NO
order by DIST_NO;

-- check if @testValue = 0
declare @testValue int;
set @testValue = 0;
select @testValue = count(*)
from #results
where ACCUM_LABOR_COST_DIFF <> 0
   or LABOR_DELTA_DIFF <> 0;

if @testValue <> 0
    throw 51002, 'Version 1.0 unit test failed: differences found in results.', 1;
if @testValue = 0
    print 'Version 1.0 unit test passed.';
select LABOR_DELTA_DIFF
from #results;
if object_id('tempdb..#sequential_actual') is not null drop table #sequential_actual;
if object_id('tempdb..#sequential_expected') is not null drop table #sequential_expected;
if object_id('tempdb..#results') is not null drop table #results;
