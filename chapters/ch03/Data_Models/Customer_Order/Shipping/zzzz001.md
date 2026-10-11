This is actually very useful. The query you created is Power BI's "View Errors" diagnostic query, and it tells us something important:

What the diagnostic query is doing

The step:

#"Detected Type Mismatches"


checks every primitive column and raises an error when a value's actual type does not match the column's expected type.

The fact that your refresh shows:

49,197 rows loaded
47,203 errors


means that almost every row contains at least one datatype mismatch.

This is much bigger than a single NULL date problem.

Why NULLs are probably not the culprit

Notice this code:

if v = null or Value.Is(v, fieldTypes{i})
then v
else error ...


A NULL is explicitly allowed.

Therefore these errors are more likely:

Text where a Date is expected
Text where a Number is expected
DateTime where a Date is expected
Error values returned from calculations
Mixed datatypes from a CASE expression

For example:

CASE
   WHEN FulfilledDate IS NULL THEN ''
   ELSE FulfilledDate
END


Power BI expects:

date


but receives:

''


which is text.

What I'd do next

The screenshot only shows the M code.

The actual offender is visible in the data preview.

In Power Query:

Open your diagnostic query.
Click on the final step:
#"Reordered Columns"

Look at the grid.
Find the first column displaying:
Error

Click the error cell.

Power BI will show something similar to:

Expression.Error:
We cannot convert the value "" to type Date.


or

DataFormat.Error:
Couldn't convert to Number.


That message identifies the exact column.

My suspicion

Looking at your column list:

ADJUSTED_DUE_DATE
DESIRED_RLS_DATE
CO_DESIRED_SHIP_DATE
MAX SHIPPED DATE
Start of Month
Late%
OT%
TOTAL QTY


I'd investigate these first:

Date columns
ADJUSTED_DUE_DATE
DESIRED_RLS_DATE
CO_DESIRED_SHIP_DATE
MAX SHIPPED DATE
Start of Month


A developer may have changed a field to:

''


instead of

NULL


or changed a date expression to return text.

Numeric columns
Late%
OT%
TOTAL QTY
LATE
ON TIME


Common ETL mistake:

CASE
   WHEN Qty = 0 THEN 'N/A'
   ELSE Qty
END


which converts the entire result to text.

A faster way to isolate the column

Create a second diagnostic query and simplify it.

For example, change:

#"Kept Errors" =
    Table.SelectRowsWithErrors(
        #"Added Index",
        {"CUSTOMER_ID", ... all columns ... }
    )


to only test one column:

#"Kept Errors" =
    Table.SelectRowsWithErrors(
        #"Added Index",
        {"ADJUSTED_DUE_DATE"}
    )


Refresh.

If you get rows back, that column contains errors.

Repeat for:

DESIRED_RLS_DATE
CO_DESIRED_SHIP_DATE
MAX SHIPPED DATE
Start of Month
Late%
OT%
TOTAL QTY


You'll quickly identify the culprit.

Another clue

The original refresh showed:

1,495 rows loaded
1,495 errors


Now you're getting:

49,197 rows loaded
47,203 errors


That pattern strongly suggests that a column's datatype definition in Power BI no longer matches the source query output. If a developer changed an expression in the ETL feed, Power BI is now treating thousands of values as the wrong type.

My bet is a recently modified date column or percentage column returning text values. If you can show the data preview of the error rows (or the message displayed when you click one error cell), we can usually identify the exact column in a minute or two.