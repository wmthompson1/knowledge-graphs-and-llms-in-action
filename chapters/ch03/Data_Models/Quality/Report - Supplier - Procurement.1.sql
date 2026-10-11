	/**
	MAP QUALITY DB 1 PRODUCT_REC_ID TO Quality DB 1? see line 96
	
		Msg 207, Level 16, State 1, Line 96
		Invalid column name 'PRODUCT_REC_ID'.
	this is step 1 of a repoting dataset called 'NCM and procurement'
    , which is a large t-sql query. 
	Edit 1 starts at line 63 and is partially complete to instantiate records
    that reflect procurement for material linked to a work order,
    like raw material and updates the original block spanning lines 55 - 87
	with a Union All
	The edited block currently starts on line 92 and goes to 129.
	please create the union from Quality Database #2 SQL
	see Documentation\plan\plan-021-quality-database-1-iqm-schema -->
	Documentation\plan\plan-020-quality-database-2-schema
	use the mapping documents  created by SME:
	Documentation\Schema\Data_Models\Quality\Mapping – Old Quality IQM To New Quality NCM.docx
	utoilize availabletools in existing code base.
	use Documentation\Schema\Data_Models\Quality\DATABASE_MAPPING 1.md for the baseline query,
     which integrates an employee table:

     ## GET Joins Used by `GET /api/ncm/[id]`

        ```sql
        FROM [dbo].[NONCONFORMANCE] NCM
        LEFT OUTER JOIN [dbo].[DISPOSITION_TYPE] DT
        ON DT.[DISPOSITION_TYPE_CODE] = NCM.[DISPOSITION_TYPE_CODE]
        LEFT OUTER JOIN [dbo].[EMPLOYEE_LOOKUP] MADE_EE
        ON MADE_EE.[EMPLOYEE_ID] = NCM.[MADE_BY_EMPLOYEE_ID]
        LEFT OUTER JOIN [dbo].[EMPLOYEE_LOOKUP] ASSGN_EE
        ON ASSGN_EE.[EMPLOYEE_ID] = NCM.[ASSIGNED_TO_EMPLOYEE_ID]
        LEFT OUTER JOIN [dbo].[EMPLOYEE_LOOKUP] DISP_EE
        ON DISP_EE.[EMPLOYEE_ID] = NCM.[DISPOSITION_BY_EMPLOYEE_ID]
        LEFT OUTER JOIN [dbo].[EMPLOYEE_LOOKUP] DISP_ASSG
        ON DISP_ASSG.[EMPLOYEE_ID] = NCM.[DISPOSITION_ASSIGNED_TO_EMPLOYEE_ID]
        LEFT OUTER JOIN [dbo].[EMPLOYEE_LOOKUP] VERIFY_BY_EE
        ON VERIFY_BY_EE.[EMPLOYEE_ID] = NCM.[VERIFIED_BY_EMPLOYEE_ID]
        WHERE 1=1
        -- and  NCM.[NCM_NUMBER] = @ncm_id
        ```
  **/


DECLARE @STARTDATE DATE 
, @ENDDATE DATE = CAST(DATEADD(dd, -DAY(GETDATE()), GETDATE()) AS DATE)

SELECT @STARTDATE = CAST(DATEADD(YEAR, -1, @ENDDATE) AS DATE)
-- ~22
SELECT @STARTDATE = CAST(DATEADD(DAY, -60, @ENDDATE) AS DATE)
--SELECT @STARTDATE, @ENDDATE;

--GET IQM NCM data
--contractor operation;  Has work order information to sequence

    -- contractor operation; has work order information to sequence
    -- demand linked through the work order and operation
    
	SELECT 
       --- 'linked iqm' AS note,
		--- NCM.NCM_TYPE
        CAST(NCM_ID AS nvarchar(50)) AS NCM_ID
        , CAST(NCM.PRODUCT_REC_ID AS nvarchar(50)) AS PRODUCT_REC_ID

        , DSL.SUPPLY_BASE_ID AS 'SupplierPO'
		, CONVERT(nvarchar(50), DSL.SUPPLY_SEQ_NO) AS 'SupplierPO_LINE'
		, NCM.LOT_SIZE, NCM.ACCEPTED, NCM.REJECTED, NCM.NCM_DATE

	FROM VQ_NONCONFORMANCE NCM
	INNER JOIN VQ_PRODUCT P ON P.RECORD_ID = NCM.PRODUCT_REC_ID
	INNER JOIN VQ_PRODUCTION_ORDER PO ON PO.RECORD_ID = NCM.PROD_ORDER_REC_ID
		AND PO.ALT_ID_1 = 'W'
	INNER JOIN VQ_OPERATION O ON O.RECORD_ID = NCM.OPERATION_REC_ID
	INNER JOIN OPERATION OP ON  PO.ALT_ID_2 = OP.WORKORDER_BASE_ID
		AND PO.ALT_ID_3 = OP.WORKORDER_LOT_ID AND PO.ALT_ID_4 = OP.WORKORDER_SPLIT_ID
		AND PO.ALT_ID_5 = OP.WORKORDER_SUB_ID AND OP.SEQUENCE_NO = TRY_CONVERT(SMALLINT, O.DISPLAY_ID)
		AND op.WORKORDER_TYPE = 'W'
	LEFT OUTER JOIN [SQL-IQM-9].[IQM_Baseline_App].DBO.VQ_SUPPLIER s
		ON s.RECORD_ID = NCM.REPORTED_BY_SUPP_REC_ID 
        -- demand linked through the work order and operation
	INNER JOIN DBO.DEMAND_SUPPLY_LINK AS DSL
		ON OP.WORKORDER_BASE_ID = DSL.DEMAND_BASE_ID
			AND OP.WORKORDER_LOT_ID = DSL.DEMAND_LOT_ID AND OP.WORKORDER_SPLIT_ID = DSL.DEMAND_SPLIT_ID
			AND OP.WORKORDER_SUB_ID = DSL.DEMAND_SUB_ID AND OP.SEQUENCE_NO = DSL.DEMAND_SEQ_NO
			AND OP.WORKORDER_TYPE ='W'
	INNER JOIN DBO.WORK_ORDER AS WO ON DSL.DEMAND_BASE_ID = WO.BASE_ID
		AND DSL.DEMAND_LOT_ID = WO.LOT_ID AND DSL.DEMAND_SPLIT_ID = WO.SPLIT_ID
		AND DSL.DEMAND_SUB_ID = WO.SUB_ID AND DSL.SUPPLY_PART_ID = WO.PART_ID AND WO.[TYPE] ='W'
	
	WHERE NCM.NCM_TYPE = 'SUPPLIER - MAJOR' AND O.CONST_RESOURCE_ID = 'CONTRACTOR'
		AND PO.ALT_ID_2 is not null 

	-- ~22
	-- Edit 1 union all starts on line 87

	union all

	    SELECT 
        -- 'linked ncm' AS note,
		--NCM.NCM_TYPE_CODE 
        CAST(NCM.NCM_NUMBER AS nvarchar(50)) AS NCM_ID
		-- MAP QUALITY DB 1 PRODUCT_REC_ID TO Quality DB 1?
        , CAST(NCM.PART_ID AS nvarchar(50)) AS PRODUCT_REC_ID  -- Part / Item / PO ID
	        , CASE 
            WHEN CHARINDEX('/', NCM.VENDOR_PO_NUMBER, 1) = 0 THEN NCM.VENDOR_PO_NUMBER
            ELSE SUBSTRING(NCM.VENDOR_PO_NUMBER, 1, CHARINDEX('/', NCM.VENDOR_PO_NUMBER, 1) - 1) 
        END AS 'SupplierPO'
        , SUBSTRING(NCM.VENDOR_PO_NUMBER, LEN(NCM.VENDOR_PO_NUMBER), CHARINDEX('/', NCM.VENDOR_PO_NUMBER, 1) + 1) AS 'SupplierPO_LINE'
        , NCM.LOT_SIZE
        , NCM.ACCEPTED
        , NCM.REJECTED
        , NCM.NCM_DATE

    FROM [sql-lab-2].[NCM].[dbo].[NONCONFORMANCE] NCM WITH (NOLOCK)
	LEFT OUTER JOIN [sql-lab-2].[Live].[dbo].[OPERATION] OP WITH (NOLOCK)
		ON NCM.BASE_ID = OP.WORKORDER_BASE_ID
		AND NCM.LOT_ID = OP.WORKORDER_LOT_ID
		AND NCM.SPLIT_ID = OP.WORKORDER_SPLIT_ID
		AND NCM.SUB_ID = OP.WORKORDER_SUB_ID
		AND OP.SEQUENCE_NO = TRY_CONVERT(SMALLINT, NCM.OPERATION_ID)
		AND OP.WORKORDER_TYPE = 'W'
	INNER JOIN DBO.DEMAND_SUPPLY_LINK AS DSL
		ON OP.WORKORDER_BASE_ID = DSL.DEMAND_BASE_ID
			AND OP.WORKORDER_LOT_ID = DSL.DEMAND_LOT_ID AND OP.WORKORDER_SPLIT_ID = DSL.DEMAND_SPLIT_ID
			AND OP.WORKORDER_SUB_ID = DSL.DEMAND_SUB_ID AND OP.SEQUENCE_NO = DSL.DEMAND_SEQ_NO
			AND OP.WORKORDER_TYPE ='W'
    LEFT OUTER JOIN [sql-lab-2].[NCM].[dbo].[DISPOSITION_TYPE] DT WITH (NOLOCK)
        ON DT.[DISPOSITION_TYPE_CODE] = NCM.[DISPOSITION_TYPE_CODE]
    LEFT OUTER JOIN [sql-lab-2].[NCM].[dbo].[EMPLOYEE_LOOKUP] MADE_EE WITH (NOLOCK)
        ON MADE_EE.[EMPLOYEE_ID] = NCM.[MADE_BY_EMPLOYEE_ID]
    LEFT OUTER JOIN [sql-lab-2].[NCM].[dbo].[EMPLOYEE_LOOKUP] ASSGN_EE WITH (NOLOCK)
        ON ASSGN_EE.[EMPLOYEE_ID] = NCM.[ASSIGNED_TO_EMPLOYEE_ID]
    LEFT OUTER JOIN [sql-lab-2].[NCM].[dbo].[EMPLOYEE_LOOKUP] DISP_EE WITH (NOLOCK)
        ON DISP_EE.[EMPLOYEE_ID] = NCM.[DISPOSITION_BY_EMPLOYEE_ID]
    LEFT OUTER JOIN [sql-lab-2].[NCM].[dbo].[EMPLOYEE_LOOKUP] DISP_ASSG WITH (NOLOCK)
        ON DISP_ASSG.[EMPLOYEE_ID] = NCM.[DISPOSITION_ASSIGNED_TO_EMPLOYEE_ID]
    LEFT OUTER JOIN [sql-lab-2].[NCM].[dbo].[EMPLOYEE_LOOKUP] VERIFY_BY_EE WITH (NOLOCK)
        ON VERIFY_BY_EE.[EMPLOYEE_ID] = NCM.[VERIFIED_BY_EMPLOYEE_ID]
    WHERE NCM.BASE_ID IS NOT NULL
        AND (NCM.NCM_TYPE_CODE IN ( 'JOB SUPPLIER')) AND OP.RESOURCE_ID = 'CONTRACTOR'


