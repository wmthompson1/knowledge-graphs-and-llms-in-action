
--SET ANSI_NULLS ON
--GO

--SET QUOTED_IDENTIFIER ON
--GO




/******************************************************************************************
-- Author:		traci treffert
-- Create date: 9/17/2019
-- Description:	Boeing Billing for BOE609 5AXIS
--		converted from original code in Crystal Reports to be used as SSRS report
--		take the logic/process out of hardcoded CR report and put in SQL for ease of maintenance
--		logic to also be included in Gross Margin processing
-- 
--> tt20211012: We need the calculations updated for the 5-AXIS CMP report.
When an item falls under fixed hours, the formula for the extended dollars needs to reflect ((Setup Time + (Run Time x Qty))*80) - 
This uses the run time listed on the fixed hours table.
For example PN 112T8108-515 that ships with a quantity of 6 = ((1.45 + ( 6 x 2.95)) x 80)
On the report we would like the run hours to be updated as well (Run time * qty) using the example above = (6 x 2.95) = 17.70

******************************************************************************************/

--DECLARE @STARTDATE DATE = '2025-08-18';
--DECLARE @ENDDATE DATE = '2025-08-24';

--CREATE PROCEDURE [dbo].[usp_BOE_BILLING_5AXIS] (@STARTDATE DATE, @ENDDATE DATE)
--AS

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET DEADLOCK_PRIORITY LOW

-- 105
DECLARE @CHARGE FLOAT = (SELECT CHARGE FROM [SQL-BI-1].LIVESupplemental.dbo.[BOE_Billing_Charges] WHERE [REPORT] = 'usp_BOE_BILLING_5AXIS') --> $80
--, @STARTDATE DATE = '10/1/2021' 
--, @ENDDATE DATE = '10/31/2021'

print @CHARGE --cast?

select *
FROM [SQL-BI-1].LIVESupplemental.dbo.[BOE_Billing_Charges] 

-- Server: sql-bi-1
SELECT
t.TABLE_TYPE 
,'sqlserver' dbms,t.TABLE_CATALOG,t.TABLE_SCHEMA
,t.TABLE_NAME,c.COLUMN_NAME,c.ORDINAL_POSITION,c.DATA_TYPE
,c.CHARACTER_MAXIMUM_LENGTH
FROM LIVESupplemental.INFORMATION_SCHEMA.TABLES t 
LEFT JOIN LIVESupplemental.INFORMATION_SCHEMA.COLUMNS c ON t.TABLE_CATALOG=c.TABLE_CATALOG AND t.TABLE_SCHEMA=c.TABLE_SCHEMA AND t.TABLE_NAME=c.TABLE_NAME 
LEFT JOIN(LIVESupplemental.INFORMATION_SCHEMA.KEY_COLUMN_USAGE k JOIN INFORMATION_SCHEMA.TABLE_CONSTRAINTS n ON k.CONSTRAINT_CATALOG=n.CONSTRAINT_CATALOG 
AND k.CONSTRAINT_SCHEMA=n.CONSTRAINT_SCHEMA AND k.CONSTRAINT_NAME=n.CONSTRAINT_NAME LEFT JOIN INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS r 
ON k.CONSTRAINT_CATALOG=r.CONSTRAINT_CATALOG AND k.CONSTRAINT_SCHEMA=r.CONSTRAINT_SCHEMA AND k.CONSTRAINT_NAME=r.CONSTRAINT_NAME)ON c.TABLE_CATALOG=k.TABLE_CATALOG 
AND c.TABLE_SCHEMA=k.TABLE_SCHEMA AND c.TABLE_NAME=k.TABLE_NAME AND c.COLUMN_NAME=k.COLUMN_NAME LEFT JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE k2 ON k.ORDINAL_POSITION=k2.ORDINAL_POSITION AND r.UNIQUE_CONSTRAINT_CATALOG=k2.CONSTRAINT_CATALOG AND r.UNIQUE_CONSTRAINT_SCHEMA=k2.CONSTRAINT_SCHEMA AND r.UNIQUE_CONSTRAINT_NAME=k2.CONSTRAINT_NAME 
WHERE (1=1) 
and t.TABLE_NAME like 'BOE_Billing_Charges'
order by 
 t.TABLE_CATALOG, t.TABLE_NAME, c.ORDINAL_POSITION

/**
TABLE_TYPE	dbms	    TABLE_CATALOG	TABLE_SCHEMA	TABLE_NAME	COLUMN_NAME	ORDINAL_POSITION	DATA_TYPE	CHARACTER_MAXIMUM_LENGTH
BASE TABLE	sqlserver	LIVESupplemental	dbo	BOE_Billing_Charges	REPORT	1	nvarchar	255
BASE TABLE	sqlserver	LIVESupplemental	dbo	BOE_Billing_Charges	DESCRIPTION	2	nvarchar	255
BASE TABLE	sqlserver	LIVESupplemental	dbo	BOE_Billing_Charges	CHARGE	3	float	NULL
BASE TABLE	sqlserver	LIVESupplemental	dbo	BOE_Billing_Charges	SPECIAL	4	float	NULL
BASE TABLE	sqlserver	LIVESupplemental	dbo	BOE_Billing_Charges	SERVICE	5	float	NULL
BASE TABLE	sqlserver	LIVESupplemental	dbo	BOE_Billing_Charges	OTHER	6	float	NULL
BASE TABLE	sqlserver	LIVESupplemental	dbo	BOE_Billing_Charges	NOTES	7	nvarchar	255

**/

/* Includion of parts  */
			SELECT * FROM [SQL-BI-1].LIVESupplemental.dbo.ReportSettings_PartID EX
			WHERE 1=1 -- COL.PART_ID = EX.PART_ID
				AND REPORT_NAME = 'usp_BOE_BILLING_5AXIS'
				AND REPORT_SECTION = 'MAIN INCLUSION'

