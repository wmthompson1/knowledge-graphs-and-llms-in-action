	/**********************************************************************************************
	Description: material_availability
	Sample:  add the two fields 
	         to wods light
			 combine Documentation\Schema\Data_Models\Work_Orders\10.1.1_WODS_Light.sql
			 with Documentation\Schema\Data_Models\Work_Orders\material_availability.sql
			 into updated Documentation\Schema\Data_Models\Work_Orders\10.1.2_WODS_Light.sql
	Date      Modified By      Change Description
	---------- ------------------ ------------------------------------------------------------
	06/03/2026 williamt			created
	06/03/2026 williamt			integration: the two datasets needs to be added to wods feed

	LEGEND
	wods = Work Order Daily Status
	**********************************************************************************************/
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET DEADLOCK_PRIORITY LOW
	IF OBJECT_ID('tempdb..#Results') IS NOT NULL DROP TABLE #Results
 
	
	IF OBJECT_ID('tempdb..#RAW_MATERIAL_WODs') IS NOT NULL DROP TABLE #RAW_MATERIAL_WODs
	IF OBJECT_ID('tempdb..#RAW_MATERIAL_WODsX') IS NOT NULL DROP TABLE #RAW_MATERIAL_WODsX
	IF OBJECT_ID('tempdb..#Prev_Op_WODs') IS NOT NULL DROP TABLE #Prev_Op_WODs
	IF OBJECT_ID('tempdb..#stands_dets_WODs') IS NOT NULL DROP TABLE #stands_dets_WODs
	
	
	DECLARE @in_commodity_code_sand nvarchar(MAX) = N'standards,details';  
    DECLARE @in_commodity_code_rm nvarchar(MAX) = N'raw material';
	
	/* Insert values into new temporal tables */
	-- arm.
	-- for rm determine if short
	select
		a.WORKORDER_BASE_ID, a.WORKORDER_LOT_ID, a.WORKORDER_SPLIT_ID, a.WORKORDER_SUB_ID
		--,STRING_AGG(CONVERT(varchar(50), a.PART_ID), ', ') AS PART_ID_CSV
		,STRING_AGG(CONVERT(varchar(50), iif(
			(iif((a.CALC_QTY - a.ISSUED_QTY) <= b.QTY_ON_HAND, 0, 1)) 
			> 0, a.PART_ID,NULL)), ', ') AS PART_ID_CSV2
	--	,STRING_AGG(CONVERT(varchar(50), b.COMMODITY_CODE), ', ') AS COMMODITY_CODE_CSV
		, iif(
			sum(iif((a.CALC_QTY - a.ISSUED_QTY) <= b.QTY_ON_HAND, 0, 1)) 
			> 0, 1,0)
		as 'available'
		,max(iif((a.CALC_QTY - a.ISSUED_QTY) <= b.QTY_ON_HAND, NULL, IIF( b.commodity_code in ('raw material'),'raw material',null))) as commodity_code
		into #RAW_MATERIAL_WODsX
	FROM REQUIREMENT a WITH (NOLOCK)  --//#VM: change from [SQL-LAB-1] to [SQL-LAB-2]
	INNER JOIN PART b WITH (NOLOCK) on a.PART_ID = b.ID  
		and b.COMMODITY_CODE IN (
    SELECT LTRIM(RTRIM(value))
    FROM STRING_SPLIT(@in_commodity_code_rm, ',')
    )
	--INNER JOIN OPERATION o on o.WORKORDER_BASE_ID=a.WORKORDER_BASE_ID and o.WORKORDER_LOT_ID=a.WORKORDER_LOT_ID and 
	--	o.WORKORDER_SPLIT_ID = a.WORKORDER_SPLIT_ID and o.SEQUENCE_NO = a.OPERATION_SEQ_NO
	--	and o.WORKORDER_SUB_ID = ISNULL(a.SUBORD_WO_SUB_ID, 0)
	INNER JOIN WORK_ORDER c WITH (NOLOCK) ON 
		a.WORKORDER_BASE_ID = c.BASE_ID and a.WORKORDER_LOT_ID = c.LOT_ID and a.WORKORDER_SPLIT_ID = c.SPLIT_ID and a.WORKORDER_SUB_ID = c.SUB_ID
	WHERE 1=1 
	-- in test 2.2.2
	and c.type = 'w'
	-- material only
	and a.SUBORD_WO_SUB_ID is null

	group by
	a.WORKORDER_BASE_ID, a.WORKORDER_LOT_ID, a.WORKORDER_SPLIT_ID, a.WORKORDER_SUB_ID

	having 
	iif(
		sum(iif(a.CALC_QTY <= b.QTY_ON_HAND, 0, 1)) 
		> 0, 1,0) > 0
		;
-- arm/

	-- ~22

	-- a.
	-- for standards and details determine if short
	select
		a.WORKORDER_BASE_ID, a.WORKORDER_LOT_ID, a.WORKORDER_SPLIT_ID, a.WORKORDER_SUB_ID
		--,STRING_AGG(CONVERT(varchar(50), a.PART_ID), ', ') AS PART_ID_CSV
		,STRING_AGG(CONVERT(varchar(50), iif(
			(iif((a.CALC_QTY - a.ISSUED_QTY) <= b.QTY_ON_HAND, 0, 1)) 
			> 0, a.PART_ID,NULL)), ', ') AS PART_ID_CSV2
	--	,STRING_AGG(CONVERT(varchar(50), b.COMMODITY_CODE), ', ') AS COMMODITY_CODE_CSV
		, iif(
			sum(iif((a.CALC_QTY - a.ISSUED_QTY) <= b.QTY_ON_HAND, 0, 1)) 
			> 0, 1,0)
		as 'available'
		,max(iif((a.CALC_QTY - a.ISSUED_QTY) <= b.QTY_ON_HAND, NULL, IIF( b.commodity_code in ('standards','details'),'sta_det',null))) as commodity_code
		into #stands_dets_WODs
	FROM REQUIREMENT a WITH (NOLOCK)  --//#VM: change from [SQL-LAB-1] to [SQL-LAB-2]
	INNER JOIN PART b WITH (NOLOCK) on a.PART_ID = b.ID  
		and b.COMMODITY_CODE IN (
    SELECT LTRIM(RTRIM(value))
    FROM STRING_SPLIT(@in_commodity_code_sand, ',')
    )
	--INNER JOIN OPERATION o on o.WORKORDER_BASE_ID=a.WORKORDER_BASE_ID and o.WORKORDER_LOT_ID=a.WORKORDER_LOT_ID and 
	--	o.WORKORDER_SPLIT_ID = a.WORKORDER_SPLIT_ID and o.SEQUENCE_NO = a.OPERATION_SEQ_NO
	--	and o.WORKORDER_SUB_ID = ISNULL(a.SUBORD_WO_SUB_ID, 0)
	INNER JOIN WORK_ORDER c WITH (NOLOCK) ON 
		a.WORKORDER_BASE_ID = c.BASE_ID and a.WORKORDER_LOT_ID = c.LOT_ID and a.WORKORDER_SPLIT_ID = c.SPLIT_ID and a.WORKORDER_SUB_ID = c.SUB_ID
	WHERE 1=1 
	-- in test 2.2.2
	and c.type = 'w'
	-- material only
	and a.SUBORD_WO_SUB_ID is null

	group by
	a.WORKORDER_BASE_ID, a.WORKORDER_LOT_ID, a.WORKORDER_SPLIT_ID, a.WORKORDER_SUB_ID

	having 
	iif(
		sum(iif(a.CALC_QTY <= b.QTY_ON_HAND, 0, 1)) 
		> 0, 1,0) > 0
		;
-- a/

--SELECT * FROM #stands_dets_WODs;
select * FROM #RAW_MATERIAL_WODsX;