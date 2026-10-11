-- Flag employee/date pairs whose daily hours exceed a standard-deviation threshold.
-- Adjust @stddev_multiplier to suit your tolerance (2.0 = 2 sigma, 3.0 = 3 sigma, etc.).

DECLARE @stddev_multiplier decimal(10,2) = 3.0;

WITH daily_hours AS (
    SELECT
        CAST(lt.clock_in AS date) AS clock_in_date,
        lt.employee_id,
        SUM(CAST(lt.hours_worked AS decimal(10,2))) AS total_hours
    FROM labor_ticket lt
    WHERE lt.ACT_CLOCK_IN >= '2026-07-10'
      AND lt.hours_worked IS NOT NULL
    GROUP BY
        CAST(lt.clock_in AS date),
        lt.employee_id
),
summary_stats AS (
    SELECT
        AVG(total_hours) AS avg_daily_hours,
        STDEV(total_hours) AS stddev_daily_hours
    FROM daily_hours
),
flagged AS (
    SELECT
        d.clock_in_date,
        d.employee_id,
        d.total_hours,
        s.avg_daily_hours,
        s.stddev_daily_hours,
        s.avg_daily_hours + (@stddev_multiplier * s.stddev_daily_hours) AS threshold_hours,
        CASE
            WHEN s.stddev_daily_hours IS NULL OR s.stddev_daily_hours = 0 THEN 0
            WHEN d.total_hours > s.avg_daily_hours + (@stddev_multiplier * s.stddev_daily_hours) THEN 1
            ELSE 0
        END AS exceeds_threshold,
        ((d.total_hours - s.avg_daily_hours) / NULLIF(s.stddev_daily_hours, 0)) AS z_score
    FROM daily_hours d
    CROSS JOIN summary_stats s
),
flagged_days AS (
    SELECT
        clock_in_date,
        employee_id
    FROM flagged
    WHERE exceeds_threshold = 1
),
problems AS (
    SELECT
        CAST(lt.clock_in AS date) AS clock_in_date,
        lt.employee_id,
        lt.hours_worked,
        lt.clock_in,
        lt.CLOCK_OUT
    FROM labor_ticket lt
    INNER JOIN flagged_days f
        ON f.clock_in_date = CAST(lt.clock_in AS date)
       AND f.employee_id = lt.employee_id
    WHERE lt.ACT_CLOCK_IN >= '2026-07-10'
)
SELECT *
FROM problems
ORDER BY clock_in_date, employee_id, clock_in;