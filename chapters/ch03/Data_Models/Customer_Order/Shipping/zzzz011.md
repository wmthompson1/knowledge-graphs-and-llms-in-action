Exactly. What makes these defects so difficult is that they often masquerade as a data problem, a Power BI problem, or a date-conversion problem when the real issue is a contract violation between derived tables.

The key principle is:

Every branch of a UNION or UNION ALL must return the same columns, in the same order, with compatible datatypes.

In your case, the previous developer had drifted into an unsafe pattern:

CTE_FULL
(
    SELECT 'BASE' AS CTE, *      -- implicit layout
    FROM CTE_BS

    UNION ALL

    SELECT 'REMAINING' AS CTE,
           column1,
           column2,
           ...
           columnN              -- explicit layout
    FROM CTE_REMAINING
)


The moment someone adds, removes, or renames a column in CTE_BS, the SELECT * branch changes shape, while the explicit branch does not. Eventually the two branches no longer agree. As documented in your notes, the BASE branch was still propagating ADJ_DUE_DATE while the other branch had already moved to ADJUSTED_DUE_DATE, creating the mismatch.

A lesson I've learned from maintaining large SQL Server ETL systems:

SELECT * inside a UNION is technical debt

A pattern I actively look for is:

SELECT *
FROM SomeCTE

UNION ALL

SELECT ...


because it creates a hidden dependency on the upstream object's column list.

Much safer:

SELECT
    CUSTOMER_ID,
    CUST_ORDER_ID,
    ...
    ADJUSTED_DUE_DATE
FROM CTE_BS

UNION ALL

SELECT
    CUSTOMER_ID,
    CUST_ORDER_ID,
    ...
    ADJUSTED_DUE_DATE
FROM CTE_REMAINING


Now the layout is self-documenting and resistant to future changes.

Why the agent's first explanation worried me

The initial explanation focused on:

Removed ADJ_DUE_DATE
Removed from GROUP BY
Removed from INSERT list
Removed from projection


Those statements describe edits.

The actual root cause was architectural:

UNION branch A = implicit column layout
UNION branch B = explicit column layout


The real fix was making both branches explicit and aligned.

That's a much more valuable finding because it prevents the same class of bug from reappearing later.

What I would capture in your documentation

Something like:

Root Cause:
CTE_FULL used UNION ALL between two queries that did not share
a common explicit column list.

The BASE branch used SELECT * from CTE_BS.
The REMAINING branch used an explicit projection.

When ADJ_DUE_DATE was removed/renamed, the BASE branch continued
to propagate the column while the REMAINING branch did not,
resulting in a UNION column mismatch.

Resolution:
Replace SELECT * with an explicit column list and standardize on
ADJUSTED_DUE_DATE throughout the ETL pipeline.


