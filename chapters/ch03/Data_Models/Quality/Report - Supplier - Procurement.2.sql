-- Report - Supplier - Procurement.2
/**
In SQL Server UNION ALL queries, data type precedence rules attempt to implicitly cast 
string types (nvarchar) to integer/numeric 
types (bigint) if the preceding SELECT block emits bigint for that positional column.
In Block 1 (IQM VQ_NONCONFORMANCE), NCM_ID and PRODUCT_REC_ID were integer/bigint keys, 
whereas in Block 2 (NCM NONCONFORMANCE), NCM_NUMBER and PART_ID are nvarchar strings
 (e.g. part numbers like 313Z7430-504).
Wrapped both Block 1 and Block 2 positional columns in explicit CAST(... AS nvarchar(50))
 for NCM_ID and PRODUCT_REC_ID. This aligns the column types across both arms of the UNION ALL 
 and resolves the execution error.
**/
	--not a contractor operation; not associated with a work order (base id/PO.ALT_ID_2 IS NULL)
    -- demand not linked through a work order and operation
	SELECT 
   
	     CAST(NCM_ID AS nvarchar(50)) AS NCM_ID
		, CAST(NCM.PRODUCT_REC_ID AS nvarchar(50)) AS PRODUCT_REC_ID
		, CASE 
			WHEN CHARINDEX('/',NCM.PO_NUMBER,1) = 0 THEN NCM.PO_NUMBER
			ELSE SUBSTRING(NCM.PO_NUMBER, 1, CHARINDEX('/',NCM.PO_NUMBER,1)-1) 
		END AS 'SupplierPO'
		, SUBSTRING(NCM.PO_NUMBER, LEN(NCM.PO_NUMBER), CHARINDEX('/',NCM.PO_NUMBER,1)+1) AS 'SupplierPO_LINE'
		, NCM.LOT_SIZE, NCM.ACCEPTED, NCM.REJECTED, NCM.NCM_DATE
	FROM VQ_NONCONFORMANCE NCM
	LEFT OUTER JOIN VQ_PRODUCT P ON P.RECORD_ID = NCM.PRODUCT_REC_ID
	LEFT OUTER JOIN VQ_PRODUCTION_ORDER PO ON PO.RECORD_ID = NCM.PROD_ORDER_REC_ID
		AND PO.ALT_ID_1 = 'W'
	LEFT OUTER JOIN VQ_OPERATION O ON O.RECORD_ID = NCM.OPERATION_REC_ID
	LEFT OUTER JOIN [SQL-IQM-9].[IQM_Baseline_App].DBO.VQ_SUPPLIER s
		ON S.RECORD_ID = NCM.REPORTED_BY_SUPP_REC_ID 
	WHERE NCM.NCM_TYPE = 'SUPPLIER - MAJOR' AND PO.ALT_ID_2 IS NULL

    union all

    	/**

	this is step 1 of a repoting dataset called 'Supplier Performance Load Details'
    , which is a large t-sql query. 
	Edit 1 starts at line 63 and is partially complete to instantiate records
    that reflect procurement for material not linked to a work order,
    like raw material and updates the original block spanning lines 1 - 21
	with a Union All
	The edited block currently starts on line 65 and goes to 73.
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

    -- Quality Database #2: SQL-Lab-2 / NCM
    SELECT 
       -- --  'unlinked ncm' AS note
          CAST(x.NCM_NUMBER AS nvarchar(50)) AS NCM_ID
        , CAST(x.PART_ID AS nvarchar(50)) AS PRODUCT_REC_ID  -- Part / Item / PO ID

        , CASE 
            WHEN CHARINDEX('/', x.VENDOR_PO_NUMBER, 1) = 0 THEN x.VENDOR_PO_NUMBER
            ELSE SUBSTRING(x.VENDOR_PO_NUMBER, 1, CHARINDEX('/', x.VENDOR_PO_NUMBER, 1) - 1) 
        END AS 'SupplierPO'
        , SUBSTRING(x.VENDOR_PO_NUMBER, LEN(x.VENDOR_PO_NUMBER), CHARINDEX('/', x.VENDOR_PO_NUMBER, 1) + 1)
                AS 'SupplierPO_LINE'
        , x.LOT_SIZE
        , x.ACCEPTED
        , x.REJECTED
        , x.NCM_DATE
 
    FROM [sql-lab-2].[NCM].[dbo].[NONCONFORMANCE] x WITH (NOLOCK)
    LEFT OUTER JOIN [sql-lab-2].[NCM].[dbo].[DISPOSITION_TYPE] DT WITH (NOLOCK)
        ON DT.[DISPOSITION_TYPE_CODE] = x.[DISPOSITION_TYPE_CODE]
    LEFT OUTER JOIN [sql-lab-2].[NCM].[dbo].[EMPLOYEE_LOOKUP] MADE_EE WITH (NOLOCK)
        ON MADE_EE.[EMPLOYEE_ID] = x.[MADE_BY_EMPLOYEE_ID]
    LEFT OUTER JOIN [sql-lab-2].[NCM].[dbo].[EMPLOYEE_LOOKUP] ASSGN_EE WITH (NOLOCK)
        ON ASSGN_EE.[EMPLOYEE_ID] = x.[ASSIGNED_TO_EMPLOYEE_ID]
    LEFT OUTER JOIN [sql-lab-2].[NCM].[dbo].[EMPLOYEE_LOOKUP] DISP_EE WITH (NOLOCK)
        ON DISP_EE.[EMPLOYEE_ID] = x.[DISPOSITION_BY_EMPLOYEE_ID]
    LEFT OUTER JOIN [sql-lab-2].[NCM].[dbo].[EMPLOYEE_LOOKUP] DISP_ASSG WITH (NOLOCK)
        ON DISP_ASSG.[EMPLOYEE_ID] = x.[DISPOSITION_ASSIGNED_TO_EMPLOYEE_ID]
    LEFT OUTER JOIN [sql-lab-2].[NCM].[dbo].[EMPLOYEE_LOOKUP] VERIFY_BY_EE WITH (NOLOCK)
        ON VERIFY_BY_EE.[EMPLOYEE_ID] = x.[VERIFIED_BY_EMPLOYEE_ID]
    WHERE x.BASE_ID IS NULL
        AND (x.NCM_TYPE_CODE IN ('PURCHASING SUPPLIER'))
        