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