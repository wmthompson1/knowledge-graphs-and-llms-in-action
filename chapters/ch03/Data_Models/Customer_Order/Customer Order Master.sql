USE [LIVE]  -- runs on lb-2 via lab-1
GO

/****** Object:  StoredProcedure [dbo].[sp_Customer_Order_Master]    Script Date: 6/9/2026 10:01:51 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- repo
-- C:\Users\williamt\source\skillsinc\skills-inc-org\SQL-Projects\SQL_Reports\Work Order Reports\1_CO Master.sql
 /***********************************************************************************/

 /**********************************************************************************************
Description: runs on live. reports refreshes feed by calling 2 staging procs 
Sample:
Date      Modified By      Change Description
---------- ------------------ ------------------------------------------------------------
SKILLS\viviane on 5/6/2022 11:47 PM   Created


Ellen And Diane requested to remove the running total from the quantity due field and add it as a separate field.  
This is because they want to be able to sum the quantity due field for reporting purposes.  The running total field is still 
included in the report for informational purposes but is not being used by contracting personnel at this time.
H. Updated the report to include the WODS fields of Prod Status and WO Due Date.  The Prod Status field is updated with the WODS Prod Status 
if the customer order line is not in stock.  The WO Due Date is updated with the WODS Desired Want Date.  If there are multiple WODS records for a part, 
then the one with the earliest Desired Want Date is used to update the customer order line information.
Ellen and Diane requested to add the WODS Desired Want Date to the output for informational purposes.  This is included in the output as WODS_DESIRED_WANT_DATE.
05/12/2022 - Updated the report to include the WODS production status and desired want date for all records, not just those that are not in stock.  
This is because some records that are in stock may also have a WODS record with a later desired want date that would be helpful for contracting personnel to see.  
The WODS production status and desired want date are included in the output as WODS_PROD_STATUS and WODS_DESIRED_WANT_DATE, respectively. 05/12/2022

-- VISUAL ENTERPRISE > WORK ORDER REPORTS > 1_WO Master

-- This report(excel output) originated from a Crystal Report built by Ann Wentzke, combined with an output from
-- the Workorder Daily Status Report (WODS) and updated via vlookup and then updated with conditional formatting.
-- It is to provide Contract personnel the status of all customer orders for Manufacturing 
-- and their associated workorders if possible.  
-- some fields have been removed because it has been determined they are not being used by the contracting personnel.
---4 day's variance
--shipdate - 3/15/2022 
--workorder due date 3/11/2022

--no workorder associated  In stock example is CBO no work order to fulfill the complete quantity  QOH 

--BOEPOP Promise del Customer PO due date 
--       promise Ship  3 or 4 
--      ASN date backoff date before the ship date day skills is going to ship depends on where it is being shipped to and customer  
--Non- BOEing  Customer 
--Back off Date of 10 or more days in the prom Ship
-- do need the unhidden fields
--part/mbu business unit        left 3 of cust po line_440 
--/5/3/2022 no current equvalent for VAL so the addition on the right may have a space after the underscore_



1. report procedure sp_Customer_Order_Master on live

2. EXEC ('staging.dbo.SP_MERGE_WODS_LIGHT');
  - then the sp_MERGE_WODS_LIGHT procedure merges the WODS feed with the existing WODS_Comp_test223 table in
   staging to create an updated WODS feed with the two new fields of desired want date and production status.  
   This updated feed is then used in the sp_Customer_Order_Master procedure to pull in the WODS information for 
   the customer order lines.
    - Runs select from staging.dbo.WODS_Comp_test223 which is the updated WODS feed with the two new fields of 
    desired want date and production status.
**********************************************************************************************/



CREATE   procedure [dbo].[sp_Customer_Order_Master]
AS
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET DEADLOCK_PRIORITY LOW
IF OBJECT_ID('tempdb..#Results') IS NOT NULL DROP TABLE #Results

IF OBJECT_ID('tempdb..#RUN_TOT_QTY_DUE') IS NOT NULL DROP TABLE #RUN_TOT_QTY_DUE
IF OBJECT_ID('tempdb..#CUST_ORDER') IS NOT NULL DROP TABLE #CUST_ORDER
IF OBJECT_ID('tempdb..#WODS') IS NOT NULL DROP TABLE #WODS
IF OBJECT_ID('tempdb..#WODS_FILTERED') IS NOT NULL DROP TABLE #WODS_FILTERED;
IF OBJECT_ID('tempdb..#Final') IS NOT NULL DROP TABLE #Final;

EXEC ('Live.dbo.SP_WODS_Light');
EXEC ('staging.dbo.SP_MERGE_WODS_LIGHT');

--Declare @base_id as varchar(50) = NULL;

DECLARE @LINE_NO AS VARCHAR(50) = NULL; 

-------- DECLARE @DUEDATE AS DATETIME
DECLARE @CUST_ORDER_ID AS NVARCHAR(50) = NULL; -- '521475'; -- '501092';  -- 521053
 
 --/*
--  --Drop all temporary table objects that exist in the tempDB for the current session
-- DECLARE @TempTablesString NVARCHAR(MAX) 

-- SELECT @TempTablesString = COALESCE(@TempTablesString + ', ', '') 
-- + CASE WHEN name LIKE '##%' THEN name 
--        WHEN name LIKE '#%'  THEN SUBSTRING(name, 1, CHARINDEX( '____', name)-1)
--   END 
-- FROM  tempdb..sysobjects WITH (NOLOCK) 
-- WHERE name LIKE '#%' 
-- AND   OBJECT_ID('tempdb..' + name) IS NOT NULL 
-- AND   name NOT LIKE CASE WHEN 0 = 0 
--                          THEN '##%' 
--                          ELSE '#######%' 
--                     END 

-- SET @TempTablesString = 'DROP TABLE ' + @TempTablesString EXECUTE sp_executesql @TempTablesString
--*/
/***********************************************************************************/

/*************************************************************************************
** -- 1_CO_Master report  
**
*************************************************************************************/

/*************************************************************************************
** -- create table for running total   
**
*************************************************************************************/

 DECLARE @DUEDATE AS DATETIME
  
--Cache table information to be used later
-- Please change all table references to the three part name = Live.dbo.TableName to ensure the correct objects are being used and to improve performance by caching the metadata.
 SELECT 
        COL.PART_ID,
        COL.DESIRED_SHIP_DATE,  --added
        COL.CUST_ORDER_ID, 
        COL.LINE_NO,

        COL.ORDER_QTY,

        COL.TOTAL_SHIPPED_QTY,
        CASE WHEN COL.TOTAL_SHIPPED_QTY > 0 
             THEN COL.ORDER_QTY - COL.TOTAL_SHIPPED_QTY 
             ELSE COL.ORDER_QTY 
        END AS OPEN_QTY,  

         SUM(CASE WHEN COL.TOTAL_SHIPPED_QTY > 0 
                 THEN COL.ORDER_QTY - COL.TOTAL_SHIPPED_QTY 
                 ELSE COL.ORDER_QTY 
              END) OVER (PARTITION BY COL.PART_ID ORDER BY COL.PART_ID,CAST(COL.DESIRED_SHIP_DATE AS DATE) ASC) AS RTQTY_DUE,

        P.QTY_AVAILABLE_ISS
            --OVER (PARTITION BY COL.PART_ID, CO.ID, COL.CUST_ORDER_ID ORDER BY CO.ID, COL.CUST_ORDER_ID) AS QTY_DUE -- FROM crystal
 INTO #RUN_TOT_QTY_DUE
 FROM   Live.dbo.CUSTOMER_ORDER CO 
 LEFT OUTER JOIN Live.dbo.CUST_ORDER_LINE COL
 ON     CO.ID  = COL.CUST_ORDER_ID
 AND    COL.LINE_STATUS = N'A' 
 LEFT OUTER JOIN Live.dbo.PART P
 ON     COL.PART_ID=P.ID
 AND    (P.PLANNER_USER_ID LIKE N'MFG-MR%' 
 OR      P.PLANNER_USER_ID LIKE N'MFG-PL%' 
 OR      P.PLANNER_USER_ID LIKE N'MRP%' 
 OR      P.PLANNER_USER_ID LIKE N'NEW%' 
 OR      P.PLANNER_USER_ID LIKE N'PLAN%')
 WHERE (CO.STATUS = N'H' OR CO.STATUS = N'R') 
 AND (CO.ID = @CUST_ORDER_ID OR @CUST_ORDER_ID IS NULL)
 -- AND (COL.LINE_NO = @LINE_NO OR @LINE_NO IS NULL)     
 --select * from #RUN_TOT_QTY_DUE where part_id = '215Z7100-2001'
 GROUP BY COL.DESIRED_SHIP_DATE,  --added
        COL.CUST_ORDER_ID, 
        COL.LINE_NO,
        COL.PART_ID,
        COL.ORDER_QTY,

        COL.TOTAL_SHIPPED_QTY,
            P.QTY_AVAILABLE_ISS    

 --SELECT * FROM #RUN_TOT_QTY_DUE 
 --WHERE PART_ID = '100T1430-89' RETURN

 /*************************************************************************************
 ** Customer order temp table to ensure datatypes are accurate
 **
 *************************************************************************************/
 
CREATE TABLE #CUST_ORDER 
(
CUSTOMER_ID             nvarchar    (30)    NOT NULL, 
STATUS                 nchar        (2)        NOT NULL, 
CO_LINE                 nvarchar    (52)        NULL, 
PO_LINE                 nvarchar    (88)        NULL, 
PART_ID                 nvarchar    (60)        NULL, 
PART_MBU             nvarchar    (68)        NULL, 
DESCRIPTION             nvarchar    (254)        NULL, 
BUYER_USER_ID        nvarchar    (40)        NULL, 
QTY_DUE                 int                        NULL, 
DESIRED_SHIP_DATE    date                    NULL, 
PROM_DEL             date                    NULL, 
PROM_SHIP             date                    NULL, 
DUE_VAR                 int                        NULL, 
QTY_AVAILABLE_ISS    int                        NULL, 
PROJ_QTY_ON_HAND    int                        NULL, 
WO_DUE                 date                    NULL, 
DUE_VAR_WO             int                        NULL, 
PROD_STATUS             varchar        (254)        NULL,   -- includes wods workorder status 
UNIT_PRICE             decimal        (10,2)         NULL, 
TOTAL_DOLLARS         decimal        (10,2)        NULL, 
USER_6                 nvarchar    (160)        NULL, 
USER_10                 nvarchar    (160)        NULL, 
PLANNING_LEADTIME     smallint                NULL, 
CUST_ROLT             nvarchar    (160)        NULL, 
M_DAY_LEADTIME         int                        NULL, 
DRAWING_ID             nvarchar    (60)        NULL, 
OPEN_QTY            decimal        (21,8)        NULL, 
QTY_DUE_STOCK_LEVEL    varchar        (10)        NULL, 
RTQTY_DUE             int                        NULL, 
ADDR_NO                 int                        NULL, 
NAME                 nvarchar    (100)        NULL, 
ADDR_1                 nvarchar    (100)        NULL, 
ADDR_2                 nvarchar    (100)        NULL, 
CITY                 nvarchar    (60)        NULL, 
STATE                 nvarchar    (20)        NULL, 
SHIPTO                 nvarchar    (100)        NULL, 
ROWNUM              int                     NULL
)

INSERT INTO #CUST_ORDER 
(    CUSTOMER_ID    , 
    STATUS    , 
    CO_LINE    , 
    PO_LINE    , 
    PART_ID    , 
    PART_MBU    , 
    DESCRIPTION    , 
    BUYER_USER_ID    , 
    QTY_DUE    , 
    DESIRED_SHIP_DATE    , 
    PROM_DEL    , 
    PROM_SHIP    , 
    DUE_VAR    , 
    QTY_AVAILABLE_ISS    , 
    PROJ_QTY_ON_HAND    , 
    WO_DUE    , 
    DUE_VAR_WO    , 
    PROD_STATUS    , 
    UNIT_PRICE    , 
    TOTAL_DOLLARS    , 
    USER_6    , 
    USER_10    , 
    PLANNING_LEADTIME    , 
    CUST_ROLT    , 
    M_DAY_LEADTIME    , 
    DRAWING_ID    , 
    OPEN_QTY    , 
    QTY_DUE_STOCK_LEVEL    , 
    RTQTY_DUE,
    ADDR_NO    , 
    NAME    , 
    ADDR_1    , 
    ADDR_2    , 
    CITY    , 
    STATE    , 
    SHIPTO, 
    ROWNUM
    )

 SELECT CO.CUSTOMER_ID,                                                                  --cust id
         CO.STATUS,                                                                       --status
        COL.CUST_ORDER_ID + '_' + CONVERT(VARCHAR(10),COL.LINE_NO,0) AS CO_LINE,         --CO/line
    --    COL.CUSTOMER_PART_ID, 

          --if not isnull({CUST_ORDER_LINE.USER_2}) then VAL(right({CUST_ORDER_LINE.USER_2},3))
        --CASE WHEN COL.USER_2 IS NOT NULL
        --     THEN RIGHT(COL.USER_2,3)
     --   END AS LINEUDF2,                                                                 -- used to see portion of end of custPO/line and Part/mbu columns

        -- if not isnull({@line udf2}) then {CUSTOMER_ORDER.CUSTOMER_PO_REF} &"_"& totext({@line udf2},0) else {CUSTOMER_ORDER.CUSTOMER_PO_REF}
        CASE WHEN COL.USER_2 IS NOT NULL
             THEN CO.CUSTOMER_PO_REF + '_' + RIGHT(COL.USER_2,3)
             ELSE CO.CUSTOMER_PO_REF 
        END AS PO_LINE,                                                                  --Cust PO/Line


        COL.PART_ID,                                                                      --Part ID
        --CASE WHEN CO.CUSTOMER_ID                 = 'BOEDEF'             THEN 'DEF' 
        --     WHEN CO.CUSTOMER_ID                IN ('BOETRN', 'BOE614') THEN 'Other' 
        --     WHEN  SUBSTRING(COL.PART_ID, 4, 1)  = 'A'                  THEN '737' 
        --      WHEN  LEFT(COL.PART_ID, 3)          = '65-'                THEN '737' 
        --     WHEN  LEFT(COL.PART_ID, 3)          = '66-'                THEN '737' 
        --     WHEN  LEFT(COL.PART_ID, 3)          = '69-'                THEN '737'  
        --     WHEN  SUBSTRING(COL.PART_ID, 4, 1)  = 'U'                  THEN '747' 
        --     WHEN  LEFT(COL.PART_ID, 3)          = '65B'                THEN '747' 
        --     WHEN  LEFT(COL.PART_ID, 3)          = '65C'                THEN '747' 
        --     WHEN  LEFT(COL.PART_ID, 3)          = '69B'                THEN '747'   
        --     WHEN  SUBSTRING(COL.PART_ID, 4, 1)  = 'N'                  THEN '767' 
        --     WHEN  SUBSTRING(COL.PART_ID, 4, 1)  = 'T'                  THEN '767' 
        --     WHEN  SUBSTRING(COL.PART_ID, 4, 1)  = 'W'                  THEN '777' 
        --     WHEN  SUBSTRING(COL.PART_ID, 4, 1)  = 'Z'                  THEN '787' 
  --           ELSE 'Other'
  --      END  AS MODEL,
          CASE WHEN COL.USER_2 IS NOT NULL
             THEN COL.PART_ID + '_' + RIGHT(COL.USER_2,3)
             ELSE COL.PART_ID 
        END AS PART_MBU,                                                                 --part/MBU
        COALESCE(P.DESCRIPTION,    COL.MISC_REFERENCE) AS DESCRIPTION,                      --Description
        P.BUYER_USER_ID,                                                                 --Buyer ID 
        COL.ORDER_QTY AS QTY_DUE,                                                        --Qty Due  -- 05.04.2022 Ellen And Diane did not want running total of  --CONVERT(INT,QD.QTY_DUE)  -- 
        CONVERT(DATE,COL.DESIRED_SHIP_DATE) AS DESIRED_SHIP_DATE,                        --Ship Date (ASN)  **see above
        CONVERT(DATE,COALESCE(COL.PROMISE_DEL_DATE,CO.PROMISE_DEL_DATE)) AS PROM_DEL,    --Prom Del
        CONVERT(DATE,COALESCE(COL.PROMISE_DATE,CO.PROMISE_DATE)) AS PROM_SHIP,           --Prom Ship
        DATEDIFF(DAY,COALESCE(COL.PROMISE_DEL_DATE,CO.PROMISE_DEL_DATE,COL.PROMISE_DATE,CO.PROMISE_DATE),COL.DESIRED_SHIP_DATE) AS DUE_VAR,-- Due Var
           CONVERT(INT,P.QTY_AVAILABLE_ISS) AS QTY_AVAILABLE_ISS,                                                             -- used for calculation
        CONVERT(INT,P.QTY_AVAILABLE_ISS) - COL.ORDER_QTY AS PROJ_QTY_ON_HAND,            --QOH      
       -- CONVERT(INT,P.QTY_AVAILABLE_ISS) - CONVERT(INT,QD.QTY_DUE) AS PROJ_QTY_ON_HAND, --QOH    -- includes running total  05.04.2022 Ellen And Diane did not want running total 
        --WODS FIELDS HERE
        NULL as WO_DUE, 
        NULL as DUE_VAR_WO,--Due Var  (WO)     
        CASE WHEN 
                  CASE WHEN p.QTY_AVAILABLE_ISS - QD.RTQTY_DUE  >= 0 
                         THEN 'In Stock' 
                       ELSE CONVERT(VARCHAR(10), CAST(COL.ORDER_QTY AS DECIMAL(6,0)))     --CONVERT(VARCHAR(10), CAST(COL.ORDER_QTY AS DECIMAL(6,0)))      ---CONVERT(VARCHAR(10), CAST(QD.OPEN_QTY AS DECIMAL(6,0)))
                  END 
                      = 'In Stock' 
             THEN 'In Stock' 
        END AS PROD_STATUS,                                                              --Prod Status
        --End of WODs fields
        CONVERT(DECIMAL(10,2),COL.UNIT_PRICE) AS UNIT_PRICE,                             --Unit Price
        CONVERT(DECIMAL(10,2),CASE WHEN COL.TOTAL_SHIPPED_QTY > 0 
             THEN COL.ORDER_QTY - COL.TOTAL_SHIPPED_QTY 
             ELSE COL.ORDER_QTY 
        END * COL.UNIT_PRICE)  AS TOTAL_DOLLARS,                                         --Total $
        COL.USER_6,                                                                      --Ship Note(U6) 
        COL.USER_10,                                                                     --FLT/EXP(U10) 
        P.PLANNING_LEADTIME,                                                             --Visual LT 
        P.USER_10 AS CUST_ROLT,                                                          --CUST ROLT
        CASE WHEN COL.DESIRED_SHIP_DATE IS NULL
             THEN DATEDIFF(DAY,CO.ORDER_DATE,COALESCE(COL.DESIRED_SHIP_DATE, CO.DESIRED_SHIP_DATE))
             ELSE DATEDIFF(DAY,CO.ORDER_DATE,COALESCE(COL.DESIRED_SHIP_DATE, CO.DESIRED_SHIP_DATE))
        END AS M_DAY_LEADTIME,                                                           --Act. LT   -- why the same thing? 
        P.DRAWING_ID,                                                                    --EXPIRES  -- why not using expiration date of price effect?
        --COL.TOTAL_SHIPPED_QTY, 
        QD.OPEN_QTY,  
        --COALESCE(COL.DESIRED_SHIP_DATE, CO.DESIRED_SHIP_DATE)-DAY(COALESCE(COL.DESIRED_SHIP_DATE, CO.DESIRED_SHIP_DATE))+1 AS DUEMONTH,
                       
        CASE WHEN P.QTY_AVAILABLE_ISS - QD.RTQTY_DUE  >= 0 
             THEN 'In Stock' 
             ELSE CONVERT(VARCHAR(10), CAST(QD.OPEN_QTY AS DECIMAL(6,0)))
        END AS QTY_DUE_STOCK_LEVEL,
        QD.RTQTY_DUE,

       --datediff(day,CB.CREATE_DATE, CO.ORDER_DATE) AS QUEUE_DAYS,   -- NEED TO ASK AB ABOUT THIS EXAMPLE 451302  PART ID    824Z2180-23
        
        ------- ADDRESS
        CA.ADDR_NO, 
        CA.NAME, 
        CA.ADDR_1, 
        CA.ADDR_2, 
        CA.CITY, 
        CA.STATE, 
        --CA.CITY + ', '+ CA.STATE AS CITY_STATE,
        CASE WHEN ISNULL(CA.CITY, NULL) + ISNULL(CA.STATE,NULL) IS NULL 
             THEN CA.COUNTRY 
             ELSE  CA.CITY + ', '+ CA.STATE 
        END  AS SHIPTO, --shiptoCity
        ----------- 
        ROW_NUMBER() OVER (PARTITION BY COL.PART_ID ORDER BY CONVERT(DATE,COL.DESIRED_SHIP_DATE)) AS ROWNUM -- forces short for in stock level

FROM   Live.dbo.CUSTOMER_ORDER CO 
LEFT OUTER JOIN Live.dbo.CUST_ORDER_LINE COL
ON     CO.ID  = COL.CUST_ORDER_ID
AND    COL.LINE_STATUS = N'A' 
LEFT OUTER JOIN Live.dbo.CUST_ADDRESS CA 
ON     CO.CUSTOMER_ID = CA.CUSTOMER_ID 
AND    CO.SHIP_TO_ADDR_NO = CA.ADDR_NO
--LEFT OUTER JOIN Live.dbo.CUSTOMER_BOOKINGS CB
--ON     CO.ID  =  CB.CUST_ORDER_ID
LEFT OUTER JOIN Live.dbo.PART P
ON     COL.PART_ID=P.ID

AND     (P.PLANNER_USER_ID LIKE N'MFG-MR%' 
OR       P.PLANNER_USER_ID LIKE N'MFG-PL%' 
OR       P.PLANNER_USER_ID LIKE N'MRP%' 
OR       P.PLANNER_USER_ID LIKE N'NEW%' 
OR       P.PLANNER_USER_ID LIKE N'PLAN%')

LEFT OUTER JOIN Live.dbo.SKILLS_PART_UDF SPU 
ON     COL.PART_ID = SPU.PART_ID
LEFT JOIN #RUN_TOT_QTY_DUE QD
ON     COL.CUST_ORDER_ID = QD.CUST_ORDER_ID
AND    COL.LINE_NO       = QD.LINE_NO
AND    COL.PART_ID       = QD.PART_ID
WHERE     (CO.STATUS = N'H' OR CO.STATUS = N'R') 
AND    P.BUYER_USER_ID NOT LIKE '5%'
AND    COL.ORDER_QTY <> COL.TOTAL_SHIPPED_QTY 
AND (CO.ID = @CUST_ORDER_ID OR @CUST_ORDER_ID IS NULL)

--SELECT * FROM #CUST_ORDER WHERE PART_ID = '100T1430-89'
----order by desired_ship_date 
--RETURN
 -- verify the select into with the following query
--SELECT * FROM #cust_order
    ----WHERE CO_LINE = '475196_1'
    --WHERE DESIRED_SHIP_DATE > GETDATE() 
    --AND DESIRED_SHIP_DATE < '6/2/2022'
    --ORDER BY CO_LINE, DESIRED_SHIP_DATE


 --select COUNT(*) CNTREC, 'CO' from #temp_qty 
 --where  CUSTOMER_ID <> 'BOEPOP'
 --AND PART_ID = '287T1020-15'  --'140T2502-49'
 
-- co_line like '476889%'
/***********************************************************************************/ 


 /*************************************************************************************
 ** -- Get WODS report information
 **
 *************************************************************************************/
 
SELECT isnull(p.global_rank,50) as Rank, 
W.* 
INTO #WODS 
--FROM [SQL-LAB-2].LIVESupplemental.dbo.WODS_output w WITH (NOLOCK)
from Staging.dbo.WODS_Comp_test223 w WITH (NOLOCK)
-- could I use this lighter feed, 
left join Live.dbo.wo_sch_priority p 
on w.base_id = p.workorder_base_id 
and w.lot_id = p.workorder_lot_id 
and w.split_id = p.workorder_split_id 
and p.workorder_sub_id = 0 
and p.workorder_type = 'w' 
and p.schedule_id = 'STANDARD'
order by isnull(p.global_rank,50)

--SELECT * FROM #WODS 
-- SELECT desired_qty FROM #WODS where base_id = '1772725'
----WHERE BUYER_USER_ID NOT LIKE '5%'
--where PART_ID = '100T1430-89'  --140T2522-295--WHERE PART_ID = '140T2522-295' --'140T2502-49'   '141T5171-127(SPIAER)'  -- not linke

SELECT W.CUSTOMER_ORDER + '_' + CONVERT(VARCHAR(10),CAST(W.LINE_NO AS INT)) AS WODS_CO_LINE, 
       P.ID AS WODS_PART_ID, 
       P.BUYER_USER_ID,
       W.STATUS, 
       W.BASE_ID, 
       W.DESIRED_QTY, 
       CONVERT(DATE,W.DESIRED_WANT_DATE) AS WODS_DESIRED_WANT_DATE, 
       W.REMAINING_OPERATIONS,
       W.RESOURCE_ID,
       ' (' + W.STATUS+ ') ' + W.BASE_ID + ' (' + CONVERT(VARCHAR(10), CAST(W.DESIRED_QTY AS DECIMAL(6,0))) + ') '
	   + W.REMAINING_OPERATIONS AS WODS_PROD_STATUS, 
           -------------------------
        ROW_NUMBER() OVER (PARTITION BY PART_ID  ORDER BY PART_ID,CONVERT(DATE,W.DESIRED_WANT_DATE) ASC) AS SEQNUM
INTO   #WODS_FILTERED
FROM   #WODS W
JOIN   Live.dbo.PART P   
ON     P.ID = W.PART_ID
WHERE  P.BUYER_USER_ID NOT LIKE '5%'   -- Excludes Finish parts

--SELECT COUNT(*) AS CNTWO, 'WO' FROM #WODS_FILTERED

--SELECT * FROM #WODS_FILTERED
----WHERE WODS_PART_ID = '69B70071-3'-- '140T2530-37'   --140T2522-295
--RETURN


--/*****************************************************************/
---- Combine customer and work order information

SELECT C.*,
       W.WODS_PROD_STATUS,                             -- to see what is updating the field above
       W.WODS_DESIRED_WANT_DATE                       -- To see what is updating the field above

        -------------------------
        --ROW_NUMBER() OVER (PARTITION BY C.CO_LINE ORDER BY C.COL_DESIRED_SHIP_DATE DESC) AS SEQNUM
INTO   #Final
FROM    #CUST_ORDER C
LEFT JOIN #WODS_FILTERED W
ON     C.PART_ID = W.WODS_PART_ID
AND    W.SEQNUM = 1
--ORDER BY C.PART_ID, C.DESIRED_SHIP_DATE, C.CO_LINE option (force order)

--select * from #Final 
--WHERE part_id = '100T1430-89' -- before the update  


-- Update the final table's production status,  WO due, and Due Var (wo) fields from the WODS dataset

UPDATE f 
SET    F.PROD_STATUS = ISNULL(F.PROD_STATUS, W.WODS_PROD_STATUS),   
       F.WO_DUE      =  ISNULL(F.WO_DUE,W.WODS_DESIRED_WANT_DATE)
                  
FROM #Final f
JOIN #WODS_FILTERED W
ON   f.PART_ID = W.WODS_PART_ID
--WHERE F.part_id = '140T2530-37'


UPDATE F       -- update after wo_due date is updated above
SET    DUE_VAR_WO = DATEDIFF(DAY,WO_DUE,DESIRED_SHIP_DATE)
FROM #Final f
--WHERE F.part_id = '140T2530-37'

SELECT * 
FROM #Final 
WHERE 1=1

--CO_LINE LIKE '501092%'
--WHERE part_id = '140T2530-37'
--where part_id = '100T1430-89'  -- use to check 'in stock'

--WHERE CO_LINE = '478730_1'

order by desired_ship_date
GO


