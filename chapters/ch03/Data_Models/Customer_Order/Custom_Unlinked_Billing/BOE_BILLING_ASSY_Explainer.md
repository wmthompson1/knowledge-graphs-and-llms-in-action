# Explainer: BOE_BILLING_ASSY.sql & Level of Granularity Analysis

**Stored Procedure Name:** `usp_BOE_BILLING_ASSY`  
**Location:** [BOE_BILLING_ASSY.sql](/C:/Users/williamt/source/skillsinc/skills-inc-org/SQL-Projects/Documentation/Schema/Data_Models/Customer_Order/Custom_Unlinked_Billing/BOE_BILLING_ASSY.sql)  
**Relative Folder:** [Documentation/Schema/Data_Models/Customer_Order/Custom_Unlinked_Billing/](/C:/Users/williamt/source/skillsinc/skills-inc-org/SQL-Projects/Documentation/Schema/Data_Models/Customer_Order/Custom_Unlinked_Billing)  
**Author:** AI Assistant using Copilot CLI runtime in VS Code  
**Date:** August 2026  

---

## 1. Executive Summary & Purpose

The SQL script [BOE_BILLING_ASSY.sql](/C:/Users/williamt/source/skillsinc/skills-inc-org/SQL-Projects/Documentation/Schema/Data_Models/Customer_Order/Custom_Unlinked_Billing/BOE_BILLING_ASSY.sql) encapsulates the billing logic for **Boeing Assembly (ASSY) orders** under Customer ID `BOE609`. Originally developed in Crystal Reports and migrated to a stored procedure (`usp_BOE_BILLING_ASSY`) by Traci Treffert, this code shifts hardcoded business calculations from reports to the SQL server layer to ensure:
*   Fidelity of gross margin audits.
*   Single-point-of-truth maintenance.
*   Accurate and automated billing based on actual shop-floor labor tickets.

This document serves as a complete technical explainer, dissecting the data pipeline, join mechanics, cost formulas, and critically, the **level of granularity** defined at each stage of the query.

---

## 2. Table Join Architecture & Data Flow

To resolve the billing values, the query bridges execution data (Shippers and Invoices), contract demand (Customer Orders), supply execution (Work Orders), labor tickets, and supplemental billing rates:

```
  [ SHIPPER ] ──(1:N)──► [ SHIPPER_LINE ]
                             │
                             ▼ (N:1)
                       [ CUST_ORDER_LINE ] ──(1:1)──► [ CUSTOMER_ORDER ]
                             │
                             ▼ (1:1 via DEMAND_SUPPLY_LINK)
                       [ WORK_ORDER ]
                             │
                             ├─(1:N)──► [ LABOR_TICKET ]
                             │               │
                             │               ▼ (N:1)
                             │          [ SHOP_RESOURCE_SITE ] (USER_1 Filter)
                             │
                             └─(1:1)──► [ LIVESupplemental.dbo.BOE_Billing_Charges ] (Rate Injection)
```

### Join Mechanics:
1.  **`dbo.SHIPPER` & `dbo.SHIPPER_LINE`**: Identifies completed shipments where actual items have left the facility (`SHIPPED_QTY > 0`) within the date parameter range (`INVOICED_DATE`).
2.  **`dbo.CUST_ORDER_LINE` & `dbo.CUSTOMER_ORDER`**: Links the shipping record back to the core commercial order and line item. Limits results to customer `BOE609`.
3.  **`dbo.DEMAND_SUPPLY_LINK`**: Acts as the physical connection bridge between the customer order line (Demand) and the specific manufacturing job (Supply).
4.  **`dbo.WORK_ORDER`**: Identifies the physical work order that built the shipped parts.
5.  **`dbo.LABOR_TICKET`**: Pulls every logged labor step performed on that work order, dividing times into **Setup** (`TYPE = 'S'`) and **Run** (`TYPE = 'R'`) hours.
6.  **`dbo.SHOP_RESOURCE_SITE`**: Standardizes labor inputs. Only labor tickets from workgroups where `USER_1 IN ('D', 'E', 'M')` (e.g. assembly/wrapping zones) are included.
7.  **`ReportSettings_PartID` (on `[SQL-BI-1].LIVESupplemental`)**: Acts as a whitelist, restricting parts to those configured under the `'MAIN INCLUSION'` section for `'usp_BOE_BILLING_ASSY'`.
```
		AND EXISTS (SELECT 1 FROM [sql-bi-1].LIVESupplemental.dbo.ReportSettings_PartID EX
			WHERE COL.PART_ID = EX.PART_ID
				AND REPORT_NAME = 'usp_BOE_BILLING_ASSY'
				AND REPORT_SECTION = 'MAIN INCLUSION'
		)
```
8.  **`[SQL-BI-1].LIVESupplemental.dbo.[BOE_Billing_Charges]`**: Injects dynamic external billing rates:
    *   `@CHARGE`: The hourly billing rate for assembly labor.
    *   `@SPECIAL`: Flat fee charged when the assembly requires specialized outside or service processing.
    *   `@SERVICE`: Supplemental service multiplier.

---

## 3. Analysis of Query Granularity (Critical Specification)

Understanding the level of granularity is essential to prevent reporting errors, double-counting, or price distortion when querying across supply and demand dimensions.

### A. Subquery Granularity (The "A" Derived Table)
The inner subquery acts as an un-aggregated compilation of individual execution facts.
*   **Granularity Level**: **One record per Labor Ticket per Shipper Line**.
*   **Reasoning**: Because a `WORK_ORDER` can have multiple `LABOR_TICKET` records, joining `WORK_ORDER` to `LABOR_TICKET` expands the granularity. If a work order has 5 labor tickets and is linked to 1 shipper line, the subquery returns 5 rows.
*   **Attributes Carried**: Contains individual `TRANSACTION_ID` (labor ticket identifier), `HOURS_WORKED`, `SHIPPED_QTY`, and invoice metadata (`INVOICE_ID`, `PACKLIST_ID`, `INVOICED_DATE`).

### B. Final Output Granularity (The Grouped Result)
The outer query performs a `GROUP BY` to roll up individual labor metrics into a commercial billing invoice layout.
*   **Granularity Level**: **One record per Customer Order Line, per Packlist (Shipper), per Invoice**.
*   **Grouping Attributes**:
    ```sql
    GROUP BY PART_ID
        , ID                 -- Customer Order ID
        , TOTAL_SHIPPED_QTY  -- Total Ordered/Shipped Qty on Customer Order Line
        , PACKLIST_ID        -- Shipper Packlist ID
        , INVOICED_DATE
        , INVOICE_ID
        , ACT_SERVICE_COST   -- Work Order Outsource Cost
    ```
*   **Business Meaning**: Each row represents an **Invoice Shipping Event** for a specific manufactured part. It rolls up all relevant labor ticket hours associated with the underlying work order that produced those shipped goods.

### C. The Granularity Cross-Join Pitfall (Architectural Warning)
In standard MRP, **Labor is logged to the Work Order (Supply)**, whereas **Billing is triggered by the Shipper (Demand)**. The query joins these two worlds directly. 
*   **The Risk**: If a single `WORK_ORDER` is split across *multiple* shipments (e.g., shipping 50 parts today on `PACKLIST_001` and 50 parts next week on `PACKLIST_002`), the `DEMAND_SUPPLY_LINK` connects both shipper lines back to the same work order.
*   **The Impact**: The subquery will duplicate the labor tickets across both packlists. When grouped by `PACKLIST_ID`, **both shipments will pull and aggregate the full sum of labor hours from the same work order**. This will result in double-billing the hours and skewing the `EXTENDED DOLLARS` and `UNIT PRICE` calculations.
*   **Mitigation Strategy**: The ASSY billing model assumes a **Strict 1:1 Relationship** between a Work Order and a Shipper/Packlist. It is critical for scheduling and shipping clerks to ensure that assembly work orders are fully shipped in a single transaction, rather than split-shipped, to preserve billing accuracy.

---

## 4. Calculation Rules & Business Logic

The query calculates prices and hours dynamically using the aggregated variables:

### 1. Setup & Run Hours
*   `SORT_SETUP` is isolated to labor tickets of type `'S'` (Setup).
*   `SORT_RUN` is isolated to labor tickets of type `'R'` (Run).
*   Summed up in the select statement as `[SETUP HOURS]` and `[RUN HOURS]`.

### 2. Extended Dollars (Total Billed Labor)
$$\text{[EXTENDED DOLLARS]} = (\sum(\text{SORT\_SETUP}) + \sum(\text{SORT\_RUN})) \times \text{@CHARGE}$$
*   Applies the hourly labor rate (`@CHARGE`) to the total hours worked by the certified assemblers.

### 3. Unit Price
$$\text{[UNIT PRICE]} = \frac{\text{[EXTENDED DOLLARS]}}{\text{TOTAL\_SHIPPED\_QTY}}$$
*   Divides the total labor cost by the total quantity shipped to derive a unit-level rate.

### 4. Special Fees
*   Evaluates `ACT_SERVICE_COST` from `dbo.WORK_ORDER` (which stores outside service or subcontractor costs).
*   If `ACT_SERVICE_COST > 0`, it assesses a flat `@SPECIAL` surcharge; otherwise, it returns `0`.

---

## 5. Rework & Scrap Exclusion Rules

To ensure Boeing is only billed for quality-certified operations, the query implements a conditional exclusion filter:
```sql
AND CASE
    WHEN COL.PART_ID IN ('411N2001-1', '411A2001-1B') THEN 'OK'
    WHEN LT.WORKORDER_BASE_ID LIKE '%R%' THEN 'NOT OK'
    WHEN WO.PART_ID LIKE '%REWORK%' THEN 'NOT OK'
    ELSE 'OK'
END = 'OK'
```
*   **The Rule**: Any work order that contains `'R'` in its base ID (indicating a rework order) or is linked to a part ID containing `'REWORK'` is strictly **excluded** from billing.
*   **The Exception**: Part numbers `'411N2001-1'` and `'411A2001-1B'` are whitelisted, allowing rework billing for these specific high-value assemblies.
