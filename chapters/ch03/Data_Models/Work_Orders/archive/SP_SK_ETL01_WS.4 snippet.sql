	DECLARE @in_commodity_code_sand nvarchar(MAX) = N'standards,details';  
	DECLARE @in_commodity_code_rm nvarchar(MAX) = N'raw material';

	
	select
		a.WORKORDER_BASE_ID, a.WORKORDER_LOT_ID, a.WORKORDER_SPLIT_ID, a.WORKORDER_SUB_ID, a.WORKORDER_TYPE
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
	--	into #RAW_MATERIAL_WODsX
	FROM REQUIREMENT a WITH (NOLOCK)  --//#VM: change from [SQL-LAB-1] to [SQL-LAB-2]
	INNER JOIN PART b WITH (NOLOCK) on a.PART_ID = b.ID  
		and b.COMMODITY_CODE IN (
    SELECT LTRIM(RTRIM(value))
    FROM STRING_SPLIT(@in_commodity_code_rm, ',')
    )
	INNER JOIN WORK_ORDER c WITH (NOLOCK) ON 
		a.WORKORDER_BASE_ID = c.BASE_ID and a.WORKORDER_LOT_ID = c.LOT_ID and a.WORKORDER_SPLIT_ID = c.SPLIT_ID and a.WORKORDER_SUB_ID = c.SUB_ID
	WHERE 1=1 
	-- in test 2.2.2
	and c.type = 'w'
	and a.SUBORD_WO_SUB_ID is null

	group by
	a.WORKORDER_BASE_ID, a.WORKORDER_LOT_ID, a.WORKORDER_SPLIT_ID, a.WORKORDER_SUB_ID, a.WORKORDER_TYPE

	having 
	iif(
		sum(iif(a.CALC_QTY <= b.QTY_ON_HAND, 0, 1)) 
		> 0, 1,0) > 0