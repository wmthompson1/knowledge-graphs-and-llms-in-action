The error is the classic UNION column-count mismatch in `CTE_FULL`. The first branch still uses `SELECT 'BASE' AS CTE, * FROM CTE_BS`, which pulls every column of `CTE_BS` — including `ADJ_DUE_DATE`. The second branch lists only the columns you want, excluding `ADJ_DUE_DATE`, so the counts differ by one.

The clean fix is to make the `BASE` branch explicit and identical in column count/order to the `REMAINING` branch (no `*`).

I’ll read the `CTE_FULL` block to capture the exact layout, then replace the `*` branch with the matching explicit list. 

Read [](file:///c%3A/Users/williamt/source/skillsinc/skills-inc-org/SQL-Projects/Documentation/Schema/Data_Models/Customer_Order/Shipping/sp_Shipments_Core_Feed_02.sql#236-236), lines 236 to 290

Read [](file:///c%3A/Users/williamt/source/skillsinc/skills-inc-org/SQL-Projects/Documentation/Schema/Data_Models/Customer_Order/Shipping/sp_Shipments_Core_Feed_02.sql#290-290), lines 290 to 335

Replacing 4 lines with 15 lines in [](file:///c%3A/Users/williamt/source/skillsinc/skills-inc-org/SQL-Projects/Documentation/Schema/Data_Models/Customer_Order/Shipping/sp_Shipments_Core_Feed_02.sql)


```

```
Fixed. The root cause was in `CTE_FULL`: the `BASE` branch used `SELECT 'BASE' AS CTE, * FROM CTE_BS`, which still pulled `ADJ_DUE_DATE` (because `CTE_BS` still contains it), while the `REMAINING` branch explicitly excluded `ADJ_DUE_DATE`. That one-column difference produced Msg 205.

I replaced the `*` in the `BASE` branch with the same explicit column list used in the `REMAINING` branch (actual column references instead of the `NULL` literals). Now both branches have identical column counts and order, and `ADJ_DUE_DATE` is no longer propagated to `CTE_FULL`.

Re-run the compile-only validation script when you’re ready — it should pass now.

Made changes.