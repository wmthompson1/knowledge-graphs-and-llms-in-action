merge_data:
				 
SET NOCOUNT OFF
DECLARE @TransactionStartDate DATETIME2(7) = SYSDATETIME()
	, @TransactionEndDate DATETIME2(7)
	, @StoredProcedureStartDate DATETIME2(7) = SYSDATETIME()
	, @DurationSeconds INT
	, @Rows INT = 0
	, @RowsPerSecond INT
	, @Error INT
	, @InsertedRows INT = 0
	, @UpdatedRows INT = 0
	, @DeletedRows INT = 0
	, @StoredProcedureName SYSNAME = (	SELECT @@SERVERNAME + '.' + DB_NAME() + '.' + s.name + '.' + o.name 
			FROM sys.objects o (NOLOCK) 
			JOIN sys.schemas s (NOLOCK) ON o.schema_id = s.schema_id 
			WHERE o.object_id = @@PROCID
		)
	, @TargetServer SYSNAME = @@SERVERNAME
	, @TargetDatabase SYSNAME = 'DataWarehouse'
	, @TargetSchema SYSNAME = 'dbo'
	, @TargetTable SYSNAME = 'Wods_Output_new'
	, @StepId INT = 1
	, @Step VARCHAR(4000)

DECLARE @MergeResult TABLE (ActionTaken VARCHAR(20) NOT NULL);
										 
MERGE LiveSupplemental.dbo.WODS_Output_ETL Trgt
USING Staging.WODS_Output01_ETL SRC (NOLOCK)
ON Trgt.WONUM = SRC.WONUM

WHEN MATCHED AND trgt.BASE_ID <> src.BASE_ID OR trgt.LOT_ID <> src.LOT_ID
	OR trgt.SPLIT_ID <> src.SPLIT_ID OR trgt.SUB_ID <> src.SUB_ID
	OR trgt.TYPE <> src.TYPE OR ISNULL(trgt.PART_ID, '') <> ISNULL(src.PART_ID, '')
	OR ISNULL(trgt.DESIRED_QTY, -30000) <> ISNULL(src.DESIRED_QTY, -30000)
	OR trgt.STATUS <> src.STATUS
	OR ISNULL(trgt.CUSTOMER_ORDER, '') <> ISNULL(src.CUSTOMER_ORDER, '')
	OR ISNULL(trgt.LINE_NO, -30000) <> ISNULL(src.LINE_NO, -30000)
	OR ISNULL(trgt.CUSTOMER_ID, '') <> ISNULL(src.CUSTOMER_ID, '')
	OR ISNULL(trgt.allocation_type, '') <> ISNULL(src.allocation_type, '')
	OR ISNULL(trgt.CurrentOperation, -30000) <> ISNULL(src.CurrentOperation, -30000)
	OR ISNULL(trgt.StatusCurrOp, -30000) <> ISNULL(src.StatusCurrOp, -30000)
	OR ISNULL(trgt.PRINTED_DATE, '1/1/1990') <> ISNULL(src.PRINTED_DATE, '1/1/1990')
	OR ISNULL(trgt.DESIRED_RLS_DATE, '1/1/1990') <> ISNULL(src.DESIRED_RLS_DATE, '1/1/1990')
	OR trgt.CREATE_DATE <> src.CREATE_DATE
	OR trgt.remaining_operations <> src.remaining_operations
	OR trgt.QTY_ON_HAND <> src.QTY_ON_HAND
	OR trgt.QTY_IN_DEMAND <> src.QTY_IN_DEMAND
	OR ISNULL(trgt.BUYER_USER_ID, '') <> ISNULL(src.BUYER_USER_ID, '')
	OR ISNULL(trgt.PLANNER_USER_ID, '') <> ISNULL(src.PLANNER_USER_ID, '')
	OR ISNULL(trgt.COMMODITY_CODE, '') <> ISNULL(src.COMMODITY_CODE, '')
	OR ISNULL(trgt.DESCRIPTION, '') <> ISNULL(src.DESCRIPTION, '')
	OR ISNULL(trgt.DESIRED_WANT_DATE, '1/1/1990') <> ISNULL(src.DESIRED_WANT_DATE, '1/1/1990')
	OR ISNULL(trgt.[EXP/FLT], '') <> ISNULL(src.[EXP/FLT], '')
	OR ISNULL(trgt.user_10, '') <> ISNULL(src.user_10, '')
	OR ISNULL(trgt.col_user_1, '') <> ISNULL(src.col_user_1, '')
	OR ISNULL(trgt.RWPart, '') <> ISNULL(src.RWPart, '')
	OR ISNULL(trgt.CUSTOMER_PO_REF, '') <> ISNULL(src.CUSTOMER_PO_REF, '')
	OR ISNULL(trgt.WORK_ORDER_NOTES, '') <> ISNULL(src.WORK_ORDER_NOTES, '')
	OR ISNULL(trgt.CUST_ORDER_NOTATION, '') <> ISNULL(src.CUST_ORDER_NOTATION, '')
	OR ISNULL(trgt.CUST_ORD_CREATEDATE, '1/1/1990') <> ISNULL(src.CUST_ORD_CREATEDATE, '1/1/1990')
	OR trgt.PartMaterialType <> src.PartMaterialType
	OR trgt.MaterialType <> src.MaterialType
	OR trgt.Alloy <> src.Alloy
	OR ISNULL(trgt.CO_AMOUNT, -30000) <> ISNULL(src.CO_AMOUNT, -30000)
	OR ISNULL(trgt.UNIT_PRICE, -30000) <> ISNULL(src.UNIT_PRICE, -30000)
	OR ISNULL(trgt.TOTAL_AMT_SHIPPED, -30000) <> ISNULL(src.TOTAL_AMT_SHIPPED, -30000)
	OR ISNULL(trgt.COL_AMOUNT, -30000) <> ISNULL(src.COL_AMOUNT, -30000)
	OR ISNULL(trgt.RESOURCE_ID_Raw, '') <> ISNULL(src.RESOURCE_ID_Raw, '')
	OR ISNULL(trgt.OPERATION_TYPE, '') <> ISNULL(src.OPERATION_TYPE, '')
	OR ISNULL(trgt.StatusCurrOpType, '') <> ISNULL(src.StatusCurrOpType, '')
	OR ISNULL(trgt.CURROPCHK, -30000) <> ISNULL(src.CURROPCHK, -30000)
	OR ISNULL(trgt.RESOURCE_ID, '') <> ISNULL(src.RESOURCE_ID, '')
	OR ISNULL(trgt.AubPriText, '') <> ISNULL(src.AubPriText, '')
	OR ISNULL(trgt.AubTcText, '') <> ISNULL(src.AubTcText, '')
	OR trgt.HasAubPri <> src.HasAubPri OR trgt.HasAubTc <> src.HasAubTc
	OR ISNULL(trgt.TimeLimit, -30000) <> ISNULL(src.TimeLimit, -30000)
	OR ISNULL(trgt.LAST_CLOCK_OUT, '1/1/1990') <> ISNULL(src.LAST_CLOCK_OUT, '1/1/1990')
	OR ISNULL(trgt.last_worked_seq, -30000) <> ISNULL(src.last_worked_seq, -30000)
	OR ISNULL(trgt.last_clocked, '') <> ISNULL(src.last_clocked, '')
	OR trgt.LATE <> src.LATE OR trgt.LATEP2 <> src.LATEP2
	OR trgt.LATEP1 <> src.LATEP1 OR trgt.LATEP3 <> src.LATEP3
	OR trgt.LATEBP1 <> src.LATEBP1 OR trgt.WAIT_DAYS <> src.WAIT_DAYS
	OR ISNULL(trgt.EMPLOYEE_ID, '') <> ISNULL(src.EMPLOYEE_ID, '')
	OR trgt.OPERATOR <> src.OPERATOR
	OR ISNULL(trgt.USER_1, '') <> ISNULL(src.USER_1, '')
	OR ISNULL(trgt.LEAD_SUPERVISOR, '') <> ISNULL(src.LEAD_SUPERVISOR, '')
	OR ISNULL(trgt.SupervisorName, '') <> ISNULL(src.SupervisorName, '')
	OR ISNULL(trgt.StatusCurrOpMsg, '') <> ISNULL(src.StatusCurrOpMsg, '')
	OR trgt.tdesc <> src.tdesc
	OR ISNULL(trgt.LABOR_TICKET_DESC, '') <> ISNULL(src.LABOR_TICKET_DESC, '')
	OR trgt.BUYER <> src.BUYER
	OR ISNULL(trgt.BUYERFILTER, '') <> ISNULL(src.BUYERFILTER, '')
	OR ISNULL(trgt.SALESREP_ID, '') <> ISNULL(src.SALESREP_ID, '')
	OR trgt.Account <> src.Account OR trgt.Plant_ID <> src.Plant_ID
	OR trgt.Tooling <> src.Tooling OR trgt.IsAP1 <> src.IsAP1
	OR trgt.IsAP2 <> src.IsAP2 OR trgt.IsAP3 <> src.IsAP3
	OR trgt.IsBP1 <> src.IsBP1 OR trgt.IsUndetermined <> src.IsUndetermined
	OR trgt.IsNORGRU <> src.IsNORGRU OR trgt.IsTWMETA <> src.IsTWMETA
	OR trgt.IsAMTRIB <> src.IsAMTRIB OR trgt.IsAUBMASK <> src.IsAUBMASK
	OR trgt.IsAUBPrime <> src.IsAUBPrime OR trgt.IsAUBSand <> src.IsAUBSand
	OR trgt.IsAUBsetup <> src.IsAUBsetup OR trgt.IsAUBTC <> src.IsAUBTC
	OR trgt.IsAUBtakedown <> src.IsAUBtakedown OR trgt.IsAUBPartMark <> src.IsAUBPartMark
	OR trgt.IsAUBFinalInspection <> src.IsAUBFinalInspection
	OR trgt.IsAUBInspection <> src.IsAUBInspection OR trgt.IsAUBPenetrant <> src.IsAUBPenetrant
	OR trgt.IsAUBChemline <> src.IsAUBChemline OR trgt.AP1_ETRAC <> src.AP1_ETRAC
	OR trgt.AP2_ETRAC <> src.AP2_ETRAC OR trgt.AP3_ETRAC <> src.AP3_ETRAC
	OR trgt.BP1_ETRAC <> src.BP1_ETRAC OR trgt.AP1_PDEXP <> src.AP1_PDEXP
	OR trgt.AP2_PDEXP <> src.AP2_PDEXP OR trgt.AP3_PDEXP <> src.AP3_PDEXP
	OR trgt.BP1_PDEXP <> src.BP1_PDEXP OR trgt.AP1_FLT <> src.AP1_FLT
	OR trgt.AP2_FLT <> src.AP2_FLT OR trgt.AP3_FLT <> src.AP3_FLT
	OR trgt.BP1_FLT <> src.BP1_FLT OR trgt.AP1_Buyer_Joe <> src.AP1_Buyer_Joe 
	OR trgt.AP1_Buyer_Rena <> src.AP1_Buyer_Rena OR trgt.AP1_Buyer_Tiffany <> src.AP1_Buyer_Tiffany 
	OR trgt.AP1_Buyer_Sunni <> src.AP1_Buyer_Sunni OR trgt.AP1_Buyer_Danielle <> src.AP1_Buyer_Danielle 
	OR trgt.AP1_Review <> src.AP1_Review OR trgt.AP1_PlanningQueue <> src.AP1_PlanningQueue 
	OR trgt.AP1_SkyFlex <> src.AP1_SkyFlex OR ISNULL(trgt.ID, '') <> ISNULL(src.ID, '') 
	OR ISNULL(trgt.DESIRED_RECV_DATE, '1/1/1990') <> ISNULL(src.DESIRED_RECV_DATE, '1/1/1990')
	OR trgt.SnapshotDate <> src.SnapshotDate OR ISNULL(trgt.DEPARTMENT, '') <> ISNULL(src.DEPARTMENT, '') 
	OR ISNULL(trgt.SUB_DEPARTMENT, '') <> ISNULL(src.SUB_DEPARTMENT, '')
	OR ISNULL(trgt.FACILITY, '') <> ISNULL(src.FACILITY, '')
	OR ISNULL(trgt.REPT_DEPT, '') <> ISNULL(src.REPT_DEPT, '')
	OR ISNULL(trgt.PROCESS, '') <> ISNULL(src.PROCESS, '')
	OR ISNULL(trgt.REPORT_GROUPING, '') <> ISNULL(src.REPORT_GROUPING, '')
	OR ISNULL(trgt.EMAIL_ADDR, '') <> ISNULL(src.EMAIL_ADDR, '')
	OR ISNULL(trgt.[SETUP_INFO], '') <> ISNULL(src.[SETUP_INFO], '')

THEN UPDATE SET
  
   LOT_ID = src.LOT_ID
 , SPLIT_ID = src.SPLIT_ID
 , SUB_ID = src.SUB_ID
 , TYPE = src.TYPE
 , PART_ID = src.PART_ID
 , WONUM = src.WONUM
 , DESIRED_QTY = src.DESIRED_QTY
 , STATUS = src.STATUS
 , CUSTOMER_ORDER = src.CUSTOMER_ORDER
 , LINE_NO = src.LINE_NO
 , CUSTOMER_ID = src.CUSTOMER_ID
 , allocation_type = src.allocation_type
 , CurrentOperation = src.CurrentOperation
 , StatusCurrOp = src.StatusCurrOp
 , PRINTED_DATE = src.PRINTED_DATE
 , DESIRED_RLS_DATE = src.DESIRED_RLS_DATE
 , CREATE_DATE = src.CREATE_DATE
 , remaining_operations = src.remaining_operations
 , QTY_ON_HAND = src.QTY_ON_HAND
 , QTY_IN_DEMAND = src.QTY_IN_DEMAND
 , BUYER_USER_ID = src.BUYER_USER_ID
 , PLANNER_USER_ID = src.PLANNER_USER_ID
 , COMMODITY_CODE = src.COMMODITY_CODE
 , DESCRIPTION = src.DESCRIPTION
 , DESIRED_WANT_DATE = src.DESIRED_WANT_DATE
 , [EXP/FLT] = src.[EXP/FLT]
 , user_10 = src.user_10
 , col_user_1 = src.col_user_1
 , RWPart = src.RWPart
 , CUSTOMER_PO_REF = src.CUSTOMER_PO_REF
 , WORK_ORDER_NOTES = src.WORK_ORDER_NOTES
 , CUST_ORDER_NOTATION = src.CUST_ORDER_NOTATION
 , CUST_ORD_CREATEDATE = src.CUST_ORD_CREATEDATE
 , PartMaterialType = src.PartMaterialType
 , MaterialType = src.MaterialType
 , Alloy = src.Alloy
 , CO_AMOUNT = src.CO_AMOUNT
 , UNIT_PRICE = src.UNIT_PRICE
 , TOTAL_AMT_SHIPPED = src.TOTAL_AMT_SHIPPED
 , COL_AMOUNT = src.COL_AMOUNT
 , RESOURCE_ID_Raw = src.RESOURCE_ID_Raw
 , OPERATION_TYPE = src.OPERATION_TYPE
 , StatusCurrOpType = src.StatusCurrOpType
 , CURROPCHK = src.CURROPCHK
 , RESOURCE_ID = src.RESOURCE_ID
 , AubPriText = src.AubPriText
 , AubTcText = src.AubTcText
 , HasAubPri = src.HasAubPri
 , HasAubTc = src.HasAubTc
 , TimeLimit = src.TimeLimit
 , LAST_CLOCK_OUT = src.LAST_CLOCK_OUT
 , last_worked_seq = src.last_worked_seq
 , last_clocked = src.last_clocked
 , LATE = src.LATE
 , LATEP2 = src.LATEP2
 , LATEP1 = src.LATEP1
 , LATEP3 = src.LATEP3
 , LATEBP1 = src.LATEBP1
 , WAIT_DAYS = src.WAIT_DAYS
 , EMPLOYEE_ID = src.EMPLOYEE_ID
 , OPERATOR = src.OPERATOR
 , USER_1 = src.USER_1
 , LEAD_SUPERVISOR = src.LEAD_SUPERVISOR
 , SupervisorName = src.SupervisorName
 , StatusCurrOpMsg = src.StatusCurrOpMsg
 , tdesc = src.tdesc
 , LABOR_TICKET_DESC = src.LABOR_TICKET_DESC
 , BUYER = src.BUYER
 , BUYERFILTER = src.BUYERFILTER
 , SALESREP_ID = src.SALESREP_ID
 , Account = src.Account
 , Plant_ID = src.Plant_ID
 , Tooling = src.Tooling
 , IsAP1 = src.IsAP1
 , IsAP2 = src.IsAP2
 , IsAP3 = src.IsAP3
 , IsBP1 = src.IsBP1
 , IsUndetermined = src.IsUndetermined
 , IsNORGRU = src.IsNORGRU
 , IsTWMETA = src.IsTWMETA
 , IsAMTRIB = src.IsAMTRIB
 , IsAUBMASK = src.IsAUBMASK
 , IsAUBPrime = src.IsAUBPrime
 , IsAUBSand = src.IsAUBSand
 , IsAUBsetup = src.IsAUBsetup
 , IsAUBTC = src.IsAUBTC
 , IsAUBtakedown = src.IsAUBtakedown
 , IsAUBPartMark = src.IsAUBPartMark
 , IsAUBFinalInspection = src.IsAUBFinalInspection
 , IsAUBInspection = src.IsAUBInspection
 , IsAUBPenetrant = src.IsAUBPenetrant
 , IsAUBChemline = src.IsAUBChemline
 , AP1_ETRAC = src.AP1_ETRAC
 , AP2_ETRAC = src.AP2_ETRAC
 , AP3_ETRAC = src.AP3_ETRAC
 , BP1_ETRAC = src.BP1_ETRAC
 , AP1_PDEXP = src.AP1_PDEXP
 , AP2_PDEXP = src.AP2_PDEXP
 , AP3_PDEXP = src.AP3_PDEXP
 , BP1_PDEXP = src.BP1_PDEXP
 , AP1_FLT = src.AP1_FLT
 , AP2_FLT = src.AP2_FLT
 , AP3_FLT = src.AP3_FLT
 , BP1_FLT = src.BP1_FLT
 , AP1_Buyer_Joe = src.AP1_Buyer_Joe
 , AP1_Buyer_Rena = src.AP1_Buyer_Rena
 , AP1_Buyer_Tiffany = src.AP1_Buyer_Tiffany
 , AP1_Buyer_Sunni = src.AP1_Buyer_Sunni
 , AP1_Buyer_Danielle = src.AP1_Buyer_Danielle
 , AP1_Review = src.AP1_Review
 , AP1_PlanningQueue = src.AP1_PlanningQueue
 , AP1_SkyFlex = src.AP1_SkyFlex
 , ID = src.ID
 , DESIRED_RECV_DATE = src.DESIRED_RECV_DATE
 , SnapshotDate = src.SnapshotDate
 , DEPARTMENT = src.DEPARTMENT
 , SUB_DEPARTMENT = src.SUB_DEPARTMENT
 , FACILITY = src.FACILITY
 , REPT_DEPT = src.REPT_DEPT
 , PROCESS = src.PROCESS
 , REPORT_GROUPING = src.REPORT_GROUPING
 , EMAIL_ADDR = src.EMAIL_ADDR
 , [SETUP_INFO] = src.SETUP_INFO
		 
WHEN NOT MATCHED BY TARGET
	THEN INSERT 
	 ( BASE_ID, LOT_ID, SPLIT_ID, SUB_ID, TYPE, PART_ID, WONUM, DESIRED_QTY, STATUS, CUSTOMER_ORDER
		, LINE_NO, CUSTOMER_ID, allocation_type, CurrentOperation, StatusCurrOp, PRINTED_DATE
		, DESIRED_RLS_DATE, CREATE_DATE, remaining_operations, QTY_ON_HAND, QTY_IN_DEMAND, BUYER_USER_ID
		, PLANNER_USER_ID, COMMODITY_CODE, DESCRIPTION, DESIRED_WANT_DATE, [EXP/FLT], user_10, col_user_1
		, RWPart, CUSTOMER_PO_REF, WORK_ORDER_NOTES, CUST_ORDER_NOTATION, CUST_ORD_CREATEDATE, PartMaterialType
		, MaterialType, Alloy, CO_AMOUNT, UNIT_PRICE, TOTAL_AMT_SHIPPED, COL_AMOUNT, RESOURCE_ID_Raw
		, OPERATION_TYPE, StatusCurrOpType, CURROPCHK, RESOURCE_ID, AubPriText, AubTcText, HasAubPri
		, HasAubTc, TimeLimit, LAST_CLOCK_OUT, last_worked_seq, last_clocked, LATE, LATEP2, LATEP1, LATEP3
		, LATEBP1, WAIT_DAYS, EMPLOYEE_ID, OPERATOR, USER_1, LEAD_SUPERVISOR, SupervisorName, StatusCurrOpMsg
		, tdesc, LABOR_TICKET_DESC, BUYER, BUYERFILTER, SALESREP_ID, Account, Plant_ID, Tooling, IsAP1, IsAP2
		, IsAP3, IsBP1, IsUndetermined, IsNORGRU, IsTWMETA, IsAMTRIB, IsAUBMASK, IsAUBPrime, IsAUBSand
		, IsAUBsetup, IsAUBTC, IsAUBtakedown, IsAUBPartMark, IsAUBFinalInspection, IsAUBInspection
		, IsAUBPenetrant, IsAUBChemline, AP1_ETRAC, AP2_ETRAC, AP3_ETRAC, BP1_ETRAC, AP1_PDEXP, AP2_PDEXP
		, AP3_PDEXP, BP1_PDEXP, AP1_FLT, AP2_FLT, AP3_FLT, BP1_FLT, AP1_Buyer_Joe, AP1_Buyer_Rena
		, AP1_Buyer_Tiffany, AP1_Buyer_Sunni, AP1_Buyer_Danielle, AP1_Review, AP1_PlanningQueue, AP1_SkyFlex
		, ID, DESIRED_RECV_DATE, SnapshotDate, DEPARTMENT, SUB_DEPARTMENT, FACILITY, REPT_DEPT, PROCESS
		, REPORT_GROUPING, EMAIL_ADDR , [SETUP_INFO]
	)

	   
 
	VALUES ( BASE_ID, LOT_ID, SPLIT_ID, SUB_ID, TYPE, PART_ID, WONUM, DESIRED_QTY, STATUS, CUSTOMER_ORDER
			, LINE_NO, CUSTOMER_ID, allocation_type, CurrentOperation, StatusCurrOp, PRINTED_DATE
			, DESIRED_RLS_DATE, CREATE_DATE, remaining_operations, QTY_ON_HAND, QTY_IN_DEMAND, BUYER_USER_ID
			, PLANNER_USER_ID, COMMODITY_CODE, DESCRIPTION, DESIRED_WANT_DATE, [EXP/FLT], user_10, col_user_1
			, RWPart, CUSTOMER_PO_REF, WORK_ORDER_NOTES, CUST_ORDER_NOTATION, CUST_ORD_CREATEDATE, PartMaterialType
			, MaterialType, Alloy, CO_AMOUNT, UNIT_PRICE, TOTAL_AMT_SHIPPED, COL_AMOUNT, RESOURCE_ID_Raw
			, OPERATION_TYPE, StatusCurrOpType, CURROPCHK, RESOURCE_ID, AubPriText, AubTcText, HasAubPri
			, HasAubTc, TimeLimit, LAST_CLOCK_OUT, last_worked_seq, last_clocked, LATE, LATEP2, LATEP1, LATEP3
			, LATEBP1, WAIT_DAYS, EMPLOYEE_ID, OPERATOR, USER_1, LEAD_SUPERVISOR, SupervisorName, StatusCurrOpMsg
			, tdesc, LABOR_TICKET_DESC, BUYER, BUYERFILTER, SALESREP_ID, Account, Plant_ID, Tooling, IsAP1, IsAP2
			, IsAP3, IsBP1, IsUndetermined, IsNORGRU, IsTWMETA, IsAMTRIB, IsAUBMASK, IsAUBPrime, IsAUBSand
			, IsAUBsetup, IsAUBTC, IsAUBtakedown, IsAUBPartMark, IsAUBFinalInspection, IsAUBInspection
			, IsAUBPenetrant, IsAUBChemline, AP1_ETRAC, AP2_ETRAC, AP3_ETRAC, BP1_ETRAC, AP1_PDEXP, AP2_PDEXP
			, AP3_PDEXP, BP1_PDEXP, AP1_FLT, AP2_FLT, AP3_FLT, BP1_FLT, AP1_Buyer_Joe, AP1_Buyer_Rena
			, AP1_Buyer_Tiffany, AP1_Buyer_Sunni, AP1_Buyer_Danielle, AP1_Review, AP1_PlanningQueue, AP1_SkyFlex
			, ID, DESIRED_RECV_DATE, SnapshotDate, DEPARTMENT, SUB_DEPARTMENT, FACILITY, REPT_DEPT, PROCESS
			, REPORT_GROUPING, EMAIL_ADDR  , [SETUP_INFO]
		)
WHEN NOT MATCHED BY SOURCE 
    THEN DELETE
	OUTPUT $Action INTO @MergeResult;

GO
