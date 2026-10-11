That screenshot shows a different class of problem, and frankly it's a stronger candidate for the root cause than the date conversion issue.

The analysis points out:

CTE_BASE
    -> produces ADJUSTED_DUE_DATE

CTE_REMAINTING
    -> references ADJ_DUE_DATE

CTE_FULL
    -> references both names


Specifically:

ADJ_DUE_DATE


vs

ADJUSTED_DUE_DATE

Why this matters

If one CTE exposes:

ADJUSTED_DUE_DATE


and a downstream CTE expects:

ADJ_DUE_DATE


then one of three things happens:

The query fails at compile time.
A different column gets picked up than intended.
A later UNION/CTE projection shifts columns and introduces unexpected NULLs.

That third scenario can be particularly nasty because the query still runs, but downstream logic gets garbage data.

Interesting connection to Power BI

Your "On Time?" column depends on:

MAX FILTER
vs
ADJUSTED_DUE_DATE


If ADJUSTED_DUE_DATE is being populated incorrectly because of the naming mismatch, then:

MAX FILTER > ADJUSTED_DUE_DATE


can produce unexpected results or errors.

What I would verify

Search the procedure for both names:

ADJ_DUE_DATE


and

ADJUSTED_DUE_DATE


Then confirm:

Which column actually exists in the source table.
Which alias is output by CTE_BASE.
Which alias is expected by CTE_REMAINTING.
Which alias is expected by CTE_FULL.

They should ultimately converge to one consistent name.

My priority order now

If I were auditing this ETL, I'd rank the issues:

✅ ADJ_DUE_DATE vs ADJUSTED_DUE_DATE inconsistency (highest suspicion)
✅ varchar date round-trips
✅ Any CASE expressions mixing dates and strings
✅ Null handling in the Power Query conditional logic

The naming inconsistency is the kind of developer mistake that can easily cascade into Power BI symptoms that initially look like datatype problems.

Given everything you've uncovered, I'd absolutely make that column-name correction and retest before spending more time hunting Power Query logic. The mismatch is concrete, whereas the date issue is still partly circumstantial.