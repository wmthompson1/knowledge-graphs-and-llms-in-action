```sql
DATEADD(
    DAY,
    -6,
    DATEADD(
        DAY,
        1 - DATEPART(WEEKDAY, CAST(GETDATE() AS date)),
        CAST(GETDATE() AS date)
    )
)
```

This matches the SSRS expression when SQL Server uses Sunday as the first day of the week:

```sql
SET DATEFIRST 7; -- Sunday

SELECT DATEADD(
    DAY,
    -6,
    DATEADD(
        DAY,
        1 - DATEPART(WEEKDAY, CAST(GETDATE() AS date)),
        CAST(GETDATE() AS date)
    )
) AS ResultDate;
```

The result is the Monday of the previous week. To avoid dependence on the session's `DATEFIRST` setting, use this version:

```sql
SELECT DATEADD(
    DAY,
    -6 - (DATEDIFF(DAY, '19000107', CAST(GETDATE() AS date)) % 7),
    CAST(GETDATE() AS date)
) AS ResultDate;
```

`1900-01-07` was a Sunday, so the second version always applies the same Sunday-based week calculation as SSRS.