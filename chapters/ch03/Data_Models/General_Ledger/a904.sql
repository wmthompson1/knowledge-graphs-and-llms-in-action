-- Hi William,
-- Can you please run following queries, save the results in excel and attach to case?

-- 1
select * from inventory_trans where workorder_base_id = '1771611'
;
-- 2
-- wip_issue_detail and wip_issue_dist
select * from wip_issue_detail
where workorder_base_id = '1771611'
order by dist_no
;
-- 2B wip_issue_dist
select * from wip_issue_dist
where workorder_base_id = '1771611'
order by dist_no
;
-- 3
select * from wip_labor_detail 
where workorder_base_id = '1771611'
order by dist_no
;
-- 4
select * from labor_ticket
where workorder_base_id = '1771611'
;
-- 5
select * from wip_service_detail 
where workorder_base_id = '1771611'
order by dist_no
;
-- 6
-- service_receipt  
select * from service_receipt
where workorder_base_id = '1771611'
;