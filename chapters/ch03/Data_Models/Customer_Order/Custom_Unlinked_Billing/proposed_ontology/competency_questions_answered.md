# Competency Questions Answered

## A. Billing scope and eligibility

### CQ-01
Which shipped customer-order lines are eligible for a given custom billing
program during an invoice-date period?

**Required evidence:** customer, invoice date, positive shipped quantity,
billing program, and applicable inclusion rules.

# Billing Schedules

## 1. Fixed Charges
First the rate by part (product type) is extracted
e.g. for 5AXIS:
SELECT CHARGE FROM [SQL-BI-1].LIVESupplemental.dbo.[BOE_Billing_Charges]
WHERE [REPORT] = 'usp_BOE_BILLING_5AXIS'

## 2. Inlusions/Exclusions ReportSettings_PartID
Inclusion and exclusion flags, determine which schedule is applied to include or exclude.
These are pulled from ReportSettings_PartID.

```sql
		AND EXISTS (SELECT 1 FROM [SQL-BI-1].LIVESupplemental.dbo.ReportSettings_PartID EX
			WHERE COL.PART_ID = EX.PART_ID
				AND REPORT_NAME = 'usp_BOE_BILLING_5AXIS'
				AND REPORT_SECTION = 'MAIN INCLUSION'
		)
```

## 3. Fixed Rates Billing By Product Type
[Setup Time], [Run Time] are preset.
They are pulled from BOE_Billing_<Product Type>


## BOE_Billing_5AXIS

```sql
SELECT
 [Setup Time], [Run Time]
FROM [SQL-BI-1].LIVESupplemental.dbo.[BOE_Billing_5AXIS] AX

```

## 4. Resource Mapping Exclusions
Only certain scheduled resources are included.
As example, ```P2M1-IN-FNL``` is excluded.

	INNER JOIN dbo.LABOR_TICKET LT
		ON WO.BASE_ID = LT.WORKORDER_BASE_ID
		AND WO.LOT_ID = LT.WORKORDER_LOT_ID
		AND WO.SPLIT_ID = LT.WORKORDER_SPLIT_ID
		AND WO.SUB_ID = LT.WORKORDER_SUB_ID
		AND WO.[TYPE] = LT.WORKORDER_TYPE
	INNER JOIN dbo.SHOP_RESOURCE_SITE SR
		ON LT.RESOURCE_ID = SR.RESOURCE_ID
		AND ISNULL(SR.USER_9, '') != 'BOE BILLING EXCLUDE'
---

### CQ-02
Why was a part included in or excluded from a billing program?

**Required evidence:** rule identifier, rule type, configured report/program,
part, resource classification, effective period, and decision result.

The effective period will be whatever start date is used, as there is no temporal data.

There are five product types (part types) in this competency, one query per part category.
Internally, the project is referred to as BOE_BILLING but customer x will remain redacted.

## BOE_BILLING_5AXIS
 - Documentation\Schema\Data_Models\Customer_Order\Custom_Unlinked_Billing\BOE_BILLING_5AXIS.sql

## BOE_BILLING_ASSY
 - Documentation\Schema\Data_Models\Customer_Order\Custom_Unlinked_Billing\BOE_BILLING_ASSY.sql

## BOE_BILLING_EME
 Documentation\Schema\Data_Models\Customer_Order\Custom_Unlinked_Billing\BOE_BILLING_EME.sql

## BOE_BILLING_FINISH
Documentation\Schema\Data_Models\Customer_Order\Custom_Unlinked_Billing\BOE_BILLING_FINISH.sql

## BOE_BILLING_MFG
Documentation\Schema\Data_Models\Customer_Order\Custom_Unlinked_Billing\BOE_BILLING_MFG.sql

## 1. Fixed Charges
First the rate by part (product type) is extracted

# Rate Schedule - BOE_Billing_Charges
Information Schema

TABLE_TYPE	dbms	TABLE_CATALOG	TABLE_SCHEMA	TABLE_NAME	COLUMN_NAME	ORDINAL_POSITION	DATA_TYPE	CHARACTER_MAXIMUM_LENGTH
BASE TABLE	sqlserver	LIVESupplemental	dbo	BOE_Billing_Charges	REPORT	1	nvarchar	255
BASE TABLE	sqlserver	LIVESupplemental	dbo	BOE_Billing_Charges	DESCRIPTION	2	nvarchar	255
BASE TABLE	sqlserver	LIVESupplemental	dbo	BOE_Billing_Charges	CHARGE	3	float	NULL
BASE TABLE	sqlserver	LIVESupplemental	dbo	BOE_Billing_Charges	SPECIAL	4	float	NULL
BASE TABLE	sqlserver	LIVESupplemental	dbo	BOE_Billing_Charges	SERVICE	5	float	NULL
BASE TABLE	sqlserver	LIVESupplemental	dbo	BOE_Billing_Charges	OTHER	6	float	NULL
BASE TABLE	sqlserver	LIVESupplemental	dbo	BOE_Billing_Charges	NOTES	7	nvarchar	255

## 2. Inlusions/Exclusions ReportSettings_PartID
```sql
SELECT Top 5 Part_ID, Report_Name, Report_Section FROM [SQL-BI-1].LIVESupplemental.dbo.ReportSettings_PartID EX
WHERE 1=1 -- COL.PART_ID = EX.PART_ID
	AND REPORT_NAME = 'usp_BOE_BILLING_5AXIS'
	AND REPORT_SECTION = 'MAIN INCLUSION'
```
Note: top 5 for brevity
Part_ID	Report_Name	Report_Section
112T8108-501	usp_BOE_BILLING_5AXIS	MAIN INCLUSION
112T8108-502	usp_BOE_BILLING_5AXIS	MAIN INCLUSION
112T8108-503	usp_BOE_BILLING_5AXIS	MAIN INCLUSION
112T8108-504	usp_BOE_BILLING_5AXIS	MAIN INCLUSION
112T8108-505	usp_BOE_BILLING_5AXIS	MAIN INCLUSION
...


## 3. Fixed Rates Billing By Product Type
[Setup Time], [Run Time] are preset.
They are pulled from BOE_Billing_<Product Type>


## BOE_Billing_5AXIS

```sql
SELECT
 [Setup Time], [Run Time]
FROM [SQL-BI-1].LIVESupplemental.dbo.[BOE_Billing_5AXIS] AX
```

## 4. Resource Mapping Exclusions
Only certain scheduled resources are included.
As example, ```P2M1-IN-FNL``` is excluded.
```sql
	INNER JOIN dbo.LABOR_TICKET LT
		ON WO.BASE_ID = LT.WORKORDER_BASE_ID
		AND WO.LOT_ID = LT.WORKORDER_LOT_ID
		AND WO.SPLIT_ID = LT.WORKORDER_SPLIT_ID
		AND WO.SUB_ID = LT.WORKORDER_SUB_ID
		AND WO.[TYPE] = LT.WORKORDER_TYPE
	INNER JOIN dbo.SHOP_RESOURCE_SITE SR
		ON LT.RESOURCE_ID = SR.RESOURCE_ID
		AND ISNULL(SR.USER_9, '') != 'BOE BILLING EXCLUDE'
```
---

## BOE_Billing_5AXIS - Formula for applied charges
Charge rate from 1.
Preset run rate from 3.
```SQL
SELECT
...
	 (AX.[Setup Time] + (AX.[Run Time] * COL.TOTAL_SHIPPED_QTY)) * @CHARGE / COL.TOTAL_SHIPPED_QTY AS [UNIT PRICE]
	, (AX.[Setup Time] + (AX.[Run Time] * COL.TOTAL_SHIPPED_QTY)) * @CHARGE AS [EXTENDED DOLLARS]
...
	INNER JOIN dbo.SHOP_RESOURCE_SITE SR
		ON LT.RESOURCE_ID = SR.RESOURCE_ID
		AND ISNULL(SR.USER_9, '') = 'BOE BILLING EXCLUDE'
	LEFT OUTER JOIN [SQL-BI-1].LIVESupplemental.dbo.[BOE_Billing_5AXIS] AX
...
...
```

