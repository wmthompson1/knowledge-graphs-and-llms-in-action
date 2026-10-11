# Billing Schedules

## 1. Fixed Charges
First the rate by part (product type) is extracted
e.g. for 5AXIS:
SELECT CHARGE FROM [SQL-BI-1].LIVESupplemental.dbo.[BOE_Billing_Charges]
WHERE [REPORT] = 'usp_BOE_BILLING_5AXIS'

## Inlusions/Exclusions ReportSettings_PartID
Inclusion and exclusion flags, determine which schedule is applied to include or exclude.
These are pulled from ReportSettings_PartID.

```sql
		AND EXISTS (SELECT 1 FROM [SQL-BI-1].LIVESupplemental.dbo.ReportSettings_PartID EX
			WHERE COL.PART_ID = EX.PART_ID
				AND REPORT_NAME = 'usp_BOE_BILLING_5AXIS'
				AND REPORT_SECTION = 'MAIN INCLUSION'
		)
```

## Fixed Rates Billing By Product Type
[Setup Time], [Run Time] are preset.
They are pulled from BOE_Billing_<Product Type>


## BOE_Billing_5AXIS

```sql
SELECT
 [Setup Time], [Run Time]
FROM [SQL-BI-1].LIVESupplemental.dbo.[BOE_Billing_5AXIS] AX

```

## Resource Mapping Exclusions
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