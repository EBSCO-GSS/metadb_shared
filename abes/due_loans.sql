--metadb:function due_loans

DROP FUNCTION IF EXISTS due_loans;

CREATE FUNCTION due_loans(
    start_date date DEFAULT '2020-01-01',
    end_date date DEFAULT '2050-01-01'    
)
RETURNS TABLE(
    
    titre text,
    code_barres_item text,
    call_number text,
    code_barres_utilisateur text,
    nom_utilisateur text,
    point_service_emprunt text,
    identifiant_copie text,
    status_copie text,
    date_emprunt text,
    date_retour_prevue text,
    type_materiel text)
AS $$


SELECT distinct 
    i.title titre, 
    i2.barcode as code_barres_item, 
    i2.effective_shelving_order as call_number,
    (u.jsonb->>'barcode') AS code_barres_utilisateur,
    (u.jsonb->'personal'->>'firstName' || ' ' || (u.jsonb->'personal'->>'lastName')) AS nom_utilisateur,
    sp.discovery_display_name  as point_service_emprunt,
    l.item_id as identifiant_copie,
    l.item_status as status_copie,
    l.loan_date as date_emprunt ,
    l.due_date as date_retour_prevue,
    mt.name as type_materiel
    
from  folio_circulation.loan__t__ l 
    LEFT JOIN folio_users.users__ u  ON u.id = l.user_id 
    left join folio_inventory.item__t__ i2 on i2.id = l.item_id 
    left join folio_inventory.holdings_record__t__ ht on ht.id= i2.holdings_record_id 
    left join folio_inventory.instance__t__ i on i.id = ht.instance_id 
    left join folio_inventory.service_point__t__ sp on sp.id =l.checkout_service_point_id 
    left join folio_inventory.material_type__t__ mt on mt.id = i2.material_type_id

WHERE 
now() > l.due_date 
and l.item_status ='Checked out' 
and l.action='checkedout' 
and  l.due_date between start_date and end_date    
ORDER BY date_retour_prevue  desc, nom_utilisateur
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
