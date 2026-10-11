I’ll pull the SQL and both mapping documents, then draft 5 high-value analytical questions that align to the mapped entities, joins, and fields already documented. I’m starting by locating the exact mapping file paths because one of them looks slightly ambiguous.

Searched for files matching `**/Documentation/Schema/Data_Models/Customer_Order/**`, 17 matches

Searched for files matching `**/Documentation/Schema/Data_Models/Customer_Order/**/*.md`, 4 matches

Searched for files matching `**/Documentation/Schema/Data_Models/Customer_Order/**/*.sql`, 11 matches

I found all three target files, including the unusual map1-1.md path. Next I’ll read the two mapping docs and key parts of the SQL so the questions are grounded in your current lineage and field logic.

Read [](file:///c%3A/Users/williamt/source/skillsinc/skills-inc-org/SQL-Projects/Documentation/Schema/Data_Models/Customer_Order/ATP%20-%20available%20to%20promise/ATP%20-%20available%20to%20promise.md)

Read [](file:///c%3A/Users/williamt/source/skillsinc/skills-inc-org/SQL-Projects/Documentation/Schema/Data_Models/Customer_Order/Customer%20Order%20Master.sql#1-1), lines 1 to 260

Read [](file:///c%3A/Users/williamt/source/skillsinc/skills-inc-org/SQL-Projects/Documentation/Schema/Data_Models/Customer_Order/2%20map%201.md/map1-1.md)

Created 4 todos

I now have the mapping context and the core customer-order logic; I’ll read the remaining section of the SQL to include the WODS merge and final output behavior in the questions.

Read [](file:///c%3A/Users/williamt/source/skillsinc/skills-inc-org/SQL-Projects/Documentation/Schema/Data_Models/Customer_Order/Customer%20Order%20Master.sql#261-261), lines 261 to 435

Here are 5 analysis questions tailored to your current mapping and logic in Customer Order Master.sql, ATP - available to promise.md, and map1-1.md.

1. Which open customer order lines are most at risk of missing ship date, based on both customer commitment variance and work-order variance?
Use DUE_VAR, DUE_VAR_WO, DESIRED_SHIP_DATE, PROM_DEL, PROM_SHIP, PROD_STATUS, and WO_DUE to rank risk by CUSTOMER_ID, BUYER_USER_ID, and PART_ID.

2. How often does In Stock status disagree with projected inventory position, and where is the logic causing false positives/negatives?
Compare PROD_STATUS and QTY_DUE_STOCK_LEVEL against QTY_AVAILABLE_ISS, OPEN_QTY, RTQTY_DUE, and PROJ_QTY_ON_HAND to validate ATP behavior against the ATP definition document.

3. What is the financial exposure of shortages and late work orders by customer and part family?
Quantify TOTAL_DOLLARS tied to lines where PROD_STATUS is not In Stock, DUE_VAR > 0, or DUE_VAR_WO > 0, then break out by CUSTOMER_ID, PART_MBU, and BUYER_USER_ID.

4. Where are customer order lines not getting matched to meaningful WODS scheduling signals, and what is the impact?
Identify lines with null or weak WO_DUE and generic/non-informative PROD_STATUS after the WODS merge, then measure counts and dollars by PART_ID and CUSTOMER_ID.

5. Are promise-date practices consistent across customer groups (for example BOE vs non-BOE patterns) and do they align with actual manufacturing lead behavior?
Analyze PROM_DEL and PROM_SHIP relative to DESIRED_SHIP_DATE and M_DAY_LEADTIME, then compare variance distributions by CUSTOMER_ID and part group to detect systemic over/under-promising.

If you want, I can turn these into a prioritized analysis checklist with exact SQL templates for each question.

Completed: *Generate analytical questions from SQL and mappings* (3/4)