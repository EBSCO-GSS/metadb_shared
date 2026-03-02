--metadb:function due_loans_7d

DROP FUNCTION IF EXISTS due_loans_7d;

CREATE FUNCTION due_loans_7d(
 
)
RETURNS TABLE(
    
    Titulo text,
    codigo_barras text,
    call_number text,
    codigo_barras_usuario text,
    nom_utilisateur text,
    punto_servicio text,
    item_id text,
    estado_copia text,
    data_prestamo text,
    data_devolucion text,
    tipo_material text)
AS $$


SELECT distinct 
    i.title Titulo, 
    i2.barcode as codigo_barras, 
    i2.effective_shelving_order as call_number,
    (u.jsonb->>'barcode') AS codigo_barras_usuario,
    (u.jsonb->'personal'->>'firstName' || ' ' || (u.jsonb->'personal'->>'lastName')) AS usuario,
    sp.discovery_display_name  as punto_servicio,
    l.item_id as item_id,
    l.item_status as estado_copia,
    l.loan_date as data_prestamo ,
    l.due_date as data_devolucion,
    mt.name as tipo_material
    
from  folio_circulation.loan__t__ l 
    LEFT JOIN folio_users.users__ u  ON u.id = l.user_id 
    left join folio_inventory.item__t__ i2 on i2.id = l.item_id 
    left join folio_inventory.holdings_record__t__ ht on ht.id= i2.holdings_record_id 
    left join folio_inventory.instance__t__ i on i.id = ht.instance_id 
    left join folio_inventory.service_point__t__ sp on sp.id =l.checkout_service_point_id 
    left join folio_inventory.material_type__t__ mt on mt.id = i2.material_type_id

WHERE 
now() > l.due_date
and l.due_date > now() - interval '7 days'
and l.item_status ='Checked out' 
and l.action='checkedout' 
ORDER BY data_devolucion  desc, usuario
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
