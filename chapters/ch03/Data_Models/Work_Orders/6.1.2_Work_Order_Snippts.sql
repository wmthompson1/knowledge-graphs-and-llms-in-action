	/** 
    get the last completed review operation for each work order
     place this code snippet in /@Documentation\Schema\Data_Models\Work_Orders\functions_used\sfn_getlast_review_op_completed.sql into a cte
     and join to work order - 
     in Documentation\Schema\Data_Models\Work_Orders\6.1.1_Work_Order_Operations.1.sql
**/

    SELECT result = MAX(o.sequence_no)
         --keys
         ,o.workorder_type, o.workorder_base_id, o.workorder_lot_id, o.workorder_split_id, o.workorder_sub_id
	FROM operation o
	WHERE 1=1
		AND o.status = 'C'
        AND (o.resource_id like '%review%'
        AND o.resource_id <> 'review' -- is old  
        AND o.resource_id <> 'B1F1-REVIEW')
        GROUP BY o.workorder_type, o.workorder_base_id, o.workorder_lot_id, o.workorder_split_id, o.workorder_sub_id
        ;   
