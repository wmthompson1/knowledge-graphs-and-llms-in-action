Excellent. This screenshot narrows it down considerably.

The error is occurring in the MAX SHIPPED DATE column.

What we're seeing:

MAX SHIPPED DATE = Error
On Time? = LATE

The key step is now to click one of those Error cells in MAX SHIPPED DATE and look at the details pane at the bottom or right side of Power Query.

Power Query should display something similar to:

DataFormat.Error: We couldn't convert to Date.
Details:
XXXX


or

The type of the value does not match the type of the column.
Details:
"LATE"


or

Cannot convert "" to type Date


That detail is the smoking gun.

What I suspect

Since MAX SHIPPED DATE sounds like a date field, one of these is likely occurring in the ETL:

CASE
    WHEN PACKLIST_ID IS NULL THEN ''
    ELSE MAX_SHIPPED_DATE
END


or

CASE
    WHEN PACKLIST_ID IS NULL THEN 'LATE'
    ELSE CONVERT(varchar(10), MAX_SHIPPED_DATE)
END


or

CASE
    WHEN condition THEN NULL
    ELSE 'Unknown'
END


The result becomes a text column, but Power BI still thinks it is a date column.

Another quick test

Go back to the original Total Transactions query and find the step where MAX SHIPPED DATE gets its type assigned.

It will look something like:

#"Changed Type" =
    Table.TransformColumnTypes(
        PreviousStep,
        {{"MAX SHIPPED DATE", type date}}
    )


Then temporarily change it to:

{{"MAX SHIPPED DATE", type text}}


or remove that column from the Changed Type step entirely.

If the errors disappear, you've confirmed that Power BI is receiving values that are not valid dates.

SQL validation

Against the source query, check for rows where MAX SHIPPED DATE isn't a true date:

SELECT TOP (100)
       [MAX SHIPPED DATE]
FROM YourSource
WHERE TRY_CONVERT(date,[MAX SHIPPED DATE]) IS NULL
  AND [MAX SHIPPED DATE] IS NOT NULL;


If the source is already a date datatype, then look for a CASE expression that produces the column.

Next step

Click one of the Error cells in MAX SHIPPED DATE and send the exact error text shown in the details pane. That message will tell us whether the offending value is:

Blank string ('')
Text such as 'LATE'
Invalid date text
DateTime vs Date mismatch
Something else

Once we have that detail, we can identify the specific ETL coding mistake very quickly.