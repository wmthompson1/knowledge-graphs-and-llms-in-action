/**********************************************************************************************
Description:
Sample:
Date      Modified By      Change Description
---------- ------------------ ------------------------------------------------------------
**********************************************************************************************/
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET DEADLOCK_PRIORITY LOW
IF OBJECT_ID('tempdb..#Results') IS NOT NULL DROP TABLE #Results
IF OBJECT_ID('tempdb..#RawDemoData') IS NOT NULL DROP TABLE #RawDemoData

CREATE TABLE #RawDemoData (
    row_no      INT IDENTITY(1,1),
    customer_id INT,
    dist_no     INT,
    raw_value   INT
);

INSERT INTO #RawDemoData (customer_id, dist_no, raw_value)
VALUES
    -- First emission group
    (123, 1, 100),
    (123, 2, 100),
    (123, 2, 25),

    -- Second emission group
    (123, 3, 100),
    (123, 3, 25),
    (123, 3, 35),

    -- Third emission group
    (123, 4, 100),
    (123, 4, 25),
    (123, 4, 35),
    (123, 4, 10),

    -- Customer 456
    -- First emission group
    (456, 1, 200),

    -- Second emission group
    (456, 2, 200),
    (456, 2, 50),

    -- Third emission group
    (456, 3, 200),
    (456, 3, 50),
    (456, 3, 75);

--select * from #RawDemoData;

-- sql 1
WITH dist_levels AS (
    SELECT
        customer_id,
        dist_no,
        raw_value AS TotalAmount,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id, dist_no
            ORDER BY row_no
        ) AS rn
    FROM #RawDemoData
)
-- SELECT
--     customer_id,
--     dist_no,
--     TotalAmount,
--     rn
-- FROM dist_levels;

-- dist_levels debug explosion
-- Code
-- 100   ← dist_no1 raw emission
-- 100   ← dist_no1 raw emission
-- 25    ← dist_no2 raw emission

-- 100   ← dist_no1 raw emission
-- 25    ← dist_no2 raw emission
-- 35    ← dist_no3 raw emission

-- 100   ← dist_no1 raw emission
-- 25    ← dist_no2 raw emission
-- 35    ← dist_no3 raw emission
-- 10    ← dist_no4 raw emission

-- sql 2
,one_row_per_dist AS (
    SELECT
        customer_id,
        dist_no,
        sum(TotalAmount) AS TotalAmount
    FROM dist_levels
    GROUP BY customer_id, dist_no
)
SELECT
    customer_id,
    dist_no,
    TotalAmount
FROM one_row_per_dist
order by customer_id, dist_no
;

-- one_row_per_dist debug explosion
-- customer_id	dist_no	TotalAmount
-- 123	    	1	    100		← dist_no1 cte2.2
-- 123 		    2	    125     ← dist_no2 cte2.2
-- 123	    	3	    160     ← dist_no3 cte2.2
-- 123	    	4	    170     ← dist_no4 cte2.2


