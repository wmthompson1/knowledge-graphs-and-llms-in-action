I’ll trace this from the active receivables/customer shipment query into the nearby customer order, work order, and shipping documentation, then report where `DESIRED_RELEASE_DATE` actually appears and how it could feed the invoice-realization rule.

Searching for regex `DESIRED_RELEASE_DATE|Desired Release Date|desired_release_date`

Searched for regex `Customer Order|Work Order|Shipping|invoice realization|realization|release \+|DESIRED_SHIP_DATE|CO_DESIRED_SHIP_DATE` (`**/Documentation/Schema/Data_Models/**`), 307 results

Searched for files matching `**/Documentation/Schema/Data_Models/**/*{Order,Work,Ship,Receivables}*`, 56 matches

The first broad field search was too wide, but the flow-specific search is already pointing at the likely path: receivables ETL files derive `ADJUSTED_DUE_DATE` from work-order reasoning and compare it to customer-order desired ship date. I’m narrowing now on the exact field name and the DDL/model surfaces that own it.

Searched for text `DESIRED_RELEASE_DATE` (`**/Documentation/Schema/Data_Models/**`), 2 results

No matches found. Your search pattern might be excluded completely by either the search.exclude settings or .*ignore files.
If you believe that it should have results, you can check into the .*ignore files and the exclude setting (here are some excluded patterns for reference:[**/node_modules,**/bower_components,**/*.code-search]).
Then if you want to include those files you can call the tool again by setting "includeIgnoredFiles" to true.

Searched for text `DESIRED_RELEASE_DATE` (`**/*.sql`), 2 results

Searched for regex `RELEASE_DATE|DESIRED_RELEASE|DESIRED_SHIP_DATE` (`**/Documentation/Schema/Data_Models/Receivables/**`), 115 results

Exact `DESIRED_RELEASE_DATE` is scarce in the docs: only one engineering comment and one purchasing alias. The receivables flow instead uses `DESIRED_RLS_DATE` and `DESIRED_SHIP_DATE`, so I’m reading those local blocks to pin down whether the requested field is a naming mismatch or an upstream column that never made it into this flow.

Read [](file:///c%3A/Users/williamt/source/skillsinc/skills-inc-org/SQL-Projects/Documentation/Schema/Data_Models/Receivables/403%20SP_SK_ETL03_CUST_SHIP.sql#1-1), lines 1 to 125

Read [](file:///c%3A/Users/williamt/source/skillsinc/skills-inc-org/SQL-Projects/Documentation/Schema/Data_Models/Receivables/401%20SP_SK_ETL01_CUST_SHIP.sql#520-520), lines 520 to 590

Read [](file:///c%3A/Users/williamt/source/skillsinc/skills-inc-org/SQL-Projects/Documentation/Schema/Data_Models/Receivables/402%20SP_SK_ETL02_CUST_SHIP.sql#1-1), lines 1 to 90

Read [](file:///c%3A/Users/williamt/source/skillsinc/skills-inc-org/SQL-Projects/Documentation/Schema/Data_Models/Engineering/Engineer%20-%20Planning%20MFG%20On%20Time.2.0.sql#170-170), lines 170 to 210

Searched for text `DESIRED_RLS_DATE` (`**/Documentation/Schema/Data_Models/Receivables/401 SP_SK_ETL01_CUST_SHIP.sql`), 30 results

Searched for text `DESIRED_RLS_DATE` (`**/Documentation/Schema/Data_Models/Customer_Order/**`), 1 result

Searched for text `DESIRED_RLS_DATE` (`**/Documentation/Schema/Data_Models/Work_Orders/**`), 133 results

Searched for text `DESIRED_RLS_DATE` (`**/Utilities/SQLMesh/ddl/**`), 6 results

Read [](file:///c%3A/Users/williamt/source/skillsinc/skills-inc-org/SQL-Projects/Documentation/Schema/Data_Models/Receivables/401%20SP_SK_ETL01_CUST_SHIP.sql#390-390), lines 390 to 430

Read [](file:///c%3A/Users/williamt/source/skillsinc/skills-inc-org/SQL-Projects/Documentation/Schema/Data_Models/Receivables/401%20SP_SK_ETL01_CUST_SHIP.sql#490-490), lines 490 to 508

Read [](file:///c%3A/Users/williamt/source/skillsinc/skills-inc-org/SQL-Projects/Documentation/Schema/Data_Models/Receivables/402%20SP_SK_ETL02_CUST_SHIP.sql#170-170), lines 170 to 230

Read [](file:///c%3A/Users/williamt/source/skillsinc/skills-inc-org/SQL-Projects/Documentation/Schema/Data_Models/Work_Orders/SP_SK_ETL01_WS.0.sql#350-350), lines 350 to 375

The local flow confirms the column used for “release” is `WORK_ORDER.DESIRED_RLS_DATE`, pulled through the customer-order demand/supply link. I’m checking the remaining join lines once so the handoff path is explicit from order line to work order to shipper/invoice.

Read [](file:///c%3A/Users/williamt/source/skillsinc/skills-inc-org/SQL-Projects/Documentation/Schema/Data_Models/Receivables/402%20SP_SK_ETL02_CUST_SHIP.sql#225-225), lines 225 to 270

Read [](file:///c%3A/Users/williamt/source/skillsinc/skills-inc-org/SQL-Projects/Utilities/SQLMesh/ddl/dbo.WORK_ORDER.sql#1-1), lines 1 to 25

Read [](file:///c%3A/Users/williamt/source/skillsinc/skills-inc-org/SQL-Projects/Documentation/Schema/Data_Models/Receivables/CUSTOMER_ORDER.sql#25-25), lines 25 to 38

Read [](file:///c%3A/Users/williamt/source/skillsinc/skills-inc-org/SQL-Projects/Documentation/Schema/Data_Models/Receivables/CUST_ORDER_LINE.sql#1-1), lines 1 to 15

I searched the Customer Order -> Work Order -> Shipping/Receivables flow.

 The release-date field being used is `WORK_ORDER.DESIRED_RLS_DATE`, defined in dbo.WORK_ORDER.sql.

The current invoice/realization logic already looks close to what management is asking for:

- Customer order lines join to work orders through `DEMAND_SUPPLY_LINK` in 402 SP_SK_ETL02_CUST_SHIP.sql.
- `ADJUSTED_DUE_DATE` is set from `DESIRED_RLS_DATE + x`, where `x` is currently:
  - `30` days for `CMP-MFG` / `MFG`
  - `10` days for `CMP-FIN` / `FIN`
  in 401 SP_SK_ETL01_CUST_SHIP.sql.
- Then ETL03 applies the “later of release + x and customer desired date” rule by comparing `ADJUSTED_DUE_DATE` to `CO_DESIRED_SHIP_DATE` in 403 SP_SK_ETL03_CUST_SHIP.sql.

Important naming point: the “desired date” in that later-of comparison sourced from `CUSTOMER_ORDER.DESIRED_SHIP_DATE`, which is defined in CUSTOMER_ORDER.sql. Order-line desired ship date also exists at CUST_ORDER_LINE.sql.

So the local translation of management’s rule appears to be:

```sql
invoice_realization_date =
    later_of(
        WORK_ORDER.DESIRED_RLS_DATE + context_days,
        CUSTOMER_ORDER / CUST_ORDER_LINE desired ship date
    )
```

In this repo’s flow, the canonical release field is `DESIRED_RLS_DATE`; the customer-facing desired date is `DESIRED_SHIP_DATE` .
You may see this aliased as  `CO_DESIRED_SHIP_DATE`.