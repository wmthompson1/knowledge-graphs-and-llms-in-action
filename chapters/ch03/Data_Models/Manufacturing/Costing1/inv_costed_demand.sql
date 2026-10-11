
/*****
 * KB0733942
 * This script is used to identify demand-supply links related to inventory transactions where the costed quantity does not match the actual quantity.
 * The focus is on Documentation\Schema\Data_Models\Manufacturing\Costing1\README.md
 *****/

SELECT top 1000 * FROM DEMAND_SUPPLY_LINK WHERE ID IN
     (SELECT DEMAND_SUPPLY_ID FROM INV_RECEIPT_DIST WHERE INV_TRANS_ID IN
            (   
                
            SELECT TRANSACTION_ID FROM INVENTORY_TRANS 
                WHERE 1=1 
            --AND PART_ID = '151W7590-25' 
            and COSTED_QTY <> QTY
            ))

            SELECT TRANSACTION_ID, COSTED_QTY, WORKORDER_BASE_ID, qty, ACT_MATERIAL_COST, type, class
            FROM INVENTORY_TRANS 
                WHERE 1=1 
            --AND PART_ID = '151W7590-25' 
            --and COSTED_QTY <> QTY
            and COSTED_QTY <> 0
            and WORKORDER_BASE_ID IS NOT NULL
            and workorder_base_id = '1815582'