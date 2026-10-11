I agree with your approach. In SQL Server 2019, I would strongly favor keeping values as DATE/DATETIME throughout the ETL and only converting to text at the presentation layer.

A few observations from what you've found:

Good

Instead of this:

DATEADD(DAY, 1, CONVERT(varchar(12), GETDATE(), 23))


I'd absolutely use:

DATEADD(DAY, 1, CAST(GETDATE() AS date))


or

DATEADD(DAY, 1, CONVERT(date, GETDATE()))


Both keep the datatype as a date.

Also good

Your month-start pattern:

DATEFROMPARTS(YEAR(CLOCK_IN), MONTH(CLOCK_IN), 1)


is excellent.

For SQL Server 2012+ I often use:

DATEFROMPARTS(YEAR(@Date), MONTH(@Date), 1)


or

EOMONTH(@Date, -1) + 1


Both return a true date value.

One pattern I'd simplify

Your filter:

AND TRANSACTION_DATE >= CAST(CONVERT(date,'2025-01-20') AS datetime)
AND TRANSACTION_DATE <  CAST(CONVERT(date,'2025-01-21') AS datetime)


works, but I'd normally write:

AND TRANSACTION_DATE >= '20250120'
AND TRANSACTION_DATE <  '20250121'


or

AND TRANSACTION_DATE >= CONVERT(date,'2025-01-20')
AND TRANSACTION_DATE <  CONVERT(date,'2025-01-21')


The ISO format is unambiguous and lets SQL Server handle the conversion.

What concerns me in this ETL

Given the Power BI symptoms, I'd search the procedures for patterns like:

CONVERT(varchar, SomeDate, 23)

CAST(SomeDate AS varchar)

ISNULL(SomeDate, '')

CASE
    WHEN SomeDate IS NULL THEN ''
    ELSE SomeDate
END


especially around:

ADJUSTED_DUE_DATE
FILTER_DATE
SHIPPED_DATE
MAX SHIPPED DATE
MAX FILTER


The biggest red flag is usually:

CASE
   WHEN condition THEN ''
   ELSE SomeDate
END


because SQL Server converts the entire expression to character data.

My current theory

After seeing the Power Query logic, I think the failure is more likely related to:

ADJUSTED_DUE_DATE


than to:

MAX SHIPPED DATE


The On Time? calculation compares:

MAX FILTER
against
ADJUSTED_DUE_DATE


and never references MAX SHIPPED DATE.

So if I were auditing the SQL procedures, I'd prioritize:

Every assignment to ADJUSTED_DUE_DATE
Every CASE expression involving dates
Every CONVERT(varchar...) involving dates
Every ISNULL(...,'') against date columns

Those are exactly the kinds of changes that can produce the type-mismatch behavior you're seeing in Power BI.

From what you've uncovered so far, replacing the varchar round-trips with native date handling is a worthwhile cleanup regardless of whether it's the root cause of this particular report failure.