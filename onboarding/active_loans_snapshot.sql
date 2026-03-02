--metadb:function active_loans_snapshot

DROP FUNCTION IF EXISTS active_loans_snapshot;

CREATE FUNCTION active_loans_snapshot(
    start_date date DEFAULT '2020-01-01',
    end_date date DEFAULT '2050-01-01'    
)
RETURNS TABLE(
    
    title text,
    item_barcode text,
    call_number text,
    user_barcode text,
    user_name text,
    service_point text,
    item_id text,
    status_item text,
    loan_date text,
    due_date text,
    material_type text)
AS $$


SELECT distinct 
    i.title title, 
    i2.barcode as item_barcode, 
    i2.effective_shelving_order as call_number,
    (u.jsonb->>'barcode') AS user_barcode,
    (u.jsonb->'personal'->>'firstName' || ' ' || (u.jsonb->'personal'->>'lastName')) AS user_name,
    sp.discovery_display_name  as service_point,
    l.item_id as item_id,
    l.item_status as status_item,
    l.loan_date as loan_date ,
    l.due_date as due_date,
    mt.name as material_type
    
from  folio_circulation.loan__t__ l 
    LEFT JOIN folio_users.users__ u  ON u.id = l.user_id 
    left join folio_inventory.item__t__ i2 on i2.id = l.item_id 
    left join folio_inventory.holdings_record__t__ ht on ht.id= i2.holdings_record_id 
    left join folio_inventory.instance__t__ i on i.id = ht.instance_id 
    left join folio_inventory.service_point__t__ sp on sp.id =l.checkout_service_point_id 
    left join folio_inventory.material_type__t__ mt on mt.id = i2.material_type_id

WHERE 
now() < l.due_date 
and l.item_status ='Checked out' 
and l.action='checkedout' 
and  l.due_date between start_date and user_name  
ORDER BY loan_date  desc, user_name
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
